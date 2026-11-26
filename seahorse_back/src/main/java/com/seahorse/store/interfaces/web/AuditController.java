package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.service.AuditLogAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.audit.model.AuditPolicy;
import com.seahorse.store.domain.audit.model.SecurityAuditLog;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;

@Tag(name = "16. 登录与系统安全审计日志", description = "全域登录流水记录、安全审计与超级管理员租户/门店策略配置")
@RestController
@RequestMapping("/api/audit")
@RequiredArgsConstructor
public class AuditController {

    private final AuditLogAppService auditLogAppService;

    @Operation(summary = "分页检索系统登录与安全审计日志")
    @GetMapping("/logs")
    public ApiResponse<Page<SecurityAuditLog>> getLogs(
            @RequestParam(value = "tenantId", required = false) String tenantId,
            @RequestParam(value = "username", required = false) String username,
            @RequestParam(value = "keyword", required = false) String keyword,
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "size", defaultValue = "10") int size) {
        boolean isPlatformAdmin = TenantContext.isPlatformAdmin();
        String effectiveTenantId = TenantContext.getTenantId();
        if (tenantId != null && !tenantId.trim().isEmpty()) {
            if (!isPlatformAdmin) {
                TenantContext.assertTenantAccess(tenantId.trim());
            }
            effectiveTenantId = tenantId.trim();
        } else if (isPlatformAdmin) {
            effectiveTenantId = null;
        }

        String currentRole = TenantContext.getRole();
        String currentUsername = TenantContext.getUsername();
        boolean isTenantAdmin = isTenantOrPlatformAdmin(currentRole, TenantContext.getTenantId(), currentUsername);

        String effectiveUsername = username;
        // 核心权限隔离：除租户主管理员/平台超管外，其他人强制仅可查看本人登录日志，禁止通过 username 参数越权窥探他人日志
        if (!isTenantAdmin) {
            effectiveUsername = (currentUsername != null && !currentUsername.trim().isEmpty())
                    ? currentUsername.trim() : "__anonymous__";
        }

        return ApiResponse.success(auditLogAppService.queryLogs(effectiveTenantId, effectiveUsername, keyword, page, size));
    }

    private boolean isTenantOrPlatformAdmin(String role, String tenantId, String username) {
        if (role != null) {
            String r = role.toUpperCase();
            if (r.contains("PLATFORM") || r.contains("SUPER_ADMIN") || r.contains("TENANT_ADMIN")
                    || r.contains("STORE_OWNER") || r.contains("MERCHANT_ADMIN") || r.contains("STORE_MANAGER")) {
                return true;
            }
        }
        return false;
    }

    @Operation(summary = "获取当前安全审计配置策略 (超级管理员专属)")
    @GetMapping("/policy")
    public ApiResponse<AuditPolicy> getPolicy() {
        TenantContext.assertTenantAdmin();
        return ApiResponse.success(auditLogAppService.getPolicy());
    }

    @Operation(summary = "更新配置安全审计策略与租户/门店黑白名单 (超级管理员专属)")
    @PostMapping("/policy/save")
    public ApiResponse<AuditPolicy> savePolicy(@RequestBody AuditPolicy policy) {
        TenantContext.assertPlatformAdmin();
        return ApiResponse.success("安全审计策略已成功保存", auditLogAppService.savePolicy(policy));
    }

    @Operation(summary = "清空系统安全审计日志")
    @DeleteMapping("/logs/clear")
    public ApiResponse<Void> clearLogs(@RequestParam(value = "tenantId", required = false) String tenantId) {
        String currentRole = TenantContext.getRole();
        String currentUsername = TenantContext.getUsername();
        if (!isTenantOrPlatformAdmin(currentRole, TenantContext.getTenantId(), currentUsername)) {
            return ApiResponse.error(403, "权限不足，清空日志仅限租户或平台管理员操作");
        }
        boolean isPlatformAdmin = "PLATFORM".equalsIgnoreCase(TenantContext.getTenantId())
                || "PLATFORM_DEVELOPER".equalsIgnoreCase(currentRole);
        String effectiveTenantId = isPlatformAdmin
                ? ((tenantId != null && !tenantId.trim().isEmpty()) ? tenantId.trim() : "PLATFORM")
                : TenantContext.getTenantId();
        if (effectiveTenantId == null || effectiveTenantId.trim().isEmpty()
                || (!isPlatformAdmin && "PLATFORM".equalsIgnoreCase(effectiveTenantId))) {
            return ApiResponse.error(403, "权限不足，非平台超级管理员不可清空全平台日志");
        }
        auditLogAppService.clearLogs(effectiveTenantId);
        return ApiResponse.success("安全日志已成功清空", null);
    }

    @Data
    public static class RecordLogCmd {
        private String action;
        private String actionType;
        private String ip;
        private String device;
        private String status;
        private String notes;
        private String storeId;
        private String storeName;
        private String username;
        private String realName;
        private Long userId;
        private String tenantId;
        private String tenantName;
    }

    @Operation(summary = "主动上报记录客户端安全敏感操作日志")
    @PostMapping("/log")
    public ApiResponse<Void> recordClientLog(@RequestBody RecordLogCmd cmd, HttpServletRequest request) {
        if (!TenantContext.isAuthenticated()) {
            return ApiResponse.error(401, "请先登录后上报操作日志");
        }
        boolean isPlatformAdmin = TenantContext.isPlatformAdmin();
        String tenantId = TenantContext.getTenantId();
        if (isPlatformAdmin && cmd.getTenantId() != null && !cmd.getTenantId().trim().isEmpty()) {
            tenantId = cmd.getTenantId().trim();
        } else if (cmd.getTenantId() != null && !cmd.getTenantId().trim().isEmpty()) {
            TenantContext.assertTenantAccess(cmd.getTenantId().trim());
        }
        String storeId = (cmd.getStoreId() != null && !cmd.getStoreId().trim().isEmpty())
                ? cmd.getStoreId()
                : TenantContext.getStoreId();
        String username = TenantContext.getUsername() != null ? TenantContext.getUsername() : "user";
        if (isPlatformAdmin && cmd.getUsername() != null && !cmd.getUsername().trim().isEmpty()) {
            username = cmd.getUsername().trim();
        }
        String realName = (cmd.getRealName() != null && !cmd.getRealName().trim().isEmpty())
                ? cmd.getRealName().trim()
                : username;
        String actionType = (cmd.getActionType() != null && !cmd.getActionType().trim().isEmpty())
                ? cmd.getActionType() : "LOGIN";
        String ip = (cmd.getIp() != null && !cmd.getIp().trim().isEmpty())
                ? cmd.getIp() : AuthController.getClientIp(request);
        String device = (cmd.getDevice() != null && !cmd.getDevice().trim().isEmpty())
                ? cmd.getDevice() : AuthController.getClientDevice(request);

        auditLogAppService.recordLog(
                tenantId,
                cmd.getTenantName(),
                storeId,
                cmd.getStoreName(),
                cmd.getUserId(),
                username,
                realName,
                cmd.getAction() != null ? cmd.getAction() : "账号密码登录",
                actionType,
                ip,
                device,
                cmd.getStatus() != null ? cmd.getStatus() : "SUCCESS",
                cmd.getNotes() != null ? cmd.getNotes() : "客户端安全登录上报"
        );
        return ApiResponse.success("记录成功", null);
    }
}
