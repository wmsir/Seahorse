package com.seahorse.store.domain.iam.model;

import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * SaaS 会员套餐版本与定价/试用期配置实体
 * 支持系统开发商在后台页面灵活配置试用期天数（如3天、7天）与会员价格
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_subscription_plan_config")
@EntityListeners(AuditingEntityListener.class)
public class SubscriptionPlanConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, unique = true, length = 32)
    private SubscriptionPlan planCode;

    @Column(nullable = false, length = 64)
    private String planName;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal annualPrice;

    @Column(nullable = false)
    private Integer trialDays;

    @Column(nullable = false)
    @Builder.Default
    private Integer storeLimit = 1;

    @Column(nullable = false)
    @Builder.Default
    private Integer staffLimit = 3;

    @Column(nullable = false)
    @Builder.Default
    private Integer storageQuotaGb = 5;

    @Column(length = 500)
    private String features;

    private Boolean isDefault;

    @Column(nullable = false, length = 32)
    private String status;

    private Integer sortOrder;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
