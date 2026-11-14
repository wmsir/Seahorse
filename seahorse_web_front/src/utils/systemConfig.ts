/**
 * 系统官方域名与网络链接配置、租户老带新推荐有礼活动核心服务
 */

export interface SystemDomainConfig {
  officialDomain: string
  devDomain: string
  activeEnv: 'PROD' | 'DEV' | 'CUSTOM'
  customDomain: string
}

export interface ReferralCampaignConfig {
  enabled: boolean
  inviterRewardType: 'TRIAL_EXTENSION' | 'COUPON' | 'STORAGE_BOOST'
  trialExtensionDays: number // 默认 30 天 (1 个月)
  couponAmount: number       // 默认 500 元抵扣券
  couponMinSpend: number     // 满 1000 可用
  storageBoostGb: number     // 赠送 20GB 云存储
  inviteeTrialDays: number   // 被邀请人享 30 天免费试用
  inviteeCouponAmount: number// 被邀请人享 200 元新客首单立减
  notifyChannels: {
    popup: boolean
    sms: boolean
    wechat: boolean
  }
  smsTemplate: string
}

export interface ReferralRecord {
  id: string
  inviterTenantId: string
  inviterTenantName: string
  inviterPhone: string
  refereeTenantId: string
  refereeTenantName: string
  refereeIndustry: string
  registeredAt: string
  status: 'ACTIVE' | 'REGISTERED'
  rewardType: 'TRIAL_EXTENSION' | 'COUPON' | 'STORAGE_BOOST'
  rewardDesc: string
  rewardStatus: 'GRANTED' | 'PENDING'
  notificationStatus: {
    popup: boolean
    sms: boolean
    wechat: boolean
  }
  notifiedAt: string
  acknowledgedByTenant: boolean
}

const DOMAIN_STORAGE_KEY = 'seahorse_system_domain_config'
const REFERRAL_CONFIG_KEY = 'seahorse_referral_campaign_config'
const REFERRAL_RECORDS_KEY = 'seahorse_referral_records'

// 默认域名配置：官方正式域名 fwpt.cn，本地开发环境 http://localhost:3000
const DEFAULT_DOMAIN_CONFIG: SystemDomainConfig = {
  officialDomain: 'https://fwpt.cn',
  devDomain: 'http://localhost:3000',
  activeEnv: 'PROD',
  customDomain: ''
}

// 默认裂变奖励规则：租户A推荐租户B，租户A可获得试用期顺延1个月或抵扣券
const DEFAULT_REFERRAL_CONFIG: ReferralCampaignConfig = {
  enabled: true,
  inviterRewardType: 'TRIAL_EXTENSION',
  trialExtensionDays: 30, // 顺延 1 个月
  couponAmount: 500,      // ￥500 抵扣券
  couponMinSpend: 1000,
  storageBoostGb: 20,
  inviteeTrialDays: 30,
  inviteeCouponAmount: 200,
  notifyChannels: {
    popup: true,
    sms: true,
    wechat: true
  },
  smsTemplate: '【海马智慧商业】尊敬的租户，您推荐的同行好友【{refereeName}】已成功入驻开店并使用系统！系统已为您自动发放推荐奖励：{rewardDesc}！已生效至您的租户账户，感谢您的支持！'
}

// 默认推荐记录（全空，等待真实推荐）
const DEFAULT_REFERRAL_RECORDS: ReferralRecord[] = []

// 读取系统域名配置
export const getSystemDomainConfig = (): SystemDomainConfig => {
  try {
    const raw = localStorage.getItem(DOMAIN_STORAGE_KEY)
    if (raw) {
      const parsed = JSON.parse(raw)
      // 保证官方生产域名必须指向 fwpt.cn，防止本地历史缓存旧域名或误写 localhost
      if (!parsed.officialDomain || parsed.officialDomain.includes('localhost') || parsed.officialDomain.includes('seahorse.saas.com')) {
        parsed.officialDomain = 'https://fwpt.cn'
      }
      if (!parsed.devDomain) {
        parsed.devDomain = 'http://localhost:3000'
      }
      return { ...DEFAULT_DOMAIN_CONFIG, ...parsed }
    }
  } catch (e) {
    console.warn('Load domain config error:', e)
  }
  return { ...DEFAULT_DOMAIN_CONFIG }
}

