<template>
  <div class="tenant-register-page">
    <div class="tr-container">
      <!-- 顶部品牌栏 -->
      <div class="tr-header">
        <div class="tr-brand">
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
          <div class="brand-text">
            <div class="brand-title">
              海马智慧门店 <span class="brand-tag">SaaS 2.0</span>
              <span style="display:inline-flex;align-items:center;margin-left:8px;padding:2px 10px;border-radius:999px;background:linear-gradient(135deg,#fef3c7,#fde68a);color:#92400e;font-size:12px;font-weight:800;border:1px solid #f59e0b;">✦ 海马会员，记住每位好客。</span>
            </div>
            <div class="brand-slogan">新一代智慧服务业连锁门店经营操作系统 · 租户入驻与套餐开通中心</div>
          </div>
        </div>
        <div class="tr-header-right">
          <el-button link type="primary" @click="$router.push('/login')">
            已有租户账号？直接登录工作台 👉
          </el-button>
        </div>
      </div>

      <!-- 营销推广与试用特权横幅 (动态绑定海报参数) -->
      <div class="tr-campaign-banner">
        <div class="tcb-left">
          <div class="tcb-badge">
            <span class="tcb-dot"></span>
            🎁 专属营销推广特权已生效
          </div>
          <h2 class="tcb-title">
            恭喜！您已成功解锁【{{ currentPlanInfo.name }}】
            <span class="tcb-days">{{ trialDays }} 天超长免费全功能深度试用</span>
          </h2>
          <div class="tcb-desc">
            无需安装硬件，扫码即可上云。体验期间享旗舰版全部功能，0 元试用满意再续费。
          </div>
        </div>
        <div class="tcb-right">
          <div class="tcb-ref-badge" v-if="refCode">
            <div class="ref-lbl">推广邀请码 / 渠道标识</div>
            <div class="ref-val">{{ refCode }}</div>
            <div class="ref-status">✓ 尊享绿通审核特权</div>
          </div>
        </div>
      </div>

      <!-- 主体内容卡片：左侧套餐权益介绍，右侧租户入驻注册表单 -->
      <div class="tr-main-card">
        <!-- 成功激活工作台结果状态 -->
        <div v-if="registerSuccess" class="tr-success-view">
          <div class="suc-icon">🎉</div>
          <h2 class="suc-title">恭喜！您的专属 SaaS 租户与首个门店已开通成功！</h2>
          <p class="suc-desc">已为您初始化纯净、独立的租户云端数据库与管理大厅，您可立即进入工作台开始配置商品与开展业务。</p>

          <div class="suc-details-card">
            <div class="sd-header">
              <span class="sd-badge">🏬 租户档案与权限</span>
              <span class="sd-status">● 运行正常 (已激活)</span>
            </div>
            <div class="sd-grid">
              <div class="sd-item">
                <span class="sd-lbl">租户品牌名称：</span>
                <span class="sd-val"><strong>{{ registeredTenantData?.tenantName }}</strong></span>
              </div>
              <div class="sd-item">
                <span class="sd-lbl">首个门店名称：</span>
                <span class="sd-val">{{ registeredTenantData?.initialStoreName }}</span>
              </div>
              <div class="sd-item">
                <span class="sd-lbl">开通套餐版本：</span>
                <span class="sd-val text-brand"><strong>{{ currentPlanInfo.name }}</strong> (已赠送 {{ trialDays }} 天试用)</span>
              </div>
              <div class="sd-item">
                <span class="sd-lbl">管理员主账号：</span>
                <span class="sd-val text-brand"><strong>{{ regForm.contactPhone }}</strong></span>
              </div>
              <div class="sd-item">
                <span class="sd-lbl">适配所属行业：</span>
                <span class="sd-val">{{ getIndustryLabel(regForm.initialIndustry) }}</span>
              </div>
              <div class="sd-item">
                <span class="sd-lbl">试用到期时间：</span>
                <span class="sd-val" style="color: #ea580c;">{{ expirationDateStr }}</span>
              </div>
            </div>
          </div>

          <div class="suc-actions">
            <el-button type="primary" size="large" class="suc-enter-btn" :loading="enteringDashboard" @click="handleEnterDashboard">
              🚀 立即进入我的租户工作台 (开启数字化经营)
            </el-button>
            <el-button size="large" style="margin-top: 12px;" @click="$router.push('/login')">
              返回系统登录页
            </el-button>
          </div>
        </div>

        <!-- 正常填报注册视图 -->
        <div v-else class="tr-content-grid">
          <!-- 左侧：所选套餐与核心赋能亮点 -->
          <div class="tr-plan-column">
            <div class="plan-card-box">
              <div class="pc-top">
                <div class="pc-name-wrap">
                  <span class="pc-icon">{{ currentPlanInfo.icon }}</span>
                  <div>
                    <div class="pc-name">{{ currentPlanInfo.name }}</div>
                    <div class="pc-tag">{{ currentPlanInfo.tag }}</div>
                  </div>
                </div>
                <div class="pc-pricing">
                  <div class="pc-price-now">
                    <span class="p-cur">￥</span><span class="p-val">0</span>
                    <span class="p-unit">/ {{ trialDays }}天全功能试用</span>
                  </div>
                  <div class="pc-price-original">原价 {{ currentPlanInfo.officialPrice }}</div>
                </div>
              </div>

              <div class="pc-divider"></div>

              <!-- 4大核心特权卖点 (对应海报文案) -->
              <div class="pc-features">
                <div class="pc-feat-title">✨ 本套餐包含核心权益：</div>
                <div v-for="(feat, idx) in currentPlanInfo.features" :key="idx" class="pc-feat-item">
                  <span class="feat-check">✓</span>
                  <span class="feat-text">{{ feat }}</span>
                </div>
              </div>

              <!-- 切换其他可选套餐 -->
              <div class="plan-switcher-box">
                <div class="ps-title">🔄 选购或切换其他 SaaS 套餐：</div>
                <div class="ps-options">
                  <div
                    v-for="p in allPlans"
                    :key="p.code"
                    class="ps-btn"
                    :class="{ active: currentPlanCode === p.code }"
                    @click="currentPlanCode = p.code"
                  >
                    <span class="ps-name">{{ p.name }}</span>
                    <span class="ps-sub">{{ p.trialTip }}</span>
                  </div>
                </div>
              </div>

              <div class="pc-trust-box">
                <div class="trust-line">🛡️ 阿里云高防专区物理隔离存储</div>
                <div class="trust-line">⚡ 99.99% 高可用 SLA 商业级保障</div>
                <div class="trust-line">👨‍💻 7×24 小时专属架构师运维支持</div>
              </div>
            </div>
          </div>

          <!-- 右侧：租户开店注册表单 -->
          <div class="tr-form-column">
            <div class="form-card-box">
              <div class="fc-header">
                <h3 class="fc-title">📝 填写租户开店资料 · 快速开通</h3>
                <div class="fc-desc">只需 1 分钟，即刻拥有独立的门店数字化管理平台</div>
              </div>

              <el-form :model="regForm" label-position="top" class="tenant-form">
                <!-- 品牌名称 -->
                <el-form-item label="企业/租户品牌名称 (用于前台及顾客小程序展示)" required>
                  <el-input
                    v-model="regForm.tenantName"
                    placeholder="例如：海马美业连锁 / 星悦餐饮管理"
                    prefix-icon="OfficeBuilding"
                    size="large"
                  />
                </el-form-item>

                <!-- 门店名称 -->
                <el-form-item label="首个门店名称 (后续可在后台任意增开连锁分店)" required>
                  <el-input
                    v-model="regForm.initialStoreName"
                    placeholder="例如：旗舰总店 / 万达概念店"
                    prefix-icon="Shop"
                    size="large"
                  />
                </el-form-item>

                <!-- 所属行业模态 -->
                <el-form-item label="主营行业模态 (系统将自动装配匹配的行业字典与收银流程)" required>
                  <div class="industry-selector-grid">
                    <div
                      v-for="ind in industryList"
                      :key="ind.code"
                      class="ind-select-card"
                      :class="{ selected: regForm.initialIndustry === ind.code }"
                      @click="regForm.initialIndustry = ind.code"
                    >
                      <div class="ind-icon">{{ ind.icon }}</div>
                      <div class="ind-name">{{ ind.name }}</div>
                      <div class="ind-desc">{{ ind.desc }}</div>
                    </div>
                  </div>
                </el-form-item>

                <el-row :gutter="14">
                  <el-col :span="12">
                    <el-form-item label="负责人称呼" required>
                      <el-input
                        v-model="regForm.adminRealName"
                        placeholder="例如：张经理 / 李老板"
                        prefix-icon="User"
                        size="large"
                      />
                    </el-form-item>
                  </el-col>
                  <el-col :span="12">
                    <el-form-item label="联系手机号 (作为主管理员登录账号)" required>
                      <el-input
                        v-model="regForm.contactPhone"
                        placeholder="11位手机号"
                        prefix-icon="Iphone"
                        maxlength="11"
                        size="large"
                      />
                    </el-form-item>
                  </el-col>
                </el-row>

                <el-row :gutter="14">
                  <el-col :span="14">
                    <el-form-item label="短信验证码" required>
                      <div style="display: flex; gap: 8px;">
                        <el-input
                          v-model="regForm.smsCode"
                          placeholder="请输入验证码"
                          prefix-icon="Key"
                          size="large"
                        />
                        <el-button
                          size="large"
                          type="primary"
                          plain
                          :disabled="smsCountDown > 0"
                          @click="handleSendSms"
                          style="white-space: nowrap;"
                        >
                          {{ smsCountDown > 0 ? `${smsCountDown}s` : '获取验证码' }}
                        </el-button>
                      </div>
                    </el-form-item>
                  </el-col>
                  <el-col :span="10">
                    <el-form-item label="设置登录密码" required>
                      <el-input
                        v-model="regForm.adminPassword"
                        type="password"
                        placeholder="6位以上密码"
                        prefix-icon="Lock"
                        show-password
                        size="large"
                      />
                    </el-form-item>
                  </el-col>
                </el-row>

                <div class="agreement-row">
                  <el-checkbox v-model="agreeTerms">
                    我已阅读并完全同意
                    <a href="javascript:void(0)" class="link-text">《海马SaaS服务条款》</a>
                    与
                    <a href="javascript:void(0)" class="link-text">《租户入驻及隐私协议》</a>
                  </el-checkbox>
                </div>

                <el-button
                  type="primary"
                  size="large"
                  class="submit-tenant-btn"
                  :loading="submitting"
                  @click="handleRegisterTenant"
                >
                  🚀 立即开通 SaaS 租户工作台 (享 {{ trialDays }} 天免费试用)
                </el-button>

                <div class="form-bottom-tip">
                  🔒 数据私有化隔离 · 试用到期前 7 天短信温馨提醒 · 无任何强制捆绑续费
                </div>
              </el-form>
            </div>
          </div>
        </div>
      </div>

      <!-- 底部版权栏 -->
      <div class="tr-footer">
        <div class="tr-f-links">
          <span>官网首页: https://fwpt.cn</span>
          <span>·</span>
          <span>开发商技术支持</span>
          <span>·</span>
          <span>SaaS 2.0 旗舰运营</span>
        </div>
        <div class="tr-f-copy">© 2026 海马智慧门店管理操作系统 Seahorse Store OS. All Rights Reserved.</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { registerMerchantApi, loginApi } from '../api'
