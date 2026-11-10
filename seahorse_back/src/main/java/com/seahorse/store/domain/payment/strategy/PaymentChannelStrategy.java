package com.seahorse.store.domain.payment.strategy;

import com.seahorse.store.domain.billing.enums.PaymentChannel;

public interface PaymentChannelStrategy {
    PaymentChannel getChannel();
    ChannelPayResult processPay(PaymentPayContext context);
}
