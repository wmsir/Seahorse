package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import com.seahorse.store.domain.iam.model.SubscriptionPlanConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SubscriptionPlanConfigRepository extends JpaRepository<SubscriptionPlanConfig, Long> {

    Optional<SubscriptionPlanConfig> findByPlanCode(SubscriptionPlan planCode);

    List<SubscriptionPlanConfig> findByStatusOrderBySortOrderAsc(String status);

    List<SubscriptionPlanConfig> findAllByOrderBySortOrderAsc();

    Optional<SubscriptionPlanConfig> findByIsDefaultTrue();
}
