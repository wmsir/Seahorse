package com.seahorse.store.application.service;

import com.seahorse.store.domain.commission.enums.CommissionStatus;
import com.seahorse.store.domain.commission.enums.CommissionType;
import com.seahorse.store.domain.commission.model.CommissionRecord;
import com.seahorse.store.domain.event.BillingCompletedEvent;
import com.seahorse.store.domain.event.ItemAppendedEvent;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.product.model.Product;
import com.seahorse.store.domain.product.model.ProductBom;
import com.seahorse.store.domain.session.model.PerformerShare;
import com.seahorse.store.domain.session.model.SessionLineItem;
import com.seahorse.store.infrastructure.repository.*;
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

    private final ProductRepository productRepository;
    private final ProductBomRepository productBomRepository;
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
        String industry = store != null ? store.getIndustry().name() : "BEAUTY";

        java.util.Map<Long, List<ProductBom>> bomsByServiceId = new java.util.HashMap<>();
        java.util.Map<Long, Product> materialMap = new java.util.HashMap<>();
        if (!"RESTAURANT".equals(industry) && event.getLineItems() != null && !event.getLineItems().isEmpty()) {
            java.util.Set<Long> serviceProductIds = new java.util.LinkedHashSet<>();
            for (SessionLineItem item : event.getLineItems()) {
                if (item.getProductId() != null) {
                    serviceProductIds.add(item.getProductId());
                }
            }
            if (!serviceProductIds.isEmpty()) {
                List<ProductBom> allBoms = productBomRepository.findByServiceProductIdIn(serviceProductIds);
                java.util.Set<Long> materialIds = new java.util.LinkedHashSet<>();
                for (ProductBom bom : allBoms) {
                    if (bom != null && bom.getServiceProductId() != null) {
                        bomsByServiceId.computeIfAbsent(bom.getServiceProductId(), k -> new ArrayList<>()).add(bom);
                        if (bom.getMaterialProductId() != null) {
                            materialIds.add(bom.getMaterialProductId());
                        }
                    }
                }
                if (!materialIds.isEmpty()) {
                    for (Product mat : productRepository.findAllById(materialIds)) {
                        if (mat != null && mat.getId() != null) {
                            materialMap.put(mat.getId(), mat);
                        }
                    }
                }
            }
        }

        for (SessionLineItem item : event.getLineItems()) {
            if ("RESTAURANT".equals(industry)) {
                // 餐饮档口小票机打印模拟
                log.info(">>> [外设调度-后厨打印机] 档口出票: 桌台={}, 菜品={}, 数量={}, 忌口备注=[{}]",
                        event.getSession().getSpaceName(), item.getProductName(), item.getQuantity(), item.getModifiers());
            } else {
                // 美业或汽修：联动 BOM 原料配方自动扣减库房耗材
                List<ProductBom> boms = bomsByServiceId.getOrDefault(item.getProductId(), java.util.Collections.emptyList());
                for (ProductBom bom : boms) {
                    Product mat = materialMap.get(bom.getMaterialProductId());
                    if (mat != null) {
                        int deductTotal = bom.getConsumeQuantity().multiply(BigDecimal.valueOf(item.getQuantity())).intValue();
                        mat.deductStock(deductTotal);
                        productRepository.save(mat);
                        log.info(">>> [商品库存-BOM耗材扣减] 服务项=[{}] 消耗原料=[{}], 扣减库存={}, 剩余库存={}",
                                item.getProductName(), bom.getMaterialName(), deductTotal, mat.getStock());
                    }
                }
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

        // 1. 全渠道即时消费动账通知 (微信公众号/服务号、支付宝生活号)
        com.seahorse.store.domain.member.model.Member member = null;
        try {
            if (event.getOrder().getMemberId() != null) {
                member = memberRepository.findById(event.getOrder().getMemberId()).orElse(null);
            } else if (event.getOrder().getCustomerPhone() != null && !event.getOrder().getCustomerPhone().trim().isEmpty()) {
                member = memberRepository.findByPhone(event.getOrder().getCustomerPhone().trim()).orElse(null);
            }
            if (member != null) {
                // 实时更新会员累计消费与成长积分 (1元积1分)
                java.math.BigDecimal actual = event.getOrder().getActualAmount() != null ? event.getOrder().getActualAmount() : java.math.BigDecimal.ZERO;
                java.math.BigDecimal oldSpent = member.getTotalSpent() != null ? member.getTotalSpent() : java.math.BigDecimal.ZERO;
                member.setTotalSpent(oldSpent.add(actual));

                int oldPoints = member.getPoints() != null ? member.getPoints() : 0;
                int addPoints = actual.intValue();
                int newPoints = oldPoints + addPoints;
                member.setPoints(newPoints);

                int visits = member.getVisitCount() != null ? member.getVisitCount() : 0;
                member.setVisitCount(visits + 1);
                member.setLastVisitTime(java.time.LocalDateTime.now());

                // 依据阶梯成长积分自动平滑晋级
                if (newPoints >= 3500) {
                    member.setLevel(com.seahorse.store.domain.member.enums.MemberLevel.DIAMOND);
                } else if (newPoints >= 2000) {
                    member.setLevel(com.seahorse.store.domain.member.enums.MemberLevel.PLATINUM);
                } else if (newPoints >= 800) {
                    member.setLevel(com.seahorse.store.domain.member.enums.MemberLevel.GOLD);
                } else if (newPoints >= 300) {
                    member.setLevel(com.seahorse.store.domain.member.enums.MemberLevel.SILVER);
                }

                memberRepository.save(member);
                log.info("【会员资产更新成功】会员={}, 订单实收=￥{}, 新累计消费=￥{}, 新积分={}, 到店频次={}, 当前等级={}",
                        member.getName(), actual, member.getTotalSpent(), member.getPoints(), member.getVisitCount(), member.getLevel());
            }
            channelNotificationAppService.sendConsumeNotification(event.getOrder(), event.getPaymentRecords(), member);
        } catch (Exception ex) {
            log.error("消费动账全渠道即时推送及会员资产更新触发异常", ex);
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
