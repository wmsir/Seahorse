package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.product.model.ProductCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductCategoryRepository extends JpaRepository<ProductCategory, Long> {
    List<ProductCategory> findByTenantId(String tenantId);
    List<ProductCategory> findByTenantIdAndIndustry(String tenantId, String industry);
}
