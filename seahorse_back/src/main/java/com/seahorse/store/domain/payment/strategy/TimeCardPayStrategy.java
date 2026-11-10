package com.seahorse.store.domain.payment.strategy;

import com.seahorse.store.domain.billing.enums.PaymentChannel;
import com.seahorse.store.domain.member.model.TimeCardBucket;
import com.seahorse.store.infrastructure.repository.TimeCardBucketRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class TimeCardPayStrategy implements PaymentChannelStrategy {

    private final TimeCardBucketRepository timeCardBucketRepository;

    @Override
    public PaymentChannel getChannel() {
        return PaymentChannel.TIME_CARD;
    }

    @Override
    public ChannelPayResult processPay(PaymentPayContext context) {
        Long memberId = context.getMemberId();
        if (memberId == null) {
            return ChannelPayResult.fail("次卡核销失败: 未关联会员");
        }

        Long skuId = context.getTimeCardSkuId();
        int count = context.getTimeCardDeductCount() != null ? context.getTimeCardDeductCount() : 1;

        List<TimeCardBucket> buckets = timeCardBucketRepository.findByMemberIdAndStatus(memberId, com.seahorse.store.domain.member.enums.TimeCardStatus.ACTIVE.name());
        TimeCardBucket targetBucket = buckets.stream()
                .filter(b -> skuId == null || b.getSkuId().equals(skuId))
                .filter(b -> b.getRemainingTimes() >= count)
                .findFirst()
                .orElse(null);

        if (targetBucket == null) {
            return ChannelPayResult.fail("次卡核销失败: 未找到可用于当前项目且剩余次数足够的有效次卡");
        }

        try {
            targetBucket.deductTimes(count);
            timeCardBucketRepository.save(targetBucket);

            log.info("【次卡核销成功】会员ID={}, 核销项目={}, 核销次数={}, 剩余次数={}",
                    memberId, targetBucket.getSkuName(), count, targetBucket.getRemainingTimes());

            String tradeNo = "TC" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 4).toUpperCase();
            return ChannelPayResult.success(tradeNo);
        } catch (Exception e) {
            return ChannelPayResult.fail("次卡核销异常: " + e.getMessage());
        }
    }
}
