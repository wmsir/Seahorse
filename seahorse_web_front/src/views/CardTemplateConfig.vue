<template>
  <div class="card-template-page">
    <!-- 顶部核心指示面板 (4 格数据概览卡片) -->
    <div class="kpi-banner">
      <div class="kpi-mini-card card-blue">
        <div class="mini-info">
          <div class="mini-lbl">全部在售卡项</div>
          <div class="mini-val">{{ systemData.cardTemplates.length }} <span class="unit">款</span></div>
          <div class="mini-sub">涵盖行业全套锁客卡种</div>
        </div>
        <div class="mini-icon">💳</div>
      </div>

      <div class="kpi-mini-card card-amber">
        <div class="mini-info">
          <div class="mini-lbl">储值折扣特惠卡</div>
          <div class="mini-val">{{ storedValueCount }} <span class="unit">款</span></div>
          <div class="mini-sub">锁客预收本金 · 赠金提频</div>
        </div>
        <div class="mini-icon">🪙</div>
      </div>

      <div class="kpi-mini-card card-emerald">
        <div class="mini-info">
          <div class="mini-lbl">计量服务次卡套餐</div>
          <div class="mini-val">{{ timeCardCount }} <span class="unit">款</span></div>
          <div class="mini-sub">高频单项绑定 · 技师工时</div>
        </div>
        <div class="mini-icon">⏱️</div>
      </div>

      <div class="kpi-mini-card card-purple">
        <div class="mini-info">
          <div class="mini-lbl">尊享年费与权益卡</div>
          <div class="mini-val">{{ benefitCount }} <span class="unit">款</span></div>
          <div class="mini-sub">身份尊荣标识 · 终身特权</div>
        </div>
        <div class="mini-icon">👑</div>
      </div>
    </div>

    <el-card shadow="never" class="main-card">
      <!-- 页面操作顶栏 -->
      <div class="page-top-bar">
        <div class="bar-left">
          <div class="title-wrap">
            <span class="page-title">✨ 会员卡项与锁客方案设置</span>
            <el-tag type="primary" effect="plain" round>当前行业：{{ industryLabel }}</el-tag>
          </div>
          <p class="page-sub">灵活配置储值本金赠金、次卡服务项目、时长卡及专属VIP身份特权，驱动顾客持续复购与转介绍</p>
        </div>

        <div class="bar-right">
          <!-- 视图切换模式：列表表格 vs 视觉卡面画廊 -->
          <el-radio-group v-model="viewMode" size="default" class="view-mode-toggle">
            <el-radio-button label="gallery">
              <el-icon><Grid /></el-icon> 卡面画廊
            </el-radio-button>
            <el-radio-button label="table">
              <el-icon><Tickets /></el-icon> 列表台账
            </el-radio-button>
          </el-radio-group>

          <el-button type="success" plain size="default" @click="handleLoadIndustryCards">
            ✨ 载入当前行业精选卡项
          </el-button>

          <el-button type="primary" icon="Plus" size="default" class="add-btn" @click="handleOpenAdd">
            新增会员卡项
          </el-button>
        </div>
      </div>

      <!-- 现代胶囊分类标签栏 (带计数微标) -->
      <div class="tab-filter-container">
        <div
          v-for="tab in tabOptionsWithCount"
          :key="tab.value"
          class="capsule-tab-item"
          :class="{ active: currentTab === tab.value }"
          @click="handleTabChange(tab.value)"
        >
          <span class="tab-label">{{ tab.label }}</span>
          <span class="tab-badge">{{ tab.count }}</span>
        </div>
      </div>

      <!-- 视图 A：精美 VIP 卡面画廊模式 (Card Gallery View) -->
      <div v-if="viewMode === 'gallery'" class="gallery-container">
        <div v-if="filteredList.length === 0" class="empty-gallery">
          <el-empty description="当前分类暂无在售会员卡项" />
        </div>

        <div class="cards-grid">
          <div
            v-for="card in filteredList"
            :key="card.id"
            class="vip-card-box"
            :class="`theme-${card.themeColor || 'gold'}`"
          >
            <!-- 卡片上部芯片与品牌标识 -->
            <div class="vip-card-header">
              <div class="card-chip">
                <div class="chip-lines"></div>
              </div>
              <div class="card-brand-tag">
                <span class="brand-text">SEAHORSE VIP</span>
                <el-tag size="small" effect="dark" class="type-pill">
                  {{ card.cardTypeName }}
                </el-tag>
              </div>
            </div>

            <!-- 卡片核心名称与特权描述 -->
            <div class="vip-card-body">
              <div class="vip-card-name">{{ card.cardName }}</div>
              <div class="vip-card-desc">{{ card.contentDescription }}</div>
            </div>

            <!-- 折扣角标 -->
            <div v-if="card.discountRate && card.discountRate < 1" class="discount-ribbon">
              {{ (card.discountRate * 10).toFixed(1) }} 折
            </div>

            <!-- 卡片下部售价与操作 -->
            <div class="vip-card-footer">
              <div class="price-block">
                <span class="price-currency">￥</span>
                <span class="price-number">{{ Number(card.price || 0).toFixed(2) }}</span>
                <span v-if="card.originalPrice && card.originalPrice > card.price" class="price-origin">
                  ￥{{ Number(card.originalPrice).toFixed(2) }}
                </span>
              </div>

              <div class="card-actions">
                <el-button size="small" circle icon="View" title="查看详情" @click="handleViewDetail(card)" />
                <el-button size="small" circle type="primary" icon="Edit" title="编辑卡项" @click="handleEdit(card)" />
                <el-button size="small" circle type="danger" icon="Delete" title="删除卡项" @click="handleDelete(card)" />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 视图 B：列表台账模式 (Table View) -->
      <div v-else class="table-container">
        <el-table
          v-loading="loading"
          :data="paginatedList"
          class="custom-card-table"
          stripe
          border
          style="width: 100%;"
        >
          <el-table-column prop="cardTypeName" label="卡项类型" width="130" align="center">
            <template #default="{ row }">
              <el-tag :type="getTypeTag(row.cardType)" effect="light">
                {{ row.cardTypeName }}
              </el-tag>
            </template>
          </el-table-column>

          <el-table-column prop="cardName" label="卡项名称" min-width="220">
            <template #default="{ row }">
              <div class="card-title-cell">
                <span class="font-bold">{{ row.cardName }}</span>
                <span class="card-code-sub">有效期：{{ row.validityDays > 0 ? `${row.validityDays}天` : '长期有效' }}</span>
              </div>
            </template>
          </el-table-column>

          <el-table-column prop="price" label="售价 (元)" width="140" align="right">
            <template #default="{ row }">
              <div class="price-col">
                <span class="bold-price">￥{{ Number(row.price || 0).toFixed(2) }}</span>
                <span v-if="row.originalPrice && row.originalPrice > row.price" class="origin-price">
                  ￥{{ Number(row.originalPrice).toFixed(2) }}
                </span>
              </div>
            </template>
          </el-table-column>

          <el-table-column prop="contentDescription" label="包含权益与服务内容" min-width="280">
            <template #default="{ row }">
              <div class="content-desc-cell">
                <span class="desc-tag-icon">🎁</span>
                <span>{{ row.contentDescription || '-' }}</span>
              </div>
            </template>
          </el-table-column>

          <el-table-column label="折扣优惠" width="110" align="center">
            <template #default="{ row }">
              <el-tag v-if="row.discountRate && row.discountRate < 1" type="danger" effect="plain" size="small">
                {{ (row.discountRate * 10).toFixed(1) }} 折
              </el-tag>
              <span v-else class="text-gray">平价</span>
            </template>
          </el-table-column>

          <el-table-column label="卡面风格" width="110" align="center">
            <template #default="{ row }">
              <div class="theme-badge-dot">
                <span class="theme-circle" :class="`theme-dot-${row.themeColor || 'gold'}`"></span>
                <span>{{ getThemeName(row.themeColor) }}</span>
              </div>
            </template>
          </el-table-column>

          <el-table-column label="操作" width="180" align="center" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" size="small" icon="View" @click="handleViewDetail(row)">
                详情
              </el-button>
              <el-button link type="primary" size="small" icon="Edit" @click="handleEdit(row)">
                编辑
              </el-button>
              <el-button link type="danger" size="small" icon="Delete" @click="handleDelete(row)">
                删除
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <!-- 底部分页 -->
        <div class="pagination-wrapper">
          <el-pagination
            v-model:current-page="currentPage"
            v-model:page-size="pageSize"
            :page-sizes="[10, 20, 50]"
            layout="total, sizes, prev, pager, next, jumper"
            :total="filteredList.length"
          />
        </div>
      </div>
    </el-card>

    <!-- 新增 / 编辑卡项弹窗 (左表单 + 右所见即所得卡面实时预览) -->
    <el-dialog
      v-model="dialogVisible"
      :title="isEdit ? '编辑会员卡项' : '新增会员卡项'"
      width="880px"
      destroy-on-close
    >
      <div class="dialog-content-layout">
        <!-- 左侧：表单配置 -->
        <div class="dialog-form-pane">
          <el-form :model="cardForm" label-width="100px" size="default">
            <el-form-item label="卡项类型" required>
              <el-select v-model="cardForm.cardType" style="width: 100%;" @change="handleTypeChange">
                <el-option label="次卡 (计量核销)" value="TIME_CARD" />
                <el-option label="储值卡 (本金+赠金)" value="STORED_VALUE" />
                <el-option label="时长卡 (周期畅玩/畅吃)" value="DURATION_CARD" />
                <el-option label="独立储值卡 (专款专用)" value="INDEPENDENT_STORED_CARD" />
                <el-option label="盲盒卡 (惊喜抽取)" value="BLIND_BOX_CARD" />
                <el-option label="权益卡 (VIP专属特权)" value="BENEFIT_CARD" />
              </el-select>
            </el-form-item>

            <el-form-item label="卡项名称" required>
              <el-input v-model="cardForm.cardName" placeholder="例如：1000元轻奢充值金卡、4次小保养年卡" />
            </el-form-item>

            <el-form-item label="卡面风格">
              <el-radio-group v-model="cardForm.themeColor" size="small">
                <el-radio-button label="gold">黑金流光</el-radio-button>
                <el-radio-button label="black">黑金钻</el-radio-button>
                <el-radio-button label="blue">深邃蓝</el-radio-button>
                <el-radio-button label="emerald">翡翠绿</el-radio-button>
                <el-radio-button label="purple">星空紫</el-radio-button>
              </el-radio-group>
            </el-form-item>

            <!-- 核心金额与额度配置卡片专区 (售价 / 原价 / 充值本金 / 赠送金额 专项质感美化) -->
            <div class="pricing-card-section">
              <div class="pricing-section-title">
                <div class="p-title-left">
                  <span class="p-icon">💰</span>
                  <span class="p-title">价格与额度设置</span>
                </div>
                <span class="p-sub-badge" v-if="cardForm.cardType === 'STORED_VALUE' || cardForm.cardType === 'INDEPENDENT_STORED_CARD'">
                  ⚡ 充本金送赠金模式
                </span>
                <span class="p-sub-badge" v-else>
                  🏷️ 售卖定价模式
                </span>
              </div>

              <!-- 售价 (元) 与 原价/面值 -->
              <div class="pricing-row-grid">
                <!-- 1. 售价 (元) -->
                <div class="price-input-box box-sale">
                  <div class="box-header">
                    <div class="box-title">
                      <span class="box-label">售价 (元)</span>
                      <span class="req-dot">*</span>
                    </div>
                    <span class="box-tag tag-sale">客户实付现金</span>
                  </div>
                  <div class="box-input-wrap">
                    <span class="c-symbol">￥</span>
                    <el-input-number
                      v-model="cardForm.price"
                      :min="0"
                      :precision="2"
                      :step="100"
                      controls-position="right"
                      class="styled-price-input"
                      placeholder="0.00"
                      @change="handlePriceChange"
                    />
                  </div>
                  <div class="box-hint">客户购卡或开卡时前台实际收取金额</div>
                </div>

                <!-- 2. 原价 / 面值 -->
                <div class="price-input-box box-original">
                  <div class="box-header">
                    <div class="box-title">
                      <span class="box-label">原价 / 面值</span>
                    </div>
                    <span class="box-tag tag-origin">卡面划线参考</span>
                  </div>
                  <div class="box-input-wrap">
                    <span class="c-symbol">￥</span>
                    <el-input-number
                      v-model="cardForm.originalPrice"
                      :min="0"
                      :precision="2"
                      :step="100"
                      controls-position="right"
                      class="styled-price-input"
                      placeholder="0.00"
                    />
                  </div>
                  <div class="box-hint">原价高于售价时展示划线优惠折扣</div>
                </div>
              </div>

              <!-- 3. 充值本金 与 4. 赠送金额 (储值卡 / 独立储值卡专属) -->
              <div
                v-if="cardForm.cardType === 'STORED_VALUE' || cardForm.cardType === 'INDEPENDENT_STORED_CARD'"
                class="pricing-row-grid stored-grid"
              >
                <!-- 充值本金 -->
                <div class="price-input-box box-principal">
                  <div class="box-header">
                    <div class="box-title">
                      <span class="box-label">充值本金</span>
                    </div>
                    <span class="box-tag tag-principal">可退本金账户</span>
                  </div>
                  <div class="box-input-wrap">
                    <span class="c-symbol">￥</span>
                    <el-input-number
                      v-model="cardForm.principalAmount"
                      :min="0"
                      :precision="2"
                      :step="100"
                      controls-position="right"
                      class="styled-price-input"
                      placeholder="0.00"
                      @change="updateStoredDesc"
                    />
                  </div>
                  <div class="box-hint">存入客户本金钱包，支持按规退款</div>
                </div>

                <!-- 赠送金额 -->
                <div class="price-input-box box-gift">
                  <div class="box-header">
                    <div class="box-title">
                      <span class="box-label">赠送金额</span>
                    </div>
                    <span class="box-tag tag-gift">营销让利赠金</span>
                  </div>
                  <div class="box-input-wrap">
                    <span class="c-symbol gift-symbol">+￥</span>
                    <el-input-number
                      v-model="cardForm.giftAmount"
                      :min="0"
                      :precision="2"
                      :step="50"
                      controls-position="right"
                      class="styled-price-input gift-input"
                      placeholder="0.00"
                      @change="updateStoredDesc"
                    />
                  </div>
                  <div class="box-hint">存入赠金钱包，消费时按比例扣除</div>
                </div>
              </div>

              <!-- 储值卡到账实时动态核算条 -->
              <div
                v-if="cardForm.cardType === 'STORED_VALUE' || cardForm.cardType === 'INDEPENDENT_STORED_CARD'"
                class="stored-calc-strip"
              >
                <div class="strip-left">
                  <span class="calc-icon">💳</span>
                  <span class="strip-text">
                    实收 <b>￥{{ Number(cardForm.price || 0).toFixed(2) }}</b>
                    ➔
                    实际到账：<span class="total-arrival">￥{{ (Number(cardForm.principalAmount || cardForm.price || 0) + Number(cardForm.giftAmount || 0)).toFixed(2) }}</span>
                  </span>
                </div>
                <div class="strip-right">
                  <span class="detail-split">
                    本金 ￥{{ Number(cardForm.principalAmount || cardForm.price || 0).toFixed(2) }} + 赠送 ￥{{ Number(cardForm.giftAmount || 0).toFixed(2) }}
                  </span>
                </div>
              </div>

              <!-- 消费折扣 -->
              <div
                v-if="cardForm.cardType === 'STORED_VALUE' || cardForm.cardType === 'INDEPENDENT_STORED_CARD'"
                class="discount-config-row"
              >
                <span class="discount-label">消费专享折扣：</span>
                <el-input-number
                  v-model="cardForm.discountRate"
                  :min="0.1"
                  :max="1"
                  :step="0.05"
                  :precision="2"
                  controls-position="right"
                  style="width: 140px;"
                />
                <span class="discount-text-tip">
                  （当前为 {{ cardForm.discountRate ? (cardForm.discountRate * 10).toFixed(1) : '10.0' }} 折，1.00 为平价不打折）
                </span>
              </div>
            </div>

            <!-- 次卡专属 -->
            <template v-if="cardForm.cardType === 'TIME_CARD'">
              <el-row :gutter="12">
                <el-col :span="12">
                  <el-form-item label="服务总次数">
                    <el-input-number v-model="cardForm.totalTimes" :min="1" :step="1" style="width: 100%;" @change="updateTimeDesc" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="关联项目名称">
                    <el-input v-model="cardForm.serviceSkuName" placeholder="如：精油SPA、小保养" @input="updateTimeDesc" />
                  </el-form-item>
                </el-col>
              </el-row>
            </template>

            <el-form-item label="包含内容描述">
              <el-input
                v-model="cardForm.contentDescription"
                placeholder="例如：充值本金￥1000即赠￥200，全场服务享8.5折"
              />
            </el-form-item>

            <el-form-item label="有效天数">
              <el-input-number v-model="cardForm.validityDays" :min="0" :step="30" style="width: 100%;" />
              <span style="font-size: 12px; color: #64748b; margin-top: 2px;">填 0 代表长期有效</span>
            </el-form-item>

            <el-form-item label="权益/备注说明">
              <el-input v-model="cardForm.notes" type="textarea" :rows="2" placeholder="填写该卡项适用说明、权益细则" />
            </el-form-item>
          </el-form>
        </div>

        <!-- 右侧：所见即所得 VIP 卡面预览 -->
        <div class="dialog-preview-pane">
          <div class="preview-title">VIP 卡面实时预览</div>
          <div class="vip-card-box preview-card" :class="`theme-${cardForm.themeColor || 'gold'}`">
            <div class="vip-card-header">
              <div class="card-chip">
                <div class="chip-lines"></div>
              </div>
              <div class="card-brand-tag">
                <span class="brand-text">SEAHORSE VIP</span>
                <el-tag size="small" effect="dark" class="type-pill">
                  {{ cardForm.cardTypeName }}
                </el-tag>
              </div>
            </div>

            <div class="vip-card-body">
              <div class="vip-card-name">{{ cardForm.cardName || '卡项名称预览' }}</div>
              <div class="vip-card-desc">{{ cardForm.contentDescription || '包含权益与服务项目说明' }}</div>
            </div>

            <div v-if="cardForm.discountRate && cardForm.discountRate < 1" class="discount-ribbon">
              {{ (cardForm.discountRate * 10).toFixed(1) }} 折
            </div>

            <div class="vip-card-footer">
              <div class="price-block">
                <span class="price-currency">￥</span>
                <span class="price-number">{{ Number(cardForm.price || 0).toFixed(2) }}</span>
                <span v-if="cardForm.originalPrice && cardForm.originalPrice > cardForm.price" class="price-origin">
                  ￥{{ Number(cardForm.originalPrice).toFixed(2) }}
                </span>
              </div>
              <span class="validity-badge">{{ cardForm.validityDays > 0 ? `${cardForm.validityDays}天` : '永久有效' }}</span>
            </div>
          </div>
          <p class="preview-hint">💡 调整左侧配置时，会员手机端与收银台卡面视觉实时同步呈现。</p>
        </div>
      </div>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="handleSave">确认保存卡项</el-button>
      </template>
    </el-dialog>

    <!-- 卡项详情弹窗 -->
    <el-dialog v-model="detailVisible" title="会员卡项完整详情" width="580px">
      <el-descriptions :column="1" border v-if="currentDetail">
        <el-descriptions-item label="卡项名称">
          <strong>{{ currentDetail.cardName }}</strong>
        </el-descriptions-item>
        <el-descriptions-item label="卡项类型">
          <el-tag size="small" :type="getTypeTag(currentDetail.cardType)">{{ currentDetail.cardTypeName }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="售价 (实付)">
          <span style="color: #0284c7; font-weight: 800; font-size: 18px;">￥{{ Number(currentDetail.price || 0).toFixed(2) }}</span>
          <span v-if="currentDetail.originalPrice && currentDetail.originalPrice > currentDetail.price" style="text-decoration: line-through; color: #94a3b8; margin-left: 8px;">
            原价 ￥{{ Number(currentDetail.originalPrice).toFixed(2) }}
          </span>
        </el-descriptions-item>
        <el-descriptions-item
          v-if="currentDetail.cardType === 'STORED_VALUE' || currentDetail.cardType === 'INDEPENDENT_STORED_CARD'"
          label="充值本金与赠送"
        >
          <div style="display: flex; gap: 14px; align-items: center; flex-wrap: wrap;">
            <span>充值本金: <b style="color: #2563eb;">￥{{ Number(currentDetail.principalAmount || currentDetail.price || 0).toFixed(2) }}</b></span>
            <span>+ 赠送金额: <b style="color: #059669;">￥{{ Number(currentDetail.giftAmount || 0).toFixed(2) }}</b></span>
            <el-tag size="small" type="success" effect="plain">
              实际到账：￥{{ (Number(currentDetail.principalAmount || currentDetail.price || 0) + Number(currentDetail.giftAmount || 0)).toFixed(2) }}
            </el-tag>
          </div>
        </el-descriptions-item>
        <el-descriptions-item label="包含内容权益">
          <div style="line-height: 1.6; font-weight: 500;">{{ currentDetail.contentDescription }}</div>
        </el-descriptions-item>
        <el-descriptions-item label="有效期限">
          {{ currentDetail.validityDays > 0 ? `${currentDetail.validityDays} 天` : '长期有效' }}
        </el-descriptions-item>
        <el-descriptions-item label="权益细则说明">
          {{ currentDetail.notes || '全店各终端通用，未消费可退' }}
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button type="primary" @click="detailVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useSystemDataStore, type CardTemplateEntity } from '../stores/systemDataStore'
import { useStoreConfig } from '../stores/store'
import { allIndustryPackages } from '../stores/industryPresets'
import { getCardTemplatesApi, saveCardTemplateApi, deleteCardTemplateApi } from '../api'

const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()

const inferThemeColor = (cardType?: string): string => {
  switch (cardType) {
    case 'INDEPENDENT_STORED_CARD': return 'emerald'
    case 'TIME_CARD': return 'blue'
    case 'DURATION_CARD':
    case 'BLIND_BOX_CARD': return 'purple'
    case 'BENEFIT_CARD': return 'black'
    default: return 'gold'
  }
}

const persistLocalCardCache = () => {
  try {
    localStorage.setItem('seahorse_card_templates_data', JSON.stringify(systemData.cardTemplates))
  } catch {}
}

const loadServerCardTemplates = async () => {
  loading.value = true
  try {
    const res: any = await getCardTemplatesApi()
    const list: any[] = Array.isArray(res) ? res : (Array.isArray(res?.data) ? res.data : [])
    if (list.length > 0) {
      const localMap = new Map(systemData.cardTemplates.map(c => [c.id, c]))
      systemData.cardTemplates = list.map((item: any) => {
        const prev = localMap.get(Number(item.id))
        return {
          id: Number(item.id),
          cardType: item.cardType || 'STORED_VALUE',
          cardTypeName: item.cardTypeName || '储值卡',
          cardName: item.cardName || '',
          price: Number(item.price ?? 0),
          originalPrice: Number(item.originalPrice ?? item.price ?? 0),
          contentDescription: item.contentDescription || '',
          principalAmount: Number(item.principalAmount ?? 0),
          giftAmount: Number(item.giftAmount ?? 0),
          discountRate: Number(item.discountRate ?? 1),
          totalTimes: Number(item.totalTimes ?? 0),
          validityDays: Number(item.validityDays ?? 365),
          serviceSkuName: item.serviceSkuName || '',
          themeColor: prev?.themeColor || inferThemeColor(item.cardType),
          notes: item.notes || '',
          status: item.status || 'ACTIVE'
        } as CardTemplateEntity
      })
      persistLocalCardCache()
    }
  } catch (e) {
    console.warn('拉取服务端会员卡模板失败，保留本地缓存', e)
  } finally {
    loading.value = false
  }
}

const loading = ref(false)
const saving = ref(false)
const viewMode = ref<'gallery' | 'table'>('gallery')
const currentTab = ref('ALL')
const currentPage = ref(1)
const pageSize = ref(12)

const industryNamesMap: Record<string, string> = {
  BEAUTY: '美容美发美甲',
  RESTAURANT: '餐饮轻食/正餐',
  AUTO: '汽车养护维修',
  RETAIL: '专营零售'
}

// 动态对齐当前商户的真实行业与经营类目，杜绝硬编码写死
const industryLabel = computed(() => {
  if (storeConfig.industryCategoryName) {
    return storeConfig.industryCategoryGroup
      ? `${storeConfig.industryCategoryGroup} · ${storeConfig.industryCategoryName}`
      : storeConfig.industryCategoryName
  }
  const currentKey = (storeConfig.industry || systemData.currentIndustry || 'BEAUTY') as 'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL'
  return industryNamesMap[currentKey] || storeConfig.industry || '智慧连锁商业'
})

// 载入当前行业精选会员卡项方案并同步后端
const handleLoadIndustryCards = async () => {
  const currentKey = (storeConfig.industry || systemData.currentIndustry || 'BEAUTY') as 'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL'
  const pkg = allIndustryPackages[currentKey] || allIndustryPackages.BEAUTY
  if (pkg && pkg.cardTemplates && Array.isArray(pkg.cardTemplates)) {
    const presetCards = JSON.parse(JSON.stringify(pkg.cardTemplates))
    systemData.cardTemplates = presetCards
    persistLocalCardCache()
    try {
      localStorage.setItem(`seahorse_card_templates_${currentKey}`, JSON.stringify(systemData.cardTemplates))
    } catch {}
    const existingNames = new Set<string>()
    try {
      const remoteRes: any = await getCardTemplatesApi()
      const remoteList: any[] = Array.isArray(remoteRes) ? remoteRes : (Array.isArray(remoteRes?.data) ? remoteRes.data : [])
      remoteList.forEach((r: any) => {
        if (r?.cardName) existingNames.add(String(r.cardName).trim())
      })
    } catch {}
    await Promise.allSettled(
      presetCards
        .filter((c: any) => c?.cardName && !existingNames.has(String(c.cardName).trim()))
        .map((c: any) => saveCardTemplateApi({
          cardType: c.cardType,
          cardTypeName: c.cardTypeName,
          cardName: c.cardName,
          price: Number(c.price ?? 0),
          originalPrice: Number(c.originalPrice ?? c.price ?? 0),
          contentDescription: c.contentDescription || '',
          principalAmount: Number(c.principalAmount ?? 0),
          giftAmount: Number(c.giftAmount ?? 0),
          discountRate: Number(c.discountRate ?? 1),
          totalTimes: Number(c.totalTimes ?? 0),
          validityDays: Number(c.validityDays ?? 365),
          serviceSkuName: c.serviceSkuName || '',
          notes: c.notes || ''
        }))
    )
    await loadServerCardTemplates()
    ElMessage.success(`已成功载入并同步适合当前行业【${industryLabel.value}】的精选会员卡项方案！`)
  }
}

onMounted(async () => {
  try {
    await storeConfig.fetchIndustry()
    if (storeConfig.industry && ['BEAUTY', 'RESTAURANT', 'AUTO', 'RETAIL'].includes(storeConfig.industry)) {
      if (systemData.currentIndustry !== storeConfig.industry) {
        systemData.currentIndustry = storeConfig.industry as any
      }
    }
    await loadServerCardTemplates()
  } catch (e) {
    console.error('CardTemplateConfig onMounted error:', e)
  }
})

// 顶部 KPI 统计
const storedValueCount = computed(() => {
  return systemData.cardTemplates.filter(c => c.cardType === 'STORED_VALUE' || c.cardType === 'INDEPENDENT_STORED_CARD').length
})

const timeCardCount = computed(() => {
  return systemData.cardTemplates.filter(c => c.cardType === 'TIME_CARD').length
})

const benefitCount = computed(() => {
  return systemData.cardTemplates.filter(c => c.cardType === 'BENEFIT_CARD' || c.cardType === 'DURATION_CARD' || c.cardType === 'BLIND_BOX_CARD').length
})

const tabOptions = [
  { label: '全部卡项', value: 'ALL' },
  { label: '次卡', value: 'TIME_CARD' },
  { label: '储值卡', value: 'STORED_VALUE' },
  { label: '时长卡', value: 'DURATION_CARD' },
  { label: '独立储值卡', value: 'INDEPENDENT_STORED_CARD' },
  { label: '盲盒卡', value: 'BLIND_BOX_CARD' },
  { label: '权益卡', value: 'BENEFIT_CARD' }
]

const tabOptionsWithCount = computed(() => {
  return tabOptions.map(t => {
    let count = 0
    if (t.value === 'ALL') {
      count = systemData.cardTemplates.length
    } else {
      count = systemData.cardTemplates.filter(c => c.cardType === t.value).length
    }
    return {
      ...t,
      count
    }
  })
})

const filteredList = computed(() => {
  if (currentTab.value === 'ALL') {
    return systemData.cardTemplates
  }
  return systemData.cardTemplates.filter(item => item.cardType === currentTab.value)
})

const paginatedList = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredList.value.slice(start, start + pageSize.value)
})

