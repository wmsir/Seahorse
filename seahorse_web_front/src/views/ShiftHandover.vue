<template>
  <div class="shift-page">
    <el-row :gutter="16">
      <!-- 左侧：执行交班盲盘录入 -->
      <el-col :xs="24" :md="10">
        <el-card shadow="hover" class="blind-input-card">
          <template #header>
            <div class="card-header">
              <span class="header-title">🔒 收银班次交接 · 现金盲盘录入</span>
              <div style="display: flex; gap: 6px; align-items: center;">
                <el-button size="small" type="primary" plain @click="showDenomCalc = !showDenomCalc">
                  🧮 {{ showDenomCalc ? '收起点钞器' : '展开面额点钞器' }}
                </el-button>
                <el-tag type="danger">盲盘防作弊</el-tag>
              </div>
            </div>
          </template>

          <div class="blind-guidance">
            <el-alert
              title="盲盘规范说明"
              type="info"
              :closable="false"
              description="交班时收银员需先清点钱箱内实际纸币硬币并如实录入（未提交前隐藏系统理论金额），提交后系统即时比对并生成长短款对账凭单。"
              show-icon
            />
          </div>

          <!-- 🧮 纸币/硬币分面额点钞辅助计算器 -->
          <div v-if="showDenomCalc" class="denom-calc-panel">
            <div class="denom-header">
              <span class="denom-title">💴 钱箱面额点钞辅助计算器</span>
              <el-button link type="danger" size="small" @click="resetDenomCounts">清空重数</el-button>
            </div>
            <div class="denom-grid">
              <div v-for="item in denomList" :key="item.value" class="denom-row">
                <span class="denom-badge" :class="'denom-' + item.value">￥{{ item.label }}</span>
                <span class="denom-mul">×</span>
                <el-input-number
                  v-model="item.count"
                  :min="0"
                  :max="9999"
                  :step="1"
                  size="small"
                  controls-position="right"
                  class="denom-input"
                  @change="syncDenomToBlindCash"
                />
                <span class="denom-sub">= ￥{{ (item.value * item.count).toFixed(0) }}</span>
              </div>
            </div>
            <div class="denom-petty-row">
              <span>🪙 硬币与散钞零钱 (元)：</span>
              <el-input-number
                v-model="coinLooseAmount"
                :min="0"
                :precision="2"
                :step="1"
                size="small"
                style="width: 120px;"
                @change="syncDenomToBlindCash"
              />
            </div>
            <div class="denom-petty-row">
              <span>🏦 扣除班前预留备用金 (元)：</span>
              <el-input-number
                v-model="pettyCashFloat"
                :min="0"
                :precision="2"
                :step="50"
                size="small"
                style="width: 120px;"
                @change="syncDenomToBlindCash"
              />
            </div>
            <div class="denom-summary-bar">
              <span>点钞合计: <b>￥{{ rawCountedTotal.toFixed(2) }}</b></span>
              <span>扣除备用金净实收: <b class="text-primary">￥{{ blindCash.toFixed(2) }}</b></span>
            </div>
          </div>

          <el-form label-position="top" style="margin-top: 16px;">
            <el-form-item label="钱箱实数净收现金金额 (盲盘总数)" required>
              <el-input-number
                v-model="blindCash"
                :min="0"
                :precision="2"
                :step="50"
                size="large"
                style="width: 100%;"
              />
            </el-form-item>

            <el-form-item label="快捷交班标签与说明备忘">
              <div class="quick-note-tags">
                <el-tag
                  v-for="tag in quickNoteTemplates"
                  :key="tag"
                  size="small"
                  effect="plain"
                  class="q-note-tag"
                  @click="appendQuickNote(tag)"
                >
                  + {{ tag }}
                </el-tag>
              </div>
              <el-input
                v-model="shiftNotes"
                type="textarea"
                :rows="3"
                placeholder="例如：钱箱备用金预留200元整，已盘点交接给晚班小刘"
              />
            </el-form-item>

            <el-button
              type="primary"
              size="large"
              style="width: 100%; margin-top: 8px;"
              :loading="submitting"
              @click="handleSubmitBlindShift"
            >
              <el-icon><Checked /></el-icon> 确认提交盲盘并平账交班
            </el-button>
          </el-form>
        </el-card>
      </el-col>

      <!-- 右侧：交班平账历史与当前班次对账单 -->
      <el-col :xs="24" :md="14">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span class="header-title">📋 班次交接平账记录与长短款对账单</span>
              <div style="display: flex; gap: 8px;">
                <el-button v-if="latestShift" size="small" type="primary" plain @click="handlePrintShiftSheet">
                  🖨️ 打印最新平账凭条
                </el-button>
                <el-button v-if="shiftRecords.length > 0" size="small" type="success" plain @click="handleExportShiftCsv">
                  📥 导出记录 (CSV)
                </el-button>
                <el-button size="small" icon="Refresh" @click="loadRecords">刷新</el-button>
              </div>
            </div>
          </template>

          <!-- 最新交班凭单展示 -->
          <div v-if="latestShift" class="latest-sheet">
            <div class="sheet-title">
              <span>🧾 最新《班次交接平账单》</span>
              <el-tag :type="latestShift.status === 'NORMAL' ? 'success' : 'danger'">
                {{ latestShift.status === 'NORMAL' ? '账目平齐' : '存在长短款差额' }}
              </el-tag>
            </div>

            <div class="sheet-grid">
              <div class="sg-item">
                <span class="sg-label">盲盘实数现金:</span>
                <span class="sg-val">￥{{ latestShift.blindCashAmount }}</span>
              </div>
              <div class="sg-item">
                <span class="sg-label">系统理论现金:</span>
                <span class="sg-val">￥{{ latestShift.systemCashAmount }}</span>
              </div>
              <div class="sg-item">
                <span class="sg-label">长短款差额:</span>
                <span class="sg-val" :class="latestShift.cashVariance >= 0 ? 'text-success' : 'text-danger'">
                  {{ latestShift.cashVariance >= 0 ? '+￥' : '-￥' }}{{ Math.abs(latestShift.cashVariance).toFixed(2) }}
                </span>
              </div>
              <div class="sg-item">
                <span class="sg-label">微信实收总额:</span>
                <span class="sg-val">￥{{ latestShift.wechatTotal }}</span>
              </div>
              <div class="sg-item">
                <span class="sg-label">支付宝实收:</span>
                <span class="sg-val">￥{{ latestShift.alipayTotal }}</span>
              </div>
              <div class="sg-item">
                <span class="sg-label">储值抵扣划扣:</span>
                <span class="sg-val">￥{{ latestShift.storedValueTotal }}</span>
              </div>
              <div class="sg-item">
                <span class="sg-label">计次卡核销总次:</span>
                <span class="sg-val">{{ latestShift.timeCardTimesTotal }} 次</span>
              </div>
              <div class="sg-item">
                <span class="sg-label">结账单数:</span>
                <span class="sg-val">{{ latestShift.orderCount }} 笔</span>
              </div>
            </div>
            <div class="sheet-time">交班时间: {{ latestShift.createdAt }} · 收银员: {{ latestShift.cashierName }}</div>
          </div>

          <!-- 历史交接列表 -->
          <el-table :data="shiftRecords" stripe style="width: 100%; margin-top: 16px;">
            <el-table-column prop="createdAt" label="交班时间" width="170" />
            <el-table-column prop="cashierName" label="收银员" width="110" />
            <el-table-column prop="blindCashAmount" label="盲盘现金">
              <template #default="{ row }">￥{{ row.blindCashAmount }}</template>
            </el-table-column>
            <el-table-column prop="systemCashAmount" label="理论现金">
              <template #default="{ row }">￥{{ row.systemCashAmount }}</template>
            </el-table-column>
            <el-table-column prop="cashVariance" label="长短款差额">
              <template #default="{ row }">
                <span :class="row.cashVariance >= 0 ? 'text-success' : 'text-danger'">
                  {{ row.cashVariance >= 0 ? '+' : '' }}￥{{ row.cashVariance }}
                </span>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="对账状态" width="110">
              <template #default="{ row }">
                <el-tag size="small" :type="row.status === 'NORMAL' ? 'success' : 'danger'">
                  {{ row.status === 'NORMAL' ? '正常平账' : '有差额' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { submitBlindShiftApi, getShiftRecordsApi } from '../api'
import { ElMessage } from 'element-plus'

const blindCash = ref(0)
const shiftNotes = ref('')
const submitting = ref(false)
const showDenomCalc = ref(true)
const coinLooseAmount = ref(0)
const pettyCashFloat = ref(0)

const denomList = ref([
  { label: '100', value: 100, count: 0 },
  { label: '50', value: 50, count: 0 },
  { label: '20', value: 20, count: 0 },
  { label: '10', value: 10, count: 0 },
  { label: '5', value: 5, count: 0 },
  { label: '1', value: 1, count: 0 }
])

const rawCountedTotal = computed(() => {
  const notesSum = denomList.value.reduce((acc, d) => acc + d.value * (d.count || 0), 0)
  return notesSum + (coinLooseAmount.value || 0)
})

const syncDenomToBlindCash = () => {
  const net = Math.max(0, rawCountedTotal.value - (pettyCashFloat.value || 0))
  blindCash.value = Number(net.toFixed(2))
}

const resetDenomCounts = () => {
  denomList.value.forEach(d => { d.count = 0 })
  coinLooseAmount.value = 0
  pettyCashFloat.value = 0
  blindCash.value = 0
}

const quickNoteTemplates = [
  '钱箱预留备用金200元整',
  '当班现金已清点投柜',
  '含顾客抹零优惠差额',
  '已与接班收银员当面核对无误'
]

const appendQuickNote = (tag: string) => {
  if (!shiftNotes.value) {
    shiftNotes.value = tag
  } else if (!shiftNotes.value.includes(tag)) {
    shiftNotes.value = `${shiftNotes.value}；${tag}`
  }
}

const shiftRecords = ref<any[]>([])
const latestShift = ref<any>(null)

const loadRecords = async () => {
  try {
    const list: any = await getShiftRecordsApi()
    shiftRecords.value = list
    if (list && list.length > 0) {
      latestShift.value = list[0]
    }
  } catch (e) {
    console.error(e)
  }
}

const handleSubmitBlindShift = async () => {
  submitting.value = true
  try {
    const res: any = await submitBlindShiftApi({
      blindCashAmount: blindCash.value,
      notes: shiftNotes.value
    })
    ElMessage.success('盲盘交班平账完成！')
    latestShift.value = res
    loadRecords()
  } catch (e) {
    console.error(e)
  } finally {
    submitting.value = false
  }
}

const handlePrintShiftSheet = () => {
  if (!latestShift.value) return
  const s = latestShift.value
  const printWin = window.open('', '_blank', 'width=420,height=640')
  if (!printWin) {
    ElMessage.warning('请允许浏览器弹出打印窗口')
    return
  }
  printWin.document.write(`
    <html><head><title>班次交接平账单</title>
    <style>
      body { font-family: 'Microsoft YaHei', monospace; padding: 18px; color: #1e293b; font-size: 13px; }
      h2 { text-align: center; margin: 0 0 6px; font-size: 17px; }
      .sub { text-align: center; color: #64748b; font-size: 12px; margin-bottom: 14px; border-bottom: 1px dashed #94a3b8; padding-bottom: 10px; }
      .row { display: flex; justify-content: space-between; margin: 7px 0; }
      .sep { border-top: 1px dashed #94a3b8; margin: 12px 0; }
      .bold { font-weight: bold; font-size: 14px; }
      .sig { margin-top: 28px; display: flex; justify-content: space-between; font-size: 12px; }
    </style></head><body>
      <h2>海马智慧门店 · 班次交接平账单</h2>
      <div class="sub">交班时间：${s.createdAt || '-'}<br/>当班收银员：${s.cashierName || '管理员'}</div>
      <div class="row"><span>盲盘实数现金：</span><span class="bold">￥${s.blindCashAmount}</span></div>
      <div class="row"><span>系统理论现金：</span><span>￥${s.systemCashAmount}</span></div>
      <div class="row"><span>长短款差额：</span><span class="bold">${s.cashVariance >= 0 ? '+￥' : '-￥'}${Math.abs(s.cashVariance || 0).toFixed(2)} (${s.status === 'NORMAL' ? '账目平齐' : '有差额'})</span></div>
      <div class="sep"></div>
      <div class="row"><span>微信实收总额：</span><span>￥${s.wechatTotal}</span></div>
      <div class="row"><span>支付宝实收：</span><span>￥${s.alipayTotal}</span></div>
      <div class="row"><span>会员储值划扣：</span><span>￥${s.storedValueTotal}</span></div>
      <div class="row"><span>计次卡核销总次：</span><span>${s.timeCardTimesTotal} 次</span></div>
      <div class="row"><span>本班结账笔数：</span><span>${s.orderCount} 笔</span></div>
      <div class="sep"></div>
      <div class="sig"><span>交班人签字：__________</span><span>接班/店长签字：__________</span></div>
    </body></html>
  `)
  printWin.document.close()
  printWin.focus()
  setTimeout(() => {
    printWin.print()
  }, 250)
}

const handleExportShiftCsv = () => {
  if (!shiftRecords.value.length) return
  const headers = ['交班时间', '收银员', '盲盘实数现金(元)', '系统理论现金(元)', '长短款差额(元)', '微信实收(元)', '支付宝实收(元)', '储值划扣(元)', '对账状态']
  const rows = shiftRecords.value.map((r: any) => [
    r.createdAt || '',
    r.cashierName || '',
    r.blindCashAmount ?? 0,
    r.systemCashAmount ?? 0,
    r.cashVariance ?? 0,
    r.wechatTotal ?? 0,
    r.alipayTotal ?? 0,
    r.storedValueTotal ?? 0,
    r.status === 'NORMAL' ? '正常平账' : '有差额'
  ])
  const csvContent = '\uFEFF' + [headers.join(','), ...rows.map(row => row.map(v => `"${String(v).replace(/"/g, '""')}"`).join(','))].join('\n')
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `海马门店_交班盲盘平账记录_${new Date().toISOString().slice(0, 10)}.csv`
  link.click()
  URL.revokeObjectURL(url)
  ElMessage.success('已导出交班平账记录 CSV 文件！')
}

onMounted(() => {
  loadRecords()
})
</script>

<style scoped>
.shift-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.blind-input-card {
  margin-bottom: 16px;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 8px;
}

.header-title {
  font-size: 15px;
  font-weight: 600;
}

.denom-calc-panel {
  margin-top: 14px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 12px 14px;
}

.denom-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.denom-title {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
}

.denom-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px 12px;
}

.denom-row {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #ffffff;
  padding: 5px 8px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.denom-badge {
  font-size: 12px;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 4px;
  min-width: 44px;
  text-align: center;
  color: #fff;
  background: #64748b;
}
.denom-100 { background: #e11d48; }
.denom-50 { background: #059669; }
.denom-20 { background: #d97706; }
.denom-10 { background: #0284c7; }
.denom-5 { background: #7c3aed; }
.denom-1 { background: #475569; }

.denom-mul {
  color: #94a3b8;
  font-size: 12px;
}

.denom-input {
  width: 82px !important;
}

.denom-sub {
  font-size: 12px;
  font-weight: 600;
  color: #334155;
  margin-left: auto;
}

.denom-petty-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
  font-size: 12.5px;
  color: #475569;
}

.denom-summary-bar {
  margin-top: 10px;
  padding-top: 8px;
  border-top: 1px dashed #cbd5e1;
  display: flex;
  justify-content: space-between;
  font-size: 12.5px;
  color: #334155;
}

.text-primary {
  color: #0284c7;
  font-size: 14px;
}

.quick-note-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 8px;
}

.q-note-tag {
  cursor: pointer;
  user-select: none;
  transition: all 0.15s;
}
.q-note-tag:hover {
  border-color: #0284c7;
  color: #0284c7;
  background: #f0f9ff;
}

.latest-sheet {
  background-color: #f8fafc;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 16px;
}

.sheet-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 15px;
  font-weight: 700;
  margin-bottom: 12px;
}

.sheet-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}

.sg-item {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  padding: 6px 8px;
  background: #fff;
  border-radius: 4px;
  border: 1px solid #e2e8f0;
}

.sg-label { color: #64748b; }
.sg-val { font-weight: 600; }

.sheet-time {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 12px;
  text-align: right;
}

.text-success { color: #059669; font-weight: 700; }
.text-danger { color: #ef4444; font-weight: 700; }

@media (max-width: 640px) {
  .denom-grid,
  .sheet-grid {
    grid-template-columns: 1fr;
  }
}
</style>
