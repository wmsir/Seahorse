package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.recruitment.model.JobApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface JobApplicationRepository extends JpaRepository<JobApplication, Long> {
    Optional<JobApplication> findByApplicationNo(String applicationNo);
    List<JobApplication> findByTenantIdOrderByIdDesc(String tenantId);
}
