package com.seahorse.store.domain.iam.enums;

/**
 * 系统人员与主体角色枚举
 */
public enum EmployeeRole {
    PLATFORM_DEVELOPER("系统开发维护人/平台运营"),
    SUPER_ADMIN("商户企业主/门店老板"),
    STORE_MANAGER("店长"),
    CASHIER("收银员"),
    TECHNICIAN("技师/施工人员"),
    WAITER("服务员"),
    CUSTOMER_MEMBER("顾客会员");

    private final String description;

    EmployeeRole(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
