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
@Table(name = "sh_store_register_config")
@EntityListeners(AuditingEntityListener.class)
public class StoreRegisterConfig {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false, unique = true, length = 64)
    private String storeId;

    @Column(columnDefinition = "TEXT")
    private String preferenceTags; // JSON 数组字符串，例如 ["发质细软","喜静免推销"]

    @Column(columnDefinition = "TEXT")
    private String chargeOptions; // JSON 数组字符串，例如 [{"id":1,"title":"首充礼遇","principal":200,"gift":50}]

    private Boolean welcomeCouponEnabled;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
