package com.seahorse.store.infrastructure.repository;

import com.seahorse.store.domain.product.model.ProductBom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface ProductBomRepository extends JpaRepository<ProductBom, Long> {
    List<ProductBom> findByServiceProductId(Long serviceProductId);
    List<ProductBom> findByServiceProductIdIn(Collection<Long> serviceProductIds);
}
