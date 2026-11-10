<template>
  <div class="session-board-page">
    <!-- 顶部状态栏与操作 -->
    <div class="board-header">
      <div class="header-left" style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
        <el-radio-group v-model="statusFilter" size="default">
          <el-radio-button label="ALL">全部 ({{ spaces.length }})</el-radio-button>
          <el-radio-button label="IDLE">空闲可用 ({{ idleCount }})</el-radio-button>
          <el-radio-button label="OCCUPIED">服务中 ({{ occupiedCount }})</el-radio-button>
          <el-radio-button label="DIRTY">待清台复位 ({{ dirtyCount }})</el-radio-button>
        </el-radio-group>

        <el-select v-if="zoneOptions.length > 1" v-model="zoneFilter" placeholder="全部区域" style="width: 140px;" clearable>
          <el-option label="全部楼层/区域" value="ALL" />
          <el-option v-for="z in zoneOptions" :key="z" :label="z" :value="z" />
        </el-select>

        <el-input
          v-model="spaceKeyword"
          :placeholder="`搜索${storeConfig.spaceAlias}号/名称/顾客...`"
          prefix-icon="Search"
          clearable
          style="width: 210px;"
        />
      </div>

      <div class="header-right" style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
        <el-button v-if="dirtyCount > 1" type="warning" plain @click="handleBatchResetDirty">
          🧹 一键清台全部 ({{ dirtyCount }})
        </el-button>
        <el-button type="success" plain @click="$router.push('/cashier')">
          ⚡ 散客直接收银
        </el-button>
        <el-button type="primary" icon="Plus" @click="handleOpenCreateSpace">新增{{ storeConfig.spaceAlias }}</el-button>
        <el-button icon="Refresh" @click="loadSpaces">刷新看板</el-button>
      </div>
    </div>

    <!-- 空间卡片网格矩阵 -->
    <div class="space-grid">
      <div
        v-for="space in filteredSpaces"
        :key="space.id"
        class="space-card"
        :class="getSpaceClass(space.status)"
        @click="handleCardClick(space)"
      >
        <div class="card-top">
          <span class="space-code">{{ space.spaceCode }}</span>
          <el-tag size="small" :type="getStatusTagType(space.status)">
            {{ getStatusText(space.status) }}
          </el-tag>
        </div>

        <div class="space-name">{{ space.spaceName }}</div>
        <div class="space-zone">
          {{ space.floorZone || '主服务区' }} · 容纳 {{ space.capacity || 1 }} 位
          <span v-if="space.status === 'OCCUPIED' && space.customerName" style="color: #0284c7; font-weight: 600; margin-left: 4px;">
            · 👤 {{ space.customerName }}
          </span>
        </div>

        <div class="card-bottom">
          <template v-if="space.status === 'IDLE'">
            <div class="action-hint"><el-icon><CirclePlus /></el-icon> 点击快速开单</div>
          </template>
          <template v-else-if="space.status === 'OCCUPIED'">
            <div style="display: flex; align-items: center; justify-content: space-between; width: 100%;">
              <div class="action-hint text-active"><el-icon><View /></el-icon> 履约/加项</div>
              <el-button size="small" type="primary" plain @click.stop="$router.push({ path: '/cashier', query: { sessionId: String(space.currentSessionId || space.id) } })">
                💳 结账
              </el-button>
            </div>
          </template>
          <template v-else-if="space.status === 'DIRTY'">
            <el-button size="small" type="warning" plain @click.stop="handleResetSpace(space.id)">
              <el-icon><RefreshRight /></el-icon> 确认清台复位
            </el-button>
          </template>
        </div>
      </div>
    </div>

    <!-- 开单对话框 -->
    <el-dialog v-model="openDialogVisible" :title="'在场服务开单 - ' + currentSpace?.spaceName" width="520px">
      <el-form :model="openForm" label-width="95px">
        <el-form-item label="选择会员">
          <el-select
            v-model="selectedSessionMemberId"
            placeholder="搜索或选择会员（散客可不选）"
            filterable
            clearable
            style="width: 100%;"
            @change="handleSessionMemberChange"
          >
            <el-option
              v-for="m in storeMembersList"
              :key="m.id"
              :label="`${m.name} - ${m.phone} (${m.levelName || m.level || '会员'})`"
              :value="m.id"
            >
              <div style="display: flex; justify-content: space-between; align-items: center; width: 100%;">
                <span><b>{{ m.name }}</b> ({{ m.phone }})</span>
                <el-tag size="small" type="success">{{ m.levelName || m.level || '会员' }}</el-tag>
              </div>
            </el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="会员手机号">
          <el-input v-model="openForm.customerPhone" placeholder="手机号 (散客可留空)" @blur="handleMemberSearch" clearable>
            <template #append>
              <el-button icon="Search" @click="handleMemberSearch" />
            </template>
          </el-input>
          <div v-if="matchedMember" class="member-preview">
            <el-tag type="success" size="small">{{ matchedMember.name }} ({{ matchedMember.level }})</el-tag>
            <span class="preview-spent">累计消费: ￥{{ matchedMember.totalSpent }}</span>
          </div>
        </el-form-item>

        <!-- 海马体专属记忆画像提示 -->
        <div v-if="memberPreferences.length > 0" class="hippocampus-alert">
          <div class="alert-title">🧠 海马体记忆画像已识别：</div>
          <div v-for="pref in memberPreferences" :key="pref.id" class="alert-item">
            • <b>{{ pref.tagKey }}:</b> {{ pref.tagValue }}
          </div>
        </div>

        <el-form-item label="顾客姓名">
          <el-input v-model="openForm.customerName" placeholder="散客可填或留空" />
        </el-form-item>

        <el-form-item label="到店人数">
          <el-input-number v-model="openForm.guestCount" :min="1" :max="20" />
        </el-form-item>

        <el-form-item label="特殊备注">
          <el-input v-model="openForm.notes" type="textarea" placeholder="例如：水温适中、免葱辣、指定托尼老师等" />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="openDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="opening" @click="handleConfirmOpen">确认开单进入履约</el-button>
      </template>
    </el-dialog>

    <!-- 会话详情与动态追加项目抽屉 -->
    <el-drawer v-model="drawerVisible" :title="'在场履约会话详情 - ' + activeSession?.spaceName" size="620px">
      <div v-if="sessionDetail" class="drawer-content">
        <!-- 账单与会话概要 -->
        <div class="session-summary-card">
          <div class="summary-line">
            <span>会话编号: <b>{{ sessionDetail.session.sessionNo }}</b></span>
            <el-tag :type="sessionDetail.session.status === 'SERVING' ? 'primary' : 'warning'">
              {{ sessionDetail.session.status }}
            </el-tag>
          </div>
          <div class="summary-line">
            <span>顾客: {{ sessionDetail.session.customerName }} ({{ sessionDetail.session.customerPhone || '未登记' }})</span>
            <span class="total-badge">当前应收: ￥{{ sessionDetail.session.payableAmount }}</span>
          </div>
          <div v-if="Number(sessionDetail.session.feeAmount) > 0" class="summary-line" style="margin-top: 6px; font-size: 13px; color: #b45309;">
            <span>🏷️ 行业附加费 ({{ storeConfig.defaultFeeName || '茶位费/餐具费' }}):</span>
            <span style="font-weight: 700;">+￥{{ Number(sessionDetail.session.feeAmount).toFixed(2) }}</span>
          </div>
        </div>

        <!-- 快捷操作区 -->
        <div class="drawer-actions">
          <el-button type="success" icon="Plus" @click="handleOpenAppendDialog">
            {{ storeConfig.appendActionAlias }} (追加项目)
          </el-button>
          <el-button type="primary" icon="Money" @click="handleGoBilling">
            发起买单结账
          </el-button>
          <el-button type="info" icon="Switch" @click="handleOpenTransferDialog">
            转{{ storeConfig.spaceAlias }}
          </el-button>
        </div>

        <!-- 点单批次与行项明细 -->
        <div class="batch-list">
          <!-- 初始开台行业附加费 (茶位费/餐具费等) -->
          <div v-if="Number(sessionDetail.session.feeAmount) > 0" class="batch-block fee-batch-block" style="border-left: 3px solid #f59e0b; background: #fffbeb;">
            <div class="batch-header" style="background: transparent;">
              <span class="batch-title" style="color: #b45309; font-weight: 700;">🏷️ 开台基础消费 · 行业附加费</span>
              <span class="batch-time">随单核算</span>
            </div>
            <div class="item-row" style="background: transparent;">
              <div class="item-main">
                <div class="item-name" style="color: #92400e; font-weight: 600;">
                  [附加费] {{ storeConfig.defaultFeeName || '茶位费/餐具费' }}
                </div>
                <div class="item-mod" style="color: #b45309;">开台按客核算标准费用</div>
              </div>
              <div class="item-right">
                <span class="item-subtotal" style="color: #b45309; font-weight: 800;">
                  ￥{{ Number(sessionDetail.session.feeAmount).toFixed(2) }}
                </span>
              </div>
            </div>
          </div>
          <div v-for="batch in sessionDetail.batches" :key="batch.id" class="batch-block">
            <div class="batch-header">
              <span class="batch-title">第 {{ batch.batchNo }} 批次 ({{ batch.operatorType }}: {{ batch.operatorName }})</span>
              <span class="batch-time">{{ batch.createdAt }}</span>
            </div>

            <div
              v-for="item in getBatchItems(batch.id)"
              :key="item.id"
              class="item-row"
              :class="{ 'item-cancelled': item.status === 'CANCELLED' }"
            >
              <div class="item-main">
                <div class="item-name">{{ item.productName }} x {{ item.quantity }}</div>
                <div v-if="item.modifiers" class="item-mod">规格/做法: {{ item.modifiers }}</div>
                <div v-if="item.status === 'CANCELLED'" class="item-cancelled-text">已退订: {{ item.cancelReason }}</div>
              </div>

              <div class="item-right">
                <span class="item-subtotal">￥{{ item.subtotal }}</span>
                <el-button
                  v-if="item.status !== 'CANCELLED'"
                  link
                  type="danger"
                  size="small"
                  @click="handleCancelItem(item.id)"
                >
                  退订
                </el-button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </el-drawer>

    <!-- 动态追加项目弹窗 -->
    <el-dialog v-model="appendDialogVisible" :title="'追加项目 - ' + storeConfig.appendActionAlias" width="600px">
      <el-form label-width="90px">
        <el-form-item label="选择项目">
          <el-select v-model="selectedProductId" filterable placeholder="请选择商品或服务" style="width: 100%;">
            <el-option
              v-for="p in availableProducts"
              :key="p.id"
              :label="p.name + ' (￥' + p.price + ')'"
              :value="p.id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="数量">
          <el-input-number v-model="appendQuantity" :min="1" :max="99" />
        </el-form-item>

        <el-form-item label="规格做法">
          <el-input v-model="appendModifiers" placeholder="例如：少冰微辣、药水色号、机油标号等" />
        </el-form-item>

        <el-form-item label="提成技师">
          <el-select v-model="selectedEmployeeId" placeholder="选择施工/服务员工(可计提成)" clearable style="width: 100%;">
            <el-option
              v-for="e in employeeList"
              :key="e.id"
              :label="e.realName + ' (' + e.role + ')'"
              :value="e.id"
            />
          </el-select>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="appendDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="appending" @click="handleConfirmAppend">确认追加至账单</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import {
  getSpacesApi,
  resetSpaceApi,
  openSessionApi,
  appendItemsApi,
  getSessionDetailApi,
  searchMembersApi,
  getMemberProfileApi,
  getProductsApi,
  cancelLineItemApi
} from '../api'
import { useStoreConfig } from '../stores/store'
import { useSystemDataStore } from '../stores/systemDataStore'
import { ElMessage, ElMessageBox } from 'element-plus'

