package com.seahorse.store.interfaces.web;

import com.seahorse.store.common.ApiResponse;
import com.seahorse.store.common.ServiceException;
import com.seahorse.store.context.TenantContext;
import com.seahorse.store.domain.member.model.MemberCardTemplate;
import com.seahorse.store.infrastructure.repository.MemberCardTemplateRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * 会员卡项配置管理控制器
 * 支持次卡、储值卡、时长卡、独立储值卡、盲盒卡、权益卡管理
 */
@Tag(name = "11. 会员卡设置", description = "会员卡模板项管理：次卡、储值卡、时长卡、独立储值卡、盲盒卡、权益卡")
@RestController
@RequestMapping("/api/card-template")
@RequiredArgsConstructor
public class CardTemplateController {

    private final MemberCardTemplateRepository cardTemplateRepository;

    @Operation(summary = "查询会员卡项列表 (支持按类型筛选)")
    @GetMapping("/list")
    public ApiResponse<List<MemberCardTemplate>> getList(@RequestParam(required = false) String cardType) {
        String tenantId = TenantContext.getTenantId();
        List<MemberCardTemplate> list;
        if (cardType == null || cardType.trim().isEmpty() || "ALL".equalsIgnoreCase(cardType)) {
            list = cardTemplateRepository.findByTenantIdAndStatusOrderBySortOrderAsc(tenantId, "ACTIVE");
        } else {
            list = cardTemplateRepository.findByTenantIdAndCardTypeAndStatusOrderBySortOrderAsc(tenantId, cardType, "ACTIVE");
        }
        return ApiResponse.success(list);
    }

    @Operation(summary = "获取会员卡项详情")
    @GetMapping("/{id}")
    public ApiResponse<MemberCardTemplate> getDetail(@PathVariable Long id) {
        MemberCardTemplate template = cardTemplateRepository.findById(id)
                .orElseThrow(() -> new ServiceException("未找到该卡项配置"));
        TenantContext.assertTenantAccess(template.getTenantId());
        return ApiResponse.success(template);
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SaveCardTemplateCommand {
        private Long id;
        private String cardType;
        private String cardTypeName;
        private String cardName;
        private BigDecimal price;
        private BigDecimal originalPrice;
        private String contentDescription;
        private BigDecimal principalAmount;
        private BigDecimal giftAmount;
        private BigDecimal discountRate;
        private Integer totalTimes;
        private Integer validityDays;
        private Long serviceSkuId;
        private String serviceSkuName;
        private Integer sortOrder;
        private String notes;
    }

    @Operation(summary = "新增或编辑会员卡项")
    @PostMapping("/save")
    public ApiResponse<MemberCardTemplate> saveCard(@RequestBody SaveCardTemplateCommand cmd) {
        String tenantId = TenantContext.getTenantId();
        String storeId = TenantContext.getStoreId();

        if (cmd.getCardName() == null || cmd.getCardName().trim().isEmpty()) {
            throw new ServiceException("卡项名称不能为空");
        }
        if (cmd.getPrice() == null) {
            throw new ServiceException("卡项价格不能为空");
        }

        MemberCardTemplate entity;
        if (cmd.getId() != null) {
            entity = cardTemplateRepository.findById(cmd.getId())
                    .orElseThrow(() -> new ServiceException("未找到待更新的卡项"));
            TenantContext.assertTenantAccess(entity.getTenantId());
        } else {
            entity = new MemberCardTemplate();
            entity.setTenantId(tenantId);
            entity.setStoreId(storeId);
            entity.setStatus("ACTIVE");
        }

        entity.setCardType(cmd.getCardType() != null ? cmd.getCardType() : "STORED_VALUE");
        entity.setCardTypeName(cmd.getCardTypeName() != null ? cmd.getCardTypeName() : "储值卡");
        entity.setCardName(cmd.getCardName());
        entity.setPrice(cmd.getPrice());
        entity.setOriginalPrice(cmd.getOriginalPrice());
        entity.setContentDescription(cmd.getContentDescription());
        entity.setPrincipalAmount(cmd.getPrincipalAmount());
        entity.setGiftAmount(cmd.getGiftAmount());
        entity.setDiscountRate(cmd.getDiscountRate());
        entity.setTotalTimes(cmd.getTotalTimes());
        entity.setValidityDays(cmd.getValidityDays() != null ? cmd.getValidityDays() : 0);
        entity.setServiceSkuId(cmd.getServiceSkuId());
        entity.setServiceSkuName(cmd.getServiceSkuName());
        entity.setSortOrder(cmd.getSortOrder() != null ? cmd.getSortOrder() : 100);
        entity.setNotes(cmd.getNotes());

        entity = cardTemplateRepository.save(entity);
        return ApiResponse.success("会员卡项保存成功", entity);
    }

    @Operation(summary = "删除会员卡项")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> deleteCard(@PathVariable Long id) {
        MemberCardTemplate template = cardTemplateRepository.findById(id)
                .orElseThrow(() -> new ServiceException("未找到该卡项"));
        TenantContext.assertTenantAccess(template.getTenantId());
        template.setStatus("INACTIVE");
        cardTemplateRepository.save(template);
        return ApiResponse.success("卡项已成功删除", null);
    }
}
