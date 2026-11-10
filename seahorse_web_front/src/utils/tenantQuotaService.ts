/**
 * 租户存储空间与接口操作频次阶梯量化计费服务 (Tenant Quota & Billing Service)
 * 支持两大核心商业模式：
 * 1. 包年订阅阶梯模式 (Annual Subscription Tiers)
 * 2. 永久免费 + 流量包/存储计费模式 (Freemium + Pay-as-you-go Quota / Storage Packs)
 * 并实现超额登录锁定、页面拦截与即时充值解封机制。
 */

export type BillingMode = 'ANNUAL_TIER' | 'PAY_AS_YOU_GO'

export interface QuotaTierInfo {
  tierLevel: number
  tierName: string
  applicableScale: string
  apiCallsRange: string
  apiCallsMax: number
  storageRange: string
  storageMaxMb: number
  billingRule: string
  recommendedPack: string
  merchantsCount: number
}

export interface RechargeRecord {
  id: string
  time: string
  type: 'STORAGE' | 'API_CALLS' | 'ANNUAL_UPGRADE'
  packName: string
  amount: number
  addedStorageMb: number
  addedApiCalls: number
  operator: string
}

export interface TenantQuotaData {
  tenantId: string
  tenantName: string
  billingMode: BillingMode
  planCode: string
  planName: string
  totalStorageMb: number
  usedStorageMb: number
  totalApiCalls: number
  usedApiCalls: number
  isLocked: boolean
  lockReason: string
  lockedAt: string | null
  lastRechargeTime: string | null
  rechargeHistory: RechargeRecord[]
  // 兼容别名与兜底字段，彻底杜绝模板访问时产生 NaN
  storageUsedMb?: number
  storageQuotaMb?: number
  apiCallsMonthly?: number
}

const QUOTA_STORAGE_PREFIX = 'seahorse_quota_tenant_'
const ALL_TENANTS_KEY = 'seahorse_all_tenants_quota_list'

// 4 大接口操作与存储计算阶梯基准表
export const QUOTA_TIER_STANDARDS: QuotaTierInfo[] = [
  {
    tierLevel: 1,
    tierName: '萌芽初创梯队 (基础免费免额)',
    applicableScale: '初创单店 (月均 100~300 笔订单)',
    apiCallsRange: '0 ~ 20,000 次操作/月',
    apiCallsMax: 20000,
    storageRange: '≤ 500 MB',
    storageMaxMb: 500,
    billingRule: '永久免费赠送 (0元/年)',
    recommendedPack: '系统初始免费额度 (无需付费)',
    merchantsCount: 0
  },
  {
    tierLevel: 2,
    tierName: '稳健发展梯队 (精益单店/双店)',
    applicableScale: '客流稳定店 (月均 800~1,500 笔订单)',
    apiCallsRange: '20,001 ~ 100,000 次操作/月',
    apiCallsMax: 100000,
    storageRange: '500 MB ~ 10 GB',
    storageMaxMb: 10240,
    billingRule: '10GB 存储包 ￥29/月 或 ￥298/年',
    recommendedPack: '10GB 云存储加速包 + 5万次接口流量包',
    merchantsCount: 0
  },
  {
    tierLevel: 3,
    tierName: '繁忙扩张梯队 (精品连锁 3-5店)',
    applicableScale: '多店连锁体系 (月均 3,000~8,000 笔订单)',
    apiCallsRange: '100,001 ~ 500,000 次操作/月',
    apiCallsMax: 500000,
    storageRange: '10 GB ~ 50 GB',
    storageMaxMb: 51200,
    billingRule: '50GB 存储包 ￥99/月 或 ￥990/年',
    recommendedPack: '50GB 高速存储包 + 20万次高频接口包',
    merchantsCount: 0
  },
  {
    tierLevel: 4,
    tierName: '旗舰矩阵梯队 (大型连锁 / 集团大区)',
    applicableScale: '连锁品牌总仓 (月均 10,000+ 笔订单)',
    apiCallsRange: '> 500,000 次操作/月 (海量并发)',
    apiCallsMax: 2000000,
    storageRange: '50 GB ~ 200 GB+',
    storageMaxMb: 204800,
    billingRule: '包年旗舰 ￥4,980/年 或 定制企业级',
    recommendedPack: '旗舰版包年套餐 (全功能不限单次流量)',
    merchantsCount: 0
  }
]

