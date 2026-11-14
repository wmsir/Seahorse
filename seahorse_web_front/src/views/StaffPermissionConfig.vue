<template>
  <div class="staff-permission-container">
    <div class="header-card">
      <div class="header-left">
        <h2 class="title">👥 店员角色与查看权限配置</h2>
        <p class="subtitle">
          门店老板专权：支持为店长、收银员、技师等店员角色精细化配置数据查看范围与操作功能，保障门店营业额与会员隐私安全。
        </p>
      </div>
      <div class="header-right">
        <el-tag type="success" size="large" effect="dark">
          当前身份：门店老板 ({{ userRoleName }})
        </el-tag>
      </div>
    </div>

    <el-card class="content-card" shadow="hover">
      <el-tabs v-model="activeTab">
        <!-- 角色权限配置 -->
        <el-tab-pane label="🛡️ 角色权限矩阵配置" name="roles">
          <div class="tab-intro">
            <el-alert
              title="配置说明：未自定义配置的角色将默认继承系统推荐模板；保存后店员重新登录或刷新即可生效。"
              type="info"
              :closable="false"
              show-icon
            />
          </div>

          <el-row :gutter="20" style="margin-top: 18px" v-loading="loading">
            <el-col
              :xs="24"
              :md="8"
              v-for="role in roles"
              :key="role.roleCode"
            >
              <el-card class="role-box" shadow="never" :body-style="{ padding: '16px' }">
                <template #header>
                  <div class="role-card-header">
                    <div>
                      <span class="role-title">{{ role.roleName }}</span>
                      <el-tag size="small" type="info" style="margin-left: 8px">{{ role.roleCode }}</el-tag>
                    </div>
                    <el-tag
                      :type="role.isCustom ? 'warning' : 'primary'"
                      size="small"
                    >
                      {{ role.isCustom ? '已自定义' : '默认模板' }}
                    </el-tag>
                  </div>
                </template>

                <p class="role-desc">{{ role.description }}</p>

                <div class="permission-groups">
                  <div
                    v-for="(items, category) in groupPermissionsByCategory(role.availablePermissions)"
                    :key="category"
                    class="perm-group"
                  >
                    <div class="group-title">{{ getCategoryLabel(category) }}</div>
                    <el-checkbox-group v-model="roleSelectedPerms[role.roleCode]">
                      <div
                        v-for="perm in items"
                        :key="perm.code"
                        class="perm-item"
                      >
                        <el-checkbox :value="perm.code" :label="perm.code">
                          <span class="perm-name">{{ perm.name }}</span>
                        </el-checkbox>
                        <div class="perm-desc">{{ perm.description }}</div>
                      </div>
                    </el-checkbox-group>
                  </div>
                </div>

                <div class="card-footer-actions">
                  <el-button
                    type="primary"
                    style="width: 100%"
                    :loading="savingRole === role.roleCode"
                    @click="saveRolePermission(role.roleCode)"
                  >
                    保存「{{ role.roleName }}」权限
                  </el-button>
                </div>
              </el-card>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- 门店员工名册 -->
        <el-tab-pane label="📋 门店员工名册" name="staff">
          <div class="staff-table-header">
            <span class="sub-heading">当前租户在职员工及所属角色</span>
            <el-button type="primary" plain @click="fetchStaffList">刷新名册</el-button>
          </div>
          <el-table :data="staffList" v-loading="staffLoading" style="width: 100%; margin-top: 12px" border stripe>
            <el-table-column prop="id" label="ID" width="70" align="center" />
            <el-table-column prop="realName" label="姓名" width="120">
              <template #default="scope">
                {{ scope.row.realName || scope.row.name || '-' }}
              </template>
            </el-table-column>
            <el-table-column prop="username" label="登录账号" width="140" />
            <el-table-column prop="role" label="角色标识" width="160">
              <template #default="scope">
                <el-tag :type="getRoleTagType(scope.row.role)">
                  {{ formatRoleName(scope.row.role) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="phone" label="联系电话" width="140">
              <template #default="scope">
                {{ scope.row.phone || '-' }}
              </template>
            </el-table-column>
            <el-table-column prop="postName" label="岗位/部门" width="140">
              <template #default="scope">
                <el-tag size="small" type="info">{{ scope.row.postName || scope.row.department || scope.row.industry || '通用' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="100" align="center">
              <template #default="scope">
                <el-tag
                  :type="(scope.row.status === 'ACTIVE' || scope.row.status === 'ENABLED') ? 'success' : (scope.row.status === 'PENDING_REVIEW' ? 'warning' : 'danger')"
                  size="small"
                >
                  {{ (scope.row.status === 'ACTIVE' || scope.row.status === 'ENABLED') ? '正常' : (scope.row.status === 'PENDING_REVIEW' ? '待审核' : '停用') }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="createdAt" label="入职时间">
              <template #default="scope">
                {{ formatDate(scope.row.createdAt) }}
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'
import {
  getMerchantStaffRolesPermissionsApi,
  updateMerchantStaffRolePermissionApi,
  getMerchantStaffListApi
} from '@/api'

const activeTab = ref('roles')
const loading = ref(false)
const savingRole = ref<string | null>(null)
const staffLoading = ref(false)

const roles = ref<any[]>([])
const roleSelectedPerms = ref<Record<string, string[]>>({})
const staffList = ref<any[]>([])

const currentUser = computed(() => {
  try {
    return JSON.parse(localStorage.getItem('currentUser') || '{}')
  } catch {
    return {}
  }
})

const userRoleName = computed(() => {
  const role = localStorage.getItem('seahorse_role') || currentUser.value.role
  if (role === 'SUPER_ADMIN' || role === 'MERCHANT_ADMIN' || role === 'TENANT_ADMIN' || role === 'STORE_OWNER') return '门店老板/超管'
  if (role === 'STORE_MANAGER' || role === 'MANAGER') return '店长'
  if (role === 'PLATFORM_DEVELOPER') return '平台开发商'
  return formatRoleName(role) || '管理员'
})

const standardPermissions = [
  // 1. 规章与员工协同 (全员公开查阅、电子手写签字、心声诉求、店长发布管理)
  { code: 'regulation:view', name: '查看规章制度与公开意见箱', category: 'REGULATION', description: '查阅全店规章制度、浏览全员公开心声建言与管理方官方答复公示' },
  { code: 'regulation:sign', name: '手写电子签名防抵赖确认', category: 'REGULATION', description: '在线手写电子签字确认规章制度条款，生成不可篡改电子存据' },
  { code: 'regulation:feedback', name: '提交合理化建议与诉求', category: 'REGULATION', description: '全员均可实名或完全匿名向管理方提交合理化建议、困难求助或创新提案' },
  { code: 'regulation:manage', name: '发布规章与答复采纳建议', category: 'REGULATION', description: '店长/老板专属：发布修订规章、一键导出宣导海报与红头公文/PDF、官方答复并落地员工建议' },

  // 2. 门店经营与老板专属
  { code: 'merchant:dashboard_view', name: '查看智慧经营大屏与营收分析', category: 'VIEW', description: '查看本店当日实收金额、客单价、经营趋势与时段客流' },
  { code: 'merchant:store_manage', name: '开设新分店与切换行业模态策略', category: 'CONFIG', description: '创建多业态新门店，配置服务费与双轨扣减策略' },
  { code: 'merchant:staff_perm_manage', name: '配置店员查看权限与权限矩阵', category: 'CONFIG', description: '门店老板专属：配置店长、收银员、技师的查看范围与操作权限' },

  // 3. 工位在场与收银结算
  { code: 'session:view', name: '查看工位/桌台在场状态看板', category: 'BUSINESS', description: '实时查看美业镜台、餐饮散台、汽修工位的占用与点单情况' },
  { code: 'session:operate', name: '工位开单/加单/技师分摊', category: 'BUSINESS', description: '发起在场消费工单，指派执行技师与提成比例' },
  { code: 'cashier:checkout', name: '执行组合收银买单与折扣结算', category: 'BUSINESS', description: '支持双轨储值扣减、微信扫码与现金找零结算' },

  // 4. 会员与海马体记忆中心
  { code: 'member:list_view', name: '查看门店会员列表与基础画像', category: 'MEMBER', description: '检索会员姓名、等级、到店频次与累计消费' },
  { code: 'member:phone_view', name: '查看会员完整手机号', category: 'MEMBER', description: '查看未脱敏的会员真实手机号联系方式' },
  { code: 'member:recharge', name: '会员双轨储值充值与发放次卡', category: 'MEMBER', description: '办理会员本金/赠金储值及次卡权益发放' },
  { code: 'member:pref_view', name: '查看会员“海马体”记忆档案', category: 'MEMBER', description: '查看会员发质、口味忌口、爱车档案与服务习惯标签' },
  { code: 'member:pref_edit', name: '录入/更新会员“海马体”记忆档案', category: 'MEMBER', description: '技师或店员为常客新增或更新个性化喜好备忘' }
]

const defaultFallbackRoles = [
  {
    roleCode: 'STORE_MANAGER',
    roleName: '店长',
    description: '负责门店日常营运接待、空间调度、收银结算、规章发布与员工建言答复',
    isCustom: false,
    availablePermissions: standardPermissions,
    permissions: [
      'regulation:view', 'regulation:sign', 'regulation:feedback', 'regulation:manage',
      'merchant:dashboard_view', 'session:view', 'session:operate',
      'cashier:checkout',
      'member:list_view', 'member:phone_view', 'member:recharge', 'member:pref_view', 'member:pref_edit'
    ]
  },
  {
    roleCode: 'CASHIER',
    roleName: '收银员',
    description: '负责前台开单、组合结算、会员储值、查阅规章签字与全员意见箱交流',
    isCustom: false,
    availablePermissions: standardPermissions,
    permissions: [
      'regulation:view', 'regulation:sign', 'regulation:feedback',
      'session:view', 'session:operate', 'cashier:checkout',
      'member:list_view', 'member:phone_view', 'member:recharge', 'member:pref_view'
    ]
  },
  {
    roleCode: 'TECHNICIAN',
    roleName: '技师/手艺人',
    description: '执行专业项目、维护海马体记忆档案、查阅规章签字与公开交流心声',
    isCustom: false,
    availablePermissions: standardPermissions,
    permissions: [
      'regulation:view', 'regulation:sign', 'regulation:feedback',
      'session:view', 'member:list_view', 'member:pref_view', 'member:pref_edit'
    ]
  }
]

const getCategoryLabel = (category: string) => {
  const map: Record<string, string> = {
    REGULATION: '📜 规章制度与员工协同',
    规章协同: '📜 规章制度与员工协同',
    BUSINESS: '💳 收银与营业操作',
    前台与收银: '💳 收银与营业操作',
    MEMBER: '👥 会员与隐私权限',
    海马会员中心: '👥 会员与隐私权限',
    VIEW: '📊 数据查看权限',
    门店经营管控: '🏬 门店经营与老板专属',
    CONFIG: '⚙️ 门店与系统设置'
  }
  return map[category] || category
}

const groupPermissionsByCategory = (perms?: any[]) => {
  const groups: Record<string, any[]> = {}
  const list = (perms && perms.length > 0) ? perms : standardPermissions
  for (const p of list) {
    let cat = p.category || 'VIEW'
    if (p.module === '规章协同' || p.code?.startsWith('regulation:')) cat = 'REGULATION'
    else if (p.module === '前台与收银') cat = 'BUSINESS'
    else if (p.module === '海马会员中心') cat = 'MEMBER'
    else if (p.module === '门店经营管控') cat = 'VIEW'
    if (!groups[cat]) groups[cat] = []
    groups[cat].push(p)
  }
  return groups
}

const fetchRoles = async () => {
  loading.value = true
  try {
    const res: any = await getMerchantStaffRolesPermissionsApi()
    const roleList = Array.isArray(res) ? res : (res?.data || [])
    if (roleList.length > 0) {
      // 排除非门店员工角色
      const filtered = roleList.filter((r: any) =>
        r.roleCode !== 'PLATFORM_DEVELOPER' &&
        r.roleCode !== 'CUSTOMER_MEMBER' &&
        r.roleCode !== 'SUPER_ADMIN'
      ).map((r: any) => {
        return {
          ...r,
          availablePermissions: (r.availablePermissions && r.availablePermissions.length > 0)
            ? r.availablePermissions
            : standardPermissions
        }
      })
      roles.value = filtered
      const mapping: Record<string, string[]> = {}
      for (const r of filtered) {
        mapping[r.roleCode] = [...(r.permissions || [])]
      }
      roleSelectedPerms.value = mapping
    } else {
      roles.value = defaultFallbackRoles
      const mapping: Record<string, string[]> = {}
      for (const r of defaultFallbackRoles) {
        mapping[r.roleCode] = [...r.permissions]
      }
      roleSelectedPerms.value = mapping
    }
  } catch (err: any) {
    roles.value = defaultFallbackRoles
    const mapping: Record<string, string[]> = {}
    for (const r of defaultFallbackRoles) {
      mapping[r.roleCode] = [...r.permissions]
    }
    roleSelectedPerms.value = mapping
  } finally {
    loading.value = false
  }
}

const saveRolePermission = async (roleCode: string) => {
  savingRole.value = roleCode
  try {
    const perms = roleSelectedPerms.value[roleCode] || []
    await updateMerchantStaffRolePermissionApi(roleCode, {
      permissions: perms
    })
    ElMessage.success(`角色 [${formatRoleName(roleCode)}] 权限更新成功`)
    await fetchRoles()
  } catch (err: any) {
    console.warn('保存角色权限失败:', err)
  } finally {
    savingRole.value = null
  }
}

const fetchStaffList = async () => {
  staffLoading.value = true
  try {
    const res: any = await getMerchantStaffListApi()
    staffList.value = Array.isArray(res) ? res : (res?.data || [])
  } catch (err: any) {
    console.warn('获取员工名册失败:', err)
  } finally {
    staffLoading.value = false
  }
}

const formatRoleName = (role: string) => {
  const map: Record<string, string> = {
    STORE_MANAGER: '店长',
    CASHIER: '收银员',
    TECHNICIAN: '技师/手艺人',
    WAITER: '服务员',
    SUPER_ADMIN: '门店老板',
    TENANT_ADMIN: '租户老板',
    STORE_OWNER: '门店老板',
    MERCHANT_ADMIN: '商家主理人',
    PLATFORM_DEVELOPER: '系统维护人'
  }
  return map[role] || role
}

const getRoleTagType = (role: string) => {
  if (role === 'SUPER_ADMIN' || role === 'MERCHANT_ADMIN' || role === 'TENANT_ADMIN' || role === 'STORE_OWNER') return 'danger'
  if (role === 'STORE_MANAGER') return 'warning'
  if (role === 'CASHIER') return 'primary'
  if (role === 'TECHNICIAN' || role === 'WAITER') return 'success'
  return 'info'
}

const formatDate = (dateStr?: string) => {
  if (!dateStr) return '-'
  return dateStr.replace('T', ' ').substring(0, 19)
}

onMounted(() => {
  fetchRoles()
  fetchStaffList()
})
</script>

<style scoped>
.staff-permission-container {
  padding: 8px;
}

.header-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #ffffff;
  padding: 20px 24px;
  border-radius: 12px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.04);
  margin-bottom: 20px;
}

.title {
  font-size: 20px;
  font-weight: 700;
  color: #1f2937;
  margin: 0 0 6px 0;
}

.subtitle {
  font-size: 13px;
  color: #6b7280;
  margin: 0;
}

.content-card {
  border-radius: 12px;
}

.tab-intro {
  margin-bottom: 12px;
}

.role-box {
  background: #fafafa;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  margin-bottom: 16px;
  display: flex;
  flex-direction: column;
}

.role-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.role-title {
  font-weight: 700;
  font-size: 16px;
  color: #111827;
}

.role-desc {
  font-size: 13px;
  color: #6b7280;
  margin: 0 0 14px 0;
  min-height: 36px;
}

.permission-groups {
  max-height: 480px;
  overflow-y: auto;
  padding-right: 6px;
}

.perm-group {
  background: #ffffff;
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  padding: 10px 12px;
  margin-bottom: 12px;
}

.group-title {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
  border-bottom: 1px solid #f3f4f6;
  padding-bottom: 6px;
  margin-bottom: 8px;
}

.perm-item {
  margin-bottom: 8px;
}

.perm-name {
  font-size: 13px;
  font-weight: 500;
}

.perm-desc {
  font-size: 12px;
  color: #9ca3af;
  margin-left: 24px;
  margin-top: 2px;
}

.card-footer-actions {
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid #ebeef5;
}

.staff-table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.sub-heading {
  font-size: 15px;
  font-weight: 600;
  color: #374151;
}
</style>
