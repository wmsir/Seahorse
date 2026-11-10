package com.seahorse.store.application.service;

import com.seahorse.store.application.dto.member.MemberCommands;
import com.seahorse.store.application.dto.member.MemberProfileVO;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.member.model.MemberPreference;
import com.seahorse.store.infrastructure.repository.BillingOrderRepository;
import com.seahorse.store.infrastructure.repository.MemberPreferenceRepository;
import com.seahorse.store.infrastructure.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 顾客会员自主中心应用服务
 * 提供会员查看与修改个人资料、维护个人海马体偏好记忆与查看卡包账单功能
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MemberSelfAppService {

    private final MemberRepository memberRepository;
    private final MemberPreferenceRepository memberPreferenceRepository;
    private final BillingOrderRepository billingOrderRepository;
    private final MemberAssetAppService memberAssetAppService;

    /**
     * 会员查看自己的完整资料画像与资产
     */
    @Transactional(readOnly = true)
    public MemberProfileVO getMyProfile(Long memberId) {
        return memberAssetAppService.getMemberProfile(memberId);
    }

    /**
     * 会员修改自己的个人信息（姓名、性别、生日、手机号）
     */
    @Transactional(rollbackFor = Exception.class)
    public MemberProfileVO updateMyProfile(Long memberId, MemberCommands.UpdateMemberProfileCommand cmd) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new ServiceException("未找到该会员档案"));

        if (cmd.getName() != null && !cmd.getName().trim().isEmpty()) {
            member.setName(cmd.getName().trim());
        }
        if (cmd.getGender() != null && !cmd.getGender().trim().isEmpty()) {
            member.setGender(cmd.getGender().trim());
        }
        if (cmd.getBirthday() != null) {
            member.setBirthday(cmd.getBirthday());
        }
        if (cmd.getPhone() != null && !cmd.getPhone().trim().isEmpty()) {
            String newPhone = cmd.getPhone().trim();
            if (!newPhone.equals(member.getPhone())) {
                // 检查手机号冲突
                memberRepository.findByPhone(newPhone).ifPresent(existing -> {
                    if (!existing.getId().equals(member.getId())) {
                        throw new ServiceException("该手机号已被其他会员绑定，无法修改");
                    }
                });
                member.setPhone(newPhone);
            }
        }

        memberRepository.save(member);
        log.info("【会员自主中心】会员 [{}] (ID={}) 成功修改个人信息", member.getName(), member.getId());

        return memberAssetAppService.getMemberProfile(member.getId());
    }

    /**
     * 会员自主录入或更新自己的海马体记忆偏好标签
     */
    @Transactional(rollbackFor = Exception.class)
    public MemberPreference saveMyPreference(Long memberId, MemberCommands.SavePreferenceCommand cmd) {
        cmd.setMemberId(memberId);
        MemberPreference pref = memberAssetAppService.savePreference(cmd);
        log.info("【会员自主中心】会员 (ID={}) 自主维护海马记忆偏好: [{}] -> {}",
                memberId, cmd.getTagKey(), cmd.getTagValue());
        return pref;
    }

    /**
     * 会员查看自己的消费订单明细列表
     */
    @Transactional(readOnly = true)
    public List<BillingOrder> getMyOrders(Long memberId) {
        return billingOrderRepository.findByMemberIdOrderByCreatedAtDesc(memberId);
    }
}
