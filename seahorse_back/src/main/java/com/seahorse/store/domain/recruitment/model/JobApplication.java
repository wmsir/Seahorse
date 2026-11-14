package com.seahorse.store.domain.recruitment.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * 岗位招聘与求职简历投递持久化实体
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_job_application")
@EntityListeners(AuditingEntityListener.class)
public class JobApplication {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 64)
    private String applicationNo;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(length = 128)
    private String storeName;

    private Long postId;

    @Column(length = 128)
    private String postName;

    @Column(nullable = false, length = 64)
    private String candidateName;

    @Column(length = 16)
    private String gender;

    private Integer age;

    @Column(nullable = false, length = 32)
    private String phone;

    @Column(length = 64)
    private String education;

    private Integer experienceYears;

    @Column(length = 64)
    private String expectedSalary;

    @Column(length = 64)
    private String availableDate;

    @Column(columnDefinition = "TEXT")
    private String personalAdvantage;

    @Column(columnDefinition = "TEXT")
    private String workHistory;

    @Column(length = 1000)
    private String certificates;

    @Column(length = 64)
    private String applyTime;

    @Column(length = 32)
    private String status;

    @Column(columnDefinition = "TEXT")
    private String interviewInfoJson;

    @Column(columnDefinition = "TEXT")
    private String interviewEvaluationJson;

    @Column(length = 500)
    private String rejectReason;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