import { useSystemDataStore } from '../stores/systemDataStore'
import { useStoreConfig } from '../stores/store'
import { ElMessage } from 'element-plus'

const route = useRoute()
const router = useRouter()
const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()

// 接收 URL 查询参数
const currentPlanCode = ref<string>('FLAGSHIP')
const refCode = ref<string>('')
const trialDays = ref<number>(30)

// 表单数据
const regForm = ref({
  tenantName: '',
  initialStoreName: '',
  initialIndustry: 'BEAUTY' as 'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL',
  adminRealName: '',
  contactPhone: '',
  smsCode: '888888',
  adminPassword: ''
})

const agreeTerms = ref(true)
const smsCountDown = ref(0)
const submitting = ref(false)
const registerSuccess = ref(false)
const enteringDashboard = ref(false)
const registeredTenantData = ref<any>(null)

// 行业字典
const industryList: Array<{ code: 'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL'; name: string; icon: string; desc: string }> = [
  { code: 'BEAUTY', name: '美容美发美甲', icon: '💇', desc: '海马体偏好/技师排班/划卡' },
  { code: 'RESTAURANT', name: '餐饮轻食正餐', icon: '🍲', desc: '扫码点餐/桌台包厢/厨房打单' },
  { code: 'AUTO', name: '汽车养护维修', icon: '🚗', desc: '车牌识别/工位施工/配件出库' },
  { code: 'RETAIL', name: '专营名品零售', icon: '🛍️', desc: '条码扫码/批次保质期/多仓' }
]

