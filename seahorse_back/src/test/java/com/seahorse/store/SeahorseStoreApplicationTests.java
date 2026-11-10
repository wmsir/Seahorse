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
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

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

        // 6. 验证“海马体”记忆档案
        MemberProfileVO profile = memberAssetAppService.getMemberProfile(member.getId());
        Assertions.assertNotNull(profile.getPreferences());
        Assertions.assertFalse(profile.getPreferences().isEmpty(), "海马体记忆档案标签数不应为空");
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
}
