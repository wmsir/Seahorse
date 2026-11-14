package com.seahorse.store.interfaces.web;

import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.billing.enums.BillingStatus;
import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.commission.model.CommissionRecord;
import com.seahorse.store.domain.session.enums.SessionStatus;
import com.seahorse.store.domain.session.enums.SpaceStatus;
import com.seahorse.store.domain.session.model.ServiceSpace;
import com.seahorse.store.infrastructure.repository.*;
import com.seahorse.store.interfaces.web.vo.DashboardStatsVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Arrays;
import java.util.List;

/**
 * 智慧门店经营大屏看板控制器
 * 符合阿里巴巴与DDD规范：类型安全、无魔法值、显式VO结构
 */
@Tag(name = "09. 智慧门店大屏与统计看板", description = "今日实收、空间开台占用率、会员活跃度与员工提成排名")
@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final BillingOrderRepository billingOrderRepository;
    private final ServiceSpaceRepository spaceRepository;
    private final ServiceSessionRepository sessionRepository;
    private final MemberRepository memberRepository;
    private final CommissionRecordRepository commissionRecordRepository;
    private final AppointmentRepository appointmentRepository;
    private final StoreRepository storeRepository;
    private final EmployeeRepository employeeRepository;

    @Operation(summary = "获取今日经营核心看板数据 (支持指定门店 storeId)")
    @GetMapping("/stats")
    public ApiResponse<DashboardStatsVO> getStats(@org.springframework.web.bind.annotation.RequestParam(value = "storeId", required = false) String storeId) {
        String targetStoreId = (storeId != null && !storeId.trim().isEmpty()) ? storeId.trim() : TenantContext.getStoreId();
        if (targetStoreId == null || targetStoreId.trim().isEmpty()) {
            targetStoreId = "S001";
        }

        String targetTenantId = storeRepository.findByStoreId(targetStoreId)
                .map(com.seahorse.store.domain.iam.model.Store::getTenantId)
                .filter(t -> t != null && !t.trim().isEmpty())
                .orElseGet(() -> {
                    String ctxTid = TenantContext.getTenantId();
                    return (ctxTid != null && !ctxTid.trim().isEmpty() && !"PLATFORM".equalsIgnoreCase(ctxTid)) ? ctxTid : "T001";
                });

        LocalDateTime todayStart = LocalDateTime.of(LocalDate.now(), LocalTime.MIN);
        LocalDateTime todayEnd = LocalDateTime.now();

        List<BillingOrder> todayOrders = billingOrderRepository.findByStoreIdAndSettledAtBetween(targetStoreId, todayStart, todayEnd);

        BigDecimal todayRevenue = todayOrders.stream()
                .filter(o -> o.getStatus() == BillingStatus.PAID)
                .map(BillingOrder::getActualAmount)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        List<ServiceSpace> spaces = spaceRepository.findByTenantIdAndStoreId(targetTenantId, targetStoreId);
        if (spaces.isEmpty()) {
            spaces = spaceRepository.findByStoreId(targetStoreId);
        }
        long totalSpaces = spaces.size();
        long occupiedSpaces = spaces.stream().filter(s -> s.getStatus() == SpaceStatus.OCCUPIED).count();
        long dirtySpaces = spaces.stream().filter(s -> s.getStatus() == SpaceStatus.DIRTY).count();

        long activeSessions = sessionRepository.findByStoreIdAndStatusIn(
                targetStoreId, Arrays.asList(SessionStatus.OCCUPIED_ORDERING, SessionStatus.SERVING, SessionStatus.SETTLING)).size();

        long totalMembers = memberRepository.countByTenantId(targetTenantId);

        List<CommissionRecord> commissions = commissionRecordRepository.findByStoreIdAndCreatedAtBetween(targetStoreId, todayStart, todayEnd);
        BigDecimal todayCommissions = commissions.stream()
                .map(CommissionRecord::getCommissionAmount)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 真实查询今日待履约预约 (非 CANCELLED, 非 COMPLETED)
        List<com.seahorse.store.domain.appointment.model.Appointment> todayApts = 
                appointmentRepository.findByStoreIdAndAptDate(targetStoreId, LocalDate.now().toString());
        long pendingAppointments = todayApts.stream()
                .filter(a -> "PENDING".equalsIgnoreCase(a.getStatus()) || "CONFIRMED".equalsIgnoreCase(a.getStatus()))
                .count();

        // 真实今日服务客流 (已结单订单数 + 履约中会话数)
        long todayCustomers = (long) todayOrders.size() + activeSessions;

        // 真实查询当前商户及门店在册与在岗员工数（排除软删除与平台管理员）
        final String storeIdFilter = targetStoreId;
        List<com.seahorse.store.domain.iam.model.Employee> allStaff = employeeRepository.findByTenantId(targetTenantId);
        List<com.seahorse.store.domain.iam.model.Employee> activeStaff = allStaff.stream()
                .filter(e -> !Boolean.TRUE.equals(e.getIsDeleted()))
                .filter(e -> e.getRole() != com.seahorse.store.domain.iam.enums.EmployeeRole.PLATFORM_DEVELOPER)
                .filter(e -> !"admin".equalsIgnoreCase(e.getUsername()))
                .filter(e -> e.getRealName() == null || !e.getRealName().contains("开发维护人"))
                .filter(e -> storeIdFilter == null || storeIdFilter.trim().isEmpty() || storeIdFilter.equals(e.getStoreId()))
                .toList();
        long totalStaffCount = activeStaff.size();
        long activeStaffCount = totalStaffCount;

        DashboardStatsVO vo = DashboardStatsVO.builder()
                .todayRevenue(todayRevenue)
                .todayOrderCount(todayOrders.size())
                .totalSpaces(totalSpaces)
                .occupiedSpaces(occupiedSpaces)
                .servingCount(occupiedSpaces)
                .dirtyCount(dirtySpaces)
                .spaceUtilizationRate(totalSpaces > 0 ? (double) occupiedSpaces / totalSpaces * 100 : 0.0)
                .activeSessions(activeSessions)
                .totalMembers(totalMembers)
                .todayCommissions(todayCommissions)
                .pendingAppointments(pendingAppointments)
                .todayCustomers(todayCustomers)
                .totalStaffCount(totalStaffCount)
                .activeStaffCount(activeStaffCount)
                .build();

        return ApiResponse.success(vo);
    }
}
