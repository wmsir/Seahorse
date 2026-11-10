// ==============================================================================
// 4 大行业全套真实业务预设数据体系 (Multi-Industry Business Datasets)
// 1. 美容美发美甲 (BEAUTY)
// 2. 餐饮轻食/正餐 (RESTAURANT)
// 3. 汽车养护维修 (AUTO)
// 4. 专营零售 (RETAIL)
// ==============================================================================

import type {
  StoreEntity,
  StaffEntity,
  ProductEntity,
  MaterialEntity,
  MemberEntity,
  LiveSession,
  CostItemEntity,
  RechargeOrder,
  ConsumeOrder,
  TimeCardItem,
  PointsLog,
  RewardLog,
  ExpenseRecord,
  AppointmentRecord
} from './systemDataStore'

export interface CardTemplateEntity {
  id: number
  cardType: 'TIME_CARD' | 'STORED_VALUE' | 'DURATION_CARD' | 'INDEPENDENT_STORED_CARD' | 'BLIND_BOX_CARD' | 'BENEFIT_CARD'
  cardTypeName: string
  cardName: string
  price: number
  originalPrice: number
  contentDescription: string
  validityDays: number
  notes?: string
  themeColor: 'gold' | 'black' | 'purple' | 'blue' | 'emerald' | 'rose'
  discountRate?: number
  principalAmount?: number
  giftAmount?: number
  totalTimes?: number
  serviceSkuName?: string
  status: 'ACTIVE' | 'INACTIVE'
}

export interface IndustryPackage {
  industryCode: 'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL'
  industryName: string
  spaceAlias: string
  appendActionAlias: string
  defaultFeeName: string
  stores: StoreEntity[]
  staff: StaffEntity[]
  products: ProductEntity[]
  materials: MaterialEntity[]
  members: MemberEntity[]
  cardTemplates: CardTemplateEntity[]
  liveSessions: LiveSession[]
  baseCosts: CostItemEntity[]
  rechargeOrders: RechargeOrder[]
  consumeOrders: ConsumeOrder[]
  timeCards: TimeCardItem[]
  pointsLedger: PointsLog[]
  rewardsLedger: RewardLog[]
  expenses: ExpenseRecord[]
  appointments: AppointmentRecord[]
}

