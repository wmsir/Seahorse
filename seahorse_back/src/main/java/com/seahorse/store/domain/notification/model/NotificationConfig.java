package com.seahorse.store.domain.notification.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * 全渠道消息推送配置实体 (微信公众号/服务号、支付宝生活号)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_notification_config")
@EntityListeners(AuditingEntityListener.class)
public class NotificationConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 64)
    private String tenantId;

    // --- 微信公众号/服务号对接配置 ---
    @Builder.Default
    private Boolean wechatEnabled = true;

    @Column(length = 64)
    private String wechatAppId;

    @Column(length = 128)
    private String wechatAppSecret;

    @Column(length = 64)
    private String wechatToken;

    @Column(length = 128)
    private String wechatAesKey;

    @Column(length = 500)
    private String wechatQrCodeUrl; // 公众号二维码或带参关注码

    @Column(length = 128)
    private String wechatConsumeTemplateId; // 消费动账模板ID (如: OPENTM413385970)

    @Column(length = 128)
    private String wechatRechargeTemplateId; // 储值到账模板ID (如: OPENTM206215005)

    @Column(length = 128)
    private String wechatMarketingTemplateId; // 营销活动模板ID (如: OPENTM408372691)

    // --- 支付宝生活号/服务窗对接配置 ---
    @Builder.Default
    private Boolean alipayEnabled = true;

    @Column(length = 64)
    private String alipayAppId;

    @Column(length = 2048)
    private String alipayPrivateKey;

    @Column(length = 2048)
    private String alipayPublicKey;

    @Column(length = 500)
    private String alipayQrCodeUrl; // 生活号关注二维码

    @Column(length = 128)
    private String alipayConsumeTemplateId; // 支付宝动账消息模板ID

    @Column(length = 128)
    private String alipayMarketingTemplateId; // 支付宝生活号营销模板ID

    // --- 自动化与沙箱策略 ---
    @Builder.Default
    private Boolean mockPushEnabled = true; // 是否开启沙箱模拟推送 (开箱即用)

    @Builder.Default
    private Boolean autoPushOnCheckout = true; // 结账完成自动推送消费通知

    @Builder.Default
    private Boolean autoPushOnRecharge = true; // 储值充值自动推送账户变动

    @Builder.Default
    private Boolean autoPushOnMarketing = true; // 营销发布自动向粉丝推送

    @Builder.Default
    private Integer voiceBroadcastRepeatCount = 1; // 移动端语音播报重复次数 (默认1次, 店长/老板可配置1~5次)

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
