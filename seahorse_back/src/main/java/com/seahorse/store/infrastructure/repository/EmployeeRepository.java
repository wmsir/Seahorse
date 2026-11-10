package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.enums.EmployeeRole;
import com.seahorse.store.domain.iam.model.Employee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EmployeeRepository extends JpaRepository<Employee, Long> {
    Optional<Employee> findByUsername(String username);
    List<Employee> findByTenantId(String tenantId);
    List<Employee> findByTenantIdAndStoreId(String tenantId, String storeId);
    List<Employee> findByStoreIdAndRole(String storeId, EmployeeRole role);
    List<Employee> findByTenantIdAndIsDeleted(String tenantId, Boolean isDeleted);
    List<Employee> findByStoreIdAndIsDeleted(String storeId, Boolean isDeleted);
    List<Employee> findByPhone(String phone);
    Optional<Employee> findByTenantIdAndPhone(String tenantId, String phone);
}
