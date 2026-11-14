-- =============================================================================
-- Migration: V1.0.3__sync_domain_tables_and_optimistic_locking.sql
-- Description: 补齐海马智慧门店全部扩展领域实体表、扩展字段、租户级会员编号复合唯一约束与 JPA 乐观锁版本号 (Expand 阶段)
-- Backward-compatible: YES (仅增量建表、带默认值新增列与扩展唯一索引，无破坏性删表删列)
-- Rollback script: U1.0.3__rollback_domain_tables_and_optimistic_locking.sql
-- Author: FWPT Database Architecture Team
-- Created: 2026-11-14
-- =============================================================================

USE `seahorse_store`;

-- =============================================================================
-- 第一部分：补齐扩展业务领域实体表 (与 schema.sql / JPA @Entity 100% 对齐)
-- =============================================================================

CREATE TABLE IF NOT EXISTS `sh_appointment` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) NOT NULL,
  `apt_no` varchar(64) NOT NULL,
  `customer_name` varchar(64) NOT NULL,
  `phone` varchar(32) NOT NULL,
  `people_count` int DEFAULT '1',
  `service_name` varchar(128) DEFAULT NULL,
  `service_price` decimal(10,2) DEFAULT NULL,
  `space_code` varchar(64) DEFAULT NULL,
  `space_name` varchar(128) DEFAULT NULL,
  `staff_name` varchar(64) DEFAULT NULL,
  `apt_date` varchar(32) NOT NULL,
  `apt_time` varchar(32) NOT NULL,
  `status` varchar(32) NOT NULL DEFAULT 'PENDING',
  `notes` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_apt_store_date` (`store_id`, `apt_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='顾客预约排班表';

CREATE TABLE IF NOT EXISTS `sh_amap_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) DEFAULT NULL,
  `web_api_key` varchar(128) DEFAULT NULL,
  `js_api_key` varchar(128) DEFAULT NULL,
  `security_code` varchar(128) DEFAULT NULL,
  `allowed_radius_meters` int DEFAULT '500',
  `store_longitude` double DEFAULT NULL,
  `store_latitude` double DEFAULT NULL,
  `store_address` varchar(255) DEFAULT NULL,
  `store_name` varchar(128) DEFAULT NULL,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_amap_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='高德地图与考勤配置表';

CREATE TABLE IF NOT EXISTS `sh_industry_category` (
  `id` int NOT NULL,
  `name` varchar(64) NOT NULL,
  `group_name` varchar(64) NOT NULL,
  `default_industry_type` varchar(32) DEFAULT NULL,
  `sort_order` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='细分行业字典分类表';

CREATE TABLE IF NOT EXISTS `sh_industry_preset_template` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `industry` varchar(32) NOT NULL,
  `industry_name` varchar(64) NOT NULL,
  `card_templates_json` longtext,
  `preference_tags_json` longtext,
  `charge_options_json` longtext,
  `departments_json` longtext,
  `positions_json` longtext,
  `updated_by` varchar(64) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_preset_industry` (`industry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='行业全景预设标准模板表';

CREATE TABLE IF NOT EXISTS `sh_role_permission_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `role_code` varchar(32) NOT NULL,
  `role_name` varchar(64) NOT NULL,
  `permissions` text,
  `description` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_role_perm_tenant` (`tenant_id`, `role_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色权限矩阵配置表';

CREATE TABLE IF NOT EXISTS `sh_staff_reward_punish` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `employee_id` bigint NOT NULL,
  `employee_name` varchar(64) NOT NULL,
  `type` varchar(32) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `record_date` date DEFAULT NULL,
  `operator` varchar(64) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rp_tenant_emp` (`tenant_id`, `employee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工奖惩记录表';

CREATE TABLE IF NOT EXISTS `sh_store_register_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) NOT NULL,
  `preference_tags` text,
  `charge_options` text,
  `welcome_coupon_enabled` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_reg_cfg_store` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='门店顾客扫码注册定制配置表';

CREATE TABLE IF NOT EXISTS `sh_leave_application` (
  `id` varchar(64) NOT NULL,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) DEFAULT NULL,
  `staff_id` bigint DEFAULT NULL,
  `staff_name` varchar(64) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `post_name` varchar(64) DEFAULT NULL,
  `department` varchar(64) DEFAULT NULL,
  `leave_type` varchar(32) DEFAULT NULL,
  `leave_type_name` varchar(64) DEFAULT NULL,
  `start_time` varchar(64) DEFAULT NULL,
  `end_time` varchar(64) DEFAULT NULL,
  `total_hours` double DEFAULT NULL,
  `total_days` double DEFAULT NULL,
  `reason` text,
  `status` varchar(32) DEFAULT 'PENDING',
  `apply_time` varchar(64) DEFAULT NULL,
  `current_approver` varchar(64) DEFAULT NULL,
  `audit_time` varchar(64) DEFAULT NULL,
  `audit_notes` text,
  `timeline_json` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_leave_tenant_store` (`tenant_id`, `store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工请假审批单表';

CREATE TABLE IF NOT EXISTS `sh_member_card_template` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) DEFAULT NULL,
  `card_type` varchar(64) NOT NULL,
  `card_type_name` varchar(64) NOT NULL,
  `card_name` varchar(128) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `original_price` decimal(10,2) DEFAULT NULL,
  `content_description` varchar(512) DEFAULT NULL,
  `principal_amount` decimal(10,2) DEFAULT NULL,
  `gift_amount` decimal(10,2) DEFAULT NULL,
  `discount_rate` decimal(5,2) DEFAULT NULL,
  `total_times` int DEFAULT NULL,
  `validity_days` int DEFAULT '0',
  `service_sku_id` bigint DEFAULT NULL,
  `service_sku_name` varchar(128) DEFAULT NULL,
  `status` varchar(32) DEFAULT 'ACTIVE',
  `sort_order` int DEFAULT '0',
  `notes` varchar(512) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_card_tpl_tenant` (`tenant_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员卡项标准与售卡模板表';

