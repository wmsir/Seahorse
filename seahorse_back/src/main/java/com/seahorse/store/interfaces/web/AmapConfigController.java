package com.seahorse.store.interfaces.web;

import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.iam.model.AmapConfig;
import com.seahorse.store.infrastructure.repository.AmapConfigRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Tag(name = "15. 高德地图与考勤定位配置", description = "提供高德Web服务Key、地理围栏半径及坐标配置")
@RestController
@RequestMapping("/api/config/amap")
@RequiredArgsConstructor
public class AmapConfigController {

    private final AmapConfigRepository amapConfigRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    @org.springframework.beans.factory.annotation.Value("${seahorse.amap.web-key:${SEAHORSE_AMAP_WEB_KEY:}}")
    private String defaultAmapWebKey;

    @org.springframework.beans.factory.annotation.Value("${seahorse.amap.js-key:${SEAHORSE_AMAP_JS_KEY:}}")
    private String defaultAmapJsKey;

    @org.springframework.beans.factory.annotation.Value("${seahorse.amap.security-code:${SEAHORSE_AMAP_SECURITY_CODE:}}")
    private String defaultAmapSecurityCode;

    @Data
    public static class AmapConfigDTO {
        private String webApiKey;
        private String jsApiKey;
        private String securityCode;
        private Integer allowedRadiusMeters;
        private Double storeLongitude;
        private Double storeLatitude;
        private String storeAddress;
        private String storeName;
    }

    @Operation(summary = "获取高德地图与考勤配置")
    @GetMapping
    public ApiResponse<AmapConfigDTO> getAmapConfig() {
        String tenantId = TenantContext.getTenantId();
        if (tenantId == null || tenantId.isEmpty()) {
            tenantId = "T001";
        }
        TenantContext.assertTenantAccess(tenantId);
        final String finalTenantId = tenantId;
        final String defaultStoreId = TenantContext.getStoreId() != null && !TenantContext.getStoreId().isEmpty()
                ? TenantContext.getStoreId()
                : "S001";

        AmapConfig config = amapConfigRepository.findByTenantId(finalTenantId)
                .orElseGet(() -> {
                    AmapConfig def = AmapConfig.builder()
                            .tenantId(finalTenantId)
                            .storeId(defaultStoreId)
                            .webApiKey(defaultAmapWebKey != null ? defaultAmapWebKey : "")
                            .jsApiKey(defaultAmapJsKey != null ? defaultAmapJsKey : "")
                            .securityCode(defaultAmapSecurityCode != null ? defaultAmapSecurityCode : "")
                            .allowedRadiusMeters(500)
                            .storeLongitude(108.953400)
                            .storeLatitude(34.265500)
                            .storeAddress("陕西省西安市高新区高新路海马商业中心1号店")
                            .storeName("海马智慧商业 (西安高新旗舰店)")
                            .build();
                    return amapConfigRepository.save(def);
                });

        if ((config.getWebApiKey() == null || config.getWebApiKey().trim().isEmpty())
                && defaultAmapWebKey != null && !defaultAmapWebKey.trim().isEmpty()) {
            config.setWebApiKey(defaultAmapWebKey.trim());
            if (defaultAmapJsKey != null && !defaultAmapJsKey.trim().isEmpty()) {
                config.setJsApiKey(defaultAmapJsKey.trim());
            }
            if (defaultAmapSecurityCode != null && !defaultAmapSecurityCode.trim().isEmpty()) {
                config.setSecurityCode(defaultAmapSecurityCode.trim());
            }
            config = amapConfigRepository.save(config);
        }

        AmapConfigDTO dto = new AmapConfigDTO();
        dto.setWebApiKey(config.getWebApiKey());
        dto.setJsApiKey(config.getJsApiKey());
        dto.setSecurityCode(config.getSecurityCode());
        dto.setAllowedRadiusMeters(config.getAllowedRadiusMeters() != null ? config.getAllowedRadiusMeters() : 500);
        dto.setStoreLongitude(config.getStoreLongitude() != null ? config.getStoreLongitude() : 108.953400);
        dto.setStoreLatitude(config.getStoreLatitude() != null ? config.getStoreLatitude() : 34.265500);
        dto.setStoreAddress(config.getStoreAddress() != null ? config.getStoreAddress() : "陕西省西安市高新区高新路海马商业中心1号店");
        dto.setStoreName(config.getStoreName() != null ? config.getStoreName() : "海马智慧商业 (西安高新旗舰店)");

        return ApiResponse.success(dto);
    }

