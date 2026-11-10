package com.seahorse.store.application.dto.vendor;

import com.seahorse.store.domain.iam.enums.IndustryType;
import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import com.seahorse.store.domain.member.enums.DeductMode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 商户自主注册与配置自选命令对象
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MerchantRegisterCommand {
    private String username; // 管理员登录账号
    private String password; // 登录密码
    private String tenantName; // 企业/商户品牌名称
    private String contactName; // 联系人
    private String contactPhone; // 联系手机号 (必填)
    private String smsCode; // 短信验证码 (必填)

    private SubscriptionPlan plan; // 选购套餐：TRIAL(默认3天试用), PROFESSIONAL, FLAGSHIP, ENTERPRISE
    private DeductMode deductMode; // 储值扣减策略：PROPORTIONAL, PRINCIPAL_FIRST (可缺省，在开卡时指定)

    private String initialStoreName; // 首个门店名称
    private IndustryType initialIndustry; // 首店底层模态：BEAUTY, RESTAURANT, AUTO, RETAIL
    private Integer initialStoreCategoryId; // 细分行业分类ID (如 1, 6, 16 等)
    private String initialStoreCategoryName; // 细分行业名称 (如 汽车服务, 美业服务, 便利店 等)
    private String initialStoreCategoryGroup; // 行业大类 (服务类 | 零售类)
    private String storeAddress; // 门店地址

    // 前端表单别名兼容字段
    private String adminUsername;
    private String adminPassword;
    private String adminRealName;
    private IndustryType initialStoreIndustry;

    public String getUsername() {
        return username != null ? username : adminUsername;
    }

    public String getPassword() {
        return password != null ? password : adminPassword;
    }

    public String getContactName() {
        return contactName != null ? contactName : adminRealName;
    }

    public IndustryType getInitialIndustry() {
        return initialIndustry != null ? initialIndustry : initialStoreIndustry;
    }
}