CREATE TABLE IF NOT EXISTS `sh_member_recharge_record` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) DEFAULT NULL,
  `order_no` varchar(64) NOT NULL,
  `member_id` bigint NOT NULL,
  `member_name` varchar(64) DEFAULT NULL,
  `member_phone` varchar(32) DEFAULT NULL,
  `principal_amount` decimal(10,2) NOT NULL,
  `gift_amount` decimal(10,2) DEFAULT '0.00',
  `seller_employee_id` bigint DEFAULT NULL,
  `seller_employee_name` varchar(64) DEFAULT NULL,
  `payment_method` varchar(32) DEFAULT NULL,
  `status` varchar(32) NOT NULL DEFAULT 'SUCCESS',
  `notes` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_recharge_order_no` (`order_no`),
  KEY `idx_recharge_member` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员储值充值流水表';

CREATE TABLE IF NOT EXISTS `sh_store_notice` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) NOT NULL,
  `title` varchar(256) NOT NULL,
  `category` varchar(32) NOT NULL,
  `category_name` varchar(64) DEFAULT NULL,
  `summary` varchar(500) DEFAULT NULL,
  `content` text,
  `key_points` varchar(1000) DEFAULT NULL,
  `version` varchar(32) DEFAULT NULL,
  `effective_date` varchar(32) DEFAULT NULL,
  `publisher` varchar(64) DEFAULT NULL,
  `publisher_role` varchar(32) DEFAULT NULL,
  `is_urgent` tinyint(1) DEFAULT '0',
  `play_music` tinyint(1) DEFAULT '0',
  `require_signature` tinyint(1) DEFAULT '0',
  `status` varchar(32) DEFAULT 'PUBLISHED',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_store_notice_store_id` (`store_id`),
  KEY `idx_store_notice_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='门店运营规范与日常公告表';

CREATE TABLE IF NOT EXISTS `sh_notification_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `wechat_enabled` tinyint(1) DEFAULT '1',
  `wechat_app_id` varchar(64) DEFAULT NULL,
  `wechat_app_secret` varchar(128) DEFAULT NULL,
  `wechat_token` varchar(64) DEFAULT NULL,
  `wechat_aes_key` varchar(128) DEFAULT NULL,
  `wechat_qr_code_url` varchar(500) DEFAULT NULL,
  `wechat_consume_template_id` varchar(128) DEFAULT NULL,
  `wechat_recharge_template_id` varchar(128) DEFAULT NULL,
  `wechat_marketing_template_id` varchar(128) DEFAULT NULL,
  `alipay_enabled` tinyint(1) DEFAULT '1',
  `alipay_app_id` varchar(64) DEFAULT NULL,
  `alipay_private_key` varchar(2048) DEFAULT NULL,
  `alipay_public_key` varchar(2048) DEFAULT NULL,
  `alipay_qr_code_url` varchar(500) DEFAULT NULL,
  `alipay_consume_template_id` varchar(128) DEFAULT NULL,
  `alipay_marketing_template_id` varchar(128) DEFAULT NULL,
  `mock_push_enabled` tinyint(1) DEFAULT '1',
  `auto_push_on_checkout` tinyint(1) DEFAULT '1',
  `auto_push_on_recharge` tinyint(1) DEFAULT '1',
  `auto_push_on_marketing` tinyint(1) DEFAULT '1',
  `voice_broadcast_repeat_count` int DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_notif_cfg_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='全渠道公众号与生活号推送配置表';

