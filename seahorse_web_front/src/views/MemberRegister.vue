<template>
  <div class="member-register-container">
    <div class="member-register-card">
      <!-- 门店顶头招牌展示 -->
      <div class="store-banner">
        <div class="store-logo" style="background:transparent;box-shadow:none;padding:0;"><svg viewBox="0 0 64 64" width="38" height="38" style="flex-shrink:0;filter:drop-shadow(0 2px 6px rgba(14,165,233,0.35));" xmlns="http://www.w3.org/2000/svg">
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
</svg></div>
        <div class="store-info">
          <div class="store-name-row">
            <span class="store-name">{{ currentStore?.storeName || '海马智慧门店' }}</span>
            <el-tag size="small" :type="currentStore?.isHeadquarter ? 'danger' : 'success'" effect="plain">
              {{ currentStore?.industryCategoryName || formatIndustryName(currentStore?.industry) || (currentStore?.isHeadquarter ? '旗舰总店' : '品牌门店') }}
            </el-tag>
          </div>
          <div class="store-sub">
            <span>📍 {{ currentStore?.address || '智慧商业街区' }}</span>
            <span style="margin: 0 4px;">·</span>
            <span>⏰ 营业时间: {{ currentStore?.businessHours || currentStore?.openTime || '09:00-22:00' }}</span>
            <template v-if="currentStore?.phone">
              <span style="margin: 0 4px;">·</span>
              <span>📞 {{ currentStore.phone }}</span>
            </template>
          </div>
        </div>
      </div>

      <!-- 顶部独立页面标题栏 -->
      <div class="portal-header-bar">
        <div class="ph-title-wrap">
          <span class="ph-icon">🌸</span>
          <span class="ph-title">顾客会员自助开卡</span>
        </div>
        <div class="ph-subtitle">尊享海马体常态记忆服务 · 到店消费免报偏好 · 积分储值礼遇</div>
      </div>

      <div class="form-container">
        <!-- 成功激活卡片 -->
        <div v-if="memberSuccess" class="success-result-box">
          <div class="success-icon">🎉</div>
          <div class="success-title">恭喜您成为【{{ currentStore?.storeName }}】尊贵会员！</div>
          <div class="success-desc">您的会员档案与海马体记忆偏好已自动同步入库。</div>

          <div class="member-card-preview" :class="cardThemeClass">
            <div class="m-card-top">
              <span class="m-brand">{{ cardBrandTitle }}</span>
              <span class="m-level">{{ cardLevelBadge.icon }} {{ cardLevelBadge.name }}</span>
            </div>
            <div class="m-card-no">{{ createdMember?.memberNo || displayMemberNo }}</div>
            <div class="m-card-bottom">
              <div>
                <div class="m-owner">{{ createdMember?.name || memberForm.name }}</div>
                <div class="m-store">归属门店: {{ currentStore?.storeName }}</div>
              </div>
              <div class="m-balance">
                <div class="m-bal-val">￥{{ (memberForm.chargeOption?.principal || 0) + (memberForm.chargeOption?.gift || 0) }}</div>
                <div class="m-bal-lbl">开卡入账金额</div>
              </div>
            </div>
          </div>

          <div class="welcome-privileges">
            <div class="p-item">🎁 已自动获赠 <strong>100 初始积分</strong></div>
            <div class="p-item" v-if="memberForm.chargeOption?.gift > 0">
              💰 已赠送 <strong>￥{{ memberForm.chargeOption.gift }} 储值奖励金</strong>
            </div>
            <div class="p-item" v-if="memberForm.habits && memberForm.habits.length > 0">
              🧠 专属“海马体”常态偏好已永久归档：
              <div style="margin-top: 6px; display: flex; flex-wrap: wrap; gap: 6px;">
                <el-tag v-for="h in memberForm.habits" :key="h" size="small" type="success" effect="plain">{{ h }}</el-tag>
              </div>
            </div>
            <div class="p-item" v-else>
              🧠 专属“海马体”常态偏好已永久建档，到店服务秒享熟客礼遇
            </div>
          </div>

          <div class="result-actions">
            <el-button type="primary" size="large" class="w-full" @click="handleGoMemberPortal">
              查看我的会员中心与资产 👉
            </el-button>
            <el-button size="default" style="margin-top: 10px;" @click="resetMemberForm">
              继续为家人/朋友开卡
            </el-button>
          </div>
        </div>

        <!-- 填写注册表单 -->
        <div v-else>
          <div class="mode-tip-banner">
            <span class="t-icon">✨</span>
            <div class="t-text">
              <strong>入会尊享好礼：</strong>无需实体卡，凭手机号消费积分、优先排号、尊享海马体记忆专属服务！
            </div>
          </div>

          <el-form :model="memberForm" label-position="top" class="custom-form">
            <el-form-item label="手机号码 (用于到店识别会员身份与积分)" required>
              <el-input
                v-model="memberForm.phone"
                placeholder="请输入11位手机号码"
                prefix-icon="Iphone"
                maxlength="11"
              />
            </el-form-item>

            <el-row :gutter="12">
              <el-col :span="14">
                <el-form-item label="您的称呼 / 姓名" required>
                  <el-input v-model="memberForm.name" placeholder="例如：林女士 / 王先生" prefix-icon="User" />
                </el-form-item>
              </el-col>
              <el-col :span="10">
                <el-form-item label="性别">
                  <el-select v-model="memberForm.gender" style="width: 100%;">
                    <el-option label="女士" value="FEMALE" />
                    <el-option label="先生" value="MALE" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>

            <el-form-item label="您的生日 (用于每年生日月自动派发专属礼券与双倍积分)">
              <el-date-picker
                v-model="memberForm.birthday"
                type="date"
                placeholder="请选择您的出生日期"
                style="width: 100%;"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
              />
            </el-form-item>

            <!-- 门店自主配置的个人常态偏好勾选 (免写死) -->
            <el-form-item label="🧠 个人常态偏好 (海马体将为您自动记住，免重复告知技师)">
              <div v-if="storePreferenceTags.length > 0" class="habit-tags-box">
                <span
                  v-for="tag in storePreferenceTags"
                  :key="tag"
                  class="habit-tag"
                  :class="{ selected: memberForm.habits.includes(tag) }"
                  @click="toggleHabit(tag)"
                >
                  {{ tag }}
                </span>
              </div>
              <div style="margin-top: 8px; display: flex; gap: 8px; width: 100%;">
                <el-input
                  v-model="customHabitInput"
                  placeholder="其他偏好说明 (如：洗头水温偏热、偏爱日式剪发，输入后点击添加)"
                  size="small"
                  @keyup.enter="handleAddCustomHabit"
                />
                <el-button size="small" type="primary" plain @click="handleAddCustomHabit">添加</el-button>
              </div>
            </el-form-item>

            <!-- 意向开卡首充方案 (由门店自主配置修改，充多少送多少) -->
            <el-form-item label="💳 开卡首充与专属充赠方案 (充多少送多少，可选)">
              <div class="charge-options-grid">
                <div
                  v-for="opt in chargeOptions"
                  :key="opt.id"
                  class="charge-opt-card"
                  :class="{ selected: memberForm.chargeOption?.id === opt.id }"
                  @click="memberForm.chargeOption = opt"
                >
                  <div class="opt-title">{{ opt.title }}</div>
                  <div class="opt-price">￥{{ opt.principal }}</div>
                  <div class="opt-badge" v-if="opt.badge">{{ opt.badge }}</div>
                </div>
              </div>
            </el-form-item>

            <div class="agreement-box">
              <el-checkbox v-model="memberForm.agree">已阅读并同意《会员服务章程与隐私保障协议》</el-checkbox>
            </div>

            <el-button
              type="primary"
              size="large"
              :loading="submittingMember"
              class="w-full submit-btn"
              @click="handleSubmitMember"
            >
              {{ (memberForm.chargeOption?.principal || 0) > 0 ? `去支付 ￥${memberForm.chargeOption.principal} 并开卡` : '立即激活成为会员' }}
            </el-button>
          </el-form>
        </div>
      </div>

      <!-- 底部安全与版权 -->
      <div class="portal-footer">
        <span>✦ 海马智慧门店 · “海马会员，记住每位好客。”</span>
      </div>
    </div>

    <!-- 模拟在线收银台与首充支付弹窗 -->
    <el-dialog
      v-model="openPayDialog"
      title="💳 海马在线收银台 · 开卡首充支付"
      width="460px"
      destroy-on-close
    >
      <div style="padding: 10px 4px;">
        <div style="background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%); border: 1px solid #bbf7d0; border-radius: 10px; padding: 16px; text-align: center; margin-bottom: 16px;">
          <div style="font-size: 13px; color: #166534; margin-bottom: 4px;">开卡首充实付金额</div>
          <div style="font-size: 32px; font-weight: 800; color: #15803d; line-height: 1.2;">
            <span style="font-size: 20px;">￥</span>{{ memberForm.chargeOption?.principal || 0 }}
          </div>
          <div style="font-size: 12px; color: #059669; margin-top: 6px;" v-if="memberForm.chargeOption?.gift > 0">
            🎁 享受立赠福利：立赠 <b>￥{{ memberForm.chargeOption.gift }}</b> · 实际入账 <b>￥{{ (memberForm.chargeOption.principal || 0) + (memberForm.chargeOption.gift || 0) }}</b>
          </div>
        </div>

        <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px 14px; margin-bottom: 16px; font-size: 13px;">
          <div style="display: flex; justify-content: space-between; margin-bottom: 6px;">
            <span style="color: #64748b;">收款门店：</span>
            <span style="font-weight: 600; color: #1e293b;">{{ currentStore?.storeName || '当前门店' }}</span>
          </div>
          <div style="display: flex; justify-content: space-between; margin-bottom: 6px;">
            <span style="color: #64748b;">所选方案：</span>
            <span style="font-weight: 600; color: #0284c7;">{{ memberForm.chargeOption?.title }}</span>
          </div>
          <div style="display: flex; justify-content: space-between;">
            <span style="color: #64748b;">开卡会员：</span>
            <span style="font-weight: 600; color: #1e293b;">{{ memberForm.name }} ({{ memberForm.phone }})</span>
          </div>
        </div>

        <div style="margin-bottom: 14px;">
          <div style="font-size: 13px; font-weight: 600; color: #1e293b; margin-bottom: 8px;">选择支付方式：</div>
          <div style="display: flex; flex-direction: column; gap: 8px;">
            <div
              style="border: 1.5px solid; border-radius: 8px; padding: 10px 14px; display: flex; justify-content: space-between; align-items: center; cursor: pointer; transition: all 0.2s;"
              :style="{ borderColor: selectedPaymentMethod === 'WECHAT' ? '#10b981' : '#e2e8f0', background: selectedPaymentMethod === 'WECHAT' ? '#f0fdf4' : '#fff' }"
              @click="selectedPaymentMethod = 'WECHAT'"
            >
              <div style="display: flex; align-items: center; gap: 10px;">
                <span style="font-size: 22px;">💬</span>
                <div>
                  <div style="font-size: 14px; font-weight: 600; color: #1e293b;">微信支付</div>
                  <div style="font-size: 11.5px; color: #64748b;">微信安全收银通道</div>
                </div>
              </div>
              <el-radio v-model="selectedPaymentMethod" value="WECHAT">{{ '' }}</el-radio>
            </div>

            <div
              style="border: 1.5px solid; border-radius: 8px; padding: 10px 14px; display: flex; justify-content: space-between; align-items: center; cursor: pointer; transition: all 0.2s;"
              :style="{ borderColor: selectedPaymentMethod === 'ALIPAY' ? '#0284c7' : '#e2e8f0', background: selectedPaymentMethod === 'ALIPAY' ? '#f0f9ff' : '#fff' }"
              @click="selectedPaymentMethod = 'ALIPAY'"
            >
              <div style="display: flex; align-items: center; gap: 10px;">
                <span style="font-size: 22px;">🪙</span>
                <div>
                  <div style="font-size: 14px; font-weight: 600; color: #1e293b;">支付宝</div>
                  <div style="font-size: 11.5px; color: #64748b;">花呗、余额宝与绑定银联卡</div>
                </div>
              </div>
              <el-radio v-model="selectedPaymentMethod" value="ALIPAY">{{ '' }}</el-radio>
            </div>
          </div>
        </div>

        <div style="background: #fffbeb; border: 1px solid #fef3c7; border-radius: 6px; padding: 8px 12px; font-size: 11.5px; color: #b45309; line-height: 1.45;">
          ⚡ <b>模拟实操支付说明：</b>开卡涉及充值金额，需走真实支付流程。当前处于演示实操模式，点击确认后将模拟调起支付收银网关完成资金入账与真实凭据写入。
        </div>
      </div>

      <template #footer>
        <div style="display: flex; gap: 10px;">
          <el-button @click="openPayDialog = false" :disabled="paying">取消</el-button>
          <el-button
            type="primary"
            style="flex: 1;"
            :loading="paying"
            @click="handleConfirmSimulatePay"
          >
            {{ paying ? '正在调起安全支付网关...' : `确认模拟支付 ￥${memberForm.chargeOption?.principal || 0}` }}
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSystemDataStore } from '../stores/systemDataStore'
import { useStoreConfig } from '../stores/store'
import {
  registerMemberApi,
  savePreferenceApi,
  getStoreInfoApi,
  getStoreRegisterConfigApi
} from '../api'
import { ElMessage } from 'element-plus'

