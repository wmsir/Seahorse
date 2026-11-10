package com.seahorse.store.application.dto.session;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 空间开单履约命令对象
 * 符合阿里巴巴与DDD规范：Command命名
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OpenSessionCommand {
    private Long spaceId;
    private Long memberId;
    private String customerName;
    private String customerPhone;
    private Integer guestCount;
    private String notes;
}
