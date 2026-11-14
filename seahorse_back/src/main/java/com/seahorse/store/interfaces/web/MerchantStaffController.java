package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.dto.iam.UpdateRolePermissionCommand;
import com.seahorse.store.application.service.PermissionManageAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.iam.enums.EmployeeRole;
import com.seahorse.store.domain.iam.model.Employee;
import com.seahorse.store.domain.iam.model.StaffRewardPunish;
import com.seahorse.store.infrastructure.repository.EmployeeRepository;
import com.seahorse.store.infrastructure.repository.StaffRewardPunishRepository;
import com.seahorse.store.infrastructure.repository.CommissionRecordRepository;
import com.seahorse.store.interfaces.web.vo.PermissionItemVO;
import com.seahorse.store.interfaces.web.vo.RolePermissionVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 门店老板专属：店员组织与角色权限配置控制器
 */
@Tag(name = "09. 门店人员与权限配置", description = "门店老板配置店员角色的查看范围与操作权限")
@RestController
@RequestMapping("/api/merchant/staff")
@RequiredArgsConstructor
public class MerchantStaffController {

    private final PermissionManageAppService permissionManageAppService;
    private final EmployeeRepository employeeRepository;
    private final StaffRewardPunishRepository staffRewardPunishRepository;
    private final CommissionRecordRepository commissionRecordRepository;
    private final com.seahorse.store.infrastructure.repository.TenantSubscriptionRepository subscriptionRepository;
    private final com.seahorse.store.infrastructure.repository.StoreRepository storeRepository;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;
    private final com.seahorse.store.application.service.AuditLogAppService auditLogAppService;
    private final jakarta.servlet.http.HttpServletRequest request;

    @Operation(summary = "获取当前商户旗下店员角色的权限配置列表")
    @GetMapping("/roles-permissions")
    public ApiResponse<List<RolePermissionVO>> getMerchantStaffPermissions() {
        String tenantId = TenantContext.getTenantId();
        return ApiResponse.success(permissionManageAppService.getMerchantStaffPermissions(tenantId));
    }

    @Operation(summary = "门店老板更新指定店员角色的查看配置和操作权限")
    @PutMapping("/roles-permissions/{roleCode}")
    public ApiResponse<RolePermissionVO> updateMerchantStaffPermission(
            @PathVariable EmployeeRole roleCode,
            @RequestBody UpdateRolePermissionCommand cmd) {
        String tenantId = TenantContext.getTenantId();
        RolePermissionVO vo = permissionManageAppService.updateMerchantStaffPermission(tenantId, roleCode, cmd);
        return ApiResponse.success("店员角色权限配置成功", vo);
    }

    @Operation(summary = "获取全部可选功能权限元数据字典")
    @GetMapping("/permissions-metadata")
    public ApiResponse<List<PermissionItemVO>> getPermissionsMetadata() {
        return ApiResponse.success(permissionManageAppService.getAllPermissionMetadata());
    }

    @Operation(summary = "获取当前商户旗下的店员列表（已排除软删除）")
    @GetMapping("/list")
    public ApiResponse<List<Employee>> getStaffList(@RequestParam(value = "storeId", required = false) String storeId) {
        String tenantId = TenantContext.getTenantId();
        String effStoreId = (storeId != null && !storeId.trim().isEmpty()) ? storeId.trim() : TenantContext.getStoreId();

        List<Employee> all;
        if (effStoreId != null && !effStoreId.isEmpty()) {
            all = employeeRepository.findByStoreIdAndIsDeleted(effStoreId, false);
            if (all.isEmpty()) {
                java.util.Optional<com.seahorse.store.domain.iam.model.Store> sOpt = storeRepository.findByStoreId(effStoreId);
                if (sOpt.isPresent() && sOpt.get().getTenantId() != null) {
                    tenantId = sOpt.get().getTenantId();
                }
                all = employeeRepository.findByTenantId(tenantId);
            }
        } else {
            all = employeeRepository.findByTenantId(tenantId);
        }

        List<Employee> active = all.stream()
                .filter(e -> !Boolean.TRUE.equals(e.getIsDeleted()))
                .filter(e -> e.getRole() != EmployeeRole.PLATFORM_DEVELOPER)
                .filter(e -> !"admin".equalsIgnoreCase(e.getUsername()))
                .filter(e -> e.getRealName() == null || !e.getRealName().contains("开发维护人"))
                .filter(e -> effStoreId == null || effStoreId.isEmpty() || effStoreId.equals(e.getStoreId()))
                .toList();
        return ApiResponse.success(active);
    }