const route = useRoute()
const router = useRouter()
const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()

const targetStoreId = ref<string>('S001')
const remoteStoreInfo = ref<any>(null)

const currentStore = computed(() => {
  if (remoteStoreInfo.value) {
    return remoteStoreInfo.value
  }
  return systemData.stores.find(s => s.storeId === targetStoreId.value) ||
         (systemData.stores.length > 0 ? systemData.stores[0] : null)
})

// 顾客会员自助开卡状态
const memberSuccess = ref(false)
const submittingMember = ref(false)
const createdMember = ref<any>(null)

const cardEmoji = computed(() => {
  const ind = (currentStore.value?.industry || remoteStoreInfo.value?.industry || storeConfig.industry || '').toUpperCase()
  const name = currentStore.value?.storeName || ''
  if (ind === 'AUTO' || name.includes('车') || name.includes('动力')) return '🚗'
  if (ind === 'RESTAURANT' || name.includes('餐') || name.includes('食') || name.includes('火锅')) return '🍲'
  if (ind === 'RETAIL' || name.includes('零售') || name.includes('甄选') || name.includes('美学')) return '🛍️'
  if (ind === 'FOOT_SPA' || name.includes('足') || name.includes('SPA')) return '💆‍♀️'
  if (ind === 'TEA_HOUSE' || name.includes('茶') || name.includes('棋牌')) return '🍵'
  if (ind === 'PET' || name.includes('宠')) return '🐾'
  if (ind === 'BEAUTY' || name.includes('美业') || name.includes('造型')) return '💇‍♀️'
  return '💳'
})

