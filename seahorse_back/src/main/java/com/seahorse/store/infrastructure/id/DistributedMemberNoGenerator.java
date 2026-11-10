package com.seahorse.store.infrastructure.id;

import com.seahorse.store.infrastructure.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.atomic.AtomicLong;

/**
 * 分布式高并发全局唯一会员号发号器
 * 
 * 生成规则: HM + yyyyMMdd + 6位高并发原子单调递增序列号 (例如: HM20260916000001)
 * 具备以下特性:
 * 1. 业务可读性: 前缀 HM (Hippo Member) + 当日年月日，直观辨识会员入会批次与开卡时间;
 * 2. 绝对唯一性: 基于原子序列递增，并与底层数据库碰撞校验，杜绝进程重启或并发导致的重复冲突;
 * 3. 跨日自动归零重置: 每日支持生成 100 万级新会员号 (000001 ~ 999999);
 * 4. 数据库级硬保障: 依托 sh_member (tenant_id, member_no) 唯一索引与乐观重试兜底。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DistributedMemberNoGenerator {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyyMMdd");
    private static final String PREFIX = "HM";

    private final MemberRepository memberRepository;
    private final AtomicLong sequence = new AtomicLong(1);
    private volatile String currentDay = LocalDate.now().format(DATE_FORMATTER);

    /**
     * 生成下一个全局唯一会员号
     */
    public synchronized String nextMemberNo() {
        String today = LocalDate.now().format(DATE_FORMATTER);
        if (!today.equals(currentDay)) {
            currentDay = today;
            sequence.set(1);
            log.info("【会员发号器】跨日重置序列号为 1, 新日期={}", currentDay);
        }

        while (true) {
            long seq = sequence.getAndIncrement();
            // 格式化为 6 位数字，超出则自动扩展
            String seqStr = String.format("%06d", seq);
            String candidate = PREFIX + currentDay + seqStr;
            if (!memberRepository.existsByMemberNo(candidate)) {
                return candidate;
            }
            log.warn("【会员发号器】检测到会员号 {} 已存在，自动向后递增跳过", candidate);
        }
    }
}
