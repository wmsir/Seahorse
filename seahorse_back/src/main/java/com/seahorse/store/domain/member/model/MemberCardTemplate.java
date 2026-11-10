package com.seahorse.store.domain.member.model;

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

/**
 * 会员卡项模版配置实体
 * 支持次卡、储值卡、时长卡、独立储值卡、盲盒卡、权益卡
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_member_card_template")
@EntityListeners(AuditingEntityListener.class)
public class MemberCardTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(length = 64)
    private String storeId;

    @Column(nullable = false, length = 64)
    private String cardType; // TIME_CARD | STORED_VALUE | DURATION_CARD | INDEPENDENT_STORED_CARD | BLIND_BOX_CARD | BENEFIT_CARD

    @Column(nullable = false, length = 64)
    private String cardTypeName; // 储值卡 | 次卡 | 时长卡 | 独立储值卡 | 盲盒卡 | 权益卡

    @Column(nullable = false, length = 128)
    private String cardName; // 卡项名称，如“300元8折轻奢储值卡”

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price; // 卡项售价

    @Column(precision = 10, scale = 2)
    private BigDecimal originalPrice; // 原价/参考面额

    @Column(length = 512)
    private String contentDescription; // 包含内容，如“可用金额:300.00”、“包含项目/服务次数: 精细洗车 × 10”

    @Column(precision = 10, scale = 2)
    private BigDecimal principalAmount; // 储值卡本金

    @Column(precision = 10, scale = 2)
    private BigDecimal giftAmount; // 储值卡赠送金额

    @Column(precision = 5, scale = 2)
    private BigDecimal discountRate; // 折扣率（如 0.80 为 8折，1.00 为无折扣）

    private Integer totalTimes; // 次卡服务总次数

    private Integer validityDays; // 有效天数 (0=长期有效)

    private Long serviceSkuId; // 关联服务工时/商品 SKU ID

    @Column(length = 128)
    private String serviceSkuName; // 关联服务项目名称

    @Column(length = 32)
    private String status; // ACTIVE(启用), INACTIVE(下架/禁用)

    private Integer sortOrder; // 排序权重

    @Column(length = 512)
    private String notes; // 卡项说明与权益备注

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
