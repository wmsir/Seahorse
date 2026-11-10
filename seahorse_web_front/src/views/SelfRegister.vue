<template>
  <div class="self-register-container">
    <div class="self-register-card">
      <!-- 门店顶头招牌展示 -->
      <div class="store-banner">
        <div class="store-logo">🌊</div>
        <div class="store-info">
          <div class="store-name-row">
            <span class="store-name">{{ currentStore?.storeName || '海马智慧门店' }}</span>
            <el-tag size="small" :type="currentStore?.isHeadquarter ? 'danger' : 'success'" effect="plain">
              {{ currentStore?.isHeadquarter ? '旗舰总店' : '分店/概念店' }}
            </el-tag>
          </div>
          <div class="store-sub">{{ currentStore?.address || '智慧商业街区' }} · {{ currentStore?.openTime || '09:00-22:00' }}</div>
        </div>
      </div>

      <!-- 顶部双通道选项卡 -->
      <div class="portal-tab-header">
        <div
          class="portal-tab-item"
          :class="{ active: activeMode === 'member' }"
          @click="switchMode('member')"
        >
          <span class="tab-icon">🌸</span>
          <span class="tab-title">顾客会员自助开卡</span>
        </div>
        <div
          class="portal-tab-item"
          :class="{ active: activeMode === 'staff' }"
          @click="switchMode('staff')"
        >
          <span class="tab-icon">💼</span>
          <span class="tab-title">员工入职申请与开号</span>
        </div>
      </div>

      <!-- ================= 模式一：顾客会员自助注册开卡 ================= -->
      <div v-if="activeMode === 'member'" class="form-container">
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
            <div class="p-item" v-if="memberForm.chargeOption.gift > 0">
              💰 已赠送 <strong>￥{{ memberForm.chargeOption.gift }} 储值奖励金</strong>
            </div>
            <div class="p-item">🧠 专属“海马体”常态偏好已永久建档，到店服务秒享熟客礼遇</div>
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

            <!-- 行业特色个性化记忆偏好勾选 -->
            <el-form-item label="🧠 个人常态偏好 (海马体将为您自动记住，免重复告知技师)">
              <div class="habit-tags-box">
                <span
                  v-for="tag in industryHabitTags"
                  :key="tag"
                  class="habit-tag"
                  :class="{ selected: memberForm.habits.includes(tag) }"
                  @click="toggleHabit(tag)"
                >
                  {{ tag }}
                </span>
              </div>
            </el-form-item>

            <!-- 意向开卡首充方案 -->
            <el-form-item label="💳 开卡首充与专属体验套餐 (可选)">
              <div class="charge-options-grid">
                <div
                  v-for="opt in chargeOptions"
                  :key="opt.id"
                  class="charge-opt-card"
                  :class="{ selected: memberForm.chargeOption.id === opt.id }"
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
              立即激活成为会员
            </el-button>
          </el-form>
        </div>
      </div>

      <!-- ================= 模式二：员工自主入职申请与账号开通 ================= -->
      <div v-else class="form-container">
        <!-- 员工入职成功界面 -->
        <div v-if="staffSuccess" class="success-result-box">
          <div class="success-icon" style="font-size: 52px; margin-bottom: 8px;">⏳</div>
          <div class="success-title" style="color: #b45309;">入职申请已提交，等待店长或租户审核！</div>
          <div class="success-desc">您已成功提交【{{ currentStore?.storeName }}】入职资料。为保障门店数据与运营安全，需由店长或租户老板审核通过后，系统账号方可激活。</div>

          <div class="staff-account-card" style="border-left: 4px solid #f59e0b; background: #fffbeb;">
            <div class="sac-row">
              <span class="sac-lbl">审核状态：</span>
              <span class="sac-val"><el-tag type="warning" effect="dark" size="small">⏳ 待店长/租户审核</el-tag></span>
            </div>
            <div class="sac-row">
              <span class="sac-lbl">申请员工：</span>
              <span class="sac-val"><strong>{{ createdStaff?.realName }}</strong> ({{ createdStaff?.gender === 'FEMALE' ? '女' : '男' }})</span>
            </div>
            <div v-if="createdStaff?.department" class="sac-row">
              <span class="sac-lbl">所属部门：</span>
              <span class="sac-val"><el-tag size="small" effect="plain">{{ createdStaff?.department }}</el-tag></span>
            </div>
            <div class="sac-row">
              <span class="sac-lbl">拟任岗位：</span>
              <span class="sac-val text-primary"><strong>{{ createdStaff?.postName }}</strong></span>
            </div>
            <div class="sac-row">
              <span class="sac-lbl">登录手机号：</span>
              <span class="sac-val text-primary"><strong>{{ createdStaff?.phone }}</strong></span>
            </div>
            <div class="sac-row">
              <span class="sac-lbl">拟执业门店：</span>
              <span class="sac-val">
                <el-tag size="small" effect="light" type="success">
                  {{ currentStore?.storeName || '海马智慧门店' }}
                </el-tag>
              </span>
            </div>
          </div>

          <div style="margin-top: 14px; padding: 10px 14px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; font-size: 12.5px; color: #15803d; line-height: 1.5; text-align: left;">
            💡 <strong>温馨提示：</strong>店长或租户老板可在后台【员工管理 ➔ 🛡️ 扫码入职审核】中一键审核通过。审核通过后，您即可直接使用此手机号登录系统！
          </div>

          <div class="result-actions">
            <el-button type="primary" size="large" class="w-full" @click="handleGoLogin">
              前往系统登录页 (待审核通过后可登录) 👉
            </el-button>
            <el-button size="default" style="margin-top: 10px;" @click="resetStaffForm">
              继续为其他员工登记入职
            </el-button>
          </div>
        </div>

        <!-- 填写员工入职表单 -->
        <div v-else>
          <div class="mode-tip-banner staff-tip-banner">
            <span class="t-icon">🛡️</span>
            <div class="t-text">
              <strong>员工自主入职通道：</strong>自助提交入职基础资料并设定登录密码，系统将自动分配对应岗位的工作台页签与门店执业权限！
            </div>
          </div>

          <el-form :model="staffForm" label-position="top" class="custom-form">
            <el-row :gutter="12">
              <el-col :span="12">
                <el-form-item label="员工真实姓名" required>
                  <el-input v-model="staffForm.realName" placeholder="例如：李明" prefix-icon="User" />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="性别" required>
                  <el-select v-model="staffForm.gender" style="width: 100%;">
                    <el-option label="男" value="MALE" />
                    <el-option label="女" value="FEMALE" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>

            <el-form-item label="手机号码 (作为后续登录系统的唯一账号)" required>
              <el-input
                v-model="staffForm.phone"
                placeholder="请输入11位员工手机号码"
                prefix-icon="Iphone"
                maxlength="11"
              />
            </el-form-item>

            <el-form-item label="设置登录密码 (默认 123456)" required>
              <el-input
                v-model="staffForm.accountPassword"
                type="text"
                placeholder="设置6位以上密码"
                prefix-icon="Lock"
              />
            </el-form-item>

            <el-form-item label="应聘/入职岗位 (系统将自动匹配功能页签权限)" required>
              <el-select v-model="staffForm.postInfo" value-key="postName" style="width: 100%;">
                <el-option
                  v-for="p in availablePositions"
                  :key="p.postName"
                  :label="p.postName + ' (' + p.dept + ')'"
                  :value="p"
                />
              </el-select>
            </el-form-item>

            <!-- 执业门店多选 (一人多店) -->
            <el-form-item label="🏪 执业门店 (支持一人兼职多店，登录时可自选门店)" required>
              <el-checkbox-group v-model="staffForm.allowedStoreIds" class="store-check-inline">
                <el-checkbox
                  v-for="s in systemData.stores"
                  :key="s.storeId"
                  :label="s.storeId"
                >
                  {{ s.storeName }}
                </el-checkbox>
              </el-checkbox-group>
            </el-form-item>

            <el-form-item label="特长与过往从业经验 (简述)">
              <el-input
                v-model="staffForm.experience"
                type="textarea"
                rows="2"
                placeholder="例如：5年美发总监经验，擅长法式烫染与头皮抗衰管理..."
              />
            </el-form-item>

            <div class="agreement-box">
              <el-checkbox v-model="staffForm.agree">本人确认填报信息真实有效，自愿加入海马门店数字化系统</el-checkbox>
            </div>

            <el-button
              type="success"
              size="large"
              :loading="submittingStaff"
              class="w-full submit-btn"
              @click="handleSubmitStaff"
            >
              提交入职资料并开通账号
            </el-button>
          </el-form>
        </div>
      </div>

      <!-- 底部操作入口与返回 -->
      <div class="portal-footer">
        <el-button link type="info" size="small" @click="$router.push('/login')">
          已有账号？返回登录工作台
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSystemDataStore, allSystemMenus } from '../stores/systemDataStore'
import { useStoreConfig } from '../stores/store'
import { registerMemberApi } from '../api'
import { ElMessage } from 'element-plus'

