package com.seahorse.store.infrastructure.init;

import com.seahorse.store.domain.common.constant.CommonConstants;
import com.seahorse.store.domain.iam.enums.EmployeeRole;
import com.seahorse.store.domain.iam.model.Employee;
import com.seahorse.store.infrastructure.repository.EmployeeRepository;
import com.seahorse.store.infrastructure.repository.IndustryCategoryRepository;
import com.seahorse.store.infrastructure.repository.MemberCardTemplateRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Component
@org.springframework.context.annotation.Profile("dev")
@RequiredArgsConstructor
public class DataInitializer implements ApplicationRunner {

    private final EmployeeRepository employeeRepository;
    private final IndustryCategoryRepository industryCategoryRepository;
    private final MemberCardTemplateRepository memberCardTemplateRepository;
    private final PasswordEncoder passwordEncoder;
    private final org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void run(ApplicationArguments args) {
        try {
            jdbcTemplate.execute("ALTER TABLE sh_employee MODIFY COLUMN store_id VARCHAR(64) NULL");
        } catch (Exception e) {
            log.warn("Modify sh_employee.store_id nullable: {}", e.getMessage());
        }
        initIndustryCategories();
        initMemberCardTemplates();
        // 确保超级管理员账号 (admin / 123456) 存在且具备最高平台管理权限
        employeeRepository.findByUsername("admin").ifPresentOrElse(a -> {
            a.setRole(EmployeeRole.PLATFORM_DEVELOPER);
            a.setTenantId("PLATFORM");
            a.setStoreId("PLATFORM");
            a.setRealName("系统开发维护人");
            employeeRepository.save(a);
        }, () -> {
            Employee admin = Employee.builder()
                    .tenantId("PLATFORM").storeId("PLATFORM").username("admin")
                    .password(passwordEncoder.encode("123456")).realName("系统开发维护人")
                    .phone("13800000001").role(EmployeeRole.PLATFORM_DEVELOPER)
                    .defaultCommissionRate(BigDecimal.ZERO).status(CommonConstants.STATUS_ACTIVE)
                    .build();
            employeeRepository.save(admin);
        });

        log.info("【海马智慧门店】系统启动：超级管理员与底层配置已就绪，系统保持纯净空数据库状态，等待租户从0注册。");
    }

    private void initIndustryCategories() {
        if (industryCategoryRepository.count() > 0) {
            return;
        }
        List<com.seahorse.store.domain.iam.model.IndustryCategoryConfig> list = Arrays.asList(
                // 服务类
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(1, "汽车服务", "服务类", "AUTO", 1),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(6, "美业服务", "服务类", "BEAUTY", 2),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(7, "保健按摩", "服务类", "BEAUTY", 3),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(8, "休闲娱乐", "服务类", "RESTAURANT", 4),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(9, "运动健身", "服务类", "BEAUTY", 5),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(10, "教育培训", "服务类", "RETAIL", 6),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(11, "儿童乐园", "服务类", "RESTAURANT", 7),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(12, "宠物服务", "服务类", "BEAUTY", 8),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(13, "棋牌娱乐", "服务类", "RESTAURANT", 9),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(14, "洗衣擦鞋", "服务类", "BEAUTY", 10),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(15, "其他行业", "服务类", "BEAUTY", 11),
                // 零售类
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(16, "美妆店", "零售类", "RETAIL", 12),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(17, "鞋服店", "零售类", "RETAIL", 13),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(18, "便利店", "零售类", "RETAIL", 14),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(19, "烟酒店", "零售类", "RETAIL", 15),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(20, "茶叶店", "零售类", "RETAIL", 16),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(21, "餐饮店", "零售类", "RESTAURANT", 17),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(22, "孕婴店", "零售类", "RETAIL", 18),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(23, "果蔬店", "零售类", "RETAIL", 19),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(24, "熟食店", "零售类", "RESTAURANT", 20),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(25, "冷饮店", "零售类", "RESTAURANT", 21),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(26, "花店", "零售类", "RETAIL", 22),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(27, "书店", "零售类", "RETAIL", 23),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(28, "药店", "零售类", "RETAIL", 24),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(29, "蛋糕面包", "零售类", "RESTAURANT", 25),
                new com.seahorse.store.domain.iam.model.IndustryCategoryConfig(30, "其他行业", "零售类", "RETAIL", 26)
        );
        industryCategoryRepository.saveAll(list);
        log.info("【行业分类】系统服务类与零售类26项细分行业分类初始化完成。");
    }

