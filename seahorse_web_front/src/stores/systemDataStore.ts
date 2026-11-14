import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { allIndustryPackages, beautyPackage, type CardTemplateEntity, type IndustryCode } from './industryPresets'
import {
  initTenantDemoDataApi,
  clearTenantDataApi,
  getTenantDataStatusApi,
  getTenantStoresApi,
  getSpacesApi,
  getProductsApi,
  searchMembersApi,
  getCardTemplatesApi,
  saveCardTemplateApi,
  deleteCardTemplateApi,
  getMerchantStaffListApi
} from '../api'
export type { CardTemplateEntity }

// ==============================================================================
// 1. 基础主数据类型定义 (Master Entities)
// ==============================================================================

export interface StoreEntity {
  storeId: string
  storeName: string
  address: string
  managerName: string
  phone: string
  isHeadquarter: boolean
  businessStatus: 'OPEN' | 'REST' | 'DECORATION' | 'CLOSED'
  totalSpaces: number
  openTime: string
  name?: string
  slogan?: string
  industry?: string
  industryDesc?: string
  industryCategoryName?: string
}

export interface StaffEntity {
  id: number
  storeId: string
  realName: string
  nickname?: string
  phone: string
  postName: string
  role: string
  department: string
  baseSalary: number
  serviceCommissionRate: number // 服务提成率 0.30
  cardCommissionRate: number    // 办卡充值提成率 0.10
  retailCommissionRate: number  // 零售提成率 0.15
  gender: 'MALE' | 'FEMALE'
  status: 'ACTIVE' | 'DELETED'
  entryDate: string
  // 员工系统登录账号与页签权限配置扩展
  hasSystemAccount?: boolean           // 是否开通系统登录账号
  accountUsername?: string             // 登录手机号/账号
  accountPassword?: string             // 登录密码 (默认123456)
  accountStatus?: 'ENABLED' | 'DISABLED' | 'PENDING_REVIEW' | 'REJECTED' // 账号状态
  allowedStoreIds?: string[]           // 授权可进入的多店铺列表 (支持一人在多家店铺任职)
  allowedMenuPaths?: string[]          // 授权可见和可使用的页签列表
  canCrossStore?: boolean              // 是否允许跨店漫游排班与业绩协同
  // 二维码扫码自主入职申请与审批扩展
  isSelfApplied?: boolean              // 是否为员工通过二维码扫码自主申请
  auditStatus?: 'PENDING' | 'APPROVED' | 'REJECTED' // 审批状态：待审核、已通过、已驳回
  auditTime?: string                   // 审核批准或驳回时间
  auditor?: string                     // 审核人 (店长 / 租户老板)
  rejectReason?: string                // 驳回原因说明
  experience?: string                  // 申请时填写的从业经历与个人特长
  applyTime?: string                   // 扫码自主申请提交时间
}

export interface StockLedgerRecord {
  recordNo: string
  type: 'STOCK_IN' | 'RETAIL_OUT' | 'BOM_AUTO' | 'SHELF_ON' | 'SHELF_OFF' | 'STOCK_ADJUST'
  itemName: string
  itemCode?: string
  changeQty: number
  operator: string
  time: string
  remark: string
}

export interface SystemMenuOption {
  path: string
  name: string
  icon: string
  category: 'FRONT_DESK' | 'CUSTOMER_MKT' | 'GOODS_SUPPLY' | 'FINANCE_LEDGER' | 'STORE_ADMIN'
  categoryName: string
  description: string
}

export const allSystemMenus: SystemMenuOption[] = [
  // 1. 门店前台
  { path: '/dashboard', name: '系统首页', icon: 'Odometer', category: 'FRONT_DESK', categoryName: '门店前台', description: '营收概览、空间工位在场动态与快捷买单' },
  { path: '/rooms', name: '包厢', icon: 'House', category: 'FRONT_DESK', categoryName: '门店前台', description: '包厢、台位、雅座与工位空间管理，支持灵活增删改查、区域划分与点单码' },
  { path: '/appointments', name: '预约排班', icon: 'Calendar', category: 'FRONT_DESK', categoryName: '门店前台', description: '顾客预约排班与到店核销登记' },
  // 2. 客源营销
  { path: '/members', name: '会员中心', icon: 'User', category: 'CUSTOMER_MKT', categoryName: '客源营销', description: '会员开卡、充值、记忆档案与资产明细' },
  { path: '/card-template', name: '会员卡包', icon: 'CreditCard', category: 'CUSTOMER_MKT', categoryName: '客源营销', description: '储值卡、次卡与权益卡面及规则制定' },
  { path: '/marketing', name: '营销裂变', icon: 'TrendCharts', category: 'CUSTOMER_MKT', categoryName: '客源营销', description: '优惠券、拼团砍价与老带新裂变策略' },
  { path: '/mall', name: '微商城', icon: 'Shop', category: 'CUSTOMER_MKT', categoryName: '客源营销', description: '24小时线上自营商城与发货订单处理' },
  // 3. 货品物资
  { path: '/products', name: '项目商品', icon: 'Goods', category: 'GOODS_SUPPLY', categoryName: '货品物资', description: '服务项目、实物零售与耗材配方清单' },
  { path: '/inventory', name: '物料库存', icon: 'Box', category: 'GOODS_SUPPLY', categoryName: '货品物资', description: '实时库存台账、采购进货、上下架状态与核销流水' },
  // 4. 财务核算
  { path: '/expenses', name: '门店账本', icon: 'Money', category: 'FINANCE_LEDGER', categoryName: '财务核算', description: '记日常开销流水，算全口径成本结构与开销排行榜' },
  { path: '/reports', name: '统计报表', icon: 'DataAnalysis', category: 'FINANCE_LEDGER', categoryName: '财务核算', description: '11大财务利润、扣卡消费与提成报表' },
  // 5. 店务管控
  { path: '/staff-management', name: '员工管理', icon: 'UserFilled', category: 'STORE_ADMIN', categoryName: '店务管控', description: '员工档案、薪资提成与登录账号授权' },
  { path: '/regulations', name: '规章制度', icon: 'Document', category: 'STORE_ADMIN', categoryName: '店务管控', description: '门店规章制度发布、电子签字签署追踪、海报与PDF导出及员工意见建议箱' },
  { path: '/chain', name: '连锁管理', icon: 'OfficeBuilding', category: 'STORE_ADMIN', categoryName: '店务管控', description: '多店协同、资金池漫游与分店开设' },
  { path: '/sms-records', name: '短信管理', icon: 'Message', category: 'CUSTOMER_MKT', categoryName: '客源营销', description: '短信发送流水明细、网关签名配置与资源加油包' },
  { path: '/settings', name: '系统设置', icon: 'Setting', category: 'STORE_ADMIN', categoryName: '店务管控', description: '门店资料、岗位职责描述与小票打印' },
  { path: '/profile', name: '个人中心', icon: 'Avatar', category: 'STORE_ADMIN', categoryName: '店务管控', description: '个人账号信息与安全设置' }
]

// ==============================================================================
// 门店规章制度、电子签名与员工意见箱类型定义
// ==============================================================================
export interface RegulationSignature {
  staffId: number | string
  staffName: string
  phone?: string
  postName?: string
  signatureDataUrl: string // base64 手写签名图片
  signedAt: string        // 签署时间
  deviceInfo?: string     // 签署终端设备标识
}

export interface RegulationEntity {
  id: string              // 如 "REG-2026-001"
  storeId: string         // 'ALL' 或具体门店ID
  title: string           // 制度标题
  category: 'ATTENDANCE' | 'SERVICE' | 'SAFETY' | 'COMMISSION' | 'CONFIDENTIAL' | 'OTHER'
  categoryName: string    // 考勤考纪、服务礼仪、安全卫生、奖惩考核、保密协议、综合制度
  summary: string         // 制度核心摘要
  content: string         // 完整规章制度条款正文
  keyPoints: string[]     // 核心红线要点速览（海报与宣传展示）
  version: string         // 版本号 (如 "V2.0")
  effectiveDate: string   // 生效日期
  status: 'PUBLISHED' | 'DRAFT' | 'ARCHIVED' // 状态：已发布、草稿、已归档
  requireSignature: boolean // 是否强制要求员工电子签字
  publisher: string       // 发布人 (店长 / 租户)
  publishTime: string     // 发布时间
  readStaffIds: (number | string)[] // 已查阅员工ID列表
  signatures: RegulationSignature[] // 员工电子签名签署记录
}

export interface StaffFeedbackEntity {
  id: string              // 如 "FB-2026-001"
  storeId: string         // 门店ID
  regulationId?: string   // 关联的制度ID（可选）
  regulationTitle?: string// 关联的制度标题
  staffId?: number | string // 员工ID (匿名时为空)
  staffName: string       // 员工姓名 (匿名时为 "匿名员工")
  isAnonymous: boolean    // 是否匿名提交
  type: 'SUGGESTION' | 'DIFFICULTY' | 'APPEAL' | 'INNOVATION' // 改进建议、执行困难、申诉反馈、创新提案
  typeName: string
  priority: 'NORMAL' | 'URGENT' // 一般、紧急
  title: string           // 建议标题
  content: string         // 详细内容
  createdAt: string       // 提交时间
  // 店长/租户答复处理
  status: 'PENDING' | 'ACCEPTED' | 'IMPLEMENTED' | 'EXPLAINED' | 'REJECTED' // 待处理、已采纳、已落地改进、解释说明、不予采纳
  replyContent?: string   // 官方回复内容
  replyTime?: string      // 回复时间
  replierName?: string    // 答复人 (店长 / 租户)
}

// ==============================================================================
// 全平台非研发人员向研发团队建言反馈类型定义
// ==============================================================================
export interface PlatformFeedbackEntity {
  id: string              // 如 "PFB-2026-001"
  tenantId: string        // 提交租户ID，如 "T001"
  tenantName: string      // 租户名称，如 "海马智慧商业"
  storeName: string       // 门店名称，如 "丝艺美学·旗舰店"
  staffName: string       // 提交人真实姓名，如 "托尼"
  role: string            // 角色标识，如 "TECHNICIAN", "STORE_MANAGER", "CASHIER", "SUPER_ADMIN"
  roleName: string        // 角色名称，如 "美业总监", "店长", "收银主管", "门店老板"
  phone?: string          // 联系电话
  type: 'FEATURE_REQUEST' | 'EXPERIENCE_OPT' | 'BUG_REPORT' | 'BUSINESS_IDEA' // 功能需求、体验优化、缺陷Bug、商业方案
  typeName: string
  module: string          // 所涉功能模块，如 "门店前台", "客源营销", "规章协同", "收银结算", "统计报表"
  title: string           // 建议或需求标题
  content: string         // 详细描述与场景期望
  urgency: 'LOW' | 'NORMAL' | 'HIGH' // 期望紧急度
  createdAt: string       // 提交时间
  status: 'PENDING' | 'EVALUATING' | 'SCHEDULED' | 'IMPLEMENTED' | 'REJECTED' | 'PROCESSING' | 'ACCEPTED' | 'RESOLVED' // 待受理、方案评估中、已排期入版本、已上线交付、暂不考虑
  devReply?: string       // 研发团队官方答复
  devReplier?: string     // 研发受理人员
  replyTime?: string      // 答复时间
  replyAt?: string        // 答复时间兼容字段
  targetVersion?: string  // 规划上线版本号，如 "V2.4"
}

// ==============================================================================
// 租户活动日志与白天使用时段采集指标模型
// ==============================================================================
export interface TenantActivityLog {
  id: string              // 如 "LOG-20260909-001"
  tenantId: string        // 如 "T001"
  tenantName: string      // 如 "丝艺美学·海马美业"
  storeName: string       // 如 "天河总院旗舰店"
  operatorName: string    // 如 "赵雪(收银主管)"
  operatorRole: string    // 如 "CASHIER"
  module: string          // 业务模块，如 "收银结算", "空间工位", "会员充值", "预约排班", "物料盘点"
  action: string          // 行为动作，如 "工位完成买单", "会员次卡扣核销", "新增顾客预约", "调价审批"
  detail: string          // 审计明细
  timestamp: string       // 时间戳
  timeSlot: 'MORNING' | 'NOON' | 'AFTERNOON' | 'EVENING' | 'NIGHT' // 08:00-11:30, 11:30-14:00, 14:00-18:00, 18:00-22:00, 22:00-08:00
  timeSlotName: string    // 时段中文名称
  isDaytime: boolean      // 是否白天营业时段 (08:00 - 22:00)
  ip: string              // 客户端IP
  device: string          // 客户端环境
}

export interface TenantDaytimeUsageStat {
  tenantId: string
  tenantName: string
  industry: string
  industryName: string
  daytimeTotalOps: number      // 白天操作总频次
  morningOps: number          // 早高峰 (08:00-11:30) 频次
  noonOps: number             // 午间营业 (11:30-14:00) 频次
  afternoonOps: number        // 下午黄金 (14:00-18:00) 频次
  eveningOps: number          // 晚间夜市 (18:00-22:00) 频次
  nightOps: number            // 夜间闲时 (22:00-08:00) 频次
  peakTimeSlot: string        // 白天最密集高峰时段
  peakTimeReason: string      // 峰值业务特征描述
  activityIndex: number       // 综合活跃指数 (1-100)
  primaryModule: string       // 日间最常用模块
}

export interface BomItem {
  materialId: string
  materialName: string
  unitUsage?: number
  dosage?: number
  consumeQuantity?: number
  unit: string
  costPerUnit: number
}

export interface ProductEntity {
  id: number
  code: string
  name: string
  type: 'SERVICE' | 'RETAIL' | 'PACKAGE'
  category: string
  categoryName: string
  price: number
  memberPrice?: number
  cost: number // 物料BOM成本或采购成本
  stock?: number
  commissionRate?: number
  durationMinutes?: number
  boms?: BomItem[]
  unit: string
  spec?: string
  status?: 'ACTIVE' | 'DISABLED'
  description?: string
  hasBom?: boolean
  isSyncMall?: boolean // 是否同步发布到线上微商城
}

export interface MallGoodsEntity {
  id: number
  productId?: number           // 关联门店项目商品库ID (若从商品库同步)
  productCode?: string         // 关联商品编码
  title: string                // 商城在售商品标题
  category: string             // 所属类目
  onlinePrice: number          // 微商城线上特惠售价
  originalPrice: number        // 划线原价
  stock: number                // 线上库存配额
  sales: number                // 线上累计销量
  onShelf: boolean             // 上架/下架开关
  isHot?: boolean              // 是否标记为商城热销爆款
  deliveryType: 'EXPRESS' | 'STORE_PICKUP' | 'BOTH' // 配送/核销方式：快递发货 / 到店核销 / 两者兼备
  coverIcon?: string           // 商品封面图标
  description?: string         // 线上商品亮点图文说明
  syncTime?: string            // 上架/同步时间
  syncSource?: 'STORE_PRODUCT' | 'MALL_EXCLUSIVE' // 同步来源：门店商品库同步 / 线上商城专营
}

export interface MallOrderEntity {
  orderNo: string
  productTitle: string
  price: number
  quantity: number
  totalAmount: number
  buyerName: string
  buyerPhone: string
  deliveryType: 'EXPRESS' | 'STORE_PICKUP'
  orderTime: string
  status: 'WAIT_PAY' | 'PAID' | 'DELIVERED' | 'COMPLETED'
  expressCompany?: string
  trackingNo?: string
}

export interface MaterialEntity {
  id: string
  code: string
  name: string
  category: 'RAW' | 'RETAIL' | 'TOOL'
  unit: string
  costPrice: number
  initialStock: number
  safeStock: number
  supplier: string
}

export interface MemberEntity {
  id: number
  memberNo: string
  name: string
  phone: string
  gender: 'MALE' | 'FEMALE'
  level: string
  levelName: string
  registeredStoreId: string
  referrerId?: number // 推荐人ID (老客带新客)
  registerTime: string
  avatar?: string
  isTrial?: boolean
  birthday?: string
  habits?: string[]
  preferences?: Array<{
    id: number | string
    category: string
    tagKey: string
    tagValue: string
    notes?: string
  }>
  notes?: string
  tenantId?: string
  totalSpent?: number
  visitCount?: number
  consumeCount?: number
  daysSinceLastVisit?: number
  points?: number
  principalBalance?: number
  giftBalance?: number
}

export interface CouponItem {
  id: string
  couponNo: string
  name: string
  type: 'CASH_REDUCE' | 'EXPERIENCE' | 'PERCENT'
  amount: number
  minSpend: number
  serviceScope: string
  validDays: number
  expireDate: string
  status: 'UNUSED' | 'USED' | 'EXPIRED'
}

// ==============================================================================
// 2. 业务事件交易账本流水类型定义 (Transaction Ledgers)
// ==============================================================================

export interface RechargeOrder {
  id: number
  orderNo: string
  memberId: number
  storeId: string
  sellerEmployeeId: number
  principalAmount: number
  giftAmount: number
  paymentMethod: 'WECHAT' | 'ALIPAY' | 'OFFLINE'
  pointsGiven: number
  createTime: string
  status: 'COMPLETED'
}

export interface OrderItem {
  productId: number
  productName: string
  type: 'SERVICE' | 'RETAIL'
  price: number
  quantity: number
  bomCost: number
}

export interface ConsumeOrder {
  id: number
  orderNo: string
  memberId: number
  storeId: string
  primaryTechnicianId: number
  assistantTechnicianId?: number
  cashierEmployeeId: number
  items: OrderItem[]
  totalAmount: number // 原价
  couponDiscount: number // 优惠券抵扣
  couponId?: string
  cardDeductPrincipal: number // 划扣储值本金
  cardDeductGift: number // 划扣储值赠送金
  timeCardDeductTimes?: number // 划扣次卡次数
  cashierPaidAmount: number // 现金/微信/支付宝实付差价
  paymentMethod: 'WECHAT' | 'ALIPAY' | 'OFFLINE' | 'DUAL_CARD' | 'TIME_CARD' | 'CASH' | 'STORED_VALUE' | 'MIXED'
  pointsEarned: number
  pointsBurned: number
  createTime: string
  status: 'COMPLETED' | 'SERVING' | 'REFUNDED' | 'PAID'
  sessionId?: number
  spaceName?: string
  type?: string
  payAmount?: number
}

export interface PointsLog {
  id: number
  memberId: number
  type: 'RECHARGE_GIFT' | 'CONSUME_EARN' | 'CASHIER_BURN' | 'MANUAL_ADJUST'
  typeName: string
  pointsDelta: number
  balanceAfter: number
  operator: string
  createTime: string
}

export interface RewardLog {
  id: number
  memberId: number // 受益会员 (老客)
  referredMemberId: number // 被推荐会员 (新客)
  reason: string
  rewardDelta: number
  balanceAfter: number
  createTime: string
}

export interface TimeCardItem {
  id: number
  memberId: number
  skuId: number
  cardName: string
  totalTimes: number
  usedTimes: number
  unitPrice: number
  expireDate: string
  remainingTimes?: number
}

export interface ExpenseRecord {
  id: number
  expenseNo?: string
  storeId: string
  category: 'RENT' | 'SUPPLY' | 'SALARY' | 'MARKETING' | 'OTHER'
  categoryName: string
  title: string
  amount: number
  date: string
  handler: string
  note: string
}

export interface AppointmentRecord {
  id: number
  aptNo: string
  memberId: number
  memberName: string
  phone: string
  storeId: string
  technicianId: number
  technicianName: string
  productId: number
  productName: string
  date: string
  timeSlot: string
  status: 'PENDING' | 'SERVING' | 'COMPLETED' | 'CANCELLED'
}

export interface CampaignEntity {
  id: number
  name: string
  type: 'COUPON' | 'GROUP' | 'REFERRAL' | 'POINTS'
  ruleDesc: string
  participateCount: number
  revenueBrought: number
  validRange: string
  status: 'RUNNING' | 'FINISHED'
  badgeText?: string
  discountHighlight?: string
}

export interface SpaceEntity {
  id: number
  storeId: string
  spaceCode: string
  spaceName: string
  spaceType: 'ROOM' | 'TABLE' | 'MIRROR' | 'BAY'
  status: 'IDLE' | 'OCCUPIED' | 'DIRTY' | 'MAINTENANCE'
  capacity: number
  floorZone: string
  minConsumeAmount?: number
  hourlyFee?: number
  facilities?: string[]
  notes?: string
  sortOrder?: number
  qrCodeUrl?: string
  currentSessionId?: number | null
}

export interface LiveSession {
  id: number
  spaceId: number
  spaceName: string
  sessionNo: string
  customerName: string
  customerPhone: string
  memberId: number
  startTime: string
  totalAmount: number
  status: 'SERVING' | 'WAIT_CLEAN' | 'COMPLETED'
  items?: Array<{ name: string; price: number; qty: number }>
}

export interface CostItemEntity {
  id: number
  code: string
  name: string
  category: 'LABOR' | 'MATERIAL' | 'RENT_UTILITY' | 'MARKETING' | 'DEPRECIATION' | 'ADMIN_MISC'
  categoryName: string
  nature: 'FIXED' | 'VARIABLE' // 固定成本 vs 变动成本
  amount: number
  month: string // 例如: '2026-09'
  date: string  // 例如: '2026-09-06'
  storeId: string
  handler: string // 经办人
  invoiceNo?: string // 发票/报销凭证号
  notes?: string // 备注说明
  isAutoSync?: boolean // 是否为系统根据员工薪酬/流水全自动核算同步项
  autoSyncType?: 'SALARY_BASE' | 'SALARY_COMMISSION' | 'MATERIAL_BOM'
}

export interface ReceiptTemplateConfig {
  paperWidth: '58mm' | '80mm'
  fontSize: 'compact' | 'standard' | 'large'
  autoPrint: boolean

  // 1. 抬头与品牌标识 (Header & Brand)
  showStoreHeader: boolean
  storeHeaderTitle: string
  showHeaderSubtitle: boolean
  headerSubTitle: string
  showTicketTitle: boolean
  ticketTitle: string

  // 2. 单据与客显元数据 (Order Meta)
  showOrderNo: boolean
  showCheckoutTime: boolean
  showCashierName: boolean
  showTechnician: boolean
  showCustomerName: boolean
  showCustomerPhone: boolean
  maskCustomerPhone: boolean

  // 3. 消费项目清单 (Items Breakdown)
  showItemsTable: boolean
  showItemQty: boolean
  showItemPrice: boolean
  showItemSum: boolean

  // 4. 金额结算与支付明细 (Calculations & Payments)
  showOriginalPrice: boolean
  showDiscount: boolean
  showActualAmount: boolean
  showPayMethods: boolean

  // 5. 会员双轨储值与资产积分 (Member Assets)
  showMemberAssetSection: boolean
  showPrincipalBalance: boolean
  showGiftBalance: boolean
  showEarnedPoints: boolean
  showTotalPoints: boolean

  // 6. 页脚致谢、服务与二维码 (Footer & Services)
  showFooterNotes: boolean
  footerNotes: string
  showServiceHotline: boolean
  serviceHotline: string
  showStoreAddress: boolean
  storeAddress: string
  showQrCode: boolean
  qrCodeText: string
  qrCodeHint: string

  // 7. 租户留存与顾客签字联 (Signature Stub)
  showSignStub: boolean
  showStubOrderMeta: boolean
  showStubSignLine: boolean
}

export interface AttendanceRecordEntity {
  id: string
  staffName: string
  phone: string
  postName: string
  workDate: string
  checkInTime: string
  checkInStatus: 'NORMAL' | 'LATE' | 'ABSENT' | 'FIELD_WORK'
  checkOutTime: string
  checkOutStatus: 'NORMAL' | 'EARLY' | 'NOT_CHECKED'
  workHours: number
  checkInLocation: string
  platformSource: 'WECHAT_WORK' | 'DINGTALK' | 'ATTENDANCE_MACHINE' | 'APP_MOBILE'
  notes?: string
}

export interface LeaveApplicationEntity {
  id: string
  staffId: number | string
  staffName: string
  phone: string
  postName: string
  department: string
  leaveType: 'PERSONAL' | 'SICK' | 'ANNUAL' | 'COMPENSATORY' | 'MARRIAGE' | 'MATERNITY' | string
  leaveTypeName: string
  startTime: string
  endTime: string
  totalHours: number
  totalDays: number
  reason: string
  status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'REVOKED'
  applyTime: string
  currentApprover: string
  auditTime?: string
  auditNotes?: string
  timeline: Array<{
    stepName: string
    operator: string
    time: string
    status: 'SUCCESS' | 'CURRENT' | 'PENDING' | 'REJECTED'
    comment?: string
  }>
}

export const buildMemberBenefitsUrl = (storeId?: string) => {
  const effectiveStoreId = storeId || (typeof localStorage !== 'undefined' ? localStorage.getItem('seahorse_store_id') : '') || 'S001'
  if (typeof window !== 'undefined' && window.location) {
    const protocol = window.location.protocol || 'http:'
    const host = window.location.host || 'fwpt.cn'
    return `${protocol}//${host}/seahorse/member-benefits?storeId=${encodeURIComponent(effectiveStoreId)}`
  }
  return `https://fwpt.cn/seahorse/member-benefits?storeId=${encodeURIComponent(effectiveStoreId)}`
}

