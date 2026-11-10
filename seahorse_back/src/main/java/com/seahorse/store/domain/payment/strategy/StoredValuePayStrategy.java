package com.seahorse.store.domain.payment.strategy;

import com.seahorse.store.domain.billing.enums.PaymentChannel;
import com.seahorse.store.domain.member.model.DualBalanceAccount;
import com.seahorse.store.infrastructure.repository.DualBalanceAccountRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class StoredValuePayStrategy implements PaymentChannelStrategy {

    private final DualBalanceAccountRepository dualBalanceAccountRepository;
    private final com.seahorse.store.infrastructure.repository.TenantRepository tenantRepository;
    private final com.seahorse.store.infrastructure.repository.MemberRepository memberRepository;

    @Override
    public PaymentChannel getChannel() {
        return PaymentChannel.STORED_VALUE;
    }

    @Override
    public ChannelPayResult processPay(PaymentPayContext context) {
        Long memberId = context.getMemberId();
        if (memberId == null) {
            return ChannelPayResult.fail("储值支付失败: 未关联会员信息");
        }

        DualBalanceAccount account = dualBalanceAccountRepository.findByMemberId(memberId)
                .orElse(null);

        if (account == null) {
            com.seahorse.store.domain.member.model.Member member = memberRepository.findById(memberId).orElse(null);
            if (member != null) {
                account = DualBalanceAccount.builder()
                        .tenantId(member.getTenantId())
                        .memberId(member.getId())
                        .principalBalance(BigDecimal.ZERO)
                        .giftBalance(BigDecimal.ZERO)
                        .totalRecharged(BigDecimal.ZERO)
                        .totalGiftGranted(BigDecimal.ZERO)
                        .deductMode(com.seahorse.store.domain.member.enums.DeductMode.PROPORTIONAL)
                        .build();
                account = dualBalanceAccountRepository.save(account);
            } else {
                return ChannelPayResult.fail("储值支付失败: 会员未开通储值账户");
            }
        }

        BigDecimal amount = context.getAmount();
        try {
            // 优先使用会员开卡时选定的储值扣减策略（比例双轨 or 优先本金），若无则继承商户默认
            com.seahorse.store.domain.member.enums.DeductMode mode = account.getDeductMode();
            if (mode == null && context.getTenantId() != null) {
                com.seahorse.store.domain.iam.model.Tenant tenant = tenantRepository.findByTenantId(context.getTenantId()).orElse(null);
                if (tenant != null && tenant.getDeductMode() != null) {
                    mode = tenant.getDeductMode();
                }
            }
            if (mode == null) {
                mode = com.seahorse.store.domain.member.enums.DeductMode.PROPORTIONAL;
            }

            // 执行储值扣除
            BigDecimal[] deducted = account.deduct(amount, mode);
            dualBalanceAccountRepository.save(account);

            final BigDecimal remainingTotal = account.getTotalBalance();
            // 同步持久化会员累计消费与到店统计
            memberRepository.findById(memberId).ifPresent(m -> {
                m.setBalance(remainingTotal);
                BigDecimal spent = m.getTotalSpent() != null ? m.getTotalSpent() : BigDecimal.ZERO;
                m.setTotalSpent(spent.add(amount));
                int visits = m.getVisitCount() != null ? m.getVisitCount() : 0;
                m.setVisitCount(visits + 1);
                m.setLastVisitTime(java.time.LocalDateTime.now());
                memberRepository.save(m);
            });

            log.info("【储值支付成功】会员ID={}, 扣减模式={}, 扣减本金={}, 扣减赠金={}, 剩余总额={}",
                    memberId, mode.getTitle(), deducted[0], deducted[1], account.getTotalBalance());

            String tradeNo = "SV" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 4).toUpperCase();
            return ChannelPayResult.builder()
                    .success(true)
                    .tradeNo(tradeNo)
                    .principalDeducted(deducted[0])
                    .giftDeducted(deducted[1])
                    .build();
        } catch (Exception e) {
            return ChannelPayResult.fail("储值扣减失败: " + e.getMessage());
        }
    }
}
