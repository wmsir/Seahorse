package com.seahorse.store.domain.audit.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_security_log")
@EntityListeners(AuditingEntityListener.class)
public class SecurityAuditLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    private String tenantName;

    @Column(length = 64)
    private String storeId;

    private String storeName;

    private Long userId;

    @Column(nullable = false, length = 64)
    private String username;

    private String realName;

    @Column(nullable = false, length = 128)
    private String action; // 事件描述，例如: "账号密码登录", "退出系统", "修改登录密码"

    @Column(nullable = false, length = 32)
    private String actionType; // LOGIN, LOGOUT, PASSWORD, SECURITY_LOCK, POLICY_CHANGE, OPERATE

    private String ip; // 客户端IP或端点

    private String device; // 终端浏览器或设备信息

    @Column(nullable = false, length = 32)
    private String status; // SUCCESS, FAILED, BLOCKED

    @Column(length = 500)
    private String notes;

    @CreatedDate
    private LocalDateTime createdAt;
}