const route = useRoute()
const router = useRouter()
const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()

const activeMode = ref<'member' | 'staff'>('member')
const targetStoreId = ref<string>('S001')

onMounted(() => {
  if (route.query.type === 'staff') {
    activeMode.value = 'staff'
  } else {
    activeMode.value = 'member'
  }
  if (route.query.storeId) {
    targetStoreId.value = String(route.query.storeId)
  } else {
    targetStoreId.value = storeConfig.currentStoreId || 'S001'
  }
})

const switchMode = (mode: 'member' | 'staff') => {
  activeMode.value = mode
}

const currentStore = computed(() => {
  return systemData.stores.find(s => s.storeId === targetStoreId.value) ||
         (systemData.stores.length > 0 ? systemData.stores[0] : null)
})

const getStoreNameById = (sId: string) => {
  const s = systemData.stores.find(item => item.storeId === sId)
  return s ? s.storeName : sId
}

// -----------------------------------------------------------------------------
// A. 顾客会员自助注册开卡
// -----------------------------------------------------------------------------
const memberSuccess = ref(false)
const submittingMember = ref(false)
const createdMember = ref<any>(null)

const cardEmoji = computed(() => {
  const ind = (currentStore.value?.industry || storeConfig.industry || '').toUpperCase()
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

const chargeOptions = [
  { id: 1, title: '基础会员开通', principal: 0, gift: 0, badge: '免费激活', levelCode: 'REGULAR', levelName: '普卡会员' },
  { id: 2, title: '首充礼遇 ￥200', principal: 200, gift: 50, badge: '立赠50元', levelCode: 'SILVER', levelName: '银卡会员' },
  { id: 3, title: '尊享体验 ￥500', principal: 500, gift: 150, badge: '热销推荐', levelCode: 'GOLD', levelName: '金卡会员' },
  { id: 4, title: '次卡开通 ￥99', principal: 99, gift: 0, badge: '含3次项目', levelCode: 'REGULAR', levelName: '普卡会员' }
]

const memberForm = ref({
  phone: '',
  name: '',
  gender: 'FEMALE' as 'FEMALE' | 'MALE',
  birthday: '',
  habits: ['喜好安静', '发质细软'] as string[],
  chargeOption: chargeOptions[0],
  agree: true
})

const industryHabitTags = computed(() => {
  const ind = storeConfig.industry || 'BEAUTY'
  if (ind === 'BEAUTY') {
    return ['发质细软', '敏感头皮', '偏爱自然修剪', '偏爱冷色调烫染', '喜好安静服务', '定期头皮SPA']
  } else if (ind === 'RESTAURANT') {
    return ['微辣免葱', '少盐少油', '偏爱包厢', '不吃香菜', '常带儿童就餐', '自备酒水']
  } else if (ind === 'AUTO') {
    return ['全合成机油偏好', '定期深度底盘检查', '车内高温桑拿', '原厂配件优先', '空调滤芯定期换']
  } else {
    return ['偏好有机绿色', '精致礼盒包装', '积分抵现优先', '新品品鉴体验']
  }
})

const toggleHabit = (tag: string) => {
  const idx = memberForm.value.habits.indexOf(tag)
  if (idx !== -1) {
    memberForm.value.habits.splice(idx, 1)
  } else {
    memberForm.value.habits.push(tag)
  }
}

const handleSubmitMember = async () => {
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
      initialGift: memberForm.value.chargeOption?.gift || 0
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
        paymentMethod: 'FREE'
      })
      const backendMemberId = regRes?.id || regRes?.data?.id
      if (backendMemberId) {
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
        }
      }
    } catch (apiErr) {
      console.warn('Backend register sync skipped, using local store', apiErr)
    }

    ElMessage.success('会员开卡成功！欢迎加入会员！')
  } catch (e: any) {
    ElMessage.error(e.message || '开卡失败')
  } finally {
    submittingMember.value = false
  }
}

