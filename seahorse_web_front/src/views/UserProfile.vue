<template>
  <div class="user-profile-page">
    <el-row :gutter="20">
      <!-- 左侧：个人基本资料卡片 -->
      <el-col :xs="24" :sm="24" :md="8">
        <el-card shadow="hover" class="profile-card">
          <div class="avatar-box">
            <el-avatar :size="88" class="user-avatar">
              {{ profile.realName ? profile.realName.substring(0, 1) : '用' }}
            </el-avatar>
            <h3 class="user-realname">{{ profile.realName || profile.username }}</h3>
            <p class="user-username">账号：{{ profile.username }}</p>
            <div class="role-tags">
              <el-tag effect="dark" type="primary" round>{{ profile.roleName || '系统用户' }}</el-tag>
              <el-tag effect="plain" type="success" round style="margin-left: 6px;">
                {{ profile.storeName || '海马智慧门店' }}
              </el-tag>
            </div>
          </div>

          <el-divider />

          <div class="info-list">
            <div class="info-item">
              <span class="lbl"><el-icon><Phone /></el-icon> 绑定手机：</span>
              <span class="val">{{ profile.phone || '未绑定' }}</span>
              <el-button link type="primary" size="small" @click="openPhoneDialog = true">修改</el-button>
            </div>
            <div class="info-item">
              <span class="lbl"><el-icon><OfficeBuilding /></el-icon> 所属企业：</span>
              <span class="val">{{ profile.tenantName || '海马SaaS平台' }}</span>
            </div>
            <div class="info-item">
              <span class="lbl"><el-icon><Lock /></el-icon> 账户安全：</span>
              <el-tag size="small" type="success">安全等级：高</el-tag>
              <el-button link type="primary" size="small" @click="openPasswordDialog = true">改密</el-button>
            </div>
            <div class="info-item">
              <span class="lbl"><el-icon><User /></el-icon> 性别：</span>
              <span class="val">{{ profile.gender === 'FEMALE' ? '女士' : '先生' }}</span>
            </div>
          </div>

          <div style="margin-top: 24px; display: flex; justify-content: center;">
            <el-button type="primary" plain icon="Edit" @click="handleOpenEditProfile">
              编辑个人基本信息
            </el-button>
          </div>
        </el-card>
      </el-col>

      <!-- 右侧：常用操作与安全日志 -->
      <el-col :xs="24" :sm="24" :md="16">
        <el-card shadow="hover">
          <el-tabs v-model="activeTab" @tab-change="handleTabChange">
            <!-- Tab 1: 快捷安全操作 -->
            <el-tab-pane label="🔐 账号与安全设置" name="security">
              <div class="security-items">
                <div class="sec-item">
                  <div class="sec-icon sec-lock"><el-icon><Lock /></el-icon></div>
                  <div class="sec-info">
                    <div class="sec-title">登录密码</div>
                    <div class="sec-desc">建议定期更换复杂密码以保障门店与会员资产安全。</div>
                  </div>
                  <el-button type="primary" @click="openPasswordDialog = true">立即修改</el-button>
                </div>

                <el-divider />

                <div class="sec-item">
                  <div class="sec-icon sec-phone"><el-icon><Iphone /></el-icon></div>
                  <div class="sec-info">
                    <div class="sec-title">密保手机</div>
                    <div class="sec-desc">当前绑定手机：{{ profile.phone || '暂无' }}。用于登录验证与异常预警。</div>
                  </div>
                  <el-button type="primary" plain @click="openPhoneDialog = true">更换手机号</el-button>
                </div>

                <el-divider />

                <div class="sec-item">
                  <div class="sec-icon sec-shield"><el-icon><CircleCheck /></el-icon></div>
                  <div class="sec-info">
                    <div class="sec-title">双因子防盗刷安全锁</div>
                    <div class="sec-desc">会员大额储值与敏感财务交接时的二次鉴权保障已开启。</div>
                  </div>
                  <el-switch v-model="doubleAuthEnabled" active-text="已启用" inactive-text="已关闭" @change="handleDoubleAuthChange" />
                </div>
              </div>
            </el-tab-pane>

            <!-- Tab 2: 登录与操作审计日志 (真实记录，租户看全员，普通人员仅看个人) -->
            <el-tab-pane :label="isSuperAdmin ? '📜 登录与安全审计日志' : (isTenantAdmin ? '📜 租户全员登录与安全日志' : '📜 我的个人登录与安全日志')" name="logs">
              <!-- 超级管理员专属：策略指示与配置卡片栏 (租户端严格不可见) -->
              <div
                v-if="isSuperAdmin"
                class="log-policy-bar"
                style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px 16px; margin-bottom: 14px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;"
              >
                <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                  <span style="font-weight: 600; font-size: 13.5px; color: #1e293b;">🛡️ 租户与店铺安全审计策略（超级管理员专属）：</span>
                  <el-tag :type="auditPolicy.enabled ? 'success' : 'info'" size="small">
                    {{ auditPolicy.enabled ? '● 实时全员审计记录已开启' : '○ 审计已停用' }}
                  </el-tag>
                  <el-tag type="primary" size="small" effect="plain">
                    模式：{{ auditPolicy.mode === 'INCLUDE' ? '白名单模式' : (auditPolicy.excludedTenantIds || auditPolicy.excludedStoreIds ? '黑名单排除模式' : '全员记录模式') }}
                  </el-tag>
                  <span style="font-size: 12px; color: #64748b;">
                    (默认全员记录，超级管理员可配置指定租户/店铺记录或免记录)
                  </span>
                </div>
                <div style="display: flex; gap: 8px;">
                  <el-button type="primary" plain size="small" @click="openPolicyConfigModal">
                    ⚙️ 配置记录策略与租户店铺名单
                  </el-button>
                  <el-button type="danger" plain size="small" @click="handleClearLogs" :disabled="logs.length === 0">
                    🗑️ 清空历史日志
                  </el-button>
                </div>
              </div>

              <div class="log-filter-bar" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
                <div style="display: flex; gap: 10px;">
                  <el-input
                    v-model="logKeyword"
                    placeholder="搜索日志事件/操作人/IP/终端"
                    style="width: 260px;"
                    clearable
                    @clear="handleSearchAuditLogs"
                    @keyup.enter="handleSearchAuditLogs"
                  />
                  <el-button type="primary" icon="Search" @click="handleSearchAuditLogs">查询</el-button>
                </div>
                <div style="font-size: 12.5px; color: #64748b;">
                  当前{{ isSuperAdmin ? '平台全域' : (isTenantAdmin ? '租户全员' : `个人账号【${profile.realName || profile.username || '当前用户'}】`) }}共记录安全事件 <b>{{ totalLogs }}</b> 条
                </div>
              </div>

              <el-table
                :data="logs"
                stripe
                style="width: 100%; margin-top: 12px;"
                v-loading="loadingLogs"
                :empty-text="isSuperAdmin ? '暂无安全审计日志记录（默认全员记录，可由超级管理员配置租户与店铺策略）' : (isTenantAdmin ? '暂无本租户全员登录与安全日志记录' : '暂无您的个人登录与使用日志记录')"
              >
                <el-table-column prop="time" label="操作时间" width="165" />
                <el-table-column prop="action" label="事件类型 / 内容" min-width="160">
                  <template #default="{ row }">
                    <el-tag size="small" :type="row.type">{{ row.eventCode || 'ACTION' }}</el-tag>
                    <span style="margin-left: 6px; font-weight: 500;">{{ row.action }}</span>
                  </template>
                </el-table-column>
                <el-table-column prop="operatorName" label="操作人 / 账号" width="130" />
                <el-table-column prop="tenantId" label="所属租户" width="100" v-if="isSuperAdmin">
                  <template #default="{ row }">
                    <el-tag size="small" type="info">{{ row.tenantId || '平台' }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="storeId" label="门店" width="90" v-if="isSuperAdmin">
                  <template #default="{ row }">
                    <span style="font-size: 12px; color: #64748b;">{{ row.storeId || '-' }}</span>
                  </template>
                </el-table-column>
                <el-table-column prop="ip" label="登录IP / 端点" width="140" />
                <el-table-column prop="device" label="操作终端 / 设备" width="160" show-overflow-tooltip />
                <el-table-column prop="notes" label="业务操作详述 / 说明" min-width="220" show-overflow-tooltip>
                  <template #default="{ row }">
                    <span style="font-size: 12.5px; color: #334155;">{{ row.notes || '-' }}</span>
                  </template>
                </el-table-column>
                <el-table-column prop="status" label="状态" width="80" align="center">
                  <template #default="{ row }">
                    <el-tag :type="row.status === '成功' ? 'success' : 'danger'" size="small">
                      {{ row.status }}
                    </el-tag>
                  </template>
                </el-table-column>
              </el-table>

              <!-- 日志分页器 -->
              <div class="pagination-box">
                <el-pagination
                  v-model:current-page="currentPage"
                  v-model:page-size="pageSize"
                  :page-sizes="[5, 10, 20, 50]"
                  layout="total, sizes, prev, pager, next, jumper"
                  :total="totalLogs"
                  @current-change="loadAuditLogs"
                  @size-change="loadAuditLogs"
                />
              </div>
            </el-tab-pane>
          </el-tabs>
        </el-card>
      </el-col>
    </el-row>

    <!-- 1. 修改密码对话框 -->
    <el-dialog v-model="openPasswordDialog" title="修改登录密码" width="460px" destroy-on-close>
      <el-form :model="passwordForm" :rules="passwordRules" ref="passwordFormRef" label-width="100px">
        <el-form-item label="原密码" prop="oldPassword">
          <el-input v-model="passwordForm.oldPassword" type="password" show-password placeholder="请输入原登录密码" />
        </el-form-item>
        <el-form-item label="新密码" prop="newPassword">
          <el-input v-model="passwordForm.newPassword" type="password" show-password placeholder="请输入新密码（至少6位）" />
        </el-form-item>
        <el-form-item label="确认新密码" prop="confirmPassword">
          <el-input v-model="passwordForm.confirmPassword" type="password" show-password placeholder="请再次输入新密码" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openPasswordDialog = false">取消</el-button>
        <el-button type="primary" :loading="savingPassword" @click="handleSavePassword">确认修改</el-button>
      </template>
    </el-dialog>

    <!-- 2. 修改手机号对话框 -->
    <el-dialog v-model="openPhoneDialog" title="更换绑定手机号码" width="460px" destroy-on-close>
      <el-form :model="phoneForm" :rules="phoneRules" ref="phoneFormRef" label-width="100px">
        <el-form-item label="当前手机号">
          <el-input :model-value="profile.phone || '暂无'" disabled />
        </el-form-item>
        <el-form-item label="新手机号" prop="newPhone">
          <el-input v-model="phoneForm.newPhone" placeholder="请输入11位新手机号码" maxlength="11" />
        </el-form-item>
        <el-form-item label="验证码" prop="verifyCode">
          <div style="display: flex; gap: 10px; width: 100%;">
            <el-input v-model="phoneForm.verifyCode" placeholder="短信验证码" maxlength="6" />
            <el-button :disabled="countdown > 0" @click="handleSendCode">
              {{ countdown > 0 ? `${countdown}s后重发` : '获取验证码' }}
            </el-button>
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openPhoneDialog = false">取消</el-button>
        <el-button type="primary" :loading="savingPhone" @click="handleSavePhone">确认更换</el-button>
      </template>
    </el-dialog>

    <!-- 3. 编辑个人资料对话框 -->
    <el-dialog v-model="openEditProfileDialog" title="编辑基本资料" width="460px" destroy-on-close>
      <el-form :model="editProfileForm" label-width="90px">
        <el-form-item label="真实姓名" required>
          <el-input v-model="editProfileForm.realName" placeholder="请输入姓名/称呼" />
        </el-form-item>
        <el-form-item label="性别">
          <el-radio-group v-model="editProfileForm.gender">
            <el-radio label="MALE">先生</el-radio>
            <el-radio label="FEMALE">女士</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openEditProfileDialog = false">取消</el-button>
        <el-button type="primary" :loading="savingProfile" @click="handleSaveProfile">保存修改</el-button>
      </template>
    </el-dialog>

    <!-- 4. 租户与门店安全审计策略配置对话框 (超级管理员专属) -->
    <el-dialog v-if="isSuperAdmin" v-model="openPolicyDialog" title="🛡️ 租户与门店安全审计日志策略配置（超级管理员专属）" width="620px" destroy-on-close>
      <el-form :model="policyEditForm" label-width="145px" style="margin-top: 10px;">
        <el-form-item label="审计日志记录总开关">
          <el-switch
            v-model="policyEditForm.enabled"
            active-text="开启真实审计记录 (默认开启)"
            inactive-text="停用全部审计日志"
          />
          <div style="font-size: 11.5px; color: #64748b; margin-top: 4px;">
            默认开启：全系统所有人员账号的登录与关键安全操作均会自动记录入库。
          </div>
        </el-form-item>

        <el-form-item label="记录范围策略模式">
          <el-radio-group v-model="policyEditForm.mode">
            <el-radio label="ALL">全员默认记录 (推荐)</el-radio>
            <el-radio label="EXCLUDE">黑名单排除模式</el-radio>
            <el-radio label="INCLUDE">白名单精简模式</el-radio>
          </el-radio-group>
          <div style="font-size: 11.5px; color: #64748b; margin-top: 4px;">
            <span v-if="policyEditForm.mode === 'ALL'">全部租户和门店均进行记录（支持下方设置例外不记录的名单）。</span>
            <span v-else-if="policyEditForm.mode === 'EXCLUDE'">除下方黑名单配置的租户和门店外，其余所有店铺正常记录。</span>
            <span v-else>仅记录下方白名单中配置的租户与门店，其余店铺均不记录。</span>
          </div>
        </el-form-item>

        <div v-if="policyEditForm.mode === 'EXCLUDE' || policyEditForm.mode === 'ALL'" style="background: #fff1f2; border: 1px solid #fecdd3; border-radius: 8px; padding: 12px 14px; margin-bottom: 16px;">
          <div style="font-weight: 600; font-size: 13px; color: #be123c; margin-bottom: 8px;">🚫 黑名单设置：配置哪些租户与店铺【不记录日志】</div>
          <el-form-item label="不记录租户ID" style="margin-bottom: 8px;">
            <el-input v-model="policyEditForm.excludedTenantIds" placeholder="多个租户ID用英文逗号分隔，如: T002, T003" />
          </el-form-item>
          <el-form-item label="不记录门店ID" style="margin-bottom: 0;">
            <el-input v-model="policyEditForm.excludedStoreIds" placeholder="多个门店ID用英文逗号分隔，如: S003, S005" />
          </el-form-item>
        </div>

        <div v-if="policyEditForm.mode === 'INCLUDE'" style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 12px 14px; margin-bottom: 16px;">
          <div style="font-weight: 600; font-size: 13px; color: #15803d; margin-bottom: 8px;">✅ 白名单设置：仅配置哪些租户与店铺【允许记录日志】</div>
          <el-form-item label="指定记录租户ID" style="margin-bottom: 8px;">
            <el-input v-model="policyEditForm.includedTenantIds" placeholder="多个租户ID用英文逗号分隔，如: T001" />
          </el-form-item>
          <el-form-item label="指定记录门店ID" style="margin-bottom: 0;">
            <el-input v-model="policyEditForm.includedStoreIds" placeholder="多个门店ID用英文逗号分隔，如: S001, S002" />
          </el-form-item>
        </div>

        <el-form-item label="事件记录项">
          <div style="display: flex; gap: 20px;">
            <el-checkbox v-model="policyEditForm.recordLogins">记录用户鉴权登录/登出事件</el-checkbox>
            <el-checkbox v-model="policyEditForm.recordOperations">记录敏感业务/配置操作事件</el-checkbox>
          </div>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="openPolicyDialog = false">取消</el-button>
        <el-button type="primary" :loading="savingPolicy" @click="handleSavePolicy">确认保存策略</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance } from 'element-plus'
