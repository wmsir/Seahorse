package com.seahorse.store.interfaces.web;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.iam.enums.EmployeeRole;
import com.seahorse.store.domain.iam.model.Employee;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.leave.model.LeaveApplication;
import com.seahorse.store.infrastructure.repository.EmployeeRepository;
import com.seahorse.store.infrastructure.repository.LeaveApplicationRepository;
import com.seahorse.store.infrastructure.repository.StoreRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 员工请假申请与审批流控制器 (基于 MySQL 真实持久化与多端实时同步)
 */
@Slf4j
@Tag(name = "15. 员工请假与审批流", description = "员工请假发起、多级审批与全流程跟踪")
@RestController
@RequestMapping("/api/leave")
@RequiredArgsConstructor
public class LeaveApplicationController {

    private final LeaveApplicationRepository leaveApplicationRepository;
    private final StoreRepository storeRepository;
    private final EmployeeRepository employeeRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Data
    public static class LeaveApplicationDTO {
        private String id;
        private Long staffId;
        private String staffName;
        private String phone;
        private String postName;
        private String department;
        private String leaveType; // PERSONAL | SICK | ANNUAL | REST | MATERNITY
        private String leaveTypeName;
        private String startTime;
        private String endTime;
        private Double totalHours;
        private Double totalDays;
        private String reason;
        private String status; // PENDING | APPROVED | REJECTED | REVOKED
        private String applyTime;
        private String currentApprover;
        private String auditTime;
        private String auditNotes;
        private List<AuditTimelineNode> timeline;
    }

    @Data
    public static class AuditTimelineNode {
        private String stepName;
        private String operator;
        private String time;
        private String status; // SUCCESS | CURRENT | PENDING | REJECTED
        private String comment;
    }

    @Data
    public static class ApplyLeaveCommand {
        private Long staffId;
        private String staffName;
        private String phone;
        private String postName;
        private String department;
        private String leaveType;
        private String startTime;
        private String endTime;
        private Double totalHours;
        private Double totalDays;
        private String reason;
    }

    @Data
    public static class AuditLeaveCommand {
        private String leaveId;
        private String action; // APPROVE | REJECT
        private String auditNotes;
        private String approver;
    }

    @Data
    public static class RevokeLeaveCommand {
        private String leaveId;
        private String reason;
        private String operator;
    }

    @Data
    public static class UpdateLeaveCommand {
        private String leaveId;
        private String leaveType;
        private String startTime;
        private String endTime;
        private Double totalHours;
        private Double totalDays;
        private String reason;
    }

    @Operation(summary = "查询员工请假单据列表")
    @GetMapping("/list")
    public ApiResponse<List<LeaveApplicationDTO>> getLeaveList(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String phone,
            @RequestParam(required = false) String tenantId) {
        String effTenantId = TenantContext.getTenantId();
        if (tenantId != null && !tenantId.trim().isEmpty()) {
            if (!TenantContext.isPlatformAdmin()) {
                TenantContext.assertTenantAccess(tenantId.trim());
            }
            effTenantId = tenantId.trim();
        }
        String storeId = TenantContext.getStoreId();
        if ((effTenantId == null || effTenantId.trim().isEmpty() || "T001".equalsIgnoreCase(effTenantId))
                && storeId != null && !storeId.trim().isEmpty() && !"S001".equalsIgnoreCase(storeId)) {
            Optional<Store> sOpt = storeRepository.findByStoreId(storeId.trim());
            if (sOpt.isPresent() && sOpt.get().getTenantId() != null) {
                TenantContext.assertTenantAccess(sOpt.get().getTenantId());
                effTenantId = sOpt.get().getTenantId();
            }
        }
        if (effTenantId == null || effTenantId.trim().isEmpty()) {
            effTenantId = "T001";
        }

        boolean canQueryGlobal = TenantContext.isPlatformAdmin();
        List<LeaveApplication> entities;
        if (canQueryGlobal && ("PLATFORM".equalsIgnoreCase(effTenantId) || "ALL".equalsIgnoreCase(effTenantId))) {
            entities = leaveApplicationRepository.findAllByOrderByCreatedAtDesc();
        } else {
            if ("PLATFORM".equalsIgnoreCase(effTenantId) || "ALL".equalsIgnoreCase(effTenantId)) {
                effTenantId = "T001";
            }
            entities = new ArrayList<>(leaveApplicationRepository.findByTenantIdOrderByCreatedAtDesc(effTenantId));
            // 补充关联当前租户门店的单据（保证跨端多门店同步）
            List<Store> stores = storeRepository.findByTenantId(effTenantId);
            Set<String> storeIds = stores.stream()
                    .map(Store::getStoreId)
                    .filter(sid -> sid != null && !sid.trim().isEmpty())
                    .collect(Collectors.toCollection(LinkedHashSet::new));
            if (!storeIds.isEmpty()) {
                Set<String> ids = entities.stream().map(LeaveApplication::getId).collect(Collectors.toSet());
                List<LeaveApplication> storeLeaves = leaveApplicationRepository.findByStoreIdInOrderByCreatedAtDesc(storeIds);
                for (LeaveApplication sl : storeLeaves) {
                    if (!ids.contains(sl.getId())) {
                        entities.add(sl);
                        ids.add(sl.getId());
                    }
                }
            }
        }

        // 过滤 status、phone 与 keyword
        List<LeaveApplicationDTO> list = entities.stream()
                .map(this::toDTO)
                .filter(l -> {
                    if (status != null && !status.trim().isEmpty() && !"ALL".equalsIgnoreCase(status.trim())) {
                        if (!status.trim().equalsIgnoreCase(l.getStatus())) return false;
                    }
                    if (phone != null && !phone.trim().isEmpty()) {
                        if (!phone.trim().equals(l.getPhone())) return false;
                    }
                    if (keyword != null && !keyword.trim().isEmpty()) {
                        String kw = keyword.trim().toLowerCase();
                        boolean matchName = l.getStaffName() != null && l.getStaffName().toLowerCase().contains(kw);
                        boolean matchReason = l.getReason() != null && l.getReason().toLowerCase().contains(kw);
                        boolean matchPost = l.getPostName() != null && l.getPostName().toLowerCase().contains(kw);
                        boolean matchPhone = l.getPhone() != null && l.getPhone().contains(kw);
                        boolean matchId = l.getId() != null && l.getId().toLowerCase().contains(kw);
                        if (!matchName && !matchReason && !matchPost && !matchPhone && !matchId) return false;
                    }
                    return true;
                })
                .toList();

        return ApiResponse.success(list);
    }

