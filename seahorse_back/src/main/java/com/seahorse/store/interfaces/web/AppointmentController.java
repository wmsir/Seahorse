package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.dto.session.OpenSessionCommand;
import com.seahorse.store.application.service.ServiceSessionAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.appointment.model.Appointment;
import com.seahorse.store.domain.session.enums.SessionStatus;
import com.seahorse.store.domain.session.enums.SpaceStatus;
import com.seahorse.store.domain.session.model.ServiceSession;
import com.seahorse.store.domain.session.model.ServiceSpace;
import com.seahorse.store.infrastructure.repository.AppointmentRepository;
import com.seahorse.store.infrastructure.repository.ServiceSessionRepository;
import com.seahorse.store.infrastructure.repository.ServiceSpaceRepository;
import com.seahorse.store.infrastructure.repository.StoreRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

@Slf4j
@Tag(name = "08. 预约排班管理", description = "顾客预约登记、排班查询、到店核销履约与展位联动")
@RestController
@RequestMapping("/api/appointment")
@RequiredArgsConstructor
public class AppointmentController {

    private final AppointmentRepository appointmentRepository;
    private final ServiceSessionAppService sessionAppService;
    private final ServiceSpaceRepository spaceRepository;
    private final ServiceSessionRepository sessionRepository;
    private final StoreRepository storeRepository;

    @Operation(summary = "查询预约排班列表（支持单日 date 或区间 startDate~endDate）")
    @GetMapping("/list")
    public ApiResponse<List<Appointment>> getAppointments(
            @RequestParam(value = "storeId", required = false) String storeId,
            @RequestParam(value = "date", required = false) String date,
            @RequestParam(value = "startDate", required = false) String startDate,
            @RequestParam(value = "endDate", required = false) String endDate) {
        if (!TenantContext.isAuthenticated()) {
            return ApiResponse.error(401, "请先登录");
        }

        String currentStoreId = (storeId != null && !storeId.trim().isEmpty())
                ? storeId.trim()
                : (TenantContext.getStoreId() != null && !TenantContext.getStoreId().trim().isEmpty() ? TenantContext.getStoreId() : "S001");
        storeRepository.findByStoreId(currentStoreId)
                .ifPresent(s -> TenantContext.assertTenantAccess(s.getTenantId()));

        List<Appointment> rawList;
        if (startDate != null && !startDate.trim().isEmpty()
                && endDate != null && !endDate.trim().isEmpty()) {
            rawList = appointmentRepository
                    .findByStoreIdAndAptDateBetweenOrderByAptDateAscAptTimeAsc(currentStoreId, startDate.trim(), endDate.trim());
        } else {
            String targetDate = (date != null && !date.trim().isEmpty()) ? date.trim() : LocalDate.now().toString();
            rawList = appointmentRepository.findByStoreIdAndAptDate(currentStoreId, targetDate);
        }
        String currentTenant = TenantContext.getTenantId();
        List<Appointment> filtered = TenantContext.isPlatformAdmin()
                ? rawList
                : rawList.stream().filter(a -> a.getTenantId() == null || currentTenant.equalsIgnoreCase(a.getTenantId())).toList();
        return ApiResponse.success(filtered);
    }

