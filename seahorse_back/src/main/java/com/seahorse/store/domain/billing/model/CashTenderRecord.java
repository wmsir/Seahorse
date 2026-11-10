package com.seahorse.store.domain.billing.model;

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
@Table(name = "sh_cash_tender_record")
@EntityListeners(AuditingEntityListener.class)
public class CashTenderRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long billingOrderId;

    @Column(nullable = false)
    private BigDecimal dueAmount; // 现金应收

    @Column(nullable = false)
    private BigDecimal tenderedAmount; // 实收现金面额

    @Column(nullable = false)
    private BigDecimal changeAmount; // 找零金额

    private Boolean drawerOpened; // 是否触发钱箱弹开

    @CreatedDate
    private LocalDateTime createdAt;
}
