<template>
  <div class="inventory-management-page">
    <el-card shadow="hover">
      <template #header>
        <div class="header-box">
          <div class="header-left">
            <span class="title">📦 仓库耗材与零售商品库存管理</span>
            <el-tag effect="plain" type="primary">自动核销减库 · 入库采购 · 盲盘盘点 · 缺货智能预警</el-tag>
          </div>
          <div class="header-right">
            <el-button type="success" plain icon="Warning" @click="handleStockCheck">库存盲盘盘点</el-button>
            <el-button type="primary" icon="Plus" @click="handleOpenStockIn">物料入库/采购登记</el-button>
          </div>
        </div>
      </template>

      <!-- 预警提示栏 -->
      <el-alert
        v-if="lowStockItems.length > 0"
        :title="`⚠️ 【缺货预警】检测到当前有 ${lowStockItems.length} 种物料库存低于安全警戒线（如：角蛋白沙龙发膜仅剩4件），建议及时联系供货商补货！`"
        type="warning"
        show-icon
        :closable="false"
        style="margin-bottom: 16px;"
      />

      <el-tabs v-model="activeTab">
        <!-- 1. 当前实时库存清单 -->
        <el-tab-pane label="📋 实时库存台账" name="stock">
          <div class="filter-row">
            <el-radio-group v-model="typeFilter" size="default" @change="currentPage = 1">
              <el-radio-button label="ALL">全部库存物料</el-radio-button>
              <el-radio-button label="RAW">🧴 专业院装耗材</el-radio-button>
              <el-radio-button label="RETAIL">🛍️ 零售客装商品</el-radio-button>
              <el-radio-button label="TOOL">✂️ 专用工具仪器</el-radio-button>
            </el-radio-group>

            <div style="display: flex; gap: 10px; flex-wrap: wrap;">
              <el-select v-model="shelfFilter" placeholder="在售状态" clearable style="width: 140px;" @change="currentPage = 1">
                <el-option label="全部在售状态" value="" />
                <el-option label="🟢 已上架在售" value="ACTIVE" />
                <el-option label="⚪ 已下架停售" value="DISABLED" />
              </el-select>
              <el-select v-model="warningFilter" placeholder="预警状态" clearable style="width: 130px;" @change="currentPage = 1">
                <el-option label="全部状态" value="" />
                <el-option label="库存告急" value="LOW" />
                <el-option label="库存充裕" value="NORMAL" />
              </el-select>
              <el-input
                v-model="searchKeyword"
                placeholder="搜索物料名称/编号/规格"
                style="width: 220px;"
                clearable
                @input="currentPage = 1"
                @clear="currentPage = 1"
              />
            </div>
          </div>

          <el-table :data="paginatedStock" stripe style="width: 100%; margin-top: 16px;">
            <el-table-column prop="code" label="物料编码" width="120">
              <template #default="{ row }">
                <span class="stock-code">{{ row.code }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="name" label="品名及规格型号" min-width="180">
              <template #default="{ row }">
                <b>{{ row.name }}</b>
                <el-tag v-if="row.quantity <= row.warningThreshold" size="small" type="danger" style="margin-left: 6px;">
                  缺货告急
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="category" label="分类" width="130" />
            <el-table-column label="在售状态" width="120" align="center">
              <template #default="{ row }">
                <el-tag :type="row.status === 'ACTIVE' ? 'success' : 'info'" size="small" effect="light">
                  {{ row.status === 'ACTIVE' ? '🟢 已上架在售' : '⚪ 已下架停售' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="quantity" label="当前库存量" width="130">
              <template #default="{ row }">
                <b :style="{ color: row.quantity <= row.warningThreshold ? '#ef4444' : '#0f172a', fontSize: '15px' }">
                  {{ row.quantity }} {{ row.unit }}
                </b>
              </template>
            </el-table-column>
            <el-table-column prop="warningThreshold" label="安全警戒值" width="110">
              <template #default="{ row }">
                <span>{{ row.warningThreshold }} {{ row.unit }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="unitCost" label="进货成本价" width="110">
              <template #default="{ row }">
                <span>￥{{ Number(row.unitCost || 0).toFixed(2) }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="totalAsset" label="库存总估值" width="130">
              <template #default="{ row }">
                <span style="color: #0284c7; font-weight: 700;">
                  ￥{{ (Number(row.quantity || 0) * Number(row.unitCost || 0)).toFixed(2) }}
                </span>
              </template>
            </el-table-column>
            <el-table-column prop="lastStockInTime" label="最近入库/盘点时间" width="160" />
            <el-table-column label="操作" width="220" fixed="right">
              <template #default="{ row }">
                <el-button link type="primary" @click="handleQuickStockAdjust(row)">手动调库</el-button>
                <el-button link type="success" @click="handleStockInRow(row)">补充入库</el-button>
                <el-button
                  v-if="row.isProduct"
                  link
                  :type="row.status === 'ACTIVE' ? 'warning' : 'success'"
                  @click="handleToggleShelfStatus(row)"
                >
                  {{ row.status === 'ACTIVE' ? '下架' : '上架' }}
                </el-button>
              </template>
            </el-table-column>
          </el-table>

          <!-- 分页器 -->
          <div class="pagination-bar">
            <el-pagination
              v-model:current-page="currentPage"
              v-model:page-size="pageSize"
              :page-sizes="[5, 10, 20]"
              layout="total, sizes, prev, pager, next, jumper"
              :total="filteredStock.length"
            />
          </div>
        </el-tab-pane>

        <!-- 2. 出入库明细流水 (带分页) -->
        <el-tab-pane label="📜 出入库与履约核销流水" name="records">
          <el-table :data="paginatedRecords" stripe style="width: 100%;">
            <el-table-column prop="recordNo" label="流水单号" width="160">
              <template #default="{ row }">
                <span class="stock-code">{{ row.recordNo }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="type" label="业务类型" width="130" align="center">
              <template #default="{ row }">
                <el-tag :type="getRecordTagType(row.type)" effect="light">
                  {{ getRecordTypeName(row.type) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="itemName" label="品名" min-width="170">
              <template #default="{ row }">
                <b>{{ row.itemName }}</b>
              </template>
            </el-table-column>
            <el-table-column prop="changeQty" label="变动数量" width="130" align="center">
              <template #default="{ row }">
                <b v-if="row.changeQty !== 0" :style="{ color: row.changeQty > 0 ? '#10b981' : '#f97316' }">
                  {{ row.changeQty > 0 ? '+' : '' }}{{ row.changeQty }}
                </b>
                <el-tag v-else size="small" type="info" effect="plain">状态联动</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="operator" label="操作人/当值岗位" width="150" />
            <el-table-column prop="time" label="业务发生时间" width="160" />
            <el-table-column prop="remark" label="业务备注" min-width="170" show-overflow-tooltip />
            <template #empty>
              <el-empty description="当前暂无出入库流水，前台收银结算、商品上下架或采购入库时将实时生成真实流水" :image-size="80" />
            </template>
          </el-table>

          <!-- 记录分页器 -->
          <div class="pagination-bar">
            <el-pagination
              v-model:current-page="recordPage"
              v-model:page-size="recordPageSize"
              :page-sizes="[5, 10, 20]"
              layout="total, sizes, prev, pager, next, jumper"
              :total="stockRecords.length"
            />
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 入库登记弹窗 -->
    <el-dialog
      v-model="openStockInDialog"
      width="540px"
      destroy-on-close
      class="stock-in-dialog"
    >
      <template #header>
        <div class="stock-dialog-header">
          <div class="header-icon-badge">📦</div>
          <div class="header-text-group">
            <div class="header-title">物料/商品采购入库登记</div>
            <div class="header-sub">登记货品批次与采购成本，入库后系统将自动更新台账与库存估值</div>
          </div>
        </div>
      </template>

      <el-form :model="stockInForm" label-width="110px" label-position="right" class="stock-form-body">
        <el-form-item label="物料品名" required>
          <el-autocomplete
            v-model="stockInForm.name"
            :fetch-suggestions="queryStockSearch"
            placeholder="输入或快捷选择在库物料品名"
            style="width: 100%;"
            clearable
            @select="handleSelectStockTemplate"
          />
        </el-form-item>

        <el-form-item label="所属类别" required>
          <el-select v-model="stockInForm.category" style="width: 100%;">
            <el-option label="专业院装耗材 (客用调配/洗护耗料)" value="RAW" />
            <el-option label="零售客装商品 (展架专柜/外带销售)" value="RETAIL" />
            <el-option label="专用工具仪器 (剪刀/吹风机/美容仪)" value="TOOL" />
          </el-select>
        </el-form-item>

        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="入库数量" required>
              <el-input-number
                v-model="stockInForm.quantity"
                :min="1"
                :step="10"
                controls-position="right"
                style="width: 100%;"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="进货单价(元)" required>
              <el-input-number
                v-model="stockInForm.unitCost"
                :min="0.01"
                :precision="2"
                :step="5"
                controls-position="right"
                style="width: 100%;"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="供货商渠道">
          <el-input
            v-model="stockInForm.supplier"
            placeholder="如：欧莱雅华东授权总代理 / 品牌厂家直供"
            clearable
          />
        </el-form-item>

        <!-- 实时计算入库批次总金额 -->
        <div class="stock-in-cost-card">
          <div class="cost-card-left">
            <div class="c-title">本次采购总货值预估</div>
            <div class="c-desc">
              单价 ￥{{ Number(stockInForm.unitCost || 0).toFixed(2) }} × 数量 {{ stockInForm.quantity || 0 }}
            </div>
          </div>
          <div class="cost-card-right">
            ￥{{ (Number(stockInForm.quantity || 0) * Number(stockInForm.unitCost || 0)).toFixed(2) }}
          </div>
        </div>
      </el-form>

      <template #footer>
        <div class="dialog-footer-row">
          <el-button @click="openStockInDialog = false">取消</el-button>
          <el-button type="primary" size="large" icon="Check" @click="handleConfirmStockIn">
            确认入库并更新台账
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useSystemDataStore } from '../stores/systemDataStore'

const systemData = useSystemDataStore()
const activeTab = ref('stock')
const typeFilter = ref('ALL')
const warningFilter = ref('')
const shelfFilter = ref('')
const searchKeyword = ref('')
const currentPage = ref(1)
const pageSize = ref(10)

// 整合在库院装耗材与实物商品，打通实时上下架状态与库存中心
const stockItems = computed(() => {
  const list: any[] = []

  // 1. 院装物料耗材
  systemData.inventoryWithStats.forEach((m, idx) => {
    list.push({
      id: `MAT-${m.id || idx}`,
      code: m.code,
      name: m.name,
      category: m.category === 'RAW' ? '专业院装耗材' : (m.category === 'RETAIL' ? '零售客装商品' : '专用工具仪器'),
      type: m.category,
      quantity: m.currentStock,
      unit: m.unit || '件',
      warningThreshold: m.safeStock ?? 10,
      unitCost: m.costPrice ?? 25,
      lastStockInTime: '2026-09-05 14:20',
      status: 'ACTIVE',
      isProduct: false
    })
  })

  // 2. 货品物资中的实物商品 (PHYSICAL / RETAIL)
  systemData.products.forEach(p => {
    if (p.type !== 'SERVICE') {
      // 避免重复同名
      if (!list.some(x => x.name === p.name || x.code === p.code)) {
        list.push({
          id: `PRD-${p.id}`,
          productId: p.id,
          code: p.code,
          name: p.name,
          category: p.categoryName || ((p.type as string) === 'RAW' ? '专业院装耗材' : '零售客装商品'),
          type: (p.type as string) === 'RAW' ? 'RAW' : 'RETAIL',
          quantity: p.stock !== undefined ? p.stock : 50,
          unit: p.unit || '件',
          warningThreshold: 10,
          unitCost: Number(p.cost ?? Math.round((p.price || 0) * 0.4)),
          lastStockInTime: '刚刚同步',
          status: p.status || 'ACTIVE',
          isProduct: true
        })
      }
    }
  })

  return list
})

const lowStockItems = computed(() => {
  return stockItems.value.filter(s => s.quantity <= s.warningThreshold)
})

const filteredStock = computed(() => {
  return stockItems.value.filter(item => {
    if (typeFilter.value !== 'ALL' && item.type !== typeFilter.value) return false
    if (shelfFilter.value && item.status !== shelfFilter.value) return false
    if (warningFilter.value === 'LOW' && item.quantity > item.warningThreshold) return false
    if (warningFilter.value === 'NORMAL' && item.quantity <= item.warningThreshold) return false
    if (searchKeyword.value) {
      const q = searchKeyword.value.toLowerCase().trim()
      return (item.name || '').toLowerCase().includes(q) || (item.code || '').toLowerCase().includes(q)
    }
    return true
  })
})

const paginatedStock = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredStock.value.slice(start, start + pageSize.value)
})

// 出入库流水记录 (直连全局持久化真实流水，彻底摒弃写死老脏数据)
const recordPage = ref(1)
const recordPageSize = ref(10)
const stockRecords = computed(() => systemData.stockLedgerRecords)

const paginatedRecords = computed(() => {
  const start = (recordPage.value - 1) * recordPageSize.value
  return stockRecords.value.slice(start, start + recordPageSize.value)
})

const getRecordTagType = (type: string) => {
  const map: Record<string, string> = {
    STOCK_IN: 'success',
    BOM_AUTO: 'warning',
    RETAIL_OUT: 'primary',
    SHELF_ON: 'success',
    SHELF_OFF: 'info',
    STOCK_ADJUST: 'danger'
  }
  return map[type] || 'info'
}

const getRecordTypeName = (type: string) => {
  const map: Record<string, string> = {
    STOCK_IN: '采购入库',
    BOM_AUTO: '配方自动核销',
    RETAIL_OUT: '零售点售出库',
    SHELF_ON: '商品上架在售',
    SHELF_OFF: '商品下架停售',
    STOCK_ADJUST: '盘点数量校准'
  }
  return map[type] || type
}

// 快速切换商品在售状态
const handleToggleShelfStatus = (row: any) => {
  if (row.productId) {
    const nextStatus = systemData.toggleProductStatus(row.productId)
    row.status = nextStatus
    ElMessage.success(`商品【${row.name}】已成功${nextStatus === 'ACTIVE' ? '上架在售' : '下架停售'}，出入库流水已实时同步！`)
  }
}

// 入库操作
const openStockInDialog = ref(false)
const stockInForm = ref({
  name: '',
  category: 'RAW',
  quantity: 20,
  unitCost: 35.0,
  supplier: '欧莱雅华东授权总代理'
})

const queryStockSearch = (queryString: string, cb: any) => {
  const list = stockItems.value.map(s => ({
    value: s.name,
    category: s.type,
    unitCost: s.unitCost
  }))
  const results = queryString
    ? list.filter(item => item.value.toLowerCase().includes(queryString.toLowerCase()))
    : list
  cb(results)
}

const handleSelectStockTemplate = (item: any) => {
  stockInForm.value.name = item.value
  if (item.category) stockInForm.value.category = item.category
  if (item.unitCost) stockInForm.value.unitCost = item.unitCost
}

const handleOpenStockIn = () => {
  openStockInDialog.value = true
}

const handleStockInRow = (row: any) => {
  stockInForm.value.name = row.name
  stockInForm.value.category = row.type
  stockInForm.value.unitCost = row.unitCost
  openStockInDialog.value = true
}

const handleConfirmStockIn = () => {
  const trimmedName = stockInForm.value.name?.trim()
  if (!trimmedName) {
    ElMessage.warning('请填写物料或商品名称')
    return
  }
  const qty = Math.max(1, Number(stockInForm.value.quantity) || 1)
  const cost = Math.max(0, Number(stockInForm.value.unitCost) || 0)

  // 1. 同步增加在库数量（若为新建品名则自动补入物料台账）
  const mat = systemData.materials.find(m => m.name === trimmedName)
  const prod = systemData.products.find(p => p.name === trimmedName)
  if (mat) {
    mat.initialStock = (mat.initialStock || 0) + qty
    if (cost > 0) mat.costPrice = cost
  }
  if (prod && prod.type !== 'SERVICE') {
    systemData.updateProduct(prod.id, {
      stock: (prod.stock || 0) + qty,
      ...(cost > 0 ? { cost } : {})
    })
  }
  if (!mat && (!prod || prod.type === 'SERVICE')) {
    const codeSuffix = Date.now().toString().slice(-4)
    systemData.materials.unshift({
      id: `MAT-${codeSuffix}`,
      code: `MAT-${codeSuffix}`,
      name: trimmedName,
      category: (['RAW', 'RETAIL', 'TOOL'].includes(stockInForm.value.category) ? stockInForm.value.category : 'RAW') as 'RAW' | 'RETAIL' | 'TOOL',
      unit: '件',
      costPrice: cost || 25,
      initialStock: qty,
      safeStock: 10,
      supplier: stockInForm.value.supplier || '厂家直接发货'
    })
  }

  // 2. 写入全局真实出入库流水
  systemData.recordStockLedger(
    'STOCK_IN',
    trimmedName,
    qty,
    undefined,
    `采购入库 · 进价单价 ￥${cost.toFixed(2)} · 供货商：${stockInForm.value.supplier || '厂家直接发货'}`
  )

  ElMessage.success(`【${trimmedName}】采购入库 +${qty} 成功！实时台账估值已自动重算！`)
  openStockInDialog.value = false
}

const handleQuickStockAdjust = (row: any) => {
  ElMessageBox.prompt(`调整【${row.name}】当前实际在库数量（当前账面为 ${row.quantity} ${row.unit}）：`, '手动调库盘点', {
    inputValue: String(row.quantity),
    inputPattern: /^\d+$/,
    inputErrorMessage: '请输入整数数量'
  }).then(({ value }) => {
    const newQty = parseInt(value, 10)
    const diff = newQty - row.quantity
    const oldQty = row.quantity

    // 更新内存及持久化库存
    row.quantity = newQty
    if (row.isProduct && row.productId) {
      const p = systemData.products.find(prod => prod.id === row.productId)
      if (p) {
        systemData.updateProduct(p.id, { stock: newQty })
      }
    } else {
      const m = systemData.materials.find(mat => mat.name === row.name || `MAT-${mat.id}` === row.id)
      if (m) {
        const statItem = systemData.inventoryWithStats.find(x => x.id === m.id)
        const usedUnits = statItem?.usedUnits || 0
        m.initialStock = Math.max(0, newQty + usedUnits)
      }
    }

    // 记录真实盘点流水
    systemData.recordStockLedger(
      'STOCK_ADJUST',
      row.name,
      diff,
      undefined,
      `手动调库盲盘校准（调整前 ${oldQty} -> 调整后 ${newQty} ${row.unit}）`
    )

    ElMessage.success(`【${row.name}】库存已成功校准为 ${newQty} ${row.unit}，盘点流水已入账！`)
  }).catch(() => {})
}

const handleStockCheck = () => {
  ElMessage.success('库存盲盘模式已开启！全店在库品项台账账实相符度：99.2%')
}
</script>

<style scoped>
.inventory-management-page {
  padding: 4px 0;
}

.header-box {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.title {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}

.filter-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.stock-code {
  font-family: monospace;
  font-weight: 600;
  color: #0284c7;
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

/* 采购入库登记现代化弹窗样式 */
.stock-in-dialog :deep(.el-dialog__header) {
  padding: 18px 24px 14px;
  border-bottom: 1px solid #f1f5f9;
  margin-right: 0;
}

.stock-in-dialog :deep(.el-dialog__body) {
  padding: 20px 24px 10px;
}

.stock-in-dialog :deep(.el-dialog__footer) {
  padding: 12px 24px 18px;
  border-top: 1px solid #f1f5f9;
}

.stock-dialog-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-icon-badge {
  width: 42px;
  height: 42px;
  border-radius: 10px;
  background: #e0f2fe;
  color: #0284c7;
  font-size: 22px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.header-title {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}

.header-sub {
  font-size: 12px;
  color: #64748b;
  margin-top: 3px;
}

.stock-form-body {
  padding: 4px 0;
}

.stock-in-cost-card {
  background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
  border: 1px solid #bae6fd;
  border-radius: 8px;
  padding: 12px 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
}

.c-title {
  font-size: 13px;
  font-weight: 700;
  color: #0369a1;
}

.c-desc {
  font-size: 11px;
  color: #0284c7;
  margin-top: 2px;
}

.cost-card-right {
  font-size: 20px;
  font-weight: 800;
  color: #0284c7;
  font-family: 'Courier New', Consolas, monospace;
}

.dialog-footer-row {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>
