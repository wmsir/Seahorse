# 智慧会员与全场景门店履约系统 领域驱动设计 (DDD) 详尽规格说明书 (企业生产落地版)

> **版本**：v2.5.0  
> **状态**：正式发布 (Approved)  
> **系统代号**：Seahorse (海马智慧门店)  
> **核心宗旨**：“海马会员，记住每位好客。全场景履约，让门店经营稳赚增效。”  
> **适配行业（7大标准业态 `IndustryType`）**：美容美发美甲 (`BEAUTY`)、餐饮轻食正餐 (`RESTAURANT`)、汽车养护维修 (`AUTO`)、专营名品零售 (`RETAIL`)、足疗推拿养生 (`FOOT_SPA`)、新中式茶馆棋牌 (`TEA_HOUSE`)、宠物洗护医疗 (`PET`)

---

## 1. 战略设计 (Strategic Design)

### 1.1 业务愿景与核心问题空间

在线下生活服务业连锁经营中，传统 SaaS 方案普遍存在以下痛点：
1. **客情割裂与千人一面**：老顾客进店需反复向技师或服务员沟通个人忌口、常态喜好、发质特性或车型配置，缺乏熟客尊享感；
2. **多批次在场履约受阻**：餐饮加菜、美业追加护理精油、汽修追加保养等在场动态消费流程缺乏统一抽象，加单易漏、工位占用无法闭环；
3. **储值资产混淆与超扣风险**：本金与赠送金未严谨分轨核算，高并发结算或网络波动时极易发生次卡超扣、资金对账不平；
4. **经营成本粗放核算**：只关注营业流水，缺少对房租、BOM 物料耗材消耗以及员工工单提成的实时自动核算，到月末变成糊涂账；
5. **一人多店执业与连锁协同割裂**：员工跨分店兼职排班难、系统账号切换繁琐、各店页签权限缺乏安全物理隔离。

**Seahorse 智慧门店系统**基于**领域驱动设计 (DDD)** 构建，确立以“海马体常态记忆”为用户心智连接，以“在场服务流会话微内核”为高并发调度引擎，以“双轨储值金防超扣”为资金底座，以“全口径成本中心”为财务视角的数字化运营操作系统。

---

### 1.2 统一语言体系 (Ubiquitous Language)

为消除业务专家、产品经理与研发团队之间的沟通鸿沟，建立如下全域统一语言：

| 统一术语 (Term) | 英文标识 (Identifier) | 严格领域定义与业务内涵 |
| :--- | :--- | :--- |
| **在场会话** | `ServiceSession` | 顾客物理到达门店、占用特定工位资源至结账离店的完整业务履约生命周期聚合。 |
| **工位/空间** | `ServiceSpace` | 承载在场服务的物理设施，支持 7 大业态别名：美发镜台/美甲位、餐饮散台/包厢、汽修举升机工位、零售体验台、足浴养生包厢、茶室棋牌包间、宠物洗护诊室。 |
| **批次追加** | `OrderBatch` | 一次在场履约过程中由顾客主扫或员工发起的动态消费明细追加单元（如加菜、加精油、加零配件）。 |
| **海马体常态记忆** | `CustomerHippocampusProfile` | 会员专属常态偏好切片，开单秒级呼出，消除重复交代成本。 |
| **双轨储值金** | `DualBalanceAccount` | 会员账户中物理隔离的`本金 (Principal)`与`赠送金 (Gift)`资金池，支持等比分摊与优先扣本金，内置 `@Version` 乐观锁版本控制。 |
| **防超扣锁机制** | `AntiOverdrawLock` | 基于 JPA `@Version` 乐观锁版本控制（CAS，覆盖 `DualBalanceAccount` 与 `Product`）防止次卡、储值资金与商品库存在高并发扣减时超扣超卖。 |
| **一人多店执业** | `MultiStorePractice` | 员工账号与多个授权执业门店的一对多绑定，登录自选工作台，严格遵循页签权限物理隔离。 |
| **BOM物料配方** | `ProductBomRecipe` | 每一个收费服务项目对应的标准原物料消耗配额（如染发膏克数、全合成机油升数），收银时自动核销扣减。 |
| **全口径成本** | `CostCenterLedger` | 包含固定成本（房租能耗、折旧）、变动成本（BOM耗材、营销补贴）与人工成本（底薪+提成自动汇总）的利润账本。 |
| **自动化关怀** | `AutomatedCareCampaign` | 深度结合中国国庆黄金周、传统节日与会员生命周期（生日、沉睡召回、高频VIP）的自动巡检与触达引擎。 |
| **隔离打印沙箱** | `PrintSandboxACL` | 客户端独立无污染热敏渲染容器，杜绝界面弹窗按钮透印，生成 58mm/80mm 矢量热敏小票与开箱脉冲。 |