const defaultReceiptConfig: ReceiptTemplateConfig = {
  paperWidth: '80mm',
  fontSize: 'standard',
  autoPrint: true,

  // 1. 抬头
  showStoreHeader: true,
  storeHeaderTitle: '',
  showHeaderSubtitle: true,
  headerSubTitle: '海马智慧连锁 · 竭诚为您提供至臻服务',
  showTicketTitle: true,
  ticketTitle: '顾客结账消费明细清单',

  // 2. 单据与客显
  showOrderNo: true,
  showCheckoutTime: true,
  showCashierName: true,
  showTechnician: true,
  showCustomerName: true,
  showCustomerPhone: true,
  maskCustomerPhone: true,

  // 3. 项目清单
  showItemsTable: true,
  showItemQty: true,
  showItemPrice: true,
  showItemSum: true,

  // 4. 金额与支付
  showOriginalPrice: true,
  showDiscount: true,
  showActualAmount: true,
  showPayMethods: true,

  // 5. 双轨储值与积分
  showMemberAssetSection: true,
  showPrincipalBalance: true,
  showGiftBalance: true,
  showEarnedPoints: true,
  showTotalPoints: true,

  // 6. 页脚致谢
  showFooterNotes: true,
  footerNotes: '凭此小票享服务售后支持与会员权益保障，感谢您的惠顾！',
  showServiceHotline: true,
  serviceHotline: '',
  showStoreAddress: true,
  storeAddress: '',
  showQrCode: true,
  qrCodeText: 'http://fwpt.cn/member/benefits',
  qrCodeHint: '扫码进入会员微商城 / 查看店铺信息与会员专属权益',

  // 7. 留存签字联
  showSignStub: true,
  showStubOrderMeta: true,
  showStubSignLine: true
}


// ==============================================================================
// 扫码盒子硬件与聚合支付通道配置 (路线 1: 个体户直连 / 路线 2: 小微租户 / 路线 3: 支付宝沙箱)
// ==============================================================================
export type PaymentRouteType = 'ROUTE_1_INDIVIDUAL' | 'ROUTE_2_AGGREGATE' | 'ROUTE_3_SANDBOX'

export interface PaymentChannelConfig {
  activeRoute: PaymentRouteType
  scanBox: {
    enabled: boolean
    keyIntervalThresholdMs: number
    autoCheckoutOnPaymentCode: boolean
    beepEnabled: boolean
    lastScannedCode: string
    lastScannedType: string
    lastScannedAt: string
  }
  route1_individual: {
    businessLicenseNo: string
    merchantName: string
    legalPerson: string
    wechat: {
      mchId: string
      apiKeyV3: string
      serialNo: string
      privateKey: string
      notifyUrl: string
      feeRate: string
    }
    alipay: {
      appId: string
      appPrivateKey: string
      alipayPublicKey: string
      signType: 'RSA2'
      gateway: string
      feeRate: string
    }
  }
  route2_aggregate: {
    provider: 'SHOUQIANBA' | 'LAKALA' | 'FUIOU' | 'CHINA_UMS'
    providerName: string
    subMchId: string
    terminalId: string
    serviceProviderKey: string
    settlementBankCard: string
    dailyLimit: number
    feeRate: string
  }
  route3_sandbox: {
    sandboxAppId: string
    sandboxGateway: string
    sandboxPrivateKey: string
    sandboxPublicKey: string
    signType: 'RSA2'
    testBuyerAccount: string
    testBuyerPassword: string
    testBuyerPayPassword: string
    virtualBalance: number
  }
}

export const defaultPaymentConfig: PaymentChannelConfig = {
  activeRoute: 'ROUTE_3_SANDBOX',
  scanBox: {
    enabled: true,
    keyIntervalThresholdMs: 50,
    autoCheckoutOnPaymentCode: true,
    beepEnabled: true,
    lastScannedCode: '6920182736192',
    lastScannedType: 'PRODUCT',
    lastScannedAt: '2026-09-09 22:00:00'
  },
  route1_individual: {
    businessLicenseNo: '92310115MA1K89762X',
    merchantName: '海马智慧美业生活馆 (个体工租户)',
    legalPerson: '张建华',
    wechat: {
      mchId: '1609823451',
      apiKeyV3: 'f78a83d76e21b84920c812d4a51e6790',
      serialNo: '4C98234B98E710283746D298104E982B',
      privateKey: '-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC69...\n-----END PRIVATE KEY-----',
      notifyUrl: 'https://api.seahorse-pos.com/pay/notify/wechat',
      feeRate: '0.38%'
    },
    alipay: {
      appId: '2021003124567890',
      appPrivateKey: 'MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQD72...\n-----END PRIVATE KEY-----',
      alipayPublicKey: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAx49...',
      signType: 'RSA2',
      gateway: 'https://openapi.alipay.com/gateway.do',
      feeRate: '0.38%'
    }
  },
  route2_aggregate: {
    provider: 'SHOUQIANBA',
    providerName: '收钱吧 (持牌聚合支付服务商)',
    subMchId: 'ME1009827364',
    terminalId: 'SQB-POS-882190',
    serviceProviderKey: 'sqb_sec_99a8b7c6d5e4f3a2b10987654321fedc',
    settlementBankCard: '6222 0210 0102 8888 (中国工商银行)',
    dailyLimit: 50000,
    feeRate: '0.38%'
  },
  route3_sandbox: {
    sandboxAppId: '9021000133682914',
    sandboxGateway: 'https://openapi-sandbox.dl.alipaydev.com/gateway.do',
    sandboxPrivateKey: 'MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC98a...SANDBOX_KEY',
    sandboxPublicKey: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu81...SANDBOX_PUB',
    signType: 'RSA2',
    testBuyerAccount: 'alipay_buyer_sandbox01@sandbox.com',
    testBuyerPassword: '111111',
    testBuyerPayPassword: '111111',
    virtualBalance: 999999
  }
}

export function deepMergePaymentConfig(base: PaymentChannelConfig, custom?: any): PaymentChannelConfig {
  if (!custom) return JSON.parse(JSON.stringify(base))
  return {
    ...base,
    ...custom,
    scanBox: {
      ...base.scanBox,
      ...(custom.scanBox || {})
    },
    route1_individual: {
      ...base.route1_individual,
      ...(custom.route1_individual || {}),
      wechat: {
        ...base.route1_individual.wechat,
        ...(custom.route1_individual?.wechat || {})
      },
      alipay: {
        ...base.route1_individual.alipay,
        ...(custom.route1_individual?.alipay || {})
      }
    },
    route2_aggregate: {
      ...base.route2_aggregate,
      ...(custom.route2_aggregate || {})
    },
    route3_sandbox: {
      ...base.route3_sandbox,
      ...(custom.route3_sandbox || {})
    }
  }
}

const initialAttendanceList: AttendanceRecordEntity[] = [
  {
    id: 'ATT-20260907-01',
    staffName: '张建华',
    phone: '13811112222',
    postName: '旗舰店店长',
    workDate: '2026-09-07',
    checkInTime: '08:52:14',
    checkInStatus: 'NORMAL',
    checkOutTime: '21:05:30',
    checkOutStatus: 'NORMAL',
    workHours: 12.2,
    checkInLocation: '门店Wi-Fi (Seahorse_Store_5G)',
    platformSource: 'WECHAT_WORK',
    notes: '准时到岗，早会主持'
  },
  {
    id: 'ATT-20260907-02',
    staffName: '托尼',
    phone: '13900001111',
    postName: '发型总监/主理人',
    workDate: '2026-09-07',
    checkInTime: '09:12:00',
    checkInStatus: 'LATE',
    checkOutTime: '21:30:00',
    checkOutStatus: 'NORMAL',
    workHours: 12.3,
    checkInLocation: '门店蓝牙考勤机',
    platformSource: 'DINGTALK',
    notes: '迟到12分钟，客户加急定制造型'
  },
  {
    id: 'ATT-20260907-03',
    staffName: '李博',
    phone: '13700002222',
    postName: '资深设计师',
    workDate: '2026-09-07',
    checkInTime: '08:58:30',
    checkInStatus: 'NORMAL',
    checkOutTime: '21:02:18',
    checkOutStatus: 'NORMAL',
    workHours: 12.0,
    checkInLocation: '门店Wi-Fi (Seahorse_Store_5G)',
    platformSource: 'WECHAT_WORK',
    notes: '准时打卡'
  },
  {
    id: 'ATT-20260907-04',
    staffName: '王芳',
    phone: '13600003333',
    postName: '美容美发顾问',
    workDate: '2026-09-07',
    checkInTime: '08:50:10',
    checkInStatus: 'NORMAL',
    checkOutTime: '18:00:20',
    checkOutStatus: 'NORMAL',
    workHours: 9.1,
    checkInLocation: '门店Wi-Fi (Seahorse_Store_5G)',
    platformSource: 'WECHAT_WORK',
    notes: '准时打卡'
  },
  {
    id: 'ATT-20260907-05',
    staffName: '陈明强',
    phone: '13966668888',
    postName: '高级顾问 (兼职)',
    workDate: '2026-09-07',
    checkInTime: '13:25:40',
    checkInStatus: 'FIELD_WORK',
    checkOutTime: '18:35:10',
    checkOutStatus: 'NORMAL',
    workHours: 5.1,
    checkInLocation: '广州正佳广场外勤打卡 (GPS定位)',
    platformSource: 'DINGTALK',
    notes: '兼职顾问外勤，附实地打卡现场照'
  }
]

const initialLeaveList: LeaveApplicationEntity[] = [
  {
    id: 'LV-20260907001',
    staffId: 2,
    staffName: '托尼',
    phone: '13900001111',
    postName: '发型总监/主理人',
    department: '美业设计部',
    leaveType: 'ANNUAL',
    leaveTypeName: '带薪年假',
    startTime: '2026-09-08 09:00',
    endTime: '2026-09-08 22:00',
    totalHours: 12.0,
    totalDays: 1.0,
    reason: '参加巴黎欧莱雅秋冬时尚美发造型发布研习会',
    status: 'PENDING',
    applyTime: '2026-09-07 14:20',
    currentApprover: '张建华 (店长)',
    timeline: [
      { stepName: '提交请假申请', operator: '托尼', time: '2026-09-07 14:20', status: 'SUCCESS', comment: '事由：参加巴黎欧莱雅秋冬研习会' },
      { stepName: '门店店长审批', operator: '张建华 (店长)', time: '', status: 'CURRENT', comment: '待店长审核在手预约交接' },
      { stepName: '人事考勤归档', operator: '集团人事', time: '', status: 'PENDING', comment: '等待上级审批通过' }
    ]
  },
  {
    id: 'LV-20260905001',
    staffId: 4,
    staffName: '王芳',
    phone: '13600003333',
    postName: '美容美发顾问',
    department: '前台客服部',
    leaveType: 'COMPENSATORY',
    leaveTypeName: '加班调休',
    startTime: '2026-09-05 14:00',
    endTime: '2026-09-05 18:00',
    totalHours: 4.0,
    totalDays: 0.5,
    reason: '上周周末全天加班筹办秋季VIP答谢会，申请半天调休',
    status: 'APPROVED',
    applyTime: '2026-09-04 18:10',
    currentApprover: '张建华 (店长)',
    auditTime: '2026-09-04 19:30',
    auditNotes: '已核对上周加班考勤打卡记录，同意调休，前台工作交由赵雪代理',
    timeline: [
      { stepName: '提交请假申请', operator: '王芳', time: '2026-09-04 18:10', status: 'SUCCESS', comment: '申请半天调休' },
      { stepName: '门店店长审批', operator: '张建华 (店长)', time: '2026-09-04 19:30', status: 'SUCCESS', comment: '已核对上周加班记录，同意调休' },
      { stepName: '人事考勤归档', operator: '系统自动归档', time: '2026-09-04 19:31', status: 'SUCCESS', comment: '已从调休假余额中核扣4小时' }
    ]
  }
]

// ==============================================================================
// 3. 初始实体测试基准数据 (具有完整真实业务拓扑)
// ==============================================================================

const initialStores: StoreEntity[] = [
  {
    storeId: 'S001',
    storeName: '海马智慧门店 (旗舰体验中心)',
    address: '广州市天河区天河路208号粤海天河城4楼',
    managerName: '张建华',
    phone: '020-88996611',
    isHeadquarter: true,
    businessStatus: 'OPEN',
    totalSpaces: 8,
    openTime: '10:00 - 22:00'
  },
  {
    storeId: 'S002',
    storeName: '海马天河城品牌概念店',
    address: '广州市天河区天河路123号正佳广场3楼',
    managerName: '李美华',
    phone: '020-88996622',
    isHeadquarter: false,
    businessStatus: 'OPEN',
    totalSpaces: 6,
    openTime: '10:00 - 22:00'
  },
  {
    storeId: 'S003',
    storeName: '海马万象城轻奢定制店',
    address: '深圳市罗湖区宝安南路1881号万象城B1层',
    managerName: '王大伟',
    phone: '0755-82289900',
    isHeadquarter: false,
    businessStatus: 'OPEN',
    totalSpaces: 6,
    openTime: '10:00 - 22:00'
  }
]

const initialStaff: StaffEntity[] = [
  {
    id: 1,
    storeId: 'S001',
    realName: '张建华',
    phone: '13811112222',
    postName: '旗舰店店长',
    role: 'STORE_MANAGER',
    department: '门店运营部',
    baseSalary: 8000,
    serviceCommissionRate: 0.15,
    cardCommissionRate: 0.05,
    retailCommissionRate: 0.10,
    gender: 'MALE',
    status: 'ACTIVE',
    entryDate: '2025-03-01'
  },
  {
    id: 2,
    storeId: 'S001',
    realName: '托尼',
    phone: '13900001111',
    postName: '发型总监/主理人',
    role: 'TECHNICIAN',
    department: '美业设计部',
    baseSalary: 5500,
    serviceCommissionRate: 0.30,
    cardCommissionRate: 0.10,
    retailCommissionRate: 0.15,
    gender: 'MALE',
    status: 'ACTIVE',
    entryDate: '2025-04-15'
  },
  {
    id: 3,
    storeId: 'S001',
    realName: '李博',
    phone: '13700002222',
    postName: '资深发型师',
    role: 'TECHNICIAN',
    department: '美业设计部',
    baseSalary: 4500,
    serviceCommissionRate: 0.25,
    cardCommissionRate: 0.08,
    retailCommissionRate: 0.12,
    gender: 'MALE',
    status: 'ACTIVE',
    entryDate: '2025-06-01'
  },
  {
    id: 4,
    storeId: 'S001',
    realName: '王芳',
    phone: '13600003333',
    postName: '美容美发顾问',
    role: 'TECHNICIAN',
    department: '技术服务部',
    baseSalary: 4000,
    serviceCommissionRate: 0.20,
    cardCommissionRate: 0.10,
    retailCommissionRate: 0.15,
    gender: 'FEMALE',
    status: 'ACTIVE',
    entryDate: '2025-07-10'
  },
  {
    id: 5,
    storeId: 'S001',
    realName: '赵雪',
    phone: '13500004444',
    postName: '收银主管/前台接待',
    role: 'CASHIER',
    department: '前台客服部',
    baseSalary: 3800,
    serviceCommissionRate: 0.05,
    cardCommissionRate: 0.05,
    retailCommissionRate: 0.08,
    gender: 'FEMALE',
    status: 'ACTIVE',
    entryDate: '2025-08-01'
  },
  {
    id: 6,
    storeId: 'S001',
    realName: '孙晓晓',
    phone: '13400005555',
    postName: '发型助理/洗护师',
    role: 'TECHNICIAN',
    department: '养护服务部',
    baseSalary: 3200,
    serviceCommissionRate: 0.15,
    cardCommissionRate: 0.05,
    retailCommissionRate: 0.08,
    gender: 'FEMALE',
    status: 'ACTIVE',
    entryDate: '2025-09-01'
  },
  {
    id: 7,
    storeId: 'S001',
    realName: '孙羽彤',
    phone: '13788990011',
    postName: '美业造型总监 (扫码申请)',
    role: 'TECHNICIAN',
    department: '美业设计部',
    baseSalary: 5500,
    serviceCommissionRate: 0.30,
    cardCommissionRate: 0.10,
    retailCommissionRate: 0.15,
    gender: 'FEMALE',
    status: 'ACTIVE',
    entryDate: '2026-09-08',
    isSelfApplied: true,
    auditStatus: 'PENDING',
    accountStatus: 'PENDING_REVIEW',
    applyTime: '2026-09-08 09:30:00',
    experience: '5年知名沙龙造型总监经验，擅长日韩质感烫染与头皮抗衰，希望加入天河旗舰店。',
    hasSystemAccount: false,
    accountUsername: '13788990011',
    accountPassword: '123456',
    allowedStoreIds: ['S001'],
    allowedMenuPaths: ['/dashboard', '/rooms', '/members', '/products', '/appointments', '/inventory', '/regulations', '/profile']
  }
]

const initialProducts: ProductEntity[] = [
  {
    id: 1,
    code: 'SRV-001',
    name: '总监设计洗剪吹',
    type: 'SERVICE',
    category: 'HAIR_CUT',
    categoryName: '洗剪吹造型',
    price: 88.0,
    cost: 13.0,
    durationMinutes: 45,
    unit: '次'
  },
  {
    id: 2,
    code: 'SRV-002',
    name: '欧莱雅植物蛋白染发',
    type: 'SERVICE',
    category: 'HAIR_DYE',
    categoryName: '烫染精修',
    price: 420.0,
    cost: 68.0,
    durationMinutes: 120,
    unit: '次'
  },
  {
    id: 3,
    code: 'SRV-003',
    name: '头皮微生态赋活深度SPA',
    type: 'SERVICE',
    category: 'HAIR_SPA',
    categoryName: '头皮护理SPA',
    price: 260.0,
    cost: 38.0,
    durationMinutes: 60,
    unit: '次'
  },
  {
    id: 4,
    code: 'RET-001',
    name: '摩洛哥坚果修护护发精油 100ml',
    type: 'RETAIL',
    category: 'RETAIL_GOODS',
    categoryName: '家居洗护实物',
    price: 168.0,
    cost: 75.0,
    unit: '瓶',
    spec: '100ml 玻璃瓶装'
  },
  {
    id: 5,
    code: 'RET-002',
    name: '哑光强力清爽定型发泥 80g',
    type: 'RETAIL',
    category: 'RETAIL_GOODS',
    categoryName: '家居洗护实物',
    price: 88.0,
    cost: 32.0,
    unit: '盒',
    spec: '80g 盒装'
  },
  {
    id: 6,
    code: 'RET-003',
    name: '角蛋白沙龙级深层发膜 500ml',
    type: 'RETAIL',
    category: 'RETAIL_GOODS',
    categoryName: '家居洗护实物',
    price: 198.0,
    cost: 88.0,
    unit: '罐',
    spec: '500ml 院线同款'
  }
]

const initialMaterials: MaterialEntity[] = [
  {
    id: 'MAT-01',
    code: 'MAT-DYE-01',
    name: '欧莱雅植物蛋白原装染膏 (栗棕/冷茶色)',
    category: 'RAW',
    unit: '支',
    costPrice: 28.0,
    initialStock: 120,
    safeStock: 20,
    supplier: '欧莱雅专业美发供应链'
  },
  {
    id: 'MAT-02',
    code: 'MAT-SPA-01',
    name: '头皮微生态安瓶赋活精华泥',
    category: 'RAW',
    unit: '支',
    costPrice: 22.0,
    initialStock: 80,
    safeStock: 15,
    supplier: '资生堂专业头皮研究所'
  },
  {
    id: 'MAT-03',
    code: 'MAT-OIL-01',
    name: '摩洛哥坚果修护精油客装 100ml',
    category: 'RETAIL',
    unit: '瓶',
    costPrice: 75.0,
    initialStock: 40,
    safeStock: 10,
    supplier: '广州利华美妆供应链'
  },
  {
    id: 'MAT-04',
    code: 'MAT-MASK-01',
    name: '角蛋白沙龙级深层发膜 500ml',
    category: 'RETAIL',
    unit: '罐',
    costPrice: 88.0,
    initialStock: 6, // 接近/低于警戒线
    safeStock: 10,
    supplier: '广州利华美妆供应链'
  }
]

const initialMembers: MemberEntity[] = [
  {
    id: 1,
    memberNo: 'HM880001',
    name: '林清雅',
    phone: '13800138001',
    gender: 'FEMALE',
    level: 'GOLD',
    levelName: '金卡会员',
    registeredStoreId: 'S001',
    registerTime: '2026-09-01 10:20:00'
  },
  {
    id: 2,
    memberNo: 'HM880002',
    name: '张小曼',
    phone: '13912345678',
    gender: 'FEMALE',
    level: 'SILVER',
    levelName: '银卡会员',
    registeredStoreId: 'S001',
    referrerId: 1, // 林清雅推荐张小曼
    registerTime: '2026-09-02 14:10:00'
  },
  {
    id: 3,
    memberNo: 'HM880003',
    name: '王凯',
    phone: '13788776655',
    gender: 'MALE',
    level: 'GOLD',
    levelName: '金卡会员',
    registeredStoreId: 'S001',
    registerTime: '2026-09-03 11:00:00'
  },
  {
    id: 4,
    memberNo: 'HM880004',
    name: '刘婷婷',
    phone: '13666554433',
    gender: 'FEMALE',
    level: 'SILVER',
    levelName: '银卡会员',
    registeredStoreId: 'S001',
    referrerId: 3, // 王凯推荐刘婷婷
    registerTime: '2026-09-04 16:30:00'
  },
  {
    id: 5,
    memberNo: 'HM880005',
    name: '赵雷',
    phone: '13511223344',
    gender: 'MALE',
    level: 'DIAMOND',
    levelName: '黑钻会员',
    registeredStoreId: 'S001',
    registerTime: '2026-09-05 17:40:00'
  },
  {
    id: 6,
    memberNo: 'HM880006',
    name: '陈伟',
    phone: '13811223399',
    gender: 'MALE',
    level: 'REGULAR',
    levelName: '普卡会员',
    registeredStoreId: 'S002',
    referrerId: 1, // 林清雅老带新推荐
    registerTime: '2026-09-06 09:30:00',
    isTrial: true
  }
]

// ==============================================================================
// 4. 业务事件交易流水 (Transaction Ledgers)
// ==============================================================================

const initialRechargeOrders: RechargeOrder[] = [
  {
    id: 1,
    orderNo: 'RC20260901001',
    memberId: 1, // 林清雅
    storeId: 'S001',
    sellerEmployeeId: 2, // 托尼老师
    principalAmount: 500.0,
    giftAmount: 100.0,
    paymentMethod: 'WECHAT',
    pointsGiven: 500,
    createTime: '2026-09-01 10:30:00',
    status: 'COMPLETED'
  },
  {
    id: 2,
    orderNo: 'RC20260902001',
    memberId: 2, // 张小曼
    storeId: 'S001',
    sellerEmployeeId: 3, // 李四
    principalAmount: 300.0,
    giftAmount: 50.0,
    paymentMethod: 'ALIPAY',
    pointsGiven: 300,
    createTime: '2026-09-02 14:15:00',
    status: 'COMPLETED'
  },
  {
    id: 3,
    orderNo: 'RC20260903001',
    memberId: 3, // 王凯
    storeId: 'S001',
    sellerEmployeeId: 2, // 托尼老师
    principalAmount: 1000.0,
    giftAmount: 200.0,
    paymentMethod: 'WECHAT',
    pointsGiven: 1000,
    createTime: '2026-09-03 11:20:00',
    status: 'COMPLETED'
  },
  {
    id: 4,
    orderNo: 'RC20260905001',
    memberId: 5, // 赵雷
    storeId: 'S001',
    sellerEmployeeId: 2, // 托尼老师
    principalAmount: 2000.0,
    giftAmount: 500.0,
    paymentMethod: 'WECHAT',
    pointsGiven: 2000,
    createTime: '2026-09-05 18:00:00',
    status: 'COMPLETED'
  }
]

