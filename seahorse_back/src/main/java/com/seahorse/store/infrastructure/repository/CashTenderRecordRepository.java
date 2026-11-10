package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.billing.model.CashTenderRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CashTenderRecordRepository extends JpaRepository<CashTenderRecord, Long> {
    Optional<CashTenderRecord> findByBillingOrderId(Long billingOrderId);
}
