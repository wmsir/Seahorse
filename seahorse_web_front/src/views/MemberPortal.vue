<template>
  <div class="member-portal-container" v-loading="loading">
    <!-- 顶部欢迎卡片 -->
    <div class="member-welcome-card">
      <div class="welcome-left">
        <el-avatar :size="64" class="avatar-box">
          {{ profile.member?.name?.substring(0, 1) || '客' }}
        </el-avatar>
        <div class="welcome-info">
          <div class="name-row">
            <h2 class="member-name">{{ profile.member?.name || '顾客会员' }}</h2>
            <el-tag effect="dark" type="warning" class="tier-tag">
              {{ profile.levelName || formatTier(profile.member?.level || profile.member?.tier) }}
            </el-tag>
            <el-tag type="success" size="small">
              {{ profile.member?.status === 'ACTIVE' ? '正常在册' : '冻结' }}
            </el-tag>
          </div>
          <p class="slogan-text">{{ storeSloganText }}</p>
          <div class="meta-row">
            <span>💳 会员卡号：{{ profile.member?.memberNo || '-' }}</span>
            <span style="margin-left: 16px">📱 手机号：{{ profile.member?.phone || '-' }}</span>
            <span style="margin-left: 16px">🎂 生日：{{ profile.member?.birthday || '未填写' }}</span>
            <span style="margin-left: 16px">⚧ 性别：{{ formatGender(profile.member?.gender) }}</span>
          </div>
        </div>
      </div>
      <div class="welcome-right" style="display: flex; gap: 10px;">
        <el-button type="success" icon="FullScreen" @click="openMemberQrModal">
          📱 出示会员码
        </el-button>
        <el-button type="primary" plain icon="Edit" @click="openEditProfile">
          修改个人资料
        </el-button>
      </div>
    </div>

    <!-- 资产总览 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :xs="12" :sm="6">
        <el-card shadow="hover" class="stat-box">
          <div class="stat-label">本金余额 (可退/保值)</div>
          <div class="stat-val principal">¥{{ (profile.balance?.principalBalance || 0).toFixed(2) }}</div>
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="6">
        <el-card shadow="hover" class="stat-box">
          <div class="stat-label">赠金余额 (不可提现)</div>
          <div class="stat-val gift">¥{{ (profile.balance?.giftBalance || 0).toFixed(2) }}</div>
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="6">
        <el-card shadow="hover" class="stat-box">
          <div class="stat-label">积分与成长值</div>
          <div class="stat-val points">{{ profile.currentPoints ?? profile.member?.points ?? 0 }} pt</div>
        </el-card>
      </el-col>
      <el-col :xs="12" :sm="6">
        <el-card shadow="hover" class="stat-box">
          <div class="stat-label">有效次卡/项目包</div>
          <div class="stat-val cards">{{ profile.timeCards?.length || 0 }} 张</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 会员等级晋升与成长中心卡片 (清晰查看距离升级差多少积分/经验) -->
    <el-card shadow="hover" class="member-growth-portal-card">
      <div class="growth-portal-header">
        <div class="portal-card-left">
          <span class="portal-badge-icon">👑</span>
          <div>
            <div class="portal-tier-title">
              {{ profile.levelName || formatTier(profile.member?.level || profile.member?.tier) }}
              <el-tag size="small" type="success" effect="plain" style="margin-left: 8px;">
                {{ getServiceDiscountText() }}
              </el-tag>
            </div>
            <div class="portal-tier-sub">消费 1 元 = 1 积分，达成阶梯门槛自动平滑升级，永久尊享专属特权</div>
          </div>
        </div>
        <el-button type="warning" plain size="small" @click="showRulesModal = true">
          📜 晋升规则与权益表
        </el-button>
      </div>

      <!-- 成长差距与进度条 -->
      <div class="growth-portal-body">
        <div class="progress-meta-row">
          <span>当前成长积分: <b class="points-val">{{ profile.currentPoints ?? profile.member?.points ?? 0 }}</b> 分</span>
          <span v-if="getNextLevelName()">
            距离晋升【<b class="next-lvl-name">{{ getNextLevelName() }}</b>】还差 
            <b class="gap-val">{{ getPointsGap() }}</b> 积分/经验
          </span>
          <span v-else class="top-honor">
            🎉 您已尊享最高等级【黑钻至尊卡】顶格特权！
          </span>
        </div>

        <el-progress
          :percentage="getGrowthPercentage()"
          :stroke-width="12"
          :status="getGrowthPercentage() >= 100 ? 'success' : undefined"
          :show-text="false"
          style="margin: 12px 0 16px 0;"
        />

        <!-- 六大等级里程碑路线图 -->
        <div class="level-ladder-milestones">
          <div
            v-for="lvl in standardLevelRules"
            :key="lvl.levelCode"
            class="ladder-step"
            :class="{ active: (profile.currentPoints ?? profile.member?.points ?? 0) >= lvl.threshold }"
          >
            <div class="step-dot"></div>
            <div class="step-name">{{ lvl.levelName }}</div>
            <div class="step-threshold">{{ lvl.threshold }}分</div>
            <div class="step-discount">{{ lvl.discount }}</div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 核心功能标签页 -->
    <el-card class="main-content-card" shadow="hover">
      <el-tabs v-model="activeTab">
        <!-- 海马体记忆偏好档案 -->
        <el-tab-pane label="🧠 我的海马体记忆档案" name="memory">
          <div class="pane-header">
            <div>
              <h3 class="pane-title">海马体专属偏好与服务禁忌</h3>
              <p class="pane-desc">
                您所记录的喜好、服务禁忌与体质特征，将实时同步给每位接待技师与服务管家。
              </p>
            </div>
            <el-button type="primary" plain icon="Plus" @click="openAddPref">
              添加新偏好/记忆标签
            </el-button>
          </div>

          <el-empty
            v-if="!profile.preferences || profile.preferences.length === 0"
            description="暂无海马体记忆偏好，点击上方按钮添加您的服务偏好～"
          />

          <el-row :gutter="16" v-else style="margin-top: 14px">
            <el-col
              :xs="24"
              :sm="12"
              :md="8"
              v-for="(pref, idx) in profile.preferences"
              :key="idx"
            >
              <div class="pref-card">
                <div class="pref-top">
                  <span class="pref-key">{{ pref.preferenceKey }}</span>
                  <el-tag size="small" type="info">{{ getCategoryName(pref.category) }}</el-tag>
                </div>
                <div class="pref-val">{{ pref.preferenceValue }}</div>
                <div class="pref-notes" v-if="pref.notes">备注：{{ pref.notes }}</div>
              </div>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- 我的次卡包 -->
        <el-tab-pane label="🎟️ 我的次卡与项目包" name="timecards">
          <el-empty
            v-if="!profile.timeCards || profile.timeCards.length === 0"
            description="您当前还没有任何次卡包或疗程包"
          />
          <el-row :gutter="16" v-else>
            <el-col
              :xs="24"
              :sm="12"
              :md="8"
              v-for="tc in profile.timeCards"
              :key="tc.id"
            >
              <div class="timecard-ticket">
                <div class="tc-name">{{ tc.itemName }}</div>
                <div class="tc-remaining">
                  剩余 <span class="num">{{ tc.remainingCount }}</span> / {{ tc.totalCount }} 次
                </div>
                <div class="tc-expire">有效期至：{{ tc.expireDate }}</div>
              </div>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- 历史消费与结账单 -->
        <el-tab-pane label="🧾 消费明细与对账" name="orders">
          <div class="pane-header">
            <div>
              <h3 class="pane-title">历史结账与消费流水</h3>
              <p class="pane-desc">每一笔本金扣除与赠金抵扣均有迹可循，透明消费。</p>
            </div>
            <el-button type="default" plain @click="fetchOrders">刷新明细</el-button>
          </div>

          <el-table :data="orders" v-loading="ordersLoading" style="width: 100%; margin-top: 14px" border stripe>
            <el-table-column prop="id" label="账单号" width="90" align="center" />
            <el-table-column prop="sessionId" label="会话ID" width="90" align="center" />
            <el-table-column prop="totalAmount" label="消费总额" width="120" align="right">
              <template #default="scope">
                <span style="font-weight: 700">¥{{ (scope.row.totalAmount || 0).toFixed(2) }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="principalPaid" label="本金扣除" width="110" align="right">
              <template #default="scope">
                ¥{{ (scope.row.principalPaid || 0).toFixed(2) }}
              </template>
            </el-table-column>
            <el-table-column prop="giftPaid" label="赠金抵扣" width="110" align="right">
              <template #default="scope">
                ¥{{ (scope.row.giftPaid || 0).toFixed(2) }}
              </template>
            </el-table-column>
            <el-table-column prop="payMethod" label="结算通道" width="110" align="center">
              <template #default="scope">
                <el-tag size="small">{{ scope.row.payMethod || '会员双轨' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="支付状态" width="100" align="center">
              <template #default="scope">
                <el-tag :type="scope.row.status === 'PAID' ? 'success' : 'info'" size="small">
                  {{ scope.row.status === 'PAID' ? '已付讫' : scope.row.status }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createdAt" label="消费时间">
              <template #default="scope">
                {{ formatDate(scope.row.createdAt) }}
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 修改个人信息弹窗 -->
    <el-dialog v-model="editDialogVisible" title="修改个人信息" width="460px" destroy-on-close>
      <el-form :model="editForm" label-width="90px">
        <el-form-item label="姓名" required>
          <el-input v-model="editForm.name" placeholder="请输入您的姓名" />
        </el-form-item>
        <el-form-item label="手机号码" required>
          <el-input v-model="editForm.phone" placeholder="请输入手机号码" />
        </el-form-item>
        <el-form-item label="性别">
          <el-radio-group v-model="editForm.gender">
            <el-radio value="FEMALE">女士</el-radio>
            <el-radio value="MALE">先生</el-radio>
            <el-radio value="UNKNOWN">保密</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="生日">
          <el-date-picker
            v-model="editForm.birthday"
            type="date"
            placeholder="请选择出生日期"
            value-format="YYYY-MM-DD"
            style="width: 100%"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingProfile" @click="submitEditProfile">保存修改</el-button>
      </template>
    </el-dialog>

    <!-- 添加偏好弹窗 -->
    <el-dialog v-model="addPrefDialogVisible" title="添加海马体服务偏好" width="480px" destroy-on-close>
      <el-form :model="prefForm" label-width="100px">
        <el-form-item label="偏好类型" required>
          <el-select v-model="prefForm.category" style="width: 100%">
            <el-option label="美业/造型偏好" value="BEAUTY_HAIR" />
            <el-option label="餐饮/口味禁忌" value="RESTAURANT_TASTE" />
            <el-option label="汽修/爱车习惯" value="AUTO_VEHICLE" />
            <el-option label="通用习惯/特殊禁忌" value="HABIT" />
          </el-select>
        </el-form-item>
        <el-form-item label="偏好项目" required>
          <el-input v-model="prefForm.preferenceKey" placeholder="如：水温、香菜、机油品牌、空调" />
        </el-form-item>
        <el-form-item label="具体偏好值" required>
          <el-input v-model="prefForm.preferenceValue" placeholder="如：偏温热、免葱姜香菜、偏好美孚全合成" />
        </el-form-item>
        <el-form-item label="补充备注">
          <el-input v-model="prefForm.notes" type="textarea" :rows="2" placeholder="如有特别需要叮嘱的事项" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addPrefDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingPref" @click="submitAddPref">保存偏好</el-button>
      </template>
    </el-dialog>

    <!-- 会员消费二维码弹窗 -->
    <el-dialog v-model="memberQrDialogVisible" title="📱 我的海马体会员消费码" width="420px" align-center>
      <div style="display: flex; flex-direction: column; align-items: center; padding: 10px 0;">
        <div style="background: #ffffff; padding: 16px; border-radius: 16px; border: 1.5px solid #0d9488; box-shadow: 0 4px 16px rgba(13,148,136,0.12); text-align: center;">
          <img v-if="memberQrDataUrl" :src="memberQrDataUrl" style="width: 220px; height: 220px; display: block;" alt="会员消费码" />
          <div v-else style="width: 220px; height: 220px; display: flex; align-items: center; justify-content: center;">生成中...</div>
          <div style="margin-top: 10px; font-weight: bold; font-size: 15px; letter-spacing: 1px; color: #1e293b;">
            {{ profile.member?.phone || profile.member?.memberNo }}
          </div>
        </div>
        <div style="margin-top: 14px; font-size: 13px; color: #64748b; text-align: center; line-height: 1.6;">
          向门店工作人员出示此二维码<br/>
          支持移动 APP 摄像头扫码与前台 USB 扫码盒即刻识别
        </div>
      </div>
      <template #footer>
        <el-button @click="memberQrDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 会员等级晋升规则与权益说明弹窗 (会员自主查看) -->
    <el-dialog v-model="showRulesModal" title="📜 会员成长阶梯与等级权益说明" width="680px">
      <div class="level-rules-dialog-content">
        <el-alert
          type="success"
          show-icon
          :closable="false"
          title="每消费 1 元积 1 分 · 自动平滑晋级"
          description="到店服务或购买商品，实付金额自动转为成长经验与积分。积分达到下一等级要求即刻自动晋升，折扣特权立享！"
          style="margin-bottom: 14px;"
        />
        <el-table :data="standardLevelRules" border stripe style="width: 100%">
          <el-table-column prop="levelName" label="会员等级" width="130">
            <template #default="{ row }">
              <span :style="getLevelBadgeStyle(row.levelCode)">{{ row.levelName }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="threshold" label="成长门槛" width="110">
            <template #default="{ row }">
              <b style="color: #0284c7;">{{ row.threshold }} 分</b>
            </template>
          </el-table-column>
          <el-table-column prop="discount" label="服务/商品折扣" width="160">
            <template #default="{ row }">
              <el-tag size="small" :type="row.threshold > 0 ? 'warning' : 'info'">{{ row.discount }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="privileges" label="会员专属特权" />
        </el-table>
      </div>
      <template #footer>
        <el-button type="primary" @click="showRulesModal = false">知道了</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import QRCode from 'qrcode'
import {
  getMyProfileApi,
  updateMyProfileApi,
  saveMyPreferenceApi,
  getMyOrdersApi
} from '@/api'
import { useSystemDataStore } from '@/stores/systemDataStore'

const route = useRoute()
const systemData = useSystemDataStore()

const getTargetMemberIdentity = () => {
  const qMemberId = route.query.memberId ? Number(route.query.memberId) : undefined
  const qPhone = route.query.phone ? String(route.query.phone).trim() : undefined
  const lsMemberId = localStorage.getItem('seahorse_member_id') ? Number(localStorage.getItem('seahorse_member_id')) : undefined
  const lsPhone = localStorage.getItem('seahorse_member_phone') ? String(localStorage.getItem('seahorse_member_phone')).trim() : undefined

  return {
    memberId: (qMemberId && qMemberId > 0) ? qMemberId : ((lsMemberId && lsMemberId > 0) ? lsMemberId : undefined),
    phone: qPhone || lsPhone || undefined
  }
}

const memberQrDialogVisible = ref(false)
const memberQrDataUrl = ref('')

const openMemberQrModal = async () => {
  memberQrDialogVisible.value = true
  const phoneOrNo = profile.value.member?.phone || profile.value.member?.memberNo || '13800000000'
  const qrText = `SEAHORSE:MEMBER:${phoneOrNo}`
  try {
    memberQrDataUrl.value = await QRCode.toDataURL(qrText, {
      width: 260,
      margin: 2,
      color: {
        dark: '#0f172a',
        light: '#ffffff'
      }
    })
  } catch (err) {
    console.error('Failed to generate member QR', err)
  }
}

const loading = ref(false)
const activeTab = ref('memory')

const profile = ref<any>({
  member: null,
  balance: null,
  timeCards: [],
  preferences: []
})

const storeSloganText = computed(() => {
  const s = systemData.stores.find((st: any) => st.storeId === profile.value.member?.registeredStoreId) || systemData.stores[0]
  if (s && s.slogan) return `${s.slogan} ｜ 私域专属会员档案`
  if (s && s.storeName) return `${s.storeName} ｜ 私域专属会员中心`
  return '海马会员，记住每位好客 ｜ 私域专属记忆档案'
})

const orders = ref<any[]>([])
const ordersLoading = ref(false)

// 编辑个人资料
const editDialogVisible = ref(false)
const savingProfile = ref(false)
const editForm = ref({
  name: '',
  phone: '',
  gender: 'FEMALE',
  birthday: ''
})

// 添加偏好
const addPrefDialogVisible = ref(false)
const savingPref = ref(false)
const prefForm = ref({
  category: 'HABIT',
  preferenceKey: '',
  preferenceValue: '',
  notes: ''
})

const fetchProfile = async () => {
  loading.value = true
  const { memberId, phone } = getTargetMemberIdentity()
  try {
    const res: any = await getMyProfileApi(memberId, phone)
    if (res) {
      profile.value = res.member ? res : (res.data || res)
    }
  } catch (err: any) {
    // 演示/断网兜底：从系统数据中精准匹配当前会员 (以手机号优先，绝不能用 ID=1 误匹配预置林清雅)
    const memberName = localStorage.getItem('seahorse_user') || ''
    const cachedMembers = localStorage.getItem('seahorse_members_data')
    let found: any = null
    if (cachedMembers) {
      try {
        const list = JSON.parse(cachedMembers)
        found = list.find((m: any) => (phone && m.phone === phone) || (memberId && m.id === memberId && (!phone || m.phone === phone)) || (memberName && m.name === memberName))
      } catch {}
    }
    if (!found) {
      found = systemData.members.find(m => (phone && m.phone === phone) || (memberId && m.id === memberId && (!phone || m.phone === phone)) || (memberName && m.name === memberName))
    }
    if (found) {
      const savedPrefsRaw = localStorage.getItem(`seahorse_member_preferences_${found.id}`) ||
                            localStorage.getItem(`seahorse_member_preferences_${found.phone}`)
      let prefs = found.preferences || []
      if ((!prefs || prefs.length === 0) && savedPrefsRaw) {
        try { prefs = JSON.parse(savedPrefsRaw) } catch {}
      }
      if ((!prefs || prefs.length === 0) && found.habits && found.habits.length > 0) {
        prefs = found.habits.map((h: string, idx: number) => ({
          id: idx + 1,
          category: 'HABIT',
          tagKey: '常客自主偏好',
          tagValue: h,
          notes: '开卡自主登记'
        }))
      }
      const stats = systemData.membersWithStats.find(m => m.id === found.id)
      profile.value = {
        member: found,
        balance: {
          principalBalance: stats?.principalBalance || 0,
          giftBalance: stats?.giftBalance || 0,
          totalBalance: stats?.totalBalance || 0
        },
        timeCards: stats?.timeCards || [],
        preferences: prefs
      }
    } else {
      ElMessage.error(err.message || '获取会员资料失败')
    }
  } finally {
    loading.value = false
  }
}

const fetchOrders = async () => {
  ordersLoading.value = true
  const { memberId, phone } = getTargetMemberIdentity()
  try {
    const res: any = await getMyOrdersApi(memberId, phone)
    if (res) {
      orders.value = Array.isArray(res) ? res : (res.data || [])
    }
  } catch (err: any) {
    ElMessage.error(err.message || '获取消费明细失败')
  } finally {
    ordersLoading.value = false
  }
}

const openEditProfile = () => {
  const m = profile.value.member || {}
  editForm.value = {
    name: m.name || '',
    phone: m.phone || '',
    gender: m.gender || 'FEMALE',
    birthday: m.birthday || ''
  }
  editDialogVisible.value = true
}

const submitEditProfile = async () => {
  if (!editForm.value.name.trim()) {
    ElMessage.warning('请输入姓名')
    return
  }
  if (!editForm.value.phone.trim()) {
    ElMessage.warning('请输入手机号码')
    return
  }
  savingProfile.value = true
  const { memberId, phone } = getTargetMemberIdentity()
  try {
    await updateMyProfileApi(editForm.value, memberId, phone)
    ElMessage.success('个人信息更新成功')
    editDialogVisible.value = false
    await fetchProfile()
  } catch (err: any) {
    ElMessage.error(err.message || '更新个人信息失败')
  } finally {
    savingProfile.value = false
  }
}

const openAddPref = () => {
  prefForm.value = {
    category: 'HABIT',
    preferenceKey: '',
    preferenceValue: '',
    notes: ''
  }
  addPrefDialogVisible.value = true
}

const submitAddPref = async () => {
  if (!prefForm.value.preferenceKey.trim() || !prefForm.value.preferenceValue.trim()) {
    ElMessage.warning('请填写偏好项目和具体偏好')
    return
  }
  savingPref.value = true
  const { memberId, phone } = getTargetMemberIdentity()
  try {
    await saveMyPreferenceApi(prefForm.value, memberId, phone)
    ElMessage.success('偏好保存成功，海马体已精准记忆！')
    addPrefDialogVisible.value = false
    await fetchProfile()
  } catch (err: any) {
    ElMessage.error(err.message || '保存偏好失败')
  } finally {
    savingPref.value = false
  }
}

const showRulesModal = ref(false)

const standardLevelRules = [
  { levelCode: 'REGULAR', levelName: '普卡会员', threshold: 0, discount: '无折扣 (100%)', privileges: '进店建档、海马体偏好常态记忆、消费基础积分' },
  { levelCode: 'SILVER', levelName: '荣耀银卡', threshold: 300, discount: '服务95折 / 商品98折', privileges: '服务95折、生日月享50元抵用券、双倍积分日' },
  { levelCode: 'GOLD', levelName: '黄金VIP卡', threshold: 800, discount: '服务90折 / 商品95折', privileges: '服务9折、免排队预约优先通道、生日免费专属体验' },
  { levelCode: 'VIP', levelName: 'VIP尊享卡', threshold: 1200, discount: '服务88折 / 商品92折', privileges: '服务88折、专属金牌技师优先点单、节日私享定制礼盒' },
  { levelCode: 'PLATINUM', levelName: '至尊白金卡', threshold: 2000, discount: '服务85折 / 商品90折', privileges: '全场85折、专属私享包间、免费携1位亲友享同折' },
  { levelCode: 'DIAMOND', levelName: '黑钻至尊卡', threshold: 3500, discount: '服务80折 / 商品85折', privileges: '全场8折、总监技师免服务费、终身顶格尊崇待遇' }
]

const formatTier = (tier?: string) => {
  const t = (tier || '').toUpperCase()
  if (t.includes('DIAMOND') || t.includes('黑钻') || t.includes('黑金')) return '黑钻至尊卡'
  if (t.includes('PLATINUM') || t.includes('白金') || t.includes('至尊')) return '至尊白金卡'
  if (t.includes('VIP') || t.includes('尊享')) return 'VIP尊享卡'
  if (t.includes('GOLD') || t.includes('金卡') || t.includes('金')) return '黄金VIP卡'
  if (t.includes('SILVER') || t.includes('银卡') || t.includes('银')) return '荣耀银卡'
  return '普卡会员'
}

const getNextLevelName = () => {
  if (profile.value?.nextLevelName) return profile.value.nextLevelName
  const points = profile.value?.currentPoints ?? profile.value?.member?.points ?? 0
  const next = standardLevelRules.find(r => r.threshold > points)
  return next ? next.levelName : null
}

const getPointsGap = () => {
  if (profile.value?.pointsToNextLevel != null) return profile.value.pointsToNextLevel
  const points = profile.value?.currentPoints ?? profile.value?.member?.points ?? 0
  const next = standardLevelRules.find(r => r.threshold > points)
  return next ? Math.max(0, next.threshold - points) : 0
}

const getGrowthPercentage = () => {
  if (profile.value?.growthProgressRatio != null) {
    return Math.min(100, Math.round(profile.value.growthProgressRatio * 100))
  }
  const points = profile.value?.currentPoints ?? profile.value?.member?.points ?? 0
  const next = standardLevelRules.find(r => r.threshold > points)
  if (!next) return 100
  let currentThresh = 0
  for (let i = standardLevelRules.length - 1; i >= 0; i--) {
    if (points >= standardLevelRules[i].threshold) {
      currentThresh = standardLevelRules[i].threshold
      break
    }
  }
  const range = next.threshold - currentThresh
  if (range <= 0) return 100
  return Math.min(100, Math.round(((points - currentThresh) / range) * 100))
}

const getServiceDiscountText = () => {
  const points = profile.value?.currentPoints ?? profile.value?.member?.points ?? 0
  let currentRule = standardLevelRules[0]
  for (let i = standardLevelRules.length - 1; i >= 0; i--) {
    if (points >= standardLevelRules[i].threshold) {
      currentRule = standardLevelRules[i]
      break
    }
  }
  return currentRule.discount
}

const getLevelBadgeStyle = (code?: string) => {
  const c = (code || '').toUpperCase()
  if (c.includes('DIAMOND') || c.includes('黑钻') || c.includes('黑金')) {
    return 'background: #0f172a; color: #f59e0b; border: 1px solid #f59e0b; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
  }
  if (c.includes('PLATINUM') || c.includes('白金') || c.includes('至尊')) {
    return 'background: #ede9fe; color: #7c3aed; border: 1px solid #c4b5fd; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
  }
  if (c.includes('VIP') || c.includes('尊享')) {
    return 'background: #fdf2f8; color: #db2777; border: 1px solid #fbcfe8; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
  }
  if (c.includes('GOLD') || c.includes('金卡') || c.includes('金')) {
    return 'background: #fef3c7; color: #b45309; border: 1px solid #fcd34d; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
  }
  if (c.includes('SILVER') || c.includes('银卡') || c.includes('银')) {
    return 'background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
  }
  return 'background: #ccfbf1; color: #0f766e; border: 1px solid #99f6e4; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
}

const formatGender = (gender?: string) => {
  if (gender === 'FEMALE') return '女士'
  if (gender === 'MALE') return '先生'
  return '保密'
}

const getCategoryName = (cat?: string) => {
  const map: Record<string, string> = {
    BEAUTY_HAIR: '美业发型',
    RESTAURANT_TASTE: '餐饮口味',
    AUTO_VEHICLE: '汽车服务',
    HABIT: '通用生活习惯'
  }
  return map[cat || ''] || '通用'
}

const formatDate = (str?: string) => {
  if (!str) return '-'
  return str.replace('T', ' ').substring(0, 19)
}

onMounted(() => {
  fetchProfile()
  fetchOrders()
})
</script>

<style scoped>
.member-portal-container {
  padding: 8px;
}

.member-welcome-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
  color: #ffffff;
  padding: 24px 28px;
  border-radius: 14px;
  box-shadow: 0 4px 16px rgba(30, 58, 138, 0.15);
  margin-bottom: 20px;
}

.welcome-left {
  display: flex;
  align-items: center;
  gap: 20px;
}

.avatar-box {
  background: #ffffff;
  color: #1e3a8a;
  font-weight: 700;
  font-size: 24px;
  border: 2px solid rgba(255, 255, 255, 0.8);
}

.name-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.member-name {
  font-size: 22px;
  font-weight: 700;
  margin: 0;
}

.slogan-text {
  font-size: 13px;
  color: #bfdbfe;
  margin: 6px 0;
}

.meta-row {
  font-size: 13px;
  color: #e0f2fe;
}

.stat-row {
  margin-bottom: 20px;
}

.stat-box {
  border-radius: 12px;
  text-align: center;
  padding: 10px 0;
}

.stat-label {
  font-size: 13px;
  color: #6b7280;
  margin-bottom: 6px;
}

.stat-val {
  font-size: 22px;
  font-weight: 700;
}

.stat-val.principal {
  color: #059669;
}

.stat-val.gift {
  color: #d97706;
}

.stat-val.points {
  color: #2563eb;
}

.stat-val.cards {
  color: #7c3aed;
}

.main-content-card {
  border-radius: 12px;
}

.pane-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.pane-title {
  font-size: 16px;
  font-weight: 700;
  color: #1f2937;
  margin: 0 0 4px 0;
}

.pane-desc {
  font-size: 13px;
  color: #6b7280;
  margin: 0;
}

.pref-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 16px;
  margin-bottom: 14px;
}

.pref-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.pref-key {
  font-weight: 600;
  font-size: 14px;
  color: #0f172a;
}

.pref-val {
  font-size: 14px;
  color: #2563eb;
  font-weight: 500;
}

.pref-notes {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 6px;
}

.timecard-ticket {
  background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
  border: 1px dashed #f59e0b;
  border-radius: 10px;
  padding: 16px;
  margin-bottom: 14px;
}

.tc-name {
  font-size: 16px;
  font-weight: 700;
  color: #92400e;
  margin-bottom: 8px;
}

.tc-remaining {
  font-size: 14px;
  color: #b45309;
}

.tc-remaining .num {
  font-size: 20px;
  font-weight: 700;
  color: #d97706;
}

.tc-expire {
  font-size: 12px;
  color: #78350f;
  margin-top: 6px;
}

.member-growth-portal-card {
  margin-bottom: 16px;
  border-radius: 12px;
  border: 1px solid #fed7aa;
  background: linear-gradient(135deg, #fffbeb 0%, #ffffff 100%);
}

.growth-portal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px dashed #fed7aa;
  padding-bottom: 12px;
  margin-bottom: 12px;
}

.portal-card-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.portal-badge-icon {
  font-size: 28px;
}

.portal-tier-title {
  font-size: 18px;
  font-weight: 700;
  color: #78350f;
  display: flex;
  align-items: center;
}

.portal-tier-sub {
  font-size: 12px;
  color: #b45309;
  margin-top: 2px;
}

.growth-portal-body {
  padding: 4px 0;
}

.progress-meta-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
  color: #475569;
}

.points-val {
  color: #0284c7;
  font-size: 16px;
}

.next-lvl-name {
  color: #b45309;
}

.gap-val {
  color: #ea580c;
  font-size: 16px;
}

.top-honor {
  color: #d97706;
  font-weight: bold;
}

.level-ladder-milestones {
  display: flex;
  justify-content: space-between;
  position: relative;
  margin-top: 16px;
  padding: 0 8px;
}

.ladder-step {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  flex: 1;
  position: relative;
  opacity: 0.55;
  transition: all 0.3s;
}

.ladder-step.active {
  opacity: 1;
}

.step-dot {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: #cbd5e1;
  border: 2px solid #ffffff;
  box-shadow: 0 0 0 1px #94a3b8;
  margin-bottom: 6px;
}

.ladder-step.active .step-dot {
  background: #f59e0b;
  box-shadow: 0 0 0 2px #d97706;
}

.step-name {
  font-size: 11px;
  font-weight: 600;
  color: #334155;
}

.step-threshold {
  font-size: 10px;
  color: #64748b;
  margin-top: 1px;
}

.step-discount {
  font-size: 10px;
  color: #0284c7;
  font-weight: 500;
  margin-top: 1px;
}
</style>
