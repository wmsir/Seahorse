package com.seahorse.store.domain.iam.model;

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
@Table(name = "sh_tenant")
@EntityListeners(AuditingEntityListener.class)
public class Tenant {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 64)
    private String tenantId;

    @Column(nullable = false, length = 128)
    private String tenantName;

    private String contactName;
    private String contactPhone;

    @Enumerated(EnumType.STRING)
    @Column(length = 32)
    private com.seahorse.store.domain.member.enums.DeductMode deductMode; // PROPORTIONAL, PRINCIPAL_FIRST

    private String status; // ACTIVE, DISABLED

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