// 保存系统域名配置
export const saveSystemDomainConfig = (config: SystemDomainConfig): void => {
  localStorage.setItem(DOMAIN_STORAGE_KEY, JSON.stringify(config))
}

// 获取当前系统激活的基础 URL（自动去除末尾斜杠，支持传入响应式 config）
export const getActiveBaseUrl = (config?: SystemDomainConfig): string => {
  const cfg = config || getSystemDomainConfig()
  let url = ''
  if (cfg.activeEnv === 'DEV') {
    url = cfg.devDomain || 'http://localhost:3000'
  } else if (cfg.activeEnv === 'CUSTOM') {
    url = cfg.customDomain || 'https://fwpt.cn'
  } else {
    // 官方生产环境 PROD：确保前缀为 fwpt.cn
    if (!cfg.officialDomain || cfg.officialDomain.includes('localhost') || cfg.officialDomain.includes('seahorse.saas.com')) {
      url = 'https://fwpt.cn'
    } else {
      url = cfg.officialDomain
    }
  }
  const cleaned = url.replace(/\/+$/, '')
  return cleaned.endsWith('/seahorse') ? cleaned : `${cleaned}/seahorse`
}

// 读取推荐活动规则配置
export const getReferralCampaignConfig = (): ReferralCampaignConfig => {
  try {
    const raw = localStorage.getItem(REFERRAL_CONFIG_KEY)
    if (raw) {
      return { ...DEFAULT_REFERRAL_CONFIG, ...JSON.parse(raw) }
    }
  } catch (e) {
    console.warn('Load referral config error:', e)
  }
  return { ...DEFAULT_REFERRAL_CONFIG }
}

// 保存推荐活动规则配置
export const saveReferralCampaignConfig = (config: ReferralCampaignConfig): void => {
  localStorage.setItem(REFERRAL_CONFIG_KEY, JSON.stringify(config))
}

// 读取推荐记录清单
export const getReferralRecords = (): ReferralRecord[] => {
  try {
    const raw = localStorage.getItem(REFERRAL_RECORDS_KEY)
    if (raw) {
      const list = JSON.parse(raw)
      if (Array.isArray(list)) {
        return list
      }
    }
  } catch (e) {
    console.warn('Load referral records error:', e)
  }
  return [...DEFAULT_REFERRAL_RECORDS]
}

// 保存推荐记录
export const saveReferralRecords = (records: ReferralRecord[]): void => {
  localStorage.setItem(REFERRAL_RECORDS_KEY, JSON.stringify(records))
}

// 模拟触发新推荐成功（用于开发商或演示测试）
export const simulateNewReferral = (
  inviterTenantId: string,
  inviterTenantName: string,
  inviterPhone: string,
  refereeTenantName: string,
  refereeIndustry: string
): ReferralRecord => {
  const cfg = getReferralCampaignConfig()
  const currentList = getReferralRecords()
  const newRefereeId = `T00${currentList.length + 5}`

  let rewardDesc = ''
  if (cfg.inviterRewardType === 'TRIAL_EXTENSION') {
    rewardDesc = `试用期免费延迟 ${cfg.trialExtensionDays} 天 (约${Math.round(cfg.trialExtensionDays / 30)}个月)`
  } else if (cfg.inviterRewardType === 'COUPON') {
    rewardDesc = `￥${cfg.couponAmount} SaaS 订阅/续费现金抵扣券 (满${cfg.couponMinSpend}可用)`
  } else {
    rewardDesc = `赠送 ${cfg.storageBoostGb}GB 云端存储加速包`
  }

  const newRecord: ReferralRecord = {
    id: `REF-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${String(currentList.length + 1).padStart(3, '0')}`,
    inviterTenantId,
    inviterTenantName,
    inviterPhone,
    refereeTenantId: newRefereeId,
    refereeTenantName,
    refereeIndustry,
    registeredAt: new Date().toLocaleString(),
    status: 'ACTIVE',
    rewardType: cfg.inviterRewardType,
    rewardDesc,
    rewardStatus: 'GRANTED',
    notificationStatus: {
      popup: cfg.notifyChannels.popup,
      sms: cfg.notifyChannels.sms,
      wechat: cfg.notifyChannels.wechat
    },
    notifiedAt: new Date().toLocaleString(),
    acknowledgedByTenant: false
  }

  currentList.unshift(newRecord)
  saveReferralRecords(currentList)
  return newRecord
}