    @Operation(summary = "获取已删除的店员列表（支持恢复）")
    @GetMapping("/deleted-list")
    public ApiResponse<List<Employee>> getDeletedStaffList() {
        String tenantId = TenantContext.getTenantId();
        List<Employee> deleted = employeeRepository.findByTenantIdAndIsDeleted(tenantId, true);
        List<Employee> filtered = deleted.stream()
                .filter(e -> e.getRole() != EmployeeRole.PLATFORM_DEVELOPER)
                .filter(e -> !"admin".equalsIgnoreCase(e.getUsername()))
                .filter(e -> e.getRealName() == null || !e.getRealName().contains("开发维护人"))
                .toList();
        return ApiResponse.success(filtered);
    }

    @Operation(summary = "新增店员")
    @PostMapping
    public ApiResponse<Employee> createStaff(@RequestBody Employee staff) {
        String tenantId = TenantContext.getTenantId();
        String storeId = TenantContext.getStoreId();

        // 校验商户套餐员工名额上限
        if (tenantId != null && !"PLATFORM".equalsIgnoreCase(tenantId)) {
            com.seahorse.store.domain.iam.model.TenantSubscription sub = subscriptionRepository.findByTenantId(tenantId).orElse(null);
            int staffLimit = (sub != null && sub.getStaffLimit() != null) ? sub.getStaffLimit() : 3;
            List<Employee> allEmployees = employeeRepository.findByTenantId(tenantId);
            long activeCount = allEmployees.stream()
                    .filter(e -> !Boolean.TRUE.equals(e.getIsDeleted()))
                    .filter(e -> e.getRole() != EmployeeRole.PLATFORM_DEVELOPER && e.getRole() != EmployeeRole.SUPER_ADMIN)
                    .count();
            if (activeCount >= staffLimit) {
                String planName = sub != null && sub.getPlan() != null ? sub.getPlan().getDescription() : "试用版";
                throw new com.seahorse.store.common.ServiceException(
                        String.format("当前【%s】最多允许配置 %d 名员工，您当前在册员工已达上限，如需扩充名额请升级至更高套餐版本！", planName, staffLimit)
                );
            }
        }

        staff.setTenantId(tenantId);
        if (staff.getStoreId() == null) {
            staff.setStoreId(storeId != null ? storeId : "S001");
        }
        if (staff.getUsername() == null || staff.getUsername().trim().isEmpty()) {
            staff.setUsername("u" + (int)((Math.random() * 9 + 1) * 100000));
        }
        staff.setPassword(passwordEncoder.encode("123456"));
        staff.setStatus("ACTIVE");
        staff.setIsDeleted(false);
        if (staff.getRole() == null) {
            staff.setRole(EmployeeRole.TECHNICIAN);
        }
        Employee saved = employeeRepository.save(staff);
        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = TenantContext.getUsername() != null ? TenantContext.getUsername() : "merchant";
        auditLogAppService.recordLog(
                tenantId,
                null,
                saved.getStoreId(),
                null,
                saved.getId(),
                username,
                null,
                "新增门店员工档案",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("新增员工: %s (%s), 角色: %s, 手机号: %s",
                        saved.getRealName(), saved.getPostName() != null ? saved.getPostName() : "-", saved.getRole(), saved.getPhone())
        );
        return ApiResponse.success("员工创建成功", saved);
    }

