package com.seahorse.store.domain.session.model;

import com.seahorse.store.domain.session.enums.SpaceStatus;
import com.seahorse.store.domain.session.enums.SpaceType;
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
@Table(name = "sh_service_space")
@EntityListeners(AuditingEntityListener.class)
public class ServiceSpace {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false, length = 64)
    private String storeId;

    @Column(nullable = false, length = 64)
    private String spaceCode; // 如 T01, M02, BAY-1

    @Column(nullable = false, length = 128)
    private String spaceName; // 如 大厅A01桌, 1号发型镜台, 2号举升机工位

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private SpaceType spaceType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private SpaceStatus status;

    private Integer capacity; // 容纳人数或车位数
    private String floorZone; // 区域（A区、二楼包厢、快修车间）
    private Long currentSessionId; // 当前在场会话 ID
    private String qrCodeUrl; // 聚合点单二维码 URL

    private BigDecimal minConsumeAmount; // 最低消费门槛 (元，0或空表示无门槛)
    private BigDecimal hourlyFee; // 钟点计时服务费 (元/小时，适用于棋牌/茶室/会议套房)
    private String facilities; // 配套设施标签 (逗号分隔，如：独立洗手间,功夫茶台,全景落地窗,高清投影)
    private String notes; // 备注与订房说明
    private Integer sortOrder; // 排序权重 (越小越靠前)

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public void occupy(Long sessionId) {
        this.status = SpaceStatus.OCCUPIED;
        this.currentSessionId = sessionId;
    }

    public void markDirty() {
        this.status = SpaceStatus.DIRTY;
        this.currentSessionId = null;
    }

    public void releaseToIdle() {
        this.status = SpaceStatus.IDLE;
        this.currentSessionId = null;
    }
}