const resetMemberForm = () => {
  memberSuccess.value = false
  memberForm.value.phone = ''
  memberForm.value.name = ''
  memberForm.value.chargeOption = chargeOptions[0]
}

const handleGoMemberPortal = () => {
  // 设置顾客会员登录态并跳转
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

// -----------------------------------------------------------------------------
// B. 员工自助入职申请与账号开通
// -----------------------------------------------------------------------------
const staffSuccess = ref(false)
const submittingStaff = ref(false)
const createdStaff = ref<any>(null)

const availablePositions = computed(() => {
  const ind = (systemData.currentIndustry || storeConfig.industry || 'BEAUTY') as 'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL'
  if (ind === 'RESTAURANT') {
    return [
      { postName: '餐厅店长/运营总监', role: 'STORE_MANAGER', dept: '门店管理部', preset: 'MANAGER' },
      { postName: '前厅领班/主管', role: 'CASHIER', dept: '前厅服务部', preset: 'CASHIER' },
      { postName: '招牌热菜主厨', role: 'TECHNICIAN', dept: '后厨烹饪部', preset: 'TECHNICIAN' },
      { postName: '资深传菜品控员', role: 'TECHNICIAN', dept: '品质保障部', preset: 'TECHNICIAN' },
      { postName: '前台迎宾/收银员', role: 'CASHIER', dept: '前台运营部', preset: 'CASHIER' }
    ]
  } else if (ind === 'AUTO') {
    return [
      { postName: '汽修总监/店长', role: 'STORE_MANAGER', dept: '门店运营部', preset: 'MANAGER' },
      { postName: '资深机电快修技师', role: 'TECHNICIAN', dept: '机电维保部', preset: 'TECHNICIAN' },
      { postName: '汽车微修美容技师', role: 'TECHNICIAN', dept: '洗美养护部', preset: 'TECHNICIAN' },
      { postName: '贴膜改色工艺师', role: 'TECHNICIAN', dept: '车身改色部', preset: 'TECHNICIAN' },
      { postName: '首席接待服务顾问', role: 'CASHIER', dept: '客户接待部', preset: 'CASHIER' }
    ]
  } else if (ind === 'RETAIL') {
    return [
      { postName: '运营总监/店长', role: 'STORE_MANAGER', dept: '店铺管理部', preset: 'MANAGER' },
      { postName: '选品采购/陈列经理', role: 'TECHNICIAN', dept: '商品采销部', preset: 'TECHNICIAN' },
      { postName: '资深导购/销售顾问', role: 'CASHIER', dept: '门店销售部', preset: 'CASHIER' },
      { postName: '总仓库存质检员', role: 'TECHNICIAN', dept: '仓储物流部', preset: 'TECHNICIAN' }
    ]
  } else {
    return [
      { postName: '沙龙旗舰店长', role: 'STORE_MANAGER', dept: '门店管理部', preset: 'MANAGER' },
      { postName: '发型总监/主理人', role: 'TECHNICIAN', dept: '造型设计部', preset: 'TECHNICIAN' },
      { postName: '资深发型师', role: 'TECHNICIAN', dept: '造型设计部', preset: 'TECHNICIAN' },
      { postName: '前台收银主管', role: 'CASHIER', dept: '前台运营部', preset: 'CASHIER' },
      { postName: '发型助理/洗护师', role: 'TECHNICIAN', dept: '养护服务部', preset: 'TECHNICIAN' },
      { postName: '高级日式美甲美睫师', role: 'TECHNICIAN', dept: '手足美学部', preset: 'TECHNICIAN' }
    ]
  }
})

const staffForm = ref({
  realName: '',
  gender: 'MALE' as 'MALE' | 'FEMALE',
  phone: '',
  accountPassword: '123456',
  postInfo: null as any,
  allowedStoreIds: [targetStoreId.value],
  experience: '',
  agree: true
})

// 初始化默认岗位
if (availablePositions.value.length > 0) {
  staffForm.value.postInfo = availablePositions.value[0]
}

const handleSubmitStaff = async () => {
  if (!staffForm.value.realName.trim()) {
    ElMessage.warning('请输入您的真实姓名')
    return
  }
  if (!staffForm.value.phone || !/^1[3-9]\d{9}$/.test(staffForm.value.phone.trim())) {
    ElMessage.warning('请输入有效的11位手机号码')
    return
  }
  if (!staffForm.value.accountPassword || staffForm.value.accountPassword.length < 4) {
    ElMessage.warning('请输入至少4位登录密码')
    return
  }
  if (staffForm.value.allowedStoreIds.length === 0) {
    ElMessage.warning('请至少选择一家执业门店')
    return
  }
  if (!staffForm.value.agree) {
    ElMessage.warning('请勾选入职确认承诺')
    return
  }

  submittingStaff.value = true
  try {
    // 依据岗位自动赋予默认页签权限
    let menuPaths = ['/dashboard', '/members', '/products', '/appointments', '/inventory', '/profile']
    if (staffForm.value.postInfo.preset === 'CASHIER') {
      menuPaths = ['/dashboard', '/members', '/products', '/card-template', '/appointments', '/expenses', '/inventory', '/profile']
    } else if (staffForm.value.postInfo.preset === 'MANAGER') {
      menuPaths = allSystemMenus.filter(m => m.path !== '/settings').map(m => m.path)
    }

    const newStaff = systemData.addStaff({
      storeId: staffForm.value.allowedStoreIds[0] || targetStoreId.value,
      realName: staffForm.value.realName.trim(),
      phone: staffForm.value.phone.trim(),
      postName: staffForm.value.postInfo.postName,
      role: staffForm.value.postInfo.role as any,
      department: staffForm.value.postInfo.dept,
      gender: staffForm.value.gender,
      baseSalary: 4500,
      hasSystemAccount: false,
      accountUsername: staffForm.value.phone.trim(),
      accountPassword: staffForm.value.accountPassword.trim(),
      accountStatus: 'PENDING_REVIEW',
      isSelfApplied: true,
      auditStatus: 'PENDING',
      experience: staffForm.value.experience?.trim() || '',
      allowedStoreIds: staffForm.value.allowedStoreIds,
      allowedMenuPaths: menuPaths
    })

    createdStaff.value = newStaff
    staffSuccess.value = true
    ElMessage.success(`入职申请已提交！请等待店长或租户老板审核通过后方可登录。`)
  } catch (e: any) {
    ElMessage.error(e.message || '入职登记失败')
  } finally {
    submittingStaff.value = false
  }
}

const resetStaffForm = () => {
  staffSuccess.value = false
  staffForm.value.realName = ''
  staffForm.value.phone = ''
}

const handleGoLogin = () => {
  router.push('/login')
}
</script>

<style scoped>
.self-register-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle at 50% 30%, #1e293b 0%, #0f172a 100%);
  padding: 24px 16px;
  box-sizing: border-box;
}

