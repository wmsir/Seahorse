package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.model.AmapConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AmapConfigRepository extends JpaRepository<AmapConfig, Long> {
    Optional<AmapConfig> findFirstByTenantIdOrderByIdDesc(String tenantId);
    default Optional<AmapConfig> findByTenantId(String tenantId) {
        return findFirstByTenantIdOrderByIdDesc(tenantId);
    }
    Optional<AmapConfig> findFirstByTenantIdAndStoreIdOrderByIdDesc(String tenantId, String storeId);
    default Optional<AmapConfig> findByTenantIdAndStoreId(String tenantId, String storeId) {
        return findFirstByTenantIdAndStoreIdOrderByIdDesc(tenantId, storeId);
    }
}
