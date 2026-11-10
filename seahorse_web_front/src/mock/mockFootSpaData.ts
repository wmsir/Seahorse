/**
 * 御境云足 · 东方养生泰式SPA连锁会所
 * 真实足疗按摩业务场景全套模拟数据集与一键加载服务
 */

export interface FootSpaStore {
  storeId: string
  storeName: string
  address: string
  phone: string
  openTime: string
  isHeadquarter: boolean
  industry: string
  industryCategoryName: string
  areaM2: number
  managerName: string
}

export const mockFootSpaStores: FootSpaStore[] = [
  {
    storeId: 'S_FOOT_01',
    storeName: '御境云足·旗舰尊享会所 (天府环球店)',
    address: '成都市高新区天府大道北段1199号新世纪环球中心E2座3层',
    phone: '028-85338899',
    openTime: '11:00 - 次日02:00',
    isHeadquarter: true,
    industry: 'BEAUTY',
    industryCategoryName: '足疗推拿SPA',
    areaM2: 860,
    managerName: '魏店长 (行政总店长)'
  },
  {
    storeId: 'S_FOOT_02',
    storeName: '御境云足·轻奢养生坊 (万象城店)',
    address: '成都市成华区双庆路8号华润万象城二期4楼408',
    phone: '028-84226688',
    openTime: '11:30 - 次日01:30',
    isHeadquarter: false,
    industry: 'BEAUTY',
    industryCategoryName: '足疗推拿SPA',
    areaM2: 450,
    managerName: '徐主管'
  },
  {
    storeId: 'S_FOOT_03',
    storeName: '御境云足·国风推拿馆 (交子金融城店)',
    address: '成都市武侯区交子大道288号中海环宇荟2层206',
    phone: '028-86995566',
    openTime: '11:00 - 次日02:00',
    isHeadquarter: false,
    industry: 'BEAUTY',
    industryCategoryName: '足疗推拿SPA',
    areaM2: 580,
    managerName: '沈副店长'
  }
]