export interface StoragePackItem {
  id: string
  name: string
  badge: string
  price: number
  period: string
  storageMb: number
  desc: string
  status?: 'ACTIVE' | 'PAUSED'
}

export interface ApiPackItem {
  id: string
  name: string
  badge: string
  price: number
  period?: string
  calls: number
  desc: string
  status?: 'ACTIVE' | 'PAUSED'
}

export interface SmsPackItem {
  id: string
  name: string
  badge: string
  price: number
  count: number
  unitPrice?: string
  desc: string
  status?: 'ACTIVE' | 'PAUSED'
}

export interface RechargePackagesConfig {
  storagePacks: StoragePackItem[]
  apiPacks: ApiPackItem[]
  smsPacks: SmsPackItem[]
  annualUpgrades: any[]
}

// 基础默认扩容加油包
export const DEFAULT_RECHARGE_PACKAGES: RechargePackagesConfig = {
  storagePacks: [
    {
      id: 'store_10g',
      name: '10GB 云端存储扩容月包',
      badge: '灵活入门',
      price: 29,
      period: '月',
      storageMb: 10240,
      desc: '约可额外存储 2,500 张高清服务客照/电子账单凭证',
      status: 'ACTIVE'
    },
    {
      id: 'store_50g',
      name: '50GB 高速存储超值季包',
      badge: '热销推荐',
      price: 99,
      period: '季',
      storageMb: 51200,
      desc: '约可存储 15,000 张客照与会员体征记忆多媒体附件',
      status: 'ACTIVE'
    },
    {
      id: 'store_100g_year',
      name: '100GB 海量存储旗舰年包',
      badge: '连锁优选',
      price: 398,
      period: '年',
      storageMb: 102400,
      desc: '专线高可用对象存储，全年免担心容量预警超额',
      status: 'ACTIVE'
    }
  ],
  apiPacks: [
    {
      id: 'api_50k',
      name: '50,000 次接口操作流量加油包',
      badge: '即充即用',
      price: 39,
      calls: 50000,
      desc: '可支撑约 3,500 次开单收银与会员核销请求',
      status: 'ACTIVE'
    },
    {
      id: 'api_200k',
      name: '200,000 次高频业务操作包',
      badge: '性价比之王',
      price: 129,
      calls: 200000,
      desc: '充沛算力保障，覆盖高峰期大量扫码与排队并发',
      status: 'ACTIVE'
    },
    {
      id: 'api_1000k',
      name: '1,000,000 次超大流量包',
      badge: '大促无忧',
      price: 499,
      calls: 1000000,
      desc: '适合节假日大促、全员营销与裂变拓客高频使用',
      status: 'ACTIVE'
    }
  ],
  smsPacks: [
    {
      id: 'sms_50',
      name: '50元短信包 (基础小包)',
      badge: '灵活尝鲜',
      price: 50,
      count: 500,
      unitPrice: '0.100',
      desc: '适合初创单店日常验证码与小量动账',
      status: 'ACTIVE'
    },
    {
      id: 'sms_100',
      name: '100元短信包 (精选推荐)',
      badge: '热销爆款',
      price: 100,
      count: 1250,
      unitPrice: '0.080',
      desc: '高性价比，适合客流稳定门店月度消费动账与会员通知',
      status: 'ACTIVE'
    },
    {
      id: 'sms_300',
      name: '300元短信包 (进阶超值)',
      badge: '超值性价比',
      price: 300,
      count: 4285,
      unitPrice: '0.070',
      desc: '多店连锁首选，支持高并发短信与预约通知',
      status: 'ACTIVE'
    },
    {
      id: 'sms_500',
      name: '500元短信包 (海量大促)',
      badge: '大促无忧',
      price: 500,
      count: 10000,
      unitPrice: '0.050',
      desc: '大促营销群发与沉睡会员激活专用，资费最划算',
      status: 'ACTIVE'
    }
  ],
  annualUpgrades: [
    {
      id: 'plan_standard_annual',
      code: 'STANDARD',
      name: '标准专业版 (包年无限单次流量)',
      price: 2980,
      storageMb: 20480,
      calls: 1000000,
      desc: '赠送 20GB 专属存储 + 百万级操作，不再按单次买包'
    },
    {
      id: 'plan_flagship_annual',
      code: 'FLAGSHIP',
      name: '旗舰连锁版 (包年不限量)',
      price: 4980,
      storageMb: 102400,
      calls: 5000000,
      desc: '赠送 100GB 旗舰专属存储 + 跨店调度，专属顾问保障'
    }
  ]
}

