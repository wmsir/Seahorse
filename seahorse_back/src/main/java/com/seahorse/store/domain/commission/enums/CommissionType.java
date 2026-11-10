package com.seahorse.store.domain.commission.enums;

public enum CommissionType {
    SERVICE_WORK("工时服务施工提成"),
    RECHARGE("售卡充值提成"),
    RETAIL_SALE("实物零售提成");

    private final String description;

    CommissionType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
