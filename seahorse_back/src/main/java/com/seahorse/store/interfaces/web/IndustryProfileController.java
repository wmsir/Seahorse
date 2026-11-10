package com.seahorse.store.interfaces.web;

import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.iam.enums.IndustryType;
import com.seahorse.store.domain.iam.model.IndustryCategoryConfig;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.infrastructure.repository.IndustryCategoryRepository;
import com.seahorse.store.infrastructure.repository.StoreRepository;
import com.seahorse.store.interfaces.web.vo.IndustryProfileVO;
import com.seahorse.store.interfaces.web.vo.IndustryTemplateVO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.*;

/**
 * 行业模态与细分配置策略控制器
 * 支持服务类、零售类层级分类与管理员初次使用/日常定制编辑
 */
@Tag(name = "08. 行业模态与策略配置", description = "全场景通用插拔架构：餐饮(F&B)、美业(Beauty)、汽修(Auto)与零售一键切换")
@RestController
@RequestMapping("/api/industry")
@RequiredArgsConstructor
public class IndustryProfileController {

    private final StoreRepository storeRepository;
    private final IndustryCategoryRepository industryCategoryRepository;

    @Operation(summary = "获取当前门店行业模式与细分配置策略")
    @GetMapping("/current")
    public ApiResponse<IndustryProfileVO> getCurrentIndustry() {
        String storeId = TenantContext.getStoreId();
        String tenantId = TenantContext.getTenantId();
        Store store = null;

        if (tenantId != null && !"PLATFORM".equalsIgnoreCase(tenantId) && !"T001".equalsIgnoreCase(tenantId)) {
            if (storeId != null && !"PLATFORM".equalsIgnoreCase(storeId) && !"S001".equalsIgnoreCase(storeId)) {
                store = storeRepository.findByStoreIdAndTenantId(storeId, tenantId).orElse(null);
            }
            if (store == null) {
                List<Store> tenantStores = storeRepository.findByTenantId(tenantId);
                if (!tenantStores.isEmpty()) {
                    store = tenantStores.get(0);
                }
            }
            if (store == null) {
                // 新商户纯净零数据状态：尚未创建首家门店与行业分类，返回待设置状态，绝不默认回退至其他租户
                return ApiResponse.success(IndustryProfileVO.builder()
                        .storeId(null)
                        .storeName("")
                        .industry(null)
                        .industryDesc("待设置")
                        .spaceAlias("工位/包厢")
                        .appendActionAlias("加项/加钟")
                        .defaultFeeName("服务费")
                        .defaultFeeAmount(BigDecimal.ZERO)
                        .feeEnabled(false)
                        .industryCategoryId(null)
                        .industryCategoryName(null)
                        .industryCategoryGroup(null)
                        .build());
            }
        } else {
            if (storeId != null && !"PLATFORM".equalsIgnoreCase(storeId)) {
                store = storeRepository.findByStoreId(storeId).orElse(null);
            }
            if (store == null && tenantId != null && !"PLATFORM".equalsIgnoreCase(tenantId)) {
                List<Store> tenantStores = storeRepository.findByTenantId(tenantId);
                if (!tenantStores.isEmpty()) {
                    store = tenantStores.get(0);
                }
            }
            if (store == null && (tenantId == null || "PLATFORM".equalsIgnoreCase(tenantId) || "T001".equalsIgnoreCase(tenantId))) {
                store = storeRepository.findByStoreId("S001").orElse(null);
            }
            if (store == null) {
                return ApiResponse.success(IndustryProfileVO.builder()
                        .storeId("PLATFORM")
                        .storeName("SaaS平台全局开发运维中心")
                        .industry("BEAUTY")
                        .industryDesc("全场景SaaS平台")
                        .spaceAlias("工位/包厢")
                        .appendActionAlias("加项/加钟")
                        .defaultFeeName("服务费")
                        .defaultFeeAmount(BigDecimal.ZERO)
                        .feeEnabled(false)
                        .build());
            }
        }

        IndustryProfileVO vo = IndustryProfileVO.builder()
                .storeId(store.getStoreId())
                .storeName(store.getStoreName())
                .industry(store.getIndustry() != null ? store.getIndustry().name() : "BEAUTY")
                .industryDesc(store.getIndustry() != null ? store.getIndustry().getDescription() : "通用实体")
                .spaceAlias(store.getIndustry() != null ? store.getIndustry().getSpaceAlias() : "工位")
                .appendActionAlias(store.getIndustry() != null ? store.getIndustry().getAppendActionAlias() : "加项")
                .defaultFeeName(store.getFeeName() != null ? store.getFeeName() : (store.getIndustry() != null ? store.getIndustry().getDefaultFeeName() : "服务费"))
                .defaultFeeAmount(store.getDefaultFeeAmount())
                .feeEnabled(store.getFeeEnabled())
                .industryCategoryId(store.getIndustryCategoryId())
                .industryCategoryName(store.getIndustryCategoryName())
                .industryCategoryGroup(store.getIndustryCategoryGroup())
                .address(store.getAddress())
                .phone(store.getPhone())
                .businessHours(store.getBusinessHours())
                .build();

        return ApiResponse.success(vo);
    }

