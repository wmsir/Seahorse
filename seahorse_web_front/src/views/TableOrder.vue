<template>
  <div class="table-order-page">
    <!-- 移动端顶部顶栏 -->
    <header class="mobile-header">
      <div class="store-badge-row">
        <span class="store-logo-icon">🏯</span>
        <span class="store-title">{{ storeDisplayName }}</span>
        <el-tag size="small" type="success" effect="dark" class="room-status-pill">
          {{ isRoomOccupied ? '在场就餐 · 加点' : '现场空闲 · 扫码开台' }}
        </el-tag>
      </div>
      <div class="room-headline">
        <h1 class="room-name">{{ currentSpaceName }}</h1>
        <span class="room-code-tag">{{ currentSpaceCode }}</span>
        <span class="room-zone-sub">{{ currentSpaceZone }} · 可容纳 {{ currentSpaceCapacity }} 人</span>
      </div>

      <!-- 包厢低消状态通知栏 -->
      <div v-if="minConsumeAmount > 0" class="min-consume-banner">
        <div class="min-consume-left">
          <span>包厢最低消费：<b>￥{{ minConsumeAmount }}</b></span>
        </div>
        <div class="min-consume-right">
          <span v-if="projectedTotalAmount >= minConsumeAmount" class="reached-tag">
            ✓ 低消已达标 (预计 ￥{{ projectedTotalAmount.toFixed(2) }})
          </span>
          <span v-else class="short-tag">
            差 ￥{{ (minConsumeAmount - projectedTotalAmount).toFixed(2) }} 达标
          </span>
        </div>
      </div>

      <!-- 快捷呼叫前台/服务员工具条 -->
      <div class="service-quick-bar">
        <button class="svc-btn" @click="handleCallService('加茶水')">🍵 加茶水</button>
        <button class="svc-btn" @click="handleCallService('换骨碟/餐具')">🍽️ 换骨碟</button>
        <button class="svc-btn" @click="handleCallService('催单')">⚡ 催单</button>
        <button class="svc-btn" @click="handleCallService('呼叫服务员')">🛎️ 呼叫管家</button>
      </div>
    </header>

    <!-- 会员权益与身份识别卡片（自愿选填，绝不强制阻塞点餐） -->
    <section class="member-id-card">
      <div class="member-card-header" @click="toggleMemberSection">
        <div class="header-left">
          <span class="crown-icon">👑</span>
          <span class="card-prompt">
            {{ verifiedMember ? `已享会员价：${verifiedMember.name} (${verifiedMember.cardLevelName || 'VIP会员'})` : '输入手机号享会员专享折扣 / 储值买单 (选填)' }}
          </span>
        </div>
        <span class="expand-arrow">{{ showMemberInput ? '收起 ▲' : '展开 ▼' }}</span>
      </div>

      <div v-show="showMemberInput" class="member-input-body">
        <div v-if="!verifiedMember" class="member-search-box">
          <el-input
            v-model="customerPhoneInput"
            placeholder="请输入会员手机号享受折扣..."
            maxlength="11"
            clearable
            class="phone-input"
          >
            <template #prefix>
              <el-icon><Phone /></el-icon>
            </template>
            <template #append>
              <el-button type="primary" :loading="checkingMember" @click="handleCheckMember">
                识别会员
              </el-button>
            </template>
          </el-input>
          <div class="member-tip">
            💡 散客可直接挑选品项无需输入；老会员识别后全单自动享受折扣与积分沉淀。
          </div>
        </div>

        <!-- 识别成功的会员资产看板 -->
        <div v-else class="member-info-panel">
          <div class="m-info-top">
            <span class="m-vip-badge">{{ verifiedMember.cardLevelName || 'VIP尊贵会员' }}</span>
            <span class="m-phone">{{ verifiedMember.phone }}</span>
            <el-button size="small" link type="danger" @click="handleClearMember">切换/退出</el-button>
          </div>
          <div class="m-asset-row">
            <div class="asset-item">
              <span class="val">￥{{ Number(verifiedMember.balance || 0).toFixed(2) }}</span>
              <span class="lbl">储值本金</span>
            </div>
            <div class="asset-item">
              <span class="val">￥{{ Number(verifiedMember.rewardBalance || 0).toFixed(2) }}</span>
              <span class="lbl">赠送金</span>
            </div>
            <div class="asset-item">
              <span class="val">{{ verifiedMember.points || 0 }}</span>
              <span class="lbl">可用积分</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 包厢在场已点品项提醒与查看抽屉入口 (刷新后依然可见，多手机数据实时同步) -->
    <section v-if="orderedItemsList.length > 0" class="room-ordered-banner" @click="orderedDrawerVisible = true">
      <div class="ordered-banner-left">
        <span class="ordered-badge-icon">📋</span>
        <span class="ordered-banner-title">
          包厢已点 <b>{{ orderedItemsList.length }}</b> 项
        </span>
        <span class="ordered-sync-hint">🟢 实时同步</span>
      </div>
      <div class="ordered-banner-right">
        <span class="ordered-amount">累计 ￥{{ existingSessionAmount.toFixed(2) }}</span>
        <span class="ordered-action-link">查看已点明细 &gt;</span>
      </div>
    </section>

    <!-- 搜索与品项分类导航 -->
    <nav class="sticky-nav-bar">
      <div class="search-input-wrap">
        <el-input
          v-model="searchKeyword"
          placeholder="搜索菜品、服务、酒水..."
          clearable
          size="default"
          class="custom-search"
        >
          <template #prefix>
            <el-icon><Search /></el-icon>
          </template>
        </el-input>
      </div>

      <div class="category-tabs-scroll">
        <button
          v-for="cat in categoryList"
          :key="cat.key"
          class="cat-tab-btn"
          :class="{ active: currentCategory === cat.key }"
          @click="currentCategory = cat.key"
        >
          {{ cat.label }}
          <span v-if="getCategoryBadge(cat.key) > 0" class="cat-badge">
            {{ getCategoryBadge(cat.key) }}
          </span>
        </button>
      </div>
    </nav>

    <!-- 品项展示列表 -->
    <main class="products-list-view">
      <div v-if="filteredProducts.length === 0" class="empty-list-view">
        <el-empty description="当前分类暂无在售品项" :image-size="80" />
      </div>

      <div
        v-for="item in filteredProducts"
        :key="item.id"
        class="product-card"
        :class="{ 'has-selected': getItemCartQty(item.id) > 0 }"
      >
        <div class="prod-cover-box">
          <span class="prod-type-emoji">{{ getProductEmoji(item) }}</span>
        </div>
        <div class="prod-main-content">
          <div class="prod-title-line">
            <h3 class="prod-name">{{ item.name }}</h3>
            <el-tag size="small" :type="getProductTypeTag(item)" effect="plain">
              {{ getProductTypeLabel(item) }}
            </el-tag>
          </div>
          <div class="prod-desc-text">
            {{ item.categoryName || '招牌甄选' }} · {{ item.specification || '标准规格' }}
          </div>
          <div class="prod-pricing-row">
            <div class="price-wrap">
              <span class="currency">￥</span>
              <span class="amount">{{ getEffectivePrice(item).toFixed(2) }}</span>
              <span v-if="verifiedMember" class="member-price-tag">
                VIP专享 (原价￥{{ Number(item.price || 0).toFixed(2) }})
              </span>
              <span v-else-if="item.memberPrice" class="member-price-tag">
                VIP ￥{{ Number(item.memberPrice).toFixed(2) }}
              </span>
            </div>
            <div class="stepper-ctrl">
              <button
                v-if="getItemCartQty(item.id) > 0"
                class="step-btn minus"
                @click="changeQty(item, -1)"
              >-</button>
              <span v-if="getItemCartQty(item.id) > 0" class="step-num">
                {{ getItemCartQty(item.id) }}
              </span>
              <button class="step-btn plus" @click="changeQty(item, 1)">+</button>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- 底部悬浮购物车栏 -->
    <footer class="bottom-cart-bar">
      <div class="cart-left-summary" @click="toggleCartDrawer">
        <div class="cart-icon-bubble" :class="{ 'bounce': cartTotalQty > 0 }">
          <span class="cart-emoji">🛒</span>
          <span v-if="cartTotalQty > 0" class="cart-count-badge">{{ cartTotalQty }}</span>
        </div>
        <div class="cart-price-info">
          <div class="current-sum">
            <span class="curr-sign">￥</span>
            <span class="curr-val">{{ cartTotalAmount.toFixed(2) }}</span>
            <span v-if="verifiedMember && cartSavedAmount > 0" style="font-size: 11px; color: #fde047; margin-left: 6px; font-weight: 600;">
              已省￥{{ cartSavedAmount.toFixed(2) }}
            </span>
          </div>
          <div class="cart-hint-text">
            {{ isRoomOccupied ? `已开台在场累计 ￥${existingSessionAmount.toFixed(2)}` : '空闲包厢 · 落单自动开台' }}
          </div>
        </div>
      </div>

      <div class="cart-right-actions">
        <button
          v-if="orderedItemsList.length > 0"
          type="button"
          class="view-ordered-mini-btn"
          @click.stop="orderedDrawerVisible = true"
        >
          📋 已点({{ orderedItemsList.length }})
        </button>
        <button
          class="checkout-submit-btn"
          :disabled="cartTotalQty === 0 || submittingOrder"
          @click="handleOpenConfirmDrawer"
        >
          {{ submittingOrder ? '正在落单...' : (cartTotalQty > 0 ? `确认落单 (${cartTotalQty})` : '请先选品') }}
        </button>
      </div>
    </footer>

    <!-- 包厢已下单明细抽屉 (刷新后依然可见，多手机数据实时同步) -->
    <el-drawer
      v-model="orderedDrawerVisible"
      title="📋 本包厢在场已下单明细"
      direction="btt"
      size="75%"
      class="ordered-detail-drawer"
      :show-close="true"
    >
      <div class="ordered-drawer-inner">
        <div class="ordered-drawer-summary-card">
          <div class="ods-title">🏯 {{ currentSpaceName }} ({{ currentSpaceCode }})</div>
          <div class="ods-meta">
            <span>在场品项总计：<b>{{ orderedItemsList.length }} 项</b></span>
            <span>已入账消费：<b style="color: #e11d48; font-size: 16px;">￥{{ existingSessionAmount.toFixed(2) }}</b></span>
          </div>
          <div class="ods-tip">💡 数据已在同包厢所有点单手机端实时同步</div>
        </div>

        <div class="ordered-items-scroll">
          <div v-for="(it, idx) in orderedItemsList" :key="idx" class="ordered-item-card">
            <div class="oic-header">
              <span class="oic-name">{{ it.productName }}</span>
              <span class="oic-subtotal">￥{{ Number(it.subtotal || it.price * it.quantity).toFixed(2) }}</span>
            </div>
            <div class="oic-meta-row">
              <span class="oic-unit">￥{{ Number(it.price).toFixed(2) }} × {{ it.quantity }}</span>
              <el-tag size="small" :type="it.status === 'CANCELLED' ? 'info' : 'success'" effect="plain">
                {{ it.status === 'CANCELLED' ? '已退单' : '已接单制作' }}
              </el-tag>
            </div>
            <div v-if="it.modifiers" class="oic-modifiers">
              备注要求：{{ it.modifiers }}
            </div>
            <div v-if="it.createdAt" class="oic-time">
              下单时间：{{ typeof it.createdAt === 'string' ? it.createdAt.replace('T', ' ').substring(5, 16) : '' }}
            </div>
          </div>
        </div>

        <div class="ordered-drawer-footer">
          <el-button type="primary" style="width: 100%; border-radius: 20px; font-weight: 700;" @click="orderedDrawerVisible = false">
            继续加菜 / 返回点单
          </el-button>
        </div>
      </div>
    </el-drawer>

    <!-- 购物车抽屉 (查看与微调规格/做法) -->
    <el-drawer
      v-model="cartDrawerVisible"
      title="🛍️ 待落单清单与制作备注"
      direction="btt"
      size="70%"
      class="cart-detail-drawer"
      :show-close="true"
    >
      <div class="drawer-inner-content">
        <div class="drawer-items-list">
          <div v-for="item in cartItems" :key="item.id" class="drawer-item-row">
            <div class="d-item-main">
              <span class="d-item-name">{{ item.name }}</span>
              <span class="d-item-price">￥{{ (Number(item.price) * item.qty).toFixed(2) }}</span>
            </div>
            <!-- 做法/忌口规格输入 -->
            <div class="d-item-spec">
              <el-input
                v-model="item.modifiers"
                placeholder="口味做法/忌口 (如: 少冰/微辣/免香菜/香型)"
                size="small"
                clearable
              />
            </div>
            <div class="d-item-ctrl">
              <div class="stepper-ctrl">
                <button class="step-btn minus" @click="changeQty(item, -1)">-</button>
                <span class="step-num">{{ item.qty }}</span>
                <button class="step-btn plus" @click="changeQty(item, 1)">+</button>
              </div>
            </div>
          </div>
        </div>

        <!-- 开单补充信息 -->
        <div class="drawer-order-meta">
          <div class="meta-field-row">
            <span class="meta-label">到店人数：</span>
            <el-input-number v-model="orderDinersCount" :min="1" :max="30" size="small" />
          </div>
          <div class="meta-field-row">
            <span class="meta-label">整单备注：</span>
            <el-input
              v-model="orderGeneralNotes"
              placeholder="整单要求，如请尽快出餐或先上饮品"
              size="small"
            />
          </div>
        </div>

        <div class="drawer-footer-row">
          <div class="drawer-sum-box">
            <span>本次下单合计：</span>
            <b class="drawer-total-price">￥{{ cartTotalAmount.toFixed(2) }}</b>
          </div>
          <el-button
            type="primary"
            size="large"
            :loading="submittingOrder"
            class="drawer-confirm-btn"
            @click="handleSubmitOrder"
          >
            🚀 立即提交落单
          </el-button>
        </div>
      </div>
    </el-drawer>

    <!-- 下单成功全屏反馈弹窗 -->
    <el-dialog
      v-model="orderSuccessVisible"
      title="🎉 下单成功！"
      width="90%"
      align-center
      class="success-modal"
      :show-close="false"
    >
      <div class="success-content-wrap">
        <div class="success-icon-animated">✅</div>
        <h2 class="s-title">服务员/后厨已受理您的订单</h2>
        <p class="s-sub">已同步计入【{{ currentSpaceName }}】在场消费账单</p>

        <div class="s-summary-box">
          <div class="s-row">
            <span>所在包厢：</span>
            <b>{{ currentSpaceName }} ({{ currentSpaceCode }})</b>
          </div>
          <div class="s-row">
            <span>本次下单品项：</span>
            <b>{{ lastOrderItemsCount }} 项</b>
          </div>
          <div class="s-row">
            <span>本次消费金额：</span>
            <b class="s-highlight">￥{{ lastOrderAmount.toFixed(2) }}</b>
          </div>
          <div class="s-row">
            <span>包厢当前总消费：</span>
            <b class="s-highlight">￥{{ existingSessionAmount.toFixed(2) }}</b>
          </div>
          <div class="s-row" v-if="verifiedMember">
            <span>入账会员：</span>
            <span>{{ verifiedMember.name }} ({{ verifiedMember.phone }})</span>
          </div>
        </div>

        <p class="s-instruction">
          您可以在就餐或享受服务期间随时再次扫码加点，消费完成后可在离开时前往前台或让服务员呈送账单结账。
        </p>

        <div class="s-actions-box">
          <el-button type="primary" size="large" @click="handleContinueOrdering">
            继续浏览加点
          </el-button>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Search, Phone } from '@element-plus/icons-vue'
