-- =============================================================================
-- Migration: V1.0.2__add_performance_indexes.sql
-- Description: 为海马智慧门店核心履约、账单、会员资产与审计表增补高频复合索引 (Expand 阶段)
-- Backward-compatible: YES (采用 MySQL 8.0 INPLACE 无锁在线建索引，完全向后兼容)
-- Rollback script: U1.0.2__rollback_performance_indexes.sql
-- Author: FWPT Database Architecture Team
-- Created: 2026-11-11
-- =============================================================================

USE `seahorse_store`;

-- 1. sh_employee 二级索引
SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_employee');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND index_name = 'idx_emp_tenant_status');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_employee` ADD INDEX `idx_emp_tenant_status` (`tenant_id`, `status`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_emp_tenant_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2. sh_service_space 二级索引
SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_service_space');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_service_space' AND index_name = 'idx_space_tenant_store_status');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_service_space` ADD INDEX `idx_space_tenant_store_status` (`tenant_id`, `store_id`, `status`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_space_tenant_store_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_service_space' AND index_name = 'idx_space_current_session');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_service_space` ADD INDEX `idx_space_current_session` (`current_session_id`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_space_current_session"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. sh_service_session 二级索引
SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_service_session');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_service_session' AND index_name = 'idx_sess_tenant_store_status');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_service_session` ADD INDEX `idx_sess_tenant_store_status` (`tenant_id`, `store_id`, `status`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_sess_tenant_store_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_service_session' AND index_name = 'idx_sess_store_created');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_service_session` ADD INDEX `idx_sess_store_created` (`store_id`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_sess_store_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_service_session' AND index_name = 'idx_sess_member_created');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_service_session` ADD INDEX `idx_sess_member_created` (`member_id`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_sess_member_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4. sh_session_line_item & sh_performer_share 二级索引
SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_session_line_item');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_session_line_item' AND index_name = 'idx_line_session_status');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_session_line_item` ADD INDEX `idx_line_session_status` (`session_id`, `status`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_line_session_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_session_line_item' AND index_name = 'idx_line_batch');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_session_line_item` ADD INDEX `idx_line_batch` (`batch_id`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_line_batch"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_session_line_item' AND index_name = 'idx_line_product');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_session_line_item` ADD INDEX `idx_line_product` (`product_id`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_line_product"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_performer_share');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_performer_share' AND index_name = 'idx_perf_session');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_performer_share` ADD INDEX `idx_perf_session` (`session_id`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_perf_session"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_performer_share' AND index_name = 'idx_perf_line_item');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_performer_share` ADD INDEX `idx_perf_line_item` (`line_item_id`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_perf_line_item"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 5. sh_billing_order, sh_payment_record 二级索引
SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_billing_order');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_billing_order' AND index_name = 'idx_bill_tenant_store_status');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_billing_order` ADD INDEX `idx_bill_tenant_store_status` (`tenant_id`, `store_id`, `status`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_bill_tenant_store_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_billing_order' AND index_name = 'idx_bill_store_settled');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_billing_order` ADD INDEX `idx_bill_store_settled` (`store_id`, `settled_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_bill_store_settled"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_billing_order' AND index_name = 'idx_bill_member_created');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_billing_order` ADD INDEX `idx_bill_member_created` (`member_id`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_bill_member_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_payment_record');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_payment_record' AND index_name = 'idx_pay_order_status');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_payment_record` ADD INDEX `idx_pay_order_status` (`billing_order_id`, `status`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_pay_order_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_payment_record' AND index_name = 'idx_pay_time');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_payment_record` ADD INDEX `idx_pay_time` (`pay_time`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_pay_time"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 6. sh_member, sh_dual_balance_account, sh_time_card_bucket 二级索引
SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_member');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND index_name = 'idx_member_tenant_status_created');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_member` ADD INDEX `idx_member_tenant_status_created` (`tenant_id`, `status`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_member_tenant_status_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND index_name = 'idx_member_tenant_name');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_member` ADD INDEX `idx_member_tenant_name` (`tenant_id`, `name`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_member_tenant_name"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_dual_balance_account');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_dual_balance_account' AND index_name = 'idx_dual_bal_tenant');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_dual_balance_account` ADD INDEX `idx_dual_bal_tenant` (`tenant_id`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_dual_bal_tenant"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_time_card_bucket');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_time_card_bucket' AND index_name = 'idx_timecard_tenant_status');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_time_card_bucket` ADD INDEX `idx_timecard_tenant_status` (`tenant_id`, `status`, `expire_date`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_timecard_tenant_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 7. sh_product, sh_product_category, sh_product_bom, sh_commission_record 二级索引
SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_product');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_product' AND index_name = 'idx_prod_tenant_store_avail');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_product` ADD INDEX `idx_prod_tenant_store_avail` (`tenant_id`, `store_id`, `is_available`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_prod_tenant_store_avail"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_product' AND index_name = 'idx_prod_code');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_product` ADD INDEX `idx_prod_code` (`product_code`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_prod_code"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_product_category');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_product_category' AND index_name = 'idx_prod_cat_tenant_sort');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_product_category` ADD INDEX `idx_prod_cat_tenant_sort` (`tenant_id`, `is_available`, `sort_order`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_prod_cat_tenant_sort"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_product_bom');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_product_bom' AND index_name = 'idx_bom_material');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_product_bom` ADD INDEX `idx_bom_material` (`material_product_id`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_bom_material"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_commission_record');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_commission_record' AND index_name = 'idx_comm_tenant_store_created');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_commission_record` ADD INDEX `idx_comm_tenant_store_created` (`tenant_id`, `store_id`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_comm_tenant_store_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_commission_record' AND index_name = 'idx_comm_billing_order');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_commission_record` ADD INDEX `idx_comm_billing_order` (`billing_order_id`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_comm_billing_order"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 8. 审计日志与扩展业务表二级索引 (若表存在则创建)
SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_member_recharge_record');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member_recharge_record' AND index_name = 'idx_rch_store_created');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_member_recharge_record` ADD INDEX `idx_rch_store_created` (`store_id`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_rch_store_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member_recharge_record' AND index_name = 'idx_rch_member_created');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_member_recharge_record` ADD INDEX `idx_rch_member_created` (`member_id`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_rch_member_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member_recharge_record' AND index_name = 'idx_rch_tenant_status');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_member_recharge_record` ADD INDEX `idx_rch_tenant_status` (`tenant_id`, `status`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_rch_tenant_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_appointment');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_appointment' AND index_name = 'idx_apt_store_date_status');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_appointment` ADD INDEX `idx_apt_store_date_status` (`store_id`, `apt_date`, `status`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_apt_store_date_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_appointment' AND index_name = 'idx_apt_tenant_created');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_appointment` ADD INDEX `idx_apt_tenant_created` (`tenant_id`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_apt_tenant_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_leave_application');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_leave_application' AND index_name = 'idx_leave_store_created');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_leave_application` ADD INDEX `idx_leave_store_created` (`store_id`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_leave_store_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_leave_application' AND index_name = 'idx_leave_tenant_status');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_leave_application` ADD INDEX `idx_leave_tenant_status` (`tenant_id`, `status`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_leave_tenant_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @tbl := (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'sh_security_log');
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_security_log' AND index_name = 'idx_seclog_store_created');
SET @sqlstmt := IF(@tbl > 0 AND @idx = 0, 'ALTER TABLE `sh_security_log` ADD INDEX `idx_seclog_store_created` (`store_id`, `created_at`) ALGORITHM=INPLACE, LOCK=NONE', 'SELECT "Skip idx_seclog_store_created"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;