// 获取某个租户未读/未确认的推荐奖励通知
export const getUnreadRewardNotificationForTenant = (tenantId: string): ReferralRecord | null => {
  const records = getReferralRecords()
  return records.find(r => r.inviterTenantId === tenantId && !r.acknowledgedByTenant && r.rewardStatus === 'GRANTED') || null
}

// 将奖励通知标记为已读/已确认
export const acknowledgeRewardNotification = (recordId: string): void => {
  const records = getReferralRecords()
  const target = records.find(r => r.id === recordId)
  if (target) {
    target.acknowledgedByTenant = true
    saveReferralRecords(records)
  }
}

// ============================================================================
// Tauri v2 桌面客户端运行环境与多服务器 API Base URL 动态路由配置
// ============================================================================

export const DESKTOP_API_STORAGE_KEY = 'seahorse_desktop_api_base'
export const DEFAULT_DESKTOP_API_BASE = 'https://fwpt.cn/api'
const LEGACY_DESKTOP_API_BASE = 'https://fwpt.cn/seahorse/api'
export const LOCAL_DEV_API_BASE = 'http://127.0.0.1:8082/api'

export interface DesktopConfigPayload {
  apiBaseUrl: string
  configPath?: string
  updatedAt?: number
}

export interface DesktopProbeResult {
  reachable: boolean
  statusCode: number | null
  latencyMs: number
  target: string
  message: string
}

export const isDesktopTauriEnv = (): boolean => {
  if (import.meta.env.MODE === 'desktop') return true
  if (typeof window !== 'undefined') {
    const w = window as any
    if ('__TAURI_INTERNALS__' in w || '__TAURI__' in w) return true
  }
  return false
}

