package com.seahorse.store.application.service;

import com.seahorse.store.application.dto.vendor.CreateStoreCommand;
import com.seahorse.store.application.dto.vendor.MerchantRegisterCommand;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.common.constant.CommonConstants;
import com.seahorse.store.domain.iam.enums.EmployeeRole;
import com.seahorse.store.domain.iam.enums.IndustryType;
import com.seahorse.store.domain.iam.enums.SubscriptionBillingType;
import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import com.seahorse.store.domain.iam.model.Employee;
import com.seahorse.store.domain.iam.model.IndustryCategoryConfig;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.iam.model.SubscriptionBillingRecord;
import com.seahorse.store.domain.iam.model.Tenant;
import com.seahorse.store.domain.iam.model.TenantSubscription;
import com.seahorse.store.domain.member.enums.DeductMode;
import com.seahorse.store.infrastructure.repository.EmployeeRepository;
import com.seahorse.store.infrastructure.repository.IndustryCategoryRepository;
import com.seahorse.store.infrastructure.repository.StoreRepository;
import com.seahorse.store.infrastructure.repository.SubscriptionBillingRecordRepository;
import com.seahorse.store.infrastructure.repository.TenantRepository;
import com.seahorse.store.infrastructure.repository.TenantSubscriptionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * 商户入驻注册与多店拓展应用服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MerchantRegisterAppService {

    private final TenantRepository tenantRepository;
    private final StoreRepository storeRepository;
    private final EmployeeRepository employeeRepository;
    private final TenantSubscriptionRepository subscriptionRepository;
    private final SubscriptionBillingRecordRepository billingRecordRepository;
    private final PlatformConfigAppService platformConfigAppService;
    private final IndustryCategoryRepository industryCategoryRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * 商户注册：自主选择 SaaS 套餐、首店细分行业类型
     */
    @Transactional(rollbackFor = Exception.class)
    public Tenant registerMerchant(MerchantRegisterCommand cmd) {
        if (cmd.getContactPhone() == null || cmd.getContactPhone().trim().isEmpty()) {
            throw new ServiceException("联系手机号为必填项");
        }
        if (employeeRepository.findByUsername(cmd.getUsername()).isPresent()) {
            throw new ServiceException("用户名已存在: " + cmd.getUsername());
        }

        SubscriptionPlan plan = cmd.getPlan() != null ? cmd.getPlan() : SubscriptionPlan.TRIAL;
        com.seahorse.store.domain.iam.model.SubscriptionPlanConfig planConfig = platformConfigAppService.getPlanConfig(plan);
        DeductMode deductMode = cmd.getDeductMode() != null ? cmd.getDeductMode() : DeductMode.PROPORTIONAL;
        IndustryType industry = cmd.getInitialIndustry() != null ? cmd.getInitialIndustry() : IndustryType.BEAUTY;

        Integer catId = cmd.getInitialStoreCategoryId();
        String catName = cmd.getInitialStoreCategoryName();
        String catGroup = cmd.getInitialStoreCategoryGroup();
        if (catId != null) {
            com.seahorse.store.domain.iam.model.IndustryCategoryConfig cfg = industryCategoryRepository.findById(catId).orElse(null);
            if (cfg != null) {
                if (cfg.getDefaultIndustryType() != null) {
                    try {
                        industry = IndustryType.valueOf(cfg.getDefaultIndustryType());
                    } catch (Exception ignored) {}
                }
                if (catName == null) catName = cfg.getName();
                if (catGroup == null) catGroup = cfg.getGroupName();
            }
        }

        // 1. 生成全局唯一 Tenant ID 与 Store ID
        String tenantId = "T" + (int)((Math.random() * 9 + 1) * 10000);
        String storeId = "S" + (int)((Math.random() * 9 + 1) * 10000);

        Tenant tenant = Tenant.builder()
                .tenantId(tenantId)
                .tenantName(cmd.getTenantName() != null ? cmd.getTenantName() : (cmd.getUsername() + "的品牌"))
                .contactName(cmd.getContactName() != null ? cmd.getContactName() : cmd.getUsername())
                .contactPhone(cmd.getContactPhone())
                .deductMode(deductMode)
                .status(CommonConstants.STATUS_ACTIVE)
                .build();
        tenant = tenantRepository.save(tenant);

        // 2. 自动创建商户首家旗舰门店（若传入了首店名称或行业类型，直接完成首店建档与绑定）
        String initialStoreName = (cmd.getInitialStoreName() != null && !cmd.getInitialStoreName().trim().isEmpty())
                ? cmd.getInitialStoreName().trim()
                : (tenant.getTenantName() + "（旗舰总店）");
        Store initialStore = Store.builder()
                .tenantId(tenantId)
                .storeId(storeId)
                .storeName(initialStoreName)
                .industry(industry)
                .industryCategoryId(catId)
                .industryCategoryName(catName != null ? catName : industry.getDescription())
                .industryCategoryGroup(catGroup != null ? catGroup : "服务类")
                .address(cmd.getStoreAddress() != null && !cmd.getStoreAddress().trim().isEmpty() ? cmd.getStoreAddress().trim() : "智慧商业中心旗舰店")
                .phone(cmd.getContactPhone())
                .businessHours("09:00 - 22:00")
                .feeName(industry.getDefaultFeeName())
                .defaultFeeAmount(BigDecimal.valueOf(10.00))
                .feeEnabled(true)
                .status(CommonConstants.STATUS_ACTIVE)
                .build();
        storeRepository.save(initialStore);

        // 3. 创建商户主管理员账号 (拥有商户全局管理权限，默认绑定首家门店)
        Employee owner = Employee.builder()
                .tenantId(tenantId)
                .storeId(storeId)
                .username(cmd.getUsername())
                .password(passwordEncoder.encode(cmd.getPassword()))
                .realName(cmd.getContactName() != null ? cmd.getContactName() : "主理人")
                .phone(cmd.getContactPhone())
                .role(EmployeeRole.SUPER_ADMIN)
                .defaultCommissionRate(BigDecimal.ZERO)
                .status(CommonConstants.STATUS_ACTIVE)
                .build();
        employeeRepository.save(owner);

        // 4. 创建商户套餐订阅合约 (根据系统配置动态获取试用期天数与价格)
        boolean isTrial = (plan == SubscriptionPlan.TRIAL);
        int trialDays = platformConfigAppService.getTrialDays();
        LocalDate startDate = LocalDate.now();
        LocalDate expireDate = isTrial ? startDate.plusDays(trialDays) : startDate.plusYears(1);
        int durationMonths = isTrial ? 0 : 12;
        BigDecimal fee = isTrial ? BigDecimal.ZERO : planConfig.getAnnualPrice();
        int storeLimit = planConfig.getStoreLimit();
        int staffLimit = planConfig.getStaffLimit() != null ? planConfig.getStaffLimit() : 3;
        int storageQuotaGb = planConfig.getStorageQuotaGb();

        TenantSubscription sub = TenantSubscription.builder()
                .tenantId(tenantId)
                .plan(plan)
                .storeLimit(storeLimit)
                .staffLimit(staffLimit)
                .storageQuotaGb(storageQuotaGb)
                .startDate(startDate)
                .expireDate(expireDate)
                .feePaid(fee)
                .status(CommonConstants.STATUS_ACTIVE)
                .autoRenew(true)
                .notes(isTrial ? ("新商户注册：默认开通" + trialDays + "天免费试用期 (开店上限" + storeLimit + "家, 员工上限" + staffLimit + "人)") : ("新商户注册选购套餐: " + planConfig.getPlanName()))
                .build();
        subscriptionRepository.save(sub);

        // 5. 记录交费/试用开通流水 (编码 yyyyMMddHHmmss 年月日时分秒)
        String recordNo = "SUB" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
                + String.format("%03d", (int)(Math.random() * 1000));
        SubscriptionBillingRecord billing = SubscriptionBillingRecord.builder()
                .recordNo(recordNo)
                .tenantId(tenantId)
                .tenantName(tenant.getTenantName())
                .billingType(SubscriptionBillingType.PLAN_SUBSCRIPTION)
                .amount(fee)
                .durationMonths(durationMonths)
                .periodStart(startDate)
                .periodEnd(expireDate)
                .payTime(LocalDateTime.now())
                .paymentMethod(isTrial ? "SYSTEM_TRIAL" : "OFFLINE")
                .operator(isTrial ? "系统默认赠送试用" : "商户自主注册")
                .notes(isTrial ? ("新商户注册默认赠送" + trialDays + "天全功能体验期 (开店" + storeLimit + "家/员工" + staffLimit + "名)") : ("注册开通套餐: " + planConfig.getPlanName()))
                .build();
        billingRecordRepository.save(billing);

        log.info("【新商户入驻成功】TenantId={}, 商户={}, 选购套餐={}, 储值扣减策略={}, 首店行业={}",
                tenantId, tenant.getTenantName(), plan.getDescription(), deductMode.getTitle(), industry.getDescription());

        return tenant;
    }

    /**
     * 商户在自身配额内开设新门店（多店多业态模态支持）
     */
    @Transactional(rollbackFor = Exception.class)
    public Store createStore(String tenantId, CreateStoreCommand cmd) {
        Tenant tenant = tenantRepository.findByTenantId(tenantId)
                .orElseThrow(() -> new ServiceException("商户不存在: " + tenantId));

        TenantSubscription sub = subscriptionRepository.findByTenantId(tenantId)
                .orElseThrow(() -> new ServiceException("未找到该商户订阅合约"));

        List<Store> existingStores = storeRepository.findByTenantId(tenantId);
        if (existingStores.size() >= sub.getStoreLimit()) {
            throw new ServiceException("已达到当前套餐门店数量上限 (" + sub.getStoreLimit() + "家)。请联系系统开发商升级为更高套餐！");
        }

        String storeId = "S" + (int)((Math.random() * 9 + 1) * 10000);
        IndustryType industry = cmd.getIndustry();
        String catName = cmd.getIndustryCategoryName();
        String catGroup = cmd.getIndustryCategoryGroup();

        if (cmd.getIndustryCategoryId() != null) {
            IndustryCategoryConfig cfg = industryCategoryRepository.findById(cmd.getIndustryCategoryId()).orElse(null);
            if (cfg != null) {
                if (industry == null && cfg.getDefaultIndustryType() != null) {
                    try {
                        industry = IndustryType.valueOf(cfg.getDefaultIndustryType());
                    } catch (Exception ignored) {}
                }
                if (catName == null) catName = cfg.getName();
                if (catGroup == null) catGroup = cfg.getGroupName();
            }
        }
        if (industry == null) {
            industry = IndustryType.BEAUTY;
        }

        Store store = Store.builder()
                .tenantId(tenantId)
                .storeId(storeId)
                .storeName(cmd.getStoreName())
                .industry(industry)
                .industryCategoryId(cmd.getIndustryCategoryId())
                .industryCategoryName(catName)
                .industryCategoryGroup(catGroup)
                .address(cmd.getAddress())
                .phone(cmd.getPhone())
                .businessHours(cmd.getBusinessHours() != null ? cmd.getBusinessHours() : "09:00 - 22:00")
                .feeName(cmd.getFeeName() != null ? cmd.getFeeName() : industry.getDefaultFeeName())
                .defaultFeeAmount(cmd.getDefaultFeeAmount() != null ? cmd.getDefaultFeeAmount() : BigDecimal.valueOf(10.00))
                .feeEnabled(cmd.getFeeEnabled() != null ? cmd.getFeeEnabled() : true)
                .status(CommonConstants.STATUS_ACTIVE)
                .build();

        store = storeRepository.save(store);

        // 若当前登录员工尚无绑定门店或为默认S001，自动绑定为该商户的首家门店
        String currentUsername = TenantContext.getUsername();
        if (currentUsername != null && !"admin".equalsIgnoreCase(currentUsername)) {
            employeeRepository.findByUsername(currentUsername).ifPresent(emp -> {
                if (emp.getStoreId() == null || emp.getStoreId().trim().isEmpty() || "S001".equalsIgnoreCase(emp.getStoreId())) {
                    emp.setStoreId(storeId);
                    employeeRepository.save(emp);
                }
            });
        }

        log.info("【商户新增门店成功】商户={}, 门店ID={}, 门店名={}, 行业={}, 细分={}",
                tenant.getTenantName(), storeId, store.getStoreName(), industry.getDescription(), catName);

        return store;
    }
}
