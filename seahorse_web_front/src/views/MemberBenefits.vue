<template>
  <div class="benefits-page-container">
    <!-- 顶部状态栏装饰 -->
    <div class="top-nav-bar">
      <div class="brand-badge">
        <svg viewBox="0 0 64 64" width="38" height="38" style="flex-shrink:0;filter:drop-shadow(0 2px 6px rgba(14,165,233,0.35));" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="shMascotBg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0284c7"/>
      <stop offset="55%" stop-color="#0ea5e9"/>
      <stop offset="100%" stop-color="#38bdf8"/>
    </linearGradient>
    <linearGradient id="shMascotGold" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fde047"/>
      <stop offset="100%" stop-color="#f59e0b"/>
    </linearGradient>
  </defs>
  <rect x="2" y="2" width="60" height="60" rx="16" fill="url(#shMascotBg)" stroke="#bae6fd" stroke-width="1.5"/>
  <path d="M29 11 L32 6 L35 11 L39 8 L38 14 Z" fill="url(#shMascotGold)"/>
  <path d="M38 22 C42 20 44 23 41 26 C44 28 42 32 37 31 Z" fill="url(#shMascotGold)" opacity="0.92"/>
  <path d="M32 12 C24 12 20 17 21 23 C22 27 25 29 24 34 C22 40 26 47 32 49 C37 51 41 47 39 43 C37 40 33 42 34 45 C31 44 29 40 31 35 C33 30 38 28 38 22 C38 19 43 19 45 18 C46 17 45 15 43 15 C40 15 37 12 32 12 Z" fill="#ffffff"/>
  <circle cx="33.5" cy="17.5" r="2" fill="#0f172a"/>
  <circle cx="34.2" cy="16.8" r="0.7" fill="#ffffff"/>