    @Operation(summary = "员工发起请假申请")
    @PostMapping("/apply")
    public ApiResponse<LeaveApplicationDTO> applyLeave(@RequestBody ApplyLeaveCommand cmd) {
        String tenantId = TenantContext.getTenantId();
        String storeId = TenantContext.getStoreId();
        if ((tenantId == null || tenantId.trim().isEmpty() || "T001".equalsIgnoreCase(tenantId))
                && storeId != null && !storeId.trim().isEmpty() && !"S001".equalsIgnoreCase(storeId)) {
            Optional<Store> sOpt = storeRepository.findByStoreId(storeId.trim());
            if (sOpt.isPresent() && sOpt.get().getTenantId() != null) {
                tenantId = sOpt.get().getTenantId();
            }
        }
        if (tenantId == null || tenantId.trim().isEmpty() || "PLATFORM".equalsIgnoreCase(tenantId)) {
            tenantId = "T001";
        }

        String nowStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
        String targetStoreId = (storeId != null && !storeId.trim().isEmpty()) ? storeId.trim() : "S001";
        String managerName = resolveStoreManagerName(targetStoreId, tenantId);

        LeaveApplication entity = LeaveApplication.builder()
                .id("LV-" + System.currentTimeMillis())
                .tenantId(tenantId)
                .storeId(targetStoreId)
                .staffId(cmd.getStaffId() != null ? cmd.getStaffId() : 2L)
                .staffName(cmd.getStaffName() != null ? cmd.getStaffName() : "员工")
                .phone(cmd.getPhone() != null ? cmd.getPhone() : "")
                .postName(cmd.getPostName() != null ? cmd.getPostName() : "员工")
                .department(cmd.getDepartment() != null ? cmd.getDepartment() : "门店运营组")
                .leaveType(cmd.getLeaveType() != null ? cmd.getLeaveType() : "PERSONAL")
                .leaveTypeName(getLeaveTypeName(cmd.getLeaveType()))
                .startTime(cmd.getStartTime())
                .endTime(cmd.getEndTime())
                .totalHours(cmd.getTotalHours() != null ? cmd.getTotalHours() : 8.0)
                .totalDays(cmd.getTotalDays() != null ? cmd.getTotalDays() : 1.0)
                .reason(cmd.getReason() != null ? cmd.getReason() : "个人事务处理")
                .status("PENDING")
                .applyTime(nowStr)
                .currentApprover(managerName)
                .build();

        List<AuditTimelineNode> nodes = new ArrayList<>();
        AuditTimelineNode n1 = new AuditTimelineNode();
        n1.setStepName("提交请假申请");
        n1.setOperator(entity.getStaffName());
        n1.setTime(nowStr);
        n1.setStatus("SUCCESS");
        n1.setComment("已提交请假申请，事由：" + entity.getReason());
        nodes.add(n1);

        AuditTimelineNode n2 = new AuditTimelineNode();
        n2.setStepName("门店店长初审");
        n2.setOperator(managerName);
        n2.setStatus("CURRENT");
        n2.setComment("待审批处理中");
        nodes.add(n2);

        try {
            entity.setTimelineJson(objectMapper.writeValueAsString(nodes));
        } catch (Exception e) {
            log.warn("write timelineJson error", e);
        }

        entity = leaveApplicationRepository.save(entity);
        log.info("【请假申请成功】单号={}, 员工={}, 门店={}, 租户={}, 审批人={}",
                entity.getId(), entity.getStaffName(), entity.getStoreId(), entity.getTenantId(), managerName);

        return ApiResponse.success("请假申请已提交，等待主管审批", toDTO(entity));
    }