CREATE TABLE IF NOT EXISTS `sh_notification_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) DEFAULT NULL,
  `member_id` bigint DEFAULT NULL,
  `member_name` varchar(64) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `channel` varchar(32) NOT NULL,
  `msg_type` varchar(32) NOT NULL,
  `target_open_id` varchar(128) DEFAULT NULL,
  `template_id` varchar(128) DEFAULT NULL,
  `title` varchar(256) NOT NULL,
  `content` varchar(4000) DEFAULT NULL,
  `data_json` varchar(4000) DEFAULT NULL,
  `status` varchar(32) NOT NULL,
  `error_message` varchar(1000) DEFAULT NULL,
  `sent_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notif_log_tenant_sent` (`tenant_id`, `sent_at`),
  KEY `idx_notif_log_member` (`tenant_id`, `member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='全渠道消息推送历史流水表';

CREATE TABLE IF NOT EXISTS `sh_attendance_record` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `record_no` varchar(64) NOT NULL,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) DEFAULT NULL,
  `staff_name` varchar(64) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `post_name` varchar(64) DEFAULT NULL,
  `work_date` varchar(32) DEFAULT NULL,
  `check_in_time` varchar(32) DEFAULT NULL,
  `check_in_status` varchar(32) DEFAULT NULL,
  `check_out_time` varchar(32) DEFAULT NULL,
  `check_out_status` varchar(32) DEFAULT NULL,
  `work_hours` double DEFAULT NULL,
  `check_in_location` varchar(255) DEFAULT NULL,
  `platform_source` varchar(32) DEFAULT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_attendance_record_no` (`record_no`),
  KEY `idx_attendance_tenant_store_date` (`tenant_id`, `store_id`, `work_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工考勤打卡流水表';

CREATE TABLE IF NOT EXISTS `sh_job_application` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `application_no` varchar(64) NOT NULL,
  `tenant_id` varchar(64) NOT NULL,
  `store_name` varchar(128) DEFAULT NULL,
  `post_id` bigint DEFAULT NULL,
  `post_name` varchar(128) DEFAULT NULL,
  `candidate_name` varchar(64) NOT NULL,
  `gender` varchar(16) DEFAULT NULL,
  `age` int DEFAULT NULL,
  `phone` varchar(32) NOT NULL,
  `education` varchar(64) DEFAULT NULL,
  `experience_years` int DEFAULT NULL,
  `expected_salary` varchar(64) DEFAULT NULL,
  `available_date` varchar(64) DEFAULT NULL,
  `personal_advantage` text,
  `work_history` text,
  `certificates` varchar(1000) DEFAULT NULL,
  `apply_time` varchar(64) DEFAULT NULL,
  `status` varchar(32) DEFAULT 'PENDING',
  `interview_info_json` text,
  `interview_evaluation_json` text,
  `reject_reason` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_job_application_no` (`application_no`),
  KEY `idx_job_app_tenant_phone` (`tenant_id`, `phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='岗位招聘与求职简历投递表';

-- =============================================================================
-- 第二部分：幂等补齐基线表扩展列与 JPA @Version 乐观锁列
-- =============================================================================