    @Operation(summary = "修改店员信息/提成设置")
    @PutMapping("/{id}")
    public ApiResponse<Employee> updateStaff(@PathVariable Long id, @RequestBody Employee updateReq) {
        Employee employee = employeeRepository.findById(id)
                .orElseThrow(() -> new com.seahorse.store.common.ServiceException("员工不存在"));
        TenantContext.assertTenantAccess(employee.getTenantId());
        if (updateReq.getRealName() != null) employee.setRealName(updateReq.getRealName());
        if (updateReq.getNickname() != null) employee.setNickname(updateReq.getNickname().trim());
        if (updateReq.getPhone() != null) employee.setPhone(updateReq.getPhone());
        if (updateReq.getPostName() != null) employee.setPostName(updateReq.getPostName());
        if (updateReq.getGender() != null) employee.setGender(updateReq.getGender());
        if (updateReq.getIdCard() != null) employee.setIdCard(updateReq.getIdCard());
        if (updateReq.getBaseSalary() != null) employee.setBaseSalary(updateReq.getBaseSalary());
        if (updateReq.getDefaultCommissionRate() != null) employee.setDefaultCommissionRate(updateReq.getDefaultCommissionRate());
        if (updateReq.getRole() != null) employee.setRole(updateReq.getRole());
        if (updateReq.getStatus() != null) employee.setStatus(updateReq.getStatus());
        Employee saved = employeeRepository.save(employee);

        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = TenantContext.getUsername() != null ? TenantContext.getUsername() : "merchant";
        auditLogAppService.recordLog(
                saved.getTenantId(),
                null,
                saved.getStoreId(),
                null,
                saved.getId(),
                username,
                null,
                "修改员工档案资料",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("更新员工: %s (%s), 角色: %s",
                        saved.getRealName(), saved.getPostName() != null ? saved.getPostName() : "-", saved.getRole())
        );
        return ApiResponse.success("员工信息更新成功", saved);
    }

    @Operation(summary = "删除员工（软删除）")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteStaff(@PathVariable Long id) {
        Employee employee = employeeRepository.findById(id)
                .orElseThrow(() -> new com.seahorse.store.common.ServiceException("员工不存在"));
        TenantContext.assertTenantAccess(employee.getTenantId());
        employee.setIsDeleted(true);
        employeeRepository.save(employee);

        String clientIp = AuthController.getClientIp(request);
        String clientDevice = AuthController.getClientDevice(request);
        String username = TenantContext.getUsername() != null ? TenantContext.getUsername() : "merchant";
        auditLogAppService.recordLog(
                employee.getTenantId(),
                null,
                employee.getStoreId(),
                null,
                employee.getId(),
                username,
                null,
                "删除/注销门店员工",
                "OPERATE",
                clientIp,
                clientDevice,
                "SUCCESS",
                String.format("删除员工: %s (%s)", employee.getRealName(), employee.getUsername())
        );
        return ApiResponse.success("员工已删除", null);
    }

    @Operation(summary = "恢复已删除员工")
    @PostMapping("/restore/{id}")
    public ApiResponse<Void> restoreStaff(@PathVariable Long id) {
        Employee employee = employeeRepository.findById(id)
                .orElseThrow(() -> new com.seahorse.store.common.ServiceException("员工不存在"));
        TenantContext.assertTenantAccess(employee.getTenantId());
        employee.setIsDeleted(false);
        employeeRepository.save(employee);
        return ApiResponse.success("员工已恢复", null);
    }

    @Operation(summary = "新增奖罚记录")
    @PostMapping("/reward-punish")
    public ApiResponse<StaffRewardPunish> createRewardPunish(@RequestBody StaffRewardPunish record) {
        String tenantId = TenantContext.getTenantId();
        record.setTenantId(tenantId);
        if (record.getRecordDate() == null) {
            record.setRecordDate(java.time.LocalDate.now());
        }
        record.setOperator(TenantContext.getUsername());
        StaffRewardPunish saved = staffRewardPunishRepository.save(record);
        return ApiResponse.success("奖罚记录添加成功", saved);
    }