</svg>
        <span class="brand-text">海马智慧门店 · “海马会员，记住每位好客。”</span>
      </div>
      <div class="live-status-chip">
        <span class="status-dot"></span>
        <span>营业中</span>
      </div>
    </div>

    <!-- 1. 门店主招牌与品牌视觉横幅 -->
    <div class="store-hero-card">
      <div class="hero-bg-glow"></div>
      <div class="hero-content">
        <div class="store-avatar-box">
          <span class="store-icon">{{ storeEmoji }}</span>
        </div>
        <div class="store-titles">
          <div class="store-main-name">
            {{ displayStoreName }}
          </div>
          <div class="store-tags-row">
            <span class="industry-chip">{{ displayIndustryName }}</span>
            <span class="cert-chip">★ 官方认证门店</span>
            <span class="store-no-chip">店铺号: {{ targetStoreId }}</span>
          </div>
          <div class="store-slogan-text">
            “{{ displaySlogan }}”
          </div>
        </div>
      </div>
    </div>

    <!-- 2. 门店核心联系方式与实体位置卡片 -->
    <div class="info-section-card">
      <div class="card-section-title">
        <span class="title-icon">📍</span>
        <span>门店基础信息与联系方式</span>
      </div>

      <div class="contact-items-list">
        <!-- 电话 -->
        <div class="contact-item" @click="handleCallPhone">
          <div class="c-left">
            <span class="c-icon phone-icon">📞</span>
            <div>
              <div class="c-label">服务热线 / 预约电话</div>
              <div class="c-val mono highlight-phone">{{ displayPhone }}</div>
            </div>
          </div>
          <div class="c-actions">
            <el-button type="primary" size="small" round>拨打</el-button>
            <el-button size="small" round @click.stop="handleCopy(displayPhone, '服务热线已复制')">复制</el-button>
          </div>
        </div>

        <!-- 地址 -->
        <div class="contact-item">
          <div class="c-left">
            <span class="c-icon loc-icon">🗺️</span>
            <div>
              <div class="c-label">门店详细地址</div>
              <div class="c-val">{{ displayAddress }}</div>
            </div>
          </div>
          <div class="c-actions">
            <el-button size="small" round @click="handleCopy(displayAddress, '门店地址已复制')">复制地址</el-button>
          </div>
        </div>

        <!-- 营业时间与 Wi-Fi -->
        <div class="contact-grid-row">
          <div class="sub-contact-box">
            <span class="sub-icon">⏰</span>
            <div>
              <div class="sub-lbl">营业时间</div>
              <div class="sub-val">{{ displayBusinessHours }}</div>
            </div>
          </div>

          <div class="sub-contact-box">
            <span class="sub-icon">📶</span>
            <div>
              <div class="sub-lbl">店内 Wi-Fi</div>
              <div class="sub-val">
                <span>{{ displayWifiSsid }}</span>
                <span v-if="displayWifiPass" class="wifi-pass-btn" @click="handleCopy(displayWifiPass, 'Wi-Fi 密码已复制')">
                  (密码: {{ displayWifiPass }} · 复制)
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 3. 会员卡尊享权益与等级折扣 -->
    <div class="info-section-card">
      <div class="card-section-title">
        <span class="title-icon">💳</span>
        <span>会员尊享权益与等级礼遇</span>
      </div>
      <div class="section-intro">
        开通本店会员即可尊享折扣特权、储值立赠金与海马体到店常态免报偏好
      </div>

      <div class="member-tiers-grid">
        <div
          v-for="card in memberTierCards"
          :key="card.code"
          :class="['tier-card-item', card.bgClass]"
        >
          <div class="t-head">
            <div class="t-name">
              <span>{{ card.icon }}</span>
              <span>{{ card.name }}</span>
            </div>
            <div class="t-discount-badge">{{ card.discountText }}</div>
          </div>
          <div class="t-desc">{{ card.desc }}</div>
          <div class="t-perks">
            <span v-for="(p, i) in card.perks" :key="i" class="perk-tag">✓ {{ p }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 4. 充多少送多少 · 优惠充赠套餐 -->
    <div v-if="chargeOptions.length > 0" class="info-section-card">
      <div class="card-section-title">
        <span class="title-icon">🎁</span>
        <span>开卡充赠优惠与限时礼遇</span>
      </div>
      <div class="section-intro">
        实充本金 + 奖励赠金双轨入账，资金透明，消费自动享受折上折
      </div>

      <div class="charge-options-grid">
        <div
          v-for="opt in chargeOptions"
          :key="opt.id"
          class="charge-card-item"
        >
          <div class="ch-badge" v-if="opt.badge">{{ opt.badge }}</div>
          <div class="ch-title">{{ opt.title }}</div>
          <div class="ch-amount-box">
            <span class="currency">￥</span>
            <span class="amount-num">{{ opt.principal }}</span>
          </div>
          <div class="ch-gift-text" v-if="opt.gift > 0">
            立赠赠金 <strong>+￥{{ opt.gift }}</strong>
          </div>
          <div class="ch-gift-text free" v-else>
            零门槛极速激活
          </div>
          <div class="ch-footer-level">
            直接晋升: <strong>{{ opt.levelName || 'VIP会员' }}</strong>
          </div>
        </div>
      </div>
    </div>

    <!-- 5. 熟客“海马体”常态记忆与贴心偏好池 -->
    <div class="info-section-card">
      <div class="card-section-title">
        <span class="title-icon">🧠</span>
        <span>本店熟客常态贴心偏好服务</span>
      </div>
      <div class="section-intro">
        海马体常态记忆档案：开卡后您的习惯免报即享，技术主理全程贴心关怀
      </div>

      <div class="habit-tags-cloud">
        <span
          v-for="(tag, i) in storePreferenceTags"
          :key="i"
          class="habit-cloud-tag"
        >
          ✨ {{ tag }}
        </span>
      </div>
    </div>

    <!-- 6. 快捷服务通道按钮 -->
    <div class="info-section-card action-hub-card">
      <div class="card-section-title">
        <span class="title-icon">🚀</span>
        <span>顾客专属服务直达通道</span>
      </div>

      <div class="hub-buttons-grid">
        <div class="hub-btn primary-hub" @click="handleGoMemberRegister">
          <div class="h-icon">💳</div>
          <div class="h-texts">
            <div class="h-main">在线自助开通会员</div>
            <div class="h-sub">免排队 · 领开卡礼遇与积分</div>
          </div>
          <span class="h-arrow">👉</span>
        </div>

        <div class="hub-btn normal-hub" @click="handleGoMemberPortal">
          <div class="h-icon">📋</div>
          <div class="h-texts">
            <div class="h-main">我的会员档案与卡包</div>
            <div class="h-sub">查看余额、消费账单与优惠券</div>
          </div>
          <span class="h-arrow">›</span>
        </div>

        <div class="hub-btn normal-hub" @click="handleGoTableOrder">
          <div class="h-icon">🛎️</div>
          <div class="h-texts">
            <div class="h-main">店内扫码选品与点单</div>
            <div class="h-sub">包厢/桌位聚合自助加项与呼叫</div>
          </div>
          <span class="h-arrow">›</span>
        </div>
      </div>
    </div>

    <!-- 底部备案与技术支持声明 -->
    <div class="footer-copyright">
      <div>本服务由 <strong>海马智慧门店云管理平台</strong> 提供技术支持</div>
      <div class="sub-cr">店铺编号: {{ targetStoreId }} · 访问域名: {{ currentHost }}</div>
    </div>

    <!-- 底部吸底操作栏 (移动端友好) -->
    <div class="bottom-float-bar">
      <el-button class="float-btn-sub" @click="handleCallPhone">
        📞 电话联系
      </el-button>
      <el-button type="primary" class="float-btn-main" @click="handleGoMemberRegister">
        💳 立即自助开卡享权益
      </el-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSystemDataStore } from '../stores/systemDataStore'
