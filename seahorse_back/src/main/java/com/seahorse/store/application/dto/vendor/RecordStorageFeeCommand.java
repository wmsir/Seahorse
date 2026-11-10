package com.seahorse.store.application.dto.vendor;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * 录入/缴纳云存储服务费命令对象
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecordStorageFeeCommand {
    private String tenantId;
    private Integer storageGb; // 扩充/购买的云存储容量(GB)
    private BigDecimal amount; // 存储服务费金额
    private Integer durationMonths; // 覆盖有效月数 (如 12 个月)
    private String paymentMethod; // WECHAT, ALIPAY, BANK_TRANSFER
    private String notes; // 备注说明 (如“美业高清客照扩容包”)
}
