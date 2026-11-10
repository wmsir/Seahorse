package com.seahorse.store.domain.event;

import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.billing.model.PaymentRecord;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

import java.util.List;

@Getter
public class BillingCompletedEvent extends ApplicationEvent {
    private final BillingOrder order;
    private final List<PaymentRecord> paymentRecords;

    public BillingCompletedEvent(Object source, BillingOrder order, List<PaymentRecord> paymentRecords) {
        super(source);
        this.order = order;
        this.paymentRecords = paymentRecords;
    }
}