import { useStoreConfig } from '../stores/store'
import { getStoreInfoApi, getStoreRegisterConfigApi } from '../api'
import { ElMessage } from 'element-plus'

const route = useRoute()
const router = useRouter()
const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()

// 目标店铺号 (优先从 URL storeId 取，缺省兼容本地当前店铺)
const targetStoreId = computed(() => {
  const qId = route.query.storeId as string
  if (qId && qId.trim()) return qId.trim()
  return storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || 'S001'
})

const remoteStore = ref<any>(null)
const currentHost = computed(() => (typeof window !== 'undefined' && window.location.host) ? window.location.host : 'fwpt.cn')

// 综合店铺信息解析 (优先远端接口，平滑回退商户本地配置及持久化资料)
const matchedLocalStore = computed(() => {
  const sId = targetStoreId.value
  return systemData.stores?.find((s: any) => s.storeId === sId || s.id === sId) ||
         storeConfig.stores?.find((s: any) => s.storeId === sId) ||
         null
})

const basicSettings = computed(() => {
  try {
    const raw = localStorage.getItem('seahorse_basic_settings')
    if (raw) return JSON.parse(raw)
  } catch {}
  return null
})

// 店铺名称主抬头
const displayStoreName = computed(() => {
  if (remoteStore.value?.storeName) return remoteStore.value.storeName
  if (matchedLocalStore.value?.storeName) return matchedLocalStore.value.storeName
  if (basicSettings.value?.storeName) return basicSettings.value.storeName
  if (storeConfig.storeName) return storeConfig.storeName
  return localStorage.getItem('seahorse_store_name') || `海马智慧门店 (${targetStoreId.value})`
})

// 店铺服务电话
const displayPhone = computed(() => {
  if (remoteStore.value?.phone) return remoteStore.value.phone
  if (matchedLocalStore.value?.phone) return matchedLocalStore.value.phone
  if (basicSettings.value?.phone) return basicSettings.value.phone
  if (storeConfig.phone) return storeConfig.phone
  return localStorage.getItem('seahorse_store_phone') || '400-888-6688'
})

