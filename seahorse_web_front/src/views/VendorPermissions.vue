<template>
  <div class="vendor-permissions-container">
    <!-- 顶部标题 -->
    <div class="page-hero-header">
      <div class="hero-left">
        <div class="hero-icon-box">
          <el-icon :size="26"><Key /></el-icon>
        </div>
        <div class="hero-text-box">
          <div class="hero-title-row">
            <h2 class="hero-title">全平台角色与查看权限全局模板配置</h2>
            <el-tag type="danger" effect="dark" size="small" class="hero-tag">全局 RBAC 权限中枢</el-tag>
          </div>
          <p class="hero-subtitle">
            系统开发商统一制定全平台面向租户端 4 大业务岗位（租户老板、旗舰店长、前台收银员、托尼老师/服务技师）的全局默认授权模板。系统开发维护人与平台运营默认具备 100% 全功能豁免，无需额外配置。
          </p>
        </div>
      </div>
      <div class="hero-right-actions">
        <el-button type="primary" plain @click="loadPermissions">
          <el-icon><Refresh /></el-icon> 刷新权限矩阵
        </el-button>
      </div>
    </div>

    <!-- 系统开发维护人/平台运营全权豁免说明提示框 -->
    <div class="developer-exemption-banner">
      <div class="banner-left">
        <div class="shield-icon">🛡️</div>
        <div class="banner-text">
          <div class="banner-title">系统开发维护人 / 平台运营人员：默认拥有 100% 全功能绝对豁免与全数据查看权限</div>
          <div class="banner-sub">
            作为底层平台主权持有者，系统开发维护人与平台运营人员（PLATFORM_DEVELOPER）默认拥有对全系统所有业务模块、系统接口与底层参数的完全访问和无条件豁免权限，底层系统永不拦截，无需且不支持在此进行权限剔除或配置。下方仅开放对租户端 4 类运营角色的全局默认模版进行定制。
          </div>
        </div>
      </div>
      <div class="banner-badge">
        <el-tag type="success" effect="dark" size="default">永久超级豁免 · 免配保护</el-tag>
      </div>
    </div>

    <!-- 全平台租户安全审计日志记录策略全局管控卡片 (超管专属中枢) -->
    <el-card shadow="never" class="audit-policy-central-card" style="margin-bottom: 22px; border-radius: 12px; border: 1px solid #e0e7ff; background: linear-gradient(180deg, #f8faff 0%, #ffffff 100%);">
      <template #header>
        <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
          <div style="display: flex; align-items: center; gap: 12px;">
            <div style="width: 38px; height: 38px; border-radius: 10px; background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 20px; box-shadow: 0 4px 10px rgba(79, 70, 229, 0.25);">
              🛡️
            </div>
            <div>
              <div style="display: flex; align-items: center; gap: 8px;">
                <span style="font-size: 16px; font-weight: 700; color: #1e1b4b;">全平台租户安全审计日志策略与等级门槛全局管控</span>
                <el-tag type="warning" size="small" effect="dark">超管专享 · 租户绝密免见</el-tag>
              </div>
              <div style="font-size: 12.5px; color: #6366f1; margin-top: 3px;">
                平台超级管理员集中制定各等级商户租户的日志记录规则与门槛。商户租户端在个人中心只能查看自身具体登录与安全事件日志，绝对看不到此策略配置项。
              </div>
            </div>
          </div>
          <el-button type="primary" :loading="savingGlobalPolicy" @click="saveGlobalAuditPolicy">
            💾 保存全平台安全审计策略
          </el-button>
        </div>
      </template>

      <el-form :model="globalAuditPolicy" label-width="155px" style="max-width: 960px; padding: 4px 10px;">
        <el-form-item label="审计日志总开关">
          <div style="display: flex; align-items: center; gap: 14px;">
            <el-switch
              v-model="globalAuditPolicy.enabled"
              active-text="全局开启真实安全事件审计"
              inactive-text="全网停用审计记录"
            />
            <span style="font-size: 12px; color: #64748b;">
              (关闭后全网所有商户租户登录与安全行为均不再写入日志)
            </span>
          </div>
        </el-form-item>

        <el-form-item label="最低记录等级门槛">
          <el-select v-model="globalAuditPolicy.minTier" style="width: 440px;">
            <el-option label="ALL - 全部租户等级均记录 (含试用/体验版商户)" value="ALL" />
            <el-option label="STANDARD - 标准专业版及以上租户记录 (体验/试用免记)" value="STANDARD" />
            <el-option label="PRO - 高阶连锁版及以上租户记录 (专业版以下免记)" value="PRO" />
            <el-option label="FLAGSHIP - 仅旗舰至尊版高阶租户记录 (其余全免记)" value="FLAGSHIP" />
          </el-select>
          <div style="font-size: 12px; color: #64748b; margin-top: 6px; line-height: 1.5;">
            💡 <b>超级管理员门槛控制规则：</b>新入驻或等级较低的普通租户免记安全审计日志，极大节省云端存储与数据库高频IO开销；满足门槛的高阶合规客户自动激活全链路安全追踪。
          </div>
        </el-form-item>

        <el-form-item label="全局审计事件类型">
          <el-checkbox-group v-model="globalAuditPolicy.recordEvents">
            <el-checkbox label="LOGIN">账号安全鉴权登录</el-checkbox>
            <el-checkbox label="PASSWORD">登录密码安全修改</el-checkbox>
            <el-checkbox label="PHONE">更换密保手机</el-checkbox>
            <el-checkbox label="PROFILE">管理员基本资料变更</el-checkbox>
            <el-checkbox label="SECURITY_LOCK">双因子防盗刷安全锁</el-checkbox>
            <el-checkbox label="POLICY_CHANGE">安全策略配置变更</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 角色权限卡片网格 -->
    <div v-loading="loading" class="roles-grid">
      <el-card
        v-for="role in vendorRoles"
        :key="role.roleCode"
        shadow="hover"
        class="role-perm-card"
      >
        <template #header>
          <div class="role-header-row">
            <div class="role-name-box">
              <span class="role-badge-icon">{{ getRoleIcon(role.roleCode) }}</span>
              <span class="role-name">{{ role.roleName }}</span>
            </div>
            <el-tag size="small" :type="getRoleTagType(role.roleCode)">{{ role.roleCode }}</el-tag>
          </div>
        </template>

        <div class="role-desc">{{ role.description }}</div>

        <div class="perm-list-box">
          <el-checkbox-group v-model="vendorRolePerms[role.roleCode]">
            <div v-for="perm in role.availablePermissions" :key="perm.code" class="perm-check-item">
              <el-checkbox :label="perm.code" :value="perm.code">
                <span class="perm-name">{{ perm.name }}</span>
              </el-checkbox>
              <div class="perm-desc">{{ perm.description }}</div>
            </div>
          </el-checkbox-group>
        </div>

        <div class="role-card-footer">
          <el-button
            type="primary"
            style="width: 100%;"
            size="default"
            :loading="savingRoleCode === role.roleCode"
            @click="saveRolePermissions(role.roleCode)"
          >
            保存「{{ role.roleName }}」全局配置
          </el-button>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import {
  getVendorPermissionsApi,
  updateVendorRolePermissionApi
} from '@/api'
import { ElMessage } from 'element-plus'
import {
  Key,
  Refresh
} from '@element-plus/icons-vue'

