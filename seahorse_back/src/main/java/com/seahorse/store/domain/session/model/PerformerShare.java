package com.seahorse.store.domain.session.model;

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
@Table(name = "sh_performer_share")
@EntityListeners(AuditingEntityListener.class)
public class PerformerShare {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long lineItemId;

    @Column(nullable = false)
    private Long sessionId;

    @Column(nullable = false)
    private Long employeeId;

    private String employeeName;

    // 分摊比例 (例如 0.70 代表 70%，0.30 代表 30%)
    @Column(nullable = false)
    private BigDecimal shareRatio;

    // 计算出的分摊业绩金额
    private BigDecimal performanceAmount;

    // 提成金额
    private BigDecimal commissionAmount;

    @CreatedDate
    private LocalDateTime createdAt;
}
