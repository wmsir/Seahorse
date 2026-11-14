package com.seahorse.store.domain.attendance.model;

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
 * 员工考勤打卡流水持久化实体
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_attendance_record")
@EntityListeners(AuditingEntityListener.class)
public class AttendanceRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 64)
    private String recordNo;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(length = 64)
    private String storeId;

    @Column(length = 64)
    private String staffName;

    @Column(length = 32)
    private String phone;

    @Column(length = 64)
    private String postName;

    @Column(length = 32)
    private String workDate;

    @Column(length = 32)
    private String checkInTime;

    @Column(length = 32)
    private String checkInStatus;

    @Column(length = 32)
    private String checkOutTime;

    @Column(length = 32)
    private String checkOutStatus;

    private Double workHours;

    @Column(length = 255)
    private String checkInLocation;

    @Column(length = 32)
    private String platformSource;

    @Column(length = 500)
    private String notes;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