const STORAGE_KEY_RECHARGE_PACKAGES = 'seahorse_recharge_packages_v2'

// 读取扩容加油包配置 (带 localStorage 本地持久化)
export const getRechargePackagesList = (): RechargePackagesConfig => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY_RECHARGE_PACKAGES)
    if (raw) {
      const parsed = JSON.parse(raw)
      if (parsed && Array.isArray(parsed.storagePacks) && Array.isArray(parsed.apiPacks)) {
        if (!Array.isArray(parsed.smsPacks) || parsed.smsPacks.length === 0) {
          parsed.smsPacks = JSON.parse(JSON.stringify(DEFAULT_RECHARGE_PACKAGES.smsPacks))
          saveRechargePackagesList(parsed)
        }
        return parsed
      }
    }
  } catch (e) {
    console.error('Failed to load recharge packages from localStorage:', e)
  }
  return JSON.parse(JSON.stringify(DEFAULT_RECHARGE_PACKAGES))
}

// 保存扩容加油包配置
export const saveRechargePackagesList = (config: RechargePackagesConfig): void => {
  try {
    localStorage.setItem(STORAGE_KEY_RECHARGE_PACKAGES, JSON.stringify(config))
    window.dispatchEvent(new CustomEvent('seahorse-recharge-packages-updated', { detail: config }))
  } catch (e) {
    console.error('Failed to save recharge packages to localStorage:', e)
  }
}

// 恢复默认加油包
export const resetRechargePackagesList = (): RechargePackagesConfig => {
  const defaults = JSON.parse(JSON.stringify(DEFAULT_RECHARGE_PACKAGES))
  saveRechargePackagesList(defaults)
  return defaults
}

// 更新/新增单个存储包
export const upsertStoragePack = (pack: StoragePackItem): void => {
  const cfg = getRechargePackagesList()
  const idx = cfg.storagePacks.findIndex(p => p.id === pack.id)
  if (idx >= 0) {
    cfg.storagePacks[idx] = { ...cfg.storagePacks[idx], ...pack }
  } else {
    cfg.storagePacks.push(pack)
  }
  saveRechargePackagesList(cfg)
}

// 删除单个存储包
export const deleteStoragePack = (id: string): void => {
  const cfg = getRechargePackagesList()
  cfg.storagePacks = cfg.storagePacks.filter(p => p.id !== id)
  saveRechargePackagesList(cfg)
}

// 更新/新增单个API流量包
export const upsertApiPack = (pack: ApiPackItem): void => {
  const cfg = getRechargePackagesList()
  const idx = cfg.apiPacks.findIndex(p => p.id === pack.id)
  if (idx >= 0) {
    cfg.apiPacks[idx] = { ...cfg.apiPacks[idx], ...pack }
  } else {
    cfg.apiPacks.push(pack)
  }
  saveRechargePackagesList(cfg)
}

