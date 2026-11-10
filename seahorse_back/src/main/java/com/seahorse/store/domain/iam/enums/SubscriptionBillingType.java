package com.seahorse.store.domain.iam.enums;

import lombok.Getter;

/**
 * SaaS 平台交费类型枚举
 */
@Getter
public enum SubscriptionBillingType {
    PLAN_SUBSCRIPTION("SaaS 会员套餐订阅费", "基础版本授权与功能模块服务费"),
    STORAGE_SERVICE("云存储扩容/运维服务费", "商户多媒体数据、高清客照、行驶证与视频云存储服务费");

    private final String description;
    private final String detail;

    SubscriptionBillingType(String description, String detail) {
        this.description = description;
        this.detail = detail;
    }
}
