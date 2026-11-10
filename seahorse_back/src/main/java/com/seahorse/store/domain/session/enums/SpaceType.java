package com.seahorse.store.domain.session.enums;

public enum SpaceType {
    TABLE("餐饮桌台"),
    MIRROR("美发镜台/美容床"),
    BAY("汽修工位/举升机"),
    ROOM("包厢/独立套房"),
    STATION("工位/卡座"),
    BED("护理床位");

    private final String description;

    SpaceType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
