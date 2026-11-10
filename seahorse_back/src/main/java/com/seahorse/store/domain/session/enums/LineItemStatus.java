package com.seahorse.store.domain.session.enums;

import lombok.Getter;

/**
 * 履约会话消费明细状态枚举
 */
@Getter
public enum LineItemStatus {
    ACTIVE("生效点单"),
    CANCELLED("已退单/取消"),
    REFUNDED("已退款");

    private final String description;

    LineItemStatus(String description) {
        this.description = description;
    }
}
