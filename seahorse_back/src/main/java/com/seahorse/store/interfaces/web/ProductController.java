package com.seahorse.store.interfaces.web;

import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.product.enums.ProductType;
import com.seahorse.store.domain.product.model.Product;
import com.seahorse.store.domain.product.model.ProductBom;
import com.seahorse.store.domain.product.model.ProductCategory;
import com.seahorse.store.infrastructure.repository.ProductBomRepository;
import com.seahorse.store.infrastructure.repository.ProductCategoryRepository;
import com.seahorse.store.infrastructure.repository.ProductRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Tag(name = "05. 商品服务与BOM原料配方", description = "实物商品、计量服务项目、原料耗材及服务联动消耗配方管理")
@RestController
@RequestMapping("/api/product")
@RequiredArgsConstructor
public class ProductController {

    private final ProductRepository productRepository;
    private final ProductCategoryRepository categoryRepository;
    private final ProductBomRepository bomRepository;
    private final com.seahorse.store.infrastructure.repository.StoreRepository storeRepository;

    @Operation(summary = "获取当前门店可用商品/服务列表")
    @GetMapping("/list")
    public ApiResponse<List<Product>> getProducts(
            @RequestParam(value = "type", required = false) ProductType type,
            @RequestParam(value = "storeId", required = false) String storeIdParam) {
        String storeId = (storeIdParam != null && !storeIdParam.trim().isEmpty()) ? storeIdParam.trim() : TenantContext.getStoreId();
        String tenantId = TenantContext.getTenantId();
        if (storeId != null && !storeId.trim().isEmpty()) {
            java.util.Optional<com.seahorse.store.domain.iam.model.Store> sOpt = storeRepository.findByStoreId(storeId);
            if (sOpt.isPresent() && sOpt.get().getTenantId() != null) {
                tenantId = sOpt.get().getTenantId();
            }
        }
        if (storeId == null || storeId.trim().isEmpty()) {
            return ApiResponse.success(productRepository.findByTenantId(tenantId));
        }
        if (type != null) {
            return ApiResponse.success(productRepository.findByStoreIdAndProductType(storeId, type));
        }
        return ApiResponse.success(productRepository.findByStoreIdAndAvailableTrue(storeId));
    }

    @Operation(summary = "获取分类列表（可按行业与门店过滤）")
    @GetMapping("/categories")
    public ApiResponse<List<ProductCategory>> getCategories(
            @RequestParam(value = "industry", required = false) String industry,
            @RequestParam(value = "storeId", required = false) String storeId,
            @RequestParam(value = "tenantId", required = false) String specifiedTenantId) {
        String tenantId = (specifiedTenantId != null && !specifiedTenantId.trim().isEmpty()) ? specifiedTenantId.trim() : TenantContext.getTenantId();
        String effStoreId = (storeId != null && !storeId.trim().isEmpty()) ? storeId.trim() : TenantContext.getStoreId();

        if (effStoreId != null && !effStoreId.isEmpty()) {
            java.util.Optional<com.seahorse.store.domain.iam.model.Store> sOpt = storeRepository.findByStoreId(effStoreId);
            if (sOpt.isPresent()) {
                com.seahorse.store.domain.iam.model.Store s = sOpt.get();
                if (s.getTenantId() != null && !s.getTenantId().trim().isEmpty()) {
                    tenantId = s.getTenantId();
                }
                if ((industry == null || industry.trim().isEmpty()) && s.getIndustry() != null) {
                    industry = s.getIndustry().name();
                }
            }
        }
        if (tenantId == null || tenantId.trim().isEmpty()) {
            tenantId = "T001";
        }

        List<ProductCategory> list;
        if (industry != null && !industry.trim().isEmpty()) {
            // 优先查该行业下的分类
            list = categoryRepository.findByTenantIdAndIndustry(tenantId, industry.toUpperCase());
            if (list.isEmpty()) {
                // 兜底：返回 tenantId 下全部可用分类（不管行业）
                list = categoryRepository.findByTenantId(tenantId);
            }
        } else {
            // 未传 industry，返回全部
            list = categoryRepository.findByTenantId(tenantId);
        }

        if (list == null) {
            list = new ArrayList<>();
        }

        return ApiResponse.success(list);
    }

    @Operation(summary = "创建或修改分类 (店长/租户老板权限)")
    @PostMapping("/category/save")
    public ApiResponse<ProductCategory> saveCategory(@RequestBody ProductCategory category) {
        if (category.getTenantId() == null || category.getTenantId().trim().isEmpty()) {
            String tid = TenantContext.getTenantId();
            category.setTenantId(tid != null && !tid.trim().isEmpty() ? tid : "T001");
        }
        if (category.getName() == null || category.getName().trim().isEmpty()) {
            throw new ServiceException("分类名称不能为空");
        }
        if (category.getAvailable() == null) {
            category.setAvailable(true);
        }
        if (category.getSortOrder() == null) {
            category.setSortOrder(0);
        }
        ProductCategory saved = categoryRepository.save(category);
        return ApiResponse.success("分类保存成功", saved);
    }

    @Operation(summary = "删除分类")
    @DeleteMapping("/category/{id}")
    public ApiResponse<Void> deleteCategory(@PathVariable("id") Long id) {
        categoryRepository.deleteById(id);
        return ApiResponse.success("分类已成功删除", null);
    }

    @Operation(summary = "创建或保存商品/服务")
    @PostMapping("/save")
    public ApiResponse<Product> saveProduct(@RequestBody Product product) {
        if (product.getTenantId() == null || product.getTenantId().trim().isEmpty()) {
            String tid = TenantContext.getTenantId();
            product.setTenantId(tid != null && !tid.trim().isEmpty() ? tid : "T001");
        }
        if (product.getStoreId() == null || product.getStoreId().trim().isEmpty()) {
            String sid = TenantContext.getStoreId();
            product.setStoreId(sid != null && !sid.trim().isEmpty() ? sid : "S001");
        }
        if (product.getProductCode() == null || product.getProductCode().trim().isEmpty()) {
            product.setProductCode("PRD" + System.currentTimeMillis());
        }
        if (product.getName() == null || product.getName().trim().isEmpty()) {
            product.setName("未命名商品");
        }
        if (product.getProductType() == null) {
            product.setProductType(ProductType.PHYSICAL);
        }
        if (product.getAvailable() == null) {
            product.setAvailable(true);
        }
        if (product.getPrice() == null) {
            product.setPrice(java.math.BigDecimal.ZERO);
        }
        return ApiResponse.success(productRepository.save(product));
    }

    @Operation(summary = "配置服务的 BOM 耗材消耗配方 (如美发烫发配药水，汽修保养配机油)")
    @PostMapping("/bom/save")
    public ApiResponse<ProductBom> saveBom(@RequestBody ProductBom bom) {
        return ApiResponse.success(bomRepository.save(bom));
    }

    @Operation(summary = "获取指定服务项关联的 BOM 原料配方")
    @GetMapping("/{serviceId}/boms")
    public ApiResponse<List<ProductBom>> getServiceBoms(@PathVariable("serviceId") Long serviceId) {
        return ApiResponse.success(bomRepository.findByServiceProductId(serviceId));
    }

    @Operation(summary = "删除商品或服务项目")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteProduct(@PathVariable("id") Long id) {
        productRepository.deleteById(id);
        return ApiResponse.success("商品已成功删除", null);
    }
}
