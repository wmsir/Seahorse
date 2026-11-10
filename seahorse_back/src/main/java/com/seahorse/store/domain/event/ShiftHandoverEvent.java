package com.seahorse.store.domain.event;

import com.seahorse.store.domain.billing.model.ShiftRecord;
import lombok.Getter;
import org.springframework.context.ApplicationEvent;

@Getter
public class ShiftHandoverEvent extends ApplicationEvent {
    private final ShiftRecord shiftRecord;

    public ShiftHandoverEvent(Object source, ShiftRecord shiftRecord) {
        super(source);
        this.shiftRecord = shiftRecord;
    }
}
