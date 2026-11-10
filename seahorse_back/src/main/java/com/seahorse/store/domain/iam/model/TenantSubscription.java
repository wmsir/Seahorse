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
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * 商户 SaaS 会员订阅合约实体
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_tenant_subscription")
@EntityListeners(AuditingEntityListener.class)
public class TenantSubscription {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 64)
    private String tenantId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private SubscriptionPlan plan; // TRIAL, PROFESSIONAL, FLAGSHIP, ENTERPRISE

    @Column(nullable = false)
    private Integer storeLimit; // 允许开设的最大门店数

    @Column(nullable = false)
    @Builder.Default
    private Integer staffLimit = 3; // 允许录入的在岗员工数上限

    @Column(nullable = false)
    private Integer storageQuotaGb; // 云存储空间配额(GB)

    @Column(nullable = false)
    private LocalDate startDate; // 订阅生效起始日

    @Column(nullable = false)
    private LocalDate expireDate; // 订阅到期日

    private BigDecimal feePaid; // 累计已缴纳套餐费

    @Column(nullable = false, length = 32)
    private String status; // ACTIVE(正常有效), EXPIRING(即将到期), EXPIRED(已逾期停用)

    private Boolean autoRenew;
    private String notes;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    /**
     * 计算距到期剩余天数（若已到期则为负数）
     */
    public long getDaysRemaining() {
        if (expireDate == null) {
            return 0;
        }
        return ChronoUnit.DAYS.between(LocalDate.now(), expireDate);
    }

    /**
     * 判断是否即将到期（30天以内）
     */
    public boolean isExpiringSoon() {
        long days = getDaysRemaining();
        return days >= 0 && days <= 30;
    }

    /**
     * 判断是否已过期
     */
    public boolean isExpired() {
        return getDaysRemaining() < 0;
    }
}
