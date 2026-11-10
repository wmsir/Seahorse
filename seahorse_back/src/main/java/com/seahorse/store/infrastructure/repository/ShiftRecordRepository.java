package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.billing.model.ShiftRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ShiftRecordRepository extends JpaRepository<ShiftRecord, Long> {
    List<ShiftRecord> findByStoreIdOrderByCreatedAtDesc(String storeId);
    Optional<ShiftRecord> findFirstByCashierIdAndStatusOrderByCreatedAtDesc(Long cashierId, String status);
}