export const mockFootSpaStaff = [
  {
    id: 101,
    realName: '魏舒兰 (魏店长)',
    phone: '13880019988',
    accountUsername: '13880019988',
    accountPassword: '123456',
    postName: '行政总店长',
    role: 'STORE_MANAGER',
    gender: '女',
    baseSalary: 9500,
    serviceCommissionRate: 0.10,
    status: 'ACTIVE',
    hasSystemAccount: true,
    accountStatus: 'ENABLED',
    canCrossStore: true, // 总店长具有跨店统筹管理权限
    allowedStoreIds: ['S_FOOT_01', 'S_FOOT_02', 'S_FOOT_03'],
    allowedMenuPaths: [
      '/dashboard', '/rooms', '/products', '/card-template', '/members',
      '/staff-management', '/appointments', '/chain', '/sms-records',
      '/expenses', '/inventory', '/reports', '/regulations', '/settings', '/profile'
    ],
    techNo: '001',
    rank: '总店长'
  },
  {
    id: 102,
    realName: '梓涵 (88号技师)',
    phone: '13980888801',
    accountUsername: '13980888801',
    accountPassword: '123456',
    postName: '首席金牌泰式SPA技师',
    role: 'TECHNICIAN',
    gender: '女',
    baseSalary: 6000,
    serviceCommissionRate: 0.35,
    status: 'ACTIVE',
    hasSystemAccount: true,
    accountStatus: 'ENABLED',
    canCrossStore: false, // 无跨店权限：严格限制仅天府环球总店
    allowedStoreIds: ['S_FOOT_01'],
    allowedMenuPaths: ['/dashboard', '/rooms', '/appointments', '/regulations', '/profile'],
    techNo: '88号',
    rank: '首席技师',
    orderCount: 142,
    rating: 4.98
  },
  {
    id: 103,
    realName: '子轩 (66号技师)',
    phone: '13980666602',
    accountUsername: '13980666602',
    accountPassword: '123456',
    postName: '特级古法经络推拿师',
    role: 'TECHNICIAN',
    gender: '男',
    baseSalary: 5500,
    serviceCommissionRate: 0.32,
    status: 'ACTIVE',
    hasSystemAccount: true,
    accountStatus: 'ENABLED',
    canCrossStore: false, // 兼任天府店与金融城店
    allowedStoreIds: ['S_FOOT_01', 'S_FOOT_03'],
    allowedMenuPaths: ['/dashboard', '/rooms', '/appointments', '/regulations', '/profile'],
    techNo: '66号',
    rank: '特级推拿师',
    orderCount: 128,
    rating: 4.95
  },
  {
    id: 104,
    realName: '曼妮 (18号技师)',
    phone: '13980181803',
    accountUsername: '13980181803',
    accountPassword: '123456',
    postName: '高级非遗采耳SPA技师',
    role: 'TECHNICIAN',
    gender: '女',
    baseSalary: 5000,
    serviceCommissionRate: 0.30,
    status: 'ACTIVE',
    hasSystemAccount: true,
    accountStatus: 'ENABLED',
    canCrossStore: false,
    allowedStoreIds: ['S_FOOT_01'],
    allowedMenuPaths: ['/dashboard', '/rooms', '/appointments', '/regulations', '/profile'],
    techNo: '18号',
    rank: '高级技师',
    orderCount: 115,
    rating: 4.92
  },
  {
    id: 105,
    realName: '文博 (09号技师)',
    phone: '13980090904',
    accountUsername: '13980090904',
    accountPassword: '123456',
    postName: '资深中药草本足道调理师',
    role: 'TECHNICIAN',
    gender: '男',
    baseSalary: 4800,
    serviceCommissionRate: 0.28,
    status: 'ACTIVE',
    hasSystemAccount: true,
    accountStatus: 'ENABLED',
    canCrossStore: false,
    allowedStoreIds: ['S_FOOT_02'],
    allowedMenuPaths: ['/dashboard', '/rooms', '/appointments', '/regulations', '/profile'],
    techNo: '09号',
    rank: '资深调理师',
    orderCount: 98,
    rating: 4.88
  },
  {
    id: 106,
    realName: '诗涵 (28号技师)',
    phone: '13980282805',
    accountUsername: '13980282805',
    accountPassword: '123456',
    postName: '养生调理顾问/推拿技师',
    role: 'TECHNICIAN',
    gender: '女',
    baseSalary: 5200,
    serviceCommissionRate: 0.30,
    status: 'ACTIVE',
    hasSystemAccount: true,
    accountStatus: 'ENABLED',
    canCrossStore: false,
    allowedStoreIds: ['S_FOOT_01', 'S_FOOT_02'],
    allowedMenuPaths: ['/dashboard', '/rooms', '/appointments', '/regulations', '/profile'],
    techNo: '28号',
    rank: '金牌技师',
    orderCount: 109,
    rating: 4.91
  },
  {
    id: 107,
    realName: '小雨 (01号前台收银)',
    phone: '13880010106',
    accountUsername: '13880010106',
    accountPassword: '123456',
    postName: '前台大堂接待兼收银',
    role: 'CASHIER',
    gender: '女',
    baseSalary: 4500,
    serviceCommissionRate: 0.05,
    status: 'ACTIVE',
    hasSystemAccount: true,
    accountStatus: 'ENABLED',
    canCrossStore: false,
    allowedStoreIds: ['S_FOOT_01'],
    allowedMenuPaths: [
      '/dashboard', '/cashier', '/rooms', '/members', '/products',
      '/card-template', '/appointments', '/shift', '/regulations', '/profile'
    ],
    techNo: '01号',
    rank: '星级收银'
  }
]

