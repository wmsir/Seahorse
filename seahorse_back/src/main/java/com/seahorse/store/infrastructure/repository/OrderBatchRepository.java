package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.session.model.OrderBatch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderBatchRepository extends JpaRepository<OrderBatch, Long> {
    List<OrderBatch> findBySessionIdOrderByBatchNoAsc(Long sessionId);
    long countBySessionId(Long sessionId);
}
