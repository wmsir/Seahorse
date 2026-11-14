package com.seahorse.store.application.service;

import com.seahorse.store.application.dto.iam.UpdateRolePermissionCommand;
import com.seahorse.store.domain.iam.enums.EmployeeRole;
import com.seahorse.store.domain.iam.model.RolePermissionConfig;
import com.seahorse.store.infrastructure.repository.RolePermissionConfigRepository;
import com.seahorse.store.interfaces.web.vo.PermissionItemVO;
import com.seahorse.store.interfaces.web.vo.RolePermissionVO;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 角色权限管理应用服务
 * 支持：
 * 1. 平台开发维护人全局角色权限配置与下发；
 * 2. 门店老板为本店店员定制查看配置与操作权限；
 * 3. 登录与请求时的生效权限计算。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PermissionManageAppService {

    public static final String PLATFORM_TENANT_ID = "PLATFORM";

    private final RolePermissionConfigRepository rolePermissionConfigRepository;

    /**
     * 系统全部可选权限项元数据字典
     */
    public List<PermissionItemVO> getAllPermissionMetadata() {
        List<PermissionItemVO> list = new ArrayList<>();

        // 1. 平台开发商专属
        list.add(new PermissionItemVO("vendor:stats_view", "查看平台注册商户与全系统会员统计", "开发商平台大屏", "查看全平台注册商户数、累计会员数及平台总营收"));
        list.add(new PermissionItemVO("vendor:subscription_view", "查看商户购买服务时长与到期监控", "开发商平台大屏", "查看各商户购买的SaaS版本、订阅服务时长（月）、到期日及交费流水"));
        list.add(new PermissionItemVO("vendor:plan_config", "配置SaaS套餐定价与全局试用期", "开发商平台大屏", "动态调整各版本年费、店铺配额、存储空间与新商户默认试用天数"));
        list.add(new PermissionItemVO("vendor:global_perm_config", "配置全局角色查看权限字典", "开发商平台大屏", "作为开发维护人统一配置各角色默认允许查看的功能与指定信息"));

        // 2. 门店经营与老板专属
        list.add(new PermissionItemVO("merchant:dashboard_view", "查看智慧经营大屏与营收分析", "门店经营管控", "查看本店当日实收金额、客单价、经营趋势与时段客流"));
        list.add(new PermissionItemVO("merchant:store_manage", "开设新分店与切换行业模态策略", "门店经营管控", "创建多业态新门店，配置服务费与双轨扣减策略"));
        list.add(new PermissionItemVO("merchant:staff_perm_manage", "配置店员查看权限与权限矩阵", "门店经营管控", "门店老板专属：配置店长、收银员、技师的查看范围与操作权限"));

        // 3. 工位在场与收银结算
        list.add(new PermissionItemVO("session:view", "查看工位/桌台在场状态看板", "前台与收银", "实时查看美业镜台、餐饮散台、汽修工位的占用与点单情况"));
        list.add(new PermissionItemVO("session:operate", "工位开单/加单/技师分摊", "前台与收银", "发起在场消费工单，指派执行技师与提成比例"));
        list.add(new PermissionItemVO("cashier:checkout", "执行组合收银买单与折扣结算", "前台与收银", "支持双轨储值扣减、微信扫码与现金找零结算"));

        // 4. 会员与海马体记忆中心
        list.add(new PermissionItemVO("member:list_view", "查看门店会员列表与基础画像", "海马会员中心", "检索会员姓名、等级、到店频次与累计消费"));
        list.add(new PermissionItemVO("member:phone_view", "查看会员完整手机号", "海马会员中心", "查看未脱敏的会员真实手机号联系方式"));
        list.add(new PermissionItemVO("member:recharge", "会员双轨储值充值与发放次卡", "海马会员中心", "办理会员本金/赠金储值及次卡权益发放"));
        list.add(new PermissionItemVO("member:pref_view", "查看会员“海马体”记忆档案", "海马会员中心", "查看会员发质、口味忌口、爱车档案与服务习惯标签"));
        list.add(new PermissionItemVO("member:pref_edit", "录入/更新会员“海马体”记忆档案", "海马会员中心", "技师或店员为常客新增或更新个性化喜好备忘"));

        // 5. 顾客会员自助中心
        list.add(new PermissionItemVO("member:self_profile_view", "会员查看自己个人资料", "会员自主中心", "查看个人会员卡号、等级、试用期剩余天数"));
        list.add(new PermissionItemVO("member:self_profile_edit", "会员修改自己个人资料", "会员自主中心", "会员自主修改自己的姓名、性别、生日与联系方式"));
        list.add(new PermissionItemVO("member:self_pref_manage", "会员自主维护海马偏好画像", "会员自主中心", "会员自主添加和修改自己的发型偏好、餐饮忌口、爱车车辆档案"));
        list.add(new PermissionItemVO("member:self_asset_view", "会员查看个人资产与账单", "会员自主中心", "查看储值本金余额、赠金余额、次卡剩余次数与消费记录"));

        // 6. 规章制度与员工协同 (全员公开查阅、电子签字、心声建议)
        list.add(new PermissionItemVO("regulation:view", "查看规章制度与公开意见箱", "规章协同", "查阅全店规章制度、浏览全员公开心声建言与管理方官方答复公示"));
        list.add(new PermissionItemVO("regulation:sign", "手写电子签名防抵赖确认", "规章协同", "在线手写电子签字确认规章制度条款，生成防伪哈希证据链"));
        list.add(new PermissionItemVO("regulation:feedback", "提交合理化建议与诉求", "规章协同", "全员均可实名或完全匿名向管理方提交合理化建议、困难求助或创新提案"));
        list.add(new PermissionItemVO("regulation:manage", "发布规章与答复采纳建议", "规章协同", "店长/老板专属：发布修订规章、一键导出宣导海报与红头公文/PDF、官方答复并落地员工建议"));

        return list;
    }

    /**
     * 初始化全局默认角色权限配置
     */
    @PostConstruct
    @Transactional(rollbackFor = Exception.class)
    public void initDefaultPermissions() {
        if (rolePermissionConfigRepository.count() > 0) {
            log.info("角色权限配置表已就绪，跳过初始化。");
            return;
        }

        log.info("【海马智慧门店】初始化全局角色权限配置模板...");

        // 1. 系统开发维护人 (PLATFORM_DEVELOPER) - 专注全平台数据监控与定价配置，不强加门店业务
        RolePermissionConfig devConfig = RolePermissionConfig.builder()
                .tenantId(PLATFORM_TENANT_ID)
                .roleCode(EmployeeRole.PLATFORM_DEVELOPER)
                .roleName("系统开发维护人/平台运营")
                .permissions(String.join(",", Arrays.asList(
                        "vendor:stats_view", "vendor:subscription_view", "vendor:plan_config", "vendor:global_perm_config"
                )))
                .description("平台开发运营角色，监控全平台会员量与服务时长，配置SaaS定价与全局权限")
                .build();

        // 2. 门店老板/企业主 (SUPER_ADMIN) - 拥有本店全量经营权限及店员权限配置权
        RolePermissionConfig bossConfig = RolePermissionConfig.builder()
                .tenantId(PLATFORM_TENANT_ID)
                .roleCode(EmployeeRole.SUPER_ADMIN)
                .roleName("商户企业主/门店老板")
                .permissions(String.join(",", Arrays.asList(
                        "merchant:dashboard_view", "merchant:store_manage", "merchant:staff_perm_manage",
                        "session:view", "session:operate", "cashier:checkout",
                        "member:list_view", "member:phone_view", "member:recharge", "member:pref_view", "member:pref_edit",
                        "regulation:view", "regulation:sign", "regulation:feedback", "regulation:manage"
                )))
                .description("商户老板拥有本店最高运营权，并可自由配置店员的权限与查看范围")
                .build();

        // 3. 店长 (STORE_MANAGER) - 默认开通经营与开单收银
        RolePermissionConfig managerConfig = RolePermissionConfig.builder()
                .tenantId(PLATFORM_TENANT_ID)
                .roleCode(EmployeeRole.STORE_MANAGER)
                .roleName("店长")
                .permissions(String.join(",", Arrays.asList(
                        "merchant:dashboard_view", "session:view", "session:operate",
                        "cashier:checkout",
                        "member:list_view", "member:phone_view", "member:recharge", "member:pref_view", "member:pref_edit",
                        "regulation:view", "regulation:sign", "regulation:feedback", "regulation:manage"
                )))
                .description("负责门店日常营运接待、空间调度、收银结算与规章制度发布答复")
                .build();

        // 4. 收银员 (CASHIER) - 专注台位开单、结账收银与储值办理，默认不看全店经营大屏
        RolePermissionConfig cashierConfig = RolePermissionConfig.builder()
                .tenantId(PLATFORM_TENANT_ID)
                .roleCode(EmployeeRole.CASHIER)
                .roleName("收银员")
                .permissions(String.join(",", Arrays.asList(
                        "session:view", "session:operate", "cashier:checkout",
                        "member:list_view", "member:phone_view", "member:recharge", "member:pref_view",
                        "regulation:view", "regulation:sign", "regulation:feedback"
                )))
                .description("负责前台开单、组合结算与收银核销，查阅制度与意见箱交流")
                .build();

        // 5. 技师/施工人员 (TECHNICIAN) - 专注在场看板、查看工单与维护海马体记忆偏好
        RolePermissionConfig techConfig = RolePermissionConfig.builder()
                .tenantId(PLATFORM_TENANT_ID)
                .roleCode(EmployeeRole.TECHNICIAN)
                .roleName("技师/施工人员")
                .permissions(String.join(",", Arrays.asList(
                        "session:view", "member:list_view", "member:pref_view", "member:pref_edit",
                        "regulation:view", "regulation:sign", "regulation:feedback"
                )))
                .description("执行专业项目，记录顾客专属海马体记忆档案，查阅制度与提交建议")
                .build();

        // 6. 顾客会员 (CUSTOMER_MEMBER) - 专属会员个人中心
        RolePermissionConfig memberConfig = RolePermissionConfig.builder()
                .tenantId(PLATFORM_TENANT_ID)
                .roleCode(EmployeeRole.CUSTOMER_MEMBER)
                .roleName("顾客会员")
                .permissions(String.join(",", Arrays.asList(
                        "member:self_profile_view", "member:self_profile_edit", "member:self_pref_manage", "member:self_asset_view"
                )))
                .description("会员自主查看与修改个人资料、维护海马偏好画像与查看资产")
                .build();

        rolePermissionConfigRepository.saveAll(Arrays.asList(
                devConfig, bossConfig, managerConfig, cashierConfig, techConfig, memberConfig
        ));
        log.info("【海马智慧门店】全局角色权限配置初始化完成！共计初始化 6 大核心角色。");
    }

    /**
     * 获取全平台默认角色权限矩阵 (系统开发维护人使用)
     */
    public List<RolePermissionVO> getPlatformRolePermissions() {
        List<RolePermissionConfig> configs = rolePermissionConfigRepository.findByTenantId(PLATFORM_TENANT_ID);
        List<PermissionItemVO> allMeta = getAllPermissionMetadata();
        return configs.stream().map(c -> RolePermissionVO.builder()
                .id(c.getId())
                .tenantId(c.getTenantId())
                .roleCode(c.getRoleCode())
                .roleName(c.getRoleName())
                .permissions(c.getPermissionList())
                .description(c.getDescription())
                .isCustom(false)
                .availablePermissions(allMeta)
                .build()
        ).collect(Collectors.toList());
    }

    /**
     * 系统开发维护人修改指定角色的全局默认权限
     */
    @Transactional(rollbackFor = Exception.class)
    public RolePermissionVO updatePlatformRolePermission(EmployeeRole roleCode, UpdateRolePermissionCommand cmd) {
        RolePermissionConfig config = rolePermissionConfigRepository
                .findByTenantIdAndRoleCode(PLATFORM_TENANT_ID, roleCode)
                .orElseGet(() -> RolePermissionConfig.builder()
                        .tenantId(PLATFORM_TENANT_ID)
                        .roleCode(roleCode)
                        .roleName(roleCode.getDescription())
                        .build());

        config.setPermissionList(cmd.getPermissions());
        if (cmd.getDescription() != null) {
            config.setDescription(cmd.getDescription());
        }
        RolePermissionConfig saved = rolePermissionConfigRepository.save(config);
        log.info("【系统开发维护人】已更新全局角色 [{}] 权限配置: {}", roleCode, cmd.getPermissions());

        return RolePermissionVO.builder()
                .id(saved.getId())
                .tenantId(saved.getTenantId())
                .roleCode(saved.getRoleCode())
                .roleName(saved.getRoleName())
                .permissions(saved.getPermissionList())
                .description(saved.getDescription())
                .isCustom(false)
                .availablePermissions(getAllPermissionMetadata())
                .build();
    }

    /**
     * 门店老板获取旗下店员角色的权限配置
     */
    public List<RolePermissionVO> getMerchantStaffPermissions(String tenantId) {
        // 1. 获取商户的定制配置
        Map<EmployeeRole, RolePermissionConfig> customMap = rolePermissionConfigRepository
                .findByTenantId(tenantId)
                .stream()
                .collect(Collectors.toMap(RolePermissionConfig::getRoleCode, c -> c));

        // 2. 获取平台默认模板
        List<RolePermissionConfig> platformDefaults = rolePermissionConfigRepository.findByTenantId(PLATFORM_TENANT_ID);
        List<PermissionItemVO> allMeta = getAllPermissionMetadata();

        // 店员角色通常包括: 店长, 收银员, 技师, 服务员
        List<EmployeeRole> staffRoles = Arrays.asList(
                EmployeeRole.STORE_MANAGER, EmployeeRole.CASHIER, EmployeeRole.TECHNICIAN, EmployeeRole.WAITER
        );

        List<RolePermissionVO> result = new ArrayList<>();
        for (EmployeeRole r : staffRoles) {
            if (customMap.containsKey(r)) {
                RolePermissionConfig c = customMap.get(r);
                result.add(RolePermissionVO.builder()
                        .id(c.getId())
                        .tenantId(c.getTenantId())
                        .roleCode(c.getRoleCode())
                        .roleName(c.getRoleName())
                        .permissions(c.getPermissionList())
                        .description(c.getDescription())
                        .isCustom(true)
                        .availablePermissions(allMeta)
                        .build());
            } else {
                RolePermissionConfig p = platformDefaults.stream()
                        .filter(cfg -> cfg.getRoleCode() == r)
                        .findFirst()
                        .orElse(null);
                if (p != null) {
                    result.add(RolePermissionVO.builder()
                            .id(p.getId())
                            .tenantId(tenantId)
                            .roleCode(p.getRoleCode())
                            .roleName(p.getRoleName())
                            .permissions(p.getPermissionList())
                            .description(p.getDescription() + " (继承平台默认)")
                            .isCustom(false)
                            .availablePermissions(allMeta)
                            .build());
                }
            }
        }
        return result;
    }

    /**
     * 会员门店老板配置店员角色的权限
     */
    @Transactional(rollbackFor = Exception.class)
    public RolePermissionVO updateMerchantStaffPermission(String tenantId, EmployeeRole roleCode, UpdateRolePermissionCommand cmd) {
        RolePermissionConfig config = rolePermissionConfigRepository
                .findByTenantIdAndRoleCode(tenantId, roleCode)
                .orElseGet(() -> RolePermissionConfig.builder()
                        .tenantId(tenantId)
                        .roleCode(roleCode)
                        .roleName(roleCode.getDescription())
                        .build());

        config.setPermissionList(cmd.getPermissions());
        if (cmd.getDescription() != null) {
            config.setDescription(cmd.getDescription());
        }
        RolePermissionConfig saved = rolePermissionConfigRepository.save(config);
        log.info("【门店老板】商户 [{}] 已更新店员角色 [{}] 专属权限: {}", tenantId, roleCode, cmd.getPermissions());

        return RolePermissionVO.builder()
                .id(saved.getId())
                .tenantId(saved.getTenantId())
                .roleCode(saved.getRoleCode())
                .roleName(saved.getRoleName())
                .permissions(saved.getPermissionList())
                .description(saved.getDescription())
                .isCustom(true)
                .availablePermissions(getAllPermissionMetadata())
                .build();
    }

    /**
     * 获取用户实时生效的权限列表 (优先商户定制，次选平台模板)
     */
    public List<String> getEffectivePermissions(String tenantId, EmployeeRole roleCode) {
        // 如果是开发维护人
        if (roleCode == EmployeeRole.PLATFORM_DEVELOPER) {
            return rolePermissionConfigRepository
                    .findByTenantIdAndRoleCode(PLATFORM_TENANT_ID, EmployeeRole.PLATFORM_DEVELOPER)
                    .map(RolePermissionConfig::getPermissionList)
                    .orElse(Collections.emptyList());
        }

        // 如果是顾客会员
        if (roleCode == EmployeeRole.CUSTOMER_MEMBER) {
            return rolePermissionConfigRepository
                    .findByTenantIdAndRoleCode(PLATFORM_TENANT_ID, EmployeeRole.CUSTOMER_MEMBER)
                    .map(RolePermissionConfig::getPermissionList)
                    .orElse(Collections.emptyList());
        }

        // 如果是商户老板
        if (roleCode == EmployeeRole.SUPER_ADMIN) {
            return rolePermissionConfigRepository
                    .findByTenantIdAndRoleCode(PLATFORM_TENANT_ID, EmployeeRole.SUPER_ADMIN)
                    .map(RolePermissionConfig::getPermissionList)
                    .orElse(Collections.emptyList());
        }

        // 店员角色：优先查本租户定制
        if (tenantId != null && !tenantId.isEmpty()) {
            Optional<RolePermissionConfig> customOpt = rolePermissionConfigRepository.findByTenantIdAndRoleCode(tenantId, roleCode);
            if (customOpt.isPresent()) {
                return customOpt.get().getPermissionList();
            }
        }

        // 回退到平台模板
        return rolePermissionConfigRepository
                .findByTenantIdAndRoleCode(PLATFORM_TENANT_ID, roleCode)
                .map(RolePermissionConfig::getPermissionList)
                .orElse(Collections.emptyList());
    }
}