// 删除单个API流量包
export const deleteApiPack = (id: string): void => {
  const cfg = getRechargePackagesList()
  cfg.apiPacks = cfg.apiPacks.filter(p => p.id !== id)
  saveRechargePackagesList(cfg)
}

// 获取全部短信加油包列表
export const getSmsPackagesList = (): SmsPackItem[] => {
  return getRechargePackagesList().smsPacks || []
}

// 更新/新增单个短信资源加油包 (超管配置条数与价格)
export const upsertSmsPack = (pack: SmsPackItem): void => {
  const cfg = getRechargePackagesList()
  if (!Array.isArray(cfg.smsPacks)) {
    cfg.smsPacks = []
  }
  // 自动重新计算单价
  if (pack.price > 0 && pack.count > 0) {
    pack.unitPrice = (pack.price / pack.count).toFixed(3)
  }
  const idx = cfg.smsPacks.findIndex(p => String(p.id) === String(pack.id))
  if (idx >= 0) {
    cfg.smsPacks[idx] = { ...cfg.smsPacks[idx], ...pack }
  } else {
    cfg.smsPacks.push(pack)
  }
  saveRechargePackagesList(cfg)
}

// 删除单个短信资源加油包
export const deleteSmsPack = (id: string | number): void => {
  const cfg = getRechargePackagesList()
  if (Array.isArray(cfg.smsPacks)) {
    cfg.smsPacks = cfg.smsPacks.filter(p => String(p.id) !== String(id))
    saveRechargePackagesList(cfg)
  }
}

// 保持 RECHARGE_PACKAGES 动态响应并完全兼容旧代码
export const RECHARGE_PACKAGES: RechargePackagesConfig = new Proxy({} as any, {
  get(_target, prop) {
    const latest = getRechargePackagesList()
    return (latest as any)[prop]
  }
})

// 默认租户预置数据（清空一切模拟租户）
const DEFAULT_TENANT_QUOTA: Record<string, TenantQuotaData> = {}

/**
 * 校验并规范化租户配额数据，过滤 NaN、未定义与非法数值
 */
export function normalizeTenantQuota(raw: any, fallbackTenantId: string = ''): TenantQuotaData {
  if (!raw || typeof raw !== 'object') {
    return {
      tenantId: fallbackTenantId,
      tenantName: fallbackTenantId ? '智慧租户' : '',
      billingMode: 'ANNUAL_TIER',
      planCode: 'FLAGSHIP',
      planName: '旗舰连锁版',
      totalStorageMb: 51200,
      usedStorageMb: 0,
      totalApiCalls: 500000,
      usedApiCalls: 0,
      isLocked: false,
      lockReason: '',
      lockedAt: null,
      lastRechargeTime: null,
      rechargeHistory: [],
      storageUsedMb: 0,
      storageQuotaMb: 51200,
      apiCallsMonthly: 0
    }
  }

  const rawTotalStorage = Number(raw.totalStorageMb ?? raw.storageQuotaMb)
  const totalStorageMb = (!isNaN(rawTotalStorage) && rawTotalStorage > 0) ? rawTotalStorage : 51200

  const rawUsedStorage = Number(raw.usedStorageMb ?? raw.storageUsedMb)
  const usedStorageMb = (!isNaN(rawUsedStorage) && rawUsedStorage >= 0) ? rawUsedStorage : 0

  const rawTotalCalls = Number(raw.totalApiCalls)
  const totalApiCalls = (!isNaN(rawTotalCalls) && rawTotalCalls > 0) ? rawTotalCalls : 500000

  const rawUsedCalls = Number(raw.usedApiCalls ?? raw.apiCallsMonthly)
  const usedApiCalls = (!isNaN(rawUsedCalls) && rawUsedCalls >= 0) ? rawUsedCalls : 0

  return {
    tenantId: raw.tenantId || fallbackTenantId,
    tenantName: raw.tenantName || '智慧租户',
    billingMode: raw.billingMode || 'ANNUAL_TIER',
    planCode: raw.planCode || 'FLAGSHIP',
    planName: raw.planName || '旗舰连锁版',
    totalStorageMb,
    usedStorageMb,
    totalApiCalls,
    usedApiCalls,
    isLocked: Boolean(raw.isLocked),
    lockReason: raw.lockReason || '',
    lockedAt: raw.lockedAt || null,
    lastRechargeTime: raw.lastRechargeTime || null,
    rechargeHistory: Array.isArray(raw.rechargeHistory) ? raw.rechargeHistory : [],
    // 兼容历史字段别名，彻底避免 NaN
    storageUsedMb: usedStorageMb,
    storageQuotaMb: totalStorageMb,
    apiCallsMonthly: usedApiCalls
  }
}

