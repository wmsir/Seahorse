-- =============================================================================
-- Migration Undo: U1.0.1__rollback_audit_and_member_indexes.sql
-- Description: 回滚 V1.0.1 所引入的审计表与会员复合索引
-- Backward-compatible: YES
-- Target Migration: V1.0.1__add_audit_and_member_indexes.sql
-- Author: FWPT Database Architecture Team
-- Created: 2026-11-03
-- =============================================================================

USE `seahorse_store`;

-- 1. 回滚会员索引
SET @exist := (
  SELECT COUNT(*) FROM information_schema.statistics 
  WHERE table_schema = DATABASE() 
    AND table_name = 'sh_member' 
    AND index_name = 'idx_member_tenant_phone'
);

SET @sqlstmt := IF(
  @exist > 0,
  'ALTER TABLE `sh_member` DROP INDEX `idx_member_tenant_phone`',
  'SELECT "Index idx_member_tenant_phone does not exist, skipping drop."'
);

PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 回滚审计表 (生产回滚先重命名归档，避免直接硬删除丢失数据)
DROP TABLE IF EXISTS `sh_operation_audit_log_rollback_bak`;

SET @table_exist := (
  SELECT COUNT(*) FROM information_schema.tables 
  WHERE table_schema = DATABASE() 
    AND table_name = 'sh_operation_audit_log'
);

SET @sqlstmt_tbl := IF(
  @table_exist > 0,
  'RENAME TABLE `sh_operation_audit_log` TO `sh_operation_audit_log_rollback_bak`',
  'SELECT "Table sh_operation_audit_log does not exist, skipping rename."'
);

PREPARE stmt_tbl FROM @sqlstmt_tbl;
EXECUTE stmt_tbl;
DEALLOCATE PREPARE stmt_tbl;
