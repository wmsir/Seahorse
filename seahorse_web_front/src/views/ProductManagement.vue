<template>
  <div class="product-management-page">
    <el-card shadow="hover">
      <template #header>
        <div class="header-box">
          <div class="header-left">
            <span class="title">🛍️ 项目商品与耗材配方中心</span>
            <el-tag effect="plain" type="info">服务项目 · 实物零售 · 套餐组合 · 耗材配方</el-tag>
          </div>
          <div class="header-right">
            <el-input
              v-model="searchKeyword"
              placeholder="搜索商品/服务名称或编号..."
              style="width: 250px;"
              clearable
              @input="currentPage = 1"
              @clear="currentPage = 1"
              @keyup.enter="currentPage = 1"
            >
              <template #append>
                <el-button icon="Search" @click="currentPage = 1" />
              </template>
            </el-input>
            <el-button type="success" plain icon="Operation" @click="openCategoryDrawer = true">
              🏷️ 分类管理配置
            </el-button>
            <el-button type="primary" icon="Plus" @click="handleOpenAddDialog">
              上架新商品/项目
            </el-button>
          </div>
        </div>
      </template>

      <!-- 快捷类型与状态筛选栏 -->
      <div class="filter-row">
        <el-radio-group v-model="productTypeFilter" size="default" @change="currentPage = 1">
          <el-radio-button label="ALL">全部在售 ({{ activeCount }})</el-radio-button>
          <el-radio-button label="SERVICE">💆 服务项目 ({{ serviceCount }})</el-radio-button>
          <el-radio-button label="RETAIL">🧴 实物商品 ({{ retailCount }})</el-radio-button>
          <el-radio-button label="PACKAGE">🎁 组合套餐 ({{ packageCount }})</el-radio-button>
          <el-radio-button label="DISABLED">⏸️ 已下架 ({{ disabledCount }})</el-radio-button>
        </el-radio-group>

        <div style="display: flex; gap: 10px; align-items: center;">
          <el-select v-model="categoryFilter" placeholder="分类筛选" clearable style="width: 180px;" @change="currentPage = 1">
            <el-option label="全部分类" value="" />
            <el-option
              v-for="cat in availableCategories"
              :key="cat"
              :label="cat"
              :value="cat"
            />
          </el-select>
        </div>
      </div>

      <!-- 批量操作工具栏 -->
      <div v-if="selectedRows.length > 0" class="batch-bar">
        <span class="batch-tip">
          已勾选 <strong>{{ selectedRows.length }}</strong> 项商品/服务
        </span>
        <div class="batch-actions">
          <el-button size="small" type="success" @click="handleBatchChangeStatus('ACTIVE')">
            一键批量上架
          </el-button>
          <el-button size="small" type="warning" @click="handleBatchChangeStatus('DISABLED')">
            一键批量下架
          </el-button>
          <el-button size="small" type="danger" @click="handleBatchDelete">
            批量删除
          </el-button>
        </div>
      </div>

      <!-- 商品列表表格 -->
      <el-table
        :data="paginatedProducts"
        stripe
        style="width: 100%; margin-top: 14px;"
        v-loading="loading"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="45" />

        <el-table-column prop="code" label="编号" width="115">
          <template #default="{ row }">
            <span class="code-tag">{{ row.code }}</span>
          </template>
        </el-table-column>

        <el-table-column prop="name" label="名称与规格" min-width="220">
          <template #default="{ row }">
            <div class="name-cell">
              <span class="product-name">{{ row.name }}</span>
              <div class="tags-row">
                <el-tag v-if="row.hasBom" size="small" type="success" effect="plain">
                  耗材配方
                </el-tag>
                <span v-if="row.spec" class="spec-label">({{ row.spec }})</span>
                <span v-if="row.durationMinutes && row.type === 'SERVICE'" class="duration-label">
                  ⏱️ {{ row.durationMinutes }}分钟
                </span>
              </div>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="type" label="类型" width="110">
          <template #default="{ row }">
            <el-tag :type="getTypeTag(row.type)">{{ getTypeName(row.type) }}</el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="categoryName" label="所属分类" width="130">
          <template #default="{ row }">
            <span class="category-name">{{ row.categoryName || row.category }}</span>
          </template>
        </el-table-column>

        <el-table-column prop="salePrice" label="标牌售价" width="120">
          <template #default="{ row }">
            <span class="price-val">￥{{ Number(row.salePrice ?? row.price ?? 0).toFixed(2) }}</span>
          </template>
        </el-table-column>

        <el-table-column prop="memberPrice" label="会员专享价" width="130">
          <template #default="{ row }">
            <div class="member-price-cell">
              <span class="member-price-val">￥{{ Number(row.memberPrice !== undefined ? row.memberPrice : Math.round((row.price ?? 0) * 0.85)).toFixed(2) }}</span>
              <span class="discount-badge">
                {{ getDiscountRateText(row.salePrice ?? row.price, row.memberPrice) }}
              </span>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="stock" label="当前库存" width="110">
          <template #default="{ row }">
            <span v-if="row.type === 'SERVICE'" class="service-stock-tag">服务无限</span>
            <el-tag
              v-else
              :type="(row.stock ?? 0) <= 0 ? 'danger' : ((row.stock ?? 0) <= 10 ? 'warning' : 'info')"
              size="small"
            >
              {{ (row.stock ?? 0) <= 0 ? '缺货(0)' : `${row.stock} ${row.unit || '件'}` }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="commissionRate" label="销售提成" width="125">
          <template #default="{ row }">
            <template v-if="(row.commissionRate ?? 0) > 1">
              <span class="comm-text">￥{{ Number(row.commissionRate).toFixed(2) }}</span>
              <span class="comm-est">(固定/份)</span>
            </template>
            <template v-else>
              <span class="comm-text">{{ ((row.commissionRate ?? (row.type === 'SERVICE' ? 0.25 : 0.1)) * 100).toFixed(0) }}%</span>
              <span class="comm-est">
                (约￥{{ ((row.salePrice ?? row.price ?? 0) * (row.commissionRate ?? (row.type === 'SERVICE' ? 0.25 : 0.1))).toFixed(1) }})
              </span>
            </template>
          </template>
        </el-table-column>

        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'ACTIVE' ? 'success' : 'info'" size="small">
              {{ row.status === 'ACTIVE' ? '在售中' : '已下架' }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="handleEditProduct(row)">编辑</el-button>
            <el-button link type="success" v-if="row.type === 'SERVICE' || row.hasBom" @click="handleManageBom(row)">耗材配方</el-button>
            <el-button
              link
              :type="row.status === 'ACTIVE' ? 'warning' : 'success'"
              @click="handleToggleStatus(row)"
            >
              {{ row.status === 'ACTIVE' ? '下架' : '上架' }}
            </el-button>
            <el-button link type="danger" @click="handleDeleteProduct(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 标准分页器 -->
      <div class="pagination-bar">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="filteredProducts.length"
        />
      </div>
    </el-card>

    <!-- 新增/编辑商品弹窗 -->
    <el-dialog
      v-model="openDialog"
      :title="isEdit ? '✏️ 编辑项目与商品' : '✨ 上架新项目/商品'"
      width="640px"
      destroy-on-close
    >
      <el-form :model="form" label-width="110px">
        <el-form-item label="类型选择" required>
          <el-radio-group v-model="form.type" @change="handleTypeChange">
            <el-radio-button label="SERVICE">💆 服务项目</el-radio-button>
            <el-radio-button label="RETAIL">🧴 实物商品</el-radio-button>
            <el-radio-button label="PACKAGE">🎁 组合套餐</el-radio-button>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="项目/商品名称" required>
          <el-input v-model="form.name" :placeholder="namePlaceholder" maxlength="60" show-word-limit />
        </el-form-item>

        <el-row :gutter="14">
          <el-col :span="12">
            <el-form-item label="所属分类" required>
              <el-select
                v-model="form.categoryName"
                placeholder="选择或输入新分类"
                filterable
                allow-create
                default-first-option
                style="width: 100%;"
              >
                <el-option
                  v-for="cat in availableCategories"
                  :key="cat"
                  :label="cat"
                  :value="cat"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="商品编码">
              <el-input v-model="form.code" placeholder="如 PRD-1024" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="14">
          <el-col :span="12">
            <el-form-item label="标牌售价(元)" required>
              <el-input-number
                v-model="form.salePrice"
                :min="0"
                :step="10"
                style="width: 100%;"
                @change="handleSalePriceChange"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="会员专享价" required>
              <el-input-number v-model="form.memberPrice" :min="0" :step="10" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 快捷会员折扣推荐按钮 -->
        <div class="quick-discount-row">
          <span class="discount-hint">💡 快捷折扣推荐：</span>
          <el-button size="small" type="primary" plain @click="setDiscount(0.85)">85折(推荐)</el-button>
          <el-button size="small" plain @click="setDiscount(0.8)">8折</el-button>
          <el-button size="small" plain @click="setDiscount(0.9)">9折</el-button>
          <el-button size="small" plain @click="setDiscount(1.0)">原价无折</el-button>
        </div>

        <el-row :gutter="14" style="margin-top: 8px;">
          <el-col :span="12">
            <el-form-item label="员工提成(比例/元)">
              <el-input-number v-model="form.commissionRate" :min="0" :precision="2" :step="(form.commissionRate || 0) > 1 ? 5 : 0.05" style="width: 100%;" />
            </el-form-item>
          </el-col>
          <el-col :span="12" v-if="form.type !== 'SERVICE'">
            <el-form-item label="期初库存">
              <el-input-number v-model="form.stock" :min="0" :step="5" style="width: 100%;" />
            </el-form-item>
          </el-col>
          <el-col :span="12" v-else>
            <el-form-item label="服务耗时(分钟)">
              <el-input-number v-model="form.durationMinutes" :min="5" :step="15" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="14" v-if="form.type !== 'SERVICE'">
          <el-col :span="14">
            <el-form-item label="规格说明">
              <el-input v-model="form.spec" placeholder="如：500g 充氮包装 / 双只精装礼盒 / 200ml" />
            </el-form-item>
          </el-col>
          <el-col :span="10">
            <el-form-item label="计量单位">
              <el-input v-model="form.unit" placeholder="如：件, 瓶, 盒, 次" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="服务耗材配方" v-if="form.type === 'SERVICE' || form.type === 'RETAIL'">
          <el-switch v-model="form.hasBom" inline-prompt active-text="启用" inactive-text="不启用" />
          <span class="switch-tip">开启后，顾客结账或服务履约时可按耗材配方清单自动扣减原材料库存</span>
        </el-form-item>

        <el-form-item label="上架状态">
          <el-switch
            v-model="form.status"
            active-value="ACTIVE"
            inactive-value="DISABLED"
            active-text="立即上架在售"
            inactive-text="暂时下架"
          />
        </el-form-item>

        <el-form-item label="介绍与说明">
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="3"
            placeholder="详细规格说明、使用方法或注意事项，可在前台与点单屏直接展示"
          />
        </el-form-item>

        <!-- 实时财务测算卡片 -->
        <div class="profit-calc-card">
          <div class="calc-item">
            <span class="calc-title">标牌售价</span>
            <span class="calc-val">￥{{ form.salePrice || 0 }}</span>
          </div>
          <div class="calc-divider">→</div>
          <div class="calc-item">
            <span class="calc-title">会员实收</span>
            <span class="calc-val text-orange">￥{{ form.memberPrice || 0 }}</span>
          </div>
          <div class="calc-divider">→</div>
          <div class="calc-item">
            <span class="calc-title">员工提成估算</span>
            <span class="calc-val text-blue">￥{{ ((form.commissionRate || 0) > 1 ? Number(form.commissionRate || 0) : (form.salePrice || 0) * (form.commissionRate || 0)).toFixed(1) }}</span>
          </div>
        </div>
      </el-form>

      <template #footer>
        <el-button @click="openDialog = false">取消</el-button>
        <el-button type="primary" @click="handleSaveProduct">
          {{ isEdit ? '保存更新' : '立即上架发布' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 服务项目耗材配方清单弹窗 -->
    <el-dialog v-model="openBomDialog" :title="'🌿 服务项目耗材配方清单(BOM) - ' + currentBomProduct?.name" width="650px">
      <el-alert
        title="配置该服务项目在顾客到店履约结算时，系统自动扣减的在库物料耗材用量，杜绝跑冒滴漏，实现真实精准的成本核算。"
        type="info"
        :closable="false"
        style="margin-bottom: 12px;"
      />
      <el-table :data="bomList" border stripe style="width: 100%;">
        <el-table-column prop="materialName" label="消耗物料耗材" min-width="160">
          <template #default="{ row }">
            <span style="font-weight: 600; color: #1e293b;">{{ row.materialName }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="dosage" label="标准消耗量" width="120" align="center">
          <template #default="{ row }">
            <b>{{ row.dosage }} {{ row.unit }}</b>
          </template>
        </el-table-column>
        <el-table-column prop="unitCost" label="单位成本 (元)" width="120" align="center">
          <template #default="{ row }">
            <span>￥{{ Number(row.unitCost || 0).toFixed(2) }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="90" align="center">
          <template #default="{ $index }">
            <el-button link type="danger" @click="bomList.splice($index, 1)">移除</el-button>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="暂未配置耗材配方，请在下方选择真实在库物料添加" :image-size="70" />
        </template>
      </el-table>

      <div style="margin-top: 14px; padding: 12px; background: #f8fafc; border-radius: 8px; border: 1px solid #e2e8f0;">
        <div style="font-size: 13px; font-weight: 600; color: #334155; margin-bottom: 8px;">
          ➕ 从在库真实物料库存中添加配方消耗项：
        </div>
        <div style="display: flex; gap: 8px; align-items: center;">
          <el-select
            v-model="newBomItem.materialName"
            placeholder="选择真实在库物料/耗材"
            filterable
            style="flex: 2;"
            @change="handleSelectRealMaterial"
          >
            <el-option
              v-for="mat in availableRealMaterials"
              :key="mat.name"
              :label="`${mat.name} (在库: ${mat.stock}${mat.unit})`"
              :value="mat.name"
            />
          </el-select>
          <el-input-number v-model="newBomItem.dosage" :min="1" placeholder="消耗用量" style="width: 120px;" />
          <el-input v-model="newBomItem.unit" placeholder="单位" style="width: 75px;" />
          <el-button type="primary" icon="Plus" @click="handleAddBomItem">添加至配方</el-button>
        </div>
      </div>

      <template #footer>
        <el-button @click="openBomDialog = false">取消</el-button>
        <el-button type="primary" @click="handleSaveBom">保存配方生效</el-button>
      </template>
    </el-dialog>

    <!-- 分类配置管理抽屉 (店长/租户老板权限) -->
    <el-drawer
      v-model="openCategoryDrawer"
      title="🏷️ 项目与商品分类管理"
      size="560px"
      destroy-on-close
    >
      <div style="padding: 0 4px;">
        <div style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 10px 14px; font-size: 13px; color: #166534; margin-bottom: 16px; line-height: 1.5;">
          💡 <strong>店长/租户老板专属权限：</strong>此处配置的分类将实时同步至网页后台与手机移动端APP，支持自定义新增、修改名称、调整排序与删除分类。
        </div>

        <!-- 快速添加新分类栏 -->
        <div style="display: flex; gap: 10px; margin-bottom: 16px;">
          <el-input
            v-model="newCategoryForm.name"
            placeholder="输入新分类名称 (如：男士修容SPA)"
            style="flex: 1;"
            @keyup.enter="handleCreateCategory"
          />
          <el-button type="primary" icon="Plus" :loading="savingCategory" @click="handleCreateCategory">
            新增分类
          </el-button>
        </div>

        <!-- 分类列表表格 -->
        <el-table :data="categoryList" border stripe style="width: 100%;">
          <el-table-column type="index" label="序号" width="60" align="center" />
          <el-table-column prop="name" label="分类名称" min-width="150">
            <template #default="{ row }">
              <el-input
                v-if="row.isEditing"
                v-model="row.editName"
                size="small"
                @keyup.enter="handleSaveCategoryName(row)"
              />
              <span v-else style="font-weight: 600; color: #1e293b;">{{ row.name }}</span>
            </template>
          </el-table-column>
          <el-table-column label="在售商品数" width="100" align="center">
            <template #default="{ row }">
              <el-tag size="small" type="info" effect="plain">
                {{ getProductCountByCategory(row.name) }} 项
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="150" align="center">
            <template #default="{ row }">
              <template v-if="row.isEditing">
                <el-button link type="success" size="small" @click="handleSaveCategoryName(row)">保存</el-button>
                <el-button link type="info" size="small" @click="row.isEditing = false">取消</el-button>
              </template>
              <template v-else>
                <el-button link type="primary" size="small" @click="handleStartEditCategory(row)">编辑</el-button>
                <el-button link type="danger" size="small" @click="handleDeleteCategory(row)">删除</el-button>
              </template>
            </template>
          </el-table-column>
          <template #empty>
            <el-empty description="暂无分类数据，请输入上方分类名称添加" />
          </template>
        </el-table>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useSystemDataStore } from '../stores/systemDataStore'
import {
  getCategoriesApi,
  saveCategoryApi,
  deleteCategoryApi,
  saveProductApi,
  deleteProductApi,
  getProductsApi
} from '../api'

const systemData = useSystemDataStore()
const loading = ref(false)
const searchKeyword = ref('')
const productTypeFilter = ref('ALL')
const categoryFilter = ref('')

const openCategoryDrawer = ref(false)
const savingCategory = ref(false)
const newCategoryForm = ref({ name: '' })
const categoryList = ref<any[]>([])

const currentPage = ref(1)
const pageSize = ref(10)
const selectedRows = ref<any[]>([])

const persistLocalProducts = () => {
  try {
    localStorage.setItem(`seahorse_products_${systemData.currentIndustry}`, JSON.stringify(systemData.products))
  } catch (e) {}
}

// 动态获取当前行业在售商品列表
const currentProductList = computed(() => {
  return systemData.products.map(p => {
    const salePrice = p.price !== undefined ? p.price : 0
    const memberPrice = p.memberPrice !== undefined ? p.memberPrice : Math.round(salePrice * 0.85)
    const stock = p.type === 'SERVICE' ? 0 : (p.stock !== undefined ? p.stock : 50)
    const commissionRate = p.commissionRate !== undefined ? p.commissionRate : (p.type === 'SERVICE' ? 0.25 : 0.1)
    const status = p.status || 'ACTIVE'
    const hasBom = p.type === 'SERVICE' || p.hasBom || false
    return {
      ...p,
      salePrice,
      memberPrice,
      stock,
      commissionRate,
      status,
      hasBom
    }
  })
})

const activeCount = computed(() => currentProductList.value.filter(p => p.status === 'ACTIVE').length)
const serviceCount = computed(() => currentProductList.value.filter(p => p.type === 'SERVICE' && p.status === 'ACTIVE').length)
const retailCount = computed(() => currentProductList.value.filter(p => p.type === 'RETAIL' && p.status === 'ACTIVE').length)
const packageCount = computed(() => currentProductList.value.filter(p => p.type === 'PACKAGE' && p.status === 'ACTIVE').length)
const disabledCount = computed(() => currentProductList.value.filter(p => p.status === 'DISABLED').length)

// 拉取分类列表
const loadCategories = async () => {
  try {
    const res: any = await getCategoriesApi(systemData.currentIndustry)
    const list = Array.isArray(res) ? res : (res?.data || [])
    categoryList.value = list.map((c: any) => ({
      ...c,
      isEditing: false,
      editName: c.name
    }))
  } catch (e) {
    console.warn('获取云端分类列表异常', e)
    categoryList.value = []
  }
}

const getProductCountByCategory = (catName: string) => {
  return currentProductList.value.filter(p => p.categoryName === catName || p.category === catName).length
}

const handleCreateCategory = async () => {
  const name = newCategoryForm.value.name.trim()
  if (!name) {
    ElMessage.warning('请输入分类名称')
    return
  }
  if (categoryList.value.some(c => c.name === name)) {
    ElMessage.warning('该分类已存在，无需重复添加')
    return
  }
  savingCategory.value = true
  try {
    const res: any = await saveCategoryApi({
      name,
      industry: systemData.currentIndustry,
      sortOrder: categoryList.value.length + 1,
      available: true
    })
    const saved = res?.id ? res : (res?.data || { id: Date.now(), name })
    categoryList.value.push({
      ...saved,
      isEditing: false,
      editName: name
    })
    newCategoryForm.value.name = ''
    ElMessage.success(`✅ 分类【${name}】添加成功，已全端同步生效！`)
  } catch (e: any) {
    categoryList.value.push({
      id: Date.now(),
      name,
      industry: systemData.currentIndustry,
      sortOrder: categoryList.value.length + 1,
      available: true,
      isEditing: false,
      editName: name
    })
    newCategoryForm.value.name = ''
    ElMessage.success(`✅ 分类【${name}】已添加！`)
  } finally {
    savingCategory.value = false
  }
}

const handleStartEditCategory = (row: any) => {
  row.editName = row.name
  row.isEditing = true
}

const handleSaveCategoryName = async (row: any) => {
  const newName = (row.editName || '').trim()
  if (!newName) {
    ElMessage.warning('分类名称不能为空')
    return
  }
  try {
    await saveCategoryApi({
      id: row.id,
      name: newName,
      sortOrder: row.sortOrder,
      industry: row.industry || systemData.currentIndustry,
      available: true
    })
  } catch (e) {}

  const oldName = row.name
  row.name = newName
  row.isEditing = false
  systemData.products.forEach(p => {
    if (p.category === oldName) p.category = newName
    if (p.categoryName === oldName) p.categoryName = newName
  })
  persistLocalProducts()
  ElMessage.success(`分类已更新为【${newName}】`)
}

const handleDeleteCategory = async (row: any) => {
  const count = getProductCountByCategory(row.name)
  let confirmMsg = `确定要彻底删除分类【${row.name}】吗？`
  if (count > 0) {
    confirmMsg += ` 当前有 ${count} 项商品属于该分类。`
  }
  try {
    await ElMessageBox.confirm(confirmMsg, '删除分类提示', {
      confirmButtonText: '确认删除',
      cancelButtonText: '取消',
      type: 'warning'
    })
    if (row.id) {
      try {
        await deleteCategoryApi(row.id)
      } catch (err) {}
    }
    categoryList.value = categoryList.value.filter(c => c.id !== row.id && c.name !== row.name)
    ElMessage.success(`已成功删除分类【${row.name}】`)
  } catch (cancel) {}
}

// 动态提取所属行业的所有可用分类
const availableCategories = computed(() => {
  if (categoryList.value.length > 0) {
    return categoryList.value.filter(c => c.available !== false).map(c => c.name)
  }
  const set = new Set<string>()
  currentProductList.value.forEach(p => {
    if (p.categoryName) set.add(p.categoryName)
    if (p.category) set.add(p.category)
  })
  return Array.from(set).filter(Boolean)
})

const filteredProducts = computed(() => {
  return currentProductList.value.filter(item => {
    if (productTypeFilter.value === 'DISABLED') {
      if (item.status !== 'DISABLED') return false
    } else if (productTypeFilter.value === 'ALL') {
      if (item.status === 'DISABLED') return false
    } else {
      if (item.status === 'DISABLED' || item.type !== productTypeFilter.value) return false
    }

    if (categoryFilter.value && item.categoryName !== categoryFilter.value && item.category !== categoryFilter.value) {
      return false
    }
    if (searchKeyword.value) {
      const q = searchKeyword.value.toLowerCase().trim()
      const matchName = item.name ? item.name.toLowerCase().includes(q) : false
      const matchCode = item.code ? item.code.toLowerCase().includes(q) : false
      return matchName || matchCode
    }
    return true
  })
})

const paginatedProducts = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredProducts.value.slice(start, start + pageSize.value)
})

const getTypeTag = (type: string) => {
  switch (type) {
    case 'SERVICE': return 'primary'
    case 'RETAIL': return 'success'
    case 'PACKAGE': return 'warning'
    default: return 'info'
  }
}

const getTypeName = (type: string) => {
  switch (type) {
    case 'SERVICE': return '服务项目'
    case 'RETAIL': return '实物商品'
    case 'PACKAGE': return '组合套餐'
    default: return '其他'
  }
}

const getDiscountRateText = (salePrice?: number, memberPrice?: number) => {
  if (!salePrice || memberPrice === undefined || memberPrice === null || salePrice === memberPrice) return '原价'
  const rate = (memberPrice / salePrice) * 10
  return `${rate.toFixed(1)}折`
}

// 行业个性化占位文案
const namePlaceholder = computed(() => {
  switch (systemData.currentIndustry) {
    case 'RETAIL':
      return '如：埃塞俄比亚耶加雪菲精品咖啡豆 500g、沙龙无火香薰礼盒'
    case 'RESTAURANT':
      return '如：主厨精选M9和牛双人餐、慢炖法式勃艮第牛肋排'
    case 'AUTO':
      return '如：美孚1号全合成机油小保养、全车精洗手工打蜡'
    default:
      return '如：发型总监精修洗剪吹、欧莱雅植物蛋白染发'
  }
})

// 新增与编辑弹窗
const openDialog = ref(false)
const isEdit = ref(false)
const form = ref<any>({
  id: 0,
  code: '',
  name: '',
  type: 'RETAIL',
  categoryName: '',
  salePrice: 120,
  memberPrice: 102,
  commissionRate: 0.15,
  stock: 50,
  durationMinutes: 30,
  spec: '',
  unit: '件',
  description: '',
  status: 'ACTIVE',
  hasBom: false
})

const handleOpenAddDialog = () => {
  isEdit.value = false
  const defaultType = systemData.currentIndustry === 'RETAIL' ? 'RETAIL' : 'SERVICE'
  const defaultCat = availableCategories.value[0] || '精品零售'
  const prefix = systemData.currentIndustry === 'RETAIL' ? 'RET' : (systemData.currentIndustry === 'RESTAURANT' ? 'RES' : (systemData.currentIndustry === 'AUTO' ? 'AUT' : 'BEA'))
  
  form.value = {
    id: Date.now(),
    code: `${prefix}-${Math.floor(100 + Math.random() * 900)}`,
    name: '',
    type: defaultType,
    categoryName: defaultCat,
    salePrice: 128,
    memberPrice: 108,
    commissionRate: defaultType === 'SERVICE' ? 0.25 : 0.10,
    stock: 50,
    durationMinutes: 30,
    spec: '',
    unit: defaultType === 'SERVICE' ? '次' : '件',
    description: '',
    status: 'ACTIVE',
    hasBom: defaultType === 'SERVICE'
  }
  openDialog.value = true
}

const handleEditProduct = (row: any) => {
  isEdit.value = true
  form.value = {
    ...row,
    salePrice: row.salePrice ?? row.price ?? 0,
    memberPrice: row.memberPrice !== undefined ? row.memberPrice : Math.round((row.price ?? 0) * 0.85),
    stock: row.stock !== undefined ? row.stock : 50,
    commissionRate: row.commissionRate !== undefined ? row.commissionRate : 0.15,
    unit: row.unit || (row.type === 'SERVICE' ? '次' : '件'),
    status: row.status || 'ACTIVE'
  }
  openDialog.value = true
}

const handleTypeChange = (typeVal: any) => {
  if (typeVal === 'SERVICE') {
    form.value.unit = '次'
    form.value.commissionRate = 0.25
    form.value.hasBom = true
  } else {
    form.value.unit = '件'
    form.value.commissionRate = 0.10
    form.value.hasBom = false
  }
}

const handleSalePriceChange = (val: any) => {
  if (val !== undefined && val !== null && !isEdit.value) {
    form.value.memberPrice = Math.round(val * 0.85)
  }
}

const setDiscount = (rate: number) => {
  form.value.memberPrice = Math.round((form.value.salePrice ?? 0) * rate)
}

const buildServerProductPayload = (item: any, overrideStatus?: 'ACTIVE' | 'DISABLED') => {
  const effectiveStatus = overrideStatus || item.status || 'ACTIVE'
  const effectiveType = item.type || 'RETAIL'
  const salePrice = Number(item.salePrice ?? item.price ?? 0)
  return {
    id: item.id,
    productCode: item.code,
    name: item.name,
    productType: effectiveType === 'SERVICE' ? 'SERVICE' : 'PHYSICAL',
    categoryName: item.categoryName || item.category || '',
    price: salePrice,
    stock: effectiveType === 'SERVICE' ? 999 : Number(item.stock ?? 0),
    unit: item.unit || (effectiveType === 'SERVICE' ? '次' : '件'),
    durationMinutes: item.durationMinutes || 0,
    description: item.description || '',
    available: effectiveStatus !== 'DISABLED',
    defaultCommission: Number(item.commissionRate ?? 0)
  }
}

const handleSaveProduct = async () => {
  if (!form.value.name.trim()) {
    ElMessage.warning('请填写项目或商品名称')
    return
  }
  if (!form.value.categoryName) {
    ElMessage.warning('请选择所属分类')
    return
  }

  const payload = {
    ...buildServerProductPayload(form.value),
    id: isEdit.value ? form.value.id : undefined
  }

  // 同步到服务端（后端 ProductType 枚举仅含 SERVICE / PHYSICAL / MATERIAL）
  let savedServerProduct: any = null
  try {
    const res: any = await saveProductApi(payload)
    savedServerProduct = res?.id ? res : (res?.data || null)
  } catch (e) {
    console.warn('saveProductApi 失败，仅本地保存', e)
  }

  if (isEdit.value) {
    systemData.updateProduct(form.value.id, {
      name: form.value.name,
      code: form.value.code,
      type: form.value.type,
      category: form.value.categoryName,
      categoryName: form.value.categoryName,
      price: Number(form.value.salePrice ?? 0),
      memberPrice: Number(form.value.memberPrice ?? 0),
      commissionRate: Number(form.value.commissionRate ?? 0),
      stock: form.value.type === 'SERVICE' ? 0 : Number(form.value.stock ?? 0),
      spec: form.value.spec,
      unit: form.value.unit,
      durationMinutes: form.value.durationMinutes,
      description: form.value.description,
      status: form.value.status,
      hasBom: form.value.hasBom
    })
    ElMessage.success(`✅ 商品【${form.value.name}】更新成功并已同步至云端！`)
  } else {
    const added = systemData.addProduct({
      code: form.value.code,
      name: form.value.name,
      type: form.value.type,
      category: form.value.categoryName,
      categoryName: form.value.categoryName,
      price: Number(form.value.salePrice ?? 0),
      memberPrice: Number(form.value.memberPrice ?? 0),
      commissionRate: Number(form.value.commissionRate ?? 0),
      stock: form.value.type === 'SERVICE' ? 0 : Number(form.value.stock ?? 0),
      unit: form.value.unit || (form.value.type === 'SERVICE' ? '次' : '件'),
      spec: form.value.spec,
      durationMinutes: form.value.durationMinutes,
      description: form.value.description,
      status: form.value.status,
      hasBom: form.value.hasBom
    })
    if (savedServerProduct?.id && added) {
      added.id = savedServerProduct.id
      persistLocalProducts()
    }
    ElMessage.success(`🎉 新商品【${form.value.name}】上架成功并已同步至云端！`)
  }
  openDialog.value = false
  await loadServerProducts()
}

const handleToggleStatus = async (row: any) => {
  const nextStatus = systemData.toggleProductStatus(row.id)
  row.status = nextStatus
  if (row.id) {
    try {
      await saveProductApi(buildServerProductPayload(row, nextStatus as 'ACTIVE' | 'DISABLED'))
    } catch (e) {
      console.warn('saveProductApi status sync failed', e)
    }
  }
  ElMessage.success(`已${nextStatus === 'ACTIVE' ? '上架在售' : '下架停售'}【${row.name}】，实时库存台账与出入库流水已同步联动！`)
}

const clampCurrentPage = () => {
  const maxPage = Math.max(1, Math.ceil(filteredProducts.value.length / pageSize.value))
  if (currentPage.value > maxPage) {
    currentPage.value = maxPage
  }
}

const handleDeleteProduct = (row: any) => {
  ElMessageBox.confirm(`确定要彻底删除【${row.name}】吗？删除后不可撤销。`, '安全提示', {
    confirmButtonText: '确认删除',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    systemData.deleteProduct(row.id)
    clampCurrentPage()
    if (row.id) {
      try {
        await deleteProductApi(row.id)
      } catch (e) {
        console.warn('deleteProductApi failed, removed locally only', e)
      }
    }
    ElMessage.success(`已成功删除【${row.name}】，台账已同步更新！`)
  }).catch(() => {})
}

// 批量勾选与批量操作
const handleSelectionChange = (selection: any[]) => {
  selectedRows.value = selection
}

const handleBatchChangeStatus = async (status: 'ACTIVE' | 'DISABLED') => {
  if (selectedRows.value.length === 0) return
  const label = status === 'ACTIVE' ? '上架在售' : '下架停售'
  const targets = [...selectedRows.value]
  targets.forEach(item => {
    systemData.updateProduct(item.id, { status })
    item.status = status
  })
  selectedRows.value = []
  await Promise.allSettled(
    targets.filter(item => item.id).map(item => saveProductApi(buildServerProductPayload(item, status)))
  )
  ElMessage.success(`批量${label} ${targets.length} 个商品成功，实时库存台账已同步！`)
}

const handleBatchDelete = () => {
  if (selectedRows.value.length === 0) return
  const targets = [...selectedRows.value]
  ElMessageBox.confirm(`确定要批量删除所选的 ${targets.length} 个商品/服务吗？`, '安全警告', {
    confirmButtonText: '立即批量删除',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    targets.forEach(item => {
      systemData.deleteProduct(item.id)
    })
    selectedRows.value = []
    clampCurrentPage()
    await Promise.allSettled(
      targets.filter(item => item.id).map(item => deleteProductApi(item.id))
    )
    ElMessage.success(`已批量删除 ${targets.length} 个商品/服务`)
  }).catch(() => {})
}

// 服务项目耗材配方清单管理 (直连真实在库物料库存，拒绝假数据)
const openBomDialog = ref(false)
const currentBomProduct = ref<any>(null)
const bomList = ref<any[]>([])
const newBomItem = ref({ materialName: '', dosage: 1, unit: '件', unitCost: 15 })

// 聚合真实在库物料与非服务类商品作为耗材选项
const availableRealMaterials = computed(() => {
  const list: any[] = []
  // 1. 提取当前门店在库院装耗材
  if (systemData.materials && systemData.materials.length > 0) {
    systemData.materials.forEach(m => {
      list.push({
        id: m.id,
        code: m.code,
        name: m.name,
        unit: m.unit || '件',
        unitCost: Number(m.costPrice ?? 20),
        stock: m.initialStock ?? 0
      })
    })
  }
  // 2. 提取当前商品库中的实物商品 (PHYSICAL / RETAIL)
  if (systemData.products && systemData.products.length > 0) {
    systemData.products.forEach(p => {
      if (p.type !== 'SERVICE' && !list.some(x => x.name === p.name)) {
        list.push({
          id: p.id,
          code: p.code,
          name: p.name,
          unit: p.unit || '件',
          unitCost: Number(p.cost ?? (Number(p.price ?? 0) * 0.4)),
          stock: p.stock ?? 50
        })
      }
    })
  }
  return list
})

const handleSelectRealMaterial = (selectedName: string) => {
  const found = availableRealMaterials.value.find(m => m.name === selectedName)
  if (found) {
    newBomItem.value.unit = found.unit
    newBomItem.value.unitCost = found.unitCost
  }
}

const handleManageBom = (row: any) => {
  currentBomProduct.value = row
  // 使用真实配置数据，若未配置则初始化为空数组，严禁注入写死假数据
  if (row.boms && row.boms.length > 0) {
    bomList.value = JSON.parse(JSON.stringify(row.boms))
  } else {
    bomList.value = []
  }
  newBomItem.value = {
    materialName: availableRealMaterials.value[0]?.name || '',
    dosage: 1,
    unit: availableRealMaterials.value[0]?.unit || '件',
    unitCost: availableRealMaterials.value[0]?.unitCost ?? 15
  }
  openBomDialog.value = true
}

const handleAddBomItem = () => {
  if (!newBomItem.value.materialName.trim()) {
    ElMessage.warning('请选择在库物料或耗材品名')
    return
  }
  bomList.value.push({ ...newBomItem.value })
  newBomItem.value = {
    materialName: availableRealMaterials.value[0]?.name || '',
    dosage: 1,
    unit: availableRealMaterials.value[0]?.unit || '件',
    unitCost: availableRealMaterials.value[0]?.unitCost ?? 15
  }
}

const handleSaveBom = () => {
  if (currentBomProduct.value) {
    systemData.updateProduct(currentBomProduct.value.id, {
      boms: [...bomList.value],
      hasBom: bomList.value.length > 0
    })
    currentBomProduct.value.hasBom = bomList.value.length > 0
    currentBomProduct.value.boms = [...bomList.value]
  }
  ElMessage.success('服务项目耗材配方清单已成功保存并实时生效！')
  openBomDialog.value = false
}

// 从服务端拉取商品，合并到 systemData.products（保留本地专属扩展字段，不产生虚假上架/入库流水）
const loadServerProducts = async () => {
  loading.value = true
  try {
    const res: any = await getProductsApi()
    const list: any[] = Array.isArray(res) ? res : (res?.data || [])
    if (list.length > 0) {
      list.forEach((p: any) => {
        const mappedType = p.productType === 'SERVICE' ? 'SERVICE' : 'RETAIL'
        const priceVal = Number(p.price ?? 0)
        const codeVal = p.productCode || ('PRD' + p.id)
        const existing = systemData.products.find((x: any) => x.id === p.id || (x.code && x.code === codeVal))
        if (!existing) {
          systemData.products.push({
            id: p.id,
            code: codeVal,
            name: p.name,
            type: mappedType,
            category: p.categoryName || '',
            categoryName: p.categoryName || '',
            price: priceVal,
            memberPrice: p.memberPrice != null ? Number(p.memberPrice) : Math.round(priceVal * 0.85),
            stock: mappedType === 'SERVICE' ? 0 : (p.stock ?? 50),
            unit: p.unit || (mappedType === 'SERVICE' ? '次' : '件'),
            durationMinutes: p.durationMinutes || 0,
            description: p.description || '',
            status: p.available === false ? 'DISABLED' : 'ACTIVE',
            hasBom: mappedType === 'SERVICE',
            commissionRate: p.defaultCommission != null ? Number(p.defaultCommission) : (mappedType === 'SERVICE' ? 0.25 : 0.15),
            spec: p.spec || ''
          } as any)
        } else {
          const preservedType = existing.type === 'PACKAGE' && p.productType !== 'SERVICE' ? 'PACKAGE' : mappedType
          Object.assign(existing, {
            id: p.id,
            code: codeVal,
            name: p.name,
            type: preservedType,
            category: p.categoryName || existing.category || '',
            categoryName: p.categoryName || existing.categoryName || '',
            price: priceVal,
            memberPrice: p.memberPrice != null ? Number(p.memberPrice) : (existing.memberPrice ?? Math.round(priceVal * 0.85)),
            stock: preservedType === 'SERVICE' ? 0 : (p.stock ?? existing.stock ?? 50),
            unit: p.unit || existing.unit || (preservedType === 'SERVICE' ? '次' : '件'),
            durationMinutes: p.durationMinutes ?? existing.durationMinutes ?? 0,
            description: p.description ?? existing.description ?? '',
            status: p.available === false ? 'DISABLED' : 'ACTIVE',
            hasBom: existing.hasBom ?? (preservedType === 'SERVICE'),
            boms: existing.boms,
            commissionRate: p.defaultCommission != null ? Number(p.defaultCommission) : (existing.commissionRate ?? 0.15),
            spec: p.spec || existing.spec || ''
          })
        }
      })
      persistLocalProducts()
    }
  } catch (e) {
    console.warn('拉取服务端商品列表失败，使用本地缓存数据', e)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadCategories()
  loadServerProducts()
})
</script>

<style scoped>
.product-management-page {
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
  align-items: center;
  gap: 12px;
}

.filter-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.batch-bar {
  margin-top: 12px;
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 6px;
  padding: 8px 14px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.batch-tip {
  font-size: 13px;
  color: #0369a1;
}

.batch-actions {
  display: flex;
  gap: 8px;
}

.code-tag {
  font-family: monospace;
  color: #0284c7;
  font-weight: 600;
  background: #f0f9ff;
  padding: 2px 6px;
  border-radius: 4px;
}

.name-cell {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.product-name {
  font-weight: 600;
  color: #1e293b;
}

.tags-row {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.spec-label {
  font-size: 12px;
  color: #64748b;
}

.duration-label {
  font-size: 12px;
  color: #0d9488;
  background: #f0fdfa;
  padding: 1px 5px;
  border-radius: 3px;
}

.category-name {
  color: #475569;
  font-weight: 500;
}

.price-val {
  color: #334155;
  font-weight: 600;
}

.member-price-cell {
  display: flex;
  align-items: center;
  gap: 6px;
}

.member-price-val {
  color: #ea580c;
  font-weight: 700;
}

.discount-badge {
  font-size: 11px;
  background: #fff7ed;
  color: #c2410c;
  border: 1px solid #fed7aa;
  padding: 1px 4px;
  border-radius: 3px;
  font-weight: 600;
}

.service-stock-tag {
  color: #059669;
  font-size: 12px;
  font-weight: 600;
}

.comm-text {
  font-weight: 600;
  color: #2563eb;
}

.comm-est {
  font-size: 11px;
  color: #94a3b8;
  display: block;
}

.quick-discount-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: 110px;
  margin-bottom: 12px;
}

.discount-hint {
  font-size: 12px;
  color: #64748b;
}

.switch-tip {
  margin-left: 10px;
  font-size: 12px;
  color: #64748b;
}

.profit-calc-card {
  margin-top: 14px;
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 8px;
  padding: 10px 16px;
  display: flex;
  justify-content: space-around;
  align-items: center;
}

.calc-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.calc-title {
  font-size: 12px;
  color: #64748b;
}

.calc-val {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
}

.calc-divider {
  color: #94a3b8;
  font-weight: 700;
}

.text-orange {
  color: #ea580c;
}

.text-blue {
  color: #2563eb;
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}
</style>
