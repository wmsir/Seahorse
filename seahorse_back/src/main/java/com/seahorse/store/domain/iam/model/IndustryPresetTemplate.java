package com.seahorse.store.domain.iam.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * 全系统常用行业预设全景配置实体
 * 包含 7 大行业由超级管理员统一部署的标准模板：
 * 1. 会员卡设置与等级折扣方案 (cardTemplatesJson)
 * 2. 顾客个人常态偏好配置标签库 (preferenceTagsJson)
 * 3. 开卡首充与充多少送多少方案 (chargeOptionsJson)
 * 4. 常用部门架构列表 (departmentsJson)
 * 5. 常用在编岗位编制与薪资提成 (positionsJson)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_industry_preset_template")
@EntityListeners(AuditingEntityListener.class)
public class IndustryPresetTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 32)
    private String industry; // BEAUTY, RESTAURANT, FOOT_SPA, AUTO, TEA_HOUSE, PET, RETAIL

    @Column(nullable = false, length = 64)
    private String industryName; // 美容美发美甲, 餐饮美食/饮品, 足道养生/推拿SPA, 汽车维保/改装洗美, 商务茶楼/棋牌雅集, 宠物生活/医疗洗护, 综合零售/商超专卖

    @Column(columnDefinition = "LONGTEXT")
    private String cardTemplatesJson; // 会员卡与等级体系 JSON

    @Column(columnDefinition = "LONGTEXT")
    private String preferenceTagsJson; // 顾客个人常态偏好标签 JSON

    @Column(columnDefinition = "LONGTEXT")
    private String chargeOptionsJson; // 开卡首充方案 JSON

    @Column(columnDefinition = "LONGTEXT")
    private String departmentsJson; // 常用部门列表 JSON

    @Column(columnDefinition = "LONGTEXT")
    private String positionsJson; // 常用在编岗位编制 JSON

    private String updatedBy;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
