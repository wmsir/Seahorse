package com.seahorse.store.interfaces.web.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "门店今日经营综合统计看板 VO")
public class DashboardStatsVO {
    @Schema(description = "今日实收总营收 (元)", example = "3580.00")
    private BigDecimal todayRevenue;

    @Schema(description = "今日结账订单总数", example = "18")
    private Integer todayOrderCount;

    @Schema(description = "门店总工位/桌台数", example = "12")
    private Long totalSpaces;

    @Schema(description = "当前在场服务占用工位数", example = "5")
    private Long occupiedSpaces;

    @Schema(description = "空间在场利用率 (%)", example = "41.67")
    private Double spaceUtilizationRate;

    @Schema(description = "当前活跃履约中会话数", example = "5")
    private Long activeSessions;

    @Schema(description = "海马私域会员总量", example = "328")
    private Long totalMembers;

    @Schema(description = "今日技师/员工施工与服务提成总额 (元)", example = "685.50")
    private BigDecimal todayCommissions;

    @Schema(description = "服务中工位数")
    private Long servingCount;

    @Schema(description = "待清台复位工位数")
    private Long dirtyCount;

    @Schema(description = "今日预约待到店数量", example = "3")
    private Long pendingAppointments;

    @Schema(description = "今日接待客流人次", example = "48")
    private Long todayCustomers;

    @Schema(description = "门店在册员工总数", example = "4")
    private Long totalStaffCount;

    @Schema(description = "今日在岗/出勤员工数", example = "3")
    private Long activeStaffCount;
}
