package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.billing.enums.BillingStatus;
import com.seahorse.store.domain.billing.model.BillingOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface BillingOrderRepository extends JpaRepository<BillingOrder, Long> {
    Optional<BillingOrder> findByOrderNo(String orderNo);
    Optional<BillingOrder> findBySessionId(Long sessionId);
    List<BillingOrder> findByStoreIdAndStatus(String storeId, BillingStatus status);
    List<BillingOrder> findByStoreIdAndSettledAtBetween(String storeId, LocalDateTime start, LocalDateTime end);
    List<BillingOrder> findByStoreIdOrderByCreatedAtDesc(String storeId);
    List<BillingOrder> findByMemberIdOrderByCreatedAtDesc(Long memberId);
}
