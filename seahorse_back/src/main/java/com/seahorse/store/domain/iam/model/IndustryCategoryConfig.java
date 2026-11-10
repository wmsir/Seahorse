package com.seahorse.store.domain.iam.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 行业分类配置实体 (服务类 / 零售类 细分层级)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_industry_category")
public class IndustryCategoryConfig {
    @Id
    private Integer id;

    @Column(nullable = false, length = 64)
    private String name; // 汽车服务, 美业服务, 便利店, ...

    @Column(nullable = false, length = 64)
    private String groupName; // 服务类 | 零售类

    @Column(length = 32)
    private String defaultIndustryType; // BEAUTY, RESTAURANT, AUTO, RETAIL

    private Integer sortOrder;
}
