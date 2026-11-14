-- ==========================================================
-- 海马 (Seahorse) ➔ 海马智慧门店 数据库全量结构脚本
-- Slogan: “海马会员，记住每位好客。”
-- 与 JPA @Entity 实体模型 100% 对齐 (兼容 prod 环境 ddl-auto: validate)
-- ==========================================================

CREATE DATABASE IF NOT EXISTS `seahorse_store` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `seahorse_store`;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. 租户表
DROP TABLE IF EXISTS `sh_tenant`;
CREATE TABLE `sh_tenant` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL COMMENT '租户全局唯一标识',
  `tenant_name` varchar(128) NOT NULL COMMENT '企业/商户名称',
  `contact_name` varchar(64) DEFAULT NULL,
  `contact_phone` varchar(32) DEFAULT NULL,
  `deduct_mode` varchar(32) DEFAULT 'PROPORTIONAL' COMMENT '双轨储值扣减策略: PROPORTIONAL (按比例) | PRINCIPAL_FIRST (优先本金)',
  `status` varchar(32) DEFAULT 'ACTIVE',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='租户表';

-- 2. 门店表
DROP TABLE IF EXISTS `sh_store`;
CREATE TABLE `sh_store` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) NOT NULL,
  `store_name` varchar(128) NOT NULL,
  `industry` varchar(32) NOT NULL DEFAULT 'BEAUTY' COMMENT '行业模态: RESTAURANT | BEAUTY | AUTO | RETAIL | FOOT_SPA | TEA_HOUSE | PET',
  `industry_category_id` int DEFAULT NULL,
  `industry_category_name` varchar(255) DEFAULT NULL,
  `industry_category_group` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `business_hours` varchar(64) DEFAULT NULL,
  `fee_name` varchar(64) DEFAULT '造型毛巾费',
  `default_fee_amount` decimal(10,2) DEFAULT '10.00',
  `fee_enabled` tinyint(1) DEFAULT '1',
  `status` varchar(32) DEFAULT 'ACTIVE',
  `custom_positions_json` text,
  `custom_departments_json` text,
  `common_remarks_json` text,
  `staff_display_mode` varchar(32) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_store_id` (`store_id`),
  KEY `idx_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='门店表';

