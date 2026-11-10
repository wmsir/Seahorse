package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.commission.model.CommissionRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommissionRecordRepository extends JpaRepository<CommissionRecord, Long> {
    List<CommissionRecord> findByEmployeeId(Long employeeId);
    List<CommissionRecord> findByEmployeeIdOrderByCreatedAtDesc(Long employeeId);
    List<CommissionRecord> findByEmployeeNameOrderByCreatedAtDesc(String employeeName);
    List<CommissionRecord> findByStoreIdAndEmployeeNameOrderByCreatedAtDesc(String storeId, String employeeName);
    List<CommissionRecord> findByBillingOrderId(Long billingOrderId);
    List<CommissionRecord> findByStoreIdOrderByCreatedAtDesc(String storeId);
}
