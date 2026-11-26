-- =============================================================================
-- Migration: V1.0.4__harden_identity_binding_and_optimistic_locks.sql
-- Description: 补齐 sh_identity_binding 映射表及 sh_time_card_bucket / sh_billing_order 乐观锁 version 列
-- Backward-compatible: YES (全部幂等检查)
-- Rollback script: U1.0.4__rollback_identity_binding_and_optimistic_locks.sql
-- Created: 2026-11-26
-- =============================================================================

USE `seahorse_store`;

-- 1. 统一认证中心 (OneID 2.0) 与海马员工显式身份绑定表
CREATE TABLE IF NOT EXISTS `sh_identity_binding` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `oneid_sub` varchar(64) NOT NULL COMMENT 'OneID 统一用户唯一标识 sub',
  `tenant_id` varchar(64) NOT NULL COMMENT '所属商户租户ID',
  `store_id` varchar(64) DEFAULT NULL COMMENT '所属门店ID',
  `employee_id` bigint NOT NULL COMMENT '关联海马员工主键ID',
  `role_code` varchar(32) NOT NULL COMMENT '显式授权角色编码',
  `match_source` varchar(32) NOT NULL DEFAULT 'PHONE_AUTO_LINK' COMMENT '映射来源',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sh_bind_emp` (`employee_id`),
  KEY `idx_sh_bind_sub` (`oneid_sub`),
  KEY `idx_sh_bind_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='OneID统一身份与门店员工映射表';

-- 2. 次卡桶乐观锁版本号 (防止高并发核销超扣)
SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_time_card_bucket' AND column_name = 'version');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_time_card_bucket` ADD COLUMN `version` bigint NOT NULL DEFAULT ''0'' COMMENT ''JPA乐观锁版本号''', 'SELECT "Skip sh_time_card_bucket.version"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. 结算账单乐观锁版本号 (防止并发重复结账)
SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_billing_order' AND column_name = 'version');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_billing_order` ADD COLUMN `version` bigint NOT NULL DEFAULT ''0'' COMMENT ''JPA乐观锁版本号''', 'SELECT "Skip sh_billing_order.version"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;
