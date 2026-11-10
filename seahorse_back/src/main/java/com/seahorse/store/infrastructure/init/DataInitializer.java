package com.seahorse.store.infrastructure.init;

import com.seahorse.store.domain.common.constant.CommonConstants;
import com.seahorse.store.domain.iam.enums.EmployeeRole;
import com.seahorse.store.domain.iam.enums.IndustryType;
import com.seahorse.store.domain.iam.model.Employee;
import com.seahorse.store.domain.iam.model.StaffRewardPunish;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.iam.model.Tenant;
import com.seahorse.store.domain.member.enums.MemberLevel;
import com.seahorse.store.domain.member.model.DualBalanceAccount;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.member.model.MemberPreference;
import com.seahorse.store.domain.member.model.TimeCardBucket;
import com.seahorse.store.domain.product.enums.ProductType;
import com.seahorse.store.domain.product.model.Product;
import com.seahorse.store.domain.product.model.ProductBom;
import com.seahorse.store.domain.product.model.ProductCategory;
import com.seahorse.store.domain.session.enums.SpaceStatus;
import com.seahorse.store.domain.session.enums.SpaceType;
import com.seahorse.store.domain.session.model.ServiceSpace;
import com.seahorse.store.domain.iam.enums.SubscriptionBillingType;
import com.seahorse.store.domain.iam.enums.SubscriptionPlan;
import com.seahorse.store.domain.iam.model.SubscriptionBillingRecord;
import com.seahorse.store.domain.iam.model.TenantSubscription;
import com.seahorse.store.domain.member.enums.DeductMode;
import com.seahorse.store.infrastructure.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Component
@org.springframework.context.annotation.Profile("dev")
@RequiredArgsConstructor
public class DataInitializer implements ApplicationRunner {

    private final TenantRepository tenantRepository;
    private final StoreRepository storeRepository;
    private final EmployeeRepository employeeRepository;
    private final ServiceSpaceRepository spaceRepository;
    private final ProductCategoryRepository categoryRepository;
    private final ProductRepository productRepository;
    private final ProductBomRepository bomRepository;
    private final MemberRepository memberRepository;
    private final DualBalanceAccountRepository dualBalanceAccountRepository;
    private final TimeCardBucketRepository timeCardBucketRepository;
    private final MemberPreferenceRepository memberPreferenceRepository;
    private final TenantSubscriptionRepository subscriptionRepository;
    private final SubscriptionBillingRecordRepository billingRecordRepository;
    private final IndustryCategoryRepository industryCategoryRepository;
    private final MemberCardTemplateRepository memberCardTemplateRepository;
    private final StaffRewardPunishRepository staffRewardPunishRepository;
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