    @Operation(summary = "登记新顾客预约排班")
    @PostMapping("/create")
    public ApiResponse<Appointment> createAppointment(@RequestBody Appointment appointment) {
        String storeId = (appointment.getStoreId() != null && !appointment.getStoreId().trim().isEmpty())
                ? appointment.getStoreId().trim() : (TenantContext.getStoreId() != null ? TenantContext.getStoreId() : "S001");
        String resolvedStoreTenant = storeRepository.findByStoreId(storeId)
                .map(com.seahorse.store.domain.iam.model.Store::getTenantId)
                .orElse(null);
        String tenantId = resolvedStoreTenant != null && !resolvedStoreTenant.trim().isEmpty()
                ? resolvedStoreTenant.trim()
                : (TenantContext.getTenantId() != null ? TenantContext.getTenantId() : "T001");
        if (TenantContext.isAuthenticated()) {
            TenantContext.assertTenantAccess(tenantId);
        }

        appointment.setTenantId(tenantId);
        appointment.setStoreId(storeId);
        if (appointment.getAptNo() == null || appointment.getAptNo().trim().isEmpty()) {
            appointment.setAptNo("APT" + System.currentTimeMillis() + (int)(Math.random() * 900 + 100));
        }
        if (!TenantContext.isAuthenticated() || appointment.getStatus() == null || appointment.getStatus().trim().isEmpty()) {
            appointment.setStatus("PENDING");
        }
        if (appointment.getAptDate() == null || appointment.getAptDate().trim().isEmpty()) {
            appointment.setAptDate(LocalDate.now().toString());
        }

        Appointment saved = appointmentRepository.save(appointment);
        return ApiResponse.success("预约登记成功", saved);
    }

    @Operation(summary = "顾客到店核销/接待入座开台 (预约与展位均变服务中)")
    @PostMapping("/{id}/check-in")
    public ApiResponse<Map<String, Object>> checkInAppointment(
            @PathVariable("id") Long id,
            @RequestBody(required = false) Map<String, Object> body) {

        Appointment apt = appointmentRepository.findById(id).orElse(null);
        if (apt == null && body != null && body.containsKey("aptNo")) {
            apt = appointmentRepository.findByAptNo(String.valueOf(body.get("aptNo"))).orElse(null);
        }
        if (apt == null) {
            apt = appointmentRepository.findByAptNo("APT" + id).orElse(null);
        }
        if (apt == null) {
            return ApiResponse.error(404, "未找到该预约记录");
        }
        TenantContext.assertTenantAccess(apt.getTenantId());

        String tenantId = apt.getTenantId() != null ? apt.getTenantId() : "T001";
        String storeId = apt.getStoreId() != null ? apt.getStoreId() : "S001";

        Long targetSpaceId = null;
        if (body != null && body.containsKey("spaceId") && body.get("spaceId") != null) {
            try {
                targetSpaceId = Long.valueOf(body.get("spaceId").toString());
            } catch (Exception ignored) {}
        }

        ServiceSpace targetSpace = null;
        if (targetSpaceId != null) {
            targetSpace = spaceRepository.findById(targetSpaceId).orElse(null);
        }

        if (targetSpace == null && apt.getSpaceCode() != null) {
            targetSpace = spaceRepository.findByStoreIdAndSpaceCode(storeId, apt.getSpaceCode()).orElse(null);
        }

        if (targetSpace == null) {
            List<ServiceSpace> idleSpaces = spaceRepository.findByStoreIdAndStatus(storeId, SpaceStatus.IDLE);
            if (!idleSpaces.isEmpty()) {
                targetSpace = idleSpaces.get(0);
            } else {
                List<ServiceSpace> allSpaces = spaceRepository.findByTenantIdAndStoreId(tenantId, storeId);
                if (!allSpaces.isEmpty()) {
                    targetSpace = allSpaces.get(0);
                }
            }
        }

        if (targetSpace == null) {
            return ApiResponse.error(400, "当前门店无可用展位/工位，请先在展位管理中配置");
        }

        // 1. 若展位空闲或无关联有效会话，开启新履约会话
        ServiceSession session = null;
        if (targetSpace.getCurrentSessionId() != null) {
            session = sessionRepository.findById(targetSpace.getCurrentSessionId()).orElse(null);
        }

        if (session == null || session.getStatus() == SessionStatus.CLOSED || session.getStatus() == SessionStatus.SETTLED_WAIT_CLEAN) {
            OpenSessionCommand cmd = OpenSessionCommand.builder()
                    .spaceId(targetSpace.getId())
                    .customerName(apt.getCustomerName())
                    .customerPhone(apt.getPhone())
                    .guestCount(apt.getPeopleCount() != null ? apt.getPeopleCount() : 1)
                    .notes((apt.getStaffName() != null ? apt.getStaffName() : "专职技师") + " | " + apt.getServiceName())
                    .build();
            try {
                session = sessionAppService.openSession(cmd);
            } catch (Exception e) {
                log.warn("sessionAppService.openSession fallback: {}", e.getMessage());
                targetSpace.setStatus(SpaceStatus.IDLE);
                targetSpace.setCurrentSessionId(null);
                spaceRepository.save(targetSpace);
                session = sessionAppService.openSession(cmd);
            }
        }

        // 2. 会话状态确认为 SERVING，并附带项目预估金额
        if (session != null) {
            session.setStatus(SessionStatus.SERVING);
            if (apt.getServicePrice() != null && apt.getServicePrice().compareTo(BigDecimal.ZERO) > 0) {
                session.setTotalAmount(apt.getServicePrice());
                session.recalculatePayable();
            }
            sessionRepository.save(session);
        }

        // 3. 展位状态置为 OCCUPIED (服务中)
        targetSpace.setStatus(SpaceStatus.OCCUPIED);
        if (session != null) {
            targetSpace.setCurrentSessionId(session.getId());
        }
        spaceRepository.save(targetSpace);

        // 4. 预约状态置为 SERVING (服务中)
        apt.setStatus("SERVING");
        apt.setSpaceCode(targetSpace.getSpaceCode());
        apt.setSpaceName(targetSpace.getSpaceName());
        appointmentRepository.save(apt);

        Map<String, Object> result = new HashMap<>();
        result.put("appointment", apt);
        result.put("session", session);
        result.put("space", targetSpace);

        return ApiResponse.success("顾客到店接待成功，展位与预约已变为【服务中】！", result);
    }