import {
  getProductsApi,
  getSpacesApi,
  getActiveSessionsApi,
  openSessionApi,
  appendItemsApi,
  searchMembersApi,
  getSessionDetailApi,
  callSpaceServiceApi,
  getStoreInfoApi
} from '../api'

const route = useRoute()

// ==============================================================================
// 1. 包厢与门店核心参数初始化
// ==============================================================================
const urlTenantId = (route.query.tenantId as string) || localStorage.getItem('seahorse_tenant_id') || 'T001'
const urlStoreId = (route.query.storeId as string) || localStorage.getItem('seahorse_store_id') || 'S001'
const urlSpaceId = ref<number | null>(route.query.spaceId ? Number(route.query.spaceId) : null)
const urlSpaceCode = (route.query.spaceCode as string) || 'R01'
const urlSpaceName = (route.query.spaceName as string) || '包厢'

// 确保在无登录态下，请求拦截器能够带上对应的租户与店铺 Header
if (urlTenantId) localStorage.setItem('seahorse_tenant_id', urlTenantId)
if (urlStoreId) localStorage.setItem('seahorse_store_id', urlStoreId)

const storeDisplayName = ref(localStorage.getItem('seahorse_store_name') || '海马智慧门店')
const currentSpaceName = ref(decodeURIComponent(urlSpaceName))
const currentSpaceCode = ref(urlSpaceCode)
const currentSpaceZone = ref('主服务区')
const currentSpaceCapacity = ref(4)
const minConsumeAmount = ref(0)
const isRoomOccupied = ref(false)
const currentSessionId = ref<number | null>(null)
const existingSessionAmount = ref(0)
const orderedItemsList = ref<any[]>([])
const orderedDrawerVisible = ref(false)

