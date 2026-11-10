package com.seahorse.store.domain.payment.strategy;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChannelPayResult {
    private boolean success;
    private String tradeNo;
    private String errorMessage;
    private BigDecimal principalDeducted;
    private BigDecimal giftDeducted;
    private BigDecimal changeAmount;
    private Boolean drawerOpened;

    public static ChannelPayResult success(String tradeNo) {
        return ChannelPayResult.builder()
                .success(true)
                .tradeNo(tradeNo)
                .build();
    }

    public static ChannelPayResult fail(String errorMessage) {
        return ChannelPayResult.builder()
                .success(false)
                .errorMessage(errorMessage)
                .build();
    }
}