const handleTabChange = (val: string) => {
  currentTab.value = val
  currentPage.value = 1
}

const getTypeTag = (type: string) => {
  switch (type) {
    case 'STORED_VALUE': return 'warning'
    case 'TIME_CARD': return 'success'
    case 'BENEFIT_CARD': return 'danger'
    case 'DURATION_CARD': return 'primary'
    case 'BLIND_BOX_CARD': return 'info'
    default: return ''
  }
}

const getThemeName = (theme?: string) => {
  switch (theme) {
    case 'gold': return '黑金流光'
    case 'black': return '黑金钻'
    case 'blue': return '深邃蓝'
    case 'emerald': return '翡翠绿'
    case 'purple': return '星空紫'
    default: return '尊享金'
  }
}

// 新增与编辑弹窗逻辑
const dialogVisible = ref(false)
const isEdit = ref(false)
const detailVisible = ref(false)
const currentDetail = ref<CardTemplateEntity | null>(null)

const cardForm = ref<any>({
  id: null,
  cardType: 'STORED_VALUE',
  cardTypeName: '储值卡',
  cardName: '',
  price: 500,
  originalPrice: 600,
  contentDescription: '充值本金￥500即赠￥100，享受全场服务9折',
  principalAmount: 500,
  giftAmount: 100,
  discountRate: 0.90,
  totalTimes: 10,
  validityDays: 365,
  serviceSkuName: '',
  themeColor: 'gold',
  notes: '',
  status: 'ACTIVE'
})