    private void initDemoStaffAndMembers() {
        // 1. 初始化美业门店真实员工：“李博”与“张建华”
        employeeRepository.findByUsername("lisi_demo").ifPresentOrElse(e -> {
            e.setPostName("资深发型师");
            e.setRealName("李博");
            e.setPhone("13800138002");
            e.setIsDeleted(false);
            employeeRepository.save(e);
        }, () -> {
            Employee lisi = Employee.builder()
                    .tenantId("T001").storeId("S001").username("lisi_demo")
                    .password(passwordEncoder.encode("123456")).realName("李博")
                    .phone("13800138002").postName("资深发型师").role(EmployeeRole.TECHNICIAN)
                    .defaultCommissionRate(BigDecimal.valueOf(0.25)).baseSalary(BigDecimal.valueOf(5000.00))
                    .gender("MALE").isDeleted(false).status(CommonConstants.STATUS_ACTIVE)
                    .build();
            employeeRepository.save(lisi);
        });

        employeeRepository.findByUsername("zhangsan_demo").ifPresentOrElse(e -> {
            e.setPostName("发型助理");
            e.setRealName("张建华");
            e.setPhone("13800138003");
            e.setIsDeleted(false);
            employeeRepository.save(e);
        }, () -> {
            Employee zhangsan = Employee.builder()
                    .tenantId("T001").storeId("S001").username("zhangsan_demo")
                    .password(passwordEncoder.encode("123456")).realName("张建华")
                    .phone("13800138003").postName("发型助理").role(EmployeeRole.TECHNICIAN)
                    .defaultCommissionRate(BigDecimal.valueOf(0.10)).baseSalary(BigDecimal.valueOf(3500.00))
                    .gender("MALE").isDeleted(false).status(CommonConstants.STATUS_ACTIVE)
                    .build();
            employeeRepository.save(zhangsan);
        });

        // 同步已有基础员工的岗位名称与未删除状态
        employeeRepository.findByUsername("manager").ifPresent(m -> {
            m.setPostName("店长");
            m.setIsDeleted(false);
            employeeRepository.save(m);
        });
        employeeRepository.findByUsername("cashier").ifPresent(c -> {
            c.setPostName("前台收银员");
            c.setIsDeleted(false);
            employeeRepository.save(c);
        });
        employeeRepository.findByUsername("tony").ifPresent(t -> {
            t.setPostName("发型总监");
            t.setIsDeleted(false);
            employeeRepository.save(t);
        });
        employeeRepository.findByUsername("kevin").ifPresent(k -> {
            k.setPostName("高级技师");
            k.setIsDeleted(false);
            employeeRepository.save(k);
        });

        // 兼职多店授权技师：陈明强 (13966668888)
        employeeRepository.findByUsername("13966668888").ifPresentOrElse(cmq -> {
            cmq.setPassword(passwordEncoder.encode("123456"));
            cmq.setRealName("陈明强");
            cmq.setPhone("13966668888");
            cmq.setPostName("高级发型造型顾问");
            cmq.setIsDeleted(false);
            cmq.setStatus(CommonConstants.STATUS_ACTIVE);
            employeeRepository.save(cmq);
        }, () -> {
            Employee cmq = Employee.builder()
                    .tenantId("T001").storeId("S001").username("13966668888")
                    .password(passwordEncoder.encode("123456")).realName("陈明强")
                    .phone("13966668888").postName("高级发型造型顾问").role(EmployeeRole.TECHNICIAN)
                    .defaultCommissionRate(BigDecimal.valueOf(0.25)).baseSalary(BigDecimal.valueOf(4500.00))
                    .gender("MALE").isDeleted(false).status(CommonConstants.STATUS_ACTIVE)
                    .build();
            employeeRepository.save(cmq);
        });

        // 2. 初始化真实会员：“李清雅”
        memberRepository.findByPhone("13800138000").ifPresentOrElse(m -> {
            if ("李女士【演示】".equals(m.getName()) || m.getName() == null) {
                m.setName("李清雅");
            }
            if (m.getCardNo() == null) {
                m.setCardNo("202405010001");
                m.setCardPasswordEnabled(false);
                m.setCardSignEnabled(false);
                m.setDiscountName("暂无等级");
                m.setReferrerName("请选择推荐人");
                m.setBirthdayType("SOLAR");
                m.setRewardAmount(BigDecimal.ZERO);
                m.setPoints(100);
                m.setDebtAmount(BigDecimal.ZERO);
                m.setWechatBound(false);
                m.setCardOpenCount(2);
                memberRepository.save(m);
            }
        }, () -> {
            Member lims = Member.builder()
                    .tenantId("T001").memberNo("HM880006").name("李清雅").phone("13800138000")
                    .gender("FEMALE").birthday(LocalDate.of(2000, 1, 1)).level(MemberLevel.REGULAR)
                    .cardNo("202405010001").cardPasswordEnabled(false).cardSignEnabled(false)
                    .discountName("暂无等级").referrerName("请选择推荐人").birthdayType("SOLAR")
                    .rewardAmount(BigDecimal.ZERO).points(100).totalSpent(BigDecimal.valueOf(1680.00))
                    .cardOpenCount(2).debtAmount(BigDecimal.ZERO).wechatBound(false).visitCount(5)
                    .notes("老客户，偏好自然系造型与头皮养护")
                    .status(CommonConstants.STATUS_ACTIVE)
                    .build();
            Member savedMember = memberRepository.save(lims);

            DualBalanceAccount acc = DualBalanceAccount.builder()
                    .memberId(savedMember.getId()).tenantId("T001")
                    .principalBalance(BigDecimal.valueOf(800.00)).giftBalance(BigDecimal.valueOf(150.00))
                    .totalRecharged(BigDecimal.valueOf(1000.00)).totalGiftGranted(BigDecimal.valueOf(200.00))
                    .build();
            dualBalanceAccountRepository.save(acc);
        });

        // 3. 初始真实业务奖罚记录
        if (staffRewardPunishRepository.count() == 0) {
            StaffRewardPunish rp1 = StaffRewardPunish.builder()
                    .tenantId("T001").employeeId(1L).employeeName("李博")
                    .type("REWARD").amount(BigDecimal.valueOf(200.00))
                    .reason("月度技能大赛一等奖卓越表现奖励")
                    .recordDate(LocalDate.now().minusDays(3))
                    .operator("店长")
                    .build();
            StaffRewardPunish rp2 = StaffRewardPunish.builder()
                    .tenantId("T001").employeeId(2L).employeeName("张建华")
                    .type("REWARD").amount(BigDecimal.valueOf(100.00))
                    .reason("本月全勤与客户好评奖励")
                    .recordDate(LocalDate.now().minusDays(1))
                    .operator("店长")
                    .build();
            staffRewardPunishRepository.saveAll(Arrays.asList(rp1, rp2));
        }
    }

