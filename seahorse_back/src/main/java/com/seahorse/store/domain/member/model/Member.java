package com.seahorse.store.domain.member.model;

import com.seahorse.store.domain.member.enums.MemberLevel;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_member", uniqueConstraints = {
        @UniqueConstraint(name = "uk_tenant_member_no", columnNames = {"tenant_id", "member_no"})
})
@EntityListeners(AuditingEntityListener.class)
public class Member {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    @Column(name = "member_no", nullable = false, length = 64)
    private String memberNo; // 8位会员号例如 HM880001

    @Column(nullable = false, length = 64)
    private String name;

    @Column(nullable = false, length = 32)
    private String phone;

    private String avatar;
    private String gender; // MALE, FEMALE, UNKNOWN
    private LocalDate birthday;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private MemberLevel level;

    // 资产统计
    private BigDecimal totalSpent; // 累计消费总金额
    private Integer visitCount; // 到店履约总频次
    private LocalDateTime lastVisitTime; // 最近一次到店履约时间

    @Transient
    private BigDecimal balance; // 会员双轨储值可用总余额

    private String status; // ACTIVE, DISABLED

    // 会员档案高级属性（对齐截图 2）
    private String cardNo; // 实体卡号 / 会员卡号
    @com.fasterxml.jackson.annotation.JsonProperty(access = com.fasterxml.jackson.annotation.JsonProperty.Access.WRITE_ONLY)
    private String cardPassword; // 扣卡密码（仅允许反序列化写入，禁止接口明文返回）
    private Boolean cardPasswordEnabled; // 扣卡密码开关
    private Boolean cardSignEnabled; // 扣卡签名开关
    private String discountName; // 会员折扣（如：暂无等级、8折黄金卡等）
    private String referrerName; // 推荐人
    private String birthdayType; // SOLAR (阳历), LUNAR (农历)
    private BigDecimal rewardAmount; // 奖励金（元）
    private Integer points; // 可用积分
    private BigDecimal debtAmount; // 欠款（元）
    private Boolean wechatBound; // 微信绑定状态
    private String wechatOpenId; // 微信公众号/服务号 OpenID
    private Boolean wechatFollowStatus; // 微信公众号关注状态 (true: 已关注, false: 未关注)
    private LocalDateTime wechatFollowTime; // 微信关注时间

    private String alipayUserId; // 支付宝生活号/服务窗 用户标识 (OpenID/UserId)
    private Boolean alipayFollowStatus; // 支付宝生活号关注状态 (true: 已关注, false: 未关注)
    private LocalDateTime alipayFollowTime; // 支付宝关注时间

    @Builder.Default
    private Boolean pushNotificationEnabled = true; // 动账与营销消息全渠道推送开关

    private Integer cardOpenCount; // 办卡次数
    @Column(length = 1000)
    private String notes; // 备注信息

    // 试用期权益管理（支持注册新会员默认试用3天）
    private LocalDate trialExpireDate; // 试用期到期日
    private Boolean isTrial; // 是否处于试用期

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    /**
     * 判断会员当前是否处于有效试用期内
     */
    public boolean isTrialActive() {
        return Boolean.TRUE.equals(isTrial) && trialExpireDate != null && !LocalDate.now().isAfter(trialExpireDate);
    }

    /**
     * 获取试用期剩余天数
     */
    public long getTrialDaysRemaining() {
        if (trialExpireDate == null) {
            return 0;
        }
        long days = java.time.temporal.ChronoUnit.DAYS.between(LocalDate.now(), trialExpireDate);
        return Math.max(0, days);
    }

    /**
     * 获取纯中文会员等级描述
     */
    public String getLevelName() {
        return level != null ? level.getDescription() : "普卡会员";
    }

    /**
     * 获取储值可用总余额（兼容旧版前端 totalBalance 字段）
     */
    public BigDecimal getTotalBalance() {
        return balance != null ? balance : BigDecimal.ZERO;
    }

    /**
     * 是否已设置扣卡密码（替代明文 cardPassword 回传）
     */
    public boolean getHasCardPassword() {
        return cardPassword != null && !cardPassword.trim().isEmpty();
    }
}
