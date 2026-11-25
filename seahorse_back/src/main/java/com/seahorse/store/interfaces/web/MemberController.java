package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.dto.member.MemberCommands.IssueTimeCardCommand;
import com.seahorse.store.application.dto.member.MemberCommands.MemberRegisterCommand;
import com.seahorse.store.application.dto.member.MemberCommands.RechargeCommand;
import com.seahorse.store.application.dto.member.MemberCommands.SavePreferenceCommand;
import com.seahorse.store.application.dto.member.MemberProfileVO;
import com.seahorse.store.application.service.MemberAssetAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.member.model.DualBalanceAccount;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.member.model.MemberPreference;
import com.seahorse.store.domain.member.model.TimeCardBucket;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 会员与海马体资产接入控制器
 * 符合阿里巴巴与DDD接口层规范
 */
@Tag(name = "04. 会员资产与“海马体”记忆档案", description = "会员全生命周期管理、双轨储值、次卡桶与海马体偏好标签")
@RestController
@RequestMapping("/api/member")
@RequiredArgsConstructor
public class MemberController {

    private final MemberAssetAppService memberAssetAppService;
    private final com.seahorse.store.application.service.AuditLogAppService auditLogAppService;
    private final jakarta.servlet.http.HttpServletRequest request;

    @Operation(summary = "会员注册开卡")
    @PostMapping("/register")
    public ApiResponse<Member> register(@RequestBody MemberRegisterCommand cmd) {
        if (!com.seahorse.store.context.TenantContext.isAuthenticated()) {
            // 匿名扫码自助注册强制清零初始储值/赠金及越权指定等级
            cmd.setInitialPrincipal(java.math.BigDecimal.ZERO);
            cmd.setInitialGift(java.math.BigDecimal.ZERO);
            cmd.setLevel(null);
        }
        Member member = memberAssetAppService.registerMember(cmd);
        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = com.seahorse.store.context.TenantContext.getUsername() != null ? com.seahorse.store.context.TenantContext.getUsername() : "cashier";
        java.math.BigDecimal p = cmd.getInitialPrincipal() != null ? cmd.getInitialPrincipal() : java.math.BigDecimal.ZERO;
        java.math.BigDecimal g = cmd.getInitialGift() != null ? cmd.getInitialGift() : java.math.BigDecimal.ZERO;
        String lvl = member.getLevel() != null ? member.getLevel().getDescription() : "普卡会员";
        auditLogAppService.recordLog(
                member.getTenantId(),
                null,
                cmd.getStoreId(),
                null,
                null,
                username,
                null,
                "新会员开卡建档",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("录入会员: %s (%s), 初始等级: %s, 首充本金: ￥%s, 赠送金: ￥%s",
                        member.getName(), member.getPhone(), lvl, p, g)
        );
        return ApiResponse.success("会员注册成功", member);
    }

    @Operation(summary = "会员双轨储值充值 (本金 + 赠送金)")
    @PostMapping("/recharge")
    public ApiResponse<DualBalanceAccount> recharge(@RequestBody RechargeCommand cmd) {
        DualBalanceAccount account = memberAssetAppService.rechargeDualBalance(cmd);
        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = com.seahorse.store.context.TenantContext.getUsername() != null ? com.seahorse.store.context.TenantContext.getUsername() : "cashier";
        auditLogAppService.recordLog(
                account.getTenantId(),
                null,
                null,
                null,
                null,
                username,
                null,
                "会员储值充值",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("会员ID: %d 储值充值: 本金 ￥%s, 赠金 ￥%s, 账户可用本金余额: ￥%s",
                        cmd.getMemberId(), cmd.getPrincipalAmount(), cmd.getGiftAmount(), account.getPrincipalBalance())
        );
        return ApiResponse.success("充值成功", account);
    }

    @Operation(summary = "发放/售卖计量次卡")
    @PostMapping("/issue-time-card")
    public ApiResponse<TimeCardBucket> issueTimeCard(@RequestBody IssueTimeCardCommand cmd) {
        TimeCardBucket bucket = memberAssetAppService.issueTimeCard(cmd);
        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = com.seahorse.store.context.TenantContext.getUsername() != null ? com.seahorse.store.context.TenantContext.getUsername() : "cashier";
        auditLogAppService.recordLog(
                com.seahorse.store.context.TenantContext.getTenantId(),
                null,
                com.seahorse.store.context.TenantContext.getStoreId(),
                null,
                null,
                username,
                null,
                "发放/售卖次卡",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("会员ID: %d 购买次卡: %s, 充入次数: %d 次",
                        cmd.getMemberId(), cmd.getSkuName(), cmd.getTotalTimes())
        );
        return ApiResponse.success("次卡发放成功", bucket);
    }

    @Operation(summary = "【海马体核心】保存/更新会员个性偏好记忆标签")
    @PostMapping("/preference")
    public ApiResponse<MemberPreference> savePreference(@RequestBody SavePreferenceCommand cmd) {
        MemberPreference pref = memberAssetAppService.savePreference(cmd);
        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = com.seahorse.store.context.TenantContext.getUsername() != null ? com.seahorse.store.context.TenantContext.getUsername() : "staff";
        auditLogAppService.recordLog(
                com.seahorse.store.context.TenantContext.getTenantId(),
                null,
                com.seahorse.store.context.TenantContext.getStoreId(),
                null,
                null,
                username,
                null,
                "更新海马偏好记忆",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("会员ID: %d, 偏好标签: %s -> %s",
                        cmd.getMemberId(), cmd.getTagKey(), cmd.getTagValue())
        );
        return ApiResponse.success("海马记忆保存成功", pref);
    }