const initialConsumeOrders: ConsumeOrder[] = [
  {
    id: 1,
    orderNo: 'ORD20260906001',
    memberId: 1, // 林清雅
    storeId: 'S001',
    primaryTechnicianId: 2, // 托尼老师
    cashierEmployeeId: 5, // 小赵
    items: [
      { productId: 2, productName: '欧莱雅植物蛋白染发', type: 'SERVICE', price: 420.0, quantity: 1, bomCost: 68.0 }
    ],
    totalAmount: 420.0,
    couponDiscount: 50.0,
    couponId: 'CPN-001',
    cardDeductPrincipal: 240.0,
    cardDeductGift: 48.0,
    cashierPaidAmount: 82.0,
    paymentMethod: 'WECHAT',
    pointsEarned: 82,
    pointsBurned: 0,
    createTime: '2026-09-06 14:35:00',
    status: 'COMPLETED'
  },
  {
    id: 2,
    orderNo: 'ORD20260906002',
    memberId: 2, // 张小曼
    storeId: 'S001',
    primaryTechnicianId: 3, // 李四
    cashierEmployeeId: 5, // 小赵
    items: [
      { productId: 4, productName: '摩洛哥坚果修护护发精油 100ml', type: 'RETAIL', price: 168.0, quantity: 1, bomCost: 75.0 }
    ],
    totalAmount: 168.0,
    couponDiscount: 0,
    cardDeductPrincipal: 0,
    cardDeductGift: 0,
    cashierPaidAmount: 168.0,
    paymentMethod: 'WECHAT',
    pointsEarned: 168,
    pointsBurned: 0,
    createTime: '2026-09-06 15:10:05',
    status: 'COMPLETED'
  },
  {
    id: 3,
    orderNo: 'ORD20260906003',
    memberId: 3, // 王凯
    storeId: 'S001',
    primaryTechnicianId: 2, // 托尼老师
    cashierEmployeeId: 5, // 小赵
    items: [
      { productId: 5, productName: '哑光强力清爽定型发泥 80g', type: 'RETAIL', price: 88.0, quantity: 1, bomCost: 32.0 }
    ],
    totalAmount: 88.0,
    couponDiscount: 0,
    cardDeductPrincipal: 0,
    cardDeductGift: 0,
    cashierPaidAmount: 88.0,
    paymentMethod: 'ALIPAY',
    pointsEarned: 88,
    pointsBurned: 0,
    createTime: '2026-09-06 16:05:30',
    status: 'COMPLETED'
  },
  {
    id: 4,
    orderNo: 'ORD20260906004',
    memberId: 4, // 刘婷婷
    storeId: 'S001',
    primaryTechnicianId: 4, // 王芳
    cashierEmployeeId: 5,
    items: [
      { productId: 1, productName: '总监设计洗剪吹', type: 'SERVICE', price: 88.0, quantity: 1, bomCost: 13.0 }
    ],
    totalAmount: 88.0,
    couponDiscount: 50.0,
    couponId: 'CPN-004',
    cardDeductPrincipal: 0,
    cardDeductGift: 0,
    cashierPaidAmount: 38.0,
    paymentMethod: 'WECHAT',
    pointsEarned: 38,
    pointsBurned: 0,
    createTime: '2026-09-06 11:35:12',
    status: 'COMPLETED'
  },
  {
    id: 5,
    orderNo: 'ORD20260905001',
    memberId: 2, // 张小曼
    storeId: 'S001',
    primaryTechnicianId: 3, // 李四
    cashierEmployeeId: 5,
    items: [
      { productId: 3, productName: '头皮微生态赋活深度SPA', type: 'SERVICE', price: 260.0, quantity: 1, bomCost: 38.0 }
    ],
    totalAmount: 260.0,
    couponDiscount: 0,
    cardDeductPrincipal: 160.0,
    cardDeductGift: 38.0,
    cashierPaidAmount: 62.0,
    paymentMethod: 'OFFLINE',
    pointsEarned: 62,
    pointsBurned: 100,
    createTime: '2026-09-05 16:20:00',
    status: 'COMPLETED'
  }
]

const initialTimeCards: TimeCardItem[] = [
  {
    id: 1,
    memberId: 1, // 林清雅
    skuId: 1,
    cardName: '总监设计洗剪吹 5次专享卡',
    totalTimes: 5,
    usedTimes: 2,
    unitPrice: 70.0,
    expireDate: '2026-12-31'
  },
  {
    id: 2,
    memberId: 3, // 王凯
    skuId: 2,
    cardName: '头皮深度微生态赋活 3次年卡',
    totalTimes: 3,
    usedTimes: 1,
    unitPrice: 220.0,
    expireDate: '2027-03-31'
  }
]

const initialPointsLedger: PointsLog[] = [
  {
    id: 1,
    memberId: 1,
    type: 'RECHARGE_GIFT',
    typeName: '开卡充值即赠',
    pointsDelta: 500,
    balanceAfter: 500,
    operator: '系统自动',
    createTime: '2026-09-01 10:30:00'
  },
  {
    id: 2,
    memberId: 1,
    type: 'CONSUME_EARN',
    typeName: '消费实付获赠',
    pointsDelta: 82,
    balanceAfter: 582,
    operator: '收银结账',
    createTime: '2026-09-06 14:35:00'
  },
  {
    id: 3,
    memberId: 2,
    type: 'RECHARGE_GIFT',
    typeName: '开卡充值即赠',
    pointsDelta: 300,
    balanceAfter: 300,
    operator: '系统自动',
    createTime: '2026-09-02 14:15:00'
  },
  {
    id: 4,
    memberId: 2,
    type: 'CASHIER_BURN',
    typeName: '收银抵扣10元',
    pointsDelta: -100,
    balanceAfter: 200,
    operator: '前台收银员',
    createTime: '2026-09-05 16:20:00'
  }
]

const initialRewardsLedger: RewardLog[] = [
  {
    id: 1,
    memberId: 1, // 林清雅推荐张小曼
    referredMemberId: 2,
    reason: '成功推荐好友【张小曼】入会办卡',
    rewardDelta: 50.0,
    balanceAfter: 50.0,
    createTime: '2026-09-02 14:30:00'
  },
  {
    id: 2,
    memberId: 3, // 王凯推荐刘婷婷
    referredMemberId: 4,
    reason: '双人拼团立减活动成团奖励',
    rewardDelta: 30.0,
    balanceAfter: 30.0,
    createTime: '2026-09-04 16:45:00'
  }
]

const initialExpenses: ExpenseRecord[] = [
  {
    id: 1,
    storeId: 'S001',
    category: 'RENT',
    categoryName: '房租水电物业',
    title: '9月份旗舰店商场租金及物业水电',
    amount: 14500.0,
    date: '2026-09-01',
    handler: '张建华',
    note: '已转账天河城物业财务部'
  },
  {
    id: 2,
    storeId: 'S001',
    category: 'SUPPLY',
    categoryName: '耗材物料采购',
    title: '9月首批染发膏与护理精油采购备货',
    amount: 11280.0,
    date: '2026-09-02',
    handler: '小赵',
    note: '欧莱雅及资生堂供货商款项'
  },
  {
    id: 3,
    storeId: 'S001',
    category: 'SALARY',
    categoryName: '员工福利社保',
    title: '全员8月份社保统筹公积金与餐补',
    amount: 8600.0,
    date: '2026-09-05',
    handler: '张建华',
    note: '人力资源薪酬代发'
  },
  {
    id: 4,
    storeId: 'S001',
    category: 'MARKETING',
    categoryName: '营销获客广告',
    title: '微信朋友圈本地门店推广定向投放',
    amount: 3500.0,
    date: '2026-09-03',
    handler: '张建华',
    note: '获客广告费用'
  }
]

const initialAppointments: AppointmentRecord[] = [
  {
    id: 1,
    aptNo: 'APT20260906001',
    memberId: 1,
    memberName: '林清雅',
    phone: '13800138001',
    storeId: 'S001',
    technicianId: 2,
    technicianName: '托尼',
    productId: 2,
    productName: '欧莱雅植物蛋白染发',
    date: '2026-09-06',
    timeSlot: '14:00 - 16:00',
    status: 'COMPLETED'
  },
  {
    id: 2,
    aptNo: 'APT20260906002',
    memberId: 2,
    memberName: '张小曼',
    phone: '13912345678',
    storeId: 'S001',
    technicianId: 3,
    technicianName: '李博',
    productId: 4,
    productName: '头皮微生态赋活深度SPA',
    date: '2026-09-06',
    timeSlot: '16:30 - 17:30',
    status: 'COMPLETED'
  },
  {
    id: 3,
    aptNo: 'APT20260906003',
    memberId: 5,
    memberName: '赵雷',
    phone: '13511223344',
    storeId: 'S001',
    technicianId: 2,
    technicianName: '托尼',
    productId: 1,
    productName: '总监设计洗剪吹',
    date: '2026-09-06',
    timeSlot: '19:00 - 20:00',
    status: 'PENDING'
  }
]

const initialLiveSessions: LiveSession[] = [
  {
    id: 1,
    spaceId: 1,
    spaceName: 'VIP 1号美发镜台',
    sessionNo: 'SES20260906001',
    customerName: '林清雅',
    customerPhone: '13800138001',
    memberId: 1,
    startTime: '2026-09-06 14:00:00',
    totalAmount: 420.0,
    status: 'SERVING',
    items: [
      { name: '欧莱雅植物蛋白染发', price: 380.0, qty: 1 },
      { name: '发型总监精修设计费', price: 40.0, qty: 1 }
    ]
  },
  {
    id: 2,
    spaceId: 2,
    spaceName: '头皮SPA专属养护台',
    sessionNo: 'SES20260906002',
    customerName: '张小曼',
    customerPhone: '13912345678',
    memberId: 2,
    startTime: '2026-09-06 14:30:00',
    totalAmount: 260.0,
    status: 'SERVING',
    items: [
      { name: '头皮微生态赋活深度SPA', price: 260.0, qty: 1 }
    ]
  },
  {
    id: 3,
    spaceId: 3,
    spaceName: '造型设计 3号镜台',
    sessionNo: 'SES20260906003',
    customerName: '王凯',
    customerPhone: '13799887766',
    memberId: 3,
    startTime: '2026-09-06 15:00:00',
    totalAmount: 88.0,
    status: 'SERVING',
    items: [
      { name: '总监设计洗剪吹造型', price: 88.0, qty: 1 }
    ]
  }
]

const initialCosts: CostItemEntity[] = [
  {
    id: 1,
    code: 'CST202609001',
    name: '员工绩效施工与销售提成总额',
    category: 'LABOR',
    categoryName: '人力薪酬成本',
    nature: 'VARIABLE',
    amount: 28500,
    month: '2026-09',
    date: '2026-09-06',
    storeId: 'S001',
    handler: '财务部-王主管',
    invoiceNo: 'SAL-202609-01',
    notes: '包含当月发型总监、高级技师及发型师服务与办卡销售提成'
  },
  {
    id: 2,
    code: 'CST202609002',
    name: '店面营业基础租金支出',
    category: 'RENT_UTILITY',
    categoryName: '店面房租能耗',
    nature: 'FIXED',
    amount: 18000,
    month: '2026-09',
    date: '2026-09-01',
    storeId: 'S001',
    handler: '李店长',
    invoiceNo: 'RNT-20260901',
    notes: '科技大厦商业空间一楼月度营业租金'
  },
  {
    id: 3,
    code: 'CST202609003',
    name: '全店在册员工基础底薪包',
    category: 'LABOR',
    categoryName: '人力薪酬成本',
    nature: 'FIXED',
    amount: 12500,
    month: '2026-09',
    date: '2026-09-05',
    storeId: 'S001',
    handler: '财务部-王主管',
    invoiceNo: 'SAL-BASE-09',
    notes: '含店长、前台收银及助理全勤底薪'
  },
  {
    id: 4,
    code: 'CST202609004',
    name: '欧莱雅及施华蔻专业染烫耗材采购',
    category: 'MATERIAL',
    categoryName: '物料耗材成本',
    nature: 'VARIABLE',
    amount: 9200,
    month: '2026-09',
    date: '2026-09-03',
    storeId: 'S001',
    handler: '库管-张芳',
    invoiceNo: 'INV-MAT-0903',
    notes: '当月植物蛋白染膏与温和冷烫水补货出库损耗'
  },
  {
    id: 5,
    code: 'CST202609005',
    name: '头皮SPA植物精油及定制客用品消耗',
    category: 'MATERIAL',
    categoryName: '物料耗材成本',
    nature: 'VARIABLE',
    amount: 4500,
    month: '2026-09',
    date: '2026-09-04',
    storeId: 'S001',
    handler: '托尼总监',
    invoiceNo: 'INV-SPA-0904',
    notes: '包含高档纯植物精油、一次性消杀毛巾与围布'
  },
  {
    id: 6,
    code: 'CST202609006',
    name: '中央空调与大功率动力用电/水费',
    category: 'RENT_UTILITY',
    categoryName: '店面房租能耗',
    nature: 'VARIABLE',
    amount: 3800,
    month: '2026-09',
    date: '2026-09-06',
    storeId: 'S001',
    handler: '前台-小赵',
    invoiceNo: 'UTL-202609-01',
    notes: '店面全天恒温空调与热水加热高负荷电费'
  },
  {
    id: 7,
    code: 'CST202609007',
    name: '美团点评本地生活流量推广佣金',
    category: 'MARKETING',
    categoryName: '营销获客成本',
    nature: 'VARIABLE',
    amount: 3600,
    month: '2026-09',
    date: '2026-09-02',
    storeId: 'S001',
    handler: '李店长',
    invoiceNo: 'MKT-MT-0902',
    notes: '线上洗剪吹与染烫团购核销佣金扣款'
  },
  {
    id: 8,
    code: 'CST202609008',
    name: '智能多功能SPA舱与美发镜台月度折旧',
    category: 'DEPRECIATION',
    categoryName: '设备资产折旧',
    nature: 'FIXED',
    amount: 2500,
    month: '2026-09',
    date: '2026-09-01',
    storeId: 'S001',
    handler: '资产部-陈工',
    invoiceNo: 'DEP-EQ-0901',
    notes: '店内高精设备资产按60期直线法月度折旧分摊'
  },
  {
    id: 9,
    code: 'CST202609009',
    name: '客休区现磨咖啡花茶与环境消杀绿植',
    category: 'ADMIN_MISC',
    categoryName: '日常运营杂费',
    nature: 'FIXED',
    amount: 1600,
    month: '2026-09',
    date: '2026-09-05',
    storeId: 'S001',
    handler: '前台-小赵',
    invoiceNo: 'ADM-SUP-0905',
    notes: '高品质客户体验伴饮原料及每周消杀保洁服务费'
  },
  {
    id: 10,
    code: 'CST202609010',
    name: '精准会员5G视频短信与触达营销费',
    category: 'MARKETING',
    categoryName: '营销获客成本',
    nature: 'VARIABLE',
    amount: 1200,
    month: '2026-09',
    date: '2026-09-06',
    storeId: 'S001',
    handler: '营销专员-小陈',
    invoiceNo: 'SMS-5G-0906',
    notes: '沉睡会员唤醒券及生日专享礼遇短信群发'
  }
]

export const industrySpacesMap: Record<string, SpaceEntity[]> = {
  RESTAURANT: [
    {
      id: 1,
      storeId: 'S002',
      spaceCode: 'B01',
      spaceName: 'VIP紫荆景观大包厢',
      spaceType: 'ROOM',
      status: 'IDLE',
      capacity: 12,
      floorZone: '二楼VIP包厢区',
      minConsumeAmount: 1200,
      hourlyFee: 0,
      facilities: ['独立洗手间', '全景落地窗', '功夫茶台', '专属管家', '新风系统'],
      notes: '适宜高端商务宴请、家庭聚餐，已配备高端茶台与新风系统',
      sortOrder: 1,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S002&spaceCode=B01'
    },
    {
      id: 2,
      storeId: 'S002',
      spaceCode: 'B02',
      spaceName: '兰亭和风独立包厢',
      spaceType: 'ROOM',
      status: 'OCCUPIED',
      capacity: 8,
      floorZone: '二楼VIP包厢区',
      minConsumeAmount: 800,
      hourlyFee: 0,
      facilities: ['榻榻米', '功夫茶台', '静音隔音', '新风系统'],
      notes: '主厨订制私房菜专席，静谧雅致',
      sortOrder: 2,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S002&spaceCode=B02',
      currentSessionId: 102
    },
    {
      id: 3,
      storeId: 'S002',
      spaceCode: 'B03',
      spaceName: '松风主厨私房包房',
      spaceType: 'ROOM',
      status: 'DIRTY',
      capacity: 10,
      floorZone: '二楼VIP包厢区',
      minConsumeAmount: 1000,
      hourlyFee: 0,
      facilities: ['主厨料理台', '独立洗手间', '高清投影', '红酒恒温柜'],
      notes: '刚结账完成，待清台消毒复位',
      sortOrder: 3,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S002&spaceCode=B03'
    },
    {
      id: 4,
      storeId: 'S002',
      spaceCode: 'B05',
      spaceName: '明月雅致商务包厢',
      spaceType: 'ROOM',
      status: 'MAINTENANCE',
      capacity: 6,
      floorZone: '二楼VIP包厢区',
      minConsumeAmount: 600,
      hourlyFee: 0,
      facilities: ['静音隔音', '智能调光', '功夫茶具'],
      notes: '中央空调管道维护保养检修中，暂未开放订座',
      sortOrder: 4,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S002&spaceCode=B05'
    },
    {
      id: 5,
      storeId: 'S002',
      spaceCode: 'T01',
      spaceName: '一楼景观大厅 4人雅座',
      spaceType: 'TABLE',
      status: 'IDLE',
      capacity: 4,
      floorZone: '一楼大厅景观区',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: ['落地窗景观', '智能无线充电', '儿童安全座椅'],
      notes: '采光好，散客高频接待',
      sortOrder: 5,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S002&spaceCode=T01'
    },
    {
      id: 6,
      storeId: 'S002',
      spaceCode: 'T02',
      spaceName: '一楼大厅 6人半开放卡座',
      spaceType: 'TABLE',
      status: 'OCCUPIED',
      capacity: 6,
      floorZone: '一楼大厅景观区',
      minConsumeAmount: 200,
      hourlyFee: 0,
      facilities: ['皮质软包卡座', '智能无线充电', '呼叫铃'],
      notes: '朋友聚会与家庭聚餐',
      sortOrder: 6,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S002&spaceCode=T02',
      currentSessionId: 101
    },
    {
      id: 7,
      storeId: 'S002',
      spaceCode: 'T03',
      spaceName: '户外花园露台 4人休闲散台',
      spaceType: 'TABLE',
      status: 'IDLE',
      capacity: 4,
      floorZone: '户外露台休闲区',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: ['绿植遮阳伞', '户外暖风机', '浪漫氛围灯'],
      notes: '微风露台，适合惬意下午茶或晚市小酌',
      sortOrder: 7,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S002&spaceCode=T03'
    }
  ],
  BEAUTY: [
    {
      id: 11,
      storeId: 'S001',
      spaceCode: 'R01',
      spaceName: 'VIP独立至尊造型美发套房',
      spaceType: 'ROOM',
      status: 'IDLE',
      capacity: 2,
      floorZone: '二楼VIP独立套房区',
      minConsumeAmount: 300,
      hourlyFee: 0,
      facilities: ['独立冲洗床', '私密隔音', '现磨手冲咖啡', '戴森吹风机'],
      notes: '黑钻会员专属定制空间，提供一对一定制造型服务',
      sortOrder: 1,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S001&spaceCode=R01'
    },
    {
      id: 12,
      storeId: 'S001',
      spaceCode: 'R02',
      spaceName: '头皮微生态SPA专属养护舱',
      spaceType: 'ROOM',
      status: 'OCCUPIED',
      capacity: 1,
      floorZone: '二楼VIP独立套房区',
      minConsumeAmount: 200,
      hourlyFee: 0,
      facilities: ['星空顶水疗床', '微雾熏蒸仪', '静音降噪', '香薰精油'],
      notes: '深度头皮理疗与SPA舱，正在服务常客张小曼',
      sortOrder: 2,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S001&spaceCode=R02',
      currentSessionId: 2
    },
    {
      id: 13,
      storeId: 'S001',
      spaceCode: 'M01',
      spaceName: '发型总监精剪 1号镜台',
      spaceType: 'MIRROR',
      status: 'OCCUPIED',
      capacity: 1,
      floorZone: '一楼美发造型大厅',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: ['高清防眩光化妆镜', '人体工学液压椅', '专业理发剪具车'],
      notes: '发型总监专属工位，正在为林清雅设计精剪',
      sortOrder: 3,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S001&spaceCode=M01',
      currentSessionId: 1
    },
    {
      id: 14,
      storeId: 'S001',
      spaceCode: 'M02',
      spaceName: '时尚烫染设计 2号镜台',
      spaceType: 'MIRROR',
      status: 'IDLE',
      capacity: 1,
      floorZone: '一楼美发造型大厅',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: ['红外恒温加热飞碟', '多孔色板染发车'],
      notes: '烫染专席，设备完好备用',
      sortOrder: 4,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S001&spaceCode=M02'
    },
    {
      id: 15,
      storeId: 'S001',
      spaceCode: 'M03',
      spaceName: '精修快剪 3号造型镜台',
      spaceType: 'MIRROR',
      status: 'DIRTY',
      capacity: 1,
      floorZone: '一楼美发造型大厅',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: ['毛发智能真空吸尘器'],
      notes: '刚完成理发，待台面清扫与工具紫外线消毒',
      sortOrder: 5,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S001&spaceCode=M03'
    }
  ],
  AUTO: [
    {
      id: 21,
      storeId: 'S003',
      spaceCode: 'BAY01',
      spaceName: '重载机电 1号双柱举升车位',
      spaceType: 'BAY',
      status: 'OCCUPIED',
      capacity: 1,
      floorZone: '机电快修车间',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: ['4吨电动双柱举升机', '自动抽接油机', '气动棘轮扳手组'],
      notes: '奔驰E300L机油保养与底盘检查中',
      sortOrder: 1,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S003&spaceCode=BAY01',
      currentSessionId: 21
    },
    {
      id: 22,
      storeId: 'S003',
      spaceCode: 'BAY02',
      spaceName: '水循环深层精洗 2号车位',
      spaceType: 'BAY',
      status: 'OCCUPIED',
      capacity: 1,
      floorZone: '洗车美容车间',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: ['德国凯驰高压水枪', '底盘冲洗喷管', '无接触雪崩泡沫机'],
      notes: '宝马3系全车手工精洗与打蜡',
      sortOrder: 2,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S003&spaceCode=BAY02',
      currentSessionId: 22
    },
    {
      id: 23,
      storeId: 'S003',
      spaceCode: 'BAY03',
      spaceName: '德国3D高清红外四轮定位工位',
      spaceType: 'BAY',
      status: 'IDLE',
      capacity: 1,
      floorZone: '精细校准车间',
      minConsumeAmount: 180,
      hourlyFee: 0,
      facilities: ['3D激光红外定位探头', '大剪式调校举升机', '轮圈高精度夹具'],
      notes: '底盘调校专用工位，校准设备已预热可用',
      sortOrder: 3,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S003&spaceCode=BAY03'
    },
    {
      id: 24,
      storeId: 'S003',
      spaceCode: 'BAY05',
      spaceName: '无痕钣金与微创修复车位',
      spaceType: 'BAY',
      status: 'IDLE',
      capacity: 1,
      floorZone: '钣金修复车间',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: ['微创吸拔整平灯', '红外短波烤灯线'],
      notes: '凹陷无损快速修复工位',
      sortOrder: 4,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S003&spaceCode=BAY05'
    }
  ],
  RETAIL: [
    {
      id: 31,
      storeId: 'S006',
      spaceCode: 'R01',
      spaceName: 'VIP名品私享选品品鉴室',
      spaceType: 'ROOM',
      status: 'IDLE',
      capacity: 6,
      floorZone: '二楼高定贵宾区',
      minConsumeAmount: 500,
      hourlyFee: 0,
      facilities: ['独立试衣间', '恒温恒湿珠宝香氛展柜', '现磨手冲吧台'],
      notes: '高端大客私密选品品鉴专室',
      sortOrder: 1,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S006&spaceCode=R01'
    },
    {
      id: 32,
      storeId: 'S006',
      spaceCode: 'T01',
      spaceName: '精品手冲咖啡品鉴吧台 1号席',
      spaceType: 'TABLE',
      status: 'OCCUPIED',
      capacity: 2,
      floorZone: '一楼中庭体验区',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: ['FELLOW温控手冲壶', '日晒精品风味轮', '高硼硅品茗杯'],
      notes: '耶加雪菲现磨风味试饮接待中',
      sortOrder: 2,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S006&spaceCode=T01',
      currentSessionId: 31
    },
    {
      id: 33,
      storeId: 'S006',
      spaceCode: 'T02',
      spaceName: '小众香薰与家居生活体验台',
      spaceType: 'TABLE',
      status: 'IDLE',
      capacity: 4,
      floorZone: '一楼中庭体验区',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: ['试香闻香石', '扩香精油试用装'],
      notes: '香氛家居体验展席',
      sortOrder: 3,
      qrCodeUrl: 'https://fwpt.cn/seahorse/table-order?storeId=S006&spaceCode=T02'
    }
  ]
}

// ==============================================================================
// 4.5. 线上微商城初始货架数据集 (自洽适配4大行业)
// ==============================================================================

