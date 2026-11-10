package com.seahorse.store.domain.iam.enums;

public enum IndustryType {
    RESTAURANT("餐饮轻食/正餐", "包厢", "加菜", "茶位费/餐具费"),
    BEAUTY("美容美发美甲", "工位", "加护理/烫染", "毛巾费/造型费"),
    AUTO("汽车养护维修", "工位", "增项/换滤芯", "工时环保费"),
    RETAIL("专营零售", "展位", "加购", "包装费"),
    FOOT_SPA("足道养生/SPA", "养生包厢", "加钟/升级精油", "养生茶位费"),
    TEA_HOUSE("茶座休闲/棋牌", "雅集茶室", "续水/茶点", "茶位服务费"),
    PET("宠物健康生活馆", "洗护工位", "加药浴/美容", "消毒护理费");

    private final String description;
    private final String spaceAlias;
    private final String appendActionAlias;
    private final String defaultFeeName;

    IndustryType(String description, String spaceAlias, String appendActionAlias, String defaultFeeName) {
        this.description = description;
        this.spaceAlias = spaceAlias;
        this.appendActionAlias = appendActionAlias;
        this.defaultFeeName = defaultFeeName;
    }

    public String getDescription() { return description; }
    public String getSpaceAlias() { return spaceAlias; }
    public String getAppendActionAlias() { return appendActionAlias; }
    public String getDefaultFeeName() { return defaultFeeName; }
}
