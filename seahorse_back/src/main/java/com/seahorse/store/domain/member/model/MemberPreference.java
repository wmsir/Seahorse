package com.seahorse.store.domain.member.model;

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
 * 海马体核心特色：“海马记忆标签与偏好档案”
 * 精准记住每一位会员的个性喜好、特征与履约偏好。
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sh_member_preference")
@EntityListeners(AuditingEntityListener.class)
public class MemberPreference {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long memberId;

    @Column(nullable = false, length = 64)
    private String tenantId;

    // 偏好分类：BEAUTY_HAIR, RESTAURANT_TASTE, AUTO_VEHICLE, HABIT
    @Column(nullable = false, length = 64)
    private String category;

    // 标签键名，例如：
    // 美业: hair_texture(细软发质), scalp_condition(偏油敏感), preferred_stylist(指定发型师: 托尼老师), perm_brand(偏好施华蔻)
    // 餐饮: spicy_level(微辣免葱), tea_preference(偏好普洱), favorite_seat(喜欢靠窗位)
    // 汽修: license_plate(粤B66888), car_model(宝马325Li 2023款), oil_spec(金美孚 0W-20), mileage_interval(每7500公里保养)
    @Column(nullable = false, length = 64)
    private String tagKey;

    @Column(nullable = false, length = 255)
    private String tagValue;

    private String notes; // 补充说明
    private String updatedBy; // 录入/更新人

    @CreatedDate
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
