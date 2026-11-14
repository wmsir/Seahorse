-- ==========================================================
-- 海马 (Seahorse) ➔ 海马智慧门店 初始种子数据脚本
-- Slogan: “海马会员，记住每位好客。”
-- ==========================================================

USE `seahorse_store`;

-- 1. 租户与门店
INSERT INTO `sh_tenant` (`id`, `tenant_id`, `tenant_name`, `contact_name`, `contact_phone`, `status`)
VALUES (1, 'T001', '海马智慧商业连锁管理集团', '陈总', '13800000000', 'ACTIVE')
ON DUPLICATE KEY UPDATE `tenant_name` = VALUES(`tenant_name`);

INSERT INTO `sh_store` (`id`, `tenant_id`, `store_id`, `store_name`, `industry`, `address`, `phone`, `business_hours`, `fee_name`, `default_fee_amount`, `fee_enabled`, `status`)
VALUES (1, 'T001', 'S001', '海马智慧门店 (旗舰体验中心)', 'BEAUTY', '深圳市南山区粤海街道海马智慧园区A座1层', '0755-88889999', '09:30 - 22:00', '造型毛巾消毒费', 10.00, 1, 'ACTIVE')
ON DUPLICATE KEY UPDATE `store_name` = VALUES(`store_name`);

-- 2. 员工账号 (默认密码: 123456 -> BCrypt hash)
INSERT INTO `sh_employee` (`id`, `tenant_id`, `store_id`, `username`, `password`, `real_name`, `phone`, `role`, `default_commission_rate`, `status`)
VALUES 
(1, 'T001', 'S001', 'admin', '$2a$10$Fuj3oPehgF0lxl0nborbV.5xFkcaBRy0EDSSxwkXTSUfXbsJ/dZyK', '老板/总管理员', '13800000001', 'SUPER_ADMIN', 0.0000, 'ACTIVE'),
(2, 'T001', 'S001', 'manager', '$2a$10$Fuj3oPehgF0lxl0nborbV.5xFkcaBRy0EDSSxwkXTSUfXbsJ/dZyK', '李店长', '13800000002', 'STORE_MANAGER', 0.0500, 'ACTIVE'),
(3, 'T001', 'S001', 'cashier', '$2a$10$Fuj3oPehgF0lxl0nborbV.5xFkcaBRy0EDSSxwkXTSUfXbsJ/dZyK', '小美前台收银', '13800000003', 'CASHIER', 0.0200, 'ACTIVE'),
(4, 'T001', 'S001', 'tony', '$2a$10$Fuj3oPehgF0lxl0nborbV.5xFkcaBRy0EDSSxwkXTSUfXbsJ/dZyK', '托尼发型总监', '13800000004', 'TECHNICIAN', 0.2500, 'ACTIVE'),
(5, 'T001', 'S001', 'kevin', '$2a$10$Fuj3oPehgF0lxl0nborbV.5xFkcaBRy0EDSSxwkXTSUfXbsJ/dZyK', '凯文机修大工', '13800000005', 'TECHNICIAN', 0.2000, 'ACTIVE')
ON DUPLICATE KEY UPDATE `real_name` = VALUES(`real_name`);

-- 3. 空间工位与桌台
INSERT INTO `sh_service_space` (`id`, `tenant_id`, `store_id`, `space_code`, `space_name`, `space_type`, `status`, `capacity`, `floor_zone`)
VALUES 
(1, 'T001', 'S001', 'M01', '1号精剪镜台', 'MIRROR', 'IDLE', 1, '美业大厅'),
(2, 'T001', 'S001', 'M02', '2号造型镜台', 'MIRROR', 'IDLE', 1, '美业大厅'),
(3, 'T001', 'S001', 'M03', 'VIP尊享美容理疗套间', 'ROOM', 'IDLE', 2, '二楼VIP'),
(4, 'T001', 'S001', 'T01', '餐饮大厅A01散台', 'TABLE', 'IDLE', 4, '轻食餐厅区'),
(5, 'T001', 'S001', 'BAY01', '1号快修举升机工位', 'BAY', 'IDLE', 1, '汽修车间')
ON DUPLICATE KEY UPDATE `space_name` = VALUES(`space_name`);