.self-register-card {
  width: 100%;
  max-width: 540px;
  background: #ffffff;
  border-radius: 20px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.4);
  overflow: hidden;
}

/* 门店招牌 */
.store-banner {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 20px 24px;
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
  color: #fff;
}

.store-logo {
  font-size: 36px;
  line-height: 1;
}

.store-name-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.store-name {
  font-size: 17px;
  font-weight: 800;
}

.store-sub {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 4px;
}

/* 顶栏双模式切换 Tab */
.portal-tab-header {
  display: flex;
  border-bottom: 2px solid #e2e8f0;
  background: #f8fafc;
}

.portal-tab-item {
  flex: 1;
  text-align: center;
  padding: 14px 10px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 700;
  color: #64748b;
  transition: all 0.2s ease;
}

.portal-tab-item.active {
  color: #0284c7;
  background: #ffffff;
  border-bottom: 3px solid #0284c7;
}

.portal-tab-item .tab-icon {
  font-size: 16px;
}

.form-container {
  padding: 24px;
}

.mode-tip-banner {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px 14px;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 10px;
  margin-bottom: 20px;
  font-size: 12.5px;
  color: #166534;
  line-height: 1.5;
}

.staff-tip-banner {
  background: #eff6ff;
  border-color: #bfdbfe;
  color: #1e40af;
}