    @Operation(summary = "主管或店长审批请假申请")
    @PostMapping("/audit")
    public ApiResponse<LeaveApplicationDTO> auditLeave(@RequestBody AuditLeaveCommand cmd) {
        TenantContext.assertTenantAdmin();
        if (cmd == null || cmd.getLeaveId() == null || cmd.getLeaveId().trim().isEmpty()) {
            return ApiResponse.error(400, "请假单号不能为空");
        }
        Optional<LeaveApplication> targetOpt = leaveApplicationRepository.findById(cmd.getLeaveId());
        if (targetOpt.isEmpty()) {
            return ApiResponse.error(404, "请假单据不存在");
        }

        LeaveApplication app = targetOpt.get();
        TenantContext.assertTenantAccess(app.getTenantId());
        // 业务规则防呆：员工不得自行审批本人发起的请假申请（含登录账号校验与审批人姓名校验）
        Long currentUserId = TenantContext.getUserId();
        String currentUsername = TenantContext.getUsername();
        if ((app.getStaffId() != null && currentUserId != null && app.getStaffId().equals(currentUserId))
                || (app.getPhone() != null && !app.getPhone().isEmpty() && app.getPhone().equals(currentUsername))) {
            return ApiResponse.error(403, "权限受限：员工不可自行审批本人发起的请假申请！请联系上级主管或管理员审批。");
        }
        String approverName = cmd.getApprover() != null ? cmd.getApprover().trim() : "";
        if (!approverName.isEmpty() && app.getStaffName() != null && approverName.contains(app.getStaffName())) {
            return ApiResponse.error(400, "权限受限：员工不可自行审批本人发起的请假申请！请联系主管或店长审批。");
        }

        boolean isApprove = "APPROVE".equalsIgnoreCase(cmd.getAction());
        String nowStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));

        // 动态解析真实审批人
        String actualApprover = null;
        if (cmd.getApprover() != null && !cmd.getApprover().trim().isEmpty() 
                && !"张建华 (店长)".equals(cmd.getApprover().trim())) {
            actualApprover = cmd.getApprover().trim();
        } else {
            String loginUser = TenantContext.getUsername();
            if (loginUser != null && !loginUser.trim().isEmpty()) {
                Optional<Employee> empOpt = employeeRepository.findByUsername(loginUser.trim());
                if (empOpt.isEmpty()) {
                    List<Employee> pList = employeeRepository.findByPhone(loginUser.trim());
                    if (!pList.isEmpty()) empOpt = Optional.of(pList.get(0));
                }
                if (empOpt.isPresent()) {
                    Employee emp = empOpt.get();
                    String name = emp.getRealName() != null && !emp.getRealName().trim().isEmpty() 
                            ? emp.getRealName().trim() 
                            : (emp.getUsername() != null ? emp.getUsername() : emp.getPhone());
                    String roleTitle = (emp.getRole() == EmployeeRole.SUPER_ADMIN || emp.getRole() == EmployeeRole.PLATFORM_DEVELOPER) ? "总负责人/老板" : "店长";
                    actualApprover = name + " (" + roleTitle + ")";
                }
            }
            if (actualApprover == null || actualApprover.trim().isEmpty()) {
                actualApprover = resolveStoreManagerName(app.getStoreId(), app.getTenantId());
            }
        }

        app.setStatus(isApprove ? "APPROVED" : "REJECTED");
        app.setAuditTime(nowStr);
        app.setAuditNotes(cmd.getAuditNotes() != null ? cmd.getAuditNotes() : (isApprove ? "同意请假，请提前交接好岗位在手客户" : "驳回申请"));
        app.setCurrentApprover(actualApprover);

        List<AuditTimelineNode> nodes = parseTimeline(app.getTimelineJson());
        if (nodes != null && nodes.size() >= 2) {
            AuditTimelineNode node2 = nodes.get(1);
            node2.setOperator(actualApprover); // 同步更新流转时间线中的真实审批人
            node2.setTime(nowStr);
            node2.setStatus(isApprove ? "SUCCESS" : "REJECTED");
            node2.setComment(app.getAuditNotes());

            if (isApprove && nodes.size() >= 3) {
                AuditTimelineNode node3 = nodes.get(2);
                node3.setTime(nowStr);
                node3.setStatus("SUCCESS");
                node3.setComment("系统自动归档考勤工时扣减");
            }
            try {
                app.setTimelineJson(objectMapper.writeValueAsString(nodes));
            } catch (Exception e) {
                log.warn("write timelineJson error", e);
            }
        }

        app = leaveApplicationRepository.save(app);
        return ApiResponse.success(isApprove ? "请假审批已通过！" : "请假审批已驳回！", toDTO(app));
    }

    private String resolveStoreManagerName(String storeId, String tenantId) {
        if (storeId != null && !storeId.trim().isEmpty()) {
            List<Employee> list = employeeRepository.findByStoreIdAndRole(storeId.trim(), EmployeeRole.STORE_MANAGER);
            if (list != null && !list.isEmpty()) {
                Employee m = list.get(0);
                String name = m.getRealName() != null && !m.getRealName().trim().isEmpty() 
                        ? m.getRealName().trim() 
                        : (m.getUsername() != null ? m.getUsername() : m.getPhone());
                return name + " (店长)";
            }
            List<Employee> all = employeeRepository.findByStoreIdAndIsDeleted(storeId.trim(), false);
            for (Employee e : all) {
                if (e.getRole() == EmployeeRole.STORE_MANAGER || (e.getPostName() != null && e.getPostName().contains("店长"))) {
                    String name = e.getRealName() != null && !e.getRealName().trim().isEmpty() 
                            ? e.getRealName().trim() 
                            : (e.getUsername() != null ? e.getUsername() : e.getPhone());
                    return name + " (店长)";
                }
            }
            Optional<Store> sOpt = storeRepository.findByStoreId(storeId.trim());
            if (sOpt.isPresent() && sOpt.get().getStoreName() != null) {
                return sOpt.get().getStoreName() + "店长";
            }
        }
        return "店长/主管";
    }

    @Operation(summary = "员工撤销/撤回请假申请")
    @PostMapping("/revoke")
    public ApiResponse<LeaveApplicationDTO> revokeLeave(@RequestBody RevokeLeaveCommand cmd) {
        if (cmd == null || cmd.getLeaveId() == null || cmd.getLeaveId().trim().isEmpty()) {
            return ApiResponse.error(400, "请假单号不能为空");
        }
        Optional<LeaveApplication> targetOpt = leaveApplicationRepository.findById(cmd.getLeaveId());
        if (targetOpt.isEmpty()) {
            return ApiResponse.error(404, "请假单据不存在");
        }

        LeaveApplication app = targetOpt.get();
        TenantContext.assertTenantAccess(app.getTenantId());
        if ("APPROVED".equalsIgnoreCase(app.getStatus())) {
            return ApiResponse.error(400, "已通过的请假不可直接撤回，请走销假流程");
        }

        String nowStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
        app.setStatus("REVOKED");
        app.setAuditTime(nowStr);
        app.setAuditNotes("员工主动撤回申请" + (cmd.getReason() != null ? "：" + cmd.getReason() : ""));

        List<AuditTimelineNode> nodes = parseTimeline(app.getTimelineJson());
        AuditTimelineNode node = new AuditTimelineNode();
        node.setStepName("撤回申请");
        node.setOperator(cmd.getOperator() != null ? cmd.getOperator() : app.getStaffName());
        node.setTime(nowStr);
        node.setStatus("SUCCESS");
        node.setComment(app.getAuditNotes());
        nodes.add(node);

        try {
            app.setTimelineJson(objectMapper.writeValueAsString(nodes));
        } catch (Exception e) {
            log.warn("write timelineJson error", e);
        }

        app = leaveApplicationRepository.save(app);
        return ApiResponse.success("请假申请已撤回", toDTO(app));
    }

    @Operation(summary = "编辑修改并重新提交请假申请")
    @PostMapping("/update")
    public ApiResponse<LeaveApplicationDTO> updateLeave(@RequestBody UpdateLeaveCommand cmd) {
        if (cmd == null || cmd.getLeaveId() == null || cmd.getLeaveId().trim().isEmpty()) {
            return ApiResponse.error(400, "请假单号不能为空");
        }
        Optional<LeaveApplication> targetOpt = leaveApplicationRepository.findById(cmd.getLeaveId());
        if (targetOpt.isEmpty()) {
            return ApiResponse.error(404, "请假单据不存在");
        }

        LeaveApplication app = targetOpt.get();
        TenantContext.assertTenantAccess(app.getTenantId());
        if ("APPROVED".equalsIgnoreCase(app.getStatus())) {
            return ApiResponse.error(400, "已审核通过的假单不可直接修改");
        }

        if (cmd.getLeaveType() != null) {
            app.setLeaveType(cmd.getLeaveType());
            app.setLeaveTypeName(getLeaveTypeName(cmd.getLeaveType()));
        }
        if (cmd.getStartTime() != null) app.setStartTime(cmd.getStartTime());
        if (cmd.getEndTime() != null) app.setEndTime(cmd.getEndTime());
        if (cmd.getTotalHours() != null) app.setTotalHours(cmd.getTotalHours());
        if (cmd.getTotalDays() != null) app.setTotalDays(cmd.getTotalDays());
        if (cmd.getReason() != null) app.setReason(cmd.getReason());

        String nowStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
        app.setStatus("PENDING");
        app.setApplyTime(nowStr);
        app.setAuditTime(null);
        app.setAuditNotes(null);

        List<AuditTimelineNode> nodes = parseTimeline(app.getTimelineJson());
        AuditTimelineNode node = new AuditTimelineNode();
        node.setStepName("重新编辑提交");
        node.setOperator(app.getStaffName());
        node.setTime(nowStr);
        node.setStatus("SUCCESS");
        node.setComment("更新请假时间与事由，重新提交审批");
        nodes.add(node);

        try {
            app.setTimelineJson(objectMapper.writeValueAsString(nodes));
        } catch (Exception e) {
            log.warn("write timelineJson error", e);
        }

        app = leaveApplicationRepository.save(app);
        return ApiResponse.success("请假申请已重新提交，等待审批", toDTO(app));
    }

    @Operation(summary = "清空员工请假记录脏数据")
    @PostMapping("/clean")
    public ApiResponse<Void> cleanLeaves() {
        TenantContext.assertTenantAdmin();
        String tenantId = TenantContext.getTenantId();
        if (tenantId == null) tenantId = "T001";
        TenantContext.assertTenantAccess(tenantId);
        List<LeaveApplication> list = leaveApplicationRepository.findByTenantIdOrderByCreatedAtDesc(tenantId);
        leaveApplicationRepository.deleteAll(list);
        return ApiResponse.success("请假单据已全部清空", null);
    }

    private List<AuditTimelineNode> parseTimeline(String json) {
        if (json == null || json.trim().isEmpty()) {
            return new ArrayList<>();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<AuditTimelineNode>>() {});
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    private LeaveApplicationDTO toDTO(LeaveApplication entity) {
        LeaveApplicationDTO dto = new LeaveApplicationDTO();
        dto.setId(entity.getId());
        dto.setStaffId(entity.getStaffId());
        dto.setStaffName(entity.getStaffName());
        dto.setPhone(entity.getPhone());
        dto.setPostName(entity.getPostName());
        dto.setDepartment(entity.getDepartment());
        dto.setLeaveType(entity.getLeaveType());
        dto.setLeaveTypeName(entity.getLeaveTypeName());
        dto.setStartTime(entity.getStartTime());
        dto.setEndTime(entity.getEndTime());
        dto.setTotalHours(entity.getTotalHours());
        dto.setTotalDays(entity.getTotalDays());
        dto.setReason(entity.getReason());
        dto.setStatus(entity.getStatus());
        dto.setApplyTime(entity.getApplyTime());
        dto.setCurrentApprover(entity.getCurrentApprover());
        dto.setAuditTime(entity.getAuditTime());
        dto.setAuditNotes(entity.getAuditNotes());
        dto.setTimeline(parseTimeline(entity.getTimelineJson()));
        return dto;
    }

    private String getLeaveTypeName(String type) {
        if (type == null) return "事假";
        switch (type) {
            case "PERSONAL": return "事假";
            case "SICK": return "病假";
            case "ANNUAL": return "带薪年假";
            case "REST":
            case "COMPENSATORY": return "加班调休";
            case "MARRIAGE": return "婚假";
            case "MATERNITY": return "产假/陪产假";
            default: return "其他请假";
        }
    }
}
