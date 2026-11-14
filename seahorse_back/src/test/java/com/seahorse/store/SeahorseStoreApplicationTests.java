package com.seahorse.store;

import com.seahorse.store.application.dto.billing.BillingSummaryVO;
import com.seahorse.store.application.dto.billing.CheckoutCommand;
import com.seahorse.store.application.dto.member.MemberProfileVO;
import com.seahorse.store.application.dto.session.AppendItemsCommand;
import com.seahorse.store.application.dto.session.OpenSessionCommand;
import com.seahorse.store.application.dto.session.SessionDetailVO;
import com.seahorse.store.application.service.BillingCheckoutAppService;
import com.seahorse.store.application.service.MemberAssetAppService;
import com.seahorse.store.application.service.ServiceSessionAppService;
import com.seahorse.store.domain.billing.enums.BillingStatus;
import com.seahorse.store.domain.billing.enums.PaymentChannel;
import com.seahorse.store.domain.billing.model.BillingOrder;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.product.model.Product;
import com.seahorse.store.domain.session.enums.SessionStatus;
import com.seahorse.store.domain.session.model.ServiceSession;
import com.seahorse.store.domain.session.model.ServiceSpace;
import com.seahorse.store.infrastructure.repository.MemberRepository;
import com.seahorse.store.infrastructure.repository.ProductRepository;
import com.seahorse.store.infrastructure.repository.ServiceSpaceRepository;
import jakarta.persistence.Column;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import jakarta.persistence.metamodel.EntityType;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@SpringBootTest
@ActiveProfiles("dev")
public class SeahorseStoreApplicationTests {

    @Autowired
    private ServiceSessionAppService sessionAppService;

    @Autowired
    private BillingCheckoutAppService checkoutAppService;

    @Autowired
    private MemberAssetAppService memberAssetAppService;

    @Autowired
    private ServiceSpaceRepository spaceRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private MemberRepository memberRepository;

    @Autowired
    private com.seahorse.store.infrastructure.repository.TenantRepository tenantRepository;

    @Autowired
    private com.seahorse.store.infrastructure.repository.StoreRepository storeRepository;

    @Autowired
    private com.seahorse.store.infrastructure.repository.DualBalanceAccountRepository dualBalanceAccountRepository;

    @Autowired
    private com.seahorse.store.infrastructure.repository.MemberPreferenceRepository memberPreferenceRepository;

    @Autowired
    private com.seahorse.store.infrastructure.repository.ProductBomRepository productBomRepository;

    @Autowired
    private EntityManagerFactory entityManagerFactory;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private com.fasterxml.jackson.databind.ObjectMapper objectMapper;

    @Autowired
    private com.seahorse.store.infrastructure.repository.EmployeeRepository employeeRepository;

    @Autowired
    private com.seahorse.store.infrastructure.repository.AppointmentRepository appointmentRepository;

    @Autowired
    private com.seahorse.store.infrastructure.repository.AttendanceRecordRepository attendanceRecordRepository;

    @Autowired
    private com.seahorse.store.infrastructure.repository.JobApplicationRepository jobApplicationRepository;

    @Autowired
    private com.seahorse.store.interfaces.web.AuthController authController;

    @Autowired
    private com.seahorse.store.interfaces.web.AppointmentController appointmentController;

    @Autowired
    private com.seahorse.store.interfaces.web.AttendanceRecordController attendanceRecordController;

    @Autowired
    private com.seahorse.store.interfaces.web.JobApplicationController jobApplicationController;

    @BeforeEach
    public void setUpSeedFixtures() {
        com.seahorse.store.context.TenantContext.set(
                com.seahorse.store.context.TenantContext.TenantInfo.builder()
                        .userId(1L)
                        .username("manager")
                        .tenantId("T001")
                        .storeId("S001")
                        .role("STORE_MANAGER")
                        .industry("BEAUTY")
                        .authenticated(true)
                        .build()
        );

        if (tenantRepository.findByTenantId("T001").isEmpty()) {
            tenantRepository.save(com.seahorse.store.domain.iam.model.Tenant.builder()
                    .tenantId("T001")
                    .tenantName("海马智慧商业连锁管理集团")
                    .contactName("陈总")
                    .contactPhone("13800000000")
                    .deductMode(com.seahorse.store.domain.member.enums.DeductMode.PROPORTIONAL)
                    .status("ACTIVE")
                    .build());
        }

        if (storeRepository.findByStoreId("S001").isEmpty()) {
            storeRepository.save(com.seahorse.store.domain.iam.model.Store.builder()
                    .tenantId("T001")
                    .storeId("S001")
                    .storeName("海马智慧门店 (旗舰体验中心)")
                    .industry(com.seahorse.store.domain.iam.enums.IndustryType.BEAUTY)
                    .feeName("造型毛巾消毒费")
                    .defaultFeeAmount(BigDecimal.valueOf(10.00))
                    .feeEnabled(true)
                    .status("ACTIVE")
                    .build());
        }

        if (tenantSubscriptionRepository.findByTenantId("T001").isEmpty()) {
            tenantSubscriptionRepository.save(com.seahorse.store.domain.iam.model.TenantSubscription.builder()
                    .tenantId("T001")
                    .plan(com.seahorse.store.domain.iam.enums.SubscriptionPlan.PROFESSIONAL)
                    .storeLimit(3)
                    .staffLimit(10)
                    .storageQuotaGb(50)
                    .startDate(LocalDate.now().minusMonths(1))
                    .expireDate(LocalDate.now().plusMonths(11))
                    .feePaid(BigDecimal.valueOf(2980.00))
                    .status("ACTIVE")
                    .autoRenew(true)
                    .build());
        }

        if (spaceRepository.count() == 0) {
            spaceRepository.save(ServiceSpace.builder()
                    .tenantId("T001")
                    .storeId("S001")
                    .spaceCode("M01")
                    .spaceName("1号精剪镜台")
                    .spaceType(com.seahorse.store.domain.session.enums.SpaceType.MIRROR)
                    .status(com.seahorse.store.domain.session.enums.SpaceStatus.IDLE)
                    .capacity(1)
                    .floorZone("美业大厅")
                    .build());
        }

        if (productRepository.count() == 0) {
            Product mat = productRepository.save(Product.builder()
                    .tenantId("T001")
                    .storeId("S001")
                    .productCode("MAT01")
                    .name("沙龙专用护发精油")
                    .productType(com.seahorse.store.domain.product.enums.ProductType.MATERIAL)
                    .price(BigDecimal.valueOf(60.00))
                    .costPrice(BigDecimal.valueOf(20.00))
                    .stock(120)
                    .unit("支")
                    .durationMinutes(0)
                    .defaultCommission(BigDecimal.ZERO)
                    .available(true)
                    .build());
            Product srv = productRepository.save(Product.builder()
                    .tenantId("T001")
                    .storeId("S001")
                    .productCode("SRV01")
                    .name("总监定制洗剪吹设计")
                    .productType(com.seahorse.store.domain.product.enums.ProductType.SERVICE)
                    .price(BigDecimal.valueOf(88.00))
                    .costPrice(BigDecimal.ZERO)
                    .unit("次")
                    .durationMinutes(45)
                    .defaultCommission(BigDecimal.valueOf(26.40))
                    .available(true)
                    .build());
            productBomRepository.save(com.seahorse.store.domain.product.model.ProductBom.builder()
                    .serviceProductId(srv.getId())
                    .materialProductId(mat.getId())
                    .materialName(mat.getName())
                    .consumeQuantity(BigDecimal.ONE)
                    .unit("支")
                    .build());
        }

        if (memberRepository.findByPhone("13800138001").isEmpty()) {
            Member m1 = memberRepository.save(Member.builder()
                    .tenantId("T001")
                    .memberNo("HM880001")
                    .name("林清雅")
                    .phone("13800138001")
                    .gender("FEMALE")
                    .birthday(LocalDate.of(1995, 6, 18))
                    .level(com.seahorse.store.domain.member.enums.MemberLevel.DIAMOND)
                    .totalSpent(BigDecimal.valueOf(3680.00))
                    .visitCount(12)
                    .points(500)
                    .lastVisitTime(LocalDateTime.now())
                    .status("ACTIVE")
                    .build());
            dualBalanceAccountRepository.save(com.seahorse.store.domain.member.model.DualBalanceAccount.builder()
                    .memberId(m1.getId())
                    .tenantId("T001")
                    .principalBalance(BigDecimal.valueOf(1800.00))
                    .giftBalance(BigDecimal.valueOf(350.00))
                    .totalRecharged(BigDecimal.valueOf(3000.00))
                    .totalGiftGranted(BigDecimal.valueOf(600.00))
                    .deductMode(com.seahorse.store.domain.member.enums.DeductMode.PROPORTIONAL)
                    .build());
            memberPreferenceRepository.save(com.seahorse.store.domain.member.model.MemberPreference.builder()
                    .memberId(m1.getId())
                    .tenantId("T001")
                    .category("BEAUTY_HAIR")
                    .tagKey("hair_texture")
                    .tagValue("细软自然卷发质，喜好蓬松轻盈剪法")
                    .updatedBy("托尼总监")
                    .build());
        }
        if (memberRepository.findByPhone("13900139002").isEmpty()) {
            memberRepository.save(Member.builder()
                    .tenantId("T001")
                    .memberNo("HM880002")
                    .name("张浩然")
                    .phone("13900139002")
                    .gender("MALE")
                    .level(com.seahorse.store.domain.member.enums.MemberLevel.GOLD)
                    .totalSpent(BigDecimal.valueOf(1280.00))
                    .visitCount(5)
                    .status("ACTIVE")
                    .build());
        }
        if (memberRepository.findByPhone("13700137003").isEmpty()) {
            memberRepository.save(Member.builder()
                    .tenantId("T001")
                    .memberNo("HM880003")
                    .name("王芳")
                    .phone("13700137003")
                    .gender("FEMALE")
                    .level(com.seahorse.store.domain.member.enums.MemberLevel.SILVER)
                    .totalSpent(BigDecimal.valueOf(580.00))
                    .visitCount(3)
                    .status("ACTIVE")
                    .build());
        }
    }

