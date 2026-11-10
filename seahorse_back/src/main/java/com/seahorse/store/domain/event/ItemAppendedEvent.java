package com.seahorse.store.domain.event;

import com.seahorse.store.domain.session.model.OrderBatch;
import com.seahorse.store.domain.session.model.ServiceSession;
import com.seahorse.store.domain.session.model.SessionLineItem;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

import java.util.List;

@Getter
public class ItemAppendedEvent extends ApplicationEvent {
    private final ServiceSession session;
    private final OrderBatch batch;
    private final List<SessionLineItem> lineItems;

    public ItemAppendedEvent(Object source, ServiceSession session, OrderBatch batch, List<SessionLineItem> lineItems) {
        super(source);
        this.session = session;
        this.batch = batch;
        this.lineItems = lineItems;
    }
}
