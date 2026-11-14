-- =============================================================================
-- Migration: V1.0.1__add_audit_and_member_indexes.sql
-- Description: 新增安全审计策略与登录操作日志表 (sh_audit_policy / sh_security_log) 及员工手机号复合索引 (Expand 阶段)
-- Backward-compatible: YES (无破坏性变更，老版本应用读写无影响)
-- Rollback script: U1.0.1__rollback_audit_and_member_indexes.sql
-- Author: FWPT Database Architecture Team
-- Created: 2026-11-03
-- =============================================================================

USE `seahorse_store`;

-- 1. 新增安全审计策略配置表 (sh_audit_policy，与 AuditPolicy 实体对齐)
CREATE TABLE IF NOT EXISTS `sh_audit_policy` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `enabled` tinyint(1) NOT NULL DEFAULT '1',
  `mode` varchar(32) DEFAULT 'ALL',
  `excluded_tenant_ids` text,
  `excluded_store_ids` text,
  `included_tenant_ids` text,
  `included_store_ids` text,
  `record_logins` tinyint(1) DEFAULT '1',
  `record_operations` tinyint(1) DEFAULT '1',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='安全审计策略配置表';

-- 2. 新增系统安全与登录审计日志表 (sh_security_log，与 SecurityLog 实体对齐)
CREATE TABLE IF NOT EXISTS `sh_security_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `tenant_name` varchar(128) DEFAULT NULL,
  `store_id` varchar(64) DEFAULT NULL,
  `store_name` varchar(128) DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `username` varchar(64) NOT NULL,
  `real_name` varchar(64) DEFAULT NULL,
  `action` varchar(128) NOT NULL,
  `action_type` varchar(32) NOT NULL,
  `ip` varchar(64) DEFAULT NULL,
  `device` varchar(255) DEFAULT NULL,
  `status` varchar(32) NOT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_seclog_tenant_time` (`tenant_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统安全与登录审计日志表';

-- 3. 为 sh_employee 表增补租户+手机号复合索引 (采用 MySQL 8.0 在线无锁算法)
SET @exist := (
  SELECT COUNT(*) FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'sh_employee'
    AND index_name = 'idx_emp_tenant_phone'
);

SET @sqlstmt := IF(
  @exist = 0,
  'ALTER TABLE `sh_employee` ADD INDEX `idx_emp_tenant_phone` (`tenant_id`, `phone`) ALGORITHM=INPLACE, LOCK=NONE',
  'SELECT "Index idx_emp_tenant_phone already exists, skipping."'
);

PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