---

### 1.3 子域划分与边界界定 (Subdomains & Bounded Contexts)

根据业务价值与战略重要度，系统划分为 12 个限界上下文：

```
+---------------------------------------------------------------------------------------------------------------+
|                                         海马智慧门店商业操作系统 领域全景                                      |
+---------------------------------------------------------------------------------------------------------------+
|  【核心域 (Core Domain)】—— 系统的差异化竞争优势与核心商业价值                                                 |
|  1. 在场履约会话上下文 (Service Session Context): 工位资源锁定、多批次动态追加、提成认领、履约状态推进        |
|  2. 统一交易与结算上下文 (Billing & Settlement Context): 组合支付拆解、防并发超扣、抹零收找、结算审计        |
|  3. 会员资产与双轨资金上下文 (Member Asset Context): 双轨资金分摊核销、计量次卡桶、积分变动、防超扣保护       |
|  4. “海马体”客户常态记忆上下文 (Customer Hippocampus Profile Context): 行业标签库、敏感体质、常态偏好秒级呼出 |
+---------------------------------------------------------------------------------------------------------------+
|  【通用域 (Generic Domain)】—— 支撑多业态运转的企业级标准化能力                                               |
|  5. 组织架构与一人多店执业上下文 (Organization & Multi-Store Context): 租户-门店-部门-岗位模型、兼职授权与鉴权|
|  6. 全口径成本与损益核算上下文 (Cost Center & Financial Context): 房租折旧、BOM出库耗材、底薪与提成实时汇总  |
|  7. 商品物料与配方 BOM 上下文 (Product, Inventory & BOM Context): 实物/服务/套餐分类、配方耗材扣减、库存预警 |
|  8. 业绩与提成核算上下文 (Commission & Performance Context): 售卡提成、施工提成、单品级多人分摊认领           |
|  9. 招聘与面试入职生命周期上下文 (Recruitment & Onboarding Context): 岗位发布、扫码投递、面试通知短信、秒开号|
+---------------------------------------------------------------------------------------------------------------+
|  【支撑域 (Supporting Domain)】—— 外部设备、网络协议集成与增长工具箱                                          |
|  10. 营销战役与自动化关怀上下文 (Marketing Campaign & Care): 12个月日历、国庆节假日企划、自动化短信巡检      |
|  11. 外设调度与打印沙箱上下文 (Hardware Dispatch & Sandbox): 独立热敏打印沙箱、58/80mm 矢量出单、钱箱脉冲驱动 |
|  12. 统一支付网关防腐上下文 (Payment Gateway ACL): 微信支付、支付宝、银联联机、现金收银策略适配与对账         |
+---------------------------------------------------------------------------------------------------------------+
```

---

### 1.4 上下文映射图 (Context Map)

