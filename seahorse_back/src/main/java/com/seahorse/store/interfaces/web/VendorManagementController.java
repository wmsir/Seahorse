package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.dto.vendor.RecordStorageFeeCommand;
import com.seahorse.store.application.dto.vendor.RenewSubscriptionCommand;
import com.seahorse.store.application.service.PlatformConfigAppService;
import com.seahorse.store.application.service.VendorOperationAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import com.seahorse.store.domain.iam.model.SubscriptionBillingRecord;
import com.seahorse.store.domain.iam.model.TenantSubscription;
import com.seahorse.store.interfaces.web.vo.VendorDashboardStatsVO;
import com.seahorse.store.interfaces.web.vo.VendorSubscriptionVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 系统开发商运营管理后台控制器
 * 提供商户会员套餐管理、存储服务费缴纳、到期预警与平台综合收益大盘
 */
@Tag(name = "10. 系统开发商运营管控平台", description = "SaaS商户订阅管理、云存储服务费记账、到期提醒预警与经营收益大盘")
@RestController
@RequestMapping("/api/vendor")
@RequiredArgsConstructor
public class VendorManagementController {

    private final VendorOperationAppService vendorOperationAppService;
    private final PlatformConfigAppService platformConfigAppService;
    private final com.seahorse.store.application.service.PermissionManageAppService permissionManageAppService;
    private final com.seahorse.store.infrastructure.repository.StoreRepository storeRepository;
    private final com.seahorse.store.infrastructure.repository.TenantRepository tenantRepository;
    private final com.seahorse.store.infrastructure.repository.EmployeeRepository employeeRepository;

    @Operation(summary = "获取开发商综合经营与财务大盘数据")
    @GetMapping("/stats")
    public ApiResponse<VendorDashboardStatsVO> getDashboardStats() {
        return ApiResponse.success(vendorOperationAppService.getVendorDashboardStats());
    }

    @Operation(summary = "查询所有商户订阅及配置清单（支持关键字和到期预警状态筛选）")
    @GetMapping("/subscriptions")
    public ApiResponse<List<VendorSubscriptionVO>> getSubscriptions(
            @RequestParam(value = "query", required = false) String query,
            @RequestParam(value = "warningLevel", required = false) String warningLevel) {
        return ApiResponse.success(vendorOperationAppService.getTenantSubscriptions(query, warningLevel));
    }

    @Operation(summary = "办理商户套餐续费或版本升级")
    @PostMapping("/renew")
    public ApiResponse<TenantSubscription> renewSubscription(@RequestBody RenewSubscriptionCommand cmd) {
        TenantSubscription sub = vendorOperationAppService.renewSubscription(cmd);
        return ApiResponse.success("续费/升级成功", sub);
    }

    @Data
    public static class AdjustLimitsRequest {
        private String tenantId;
        private Integer storeLimit;
        private Integer staffLimit;
        private Integer storageQuotaGb;
    }

    @Operation(summary = "调整商户配额限制 (门店数/员工数/存储配额)")
    @PostMapping("/adjust-limits")
    public ApiResponse<TenantSubscription> adjustLimits(@RequestBody AdjustLimitsRequest req) {
        TenantSubscription sub = vendorOperationAppService.adjustTenantLimits(
                req.getTenantId(), req.getStoreLimit(), req.getStaffLimit(), req.getStorageQuotaGb()
        );
        return ApiResponse.success("配额上限调整成功", sub);
    }

    @Operation(summary = "录入商户云存储扩容服务费交费记录")
    @PostMapping("/record-storage-fee")
    public ApiResponse<SubscriptionBillingRecord> recordStorageFee(@RequestBody RecordStorageFeeCommand cmd) {
        SubscriptionBillingRecord record = vendorOperationAppService.recordStorageFee(cmd);
        return ApiResponse.success("存储服务费录入成功", record);
    }

    @Operation(summary = "查询平台历史订阅与存储服务费交费流水")
    @GetMapping("/billing-records")
    public ApiResponse<List<SubscriptionBillingRecord>> getBillingRecords(
            @RequestParam(value = "tenantId", required = false) String tenantId) {
        return ApiResponse.success(vendorOperationAppService.getBillingRecords(tenantId));
    }