export const normalizeApiBaseUrl = (raw?: string | null): string => {
  const trimmed = (raw || '').trim().replace(/\/+$/, '')
  if (!trimmed) return DEFAULT_DESKTOP_API_BASE
  if (trimmed === '/api') return '/api'
  const withScheme = /^https?:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`
  if (withScheme.toLowerCase() === LEGACY_DESKTOP_API_BASE) {
    return DEFAULT_DESKTOP_API_BASE
  }
  return withScheme
}

export const getApiBaseUrl = (): string => {
  if (!isDesktopTauriEnv()) {
    return '/api'
  }
  try {
    const saved = localStorage.getItem(DESKTOP_API_STORAGE_KEY)
    if (saved && saved.trim()) {
      const cleanedSaved = saved.trim().replace(/\/+$/, '')
      if (cleanedSaved === LEGACY_DESKTOP_API_BASE || cleanedSaved.toLowerCase() === LEGACY_DESKTOP_API_BASE) {
        localStorage.setItem(DESKTOP_API_STORAGE_KEY, DEFAULT_DESKTOP_API_BASE)
        return DEFAULT_DESKTOP_API_BASE
      }
      return normalizeApiBaseUrl(saved)
    }
  } catch (_e) {}
  return DEFAULT_DESKTOP_API_BASE
}

export const resolveApiUrl = (path: string): string => {
  if (!path) return getApiBaseUrl()
  if (/^https?:\/\//i.test(path)) return path
  const base = getApiBaseUrl()
  if (base === '/api') {
    return path.startsWith('/') ? path : `/${path}`
  }
  const cleanSubPath = path.replace(/^\/api(?=\/|$)/, '')
  if (!cleanSubPath) return base
  return `${base}${cleanSubPath.startsWith('/') ? cleanSubPath : `/${cleanSubPath}`}`
}

const invokeTauriCommand = async <T = any>(cmd: string, args?: Record<string, any>): Promise<T | null> => {
  if (typeof window === 'undefined') return null
  const w = window as any
  const invokeFn = w.__TAURI__?.core?.invoke || w.__TAURI_INTERNALS__?.invoke
  if (typeof invokeFn !== 'function') return null
  try {
    return await invokeFn(cmd, args)
  } catch (err) {
    console.warn(`[DesktopIPC] ${cmd} failed:`, err)
    return null
  }
}

export const initDesktopApiConfig = async (): Promise<string> => {
  if (!isDesktopTauriEnv()) return '/api'
  try {
    const cached = localStorage.getItem(DESKTOP_API_STORAGE_KEY)
    if (cached && cached.trim().replace(/\/+$/, '').toLowerCase() === LEGACY_DESKTOP_API_BASE) {
      localStorage.setItem(DESKTOP_API_STORAGE_KEY, DEFAULT_DESKTOP_API_BASE)
    }
  } catch (_e) {}
  const cfg = await invokeTauriCommand<DesktopConfigPayload>('get_desktop_config')
  if (cfg && cfg.apiBaseUrl) {
    const normalized = normalizeApiBaseUrl(cfg.apiBaseUrl)
    if (cfg.apiBaseUrl.trim().replace(/\/+$/, '').toLowerCase() === LEGACY_DESKTOP_API_BASE) {
      await invokeTauriCommand<DesktopConfigPayload>('save_desktop_config', { apiBaseUrl: DEFAULT_DESKTOP_API_BASE })
    }
    try {
      localStorage.setItem(DESKTOP_API_STORAGE_KEY, normalized)
    } catch (_e) {}
    return normalized
  }
  return getApiBaseUrl()
}

export const saveDesktopApiBaseUrl = async (apiBaseUrl: string): Promise<string> => {
  const normalized = normalizeApiBaseUrl(apiBaseUrl)
  try {
    localStorage.setItem(DESKTOP_API_STORAGE_KEY, normalized)
  } catch (_e) {}
  await invokeTauriCommand<DesktopConfigPayload>('save_desktop_config', { apiBaseUrl: normalized })
  return normalized
}

export const probeDesktopBackend = async (apiBaseUrl: string, timeoutMs = 3000): Promise<DesktopProbeResult> => {
  const normalized = normalizeApiBaseUrl(apiBaseUrl)
  const ipcRes = await invokeTauriCommand<DesktopProbeResult>('probe_backend_server', {
    apiBaseUrl: normalized,
    timeoutMs
  })
  if (ipcRes && typeof ipcRes.reachable === 'boolean') {
    return ipcRes
  }
  const start = Date.now()
  const controller = typeof AbortController !== 'undefined' ? new AbortController() : null
  const timer = controller ? setTimeout(() => controller.abort(), timeoutMs) : null
  const probeUrl = `${normalized}/auth/plans`
  try {
    const res = await fetch(probeUrl, { method: 'GET', signal: controller?.signal })
    return {
      reachable: res.status < 500,
      statusCode: res.status,
      latencyMs: Date.now() - start,
      target: probeUrl,
      message: res.ok ? '服务端响应正常' : `HTTP ${res.status}`
    }
  } catch (err: any) {
    return {
      reachable: false,
      statusCode: null,
      latencyMs: Date.now() - start,
      target: probeUrl,
      message: err?.message || '无法连接目标服务器'
    }
  } finally {
    if (timer) clearTimeout(timer)
  }
}

// ============================================================================
// 统一角色权限标准化辅助函数 (对齐后端 EmployeeRole 枚举)
// ============================================================================

export const isPlatformAdminRole = (role?: string | null, username?: string | null): boolean => {
  const r = (role || '').toUpperCase().trim()
  const u = (username || '').toLowerCase().trim()
  return (
    u === 'admin' ||
    r === 'PLATFORM_DEVELOPER' ||
    r === 'PLATFORM_ADMIN' ||
    r === 'PLATFORM_SUPER_ADMIN'
  )
}

export const isTenantBossRole = (role?: string | null): boolean => {
  const r = (role || '').toUpperCase().trim()
  return (
    r === 'SUPER_ADMIN' ||
    r === 'TENANT_ADMIN' ||
    r === 'MERCHANT_ADMIN' ||
    r === 'STORE_OWNER'
  )
}

export const isManagerOrAboveRole = (role?: string | null, username?: string | null): boolean => {
  const r = (role || '').toUpperCase().trim()
  return (
    isPlatformAdminRole(r, username) ||
    isTenantBossRole(r) ||
    r === 'STORE_MANAGER'
  )
}
