package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.dto.billing.BillingSummaryVO;
import com.seahorse.store.application.dto.billing.CheckoutCommand;
import com.seahorse.store.application.service.BillingCheckoutAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.infrastructure.repository.BillingOrderRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 结算收银接入控制器
 * 符合阿里巴巴与DDD接口层命名规范
 */
@Tag(name = "03. 交易与收银结算", description = "账单汇总、全渠道组合混合拆分支付、现金找零与钱箱开箱")
@RestController
@RequestMapping("/api/billing")
@RequiredArgsConstructor
public class BillingCheckoutController {

    private final BillingCheckoutAppService checkoutAppService;
    private final BillingOrderRepository billingOrderRepository;
    private final com.seahorse.store.application.service.AuditLogAppService auditLogAppService;
    private final jakarta.servlet.http.HttpServletRequest request;

    @Operation(summary = "发起买单结账请求 (核算账单总额与附加费)")
    @PostMapping("/request/{sessionId}")
    public ApiResponse<BillingOrder> requestBilling(@PathVariable("sessionId") Long sessionId) {
        BillingOrder order = checkoutAppService.requestBilling(sessionId);
        return ApiResponse.success("账单生成成功", order);
    }

    @Operation(summary = "执行多通道组合结账 (支持微信/支付宝/储值扣减/次卡核销/现金找零)")
    @PostMapping("/checkout")
    public ApiResponse<BillingSummaryVO> executeCheckout(@RequestBody CheckoutCommand cmd) {
        BillingSummaryVO summary = checkoutAppService.executeCheckout(cmd);
        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = com.seahorse.store.context.TenantContext.getUsername() != null ? com.seahorse.store.context.TenantContext.getUsername() : "cashier";
        java.math.BigDecimal finalAmt = (summary.getOrder() != null && summary.getOrder().getActualAmount() != null)
                ? summary.getOrder().getActualAmount() : java.math.BigDecimal.ZERO;
        Long orderId = summary.getOrder() != null ? summary.getOrder().getId() : null;
        auditLogAppService.recordLog(
                com.seahorse.store.context.TenantContext.getTenantId(),
                null,
                com.seahorse.store.context.TenantContext.getStoreId(),
                null,
                null,
                username,
                null,
                "前台收银结账",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("订单结账: #%s, 实收总额: ￥%s", orderId != null ? orderId : "-", finalAmt)
        );
        return ApiResponse.success("结算成功", summary);
    }

    @Operation(summary = "查看订单结算详尽结果")
    @GetMapping("/{orderId}")
    public ApiResponse<BillingOrder> getBillingOrder(@PathVariable("orderId") Long orderId) {
        return billingOrderRepository.findById(orderId)
                .map(order -> {
                    com.seahorse.store.context.TenantContext.assertTenantAccess(order.getTenantId());
                    return ApiResponse.success(order);
                })
                .orElse(ApiResponse.error(404, "订单不存在"));
    }
}
