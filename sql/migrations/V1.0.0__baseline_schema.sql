-- ==========================================================
-- 海马 (Seahorse) ➔ 海马智慧门店 数据库全量结构脚本
-- Slogan: “海马会员，记住每位好客。”
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
  `address` varchar(255) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `business_hours` varchar(64) DEFAULT NULL,
  `fee_name` varchar(64) DEFAULT '造型毛巾费',
  `default_fee_amount` decimal(10,2) DEFAULT '10.00',
  `fee_enabled` tinyint(1) DEFAULT '1',
  `status` varchar(32) DEFAULT 'ACTIVE',
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
  `store_id` varchar(64) NOT NULL,
  `username` varchar(64) NOT NULL,
  `password` varchar(255) NOT NULL,
  `real_name` varchar(64) NOT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `role` varchar(32) NOT NULL COMMENT 'PLATFORM_DEVELOPER | SUPER_ADMIN | STORE_MANAGER | CASHIER | TECHNICIAN | WAITER',
  `default_commission_rate` decimal(5,4) DEFAULT '0.1500',
  `status` varchar(32) DEFAULT 'ACTIVE',
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
  `trial_expire_date` date DEFAULT NULL COMMENT '试用期到期日(默认3天试用)',
  `is_trial` tinyint(1) DEFAULT '1' COMMENT '是否处于权益试用期',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_no` (`member_no`),
  UNIQUE KEY `uk_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会员主体表';

-- 14. 双轨储值资金账户表
DROP TABLE IF EXISTS `sh_dual_balance_account`;
CREATE TABLE `sh_dual_balance_account` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `member_id` bigint NOT NULL,
  `tenant_id` varchar(64) NOT NULL,
  `principal_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '本金余额',
  `gift_balance` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '赠送金余额',
  `total_recharged` decimal(10,2) DEFAULT '0.00',
  `total_gift_granted` decimal(10,2) DEFAULT '0.00',
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
  `storage_quota_gb` int NOT NULL DEFAULT '50' COMMENT '云存储配额GB',
  `start_date` date NOT NULL,
  `expire_date` date NOT NULL,
  `fee_paid` decimal(10,2) DEFAULT '0.00',
  `status` varchar(32) DEFAULT 'ACTIVE' COMMENT 'ACTIVE | EXPIRING | EXPIRED',
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

-- 23. SaaS 会员套餐版本与定价/试用期配置表 (开发商端可动态配置价格与试用天数)
DROP TABLE IF EXISTS `sh_subscription_plan_config`;
CREATE TABLE `sh_subscription_plan_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `plan_code` varchar(32) NOT NULL COMMENT 'TRIAL | PROFESSIONAL | FLAGSHIP | ENTERPRISE',
  `plan_name` varchar(64) NOT NULL COMMENT '套餐显示名称',
  `annual_price` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT '会员套餐价格/年',
  `trial_days` int NOT NULL DEFAULT '3' COMMENT '免费试用期天数(支持3天、可修改为7天等)',
  `store_limit` int NOT NULL DEFAULT '1' COMMENT '允许开店上限',
  `storage_quota_gb` int NOT NULL DEFAULT '5' COMMENT '存储空间GB',
  `features` varchar(500) DEFAULT NULL COMMENT '功能特性与适用描述',
  `is_default` tinyint(1) DEFAULT '0' COMMENT '是否为新注册默认选中套餐',
  `status` varchar(32) DEFAULT 'ACTIVE' COMMENT 'ACTIVE | DISABLED',
  `sort_order` int DEFAULT '0',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_plan_code` (`plan_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SaaS会员套餐版本与定价配置表';


SET FOREIGN_KEY_CHECKS = 1;