// ------------------------------------------------------------------------------
// 1. 美容美发美甲 (BEAUTY)
// ------------------------------------------------------------------------------
export const beautyPackage: IndustryPackage = {
  industryCode: 'BEAUTY',
  industryName: '美容美发美甲',
  spaceAlias: '工位',
  appendActionAlias: '加护理',
  defaultFeeName: '造型设计费',
  stores: [
    {
      storeId: 'S001',
      storeName: '海马丝艺美学·发型美甲定制旗舰店',
      address: '广州市天河区天河路208号粤海天河城4楼402室',
      managerName: '张建华',
      phone: '020-88996611',
      isHeadquarter: true,
      businessStatus: 'OPEN',
      totalSpaces: 8,
      openTime: '10:00 - 22:00'
    },
    {
      storeId: 'S002',
      storeName: '海马丝艺美学·正佳广场概念店',
      address: '广州市天河区天河路123号正佳广场3楼318',
      managerName: '李美华',
      phone: '020-88996622',
      isHeadquarter: false,
      businessStatus: 'OPEN',
      totalSpaces: 6,
      openTime: '10:00 - 22:00'
    }
  ],
  staff: [
    {
      id: 1,
      storeId: 'S001',
      realName: '张建华',
      phone: '13811112222',
      postName: '沙龙旗舰店长',
      role: 'STORE_MANAGER',
      department: '综合运营部',
      baseSalary: 8000,
      serviceCommissionRate: 0.15,
      cardCommissionRate: 0.05,
      retailCommissionRate: 0.10,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-03-01',
      hasSystemAccount: true,
      accountUsername: '13811112222',
      accountPassword: '123456',
      accountStatus: 'ENABLED',
      allowedStoreIds: ['S001', 'S002'],
      allowedMenuPaths: ['/dashboard', '/rooms', '/members', '/products', '/card-template', '/staff-management', '/marketing', '/mall', '/appointments', '/expenses', '/inventory', '/reports', '/regulations', '/chain', '/profile']
    },
    {
      id: 2,
      storeId: 'S001',
      realName: '托尼',
      phone: '13900001111',
      postName: '美业发型总监/主理人',
      role: 'TECHNICIAN',
      department: '美业设计部',
      baseSalary: 5500,
      serviceCommissionRate: 0.30,
      cardCommissionRate: 0.10,
      retailCommissionRate: 0.15,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-04-15',
      hasSystemAccount: true,
      accountUsername: '13900001111',
      accountPassword: '123456',
      accountStatus: 'ENABLED',
      allowedStoreIds: ['S001'],
      allowedMenuPaths: ['/dashboard', '/rooms', '/members', '/products', '/appointments', '/inventory', '/regulations', '/profile']
    },
    {
      id: 3,
      storeId: 'S001',
      realName: '李博',
      phone: '13700002222',
      postName: '资深染烫设计师',
      role: 'TECHNICIAN',
      department: '美业设计部',
      baseSalary: 4500,
      serviceCommissionRate: 0.25,
      cardCommissionRate: 0.08,
      retailCommissionRate: 0.12,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-06-01',
      hasSystemAccount: false
    },
    {
      id: 4,
      storeId: 'S001',
      realName: '王芳',
      phone: '13600003333',
      postName: '高级日式美甲顾问',
      role: 'TECHNICIAN',
      department: '美甲手足SPA部',
      baseSalary: 4200,
      serviceCommissionRate: 0.25,
      cardCommissionRate: 0.10,
      retailCommissionRate: 0.15,
      gender: 'FEMALE',
      status: 'ACTIVE',
      entryDate: '2025-07-10',
      hasSystemAccount: false
    },
    {
      id: 5,
      storeId: 'S001',
      realName: '赵雪',
      phone: '13500004444',
      postName: '前台接待与收银主管',
      role: 'CASHIER',
      department: '前台客户服务部',
      baseSalary: 3800,
      serviceCommissionRate: 0.05,
      cardCommissionRate: 0.05,
      retailCommissionRate: 0.08,
      gender: 'FEMALE',
      status: 'ACTIVE',
      entryDate: '2025-08-01',
      hasSystemAccount: true,
      accountUsername: '13500004444',
      accountPassword: '123456',
      accountStatus: 'ENABLED',
      allowedStoreIds: ['S001'],
      allowedMenuPaths: ['/dashboard', '/rooms', '/members', '/products', '/card-template', '/appointments', '/expenses', '/inventory', '/regulations', '/profile']
    },
    {
      id: 6,
      storeId: 'S001',
      realName: '陈明强',
      phone: '13966668888',
      postName: '高级发型造型顾问',
      role: 'TECHNICIAN',
      department: '美业设计部',
      baseSalary: 4500,
      serviceCommissionRate: 0.25,
      cardCommissionRate: 0.08,
      retailCommissionRate: 0.12,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-09-01',
      hasSystemAccount: true,
      accountUsername: '13966668888',
      accountPassword: '123456',
      accountStatus: 'ENABLED',
      allowedStoreIds: ['S001', 'S002'],
      allowedMenuPaths: ['/dashboard', '/rooms', '/members', '/products', '/appointments', '/inventory', '/regulations', '/profile']
    },
    {
      id: 7,
      storeId: 'S001',
      realName: '孙晓晓',
      phone: '13400005555',
      postName: '高级养护助理',
      role: 'TECHNICIAN',
      department: '头皮养护部',
      baseSalary: 3200,
      serviceCommissionRate: 0.15,
      cardCommissionRate: 0.05,
      retailCommissionRate: 0.08,
      gender: 'FEMALE',
      status: 'ACTIVE',
      entryDate: '2025-09-01'
    }
  ],
  products: [
    { id: 1, code: 'BEA-001', name: '发型总监精修洗剪吹', type: 'SERVICE', category: 'HAIR_CUT', categoryName: '洗剪吹造型', price: 88, cost: 13, durationMinutes: 45, unit: '次' },
    { id: 2, code: 'BEA-002', name: '欧莱雅植物蛋白染发', type: 'SERVICE', category: 'HAIR_DYE', categoryName: '烫染精修', price: 420, cost: 68, durationMinutes: 120, unit: '次' },
    { id: 3, code: 'BEA-003', name: '头皮微生态赋活深度SPA', type: 'SERVICE', category: 'HAIR_SPA', categoryName: '头皮护理SPA', price: 260, cost: 38, durationMinutes: 60, unit: '次' },
    { id: 4, code: 'BEA-004', name: '日式轻奢光疗猫眼美甲', type: 'SERVICE', category: 'NAIL_SPA', categoryName: '美甲手部护理', price: 198, cost: 30, durationMinutes: 75, unit: '次' },
    { id: 5, code: 'BEA-005', name: '摩洛哥坚果修护护发精油 100ml', type: 'RETAIL', category: 'RETAIL_GOODS', categoryName: '家居洗护客装', price: 168, cost: 75, unit: '瓶', spec: '100ml' },
    { id: 6, code: 'BEA-006', name: '哑光强力清爽定型发泥 80g', type: 'RETAIL', category: 'RETAIL_GOODS', categoryName: '家居洗护客装', price: 88, cost: 32, unit: '盒', spec: '80g' },
    { id: 7, code: 'BEA-007', name: '角蛋白沙龙级深层发膜 500ml', type: 'RETAIL', category: 'RETAIL_GOODS', categoryName: '家居洗护客装', price: 198, cost: 88, unit: '罐', spec: '500ml' }
  ],
  materials: [
    { id: 'MAT-B01', code: 'MAT-DYE-01', name: '欧莱雅植物蛋白原装染膏 (栗棕/冷茶色)', category: 'RAW', unit: '支', costPrice: 28, initialStock: 120, safeStock: 20, supplier: '欧莱雅专业美发供应链' },
    { id: 'MAT-B02', code: 'MAT-SPA-01', name: '头皮微生态安瓶赋活精华泥', category: 'RAW', unit: '支', costPrice: 22, initialStock: 80, safeStock: 15, supplier: '资生堂专业头皮研究所' },
    { id: 'MAT-B03', code: 'MAT-OIL-01', name: '摩洛哥坚果修护精油客装 100ml', category: 'RETAIL', unit: '瓶', costPrice: 75, initialStock: 40, safeStock: 10, supplier: '利华美妆供应链' },
    { id: 'MAT-B04', code: 'MAT-MASK-01', name: '角蛋白沙龙级深层发膜 500ml', category: 'RETAIL', unit: '罐', costPrice: 88, initialStock: 6, safeStock: 10, supplier: '利华美妆供应链' }
  ],
  members: [
    { id: 1, memberNo: 'HM880001', name: '林清雅', phone: '13800138001', gender: 'FEMALE', level: 'GOLD', levelName: '金卡会员', registeredStoreId: 'S001', registerTime: '2026-09-01 10:20:00' },
    { id: 2, memberNo: 'HM880002', name: '张小曼', phone: '13912345678', gender: 'FEMALE', level: 'SILVER', levelName: '银卡会员', registeredStoreId: 'S001', referrerId: 1, registerTime: '2026-09-02 14:10:00' },
    { id: 3, memberNo: 'HM880003', name: '王凯', phone: '13788776655', gender: 'MALE', level: 'GOLD', levelName: '金卡会员', registeredStoreId: 'S001', registerTime: '2026-09-03 11:00:00' },
    { id: 4, memberNo: 'HM880004', name: '刘婷婷', phone: '13666554433', gender: 'FEMALE', level: 'SILVER', levelName: '银卡会员', registeredStoreId: 'S001', referrerId: 3, registerTime: '2026-09-04 16:30:00' },
    { id: 5, memberNo: 'HM880005', name: '赵雷', phone: '13511223344', gender: 'MALE', level: 'DIAMOND', levelName: '黑钻会员', registeredStoreId: 'S001', registerTime: '2026-09-05 17:40:00' }
  ],
  cardTemplates: [
    { id: 101, cardType: 'STORED_VALUE', cardTypeName: '储值卡', cardName: '1000元轻奢充值金卡', price: 1000, originalPrice: 1200, principalAmount: 1000, giftAmount: 200, discountRate: 0.85, contentDescription: '充值本金￥1000即赠￥200，全场服务享8.5折', validityDays: 365, themeColor: 'gold', status: 'ACTIVE', notes: '全店美发及美甲服务通用' },
    { id: 102, cardType: 'TIME_CARD', cardTypeName: '次卡', cardName: '欧莱雅植物染烫 3次季卡', price: 980, originalPrice: 1260, totalTimes: 3, serviceSkuName: '欧莱雅植物蛋白染发', contentDescription: '包含欧莱雅植物蛋白染发 × 3次，支持指定发型总监', validityDays: 90, themeColor: 'purple', status: 'ACTIVE', notes: '季卡不限本人，支持亲友共享' },
    { id: 103, cardType: 'TIME_CARD', cardTypeName: '次卡', cardName: '头皮微生态SPA赋活 5次年卡', price: 990, originalPrice: 1300, totalTimes: 5, serviceSkuName: '头皮微生态赋活深度SPA', contentDescription: '包含头皮深度SPA护理 × 5次 + 赠毛囊检测', validityDays: 365, themeColor: 'emerald', status: 'ACTIVE', notes: '养护发根，改善头皮微环境' },
    { id: 104, cardType: 'STORED_VALUE', cardTypeName: '储值卡', cardName: '300元美甲美睫体验卡', price: 300, originalPrice: 350, principalAmount: 300, giftAmount: 50, discountRate: 0.90, contentDescription: '可用金额￥350，美甲光疗享9折优惠', validityDays: 180, themeColor: 'blue', status: 'ACTIVE' },
    { id: 105, cardType: 'BENEFIT_CARD', cardTypeName: '权益卡', cardName: '黑钻尊享年费专属权益卡', price: 1888, originalPrice: 3680, contentDescription: '全年洗剪吹造型半价，每月赠送一次深层滋养发膜护理', validityDays: 365, themeColor: 'black', status: 'ACTIVE', notes: '黑钻VIP专属身份标识' }
  ],
  liveSessions: [
    { id: 1, spaceId: 1, spaceName: 'VIP 1号美发镜台', sessionNo: 'SES20260906001', customerName: '林清雅', customerPhone: '13800138001', memberId: 1, startTime: '2026-09-06 14:00:00', totalAmount: 420, status: 'SERVING', items: [{ name: '欧莱雅植物蛋白染发', price: 380, qty: 1 }, { name: '发型总监精修设计费', price: 40, qty: 1 }] },
    { id: 2, spaceId: 2, spaceName: '头皮SPA专属养护舱', sessionNo: 'SES20260906002', customerName: '张小曼', customerPhone: '13912345678', memberId: 2, startTime: '2026-09-06 14:30:00', totalAmount: 260, status: 'SERVING', items: [{ name: '头皮微生态赋活深度SPA', price: 260, qty: 1 }] },
    { id: 3, spaceId: 3, spaceName: '造型设计 3号镜台', sessionNo: 'SES20260906003', customerName: '王凯', customerPhone: '13788776655', memberId: 3, startTime: '2026-09-06 15:00:00', totalAmount: 88, status: 'SERVING', items: [{ name: '总监设计洗剪吹', price: 88, qty: 1 }] }
  ],
  baseCosts: [
    { id: 101, code: 'CST-B-001', name: '商场旗舰店核心铺位营业租金', category: 'RENT_UTILITY', categoryName: '店面房租能耗', nature: 'FIXED', amount: 18000, month: '2026-09', date: '2026-09-01', storeId: 'S001', handler: '李店长', invoiceNo: 'RNT-20260901', notes: '粤海天河城月度固定租金' },
    { id: 102, code: 'CST-B-002', name: '欧莱雅及施华蔻专业染烫耗材备货', category: 'MATERIAL', categoryName: '物料耗材成本', nature: 'VARIABLE', amount: 9200, month: '2026-09', date: '2026-09-03', storeId: 'S001', handler: '库管-张芳', invoiceNo: 'MAT-20260903', notes: '植物蛋白染膏及药水采购' },
    { id: 103, code: 'CST-B-003', name: '头皮SPA植物精油及客用品消耗', category: 'MATERIAL', categoryName: '物料耗材成本', nature: 'VARIABLE', amount: 4500, month: '2026-09', date: '2026-09-04', storeId: 'S001', handler: '托尼总监', invoiceNo: 'SPA-20260904', notes: '植物安瓶精油与一次性浴巾' },
    { id: 104, code: 'CST-B-004', name: '全天恒温中央空调与大功率动力电费', category: 'RENT_UTILITY', categoryName: '店面房租能耗', nature: 'VARIABLE', amount: 3800, month: '2026-09', date: '2026-09-06', storeId: 'S001', handler: '赵雪', invoiceNo: 'UTL-202609-01', notes: '高负荷烘发与空调水电气' },
    { id: 105, code: 'CST-B-005', name: '美团点评本地生活团购佣金推广', category: 'MARKETING', categoryName: '营销获客成本', nature: 'VARIABLE', amount: 3600, month: '2026-09', date: '2026-09-02', storeId: 'S001', handler: '李店长', invoiceNo: 'MKT-MT-0902', notes: '线上洗剪吹与染烫核销佣金' },
    { id: 106, code: 'CST-B-006', name: '智能微电脑SPA舱与造型镜台直线折旧', category: 'DEPRECIATION', categoryName: '设备资产折旧', nature: 'FIXED', amount: 2500, month: '2026-09', date: '2026-09-01', storeId: 'S001', handler: '资产部-陈工', invoiceNo: 'DEP-EQ-0901', notes: '固定资产60期直线分摊' },
    { id: 107, code: 'CST-B-007', name: '客休区现磨咖啡花茶与环境消杀绿植', category: 'ADMIN_MISC', categoryName: '日常运营杂费', nature: 'FIXED', amount: 1600, month: '2026-09', date: '2026-09-05', storeId: 'S001', handler: '赵雪', invoiceNo: 'ADM-0905', notes: '高端伴饮与保洁消杀服务' }
  ],
  rechargeOrders: [
    { id: 1, orderNo: 'RC20260901001', memberId: 1, storeId: 'S001', sellerEmployeeId: 2, principalAmount: 1000, giftAmount: 200, paymentMethod: 'WECHAT', pointsGiven: 1000, createTime: '2026-09-01 10:30:00', status: 'COMPLETED' },
    { id: 2, orderNo: 'RC20260902001', memberId: 2, storeId: 'S001', sellerEmployeeId: 3, principalAmount: 300, giftAmount: 50, paymentMethod: 'ALIPAY', pointsGiven: 300, createTime: '2026-09-02 14:15:00', status: 'COMPLETED' },
    { id: 3, orderNo: 'RC20260903001', memberId: 3, storeId: 'S001', sellerEmployeeId: 2, principalAmount: 1000, giftAmount: 200, paymentMethod: 'WECHAT', pointsGiven: 1000, createTime: '2026-09-03 11:20:00', status: 'COMPLETED' },
    { id: 4, orderNo: 'RC20260905001', memberId: 5, storeId: 'S001', sellerEmployeeId: 2, principalAmount: 2000, giftAmount: 500, paymentMethod: 'WECHAT', pointsGiven: 2000, createTime: '2026-09-05 18:00:00', status: 'COMPLETED' }
  ],
  consumeOrders: [
    { id: 1, orderNo: 'ORD20260906001', memberId: 1, storeId: 'S001', primaryTechnicianId: 2, cashierEmployeeId: 5, items: [{ productId: 2, productName: '欧莱雅植物蛋白染发', type: 'SERVICE', price: 420, quantity: 1, bomCost: 68 }], totalAmount: 420, couponDiscount: 50, couponId: 'CPN-001', cardDeductPrincipal: 240, cardDeductGift: 48, cashierPaidAmount: 82, paymentMethod: 'WECHAT', pointsEarned: 82, pointsBurned: 0, createTime: '2026-09-06 14:35:00', status: 'COMPLETED' },
    { id: 2, orderNo: 'ORD20260906002', memberId: 2, storeId: 'S001', primaryTechnicianId: 3, cashierEmployeeId: 5, items: [{ productId: 5, productName: '摩洛哥坚果修护护发精油 100ml', type: 'RETAIL', price: 168, quantity: 1, bomCost: 75 }], totalAmount: 168, couponDiscount: 0, cardDeductPrincipal: 0, cardDeductGift: 0, cashierPaidAmount: 168, paymentMethod: 'WECHAT', pointsEarned: 168, pointsBurned: 0, createTime: '2026-09-06 15:10:05', status: 'COMPLETED' },
    { id: 3, orderNo: 'ORD20260906003', memberId: 3, storeId: 'S001', primaryTechnicianId: 2, cashierEmployeeId: 5, items: [{ productId: 6, productName: '哑光强力清爽定型发泥 80g', type: 'RETAIL', price: 88, quantity: 1, bomCost: 32 }], totalAmount: 88, couponDiscount: 0, cardDeductPrincipal: 0, cardDeductGift: 0, cashierPaidAmount: 88, paymentMethod: 'ALIPAY', pointsEarned: 88, pointsBurned: 0, createTime: '2026-09-06 16:05:30', status: 'COMPLETED' },
    { id: 4, orderNo: 'ORD20260906004', memberId: 4, storeId: 'S001', primaryTechnicianId: 4, cashierEmployeeId: 5, items: [{ productId: 1, productName: '发型总监精修洗剪吹', type: 'SERVICE', price: 88, quantity: 1, bomCost: 13 }], totalAmount: 88, couponDiscount: 50, couponId: 'CPN-004', cardDeductPrincipal: 0, cardDeductGift: 0, cashierPaidAmount: 38, paymentMethod: 'WECHAT', pointsEarned: 38, pointsBurned: 0, createTime: '2026-09-06 11:35:12', status: 'COMPLETED' }
  ],
  timeCards: [
    { id: 1, memberId: 1, skuId: 1, cardName: '欧莱雅植物染烫 3次季卡', totalTimes: 3, usedTimes: 1, unitPrice: 326.6, expireDate: '2026-12-31' },
    { id: 2, memberId: 3, skuId: 2, cardName: '头皮微生态SPA赋活 5次年卡', totalTimes: 5, usedTimes: 1, unitPrice: 198, expireDate: '2027-03-31' }
  ],
  pointsLedger: [
    { id: 1, memberId: 1, type: 'RECHARGE_GIFT', typeName: '开卡充值即赠', pointsDelta: 1000, balanceAfter: 1000, operator: '系统自动', createTime: '2026-09-01 10:30:00' },
    { id: 2, memberId: 1, type: 'CONSUME_EARN', typeName: '消费实付获赠', pointsDelta: 82, balanceAfter: 1082, operator: '收银结账', createTime: '2026-09-06 14:35:00' }
  ],
  rewardsLedger: [
    { id: 1, memberId: 1, referredMemberId: 2, reason: '推荐张小曼开通美发卡', rewardDelta: 50, balanceAfter: 50, createTime: '2026-09-02 14:30:00' }
  ],
  expenses: [
    { id: 1, storeId: 'S001', category: 'RENT', categoryName: '房租水电物业', title: '9月份商场租金与能耗物业', amount: 18000, date: '2026-09-01', handler: '张建华', note: '已转账天河城财务部' },
    { id: 2, storeId: 'S001', category: 'SUPPLY', categoryName: '耗材物料采购', title: '9月首批染膏与精油采购', amount: 9200, date: '2026-09-02', handler: '赵雪', note: '欧莱雅供货款项' }
  ],
  appointments: [
    { id: 1, aptNo: 'APT20260906001', memberId: 1, memberName: '林清雅', phone: '13800138001', storeId: 'S001', technicianId: 2, technicianName: '托尼', productId: 2, productName: '欧莱雅植物蛋白染发', date: '2026-09-06', timeSlot: '14:00 - 16:00', status: 'COMPLETED' },
    { id: 2, aptNo: 'APT20260906002', memberId: 2, memberName: '张小曼', phone: '13912345678', storeId: 'S001', technicianId: 3, technicianName: '李博', productId: 3, productName: '头皮微生态赋活深度SPA', date: '2026-09-06', timeSlot: '16:30 - 17:30', status: 'COMPLETED' },
    { id: 3, aptNo: 'APT20260906003', memberId: 5, memberName: '赵雷', phone: '13511223344', storeId: 'S001', technicianId: 2, technicianName: '托尼', productId: 1, productName: '发型总监精修洗剪吹', date: '2026-09-06', timeSlot: '19:00 - 20:00', status: 'PENDING' }
  ]
}

