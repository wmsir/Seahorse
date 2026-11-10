package com.seahorse.store.domain.event;

import com.seahorse.store.domain.session.model.ServiceSession;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class SessionOpenedEvent extends ApplicationEvent {
    private final ServiceSession session;

    public SessionOpenedEvent(Object source, ServiceSession session) {
        super(source);
        this.session = session;
    }
}
