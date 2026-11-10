package com.seahorse.store.domain.product.model;

import com.seahorse.store.domain.product.enums.ProductType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_product")
@EntityListeners(AuditingEntityListener.class)
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false, length = 64)
    private String storeId;

    @Column(nullable = false, length = 64)
    private String productCode;

    @Column(nullable = false, length = 128)
    private String name;

    private Long categoryId;
    private String categoryName;

    @com.fasterxml.jackson.annotation.JsonAlias({"type"})
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private ProductType productType;

    @Column(nullable = false)
    private BigDecimal price; // 销售单价

    private BigDecimal costPrice; // 成本价
    private Integer stock; // 物理库存（实物与耗材有效，服务项为null）
    private String unit; // 单位：次、瓶、包、份、升
    private String imageUrl;
    private String description;

    // 默认执行时长（分钟，用于美发、汽修服务工时）
    private Integer durationMinutes;

    // 默认提成金额（一口价）或百分比
    private BigDecimal defaultCommission;

    @Column(name = "is_available")
    private Boolean available;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public void deductStock(int count) {
        if (this.productType != ProductType.SERVICE) {
            if (this.stock == null) {
                this.stock = 0;
            }
            this.stock = Math.max(0, this.stock - count);
        }
    }

    public Boolean getIsAvailable() {
        return this.available;
    }

    public void setIsAvailable(Boolean available) {
        this.available = available;
    }
}
