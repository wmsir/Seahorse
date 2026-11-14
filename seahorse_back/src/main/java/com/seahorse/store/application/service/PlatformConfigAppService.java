package com.seahorse.store.application.service;

import com.seahorse.store.application.dto.vendor.UpdatePlanConfigCommand;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.domain.common.constant.CommonConstants;
import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import com.seahorse.store.domain.iam.model.SubscriptionPlanConfig;
import com.seahorse.store.infrastructure.repository.SubscriptionPlanConfigRepository;
import com.seahorse.store.interfaces.web.vo.SubscriptionPlanConfigVO;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 平台运营与会员套餐配置应用服务
 * 管理试用期时长（如3天、7天）与会员定价策略
 */
@Service
public class PlatformConfigAppService {

    private static final Logger log = LoggerFactory.getLogger(PlatformConfigAppService.class);

    private final SubscriptionPlanConfigRepository planConfigRepository;

    public PlatformConfigAppService(SubscriptionPlanConfigRepository planConfigRepository) {
        this.planConfigRepository = planConfigRepository;
    }

    @PostConstruct
    @Transactional(rollbackFor = Exception.class)
    public void initDefaultPlanConfigsIfNeeded() {
        if (planConfigRepository.count() > 0) {
            return;
        }
        log.info("【平台初始化】自动植入默认 SaaS 会员套餐与定价试用期配置...");
        List<SubscriptionPlanConfig> configs = new ArrayList<>();

        configs.add(SubscriptionPlanConfig.builder()
                .planCode(SubscriptionPlan.TRIAL)
                .planName("基础体验版")
                .annualPrice(BigDecimal.valueOf(0.00))
                .trialDays(3) // 默认3天试用期，开发商可在页面随时修改为7天、15天等
                .storeLimit(1)
                .staffLimit(3) // 试用账号默认最多开通1家店，3名员工
                .storageQuotaGb(5)
                .features("支持1家单店，允许录入3名员工，5GB基础云存储，新注册商户默认赠送免费试用体验")
                .isDefault(true)
                .sortOrder(1)
                .status(CommonConstants.STATUS_ACTIVE)
                .build());

        configs.add(SubscriptionPlanConfig.builder()
                .planCode(SubscriptionPlan.PROFESSIONAL)
                .planName("专业成长版")
                .annualPrice(BigDecimal.valueOf(2980.00)) // 页面可随时配置价格
                .trialDays(0)
                .storeLimit(3)
                .staffLimit(15)
                .storageQuotaGb(50)
                .features("支持最多3家门店，允许录入15名员工，50GB云存储，支持双轨储值策略自选与全渠道收银")
                .isDefault(false)
                .sortOrder(2)
                .status(CommonConstants.STATUS_ACTIVE)
                .build());

        configs.add(SubscriptionPlanConfig.builder()
                .planCode(SubscriptionPlan.FLAGSHIP)
                .planName("旗舰连锁版")
                .annualPrice(BigDecimal.valueOf(6800.00))
                .trialDays(0)
                .storeLimit(10)
                .staffLimit(50)
                .storageQuotaGb(200)
                .features("支持最多10家门店，允许录入50名员工，多业态跨行业混部，200GB大容量云存储与私域深度营销")
                .isDefault(false)
                .sortOrder(3)
                .status(CommonConstants.STATUS_ACTIVE)
                .build());

        configs.add(SubscriptionPlanConfig.builder()
                .planCode(SubscriptionPlan.ENTERPRISE)
                .planName("集团企业版")
                .annualPrice(BigDecimal.valueOf(19800.00))
                .trialDays(0)
                .storeLimit(999)
                .staffLimit(999)
                .storageQuotaGb(1024)
                .features("门店数不限，员工名额不限，1TB超大云存储空间，专属定制与API开放接入")
                .isDefault(false)
                .sortOrder(4)
                .status(CommonConstants.STATUS_ACTIVE)
                .build());

        planConfigRepository.saveAll(configs);
        log.info("【平台初始化】SaaS 会员套餐定价与试用期初始化完成，共 {} 项配置", configs.size());
    }

    /**
     * 获取所有套餐版本与定价配置（开发商运营端）
     */
    @Transactional(readOnly = true)
    public List<SubscriptionPlanConfigVO> getAllPlanConfigs() {
        return planConfigRepository.findAllByOrderBySortOrderAsc().stream()
                .map(this::toVO)
                .collect(Collectors.toList());
    }

    /**
     * 获取对前台注册公开展示的有效套餐清单
     */
    @Transactional(readOnly = true)
    public List<SubscriptionPlanConfigVO> getActivePlanConfigs() {
        return planConfigRepository.findByStatusOrderBySortOrderAsc(CommonConstants.STATUS_ACTIVE).stream()
                .map(this::toVO)
                .collect(Collectors.toList());
    }

    /**
     * 获取当前生效的默认试用期天数（如默认3天，若开发商配置为7天则返回7）
     */
    @Transactional(readOnly = true)
    public int getTrialDays() {
        Optional<SubscriptionPlanConfig> trialOpt = planConfigRepository.findByPlanCode(SubscriptionPlan.TRIAL);
        if (trialOpt.isPresent() && trialOpt.get().getTrialDays() != null && trialOpt.get().getTrialDays() > 0) {
            return trialOpt.get().getTrialDays();
        }
        return 3;
    }

    /**
     * 获取门店顾客会员默认权益试用天数
     */
    @Transactional(readOnly = true)
    public int getCustomerTrialDays() {
        return getTrialDays();
    }

    @Transactional(readOnly = true)
    public int getDefaultTrialDays() {
        return getTrialDays();
    }

