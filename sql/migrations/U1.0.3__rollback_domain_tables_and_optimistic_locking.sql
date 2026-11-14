-- =============================================================================
-- Migration Undo: U1.0.3__rollback_domain_tables_and_optimistic_locking.sql
-- Description: 回滚 V1.0.3 所引入的乐观锁版本列、租户级会员编号唯一索引与扩展业务表
-- Backward-compatible: YES
-- Target Migration: V1.0.3__sync_domain_tables_and_optimistic_locking.sql
-- Author: FWPT Database Architecture Team
-- Created: 2026-11-14
-- =============================================================================

USE `seahorse_store`;

-- 1. 回滚乐观锁与订阅套餐新增列
SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_subscription_plan_config' AND column_name = 'staff_limit');
SET @sqlstmt := IF(@col > 0, 'ALTER TABLE `sh_subscription_plan_config` DROP COLUMN `staff_limit`', 'SELECT "Skip drop sh_subscription_plan_config.staff_limit"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_tenant_subscription' AND column_name = 'staff_limit');
SET @sqlstmt := IF(@col > 0, 'ALTER TABLE `sh_tenant_subscription` DROP COLUMN `staff_limit`', 'SELECT "Skip drop sh_tenant_subscription.staff_limit"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_product' AND column_name = 'version');
SET @sqlstmt := IF(@col > 0, 'ALTER TABLE `sh_product` DROP COLUMN `version`', 'SELECT "Skip drop sh_product.version"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_dual_balance_account' AND column_name = 'version');
SET @sqlstmt := IF(@col > 0, 'ALTER TABLE `sh_dual_balance_account` DROP COLUMN `version`', 'SELECT "Skip drop sh_dual_balance_account.version"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_dual_balance_account' AND column_name = 'deduct_mode');
SET @sqlstmt := IF(@col > 0, 'ALTER TABLE `sh_dual_balance_account` DROP COLUMN `deduct_mode`', 'SELECT "Skip drop sh_dual_balance_account.deduct_mode"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2. 回滚 sh_member 会员编号复合唯一索引
SET @idx_old := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND index_name = 'uk_member_no');
SET @sqlstmt := IF(@idx_old = 0, 'ALTER TABLE `sh_member` ADD UNIQUE INDEX `uk_member_no` (`member_no`)', 'SELECT "Skip restore uk_member_no"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_new := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND index_name = 'uk_tenant_member_no');
SET @sqlstmt := IF(@idx_new > 0, 'ALTER TABLE `sh_member` DROP INDEX `uk_tenant_member_no`', 'SELECT "Skip drop uk_tenant_member_no"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. 归档 V1.0.3 新增持久化表 (重命名为 *_rollback_bak 防止生产误丢数据)
SET @t := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_job_application');
SET @b := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_job_application_rollback_bak');
SET @sqlstmt := IF(@t > 0 AND @b > 0, 'DROP TABLE `sh_job_application_rollback_bak`', 'SELECT "No stale sh_job_application_rollback_bak"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sqlstmt := IF(@t > 0, 'RENAME TABLE `sh_job_application` TO `sh_job_application_rollback_bak`', 'SELECT "Skip sh_job_application"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @t := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_attendance_record');
SET @b := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_attendance_record_rollback_bak');
SET @sqlstmt := IF(@t > 0 AND @b > 0, 'DROP TABLE `sh_attendance_record_rollback_bak`', 'SELECT "No stale sh_attendance_record_rollback_bak"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sqlstmt := IF(@t > 0, 'RENAME TABLE `sh_attendance_record` TO `sh_attendance_record_rollback_bak`', 'SELECT "Skip sh_attendance_record"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;