// 店铺详细地址
const displayAddress = computed(() => {
  if (remoteStore.value?.address) return remoteStore.value.address
  if (matchedLocalStore.value?.address) return matchedLocalStore.value.address
  if (basicSettings.value?.address) return basicSettings.value.address
  if (storeConfig.address) return storeConfig.address
  return localStorage.getItem('seahorse_store_address') || '智慧商业中心 101号铺'
})

// 营业时段
const displayBusinessHours = computed(() => {
  if (remoteStore.value?.businessHours) return remoteStore.value.businessHours
  if (basicSettings.value?.businessHours) {
    if (Array.isArray(basicSettings.value.businessHours)) return basicSettings.value.businessHours.join(' - ')
    return basicSettings.value.businessHours
  }
  return localStorage.getItem('seahorse_store_business_hours') || '09:00 - 22:00'
})

// 店内 Wi-Fi
const displayWifiSsid = computed(() => basicSettings.value?.wifiSsid || 'Store_VIP_5G')
const displayWifiPass = computed(() => basicSettings.value?.wifiPass || '88888888')

// 口号
const displaySlogan = computed(() => {
  return basicSettings.value?.slogan || '以客为尊 · 品质服务每一天'
})

// 行业模态图标与名称
const storeEmoji = computed(() => {
  const ind = (remoteStore.value?.industry || matchedLocalStore.value?.industry || storeConfig.industry || '').toUpperCase()
  const name = displayStoreName.value
  if (ind === 'AUTO' || name.includes('车') || name.includes('维保')) return '🚗'
  if (ind === 'RESTAURANT' || name.includes('餐') || name.includes('食') || name.includes('火锅')) return '🍲'
  if (ind === 'FOOT_SPA' || name.includes('足') || name.includes('SPA') || name.includes('养生')) return '💆‍♀️'
  if (ind === 'TEA_HOUSE' || name.includes('茶') || name.includes('棋牌')) return '🍵'
  if (ind === 'PET' || name.includes('宠')) return '🐾'
  if (ind === 'RETAIL' || name.includes('零售') || name.includes('生活馆')) return '🛍️'
  return '💇‍♀️'
})

const displayIndustryName = computed(() => {
  const ind = (remoteStore.value?.industry || matchedLocalStore.value?.industry || storeConfig.industry || 'BEAUTY').toUpperCase()
  switch (ind) {
    case 'RESTAURANT': return '餐饮美食 / 聚合点单'
    case 'AUTO': return '汽车养护 / 维保工位'
    case 'FOOT_SPA': return '足道养生 / 东方SPA'
    case 'TEA_HOUSE': return '茶座休闲 / 商务棋牌'
    case 'PET': return '宠物健康 / 精致洗护'
    case 'RETAIL': return '特色零售 / 严选好物'
    default: return '专业美业 / 形象造型'
  }
})

// 会员卡等级权益配置
const memberTierCards = ref([
  {
    code: 'REGULAR',
    name: '普卡会员',
    icon: '🥉',
    discountText: '享 9.8 折',
    desc: '进店开卡激活即享，享有常态海马体偏好记忆与消费积分礼遇。',
    perks: ['消费积分累积', '生日立减礼包', '海马体熟客档案'],
    bgClass: 'tier-bronze'
  },
  {
    code: 'SILVER',
    name: '银卡会员',
    icon: '🥈',
    discountText: '享 9.2 折',
    desc: '首充即享超值优惠，项目及商品均享 9.2 折特权。',
    perks: ['9.2折全单优惠', '专属茶饮服务', '优先免排队预约'],
    bgClass: 'tier-silver'
  },
  {
    code: 'GOLD',
    name: '金卡会员',
    icon: '🥇',
    discountText: '享 8.5 折',
    desc: '主力推荐尊享卡，享受 8.5 折与指定主理人专属服务。',
    perks: ['8.5折尊享特权', '积分1.5倍累加', '包厢免费升级', '技术总监点单'],
    bgClass: 'tier-gold'
  },
  {
    code: 'PLATINUM',
    name: '白金黑钻卡',
    icon: '💎',
    discountText: '享 7.5 ~ 8 折',
    desc: '至尊贵宾尊贵特权，全店最高折扣权益与私人管家一对一。',
    perks: ['至尊7.5折底价', '充值超额赠金', 'VIP专属包厢', '免费泊车洗车'],
    bgClass: 'tier-diamond'
  }
])