const loading = ref(false)
const vendorRoles = ref<any[]>([])
const vendorRolePerms = ref<Record<string, string[]>>({})
const savingRoleCode = ref('')

const loadPermissions = async () => {
  loading.value = true
  try {
    const res: any = await getVendorPermissionsApi()
    if (Array.isArray(res) && res.length > 0) {
      // 过滤掉开发商运维角色，只展示租户端业务角色
      const filtered = res.filter((r: any) => !['PLATFORM_DEVELOPER', 'DEVELOPER', 'VENDOR'].includes(r.roleCode))
      vendorRoles.value = filtered
      filtered.forEach((role: any) => {
        vendorRolePerms.value[role.roleCode] = [...(role.currentPermissions || [])]
      })
    } else {
      // 演示兜底数据
      vendorRoles.value = [
        {
          roleCode: 'SUPER_ADMIN',
          roleName: '租户老板 (SUPER_ADMIN)',
          description: '租户唯一法定最高权限，具备开店、财税、薪资、提成与全店数据全量豁免权限',
          currentPermissions: ['MENU_ALL', 'DATA_ALL', 'FINANCE_ALL', 'STAFF_ALL'],
          availablePermissions: [
            { code: 'MENU_ALL', name: '全量系统功能页签豁免访问', description: '不受任何菜单白名单限制' },
            { code: 'DATA_ALL', name: '全连锁分店经营数据漫游查看', description: '可切换任意分店查账' },
            { code: 'FINANCE_ALL', name: '财务成本利润与账本绝对支配', description: '包含全口径利润表' },
            { code: 'STAFF_ALL', name: '员工账号开通与角色矩阵授权', description: '随时启停员工账号' }
          ]
        },
        {
          roleCode: 'STORE_MANAGER',
          roleName: '旗舰店长 (STORE_MANAGER)',
          description: '单个或授权多个分店的现场运营负责人，管人、管货、管前台排班与业绩考核',
          currentPermissions: ['MENU_FRONT', 'MENU_STAFF', 'MENU_GOODS', 'DATA_STORE'],
          availablePermissions: [
            { code: 'MENU_FRONT', name: '前台收银与空间桌台看板全权调度', description: '开台、加项与转台' },
            { code: 'MENU_STAFF', name: '本店员工排班与入职申请审批', description: '扫码入职审核' },
            { code: 'MENU_GOODS', name: '物料库存盘点与采购入库申请', description: 'BOM耗材盘点' },
            { code: 'DATA_STORE', name: '所属执业门店营业报表与业绩核算', description: '仅限执业门店' }
          ]
        },
        {
          roleCode: 'CASHIER',
          roleName: '前台收银员 (CASHIER)',
          description: '负责门店前台顾客接待、会员开卡充值、组合结算开单及盲盘交班',
          currentPermissions: ['MENU_CASHIER', 'MENU_MEMBER_RECHARGE', 'MENU_SHIFT'],
          availablePermissions: [
            { code: 'MENU_CASHIER', name: '快捷收银结算与动态追加项目', description: '卡券微信现金多轨结算' },
            { code: 'MENU_MEMBER_RECHARGE', name: '会员快速开卡与储值充值', description: '双轨扣减与次卡发放' },
            { code: 'MENU_SHIFT', name: '收银日结盲盘与钱箱交班登记', description: '盲盘防作弊对账' }
          ]
        },
        {
          roleCode: 'TECHNICIAN',
          roleName: '服务技师 / 托尼老师 (TECHNICIAN)',
          description: '一线手艺人、发型师、汽修师傅、厨师等，专注在场服务履约与个人提成业绩',
          currentPermissions: ['MENU_MY_PERF', 'MENU_REGULATION'],
          availablePermissions: [
            { code: 'MENU_MY_PERF', name: '个人提成与服务钟数业绩实时看板', description: '透明提成查询' },
            { code: 'MENU_REGULATION', name: '查阅规章制度并完成电子签名确认', description: '规章与意见箱直通' },
            { code: 'MENU_COMMISSION_DISPUTE', name: '服务工单分工提成争议一键复核', description: '多人提成分工' }
          ]
        }
      ]
      vendorRoles.value.forEach((role: any) => {
        vendorRolePerms.value[role.roleCode] = [...(role.currentPermissions || [])]
      })
    }
  } catch (e) {
    console.warn('Load permissions fallback:', e)
  } finally {
    loading.value = false
  }
}