    @Data
    public static class ToggleStatusRequest {
        private String status; // ACTIVE, DISABLED
        private String reason;
    }

    @Operation(summary = "启用/禁用指定商户权限 (禁止使用/恢复启用)")
    @PostMapping("/tenant/{tenantId}/toggle-status")
    public ApiResponse<String> toggleTenantStatus(
            @PathVariable("tenantId") String tenantId,
            @RequestBody ToggleStatusRequest req) {
        vendorOperationAppService.toggleTenantStatus(tenantId, req.getStatus());
        return ApiResponse.success("商户状态更新成功", req.getStatus());
    }

    @Operation(summary = "超级管理员彻底注销/删除指定租户")
    @DeleteMapping("/tenant/{tenantId}")
    public ApiResponse<String> deleteTenant(@PathVariable("tenantId") String tenantId) {
        vendorOperationAppService.deleteTenant(tenantId);
        return ApiResponse.success("租户及关联数据已成功安全注销删除", "OK");
    }

    @Operation(summary = "获取指定租户名下所有有效人员账号清单")
    @GetMapping("/tenant/{tenantId}/users")
    public ApiResponse<List<Map<String, Object>>> getTenantUsers(@PathVariable("tenantId") String tenantId) {
        return ApiResponse.success(vendorOperationAppService.getTenantUsers(tenantId));
    }

    @Data
    public static class ResetUserPasswordRequest {
        private Long userId;
        private String username;
        private String newPassword;
        private String tenantId;
    }

    @Operation(summary = "超级管理员修改/重置任意用户密码")
    @PostMapping("/users/reset-password")
    public ApiResponse<Map<String, Object>> resetUserPassword(@RequestBody ResetUserPasswordRequest req) {
        Map<String, Object> result = vendorOperationAppService.resetUserPassword(
                req.getUserId(), req.getUsername(), req.getNewPassword(), req.getTenantId()
        );
        return ApiResponse.success("用户密码重置成功", result);
    }

    @Operation(summary = "获取所有 SaaS 套餐方案与定价配置清单")
    @GetMapping("/plans")
    public ApiResponse<List<com.seahorse.store.interfaces.web.vo.SubscriptionPlanConfigVO>> getAvailablePlans() {
        return ApiResponse.success(platformConfigAppService.getAllPlanConfigs());
    }

    @Operation(summary = "修改指定SaaS会员套餐价格、试用期及配额配置")
    @PutMapping("/plans/{id}")
    public ApiResponse<com.seahorse.store.interfaces.web.vo.SubscriptionPlanConfigVO> updatePlanConfig(
            @PathVariable("id") Long id,
            @RequestBody com.seahorse.store.application.dto.vendor.UpdatePlanConfigCommand cmd) {
        com.seahorse.store.interfaces.web.vo.SubscriptionPlanConfigVO vo = platformConfigAppService.updatePlanConfig(id, cmd);
        return ApiResponse.success("套餐配置与定价修改成功", vo);
    }

    @Data
    public static class UpdateTrialDaysRequest {
        private Integer trialDays;
    }

    @Operation(summary = "快捷修改新注册默认试用期天数 (如3天修改为7天等)")
    @PutMapping("/trial-days")
    public ApiResponse<Integer> updateTrialDays(@RequestBody UpdateTrialDaysRequest req) {
        int updated = platformConfigAppService.updateTrialDays(req.getTrialDays());
        return ApiResponse.success("新商户默认试用天数已成功更新为 " + updated + " 天", updated);
    }

    @Operation(summary = "获取全平台各角色的全局查看权限与功能矩阵配置")
    @GetMapping("/permissions")
    public ApiResponse<List<com.seahorse.store.interfaces.web.vo.RolePermissionVO>> getPlatformRolePermissions() {
        return ApiResponse.success(permissionManageAppService.getPlatformRolePermissions());
    }

    @Operation(summary = "开发维护人修改指定角色的全局权限与查看配置")
    @PutMapping("/permissions/{roleCode}")
    public ApiResponse<com.seahorse.store.interfaces.web.vo.RolePermissionVO> updatePlatformRolePermission(
            @PathVariable com.seahorse.store.domain.iam.enums.EmployeeRole roleCode,
            @RequestBody com.seahorse.store.application.dto.iam.UpdateRolePermissionCommand cmd) {
        com.seahorse.store.interfaces.web.vo.RolePermissionVO vo = permissionManageAppService.updatePlatformRolePermission(roleCode, cmd);
        return ApiResponse.success("全局角色权限配置成功", vo);
    }

