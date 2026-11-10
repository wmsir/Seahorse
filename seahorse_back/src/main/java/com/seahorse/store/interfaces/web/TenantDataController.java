package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.service.TenantDataGeneratorAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.TenantContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 租户独立数据管理与业务场景真实测试数据生成控制器
 * 严格按照多租户隔离规范，支持新租户纯净零数据与按需后台生成场景测试数据
 */
@Tag(name = "12. 租户数据隔离与场景生成", description = "支持新注册租户纯净空数据起步，与后台按需生成行业真实测试数据")
@RestController
@RequestMapping("/api/tenant")
@RequiredArgsConstructor
public class TenantDataController {

    private final TenantDataGeneratorAppService tenantDataGeneratorAppService;

    @Data
    public static class InitDemoDataRequest {
        private String industry; // BEAUTY | RESTAURANT | AUTO | RETAIL
    }

    @Operation(summary = "按需为当前商户在后台生成业务场景真实测试数据")
    @PostMapping("/init-demo-data")
    public ApiResponse<Map<String, Object>> initDemoData(@RequestBody(required = false) InitDemoDataRequest req) {
        String tenantId = TenantContext.getTenantId();
        if (tenantId == null || "PLATFORM".equalsIgnoreCase(tenantId)) {
            throw new ServiceException("当前登录身份无效，仅限商户租户调用");
        }
        String industry = (req != null && req.getIndustry() != null) ? req.getIndustry() : "BEAUTY";
        Map<String, Object> result = tenantDataGeneratorAppService.initDemoData(tenantId, industry);
        return ApiResponse.success("测试数据生成成功", result);
    }

    @Operation(summary = "一键清空当前商户所有业务测试数据，重置为纯净零数据状态")
    @PostMapping("/clear-data")
    public ApiResponse<Map<String, Object>> clearData() {
        String tenantId = TenantContext.getTenantId();
        if (tenantId == null || "PLATFORM".equalsIgnoreCase(tenantId)) {
            throw new ServiceException("当前登录身份无效，仅限商户租户调用");
        }
        Map<String, Object> result = tenantDataGeneratorAppService.clearTenantData(tenantId);
        return ApiResponse.success("商户数据清空成功", result);
    }

    @Operation(summary = "查询当前商户的数据状态（门店数、店员数、会员数、是否纯净状态）")
    @GetMapping("/data-status")
    public ApiResponse<Map<String, Object>> getDataStatus() {
        String tenantId = TenantContext.getTenantId();
        if (tenantId == null || "PLATFORM".equalsIgnoreCase(tenantId)) {
            throw new ServiceException("当前登录身份无效，仅限商户租户调用");
        }
        Map<String, Object> result = tenantDataGeneratorAppService.getTenantDataStatus(tenantId);
        return ApiResponse.success(result);
    }
}
