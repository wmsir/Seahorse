package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.audit.model.SecurityAuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface SecurityAuditLogRepository extends JpaRepository<SecurityAuditLog, Long> {
    Page<SecurityAuditLog> findByTenantIdOrderByCreatedAtDesc(String tenantId, Pageable pageable);
    
    @Query("SELECT l FROM SecurityAuditLog l WHERE (:tenantId IS NULL OR :tenantId = '' OR :tenantId = 'PLATFORM' OR l.tenantId = :tenantId) " +
           "AND (:username IS NULL OR :username = '' OR l.username = :username OR l.realName = :username OR l.username LIKE %:username% OR l.realName LIKE %:username%) " +
           "AND (:keyword IS NULL OR :keyword = '' OR l.username LIKE %:keyword% OR l.realName LIKE %:keyword% OR l.action LIKE %:keyword% OR l.ip LIKE %:keyword% OR l.device LIKE %:keyword% OR l.notes LIKE %:keyword% OR l.actionType LIKE %:keyword%) " +
           "ORDER BY l.createdAt DESC")
    Page<SecurityAuditLog> searchLogs(@Param("tenantId") String tenantId, @Param("username") String username, @Param("keyword") String keyword, Pageable pageable);

    @Modifying
    @Query("DELETE FROM SecurityAuditLog l WHERE (:tenantId IS NULL OR :tenantId = '' OR :tenantId = 'PLATFORM' OR l.tenantId = :tenantId)")
    void clearLogsByTenant(@Param("tenantId") String tenantId);
}