// ==============================================================================
// 2. 会员身份与特权识别 (自愿选填机制)
// ==============================================================================
const showMemberInput = ref(false)
const customerPhoneInput = ref('')
const checkingMember = ref(false)
const verifiedMember = ref<any>(null)

const toggleMemberSection = () => {
  showMemberInput.value = !showMemberInput.value
}

const handleCheckMember = async () => {
  const phone = customerPhoneInput.value.trim()
  if (!phone || phone.length < 11) {
    ElMessage.warning('请输入完整的11位手机号码')
    return
  }
  checkingMember.value = true
  try {
    const res: any = await searchMembersApi(phone, urlTenantId)
    const list = Array.isArray(res) ? res : (res?.data || [])
    if (list.length > 0) {
      verifiedMember.value = list[0]
      ElMessage.success(`🎉 识别成功！欢迎尊贵会员【${list[0].name}】光临！已享受会员权益。`)
    } else {
      ElMessage.info('未检索到此手机号会员档案，将作为现场尊贵散客继续为您点餐。')
    }
  } catch (err: any) {
    ElMessage.error(err?.message || '会员识别服务暂时繁忙')
  } finally {
    checkingMember.value = false
  }
}

const handleClearMember = () => {
  verifiedMember.value = null
  customerPhoneInput.value = ''
  ElMessage.info('已切换为现场散客模式')
}

