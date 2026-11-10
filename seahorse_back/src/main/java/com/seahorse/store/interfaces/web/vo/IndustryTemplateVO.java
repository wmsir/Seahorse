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
@Schema(description = "行业模态模板 VO")
public class IndustryTemplateVO {
    @Schema(description = "行业代码", example = "RESTAURANT")
    private String code;

    @Schema(description = "行业名称", example = "餐饮轻食/正餐")
    private String name;

    @Schema(description = "空间称谓", example = "桌台")
    private String spaceAlias;

    @Schema(description = "追加动作动词", example = "加菜加酒水")
    private String appendActionAlias;

    @Schema(description = "默认附加费名称", example = "茶位费/餐具费")
    private String defaultFeeName;
}
