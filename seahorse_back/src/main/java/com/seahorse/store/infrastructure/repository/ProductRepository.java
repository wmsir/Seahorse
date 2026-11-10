package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.product.enums.ProductType;
import com.seahorse.store.domain.product.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    Optional<Product> findByProductCode(String productCode);
    Optional<Product> findByStoreIdAndProductCode(String storeId, String productCode);
    Optional<Product> findByTenantIdAndProductCode(String tenantId, String productCode);
    List<Product> findByTenantId(String tenantId);
    long countByTenantId(String tenantId);
    List<Product> findByStoreIdAndAvailableTrue(String storeId);
    List<Product> findByStoreIdAndProductType(String storeId, ProductType productType);
    List<Product> findByCategoryId(Long categoryId);
}
