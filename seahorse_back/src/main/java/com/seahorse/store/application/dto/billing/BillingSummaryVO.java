package com.seahorse.store.application.dto.billing;

import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.billing.model.CashTenderRecord;
import com.seahorse.store.domain.billing.model.PaymentRecord;

import java.util.List;

/**
 * 结算账单概要视图对象
 */
public class BillingSummaryVO {
    private BillingOrder order;
    private List<PaymentRecord> paymentRecords;
    private CashTenderRecord cashTender;

    public BillingSummaryVO() {
    }

    public BillingSummaryVO(BillingOrder order, List<PaymentRecord> paymentRecords, CashTenderRecord cashTender) {
        this.order = order;
        this.paymentRecords = paymentRecords;
        this.cashTender = cashTender;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private BillingOrder order;
        private List<PaymentRecord> paymentRecords;
        private CashTenderRecord cashTender;

        public Builder order(BillingOrder order) { this.order = order; return this; }
        public Builder paymentRecords(List<PaymentRecord> paymentRecords) { this.paymentRecords = paymentRecords; return this; }
        public Builder cashTender(CashTenderRecord cashTender) { this.cashTender = cashTender; return this; }

        public BillingSummaryVO build() {
            return new BillingSummaryVO(order, paymentRecords, cashTender);
        }
    }

    public BillingOrder getOrder() { return order; }
    public void setOrder(BillingOrder order) { this.order = order; }
    public List<PaymentRecord> getPaymentRecords() { return paymentRecords; }
    public void setPaymentRecords(List<PaymentRecord> paymentRecords) { this.paymentRecords = paymentRecords; }
    public CashTenderRecord getCashTender() { return cashTender; }
    public void setCashTender(CashTenderRecord cashTender) { this.cashTender = cashTender; }
}