    @Operation(summary = "获取全平台功能权限字典元数据")
    @GetMapping("/permissions-metadata")
    public ApiResponse<List<com.seahorse.store.interfaces.web.vo.PermissionItemVO>> getPermissionsMetadata() {
        return ApiResponse.success(permissionManageAppService.getAllPermissionMetadata());
    }

    @Operation(summary = "超级管理员通过手机号检索商户与分店信息，用于授权代管登录")
    @GetMapping("/query-stores-by-phone")
    public ApiResponse<List<Map<String, Object>>> queryStoresByPhone(@RequestParam("phone") String phone) {
        String clean = phone != null ? phone.trim() : "";
        if (clean.isEmpty()) {
            return ApiResponse.success(Collections.emptyList());
        }

        Map<String, Map<String, Object>> resultMap = new LinkedHashMap<>();

        // 1. 根据店铺联系电话检索
        List<com.seahorse.store.domain.iam.model.Store> storesByPhone = storeRepository.findByPhoneContaining(clean);
        Set<String> storeTenantIds = storesByPhone.stream()
                .map(com.seahorse.store.domain.iam.model.Store::getTenantId)
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        Map<String, com.seahorse.store.domain.iam.model.Tenant> tenantMap = new HashMap<>();
        if (!storeTenantIds.isEmpty()) {
            for (com.seahorse.store.domain.iam.model.Tenant t : tenantRepository.findByTenantIdIn(storeTenantIds)) {
                if (t != null && t.getTenantId() != null) {
                    tenantMap.put(t.getTenantId(), t);
                }
            }
        }
        for (com.seahorse.store.domain.iam.model.Store s : storesByPhone) {
            com.seahorse.store.domain.iam.model.Tenant t = tenantMap.get(s.getTenantId());
            String tName = t != null ? t.getTenantName() : "智慧商户";
            String managerName = t != null && t.getContactName() != null ? t.getContactName() : "店长";
            String key = s.getTenantId() + "_" + s.getStoreId();
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("tenantId", s.getTenantId());
            map.put("tenantName", tName);
            map.put("storeId", s.getStoreId());
            map.put("storeName", s.getStoreName());
            map.put("industry", s.getIndustry() != null ? s.getIndustry().name() : "BEAUTY");
            map.put("managerName", managerName);
            map.put("phone", s.getPhone() != null ? s.getPhone() : (t != null ? t.getContactPhone() : ""));
            map.put("address", s.getAddress() != null ? s.getAddress() : "");
            map.put("businessStatus", s.getStatus() != null ? s.getStatus() : "ACTIVE");
            resultMap.put(key, map);
        }

        // 2. 根据租户联系电话检索旗下所有门店
        List<com.seahorse.store.domain.iam.model.Tenant> tenants = tenantRepository.findByContactPhoneContaining(clean);
        for (com.seahorse.store.domain.iam.model.Tenant t : tenants) {
            if (t != null && t.getTenantId() != null) {
                tenantMap.putIfAbsent(t.getTenantId(), t);
            }
        }
        Set<String> contactTenantIds = tenants.stream()
                .map(com.seahorse.store.domain.iam.model.Tenant::getTenantId)
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        Map<String, List<com.seahorse.store.domain.iam.model.Store>> storesByTenantMap = new HashMap<>();
        if (!contactTenantIds.isEmpty()) {
            for (com.seahorse.store.domain.iam.model.Store st : storeRepository.findByTenantIdIn(contactTenantIds)) {
                if (st != null && st.getTenantId() != null) {
                    storesByTenantMap.computeIfAbsent(st.getTenantId(), k -> new ArrayList<>()).add(st);
                }
            }
        }
        for (com.seahorse.store.domain.iam.model.Tenant t : tenants) {
            List<com.seahorse.store.domain.iam.model.Store> tStores = storesByTenantMap.getOrDefault(t.getTenantId(), Collections.emptyList());
            for (com.seahorse.store.domain.iam.model.Store s : tStores) {
                String key = s.getTenantId() + "_" + s.getStoreId();
                if (!resultMap.containsKey(key)) {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("tenantId", s.getTenantId());
                    map.put("tenantName", t.getTenantName());
                    map.put("storeId", s.getStoreId());
                    map.put("storeName", s.getStoreName());
                    map.put("industry", s.getIndustry() != null ? s.getIndustry().name() : "BEAUTY");
                    map.put("managerName", t.getContactName() != null ? t.getContactName() : "店长");
                    map.put("phone", s.getPhone() != null ? s.getPhone() : t.getContactPhone());
                    map.put("address", s.getAddress() != null ? s.getAddress() : "");
                    map.put("businessStatus", s.getStatus() != null ? s.getStatus() : "ACTIVE");
                    resultMap.put(key, map);
                }
            }
        }

        // 3. 根据员工/老板手机号检索关联门店
        List<com.seahorse.store.domain.iam.model.Employee> employees = employeeRepository.findByPhone(clean);
        Set<String> empTenantIds = employees.stream()
                .map(com.seahorse.store.domain.iam.model.Employee::getTenantId)
                .filter(tid -> tid != null && !"PLATFORM".equalsIgnoreCase(tid))
                .collect(Collectors.toCollection(LinkedHashSet::new));
        Set<String> missingStoreTenantIds = empTenantIds.stream()
                .filter(tid -> !storesByTenantMap.containsKey(tid))
                .collect(Collectors.toCollection(LinkedHashSet::new));
        if (!missingStoreTenantIds.isEmpty()) {
            for (com.seahorse.store.domain.iam.model.Store st : storeRepository.findByTenantIdIn(missingStoreTenantIds)) {
                if (st != null && st.getTenantId() != null) {
                    storesByTenantMap.computeIfAbsent(st.getTenantId(), k -> new ArrayList<>()).add(st);
                }
            }
        }
        Set<String> missingTenantIds = empTenantIds.stream()
                .filter(tid -> !tenantMap.containsKey(tid))
                .collect(Collectors.toCollection(LinkedHashSet::new));
        if (!missingTenantIds.isEmpty()) {
            for (com.seahorse.store.domain.iam.model.Tenant t : tenantRepository.findByTenantIdIn(missingTenantIds)) {
                if (t != null && t.getTenantId() != null) {
                    tenantMap.put(t.getTenantId(), t);
                }
            }
        }
        for (com.seahorse.store.domain.iam.model.Employee e : employees) {
            if (e.getTenantId() != null && !"PLATFORM".equalsIgnoreCase(e.getTenantId())) {
                List<com.seahorse.store.domain.iam.model.Store> eStores = storesByTenantMap.getOrDefault(e.getTenantId(), Collections.emptyList());
                for (com.seahorse.store.domain.iam.model.Store s : eStores) {
                    String key = s.getTenantId() + "_" + s.getStoreId();
                    if (!resultMap.containsKey(key)) {
                        com.seahorse.store.domain.iam.model.Tenant t = tenantMap.get(s.getTenantId());
                        String tName = t != null ? t.getTenantName() : "智慧商户";
                        String managerName = e.getRealName() != null ? e.getRealName() : (t != null && t.getContactName() != null ? t.getContactName() : "负责人");
                        Map<String, Object> map = new LinkedHashMap<>();
                        map.put("tenantId", s.getTenantId());
                        map.put("tenantName", tName);
                        map.put("storeId", s.getStoreId());
                        map.put("storeName", s.getStoreName());
                        map.put("industry", s.getIndustry() != null ? s.getIndustry().name() : "BEAUTY");
                        map.put("managerName", managerName);
                        map.put("phone", e.getPhone() != null ? e.getPhone() : (s.getPhone() != null ? s.getPhone() : ""));
                        map.put("address", s.getAddress() != null ? s.getAddress() : "");
                        map.put("businessStatus", s.getStatus() != null ? s.getStatus() : "ACTIVE");
                        resultMap.put(key, map);
                    }
                }
            }
        }

        return ApiResponse.success(new ArrayList<>(resultMap.values()));
    }
}
