package com.seahorse.store.domain.payment.strategy;

import com.seahorse.store.domain.billing.enums.PaymentChannel;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Slf4j
@Component
public class WechatPayStrategy implements PaymentChannelStrategy {

    @Override
    public PaymentChannel getChannel() {
        return PaymentChannel.WECHAT;
    }

    @Override
    public ChannelPayResult processPay(PaymentPayContext context) {
        log.info("【微信支付】开始处理支付: orderNo={}, amount={}", context.getOrder().getOrderNo(), context.getAmount());
        // 模拟或真实微信支付 API 调用
        String tradeNo = "WX" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        return ChannelPayResult.success(tradeNo);
    }
}