.t-icon {
  font-size: 16px;
  flex-shrink: 0;
}

/* 表单内部定制 */
.custom-form :deep(.el-form-item__label) {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
  padding-bottom: 4px;
}

/* 习惯标签 */
.habit-tags-box {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.habit-tag {
  font-size: 12px;
  padding: 5px 12px;
  border-radius: 999px;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  color: #475569;
  cursor: pointer;
  transition: all 0.2s ease;
}

.habit-tag:hover {
  border-color: #0284c7;
  color: #0284c7;
}

.habit-tag.selected {
  background: #e0f2fe;
  border-color: #0284c7;
  color: #0369a1;
  font-weight: 600;
}

/* 首充套餐 */
.charge-options-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  width: 100%;
}

.charge-opt-card {
  position: relative;
  padding: 12px;
  border: 1.5px solid #e2e8f0;
  border-radius: 10px;
  cursor: pointer;
  background: #fff;
  transition: all 0.2s ease;
}

.charge-opt-card:hover {
  border-color: #0284c7;
}

.charge-opt-card.selected {
  border-color: #0284c7;
  background: #f0f9ff;
}

.opt-title {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
}

.opt-price {
  font-size: 18px;
  font-weight: 800;
  color: #0284c7;
  margin-top: 4px;
}

.opt-badge {
  position: absolute;
  top: 8px;
  right: 8px;
  font-size: 10px;
  background: #ec4899;
  color: #fff;
  padding: 1px 6px;
  border-radius: 4px;
  font-weight: 600;
}