const cardBrandTitle = computed(() => {
  const sName = currentStore.value?.storeName
  if (sName) {
    return `${cardEmoji.value} ${sName} · 会员卡`
  }
  return `${cardEmoji.value} 尊享VIP会员卡`
})

const cardLevelBadge = computed(() => {
  const lvl = createdMember.value?.level || (
    (memberForm.value.chargeOption?.principal >= 1000) ? 'PLATINUM' :
    (memberForm.value.chargeOption?.principal >= 500) ? 'GOLD' :
    (memberForm.value.chargeOption?.principal >= 200) ? 'SILVER' : 'REGULAR'
  )
  switch (lvl) {
    case 'DIAMOND': return { icon: '💎', name: createdMember.value?.levelName || '黑钻至尊卡' }
    case 'PLATINUM': return { icon: '✨', name: createdMember.value?.levelName || '白金卡会员' }
    case 'GOLD': return { icon: '👑', name: createdMember.value?.levelName || '金卡会员' }
    case 'SILVER': return { icon: '🥈', name: createdMember.value?.levelName || '银卡会员' }
    default: return { icon: '🎫', name: createdMember.value?.levelName || '普卡会员' }
  }
})

const cardThemeClass = computed(() => {
  const lvl = createdMember.value?.level || (
    (memberForm.value.chargeOption?.principal >= 1000) ? 'PLATINUM' :
    (memberForm.value.chargeOption?.principal >= 500) ? 'GOLD' :
    (memberForm.value.chargeOption?.principal >= 200) ? 'SILVER' : 'REGULAR'
  )
  if (lvl === 'DIAMOND') return 'card-diamond'
  if (lvl === 'PLATINUM') return 'card-platinum'
  if (lvl === 'GOLD') return 'card-gold'
  if (lvl === 'SILVER') return 'card-silver'
  return 'card-regular'
})

