package com.seahorse.store.domain.common.constant;

/**
 * 通用常量规范定义
 * 符合阿里巴巴 Java 开发手册：常量命名全大写，单词间下划线分隔，语义明确
 */
public final class CommonConstants {

    private CommonConstants() {
        // 禁止实例化工具类/常量类
    }

    /** 默认租户ID */
    public static final String DEFAULT_TENANT_ID = "T001";

    /** 默认门店ID */
    public static final String DEFAULT_STORE_ID = "S001";

    /** 状态常量：正常/启用 */
    public static final String STATUS_ACTIVE = "ACTIVE";

    /** 状态常量：停用/禁用 */
    public static final String STATUS_DISABLED = "DISABLED";

    /** 状态常量：冻结 */
    public static final String STATUS_FROZEN = "FROZEN";

    /** 性别：男 */
    public static final String GENDER_MALE = "MALE";

    /** 性别：女 */
    public static final String GENDER_FEMALE = "FEMALE";

    /** 性别：未知 */
    public static final String GENDER_UNKNOWN = "UNKNOWN";

    /** 操作人类型：顾客自助 */
    public static final String OPERATOR_TYPE_CUSTOMER = "CUSTOMER";

    /** 操作人类型：服务员/员工 */
    public static final String OPERATOR_TYPE_WAITER = "WAITER";
}
