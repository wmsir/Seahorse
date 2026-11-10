package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.model.Employee;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.iam.model.Tenant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TenantRepository extends JpaRepository<Tenant, Long> {
    Optional<Tenant> findByTenantId(String tenantId);
    List<Tenant> findByContactPhoneContaining(String contactPhone);
}
