package com.seahorse.store.domain.payment.strategy;

import com.seahorse.store.common.ServiceException;
import com.seahorse.store.domain.billing.enums.PaymentChannel;
import org.springframework.stereotype.Component;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;

@Component
public class PaymentStrategyFactory {

    private final Map<PaymentChannel, PaymentChannelStrategy> strategyMap = new EnumMap<>(PaymentChannel.class);

    public PaymentStrategyFactory(List<PaymentChannelStrategy> strategies) {
        for (PaymentChannelStrategy strategy : strategies) {
            strategyMap.put(strategy.getChannel(), strategy);
        }
    }

    public PaymentChannelStrategy getStrategy(PaymentChannel channel) {
        PaymentChannelStrategy strategy = strategyMap.get(channel);
        if (strategy == null) {
            throw new ServiceException("未配置对应支付通道策略: " + channel);
        }
        return strategy;
    }
}