/**
 * 获取租户配额与用量详情 (具备刷新即时自愈能力)
 */
export function getTenantQuota(tenantId?: string): TenantQuotaData {
  const currentTenantId = tenantId || localStorage.getItem('seahorse_tenant_id') || ''
  if (!currentTenantId || currentTenantId === 'PLATFORM') {
    return normalizeTenantQuota(null, '')
  }
  const key = `${QUOTA_STORAGE_PREFIX}${currentTenantId}`
  try {
    const raw = localStorage.getItem(key)
    if (raw) {
      const parsed = JSON.parse(raw)
      const data = normalizeTenantQuota(parsed, currentTenantId)

      // 刷新自愈保护：如果当前登录租户已续费/已是正式商业版，或服务期尚未过期，自动清除本地历史残留锁定
      const cachedPlan = localStorage.getItem('seahorse_plan')
      const cachedExpire = localStorage.getItem('seahorse_expire_date')
      const isNotExpired = cachedExpire ? (new Date(cachedExpire).getTime() >= new Date().setHours(0, 0, 0, 0)) : true
      const isCommercial = cachedPlan && cachedPlan !== 'TRIAL' && cachedPlan !== 'FREE'

      if (isCommercial || isNotExpired) {
        if (data.isLocked && !data.lockReason?.includes('测试模式')) {
          data.isLocked = false
          data.lockReason = ''
          data.lockedAt = null
          if (data.usedStorageMb >= data.totalStorageMb) {
            data.totalStorageMb = Math.max(data.totalStorageMb, isCommercial ? 51200 : 10240)
            data.usedStorageMb = Math.min(data.usedStorageMb, Math.round(data.totalStorageMb * 0.2))
          }
          if (data.usedApiCalls >= data.totalApiCalls) {
            data.totalApiCalls = Math.max(data.totalApiCalls, isCommercial ? 1000000 : 100000)
            data.usedApiCalls = Math.min(data.usedApiCalls, Math.round(data.totalApiCalls * 0.2))
          }
          saveTenantQuota(data)
        }
      }

      return data
    }
  } catch (e) {
    console.warn('Load tenant quota error', e)
  }

  // 若无缓存，取预设或根据租户类型初始化
  if (DEFAULT_TENANT_QUOTA[currentTenantId]) {
    const data = normalizeTenantQuota(DEFAULT_TENANT_QUOTA[currentTenantId], currentTenantId)
    saveTenantQuota(data)
    return data
  }

  // 新建普通租户默认进入“普通永久免费 + 流量包/存储计费模式”
  const isNewTenant = localStorage.getItem('seahorse_is_new_tenant') === 'true'
  const tenantName = localStorage.getItem('seahorse_tenant_name') || '新入驻智慧租户'
  const initData: TenantQuotaData = normalizeTenantQuota({
    tenantId: currentTenantId,
    tenantName: tenantName,
    billingMode: isNewTenant ? 'PAY_AS_YOU_GO' : 'ANNUAL_TIER',
    planCode: isNewTenant ? 'FREE' : 'FLAGSHIP',
    planName: isNewTenant ? '普通永久免费+按量存储' : '旗舰连锁版',
    totalStorageMb: isNewTenant ? 500 : 51200,
    usedStorageMb: 0,
    totalApiCalls: isNewTenant ? 20000 : 500000,
    usedApiCalls: 0,
    isLocked: false,
    lockReason: '',
    lockedAt: null,
    lastRechargeTime: null,
    rechargeHistory: []
  }, currentTenantId)
  saveTenantQuota(initData)
  return initData
}

