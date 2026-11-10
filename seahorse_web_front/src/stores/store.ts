import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getCurrentIndustryApi, getTenantStoresApi, getCurrentSubscriptionApi } from '../api'
import { unlockTenant, syncAndUnlockTenantQuota } from '../utils/tenantQuotaService'

export interface StoreItem {
  storeId: string
  storeName: string
  industry: string
  industryDesc: string
}

export const useStoreConfig = defineStore('storeConfig', () => {
  const industry = ref('BEAUTY')
  const getDefaultSpaceAlias = (ind?: string) => {
    const target = ind || industry.value
    switch (target) {
      case 'RESTAURANT': return '包厢'
      case 'AUTO': return '工位'
      case 'BEAUTY': return '工位'
      case 'RETAIL': return '展位'
      default: return '包厢'
    }
  }

  const spaceAlias = ref(localStorage.getItem('seahorse_custom_space_alias') || getDefaultSpaceAlias('BEAUTY'))
  const appendActionAlias = ref('加护理')
  const defaultFeeName = ref('造型费')
  const isNewTenant = localStorage.getItem('seahorse_is_new_tenant') === 'true'
  const storeName = ref(localStorage.getItem('seahorse_store_name') ?? (isNewTenant ? '' : '海马智慧门店 (旗舰体验中心)'))
  const currentStoreId = ref(localStorage.getItem('seahorse_store_id') ?? (isNewTenant ? '' : 'S001'))
  const tenantId = ref(localStorage.getItem('seahorse_tenant_id') ?? (isNewTenant ? '' : 'T001'))
  const tenantName = ref(localStorage.getItem('seahorse_tenant_name') ?? (isNewTenant ? '' : '海马智慧连锁集团'))
  const plan = ref(localStorage.getItem('seahorse_plan') || 'FLAGSHIP')
  const expireDate = ref(localStorage.getItem('seahorse_expire_date') || '')
  const status = ref(localStorage.getItem('seahorse_tenant_status') || 'ACTIVE')
  const deductMode = ref(localStorage.getItem('seahorse_deduct_mode') || 'PROPORTIONAL')
  const storeLimit = ref(Number(localStorage.getItem('seahorse_store_limit')) || 1)
  const staffLimit = ref(Number(localStorage.getItem('seahorse_staff_limit')) || 3)
  const industryCategoryId = ref<number | null>(null)
  const industryCategoryName = ref<string>(localStorage.getItem('seahorse_industry_category') || '')
  const industryCategoryGroup = ref<string>('')
  const phone = ref(localStorage.getItem('seahorse_store_phone') || '400-888-6688')
  const address = ref(localStorage.getItem('seahorse_store_address') || '智慧商业中心 101号铺')
  const businessHours = ref(localStorage.getItem('seahorse_store_business_hours') || '09:00 - 22:30')
  let initialStores: StoreItem[] = []
  try {
    const raw = localStorage.getItem('seahorse_stores_data')
    if (raw) initialStores = JSON.parse(raw)
  } catch {}
  const stores = ref<StoreItem[]>(initialStores)

  const setCustomSpaceAlias = (alias: string) => {
    const val = alias.trim() || getDefaultSpaceAlias()
    spaceAlias.value = val
    localStorage.setItem('seahorse_custom_space_alias', val)
  }

  const isTrial = computed(() => plan.value === 'TRIAL')
  const trialDaysRemaining = computed(() => {
    if (!expireDate.value) return 3
    const target = new Date(expireDate.value).getTime()
    const today = new Date().setHours(0, 0, 0, 0)
    const diff = target - today
    const days = Math.ceil(diff / (1000 * 60 * 60 * 24))
    return days >= 0 ? days : 0
  })

  const fetchIndustry = async () => {
    const demoMode = localStorage.getItem('seahorse_demo_mode')
    if (demoMode) {
      industry.value = demoMode
      return
    }
    try {
      const data: any = await getCurrentIndustryApi()
      if (data) {
        industry.value = data.industry || (data.storeId ? 'BEAUTY' : '')
        const custom = localStorage.getItem('seahorse_custom_space_alias')
        if (custom) {
          spaceAlias.value = custom
        } else if (data.spaceAlias) {
          spaceAlias.value = data.spaceAlias
        }
        if (data.appendActionAlias) appendActionAlias.value = data.appendActionAlias
        if (data.defaultFeeName) defaultFeeName.value = data.defaultFeeName
        if (data.storeId) {
          currentStoreId.value = data.storeId
          localStorage.setItem('seahorse_store_id', data.storeId)
        }
        if (data.storeName) {
          storeName.value = data.storeName
          localStorage.setItem('seahorse_store_name', data.storeName)
        }
        if (data.storeId && data.storeName) {
          localStorage.removeItem('seahorse_is_new_tenant')
        }
        if (data.deductMode) {
          deductMode.value = data.deductMode
          localStorage.setItem('seahorse_deduct_mode', data.deductMode)
        }
        const catName = data.industryCategoryName || data.category?.name
        const catId = data.industryCategoryId ?? data.category?.id
        const catGroup = data.industryCategoryGroup || data.category?.groupName
        if (catName || catId) {
          industryCategoryId.value = catId ?? null
          industryCategoryName.value = catName || ''
          industryCategoryGroup.value = catGroup || ''
          if (catName) localStorage.setItem('seahorse_industry_category', catName)
        }
        if (data.phone) {
          phone.value = data.phone
          localStorage.setItem('seahorse_store_phone', data.phone)
        }
        if (data.address) {
          address.value = data.address
          localStorage.setItem('seahorse_store_address', data.address)
        }
        if (data.businessHours) {
          businessHours.value = data.businessHours
          localStorage.setItem('seahorse_store_business_hours', data.businessHours)
        }
      }
    } catch (e) {
      console.error(e)
    }
  }

  const loadStores = async () => {
    const demoMode = localStorage.getItem('seahorse_demo_mode')
    if (demoMode) {
      try {
        const cached = localStorage.getItem('seahorse_stores_data')
        if (cached) {
          const parsed = JSON.parse(cached)
          if (Array.isArray(parsed) && parsed.length > 0) {
            stores.value = parsed
            const matched = parsed.find((s: any) => s.storeId === currentStoreId.value) || parsed[0]
            if (matched) {
              currentStoreId.value = matched.storeId
              storeName.value = matched.storeName
              localStorage.setItem('seahorse_store_id', matched.storeId)
              localStorage.setItem('seahorse_store_name', matched.storeName)
            }
            return
          }
        }
      } catch {}
    }
    try {
      const list: any = await getTenantStoresApi()
      if (Array.isArray(list)) {
        stores.value = list
        localStorage.setItem('seahorse_stores_data', JSON.stringify(list))
        if (list.length > 0) {
          localStorage.removeItem('seahorse_is_new_tenant')
          const matched = list.find((s: any) => s.storeId === currentStoreId.value) || list[0]
          if (matched) {
            currentStoreId.value = matched.storeId
            storeName.value = matched.storeName
            localStorage.setItem('seahorse_store_id', matched.storeId)
            localStorage.setItem('seahorse_store_name', matched.storeName)
            if (matched.industry) {
              industry.value = matched.industry
            }
            if (matched.industryCategoryName) {
              industryCategoryName.value = matched.industryCategoryName
              localStorage.setItem('seahorse_industry_category', matched.industryCategoryName)
            }
            if (matched.industryCategoryId) {
              industryCategoryId.value = matched.industryCategoryId
            }
            if (matched.industryCategoryGroup) {
              industryCategoryGroup.value = matched.industryCategoryGroup
            }
          }
        }
      }
    } catch (e) {
      console.error(e)
    }
  }

  const switchStore = async (newStoreId: string) => {
    currentStoreId.value = newStoreId
    localStorage.setItem('seahorse_store_id', newStoreId)
    const matched = stores.value.find(s => s.storeId === newStoreId)
    if (matched && matched.storeName) {
      storeName.value = matched.storeName
      localStorage.setItem('seahorse_store_name', matched.storeName)
    }
    await fetchIndustry()
  }

  const fetchCurrentSubscription = async () => {
    try {
      const res: any = await getCurrentSubscriptionApi()
      if (res) {
        if (res.plan) {
          plan.value = res.plan
          localStorage.setItem('seahorse_plan', res.plan)
        }
        if (res.storeLimit != null) {
          storeLimit.value = Number(res.storeLimit)
          localStorage.setItem('seahorse_store_limit', String(res.storeLimit))
        }
        if (res.staffLimit != null) {
          staffLimit.value = Number(res.staffLimit)
          localStorage.setItem('seahorse_staff_limit', String(res.staffLimit))
        }
        if (res.expireDate) {
          expireDate.value = res.expireDate
          localStorage.setItem('seahorse_expire_date', res.expireDate)
        }
        if (res.status) {
          status.value = res.status
          localStorage.setItem('seahorse_tenant_status', res.status)
        }
        if (res.tenantName && !isNewTenant) {
          tenantName.value = res.tenantName
          localStorage.setItem('seahorse_tenant_name', res.tenantName)
        }

        // 无论何种套餐版本，只要后台显示正常在约/已续费，即刻同步配额并彻底解除锁定
        const currentTid = res.tenantId || tenantId.value || localStorage.getItem('seahorse_tenant_id') || 'T001'
        syncAndUnlockTenantQuota(
          currentTid,
          res.plan,
          res.storageQuotaGb,
          res.status,
          res.daysRemaining
        )
      }
      return res
    } catch (e) {
      console.warn('拉取商户最新订阅状态失败', e)
      return null
    }
  }

  return {
    industry,
    spaceAlias,
    appendActionAlias,
    defaultFeeName,
    storeName,
    currentStoreId,
    tenantId,
    tenantName,
    plan,
    status,
    expireDate,
    isTrial,
    trialDaysRemaining,
    deductMode,
    industryCategoryId,
    industryCategoryName,
    industryCategoryGroup,
    phone,
    address,
    businessHours,
    stores,
    storeLimit,
    staffLimit,
    fetchIndustry,
    loadStores,
    switchStore,
    fetchCurrentSubscription,
    getDefaultSpaceAlias,
    setCustomSpaceAlias
  }
})
