package com.seahorse.store.interfaces.web.vo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Map;

/**
 * 开发商运营与财务综合统计大盘 VO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VendorDashboardStatsVO implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long totalTenants; // 注册商户总数
    private Long totalMembers; // 全平台注册会员总数 (海马体会员总量)
    private Long totalStores; // 全平台连锁门店总数
    private Long activeTenants; // 正常在约商户数
    private Long trialTenantsCount; // 试用期中商户数
    private Long expiringSoonCount; // 即将到期商户预警数 (<=7天)
    private Long expiredCount; // 已逾期商户数
    private Double averageServiceDurationMonths; // 平均购买服务时长(月)

    private BigDecimal totalSubscriptionRevenue; // SaaS 套餐订阅总流水
    private BigDecimal totalStorageRevenue; // 云存储服务费总流水
    private BigDecimal totalPlatformRevenue; // 平台累计总收入

    private Map<String, Long> planDistribution; // 套餐版本分布 (TRIAL, PROFESSIONAL, FLAGSHIP, ENTERPRISE)
    private Map<String, Long> industryStoreDistribution; // 多行业门店分布 (BEAUTY, RESTAURANT, AUTO, RETAIL)
}