/**
 * 保存租户配额与用量
 */
export function saveTenantQuota(data: TenantQuotaData): void {
  const key = `${QUOTA_STORAGE_PREFIX}${data.tenantId}`
  localStorage.setItem(key, JSON.stringify(data))

  // 同步更新全局租户列表
  updateGlobalTenantQuotaList(data)

  // 触发全局自定义事件，以便 MainLayout 实时响应锁屏/解锁
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent('seahorse-quota-updated', { detail: data }))
  }
}

/**
 * 记录一次 API 接口调用 (每次请求累加)
 */
export function recordApiCall(tenantId?: string, count: number = 1): TenantQuotaData {
  const quota = getTenantQuota(tenantId)

  // 若已锁定则不重复累加
  if (quota.isLocked) {
    return quota
  }

  // 正式商业包年租户（旗舰版/专业版/企业定制版）不实施单次接口频次锁屏熔断
  if (quota.billingMode === 'ANNUAL_TIER' && quota.planCode !== 'FREE' && quota.planCode !== 'TRIAL') {
    quota.usedApiCalls += count
    saveTenantQuota(quota)
    return quota
  }

  quota.usedApiCalls += count

  // 检查是否达到接口上限
  if (quota.usedApiCalls >= quota.totalApiCalls) {
    quota.usedApiCalls = quota.totalApiCalls
    quota.isLocked = true
    quota.lockReason = `系统操作接口次数已达额度上限 (${quota.totalApiCalls.toLocaleString()} 次)，请及时补充操作流量包！`
    quota.lockedAt = new Date().toLocaleString()
  }

  saveTenantQuota(quota)
  return quota
}

/**
 * 记录一次云端存储写入 (如图片上传、多媒体附件保存)
 */
export function recordStorageUsage(tenantId: string | undefined, deltaMb: number): TenantQuotaData {
  const quota = getTenantQuota(tenantId)
  if (quota.isLocked) {
    return quota
  }

  quota.usedStorageMb = Math.max(0, quota.usedStorageMb + deltaMb)

  // 检查是否达到存储空间上限
  if (quota.usedStorageMb >= quota.totalStorageMb) {
    quota.usedStorageMb = quota.totalStorageMb
    // 正式商业版自动弹性扩容 10GB 缓冲，保障前台收银开单平稳不中断
    if (quota.billingMode === 'ANNUAL_TIER' && quota.planCode !== 'FREE' && quota.planCode !== 'TRIAL') {
      quota.totalStorageMb += 10240
      quota.isLocked = false
    } else {
      quota.isLocked = true
      quota.lockReason = `云端存储空间已达上限 (${quota.totalStorageMb >= 1024 ? (quota.totalStorageMb / 1024).toFixed(1) + ' GB' : quota.totalStorageMb + ' MB'})，请及时充值扩容存储空间！`
      quota.lockedAt = new Date().toLocaleString()
    }
  }

  saveTenantQuota(quota)
  return quota
}

/**
 * 强制锁定租户 (测试或风控使用)
 */
export function lockTenant(tenantId: string | undefined, reason?: string): TenantQuotaData {
  const quota = getTenantQuota(tenantId)
  quota.isLocked = true
  quota.usedStorageMb = quota.totalStorageMb // 标记为耗尽
  quota.lockReason = reason || '云端存储空间已达上限 (100%)，页面写操作已进入锁定保护状态。'
  quota.lockedAt = new Date().toLocaleString()
  saveTenantQuota(quota)
  return quota
}

/**
 * 一键解封租户
 */
