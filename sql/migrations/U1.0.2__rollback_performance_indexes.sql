-- =============================================================================
-- Migration Undo: U1.0.2__rollback_performance_indexes.sql
-- Description: 回滚 V1.0.2 为海马智慧门店增补的性能优化二级索引
-- Backward-compatible: YES
-- Target Migration: V1.0.2__add_performance_indexes.sql
-- Author: FWPT Database Architecture Team
-- Created: 2026-11-11
-- =============================================================================

USE `seahorse_store`;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_security_log' AND index_name = 'idx_seclog_store_created');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_security_log` DROP INDEX `idx_seclog_store_created`', 'SELECT "Skip drop idx_seclog_store_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_leave_application' AND index_name = 'idx_leave_tenant_status');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_leave_application` DROP INDEX `idx_leave_tenant_status`', 'SELECT "Skip drop idx_leave_tenant_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_leave_application' AND index_name = 'idx_leave_store_created');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_leave_application` DROP INDEX `idx_leave_store_created`', 'SELECT "Skip drop idx_leave_store_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_appointment' AND index_name = 'idx_apt_tenant_created');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_appointment` DROP INDEX `idx_apt_tenant_created`', 'SELECT "Skip drop idx_apt_tenant_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_appointment' AND index_name = 'idx_apt_store_date_status');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_appointment` DROP INDEX `idx_apt_store_date_status`', 'SELECT "Skip drop idx_apt_store_date_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member_recharge_record' AND index_name = 'idx_rch_tenant_status');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_member_recharge_record` DROP INDEX `idx_rch_tenant_status`', 'SELECT "Skip drop idx_rch_tenant_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member_recharge_record' AND index_name = 'idx_rch_member_created');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_member_recharge_record` DROP INDEX `idx_rch_member_created`', 'SELECT "Skip drop idx_rch_member_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member_recharge_record' AND index_name = 'idx_rch_store_created');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_member_recharge_record` DROP INDEX `idx_rch_store_created`', 'SELECT "Skip drop idx_rch_store_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_commission_record' AND index_name = 'idx_comm_billing_order');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_commission_record` DROP INDEX `idx_comm_billing_order`', 'SELECT "Skip drop idx_comm_billing_order"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_commission_record' AND index_name = 'idx_comm_tenant_store_created');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_commission_record` DROP INDEX `idx_comm_tenant_store_created`', 'SELECT "Skip drop idx_comm_tenant_store_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_product_bom' AND index_name = 'idx_bom_material');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_product_bom` DROP INDEX `idx_bom_material`', 'SELECT "Skip drop idx_bom_material"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_product_category' AND index_name = 'idx_prod_cat_tenant_sort');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_product_category` DROP INDEX `idx_prod_cat_tenant_sort`', 'SELECT "Skip drop idx_prod_cat_tenant_sort"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_product' AND index_name = 'idx_prod_code');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_product` DROP INDEX `idx_prod_code`', 'SELECT "Skip drop idx_prod_code"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_product' AND index_name = 'idx_prod_tenant_store_avail');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_product` DROP INDEX `idx_prod_tenant_store_avail`', 'SELECT "Skip drop idx_prod_tenant_store_avail"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_time_card_bucket' AND index_name = 'idx_timecard_tenant_status');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_time_card_bucket` DROP INDEX `idx_timecard_tenant_status`', 'SELECT "Skip drop idx_timecard_tenant_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_dual_balance_account' AND index_name = 'idx_dual_bal_tenant');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_dual_balance_account` DROP INDEX `idx_dual_bal_tenant`', 'SELECT "Skip drop idx_dual_bal_tenant"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND index_name = 'idx_member_tenant_name');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_member` DROP INDEX `idx_member_tenant_name`', 'SELECT "Skip drop idx_member_tenant_name"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND index_name = 'idx_member_tenant_status_created');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_member` DROP INDEX `idx_member_tenant_status_created`', 'SELECT "Skip drop idx_member_tenant_status_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_payment_record' AND index_name = 'idx_pay_time');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_payment_record` DROP INDEX `idx_pay_time`', 'SELECT "Skip drop idx_pay_time"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_payment_record' AND index_name = 'idx_pay_order_status');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_payment_record` DROP INDEX `idx_pay_order_status`', 'SELECT "Skip drop idx_pay_order_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_billing_order' AND index_name = 'idx_bill_member_created');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_billing_order` DROP INDEX `idx_bill_member_created`', 'SELECT "Skip drop idx_bill_member_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_billing_order' AND index_name = 'idx_bill_store_settled');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_billing_order` DROP INDEX `idx_bill_store_settled`', 'SELECT "Skip drop idx_bill_store_settled"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_billing_order' AND index_name = 'idx_bill_tenant_store_status');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_billing_order` DROP INDEX `idx_bill_tenant_store_status`', 'SELECT "Skip drop idx_bill_tenant_store_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_performer_share' AND index_name = 'idx_perf_line_item');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_performer_share` DROP INDEX `idx_perf_line_item`', 'SELECT "Skip drop idx_perf_line_item"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_performer_share' AND index_name = 'idx_perf_session');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_performer_share` DROP INDEX `idx_perf_session`', 'SELECT "Skip drop idx_perf_session"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_session_line_item' AND index_name = 'idx_line_product');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_session_line_item` DROP INDEX `idx_line_product`', 'SELECT "Skip drop idx_line_product"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_session_line_item' AND index_name = 'idx_line_batch');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_session_line_item` DROP INDEX `idx_line_batch`', 'SELECT "Skip drop idx_line_batch"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_session_line_item' AND index_name = 'idx_line_session_status');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_session_line_item` DROP INDEX `idx_line_session_status`', 'SELECT "Skip drop idx_line_session_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_service_session' AND index_name = 'idx_sess_member_created');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_service_session` DROP INDEX `idx_sess_member_created`', 'SELECT "Skip drop idx_sess_member_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_service_session' AND index_name = 'idx_sess_store_created');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_service_session` DROP INDEX `idx_sess_store_created`', 'SELECT "Skip drop idx_sess_store_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_service_session' AND index_name = 'idx_sess_tenant_store_status');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_service_session` DROP INDEX `idx_sess_tenant_store_status`', 'SELECT "Skip drop idx_sess_tenant_store_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_service_space' AND index_name = 'idx_space_current_session');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_service_space` DROP INDEX `idx_space_current_session`', 'SELECT "Skip drop idx_space_current_session"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_service_space' AND index_name = 'idx_space_tenant_store_status');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_service_space` DROP INDEX `idx_space_tenant_store_status`', 'SELECT "Skip drop idx_space_tenant_store_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND index_name = 'idx_emp_tenant_status');
SET @sqlstmt := IF(@idx > 0, 'ALTER TABLE `sh_employee` DROP INDEX `idx_emp_tenant_status`', 'SELECT "Skip drop idx_emp_tenant_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;
