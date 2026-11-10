package com.seahorse.store.interfaces.web;

import com.seahorse.store.common.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * 云端服务健康检查与客户端网络探针
 * 提供系统根网关 /api 及 /api/health、/api/ping 的零耗时握手响应
 */
@Tag(name = "00. 健康检查与网络探测", description = "用于客户端网络连通性测试与服务存活心跳")
@RestController
@RequestMapping("/api")
public class SystemHealthController {

    @Operation(summary = "根网关及健康心跳探测探针")
    @GetMapping({"", "/", "/health", "/ping"})
    public ApiResponse<Map<String, Object>> ping() {
        Map<String, Object> data = new HashMap<>();
        data.put("status", "UP");
        data.put("service", "seahorse-cloud-service");
        data.put("version", "2.0.0");
        data.put("timestamp", System.currentTimeMillis());
        return ApiResponse.success("服务在线，网关连通正常", data);
    }
}