    @Operation(summary = "查询奖罚记录列表")
    @GetMapping("/reward-punish")
    public ApiResponse<List<StaffRewardPunish>> getRewardPunishList(@RequestParam(value = "employeeId", required = false) Long employeeId) {
        String tenantId = TenantContext.getTenantId();
        if (employeeId != null) {
            return ApiResponse.success(staffRewardPunishRepository.findByTenantIdAndEmployeeIdOrderByCreatedAtDesc(tenantId, employeeId));
        }
        return ApiResponse.success(staffRewardPunishRepository.findByTenantIdOrderByCreatedAtDesc(tenantId));
    }

    @Operation(summary = "查询指定员工提成记录")
    @GetMapping("/commissions")
    public ApiResponse<List<com.seahorse.store.domain.commission.model.CommissionRecord>> getStaffCommissions(
            @RequestParam(value = "employeeId", required = false) Long employeeId,
            @RequestParam(value = "employeeName", required = false) String employeeName,
            @RequestParam(value = "storeId", required = false) String storeId) {
        if (employeeId != null) {
            return ApiResponse.success(commissionRecordRepository.findByEmployeeIdOrderByCreatedAtDesc(employeeId));
        }
        if (employeeName != null && !employeeName.trim().isEmpty()) {
            String name = employeeName.trim();
            if (storeId != null && !storeId.trim().isEmpty()) {
                return ApiResponse.success(commissionRecordRepository.findByStoreIdAndEmployeeNameOrderByCreatedAtDesc(storeId.trim(), name));
            }
            return ApiResponse.success(commissionRecordRepository.findByEmployeeNameOrderByCreatedAtDesc(name));
        }
        if (storeId != null && !storeId.trim().isEmpty()) {
            return ApiResponse.success(commissionRecordRepository.findByStoreIdOrderByCreatedAtDesc(storeId.trim()));
        }
        return ApiResponse.success(java.util.Collections.emptyList());
    }

    @lombok.Data
    public static class SelfRegisterCommand {
        private String tenantId;
        private String storeId;
        private String realName;
        private String phone;
        private String accountPassword;
        private String department;
        private String postName;
        private String gender;
        private String experience;
        private java.math.BigDecimal baseSalary;
        private String role;
    }

