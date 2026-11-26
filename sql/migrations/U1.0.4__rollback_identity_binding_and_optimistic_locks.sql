-- =============================================================================
-- Migration Undo: U1.0.4__rollback_identity_binding_and_optimistic_locks.sql
-- Description: 回滚 V1.0.4 新增乐观锁列并归档 sh_identity_binding 表
-- Target Migration: V1.0.4__harden_identity_binding_and_optimistic_locks.sql
-- Created: 2026-11-26
-- =============================================================================

USE `seahorse_store`;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_billing_order' AND column_name = 'version');
SET @sqlstmt := IF(@col > 0, 'ALTER TABLE `sh_billing_order` DROP COLUMN `version`', 'SELECT "Skip drop sh_billing_order.version"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_time_card_bucket' AND column_name = 'version');
SET @sqlstmt := IF(@col > 0, 'ALTER TABLE `sh_time_card_bucket` DROP COLUMN `version`', 'SELECT "Skip drop sh_time_card_bucket.version"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @t := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_identity_binding');
SET @b := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_identity_binding_rollback_bak');
SET @sqlstmt := IF(@t > 0 AND @b > 0, 'DROP TABLE `sh_identity_binding_rollback_bak`', 'SELECT "No stale sh_identity_binding_rollback_bak"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @sqlstmt := IF(@t > 0, 'RENAME TABLE `sh_identity_binding` TO `sh_identity_binding_rollback_bak`', 'SELECT "Skip sh_identity_binding"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;
