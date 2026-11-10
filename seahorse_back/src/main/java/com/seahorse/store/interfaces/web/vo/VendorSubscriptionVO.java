package com.seahorse.store.interfaces.web.vo;

import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * 开发商视角：商户会员订阅及存储费管理展示对象
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VendorSubscriptionVO implements Serializable {
    private static final long serialVersionUID = 1L;

    private String tenantId;
    private String tenantName;
    private String contactName;
    private String contactPhone;

    private SubscriptionPlan plan;
    private String planName;
    private String planFeatures;

    private Integer purchasedDurationMonths; // 购买的服务时长(月数，如12个月、24个月)
    private Integer memberCount; // 该商户旗下注册会员数量

    private Integer storeCount; // 已开门店数
    private Integer storeLimit; // 允许开设门店上限
    private List<StoreSummaryVO> stores; // 门店详情列表

    private Integer storageQuotaGb; // 云存储空间配额(GB)
    private LocalDate startDate;
    private LocalDate expireDate;
    private Long daysRemaining; // 剩余到期天数
    private String warningLevel; // NORMAL, EXPIRING_SOON, EXPIRED

    private String deductMode; // PROPORTIONAL, PRINCIPAL_FIRST
    private String deductModeTitle;

    private BigDecimal totalPaidAmount; // 累计已缴纳总额（套餐+存储）
    private BigDecimal subscriptionFeePaid; // 套餐费小计
    private BigDecimal storageFeePaid; // 存储费小计

    private Boolean isTrial; // 是否为免费试用期
    private Integer trialDays; // 试用天数

    private String status; // ACTIVE, DISABLED

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StoreSummaryVO implements Serializable {
        private static final long serialVersionUID = 1L;
        private String storeId;
        private String storeName;
        private String industry;
        private String industryDesc;
        private String address;
        private String phone;
    }
}
