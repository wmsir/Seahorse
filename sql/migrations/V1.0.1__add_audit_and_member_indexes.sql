-- =============================================================================
-- Migration: V1.0.1__add_audit_and_member_indexes.sql
-- Description: 新增操作审计日志表与会员快速检索索引 (Expand 阶段)
-- Backward-compatible: YES (无破坏性变更，老版本应用读写无影响)
-- Rollback script: U1.0.1__rollback_audit_and_member_indexes.sql
-- Author: FWPT Database Architecture Team
-- Created: 2026-11-03
-- =============================================================================

USE `seahorse_store`;

-- 1. 新增操作审计日志表 (sh_operation_audit_log)
CREATE TABLE IF NOT EXISTS `sh_operation_audit_log` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `tenant_id` VARCHAR(64) NOT NULL COMMENT '租户全局ID',
  `store_id` VARCHAR(64) DEFAULT NULL COMMENT '门店ID',
  `operator_id` VARCHAR(64) NOT NULL COMMENT '操作人ID/账号',
  `operator_name` VARCHAR(128) DEFAULT NULL COMMENT '操作人名称',
  `action_module` VARCHAR(64) NOT NULL COMMENT '业务模块(MEMBER, ORDER, RECHARGE, SETTING)',
  `action_type` VARCHAR(64) NOT NULL COMMENT '操作类型(CREATE, UPDATE, REFUND, EXPORT)',
  `target_id` VARCHAR(64) DEFAULT NULL COMMENT '目标实体ID',
  `ip_address` VARCHAR(45) DEFAULT NULL COMMENT '操作来源IP',
  `user_agent` VARCHAR(255) DEFAULT NULL COMMENT '客户端UA',
  `details_json` JSON DEFAULT NULL COMMENT '变更明细快照(JSON格式)',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_audit_tenant_time` (`tenant_id`, `created_at`),
  KEY `idx_audit_operator` (`operator_id`),
  KEY `idx_audit_module_type` (`action_module`, `action_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统全局操作安全审计日志表';

-- 2. 为 sh_member 表增补租户+手机号复合索引 (采用 MySQL 8.0 在线无锁算法)
-- 注意：已存在索引则略过，避免重复定义
SET @exist := (
  SELECT COUNT(*) FROM information_schema.statistics 
  WHERE table_schema = DATABASE() 
    AND table_name = 'sh_member' 
    AND index_name = 'idx_member_tenant_phone'
);

SET @sqlstmt := IF(
  @exist = 0,
  'ALTER TABLE `sh_member` ADD INDEX `idx_member_tenant_phone` (`tenant_id`, `phone`) ALGORITHM=INPLACE, LOCK=NONE',
  'SELECT "Index idx_member_tenant_phone already exists, skipping."'
);

PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
