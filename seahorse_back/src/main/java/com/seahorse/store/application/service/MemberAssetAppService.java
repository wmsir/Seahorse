package com.seahorse.store.application.service;

import com.seahorse.store.application.dto.member.MemberCommands.IssueTimeCardCommand;
import com.seahorse.store.application.dto.member.MemberCommands.MemberRegisterCommand;
import com.seahorse.store.application.dto.member.MemberCommands.RechargeCommand;
import com.seahorse.store.application.dto.member.MemberCommands.SavePreferenceCommand;
import com.seahorse.store.application.dto.member.MemberProfileVO;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.commission.enums.CommissionStatus;
import com.seahorse.store.domain.commission.enums.CommissionType;
import com.seahorse.store.domain.commission.model.CommissionRecord;
import com.seahorse.store.domain.common.constant.CommonConstants;
import com.seahorse.store.domain.iam.model.Employee;
import com.seahorse.store.domain.member.enums.MemberLevel;
import com.seahorse.store.domain.member.enums.TimeCardStatus;
import com.seahorse.store.domain.member.model.DualBalanceAccount;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.member.model.MemberPreference;
import com.seahorse.store.domain.member.model.TimeCardBucket;
import com.seahorse.store.infrastructure.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * 会员资产与海马体记忆应用服务
 * 符合阿里巴巴与DDD应用层规范
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MemberAssetAppService {

    private final MemberRepository memberRepository;
    private final DualBalanceAccountRepository dualBalanceAccountRepository;
    private final TimeCardBucketRepository timeCardBucketRepository;
    private final MemberPreferenceRepository memberPreferenceRepository;
    private final EmployeeRepository employeeRepository;
    private final CommissionRecordRepository commissionRecordRepository;
    private final BillingOrderRepository billingOrderRepository;
    private final PlatformConfigAppService platformConfigAppService;
    private final ChannelNotificationAppService channelNotificationAppService;
    private final com.seahorse.store.infrastructure.id.DistributedMemberNoGenerator distributedMemberNoGenerator;
    private final com.seahorse.store.infrastructure.repository.MemberRechargeRecordRepository memberRechargeRecordRepository;
    private final com.seahorse.store.infrastructure.repository.StoreRepository storeRepository;

    @Transactional(rollbackFor = Exception.class)
    public Member registerMember(MemberRegisterCommand cmd) {
        String tenantId = null;
        if (cmd.getStoreId() != null && !cmd.getStoreId().trim().isEmpty()) {
            tenantId = storeRepository.findByStoreId(cmd.getStoreId().trim())
                    .map(com.seahorse.store.domain.iam.model.Store::getTenantId)
                    .orElse(null);
        }
        if (tenantId == null || tenantId.trim().isEmpty()) {
            tenantId = TenantContext.getTenantId();
        }
        if (tenantId == null || tenantId.trim().isEmpty() || "PLATFORM".equalsIgnoreCase(tenantId)) {
            tenantId = "T001";
        }

        if (memberRepository.findByTenantIdAndPhone(tenantId, cmd.getPhone()).isPresent()) {
            throw new ServiceException("当前商户下该手机号已注册为会员: " + cmd.getPhone());
        }

        int trialDays = platformConfigAppService != null ? platformConfigAppService.getCustomerTrialDays() : 3;
        // 使用分布式高并发租户内唯一会员号发号器
        String memberNo = distributedMemberNoGenerator.nextMemberNo(tenantId);
        LocalDate trialExpire = LocalDate.now().plusDays(trialDays);

        // 计算初始会员等级：依据首充本金门槛自动定级
        BigDecimal initP = cmd.getInitialPrincipal() != null ? cmd.getInitialPrincipal() : BigDecimal.ZERO;
        BigDecimal initG = cmd.getInitialGift() != null ? cmd.getInitialGift() : BigDecimal.ZERO;

        MemberLevel initialLevel = (cmd.getLevel() != null && !cmd.getLevel().trim().isEmpty())
                ? MemberLevel.fromString(cmd.getLevel().trim())
                : MemberLevel.calculateLevelByRecharge(initP);

        Member member = Member.builder()
                .tenantId(tenantId)
                .memberNo(memberNo)
                .name(cmd.getName())
                .phone(cmd.getPhone())
                .gender(cmd.getGender() != null ? cmd.getGender() : CommonConstants.GENDER_UNKNOWN)
                .birthday(cmd.getBirthday())
                .level(initialLevel)
                .trialExpireDate(trialExpire)
                .isTrial(true)
                .totalSpent(BigDecimal.ZERO)
                .visitCount(0)
                .status(CommonConstants.STATUS_ACTIVE)
                .build();

        member = memberRepository.save(member);

        // 初始化双轨储值账户

        com.seahorse.store.domain.member.enums.DeductMode deductMode = cmd.getDeductMode() != null ?
                cmd.getDeductMode() : com.seahorse.store.domain.member.enums.DeductMode.PROPORTIONAL;

        DualBalanceAccount account = DualBalanceAccount.builder()
                .memberId(member.getId())
                .tenantId(tenantId)
                .deductMode(deductMode)
                .principalBalance(initP)
                .giftBalance(initG)
                .totalRecharged(initP)
                .totalGiftGranted(initG)
                .build();

        dualBalanceAccountRepository.save(account);

        // 如果开卡时有首充本金或赠送金，生成真实持久化的会员充值入账流水单据
        if (initP.compareTo(BigDecimal.ZERO) > 0 || initG.compareTo(BigDecimal.ZERO) > 0) {
            String recordNo = "RC" + System.currentTimeMillis() + String.format("%04d", (int)(Math.random() * 10000));
            com.seahorse.store.domain.member.model.MemberRechargeRecord rechargeRecord =
                    com.seahorse.store.domain.member.model.MemberRechargeRecord.builder()
                            .tenantId(tenantId)
                            .storeId(cmd.getStoreId() != null && !cmd.getStoreId().trim().isEmpty() ? cmd.getStoreId().trim() : "S001")
                            .orderNo(recordNo)
                            .memberId(member.getId())
                            .memberName(member.getName())
                            .memberPhone(member.getPhone())
                            .principalAmount(initP)
                            .giftAmount(initG)
                            .sellerEmployeeName("顾客扫码自助开卡")
                            .paymentMethod(cmd.getPaymentMethod() != null && !cmd.getPaymentMethod().trim().isEmpty() ? cmd.getPaymentMethod().trim() : "WECHAT")
                            .status("SUCCESS")
                            .notes("会员扫码自助开卡首充入账")
                            .createdAt(LocalDateTime.now())
                            .build();
            memberRechargeRecordRepository.save(rechargeRecord);
            log.info("【开卡首充入账成功】会员={}, 充值流水单号={}, 本金={}, 赠金={}", member.getName(), recordNo, initP, initG);
        }

        log.info("【会员注册成功】会员号={}, 姓名={}, 手机号={}", memberNo, member.getName(), member.getPhone());
        return member;
    }

    @Transactional(rollbackFor = Exception.class)
    public DualBalanceAccount rechargeDualBalance(RechargeCommand cmd) {
        Member member = memberRepository.findById(cmd.getMemberId())
                .orElseThrow(() -> new ServiceException("会员不存在"));
        TenantContext.assertTenantAccess(member.getTenantId());

        DualBalanceAccount account = dualBalanceAccountRepository.findByMemberId(member.getId())
                .orElseGet(() -> DualBalanceAccount.builder()
                        .memberId(member.getId())
                        .tenantId(member.getTenantId())
                        .principalBalance(BigDecimal.ZERO)
                        .giftBalance(BigDecimal.ZERO)
                        .totalRecharged(BigDecimal.ZERO)
                        .totalGiftGranted(BigDecimal.ZERO)
                        .build());

        BigDecimal p = cmd.getPrincipalAmount() != null ? cmd.getPrincipalAmount() : BigDecimal.ZERO;
        BigDecimal g = cmd.getGiftAmount() != null ? cmd.getGiftAmount() : BigDecimal.ZERO;

        account.recharge(p, g);
        account = dualBalanceAccountRepository.save(account);

        // 依据累计充值本金自动晋升会员等级（单向升级不降级）
        MemberLevel rechargeTier = MemberLevel.calculateLevelByRecharge(account.getTotalRecharged());
        MemberLevel currentLevel = member.getLevel() != null ? member.getLevel() : MemberLevel.REGULAR;
        if (rechargeTier.ordinal() > currentLevel.ordinal()) {
            member.setLevel(rechargeTier);
            memberRepository.save(member);
            log.info("【储值自动晋级成功】会员ID={}, 姓名={}, 原等级={}, 新等级={}, 累计充值={}",
                    member.getId(), member.getName(), currentLevel.getDescription(), rechargeTier.getDescription(), account.getTotalRecharged());
        }

        String sellerName = null;
        // 如果指定售卡人，核算售卡充值提成（按本金 5% 或员工默认提成比例）
        if (cmd.getSellerEmployeeId() != null) {
            Optional<Employee> empOpt = employeeRepository.findById(cmd.getSellerEmployeeId());
            if (empOpt.isPresent()) {
                Employee emp = empOpt.get();
                sellerName = emp.getRealName();
                if (p.compareTo(BigDecimal.ZERO) > 0) {
                    BigDecimal rate = emp.getDefaultCommissionRate() != null ? emp.getDefaultCommissionRate() : BigDecimal.valueOf(0.05);
                    BigDecimal comm = p.multiply(rate);

                    CommissionRecord commission = CommissionRecord.builder()
                            .tenantId(member.getTenantId())
                            .storeId(TenantContext.getStoreId())
                            .employeeId(emp.getId())
                            .employeeName(emp.getRealName())
                            .commissionType(CommissionType.RECHARGE)
                            .baseAmount(p)
                            .commissionRate(rate)
                            .commissionAmount(comm)
                            .notes("会员充值本金 ￥" + p + " 提成")
                            .status(CommissionStatus.RECORDED)
                            .build();
                    commissionRecordRepository.save(commission);
                }
            }
        }

        // 保存真实的会员充值流水单据到持久化数据库
        String rechargeOrderNo = "RC" + System.currentTimeMillis() + String.format("%04d", (int)(Math.random() * 10000));
        com.seahorse.store.domain.member.model.MemberRechargeRecord rechargeRecord = com.seahorse.store.domain.member.model.MemberRechargeRecord.builder()
                .tenantId(member.getTenantId())
                .storeId(TenantContext.getStoreId() != null ? TenantContext.getStoreId() : "S001")
                .orderNo(rechargeOrderNo)
                .memberId(member.getId())
                .memberName(member.getName())
                .memberPhone(member.getPhone())
                .principalAmount(p)
                .giftAmount(g)
                .sellerEmployeeId(cmd.getSellerEmployeeId())
                .sellerEmployeeName(sellerName)
                .paymentMethod("WECHAT")
                .status("SUCCESS")
                .notes("双轨储值充值入账")
                .createdAt(LocalDateTime.now())
                .build();
        memberRechargeRecordRepository.save(rechargeRecord);

        log.info("【储值充值成功】会员={}, 充值单号={}, 充值本金={}, 赠送金={}, 账户新总额={}",
                member.getName(), rechargeOrderNo, p, g, account.getTotalBalance());

        // 异步/全渠道即时推送储值到账通知
        try {
            String opName = sellerName != null ? sellerName : "前台收银员";
            channelNotificationAppService.sendRechargeNotification(member, account, p, g, opName);
        } catch (Exception ex) {
            log.error("储值充值消息通知推送异常", ex);
        }

        return account;
    }

    @Transactional(rollbackFor = Exception.class)
    public TimeCardBucket issueTimeCard(IssueTimeCardCommand cmd) {
        Member member = memberRepository.findById(cmd.getMemberId())
                .orElseThrow(() -> new ServiceException("会员不存在"));
        TenantContext.assertTenantAccess(member.getTenantId());

        TimeCardBucket bucket = TimeCardBucket.builder()
                .memberId(member.getId())
                .tenantId(member.getTenantId())
                .skuId(cmd.getSkuId())
                .skuName(cmd.getSkuName())
                .totalTimes(cmd.getTotalTimes())
                .remainingTimes(cmd.getTotalTimes())
                .expireDate(cmd.getExpireDate() != null ? cmd.getExpireDate() : LocalDate.now().plusYears(1))
                .status(TimeCardStatus.ACTIVE.name())
                .build();

        return timeCardBucketRepository.save(bucket);
    }

    @Transactional(rollbackFor = Exception.class)
    public MemberPreference savePreference(SavePreferenceCommand cmd) {
        if (cmd == null || cmd.getMemberId() == null) {
            log.warn("【保存偏好跳过】cmd 或 memberId 为空");
            return null;
        }
        Member member = memberRepository.findById(cmd.getMemberId())
                .orElseThrow(() -> new ServiceException("会员不存在"));
        if (TenantContext.isAuthenticated()) {
            TenantContext.assertTenantAccess(member.getTenantId());
        }

        MemberPreference pref = MemberPreference.builder()
                .memberId(member.getId())
                .tenantId(member.getTenantId())
                .category(cmd.getCategory())
                .tagKey(cmd.getTagKey())
                .tagValue(cmd.getTagValue())
                .notes(cmd.getNotes())
                .updatedBy(TenantContext.getUsername())
                .build();

        return memberPreferenceRepository.save(pref);
    }

    public List<MemberProfileVO.MemberLevelRuleVO> getAllLevelRules() {
        List<MemberProfileVO.MemberLevelRuleVO> list = new java.util.ArrayList<>();
        for (MemberLevel l : MemberLevel.values()) {
            String discountDisplay = l.getServiceDiscount().compareTo(BigDecimal.ONE) == 0 ? "无折扣" :
                    l.getServiceDiscount().multiply(BigDecimal.TEN).stripTrailingZeros().toPlainString() + "折";
            list.add(MemberProfileVO.MemberLevelRuleVO.builder()
                    .levelCode(l.name())
                    .levelName(l.getDescription())
                    .growthThreshold(l.getGrowthThreshold())
                    .serviceDiscount(l.getServiceDiscount())
                    .productDiscount(l.getProductDiscount())
                    .discountDisplay(discountDisplay)
                    .privileges(l.getPrivileges())
                    .build());
        }
        return list;
    }

    @Transactional(readOnly = true)
    public MemberProfileVO getMemberProfile(Long memberId) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new ServiceException("未找到该会员档案"));
        TenantContext.assertTenantAccess(member.getTenantId());

        DualBalanceAccount account = dualBalanceAccountRepository.findByMemberId(memberId)
                .orElse(null);

        List<TimeCardBucket> timeCards = timeCardBucketRepository.findByMemberId(memberId);
        List<MemberPreference> preferences = memberPreferenceRepository.findByMemberId(memberId);

        MemberLevel level = member.getLevel() != null ? member.getLevel() : MemberLevel.REGULAR;
        int points = member.getPoints() != null ? member.getPoints() : 0;
        MemberLevel nextLevel = level.getNextLevel();
        String nextLevelCode = nextLevel != null ? nextLevel.name() : null;
        String nextLevelName = nextLevel != null ? nextLevel.getDescription() : null;
        int nextThreshold = level.getNextThreshold();
        int pointsToNext = level.getPointsToNext(points);
        double ratio = level.getGrowthProgressRatio(points);

        return MemberProfileVO.builder()
                .member(member)
                .dualBalance(account)
                .timeCards(timeCards)
                .preferences(preferences)
                .isTrial(member.isTrialActive())
                .trialExpireDate(member.getTrialExpireDate())
                .trialDaysRemaining(member.getTrialDaysRemaining())
                .levelCode(level.name())
                .levelName(level.getDescription())
                .currentPoints(points)
                .nextLevelCode(nextLevelCode)
                .nextLevelName(nextLevelName)
                .growthThreshold(level.getGrowthThreshold())
                .nextGrowthThreshold(nextThreshold)
                .pointsToNextLevel(pointsToNext)
                .growthProgressRatio(ratio)
                .levelRules(getAllLevelRules())
                .build();
    }

    @Transactional(readOnly = true)
    public List<Member> searchMembers(String query) {
        return searchMembers(query, null, null);
    }

    @Transactional(readOnly = true)
    public List<Member> searchMembers(String query, String specifiedTenantId) {
        return searchMembers(query, specifiedTenantId, null);
    }

    @Transactional(readOnly = true)
    public List<Member> searchMembers(String query, String specifiedTenantId, String specifiedStoreId) {
        String tenantId = (specifiedTenantId != null && !specifiedTenantId.trim().isEmpty())
                ? specifiedTenantId.trim()
                : TenantContext.getTenantId();

        // 当租户为默认T001或空，但存在指定门店上下文时，优先校准至该门店所属真实租户
        String storeId = (specifiedStoreId != null && !specifiedStoreId.trim().isEmpty())
                ? specifiedStoreId.trim()
                : TenantContext.getStoreId();
        if (storeId != null && !storeId.trim().isEmpty()) {
            java.util.Optional<com.seahorse.store.domain.iam.model.Store> sOpt = storeRepository.findByStoreId(storeId.trim());
            if (sOpt.isPresent() && sOpt.get().getTenantId() != null) {
                tenantId = sOpt.get().getTenantId();
            }
        }
        if (tenantId == null || tenantId.trim().isEmpty()) {
            tenantId = "T001";
        }

        boolean canQueryGlobal = "PLATFORM".equalsIgnoreCase(TenantContext.getTenantId())
                || "PLATFORM_DEVELOPER".equalsIgnoreCase(TenantContext.getRole());
        List<Member> list;
        if (canQueryGlobal && ("PLATFORM".equalsIgnoreCase(tenantId) || "ALL".equalsIgnoreCase(tenantId))) {
            if (query == null || query.trim().isEmpty()) {
                list = new java.util.ArrayList<>(memberRepository.findAll());
            } else {
                list = new java.util.ArrayList<>(memberRepository.findByNameContainingOrPhoneContaining(query.trim(), query.trim()));
            }
        } else {
            String scopedTenantId = ("PLATFORM".equalsIgnoreCase(tenantId) || "ALL".equalsIgnoreCase(tenantId)) ? "T001" : tenantId;
            if (query == null || query.trim().isEmpty()) {
                list = new java.util.ArrayList<>(memberRepository.findByTenantId(scopedTenantId));
            } else {
                list = new java.util.ArrayList<>(memberRepository.findByTenantIdAndNameContainingOrTenantIdAndPhoneContaining(
                        scopedTenantId, query.trim(), scopedTenantId, query.trim()));
            }
        }

        // 检查归属当前租户门店的充值记录，自动找回并修复由于跨租户或公开扫码建档导致的会员归属偏差
        if (!"PLATFORM".equalsIgnoreCase(tenantId) && !"ALL".equalsIgnoreCase(tenantId)) {
            List<com.seahorse.store.domain.iam.model.Store> stores = storeRepository.findByTenantId(tenantId);
            java.util.Set<String> storeIds = stores.stream()
                    .map(com.seahorse.store.domain.iam.model.Store::getStoreId)
                    .filter(sid -> sid != null && !sid.trim().isEmpty())
                    .collect(java.util.stream.Collectors.toCollection(java.util.LinkedHashSet::new));
            if (!storeIds.isEmpty()) {
                List<com.seahorse.store.domain.member.model.MemberRechargeRecord> records =
                        memberRechargeRecordRepository.findByStoreIdInOrderByCreatedAtDesc(storeIds);
                java.util.Set<Long> existingIds = list.stream()
                        .map(Member::getId)
                        .filter(java.util.Objects::nonNull)
                        .collect(java.util.stream.Collectors.toSet());
                java.util.Set<Long> orphanMemberIds = new java.util.LinkedHashSet<>();
                for (com.seahorse.store.domain.member.model.MemberRechargeRecord rc : records) {
                    if (rc.getMemberId() != null && !existingIds.contains(rc.getMemberId())) {
                        orphanMemberIds.add(rc.getMemberId());
                    }
                }
                if (!orphanMemberIds.isEmpty()) {
                    java.util.Map<Long, Member> orphanMap = new java.util.HashMap<>();
                    for (Member orphan : memberRepository.findAllById(orphanMemberIds)) {
                        if (orphan != null && orphan.getId() != null) {
                            orphanMap.put(orphan.getId(), orphan);
                        }
                    }
                    for (Long orphanId : orphanMemberIds) {
                        Member orphan = orphanMap.get(orphanId);
                        if (orphan != null && existingIds.add(orphan.getId())) {
                            list.add(orphan);
                        }
                    }
                }
            }
        }

        if (!list.isEmpty()) {
            java.util.Set<Long> memberIds = list.stream()
                    .map(Member::getId)
                    .filter(java.util.Objects::nonNull)
                    .collect(java.util.stream.Collectors.toSet());
            if (!memberIds.isEmpty()) {
                java.util.Map<Long, DualBalanceAccount> accountMap = new java.util.HashMap<>();
                for (DualBalanceAccount acc : dualBalanceAccountRepository.findByMemberIdIn(memberIds)) {
                    if (acc != null && acc.getMemberId() != null) {
                        accountMap.put(acc.getMemberId(), acc);
                    }
                }
                for (Member m : list) {
                    DualBalanceAccount acc = accountMap.get(m.getId());
                    if (acc != null) {
                        m.setBalance(acc.getTotalBalance());
                    }
                }
            }
        }
        return list;
    }

    @Transactional(rollbackFor = Exception.class)
    public Member updateMemberDetail(Long memberId, com.seahorse.store.application.dto.member.MemberCommands.UpdateMemberDetailCommand cmd) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new ServiceException("未找到该会员档案"));
        TenantContext.assertTenantAccess(member.getTenantId());

        if (cmd.getName() != null) member.setName(cmd.getName());
        if (cmd.getPhone() != null) member.setPhone(cmd.getPhone());
        if (cmd.getAvatar() != null) member.setAvatar(cmd.getAvatar());
        if (cmd.getCardNo() != null) member.setCardNo(cmd.getCardNo());
        if (cmd.getCardPassword() != null) member.setCardPassword(cmd.getCardPassword());
        if (cmd.getCardPasswordEnabled() != null) member.setCardPasswordEnabled(cmd.getCardPasswordEnabled());
        if (cmd.getCardSignEnabled() != null) member.setCardSignEnabled(cmd.getCardSignEnabled());
        if (cmd.getGender() != null) member.setGender(cmd.getGender());
        if (cmd.getDiscountName() != null) member.setDiscountName(cmd.getDiscountName());
        if (cmd.getReferrerName() != null) member.setReferrerName(cmd.getReferrerName());
        if (cmd.getBirthdayType() != null) member.setBirthdayType(cmd.getBirthdayType());
        if (cmd.getBirthday() != null) member.setBirthday(cmd.getBirthday());
        if (cmd.getRewardAmount() != null) member.setRewardAmount(cmd.getRewardAmount());
        if (cmd.getPoints() != null) member.setPoints(cmd.getPoints());
        if (cmd.getDebtAmount() != null) member.setDebtAmount(cmd.getDebtAmount());
        if (cmd.getWechatBound() != null) member.setWechatBound(cmd.getWechatBound());
        if (cmd.getCardOpenCount() != null) member.setCardOpenCount(cmd.getCardOpenCount());
        if (cmd.getNotes() != null) member.setNotes(cmd.getNotes());
        if (cmd.getLevel() != null && !cmd.getLevel().trim().isEmpty()) {
            member.setLevel(MemberLevel.fromString(cmd.getLevel()));
        } else if (cmd.getDiscountName() != null && !cmd.getDiscountName().trim().isEmpty()) {
            String dn = cmd.getDiscountName().trim();
            MemberLevel inferred = MemberLevel.fromString(dn);
            if (inferred != MemberLevel.REGULAR || dn.contains("普") || dn.contains("无") || dn.equalsIgnoreCase("REGULAR")) {
                member.setLevel(inferred);
            }
        }

        return memberRepository.save(member);
    }

    @Transactional(readOnly = true)
    public List<BillingOrder> getMemberOrders(Long memberId) {
        memberRepository.findById(memberId).ifPresent(m -> TenantContext.assertTenantAccess(m.getTenantId()));
        return billingOrderRepository.findByMemberIdOrderByCreatedAtDesc(memberId);
    }

    @Transactional(rollbackFor = Exception.class)
    public Member adjustPoints(Long memberId, com.seahorse.store.application.dto.member.MemberCommands.AdjustPointsCommand cmd) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new ServiceException("未找到该会员档案"));
        TenantContext.assertTenantAccess(member.getTenantId());
        int current = member.getPoints() != null ? member.getPoints() : 0;
        int delta = cmd.getPointsDelta() != null ? cmd.getPointsDelta() : 0;
        member.setPoints(Math.max(0, current + delta));
        return memberRepository.save(member);
    }

    @Transactional(rollbackFor = Exception.class)
    public Member adjustRewards(Long memberId, com.seahorse.store.application.dto.member.MemberCommands.AdjustRewardsCommand cmd) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new ServiceException("未找到该会员档案"));
        TenantContext.assertTenantAccess(member.getTenantId());
        BigDecimal current = member.getRewardAmount() != null ? member.getRewardAmount() : BigDecimal.ZERO;
        BigDecimal delta = cmd.getRewardDelta() != null ? cmd.getRewardDelta() : BigDecimal.ZERO;
        BigDecimal updated = current.add(delta);
        if (updated.compareTo(BigDecimal.ZERO) < 0) {
            updated = BigDecimal.ZERO;
        }
        member.setRewardAmount(updated);
        return memberRepository.save(member);
    }

    @Transactional(rollbackFor = Exception.class)
    public Member setCardPassword(Long memberId, com.seahorse.store.application.dto.member.MemberCommands.SetCardPasswordCommand cmd) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> new ServiceException("未找到该会员档案"));
        TenantContext.assertTenantAccess(member.getTenantId());
        if (cmd.getPassword() != null) {
            member.setCardPassword(cmd.getPassword());
        }
        if (cmd.getEnabled() != null) {
            member.setCardPasswordEnabled(cmd.getEnabled());
        }
        return memberRepository.save(member);
    }

    @Transactional(readOnly = true)
    public List<com.seahorse.store.domain.member.model.MemberRechargeRecord> getMemberRecharges(Long memberId) {
        memberRepository.findById(memberId).ifPresent(m -> TenantContext.assertTenantAccess(m.getTenantId()));
        return memberRechargeRecordRepository.findByMemberIdOrderByCreatedAtDesc(memberId);
    }
}