-- 1. sh_store 扩展列
SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_store' AND column_name = 'industry_category_id');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_store` ADD COLUMN `industry_category_id` int DEFAULT NULL', 'SELECT "Skip sh_store.industry_category_id"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_store' AND column_name = 'industry_category_name');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_store` ADD COLUMN `industry_category_name` varchar(255) DEFAULT NULL', 'SELECT "Skip sh_store.industry_category_name"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_store' AND column_name = 'industry_category_group');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_store` ADD COLUMN `industry_category_group` varchar(255) DEFAULT NULL', 'SELECT "Skip sh_store.industry_category_group"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_store' AND column_name = 'custom_positions_json');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_store` ADD COLUMN `custom_positions_json` text', 'SELECT "Skip sh_store.custom_positions_json"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_store' AND column_name = 'custom_departments_json');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_store` ADD COLUMN `custom_departments_json` text', 'SELECT "Skip sh_store.custom_departments_json"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_store' AND column_name = 'common_remarks_json');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_store` ADD COLUMN `common_remarks_json` text', 'SELECT "Skip sh_store.common_remarks_json"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_store' AND column_name = 'staff_display_mode');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_store` ADD COLUMN `staff_display_mode` varchar(32) DEFAULT NULL', 'SELECT "Skip sh_store.staff_display_mode"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2. sh_employee 扩展列及可空性对齐
ALTER TABLE `sh_employee` MODIFY COLUMN `store_id` varchar(64) DEFAULT NULL, MODIFY COLUMN `password` varchar(255) DEFAULT NULL;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND column_name = 'nickname');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_employee` ADD COLUMN `nickname` varchar(64) DEFAULT NULL', 'SELECT "Skip sh_employee.nickname"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND column_name = 'post_name');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_employee` ADD COLUMN `post_name` varchar(255) DEFAULT NULL', 'SELECT "Skip sh_employee.post_name"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND column_name = 'gender');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_employee` ADD COLUMN `gender` varchar(32) DEFAULT NULL', 'SELECT "Skip sh_employee.gender"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND column_name = 'id_card');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_employee` ADD COLUMN `id_card` varchar(64) DEFAULT NULL', 'SELECT "Skip sh_employee.id_card"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND column_name = 'base_salary');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_employee` ADD COLUMN `base_salary` decimal(10,2) DEFAULT NULL', 'SELECT "Skip sh_employee.base_salary"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND column_name = 'is_deleted');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_employee` ADD COLUMN `is_deleted` tinyint(1) DEFAULT ''0''', 'SELECT "Skip sh_employee.is_deleted"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND column_name = 'department');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_employee` ADD COLUMN `department` varchar(128) DEFAULT NULL', 'SELECT "Skip sh_employee.department"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND column_name = 'audit_status');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_employee` ADD COLUMN `audit_status` varchar(32) DEFAULT NULL', 'SELECT "Skip sh_employee.audit_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND column_name = 'is_self_applied');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_employee` ADD COLUMN `is_self_applied` tinyint(1) DEFAULT ''0''', 'SELECT "Skip sh_employee.is_self_applied"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_employee' AND column_name = 'experience');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_employee` ADD COLUMN `experience` varchar(1024) DEFAULT NULL', 'SELECT "Skip sh_employee.experience"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. sh_service_space & sh_service_session 扩展列
SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_service_space' AND column_name = 'min_consume_amount');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_service_space` ADD COLUMN `min_consume_amount` decimal(10,2) DEFAULT NULL', 'SELECT "Skip sh_service_space.min_consume_amount"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_service_space' AND column_name = 'hourly_fee');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_service_space` ADD COLUMN `hourly_fee` decimal(10,2) DEFAULT NULL', 'SELECT "Skip sh_service_space.hourly_fee"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_service_space' AND column_name = 'facilities');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_service_space` ADD COLUMN `facilities` varchar(255) DEFAULT NULL', 'SELECT "Skip sh_service_space.facilities"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_service_space' AND column_name = 'notes');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_service_space` ADD COLUMN `notes` varchar(255) DEFAULT NULL', 'SELECT "Skip sh_service_space.notes"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_service_space' AND column_name = 'sort_order');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_service_space` ADD COLUMN `sort_order` int DEFAULT ''0''', 'SELECT "Skip sh_service_space.sort_order"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_service_session' AND column_name = 'fee_name');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_service_session` ADD COLUMN `fee_name` varchar(64) DEFAULT NULL', 'SELECT "Skip sh_service_session.fee_name"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4. sh_member 扩展列与租户级会员编号唯一索引
SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'card_no');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `card_no` varchar(64) DEFAULT NULL', 'SELECT "Skip sh_member.card_no"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'card_password');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `card_password` varchar(255) DEFAULT NULL', 'SELECT "Skip sh_member.card_password"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'card_password_enabled');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `card_password_enabled` tinyint(1) DEFAULT ''0''', 'SELECT "Skip sh_member.card_password_enabled"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'card_sign_enabled');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `card_sign_enabled` tinyint(1) DEFAULT ''0''', 'SELECT "Skip sh_member.card_sign_enabled"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'discount_name');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `discount_name` varchar(64) DEFAULT NULL', 'SELECT "Skip sh_member.discount_name"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'referrer_name');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `referrer_name` varchar(64) DEFAULT NULL', 'SELECT "Skip sh_member.referrer_name"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'birthday_type');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `birthday_type` varchar(16) DEFAULT ''SOLAR''', 'SELECT "Skip sh_member.birthday_type"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'reward_amount');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `reward_amount` decimal(10,2) DEFAULT ''0.00''', 'SELECT "Skip sh_member.reward_amount"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'points');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `points` int DEFAULT ''0''', 'SELECT "Skip sh_member.points"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'debt_amount');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `debt_amount` decimal(10,2) DEFAULT ''0.00''', 'SELECT "Skip sh_member.debt_amount"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'wechat_bound');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `wechat_bound` tinyint(1) DEFAULT ''0''', 'SELECT "Skip sh_member.wechat_bound"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'wechat_open_id');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `wechat_open_id` varchar(128) DEFAULT NULL', 'SELECT "Skip sh_member.wechat_open_id"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'wechat_follow_status');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `wechat_follow_status` tinyint(1) DEFAULT ''0''', 'SELECT "Skip sh_member.wechat_follow_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'wechat_follow_time');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `wechat_follow_time` datetime DEFAULT NULL', 'SELECT "Skip sh_member.wechat_follow_time"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'alipay_user_id');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `alipay_user_id` varchar(128) DEFAULT NULL', 'SELECT "Skip sh_member.alipay_user_id"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'alipay_follow_status');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `alipay_follow_status` tinyint(1) DEFAULT ''0''', 'SELECT "Skip sh_member.alipay_follow_status"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'alipay_follow_time');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `alipay_follow_time` datetime DEFAULT NULL', 'SELECT "Skip sh_member.alipay_follow_time"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'push_notification_enabled');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `push_notification_enabled` tinyint(1) DEFAULT ''1''', 'SELECT "Skip sh_member.push_notification_enabled"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'card_open_count');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `card_open_count` int DEFAULT ''0''', 'SELECT "Skip sh_member.card_open_count"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND column_name = 'notes');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_member` ADD COLUMN `notes` varchar(1000) DEFAULT NULL', 'SELECT "Skip sh_member.notes"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_new := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND index_name = 'uk_tenant_member_no');
SET @sqlstmt := IF(@idx_new = 0, 'ALTER TABLE `sh_member` ADD UNIQUE INDEX `uk_tenant_member_no` (`tenant_id`, `member_no`)', 'SELECT "Skip uk_tenant_member_no"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_old := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'sh_member' AND index_name = 'uk_member_no');
SET @sqlstmt := IF(@idx_old > 0, 'ALTER TABLE `sh_member` DROP INDEX `uk_member_no`', 'SELECT "Skip drop uk_member_no"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 5. sh_dual_balance_account, sh_product, sh_tenant_subscription, sh_subscription_plan_config 乐观锁与套餐上限扩展列
SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_dual_balance_account' AND column_name = 'deduct_mode');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_dual_balance_account` ADD COLUMN `deduct_mode` varchar(32) DEFAULT ''PROPORTIONAL''', 'SELECT "Skip sh_dual_balance_account.deduct_mode"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_dual_balance_account' AND column_name = 'version');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_dual_balance_account` ADD COLUMN `version` bigint NOT NULL DEFAULT ''0'' COMMENT ''JPA乐观锁版本号''', 'SELECT "Skip sh_dual_balance_account.version"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_product' AND column_name = 'version');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_product` ADD COLUMN `version` bigint NOT NULL DEFAULT ''0'' COMMENT ''JPA乐观锁版本号''', 'SELECT "Skip sh_product.version"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_tenant_subscription' AND column_name = 'staff_limit');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_tenant_subscription` ADD COLUMN `staff_limit` int NOT NULL DEFAULT ''3'' COMMENT ''允许在岗员工上限''', 'SELECT "Skip sh_tenant_subscription.staff_limit"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'sh_subscription_plan_config' AND column_name = 'staff_limit');
SET @sqlstmt := IF(@col = 0, 'ALTER TABLE `sh_subscription_plan_config` ADD COLUMN `staff_limit` int NOT NULL DEFAULT ''3'' COMMENT ''允许员工上限''', 'SELECT "Skip sh_subscription_plan_config.staff_limit"');
PREPARE stmt FROM @sqlstmt; EXECUTE stmt; DEALLOCATE PREPARE stmt;
