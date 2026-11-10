package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.session.enums.SpaceStatus;
import com.seahorse.store.domain.session.enums.SpaceType;
import com.seahorse.store.domain.session.model.ServiceSpace;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ServiceSpaceRepository extends JpaRepository<ServiceSpace, Long> {
    List<ServiceSpace> findByTenantIdAndStoreId(String tenantId, String storeId);
    List<ServiceSpace> findByTenantId(String tenantId);
    long countByTenantId(String tenantId);
    List<ServiceSpace> findByStoreId(String storeId);
    List<ServiceSpace> findByStoreIdAndStatus(String storeId, SpaceStatus status);
    List<ServiceSpace> findByStoreIdAndSpaceType(String storeId, SpaceType spaceType);
    Optional<ServiceSpace> findByStoreIdAndSpaceCode(String storeId, String spaceCode);
}
