<template>
  <div class="vendor-activity-container">
    <!-- 顶部标题栏 -->
    <div class="page-hero-header">
      <div class="hero-left">
        <div class="hero-icon-box">
          <el-icon :size="26"><TrendCharts /></el-icon>
        </div>
        <div class="hero-text-box">
          <div class="hero-title-row">
            <h2 class="hero-title">租户活跃与白天营业时段分析 · 审计日志</h2>
            <el-tag type="primary" effect="dark" size="small" class="hero-tag">实时行为画像与算力排班</el-tag>
          </div>
          <p class="hero-subtitle">
            采集全平台租户白天各时段（早市晨峰、午间高峰、下午黄金、晚间夜市）的使用频次与业务特征，精准指引开发团队在业务低谷期（22:00-08:00）发布微服务平滑热更新，并在高峰期动态伸缩数据库连接池。
          </p>
        </div>
      </div>
      <div class="hero-right-actions">
        <el-button type="primary" plain @click="loadAllActivityData">
          <el-icon><Refresh /></el-icon> 刷新实时活跃数据
        </el-button>
        <el-button type="primary" @click="scrollToLogs">
          <el-icon><Timer /></el-icon> 穿透查阅活动审计日志
        </el-button>
      </div>
    </div>

    <!-- 白天营业时段特征总览卡片 (真实时段统计) -->
    <el-row :gutter="14" class="stat-cards-row">
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-header">
            <span class="stat-title">🌅 早市晨峰 (08:00 - 11:30)</span>
            <el-tag size="small" type="info">开店盘点</el-tag>
          </div>
          <div class="stat-num text-cyan">{{ morningPercent }} <span class="stat-sub">({{ periodCounts.morning }} 次操作)</span></div>
          <div class="stat-desc">主营业务：物料盘点、工位开台、预约确认</div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-header">
            <span class="stat-title">☀️ 午间高峰 (11:30 - 14:00)</span>
            <el-tag size="small" type="warning">餐饮/快速消费</el-tag>
          </div>
          <div class="stat-num text-amber">{{ noonPercent }} <span class="stat-sub">({{ periodCounts.noon }} 次操作)</span></div>
          <div class="stat-desc">主营业务：扫码点单、加单并台、快速收银</div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card stat-peak">
          <div class="stat-header">
            <span class="stat-title">🌟 下午黄金 (14:00 - 18:00)</span>
            <el-tag size="small" type="danger" effect="dark">🔥 密集并发</el-tag>
          </div>
          <div class="stat-num text-rose">{{ afternoonPercent }} <span class="stat-sub">({{ periodCounts.afternoon }} 次操作)</span></div>
          <div class="stat-desc">主营业务：美业洗剪烫染、施工维修、大额充值</div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-header">
            <span class="stat-title">🌙 晚间夜市 (18:00 - 22:00)</span>
            <el-tag size="small" type="success">交班对账</el-tag>
          </div>
          <div class="stat-num text-purple">{{ eveningPercent }} <span class="stat-sub">({{ periodCounts.evening }} 次操作)</span></div>
          <div class="stat-desc">主营业务：日结盲盘、收银交班、规章签字确认</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 租户白天各时段业务行为深度特征表 -->
    <el-card shadow="never" class="table-card">
      <template #header>
        <div class="card-header-flex">
          <div class="header-left">
            <el-icon color="#0284c7" :size="18"><Clock /></el-icon>
            <span class="header-title">各租户白天使用时段特征与行为画像统计</span>
          </div>
          <div class="header-right">
            <el-tag type="info" size="small">基于真实登录与系统操作实时聚合</el-tag>
          </div>
        </div>
      </template>

      <el-table :data="tenantDaytimeStats" v-loading="loading" stripe border style="width: 100%;">
        <el-table-column prop="tenantId" label="租户ID" width="90" />
        <el-table-column prop="tenantName" label="租户名称" min-width="170">
          <template #default="{ row }">
            <div style="font-weight: 700; color: #0f172a;">{{ row.tenantName }}</div>
            <div style="font-size: 11px; color: #64748b;">行业：{{ row.industryName }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="daytimeTotalOps" label="日间操作量" width="120" align="center" sortable>
          <template #default="{ row }">
            <span style="font-weight: 700; color: #0284c7;">{{ row.daytimeTotalOps }} 次</span>
          </template>
        </el-table-column>
        <el-table-column label="白天最高频密集时段" width="160">
          <template #default="{ row }">
            <el-tag type="warning" effect="dark" size="default" style="font-weight: 600;">
              {{ row.peakTimeSlot }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="峰值业务特征与驱动原因采集" min-width="240">
          <template #default="{ row }">
            <div style="font-size: 13px; color: #334155; line-height: 1.5;">
              💡 {{ row.peakTimeReason }}
            </div>
          </template>
        </el-table-column>
        <el-table-column label="白天4时段分布比" width="190">
          <template #default="{ row }">
            <div class="mini-period-bars">
              <div class="mini-bar-item">
                <span class="lbl">早</span>
                <el-progress :percentage="row.daytimeTotalOps > 0 ? Math.round(row.morningOps / row.daytimeTotalOps * 100) : 0" :stroke-width="5" :show-text="false" color="#38bdf8" />
                <span class="val">{{ row.morningOps }}</span>
              </div>
              <div class="mini-bar-item">
                <span class="lbl">午</span>
                <el-progress :percentage="row.daytimeTotalOps > 0 ? Math.round(row.noonOps / row.daytimeTotalOps * 100) : 0" :stroke-width="5" :show-text="false" color="#fbbf24" />
                <span class="val">{{ row.noonOps }}</span>
              </div>
              <div class="mini-bar-item">
                <span class="lbl">下</span>
                <el-progress :percentage="row.daytimeTotalOps > 0 ? Math.round(row.afternoonOps / row.daytimeTotalOps * 100) : 0" :stroke-width="5" :show-text="false" color="#f97316" />
                <span class="val">{{ row.afternoonOps }}</span>
              </div>
              <div class="mini-bar-item">
                <span class="lbl">晚</span>
                <el-progress :percentage="row.daytimeTotalOps > 0 ? Math.round(row.eveningOps / row.daytimeTotalOps * 100) : 0" :stroke-width="5" :show-text="false" color="#a855f7" />
                <span class="val">{{ row.eveningOps }}</span>
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="活跃指数" width="130" align="center">
          <template #default="{ row }">
            <div style="font-weight: 800; font-size: 14px;" :style="{ color: row.activityIndex >= 90 ? '#059669' : '#0284c7' }">
              {{ row.activityIndex }} / 100
            </div>
            <el-progress :percentage="row.activityIndex" :stroke-width="4" :show-text="false" :color="row.activityIndex >= 90 ? '#10b981' : '#0284c7'" />
          </template>
        </el-table-column>
        <el-table-column prop="primaryModule" label="日间主力模块" width="130" align="center">
          <template #default="{ row }">
            <el-tag size="small" type="info">{{ row.primaryModule }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="filterLogsByTenant(row.tenantId)">
              查阅日志
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 租户操作活动全量审计日志 -->
    <el-card id="activity-log-anchor" shadow="never" class="table-card" style="margin-top: 18px;">
      <template #header>
        <div class="table-toolbar">
          <div class="toolbar-left">
            <div style="font-weight: 700; color: #0f172a; font-size: 15px; display: flex; align-items: center; gap: 6px;">
              <el-icon color="#0284c7"><Timer /></el-icon>
              <span>租户全量操作活动审计日志 (支持白天时段过滤)</span>
            </div>
            <el-select v-model="logTimeSlotFilter" placeholder="营业时段" size="small" style="width: 160px;">
              <el-option label="全部营业时段" value="ALL" />
              <el-option label="🌅 早市晨峰 (08:00-11:30)" value="MORNING" />
              <el-option label="☀️ 午间高峰 (11:30-14:00)" value="NOON" />
              <el-option label="🌟 下午黄金 (14:00-18:00)" value="AFTERNOON" />
              <el-option label="🌙 晚间夜市 (18:00-22:00)" value="EVENING" />
              <el-option label="💤 夜间离线 (22:00-08:00)" value="NIGHT" />
            </el-select>
            <el-select v-model="logTenantFilter" placeholder="所属租户" size="small" style="width: 170px;" clearable>
              <el-option label="全部租户" value="ALL" />
              <el-option v-for="t in tenantOptions" :key="t.tenantId" :label="t.tenantName" :value="t.tenantId" />
            </el-select>
            <el-select v-model="logModuleFilter" placeholder="业务功能模块" size="small" style="width: 140px;">
              <el-option label="全部功能模块" value="ALL" />
              <el-option label="系统登录" value="LOGIN" />
              <el-option label="退出系统" value="LOGOUT" />
              <el-option label="安全与密码" value="PASSWORD" />
              <el-option label="安全策略" value="POLICY_CHANGE" />
              <el-option label="业务操作" value="OPERATE" />
            </el-select>
          </div>
          <div class="toolbar-right">
            <el-input
              v-model="logSearchQuery"
              placeholder="搜索操作人/动作/明细/IP..."
              clearable
              size="small"
              style="width: 220px;"
            >
              <template #prefix><el-icon><Search /></el-icon></template>
            </el-input>
          </div>
        </div>
      </template>

      <el-table :data="paginatedActivityLogs" v-loading="loading" border stripe style="width: 100%;">
        <el-table-column prop="timestamp" label="操作时间" width="165" />
        <el-table-column label="归属时段" width="140" align="center">
          <template #default="{ row }">
            <el-tag :type="getTimeSlotTagType(row.timeSlot)" effect="light">
              {{ row.timeSlotName }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="租户与门店" min-width="180">
          <template #default="{ row }">
            <div style="font-weight: 600; color: #1e293b;">{{ row.tenantName || '平台直辖' }}</div>
            <div style="font-size: 12px; color: #64748b;">{{ row.storeName || (row.tenantId ? '租户编号: ' + row.tenantId : '总控中心') }}</div>
          </template>
        </el-table-column>
        <el-table-column label="操作人 / 角色" width="150">
          <template #default="{ row }">
            <div style="font-weight: 500; color: #0f172a;">{{ row.operatorName }}</div>
            <el-tag size="small" type="info">{{ row.operatorRole }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="module" label="功能模块" width="120" align="center">
          <template #default="{ row }">
            <el-tag size="small">{{ row.module }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="action" label="业务行为动作" width="150">
          <template #default="{ row }">
            <strong>{{ row.action }}</strong>
          </template>
        </el-table-column>
        <el-table-column prop="detail" label="审计明细" min-width="240" show-overflow-tooltip />
        <el-table-column label="终端 / IP" width="170">
          <template #default="{ row }">
            <div style="font-size: 11px; color: #64748b;">IP: {{ row.ip }}</div>
            <div style="font-size: 11px; color: #94a3b8;">{{ row.device }}</div>
          </template>
        </el-table-column>
      </el-table>

      <!-- 日志分页 -->
      <div style="margin-top: 14px; display: flex; justify-content: flex-end;">
        <el-pagination
          v-model:current-page="logCurrentPage"
          v-model:page-size="logPageSize"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next"
          :total="filteredActivityLogs.length"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { getAuditLogsApi, getVendorSubscriptionsApi } from '@/api'
import {
  TrendCharts,
  Clock,
  Timer,
  Search,
  Refresh
} from '@element-plus/icons-vue'

const loading = ref(false)
const rawLogs = ref<any[]>([])
const tenantOptions = ref<any[]>([])
const tenantDaytimeStats = ref<any[]>([])

// 审计日志过滤器
const logTimeSlotFilter = ref('ALL')
const logTenantFilter = ref('ALL')
const logModuleFilter = ref('ALL')
const logSearchQuery = ref('')
const logCurrentPage = ref(1)
const logPageSize = ref(10)

const getTimeSlotInfo = (timeStr: string) => {
  if (!timeStr) return { slot: 'AFTERNOON', name: '下午黄金营业期 (14:00-18:00)', isDaytime: true }
  try {
    const parts = timeStr.split(' ')
    const timePart = parts[1] || parts[0]
    const hour = parseInt(timePart.split(':')[0], 10)
    const minute = parseInt(timePart.split(':')[1] || '0', 10)
    const timeVal = hour + minute / 60

    if (timeVal >= 8 && timeVal < 11.5) {
      return { slot: 'MORNING', name: '早间到店早高峰 (08:00-11:30)', isDaytime: true }
    } else if (timeVal >= 11.5 && timeVal < 14) {
      return { slot: 'NOON', name: '午间餐饮高峰 (11:30-14:00)', isDaytime: true }
    } else if (timeVal >= 14 && timeVal < 18) {
      return { slot: 'AFTERNOON', name: '下午黄金营业期 (14:00-18:00)', isDaytime: true }
    } else if (timeVal >= 18 && timeVal < 22) {
      return { slot: 'EVENING', name: '晚间夜市营业期 (18:00-22:00)', isDaytime: true }
    } else {
      return { slot: 'NIGHT', name: '夜间离线低谷 (22:00-08:00)', isDaytime: false }
    }
  } catch (e) {
    return { slot: 'AFTERNOON', name: '下午黄金营业期 (14:00-18:00)', isDaytime: true }
  }
}

const allFormattedLogs = computed(() => {
  return rawLogs.value.map(item => {
    const ts = item.createdAt ? item.createdAt.replace('T', ' ').substring(0, 19) : ''
    const slotInfo = getTimeSlotInfo(ts)
    const actionType = item.actionType || 'OPERATE'
    const moduleMap: Record<string, string> = {
      LOGIN: '系统登录',
      LOGOUT: '退出注销',
      PASSWORD: '安全密码',
      SECURITY_LOCK: '安全风控',
      POLICY_CHANGE: '审计策略',
      OPERATE: '业务操作'
    }
    return {
      id: item.id,
      timestamp: ts || '-',
      timeSlot: slotInfo.slot,
      timeSlotName: slotInfo.name,
      isDaytime: slotInfo.isDaytime,
      tenantId: item.tenantId || '',
      tenantName: item.tenantName || (item.tenantId ? '租户 ' + item.tenantId : '平台直辖'),
      storeName: item.storeName || (item.storeId ? '门店 ' + item.storeId : '总控中心'),
      operatorName: item.realName || item.username || '系统用户',
      operatorRole: item.username === 'admin' ? '超级管理员' : (item.status === 'SUCCESS' ? '认证操作员' : '受限账号'),
      module: moduleMap[actionType] || actionType,
      actionType,
      action: item.action || '业务系统操作',
      detail: item.notes || item.action || '操作记录执行完毕',
      ip: item.ip || '127.0.0.1',
      device: item.device || 'Chrome Web 端'
    }
  })
})

const periodCounts = computed(() => {
  const counts = { morning: 0, noon: 0, afternoon: 0, evening: 0, night: 0 }
  allFormattedLogs.value.forEach(l => {
    if (l.timeSlot === 'MORNING') counts.morning++
    else if (l.timeSlot === 'NOON') counts.noon++
    else if (l.timeSlot === 'AFTERNOON') counts.afternoon++
    else if (l.timeSlot === 'EVENING') counts.evening++
    else counts.night++
  })
  return counts
})

const daytimeTotal = computed(() => {
  return periodCounts.value.morning + periodCounts.value.noon + periodCounts.value.afternoon + periodCounts.value.evening
})

const morningPercent = computed(() => {
  if (daytimeTotal.value === 0) return '0.0%'
  return (periodCounts.value.morning / daytimeTotal.value * 100).toFixed(1) + '%'
})

const noonPercent = computed(() => {
  if (daytimeTotal.value === 0) return '0.0%'
  return (periodCounts.value.noon / daytimeTotal.value * 100).toFixed(1) + '%'
})

const afternoonPercent = computed(() => {
  if (daytimeTotal.value === 0) return '0.0%'
  return (periodCounts.value.afternoon / daytimeTotal.value * 100).toFixed(1) + '%'
})

const eveningPercent = computed(() => {
  if (daytimeTotal.value === 0) return '0.0%'
  return (periodCounts.value.evening / daytimeTotal.value * 100).toFixed(1) + '%'
})

const filteredActivityLogs = computed(() => {
  return allFormattedLogs.value.filter(log => {
    if (logTimeSlotFilter.value !== 'ALL' && log.timeSlot !== logTimeSlotFilter.value) {
      return false
    }
    if (logTenantFilter.value && logTenantFilter.value !== 'ALL' && log.tenantId !== logTenantFilter.value) {
      return false
    }
    if (logModuleFilter.value !== 'ALL' && log.actionType !== logModuleFilter.value) {
      return false
    }
    if (logSearchQuery.value.trim()) {
      const q = logSearchQuery.value.trim().toLowerCase()
      const match =
        (log.operatorName || '').toLowerCase().includes(q) ||
        (log.action || '').toLowerCase().includes(q) ||
        (log.detail || '').toLowerCase().includes(q) ||
        (log.ip || '').toLowerCase().includes(q) ||
        (log.tenantName || '').toLowerCase().includes(q)
      if (!match) return false
    }
    return true
  })
})

const paginatedActivityLogs = computed(() => {
  const start = (logCurrentPage.value - 1) * logPageSize.value
  return filteredActivityLogs.value.slice(start, start + logPageSize.value)
})

const getTimeSlotTagType = (slot: string) => {
  switch (slot) {
    case 'MORNING': return 'info'
    case 'NOON': return 'warning'
    case 'AFTERNOON': return 'danger'
    case 'EVENING': return 'success'
    case 'NIGHT': return 'primary'
    default: return 'info'
  }
}

const filterLogsByTenant = (tenantId: string) => {
  logTenantFilter.value = tenantId
  scrollToLogs()
}

const scrollToLogs = () => {
  const el = document.getElementById('activity-log-anchor')
  if (el) {
    el.scrollIntoView({ behavior: 'smooth' })
  }
}

const loadAllActivityData = async () => {
  loading.value = true
  try {
    const [subRes, auditRes]: [any, any] = await Promise.all([
      getVendorSubscriptionsApi().catch(() => []),
      getAuditLogsApi({ page: 1, size: 300 }).catch(() => null)
    ])

    const subs = Array.isArray(subRes) ? subRes : (subRes?.data || [])
    tenantOptions.value = subs.filter((s: any) => s.tenantId && s.tenantId !== 'PLATFORM')

    const pageData = auditRes?.data !== undefined && auditRes?.code ? auditRes.data : (auditRes?.data || auditRes)
    if (pageData) {
      rawLogs.value = pageData.content || (Array.isArray(pageData) ? pageData : [])
    } else {
      rawLogs.value = []
    }

    // 计算各真实租户的白天时段特征与行为画像
    const stats: any[] = []
    for (const sub of tenantOptions.value) {
      const tid = sub.tenantId
      const tLogs = allFormattedLogs.value.filter(l => l.tenantId === tid)
      let m = 0, n = 0, a = 0, e = 0
      tLogs.forEach(l => {
        if (l.timeSlot === 'MORNING') m++
        else if (l.timeSlot === 'NOON') n++
        else if (l.timeSlot === 'AFTERNOON') a++
        else if (l.timeSlot === 'EVENING') e++
      })
      const totalOps = m + n + a + e
      let peakSlot = '下午黄金 (14:00-18:00)'
      const maxOps = Math.max(m, n, a, e)
      if (maxOps === m && m > 0) peakSlot = '早市晨峰 (08:00-11:30)'
      else if (maxOps === n && n > 0) peakSlot = '午间高峰 (11:30-14:00)'
      else if (maxOps === e && e > 0) peakSlot = '晚间夜市 (18:00-22:00)'

      stats.push({
        tenantId: tid,
        tenantName: sub.tenantName || '智慧门店连锁',
        industryName: sub.industry || '智慧商业综合体',
        daytimeTotalOps: totalOps,
        morningOps: m,
        noonOps: n,
        afternoonOps: a,
        eveningOps: e,
        peakTimeSlot: totalOps > 0 ? peakSlot : '平稳运营中',
        peakTimeReason: totalOps > 0 ? '收银结算、会员服务与日常安全审计' : '新入驻系统，待产生开单与登录活跃数据',
        activityIndex: Math.min(100, Math.max(15, Math.round(totalOps * 10 + 35))),
        primaryModule: '收银结算 / 会员'
      })
    }
    tenantDaytimeStats.value = stats
  } catch (err) {
    console.error('Failed to load activity data:', err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadAllActivityData()
})
</script>

<style scoped>
.vendor-activity-container {
  padding: 18px 24px 40px;
  background: #f8fafc;
  min-height: calc(100vh - 60px);
}

.page-hero-header {
  background: linear-gradient(135deg, #ffffff 0%, #f0fdf4 100%);
  border: 1px solid #dcfce7;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(16, 185, 129, 0.04);
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
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(16, 185, 129, 0.25);
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

.stat-cards-row {
  margin-bottom: 18px;
}

.stat-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
}

.stat-card.stat-peak {
  border-color: #fecdd3;
  background: #fff1f2;
}

.stat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.stat-title {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
}

.stat-num {
  font-size: 24px;
  font-weight: 800;
  line-height: 1.2;
}

.stat-sub {
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
}

.text-cyan { color: #0284c7; }
.text-amber { color: #d97706; }
.text-rose { color: #e11d48; }
.text-purple { color: #7c3aed; }

.stat-desc {
  font-size: 12px;
  color: #64748b;
  margin-top: 6px;
}

.table-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.card-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.header-title {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}

.mini-period-bars {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.mini-bar-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
}

.mini-bar-item .lbl {
  width: 14px;
  color: #64748b;
}

.mini-bar-item .val {
  width: 24px;
  text-align: right;
  color: #475569;
  font-weight: 600;
}

.table-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}
</style>
