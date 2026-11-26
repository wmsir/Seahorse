package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.dto.vendor.CreateStoreCommand;
import com.seahorse.store.application.service.MerchantRegisterAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.iam.model.Tenant;
import com.seahorse.store.domain.session.enums.SessionStatus;
import com.seahorse.store.domain.session.enums.SpaceStatus;
import com.seahorse.store.domain.session.enums.SpaceType;
import com.seahorse.store.domain.session.model.ServiceSession;
import com.seahorse.store.domain.session.model.ServiceSpace;
import com.seahorse.store.infrastructure.repository.ServiceSessionRepository;
import com.seahorse.store.infrastructure.repository.ServiceSpaceRepository;
import com.seahorse.store.infrastructure.repository.StoreRepository;
import com.seahorse.store.infrastructure.repository.TenantRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.seahorse.store.domain.iam.model.Employee;
import com.seahorse.store.infrastructure.repository.EmployeeRepository;
import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * 空间工位与多门店管理控制器
 */
@Slf4j
@Tag(name = "06. 空间与工位看板", description = "桌台/镜台/工位看板视图、状态复位与商户多门店管理")
@RestController
@RequestMapping("/api/space")
@RequiredArgsConstructor
public class StoreSpaceController {

    private final ServiceSpaceRepository spaceRepository;
    private final StoreRepository storeRepository;
    private final TenantRepository tenantRepository;
    private final MerchantRegisterAppService merchantRegisterAppService;
    private final ServiceSessionRepository sessionRepository;
    private final EmployeeRepository employeeRepository;
    private final ObjectMapper objectMapper;

    @Operation(summary = "获取当前门店所有空间包厢/工位列表 (带实时状态)")
    @GetMapping("/list")
    public ApiResponse<List<ServiceSpace>> getSpaces(@RequestParam(value = "storeId", required = false) String storeId) {
        String targetStoreId = (storeId != null && !storeId.trim().isEmpty()) ? storeId.trim() : TenantContext.getStoreId();
        String tenantId = TenantContext.getTenantId();

        if (targetStoreId != null && !targetStoreId.trim().isEmpty()) {
            Optional<Store> sOpt = storeRepository.findByStoreId(targetStoreId);
            if (sOpt.isPresent() && sOpt.get().getTenantId() != null) {
                if (TenantContext.isAuthenticated()) {
                    TenantContext.assertTenantAccess(sOpt.get().getTenantId());
                }
                tenantId = sOpt.get().getTenantId();
            }
            List<ServiceSpace> spaces = spaceRepository.findByStoreId(targetStoreId);
            if (!spaces.isEmpty()) {
                if (TenantContext.isAuthenticated() && !TenantContext.isPlatformAdmin()) {
                    String currentTenant = TenantContext.getTenantId();
                    spaces = spaces.stream()
                            .filter(sp -> sp.getTenantId() == null || currentTenant.equalsIgnoreCase(sp.getTenantId()))
                            .toList();
                }
                return ApiResponse.success(spaces);
            }
            return ApiResponse.success(spaceRepository.findByTenantIdAndStoreId(tenantId, targetStoreId));
        }

        if (tenantId == null || tenantId.trim().isEmpty()) {
            tenantId = "T001";
        }
        TenantContext.assertTenantAccess(tenantId);
        return ApiResponse.success(spaceRepository.findByTenantId(tenantId));
    }

    @Operation(summary = "创建或更新包厢/台位/工位")
    @PostMapping("/save")
    public ApiResponse<ServiceSpace> saveSpace(@RequestBody ServiceSpace space) {
        TenantContext.assertTenantAdmin();
        if (space.getId() != null) {
            spaceRepository.findById(space.getId())
                    .ifPresent(existing -> TenantContext.assertTenantAccess(existing.getTenantId()));
        }
        String tid = TenantContext.getTenantId();
        if (!TenantContext.isPlatformAdmin() || space.getTenantId() == null || space.getTenantId().trim().isEmpty()) {
            space.setTenantId(tid != null && !tid.trim().isEmpty() ? tid : "T001");
        }
        if (space.getStoreId() == null || space.getStoreId().trim().isEmpty()) {
            String sid = TenantContext.getStoreId();
            space.setStoreId(sid != null && !sid.trim().isEmpty() ? sid : "S001");
        } else {
            storeRepository.findByStoreId(space.getStoreId().trim())
                    .ifPresent(st -> TenantContext.assertTenantAccess(st.getTenantId()));
        }
        if (space.getSpaceCode() == null || space.getSpaceCode().trim().isEmpty()) {
            space.setSpaceCode("R" + (System.currentTimeMillis() % 1000));
        }
        if (space.getSpaceName() == null || space.getSpaceName().trim().isEmpty()) {
            space.setSpaceName(space.getSpaceCode());
        }
        if (space.getSpaceType() == null) {
            space.setSpaceType(SpaceType.ROOM);
        }
        if (space.getStatus() == null) {
            space.setStatus(SpaceStatus.IDLE);
        }
        if (space.getCapacity() == null || space.getCapacity() <= 0) {
            space.setCapacity(4);
        }
        return ApiResponse.success(spaceRepository.save(space));
    }