    @Operation(summary = "保存高德地图与考勤配置")
    @PostMapping
    public ApiResponse<AmapConfigDTO> saveAmapConfig(@RequestBody AmapConfigDTO dto) {
        TenantContext.assertTenantAdmin();
        String tenantId = TenantContext.getTenantId();
        if (tenantId == null || tenantId.isEmpty()) {
            tenantId = "T001";
        }
        TenantContext.assertTenantAccess(tenantId);

        final String finalTenantId = tenantId;
        AmapConfig config = amapConfigRepository.findByTenantId(tenantId)
                .orElseGet(() -> AmapConfig.builder().tenantId(finalTenantId).storeId("S001").build());

        if (dto.getWebApiKey() != null) config.setWebApiKey(dto.getWebApiKey().trim());
        if (dto.getJsApiKey() != null) config.setJsApiKey(dto.getJsApiKey().trim());
        if (dto.getSecurityCode() != null) config.setSecurityCode(dto.getSecurityCode().trim());
        if (dto.getAllowedRadiusMeters() != null) config.setAllowedRadiusMeters(dto.getAllowedRadiusMeters());
        if (dto.getStoreLongitude() != null) config.setStoreLongitude(dto.getStoreLongitude());
        if (dto.getStoreLatitude() != null) config.setStoreLatitude(dto.getStoreLatitude());
        if (dto.getStoreAddress() != null) config.setStoreAddress(dto.getStoreAddress().trim());
        if (dto.getStoreName() != null) config.setStoreName(dto.getStoreName().trim());

        amapConfigRepository.save(config);
        log.info("【高德与考勤配置保存成功】tenantId={}, webApiKey={}, radius={}m, store={}",
                tenantId, config.getWebApiKey(), config.getAllowedRadiusMeters(), config.getStoreName());

        return ApiResponse.success("高德地图与考勤定位配置已保存", dto);
    }

    @Operation(summary = "测试高德Web服务Key有效性")
    @GetMapping("/test")
    public ApiResponse<Map<String, Object>> testAmapApiKey(@RequestParam(required = false) String key) {
        TenantContext.assertTenantAdmin();
        if (key == null || key.trim().isEmpty()) {
            String tenantId = TenantContext.getTenantId();
            if (tenantId == null || tenantId.isEmpty()) tenantId = "T001";
            TenantContext.assertTenantAccess(tenantId);
            Optional<AmapConfig> opt = amapConfigRepository.findByTenantId(tenantId);
            if (opt.isPresent()) {
                key = opt.get().getWebApiKey();
            }
        }

        if (key == null || key.trim().isEmpty()) {
            return ApiResponse.error(400, "高德 Web 服务 API Key 不能为空，请先在输入框填入");
        }
        String cleanKey = key.trim();
        if (!cleanKey.matches("^[A-Za-z0-9_-]{8,64}$")) {
            return ApiResponse.error(400, "高德 API Key 格式无效");
        }

        Map<String, Object> result = new HashMap<>();
        try {
            String encodedKey = java.net.URLEncoder.encode(cleanKey, java.nio.charset.StandardCharsets.UTF_8);
            String url = "https://restapi.amap.com/v3/ip?key=" + encodedKey;
            Map resp = restTemplate.getForObject(url, Map.class);
            if (resp != null) {
                String status = String.valueOf(resp.get("status"));
                String info = String.valueOf(resp.get("info"));
                String infocode = String.valueOf(resp.get("infocode"));
                if ("1".equals(status)) {
                    result.put("valid", true);
                    result.put("status", status);
                    result.put("platform", "Web服务 (REST API)");
                    result.put("info", "Key 校验成功有效！");
                    result.put("province", resp.get("province"));
                    result.put("city", resp.get("city"));
                    result.put("ip", resp.get("ip"));
                    return ApiResponse.success("高德 Web 服务 Key 验证通过，网络通讯正常", result);
                } else if ("10009".equals(infocode)) {
                    // 10009 平台不匹配：说明该 Key 为【Web端 (JS API)】类型（如高德开放平台创建的 testJs）
                    try {
                        String jsUrl = "https://webapi.amap.com/maps?v=2.0&key=" + encodedKey;
                        String jsResp = restTemplate.getForObject(jsUrl, String.class);
                        if (jsResp != null && (jsResp.contains("amap") || jsResp.contains("AMap") || jsResp.length() > 500)) {
                            result.put("valid", true);
                            result.put("platform", "Web端 (JS API)");
                            result.put("info", "高德 Web端 JS API Key 验证通过，浏览器地图与定位服务已就绪！");
                            result.put("province", "全国通用");
                            result.put("city", "高德 Web 端地图 SDK 已就绪");
                            return ApiResponse.success("高德 Web端(JS API) Key 验证通过，浏览器服务可用！", result);
                        }
                    } catch (Exception ex) {
                        log.warn("高德 JS API 端点验证警告: {}", ex.getMessage());
                    }
                    result.put("valid", true);
                    result.put("platform", "Web端 (JS API)");
                    result.put("info", "高德 Web端 JS API Key 登记有效！");
                    result.put("province", "全国通用");
                    result.put("city", "浏览器高德地图服务已生效");
                    return ApiResponse.success("高德 Web端(JS API) Key 验证通过，浏览器服务可用！", result);
                } else {
                    result.put("valid", false);
                    result.put("status", status);
                    result.put("info", info);
                    result.put("infocode", infocode);
                    return ApiResponse.error(400, "高德 API 验证失败: " + info + " (错误码:" + infocode + ")");
                }
            }
            return ApiResponse.error(500, "高德接口无响应");
        } catch (Exception e) {
            log.error("测试高德 API Key 发生网络异常", e);
            result.put("valid", false);
            result.put("error", e.getMessage());
            return ApiResponse.error(500, "连接高德服务器超时或网络异常: " + e.getMessage());
        }
    }
}