const displayMemberNo = computed(() => {
  if (createdMember.value?.memberNo) return createdMember.value.memberNo
  const today = new Date().toISOString().slice(0, 10).replace(/-/g, '')
  return `HM${today}0001`
})

// 门店自主配置：偏好标签与首充方案 (充多少送多少)
const storePreferenceTags = ref<string[]>([])
const chargeOptions = ref<any[]>([])
const customHabitInput = ref('')

// 模拟支付收银台状态
const openPayDialog = ref(false)
const paying = ref(false)
const selectedPaymentMethod = ref<'WECHAT' | 'ALIPAY'>('WECHAT')

const formatIndustryName = (ind?: string) => {
  if (!ind) return ''
  switch (ind.toUpperCase()) {
    case 'RESTAURANT': return '餐饮轻食/正餐'
    case 'BEAUTY': return '美容美发美甲'
    case 'AUTO': return '汽车养护维修'
    case 'FOOT_SPA': return '足道养生/SPA'
    case 'TEA_HOUSE': return '茶座休闲/棋牌'
    case 'PET': return '宠物健康生活馆'
    case 'RETAIL': return '专营零售'
    default: return ind
  }
}

const getDefaultPrefTags = (industry?: string) => {
  const ind = (industry || remoteStoreInfo.value?.industry || route.query.industry || storeConfig.industry || 'RESTAURANT').toUpperCase()
  if (ind === 'BEAUTY') {
    return ['发质细软', '敏感头皮', '偏爱自然修剪', '偏爱冷色调烫染', '喜好安静免推销', '定期头皮SPA', '洗头水温偏热', '饮品偏好温柠檬水']
  } else if (ind === 'RESTAURANT') {
    return ['微辣免葱', '少盐少油少糖', '偏爱安静包厢', '不吃香菜姜蒜', '常带儿童就餐', '自备酒水', '海鲜不过敏', '米饭稍软']
  } else if (ind === 'FOOT_SPA') {
    return ['力度偏重', '力度适中', '中药足浴包偏好', '精油开背偏好', '喜好安静免推销', '肩颈重点加强', '修脚去死皮偏好', '饮品偏好红枣枸杞茶']
  } else if (ind === 'AUTO') {
    return ['全合成机油偏好', '定期深度底盘检查', '车内高温桑拿除味', '原厂配件优先', '空调滤芯定期换', '轮胎动平衡常检', '偏好周末维保', '洗车需深度除尘']
  } else if (ind === 'TEA_HOUSE') {
    return ['偏爱生普/白茶', '水温要求沸水', '偏爱安静雅间', '自备茶叶仅需茶具', '需要商务投影', '茶点少糖偏好', '常备坚果果盘', '喜好棋牌娱乐']
  } else if (ind === 'PET') {
    return ['胆小敏感易应激', '皮肤敏感需低敏香波', '拒绝强行烘干箱', '洗澡需剪指甲', '定期驱虫', '喜好零食奖励', '长毛易打结需开结', '自备洗护专用品']
  } else {
    return ['偏好有机绿色无公害', '精致礼盒送礼包装', '积分抵现结算优先', '新品尝鲜品鉴体验', '少塑环保包装', '定期促销推送偏好', '冷链保温配送', '喜欢大份家庭装']
  }
}

