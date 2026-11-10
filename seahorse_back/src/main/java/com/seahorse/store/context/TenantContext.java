package com.seahorse.store.context;

import lombok.Builder;
import lombok.Data;

public class TenantContext {
    private static final ThreadLocal<TenantInfo> CURRENT = new ThreadLocal<>();

    @Data
    @Builder
    public static class TenantInfo {
        private String tenantId;
        private String storeId;
        private Long userId;
        private String username;
        private String role;
        private String industry;
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

    public static void clear() {
        CURRENT.remove();
    }
}
