package com.seahorse.store.application.service;

import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.billing.enums.PaymentChannel;
import com.seahorse.store.domain.billing.enums.ShiftStatus;
import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.billing.model.PaymentRecord;
import com.seahorse.store.domain.billing.model.ShiftRecord;
import com.seahorse.store.domain.event.ShiftHandoverEvent;
import com.seahorse.store.infrastructure.repository.BillingOrderRepository;
import com.seahorse.store.infrastructure.repository.PaymentRecordRepository;
import com.seahorse.store.infrastructure.repository.ShiftRecordRepository;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

/**
 * 收银交班与对账应用服务
 * 符合阿里巴巴与DDD应用层规范
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ShiftHandoverAppService {

    private final ShiftRecordRepository shiftRecordRepository;
    private final BillingOrderRepository billingOrderRepository;
    private final PaymentRecordRepository paymentRecordRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BlindShiftCommand {
        private BigDecimal blindCashAmount; // 抽屉盲盘实数现金
        private String notes; // 交班备忘说明
    }

    @EqualsAndHashCode(callSuper = true)
    public static class BlindShiftCmd extends BlindShiftCommand {}

    @Transactional(rollbackFor = Exception.class)
    public ShiftRecord submitBlindShift(BlindShiftCommand cmd) {
        String storeId = TenantContext.getStoreId();
        Long cashierId = TenantContext.getUserId();
        String cashierName = TenantContext.getUsername();

        LocalDateTime shiftStart = LocalDateTime.of(LocalDate.now(), LocalTime.MIN);
        LocalDateTime shiftEnd = LocalDateTime.now();

        // 统计当天支付流水
        List<PaymentRecord> payments = paymentRecordRepository.findByPayTimeBetween(shiftStart, shiftEnd);

        BigDecimal systemCash = BigDecimal.ZERO;
        BigDecimal wechatTotal = BigDecimal.ZERO;
        BigDecimal alipayTotal = BigDecimal.ZERO;
        BigDecimal unionPayTotal = BigDecimal.ZERO;
        BigDecimal storedValueTotal = BigDecimal.ZERO;
        int timeCardTimes = 0;

        for (PaymentRecord p : payments) {
            if (p.getChannel() == PaymentChannel.CASH) {
                systemCash = systemCash.add(p.getAmount());
            } else if (p.getChannel() == PaymentChannel.WECHAT) {
                wechatTotal = wechatTotal.add(p.getAmount());
            } else if (p.getChannel() == PaymentChannel.ALIPAY) {
                alipayTotal = alipayTotal.add(p.getAmount());
            } else if (p.getChannel() == PaymentChannel.UNION_PAY) {
                unionPayTotal = unionPayTotal.add(p.getAmount());
            } else if (p.getChannel() == PaymentChannel.STORED_VALUE) {
                storedValueTotal = storedValueTotal.add(p.getAmount());
            } else if (p.getChannel() == PaymentChannel.TIME_CARD) {
                timeCardTimes += (p.getTimeCardDeductCount() != null ? p.getTimeCardDeductCount() : 1);
            }
        }

        BigDecimal blindCash = cmd.getBlindCashAmount() != null ? cmd.getBlindCashAmount() : BigDecimal.ZERO;
        BigDecimal variance = blindCash.subtract(systemCash);

        ShiftStatus status = variance.compareTo(BigDecimal.ZERO) == 0 ? ShiftStatus.NORMAL : ShiftStatus.VARIANCE;

        List<BillingOrder> settledOrders = billingOrderRepository.findByStoreIdAndSettledAtBetween(storeId, shiftStart, shiftEnd);

        ShiftRecord shiftRecord = ShiftRecord.builder()
                .tenantId(TenantContext.getTenantId())
                .storeId(storeId)
                .cashierId(cashierId)
                .cashierName(cashierName)
                .shiftStartTime(shiftStart)
                .shiftEndTime(shiftEnd)
                .blindCashAmount(blindCash)
                .systemCashAmount(systemCash)
                .cashVariance(variance)
                .wechatTotal(wechatTotal)
                .alipayTotal(alipayTotal)
                .unionPayTotal(unionPayTotal)
                .storedValueTotal(storedValueTotal)
                .timeCardTimesTotal(timeCardTimes)
                .orderCount(settledOrders.size())
                .status(status)
                .notes(cmd.getNotes())
                .build();

        shiftRecord = shiftRecordRepository.save(shiftRecord);
        eventPublisher.publishEvent(new ShiftHandoverEvent(this, shiftRecord));

        log.info("【收银交班完成】收银员={}, 盲盘现金={}, 理论现金={}, 长短款差额={}, 状态={}",
                cashierName, blindCash, systemCash, variance, status);

        return shiftRecord;
    }
}