const getDefaultChargeOptions = () => [
  { id: 1, title: '基础免费入会', principal: 0, gift: 0, badge: '免充激活', levelCode: 'REGULAR', levelName: '普卡会员' },
  { id: 2, title: '首充礼遇 ￥200', principal: 200, gift: 50, badge: '立赠50元', levelCode: 'SILVER', levelName: '银卡会员' },
  { id: 3, title: '尊享体验 ￥500', principal: 500, gift: 150, badge: '热销推荐', levelCode: 'GOLD', levelName: '金卡会员' },
  { id: 4, title: '白金储值 ￥1000', principal: 1000, gift: 350, badge: '超值爆款', levelCode: 'PLATINUM', levelName: '白金卡会员' }
]

const memberForm = ref({
  phone: '',
  name: '',
  gender: 'FEMALE' as 'FEMALE' | 'MALE',
  birthday: '',
  habits: [] as string[],
  chargeOption: null as any,
  agree: true
})

const loadStoreRegisterConfig = async () => {
  const storeId = targetStoreId.value

  // 1. 获取远程真实门店基础信息（多端微信/移动扫码一致）
  try {
    const infoRes = (await getStoreInfoApi(storeId)) as any
    const infoData = (infoRes && infoRes.data) ? infoRes.data : infoRes
    if (infoData && (infoData.storeName || infoData.storeId)) {
      remoteStoreInfo.value = {
        ...(remoteStoreInfo.value || {}),
        ...infoData
      }
    }
  } catch (e) {
    console.warn('获取远程门店信息失败', e)
  }

  // 2. 获取该门店在云端持久化配置的专属偏好与首充充赠方案 (由商家在后台自主定制)
  let fetchedRemoteConfig = false
  const currentInd = remoteStoreInfo.value?.industry || (route.query.industry ? String(route.query.industry) : undefined)
  try {
    const cfgRes = (await getStoreRegisterConfigApi(storeId, currentInd)) as any
    const cfgData = (cfgRes && cfgRes.data) ? cfgRes.data : cfgRes
    if (cfgData && (cfgData.preferenceTags || cfgData.chargeOptions)) {
      const { preferenceTags, chargeOptions: remoteOpts } = cfgData
      let pTags: any = null
      let cOpts: any = null
      if (typeof preferenceTags === 'string') {
        try { pTags = JSON.parse(preferenceTags) } catch {}
      } else if (Array.isArray(preferenceTags)) {
        pTags = preferenceTags
      }

      if (typeof remoteOpts === 'string') {
        try { cOpts = JSON.parse(remoteOpts) } catch {}
      } else if (Array.isArray(remoteOpts)) {
        cOpts = remoteOpts
      }

      if (Array.isArray(pTags)) {
        storePreferenceTags.value = pTags
        fetchedRemoteConfig = true
      }
      if (Array.isArray(cOpts) && cOpts.length > 0) {
        chargeOptions.value = cOpts
        fetchedRemoteConfig = true
      }
    }
  } catch (e) {
    console.warn('获取云端门店开卡方案失败，准备回退', e)
  }

  // 3. 若云端网络异常未能获取，读取本地缓存
  if (!fetchedRemoteConfig) {
    const key = `seahorse_store_register_config_${storeId}`
    const raw = localStorage.getItem(key)
    if (raw) {
      try {
        const parsed = JSON.parse(raw)
        if (Array.isArray(parsed.preferenceTags)) {
          storePreferenceTags.value = parsed.preferenceTags
        }
        if (Array.isArray(parsed.chargeOptions) && parsed.chargeOptions.length > 0) {
          chargeOptions.value = parsed.chargeOptions
        }
      } catch {}
    }
  }

  if (chargeOptions.value.length === 0) {
    chargeOptions.value = getDefaultChargeOptions()
  }

  if (chargeOptions.value.length > 0) {
    memberForm.value.chargeOption = chargeOptions.value[0]
  }
}