const router = useRouter()
const storeConfig = useStoreConfig()
const systemData = useSystemDataStore()

const spaces = ref<any[]>([])
const statusFilter = ref('ALL')
const zoneFilter = ref('ALL')
const spaceKeyword = ref('')
const availableProducts = ref<any[]>([])

// 开单相关
const openDialogVisible = ref(false)
const currentSpace = ref<any>(null)
const opening = ref(false)
const selectedSessionMemberId = ref<number | null>(null)
const storeMembersList = ref<any[]>([])
const openForm = ref({
  spaceId: 0,
  memberId: null as number | null,
  customerName: '',
  customerPhone: '',
  guestCount: 1,
  notes: ''
})
const matchedMember = ref<any>(null)
const memberPreferences = ref<any[]>([])

const loadStoreMembersList = async () => {
  try {
    const tenantId = localStorage.getItem('seahorse_tenant_id') || 'T001'
    const res: any = await searchMembersApi('', tenantId)
    if (Array.isArray(res) && res.length > 0) {
      storeMembersList.value = res
      return
    }
  } catch (e) {}
  if (systemData.members && systemData.members.length > 0) {
    storeMembersList.value = systemData.members
  }
}

const handleSessionMemberChange = async (memId: number | null) => {
  if (!memId) {
    openForm.value.memberId = null
    openForm.value.customerName = ''
    openForm.value.customerPhone = ''
    matchedMember.value = null
    memberPreferences.value = []
    return
  }
  const m = storeMembersList.value.find(item => item.id === memId)
  if (m) {
    matchedMember.value = m
    openForm.value.memberId = m.id
    openForm.value.customerName = m.name
    openForm.value.customerPhone = m.phone
    try {
      const profile: any = await getMemberProfileApi(m.id)
      memberPreferences.value = profile?.preferences || []
    } catch (e) {}
    ElMessage.success('已识别会员：' + m.name)
  }
}