// 充多少送多少方案
const chargeOptions = ref<any[]>([
  { id: 1, title: '免充激活入会', principal: 0, gift: 0, badge: '新手开卡', levelName: '普卡会员' },
  { id: 2, title: '首充礼遇 ￥200', principal: 200, gift: 50, badge: '立赠50元', levelName: '银卡会员' },
  { id: 3, title: '尊享体验 ￥500', principal: 500, gift: 150, badge: '热销爆款', levelName: '金卡会员' },
  { id: 4, title: '白金储值 ￥1000', principal: 1000, gift: 350, badge: '超值特惠', levelName: '白金卡会员' }
])

// 熟客常态偏好池
const storePreferenceTags = ref<string[]>([
  '到店免推销',
  '服务水温偏温热',
  '偏爱安静独立包厢',
  '饮品偏好温柠檬水',
  '力度适中舒适',
  '定期会员保养体验',
  '洗护自备用品',
  '老友熟客专属招呼'
])

// 复制与拨打电话操作
const handleCopy = async (text: string, successTip: string) => {
  if (!text) return
  try {
    await navigator.clipboard.writeText(text)
    ElMessage.success(successTip)
  } catch {
    ElMessage.info(`内容：${text}`)
  }
}

const handleCallPhone = () => {
  if (displayPhone.value) {
    window.location.href = `tel:${displayPhone.value}`
  }
}

// 页面跳转
const handleGoMemberRegister = () => {
  router.push({
    path: '/member-register',
    query: { storeId: targetStoreId.value }
  })
}

const handleGoMemberPortal = () => {
  router.push({
    path: '/member-portal',
    query: { storeId: targetStoreId.value }
  })
}

const handleGoTableOrder = () => {
  router.push({
    path: '/table-order',
    query: { storeId: targetStoreId.value }
  })
}

// 挂载加载
onMounted(async () => {
  const sId = targetStoreId.value
  try {
    const res: any = await getStoreInfoApi(sId)
    if (res && res.storeName) {
      remoteStore.value = res
    }
  } catch (e) {
    console.log('获取远端门店信息回退本地资料', e)
  }

  try {
    const cfgRes: any = await getStoreRegisterConfigApi(sId)
    if (cfgRes) {
      if (Array.isArray(cfgRes.preferenceTags) && cfgRes.preferenceTags.length > 0) {
        storePreferenceTags.value = cfgRes.preferenceTags
      }
      if (Array.isArray(cfgRes.chargeOptions) && cfgRes.chargeOptions.length > 0) {
        chargeOptions.value = cfgRes.chargeOptions
      }
    }
  } catch {}
})
</script>

<style scoped>
.benefits-page-container {
  min-height: 100vh;
  background: #f1f5f9;
  padding: 16px 16px 90px;
  max-width: 680px;
  margin: 0 auto;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  box-sizing: border-box;
}

/* 顶部导航条 */
.top-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 14px;
  background: #ffffff;
  border-radius: 12px;
  margin-bottom: 12px;
  box-shadow: 0 2px 8px rgba(15, 23, 42, 0.05);
}
.brand-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
}
.brand-logo {
  font-size: 16px;
}
.live-status-chip {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 11.5px;
  color: #16a34a;
  background: #dcfce7;
  padding: 3px 8px;
  border-radius: 12px;
  font-weight: 600;
}
.status-dot {
  width: 6px;
  height: 6px;
  background: #16a34a;
  border-radius: 50%;
  animation: pulse 2s infinite;
}
@keyframes pulse {
  0% { opacity: 0.4; }
  50% { opacity: 1; }
  100% { opacity: 0.4; }
}

