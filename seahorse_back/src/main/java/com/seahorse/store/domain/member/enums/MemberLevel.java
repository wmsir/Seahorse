package com.seahorse.store.domain.member.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import java.math.BigDecimal;

public enum MemberLevel {
    REGULAR("普卡会员", 0, BigDecimal.valueOf(1.00), BigDecimal.valueOf(1.00), "进店建档、海马体个性偏好常态记忆、消费基础积分"),
    SILVER("荣耀银卡", 300, BigDecimal.valueOf(0.95), BigDecimal.valueOf(0.98), "服务95折、商品98折、生日月享50元抵用券、双倍积分日"),
    GOLD("黄金VIP卡", 800, BigDecimal.valueOf(0.90), BigDecimal.valueOf(0.95), "服务9折、商品95折、免排队预约优先通道、生日免费专属体验"),
    VIP("VIP尊享卡", 1200, BigDecimal.valueOf(0.88), BigDecimal.valueOf(0.92), "服务88折、商品92折、专属金牌技师优先点单、节日私享定制礼盒"),
    PLATINUM("至尊白金卡", 2000, BigDecimal.valueOf(0.85), BigDecimal.valueOf(0.90), "服务85折、商品90折、专属私享包间、免费携带1位亲友享同等折扣"),
    DIAMOND("黑钻至尊卡", 3500, BigDecimal.valueOf(0.80), BigDecimal.valueOf(0.85), "服务8折、商品85折、总监技师免服务费、终身顶格尊崇待遇、年度私享盛典");

    private final String description;
    private final int growthThreshold; // 升级所需积分/成长经验门槛
    private final BigDecimal serviceDiscount; // 服务类折扣
    private final BigDecimal productDiscount; // 实物商品折扣
    private final String privileges; // 等级特权

    MemberLevel(String description, int growthThreshold, BigDecimal serviceDiscount, BigDecimal productDiscount, String privileges) {
        this.description = description;
        this.growthThreshold = growthThreshold;
        this.serviceDiscount = serviceDiscount;
        this.productDiscount = productDiscount;
        this.privileges = privileges;
    }

    public String getDescription() { return description; }
    public int getGrowthThreshold() { return growthThreshold; }
    public BigDecimal getServiceDiscount() { return serviceDiscount; }
    public BigDecimal getProductDiscount() { return productDiscount; }
    public String getPrivileges() { return privileges; }

    /**
     * 获取下一个升级目标等级 (已达最高级则返回 null)
     */
    public MemberLevel getNextLevel() {
        switch (this) {
            case REGULAR: return SILVER;
            case SILVER: return GOLD;
            case GOLD: return VIP;
            case VIP: return PLATINUM;
            case PLATINUM: return DIAMOND;
            case DIAMOND: return null;
            default: return null;
        }
    }

    /**
     * 获取下一等级升级门槛
     */
    public int getNextThreshold() {
        MemberLevel next = getNextLevel();
        return next != null ? next.getGrowthThreshold() : this.growthThreshold;
    }

    /**
     * 计算距离下一级还差多少积分/经验
     */
    public int getPointsToNext(int currentPoints) {
        MemberLevel next = getNextLevel();
        if (next == null) {
            return 0;
        }
        return Math.max(0, next.getGrowthThreshold() - currentPoints);
    }

    /**
     * 计算当前等级到下一等级的升级进度比率 (0.0 ~ 1.0)
     */
    public double getGrowthProgressRatio(int currentPoints) {
        MemberLevel next = getNextLevel();
        if (next == null) {
            return 1.0;
        }
        int range = next.getGrowthThreshold() - this.growthThreshold;
        if (range <= 0) {
            return 1.0;
        }
        int currentInLevel = Math.max(0, currentPoints - this.growthThreshold);
        return Math.min(1.0, Math.max(0.0, (double) currentInLevel / range));
    }

    /**
     * 根据当前积分自动计算应处的最高会员等级 (自动晋升检测)
     */
    public static MemberLevel calculateLevelByGrowth(int currentPoints) {
        MemberLevel[] levels = values();
        for (int i = levels.length - 1; i >= 0; i--) {
            if (currentPoints >= levels[i].getGrowthThreshold()) {
                return levels[i];
            }
        }
        return REGULAR;
    }

    /**
     * 根据累计充值本金自动计算对应的最高会员等级
     */
    public static MemberLevel calculateLevelByRecharge(BigDecimal rechargedAmount) {
        if (rechargedAmount == null) {
            return REGULAR;
        }
        if (rechargedAmount.compareTo(new BigDecimal("3500")) >= 0) return DIAMOND;
        if (rechargedAmount.compareTo(new BigDecimal("2000")) >= 0) return PLATINUM;
        if (rechargedAmount.compareTo(new BigDecimal("1200")) >= 0) return VIP;
        if (rechargedAmount.compareTo(new BigDecimal("800")) >= 0) return GOLD;
        if (rechargedAmount.compareTo(new BigDecimal("300")) >= 0) return SILVER;
        return REGULAR;
    }

    @JsonCreator
    public static MemberLevel fromString(String value) {
        if (value == null || value.trim().isEmpty()) {
            return REGULAR;
        }
        String v = value.trim().toUpperCase();
        for (MemberLevel level : values()) {
            if (level.name().equalsIgnoreCase(v)) {
                return level;
            }
        }
        if (v.contains("DIAMOND") || v.contains("黑钻") || v.contains("黑金") || v.contains("钻")) return DIAMOND;
        if (v.contains("PLATINUM") || v.contains("白金") || v.contains("铂金")) return PLATINUM;
        if (v.contains("VIP尊享") || v.contains("尊享") || v.equals("VIP")) return VIP;
        if (v.contains("GOLD") || v.contains("黄金") || v.contains("金")) return GOLD;
        if (v.contains("SILVER") || v.contains("银")) return SILVER;
        return REGULAR;
    }
}
