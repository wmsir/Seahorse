package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.model.StoreRegisterConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface StoreRegisterConfigRepository extends JpaRepository<StoreRegisterConfig, Long> {
    Optional<StoreRegisterConfig> findByStoreId(String storeId);
    Optional<StoreRegisterConfig> findByStoreIdAndTenantId(String storeId, String tenantId);
}