/* 门店 Hero 卡片 */
.store-hero-card {
  position: relative;
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 60%, #0369a1 100%);
  color: #ffffff;
  border-radius: 18px;
  padding: 24px 20px;
  margin-bottom: 14px;
  overflow: hidden;
  box-shadow: 0 10px 25px -5px rgba(15, 23, 42, 0.3);
}
.hero-bg-glow {
  position: absolute;
  top: -40px;
  right: -40px;
  width: 140px;
  height: 140px;
  background: radial-gradient(circle, rgba(56, 189, 248, 0.35) 0%, rgba(2, 132, 199, 0) 70%);
  border-radius: 50%;
}
.hero-content {
  position: relative;
  display: flex;
  align-items: center;
  gap: 16px;
}
.store-avatar-box {
  width: 64px;
  height: 64px;
  background: rgba(255, 255, 255, 0.12);
  backdrop-filter: blur(8px);
  border: 2px solid rgba(255, 255, 255, 0.25);
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  flex-shrink: 0;
}
.store-titles {
  flex: 1;
}
.store-main-name {
  font-size: 19px;
  font-weight: 800;
  letter-spacing: 0.3px;
  line-height: 1.35;
  margin-bottom: 6px;
}
.store-tags-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 6px;
}
.industry-chip {
  background: rgba(56, 189, 248, 0.2);
  color: #7dd3fc;
  font-size: 11px;
  padding: 2px 7px;
  border-radius: 6px;
  font-weight: 600;
}
.cert-chip {
  background: rgba(245, 158, 11, 0.2);
  color: #fde68a;
  font-size: 11px;
  padding: 2px 7px;
  border-radius: 6px;
}
.store-no-chip {
  background: rgba(255, 255, 255, 0.1);
  color: #cbd5e1;
  font-size: 11px;
  padding: 2px 6px;
  border-radius: 6px;
}
.store-slogan-text {
  font-size: 12px;
  color: #94a3b8;
  font-style: italic;
}

/* 通用区块卡片 */
.info-section-card {
  background: #ffffff;
  border-radius: 16px;
  padding: 18px;
  margin-bottom: 14px;
  box-shadow: 0 4px 12px rgba(15, 23, 42, 0.04);
}
.card-section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 4px;
}
.title-icon {
  font-size: 18px;
}
.section-intro {
  font-size: 12px;
  color: #64748b;
  margin-bottom: 14px;
  line-height: 1.5;
}

/* 联系方式列表 */
.contact-items-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.contact-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #f8fafc;
  padding: 12px 14px;
  border-radius: 12px;
  border: 1px solid #f1f5f9;
}
.c-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}
.c-icon {
  font-size: 22px;
}
.c-label {
  font-size: 11.5px;
  color: #64748b;
  margin-bottom: 2px;
}
.c-val {
  font-size: 14px;
  color: #1e293b;
  font-weight: 600;
}
.highlight-phone {
  color: #0284c7;
  font-size: 15px;
}
.mono {
  font-family: monospace;
}
.c-actions {
  display: flex;
  gap: 6px;
}

.contact-grid-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-top: 2px;
}
.sub-contact-box {
  background: #f8fafc;
  padding: 10px 12px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 8px;
  border: 1px solid #f1f5f9;
}
.sub-icon {
  font-size: 18px;
}
.sub-lbl {
  font-size: 11px;
  color: #64748b;
}
.sub-val {
  font-size: 12px;
  font-weight: 600;
  color: #1e293b;
}
.wifi-pass-btn {
  color: #0284c7;
  cursor: pointer;
  margin-left: 2px;
}

