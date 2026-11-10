package com.seahorse.store.domain.session.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_session_line_item")
@EntityListeners(AuditingEntityListener.class)
public class SessionLineItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long sessionId;

    @Column(nullable = false)
    private Long batchId;

    private Integer batchNo;

    @Column(nullable = false)
    private Long productId;

    @Column(nullable = false, length = 128)
    private String productName;

    private String productType; // PHYSICAL, SERVICE, MATERIAL
    private String categoryName;

    @Column(nullable = false)
    private BigDecimal price;

    @Column(nullable = false)
    private Integer quantity;

    @Column(nullable = false)
    private BigDecimal subtotal;

    // 动态规格定制属性（例如微辣、免葱；欧莱雅药水；5W-40机油等）
    private String modifiers;

    private String status; // ACTIVE, CANCELLED
    private String cancelReason;

    @CreatedDate
    private LocalDateTime createdAt;
}
