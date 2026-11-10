package com.seahorse.store.domain.session.enums;

public enum SpaceStatus {
    IDLE("空闲可用"),
    OCCUPIED("在场服务中"),
    DIRTY("待清台/待复位"),
    MAINTENANCE("维修停用");

    private final String description;

    SpaceStatus(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