const initialMallGoodsMap: Record<'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL', MallGoodsEntity[]> = {
  BEAUTY: [
    { id: 101, productId: 4, productCode: 'RET-001', title: '摩洛哥坚果修护护发精油 100ml', category: '家居洗护', onlinePrice: 138, originalPrice: 168, sales: 86, stock: 32, onShelf: true, isHot: true, deliveryType: 'BOTH', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '甄选摩洛哥冷榨阿甘油，深度抚平毛躁，沙龙级柔亮丝滑。' },
    { id: 102, productId: 5, productCode: 'RET-002', title: '哑光强力清爽定型发泥 80g', category: '家居洗护', onlinePrice: 78, originalPrice: 98, sales: 120, stock: 18, onShelf: true, isHot: false, deliveryType: 'EXPRESS', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '天然蜂蜡成分，清爽不油腻，哑光动感定型一整天。' },
    { id: 103, title: '角蛋白沙龙级深层发膜 250g (线上特供礼盒)', category: '家居洗护', onlinePrice: 158, originalPrice: 198, sales: 54, stock: 15, onShelf: true, isHot: true, deliveryType: 'BOTH', syncSource: 'MALL_EXCLUSIVE', syncTime: '2026-09-06 10:00:00', description: '深层渗透发丝纤维，修护染烫受损，附赠便携分装瓶。' }
  ],
  RESTAURANT: [
    { id: 201, title: '地中海黑松露初榨原浆橄榄油礼盒 500ml', category: '主厨私房零售', onlinePrice: 188, originalPrice: 228, sales: 92, stock: 40, onShelf: true, isHot: true, deliveryType: 'EXPRESS', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '特级初榨橄榄油融入意大利野生黑松露原浆，凉拌/烹饪点睛。' },
    { id: 202, title: '主厨秘制法式和牛酱汁双瓶礼装', category: '主厨私房零售', onlinePrice: 128, originalPrice: 158, sales: 140, stock: 25, onShelf: true, isHot: true, deliveryType: 'BOTH', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '主厨秘方熬制24小时，浓郁醇厚，佐餐牛排意面绝配。' },
    { id: 203, title: '精酿白啤现扎保鲜冷链配送桶 1.5L', category: '特调与精酿', onlinePrice: 98, originalPrice: 118, sales: 76, stock: 20, onShelf: true, isHot: false, deliveryType: 'STORE_PICKUP', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '当天现打鲜啤，麦香浓郁带有果香，冷链闪送锁鲜。' }
  ],
  AUTO: [
    { id: 301, title: '车载多功能太阳能空气净化香氛器', category: '汽车精品实物', onlinePrice: 198, originalPrice: 258, sales: 135, stock: 30, onShelf: true, isHot: true, deliveryType: 'EXPRESS', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '太阳能自动旋转散香，负离子主动降解车内甲醛异味。' },
    { id: 302, title: '无水纳米微晶玻璃除油膜防雨涂层剂 180ml', category: '汽车精品实物', onlinePrice: 68, originalPrice: 98, sales: 210, stock: 45, onShelf: true, isHot: false, deliveryType: 'BOTH', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '驱水防雾视野清晰，纳米微晶快速形成疏水保护层。' },
    { id: 303, title: '专车专用全包围环保无味静音脚垫', category: '汽车精品实物', onlinePrice: 368, originalPrice: 480, sales: 45, stock: 12, onShelf: true, isHot: true, deliveryType: 'EXPRESS', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '高分子环保TPE无味材质，激光扫描开模，原车原卡扣。' }
  ],
  RETAIL: [
    { id: 401, title: '埃塞俄比亚耶加雪菲日晒精品咖啡豆 500g', category: '精品咖啡茗茶', onlinePrice: 168, originalPrice: 198, sales: 156, stock: 50, onShelf: true, isHot: true, deliveryType: 'EXPRESS', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: 'G1等级浅中烘焙，明亮柑橘花香与蜂蜜回甘，单向透气阀铝箔装。' },
    { id: 402, title: '沙龙小众冷杉雪松木质调无火香薰礼盒', category: '家居生活美学', onlinePrice: 298, originalPrice: 358, sales: 88, stock: 35, onShelf: true, isHot: true, deliveryType: 'BOTH', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '天然植物精油扩香，沉稳雪松与清冽冷杉交融，治愈系居家氛围。' },
    { id: 403, title: '北欧极简手作耐热双层玻璃品茗杯', category: '工艺器皿生活', onlinePrice: 128, originalPrice: 158, sales: 64, stock: 28, onShelf: true, isHot: false, deliveryType: 'BOTH', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '高硼硅手工吹制，双层中空防烫保温，通透清亮。' },
    { id: 404, title: '高山冷萃有机原叶白毫银针礼盒 100g', category: '精品咖啡茗茶', onlinePrice: 198, originalPrice: 248, sales: 42, stock: 15, onShelf: true, isHot: false, deliveryType: 'EXPRESS', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '福鼎核心产区明前单芽，毫香显露，汤色杏黄清澈。' },
    { id: 405, title: '比利时手工72%黑巧纯可可脂排块', category: '进口轻奢零食', onlinePrice: 88, originalPrice: 108, sales: 110, stock: 60, onShelf: true, isHot: false, deliveryType: 'EXPRESS', syncSource: 'STORE_PRODUCT', syncTime: '2026-09-06 10:00:00', description: '纯可可脂非代可可脂，微苦甘醇，丝滑入口即化。' }
  ]
}

// 4.6. 获客裂变与营销活动行业场景初始数据集
export const initialIndustryCampaignsMap: Record<'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL', CampaignEntity[]> = {
  BEAUTY: [
    { id: 101, name: '新人开卡专享50元无门槛券', type: 'COUPON', ruleDesc: '新会员入会立得50元代金券，全场美发/美甲项目通用', participateCount: 120, revenueBrought: 16800, validRange: '2026-08-01 ~ 2026-12-31', status: 'RUNNING', badgeText: '新人专享', discountHighlight: '立减¥50' },
    { id: 102, name: '闺蜜同行·双人成团烫染立享7折', type: 'GROUP', ruleDesc: '2人成团即享烫染7折优惠，再赠进口植物护发精油', participateCount: 68, revenueBrought: 24600, validRange: '2026-09-01 ~ 2026-09-30', status: 'RUNNING', badgeText: '拼团特惠', discountHighlight: '7折特惠' },
    { id: 103, name: '老带新裂变·好友首单返50元奖励金', type: 'REFERRAL', ruleDesc: '邀请好友到店消费，推荐人立得50元储值金无上限', participateCount: 42, revenueBrought: 12800, validRange: '2026-07-01 ~ 2026-10-31', status: 'RUNNING', badgeText: '现金返利', discountHighlight: '返¥50' },
    { id: 104, name: '每周二会员日·积分双倍抵扣', type: 'POINTS', ruleDesc: '周二到店消费享受双倍积分，积分可100%冲抵账单', participateCount: 86, revenueBrought: 7400, validRange: '2026-09-01 ~ 2026-12-31', status: 'RUNNING', badgeText: '积分加速', discountHighlight: '双倍积分' }
  ],
  RESTAURANT: [
    { id: 201, name: '主厨甄选·到店立减30元品鉴券', type: 'COUPON', ruleDesc: '单笔就餐消费满200元立减30元，招牌料理通用', participateCount: 145, revenueBrought: 28900, validRange: '2026-08-01 ~ 2026-12-31', status: 'RUNNING', badgeText: '就餐礼遇', discountHighlight: '立减¥30' },
    { id: 202, name: '4人同行聚餐·招牌炭烤大份免费升', type: 'GROUP', ruleDesc: '4人及以上到店聚餐，招牌炭烤自动免费升级至特大份', participateCount: 52, revenueBrought: 19800, validRange: '2026-09-01 ~ 2026-10-15', status: 'RUNNING', badgeText: '欢聚聚餐', discountHighlight: '免费升级' },
    { id: 203, name: '老饕带新客·好友就餐赠精酿原浆', type: 'REFERRAL', ruleDesc: '推荐好友到店就餐，推荐人获赠500ml手工精酿鲜啤酒两瓶', participateCount: 38, revenueBrought: 9600, validRange: '2026-07-01 ~ 2026-11-30', status: 'RUNNING', badgeText: '好礼相赠', discountHighlight: '送精酿' }
  ],
  AUTO: [
    { id: 301, name: '常规小保养·全合成机油立减60元券', type: 'COUPON', ruleDesc: '更换全合成机油基础保养立减60元，含免费36项体检', participateCount: 96, revenueBrought: 21800, validRange: '2026-08-01 ~ 2026-12-31', status: 'RUNNING', badgeText: '养车特惠', discountHighlight: '立减¥60' },
    { id: 302, name: '车友拼团·全车安全检测0元领', type: 'GROUP', ruleDesc: '2位车主成团，即可0元免费享受原价120元全车底盘电路检测', participateCount: 74, revenueBrought: 15400, validRange: '2026-09-01 ~ 2026-10-31', status: 'RUNNING', badgeText: '0元体验', discountHighlight: '0元体检' },
    { id: 303, name: '老车主转介绍·推荐新车主送精细洗美', type: 'REFERRAL', ruleDesc: '老客户转介绍新车主到店养护，立赠价值80元精细洗美一次', participateCount: 45, revenueBrought: 16200, validRange: '2026-07-01 ~ 2026-12-31', status: 'RUNNING', badgeText: '转介好礼', discountHighlight: '送精洗' }
  ],
  RETAIL: [
    { id: 401, name: '进店新人礼·专享30元无门槛立减券', type: 'COUPON', ruleDesc: '新客进店或扫码即领30元优惠券，全场正价商品可用', participateCount: 160, revenueBrought: 25400, validRange: '2026-08-01 ~ 2026-12-31', status: 'RUNNING', badgeText: '进店礼券', discountHighlight: '无门槛¥30' },
    { id: 402, name: '多件多折·全场精选满2件立享8折', type: 'GROUP', ruleDesc: '好友同单拼购2件及以上，全单享受8折特惠', participateCount: 85, revenueBrought: 31200, validRange: '2026-09-01 ~ 2026-09-30', status: 'RUNNING', badgeText: '满件立减', discountHighlight: '全场8折' },
    { id: 403, name: '名品裂变·分享好友消费享5%返佣', type: 'REFERRAL', ruleDesc: '生成专属海报转发好友下单，推荐人立得5%现金提成', participateCount: 62, revenueBrought: 18600, validRange: '2026-07-01 ~ 2026-12-31', status: 'RUNNING', badgeText: '分享返佣', discountHighlight: '5%返现' }
  ]
}

// 4.7. 线上微商城初始订单数据集 (自洽适配4大行业，新注册租户纯净零订单)
export const initialMallOrdersMap: Record<'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL', MallOrderEntity[]> = {
  BEAUTY: [
    { orderNo: 'ORD20260906001', productTitle: '摩洛哥坚果修护护发精油 100ml', price: 138, quantity: 2, totalAmount: 276, buyerName: '李清雅', buyerPhone: '13800138001', deliveryType: 'EXPRESS', orderTime: '2026-09-06 18:20:11', status: 'PAID' },
    { orderNo: 'ORD20260906002', productTitle: '头皮微生态赋活精油原液 50ml', price: 198, quantity: 1, totalAmount: 198, buyerName: '张小曼', buyerPhone: '13912345678', deliveryType: 'STORE_PICKUP', orderTime: '2026-09-06 15:40:02', status: 'PAID' },
    { orderNo: 'ORD20260905001', productTitle: '氨基酸去屑控油洗发乳 500ml', price: 98, quantity: 1, totalAmount: 98, buyerName: '陈伟', buyerPhone: '13799887766', deliveryType: 'EXPRESS', orderTime: '2026-09-05 11:15:30', status: 'DELIVERED' }
  ],
  RESTAURANT: [
    { orderNo: 'ORD20260906201', productTitle: '地中海黑松露初榨原浆橄榄油礼盒 500ml', price: 188, quantity: 1, totalAmount: 188, buyerName: '高逸轩', buyerPhone: '13900223301', deliveryType: 'EXPRESS', orderTime: '2026-09-06 17:15:00', status: 'PAID' },
    { orderNo: 'ORD20260906202', productTitle: '精酿白啤现扎保鲜冷链配送桶 1.5L', price: 98, quantity: 2, totalAmount: 196, buyerName: '苏雅菲', buyerPhone: '13811223344', deliveryType: 'STORE_PICKUP', orderTime: '2026-09-06 15:10:00', status: 'PAID' },
    { orderNo: 'ORD20260905201', productTitle: '主厨秘制法式和牛酱汁双瓶礼装', price: 128, quantity: 1, totalAmount: 128, buyerName: '杜明诚', buyerPhone: '13722334455', deliveryType: 'EXPRESS', orderTime: '2026-09-05 12:40:00', status: 'DELIVERED' }
  ],
  AUTO: [
    { orderNo: 'ORD20260906301', productTitle: '车载多功能太阳能空气净化香氛器', price: 198, quantity: 1, totalAmount: 198, buyerName: '赵天宇', buyerPhone: '13900334401', deliveryType: 'EXPRESS', orderTime: '2026-09-06 16:50:00', status: 'PAID' },
    { orderNo: 'ORD20260906302', productTitle: '无水纳米微晶玻璃除油膜防雨涂层剂 180ml', price: 68, quantity: 2, totalAmount: 136, buyerName: '孙伟东', buyerPhone: '13822334455', deliveryType: 'STORE_PICKUP', orderTime: '2026-09-06 14:05:00', status: 'PAID' },
    { orderNo: 'ORD20260905301', productTitle: '专车专用全包围环保无味静音脚垫', price: 368, quantity: 1, totalAmount: 368, buyerName: '郑志国', buyerPhone: '13733445566', deliveryType: 'EXPRESS', orderTime: '2026-09-05 10:20:00', status: 'DELIVERED' }
  ],
  RETAIL: [
    { orderNo: 'ORD20260906401', productTitle: '埃塞俄比亚耶加雪菲日晒精品咖啡豆 500g', price: 168, quantity: 1, totalAmount: 168, buyerName: '薛梦瑶', buyerPhone: '13800449901', deliveryType: 'EXPRESS', orderTime: '2026-09-06 16:20:00', status: 'PAID' },
    { orderNo: 'ORD20260906402', productTitle: '沙龙小众冷杉雪松木质调无火香薰礼盒', price: 298, quantity: 1, totalAmount: 298, buyerName: '陆文彬', buyerPhone: '13911669988', deliveryType: 'STORE_PICKUP', orderTime: '2026-09-06 14:15:20', status: 'PAID' },
    { orderNo: 'ORD20260905401', productTitle: '北欧极简手作耐热双层玻璃品茗杯', price: 128, quantity: 2, totalAmount: 256, buyerName: '郑敏', buyerPhone: '13766553344', deliveryType: 'EXPRESS', orderTime: '2026-09-05 11:10:00', status: 'DELIVERED' },
    { orderNo: 'ORD20260904401', productTitle: '高山冷萃有机原叶白毫银针礼盒 100g', price: 198, quantity: 1, totalAmount: 198, buyerName: '薛梦瑶', buyerPhone: '13800449901', deliveryType: 'STORE_PICKUP', orderTime: '2026-09-04 18:30:00', status: 'COMPLETED' },
    { orderNo: 'ORD20260903401', productTitle: '比利时手工72%黑巧纯可可脂排块', price: 88, quantity: 2, totalAmount: 176, buyerName: '陆文彬', buyerPhone: '13911669988', deliveryType: 'EXPRESS', orderTime: '2026-09-03 10:25:00', status: 'COMPLETED' }
  ]
}

// ==============================================================================
// 5. Pinia 统一真理数据仓库
// ==============================================================================

