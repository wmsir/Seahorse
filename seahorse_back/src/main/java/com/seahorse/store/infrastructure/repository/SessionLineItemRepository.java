package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.session.model.SessionLineItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SessionLineItemRepository extends JpaRepository<SessionLineItem, Long> {
    List<SessionLineItem> findBySessionId(Long sessionId);
    List<SessionLineItem> findByBatchId(Long batchId);
    List<SessionLineItem> findBySessionIdAndStatus(Long sessionId, String status);
}