```
                       +-------------------------------------------------+
                       | “海马体”常态记忆上下文 (Hippocampus Profile)   |
                       +-------------------------------------------------+
                                                │ (U / Customer)
                                                ▼ (D / Supplier)
+------------------------------------------------------------------------------------------------+
|                             在场履约会话上下文 (Service Session Context)                        |
|                     (空间工位占用、多批次动态追加明细、多人提成认领、服务状态推进)               |
+------------------------------------------------------------------------------------------------+
     │ 1. 触发明细追加与配方预占 (ItemAppendedEvent)               │ 2. 发起结账结算 (RequestCheckoutCommand)
     ├─────────────────────────────────────────┐                   ▼
     ▼                                         ▼      +------------------------------------------+
+--------------------------+   +--------------------------+   | 统一交易与结算上下文 (Billing Order)     |
| 硬件外设调度与沙箱 (ACL) |   | 商品与BOM库存上下文 (BOM)|   +------------------------------------------+
| (后厨分单/台位叫号单)    |   | (锁定精油/配件/原料消耗) |         │                   │
+--------------------------+   +--------------------------+         │ 3. 划扣会员资产   │ 4. 外部通道扣款
                                                                    ▼                   ▼
                                       +-----------------------------------+   +-------------------------+
                                       | 会员资产与双轨资金账户 (Asset)    |   | 统一支付网关上下文 (ACL)|
                                       | (本金/赠送金双轨扣减，次卡核销)   |   | (微信/支付宝/现金/刷卡) |
                                       +-----------------------------------+   +-------------------------+
                                                                    │                   │
                                                                    └─────────┬─────────┘
                                                                              │ 5. 结算成功 (BillingCompletedEvent)
                                                                              ▼
+----------------------------------------------------------------------------------------------------------------+
|                                        跨上下文事件广播与数据汇流中枢                                          |
+----------------------------------------------------------------------------------------------------------------+
          │                                           │                                     │
          ▼                                           ▼                                     ▼
+----------------------------------+     +----------------------------------+     +------------------------------+
| 业绩与提成核算上下文 (Commission)|     | 全口径成本与损益上下文 (Cost)    |     | 营销与自动化关怀 (Marketing) |
| (解析单品执行人，计入员工提成)   |     | (BOM消耗+提成+固定成本自动汇算)  |     | (累加积分、国庆双倍、促复购) |
+----------------------------------+     +----------------------------------+     +------------------------------+
```

- **映射关系说明**：
  - `ServiceSession` 与 `HippocampusProfile` 为顾客-供应者关系（Customer-Supplier），会话开启时注入记忆；
  - `BillingOrder` 与 `PaymentGateway` 之间建立防腐层（ACL），屏蔽渠道报文差异；
  - `BillingOrder` 通过发布 `BillingCompletedEvent` 向 `Commission`、`CostCenter` 与 `Marketing` 异步发布事件，实现最终一致性。

---

## 2. 战术设计：8 大核心领域聚合与实体建模 (Tactical Aggregates)

### 2.1 聚合 1：在场履约会话聚合根 (`ServiceSession`)

抹平餐饮“加菜”、美业“加护理”、汽修“增修项目”以及零售“加购”的业务形态差异，通过“会话-批次-明细”三层结构统一承载。

- **聚合根 (Aggregate Root)**: `ServiceSession`
- **内部实体 (Entities)**:
  - `ServiceSpace`: 履约物理空间（空间编号、空间别名：桌台/包厢/美发椅/举升机工位、容纳人数、状态）。
  - `OrderBatch`: 点单批次（批次序号、发起时间、操作端类型：顾客小程序主扫/员工POS录入）。
  - `SessionLineItem`: 消费明细项（服务项/商品SKU、数量、单价、规格属性、定制备注、关联BOM原料清单）。
  - `PerformerShare`: 服务提成人员配比（主做技师、协助技师、各自认领比例，如总监70%、助理30%）。
- **值对象 (Value Objects)**:
  - `SessionId`, `StoreId`, `TenantId`, `CustomerIdentity`
  - `SessionStatus`:
    - `IDLE` (空闲待开)
    - `OCCUPIED_ORDERING` (已占用/选品中)
    - `SERVING` (服务履约中/项目施工中)
    - `SETTLING` (结算锁定中)
    - `SETTLED_WAIT_CLEAN` (已买单/待清理复位)
- **核心业务行为 (Domain Behaviors)**:
  - `openSession(spaceId, customerIdentity, initialGuests)`: 校验空间空闲性并开启物理工位占用。
  - `appendBatch(List<AppendItemCmd> items, Operator operator)`: 动态追加消费项，自动创建新递增批次，触发领域事件 `ItemAppendedEvent`。
  - `adjustPerformerShare(lineItemId, List<PerformerShare> shares)`: 灵活分工调整，校验同一行项所有技师分摊比例之和必须为 100%。
  - `cancelLineItem(lineItemId, reason, supervisorAuth)`: 履约项目退订撤销，校验施工制作状态并记录审计日志。
  - `transferSpace(targetSpaceId)`: 换台/转工位，将全部消费批次无缝转移至空闲新工位。
  - `closeSession()`: 接收结账完成事件，推进状态为待清理，释放占用锁。

---

### 2.2 聚合 2：统一交易与组合支付聚合根 (`BillingOrder`)

负责将复杂的混合支付装配为不可篡改的法定财务凭单，杜绝并发差错与算力漏洞。

