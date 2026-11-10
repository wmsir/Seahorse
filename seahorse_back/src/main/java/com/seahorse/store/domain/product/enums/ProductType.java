package com.seahorse.store.domain.product.enums;

public enum ProductType {
    SERVICE("计量服务项(虚拟工时)"),
    PHYSICAL("实物零售品(物理库存)"),
    MATERIAL("原料耗材(BOM配方消耗)");

    private final String description;

    ProductType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
