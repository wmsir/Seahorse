package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.service.ShiftHandoverAppService;
import com.seahorse.store.application.service.ShiftHandoverAppService.BlindShiftCommand;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.billing.model.ShiftRecord;
import com.seahorse.store.infrastructure.repository.ShiftRecordRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 收银交班接入控制器
 * 符合阿里巴巴与DDD接口层规范
 */
@Tag(name = "07. 收银交班与盲盘对账", description = "盲盘现金录入、全渠道实收对账与长短款平账单")
@RestController
@RequestMapping("/api/shift")
@RequiredArgsConstructor
public class ShiftController {

    private final ShiftHandoverAppService shiftHandoverAppService;
    private final ShiftRecordRepository shiftRecordRepository;

    @Operation(summary = "提交收银员盲盘交班 (自动核对系统理论现金与长短款差额)")
    @PostMapping("/blind-submit")
    public ApiResponse<ShiftRecord> submitShift(@RequestBody BlindShiftCommand cmd) {
        ShiftRecord record = shiftHandoverAppService.submitBlindShift(cmd);
        return ApiResponse.success("交班对账完成", record);
    }

    @Operation(summary = "查询历史交班对账凭单列表")
    @GetMapping("/records")
    public ApiResponse<List<ShiftRecord>> getShiftRecords() {
        return ApiResponse.success(shiftRecordRepository.findByStoreIdOrderByCreatedAtDesc(TenantContext.getStoreId()));
    }
}
