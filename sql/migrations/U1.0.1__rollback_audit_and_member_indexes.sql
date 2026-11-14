-- =============================================================================
-- Migration Undo: U1.0.1__rollback_audit_and_member_indexes.sql
-- Description: 回滚 V1.0.1 所引入的安全审计表 (sh_security_log / sh_audit_policy) 与员工复合索引
-- Backward-compatible: YES
-- Target Migration: V1.0.1__add_audit_and_member_indexes.sql
-- Author: FWPT Database Architecture Team
-- Created: 2026-11-03
-- =============================================================================

USE `seahorse_store`;

-- 1. 回滚员工租户+手机号索引
SET @exist := (
  SELECT COUNT(*) FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'sh_employee'
    AND index_name = 'idx_emp_tenant_phone'
);

SET @sqlstmt := IF(
  @exist > 0,
  'ALTER TABLE `sh_employee` DROP INDEX `idx_emp_tenant_phone`',
  'SELECT "Index idx_emp_tenant_phone does not exist, skipping drop."'
);

PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 回滚 sh_security_log 表 (先归档为 *_rollback_bak，避免硬删丢数据)
SET @seclog_exist := (
  SELECT COUNT(*) FROM information_schema.tables
  WHERE table_schema = DATABASE() AND table_name = 'sh_security_log'
);
SET @seclog_bak_exist := (
  SELECT COUNT(*) FROM information_schema.tables
  WHERE table_schema = DATABASE() AND table_name = 'sh_security_log_rollback_bak'
);
SET @sqlstmt_drop_seclog_bak := IF(
  @seclog_exist > 0 AND @seclog_bak_exist > 0,
  'DROP TABLE `sh_security_log_rollback_bak`',
  'SELECT "No stale sh_security_log_rollback_bak to replace."'
);
PREPARE stmt_drop_seclog_bak FROM @sqlstmt_drop_seclog_bak;
EXECUTE stmt_drop_seclog_bak;
DEALLOCATE PREPARE stmt_drop_seclog_bak;

SET @sqlstmt_seclog := IF(
  @seclog_exist > 0,
  'RENAME TABLE `sh_security_log` TO `sh_security_log_rollback_bak`',
  'SELECT "Table sh_security_log does not exist, skipping rename."'
);
PREPARE stmt_seclog FROM @sqlstmt_seclog;
EXECUTE stmt_seclog;
DEALLOCATE PREPARE stmt_seclog;

-- 3. 回滚 sh_audit_policy 表
SET @policy_exist := (
  SELECT COUNT(*) FROM information_schema.tables
  WHERE table_schema = DATABASE() AND table_name = 'sh_audit_policy'
);
SET @policy_bak_exist := (
  SELECT COUNT(*) FROM information_schema.tables
  WHERE table_schema = DATABASE() AND table_name = 'sh_audit_policy_rollback_bak'
);
SET @sqlstmt_drop_policy_bak := IF(
  @policy_exist > 0 AND @policy_bak_exist > 0,
  'DROP TABLE `sh_audit_policy_rollback_bak`',
  'SELECT "No stale sh_audit_policy_rollback_bak to replace."'
);
PREPARE stmt_drop_policy_bak FROM @sqlstmt_drop_policy_bak;
EXECUTE stmt_drop_policy_bak;
DEALLOCATE PREPARE stmt_drop_policy_bak;

SET @sqlstmt_policy := IF(
  @policy_exist > 0,
  'RENAME TABLE `sh_audit_policy` TO `sh_audit_policy_rollback_bak`',
  'SELECT "Table sh_audit_policy does not exist, skipping rename."'
);
PREPARE stmt_policy FROM @sqlstmt_policy;
EXECUTE stmt_policy;
DEALLOCATE PREPARE stmt_policy;
