package com.seahorse.store.application.dto.session;

import com.seahorse.store.domain.session.model.OrderBatch;
import com.seahorse.store.domain.session.model.PerformerShare;
import com.seahorse.store.domain.session.model.ServiceSession;
import com.seahorse.store.domain.session.model.SessionLineItem;

import java.util.List;
import java.util.Map;

/**
 * 在场服务会话详情视图对象
 */
public class SessionDetailVO {
    private ServiceSession session;
    private List<OrderBatch> batches;
    private List<SessionLineItem> lineItems;
    private Map<Long, List<PerformerShare>> performersByItem;

    public SessionDetailVO() {
    }

    public SessionDetailVO(ServiceSession session, List<OrderBatch> batches, List<SessionLineItem> lineItems, Map<Long, List<PerformerShare>> performersByItem) {
        this.session = session;
        this.batches = batches;
        this.lineItems = lineItems;
        this.performersByItem = performersByItem;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private ServiceSession session;
        private List<OrderBatch> batches;
        private List<SessionLineItem> lineItems;
        private Map<Long, List<PerformerShare>> performersByItem;

        public Builder session(ServiceSession session) { this.session = session; return this; }
        public Builder batches(List<OrderBatch> batches) { this.batches = batches; return this; }
        public Builder lineItems(List<SessionLineItem> lineItems) { this.lineItems = lineItems; return this; }
        public Builder performersByItem(Map<Long, List<PerformerShare>> performersByItem) { this.performersByItem = performersByItem; return this; }

        public SessionDetailVO build() {
            return new SessionDetailVO(session, batches, lineItems, performersByItem);
        }
    }

    public ServiceSession getSession() { return session; }
    public void setSession(ServiceSession session) { this.session = session; }
    public List<OrderBatch> getBatches() { return batches; }
    public void setBatches(List<OrderBatch> batches) { this.batches = batches; }
    public List<SessionLineItem> getLineItems() { return lineItems; }
    public void setLineItems(List<SessionLineItem> lineItems) { this.lineItems = lineItems; }
    public Map<Long, List<PerformerShare>> getPerformersByItem() { return performersByItem; }
    public void setPerformersByItem(Map<Long, List<PerformerShare>> performersByItem) { this.performersByItem = performersByItem; }
}
