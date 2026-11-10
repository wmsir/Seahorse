package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.notification.model.NotificationLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationLogRepository extends JpaRepository<NotificationLog, Long> {
    List<NotificationLog> findTop100ByTenantIdOrderBySentAtDesc(String tenantId);
    List<NotificationLog> findByTenantIdAndMemberIdOrderBySentAtDesc(String tenantId, Long memberId);
    Page<NotificationLog> findByTenantIdOrderBySentAtDesc(String tenantId, Pageable pageable);
}
