package com.seahorse.store.interfaces.web.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "当前登录人信息 VO")
public class UserInfoVO {
    @Schema(description = "用户ID")
    private Long userId;

    @Schema(description = "登录用户名")
    private String username;

    @Schema(description = "租户ID")
    private String tenantId;

    @Schema(description = "当前门店ID")
    private String storeId;
}