// 会话详情抽屉
const drawerVisible = ref(false)
const activeSession = ref<any>(null)
const sessionDetail = ref<any>(null)

// 追加项目
const appendDialogVisible = ref(false)
const appending = ref(false)
const selectedProductId = ref<number | null>(null)
const appendQuantity = ref(1)
const appendModifiers = ref('')
const selectedEmployeeId = ref<number | null>(null)
const employeeList = ref<any[]>([
  { id: 4, realName: '托尼总监', role: 'TECHNICIAN' },
  { id: 5, realName: '凯文大工', role: 'TECHNICIAN' }
])

const loadSpaces = async () => {
  try {
    let list: any[] = []
    try {
      list = (await getSpacesApi()) as any[]
    } catch (err) {}

    if (Array.isArray(list) && list.length > 0) {
      spaces.value = list.map(sp => {
        const live = systemData.liveSessions.find(ls => ls.spaceId === sp.id || (sp.spaceName && ls.spaceName.includes(sp.spaceCode)) || (sp.spaceName && sp.spaceName.includes(ls.spaceName.substring(0, 3))))
        if (live && live.status !== 'COMPLETED') {
          return {
            ...sp,
            status: live.status === 'WAIT_CLEAN' ? 'DIRTY' : 'OCCUPIED',
            customerName: live.customerName,
            currentSessionId: live.id
          }
        }
        return sp
      })
    } else {
      spaces.value = systemData.liveSessions.map((ls, idx) => ({
        id: ls.spaceId || (idx + 1),
        spaceCode: `M0${idx + 1}`,
        spaceName: ls.spaceName,
        spaceType: 'MIRROR',
        status: ls.status === 'WAIT_CLEAN' ? 'DIRTY' : (ls.status === 'SERVING' ? 'OCCUPIED' : 'IDLE'),
        capacity: 1,
        floorZone: '美发大厅',
        currentSessionId: ls.id,
        customerName: ls.customerName
      }))
    }
  } catch (e) {
    console.error(e)
  }
}

