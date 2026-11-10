package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.member.model.MemberRechargeRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MemberRechargeRecordRepository extends JpaRepository<MemberRechargeRecord, Long> {
    List<MemberRechargeRecord> findByMemberIdOrderByCreatedAtDesc(Long memberId);
    List<MemberRechargeRecord> findByTenantIdOrderByCreatedAtDesc(String tenantId);
    List<MemberRechargeRecord> findByStoreIdOrderByCreatedAtDesc(String storeId);
}
