package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.dto.member.MemberCommands;
import com.seahorse.store.application.dto.member.MemberProfileVO;
import com.seahorse.store.application.service.MemberSelfAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.member.model.MemberPreference;
import com.seahorse.store.infrastructure.repository.MemberRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 顾客会员自主中心控制器
 * 提供会员查看与修改个人资料、管理个人海马体偏好记忆与资产账单查询
 */
@Tag(name = "08. 会员自主中心", description = "会员自主查看与修改资料、维护海马体偏好与卡包资产")
@RestController
@RequestMapping("/api/member-portal")
@RequiredArgsConstructor
public class MemberPortalController {

    private final MemberSelfAppService memberSelfAppService;
    private final MemberRepository memberRepository;

    private Long resolveMemberId(Long memberId, String phone) {
        String tenantId = TenantContext.getTenantId();

        // 1. 优先以精准手机号匹配当前租户或系统中的真实注册会员
        if (phone != null && !phone.trim().isEmpty()) {
            String p = phone.trim();
            if (tenantId != null && !"PLATFORM".equalsIgnoreCase(tenantId)) {
                java.util.Optional<Member> m = memberRepository.findByTenantIdAndPhone(tenantId, p);
                if (m.isPresent()) {
                    return m.get().getId();
                }
            }
            java.util.Optional<Member> m = memberRepository.findByPhone(p);
            if (m.isPresent()) {
                return m.get().getId();
            }
        }

        // 2. 若传入了 memberId，必须校验其真实存在且与传入的 phone/租户一致（防前端mock ID与后端冲突导致串号）
        if (memberId != null && memberId > 0) {
            java.util.Optional<Member> mOpt = memberRepository.findById(memberId);
            if (mOpt.isPresent()) {
                Member m = mOpt.get();
                if (phone != null && !phone.trim().isEmpty() && !phone.trim().equals(m.getPhone())) {
                    // ID 与手机号不一致，说明该 ID 来自前端临时序列，丢弃并返回 null
                } else if (tenantId == null || "PLATFORM".equalsIgnoreCase(tenantId) || tenantId.equalsIgnoreCase(m.getTenantId())) {
                    return memberId;
                }
            }
        }

        // 3. 从当前登录态获取
        Long uid = TenantContext.getUserId();
        if (uid != null && uid > 0) {
            return uid;
        }

        return null;
    }

    @Operation(summary = "会员获取个人完整档案与资产画像")
    @GetMapping("/profile")
    public ApiResponse<MemberProfileVO> getMyProfile(
            @RequestParam(value = "memberId", required = false) Long memberId,
            @RequestParam(value = "phone", required = false) String phone) {
        Long targetId = resolveMemberId(memberId, phone);
        if (targetId == null) {
            return ApiResponse.error(404, "未找到该会员档案");
        }
        return ApiResponse.success(memberSelfAppService.getMyProfile(targetId));
    }

    @Operation(summary = "会员自主修改个人信息 (姓名、性别、生日、手机号)")
    @PutMapping("/profile")
    public ApiResponse<MemberProfileVO> updateMyProfile(
            @RequestParam(value = "memberId", required = false) Long memberId,
            @RequestParam(value = "phone", required = false) String phone,
            @RequestBody MemberCommands.UpdateMemberProfileCommand cmd) {
        Long targetId = resolveMemberId(memberId, phone);
        if (targetId == null) {
            return ApiResponse.error(404, "未找到该会员档案");
        }
        return ApiResponse.success("个人信息更新成功", memberSelfAppService.updateMyProfile(targetId, cmd));
    }

    @Operation(summary = "会员自主添加/修改海马体个性偏好特征")
    @PostMapping("/preference")
    public ApiResponse<MemberPreference> saveMyPreference(
            @RequestParam(value = "memberId", required = false) Long memberId,
            @RequestParam(value = "phone", required = false) String phone,
            @RequestBody MemberCommands.SavePreferenceCommand cmd) {
        Long targetId = resolveMemberId(memberId, phone);
        if (targetId == null) {
            return ApiResponse.error(404, "未找到该会员档案");
        }
        return ApiResponse.success("海马偏好特征更新成功", memberSelfAppService.saveMyPreference(targetId, cmd));
    }

    @Operation(summary = "会员查看个人历史消费订单")
    @GetMapping("/orders")
    public ApiResponse<List<BillingOrder>> getMyOrders(
            @RequestParam(value = "memberId", required = false) Long memberId,
            @RequestParam(value = "phone", required = false) String phone) {
        Long targetId = resolveMemberId(memberId, phone);
        if (targetId == null) {
            return ApiResponse.error(404, "未找到该会员档案");
        }
        return ApiResponse.success(memberSelfAppService.getMyOrders(targetId));
    }
}
