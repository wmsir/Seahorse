package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.attendance.model.AttendanceRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AttendanceRecordRepository extends JpaRepository<AttendanceRecord, Long> {
    Optional<AttendanceRecord> findByRecordNo(String recordNo);
    List<AttendanceRecord> findByTenantIdOrderByWorkDateDescIdDesc(String tenantId);
    List<AttendanceRecord> findByTenantIdAndStoreIdOrderByWorkDateDescIdDesc(String tenantId, String storeId);
}
