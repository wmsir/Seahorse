package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.leave.model.LeaveApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface LeaveApplicationRepository extends JpaRepository<LeaveApplication, String> {
    List<LeaveApplication> findByTenantIdOrderByCreatedAtDesc(String tenantId);
    List<LeaveApplication> findByTenantIdAndStatusOrderByCreatedAtDesc(String tenantId, String status);
    List<LeaveApplication> findByStoreIdOrderByCreatedAtDesc(String storeId);
    List<LeaveApplication> findByStoreIdInOrderByCreatedAtDesc(Collection<String> storeIds);
    List<LeaveApplication> findByPhoneOrderByCreatedAtDesc(String phone);
    List<LeaveApplication> findByTenantIdAndPhoneOrderByCreatedAtDesc(String tenantId, String phone);
    List<LeaveApplication> findAllByOrderByCreatedAtDesc();
}