export function unlockTenant(tenantId: string | undefined): TenantQuotaData {
  const quota = getTenantQuota(tenantId)
  quota.isLocked = false
  quota.lockReason = ''
  quota.lockedAt = null
  // 若使用量顶格，提供 20% 临时安全缓冲
  if (quota.usedStorageMb >= quota.totalStorageMb) {
    quota.totalStorageMb += 1024 // 赠送 1GB 应急缓冲
  }
  if (quota.usedApiCalls >= quota.totalApiCalls) {
    quota.totalApiCalls += 5000 // 赠送 5000 次应急调用
  }
  saveTenantQuota(quota)
  return quota
}

/**
 * 同步后端最新订阅套餐配额并彻底解除锁定限制 (专用于页面刷新与超管续费后自愈)
 */
export function syncAndUnlockTenantQuota(
  tenantId?: string,
  planCode?: string,
  storageQuotaGb?: number,
  status?: string,
  daysRemaining?: number
): TenantQuotaData {
  const currentTenantId = tenantId || localStorage.getItem('seahorse_tenant_id') || 'T001'
  const quota = getTenantQuota(currentTenantId)

  const effectivePlan = planCode || localStorage.getItem('seahorse_plan') || 'FLAGSHIP'
  const planNameMap: Record<string, string> = {
    FLAGSHIP: '黑金旗舰版',
    PROFESSIONAL: '星光专业版',
    ENTERPRISE: '私有化企业定制版',
    TRIAL: 'SaaS体验版'
  }

  quota.planCode = effectivePlan
  quota.planName = planNameMap[effectivePlan] || '黑金旗舰版'
  quota.billingMode = effectivePlan === 'TRIAL' ? 'PAY_AS_YOU_GO' : 'ANNUAL_TIER'

  // 同步云端总存储空间与调用量上限
  const standardGb = effectivePlan === 'ENTERPRISE' ? 1000 : (effectivePlan === 'FLAGSHIP' ? 50 : (effectivePlan === 'PROFESSIONAL' ? 20 : 5))
  const gb = storageQuotaGb && storageQuotaGb > 0 ? storageQuotaGb : standardGb
  quota.totalStorageMb = Math.max(quota.totalStorageMb || 0, gb * 1024)

  const defaultCalls = effectivePlan === 'ENTERPRISE' ? 10000000 : (effectivePlan === 'FLAGSHIP' ? 2000000 : (effectivePlan === 'PROFESSIONAL' ? 500000 : 50000))
  quota.totalApiCalls = Math.max(quota.totalApiCalls || 0, defaultCalls)

  const isNotExpired = daysRemaining !== undefined ? daysRemaining > 0 : true
  const isActive = (status === 'ACTIVE' || status === 'VALID' || !status) && (effectivePlan !== 'TRIAL' || isNotExpired)

  // 只要商户正常在约或已续费升级，彻底清除阻断锁屏
  if (isActive || effectivePlan !== 'TRIAL') {
    quota.isLocked = false
    quota.lockReason = ''
    quota.lockedAt = null

    // 如果之前处于超额顶格状态，自动修正使用量为合理健康水位
    if (quota.usedStorageMb >= quota.totalStorageMb) {
      quota.usedStorageMb = Math.round(quota.totalStorageMb * 0.15)
    }
    if (quota.usedApiCalls >= quota.totalApiCalls) {
      quota.usedApiCalls = Math.round(quota.totalApiCalls * 0.15)
    }
  }

  saveTenantQuota(quota)
  return quota
}

/**
 * 租户充值存储空间
 */
export function rechargeTenantStorage(
  tenantId: string | undefined,
  packName: string,
  amount: number,
  storageMb: number,
  operator: string = '在线自费充值'
): TenantQuotaData {
  const quota = getTenantQuota(tenantId)
  quota.totalStorageMb += storageMb
  quota.isLocked = false
  quota.lockReason = ''
  quota.lockedAt = null
  quota.lastRechargeTime = new Date().toLocaleString()

  const record: RechargeRecord = {
    id: `RC-ST-${Date.now().toString().slice(-6)}`,
    time: quota.lastRechargeTime,
    type: 'STORAGE',
    packName,
    amount,
    addedStorageMb: storageMb,
    addedApiCalls: 0,
    operator
  }
  quota.rechargeHistory.unshift(record)

  saveTenantQuota(quota)
  return quota
}

