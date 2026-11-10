package com.seahorse.store.domain.billing.enums;

import lombok.Getter;

/**
 * 收银交班对账状态枚举
 */
@Getter
public enum ShiftStatus {
    NORMAL("正常平账"),
    VARIANCE("存在长短款差额"),
    PENDING("交班确认中");

    private final String description;

    ShiftStatus(String description) {
        this.description = description;
    }
}
