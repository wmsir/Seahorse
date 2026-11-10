package com.seahorse.store.interfaces.web;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.io.File;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * 岗位招聘与应聘简历跨端投递协同控制器
 */
@Slf4j
@Tag(name = "16. 岗位招聘与应聘简历管理", description = "支持手机端扫码提交简历与PC端实时查阅初筛")
@RestController
@RequestMapping("/api/job-application")
public class JobApplicationController {

    private static final String STORAGE_FILE_PATH = "data/job_applications_store.json";
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final Map<String, List<JobApplicationDTO>> applicationMap = new ConcurrentHashMap<>();

    public JobApplicationController() {
        loadFromDisk();
    }

    @Data
    public static class JobApplicationDTO {
        private String id;
        private String tenantId;
        private String storeName;
        private Long postId;
        private String postName;
        private String candidateName;
        private String gender;
        private Integer age;
        private String phone;
        private String education;
        private Integer experienceYears;
        private String expectedSalary;
        private String availableDate;
        private String personalAdvantage;
        private String workHistory;
        private String certificates;
        private String applyTime;
        private String status; // PENDING | INTERVIEW_SCHEDULED | PASSED | HIRED | REJECTED
        private Map<String, Object> interviewInfo;
        private Map<String, Object> interviewEvaluation;
        private String rejectReason;
    }

