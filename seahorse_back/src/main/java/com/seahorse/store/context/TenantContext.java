package com.seahorse.store.context;

import com.seahorse.store.common.ServiceException;
import lombok.Builder;
import lombok.Data;

import java.util.Set;

public class TenantContext {
    private static final ThreadLocal<TenantInfo> CURRENT = new ThreadLocal<>();

    private static final Set<String> TENANT_ADMIN_ROLES = Set.of(
            "PLATFORM_DEVELOPER",
            "SUPER_ADMIN",
            "STORE_MANAGER",
            "TENANT_ADMIN",
            "STORE_OWNER",
            "MERCHANT_ADMIN"
    );

    @Data
    @Builder
    public static class TenantInfo {
        private String tenantId;
        private String storeId;
        private Long userId;
        private String username;
        private String role;
        private String industry;
        private boolean authenticated;
    }

    public static void set(TenantInfo info) {
        CURRENT.set(info);
    }

    public static TenantInfo get() {
        return CURRENT.get();
    }

    public static String getTenantId() {
        TenantInfo info = CURRENT.get();
        return info != null && info.getTenantId() != null ? info.getTenantId() : "T001";
    }

    public static String getStoreId() {
        TenantInfo info = CURRENT.get();
        if (info == null) return null;
        if (info.getStoreId() != null && !info.getStoreId().trim().isEmpty() && !"S001".equalsIgnoreCase(info.getStoreId())) {
            return info.getStoreId();
        }
        if ("T001".equalsIgnoreCase(info.getTenantId()) || "PLATFORM".equalsIgnoreCase(info.getTenantId())) {
            return info.getStoreId() != null ? info.getStoreId() : "S001";
        }
        return info.getStoreId();
    }

    public static Long getUserId() {
        TenantInfo info = CURRENT.get();
        return info != null ? info.getUserId() : 1L;
    }

    public static String getUsername() {
        TenantInfo info = CURRENT.get();
        return info != null ? info.getUsername() : "admin";
    }

    public static String getRole() {
        TenantInfo info = CURRENT.get();
        return info != null ? info.getRole() : null;
    }

    public static boolean isAuthenticated() {
        TenantInfo info = CURRENT.get();
        return info != null && info.isAuthenticated();
    }

    public static boolean isPlatformAdmin() {
        TenantInfo info = CURRENT.get();
        if (info == null) {
            return false;
        }
        return "PLATFORM".equalsIgnoreCase(info.getTenantId())
                || "PLATFORM_DEVELOPER".equalsIgnoreCase(info.getRole());
    }

    public static void assertPlatformAdmin() {
        if (!isPlatformAdmin()) {
            throw new ServiceException(403, "权限不足，仅限平台超级管理员访问");
        }
    }

    public static void assertTenantAdmin() {
        if (isPlatformAdmin()) {
            return;
        }
        String role = getRole();
        if (role == null || !TENANT_ADMIN_ROLES.contains(role.trim().toUpperCase())) {
            throw new ServiceException(403, "权限不足，仅限商户管理员或店长执行该操作");
        }
    }

    public static void assertTenantAccess(String resourceTenantId) {
        if (resourceTenantId == null || resourceTenantId.trim().isEmpty() || isPlatformAdmin()) {
            return;
        }
        String currentTenantId = getTenantId();
        if (!resourceTenantId.trim().equalsIgnoreCase(currentTenantId)) {
            throw new ServiceException(403, "无权跨租户访问或修改其他商户数据");
        }
    }

    public static void clear() {
        CURRENT.remove();
    }
}