const handleTypeChange = (typeVal: string) => {
  const found = tabOptions.find(t => t.value === typeVal)
  if (found) {
    cardForm.value.cardTypeName = found.label
  }
  if (typeVal === 'STORED_VALUE') {
    cardForm.value.themeColor = 'gold'
    updateStoredDesc()
  } else if (typeVal === 'INDEPENDENT_STORED_CARD') {
    cardForm.value.themeColor = 'emerald'
    updateStoredDesc()
  } else if (typeVal === 'TIME_CARD') {
    cardForm.value.themeColor = 'blue'
    updateTimeDesc()
  } else if (typeVal === 'DURATION_CARD') {
    cardForm.value.themeColor = 'purple'
    cardForm.value.contentDescription = '周期有效期内尊享不限次畅享服务'
  } else if (typeVal === 'BENEFIT_CARD') {
    cardForm.value.themeColor = 'black'
    cardForm.value.contentDescription = '尊享VIP专属会员折扣与优先预约特权'
  } else if (typeVal === 'BLIND_BOX_CARD') {
    cardForm.value.themeColor = 'purple'
    cardForm.value.contentDescription = '开启盲盒随机解锁超值明星护理项目'
  }
}

const handlePriceChange = () => {
  if (cardForm.value.cardType === 'STORED_VALUE' || cardForm.value.cardType === 'INDEPENDENT_STORED_CARD') {
    if (!cardForm.value.principalAmount || cardForm.value.principalAmount === 0 || cardForm.value.principalAmount === 500) {
      cardForm.value.principalAmount = Number(cardForm.value.price || 0)
    }
    updateStoredDesc()
  }
}

