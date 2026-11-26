package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.dto.member.MemberCommands;
import com.seahorse.store.application.dto.member.MemberProfileVO;
import com.seahorse.store.application.service.MemberSelfAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.common.ServiceException;
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

    private Long resolveAuthenticatedMemberId(Long requestedMemberId, String requestedPhone) {
        if (!TenantContext.isAuthenticated()) {
            throw new ServiceException(401, "请先登录会员账号");
        }
        String role = TenantContext.getRole();
        if (!"CUSTOMER_MEMBER".equalsIgnoreCase(role)) {
            throw new ServiceException(403, "仅限已登录会员访问会员自主中心");
        }

        Long uid = TenantContext.getUserId();
        if (uid == null || uid <= 0) {
            throw new ServiceException(401, "会员身份令牌无效，请重新登录");
        }

        Member currentMember = memberRepository.findById(uid)
                .orElseThrow(() -> new ServiceException(404, "未找到当前登录会员档案"));
        TenantContext.assertTenantAccess(currentMember.getTenantId());

        if (requestedMemberId != null && !requestedMemberId.equals(currentMember.getId())) {
            throw new ServiceException(403, "无权访问或修改其他会员档案");
        }
        if (requestedPhone != null && !requestedPhone.trim().isEmpty()
                && !requestedPhone.trim().equals(currentMember.getPhone())) {
            throw new ServiceException(403, "无权访问或修改其他手机号对应会员档案");
        }
        return currentMember.getId();
    }

    @Operation(summary = "会员获取个人完整档案与资产画像")
    @GetMapping("/profile")
    public ApiResponse<MemberProfileVO> getMyProfile(
            @RequestParam(value = "memberId", required = false) Long memberId,
            @RequestParam(value = "phone", required = false) String phone) {
        Long targetId = resolveAuthenticatedMemberId(memberId, phone);
        return ApiResponse.success(memberSelfAppService.getMyProfile(targetId));
    }

    @Operation(summary = "会员自主修改个人信息 (姓名、性别、生日、手机号)")
    @PutMapping("/profile")
    public ApiResponse<MemberProfileVO> updateMyProfile(
            @RequestParam(value = "memberId", required = false) Long memberId,
            @RequestParam(value = "phone", required = false) String phone,
            @RequestBody MemberCommands.UpdateMemberProfileCommand cmd) {
        Long targetId = resolveAuthenticatedMemberId(memberId, phone);
        return ApiResponse.success("个人信息更新成功", memberSelfAppService.updateMyProfile(targetId, cmd));
    }

    @Operation(summary = "会员自主添加/修改海马体个性偏好特征")
    @PostMapping("/preference")
    public ApiResponse<MemberPreference> saveMyPreference(
            @RequestParam(value = "memberId", required = false) Long memberId,
            @RequestParam(value = "phone", required = false) String phone,
            @RequestBody MemberCommands.SavePreferenceCommand cmd) {
        Long targetId = resolveAuthenticatedMemberId(memberId, phone);
        return ApiResponse.success("海马偏好特征更新成功", memberSelfAppService.saveMyPreference(targetId, cmd));
    }

    @Operation(summary = "会员查看个人历史消费订单")
    @GetMapping("/orders")
    public ApiResponse<List<BillingOrder>> getMyOrders(
            @RequestParam(value = "memberId", required = false) Long memberId,
            @RequestParam(value = "phone", required = false) String phone) {
        Long targetId = resolveAuthenticatedMemberId(memberId, phone);
        return ApiResponse.success(memberSelfAppService.getMyOrders(targetId));
    }
}
