package com.seahorse.store.interfaces.web.vo;

import com.seahorse.store.domain.iam.enums.EmployeeRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.List;

/**
 * 角色权限配置视图对象 VO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RolePermissionVO implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long id;
    private String tenantId;
    private EmployeeRole roleCode;
    private String roleName;
    private List<String> permissions;
    private String description;
    private Boolean isCustom;
    private List<PermissionItemVO> availablePermissions;
}
