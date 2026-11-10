package com.seahorse.store.application.dto.vendor;

import com.seahorse.store.domain.iam.enums.SubscriptionPlan;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 修改SaaS会员套餐定价与试用期命令对象
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdatePlanConfigCommand {
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
}
