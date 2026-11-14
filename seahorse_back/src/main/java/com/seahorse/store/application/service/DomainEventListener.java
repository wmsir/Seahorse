package com.seahorse.store.application.service;

import com.seahorse.store.domain.commission.enums.CommissionStatus;
import com.seahorse.store.domain.commission.enums.CommissionType;
import com.seahorse.store.domain.commission.model.CommissionRecord;
import com.seahorse.store.domain.event.BillingCompletedEvent;
import com.seahorse.store.domain.event.ItemAppendedEvent;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.session.model.PerformerShare;
import com.seahorse.store.domain.session.model.SessionLineItem;
import com.seahorse.store.infrastructure.repository.CommissionRecordRepository;
import com.seahorse.store.infrastructure.repository.MemberRepository;
import com.seahorse.store.infrastructure.repository.PerformerShareRepository;
import com.seahorse.store.infrastructure.repository.StoreRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.seahorse.store.interfaces.web.StoreSpaceController;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class DomainEventListener {

    private final PerformerShareRepository performerShareRepository;
    private final CommissionRecordRepository commissionRecordRepository;
    private final StoreRepository storeRepository;
    private final MemberRepository memberRepository;
    private final ChannelNotificationAppService channelNotificationAppService;

    @Async
    @EventListener
    @Transactional(rollbackFor = Exception.class)
    public void handleItemAppended(ItemAppendedEvent event) {
        log.info("【事件触发】会话追加项目事件: sessionNo={}, batchNo={}",
                event.getSession().getSessionNo(), event.getBatch().getBatchNo());

        Store store = storeRepository.findByStoreId(event.getSession().getStoreId()).orElse(null);
        String industry = (store != null && store.getIndustry() != null) ? store.getIndustry().name() : "BEAUTY";

        // 餐饮档口小票机打印模拟（商品与服务 BOM 耗材库存统一在结账完成时对有效未退单品项扣减，避免重复扣减及退菜漏回滚）
        if ("RESTAURANT".equals(industry) && event.getLineItems() != null) {
            for (SessionLineItem item : event.getLineItems()) {
                log.info(">>> [外设调度-后厨打印机] 档口出票: 桌台={}, 菜品={}, 数量={}, 忌口备注=[{}]",
                        event.getSession().getSpaceName(), item.getProductName(), item.getQuantity(), item.getModifiers());
            }
        }

        // 📢 组装新点单语音报单与APP/浏览器强提醒广播 (报出菜品或服务名)
        try {
            List<SessionLineItem> items = event.getLineItems();
            if (items != null && !items.isEmpty()) {
                String spaceName = event.getSession().getSpaceName() != null ? event.getSession().getSpaceName() : "包厢";
                String spaceCode = event.getSession().getSpaceCode();
                String spaceDesc = spaceName + (spaceCode != null && !spaceCode.isEmpty() ? " (" + spaceCode + ")" : "");

                List<String> names = new ArrayList<>();
                BigDecimal batchTotal = BigDecimal.ZERO;
                for (SessionLineItem item : items) {
                    int q = item.getQuantity() != null ? item.getQuantity() : 1;
                    names.add(item.getProductName() + (q > 1 ? " " + q + "份" : ""));
                    if (item.getSubtotal() != null) {
                        batchTotal = batchTotal.add(item.getSubtotal());
                    }
                }

                String summary;
                if (names.size() <= 3) {
                    summary = String.join("、", names);
                } else {
                    summary = String.join("、", names.subList(0, 3)) + " 等" + names.size() + "项品项";
                }

                String broadcastText = String.format("请注意，%s新下单：%s，共%d项，请及时出餐服务！",
                        spaceDesc, summary, items.size());

                String id = "ORD_" + System.currentTimeMillis() + "_" + (int)(Math.random() * 900 + 100);
                String nowStr = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").format(LocalDateTime.now());

                StoreSpaceController.OrderNotificationEvent notif = StoreSpaceController.OrderNotificationEvent.builder()
                        .id(id)
                        .spaceId(event.getSession().getSpaceId())
                        .spaceCode(spaceCode)
                        .spaceName(spaceName)
                        .storeId(event.getSession().getStoreId())
                        .tenantId(event.getSession().getTenantId())
                        .itemsCount(items.size())
                        .totalAmount(batchTotal)
                        .itemNames(names)
                        .itemNamesSummary(summary)
                        .broadcastText(broadcastText)
                        .createTime(nowStr)
                        .status("PENDING")
                        .build();

                StoreSpaceController.publishOrderNotification(notif);
            }
        } catch (Exception e) {
            log.warn("发布新订单语音广播异常:", e);
        }
    }

    @Async
    @EventListener
    @Transactional(rollbackFor = Exception.class)
    public void handleBillingCompleted(BillingCompletedEvent event) {
        log.info("【事件触发】结算完成事件: orderNo={}, 订单总额={}",
                event.getOrder().getOrderNo(), event.getOrder().getActualAmount());

        // 1. 全渠道即时消费动账通知 (会员累计消费/积分/等级已在 BillingCheckoutAppService 事务内完成单次更新)
        com.seahorse.store.domain.member.model.Member member = null;
        try {
            if (event.getOrder().getMemberId() != null) {
                member = memberRepository.findById(event.getOrder().getMemberId()).orElse(null);
            } else if (event.getOrder().getCustomerPhone() != null && !event.getOrder().getCustomerPhone().trim().isEmpty()) {
                String phone = event.getOrder().getCustomerPhone().trim();
                String orderTenantId = event.getOrder().getTenantId();
                if (orderTenantId != null && !orderTenantId.trim().isEmpty()) {
                    member = memberRepository.findByTenantIdAndPhone(orderTenantId, phone).orElse(null);
                }
                if (member == null) {
                    member = memberRepository.findByPhone(phone).orElse(null);
                }
            }
            channelNotificationAppService.sendConsumeNotification(event.getOrder(), event.getPaymentRecords(), member);
        } catch (Exception ex) {
            log.error("消费动账全渠道即时推送触发异常", ex);
        }

        // 2. 异步解析并沉淀员工工时提成 (若有关联会话工单)
        Long sessionId = event.getOrder().getSessionId();
        if (sessionId != null) {
            List<PerformerShare> shares = performerShareRepository.findBySessionId(sessionId);
            for (PerformerShare share : shares) {
                BigDecimal comm = share.getCommissionAmount() != null ? share.getCommissionAmount() : BigDecimal.ZERO;

                CommissionRecord record = CommissionRecord.builder()
                        .tenantId(event.getOrder().getTenantId())
                        .storeId(event.getOrder().getStoreId())
                        .employeeId(share.getEmployeeId())
                        .employeeName(share.getEmployeeName())
                        .billingOrderId(event.getOrder().getId())
                        .lineItemId(share.getLineItemId())
                        .commissionType(CommissionType.SERVICE_WORK)
                        .baseAmount(share.getPerformanceAmount())
                        .commissionRate(share.getShareRatio())
                        .commissionAmount(comm)
                        .notes("会话工单分成结算 (单号 " + event.getOrder().getOrderNo() + ")")
                        .status(CommissionStatus.RECORDED)
                        .build();

                commissionRecordRepository.save(record);
                log.info(">>> [业绩提成核算] 技师={}, 提成金额=￥{}, 基准业绩=￥{}",
                        share.getEmployeeName(), comm, share.getPerformanceAmount());
            }
        }
    }
}