    @Operation(summary = "员工扫码自主提交入职申请(免登公开通道)")
    @PostMapping("/self-register")
    public ApiResponse<Employee> selfRegisterStaff(@RequestBody SelfRegisterCommand cmd) {
        if (cmd.getRealName() == null || cmd.getRealName().trim().isEmpty()) {
            return ApiResponse.error(400, "请填写真实姓名");
        }
        if (cmd.getPhone() == null || cmd.getPhone().trim().isEmpty()) {
            return ApiResponse.error(400, "请填写手机号码");
        }

        String storeId = cmd.getStoreId() != null && !cmd.getStoreId().trim().isEmpty() ? cmd.getStoreId().trim() : "S001";
        String tenantId = cmd.getTenantId();
        // 优先根据所属门店获取真实租户ID，防止访客端携带平台默认租户
        if (storeId != null && !storeId.trim().isEmpty()) {
            var storeOpt = storeRepository.findByStoreId(storeId);
            if (storeOpt.isPresent() && storeOpt.get().getTenantId() != null && !storeOpt.get().getTenantId().trim().isEmpty()) {
                tenantId = storeOpt.get().getTenantId();
            }
        }
        if (tenantId == null || tenantId.trim().isEmpty() || "undefined".equalsIgnoreCase(tenantId) || "PLATFORM".equalsIgnoreCase(tenantId)) {
            String ctxTenant = TenantContext.getTenantId();
            if (ctxTenant != null && !ctxTenant.trim().isEmpty() && !"PLATFORM".equalsIgnoreCase(ctxTenant)) {
                tenantId = ctxTenant;
            }
        }
        if (tenantId == null || tenantId.trim().isEmpty() || "undefined".equalsIgnoreCase(tenantId) || "PLATFORM".equalsIgnoreCase(tenantId)) {
            tenantId = "T001";
        }

        String phone = cmd.getPhone().trim();
        java.util.Optional<Employee> existing = employeeRepository.findByTenantIdAndPhone(tenantId, phone);
        Employee employee;
        if (existing.isPresent()) {
            employee = existing.get();
            employee.setRealName(cmd.getRealName().trim());
            employee.setStoreId(storeId);
            if (cmd.getDepartment() != null) employee.setDepartment(cmd.getDepartment().trim());
            if (cmd.getPostName() != null) employee.setPostName(cmd.getPostName().trim());
            if (cmd.getGender() != null) employee.setGender(cmd.getGender());
            if (cmd.getExperience() != null) employee.setExperience(cmd.getExperience().trim());
            if (cmd.getAccountPassword() != null && !cmd.getAccountPassword().trim().isEmpty()) {
                employee.setPassword(passwordEncoder.encode(cmd.getAccountPassword().trim()));
            }
            employee.setAuditStatus("PENDING");
            employee.setStatus("PENDING_REVIEW");
            employee.setIsSelfApplied(true);
            employee.setIsDeleted(false);
        } else {
            employee = new Employee();
            employee.setTenantId(tenantId);
            employee.setStoreId(storeId);
            employee.setUsername(phone);
            String rawPwd = cmd.getAccountPassword() != null && !cmd.getAccountPassword().trim().isEmpty()
                    ? cmd.getAccountPassword().trim() : "123456";
            employee.setPassword(passwordEncoder.encode(rawPwd));
            employee.setRealName(cmd.getRealName().trim());
            employee.setPhone(phone);
            employee.setDepartment(cmd.getDepartment() != null ? cmd.getDepartment().trim() : "门店服务部");
            employee.setPostName(cmd.getPostName() != null ? cmd.getPostName().trim() : "造型技师");
            employee.setGender(cmd.getGender() != null ? cmd.getGender() : "MALE");
            employee.setExperience(cmd.getExperience() != null ? cmd.getExperience().trim() : "");
            employee.setStatus("PENDING_REVIEW");
            employee.setAuditStatus("PENDING");
            employee.setIsSelfApplied(true);
            employee.setIsDeleted(false);

            EmployeeRole role = EmployeeRole.TECHNICIAN;
            if (cmd.getPostName() != null && (cmd.getPostName().contains("店长") || cmd.getPostName().contains("主管"))) {
                role = EmployeeRole.STORE_MANAGER;
            } else if (cmd.getPostName() != null && (cmd.getPostName().contains("收银") || cmd.getPostName().contains("前台"))) {
                role = EmployeeRole.CASHIER;
            }
            employee.setRole(role);
            employee.setBaseSalary(cmd.getBaseSalary() != null ? cmd.getBaseSalary() : new java.math.BigDecimal("4500"));
            employee.setDefaultCommissionRate(new java.math.BigDecimal("0.15"));
        }

        Employee saved = employeeRepository.save(employee);
        return ApiResponse.success("入职申请已提交，请等待店长或租户审核", saved);
    }

