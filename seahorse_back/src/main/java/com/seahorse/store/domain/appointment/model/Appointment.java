package com.seahorse.store.domain.appointment.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_appointment")
@EntityListeners(AuditingEntityListener.class)
public class Appointment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false, length = 64)
    private String storeId;

    @Column(nullable = false, length = 64)
    private String aptNo;

    @Column(nullable = false, length = 64)
    private String customerName;

    @Column(nullable = false, length = 32)
    private String phone;

    @Builder.Default
    private Integer peopleCount = 1;

    @Column(length = 128)
    private String serviceName;

    private BigDecimal servicePrice;

    private String spaceCode;
    private String spaceName;
    private String staffName;

    @Column(nullable = false, length = 32)
    private String aptDate;

    @Column(nullable = false, length = 32)
    private String aptTime;

    @Builder.Default
    @Column(nullable = false, length = 32)
    private String status = "PENDING";

    @Column(length = 500)
    private String notes;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