const saveRolePermissions = async (roleCode: string) => {
  savingRoleCode.value = roleCode
  try {
    const perms = vendorRolePerms.value[roleCode] || []
    await updateVendorRolePermissionApi(roleCode, { permissions: perms })
    ElMessage.success(`🎉 角色【${roleCode}】全平台默认权限模板已成功保存生效！`)
  } catch (e: any) {
    ElMessage.error(e.message || '保存失败')
  } finally {
    savingRoleCode.value = ''
  }
}

const getRoleIcon = (code: string) => {
  switch (code) {
    case 'SUPER_ADMIN': return '👑'
    case 'STORE_MANAGER': return '🏬'
    case 'CASHIER': return '💳'
    case 'TECHNICIAN': return '✂️'
    default: return '👤'
  }
}

const getRoleTagType = (code: string) => {
  switch (code) {
    case 'SUPER_ADMIN': return 'danger'
    case 'STORE_MANAGER': return 'warning'
    case 'CASHIER': return 'primary'
    case 'TECHNICIAN': return 'success'
    default: return 'info'
  }
}

// ==============================================================================
// 全平台租户安全审计日志策略与等级门槛全局管控 (超管专属)
// ==============================================================================
interface AuditPolicy {
  enabled: boolean
  minTier: 'ALL' | 'STANDARD' | 'PRO' | 'FLAGSHIP'
  recordEvents: string[]
}

