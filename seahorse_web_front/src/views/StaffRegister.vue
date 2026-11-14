<template>
  <div class="staff-register-container">
    <div class="staff-register-card">
      <!-- 门店顶头招牌展示 (展示当前具体门店的详细档案与真实信息) -->
      <div class="store-banner">
        <div class="store-logo-wrap">
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
        </div>
        <div class="store-info">
          <div class="store-name-row">
            <span class="store-name">{{ currentStore?.storeName || '海马智慧门店' }}</span>
            <el-tag size="small" :type="currentStore?.isHeadquarter ? 'danger' : 'success'" effect="plain">
              {{ currentStore?.isHeadquarter ? '旗舰总店' : '直营分店' }}
            </el-tag>
            <el-tag size="small" type="primary" effect="light">营业中</el-tag>
          </div>
          <div class="store-meta-list">
            <div class="meta-item">
              <span class="m-icon">📍</span>
              <span class="m-text">{{ currentStore?.address }}</span>
            </div>
            <div class="meta-row-two">
              <div class="meta-item">
                <span class="m-icon">📞</span>
                <span class="m-text">{{ currentStore?.phone }}</span>
                <span class="m-sub" v-if="currentStore?.managerName">({{ currentStore.managerName }})</span>
              </div>
              <div class="meta-item">
                <span class="m-icon">🕒</span>
                <span class="m-text">{{ currentStore?.openTime }}</span>
              </div>
            </div>
            <div class="meta-item slogan-item" v-if="currentStore?.slogan">
              <span class="m-icon">📢</span>
              <span class="m-text">{{ currentStore?.slogan }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 顶部独立页面标题栏 -->
      <div class="portal-header-bar">
        <div class="ph-title-wrap">
          <span class="ph-icon">💼</span>
          <span class="ph-title">员工自助入职申请与开号</span>
        </div>
        <div class="ph-subtitle">认领所属部门与岗位 · 快速开通系统工号 · 门店数字化协同</div>
      </div>

      <div class="form-container">
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
              <span class="sac-val"><strong>{{ createdStaff?.realName }}</strong> ({{ createdStaff?.gender === 'MALE' ? '男' : '女' }})</span>
            </div>
            <div class="sac-row">
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
              前往系统登录页 👉
            </el-button>
            <el-button size="default" style="margin-top: 10px;" @click="resetStaffForm">
              继续为其他员工登记入职
            </el-button>
          </div>
        </div>

        <!-- 填写员工入职表单 -->
        <div v-else>
          <!-- 面试通过候选人专属欢迎提示横幅 -->
          <div v-if="isCandidateOnboarding" class="candidate-onboarding-banner">
            <div class="cob-top">
              <span class="cob-badge">🏆 面试通过 · 诚邀入职</span>
              <span class="cob-tag">专属建档通道</span>
            </div>
            <div class="cob-title">恭喜您，{{ staffForm.realName || '优秀人才' }}！您已通过【{{ currentStore?.storeName }}】面试考评</div>
            <div class="cob-desc">
              经店长与考官综合考评决议，诚邀您入职我店拟任<strong>【{{ staffForm.department }} · {{ currentSelectedPost?.postName }}】</strong>。系统已自动为您绑定专属岗位，请核验下方个人档案并设置您的独立系统登录密码，提交后工号即刻激活生效！
            </div>
          </div>

          <div class="mode-tip-banner staff-tip-banner">
            <span class="t-icon">🛡️</span>
            <div class="t-text">
              <strong>【{{ currentStore?.storeName }}】员工入职申报通道：</strong>所选部门与在招岗位均源自本店真实架构体系，提交后店长一键复核即可激活工号！
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
                type="password"
                placeholder="设置6位以上密码"
                prefix-icon="Lock"
                show-password
              />
            </el-form-item>

            <!-- 部门与岗位联动选择 (严格对接当前门店具体部门架构与在招岗位) -->
            <el-row :gutter="12">
              <el-col :span="12">
                <el-form-item label="选择拟入职/所属部门" required>
                  <el-select
                    v-model="staffForm.department"
                    placeholder="选择当前门店部门"
                    style="width: 100%;"
                    :loading="loadingStoreDetail"
                    @change="handleDepartmentChange"
                  >
                    <el-option
                      v-for="dept in storeDepartments"
                      :key="dept"
                      :label="dept"
                      :value="dept"
                    />
                    <template #empty>
                      <div style="padding: 14px; text-align: center; color: #94a3b8; font-size: 13px;">
                        当前门店暂未设立部门架构，请联系店长在后台配置
                      </div>
                    </template>
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="选择应聘/拟任岗位" required>
                  <el-select
                    v-model="staffForm.selectedPostId"
                    placeholder="选择当前门店在招岗位"
                    style="width: 100%;"
                    :loading="loadingStoreDetail"
                    @change="handlePositionChange"
                  >
                    <el-option
                      v-for="p in allStorePositions"
                      :key="p.id || p.postName"
                      :label="p.postName"
                      :value="p.id || p.postName"
                    >
                      <div style="display: flex; justify-content: space-between; align-items: center; width: 100%;">
                        <div style="display: flex; align-items: center;">
                          <span style="font-weight: 500;">{{ p.postName }}</span>
                          <el-tag size="small" type="info" effect="plain" style="margin-left: 8px; font-size: 11px;">{{ p.department }}</el-tag>
                        </div>
                        <span style="color: #059669; font-size: 11px; margin-left: 8px;">{{ p.salaryRange || ('底薪￥' + (p.baseSalary || 4500)) }}</span>
                      </div>
                    </el-option>
                    <template #empty>
                      <div style="padding: 14px; text-align: center; color: #94a3b8; font-size: 13px;">
                        当前门店暂未发布在招岗位，请联系店长在后台配置
                      </div>
                    </template>
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>

            <!-- 岗位画像与系统预设权限说明卡片 -->
            <div v-if="currentSelectedPost" class="selected-post-card">
              <div class="post-card-header">
                <div class="post-title-group">
                  <span class="post-title">{{ currentSelectedPost.postName }}</span>
                  <el-tag size="small" type="info" effect="plain">{{ currentSelectedPost.department }}</el-tag>
                  <el-tag size="small" :type="currentSelectedPost.isRecruiting ? 'success' : 'warning'" effect="light">
                    {{ currentSelectedPost.isRecruiting ? '🔥 本店热招中' : '标准定编岗位' }}
                  </el-tag>
                </div>
                <div class="post-salary">{{ currentSelectedPost.salaryRange || ('底薪 ￥' + (currentSelectedPost.baseSalary || 4500) + '元/月') }}</div>
              </div>
              <div class="post-card-desc" v-if="currentSelectedPost.description">
                <span class="desc-lbl">岗位职责：</span>{{ currentSelectedPost.description }}
              </div>
              <div class="post-card-req" v-if="currentSelectedPost.requirements">
                <span class="desc-lbl">岗位要求：</span>{{ currentSelectedPost.requirements }}
              </div>
              <div class="post-card-perm">
                <span class="p-perm-icon">🔑</span>
                <span><strong>系统权限预设：</strong>{{ getPostPermissionDesc(currentSelectedPost) }}</span>
              </div>
            </div>

            <!-- 执业门店 (展示当前店铺名称) -->
            <el-form-item label="执业门店" required>
              <div class="fixed-store-box">
                <div class="fsb-content">
                  <span class="fsb-icon">📍</span>
                  <span class="fsb-title">{{ currentStore?.storeName || '海马智慧门店' }}</span>
                  <el-tag size="small" type="success" effect="plain">当前申请门店</el-tag>
                  <el-tag v-if="currentStore?.isHeadquarter" size="small" type="danger" effect="plain">旗舰总店</el-tag>
                </div>
              </div>
            </el-form-item>

            <el-form-item label="特长与过往从业经验 (简述)">
              <el-input
                v-model="staffForm.experience"
                type="textarea"
                rows="2"
                placeholder="例如：5年美业设计资深经验，擅长潮流烫染与会员客情维护..."
              />
            </el-form-item>

            <div class="agreement-box">
              <el-checkbox v-model="staffForm.agree">本人确认填报信息真实有效，自愿加入【{{ currentStore?.storeName }}】数字化协同体系</el-checkbox>
            </div>

            <el-button
              type="success"
              size="large"
              :loading="submittingStaff"
              class="w-full submit-btn staff-submit-btn"
              @click="handleSubmitStaff"
            >
              提交入职申请并生成工号
            </el-button>
          </el-form>
        </div>
      </div>

      <!-- 底部操作入口与返回 -->
      <div class="portal-footer">
        <el-button link type="info" size="small" @click="$router.push('/login')">
          已有账号？返回登录工作台 👉
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
import { resolveApiUrl } from '../utils/systemConfig'
import { ElMessage } from 'element-plus'

// 员工自助入职申请 API (后端持久化接口，无需登录 JWT)
const selfRegisterStaffApi = async (data: any) => {
  const res = await fetch(resolveApiUrl('/api/merchant/staff/self-register'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  return res.json()
}

const route = useRoute()
const router = useRouter()
const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()

const targetStoreId = ref<string>('S001')
const remoteStoreDetail = ref<any>(null)
const loadingStoreDetail = ref(true)
const isCandidateOnboarding = ref(false)

// 获取当前门店的真实具体信息 (优先读取远程公共档案，避免跨租户/未登录时出现美业S001兜底)
const currentStore = computed(() => {
  if (remoteStoreDetail.value) {
    return {
      storeId: remoteStoreDetail.value.storeId || targetStoreId.value,
      storeName: remoteStoreDetail.value.storeName || '海马智慧门店',
      address: remoteStoreDetail.value.address || '门店现场',
      phone: remoteStoreDetail.value.phone || '',
      openTime: remoteStoreDetail.value.businessHours || '09:00 - 22:00',
      slogan: '以客为尊，品质服务每一天',
      managerName: remoteStoreDetail.value.managerName || '门店店长',
      isHeadquarter: remoteStoreDetail.value.isHeadquarter || false,
      industry: remoteStoreDetail.value.industry || 'BEAUTY'
    }
  }

  const store = systemData.stores.find(s => s.storeId === targetStoreId.value) ||
                (systemData.stores.length > 0 ? systemData.stores[0] : null)

  let basicSettings: any = null
  try {
    const raw = localStorage.getItem('seahorse_basic_settings')
    if (raw) basicSettings = JSON.parse(raw)
  } catch (e) {}

  const isCurrentTenantStore = targetStoreId.value === storeConfig.currentStoreId || targetStoreId.value === 'S001'
  const sName = (isCurrentTenantStore && basicSettings?.storeName)
    ? basicSettings.storeName
    : (store?.storeName || (isCurrentTenantStore && storeConfig.storeName) || '海马智慧门店')

  const sAddress = (isCurrentTenantStore && basicSettings?.address)
    ? basicSettings.address
    : (store?.address || '门店现场')

  const sPhone = (isCurrentTenantStore && basicSettings?.phone)
    ? basicSettings.phone
    : (store?.phone || '')

  const sHours = (isCurrentTenantStore && basicSettings?.businessHours && Array.isArray(basicSettings.businessHours))
    ? `${basicSettings.businessHours[0]} - ${basicSettings.businessHours[1]}`
    : (store?.openTime || '09:00 - 22:00')

  const sSlogan = (isCurrentTenantStore && basicSettings?.slogan)
    ? basicSettings.slogan
    : '以客为尊，品质服务每一天'

  const manager = store?.managerName || '门店店长'
  const isHq = store ? store.isHeadquarter : (targetStoreId.value === 'S001')

  return {
    storeId: targetStoreId.value,
    storeName: sName,
    address: sAddress,
    phone: sPhone,
    openTime: sHours,
    slogan: sSlogan,
    managerName: manager,
    isHeadquarter: isHq,
    industry: store?.industry || remoteStoreDetail.value?.industry || storeConfig.industry || 'BEAUTY'
  }
})

// 可选门店列表（合并当前目标门店，保证多选框展示本店名称）
const availableStores = computed(() => {
  const list = [...systemData.stores]
  if (remoteStoreDetail.value && !list.some(s => s.storeId === remoteStoreDetail.value.storeId)) {
    list.unshift({
      storeId: remoteStoreDetail.value.storeId,
      storeName: remoteStoreDetail.value.storeName,
      address: remoteStoreDetail.value.address,
      phone: remoteStoreDetail.value.phone,
      isHeadquarter: remoteStoreDetail.value.isHeadquarter
    } as any)
  }
  return list
})

const getStoreNameById = (sId: string) => {
  if (remoteStoreDetail.value && remoteStoreDetail.value.storeId === sId) {
    return remoteStoreDetail.value.storeName
  }
  const s = systemData.stores.find(item => item.storeId === sId)
  return s ? s.storeName : sId
}

// ----------------------------------------------------------------------------
// 精准获取目标门店真实行业属性 (杜绝跨行业错乱)
// ----------------------------------------------------------------------------
const effectiveStoreIndustry = computed(() => {
  if (remoteStoreDetail.value?.industry) {
    return remoteStoreDetail.value.industry
  }
  const st = systemData.stores.find(s => s.storeId === targetStoreId.value)
  if (st?.industry) {
    return st.industry
  }
  if (storeConfig.industry) {
    return storeConfig.industry
  }
  return 'BEAUTY'
})

// 读取指定门店的本地独立配置岗位（严格隔离门店命名空间）
const getStoreConfiguredPositions = (sId: string) => {
  try {
    const rawScoped = localStorage.getItem(`seahorse_positions_${sId}`)
    if (rawScoped) {
      const arr = JSON.parse(rawScoped)
      if (Array.isArray(arr) && arr.length > 0) return arr
    }
    // 仅当当前浏览器登录的正是该门店时，才允许复用通用配置
    if (storeConfig.currentStoreId === sId) {
      const raw = localStorage.getItem('seahorse_system_positions')
      if (raw) {
        const arr = JSON.parse(raw)
        if (Array.isArray(arr) && arr.length > 0) {
          return arr.map((item: any, idx: number) => ({
            id: item.id || idx + 1,
            postName: item.postName,
            role: item.role || (item.postName?.includes('店长') ? 'STORE_MANAGER' : (item.postName?.includes('收银') || item.postName?.includes('前台') ? 'CASHIER' : 'TECHNICIAN')),
            department: item.department || '店务管理部',
            preset: item.preset || (item.postName?.includes('店长') ? 'MANAGER' : (item.postName?.includes('收银') ? 'CASHIER' : 'TECHNICIAN')),
            baseSalary: item.baseSalary || 5000,
            salaryRange: item.salaryRange || (item.baseSalary ? `￥${item.baseSalary}-${item.baseSalary + 3000}元/月` : '￥5000-8000元/月'),
            description: item.description || `负责本店${item.postName}相关日常工作与客户交付`,
            requirements: item.requirements || '具备相应业务经验与良好沟通服务意识',
            isRecruiting: item.isRecruiting !== false
          }))
        }
      }
    }
  } catch (e) {}
  return null
}

const getIndustryPresetPositions = (ind: string) => {
  if (ind === 'FOOT_SPA') {
    return [
      { id: 1, postName: '养生会所店长/主管', role: 'STORE_MANAGER', department: '店务管理部', preset: 'MANAGER', baseSalary: 7000, salaryRange: '￥7000-12000元/月', description: '统筹日常店务运营、房态调度、技师考勤与客户满意度', requirements: '养生会所管理经验', isRecruiting: true },
      { id: 2, postName: '资深足道养生技师', role: 'TECHNICIAN', department: '足道养生部', preset: 'TECHNICIAN', baseSalary: 6500, salaryRange: '￥6500-11000元/月', description: '负责顾客足底反射疗法、古法修脚与足部养护项目交付', requirements: '手法熟练，有足道经验', isRecruiting: true },
      { id: 3, postName: '首席SPA芳疗理疗师', role: 'TECHNICIAN', department: 'SPA理疗部', preset: 'TECHNICIAN', baseSalary: 6000, salaryRange: '￥6000-10000元/月', description: '负责全身精油SPA、淋巴排毒、肩颈舒缓与高端芳疗', requirements: '具备芳疗专业经验，手法温和', isRecruiting: true },
      { id: 4, postName: '中医经络推拿师', role: 'TECHNICIAN', department: '理疗推拿部', preset: 'TECHNICIAN', baseSalary: 5800, salaryRange: '￥5800-9500元/月', description: '负责经络穴位调理、背部拔罐刮痧与肌肉劳损松解', requirements: '持有中医推拿相关经验者优先', isRecruiting: true },
      { id: 5, postName: '前台接待主管', role: 'CASHIER', department: '前台客服部', preset: 'CASHIER', baseSalary: 4800, salaryRange: '￥4800-7000元/月', description: '负责到店迎宾领位、房态排钟分配、收银买单与会员储值', requirements: '形象端正，亲和力佳', isRecruiting: true }
    ]
  } else if (ind === 'AUTO') {
    return [
      { id: 1, postName: '汽修总监/店长', role: 'STORE_MANAGER', department: '店务管理部', preset: 'MANAGER', baseSalary: 8000, salaryRange: '￥8000-12000元/月', description: '全面统筹车间接车诊断与维修施工品控', requirements: '汽修管理经验', isRecruiting: true },
      { id: 2, postName: '资深机电快修技师', role: 'TECHNICIAN', department: '技术养护部', preset: 'TECHNICIAN', baseSalary: 6000, salaryRange: '￥6000-9000元/月', description: '负责车辆发动机、底盘及常规快修保养项目', requirements: '有汽车维修经验', isRecruiting: true },
      { id: 3, postName: '汽车美容养护技师', role: 'TECHNICIAN', department: '技术养护部', preset: 'TECHNICIAN', baseSalary: 5000, salaryRange: '￥5000-7500元/月', description: '负责精细洗车、镀晶打蜡与漆面修复', requirements: '爱护车辆，细致周到', isRecruiting: true },
      { id: 4, postName: '首席服务顾问(SA)', role: 'CASHIER', department: '前台客服部', preset: 'CASHIER', baseSalary: 5500, salaryRange: '￥5500-8500元/月', description: '负责进店车辆接车问询与结算开单', requirements: '沟通表达流畅', isRecruiting: true }
    ]
  } else if (ind === 'RETAIL') {
    return [
      { id: 1, postName: '运营总监/店长', role: 'STORE_MANAGER', department: '店务管理部', preset: 'MANAGER', baseSalary: 7500, salaryRange: '￥7500-11000元/月', description: '统筹门店销售业绩、商品陈列与人员督导', requirements: '零售管理经验', isRecruiting: true },
      { id: 2, postName: '资深导购/销售顾问', role: 'CASHIER', department: '门店服务部', preset: 'CASHIER', baseSalary: 4500, salaryRange: '￥4500-7000元/月', description: '负责客户导购选品、收银开单与会员纳新', requirements: '亲和力好', isRecruiting: true },
      { id: 3, postName: '仓储配货质检员', role: 'TECHNICIAN', department: '仓储配货部', preset: 'TECHNICIAN', baseSalary: 4800, salaryRange: '￥4800-6500元/月', description: '负责商品入库核验、条码打印与库存盘点', requirements: '细致严谨', isRecruiting: true },
      { id: 4, postName: '前台收银结算员', role: 'CASHIER', department: '前台收银部', preset: 'CASHIER', baseSalary: 4500, salaryRange: '￥4500-6000元/月', description: '负责商品扫码结算、开卡储值与对账交接', requirements: '细致认真', isRecruiting: true }
    ]
  } else if (ind === 'RESTAURANT') {
    return [
      { id: 1, postName: '餐厅店长/运营主管', role: 'STORE_MANAGER', department: '店务管理部', preset: 'MANAGER', baseSalary: 7000, salaryRange: '￥7000-11000元/月', description: '全面统筹日常运营、现场调度与月度经营核算', requirements: '有餐饮管理经验', isRecruiting: true },
      { id: 2, postName: '前厅领班/主管', role: 'CASHIER', department: '前厅服务部', preset: 'CASHIER', baseSalary: 5200, salaryRange: '￥5200-7500元/月', description: '负责前厅迎宾领位、翻台调度与客户满意度', requirements: '沟通亲和力强', isRecruiting: true },
      { id: 3, postName: '招牌烹饪/烧烤主厨', role: 'TECHNICIAN', department: '后厨烹饪部', preset: 'TECHNICIAN', baseSalary: 6800, salaryRange: '￥6800-9500元/月', description: '负责后厨菜品出品、烧烤火候掌控与菜品品控', requirements: '具备专业烹饪厨艺', isRecruiting: true },
      { id: 4, postName: '前台迎宾/收银员', role: 'CASHIER', department: '前台客服部', preset: 'CASHIER', baseSalary: 4500, salaryRange: '￥4500-6000元/月', description: '负责到店接待、系统收银开单与发票开具', requirements: '细致认真', isRecruiting: true },
      { id: 5, postName: '后厨切配/打荷员', role: 'TECHNICIAN', department: '后厨烹饪部', preset: 'TECHNICIAN', baseSalary: 4800, salaryRange: '￥4800-6500元/月', description: '负责食材初加工、串签备料与工位卫生', requirements: '吃苦耐劳', isRecruiting: true }
    ]
  } else if (ind === 'TEA_HOUSE') {
    return [
      { id: 1, postName: '茶楼掌柜/店长', role: 'STORE_MANAGER', department: '店务管理部', preset: 'MANAGER', baseSalary: 6500, salaryRange: '￥6500-10000元/月', description: '统筹茶室日常营运、茶礼接待与雅间环境调度', requirements: '茶室经营经验', isRecruiting: true },
      { id: 2, postName: '资深茶艺师/侍茶师', role: 'TECHNICIAN', department: '茶艺服务部', preset: 'TECHNICIAN', baseSalary: 5500, salaryRange: '￥5500-8500元/月', description: '负责名优茶冲泡品饮演示、茶道文化讲解与茶礼服务', requirements: '持有茶艺师资格或经验', isRecruiting: true },
      { id: 3, postName: '雅间管家/茶礼服务员', role: 'TECHNICIAN', department: '前厅接待部', preset: 'TECHNICIAN', baseSalary: 4800, salaryRange: '￥4800-7000元/月', description: '负责茶室雅座包厢布景备茶、续水与茶点呈递', requirements: '举止端庄，礼貌周到', isRecruiting: true },
      { id: 4, postName: '前台收银员', role: 'CASHIER', department: '前台客服部', preset: 'CASHIER', baseSalary: 4500, salaryRange: '￥4500-6000元/月', description: '负责到店接待、茶室消费开单与收银结算', requirements: '细致认真', isRecruiting: true }
    ]
  } else if (ind === 'PET') {
    return [
      { id: 1, postName: '宠物生活馆店长', role: 'STORE_MANAGER', department: '店务管理部', preset: 'MANAGER', baseSalary: 6500, salaryRange: '￥6500-10000元/月', description: '全面统筹门店日常经营、洗美工位排班与宠物安全品控', requirements: '具备宠物门店管理经验', isRecruiting: true },
      { id: 2, postName: '资深宠物美容造型师', role: 'TECHNICIAN', department: '宠物美容部', preset: 'TECHNICIAN', baseSalary: 6000, salaryRange: '￥6000-10000元/月', description: '负责爱宠洗护吹干、全身创意修剪与染色造型设计', requirements: '具备专业宠物美容经验', isRecruiting: true },
      { id: 3, postName: '宠物洗护精细技师', role: 'TECHNICIAN', department: '洗护服务部', preset: 'TECHNICIAN', baseSalary: 4800, salaryRange: '￥4800-7500元/月', description: '负责爱宠药浴浸泡、耳道清洁、挤肛门腺与基础护理', requirements: '喜爱小动物，耐心细致', isRecruiting: true },
      { id: 4, postName: '门店接待/收银主管', role: 'CASHIER', department: '前台客服部', preset: 'CASHIER', baseSalary: 4500, salaryRange: '￥4500-6500元/月', description: '负责接宠登记、健康情况问询、商品导购与收银结算', requirements: '亲和力强，喜爱宠物', isRecruiting: true }
    ]
  } else {
    // 默认 BEAUTY (品质美业/美容美发美甲)
    return [
      { id: 1, postName: '店长/运营主管', role: 'STORE_MANAGER', department: '店务管理部', preset: 'MANAGER', baseSalary: 6500, salaryRange: '￥6500-10000元/月', description: '全面统筹日常店务、顾客服务质检与人员考勤考核', requirements: '美业管理经验', isRecruiting: true },
      { id: 2, postName: '资深造型师/发型总监', role: 'TECHNICIAN', department: '美业设计部', preset: 'TECHNICIAN', baseSalary: 6000, salaryRange: '￥6000-12000元/月', description: '负责高端发型定制设计、潮流烫染交付与客户维系', requirements: '具备发型设计经验', isRecruiting: true },
      { id: 3, postName: '资深美业技师/设计师', role: 'TECHNICIAN', department: '美业设计部', preset: 'TECHNICIAN', baseSalary: 5000, salaryRange: '￥5000-9000元/月', description: '负责顾客剪发造型、专业洗护与方案推荐', requirements: '具备专业服务技巧', isRecruiting: true },
      { id: 4, postName: '头部养护/洗护技师', role: 'TECHNICIAN', department: '技术养护部', preset: 'TECHNICIAN', baseSalary: 4500, salaryRange: '￥4500-7000元/月', description: '负责专业头皮检测、草本精油熏蒸与舒缓洗发', requirements: '学习意愿强，服务意识好', isRecruiting: true },
      { id: 5, postName: '前台收银主管', role: 'CASHIER', department: '前台客服部', preset: 'CASHIER', baseSalary: 4500, salaryRange: '￥4500-6500元/月', description: '负责到店顾客接待、系统开卡收银与电话回访', requirements: '服务意识强', isRecruiting: true }
    ]
  }
}

const isDemoTenantEnv = computed(() => {
  const tId = remoteStoreDetail.value?.tenantId || storeConfig.tenantId || localStorage.getItem('seahorse_tenant_id') || ''
  return tId === 'T001' || tId === 'PLATFORM'
})

// ----------------------------------------------------------------------------
// 动态获取当前门店在招岗位 (严格以当前门店真实档案与云端架构为真理)
// ----------------------------------------------------------------------------
const allStorePositions = computed(() => {
  // 1. 核心真理来源：云端根据目标 storeId 返回的专属在招岗位架构
  if (remoteStoreDetail.value && Array.isArray(remoteStoreDetail.value.positions) && remoteStoreDetail.value.positions.length > 0) {
    return remoteStoreDetail.value.positions
  }

  // 2. 本地专属门店配置（若在同店管理后台操作并设置过该店专用岗位）
  const localPos = getStoreConfiguredPositions(targetStoreId.value)
  if (localPos && localPos.length > 0) {
    return localPos
  }

  // 3. 仅对系统内置演示租户(T001)兜底展示演示岗位；真实门店必须展示当前店铺实际配置，绝不展示未配置的假数据
  if (isDemoTenantEnv.value) {
    return getIndustryPresetPositions(effectiveStoreIndustry.value)
  }

  return []
})

// 读取当前门店部门架构 (严格依据当前店铺真实架构)
const storeDepartments = computed(() => {
  // 1. 优先读取云端门店接口返回的部门架构
  if (remoteStoreDetail.value && Array.isArray(remoteStoreDetail.value.departments) && remoteStoreDetail.value.departments.length > 0) {
    return remoteStoreDetail.value.departments
  }

  // 2. 本地专属门店配置（若在后台保存过该店部门）
  try {
    const rawDepts = localStorage.getItem(`seahorse_departments_${targetStoreId.value}`)
    if (rawDepts) {
      const arr = JSON.parse(rawDepts)
      if (Array.isArray(arr) && arr.length > 0) return arr
    }
    if (storeConfig.currentStoreId === targetStoreId.value) {
      const raw = localStorage.getItem('seahorse_store_departments')
      if (raw) {
        const arr = JSON.parse(raw)
        if (Array.isArray(arr) && arr.length > 0) return arr
      }
    }
  } catch (e) {}

  // 3. 从当前有效岗位中提取唯一所属部门列表
  if (allStorePositions.value && allStorePositions.value.length > 0) {
    const fromPosts = Array.from(new Set(allStorePositions.value.map(p => p.department).filter(Boolean)))
    if (fromPosts.length > 0) return fromPosts
  }

  // 4. 仅对系统内置演示租户(T001)兜底展示行业预设部门；真实门店未配置时返回空列表
  if (isDemoTenantEnv.value) {
    const ind = effectiveStoreIndustry.value
    if (ind === 'FOOT_SPA') {
      return ['店务管理部', '足道养生部', 'SPA理疗部', '理疗推拿部', '前台客服部']
    } else if (ind === 'AUTO') {
      return ['店务管理部', '技术养护部', '车间维修部', '前台客服部']
    } else if (ind === 'RETAIL') {
      return ['店务管理部', '门店服务部', '仓储配货部', '前台收银部']
    } else if (ind === 'RESTAURANT') {
      return ['店务管理部', '前厅服务部', '后厨烹饪部', '品质保障部', '前台客服部']
    } else if (ind === 'TEA_HOUSE') {
      return ['店务管理部', '茶艺服务部', '前厅接待部', '前台客服部']
    } else if (ind === 'PET') {
      return ['店务管理部', '宠物美容部', '洗护服务部', '前台客服部']
    } else {
      return ['店务管理部', '美业设计部', '前台客服部', '技术养护部', '门店服务部']
    }
  }

  return []
})

// 员工入职表单
const staffForm = ref({
  realName: '',
  gender: 'MALE' as 'MALE' | 'FEMALE',
  phone: '',
  accountPassword: '123456',
  department: '',
  selectedPostId: null as any,
  allowedStoreIds: [targetStoreId.value],
  experience: '',
  agree: true
})

// 根据所选部门动态过滤在招岗位 (用于辅助展示或部门先选场景)
const filteredPositionsByDept = computed(() => {
  if (!staffForm.value.department) {
    return allStorePositions.value
  }
  const list = allStorePositions.value.filter(p => p.department === staffForm.value.department)
  return list.length > 0 ? list : allStorePositions.value
})

// 当前选中的岗位对象
const currentSelectedPost = computed(() => {
  if (staffForm.value.selectedPostId) {
    const found = allStorePositions.value.find(p => (p.id || p.postName) === staffForm.value.selectedPostId || String(p.id) === String(staffForm.value.selectedPostId) || p.postName === staffForm.value.selectedPostId)
    if (found) return found
  }
  return allStorePositions.value[0] || null
})

// 部门切换联动：当手动选择部门时，若当前岗位不在该部门，自动切至该部门首个在招岗位
const handleDepartmentChange = (dept: string) => {
  const matchedPosts = allStorePositions.value.filter(p => p.department === dept)
  if (matchedPosts.length > 0) {
    const isCurrentInDept = matchedPosts.some(p => (p.id || p.postName) === staffForm.value.selectedPostId || String(p.id) === String(staffForm.value.selectedPostId) || p.postName === staffForm.value.selectedPostId)
    if (!isCurrentInDept) {
      staffForm.value.selectedPostId = matchedPosts[0].id || matchedPosts[0].postName
    }
  }
}

// 岗位切换联动：核心逻辑！当求职者选择岗位后，自动反向对齐填充所属部门！
const handlePositionChange = (posId: any) => {
  const found = allStorePositions.value.find(p => (p.id || p.postName) === posId || String(p.id) === String(posId) || p.postName === posId)
  if (found && found.department) {
    staffForm.value.department = found.department
  }
}

const getPostPermissionDesc = (post: any) => {
  if (!post) return '开通基础工作台'
  if (post.role === 'STORE_MANAGER' || post.preset === 'MANAGER') {
    return '开通店长管理席位（房态监控、排班考勤、收银报表、商品耗材及员工审核权）'
  } else if (post.role === 'CASHIER' || post.preset === 'CASHIER') {
    return '开通前台收银专席（前台接单、收银结账、会员开卡储值、预约调度）'
  } else {
    return '开通专业服务/技师工作台（个人履约接单、工单交付、耗材领用、提成明细核对）'
  }
}

const safeDecode = (val: unknown): string => {
  const str = String(val ?? '')
  try {
    return decodeURIComponent(str)
  } catch {
    return str
  }
}

// 异步拉取门店云端真实档案与部门在招岗位
const fetchStoreDetail = async (storeId: string) => {
  try {
    const res = await fetch(resolveApiUrl(`/api/space/public/store-detail?storeId=${encodeURIComponent(storeId)}`))
    if (res.ok) {
      const data = await res.json()
      if (data && data.code === 200 && data.data) {
        remoteStoreDetail.value = data.data
        // 自动对齐部门与在招岗位
        if (Array.isArray(data.data.positions) && data.data.positions.length > 0) {
          const targetPost = route.query.post ? safeDecode(route.query.post) : ''
          const matched = targetPost ? data.data.positions.find((p: any) => p.postName === targetPost) : null
          // 优先挑选指定岗位；未指定时优先推荐一线专业技术/服务岗位（避免直接锁定店长）
          const chosen = matched || data.data.positions.find((p: any) => p.role === 'TECHNICIAN' || !p.postName.includes('店长')) || data.data.positions[0]
          staffForm.value.selectedPostId = chosen.id || chosen.postName
          staffForm.value.department = chosen.department || data.data.departments?.[0] || ''
        } else if (Array.isArray(data.data.departments) && data.data.departments.length > 0) {
          staffForm.value.department = data.data.departments[0]
        }
      }
    }
  } catch (err) {
    console.warn('获取目标门店云端组织架构失败:', err)
  }
}

// 严格对齐当前表单部门与岗位归属
const alignFormDepartmentAndPosition = () => {
  const depts = storeDepartments.value
  const posts = allStorePositions.value
  if (posts.length === 0) {
    if (depts.length > 0 && !staffForm.value.department) {
      staffForm.value.department = depts[0]
    }
    return
  }

  // 若当前未选择岗位，或选择的岗位不属于当前门店，自动选取一个合理岗位
  const validPost = posts.find(p => (p.id || p.postName) === staffForm.value.selectedPostId || String(p.id) === String(staffForm.value.selectedPostId) || p.postName === staffForm.value.selectedPostId)
  if (validPost) {
    staffForm.value.department = validPost.department || staffForm.value.department || depts[0] || ''
  } else {
    // 优先选一线技师或服务岗位
    const defaultPost = posts.find(p => p.role === 'TECHNICIAN' || !p.postName.includes('店长')) || posts[0]
    staffForm.value.selectedPostId = defaultPost.id || defaultPost.postName
    staffForm.value.department = defaultPost.department || depts[0] || ''
  }
}

onMounted(async () => {
  loadingStoreDetail.value = true
  const qStoreId = route.query.storeId ? String(route.query.storeId).trim() : ''
  if (qStoreId && qStoreId !== 'undefined' && qStoreId !== 'null') {
    targetStoreId.value = qStoreId
  } else {
    targetStoreId.value = storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || 'S001'
  }
  staffForm.value.allowedStoreIds = [targetStoreId.value]

  // 处理候选人专属邀请入职参数
  if (route.query.realName || route.query.phone || route.query.candidateId) {
    isCandidateOnboarding.value = true
    if (route.query.realName) {
      staffForm.value.realName = safeDecode(route.query.realName)
    }
    if (route.query.phone) {
      staffForm.value.phone = String(route.query.phone)
    }
  }

  // 异步获取远程目标门店信息与组织架构岗位 (首要真理)
  await fetchStoreDetail(targetStoreId.value)

  // 再次校准保证选中的岗位与部门真实属于本店配置
  alignFormDepartmentAndPosition()
  loadingStoreDetail.value = false
})

// 提交审核与开号
const staffSuccess = ref(false)
const submittingStaff = ref(false)
const createdStaff = ref<any>(null)

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
  if (!staffForm.value.department) {
    ElMessage.warning('请选择拟入职部门')
    return
  }
  if (!staffForm.value.selectedPostId) {
    ElMessage.warning('请选择拟入职岗位')
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
    const pos = currentSelectedPost.value
    let menuPaths = ['/dashboard', '/members', '/products', '/appointments', '/inventory', '/profile']
    if (pos?.preset === 'CASHIER' || pos?.role === 'CASHIER') {
      menuPaths = ['/dashboard', '/members', '/products', '/card-template', '/appointments', '/expenses', '/inventory', '/profile']
    } else if (pos?.preset === 'MANAGER' || pos?.role === 'STORE_MANAGER') {
      menuPaths = allSystemMenus.filter(m => m.path !== '/settings').map(m => m.path)
    }

    // === 关键：向后端云端发起持久化入职申请（公开通道，不需要 JWT 登录）===
    let serverStaff: any = null
    try {
      const serverRes = await selfRegisterStaffApi({
        tenantId: storeConfig.tenantId || remoteStoreDetail.value?.tenantId || '',
        storeId: targetStoreId.value,
        realName: staffForm.value.realName.trim(),
        phone: staffForm.value.phone.trim(),
        accountPassword: staffForm.value.accountPassword.trim(),
        department: staffForm.value.department || pos?.department || '',
        postName: pos?.postName || '',
        gender: staffForm.value.gender,
        experience: staffForm.value.experience?.trim() || '',
        baseSalary: pos?.baseSalary || 4500,
        role: pos?.role || 'TECHNICIAN'
      })
      if (serverRes?.code === 200 || serverRes?.data) {
        serverStaff = serverRes.data || serverRes
      }
    } catch (e) {
      console.warn('云端自主入职申请提交失败，已保存至本地', e)
    }

    const newStaff = systemData.addStaff({
      storeId: targetStoreId.value,
      realName: staffForm.value.realName.trim(),
      phone: staffForm.value.phone.trim(),
      postName: pos?.postName || '',
      role: (pos?.role as any) || 'TECHNICIAN',
      department: staffForm.value.department || pos?.department || '',
      gender: staffForm.value.gender,
      baseSalary: pos?.baseSalary || 4500,
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

    // 同时向 seahorse_job_applications 写入一份申请简历，保障系统设置人才库与员工管理审核库双向联动
    try {
      const rawApps = localStorage.getItem('seahorse_job_applications')
      const appList = rawApps ? JSON.parse(rawApps) : []
      const nowStr = new Date().toISOString().replace('T', ' ').substring(0, 19)
      appList.unshift({
        id: 'APP' + Date.now().toString().slice(-8),
        postId: pos?.id || 1,
        postName: pos?.postName || '造型技师',
        department: staffForm.value.department || pos?.department || '门店服务部',
        candidateName: staffForm.value.realName.trim(),
        gender: staffForm.value.gender === 'MALE' ? '男' : '女',
        phone: staffForm.value.phone.trim(),
        storeId: targetStoreId.value,
        storeName: currentStore.value?.storeName || '',
        expectedSalary: pos?.salaryRange || ('底薪 ￥' + (pos?.baseSalary || 4500)),
        personalAdvantage: staffForm.value.experience?.trim() || '通过门店员工自助入职二维码填报',
        applyTime: nowStr,
        status: 'PENDING',
        isSelfApplied: true
      })
      localStorage.setItem('seahorse_job_applications', JSON.stringify(appList))
    } catch (e) {}

    // 若来自候选人入职链接，同步更新招聘人才库中的候选人状态为已自主建档入职
    if (route.query.candidateId) {
      const cId = String(route.query.candidateId)
      try {
        const tenantId = encodeURIComponent(storeConfig.tenantId || remoteStoreDetail.value?.tenantId || 'DEFAULT')
        fetch(resolveApiUrl(`/api/job-application/${cId}/status?tenantId=${tenantId}`), {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            status: 'HIRED',
            rejectReason: '已通过扫码自主完成员工个人档案填报与系统工号开通'
          })
        }).catch(() => {})
      } catch (e) {}
    }

    createdStaff.value = serverStaff || newStaff
    staffSuccess.value = true
    ElMessage.success(`入职申请已提交至云端！请等待店长或租户老板审核通过后方可登录。`)
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
.staff-register-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 50%, #e2e8f0 100%);
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding: 32px 16px;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

.staff-register-card {
  width: 100%;
  max-width: 560px;
  background: #ffffff;
  border-radius: 20px;
  box-shadow: 0 20px 40px -15px rgba(15, 23, 42, 0.12);
  overflow: hidden;
  border: 1px solid #e2e8f0;
}

.store-banner {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
  color: #ffffff;
  padding: 22px 24px;
  display: flex;
  align-items: flex-start;
  gap: 16px;
  border-bottom: 3px solid #0284c7;
}

.store-logo-wrap {
  flex-shrink: 0;
}

.store-logo {
  font-size: 34px;
  width: 56px;
  height: 56px;
  background: rgba(255, 255, 255, 0.12);
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.15);
}

.store-info {
  flex: 1;
}

.store-name-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}

.store-name {
  font-size: 19px;
  font-weight: 800;
  letter-spacing: 0.5px;
  color: #ffffff;
}

.store-meta-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  color: #cbd5e1;
  line-height: 1.4;
}

.meta-row-two {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}

.m-icon {
  font-size: 13px;
  flex-shrink: 0;
}

.m-sub {
  color: #94a3b8;
  font-size: 11.5px;
}

.slogan-item {
  margin-top: 2px;
  font-size: 11.5px;
  color: #38bdf8;
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

.staff-tip-banner {
  background: #f0fdf4;
  border-color: #bbf7d0;
}

.staff-tip-banner .t-text {
  color: #166534;
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

/* 岗位详情画像展示卡片 */
.selected-post-card {
  margin-top: -6px;
  margin-bottom: 18px;
  padding: 12px 14px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 12.5px;
  line-height: 1.5;
}

.post-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
  padding-bottom: 6px;
  border-bottom: 1px dashed #e2e8f0;
}

.post-title-group {
  display: flex;
  align-items: center;
  gap: 6px;
}

.post-title {
  font-weight: 700;
  color: #0f172a;
  font-size: 14px;
}

.post-salary {
  font-weight: 700;
  color: #059669;
  font-size: 13px;
}

.post-card-desc,
.post-card-req {
  color: #475569;
  margin-bottom: 4px;
}

.desc-lbl {
  font-weight: 600;
  color: #334155;
}

.post-card-perm {
  margin-top: 6px;
  padding: 6px 10px;
  background: #eff6ff;
  border-radius: 6px;
  color: #1e40af;
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11.5px;
}

.p-perm-icon {
  font-size: 13px;
}

.store-check-inline {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.primary-store-check :deep(.el-checkbox__label) {
  font-weight: 700;
  color: #0369a1;
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
}

.staff-submit-btn {
  background: linear-gradient(135deg, #059669 0%, #047857 100%);
  border: none;
  box-shadow: 0 4px 14px rgba(5, 150, 105, 0.35);
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
  margin-bottom: 20px;
  line-height: 1.5;
}

.staff-account-card {
  border-radius: 12px;
  padding: 16px;
  text-align: left;
  margin-bottom: 16px;
}

.sac-row {
  display: flex;
  margin-bottom: 8px;
  font-size: 13px;
  line-height: 1.5;
}

.sac-row:last-child {
  margin-bottom: 0;
}

.sac-lbl {
  width: 85px;
  color: #64748b;
  flex-shrink: 0;
}

.sac-val {
  flex: 1;
  color: #1e293b;
}

.text-primary {
  color: #0284c7;
}

.text-muted {
  color: #64748b;
}

.candidate-onboarding-banner {
  background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
  border: 1.5px solid #f59e0b;
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 18px;
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.15);
}

.cob-top {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.cob-badge {
  font-size: 13px;
  font-weight: bold;
  color: #92400e;
}

.cob-tag {
  background: #d97706;
  color: #ffffff;
  font-size: 10px;
  padding: 1px 6px;
  border-radius: 4px;
}

.cob-title {
  font-size: 15px;
  font-weight: 700;
  color: #78350f;
  margin-bottom: 6px;
}

.cob-desc {
  font-size: 12.5px;
  color: #92400e;
  line-height: 1.6;
}

.portal-footer {
  padding: 16px 24px;
  background: #f8fafc;
  border-top: 1px solid #f1f5f9;
  text-align: center;
  font-size: 12px;
  color: #94a3b8;
}

.fixed-store-box {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  width: 100%;
}

.fsb-content {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.fsb-title {
  font-size: 14.5px;
  font-weight: 700;
  color: #1e293b;
}

.fsb-tips {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11.5px;
  color: #64748b;
}

.lock-badge {
  color: #d97706;
  font-weight: 600;
}
</style>