    @AfterEach
    public void tearDownTenantContext() {
        com.seahorse.store.context.TenantContext.clear();
    }

    @Test
    @DisplayName("验证海马智慧门店核心会话与组合结账完整闭环")
    @Transactional(rollbackFor = Exception.class)
    public void testCompleteSessionAndCheckoutFlow() {
        // 1. 查询初始化空间与会员
        List<ServiceSpace> spaces = spaceRepository.findAll();
        Assertions.assertFalse(spaces.isEmpty(), "预置空间不应为空");
        ServiceSpace space = spaces.get(0);

        Member member = memberRepository.findByPhone("13800138001").orElseThrow();

        // 2. 空间开单 (openSession)
        OpenSessionCommand openCmd = OpenSessionCommand.builder()
                .spaceId(space.getId())
                .memberId(member.getId())
                .guestCount(1)
                .notes("测试开单")
                .build();

        ServiceSession session = sessionAppService.openSession(openCmd);
        Assertions.assertNotNull(session.getId());
        Assertions.assertEquals(SessionStatus.OCCUPIED_ORDERING, session.getStatus());

        // 3. 动态追加项目 (appendItems - 模拟美业总监理发与头皮护理)
        List<Product> products = productRepository.findAll();
        Product serviceProduct = products.stream()
                .filter(p -> p.getName().contains("洗剪吹"))
                .findFirst().orElseThrow();

        AppendItemsCommand.PerformerShareParam performer = AppendItemsCommand.PerformerShareParam.builder()
                .employeeId(4L) // 托尼总监
                .employeeName("托尼总监")
                .shareRatio(BigDecimal.ONE)
                .build();

        AppendItemsCommand.AppendItemParam itemParam = AppendItemsCommand.AppendItemParam.builder()
                .productId(serviceProduct.getId())
                .quantity(1)
                .modifiers("自然轻盈微卷，不打发胶")
                .performers(Collections.singletonList(performer))
                .build();

        AppendItemsCommand appendCmd = AppendItemsCommand.builder()
                .sessionId(session.getId())
                .items(Collections.singletonList(itemParam))
                .build();

        SessionDetailVO detailVo = sessionAppService.appendItems(appendCmd);
        Assertions.assertEquals(1, detailVo.getBatches().size());
        Assertions.assertEquals(1, detailVo.getLineItems().size());
        Assertions.assertTrue(detailVo.getSession().getPayableAmount().compareTo(BigDecimal.ZERO) > 0);

        // 4. 发起买单请求 (requestBilling)
        BillingOrder order = checkoutAppService.requestBilling(session.getId());
        Assertions.assertNotNull(order.getId());
        Assertions.assertEquals(BillingStatus.PENDING, order.getStatus());

        // 5. 组合支付结算 (50元储值卡 + 剩余微信支付)
        List<CheckoutCommand.PaymentSplitItem> splits = new ArrayList<>();

        CheckoutCommand.PaymentSplitItem splitStored = CheckoutCommand.PaymentSplitItem.builder()
                .channel(PaymentChannel.STORED_VALUE)
                .amount(BigDecimal.valueOf(50.00))
                .build();
        splits.add(splitStored);

        BigDecimal remaining = order.getActualAmount().subtract(BigDecimal.valueOf(50.00));
        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            CheckoutCommand.PaymentSplitItem splitWechat = CheckoutCommand.PaymentSplitItem.builder()
                    .channel(PaymentChannel.WECHAT)
                    .amount(remaining)
                    .build();
            splits.add(splitWechat);
        }

        CheckoutCommand checkoutCmd = CheckoutCommand.builder()
                .billingOrderId(order.getId())
                .splitItems(splits)
                .build();

        BillingSummaryVO summaryVo = checkoutAppService.executeCheckout(checkoutCmd);
        Assertions.assertEquals(BillingStatus.PAID, summaryVo.getOrder().getStatus());