- **聚合根 (Aggregate Root)**: `BillingOrder`
- **内部实体 (Entities)**:
  - `BillingLineItem`: 结算行项（快照记录会话中各批次确认履约的服务或商品）。
  - `PaymentRecord`: 支付记录明细（支付渠道类型、外部交易号、商户单号、实付金额、支付完成时间）。
  - `CashTender`: 现金收找记录（应收现钞、实收面额、自动计算找零）。
- **值对象 (Value Objects)**:
  - `OrderId`, `SessionId`, `CashierId`
  - `Money`: 高精度金额对象（封装防精度丢失运算、四舍五入、向下抹零策略）。
  - `RoundingMode`: 抹零策略（不抹零、抹分至角、抹角至元）。
  - `CompositePaymentPlan`: 组合支付方案（储值扣减方案 + 优惠券抵扣方案 + 现金/第三方支付方案）。
- **核心业务行为 (Domain Behaviors)**:
  - `calculateReceivable(discountRules, roundingMode)`: 计算整单应收金额与优惠立减。
  - `assembleCompositePayment(CompositePaymentPlan plan)`: 校验组合金额总和必须绝对等于应收总额。
  - `executeCashSettlement(Money tenderedAmount)`: 校验现金充足性，生成现金收找流水，触发钱箱硬件信号。
  - `confirmFullPayment()`: 确认全渠道资金入账，发布 `BillingCompletedEvent`。

---

### 2.3 聚合 3：会员资产与双轨资金账户聚合根 (`MemberAssetAccount`)

构建业界严谨的**双轨储值金体系**与**计量次卡桶**，支持商户根据经营战略配置资金扣减模型。

- **聚合根 (Aggregate Root)**: `MemberAssetAccount`
- **内部实体 (Entities)**:
  - `DualBalanceAccount`: 双轨资金池（`principalBalance` 本金余额、`giftBalance` 赠送奖励金余额、`version` 乐观锁版本号）。
  - `TimeCardBucket`: 计量服务次卡桶（项目SKU、总次数、剩余有效次数、有效期截止日、适用门店范围）。
  - `CouponBucket`: 权益券包桶（满减券、折扣券、兑换券、已使用/未生效/已过期状态）。
  - `PointsAccount`: 会员积分账户（可用积分、累计积分、冻结积分）。
- **值对象 (Value Objects)**:
  - `MemberId`, `StoreId`, `CardNo`
  - `DeductMode`:
    - `PROPORTIONAL` (本金与赠送金按当前储值比例等比协同扣除)
    - `PRINCIPAL_FIRST` (优先扣除顾客实际充值本金，本金用尽后方可扣除赠送金)
- **核心业务行为 (Domain Behaviors)**:
  - `deductDualBalance(Money totalAmount, DeductMode mode)`:
    - **等比扣减算法**：计算本金比例 \( R = \frac{P}{P + G} \)，本金扣减 \( A_p = \text{round}(A \times R) \)，赠金扣减 \( A_g = A - A_p \)；
    - 执行版本号 CAS 校验，若余额不足或版本冲突立即抛出领域异常 `InsufficientBalanceException`。
  - `consumeTimeCard(skuId, times, storeId)`: 次卡核销，校验门店准入限制与有效期，原子递减次数并记录技师归属。
  - `rewardPoints(spendAmount, multiplier)`: 按实付金额计算返奖积分（支持国庆黄金周等节日活动翻倍系数）。

---

### 2.4 聚合 4：“海马体”客户常态记忆聚合根 (`CustomerHippocampusProfile`)

系统最鲜明的核心差异化能力，将客户无形的服务偏好转变为数字化结构记忆。

- **聚合根 (Aggregate Root)**: `CustomerHippocampusProfile`
- **内部实体与值对象 (Entities & VOs)**:
  - `IndustryMemorySlice`: 行业偏好记忆切片（关联美业、餐饮、汽修等具体行业）。
  - `MemoryTag`: 结构化记忆标签（标签名称、标签类别：喜好/禁忌/体质/习惯、重要等级）。
  - `ConsumptiveRhythm`: 消费律动画像（历史平均到店间隔天数、常驻门店、客单价区间、偏好技师）。
- **核心业务行为 (Domain Behaviors)**:
  - `recallProfileOnSessionOpen(memberId, industry)`: 会话开启瞬间毫秒级呼出该顾客在当前行业的全部常态偏好。
  - `upsertMemoryTags(List<MemoryTag> tags)`: 在服务开单、顾客自助注册或技师复盘时，动态丰富记忆标签库。
  - `predictNextVisitDate()`: 基于历史到店频次时间序列，智能预测下次到店周期。