export const mockFootSpaProducts = [
  {
    id: 301,
    name: '御境经典中药草本足道 (70分钟)',
    category: '足道调理',
    price: 198,
    memberPrice: 158,
    costPrice: 35,
    durationMinutes: 70,
    unit: '次',
    stock: 9999,
    type: 'SERVICE',
    description: '古法瑶浴泡足、足底穴位深度反射区按摩、小腿舒缓推油、热敷包草本温灸。',
    commissionAmount: 60
  },
  {
    id: 302,
    name: '古法经络通络推拿 (60分钟)',
    category: '经络推拿',
    price: 238,
    memberPrice: 188,
    costPrice: 42,
    durationMinutes: 60,
    unit: '次',
    stock: 9999,
    type: 'SERVICE',
    description: '针对久坐肩颈僵硬、腰背酸胀，纯手工循经走穴，松解粘连肌群，行气活血。',
    commissionAmount: 76
  },
  {
    id: 303,
    name: '泰式皇家草本精油芳疗SPA (90分钟)',
    category: '泰式芳疗',
    price: 398,
    memberPrice: 298,
    costPrice: 65,
    durationMinutes: 90,
    unit: '次',
    stock: 9999,
    type: 'SERVICE',
    description: '进口大马士革玫瑰与薰衣草复方精油，泰式传统拉伸手法与背部精油深层排毒。',
    commissionAmount: 120
  },
  {
    id: 304,
    name: '非遗汉唐可视采耳与头部安神 (45分钟)',
    category: '采耳养生',
    price: 138,
    memberPrice: 99,
    costPrice: 22,
    durationMinutes: 45,
    unit: '次',
    stock: 9999,
    type: 'SERVICE',
    description: '高精可视内窥耳勺清理耳道，孔雀羽毛拂面、音叉共振颅内高潮、舒缓安神头疗。',
    commissionAmount: 42
  },
  {
    id: 305,
    name: '沉香艾灸背部温阳排湿理疗 (45分钟)',
    category: '特色理疗',
    price: 168,
    memberPrice: 128,
    costPrice: 28,
    durationMinutes: 45,
    unit: '次',
    stock: 9999,
    type: 'SERVICE',
    description: '五年陈蕲春艾条温灸督脉，驱寒逐湿，改善手脚冰凉与宫寒体虚。',
    commissionAmount: 50
  },
  {
    id: 306,
    name: '御境尊享·全身深度舒压SPA全套 (100分钟)',
    category: '尊享全套',
    price: 468,
    memberPrice: 368,
    costPrice: 85,
    durationMinutes: 100,
    unit: '次',
    stock: 9999,
    type: 'SERVICE',
    description: '草本沐足 + 经络推拿 + 芳疗精油开背 + 头部安神拨筋全流程尊贵呵护。',
    commissionAmount: 150
  },
  {
    id: 307,
    name: '正骨整脊调理与肩颈深度解压 (50分钟)',
    category: '经络推拿',
    price: 218,
    memberPrice: 168,
    costPrice: 38,
    durationMinutes: 50,
    unit: '次',
    stock: 9999,
    type: 'SERVICE',
    description: '特级推拿大师亲诊，胸椎腰椎微调，缓解神经压迫与不良体态。',
    commissionAmount: 70
  },
  {
    id: 308,
    name: '御境自研·草本蕲艾精油礼盒 (50ml*2)',
    category: '外卖精油',
    price: 298,
    memberPrice: 238,
    costPrice: 78,
    durationMinutes: 0,
    unit: '盒',
    stock: 68,
    type: 'PRODUCT',
    description: '居家刮痧推油专用，透皮吸收快，通络发热排寒。',
    commissionAmount: 45
  },
  {
    id: 309,
    name: '瑶族古方本草足浴包 (30袋精装)',
    category: '养生耗材',
    price: 128,
    memberPrice: 99,
    costPrice: 32,
    durationMinutes: 0,
    unit: '袋',
    stock: 120,
    type: 'PRODUCT',
    description: '含红花、艾叶、老姜、川穹纯草本粉碎配方，家庭日常泡脚必备。',
    commissionAmount: 20
  }
]

export const mockFootSpaRooms = [
  {
    id: 'R_01',
    name: '静心阁 · 豪华双人足道包厢',
    spaceName: '静心阁 · 豪华双人足道包厢',
    spaceCode: 'V801',
    roomNo: 'V801',
    type: 'FOOT_SPA_DOUBLE',
    bedCount: 2,
    floor: '3层 A区',
    status: 'IN_USE',
    pricePerHour: 198,
    features: ['4K智能巨幕投影', '头等舱电动按摩椅', '功夫茶台', '新风静音'],
    currentCustomer: '张总 (2人同约)',
    technician: '88号·梓涵 / 66号·子轩',
    service: '经典草本足道',
    startTime: '19:30',
    remainMinutes: 35
  },
  {
    id: 'R_02',
    name: '养颐轩 · 三人泰式SPA套房',
    spaceName: '养颐轩 · 三人泰式SPA套房',
    spaceCode: 'V802',
    roomNo: 'V802',
    type: 'SPA_SUITE',
    bedCount: 3,
    floor: '3层 B区',
    status: 'AVAILABLE',
    pricePerHour: 298,
    features: ['独立干湿分离卫浴', '泰式实木SPA床', '法国香薰仪', '欢迎水果茶点'],
    currentCustomer: '',
    technician: '',
    service: '',
    startTime: '',
    remainMinutes: 0
  },
  {
    id: 'R_03',
    name: '禅意居 · 单人私密VIP包厢',
    spaceName: '禅意居 · 单人私密VIP包厢',
    spaceCode: 'V803',
    roomNo: 'V803',
    type: 'VIP_SINGLE',
    bedCount: 1,
    floor: '3层 C区',
    status: 'RESERVED',
    pricePerHour: 238,
    features: ['梦幻星空顶', '专属独立卫浴', '高保真丹拿音响', '高定乳胶床垫'],
    currentCustomer: '李女士 (预约中)',
    technician: '18号·曼妮',
    service: '非遗可视采耳+头部安神',
    startTime: '20:30',
    remainMinutes: 0
  },
  {
    id: 'R_04',
    name: '听泉堂 · 四人挚友足道棋牌厅',
    spaceName: '听泉堂 · 四人挚友足道棋牌厅',
    spaceCode: 'V805',
    roomNo: 'V805',
    type: 'ENTERTAINMENT_SPA',
    bedCount: 4,
    floor: '3层 D区',
    status: 'IN_USE',
    pricePerHour: 368,
    features: ['智能静音麻将机', '4座影音足道沙发', '独立卫生间', '精选现磨咖啡'],
    currentCustomer: '王总等4位贵宾',
    technician: '28号·诗涵 / 09号·文博等',
    service: '经典草本足道+背部艾灸',
    startTime: '18:45',
    remainMinutes: 50
  }
]

