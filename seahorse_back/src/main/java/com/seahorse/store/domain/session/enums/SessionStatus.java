package com.seahorse.store.domain.session.enums;

public enum SessionStatus {
    OCCUPIED_ORDERING("已占位/点单中"),
    SERVING("服务履约中"),
    SETTLING("待结算锁定"),
    SETTLED_WAIT_CLEAN("已买单/待复位"),
    CLOSED("已关闭");

    private final String description;

    SessionStatus(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
