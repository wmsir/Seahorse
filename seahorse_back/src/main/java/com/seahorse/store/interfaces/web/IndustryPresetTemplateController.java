package com.seahorse.store.interfaces.web;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.iam.model.IndustryPresetTemplate;
import com.seahorse.store.infrastructure.repository.IndustryPresetTemplateRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;

/**
 * 常用行业全景预设配置控制器 (超级管理员统一配置中心)
 * 涵盖 7 大行业：美业(BEAUTY)、餐饮(RESTAURANT)、足道(FOOT_SPA)、汽修(AUTO)、茶楼(TEA_HOUSE)、宠物(PET)、零售(RETAIL)
 * 包含：会员卡设置、顾客常态偏好配置、首充与充多少送多少方案、常用部门和在编岗位
 */
@Slf4j
@Tag(name = "09. 行业预设全景配置中心", description = "平台超级管理员管理 7 大行业会员卡、偏好标签、首充方案与部门岗位标准模板")
@RestController
@RequestMapping("/api/industry/preset-template")
@RequiredArgsConstructor
public class IndustryPresetTemplateController {

    private final IndustryPresetTemplateRepository templateRepository;
    private final ObjectMapper objectMapper;

    @Operation(summary = "获取所有支持的行业预设列表概要")
    @GetMapping("/all")
    public ApiResponse<List<Map<String, Object>>> getAllIndustryPresets() {
        List<Map<String, Object>> result = new ArrayList<>();
        String[] industries = {"BEAUTY", "RESTAURANT", "FOOT_SPA", "AUTO", "TEA_HOUSE", "PET", "RETAIL"};
        for (String ind : industries) {
            IndustryPresetTemplate template = getOrCreateDefaultTemplate(ind);
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("industry", template.getIndustry());
            map.put("industryName", template.getIndustryName());
            map.put("updatedAt", template.getUpdatedAt());
            map.put("updatedBy", template.getUpdatedBy());
            result.add(map);
        }
        return ApiResponse.success(result);
    }

    @Operation(summary = "获取指定行业全景配置 (优先读数据库，若无则初始化默认标准并落库)")
    @GetMapping("/{industry}")
    public ApiResponse<Map<String, Object>> getIndustryPreset(@PathVariable("industry") String industry) {
        String ind = (industry != null ? industry.trim().toUpperCase() : "BEAUTY");
        IndustryPresetTemplate template = getOrCreateDefaultTemplate(ind);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", template.getId());
        data.put("industry", template.getIndustry());
        data.put("industryName", template.getIndustryName());
        data.put("updatedAt", template.getUpdatedAt());
        data.put("updatedBy", template.getUpdatedBy());

        try {
            data.put("cardTemplates", objectMapper.readValue(template.getCardTemplatesJson(), new TypeReference<List<Map<String, Object>>>() {}));
        } catch (Exception e) {
            data.put("cardTemplates", Collections.emptyList());
        }

        try {
            data.put("preferenceTags", objectMapper.readValue(template.getPreferenceTagsJson(), new TypeReference<List<String>>() {}));
        } catch (Exception e) {
            data.put("preferenceTags", Collections.emptyList());
        }

        try {
            data.put("chargeOptions", objectMapper.readValue(template.getChargeOptionsJson(), new TypeReference<List<Map<String, Object>>>() {}));
        } catch (Exception e) {
            data.put("chargeOptions", Collections.emptyList());
        }

        try {
            data.put("departments", objectMapper.readValue(template.getDepartmentsJson(), new TypeReference<List<String>>() {}));
        } catch (Exception e) {
            data.put("departments", Collections.emptyList());
        }

        try {
            data.put("positions", objectMapper.readValue(template.getPositionsJson(), new TypeReference<List<Map<String, Object>>>() {}));
        } catch (Exception e) {
            data.put("positions", Collections.emptyList());
        }

        return ApiResponse.success(data);
    }

    @Data
    public static class SaveIndustryTemplateCmd {
        private String industry;
        private String industryName;
        private List<Map<String, Object>> cardTemplates;
        private List<String> preferenceTags;
        private List<Map<String, Object>> chargeOptions;
        private List<String> departments;
        private List<Map<String, Object>> positions;
    }

