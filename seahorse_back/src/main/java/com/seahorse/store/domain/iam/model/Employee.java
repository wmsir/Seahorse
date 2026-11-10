package com.seahorse.store.domain.iam.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.seahorse.store.domain.iam.enums.EmployeeRole;
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
@Table(name = "sh_employee")
@EntityListeners(AuditingEntityListener.class)
public class Employee {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(length = 64)
    private String storeId;

    @Column(nullable = false, unique = true, length = 64)
    private String username;

    @JsonIgnore
    private String password;

    @Column(nullable = false, length = 64)
    private String realName;

    // 店内称呼 / 艺名 / 服务对外称谓 (例如: 真实姓名“张三”，店内称呼“小美”)
    @Column(length = 64)
    private String nickname;

    private String phone;
    private String avatar;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private EmployeeRole role;

    // 岗位名称 (例如：资深发型师、发型助理、发型总监、行政主厨等)
    private String postName;

    private String gender; // MALE, FEMALE
    private String idCard;
    private BigDecimal baseSalary; // 基本底薪

    // 默认提成比率（例如 0.20 代表 20%）
    private BigDecimal defaultCommissionRate;

    private String status; // ACTIVE, DISABLED, PENDING_REVIEW
    private Boolean isDeleted; // 是否已删除（支持恢复删除员工）

    // 部门归属 (例如：店务管理部、美业设计部、前台客服部等)
    private String department;

    // 自主入职审核状态 (PENDING: 待审核, APPROVED: 已批准, REJECTED: 已驳回)
    private String auditStatus;

    // 是否为扫码自主申请入职
    private Boolean isSelfApplied;

    // 从业经验与特长描述
    @Column(length = 1024)
    private String experience;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