    @Operation(summary = "店长/租户老板查询员工入职审核申请列表")
    @GetMapping("/audit-list")
    public ApiResponse<List<Employee>> getStaffAuditList(
            @RequestParam(value = "tenantId", required = false) String paramTenantId,
            @RequestParam(value = "storeId", required = false) String storeId,
            @RequestParam(value = "status", required = false) String status) {
        String tenantId = (paramTenantId != null && !paramTenantId.trim().isEmpty() && !"undefined".equalsIgnoreCase(paramTenantId))
                ? paramTenantId.trim() : TenantContext.getTenantId();
        if (tenantId == null || tenantId.trim().isEmpty() || "undefined".equalsIgnoreCase(tenantId) || "PLATFORM".equalsIgnoreCase(tenantId)) {
            if (storeId != null && !storeId.trim().isEmpty()) {
                var storeOpt = storeRepository.findByStoreId(storeId);
                if (storeOpt.isPresent() && storeOpt.get().getTenantId() != null) {
                    tenantId = storeOpt.get().getTenantId();
                }
            }
        }
        if (tenantId == null || tenantId.trim().isEmpty()) {
            tenantId = "T001";
        }
        List<Employee> all = new java.util.ArrayList<>(employeeRepository.findByTenantId(tenantId));
        if (storeId != null && !storeId.trim().isEmpty()) {
            List<Employee> storeStaff = employeeRepository.findByStoreIdAndIsDeleted(storeId, false);
            for (Employee s : storeStaff) {
                if (all.stream().noneMatch(e -> e.getId() != null && e.getId().equals(s.getId()))) {
                    all.add(s);
                }
            }
        }
        List<Employee> filtered = all.stream()
                .filter(e -> !Boolean.TRUE.equals(e.getIsDeleted()))
                .filter(e -> e.getRole() != EmployeeRole.PLATFORM_DEVELOPER)
                .filter(e -> !"admin".equalsIgnoreCase(e.getUsername()))
                .filter(e -> e.getRealName() == null || !e.getRealName().contains("开发维护人"))
                .filter(e -> Boolean.TRUE.equals(e.getIsSelfApplied()) || e.getAuditStatus() != null || "PENDING_REVIEW".equalsIgnoreCase(e.getStatus()))
                .filter(e -> storeId == null || storeId.trim().isEmpty() || storeId.equals(e.getStoreId()))
                .filter(e -> status == null || status.trim().isEmpty() || "ALL".equalsIgnoreCase(status) || (e.getAuditStatus() != null && e.getAuditStatus().equalsIgnoreCase(status)))
                .sorted((a, b) -> {
                    boolean aPending = "PENDING".equalsIgnoreCase(a.getAuditStatus()) || "PENDING_REVIEW".equalsIgnoreCase(a.getStatus());
                    boolean bPending = "PENDING".equalsIgnoreCase(b.getAuditStatus()) || "PENDING_REVIEW".equalsIgnoreCase(b.getStatus());
                    if (aPending && !bPending) return -1;
                    if (!aPending && bPending) return 1;
                    return (b.getId() != null && a.getId() != null) ? b.getId().compareTo(a.getId()) : 0;
                })
                .toList();
        return ApiResponse.success(filtered);
    }

    @lombok.Data
    public static class StaffAuditApproveCommand {
        private String postName;
        private java.math.BigDecimal baseSalary;
        private String department;
        private EmployeeRole role;
    }

    @Operation(summary = "审批通过员工自主入职申请")
    @PostMapping("/audit/{id}/approve")
    public ApiResponse<Employee> approveStaffAudit(
            @PathVariable Long id,
            @RequestBody(required = false) StaffAuditApproveCommand cmd) {
        Employee employee = employeeRepository.findById(id)
                .orElseThrow(() -> new com.seahorse.store.common.ServiceException("入职申请记录不存在"));
        TenantContext.assertTenantAccess(employee.getTenantId());

        if (cmd != null) {
            if (cmd.getPostName() != null && !cmd.getPostName().trim().isEmpty()) {
                employee.setPostName(cmd.getPostName().trim());
            }
            if (cmd.getDepartment() != null && !cmd.getDepartment().trim().isEmpty()) {
                employee.setDepartment(cmd.getDepartment().trim());
            }
            if (cmd.getBaseSalary() != null) {
                employee.setBaseSalary(cmd.getBaseSalary());
            }
            if (cmd.getRole() != null) {
                employee.setRole(cmd.getRole());
            }
        }
        employee.setAuditStatus("APPROVED");
        employee.setStatus("ACTIVE");
        Employee saved = employeeRepository.save(employee);
        return ApiResponse.success("已批准该员工入职并激活工号权限！", saved);
    }

    @Operation(summary = "驳回员工自主入职申请")
    @PostMapping("/audit/{id}/reject")
    public ApiResponse<Employee> rejectStaffAudit(
            @PathVariable Long id,
            @RequestParam(value = "reason", required = false) String reason) {
        Employee employee = employeeRepository.findById(id)
                .orElseThrow(() -> new com.seahorse.store.common.ServiceException("入职申请记录不存在"));
        TenantContext.assertTenantAccess(employee.getTenantId());
        employee.setAuditStatus("REJECTED");
        employee.setStatus("DISABLED");
        Employee saved = employeeRepository.save(employee);
        return ApiResponse.success("已驳回该入职申请", saved);
    }
}
