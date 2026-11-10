package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.billing.enums.PaymentChannel;
import com.seahorse.store.domain.billing.model.PaymentRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PaymentRecordRepository extends JpaRepository<PaymentRecord, Long> {
    List<PaymentRecord> findByBillingOrderId(Long billingOrderId);
    List<PaymentRecord> findByPayTimeBetween(LocalDateTime start, LocalDateTime end);
    List<PaymentRecord> findByChannelAndPayTimeBetween(PaymentChannel channel, LocalDateTime start, LocalDateTime end);
}
