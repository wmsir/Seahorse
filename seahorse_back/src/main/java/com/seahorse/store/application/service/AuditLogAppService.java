package com.seahorse.store.application.service;

import com.seahorse.store.domain.audit.model.AuditPolicy;
import com.seahorse.store.domain.audit.model.SecurityAuditLog;
import com.seahorse.store.infrastructure.repository.AuditPolicyRepository;
import com.seahorse.store.infrastructure.repository.SecurityAuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuditLogAppService {

    private final SecurityAuditLogRepository securityAuditLogRepository;
    private final AuditPolicyRepository auditPolicyRepository;

    /**
     * 获取全局审计策略（若无则初始化全员默认记录策略）
     */
    @Transactional(readOnly = true)
    public AuditPolicy getPolicy() {
        return auditPolicyRepository.findFirstByOrderByIdAsc().orElseGet(() -> {
            AuditPolicy defaultPolicy = AuditPolicy.builder()
                    .enabled(true)
                    .mode("ALL") // ALL: 默认全员全量记录
                    .excludedTenantIds("")
                    .excludedStoreIds("")
                    .includedTenantIds("")
                    .includedStoreIds("")
                    .recordLogins(true)
                    .recordOperations(true)
                    .build();
            return defaultPolicy;
        });
    }

    /**
     * 超级管理员保存/配置审计策略
     */
    @Transactional(rollbackFor = Exception.class)
    public AuditPolicy savePolicy(AuditPolicy input) {
        AuditPolicy existing = auditPolicyRepository.findFirstByOrderByIdAsc().orElse(null);
        if (existing == null) {
            existing = new AuditPolicy();
        }
        existing.setEnabled(input.getEnabled() != null ? input.getEnabled() : true);
        existing.setMode(input.getMode() != null ? input.getMode() : "ALL");
        existing.setExcludedTenantIds(input.getExcludedTenantIds() != null ? input.getExcludedTenantIds().trim() : "");
        existing.setExcludedStoreIds(input.getExcludedStoreIds() != null ? input.getExcludedStoreIds().trim() : "");
        existing.setIncludedTenantIds(input.getIncludedTenantIds() != null ? input.getIncludedTenantIds().trim() : "");
        existing.setIncludedStoreIds(input.getIncludedStoreIds() != null ? input.getIncludedStoreIds().trim() : "");
        existing.setRecordLogins(input.getRecordLogins() != null ? input.getRecordLogins() : true);
        existing.setRecordOperations(input.getRecordOperations() != null ? input.getRecordOperations() : true);
        existing.setUpdatedAt(LocalDateTime.now());

        AuditPolicy saved = auditPolicyRepository.save(existing);
        log.info("【安全审计策略已更新】enabled={}, mode={}, excludedTenants={}, excludedStores={}",
                saved.getEnabled(), saved.getMode(), saved.getExcludedTenantIds(), saved.getExcludedStoreIds());
        return saved;
    }

    /**
     * 核心记录方法：依据策略与租户/门店黑白名单判断并持久化
     */
    @Transactional(rollbackFor = Exception.class)
    public void recordLog(
            String tenantId,
            String tenantName,
            String storeId,
            String storeName,
            Long userId,
            String username,
            String realName,
            String action,
            String actionType,
            String ip,
            String device,
            String status,
            String notes) {
        try {
            AuditPolicy policy = getPolicy();
            // 1. 全局总开关检查
            if (policy.getEnabled() == null || !policy.getEnabled()) {
                return;
            }

            // 2. 登录与业务操作开关检查
            if ("LOGIN".equalsIgnoreCase(actionType) && Boolean.FALSE.equals(policy.getRecordLogins())) {
                return;
            }
            if (!"LOGIN".equalsIgnoreCase(actionType) && Boolean.FALSE.equals(policy.getRecordOperations())) {
                return;
            }

            // 3. 租户与门店黑白名单判定
            String tid = tenantId != null ? tenantId.trim() : "";
            String sid = storeId != null ? storeId.trim() : "";

            String mode = policy.getMode() != null ? policy.getMode().toUpperCase() : "ALL";

            if ("EXCLUDE".equals(mode)) {
                // 黑名单模式: 检查租户或门店是否在排除列表中
                Set<String> excludedTenants = splitToSet(policy.getExcludedTenantIds());
                if (!tid.isEmpty() && excludedTenants.contains(tid)) {
                    log.debug("【审计豁免】租户 {} 处于免记黑名单中", tid);
                    return;
                }
                Set<String> excludedStores = splitToSet(policy.getExcludedStoreIds());
                if (!sid.isEmpty() && excludedStores.contains(sid)) {
                    log.debug("【审计豁免】门店 {} 处于免记黑名单中", sid);
                    return;
                }
            } else if ("INCLUDE".equals(mode)) {
                // 白名单模式: 仅记录在白名单内的租户或门店
                Set<String> includedTenants = splitToSet(policy.getIncludedTenantIds());
                Set<String> includedStores = splitToSet(policy.getIncludedStoreIds());
                boolean tenantMatched = includedTenants.isEmpty() || (!tid.isEmpty() && includedTenants.contains(tid));
                boolean storeMatched = includedStores.isEmpty() || (!sid.isEmpty() && includedStores.contains(sid));
                if (!tenantMatched || !storeMatched) {
                    return;
                }
            } else {
                // 默认 ALL 模式: 即使是 ALL 模式，如果超管在黑名单填写了特定租户/门店，也进行尊重豁免
                Set<String> excludedTenants = splitToSet(policy.getExcludedTenantIds());
                if (!tid.isEmpty() && excludedTenants.contains(tid)) {
                    return;
                }
                Set<String> excludedStores = splitToSet(policy.getExcludedStoreIds());
                if (!sid.isEmpty() && excludedStores.contains(sid)) {
                    return;
                }
            }

            SecurityAuditLog auditLog = SecurityAuditLog.builder()
                    .tenantId(tid.isEmpty() ? "PLATFORM" : tid)
                    .tenantName(tenantName)
                    .storeId(sid)
                    .storeName(storeName)
                    .userId(userId)
                    .username(username != null ? username : "anonymous")
                    .realName(realName)
                    .action(action)
                    .actionType(actionType != null ? actionType : "OPERATE")
                    .ip(ip)
                    .device(device)
                    .status(status != null ? status : "SUCCESS")
                    .notes(notes)
                    .createdAt(LocalDateTime.now())
                    .build();

            securityAuditLogRepository.save(auditLog);
            log.info("【安全日志已记录】action={}, user={}, tenantId={}, storeId={}, ip={}",
                    action, username, tid, sid, ip);
        } catch (Exception e) {
            log.error("安全审计日志记录异常", e);
        }
    }

    /**
     * 规范分页查询审计日志
     */
    @Transactional(readOnly = true)
    public Page<SecurityAuditLog> queryLogs(String tenantId, String username, String keyword, int page, int size) {
        Pageable pageable = PageRequest.of(Math.max(0, page - 1), Math.max(1, size));
        return securityAuditLogRepository.searchLogs(tenantId, username, keyword, pageable);
    }

    /**
     * 清空指定租户或平台的安全日志
     */
    @Transactional(rollbackFor = Exception.class)
    public void clearLogs(String tenantId) {
        securityAuditLogRepository.clearLogsByTenant(tenantId);
        log.info("【安全日志已清空】tenantId={}", tenantId);
    }

    private Set<String> splitToSet(String str) {
        if (str == null || str.trim().isEmpty()) return new HashSet<>();
        return new HashSet<>(Arrays.asList(str.trim().split("[,，\\s]+")));
    }
}
