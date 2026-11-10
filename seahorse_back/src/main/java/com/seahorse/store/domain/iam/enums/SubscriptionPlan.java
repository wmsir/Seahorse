package com.seahorse.store.domain.iam.enums;

import lombok.Getter;

import java.math.BigDecimal;

/**
 * SaaS 商户会员订阅套餐版本
 */
@Getter
public enum SubscriptionPlan {
    TRIAL("基础体验版(默认试用3天)", 1, 5, BigDecimal.valueOf(0.00), 3, "支持1家单店，5GB基础云存储，新注册商户默认赠送3天全功能免费试用"),
    PROFESSIONAL("专业成长版", 3, 50, BigDecimal.valueOf(2980.00), 0, "支持最多3家门店，50GB云存储，支持双轨储值策略自选与全渠道收银"),
    FLAGSHIP("旗舰连锁版", 10, 200, BigDecimal.valueOf(6800.00), 0, "支持最多10家门店，多业态跨行业混部，200GB大容量云存储与私域深度营销"),
    ENTERPRISE("集团企业版", 999, 1024, BigDecimal.valueOf(19800.00), 0, "门店数不限，1TB超大云存储空间，专属定制与API开放接入");

    private final String description;
    private final int maxStores;
    private final int storageQuotaGb;
    private final BigDecimal annualFee;
    private final int trialDays;
    private final String features;

    SubscriptionPlan(String description, int maxStores, int storageQuotaGb, BigDecimal annualFee, int trialDays, String features) {
        this.description = description;
        this.maxStores = maxStores;
        this.storageQuotaGb = storageQuotaGb;
        this.annualFee = annualFee;
        this.trialDays = trialDays;
        this.features = features;
    }

    public String getDescription() {
        return description;
    }

    public int getMaxStores() {
        return maxStores;
    }

    public int getStorageQuotaGb() {
        return storageQuotaGb;
    }

    public BigDecimal getAnnualFee() {
        return annualFee;
    }

    public int getTrialDays() {
        return trialDays;
    }

    public String getFeatures() {
        return features;
    }
}