    @Operation(summary = "超级管理员保存与更新指定行业全景预设配置")
    @PostMapping("/save")
    public ApiResponse<String> saveIndustryPreset(@RequestBody SaveIndustryTemplateCmd cmd) {
        if (cmd.getIndustry() == null || cmd.getIndustry().trim().isEmpty()) {
            return ApiResponse.error(400, "行业标识代码不能为空");
        }
        String ind = cmd.getIndustry().trim().toUpperCase();

        try {
            IndustryPresetTemplate template = templateRepository.findByIndustry(ind)
                    .orElseGet(() -> IndustryPresetTemplate.builder().industry(ind).build());

            if (cmd.getIndustryName() != null && !cmd.getIndustryName().trim().isEmpty()) {
                template.setIndustryName(cmd.getIndustryName().trim());
            } else if (template.getIndustryName() == null) {
                template.setIndustryName(getDefaultIndustryName(ind));
            }

            if (cmd.getCardTemplates() != null) {
                template.setCardTemplatesJson(objectMapper.writeValueAsString(cmd.getCardTemplates()));
            }
            if (cmd.getPreferenceTags() != null) {
                template.setPreferenceTagsJson(objectMapper.writeValueAsString(cmd.getPreferenceTags()));
            }
            if (cmd.getChargeOptions() != null) {
                template.setChargeOptionsJson(objectMapper.writeValueAsString(cmd.getChargeOptions()));
            }
            if (cmd.getDepartments() != null) {
                template.setDepartmentsJson(objectMapper.writeValueAsString(cmd.getDepartments()));
            }
            if (cmd.getPositions() != null) {
                template.setPositionsJson(objectMapper.writeValueAsString(cmd.getPositions()));
            }

            String operator = TenantContext.getUsername() != null ? TenantContext.getUsername() : "superadmin";
            template.setUpdatedBy(operator);
            template.setUpdatedAt(LocalDateTime.now());

            templateRepository.save(template);
            log.info("【超管全景行业模板已保存】industry={}, operator={}", ind, operator);
            return ApiResponse.success("行业全景配置已成功保存至数据库！", "OK");
        } catch (Exception e) {
            log.error("保存行业全景模板异常", e);
            return ApiResponse.error(500, "保存行业配置失败: " + e.getMessage());
        }
    }

    @Operation(summary = "超级管理员重置指定行业为系统出厂标准预设")
    @PostMapping("/reset/{industry}")
    public ApiResponse<String> resetIndustryPreset(@PathVariable("industry") String industry) {
        String ind = (industry != null ? industry.trim().toUpperCase() : "BEAUTY");
        IndustryPresetTemplate defaultTemplate = buildDefaultTemplate(ind);

        IndustryPresetTemplate template = templateRepository.findByIndustry(ind)
                .orElseGet(() -> IndustryPresetTemplate.builder().industry(ind).build());

        template.setIndustryName(defaultTemplate.getIndustryName());
        template.setCardTemplatesJson(defaultTemplate.getCardTemplatesJson());
        template.setPreferenceTagsJson(defaultTemplate.getPreferenceTagsJson());
        template.setChargeOptionsJson(defaultTemplate.getChargeOptionsJson());
        template.setDepartmentsJson(defaultTemplate.getDepartmentsJson());
        template.setPositionsJson(defaultTemplate.getPositionsJson());

        String operator = TenantContext.getUsername() != null ? TenantContext.getUsername() : "superadmin";
        template.setUpdatedBy(operator);
        template.setUpdatedAt(LocalDateTime.now());

        templateRepository.save(template);
        return ApiResponse.success("已恢复出厂标准行业配置！", "OK");
    }

    private IndustryPresetTemplate getOrCreateDefaultTemplate(String ind) {
        Optional<IndustryPresetTemplate> opt = templateRepository.findByIndustry(ind);
        if (opt.isPresent()) {
            return opt.get();
        }
        IndustryPresetTemplate def = buildDefaultTemplate(ind);
        try {
            return templateRepository.save(def);
        } catch (Exception e) {
            log.warn("保存默认行业模板并发或失败，返回临时模板: {}", e.getMessage());
            return def;
        }
    }

    private String getDefaultIndustryName(String ind) {
        switch (ind) {
            case "RESTAURANT": return "餐饮美食/饮品";
            case "FOOT_SPA": return "足道养生/推拿SPA";
            case "AUTO": return "汽车维保/改装洗美";
            case "TEA_HOUSE": return "商务茶楼/棋牌雅集";
            case "PET": return "宠物生活/医疗洗护";
            case "RETAIL": return "综合零售/商超专卖";
            case "BEAUTY":
            default: return "美容美发美甲";
        }
    }