        // 6. 验证“海马体”记忆档案与单次累计/不降级/一口价提成/单次BOM扣减
        MemberProfileVO profile = memberAssetAppService.getMemberProfile(member.getId());
        Assertions.assertNotNull(profile.getPreferences());
        Assertions.assertFalse(profile.getPreferences().isEmpty(), "海马体记忆档案标签数不应为空");
        Assertions.assertEquals(13, profile.getMember().getVisitCount(), "结账后会员到店频次应仅累加1次(12 -> 13)");
        Assertions.assertEquals(0, BigDecimal.valueOf(3680.00).add(order.getActualAmount()).compareTo(profile.getMember().getTotalSpent()),
                "结账后会员累计消费应仅按实收金额累加1次");
        Assertions.assertEquals(com.seahorse.store.domain.member.enums.MemberLevel.DIAMOND, profile.getMember().getLevel(),
                "高等级黑钻会员低积分时不应被错误降级");
        Long firstLineId = detailVo.getLineItems().get(0).getId();
        Assertions.assertEquals(0, BigDecimal.valueOf(26.40).compareTo(detailVo.getPerformersByItem().get(firstLineId).get(0).getCommissionAmount()),
                "大于1的固定提成金额配置应按单价提成而非放大为百倍比例");
        Product updatedMat = productRepository.findByProductCode("MAT01").orElseThrow();
        Assertions.assertEquals(119, updatedMat.getStock(), "服务关联BOM耗材应仅在结账时扣减1次(120 -> 119)");
        System.out.println("【测试验证成功】海马体记忆档案标签数: " + profile.getPreferences().size());
    }

    @Test
    @DisplayName("验证双轨储值扣减策略：同比例双轨扣减 vs 优先扣减本金")
    public void testDualBalanceDeductModes() {
        // 1. 测试 PROPORTIONAL (按本金/赠金比例扣减)
        // 充值 100 本金 + 50 赠金 = 150 总额 (本金占比 2/3, 赠金占比 1/3)
        com.seahorse.store.domain.member.model.DualBalanceAccount accountProp =
                com.seahorse.store.domain.member.model.DualBalanceAccount.builder()
                        .principalBalance(BigDecimal.valueOf(100.00))
                        .giftBalance(BigDecimal.valueOf(50.00))
                        .totalRecharged(BigDecimal.valueOf(100.00))
                        .totalGiftGranted(BigDecimal.valueOf(50.00))
                        .build();

        // 扣减 60 元: 本金扣 40 元, 赠金扣 20 元
        accountProp.deduct(BigDecimal.valueOf(60.00), com.seahorse.store.domain.member.enums.DeductMode.PROPORTIONAL);
        Assertions.assertEquals(0, BigDecimal.valueOf(60.00).compareTo(accountProp.getPrincipalBalance()));
        Assertions.assertEquals(0, BigDecimal.valueOf(30.00).compareTo(accountProp.getGiftBalance()));
        Assertions.assertEquals(0, BigDecimal.valueOf(90.00).compareTo(accountProp.getTotalBalance()));

        // 2. 测试 PRINCIPAL_FIRST (优先扣减实充本金)
        // 充值 100 本金 + 50 赠金 = 150 总额
        com.seahorse.store.domain.member.model.DualBalanceAccount accountFirst =
                com.seahorse.store.domain.member.model.DualBalanceAccount.builder()
                        .principalBalance(BigDecimal.valueOf(100.00))
                        .giftBalance(BigDecimal.valueOf(50.00))
                        .totalRecharged(BigDecimal.valueOf(100.00))
                        .totalGiftGranted(BigDecimal.valueOf(50.00))
                        .build();

        // 扣减 60 元: 优先从本金扣除 60 元, 赠金保持 50 元不变
        accountFirst.deduct(BigDecimal.valueOf(60.00), com.seahorse.store.domain.member.enums.DeductMode.PRINCIPAL_FIRST);
        Assertions.assertEquals(0, BigDecimal.valueOf(40.00).compareTo(accountFirst.getPrincipalBalance()));
        Assertions.assertEquals(0, BigDecimal.valueOf(50.00).compareTo(accountFirst.getGiftBalance()));
        Assertions.assertEquals(0, BigDecimal.valueOf(90.00).compareTo(accountFirst.getTotalBalance()));

        // 再次扣减 50 元: 本金剩余 40 元全部扣完，剩余 10 元从赠金扣除 (赠金变为 40 元)
        accountFirst.deduct(BigDecimal.valueOf(50.00), com.seahorse.store.domain.member.enums.DeductMode.PRINCIPAL_FIRST);
        Assertions.assertEquals(0, BigDecimal.ZERO.compareTo(accountFirst.getPrincipalBalance()));
        Assertions.assertEquals(0, BigDecimal.valueOf(40.00).compareTo(accountFirst.getGiftBalance()));
        Assertions.assertEquals(0, BigDecimal.valueOf(40.00).compareTo(accountFirst.getTotalBalance()));
    }

    @Autowired
    private com.seahorse.store.application.service.MerchantRegisterAppService registerAppService;

    @Autowired
    private com.seahorse.store.application.service.VendorOperationAppService vendorOperationAppService;

    @Test
    @DisplayName("验证商户自助注册开通、SaaS版本订阅管理与开发商费用统计看板")
    @Transactional(rollbackFor = Exception.class)
    public void testMerchantRegistrationAndVendorConsole() {
        // 1. 商户自助入驻注册 (选择专业版套餐 + 优先本金扣减 + 首家汽修门店)
        com.seahorse.store.application.dto.vendor.MerchantRegisterCommand regCmd =
                com.seahorse.store.application.dto.vendor.MerchantRegisterCommand.builder()
                        .tenantName("极速汽修动力连锁")
                        .adminUsername("speed_boss")
                        .adminPassword("123456")
                        .adminRealName("张总")
                        .contactPhone("13912345678")
                        .plan(com.seahorse.store.domain.iam.enums.SubscriptionPlan.PROFESSIONAL)
                        .deductMode(com.seahorse.store.domain.member.enums.DeductMode.PRINCIPAL_FIRST)
                        .initialStoreName("极速汽修总店")
                        .initialStoreIndustry(com.seahorse.store.domain.iam.enums.IndustryType.AUTO)
                        .build();

        com.seahorse.store.domain.iam.model.Tenant regTenant = registerAppService.registerMerchant(regCmd);

        Assertions.assertNotNull(regTenant.getTenantId());
        Assertions.assertEquals("极速汽修动力连锁", regTenant.getTenantName());
        Assertions.assertEquals(com.seahorse.store.domain.member.enums.DeductMode.PRINCIPAL_FIRST, regTenant.getDeductMode());

        // 2. 开发商总管录入该商户的存储服务费
        com.seahorse.store.application.dto.vendor.RecordStorageFeeCommand feeCmd =
                com.seahorse.store.application.dto.vendor.RecordStorageFeeCommand.builder()
                        .tenantId(regTenant.getTenantId())
                        .amount(BigDecimal.valueOf(480.00))
                        .storageGb(200)
                        .durationMonths(12)
                        .paymentMethod("ALIPAY")
                        .notes("年度200G数据存储扩容包")
                        .build();

        com.seahorse.store.domain.iam.model.SubscriptionBillingRecord feeRecord =
                vendorOperationAppService.recordStorageFee(feeCmd);
        Assertions.assertNotNull(feeRecord.getId());
        Assertions.assertEquals(com.seahorse.store.domain.iam.enums.SubscriptionBillingType.STORAGE_SERVICE, feeRecord.getBillingType());

        // 3. 开发商总管为该商户办理套餐续费
        com.seahorse.store.application.dto.vendor.RenewSubscriptionCommand renewCmd =
                com.seahorse.store.application.dto.vendor.RenewSubscriptionCommand.builder()
                        .tenantId(regTenant.getTenantId())
                        .targetPlan(com.seahorse.store.domain.iam.enums.SubscriptionPlan.FLAGSHIP)
                        .durationMonths(12)
                        .amount(BigDecimal.valueOf(4999.00))
                        .paymentMethod("BANK_TRANSFER")
                        .notes("升级为旗舰版套餐并续费1年")
                        .build();

        com.seahorse.store.domain.iam.model.TenantSubscription renewedSub =
                vendorOperationAppService.renewSubscription(renewCmd);
        Assertions.assertEquals(com.seahorse.store.domain.iam.enums.SubscriptionPlan.FLAGSHIP, renewedSub.getPlan());

        // 4. 获取开发商运营管控统计数据
        com.seahorse.store.interfaces.web.vo.VendorDashboardStatsVO stats =
                vendorOperationAppService.getVendorDashboardStats();
        Assertions.assertTrue(stats.getTotalTenants() >= 1);
        Assertions.assertTrue(stats.getTotalPlatformRevenue().compareTo(BigDecimal.ZERO) > 0);
        System.out.println("【测试验证成功】平台开发商总商户数: " + stats.getTotalTenants() + ", 累计营收: ¥" + stats.getTotalPlatformRevenue());
    }

    @Autowired
    private com.seahorse.store.infrastructure.repository.TenantSubscriptionRepository tenantSubscriptionRepository;

    @Test
    @DisplayName("验证新商户注册默认免费试用3天及到期日计算")
    @Transactional(rollbackFor = Exception.class)
    public void testNewMerchantDefaultTrial3Days() {
        // 新注册商户，默认体验版套餐 (TRIAL)
        com.seahorse.store.application.dto.vendor.MerchantRegisterCommand trialCmd =
                com.seahorse.store.application.dto.vendor.MerchantRegisterCommand.builder()
                        .tenantName("清风茶饮连锁测试")
                        .adminUsername("tea_boss")
                        .adminPassword("123456")
                        .adminRealName("李老板")
                        .contactPhone("13711112222")
                        .plan(com.seahorse.store.domain.iam.enums.SubscriptionPlan.TRIAL)
                        .initialStoreName("清风茶饮一号店")
                        .initialStoreIndustry(com.seahorse.store.domain.iam.enums.IndustryType.RESTAURANT)
                        .build();

        com.seahorse.store.domain.iam.model.Tenant tenant = registerAppService.registerMerchant(trialCmd);
        Assertions.assertNotNull(tenant.getTenantId());

        // 验证订阅合约
        com.seahorse.store.domain.iam.model.TenantSubscription sub =
                tenantSubscriptionRepository.findByTenantId(tenant.getTenantId()).orElseThrow();
        Assertions.assertEquals(com.seahorse.store.domain.iam.enums.SubscriptionPlan.TRIAL, sub.getPlan());
        Assertions.assertEquals(3, sub.getDaysRemaining(), "新商户默认试用天数应为3天");
        Assertions.assertEquals(java.time.LocalDate.now().plusDays(3), sub.getExpireDate());
        Assertions.assertEquals(0, BigDecimal.ZERO.compareTo(sub.getFeePaid()), "试用期费用应为0");
        System.out.println("【测试验证成功】新商户注册默认开通3天试用，剩余天数: " + sub.getDaysRemaining() + " 天，到期日: " + sub.getExpireDate());
    }

    @Test
    @DisplayName("验证新门店顾客会员注册默认开通3天权益试用期")
    @Transactional(rollbackFor = Exception.class)
    public void testNewStoreMemberDefaultTrial3Days() {
        com.seahorse.store.application.dto.member.MemberCommands.MemberRegisterCommand cmd =
                new com.seahorse.store.application.dto.member.MemberCommands.MemberRegisterCommand(
                        "苏婉儿", "13699998888", "FEMALE",
                        java.time.LocalDate.of(2000, 5, 20),
                        BigDecimal.ZERO, BigDecimal.ZERO
                );

        Member member = memberAssetAppService.registerMember(cmd);
        Assertions.assertNotNull(member.getId());
        Assertions.assertTrue(member.isTrialActive(), "新注册顾客会员应处于试用状态");
        Assertions.assertEquals(3, member.getTrialDaysRemaining(), "试用期剩余天数应为3天");
        Assertions.assertEquals(java.time.LocalDate.now().plusDays(3), member.getTrialExpireDate());

        MemberProfileVO profile = memberAssetAppService.getMemberProfile(member.getId());
        Assertions.assertTrue(profile.getIsTrial());
        Assertions.assertEquals(3, profile.getTrialDaysRemaining());
        System.out.println("【测试验证成功】新顾客会员注册默认开通3天权益试用，剩余: " + profile.getTrialDaysRemaining() + " 天");
    }

    @Autowired
    private com.seahorse.store.application.service.PlatformConfigAppService platformConfigAppService;

    @Test
    @DisplayName("验证页面动态修改试用期为7天以及动态调整SaaS套餐价格即时生效")
    @Transactional(rollbackFor = Exception.class)
    public void testDynamicTrialDaysAndPlanPricingConfiguration() {
        // 1. 将全系统试用期从 3 天动态调整为 7 天
        platformConfigAppService.updateTrialDays(7);
        Assertions.assertEquals(7, platformConfigAppService.getDefaultTrialDays(), "系统默认试用天数应被动态修改为7天");

        // 2. 动态调整旗舰版(FLAGSHIP)年费定价
        List<com.seahorse.store.interfaces.web.vo.SubscriptionPlanConfigVO> plans = platformConfigAppService.getAllPlanConfigs();
        com.seahorse.store.interfaces.web.vo.SubscriptionPlanConfigVO flagshipPlan = plans.stream()
                .filter(p -> p.getPlanCode() == com.seahorse.store.domain.iam.enums.SubscriptionPlan.FLAGSHIP)
                .findFirst().orElseThrow();

        com.seahorse.store.application.dto.vendor.UpdatePlanConfigCommand updateCmd =
                com.seahorse.store.application.dto.vendor.UpdatePlanConfigCommand.builder()
                        .planName("尊享旗舰版-年中大促")
                        .annualPrice(BigDecimal.valueOf(5999.00))
                        .trialDays(0)
                        .storeLimit(15)
                        .storageQuotaGb(100)
                        .features("支持15家门店连锁管理，100GB云存储，全行业模态")
                        .build();

        platformConfigAppService.updatePlanConfig(flagshipPlan.getId(), updateCmd);
        Assertions.assertEquals(0, BigDecimal.valueOf(5999.00).compareTo(
                platformConfigAppService.getPlanAnnualPrice(com.seahorse.store.domain.iam.enums.SubscriptionPlan.FLAGSHIP)
        ));

        // 3. 注册新商户(TRIAL)，验证到期日自动变为当前日期+7天
        com.seahorse.store.application.dto.vendor.MerchantRegisterCommand trialCmd =
                com.seahorse.store.application.dto.vendor.MerchantRegisterCommand.builder()
                        .tenantName("7天试用测试美业")
                        .adminUsername("seven_boss")
                        .adminPassword("123456")
                        .adminRealName("七天测试")
                        .contactPhone("13977778888")
                        .plan(com.seahorse.store.domain.iam.enums.SubscriptionPlan.TRIAL)
                        .initialStoreName("七天体验店")
                        .initialStoreIndustry(com.seahorse.store.domain.iam.enums.IndustryType.BEAUTY)
                        .build();

        com.seahorse.store.domain.iam.model.Tenant newTenant = registerAppService.registerMerchant(trialCmd);
        com.seahorse.store.domain.iam.model.TenantSubscription sub =
                tenantSubscriptionRepository.findByTenantId(newTenant.getTenantId()).orElseThrow();
        Assertions.assertEquals(7, sub.getDaysRemaining(), "新商户试用天数应按系统最新配置计算为7天");
        Assertions.assertEquals(java.time.LocalDate.now().plusDays(7), sub.getExpireDate());

        // 4. 注册新顾客会员，验证权益试用期也自动变为7天
        com.seahorse.store.application.dto.member.MemberCommands.MemberRegisterCommand memberCmd =
                new com.seahorse.store.application.dto.member.MemberCommands.MemberRegisterCommand(
                        "七天体验会员", "13700007777", "FEMALE",
                        java.time.LocalDate.of(1995, 7, 7),
                        BigDecimal.ZERO, BigDecimal.ZERO
                );
        Member member = memberAssetAppService.registerMember(memberCmd);
        Assertions.assertEquals(7, member.getTrialDaysRemaining(), "新顾客会员试用期应动态生效为7天");
        Assertions.assertEquals(java.time.LocalDate.now().plusDays(7), member.getTrialExpireDate());

        // 5. 注册新商户选择调整过价格的旗舰版，验证计费金额与最新配置完全一致
        com.seahorse.store.application.dto.vendor.MerchantRegisterCommand paidCmd =
                com.seahorse.store.application.dto.vendor.MerchantRegisterCommand.builder()
                        .tenantName("尊享旗舰美业集团")
                        .adminUsername("vip_boss")
                        .adminPassword("123456")
                        .adminRealName("王董事长")
                        .contactPhone("13999996666")
                        .plan(com.seahorse.store.domain.iam.enums.SubscriptionPlan.FLAGSHIP)
                        .initialStoreName("旗舰一号院")
                        .initialStoreIndustry(com.seahorse.store.domain.iam.enums.IndustryType.BEAUTY)
                        .build();

        com.seahorse.store.domain.iam.model.Tenant paidTenant = registerAppService.registerMerchant(paidCmd);
        com.seahorse.store.domain.iam.model.TenantSubscription paidSub =
                tenantSubscriptionRepository.findByTenantId(paidTenant.getTenantId()).orElseThrow();
        Assertions.assertEquals(0, BigDecimal.valueOf(5999.00).compareTo(paidSub.getFeePaid()), "商户应按最新调整的旗舰版价格 5999.00 入账");

        System.out.println("【测试验证成功】系统试用期成功从3天配置修改为7天，SaaS套餐价格从6800调整为5999并实时生效！");

        // 恢复默认 3 天
        platformConfigAppService.updateTrialDays(3);
    }

    @Autowired
    private com.seahorse.store.application.service.PermissionManageAppService permissionManageAppService;

    @Autowired
    private com.seahorse.store.application.service.MemberSelfAppService memberSelfAppService;

    @Test
    @DisplayName("验证三级角色与权限体系：开发商监控会员量/服务时长/全局权限，老板定制店员权限，会员自主修改信息与海马偏好")
    @Transactional(rollbackFor = Exception.class)
    public void testRolePermissionsAndMemberSelfService() {
        // 1. 系统开发维护人视角：验证获取全平台会员总量与商户购买服务时长
        com.seahorse.store.interfaces.web.vo.VendorDashboardStatsVO stats = vendorOperationAppService.getVendorDashboardStats();
        Assertions.assertNotNull(stats.getTotalMembers(), "全平台注册会员数量不应为空");
        Assertions.assertTrue(stats.getTotalMembers() >= 3, "初始种子数据至少包含3名注册会员");
        System.out.println("【测试验证成功-开发维护人】全平台注册会员总数: " + stats.getTotalMembers() + ", 注册商户数: " + stats.getTotalTenants());

        List<com.seahorse.store.interfaces.web.vo.VendorSubscriptionVO> subs = vendorOperationAppService.getTenantSubscriptions(null, null);
        Assertions.assertFalse(subs.isEmpty(), "商户订阅列表不应为空");
        com.seahorse.store.interfaces.web.vo.VendorSubscriptionVO sub1 = subs.get(0);
        Assertions.assertNotNull(sub1.getPurchasedDurationMonths(), "商户购买的服务时长(月)不应为空");
        Assertions.assertNotNull(sub1.getMemberCount(), "商户旗下会员数不应为空");
        System.out.println("【测试验证成功-开发维护人】商户 [" + sub1.getTenantName() + "] 购买服务时长: "
                + sub1.getPurchasedDurationMonths() + " 个月，到期日: " + sub1.getExpireDate() + "，剩余: " + sub1.getDaysRemaining() + " 天");

        // 2. 系统开发维护人视角：查看并配置全局角色默认权限
        List<com.seahorse.store.interfaces.web.vo.RolePermissionVO> platformRoles = permissionManageAppService.getPlatformRolePermissions();
        Assertions.assertEquals(6, platformRoles.size(), "全平台应初始化 6 大核心角色权限模板");

        com.seahorse.store.application.dto.iam.UpdateRolePermissionCommand devUpdateCmd =
                com.seahorse.store.application.dto.iam.UpdateRolePermissionCommand.builder()
                        .roleCode(com.seahorse.store.domain.iam.enums.EmployeeRole.CASHIER)
                        .permissions(java.util.Arrays.asList("session:view", "cashier:checkout", "member:list_view"))
                        .description("平台开发商下发的收银员标准权限")
                        .build();
        permissionManageAppService.updatePlatformRolePermission(com.seahorse.store.domain.iam.enums.EmployeeRole.CASHIER, devUpdateCmd);

        // 3. 会员门店老板视角：为本店定制店员权限（如为收银员新增录入海马记忆档案权限）
        String testTenantId = "T001";
        com.seahorse.store.application.dto.iam.UpdateRolePermissionCommand bossCustomCmd =
                com.seahorse.store.application.dto.iam.UpdateRolePermissionCommand.builder()
                        .roleCode(com.seahorse.store.domain.iam.enums.EmployeeRole.CASHIER)
                        .permissions(java.util.Arrays.asList("session:view", "cashier:checkout", "member:list_view", "member:pref_edit"))
                        .description("陈总为本店收银员特许开放海马档案录入权")
                        .build();
        permissionManageAppService.updateMerchantStaffPermission(testTenantId, com.seahorse.store.domain.iam.enums.EmployeeRole.CASHIER, bossCustomCmd);

        List<String> effectiveCashierPerms = permissionManageAppService.getEffectivePermissions(testTenantId, com.seahorse.store.domain.iam.enums.EmployeeRole.CASHIER);
        Assertions.assertTrue(effectiveCashierPerms.contains("member:pref_edit"), "门店老板定制的收银员海马记忆编辑权限应生效");

        // 4. 顾客会员自己视角：自主查看并修改个人信息
        Member member = memberRepository.findByPhone("13800138001").orElseThrow();
        com.seahorse.store.application.dto.member.MemberCommands.UpdateMemberProfileCommand updateProfileCmd =
                com.seahorse.store.application.dto.member.MemberCommands.UpdateMemberProfileCommand.builder()
                        .name("林清雅(VIP修改)")
                        .gender("FEMALE")
                        .birthday(java.time.LocalDate.of(1996, 8, 18))
                        .phone("13800138001")
                        .build();

        com.seahorse.store.application.dto.member.MemberProfileVO updatedProfile =
                memberSelfAppService.updateMyProfile(member.getId(), updateProfileCmd);
        Assertions.assertEquals("林清雅(VIP修改)", updatedProfile.getMember().getName(), "会员自主修改姓名应成功生效");
        Assertions.assertEquals(java.time.LocalDate.of(1996, 8, 18), updatedProfile.getMember().getBirthday(), "会员自主修改生日应成功生效");

        // 5. 顾客会员自己视角：自主添加/更新海马体个人偏好画像
        com.seahorse.store.application.dto.member.MemberCommands.SavePreferenceCommand prefCmd =
                com.seahorse.store.application.dto.member.MemberCommands.SavePreferenceCommand.builder()
                        .category("BEAUTY_HAIR")
                        .tagKey("favorite_color")
                        .tagValue("冷棕亚麻色，偏爱无氨植物染膏")
                        .notes("会员本人自主添加")
                        .build();
        com.seahorse.store.domain.member.model.MemberPreference pref =
                memberSelfAppService.saveMyPreference(member.getId(), prefCmd);
        Assertions.assertNotNull(pref.getId());
        Assertions.assertEquals("favorite_color", pref.getTagKey());

        System.out.println("【测试验证成功-会员自主中心】会员已成功自主更新资料: 姓名=" + updatedProfile.getMember().getName()
                + ", 偏好=" + pref.getTagValue());
    }

    @Test
    @DisplayName("验证 sql/schema.sql 与全部 JPA 实体表/字段 100% 对齐及 init_data.sql 密码哈希有效")
    public void testSqlSchemaAndInitDataParityAndBcrypt() throws Exception {
        Path schemaPath = Paths.get("..", "sql", "schema.sql").normalize();
        Path initDataPath = Paths.get("..", "sql", "init_data.sql").normalize();
        Assertions.assertTrue(Files.exists(schemaPath), "sql/schema.sql 应存在: " + schemaPath.toAbsolutePath());
        Assertions.assertTrue(Files.exists(initDataPath), "sql/init_data.sql 应存在: " + initDataPath.toAbsolutePath());

        String schemaSql = Files.readString(schemaPath, StandardCharsets.UTF_8);
        String initDataSql = Files.readString(initDataPath, StandardCharsets.UTF_8);

        String jdbcUrl = "jdbc:h2:mem:sql_parity_check;MODE=MySQL;DATABASE_TO_LOWER=TRUE;NON_KEYWORDS=VALUE,USER";
        try (Connection conn = DriverManager.getConnection(jdbcUrl, "sa", "")) {
            executeSqlScript(conn, schemaSql);

            Set<EntityType<?>> entities = entityManagerFactory.getMetamodel().getEntities();
            Assertions.assertFalse(entities.isEmpty());

            for (EntityType<?> entityType : entities) {
                Class<?> javaType = entityType.getJavaType();
                Table tableAnn = javaType.getAnnotation(Table.class);
                String tableName = (tableAnn != null && !tableAnn.name().isEmpty())
                        ? tableAnn.name().toLowerCase()
                        : camelToSnake(javaType.getSimpleName());

                Set<String> dbColumns = new HashSet<>();
                try (ResultSet rs = conn.getMetaData().getColumns(null, null, tableName, null)) {
                    while (rs.next()) {
                        dbColumns.add(rs.getString("COLUMN_NAME").toLowerCase());
                    }
                }
                Assertions.assertFalse(dbColumns.isEmpty(),
                        "sql/schema.sql 缺失 JPA 实体对应的表: " + tableName + " (" + javaType.getName() + ")");

                for (Field field : javaType.getDeclaredFields()) {
                    if (Modifier.isStatic(field.getModifiers())
                            || Modifier.isTransient(field.getModifiers())
                            || field.isAnnotationPresent(Transient.class)) {
                        continue;
                    }
                    Column colAnn = field.getAnnotation(Column.class);
                    String colName = (colAnn != null && !colAnn.name().isEmpty())
                            ? colAnn.name().toLowerCase()
                            : camelToSnake(field.getName());
                    Assertions.assertTrue(dbColumns.contains(colName),
                            "sql/schema.sql 表 " + tableName + " 缺失字段 " + colName + " (来自 " + javaType.getSimpleName() + "." + field.getName() + ")");
                }
            }

            try (ResultSet legacyTableRs = conn.getMetaData().getTables(null, null, "sh_shift_record", null)) {
                Assertions.assertFalse(legacyTableRs.next(), "已下线数据表不应存在于 sql/schema.sql");
            }

            executeSqlScript(conn, initDataSql);

            try (PreparedStatement ps = conn.prepareStatement("SELECT password FROM sh_employee WHERE username = ?")) {
                ps.setString(1, "admin");
                try (ResultSet rs = ps.executeQuery()) {
                    Assertions.assertTrue(rs.next(), "init_data.sql 应插入默认员工账号 admin");
                    String adminHash = rs.getString(1);
                    Assertions.assertTrue(passwordEncoder.matches("123456", adminHash),
                            "init_data.sql 中的员工 BCrypt 密码哈希必须能通过 123456 校验");
                }
            }
        }
    }

    @Test
    @DisplayName("验证多批次加单、银联UNION_PAY支付策略与¥0.00免单核销闭环")
    @Transactional(rollbackFor = Exception.class)
    public void testMultiBatchOrderingUnionPayAndZeroCompedCheckout() {
        ServiceSpace tableSpace = spaceRepository.save(ServiceSpace.builder()
                .tenantId("T001")
                .storeId("S001")
                .spaceCode("T88")
                .spaceName("餐饮景观卡座T88")
                .spaceType(com.seahorse.store.domain.session.enums.SpaceType.TABLE)
                .status(com.seahorse.store.domain.session.enums.SpaceStatus.IDLE)
                .capacity(4)
                .floorZone("餐饮区")
                .build());

        Product dish1 = productRepository.save(Product.builder()
                .tenantId("T001")
                .storeId("S001")
                .productCode("FOD88")
                .name("招牌潮汕吊龙")
                .productType(com.seahorse.store.domain.product.enums.ProductType.PHYSICAL)
                .price(BigDecimal.valueOf(68.00))
                .stock(50)
                .unit("盘")
                .available(true)
                .build());

        Product dish2 = productRepository.save(Product.builder()
                .tenantId("T001")
                .storeId("S001")
                .productCode("FOD89")
                .name("手打牛筋丸")
                .productType(com.seahorse.store.domain.product.enums.ProductType.PHYSICAL)
                .price(BigDecimal.valueOf(38.00))
                .stock(50)
                .unit("份")
                .available(true)
                .build());

        ServiceSession session = sessionAppService.openSession(OpenSessionCommand.builder()
                .spaceId(tableSpace.getId())
                .customerName("餐饮散客")
                .guestCount(3)
                .build());

        // 第 1 批次点单
        sessionAppService.appendItems(AppendItemsCommand.builder()
                .sessionId(session.getId())
                .items(Collections.singletonList(AppendItemsCommand.AppendItemParam.builder()
                        .productId(dish1.getId())
                        .quantity(2)
                        .modifiers("微辣")
                        .build()))
                .build());

        // 第 2 批次加菜
        SessionDetailVO afterSecondBatch = sessionAppService.appendItems(AppendItemsCommand.builder()
                .sessionId(session.getId())
                .items(Collections.singletonList(AppendItemsCommand.AppendItemParam.builder()
                        .productId(dish2.getId())
                        .quantity(1)
                        .modifiers("免葱")
                        .build()))
                .build());

        Assertions.assertEquals(2, afterSecondBatch.getBatches().size(), "多次加菜应生成2个批次记录");
        Assertions.assertEquals(2, afterSecondBatch.getLineItems().size(), "会话应包含2条有效菜品明细");

        BillingOrder unionOrder = checkoutAppService.requestBilling(session.getId());
        BillingSummaryVO unionSummary = checkoutAppService.executeCheckout(CheckoutCommand.builder()
                .billingOrderId(unionOrder.getId())
                .splitItems(Collections.singletonList(CheckoutCommand.PaymentSplitItem.builder()
                        .channel(PaymentChannel.UNION_PAY)
                        .amount(unionOrder.getActualAmount())
                        .build()))
                .build());

        Assertions.assertEquals(BillingStatus.PAID, unionSummary.getOrder().getStatus(), "银联UNION_PAY通道应成功完成结算");
        Assertions.assertEquals(1, unionSummary.getPaymentRecords().size());
        Assertions.assertTrue(unionSummary.getPaymentRecords().get(0).getTradeNo().startsWith("UP"), "银联流水号应以UP开头");

        // 验证 ¥0.00 全额免单核销闭环 (actualAmount = 0, 空 splitItems)
        BillingSummaryVO compedSummary = checkoutAppService.executeCheckout(CheckoutCommand.builder()
                .totalAmount(BigDecimal.valueOf(88.00))
                .discountAmount(BigDecimal.valueOf(88.00))
                .actualAmount(BigDecimal.ZERO)
                .customerName("店长特批免单体验客")
                .splitItems(Collections.emptyList())
                .build());

        Assertions.assertEquals(BillingStatus.PAID, compedSummary.getOrder().getStatus(), "¥0.00免单应直接标记为PAID");
        Assertions.assertEquals(0, BigDecimal.ZERO.compareTo(compedSummary.getOrder().getActualAmount()));
        Assertions.assertEquals(0, BigDecimal.ZERO.compareTo(compedSummary.getOrder().getPaidAmount()));
    }

    @Test
    @DisplayName("验证找回密码、会员卡密脱敏与跨租户同号、充值自动升级、预约区间与软取消、考勤招聘入库及越权拦截")
    @Transactional(rollbackFor = Exception.class)
    public void testPhase2SecurityForgotPasswordMemberMaskingUpgradeAppointmentAndDbPersistence() throws Exception {
        // 1. 找回密码公开接口闭环 (R-02)
        com.seahorse.store.domain.iam.model.Employee emp = employeeRepository.save(
                com.seahorse.store.domain.iam.model.Employee.builder()
                        .tenantId("T001")
                        .storeId("S001")
                        .username("reset_tester")
                        .password(passwordEncoder.encode("OldPass123"))
                        .realName("密码重置测试员")
                        .phone("13812349999")
                        .role(com.seahorse.store.domain.iam.enums.EmployeeRole.CASHIER)
                        .status("ACTIVE")
                        .build()
        );

        com.seahorse.store.interfaces.web.AuthController.SendResetCodeRequest sendReq =
                new com.seahorse.store.interfaces.web.AuthController.SendResetCodeRequest();
        sendReq.setAccount("13812349999");
        var codeResp = authController.sendResetCode(sendReq);
        Assertions.assertEquals(200, codeResp.getCode());
        String devCode = String.valueOf(codeResp.getData().get("devCode"));
        Assertions.assertEquals(6, devCode.length());

        com.seahorse.store.interfaces.web.AuthController.ResetPasswordByCodeRequest resetReq =
                new com.seahorse.store.interfaces.web.AuthController.ResetPasswordByCodeRequest();
        resetReq.setAccount("reset_tester");
        resetReq.setCode(devCode);
        resetReq.setNewPassword("NewPass888");
        var resetResp = authController.resetPasswordByCode(resetReq);
        Assertions.assertEquals(200, resetResp.getCode());

        com.seahorse.store.domain.iam.model.Employee reloadedEmp = employeeRepository.findById(emp.getId()).orElseThrow();
        Assertions.assertTrue(passwordEncoder.matches("NewPass888", reloadedEmp.getPassword()), "重置密码后BCrypt哈希应立即更新");

        // 2. 会员卡密 WRITE_ONLY 序列化脱敏 + 跨租户相同 memberNo 唯一性隔离 (R-03, R-08)
        Member m1 = memberRepository.findByPhone("13800138001").orElseThrow();
        com.seahorse.store.application.dto.member.MemberCommands.SetCardPasswordCommand pwdCmd =
                com.seahorse.store.application.dto.member.MemberCommands.SetCardPasswordCommand.builder()
                        .password("654321")
                        .enabled(true)
                        .build();
        Member withPwd = memberAssetAppService.setCardPassword(m1.getId(), pwdCmd);
        String memberJson = objectMapper.writeValueAsString(withPwd);
        Assertions.assertFalse(memberJson.contains("\"cardPassword\":"), "JSON序列化严禁泄露cardPassword哈希字段");
        Assertions.assertTrue(memberJson.contains("\"hasCardPassword\":true"), "JSON序列化应输出hasCardPassword布尔派生属性");

        Member otherTenantSameNo = memberRepository.saveAndFlush(Member.builder()
                .tenantId("T999")
                .memberNo("HM880001")
                .name("跨租户同号会员")
                .phone("13599990001")
                .level(com.seahorse.store.domain.member.enums.MemberLevel.REGULAR)
                .status("ACTIVE")
                .build());
        Assertions.assertNotNull(otherTenantSameNo.getId(), "不同租户允许拥有相同memberNo(uk_tenant_member_no)");

        // 3. 会员充值自动晋升等级 + discountName 等级联动同步 (R-08)
        Member upgradeMember = memberAssetAppService.registerMember(
                new com.seahorse.store.application.dto.member.MemberCommands.MemberRegisterCommand(
                        "周晋升", "13688887777", "MALE", LocalDate.of(1998, 3, 15), BigDecimal.ZERO, BigDecimal.ZERO
                )
        );
        Assertions.assertEquals(com.seahorse.store.domain.member.enums.MemberLevel.REGULAR, upgradeMember.getLevel());

        memberAssetAppService.rechargeDualBalance(
                com.seahorse.store.application.dto.member.MemberCommands.RechargeCommand.builder()
                        .memberId(upgradeMember.getId())
                        .principalAmount(BigDecimal.valueOf(1200.00))
                        .giftAmount(BigDecimal.valueOf(200.00))
                        .build()
        );
        Member afterRecharge = memberRepository.findById(upgradeMember.getId()).orElseThrow();
        Assertions.assertEquals(com.seahorse.store.domain.member.enums.MemberLevel.VIP, afterRecharge.getLevel(),
                "累计实充达1200元应自动晋升为VIP");

        Member afterDiscountSync = memberAssetAppService.updateMemberDetail(
                upgradeMember.getId(),
                com.seahorse.store.application.dto.member.MemberCommands.UpdateMemberDetailCommand.builder()
                        .discountName("至尊白金卡")
                        .build()
        );
        Assertions.assertEquals(com.seahorse.store.domain.member.enums.MemberLevel.PLATINUM, afterDiscountSync.getLevel(),
                "修改discountName为白金卡时应自动同步会员等级为PLATINUM");

        // 4. 预约 startDate~endDate 区间查询与软取消 (R-10)
        com.seahorse.store.domain.appointment.model.Appointment apt1 = appointmentController.createAppointment(
                com.seahorse.store.domain.appointment.model.Appointment.builder()
                        .customerName("区间预约客A")
                        .phone("13500001111")
                        .aptDate("2026-11-20")
                        .aptTime("14:00")
                        .serviceName("精致剪发")
                        .build()
        ).getData();
        appointmentController.createAppointment(
                com.seahorse.store.domain.appointment.model.Appointment.builder()
                        .customerName("区间预约客B")
                        .phone("13500002222")
                        .aptDate("2026-11-22")
                        .aptTime("16:30")
                        .serviceName("头皮护理")
                        .build()
        );

        List<com.seahorse.store.domain.appointment.model.Appointment> rangeApts =
                appointmentController.getAppointments("S001", null, "2026-11-19", "2026-11-23").getData();
        Assertions.assertEquals(2, rangeApts.size(), "startDate~endDate区间查询应返回2条预约");

        var cancelResp = appointmentController.deleteAppointment(apt1.getId());
        Assertions.assertEquals("CANCELLED", cancelResp.getData().getStatus(), "取消预约应软更新状态为CANCELLED");
        Assertions.assertTrue(appointmentRepository.findById(apt1.getId()).isPresent(), "软取消后数据库应保留预约记录");

        // 5. 考勤打卡与求职简历数据库持久化 (R-04) + 平台/跨租户权限防越权校验 (R-01)
        com.seahorse.store.interfaces.web.AttendanceRecordController.MobileCheckInRequest checkInReq =
                new com.seahorse.store.interfaces.web.AttendanceRecordController.MobileCheckInRequest();
        checkInReq.setStaffName("李店长");
        checkInReq.setPhone("13800000002");
        checkInReq.setPostName("店长");
        checkInReq.setType("CHECK_IN");
        checkInReq.setDistanceMeters(50.0);
        checkInReq.setLocationName("海马旗舰店正门");
        var checkInResp = attendanceRecordController.mobileCheckIn(checkInReq);
        Assertions.assertEquals(200, checkInResp.getCode());
        Assertions.assertTrue(attendanceRecordRepository.count() >= 1, "移动端考勤打卡记录应持久化至sh_attendance_record表");

        com.seahorse.store.interfaces.web.JobApplicationController.JobApplicationDTO jobDto =
                new com.seahorse.store.interfaces.web.JobApplicationController.JobApplicationDTO();
        jobDto.setTenantId("T001");
        jobDto.setStoreName("海马智慧门店");
        jobDto.setPostName("高级发型师");
        jobDto.setCandidateName("陈求职");
        jobDto.setPhone("13966668888");
        var jobResp = jobApplicationController.submitApplication(jobDto);
        Assertions.assertEquals(200, jobResp.getCode());
        Assertions.assertTrue(jobApplicationRepository.findByApplicationNo(jobResp.getData().getId()).isPresent(),
                "求职简历应持久化至sh_job_application表");

        com.seahorse.store.common.ServiceException platformDenied = Assertions.assertThrows(
                com.seahorse.store.common.ServiceException.class,
                com.seahorse.store.context.TenantContext::assertPlatformAdmin,
                "T001租户普通店长绝不应绕过平台开发商权限校验"
        );
        Assertions.assertEquals(403, platformDenied.getCode());

        com.seahorse.store.common.ServiceException crossTenantDenied = Assertions.assertThrows(
                com.seahorse.store.common.ServiceException.class,
                () -> com.seahorse.store.context.TenantContext.assertTenantAccess("T999"),
                "跨租户访问T999资源应抛出403越权异常"
        );
        Assertions.assertEquals(403, crossTenantDenied.getCode());
    }

    private void executeSqlScript(Connection conn, String rawSql) throws Exception {
        StringBuilder cleaned = new StringBuilder();
        for (String line : rawSql.split("\\r?\\n")) {
            String trimmed = line.trim();
            if (trimmed.isEmpty() || trimmed.startsWith("--")) {
                continue;
            }
            String upper = trimmed.toUpperCase();
            if (upper.startsWith("CREATE DATABASE ") || upper.startsWith("USE ")) {
                continue;
            }
            cleaned.append(line).append('\n');
        }
        for (String stmtSql : cleaned.toString().split(";")) {
            String sql = stmtSql.trim();
            if (sql.isEmpty()) {
                continue;
            }
            sql = sql.replaceAll("(?i)\\)\\s*ENGINE\\s*=\\s*InnoDB[^;]*", ")");
            sql = sql.replaceAll("(?i)DATE_ADD\\(\\s*CURDATE\\(\\)\\s*,\\s*INTERVAL\\s+(\\d+)\\s+MONTH\\s*\\)",
                    "TIMESTAMPADD(MONTH, $1, CURRENT_DATE)");
            try (Statement st = conn.createStatement()) {
                st.execute(sql);
            }
        }
    }

    private String camelToSnake(String str) {
        return str.replaceAll("([a-z0-9])([A-Z])", "$1_$2").toLowerCase();
    }
}