const updateStoredDesc = () => {
  const p = Number(cardForm.value.principalAmount || 0)
  const g = Number(cardForm.value.giftAmount || 0)
  cardForm.value.contentDescription = `充值本金￥${p}即赠￥${g}，可用总金额￥${(p + g).toFixed(2)}`
}

const updateTimeDesc = () => {
  const s = cardForm.value.serviceSkuName || '专享特色项目'
  const t = cardForm.value.totalTimes || 10
  cardForm.value.contentDescription = `包含项目/服务次数: ${s} × ${t}次`
}

const handleOpenAdd = () => {
  isEdit.value = false
  const initialType = currentTab.value === 'ALL' ? 'STORED_VALUE' : currentTab.value
  cardForm.value = {
    id: null,
    cardType: initialType,
    cardTypeName: currentTab.value === 'ALL' ? '储值卡' : (tabOptions.find(t => t.value === currentTab.value)?.label || '储值卡'),
    cardName: '',
    price: 500,
    originalPrice: 600,
    contentDescription: '充值本金￥500即赠￥100，享全场服务9折',
    principalAmount: 500,
    giftAmount: 100,
    discountRate: 0.90,
    totalTimes: 10,
    validityDays: 365,
    serviceSkuName: '',
    themeColor: 'gold',
    notes: '',
    status: 'ACTIVE'
  }
  if (initialType !== 'STORED_VALUE') {
    handleTypeChange(initialType)
  }
  dialogVisible.value = true
}