/**
 * 租户充值 API 操作流量包
 */
export function rechargeTenantApiCalls(
  tenantId: string | undefined,
  packName: string,
  amount: number,
  calls: number,
  operator: string = '在线自费充值'
): TenantQuotaData {
  const quota = getTenantQuota(tenantId)
  quota.totalApiCalls += calls
  quota.isLocked = false
  quota.lockReason = ''
  quota.lockedAt = null
  quota.lastRechargeTime = new Date().toLocaleString()

  const record: RechargeRecord = {
    id: `RC-API-${Date.now().toString().slice(-6)}`,
    time: quota.lastRechargeTime,
    type: 'API_CALLS',
    packName,
    amount,
    addedStorageMb: 0,
    addedApiCalls: calls,
    operator
  }
  quota.rechargeHistory.unshift(record)

  saveTenantQuota(quota)
  return quota
}

/**
 * 升级为包年套餐
 */
export function upgradeToAnnualPlan(
  tenantId: string | undefined,
  planCode: string,
  planName: string,
  price: number,
  storageMb: number,
  calls: number,
  operator: string = '在线升级包年'
): TenantQuotaData {
  const quota = getTenantQuota(tenantId)
  quota.billingMode = 'ANNUAL_TIER'
  quota.planCode = planCode
  quota.planName = planName
  quota.totalStorageMb += storageMb
  quota.totalApiCalls += calls
  quota.isLocked = false
  quota.lockReason = ''
  quota.lockedAt = null
  quota.lastRechargeTime = new Date().toLocaleString()

  const record: RechargeRecord = {
    id: `RC-ANN-${Date.now().toString().slice(-6)}`,
    time: quota.lastRechargeTime,
    type: 'ANNUAL_UPGRADE',
    packName: `${planName} (年度全功能授权)`,
    amount: price,
    addedStorageMb: storageMb,
    addedApiCalls: calls,
    operator
  }
  quota.rechargeHistory.unshift(record)

  saveTenantQuota(quota)
  return quota
}

/**
 * 获取全平台所有租户的配额与用量台账列表 (供开发商大厅统一监控)
 */
export function getAllTenantsQuotaList(): TenantQuotaData[] {
  const list: TenantQuotaData[] = []
  const knownTenantIds: string[] = []
  try {
    const rawSubs = localStorage.getItem('seahorse_vendor_subscriptions')
    if (rawSubs) {
      const parsed = JSON.parse(rawSubs)
      if (Array.isArray(parsed)) {
        parsed.forEach((s: any) => {
          if (s.tenantId && s.tenantId !== 'PLATFORM' && !knownTenantIds.includes(s.tenantId)) {
            knownTenantIds.push(s.tenantId)
          }
        })
      }
    }
  } catch (e) {}

  const currentTenantId = localStorage.getItem('seahorse_tenant_id')
  if (currentTenantId && currentTenantId !== 'PLATFORM' && !knownTenantIds.includes(currentTenantId)) {
    knownTenantIds.push(currentTenantId)
  }

  for (const tid of knownTenantIds) {
    list.push(getTenantQuota(tid))
  }
  return list
}

function updateGlobalTenantQuotaList(updated: TenantQuotaData): void {
  try {
    const list = getAllTenantsQuotaList()
    const idx = list.findIndex(item => item.tenantId === updated.tenantId)
    if (idx !== -1) {
      list[idx] = updated
    } else {
      list.push(updated)
    }
    localStorage.setItem(ALL_TENANTS_KEY, JSON.stringify(list))
  } catch (e) {
    console.warn('Update global quota list error', e)
  }
}
