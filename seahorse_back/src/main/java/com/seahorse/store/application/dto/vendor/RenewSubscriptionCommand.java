package com.seahorse.store.application.dto.vendor;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 续费或变更 SaaS 套餐命令对象
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RenewSubscriptionCommand {
    private String tenantId;

    @JsonAlias({"plan", "planCode"})
    private SubscriptionPlan targetPlan;
    private SubscriptionPlan plan;

    private Integer durationMonths; // 续费月数，通常 12 个月

    @JsonAlias({"paidAmount", "price"})
    private BigDecimal amount; // 实收续费金额
    private BigDecimal paidAmount;

    private String paymentMethod; // WECHAT, ALIPAY, BANK_TRANSFER
    private String notes;

    // 可选特批开店与员工配额（若为空则按目标套餐默认最大配额装配）
    private Integer storeLimit;
    private Integer staffLimit;

    public SubscriptionPlan getEffectiveTargetPlan() {
        return targetPlan != null ? targetPlan : plan;
    }

    public BigDecimal getEffectiveAmount() {
        return amount != null ? amount : paidAmount;
    }
}

