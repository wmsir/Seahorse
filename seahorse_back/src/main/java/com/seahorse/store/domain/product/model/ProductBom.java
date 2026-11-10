package com.seahorse.store.domain.product.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_product_bom")
public class ProductBom {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long serviceProductId; // 计量服务项 ID

    @Column(nullable = false)
    private Long materialProductId; // 消耗的原料耗材商品 ID

    @Column(nullable = false, length = 128)
    private String materialName;

    @Column(nullable = false)
    private BigDecimal consumeQuantity; // 消耗数量

    private String unit; // 单位
}