    @Operation(summary = "批量创建包厢/台位")
    @PostMapping("/batch-create")
    public ApiResponse<List<ServiceSpace>> batchCreateSpaces(@RequestBody List<ServiceSpace> spaces) {
        TenantContext.assertTenantAdmin();
        String tenantId = TenantContext.getTenantId();
        String storeId = TenantContext.getStoreId();
        int idx = 1;
        for (ServiceSpace s : spaces) {
            if (!TenantContext.isPlatformAdmin() || s.getTenantId() == null || s.getTenantId().trim().isEmpty()) {
                s.setTenantId(tenantId != null && !tenantId.trim().isEmpty() ? tenantId : "T001");
            }
            if (s.getStoreId() == null || s.getStoreId().trim().isEmpty()) {
                s.setStoreId(storeId != null && !storeId.trim().isEmpty() ? storeId : "S001");
            } else {
                storeRepository.findByStoreId(s.getStoreId().trim())
                        .ifPresent(st -> TenantContext.assertTenantAccess(st.getTenantId()));
            }
            if (s.getSpaceCode() == null || s.getSpaceCode().trim().isEmpty()) {
                s.setSpaceCode(String.format("R%02d", idx++));
            }
            if (s.getSpaceName() == null || s.getSpaceName().trim().isEmpty()) {
                s.setSpaceName(s.getSpaceCode());
            }
            if (s.getSpaceType() == null) {
                s.setSpaceType(SpaceType.ROOM);
            }
            if (s.getStatus() == null) {
                s.setStatus(SpaceStatus.IDLE);
            }
            if (s.getCapacity() == null || s.getCapacity() <= 0) {
                s.setCapacity(4);
            }
        }
        return ApiResponse.success("批量创建成功", spaceRepository.saveAll(spaces));
    }

    @Operation(summary = "删除指定包厢/台位 (防误删拦截服务中)")
    @DeleteMapping("/{id}")
    public ApiResponse<String> deleteSpace(@PathVariable("id") Long id) {
        ServiceSpace space = spaceRepository.findById(id)
                .orElseThrow(() -> new ServiceException("包厢/空间不存在"));
        TenantContext.assertTenantAccess(space.getTenantId());
        if (space.getStatus() == SpaceStatus.OCCUPIED) {
            throw new ServiceException("该包厢当前正处于在场服务中，请先买单结算或转台后再删除！");
        }
        spaceRepository.deleteById(id);
        return ApiResponse.success("删除成功", "OK");
    }

    @Operation(summary = "快速切换包厢/台位状态 (如置为维修停用或恢复空闲)")
    @PostMapping("/{id}/status")
    public ApiResponse<ServiceSpace> updateStatus(@PathVariable("id") Long id, @RequestParam("status") SpaceStatus status) {
        ServiceSpace space = spaceRepository.findById(id)
                .orElseThrow(() -> new ServiceException("包厢/空间不存在"));
        TenantContext.assertTenantAccess(space.getTenantId());
        if (space.getStatus() == SpaceStatus.OCCUPIED && status != SpaceStatus.OCCUPIED) {
            throw new ServiceException("该包厢当前有顾客在场服务中，不可直接强制修改状态！");
        }
        space.setStatus(status);
        return ApiResponse.success("状态更新成功", spaceRepository.save(space));
    }

    @Operation(summary = "翻台/清台复位 (将已买单待清理 DIRTY 空间重置为 IDLE 空闲并结束在场服务会话)")
    @PostMapping("/{id}/reset")
    public ApiResponse<String> resetSpace(@PathVariable("id") Long id) {
        ServiceSpace space = spaceRepository.findById(id)
                .orElseThrow(() -> new ServiceException("包厢/空间不存在"));
        TenantContext.assertTenantAccess(space.getTenantId());
        space.releaseToIdle();
        spaceRepository.save(space);

        // 关闭该空间下所有未完成的会话，彻底清除活跃列表中的占位记录
        List<SessionStatus> activeStatuses = Arrays.asList(
                SessionStatus.OCCUPIED_ORDERING, SessionStatus.SERVING, SessionStatus.SETTLING, SessionStatus.SETTLED_WAIT_CLEAN);
        List<ServiceSession> activeSessions = sessionRepository.findBySpaceIdAndStatusIn(id, activeStatuses);
        for (ServiceSession s : activeSessions) {
            s.setStatus(SessionStatus.CLOSED);
            s.setEndTime(LocalDateTime.now());
            sessionRepository.save(s);
        }

        return ApiResponse.success("复位成功", "OK");
    }

    @Operation(summary = "获取当前商户旗下所有门店列表")
    @GetMapping("/stores")
    public ApiResponse<List<Store>> getTenantStores() {
        String tenantId = TenantContext.getTenantId();
        if (TenantContext.isPlatformAdmin() && ("PLATFORM".equalsIgnoreCase(tenantId) || "ALL".equalsIgnoreCase(tenantId))) {
            return ApiResponse.success(storeRepository.findAll());
        }
        List<Store> list = storeRepository.findByTenantId(tenantId);
        if (list.isEmpty()) {
            String storeId = TenantContext.getStoreId();
            if (storeId != null && !storeId.trim().isEmpty()) {
                storeRepository.findByStoreId(storeId.trim()).ifPresent(s -> {
                    TenantContext.assertTenantAccess(s.getTenantId());
                    list.add(s);
                });
            }
        }
        return ApiResponse.success(list);
    }