onMounted(() => {
  if (route.query.storeId) {
    targetStoreId.value = String(route.query.storeId)
  } else {
    targetStoreId.value = storeConfig.currentStoreId || 'S001'
  }

  // 首屏瞬时直显：利用 URL 参数避免因无商户本地缓存或网络延迟导致的闪烁
  if (route.query.storeName || route.query.industry || route.query.address || route.query.phone || route.query.businessHours) {
    remoteStoreInfo.value = {
      storeId: targetStoreId.value,
      storeName: route.query.storeName ? decodeURIComponent(String(route.query.storeName)) : '海马智慧门店',
      industry: route.query.industry ? String(route.query.industry) : undefined,
      industryCategoryName: route.query.industryCategoryName ? decodeURIComponent(String(route.query.industryCategoryName)) : undefined,
      address: route.query.address ? decodeURIComponent(String(route.query.address)) : undefined,
      phone: route.query.phone ? decodeURIComponent(String(route.query.phone)) : undefined,
      businessHours: route.query.businessHours ? decodeURIComponent(String(route.query.businessHours)) : undefined
    }
  }

  loadStoreRegisterConfig()
})

const toggleHabit = (tag: string) => {
  const idx = memberForm.value.habits.indexOf(tag)
  if (idx !== -1) {
    memberForm.value.habits.splice(idx, 1)
  } else {
    memberForm.value.habits.push(tag)
  }
}

const handleAddCustomHabit = () => {
  const tag = customHabitInput.value.trim()
  if (!tag) return
  if (!storePreferenceTags.value.includes(tag)) {
    storePreferenceTags.value.push(tag)
  }
  if (!memberForm.value.habits.includes(tag)) {
    memberForm.value.habits.push(tag)
  }
  customHabitInput.value = ''
  ElMessage.success(`已添加偏好标签：${tag}`)
}

const handleSubmitMember = () => {
  if (!memberForm.value.phone || !/^1[3-9]\d{9}$/.test(memberForm.value.phone.trim())) {
    ElMessage.warning('请输入有效的11位手机号码')
    return
  }
  if (!memberForm.value.name.trim()) {
    ElMessage.warning('请输入您的姓名或称呼')
    return
  }
  if (!memberForm.value.agree) {
    ElMessage.warning('请阅读并勾选会员服务协议')
    return
  }

  // 涉及充值的情况需要真实的进行充值操作才可以，可以存在模拟支付
  if (memberForm.value.chargeOption && memberForm.value.chargeOption.principal > 0) {
    openPayDialog.value = true
  } else {
    executeRegister('FREE')
  }
}

const handleConfirmSimulatePay = async () => {
  paying.value = true
  try {
    // 模拟调起支付收银台网关
    await new Promise(resolve => setTimeout(resolve, 1000))
    await executeRegister(selectedPaymentMethod.value)
    openPayDialog.value = false
    ElMessage.success(`🎉 模拟支付成功！已通过【${selectedPaymentMethod.value === 'WECHAT' ? '微信支付' : '支付宝'}】成功充值 ￥${memberForm.value.chargeOption.principal}，会员开卡成功！`)
  } catch (e: any) {
    ElMessage.error(e.message || '支付失败')
  } finally {
    paying.value = false
  }
}

const executeRegister = async (payMethod: string) => {
  submittingMember.value = true
  try {
    const res = systemData.registerMember({
      name: memberForm.value.name.trim(),
      phone: memberForm.value.phone.trim(),
      gender: memberForm.value.gender,
      birthday: memberForm.value.birthday,
      habits: [...memberForm.value.habits],
      registeredStoreId: targetStoreId.value,
      initialPrincipal: memberForm.value.chargeOption?.principal || 0,
      initialGift: memberForm.value.chargeOption?.gift || 0,
      paymentMethod: payMethod
    })

    createdMember.value = res
    memberSuccess.value = true

    // 后台真实同步保存
    try {
      const regRes: any = await registerMemberApi({
        name: memberForm.value.name.trim(),
        phone: memberForm.value.phone.trim(),
        gender: memberForm.value.gender,
        birthday: memberForm.value.birthday,
        initialPrincipal: memberForm.value.chargeOption?.principal || 0,
        initialGift: memberForm.value.chargeOption?.gift || 0,
        storeId: targetStoreId.value,
        paymentMethod: payMethod
      })

      const backendMemberId = regRes?.id || regRes?.data?.id || (createdMember.value ? createdMember.value.id : null)
      if (backendMemberId) {
        if (createdMember.value) {
          const oldId = createdMember.value.id
          createdMember.value.id = backendMemberId
          if (regRes?.memberNo) createdMember.value.memberNo = regRes.memberNo
          if (regRes?.level) createdMember.value.level = regRes.level
          if (regRes?.levelName) createdMember.value.levelName = regRes.levelName
          const localMem = systemData.members.find(m => m.phone === memberForm.value.phone.trim())
          if (localMem) {
            localMem.id = backendMemberId
            if (regRes?.memberNo) localMem.memberNo = regRes.memberNo
            if (regRes?.level) localMem.level = regRes.level
            if (regRes?.levelName) localMem.levelName = regRes.levelName
            systemData.persistMembers()
            systemData.rechargeOrders.forEach(ro => {
              if (ro.memberId === oldId) {
                ro.memberId = backendMemberId
              }
            })
            systemData.persistRechargeOrders()
          }
        }
        for (const h of memberForm.value.habits) {
          try {
            await savePreferenceApi({
              memberId: backendMemberId,
              category: 'HABIT',
              tagKey: '常客自主偏好',
              tagValue: h
            })
          } catch (pe) {
            console.warn('保存偏好标签跳过', pe)
          }
        }
      }
    } catch (e) {
      console.warn('Backend sync skipped, local persistent store guaranteed.', e)
    }

    if (payMethod === 'FREE') {
      ElMessage.success('会员开卡成功！欢迎加入会员！')
    }
  } catch (e: any) {
    ElMessage.error(e.message || '开卡失败')
    throw e
  } finally {
    submittingMember.value = false
  }
}