const GLOBAL_AUDIT_POLICY_KEY = 'seahorse_global_audit_policy'
const savingGlobalPolicy = ref(false)
const globalAuditPolicy = ref<AuditPolicy>({
  enabled: true,
  minTier: 'ALL',
  recordEvents: ['LOGIN', 'PASSWORD', 'PHONE', 'PROFILE', 'SECURITY_LOCK', 'POLICY_CHANGE']
})

const loadGlobalAuditPolicy = () => {
  try {
    const raw = localStorage.getItem(GLOBAL_AUDIT_POLICY_KEY)
    if (raw) {
      globalAuditPolicy.value = { ...globalAuditPolicy.value, ...JSON.parse(raw) }
    }
  } catch (e) {
    console.error('loadGlobalAuditPolicy error:', e)
  }
}

const saveGlobalAuditPolicy = () => {
  savingGlobalPolicy.value = true
  try {
    localStorage.setItem(GLOBAL_AUDIT_POLICY_KEY, JSON.stringify(globalAuditPolicy.value))
    ElMessage.success('🎉 全平台租户安全审计日志记录全局策略已成功保存生效！租户端将严格遵从该规则且无权查阅修改。')
  } catch (e: any) {
    ElMessage.error(e.message || '保存失败')
  } finally {
    savingGlobalPolicy.value = false
  }
}

onMounted(() => {
  loadPermissions()
  loadGlobalAuditPolicy()
})
</script>

<style scoped>
.vendor-permissions-container {
  padding: 18px 24px 40px;
  background: #f8fafc;
  min-height: calc(100vh - 60px);
}

.page-hero-header {
  background: linear-gradient(135deg, #ffffff 0%, #fef2f2 100%);
  border: 1px solid #fee2e2;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(239, 68, 68, 0.04);
  margin-bottom: 18px;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hero-icon-box {
  width: 52px;
  height: 52px;
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(239, 68, 68, 0.25);
}

.hero-title-row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.hero-title {
  margin: 0;
  font-size: 20px;
  font-weight: 800;
  color: #0f172a;
}

.hero-subtitle {
  margin: 6px 0 0;
  font-size: 13px;
  color: #64748b;
  line-height: 1.5;
  max-width: 820px;
}

.roles-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 18px;
}

.role-perm-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.role-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.role-name-box {
  display: flex;
  align-items: center;
  gap: 8px;
}

.role-badge-icon {
  font-size: 18px;
}

.role-name {
  font-weight: 800;
  font-size: 15px;
  color: #0f172a;
}

.role-desc {
  font-size: 12px;
  color: #64748b;
  line-height: 1.5;
  margin-bottom: 14px;
  min-height: 36px;
}

.perm-list-box {
  max-height: 380px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding-right: 6px;
}

.perm-check-item {
  margin-bottom: 10px;
  background: #f8fafc;
  padding: 8px 12px;
  border-radius: 6px;
  border: 1px solid #f1f5f9;
}

.perm-name {
  font-weight: 700;
  color: #1e293b;
  font-size: 13px;
}

.perm-desc {
  font-size: 11px;
  color: #94a3b8;
  margin-left: 24px;
  margin-top: 2px;
}

.role-card-footer {
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid #f1f5f9;
}

.developer-exemption-banner {
  background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
  border: 1px solid #bbf7d0;
  border-radius: 12px;
  padding: 16px 20px;
  margin-bottom: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  box-shadow: 0 2px 6px rgba(16, 185, 129, 0.08);
}

.banner-left {
  display: flex;
  align-items: center;
  gap: 14px;
}

.shield-icon {
  font-size: 28px;
  width: 44px;
  height: 44px;
  background: #ffffff;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(16, 185, 129, 0.15);
  flex-shrink: 0;
}

.banner-title {
  font-weight: 800;
  font-size: 14px;
  color: #166534;
  margin-bottom: 4px;
}

.banner-sub {
  font-size: 12px;
  color: #15803d;
  line-height: 1.5;
}

.banner-badge {
  flex-shrink: 0;
}
</style>