    @Operation(summary = "获取会员全量画像（基本资料、双轨储值、次卡、海马偏好标签）")
    @GetMapping("/{id}/profile")
    public ApiResponse<MemberProfileVO> getProfile(@PathVariable("id") Long id) {
        return ApiResponse.success(memberAssetAppService.getMemberProfile(id));
    }

    @Operation(summary = "查询/检索会员 (支持姓名、手机号、手机尾号搜索)")
    @GetMapping("/search")
    public ApiResponse<List<Member>> search(
            @RequestParam(value = "query", required = false) String query,
            @RequestParam(value = "tenantId", required = false) String tenantId,
            @RequestParam(value = "storeId", required = false) String storeId) {
        return ApiResponse.success(memberAssetAppService.searchMembers(query, tenantId, storeId));
    }

    @Operation(summary = "获取会员基础档案详情")
    @GetMapping("/{id}")
    public ApiResponse<Member> getMemberDetail(@PathVariable("id") Long id) {
        return ApiResponse.success(memberAssetAppService.getMemberProfile(id).getMember());
    }

    @Operation(summary = "保存/更新会员档案资料")
    @PutMapping("/{id}")
    public ApiResponse<Member> updateMemberDetail(
            @PathVariable("id") Long id,
            @RequestBody com.seahorse.store.application.dto.member.MemberCommands.UpdateMemberDetailCommand cmd) {
        Member updated = memberAssetAppService.updateMemberDetail(id, cmd);
        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = com.seahorse.store.context.TenantContext.getUsername() != null ? com.seahorse.store.context.TenantContext.getUsername() : "staff";
        auditLogAppService.recordLog(
                updated.getTenantId(),
                null,
                null,
                null,
                null,
                username,
                null,
                "修改会员档案",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("会员: %s (%s), 现等级: %s, 积分: %d",
                        updated.getName(), updated.getPhone(), updated.getLevel() != null ? updated.getLevel().getDescription() : "-", updated.getPoints())
        );
        return ApiResponse.success("会员档案保存成功", updated);
    }

    @Operation(summary = "调整会员可用积分")
    @PostMapping("/{id}/adjust-points")
    public ApiResponse<Member> adjustPoints(
            @PathVariable("id") Long id,
            @RequestBody com.seahorse.store.application.dto.member.MemberCommands.AdjustPointsCommand cmd) {
        Member updated = memberAssetAppService.adjustPoints(id, cmd);
        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = com.seahorse.store.context.TenantContext.getUsername() != null ? com.seahorse.store.context.TenantContext.getUsername() : "staff";
        auditLogAppService.recordLog(
                updated.getTenantId(),
                null,
                null,
                null,
                null,
                username,
                null,
                "调整会员积分",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("会员: %s (%s), 变动积分: %+d, 当前总积分: %d, 原因: %s",
                        updated.getName(), updated.getPhone(), cmd.getPointsDelta(), updated.getPoints(), cmd.getReason() != null ? cmd.getReason() : "人工调整")
        );
        return ApiResponse.success("积分调整成功", updated);
    }

    @Operation(summary = "调整会员奖励金")
    @PostMapping("/{id}/adjust-rewards")
    public ApiResponse<Member> adjustRewards(
            @PathVariable("id") Long id,
            @RequestBody com.seahorse.store.application.dto.member.MemberCommands.AdjustRewardsCommand cmd) {
        Member updated = memberAssetAppService.adjustRewards(id, cmd);
        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = com.seahorse.store.context.TenantContext.getUsername() != null ? com.seahorse.store.context.TenantContext.getUsername() : "staff";
        auditLogAppService.recordLog(
                updated.getTenantId(),
                null,
                null,
                null,
                null,
                username,
                null,
                "调整会员奖励金",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("会员: %s (%s), 变动奖励金: ￥%s, 原因: %s",
                        updated.getName(), updated.getPhone(), cmd.getRewardDelta(), cmd.getReason() != null ? cmd.getReason() : "人工调整")
        );
        return ApiResponse.success("奖励金调整成功", updated);
    }

    @Operation(summary = "设置/开启扣卡密码")
    @PostMapping("/{id}/card-password")
    public ApiResponse<Member> setCardPassword(
            @PathVariable("id") Long id,
            @RequestBody com.seahorse.store.application.dto.member.MemberCommands.SetCardPasswordCommand cmd) {
        Member updated = memberAssetAppService.setCardPassword(id, cmd);
        return ApiResponse.success("扣卡密码设置成功", updated);
    }

    @Operation(summary = "获取会员消费订单与履约流水")
    @GetMapping("/{id}/orders")
    public ApiResponse<List<BillingOrder>> getMemberOrders(@PathVariable("id") Long id) {
        return ApiResponse.success(memberAssetAppService.getMemberOrders(id));
    }

    @Operation(summary = "获取会员充值流水记录 (真实本金与赠金入账明细)")
    @GetMapping("/{id}/recharges")
    public ApiResponse<List<com.seahorse.store.domain.member.model.MemberRechargeRecord>> getMemberRecharges(@PathVariable("id") Long id) {
        return ApiResponse.success(memberAssetAppService.getMemberRecharges(id));
    }

    @Operation(summary = "获取全量会员等级成长与晋升规则阶梯")
    @GetMapping("/levels/rules")
    public ApiResponse<List<MemberProfileVO.MemberLevelRuleVO>> getLevelRules() {
        return ApiResponse.success(memberAssetAppService.getAllLevelRules());
    }
}
