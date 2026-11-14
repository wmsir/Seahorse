package com.seahorse.store.domain.session.model;

import com.seahorse.store.domain.session.enums.SessionStatus;
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
@Table(name = "sh_service_session")
@EntityListeners(AuditingEntityListener.class)
public class ServiceSession {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false, length = 64)
    private String storeId;

    @Column(nullable = false, unique = true, length = 64)
    private String sessionNo;

    @Column(nullable = false)
    private Long spaceId;

    private String spaceCode;
    private String spaceName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private SessionStatus status;

    // 会员或客户信息
    private Long memberId;
    private String customerName;
    private String customerPhone;
    private Integer guestCount;

    // 费用
    private BigDecimal totalAmount;
    private BigDecimal discountAmount;
    private BigDecimal payableAmount;
    private BigDecimal feeAmount; // 附加费（茶位费、环保费、毛巾费）
    private String feeName; // 附加费名称
    private String notes; // 特殊要求备注

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public void recalculatePayable() {
        BigDecimal total = totalAmount != null ? totalAmount : BigDecimal.ZERO;
        BigDecimal fee = feeAmount != null ? feeAmount : BigDecimal.ZERO;
        BigDecimal discount = discountAmount != null ? discountAmount : BigDecimal.ZERO;
        this.payableAmount = total.add(fee).subtract(discount).max(BigDecimal.ZERO);
    }

    public String getTechnicianName() {
        if (this.notes != null && !this.notes.trim().isEmpty()) {
            if (this.notes.contains("|")) {
                String tech = this.notes.split("\\|")[0].trim();
                if (!tech.isEmpty()) {
                    return tech;
                }
            }
            return this.notes.trim();
        }
        return null;
    }
}