    private IndustryPresetTemplate buildDefaultTemplate(String ind) {
        IndustryPresetTemplate t = new IndustryPresetTemplate();
        t.setIndustry(ind);
        t.setIndustryName(getDefaultIndustryName(ind));
        t.setUpdatedBy("SYSTEM_INIT");
        t.setCreatedAt(LocalDateTime.now());
        t.setUpdatedAt(LocalDateTime.now());

        try {
            switch (ind) {
                case "RESTAURANT":
                    t.setDepartmentsJson(objectMapper.writeValueAsString(Arrays.asList("店务管理部", "前厅服务部", "后厨烹饪部", "品质保障部", "前台收银部")));
                    t.setPreferenceTagsJson(objectMapper.writeValueAsString(Arrays.asList("微辣免葱", "少盐少油少糖", "偏爱安静包厢", "不吃香菜姜蒜", "常带儿童就餐", "自备酒水", "海鲜不过敏", "米饭稍软")));
                    t.setChargeOptionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCharge(1, "基础免费入会", 0, 0, "普卡会员", "REGULAR", "免充激活"),
                            createCharge(2, "尝鲜储值 ￥200", 200, 30, "荣耀银卡", "SILVER", "立赠30元"),
                            createCharge(3, "美味畅享 ￥500", 500, 100, "黄金VIP卡", "GOLD", "赠招牌菜品"),
                            createCharge(4, "商务宴请 ￥1000", 1000, 260, "VIP尊享卡", "VIP", "尊享包厢优先"),
                            createCharge(5, "尊荣白金 ￥2000", 2000, 600, "至尊白金卡", "PLATINUM", "超值立返"),
                            createCharge(6, "黑钻顶格储值 ￥5000", 5000, 1800, "黑钻至尊卡", "DIAMOND", "全年免服务费")
                    )));
                    t.setPositionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createPost(1L, "餐厅店长/运营主管", "店务管理部", "STORE_MANAGER", "MANAGER", 7000, "￥7000-11000元/月", 0.05, "全面统筹日常运营、现场调度与月度经营核算", "具备餐饮前厅与后厨统筹管理经验"),
                            createPost(2L, "前厅领班/主管", "前厅服务部", "CASHIER", "CASHIER", 5200, "￥5200-7500元/月", 0.03, "负责前厅迎宾领位、翻台调度与客户满意度", "沟通亲和力强，有餐饮服务管理经验"),
                            createPost(3L, "招牌烹饪/主厨", "后厨烹饪部", "TECHNICIAN", "TECHNICIAN", 6800, "￥6800-9500元/月", 0.06, "负责后厨菜品出品、火候掌控与菜品品控", "具备专业中西餐厨艺技能与品控意识"),
                            createPost(4L, "前台迎宾/收银员", "前台收银部", "CASHIER", "CASHIER", 4500, "￥4500-6000元/月", 0.02, "负责到店接待、系统收银开单与发票开具", "细致认真，掌握主流收银设备操作"),
                            createPost(5L, "后厨切配/打荷员", "后厨烹饪部", "TECHNICIAN", "TECHNICIAN", 4800, "￥4800-6500元/月", 0.03, "负责食材初加工、串签备料与工位卫生", "吃苦耐劳，熟悉食品安全规范")
                    )));
                    t.setCardTemplatesJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCard(1, "STORED_VALUE", "储值卡", "饕餮美食储值金卡", 1000, 1000, "堂食单点菜品享9折，充值即送冷菜尝鲜券", 365, "gold", 0.90),
                            createCard(2, "TIME_CARD", "次卡", "工作日午市特惠 10次卡", 380, 500, "包含10次工作日精选商务轻食套餐，免排队快速出餐", 90, "blue", 0.76),
                            createCard(3, "BENEFIT_CARD", "权益卡", "尊荣黑金贵宾权益卡", 3000, 3000, "包厢免收茶位费，生日当月尊享特级主厨私房菜一份", 365, "black", 0.85)
                    )));
                    break;

                case "FOOT_SPA":
                    t.setDepartmentsJson(objectMapper.writeValueAsString(Arrays.asList("店务管理部", "足道养生部", "SPA理疗部", "理疗推拿部", "前台客服部")));
                    t.setPreferenceTagsJson(objectMapper.writeValueAsString(Arrays.asList("力度偏重", "力度适中", "中药足浴包偏好", "精油开背偏好", "喜好安静免推销", "肩颈重点加强", "修脚去死皮偏好", "饮品偏好红枣枸杞茶")));
                    t.setChargeOptionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCharge(1, "基础免费入会", 0, 0, "普卡会员", "REGULAR", "免充激活"),
                            createCharge(2, "足道初验 ￥300", 300, 80, "荣耀银卡", "SILVER", "立赠80元"),
                            createCharge(3, "经络调理 ￥600", 600, 180, "黄金VIP卡", "GOLD", "赠足浴包"),
                            createCharge(4, "尊享理疗 ￥1000", 1000, 350, "VIP尊享卡", "VIP", "赠经络推拿"),
                            createCharge(5, "白金养生 ￥2000", 2000, 800, "至尊白金卡", "PLATINUM", "专属SPA房"),
                            createCharge(6, "黑钻至尊 ￥5000", 5000, 2200, "黑钻至尊卡", "DIAMOND", "终身VIP私汤")
                    )));
                    t.setPositionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createPost(1L, "养生会所店长/主管", "店务管理部", "STORE_MANAGER", "MANAGER", 7000, "￥7000-12000元/月", 0.08, "统筹日常店务运营、房态调度、技师考勤与客户满意度", "养生会所管理经验3年以上"),
                            createPost(2L, "资深足道养生技师", "足道养生部", "TECHNICIAN", "TECHNICIAN", 6500, "￥6500-11000元/月", 0.25, "负责顾客足底反射疗法、古法修脚与足部养护项目交付", "手法熟练，有专业足道从业经验"),
                            createPost(3L, "首席SPA芳疗理疗师", "SPA理疗部", "TECHNICIAN", "TECHNICIAN", 6000, "￥6000-10000元/月", 0.28, "负责全身精油SPA、淋巴排毒、肩颈舒缓与高端芳疗", "具备芳疗专业资格，手法温和沉稳"),
                            createPost(4L, "中医经络推拿师", "理疗推拿部", "TECHNICIAN", "TECHNICIAN", 5800, "￥5800-9500元/月", 0.26, "负责经络穴位调理、背部拔罐刮痧与肌肉劳损松解", "持有中医推拿相关经验者优先"),
                            createPost(5L, "前台接待主管", "前台客服部", "CASHIER", "CASHIER", 4800, "￥4800-7000元/月", 0.05, "负责到店迎宾领位、房态排钟分配、收银买单与会员储值", "形象端正，亲和力佳，懂排钟技巧")
                    )));
                    t.setCardTemplatesJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCard(1, "TIME_CARD", "次卡", "经典草本养生足道 10次卡", 1280, 1680, "包含10次60分钟草本养生足浴，附赠修脚一次", 180, "emerald", 0.76),
                            createCard(2, "STORED_VALUE", "储值卡", "泰式芳疗SPA储值金卡", 2000, 2000, "全店养生推拿及精油项目享8.5折，充值即赠采耳1次", 365, "purple", 0.85),
                            createCard(3, "DURATION_CARD", "期限卡", "至尊养生尊崇年卡", 4980, 6800, "全年365天无限次享受足道免茶位费与专用私享包房", 365, "black", 0.80)
                    )));
                    break;

                case "AUTO":
                    t.setDepartmentsJson(objectMapper.writeValueAsString(Arrays.asList("店务管理部", "技术养护部", "车间维修部", "钣喷美容部", "前台客服部")));
                    t.setPreferenceTagsJson(objectMapper.writeValueAsString(Arrays.asList("全合成机油偏好", "定期深度底盘检查", "车内高温桑拿除味", "原厂配件优先", "空调滤芯定期换", "轮胎动平衡常检", "偏好周末维保", "洗车需深度除尘")));
                    t.setChargeOptionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCharge(1, "基础免费入会", 0, 0, "普卡会员", "REGULAR", "免充激活"),
                            createCharge(2, "养护体验 ￥300", 300, 60, "荣耀银卡", "SILVER", "赠精细洗车"),
                            createCharge(3, "金牌车主 ￥800", 800, 220, "黄金VIP卡", "GOLD", "赠全车检测"),
                            createCharge(4, "尊享保养 ￥1500", 1500, 480, "VIP尊享卡", "VIP", "赠小保养1次"),
                            createCharge(5, "白金车主 ￥3000", 3000, 1100, "至尊白金卡", "PLATINUM", "享免费救援"),
                            createCharge(6, "黑钻至尊车主 ￥6000", 6000, 2600, "黑钻至尊卡", "DIAMOND", "全年免费洗车")
                    )));
                    t.setPositionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createPost(1L, "汽修总监/店长", "店务管理部", "STORE_MANAGER", "MANAGER", 8000, "￥8000-12000元/月", 0.08, "全面统筹车间接车诊断、工位调度与维修施工品控", "汽修厂5年以上管理与诊断经验"),
                            createPost(2L, "资深机电快修技师", "车间维修部", "TECHNICIAN", "TECHNICIAN", 6000, "￥6000-9000元/月", 0.20, "负责车辆机电快修、全车保养、底盘调校与故障排除", "持有汽修中高级证书，熟悉主流车型"),
                            createPost(3L, "汽车美容养护技师", "钣喷美容部", "TECHNICIAN", "TECHNICIAN", 5000, "￥5000-7500元/月", 0.22, "负责精细洗车、车身镀晶打蜡、内饰深度桑拿与微修", "细致周到，具备漆面养护技能"),
                            createPost(4L, "首席服务顾问(SA)", "前台客服部", "CASHIER", "CASHIER", 5500, "￥5500-8500元/月", 0.06, "负责进店接车问询、系统派工开单与施工后交车验收", "沟通表达流畅，懂汽车养护专业话术")
                    )));
                    t.setCardTemplatesJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCard(1, "TIME_CARD", "次卡", "全年精致洗车 12次卡", 480, 600, "包含12次高压泥沙预洗+车身水蜡养护+轮胎养护", 365, "blue", 0.80),
                            createCard(2, "TIME_CARD", "次卡", "全合成机油小保养 3次卡", 980, 1380, "包含美孚全合成机油+原厂机油滤芯+42项全车安全检测", 365, "gold", 0.71),
                            createCard(3, "STORED_VALUE", "储值卡", "尊贵车管家储值卡", 3000, 3000, "全店工时与零配件享受8.5折，免费提供同城24H道路救援", 365, "black", 0.85)
                    )));
                    break;

                case "TEA_HOUSE":
                    t.setDepartmentsJson(objectMapper.writeValueAsString(Arrays.asList("店务管理部", "茶艺服务部", "前厅接待部", "茶礼运营部", "前台客服部")));
                    t.setPreferenceTagsJson(objectMapper.writeValueAsString(Arrays.asList("偏爱生普/白茶", "水温要求沸水", "偏爱安静雅间", "自备茶叶仅需茶具", "需要商务投影", "茶点少糖偏好", "常备坚果果盘", "喜好棋牌娱乐")));
                    t.setChargeOptionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCharge(1, "基础免费入会", 0, 0, "普卡会员", "REGULAR", "免充激活"),
                            createCharge(2, "品茗初试 ￥300", 300, 60, "荣耀银卡", "SILVER", "赠私房茶点"),
                            createCharge(3, "雅集雅士 ￥600", 600, 160, "黄金VIP卡", "GOLD", "赠名山茶样"),
                            createCharge(4, "商务雅聚 ￥1200", 1200, 380, "VIP尊享卡", "VIP", "包厢优先预留"),
                            createCharge(5, "鸿儒白金 ￥2500", 2500, 900, "至尊白金卡", "PLATINUM", "赠专属茶柜"),
                            createCharge(6, "紫砂黑钻 ￥6000", 6000, 2500, "黑钻至尊卡", "DIAMOND", "全年免茶位费")
                    )));
                    t.setPositionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createPost(1L, "茶楼掌柜/店长", "店务管理部", "STORE_MANAGER", "MANAGER", 6500, "￥6500-10000元/月", 0.08, "统筹茶室日常营运、茶礼接待与雅间环境调度", "具备中高端茶馆经营管理经验"),
                            createPost(2L, "资深茶艺师/侍茶师", "茶艺服务部", "TECHNICIAN", "TECHNICIAN", 5500, "￥5500-8500元/月", 0.18, "负责名优茶冲泡品饮演示、茶道文化讲解与茶礼服务", "持有中级以上茶艺师资格证"),
                            createPost(3L, "雅间管家/茶礼服务员", "前厅接待部", "TECHNICIAN", "TECHNICIAN", 4800, "￥4800-7000元/月", 0.12, "负责茶室雅座包厢布景备茶、续水与茶点呈递", "举止端庄，礼貌周到，具备服务礼仪"),
                            createPost(4L, "前台收银员", "前台客服部", "CASHIER", "CASHIER", 4500, "￥4500-6000元/月", 0.03, "负责到店接待、茶室消费开单与收银结算", "细致认真，掌握结账系统操作")
                    )));
                    t.setCardTemplatesJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCard(1, "TIME_CARD", "次卡", "商务雅间 4小时包段 10次卡", 1500, 2000, "包含10次4小时中型商务雅间使用，附赠名优普洱茶1泡", 180, "emerald", 0.75),
                            createCard(2, "STORED_VALUE", "储值卡", "茶楼会员储值金卡", 2000, 2000, "包厢房费与全店名茶享受8.8折优惠，赠送私家紫砂品茗杯一套", 365, "gold", 0.88),
                            createCard(3, "BENEFIT_CARD", "权益卡", "茶室尊崇黑金卡", 5000, 5000, "全店房费8折，尊享专属私人藏茶柜保管服务及优先订房特权", 365, "black", 0.80)
                    )));
                    break;

                case "PET":
                    t.setDepartmentsJson(objectMapper.writeValueAsString(Arrays.asList("店务管理部", "宠物美容部", "洗护服务部", "寄养萌宠部", "前台客服部")));
                    t.setPreferenceTagsJson(objectMapper.writeValueAsString(Arrays.asList("胆小敏感易应激", "皮肤敏感需低敏香波", "拒绝强行烘干箱", "洗澡需剪指甲", "定期驱虫", "喜好零食奖励", "长毛易打结需开结", "自备洗护专用品")));
                    t.setChargeOptionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCharge(1, "基础免费入会", 0, 0, "普卡会员", "REGULAR", "免充激活"),
                            createCharge(2, "爱宠尝鲜 ￥200", 200, 40, "荣耀银卡", "SILVER", "赠零食罐"),
                            createCharge(3, "萌宠关爱 ￥500", 500, 130, "黄金VIP卡", "GOLD", "赠单次药浴"),
                            createCharge(4, "宠爱尊享 ￥1000", 1000, 320, "VIP尊享卡", "VIP", "洗美8.8折"),
                            createCharge(5, "白金贵宾 ￥2000", 2000, 750, "至尊白金卡", "PLATINUM", "免寄养2天"),
                            createCharge(6, "黑钻至尊 ￥5000", 5000, 2100, "黑钻至尊卡", "DIAMOND", "洗护免费接送")
                    )));
                    t.setPositionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createPost(1L, "宠物生活馆店长", "店务管理部", "STORE_MANAGER", "MANAGER", 6500, "￥6500-10000元/月", 0.08, "全面统筹门店日常经营、洗美工位排班与宠物安全品控", "具备宠物门店管理经验"),
                            createPost(2L, "资深宠物美容造型师", "宠物美容部", "TECHNICIAN", "TECHNICIAN", 6000, "￥6000-10000元/月", 0.25, "负责爱宠洗护吹干、全身创意修剪与染色造型设计", "具备专业C级或B级宠物美容资格"),
                            createPost(3L, "宠物洗护精细技师", "洗护服务部", "TECHNICIAN", "TECHNICIAN", 4800, "￥4800-7500元/月", 0.22, "负责爱宠药浴浸泡、耳道清洁、挤肛门腺与基础护理", "喜爱小动物，耐心细致，熟悉保定手法"),
                            createPost(4L, "门店接待/收银主管", "前台客服部", "CASHIER", "CASHIER", 4500, "￥4500-6500元/月", 0.05, "负责接宠登记、健康情况问询、商品导购与收银结算", "亲和力强，喜爱宠物，懂宠物健康常识")
                    )));
                    t.setCardTemplatesJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCard(1, "TIME_CARD", "次卡", "精细洗护 5次卡", 350, 450, "包含5次精细洗吹、耳道清理、指甲修剪与肛门腺清理", 180, "blue", 0.78),
                            createCard(2, "TIME_CARD", "次卡", "美容造型季卡 3次", 520, 660, "包含3次全套宠物深度洗护+全身毛发修剪造型", 120, "rose", 0.79),
                            createCard(3, "STORED_VALUE", "储值卡", "萌宠至尊储值卡", 2000, 2000, "活体、用品、洗美、寄养全场享受8.5折优惠", 365, "gold", 0.85)
                    )));
                    break;

                case "RETAIL":
                    t.setDepartmentsJson(objectMapper.writeValueAsString(Arrays.asList("店务管理部", "门店服务部", "仓储配货部", "采购质检部", "前台收银部")));
                    t.setPreferenceTagsJson(objectMapper.writeValueAsString(Arrays.asList("偏好有机绿色无公害", "精致礼盒送礼包装", "积分抵现结算优先", "新品尝鲜品鉴体验", "少塑环保包装", "定期促销推送偏好", "冷链保温配送", "喜欢大份家庭装")));
                    t.setChargeOptionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCharge(1, "基础免费入会", 0, 0, "普卡会员", "REGULAR", "免充激活"),
                            createCharge(2, "优选立享 ￥200", 200, 30, "荣耀银卡", "SILVER", "立赠30元抵用金"),
                            createCharge(3, "乐享购物 ￥500", 500, 90, "黄金VIP卡", "GOLD", "赠热卖伴手礼"),
                            createCharge(4, "尊享储值 ￥1000", 1000, 220, "VIP尊享卡", "VIP", "全场享9折"),
                            createCharge(5, "白金尊享 ￥2000", 2000, 500, "至尊白金卡", "PLATINUM", "双倍积分特权"),
                            createCharge(6, "黑钻顶格 ￥5000", 5000, 1500, "黑钻至尊卡", "DIAMOND", "同城急速免送达")
                    )));
                    t.setPositionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createPost(1L, "运营总监/店长", "店务管理部", "STORE_MANAGER", "MANAGER", 7500, "￥7500-11000元/月", 0.05, "统筹门店销售业绩、商品陈列与人员督导", "大型商超或专营零售店长管理经验"),
                            createPost(2L, "资深导购/销售顾问", "门店服务部", "CASHIER", "CASHIER", 4500, "￥4500-7000元/月", 0.08, "负责客户导购选品、收银开单与会员纳新", "亲和力好，熟悉商品卖点"),
                            createPost(3L, "仓储质检盘点员", "仓储配货部", "TECHNICIAN", "TECHNICIAN", 4800, "￥4800-6500元/月", 0.03, "负责商品入库核验、条码打印与库存盘点", "细致严谨，掌握仓储系统出入库操作"),
                            createPost(4L, "前台收银结算员", "前台收银部", "CASHIER", "CASHIER", 4500, "￥4500-6000元/月", 0.02, "负责商品扫码结算、开卡储值与对账交接", "细致认真，收银操作零失误")
                    )));
                    t.setCardTemplatesJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCard(1, "STORED_VALUE", "储值卡", "畅享储值会员卡", 1000, 1000, "全场常规商品享受9.2折，充值即送高档帆布购物袋", 365, "emerald", 0.92),
                            createCard(2, "STORED_VALUE", "储值卡", "节日礼品尊享卡", 2000, 2000, "高端礼盒与进口直采商品享8.8折，支持专人配货包装", 365, "gold", 0.88),
                            createCard(3, "BENEFIT_CARD", "权益卡", "黑金VIP年度特权卡", 365, 365, "每日享受专属会员成本价特惠商品1件，同城配送免运费", 365, "black", 0.95)
                    )));
                    break;

                case "BEAUTY":
                default:
                    t.setDepartmentsJson(objectMapper.writeValueAsString(Arrays.asList("店务管理部", "美业设计部", "前台客服部", "技术养护部", "门店服务部")));
                    t.setPreferenceTagsJson(objectMapper.writeValueAsString(Arrays.asList("发质细软", "敏感头皮", "偏爱自然修剪", "偏爱冷色调烫染", "喜好安静免推销", "定期头皮SPA", "洗头水温偏热", "饮品偏好温柠檬水")));
                    t.setChargeOptionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCharge(1, "基础免费入会", 0, 0, "普卡会员", "REGULAR", "免充激活"),
                            createCharge(2, "首充礼遇 ￥200", 200, 50, "荣耀银卡", "SILVER", "立赠50元"),
                            createCharge(3, "尊享体验 ￥500", 500, 150, "黄金VIP卡", "GOLD", "热销推荐"),
                            createCharge(4, "VIP尊享储值 ￥800", 800, 260, "VIP尊享卡", "VIP", "尊贵礼遇"),
                            createCharge(5, "白金储值 ￥1000", 1000, 350, "至尊白金卡", "PLATINUM", "超值爆款"),
                            createCharge(6, "黑钻至尊储值 ￥3000", 3000, 1200, "黑钻至尊卡", "DIAMOND", "终身顶格")
                    )));
                    t.setPositionsJson(objectMapper.writeValueAsString(Arrays.asList(
                            createPost(1L, "店长/运营主管", "店务管理部", "STORE_MANAGER", "MANAGER", 6500, "￥6500-10000元/月", 0.08, "全面统筹日常店务、顾客服务质检与人员考勤考核", "具备美业沙龙3年以上管理经验"),
                            createPost(2L, "资深造型师/发型总监", "美业设计部", "TECHNICIAN", "TECHNICIAN", 6000, "￥6000-12000元/月", 0.30, "负责高端发型定制设计、潮流烫染交付与客户维系", "具备发型设计经验，擅长美感搭配"),
                            createPost(3L, "资深美业技师/设计师", "美业设计部", "TECHNICIAN", "TECHNICIAN", 5000, "￥5000-9000元/月", 0.25, "负责顾客剪发造型、专业洗护与方案推荐", "具备专业服务技巧与沟通能力"),
                            createPost(4L, "头部养护/洗护技师", "技术养护部", "TECHNICIAN", "TECHNICIAN", 4500, "￥4500-7000元/月", 0.20, "负责专业头皮检测、草本精油熏蒸与舒缓洗发", "学习意愿强，服务意识好"),
                            createPost(5L, "前台收银主管", "前台客服部", "CASHIER", "CASHIER", 4500, "￥4500-6500元/月", 0.05, "负责到店顾客接待、系统开卡收银与电话回访", "服务意识强，掌握收银软件操作")
                    )));
                    t.setCardTemplatesJson(objectMapper.writeValueAsString(Arrays.asList(
                            createCard(1, "STORED_VALUE", "储值卡", "丝艺金卡 ￥1000", 1000, 1000, "全店洗剪吹及烫染项目享8.8折优惠，生日当月赠深层水疗1次", 365, "gold", 0.88),
                            createCard(2, "TIME_CARD", "次卡", "头皮深度草本SPA 5次卡", 680, 900, "包含5次专业头皮毛囊净化及草本熏蒸SPA", 180, "purple", 0.75),
                            createCard(3, "DURATION_CARD", "期限卡", "丝艺白金洗吹年卡", 2880, 3600, "365天内无限次洗吹造型，烫染项目享8折特惠", 365, "black", 0.80)
                    )));
                    break;
            }
        } catch (Exception e) {
            log.error("构建默认行业预设JSON失败: {}", e.getMessage(), e);
        }

        return t;
    }

    private Map<String, Object> createCharge(int id, String title, int principal, int gift, String levelName, String levelCode, String badge) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", id);
        map.put("title", title);
        map.put("principal", principal);
        map.put("gift", gift);
        map.put("levelName", levelName);
        map.put("levelCode", levelCode);
        map.put("badge", badge);
        return map;
    }

    private Map<String, Object> createPost(Long id, String postName, String department, String postCode, String role,
                                          int baseSalary, String salaryRange, double commissionRate, String description, String requirements) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", id);
        map.put("postName", postName);
        map.put("department", department);
        map.put("postCode", postCode);
        map.put("role", role);
        map.put("baseSalary", baseSalary);
        map.put("salaryRange", salaryRange);
        map.put("commissionRate", commissionRate);
        map.put("description", description);
        map.put("requirements", requirements);
        map.put("isRecruiting", true);
        return map;
    }

    private Map<String, Object> createCard(int id, String cardType, String cardTypeName, String cardName,
                                          int price, int originalPrice, String contentDescription, int validityDays, String themeColor, double discountRate) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", id);
        map.put("cardType", cardType);
        map.put("cardTypeName", cardTypeName);
        map.put("cardName", cardName);
        map.put("price", price);
        map.put("originalPrice", originalPrice);
        map.put("contentDescription", contentDescription);
        map.put("validityDays", validityDays);
        map.put("themeColor", themeColor);
        map.put("discountRate", discountRate);
        map.put("status", "ACTIVE");
        return map;
    }
}