const getIndustryLabel = (code: string) => {
  const item = industryList.find(i => i.code === code)
  return item ? `${item.icon} ${item.name}` : code
}

// SaaS 套餐预设定义
const allPlans = [
  {
    code: 'TRIAL',
    name: '体验版 (基础启航)',
    tag: '轻量首选',
    icon: '🌱',
    officialPrice: '￥980/年',
    trialTip: '3天免费试用',
    features: [
      '单店收银与基础会员档案建档',
      '商品与项目基础管理',
      '日结账单与收银流水报表',
      '基础技术支持'
    ]
  },
  {
    code: 'STANDARD',
    name: '标准专业版 (单店领航)',
    tag: '口碑爆款',
    icon: '⚡',
    officialPrice: '￥2980/年',
    trialTip: '14天免费试用',
    features: [
      '组合双轨收银与并发防超扣保障',
      '海马体会员智能画像与到店常态偏好记忆',
      '会员折扣/次卡/储值全套营销',
      '技师提成智能算薪与报表'
    ]
  },
  {
    code: 'FLAGSHIP',
    name: '旗舰连锁版 (多店裂变)',
    tag: '热销推荐',
    icon: '👑',
    officialPrice: '￥4980/年',
    trialTip: '30天免费试用',
    features: [
      '跨店储值通存通兑与一人多店兼职调度',
      '全渠道营销海报生成与裂变推广分发',
      '预约看板与工位/包厢智能流转调度',
      '7×24小时专属客户成功顾问保障'
    ]
  },
  {
    code: 'ENTERPRISE',
    name: '私有化企业版 (定制互联)',
    tag: '集团尊享',
    icon: '🏢',
    officialPrice: '￥9980/年',
    trialTip: '专属定制开通',
    features: [
      '专属独立私有化服务器部署支持',
      '全功能开放 API 与第三方 ERP/财务打通',
      '多法人独立资金结算与分账体系',
      '专属专家团队上门驻场培训实施'
    ]
  }
]