const loadProducts = async () => {
  try {
    availableProducts.value = (await getProductsApi()) as any[]
  } catch (e) {
    console.error(e)
  }
}

const idleCount = computed(() => spaces.value.filter(s => s.status === 'IDLE').length)
const occupiedCount = computed(() => spaces.value.filter(s => s.status === 'OCCUPIED').length)
const dirtyCount = computed(() => spaces.value.filter(s => s.status === 'DIRTY').length)

const zoneOptions = computed(() => {
  const set = new Set<string>()
  spaces.value.forEach(s => {
    if (s.floorZone) set.add(s.floorZone)
  })
  return Array.from(set)
})

const filteredSpaces = computed(() => {
  return spaces.value.filter(s => {
    if (statusFilter.value !== 'ALL' && s.status !== statusFilter.value) return false
    if (zoneFilter.value && zoneFilter.value !== 'ALL' && s.floorZone !== zoneFilter.value) return false
    if (spaceKeyword.value.trim()) {
      const kw = spaceKeyword.value.trim().toLowerCase()
      const matchCode = (s.spaceCode || '').toLowerCase().includes(kw)
      const matchName = (s.spaceName || '').toLowerCase().includes(kw)
      const matchCust = (s.customerName || '').toLowerCase().includes(kw)
      if (!matchCode && !matchName && !matchCust) return false
    }
    return true
  })
})

