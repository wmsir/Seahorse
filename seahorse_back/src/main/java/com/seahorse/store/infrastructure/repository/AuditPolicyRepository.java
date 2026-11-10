package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.audit.model.AuditPolicy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AuditPolicyRepository extends JpaRepository<AuditPolicy, Long> {
    Optional<AuditPolicy> findFirstByOrderByIdAsc();
}
