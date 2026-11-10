package com.seahorse.store.application.dto.member;

import com.seahorse.store.domain.member.model.DualBalanceAccount;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.member.model.MemberPreference;
import com.seahorse.store.domain.member.model.TimeCardBucket;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

/**
 * 会员综合档案画像 VO (含3天试用期权益标识)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MemberProfileVO {
    private Member member;
    private DualBalanceAccount dualBalance;
    private List<TimeCardBucket> timeCards;
    private List<MemberPreference> preferences;

    private Boolean isTrial;
    private Long trialDaysRemaining;
    private LocalDate trialExpireDate;

    // 会员成长与等级晋升规则模型
    private String levelCode;
    private String levelName;
    private Integer currentPoints;
    private String nextLevelCode;
    private String nextLevelName;
    private Integer growthThreshold;
    private Integer nextGrowthThreshold;
    private Integer pointsToNextLevel;
    private Double growthProgressRatio;
    private List<MemberLevelRuleVO> levelRules;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MemberLevelRuleVO {
        private String levelCode;
        private String levelName;
        private int growthThreshold;
        private java.math.BigDecimal serviceDiscount;
        private java.math.BigDecimal productDiscount;
        private String discountDisplay;
        private String privileges;
    }
}

