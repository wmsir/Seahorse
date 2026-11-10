package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.session.model.PerformerShare;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PerformerShareRepository extends JpaRepository<PerformerShare, Long> {
    List<PerformerShare> findBySessionId(Long sessionId);
    List<PerformerShare> findByLineItemId(Long lineItemId);
    List<PerformerShare> findByEmployeeId(Long employeeId);
}
