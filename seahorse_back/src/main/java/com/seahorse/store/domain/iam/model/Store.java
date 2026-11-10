package com.seahorse.store.domain.iam.model;

import com.seahorse.store.domain.iam.enums.IndustryType;
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
@Table(name = "sh_store")
@EntityListeners(AuditingEntityListener.class)
public class Store {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 64)
    private String tenantId;

    @Column(nullable = false, unique = true, length = 64)
    private String storeId;

    @Column(nullable = false, length = 128)
    private String storeName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private IndustryType industry;

    private Integer industryCategoryId; // 细分行业分类ID (如 1, 6, 16 等)
    private String industryCategoryName; // 细分行业名称 (如 汽车服务, 美业服务, 便利店 等)
    private String industryCategoryGroup; // 行业大类 (服务类 | 零售类)

    private String address;
    private String phone;
    private String businessHours;

    // 行业附加费配置（如茶位费、毛巾费、工时环保费）
    private String feeName;
    private BigDecimal defaultFeeAmount;
    private Boolean feeEnabled;

    private String status; // ACTIVE, DISABLED

    // 门店专属自定义在招岗位与所属部门架构 JSON (用于移动端免登精准展示与配置持久化)
    @Column(columnDefinition = "TEXT")
    private String customPositionsJson;

    @Column(columnDefinition = "TEXT")
    private String customDepartmentsJson;

    // 门店常用服务要求与特殊备注标签 JSON (多端双向同步，如：微辣、免葱姜蒜、加重力度等)
    @Column(columnDefinition = "TEXT")
    private String commonRemarksJson;

    // 服务人员在APP与前台加项下拉中的称呼展示规则 (NICKNAME_FIRST: 优先店内称呼, REAL_NAME: 真实姓名, NICKNAME: 仅店内称呼, BOTH: 姓名(称呼))
    @Column(length = 32)
    private String staffDisplayMode;

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
