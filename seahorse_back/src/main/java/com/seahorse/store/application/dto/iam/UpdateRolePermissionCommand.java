package com.seahorse.store.application.dto.iam;

import com.seahorse.store.domain.iam.enums.EmployeeRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.List;

/**
 * 角色权限配置修改命令
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateRolePermissionCommand implements Serializable {
    private static final long serialVersionUID = 1L;

    private EmployeeRole roleCode;
    private List<String> permissions;
    private String description;
}