// ==============================================================================
// 3. 呼叫前台/服务员管家轻功能 (实时通知登录端与播放声音)
// ==============================================================================
const callingService = ref(false)
const handleCallService = async (type: string) => {
  if (callingService.value) return
  callingService.value = true
  try {
    await callSpaceServiceApi({
      spaceId: urlSpaceId.value || undefined,
      spaceCode: currentSpaceCode.value,
      spaceName: currentSpaceName.value,
      serviceType: type,
      storeId: urlStoreId,
      tenantId: urlTenantId
    })
    ElMessage.success({
      message: `🛎️ 已成功向服务台呼叫【${type}】，包厢服务管家稍后即到！`,
      duration: 3500
    })
  } catch (err: any) {
    ElMessage.success({
      message: `🛎️ 已呼叫服务员【${type}】，稍后即到！`,
      duration: 3000
    })
  } finally {
    if (callServiceTimer) clearTimeout(callServiceTimer)
    callServiceTimer = setTimeout(() => {
      callingService.value = false
      callServiceTimer = null
    }, 1500)
  }
}
let callServiceTimer: ReturnType<typeof setTimeout> | null = null

// ==============================================================================
// 4. 品项库与分类过滤
// ==============================================================================
const searchKeyword = ref('')
const currentCategory = ref('ALL')
const catalogProducts = ref<any[]>([])

const categoryList = computed(() => {
  const cats = new Set<string>()
  catalogProducts.value.forEach(p => {
    const c = (p.categoryName || p.category || '').trim()
    if (c) cats.add(c)
  })
  const list = [{ key: 'ALL', label: '全部' }]
  cats.forEach(c => {
    list.push({ key: c, label: c })
  })
  return list
})

const isDrinkItem = (p: any) => {
  const text = ((p.name || '') + (p.categoryName || '')).toLowerCase()
  return text.includes('酒') || text.includes('茶') || text.includes('饮') || text.includes('咖啡') || text.includes('可乐') || text.includes('果汁')
}

const isFoodItem = (p: any) => {
  const text = ((p.name || '') + (p.categoryName || '')).toLowerCase()
  if (isDrinkItem(p)) return false
  return text.includes('餐') || text.includes('菜') || text.includes('食') || text.includes('面') || text.includes('饭') || text.includes('牛排') || text.includes('小吃') || text.includes('果盘') || text.includes('甜品')
}

const isServiceItem = (p: any) => {
  return p.productType === 'SERVICE' || (p.categoryName && p.categoryName.includes('服务'))
}

const getProductEmoji = (p: any) => {
  if (isDrinkItem(p)) return '🍷'
  if (isFoodItem(p)) return '🍲'
  if (isServiceItem(p)) return '💆'
  return '🛍️'
}

const getProductTypeLabel = (p: any) => {
  if (p.productType === 'SERVICE' || p.type === 'SERVICE') return '服务'
  if (isDrinkItem(p)) return '酒水'
  if (isFoodItem(p)) return '菜品'
  return p.categoryName || '商品'
}

const getProductTypeTag = (p: any) => {
  if (p.productType === 'SERVICE' || p.type === 'SERVICE') return 'success'
  if (isDrinkItem(p)) return 'warning'
  if (isFoodItem(p)) return 'danger'
  return 'info'
}

const filteredProducts = computed(() => {
  let list = catalogProducts.value
  if (currentCategory.value !== 'ALL') {
    list = list.filter(p => p.categoryName === currentCategory.value || p.category === currentCategory.value)
  }

  if (searchKeyword.value.trim()) {
    const kw = searchKeyword.value.trim().toLowerCase()
    list = list.filter(p =>
      (p.name && p.name.toLowerCase().includes(kw)) ||
      (p.categoryName && p.categoryName.toLowerCase().includes(kw))
    )
  }
  return list
})

