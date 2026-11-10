package com.seahorse.store.domain.payment.strategy;

import com.seahorse.store.domain.billing.model.BillingOrder;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.Map;

@Data
@Builder
public class PaymentPayContext {
    private String tenantId;
    private String storeId;
    private BillingOrder order;
    private BigDecimal amount;
    private Long memberId;
    private Long timeCardSkuId;
    private Integer timeCardDeductCount;
    private BigDecimal tenderedAmount; // 现金实收
    private Map<String, Object> extraParams;
}
