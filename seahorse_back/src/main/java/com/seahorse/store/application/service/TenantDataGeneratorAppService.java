package com.seahorse.store.application.service;

import com.seahorse.store.common.ServiceException;
import com.seahorse.store.domain.common.constant.CommonConstants;
import com.seahorse.store.domain.iam.enums.EmployeeRole;
import com.seahorse.store.domain.iam.enums.IndustryType;
import com.seahorse.store.domain.iam.model.Employee;
import com.seahorse.store.domain.iam.model.Store;
import com.seahorse.store.domain.iam.model.Tenant;
import com.seahorse.store.domain.member.enums.MemberLevel;
import com.seahorse.store.domain.member.model.DualBalanceAccount;
import com.seahorse.store.domain.member.model.Member;
import com.seahorse.store.domain.member.model.MemberCardTemplate;
import com.seahorse.store.domain.product.enums.ProductType;
import com.seahorse.store.domain.product.model.Product;
import com.seahorse.store.domain.session.enums.SpaceStatus;
import com.seahorse.store.domain.session.enums.SpaceType;
import com.seahorse.store.domain.session.model.ServiceSpace;
import com.seahorse.store.infrastructure.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * 租户业务场景真实测试数据生成器
 * 严格遵从多租户物理隔离规范，仅对当前租户 tenantId 生效，支持美业/餐饮/汽修/零售 4 大行业真实业务场景
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TenantDataGeneratorAppService {

    private final TenantRepository tenantRepository;
    private final StoreRepository storeRepository;
    private final EmployeeRepository employeeRepository;
    private final ServiceSpaceRepository spaceRepository;
    private final ProductRepository productRepository;
    private final MemberRepository memberRepository;
    private final DualBalanceAccountRepository balanceAccountRepository;
    private final MemberCardTemplateRepository cardTemplateRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * 为指定租户按需生成业务场景全套测试数据
     */
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> initDemoData(String tenantId, String industryStr) {
        Tenant tenant = tenantRepository.findByTenantId(tenantId)
                .orElseThrow(() -> new ServiceException("租户不存在: " + tenantId));

        if ("T001".equalsIgnoreCase(tenantId) || "PLATFORM".equalsIgnoreCase(tenantId)) {
            throw new ServiceException("系统演示公共租户数据受保护，不可重新生成！");
        }

        // 1. 先安全清理当前租户现有业务数据，确保全新独立
        clearTenantDataInternal(tenantId);

        IndustryType industry = IndustryType.BEAUTY;
        if ("RESTAURANT".equalsIgnoreCase(industryStr) || "DINING".equalsIgnoreCase(industryStr)) {
            industry = IndustryType.RESTAURANT;
        } else if ("AUTO".equalsIgnoreCase(industryStr)) {
            industry = IndustryType.AUTO;
        } else if ("RETAIL".equalsIgnoreCase(industryStr)) {
            industry = IndustryType.RETAIL;
        }

        String storeId = "S" + (int)((Math.random() * 9 + 1) * 10000);
        String storeName;
        String catName;
        String catGroup;
        String feeName;
        BigDecimal feeAmount;

        switch (industry) {
            case RESTAURANT -> {
                storeName = tenant.getTenantName() != null ? (tenant.getTenantName() + " (特色餐饮旗舰店)") : "栖枫悦食·特色餐饮 (旗舰店)";
                catName = "餐饮轻食";
                catGroup = "服务类";
                feeName = "餐位费";
                feeAmount = BigDecimal.valueOf(5.00);
            }
            case AUTO -> {
                storeName = tenant.getTenantName() != null ? (tenant.getTenantName() + " (汽车工坊总店)") : "极速驰骋·汽车工坊 (总店)";
                catName = "汽车养护";
                catGroup = "服务类";
                feeName = "工时费";
                feeAmount = BigDecimal.valueOf(50.00);
            }
            case RETAIL -> {
                storeName = tenant.getTenantName() != null ? (tenant.getTenantName() + " (精品专营总店)") : "优选名品·精品零售 (总店)";
                catName = "专营零售";
                catGroup = "零售类";
                feeName = "包装费";
                feeAmount = BigDecimal.valueOf(2.00);
            }
            default -> {
                storeName = tenant.getTenantName() != null ? (tenant.getTenantName() + " (丝艺美学总店)") : "丝艺美学·旗舰总店";
                catName = "美业服务";
                catGroup = "服务类";
                feeName = "造型设计费";
                feeAmount = BigDecimal.valueOf(15.00);
            }
        }

        // 2. 创建真实场景门店
        Store store = Store.builder()
                .tenantId(tenantId)
                .storeId(storeId)
                .storeName(storeName)
                .industry(industry)
                .industryCategoryId(6)
                .industryCategoryName(catName)
                .industryCategoryGroup(catGroup)
                .address("核心商业中心街区 A座101")
                .phone(tenant.getContactPhone() != null ? tenant.getContactPhone() : "020-88886666")
                .businessHours("09:00 - 22:00")
                .feeName(feeName)
                .defaultFeeAmount(feeAmount)
                .feeEnabled(true)
                .status(CommonConstants.STATUS_ACTIVE)
                .build();
        storeRepository.save(store);

        // 3. 将商户主管理员账号关联到该门店
        List<Employee> owners = employeeRepository.findByTenantId(tenantId);
        for (Employee emp : owners) {
            if (emp.getRole() == EmployeeRole.SUPER_ADMIN) {
                emp.setStoreId(storeId);
                employeeRepository.save(emp);
            }
        }

        // 4. 创建 2 名合规店员 (在体验版 3 人名额上限内，留 1 名额供自主录入)
        List<Employee> staffList = createScenarioStaff(tenantId, storeId, industry);
        employeeRepository.saveAll(staffList);

        // 5. 创建 4 个空间包厢/工位
        List<ServiceSpace> spaces = createScenarioSpaces(tenantId, storeId, industry);
        spaceRepository.saveAll(spaces);

        // 6. 创建 4 项商品与服务
        List<Product> products = createScenarioProducts(tenantId, storeId, industry);
        productRepository.saveAll(products);

        // 7. 创建 3 名会员与储值账户
        List<Member> members = createScenarioMembers(tenantId, storeId);
        memberRepository.saveAll(members);
        for (int i = 0; i < members.size(); i++) {
            Member m = members.get(i);
            BigDecimal principal = (i == 0) ? BigDecimal.valueOf(1580.00) : ((i == 1) ? BigDecimal.valueOf(680.00) : BigDecimal.valueOf(3200.00));
            BigDecimal gift = (i == 0) ? BigDecimal.valueOf(200.00) : ((i == 1) ? BigDecimal.valueOf(50.00) : BigDecimal.valueOf(500.00));
            DualBalanceAccount acc = DualBalanceAccount.builder()
                    .memberId(m.getId())
                    .tenantId(tenantId)
                    .principalBalance(principal)
                    .giftBalance(gift)
                    .totalRecharged(principal)
                    .totalGiftGranted(gift)
                    .deductMode(com.seahorse.store.domain.member.enums.DeductMode.PROPORTIONAL)
                    .build();
            balanceAccountRepository.save(acc);
        }

        // 8. 创建 3 套会员卡项模板
        List<MemberCardTemplate> cardTemplates = createScenarioCardTemplates(tenantId);
        cardTemplateRepository.saveAll(cardTemplates);

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("tenantId", tenantId);
        res.put("storeId", storeId);
        res.put("storeName", storeName);
        res.put("industry", industry.name());
        res.put("industryCategoryName", catName);
        res.put("storeCount", 1);
        res.put("staffCount", staffList.size());
        res.put("spaceCount", spaces.size());
        res.put("productCount", products.size());
        res.put("memberCount", members.size());
        res.put("cardTemplateCount", cardTemplates.size());
        res.put("message", "已为您成功生成符合【" + catName + "】经营场景的全套业务测试数据！所有数据均严格隔离仅归属本商户。");

        log.info("【租户测试数据生成成功】TenantId={}, StoreId={}, Industry={}, StaffCount={}, SpaceCount={}",
                tenantId, storeId, industry, staffList.size(), spaces.size());

        return res;
    }

    /**
     * 清空当前租户名下的所有业务数据，彻底重置为纯净零数据状态
     */
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> clearTenantData(String tenantId) {
        if ("T001".equalsIgnoreCase(tenantId) || "PLATFORM".equalsIgnoreCase(tenantId)) {
            throw new ServiceException("系统演示公共租户数据受保护，不可清空！");
        }
        clearTenantDataInternal(tenantId);
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("tenantId", tenantId);
        res.put("isCleanState", true);
        res.put("message", "商户所有门店及业务数据已全部清空，已重置为全新纯净初始状态！");
        return res;
    }

    private void clearTenantDataInternal(String tenantId) {
        // 1. 删除空间
        spaceRepository.deleteAll(spaceRepository.findByTenantId(tenantId));
        // 2. 删除商品
        productRepository.deleteAll(productRepository.findByTenantId(tenantId));
        // 3. 删除员工 (保留主管理员 SUPER_ADMIN)
        List<Employee> allStaff = employeeRepository.findByTenantId(tenantId);
        for (Employee emp : allStaff) {
            if (emp.getRole() == EmployeeRole.SUPER_ADMIN) {
                emp.setStoreId(null);
                employeeRepository.save(emp);
            } else {
                employeeRepository.delete(emp);
            }
        }
        // 4. 删除会员及储值账户
        List<Member> members = memberRepository.findByTenantId(tenantId);
        if (!members.isEmpty()) {
            List<Long> memberIds = members.stream()
                    .map(Member::getId)
                    .filter(Objects::nonNull)
                    .toList();
            if (!memberIds.isEmpty()) {
                balanceAccountRepository.deleteAll(balanceAccountRepository.findByMemberIdIn(memberIds));
            }
            memberRepository.deleteAll(members);
        }
        // 5. 删除卡模板
        cardTemplateRepository.deleteAll(cardTemplateRepository.findByTenantIdOrderBySortOrderAsc(tenantId));
        // 6. 删除门店
        storeRepository.deleteAll(storeRepository.findByTenantId(tenantId));
    }

    /**
     * 查询租户当前数据状态
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getTenantDataStatus(String tenantId) {
        List<Store> stores = storeRepository.findByTenantId(tenantId);
        List<Employee> staff = employeeRepository.findByTenantId(tenantId).stream()
                .filter(e -> e.getRole() != EmployeeRole.SUPER_ADMIN && e.getRole() != EmployeeRole.PLATFORM_DEVELOPER)
                .toList();
        long spaceCount = spaceRepository.countByTenantId(tenantId);
        long productCount = productRepository.countByTenantId(tenantId);
        long memberCount = memberRepository.countByTenantId(tenantId);

        boolean isCleanState = stores.isEmpty() && staff.isEmpty() && memberCount == 0;

        Map<String, Object> map = new LinkedHashMap<>();
        map.put("tenantId", tenantId);
        map.put("storeCount", stores.size());
        map.put("staffCount", staff.size());
        map.put("spaceCount", spaceCount);
        map.put("productCount", productCount);
        map.put("memberCount", memberCount);
        map.put("isCleanState", isCleanState);
        return map;
    }

    private List<Employee> createScenarioStaff(String tenantId, String storeId, IndustryType industry) {
        String rand = String.format("%04d", (int)(Math.random() * 10000));
        String pwd = passwordEncoder.encode("123456");

        Employee s1;
        Employee s2;

        switch (industry) {
            case RESTAURANT -> {
                s1 = Employee.builder().tenantId(tenantId).storeId(storeId)
                        .username("mgr_" + rand).password(pwd).realName("王经理")
                        .phone("138" + rand + "001").postName("店长兼营运主管").role(EmployeeRole.STORE_MANAGER)
                        .baseSalary(BigDecimal.valueOf(7000)).defaultCommissionRate(BigDecimal.valueOf(0.05))
                        .status(CommonConstants.STATUS_ACTIVE).isDeleted(false).build();
                s2 = Employee.builder().tenantId(tenantId).storeId(storeId)
                        .username("chef_" + rand).password(pwd).realName("李主厨")
                        .phone("138" + rand + "002").postName("料理主厨").role(EmployeeRole.TECHNICIAN)
                        .baseSalary(BigDecimal.valueOf(5500)).defaultCommissionRate(BigDecimal.valueOf(0.10))
                        .status(CommonConstants.STATUS_ACTIVE).isDeleted(false).build();
            }
            case AUTO -> {
                s1 = Employee.builder().tenantId(tenantId).storeId(storeId)
                        .username("head_" + rand).password(pwd).realName("张车间长")
                        .phone("138" + rand + "001").postName("车间主管").role(EmployeeRole.STORE_MANAGER)
                        .baseSalary(BigDecimal.valueOf(7500)).defaultCommissionRate(BigDecimal.valueOf(0.06))
                        .status(CommonConstants.STATUS_ACTIVE).isDeleted(false).build();
                s2 = Employee.builder().tenantId(tenantId).storeId(storeId)
                        .username("tech_" + rand).password(pwd).realName("刘高级技工")
                        .phone("138" + rand + "002").postName("机电技师").role(EmployeeRole.TECHNICIAN)
                        .baseSalary(BigDecimal.valueOf(5000)).defaultCommissionRate(BigDecimal.valueOf(0.15))
                        .status(CommonConstants.STATUS_ACTIVE).isDeleted(false).build();
            }
            case RETAIL -> {
                s1 = Employee.builder().tenantId(tenantId).storeId(storeId)
                        .username("lead_" + rand).password(pwd).realName("赵店长")
                        .phone("138" + rand + "001").postName("专营店长").role(EmployeeRole.STORE_MANAGER)
                        .baseSalary(BigDecimal.valueOf(6000)).defaultCommissionRate(BigDecimal.valueOf(0.04))
                        .status(CommonConstants.STATUS_ACTIVE).isDeleted(false).build();
                s2 = Employee.builder().tenantId(tenantId).storeId(storeId)
                        .username("cash_" + rand).password(pwd).realName("孙导购")
                        .phone("138" + rand + "002").postName("资深顾问").role(EmployeeRole.CASHIER)
                        .baseSalary(BigDecimal.valueOf(4200)).defaultCommissionRate(BigDecimal.valueOf(0.08))
                        .status(CommonConstants.STATUS_ACTIVE).isDeleted(false).build();
            }
            default -> {
                s1 = Employee.builder().tenantId(tenantId).storeId(storeId)
                        .username("su_" + rand).password(pwd).realName("苏曼")
                        .phone("138" + rand + "001").postName("店长兼高级发型师").role(EmployeeRole.STORE_MANAGER)
                        .baseSalary(BigDecimal.valueOf(6500)).defaultCommissionRate(BigDecimal.valueOf(0.10))
                        .status(CommonConstants.STATUS_ACTIVE).isDeleted(false).build();
                s2 = Employee.builder().tenantId(tenantId).storeId(storeId)
                        .username("tony_" + rand).password(pwd).realName("阿杰总监")
                        .phone("138" + rand + "002").postName("资深美学总监").role(EmployeeRole.TECHNICIAN)
                        .baseSalary(BigDecimal.valueOf(4500)).defaultCommissionRate(BigDecimal.valueOf(0.30))
                        .status(CommonConstants.STATUS_ACTIVE).isDeleted(false).build();
            }
        }
        return Arrays.asList(s1, s2);
    }

    private List<ServiceSpace> createScenarioSpaces(String tenantId, String storeId, IndustryType industry) {
        List<ServiceSpace> list = new ArrayList<>();
        switch (industry) {
            case RESTAURANT -> {
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("R01").spaceName("包厢·雅竹轩").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(8).floorZone("2楼VIP区").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("R02").spaceName("包厢·荷风阁").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(6).floorZone("2楼VIP区").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("A01").spaceName("卡座·A01").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(4).floorZone("1楼大厅").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("B02").spaceName("散台·B02").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(2).floorZone("1楼大厅").build());
            }
            case AUTO -> {
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("W01").spaceName("1号快保工位").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(1).floorZone("A区机修").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("W02").spaceName("2号底盘维修工位").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(1).floorZone("A区机修").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("W03").spaceName("3号四轮定位工位").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(1).floorZone("B区校正").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("W04").spaceName("精细洗美工位").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(1).floorZone("C区洗美").build());
            }
            case RETAIL -> {
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("S01").spaceName("A区服饰精品展台").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(4).floorZone("精品主展区").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("S02").spaceName("B区数码科技展位").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(4).floorZone("潮流数码区").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("S03").spaceName("C区美妆护肤体验台").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(2).floorZone("体验沙龙区").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("S04").spaceName("收银与提货专席").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(2).floorZone("收银前台").build());
            }
            default -> {
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("B01").spaceName("1号造型镜台").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(1).floorZone("造型剪发大厅").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("B02").spaceName("2号造型镜台").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(1).floorZone("造型剪发大厅").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("B03").spaceName("VIP头皮理疗SPA包厢").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(2).floorZone("VIP养护专区").build());
                list.add(ServiceSpace.builder().tenantId(tenantId).storeId(storeId).spaceCode("B04").spaceName("美甲美睫轻奢雅座").spaceType(SpaceType.ROOM).status(SpaceStatus.IDLE).capacity(2).floorZone("手足美甲区").build());
            }
        }
        return list;
    }

    private List<Product> createScenarioProducts(String tenantId, String storeId, IndustryType industry) {
        List<Product> list = new ArrayList<>();
        String rand = String.format("%03d", (int)(Math.random() * 1000));
        switch (industry) {
            case RESTAURANT -> {
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_R1_" + rand).name("主厨推荐·双人甄选套餐").productType(ProductType.SERVICE).price(BigDecimal.valueOf(298.00)).costPrice(BigDecimal.valueOf(120.00)).defaultCommission(BigDecimal.valueOf(15.00)).unit("套").durationMinutes(60).description("2人份特惠豪华套餐").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_R2_" + rand).name("招牌特色炭烤料理").productType(ProductType.SERVICE).price(BigDecimal.valueOf(128.00)).costPrice(BigDecimal.valueOf(50.00)).defaultCommission(BigDecimal.valueOf(10.00)).unit("份").durationMinutes(30).description("招牌火候炭烤").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_R3_" + rand).name("轻食时蔬有机沙拉").productType(ProductType.SERVICE).price(BigDecimal.valueOf(48.00)).costPrice(BigDecimal.valueOf(15.00)).defaultCommission(BigDecimal.valueOf(3.00)).unit("例").durationMinutes(15).description("低卡轻食健康之选").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_R4_" + rand).name("精酿手工气泡原浆").productType(ProductType.PHYSICAL).price(BigDecimal.valueOf(38.00)).costPrice(BigDecimal.valueOf(12.00)).stock(100).unit("瓶").description("500ml手工鲜酿").available(true).build());
            }
            case AUTO -> {
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_A1_" + rand).name("全合成机油基础常规保养").productType(ProductType.SERVICE).price(BigDecimal.valueOf(399.00)).costPrice(BigDecimal.valueOf(160.00)).defaultCommission(BigDecimal.valueOf(50.00)).unit("次").durationMinutes(60).description("含机滤更换与多项工况检查").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_A2_" + rand).name("全车深度安全检测与胎压校准").productType(ProductType.SERVICE).price(BigDecimal.valueOf(120.00)).costPrice(BigDecimal.valueOf(20.00)).defaultCommission(BigDecimal.valueOf(25.00)).unit("次").durationMinutes(30).description("底盘线路胎压36项安全体检").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_A3_" + rand).name("刹车系统深化养护与刹车油更换").productType(ProductType.SERVICE).price(BigDecimal.valueOf(260.00)).costPrice(BigDecimal.valueOf(80.00)).defaultCommission(BigDecimal.valueOf(35.00)).unit("套").durationMinutes(45).description("制动系统深度除杂与换油").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_A4_" + rand).name("德国进口纳米级水晶镀晶液").productType(ProductType.PHYSICAL).price(BigDecimal.valueOf(580.00)).costPrice(BigDecimal.valueOf(200.00)).stock(50).unit("盒").description("50ml装纳米硬化防划痕").available(true).build());
            }
            case RETAIL -> {
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_S1_" + rand).name("轻奢纯棉休闲商务外套").productType(ProductType.PHYSICAL).price(BigDecimal.valueOf(680.00)).costPrice(BigDecimal.valueOf(260.00)).stock(30).unit("件").description("春季新款舒适透气").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_S2_" + rand).name("真丝桑蚕丝丝巾礼盒").productType(ProductType.PHYSICAL).price(BigDecimal.valueOf(299.00)).costPrice(BigDecimal.valueOf(90.00)).stock(40).unit("盒").description("100%桑蚕丝典雅礼盒").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_S3_" + rand).name("便携式高保真无线蓝牙音箱").productType(ProductType.PHYSICAL).price(BigDecimal.valueOf(199.00)).costPrice(BigDecimal.valueOf(65.00)).stock(60).unit("台").description("超长续航重低音立体声").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_S4_" + rand).name("天然植物精油香薰礼盒").productType(ProductType.PHYSICAL).price(BigDecimal.valueOf(158.00)).costPrice(BigDecimal.valueOf(45.00)).stock(80).unit("套").description("白茶香型安神舒眠").available(true).build());
            }
            default -> {
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_B1_" + rand).name("精细洗剪吹(总监美学设计)").productType(ProductType.SERVICE).price(BigDecimal.valueOf(128.00)).costPrice(BigDecimal.valueOf(10.00)).defaultCommission(BigDecimal.valueOf(45.00)).unit("次").durationMinutes(45).description("资深总监定制发型剪发").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_B2_" + rand).name("高端染烫修复全套护理套餐").productType(ProductType.SERVICE).price(BigDecimal.valueOf(580.00)).costPrice(BigDecimal.valueOf(90.00)).defaultCommission(BigDecimal.valueOf(160.00)).unit("套").durationMinutes(120).description("进口植物染烫膏搭配精油养护").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_B3_" + rand).name("深层头皮净化抗衰理疗SPA").productType(ProductType.SERVICE).price(BigDecimal.valueOf(320.00)).costPrice(BigDecimal.valueOf(40.00)).defaultCommission(BigDecimal.valueOf(90.00)).unit("次").durationMinutes(60).description("毛囊深层清洁与微循环激活").available(true).build());
                list.add(Product.builder().tenantId(tenantId).storeId(storeId).productCode("PRD_B4_" + rand).name("沙龙级植物弱酸精油修护洗发乳").productType(ProductType.PHYSICAL).price(BigDecimal.valueOf(168.00)).costPrice(BigDecimal.valueOf(48.00)).stock(120).unit("瓶").description("500ml沙龙专用弱酸配方").available(true).build());
            }
        }
        return list;
    }

    private List<Member> createScenarioMembers(String tenantId, String storeId) {
        String rand = String.format("%04d", (int)(Math.random() * 10000));
        Member m1 = Member.builder()
                .tenantId(tenantId)
                .memberNo("VIP" + rand + "1")
                .name("林清雅")
                .phone("138" + rand + "1")
                .gender("FEMALE")
                .birthday(LocalDate.of(1995, 6, 18))
                .level(MemberLevel.DIAMOND)
                .totalSpent(BigDecimal.valueOf(3680.00))
                .visitCount(12)
                .points(520)
                .status(CommonConstants.STATUS_ACTIVE)
                .build();

        Member m2 = Member.builder()
                .tenantId(tenantId)
                .memberNo("VIP" + rand + "2")
                .name("陈子轩")
                .phone("138" + rand + "2")
                .gender("MALE")
                .birthday(LocalDate.of(1990, 11, 24))
                .level(MemberLevel.GOLD)
                .totalSpent(BigDecimal.valueOf(1280.00))
                .visitCount(5)
                .points(180)
                .status(CommonConstants.STATUS_ACTIVE)
                .build();

        Member m3 = Member.builder()
                .tenantId(tenantId)
                .memberNo("VIP" + rand + "3")
                .name("赵嘉欣")
                .phone("138" + rand + "3")
                .gender("FEMALE")
                .birthday(LocalDate.of(1998, 3, 12))
                .level(MemberLevel.REGULAR)
                .totalSpent(BigDecimal.valueOf(680.00))
                .visitCount(2)
                .points(90)
                .status(CommonConstants.STATUS_ACTIVE)
                .build();

        return Arrays.asList(m1, m2, m3);
    }

    private List<MemberCardTemplate> createScenarioCardTemplates(String tenantId) {
        MemberCardTemplate t1 = MemberCardTemplate.builder()
                .tenantId(tenantId)
                .cardType("STORED_VALUE")
                .cardTypeName("储值卡")
                .cardName("尊享储值金卡 (充2000送300)")
                .price(BigDecimal.valueOf(2000.00))
                .originalPrice(BigDecimal.valueOf(2300.00))
                .principalAmount(BigDecimal.valueOf(2000.00))
                .giftAmount(BigDecimal.valueOf(300.00))
                .discountRate(BigDecimal.valueOf(0.85))
                .contentDescription("本金2000元，赠金300元，全场享8.5折优惠")
                .status(CommonConstants.STATUS_ACTIVE)
                .sortOrder(1)
                .notes("全场项目通用，享8.5折优惠")
                .build();

        MemberCardTemplate t2 = MemberCardTemplate.builder()
                .tenantId(tenantId)
                .cardType("TIME_CARD")
                .cardTypeName("次卡")
                .cardName("畅享体验次卡 (10次卡)")
                .price(BigDecimal.valueOf(880.00))
                .originalPrice(BigDecimal.valueOf(1280.00))
                .principalAmount(BigDecimal.valueOf(880.00))
                .giftAmount(BigDecimal.ZERO)
                .totalTimes(10)
                .validityDays(365)
                .contentDescription("包含项目服务10次，有效期365天")
                .status(CommonConstants.STATUS_ACTIVE)
                .sortOrder(2)
                .notes("有效期1年，平均每次仅需88元")
                .build();

        MemberCardTemplate t3 = MemberCardTemplate.builder()
                .tenantId(tenantId)
                .cardType("BENEFIT_CARD")
                .cardTypeName("权益卡")
                .cardName("黑金年度尊享权益卡")
                .price(BigDecimal.valueOf(365.00))
                .originalPrice(BigDecimal.valueOf(680.00))
                .principalAmount(BigDecimal.valueOf(365.00))
                .giftAmount(BigDecimal.ZERO)
                .discountRate(BigDecimal.valueOf(0.80))
                .validityDays(365)
                .contentDescription("全年尊享8折VIP折上折与专属优先服务")
                .status(CommonConstants.STATUS_ACTIVE)
                .sortOrder(3)
                .notes("每天仅需1元，全年尊享8折VIP折上折与优先预约")
                .build();

        return Arrays.asList(t1, t2, t3);
    }
}
