package com.seahorse.store.domain.session.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_order_batch")
@EntityListeners(AuditingEntityListener.class)
public class OrderBatch {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long sessionId;

    @Column(nullable = false)
    private Integer batchNo; // 批次号 1, 2, 3...

    private Long operatorId;
    private String operatorName;
    private String operatorType; // CUSTOMER(顾客扫码), WAITER(员工录入)

    @CreatedDate
    private LocalDateTime createdAt;
}