/* 会员卡等级网格 */
.member-tiers-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}
.tier-card-item {
  border-radius: 12px;
  padding: 14px;
  display: flex;
  flex-direction: column;
  color: #ffffff;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.08);
}
.tier-bronze {
  background: linear-gradient(135deg, #78350f, #92400e);
}
.tier-silver {
  background: linear-gradient(135deg, #475569, #64748b);
}
.tier-gold {
  background: linear-gradient(135deg, #b45309, #d97706);
}
.tier-diamond {
  background: linear-gradient(135deg, #0f172a, #334155);
}
.t-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
}
.t-name {
  font-size: 14px;
  font-weight: 800;
  display: flex;
  align-items: center;
  gap: 4px;
}
.t-discount-badge {
  background: rgba(255, 255, 255, 0.25);
  font-size: 11px;
  padding: 2px 6px;
  border-radius: 6px;
  font-weight: 700;
}
.t-desc {
  font-size: 11px;
  opacity: 0.9;
  line-height: 1.4;
  margin-bottom: 8px;
}
.t-perks {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-top: auto;
}
.perk-tag {
  background: rgba(255, 255, 255, 0.15);
  font-size: 9.5px;
  padding: 2px 5px;
  border-radius: 4px;
}

/* 充赠方案 */
.charge-options-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
  gap: 10px;
}
.charge-card-item {
  position: relative;
  background: #f8fafc;
  border: 1.5px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px 10px;
  text-align: center;
  transition: all 0.2s;
}
.charge-card-item:hover {
  border-color: #0284c7;
  transform: translateY(-2px);
}
.ch-badge {
  position: absolute;
  top: -8px;
  right: 6px;
  background: #ef4444;
  color: #ffffff;
  font-size: 9.5px;
  padding: 1px 6px;
  border-radius: 8px;
  font-weight: 700;
}
.ch-title {
  font-size: 12px;
  font-weight: 700;
  color: #334155;
  margin-bottom: 6px;
}
.ch-amount-box {
  color: #0284c7;
  font-weight: 800;
  margin-bottom: 4px;
}
.ch-amount-box .currency {
  font-size: 13px;
}
.ch-amount-box .amount-num {
  font-size: 22px;
}
.ch-gift-text {
  font-size: 11px;
  color: #dc2626;
  font-weight: 600;
  margin-bottom: 6px;
}
.ch-gift-text.free {
  color: #16a34a;
}
.ch-footer-level {
  font-size: 10px;
  color: #64748b;
  border-top: 1px dashed #e2e8f0;
  padding-top: 6px;
}

/* 熟客常态习惯云 */
.habit-tags-cloud {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.habit-cloud-tag {
  background: #eff6ff;
  color: #1e40af;
  border: 1px solid #bfdbfe;
  font-size: 12px;
  padding: 6px 12px;
  border-radius: 20px;
  font-weight: 600;
}

/* 直达通道 */
.hub-buttons-grid {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.hub-btn {
  display: flex;
  align-items: center;
  padding: 14px 16px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}
.primary-hub {
  background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(2, 132, 199, 0.25);
}
.primary-hub .h-sub {
  color: #bae6fd;
}
.normal-hub {
  background: #f8fafc;
  color: #1e293b;
  border: 1px solid #e2e8f0;
}
.normal-hub:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
}
.h-icon {
  font-size: 26px;
  margin-right: 14px;
}
.h-texts {
  flex: 1;
}
.h-main {
  font-size: 14.5px;
  font-weight: 700;
  margin-bottom: 2px;
}
.h-sub {
  font-size: 11.5px;
  color: #64748b;
}
.h-arrow {
  font-size: 16px;
  opacity: 0.7;
}

/* 底部版权 */
.footer-copyright {
  text-align: center;
  font-size: 11.5px;
  color: #94a3b8;
  margin-top: 20px;
  line-height: 1.6;
}
.sub-cr {
  font-size: 10.5px;
  color: #cbd5e1;
}

/* 底部吸底操作栏 */
.bottom-float-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-top: 1px solid #e2e8f0;
  padding: 10px 16px;
  display: flex;
  gap: 12px;
  max-width: 680px;
  margin: 0 auto;
  box-sizing: border-box;
  z-index: 100;
}
.float-btn-sub {
  width: 110px;
  font-weight: 600;
}
.float-btn-main {
  flex: 1;
  font-weight: 700;
  font-size: 14.5px;
  background: #0284c7;
  border-color: #0284c7;
}

@media (max-width: 480px) {
  .member-tiers-grid {
    grid-template-columns: 1fr;
  }
}
</style>