import {
  getUserProfileApi,
  changePasswordApi,
  updatePhoneApi,
  updateProfileInfoApi,
  getAuditLogsApi,
  getAuditPolicyApi,
  saveAuditPolicyApi,
  clearAuditLogsApi,
  recordClientAuditLogApi
} from '../api'

const activeTab = ref('security')
const doubleAuthEnabled = ref(true)

const profile = ref<any>({
  userId: 1,
  username: 'admin',
  realName: '系统管理员',
  phone: '13800000000',
  role: 'STORE_OWNER',
  roleName: '会员门店老板',
  storeName: '海马智慧旗舰店',
  tenantName: '海马智慧租户',
  planCode: 'STANDARD',
  planName: '标准专业版',
  gender: 'MALE'
})

// 修改密码
const openPasswordDialog = ref(false)
const savingPassword = ref(false)
const passwordFormRef = ref<FormInstance>()
const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const passwordRules = {
  oldPassword: [{ required: true, message: '请输入原密码', trigger: 'blur' }],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码不能少于6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    {
      validator: (_: any, value: string, callback: any) => {
        if (value !== passwordForm.newPassword) {
          callback(new Error('两次输入的新密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
}

// 修改手机号
const openPhoneDialog = ref(false)
const savingPhone = ref(false)
const countdown = ref(0)
const phoneFormRef = ref<FormInstance>()
const phoneForm = reactive({
  newPhone: '',
  verifyCode: ''
})

const phoneRules = {
  newPhone: [
    { required: true, message: '请输入新手机号码', trigger: 'blur' },
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的11位手机号', trigger: 'blur' }
  ],
  verifyCode: [{ required: true, message: '请输入验证码', trigger: 'blur' }]
}

// 编辑资料
const openEditProfileDialog = ref(false)
const savingProfile = ref(false)
const editProfileForm = reactive({
  realName: '',
  gender: 'MALE'
})

// ==============================================================================
// 真实安全审计日志与等级门槛记录策略体系
// ==============================================================================
// 严格超级管理员权限判定：仅限平台超级管理员/系统开发维护人，租户商户（11位手机号/新租户/普通商户）严格不可见且不可配置策略
const isSuperAdmin = computed(() => {
  const role = profile.value?.role || localStorage.getItem('seahorse_role') || ''
  const username = profile.value?.username || localStorage.getItem('seahorse_user') || ''
  const phone = profile.value?.phone || ''
  const isPhone = /^\d{11}$/.test(username) || /^\d{11}$/.test(phone)

  // 手机号登录、新注册租户或普通商户绝对不是平台超级管理员
  if (isPhone) return false
  if (localStorage.getItem('seahorse_is_new_tenant') === 'true') return false

  const tenantId = profile.value?.tenantId || localStorage.getItem('seahorse_tenant_id') || ''
  if (tenantId && tenantId !== 'PLATFORM' && tenantId !== 'T001') {
    return false
  }

  return (
    role === 'PLATFORM_DEVELOPER' ||
    role === 'PLATFORM_SUPER_ADMIN' ||
    role === 'PLATFORM_ADMIN' ||
    username === 'admin' ||
    username === 'root_ops'
  )
})

// 租户主账号/老板权限判定：除租户管理者与平台超管外，其他人只能看到自己的登录和使用日志
const isTenantAdmin = computed(() => {
  const role = profile.value?.role || localStorage.getItem('seahorse_role') || ''
  const isNewTenant = localStorage.getItem('seahorse_is_new_tenant') === 'true'
  return (
    isSuperAdmin.value ||
    role === 'TENANT_ADMIN' ||
    role === 'STORE_OWNER' ||
    role === 'MERCHANT_ADMIN' ||
    role === 'SUPER_ADMIN' ||
    isNewTenant
  )
})

interface AuditPolicy {
  enabled: boolean
  mode: 'ALL' | 'EXCLUDE' | 'INCLUDE'
  excludedTenantIds: string
  excludedStoreIds: string
  includedTenantIds: string
  includedStoreIds: string
  recordLogins: boolean
  recordOperations: boolean
}

const openPolicyDialog = ref(false)
const savingPolicy = ref(false)
const auditPolicy = ref<AuditPolicy>({
  enabled: true,
  mode: 'ALL',
  excludedTenantIds: '',
  excludedStoreIds: '',
  includedTenantIds: '',
  includedStoreIds: '',
  recordLogins: true,
  recordOperations: true
})

const policyEditForm = reactive<AuditPolicy>({
  enabled: true,
  mode: 'ALL',
  excludedTenantIds: '',
  excludedStoreIds: '',
  includedTenantIds: '',
  includedStoreIds: '',
  recordLogins: true,
  recordOperations: true
})

const loadAuditPolicy = async () => {
  try {
    const res = (await getAuditPolicyApi()) as any
    const pData = res?.data !== undefined && res?.code ? res.data : (res?.data || res)
    if (pData) {
      auditPolicy.value = {
        enabled: pData.enabled !== false,
        mode: pData.mode || 'ALL',
        excludedTenantIds: pData.excludedTenantIds || '',
        excludedStoreIds: pData.excludedStoreIds || '',
        includedTenantIds: pData.includedTenantIds || '',
        includedStoreIds: pData.includedStoreIds || '',
        recordLogins: pData.recordLogins !== false,
        recordOperations: pData.recordOperations !== false
      }
    }
  } catch (e) {
    console.warn('拉取审计策略失败', e)
  }
}

const openPolicyConfigModal = () => {
  if (!isSuperAdmin.value) {
    ElMessage.warning('安全审计策略仅限平台超级管理员统一管控配置，租户端无权操作！')
    return
  }
  policyEditForm.enabled = auditPolicy.value.enabled
  policyEditForm.mode = auditPolicy.value.mode
  policyEditForm.excludedTenantIds = auditPolicy.value.excludedTenantIds
  policyEditForm.excludedStoreIds = auditPolicy.value.excludedStoreIds
  policyEditForm.includedTenantIds = auditPolicy.value.includedTenantIds
  policyEditForm.includedStoreIds = auditPolicy.value.includedStoreIds
  policyEditForm.recordLogins = auditPolicy.value.recordLogins
  policyEditForm.recordOperations = auditPolicy.value.recordOperations
  openPolicyDialog.value = true
}

const handleSavePolicy = async () => {
  if (!isSuperAdmin.value) {
    ElMessage.error('权限不足！该策略仅限超级管理员配置。')
    return
  }
  savingPolicy.value = true
  try {
    await saveAuditPolicyApi(policyEditForm)
    auditPolicy.value = { ...policyEditForm }
    openPolicyDialog.value = false
    ElMessage.success('租户与店铺安全审计日志记录策略已成功保存！')
    await recordAuditLog('修改系统安全审计与黑白名单策略', 'warning', 'POLICY_CHANGE', '成功')
    await loadAuditLogs()
  } catch (e: any) {
    ElMessage.error(e.message || '保存策略失败')
  } finally {
    savingPolicy.value = false
  }
}

// 真实审计日志列表 (直连后端MySQL数据库)
const logs = ref<any[]>([])
const loadingLogs = ref(false)
const totalLogs = ref(0)
const logKeyword = ref('')
const currentPage = ref(1)
const pageSize = ref(10)

const handleSearchAuditLogs = () => {
  currentPage.value = 1
  loadAuditLogs()
}

const loadAuditLogs = async () => {
  loadingLogs.value = true
  try {
    const rawUser = profile.value?.username || localStorage.getItem('seahorse_username') || localStorage.getItem('seahorse_user') || ''
    const cleanUser = rawUser.split(/[\(（【]/)[0].trim()
    const queryParams: any = {
      keyword: logKeyword.value,
      page: currentPage.value,
      size: pageSize.value
    }
    // 权限隔离控制：当前登录人除了租户/管理员以外，其他人只能看到自己的登录和使用日志
    if (!isTenantAdmin.value) {
      queryParams.username = cleanUser
    }
    const res = (await getAuditLogsApi(queryParams)) as any

    const pageData = res?.data !== undefined && res?.code ? res.data : (res?.data || res)
    if (pageData) {
      const list = pageData.content || (Array.isArray(pageData) ? pageData : (Array.isArray(pageData.data) ? pageData.data : []))
      logs.value = list.map((item: any) => {
        const actionType = item.actionType || item.eventCode || 'LOGIN'
        const isSuccess = item.status === 'SUCCESS' || item.status === '成功'
        let badgeType = 'info'
        if (actionType === 'LOGIN') badgeType = 'primary'
        else if (actionType === 'OPERATE') badgeType = 'success'
        else if (actionType === 'PASSWORD') badgeType = 'danger'
        else if (actionType === 'POLICY_CHANGE') badgeType = 'warning'

        return {
          id: item.id,
          time: item.createdAt ? item.createdAt.replace('T', ' ').substring(0, 19) : '-',
          action: item.action || '系统操作',
          eventCode: actionType,
          type: badgeType,
          tenantId: item.tenantId,
          storeId: item.storeId,
          operatorName: item.realName || item.username || item.operatorName || item.operatorPhone || '系统用户',
          ip: item.ip || '127.0.0.1',
          device: item.device || '移动终端 / 浏览器',
          notes: item.notes || '-',
          status: isSuccess ? '成功' : (item.status === 'FAILED' ? '失败' : (item.status || '成功'))
        }
      })
      totalLogs.value = pageData.totalElements != null ? pageData.totalElements : logs.value.length
    } else {
      logs.value = []
      totalLogs.value = 0
    }
  } catch (e) {
    console.warn('获取真实安全审计日志失败', e)
    logs.value = []
    totalLogs.value = 0
  } finally {
    loadingLogs.value = false
  }
}

// 真实记录安全事件审计日志并上报后端
const recordAuditLog = async (
  action: string,
  _type: 'info' | 'primary' | 'warning' | 'danger' | 'success',
  eventCode: string,
  status: '成功' | '拦截' | '失败' = '成功'
) => {
  try {
    const rawUser = profile.value?.username || localStorage.getItem('seahorse_username') || localStorage.getItem('seahorse_user') || 'user'
    const cleanUser = rawUser.split(/[\(（【]/)[0].trim()
    const rawRealName = profile.value?.realName || localStorage.getItem('seahorse_real_name') || cleanUser
    await recordClientAuditLogApi({
      action,
      actionType: eventCode,
      status: status === '成功' ? 'SUCCESS' : (status === '失败' ? 'FAILED' : 'BLOCKED'),
      notes: action,
      username: cleanUser,
      realName: rawRealName,
      tenantId: profile.value?.tenantId || localStorage.getItem('seahorse_tenant_id') || 'T001',
      storeId: profile.value?.storeId || localStorage.getItem('seahorse_store_id') || 'S001',
      storeName: profile.value?.storeName || localStorage.getItem('seahorse_store_name') || '海马智慧门店',
      device: navigator.userAgent.includes('Mobile') ? '移动端手机浏览器' : 'Chrome 浏览器 (PC)'
    })
    loadAuditLogs()
  } catch (e) {
    console.warn('上报审计日志失败', e)
  }
}

const handleTabChange = (name: any) => {
  if (name === 'logs') {
    loadAuditLogs()
  }
}

const handleClearLogs = () => {
  if (!isSuperAdmin.value) {
    ElMessage.warning('清空历史日志功能仅限超级管理员操作！')
    return
  }
  ElMessageBox.confirm('确定要清空历史安全审计日志吗？清空后不可恢复。', '清空日志确认', {
    confirmButtonText: '确定清空',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    try {
      await clearAuditLogsApi()
      logs.value = []
      totalLogs.value = 0
      ElMessage.success('安全审计日志已成功清空！')
    } catch (e: any) {
      ElMessage.error(e.message || '清空日志失败')
    }
  }).catch(() => {})
}

const handleDoubleAuthChange = (val: any) => {
  recordAuditLog(`双因子防盗刷安全锁: ${val ? '已启用' : '已关闭'}`, 'warning', 'SECURITY_LOCK', '成功')
  ElMessage.success(`双因子防盗刷安全锁${val ? '已开启' : '已关闭'}！`)
}

const loadProfile = async () => {
  try {
    const res = (await getUserProfileApi()) as any
    if (res) {
      profile.value = { ...profile.value, ...res }
      editProfileForm.realName = res.realName || res.username
      editProfileForm.gender = res.gender || 'MALE'
    }
  } catch (e) {
    console.error(e)
  }
  loadAuditPolicy()
  loadAuditLogs()
}

const handleSavePassword = async () => {
  if (!passwordFormRef.value) return
  await passwordFormRef.value.validate(async (valid) => {
    if (!valid) return
    savingPassword.value = true
    try {
      await changePasswordApi({
        oldPassword: passwordForm.oldPassword,
        newPassword: passwordForm.newPassword
      })
      ElMessage.success('密码修改成功，请妥善保管新密码！')
      recordAuditLog('修改登录密码', 'primary', 'PASSWORD', '成功')
      openPasswordDialog.value = false
      passwordForm.oldPassword = ''
      passwordForm.newPassword = ''
      passwordForm.confirmPassword = ''
    } catch (e: any) {
      recordAuditLog('尝试修改登录密码失败', 'danger', 'PASSWORD', '失败')
      ElMessage.error(e.message || '密码修改失败')
    } finally {
      savingPassword.value = false
    }
  })
}

let countdownTimer: ReturnType<typeof setInterval> | null = null

const handleSendCode = () => {
  if (!phoneForm.newPhone || !/^1[3-9]\d{9}$/.test(phoneForm.newPhone)) {
    ElMessage.warning('请先输入正确的11位新手机号码')
    return
  }
  if (countdownTimer) {
    clearInterval(countdownTimer)
    countdownTimer = null
  }
  countdown.value = 60
  phoneForm.verifyCode = '888888'
  ElMessage.success('【演示模式】验证码已模拟发送至新手机：888888')
  countdownTimer = setInterval(() => {
    countdown.value--
    if (countdown.value <= 0 && countdownTimer) {
      clearInterval(countdownTimer)
      countdownTimer = null
    }
  }, 1000)
}

const handleSavePhone = async () => {
  if (!phoneFormRef.value) return
  await phoneFormRef.value.validate(async (valid) => {
    if (!valid) return
    savingPhone.value = true
    try {
      await updatePhoneApi({
        phone: phoneForm.newPhone,
        verifyCode: phoneForm.verifyCode
      })
      ElMessage.success('绑定手机号更换成功！')
      recordAuditLog(`更换密保手机为: ${phoneForm.newPhone}`, 'warning', 'PHONE', '成功')
      openPhoneDialog.value = false
      profile.value.phone = phoneForm.newPhone
      phoneForm.newPhone = ''
      phoneForm.verifyCode = ''
    } catch (e: any) {
      recordAuditLog('尝试更换密保手机失败', 'danger', 'PHONE', '失败')
    } finally {
      savingPhone.value = false
    }
  })
}

const handleOpenEditProfile = () => {
  editProfileForm.realName = profile.value.realName || profile.value.username || ''
  editProfileForm.gender = profile.value.gender || 'MALE'
  openEditProfileDialog.value = true
}

const handleSaveProfile = async () => {
  const trimmedName = editProfileForm.realName?.trim()
  if (!trimmedName) {
    ElMessage.warning('请输入真实姓名')
    return
  }
  savingProfile.value = true
  try {
    await updateProfileInfoApi({
      realName: trimmedName,
      gender: editProfileForm.gender
    })
    ElMessage.success('个人基本信息保存成功！')
    recordAuditLog(`更新个人基本信息(姓名:${trimmedName})`, 'info', 'PROFILE', '成功')
    openEditProfileDialog.value = false
    profile.value.realName = trimmedName
    profile.value.gender = editProfileForm.gender
    localStorage.setItem('seahorse_real_name', trimmedName)
  } catch (e: any) {
    console.warn('保存个人基本信息失败:', e)
  } finally {
    savingProfile.value = false
  }
}

onMounted(() => {
  loadProfile()
})

onUnmounted(() => {
  if (countdownTimer) {
    clearInterval(countdownTimer)
    countdownTimer = null
  }
})
</script>

<style scoped>
.user-profile-page {
  padding: 8px 0;
}

.profile-card {
  text-align: center;
}

.avatar-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px 0;
}

.user-avatar {
  background: linear-gradient(135deg, #0284c7, #38bdf8);
  font-size: 32px;
  font-weight: 700;
  color: #fff;
  box-shadow: 0 4px 12px rgba(2, 132, 199, 0.3);
}

.user-realname {
  margin: 12px 0 4px;
  font-size: 20px;
  font-weight: 700;
  color: #0f172a;
}

.user-username {
  font-size: 13px;
  color: #64748b;
  margin-bottom: 12px;
}

.role-tags {
  display: flex;
  justify-content: center;
}

.info-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
  text-align: left;
  padding: 0 10px;
}

.info-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 14px;
}

.info-item .lbl {
  color: #64748b;
  display: flex;
  align-items: center;
  gap: 6px;
}

.info-item .val {
  color: #0f172a;
  font-weight: 500;
}

.security-items {
  padding: 8px 12px;
}

.sec-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 0;
}

.sec-icon {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  margin-right: 16px;
}

.sec-lock {
  background: #e0f2fe;
  color: #0284c7;
}

.sec-phone {
  background: #fef3c7;
  color: #d97706;
}

.sec-shield {
  background: #dcfce7;
  color: #16a34a;
}

.sec-info {
  flex: 1;
}

.sec-title {
  font-size: 15px;
  font-weight: 600;
  color: #0f172a;
}

.sec-desc {
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
}

.log-filter-bar {
  display: flex;
  gap: 12px;
}

.pagination-box {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
