package com.seahorse.store.domain.iam.model;

import com.seahorse.store.domain.iam.enums.EmployeeRole;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 角色权限配置领域模型
 * 支持两级配置：
 * 1. tenantId = "PLATFORM"：系统开发维护人配置的全平台角色默认权限与查看范围；
 * 2. tenantId = "{具体商户ID}"：会员门店老板为本店店员定制的专属权限覆盖规则。
 */
@Data
@Entity
@Table(name = "sh_role_permission_config")
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RolePermissionConfig implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 租户标识: "PLATFORM" 为平台开发商全局模板, 其他为特定商户老板定制规则
     */
    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    /**
     * 角色枚举
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "role_code", nullable = false, length = 32)
    private EmployeeRole roleCode;

    /**
     * 角色中文名称
     */
    @Column(name = "role_name", nullable = false, length = 64)
    private String roleName;

    /**
     * 授权的功能权限代码列表 (以逗号分隔存储)
     */
    @Column(name = "permissions", columnDefinition = "TEXT")
    private String permissions;

    /**
     * 权限配置说明/描述
     */
    @Column(name = "description", length = 255)
    private String description;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    public void onPrePersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = LocalDateTime.now();
        }
    }

    @PreUpdate
    public void onPreUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public List<String> getPermissionList() {
        if (permissions == null || permissions.trim().isEmpty()) {
            return new ArrayList<>();
        }
        return Arrays.stream(permissions.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    public void setPermissionList(List<String> list) {
        if (list == null || list.isEmpty()) {
            this.permissions = "";
        } else {
            this.permissions = String.join(",", list);
        }
    }
}
