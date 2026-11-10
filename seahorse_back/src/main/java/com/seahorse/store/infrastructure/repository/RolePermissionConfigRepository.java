package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.enums.EmployeeRole;
import com.seahorse.store.domain.iam.model.RolePermissionConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RolePermissionConfigRepository extends JpaRepository<RolePermissionConfig, Long> {

    Optional<RolePermissionConfig> findByTenantIdAndRoleCode(String tenantId, EmployeeRole roleCode);

    List<RolePermissionConfig> findByTenantId(String tenantId);

    List<RolePermissionConfig> findByTenantIdIn(List<String> tenantIds);
}
