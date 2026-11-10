package com.seahorse.store.application.dto.vendor;

import com.seahorse.store.domain.iam.enums.IndustryType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 商家开设新门店命令对象
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateStoreCommand {
    private String storeId;
    private String storeName;
    private IndustryType industry; // BEAUTY, RESTAURANT, AUTO, RETAIL
    private Integer industryCategoryId;
    private String industryCategoryName;
    private String industryCategoryGroup;
    private String address;
    private String phone;
    private String businessHours;
    private String status; // ACTIVE, PAUSED
    private String feeName;
    private BigDecimal defaultFeeAmount;
    private Boolean feeEnabled;
}
