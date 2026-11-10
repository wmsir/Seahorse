package com.seahorse.store.domain.billing.enums;

public enum PaymentChannel {
    WECHAT("微信支付"),
    ALIPAY("支付宝"),
    CASH("现金收银"),
    STORED_VALUE("会员储值卡"),
    TIME_CARD("计次卡核销"),
    UNION_PAY("银行卡/银联刷卡");

    private final String description;

    PaymentChannel(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
