package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.model.IndustryCategoryConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IndustryCategoryRepository extends JpaRepository<IndustryCategoryConfig, Integer> {
    List<IndustryCategoryConfig> findAllByOrderBySortOrderAsc();
    List<IndustryCategoryConfig> findByGroupNameOrderBySortOrderAsc(String groupName);
}
