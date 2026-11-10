package com.seahorse.store.domain.billing.model;

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
@Table(name = "sh_shift_record")
@EntityListeners(AuditingEntityListener.class)
public class ShiftRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false, length = 64)
    private String storeId;

    @Column(nullable = false)
    private Long cashierId;

    private String cashierName;

    private LocalDateTime shiftStartTime;
    private LocalDateTime shiftEndTime;

    // 盲盘数据
    private BigDecimal blindCashAmount; // 收银员交班盲盘清点录入现金
    private BigDecimal systemCashAmount; // 系统记录现金理论应有总额
    private BigDecimal cashVariance; // 长短款差额 (盲盘 - 系统理论)

    // 各渠道汇总
    private BigDecimal wechatTotal;
    private BigDecimal alipayTotal;
    private BigDecimal unionPayTotal;
    private BigDecimal storedValueTotal;
    private Integer timeCardTimesTotal;
    private Integer orderCount;

    @Enumerated(EnumType.STRING)
    @Column(length = 32)
    private com.seahorse.store.domain.billing.enums.ShiftStatus status; // NORMAL, VARIANCE, PENDING

    private String notes; // 交班说明与备忘

    @CreatedDate
    private LocalDateTime createdAt;
}