    @Operation(summary = "商户在套餐额度内新增门店 (跨行业模态支持)")
    @PostMapping("/store/create")
    public ApiResponse<Store> createStore(@RequestBody CreateStoreCommand cmd) {
        TenantContext.assertTenantAdmin();
        Store store = merchantRegisterAppService.createStore(TenantContext.getTenantId(), cmd);
        return ApiResponse.success("新增门店成功", store);
    }

    @Operation(summary = "商户修改/编辑分店资料与运营参数")
    @PostMapping("/store/update")
    public ApiResponse<Store> updateStore(@RequestBody CreateStoreCommand cmd) {
        TenantContext.assertTenantAdmin();
        String tenantId = TenantContext.getTenantId();
        if (cmd.getStoreId() == null || cmd.getStoreId().trim().isEmpty()) {
            throw new ServiceException("分店ID不可为空");
        }
        Store store = storeRepository.findByStoreIdAndTenantId(cmd.getStoreId().trim(), tenantId)
                .orElseThrow(() -> new ServiceException("未找到指定分店信息: " + cmd.getStoreId()));

        if (cmd.getStoreName() != null && !cmd.getStoreName().trim().isEmpty()) {
            store.setStoreName(cmd.getStoreName().trim());
        }
        if (cmd.getIndustry() != null) {
            store.setIndustry(cmd.getIndustry());
        }
        if (cmd.getIndustryCategoryId() != null) {
            store.setIndustryCategoryId(cmd.getIndustryCategoryId());
        }
        if (cmd.getIndustryCategoryName() != null && !cmd.getIndustryCategoryName().trim().isEmpty()) {
            store.setIndustryCategoryName(cmd.getIndustryCategoryName().trim());
        }
        if (cmd.getIndustryCategoryGroup() != null && !cmd.getIndustryCategoryGroup().trim().isEmpty()) {
            store.setIndustryCategoryGroup(cmd.getIndustryCategoryGroup().trim());
        }
        if (cmd.getAddress() != null) {
            store.setAddress(cmd.getAddress().trim());
        }
        if (cmd.getPhone() != null) {
            store.setPhone(cmd.getPhone().trim());
        }
        if (cmd.getBusinessHours() != null) {
            store.setBusinessHours(cmd.getBusinessHours().trim());
        }
        if (cmd.getStatus() != null && !cmd.getStatus().trim().isEmpty()) {
            store.setStatus(cmd.getStatus().trim());
        }
        if (cmd.getFeeName() != null) {
            store.setFeeName(cmd.getFeeName());
        }
        if (cmd.getDefaultFeeAmount() != null) {
            store.setDefaultFeeAmount(cmd.getDefaultFeeAmount());
        }
        if (cmd.getFeeEnabled() != null) {
            store.setFeeEnabled(cmd.getFeeEnabled());
        }
        return ApiResponse.success("分店资料更新成功", storeRepository.save(store));
    }

    @Operation(summary = "商户/店长保存与更新指定分店的组织架构与在招岗位")
    @PostMapping("/store/positions")
    public ApiResponse<String> saveStorePositions(
            @RequestParam("storeId") String storeId,
            @RequestBody Map<String, Object> body) {
        TenantContext.assertTenantAdmin();
        String sId = storeId != null ? storeId.trim() : "";
        if (sId.isEmpty()) {
            return ApiResponse.error(400, "门店ID不能为空");
        }
        Store store = storeRepository.findByStoreId(sId).orElse(null);
        if (store == null) {
            return ApiResponse.error(404, "未找到该门店信息");
        }
        TenantContext.assertTenantAccess(store.getTenantId());
        try {
            if (body.containsKey("positions")) {
                store.setCustomPositionsJson(objectMapper.writeValueAsString(body.get("positions")));
            }
            if (body.containsKey("departments")) {
                store.setCustomDepartmentsJson(objectMapper.writeValueAsString(body.get("departments")));
            }
            storeRepository.save(store);
            return ApiResponse.success("门店组织架构与招聘岗位保存成功", "OK");
        } catch (Exception e) {
            log.error("保存门店组织架构失败", e);
            return ApiResponse.error(500, "保存失败: " + e.getMessage());
        }
    }