export const useSystemDataStore = defineStore('systemDataStore', () => {
  const initialIndustryKey = ((localStorage.getItem('seahorse_industry') as any) || 'BEAUTY') as IndustryCode
  const currentIndustry = ref<IndustryCode>(initialIndustryKey)
  const defaultPkg = allIndustryPackages[initialIndustryKey] || beautyPackage

  // 区分系统演示环境与新注册租户专属纯净空间
  const tenantIdStored = localStorage.getItem('seahorse_tenant_id')
  const isNewTenantStored = localStorage.getItem('seahorse_is_new_tenant') === 'true' ||
    (Boolean(tenantIdStored) && tenantIdStored !== 'T001' && tenantIdStored !== 'T002' && tenantIdStored !== 'PLATFORM')
  const isNewTenant = ref<boolean>(isNewTenantStored)

  // 纯净新租户工作空间默认门店、员工与工位
  const getNewTenantStore = (): StoreEntity[] => {
    const storeName = localStorage.getItem('seahorse_new_store_name') || localStorage.getItem('seahorse_tenant_name') || '我的智慧门店 (总店)'
    const bossName = localStorage.getItem('seahorse_new_boss_name') || localStorage.getItem('seahorse_user') || '店长/老板'
    const phone = localStorage.getItem('seahorse_new_boss_phone') || '13800000000'
    return [
      {
        storeId: 'S001',
        storeName,
        address: '待完善门店具体地址 (可在系统设置中修改)',
        managerName: bossName,
        phone,
        isHeadquarter: true,
        businessStatus: 'OPEN',
        totalSpaces: 4,
        openTime: '09:00 - 22:00'
      }
    ]
  }

  const getNewTenantStaff = (): StaffEntity[] => {
    const bossName = localStorage.getItem('seahorse_new_boss_name') || localStorage.getItem('seahorse_user') || '老板/总管理员'
    const phone = localStorage.getItem('seahorse_new_boss_phone') || '13800000000'
    return [
      {
        id: 1,
        storeId: 'S001',
        realName: bossName,
        phone,
        postName: '门店老板/总管理员',
        role: 'SUPER_ADMIN',
        department: '总经办',
        baseSalary: 0,
        serviceCommissionRate: 0,
        cardCommissionRate: 0,
        retailCommissionRate: 0,
        gender: 'MALE',
        status: 'ACTIVE',
        entryDate: new Date().toISOString().split('T')[0],
        hasSystemAccount: true,
        accountUsername: phone,
        accountStatus: 'ENABLED',
        allowedStoreIds: ['S001']
      }
    ]
  }

  const getNewTenantSpaces = (): SpaceEntity[] => [
    { id: 1, storeId: 'S001', spaceCode: 'SP01', spaceName: '1号工位/包厢', spaceType: 'ROOM', status: 'IDLE', capacity: 2, floorZone: '一楼大厅' },
    { id: 2, storeId: 'S001', spaceCode: 'SP02', spaceName: '2号工位/包厢', spaceType: 'ROOM', status: 'IDLE', capacity: 2, floorZone: '一楼大厅' },
    { id: 3, storeId: 'S001', spaceCode: 'SP03', spaceName: '3号工位/包厢', spaceType: 'ROOM', status: 'IDLE', capacity: 4, floorZone: '一楼大厅' },
    { id: 4, storeId: 'S001', spaceCode: 'SP04', spaceName: 'VIP贵宾包厢', spaceType: 'ROOM', status: 'IDLE', capacity: 6, floorZone: '二楼VIP区' }
  ]

  // 基础实体状态：若是新入驻租户，提供零污染纯净工作空间（门店、员工、商品、会员、卡项全空）
  const cachedStoresData = localStorage.getItem('seahorse_stores_data')
  let initialStores: StoreEntity[]
  try {
    initialStores = isNewTenantStored ? getNewTenantStore() : (cachedStoresData ? JSON.parse(cachedStoresData) : JSON.parse(JSON.stringify(defaultPkg.stores)))
  } catch {
    initialStores = isNewTenantStored ? getNewTenantStore() : JSON.parse(JSON.stringify(defaultPkg.stores))
  }
  const stores = ref<StoreEntity[]>(initialStores)

  const cachedStaffData = localStorage.getItem('seahorse_staff_data')
  let initialStaff: StaffEntity[]
  try {
    initialStaff = isNewTenantStored ? [] : (cachedStaffData ? JSON.parse(cachedStaffData) : JSON.parse(JSON.stringify(defaultPkg.staff)))
  } catch {
    initialStaff = isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.staff))
  }
  const staff = ref<StaffEntity[]>(initialStaff)

  const cachedProducts = localStorage.getItem('seahorse_products_data') || localStorage.getItem(`seahorse_products_${initialIndustryKey}`)
  let initialProducts: ProductEntity[]
  try {
    initialProducts = isNewTenantStored ? [] : (cachedProducts ? JSON.parse(cachedProducts) : JSON.parse(JSON.stringify(defaultPkg.products)))
  } catch {
    initialProducts = isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.products))
  }
  const products = ref<ProductEntity[]>(initialProducts)
  const materials = ref<MaterialEntity[]>(
    isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.materials))
  )
  const cachedMembers = localStorage.getItem('seahorse_members_data')
  let initialMembersList: MemberEntity[] = []
  if (cachedMembers) {
    try {
      initialMembersList = JSON.parse(cachedMembers)
    } catch {
      initialMembersList = isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.members))
    }
  } else {
    initialMembersList = isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.members))
  }
  const members = ref<MemberEntity[]>(initialMembersList)

  const persistMembers = () => {
    try {
      localStorage.setItem('seahorse_members_data', JSON.stringify(members.value))
    } catch (e) {}
  }
  const cachedCardTemplates = localStorage.getItem('seahorse_card_templates_data')
  let initialCardTemplates: CardTemplateEntity[]
  try {
    initialCardTemplates = isNewTenantStored ? [] : (cachedCardTemplates ? JSON.parse(cachedCardTemplates) : JSON.parse(JSON.stringify(defaultPkg.cardTemplates)))
  } catch {
    initialCardTemplates = isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.cardTemplates))
  }
  const cardTemplates = ref<CardTemplateEntity[]>(initialCardTemplates)

  const persistCardTemplates = () => {
    try {
      localStorage.setItem('seahorse_card_templates_data', JSON.stringify(cardTemplates.value))
    } catch (e) {}
  }

  // 线上微商城在售商品货架状态 (支持全行业与持久化)
  const cachedMallGoods = localStorage.getItem(`seahorse_mall_goods_${initialIndustryKey}`)
  const mallGoods = ref<MallGoodsEntity[]>(
    isNewTenantStored ? [] : (cachedMallGoods ? JSON.parse(cachedMallGoods) : JSON.parse(JSON.stringify(initialMallGoodsMap[initialIndustryKey] || initialMallGoodsMap.BEAUTY)))
  )

  const persistMallGoods = () => {
    try {
      localStorage.setItem(`seahorse_mall_goods_${currentIndustry.value}`, JSON.stringify(mallGoods.value))
    } catch (e) {}
  }

  // 线上微商城订单数据集 (初始注册租户严格零数据初始态，支持行业切换与发货持久化)
  const cachedMallOrders = localStorage.getItem(`seahorse_mall_orders_${initialIndustryKey}`)
  const mallOrders = ref<MallOrderEntity[]>(
    isNewTenantStored ? [] : (cachedMallOrders ? JSON.parse(cachedMallOrders) : JSON.parse(JSON.stringify(initialMallOrdersMap[initialIndustryKey] || initialMallOrdersMap.BEAUTY)))
  )

  const persistMallOrders = () => {
    try {
      localStorage.setItem(`seahorse_mall_orders_${currentIndustry.value}`, JSON.stringify(mallOrders.value))
    } catch (e) {}
  }

  const shipMallOrder = (orderNo: string, expressCompany?: string, trackingNo?: string) => {
    const o = mallOrders.value.find(item => item.orderNo === orderNo)
    if (o) {
      o.status = 'DELIVERED'
      if (expressCompany) o.expressCompany = expressCompany
      if (trackingNo) o.trackingNo = trackingNo
      persistMallOrders()
    }
  }

  // 空间/包厢/台位实体状态
  const cachedRoomsData = localStorage.getItem('seahorse_rooms_data')
  let initialSpaces: SpaceEntity[]
  try {
    initialSpaces = isNewTenantStored ? [] : (cachedRoomsData ? JSON.parse(cachedRoomsData) : JSON.parse(JSON.stringify(industrySpacesMap[initialIndustryKey] || industrySpacesMap.BEAUTY)))
  } catch {
    initialSpaces = isNewTenantStored ? [] : JSON.parse(JSON.stringify(industrySpacesMap[initialIndustryKey] || industrySpacesMap.BEAUTY))
  }
  const spaces = ref<SpaceEntity[]>(initialSpaces)

  // 事件流水与在场动态状态
  const liveSessions = ref<LiveSession[]>(
    isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.liveSessions))
  )
  const costItems = ref<CostItemEntity[]>(
    isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.baseCosts))
  )
  const cachedRecharges = localStorage.getItem('seahorse_recharge_orders_data')
  let initialRechargesList: RechargeOrder[] = []
  if (cachedRecharges) {
    try {
      initialRechargesList = JSON.parse(cachedRecharges)
    } catch {
      initialRechargesList = isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.rechargeOrders))
    }
  } else {
    initialRechargesList = isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.rechargeOrders))
  }
  const rechargeOrders = ref<RechargeOrder[]>(initialRechargesList)

  const persistRechargeOrders = () => {
    try {
      localStorage.setItem('seahorse_recharge_orders_data', JSON.stringify(rechargeOrders.value))
    } catch (e) {}
  }

  const consumeOrders = ref<ConsumeOrder[]>(
    isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.consumeOrders))
  )
  const timeCards = ref<TimeCardItem[]>(
    isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.timeCards))
  )

  const cachedPoints = localStorage.getItem('seahorse_points_ledger_data')
  let initialPointsList: PointsLog[] = []
  if (cachedPoints) {
    try {
      initialPointsList = JSON.parse(cachedPoints)
    } catch {
      initialPointsList = isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.pointsLedger))
    }
  } else {
    initialPointsList = isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.pointsLedger))
  }
  const pointsLedger = ref<PointsLog[]>(initialPointsList)

  const persistPointsLedger = () => {
    try {
      localStorage.setItem('seahorse_points_ledger_data', JSON.stringify(pointsLedger.value))
    } catch (e) {}
  }
  const rewardsLedger = ref<RewardLog[]>(
    isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.rewardsLedger))
  )
  const expenses = ref<ExpenseRecord[]>(
    isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.expenses))
  )
  const cachedAptData = localStorage.getItem('seahorse_appointments_data')
  let initialAppointments: AppointmentRecord[]
  try {
    initialAppointments = isNewTenantStored ? [] : (cachedAptData ? JSON.parse(cachedAptData) : JSON.parse(JSON.stringify(defaultPkg.appointments)))
  } catch {
    initialAppointments = isNewTenantStored ? [] : JSON.parse(JSON.stringify(defaultPkg.appointments))
  }
  const appointments = ref<AppointmentRecord[]>(initialAppointments)

  // 获客裂变与营销活动状态 (新租户严格零数据初始态)
  const cachedCampaigns = localStorage.getItem('seahorse_campaigns')
  const campaigns = ref<CampaignEntity[]>(
    isNewTenantStored ? [] : (cachedCampaigns ? JSON.parse(cachedCampaigns) : JSON.parse(JSON.stringify(initialIndustryCampaignsMap[initialIndustryKey] || initialIndustryCampaignsMap.BEAUTY)))
  )

  const persistCampaigns = () => {
    try {
      localStorage.setItem('seahorse_campaigns', JSON.stringify(campaigns.value))
    } catch (e) {}
  }

  const addCampaign = (campaign: Omit<CampaignEntity, 'id'>) => {
    const newId = Date.now()
    const item: CampaignEntity = { ...campaign, id: newId }
    campaigns.value.unshift(item)
    persistCampaigns()
    return item
  }

  const updateCampaign = (id: number, patch: Partial<CampaignEntity>) => {
    const idx = campaigns.value.findIndex(c => c.id === id)
    if (idx >= 0) {
      campaigns.value[idx] = { ...campaigns.value[idx], ...patch }
      persistCampaigns()
    }
  }

  const deleteCampaign = (id: number) => {
    campaigns.value = campaigns.value.filter(c => c.id !== id)
    persistCampaigns()
  }

  const toggleCampaignStatus = (id: number) => {
    const item = campaigns.value.find(c => c.id === id)
    if (item) {
      item.status = item.status === 'RUNNING' ? 'FINISHED' : 'RUNNING'
      persistCampaigns()
    }
  }

  const loadIndustryCampaigns = (industryKey?: string) => {
    const key = (industryKey || currentIndustry.value) as IndustryCode
    const preset = initialIndustryCampaignsMap[key] || initialIndustryCampaignsMap.BEAUTY
    campaigns.value = JSON.parse(JSON.stringify(preset))
    persistCampaigns()
  }

  // 打印小票模板与外设配置
  const storedReceipt = localStorage.getItem('seahorse_receipt_template')
  let initialReceipt = { ...defaultReceiptConfig }
  if (storedReceipt) {
    try {
      const parsed = JSON.parse(storedReceipt)
      if (parsed.qrCodeText && parsed.qrCodeText.includes('seahorse.store')) {
        parsed.qrCodeText = buildMemberBenefitsUrl()
      }
      initialReceipt = { ...initialReceipt, ...parsed }
    } catch {}
  } else {
    initialReceipt.qrCodeText = buildMemberBenefitsUrl()
  }
  const receiptTemplate = ref<ReceiptTemplateConfig>(initialReceipt)

  // 动态合并当前店铺真实资料 (店铺名称主抬头、服务热线、地址与专属二维码)
  const getResolvedReceiptTemplate = (targetStoreId?: string): ReceiptTemplateConfig => {
    const sId = targetStoreId || localStorage.getItem('seahorse_store_id') || 'S001'
    const matchedStore = stores.value.find(s => s.storeId === sId || (s as any).id === sId)
    let basicSettings: any = null
    try {
      const raw = localStorage.getItem('seahorse_basic_settings')
      if (raw) basicSettings = JSON.parse(raw)
    } catch {}

    const realStoreName = basicSettings?.storeName ||
                         localStorage.getItem('seahorse_store_name') ||
                         matchedStore?.storeName ||
                         '海马智慧门店'

    const realStorePhone = basicSettings?.phone ||
                          localStorage.getItem('seahorse_store_phone') ||
                          matchedStore?.phone ||
                          '400-888-6688'

    const realStoreAddress = basicSettings?.address ||
                            localStorage.getItem('seahorse_store_address') ||
                            matchedStore?.address ||
                            '智慧商业中心 101号铺'

    const cfg: ReceiptTemplateConfig = JSON.parse(JSON.stringify(receiptTemplate.value))

    // 若未特别设定或仍为老旧假数据，自动绑定为当前店铺真实信息
    if (!cfg.storeHeaderTitle || cfg.storeHeaderTitle === '海马美业·全国连锁旗舰店' || cfg.storeHeaderTitle === '海马智慧门店 (旗舰体验中心)') {
      cfg.storeHeaderTitle = realStoreName
    }
    if (!cfg.serviceHotline || cfg.serviceHotline === '020-88996611') {
      cfg.serviceHotline = realStorePhone
    }
    if (!cfg.storeAddress || cfg.storeAddress === '广州市天河区天河路208号天河城购物中心4楼') {
      cfg.storeAddress = realStoreAddress
    }
    if (!cfg.qrCodeText || cfg.qrCodeText.includes('seahorse.store')) {
      cfg.qrCodeText = buildMemberBenefitsUrl(sId)
    }
    return cfg
  }

  // 扫码盒子硬件与支付通道持久化配置
  let initialPayment: PaymentChannelConfig = JSON.parse(JSON.stringify(defaultPaymentConfig))
  try {
    const storedPayment = localStorage.getItem('seahorse_payment_config')
    if (storedPayment) {
      initialPayment = deepMergePaymentConfig(defaultPaymentConfig, JSON.parse(storedPayment))
    }
  } catch (e) {
    console.error('Failed to parse seahorse_payment_config', e)
  }
  const paymentConfig = ref<PaymentChannelConfig>(initialPayment)

  const updatePaymentConfig = (cfg: Partial<PaymentChannelConfig>) => {
    paymentConfig.value = deepMergePaymentConfig(paymentConfig.value, cfg)
    localStorage.setItem('seahorse_payment_config', JSON.stringify(paymentConfig.value))
  }

  const loadPaymentRoutePreset = (route: PaymentRouteType) => {
    paymentConfig.value.activeRoute = route
    if (route === 'ROUTE_1_INDIVIDUAL') {
      paymentConfig.value.route1_individual = JSON.parse(JSON.stringify(defaultPaymentConfig.route1_individual))
    } else if (route === 'ROUTE_2_AGGREGATE') {
      paymentConfig.value.route2_aggregate = JSON.parse(JSON.stringify(defaultPaymentConfig.route2_aggregate))
    } else {
      paymentConfig.value.route3_sandbox = JSON.parse(JSON.stringify(defaultPaymentConfig.route3_sandbox))
    }
    localStorage.setItem('seahorse_payment_config', JSON.stringify(paymentConfig.value))
  }

  const updateReceiptTemplate = (cfg: Partial<ReceiptTemplateConfig>) => {
    receiptTemplate.value = { ...receiptTemplate.value, ...cfg }
    localStorage.setItem('seahorse_receipt_template', JSON.stringify(receiptTemplate.value))
  }

  // 规章制度与员工意见箱（严格零制造虚假数据初始态，未配置时为纯净空列表）
  const initialStoreRegulations: RegulationEntity[] = []
  const initialStaffFeedbacks: StaffFeedbackEntity[] = []

  // 规章制度与意见箱持久化状态（严格剔除预置假数据）
  const loadStoredRegulations = (): RegulationEntity[] => {
    if (isNewTenantStored) return []
    try {
      const raw = localStorage.getItem('seahorse_store_regulations')
      if (raw) {
        const parsed = JSON.parse(raw)
        if (Array.isArray(parsed)) {
          // 彻底剔除预置历史假数据
          const clean = parsed.filter((r: any) => !['REG-2026-001', 'REG-2026-002', 'REG-2026-003', 'REG-2026-004'].includes(r.id))
          if (clean.length !== parsed.length) {
            localStorage.setItem('seahorse_store_regulations', JSON.stringify(clean))
          }
          return clean
        }
      }
    } catch (e) {}
    return []
  }

  const loadStoredFeedbacks = (): StaffFeedbackEntity[] => {
    if (isNewTenantStored) return []
    try {
      const raw = localStorage.getItem('seahorse_staff_feedbacks')
      if (raw) {
        const parsed = JSON.parse(raw)
        if (Array.isArray(parsed)) {
          const clean = parsed.filter((f: any) => !['FB-2026-001', 'FB-2026-002'].includes(f.id))
          if (clean.length !== parsed.length) {
            localStorage.setItem('seahorse_staff_feedbacks', JSON.stringify(clean))
          }
          return clean
        }
      }
    } catch (e) {}
    return []
  }

  const regulations = ref<RegulationEntity[]>(loadStoredRegulations())
  const staffFeedbacks = ref<StaffFeedbackEntity[]>(loadStoredFeedbacks())

  const persistRegulations = () => {
    try {
      localStorage.setItem('seahorse_store_regulations', JSON.stringify(regulations.value))
    } catch (e) {}
  }

  const persistFeedbacks = () => {
    try {
      localStorage.setItem('seahorse_staff_feedbacks', JSON.stringify(staffFeedbacks.value))
    } catch (e) {}
  }

  const saveRegulation = (item: RegulationEntity) => {
    const idx = regulations.value.findIndex(r => r.id === item.id)
    if (idx >= 0) {
      regulations.value[idx] = { ...item }
    } else {
      regulations.value.unshift({ ...item })
    }
    persistRegulations()
  }

  const deleteRegulation = (id: string) => {
    regulations.value = regulations.value.filter(r => r.id !== id)
    persistRegulations()
  }

  const signRegulation = (regId: string, signature: RegulationSignature) => {
    const reg = regulations.value.find(r => r.id === regId)
    if (reg) {
      if (!reg.signatures) reg.signatures = []
      const existIdx = reg.signatures.findIndex(s => String(s.staffId) === String(signature.staffId))
      if (existIdx >= 0) {
        reg.signatures[existIdx] = signature
      } else {
        reg.signatures.push(signature)
      }
      if (!reg.readStaffIds) reg.readStaffIds = []
      if (!reg.readStaffIds.some(id => String(id) === String(signature.staffId))) {
        reg.readStaffIds.push(signature.staffId)
      }
      persistRegulations()
    }
  }

  const markRegulationRead = (regId: string, staffId: number | string) => {
    const reg = regulations.value.find(r => r.id === regId)
    if (reg) {
      if (!reg.readStaffIds) reg.readStaffIds = []
      if (!reg.readStaffIds.some(id => String(id) === String(staffId))) {
        reg.readStaffIds.push(staffId)
        persistRegulations()
      }
    }
  }

  const submitStaffFeedback = (fb: StaffFeedbackEntity) => {
    staffFeedbacks.value.unshift(fb)
    persistFeedbacks()
  }

  const replyStaffFeedback = (feedbackId: string, status: StaffFeedbackEntity['status'], replyContent: string, replierName: string) => {
    const fb = staffFeedbacks.value.find(f => f.id === feedbackId)
    if (fb) {
      fb.status = status
      fb.replyContent = replyContent
      fb.replierName = replierName
      fb.replyTime = new Date().toLocaleString()
      persistFeedbacks()
    }
  }

  // =========================================================================
  // 平台级非研发人员建言反馈中心 (Platform Feedback)
  // =========================================================================
  const initialPlatformFeedbacks: PlatformFeedbackEntity[] = []

  // 彻底清除历史残留的假订阅与账单缓存（保留真实提交的建言反馈与租户活动日志）
  try {
    localStorage.removeItem('seahorse_vendor_subscriptions')
    localStorage.removeItem('seahorse_vendor_billing_records')
  } catch (e) {}

  let initialFeedbacksList: PlatformFeedbackEntity[] = []
  try {
    const cachedPlatformFeedbacks = localStorage.getItem('seahorse_platform_feedbacks')
    if (cachedPlatformFeedbacks) initialFeedbacksList = JSON.parse(cachedPlatformFeedbacks)
  } catch (e) {}
  const platformFeedbacks = ref<PlatformFeedbackEntity[]>(initialFeedbacksList)

  let initialTenantActivityLogs: TenantActivityLog[] = []
  try {
    const cachedActivityLogs = localStorage.getItem('seahorse_tenant_activity_logs')
    if (cachedActivityLogs) initialTenantActivityLogs = JSON.parse(cachedActivityLogs)
  } catch (e) {}
  const tenantActivityLogs = ref<TenantActivityLog[]>(initialTenantActivityLogs)
  const tenantDaytimeUsageStats = ref<TenantDaytimeUsageStat[]>([])

  const persistPlatformFeedbacks = () => {
    try {
      localStorage.setItem('seahorse_platform_feedbacks', JSON.stringify(platformFeedbacks.value))
    } catch (e) {}
  }

  const persistTenantActivityLogs = () => {
    try {
      localStorage.setItem('seahorse_tenant_activity_logs', JSON.stringify(tenantActivityLogs.value))
    } catch (e) {}
  }

  const submitPlatformFeedback = (fb: PlatformFeedbackEntity) => {
    platformFeedbacks.value.unshift(fb)
    persistPlatformFeedbacks()
  }

  const replyPlatformFeedback = (
    feedbackId: string,
    devReply: string,
    status: PlatformFeedbackEntity['status'],
    devReplier: string = '平台研发总管',
    targetVersion?: string
  ) => {
    const target = platformFeedbacks.value.find(f => f.id === feedbackId)
    if (target) {
      target.devReply = devReply
      target.status = status
      target.devReplier = devReplier
      target.replyTime = new Date().toLocaleString()
      target.replyAt = target.replyTime
      if (targetVersion) target.targetVersion = targetVersion
      persistPlatformFeedbacks()
    }
  }

  const logTenantActivity = (logItem: Omit<TenantActivityLog, 'id' | 'timestamp'>) => {
    const now = new Date()
    const hour = now.getHours()
    let timeSlot: TenantActivityLog['timeSlot'] = 'AFTERNOON'
    let timeSlotName = '下午黄金营业期 (14:00-18:00)'
    let isDaytime = true
    if (hour >= 8 && hour < 11.5) {
      timeSlot = 'MORNING'
      timeSlotName = '早间到店早高峰 (08:00-11:30)'
    } else if (hour >= 11.5 && hour < 14) {
      timeSlot = 'NOON'
      timeSlotName = '午间营业高峰 (11:30-14:00)'
    } else if (hour >= 14 && hour < 18) {
      timeSlot = 'AFTERNOON'
      timeSlotName = '下午黄金营业期 (14:00-18:00)'
    } else if (hour >= 18 && hour < 22) {
      timeSlot = 'EVENING'
      timeSlotName = '晚间夜市营业期 (18:00-22:00)'
    } else {
      timeSlot = 'NIGHT'
      timeSlotName = '夜间闲时 (22:00-08:00)'
      isDaytime = false
    }

    const fullLog: TenantActivityLog = {
      id: `LOG-${Date.now()}`,
      timestamp: now.toLocaleString(),
      timeSlot,
      timeSlotName,
      isDaytime,
      ...logItem
    }
    tenantActivityLogs.value.unshift(fullLog)
    persistTenantActivityLogs()
  }

  // 考勤打卡与请假审批状态 (新注册租户无历史考勤，纯净化为空)
  const attendanceRecords = ref<AttendanceRecordEntity[]>(isNewTenantStored ? [] : JSON.parse(JSON.stringify(initialAttendanceList)))
  const leaveApplications = ref<LeaveApplicationEntity[]>(isNewTenantStored ? [] : JSON.parse(JSON.stringify(initialLeaveList)))

  const syncAttendanceFromPlatform = (platform: 'WECHAT_WORK' | 'DINGTALK') => {
    const today = new Date().toISOString().split('T')[0]
    const list: AttendanceRecordEntity[] = staff.value.map((s, idx) => {
      const isLate = idx === 1
      const isField = idx === 4
      return {
        id: `ATT-${Date.now()}-${idx + 1}`,
        staffName: s.realName,
        phone: s.phone,
        postName: s.postName,
        workDate: today,
        checkInTime: isLate ? '09:15:20' : (isField ? '13:20:00' : `08:${45 + idx}:10`),
        checkInStatus: isLate ? 'LATE' : (isField ? 'FIELD_WORK' : 'NORMAL'),
        checkOutTime: isField ? '18:30:00' : '21:00:00',
        checkOutStatus: 'NORMAL',
        workHours: isField ? 5.2 : 12.0,
        checkInLocation: isField ? '广州正佳广场外勤 (GPS定位)' : '门店高速Wi-Fi打卡',
        platformSource: platform,
        notes: isLate ? '迟到15分钟' : (isField ? '兼职/外勤巡店' : '准时到岗')
      }
    })
    attendanceRecords.value = list
    return list
  }

  const applyLeave = (data: Partial<LeaveApplicationEntity>) => {
    const now = new Date()
    const nowStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    const defaultApprover = data.currentApprover || (localStorage.getItem('seahorse_user') || '店长')
    const newApp: LeaveApplicationEntity = {
      id: `LV-${Date.now()}`,
      staffId: data.staffId || 2,
      staffName: data.staffName || '员工',
      phone: data.phone || '13800000000',
      postName: data.postName || '技术骨干',
      department: data.department || '门店设计部',
      leaveType: data.leaveType || 'PERSONAL',
      leaveTypeName: data.leaveTypeName || '事假',
      startTime: data.startTime || `${nowStr}`,
      endTime: data.endTime || `${nowStr}`,
      totalHours: data.totalHours || 8.0,
      totalDays: data.totalDays || 1.0,
      reason: data.reason || '个人事务处理',
      status: 'PENDING',
      applyTime: nowStr,
      currentApprover: defaultApprover,
      timeline: [
        { stepName: '提交请假申请', operator: data.staffName || '员工', time: nowStr, status: 'SUCCESS', comment: `事由：${data.reason || '个人事务'}` },
        { stepName: '门店店长初审', operator: defaultApprover, time: '', status: 'CURRENT', comment: '待店长审批处理' },
        { stepName: '人事考勤归档', operator: '系统自动归档', time: '', status: 'PENDING', comment: '等待上级节点批准' }
      ]
    }
    leaveApplications.value.unshift(newApp)
    return newApp
  }

  const auditLeave = (leaveId: string, action: 'APPROVE' | 'REJECT', notes?: string, approver?: string) => {
    const target = leaveApplications.value.find(l => l.id === leaveId)
    if (!target) return null
    const now = new Date()
    const nowStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    const isApprove = action === 'APPROVE'
    target.status = isApprove ? 'APPROVED' : 'REJECTED'
    target.auditTime = nowStr
    target.auditNotes = notes || (isApprove ? '同意请假申请，请做好交接' : '驳回申请')
    if (approver) {
      target.currentApprover = approver
    }
    if (target.timeline && target.timeline.length >= 2) {
      if (approver) {
        target.timeline[1].operator = approver
      }
      target.timeline[1].time = nowStr
      target.timeline[1].status = isApprove ? 'SUCCESS' : 'REJECTED'
      target.timeline[1].comment = target.auditNotes
      if (isApprove && target.timeline.length >= 3) {
        target.timeline[2].time = nowStr
        target.timeline[2].status = 'SUCCESS'
        target.timeline[2].comment = `系统自动核扣考勤工时 ${target.totalHours} 小时`
      }
    }
    return target
  }

  // --------------------------------------------------------------------------
  // A. 会员全维度动态计算
  // --------------------------------------------------------------------------
  const membersWithStats = computed(() => {
    return members.value.map(m => {
      const memberRecharges = rechargeOrders.value.filter(r => r.memberId === m.id)
      const totalPrincipalRecharged = memberRecharges.reduce((sum, r) => sum + r.principalAmount, 0)
      const totalGiftRecharged = memberRecharges.reduce((sum, r) => sum + r.giftAmount, 0)

      const memberConsumes = consumeOrders.value.filter(c => c.memberId === m.id && c.status === 'COMPLETED')
      const totalPrincipalDeducted = memberConsumes.reduce((sum, c) => sum + c.cardDeductPrincipal, 0)
      const totalGiftDeducted = memberConsumes.reduce((sum, c) => sum + c.cardDeductGift, 0)
      const totalCashPaid = memberConsumes.reduce((sum, c) => sum + c.cashierPaidAmount, 0)

      const principalBalance = Math.max(0, totalPrincipalRecharged - totalPrincipalDeducted)
      const giftBalance = Math.max(0, totalGiftRecharged - totalGiftDeducted)
      const totalBalance = principalBalance + giftBalance
      const totalSpentFromConsumes = memberConsumes.reduce((sum, c) => {
        const val = Number(c.totalAmount) || (Number(c.cardDeductPrincipal || 0) + Number(c.cardDeductGift || 0) + Number(c.cashierPaidAmount || 0))
        return sum + val
      }, 0)
      const totalSpent = totalSpentFromConsumes > 0 ? totalSpentFromConsumes : (Number(m.totalSpent) || 0)
      const visitCount = memberConsumes.length > 0 ? memberConsumes.length : (m.visitCount || 0)
      const lastVisitTime = memberConsumes.length > 0
        ? memberConsumes[memberConsumes.length - 1].createTime
        : m.registerTime

      const memberPoints = pointsLedger.value
        .filter(p => p.memberId === m.id)
        .reduce((sum, p) => sum + p.pointsDelta, 0)

      const memberRewards = rewardsLedger.value
        .filter(r => r.memberId === m.id)
        .reduce((sum, r) => sum + r.rewardDelta, 0)

      const memberTimeCards = timeCards.value.filter(t => t.memberId === m.id)

      return {
        ...m,
        totalBalance: Number(totalBalance.toFixed(2)),
        principalBalance: Number(principalBalance.toFixed(2)),
        giftBalance: Number(giftBalance.toFixed(2)),
        totalSpent: Number(totalSpent.toFixed(2)),
        visitCount,
        lastVisitTime,
        points: memberPoints,
        rewardBonus: Number(memberRewards.toFixed(2)),
        timeCards: memberTimeCards
      }
    })
  })

  // --------------------------------------------------------------------------
  // B. 员工全维度业绩与提成动态计算
  // --------------------------------------------------------------------------
  const staffWithStats = computed(() => {
    return staff.value.map(s => {
      const serviceOrders = consumeOrders.value.filter(
        c => c.primaryTechnicianId === s.id && c.status === 'COMPLETED'
      )
      const serviceCount = serviceOrders.length
      const serviceRevenue = serviceOrders.reduce((sum, c) => {
        const itemSum = c.items.filter(i => i.type === 'SERVICE').reduce((s2, i) => s2 + i.price * i.quantity, 0)
        return sum + itemSum
      }, 0)

      const cardRecharges = rechargeOrders.value.filter(r => r.sellerEmployeeId === s.id)
      const cardSales = cardRecharges.reduce((sum, r) => sum + r.principalAmount, 0)

      const retailSales = serviceOrders.reduce((sum, c) => {
        const itemSum = c.items.filter(i => i.type === 'RETAIL').reduce((s2, i) => s2 + i.price * i.quantity, 0)
        return sum + itemSum
      }, 0)

      const serviceCommission = serviceRevenue * s.serviceCommissionRate
      const cardCommission = cardSales * s.cardCommissionRate
      const retailCommission = retailSales * s.retailCommissionRate
      const totalCommission = Number((serviceCommission + cardCommission + retailCommission).toFixed(2))
      const calculatedSalary = Number((s.baseSalary + totalCommission).toFixed(2))

      const commissionRecords: any[] = []
      serviceOrders.forEach(o => {
        o.items.forEach(it => {
          const rate = it.type === 'SERVICE' ? s.serviceCommissionRate : s.retailCommissionRate
          const money = it.price * it.quantity * rate
          commissionRecords.push({
            orderNo: o.orderNo,
            type: it.type === 'SERVICE' ? '工单手工提成' : '产品销售提成',
            itemTitle: it.productName,
            amount: it.price * it.quantity,
            rateText: `${(rate * 100).toFixed(0)}%`,
            commission: Number(money.toFixed(2)),
            date: o.createTime
          })
        })
      })
      cardRecharges.forEach(r => {
        const money = r.principalAmount * s.cardCommissionRate
        commissionRecords.push({
          orderNo: r.orderNo,
          type: '充值开卡提成',
          itemTitle: `会员开卡充值本金 ￥${r.principalAmount}`,
          amount: r.principalAmount,
          rateText: `${(s.cardCommissionRate * 100).toFixed(0)}%`,
          commission: Number(money.toFixed(2)),
          date: r.createTime
        })
      })

      return {
        ...s,
        serviceCount,
        serviceRevenue: Number(serviceRevenue.toFixed(2)),
        cardSales: Number(cardSales.toFixed(2)),
        retailSales: Number(retailSales.toFixed(2)),
        totalCommission,
        calculatedSalary,
        commissionRecords
      }
    })
  })

  // --------------------------------------------------------------------------
  // C. 统计报表 11 大子项动态计算引擎
  // --------------------------------------------------------------------------
  const reportsData = computed(() => {
    // 1. 收入明细
    const incomeList: any[] = []
    rechargeOrders.value.forEach(r => {
      const m = members.value.find(mem => mem.id === r.memberId)
      incomeList.push({
        id: `RC_${r.id}`,
        customerName: m?.name || '会员',
        phone: m?.phone || '-',
        income: r.principalAmount,
        type: '充值办卡',
        rawType: 'RECHARGE',
        details: `开卡充值本金 ￥${r.principalAmount}，赠送金 ￥${r.giftAmount}`,
        date: r.createTime,
        status: '已完成',
        paymentMethod: r.paymentMethod
      })
    })

    consumeOrders.value.filter(c => c && c.status === 'COMPLETED').forEach(c => {
      const m = members.value.find(mem => mem.id === c.memberId)
      if (c.cashierPaidAmount > 0) {
        const isRetail = c.type === 'RETAIL' || (Array.isArray(c.items) && c.items.length > 0 && c.items.every(i => i.type === 'RETAIL'))
        const isExtra = c.cardDeductPrincipal > 0 || c.cardDeductGift > 0
        const itemNames = (c.items || []).map(i => i?.productName || '').filter(Boolean).join('、') || '消费服务'
        incomeList.push({
          id: `CS_${c.id}`,
          customerName: m?.name || '会员',
          phone: m?.phone || '-',
          income: c.cashierPaidAmount,
          type: isRetail ? '零售收银' : (isExtra ? '扣卡另付' : '项目收银'),
          rawType: isRetail ? 'RETAIL' : (isExtra ? 'CARD_EXTRA' : 'SERVICE'),
          details: `${itemNames} (实收 ￥${c.cashierPaidAmount})`,
          date: c.createTime || '',
          status: '已完成',
          paymentMethod: c.paymentMethod
        })
      }
    })

    // 2. 扣卡统计
    const cardDeductList = consumeOrders.value
      .filter(c => c && ((c.cardDeductPrincipal || 0) > 0 || (c.cardDeductGift || 0) > 0) && c.status === 'COMPLETED')
      .map(c => {
        const m = membersWithStats.value.find(mem => mem.id === c.memberId)
        const staffMem = staff.value.find(s => s.id === c.primaryTechnicianId)
        const total = (c.cardDeductPrincipal || 0) + (c.cardDeductGift || 0)
        return {
          id: c.id,
          customerName: m?.name || '会员',
          phone: m?.phone || '-',
          serviceName: (c.items || []).map(i => i?.productName || '').filter(Boolean).join('、') || '卡项核销',
          deductPrincipal: c.cardDeductPrincipal || 0,
          deductGift: c.cardDeductGift || 0,
          deductTotal: total,
          remainingBalance: `￥${m?.totalBalance != null ? Number(m.totalBalance).toFixed(2) : '0.00'}`,
          date: c.createTime || '',
          operator: staffMem ? `${staffMem.realName} (${staffMem.postName})` : '技师',
          rawType: 'RECHARGE_CARD'
        }
      })

    // 3. 积分统计
    const pointsList = pointsLedger.value.map(p => {
      const m = members.value.find(mem => mem.id === p.memberId)
      return {
        id: p.id,
        customerName: m?.name || '会员',
        phone: m?.phone || '-',
        pointsChange: p.pointsDelta || 0,
        changeType: p.typeName || '积分变更',
        balance: p.balanceAfter || 0,
        date: p.createTime || '',
        operator: p.operator || '系统',
        rawType: (p.pointsDelta || 0) > 0 ? 'GIVE' : 'USE'
      }
    })

    // 4. 奖励金统计
    const rewardsList = rewardsLedger.value.map(r => {
      const m = members.value.find(mem => mem.id === r.memberId)
      const refM = members.value.find(mem => mem.id === r.referredMemberId)
      return {
        id: r.id,
        customerName: m?.name || '会员',
        phone: m?.phone || '-',
        rewardChange: r.rewardDelta || 0,
        reason: r.reason || '邀请奖励',
        referredCustomer: refM ? `${refM.name} (${refM.phone})` : '新会员',
        currentReward: `￥${r.balanceAfter != null ? Number(r.balanceAfter).toFixed(2) : '0.00'}`,
        date: r.createTime || '',
        rawType: 'INVITE'
      }
    })

    // 5. 新增会员统计
    const newMembersList = membersWithStats.value.map(m => {
      const firstRecharge = rechargeOrders.value.find(r => r.memberId === m.id)
      const referrer = members.value.find(mem => mem.id === m.referrerId)
      return {
        id: m.id,
        memberNo: m.memberNo,
        name: m.name,
        phone: m.phone,
        level: m.levelName,
        initialRecharge: firstRecharge ? firstRecharge.principalAmount : 0,
        giftCoupon: '新人专享50元抵用券',
        date: m.registerTime,
        referrer: referrer ? `${referrer.name} (老带新)` : '自主到店开卡',
        rawType: m.level
      }
    })

    // 6. 收入方式统计
    let wechatTotal = 0, wechatCount = 0
    let alipayTotal = 0, alipayCount = 0
    let cardPrincipalTotal = 0, cardPrincipalCount = 0
    let offlineTotal = 0, offlineCount = 0

    rechargeOrders.value.forEach(r => {
      if (r.paymentMethod === 'WECHAT') { wechatTotal += r.principalAmount; wechatCount++ }
      else if (r.paymentMethod === 'ALIPAY') { alipayTotal += r.principalAmount; alipayCount++ }
      else { offlineTotal += r.principalAmount; offlineCount++ }
    })

    consumeOrders.value.filter(c => c.status === 'COMPLETED').forEach(c => {
      if (c.cardDeductPrincipal > 0) {
        cardPrincipalTotal += c.cardDeductPrincipal
        cardPrincipalCount++
      }
      if (c.cashierPaidAmount > 0) {
        if (c.paymentMethod === 'WECHAT') { wechatTotal += c.cashierPaidAmount; wechatCount++ }
        else if (c.paymentMethod === 'ALIPAY') { alipayTotal += c.cashierPaidAmount; alipayCount++ }
        else { offlineTotal += c.cashierPaidAmount; offlineCount++ }
      }
    })

    const grandRealIncome = wechatTotal + alipayTotal + cardPrincipalTotal + offlineTotal
    const isCurrentNewTenant = isNewTenant.value ||
      localStorage.getItem('seahorse_is_new_tenant') === 'true' ||
      localStorage.getItem('seahorse_role') === 'TENANT_ADMIN'

    // 新租户或无订单时纯净化：严格清空，不展示任何虚拟行
    const paymentMethodsList = (isCurrentNewTenant || grandRealIncome === 0) ? [] : [
      {
        id: 1,
        methodName: '微信商业收款码',
        transactionCount: wechatCount,
        amount: Number(wechatTotal.toFixed(2)),
        ratio: grandRealIncome > 0 ? Number(((wechatTotal / grandRealIncome) * 100).toFixed(1)) : 0,
        refundAmount: 0,
        netIncome: Number(wechatTotal.toFixed(2)),
        rawType: 'WECHAT'
      },
      {
        id: 2,
        methodName: '双轨储值本金划扣',
        transactionCount: cardPrincipalCount,
        amount: Number(cardPrincipalTotal.toFixed(2)),
        ratio: grandRealIncome > 0 ? Number(((cardPrincipalTotal / grandRealIncome) * 100).toFixed(1)) : 0,
        refundAmount: 0,
        netIncome: Number(cardPrincipalTotal.toFixed(2)),
        rawType: 'CARD'
      },
      {
        id: 3,
        methodName: '支付宝在线收单',
        transactionCount: alipayCount,
        amount: Number(alipayTotal.toFixed(2)),
        ratio: grandRealIncome > 0 ? Number(((alipayTotal / grandRealIncome) * 100).toFixed(1)) : 0,
        refundAmount: 0,
        netIncome: Number(alipayTotal.toFixed(2)),
        rawType: 'ALIPAY'
      },
      {
        id: 4,
        methodName: '前台现金及银联POS',
        transactionCount: offlineCount,
        amount: Number(offlineTotal.toFixed(2)),
        ratio: grandRealIncome > 0 ? Number(((offlineTotal / grandRealIncome) * 100).toFixed(1)) : 0,
        refundAmount: 0,
        netIncome: Number(offlineTotal.toFixed(2)),
        rawType: 'OFFLINE'
      }
    ]

    // 7. 利润统计
    const totalGrossRevenue = incomeList.reduce((sum, i) => sum + (Number(i.income) || 0), 0)
    const totalBomCost = consumeOrders.value
      .filter(c => c && c.status === 'COMPLETED')
      .reduce((sum, c) => sum + (c.items || []).reduce((s2, it) => s2 + (Number(it?.bomCost) || 0) * (Number(it?.quantity) || 0), 0), 0)
    const totalStaffCommissions = staffWithStats.value.reduce((sum, s) => sum + (Number(s.totalCommission) || 0), 0)
    const rentExpenses = expenses.value
      .filter(e => e && e.category === 'RENT')
      .reduce((sum, e) => sum + (Number(e.amount) || 0), 0)

    const totalOperationalCost = totalBomCost + totalStaffCommissions + rentExpenses
    const netProfit = totalGrossRevenue - totalOperationalCost
    const marginRate = totalGrossRevenue > 0
      ? ((netProfit / totalGrossRevenue) * 100).toFixed(1) + '%'
      : '0.0%'

    // 新租户或无经营数据时纯净化：严格清空，不展示写死的周期模拟行
    const profitList = (isCurrentNewTenant || (totalGrossRevenue === 0 && totalOperationalCost === 0)) ? [] : [
      {
        id: 1,
        period: '2026年9月第1周',
        grossRevenue: `￥${totalGrossRevenue.toFixed(2)}`,
        bomCost: `￥${totalBomCost.toFixed(2)}`,
        rentCost: `￥${rentExpenses.toFixed(2)}`,
        salaryCommission: `￥${totalStaffCommissions.toFixed(2)}`,
        netProfit: `${netProfit >= 0 ? '+' : ''}${netProfit.toFixed(2)}`,
        profitMargin: marginRate,
        rawType: 'WEEK'
      }
    ]

    // 8. 员工业绩统计
    const staffPerformanceList = staffWithStats.value.map(s => ({
      id: s.id,
      staffName: s.realName,
      post: s.postName,
      department: s.department,
      serviceCount: s.serviceCount,
      serviceRevenue: s.serviceRevenue,
      cardSales: s.cardSales,
      retailSales: s.retailSales,
      totalCommission: s.totalCommission,
      rawType: s.role
    }))

    // 9. 未消费余次统计
    const remainingTimesList = timeCards.value.map(t => {
      const m = members.value.find(mem => mem.id === t.memberId)
      const remain = (t.totalTimes || 0) - (t.usedTimes || 0)
      return {
        id: t.id,
        customerName: m?.name || '会员',
        phone: m?.phone || '-',
        cardName: t.cardName || '次卡',
        timeCardName: t.cardName || '次卡',
        totalTimes: t.totalTimes || 0,
        usedTimes: t.usedTimes || 0,
        remainingTimes: remain,
        unitValue: t.unitPrice || 0,
        unconsumedWorth: Number((remain * (t.unitPrice || 0)).toFixed(2)),
        expireDate: t.expireDate || '',
        rawType: remain > 0 ? 'ACTIVE' : 'USED_UP'
      }
    })

    // 10. 未消费余额统计
    const remainingBalanceList = membersWithStats.value
      .filter(m => m.totalBalance > 0)
      .map(m => ({
        id: m.id,
        memberNo: m.memberNo,
        customerName: m.name,
        phone: m.phone,
        level: m.levelName,
        principal: m.principalBalance,
        gift: m.giftBalance,
        totalBalance: m.totalBalance,
        lastRechargeDate: m.registerTime,
        rawType: m.level
      }))

    // 11. 单项销售统计
    const itemSalesMap: Record<number, { count: number; revenue: number; totalCost: number }> = {}
    consumeOrders.value.filter(c => c && c.status === 'COMPLETED').forEach(c => {
      (c.items || []).forEach(it => {
        if (!it) return
        if (!itemSalesMap[it.productId]) {
          itemSalesMap[it.productId] = { count: 0, revenue: 0, totalCost: 0 }
        }
        itemSalesMap[it.productId].count += (Number(it.quantity) || 0)
        itemSalesMap[it.productId].revenue += (Number(it.price) || 0) * (Number(it.quantity) || 0)
        itemSalesMap[it.productId].totalCost += (Number(it.bomCost) || 0) * (Number(it.quantity) || 0)
      })
    })

    // 新租户无订单时单项销售统计纯净化
    const hasAnySales = Object.keys(itemSalesMap).length > 0
    const itemSalesList = (isNewTenant.value && !hasAnySales) ? [] : products.value.map(p => {
      const stat = itemSalesMap[p.id] || { count: 0, revenue: 0, totalCost: 0 }
      const profit = stat.revenue - stat.totalCost
      const margin = stat.revenue > 0 ? ((profit / stat.revenue) * 100).toFixed(1) + '%' : '0.0%'
      return {
        id: p.id,
        itemName: p.name,
        category: p.categoryName,
        price: p.price,
        salesCount: stat.count,
        totalSales: Number(stat.revenue.toFixed(2)),
        marginRate: margin,
        rawType: p.category
      }
    })

    return {
      incomeList,
      cardDeductList,
      pointsList,
      rewardsList,
      newMembersList,
      paymentMethodsList,
      profitList,
      staffPerformanceList,
      remainingTimesList,
      remainingBalanceList,
      itemSalesList
    }
  })

  // --------------------------------------------------------------------------
  // D. 首页 Dashboard 指标动态计算
  // --------------------------------------------------------------------------
  const dashboardStats = computed(() => {
    const todayStr = '2026-09-06'
    const todayRecharges = rechargeOrders.value
      .filter(r => r.createTime.startsWith(todayStr))
      .reduce((sum, r) => sum + r.principalAmount, 0)

    const todayConsumes = consumeOrders.value
      .filter(c => (c.createTime.startsWith(todayStr) || c.createTime.startsWith(new Date().toISOString().substring(0, 10))) && (c.status === 'COMPLETED' || c.status === 'PAID'))
      .reduce((sum, c) => sum + (c.cashierPaidAmount || 0) + (c.cardDeductPrincipal || 0), 0)

    const todayRevenue = todayRecharges + todayConsumes

    const todayOrdersCount = rechargeOrders.value.filter(r => r.createTime.startsWith(todayStr)).length +
      consumeOrders.value.filter(c => (c.createTime.startsWith(todayStr) || c.createTime.startsWith(new Date().toISOString().substring(0, 10))) && (c.status === 'COMPLETED' || c.status === 'PAID')).length

    const todayStaffCommissions = staffWithStats.value.reduce((sum, s) => {
      const todayRecords = s.commissionRecords.filter((r: any) => r.date.startsWith(todayStr))
      return sum + todayRecords.reduce((s2: number, r: any) => s2 + r.commission, 0)
    }, 0)

    const totalMembers = members.value.length
    const totalSpaces = 8
    const servingSessions = liveSessions.value.filter(s => s.status === 'SERVING')
    const waitingCleanSessions = liveSessions.value.filter(s => s.status === 'WAIT_CLEAN')
    const occupiedSpaces = servingSessions.length + waitingCleanSessions.length
    const spaceUtilizationRate = (occupiedSpaces / totalSpaces) * 100

    return {
      todayRevenue: Number(todayRevenue.toFixed(2)),
      todayOrderCount: todayOrdersCount,
      totalSpaces,
      occupiedSpaces,
      servingCount: servingSessions.length,
      dirtyCount: waitingCleanSessions.length,
      spaceUtilizationRate: Number(spaceUtilizationRate.toFixed(1)),
      activeSessions: servingSessions.length,
      totalMembers,
      todayCommissions: Number(todayStaffCommissions.toFixed(2))
    }
  })

  // --------------------------------------------------------------------------
  // E. 连锁管理多店指标动态计算
  // --------------------------------------------------------------------------
  const chainStats = computed(() => {
    const totalStores = stores.value.length
    const roamCardBalance = membersWithStats.value.reduce((sum, m) => sum + m.totalBalance, 0)
    const crossStoreConsumes = consumeOrders.value.filter(c => {
      const m = members.value.find(mem => mem.id === c.memberId)
      return m && m.registeredStoreId !== c.storeId
    })
    const crossStoreSettlement = crossStoreConsumes.reduce((sum, c) => sum + c.totalAmount, 0)
    const totalStaff = staff.value.filter(s => s.status === 'ACTIVE').length

    return {
      totalStores,
      roamCardBalance: Number(roamCardBalance.toFixed(2)),
      crossStoreSettlement: Number(crossStoreSettlement.toFixed(2)),
      totalStaff
    }
  })

  // --------------------------------------------------------------------------
  // F. 营销获客指标动态计算
  // --------------------------------------------------------------------------
  const marketingStats = computed(() => {
    const runningCampaigns = campaigns.value.filter(c => c.status === 'RUNNING').length
    const totalCampaigns = campaigns.value.length
    const totalIssued = totalCampaigns > 0 ? (members.value.length * 2 + totalCampaigns * 15) : 0
    const usedCoupons = consumeOrders.value.filter(c => c.couponDiscount > 0).length
    const redemptionRate = totalIssued > 0 ? ((usedCoupons / totalIssued) * 100).toFixed(1) : '0.0'
    const referredMembers = members.value.filter(m => !!m.referrerId).length
    const drivenRevenue = consumeOrders.value
      .filter(c => c.couponDiscount > 0)
      .reduce((sum, c) => sum + c.cashierPaidAmount + c.cardDeductPrincipal, 0)

    return {
      runningCampaigns,
      totalCampaigns,
      totalIssued,
      usedCoupons,
      redemptionRate,
      referredMembers,
      drivenRevenue: Number(drivenRevenue.toFixed(2))
    }
  })

  // --------------------------------------------------------------------------
  // G. 支出与库存指标动态计算
  // --------------------------------------------------------------------------
  const expenseStats = computed(() => {
    const totalMonth = expenses.value.reduce((sum, e) => sum + e.amount, 0)
    const rent = expenses.value.filter(e => e.category === 'RENT').reduce((sum, e) => sum + e.amount, 0)
    const supply = expenses.value.filter(e => e.category === 'SUPPLY').reduce((sum, e) => sum + e.amount, 0)
    const salary = expenses.value.filter(e => e.category === 'SALARY').reduce((sum, e) => sum + e.amount, 0)
    const marketing = expenses.value.filter(e => e.category === 'MARKETING').reduce((sum, e) => sum + e.amount, 0)

    return {
      totalMonthExpense: Number(totalMonth.toFixed(2)),
      rent: Number(rent.toFixed(2)),
      supply: Number(supply.toFixed(2)),
      salary: Number(salary.toFixed(2)),
      marketing: Number(marketing.toFixed(2))
    }
  })

  const inventoryWithStats = computed(() => {
    return materials.value.map(mat => {
      let usedUnits = 0
      if (mat.id === 'MAT-01') {
        const dyeOrders = consumeOrders.value.filter(
          c => c.status === 'COMPLETED' && c.items.some(i => i.productId === 2)
        )
        usedUnits = dyeOrders.length
      } else if (mat.id === 'MAT-02') {
        const spaOrders = consumeOrders.value.filter(
          c => c.status === 'COMPLETED' && c.items.some(i => i.productId === 3)
        )
        usedUnits = spaOrders.length
      } else if (mat.id === 'MAT-03') {
        const retailOrders = consumeOrders.value.filter(
          c => c.status === 'COMPLETED' && c.items.some(i => i.productId === 4)
        )
        usedUnits = retailOrders.length
      }

      const currentStock = Math.max(0, mat.initialStock - usedUnits)
      const isLow = currentStock <= mat.safeStock
      return {
        ...mat,
        currentStock,
        usedUnits,
        isLow
      }
    })
  })

  // --------------------------------------------------------------------------
  // G1. 员工薪酬底薪与工单提成全自动核算（底薪 + 提成自动同步成本中心，零二次录入）
  // --------------------------------------------------------------------------
  const autoSalaryBaseCost = computed(() => {
    return staff.value
      .filter(s => s.status === 'ACTIVE')
      .reduce((sum, s) => sum + (Number(s.baseSalary) || 0), 0)
  })

  const autoSalaryCommissionCost = computed(() => {
    return staffWithStats.value.reduce((sum, s) => sum + (Number(s.totalCommission) || 0), 0)
  })

  // 融合员工薪资自动核算项与其余成本的完整全口径成本清单
  const allCostItems = computed<CostItemEntity[]>(() => {
    const currentMonth = '2026-09'
    const activeStaff = staff.value.filter(s => s.status === 'ACTIVE')
    const activeCount = activeStaff.length
    const currentStore = stores.value[0]?.storeId || 'S001'

    // 1. 系统自动核算固定成本：全员在册员工基础底薪包
    const autoBaseItem: CostItemEntity = {
      id: 999001,
      code: 'CST-AUTO-BASE',
      name: `全员在册基础底薪包 (系统核算在职 ${activeCount} 人)`,
      category: 'LABOR',
      categoryName: '人力薪酬成本',
      nature: 'FIXED',
      amount: Number(autoSalaryBaseCost.value.toFixed(2)),
      month: currentMonth,
      date: `${currentMonth}-05`,
      storeId: currentStore,
      handler: '人事档案自动核算',
      invoiceNo: 'AUTO-HR-PAYROLL',
      notes: '由员工管理系统录入的员工基础底薪自动汇总，增减员工或修改薪资时实时联动更新，无需二次录入',
      isAutoSync: true,
      autoSyncType: 'SALARY_BASE'
    }

    // 2. 系统自动核算变动成本：全员业务施工与销售提成总额
    const autoCommItem: CostItemEntity = {
      id: 999002,
      code: 'CST-AUTO-COMM',
      name: '员工工单服务与开卡销售提成总额 (实时业绩)',
      category: 'LABOR',
      categoryName: '人力薪酬成本',
      nature: 'VARIABLE',
      amount: Number(autoSalaryCommissionCost.value.toFixed(2)),
      month: currentMonth,
      date: `${currentMonth}-06`,
      storeId: currentStore,
      handler: '收银工单流水核算',
      invoiceNo: 'AUTO-PERF-COMM',
      notes: '由前台结账流水与各员工提成比例引擎实时自动核算累加，无需二次录入',
      isAutoSync: true,
      autoSyncType: 'SALARY_COMMISSION'
    }

    // 过滤掉原本可能硬编码的静态薪资项，保留手动录入的其他成本及临时劳务
    const nonLaborUserCosts = costItems.value.filter(c => !c.isAutoSync && c.category !== 'LABOR')
    const manualExtraLaborCosts = costItems.value.filter(c => !c.isAutoSync && c.category === 'LABOR')

    // 新租户下若未录入员工和手动开支，直接返回纯净空列表
    if (isNewTenant.value && activeCount === 0 && nonLaborUserCosts.length === 0 && manualExtraLaborCosts.length === 0) {
      return []
    }

    return [autoBaseItem, autoCommItem, ...manualExtraLaborCosts, ...nonLaborUserCosts]
  })

  // --------------------------------------------------------------------------
  // G2. 成本中心指标与结构动态计算 (Cost Center Analytics)
  // --------------------------------------------------------------------------
  const costStats = computed(() => {
    const currentMonth = '2026-09'
    const currentMonthCosts = allCostItems.value.filter(c => c.month === currentMonth || !c.month)
    const totalCost = currentMonthCosts.reduce((sum, c) => sum + c.amount, 0)

    // 固定成本 vs 变动成本
    const fixedCostTotal = currentMonthCosts.filter(c => c.nature === 'FIXED').reduce((sum, c) => sum + c.amount, 0)
    const variableCostTotal = currentMonthCosts.filter(c => c.nature === 'VARIABLE').reduce((sum, c) => sum + c.amount, 0)
    const fixedRate = totalCost > 0 ? ((fixedCostTotal / totalCost) * 100).toFixed(1) : '0.0'
    const variableRate = totalCost > 0 ? ((variableCostTotal / totalCost) * 100).toFixed(1) : '0.0'

    // 成本类别分类汇总与比重
    const categories: Record<string, { name: string; amount: number; color: string; count: number }> = {
      LABOR: { name: '人力薪酬成本', amount: 0, color: '#3B82F6', count: 0 },
      RENT_UTILITY: { name: '店面房租能耗', amount: 0, color: '#10B981', count: 0 },
      MATERIAL: { name: '物料耗材成本', amount: 0, color: '#F59E0B', count: 0 },
      MARKETING: { name: '营销获客成本', amount: 0, color: '#EC4899', count: 0 },
      DEPRECIATION: { name: '设备资产折旧', amount: 0, color: '#8B5CF6', count: 0 },
      ADMIN_MISC: { name: '日常运营杂费', amount: 0, color: '#6B7280', count: 0 }
    }

    currentMonthCosts.forEach(c => {
      if (categories[c.category]) {
        categories[c.category].amount += c.amount
        categories[c.category].count += 1
      }
    })

    const categoryBreakdown = Object.entries(categories).map(([key, val]) => {
      const percentage = totalCost > 0 ? Number(((val.amount / totalCost) * 100).toFixed(1)) : 0
      return {
        key,
        name: val.name,
        amount: Number(val.amount.toFixed(2)),
        color: val.color,
        count: val.count,
        percentage
      }
    }).sort((a, b) => b.amount - a.amount)

    // 单项成本排行榜（从高到低）
    const topCostsRanking = [...currentMonthCosts]
      .sort((a, b) => b.amount - a.amount)
      .map((c, index) => ({
        ...c,
        rank: index + 1,
        percentage: totalCost > 0 ? Number(((c.amount / totalCost) * 100).toFixed(1)) : 0
      }))

    // 关联总营收与营收成本率
    const monthRecharges = rechargeOrders.value
      .filter(r => r.createTime.startsWith(currentMonth))
      .reduce((sum, r) => sum + r.principalAmount, 0)
    const monthConsumes = consumeOrders.value
      .filter(c => c.createTime.startsWith(currentMonth) && (c.status === 'COMPLETED' || c.status === 'PAID'))
      .reduce((sum, c) => sum + (c.cashierPaidAmount || 0) + (c.cardDeductPrincipal || 0), 0)
    const monthRevenue = monthRecharges + monthConsumes || 128600
    const revenueCostRatio = monthRevenue > 0 ? Number(((totalCost / monthRevenue) * 100).toFixed(1)) : 0

    return {
      currentMonth,
      totalCost: Number(totalCost.toFixed(2)),
      fixedCostTotal: Number(fixedCostTotal.toFixed(2)),
      variableCostTotal: Number(variableCostTotal.toFixed(2)),
      fixedRate,
      variableRate,
      categoryBreakdown,
      topCostsRanking,
      monthRevenue: Number(monthRevenue.toFixed(2)),
      revenueCostRatio
    }
  })

  // --------------------------------------------------------------------------
  // H. 业务动作驱动
  // --------------------------------------------------------------------------
  const registerMember = (data: {
    name: string
    phone: string
    gender?: 'MALE' | 'FEMALE'
    birthday?: string
    habits?: string[]
    initialPrincipal?: number
    initialGift?: number
    referrerId?: number
    registeredStoreId?: string
    paymentMethod?: string
    tenantId?: string
    notes?: string
  }) => {
    const newId = members.value.length > 0 ? Math.max(...members.value.map(m => m.id)) + 1 : Math.floor(Date.now() / 1000)
    const todayStr = new Date().toISOString().slice(0, 10).replace(/-/g, '')
    const randSuffix = String(Math.floor(Math.random() * 9000) + 1000)
    const newMemberNo = `HM${todayStr}${randSuffix}`
    const nowStr = new Date().toISOString().replace('T', ' ').substring(0, 19)
    const targetStoreId = data.registeredStoreId || 'S001'
    const curTenantId = data.tenantId || localStorage.getItem('seahorse_tenant_id') || 'T001'

    // 将顾客选择的个人常态偏好封装为标准海马体偏好结构
    const formattedPrefs = (data.habits || []).map((h, idx) => ({
      id: Date.now() + idx,
      category: 'HABIT',
      tagKey: '常客自主偏好',
      tagValue: h,
      notes: '顾客扫码自助开卡登记'
    }))

    const p = data.initialPrincipal || 0
    const isPlat = p >= 1000
    const isGold = p >= 500
    const isSilver = p >= 200
    const levelCode = isPlat ? 'PLATINUM' : (isGold ? 'GOLD' : (isSilver ? 'SILVER' : 'REGULAR'))
    const levelName = isPlat ? '白金卡会员' : (isGold ? '金卡会员' : (isSilver ? '银卡会员' : '普卡会员'))

    const newMember: MemberEntity = {
      id: newId,
      memberNo: newMemberNo,
      name: data.name,
      phone: data.phone,
      gender: data.gender || 'FEMALE',
      birthday: data.birthday,
      habits: data.habits || [],
      preferences: formattedPrefs,
      level: levelCode,
      levelName: levelName,
      registeredStoreId: targetStoreId,
      referrerId: data.referrerId,
      registerTime: nowStr,
      tenantId: curTenantId,
      notes: data.notes || (data.habits && data.habits.length > 0 ? `偏好: ${data.habits.join('、')}` : '')
    }
    members.value.unshift(newMember)
    persistMembers()

    // 独立持久化该会员的海马体偏好档案，确保在详情页直接呼出
    try {
      localStorage.setItem(`seahorse_member_preferences_${newId}`, JSON.stringify(formattedPrefs))
      localStorage.setItem(`seahorse_member_preferences_${data.phone}`, JSON.stringify(formattedPrefs))
    } catch (e) {}

    if (data.initialPrincipal && data.initialPrincipal > 0) {
      rechargeOrders.value.unshift({
        id: rechargeOrders.value.length + 1,
        orderNo: `RC${Date.now()}`,
        memberId: newId,
        storeId: targetStoreId,
        sellerEmployeeId: 1,
        principalAmount: data.initialPrincipal,
        giftAmount: data.initialGift || 0,
        paymentMethod: (data.paymentMethod || 'WECHAT') as any,
        pointsGiven: data.initialPrincipal,
        createTime: nowStr,
        status: 'COMPLETED'
      })
      persistRechargeOrders()

      pointsLedger.value.unshift({
        id: pointsLedger.value.length + 1,
        memberId: newId,
        type: 'RECHARGE_GIFT',
        typeName: '新会员开卡即赠',
        pointsDelta: data.initialPrincipal,
        balanceAfter: data.initialPrincipal,
        operator: '系统自动',
        createTime: nowStr
      })
      persistPointsLedger()
    }

    return newMember
  }

  const rechargeMember = (data: { memberId: number; principal: number; gift: number; sellerId?: number }) => {
    const nowStr = new Date().toISOString().replace('T', ' ').substring(0, 19)
    const newOrder: RechargeOrder = {
      id: rechargeOrders.value.length + 1,
      orderNo: `RC${Date.now()}`,
      memberId: data.memberId,
      storeId: 'S001',
      sellerEmployeeId: data.sellerId || 2,
      principalAmount: data.principal,
      giftAmount: data.gift,
      paymentMethod: 'WECHAT',
      pointsGiven: data.principal,
      createTime: nowStr,
      status: 'COMPLETED'
    }
    rechargeOrders.value.push(newOrder)
    persistRechargeOrders()

    const currentPoints = pointsLedger.value
      .filter(p => p.memberId === data.memberId)
      .reduce((sum, p) => sum + p.pointsDelta, 0)
    pointsLedger.value.push({
      id: pointsLedger.value.length + 1,
      memberId: data.memberId,
      type: 'RECHARGE_GIFT',
      typeName: '会员充值赠积分',
      pointsDelta: data.principal,
      balanceAfter: currentPoints + data.principal,
      operator: '系统自动',
      createTime: nowStr
    })
    persistPointsLedger()
    return newOrder
  }

  const addExpense = (data: { category: any; categoryName: string; title: string; amount: number; handler: string; note: string }) => {
    const nowStr = new Date().toISOString().substring(0, 10)
    const newExp: ExpenseRecord = {
      id: expenses.value.length + 1,
      storeId: 'S001',
      category: data.category,
      categoryName: data.categoryName,
      title: data.title,
      amount: data.amount,
      date: nowStr,
      handler: data.handler || '经办人',
      note: data.note || ''
    }
    expenses.value.push(newExp)
    return newExp
  }

  const syncStores = (newStores: any[]) => {
    if (Array.isArray(newStores) && newStores.length > 0) {
      stores.value = newStores.map((s, idx) => ({
        storeId: s.storeId || `S00${idx + 1}`,
        storeName: s.storeName,
        address: s.address || '科技园区',
        managerName: s.manager || s.managerName || '负责人',
        phone: s.phone || '13800000000',
        isHeadquarter: s.isHeadquarter !== undefined ? s.isHeadquarter : (idx === 0 || s.storeName?.includes('总店')),
        businessStatus: (s.status === 'ACTIVE' || s.businessStatus === 'OPEN') ? 'OPEN' : 'CLOSED',
        totalSpaces: s.totalSpaces || 8,
        openTime: s.businessHours || '09:00 - 22:00'
      }))
      try {
        localStorage.setItem('seahorse_stores_data', JSON.stringify(stores.value))
      } catch (e) {}
    }
  }

  const syncStaff = (newStaff: any[]) => {
    if (Array.isArray(newStaff) && newStaff.length > 0) {
      staff.value = newStaff.map((s, idx) => ({
        id: s.id || idx + 1,
        storeId: s.storeId || 'S001',
        realName: s.realName,
        phone: s.phone || '13800000000',
        postName: s.postName || (s.role === 'SUPER_ADMIN' ? '租户老板' : (s.role === 'STORE_MANAGER' ? '店长' : (s.role === 'CASHIER' ? '前台收银' : '技师'))),
        role: s.role || 'TECHNICIAN',
        department: s.department || '综合运营部',
        baseSalary: s.baseSalary != null ? Number(s.baseSalary) : 0,
        serviceCommissionRate: s.defaultCommissionRate || s.serviceCommissionRate || 0.25,
        cardCommissionRate: s.cardCommissionRate || 0.08,
        retailCommissionRate: s.retailCommissionRate || 0.12,
        gender: s.gender || 'MALE',
        status: s.isDeleted ? 'DELETED' : (s.status || 'ACTIVE'),
        entryDate: s.createdAt ? String(s.createdAt).substring(0, 10) : '2026-01-01'
      }))
      try {
        localStorage.setItem('seahorse_staff_data', JSON.stringify(staff.value))
      } catch (e) {}
    }
  }

  const fetchStaff = async () => {
    try {
      const res: any = await getMerchantStaffListApi()
      if (Array.isArray(res) && res.length > 0) {
        const cleaned = res.filter((item: any) =>
          item.role !== 'PLATFORM_DEVELOPER' &&
          item.username !== 'admin' &&
          (!item.realName || !item.realName.includes('开发维护人'))
        )
        if (cleaned.length > 0) {
          syncStaff(cleaned)
        }
      }
    } catch (e) {
      console.error('fetchStaff error:', e)
    }
  }

  const persistStaff = () => {
    try {
      localStorage.setItem(`seahorse_staff_${currentIndustry.value}`, JSON.stringify(staff.value))
    } catch (e) {}
  }

  const persistProducts = () => {
    try {
      localStorage.setItem(`seahorse_products_${currentIndustry.value}`, JSON.stringify(products.value))
    } catch (e) {}
  }

  // --------------------------------------------------------------------------
  // H. 实时出入库与履约核销流水台账（打通商品上下架、采购入库与结账扣库）
  // --------------------------------------------------------------------------
  const getStoredStockLedgerRecords = (): StockLedgerRecord[] => {
    try {
      const raw = localStorage.getItem('seahorse_stock_ledger_records')
      if (raw) {
        const parsed = JSON.parse(raw)
        if (Array.isArray(parsed)) {
          // 清理历史脏数据（过滤张建华等老写死演示记录）
          return parsed.filter(r => r.operator !== '张建华 (店长)' && r.operator !== '托尼')
        }
      }
    } catch (e) {}
    return []
  }

  const stockLedgerRecords = ref<StockLedgerRecord[]>(getStoredStockLedgerRecords())

  const persistStockLedgerRecords = () => {
    try {
      localStorage.setItem('seahorse_stock_ledger_records', JSON.stringify(stockLedgerRecords.value.slice(0, 300)))
    } catch (e) {}
  }

  const resolveCurrentOperator = (customOperator?: string) => {
    if (customOperator && customOperator.trim()) return customOperator
    const realName = localStorage.getItem('seahorse_real_name')
    const username = localStorage.getItem('seahorse_username')
    const r = localStorage.getItem('seahorse_role')
    const roleName = r === 'SUPER_ADMIN' ? '店长/超管' : (r === 'CASHIER' ? '收银员' : (r === 'STORE_MANAGER' ? '店长' : '操作员'))
    if (realName) return `${realName} (${roleName})`
    if (username) return `${username} (${roleName})`
    return `门店${roleName}`
  }

  const recordStockLedger = (
    type: 'STOCK_IN' | 'RETAIL_OUT' | 'BOM_AUTO' | 'SHELF_ON' | 'SHELF_OFF' | 'STOCK_ADJUST',
    itemName: string,
    changeQty: number,
    operator?: string,
    remark?: string,
    itemCode?: string
  ) => {
    const now = new Date()
    const pad = (n: number) => n < 10 ? '0' + n : String(n)
    const timeStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`
    const prefixMap: Record<string, string> = {
      STOCK_IN: 'RK',
      RETAIL_OUT: 'CK',
      BOM_AUTO: 'HX',
      SHELF_ON: 'SJ',
      SHELF_OFF: 'XJ',
      STOCK_ADJUST: 'PD'
    }
    const prefix = prefixMap[type] || 'LS'
    const recordNo = `${prefix}${Date.now().toString().slice(-8)}`
    const newRecord: StockLedgerRecord = {
      recordNo,
      type,
      itemName,
      itemCode,
      changeQty,
      operator: resolveCurrentOperator(operator),
      time: timeStr,
      remark: remark || (type === 'SHELF_ON' ? '商品已上架在售' : (type === 'SHELF_OFF' ? '商品已下架停售' : ''))
    }
    stockLedgerRecords.value.unshift(newRecord)
    persistStockLedgerRecords()
    return newRecord
  }

  const addProduct = (prod: Partial<ProductEntity>, operator?: string) => {
    const newId = products.value.length > 0 ? Math.max(...products.value.map(p => p.id)) + 1 : 1
    const pPrice = Number(prod.price) || 0
    const newProduct: ProductEntity = {
      id: newId,
      code: prod.code || `PRD-${Date.now().toString().slice(-4)}`,
      name: prod.name || '新项目/商品',
      type: prod.type || 'RETAIL',
      category: prod.category || prod.categoryName || '精品分类',
      categoryName: prod.categoryName || prod.category || '精品分类',
      price: pPrice,
      memberPrice: prod.memberPrice !== undefined ? Number(prod.memberPrice) : Math.round(pPrice * 0.85),
      cost: prod.cost !== undefined ? Number(prod.cost) : Math.round(pPrice * 0.4),
      stock: prod.type === 'SERVICE' ? 0 : (prod.stock !== undefined ? Number(prod.stock) : 50),
      commissionRate: prod.commissionRate !== undefined ? Number(prod.commissionRate) : (prod.type === 'SERVICE' ? 0.25 : 0.1),
      unit: prod.unit || (prod.type === 'SERVICE' ? '次' : '件'),
      spec: prod.spec || '',
      durationMinutes: prod.durationMinutes || (prod.type === 'SERVICE' ? 30 : undefined),
      status: prod.status || 'ACTIVE',
      description: prod.description || '',
      hasBom: prod.hasBom || (prod.type === 'SERVICE') || false,
      boms: prod.boms || []
    }
    products.value.unshift(newProduct)
    persistProducts()
    // 联动生成商品上架与初始入库流水
    recordStockLedger(
      'SHELF_ON',
      newProduct.name,
      0,
      operator,
      `新${newProduct.type === 'SERVICE' ? '服务项目' : '实物商品'}上架建档入库，已同步至前台与台账`,
      newProduct.code
    )
    if (newProduct.type !== 'SERVICE' && (newProduct.stock || 0) > 0) {
      recordStockLedger(
        'STOCK_IN',
        newProduct.name,
        newProduct.stock || 0,
        operator,
        `建档期初入库（在库初始量：${newProduct.stock} ${newProduct.unit}）`,
        newProduct.code
      )
    }
    return newProduct
  }

  const updateProduct = (id: number, prod: Partial<ProductEntity>, operator?: string) => {
    const idx = products.value.findIndex(p => p.id === id)
    if (idx !== -1) {
      const oldStatus = products.value[idx].status
      const pPrice = prod.price !== undefined ? Number(prod.price) : products.value[idx].price
      products.value[idx] = {
        ...products.value[idx],
        ...prod,
        price: pPrice,
        memberPrice: prod.memberPrice !== undefined ? Number(prod.memberPrice) : products.value[idx].memberPrice,
        cost: prod.cost !== undefined ? Number(prod.cost) : products.value[idx].cost,
        stock: prod.stock !== undefined ? Number(prod.stock) : products.value[idx].stock,
        commissionRate: prod.commissionRate !== undefined ? Number(prod.commissionRate) : products.value[idx].commissionRate
      }
      persistProducts()
      // 若有上下架状态变动，联动生成流水
      if (prod.status && prod.status !== oldStatus) {
        recordStockLedger(
          prod.status === 'ACTIVE' ? 'SHELF_ON' : 'SHELF_OFF',
          products.value[idx].name,
          0,
          operator,
          prod.status === 'ACTIVE' ? '商品已上架在售，前台收银已同步放行' : '商品已下架停售，前台已禁售锁定',
          products.value[idx].code
        )
      }
      return products.value[idx]
    }
    return null
  }

  const deleteProduct = (id: number) => {
    const idx = products.value.findIndex(p => p.id === id)
    if (idx !== -1) {
      const name = products.value[idx].name
      const code = products.value[idx].code
      products.value.splice(idx, 1)
      persistProducts()
      recordStockLedger('SHELF_OFF', name, 0, undefined, '商品已从系统目录彻底删除注销', code)
      return true
    }
    return false
  }

  const toggleProductStatus = (id: number, operator?: string) => {
    const prod = products.value.find(p => p.id === id)
    if (prod) {
      const nextStatus = (prod.status || 'ACTIVE') === 'ACTIVE' ? 'DISABLED' : 'ACTIVE'
      prod.status = nextStatus
      persistProducts()
      recordStockLedger(
        nextStatus === 'ACTIVE' ? 'SHELF_ON' : 'SHELF_OFF',
        prod.name,
        0,
        operator,
        nextStatus === 'ACTIVE' ? '商品已上架在售，已打通同步至实时库存台账' : '商品已下架停售，前台已禁售锁定',
        prod.code
      )
      return prod.status
    }
    return null
  }

  // 结账消费后就地扣减商品实物库存并联动记录流水
  const deductProductStock = (items: Array<any>, operator?: string) => {
    if (!items || !items.length) return
    items.forEach(item => {
      const q = Number(item.qty || item.quantity || 1)
      const p = products.value.find(prod =>
        (item.id && prod.id === item.id) ||
        (item.productId && prod.id === item.productId) ||
        (item.code && prod.code === item.code) ||
        (item.productCode && prod.code === item.productCode) ||
        (item.name && prod.name === item.name)
      )
      if (p && p.type !== 'SERVICE' && p.stock !== undefined) {
        p.stock = Math.max(0, p.stock - q)
        recordStockLedger(
          'RETAIL_OUT',
          p.name,
          -q,
          operator,
          `前台收银点售出库 · 剩余库存 ${p.stock} ${p.unit || '件'}`,
          p.code
        )
      } else if (p && p.type === 'SERVICE' && p.boms && p.boms.length > 0) {
        // 服务项目履约：根据配方清单自动扣减对应物料耗材
        p.boms.forEach((bom: any) => {
          const consume = (Number(bom.dosage ?? bom.unitUsage ?? bom.consumeQuantity) || 1) * q
          const mat = materials.value.find(m => m.name === bom.materialName)
          if (mat) {
            mat.initialStock = Math.max(0, (mat.initialStock || 0) - consume)
          }
          recordStockLedger(
            'BOM_AUTO',
            bom.materialName,
            -consume,
            operator,
            `服务【${p.name}】履约核销耗材配方自动扣减`,
            p.code
          )
        })
      }
    })
    persistProducts()
  }

  // 从服务端拉取最新商品与库存，全量合并更新至全局 Store
  const syncProductsFromServer = async () => {
    try {
      const res: any = await getProductsApi()
      const list: any[] = Array.isArray(res) ? res : (res?.data || [])
      if (list.length > 0) {
        list.forEach((p: any) => {
          const mapped: any = {
            id: p.id,
            code: p.productCode || ('PRD' + p.id),
            name: p.name,
            type: p.productType === 'SERVICE' ? 'SERVICE' : (p.productType === 'PACKAGE' ? 'PACKAGE' : 'RETAIL'),
            category: p.categoryName || '',
            categoryName: p.categoryName || '',
            price: Number(p.price) || 0,
            memberPrice: p.memberPrice != null ? Number(p.memberPrice) : Math.round(Number(p.price || 0) * 0.85),
            stock: p.stock ?? 50,
            unit: p.unit || '件',
            durationMinutes: p.durationMinutes || 0,
            description: p.description || '',
            status: p.available === false ? 'DISABLED' : 'ACTIVE',
            hasBom: p.productType === 'SERVICE',
            commissionRate: p.defaultCommission != null ? Number(p.defaultCommission) : 0.15,
            spec: p.spec || ''
          }
          const existing = products.value.find((x: any) => x.id === mapped.id || (x.code && x.code === mapped.code))
          if (!existing) {
            products.value.unshift(mapped)
          } else {
            Object.assign(existing, mapped)
          }
        })
        persistProducts()
      }
    } catch (e) {
      console.warn('同步服务端商品库存失败:', e)
    }
  }

  const addStaff = (data: Partial<StaffEntity>) => {
    const newId = staff.value.length > 0 ? Math.max(...staff.value.map(s => s.id)) + 1 : 1
    const isSelf = !!data.isSelfApplied
    const newStaffMember: StaffEntity = {
      id: newId,
      storeId: data.storeId || 'S001',
      realName: data.realName || '新员工',
      phone: data.phone || '13800000000',
      postName: data.postName || '专业技师',
      role: data.role || 'TECHNICIAN',
      department: data.department || '综合部',
      baseSalary: Number(data.baseSalary) || 0,
      serviceCommissionRate: data.serviceCommissionRate ?? 0,
      cardCommissionRate: data.cardCommissionRate ?? 0.08,
      retailCommissionRate: data.retailCommissionRate ?? 0.12,
      gender: data.gender || 'MALE',
      status: 'ACTIVE',
      entryDate: data.entryDate || new Date().toISOString().substring(0, 10),
      hasSystemAccount: isSelf ? false : (data.hasSystemAccount || false),
      accountUsername: data.accountUsername || data.phone || '',
      accountPassword: data.accountPassword || '123456',
      accountStatus: isSelf ? 'PENDING_REVIEW' : (data.accountStatus || 'ENABLED'),
      isSelfApplied: isSelf,
      auditStatus: isSelf ? 'PENDING' : 'APPROVED',
      applyTime: data.applyTime || new Date().toISOString().replace('T', ' ').substring(0, 19),
      experience: data.experience || '',
      allowedStoreIds: data.allowedStoreIds || [data.storeId || 'S001'],
      allowedMenuPaths: data.allowedMenuPaths || ['/dashboard', '/rooms', '/members', '/products', '/appointments', '/inventory', '/regulations', '/profile']
    }
    staff.value.unshift(newStaffMember)
    persistStaff()
    return newStaffMember
  }

  const approveStaff = (staffId: number, options?: {
    postName?: string
    role?: any
    storeId?: string
    baseSalary?: number
    allowedStoreIds?: string[]
    allowedMenuPaths?: string[]
    auditor?: string
  }) => {
    const target = staff.value.find(s => s.id === staffId)
    if (target) {
      target.auditStatus = 'APPROVED'
      target.accountStatus = 'ENABLED'
      target.hasSystemAccount = true
      target.auditTime = new Date().toISOString().replace('T', ' ').substring(0, 19)
      target.auditor = options?.auditor || '店长/租户老板'
      if (options?.postName) target.postName = options.postName
      if (options?.role) target.role = options.role
      if (options?.storeId) target.storeId = options.storeId
      if (options?.baseSalary !== undefined) target.baseSalary = options.baseSalary
      if (options?.allowedStoreIds) target.allowedStoreIds = options.allowedStoreIds
      if (options?.allowedMenuPaths) target.allowedMenuPaths = options.allowedMenuPaths
      persistStaff()
      return target
    }
    return null
  }

  const rejectStaff = (staffId: number, reason: string, auditor?: string) => {
    const target = staff.value.find(s => s.id === staffId)
    if (target) {
      target.auditStatus = 'REJECTED'
      target.accountStatus = 'REJECTED'
      target.hasSystemAccount = false
      target.rejectReason = reason || '未通过门店资质或岗位要求审核'
      target.auditTime = new Date().toISOString().replace('T', ' ').substring(0, 19)
      target.auditor = auditor || '店长/租户老板'
      persistStaff()
      return target
    }
    return null
  }

  const updateStaff = (id: number, data: Partial<StaffEntity>) => {
    const idx = staff.value.findIndex(s => s.id === id)
    if (idx !== -1) {
      staff.value[idx] = {
        ...staff.value[idx],
        ...data,
        baseSalary: data.baseSalary !== undefined ? Number(data.baseSalary) : staff.value[idx].baseSalary
      }
      persistStaff()
      return staff.value[idx]
    }
    return null
  }

  const setupStaffAccount = (
    staffId: number,
    accountData: {
      hasSystemAccount: boolean
      accountUsername: string
      accountPassword?: string
      accountStatus: 'ENABLED' | 'DISABLED'
      allowedStoreIds: string[]
      allowedMenuPaths: string[]
      canCrossStore?: boolean
    }
  ) => {
    const idx = staff.value.findIndex(s => s.id === staffId)
    if (idx !== -1) {
      staff.value[idx] = {
        ...staff.value[idx],
        ...accountData,
        accountPassword: accountData.accountPassword || staff.value[idx].accountPassword || '123456'
      }
      persistStaff()
      return staff.value[idx]
    }
    return null
  }

  const deleteStaff = (id: number) => {
    const s = staff.value.find(item => item.id === id)
    if (s) {
      s.status = 'DELETED'
      persistStaff()
      return true
    }
    return false
  }

  // --------------------------------------------------------------------------
  // H.2. 线上微商城运营动作 (Micro-Mall Goods Operations)
  // --------------------------------------------------------------------------
  const addMallGoods = (goods: Partial<MallGoodsEntity>) => {
    const newId = mallGoods.value.length > 0 ? Math.max(...mallGoods.value.map(g => g.id)) + 1 : 101
    const newGoods: MallGoodsEntity = {
      id: newId,
      productId: goods.productId,
      productCode: goods.productCode || `MALL-${Date.now().toString().slice(-4)}`,
      title: goods.title || '新微商城商品',
      category: goods.category || '专营品类',
      onlinePrice: Number(goods.onlinePrice) || 99,
      originalPrice: Number(goods.originalPrice) || Number(goods.onlinePrice) || 99,
      stock: goods.stock !== undefined ? Number(goods.stock) : 50,
      sales: goods.sales || 0,
      onShelf: goods.onShelf ?? true,
      isHot: goods.isHot ?? false,
      deliveryType: goods.deliveryType || 'BOTH',
      description: goods.description || '',
      syncTime: new Date().toISOString().replace('T', ' ').substring(0, 19),
      syncSource: goods.syncSource || (goods.productId ? 'STORE_PRODUCT' : 'MALL_EXCLUSIVE')
    }
    mallGoods.value.unshift(newGoods)
    persistMallGoods()
    return newGoods
  }

  const updateMallGoods = (id: number, updated: Partial<MallGoodsEntity>) => {
    const idx = mallGoods.value.findIndex(g => g.id === id)
    if (idx !== -1) {
      mallGoods.value[idx] = {
        ...mallGoods.value[idx],
        ...updated,
        onlinePrice: updated.onlinePrice !== undefined ? Number(updated.onlinePrice) : mallGoods.value[idx].onlinePrice,
        stock: updated.stock !== undefined ? Number(updated.stock) : mallGoods.value[idx].stock
      }
      persistMallGoods()
      return mallGoods.value[idx]
    }
    return null
  }

  const deleteMallGoods = (id: number) => {
    const idx = mallGoods.value.findIndex(g => g.id === id)
    if (idx !== -1) {
      const item = mallGoods.value[idx]
      mallGoods.value.splice(idx, 1)
      persistMallGoods()
      if (item.productId) {
        const prod = products.value.find(p => p.id === item.productId)
        if (prod) {
          prod.isSyncMall = false
          persistProducts()
        }
      }
      return true
    }
    return false
  }

  const toggleMallGoodsShelf = (id: number) => {
    const item = mallGoods.value.find(g => g.id === id)
    if (item) {
      item.onShelf = !item.onShelf
      persistMallGoods()
      return item.onShelf
    }
    return null
  }

  const syncProductToMall = (productId: number, customOpts?: Partial<MallGoodsEntity>) => {
    const prod = products.value.find(p => p.id === productId)
    if (!prod) return null
    prod.isSyncMall = true
    persistProducts()

    const existing = mallGoods.value.find(g => g.productId === productId || g.title === prod.name)
    if (existing) {
      existing.onlinePrice = customOpts?.onlinePrice ?? (prod.memberPrice || prod.price)
      existing.originalPrice = prod.price
      existing.stock = customOpts?.stock ?? (prod.stock || 50)
      existing.onShelf = true
      if (customOpts?.deliveryType) existing.deliveryType = customOpts.deliveryType
      if (customOpts?.isHot !== undefined) existing.isHot = customOpts.isHot
      existing.syncTime = new Date().toISOString().replace('T', ' ').substring(0, 19)
      persistMallGoods()
      return existing
    }

    const newId = mallGoods.value.length > 0 ? Math.max(...mallGoods.value.map(g => g.id)) + 1 : 101
    const newGoods: MallGoodsEntity = {
      id: newId,
      productId: prod.id,
      productCode: prod.code,
      title: prod.name,
      category: prod.categoryName || prod.category || '精品商品',
      onlinePrice: customOpts?.onlinePrice ?? (prod.memberPrice || prod.price),
      originalPrice: prod.price,
      stock: customOpts?.stock ?? (prod.stock || 50),
      sales: 0,
      onShelf: true,
      isHot: customOpts?.isHot ?? false,
      deliveryType: customOpts?.deliveryType || (prod.type === 'SERVICE' ? 'STORE_PICKUP' : 'BOTH'),
      description: prod.description || `${prod.name}，门店官方直营品质保证。`,
      syncTime: new Date().toISOString().replace('T', ' ').substring(0, 19),
      syncSource: 'STORE_PRODUCT'
    }
    mallGoods.value.unshift(newGoods)
    persistMallGoods()
    return newGoods
  }

  const syncAllProductsToMall = () => {
    const activeProducts = products.value.filter(p => (p.status || 'ACTIVE') === 'ACTIVE')
    let syncedCount = 0
    activeProducts.forEach(prod => {
      const alreadyOnShelf = mallGoods.value.some(g => g.productId === prod.id || g.title === prod.name)
      if (!alreadyOnShelf) {
        syncProductToMall(prod.id)
        syncedCount++
      }
    })
    return syncedCount
  }

  const checkoutSession = (sessionId: number, payload: {
    orderNo: string
    customerName?: string
    totalAmount: number
    wechat: number
    alipay: number
    storedValue: number
    cash: number
    memberId?: number
  }) => {
    // 1. 将在场会话状态推进为待清台【WAIT_CLEAN】
    const session = liveSessions.value.find(s => s.id === sessionId || s.sessionNo.includes(String(sessionId)))
    if (session) {
      session.status = 'WAIT_CLEAN'
    }

    // 2. 记入真实消费账本与资金流水
    const memberId = payload.memberId || session?.memberId || null
    const m = memberId ? (members.value.find(item => item.id === memberId) || null) : null
    const todayStr = new Date().toISOString().substring(0, 10)
    const nowTime = new Date().toTimeString().substring(0, 8)
    const nowStr = `${todayStr} ${nowTime}`

    const newConsume: ConsumeOrder = {
      id: Date.now(),
      orderNo: payload.orderNo,
      memberId: m ? m.id : (memberId || 0),
      storeId: m ? (m.registeredStoreId || 'S001') : 'S001',
      primaryTechnicianId: 2,
      cashierEmployeeId: 5,
      items: [
        { productId: 101, productName: '美业养护造型服务', type: 'SERVICE', price: payload.totalAmount, quantity: 1, bomCost: 28 }
      ],
      totalAmount: payload.totalAmount,
      couponDiscount: 0,
      cardDeductPrincipal: Math.min(payload.storedValue, 500),
      cardDeductGift: Math.max(0, payload.storedValue - 500),
      cashierPaidAmount: payload.wechat + payload.alipay + payload.cash,
      paymentMethod: payload.wechat > 0 ? 'WECHAT' : (payload.alipay > 0 ? 'ALIPAY' : (payload.storedValue > 0 ? 'DUAL_CARD' : 'CASH')),
      pointsEarned: m ? Math.floor(payload.totalAmount) : 0,
      pointsBurned: 0,
      createTime: nowStr,
      status: 'COMPLETED'
    }
    consumeOrders.value.unshift(newConsume)

    // 3. 会员积分与储值划扣
    if (m) {
      const prevPoints = m.points !== undefined
        ? m.points
        : pointsLedger.value.filter(p => p.memberId === m.id).reduce((sum, p) => sum + p.pointsDelta, 0)
      const earned = Math.floor(payload.totalAmount)
      pointsLedger.value.push({
        id: pointsLedger.value.length + 1,
        memberId: m.id,
        type: 'CONSUME_EARN',
        typeName: '收银买单赠送积分',
        pointsDelta: earned,
        balanceAfter: prevPoints + earned,
        operator: '收银台自动',
        createTime: nowStr
      })
      persistPointsLedger()
      if (m.points !== undefined) {
        m.points += earned
      }
      if (payload.storedValue > 0) {
        const pDeduct = Math.min(m.principalBalance || 0, payload.storedValue)
        const gDeduct = Math.max(0, payload.storedValue - pDeduct)
        m.principalBalance = Math.max(0, (m.principalBalance || 0) - pDeduct)
        m.giftBalance = Math.max(0, (m.giftBalance || 0) - gDeduct)
      }
      persistMembers()
    }

    return newConsume
  }

  const recordCashierSettlement = (payload: any) => {
    return checkoutSession(payload.sessionId || 1, payload)
  }

  const resetSpace = (sessionIdOrSpaceId: number) => {
    const session = liveSessions.value.find(s => s.id === sessionIdOrSpaceId || s.spaceId === sessionIdOrSpaceId)
    if (session) {
      session.status = 'COMPLETED'
    }
    const space = spaces.value.find(s => s.id === sessionIdOrSpaceId || s.currentSessionId === sessionIdOrSpaceId)
    if (space) {
      space.status = 'IDLE'
      space.currentSessionId = null
    }
  }

  // --------------------------------------------------------------------------
  // K. 空间/包厢/台位实体运维动作 (Space & Room Management Actions)
  // --------------------------------------------------------------------------
  const addSpace = (item: Omit<SpaceEntity, 'id'> & { id?: number }) => {
    const newId = item.id || (spaces.value.length > 0 ? Math.max(...spaces.value.map(s => s.id)) + 1 : 1)
    const newSpace: SpaceEntity = {
      status: 'IDLE',
      capacity: 4,
      floorZone: '一楼大厅',
      minConsumeAmount: 0,
      hourlyFee: 0,
      facilities: [],
      notes: '',
      sortOrder: spaces.value.length + 1,
      ...item,
      id: newId,
      qrCodeUrl: item.qrCodeUrl || `https://fwpt.cn/seahorse/table-order?storeId=${item.storeId || 'S001'}&spaceCode=${item.spaceCode}`
    }
    spaces.value.push(newSpace)
    return newSpace
  }

  const updateSpace = (id: number, updated: Partial<SpaceEntity>) => {
    const idx = spaces.value.findIndex(s => s.id === id)
    if (idx !== -1) {
      spaces.value[idx] = { ...spaces.value[idx], ...updated }
      return spaces.value[idx]
    }
    return null
  }

  const deleteSpace = (id: number) => {
    const idx = spaces.value.findIndex(s => s.id === id)
    if (idx !== -1) {
      spaces.value.splice(idx, 1)
      return true
    }
    return false
  }

  const batchAddSpaces = (items: Array<Omit<SpaceEntity, 'id'>>) => {
    let currentMaxId = spaces.value.length > 0 ? Math.max(...spaces.value.map(s => s.id)) : 0
    const created: SpaceEntity[] = []
    items.forEach(item => {
      currentMaxId++
      const newSpace: SpaceEntity = {
        status: 'IDLE',
        capacity: 4,
        floorZone: '包厢区',
        minConsumeAmount: 0,
        hourlyFee: 0,
        facilities: [],
        notes: '',
        sortOrder: currentMaxId,
        ...item,
        id: currentMaxId,
        qrCodeUrl: `https://fwpt.cn/seahorse/table-order?storeId=${item.storeId || 'S001'}&spaceCode=${item.spaceCode}`
      }
      spaces.value.push(newSpace)
      created.push(newSpace)
    })
    return created
  }

  const updateSpaceStatus = (id: number, status: 'IDLE' | 'OCCUPIED' | 'DIRTY' | 'MAINTENANCE') => {
    const space = spaces.value.find(s => s.id === id)
    if (space) {
      space.status = status
      if (status === 'IDLE' || status === 'MAINTENANCE') {
        space.currentSessionId = null
      }
      return space
    }
    return null
  }

  const addCostItem = (item: Omit<CostItemEntity, 'id' | 'code'> & { code?: string }) => {
    const newId = costItems.value.length > 0 ? Math.max(...costItems.value.map(c => c.id)) + 1 : 1
    const code = item.code || `CST${(item.month || '2026-09').replace('-', '')}${String(newId).padStart(3, '0')}`
    const newItem: CostItemEntity = {
      ...item,
      id: newId,
      code
    }
    costItems.value.unshift(newItem)
    return newItem
  }

  const updateCostItem = (id: number, updated: Partial<CostItemEntity>) => {
    const idx = costItems.value.findIndex(c => c.id === id)
    if (idx !== -1) {
      costItems.value[idx] = {
        ...costItems.value[idx],
        ...updated
      }
      return costItems.value[idx]
    }
    return null
  }

  const deleteCostItem = (id: number) => {
    const idx = costItems.value.findIndex(c => c.id === id)
    if (idx !== -1) {
      costItems.value.splice(idx, 1)
      return true
    }
    return false
  }

  // --------------------------------------------------------------------------
  // I. 会员卡模板动作 (Card Template Actions — 本地缓存 + 后端 /api/card-template 双写同步)
  // --------------------------------------------------------------------------
  const addCardTemplate = (data: Omit<CardTemplateEntity, 'id'>) => {
    const newId = cardTemplates.value.length > 0 ? Math.max(...cardTemplates.value.map(c => c.id)) + 1 : 1
    const newCard: CardTemplateEntity = {
      ...data,
      id: newId
    }
    cardTemplates.value.unshift(newCard)
    persistCardTemplates()
    saveCardTemplateApi({ ...data }, true)
      .then((saved: any) => {
        if (saved && typeof saved.id === 'number') {
          const target = cardTemplates.value.find(c => c.id === newId)
          if (target) {
            target.id = saved.id
            persistCardTemplates()
          }
        }
      })
      .catch(() => {})
    return newCard
  }

  const updateCardTemplate = (id: number, data: Partial<CardTemplateEntity>) => {
    const idx = cardTemplates.value.findIndex(c => c.id === id)
    if (idx !== -1) {
      cardTemplates.value[idx] = { ...cardTemplates.value[idx], ...data }
      persistCardTemplates()
      const updated = cardTemplates.value[idx]
      saveCardTemplateApi({ ...updated }, true).catch(() => {})
      return updated
    }
    return null
  }

  const deleteCardTemplate = (id: number) => {
    const idx = cardTemplates.value.findIndex(c => c.id === id)
    if (idx !== -1) {
      cardTemplates.value.splice(idx, 1)
      persistCardTemplates()
      deleteCardTemplateApi(id, true).catch(() => {})
      return true
    }
    return false
  }

  // --------------------------------------------------------------------------
  // J. 7 大行业一键切换与真实数据集装载 (Multi-Industry Dataset Switcher)
  // --------------------------------------------------------------------------
  const switchIndustry = (key: IndustryCode) => {
    const pkg = allIndustryPackages[key] || beautyPackage
    currentIndustry.value = key
    localStorage.setItem('seahorse_industry', key)

    // 新注册租户仅切换行业类别，坚决不注入任何演示假数据
    if (isNewTenant.value) {
      return pkg
    }

    stores.value = JSON.parse(JSON.stringify(pkg.stores))
    staff.value = JSON.parse(JSON.stringify(pkg.staff))
    const cachedIndProducts = localStorage.getItem(`seahorse_products_${key}`)
    products.value = cachedIndProducts ? JSON.parse(cachedIndProducts) : JSON.parse(JSON.stringify(pkg.products))
    materials.value = JSON.parse(JSON.stringify(pkg.materials))
    members.value = JSON.parse(JSON.stringify(pkg.members))
    cardTemplates.value = JSON.parse(JSON.stringify(pkg.cardTemplates))
    liveSessions.value = JSON.parse(JSON.stringify(pkg.liveSessions))
    costItems.value = JSON.parse(JSON.stringify(pkg.baseCosts))
    rechargeOrders.value = JSON.parse(JSON.stringify(pkg.rechargeOrders))
    consumeOrders.value = JSON.parse(JSON.stringify(pkg.consumeOrders))
    timeCards.value = JSON.parse(JSON.stringify(pkg.timeCards))
    pointsLedger.value = JSON.parse(JSON.stringify(pkg.pointsLedger))
    rewardsLedger.value = JSON.parse(JSON.stringify(pkg.rewardsLedger))
    expenses.value = JSON.parse(JSON.stringify(pkg.expenses))
    appointments.value = JSON.parse(JSON.stringify(pkg.appointments))
    spaces.value = JSON.parse(JSON.stringify(industrySpacesMap[key] || []))
    const cachedIndMallGoods = localStorage.getItem(`seahorse_mall_goods_${key}`)
    mallGoods.value = isNewTenant.value ? [] : (cachedIndMallGoods ? JSON.parse(cachedIndMallGoods) : JSON.parse(JSON.stringify(initialMallGoodsMap[key] || initialMallGoodsMap.BEAUTY)))
    const cachedIndMallOrders = localStorage.getItem(`seahorse_mall_orders_${key}`)
    mallOrders.value = isNewTenant.value ? [] : (cachedIndMallOrders ? JSON.parse(cachedIndMallOrders) : JSON.parse(JSON.stringify(initialMallOrdersMap[key] || initialMallOrdersMap.BEAUTY)))
    return pkg
  }

  // --------------------------------------------------------------------------
  // K. 纯净新租户工作台重置与示范数据自由加载
  // --------------------------------------------------------------------------
  const initNewTenantWorkspace = (tenantName?: string, storeName?: string, bossName?: string, phone?: string) => {
    isNewTenant.value = true
    localStorage.setItem('seahorse_is_new_tenant', 'true')
    if (tenantName) localStorage.setItem('seahorse_new_tenant_name', tenantName)
    if (storeName) localStorage.setItem('seahorse_new_store_name', storeName)
    if (bossName) localStorage.setItem('seahorse_new_boss_name', bossName)
    if (phone) localStorage.setItem('seahorse_new_boss_phone', phone)

    stores.value = []
    staff.value = []
    spaces.value = []
    products.value = []
    materials.value = []
    members.value = []
    cardTemplates.value = []
    mallGoods.value = []
    mallOrders.value = []
    liveSessions.value = []
    costItems.value = []
    rechargeOrders.value = []
    consumeOrders.value = []
    timeCards.value = []
    pointsLedger.value = []
    rewardsLedger.value = []
    expenses.value = []
    appointments.value = []
    attendanceRecords.value = []
    leaveApplications.value = []
    campaigns.value = []
    localStorage.removeItem('seahorse_campaigns')
    localStorage.removeItem('seahorse_card_templates_data')
    localStorage.removeItem(`seahorse_mall_orders_${currentIndustry.value}`)
    localStorage.removeItem('seahorse_job_applications')
    localStorage.removeItem('seahorse_store_budgets')
    localStorage.removeItem('seahorse_system_positions')
    localStorage.removeItem('seahorse_store_departments')
    localStorage.removeItem('seahorse_staff_data')
    localStorage.removeItem(`seahorse_staff_${currentIndustry.value}`)
    localStorage.removeItem('seahorse_stores_data')
    localStorage.removeItem('seahorse_products_data')
    localStorage.removeItem('seahorse_rooms_data')
    localStorage.removeItem('seahorse_appointments_data')
  }

  const initScenarioDemoData = async (industry: string) => {
    const res: any = await initTenantDemoDataApi({ industry })
    isNewTenant.value = false
    localStorage.removeItem('seahorse_is_new_tenant')

    // 重新从后端拉取本租户专属业务数据，严格物理隔离
    try {
      const storeList: any = await getTenantStoresApi()
      if (Array.isArray(storeList)) {
        stores.value = storeList
      }
    } catch (e) {}

    try {
      const staffList: any = await getMerchantStaffListApi()
      if (Array.isArray(staffList)) {
        staff.value = staffList
      }
    } catch (e) {}

    try {
      const spaceList: any = await getSpacesApi()
      if (Array.isArray(spaceList)) {
        spaces.value = spaceList
      }
    } catch (e) {}

    try {
      const prodList: any = await getProductsApi()
      if (Array.isArray(prodList)) {
        products.value = prodList
      }
    } catch (e) {}

    try {
      const memberList: any = await searchMembersApi()
      if (Array.isArray(memberList)) {
        members.value = memberList
      }
    } catch (e) {}

    try {
      const cardList: any = await getCardTemplatesApi()
      if (Array.isArray(cardList)) {
        cardTemplates.value = cardList
      }
    } catch (e) {}

    // 加载行业裂变获客活动方案
    loadIndustryCampaigns(industry)
    mallOrders.value = JSON.parse(JSON.stringify(initialMallOrdersMap[(industry as any)] || initialMallOrdersMap.BEAUTY))
    persistMallOrders()

    return res
  }

  const clearAllTenantData = async () => {
    const res: any = await clearTenantDataApi()
    isNewTenant.value = true
    localStorage.setItem('seahorse_is_new_tenant', 'true')

    stores.value = []
    staff.value = []
    spaces.value = []
    products.value = []
    materials.value = []
    members.value = []
    cardTemplates.value = []
    mallGoods.value = []
    mallOrders.value = []
    liveSessions.value = []
    costItems.value = []
    rechargeOrders.value = []
    consumeOrders.value = []
    timeCards.value = []
    pointsLedger.value = []
    rewardsLedger.value = []
    expenses.value = []
    appointments.value = []
    attendanceRecords.value = []
    leaveApplications.value = []
    campaigns.value = []
    localStorage.removeItem('seahorse_campaigns')
    localStorage.removeItem('seahorse_card_templates_data')
    localStorage.removeItem(`seahorse_mall_orders_${currentIndustry.value}`)

    return res
  }

  const loadDemoPackage = () => {
    isNewTenant.value = false
    localStorage.removeItem('seahorse_is_new_tenant')
    const pkg = allIndustryPackages[currentIndustry.value] || beautyPackage
    stores.value = JSON.parse(JSON.stringify(pkg.stores))
    staff.value = JSON.parse(JSON.stringify(pkg.staff))
    spaces.value = JSON.parse(JSON.stringify(industrySpacesMap[currentIndustry.value] || []))
    products.value = JSON.parse(JSON.stringify(pkg.products))
    materials.value = JSON.parse(JSON.stringify(pkg.materials))
    members.value = JSON.parse(JSON.stringify(pkg.members))
    cardTemplates.value = JSON.parse(JSON.stringify(pkg.cardTemplates))
    mallGoods.value = JSON.parse(JSON.stringify(initialMallGoodsMap[currentIndustry.value] || initialMallGoodsMap.BEAUTY))
    liveSessions.value = JSON.parse(JSON.stringify(pkg.liveSessions))
    costItems.value = JSON.parse(JSON.stringify(pkg.baseCosts))
    rechargeOrders.value = JSON.parse(JSON.stringify(pkg.rechargeOrders))
    consumeOrders.value = JSON.parse(JSON.stringify(pkg.consumeOrders))
    timeCards.value = JSON.parse(JSON.stringify(pkg.timeCards))
    pointsLedger.value = JSON.parse(JSON.stringify(pkg.pointsLedger))
    rewardsLedger.value = JSON.parse(JSON.stringify(pkg.rewardsLedger))
    expenses.value = JSON.parse(JSON.stringify(pkg.expenses))
    appointments.value = JSON.parse(JSON.stringify(pkg.appointments))
    loadIndustryCampaigns(currentIndustry.value)
    mallOrders.value = JSON.parse(JSON.stringify(initialMallOrdersMap[currentIndustry.value] || initialMallOrdersMap.BEAUTY))
    persistProducts()
    persistMembers()
    persistCardTemplates()
    persistMallGoods()
    persistMallOrders()
  }

  const clearBusinessData = () => {
    isNewTenant.value = true
    localStorage.setItem('seahorse_is_new_tenant', 'true')
    stores.value = []
    staff.value = []
    spaces.value = []
    products.value = []
    materials.value = []
    members.value = []
    cardTemplates.value = []
    mallGoods.value = []
    mallOrders.value = []
    liveSessions.value = []
    costItems.value = []
    rechargeOrders.value = []
    consumeOrders.value = []
    timeCards.value = []
    pointsLedger.value = []
    rewardsLedger.value = []
    expenses.value = []
    appointments.value = []
    campaigns.value = []
    localStorage.removeItem('seahorse_campaigns')
    localStorage.removeItem('seahorse_card_templates_data')
    localStorage.removeItem(`seahorse_mall_orders_${currentIndustry.value}`)
  }

  return {
    stores,
    staff,
    spaces,
    products,
    materials,
    members,
    mallGoods,
    liveSessions,
    costItems,
    cardTemplates,
    rechargeOrders,
    consumeOrders,
    timeCards,
    pointsLedger,
    rewardsLedger,
    expenses,
    appointments,
    currentIndustry,
    // 营销获客活动
    campaigns,
    addCampaign,
    updateCampaign,
    deleteCampaign,
    toggleCampaignStatus,
    loadIndustryCampaigns,
    // 计算属性
    membersWithStats,
    staffWithStats,
    reportsData,
    dashboardStats,
    chainStats,
    marketingStats,
    expenseStats,
    costStats,
    allCostItems,
    autoSalaryBaseCost,
    autoSalaryCommissionCost,
    inventoryWithStats,
    // 实时库存流水与台账
    stockLedgerRecords,
    recordStockLedger,
    // 业务动作
    addProduct,
    updateProduct,
    deleteProduct,
    toggleProductStatus,
    deductProductStock,
    syncProductsFromServer,
    persistProducts,
    registerMember,
    addMember: registerMember,
    persistMembers,
    rechargeMember,
    persistRechargeOrders,
    persistPointsLedger,
    persistCardTemplates,
    addExpense,
    addCostItem,
    updateCostItem,
    deleteCostItem,
    addCardTemplate,
    updateCardTemplate,
    deleteCardTemplate,
    switchIndustry,
    syncStores,
    syncStaff,
    fetchStaff,
    persistStaff,
    addStaff,
    approveStaff,
    rejectStaff,
    updateStaff,
    deleteStaff,
    setupStaffAccount,
    // 线上商城动作
    mallOrders,
    shipMallOrder,
    addMallGoods,
    updateMallGoods,
    deleteMallGoods,
    toggleMallGoodsShelf,
    syncProductToMall,
    syncAllProductsToMall,
    checkoutSession,
    resetSpace,
    recordCashierSettlement,
    // 空间包厢运维动作
    addSpace,
    updateSpace,
    deleteSpace,
    batchAddSpaces,
    updateSpaceStatus,
    // 考勤与请假与小票模板
    receiptTemplate,
    updateReceiptTemplate,
    getResolvedReceiptTemplate,
    paymentConfig,
    updatePaymentConfig,
    loadPaymentRoutePreset,
    attendanceRecords,
    leaveApplications,
    syncAttendanceFromPlatform,
    applyLeave,
    auditLeave,
    // 规章制度、电子签字与员工意见箱
    regulations,
    staffFeedbacks,
    saveRegulation,
    deleteRegulation,
    signRegulation,
    markRegulationRead,
    submitStaffFeedback,
    replyStaffFeedback,
    // 平台建言与需求受理中心 & 租户活动日志时段采集
    platformFeedbacks,
    submitPlatformFeedback,
    replyPlatformFeedback,
    tenantActivityLogs,
    tenantDaytimeUsageStats,
    logTenantActivity,
    // 新租户纯净空间控制
    isNewTenant,
    initNewTenantWorkspace,
    initScenarioDemoData,
    clearAllTenantData,
    loadDemoPackage,
    clearBusinessData
  }
})
