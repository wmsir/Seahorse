package com.seahorse.store.domain.commission.model;

import com.seahorse.store.domain.commission.enums.CommissionStatus;
import com.seahorse.store.domain.commission.enums.CommissionType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_commission_record")
@EntityListeners(AuditingEntityListener.class)
public class CommissionRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false, length = 64)
    private String storeId;

    @Column(nullable = false)
    private Long employeeId;

    private String employeeName;

    private Long billingOrderId;
    private Long lineItemId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private CommissionType commissionType;

    private BigDecimal baseAmount; // 提成基准业绩金额
    private BigDecimal commissionRate; // 提成比例
    private BigDecimal commissionAmount; // 实际应得提成金额

    private String notes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private CommissionStatus status; // RECORDED, SETTLED

    @CreatedDate
    private LocalDateTime createdAt;
}