---

### 2.5 聚合 5：全口径成本核算聚合根 (`CostCenterLedger`)

彻底告别传统门店记账“只算流水，不算成本”的粗放模式，打通全流程收支闭环。

- **聚合根 (Aggregate Root)**: `CostCenterLedger`
- **内部实体 (Entities)**:
  - `FixedCostItem`: 固定成本（房租、水电公摊、物业费、装修与大型设备每月折旧）。
  - `MaterialCostItem`: 原料耗材成本（收银核销时按项目 BOM 标准用量实时计提的出库成本）。
  - `LaborCostItem`: 人工薪资成本（员工当月基础底薪 + 工单施工提成实时自动累计）。
  - `MarketingCostItem`: 营销投放成本（发券补贴、团购平台抽佣、短信触达费用）。
- **核心业务行为 (Domain Behaviors)**:
  - `recordBomConsumption(BillingCompletedEvent event)`: 监听结算事件，遍历行项对应的 BOM 配方成本，自动借记物料成本科目。
  - `accrueStaffCommission(BillingCompletedEvent event)`: 自动汇算本次工单全部执行技师的提成总额，借记人工提成成本。
  - `generateProfitSummary(yearMonth)`: 汇总本月全口径营收与成本，精确产出毛利润、净利润与毛利率指标。

---

### 2.6 聚合 6：营销战役与自动化关怀聚合根 (`MarketingCampaignCare`)

以全年 12 个月作战日历为轴线，实现 365 天无感自动化客群长效经营。

- **聚合根 (Aggregate Root)**: `MarketingCampaignCare`
- **内部实体 (Entities)**:
  - `CareEventStrategy`: 自动化关怀策略（事件名称、触发时机、主题色、图标、赠送券额度、赠送积分、实物礼袋、短信模板）。
  - `MarketingCalendarNode`: 全年 12 个月营销节点（公历日期、农历日期、节假日休/班状态、二十四节气、主打营销主题）。
  - `TargetCustomerPersona`: 4 大目标客群画像（高净值名媛、都市白领、全职宝妈、年轻大学生，包含最佳联络时间与转化渠道建议）。
- **预设系统级关怀策略 (Built-in Strategies)**:
  1. **🇨🇳 国庆黄金周盛世华诞特别企划**：每年 10月1日~10月7日 自动生效，满300减60券 + 进店双倍积分 + 红运伴手礼盒 + 盛世华诞短信祝福。
  2. **🎂 会员生日专属宠粉礼遇**：会员生日当月自动发放 100元免单礼券 + 500关怀积分 + 定制生日鲜花蛋糕。
  3. **🔥 高频消费VIP忠诚回馈礼包**：当月消费满 5 次或累计满 1000 元，自动奖励 50元无门槛券 + 300积分 + 专属伴手礼。
  4. **💎 大额充值尊享礼遇**：当月单笔或累计充值满 2000 元，自动加赠 300元储值金 + 800积分 + 尊享定制礼盒。
  5. **💤 沉睡60天温情唤醒召回**：未到店满 60 天会员，每周一自动巡检派发 30元无门槛券 + 免费体验护理项目。
- **核心业务行为 (Domain Behaviors)**:
  - `executeDailyCareScan()`: 每日凌晨自动化巡检引擎，匹配规则人群，触发礼券入账与动账通知。
  - `simulateCareExecution(memberId, eventId)`: 运营人员可在后台选择真实会员立即模拟执行，实时验证发券与短信触达逻辑。

---

### 2.7 聚合 7：组织架构与一人多店执业聚合根 (`StaffOrganizationPractice`)

支持集团化连锁经营下的灵活排班、多店兼职执业与细粒度菜单权限隔离。

