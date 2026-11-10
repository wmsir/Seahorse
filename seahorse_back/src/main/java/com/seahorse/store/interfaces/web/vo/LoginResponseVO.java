package com.seahorse.store.interfaces.web.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "员工及商户登录响应 VO")
public class LoginResponseVO {
    @Schema(description = "JWT 认证令牌")
    private String token;

    @Schema(description = "员工/用户ID")
    private Long userId;

    @Schema(description = "登录用户名")
    private String username;

    @Schema(description = "员工真实姓名")
    private String realName;

    @Schema(description = "组织角色代码")
    private String role;

    @Schema(description = "归属租户商户ID")
    private String tenantId;

    @Schema(description = "商户企业品牌名称")
    private String tenantName;

    @Schema(description = "当前默认门店编号")
    private String storeId;

    @Schema(description = "当前默认门店名称")
    private String storeName;

    @Schema(description = "当前默认门店行业模态代码")
    private String industry;

    @Schema(description = "当前订阅套餐版本")
    private String plan;

    @Schema(description = "套餐名称")
    private String planName;

    @Schema(description = "双轨储值扣减策略")
    private String deductMode;

    @Schema(description = "云存储容量配额(GB)")
    private Integer storageQuotaGb;

    @Schema(description = "套餐到期日")
    private LocalDate expireDate;

    @Schema(description = "套餐允许开设最大门店数")
    private Integer storeLimit;

    @Schema(description = "套餐允许员工名额上限")
    private Integer staffLimit;

    @Schema(description = "商户拥有的全部门店列表")
    private List<StoreItemVO> stores;

    @Schema(description = "当前角色生效的权限列表")
    private List<String> permissions;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StoreItemVO {
        private String storeId;
        private String storeName;
        private String industry;
        private String industryDesc;
        private String address;
        private String phone;
    }
}
