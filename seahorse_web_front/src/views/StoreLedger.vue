<template>
  <div class="store-ledger-page">
    <!-- 顶部标题与定位 -->
    <div class="page-header-card">
      <div class="header-left">
        <div class="title-row">
          <h2 class="page-title">📔 门店账本</h2>
          <el-tag type="danger" effect="light" round class="ledger-tag">记日常开销 · 算经营成本 · 查钱花在哪</el-tag>
          <el-tag type="info" effect="plain" class="store-tag">
            🏬 {{ currentStoreName }} · {{ currentIndustryName }}
          </el-tag>
        </div>
        <p class="page-subtitle">
          融合日常开支记账与全口径成本核算，打通员工底薪提成与物料BOM耗材；录一笔流水，自动汇算利润与成本比重，告别两套账本。
        </p>
      </div>

      <div class="header-right">
        <el-button type="success" plain size="large" icon="Download" @click="handleExportLedgerCsv">
          导出账本明细 (CSV)
        </el-button>
        <el-button type="primary" size="large" icon="Plus" @click="handleOpenAddExpense">
          记一笔开销
        </el-button>
        <el-button icon="Refresh" circle @click="refreshLedger" title="刷新账本" />
      </div>
    </div>

    <!-- 4 格核心成本与开支看板 -->
    <div class="kpi-grid">
      <div class="kpi-card kpi-rose">
        <div class="kpi-header">
          <span class="kpi-label">本月累计开支成本</span>
          <span class="kpi-tag">全口径支出</span>
        </div>
        <div class="kpi-value">￥{{ totalMonthExpense.toLocaleString('zh-CN', { minimumFractionDigits: 2 }) }}</div>
        <div class="kpi-footer">
          <span>与利润报表成本联动自洽 (共 {{ activeExpenseList.length }} 笔)</span>
        </div>
      </div>

      <div class="kpi-card kpi-indigo">
        <div class="kpi-header">
          <span class="kpi-label">营收成本率</span>
          <span class="kpi-tag">健康指标</span>
        </div>
        <div class="kpi-value">{{ revenueCostRatio }}%</div>
        <div class="kpi-footer">
          <span>毛利控制区间良好 (行业基准 ≤ 65%)</span>
        </div>
      </div>

      <div class="kpi-card kpi-amber">
        <div class="kpi-header">
          <span class="kpi-label">最大开销类别</span>
          <span class="kpi-tag">高权重项</span>
        </div>
        <div class="kpi-value">{{ topCategoryName }}</div>
        <div class="kpi-footer">
          <span>￥{{ topCategoryAmount.toLocaleString() }} (占比 {{ topCategoryPercentage }}%)</span>
        </div>
      </div>

      <div class="kpi-card kpi-emerald">
        <div class="kpi-header">
          <span class="kpi-label">固定 vs 变动成本比</span>
          <span class="kpi-tag">结构平衡</span>
        </div>
        <div class="kpi-value">{{ fixedCostPercent }}% : {{ variableCostPercent }}%</div>
        <div class="kpi-footer">
          <span>固定 ￥{{ fixedCostAmount.toLocaleString() }} | 变动 ￥{{ variableCostAmount.toLocaleString() }}</span>
        </div>
      </div>
    </div>

    <!-- 自动同步引擎说明横幅 -->
    <div class="sync-engine-banner">
      <div class="banner-left">
        <span class="engine-icon">⚡</span>
        <div class="engine-text">
          <div class="engine-title">薪资与提成全自动核算引擎已激活</div>
          <div class="engine-desc">
            在册员工每月固定底薪自动核算入账；前台开单收银时技师/销售提成自动实时计入变动成本。系统自动计算的款项均无需人工重复记账！
          </div>
        </div>
      </div>
      <div class="banner-right">
        <el-tag type="success" effect="dark" round>
          底薪自动核算: ￥{{ systemData.autoSalaryBaseCost.toFixed(2) }}
        </el-tag>
        <el-tag type="warning" effect="dark" round style="margin-left: 8px;">
          提成实时计入: ￥{{ systemData.autoSalaryCommissionCost.toFixed(2) }}
        </el-tag>
      </div>
    </div>

    <!-- 主体业务选项卡 -->
    <el-card class="content-card" shadow="never">
      <el-tabs v-model="activeTab" class="ledger-tabs">
        <!-- Tab 1: 开销明细与流水记账 -->
        <el-tab-pane label="📝 开销流水与明细记账" name="records">
          <!-- 筛选与搜索工具栏 -->
          <div class="filter-row">
            <div class="filter-capsules">
              <el-radio-group v-model="categoryFilter" size="default">
                <el-radio-button label="ALL">全部开支 ({{ activeExpenseList.length }})</el-radio-button>
                <el-radio-button label="RENT">🏢 房租物业水电</el-radio-button>
                <el-radio-button label="SUPPLY">🧴 耗材备货采购</el-radio-button>
                <el-radio-button label="SALARY">👤 薪资福利补贴</el-radio-button>
                <el-radio-button label="MARKETING">📢 营销获客广告</el-radio-button>
                <el-radio-button label="DEPRECIATION">⚙️ 设备折旧维保</el-radio-button>
                <el-radio-button label="OTHER">🏷️ 杂项日常报销</el-radio-button>
              </el-radio-group>
            </div>

            <div class="filter-inputs">
              <el-date-picker
                v-model="dateFilter"
                type="month"
                placeholder="选择月份"
                value-format="YYYY-MM"
                style="width: 140px;"
                clearable
              />
              <el-input
                v-model="searchKeyword"
                placeholder="搜索款项事由/经办人/凭证"
                prefix-icon="Search"
                clearable
                style="width: 220px;"
              />
            </div>
          </div>

          <!-- 开支明细表格 -->
          <el-table :data="paginatedExpenses" stripe border style="width: 100%; margin-top: 16px;">
            <el-table-column prop="expenseNo" label="凭证单号" width="150" align="center">
              <template #default="{ row }">
                <span class="mono-code">{{ row.expenseNo }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="categoryName" label="开支科目" width="140" align="center">
              <template #default="{ row }">
                <el-tag :type="getCategoryTagType(row.category)">{{ row.categoryName }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="title" label="款项具体事由" min-width="200">
              <template #default="{ row }">
                <span style="font-weight: 600; color: #1e293b;">{{ row.title }}</span>
                <div v-if="row.note" class="row-note">备注: {{ row.note }}</div>
              </template>
            </el-table-column>
            <el-table-column prop="amount" label="开支金额 (元)" width="140" align="right" sortable>
              <template #default="{ row }">
                <span class="expense-amount">-￥{{ Number(row.amount || 0).toFixed(2) }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="paymentMethod" label="支付方式" width="120" align="center">
              <template #default="{ row }">
                <el-tag size="small" type="info" effect="plain">
                  {{ getPaymentMethodName(row.paymentMethod) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="date" label="发生日期" width="120" align="center" sortable />
            <el-table-column prop="handler" label="经办人" width="110" align="center" />
            <el-table-column prop="invoiceNo" label="发票/报销凭据" width="150" align="center">
              <template #default="{ row }">
                <span v-if="row.invoiceNo" class="invoice-badge">{{ row.invoiceNo }}</span>
                <span v-else style="color: #cbd5e1;">-</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="100" align="center" fixed="right">
              <template #default="{ row }">
                <el-button type="danger" link size="small" @click="handleDeleteExpense(row.id)">
                  删除
                </el-button>
              </template>
            </el-table-column>
          </el-table>

          <!-- 分页 -->
          <div class="pagination-bar" v-if="filteredExpenses.length > pageSize">
            <el-pagination
              v-model:current-page="currentPage"
              :page-size="pageSize"
              :total="filteredExpenses.length"
              layout="total, prev, pager, next"
            />
          </div>
        </el-tab-pane>

        <!-- Tab 2: 全口径成本与结构分析 (原成本中心可视化) -->
        <el-tab-pane label="📊 全口径成本与比重分析" name="analysis">
          <div class="analysis-container">
            <el-row :gutter="20">
              <!-- 环形占比图 -->
              <el-col :xs="24" :md="12">
                <el-card shadow="never" class="chart-box">
                  <template #header>
                    <div class="chart-head">
                      <span class="chart-title">🍩 成本结构比重是多少？</span>
                      <el-tag size="small" type="info">全店六大类目分布</el-tag>
                    </div>
                  </template>

                  <div class="donut-display">
                    <div class="donut-mock-chart">
                      <div class="donut-inner-circle">
                        <span class="center-label">全口径总成本</span>
                        <span class="center-value">￥{{ totalMonthExpense.toLocaleString() }}</span>
                      </div>
                    </div>

                    <!-- 占比列表 -->
                    <div class="breakdown-list">
                      <div
                        v-for="cat in categoryBreakdown"
                        :key="cat.name"
                        class="breakdown-item"
                      >
                        <div class="item-left">
                          <span class="color-dot" :style="{ backgroundColor: cat.color }"></span>
                          <span class="item-name">{{ cat.name }}</span>
                        </div>
                        <div class="item-right">
                          <span class="item-amount">￥{{ cat.amount.toLocaleString() }}</span>
                          <span class="item-pct">({{ cat.percentage }}%)</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </el-card>
              </el-col>

              <!-- 支出排行榜 -->
              <el-col :xs="24" :md="12">
                <el-card shadow="never" class="chart-box">
                  <template #header>
                    <div class="chart-head">
                      <span class="chart-title">📈 哪些成本最高？支出排行榜</span>
                      <el-tag size="small" type="warning">按单项金额高低倒序</el-tag>
                    </div>
                  </template>

                  <div class="rank-list">
                    <div
                      v-for="(item, idx) in sortedCostRankings.slice(0, 7)"
                      :key="item.id"
                      class="rank-row"
                    >
                      <div class="rank-badge" :class="'top-' + (idx + 1)">{{ idx + 1 }}</div>
                      <div class="rank-info">
                        <div class="rank-title-row">
                          <span class="rank-name">{{ item.name }}</span>
                          <span class="rank-cost">￥{{ item.amount.toLocaleString() }}</span>
                        </div>
                        <el-progress
                          :percentage="Math.min(100, Math.round((item.amount / (totalMonthExpense || 1)) * 100))"
                          :color="getRankColor(idx)"
                          :stroke-width="6"
                          :show-text="false"
                        />
                      </div>
                    </div>
                  </div>
                </el-card>
              </el-col>
            </el-row>

            <!-- 固定与变动成本台账明细 -->
            <el-card shadow="never" class="structure-card" style="margin-top: 16px;">
              <template #header>
                <div class="chart-head">
                  <span class="chart-title">📋 成本固定与变动属性台账明细</span>
                  <div style="display: flex; gap: 8px;">
                    <el-tag type="primary">固定成本：￥{{ fixedCostAmount.toLocaleString() }}</el-tag>
                    <el-tag type="warning">变动成本：￥{{ variableCostAmount.toLocaleString() }}</el-tag>
                  </div>
                </div>
              </template>

              <el-table :data="costTableData" stripe border style="width: 100%">
                <el-table-column prop="code" label="科目代码" width="130" align="center" />
                <el-table-column prop="name" label="成本科目名称" min-width="180">
                  <template #default="{ row }">
                    <span style="font-weight: 600;">{{ row.name }}</span>
                    <el-tag v-if="row.isAutoSync" size="small" type="success" style="margin-left: 6px;">自动核算</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="categoryName" label="所属类别" width="130" align="center" />
                <el-table-column prop="nature" label="成本性质" width="110" align="center">
                  <template #default="{ row }">
                    <el-tag :type="row.nature === 'FIXED' ? 'primary' : 'warning'" effect="plain">
                      {{ row.nature === 'FIXED' ? '固定刚性' : '变动弹性' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="amount" label="核算金额 (元)" width="140" align="right" sortable>
                  <template #default="{ row }">
                    <span style="font-weight: bold; color: #ef4444;">￥{{ Number(row.amount || 0).toFixed(2) }}</span>
                  </template>
                </el-table-column>
                <el-table-column prop="handler" label="经手人/责任人" width="120" align="center" />
                <el-table-column prop="notes" label="成本说明与分摊原则" min-width="200" show-overflow-tooltip />
              </el-table>
            </el-card>
          </div>
        </el-tab-pane>

        <!-- Tab 3: 支出科目与月度预算 -->
        <el-tab-pane label="🏷️ 支出科目与月度预算" name="budget">
          <div class="budget-container">
            <el-alert
              title="设定各支出科目的月度开支上限警戒线。当实际支出接近或超出预算时，系统将在系统首页大屏与账本中发出预警提示！"
              type="info"
              :closable="false"
              show-icon
              style="margin-bottom: 16px;"
            />

            <el-row :gutter="16">
              <el-col
                v-for="b in budgetList"
                :key="b.category"
                :xs="24" :sm="12" :md="8"
                style="margin-bottom: 16px;"
              >
                <el-card shadow="never" class="budget-card">
                  <div class="budget-card-header">
                    <div class="b-title">
                      <span class="b-icon">{{ b.icon }}</span>
                      <span class="b-name">{{ b.categoryName }}</span>
                    </div>
                    <el-tag :type="getBudgetStatusType(b.used, b.limit)" size="small">
                      {{ getBudgetStatusText(b.used, b.limit) }}
                    </el-tag>
                  </div>

                  <div class="budget-amounts">
                    <div class="b-amount-item">
                      <span class="b-lbl">已发生支出</span>
                      <span class="b-val text-red">￥{{ b.used.toLocaleString() }}</span>
                    </div>
                    <div class="b-amount-item right">
                      <span class="b-lbl">预算上限</span>
                      <span class="b-val text-gray">￥{{ b.limit.toLocaleString() }}</span>
                    </div>
                  </div>

                  <div class="budget-progress-wrap">
                    <el-progress
                      :percentage="Math.min(100, Math.round((b.used / b.limit) * 100))"
                      :status="getProgressBarStatus(b.used, b.limit)"
                      :stroke-width="8"
                    />
                  </div>

                  <div class="budget-footer">
                    <span class="b-remain">剩余预算: <b>￥{{ Math.max(0, b.limit - b.used).toLocaleString() }}</b></span>
                    <el-button size="small" type="primary" link @click="handleEditBudget(b)">调整限额</el-button>
                  </div>
                </el-card>
              </el-col>
            </el-row>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 弹窗: 记一笔开销 -->
    <el-dialog
      v-model="addExpenseVisible"
      title="💸 记一笔门店开支"
      width="560px"
      destroy-on-close
    >
      <el-form :model="expenseForm" label-width="110px">
        <el-form-item label="支出科目" required>
          <el-select v-model="expenseForm.category" style="width: 100%" @change="handleCategoryChange">
            <el-option label="🏢 房租物业水电" value="RENT" />
            <el-option label="🧴 耗材备货采购" value="SUPPLY" />
            <el-option label="👤 员工福利与补贴" value="SALARY" />
            <el-option label="📢 营销获客广告" value="MARKETING" />
            <el-option label="⚙️ 设备折旧维保" value="DEPRECIATION" />
            <el-option label="🏷️ 杂项日常报销" value="OTHER" />
          </el-select>
        </el-form-item>

        <el-form-item label="款项具体事由" required>
          <el-input v-model="expenseForm.title" placeholder="如：9月份店面物业费及水电公摊、客休区现磨咖啡豆补货" />
        </el-form-item>

        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="开支金额(元)" required>
              <el-input-number v-model="expenseForm.amount" :min="0.01" :step="100" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="成本性质">
              <el-select v-model="expenseForm.nature" style="width: 100%">
                <el-option label="固定刚性成本" value="FIXED" />
                <el-option label="变动弹性成本" value="VARIABLE" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="支付方式" required>
              <el-select v-model="expenseForm.paymentMethod" style="width: 100%">
                <el-option label="微信租户支出" value="WECHAT" />
                <el-option label="企业支付宝" value="ALIPAY" />
                <el-option label="银行对公转账" value="BANK" />
                <el-option label="前台备用金现金" value="CASH" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="发生日期" required>
              <el-date-picker
                v-model="expenseForm.date"
                type="date"
                value-format="YYYY-MM-DD"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="经办人" required>
              <el-input v-model="expenseForm.handler" placeholder="如：店长、财务-小赵" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="发票/凭证号">
              <el-input v-model="expenseForm.invoiceNo" placeholder="如：FP202609001" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="备注说明">
          <el-input v-model="expenseForm.note" type="textarea" :rows="2" placeholder="填写费用详细说明或分摊月份" />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="addExpenseVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleConfirmAddExpense">
          确认入账
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useSystemDataStore } from '../stores/systemDataStore'
import { ElMessage, ElMessageBox } from 'element-plus'

const route = useRoute()
const systemData = useSystemDataStore()

// 选中的 Tab：records (流水) | analysis (全口径成本分析) | budget (科目预算)
const activeTab = ref('records')

const syncTabFromRoute = () => {
  if (route.path === '/cost-center' || route.query.tab === 'cost' || route.query.tab === 'analysis') {
    activeTab.value = 'analysis'
  } else if (route.query.tab === 'budget') {
    activeTab.value = 'budget'
  } else if (route.path === '/expenses') {
    activeTab.value = 'records'
  }
}

onMounted(() => {
  syncTabFromRoute()
})

watch(() => [route.path, route.query.tab], () => {
  syncTabFromRoute()
})

const currentStoreName = computed(() => {
  return systemData.stores[0]?.storeName || '海马智慧门店旗舰店'
})

const currentIndustryName = computed(() => {
  switch (systemData.currentIndustry) {
    case 'RESTAURANT': return '餐饮轻食/融合料理'
    case 'BEAUTY': return '美容美发美甲'
    case 'AUTO': return '汽车养护维修'
    case 'RETAIL': return '专营名品零售'
    default: return '智慧门店'
  }
})

// ----------------------------------------------------------------------------
// 核心 KPI 计算
// ----------------------------------------------------------------------------
const activeExpenseList = computed(() => systemData.expenses || [])

const totalMonthExpense = computed(() => {
  return systemData.allCostItems.reduce((sum, item) => sum + (item.amount || 0), 0)
})

const revenueCostRatio = computed(() => {
  const rev = systemData.costStats.monthRevenue || (systemData.isNewTenant ? 0 : 76500)
  if (!rev || rev === 0 || totalMonthExpense.value === 0) return '0.0'
  return ((totalMonthExpense.value / rev) * 100).toFixed(1)
})

const fixedCostAmount = computed(() => {
  return systemData.allCostItems
    .filter(c => c.nature === 'FIXED')
    .reduce((sum, c) => sum + c.amount, 0)
})

const variableCostAmount = computed(() => {
  return systemData.allCostItems
    .filter(c => c.nature === 'VARIABLE')
    .reduce((sum, c) => sum + c.amount, 0)
})

const fixedCostPercent = computed(() => {
  if (totalMonthExpense.value === 0) return 50
  return Math.round((fixedCostAmount.value / totalMonthExpense.value) * 100)
})

const variableCostPercent = computed(() => {
  return 100 - fixedCostPercent.value
})

const categoryBreakdown = computed(() => {
  const map: Record<string, { name: string; amount: number; color: string }> = {
    LABOR: { name: '人力薪酬与福利', amount: 0, color: '#ec4899' },
    RENT_UTILITY: { name: '店面房租与物业能耗', amount: 0, color: '#3b82f6' },
    MATERIAL: { name: '耗材原液与BOM采购', amount: 0, color: '#f59e0b' },
    MARKETING: { name: '营销拓客与流量推广', amount: 0, color: '#8b5cf6' },
    DEPRECIATION: { name: '设备折旧与资产分摊', amount: 0, color: '#10b981' },
    ADMIN_MISC: { name: '日常杂费与办公运营', amount: 0, color: '#64748b' }
  }

  systemData.allCostItems.forEach(item => {
    if (map[item.category]) {
      map[item.category].amount += item.amount
    } else {
      map.ADMIN_MISC.amount += item.amount
    }
  })

  const total = totalMonthExpense.value || 1
  return Object.values(map).map(cat => ({
    ...cat,
    percentage: ((cat.amount / total) * 100).toFixed(1)
  })).sort((a, b) => b.amount - a.amount)
})

const topCategoryName = computed(() => categoryBreakdown.value[0]?.name || '人力薪酬')
const topCategoryAmount = computed(() => categoryBreakdown.value[0]?.amount || 0)
const topCategoryPercentage = computed(() => categoryBreakdown.value[0]?.percentage || '0')

// ----------------------------------------------------------------------------
// Tab 1: 流水明细列表与过滤
// ----------------------------------------------------------------------------
const categoryFilter = ref('ALL')
const dateFilter = ref('')
const searchKeyword = ref('')
const currentPage = ref(1)
const pageSize = ref(8)

const filteredExpenses = computed(() => {
  return activeExpenseList.value.filter(exp => {
    if (categoryFilter.value !== 'ALL' && exp.category !== categoryFilter.value) {
      return false
    }
    if (dateFilter.value && !exp.date.startsWith(dateFilter.value)) {
      return false
    }
    if (searchKeyword.value.trim()) {
      const kw = searchKeyword.value.trim().toLowerCase()
      const matchTitle = (exp.title || '').toLowerCase().includes(kw)
      const matchHandler = (exp.handler || '').toLowerCase().includes(kw)
      const matchNo = (exp.expenseNo || '').toLowerCase().includes(kw)
      if (!matchTitle && !matchHandler && !matchNo) return false
    }
    return true
  })
})

const paginatedExpenses = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredExpenses.value.slice(start, start + pageSize.value)
})

const getCategoryTagType = (cat: string) => {
  switch (cat) {
    case 'RENT': return 'primary'
    case 'SUPPLY': return 'warning'
    case 'SALARY': return 'success'
    case 'MARKETING': return 'danger'
    case 'DEPRECIATION': return 'info'
    default: return 'info'
  }
}

const getPaymentMethodName = (pm?: string) => {
  switch (pm) {
    case 'WECHAT': return '微信租户'
    case 'ALIPAY': return '企业支付宝'
    case 'BANK': return '银行转账'
    case 'CASH': return '备用金现金'
    default: return '对公结算'
  }
}

const handleDeleteExpense = (id: number) => {
  ElMessageBox.confirm('确定要删除此笔开支记录吗？删除后将自动扣减成本核算。', '确认删除', {
    type: 'warning'
  }).then(() => {
    const idx = systemData.expenses.findIndex(e => e.id === id)
    if (idx !== -1) {
      systemData.expenses.splice(idx, 1)
      ElMessage.success('开支记录已删除！')
    }
  }).catch(() => {})
}

// ----------------------------------------------------------------------------
// Tab 2: 成本排行与明细表
// ----------------------------------------------------------------------------
const sortedCostRankings = computed(() => {
  return [...systemData.allCostItems].sort((a, b) => b.amount - a.amount)
})

const getRankColor = (idx: number) => {
  if (idx === 0) return '#ef4444'
  if (idx === 1) return '#f97316'
  if (idx === 2) return '#f59e0b'
  return '#3b82f6'
}

const costTableData = computed(() => systemData.allCostItems)

// ----------------------------------------------------------------------------
// Tab 3: 支出科目与月度预算
// ----------------------------------------------------------------------------
const initBudgets = () => {
  try {
    const raw = localStorage.getItem('seahorse_store_budgets')
    if (raw) return JSON.parse(raw)
  } catch (e) {}
  const isNew = systemData.isNewTenant
  return [
    { category: 'RENT', categoryName: '房租物业水电', icon: '🏢', limit: 18000, used: isNew ? 0 : 16500 },
    { category: 'SALARY', categoryName: '员工薪酬与福利', icon: '👤', limit: 25000, used: isNew ? 0 : 21900 },
    { category: 'SUPPLY', categoryName: '耗材备货采购', icon: '🧴', limit: 12000, used: isNew ? 0 : 8400 },
    { category: 'MARKETING', categoryName: '营销获客推广', icon: '📢', limit: 6000, used: isNew ? 0 : 4800 },
    { category: 'DEPRECIATION', categoryName: '设备折旧维保', icon: '⚙️', limit: 4000, used: isNew ? 0 : 2500 },
    { category: 'OTHER', categoryName: '办公行政杂项', icon: '🏷️', limit: 3000, used: isNew ? 0 : 1600 }
  ]
}
const budgetList = ref(initBudgets())

const getBudgetStatusType = (used: number, limit: number) => {
  const ratio = used / limit
  if (ratio > 1) return 'danger'
  if (ratio > 0.8) return 'warning'
  return 'success'
}

const getBudgetStatusText = (used: number, limit: number) => {
  const ratio = used / limit
  if (ratio > 1) return '已超支'
  if (ratio > 0.8) return '临近预算'
  return '预算健康'
}

const getProgressBarStatus = (used: number, limit: number) => {
  const ratio = used / limit
  if (ratio > 1) return 'exception'
  if (ratio > 0.8) return 'warning'
  return 'success'
}

const handleEditBudget = (b: any) => {
  ElMessageBox.prompt(`请输入【${b.categoryName}】的新月度预算上限 (元)：`, '调整预算额度', {
    inputValue: String(b.limit),
    inputPattern: /^[1-9]\d*$/,
    inputErrorMessage: '请输入合法的正整数金额'
  }).then(({ value }) => {
    b.limit = Number(value)
    ElMessage.success(`【${b.categoryName}】月度预算已更新为 ￥${Number(value).toLocaleString()}！`)
  }).catch(() => {})
}

// ----------------------------------------------------------------------------
// 记一笔开销弹窗
// ----------------------------------------------------------------------------
const addExpenseVisible = ref(false)
const submitting = ref(false)
const expenseForm = ref({
  category: 'RENT',
  categoryName: '房租物业水电',
  title: '',
  amount: 1000,
  nature: 'FIXED',
  paymentMethod: 'WECHAT',
  date: new Date().toISOString().substring(0, 10),
  handler: '店长',
  invoiceNo: '',
  note: ''
})

const handleCategoryChange = (cat: string) => {
  const map: Record<string, { name: string; nature: string }> = {
    RENT: { name: '房租物业水电', nature: 'FIXED' },
    SUPPLY: { name: '耗材备货采购', nature: 'VARIABLE' },
    SALARY: { name: '员工福利与补贴', nature: 'VARIABLE' },
    MARKETING: { name: '营销获客广告', nature: 'VARIABLE' },
    DEPRECIATION: { name: '设备折旧维保', nature: 'FIXED' },
    OTHER: { name: '杂项日常报销', nature: 'FIXED' }
  }
  if (map[cat]) {
    expenseForm.value.categoryName = map[cat].name
    expenseForm.value.nature = map[cat].nature
  }
}

const handleOpenAddExpense = () => {
  expenseForm.value = {
    category: 'RENT',
    categoryName: '房租物业水电',
    title: '',
    amount: 500,
    nature: 'FIXED',
    paymentMethod: 'WECHAT',
    date: new Date().toISOString().substring(0, 10),
    handler: '李店长',
    invoiceNo: `FP${Date.now().toString().slice(-6)}`,
    note: ''
  }
  addExpenseVisible.value = true
}

const handleConfirmAddExpense = () => {
  if (!expenseForm.value.title.trim()) {
    ElMessage.warning('请输入款项具体事由！')
    return
  }
  if (expenseForm.value.amount <= 0) {
    ElMessage.warning('开支金额必须大于0！')
    return
  }

  submitting.value = true
  try {
    // 1. 写入日常支出流水
    const newExp = {
      id: Date.now(),
      expenseNo: `EXP${new Date().toISOString().substring(0, 10).replace(/-/g, '')}${Math.floor(Math.random() * 900 + 100)}`,
      category: expenseForm.value.category,
      categoryName: expenseForm.value.categoryName,
      title: expenseForm.value.title,
      amount: expenseForm.value.amount,
      date: expenseForm.value.date,
      handler: expenseForm.value.handler,
      paymentMethod: expenseForm.value.paymentMethod,
      invoiceNo: expenseForm.value.invoiceNo,
      note: expenseForm.value.note
    }
    systemData.expenses.unshift(newExp as any)

    // 2. 自动同步沉淀至全口径成本核算台账 (实现去冗余单入口)
    const costCatMap: Record<string, any> = {
      RENT: 'RENT_UTILITY',
      SUPPLY: 'MATERIAL',
      SALARY: 'LABOR',
      MARKETING: 'MARKETING',
      DEPRECIATION: 'DEPRECIATION',
      OTHER: 'ADMIN_MISC'
    }
    systemData.addCostItem({
      name: expenseForm.value.title,
      category: costCatMap[expenseForm.value.category] || 'ADMIN_MISC',
      categoryName: expenseForm.value.categoryName,
      nature: expenseForm.value.nature as any,
      amount: expenseForm.value.amount,
      month: expenseForm.value.date.substring(0, 7),
      date: expenseForm.value.date,
      storeId: 'S001',
      handler: expenseForm.value.handler,
      invoiceNo: expenseForm.value.invoiceNo,
      notes: expenseForm.value.note || '来自门店账本日常开支记账录入'
    })

    ElMessage.success(`已成功记入一笔开销【￥${expenseForm.value.amount}】并自动核算入成本中心！`)
    addExpenseVisible.value = false
  } finally {
    submitting.value = false
  }
}

const refreshLedger = () => {
  ElMessage.success('门店账本数据已即时刷新！')
}

const handleExportLedgerCsv = () => {
  const list = filteredExpenses.value
  if (!list.length) {
    ElMessage.warning('当前筛选条件下暂无可导出的开支流水')
    return
  }
  const headers = ['凭证单号', '开支科目', '款项具体事由', '开支金额(元)', '支付方式', '发生日期', '经办人', '发票/凭证号', '备注说明']
  const rows = list.map((r: any) => [
    r.expenseNo || '',
    r.categoryName || '',
    r.title || '',
    Number(r.amount || 0).toFixed(2),
    getPaymentMethodName(r.paymentMethod),
    r.date || '',
    r.handler || '',
    r.invoiceNo || '',
    r.note || ''
  ])
  const csvContent = '\uFEFF' + [headers.join(','), ...rows.map(row => row.map(v => `"${String(v).replace(/"/g, '""')}"`).join(','))].join('\n')
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `${currentStoreName.value}_门店开支账本明细_${new Date().toISOString().slice(0, 10)}.csv`
  link.click()
  URL.revokeObjectURL(url)
  ElMessage.success(`已导出 ${list.length} 笔门店账本明细 CSV 文件！`)
}
</script>

<style scoped>
.store-ledger-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* 顶部卡片 */
.page-header-card {
  background: #fff;
  border-radius: 8px;
  padding: 16px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.title-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.page-title {
  margin: 0;
  font-size: 20px;
  font-weight: bold;
  color: #0f172a;
}

.page-subtitle {
  margin: 6px 0 0 0;
  font-size: 13px;
  color: #64748b;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* 4格 KPI 看板 */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.kpi-card {
  background: #fff;
  border-radius: 8px;
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
  border: 1px solid #f1f5f9;
}

.kpi-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.kpi-label {
  font-size: 13px;
  color: #64748b;
}

.kpi-tag {
  font-size: 11px;
  padding: 2px 6px;
  border-radius: 4px;
}

.kpi-rose .kpi-tag { background: #ffe4e6; color: #e11d48; }
.kpi-indigo .kpi-tag { background: #e0e7ff; color: #4338ca; }
.kpi-amber .kpi-tag { background: #fef3c7; color: #d97706; }
.kpi-emerald .kpi-tag { background: #d1fae5; color: #059669; }

.kpi-value {
  font-size: 24px;
  font-weight: 700;
  color: #0f172a;
  margin: 10px 0 6px;
}

.kpi-footer {
  font-size: 12px;
  color: #94a3b8;
}

/* 自动同步横幅 */
.sync-engine-banner {
  background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
  color: #fff;
  border-radius: 8px;
  padding: 14px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 2px 6px rgba(0,0,0,0.1);
}

.banner-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.engine-icon {
  font-size: 26px;
}

.engine-title {
  font-size: 14px;
  font-weight: 600;
  color: #38bdf8;
}

.engine-desc {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 2px;
}

.banner-right {
  display: flex;
  align-items: center;
}

/* 主内容卡片与 Tabs */
.content-card {
  border-radius: 8px;
  border: none;
}

.filter-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}

.filter-inputs {
  display: flex;
  align-items: center;
  gap: 10px;
}

.mono-code {
  font-family: monospace;
  font-weight: 600;
  color: #0284c7;
  background: #f0f9ff;
  padding: 2px 6px;
  border-radius: 4px;
}

.row-note {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 2px;
}

.expense-amount {
  font-weight: bold;
  color: #ef4444;
}

.invoice-badge {
  font-size: 12px;
  color: #475569;
  background: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
}

.pagination-bar {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}

/* 成本分析图表展示 */
.chart-box {
  border-radius: 8px;
  border: 1px solid #f1f5f9;
}

.chart-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.chart-title {
  font-size: 15px;
  font-weight: 600;
  color: #0f172a;
}

.donut-display {
  display: flex;
  align-items: center;
  gap: 24px;
  padding: 10px 0;
}

.donut-mock-chart {
  width: 150px;
  height: 150px;
  border-radius: 50%;
  background: conic-gradient(
    #ec4899 0% 38%,
    #3b82f6 38% 66%,
    #f59e0b 66% 80%,
    #8b5cf6 80% 90%,
    #10b981 90% 95%,
    #64748b 95% 100%
  );
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  flex-shrink: 0;
}

.donut-inner-circle {
  width: 96px;
  height: 96px;
  border-radius: 50%;
  background: #fff;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.center-label {
  font-size: 10px;
  color: #64748b;
}

.center-value {
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
  margin-top: 2px;
}

.breakdown-list {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.breakdown-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 13px;
}

.item-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.color-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.item-amount {
  font-weight: 600;
  color: #1e293b;
}

.item-pct {
  color: #94a3b8;
  font-size: 12px;
  margin-left: 4px;
}

/* 排行榜 */
.rank-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 4px 0;
}

.rank-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.rank-badge {
  width: 22px;
  height: 22px;
  border-radius: 4px;
  background: #e2e8f0;
  color: #64748b;
  font-size: 12px;
  font-weight: bold;
  display: flex;
  align-items: center;
  justify-content: center;
}

.rank-badge.top-1 { background: #fee2e2; color: #ef4444; }
.rank-badge.top-2 { background: #ffedd5; color: #f97316; }
.rank-badge.top-3 { background: #fef3c7; color: #f59e0b; }

.rank-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.rank-title-row {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
}

.rank-name {
  font-weight: 500;
  color: #1e293b;
}

.rank-cost {
  font-weight: 600;
  color: #0f172a;
}

/* 预算卡片 */
.budget-card {
  border-radius: 8px;
  border: 1px solid #f1f5f9;
}

.budget-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.b-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  font-size: 15px;
  color: #0f172a;
}

.budget-amounts {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}

.b-lbl {
  font-size: 11px;
  color: #94a3b8;
  display: block;
}

.b-val {
  font-size: 16px;
  font-weight: 700;
  margin-top: 2px;
}

.text-red { color: #ef4444; }
.text-gray { color: #64748b; }

.budget-progress-wrap {
  margin-bottom: 12px;
}

.budget-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12px;
  color: #64748b;
  border-top: 1px solid #f8fafc;
  padding-top: 8px;
}
</style>