- **聚合根 (Aggregate Root)**: `StaffOrganizationPractice`
- **内部实体 (Entities)**:
  - `Tenant`: 顶级商户企业（开通套餐类型：体验版/专业版/旗舰版、扣减模式配置）。
  - `Store`: 执业物理门店（所属行业 7 大标准枚举 `IndustryType`：`BEAUTY` / `RESTAURANT` / `AUTO` / `RETAIL` / `FOOT_SPA` / `TEA_HOUSE` / `PET`、空间别名、附加费名称）。
  - `StaffMember`: 员工档案实体（真实姓名、手机号/账号、岗位名称、所属部门、基础底薪、提成率）。
  - `PracticeAssignment`: 多店兼职执业关系（员工允许执业的多个 `storeId` 列表、各个门店的工作台可见页签 `allowedMenuPaths`）。
  - `JobApplication`: 招聘应聘全生命周期记录（候选人信息、应聘岗位、面试时间/形式/考官、面试通知短信副本、录用决策，持久化于 `sh_job_application`）。
- **核心业务行为 (Domain Behaviors)**:
  - `authorizeMultiStorePractice(staffId, List<StoreId> stores, List<MenuPath> menus)`: 为员工授权兼职执业多店，并绑定页签权限。
  - `hireCandidateAndCreateAccount(JobApplication app)`: 候选人面试通过（`PASSED`）后，一键办理入职，系统自动依据门店行业指派部门，并创建系统登录账号（初始密码 `123456`），实现“招聘-面试-录用-开号”无缝闭环。

---

### 2.8 聚合 8：商品物料与配方 BOM 聚合根 (`ProductBomRecipe`)

统筹管理零售实物、计量服务项目以及原料耗材的标准配方定额。

- **聚合根 (Aggregate Root)**: `ProductBomRecipe`
- **内部实体与值对象**:
  - `Product`: 商品/服务主档（标牌售价、成本价、库存、默认提成金额/比例、在售状态、单位、耗时、`@Version version` 乐观锁版本号）。
  - `ProductBom`: 配方消耗原料行项（原料SKU、原料名称、标准单次消耗量、计量单位）。
  - `ProductType`: `SERVICE` (计量服务项目), `PHYSICAL` (实物零售商品/套餐载体), `MATERIAL` (BOM配方原料耗材)。
- **核心业务行为 (Domain Behaviors)**:
  - `defineBomRecipe(productId, List<ProductBom> ingredients)`: 为高附加值服务配置物料标准定额。
  - `deductIngredientsOnCheckout(productId, quantity)`: 履约/结算确认时按标准量原子扣除物料库存（含 `@Version` 乐观锁保护），若低于安全库存阈值自动上报缺货预警。

---

## 3. 防腐层设计：统一支付网关与硬件沙箱 (ACL)

### 3.1 统一支付网关防腐层 (`PaymentGatewayACL`)

采用策略模式（Strategy Pattern）与适配器模式，彻底屏蔽各第三方收单机构报文协议差异：

```
                                   +-----------------------------------------+
                                   |     统一支付防腐接口 (PaymentGateway)    |
                                   +-----------------------------------------+
                    ▲                   ▲                   ▲                   ▲
                    │                   │                   │                   │
    ┌───────────────┴──────┐ ┌──────────┴─────┐ ┌───────────┴──────┐ ┌──────────┴───────────────┐
    │ WechatPayStrategy    │ │ AlipayStrategy │ │ UnionPayStrategy │ │ Cash / StoredValue /     │
    │ (JSAPI/被扫条码)     │ │ (当面付条码)   │ │ (银联云闪付/刷卡)│ │ TimeCardPayStrategy      │
    └──────────────────────┘ └────────────────┘ └──────────────────┘ └──────────────────────────┘
```

### 3.2 独立热敏打印沙箱 (`PrintSandboxHardwareACL`)

解决浏览器原生打印控件受 Element Plus 弹窗宿主样式污染、按钮透印与断页截断的核心痛点：
- **纯净打印沙箱 (Isolated Print Sandbox)**：动态创建不可见的独立 iframe 容器，注入专用的 `@page { margin: 0; size: 80mm auto; }` 样式表；
- **真实矢量二维码生成**：使用 Base64 矢量格式，替代原伪 CSS 占位块；
- **全机型适配**：原生无缝对齐 58mm 紧凑型热敏机与 80mm 大宽幅商用热敏机；
- **硬件指令集**：支持标准 ESC/POS 连续出纸与自动切刀指令，支持收银买单时通过 RJ11 口向钱箱发送电平脉冲（`0x1B 0x70`）。

---

## 4. 核心领域事件驱动架构 (Event-Driven Architecture)

全系统通过轻量级领域事件总线实现聚合解耦与最终一致性保障：

