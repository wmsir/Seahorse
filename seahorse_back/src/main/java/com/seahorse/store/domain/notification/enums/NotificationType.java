package com.seahorse.store.domain.notification.enums;

import lombok.Getter;

@Getter
public enum NotificationType {
    CONSUME_NOTICE("消费动账提醒"),
    RECHARGE_NOTICE("储值充值通知"),
    MARKETING_CAMPAIGN("营销活动通知"),
    COUPON_NOTICE("优惠券到账通知"),
    TEST_NOTICE("全渠道测试通知");

    private final String description;

    NotificationType(String description) {
        this.description = description;
    }
}