// ------------------------------------------------------------------------------
// 2. 餐饮轻食/正餐 (RESTAURANT)
// ------------------------------------------------------------------------------
export const restaurantPackage: IndustryPackage = {
  industryCode: 'RESTAURANT',
  industryName: '餐饮轻食/正餐',
  spaceAlias: '包厢',
  appendActionAlias: '加菜品',
  defaultFeeName: '茶位及服务费',
  stores: [
    {
      storeId: 'R001',
      storeName: '栖枫悦食·轻奢融合料理 (天河城旗舰店)',
      address: '广州市天河区天河路208号天河城6楼美食天街601号',
      managerName: '张晓雯',
      phone: '020-88775511',
      isHeadquarter: true,
      businessStatus: 'OPEN',
      totalSpaces: 10,
      openTime: '11:00 - 22:00'
    },
    {
      storeId: 'R002',
      storeName: '栖枫悦食·太古汇精致轻食沙龙店',
      address: '广州市天河区天河路383号太古汇B2层轻餐饮街区',
      managerName: '刘震宇',
      phone: '020-88775522',
      isHeadquarter: false,
      businessStatus: 'OPEN',
      totalSpaces: 8,
      openTime: '10:30 - 21:30'
    }
  ],
  staff: [
    {
      id: 11,
      storeId: 'R001',
      realName: '刘震宇',
      phone: '13911223344',
      postName: '行政主厨/后厨总监',
      role: 'TECHNICIAN',
      department: '后厨品控部',
      baseSalary: 9500,
      serviceCommissionRate: 0.05,
      cardCommissionRate: 0.02,
      retailCommissionRate: 0.05,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-01-10'
    },
    {
      id: 12,
      storeId: 'R001',
      realName: '张晓雯',
      phone: '13822334455',
      postName: '前厅大堂主管',
      role: 'STORE_MANAGER',
      department: '前厅服务部',
      baseSalary: 6000,
      serviceCommissionRate: 0.04,
      cardCommissionRate: 0.08,
      retailCommissionRate: 0.06,
      gender: 'FEMALE',
      status: 'ACTIVE',
      entryDate: '2025-02-15'
    },
    {
      id: 13,
      storeId: 'R001',
      realName: '陈建伟',
      phone: '13733445566',
      postName: '特一级热菜厨师',
      role: 'TECHNICIAN',
      department: '后厨炉灶部',
      baseSalary: 6500,
      serviceCommissionRate: 0.04,
      cardCommissionRate: 0.02,
      retailCommissionRate: 0.03,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-03-20'
    },
    {
      id: 14,
      storeId: 'R001',
      realName: '李国强',
      phone: '13644556677',
      postName: '资深传菜领班',
      role: 'TECHNICIAN',
      department: '前厅服务部',
      baseSalary: 4200,
      serviceCommissionRate: 0.03,
      cardCommissionRate: 0.05,
      retailCommissionRate: 0.04,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-05-01'
    },
    {
      id: 15,
      storeId: 'R001',
      realName: '陈思思',
      phone: '13555667788',
      postName: '前台收银/调酒师',
      role: 'CASHIER',
      department: '前厅服务部',
      baseSalary: 4000,
      serviceCommissionRate: 0.02,
      cardCommissionRate: 0.04,
      retailCommissionRate: 0.05,
      gender: 'FEMALE',
      status: 'ACTIVE',
      entryDate: '2025-06-15'
    }
  ],
  products: [
    { id: 21, code: 'RES-001', name: '主厨精选M9澳洲和牛慢煎双人套餐', type: 'SERVICE', category: 'MAIN_COURSE', categoryName: '主厨招牌正餐', price: 398, cost: 135, durationMinutes: 60, unit: '份' },
    { id: 22, code: 'RES-002', name: '慢炖法式勃艮第红酒牛肋排', type: 'SERVICE', category: 'MAIN_COURSE', categoryName: '主厨招牌正餐', price: 188, cost: 62, durationMinutes: 45, unit: '例' },
    { id: 23, code: 'RES-003', name: '招牌黑松露温泉蛋轻食沙拉', type: 'SERVICE', category: 'LIGHT_MEAL', categoryName: '轻食与前菜', price: 68, cost: 18, durationMinutes: 20, unit: '份' },
    { id: 24, code: 'RES-004', name: '现烤意式海鲜手工薄脆披萨', type: 'SERVICE', category: 'PIZZA_PASTA', categoryName: '披萨意面主食', price: 98, cost: 28, durationMinutes: 30, unit: '份' },
    { id: 25, code: 'RES-005', name: '现调精酿鲜萃白桃乌龙果啤', type: 'RETAIL', category: 'BEVERAGE', categoryName: '酒水精酿饮品', price: 38, cost: 9, unit: '杯' },
    { id: 26, code: 'RES-006', name: '经典意式手作马斯卡彭提拉米苏', type: 'RETAIL', category: 'DESSERT', categoryName: '甜品烘焙特赏', price: 48, cost: 14, unit: '份' }
  ],
  materials: [
    { id: 'MAT-R01', code: 'MAT-BEEF-01', name: '澳洲冰鲜谷饲M9级西冷和牛 (公斤)', category: 'RAW', unit: 'kg', costPrice: 220, initialStock: 50, safeStock: 10, supplier: '大洋洲冷链有机直采' },
    { id: 'MAT-R02', code: 'MAT-TRUFFLE-01', name: '黑松露原浆与特级初榨橄榄油', category: 'RAW', unit: '瓶', costPrice: 85, initialStock: 30, safeStock: 8, supplier: '意大利味好美供应链' },
    { id: 'MAT-R03', code: 'MAT-BEER-01', name: '精酿果味鲜啤桶装原液 (20L)', category: 'RAW', unit: '桶', costPrice: 180, initialStock: 15, safeStock: 4, supplier: '青岛精酿工坊' }
  ],
  members: [
    { id: 21, memberNo: 'FD880001', name: '高逸轩', phone: '13800228801', gender: 'MALE', level: 'DIAMOND', levelName: '黑钻食神', registeredStoreId: 'R001', registerTime: '2026-09-01 12:30:00' },
    { id: 22, memberNo: 'FD880002', name: '苏雅菲', phone: '13911447788', gender: 'FEMALE', level: 'GOLD', levelName: '金牌老饕', registeredStoreId: 'R001', referrerId: 21, registerTime: '2026-09-02 18:20:00' },
    { id: 23, memberNo: 'FD880003', name: '杜明诚', phone: '13799663322', gender: 'MALE', level: 'SILVER', levelName: '银卡食客', registeredStoreId: 'R001', registerTime: '2026-09-03 19:10:00' }
  ],
  cardTemplates: [
    { id: 201, cardType: 'STORED_VALUE', cardTypeName: '储值卡', cardName: '栖枫老饕至尊储值卡', price: 2000, originalPrice: 2500, principalAmount: 2000, giftAmount: 500, discountRate: 0.88, contentDescription: '充值￥2000赠送￥500，全单享8.8折特权', validityDays: 365, themeColor: 'gold', status: 'ACTIVE', notes: '全店餐品及酒水通用，生日当天免包厢服务费' },
    { id: 202, cardType: 'TIME_CARD', cardTypeName: '次卡', cardName: '白领轻食能量 30天午餐畅享卡', price: 1280, originalPrice: 2040, totalTimes: 30, serviceSkuName: '招牌黑松露温泉蛋轻食沙拉', contentDescription: '包含30份主厨定制工作日轻食午餐套餐', validityDays: 60, themeColor: 'emerald', status: 'ACTIVE', notes: '每日限核销1次，堂食外带皆可' },
    { id: 203, cardType: 'STORED_VALUE', cardTypeName: '储值卡', cardName: '500元亲友欢聚尝鲜卡', price: 500, originalPrice: 580, principalAmount: 500, giftAmount: 80, discountRate: 0.95, contentDescription: '可用金额￥580，整单结账9.5折', validityDays: 180, themeColor: 'blue', status: 'ACTIVE' },
    { id: 204, cardType: 'BENEFIT_CARD', cardTypeName: '权益卡', cardName: 'VIP景观包厢全年免服务费卡', price: 888, originalPrice: 2400, contentDescription: '全年不限次免除VIP包厢低消与服务费，提前专属留位', validityDays: 365, themeColor: 'black', status: 'ACTIVE', notes: '商宴与家宴必备首选' }
  ],
  liveSessions: [
    { id: 11, spaceId: 101, spaceName: '全景景观 1号大卡座', sessionNo: 'SES20260906101', customerName: '高逸轩', customerPhone: '13800228801', memberId: 21, startTime: '2026-09-06 18:30:00', totalAmount: 586, status: 'SERVING', items: [{ name: '主厨精选M9和牛双人套餐', price: 398, qty: 1 }, { name: '红酒牛肋排', price: 188, qty: 1 }] },
    { id: 12, spaceId: 102, spaceName: 'VIP 紫荆景观包厢', sessionNo: 'SES20260906102', customerName: '苏雅菲', customerPhone: '13911447788', memberId: 22, startTime: '2026-09-06 19:00:00', totalAmount: 398, status: 'SERVING', items: [{ name: '主厨精选M9和牛双人套餐', price: 398, qty: 1 }] }
  ],
  baseCosts: [
    { id: 201, code: 'CST-R-001', name: '天河城6楼旺铺月度商场租金物业', category: 'RENT_UTILITY', categoryName: '店面房租能耗', nature: 'FIXED', amount: 22000, month: '2026-09', date: '2026-09-01', storeId: 'R001', handler: '张晓雯', invoiceNo: 'RNT-R202609', notes: '餐饮核心商圈租金' },
    { id: 202, code: 'CST-R-002', name: '冷链进口M9牛肉与有机蔬菜每日生鲜直采', category: 'MATERIAL', categoryName: '物料耗材成本', nature: 'VARIABLE', amount: 15600, month: '2026-09', date: '2026-09-03', storeId: 'R001', handler: '刘震宇', invoiceNo: 'INGR-202609', notes: '原产地冷链原切食材采购款' },
    { id: 203, code: 'CST-R-003', name: '厨房商用猛火天然气与排烟环保电费', category: 'RENT_UTILITY', categoryName: '店面房租能耗', nature: 'VARIABLE', amount: 5200, month: '2026-09', date: '2026-09-06', storeId: 'R001', handler: '陈建伟', invoiceNo: 'GAS-202609', notes: '厨房燃气与风机动力电费' },
    { id: 204, code: 'CST-R-004', name: '大众点评必吃榜流量曝光与团购抽佣', category: 'MARKETING', categoryName: '营销获客成本', nature: 'VARIABLE', amount: 4800, month: '2026-09', date: '2026-09-02', storeId: 'R001', handler: '张晓雯', invoiceNo: 'MKT-DP-202609', notes: '线上堂食代金券核销技术费' },
    { id: 205, code: 'CST-R-005', name: '智能德国万能蒸烤箱与超声波洗碗机折旧', category: 'DEPRECIATION', categoryName: '设备资产折旧', nature: 'FIXED', amount: 2800, month: '2026-09', date: '2026-09-01', storeId: 'R001', handler: '周工', invoiceNo: 'DEP-OVEN-09', notes: '重资产厨房设备月度折旧' },
    { id: 206, code: 'CST-R-006', name: '骨瓷餐具消杀洗涤与定制餐巾纸包装耗材', category: 'ADMIN_MISC', categoryName: '日常运营杂费', nature: 'FIXED', amount: 1900, month: '2026-09', date: '2026-09-05', storeId: 'R001', handler: '李国强', invoiceNo: 'PKG-202609', notes: '高品质餐巾纸、打包盒与餐具消毒' }
  ],
  rechargeOrders: [
    { id: 21, orderNo: 'RC20260901201', memberId: 21, storeId: 'R001', sellerEmployeeId: 12, principalAmount: 2000, giftAmount: 500, paymentMethod: 'WECHAT', pointsGiven: 2000, createTime: '2026-09-01 12:35:00', status: 'COMPLETED' },
    { id: 22, orderNo: 'RC20260902202', memberId: 22, storeId: 'R001', sellerEmployeeId: 12, principalAmount: 500, giftAmount: 80, paymentMethod: 'ALIPAY', pointsGiven: 500, createTime: '2026-09-02 18:25:00', status: 'COMPLETED' }
  ],
  consumeOrders: [
    { id: 21, orderNo: 'ORD20260906201', memberId: 21, storeId: 'R001', primaryTechnicianId: 11, cashierEmployeeId: 15, items: [{ productId: 21, productName: '主厨精选M9和牛双人套餐', type: 'SERVICE', price: 398, quantity: 1, bomCost: 135 }], totalAmount: 398, couponDiscount: 0, cardDeductPrincipal: 350, cardDeductGift: 48, cashierPaidAmount: 0, paymentMethod: 'OFFLINE', pointsEarned: 398, pointsBurned: 0, createTime: '2026-09-06 19:40:00', status: 'COMPLETED' }
  ],
  timeCards: [
    { id: 21, memberId: 22, skuId: 23, cardName: '白领轻食能量 30天午餐畅享卡', totalTimes: 30, usedTimes: 4, unitPrice: 42.6, expireDate: '2026-10-31' }
  ],
  pointsLedger: [
    { id: 21, memberId: 21, type: 'RECHARGE_GIFT', typeName: '餐饮储值赠积分', pointsDelta: 2000, balanceAfter: 2000, operator: '系统自动', createTime: '2026-09-01 12:35:00' }
  ],
  rewardsLedger: [
    { id: 21, memberId: 21, referredMemberId: 22, reason: '成功推荐好友到店用餐开卡', rewardDelta: 50, balanceAfter: 50, createTime: '2026-09-02 18:30:00' }
  ],
  expenses: [
    { id: 21, storeId: 'R001', category: 'RENT', categoryName: '房租水电物业', title: '9月份餐厅铺位租金', amount: 22000, date: '2026-09-01', handler: '张晓雯', note: '商场租金结清' }
  ],
  appointments: [
    { id: 21, aptNo: 'APT20260906201', memberId: 21, memberName: '高逸轩', phone: '13800228801', storeId: 'R001', technicianId: 11, technicianName: '刘震宇', productId: 21, productName: '主厨精选M9澳洲和牛慢煎双人套餐', date: '2026-09-06', timeSlot: '18:30 - 20:00', status: 'COMPLETED' }
  ]
}

