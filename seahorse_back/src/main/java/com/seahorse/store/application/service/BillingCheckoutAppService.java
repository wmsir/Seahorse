package com.seahorse.store.application.service;

import com.seahorse.store.application.dto.billing.BillingSummaryVO;
import com.seahorse.store.application.dto.billing.CheckoutCommand;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.billing.enums.BillingStatus;
import com.seahorse.store.domain.billing.enums.PaymentChannel;
import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.billing.model.CashTenderRecord;
import com.seahorse.store.domain.billing.model.PaymentRecord;
import com.seahorse.store.domain.event.BillingCompletedEvent;
import com.seahorse.store.domain.member.enums.MemberLevel;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.payment.strategy.ChannelPayResult;
import com.seahorse.store.domain.payment.strategy.PaymentChannelStrategy;
import com.seahorse.store.domain.payment.strategy.PaymentPayContext;
import com.seahorse.store.domain.payment.strategy.PaymentStrategyFactory;
import com.seahorse.store.domain.session.enums.SessionStatus;
import com.seahorse.store.domain.product.enums.ProductType;
import com.seahorse.store.domain.product.model.Product;
import com.seahorse.store.domain.product.model.ProductBom;
import com.seahorse.store.domain.session.model.ServiceSession;
import com.seahorse.store.domain.session.model.ServiceSpace;
import com.seahorse.store.domain.session.model.SessionLineItem;
import com.seahorse.store.infrastructure.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class BillingCheckoutAppService {

    private final BillingOrderRepository billingOrderRepository;
    private final ServiceSessionRepository sessionRepository;
    private final ServiceSpaceRepository spaceRepository;
    private final PaymentRecordRepository paymentRecordRepository;
    private final CashTenderRecordRepository cashTenderRecordRepository;
    private final MemberRepository memberRepository;
    private final PaymentStrategyFactory paymentStrategyFactory;
    private final ApplicationEventPublisher eventPublisher;
    private final ProductRepository productRepository;
    private final ProductBomRepository bomRepository;
    private final SessionLineItemRepository sessionLineItemRepository;
    private final StoreRepository storeRepository;

    private void assertStaffOperator() {
        if (!TenantContext.isAuthenticated()) {
            throw new ServiceException(401, "请先登录门店员工账号再执行收银操作");
        }
        if ("CUSTOMER_MEMBER".equalsIgnoreCase(TenantContext.getRole())) {
            throw new ServiceException(403, "会员账号无权发起或结算门店收银账单");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public BillingOrder requestBilling(Long sessionId) {
        assertStaffOperator();
        ServiceSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ServiceException("未找到该在场会话"));
        TenantContext.assertTenantAccess(session.getTenantId());

        if (session.getStatus() == SessionStatus.CLOSED) {
            throw new ServiceException("会话已结束");
        }

        session.setStatus(SessionStatus.SETTLING);
        sessionRepository.save(session);

        // 获取实际活跃消费品项汇总金额
        List<SessionLineItem> lineItems = sessionLineItemRepository.findBySessionIdAndStatus(sessionId, "ACTIVE");
        BigDecimal itemTotal = lineItems.stream()
                .map(it -> it.getSubtotal() != null ? it.getSubtotal() : (it.getPrice() != null ? it.getPrice().multiply(BigDecimal.valueOf(it.getQuantity() != null ? it.getQuantity() : 1)) : BigDecimal.ZERO))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal total = (!lineItems.isEmpty()) ? itemTotal : (session.getTotalAmount() != null ? session.getTotalAmount() : BigDecimal.ZERO);
        BigDecimal fee = session.getFeeAmount() != null ? session.getFeeAmount() : BigDecimal.ZERO;
        BigDecimal discount = session.getDiscountAmount() != null ? session.getDiscountAmount() : BigDecimal.ZERO;
        BigDecimal actual = total.add(fee).subtract(discount).max(BigDecimal.ZERO);

        BillingOrder order = billingOrderRepository.findBySessionId(sessionId).orElse(null);
        if (order == null) {
            String orderNo = "ORD" + System.currentTimeMillis() + (int)(Math.random() * 900 + 100);
            order = BillingOrder.builder()
                    .tenantId(session.getTenantId())
                    .storeId(session.getStoreId())
                    .orderNo(orderNo)
                    .sessionId(session.getId())
                    .sessionNo(session.getSessionNo())
                    .spaceId(session.getSpaceId())
                    .spaceName(session.getSpaceName())
                    .memberId(session.getMemberId())
                    .customerName(session.getCustomerName())
                    .customerPhone(session.getCustomerPhone())
                    .totalAmount(total)
                    .feeAmount(fee)
                    .discountAmount(discount)
                    .actualAmount(actual)
                    .paidAmount(BigDecimal.ZERO)
                    .status(BillingStatus.PENDING)
                    .build();
        } else if (order.getStatus() == BillingStatus.PENDING) {
            order.setTotalAmount(total);
            order.setFeeAmount(fee);
            order.setDiscountAmount(discount);
            order.setActualAmount(actual);
            order.setMemberId(session.getMemberId());
            order.setCustomerName(session.getCustomerName());
            order.setCustomerPhone(session.getCustomerPhone());
        }

        return billingOrderRepository.save(order);
    }

    @Transactional(rollbackFor = Exception.class)
    public BillingSummaryVO executeCheckout(CheckoutCommand cmd) {
        assertStaffOperator();
        BillingOrder order = null;
        if (cmd.getBillingOrderId() != null) {
            order = billingOrderRepository.findById(cmd.getBillingOrderId()).orElse(null);
            if (order == null) {
                // 若按 billingOrderId 没查到，尝试是否误传为 sessionId
                order = billingOrderRepository.findBySessionId(cmd.getBillingOrderId()).orElse(null);
            }
        }

        if (order == null && cmd.getSessionId() != null) {
            order = billingOrderRepository.findBySessionId(cmd.getSessionId()).orElse(null);
            if (order == null && sessionRepository.existsById(cmd.getSessionId())) {
                order = requestBilling(cmd.getSessionId());
            }
        }

        List<CheckoutCommand.PaymentSplitItem> rawSplits = cmd.getSplitItems() != null
                ? cmd.getSplitItems()
                : java.util.Collections.emptyList();

        // 若无既有账单且为前台快速收银，必须基于服务端商品目录价格实时核算总额与会员折扣，严禁采信客户端传入金额/折扣
        if (order == null) {
            if (cmd.getItems() == null || cmd.getItems().isEmpty()) {
                throw new ServiceException(400, "未找到对应账单且未提供结算商品/服务明细");
            }
            String tenantId = TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001";
            String storeId = TenantContext.getStoreId() != null ? TenantContext.getStoreId() : "S001";

            Long memberId = cmd.getMemberId();
            Member foundMem = null;
            if (memberId != null) {
                foundMem = memberRepository.findById(memberId).orElse(null);
                if (foundMem != null) {
                    TenantContext.assertTenantAccess(foundMem.getTenantId());
                } else {
                    memberId = null;
                }
            } else if (cmd.getCustomerPhone() != null && !cmd.getCustomerPhone().trim().isEmpty()) {
                foundMem = memberRepository.findByTenantIdAndPhone(tenantId, cmd.getCustomerPhone().trim()).orElse(null);
                if (foundMem != null) {
                    memberId = foundMem.getId();
                }
            }

            BigDecimal total = BigDecimal.ZERO;
            BigDecimal discountedTotal = BigDecimal.ZERO;
            for (CheckoutCommand.CheckoutItem item : cmd.getItems()) {
                int qty = (item.getQuantity() != null && item.getQuantity() > 0) ? item.getQuantity() : 1;
                Product catalogProduct = resolveCatalogProduct(tenantId, storeId, item);
                if (catalogProduct == null) {
                    throw new ServiceException(400, "结算失败：商品/服务不存在或无权跨租户访问");
                }
                BigDecimal unitPrice = catalogProduct.getPrice() != null ? catalogProduct.getPrice().max(BigDecimal.ZERO) : BigDecimal.ZERO;
                BigDecimal lineSubtotal = unitPrice.multiply(BigDecimal.valueOf(qty));
                total = total.add(lineSubtotal);

                BigDecimal discountRate = BigDecimal.ONE;
                if (foundMem != null && foundMem.getLevel() != null) {
                    discountRate = catalogProduct.getProductType() == ProductType.SERVICE
                            ? foundMem.getLevel().getServiceDiscount()
                            : foundMem.getLevel().getProductDiscount();
                }
                discountedTotal = discountedTotal.add(lineSubtotal.multiply(discountRate)
                        .setScale(2, java.math.RoundingMode.HALF_UP));
            }

            BigDecimal fee = BigDecimal.ZERO;
            if (cmd.getSpaceId() != null && total.compareTo(BigDecimal.ZERO) > 0) {
                var storeOpt = storeRepository.findByStoreIdAndTenantId(storeId, tenantId);
                if (storeOpt.isPresent() && Boolean.TRUE.equals(storeOpt.get().getFeeEnabled())
                        && storeOpt.get().getDefaultFeeAmount() != null) {
                    fee = storeOpt.get().getDefaultFeeAmount().max(BigDecimal.ZERO);
                }
            }
            BigDecimal discount = total.subtract(discountedTotal).max(BigDecimal.ZERO);
            BigDecimal actual = total.add(fee).subtract(discount).max(BigDecimal.ZERO);
            String orderNo = (cmd.getOrderNo() != null && !cmd.getOrderNo().trim().isEmpty())
                    ? cmd.getOrderNo()
                    : "ORD" + System.currentTimeMillis() + (int)(Math.random() * 900 + 100);

            order = BillingOrder.builder()
                    .tenantId(tenantId)
                    .storeId(storeId)
                    .orderNo(orderNo)
                    .sessionId(cmd.getSessionId())
                    .spaceId(cmd.getSpaceId())
                    .spaceName(cmd.getSpaceName() != null ? cmd.getSpaceName() : "前台收银台")
                    .memberId(memberId)
                    .customerName(foundMem != null ? foundMem.getName() : (cmd.getCustomerName() != null ? cmd.getCustomerName() : "散客顾客"))
                    .customerPhone(foundMem != null ? foundMem.getPhone() : (cmd.getCustomerPhone() != null ? cmd.getCustomerPhone() : ""))
                    .totalAmount(total)
                    .feeAmount(fee)
                    .discountAmount(discount)
                    .actualAmount(actual)
                    .paidAmount(BigDecimal.ZERO)
                    .status(BillingStatus.PENDING)
                    .build();
            order = billingOrderRepository.save(order);
        } else {
            TenantContext.assertTenantAccess(order.getTenantId());
        }

        if (order.getStatus() == BillingStatus.PAID) {
            throw new ServiceException("该账单已完成结算，不可重复支付");
        }

        // 计算组合支付覆盖金额
        BigDecimal totalPlanAmount = rawSplits.stream()
                .map(item -> item.getAmount() != null ? item.getAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 对既有 PENDING 账单：仅允许按服务端会话明细与会员等级重新核算，禁止客户端篡改总额/折扣/实收
        if (order.getStatus() == BillingStatus.PENDING) {
            if (order.getSessionId() != null) {
                ServiceSession session = sessionRepository.findById(order.getSessionId()).orElse(null);
                if (session != null) {
                    TenantContext.assertTenantAccess(session.getTenantId());
                    List<SessionLineItem> lineItems = sessionLineItemRepository.findBySessionIdAndStatus(order.getSessionId(), "ACTIVE");
                    BigDecimal itemTotal = lineItems.stream()
                            .map(it -> it.getSubtotal() != null ? it.getSubtotal() : (it.getPrice() != null ? it.getPrice().multiply(BigDecimal.valueOf(it.getQuantity() != null ? it.getQuantity() : 1)) : BigDecimal.ZERO))
                            .reduce(BigDecimal.ZERO, BigDecimal::add);
                    BigDecimal serverTotal = (!lineItems.isEmpty()) ? itemTotal : (session.getTotalAmount() != null ? session.getTotalAmount() : BigDecimal.ZERO);
                    BigDecimal serverFee = session.getFeeAmount() != null ? session.getFeeAmount() : BigDecimal.ZERO;
                    BigDecimal serverDiscount = session.getDiscountAmount() != null ? session.getDiscountAmount() : BigDecimal.ZERO;
                    BigDecimal serverActual = serverTotal.add(serverFee).subtract(serverDiscount).max(BigDecimal.ZERO);
                    order.setTotalAmount(serverTotal);
                    order.setFeeAmount(serverFee);
                    order.setDiscountAmount(serverDiscount);
                    order.setActualAmount(serverActual);
                }
            }
            if (cmd.getMemberId() != null && order.getMemberId() == null) {
                Member foundMem = memberRepository.findById(cmd.getMemberId()).orElse(null);
                if (foundMem != null) {
                    TenantContext.assertTenantAccess(foundMem.getTenantId());
                    order.setMemberId(foundMem.getId());
                }
            } else if (order.getMemberId() == null && cmd.getCustomerPhone() != null && !cmd.getCustomerPhone().trim().isEmpty()) {
                Member foundMem = memberRepository.findByTenantIdAndPhone(order.getTenantId(), cmd.getCustomerPhone().trim()).orElse(null);
                if (foundMem != null) {
                    order.setMemberId(foundMem.getId());
                }
            }
            if (cmd.getCustomerName() != null && !cmd.getCustomerName().trim().isEmpty()) {
                order.setCustomerName(cmd.getCustomerName());
            }
            if (cmd.getCustomerPhone() != null && !cmd.getCustomerPhone().trim().isEmpty()) {
                order.setCustomerPhone(cmd.getCustomerPhone());
            }
            order = billingOrderRepository.save(order);
        }

        boolean isZeroCompedOrder = order.getActualAmount() != null
                && order.getActualAmount().compareTo(BigDecimal.ZERO) == 0;
        if (!isZeroCompedOrder && rawSplits.isEmpty()) {
            throw new ServiceException("支付组合明细不能为空");
        }

        if (totalPlanAmount.compareTo(order.getActualAmount()) < 0) {
            throw new ServiceException("支付组合金额不足（应收: ￥" + order.getActualAmount() + ", 计划支付: ￥" + totalPlanAmount + "）");
        }

        List<PaymentRecord> paymentRecords = new ArrayList<>();
        CashTenderRecord cashTenderRecord = null;

        Long resolvedMemberId = order.getMemberId();
        if (resolvedMemberId != null) {
            memberRepository.findById(resolvedMemberId)
                    .ifPresent(m -> TenantContext.assertTenantAccess(m.getTenantId()));
        }

        for (CheckoutCommand.PaymentSplitItem split : rawSplits) {
            BigDecimal splitAmount = split.getAmount() != null ? split.getAmount() : BigDecimal.ZERO;
            boolean isTimeCardDeduct = split.getChannel() == PaymentChannel.TIME_CARD
                    && split.getTimeCardDeductCount() != null
                    && split.getTimeCardDeductCount() > 0;

            ChannelPayResult result;
            if (splitAmount.compareTo(BigDecimal.ZERO) <= 0 && !isTimeCardDeduct) {
                result = ChannelPayResult.success("COMP" + System.currentTimeMillis());
            } else {
                PaymentChannelStrategy strategy = paymentStrategyFactory.getStrategy(split.getChannel());
                PaymentPayContext payContext = PaymentPayContext.builder()
                        .tenantId(order.getTenantId())
                        .storeId(order.getStoreId())
                        .order(order)
                        .amount(splitAmount)
                        .memberId(resolvedMemberId)
                        .timeCardSkuId(split.getTimeCardSkuId())
                        .timeCardDeductCount(split.getTimeCardDeductCount())
                        .tenderedAmount(split.getTenderedAmount())
                        .build();

                result = strategy.processPay(payContext);
                if (!result.isSuccess()) {
                    throw new ServiceException("渠道结算失败: " + result.getErrorMessage());
                }
            }

            // 现金记录
            if (split.getChannel() == PaymentChannel.CASH && result.getChangeAmount() != null) {
                cashTenderRecord = CashTenderRecord.builder()
                        .billingOrderId(order.getId())
                        .dueAmount(splitAmount)
                        .tenderedAmount(split.getTenderedAmount() != null ? split.getTenderedAmount() : splitAmount)
                        .changeAmount(result.getChangeAmount())
                        .drawerOpened(result.getDrawerOpened())
                        .build();
                cashTenderRecord = cashTenderRecordRepository.save(cashTenderRecord);
            }

            PaymentRecord record = PaymentRecord.builder()
                    .billingOrderId(order.getId())
                    .orderNo(order.getOrderNo())
                    .channel(split.getChannel() != null ? split.getChannel() : PaymentChannel.CASH)
                    .amount(splitAmount)
                    .principalAmount(result.getPrincipalDeducted())
                    .giftAmount(result.getGiftDeducted())
                    .timeCardSkuId(split.getTimeCardSkuId())
                    .timeCardDeductCount(split.getTimeCardDeductCount())
                    .tradeNo(result.getTradeNo())
                    .status("SUCCESS")
                    .payTime(LocalDateTime.now())
                    .build();

            record = paymentRecordRepository.save(record);
            paymentRecords.add(record);
        }

        // 订单状态变更为已支付
        order.setStatus(BillingStatus.PAID);
        order.setPaidAmount(order.getActualAmount());
        order.setCashierId(cmd.getCashierId() != null ? cmd.getCashierId() : TenantContext.getUserId());
        order.setCashierName(cmd.getCashierName() != null ? cmd.getCashierName() : (TenantContext.getUsername() != null ? TenantContext.getUsername() : "前台收银员"));
        order.setSettledAt(LocalDateTime.now());
        final BillingOrder savedOrder = billingOrderRepository.save(order);

        // 会话状态推进为已结账待复位
        if (savedOrder.getSessionId() != null) {
            sessionRepository.findById(savedOrder.getSessionId()).ifPresent(session -> {
                session.setStatus(SessionStatus.SETTLED_WAIT_CLEAN);
                session.setEndTime(LocalDateTime.now());
                if (savedOrder.getActualAmount() != null) {
                    session.setPayableAmount(savedOrder.getActualAmount());
                }
                if (savedOrder.getTotalAmount() != null) {
                    session.setTotalAmount(savedOrder.getTotalAmount());
                }
                sessionRepository.save(session);

                // 空间标记为待清理 DIRTY
                spaceRepository.findById(session.getSpaceId()).ifPresent(space -> {
                    space.markDirty();
                    spaceRepository.save(space);
                });
            });
        }
        if (savedOrder.getSpaceId() != null) {
            spaceRepository.findById(savedOrder.getSpaceId()).ifPresent(space -> {
                space.markDirty();
                spaceRepository.save(space);
            });
            // 兜底将该空间关联的活跃服务会话均推进为已结账待复位
            List<SessionStatus> activeStatuses = Arrays.asList(
                    SessionStatus.OCCUPIED_ORDERING, SessionStatus.SERVING, SessionStatus.SETTLING);
            List<ServiceSession> activeSessions = sessionRepository.findBySpaceIdAndStatusIn(savedOrder.getSpaceId(), activeStatuses);
            for (ServiceSession s : activeSessions) {
                s.setStatus(SessionStatus.SETTLED_WAIT_CLEAN);
                s.setEndTime(LocalDateTime.now());
                sessionRepository.save(s);
            }
        }

        // 更新会员消费累计、到店频次、成长积分及自动晋级
        if (savedOrder.getMemberId() != null) {
            memberRepository.findById(savedOrder.getMemberId()).ifPresent(member -> {
                BigDecimal actualAmount = savedOrder.getActualAmount() != null ? savedOrder.getActualAmount() : BigDecimal.ZERO;
                BigDecimal spent = member.getTotalSpent() != null ? member.getTotalSpent() : BigDecimal.ZERO;
                member.setTotalSpent(spent.add(actualAmount));
                int visits = member.getVisitCount() != null ? member.getVisitCount() : 0;
                member.setVisitCount(visits + 1);
                member.setLastVisitTime(LocalDateTime.now());

                // 消费 1 元累积 1 积分/经验
                int earnedPoints = actualAmount.intValue();
                if (earnedPoints > 0) {
                    int currPoints = member.getPoints() != null ? member.getPoints() : 0;
                    int updatedPoints = currPoints + earnedPoints;
                    member.setPoints(updatedPoints);

                    // 自动成长晋级检测
                    MemberLevel oldLevel = member.getLevel() != null ? member.getLevel() : MemberLevel.REGULAR;
                    MemberLevel newLevel = MemberLevel.calculateLevelByGrowth(updatedPoints);
                    if (newLevel.ordinal() > oldLevel.ordinal()) {
                        member.setLevel(newLevel);
                        log.info("【会员自动升级成功】会员ID={}, 姓名={}, 原等级={}, 升级为新等级={}, 当前积分={}",
                                member.getId(), member.getName(), oldLevel.getDescription(), newLevel.getDescription(), updatedPoints);
                    }
                }

                memberRepository.save(member);
            });
        }

        // 扣减商品实物库存及服务项关联的BOM配方耗材库存
        deductProductAndBomStock(savedOrder, cmd);

        // 发布结算成功领域事件（触发员工提成计算、微信动账消息等）
        eventPublisher.publishEvent(new BillingCompletedEvent(this, savedOrder, paymentRecords));
        log.info("【结算完成】订单号={}, 实收总额={}, 组合支付通道数={}",
                savedOrder.getOrderNo(), savedOrder.getActualAmount(), paymentRecords.size());

        return BillingSummaryVO.builder()
                .order(savedOrder)
                .paymentRecords(paymentRecords)
                .cashTender(cashTenderRecord)
                .build();
    }

    private Product resolveCatalogProduct(String tenantId, String storeId, CheckoutCommand.CheckoutItem item) {
        if (item == null) {
            return null;
        }
        if (item.getProductId() != null && item.getProductId() > 0) {
            Product p = productRepository.findById(item.getProductId()).orElse(null);
            if (p != null) {
                TenantContext.assertTenantAccess(p.getTenantId());
                return p;
            }
        }
        List<Product> tenantProducts = productRepository.findByTenantId(tenantId);
        if (item.getProductCode() != null && !item.getProductCode().trim().isEmpty()) {
            String code = item.getProductCode().trim();
            for (Product p : tenantProducts) {
                if ((storeId == null || storeId.equals(p.getStoreId())) && code.equals(p.getProductCode())) {
                    return p;
                }
            }
            for (Product p : tenantProducts) {
                if (code.equals(p.getProductCode())) {
                    return p;
                }
            }
        }
        if (item.getProductName() != null && !item.getProductName().trim().isEmpty()) {
            String name = item.getProductName().trim();
            for (Product p : tenantProducts) {
                if (name.equalsIgnoreCase(p.getName())) {
                    return p;
                }
            }
        }
        return null;
    }

    /**
     * 结账完成后扣减商品实物库存及服务项关联的BOM原料耗材
     */
    private void deductProductAndBomStock(BillingOrder order, CheckoutCommand cmd) {
        try {
            List<CheckoutCommand.CheckoutItem> itemsToDeduct = new ArrayList<>();
            if (cmd.getItems() != null && !cmd.getItems().isEmpty()) {
                itemsToDeduct.addAll(cmd.getItems());
            } else if (order.getSessionId() != null) {
                // 如果前端未显式传递品项清单，且关联了在场会话，从会话点单明细中提取
                List<SessionLineItem> sessionItems = sessionLineItemRepository.findBySessionId(order.getSessionId());
                if (sessionItems != null) {
                    for (SessionLineItem sli : sessionItems) {
                        if (!"CANCELLED".equalsIgnoreCase(sli.getStatus())) {
                            itemsToDeduct.add(CheckoutCommand.CheckoutItem.builder()
                                    .productId(sli.getProductId())
                                    .productName(sli.getProductName())
                                    .productType(sli.getProductType())
                                    .price(sli.getPrice())
                                    .quantity(sli.getQuantity())
                                    .build());
                        }
                    }
                }
            }

            if (itemsToDeduct.isEmpty()) {
                log.info("【结账库存处理】订单号={} 未包含需扣减的商品品项", order.getOrderNo());
                return;
            }

            java.util.Set<Long> itemProductIds = new java.util.LinkedHashSet<>();
            for (CheckoutCommand.CheckoutItem item : itemsToDeduct) {
                if (item.getProductId() != null && item.getProductId() > 0) {
                    itemProductIds.add(item.getProductId());
                }
            }
            java.util.Map<Long, Product> productByIdMap = new java.util.HashMap<>();
            if (!itemProductIds.isEmpty()) {
                for (Product p : productRepository.findAllById(itemProductIds)) {
                    if (p != null && p.getId() != null) {
                        productByIdMap.put(p.getId(), p);
                    }
                }
            }

            List<Product> tenantProductsCache = null;
            List<Product> resolvedProducts = new ArrayList<>(itemsToDeduct.size());
            java.util.Set<Long> serviceProductIds = new java.util.LinkedHashSet<>();

            for (CheckoutCommand.CheckoutItem item : itemsToDeduct) {
                Product product = null;
                // 1. 优先通过 productId 批量缓存查找
                if (item.getProductId() != null && item.getProductId() > 0) {
                    product = productByIdMap.get(item.getProductId());
                }
                // 2. 其次通过 productCode 查询
                if (product == null && item.getProductCode() != null && !item.getProductCode().trim().isEmpty()) {
                    String code = item.getProductCode().trim();
                    if (tenantProductsCache == null) {
                        tenantProductsCache = productRepository.findByTenantId(order.getTenantId());
                    }
                    for (Product p : tenantProductsCache) {
                        if (order.getStoreId() != null && order.getStoreId().equals(p.getStoreId()) && code.equals(p.getProductCode())) {
                            product = p;
                            break;
                        }
                    }
                    if (product == null && storeIdOrDefault(order) != null) {
                        product = productRepository.findByStoreIdAndProductCode(order.getStoreId(), code).orElse(null);
                    }
                }
                if (product != null) {
                    TenantContext.assertTenantAccess(product.getTenantId());
                }
                // 3. 再次通过商品名称在租户下匹配
                if (product == null && item.getProductName() != null && !item.getProductName().trim().isEmpty()) {
                    if (tenantProductsCache == null) {
                        tenantProductsCache = productRepository.findByTenantId(order.getTenantId());
                    }
                    for (Product p : tenantProductsCache) {
                        if (item.getProductName().trim().equalsIgnoreCase(p.getName())) {
                            product = p;
                            break;
                        }
                    }
                }
                if (product != null && product.getId() != null) {
                    productByIdMap.putIfAbsent(product.getId(), product);
                    product = productByIdMap.get(product.getId());
                    if (product.getProductType() == ProductType.SERVICE) {
                        serviceProductIds.add(product.getId());
                    }
                }
                resolvedProducts.add(product);
            }

            java.util.Map<Long, List<ProductBom>> bomsByServiceId = new java.util.HashMap<>();
            if (!serviceProductIds.isEmpty()) {
                List<ProductBom> allBoms = bomRepository.findByServiceProductIdIn(serviceProductIds);
                java.util.Set<Long> missingMaterialIds = new java.util.LinkedHashSet<>();
                for (ProductBom bom : allBoms) {
                    if (bom != null && bom.getServiceProductId() != null) {
                        bomsByServiceId.computeIfAbsent(bom.getServiceProductId(), k -> new ArrayList<>()).add(bom);
                        if (bom.getMaterialProductId() != null && !productByIdMap.containsKey(bom.getMaterialProductId())) {
                            missingMaterialIds.add(bom.getMaterialProductId());
                        }
                    }
                }
                if (!missingMaterialIds.isEmpty()) {
                    for (Product mat : productRepository.findAllById(missingMaterialIds)) {
                        if (mat != null && mat.getId() != null) {
                            productByIdMap.put(mat.getId(), mat);
                        }
                    }
                }
            }

            for (int idx = 0; idx < itemsToDeduct.size(); idx++) {
                CheckoutCommand.CheckoutItem item = itemsToDeduct.get(idx);
                int qty = (item.getQuantity() != null && item.getQuantity() > 0) ? item.getQuantity() : 1;
                Product product = resolvedProducts.get(idx);

                if (product != null) {
                    if (product.getProductType() != ProductType.SERVICE) {
                        // 实物商品、零售商品或消耗品：直接扣减物理库存
                        product.deductStock(qty);
                        productRepository.save(product);
                        log.info("【收银实物库存扣减成功】订单={}, 商品ID={}, 名称={}, 扣减数量={}, 剩余库存={}",
                                order.getOrderNo(), product.getId(), product.getName(), qty, product.getStock());
                    } else {
                        // 服务项目：查询其配置关联的 BOM 耗材配方进行联动消耗扣减
                        List<ProductBom> boms = bomsByServiceId.get(product.getId());
                        if (boms != null && !boms.isEmpty()) {
                            for (ProductBom bom : boms) {
                                if (bom.getMaterialProductId() != null) {
                                    Product material = productByIdMap.get(bom.getMaterialProductId());
                                    if (material != null) {
                                        BigDecimal consume = bom.getConsumeQuantity() != null
                                                ? bom.getConsumeQuantity().multiply(BigDecimal.valueOf(qty))
                                                : BigDecimal.valueOf(qty);
                                        int consumeCount = consume.intValue() > 0 ? consume.intValue() : qty;
                                        material.deductStock(consumeCount);
                                        productRepository.save(material);
                                        log.info("【服务BOM耗材库存联动扣减成功】订单={}, 服务项={}, 原料ID={}, 名称={}, 消耗数量={}, 剩余库存={}",
                                                order.getOrderNo(), product.getName(), material.getId(), material.getName(), consumeCount, material.getStock());
                                    }
                                }
                            }
                        }
                    }
                } else {
                    log.warn("【结账扣减库存警告】未在商品库中找到对应商品：productId={}, productCode={}, productName={}",
                            item.getProductId(), item.getProductCode(), item.getProductName());
                }
            }
        } catch (Exception e) {
            log.error("【结账商品库存扣减异常】订单号={}, 异常原因: {}", order.getOrderNo(), e.getMessage(), e);
        }
    }

    private String storeIdOrDefault(BillingOrder order) {
        return order.getStoreId();
    }
}