const getCategoryBadge = (catKey: string) => {
  if (catKey === 'ALL') return cartTotalQty.value
  return cartItems.value
    .filter(it => (it.categoryName || '').trim() === catKey)
    .reduce((acc, it) => acc + it.qty, 0)
}

// ==============================================================================
// 5. 点单购物车与增减逻辑
// ==============================================================================
interface CartItem {
  id: number
  productId: number
  name: string
  price: number
  memberPrice?: number
  categoryName?: string
  productType?: string
  specification?: string
  qty: number
  modifiers: string
}

const getEffectivePrice = (prod: any): number => {
  const basePrice = Number(prod?.price || 0)
  if (!verifiedMember.value) return basePrice
  if (prod?.memberPrice && Number(prod.memberPrice) > 0) {
    return Number(prod.memberPrice)
  }
  return Number((basePrice * 0.9).toFixed(2))
}

const cartItems = ref<CartItem[]>([])
const cartDrawerVisible = ref(false)
const orderDinersCount = ref(2)
const orderGeneralNotes = ref('')
const submittingOrder = ref(false)

const getItemCartQty = (prodId: number) => {
  const found = cartItems.value.find(i => i.productId === prodId)
  return found ? found.qty : 0
}

const changeQty = (prod: any, delta: number) => {
  const found = cartItems.value.find(i => i.productId === prod.id)
  if (found) {
    found.qty += delta
    if (found.qty <= 0) {
      cartItems.value = cartItems.value.filter(i => i.productId !== prod.id)
    }
  } else if (delta > 0) {
    cartItems.value.push({
      id: prod.id,
      productId: prod.id,
      name: prod.name,
      price: Number(prod.price) || 0,
      memberPrice: prod.memberPrice ? Number(prod.memberPrice) : undefined,
      categoryName: prod.categoryName || prod.category,
      productType: prod.productType,
      specification: prod.specification,
      qty: 1,
      modifiers: ''
    })
  }
}

const cartTotalQty = computed(() => cartItems.value.reduce((s, it) => s + it.qty, 0))
const cartOriginalAmount = computed(() => cartItems.value.reduce((s, it) => s + (it.price * it.qty), 0))
const cartTotalAmount = computed(() => cartItems.value.reduce((s, it) => s + (getEffectivePrice(it) * it.qty), 0))
const cartSavedAmount = computed(() => Math.max(0, Number((cartOriginalAmount.value - cartTotalAmount.value).toFixed(2))))
const projectedTotalAmount = computed(() => existingSessionAmount.value + cartTotalAmount.value)

const toggleCartDrawer = () => {
  if (cartTotalQty.value > 0) {
    cartDrawerVisible.value = !cartDrawerVisible.value
  }
}

const handleOpenConfirmDrawer = () => {
  if (cartTotalQty.value === 0) return
  cartDrawerVisible.value = true
}

// ==============================================================================
// 6. 提交落单与账单闭环
// ==============================================================================
const orderSuccessVisible = ref(false)
const lastOrderAmount = ref(0)
const lastOrderItemsCount = ref(0)

const handleSubmitOrder = async () => {
  if (cartItems.value.length === 0) {
    ElMessage.warning('请先选购品项！')
    return
  }

  submittingOrder.value = true
  try {
    let sId = currentSessionId.value
    const prevSessionAmount = existingSessionAmount.value

    // 若包厢尚未开台，先自动开启在场会话
    if (!sId || !isRoomOccupied.value) {
      const custName = verifiedMember.value ? verifiedMember.value.name : `${currentSpaceName.value}贵宾`
      const custPhone = verifiedMember.value ? verifiedMember.value.phone : (customerPhoneInput.value || '13800000000')

      const openRes: any = await openSessionApi({
        spaceId: urlSpaceId.value || 1,
        memberId: verifiedMember.value?.id || null,
        customerName: custName,
        customerPhone: custPhone,
        guestCount: orderDinersCount.value || 2,
        notes: `[手机扫码自助开单] ${orderGeneralNotes.value || ''}`
      })
      const openedSession = openRes?.data || openRes
      sId = openedSession?.id
      currentSessionId.value = sId
      isRoomOccupied.value = true
    }

    // 将购物车内全部品项批量追加至会话
    const appendCmd = {
      sessionId: Number(sId),
      operatorType: 'CUSTOMER',
      operatorName: verifiedMember.value ? `顾客(${verifiedMember.value.name})` : '手机扫码客',
      items: cartItems.value.map(it => ({
        productId: it.productId,
        quantity: it.qty,
        modifiers: it.modifiers || orderGeneralNotes.value || '',
        performers: []
      }))
    }

    await appendItemsApi(appendCmd)

    // 记录本次下单数据供结果展示
    lastOrderAmount.value = cartTotalAmount.value
    lastOrderItemsCount.value = cartTotalQty.value
    existingSessionAmount.value = prevSessionAmount + cartTotalAmount.value

    // 清空本地购物车与关闭抽屉
    cartItems.value = []
    cartDrawerVisible.value = false
    orderSuccessVisible.value = true

    // 立即刷新本包厢已点明细与在场累计消费 (刷新后与多手机同步展示)
    await loadSessionDetail(Number(sId), false)
  } catch (err: any) {
    console.error('扫码点餐提交失败:', err)
    ElMessage.error(err?.message || '提交点餐失败，请稍后重试或呼叫服务员')
  } finally {
    submittingOrder.value = false
  }
}

const handleContinueOrdering = () => {
  orderSuccessVisible.value = false
}

