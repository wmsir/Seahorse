package com.seahorse.store.application.dto.session;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * 履约会话点单/加单命令对象
 * 符合阿里巴巴与DDD规范：Command命名
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppendItemsCommand {
    private Long sessionId;
    private List<AppendItemParam> items;
    private String operatorType; // CUSTOMER, WAITER
    private Long operatorId;
    private String operatorName;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AppendItemParam {
        private Long productId;
        private Integer quantity;
        private String modifiers; // 做法、忌口、规格
        private List<PerformerShareParam> performers; // 提成人员
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PerformerShareParam {
        private Long employeeId;
        private String employeeName;
        private BigDecimal shareRatio; // 0.70 代表 70%
    }
}