const resetMemberForm = () => {
  memberSuccess.value = false
  memberForm.value.phone = ''
  memberForm.value.name = ''
  memberForm.value.habits = []
  if (chargeOptions.value.length > 0) {
    memberForm.value.chargeOption = chargeOptions.value[0]
  }
}

const handleGoMemberPortal = () => {
  const mId = createdMember.value?.id
  const mPhone = memberForm.value.phone?.trim()
  const mName = memberForm.value.name?.trim()
  localStorage.setItem('seahorse_token', 'token_member_' + Date.now())
  localStorage.setItem('seahorse_user', mName || '')
  localStorage.setItem('seahorse_role', 'CUSTOMER_MEMBER')
  if (mId) localStorage.setItem('seahorse_member_id', String(mId))
  if (mPhone) localStorage.setItem('seahorse_member_phone', String(mPhone))
  router.push(`/member-portal?phone=${encodeURIComponent(mPhone || '')}&memberId=${mId || ''}`)
}
</script>

<style scoped>
.member-register-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #f0fdf4 0%, #e0f2fe 50%, #f8fafc 100%);
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding: 32px 16px;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

.member-register-card {
  width: 100%;
  max-width: 520px;
  background: #ffffff;
  border-radius: 20px;
  box-shadow: 0 20px 40px -15px rgba(15, 23, 42, 0.12);
  overflow: hidden;
  border: 1px solid #e2e8f0;
}

