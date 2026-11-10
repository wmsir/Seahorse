package com.seahorse.store.application.service;

import com.seahorse.store.application.dto.vendor.RecordStorageFeeCommand;
import com.seahorse.store.application.dto.vendor.RenewSubscriptionCommand;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.common.constant.CommonConstants;
import com.seahorse.store.domain.iam.enums.SubscriptionBillingType;
import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.iam.model.SubscriptionBillingRecord;
import com.seahorse.store.domain.iam.model.Tenant;
import com.seahorse.store.domain.iam.model.TenantSubscription;
import com.seahorse.store.domain.member.enums.DeductMode;
import com.seahorse.store.infrastructure.repository.StoreRepository;
import com.seahorse.store.infrastructure.repository.SubscriptionBillingRecordRepository;
import com.seahorse.store.infrastructure.repository.TenantRepository;
import com.seahorse.store.infrastructure.repository.TenantSubscriptionRepository;
import com.seahorse.store.interfaces.web.vo.VendorDashboardStatsVO;
import com.seahorse.store.interfaces.web.vo.VendorSubscriptionVO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 系统开发商运营管控应用服务
 * 管理所有商户订阅套餐、存储服务费缴纳、到期预警与全盘经营统计
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class VendorOperationAppService {

    private final TenantRepository tenantRepository;
    private final TenantSubscriptionRepository subscriptionRepository;
    private final SubscriptionBillingRecordRepository billingRecordRepository;
    private final StoreRepository storeRepository;
    private final com.seahorse.store.infrastructure.repository.MemberRepository memberRepository;
    private final com.seahorse.store.infrastructure.repository.EmployeeRepository employeeRepository;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;
    private final AuditLogAppService auditLogAppService;

    /**
     * 获取商户订阅列表（支持关键字搜索与到期预警筛选）
     */
    @Transactional(rollbackFor = Exception.class)
    public List<VendorSubscriptionVO> getTenantSubscriptions(String query, String warningLevel) {
        List<Tenant> tenants = tenantRepository.findAll();
        List<VendorSubscriptionVO> result = new ArrayList<>();

        for (Tenant tenant : tenants) {
            if ("PLATFORM".equalsIgnoreCase(tenant.getTenantId())) {
                continue;
            }
            if ("DELETED".equalsIgnoreCase(tenant.getStatus())) {
                continue;
            }
            if (query != null && !query.trim().isEmpty()) {
                String q = query.trim().toLowerCase();
                boolean matches = (tenant.getTenantName() != null && tenant.getTenantName().toLowerCase().contains(q))
                        || (tenant.getContactName() != null && tenant.getContactName().toLowerCase().contains(q))
                        || (tenant.getContactPhone() != null && tenant.getContactPhone().contains(q))
                        || tenant.getTenantId().toLowerCase().contains(q);
                if (!matches) {
                    continue;
                }
            }

            TenantSubscription sub = subscriptionRepository.findByTenantId(tenant.getTenantId())
                    .orElseGet(() -> createDefaultSubscription(tenant.getTenantId()));

            List<Store> stores = storeRepository.findByTenantId(tenant.getTenantId());
            List<VendorSubscriptionVO.StoreSummaryVO> storeVos = stores.stream()
                    .map(s -> VendorSubscriptionVO.StoreSummaryVO.builder()
                            .storeId(s.getStoreId())
                            .storeName(s.getStoreName())
                            .industry(s.getIndustry() != null ? s.getIndustry().name() : "GENERAL")
                            .industryDesc(s.getIndustry() != null ? s.getIndustry().getDescription() : "通用实体")
                            .address(s.getAddress())
                            .phone(s.getPhone())
                            .build())
                    .collect(Collectors.toList());

            long daysRemaining = sub.getDaysRemaining();
            String level = "NORMAL";
            if (daysRemaining < 0) {
                level = "EXPIRED";
            } else if (daysRemaining <= 30) {
                level = "EXPIRING_SOON";
            }

            if (warningLevel != null && !warningLevel.trim().isEmpty() && !warningLevel.equalsIgnoreCase("ALL")) {
                if (!level.equalsIgnoreCase(warningLevel.trim())) {
                    continue;
                }
            }

            // 统计该商户缴纳的套餐费与存储费
            List<SubscriptionBillingRecord> billings = billingRecordRepository.findByTenantIdOrderByPayTimeDesc(tenant.getTenantId());
            BigDecimal subFee = BigDecimal.ZERO;
            BigDecimal storageFee = BigDecimal.ZERO;
            for (SubscriptionBillingRecord b : billings) {
                if (b.getBillingType() == SubscriptionBillingType.PLAN_SUBSCRIPTION) {
                    subFee = subFee.add(b.getAmount());
                } else if (b.getBillingType() == SubscriptionBillingType.STORAGE_SERVICE) {
                    storageFee = storageFee.add(b.getAmount());
                }
            }

            DeductMode deductMode = tenant.getDeductMode() != null ? tenant.getDeductMode() : DeductMode.PROPORTIONAL;

            int durationMonths = 12;
            if (sub.getStartDate() != null && sub.getExpireDate() != null) {
                long daysBetween = java.time.temporal.ChronoUnit.DAYS.between(sub.getStartDate(), sub.getExpireDate());
                durationMonths = Math.max(1, (int) Math.round(daysBetween / 30.0));
            }
            int tenantMemberCount = (int) memberRepository.countByTenantId(tenant.getTenantId());

            BigDecimal effectiveTotalPaid = subFee.add(storageFee);
            if (sub.getFeePaid() != null && sub.getFeePaid().compareTo(effectiveTotalPaid) > 0) {
                effectiveTotalPaid = sub.getFeePaid();
            }

            // 自动纠偏与自愈：如果租户已缴纳费用（例如 1980 或 2980）或者服务有效期跨年，却因历史原因被标记为 TRIAL，
            // 必须自动校正为正式专业版/旗舰版，并将开店配额提升至对应套餐标准！
            if (sub.getPlan() == SubscriptionPlan.TRIAL && (effectiveTotalPaid.compareTo(BigDecimal.ZERO) > 0 || daysRemaining > 30)) {
                SubscriptionPlan correctedPlan = effectiveTotalPaid.compareTo(BigDecimal.valueOf(2500)) >= 0 ? SubscriptionPlan.FLAGSHIP : SubscriptionPlan.PROFESSIONAL;
                sub.setPlan(correctedPlan);
                sub.setStoreLimit(Math.max(sub.getStoreLimit() != null ? sub.getStoreLimit() : 1, correctedPlan.getMaxStores()));
                sub.setStaffLimit(Math.max(sub.getStaffLimit() != null ? sub.getStaffLimit() : 3, getDefaultStaffLimit(correctedPlan)));
                sub.setStorageQuotaGb(Math.max(sub.getStorageQuotaGb() != null ? sub.getStorageQuotaGb() : 0, correctedPlan.getStorageQuotaGb()));
                sub.setStatus(CommonConstants.STATUS_ACTIVE);
                subscriptionRepository.save(sub);
            }

            boolean isActuallyTrial = (sub.getPlan() == SubscriptionPlan.TRIAL)
                    && (effectiveTotalPaid.compareTo(BigDecimal.ZERO) <= 0)
                    && (daysRemaining <= 30);

            VendorSubscriptionVO vo = VendorSubscriptionVO.builder()
                    .tenantId(tenant.getTenantId())
                    .tenantName(tenant.getTenantName())
                    .contactName(tenant.getContactName())
                    .contactPhone(tenant.getContactPhone())
                    .plan(sub.getPlan())
                    .planName(sub.getPlan().getDescription())
                    .planFeatures(sub.getPlan().getFeatures())
                    .purchasedDurationMonths(durationMonths)
                    .memberCount(tenantMemberCount)
                    .storeCount(stores.size())
                    .storeLimit(sub.getStoreLimit())
                    .stores(storeVos)
                    .storageQuotaGb(sub.getStorageQuotaGb())
                    .startDate(sub.getStartDate())
                    .expireDate(sub.getExpireDate())
                    .daysRemaining(daysRemaining)
                    .warningLevel(level)
                    .deductMode(deductMode.name())
                    .deductModeTitle(deductMode.getTitle())
                    .subscriptionFeePaid(subFee)
                    .storageFeePaid(storageFee)
                    .totalPaidAmount(effectiveTotalPaid)
                    .isTrial(isActuallyTrial)
                    .trialDays(sub.getPlan().getTrialDays())
                    .status(tenant.getStatus())
                    .build();

            result.add(vo);
        }

        return result;
    }

    /**
     * 为商户办理套餐续费或版本升级变更
     */
    @Transactional(rollbackFor = Exception.class)
    public TenantSubscription renewSubscription(RenewSubscriptionCommand cmd) {
        Tenant tenant = tenantRepository.findByTenantId(cmd.getTenantId())
                .orElseThrow(() -> new ServiceException("商户不存在: " + cmd.getTenantId()));

        TenantSubscription sub = subscriptionRepository.findByTenantId(cmd.getTenantId())
                .orElseGet(() -> createDefaultSubscription(cmd.getTenantId()));

        SubscriptionPlan targetPlan = cmd.getEffectiveTargetPlan() != null ? cmd.getEffectiveTargetPlan() : sub.getPlan();
        int months = cmd.getDurationMonths() != null && cmd.getDurationMonths() > 0 ? cmd.getDurationMonths() : 12;
        BigDecimal amount = cmd.getEffectiveAmount() != null ? cmd.getEffectiveAmount() : BigDecimal.ZERO;

        // 核心安全防护：商户续费交费或延长周期后，绝对不允许仍然停留在 TRIAL 试用状态
        if (targetPlan == null || targetPlan == SubscriptionPlan.TRIAL) {
            if (amount.compareTo(BigDecimal.valueOf(2500)) >= 0) {
                targetPlan = SubscriptionPlan.FLAGSHIP;
            } else {
                targetPlan = SubscriptionPlan.PROFESSIONAL;
            }
        }
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            amount = targetPlan.getAnnualFee();
        }

        LocalDate baseDate = (sub.getExpireDate() != null && sub.getExpireDate().isAfter(LocalDate.now()))
                ? sub.getExpireDate() : LocalDate.now();
        LocalDate newExpireDate = baseDate.plusMonths(months);

        sub.setPlan(targetPlan);

        // 计算门店上限：续费升级后门店上限必须提升至目标套餐标准（专业版至少3家，旗舰版至少10家）
        int targetStoreLimit = (cmd.getStoreLimit() != null && cmd.getStoreLimit() > 0)
                ? Math.max(cmd.getStoreLimit(), targetPlan.getMaxStores())
                : Math.max(sub.getStoreLimit() != null ? sub.getStoreLimit() : 1, targetPlan.getMaxStores());
        sub.setStoreLimit(targetStoreLimit);

        // 计算员工名额上限：根据目标套餐等级跃升，避免升级后仍受制于 3 人试用上限！
        int defaultStaffLimit = getDefaultStaffLimit(targetPlan);
        int targetStaffLimit = (cmd.getStaffLimit() != null && cmd.getStaffLimit() > 0)
                ? Math.max(cmd.getStaffLimit(), defaultStaffLimit)
                : Math.max(sub.getStaffLimit() != null ? sub.getStaffLimit() : 3, defaultStaffLimit);
        sub.setStaffLimit(targetStaffLimit);

        sub.setStorageQuotaGb(Math.max(sub.getStorageQuotaGb() != null ? sub.getStorageQuotaGb() : 0, targetPlan.getStorageQuotaGb()));
        sub.setExpireDate(newExpireDate);
        sub.setStatus(CommonConstants.STATUS_ACTIVE);
        sub.setFeePaid((sub.getFeePaid() != null ? sub.getFeePaid() : BigDecimal.ZERO).add(amount));

        // 确保租户本身也是激活状态
        tenant.setStatus(CommonConstants.STATUS_ACTIVE);
        tenantRepository.save(tenant);

        sub = subscriptionRepository.save(sub);

        // 生成交费流水记录 (编码 yyyyMMddHHmmss 年月日时分秒，方便对账辨识)
        String recordNo = "SUB" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + String.format("%03d", (int)(Math.random() * 1000));
        SubscriptionBillingRecord record = SubscriptionBillingRecord.builder()
                .recordNo(recordNo)
                .tenantId(tenant.getTenantId())
                .tenantName(tenant.getTenantName())
                .billingType(SubscriptionBillingType.PLAN_SUBSCRIPTION)
                .amount(amount)
                .durationMonths(months)
                .periodStart(baseDate)
                .periodEnd(newExpireDate)
                .payTime(LocalDateTime.now())
                .paymentMethod(cmd.getPaymentMethod() != null ? cmd.getPaymentMethod() : "OFFLINE")
                .operator(TenantContext.getUsername() != null ? TenantContext.getUsername() : "平台管理员")
                .notes(cmd.getNotes() != null ? cmd.getNotes() : ("办理套餐续费/升级: " + targetPlan.getDescription()))
                .build();
        billingRecordRepository.save(record);

        log.info("【开发商运营-商户续费成功】商户={}, 套餐={}, 续费月数={}, 金额={}, 门店上限={}, 员工上限={}, 新到期日={}",
                tenant.getTenantName(), targetPlan.getDescription(), months, amount, targetStoreLimit, targetStaffLimit, newExpireDate);

        return sub;
    }

    /**
     * 特批或调整租户开店上限、员工上限及存储配额
     */
    @Transactional(rollbackFor = Exception.class)
    public TenantSubscription adjustTenantLimits(String tenantId, Integer storeLimit, Integer staffLimit, Integer storageQuotaGb) {
        Tenant tenant = tenantRepository.findByTenantId(tenantId)
                .orElseThrow(() -> new ServiceException("商户不存在: " + tenantId));
        TenantSubscription sub = subscriptionRepository.findByTenantId(tenantId)
                .orElseGet(() -> createDefaultSubscription(tenantId));

        if (storeLimit != null && storeLimit > 0) {
            sub.setStoreLimit(storeLimit);
        }
        if (staffLimit != null && staffLimit > 0) {
            sub.setStaffLimit(staffLimit);
        }
        if (storageQuotaGb != null && storageQuotaGb > 0) {
            sub.setStorageQuotaGb(storageQuotaGb);
        }
        sub.setStatus(CommonConstants.STATUS_ACTIVE);
        tenant.setStatus(CommonConstants.STATUS_ACTIVE);
        tenantRepository.save(tenant);
        sub = subscriptionRepository.save(sub);

        log.info("【开发商运营-特批配额调整】商户={}, 门店上限={}, 员工上限={}, 存储配额={}GB",
                tenant.getTenantName(), sub.getStoreLimit(), sub.getStaffLimit(), sub.getStorageQuotaGb());
        return sub;
    }

    public int getDefaultStaffLimit(SubscriptionPlan plan) {
        if (plan == SubscriptionPlan.TRIAL) return 3;
        if (plan == SubscriptionPlan.PROFESSIONAL) return 15;
        if (plan == SubscriptionPlan.FLAGSHIP) return 50;
        return 999;
    }

    /**
     * 录入商户云存储服务费缴费
     */
    @Transactional(rollbackFor = Exception.class)
    public SubscriptionBillingRecord recordStorageFee(RecordStorageFeeCommand cmd) {
        Tenant tenant = tenantRepository.findByTenantId(cmd.getTenantId())
                .orElseThrow(() -> new ServiceException("商户不存在: " + cmd.getTenantId()));

        TenantSubscription sub = subscriptionRepository.findByTenantId(cmd.getTenantId())
                .orElseGet(() -> createDefaultSubscription(cmd.getTenantId()));

        int addGb = cmd.getStorageGb() != null && cmd.getStorageGb() > 0 ? cmd.getStorageGb() : 50;
        BigDecimal amount = cmd.getAmount() != null ? cmd.getAmount() : BigDecimal.valueOf(300.00);
        int months = cmd.getDurationMonths() != null && cmd.getDurationMonths() > 0 ? cmd.getDurationMonths() : 12;

        sub.setStorageQuotaGb(sub.getStorageQuotaGb() + addGb);
        subscriptionRepository.save(sub);

        // 生成交费流水记录 (编码 yyyyMMddHHmmss 年月日时分秒，方便对账辨识)
        String recordNo = "STG" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + String.format("%03d", (int)(Math.random() * 1000));
        SubscriptionBillingRecord record = SubscriptionBillingRecord.builder()
                .recordNo(recordNo)
                .tenantId(tenant.getTenantId())
                .tenantName(tenant.getTenantName())
                .billingType(SubscriptionBillingType.STORAGE_SERVICE)
                .amount(amount)
                .storageGbGranted(addGb)
                .durationMonths(months)
                .periodStart(LocalDate.now())
                .periodEnd(LocalDate.now().plusMonths(months))
                .payTime(LocalDateTime.now())
                .paymentMethod(cmd.getPaymentMethod() != null ? cmd.getPaymentMethod() : "OFFLINE")
                .operator(TenantContext.getUsername() != null ? TenantContext.getUsername() : "平台管理员")
                .notes(cmd.getNotes() != null ? cmd.getNotes() : ("云存储空间扩容服务费 (+" + addGb + "GB)"))
                .build();

        record = billingRecordRepository.save(record);
        log.info("【开发商运营-存储费交费入账】商户={}, 扩容GB={}, 金额={}, 累计存储配额={}GB",
                tenant.getTenantName(), addGb, amount, sub.getStorageQuotaGb());

        return record;
    }

    /**
     * 查询交费流水明细
     */
    @Transactional(readOnly = true)
    public List<SubscriptionBillingRecord> getBillingRecords(String tenantId) {
        java.util.Set<String> validTenantIds = tenantRepository.findAll().stream()
                .filter(t -> !"DELETED".equalsIgnoreCase(t.getStatus()))
                .map(Tenant::getTenantId)
                .collect(java.util.stream.Collectors.toSet());

        List<SubscriptionBillingRecord> list;
        if (tenantId != null && !tenantId.trim().isEmpty()) {
            list = billingRecordRepository.findByTenantIdOrderByPayTimeDesc(tenantId.trim());
        } else {
            list = billingRecordRepository.findAllByOrderByPayTimeDesc();
        }
        return list.stream()
                .filter(r -> validTenantIds.contains(r.getTenantId()))
                .collect(java.util.stream.Collectors.toList());
    }

    /**
     * 启用/停用商户 (禁止租户使用 / 恢复使用)
     */
    @Transactional(rollbackFor = Exception.class)
    public void toggleTenantStatus(String tenantId, String status) {
        if ("PLATFORM".equalsIgnoreCase(tenantId)) {
            throw new ServiceException("系统运维平台端不可停用");
        }
        Tenant tenant = tenantRepository.findByTenantId(tenantId)
                .orElseThrow(() -> new ServiceException("商户不存在: " + tenantId));
        tenant.setStatus(status);
        tenantRepository.save(tenant);

        TenantSubscription sub = subscriptionRepository.findByTenantId(tenantId).orElse(null);
        if (sub != null) {
            sub.setStatus(status);
            subscriptionRepository.save(sub);
        }

        // 级联启停该租户旗下所有员工账号
        List<com.seahorse.store.domain.iam.model.Employee> emps = employeeRepository.findByTenantId(tenantId);
        for (com.seahorse.store.domain.iam.model.Employee emp : emps) {
            if (!Boolean.TRUE.equals(emp.getIsDeleted())) {
                emp.setStatus(status);
            }
        }
        employeeRepository.saveAll(emps);

        auditLogAppService.recordLog(
                tenant.getTenantId(),
                tenant.getTenantName(),
                null,
                null,
                TenantContext.getUserId(),
                TenantContext.getUsername(),
                null,
                "DISABLED".equalsIgnoreCase(status) ? "禁用租户" : "恢复启用租户",
                "SECURITY",
                null,
                null,
                "SUCCESS",
                "超级管理员变更租户状态为: " + status + "，级联更新了 " + emps.size() + " 名员工账号"
        );
        log.info("【开发商运营-商户状态变更】商户={}, 新状态={}, 级联员工数={}", tenant.getTenantName(), status, emps.size());
    }

    /**
     * 超级管理员安全删除注销商户
     */
    @Transactional(rollbackFor = Exception.class)
    public void deleteTenant(String tenantId) {
        if ("PLATFORM".equalsIgnoreCase(tenantId) || "T001".equalsIgnoreCase(tenantId)) {
            throw new ServiceException("系统基础运维端与出厂示范商户受系统保护，严禁删除！");
        }
        Tenant tenant = tenantRepository.findByTenantId(tenantId).orElse(null);
        String tenantName = tenant != null ? tenant.getTenantName() : ("租户 " + tenantId);

        if (tenant != null) {
            tenant.setStatus("DELETED");
            tenantRepository.save(tenant);
        }

        TenantSubscription sub = subscriptionRepository.findByTenantId(tenantId).orElse(null);
        if (sub != null) {
            sub.setStatus("DELETED");
            subscriptionRepository.save(sub);
        }

        // 级联软删除门店
        List<Store> stores = storeRepository.findByTenantId(tenantId);
        for (Store s : stores) {
            s.setStatus("DELETED");
        }
        storeRepository.saveAll(stores);

        // 级联软删除员工账号
        List<com.seahorse.store.domain.iam.model.Employee> emps = employeeRepository.findByTenantId(tenantId);
        for (com.seahorse.store.domain.iam.model.Employee emp : emps) {
            emp.setIsDeleted(true);
            emp.setStatus("DELETED");
        }
        employeeRepository.saveAll(emps);

        // 级联清理可能存在的历史交费流水记录
        List<SubscriptionBillingRecord> billings = billingRecordRepository.findByTenantIdOrderByPayTimeDesc(tenantId);
        if (billings != null && !billings.isEmpty()) {
            billingRecordRepository.deleteAll(billings);
        }

        auditLogAppService.recordLog(
                tenantId,
                tenantName,
                null,
                null,
                TenantContext.getUserId(),
                TenantContext.getUsername(),
                null,
                "DELETE_TENANT",
                "SECURITY_POLICY",
                null,
                null,
                "SUCCESS",
                "超级管理员彻底注销删除租户: " + tenantName + " (" + tenantId + ")"
        );
        log.info("【开发商运营-商户删除注销】商户={}, 租户ID={}, 级联门店={}, 级联员工={}", tenantName, tenantId, stores.size(), emps.size());
    }

    /**
     * 查询指定租户旗下的全量员工账号清单 (供超管查看并重置密码)
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getTenantUsers(String tenantId) {
        List<com.seahorse.store.domain.iam.model.Employee> emps = employeeRepository.findByTenantId(tenantId);
        List<Map<String, Object>> list = new ArrayList<>();
        for (com.seahorse.store.domain.iam.model.Employee e : emps) {
            if (Boolean.TRUE.equals(e.getIsDeleted()) || "DELETED".equalsIgnoreCase(e.getStatus())) {
                continue;
            }
            Map<String, Object> m = new HashMap<>();
            m.put("id", e.getId());
            m.put("username", e.getUsername());
            m.put("realName", e.getRealName());
            m.put("nickname", e.getNickname());
            m.put("phone", e.getPhone());
            m.put("role", e.getRole() != null ? e.getRole().name() : "");
            m.put("roleDesc", e.getRole() != null ? e.getRole().getDescription() : "");
            m.put("postName", e.getPostName());
            m.put("department", e.getDepartment());
            m.put("storeId", e.getStoreId());
            m.put("status", e.getStatus());
            list.add(m);
        }
        return list;
    }

    /**
     * 超级管理员重置/修改任意用户密码
     */
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> resetUserPassword(Long userId, String username, String newPassword, String tenantId) {
        com.seahorse.store.domain.iam.model.Employee emp = null;
        if (userId != null) {
            emp = employeeRepository.findById(userId).orElse(null);
        }
        if (emp == null && username != null && !username.trim().isEmpty()) {
            emp = employeeRepository.findByUsername(username.trim()).orElse(null);
        }
        if (emp == null) {
            throw new ServiceException("未找到对应的用户账号，请核对用户ID或用户名");
        }

        String effectivePassword = (newPassword != null && !newPassword.trim().isEmpty()) ? newPassword.trim() : "123456";
        if (effectivePassword.length() < 6) {
            throw new ServiceException("新密码长度不能少于6位字符");
        }

        emp.setPassword(passwordEncoder.encode(effectivePassword));
        employeeRepository.save(emp);

        auditLogAppService.recordLog(
                emp.getTenantId(),
                null,
                emp.getStoreId(),
                null,
                TenantContext.getUserId(),
                TenantContext.getUsername(),
                null,
                "超级管理员重置用户密码",
                "SECURITY",
                null,
                null,
                "SUCCESS",
                "超管为用户【" + emp.getUsername() + "】(" + emp.getRealName() + ") 重置了密码"
        );
        log.info("【开发商运营-重置用户密码成功】用户={}, 真实姓名={}, 租户={}", emp.getUsername(), emp.getRealName(), emp.getTenantId());

        Map<String, Object> res = new HashMap<>();
        res.put("userId", emp.getId());
        res.put("username", emp.getUsername());
        res.put("realName", emp.getRealName());
        res.put("newPassword", effectivePassword);
        res.put("tenantId", emp.getTenantId());
        return res;
    }

    /**
     * 统计开发商综合大盘
     */
    @Transactional(readOnly = true)
    public VendorDashboardStatsVO getVendorDashboardStats() {
        List<Tenant> tenants = tenantRepository.findAll();
        List<TenantSubscription> subs = subscriptionRepository.findAll();
        List<SubscriptionBillingRecord> billings = billingRecordRepository.findAll();
        List<Store> stores = storeRepository.findAll();

        long activeCount = 0;
        long expiringSoon = 0;
        long expiredCount = 0;
        long trialCount = 0;

        Map<String, Long> planDist = new HashMap<>();
        for (SubscriptionPlan plan : SubscriptionPlan.values()) {
            planDist.put(plan.name(), 0L);
        }

        for (TenantSubscription sub : subs) {
            long days = sub.getDaysRemaining();
            boolean isTrial = (sub.getPlan() == SubscriptionPlan.TRIAL);
            if (isTrial && days >= 0) {
                trialCount++;
            }

            if (days < 0) {
                expiredCount++;
            } else if (days <= 30) {
                expiringSoon++;
                activeCount++;
            } else {
                activeCount++;
            }
            String pName = sub.getPlan() != null ? sub.getPlan().name() : SubscriptionPlan.TRIAL.name();
            planDist.put(pName, planDist.getOrDefault(pName, 0L) + 1);
        }

        BigDecimal subRev = BigDecimal.ZERO;
        BigDecimal stgRev = BigDecimal.ZERO;

        for (SubscriptionBillingRecord b : billings) {
            if (b.getBillingType() == SubscriptionBillingType.PLAN_SUBSCRIPTION) {
                subRev = subRev.add(b.getAmount());
            } else if (b.getBillingType() == SubscriptionBillingType.STORAGE_SERVICE) {
                stgRev = stgRev.add(b.getAmount());
            }
        }

        Map<String, Long> industryDist = new HashMap<>();
        for (Store s : stores) {
            String ind = s.getIndustry() != null ? s.getIndustry().name() : "GENERAL";
            industryDist.put(ind, industryDist.getOrDefault(ind, 0L) + 1);
        }

        long totalMembersCount = memberRepository.count();

        return VendorDashboardStatsVO.builder()
                .totalTenants((long) tenants.size())
                .totalMembers(totalMembersCount)
                .totalStores((long) stores.size())
                .activeTenants(activeCount)
                .trialTenantsCount(trialCount)
                .expiringSoonCount(expiringSoon)
                .expiredCount(expiredCount)
                .averageServiceDurationMonths(12.0)
                .totalSubscriptionRevenue(subRev)
                .totalStorageRevenue(stgRev)
                .totalPlatformRevenue(subRev.add(stgRev))
                .planDistribution(planDist)
                .industryStoreDistribution(industryDist)
                .build();
    }

    public VendorDashboardStatsVO getDashboardStats() {
        return getVendorDashboardStats();
    }

    private TenantSubscription createDefaultSubscription(String tenantId) {
        TenantSubscription sub = TenantSubscription.builder()
                .tenantId(tenantId)
                .plan(SubscriptionPlan.TRIAL)
                .storeLimit(1)
                .staffLimit(3)
                .storageQuotaGb(5)
                .startDate(LocalDate.now())
                .expireDate(LocalDate.now().plusDays(3))
                .feePaid(BigDecimal.ZERO)
                .status(CommonConstants.STATUS_ACTIVE)
                .autoRenew(true)
                .notes("新商户默认开通3天试用体验")
                .build();
        return subscriptionRepository.save(sub);
    }
}
