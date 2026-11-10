package com.seahorse.store.interfaces.web.vo;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

/**
 * 权限定义项元数据 VO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PermissionItemVO implements Serializable {
    private static final long serialVersionUID = 1L;

    private String code;
    private String name;
    private String module;
    private String description;
}
