package com.seahorse.store.interfaces.web;

import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.iam.model.StoreRegisterConfig;
import com.seahorse.store.infrastructure.repository.StoreRegisterConfigRepository;
import com.seahorse.store.infrastructure.repository.StoreRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Tag(name = "17. 门店基础信息与自主开卡定制配置", description = "门店公开档案查询、自助开卡偏好与充多少送多少方案云端持久化")
@RestController
@RequestMapping("/api/store")
@RequiredArgsConstructor
public class StoreInfoController {

    private final StoreRepository storeRepository;
    private final StoreRegisterConfigRepository storeRegisterConfigRepository;
    private final com.seahorse.store.application.service.AuditLogAppService auditLogAppService;
    private final jakarta.servlet.http.HttpServletRequest request;

    @Operation(summary = "获取指定门店的基础信息 (公开无需Token)")
    @GetMapping("/info")
    public ApiResponse<Store> getStoreInfo(@RequestParam("storeId") String storeId) {
        if (storeId == null || storeId.trim().isEmpty()) {
            return ApiResponse.error(400, "门店编号不能为空");
        }
        Optional<Store> storeOpt = storeRepository.findByStoreId(storeId.trim());
        if (storeOpt.isPresent()) {
            return ApiResponse.success(storeOpt.get());
        }
        // 若数据库中无此 storeId，且是以 S84624 等形式，尝试按默认门店或新虚拟门店优雅返回
        Store fallback = Store.builder()
                .storeId(storeId.trim())
                .storeName("海马智慧门店 (" + storeId.trim() + ")")
                .tenantId(TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001")
                .industry(com.seahorse.store.domain.iam.enums.IndustryType.BEAUTY)
                .address("智慧商业中心 101号铺")
                .phone("400-888-6688")
                .businessHours("09:00 - 22:00")
                .status("ACTIVE")
                .build();
        return ApiResponse.success(fallback);
    }

    @Operation(summary = "更新指定门店的基础信息")
    @PostMapping("/info/update")
    public ApiResponse<Store> updateStoreInfo(@RequestBody Store updateReq) {
        if (updateReq.getStoreId() == null || updateReq.getStoreId().trim().isEmpty()) {
            return ApiResponse.error(400, "门店编号不能为空");
        }
        String sId = updateReq.getStoreId().trim();
        Store store = storeRepository.findByStoreId(sId).orElseGet(() -> Store.builder()
                .storeId(sId)
                .tenantId(TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001")
                .status("ACTIVE")
                .build());

        if (updateReq.getStoreName() != null) store.setStoreName(updateReq.getStoreName().trim());
        if (updateReq.getIndustry() != null) store.setIndustry(updateReq.getIndustry());
        if (updateReq.getIndustryCategoryName() != null) store.setIndustryCategoryName(updateReq.getIndustryCategoryName().trim());
        if (updateReq.getAddress() != null) store.setAddress(updateReq.getAddress().trim());
        if (updateReq.getPhone() != null) store.setPhone(updateReq.getPhone().trim());
        if (updateReq.getBusinessHours() != null) store.setBusinessHours(updateReq.getBusinessHours().trim());
        if (updateReq.getFeeName() != null) store.setFeeName(updateReq.getFeeName().trim());
        if (updateReq.getDefaultFeeAmount() != null) store.setDefaultFeeAmount(updateReq.getDefaultFeeAmount());
        if (updateReq.getFeeEnabled() != null) store.setFeeEnabled(updateReq.getFeeEnabled());
        store.setUpdatedAt(LocalDateTime.now());

        Store saved = storeRepository.save(store);
        log.info("【门店基础信息已更新】storeId={}, name={}, industry={}, hours={}", sId, saved.getStoreName(), saved.getIndustry(), saved.getBusinessHours());
        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = TenantContext.getUsername() != null ? TenantContext.getUsername() : "merchant";
        auditLogAppService.recordLog(
                saved.getTenantId(),
                null,
                saved.getStoreId(),
                saved.getStoreName(),
                null,
                username,
                null,
                "修改门店基础信息",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("修改门店档案: %s (%s), 业态: %s, 电话: %s",
                        saved.getStoreName(), saved.getStoreId(), saved.getIndustry() != null ? saved.getIndustry().getDescription() : "-", saved.getPhone())
        );
        return ApiResponse.success("门店基础信息已更新成功", saved);
    }

    public static String getIndustryDefaultPreferenceTags(com.seahorse.store.domain.iam.enums.IndustryType industry) {
        if (industry == null) {
            return "[\"常客免推销\",\"服务偏好安静\",\"微信电子账单\"]";
        }
        switch (industry) {
            case RESTAURANT:
                return "[\"微辣免葱\",\"少盐少油少糖\",\"偏爱安静包厢\",\"不吃香菜姜蒜\",\"常带儿童就餐\",\"自备酒水\",\"海鲜不过敏\",\"米饭稍软\"]";
            case FOOT_SPA:
                return "[\"力度偏重\",\"力度适中\",\"中药足浴包偏好\",\"精油开背偏好\",\"喜好安静免推销\",\"肩颈重点加强\",\"修脚去死皮偏好\",\"饮品偏好红枣枸杞茶\"]";
            case AUTO:
                return "[\"全合成机油偏好\",\"定期深度底盘检查\",\"车内高温桑拿除味\",\"原厂配件优先\",\"空调滤芯定期换\",\"轮胎动平衡常检\",\"偏好周末维保\",\"洗车需深度除尘\"]";
            case TEA_HOUSE:
                return "[\"偏爱生普/白茶\",\"水温要求沸水\",\"偏爱安静雅间\",\"自备茶叶仅需茶具\",\"需要商务投影\",\"茶点少糖偏好\",\"常备坚果果盘\",\"喜好棋牌娱乐\"]";
            case PET:
                return "[\"胆小敏感易应激\",\"皮肤敏感需低敏香波\",\"拒绝强行烘干箱\",\"洗澡需剪指甲\",\"定期驱虫\",\"喜好零食奖励\",\"长毛易打结需开结\",\"自备洗护专用品\"]";
            case RETAIL:
                return "[\"偏好有机绿色无公害\",\"精致礼盒送礼包装\",\"积分抵现结算优先\",\"新品尝鲜品鉴体验\",\"少塑环保包装\",\"定期促销推送偏好\",\"冷链保温配送\",\"喜欢大份家庭装\"]";
            case BEAUTY:
            default:
                return "[\"发质细软\",\"敏感头皮\",\"偏爱自然修剪\",\"偏爱冷色调烫染\",\"喜好安静免推销\",\"定期头皮SPA\",\"洗头水温偏热\",\"饮品偏好温柠檬水\"]";
        }
    }

    @Operation(summary = "获取指定门店自助开卡常态偏好与首充充赠方案")
    @GetMapping("/register-config")
    public ApiResponse<StoreRegisterConfig> getRegisterConfig(
            @RequestParam("storeId") String storeId,
            @RequestParam(value = "industry", required = false) String industryParam) {
        String targetStoreId = (storeId != null && !storeId.trim().isEmpty()) ? storeId.trim() : "S001";
        
        // 查找该门店实际业态
        com.seahorse.store.domain.iam.enums.IndustryType industry = null;
        Optional<Store> storeOpt = storeRepository.findByStoreId(targetStoreId);
        if (storeOpt.isPresent() && storeOpt.get().getIndustry() != null) {
            industry = storeOpt.get().getIndustry();
        } else if (industryParam != null && !industryParam.trim().isEmpty()) {
            try {
                industry = com.seahorse.store.domain.iam.enums.IndustryType.valueOf(industryParam.trim().toUpperCase());
            } catch (Exception ignored) {}
        }
        if (industry == null) {
            industry = com.seahorse.store.domain.iam.enums.IndustryType.RESTAURANT;
        }

        Optional<StoreRegisterConfig> configOpt = storeRegisterConfigRepository.findByStoreId(targetStoreId);
        if (configOpt.isPresent()) {
            StoreRegisterConfig existing = configOpt.get();
            String prefs = existing.getPreferenceTags();
            if (prefs == null || prefs.trim().isEmpty() || "[]".equals(prefs.trim())
                    || (industry != com.seahorse.store.domain.iam.enums.IndustryType.RESTAURANT && prefs.contains("微辣免葱"))) {
                existing.setPreferenceTags(getIndustryDefaultPreferenceTags(industry));
            }
            return ApiResponse.success(existing);
        }

        // 店铺未配置偏好标签时自动返回对应业态的推荐标签
        StoreRegisterConfig defaultConfig = StoreRegisterConfig.builder()
                .tenantId(storeOpt.map(Store::getTenantId).orElse(TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001"))
                .storeId(targetStoreId)
                .preferenceTags(getIndustryDefaultPreferenceTags(industry))
                .chargeOptions("[{\"id\":1,\"title\":\"基础免费入会\",\"principal\":0,\"gift\":0,\"levelName\":\"普卡会员\",\"levelCode\":\"REGULAR\",\"badge\":\"免充激活\"},{\"id\":2,\"title\":\"首充礼遇 ￥200\",\"principal\":200,\"gift\":50,\"levelName\":\"荣耀银卡\",\"levelCode\":\"SILVER\",\"badge\":\"立赠50元\"},{\"id\":3,\"title\":\"尊享体验 ￥500\",\"principal\":500,\"gift\":150,\"levelName\":\"黄金VIP卡\",\"levelCode\":\"GOLD\",\"badge\":\"热销推荐\"},{\"id\":4,\"title\":\"VIP尊享储值 ￥800\",\"principal\":800,\"gift\":260,\"levelName\":\"VIP尊享卡\",\"levelCode\":\"VIP\",\"badge\":\"尊贵礼遇\"},{\"id\":5,\"title\":\"白金储值 ￥1000\",\"principal\":1000,\"gift\":350,\"levelName\":\"至尊白金卡\",\"levelCode\":\"PLATINUM\",\"badge\":\"超值爆款\"},{\"id\":6,\"title\":\"黑钻至尊储值 ￥3000\",\"principal\":3000,\"gift\":1200,\"levelName\":\"黑钻至尊卡\",\"levelCode\":\"DIAMOND\",\"badge\":\"终身顶格\"}]")
                .welcomeCouponEnabled(true)
                .build();
        return ApiResponse.success(defaultConfig);
    }

    @Data
    public static class SaveRegisterConfigCmd {
        private String storeId;
        private String preferenceTags; // JSON 字符串
        private String chargeOptions; // JSON 字符串
        private Boolean welcomeCouponEnabled;
    }

    @Operation(summary = "门店/店长保存自主开卡页面定制方案 (常态偏好与充多少送多少)")
    @PostMapping("/register-config")
    public ApiResponse<StoreRegisterConfig> saveRegisterConfig(@RequestBody SaveRegisterConfigCmd cmd) {
        String targetStoreId = (cmd.getStoreId() != null && !cmd.getStoreId().trim().isEmpty())
                ? cmd.getStoreId().trim()
                : (TenantContext.getStoreId() != null ? TenantContext.getStoreId() : "S001");

        StoreRegisterConfig config = storeRegisterConfigRepository.findByStoreId(targetStoreId)
                .orElseGet(() -> StoreRegisterConfig.builder()
                        .storeId(targetStoreId)
                        .tenantId(TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001")
                        .build());

        if (cmd.getPreferenceTags() != null) config.setPreferenceTags(cmd.getPreferenceTags());
        if (cmd.getChargeOptions() != null) config.setChargeOptions(cmd.getChargeOptions());
        if (cmd.getWelcomeCouponEnabled() != null) config.setWelcomeCouponEnabled(cmd.getWelcomeCouponEnabled());
        config.setUpdatedAt(LocalDateTime.now());

        StoreRegisterConfig saved = storeRegisterConfigRepository.save(config);
        log.info("【门店自助开卡配置已保存】storeId={}, prefLength={}, chargeLength={}",
                targetStoreId,
                cmd.getPreferenceTags() != null ? cmd.getPreferenceTags().length() : 0,
                cmd.getChargeOptions() != null ? cmd.getChargeOptions().length() : 0);

        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = TenantContext.getUsername() != null ? TenantContext.getUsername() : "merchant";
        auditLogAppService.recordLog(
                saved.getTenantId(),
                null,
                targetStoreId,
                null,
                null,
                username,
                null,
                "更新开卡偏好与首充方案",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("保存门店自主开卡配置 (门店: %s)", targetStoreId)
        );

        return ApiResponse.success("门店自助开卡方案已保存成功", saved);
    }

    @Operation(summary = "获取指定门店的服务要求与特殊备注常用标签")
    @GetMapping("/common-remarks")
    public ApiResponse<List<String>> getCommonRemarks(
            @RequestParam("storeId") String storeId,
            @RequestParam(value = "industry", required = false) String industryParam) {
        String targetStoreId = (storeId != null && !storeId.trim().isEmpty()) ? storeId.trim() : "S001";
        Optional<Store> storeOpt = storeRepository.findByStoreId(targetStoreId);
        
        if (storeOpt.isPresent() && storeOpt.get().getCommonRemarksJson() != null && !storeOpt.get().getCommonRemarksJson().trim().isEmpty()) {
            try {
                com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                List<String> list = mapper.readValue(storeOpt.get().getCommonRemarksJson(), new com.fasterxml.jackson.core.type.TypeReference<List<String>>() {});
                if (list != null && !list.isEmpty()) {
                    return ApiResponse.success(list);
                }
            } catch (Exception e) {
                log.warn("解析门店常用备注失败: {}", e.getMessage());
            }
        }

        // 根据业态返回推荐常用标签
        com.seahorse.store.domain.iam.enums.IndustryType industry = null;
        if (storeOpt.isPresent() && storeOpt.get().getIndustry() != null) {
            industry = storeOpt.get().getIndustry();
        } else if (industryParam != null && !industryParam.trim().isEmpty()) {
            try {
                industry = com.seahorse.store.domain.iam.enums.IndustryType.valueOf(industryParam.trim().toUpperCase());
            } catch (Exception ignored) {}
        }
        if (industry == null) industry = com.seahorse.store.domain.iam.enums.IndustryType.RESTAURANT;

        List<String> defaultRemarks = getDefaultCommonRemarksByIndustry(industry);
        return ApiResponse.success(defaultRemarks);
    }

    public static List<String> getDefaultCommonRemarksByIndustry(com.seahorse.store.domain.iam.enums.IndustryType industry) {
        if (industry == null) return java.util.Arrays.asList("加急处理", "少盐少油", "免推销", "常温茶水");
        switch (industry) {
            case RESTAURANT:
                return java.util.Arrays.asList("微辣", "免葱姜蒜", "免香菜", "少油少盐", "少糖", "免味精", "先上凉菜", "打包盒备用", "常温饮品", "加急催菜");
            case FOOT_SPA:
                return java.util.Arrays.asList("加重力度", "轻柔舒适", "重点肩颈", "加强足底", "加时15分钟", "艾灸加温", "温热红枣茶", "喜好安静免推销", "去死皮修脚");
            case AUTO:
                return java.util.Arrays.asList("原厂配件优先", "底盘重点检查", "更换空调滤芯", "洗车深度除尘", "轮胎动平衡", "保留旧滤芯查看", "加急快修");
            case TEA_HOUSE:
                return java.util.Arrays.asList("沸水冲泡", "茶汤偏浓", "茶汤偏淡", "自备茶叶", "续加热水", "加干果果盘", "调暗雅间灯光");
            case PET:
                return java.util.Arrays.asList("胆小勿大声", "皮肤敏感低敏香波", "修剪指甲", "清洁耳道", "拒绝烘干箱", "零食安抚");
            case BEAUTY:
            default:
                return java.util.Arrays.asList("水温偏热", "水温偏温", "力度适中", "重点头皮放松", "偏好自然修剪", "免推销喜静", "温柠檬水");
        }
    }

    @Data
    public static class SaveCommonRemarksCmd {
        private String storeId;
        private List<String> remarks;
    }

    @Operation(summary = "门店/店长保存服务要求与特殊备注常用标签 (多端双向同步)")
    @PostMapping("/common-remarks")
    public ApiResponse<List<String>> saveCommonRemarks(@RequestBody SaveCommonRemarksCmd cmd) {
        String targetStoreId = (cmd.getStoreId() != null && !cmd.getStoreId().trim().isEmpty())
                ? cmd.getStoreId().trim()
                : (TenantContext.getStoreId() != null ? TenantContext.getStoreId() : "S001");

        Store store = storeRepository.findByStoreId(targetStoreId).orElseGet(() -> Store.builder()
                .storeId(targetStoreId)
                .tenantId(TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001")
                .status("ACTIVE")
                .build());

        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            List<String> list = cmd.getRemarks() != null ? cmd.getRemarks() : new java.util.ArrayList<>();
            store.setCommonRemarksJson(mapper.writeValueAsString(list));
            store.setUpdatedAt(LocalDateTime.now());
            storeRepository.save(store);
            log.info("【门店常用服务备注已保存】storeId={}, count={}", targetStoreId, list.size());
            return ApiResponse.success("常用备注标签已保存并同步", list);
        } catch (Exception e) {
            log.error("保存常用备注标签失败", e);
            return ApiResponse.error(500, "保存失败: " + e.getMessage());
        }
    }

    @Data
    public static class StaffDisplayConfigCmd {
        private String storeId;
        private String staffDisplayMode; // NICKNAME_FIRST, NICKNAME, REAL_NAME, BOTH
    }

    @Operation(summary = "获取门店服务人员对外称谓展示规则")
    @GetMapping("/staff-display-mode")
    public ApiResponse<java.util.Map<String, String>> getStaffDisplayMode(@RequestParam("storeId") String storeId) {
        String targetStoreId = (storeId != null && !storeId.trim().isEmpty()) ? storeId.trim() : "S001";
        Optional<Store> storeOpt = storeRepository.findByStoreId(targetStoreId);
        String mode = "NICKNAME_FIRST";
        if (storeOpt.isPresent() && storeOpt.get().getStaffDisplayMode() != null && !storeOpt.get().getStaffDisplayMode().trim().isEmpty()) {
            mode = storeOpt.get().getStaffDisplayMode().trim();
        }
        java.util.Map<String, String> res = new java.util.HashMap<>();
        res.put("storeId", targetStoreId);
        res.put("staffDisplayMode", mode);
        return ApiResponse.success(res);
    }

    @Operation(summary = "保存门店服务人员对外称谓展示规则")
    @PostMapping("/staff-display-mode")
    public ApiResponse<java.util.Map<String, String>> saveStaffDisplayMode(@RequestBody StaffDisplayConfigCmd cmd) {
        String targetStoreId = (cmd.getStoreId() != null && !cmd.getStoreId().trim().isEmpty())
                ? cmd.getStoreId().trim()
                : (TenantContext.getStoreId() != null ? TenantContext.getStoreId() : "S001");

        Store store = storeRepository.findByStoreId(targetStoreId).orElseGet(() -> Store.builder()
                .storeId(targetStoreId)
                .tenantId(TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001")
                .status("ACTIVE")
                .build());

        String mode = (cmd.getStaffDisplayMode() != null && !cmd.getStaffDisplayMode().trim().isEmpty())
                ? cmd.getStaffDisplayMode().trim() : "NICKNAME_FIRST";
        store.setStaffDisplayMode(mode);
        store.setUpdatedAt(LocalDateTime.now());
        storeRepository.save(store);
        log.info("【门店服务人员称谓规则已保存】storeId={}, mode={}", targetStoreId, mode);

        java.util.Map<String, String> res = new java.util.HashMap<>();
        res.put("storeId", targetStoreId);
        res.put("staffDisplayMode", mode);
        return ApiResponse.success("服务人员称谓展示规则已生效", res);
    }
}
