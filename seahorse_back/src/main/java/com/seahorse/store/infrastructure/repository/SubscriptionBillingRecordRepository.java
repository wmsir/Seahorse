package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.enums.SubscriptionBillingType;
import com.seahorse.store.domain.iam.model.SubscriptionBillingRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface SubscriptionBillingRecordRepository extends JpaRepository<SubscriptionBillingRecord, Long> {
    Optional<SubscriptionBillingRecord> findByRecordNo(String recordNo);
    List<SubscriptionBillingRecord> findByTenantIdOrderByPayTimeDesc(String tenantId);
    List<SubscriptionBillingRecord> findByTenantIdInOrderByPayTimeDesc(Collection<String> tenantIds);
    List<SubscriptionBillingRecord> findByBillingTypeOrderByPayTimeDesc(SubscriptionBillingType billingType);
    List<SubscriptionBillingRecord> findAllByOrderByPayTimeDesc();

    @Query("SELECT r FROM SubscriptionBillingRecord r WHERE (:billingType IS NULL OR r.billingType = :billingType) " +
           "AND r.tenantId IN (SELECT t.tenantId FROM Tenant t WHERE t.status IS NULL OR UPPER(t.status) <> 'DELETED') " +
           "ORDER BY r.payTime DESC")
    List<SubscriptionBillingRecord> findActiveBillingRecords(@Param("billingType") SubscriptionBillingType billingType);

    @Query("SELECT r.billingType, COALESCE(SUM(r.amount), 0) FROM SubscriptionBillingRecord r " +
           "WHERE r.tenantId IN (SELECT t.tenantId FROM Tenant t WHERE t.status IS NULL OR UPPER(t.status) <> 'DELETED') " +
           "GROUP BY r.billingType")
    List<Object[]> sumPaidAmountGroupByBillingType();
}