    @Operation(summary = "更新预约排班状态 (如核销到店、开始服务、完成服务)")
    @PostMapping("/{id}/status")
    public ApiResponse<Appointment> updateStatus(@PathVariable("id") Long id, @RequestBody(required = false) Map<String, String> body) {
        String newStatus = body != null ? body.get("status") : null;
        Appointment apt = appointmentRepository.findById(id).orElse(null);
        if (apt == null && body != null && body.containsKey("aptNo")) {
            apt = appointmentRepository.findByAptNo(body.get("aptNo")).orElse(null);
        }
        if (apt == null) {
            apt = appointmentRepository.findByAptNo("APT" + id).orElse(null);
        }
        if (apt == null) {
            return ApiResponse.error(404, "未找到该预约记录");
        }
        TenantContext.assertTenantAccess(apt.getTenantId());

        if (newStatus != null && !newStatus.trim().isEmpty()) {
            String upper = newStatus.toUpperCase();
            apt.setStatus(upper);
            appointmentRepository.save(apt);

            // 若状态变更为 SERVING，且绑定了空间，联动将该空间置为 OCCUPIED
            if ("SERVING".equals(upper) && apt.getSpaceCode() != null) {
                spaceRepository.findByStoreIdAndSpaceCode(apt.getStoreId(), apt.getSpaceCode()).ifPresent(sp -> {
                    if (sp.getStatus() != SpaceStatus.OCCUPIED) {
                        sp.setStatus(SpaceStatus.OCCUPIED);
                        spaceRepository.save(sp);
                    }
                });
            }
        }
        return ApiResponse.success("状态流转成功", apt);
    }

    @Operation(summary = "取消预约（软取消保留历史状态与审计记录）")
    @DeleteMapping("/{id}")
    public ApiResponse<Appointment> deleteAppointment(@PathVariable("id") Long id) {
        Appointment apt = appointmentRepository.findById(id).orElse(null);
        if (apt == null) {
            apt = appointmentRepository.findByAptNo("APT" + id).orElse(null);
        }
        if (apt != null) {
            TenantContext.assertTenantAccess(apt.getTenantId());
            apt.setStatus("CANCELLED");
            Appointment saved = appointmentRepository.save(apt);
            return ApiResponse.success("预约已取消", saved);
        }
        return ApiResponse.error(404, "预约不存在");
    }
}