// ==============================================================================
// 7. 加载在场已点品项明细与多手机实时同步
// ==============================================================================
const loadSessionDetail = async (sId: number, silent = false) => {
  try {
    const res: any = await getSessionDetailApi(sId, true)
    const detail = res?.data || res
    if (detail) {
      if (detail.session) {
        existingSessionAmount.value = Number(detail.session.payableAmount || detail.session.totalAmount || 0)
      }
      if (Array.isArray(detail.lineItems)) {
        const activeItems = detail.lineItems.filter((i: any) => i.status !== 'CANCELLED')
        const prevCount = orderedItemsList.value.length
        orderedItemsList.value = activeItems
        if (silent && prevCount > 0 && activeItems.length > prevCount) {
          ElMessage.info({
            message: `🔔 同桌新增了 ${activeItems.length - prevCount} 项点单，已实时同步！`,
            duration: 3000
          })
        }
      }
    }
  } catch (e) {
    // ignore
  }
}

const syncRoomSessionData = async (silent = true) => {
  try {
    const activeRes: any = await getActiveSessionsApi()
    const activeList = Array.isArray(activeRes) ? activeRes : (activeRes?.data || [])
    const sessionMatch = activeList.find((s: any) =>
      (urlSpaceId.value && Number(s.spaceId) === Number(urlSpaceId.value)) && s.status !== 'COMPLETED'
    )
    if (sessionMatch) {
      isRoomOccupied.value = true
      currentSessionId.value = sessionMatch.id
      await loadSessionDetail(sessionMatch.id, silent)
    } else {
      isRoomOccupied.value = false
      currentSessionId.value = null
      existingSessionAmount.value = 0
      orderedItemsList.value = []
    }
  } catch (e) {}
}

let syncTimer: any = null
const startSyncTimer = () => {
  stopSyncTimer()
  syncTimer = setInterval(async () => {
    if (document.hidden) return
    await syncRoomSessionData(true)
  }, 4000)
}

const stopSyncTimer = () => {
  if (syncTimer) {
    clearInterval(syncTimer)
    syncTimer = null
  }
}

const handleVisibilityChange = () => {
  if (!document.hidden) {
    syncRoomSessionData(true)
  }
}

// ==============================================================================
// 8. 页面数据初次装载
// ==============================================================================
const loadPageData = async () => {
  // 0. 动态拉取当前门店基础信息（保障手机首次扫码时展示真实门店名）
  try {
    const storeRes: any = await getStoreInfoApi(urlStoreId)
    const storeObj = storeRes?.data || storeRes
    if (storeObj && storeObj.storeName) {
      storeDisplayName.value = storeObj.storeName
      localStorage.setItem('seahorse_store_name', storeObj.storeName)
      if (storeObj.tenantId) {
        localStorage.setItem('seahorse_tenant_id', storeObj.tenantId)
      }
    }
  } catch (e) {}

  // 1. 获取包厢/空间信息
  try {
    const spacesRes: any = await getSpacesApi(urlStoreId)
    const spacesList = Array.isArray(spacesRes) ? spacesRes : (spacesRes?.data || [])
    const matchedSpace = spacesList.find((s: any) =>
      (urlSpaceId.value && Number(s.id) === Number(urlSpaceId.value)) ||
      (urlSpaceCode && s.spaceCode === urlSpaceCode)
    )
    if (matchedSpace) {
      urlSpaceId.value = matchedSpace.id
      currentSpaceName.value = matchedSpace.spaceName
      currentSpaceCode.value = matchedSpace.spaceCode
      currentSpaceZone.value = matchedSpace.floorZone || '主服务区'
      currentSpaceCapacity.value = matchedSpace.capacity || 4
      minConsumeAmount.value = Number(matchedSpace.minConsumeAmount || 0)
      if (matchedSpace.status === 'OCCUPIED') {
        isRoomOccupied.value = true
      }
    }
  } catch (e) {
    console.warn('获取包厢信息异常', e)
  }

  // 2. 检测当前包厢是否有活跃在场会话并加载已点品项 (刷新后保留展示)
  await syncRoomSessionData(false)

  // 3. 加载门店可供扫码选购的品项列表
  try {
    const prodRes: any = await getProductsApi()
    const prods = Array.isArray(prodRes) ? prodRes : (prodRes?.data || [])
    if (prods.length > 0) {
      catalogProducts.value = prods
    }
  } catch (e) {
    console.warn('加载商品列表异常', e)
  }
}

onMounted(() => {
  loadPageData()
  startSyncTimer()
  document.addEventListener('visibilitychange', handleVisibilityChange)
})

onUnmounted(() => {
  stopSyncTimer()
  if (callServiceTimer) {
    clearTimeout(callServiceTimer)
    callServiceTimer = null
  }
  document.removeEventListener('visibilitychange', handleVisibilityChange)
})
</script>

<style scoped>
/* 移动端沉浸式容器布局 */
.table-order-page {
  max-width: 520px;
  margin: 0 auto;
  min-height: 100vh;
  background-color: #f8fafc;
  display: flex;
  flex-direction: column;
  padding-bottom: 90px;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  color: #1e293b;
}

/* 顶部顶栏 */
.mobile-header {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
  color: #ffffff;
  padding: 16px 16px 14px 16px;
  border-bottom-left-radius: 16px;
  border-bottom-right-radius: 16px;
  box-shadow: 0 4px 16px rgba(15, 23, 42, 0.15);
}

.store-badge-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #94a3b8;
}

.store-title {
  font-weight: 500;
  color: #cbd5e1;
}

.room-status-pill {
  margin-left: auto;
  font-size: 11px;
}

.room-headline {
  margin-top: 10px;
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 8px;
}

.room-name {
  margin: 0;
  font-size: 22px;
  font-weight: 800;
  color: #ffffff;
}