    private void syncSelfConsistentIndustryProducts() {
        // 1. 确保零售商户 T004 与 零售门店 S006 存在
        tenantRepository.findByTenantId("T004").ifPresentOrElse(t -> {}, () -> {
            Tenant t4 = Tenant.builder()
                    .tenantId("T004")
                    .tenantName("云缦甄选商业连锁集团")
                    .contactName("周海峰")
                    .contactPhone("13988771122")
                    .deductMode(DeductMode.PROPORTIONAL)
                    .status(CommonConstants.STATUS_ACTIVE)
                    .build();
            tenantRepository.save(t4);
        });

        subscriptionRepository.findByTenantId("T004").ifPresentOrElse(s -> {}, () -> {
            TenantSubscription sub4 = TenantSubscription.builder()
                    .tenantId("T004")
                    .plan(SubscriptionPlan.PROFESSIONAL)
                    .storeLimit(3)
                    .storageQuotaGb(50)
                    .startDate(LocalDate.now().minusDays(10))
                    .expireDate(LocalDate.now().plusMonths(11).plusDays(20))
                    .feePaid(BigDecimal.valueOf(2980.00))
                    .status(CommonConstants.STATUS_ACTIVE)
                    .autoRenew(true)
                    .notes("云缦甄选专营零售商户官方订阅")
                    .build();
            subscriptionRepository.save(sub4);
        });

        storeRepository.findByStoreId("S006").ifPresentOrElse(s -> {}, () -> {
            Store s6 = Store.builder()
                    .tenantId("T001")
                    .storeId("S006")
                    .storeName("云缦甄选·现代轻奢生活美学馆 (正佳广场店)")
                    .industry(IndustryType.RETAIL)
                    .address("广州市天河区天河路228号正佳广场3楼中庭3A018")
                    .phone("020-88996611")
                    .businessHours("10:00 - 22:00")
                    .feeName("精美包装与礼盒费")
                    .defaultFeeAmount(BigDecimal.valueOf(15.00))
                    .feeEnabled(true)
                    .status(CommonConstants.STATUS_ACTIVE)
                    .build();
            storeRepository.save(s6);
        });

        // 2. 检查并创建零售商品分类
        List<ProductCategory> existingCategories = categoryRepository.findAll();
        ProductCategory cRetail = existingCategories.stream()
                .filter(c -> "RETAIL".equalsIgnoreCase(c.getIndustry()) || (c.getName() != null && (c.getName().contains("零售") || c.getName().contains("百货"))))
                .findFirst()
                .orElseGet(() -> categoryRepository.save(ProductCategory.builder()
                        .tenantId("T001").name("精品百货与轻奢生活").industry("RETAIL").sortOrder(5).available(true).build()));

        // 3. 规范纠正已有产品门店归属，彻底消除跨行业混部污染
        List<Product> allProducts = productRepository.findAll();
        for (Product p : allProducts) {
            String n = p.getName() != null ? p.getName() : "";
            if (n.contains("洗剪吹") || n.contains("烫染") || n.contains("发型") || n.contains("头皮") || n.contains("发膜") || n.contains("染发")) {
                if (!"S001".equals(p.getStoreId())) {
                    p.setStoreId("S001");
                    productRepository.save(p);
                }
            } else if (n.contains("牛肉") || n.contains("和牛") || n.contains("牛肋排") || n.contains("沙拉") || n.contains("餐饮") || n.contains("火锅")) {
                if (!"S002".equals(p.getStoreId())) {
                    p.setStoreId("S002");
                    productRepository.save(p);
                }
            } else if (n.contains("机油") || n.contains("保养") || n.contains("洗车") || n.contains("四轮定位") || n.contains("刹车油") || n.contains("汽修")) {
                if (!"S003".equals(p.getStoreId())) {
                    p.setStoreId("S003");
                    productRepository.save(p);
                }
            } else if (n.contains("咖啡") || n.contains("香薰") || n.contains("品茗杯") || n.contains("白毫银针") || n.contains("黑巧") || n.contains("零售")) {
                if (!"S006".equals(p.getStoreId())) {
                    p.setStoreId("S006");
                    productRepository.save(p);
                }
            }
        }

        // 4. 确保零售代表商品入库 (S006 与 T001)
        if (productRepository.findByProductCode("RET01").isEmpty()) {
            Product ret1 = Product.builder()
                    .tenantId("T001").storeId("S006").productCode("RET01").name("埃塞俄比亚耶加雪菲日晒精品原装咖啡豆 500g")
                    .categoryId(cRetail.getId()).categoryName("精品咖啡茗茶").productType(ProductType.PHYSICAL)
                    .price(BigDecimal.valueOf(168.00)).costPrice(BigDecimal.valueOf(78.00)).stock(50).unit("包")
                    .available(true).description("500g 充氮锁鲜，日晒处理法花果香")
                    .build();
            productRepository.save(ret1);
        }
        if (productRepository.findByProductCode("RET02").isEmpty()) {
            Product ret2 = Product.builder()
                    .tenantId("T001").storeId("S006").productCode("RET02").name("沙龙小众冷杉雪松木质调无火香薰礼盒")
                    .categoryId(cRetail.getId()).categoryName("家居生活美学").productType(ProductType.PHYSICAL)
                    .price(BigDecimal.valueOf(298.00)).costPrice(BigDecimal.valueOf(120.00)).stock(35).unit("套")
                    .available(true).description("200ml 法式小众冷杉雪松调无火藤条香薰")
                    .build();
            productRepository.save(ret2);
        }
        if (productRepository.findByProductCode("RET03").isEmpty()) {
            Product ret3 = Product.builder()
                    .tenantId("T001").storeId("S006").productCode("RET03").name("北欧极简手作耐热双层玻璃品茗杯")
                    .categoryId(cRetail.getId()).categoryName("工艺器皿生活").productType(ProductType.PHYSICAL)
                    .price(BigDecimal.valueOf(128.00)).costPrice(BigDecimal.valueOf(45.00)).stock(28).unit("对")
                    .available(true).description("高硼硅耐热手作双层玻璃品茗杯双只礼盒装")
                    .build();
            productRepository.save(ret3);
        }
    }
}