    @Operation(summary = "公开查询门店详情与对应行业组织架构在招岗位(免登公开接口)")
    @GetMapping("/public/store-detail")
    public ApiResponse<Map<String, Object>> getPublicStoreDetail(@RequestParam("storeId") String storeId) {
        String sId = storeId != null ? storeId.trim() : "";
        if (sId.isEmpty()) {
            return ApiResponse.error(400, "门店ID不能为空");
        }
        Store store = storeRepository.findByStoreId(sId).orElse(null);
        if (store == null) {
            return ApiResponse.error(404, "未找到该门店信息");
        }

        Tenant tenant = tenantRepository.findByTenantId(store.getTenantId()).orElse(null);
        String manager = (tenant != null && tenant.getContactName() != null && !tenant.getContactName().trim().isEmpty())
                ? tenant.getContactName() : "门店店长";

        String ind = store.getIndustry() != null ? store.getIndustry().name() : "BEAUTY";

        List<String> departments = new ArrayList<>();
        List<Map<String, Object>> positions = new ArrayList<>();
        boolean hasCustom = false;

        // 1. 优先读取门店自定义配置的在招岗位与所属部门（支持独立配置）
        if (store.getCustomDepartmentsJson() != null && !store.getCustomDepartmentsJson().trim().isEmpty()) {
            try {
                List<String> customDepts = objectMapper.readValue(
                        store.getCustomDepartmentsJson(),
                        new TypeReference<List<String>>() {}
                );
                if (customDepts != null && !customDepts.isEmpty()) {
                    departments.addAll(customDepts);
                    hasCustom = true;
                }
            } catch (Exception e) {
                log.warn("解析门店自定义部门失败: {}", e.getMessage());
            }
        }

        if (store.getCustomPositionsJson() != null && !store.getCustomPositionsJson().trim().isEmpty()) {
            try {
                List<Map<String, Object>> customPos = objectMapper.readValue(
                        store.getCustomPositionsJson(),
                        new TypeReference<List<Map<String, Object>>>() {}
                );
                if (customPos != null && !customPos.isEmpty()) {
                    positions.addAll(customPos);
                    hasCustom = true;
                    // 若自定义部门列表为空，但岗位中包含部门，提取平滑补充
                    if (departments.isEmpty()) {
                        Set<String> deptSet = new LinkedHashSet<>();
                        for (Map<String, Object> p : positions) {
                            if (p.get("department") != null) {
                                deptSet.add(String.valueOf(p.get("department")));
                            }
                        }
                        departments.addAll(deptSet);
                    }
                }
            } catch (Exception e) {
                log.warn("解析门店自定义岗位失败: {}", e.getMessage());
            }
        }

        // 2. 若未自定义，且为系统演示租户或标准演示门店，生成演示标准岗位与部门；普通/新注册商户严格保持纯净空状态
        String tenantId = store.getTenantId();
        boolean isDemoTenant = "T001".equalsIgnoreCase(tenantId)
                || "PLATFORM".equalsIgnoreCase(tenantId)
                || Arrays.asList("T54035", "T43782", "T63102", "T50451").contains(tenantId)
                || sId.startsWith("S00")
                || sId.startsWith("S_");
        if (!hasCustom && isDemoTenant) {
            if ("FOOT_SPA".equalsIgnoreCase(ind)) {
                departments = Arrays.asList("店务管理部", "足道养生部", "SPA理疗部", "理疗推拿部", "前台客服部");
                positions.add(createPostMap(1L, "养生会所店长/主管", "店务管理部", "STORE_MANAGER", "MANAGER", 7000, "￥7000-12000元/月", "统筹日常店务运营、房态调度、技师考勤与客户满意度", "养生会所管理经验"));
                positions.add(createPostMap(2L, "资深足道养生技师", "足道养生部", "TECHNICIAN", "TECHNICIAN", 6500, "￥6500-11000元/月", "负责顾客足底反射疗法、古法修脚与足部养护项目交付", "手法熟练，有足道经验"));
                positions.add(createPostMap(3L, "首席SPA芳疗理疗师", "SPA理疗部", "TECHNICIAN", "TECHNICIAN", 6000, "￥6000-10000元/月", "负责全身精油SPA、淋巴排毒、肩颈舒缓与高端芳疗", "具备芳疗专业经验，手法温和"));
                positions.add(createPostMap(4L, "中医经络推拿师", "理疗推拿部", "TECHNICIAN", "TECHNICIAN", 5800, "￥5800-9500元/月", "负责经络穴位调理、背部拔罐刮痧与肌肉劳损松解", "持有中医推拿相关经验者优先"));
                positions.add(createPostMap(5L, "前台接待主管", "前台客服部", "CASHIER", "CASHIER", 4800, "￥4800-7000元/月", "负责到店迎宾领位、房态排钟分配、收银买单与会员储值", "形象端正，亲和力佳"));
            } else if ("RESTAURANT".equalsIgnoreCase(ind)) {
                departments = Arrays.asList("店务管理部", "前厅服务部", "后厨烹饪部", "品质保障部", "前台客服部");
                positions.add(createPostMap(1L, "餐厅店长/运营主管", "店务管理部", "STORE_MANAGER", "MANAGER", 7000, "￥7000-11000元/月", "全面统筹日常运营、现场调度与月度经营核算", "有餐饮管理经验"));
                positions.add(createPostMap(2L, "前厅领班/主管", "前厅服务部", "CASHIER", "CASHIER", 5200, "￥5200-7500元/月", "负责前厅迎宾领位、翻台调度与客户满意度", "沟通亲和力强"));
                positions.add(createPostMap(3L, "招牌烹饪/烧烤主厨", "后厨烹饪部", "TECHNICIAN", "TECHNICIAN", 6800, "￥6800-9500元/月", "负责后厨菜品出品、烧烤火候掌控与菜品品控", "具备专业烹饪厨艺"));
                positions.add(createPostMap(4L, "前台迎宾/收银员", "前台客服部", "CASHIER", "CASHIER", 4500, "￥4500-6000元/月", "负责到店接待、系统收银开单与发票开具", "细致认真"));
                positions.add(createPostMap(5L, "后厨切配/打荷员", "后厨烹饪部", "TECHNICIAN", "TECHNICIAN", 4800, "￥4800-6500元/月", "负责食材初加工、串签备料与工位卫生", "吃苦耐劳"));
            } else if ("AUTO".equalsIgnoreCase(ind)) {
                departments = Arrays.asList("店务管理部", "技术养护部", "车间维修部", "前台客服部");
                positions.add(createPostMap(1L, "汽修总监/店长", "店务管理部", "STORE_MANAGER", "MANAGER", 8000, "￥8000-12000元/月", "全面统筹车间接车诊断与维修施工品控", "汽修管理经验"));
                positions.add(createPostMap(2L, "资深机电快修技师", "技术养护部", "TECHNICIAN", "TECHNICIAN", 6000, "￥6000-9000元/月", "负责车辆机电快修、全车保养与故障排除", "有汽车维修经验"));
                positions.add(createPostMap(3L, "汽车美容养护技师", "技术养护部", "TECHNICIAN", "TECHNICIAN", 5000, "￥5000-7500元/月", "负责精细洗车、镀晶打蜡与漆面微修修复", "爱护车辆，细致周到"));
                positions.add(createPostMap(4L, "首席服务顾问(SA)", "前台客服部", "CASHIER", "CASHIER", 5500, "￥5500-8500元/月", "负责进店车辆接车问询与结算开单", "沟通表达流畅"));
            } else if ("RETAIL".equalsIgnoreCase(ind)) {
                departments = Arrays.asList("店务管理部", "门店服务部", "仓储配货部", "前台收银部");
                positions.add(createPostMap(1L, "运营总监/店长", "店务管理部", "STORE_MANAGER", "MANAGER", 7500, "￥7500-11000元/月", "统筹门店销售业绩、商品陈列与人员督导", "零售店长经验"));
                positions.add(createPostMap(2L, "资深导购/销售顾问", "门店服务部", "CASHIER", "CASHIER", 4500, "￥4500-7000元/月", "负责客户导购选品、收银开单与会员纳新", "亲和力好"));
                positions.add(createPostMap(3L, "仓储质检盘点员", "仓储配货部", "TECHNICIAN", "TECHNICIAN", 4800, "￥4800-6500元/月", "负责商品入库核验、条码打印与库存盘点", "细致严谨"));
                positions.add(createPostMap(4L, "前台收银结算员", "前台收银部", "CASHIER", "CASHIER", 4500, "￥4500-6000元/月", "负责商品扫码结算、开卡储值与对账交接", "细致认真"));
            } else if ("TEA_HOUSE".equalsIgnoreCase(ind)) {
                departments = Arrays.asList("店务管理部", "茶艺服务部", "前厅接待部", "前台客服部");
                positions.add(createPostMap(1L, "茶楼掌柜/店长", "店务管理部", "STORE_MANAGER", "MANAGER", 6500, "￥6500-10000元/月", "统筹茶室日常营运、茶礼接待与雅间环境调度", "茶室经营经验"));
                positions.add(createPostMap(2L, "资深茶艺师/侍茶师", "茶艺服务部", "TECHNICIAN", "TECHNICIAN", 5500, "￥5500-8500元/月", "负责名优茶冲泡品饮演示、茶道文化讲解与茶礼服务", "持有茶艺师资格或经验"));
                positions.add(createPostMap(3L, "雅间管家/茶礼服务员", "前厅接待部", "TECHNICIAN", "TECHNICIAN", 4800, "￥4800-7000元/月", "负责茶室雅座包厢布景备茶、续水与茶点呈递", "举止端庄，礼貌周到"));
                positions.add(createPostMap(4L, "前台收银员", "前台客服部", "CASHIER", "CASHIER", 4500, "￥4500-6000元/月", "负责到店接待、茶室消费开单与收银结算", "细致认真"));
            } else if ("PET".equalsIgnoreCase(ind)) {
                departments = Arrays.asList("店务管理部", "宠物美容部", "洗护服务部", "前台客服部");
                positions.add(createPostMap(1L, "宠物生活馆店长", "店务管理部", "STORE_MANAGER", "MANAGER", 6500, "￥6500-10000元/月", "全面统筹门店日常经营、洗美工位排班与宠物安全品控", "具备宠物门店管理经验"));
                positions.add(createPostMap(2L, "资深宠物美容造型师", "宠物美容部", "TECHNICIAN", "TECHNICIAN", 6000, "￥6000-10000元/月", "负责爱宠洗护吹干、全身创意修剪与染色造型设计", "具备专业宠物美容经验"));
                positions.add(createPostMap(3L, "宠物洗护精细技师", "洗护服务部", "TECHNICIAN", "TECHNICIAN", 4800, "￥4800-7500元/月", "负责爱宠药浴浸泡、耳道清洁、挤肛门腺与基础护理", "喜爱小动物，耐心细致"));
                positions.add(createPostMap(4L, "门店接待/收银主管", "前台客服部", "CASHIER", "CASHIER", 4500, "￥4500-6500元/月", "负责接宠登记、健康情况问询、商品导购与收银结算", "亲和力强，喜爱宠物"));
            } else {
                // 默认 BEAUTY (品质美业/美发/美甲美睫/生活美容)
                departments = Arrays.asList("店务管理部", "美业设计部", "前台客服部", "技术养护部", "门店服务部");
                positions.add(createPostMap(1L, "店长/运营主管", "店务管理部", "STORE_MANAGER", "MANAGER", 6500, "￥6500-10000元/月", "全面统筹日常店务、顾客服务质检与人员考勤考核", "美业管理经验"));
                positions.add(createPostMap(2L, "资深造型师/发型总监", "美业设计部", "TECHNICIAN", "TECHNICIAN", 6000, "￥6000-12000元/月", "负责高端发型定制设计、潮流烫染交付与客户维系", "具备发型设计经验"));
                positions.add(createPostMap(3L, "资深美业技师/设计师", "美业设计部", "TECHNICIAN", "TECHNICIAN", 5000, "￥5000-9000元/月", "负责顾客剪发造型、专业洗护与方案推荐", "具备专业服务技巧"));
                positions.add(createPostMap(4L, "头部养护/洗护技师", "技术养护部", "TECHNICIAN", "TECHNICIAN", 4500, "￥4500-7000元/月", "负责专业头皮检测、草本精油熏蒸与舒缓洗发", "学习意愿强，服务意识好"));
                positions.add(createPostMap(5L, "前台收银主管", "前台客服部", "CASHIER", "CASHIER", 4500, "￥4500-6500元/月", "负责到店顾客接待、系统开卡收银与电话回访", "服务意识强"));
            }

            // 3. 动态融合当前门店在册现有员工岗位 (若有新设岗位名，平滑融入当前店铺体系)
            try {
                List<Employee> existingStaff = employeeRepository.findByStoreIdAndIsDeleted(sId, false);
                if (existingStaff != null && !existingStaff.isEmpty()) {
                    long maxId = positions.size() + 1;
                    Set<String> existingNames = new HashSet<>();
                    for (Map<String, Object> p : positions) {
                        existingNames.add(String.valueOf(p.get("postName")));
                    }
                    for (Employee emp : existingStaff) {
                        if (emp.getPostName() != null && !emp.getPostName().trim().isEmpty() && !existingNames.contains(emp.getPostName())) {
                            String roleStr = emp.getRole() != null ? emp.getRole().name() : "TECHNICIAN";
                            String preset = "STORE_MANAGER".equals(roleStr) ? "MANAGER" : ("CASHIER".equals(roleStr) ? "CASHIER" : "TECHNICIAN");
                            String dept = "STORE_MANAGER".equals(roleStr) ? "店务管理部" : ("CASHIER".equals(roleStr) ? "前台客服部" : "美业设计部");
                            positions.add(createPostMap(maxId++, emp.getPostName(), dept, roleStr, preset,
                                    emp.getBaseSalary() != null ? emp.getBaseSalary().intValue() : 5000,
                                    "￥5000-8500元/月", "负责本店" + emp.getPostName() + "相关业务协同交付", "具备相应实操服务经验"));
                            existingNames.add(emp.getPostName());
                        }
                    }
                }
            } catch (Exception e) {
                log.warn("检查门店现有员工岗位失败: {}", e.getMessage());
            }
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("storeId", store.getStoreId());
        data.put("tenantId", store.getTenantId());
        data.put("storeName", store.getStoreName());
        data.put("industry", ind);
        data.put("industryCategoryName", store.getIndustryCategoryName() != null ? store.getIndustryCategoryName() : (store.getIndustry() != null ? store.getIndustry().getDescription() : ""));
        data.put("address", store.getAddress() != null ? store.getAddress() : "门店现场");
        data.put("phone", store.getPhone() != null ? store.getPhone() : (tenant != null ? tenant.getContactPhone() : ""));
        data.put("businessHours", store.getBusinessHours() != null ? store.getBusinessHours() : "09:00 - 22:00");
        data.put("managerName", manager);
        data.put("isHeadquarter", "S001".equalsIgnoreCase(store.getStoreId())
                || (store.getStoreName() != null && store.getStoreName().contains("总店")));
        data.put("hasCustom", hasCustom);
        data.put("departments", departments);
        data.put("positions", positions);

        return ApiResponse.success(data);
    }

    private Map<String, Object> createPostMap(Long id, String postName, String department, String role, String preset,
                                              int baseSalary, String salaryRange, String description, String requirements) {
        Map<String, Object> p = new LinkedHashMap<>();
        p.put("id", id);
        p.put("postName", postName);
        p.put("department", department);
        p.put("role", role);
        p.put("preset", preset);
        p.put("baseSalary", baseSalary);
        p.put("salaryRange", salaryRange);
        p.put("description", description);
        p.put("requirements", requirements);
        p.put("isRecruiting", true);
        return p;
    }

    // =========================================================================
    // 🛎️ 包厢扫码呼叫管家/服务事件与实时通知
    // =========================================================================

    @Data
    public static class CallServiceRequest {
        private Long spaceId;
        private String spaceCode;
        private String spaceName;
        private String serviceType;
        private String notes;
        private String storeId;
        private String tenantId;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ServiceCallEvent {
        private String id;
        private Long spaceId;
        private String spaceCode;
        private String spaceName;
        private String serviceType;
        private String notes;
        private String storeId;
        private String tenantId;
        private String createTime;
        private String status; // PENDING, HANDLED
    }

    private static final List<ServiceCallEvent> SERVICE_CALLS = new CopyOnWriteArrayList<>();

    @Operation(summary = "包厢扫码呼叫服务 (加茶水/换骨碟/催单/呼叫管家)")
    @PostMapping("/call-service")
    public ApiResponse<ServiceCallEvent> callService(@RequestBody CallServiceRequest req) {
        String tenantId = req.getTenantId() != null && !req.getTenantId().trim().isEmpty()
                ? req.getTenantId() : (TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001");
        String storeId = req.getStoreId() != null && !req.getStoreId().trim().isEmpty()
                ? req.getStoreId() : (TenantContext.getStoreId() != null ? TenantContext.getStoreId() : "S001");

        String id = "SC_" + System.currentTimeMillis() + "_" + (int)(Math.random() * 900 + 100);
        String nowStr = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").format(LocalDateTime.now());

        ServiceCallEvent event = ServiceCallEvent.builder()
                .id(id)
                .spaceId(req.getSpaceId())
                .spaceCode(req.getSpaceCode() != null ? req.getSpaceCode() : "A01")
                .spaceName(req.getSpaceName() != null ? req.getSpaceName() : "包厢")
                .serviceType(req.getServiceType() != null ? req.getServiceType() : "呼叫服务")
                .notes(req.getNotes())
                .storeId(storeId)
                .tenantId(tenantId)
                .createTime(nowStr)
                .status("PENDING")
                .build();

        SERVICE_CALLS.add(0, event);
        while (SERVICE_CALLS.size() > 200) {
            try {
                SERVICE_CALLS.remove(SERVICE_CALLS.size() - 1);
            } catch (IndexOutOfBoundsException ignored) {
                break;
            }
        }

        log.info("【包厢呼叫服务】收到新呼叫: 门店={}, 包厢={} ({}), 呼叫项目={}",
                storeId, event.getSpaceName(), event.getSpaceCode(), event.getServiceType());

        return ApiResponse.success("呼叫成功，服务管家稍后即到", event);
    }

    @Operation(summary = "查询门店呼叫服务通知列表")
    @GetMapping("/service-calls")
    public ApiResponse<List<ServiceCallEvent>> getServiceCalls(
            @RequestParam(value = "storeId", required = false) String storeId,
            @RequestParam(value = "status", required = false, defaultValue = "PENDING") String status,
            @RequestParam(value = "limit", required = false, defaultValue = "30") Integer limit) {

        String effStoreId = storeId != null && !storeId.trim().isEmpty() ? storeId.trim() : TenantContext.getStoreId();
        if (effStoreId != null && !"PLATFORM".equalsIgnoreCase(effStoreId)) {
            storeRepository.findByStoreId(effStoreId).ifPresent(s -> TenantContext.assertTenantAccess(s.getTenantId()));
        }
        String currentTenant = TenantContext.getTenantId();
        List<ServiceCallEvent> list = new ArrayList<>();
        int count = 0;
        for (ServiceCallEvent sc : SERVICE_CALLS) {
            if (!TenantContext.isPlatformAdmin() && sc.getTenantId() != null && !currentTenant.equalsIgnoreCase(sc.getTenantId())) {
                continue;
            }
            if (effStoreId != null && !"PLATFORM".equalsIgnoreCase(effStoreId)
                    && sc.getStoreId() != null && !sc.getStoreId().equalsIgnoreCase(effStoreId)) {
                continue;
            }
            if (!"ALL".equalsIgnoreCase(status) && !status.equalsIgnoreCase(sc.getStatus())) {
                continue;
            }
            list.add(sc);
            count++;
            if (count >= limit) break;
        }
        return ApiResponse.success(list);
    }

    @Operation(summary = "处理/标记呼叫服务通知")
    @PostMapping("/service-calls/{id}/handle")
    public ApiResponse<String> handleServiceCall(@PathVariable("id") String id) {
        for (ServiceCallEvent sc : SERVICE_CALLS) {
            if (sc.getId().equals(id)) {
                TenantContext.assertTenantAccess(sc.getTenantId());
                sc.setStatus("HANDLED");
                break;
            }
        }
        return ApiResponse.success("已处理呼叫", "OK");
    }

    // =========================================================================
    // 🍲 包厢/桌台新点单（菜品、服务、商品）事件广播与语音报单
    // =========================================================================

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OrderNotificationEvent {
        private String id;
        private Long spaceId;
        private String spaceCode;
        private String spaceName;
        private String storeId;
        private String tenantId;
        private Integer itemsCount;
        private BigDecimal totalAmount;
        private List<String> itemNames;
        private String itemNamesSummary; // e.g. "龙井虾仁、清蒸桂鱼"
        private String broadcastText;    // e.g. "请注意，A01 烟波致爽包厢新下单：龙井虾仁、清蒸桂鱼，共2项，请及时服务出餐！"
        private String createTime;
        private String status; // PENDING, HANDLED
    }

    private static final List<OrderNotificationEvent> ORDER_NOTIFICATIONS = new CopyOnWriteArrayList<>();

    public static void publishOrderNotification(OrderNotificationEvent event) {
        if (event == null) return;
        ORDER_NOTIFICATIONS.add(0, event);
        while (ORDER_NOTIFICATIONS.size() > 200) {
            try {
                ORDER_NOTIFICATIONS.remove(ORDER_NOTIFICATIONS.size() - 1);
            } catch (IndexOutOfBoundsException ignored) {
                break;
            }
        }
        log.info("【新订单报单广播】门店={}, 空间={}, 播报文本={}",
                event.getStoreId(), event.getSpaceName(), event.getBroadcastText());
    }

    @Operation(summary = "发布新订单语音报单通知")
    @PostMapping("/order-notify")
    public ApiResponse<OrderNotificationEvent> postOrderNotification(@RequestBody OrderNotificationEvent req) {
        String tenantId = req.getTenantId() != null && !req.getTenantId().trim().isEmpty()
                ? req.getTenantId() : (TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001");
        String storeId = req.getStoreId() != null && !req.getStoreId().trim().isEmpty()
                ? req.getStoreId() : (TenantContext.getStoreId() != null ? TenantContext.getStoreId() : "S001");

        String id = "ORD_" + System.currentTimeMillis() + "_" + (int)(Math.random() * 900 + 100);
        String nowStr = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").format(LocalDateTime.now());

        req.setId(id);
        req.setStoreId(storeId);
        req.setTenantId(tenantId);
        req.setCreateTime(nowStr);
        req.setStatus("PENDING");

        if (req.getBroadcastText() == null || req.getBroadcastText().trim().isEmpty()) {
            String spaceDesc = (req.getSpaceName() != null ? req.getSpaceName() : "包厢")
                    + (req.getSpaceCode() != null ? " (" + req.getSpaceCode() + ")" : "");
            String summary = req.getItemNamesSummary() != null && !req.getItemNamesSummary().isEmpty()
                    ? req.getItemNamesSummary() : "点餐品项";
            int count = req.getItemsCount() != null ? req.getItemsCount() : 1;
            req.setBroadcastText(String.format("请注意，%s新下单：%s，共%d项，请及时服务出餐！", spaceDesc, summary, count));
        }

        publishOrderNotification(req);
        return ApiResponse.success("订单播报已发布", req);
    }

    @Operation(summary = "查询门店新订单播报通知列表")
    @GetMapping("/order-notifications")
    public ApiResponse<List<OrderNotificationEvent>> getOrderNotifications(
            @RequestParam(value = "storeId", required = false) String storeId,
            @RequestParam(value = "status", required = false, defaultValue = "PENDING") String status,
            @RequestParam(value = "limit", required = false, defaultValue = "30") Integer limit) {

        String effStoreId = storeId != null && !storeId.trim().isEmpty() ? storeId.trim() : TenantContext.getStoreId();
        if (effStoreId != null && !"PLATFORM".equalsIgnoreCase(effStoreId)) {
            storeRepository.findByStoreId(effStoreId).ifPresent(s -> TenantContext.assertTenantAccess(s.getTenantId()));
        }
        String currentTenant = TenantContext.getTenantId();
        List<OrderNotificationEvent> list = new ArrayList<>();
        int count = 0;
        for (OrderNotificationEvent on : ORDER_NOTIFICATIONS) {
            if (!TenantContext.isPlatformAdmin() && on.getTenantId() != null && !currentTenant.equalsIgnoreCase(on.getTenantId())) {
                continue;
            }
            if (effStoreId != null && !"PLATFORM".equalsIgnoreCase(effStoreId)
                    && on.getStoreId() != null && !on.getStoreId().equalsIgnoreCase(effStoreId)) {
                continue;
            }
            if (!"ALL".equalsIgnoreCase(status) && !status.equalsIgnoreCase(on.getStatus())) {
                continue;
            }
            list.add(on);
            count++;
            if (count >= limit) break;
        }
        return ApiResponse.success(list);
    }

    @Operation(summary = "处理/标记新订单播报通知为已接单/已出餐")
    @PostMapping("/order-notifications/{id}/handle")
    public ApiResponse<String> handleOrderNotification(@PathVariable("id") String id) {
        for (OrderNotificationEvent on : ORDER_NOTIFICATIONS) {
            if (on.getId().equals(id)) {
                TenantContext.assertTenantAccess(on.getTenantId());
                on.setStatus("HANDLED");
                break;
            }
        }
        return ApiResponse.success("已受理该订单", "OK");
    }
}