-- 3. 员工组织表
DROP TABLE IF EXISTS `sh_employee`;
CREATE TABLE `sh_employee` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) DEFAULT NULL,
  `username` varchar(64) NOT NULL,
  `password` varchar(255) DEFAULT NULL,
  `real_name` varchar(64) NOT NULL,
  `nickname` varchar(64) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `role` varchar(32) NOT NULL COMMENT 'PLATFORM_DEVELOPER | SUPER_ADMIN | STORE_MANAGER | CASHIER | TECHNICIAN | WAITER',
  `post_name` varchar(255) DEFAULT NULL,
  `gender` varchar(32) DEFAULT NULL,
  `id_card` varchar(64) DEFAULT NULL,
  `base_salary` decimal(10,2) DEFAULT NULL,
  `default_commission_rate` decimal(5,4) DEFAULT '0.1500',
  `status` varchar(32) DEFAULT 'ACTIVE',
  `is_deleted` tinyint(1) DEFAULT '0',
  `department` varchar(128) DEFAULT NULL,
  `audit_status` varchar(32) DEFAULT NULL,
  `is_self_applied` tinyint(1) DEFAULT '0',
  `experience` varchar(1024) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`),
  KEY `idx_store_id` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工与技师表';

-- 4. 空间与工位表
DROP TABLE IF EXISTS `sh_service_space`;
CREATE TABLE `sh_service_space` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) NOT NULL,
  `space_code` varchar(64) NOT NULL COMMENT '工位编号如 M01, T01, BAY01',
  `space_name` varchar(128) NOT NULL,
  `space_type` varchar(32) NOT NULL COMMENT 'TABLE | MIRROR | BAY | ROOM',
  `status` varchar(32) NOT NULL DEFAULT 'IDLE' COMMENT 'IDLE | OCCUPIED | DIRTY | MAINTENANCE',
  `capacity` int DEFAULT '1',
  `floor_zone` varchar(64) DEFAULT '主服务区',
  `current_session_id` bigint DEFAULT NULL,
  `qr_code_url` varchar(255) DEFAULT NULL,
  `min_consume_amount` decimal(10,2) DEFAULT NULL,
  `hourly_fee` decimal(10,2) DEFAULT NULL,
  `facilities` varchar(255) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `sort_order` int DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_store_space` (`store_id`, `space_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='空间与工位表';

-- 5. 在场履约会话表
DROP TABLE IF EXISTS `sh_service_session`;
CREATE TABLE `sh_service_session` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) NOT NULL,
  `session_no` varchar(64) NOT NULL,
  `space_id` bigint NOT NULL,
  `space_code` varchar(64) DEFAULT NULL,
  `space_name` varchar(128) DEFAULT NULL,
  `status` varchar(32) NOT NULL COMMENT 'OCCUPIED_ORDERING | SERVING | SETTLING | SETTLED_WAIT_CLEAN | CLOSED',
  `member_id` bigint DEFAULT NULL,
  `customer_name` varchar(64) DEFAULT '散客',
  `customer_phone` varchar(32) DEFAULT NULL,
  `guest_count` int DEFAULT '1',
  `total_amount` decimal(10,2) DEFAULT '0.00',
  `fee_amount` decimal(10,2) DEFAULT '0.00',
  `fee_name` varchar(64) DEFAULT NULL,
  `discount_amount` decimal(10,2) DEFAULT '0.00',
  `payable_amount` decimal(10,2) DEFAULT '0.00',
  `notes` varchar(255) DEFAULT NULL,
  `start_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `end_time` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_session_no` (`session_no`),
  KEY `idx_space_status` (`space_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='在场履约会话表';

-- 6. 点单批次表
DROP TABLE IF EXISTS `sh_order_batch`;
CREATE TABLE `sh_order_batch` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `session_id` bigint NOT NULL,
  `batch_no` int NOT NULL DEFAULT '1',
  `operator_id` bigint DEFAULT NULL,
  `operator_name` varchar(64) DEFAULT NULL,
  `operator_type` varchar(32) DEFAULT 'WAITER',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_session_id` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='点单批次表';

-- 7. 点单消费明细行表
DROP TABLE IF EXISTS `sh_session_line_item`;
CREATE TABLE `sh_session_line_item` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `session_id` bigint NOT NULL,
  `batch_id` bigint NOT NULL,
  `batch_no` int DEFAULT '1',
  `product_id` bigint NOT NULL,
  `product_name` varchar(128) NOT NULL,
  `product_type` varchar(32) DEFAULT 'SERVICE',
  `category_name` varchar(64) DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  `subtotal` decimal(10,2) NOT NULL,
  `modifiers` varchar(255) DEFAULT NULL COMMENT '做法、忌口、规格说明',
  `status` varchar(32) DEFAULT 'ACTIVE' COMMENT 'ACTIVE | CANCELLED',
  `cancel_reason` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_session_line` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='点单明细行表';

-- 8. 服务人员提成分摊表
DROP TABLE IF EXISTS `sh_performer_share`;
CREATE TABLE `sh_performer_share` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `line_item_id` bigint NOT NULL,
  `session_id` bigint NOT NULL,
  `employee_id` bigint NOT NULL,
  `employee_name` varchar(64) DEFAULT NULL,
  `share_ratio` decimal(5,4) NOT NULL DEFAULT '1.0000',
  `performance_amount` decimal(10,2) DEFAULT '0.00',
  `commission_amount` decimal(10,2) DEFAULT '0.00',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_employee_session` (`employee_id`, `session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务人员提成分摊表';

-- 9. 统一结算账单表
DROP TABLE IF EXISTS `sh_billing_order`;
CREATE TABLE `sh_billing_order` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) NOT NULL,
  `order_no` varchar(64) NOT NULL,
  `session_id` bigint DEFAULT NULL,
  `session_no` varchar(64) DEFAULT NULL,
  `space_id` bigint DEFAULT NULL,
  `space_name` varchar(128) DEFAULT NULL,
  `member_id` bigint DEFAULT NULL,
  `customer_name` varchar(64) DEFAULT NULL,
  `customer_phone` varchar(32) DEFAULT NULL,
  `total_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `fee_amount` decimal(10,2) DEFAULT '0.00',
  `discount_amount` decimal(10,2) DEFAULT '0.00',
  `actual_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `paid_amount` decimal(10,2) DEFAULT '0.00',
  `status` varchar(32) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING | PAID | REFUNDED | CANCELLED',
  `cashier_id` bigint DEFAULT NULL,
  `cashier_name` varchar(64) DEFAULT NULL,
  `settled_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_billing_session_id` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='统一结算账单表';

