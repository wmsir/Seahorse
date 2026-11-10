package com.seahorse.store.domain.notice.model;

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
 * 门店运营规范与日常公告实体
 * 支持店长或租户老板配置后向 Web 浏览器与手机端 APP 全渠道推送
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_store_notice", indexes = {
        @Index(name = "idx_store_notice_store_id", columnList = "storeId"),
        @Index(name = "idx_store_notice_tenant_id", columnList = "tenantId")
})
@EntityListeners(AuditingEntityListener.class)
public class StoreNotice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    /**
     * 所属门店ID：'ALL' 代表全连锁通用，否则为具体门店编码如 'S84624'
     */
    @Column(nullable = false, length = 64)
    private String storeId;

    /**
     * 规范/公告标题
     */
    @Column(nullable = false, length = 256)
    private String title;

    /**
     * 类别：REGULATION (门店运营规范), NOTICE (日常业务公告), URGENT (特急重要通知)
     */
    @Column(nullable = false, length = 32)
    private String category;

    /**
     * 类别中文名，如：服务礼仪、安全生产、打烊消杀、日常公告、特急通知
     */
    @Column(length = 64)
    private String categoryName;

    /**
     * 核心摘要
     */
    @Column(length = 500)
    private String summary;

    /**
     * 详细条款或公告正文
     */
    @Column(columnDefinition = "TEXT")
    private String content;

    /**
     * 核心要点速览（用于海报/重点提醒，以分号隔开或JSON）
     */
    @Column(length = 1000)
    private String keyPoints;

    /**
     * 版本号（如 V1.0、V2.2）
     */
    @Column(length = 32)
    private String version;

    /**
     * 生效日期，如 "2026-09-16"
     */
    @Column(length = 32)
    private String effectiveDate;

    /**
     * 发布人姓名（店长/老板）
     */
    @Column(length = 64)
    private String publisher;

    /**
     * 发布人角色（STORE_MANAGER, STORE_OWNER, etc.）
     */
    @Column(length = 32)
    private String publisherRole;

    /**
     * 是否特别重要 / 特急通知
     */
    @Builder.Default
    private Boolean isUrgent = false;

    /**
     * 推送到手机 APP 是否播放提示音乐
     */
    @Builder.Default
    private Boolean playMusic = false;

    /**
     * 是否强制员工电子签名
     */
    @Builder.Default
    private Boolean requireSignature = false;

    /**
     * 状态：PUBLISHED (已生效发布), REVOKED (已撤回/废止)
     */
    @Builder.Default
    @Column(length = 32)
    private String status = "PUBLISHED";

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
