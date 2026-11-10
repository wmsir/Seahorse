package com.seahorse.store.common;

import lombok.Getter;

/**
 * 统一业务异常定义
 * 符合阿里巴巴 Java 开发手册：显式声明 serialVersionUID，提供完整异常链构造函数
 */
@Getter
public class ServiceException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    private final Integer code;

    public ServiceException(String message) {
        super(message);
        this.code = 500;
    }

    public ServiceException(Integer code, String message) {
        super(message);
        this.code = code;
    }

    public ServiceException(String message, Throwable cause) {
        super(message, cause);
        this.code = 500;
    }

    public ServiceException(Integer code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
    }
}