const handleEdit = (row: CardTemplateEntity) => {
  isEdit.value = true
  cardForm.value = JSON.parse(JSON.stringify(row))
  dialogVisible.value = true
}

const handleViewDetail = (row: CardTemplateEntity) => {
  currentDetail.value = row
  detailVisible.value = true
}

const handleSave = async () => {
  if (!(cardForm.value.cardName || '').trim()) {
    ElMessage.warning('请输入卡项名称')
    return
  }
  if (cardForm.value.price == null || isNaN(Number(cardForm.value.price))) {
    ElMessage.warning('请输入有效的卡项售价')
    return
  }
  saving.value = true
  try {
    const payload = {
      ...cardForm.value,
      cardName: cardForm.value.cardName.trim(),
      price: Number(cardForm.value.price || 0)
    }
    const serverPayload = {
      id: isEdit.value && payload.id ? payload.id : undefined,
      cardType: payload.cardType,
      cardTypeName: payload.cardTypeName,
      cardName: payload.cardName,
      price: Number(payload.price || 0),
      originalPrice: payload.originalPrice != null ? Number(payload.originalPrice) : undefined,
      contentDescription: payload.contentDescription || '',
      principalAmount: payload.principalAmount != null ? Number(payload.principalAmount) : undefined,
      giftAmount: payload.giftAmount != null ? Number(payload.giftAmount) : undefined,
      discountRate: payload.discountRate != null ? Number(payload.discountRate) : undefined,
      totalTimes: payload.totalTimes != null ? Number(payload.totalTimes) : undefined,
      validityDays: payload.validityDays != null ? Number(payload.validityDays) : 365,
      serviceSkuName: payload.serviceSkuName || '',
      notes: payload.notes || ''
    }
    let savedServer: any = null
    try {
      const res: any = await saveCardTemplateApi(serverPayload)
      savedServer = res?.id ? res : (res?.data || null)
    } catch (e) {
      console.warn('saveCardTemplateApi failed, falling back to local store', e)
    }

    if (savedServer?.id) {
      const merged: CardTemplateEntity = {
        ...payload,
        id: Number(savedServer.id),
        themeColor: payload.themeColor || inferThemeColor(payload.cardType),
        status: savedServer.status || payload.status || 'ACTIVE'
      }
      const idx = systemData.cardTemplates.findIndex(c => c.id === merged.id || (isEdit.value && c.id === payload.id))
      if (idx !== -1) {
        systemData.cardTemplates[idx] = merged
      } else {
        systemData.cardTemplates.unshift(merged)
      }
      persistLocalCardCache()
      ElMessage.success(isEdit.value ? '会员卡项更新成功并已同步云端！' : '新会员卡项创建成功并已同步云端！')
    } else if (isEdit.value && payload.id) {
      systemData.updateCardTemplate(payload.id, payload)
      ElMessage.success('会员卡项更新成功！')
    } else {
      systemData.addCardTemplate(payload)
      ElMessage.success('新会员卡项创建成功，已生效上线！')
    }
    dialogVisible.value = false
  } finally {
    saving.value = false
  }
}

