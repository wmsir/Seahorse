package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.model.Store;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StoreRepository extends JpaRepository<Store, Long> {
    Optional<Store> findByStoreId(String storeId);
    Optional<Store> findByStoreIdAndTenantId(String storeId, String tenantId);
    List<Store> findByTenantId(String tenantId);
    List<Store> findByPhoneContaining(String phone);
}