.room-code-tag {
  background: rgba(255, 255, 255, 0.15);
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
  color: #38bdf8;
  font-weight: 600;
}

.room-zone-sub {
  font-size: 12px;
  color: #94a3b8;
}

/* 包厢低消提示栏 */
.min-consume-banner {
  margin-top: 12px;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 8px;
  padding: 8px 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
}

.reached-tag {
  color: #4ade80;
  font-weight: 700;
}

.short-tag {
  color: #fb923c;
  font-weight: 600;
}

/* 呼叫服务轻按钮组 */
.service-quick-bar {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  margin-top: 12px;
}

.svc-btn {
  background: rgba(255, 255, 255, 0.12);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: #f1f5f9;
  border-radius: 6px;
  padding: 6px 0;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.svc-btn:active {
  background: rgba(255, 255, 255, 0.25);
  transform: scale(0.96);
}

/* 会员身份与特权识别卡片 */
.member-id-card {
  margin: 12px 14px 0 14px;
  background: #ffffff;
  border-radius: 12px;
  border: 1px solid #fde68a;
  box-shadow: 0 2px 8px rgba(245, 158, 11, 0.08);
  overflow: hidden;
}

.member-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 14px;
  background: #fffbeb;
  cursor: pointer;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 6px;
}

.crown-icon {
  font-size: 16px;
}

.card-prompt {
  font-size: 12px;
  font-weight: 600;
  color: #92400e;
}

.expand-arrow {
  font-size: 11px;
  color: #b45309;
}

.member-input-body {
  padding: 12px 14px;
  background: #ffffff;
}

.phone-input {
  width: 100%;
}

.member-tip {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 6px;
  line-height: 1.4;
}

.member-info-panel {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.m-info-top {
  display: flex;
  align-items: center;
  gap: 8px;
}

.m-vip-badge {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 4px;
}

.m-phone {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
}

.m-asset-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  background: #f8fafc;
  padding: 8px;
  border-radius: 8px;
  text-align: center;
}

.asset-item {
  display: flex;
  flex-direction: column;
}

.asset-item .val {
  font-size: 13px;
  font-weight: 700;
  color: #e11d48;
}

.asset-item .lbl {
  font-size: 10px;
  color: #64748b;
  margin-top: 2px;
}

/* 吸顶导航栏 */
.sticky-nav-bar {
  position: sticky;
  top: 0;
  z-index: 50;
  background: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  padding: 10px 14px 4px 14px;
}

.custom-search {
  border-radius: 8px;
}

.category-tabs-scroll {
  display: flex;
  overflow-x: auto;
  gap: 8px;
  margin-top: 8px;
  padding-bottom: 6px;
  scrollbar-width: none;
}

.category-tabs-scroll::-webkit-scrollbar {
  display: none;
}

.cat-tab-btn {
  white-space: nowrap;
  background: #f1f5f9;
  border: 1px solid transparent;
  color: #475569;
  font-size: 13px;
  font-weight: 500;
  padding: 6px 14px;
  border-radius: 18px;
  cursor: pointer;
  position: relative;
  transition: all 0.2s;
}

.cat-tab-btn.active {
  background: #0f172a;
  color: #ffffff;
  font-weight: 600;
}

.cat-badge {
  background: #e11d48;
  color: #ffffff;
  font-size: 10px;
  border-radius: 10px;
  padding: 1px 5px;
  margin-left: 4px;
}

/* 品项卡片列表 */
.products-list-view {
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.empty-list-view {
  padding: 40px 0;
}

.product-card {
  display: flex;
  gap: 12px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 12px;
  transition: all 0.2s;
}

.product-card.has-selected {
  border-color: #38bdf8;
  background: #f0f9ff;
}

.prod-cover-box {
  width: 68px;
  height: 68px;
  background: #f1f5f9;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.prod-type-emoji {
  font-size: 32px;
}

.prod-main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.prod-title-line {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 6px;
}

.prod-name {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
  line-height: 1.3;
}

.prod-desc-text {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
}

.prod-pricing-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
}

.price-wrap {
  display: flex;
  align-items: baseline;
}

.currency {
  font-size: 12px;
  color: #e11d48;
  font-weight: 700;
}

.amount {
  font-size: 18px;
  color: #e11d48;
  font-weight: 800;
}

.member-price-tag {
  font-size: 11px;
  color: #b45309;
  background: #fef3c7;
  padding: 1px 6px;
  border-radius: 4px;
  margin-left: 6px;
  font-weight: 600;
}

/* 步进器按钮组 */
.stepper-ctrl {
  display: flex;
  align-items: center;
  gap: 8px;
}

.step-btn {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  font-weight: 700;
  transition: all 0.15s;
}

.step-btn.minus {
  background: #e2e8f0;
  color: #334155;
}

.step-btn.plus {
  background: #0f172a;
  color: #ffffff;
}

.step-btn:active {
  transform: scale(0.9);
}

.step-num {
  font-size: 14px;
  font-weight: 700;
  min-width: 18px;
  text-align: center;
  color: #0f172a;
}

/* 底部悬浮购物车栏 */
.bottom-cart-bar {
  position: fixed;
  bottom: 12px;
  left: 50%;
  transform: translateX(-50%);
  width: calc(100% - 24px);
  max-width: 496px;
  height: 60px;
  background: #0f172a;
  border-radius: 30px;
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.35);
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 10px 0 16px;
  z-index: 100;
}

.cart-left-summary {
  display: flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  flex: 1;
}

.cart-icon-bubble {
  position: relative;
  width: 42px;
  height: 42px;
  background: #1e293b;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #38bdf8;
}

.cart-emoji {
  font-size: 20px;
}