// ------------------------------------------------------------------------------
// 3. 汽车养护维修 (AUTO)
// ------------------------------------------------------------------------------
export const autoPackage: IndustryPackage = {
  industryCode: 'AUTO',
  industryName: '汽车养护维修',
  spaceAlias: '工位',
  appendActionAlias: '加配件',
  defaultFeeName: '工时检测费',
  stores: [
    {
      storeId: 'A001',
      storeName: '极速驰骋·智能汽修养护旗舰工坊',
      address: '广州市海珠区新港东路1022号华南汽贸园A区08栋',
      managerName: '陆国强',
      phone: '020-89883311',
      isHeadquarter: true,
      businessStatus: 'OPEN',
      totalSpaces: 8,
      openTime: '08:30 - 20:30'
    },
    {
      storeId: 'A002',
      storeName: '极速驰骋·琶洲社区快修快洗站',
      address: '广州市海珠区阅江中路688号保利天悦首层底商',
      managerName: '陈明远',
      phone: '020-89883322',
      isHeadquarter: false,
      businessStatus: 'OPEN',
      totalSpaces: 5,
      openTime: '09:00 - 21:00'
    }
  ],
  staff: [
    {
      id: 31,
      storeId: 'A001',
      realName: '陆国强',
      phone: '13922331100',
      postName: '汽修技术总监/厂长',
      role: 'STORE_MANAGER',
      department: '厂务管理部',
      baseSalary: 8500,
      serviceCommissionRate: 0.10,
      cardCommissionRate: 0.05,
      retailCommissionRate: 0.08,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2024-11-01'
    },
    {
      id: 32,
      storeId: 'A001',
      realName: '陈明远',
      phone: '13833442211',
      postName: '发动机机电特级技师',
      role: 'TECHNICIAN',
      department: '机电维修部',
      baseSalary: 6500,
      serviceCommissionRate: 0.35,
      cardCommissionRate: 0.08,
      retailCommissionRate: 0.12,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-01-15'
    },
    {
      id: 33,
      storeId: 'A001',
      realName: '赵宏伟',
      phone: '13744553322',
      postName: '车身微创快修技师',
      role: 'TECHNICIAN',
      department: '钣金喷漆部',
      baseSalary: 5500,
      serviceCommissionRate: 0.30,
      cardCommissionRate: 0.06,
      retailCommissionRate: 0.10,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-02-20'
    },
    {
      id: 34,
      storeId: 'A001',
      realName: '孙立',
      phone: '13655664433',
      postName: '汽车美容贴膜技工',
      role: 'TECHNICIAN',
      department: '汽车美容部',
      baseSalary: 4000,
      serviceCommissionRate: 0.25,
      cardCommissionRate: 0.08,
      retailCommissionRate: 0.10,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-04-10'
    },
    {
      id: 35,
      storeId: 'A001',
      realName: '钱思思',
      phone: '13566775544',
      postName: '首席接车服务顾问',
      role: 'CASHIER',
      department: '客户接待部',
      baseSalary: 4200,
      serviceCommissionRate: 0.05,
      cardCommissionRate: 0.10,
      retailCommissionRate: 0.08,
      gender: 'FEMALE',
      status: 'ACTIVE',
      entryDate: '2025-05-15'
    }
  ],
  products: [
    { id: 31, code: 'AUT-001', name: '美孚1号全合成机油小保养套餐 (含机滤+全车检查)', type: 'SERVICE', category: 'MAINTENANCE', categoryName: '机修保养项目', price: 380, cost: 160, durationMinutes: 60, unit: '台次' },
    { id: 32, code: 'AUT-002', name: '全车深层泥巴脱水脱脂精洗+手工棕榈打蜡', type: 'SERVICE', category: 'CAR_WASH', categoryName: '精致美容洗车', price: 128, cost: 25, durationMinutes: 50, unit: '台次' },
    { id: 33, code: 'AUT-003', name: '德国3D高清红外四轮定位与底盘调校', type: 'SERVICE', category: 'MAINTENANCE', categoryName: '机修保养项目', price: 260, cost: 30, durationMinutes: 45, unit: '台次' },
    { id: 34, code: 'AUT-004', name: '米其林浩悦浩越静音轮胎 225/55 R18 (包安装动平衡)', type: 'RETAIL', category: 'TIRE_PARTS', categoryName: '原厂轮胎配件', price: 580, cost: 380, unit: '条' },
    { id: 35, code: 'AUT-005', name: '汽车空调管路纳米超声雾化除菌除味', type: 'SERVICE', category: 'AIR_CLEAN', categoryName: '车内健康养护', price: 158, cost: 22, durationMinutes: 30, unit: '台次' },
    { id: 36, code: 'AUT-006', name: '高沸点原厂DOT4制动液深度循环更换', type: 'SERVICE', category: 'MAINTENANCE', categoryName: '机修保养项目', price: 320, cost: 90, durationMinutes: 40, unit: '台次' }
  ],
  materials: [
    { id: 'MAT-A01', code: 'MAT-OIL-01', name: '美孚1号经典全合成机油 5W-30 (4L装)', category: 'RAW', unit: '桶', costPrice: 140, initialStock: 80, safeStock: 15, supplier: '美孚中国授权经销商' },
    { id: 'MAT-A02', code: 'MAT-FILTER-01', name: '博世高精度机油滤清器 (通用型号)', category: 'RAW', unit: '个', costPrice: 20, initialStock: 120, safeStock: 30, supplier: '博世汽车后市场' },
    { id: 'MAT-A03', code: 'MAT-TIRE-01', name: '米其林225/55 R18浩悦轮胎', category: 'RETAIL', unit: '条', costPrice: 380, initialStock: 16, safeStock: 4, supplier: '米其林供应链' }
  ],
  members: [
    { id: 31, memberNo: 'QC880001', name: '严建军 (粤A·888X2 奔驰E300L)', phone: '13800336601', gender: 'MALE', level: 'DIAMOND', levelName: '尊享白金车主', registeredStoreId: 'A001', registerTime: '2026-09-01 09:30:00' },
    { id: 32, memberNo: 'QC880002', name: '何思琪 (粤A·666V1 宝马3系)', phone: '13911558899', gender: 'FEMALE', level: 'GOLD', levelName: '金卡车主', registeredStoreId: 'A001', referrerId: 31, registerTime: '2026-09-02 11:20:00' },
    { id: 33, memberNo: 'QC880003', name: '周志勇 (粤A·555K8 特斯拉Model Y)', phone: '13788224411', gender: 'MALE', level: 'SILVER', levelName: '银卡车主', registeredStoreId: 'A001', registerTime: '2026-09-03 14:00:00' }
  ],
  cardTemplates: [
    { id: 301, cardType: 'TIME_CARD', cardTypeName: '次卡', cardName: '全合成机油小保养 4次年卡', price: 1280, originalPrice: 1520, totalTimes: 4, serviceSkuName: '美孚1号全合成机油小保养套餐', contentDescription: '包含4次美孚全合成机油更换+博世机滤+全车36项安全体检', validityDays: 365, themeColor: 'gold', status: 'ACTIVE', notes: '全国联保，每次节省近￥100' },
    { id: 302, cardType: 'TIME_CARD', cardTypeName: '次卡', cardName: '精致深层手工洗车 24次超值储值卡', price: 680, originalPrice: 1200, totalTimes: 24, serviceSkuName: '全车深层精洗手工打蜡', contentDescription: '包含24次全车手工精洗打蜡服务，免排队快速通道', validityDays: 365, themeColor: 'blue', status: 'ACTIVE', notes: '双店通用，随到随洗' },
    { id: 303, cardType: 'STORED_VALUE', cardTypeName: '储值卡', cardName: '5000元养车无忧至尊黑金卡', price: 5000, originalPrice: 6500, principalAmount: 5000, giftAmount: 1500, discountRate: 0.80, contentDescription: '充值￥5000即送￥1500，全场配件及工时享8折优惠', validityDays: 730, themeColor: 'black', status: 'ACTIVE', notes: '尊享免费道路搭电与四轮动平衡' },
    { id: 304, cardType: 'BENEFIT_CARD', cardTypeName: '权益卡', cardName: '道路救援与车检安全护航年卡', price: 299, originalPrice: 880, contentDescription: '市内全天候3次免费电瓶搭电、补胎充气及免费四轮调位检测', validityDays: 365, themeColor: 'emerald', status: 'ACTIVE', notes: '行车出行必备安心保障' }
  ],
  liveSessions: [
    { id: 21, spaceId: 201, spaceName: '重载机电 1号双柱举升位', sessionNo: 'SES20260906201', customerName: '严建军 (奔驰E300L)', customerPhone: '13800336601', memberId: 31, startTime: '2026-09-06 14:00:00', totalAmount: 380, status: 'SERVING', items: [{ name: '美孚全合成机油小保养套餐', price: 380, qty: 1 }] },
    { id: 22, spaceId: 202, spaceName: '水循环精洗美容 2号车位', sessionNo: 'SES20260906202', customerName: '何思琪 (宝马3系)', customerPhone: '13911558899', memberId: 32, startTime: '2026-09-06 14:30:00', totalAmount: 128, status: 'SERVING', items: [{ name: '全车深层精洗手工打蜡', price: 128, qty: 1 }] }
  ],
  baseCosts: [
    { id: 301, code: 'CST-A-001', name: '华南汽贸园临街标准厂房月度租金', category: 'RENT_UTILITY', categoryName: '店面房租能耗', nature: 'FIXED', amount: 16000, month: '2026-09', date: '2026-09-01', storeId: 'A001', handler: '陆国强', invoiceNo: 'RNT-A202609', notes: '双跨门面汽修厂房租金' },
    { id: 302, code: 'CST-A-002', name: '原厂美孚机油/机滤备货大宗采购款', category: 'MATERIAL', categoryName: '物料耗材成本', nature: 'VARIABLE', amount: 11800, month: '2026-09', date: '2026-09-03', storeId: 'A001', handler: '陈明远', invoiceNo: 'OIL-202609', notes: '全合成机油大批入库款' },
    { id: 303, code: 'CST-A-003', name: '烤漆房大功率电加热与举升机动力电费', category: 'RENT_UTILITY', categoryName: '店面房租能耗', nature: 'VARIABLE', amount: 4600, month: '2026-09', date: '2026-09-06', storeId: 'A001', handler: '钱思思', invoiceNo: 'PWR-202609', notes: '汽修高负荷三相动力用电' },
    { id: 304, code: 'CST-A-004', name: '途虎与天猫养车引流平台核销佣金', category: 'MARKETING', categoryName: '营销获客成本', nature: 'VARIABLE', amount: 3200, month: '2026-09', date: '2026-09-02', storeId: 'A001', handler: '钱思思', invoiceNo: 'MKT-TUHU-09', notes: '线上小保养订单抽成' },
    { id: 305, code: 'CST-A-005', name: '4吨双柱举升机与道通诊断电脑折旧', category: 'DEPRECIATION', categoryName: '设备资产折旧', nature: 'FIXED', amount: 3000, month: '2026-09', date: '2026-09-01', storeId: 'A001', handler: '王工', invoiceNo: 'DEP-EQ-09A', notes: '汽修专用大型设备直线折旧' },
    { id: 306, code: 'CST-A-006', name: '环保机油废液危险废物合规处置费', category: 'ADMIN_MISC', categoryName: '日常运营杂费', nature: 'FIXED', amount: 1800, month: '2026-09', date: '2026-09-05', storeId: 'A001', handler: '陆国强', invoiceNo: 'ENV-202609', notes: '危废合规回收处置环保费' }
  ],
  rechargeOrders: [
    { id: 31, orderNo: 'RC20260901301', memberId: 31, storeId: 'A001', sellerEmployeeId: 35, principalAmount: 5000, giftAmount: 1500, paymentMethod: 'WECHAT', pointsGiven: 5000, createTime: '2026-09-01 09:40:00', status: 'COMPLETED' },
    { id: 32, orderNo: 'RC20260902302', memberId: 32, storeId: 'A001', sellerEmployeeId: 35, principalAmount: 680, giftAmount: 0, paymentMethod: 'ALIPAY', pointsGiven: 680, createTime: '2026-09-02 11:30:00', status: 'COMPLETED' }
  ],
  consumeOrders: [
    { id: 31, orderNo: 'ORD20260906301', memberId: 31, storeId: 'A001', primaryTechnicianId: 32, cashierEmployeeId: 35, items: [{ productId: 31, productName: '美孚全合成机油小保养套餐', type: 'SERVICE', price: 380, quantity: 1, bomCost: 160 }], totalAmount: 380, couponDiscount: 0, cardDeductPrincipal: 304, cardDeductGift: 76, cashierPaidAmount: 0, paymentMethod: 'OFFLINE', pointsEarned: 380, pointsBurned: 0, createTime: '2026-09-06 15:10:00', status: 'COMPLETED' }
  ],
  timeCards: [
    { id: 31, memberId: 32, skuId: 32, cardName: '精致深层手工洗车 24次超值储值卡', totalTimes: 24, usedTimes: 3, unitPrice: 28.3, expireDate: '2027-09-02' }
  ],
  pointsLedger: [
    { id: 31, memberId: 31, type: 'RECHARGE_GIFT', typeName: '车主大额充值赠积分', pointsDelta: 5000, balanceAfter: 5000, operator: '系统自动', createTime: '2026-09-01 09:40:00' }
  ],
  rewardsLedger: [
    { id: 31, memberId: 31, referredMemberId: 32, reason: '推荐车友办理洗车年卡', rewardDelta: 50, balanceAfter: 50, createTime: '2026-09-02 11:35:00' }
  ],
  expenses: [
    { id: 31, storeId: 'A001', category: 'RENT', categoryName: '房租水电物业', title: '9月份汽修厂房租金', amount: 16000, date: '2026-09-01', handler: '陆国强', note: '华南汽贸园租金结清' }
  ],
  appointments: [
    { id: 31, aptNo: 'APT20260906301', memberId: 31, memberName: '严建军 (粤A·888X2 奔驰E300L)', phone: '13800336601', storeId: 'A001', technicianId: 32, technicianName: '陈明远', productId: 31, productName: '美孚1号全合成机油小保养套餐', date: '2026-09-06', timeSlot: '14:00 - 15:30', status: 'COMPLETED' }
  ]
}

