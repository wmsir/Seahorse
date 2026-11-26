package com.seahorse.store.domain.member.model;

import com.seahorse.store.common.ServiceException;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_time_card_bucket")
@EntityListeners(AuditingEntityListener.class)
public class TimeCardBucket {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long memberId;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false)
    private Long skuId; // 绑定的计量服务项目 ID

    @Column(nullable = false, length = 128)
    private String skuName; // 项目名称，如“总监洗剪吹”、“小保养工时”、“精油头皮理疗”

    @Column(nullable = false)
    private Integer totalTimes; // 购买总次数

    @Column(nullable = false)
    private Integer remainingTimes; // 剩余可用次数

    private LocalDate expireDate; // 过期日期

    private String status; // ACTIVE(有效), EXPIRED(已过期), EXHAUSTED(已耗尽)

    @Version
    @Column(nullable = false)
    private Long version; // JPA 乐观锁版本号

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public void deductTimes(int count) {
        if (remainingTimes == null || remainingTimes < count) {
            throw new ServiceException("次卡剩余次数不足（当前剩余 " + (remainingTimes == null ? 0 : remainingTimes) + " 次，需核销 " + count + " 次）");
        }
        if (expireDate != null && expireDate.isBefore(LocalDate.now())) {
            throw new ServiceException("次卡已于 " + expireDate + " 过期，无法核销");
        }
        this.remainingTimes -= count;
        if (this.remainingTimes == 0) {
            this.status = com.seahorse.store.domain.member.enums.TimeCardStatus.EXHAUSTED.name();
        }
    }
}
