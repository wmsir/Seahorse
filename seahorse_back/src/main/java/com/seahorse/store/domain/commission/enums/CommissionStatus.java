package com.seahorse.store.domain.commission.enums;

import lombok.Getter;

/**
 * 提成记录状态枚举
 */
@Getter
public enum CommissionStatus {
    RECORDED("已记录待结算"),
    SETTLED("已结算发放");

    private final String description;

    CommissionStatus(String description) {
        this.description = description;
    }
}
