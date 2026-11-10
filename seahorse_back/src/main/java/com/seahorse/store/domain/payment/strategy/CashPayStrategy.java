package com.seahorse.store.domain.payment.strategy;

import com.seahorse.store.domain.billing.enums.PaymentChannel;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.UUID;

@Slf4j
@Component
public class CashPayStrategy implements PaymentChannelStrategy {

    @Override
    public PaymentChannel getChannel() {
        return PaymentChannel.CASH;
    }

    @Override
    public ChannelPayResult processPay(PaymentPayContext context) {
        BigDecimal due = context.getAmount();
        BigDecimal tendered = context.getTenderedAmount() != null ? context.getTenderedAmount() : due;

        if (tendered.compareTo(due) < 0) {
            return ChannelPayResult.fail("实收现金不足 (应收: ￥" + due + ", 实收: ￥" + tendered + ")");
        }

        BigDecimal change = tendered.subtract(due);
        log.info("【现金收银】触发钱箱开箱脉冲: 应收={}, 实收={}, 找零={}", due, tendered, change);

        String tradeNo = "CASH" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 4).toUpperCase();
        return ChannelPayResult.builder()
                .success(true)
                .tradeNo(tradeNo)
                .changeAmount(change)
                .drawerOpened(true)
                .build();
    }
}