// ------------------------------------------------------------------------------
// 4. 专营零售 (RETAIL)
// ------------------------------------------------------------------------------
export const retailPackage: IndustryPackage = {
  industryCode: 'RETAIL',
  industryName: '专营零售',
  spaceAlias: '展位',
  appendActionAlias: '加购商品',
  defaultFeeName: '精美包装与礼盒费',
  stores: [
    {
      storeId: 'T001',
      storeName: '云缦甄选·现代轻奢生活美学馆 (正佳广场店)',
      address: '广州市天河区天河路228号正佳广场3楼中庭3A018',
      managerName: '周海峰',
      phone: '020-88996611',
      isHeadquarter: true,
      businessStatus: 'OPEN',
      totalSpaces: 6,
      openTime: '10:00 - 22:00'
    },
    {
      storeId: 'T002',
      storeName: '云缦甄选·日韩进口零食美妆快闪店',
      address: '广州市越秀区北京路步行街名盛广场1楼中庭',
      managerName: '吴丽丽',
      phone: '020-88996622',
      isHeadquarter: false,
      businessStatus: 'OPEN',
      totalSpaces: 4,
      openTime: '10:00 - 22:30'
    }
  ],
  staff: [
    {
      id: 41,
      storeId: 'T001',
      realName: '周海峰',
      phone: '13988771122',
      postName: '零售运营总监/店长',
      role: 'STORE_MANAGER',
      department: '店务管理部',
      baseSalary: 7500,
      serviceCommissionRate: 0.05,
      cardCommissionRate: 0.05,
      retailCommissionRate: 0.05,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2024-12-01'
    },
    {
      id: 42,
      storeId: 'T001',
      realName: '吴丽丽',
      phone: '13877662233',
      postName: '资深奢侈品/选品顾问',
      role: 'TECHNICIAN',
      department: '零售销售部',
      baseSalary: 4200,
      serviceCommissionRate: 0.10,
      cardCommissionRate: 0.08,
      retailCommissionRate: 0.12,
      gender: 'FEMALE',
      status: 'ACTIVE',
      entryDate: '2025-02-10'
    },
    {
      id: 43,
      storeId: 'T001',
      realName: '郑敏',
      phone: '13766553344',
      postName: '陈列设计师/收银领班',
      role: 'CASHIER',
      department: '前台收银部',
      baseSalary: 3800,
      serviceCommissionRate: 0.05,
      cardCommissionRate: 0.05,
      retailCommissionRate: 0.08,
      gender: 'FEMALE',
      status: 'ACTIVE',
      entryDate: '2025-03-15'
    },
    {
      id: 44,
      storeId: 'T001',
      realName: '黄子豪',
      phone: '13655442211',
      postName: '智能仓库理货质检员',
      role: 'TECHNICIAN',
      department: '智能仓储部',
      baseSalary: 3500,
      serviceCommissionRate: 0.02,
      cardCommissionRate: 0.02,
      retailCommissionRate: 0.03,
      gender: 'MALE',
      status: 'ACTIVE',
      entryDate: '2025-05-20'
    }
  ],
  products: [
    { id: 41, code: 'RET-001', name: '埃塞俄比亚耶加雪菲日晒精品原装咖啡豆 500g', type: 'RETAIL', category: 'COFFEE_TEA', categoryName: '精品咖啡茗茶', price: 168, cost: 78, unit: '包', spec: '500g 充氮包装' },
    { id: 42, code: 'RET-002', name: '沙龙小众冷杉雪松木质调无火香薰礼盒', type: 'RETAIL', category: 'LIFESTYLE', categoryName: '家居生活美学', price: 298, cost: 120, unit: '套', spec: '200ml 含藤条' },
    { id: 43, code: 'RET-003', name: '北欧极简手作耐热双层玻璃品茗杯', type: 'RETAIL', category: 'CUP_WARE', categoryName: '工艺器皿生活', price: 128, cost: 45, unit: '对', spec: '双只精装礼盒' },
    { id: 44, code: 'RET-004', name: '高山冷萃有机原叶白毫银针礼盒 100g', type: 'RETAIL', category: 'COFFEE_TEA', categoryName: '精品咖啡茗茶', price: 198, cost: 80, unit: '盒', spec: '100g 木盒' },
    { id: 45, code: 'RET-005', name: '阿尔卑斯天然冰川低钠含气矿泉水 6瓶装', type: 'RETAIL', category: 'BEVERAGE', categoryName: '进口轻奢饮品', price: 58, cost: 24, unit: '提', spec: '330ml × 6' },
    { id: 46, code: 'RET-006', name: '比利时手工72%黑巧纯可可脂排块', type: 'RETAIL', category: 'SNACKS', categoryName: '进口轻奢零食', price: 88, cost: 35, unit: '盒', spec: '200g 精装' }
  ],
  materials: [
    { id: 'MAT-T01', code: 'MAT-BEAN-01', name: '耶加雪菲原产地精品生豆 (烘焙备货)', category: 'RETAIL', unit: '包', costPrice: 78, initialStock: 60, safeStock: 15, supplier: '非洲精品咖啡生豆进口联盟' },
    { id: 'MAT-T02', code: 'MAT-AROMA-01', name: '法式调香植物天然扩香精油原料', category: 'RETAIL', unit: '套', costPrice: 120, initialStock: 40, safeStock: 10, supplier: '格拉斯香氛实验室' }
  ],
  members: [
    { id: 41, memberNo: 'LS880001', name: '薛梦瑶', phone: '13800449901', gender: 'FEMALE', level: 'DIAMOND', levelName: '黑钻VIP鉴赏家', registeredStoreId: 'T001', registerTime: '2026-09-01 15:20:00' },
    { id: 42, memberNo: 'FD880002', name: '陆文彬', phone: '13911669988', gender: 'MALE', level: 'GOLD', levelName: '金卡鉴赏家', registeredStoreId: 'T001', referrerId: 41, registerTime: '2026-09-02 16:40:00' }
  ],
  cardTemplates: [
    { id: 401, cardType: 'STORED_VALUE', cardTypeName: '储值卡', cardName: '1000元新潮品鉴储值卡', price: 1000, originalPrice: 1200, principalAmount: 1000, giftAmount: 200, discountRate: 0.90, contentDescription: '充值￥1000赠￥200，全场正价商品9折特权', validityDays: 365, themeColor: 'gold', status: 'ACTIVE', notes: '全店好物通用，新品优先预订' },
    { id: 402, cardType: 'TIME_CARD', cardTypeName: '次卡', cardName: '精品手冲咖啡豆 10次提货兑换卡', price: 480, originalPrice: 680, totalTimes: 10, serviceSkuName: '埃塞俄比亚耶加雪菲精品咖啡豆 500g', contentDescription: '可提货兑换精品咖啡豆或原叶茶礼盒10次', validityDays: 180, themeColor: 'emerald', status: 'ACTIVE', notes: '品质生活高频好物' },
    { id: 403, cardType: 'BENEFIT_CARD', cardTypeName: '权益卡', cardName: '优选黑金终身荣誉会员年卡', price: 699, originalPrice: 1580, contentDescription: '每月免费到店领取一份时令好礼（价值￥98），专属顺丰包邮特权', validityDays: 365, themeColor: 'black', status: 'ACTIVE', notes: '尊贵VIP高阶礼遇' },
    { id: 404, cardType: 'BLIND_BOX_CARD', cardTypeName: '盲盒卡', cardName: '潮流好物惊喜盲盒 5抽权益卡', price: 199, originalPrice: 350, contentDescription: '享受5次限量潮流手办及小众香氛盲盒抽取机会', validityDays: 90, themeColor: 'purple', status: 'ACTIVE' }
  ],
  liveSessions: [
    { id: 31, spaceId: 301, spaceName: '前台收银结算 1号展位', sessionNo: 'SES20260906301', customerName: '薛梦瑶', customerPhone: '13800449901', memberId: 41, startTime: '2026-09-06 15:30:00', totalAmount: 466, status: 'SERVING', items: [{ name: '耶加雪菲精品咖啡豆 500g', price: 168, qty: 1 }, { name: '沙龙木质调扩香礼盒', price: 298, qty: 1 }] }
  ],
  baseCosts: [
    { id: 401, code: 'CST-T-001', name: '北京路商业街首层核心旺铺月度租金', category: 'RENT_UTILITY', categoryName: '店面房租能耗', nature: 'FIXED', amount: 24000, month: '2026-09', date: '2026-09-01', storeId: 'T001', handler: '周海峰', invoiceNo: 'RNT-T202609', notes: '顶级商圈临街旺铺月租金' },
    { id: 402, code: 'CST-T-002', name: '进口精品百货与咖啡香氛供应链采购款', category: 'MATERIAL', categoryName: '物料耗材成本', nature: 'VARIABLE', amount: 16500, month: '2026-09', date: '2026-09-03', storeId: 'T001', handler: '黄子豪', invoiceNo: 'SUP-202609', notes: '首批高频零售爆品采购备货' },
    { id: 403, code: 'CST-T-003', name: '全景艺术射灯与全天候恒温空调电费', category: 'RENT_UTILITY', categoryName: '店面房租能耗', nature: 'VARIABLE', amount: 3500, month: '2026-09', date: '2026-09-06', storeId: 'T001', handler: '郑敏', invoiceNo: 'PWR-T-202609', notes: '高格调展陈灯光与冷气能耗' },
    { id: 404, code: 'CST-T-004', name: '小红书探店达人与抖音本地生活种草推广', category: 'MARKETING', categoryName: '营销获客成本', nature: 'VARIABLE', amount: 4200, month: '2026-09', date: '2026-09-02', storeId: 'T001', handler: '吴丽丽', invoiceNo: 'MKT-XHS-09', notes: '本地潮流达人探店视频推广' },
    { id: 405, code: 'CST-T-005', name: '定制实木艺术展柜与条码收银POS设备折旧', category: 'DEPRECIATION', categoryName: '设备资产折旧', nature: 'FIXED', amount: 2200, month: '2026-09', date: '2026-09-01', storeId: 'T001', handler: '周海峰', invoiceNo: 'DEP-POS-09', notes: '精品展架与收银硬件分摊' },
    { id: 406, code: 'CST-T-006', name: '高端环保牛皮纸礼袋与气泡缓震包材', category: 'ADMIN_MISC', categoryName: '日常运营杂费', nature: 'FIXED', amount: 1300, month: '2026-09', date: '2026-09-05', storeId: 'T001', handler: '郑敏', invoiceNo: 'PKG-T-09', notes: '定制品牌伴手礼盒与环保包装' }
  ],
  rechargeOrders: [
    { id: 41, orderNo: 'RC20260901401', memberId: 41, storeId: 'T001', sellerEmployeeId: 42, principalAmount: 1000, giftAmount: 200, paymentMethod: 'WECHAT', pointsGiven: 1000, createTime: '2026-09-01 15:25:00', status: 'COMPLETED' }
  ],
  consumeOrders: [
    { id: 41, orderNo: 'ORD20260906401', memberId: 41, storeId: 'T001', primaryTechnicianId: 42, cashierEmployeeId: 43, items: [{ productId: 41, productName: '埃塞俄比亚耶加雪菲精品原装咖啡豆 500g', type: 'RETAIL', price: 168, quantity: 1, bomCost: 78 }, { productId: 42, productName: '沙龙小众木质调扩香礼盒', type: 'RETAIL', price: 298, quantity: 1, bomCost: 120 }], totalAmount: 466, couponDiscount: 0, cardDeductPrincipal: 388, cardDeductGift: 78, cashierPaidAmount: 0, paymentMethod: 'OFFLINE', pointsEarned: 466, pointsBurned: 0, createTime: '2026-09-06 16:10:00', status: 'COMPLETED' }
  ],
  timeCards: [
    { id: 41, memberId: 41, skuId: 42, cardName: '精品手冲咖啡豆 10次提货兑换卡', totalTimes: 10, usedTimes: 1, unitPrice: 48, expireDate: '2027-03-01' }
  ],
  pointsLedger: [
    { id: 41, memberId: 41, type: 'RECHARGE_GIFT', typeName: '精品专营储值赠积分', pointsDelta: 1000, balanceAfter: 1000, operator: '系统自动', createTime: '2026-09-01 15:25:00' }
  ],
  rewardsLedger: [
    { id: 41, memberId: 41, referredMemberId: 42, reason: '推荐好友购买黑金卡', rewardDelta: 50, balanceAfter: 50, createTime: '2026-09-02 16:45:00' }
  ],
  expenses: [
    { id: 41, storeId: 'T001', category: 'RENT', categoryName: '房租水电物业', title: '9月份北京路临街商铺租金', amount: 24000, date: '2026-09-01', handler: '周海峰', note: '旗舰店租金结清' }
  ],
  appointments: [
    { id: 41, aptNo: 'APT20260906401', memberId: 41, memberName: '薛梦瑶', phone: '13800449901', storeId: 'T001', technicianId: 42, technicianName: '吴丽丽', productId: 42, productName: '沙龙小众木质调无火香薰礼盒', date: '2026-09-06', timeSlot: '15:30 - 16:30', status: 'COMPLETED' }
  ]
}

export const allIndustryPackages: Record<string, IndustryPackage> = {
  BEAUTY: beautyPackage,
  RESTAURANT: restaurantPackage,
  AUTO: autoPackage,
  RETAIL: retailPackage
}