const currentPlanInfo = computed(() => {
  return allPlans.find(p => p.code === currentPlanCode.value) || allPlans[2]
})

const expirationDateStr = computed(() => {
  const d = new Date()
  d.setDate(d.getDate() + trialDays.value)
  return d.toISOString().split('T')[0] + ' 23:59:59'
})

onMounted(() => {
  // 解析路由参数
  if (route.query.plan) {
    const p = String(route.query.plan).toUpperCase()
    if (allPlans.some(item => item.code === p)) {
      currentPlanCode.value = p
    }
  }
  if (route.query.ref) {
    refCode.value = String(route.query.ref)
  }
  if (route.query.trial) {
    const t = parseInt(String(route.query.trial))
    if (!isNaN(t) && t > 0) {
      trialDays.value = t
    }
  }

  // 默认根据选择预填租户及首店名称示例
  if (!regForm.value.tenantName) {
    regForm.value.tenantName = '海马连锁美业'
    regForm.value.initialStoreName = '杭州旗舰总店'
  }
})

let smsTimer: ReturnType<typeof setInterval> | null = null

onUnmounted(() => {
  if (smsTimer) {
    clearInterval(smsTimer)
    smsTimer = null
  }
})

const handleSendSms = () => {
  if (!regForm.value.contactPhone || !/^1[3-9]\d{9}$/.test(regForm.value.contactPhone.trim())) {
    ElMessage.warning('请输入有效的11位手机号码')
    return
  }
  regForm.value.smsCode = '888888'
  smsCountDown.value = 60
  if (smsTimer) clearInterval(smsTimer)
  smsTimer = setInterval(() => {
    smsCountDown.value--
    if (smsCountDown.value <= 0 && smsTimer) {
      clearInterval(smsTimer)
      smsTimer = null
    }
  }, 1000)
  ElMessage.success('短信验证码已发送！测试环境已自动填入 [888888]')
}

