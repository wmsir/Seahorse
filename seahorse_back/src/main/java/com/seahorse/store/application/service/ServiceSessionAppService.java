package com.seahorse.store.application.service;

import com.seahorse.store.application.dto.session.AppendItemsCommand;
import com.seahorse.store.application.dto.session.OpenSessionCommand;
import com.seahorse.store.application.dto.session.SessionDetailVO;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.common.constant.CommonConstants;
import com.seahorse.store.domain.event.ItemAppendedEvent;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.product.model.Product;
import com.seahorse.store.domain.session.enums.LineItemStatus;
import com.seahorse.store.domain.session.enums.SessionStatus;
import com.seahorse.store.domain.session.enums.SpaceStatus;
import com.seahorse.store.domain.session.model.*;
import com.seahorse.store.infrastructure.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 空间履约与会话核心应用服务
 * 符合阿里巴巴与DDD分层架构规范
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ServiceSessionAppService {

    private final ServiceSpaceRepository spaceRepository;
    private final ServiceSessionRepository sessionRepository;
    private final OrderBatchRepository batchRepository;
    private final SessionLineItemRepository lineItemRepository;
    private final PerformerShareRepository performerShareRepository;
    private final ProductRepository productRepository;
    private final MemberRepository memberRepository;
    private final StoreRepository storeRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional(rollbackFor = Exception.class)
    public ServiceSession openSession(OpenSessionCommand cmd) {
        ServiceSpace space = spaceRepository.findById(cmd.getSpaceId())
                .orElseThrow(() -> new ServiceException("未找到该空间/工位"));
        TenantContext.assertTenantAccess(space.getTenantId());
        String tenantId = space.getTenantId();
        String storeId = space.getStoreId() != null ? space.getStoreId() : TenantContext.getStoreId();

        if (space.getStatus() == SpaceStatus.OCCUPIED) {
            throw new ServiceException("当前空间/工位正在服务中，无法重复开单");
        }

        // 查验会员身份
        String customerName = cmd.getCustomerName();
        String customerPhone = cmd.getCustomerPhone();
        if (cmd.getMemberId() != null) {
            Optional<Member> memberOpt = memberRepository.findById(cmd.getMemberId());
            if (memberOpt.isPresent()) {
                Member m = memberOpt.get();
                TenantContext.assertTenantAccess(m.getTenantId());
                customerName = m.getName();
                customerPhone = m.getPhone();
            }
        } else if (customerPhone != null && !customerPhone.trim().isEmpty()) {
            final String finalPhone = customerPhone.trim();
            Member m = memberRepository.findByTenantIdAndPhone(tenantId, finalPhone).orElse(null);
            if (m != null) {
                cmd.setMemberId(m.getId());
                if (customerName == null || customerName.trim().isEmpty() || "散客顾客".equals(customerName) || "散客到店".equals(customerName)) {
                    customerName = m.getName();
                }
            }
        }

        if (customerName == null || customerName.trim().isEmpty()) {
            customerName = "散客到店";
        }
        if (customerPhone == null) {
            customerPhone = "";
        }

        // 查询门店默认附加费配置（例如餐位费、清洁包、工位基础台费）
        BigDecimal defaultFeeAmount = BigDecimal.ZERO;
        String defaultFeeName = null;
        Optional<Store> storeOpt = storeRepository.findByStoreId(storeId);
        if (storeOpt.isPresent()) {
            Store st = storeOpt.get();
            if (Boolean.TRUE.equals(st.getFeeEnabled()) && st.getDefaultFeeAmount() != null) {
                int count = cmd.getGuestCount() != null && cmd.getGuestCount() > 0 ? cmd.getGuestCount() : 1;
                defaultFeeAmount = st.getDefaultFeeAmount().multiply(BigDecimal.valueOf(count));
                defaultFeeName = st.getFeeName();
            }
        }

        String sessionNo = "SS" + System.currentTimeMillis();

        ServiceSession session = ServiceSession.builder()
                .tenantId(tenantId)
                .storeId(storeId)
                .sessionNo(sessionNo)
                .spaceId(space.getId())
                .spaceCode(space.getSpaceCode())
                .spaceName(space.getSpaceName())
                .memberId(cmd.getMemberId())
                .customerName(customerName)
                .customerPhone(customerPhone)
                .guestCount(cmd.getGuestCount() != null ? cmd.getGuestCount() : 1)
                .status(SessionStatus.OCCUPIED_ORDERING)
                .startTime(LocalDateTime.now())
                .totalAmount(BigDecimal.ZERO)
                .feeName(defaultFeeName)
                .feeAmount(defaultFeeAmount)
                .notes(cmd.getNotes())
                .build();

        session.recalculatePayable();
        session = sessionRepository.save(session);

        // 空间状态流转为占用
        space.occupy(session.getId());
        spaceRepository.save(space);

        log.info("【开单履约成功】会话号={}, 空间={}, 顾客={}", sessionNo, space.getSpaceName(), customerName);

        return session;
    }

    @Transactional(rollbackFor = Exception.class)
    public SessionDetailVO appendItems(AppendItemsCommand cmd) {
        ServiceSession session = sessionRepository.findById(cmd.getSessionId())
                .orElseThrow(() -> new ServiceException("未找到对应会话"));
        TenantContext.assertTenantAccess(session.getTenantId());

        if (session.getStatus() == SessionStatus.CLOSED) {
            throw new ServiceException("会话已关闭，不可追加项目");
        }

        long existingBatches = batchRepository.countBySessionId(session.getId());
        int newBatchNo = (int) existingBatches + 1;

        OrderBatch batch = OrderBatch.builder()
                .sessionId(session.getId())
                .batchNo(newBatchNo)
                .operatorId(cmd.getOperatorId() != null ? cmd.getOperatorId() : TenantContext.getUserId())
                .operatorName(cmd.getOperatorName() != null ? cmd.getOperatorName() : TenantContext.getUsername())
                .operatorType(cmd.getOperatorType() != null ? cmd.getOperatorType() : CommonConstants.OPERATOR_TYPE_WAITER)
                .build();
        batch = batchRepository.save(batch);

        List<SessionLineItem> createdItems = new ArrayList<>();
        BigDecimal batchTotal = BigDecimal.ZERO;

        Set<Long> productIds = cmd.getItems() == null ? Collections.emptySet() : cmd.getItems().stream()
                .map(AppendItemsCommand.AppendItemParam::getProductId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        Map<Long, Product> productMap = new HashMap<>();
        if (!productIds.isEmpty()) {
            for (Product p : productRepository.findAllById(productIds)) {
                if (p != null && p.getId() != null) {
                    productMap.put(p.getId(), p);
                }
            }
        }

        for (AppendItemsCommand.AppendItemParam itemParam : cmd.getItems()) {
            Product product = itemParam.getProductId() != null ? productMap.get(itemParam.getProductId()) : null;
            if (product == null) {
                throw new ServiceException("商品/服务不存在: ID=" + itemParam.getProductId());
            }
            TenantContext.assertTenantAccess(product.getTenantId());

            int qty = itemParam.getQuantity() != null && itemParam.getQuantity() > 0 ? itemParam.getQuantity() : 1;
            BigDecimal subtotal = product.getPrice().multiply(BigDecimal.valueOf(qty));
            batchTotal = batchTotal.add(subtotal);

            SessionLineItem lineItem = SessionLineItem.builder()
                    .sessionId(session.getId())
                    .batchId(batch.getId())
                    .batchNo(newBatchNo)
                    .productId(product.getId())
                    .productName(product.getName())
                    .productType(product.getProductType().name())
                    .categoryName(product.getCategoryName())
                    .price(product.getPrice())
                    .quantity(qty)
                    .subtotal(subtotal)
                    .modifiers(itemParam.getModifiers())
                    .status(LineItemStatus.ACTIVE.name())
                    .build();
            lineItem = lineItemRepository.save(lineItem);
            createdItems.add(lineItem);

            // 保存施工提成分摊
            if (itemParam.getPerformers() != null && !itemParam.getPerformers().isEmpty()) {
                for (AppendItemsCommand.PerformerShareParam p : itemParam.getPerformers()) {
                    BigDecimal ratio = p.getShareRatio() != null ? p.getShareRatio() : BigDecimal.ONE;
                    BigDecimal perf = subtotal.multiply(ratio);
                    BigDecimal commConfig = product.getDefaultCommission() != null ? product.getDefaultCommission() : BigDecimal.valueOf(0.15);
                    // 兼容一口价固定提成金额(>1元)与百分比提成比例(0~1)两种配置形态
                    BigDecimal comm = commConfig.compareTo(BigDecimal.ONE) > 0
                            ? commConfig.multiply(BigDecimal.valueOf(qty)).multiply(ratio)
                            : perf.multiply(commConfig);

                    PerformerShare share = PerformerShare.builder()
                            .lineItemId(lineItem.getId())
                            .sessionId(session.getId())
                            .employeeId(p.getEmployeeId())
                            .employeeName(p.getEmployeeName())
                            .shareRatio(ratio)
                            .performanceAmount(perf)
                            .commissionAmount(comm)
                            .build();
                    performerShareRepository.save(share);
                }
            }
        }

        BigDecimal currentTotal = session.getTotalAmount() != null ? session.getTotalAmount() : BigDecimal.ZERO;
        session.setTotalAmount(currentTotal.add(batchTotal));
        session.setStatus(SessionStatus.SERVING);
        session.recalculatePayable();
        sessionRepository.save(session);

        // 发布追加事件（打印机出票或耗材扣减）
        eventPublisher.publishEvent(new ItemAppendedEvent(this, session, batch, createdItems));
        log.info("【动态追加成功】会话号={}, 追加批次={}, 项数={}, 增加金额={}",
                session.getSessionNo(), newBatchNo, createdItems.size(), batchTotal);

        return getSessionDetail(session.getId());
    }

    @Transactional(readOnly = true)
    public SessionDetailVO getSessionDetail(Long sessionId) {
        ServiceSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ServiceException("未找到该在场会话"));
        TenantContext.assertTenantAccess(session.getTenantId());

        List<OrderBatch> batches = batchRepository.findBySessionIdOrderByBatchNoAsc(sessionId);
        List<SessionLineItem> lineItems = lineItemRepository.findBySessionId(sessionId);
        List<PerformerShare> shares = performerShareRepository.findBySessionId(sessionId);

        Map<Long, List<PerformerShare>> performersByItem = shares.stream()
                .collect(Collectors.groupingBy(PerformerShare::getLineItemId));

        return SessionDetailVO.builder()
                .session(session)
                .batches(batches)
                .lineItems(lineItems)
                .performersByItem(performersByItem)
                .build();
    }

    @Transactional(rollbackFor = Exception.class)
    public void transferSpace(Long sessionId, Long targetSpaceId) {
        ServiceSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ServiceException("未找到在场会话"));
        TenantContext.assertTenantAccess(session.getTenantId());

        ServiceSpace oldSpace = spaceRepository.findById(session.getSpaceId())
                .orElseThrow(() -> new ServiceException("原空间不存在"));
        TenantContext.assertTenantAccess(oldSpace.getTenantId());

        ServiceSpace newSpace = spaceRepository.findById(targetSpaceId)
                .orElseThrow(() -> new ServiceException("目标空间不存在"));
        TenantContext.assertTenantAccess(newSpace.getTenantId());

        if (newSpace.getStatus() != SpaceStatus.IDLE) {
            throw new ServiceException("目标空间已被占用或非空闲状态，无法转入");
        }

        oldSpace.releaseToIdle();
        spaceRepository.save(oldSpace);

        newSpace.occupy(session.getId());
        spaceRepository.save(newSpace);

        session.setSpaceId(newSpace.getId());
        session.setSpaceCode(newSpace.getSpaceCode());
        session.setSpaceName(newSpace.getSpaceName());
        sessionRepository.save(session);

        log.info("【转台/转工位成功】会话 {} 从 {} 转至 {}",
                session.getSessionNo(), oldSpace.getSpaceName(), newSpace.getSpaceName());
    }

    @Transactional(rollbackFor = Exception.class)
    public void cancelLineItem(Long lineItemId, String reason) {
        SessionLineItem item = lineItemRepository.findById(lineItemId)
                .orElseThrow(() -> new ServiceException("明细项不存在"));

        ServiceSession session = sessionRepository.findById(item.getSessionId())
                .orElseThrow(() -> new ServiceException("会话不存在"));
        TenantContext.assertTenantAccess(session.getTenantId());

        if (LineItemStatus.CANCELLED.name().equals(item.getStatus())) {
            throw new ServiceException("该项目已取消");
        }

        item.setStatus(LineItemStatus.CANCELLED.name());
        item.setCancelReason(reason);
        lineItemRepository.save(item);

        BigDecimal newTotal = session.getTotalAmount().subtract(item.getSubtotal()).max(BigDecimal.ZERO);
        session.setTotalAmount(newTotal);
        session.recalculatePayable();
        sessionRepository.save(session);

        log.info("【退订取消项目】行项={}, 退款扣减金额={}, 理由={}", item.getProductName(), item.getSubtotal(), reason);
    }
}