| 领域事件 (Domain Event) | 发生源聚合 | 事件载荷核心字段 (Payload) | 订阅上下文与联动执行动作 |
| :--- | :--- | :--- | :--- |
| `SessionOpenedEvent` | `ServiceSession` | `sessionId, storeId, spaceId, memberId, openTime` | **常态记忆域**：呼出并推送客户偏好；<br>**看板展示**：更新工位状态为占用中。 |
| `ItemAppendedEvent` | `ServiceSession` | `sessionId, batchNo, items, operator` | **外设调度域**：若为餐饮，拆分后厨打印小票；<br>**BOM库存域**：预占并锁定对应原料配件。 |
| `ItemCancelledEvent` | `ServiceSession` | `sessionId, lineItemId, reason, cancelTime` | **外设调度域**：输出醒目【退菜单】；<br>**BOM库存域**：释放物料预占锁。 |
| `BillingCompletedEvent` | `BillingOrder` | `orderId, sessionId, memberId, paidAmount, items` | **会话聚合**：推进工位为待清台；<br>**资产域**：核销次卡/扣除储值并返奖积分；<br>**成本中心**：自动核算物料出库成本与员工提成；<br>**营销中心**：下发消费动账通知。 |
| `MemberRechargedEvent` | `MemberAssetAccount`| `memberId, storeId, principal, gift, payMethod` | **营销域**：校验是否满足大额充值回馈礼包；<br>**财务域**：记录充值现金流入。 |
| `CandidateHiredEvent` | `StaffOrganization` | `applicantId, phone, realName, postName, dept` | **组织域**：转正创建在册员工记录；<br>**系统账号**：自动开通登录账号并配置初始权限。 |
| `CareEventTriggeredEvent`| `MarketingCarePlan` | `eventId, memberId, couponId, pointsAwarded` | **资产账户域**：礼券与积分实时入账；<br>**通知网关**：下发个性化节日祝福短信。 |

---

## 5. 核心领域服务与应用服务界定 (Services Boundary)

为严格遵循 DDD 分层规范，杜绝贫血模型与逻辑泄漏：

- **领域服务 (Domain Services)**：
  - `DualBalanceDeductService`：处理复杂的本金与赠送金分摊计算及超扣并发校验；
  - `CostAccrualDomainService`：基于行项执行人和 BOM 清单，计算单笔工单的直接物料成本与人工提成；
  - `CareEventEvaluationService`：根据会员历史到店频次与节日规则，判定会员当前是否命中特定关怀策略。
- **应用服务 (Application Services)**：
  - `SessionCheckoutAppService`：编排会话结算全流程（获取账单 -> 锁定资产 -> 调起支付网关 -> 广播完成事件）；
  - `StaffRecruitmentAppService`：编排招聘全流程（发布岗位 -> 接收扫码简历 -> 安排面试发短信 -> 录用开通账号）；
  - `MarketingCareAutomationAppService`：驱动定时任务调度，执行全量会员日历关怀巡检。

---

## 6. 核心业务规则落地代码示例 (Production Reference)

### 6.1 双轨储值资金等比分摊与原子扣减领域实现 (Java)

```java
package com.seahorse.store.domain.member.service;

import com.seahorse.store.common.ServiceException;
import com.seahorse.store.domain.member.enums.DeductMode;
import com.seahorse.store.domain.member.model.DualBalanceAccount;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Service
public class DualBalanceDeductDomainService {

    /**
     * 核心双轨扣款领域行为：科学划分本金与赠送金扣除额度，防并发超扣
     */
    public DeductResult deduct(DualBalanceAccount account, BigDecimal totalAmount, DeductMode mode) {
        BigDecimal principal = account.getPrincipalBalance();
        BigDecimal gift = account.getGiftBalance();
        BigDecimal totalBalance = principal.add(gift);

        if (totalBalance.compareTo(totalAmount) < 0) {
            throw new ServiceException(400, String.format(
                "储值总余额不足！当前可用：￥%s (本金￥%s+赠金￥%s)，应扣：￥%s",
                totalBalance, principal, gift, totalAmount
            ));
        }

        BigDecimal deductPrincipal;
        BigDecimal deductGift;

        if (mode == DeductMode.PRINCIPAL_FIRST) {
            // 模式 A: 优先扣除充值本金
            if (principal.compareTo(totalAmount) >= 0) {
                deductPrincipal = totalAmount;
                deductGift = BigDecimal.ZERO;
            } else {
                deductPrincipal = principal;
                deductGift = totalAmount.subtract(principal);
            }
        } else {
            // 模式 B (默认推荐): 本金与赠金等比协同分摊
            // 本金比例 Ratio = P / (P + G)
            BigDecimal principalRatio = principal.divide(totalBalance, 4, RoundingMode.HALF_UP);
            deductPrincipal = totalAmount.multiply(principalRatio).setScale(2, RoundingMode.HALF_UP);
            deductGift = totalAmount.subtract(deductPrincipal);

            // 越界兜底校验
            if (deductPrincipal.compareTo(principal) > 0) {
                deductPrincipal = principal;
                deductGift = totalAmount.subtract(deductPrincipal);
            }
        }

        // 原子扣减
        account.setPrincipalBalance(principal.subtract(deductPrincipal));
        account.setGiftBalance(gift.subtract(deductGift));

        return new DeductResult(deductPrincipal, deductGift);
    }

    public record DeductResult(BigDecimal principalDeducted, BigDecimal giftDeducted) {}
}
```

