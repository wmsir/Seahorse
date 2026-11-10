package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.model.StaffRewardPunish;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StaffRewardPunishRepository extends JpaRepository<StaffRewardPunish, Long> {
    List<StaffRewardPunish> findByTenantIdOrderByCreatedAtDesc(String tenantId);
    List<StaffRewardPunish> findByTenantIdAndEmployeeIdOrderByCreatedAtDesc(String tenantId, Long employeeId);
}
