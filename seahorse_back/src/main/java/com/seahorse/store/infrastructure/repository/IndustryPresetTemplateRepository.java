package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.model.IndustryPresetTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface IndustryPresetTemplateRepository extends JpaRepository<IndustryPresetTemplate, Long> {

    Optional<IndustryPresetTemplate> findByIndustry(String industry);

    boolean existsByIndustry(String industry);
}
