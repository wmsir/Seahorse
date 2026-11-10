package com.seahorse.store.application.dto.billing;

import com.seahorse.store.domain.billing.enums.PaymentChannel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * 结算收银命令对象
 * 符合阿里巴巴与DDD规范：Command命名
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CheckoutCommand {
    private Long sessionId;
    private Long billingOrderId;
    private List<PaymentSplitItem> splitItems;
    private Long cashierId;
    private String cashierName;

    // 补充快照与散客/快速收银扩展字段（避免因未预先生成账单引发 500 异常）
    private String orderNo;
    private BigDecimal totalAmount;
    private BigDecimal actualAmount;
    private BigDecimal feeAmount;
    private BigDecimal discountAmount;
    private Long spaceId;
    private String spaceName;
    private Long memberId;
    private String customerName;
    private String customerPhone;

    // 结算消费的商品/服务品项列表（用于库存联动扣减与销售对账）
    private List<CheckoutItem> items;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CheckoutItem {
        private Long productId;
        private String productCode;
        private String productName;
        private String productType; // PHYSICAL, SERVICE, MATERIAL, RETAIL
        private BigDecimal price;
        private Integer quantity;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PaymentSplitItem {
        private PaymentChannel channel;
        private BigDecimal amount;
        private BigDecimal tenderedAmount; // 若为现金，传入实收纸币金额（用于找零计算）
        private Long timeCardSkuId; // 若为次卡核销，传入服务项ID
        private Integer timeCardDeductCount; // 若为次卡核销，传入核销次数
    }
}
