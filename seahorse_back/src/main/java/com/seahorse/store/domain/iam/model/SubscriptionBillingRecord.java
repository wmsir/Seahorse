package com.seahorse.store.domain.iam.model;

import com.seahorse.store.domain.iam.enums.SubscriptionBillingType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * SaaS 订阅与存储服务费交费流水记录实体
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_subscription_billing_record")
@EntityListeners(AuditingEntityListener.class)
public class SubscriptionBillingRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 64)
    private String recordNo;

    @Column(nullable = false, length = 64)
    private String tenantId;

    private String tenantName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private SubscriptionBillingType billingType; // PLAN_SUBSCRIPTION, STORAGE_SERVICE

    @Column(nullable = false)
    private BigDecimal amount; // 交费金额

    private Integer storageGbGranted; // 若为存储服务费，增加的GB数

    private Integer durationMonths; // 购买/续费月数

    private LocalDate periodStart; // 费用覆盖开始日期
    private LocalDate periodEnd; // 费用覆盖到期日期

    @Column(nullable = false)
    private LocalDateTime payTime; // 实际交费入账时间

    private String paymentMethod; // WECHAT, ALIPAY, BANK_TRANSFER, OFFLINE
    private String operator; // 经办人/开发商管理员
    private String notes; // 备注说明

    @CreatedDate
    private LocalDateTime createdAt;
}
