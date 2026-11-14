package com.seahorse.store.interfaces.web;

import com.seahorse.store.application.dto.vendor.MerchantRegisterCommand;
import com.seahorse.store.application.service.MerchantRegisterAppService;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.JwtUtil;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.common.constant.CommonConstants;
import com.seahorse.store.domain.iam.model.Employee;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.iam.model.Tenant;
import com.seahorse.store.domain.iam.model.TenantSubscription;
import com.seahorse.store.domain.member.enums.DeductMode;
import com.seahorse.store.infrastructure.repository.EmployeeRepository;
import com.seahorse.store.infrastructure.repository.StoreRepository;
import com.seahorse.store.infrastructure.repository.TenantRepository;
import com.seahorse.store.infrastructure.repository.TenantSubscriptionRepository;
import com.seahorse.store.interfaces.web.vo.LoginResponseVO;
import com.seahorse.store.interfaces.web.vo.UserInfoVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import com.seahorse.store.domain.iam.enums.EmployeeRole;
import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 认证中心控制器
 * 提供员工登录、商户自主注册与多门店凭证发放
 */
@Tag(name = "01. 认证中心", description = "员工登录与权限令牌发放、商户入驻注册")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final EmployeeRepository employeeRepository;
    private final StoreRepository storeRepository;
    private final TenantRepository tenantRepository;
    private final TenantSubscriptionRepository subscriptionRepository;
    private final MerchantRegisterAppService merchantRegisterAppService;
    private final com.seahorse.store.application.service.PlatformConfigAppService platformConfigAppService;
    private final com.seahorse.store.application.service.PermissionManageAppService permissionManageAppService;
    private final com.seahorse.store.infrastructure.repository.MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final com.seahorse.store.application.service.AuditLogAppService auditLogAppService;
    private final jakarta.servlet.http.HttpServletRequest request;

    @org.springframework.beans.factory.annotation.Value("${spring.profiles.active:dev}")
    private String activeProfile;

    private static final java.security.SecureRandom RESET_RANDOM = new java.security.SecureRandom();
    private final java.util.concurrent.ConcurrentHashMap<Long, ResetCodeEntry> resetCodeCache = new java.util.concurrent.ConcurrentHashMap<>();

    private static class ResetCodeEntry {
        private final String code;
        private final java.time.Instant expireAt;
        private int attempts;

        private ResetCodeEntry(String code, java.time.Instant expireAt) {
            this.code = code;
            this.expireAt = expireAt;
            this.attempts = 0;
        }
    }

    @Data
    public static class LoginRequest {
        private String username;
        private String password;
        private String clientPlatform;
        private String deviceModel;
        private String clientDevice;
    }

    @Data
    public static class MemberLoginRequest {
        private String phone;
        private String password;
    }

    @Data
    public static class SendResetCodeRequest {
        private String account;
    }

    @Data
    public static class ResetPasswordByCodeRequest {
        private String account;
        private String code;
        private String newPassword;
    }

    @Operation(summary = "忘记密码-发送找回密码验证码 (公开接口)")
    @PostMapping("/send-reset-code")
    public ApiResponse<Map<String, Object>> sendResetCode(@RequestBody SendResetCodeRequest req) {
        Employee emp = resolveEmployeeByAccount(req != null ? req.getAccount() : null);
        String code = String.format("%06d", RESET_RANDOM.nextInt(1_000_000));
        resetCodeCache.put(emp.getId(), new ResetCodeEntry(code, java.time.Instant.now().plusSeconds(300)));

        String phone = emp.getPhone() != null ? emp.getPhone().trim() : "";
        String maskedPhone = phone.length() >= 7
                ? phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4)
                : "已绑定账号";

        Map<String, Object> data = new HashMap<>();
        data.put("account", emp.getUsername());
        data.put("maskedPhone", maskedPhone);
        data.put("expireSeconds", 300);
        if (!"prod".equalsIgnoreCase(activeProfile)) {
            data.put("devCode", code);
            data.put("code", code);
        }
        return ApiResponse.success("验证码已发送，5分钟内有效", data);
    }

    @Operation(summary = "忘记密码-通过验证码重置登录密码 (公开接口)")
    @PostMapping("/reset-password")
    public ApiResponse<Map<String, Object>> resetPasswordByCode(@RequestBody ResetPasswordByCodeRequest req) {
        if (req == null || req.getCode() == null || req.getCode().trim().isEmpty()) {
            throw new ServiceException(400, "请输入6位验证码");
        }
        if (req.getNewPassword() == null || req.getNewPassword().trim().length() < 6) {
            throw new ServiceException(400, "新密码长度不能少于6位字符");
        }

        Employee emp = resolveEmployeeByAccount(req.getAccount());
        ResetCodeEntry entry = resetCodeCache.get(emp.getId());
        if (entry == null || java.time.Instant.now().isAfter(entry.expireAt)) {
            resetCodeCache.remove(emp.getId());
            throw new ServiceException(400, "验证码已过期或不存在，请重新获取");
        }
        entry.attempts++;
        if (entry.attempts > 5) {
            resetCodeCache.remove(emp.getId());
            throw new ServiceException(429, "验证码错误次数过多，请重新获取验证码");
        }
        if (!entry.code.equals(req.getCode().trim())) {
            throw new ServiceException(400, "验证码不正确，请核对后重试");
        }

        resetCodeCache.remove(emp.getId());
        emp.setPassword(passwordEncoder.encode(req.getNewPassword().trim()));
        employeeRepository.save(emp);

        auditLogAppService.recordLog(
                emp.getTenantId(),
                null,
                emp.getStoreId(),
                null,
                emp.getId(),
                emp.getUsername(),
                emp.getRealName(),
                "自助找回重置密码",
                "SECURITY",
                getClientIp(request),
                getClientDevice(request),
                "SUCCESS",
                "通过验证码校验完成自助密码重置"
        );

        Map<String, Object> res = new HashMap<>();
        res.put("username", emp.getUsername());
        res.put("updated", true);
        return ApiResponse.success("密码重置成功，请使用新密码登录", res);
    }

    private Employee resolveEmployeeByAccount(String rawAccount) {
        if (rawAccount == null || rawAccount.trim().isEmpty()) {
            throw new ServiceException(400, "请输入登录账号或绑定手机号");
        }
        String account = rawAccount.trim();
        Employee emp = employeeRepository.findByUsername(account)
                .filter(e -> !Boolean.TRUE.equals(e.getIsDeleted()) && !"DELETED".equalsIgnoreCase(e.getStatus()))
                .orElse(null);
        if (emp == null) {
            emp = employeeRepository.findByPhone(account).stream()
                    .filter(e -> !Boolean.TRUE.equals(e.getIsDeleted()) && !"DELETED".equalsIgnoreCase(e.getStatus()))
                    .findFirst()
                    .orElse(null);
        }
        if (emp == null) {
            throw new ServiceException(404, "未找到该账号或绑定手机号对应的员工档案");
        }
        return emp;
    }

    @Operation(summary = "获取公开SaaS会员套餐版本与试用期定价配置")
    @GetMapping("/plans")
    public ApiResponse<List<com.seahorse.store.interfaces.web.vo.SubscriptionPlanConfigVO>> getPublicPlans() {
        return ApiResponse.success(platformConfigAppService.getActivePlanConfigs());
    }

    @Operation(summary = "商户自主入驻注册 (自选SaaS套餐、多店模态与双轨储值策略)")
    @PostMapping("/register-merchant")
    public ApiResponse<Tenant> registerMerchant(@RequestBody MerchantRegisterCommand cmd) {
        Tenant tenant = merchantRegisterAppService.registerMerchant(cmd);
        return ApiResponse.success("商户入驻注册成功", tenant);
    }

    @Operation(summary = "员工/管理员登录")
    @PostMapping("/login")
    public ApiResponse<LoginResponseVO> login(@RequestBody LoginRequest req) {
        String clientIp = getClientIp(request);
        String clientDevice = getClientDevice(request, req.getClientDevice(), req.getClientPlatform(), req.getDeviceModel());

        Employee emp = employeeRepository.findByUsername(req.getUsername())
                .orElse(null);

        // 1. 优先联动 FWPT 统一通行证中心 (OneID) 核验，确保跨系统单点登录、密码修改、冻结状态与审计大盘实时同步
        Map<String, Object> fwptAuth = verifyFwptAuth(req.getUsername(), req.getPassword());
        if (fwptAuth != null) {
            if (Boolean.TRUE.equals(fwptAuth.get("frozen"))) {
                throw new ServiceException(403, "该通行证账号已被管理员冻结，请联系平台客服");
            }
            String fwptRealName = (String) fwptAuth.get("realName");
            String fwptPhone = (String) fwptAuth.get("phone");
            String displayName = (fwptRealName != null && !fwptRealName.trim().isEmpty()) ? fwptRealName.trim() : req.getUsername();

            if (emp == null) {
                emp = Employee.builder()
                        .tenantId("T001")
                        .storeId("S001")
                        .username(req.getUsername().trim())
                        .password(passwordEncoder.encode(req.getPassword()))
                        .realName(displayName)
                        .nickname(displayName)
                        .phone(fwptPhone != null ? fwptPhone : "")
                        .role(EmployeeRole.STORE_MANAGER) // 统一赋权店长/管理权限
                        .status(CommonConstants.STATUS_ACTIVE)
                        .build();
                emp = employeeRepository.save(emp);
            } else {
                emp.setPassword(passwordEncoder.encode(req.getPassword()));
                if (fwptRealName != null && !fwptRealName.trim().isEmpty()) {
                    emp.setRealName(fwptRealName.trim());
                }
                emp = employeeRepository.save(emp);
            }
        } else if (emp == null || !passwordEncoder.matches(req.getPassword(), emp.getPassword())) {
            auditLogAppService.recordLog(
                    emp != null ? emp.getTenantId() : "PLATFORM",
                    null,
                    emp != null ? emp.getStoreId() : null,
                    null,
                    emp != null ? emp.getId() : null,
                    req.getUsername(),
                    emp != null ? emp.getRealName() : null,
                    "账号密码登录",
                    "LOGIN",
                    clientIp,
                    clientDevice,
                    "FAILED",
                    "用户名或密码错误"
            );
            throw new ServiceException(401, "用户名或密码错误");
        }

        if (!CommonConstants.STATUS_ACTIVE.equals(emp.getStatus())) {
            auditLogAppService.recordLog(
                    emp.getTenantId(),
                    null,
                    emp.getStoreId(),
                    null,
                    emp.getId(),
                    emp.getUsername(),
                    emp.getRealName(),
                    "账号密码登录",
                    "LOGIN",
                    clientIp,
                    clientDevice,
                    "BLOCKED",
                    "账号已被禁用拦截"
            );
            throw new ServiceException(403, "账号已被禁用");
        }

        boolean isPlatformDev = "admin".equalsIgnoreCase(emp.getUsername()) || emp.getRole() == EmployeeRole.PLATFORM_DEVELOPER;
        String roleStr = isPlatformDev ? EmployeeRole.PLATFORM_DEVELOPER.name() : emp.getRole().name();

        if (!isPlatformDev) {
            Tenant tenantCheck = tenantRepository.findByTenantId(emp.getTenantId()).orElse(null);
            if (tenantCheck != null) {
                if ("DELETED".equalsIgnoreCase(tenantCheck.getStatus())) {
                    throw new ServiceException(403, "该商户账号已安全注销删除，无法登录系统");
                }
                if ("DISABLED".equalsIgnoreCase(tenantCheck.getStatus())) {
                    auditLogAppService.recordLog(
                            emp.getTenantId(),
                            tenantCheck.getTenantName(),
                            emp.getStoreId(),
                            null,
                            emp.getId(),
                            emp.getUsername(),
                            emp.getRealName(),
                            "账号密码登录",
                            "LOGIN",
                            clientIp,
                            clientDevice,
                            "BLOCKED",
                            "商户已被超级管理员禁用拦截"
                    );
                    throw new ServiceException(403, "该商户已被平台超级管理员暂时禁用，暂停提供系统服务，请联系平台客服！");
                }
            }
        }

        Store currentStore = null;
        if (emp.getStoreId() != null && !emp.getStoreId().trim().isEmpty() && !"S001".equalsIgnoreCase(emp.getStoreId())) {
            currentStore = storeRepository.findByStoreIdAndTenantId(emp.getStoreId(), emp.getTenantId()).orElse(null);
        }
        if (currentStore == null && !isPlatformDev) {
            List<Store> tenantStores = storeRepository.findByTenantId(emp.getTenantId());
            if (!tenantStores.isEmpty()) {
                currentStore = tenantStores.get(0);
            }
        }
        String industry = isPlatformDev ? "PLATFORM" : (currentStore != null && currentStore.getIndustry() != null ? currentStore.getIndustry().name() : "");
        String storeName = isPlatformDev ? "SaaS平台全局运维大厅" : (currentStore != null ? currentStore.getStoreName() : "");
        String effectiveStoreId = isPlatformDev ? "PLATFORM" : (currentStore != null ? currentStore.getStoreId() : null);

        // 查询该商户旗下开设的所有门店（支持多店多模态切换）
        List<Store> allStores = isPlatformDev ? Collections.emptyList() : storeRepository.findByTenantId(emp.getTenantId());
        List<LoginResponseVO.StoreItemVO> storeItemVos = allStores.stream()
                .map(s -> LoginResponseVO.StoreItemVO.builder()
                        .storeId(s.getStoreId())
                        .storeName(s.getStoreName())
                        .industry(s.getIndustry() != null ? s.getIndustry().name() : "BEAUTY")
                        .industryDesc(s.getIndustry() != null ? s.getIndustry().getDescription() : "美业服务")
                        .address(s.getAddress())
                        .phone(s.getPhone())
                        .build())
                .collect(Collectors.toList());

        // 查询商户订阅套餐与配置
        Tenant tenant = tenantRepository.findByTenantId(emp.getTenantId()).orElse(null);
        TenantSubscription sub = subscriptionRepository.findByTenantId(emp.getTenantId()).orElse(null);

        // 计算当前角色生效的权限列表
        List<String> permissions = isPlatformDev
                ? permissionManageAppService.getEffectivePermissions("PLATFORM", EmployeeRole.PLATFORM_DEVELOPER)
                : permissionManageAppService.getEffectivePermissions(emp.getTenantId(), emp.getRole());

        String token = jwtUtil.generateToken(
                emp.getId(), emp.getUsername(), isPlatformDev ? "PLATFORM" : emp.getTenantId(), effectiveStoreId != null ? effectiveStoreId : "",
                roleStr, industry
        );

        LoginResponseVO vo = LoginResponseVO.builder()
                .token(token)
                .userId(emp.getId())
                .username(emp.getUsername())
                .realName(isPlatformDev ? "系统开发维护人" : emp.getRealName())
                .role(roleStr)
                .tenantId(isPlatformDev ? "PLATFORM" : emp.getTenantId())
                .tenantName(isPlatformDev ? "海马SaaS平台全局开发运维中心" : (tenant != null ? tenant.getTenantName() : "海马智慧商户"))
                .storeId(effectiveStoreId)
                .storeName(storeName)
                .industry(industry)
                .plan(sub != null && sub.getPlan() != null ? sub.getPlan().name() : (isPlatformDev ? "ENTERPRISE" : "PROFESSIONAL"))
                .planName(sub != null && sub.getPlan() != null ? sub.getPlan().getDescription() : (isPlatformDev ? "平台开发运维端" : "专业成长版"))
                .deductMode(tenant != null && tenant.getDeductMode() != null ? tenant.getDeductMode().name() : DeductMode.PROPORTIONAL.name())
                .storageQuotaGb(sub != null ? sub.getStorageQuotaGb() : (isPlatformDev ? 9999 : 50))
                .expireDate(sub != null ? sub.getExpireDate() : null)
                .storeLimit(sub != null && sub.getStoreLimit() != null ? sub.getStoreLimit() : (isPlatformDev ? 999 : 1))
                .staffLimit(sub != null && sub.getStaffLimit() != null ? sub.getStaffLimit() : (isPlatformDev ? 999 : 3))
                .stores(storeItemVos)
                .permissions(permissions)
                .build();

        // 记录登录成功安全审计日志
        auditLogAppService.recordLog(
                emp.getTenantId(),
                tenant != null ? tenant.getTenantName() : null,
                effectiveStoreId,
                storeName,
                emp.getId(),
                emp.getUsername(),
                isPlatformDev ? "系统开发维护人" : emp.getRealName(),
                "账号密码登录",
                "LOGIN",
                clientIp,
                clientDevice,
                "SUCCESS",
                "登录成功 · 身份: " + roleStr
        );

        return ApiResponse.success("登录成功", vo);
    }

    @Operation(summary = "顾客会员手机号登录")
    @PostMapping("/member-login")
    public ApiResponse<LoginResponseVO> memberLogin(@RequestBody MemberLoginRequest req) {
        if (req.getPhone() == null || req.getPhone().trim().isEmpty()) {
            throw new ServiceException(400, "请输入会员手机号");
        }
        String phone = req.getPhone().trim();
        com.seahorse.store.domain.member.model.Member member = memberRepository.findByPhone(phone)
                .orElseThrow(() -> new ServiceException(404, "未找到该手机号绑定的会员档案，请核对手机号"));

        Tenant tenant = tenantRepository.findByTenantId(member.getTenantId()).orElse(null);
        TenantSubscription sub = subscriptionRepository.findByTenantId(member.getTenantId()).orElse(null);

        List<String> permissions = permissionManageAppService.getEffectivePermissions(member.getTenantId(), EmployeeRole.CUSTOMER_MEMBER);

        String token = jwtUtil.generateToken(
                member.getId(), member.getPhone(), member.getTenantId(), "S001",
                EmployeeRole.CUSTOMER_MEMBER.name(), "GENERAL"
        );

        LoginResponseVO vo = LoginResponseVO.builder()
                .token(token)
                .userId(member.getId())
                .username(member.getPhone())
                .realName(member.getName())
                .role(EmployeeRole.CUSTOMER_MEMBER.name())
                .tenantId(member.getTenantId())
                .tenantName(tenant != null ? tenant.getTenantName() : "海马智慧门店")
                .storeId("S001")
                .storeName("会员个人服务专区")
                .industry("GENERAL")
                .plan(sub != null ? sub.getPlan().name() : "TRIAL")
                .planName(sub != null ? sub.getPlan().getDescription() : "体验版")
                .permissions(permissions)
                .build();

        return ApiResponse.success("会员登录成功", vo);
    }

    @Operation(summary = "获取当前登录人信息")
    @GetMapping("/me")
    public ApiResponse<UserInfoVO> getCurrentUser() {
        UserInfoVO vo = UserInfoVO.builder()
                .userId(TenantContext.getUserId())
                .username(TenantContext.getUsername())
                .tenantId(TenantContext.getTenantId())
                .storeId(TenantContext.getStoreId())
                .build();
        return ApiResponse.success(vo);
    }

    @Operation(summary = "获取当前商户最新套餐订阅状态与配额")
    @GetMapping("/current-subscription")
    public ApiResponse<Map<String, Object>> getCurrentSubscription() {
        String tenantId = TenantContext.getTenantId();
        if (tenantId == null || "PLATFORM".equalsIgnoreCase(tenantId)) {
            Map<String, Object> map = new HashMap<>();
            map.put("tenantId", "PLATFORM");
            map.put("tenantName", "海马平台开发运维中心");
            map.put("plan", "ENTERPRISE");
            map.put("planName", "平台开发运维至尊端");
            map.put("storeLimit", 999);
            map.put("staffLimit", 999);
            map.put("storageQuotaGb", 9999);
            map.put("isTrial", false);
            map.put("daysRemaining", 9999);
            map.put("status", "ACTIVE");
            return ApiResponse.success(map);
        }

        Tenant tenant = tenantRepository.findByTenantId(tenantId).orElse(null);
        TenantSubscription sub = subscriptionRepository.findByTenantId(tenantId).orElse(null);

        Map<String, Object> map = new HashMap<>();
        SubscriptionPlan plan = (sub != null && sub.getPlan() != null) ? sub.getPlan() : SubscriptionPlan.TRIAL;
        map.put("tenantId", tenantId);
        map.put("tenantName", tenant != null ? tenant.getTenantName() : "智慧商户");
        map.put("plan", plan.name());
        map.put("planName", plan.getDescription());

        int storeLimit = (sub != null && sub.getStoreLimit() != null && sub.getStoreLimit() > 0)
                ? sub.getStoreLimit()
                : plan.getMaxStores();
        map.put("storeLimit", storeLimit);

        int defaultStaffLimit = (plan == SubscriptionPlan.TRIAL) ? 3 : (plan == SubscriptionPlan.PROFESSIONAL ? 15 : (plan == SubscriptionPlan.FLAGSHIP ? 50 : 999));
        int staffLimit = (sub != null && sub.getStaffLimit() != null && sub.getStaffLimit() > 0)
                ? sub.getStaffLimit()
                : defaultStaffLimit;
        map.put("staffLimit", staffLimit);

        int storageGb = (sub != null && sub.getStorageQuotaGb() != null && sub.getStorageQuotaGb() > 0)
                ? sub.getStorageQuotaGb()
                : plan.getStorageQuotaGb();
        map.put("storageQuotaGb", storageGb);

        map.put("expireDate", (sub != null && sub.getExpireDate() != null) ? sub.getExpireDate().toString() : "");
        String effectiveStatus = (tenant != null && tenant.getStatus() != null) ? tenant.getStatus() : (sub != null ? sub.getStatus() : "ACTIVE");
        map.put("status", effectiveStatus);

        boolean isTrial = (plan == SubscriptionPlan.TRIAL);
        map.put("isTrial", isTrial);

        long daysRemaining = 3;
        if (sub != null && sub.getExpireDate() != null) {
            daysRemaining = java.time.temporal.ChronoUnit.DAYS.between(java.time.LocalDate.now(), sub.getExpireDate());
        }
        map.put("daysRemaining", Math.max(0, daysRemaining));

        return ApiResponse.success(map);
    }

    @Data
    public static class ChangePasswordRequest {
        private String oldPassword;
        private String newPassword;
    }

    @Data
    public static class UpdatePhoneRequest {
        private String phone;
        private String verifyCode;
    }

    @Data
    public static class UpdateProfileRequest {
        private String realName;
        private String gender;
        private String avatar;
    }

    @Data
    @lombok.Builder
    public static class UserProfileVO {
        private Long userId;
        private String username;
        private String realName;
        private String phone;
        private String avatar;
        private String gender;
        private String role;
        private String roleName;
        private String storeId;
        private String storeName;
        private String tenantId;
        private String tenantName;
    }

    @Operation(summary = "获取个人中心信息")
    @GetMapping("/profile")
    public ApiResponse<UserProfileVO> getProfile() {
        String username = TenantContext.getUsername();
        Employee emp = employeeRepository.findByUsername(username).orElse(null);
        if (emp != null) {
            Store store = storeRepository.findByStoreId(emp.getStoreId()).orElse(null);
            Tenant tenant = tenantRepository.findByTenantId(emp.getTenantId()).orElse(null);
            UserProfileVO vo = UserProfileVO.builder()
                    .userId(emp.getId())
                    .username(emp.getUsername())
                    .realName(emp.getRealName())
                    .phone(emp.getPhone())
                    .avatar(emp.getAvatar())
                    .gender(emp.getGender())
                    .role(emp.getRole().name())
                    .roleName(emp.getRole().getDescription())
                    .storeId(emp.getStoreId())
                    .storeName(store != null ? store.getStoreName() : "总部直营店")
                    .tenantId(emp.getTenantId())
                    .tenantName(tenant != null ? tenant.getTenantName() : "海马智慧门店")
                    .build();
            return ApiResponse.success(vo);
        }
        com.seahorse.store.domain.member.model.Member m = memberRepository.findByPhone(username).orElse(null);
        if (m != null) {
            UserProfileVO vo = UserProfileVO.builder()
                    .userId(m.getId())
                    .username(m.getPhone())
                    .realName(m.getName())
                    .phone(m.getPhone())
                    .avatar(m.getAvatar())
                    .gender(m.getGender())
                    .role("CUSTOMER_MEMBER")
                    .roleName("会员顾客")
                    .storeId("S001")
                    .storeName("会员专区")
                    .tenantId(m.getTenantId())
                    .tenantName("海马智慧门店")
                    .build();
            return ApiResponse.success(vo);
        }
        throw new ServiceException(404, "未找到该用户信息");
    }

    @Operation(summary = "个人中心-修改密码")
    @PutMapping("/profile/change-password")
    public ApiResponse<String> changePassword(@RequestBody ChangePasswordRequest req) {
        if (req.getNewPassword() == null || req.getNewPassword().length() < 6) {
            throw new ServiceException(400, "新密码长度不能少于6位");
        }
        String username = TenantContext.getUsername();
        Employee emp = employeeRepository.findByUsername(username).orElse(null);
        if (emp != null) {
            if (req.getOldPassword() != null && !req.getOldPassword().isEmpty()) {
                if (!passwordEncoder.matches(req.getOldPassword(), emp.getPassword())) {
                    throw new ServiceException(400, "原密码输入不正确，请重新核对");
                }
            }
            emp.setPassword(passwordEncoder.encode(req.getNewPassword()));
            employeeRepository.save(emp);
            return ApiResponse.success("密码修改成功，请牢记新密码", "OK");
        }
        com.seahorse.store.domain.member.model.Member m = memberRepository.findByPhone(username).orElse(null);
        if (m != null) {
            m.setCardPassword(req.getNewPassword());
            m.setCardPasswordEnabled(true);
            memberRepository.save(m);
            return ApiResponse.success("会员密码修改成功", "OK");
        }
        throw new ServiceException(404, "用户不存在");
    }

    @Operation(summary = "个人中心-修改手机号")
    @PutMapping("/profile/update-phone")
    public ApiResponse<String> updatePhone(@RequestBody UpdatePhoneRequest req) {
        if (req.getPhone() == null || req.getPhone().trim().isEmpty()) {
            throw new ServiceException(400, "手机号不能为空");
        }
        String username = TenantContext.getUsername();
        Employee emp = employeeRepository.findByUsername(username).orElse(null);
        if (emp != null) {
            emp.setPhone(req.getPhone().trim());
            employeeRepository.save(emp);
            return ApiResponse.success("手机号已成功修改为：" + req.getPhone().trim(), "OK");
        }
        com.seahorse.store.domain.member.model.Member m = memberRepository.findByPhone(username).orElse(null);
        if (m != null) {
            m.setPhone(req.getPhone().trim());
            memberRepository.save(m);
            return ApiResponse.success("会员手机号修改成功", "OK");
        }
        throw new ServiceException(404, "用户不存在");
    }

    @Operation(summary = "个人中心-修改基础信息")
    @PutMapping("/profile/info")
    public ApiResponse<String> updateProfileInfo(@RequestBody UpdateProfileRequest req) {
        String username = TenantContext.getUsername();
        Employee emp = employeeRepository.findByUsername(username).orElse(null);
        if (emp != null) {
            if (req.getRealName() != null && !req.getRealName().trim().isEmpty()) {
                emp.setRealName(req.getRealName().trim());
            }
            if (req.getGender() != null) {
                emp.setGender(req.getGender());
            }
            if (req.getAvatar() != null) {
                emp.setAvatar(req.getAvatar());
            }
            employeeRepository.save(emp);
            return ApiResponse.success("个人基本信息已更新", "OK");
        }
        com.seahorse.store.domain.member.model.Member m = memberRepository.findByPhone(username).orElse(null);
        if (m != null) {
            if (req.getRealName() != null && !req.getRealName().trim().isEmpty()) {
                m.setName(req.getRealName().trim());
            }
            if (req.getGender() != null) {
                m.setGender(req.getGender());
            }
            memberRepository.save(m);
            return ApiResponse.success("会员信息已更新", "OK");
        }
        throw new ServiceException(404, "用户不存在");
    }

    public static String getClientIp(jakarta.servlet.http.HttpServletRequest req) {
        if (req == null) return "127.0.0.1";
        String ip = req.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = req.getHeader("Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = req.getHeader("WL-Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = req.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = req.getRemoteAddr();
        }
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip != null ? ip : "127.0.0.1";
    }

    public static String getClientDevice(jakarta.servlet.http.HttpServletRequest req) {
        return getClientDevice(req, null, null, null);
    }

    public static String getClientDevice(jakarta.servlet.http.HttpServletRequest req, String clientDevice, String clientPlatform, String deviceModel) {
        // 1. 优先使用客户端主动声明的设备名称
        if (clientDevice != null && !clientDevice.trim().isEmpty()) {
            return clientDevice.trim();
        }

        // 2. 检查客户端平台与机型参数
        if (clientPlatform != null && !clientPlatform.trim().isEmpty()) {
            String cp = clientPlatform.trim().toUpperCase();
            if (cp.contains("ANDROID")) {
                return (deviceModel != null && !deviceModel.trim().isEmpty()) ? "安卓手机 (" + deviceModel.trim() + ")" : "安卓手机 APP (Android)";
            }
            if (cp.contains("IOS") || cp.contains("IPHONE") || cp.contains("IPAD")) {
                return (deviceModel != null && !deviceModel.trim().isEmpty()) ? "苹果手机 (" + deviceModel.trim() + ")" : "苹果手机 APP (iOS)";
            }
            if (cp.contains("APP") || cp.contains("MOBILE")) {
                return "海马APP移动终端";
            }
        }

        if (req == null) return "Web 浏览器终端";

        // 3. 检查自定义 HTTP 请求头 (跨平台 App 统一在请求头中注入)
        String headerDevice = req.getHeader("X-Device-Type");
        if (headerDevice != null && !headerDevice.trim().isEmpty()) {
            return headerDevice.trim();
        }
        String headerPlatform = req.getHeader("X-Client-Platform");
        String headerModel = req.getHeader("X-Device-Model");
        if (headerPlatform != null && !headerPlatform.trim().isEmpty()) {
            String hp = headerPlatform.trim().toUpperCase();
            if (hp.contains("ANDROID")) {
                return (headerModel != null && !headerModel.trim().isEmpty()) ? "安卓手机 (" + headerModel.trim() + ")" : "安卓手机 APP (Android)";
            }
            if (hp.contains("IOS") || hp.contains("IPHONE") || hp.contains("IPAD")) {
                return (headerModel != null && !headerModel.trim().isEmpty()) ? "苹果手机 (" + headerModel.trim() + ")" : "苹果手机 APP (iOS)";
            }
            if (hp.contains("APP")) {
                return "海马APP移动终端";
            }
        }

        // 4. 解析 User-Agent 特征
        String ua = req.getHeader("User-Agent");
        if (ua == null || ua.isEmpty()) return "Web 浏览器终端";

        if (ua.contains("Android")) {
            return "安卓手机 APP (Android)";
        }
        if (ua.contains("iPhone") || ua.contains("iPad") || ua.contains("iOS") || ua.contains("Darwin") || ua.contains("CFNetwork")) {
            return "苹果手机 APP (iOS)";
        }
        if (ua.contains("Dart") || ua.contains("Flutter") || ua.contains("SeahorseApp")) {
            return "海马APP移动端 (安卓/iOS)";
        }
        if (ua.contains("MicroMessenger")) return "微信小程序 / 微信内置浏览器";
        if (ua.contains("AlipayClient")) return "支付宝小程序 / 生活号";
        if (ua.contains("Mobile")) return "移动端手机浏览器";
        if (ua.contains("Chrome")) return "Chrome 浏览器 (PC)";
        if (ua.contains("Firefox")) return "Firefox 浏览器 (PC)";
        if (ua.contains("Safari")) return "Safari 浏览器 (Mac)";
        if (ua.contains("Windows")) return "Windows PC 浏览器";
        return "Web 浏览器终端";
    }

    /**
     * 联动 FWPT 统一通行证中心 (OneID) 校验账号与口令
     */
    private Map<String, Object> verifyFwptAuth(String username, String password) {
        if (username == null || password == null || username.trim().isEmpty() || password.trim().isEmpty()) {
            return null;
        }
        String[] candidateUrls = new String[]{
                "http://101.35.100.169:8088/api/v1/auth/login",
                "https://fwpt.cn/api/v1/auth/login"
        };
        for (String targetUrl : candidateUrls) {
            try {
                java.net.URL url = new java.net.URL(targetUrl);
                java.net.HttpURLConnection conn = (java.net.HttpURLConnection) url.openConnection();
                if (conn instanceof javax.net.ssl.HttpsURLConnection) {
                    ((javax.net.ssl.HttpsURLConnection) conn).setHostnameVerifier((hostname, session) -> true);
                }
                conn.setRequestMethod("POST");
                conn.setRequestProperty("Content-Type", "application/json;charset=UTF-8");
                conn.setRequestProperty("User-Agent", "SeahorseBack/1.0 (FWPT-OneID-Bridge)");
                conn.setConnectTimeout(2500);
                conn.setReadTimeout(3000);
                conn.setDoOutput(true);

                String payload = "{\"username\":\"" + escapeJson(username) + "\",\"password\":\"" + escapeJson(password) + "\",\"account\":\"" + escapeJson(username) + "\"}";
                try (java.io.OutputStream os = conn.getOutputStream()) {
                    os.write(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                }

                int code = conn.getResponseCode();
                if (code == 200) {
                    try (java.io.InputStream is = conn.getInputStream();
                         java.io.BufferedReader reader = new java.io.BufferedReader(new java.io.InputStreamReader(is, java.nio.charset.StandardCharsets.UTF_8))) {
                        StringBuilder sb = new StringBuilder();
                        String line;
                        while ((line = reader.readLine()) != null) {
                            sb.append(line);
                        }
                        String respBody = sb.toString();
                        if (respBody.contains("已被管理员冻结")) {
                            Map<String, Object> frozenMap = new HashMap<>();
                            frozenMap.put("frozen", true);
                            return frozenMap;
                        }
                        if (respBody.contains("\"00000\"") && respBody.contains("\"token\"")) {
                            Map<String, Object> result = new HashMap<>();
                            result.put("username", username);
                            String realName = extractJsonField(respBody, "realName");
                            String phone = extractJsonField(respBody, "phone");
                            if (realName != null) result.put("realName", realName);
                            if (phone != null) result.put("phone", phone);
                            return result;
                        }
                        break;
                    }
                }
            } catch (Exception ignored) {}
        }
        return null;
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static String extractJsonField(String json, String field) {
        try {
            String pattern = "\"" + field + "\":\"";
            int idx = json.indexOf(pattern);
            if (idx != -1) {
                int start = idx + pattern.length();
                int end = json.indexOf("\"", start);
                if (end != -1) {
                    return json.substring(start, end);
                }
            }
        } catch (Exception ignored) {}
        return null;
    }
}
