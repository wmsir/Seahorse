package com.seahorse.store.domain.leave.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_leave_application")
@EntityListeners(AuditingEntityListener.class)
public class LeaveApplication {

    @Id
    @Column(length = 64)
    private String id; // 业务流水单号如 LV-1789650000001

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(length = 64)
    private String storeId;

    private Long staffId;

    @Column(length = 64)
    private String staffName;

    @Column(length = 32)
    private String phone;

    @Column(length = 64)
    private String postName;

    @Column(length = 64)
    private String department;

    @Column(length = 32)
    private String leaveType; // PERSONAL | SICK | ANNUAL | REST | MATERNITY

    @Column(length = 64)
    private String leaveTypeName;

    @Column(length = 64)
    private String startTime;

    @Column(length = 64)
    private String endTime;

    private Double totalHours;

    private Double totalDays;

    @Column(columnDefinition = "TEXT")
    private String reason;

    @Column(length = 32)
    private String status; // PENDING | APPROVED | REJECTED | REVOKED

    @Column(length = 64)
    private String applyTime;

    @Column(length = 64)
    private String currentApprover;

    @Column(length = 64)
    private String auditTime;

    @Column(columnDefinition = "TEXT")
    private String auditNotes;

    @Column(columnDefinition = "TEXT")
    private String timelineJson;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