const handleDelete = (row: CardTemplateEntity) => {
  ElMessageBox.confirm(
    `确定要删除会员卡项【${row.cardName}】吗？删除后新客户将无法购买该卡项。`,
    '删除确认',
    {
      confirmButtonText: '确定删除',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(async () => {
    if (row.id) {
      try {
        await deleteCardTemplateApi(row.id)
      } catch (e) {
        console.warn('deleteCardTemplateApi failed, removing locally', e)
      }
    }
    const idx = systemData.cardTemplates.findIndex(c => c.id === row.id)
    if (idx !== -1) {
      systemData.cardTemplates.splice(idx, 1)
      persistLocalCardCache()
    }
    ElMessage.success('该卡项已成功下架删除')
  }).catch(() => {})
}
</script>

<style scoped>
.card-template-page {
  padding: 16px;
  background-color: #f8fafc;
  min-height: calc(100vh - 70px);
}

/* 顶部 KPI 看板 */
.kpi-banner {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 16px;
}

@media (max-width: 1024px) {
  .kpi-banner {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 640px) {
  .kpi-banner {
    grid-template-columns: 1fr;
  }
}

.kpi-mini-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-radius: 12px;
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  transition: transform 0.2s;
}

.kpi-mini-card:hover {
  transform: translateY(-2px);
}

.card-blue {
  background: linear-gradient(135deg, #0284c7, #0369a1);
}

.card-amber {
  background: linear-gradient(135deg, #f59e0b, #d97706);
}

.card-emerald {
  background: linear-gradient(135deg, #10b981, #059669);
}

.card-purple {
  background: linear-gradient(135deg, #8b5cf6, #6d28d9);
}

.mini-lbl {
  font-size: 13px;
  opacity: 0.92;
}

.mini-val {
  font-size: 24px;
  font-weight: 800;
  margin: 4px 0;
}

.mini-val .unit {
  font-size: 13px;
  font-weight: normal;
  margin-left: 2px;
}

.mini-sub {
  font-size: 11px;
  opacity: 0.85;
}

.mini-icon {
  font-size: 32px;
  opacity: 0.9;
}

/* 主卡片容器 */
.main-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  background-color: #ffffff;
}

/* 操作顶栏 */
.page-top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 16px;
  padding-bottom: 14px;
  border-bottom: 1px solid #f1f5f9;
}

.title-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
}

.page-title {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
}

.page-sub {
  margin: 4px 0 0 0;
  font-size: 13px;
  color: #64748b;
}

.bar-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* 胶囊标签栏 */
.tab-filter-container {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  padding: 8px 0 16px 0;
}

.capsule-tab-item {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border-radius: 20px;
  background: #f1f5f9;
  color: #475569;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s ease;
  user-select: none;
}

.capsule-tab-item:hover {
  background: #e2e8f0;
  color: #0284c7;
}

.capsule-tab-item.active {
  background: #0284c7;
  color: #ffffff;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(2, 132, 199, 0.3);
}

.tab-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 10px;
  background: rgba(0, 0, 0, 0.08);
}

.capsule-tab-item.active .tab-badge {
  background: rgba(255, 255, 255, 0.25);
  color: #ffffff;
}

/* 画廊卡片网格 */
.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(290px, 1fr));
  gap: 20px;
  margin-top: 8px;
}