-- 10. 支付记录明细表
DROP TABLE IF EXISTS `sh_payment_record`;
CREATE TABLE `sh_payment_record` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `billing_order_id` bigint NOT NULL,
  `order_no` varchar(64) DEFAULT NULL,
  `channel` varchar(32) NOT NULL COMMENT 'WECHAT | ALIPAY | CASH | STORED_VALUE | TIME_CARD | UNION_PAY',
  `amount` decimal(10,2) NOT NULL,
  `principal_amount` decimal(10,2) DEFAULT NULL,
  `gift_amount` decimal(10,2) DEFAULT NULL,
  `time_card_deduct_count` int DEFAULT NULL,
  `time_card_sku_id` bigint DEFAULT NULL,
  `trade_no` varchar(64) DEFAULT NULL,
  `status` varchar(32) DEFAULT 'SUCCESS',
  `pay_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_billing_order_id` (`billing_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付流水明细表';

-- 11. 现金收找记录表
DROP TABLE IF EXISTS `sh_cash_tender_record`;
CREATE TABLE `sh_cash_tender_record` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `billing_order_id` bigint NOT NULL,
  `due_amount` decimal(10,2) NOT NULL,
  `tendered_amount` decimal(10,2) NOT NULL,
  `change_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `drawer_opened` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_billing_cash` (`billing_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='现金收找记录表';

-- 12. 会员主体表
DROP TABLE IF EXISTS `sh_member`;
CREATE TABLE `sh_member` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `member_no` varchar(64) NOT NULL,
  `name` varchar(64) NOT NULL,
  `phone` varchar(32) NOT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `gender` varchar(16) DEFAULT 'UNKNOWN',
  `birthday` date DEFAULT NULL,
  `level` varchar(32) NOT NULL DEFAULT 'REGULAR',
  `total_spent` decimal(10,2) DEFAULT '0.00',
  `visit_count` int DEFAULT '0',
  `last_visit_time` datetime DEFAULT NULL,
  `status` varchar(32) DEFAULT 'ACTIVE',
  `card_no` varchar(64) DEFAULT NULL,
  `card_password` varchar(255) DEFAULT NULL,
  `card_password_enabled` tinyint(1) DEFAULT '0',
  `card_sign_enabled` tinyint(1) DEFAULT '0',
  `discount_name` varchar(64) DEFAULT NULL,
  `referrer_name` varchar(64) DEFAULT NULL,
  `birthday_type` varchar(16) DEFAULT 'SOLAR',
  `reward_amount` decimal(10,2) DEFAULT '0.00',
  `points` int DEFAULT '0',
  `debt_amount` decimal(10,2) DEFAULT '0.00',
  `wechat_bound` tinyint(1) DEFAULT '0',
  `wechat_open_id` varchar(128) DEFAULT NULL,
  `wechat_follow_status` tinyint(1) DEFAULT '0',
  `wechat_follow_time` datetime DEFAULT NULL,
  `alipay_user_id` varchar(128) DEFAULT NULL,
  `alipay_follow_status` tinyint(1) DEFAULT '0',
  `alipay_follow_time` datetime DEFAULT NULL,
  `push_notification_enabled` tinyint(1) DEFAULT '1',
  `card_open_count` int DEFAULT '0',
  `notes` varchar(1000) DEFAULT NULL,
  `trial_expire_date` date DEFAULT NULL COMMENT '试用期到期日(默认3天试用)',
  `is_trial` tinyint(1) DEFAULT '1' COMMENT '是否处于权益试用期',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tenant_member_no` (`tenant_id`, `member_no`),
  UNIQUE KEY `uk_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员主体表';

-- 13. 双轨储值资金账户表
DROP TABLE IF EXISTS `sh_dual_balance_account`;
CREATE TABLE `sh_dual_balance_account` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `tenant_id` varchar(64) NOT NULL,
  `principal_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '本金余额',
  `gift_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '赠送金余额',
  `total_recharged` decimal(10,2) DEFAULT '0.00',
  `total_gift_granted` decimal(10,2) DEFAULT '0.00',
  `deduct_mode` varchar(32) DEFAULT 'PROPORTIONAL',
  `version` bigint NOT NULL DEFAULT '0' COMMENT 'JPA乐观锁版本号',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_balance` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='双轨储值资金账户表';

-- 15. 计量次卡桶表
DROP TABLE IF EXISTS `sh_time_card_bucket`;
CREATE TABLE `sh_time_card_bucket` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `tenant_id` varchar(64) NOT NULL,
  `sku_id` bigint NOT NULL,
  `sku_name` varchar(128) NOT NULL,
  `total_times` int NOT NULL DEFAULT '1',
  `remaining_times` int NOT NULL DEFAULT '1',
  `expire_date` date DEFAULT NULL,
  `status` varchar(32) DEFAULT 'ACTIVE',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_member_sku` (`member_id`, `sku_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='计量服务次卡桶表';

-- 16. “海马体”记忆标签档案表
DROP TABLE IF EXISTS `sh_member_preference`;
CREATE TABLE `sh_member_preference` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `tenant_id` varchar(64) NOT NULL,
  `category` varchar(64) NOT NULL COMMENT 'BEAUTY_HAIR | RESTAURANT_TASTE | AUTO_VEHICLE | HABIT',
  `tag_key` varchar(64) NOT NULL,
  `tag_value` varchar(255) NOT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `updated_by` varchar(64) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_member_category` (`member_id`, `category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='海马体个性记忆标签档案表';

-- 17. 商品服务与耗材表
DROP TABLE IF EXISTS `sh_product`;
CREATE TABLE `sh_product` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) NOT NULL,
  `product_code` varchar(64) NOT NULL,
  `name` varchar(128) NOT NULL,
  `category_id` bigint DEFAULT NULL,
  `category_name` varchar(64) DEFAULT NULL,
  `product_type` varchar(32) NOT NULL COMMENT 'SERVICE | PHYSICAL | MATERIAL',
  `price` decimal(10,2) NOT NULL,
  `cost_price` decimal(10,2) DEFAULT NULL,
  `stock` int DEFAULT NULL,
  `unit` varchar(16) DEFAULT '次',
  `duration_minutes` int DEFAULT '30',
  `default_commission` decimal(10,2) DEFAULT '0.00',
  `image_url` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `is_available` tinyint(1) DEFAULT '1',
  `version` bigint NOT NULL DEFAULT '0' COMMENT 'JPA乐观锁版本号',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_store_product` (`store_id`, `product_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品与服务表';

-- 18. 商品分类表
DROP TABLE IF EXISTS `sh_product_category`;
CREATE TABLE `sh_product_category` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `name` varchar(64) NOT NULL,
  `industry` varchar(32) DEFAULT 'GENERAL',
  `sort_order` int DEFAULT '0',
  `is_available` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品分类表';

-- 19. 服务关联 BOM 耗材配方表
DROP TABLE IF EXISTS `sh_product_bom`;
CREATE TABLE `sh_product_bom` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `service_product_id` bigint NOT NULL,
  `material_product_id` bigint NOT NULL,
  `material_name` varchar(128) NOT NULL,
  `consume_quantity` decimal(10,2) NOT NULL DEFAULT '1.00',
  `unit` varchar(16) DEFAULT '瓶',
  PRIMARY KEY (`id`),
  KEY `idx_service_product` (`service_product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务关联BOM耗材配方表';

-- 20. 员工提成流水表
DROP TABLE IF EXISTS `sh_commission_record`;
CREATE TABLE `sh_commission_record` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `store_id` varchar(64) NOT NULL,
  `employee_id` bigint NOT NULL,
  `employee_name` varchar(64) DEFAULT NULL,
  `billing_order_id` bigint DEFAULT NULL,
  `line_item_id` bigint DEFAULT NULL,
  `commission_type` varchar(32) NOT NULL COMMENT 'SERVICE_WORK | RECHARGE | RETAIL_SALE',
  `base_amount` decimal(10,2) DEFAULT '0.00',
  `commission_rate` decimal(5,4) DEFAULT '0.1500',
  `commission_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `notes` varchar(255) DEFAULT NULL,
  `status` varchar(32) DEFAULT 'RECORDED',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_employee_time` (`employee_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工提成流水表';

-- 21. SaaS 商户会员订阅合约表
DROP TABLE IF EXISTS `sh_tenant_subscription`;
CREATE TABLE `sh_tenant_subscription` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` varchar(64) NOT NULL,
  `plan` varchar(32) NOT NULL DEFAULT 'PROFESSIONAL' COMMENT 'TRIAL | PROFESSIONAL | FLAGSHIP | ENTERPRISE',
  `store_limit` int NOT NULL DEFAULT '3' COMMENT '允许开店上限',
  `staff_limit` int NOT NULL DEFAULT '3' COMMENT '允许在岗员工上限',
  `storage_quota_gb` int NOT NULL DEFAULT '50' COMMENT '云存储配额GB',
  `start_date` date NOT NULL,
  `expire_date` date NOT NULL,
  `fee_paid` decimal(10,2) DEFAULT '0.00',
  `status` varchar(32) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE | EXPIRING | EXPIRED',
  `auto_renew` tinyint(1) DEFAULT '1',
  `notes` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sub_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SaaS商户会员订阅合约表';

-- 22. SaaS 订阅与云存储服务费缴费流水表
DROP TABLE IF EXISTS `sh_subscription_billing_record`;
CREATE TABLE `sh_subscription_billing_record` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `record_no` varchar(64) NOT NULL,
  `tenant_id` varchar(64) NOT NULL,
  `tenant_name` varchar(128) DEFAULT NULL,
  `billing_type` varchar(32) NOT NULL COMMENT 'PLAN_SUBSCRIPTION | STORAGE_SERVICE',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `storage_gb_granted` int DEFAULT '0',
  `duration_months` int DEFAULT '12',
  `period_start` date DEFAULT NULL,
  `period_end` date DEFAULT NULL,
  `pay_time` datetime NOT NULL,
  `payment_method` varchar(32) DEFAULT 'OFFLINE',
  `operator` varchar(64) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_record_no` (`record_no`),
  KEY `idx_tenant_paytime` (`tenant_id`, `pay_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SaaS订阅与云存储服务费缴费流水表';

-- 23. SaaS 会员套餐版本与定价/试用期配置表
DROP TABLE IF EXISTS `sh_subscription_plan_config`;
CREATE TABLE `sh_subscription_plan_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `plan_code` varchar(32) NOT NULL COMMENT 'TRIAL | PROFESSIONAL | FLAGSHIP | ENTERPRISE',
  `plan_name` varchar(64) NOT NULL COMMENT '套餐显示名称',
  `annual_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '会员套餐价格/年',
  `trial_days` int NOT NULL DEFAULT '3' COMMENT '免费试用期天数',
  `store_limit` int NOT NULL DEFAULT '1' COMMENT '允许开店上限',
  `staff_limit` int NOT NULL DEFAULT '3' COMMENT '允许员工上限',
  `storage_quota_gb` int NOT NULL DEFAULT '5' COMMENT '存储空间GB',
  `features` varchar(500) DEFAULT NULL COMMENT '功能特性与适用描述',
  `is_default` tinyint(1) DEFAULT '0' COMMENT '是否为新注册默认选中套餐',
  `status` varchar(32) NOT NULL DEFAULT 'ACTIVE' COMMENT 'ACTIVE | DISABLED',
  `sort_order` int DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_plan_code` (`plan_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SaaS会员套餐版本与定价配置表';

-- 24. 顾客预约排班表
DROP TABLE IF EXISTS `sh_appointment`;
CREATE TABLE `sh_appointment` (
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

-- 25. 安全审计策略配置表
DROP TABLE IF EXISTS `sh_audit_policy`;
CREATE TABLE `sh_audit_policy` (
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

-- 26. 系统安全与登录审计日志表
DROP TABLE IF EXISTS `sh_security_log`;
CREATE TABLE `sh_security_log` (
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

-- 27. 高德地图与地理围栏考勤配置表
DROP TABLE IF EXISTS `sh_amap_config`;
CREATE TABLE `sh_amap_config` (
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

-- 28. 细分行业字典分类表
DROP TABLE IF EXISTS `sh_industry_category`;
CREATE TABLE `sh_industry_category` (
  `id` int NOT NULL,
  `name` varchar(64) NOT NULL,
  `group_name` varchar(64) NOT NULL,
  `default_industry_type` varchar(32) DEFAULT NULL,
  `sort_order` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='细分行业字典分类表';

-- 29. 行业全景预设标准模板表
DROP TABLE IF EXISTS `sh_industry_preset_template`;
CREATE TABLE `sh_industry_preset_template` (
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

-- 30. 角色权限矩阵配置表
DROP TABLE IF EXISTS `sh_role_permission_config`;
CREATE TABLE `sh_role_permission_config` (
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

-- 31. 员工奖惩记录表
DROP TABLE IF EXISTS `sh_staff_reward_punish`;
CREATE TABLE `sh_staff_reward_punish` (
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

-- 32. 门店顾客扫码注册定制配置表
DROP TABLE IF EXISTS `sh_store_register_config`;
CREATE TABLE `sh_store_register_config` (
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

-- 33. 员工请假审批单表
DROP TABLE IF EXISTS `sh_leave_application`;
CREATE TABLE `sh_leave_application` (
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

-- 34. 会员卡项标准与售卡模板表
DROP TABLE IF EXISTS `sh_member_card_template`;
CREATE TABLE `sh_member_card_template` (
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

-- 35. 会员储值充值流水表
DROP TABLE IF EXISTS `sh_member_recharge_record`;
CREATE TABLE `sh_member_recharge_record` (
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

-- 36. 门店运营规范与日常公告表
DROP TABLE IF EXISTS `sh_store_notice`;
CREATE TABLE `sh_store_notice` (
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

-- 37. 全渠道公众号与生活号推送配置表
DROP TABLE IF EXISTS `sh_notification_config`;
CREATE TABLE `sh_notification_config` (
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

-- 38. 全渠道消息推送历史流水表
DROP TABLE IF EXISTS `sh_notification_log`;
CREATE TABLE `sh_notification_log` (
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

-- 39. 员工考勤打卡流水表
DROP TABLE IF EXISTS `sh_attendance_record`;
CREATE TABLE `sh_attendance_record` (
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

-- 40. 岗位招聘与求职简历投递表
DROP TABLE IF EXISTS `sh_job_application`;
CREATE TABLE `sh_job_application` (
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

SET FOREIGN_KEY_CHECKS = 1;
