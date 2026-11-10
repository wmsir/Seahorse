package com.seahorse.store.domain.member.model;

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
@Table(name = "sh_member_recharge_record")
@EntityListeners(AuditingEntityListener.class)
public class MemberRechargeRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(length = 64)
    private String storeId;

    @Column(nullable = false, unique = true, length = 64)
    private String orderNo;

    @Column(nullable = false)
    private Long memberId;

    private String memberName;
    private String memberPhone;

    @Column(nullable = false)
    private BigDecimal principalAmount; // 实充本金

    private BigDecimal giftAmount; // 赠送金

    private Long sellerEmployeeId; // 售卡提成人员ID
    private String sellerEmployeeName; // 售卡提成人员姓名

    @Column(length = 32)
    private String paymentMethod; // WECHAT, ALIPAY, CASH, BANK

    @Column(nullable = false, length = 32)
    private String status; // SUCCESS, CANCELLED

    private String notes;

    @CreatedDate
    private LocalDateTime createdAt;
}