    @Transactional(readOnly = true)
    public BigDecimal getPlanAnnualPrice(SubscriptionPlan plan) {
        return getPlanConfig(plan).getAnnualPrice();
    }

    /**
     * 修改套餐定价与配置（价格、试用天数、门店配额、云存储配额等）
     */
    @Transactional(rollbackFor = Exception.class)
    public SubscriptionPlanConfigVO updatePlanConfig(Long id, UpdatePlanConfigCommand cmd) {
        SubscriptionPlanConfig config = planConfigRepository.findById(id)
                .orElseThrow(() -> new ServiceException("未找到该套餐配置: ID=" + id));

        if (cmd.getPlanName() != null && !cmd.getPlanName().trim().isEmpty()) {
            config.setPlanName(cmd.getPlanName().trim());
        }
        if (cmd.getAnnualPrice() != null) {
            config.setAnnualPrice(cmd.getAnnualPrice());
        }
        if (cmd.getTrialDays() != null && cmd.getTrialDays() >= 0) {
            config.setTrialDays(cmd.getTrialDays());
        }
        if (cmd.getStoreLimit() != null && cmd.getStoreLimit() > 0) {
            config.setStoreLimit(cmd.getStoreLimit());
        }
        if (cmd.getStaffLimit() != null && cmd.getStaffLimit() > 0) {
            config.setStaffLimit(cmd.getStaffLimit());
        }
        if (cmd.getStorageQuotaGb() != null && cmd.getStorageQuotaGb() > 0) {
            config.setStorageQuotaGb(cmd.getStorageQuotaGb());
        }
        if (cmd.getFeatures() != null) {
            config.setFeatures(cmd.getFeatures());
        }
        if (cmd.getStatus() != null) {
            config.setStatus(cmd.getStatus());
        }
        if (cmd.getIsDefault() != null) {
            if (Boolean.TRUE.equals(cmd.getIsDefault())) {
                List<SubscriptionPlanConfig> allConfigs = planConfigRepository.findAll();
                allConfigs.forEach(c -> c.setIsDefault(false));
                planConfigRepository.saveAll(allConfigs);
            }
            config.setIsDefault(cmd.getIsDefault());
        }

        config = planConfigRepository.save(config);
        log.info("【开发商更新套餐配置成功】套餐={}, 价格=￥{}, 试用天数={}天, 门店上限={}, 员工上限={}",
                config.getPlanCode(), config.getAnnualPrice(), config.getTrialDays(), config.getStoreLimit(), config.getStaffLimit());

        return toVO(config);
    }

    /**
     * 快捷更新试用期天数（如从 3天 修改为 7天、15天等）
     */
    @Transactional(rollbackFor = Exception.class)
    public int updateTrialDays(int days) {
        if (days <= 0 || days > 365) {
            throw new ServiceException("试用期天数必须在 1 ~ 365 天之间");
        }
        SubscriptionPlanConfig trialConfig = planConfigRepository.findByPlanCode(SubscriptionPlan.TRIAL)
                .orElseGet(() -> {
                    initDefaultPlanConfigsIfNeeded();
                    return planConfigRepository.findByPlanCode(SubscriptionPlan.TRIAL).orElseThrow();
                });

        trialConfig.setTrialDays(days);
        planConfigRepository.save(trialConfig);
        log.info("【开发商全局调整试用期成功】新商户注册默认试用期更新为: {} 天", days);
        return days;
    }

    /**
     * 获取指定套餐的当前配置（含实时价格与配额）
     */
    @Transactional(readOnly = true)
    public SubscriptionPlanConfig getPlanConfig(SubscriptionPlan plan) {
        SubscriptionPlanConfig config = planConfigRepository.findByPlanCode(plan)
                .orElseGet(() -> SubscriptionPlanConfig.builder()
                        .planCode(plan)
                        .planName(plan.getDescription())
                        .annualPrice(plan.getAnnualFee())
                        .trialDays(plan.getTrialDays())
                        .storeLimit(plan.getMaxStores())
                        .staffLimit(getDefaultStaffLimit(plan))
                        .storageQuotaGb(plan.getStorageQuotaGb())
                        .features(plan.getFeatures())
                        .isDefault(plan == SubscriptionPlan.TRIAL)
                        .status(CommonConstants.STATUS_ACTIVE)
                        .build());
        if (config.getStaffLimit() == null || config.getStaffLimit() <= 0) {
            config.setStaffLimit(getDefaultStaffLimit(config.getPlanCode()));
        }
        return config;
    }

    private int getDefaultStaffLimit(SubscriptionPlan plan) {
        if (plan == SubscriptionPlan.TRIAL) return 3;
        if (plan == SubscriptionPlan.PROFESSIONAL) return 15;
        if (plan == SubscriptionPlan.FLAGSHIP) return 50;
        return 999;
    }

    private SubscriptionPlanConfigVO toVO(SubscriptionPlanConfig c) {
        int staffLimit = (c.getStaffLimit() != null && c.getStaffLimit() > 0)
                ? c.getStaffLimit()
                : getDefaultStaffLimit(c.getPlanCode());
        return SubscriptionPlanConfigVO.builder()
                .id(c.getId())
                .planCode(c.getPlanCode())
                .planName(c.getPlanName())
                .annualPrice(c.getAnnualPrice())
                .trialDays(c.getTrialDays())
                .storeLimit(c.getStoreLimit())
                .staffLimit(staffLimit)
                .storageQuotaGb(c.getStorageQuotaGb())
                .features(c.getFeatures())
                .isDefault(c.getIsDefault())
                .status(c.getStatus())
                .sortOrder(c.getSortOrder())
                .updatedAt(c.getUpdatedAt() != null ? c.getUpdatedAt() : c.getCreatedAt())
                .build();
    }
}
