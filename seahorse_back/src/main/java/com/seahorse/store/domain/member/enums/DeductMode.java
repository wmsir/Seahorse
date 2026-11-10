package com.seahorse.store.domain.member.enums;

import lombok.Getter;

/**
 * 会员双轨储值扣减策略模式
 */
@Getter
public enum DeductMode {
    PROPORTIONAL("按本金/赠金比例双轨扣减", "消费时按当前账户本金与赠送金余额比例协同扣除，降低商家负债"),
    PRINCIPAL_FIRST("优先本金扣减", "消费时优先全额扣减真实充值本金，本金不足时再扣减赠送金");

    private final String title;
    private final String description;

    DeductMode(String title, String description) {
        this.title = title;
        this.description = description;
    }
}
