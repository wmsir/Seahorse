package com.seahorse.store.domain.audit.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_audit_policy")
@EntityListeners(AuditingEntityListener.class)
public class AuditPolicy {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Boolean enabled; // 全局审计总开关，默认 true

    @Column(length = 32)
    private String mode; // ALL (默认全员记录), EXCLUDE (黑名单模式), INCLUDE (白名单模式)

    @Column(columnDefinition = "TEXT")
    private String excludedTenantIds; // 黑名单租户ID，英文逗号分隔

    @Column(columnDefinition = "TEXT")
    private String excludedStoreIds; // 黑名单门店ID，英文逗号分隔

    @Column(columnDefinition = "TEXT")
    private String includedTenantIds; // 白名单租户ID，英文逗号分隔

    @Column(columnDefinition = "TEXT")
    private String includedStoreIds; // 白名单门店ID，英文逗号分隔

    private Boolean recordLogins; // 是否记录登录事件 (默认 true)

    private Boolean recordOperations; // 是否记录敏感业务操作 (默认 true)

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
