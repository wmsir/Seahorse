package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.model.Tenant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface TenantRepository extends JpaRepository<Tenant, Long> {
    Optional<Tenant> findByTenantId(String tenantId);
    List<Tenant> findByTenantIdIn(Collection<String> tenantIds);
    List<Tenant> findByContactPhoneContaining(String contactPhone);

    @Query("SELECT t FROM Tenant t WHERE UPPER(t.tenantId) <> 'PLATFORM' " +
           "AND (t.status IS NULL OR UPPER(t.status) <> 'DELETED') " +
           "AND (:kw IS NULL OR :kw = '' " +
           "OR LOWER(COALESCE(t.tenantName, '')) LIKE LOWER(CONCAT('%', :kw, '%')) " +
           "OR LOWER(COALESCE(t.contactName, '')) LIKE LOWER(CONCAT('%', :kw, '%')) " +
           "OR COALESCE(t.contactPhone, '') LIKE CONCAT('%', :kw, '%') " +
           "OR LOWER(t.tenantId) LIKE LOWER(CONCAT('%', :kw, '%')))")
    List<Tenant> searchActiveTenants(@Param("kw") String kw);

    @Query("SELECT COUNT(t) FROM Tenant t WHERE t.status IS NULL OR UPPER(t.status) <> 'DELETED'")
    long countNonDeletedTenants();
}