    @Operation(summary = "获取系统支持的所有行业基础模板列表")
    @GetMapping("/templates")
    public ApiResponse<List<IndustryTemplateVO>> getTemplates() {
        List<IndustryTemplateVO> list = new ArrayList<>();
        for (IndustryType type : IndustryType.values()) {
            list.add(IndustryTemplateVO.builder()
                    .code(type.name())
                    .name(type.getDescription())
                    .spaceAlias(type.getSpaceAlias())
                    .appendActionAlias(type.getAppendActionAlias())
                    .defaultFeeName(type.getDefaultFeeName())
                    .build());
        }
        return ApiResponse.success(list);
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategoryItemVO {
        private Integer id;
        private String name;
        private String defaultIndustryType;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategoryGroupVO {
        private String name; // "服务类" | "零售类"
        private List<CategoryItemVO> data;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class IndustryCategoriesResponseVO {
        private List<CategoryGroupVO> all;
    }

    @Operation(summary = "获取全行业分类树 (服务类/零售类)")
    @GetMapping("/categories")
    public ApiResponse<IndustryCategoriesResponseVO> getCategories() {
        List<IndustryCategoryConfig> allConfigs = industryCategoryRepository.findAllByOrderBySortOrderAsc();
        Map<String, List<CategoryItemVO>> groupMap = new LinkedHashMap<>();
        groupMap.put("服务类", new ArrayList<>());
        groupMap.put("零售类", new ArrayList<>());

        for (IndustryCategoryConfig cfg : allConfigs) {
            String grp = cfg.getGroupName() != null ? cfg.getGroupName() : "服务类";
            groupMap.computeIfAbsent(grp, k -> new ArrayList<>())
                    .add(CategoryItemVO.builder()
                            .id(cfg.getId())
                            .name(cfg.getName())
                            .defaultIndustryType(cfg.getDefaultIndustryType())
                            .build());
        }

        List<CategoryGroupVO> all = new ArrayList<>();
        for (Map.Entry<String, List<CategoryItemVO>> entry : groupMap.entrySet()) {
            all.add(CategoryGroupVO.builder().name(entry.getKey()).data(entry.getValue()).build());
        }

        return ApiResponse.success(IndustryCategoriesResponseVO.builder().all(all).build());
    }

    private Store resolveCurrentStore() {
        String tenantId = TenantContext.getTenantId();
        String storeId = TenantContext.getStoreId();
        Store store = null;
        if (tenantId != null && !"PLATFORM".equalsIgnoreCase(tenantId) && !"T001".equalsIgnoreCase(tenantId)) {
            if (storeId != null && !"PLATFORM".equalsIgnoreCase(storeId) && !"S001".equalsIgnoreCase(storeId)) {
                store = storeRepository.findByStoreIdAndTenantId(storeId, tenantId).orElse(null);
            }
            if (store == null) {
                List<Store> tenantStores = storeRepository.findByTenantId(tenantId);
                if (!tenantStores.isEmpty()) {
                    store = tenantStores.get(0);
                }
            }
        } else {
            if (storeId != null && !"PLATFORM".equalsIgnoreCase(storeId)) {
                store = storeRepository.findByStoreId(storeId).orElse(null);
            }
            if (store == null) {
                store = storeRepository.findByStoreId("S001").orElse(null);
            }
        }
        if (store == null) {
            throw new ServiceException("未找到门店信息，请先创建首家门店！");
        }
        return store;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UpdateStoreCategoryCommand {
        private Integer categoryId;
        private String categoryName;
        private String categoryGroup;
    }

    @Operation(summary = "门店初次使用或管理员修改行业细分分类配置")
    @PostMapping("/store-category")
    public ApiResponse<Store> updateStoreCategory(@RequestBody UpdateStoreCategoryCommand cmd) {
        Store store = resolveCurrentStore();

        if (cmd.getCategoryId() != null) {
            store.setIndustryCategoryId(cmd.getCategoryId());
            IndustryCategoryConfig cfg = industryCategoryRepository.findById(cmd.getCategoryId()).orElse(null);
            if (cfg != null) {
                if (cfg.getDefaultIndustryType() != null) {
                    try {
                        store.setIndustry(IndustryType.valueOf(cfg.getDefaultIndustryType()));
                    } catch (Exception ignored) {}
                }
                if (cmd.getCategoryName() == null) {
                    store.setIndustryCategoryName(cfg.getName());
                }
                if (cmd.getCategoryGroup() == null) {
                    store.setIndustryCategoryGroup(cfg.getGroupName());
                }
            }
        }
        if (cmd.getCategoryName() != null) {
            store.setIndustryCategoryName(cmd.getCategoryName());
        }
        if (cmd.getCategoryGroup() != null) {
            store.setIndustryCategoryGroup(cmd.getCategoryGroup());
        }

        store = storeRepository.save(store);
        return ApiResponse.success("门店行业细分分类配置已更新", store);
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SwitchIndustryCommand {
        private IndustryType industry;
        private String feeName;
        private BigDecimal feeAmount;
        private Boolean feeEnabled;
    }

    @EqualsAndHashCode(callSuper = true)
    public static class SwitchIndustryReq extends SwitchIndustryCommand {}

    @Operation(summary = "一键切换门店行业模态 (餐饮 / 美业 / 汽修 / 零售)")
    @PostMapping("/switch")
    public ApiResponse<Store> switchIndustry(@RequestBody SwitchIndustryCommand req) {
        Store store = resolveCurrentStore();

        store.setIndustry(req.getIndustry());
        if (req.getFeeName() != null) {
            store.setFeeName(req.getFeeName());
        } else {
            store.setFeeName(req.getIndustry().getDefaultFeeName());
        }
        if (req.getFeeAmount() != null) {
            store.setDefaultFeeAmount(req.getFeeAmount());
        }
        if (req.getFeeEnabled() != null) {
            store.setFeeEnabled(req.getFeeEnabled());
        }

        store = storeRepository.save(store);
        return ApiResponse.success("行业模态切换成功", store);
    }
}