const handleRegisterTenant = async () => {
  if (!regForm.value.tenantName.trim()) {
    ElMessage.warning('请输入企业/租户品牌名称')
    return
  }
  if (!regForm.value.initialStoreName.trim()) {
    ElMessage.warning('请输入首个门店名称')
    return
  }
  if (!regForm.value.adminRealName.trim()) {
    ElMessage.warning('请输入负责人称呼')
    return
  }
  if (!regForm.value.contactPhone || !/^1[3-9]\d{9}$/.test(regForm.value.contactPhone.trim())) {
    ElMessage.warning('请输入有效的11位手机号码')
    return
  }
  if (!regForm.value.smsCode.trim()) {
    ElMessage.warning('请输入短信验证码')
    return
  }
  if (!regForm.value.adminPassword || regForm.value.adminPassword.length < 6) {
    ElMessage.warning('请设置至少6位的管理登录密码')
    return
  }
  if (!agreeTerms.value) {
    ElMessage.warning('请勾选并同意服务条款与隐私协议')
    return
  }

  submitting.value = true
  try {
    const payload = {
      tenantName: regForm.value.tenantName.trim(),
      initialStoreName: regForm.value.initialStoreName.trim(),
      initialIndustry: regForm.value.initialIndustry,
      contactName: regForm.value.adminRealName.trim(),
      contactPhone: regForm.value.contactPhone.trim(),
      username: regForm.value.contactPhone.trim(),
      password: regForm.value.adminPassword.trim(),
      smsCode: regForm.value.smsCode.trim(),
      plan: currentPlanCode.value
    }

    const res: any = await registerMerchantApi(payload)

    // 本地存储新租户纯净环境与专属数据
    localStorage.setItem('seahorse_is_new_tenant', 'true')
    localStorage.setItem('seahorse_new_store_name', payload.initialStoreName)
    localStorage.setItem('seahorse_new_tenant_name', payload.tenantName)
    localStorage.setItem('seahorse_new_boss_name', payload.contactName)
    localStorage.setItem('seahorse_new_boss_phone', payload.contactPhone)

    // 初始化新租户全局工作区
    systemData.initNewTenantWorkspace(
      payload.tenantName,
      payload.initialStoreName,
      payload.contactName,
      payload.contactPhone
    )

    // 同步切换所选行业模态
    systemData.switchIndustry(payload.initialIndustry)
    storeConfig.industry = payload.initialIndustry
    storeConfig.storeName = payload.initialStoreName

    registeredTenantData.value = payload
    registerSuccess.value = true
    ElMessage.success(`🎉 恭喜！SaaS 租户开通成功，已为您赋予 ${trialDays.value} 天超长免费全功能试用特权！`)
  } catch (e: any) {
    ElMessage.error(e.message || '租户入驻注册失败，请稍后重试')
  } finally {
    submitting.value = false
  }
}

const handleEnterDashboard = async () => {
  enteringDashboard.value = true
  try {
    const res: any = await loginApi({
      username: regForm.value.contactPhone.trim(),
      password: regForm.value.adminPassword.trim()
    })
    if (!res?.token) {
      ElMessage.error('获取登录令牌失败，请返回登录页使用注册手机号登录')
      router.push('/login')
      return
    }
    localStorage.setItem('seahorse_token', res.token)
    localStorage.setItem('seahorse_user', res.realName || regForm.value.adminRealName)
    localStorage.setItem('seahorse_username', res.username || regForm.value.contactPhone.trim())
    localStorage.setItem('seahorse_role', res.role || 'TENANT_ADMIN')
    localStorage.setItem('seahorse_is_new_tenant', 'true')
    localStorage.setItem('seahorse_tenant_id', res.tenantId || '')
    localStorage.setItem('seahorse_store_id', res.storeId || 'S001')
    localStorage.setItem('seahorse_tenant_name', res.tenantName || regForm.value.tenantName)
    localStorage.setItem('seahorse_store_name', res.storeName || regForm.value.initialStoreName)
    localStorage.removeItem('seahorse_user_menu_paths')
    localStorage.removeItem('seahorse_allowed_stores')
    localStorage.removeItem('seahorse_staff_id')
    ElMessage.success('欢迎进入海马智慧门店 SaaS 工作台！')
    router.push('/dashboard')
  } catch (e: any) {
    ElMessage.warning('租户已开通，请使用注册手机号与密码登录工作台')
    router.push('/login')
  } finally {
    enteringDashboard.value = false
  }
}
</script>

<style scoped>
.tenant-register-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #091e3a 0%, #0a2e5c 40%, #0b1f3d 100%);
  color: #1e293b;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  padding: 32px 20px 60px 20px;
}

.tr-container {
  max-width: 1200px;
  margin: 0 auto;
}

/* 顶部品牌栏 */
.tr-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.tr-brand {
  display: flex;
  align-items: center;
  gap: 14px;
}

.logo-emoji {
  font-size: 38px;
  background: rgba(255, 255, 255, 0.12);
  width: 54px;
  height: 54px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
}

