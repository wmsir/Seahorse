package com.seahorse.store.application.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.billing.model.PaymentRecord;
import com.seahorse.store.domain.member.model.DualBalanceAccount;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.notification.enums.NotificationChannel;
import com.seahorse.store.domain.notification.enums.NotificationType;
import com.seahorse.store.domain.notification.model.NotificationConfig;
import com.seahorse.store.domain.notification.model.NotificationLog;
import com.seahorse.store.infrastructure.repository.DualBalanceAccountRepository;
import com.seahorse.store.infrastructure.repository.MemberRepository;
import com.seahorse.store.infrastructure.repository.NotificationConfigRepository;
import com.seahorse.store.infrastructure.repository.NotificationLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChannelNotificationAppService {

    private final NotificationConfigRepository configRepository;
    private final NotificationLogRepository logRepository;
    private final MemberRepository memberRepository;
    private final DualBalanceAccountRepository dualBalanceAccountRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final RestTemplate restTemplate = new RestTemplate();

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * 获取或初始化当前租户的推送配置
     */
    @Transactional
    public NotificationConfig getConfig() {
        String tenantId = getEffectiveTenantId();
        return configRepository.findByTenantId(tenantId).orElseGet(() -> {
            NotificationConfig defaultConfig = NotificationConfig.builder()
                    .tenantId(tenantId)
                    .wechatEnabled(true)
                    .wechatAppId("wx88a666999seahorse")
                    .wechatAppSecret("")
                    .wechatToken("seahorse_token_123456")
                    .wechatAesKey("seahorse_aes_key_mock_abcdefghijklmnopqrst")
                    .wechatQrCodeUrl("https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=https://mp.weixin.qq.com/s/seahorse_demo")
                    .wechatConsumeTemplateId("OPENTM413385970")
                    .wechatRechargeTemplateId("OPENTM206215005")
                    .wechatMarketingTemplateId("OPENTM408372691")
                    .alipayEnabled(true)
                    .alipayAppId("2021000188899999")
                    .alipayPrivateKey("")
                    .alipayPublicKey("")
                    .alipayQrCodeUrl("https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=https://alipay.com/life/seahorse_demo")
                    .alipayConsumeTemplateId("ALIPAY_TMPL_CONSUME_01")
                    .alipayMarketingTemplateId("ALIPAY_TMPL_MARKETING_01")
                    .mockPushEnabled(true)
                    .autoPushOnCheckout(true)
                    .autoPushOnRecharge(true)
                    .autoPushOnMarketing(true)
                    .build();
            return configRepository.save(defaultConfig);
        });
    }

    /**
     * 保存或更新推送配置
     */
    @Transactional
    public NotificationConfig saveConfig(NotificationConfig input) {
        String tenantId = getEffectiveTenantId();
        NotificationConfig config = configRepository.findByTenantId(tenantId).orElseGet(() ->
                NotificationConfig.builder().tenantId(tenantId).build());

        config.setWechatEnabled(input.getWechatEnabled());
        config.setWechatAppId(input.getWechatAppId());
        config.setWechatAppSecret(input.getWechatAppSecret());
        config.setWechatToken(input.getWechatToken());
        config.setWechatAesKey(input.getWechatAesKey());
        config.setWechatQrCodeUrl(input.getWechatQrCodeUrl());
        config.setWechatConsumeTemplateId(input.getWechatConsumeTemplateId());
        config.setWechatRechargeTemplateId(input.getWechatRechargeTemplateId());
        config.setWechatMarketingTemplateId(input.getWechatMarketingTemplateId());

        config.setAlipayEnabled(input.getAlipayEnabled());
        config.setAlipayAppId(input.getAlipayAppId());
        config.setAlipayPrivateKey(input.getAlipayPrivateKey());
        config.setAlipayPublicKey(input.getAlipayPublicKey());
        config.setAlipayQrCodeUrl(input.getAlipayQrCodeUrl());
        config.setAlipayConsumeTemplateId(input.getAlipayConsumeTemplateId());
        config.setAlipayMarketingTemplateId(input.getAlipayMarketingTemplateId());

        config.setMockPushEnabled(input.getMockPushEnabled());
        config.setAutoPushOnCheckout(input.getAutoPushOnCheckout());
        config.setAutoPushOnRecharge(input.getAutoPushOnRecharge());
        config.setAutoPushOnMarketing(input.getAutoPushOnMarketing());
        if (input.getVoiceBroadcastRepeatCount() != null) {
            config.setVoiceBroadcastRepeatCount(Math.max(1, Math.min(5, input.getVoiceBroadcastRepeatCount())));
        }

        return configRepository.save(config);
    }

    /**
     * 结账完成时：自动触发消费动账消息推送
     */
    @Transactional
    public void sendConsumeNotification(BillingOrder order, List<PaymentRecord> paymentRecords, Member member) {
        NotificationConfig config = getConfig();
        if (!Boolean.TRUE.equals(config.getAutoPushOnCheckout())) {
            log.info("【消息推送】租户已关闭结账自动推送消费动账通知, orderNo={}", order.getOrderNo());
            return;
        }

        if (member != null && Boolean.FALSE.equals(member.getPushNotificationEnabled())) {
            log.info("【消息推送】会员已自主关闭消息通知, member={}", member.getName());
            return;
        }

        // 构造支付渠道明细摘要
        StringBuilder payDetails = new StringBuilder();
        if (paymentRecords != null && !paymentRecords.isEmpty()) {
            for (PaymentRecord pr : paymentRecords) {
                if (payDetails.length() > 0) payDetails.append(" + ");
                payDetails.append(pr.getChannel() != null ? pr.getChannel().name() : "支付")
                        .append("￥").append(pr.getAmount());
            }
        } else {
            payDetails.append("实收￥").append(order.getActualAmount());
        }

        // 查询会员剩余储值与积分
        BigDecimal remainBal = BigDecimal.ZERO;
        if (member != null) {
            Optional<DualBalanceAccount> accOpt = dualBalanceAccountRepository.findByMemberId(member.getId());
            if (accOpt.isPresent()) {
                remainBal = accOpt.get().getTotalBalance();
            }
        }

        String memberName = member != null ? member.getName() : (order.getCustomerName() != null ? order.getCustomerName() : "散客");
        String phone = member != null ? member.getPhone() : order.getCustomerPhone();
        String storeName = order.getSpaceName() != null ? (order.getSpaceName() + " (门店)") : "海马体验旗舰店";
        String timeStr = order.getSettledAt() != null ? order.getSettledAt().format(DATE_TIME_FORMATTER) : LocalDateTime.now().format(DATE_TIME_FORMATTER);

        Map<String, Object> tplData = new LinkedHashMap<>();
        tplData.put("first", createField("尊敬的 " + memberName + " 贵宾，您的消费账单已结清，祝您生活愉快！", "#173177"));
        tplData.put("keyword1", createField(storeName, "#333333"));
        tplData.put("keyword2", createField("￥" + order.getActualAmount(), "#ff6600"));
        tplData.put("keyword3", createField(payDetails.toString(), "#333333"));
        tplData.put("keyword4", createField(order.getOrderNo(), "#666666"));
        tplData.put("keyword5", createField(timeStr, "#666666"));
        tplData.put("remark", createField("卡内剩余可用储值: ￥" + remainBal + (member != null ? ("，积分: " + member.getPoints()) : "") + "。点击查看电子账单明细。", "#059669"));

        String textSummary = String.format("【消费动账提醒】\n门店: %s\n实付金额: ￥%s\n支付方式: %s\n账单号: %s\n时间: %s\n账户结余: ￥%s",
                storeName, order.getActualAmount(), payDetails, order.getOrderNo(), timeStr, remainBal);

        // 微信公众号推送
        if (Boolean.TRUE.equals(config.getWechatEnabled())) {
            boolean hasWechat = member != null && Boolean.TRUE.equals(member.getWechatFollowStatus());
            String openId = member != null && member.getWechatOpenId() != null ? member.getWechatOpenId() : "mock_wx_openid_" + (phone != null ? phone : "guest");
            dispatchChannelMessage(order.getTenantId(), order.getStoreId(), member != null ? member.getId() : null,
                    memberName, phone, NotificationChannel.WECHAT_MP, NotificationType.CONSUME_NOTICE,
                    openId, config.getWechatConsumeTemplateId(), "消费结账成功通知", textSummary, tplData, config, hasWechat);
        }

        // 支付宝生活号推送
        if (Boolean.TRUE.equals(config.getAlipayEnabled()) && member != null && Boolean.TRUE.equals(member.getAlipayFollowStatus())) {
            String alipayUid = member.getAlipayUserId() != null ? member.getAlipayUserId() : "2088" + (phone != null ? phone : "000000");
            dispatchChannelMessage(order.getTenantId(), order.getStoreId(), member.getId(),
                    memberName, phone, NotificationChannel.ALIPAY_LIFE, NotificationType.CONSUME_NOTICE,
                    alipayUid, config.getAlipayConsumeTemplateId(), "消费动账提醒", textSummary, tplData, config, true);
        }
    }

    /**
     * 储值充值到账时：自动触发充值变动通知
     */
    @Transactional
    public void sendRechargeNotification(Member member, DualBalanceAccount account, BigDecimal principal, BigDecimal gift, String operatorName) {
        NotificationConfig config = getConfig();
        if (!Boolean.TRUE.equals(config.getAutoPushOnRecharge())) {
            log.info("【消息推送】租户已关闭充值动账自动推送, member={}", member.getName());
            return;
        }

        if (Boolean.FALSE.equals(member.getPushNotificationEnabled())) {
            return;
        }

        String timeStr = LocalDateTime.now().format(DATE_TIME_FORMATTER);
        Map<String, Object> tplData = new LinkedHashMap<>();
        tplData.put("first", createField("尊敬的会员 " + member.getName() + "，您的会员卡充值已成功到账！", "#173177"));
        tplData.put("keyword1", createField("￥" + principal, "#059669"));
        tplData.put("keyword2", createField("￥" + (gift != null ? gift : BigDecimal.ZERO), "#ff6600"));
        tplData.put("keyword3", createField("￥" + account.getTotalBalance(), "#2563eb"));
        tplData.put("keyword4", createField(operatorName != null ? operatorName : "前台收银台", "#666666"));
        tplData.put("keyword5", createField(timeStr, "#666666"));
        tplData.put("remark", createField("本金账户: ￥" + account.getPrincipalBalance() + "，赠送账户: ￥" + account.getGiftBalance() + "。感谢您的支持！", "#10b981"));

        String textSummary = String.format("【储值充值到账】\n充值本金: ￥%s\n赠送金: ￥%s\n卡内当前总余额: ￥%s\n经办人: %s\n时间: %s",
                principal, gift, account.getTotalBalance(), operatorName, timeStr);

        if (Boolean.TRUE.equals(config.getWechatEnabled())) {
            boolean hasWechat = Boolean.TRUE.equals(member.getWechatFollowStatus());
            String openId = member.getWechatOpenId() != null ? member.getWechatOpenId() : "mock_wx_openid_" + member.getPhone();
            dispatchChannelMessage(member.getTenantId(), TenantContext.getStoreId(), member.getId(),
                    member.getName(), member.getPhone(), NotificationChannel.WECHAT_MP, NotificationType.RECHARGE_NOTICE,
                    openId, config.getWechatRechargeTemplateId(), "会员储值充值到账提醒", textSummary, tplData, config, hasWechat);
        }

        if (Boolean.TRUE.equals(config.getAlipayEnabled()) && Boolean.TRUE.equals(member.getAlipayFollowStatus())) {
            String alipayUid = member.getAlipayUserId() != null ? member.getAlipayUserId() : "2088" + member.getPhone();
            dispatchChannelMessage(member.getTenantId(), TenantContext.getStoreId(), member.getId(),
                    member.getName(), member.getPhone(), NotificationChannel.ALIPAY_LIFE, NotificationType.RECHARGE_NOTICE,
                    alipayUid, config.getAlipayConsumeTemplateId(), "支付宝生活号充值到账提醒", textSummary, tplData, config, true);
        }
    }

    /**
     * 营销活动广播：批量推送给所有已关注微信公众号或支付宝生活号的会员
     */
    @Transactional
    public Map<String, Object> broadcastMarketing(String campaignTitle, String content, String linkUrl) {
        String tenantId = getEffectiveTenantId();
        NotificationConfig config = getConfig();

        List<Member> wechatMembers = memberRepository.findByTenantIdAndWechatFollowStatusTrue(tenantId);
        List<Member> alipayMembers = memberRepository.findByTenantIdAndAlipayFollowStatusTrue(tenantId);

        Set<Long> processedMembers = new HashSet<>();
        int wechatCount = 0;
        int alipayCount = 0;

        String timeStr = LocalDateTime.now().format(DATE_TIME_FORMATTER);

        for (Member m : wechatMembers) {
            if (Boolean.FALSE.equals(m.getPushNotificationEnabled())) continue;
            processedMembers.add(m.getId());

            Map<String, Object> tplData = new LinkedHashMap<>();
            tplData.put("first", createField("🎉 尊敬的会员 " + m.getName() + "，门店特惠福利已上线！", "#e11d48"));
            tplData.put("keyword1", createField(campaignTitle, "#1e293b"));
            tplData.put("keyword2", createField("全体认证会员特享", "#2563eb"));
            tplData.put("keyword3", createField(timeStr, "#64748b"));
            tplData.put("remark", createField(content + " 点击立即领券享特权！", "#059669"));

            String textSummary = String.format("【特惠营销活动】%s\n活动内容: %s\n发布时间: %s", campaignTitle, content, timeStr);
            String openId = m.getWechatOpenId() != null ? m.getWechatOpenId() : "mock_wx_openid_" + m.getPhone();

            dispatchChannelMessage(tenantId, TenantContext.getStoreId(), m.getId(), m.getName(), m.getPhone(),
                    NotificationChannel.WECHAT_MP, NotificationType.MARKETING_CAMPAIGN,
                    openId, config.getWechatMarketingTemplateId(), campaignTitle, textSummary, tplData, config, true);
            wechatCount++;
        }

        for (Member m : alipayMembers) {
            if (Boolean.FALSE.equals(m.getPushNotificationEnabled())) continue;
            if (processedMembers.contains(m.getId()) && wechatCount > 0) {
                // 如果已在微信推送过，避免过度骚扰，可跳过或继续
            }
            Map<String, Object> tplData = new LinkedHashMap<>();
            tplData.put("first", createField("🔔 支付宝生活号专享福利: " + campaignTitle, "#e11d48"));
            tplData.put("keyword1", createField(campaignTitle, "#1e293b"));
            tplData.put("keyword2", createField(timeStr, "#64748b"));
            tplData.put("remark", createField(content, "#059669"));

            String textSummary = String.format("【支付宝生活号活动推送】%s\n%s", campaignTitle, content);
            String alipayUid = m.getAlipayUserId() != null ? m.getAlipayUserId() : "2088" + m.getPhone();

            dispatchChannelMessage(tenantId, TenantContext.getStoreId(), m.getId(), m.getName(), m.getPhone(),
                    NotificationChannel.ALIPAY_LIFE, NotificationType.MARKETING_CAMPAIGN,
                    alipayUid, config.getAlipayMarketingTemplateId(), campaignTitle, textSummary, tplData, config, true);
            alipayCount++;
        }

        Map<String, Object> result = new HashMap<>();
        result.put("wechatCount", wechatCount);
        result.put("alipayCount", alipayCount);
        result.put("totalSent", wechatCount + alipayCount);
        result.put("message", String.format("全渠道营销通知推送成功: 微信已触达 %d 人, 支付宝已触达 %d 人", wechatCount, alipayCount));
        return result;
    }

    /**
     * 发送测试动账/营销消息
     */
    @Transactional
    public NotificationLog sendTestNotification(String channelStr, String targetPhone, String msgTypeStr) {
        String tenantId = getEffectiveTenantId();
        NotificationConfig config = getConfig();

        NotificationChannel channel = NotificationChannel.WECHAT_MP;
        try {
            channel = NotificationChannel.valueOf(channelStr);
        } catch (Exception ignored) {}

        NotificationType msgType = NotificationType.TEST_NOTICE;
        try {
            msgType = NotificationType.valueOf(msgTypeStr);
        } catch (Exception ignored) {}

        Member member = null;
        if (targetPhone != null && !targetPhone.trim().isEmpty()) {
            member = memberRepository.findByTenantIdAndPhone(tenantId, targetPhone.trim()).orElse(null);
        }

        String memberName = member != null ? member.getName() : "测试体验用户";
        String phone = member != null ? member.getPhone() : (targetPhone != null ? targetPhone : "13800138000");
        String timeStr = LocalDateTime.now().format(DATE_TIME_FORMATTER);

        String templateId = channel == NotificationChannel.WECHAT_MP ?
                config.getWechatConsumeTemplateId() : config.getAlipayConsumeTemplateId();

        Map<String, Object> tplData = new LinkedHashMap<>();
        tplData.put("first", createField("【测试】尊敬的 " + memberName + "，这是来自海马汇全渠道消息中心的测试推送。", "#173177"));
        tplData.put("keyword1", createField("海马智慧体验旗舰店", "#333333"));
        tplData.put("keyword2", createField("￥168.00", "#ff6600"));
        tplData.put("keyword3", createField("微信支付￥100.00 + 储值扣减￥68.00", "#333333"));
        tplData.put("keyword4", createField("TEST" + System.currentTimeMillis(), "#666666"));
        tplData.put("keyword5", createField(timeStr, "#666666"));
        tplData.put("remark", createField("此条为沙箱模拟测试消息，用于验证微信公众号与生活号消息格式与即时推送管道正常运行。", "#059669"));

        String textSummary = String.format("【全渠道测试通知】\n目标用户: %s (%s)\n渠道: %s\n时间: %s\n状态: 沙箱全真模拟已送达",
                memberName, phone, channel.getDescription(), timeStr);

        String targetOpenId = channel == NotificationChannel.WECHAT_MP ?
                (member != null && member.getWechatOpenId() != null ? member.getWechatOpenId() : "mock_wx_openid_" + phone) :
                (member != null && member.getAlipayUserId() != null ? member.getAlipayUserId() : "2088" + phone);

        return dispatchChannelMessage(tenantId, TenantContext.getStoreId(), member != null ? member.getId() : null,
                memberName, phone, channel, msgType, targetOpenId, templateId, "全渠道即时推送测试", textSummary, tplData, config, true);
    }

    /**
     * 绑定或更新会员全渠道信息 (微信 OpenID、支付宝 UserID 与关注状态)
     */
    @Transactional
    public Member bindMemberChannel(Long memberId, String channel, String openId, Boolean followStatus) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new IllegalArgumentException("未找到对应会员: " + memberId));
        TenantContext.assertTenantAccess(member.getTenantId());

        if ("WECHAT".equalsIgnoreCase(channel) || "WECHAT_MP".equalsIgnoreCase(channel)) {
            member.setWechatBound(true);
            member.setWechatOpenId(openId != null && !openId.isEmpty() ? openId : ("wx_openid_" + member.getPhone()));
            member.setWechatFollowStatus(Boolean.TRUE.equals(followStatus));
            if (Boolean.TRUE.equals(followStatus) && member.getWechatFollowTime() == null) {
                member.setWechatFollowTime(LocalDateTime.now());
            }
        } else if ("ALIPAY".equalsIgnoreCase(channel) || "ALIPAY_LIFE".equalsIgnoreCase(channel)) {
            member.setAlipayUserId(openId != null && !openId.isEmpty() ? openId : ("2088" + member.getPhone()));
            member.setAlipayFollowStatus(Boolean.TRUE.equals(followStatus));
            if (Boolean.TRUE.equals(followStatus) && member.getAlipayFollowTime() == null) {
                member.setAlipayFollowTime(LocalDateTime.now());
            }
        }

        return memberRepository.save(member);
    }

    /**
     * 模拟顾客手机扫码关注公众号/生活号
     */
    @Transactional
    public Map<String, Object> simulateFollow(String phone, String channel) {
        String tenantId = getEffectiveTenantId();
        Member member = memberRepository.findByTenantIdAndPhone(tenantId, phone.trim()).orElse(null);
        if (member == null) {
            // 自动建会员
            member = Member.builder()
                    .tenantId(tenantId)
                    .memberNo("HM" + (int)((Math.random() * 9 + 1) * 100000))
                    .name("扫码新关注会员")
                    .phone(phone.trim())
                    .level(com.seahorse.store.domain.member.enums.MemberLevel.REGULAR)
                    .totalSpent(BigDecimal.ZERO)
                    .visitCount(0)
                    .points(50) // 关注送 50 积分
                    .status("ACTIVE")
                    .pushNotificationEnabled(true)
                    .build();
            member = memberRepository.save(member);
        }

        if ("ALIPAY".equalsIgnoreCase(channel) || "ALIPAY_LIFE".equalsIgnoreCase(channel)) {
            member.setAlipayUserId("2088" + phone);
            member.setAlipayFollowStatus(true);
            member.setAlipayFollowTime(LocalDateTime.now());
        } else {
            member.setWechatBound(true);
            member.setWechatOpenId("wx_oid_" + phone + "_" + System.currentTimeMillis() % 10000);
            member.setWechatFollowStatus(true);
            member.setWechatFollowTime(LocalDateTime.now());
        }

        member = memberRepository.save(member);

        // 发送关注欢迎与开卡赠礼模板通知
        Map<String, Object> tplData = new LinkedHashMap<>();
        tplData.put("first", createField("🎉 欢迎关注海马汇官方公众号！已自动为您绑定会员专属权益。", "#173177"));
        tplData.put("keyword1", createField(member.getName(), "#333333"));
        tplData.put("keyword2", createField(member.getMemberNo(), "#2563eb"));
        tplData.put("keyword3", createField(LocalDateTime.now().format(DATE_TIME_FORMATTER), "#666666"));
        tplData.put("remark", createField("关注礼已到账：赠送50积分及新手专属礼遇！后续您的每次消费与优惠活动将第一时间推送至此。", "#059669"));

        String textSummary = String.format("【公众号关注成功】\n会员姓名: %s\n会员卡号: %s\n积分赠送: +50分\n状态: 动账通知已激活",
                member.getName(), member.getMemberNo());

        NotificationConfig config = getConfig();
        dispatchChannelMessage(tenantId, TenantContext.getStoreId(), member.getId(), member.getName(), member.getPhone(),
                "ALIPAY".equalsIgnoreCase(channel) ? NotificationChannel.ALIPAY_LIFE : NotificationChannel.WECHAT_MP,
                NotificationType.TEST_NOTICE,
                "ALIPAY".equalsIgnoreCase(channel) ? member.getAlipayUserId() : member.getWechatOpenId(),
                config.getWechatConsumeTemplateId(), "关注公众号绑定成功", textSummary, tplData, config, true);

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("member", member);
        res.put("message", "扫码关注并关联会员档案成功！已自动激活微信公众号/生活号消费动账推送管道。");
        return res;
    }

    /**
     * 分页查询推送历史流水
     */
    public Page<NotificationLog> getNotificationLogs(int page, int size, Long memberId) {
        String tenantId = getEffectiveTenantId();
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.max(1, size));
        if (memberId != null) {
            return logRepository.findByTenantIdAndMemberIdOrderBySentAtDesc(tenantId, memberId, pageable);
        }
        return logRepository.findByTenantIdOrderBySentAtDesc(tenantId, pageable);
    }

    /**
     * 获取最近 100 条推送记录
     */
    public List<NotificationLog> getRecentNotificationLogs() {
        return getRecentNotificationLogs(null);
    }

    /**
     * 获取最近推送记录（支持按指定会员 ID 过滤）
     */
    public List<NotificationLog> getRecentNotificationLogs(Long memberId) {
        String tenantId = getEffectiveTenantId();
        if (memberId != null) {
            memberRepository.findById(memberId).ifPresent(m -> TenantContext.assertTenantAccess(m.getTenantId()));
            return logRepository.findByTenantIdAndMemberIdOrderBySentAtDesc(tenantId, memberId);
        }
        return logRepository.findTop100ByTenantIdOrderBySentAtDesc(tenantId);
    }

    // --- 私有辅助方法 ---

    private NotificationLog dispatchChannelMessage(
            String tenantId, String storeId, Long memberId, String memberName, String phone,
            NotificationChannel channel, NotificationType msgType, String targetOpenId,
            String templateId, String title, String textSummary, Map<String, Object> templateData,
            NotificationConfig config, boolean isFollowed) {

        String jsonPayload = "";
        try {
            jsonPayload = objectMapper.writeValueAsString(templateData);
        } catch (Exception e) {
            jsonPayload = "{}";
        }

        boolean isMock = Boolean.TRUE.equals(config.getMockPushEnabled()) ||
                (channel == NotificationChannel.WECHAT_MP && (config.getWechatAppSecret() == null || config.getWechatAppSecret().trim().isEmpty()));

        String status = "SUCCESS";
        String errMsg = null;

        if (isMock) {
            log.info("📢 >>> [全渠道消息推送-沙箱模拟] 渠道={}, 接收人={}({}), OpenID={}, 标题={}, 内容=\n{}",
                    channel.getDescription(), memberName, phone, targetOpenId, title, textSummary);
            status = isFollowed ? "SUCCESS" : "UNSUBSCRIBED (模拟)";
        } else {
            // 真实官方接口发起调用 (以微信公众平台模板消息为例)
            try {
                if (channel == NotificationChannel.WECHAT_MP) {
                    callWechatTemplateSend(config, targetOpenId, templateId, templateData);
                    status = "SUCCESS";
                    log.info("📢 >>> [微信公众平台官方API推送成功] OpenID={}, TemplateId={}", targetOpenId, templateId);
                } else {
                    // 支付宝生活号/开放平台单发模板消息
                    log.info("📢 >>> [支付宝开放平台API推送模拟成功] UserId={}", targetOpenId);
                    status = "SUCCESS";
                }
            } catch (Exception ex) {
                log.error("📢 >>> [全渠道消息推送失败] channel={}, target={}", channel, targetOpenId, ex);
                status = "FAILED";
                errMsg = ex.getMessage();
            }
        }

        NotificationLog logRecord = NotificationLog.builder()
                .tenantId(tenantId != null ? tenantId : getEffectiveTenantId())
                .storeId(storeId)
                .memberId(memberId)
                .memberName(memberName)
                .phone(phone)
                .channel(channel)
                .msgType(msgType)
                .targetOpenId(targetOpenId)
                .templateId(templateId)
                .title(title)
                .content(textSummary)
                .dataJson(jsonPayload)
                .status(status)
                .errorMessage(errMsg)
                .sentAt(LocalDateTime.now())
                .build();

        return logRepository.save(logRecord);
    }

    private void callWechatTemplateSend(NotificationConfig config, String openId, String templateId, Map<String, Object> data) {
        String tokenUrl = String.format("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=%s&secret=%s",
                config.getWechatAppId(), config.getWechatAppSecret());
        Map tokenRes = restTemplate.getForObject(tokenUrl, Map.class);
        if (tokenRes == null || !tokenRes.containsKey("access_token")) {
            throw new RuntimeException("获取微信AccessToken失败: " + tokenRes);
        }
        String accessToken = (String) tokenRes.get("access_token");

        String sendUrl = "https://api.weixin.qq.com/cgi-bin/message/template/send?access_token=" + accessToken;
        Map<String, Object> body = new HashMap<>();
        body.put("touser", openId);
        body.put("template_id", templateId);
        body.put("data", data);

        ResponseEntity<Map> res = restTemplate.postForEntity(sendUrl, body, Map.class);
        if (res.getBody() != null && res.getBody().containsKey("errcode")) {
            Integer errcode = (Integer) res.getBody().get("errcode");
            if (errcode != null && errcode != 0) {
                throw new RuntimeException("微信推送错误码: " + errcode + ", 说明: " + res.getBody().get("errmsg"));
            }
        }
    }

    private Map<String, String> createField(String value, String color) {
        Map<String, String> map = new HashMap<>();
        map.put("value", value);
        map.put("color", color != null ? color : "#173177");
        return map;
    }

    private String getEffectiveTenantId() {
        String t = TenantContext.getTenantId();
        return (t != null && !t.isEmpty()) ? t : "T001";
    }
}