### 6.2 自动化关怀策略执行与模拟测试引擎 (TypeScript / Domain Entity)

```typescript
export interface CareEventEntity {
  id: string
  title: string
  themeColor: string
  icon: string
  triggerCondition: 'NATIONAL_DAY' | 'BIRTHDAY' | 'SPRING_FESTIVAL' | 'HIGH_FREQ' | 'BIG_RECHARGE' | 'CUSTOM'
  couponAmount: number
  couponThreshold: number
  rewardPoints: number
  giftSouvenir: string
  smsTemplate: string
  isActive: boolean
}

export class MarketingCareDomainEngine {
  /**
   * 动态装配个性化短信变量
   */
  public static renderSmsMessage(template: string, member: { name: string; phone: string }, event: CareEventEntity): string {
    return template
      .replace(/\{name\}/g, member.name)
      .replace(/\{couponAmount\}/g, String(event.couponAmount))
      .replace(/\{couponThreshold\}/g, String(event.couponThreshold))
      .replace(/\{points\}/g, String(event.rewardPoints))
      .replace(/\{gift\}/g, event.giftSouvenir)
  }

  /**
   * 评估会员是否命中高频消费 VIP 回馈礼包
   */
  public static matchHighFrequencyVip(visitCountInMonth: number, spendInMonth: number): boolean {
    return visitCountInMonth >= 5 || spendInMonth >= 1000
  }
}
```

---

## 7. 架构演进与全生命周期交付保障

1. **测试数据自洽与 7 大行业隔离规范**：全系统严格根据商户设定的行业类型（`BEAUTY` 美业、`RESTAURANT` 餐饮、`AUTO` 汽修、`RETAIL` 零售、`FOOT_SPA` 足疗养生、`TEA_HOUSE` 茶馆棋牌、`PET` 宠物门店）提供自洽的默认职位、商品清单与空间别名，全流程绝无不相关业务脏数据。
2. **容灾与高可用韧性**：系统前端集成优雅离线演示兜底机制，无论在断网还是局域网单机状态下，均可无阻碍畅享完整的开单加项、会员查询与组合收银结算流程。
3. **安全审计底线**：所有针对会员资金、提成和员工账号的关键变更均产生不可篡改的日志流水，构建全链路可审计的生产级 SaaS 商业闭环。
4. **全平台原生客户端矩阵与自动化 CI/CD 交付**：
   - **Web 收银与运营工作台** (`seahorse_web_front/`): Vue 3 + Vite + TypeScript + Element Plus；
   - **Windows & macOS 原生桌面客户端** (`seahorse_desktop/`): Rust + Tauri v2，支持系统托盘常驻、多环境 API 网关切换与离线配置持久化；
   - **Android / iOS / HarmonyOS NEXT 移动端 APP** (`seahorse_app/`): Flutter 3.x 跨端架构，覆盖全平台移动开单、预约排班、考勤打卡与平台运维；
   - **顾客端微信小程序** (`seahorse_mini_program/`): 支持桌台/包厢扫码点单、在场动态追加与“海马体”会员档案自助查询；
   - **GitHub Actions 云端自动构建流水线** (`.github/workflows/build-seahorse-clients.yml`): 一键并行编译产出 Windows NSIS/MSI、macOS Universal DMG、Android APK、iOS IPA 与 HarmonyOS NEXT HAP 安装包。