.brand-title {
  font-size: 22px;
  font-weight: 800;
  color: #ffffff;
  display: flex;
  align-items: center;
  gap: 10px;
}

.brand-tag {
  font-size: 11px;
  font-weight: 700;
  background: linear-gradient(135deg, #38bdf8 0%, #0284c7 100%);
  color: #ffffff;
  padding: 2px 8px;
  border-radius: 6px;
  letter-spacing: 0.5px;
}

.brand-slogan {
  font-size: 13px;
  color: #94a3b8;
  margin-top: 2px;
}

/* 营销活动特权横幅 */
.tr-campaign-banner {
  background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
  border: 1px solid rgba(56, 189, 248, 0.3);
  border-radius: 16px;
  padding: 22px 28px;
  margin-bottom: 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
  position: relative;
  overflow: hidden;
}

.tr-campaign-banner::after {
  content: '';
  position: absolute;
  top: -50px;
  right: -50px;
  width: 180px;
  height: 180px;
  background: radial-gradient(circle, rgba(56, 189, 248, 0.15) 0%, transparent 70%);
  border-radius: 50%;
}

.tcb-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: rgba(16, 185, 129, 0.15);
  color: #34d399;
  border: 1px solid rgba(16, 185, 129, 0.3);
  font-size: 12px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 20px;
  margin-bottom: 8px;
}

.tcb-dot {
  width: 6px;
  height: 6px;
  background: #34d399;
  border-radius: 50%;
}

.tcb-title {
  font-size: 20px;
  font-weight: 800;
  color: #ffffff;
  margin: 0 0 6px 0;
}

.tcb-days {
  color: #38bdf8;
  text-decoration: underline;
  text-underline-offset: 4px;
}

.tcb-desc {
  font-size: 13px;
  color: #94a3b8;
}

.tcb-ref-badge {
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.15);
  padding: 12px 18px;
  border-radius: 12px;
  text-align: center;
}

.ref-lbl {
  font-size: 11px;
  color: #94a3b8;
  margin-bottom: 2px;
}

.ref-val {
  font-family: 'Courier New', Courier, monospace;
  font-size: 16px;
  font-weight: 800;
  color: #38bdf8;
  letter-spacing: 1px;
}

.ref-status {
  font-size: 11px;
  color: #34d399;
  margin-top: 4px;
}

/* 主卡片布局 */
.tr-main-card {
  background: #ffffff;
  border-radius: 20px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  overflow: hidden;
}

.tr-content-grid {
  display: grid;
  grid-template-columns: 420px 1fr;
  min-height: 640px;
}

/* 左侧套餐专栏 */
.tr-plan-column {
  background: #f8fafc;
  border-right: 1px solid #e2e8f0;
  padding: 32px 28px;
}

.plan-card-box {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.pc-top {
  margin-bottom: 20px;
}

.pc-name-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.pc-icon {
  font-size: 32px;
}

.pc-name {
  font-size: 19px;
  font-weight: 800;
  color: #0f172a;
}

.pc-tag {
  font-size: 11px;
  font-weight: 700;
  color: #0284c7;
  background: #e0f2fe;
  display: inline-block;
  padding: 1px 8px;
  border-radius: 6px;
  margin-top: 3px;
}

.pc-pricing {
  display: flex;
  align-items: baseline;
  gap: 12px;
}

.pc-price-now {
  font-size: 30px;
  font-weight: 900;
  color: #0284c7;
}

.p-cur {
  font-size: 20px;
}

.p-unit {
  font-size: 13px;
  font-weight: normal;
  color: #64748b;
  margin-left: 4px;
}

.pc-price-original {
  font-size: 13px;
  color: #94a3b8;
  text-decoration: line-through;
}

.pc-divider {
  height: 1px;
  background: #e2e8f0;
  margin-bottom: 20px;
}

.pc-feat-title {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
  margin-bottom: 12px;
}

.pc-feat-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 13px;
  color: #475569;
  margin-bottom: 10px;
  line-height: 1.5;
}

.feat-check {
  color: #10b981;
  font-weight: 800;
}

.plan-switcher-box {
  margin-top: 24px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px;
}

.ps-title {
  font-size: 12px;
  font-weight: 700;
  color: #64748b;
  margin-bottom: 10px;
}

