package com.seahorse.store.domain.member.model;

import com.seahorse.store.common.ServiceException;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_dual_balance_account")
@EntityListeners(AuditingEntityListener.class)
public class DualBalanceAccount {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private Long memberId;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false)
    private BigDecimal principalBalance; // 本金账户余额

    @Column(nullable = false)
    private BigDecimal giftBalance; // 赠送金账户余额

    private BigDecimal totalRecharged; // 历史累计充值本金
    private BigDecimal totalGiftGranted; // 历史累计获得赠送金

    @Enumerated(EnumType.STRING)
    @Column(length = 32)
    private com.seahorse.store.domain.member.enums.DeductMode deductMode; // 会员开卡时选定的储值扣减策略 (PROPORTIONAL | PRINCIPAL_FIRST)

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public BigDecimal getTotalBalance() {
        BigDecimal p = principalBalance != null ? principalBalance : BigDecimal.ZERO;
        BigDecimal g = giftBalance != null ? giftBalance : BigDecimal.ZERO;
        return p.add(g);
    }

    /**
     * 按本金与赠金比例协同扣除
     * @param amount 需扣除总金额
     * @return [扣除本金, 扣除赠金]
     */
    public BigDecimal[] deductProportional(BigDecimal amount) {
        BigDecimal total = getTotalBalance();
        if (total.compareTo(amount) < 0) {
            throw new ServiceException("储值账户总余额不足（当前总余额: ￥" + total + ", 需扣除: ￥" + amount + "）");
        }

        BigDecimal p = principalBalance != null ? principalBalance : BigDecimal.ZERO;
        BigDecimal g = giftBalance != null ? giftBalance : BigDecimal.ZERO;

        BigDecimal deductP;
        BigDecimal deductG;

        if (g.compareTo(BigDecimal.ZERO) == 0) {
            deductP = amount;
            deductG = BigDecimal.ZERO;
        } else if (p.compareTo(BigDecimal.ZERO) == 0) {
            deductP = BigDecimal.ZERO;
            deductG = amount;
        } else {
            // 本金占比 = p / total
            BigDecimal ratio = p.divide(total, 4, RoundingMode.HALF_UP);
            deductP = amount.multiply(ratio).setScale(2, RoundingMode.HALF_UP);
            deductG = amount.subtract(deductP);

            if (deductP.compareTo(p) > 0) {
                deductP = p;
                deductG = amount.subtract(deductP);
            } else if (deductG.compareTo(g) > 0) {
                deductG = g;
                deductP = amount.subtract(deductG);
            }
        }

        this.principalBalance = p.subtract(deductP);
        this.giftBalance = g.subtract(deductG);

        return new BigDecimal[]{deductP, deductG};
    }

    /**
     * 优先扣除本金，本金不足再扣除赠金
     * @param amount 需扣除总金额
     * @return [扣除本金, 扣除赠金]
     */
    public BigDecimal[] deductPrincipalFirst(BigDecimal amount) {
        BigDecimal total = getTotalBalance();
        if (total.compareTo(amount) < 0) {
            throw new ServiceException("储值账户总余额不足（当前总余额: ￥" + total + ", 需扣除: ￥" + amount + "）");
        }

        BigDecimal p = principalBalance != null ? principalBalance : BigDecimal.ZERO;
        BigDecimal g = giftBalance != null ? giftBalance : BigDecimal.ZERO;

        BigDecimal deductP;
        BigDecimal deductG;

        if (p.compareTo(amount) >= 0) {
            // 本金充足，全额使用本金
            deductP = amount;
            deductG = BigDecimal.ZERO;
        } else {
            // 本金不够，本金扣尽，差额由赠送金补足
            deductP = p;
            deductG = amount.subtract(p);
        }

        this.principalBalance = p.subtract(deductP);
        this.giftBalance = g.subtract(deductG);

        return new BigDecimal[]{deductP, deductG};
    }

    /**
     * 根据扣减模式执行储值扣费
     */
    public BigDecimal[] deduct(BigDecimal amount, com.seahorse.store.domain.member.enums.DeductMode mode) {
        if (mode == com.seahorse.store.domain.member.enums.DeductMode.PRINCIPAL_FIRST) {
            return deductPrincipalFirst(amount);
        }
        return deductProportional(amount);
    }

    public void recharge(BigDecimal principal, BigDecimal gift) {
        BigDecimal p = principal != null ? principal : BigDecimal.ZERO;
        BigDecimal g = gift != null ? gift : BigDecimal.ZERO;

        this.principalBalance = (this.principalBalance != null ? this.principalBalance : BigDecimal.ZERO).add(p);
        this.giftBalance = (this.giftBalance != null ? this.giftBalance : BigDecimal.ZERO).add(g);
        this.totalRecharged = (this.totalRecharged != null ? this.totalRecharged : BigDecimal.ZERO).add(p);
        this.totalGiftGranted = (this.totalGiftGranted != null ? this.totalGiftGranted : BigDecimal.ZERO).add(g);
    }
}
