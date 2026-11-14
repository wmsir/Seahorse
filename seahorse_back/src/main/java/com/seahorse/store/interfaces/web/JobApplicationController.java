package com.seahorse.store.interfaces.web;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.recruitment.model.JobApplication;
import com.seahorse.store.infrastructure.repository.JobApplicationRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 岗位招聘与应聘简历跨端投递协同控制器（基于数据库持久化）
 */
@Slf4j
@Tag(name = "16. 岗位招聘与应聘简历管理", description = "支持手机端扫码提交简历与PC端实时查阅初筛")
@RestController
@RequestMapping("/api/job-application")
@RequiredArgsConstructor
public class JobApplicationController {

    private final JobApplicationRepository jobApplicationRepository;
    private final ObjectMapper objectMapper;

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
    @Transactional(rollbackFor = Exception.class)
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
        targetTenantId = targetTenantId.trim();
        req.setTenantId(targetTenantId);

        if (req.getApplyTime() == null || req.getApplyTime().trim().isEmpty()) {
            req.setApplyTime(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        }
        if (req.getStatus() == null || req.getStatus().trim().isEmpty()) {
            req.setStatus("PENDING");
        }

        List<JobApplication> existingList = jobApplicationRepository.findByTenantIdOrderByIdDesc(targetTenantId);
        JobApplication target = null;
        for (JobApplication existing : existingList) {
            boolean samePhone = existing.getPhone() != null && existing.getPhone().trim().equals(req.getPhone().trim());
            boolean samePost = (existing.getPostId() != null && req.getPostId() != null && existing.getPostId().equals(req.getPostId()))
                    || (existing.getPostName() != null && req.getPostName() != null && existing.getPostName().trim().equals(req.getPostName().trim()));
            if (samePhone && samePost) {
                target = existing;
                break;
            }
        }

        if (target != null) {
            req.setId(target.getApplicationNo());
            if (target.getStatus() != null && !"REJECTED".equals(target.getStatus()) && !"PENDING".equals(target.getStatus())) {
                req.setStatus(target.getStatus());
            }
            applyDtoToEntity(req, target);
            JobApplication saved = jobApplicationRepository.save(target);
            log.info("覆盖更新已有应聘简历: candidate={}, post={}, phone={}, tenant={}",
                    req.getCandidateName(), req.getPostName(), req.getPhone(), targetTenantId);
            return ApiResponse.success("简历投递成功，门店店长将尽快查阅与联系！", toDto(saved));
        }

        if (req.getId() == null || req.getId().trim().isEmpty()
                || jobApplicationRepository.findByApplicationNo(req.getId().trim()).isPresent()) {
            req.setId("APP" + System.currentTimeMillis() + (int) (Math.random() * 90 + 10));
        }

        JobApplication created = new JobApplication();
        created.setApplicationNo(req.getId().trim());
        applyDtoToEntity(req, created);
        JobApplication saved = jobApplicationRepository.save(created);
        log.info("新增求职者简历投递: candidate={}, post={}, phone={}, tenant={}",
                req.getCandidateName(), req.getPostName(), req.getPhone(), targetTenantId);

        return ApiResponse.success("简历投递成功，门店店长将尽快查阅与联系！", toDto(saved));
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
        targetTenantId = targetTenantId.trim();

        if (!"DEFAULT".equalsIgnoreCase(targetTenantId)) {
            TenantContext.assertTenantAccess(targetTenantId);
        }

        List<JobApplication> list = jobApplicationRepository.findByTenantIdOrderByIdDesc(targetTenantId);
        return ApiResponse.success(list.stream().map(this::toDto).toList());
    }

    @Operation(summary = "更新应聘简历状态")
    @PutMapping("/{id}/status")
    @Transactional(rollbackFor = Exception.class)
    public ApiResponse<String> updateStatus(
            @PathVariable("id") String id,
            @RequestBody Map<String, Object> body,
            @RequestParam(value = "tenantId", required = false) String paramTenantId) {
        String newStatus = body != null ? (String) body.get("status") : null;
        if (newStatus == null || newStatus.trim().isEmpty()) {
            return ApiResponse.error(400, "状态不能为空");
        }

        Optional<JobApplication> opt = jobApplicationRepository.findByApplicationNo(id);
        if (opt.isEmpty()) {
            return ApiResponse.error(404, "未找到该简历记录");
        }
        JobApplication entity = opt.get();

        if (TenantContext.isAuthenticated()) {
            TenantContext.assertTenantAccess(entity.getTenantId());
        } else {
            // 未登录场景仅允许候选人扫码入职登记完成后回写 HIRED 状态，且租户需匹配
            if (!"HIRED".equalsIgnoreCase(newStatus.trim())) {
                return ApiResponse.error(401, "未登录无权修改该简历审核状态");
            }
            if (paramTenantId != null && !paramTenantId.trim().isEmpty()
                    && !"DEFAULT".equalsIgnoreCase(entity.getTenantId())
                    && !paramTenantId.trim().equalsIgnoreCase(entity.getTenantId())) {
                return ApiResponse.error(403, "无权跨租户更新应聘简历状态");
            }
        }

        entity.setStatus(newStatus.trim());
        if (body.containsKey("interviewInfo")) {
            entity.setInterviewInfoJson(serializeMap(toStringObjectMap(body.get("interviewInfo"))));
        }
        if (body.containsKey("interviewEvaluation")) {
            entity.setInterviewEvaluationJson(serializeMap(toStringObjectMap(body.get("interviewEvaluation"))));
        }
        if (body.containsKey("rejectReason")) {
            entity.setRejectReason((String) body.get("rejectReason"));
        }
        jobApplicationRepository.save(entity);
        return ApiResponse.success("简历状态更新成功", "OK");
    }

