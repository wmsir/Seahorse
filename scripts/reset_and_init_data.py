import os
# -*- coding: utf-8 -*-
import sys
import datetime
import pymysql

sys.stdout.reconfigure(encoding='utf-8')

conn = pymysql.connect(
    host=os.environ.get('SEAHORSE_DB_HOST', '127.0.0.1'),
    port=3306,
    user='root',
    password=os.environ.get('SEAHORSE_DB_PASSWORD', ''),
    database='seahorse_store',
    charset='utf8mb4'
)

now = datetime.datetime.now()

with conn.cursor() as cursor:
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
    
    # 1. 清空所有测试数据表
    tables_to_clean = [
        'sh_billing_order',
        'sh_payment_record',
        'sh_cash_tender_record',
        'sh_commission_record',
        'sh_session_line_item',
        'sh_service_session',
        'sh_appointment',
        'sh_time_card_bucket',
        'sh_member_preference',
        'sh_dual_balance_account',
        'sh_member',
        'sh_service_space',
        'sh_product_bom',
        'sh_product',
        'sh_store',
        'sh_tenant',
        'sh_amap_config',
        'sh_shift_record'
    ]
    for t in tables_to_clean:
        try:
            cursor.execute(f"TRUNCATE TABLE {t};")
            print(f"Truncated table: {t}")
        except Exception as e:
            print(f"Error truncating {t}: {e}")
            cursor.execute(f"DELETE FROM {t};")

    # 2. 插入 2 个独立租户
    cursor.execute("""
        INSERT INTO sh_tenant (id, tenant_id, tenant_name, contact_name, contact_phone, deduct_mode, status, created_at, updated_at)
        VALUES 
        (1, 'T001', '海马体智慧生活连锁', '王店长', '13800000001', 'PROPORTIONAL', 'ACTIVE', %s, %s),
        (2, 'T002', '悦澜养生健康会所', '陈总监', '13500000002', 'PRINCIPAL_FIRST', 'ACTIVE', %s, %s);
    """, (now, now, now, now))
    print("Inserted 2 tenants.")

    # 3. 插入对应门店
    cursor.execute("""
        INSERT INTO sh_store (id, tenant_id, store_id, store_name, industry, address, phone, business_hours, fee_name, default_fee_amount, fee_enabled, status, created_at, updated_at)
        VALUES 
        (1, 'T001', 'S001', '海马体智慧生活 (西安高新旗舰店)', 'BEAUTY', '陕西省西安市高新区高新路海马商业中心1号店', '029-88889999', '09:00 - 22:30', '包厢茶位费', 10.00, 1, 'ACTIVE', %s, %s),
        (2, 'T002', 'S002', '悦澜养生健康会所 (广州天河总店)', 'FOOT_SPA', '广州市天河区天河路208号天河城4楼', '020-88881111', '10:00 - 23:00', '草本茶水费', 15.00, 1, 'ACTIVE', %s, %s);
    """, (now, now, now, now))
    print("Inserted 2 stores.")

    # 4. 插入高德地图配置 (用户提供的专属配置: Key=216aceb246ab68fbd8abb38f6cb24582, 安全密钥=a959cdbdf4b90d3ce9d3552521c0d0b9)
    cursor.execute("""
        INSERT INTO sh_amap_config (id, tenant_id, store_id, web_api_key, js_api_key, security_code, allowed_radius_meters, store_longitude, store_latitude, store_name, store_address, updated_at)
        VALUES 
        (1, 'T001', 'S001', '216aceb246ab68fbd8abb38f6cb24582', '216aceb246ab68fbd8abb38f6cb24582', 'a959cdbdf4b90d3ce9d3552521c0d0b9', 500, 108.953400, 34.265500, '海马体智慧生活 (西安高新旗舰店)', '陕西省西安市高新区高新路海马商业中心1号店', %s),
        (2, 'T002', 'S002', '216aceb246ab68fbd8abb38f6cb24582', '216aceb246ab68fbd8abb38f6cb24582', 'a959cdbdf4b90d3ce9d3552521c0d0b9', 500, 113.324520, 23.134230, '悦澜养生健康会所 (广州天河总店)', '广州市天河区天河路208号天河城4楼', %s);
    """, (now, now))
    print("Inserted AMap configs for both tenants.")

    # 5. 插入租户1包厢/工位
    cursor.execute("""
        INSERT INTO sh_service_space (id, tenant_id, store_id, space_code, space_name, space_type, status, capacity, floor_zone, hourly_fee, min_consume_amount, facilities, notes, sort_order, created_at, updated_at)
        VALUES 
        (1, 'T001', 'S001', 'VIP-01', '天权尊荣包厢', 'ROOM', 'IDLE', 4, '一楼养生区', 120.00, 200.00, '独立卫浴,恒温SPA床,香薰系统', '主打尊享SPA推拿', 1, %s, %s),
        (2, 'T001', 'S001', 'VIP-02', '玉衡养生包厢', 'ROOM', 'IDLE', 2, '一楼养生区', 100.00, 150.00, '恒温SPA床,蓝牙音箱', '适合双人同行', 2, %s, %s),
        (3, 'T001', 'S001', 'ST-01', '开阳美业工位', 'STATION', 'IDLE', 1, '二楼造型区', 50.00, 0.00, '多功能理发椅,冲水床', '发型设计专属工位', 3, %s, %s),
        (4, 'T001', 'S001', 'ST-02', '摇光美发工位', 'STATION', 'IDLE', 1, '二楼造型区', 50.00, 0.00, '多功能理发椅,戴森吹风机', '剪发造型工位', 4, %s, %s);
    """, (now, now, now, now, now, now, now, now))

    # 插入租户2包厢
    cursor.execute("""
        INSERT INTO sh_service_space (id, tenant_id, store_id, space_code, space_name, space_type, status, capacity, floor_zone, hourly_fee, min_consume_amount, facilities, notes, sort_order, created_at, updated_at)
        VALUES 
        (5, 'T002', 'S002', 'YL-01', '映月阁中式禅意养生房', 'ROOM', 'IDLE', 2, '东区VIP区', 150.00, 260.00, '禅意茶台,恒温按摩榻,独立沐浴', '高端商务静养', 1, %s, %s),
        (6, 'T002', 'S002', 'YL-02', '听泉阁泰式SPA贵宾房', 'ROOM', 'IDLE', 2, '东区VIP区', 160.00, 300.00, '泰式草本熏蒸舱,原木大床', '泰式精油专用', 2, %s, %s),
        (7, 'T002', 'S002', 'YL-03', '望舒阁古法足道大厅', 'ROOM', 'IDLE', 4, '西区足道区', 80.00, 100.00, '电动多档足道沙发,极光投屏', '休闲足道放松', 3, %s, %s);
    """, (now, now, now, now, now, now))
    print("Inserted service spaces.")

    # 6. 插入商品与服务项目
    # 租户1商品
    cursor.execute("""
        INSERT INTO sh_product (id, tenant_id, store_id, product_code, name, category_name, product_type, price, cost_price, stock, unit, duration_minutes, is_available, created_at, updated_at)
        VALUES 
        (1, 'T001', 'S001', '6901001', '经典经络推拿SPA', '服务项目', 'SERVICE', 198.00, 30.00, 999, '次', 60, 1, %s, %s),
        (2, 'T001', 'S001', '6901002', '芳香精油肩颈护理', '服务项目', 'SERVICE', 158.00, 25.00, 999, '次', 45, 1, %s, %s),
        (3, 'T001', 'S001', '6901003', '极光轻奢造型剪发', '服务项目', 'SERVICE', 98.00, 10.00, 999, '次', 30, 1, %s, %s),
        (4, 'T001', 'S001', '6901004', '特级明前龙井茶礼盒', '名茶实物', 'PHYSICAL', 168.00, 60.00, 50, '盒', 0, 1, %s, %s),
        (5, 'T001', 'S001', '6901005', '舒缓薰衣草精油', '护理用品', 'PHYSICAL', 68.00, 18.00, 100, '瓶', 0, 1, %s, %s),
        (6, 'T001', 'S001', '6901006', '冷萃乌龙茶(500ml)', '酒水饮料', 'PHYSICAL', 25.00, 8.00, 80, '瓶', 0, 1, %s, %s);
    """, (now, now, now, now, now, now, now, now, now, now, now, now))

    # 租户2商品
    cursor.execute("""
        INSERT INTO sh_product (id, tenant_id, store_id, product_code, name, category_name, product_type, price, cost_price, stock, unit, duration_minutes, is_available, created_at, updated_at)
        VALUES 
        (7, 'T002', 'S002', '6902001', '泰式古法草本芳疗SPA', '养生服务', 'SERVICE', 268.00, 40.00, 999, '次', 90, 1, %s, %s),
        (8, 'T002', 'S002', '6902002', '沉香草本古法足道', '养生服务', 'SERVICE', 158.00, 20.00, 999, '次', 60, 1, %s, %s),
        (9, 'T002', 'S002', '6902003', '艾灸温阳通络调理', '养生服务', 'SERVICE', 188.00, 28.00, 999, '次', 50, 1, %s, %s),
        (10, 'T002', 'S002', '6902004', '特级武夷山大红袍茶礼', '茶饮商品', 'PHYSICAL', 188.00, 70.00, 40, '盒', 0, 1, %s, %s),
        (11, 'T002', 'S002', '6902005', '泰国原产草本热敷包', '养生辅品', 'PHYSICAL', 88.00, 22.00, 80, '包', 0, 1, %s, %s);
    """, (now, now, now, now, now, now, now, now, now, now))
    print("Inserted products for both tenants.")

    # 7. 插入真实会员（租户1 与 租户2 彻底隔离）
    # 租户1 会员 (HM880001, HM880002, HM880003)
    cursor.execute("""
        INSERT INTO sh_member (id, tenant_id, member_no, name, phone, gender, level, total_spent, visit_count, status, points, is_trial, created_at, updated_at)
        VALUES 
        (1, 'T001', 'HM880001', '张建国', '13800138001', 'MALE', 'DIAMOND', 1580.00, 3, 'ACTIVE', 1200, 0, %s, %s),
        (2, 'T001', 'HM880002', '李芳', '13900139002', 'FEMALE', 'GOLD', 890.00, 2, 'ACTIVE', 600, 0, %s, %s),
        (3, 'T001', 'HM880003', '王磊', '13700137003', 'MALE', 'REGULAR', 298.00, 1, 'ACTIVE', 150, 0, %s, %s);
    """, (now, now, now, now, now, now))

    # 租户1 双轨储值账户
    cursor.execute("""
        INSERT INTO sh_dual_balance_account (id, member_id, tenant_id, principal_balance, gift_balance, total_recharged, total_gift_granted, deduct_mode, created_at, updated_at)
        VALUES 
        (1, 1, 'T001', 4000.00, 1000.00, 4000.00, 1000.00, 'PROPORTIONAL', %s, %s),
        (2, 2, 'T001', 1800.00, 200.00, 1800.00, 200.00, 'PROPORTIONAL', %s, %s),
        (3, 3, 'T001', 500.00, 0.00, 500.00, 0.00, 'PROPORTIONAL', %s, %s);
    """, (now, now, now, now, now, now))

    # 租户2 会员 (YL660001, YL660002, YL660003)
    cursor.execute("""
        INSERT INTO sh_member (id, tenant_id, member_no, name, phone, gender, level, total_spent, visit_count, status, points, is_trial, created_at, updated_at)
        VALUES 
        (4, 'T002', 'YL660001', '陈伟强', '13500135001', 'MALE', 'DIAMOND', 3280.00, 5, 'ACTIVE', 2500, 0, %s, %s),
        (5, 'T002', 'YL660002', '周晓敏', '13600136002', 'FEMALE', 'SILVER', 680.00, 2, 'ACTIVE', 350, 0, %s, %s),
        (6, 'T002', 'YL660003', '赵志远', '13300133003', 'MALE', 'REGULAR', 158.00, 1, 'ACTIVE', 80, 0, %s, %s);
    """, (now, now, now, now, now, now))

    # 租户2 双轨储值账户
    cursor.execute("""
        INSERT INTO sh_dual_balance_account (id, member_id, tenant_id, principal_balance, gift_balance, total_recharged, total_gift_granted, deduct_mode, created_at, updated_at)
        VALUES 
        (4, 4, 'T002', 7000.00, 1800.00, 7000.00, 1800.00, 'PRINCIPAL_FIRST', %s, %s),
        (5, 5, 'T002', 1000.00, 200.00, 1000.00, 200.00, 'PRINCIPAL_FIRST', %s, %s),
        (6, 6, 'T002', 300.00, 0.00, 300.00, 0.00, 'PRINCIPAL_FIRST', %s, %s);
    """, (now, now, now, now, now, now))
    print("Inserted members and dual balance accounts for both tenants.")

    # 8. 插入会员次卡
    cursor.execute("""
        INSERT INTO sh_time_card_bucket (id, member_id, tenant_id, sku_id, sku_name, total_times, remaining_times, expire_date, status, created_at, updated_at)
        VALUES 
        (1, 1, 'T001', 1, '经典经络推拿SPA次卡', 10, 8, '2027-12-31', 'ACTIVE', %s, %s),
        (2, 4, 'T002', 7, '泰式古法草本芳疗SPA次卡', 10, 9, '2027-12-31', 'ACTIVE', %s, %s);
    """, (now, now, now, now))
    print("Inserted time cards.")

    # 9. 插入海马体记忆档案
    cursor.execute("""
        INSERT INTO sh_member_preference (id, member_id, tenant_id, category, tag_key, tag_value, notes, updated_by, created_at, updated_at)
        VALUES 
        (1, 1, 'T001', 'HABIT', 'room_pref', '喜欢靠窗通风包厢，习惯饮用常温明前龙井', '老顾客偏好', '王店长', %s, %s),
        (2, 4, 'T002', 'HABIT', 'aroma_pref', '喜好泰国柠檬草精油香薰，力度要求中度', '熟客偏好', '陈总监', %s, %s);
    """, (now, now, now, now))
    print("Inserted member preferences.")

    # 10. 插入真实测试预约
    cursor.execute("""
        INSERT INTO sh_appointment (id, tenant_id, store_id, apt_no, customer_name, phone, people_count, service_name, service_price, apt_date, apt_time, status, staff_name, space_code, space_name, notes, created_at, updated_at)
        VALUES 
        (1, 'T001', 'S001', 'APT20260915001', '李芳', '13900139002', 1, '芳香精油肩颈护理', 158.00, '2026-09-15', '14:30', 'PENDING', '8号金牌技师(王琳)', 'VIP-02', '玉衡养生包厢', '老顾客预约，请提前准备精油', %s, %s),
        (2, 'T002', 'S002', 'APT20260915002', '周晓敏', '13600136002', 1, '泰式古法草本芳疗SPA', 268.00, '2026-09-15', '16:00', 'PENDING', '6号泰式技师(阿敏)', 'YL-02', '听泉阁泰式SPA贵宾房', '草本熏蒸预热', %s, %s);
    """, (now, now, now, now))
    print("Inserted test appointments.")

    cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")
    conn.commit()

conn.close()
print("All clean test data initialized successfully!")
