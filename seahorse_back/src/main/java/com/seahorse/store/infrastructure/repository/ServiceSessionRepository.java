package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.session.enums.SessionStatus;
import com.seahorse.store.domain.session.model.ServiceSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface ServiceSessionRepository extends JpaRepository<ServiceSession, Long> {
    Optional<ServiceSession> findBySessionNo(String sessionNo);
    Optional<ServiceSession> findBySpaceIdAndStatusNot(Long spaceId, SessionStatus status);
    List<ServiceSession> findBySpaceIdAndStatusIn(Long spaceId, Collection<SessionStatus> statuses);
    List<ServiceSession> findByStoreIdAndStatusIn(String storeId, List<SessionStatus> statuses);
    List<ServiceSession> findByTenantIdAndStatusIn(String tenantId, List<SessionStatus> statuses);
    List<ServiceSession> findByStoreIdOrderByCreatedAtDesc(String storeId);
}
