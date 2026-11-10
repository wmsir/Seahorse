package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.enums.SubscriptionBillingType;
import com.seahorse.store.domain.iam.model.SubscriptionBillingRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface SubscriptionBillingRecordRepository extends JpaRepository<SubscriptionBillingRecord, Long> {
    Optional<SubscriptionBillingRecord> findByRecordNo(String recordNo);
    List<SubscriptionBillingRecord> findByTenantIdOrderByPayTimeDesc(String tenantId);
    List<SubscriptionBillingRecord> findByBillingTypeOrderByPayTimeDesc(SubscriptionBillingType billingType);
    List<SubscriptionBillingRecord> findByPayTimeBetweenOrderByPayTimeDesc(LocalDateTime start, LocalDateTime end);
    List<SubscriptionBillingRecord> findAllByOrderByPayTimeDesc();
}
