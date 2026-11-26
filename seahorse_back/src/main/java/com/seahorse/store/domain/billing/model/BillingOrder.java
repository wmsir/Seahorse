package com.seahorse.store.domain.billing.model;

import com.seahorse.store.domain.billing.enums.BillingStatus;
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

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_billing_order")
@EntityListeners(AuditingEntityListener.class)
public class BillingOrder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false, length = 64)
    private String storeId;

    @Column(nullable = false, unique = true, length = 64)
    private String orderNo;

    private Long sessionId;
    private String sessionNo;

    private Long spaceId;
    private String spaceName;

    private Long memberId;
    private String customerName;
    private String customerPhone;

    @Column(nullable = false)
    private BigDecimal totalAmount;

    private BigDecimal feeAmount; // 附加费
    private BigDecimal discountAmount;

    @Column(nullable = false)
    private BigDecimal actualAmount; // 应收实收

    private BigDecimal paidAmount; // 已支付总和

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private BillingStatus status;

    private Long cashierId;
    private String cashierName;

    private LocalDateTime settledAt;

    @Version
    @Column(nullable = false)
    private Long version; // JPA 乐观锁版本号

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public boolean isFullyPaid() {
        if (paidAmount == null || actualAmount == null) return false;
        return paidAmount.compareTo(actualAmount) >= 0;
    }
}