/* 精美 VIP 卡面盒模型 */
.vip-card-box {
  position: relative;
  border-radius: 16px;
  padding: 20px;
  min-height: 180px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  color: #ffffff;
  overflow: hidden;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
  transition: transform 0.25s ease, box-shadow 0.25s ease;
}

.vip-card-box:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.18);
}

/* 各色主题：统一跨端 5 级会员色彩体系 */
.theme-emerald {
  /* 普卡/普通会员: 翡翠石绿 (#0D9488) */
  background: linear-gradient(135deg, #042f2e 0%, #0d9488 60%, #14b8a6 100%);
  border: 1px solid #14b8a6;
}

.theme-blue {
  /* 银卡会员: 冰川湖蓝 (#0284C7) */
  background: linear-gradient(135deg, #075985 0%, #0284c7 60%, #38bdf8 100%);
  border: 1px solid #38bdf8;
}

.theme-gold {
  /* 黄金VIP卡: 香槟琥珀金 (#D97706) */
  background: linear-gradient(135deg, #78350f 0%, #d97706 60%, #fbbf24 100%);
  border: 1px solid #f59e0b;
}

.theme-purple {
  /* 铂金尊享卡: 皇家紫晶 (#7C3AED) */
  background: linear-gradient(135deg, #4c1d95 0%, #7c3aed 60%, #c084fc 100%);
  border: 1px solid #c4b5fd;
}

.theme-black {
  /* 黑金至尊卡/黑钻: 曜石黑金底 + 烫金边框 (#0F172A / #F59E0B) */
  background: linear-gradient(135deg, #090d16 0%, #0f172a 60%, #1e293b 100%);
  border: 1.5px solid #f59e0b;
  box-shadow: 0 4px 16px rgba(245, 158, 11, 0.25);
}

/* 芯片装饰 */
.card-chip {
  width: 38px;
  height: 28px;
  background: linear-gradient(135deg, #fbbf24, #d97706);
  border-radius: 5px;
  position: relative;
  overflow: hidden;
}

.chip-lines {
  position: absolute;
  top: 50%;
  left: 0;
  right: 0;
  height: 1px;
  background: rgba(0, 0, 0, 0.2);
}

.vip-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-brand-tag {
  display: flex;
  align-items: center;
  gap: 6px;
}

.brand-text {
  font-size: 11px;
  letter-spacing: 1px;
  font-weight: 700;
  opacity: 0.85;
}

.type-pill {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  font-size: 11px;
}

.vip-card-body {
  margin: 14px 0;
}

.vip-card-name {
  font-size: 17px;
  font-weight: 700;
  line-height: 1.3;
  margin-bottom: 6px;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
}

.vip-card-desc {
  font-size: 12px;
  opacity: 0.88;
  line-height: 1.4;
}

/* 折扣角标 */
.discount-ribbon {
  position: absolute;
  top: 14px;
  right: -28px;
  background: #ef4444;
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  padding: 3px 28px;
  transform: rotate(45deg);
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.vip-card-footer {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
}

.price-currency {
  font-size: 14px;
  font-weight: 600;
}

.price-number {
  font-size: 22px;
  font-weight: 800;
}

.price-origin {
  font-size: 12px;
  text-decoration: line-through;
  opacity: 0.65;
  margin-left: 6px;
}

.card-actions {
  display: flex;
  gap: 6px;
}

/* 列表表格视图 */
.card-title-cell {
  display: flex;
  flex-direction: column;
}

.font-bold {
  font-weight: 600;
  color: #0f172a;
}

.card-code-sub {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
}

.bold-price {
  font-weight: 700;
  color: #0284c7;
  font-size: 15px;
}

.origin-price {
  display: block;
  font-size: 11px;
  color: #94a3b8;
  text-decoration: line-through;
}

.content-desc-cell {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #334155;
}

.desc-tag-icon {
  font-size: 14px;
}

.theme-badge-dot {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
}

.theme-circle {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.theme-dot-gold { background-color: #f59e0b; }
.theme-dot-black { background-color: #1e293b; }
.theme-dot-blue { background-color: #0284c7; }
.theme-dot-emerald { background-color: #10b981; }
.theme-dot-purple { background-color: #8b5cf6; }

.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

/* 弹窗布局 */
.dialog-content-layout {
  display: grid;
  grid-template-columns: 1.35fr 1fr;
  gap: 24px;
}

@media (max-width: 860px) {
  .dialog-content-layout {
    grid-template-columns: 1fr;
  }
}

/* 核心价格与额度配置卡片专区 */
.pricing-card-section {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px 16px;
  margin-bottom: 18px;
}

.pricing-section-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.p-title-left {
  display: flex;
  align-items: center;
  gap: 6px;
}

.p-icon {
  font-size: 16px;
}

.p-title {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
}

.p-sub-badge {
  font-size: 11px;
  color: #0284c7;
  background: #e0f2fe;
  padding: 2px 8px;
  border-radius: 12px;
  font-weight: 600;
}

.pricing-row-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.stored-grid {
  margin-top: 10px;
}

.price-input-box {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 10px 12px;
  transition: all 0.2s ease;
}

.price-input-box:hover {
  border-color: #cbd5e1;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.box-sale {
  border-left: 3px solid #0284c7;
}

.box-origin {
  border-left: 3px solid #94a3b8;
}

.box-principal {
  border-left: 3px solid #2563eb;
}

.box-gift {
  border-left: 3px solid #10b981;
}

.box-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.box-title {
  display: flex;
  align-items: center;
  gap: 2px;
}

.box-label {
  font-size: 12px;
  font-weight: 700;
  color: #334155;
}

.req-dot {
  color: #ef4444;
  font-weight: bold;
}

.box-tag {
  font-size: 10px;
  padding: 1px 6px;
  border-radius: 4px;
  font-weight: 600;
}

.tag-sale {
  background: #e0f2fe;
  color: #0284c7;
}

.tag-origin {
  background: #f1f5f9;
  color: #64748b;
}

.tag-principal {
  background: #eff6ff;
  color: #2563eb;
}

.tag-gift {
  background: #ecfdf5;
  color: #059669;
}

.box-input-wrap {
  display: flex;
  align-items: center;
  gap: 4px;
}

.c-symbol {
  font-size: 15px;
  font-weight: 800;
  color: #0284c7;
}

.gift-symbol {
  color: #059669;
}

.styled-price-input {
  width: 100%;
}

.styled-price-input :deep(.el-input__inner) {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: 0.3px;
}

.gift-input :deep(.el-input__inner) {
  color: #059669;
}

.box-hint {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 4px;
  line-height: 1.3;
}

/* 储值卡动态到账核算条 */
.stored-calc-strip {
  margin-top: 12px;
  background: linear-gradient(135deg, #eff6ff 0%, #f0fdf4 100%);
  border: 1px dashed #93c5fd;
  border-radius: 8px;
  padding: 9px 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
}

.strip-left {
  display: flex;
  align-items: center;
  gap: 6px;
}

.calc-icon {
  font-size: 16px;
}

.strip-text {
  font-size: 12px;
  color: #1e293b;
}

.total-arrival {
  font-size: 15px;
  font-weight: 800;
  color: #059669;
}

.strip-right {
  font-size: 11px;
  color: #64748b;
}

.detail-split {
  background: #ffffff;
  padding: 2px 8px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.discount-config-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 10px;
  font-size: 12px;
  color: #475569;
}

.discount-label {
  font-weight: 600;
}

.discount-text-tip {
  color: #94a3b8;
}

.dialog-preview-pane {
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.preview-title {
  font-size: 13px;
  font-weight: 600;
  color: #475569;
  margin-bottom: 12px;
}

.preview-card {
  width: 100%;
  max-width: 320px;
}

.validity-badge {
  font-size: 11px;
  background: rgba(255, 255, 255, 0.2);
  padding: 2px 8px;
  border-radius: 10px;
}

.preview-hint {
  margin-top: 14px;
  font-size: 11px;
  color: #94a3b8;
  text-align: center;
}
</style>
