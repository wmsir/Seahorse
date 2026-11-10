package com.seahorse.store.interfaces.web.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "门店行业模态与配置策略 VO")
public class IndustryProfileVO {
    @Schema(description = "门店ID", example = "S001")
    private String storeId;

    @Schema(description = "门店名称", example = "海马智慧门店 (旗舰体验中心)")
    private String storeName;

    @Schema(description = "行业类型代码", example = "BEAUTY")
    private String industry;

    @Schema(description = "行业中文描述", example = "美容美发美甲")
    private String industryDesc;

    @Schema(description = "空间资源别名", example = "镜台")
    private String spaceAlias;

    @Schema(description = "追加项目动词", example = "加护理/烫染")
    private String appendActionAlias;

    @Schema(description = "附加费名称", example = "造型毛巾消毒费")
    private String defaultFeeName;

    @Schema(description = "附加费默认金额", example = "10.00")
    private BigDecimal defaultFeeAmount;

    @Schema(description = "是否默认开启附加费")
    private Boolean feeEnabled;

    @Schema(description = "细分行业分类ID", example = "6")
    private Integer industryCategoryId;

    @Schema(description = "细分行业名称", example = "美业服务")
    private String industryCategoryName;

    @Schema(description = "行业大类", example = "服务类")
    private String industryCategoryGroup;

    @Schema(description = "门店地址")
    private String address;

    @Schema(description = "门店联系电话")
    private String phone;

    @Schema(description = "营业时间")
    private String businessHours;
}