-- 4. 商品与服务分类
INSERT INTO `sh_product_category` (`id`, `tenant_id`, `name`, `industry`, `sort_order`, `is_available`)
VALUES 
(1, 'T001', '美发设计与头皮理疗', 'BEAUTY', 1, 1),
(2, 'T001', '汽车快修保养与检测', 'AUTO', 2, 1),
(3, 'T001', '养生潮汕牛肉锅', 'RESTAURANT', 3, 1),
(4, 'T001', '专业沙龙耗材原料', 'GENERAL', 4, 1)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 5. 原料耗材与服务商品
INSERT INTO `sh_product` (`id`, `tenant_id`, `store_id`, `product_code`, `name`, `category_id`, `category_name`, `product_type`, `price`, `cost_price`, `stock`, `unit`, `duration_minutes`, `default_commission`, `description`, `is_available`)
VALUES 
(1, 'T001', 'S001', 'MAT01', '欧莱雅沙龙级精油染烫膏', 4, '专业沙龙耗材原料', 'MATERIAL', 80.00, 35.00, 120, '支', 0, 0.00, '专业沙龙院线装', 1),
(2, 'T001', 'S001', 'MAT02', '大马士革玫瑰头皮精油', 4, '专业沙龙耗材原料', 'MATERIAL', 60.00, 20.00, 85, '瓶', 0, 0.00, '天然纯植物萃取', 1),
(3, 'T001', 'S001', 'MAT03', '美孚1号全合成机油 0W-20', 4, '专业沙龙耗材原料', 'MATERIAL', 98.00, 50.00, 60, '升', 0, 0.00, '原厂正品国六标准', 1),
(4, 'T001', 'S001', 'SRV01', '总监定制洗剪吹设计', 1, '美发设计与头皮理疗', 'SERVICE', 88.00, 0.00, NULL, '次', 45, 26.40, '总监级一对一发型精修与定制', 1),
(5, 'T001', 'S001', 'SRV02', '欧莱雅丝柔烫染护理全套', 1, '美发设计与头皮理疗', 'SERVICE', 480.00, 35.00, NULL, '次', 120, 120.00, '含全头深层护理与欧莱雅专业烫染', 1),
(6, 'T001', 'S001', 'SRV03', '玫瑰精油头皮深层SPA理疗', 1, '美发设计与头皮理疗', 'SERVICE', 220.00, 20.00, NULL, '次', 60, 44.00, '深层去屑舒缓，促进微循环', 1),
(7, 'T001', 'S001', 'SRV04', '汽车全合成小保养工时套包', 2, '汽车快修保养与检测', 'SERVICE', 398.00, 235.00, NULL, '台', 50, 79.60, '含全车36项安全排查与工时', 1),
(8, 'T001', 'S001', 'FOD01', '秘制养生潮汕牛肉锅', 3, '养生潮汕牛肉锅', 'PHYSICAL', 108.00, 45.00, 999, '份', 0, 0.00, '现熬牛骨汤底，鲜切牛肉', 1)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 6. BOM 耗材配方消耗
INSERT INTO `sh_product_bom` (`id`, `service_product_id`, `material_product_id`, `material_name`, `consume_quantity`, `unit`)
VALUES 
(1, 5, 1, '欧莱雅沙龙级精油染烫膏', 1.00, '支'),
(2, 6, 2, '大马士革玫瑰头皮精油', 1.00, '瓶'),
(3, 7, 3, '美孚1号全合成机油 0W-20', 4.00, '升')
ON DUPLICATE KEY UPDATE `material_name` = VALUES(`material_name`);

-- 7. 会员主体
INSERT INTO `sh_member` (`id`, `tenant_id`, `member_no`, `name`, `phone`, `gender`, `birthday`, `level`, `total_spent`, `visit_count`, `last_visit_time`, `status`)
VALUES 
(1, 'T001', 'HM880001', '林清雅', '13800138001', 'FEMALE', '1995-06-18', 'DIAMOND', 3680.00, 12, NOW(), 'ACTIVE'),
(2, 'T001', 'HM880002', '张浩然', '13900139002', 'MALE', '1990-11-24', 'GOLD', 1280.00, 5, NOW(), 'ACTIVE')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- 8. 双轨储值账户
INSERT INTO `sh_dual_balance_account` (`id`, `member_id`, `tenant_id`, `principal_balance`, `gift_balance`, `total_recharged`, `total_gift_granted`)
VALUES 
(1, 1, 'T001', 1800.00, 350.00, 3000.00, 600.00),
(2, 2, 'T001', 650.00, 120.00, 1000.00, 200.00)
ON DUPLICATE KEY UPDATE `principal_balance` = VALUES(`principal_balance`);

-- 9. 计量服务次卡
INSERT INTO `sh_time_card_bucket` (`id`, `member_id`, `tenant_id`, `sku_id`, `sku_name`, `total_times`, `remaining_times`, `expire_date`, `status`)
VALUES 
(1, 1, 'T001', 6, '玫瑰精油头皮深层SPA理疗', 10, 7, DATE_ADD(CURDATE(), INTERVAL 8 MONTH), 'ACTIVE'),
(2, 2, 'T001', 4, '总监定制洗剪吹设计', 5, 3, DATE_ADD(CURDATE(), INTERVAL 6 MONTH), 'ACTIVE')
ON DUPLICATE KEY UPDATE `sku_name` = VALUES(`sku_name`);

-- 10. “海马体”记忆标签档案
INSERT INTO `sh_member_preference` (`id`, `member_id`, `tenant_id`, `category`, `tag_key`, `tag_value`, `notes`, `updated_by`)
VALUES 
(1, 1, 'T001', 'BEAUTY_HAIR', 'hair_texture', '细软自然卷发质，喜好蓬松轻盈剪法，不喜用发胶', '发质档案', '托尼总监'),
(2, 1, 'T001', 'BEAUTY_HAIR', 'preferred_stylist', '指定发型总监 托尼 (非必要不安排其他发型师)', '专属技师', '托尼总监'),
(3, 1, 'T001', 'RESTAURANT_TASTE', 'taste_notes', '喜好微辣、免葱蒜、常喝温柠檬水，喜欢靠窗静音座位', '餐饮偏好', '李店长'),
(4, 1, 'T001', 'AUTO_VEHICLE', 'vehicle_profile', '粤B66888 奔驰C260L 2023款 (偏好原厂0W-20，要求每次检查胎压)', '爱车档案', '凯文技师')
ON DUPLICATE KEY UPDATE `tag_value` = VALUES(`tag_value`);