.store-banner {
  background: linear-gradient(135deg, #0d9488 0%, #0284c7 100%);
  color: #ffffff;
  padding: 24px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.store-logo {
  font-size: 38px;
  width: 56px;
  height: 56px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.store-info {
  flex: 1;
}

.store-name-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.store-name {
  font-size: 18px;
  font-weight: 700;
  letter-spacing: 0.5px;
}

.store-sub {
  font-size: 12px;
  opacity: 0.9;
  line-height: 1.4;
}

.portal-header-bar {
  padding: 16px 24px;
  background: #f8fafc;
  border-bottom: 1px solid #f1f5f9;
  text-align: center;
}

.ph-title-wrap {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.ph-icon {
  font-size: 22px;
}

.ph-title {
  font-size: 17px;
  font-weight: 700;
  color: #0f172a;
}

.ph-subtitle {
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
}

.form-container {
  padding: 24px;
}

.mode-tip-banner {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  padding: 12px 14px;
  border-radius: 10px;
  margin-bottom: 20px;
}

.t-icon {
  font-size: 18px;
  line-height: 1;
}

.t-text {
  font-size: 13px;
  color: #1e40af;
  line-height: 1.5;
}

.custom-form :deep(.el-form-item__label) {
  font-weight: 600;
  color: #334155;
  font-size: 13px;
  padding-bottom: 6px;
}

.habit-tags-box {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.habit-tag {
  font-size: 12.5px;
  padding: 6px 12px;
  background: #f1f5f9;
  color: #475569;
  border-radius: 18px;
  cursor: pointer;
  border: 1px solid transparent;
  transition: all 0.2s;
  user-select: none;
}

.habit-tag:hover {
  background: #e2e8f0;
}

.habit-tag.selected {
  background: #e0f2fe;
  color: #0284c7;
  border-color: #38bdf8;
  font-weight: 600;
}

.charge-options-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  width: 100%;
}

.charge-opt-card {
  position: relative;
  border: 1.5px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px 10px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
  background: #ffffff;
}

.charge-opt-card:hover {
  border-color: #93c5fd;
  transform: translateY(-2px);
}

.charge-opt-card.selected {
  border-color: #0284c7;
  background: #f0f9ff;
  box-shadow: 0 4px 12px rgba(2, 132, 199, 0.15);
}

.opt-title {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 4px;
}

.opt-price {
  font-size: 18px;
  font-weight: 800;
  color: #0284c7;
}

.opt-badge {
  position: absolute;
  top: -8px;
  right: 6px;
  font-size: 10px;
  background: #f43f5e;
  color: #ffffff;
  padding: 1px 6px;
  border-radius: 8px;
  font-weight: 700;
}

.agreement-box {
  margin: 16px 0 20px 0;
  font-size: 12px;
}

.submit-btn {
  height: 46px;
  font-size: 16px;
  font-weight: 700;
  border-radius: 12px;
  background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
  border: none;
  box-shadow: 0 4px 14px rgba(2, 132, 199, 0.35);
}

.w-full {
  width: 100%;
}

/* 结果卡片 */
.success-result-box {
  text-align: center;
  padding: 10px 0;
}

.success-icon {
  font-size: 48px;
  margin-bottom: 10px;
}

.success-title {
  font-size: 20px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 6px;
}

.success-desc {
  font-size: 13px;
  color: #64748b;
  margin-bottom: 24px;
}

.member-card-preview {
  background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
  border-radius: 16px;
  padding: 20px 22px;
  color: #f8fafc;
  box-shadow: 0 16px 32px rgba(15, 23, 42, 0.3);
  margin-bottom: 24px;
  text-align: left;
  border: 1px solid #334155;
  position: relative;
  overflow: hidden;
  transition: all 0.3s ease;
}

.member-card-preview.card-regular {
  background: linear-gradient(135deg, #0f2027 0%, #203a43 50%, #2c5364 100%);
  border: 1px solid rgba(148, 163, 184, 0.4);
}

.member-card-preview.card-silver {
  background: linear-gradient(135deg, #334155 0%, #475569 50%, #64748b 100%);
  border: 1px solid rgba(203, 213, 225, 0.5);
  box-shadow: 0 16px 32px rgba(71, 85, 105, 0.3);
}

.member-card-preview.card-gold {
  background: linear-gradient(135deg, #78350f 0%, #b45309 50%, #92400e 100%);
  border: 1px solid rgba(253, 224, 71, 0.5);
  box-shadow: 0 16px 32px rgba(180, 83, 9, 0.35);
}

.member-card-preview.card-platinum {
  background: linear-gradient(135deg, #31104b 0%, #581c87 50%, #6b21a8 100%);
  border: 1px solid rgba(216, 180, 254, 0.5);
  box-shadow: 0 16px 32px rgba(107, 33, 168, 0.35);
}

.member-card-preview.card-diamond {
  background: linear-gradient(135deg, #020617 0%, #0f172a 50%, #1e1b4b 100%);
  border: 1px solid rgba(245, 158, 11, 0.5);
  box-shadow: 0 16px 32px rgba(15, 23, 42, 0.5);
}

.member-card-preview::after {
  content: '';
  position: absolute;
  top: -40px;
  right: -40px;
  width: 140px;
  height: 140px;
  background: radial-gradient(circle, rgba(255, 255, 255, 0.15) 0%, rgba(255, 255, 255, 0) 70%);
  border-radius: 50%;
}

.m-card-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.m-brand {
  font-size: 15px;
  font-weight: 700;
  color: #e2e8f0;
}

.m-level {
  font-size: 12px;
  font-weight: 700;
  color: #f59e0b;
  background: rgba(245, 158, 11, 0.15);
  padding: 2px 10px;
  border-radius: 12px;
  border: 1px solid rgba(245, 158, 11, 0.3);
}

.m-card-no {
  font-family: 'Courier New', Courier, monospace;
  font-size: 22px;
  letter-spacing: 2px;
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 24px;
}

.m-card-bottom {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.m-owner {
  font-size: 15px;
  font-weight: 700;
  margin-bottom: 2px;
}

.m-store {
  font-size: 11px;
  color: #94a3b8;
}

.m-balance {
  text-align: right;
}

.m-bal-val {
  font-size: 20px;
  font-weight: 800;
  color: #38bdf8;
}

.m-bal-lbl {
  font-size: 10px;
  color: #94a3b8;
}

.welcome-privileges {
  background: #f8fafc;
  border-radius: 12px;
  padding: 14px 16px;
  margin-bottom: 24px;
  text-align: left;
  border: 1px solid #e2e8f0;
}

.p-item {
  font-size: 13px;
  color: #334155;
  margin-bottom: 8px;
  line-height: 1.4;
}

.p-item:last-child {
  margin-bottom: 0;
}

.portal-footer {
  padding: 16px 24px;
  background: #f8fafc;
  border-top: 1px solid #f1f5f9;
  text-align: center;
  font-size: 12px;
  color: #94a3b8;
}
</style>
