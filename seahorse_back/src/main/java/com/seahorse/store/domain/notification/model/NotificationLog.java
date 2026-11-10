package com.seahorse.store.domain.notification.model;

import com.seahorse.store.domain.notification.enums.NotificationChannel;
import com.seahorse.store.domain.notification.enums.NotificationType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * 全渠道推送流水记录实体 (支持微信服务号与支付宝生活号审计)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_notification_log")
@EntityListeners(AuditingEntityListener.class)
public class NotificationLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(length = 64)
    private String storeId;

    private Long memberId;
    private String memberName;
    private String phone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private NotificationChannel channel;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private NotificationType msgType;

    @Column(length = 128)
    private String targetOpenId;

    @Column(length = 128)
    private String templateId;

    @Column(nullable = false, length = 256)
    private String title;

    @Column(length = 4000)
    private String content; // 格式化文本展示

    @Column(length = 4000)
    private String dataJson; // 微信/支付宝标准格式 JSON 参数

    @Column(nullable = false, length = 32)
    private String status; // SUCCESS, FAILED

    @Column(length = 1000)
    private String errorMessage;

    private LocalDateTime sentAt;

    @CreatedDate
    private LocalDateTime createdAt;
}
