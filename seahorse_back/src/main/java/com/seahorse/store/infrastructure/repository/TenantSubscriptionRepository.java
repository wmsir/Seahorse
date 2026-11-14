package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.model.TenantSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface TenantSubscriptionRepository extends JpaRepository<TenantSubscription, Long> {
    Optional<TenantSubscription> findByTenantId(String tenantId);
    List<TenantSubscription> findByTenantIdIn(Collection<String> tenantIds);
    List<TenantSubscription> findByStatus(String status);
    List<TenantSubscription> findByExpireDateLessThanEqual(LocalDate date);
    List<TenantSubscription> findByExpireDateBetween(LocalDate start, LocalDate end);

    @Query("SELECT s FROM TenantSubscription s WHERE s.status IS NULL OR UPPER(s.status) <> 'DELETED'")
    List<TenantSubscription> findActiveSubscriptions();
}