const handleBatchResetDirty = async () => {
  const dirtyList = spaces.value.filter(s => s.status === 'DIRTY')
  for (const sp of dirtyList) {
    try {
      await resetSpaceApi(sp.id)
    } catch (e) {}
    systemData.resetSpace(sp.id)
  }
  ElMessage.success(`已批量清台复位 ${dirtyList.length} 个${storeConfig.spaceAlias}！`)
  loadSpaces()
}

const getSpaceClass = (status: string) => {
  switch (status) {
    case 'IDLE': return 'card-idle'
    case 'OCCUPIED': return 'card-occupied'
    case 'DIRTY': return 'card-dirty'
    default: return ''
  }
}

const getStatusTagType = (status: string) => {
  switch (status) {
    case 'IDLE': return 'success'
    case 'OCCUPIED': return 'primary'
    case 'DIRTY': return 'warning'
    default: return 'info'
  }
}

const getStatusText = (status: string) => {
  switch (status) {
    case 'IDLE': return '空闲'
    case 'OCCUPIED': return '服务中'
    case 'DIRTY': return '待清台'
    default: return status
  }
}

const handleCardClick = (space: any) => {
  if (space.status === 'IDLE') {
    currentSpace.value = space
    selectedSessionMemberId.value = null
    openForm.value = {
      spaceId: space.id,
      memberId: null,
      customerName: '',
      customerPhone: '',
      guestCount: 1,
      notes: ''
    }
    matchedMember.value = null
    memberPreferences.value = []
    loadStoreMembersList()
    openDialogVisible.value = true
  } else if (space.status === 'OCCUPIED' && space.currentSessionId) {
    openSessionDrawer(space.currentSessionId, space)
  }
}

const handleMemberSearch = async () => {
  if (!openForm.value.customerPhone) return
  try {
    const list: any = await searchMembersApi(openForm.value.customerPhone)
    if (list && list.length > 0) {
      matchedMember.value = list[0]
      openForm.value.memberId = list[0].id
      openForm.value.customerName = list[0].name
      // 触发海马体记忆档案获取
      const profile: any = await getMemberProfileApi(list[0].id)
      memberPreferences.value = profile.preferences || []
      ElMessage.success('已识别海马会员：' + list[0].name)
    }
  } catch (e) {
    console.error(e)
  }
}

const handleConfirmOpen = async () => {
  opening.value = true
  try {
    await openSessionApi(openForm.value)
    ElMessage.success('开单成功！')
    openDialogVisible.value = false
    loadSpaces()
  } catch (e) {
    console.error(e)
  } finally {
    opening.value = false
  }
}

const openSessionDrawer = async (sessionId: number, space: any) => {
  activeSession.value = space
  drawerVisible.value = true
  try {
    sessionDetail.value = await getSessionDetailApi(sessionId)
  } catch (e) {
    console.error(e)
  }
}

const getBatchItems = (batchId: number) => {
  if (!sessionDetail.value?.lineItems) return []
  return sessionDetail.value.lineItems.filter((i: any) => i.batchId === batchId)
}

const handleOpenAppendDialog = () => {
  selectedProductId.value = null
  appendQuantity.value = 1
  appendModifiers.value = ''
  selectedEmployeeId.value = null
  appendDialogVisible.value = true
}

const handleConfirmAppend = async () => {
  if (!selectedProductId.value) {
    ElMessage.warning('请选择商品/服务')
    return
  }

  appending.value = true
  try {
    const performers = []
    if (selectedEmployeeId.value) {
      const emp = employeeList.value.find(e => e.id === selectedEmployeeId.value)
      performers.push({
        employeeId: emp.id,
        employeeName: emp.realName,
        shareRatio: 1.0
      })
    }

    await appendItemsApi({
      sessionId: sessionDetail.value.session.id,
      items: [{
        productId: selectedProductId.value,
        quantity: appendQuantity.value,
        modifiers: appendModifiers.value,
        performers
      }],
      operatorType: 'WAITER'
    })

    ElMessage.success('动态追加成功！')
    appendDialogVisible.value = false
    sessionDetail.value = await getSessionDetailApi(sessionDetail.value.session.id)
    loadSpaces()
  } catch (e) {
    console.error(e)
  } finally {
    appending.value = false
  }
}