    private void initMemberCardTemplates() {
        if (memberCardTemplateRepository.count() > 0) {
            // 清理旧数据中的【演示】字样
            List<com.seahorse.store.domain.member.model.MemberCardTemplate> existing = memberCardTemplateRepository.findAll();
            for (com.seahorse.store.domain.member.model.MemberCardTemplate c : existing) {
                boolean changed = false;
                if (c.getCardName() != null && c.getCardName().contains("【演示】")) {
                    c.setCardName(c.getCardName().replace("【演示】", ""));
                    changed = true;
                }
                if (c.getContentDescription() != null && c.getContentDescription().contains("【演示】")) {
                    c.setContentDescription(c.getContentDescription().replace("【演示】", ""));
                    changed = true;
                }
                if (c.getServiceSkuName() != null && c.getServiceSkuName().contains("【演示】")) {
                    c.setServiceSkuName(c.getServiceSkuName().replace("【演示】", ""));
                    changed = true;
                }
                if (changed) {
                    memberCardTemplateRepository.save(c);
                }
            }
            return;
        }
        List<com.seahorse.store.domain.member.model.MemberCardTemplate> cards = Arrays.asList(
                com.seahorse.store.domain.member.model.MemberCardTemplate.builder()
                        .tenantId("T001").storeId("S001")
                        .cardType("STORED_VALUE").cardTypeName("储值卡")
                        .cardName("300元8折轻奢储值卡")
                        .price(new BigDecimal("300.00")).originalPrice(new BigDecimal("300.00"))
                        .contentDescription("可用金额:300.00")
                        .principalAmount(new BigDecimal("300.00")).giftAmount(BigDecimal.ZERO)
                        .discountRate(new BigDecimal("0.80"))
                        .validityDays(0).status("ACTIVE").sortOrder(1)
                        .notes("开卡即享全场消费8折优惠")
                        .build(),
                com.seahorse.store.domain.member.model.MemberCardTemplate.builder()
                        .tenantId("T001").storeId("S001")
                        .cardType("STORED_VALUE").cardTypeName("储值卡")
                        .cardName("充300送100超值储值卡")
                        .price(new BigDecimal("300.00")).originalPrice(new BigDecimal("400.00"))
                        .contentDescription("可用金额:400.00")
                        .principalAmount(new BigDecimal("300.00")).giftAmount(new BigDecimal("100.00"))
                        .discountRate(new BigDecimal("1.00"))
                        .validityDays(0).status("ACTIVE").sortOrder(2)
                        .notes("本金300元 + 赠送金100元，双轨比例扣减")
                        .build(),
                com.seahorse.store.domain.member.model.MemberCardTemplate.builder()
                        .tenantId("T001").storeId("S001")
                        .cardType("TIME_CARD").cardTypeName("次卡")
                        .cardName("200元10次精细洗车卡")
                        .price(new BigDecimal("200.00")).originalPrice(new BigDecimal("350.00"))
                        .contentDescription("包含项目/服务次数: 精细洗车 × 10")
                        .totalTimes(10).serviceSkuName("精细洗车")
                        .validityDays(365).status("ACTIVE").sortOrder(3)
                        .notes("标准精细洗车服务10次，一年内有效")
                        .build(),
                com.seahorse.store.domain.member.model.MemberCardTemplate.builder()
                        .tenantId("T001").storeId("S001")
                        .cardType("DURATION_CARD").cardTypeName("时长卡")
                        .cardName("599元无限次美业尊享月卡")
                        .price(new BigDecimal("599.00")).originalPrice(new BigDecimal("1200.00"))
                        .contentDescription("30天内无限次洗吹造型与头皮护理")
                        .validityDays(30).status("ACTIVE").sortOrder(4)
                        .notes("一个月内无限次进店体验基础造型")
                        .build(),
                com.seahorse.store.domain.member.model.MemberCardTemplate.builder()
                        .tenantId("T001").storeId("S001")
                        .cardType("INDEPENDENT_STORED_CARD").cardTypeName("独立储值卡")
                        .cardName("500元精油SPA专项储值卡")
                        .price(new BigDecimal("500.00")).originalPrice(new BigDecimal("500.00"))
                        .contentDescription("专用于精油SPA与耗材直冲")
                        .principalAmount(new BigDecimal("500.00")).giftAmount(BigDecimal.ZERO)
                        .validityDays(0).status("ACTIVE").sortOrder(5)
                        .notes("专项产品原料专款专用")
                        .build(),
                com.seahorse.store.domain.member.model.MemberCardTemplate.builder()
                        .tenantId("T001").storeId("S001")
                        .cardType("BLIND_BOX_CARD").cardTypeName("盲盒卡")
                        .cardName("99元尊享服务盲盒体验卡")
                        .price(new BigDecimal("99.00")).originalPrice(new BigDecimal("298.00"))
                        .contentDescription("随机抽取深层养护或尊享礼包")
                        .validityDays(90).status("ACTIVE").sortOrder(6)
                        .notes("开卡随机抽取精喜项目")
                        .build(),
                com.seahorse.store.domain.member.model.MemberCardTemplate.builder()
                        .tenantId("T001").storeId("S001")
                        .cardType("BENEFIT_CARD").cardTypeName("权益卡")
                        .cardName("199元黑金年费专属特权卡")
                        .price(new BigDecimal("199.00")).originalPrice(new BigDecimal("680.00"))
                        .contentDescription("全场消费享85折特权+专属车位/包厢优先预约")
                        .discountRate(new BigDecimal("0.85"))
                        .validityDays(365).status("ACTIVE").sortOrder(7)
                        .notes("尊享VIP年费特权与预约通道")
                        .build()
        );
        memberCardTemplateRepository.saveAll(cards);
        log.info("【会员卡设置】真实会员卡项模板初始化完成，共初始化 7 张卡项。");
    }
}