.cart-count-badge {
  position: absolute;
  top: -4px;
  right: -4px;
  background: #e11d48;
  color: #fff;
  font-size: 11px;
  font-weight: 800;
  padding: 1px 6px;
  border-radius: 10px;
}

.cart-price-info {
  display: flex;
  flex-direction: column;
}

.current-sum {
  color: #ffffff;
  font-weight: 800;
  display: flex;
  align-items: baseline;
}

.curr-sign {
  font-size: 13px;
}

.curr-val {
  font-size: 20px;
}

.cart-hint-text {
  font-size: 10px;
  color: #94a3b8;
}

.checkout-submit-btn {
  background: linear-gradient(135deg, #38bdf8 0%, #0284c7 100%);
  color: #ffffff;
  border: none;
  font-size: 14px;
  font-weight: 700;
  padding: 10px 20px;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s;
}

.checkout-submit-btn:disabled {
  background: #475569;
  color: #94a3b8;
  cursor: not-allowed;
}

/* 购物车抽屉样式 */
:deep(.cart-detail-drawer) {
  border-top-left-radius: 20px;
  border-top-right-radius: 20px;
}

.drawer-inner-content {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.drawer-items-list {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding-bottom: 12px;
}

.drawer-item-row {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.d-item-main {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.d-item-name {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}

.d-item-price {
  font-size: 14px;
  font-weight: 700;
  color: #e11d48;
}

.d-item-ctrl {
  display: flex;
  justify-content: flex-end;
}

.drawer-order-meta {
  border-top: 1px dashed #cbd5e1;
  padding: 12px 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.meta-field-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.meta-label {
  width: 75px;
  font-size: 13px;
  font-weight: 600;
  color: #334155;
  flex-shrink: 0;
}

.drawer-footer-row {
  border-top: 1px solid #e2e8f0;
  padding-top: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.drawer-total-price {
  font-size: 20px;
  color: #e11d48;
}

.drawer-confirm-btn {
  padding: 12px 24px;
  font-size: 15px;
  font-weight: 700;
  border-radius: 24px;
}

/* 成功反馈弹窗 */
.success-content-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 10px 0;
}

.success-icon-animated {
  font-size: 52px;
  margin-bottom: 8px;
}

.s-title {
  margin: 0;
  font-size: 19px;
  font-weight: 800;
  color: #0f172a;
}

.s-sub {
  margin: 4px 0 16px 0;
  font-size: 13px;
  color: #64748b;
}

.s-summary-box {
  width: 100%;
  background: #f8fafc;
  border-radius: 10px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  text-align: left;
  font-size: 13px;
}

.s-row {
  display: flex;
  justify-content: space-between;
  color: #334155;
}

.s-highlight {
  color: #e11d48;
  font-weight: 800;
}

.s-instruction {
  font-size: 12px;
  color: #94a3b8;
  margin: 16px 0;
  line-height: 1.5;
}

.s-actions-box {
  width: 100%;
}

.s-actions-box .el-button {
  width: 100%;
  border-radius: 22px;
}

/* 包厢在场已点品项栏 */
.room-ordered-banner {
  margin: 10px 14px 0 14px;
  background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
  border: 1px solid #bfdbfe;
  border-radius: 10px;
  padding: 10px 14px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(37, 99, 235, 0.08);
  transition: all 0.2s;
}

.room-ordered-banner:active {
  transform: scale(0.98);
}

.ordered-banner-left {
  display: flex;
  align-items: center;
  gap: 6px;
}

.ordered-badge-icon {
  font-size: 16px;
}

.ordered-banner-title {
  font-size: 13px;
  font-weight: 700;
  color: #1e3a8a;
}

.ordered-sync-hint {
  font-size: 10px;
  color: #2563eb;
  background: #fff;
  padding: 1px 6px;
  border-radius: 10px;
  font-weight: 600;
}

.ordered-banner-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ordered-amount {
  font-size: 13px;
  font-weight: 700;
  color: #e11d48;
}

.ordered-action-link {
  font-size: 12px;
  color: #1d4ed8;
  font-weight: 600;
}

/* 底部已点按钮 */
.view-ordered-mini-btn {
  background: rgba(255, 255, 255, 0.15);
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: #ffffff;
  font-size: 12px;
  font-weight: 600;
  padding: 8px 12px;
  border-radius: 18px;
  cursor: pointer;
  margin-right: 8px;
  white-space: nowrap;
  transition: all 0.2s;
}

.view-ordered-mini-btn:active {
  background: rgba(255, 255, 255, 0.3);
}

/* 已点明细抽屉 */
.ordered-drawer-inner {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.ordered-drawer-summary-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 12px 14px;
  margin-bottom: 12px;
}

.ods-title {
  font-size: 15px;
  font-weight: 800;
  color: #0f172a;
}

.ods-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 6px;
  font-size: 13px;
  color: #334155;
}

.ods-tip {
  font-size: 11px;
  color: #059669;
  margin-top: 6px;
  font-weight: 500;
}

.ordered-items-scroll {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding-bottom: 14px;
}

.ordered-item-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.oic-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.oic-name {
  font-size: 14px;
  font-weight: 700;
  color: #1e293b;
}

.oic-subtotal {
  font-size: 14px;
  font-weight: 800;
  color: #e11d48;
}

.oic-meta-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #64748b;
}

.oic-modifiers {
  font-size: 11px;
  color: #d97706;
  background: #fffbeb;
  padding: 2px 6px;
  border-radius: 4px;
  margin-top: 2px;
}

.oic-time {
  font-size: 10px;
  color: #94a3b8;
}

.ordered-drawer-footer {
  border-top: 1px solid #e2e8f0;
  padding-top: 12px;
}
</style>
