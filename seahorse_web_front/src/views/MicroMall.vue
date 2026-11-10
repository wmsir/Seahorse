<template>
  <div class="micro-mall-page">
    <el-card shadow="hover">
      <template #header>
        <div class="header-box">
          <div class="header-left">
            <span class="title">🏬 微信微商城与线上自营</span>
            <el-tag effect="plain" type="primary">当前行业：{{ currentIndustryName }}</el-tag>
            <el-tag effect="plain" type="success">24小时不打烊 · 顾客自主购卡/选品 · 快递包邮到家</el-tag>
          </div>
          <div class="header-right">
            <el-button type="success" plain icon="Share" @click="openQrDialog = true">商城访问码</el-button>
            <el-button type="warning" plain icon="Refresh" @click="handleBatchSyncProducts">
              ⚡ 一键同步门店在售商品
            </el-button>
            <el-button type="primary" icon="Plus" @click="handleOpenShelfDialog">上架新商品</el-button>
          </div>
        </div>
      </template>

      <!-- 线上微商城Tab切换 -->
      <el-tabs v-model="activeTab">
        <!-- 1. 线上订单履约管理 -->
        <el-tab-pane label="📦 线上订单管理" name="orders">
          <div class="filter-row">
            <el-radio-group v-model="orderStatusFilter" size="default" @change="orderPage = 1">
              <el-radio-button label="ALL">全部线上订单 ({{ currentOrders.length }})</el-radio-button>
              <el-radio-button label="WAIT_PAY">待付款</el-radio-button>
              <el-radio-button label="PAID">已付款 (待履约/发货)</el-radio-button>
              <el-radio-button label="DELIVERED">已发货/已履约</el-radio-button>
              <el-radio-button label="COMPLETED">已完成</el-radio-button>
            </el-radio-group>

            <el-input
              v-model="orderKeyword"
              placeholder="搜索订单号/会员手机号/收货人"
              style="width: 250px;"
              clearable
              @clear="orderPage = 1"
            />
          </div>

          <el-table :data="paginatedOrders" stripe style="width: 100%; margin-top: 16px;">
            <el-table-column prop="orderNo" label="订单编号" width="160">
              <template #default="{ row }">
                <span class="order-no">{{ row.orderNo }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="productTitle" label="商品/项目明细" min-width="180">
              <template #default="{ row }">
                <b>{{ row.productTitle }}</b>
                <div style="font-size: 12px; color: #64748b;">单价：￥{{ row.price }} × {{ row.quantity }} 件</div>
              </template>
            </el-table-column>
            <el-table-column prop="buyerName" label="买家信息" width="160">
              <template #default="{ row }">
                <div>{{ row.buyerName }}</div>
                <div style="font-size: 12px; color: #64748b;">{{ row.buyerPhone }}</div>
              </template>
            </el-table-column>
            <el-table-column prop="deliveryType" label="配送/核销方式" width="130">
              <template #default="{ row }">
                <el-tag :type="row.deliveryType === 'EXPRESS' ? 'primary' : 'warning'" size="small">
                  {{ row.deliveryType === 'EXPRESS' ? '快递发货' : '到店核销' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="totalAmount" label="实付金额" width="120">
              <template #default="{ row }">
                <span style="color: #ea580c; font-weight: 700;">￥{{ Number(row.totalAmount || 0).toFixed(2) }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="orderTime" label="下单时间" width="160" />
            <el-table-column prop="status" label="订单状态" width="110">
              <template #default="{ row }">
                <el-tag :type="getOrderStatusTag(row.status)">{{ getOrderStatusName(row.status) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="170" fixed="right">
              <template #default="{ row }">
                <el-button link type="primary" v-if="row.status === 'PAID'" @click="handleShipOrder(row)">
                  {{ row.deliveryType === 'EXPRESS' ? '填写单号发货' : '核销扫码' }}
                </el-button>
                <el-button link type="primary" @click="handleViewOrderDetail(row)">详情</el-button>
              </template>
            </el-table-column>
            <template #empty>
              <div style="padding: 36px 0;">
                <el-empty description="暂无线上微商城订单数据，顾客在微信商城下单付款后将实时自动同步至此处" />
              </div>
            </template>
          </el-table>

          <!-- 分页器 -->
          <div class="pagination-bar">
            <el-pagination
              v-model:current-page="orderPage"
              v-model:page-size="orderPageSize"
              :page-sizes="[5, 10, 20]"
              layout="total, sizes, prev, pager, next, jumper"
              :total="filteredOrders.length"
            />
          </div>
        </el-tab-pane>

        <!-- 2. 微商城在售货架 -->
        <el-tab-pane label="🛍️ 商城货架上架管理" name="shelf">
          <!-- 上架与同步指导提示条 -->
          <div style="padding: 12px 16px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between;">
            <div style="font-size: 13px; color: #15803d; line-height: 1.6;">
              💡 <strong>微商城商品管理与门店同步规范：</strong>支持从【门店项目商品库】一键同步在售商品，也可录入微商城线上特供商品。支持独立设置商城线上特惠价、划线原价、线上库存配额及配送/核销方式（快递包邮 / 到店核销）。
            </div>
            <div style="display: flex; gap: 8px;">
              <el-button size="small" type="warning" plain icon="Refresh" @click="handleBatchSyncProducts">
                ⚡ 批量同步门店在售
              </el-button>
              <el-button size="small" type="primary" icon="Plus" @click="handleOpenShelfDialog">
                上架新商品
              </el-button>
            </div>
          </div>

          <div class="filter-row">
            <div style="display: flex; gap: 10px; align-items: center;">
              <el-input
                v-model="goodsKeyword"
                placeholder="搜索货架商品/规格/类目"
                style="width: 250px;"
                clearable
                @clear="goodsPage = 1"
              />
            </div>
            <div style="font-size: 13px; color: #64748b;">
              当前货架在售商品共 <b>{{ filteredGoods.length }}</b> 件
            </div>
          </div>

          <el-table :data="paginatedGoods" stripe style="width: 100%; margin-top: 16px;">
            <el-table-column prop="id" label="商品ID" width="90" />
            <el-table-column prop="title" label="商品名称" min-width="200">
              <template #default="{ row }">
                <b>{{ row.title }}</b>
                <el-tag size="small" type="danger" effect="plain" v-if="row.isHot" style="margin-left: 6px;">热销爆款</el-tag>
                <div v-if="row.description" style="font-size: 11.5px; color: #64748b; margin-top: 2px;">{{ row.description }}</div>
              </template>
            </el-table-column>
            <el-table-column prop="category" label="所属类目" width="130" />
            <el-table-column label="数据同步来源" width="130">
              <template #default="{ row }">
                <el-tag :type="row.syncSource === 'STORE_PRODUCT' ? 'success' : 'primary'" size="small" effect="plain">
                  {{ row.syncSource === 'STORE_PRODUCT' ? '🏪 门店库同步' : '✨ 商城专售' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="配送/核销方式" width="130">
              <template #default="{ row }">
                <el-tag size="small" :type="row.deliveryType === 'EXPRESS' ? 'primary' : (row.deliveryType === 'STORE_PICKUP' ? 'warning' : 'success')">
                  {{ row.deliveryType === 'EXPRESS' ? '快递包邮' : (row.deliveryType === 'STORE_PICKUP' ? '到店核销' : '快递+到店') }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="originalPrice" label="划线原价" width="100">
              <template #default="{ row }">
                <span style="color: #94a3b8; text-decoration: line-through;">￥{{ row.originalPrice }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="onlinePrice" label="商城特惠价" width="120">
              <template #default="{ row }">
                <span style="color: #ea580c; font-weight: 700; font-size: 15px;">￥{{ row.onlinePrice }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="sales" label="线上销量" width="100">
              <template #default="{ row }">
                <span>{{ row.sales }} 件</span>
              </template>
            </el-table-column>
            <el-table-column prop="stock" label="可售库存" width="100">
              <template #default="{ row }">
                <el-tag :type="row.stock <= 5 ? 'danger' : 'info'">{{ row.stock }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="onShelf" label="货架状态" width="100">
              <template #default="{ row }">
                <el-tag :type="row.onShelf ? 'success' : 'info'">{{ row.onShelf ? '已上架' : '已下架' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="200" fixed="right">
              <template #default="{ row }">
                <el-button link :type="row.onShelf ? 'warning' : 'success'" @click="handleToggleShelf(row)">
                  {{ row.onShelf ? '下架' : '上架' }}
                </el-button>
                <el-button link type="primary" @click="handleOpenEditGoods(row)">编辑商品</el-button>
                <el-button link type="danger" @click="handleDeleteGoods(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>

          <!-- 分页器 -->
          <div class="pagination-bar">
            <el-pagination
              v-model:current-page="goodsPage"
              v-model:page-size="goodsPageSize"
              :page-sizes="[5, 10, 20]"
              layout="total, sizes, prev, pager, next, jumper"
              :total="filteredGoods.length"
            />
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 商城二维码弹窗 -->
    <el-dialog v-model="openQrDialog" title="微信微商城直达码" width="400px">
      <div style="text-align: center; padding: 12px 0;">
        <div style="width: 180px; height: 180px; margin: 0 auto; background: #f0fdf4; border: 2px dashed #86efac; border-radius: 12px; display: flex; flex-direction: column; align-items: center; justify-content: center; color: #16a34a;">
          <el-icon style="font-size: 60px;"><Shop /></el-icon>
          <span style="font-size: 13px; margin-top: 6px; font-weight: 600;">微信在线商城小程序</span>
        </div>
        <p style="margin-top: 14px; font-size: 13px; color: #64748b;">海马智慧会员微商城 · 支持微信支付与会员储值本金安全免密抵扣</p>
      </div>
      <template #footer>
        <el-button type="primary" style="width: 100%;" @click="openQrDialog = false">复制商城直达链接</el-button>
      </template>
    </el-dialog>

    <!-- 发货弹窗 -->
    <el-dialog v-model="openShipDialog" title="订单发货处理" width="450px">
      <el-form label-width="90px">
        <el-form-item label="订单号">
          <el-input :model-value="currentOrder?.orderNo" disabled />
        </el-form-item>
        <el-form-item label="收件人">
          <el-input :model-value="currentOrder?.buyerName + ' ' + currentOrder?.buyerPhone" disabled />
        </el-form-item>
        <el-form-item label="快递物流">
          <el-select v-model="shipForm.expressCompany" style="width: 100%;">
            <el-option label="顺丰速运" value="SF" />
            <el-option label="中通快递" value="ZTO" />
            <el-option label="圆通速递" value="YTO" />
          </el-select>
        </el-form-item>
        <el-form-item label="运单号" required>
          <el-input v-model="shipForm.trackingNo" placeholder="请输入或扫描运单号" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openShipDialog = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmShip">确认发货并通知买家</el-button>
      </template>
    </el-dialog>

    <!-- 3. 上架新商品与商品库同步弹窗 -->
    <el-dialog
      v-model="openShelfDialog"
      title="🛍️ 上架微商城新商品与门店商品库同步"
      width="640px"
      destroy-on-close
    >
      <!-- 操作提示引导 -->
      <div style="padding: 12px 16px; background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; margin-bottom: 16px; font-size: 13px; color: #1e40af; line-height: 1.6;">
        💡 <strong>上架与数据同步指引：</strong>
        <div style="margin-top: 4px;">1. <b>从门店商品库挑选（推荐）</b>：系统直接读取门店现存在售实物商品，自动带出商品编码、原价与类目，支持设定线上独立特惠售价与库存配额；</div>
        <div>2. <b>全新录入</b>：可录入微商城线上专供定制品，支持一键反向同步建档至门店基础商品库。</div>
      </div>

      <el-form :model="shelfForm" label-width="115px">
        <el-form-item label="上架渠道模式" required>
          <el-radio-group v-model="shelfForm.mode" @change="handleShelfModeChange">
            <el-radio-button label="STORE_SYNC">🏪 从门店现有商品库同步 (推荐)</el-radio-button>
            <el-radio-button label="CUSTOM_NEW">✨ 全新录入微商城自营商品</el-radio-button>
          </el-radio-group>
        </el-form-item>

        <!-- 门店商品选择 (同步模式) -->
        <template v-if="shelfForm.mode === 'STORE_SYNC'">
          <el-form-item label="选择门店商品" required>
            <el-select
              v-model="shelfForm.selectedProductId"
              placeholder="请从门店在售商品中挑选"
              filterable
              style="width: 100%;"
              @change="handleSelectStoreProduct"
            >
              <el-option
                v-for="p in availableStoreProducts"
                :key="p.id"
                :label="`[${p.code}] ${p.name} - 门店价 ￥${p.price} (库存: ${p.stock || 50})`"
                :value="p.id"
              />
            </el-select>
          </el-form-item>
        </template>

        <el-form-item label="商品标题名称" required>
          <el-input v-model="shelfForm.title" placeholder="例如：摩洛哥坚果修护护发精油 100ml" />
        </el-form-item>

        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="所属商品类目" required>
              <el-input v-model="shelfForm.category" placeholder="例如：家居洗护 / 主厨私房" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="划线原价(元)" required>
              <el-input-number v-model="shelfForm.originalPrice" :min="0" :precision="2" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="微商城特惠价" required>
              <el-input-number v-model="shelfForm.onlinePrice" :min="0" :precision="2" style="width: 100%;" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="线上库存配额" required>
              <el-input-number v-model="shelfForm.stock" :min="1" :step="10" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="配送/履约方式" required>
          <el-radio-group v-model="shelfForm.deliveryType">
            <el-radio label="EXPRESS">📦 快递发货包邮到家</el-radio>
            <el-radio label="STORE_PICKUP">🏪 到店核销提货</el-radio>
            <el-radio label="BOTH">⚡ 两者兼备</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="爆款推荐标签">
          <el-switch v-model="shelfForm.isHot" active-text="标记为微商城首页爆款专区推荐" />
        </el-form-item>

        <el-form-item label="商品亮点图文">
          <el-input
            v-model="shelfForm.description"
            type="textarea"
            rows="2"
            placeholder="简述商品的成分亮点、适用人群或使用体验..."
          />
        </el-form-item>

        <el-form-item v-if="shelfForm.mode === 'CUSTOM_NEW'" label="同步至门店库">
          <el-checkbox v-model="shelfForm.syncBackToStore">
            同时将该商品建档至门店基础实物商品库（支持线下门店收银与扫码出库）
          </el-checkbox>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="openShelfDialog = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmShelfGoods">确认上架并同步至微信商城</el-button>
      </template>
    </el-dialog>

    <!-- 4. 编辑商品弹窗 -->
    <el-dialog
      v-model="openEditGoodsDialog"
      title="✏️ 编辑微商城在售商品"
      width="520px"
      destroy-on-close
    >
      <el-form v-if="editingGoods" :model="editGoodsForm" label-width="110px">
        <el-form-item label="商品名称">
          <el-input v-model="editGoodsForm.title" />
        </el-form-item>
        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="划线原价">
              <el-input-number v-model="editGoodsForm.originalPrice" :min="0" :precision="2" style="width: 100%;" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="微商城特惠价" required>
              <el-input-number v-model="editGoodsForm.onlinePrice" :min="0" :precision="2" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="线上库存配额" required>
          <el-input-number v-model="editGoodsForm.stock" :min="0" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="配送/核销方式">
          <el-radio-group v-model="editGoodsForm.deliveryType">
            <el-radio label="EXPRESS">快递包邮</el-radio>
            <el-radio label="STORE_PICKUP">到店核销</el-radio>
            <el-radio label="BOTH">两者兼备</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="爆款推荐">
          <el-switch v-model="editGoodsForm.isHot" active-text="热销爆款" />
        </el-form-item>
        <el-form-item label="商品描述">
          <el-input v-model="editGoodsForm.description" type="textarea" rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openEditGoodsDialog = false">取消</el-button>
        <el-button type="primary" @click="handleSaveEditGoods">保存修改</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useSystemDataStore } from '../stores/systemDataStore'

const systemData = useSystemDataStore()
const activeTab = ref('orders')

const industryMap: Record<string, string> = {
  BEAUTY: '美容美发美甲',
  RESTAURANT: '餐饮轻食/正餐',
  AUTO: '汽车养护维修',
  RETAIL: '专营零售'
}

const currentIndustryName = computed(() => {
  return industryMap[systemData.currentIndustry] || '智慧零售'
})

// 订单数据与分页
const orderStatusFilter = ref('ALL')
const orderKeyword = ref('')
const orderPage = ref(1)
const orderPageSize = ref(10)

// 依据当前租户状态与行业自洽初始化微商城订单 (新注册租户纯净零订单态，演示租户按行业提供范例数据)
const currentOrders = computed(() => {
  if (systemData.isNewTenant) {
    return []
  }
  return systemData.mallOrders || []
})

const filteredOrders = computed(() => {
  return currentOrders.value.filter(item => {
    if (orderStatusFilter.value !== 'ALL' && item.status !== orderStatusFilter.value) return false
    if (orderKeyword.value) {
      const q = orderKeyword.value.toLowerCase()
      return item.orderNo.toLowerCase().includes(q) || item.buyerName.includes(q) || item.buyerPhone.includes(q)
    }
    return true
  })
})

const paginatedOrders = computed(() => {
  const start = (orderPage.value - 1) * orderPageSize.value
  return filteredOrders.value.slice(start, start + orderPageSize.value)
})

const getOrderStatusTag = (status: string) => {
  switch (status) {
    case 'PAID': return 'warning'
    case 'DELIVERED': return 'primary'
    case 'COMPLETED': return 'success'
    case 'WAIT_PAY': return 'info'
    default: return 'info'
  }
}

const getOrderStatusName = (status: string) => {
  switch (status) {
    case 'PAID': return '已付款待发货'
    case 'DELIVERED': return '已发货/已通知'
    case 'COMPLETED': return '已完成'
    case 'WAIT_PAY': return '待付款'
    default: return status
  }
}

// 货架商品数据与分页 (直接响应式绑定 systemData.mallGoods)
const goodsKeyword = ref('')
const goodsCategoryFilter = ref('ALL')
const goodsPage = ref(1)
const goodsPageSize = ref(10)

const mallCategories = computed(() => {
  const cats = new Set<string>()
  systemData.mallGoods.forEach(g => {
    if (g.category) cats.add(g.category)
  })
  return Array.from(cats)
})

const currentGoods = computed(() => {
  return systemData.mallGoods
})

const filteredGoods = computed(() => {
  return currentGoods.value.filter(item => {
    if (goodsCategoryFilter.value && goodsCategoryFilter.value !== 'ALL' && item.category !== goodsCategoryFilter.value) {
      return false
    }
    if (goodsKeyword.value.trim()) {
      const q = goodsKeyword.value.trim().toLowerCase()
      return item.title.toLowerCase().includes(q) || item.category.toLowerCase().includes(q)
    }
    return true
  })
})

const paginatedGoods = computed(() => {
  const start = (goodsPage.value - 1) * goodsPageSize.value
  return filteredGoods.value.slice(start, start + goodsPageSize.value)
})

// 货架商品上架与编辑弹窗状态
const openShelfDialog = ref(false)
const shelfForm = ref({
  mode: 'STORE_SYNC' as 'STORE_SYNC' | 'CUSTOM_NEW',
  selectedProductId: undefined as number | undefined,
  title: '',
  category: '',
  onlinePrice: 99,
  originalPrice: 128,
  stock: 50,
  deliveryType: 'BOTH' as 'EXPRESS' | 'STORE_PICKUP' | 'BOTH',
  isHot: false,
  description: '',
  syncBackToStore: true
})

const availableStoreProducts = computed(() => {
  return systemData.products.filter(p => (p.status || 'ACTIVE') === 'ACTIVE')
})

const handleShelfModeChange = (mode: 'STORE_SYNC' | 'CUSTOM_NEW') => {
  if (mode === 'STORE_SYNC') {
    if (availableStoreProducts.value.length > 0) {
      handleSelectStoreProduct(availableStoreProducts.value[0].id)
    }
  } else {
    shelfForm.value.selectedProductId = undefined
    shelfForm.value.title = ''
    shelfForm.value.category = '线上商城特供'
    shelfForm.value.onlinePrice = 99
    shelfForm.value.originalPrice = 128
    shelfForm.value.stock = 50
    shelfForm.value.description = ''
  }
}

const handleSelectStoreProduct = (prodId?: number) => {
  const targetId = prodId || shelfForm.value.selectedProductId
  if (!targetId) return
  const prod = systemData.products.find(p => p.id === targetId)
  if (prod) {
    shelfForm.value.selectedProductId = prod.id
    shelfForm.value.title = prod.name
    shelfForm.value.category = prod.categoryName || prod.category || '精品商品'
    shelfForm.value.originalPrice = prod.price
    shelfForm.value.onlinePrice = prod.memberPrice ? prod.memberPrice : Math.round(prod.price * 0.9)
    shelfForm.value.stock = prod.stock || 50
    shelfForm.value.deliveryType = prod.type === 'SERVICE' ? 'STORE_PICKUP' : 'BOTH'
    shelfForm.value.description = prod.description || `${prod.name}，门店官方严选保真。`
  }
}

const handleOpenShelfDialog = () => {
  shelfForm.value = {
    mode: 'STORE_SYNC',
    selectedProductId: availableStoreProducts.value[0]?.id,
    title: '',
    category: '',
    onlinePrice: 99,
    originalPrice: 128,
    stock: 50,
    deliveryType: 'BOTH',
    isHot: false,
    description: '',
    syncBackToStore: true
  }
  if (availableStoreProducts.value.length > 0) {
    handleSelectStoreProduct(availableStoreProducts.value[0].id)
  }
  openShelfDialog.value = true
}

const handleConfirmShelfGoods = () => {
  if (!shelfForm.value.title.trim()) {
    ElMessage.warning('请输入商品标题名称')
    return
  }
  if (!shelfForm.value.category.trim()) {
    ElMessage.warning('请输入商品所属类目')
    return
  }

  if (shelfForm.value.mode === 'STORE_SYNC' && shelfForm.value.selectedProductId) {
    systemData.syncProductToMall(shelfForm.value.selectedProductId, {
      title: shelfForm.value.title.trim(),
      category: shelfForm.value.category.trim(),
      onlinePrice: Number(shelfForm.value.onlinePrice),
      originalPrice: Number(shelfForm.value.originalPrice),
      stock: Number(shelfForm.value.stock),
      deliveryType: shelfForm.value.deliveryType,
      isHot: shelfForm.value.isHot,
      description: shelfForm.value.description
    })
    ElMessage.success(`✅ 已成功将门店商品【${shelfForm.value.title}】同步上架至微商城货架！`)
  } else {
    // 全新录入
    let createdProdId: number | undefined
    if (shelfForm.value.syncBackToStore) {
      const createdProd = systemData.addProduct({
        name: shelfForm.value.title.trim(),
        category: shelfForm.value.category.trim(),
        categoryName: shelfForm.value.category.trim(),
        price: Number(shelfForm.value.originalPrice),
        memberPrice: Number(shelfForm.value.onlinePrice),
        cost: Math.round(Number(shelfForm.value.originalPrice) * 0.4),
        stock: Number(shelfForm.value.stock),
        unit: '件',
        type: 'RETAIL',
        description: shelfForm.value.description,
        isSyncMall: true
      })
      createdProdId = createdProd.id
    }

    systemData.addMallGoods({
      productId: createdProdId,
      title: shelfForm.value.title.trim(),
      category: shelfForm.value.category.trim(),
      onlinePrice: Number(shelfForm.value.onlinePrice),
      originalPrice: Number(shelfForm.value.originalPrice),
      stock: Number(shelfForm.value.stock),
      deliveryType: shelfForm.value.deliveryType,
      isHot: shelfForm.value.isHot,
      description: shelfForm.value.description,
      syncSource: createdProdId ? 'STORE_PRODUCT' : 'MALL_EXCLUSIVE'
    })
    ElMessage.success(`✅ 新商品【${shelfForm.value.title}】已成功上架并在微信微商城开售！${createdProdId ? '已同步建档至门店商品库。' : ''}`)
  }

  openShelfDialog.value = false
}

// 批量一键同步门店在售商品
const handleBatchSyncProducts = () => {
  const synced = systemData.syncAllProductsToMall()
  if (synced > 0) {
    ElMessage.success(`⚡ 批量同步完成！已成功将门店 ${synced} 件在售商品一键同步上架至微信微商城！`)
  } else {
    ElMessage.info('当前门店所有在售商品已处于微商城在售货架中，无需重复同步！')
  }
}

// 上下架切换
const handleToggleShelf = (row: any) => {
  const onShelf = systemData.toggleMallGoodsShelf(row.id)
  ElMessage.success(onShelf ? `【${row.title}】已上架并在微信端展示开售！` : `【${row.title}】已下架，微信商城已暂停展示！`)
}

// 编辑商品
const openEditGoodsDialog = ref(false)
const editingGoods = ref<any>(null)
const editGoodsForm = ref({
  id: 0,
  title: '',
  originalPrice: 0,
  onlinePrice: 0,
  stock: 0,
  deliveryType: 'BOTH' as 'EXPRESS' | 'STORE_PICKUP' | 'BOTH',
  isHot: false,
  description: ''
})

const handleOpenEditGoods = (row: any) => {
  editingGoods.value = row
  editGoodsForm.value = {
    id: row.id,
    title: row.title,
    originalPrice: row.originalPrice || row.onlinePrice,
    onlinePrice: row.onlinePrice,
    stock: row.stock,
    deliveryType: row.deliveryType || 'BOTH',
    isHot: !!row.isHot,
    description: row.description || ''
  }
  openEditGoodsDialog.value = true
}

const handleSaveEditGoods = () => {
  if (!editGoodsForm.value.title.trim()) {
    ElMessage.warning('商品名称不能为空')
    return
  }
  systemData.updateMallGoods(editGoodsForm.value.id, {
    title: editGoodsForm.value.title.trim(),
    originalPrice: Number(editGoodsForm.value.originalPrice),
    onlinePrice: Number(editGoodsForm.value.onlinePrice),
    stock: Number(editGoodsForm.value.stock),
    deliveryType: editGoodsForm.value.deliveryType,
    isHot: editGoodsForm.value.isHot,
    description: editGoodsForm.value.description
  })
  openEditGoodsDialog.value = false
  ElMessage.success('商品信息与价格配置已更新并同步！')
}

// 发货操作
const openShipDialog = ref(false)
const currentOrder = ref<any>(null)
const shipForm = ref({ expressCompany: 'SF', trackingNo: '' })

const handleShipOrder = (row: any) => {
  currentOrder.value = row
  shipForm.value.trackingNo = 'SF' + Math.floor(1000000000 + Math.random() * 9000000000)
  openShipDialog.value = true
}

const handleConfirmShip = () => {
  if (!shipForm.value.trackingNo) {
    ElMessage.warning('请输入运单号')
    return
  }
  if (currentOrder.value) {
    currentOrder.value.status = 'DELIVERED'
    systemData.shipMallOrder(currentOrder.value.orderNo, shipForm.value.expressCompany, shipForm.value.trackingNo)
    ElMessage.success('发货成功！微信端买家已收到出库与物流通知！')
  }
  openShipDialog.value = false
}

const handleViewOrderDetail = (row: any) => {
  ElMessageBox.alert(
    `订单编号：${row.orderNo}<br>商品：${row.productTitle}<br>买家：${row.buyerName} (${row.buyerPhone})<br>实付：￥${row.totalAmount}<br>配送方式：${row.deliveryType === 'EXPRESS' ? '快递包邮' : '到店核销'}`,
    '订单明细',
    { dangerouslyUseHTMLString: true }
  )
}

const openQrDialog = ref(false)

const handleDeleteGoods = (row: any) => {
  ElMessageBox.confirm(`确定要从微商城中删除【${row.title}】吗？`, '安全提示', {
    confirmButtonText: '删除',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    systemData.deleteMallGoods(row.id)
    ElMessage.success('删除成功')
  })
}
</script>

<style scoped>
.micro-mall-page {
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

.header-right {
  display: flex;
  gap: 12px;
}

.filter-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.order-no {
  font-family: monospace;
  font-weight: 600;
  color: #0284c7;
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
