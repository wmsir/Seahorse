package com.seahorse.store.domain.iam.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 高德地图与考勤定位服务配置实体
 */
@Data
@Entity
@Table(name = "sh_amap_config")
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmapConfig implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    @Column(name = "store_id", length = 64)
    private String storeId;

    /**
     * 高德 Web 服务 API Key (用于移动端高精度IP反查、基站反查、逆地理编码)
     */
    @Column(name = "web_api_key", length = 128)
    private String webApiKey;

    /**
     * 高德 JS API Key (用于管理后台Web端地图渲染)
     */
    @Column(name = "js_api_key", length = 128)
    private String jsApiKey;

    /**
     * 高德安全密钥 securityCode (用于新版JS API前端鉴权)
     */
    @Column(name = "security_code", length = 128)
    private String securityCode;

    /**
     * 考勤有效打卡半径偏差 (单位: 米，默认500米)
     */
    @Column(name = "allowed_radius_meters")
    private Integer allowedRadiusMeters;

    /**
     * 考勤打卡基准门店经度
     */
    @Column(name = "store_longitude")
    private Double storeLongitude;

    /**
     * 考勤打卡基准门店纬度
     */
    @Column(name = "store_latitude")
    private Double storeLatitude;

    /**
     * 门店标准地理详细地址
     */
    @Column(name = "store_address", length = 255)
    private String storeAddress;

    /**
     * 门店基准名称
     */
    @Column(name = "store_name", length = 128)
    private String storeName;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
