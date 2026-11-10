package com.seahorse.store.domain.iam.model;

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
 * 员工奖罚记录
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_staff_reward_punish")
@EntityListeners(AuditingEntityListener.class)
public class StaffRewardPunish {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false)
    private Long employeeId;

    @Column(nullable = false, length = 64)
    private String employeeName;

    @Column(nullable = false, length = 32)
    private String type; // REWARD (奖励), PUNISH (扣罚)

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal amount;

    private String reason; // 奖罚原因 / 说明

    private LocalDate recordDate; // 发生日期

    private String operator; // 操作人

    @CreatedDate
    private LocalDateTime createdAt;
}