const handleGoBilling = () => {
  drawerVisible.value = false
  router.push({ path: '/cashier', query: { sessionId: String(sessionDetail.value.session.id) } })
}

const handleResetSpace = async (spaceId: number) => {
  try {
    try {
      await resetSpaceApi(spaceId)
    } catch (err) {}
    systemData.resetSpace(spaceId)
    ElMessage.success('空间已成功复位为空闲状态')
    loadSpaces()
  } catch (e) {
    console.error(e)
  }
}

const handleCancelItem = (itemId: number) => {
  ElMessageBox.prompt('请输入退订理由', '退单确认', {
    confirmButtonText: '确定退单',
    cancelButtonText: '取消'
  }).then(async ({ value }) => {
    try {
      await cancelLineItemApi(itemId, { reason: value || '顾客退单' })
      ElMessage.success('退单成功')
      sessionDetail.value = await getSessionDetailApi(sessionDetail.value.session.id)
    } catch (e) {
      console.error(e)
    }
  })
}

const handleOpenCreateSpace = () => {
  router.push('/rooms')
}

const handleOpenTransferDialog = () => {
  ElMessage.info('转台功能可直接选择任意空闲工位')
}

onMounted(() => {
  loadSpaces()
  loadProducts()
  loadStoreMembersList()
})
</script>

<style scoped>
.session-board-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.board-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: #fff;
  padding: 12px 16px;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.space-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 16px;
}

.space-card {
  background-color: #fff;
  border-radius: 8px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s ease;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  min-height: 140px;
}

.space-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}

.card-idle {
  border-top: 4px solid #10b981;
}

.card-occupied {
  border-top: 4px solid #0284c7;
  background-color: #f0f9ff;
}

.card-dirty {
  border-top: 4px solid #f59e0b;
  background-color: #fffbeb;
}

.card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.space-code {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
}

.space-name {
  font-size: 14px;
  font-weight: 600;
  color: #334155;
  margin-top: 8px;
}

.space-zone {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 4px;
}

.card-bottom {
  margin-top: 16px;
  font-size: 12px;
}

.action-hint {
  display: flex;
  align-items: center;
  gap: 4px;
  color: #64748b;
}

.text-active {
  color: #0284c7;
  font-weight: 600;
}

.member-preview {
  margin-top: 6px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.preview-spent {
  font-size: 12px;
  color: #64748b;
}

.hippocampus-alert {
  background-color: #f5f3ff;
  border: 1px solid #ddd6fe;
  border-radius: 6px;
  padding: 10px;
  margin-bottom: 16px;
}

.alert-title {
  font-weight: 600;
  color: #6d28d9;
  font-size: 13px;
  margin-bottom: 6px;
}

.alert-item {
  font-size: 12px;
  color: #4c1d95;
  line-height: 1.4;
}

.session-summary-card {
  background-color: #f8fafc;
  padding: 12px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  margin-bottom: 16px;
}

.summary-line {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
  font-size: 13px;
}

.total-badge {
  font-size: 16px;
  font-weight: 700;
  color: #ef4444;
}

.drawer-actions {
  display: flex;
  gap: 8px;
  margin-bottom: 16px;
}

.batch-block {
  margin-bottom: 16px;
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  overflow: hidden;
}

.batch-header {
  background-color: #f1f5f9;
  padding: 8px 12px;
  font-size: 12px;
  display: flex;
  justify-content: space-between;
  color: #475569;
}

.item-row {
  padding: 10px 12px;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.item-name {
  font-size: 13px;
  font-weight: 600;
}

.item-mod {
  font-size: 11px;
  color: #64748b;
  margin-top: 2px;
}

.item-subtotal {
  font-weight: 600;
  margin-right: 12px;
}

.item-cancelled {
  opacity: 0.5;
  text-decoration: line-through;
}

.item-cancelled-text {
  font-size: 11px;
  color: #ef4444;
}
</style>
