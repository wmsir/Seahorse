package com.seahorse.store.interfaces.web.vo;

import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * SaaS 会员套餐版本与定价展示 VO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionPlanConfigVO {
    private Long id;
    private SubscriptionPlan planCode;
    private String planName;
    private BigDecimal annualPrice;
    private Integer trialDays;
    private Integer storeLimit;
    private Integer staffLimit;
    private Integer storageQuotaGb;
    private String features;
    private Boolean isDefault;
    private String status;
    private Integer sortOrder;
    private LocalDateTime updatedAt;
}
