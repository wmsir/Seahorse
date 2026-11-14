package com.seahorse.store.domain.payment.strategy;

import com.seahorse.store.domain.billing.enums.PaymentChannel;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * 银联刷卡 / 云闪付渠道支付策略
 */
@Slf4j
@Component
public class UnionPayStrategy implements PaymentChannelStrategy {

    @Override
    public PaymentChannel getChannel() {
        return PaymentChannel.UNION_PAY;
    }

    @Override
    public ChannelPayResult processPay(PaymentPayContext context) {
        log.info("【银联刷卡/云闪付】开始处理支付: orderNo={}, amount={}",
                context.getOrder().getOrderNo(), context.getAmount());
        String tradeNo = "UP" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        return ChannelPayResult.success(tradeNo);
    }
}
