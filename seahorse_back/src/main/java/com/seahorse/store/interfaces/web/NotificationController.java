package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.service.ChannelNotificationAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.notification.model.NotificationConfig;
import com.seahorse.store.domain.notification.model.NotificationLog;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Tag(name = "15. 全渠道公众号与生活号消息推送", description = "微信服务号与支付宝生活号扫码关注、动账提醒、储值通知与营销活动即时推送")
@RestController
@RequestMapping("/api/notification")
@RequiredArgsConstructor
public class NotificationController {

    private final ChannelNotificationAppService notificationAppService;

    @Operation(summary = "获取全渠道推送与公众号对接配置")
    @GetMapping("/config")
    public ApiResponse<NotificationConfig> getConfig() {
        return ApiResponse.success("获取配置成功", notificationAppService.getConfig());
    }

    @Operation(summary = "保存/更新全渠道推送配置")
    @PostMapping("/config")
    public ApiResponse<NotificationConfig> saveConfig(@RequestBody NotificationConfig config) {
        return ApiResponse.success("配置已成功保存", notificationAppService.saveConfig(config));
    }

    @Operation(summary = "发送测试动账/营销模板消息")
    @PostMapping("/send-test")
    public ApiResponse<NotificationLog> sendTest(@RequestBody TestNotificationRequest req) {
        NotificationLog log = notificationAppService.sendTestNotification(req.getChannel(), req.getTargetPhone(), req.getMsgType());
        return ApiResponse.success("测试消息已发送 (模拟送达或官方API已提交)", log);
    }

    @Operation(summary = "全渠道广播营销活动消息给所有已关注会员")
    @PostMapping("/broadcast-marketing")
    public ApiResponse<Map<String, Object>> broadcastMarketing(@RequestBody MarketingBroadcastRequest req) {
        Map<String, Object> res = notificationAppService.broadcastMarketing(req.getCampaignTitle(), req.getContent(), req.getLinkUrl());
        return ApiResponse.success("营销活动全渠道即时推送完成", res);
    }

    @Operation(summary = "获取最近推送流水记录 (默认最近100条，支持按会员过滤)")
    @GetMapping("/logs")
    public ApiResponse<List<NotificationLog>> getLogs(
            @RequestParam(value = "memberId", required = false) Long memberId) {
        return ApiResponse.success(notificationAppService.getRecentNotificationLogs(memberId));
    }

    @Operation(summary = "绑定/解绑会员渠道标识 (微信OpenID/支付宝UserId/关注状态)")
    @PostMapping("/member/bind-channel")
    public ApiResponse<Member> bindMemberChannel(@RequestBody BindChannelRequest req) {
        Member member = notificationAppService.bindMemberChannel(req.getMemberId(), req.getChannel(), req.getOpenId(), req.getFollowStatus());
        return ApiResponse.success("会员全渠道绑定信息更新成功", member);
    }

    @Operation(summary = "模拟顾客手机扫码关注公众号/生活号并激活会员档案")
    @PostMapping("/member/simulate-follow")
    public ApiResponse<Map<String, Object>> simulateFollow(@RequestBody SimulateFollowRequest req) {
        Map<String, Object> res = notificationAppService.simulateFollow(req.getPhone(), req.getChannel());
        return ApiResponse.success("模拟扫码关注成功", res);
    }

    // --- 请求参数 DTO ---

    @Data
    public static class TestNotificationRequest {
        private String channel; // WECHAT_MP, ALIPAY_LIFE
        private String targetPhone;
        private String msgType; // CONSUME_NOTICE, RECHARGE_NOTICE, MARKETING_CAMPAIGN, TEST_NOTICE
    }

    @Data
    public static class MarketingBroadcastRequest {
        private String campaignTitle;
        private String content;
        private String linkUrl;
    }

    @Data
    public static class BindChannelRequest {
        private Long memberId;
        private String channel;
        private String openId;
        private Boolean followStatus;
    }

    @Data
    public static class SimulateFollowRequest {
        private String phone;
        private String channel; // WECHAT_MP, ALIPAY_LIFE
    }
}
