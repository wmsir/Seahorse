package com.seahorse.store.domain.member.enums;

public enum CardType {
    STORED_VALUE("双轨储值卡"),
    TIME_CARD("计量次卡"),
    DISCOUNT("折扣身份卡"),
    PERIOD("时长周期卡"),
    PACKAGE("套餐盒卡"),
    PLUS("付费权益卡(PLUS)");

    private final String description;

    CardType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
