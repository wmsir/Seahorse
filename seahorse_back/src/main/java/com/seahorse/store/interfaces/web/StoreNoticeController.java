package com.seahorse.store.interfaces.web;

import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.notice.model.StoreNotice;
import com.seahorse.store.infrastructure.repository.StoreNoticeRepository;
import com.seahorse.store.infrastructure.repository.StoreRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 门店运营规范与日常公告接口
 * 支持店长/租户老板发布与维护，推送到 APP 与浏览器页面实时展示
 */
@Slf4j
@Tag(name = "15. 门店运营规范与日常公告", description = "门店规范制度发布、日常公告下发、特急重要通知及移动端提示音推送")
@RestController
@RequestMapping("/api/store/notice")
@RequiredArgsConstructor
public class StoreNoticeController {

    private final StoreNoticeRepository noticeRepository;
    private final StoreRepository storeRepository;

    private String resolveTenantId(String targetStoreId) {
        if (targetStoreId != null && !targetStoreId.trim().isEmpty() && !"ALL".equalsIgnoreCase(targetStoreId)) {
            Optional<Store> sOpt = storeRepository.findByStoreId(targetStoreId.trim());
            if (sOpt.isPresent() && sOpt.get().getTenantId() != null && !sOpt.get().getTenantId().trim().isEmpty()) {
                return sOpt.get().getTenantId().trim();
            }
        }
        String ctxTid = TenantContext.getTenantId();
        if (ctxTid != null && !ctxTid.trim().isEmpty() && !"PLATFORM".equalsIgnoreCase(ctxTid)) {
            return ctxTid.trim();
        }
        return null;
    }

    @Operation(summary = "获取门店现行运营规范与日常公告列表 (严格租户隔离)")
    @GetMapping("/list")
    public ApiResponse<List<StoreNotice>> getNoticeList(
            @RequestParam(value = "storeId", required = false) String storeId,
            @RequestParam(value = "category", required = false) String category) {
        String targetStoreId = (storeId != null && !storeId.trim().isEmpty()) ? storeId.trim() : TenantContext.getStoreId();
        if (targetStoreId == null || targetStoreId.trim().isEmpty()) {
            targetStoreId = "S001";
        }
        String targetTenantId = resolveTenantId(targetStoreId);

        List<StoreNotice> list;
        if (targetTenantId != null && !targetTenantId.isEmpty()) {
            list = noticeRepository.findActiveNoticesByTenantAndStore(targetTenantId, targetStoreId);
        } else {
            list = noticeRepository.findActiveNoticesByStoreId(targetStoreId);
        }

        if (category != null && !category.trim().isEmpty() && !"ALL".equalsIgnoreCase(category)) {
            list = list.stream()
                    .filter(n -> category.equalsIgnoreCase(n.getCategory()))
                    .collect(Collectors.toList());
        }

        return ApiResponse.success(list);
    }

    @Operation(summary = "发布或更新门店运营规范 / 日常公告 / 特急通知")
    @PostMapping("/save")
    public ApiResponse<StoreNotice> saveNotice(@RequestBody StoreNotice notice) {
        if (notice.getId() != null) {
            noticeRepository.findById(notice.getId())
                    .ifPresent(existing -> TenantContext.assertTenantAccess(existing.getTenantId()));
        }
        String tenantId = TenantContext.isPlatformAdmin() ? notice.getTenantId() : TenantContext.getTenantId();
        if (tenantId == null || tenantId.trim().isEmpty() || "PLATFORM".equalsIgnoreCase(tenantId)) {
            String resolved = resolveTenantId(notice.getStoreId());
            tenantId = (resolved != null && !resolved.isEmpty()) ? resolved : "T001";
        }
        notice.setTenantId(tenantId);

        if (notice.getStoreId() == null || notice.getStoreId().trim().isEmpty()) {
            String ctxSid = TenantContext.getStoreId();
            notice.setStoreId((ctxSid != null && !ctxSid.trim().isEmpty()) ? ctxSid.trim() : "ALL");
        }

        if (notice.getStatus() == null || notice.getStatus().trim().isEmpty()) {
            notice.setStatus("PUBLISHED");
        }

        if (notice.getPublisher() == null || notice.getPublisher().trim().isEmpty()) {
            notice.setPublisher("门店管理中心");
        }

        if (Boolean.TRUE.equals(notice.getIsUrgent()) && notice.getPlayMusic() == null) {
            notice.setPlayMusic(true);
        }

        StoreNotice saved = noticeRepository.save(notice);
        log.info("成功发布/更新门店规范公告: id={}, tenantId={}, title={}, storeId={}, isUrgent={}, playMusic={}",
                saved.getId(), saved.getTenantId(), saved.getTitle(), saved.getStoreId(), saved.getIsUrgent(), saved.getPlayMusic());
        return ApiResponse.success(saved);
    }

    @Operation(summary = "下架/废止或删除规范公告")
    @PostMapping("/delete")
    public ApiResponse<Boolean> deleteNotice(@RequestParam("id") Long id) {
        Optional<StoreNotice> opt = noticeRepository.findById(id);
        if (opt.isPresent()) {
            StoreNotice notice = opt.get();
            TenantContext.assertTenantAccess(notice.getTenantId());
            notice.setStatus("REVOKED");
            noticeRepository.save(notice);
            log.info("已成功下架废止规范公告: id={}, title={}", id, notice.getTitle());
            return ApiResponse.success(true);
        }
        return ApiResponse.success(false);
    }

    @Operation(summary = "获取当前门店最新未读特急重要通知 (用于移动端APP提示音乐播放与弹窗)")
    @GetMapping("/urgent-latest")
    public ApiResponse<StoreNotice> getLatestUrgentNotice(@RequestParam(value = "storeId", required = false) String storeId) {
        String targetStoreId = (storeId != null && !storeId.trim().isEmpty()) ? storeId.trim() : TenantContext.getStoreId();
        if (targetStoreId == null || targetStoreId.trim().isEmpty()) {
            targetStoreId = "S001";
        }
        String targetTenantId = resolveTenantId(targetStoreId);
        List<StoreNotice> urgents;
        if (targetTenantId != null && !targetTenantId.isEmpty()) {
            urgents = noticeRepository.findUrgentNoticesByTenantAndStore(targetTenantId, targetStoreId);
        } else {
            urgents = noticeRepository.findUrgentNoticesByStoreId(targetStoreId);
        }
        if (urgents != null && !urgents.isEmpty()) {
            return ApiResponse.success(urgents.get(0));
        }
        return ApiResponse.success(null);
    }

}
