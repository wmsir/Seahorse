package com.seahorse.store.domain.common.enums;

import lombok.Getter;

/**
 * 通用状态枚举
 */
@Getter
public enum CommonStatus {
    ACTIVE("正常/有效"),
    DISABLED("已禁用/停用"),
    FROZEN("已冻结");

    private final String description;

    CommonStatus(String description) {
        this.description = description;
    }
}
