package com.seahorse.store.domain.notification.enums;

import lombok.Getter;

@Getter
public enum NotificationChannel {
    WECHAT_MP("微信公众号/服务号"),
    ALIPAY_LIFE("支付宝生活号"),
    SMS("短信通知");

    private final String description;

    NotificationChannel(String description) {
        this.description = description;
    }
}