.ps-options {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.ps-btn {
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 8px;
  text-align: center;
  cursor: pointer;
  background: #ffffff;
  transition: all 0.2s;
}

.ps-btn:hover {
  border-color: #38bdf8;
}

.ps-btn.active {
  border-color: #0284c7;
  background: #f0f9ff;
  box-shadow: 0 2px 6px rgba(2, 132, 199, 0.15);
}

.ps-name {
  display: block;
  font-size: 12px;
  font-weight: 700;
  color: #0f172a;
}

.ps-sub {
  display: block;
  font-size: 10px;
  color: #0284c7;
  margin-top: 2px;
}

.pc-trust-box {
  margin-top: auto;
  padding-top: 20px;
  border-top: 1px dashed #cbd5e1;
  font-size: 11.5px;
  color: #64748b;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

/* 右侧表单专栏 */
.tr-form-column {
  padding: 36px 40px;
}

.fc-header {
  margin-bottom: 24px;
}

.fc-title {
  font-size: 20px;
  font-weight: 800;
  color: #0f172a;
  margin: 0 0 6px 0;
}

.fc-desc {
  font-size: 13px;
  color: #64748b;
}

.tenant-form :deep(.el-form-item__label) {
  font-weight: 600;
  color: #334155;
  font-size: 13px;
  padding-bottom: 4px;
}

.industry-selector-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  width: 100%;
}

.ind-select-card {
  border: 1.5px solid #e2e8f0;
  border-radius: 10px;
  padding: 10px 8px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
  background: #ffffff;
}

.ind-select-card:hover {
  border-color: #93c5fd;
  transform: translateY(-2px);
}

.ind-select-card.selected {
  border-color: #0284c7;
  background: #f0f9ff;
  box-shadow: 0 4px 10px rgba(2, 132, 199, 0.12);
}

.ind-icon {
  font-size: 22px;
  margin-bottom: 4px;
}

.ind-name {
  font-size: 12.5px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 2px;
}

.ind-desc {
  font-size: 10px;
  color: #64748b;
  line-height: 1.2;
}

.agreement-row {
  margin: 16px 0 20px 0;
  font-size: 12px;
}

.link-text {
  color: #0284c7;
  text-decoration: none;
}

.link-text:hover {
  text-decoration: underline;
}

.submit-tenant-btn {
  width: 100%;
  height: 50px;
  font-size: 16px;
  font-weight: 800;
  border-radius: 12px;
  background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
  border: none;
  box-shadow: 0 6px 18px rgba(2, 132, 199, 0.35);
}

.form-bottom-tip {
  text-align: center;
  font-size: 11.5px;
  color: #94a3b8;
  margin-top: 14px;
}

/* 注册成功视图 */
.tr-success-view {
  padding: 48px 40px;
  text-align: center;
  max-width: 720px;
  margin: 0 auto;
}

.suc-icon {
  font-size: 54px;
  margin-bottom: 14px;
}

.suc-title {
  font-size: 22px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 8px;
}

.suc-desc {
  font-size: 14px;
  color: #64748b;
  margin-bottom: 28px;
  line-height: 1.6;
}

.suc-details-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 20px 24px;
  text-align: left;
  margin-bottom: 30px;
}

.sd-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  border-bottom: 1px solid #e2e8f0;
  padding-bottom: 10px;
}

.sd-badge {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}

.sd-status {
  font-size: 12px;
  font-weight: 600;
  color: #16a34a;
}

.sd-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.sd-item {
  font-size: 13px;
  display: flex;
}

.sd-lbl {
  color: #64748b;
  width: 110px;
  flex-shrink: 0;
}

.sd-val {
  color: #1e293b;
}

.text-brand {
  color: #0284c7;
}

.suc-actions {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.suc-enter-btn {
  width: 100%;
  max-width: 440px;
  height: 48px;
  font-size: 16px;
  font-weight: 800;
  border-radius: 12px;
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  border: none;
  box-shadow: 0 6px 18px rgba(16, 185, 129, 0.35);
}

/* 底部版权栏 */
.tr-footer {
  margin-top: 36px;
  text-align: center;
  font-size: 12px;
  color: #64748b;
}

.tr-f-links {
  display: flex;
  justify-content: center;
  gap: 10px;
  margin-bottom: 8px;
}

@media (max-width: 960px) {
  .tr-content-grid {
    grid-template-columns: 1fr;
  }
  .tr-campaign-banner {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }
  .industry-selector-grid {
    grid-template-columns: 1fr 1fr;
  }
}
</style>