.store-check-inline {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.agreement-box {
  margin: 16px 0;
  font-size: 12px;
}

.w-full {
  width: 100%;
}

.submit-btn {
  height: 44px;
  font-size: 15px;
  font-weight: 700;
  letter-spacing: 0.5px;
}

/* 成功结果区 */
.success-result-box {
  text-align: center;
  padding: 10px 0;
}

.success-icon {
  font-size: 48px;
  margin-bottom: 8px;
}

.success-title {
  font-size: 18px;
  font-weight: 800;
  color: #0f172a;
}

.success-desc {
  font-size: 13px;
  color: #64748b;
  margin-top: 4px;
  margin-bottom: 20px;
}

/* 电子会员卡视效 */
.member-card-preview {
  background: linear-gradient(135deg, #0284c7 0%, #0369a1 50%, #0c4a6e 100%);
  border-radius: 16px;
  padding: 20px 24px;
  color: #fff;
  text-align: left;
  box-shadow: 0 10px 30px rgba(2, 132, 199, 0.3);
  margin-bottom: 20px;
  transition: all 0.3s ease;
}

.member-card-preview.card-regular {
  background: linear-gradient(135deg, #0f2027 0%, #203a43 50%, #2c5364 100%);
  box-shadow: 0 10px 30px rgba(32, 58, 67, 0.3);
}

.member-card-preview.card-silver {
  background: linear-gradient(135deg, #334155 0%, #475569 50%, #64748b 100%);
  box-shadow: 0 10px 30px rgba(71, 85, 105, 0.3);
}

.member-card-preview.card-gold {
  background: linear-gradient(135deg, #78350f 0%, #b45309 50%, #92400e 100%);
  box-shadow: 0 10px 30px rgba(180, 83, 9, 0.35);
}

.member-card-preview.card-platinum {
  background: linear-gradient(135deg, #31104b 0%, #581c87 50%, #6b21a8 100%);
  box-shadow: 0 10px 30px rgba(107, 33, 168, 0.35);
}

.member-card-preview.card-diamond {
  background: linear-gradient(135deg, #020617 0%, #0f172a 50%, #1e1b4b 100%);
  box-shadow: 0 10px 30px rgba(15, 23, 42, 0.5);
}

.m-card-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.m-brand {
  font-size: 15px;
  font-weight: 700;
}

.m-level {
  font-size: 12px;
  background: rgba(255, 255, 255, 0.2);
  padding: 2px 10px;
  border-radius: 999px;
}

.m-card-no {
  font-size: 20px;
  font-weight: 800;
  letter-spacing: 2px;
  font-family: monospace;
  margin-bottom: 20px;
}

.m-card-bottom {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.m-owner {
  font-size: 15px;
  font-weight: 700;
}

.m-store {
  font-size: 11px;
  color: #bae6fd;
  margin-top: 2px;
}

.m-balance {
  text-align: right;
}

.m-bal-val {
  font-size: 18px;
  font-weight: 800;
}

.m-bal-lbl {
  font-size: 10px;
  color: #bae6fd;
}

.welcome-privileges {
  background: #f8fafc;
  border-radius: 12px;
  padding: 14px;
  margin-bottom: 24px;
  text-align: left;
  font-size: 13px;
  color: #334155;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

/* 员工账号确认卡 */
.staff-account-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px 20px;
  text-align: left;
  margin-bottom: 24px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sac-row {
  display: flex;
  align-items: center;
  font-size: 13px;
}

.sac-lbl {
  width: 100px;
  color: #64748b;
}

.sac-val {
  flex: 1;
  color: #1e293b;
}

.portal-footer {
  padding: 14px;
  text-align: center;
  background: #f8fafc;
  border-top: 1px solid #f1f5f9;
}
</style>