    @Operation(summary = "删除简历记录")
    @DeleteMapping("/{id}")
    @Transactional(rollbackFor = Exception.class)
    public ApiResponse<String> deleteApplication(@PathVariable("id") String id) {
        Optional<JobApplication> opt = jobApplicationRepository.findByApplicationNo(id);
        if (opt.isPresent()) {
            JobApplication entity = opt.get();
            TenantContext.assertTenantAccess(entity.getTenantId());
            jobApplicationRepository.delete(entity);
        }
        return ApiResponse.success("简历记录已删除", "OK");
    }

    private void applyDtoToEntity(JobApplicationDTO dto, JobApplication entity) {
        entity.setTenantId(dto.getTenantId());
        entity.setStoreName(dto.getStoreName());
        entity.setPostId(dto.getPostId());
        entity.setPostName(dto.getPostName());
        entity.setCandidateName(dto.getCandidateName() != null ? dto.getCandidateName().trim() : "");
        entity.setGender(dto.getGender());
        entity.setAge(dto.getAge());
        entity.setPhone(dto.getPhone() != null ? dto.getPhone().trim() : "");
        entity.setEducation(dto.getEducation());
        entity.setExperienceYears(dto.getExperienceYears());
        entity.setExpectedSalary(dto.getExpectedSalary());
        entity.setAvailableDate(dto.getAvailableDate());
        entity.setPersonalAdvantage(dto.getPersonalAdvantage());
        entity.setWorkHistory(dto.getWorkHistory());
        entity.setCertificates(dto.getCertificates());
        entity.setApplyTime(dto.getApplyTime());
        entity.setStatus(dto.getStatus());
        if (dto.getInterviewInfo() != null) {
            entity.setInterviewInfoJson(serializeMap(dto.getInterviewInfo()));
        }
        if (dto.getInterviewEvaluation() != null) {
            entity.setInterviewEvaluationJson(serializeMap(dto.getInterviewEvaluation()));
        }
        if (dto.getRejectReason() != null) {
            entity.setRejectReason(dto.getRejectReason());
        }
    }

    private JobApplicationDTO toDto(JobApplication entity) {
        JobApplicationDTO dto = new JobApplicationDTO();
        dto.setId(entity.getApplicationNo());
        dto.setTenantId(entity.getTenantId());
        dto.setStoreName(entity.getStoreName());
        dto.setPostId(entity.getPostId());
        dto.setPostName(entity.getPostName());
        dto.setCandidateName(entity.getCandidateName());
        dto.setGender(entity.getGender());
        dto.setAge(entity.getAge());
        dto.setPhone(entity.getPhone());
        dto.setEducation(entity.getEducation());
        dto.setExperienceYears(entity.getExperienceYears());
        dto.setExpectedSalary(entity.getExpectedSalary());
        dto.setAvailableDate(entity.getAvailableDate());
        dto.setPersonalAdvantage(entity.getPersonalAdvantage());
        dto.setWorkHistory(entity.getWorkHistory());
        dto.setCertificates(entity.getCertificates());
        dto.setApplyTime(entity.getApplyTime());
        dto.setStatus(entity.getStatus());
        dto.setInterviewInfo(deserializeMap(entity.getInterviewInfoJson()));
        dto.setInterviewEvaluation(deserializeMap(entity.getInterviewEvaluationJson()));
        dto.setRejectReason(entity.getRejectReason());
        return dto;
    }

    private String serializeMap(Map<String, Object> map) {
        if (map == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(map);
        } catch (Exception e) {
            log.warn("序列化面试信息失败: {}", e.getMessage());
            return null;
        }
    }

    private Map<String, Object> deserializeMap(String json) {
        if (json == null || json.trim().isEmpty()) {
            return null;
        }
        try {
            return objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            log.warn("反序列化面试信息失败: {}", e.getMessage());
            return null;
        }
    }

    private Map<String, Object> toStringObjectMap(Object raw) {
        if (!(raw instanceof Map<?, ?> map)) {
            return null;
        }
        Map<String, Object> converted = new LinkedHashMap<>();
        for (Map.Entry<?, ?> entry : map.entrySet()) {
            if (entry.getKey() != null) {
                converted.put(String.valueOf(entry.getKey()), entry.getValue());
            }
        }
        return converted;
    }
}