export const mockFootSpaCards = [
  {
    id: 'CARD_GOLD',
    name: '御境养生·尊贵金卡',
    cardType: 'STORED_VALUE',
    rechargeAmount: 2000,
    giftAmount: 400,
    discountRate: 0.85,
    validDays: 730,
    bgGradient: 'linear-gradient(135deg, #b45309 0%, #f59e0b 100%)',
    description: '充￥2000送￥400，全场足道/推拿/SPA享8.5折，生日送免单项目1次。'
  },
  {
    id: 'CARD_BLACK_GOLD',
    name: '御境云足·黑金尊享卡',
    cardType: 'STORED_VALUE',
    rechargeAmount: 5000,
    giftAmount: 1200,
    discountRate: 0.75,
    validDays: 1095,
    bgGradient: 'linear-gradient(135deg, #0f172a 0%, #334155 100%)',
    description: '充￥5000送￥1200，全场享7.5折，尊享VIP包间免费升级，赠送高档草本精油礼盒。'
  },
  {
    id: 'CARD_TIMES_FOOT',
    name: '御境经典中药足道10次次卡',
    cardType: 'TIMES',
    rechargeAmount: 1380,
    giftAmount: 0,
    totalTimes: 10,
    validDays: 365,
    bgGradient: 'linear-gradient(135deg, #047857 0%, #10b981 100%)',
    description: '单次仅需￥138 (原价￥198)，含瑶浴草本泡脚、全套穴位推拿，无额外加价。'
  }
]

export const mockFootSpaAppointments: any[] = []

/**
 * 一键将足疗推拿养生会所全套数据注入至系统状态与缓存
 */
export function injectFootSpaMockData(systemData: any, storeConfig?: any) {
  // 1. 设置门店配置
  if (storeConfig) {
    storeConfig.tenantName = '御境云足·东方养生连锁管理集团'
    storeConfig.storeName = mockFootSpaStores[0].storeName
    storeConfig.currentStoreId = mockFootSpaStores[0].storeId
    storeConfig.stores = [...mockFootSpaStores]
    storeConfig.industry = 'BEAUTY'
    storeConfig.industryCategoryName = '足疗推拿SPA'
  }

  // 2. 注入门店与行业数据到 systemData
  if (systemData) {
    systemData.currentIndustry = 'BEAUTY'
    systemData.stores = [...mockFootSpaStores]
    systemData.staff = [...mockFootSpaStaff]
    systemData.products = [...mockFootSpaProducts]
    systemData.spaces = [...mockFootSpaRooms]
  }

  // 3. 持久化存储
  localStorage.setItem('seahorse_tenant_name', storeConfig.tenantName)
  localStorage.setItem('seahorse_store_name', storeConfig.storeName)
  localStorage.setItem('seahorse_store_id', storeConfig.currentStoreId)
  localStorage.setItem('seahorse_stores_data', JSON.stringify(mockFootSpaStores))
  localStorage.setItem('seahorse_staff_data', JSON.stringify(mockFootSpaStaff))
  localStorage.setItem('seahorse_products_data', JSON.stringify(mockFootSpaProducts))
  localStorage.setItem('seahorse_rooms_data', JSON.stringify(mockFootSpaRooms))
  localStorage.removeItem('seahorse_appointments_data')
  localStorage.setItem('seahorse_industry_category', '足疗推拿SPA')

  return true
}