    @Operation(summary = "手机扫码求职者在线提交应聘简历")
    @PostMapping("/submit")
    public ApiResponse<JobApplicationDTO> submitApplication(@RequestBody JobApplicationDTO req) {
        if (req.getCandidateName() == null || req.getCandidateName().trim().isEmpty()) {
            return ApiResponse.error(400, "请填写求职者真实姓名");
        }
        if (req.getPhone() == null || req.getPhone().trim().isEmpty()) {
            return ApiResponse.error(400, "请填写联系电话");
        }

        String targetTenantId = req.getTenantId();
        if (targetTenantId == null || targetTenantId.trim().isEmpty() || "undefined".equalsIgnoreCase(targetTenantId)) {
            targetTenantId = TenantContext.getTenantId();
        }
        if (targetTenantId == null || targetTenantId.trim().isEmpty()) {
            targetTenantId = "DEFAULT";
        }
        req.setTenantId(targetTenantId);

        if (req.getId() == null || req.getId().trim().isEmpty()) {
            req.setId("APP" + (System.currentTimeMillis() % 100000000));
        }
        if (req.getApplyTime() == null || req.getApplyTime().trim().isEmpty()) {
            req.setApplyTime(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        }
        if (req.getStatus() == null || req.getStatus().trim().isEmpty()) {
            req.setStatus("PENDING");
        }

        List<JobApplicationDTO> list = applicationMap.computeIfAbsent(targetTenantId, k -> new CopyOnWriteArrayList<>());

        // 同一手机号码和岗位再次修改编辑的，直接覆盖更新已有数据，而不是生成多份重复数据
        boolean updated = false;
        for (int i = 0; i < list.size(); i++) {
            JobApplicationDTO existing = list.get(i);
            boolean samePhone = existing.getPhone() != null && existing.getPhone().trim().equals(req.getPhone().trim());
            boolean samePost = (existing.getPostId() != null && req.getPostId() != null && existing.getPostId().equals(req.getPostId()))
                    || (existing.getPostName() != null && req.getPostName() != null && existing.getPostName().trim().equals(req.getPostName().trim()));
            if (samePhone && samePost) {
                // 保留原记录 ID 和非初筛的面试/录用状态
                req.setId(existing.getId());
                if (existing.getStatus() != null && !"REJECTED".equals(existing.getStatus()) && !"PENDING".equals(existing.getStatus())) {
                    req.setStatus(existing.getStatus());
                }
                list.set(i, req);
                updated = true;
                log.info("覆盖更新已有应聘简历: candidate={}, post={}, phone={}, tenant={}", req.getCandidateName(), req.getPostName(), req.getPhone(), targetTenantId);
                break;
            }
        }

        if (!updated) {
            list.add(0, req);
            log.info("新增求职者简历投递: candidate={}, post={}, phone={}, tenant={}", req.getCandidateName(), req.getPostName(), req.getPhone(), targetTenantId);
        }

        saveToDisk();

        return ApiResponse.success("简历投递成功，门店店长将尽快查阅与联系！", req);
    }

    @Operation(summary = "获取当前租户的应聘简历列表")
    @GetMapping("/list")
    public ApiResponse<List<JobApplicationDTO>> getApplicationList(
            @RequestParam(value = "tenantId", required = false) String paramTenantId) {
        String targetTenantId = paramTenantId;
        if (targetTenantId == null || targetTenantId.trim().isEmpty() || "undefined".equalsIgnoreCase(targetTenantId)) {
            targetTenantId = TenantContext.getTenantId();
        }
        if (targetTenantId == null || targetTenantId.trim().isEmpty()) {
            targetTenantId = "DEFAULT";
        }

        List<JobApplicationDTO> list = applicationMap.getOrDefault(targetTenantId, Collections.emptyList());
        if (list.isEmpty() && !"DEFAULT".equals(targetTenantId) && applicationMap.containsKey("DEFAULT")) {
            List<JobApplicationDTO> defaultList = applicationMap.get("DEFAULT");
            return ApiResponse.success(new ArrayList<>(defaultList));
        }
        return ApiResponse.success(new ArrayList<>(list));
    }

    @Operation(summary = "更新应聘简历状态")
    @PutMapping("/{id}/status")
    public ApiResponse<String> updateStatus(
            @PathVariable("id") String id,
            @RequestBody Map<String, Object> body,
            @RequestParam(value = "tenantId", required = false) String paramTenantId) {
        String targetTenantId = paramTenantId;
        if (targetTenantId == null || targetTenantId.trim().isEmpty()) {
            targetTenantId = TenantContext.getTenantId();
        }

        String newStatus = (String) body.get("status");
        if (newStatus == null) {
            return ApiResponse.error(400, "状态不能为空");
        }

        boolean found = false;
        Collection<List<JobApplicationDTO>> targets = (targetTenantId != null && applicationMap.containsKey(targetTenantId))
                ? Collections.singletonList(applicationMap.get(targetTenantId))
                : applicationMap.values();

        for (List<JobApplicationDTO> list : targets) {
            for (JobApplicationDTO item : list) {
                if (id.equals(item.getId())) {
                    item.setStatus(newStatus);
                    if (body.containsKey("interviewInfo")) {
                        item.setInterviewInfo((Map<String, Object>) body.get("interviewInfo"));
                    }
                    if (body.containsKey("interviewEvaluation")) {
                        item.setInterviewEvaluation((Map<String, Object>) body.get("interviewEvaluation"));
                    }
                    if (body.containsKey("rejectReason")) {
                        item.setRejectReason((String) body.get("rejectReason"));
                    }
                    found = true;
                    break;
                }
            }
            if (found) break;
        }

        if (found) {
            saveToDisk();
            return ApiResponse.success("简历状态更新成功", "OK");
        }
        return ApiResponse.error(404, "未找到该简历记录");
    }

    @Operation(summary = "删除简历记录")
    @DeleteMapping("/{id}")
    public ApiResponse<String> deleteApplication(@PathVariable("id") String id) {
        for (List<JobApplicationDTO> list : applicationMap.values()) {
            list.removeIf(item -> id.equals(item.getId()));
        }
        saveToDisk();
        return ApiResponse.success("简历记录已删除", "OK");
    }

    private synchronized void saveToDisk() {
        try {
            File file = new File(STORAGE_FILE_PATH);
            File parent = file.getParentFile();
            if (parent != null && !parent.exists()) {
                parent.mkdirs();
            }
            objectMapper.writeValue(file, applicationMap);
        } catch (Exception e) {
            log.warn("保存简历数据到磁盘失败: {}", e.getMessage());
        }
    }

    private synchronized void loadFromDisk() {
        try {
            File file = new File(STORAGE_FILE_PATH);
            if (file.exists() && file.length() > 0) {
                Map<String, List<JobApplicationDTO>> loaded = objectMapper.readValue(
                        file,
                        new TypeReference<Map<String, List<JobApplicationDTO>>>() {}
                );
                if (loaded != null) {
                    applicationMap.putAll(loaded);
                    log.info("成功从磁盘恢复简历数据，共包含 {} 个商户", applicationMap.size());
                }
            }
        } catch (Exception e) {
            log.warn("从磁盘加载简历数据失败: {}", e.getMessage());
        }
    }
}
