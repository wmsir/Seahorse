package com.seahorse.store.domain.billing.model;

import com.seahorse.store.domain.billing.enums.PaymentChannel;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_payment_record")
@EntityListeners(AuditingEntityListener.class)
public class PaymentRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long billingOrderId;

    private String orderNo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private PaymentChannel channel;

    @Column(nullable = false)
    private BigDecimal amount;

    // 针对储值卡支付：拆解本金与赠送金
    private BigDecimal principalAmount;
    private BigDecimal giftAmount;

    // 针对次卡支付：核销次数与项目ID
    private Integer timeCardDeductCount;
    private Long timeCardSkuId;

    private String tradeNo; // 第三方或系统流水号
    private String status; // SUCCESS, REFUNDED

    @CreatedDate
    private LocalDateTime payTime;
}
