package com.seahorse.store.domain.member.enums;

import lombok.Getter;

/**
 * 计量次卡状态枚举
 */
@Getter
public enum TimeCardStatus {
    ACTIVE("有效可用"),
    EXPIRED("已过期"),
    EXHAUSTED("已核销耗尽");

    private final String description;

    TimeCardStatus(String description) {
        this.description = description;
    }
}
