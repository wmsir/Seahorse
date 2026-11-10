package com.seahorse.store.application.dto.member;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 会员域相关命令对象规范
 * 符合阿里巴巴与DDD规范：Command全拼命名
 */
public final class MemberCommands {

    private MemberCommands() {
        // 私有构造防实例化
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MemberRegisterCommand {
        private String name;
        private String phone;
        private String gender;
        private LocalDate birthday;
        private BigDecimal initialPrincipal; // 开卡同时充值
        private BigDecimal initialGift;
        private String storeId;
        private String paymentMethod;
        private com.seahorse.store.domain.member.enums.DeductMode deductMode; // 会员开卡时选择的储值扣减策略 (PROPORTIONAL | PRINCIPAL_FIRST)
        private String level; // 初始会员等级 (REGULAR, SILVER, GOLD, VIP, PLATINUM, DIAMOND 或 对应中文名)

        public MemberRegisterCommand(String name, String phone, String gender, LocalDate birthday, BigDecimal initialPrincipal, BigDecimal initialGift) {
            this(name, phone, gender, birthday, initialPrincipal, initialGift, null, null, com.seahorse.store.domain.member.enums.DeductMode.PROPORTIONAL, null);
        }
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RechargeCommand {
        private Long memberId;
        private BigDecimal principalAmount;
        private BigDecimal giftAmount;
        private Long sellerEmployeeId; // 售卡人ID（用于充值提成）
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class IssueTimeCardCommand {
        private Long memberId;
        private Long skuId;
        private String skuName;
        private Integer totalTimes;
        private LocalDate expireDate;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SavePreferenceCommand {
        private Long memberId;
        private String category; // BEAUTY_HAIR, RESTAURANT_TASTE, AUTO_VEHICLE, HABIT
        private String tagKey;
        private String tagValue;
        private String notes;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateMemberProfileCommand {
        private String name;
        private String phone;
        private String gender;
        private LocalDate birthday;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateMemberDetailCommand {
        private String name;
        private String phone;
        private String avatar;
        private String cardNo;
        private String cardPassword;
        private Boolean cardPasswordEnabled;
        private Boolean cardSignEnabled;
        private String gender;
        private String discountName;
        private String referrerName;
        private String birthdayType;
        private LocalDate birthday;
        private BigDecimal rewardAmount;
        private Integer points;
        private BigDecimal debtAmount;
        private Boolean wechatBound;
        private Integer cardOpenCount;
        private String notes;
        private String level;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AdjustPointsCommand {
        private Integer pointsDelta;
        private String reason;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AdjustRewardsCommand {
        private BigDecimal rewardDelta;
        private String reason;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SetCardPasswordCommand {
        private String password;
        private Boolean enabled;
    }

    // --- 兼容别名 ---
    @EqualsAndHashCode(callSuper = true)
    public static class MemberRegisterCmd extends MemberRegisterCommand {}

    @EqualsAndHashCode(callSuper = true)
    public static class RechargeCmd extends RechargeCommand {}

    @EqualsAndHashCode(callSuper = true)
    public static class IssueTimeCardCmd extends IssueTimeCardCommand {}

    @EqualsAndHashCode(callSuper = true)
    public static class SavePreferenceCmd extends SavePreferenceCommand {}
}
