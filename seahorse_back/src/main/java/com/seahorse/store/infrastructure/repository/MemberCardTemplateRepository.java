package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.member.model.MemberCardTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MemberCardTemplateRepository extends JpaRepository<MemberCardTemplate, Long> {

    List<MemberCardTemplate> findByTenantIdAndStatusOrderBySortOrderAsc(String tenantId, String status);

    List<MemberCardTemplate> findByTenantIdAndCardTypeAndStatusOrderBySortOrderAsc(String tenantId, String cardType, String status);

    List<MemberCardTemplate> findByTenantIdOrderBySortOrderAsc(String tenantId);
}
