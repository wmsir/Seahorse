package com.seahorse.store.domain.payment.strategy;

import com.seahorse.store.domain.billing.enums.PaymentChannel;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Slf4j
@Component
public class AlipayPayStrategy implements PaymentChannelStrategy {

    @Override
    public PaymentChannel getChannel() {
        return PaymentChannel.ALIPAY;
    }

    @Override
    public ChannelPayResult processPay(PaymentPayContext context) {
        log.info("【支付宝支付】开始处理支付: orderNo={}, amount={}", context.getOrder().getOrderNo(), context.getAmount());
        String tradeNo = "ALI" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        return ChannelPayResult.success(tradeNo);
    }
}
