package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.dto.session.AppendItemsCommand;
import com.seahorse.store.application.dto.session.OpenSessionCommand;
import com.seahorse.store.application.dto.session.SessionDetailVO;
import com.seahorse.store.application.service.ServiceSessionAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.session.enums.SessionStatus;
import com.seahorse.store.domain.session.model.ServiceSession;
import com.seahorse.store.infrastructure.repository.ServiceSessionRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * 在场履约会话接入控制器
 * 符合阿里巴巴与DDD接口层规范
 */
@Tag(name = "02. 在场履约会话", description = "桌台/镜台/工位在场开单、动态追加项目、转台与履约全流程")
@RestController
@RequestMapping("/api/session")
@RequiredArgsConstructor
public class ServiceSessionController {

    private final ServiceSessionAppService sessionAppService;
    private final ServiceSessionRepository sessionRepository;

    @Operation(summary = "开启在场会话 (开台/占位/进厂)")
    @PostMapping("/open")
    public ApiResponse<ServiceSession> openSession(@RequestBody OpenSessionCommand cmd) {
        ServiceSession session = sessionAppService.openSession(cmd);
        return ApiResponse.success("开单成功", session);
    }

    @Operation(summary = "通用动态追加项目 (加菜 / 加护理 / 增项换配件)")
    @PostMapping("/append")
    public ApiResponse<SessionDetailVO> appendItems(@RequestBody AppendItemsCommand cmd) {
        SessionDetailVO detail = sessionAppService.appendItems(cmd);
        return ApiResponse.success("追加成功", detail);
    }

    @Operation(summary = "获取在场会话详尽明细 (包含所有点单批次与技师分摊)")
    @GetMapping("/{id}/detail")
    public ApiResponse<SessionDetailVO> getDetail(@PathVariable("id") Long id) {
        return ApiResponse.success(sessionAppService.getSessionDetail(id));
    }

    @Data
    public static class TransferSpaceRequest {
        private Long targetSpaceId;
    }

    @Operation(summary = "转台 / 转工位")
    @PostMapping("/{id}/transfer")
    public ApiResponse<String> transferSpace(@PathVariable("id") Long id, @RequestBody TransferSpaceRequest req) {
        sessionAppService.transferSpace(id, req.getTargetSpaceId());
        return ApiResponse.success("转台成功", "OK");
    }

    @Data
    public static class CancelItemRequest {
        private String reason;
    }

    @Operation(summary = "退单 / 取消明细项目")
    @PostMapping("/item/{lineItemId}/cancel")
    public ApiResponse<String> cancelLineItem(@PathVariable("lineItemId") Long lineItemId, @RequestBody CancelItemRequest req) {
        sessionAppService.cancelLineItem(lineItemId, req.getReason());
        return ApiResponse.success("退单成功", "OK");
    }

    @Operation(summary = "获取当前门店活跃服务中的会话列表")
    @GetMapping("/active-list")
    public ApiResponse<List<ServiceSession>> getActiveSessions() {
        String tenantId = TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001";
        TenantContext.assertTenantAccess(tenantId);
        String storeId = TenantContext.getStoreId();
        List<SessionStatus> activeStatuses = Arrays.asList(
                SessionStatus.OCCUPIED_ORDERING, SessionStatus.SERVING, SessionStatus.SETTLING);

        List<ServiceSession> list = new ArrayList<>();
        if (storeId != null && !"PLATFORM".equalsIgnoreCase(storeId)) {
            for (ServiceSession s : sessionRepository.findByStoreIdAndStatusIn(storeId, activeStatuses)) {
                if (TenantContext.isPlatformAdmin() || tenantId.equalsIgnoreCase(s.getTenantId())) {
                    list.add(s);
                }
            }
        }

        List<ServiceSession> tenantSessions = sessionRepository.findByTenantIdAndStatusIn(tenantId, activeStatuses);
        for (ServiceSession s : tenantSessions) {
            boolean exists = list.stream().anyMatch(item -> item.getId().equals(s.getId()));
            if (!exists) {
                list.add(s);
            }
        }
        return ApiResponse.success(list);
    }
}
