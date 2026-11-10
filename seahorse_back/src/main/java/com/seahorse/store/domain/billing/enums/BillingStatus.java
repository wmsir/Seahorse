package com.seahorse.store.domain.billing.enums;

public enum BillingStatus {
    PENDING("待支付"),
    PAID("已支付结账"),
    REFUNDED("已全额退款"),
    PARTIAL_REFUNDED("已部分退款"),
    CANCELLED("已取消");

    private final String description;

    BillingStatus(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
