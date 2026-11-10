<template>
  <div class="vendor-industry-presets-page">
    <!-- 头部横幅与行业切换器 -->
    <el-card shadow="hover" class="header-card" style="border-left: 5px solid #6366f1; margin-bottom: 16px;">
      <div class="page-top-bar">
        <div>
          <div class="top-title">
            <span class="badge-icon">👑</span>
            <span>常用行业预设全景配置中心（超级管理员专属）</span>
          </div>
          <div class="top-subtitle">
            统一维护全平台 7 大主流实体行业的标准公共模板。超级管理员在此配置的【会员卡设置】、【常态偏好标签】、【首充方案】与【部门岗位架构】将被全平台所有商户一键载入与持久化应用。
          </div>
        </div>

        <div class="top-actions">
          <el-button type="warning" plain icon="RefreshLeft" @click="handleResetIndustryPreset" :loading="resetting">
            🔄 恢复出厂推荐预设
          </el-button>
          <el-button type="primary" size="large" icon="Check" @click="handleSaveIndustryPreset" :loading="saving">
            💾 保存当前行业配置至数据库
          </el-button>
        </div>
      </div>

      <!-- 7 大行业选择胶囊 -->
      <div class="industry-pills-bar">
        <div
          v-for="item in industryList"
          :key="item.code"
          :class="['industry-pill', currentIndustry === item.code ? 'active' : '']"
          @click="handleChangeIndustry(item.code)"
        >
          <span class="pill-icon">{{ item.icon }}</span>
          <span class="pill-name">{{ item.name }}</span>
          <span class="pill-code">{{ item.code }}</span>
        </div>
      </div>

      <div class="status-summary-bar">
        <span>当前编辑行业：<b style="color: #4f46e5;">{{ currentIndustryName }}</b> ({{ currentIndustry }})</span>
        <span style="color: #64748b;">最后持久化时间：{{ lastUpdatedAt || '系统内置初始化' }}</span>
        <span style="color: #64748b;">最后操作人：{{ lastUpdatedBy || '超级管理员' }}</span>
      </div>
    </el-card>

    <!-- 4 大核心业务子页签配置区域 -->
    <el-card shadow="hover" class="content-card">
      <el-tabs v-model="activeTab" class="custom-tabs">
        <!-- Tab 1: 💳 会员卡设置与等级权益 -->
        <el-tab-pane label="💳 会员卡设置与等级权益" name="cards">
          <div class="section-intro">
            <div class="intro-text">
              💡 <b>配置说明</b>：为 <b>{{ currentIndustryName }}</b> 配置推荐的会员卡模板、充值门槛、服务折扣率、有效天数及专属权益。商户可在会员卡包中直接一键套用该体系。
            </div>
            <el-button type="primary" icon="Plus" @click="handleOpenAddCard">
              + 新增会员卡模板
            </el-button>
          </div>

          <el-table :data="cardTemplates" border stripe style="width: 100%; margin-top: 14px;">
            <el-table-column label="会员卡名称" min-width="160">
              <template #default="{ row }">
                <div style="font-weight: 700; color: #1e293b; display: flex; align-items: center; gap: 6px;">
                  <span>{{ row.cardName }}</span>
                  <el-tag :type="getCardThemeTag(row.themeColor)" size="small">{{ getCardTypeName(row.cardType) }}</el-tag>
                </div>
                <div style="font-size: 11px; color: #64748b; margin-top: 2px;">卡面配色: {{ row.themeColor || 'gold' }}</div>
              </template>
            </el-table-column>
            <el-table-column label="卡种分类" width="120" align="center">
              <template #default="{ row }">
                <el-tag size="small" effect="plain">{{ row.cardTypeName || getCardTypeName(row.cardType) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="售价 / 储值门槛" width="140" align="center">
              <template #default="{ row }">
                <span style="font-weight: bold; color: #059669; font-size: 14px;">￥{{ row.price }}</span>
                <div v-if="row.originalPrice && row.originalPrice > row.price" style="font-size: 11px; color: #94a3b8; text-decoration: line-through;">
                  原价￥{{ row.originalPrice }}
                </div>
              </template>
            </el-table-column>
            <el-table-column label="折扣率" width="110" align="center">
              <template #default="{ row }">
                <el-tag v-if="row.discountRate" type="success" size="small">
                  {{ (row.discountRate * 10).toFixed(1) }} 折
                </el-tag>
                <span v-else style="color: #94a3b8; font-size: 12px;">--</span>
              </template>
            </el-table-column>
            <el-table-column label="有效期" width="110" align="center">
              <template #default="{ row }">
                <span>{{ row.validityDays ? row.validityDays + ' 天' : '永久有效' }}</span>
              </template>
            </el-table-column>
            <el-table-column label="核心权益与内容描述" min-width="240">
              <template #default="{ row }">
                <div style="font-size: 13px; color: #334155; line-height: 1.5;">{{ row.contentDescription }}</div>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="140" align="center" fixed="right">
              <template #default="{ row, $index }">
                <el-button link type="primary" size="small" @click="handleEditCard(row, $index)">编辑</el-button>
                <el-button link type="danger" size="small" @click="handleDeleteCard($index)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- Tab 2: 🧠 顾客个人常态偏好配置 -->
        <el-tab-pane label="🧠 顾客个人常态偏好配置" name="preference">
          <div class="section-intro">
            <div class="intro-text">
              💡 <b>配置说明</b>：为 <b>{{ currentIndustryName }}</b> 定制标准熟客常态偏好标签池。商户在【会员中心】->【开卡配置】中点击载入行业推荐标签时，将实时拉取此处配置的标签。
            </div>
            <div style="display: flex; gap: 8px;">
              <el-button type="danger" plain size="small" @click="preferenceTags = []" :disabled="preferenceTags.length === 0">
                清空全部标签
              </el-button>
            </div>
          </div>

          <!-- 标签展示面板 -->
          <div class="pref-tags-container">
            <div class="pref-tags-header">
              <span style="font-size: 13px; font-weight: 700; color: #1e293b;">
                当前行业推荐标签池 (共 {{ preferenceTags.length }} 个)
              </span>
              <span style="font-size: 12px; color: #64748b;">支持自由点击标签后的 ✖️ 删除，或在下方输入快速新增</span>
            </div>

            <div v-if="preferenceTags.length > 0" class="pref-tags-list">
              <el-tag
                v-for="(tag, index) in preferenceTags"
                :key="tag + index"
                closable
                size="large"
                type="primary"
                effect="light"
                class="pref-tag-item"
                @close="handleRemovePrefTag(index)"
              >
                🏷️ {{ tag }}
              </el-tag>
            </div>
            <div v-else class="empty-tags-box">
              <el-empty description="当前行业暂未配置任何偏好标签，请在下方快速输入或点击推荐关键词引入" :image-size="80" />
            </div>
          </div>

          <!-- 添加标签操作栏 -->
          <div class="add-tag-bar">
            <el-input
              v-model="newTagInput"
              placeholder="输入新偏好标签（如：免葱蒜、喜静免推销、水温偏热、偏爱全合成机油）..."
              style="width: 420px;"
              clearable
              @keyup.enter="handleAddPrefTag"
            />
            <el-button type="primary" icon="Plus" @click="handleAddPrefTag">
              添加至标签池
            </el-button>
          </div>

          <!-- 智能备选标签快捷气泡 -->
          <div class="suggested-tags-box">
            <span class="suggest-label">💡 常见备选关键词：</span>
            <div class="suggest-pills">
              <el-button
                v-for="kw in getSuggestedTagsForIndustry(currentIndustry)"
                :key="kw"
                size="small"
                round
                :disabled="preferenceTags.includes(kw)"
                @click="handleAddSpecificTag(kw)"
              >
                + {{ kw }}
              </el-button>
            </div>
          </div>
        </el-tab-pane>

        <!-- Tab 3: 🎁 开卡首充与充多少送多少方案 -->
        <el-tab-pane label="🎁 开卡首充与充多少送多少方案" name="charge">
          <div class="section-intro">
            <div class="intro-text">
              💡 <b>配置说明</b>：为 <b>{{ currentIndustryName }}</b> 配置顾客扫码自主开卡时呈现的充值立赠体验方案、营销角标与对应的初始会员等级。
            </div>
            <el-button type="primary" icon="Plus" @click="handleAddChargeOption">
              + 新增充值立赠方案
            </el-button>
          </div>

          <el-table :data="chargeOptions" border stripe style="width: 100%; margin-top: 14px;">
            <el-table-column label="方案名称" min-width="160">
              <template #default="{ row }">
                <el-input v-model="row.title" placeholder="如：首充礼遇 ￥200" size="small" />
              </template>
            </el-table-column>
            <el-table-column label="充值本金 (元)" width="150" align="center">
              <template #default="{ row }">
                <el-input-number v-model="row.principal" :min="0" :step="50" size="small" style="width: 100%;" />
              </template>
            </el-table-column>
            <el-table-column label="立赠金额 (元)" width="150" align="center">
              <template #default="{ row }">
                <el-input-number v-model="row.gift" :min="0" :step="10" size="small" style="width: 100%;" />
              </template>
            </el-table-column>
            <el-table-column label="营销角标" width="140" align="center">
              <template #default="{ row }">
                <el-input v-model="row.badge" placeholder="如：立赠50元" size="small" />
              </template>
            </el-table-column>
            <el-table-column label="对应初始会员等级" min-width="180">
              <template #default="{ row }">
                <el-select v-model="row.levelName" size="small" style="width: 100%;" @change="(val: string) => handleLevelChange(row, val)">
                  <el-option
                    v-for="lvl in standardLevelList"
                    :key="lvl.levelCode"
                    :label="lvl.label"
                    :value="lvl.levelName"
                  />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="100" align="center">
              <template #default="{ $index }">
                <el-button type="danger" link size="small" @click="chargeOptions.splice($index, 1)" :disabled="chargeOptions.length <= 1">
                  删除
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- Tab 4: 🏢 常用的部门和在编岗位 -->
        <el-tab-pane label="🏢 常用的部门和在编岗位" name="org">
          <div class="section-intro">
            <div class="intro-text">
              💡 <b>配置说明</b>：为 <b>{{ currentIndustryName }}</b> 配置行业标准部门架构与核心在编岗位。商户在【部门架构与岗位管理】页面点击【载入行业推荐】时，将完整载入此处设定的部门与在编岗位。
            </div>
          </div>

          <!-- 子模块 A: 常用部门架构 -->
          <div class="org-sub-card">
            <div class="org-sub-title">
              <span>🏢 该行业常用部门架构列表 (共 {{ departments.length }} 个部门)</span>
              <div style="display: flex; gap: 8px;">
                <el-input
                  v-model="newDeptInput"
                  placeholder="输入新部门名称 (如：品质保障部)..."
                  size="small"
                  style="width: 220px;"
                  @keyup.enter="handleAddDepartment"
                />
                <el-button type="primary" size="small" icon="Plus" @click="handleAddDepartment">
                  添加部门
                </el-button>
              </div>
            </div>
            <div class="dept-chips-container">
              <el-tag
                v-for="(dept, index) in departments"
                :key="dept + index"
                closable
                size="large"
                type="success"
                effect="light"
                class="dept-chip"
                @close="handleRemoveDepartment(index)"
              >
                🏢 {{ dept }}
              </el-tag>
            </div>
          </div>

          <!-- 子模块 B: 推荐在编岗位编制 -->
          <div class="org-sub-card" style="margin-top: 16px;">
            <div class="org-sub-title">
              <span>💼 推荐在编岗位编制明细 (共 {{ positions.length }} 个在编岗位)</span>
              <el-button type="primary" size="small" icon="Plus" @click="handleOpenAddPosition">
                + 新增推荐岗位
              </el-button>
            </div>

            <el-table :data="positions" border stripe style="width: 100%; margin-top: 10px;">
              <el-table-column label="岗位名称" min-width="160">
                <template #default="{ row }">
                  <div style="font-weight: 700; color: #1e293b;">{{ row.postName }}</div>
                  <div style="font-size: 11px; color: #64748b;">职务代号: {{ row.postCode || 'TECHNICIAN' }}</div>
                </template>
              </el-table-column>
              <el-table-column label="所属部门" width="140" align="center">
                <template #default="{ row }">
                  <el-tag size="small" type="info">{{ row.department }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="建议薪资待遇" min-width="150">
                <template #default="{ row }">
                  <div style="color: #059669; font-weight: bold;">{{ row.salaryRange || ('￥' + row.baseSalary + '/月') }}</div>
                  <div style="font-size: 11px; color: #64748b;">提成建议: {{ ((row.commissionRate || 0) * 100).toFixed(0) }}%</div>
                </template>
              </el-table-column>
              <el-table-column label="核心工作职责" min-width="220">
                <template #default="{ row }">
                  <div style="font-size: 12px; color: #334155; line-height: 1.5;">{{ row.description }}</div>
                </template>
              </el-table-column>
              <el-table-column label="任职资格要求" min-width="200">
                <template #default="{ row }">
                  <div style="font-size: 12px; color: #475569; line-height: 1.5;">{{ row.requirements }}</div>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="130" align="center" fixed="right">
                <template #default="{ row, $index }">
                  <el-button link type="primary" size="small" @click="handleEditPosition(row, $index)">编辑</el-button>
                  <el-button link type="danger" size="small" @click="positions.splice($index, 1)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 会员卡新增/编辑弹窗 -->
    <el-dialog
      v-model="cardModalVisible"
      :title="editingCardIndex === -1 ? '➕ 新增行业推荐会员卡' : '✏️ 编辑行业推荐会员卡'"
      width="600px"
      destroy-on-close
    >
      <el-form :model="cardForm" label-width="120px">
        <el-form-item label="卡片名称" required>
          <el-input v-model="cardForm.cardName" placeholder="如：丝艺金卡 ￥1000、草本养生10次卡" />
        </el-form-item>
        <el-form-item label="会员卡类型" required>
          <el-select v-model="cardForm.cardType" style="width: 100%;" @change="handleCardTypeSelect">
            <el-option label="储值本金卡 (STORED_VALUE)" value="STORED_VALUE" />
            <el-option label="服务计次卡 (TIME_CARD)" value="TIME_CARD" />
            <el-option label="时效期限卡 (DURATION_CARD)" value="DURATION_CARD" />
            <el-option label="尊享权益卡 (BENEFIT_CARD)" value="BENEFIT_CARD" />
          </el-select>
        </el-form-item>
        <el-form-item label="售卖 / 门槛金额" required>
          <el-input-number v-model="cardForm.price" :min="0" :step="100" style="width: 200px;" />
          <span style="margin-left: 10px; font-size: 12px; color: #64748b;">元</span>
        </el-form-item>
        <el-form-item label="服务折扣率">
          <el-input-number v-model="cardForm.discountRate" :min="0.1" :max="1.0" :step="0.05" :precision="2" style="width: 200px;" />
          <span style="margin-left: 10px; font-size: 12px; color: #059669;">
            {{ (cardForm.discountRate * 10).toFixed(1) }} 折 (1.0表示不打折)
          </span>
        </el-form-item>
        <el-form-item label="有效天数">
          <el-input-number v-model="cardForm.validityDays" :min="0" :step="30" style="width: 200px;" />
          <span style="margin-left: 10px; font-size: 12px; color: #64748b;">天 (填0或365)</span>
        </el-form-item>
        <el-form-item label="卡面主题风格">
          <el-select v-model="cardForm.themeColor" style="width: 200px;">
            <el-option label="黑金尊崇 (black)" value="black" />
            <el-option label="奢华金黄 (gold)" value="gold" />
            <el-option label="典雅魅紫 (purple)" value="purple" />
            <el-option label="商务湛蓝 (blue)" value="blue" />
            <el-option label="清心翠绿 (emerald)" value="emerald" />
            <el-option label="浪漫粉红 (rose)" value="rose" />
          </el-select>
        </el-form-item>
        <el-form-item label="权益内容描述" required>
          <el-input
            v-model="cardForm.contentDescription"
            type="textarea"
            :rows="3"
            placeholder="描述此卡包含的核心服务权益、折扣范围、赠送项目等..."
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="cardModalVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveCardForm">确认保存</el-button>
      </template>
    </el-dialog>

    <!-- 推荐岗位新增/编辑弹窗 -->
    <el-dialog
      v-model="positionModalVisible"
      :title="editingPositionIndex === -1 ? '➕ 新增行业推荐岗位编制' : '✏️ 编辑行业推荐岗位编制'"
      width="640px"
      destroy-on-close
    >
      <el-form :model="positionForm" label-width="120px">
        <el-form-item label="岗位名称" required>
          <el-input v-model="positionForm.postName" placeholder="如：发型总监、主厨、养生技师、快修技师" />
        </el-form-item>
        <el-form-item label="所属部门" required>
          <el-select v-model="positionForm.department" style="width: 100%;" filterable allow-create>
            <el-option v-for="d in departments" :key="d" :label="d" :value="d" />
          </el-select>
        </el-form-item>
        <el-form-item label="薪资范围描述">
          <el-input v-model="positionForm.salaryRange" placeholder="如：￥6000-11000元/月" />
        </el-form-item>
        <el-form-item label="建议底薪 (元)">
          <el-input-number v-model="positionForm.baseSalary" :min="0" :step="500" style="width: 200px;" />
        </el-form-item>
        <el-form-item label="提成比例建议">
          <el-input-number v-model="positionForm.commissionRate" :min="0" :max="1" :step="0.05" :precision="2" style="width: 200px;" />
          <span style="margin-left: 10px; font-size: 12px; color: #059669;">
            {{ ((positionForm.commissionRate || 0) * 100).toFixed(0) }}%
          </span>
        </el-form-item>
        <el-form-item label="核心工作职责" required>
          <el-input
            v-model="positionForm.description"
            type="textarea"
            :rows="3"
            placeholder="详细描述该岗位的核心服务交付职责与日常工作要求..."
          />
        </el-form-item>
        <el-form-item label="任职资格要求">
          <el-input
            v-model="positionForm.requirements"
            type="textarea"
            :rows="2"
            placeholder="如：具备3年以上相关行业工作经验、持证者优先等..."
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="positionModalVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSavePositionForm">确认保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  getIndustryPresetTemplateApi,
  saveIndustryPresetTemplateApi,
  resetIndustryPresetTemplateApi
} from '../api'

const industryList = [
  { code: 'BEAUTY', name: '美容美发美甲', icon: '💇' },
  { code: 'RESTAURANT', name: '餐饮美食饮品', icon: '🍲' },
  { code: 'FOOT_SPA', name: '足道养生推拿', icon: '💆' },
  { code: 'AUTO', name: '汽车维保洗美', icon: '🚗' },
  { code: 'TEA_HOUSE', name: '商务茶楼棋牌', icon: '🍵' },
  { code: 'PET', name: '宠物生活洗护', icon: '🐾' },
  { code: 'RETAIL', name: '综合商超零售', icon: '🛍️' }
]

const currentIndustry = ref('BEAUTY')
const currentIndustryName = computed(() => {
  return industryList.find(i => i.code === currentIndustry.value)?.name || '品质美业'
})

const activeTab = ref('cards')
const saving = ref(false)
const resetting = ref(false)
const lastUpdatedAt = ref('')
const lastUpdatedBy = ref('')

// 会员卡列表
const cardTemplates = ref<any[]>([])
// 偏好标签列表
const preferenceTags = ref<string[]>([])
// 开卡首充列表
const chargeOptions = ref<any[]>([])
// 常用部门列表
const departments = ref<string[]>([])
// 在编岗位列表
const positions = ref<any[]>([])

// ----------------------------------------------------------------------------
// 会员等级映射
// ----------------------------------------------------------------------------
const standardLevelList = [
  { levelCode: 'REGULAR', levelName: '普卡会员', label: '🥉 普卡会员 (基础入会)' },
  { levelCode: 'SILVER', levelName: '荣耀银卡', label: '🥈 荣耀银卡 (9.5折特权)' },
  { levelCode: 'GOLD', levelName: '黄金VIP卡', label: '🥇 黄金VIP卡 (8.8折爆款)' },
  { levelCode: 'VIP', levelName: 'VIP尊享卡', label: '👑 VIP尊享卡 (8.5折尊贵)' },
  { levelCode: 'PLATINUM', levelName: '至尊白金卡', label: '💎 至尊白金卡 (8.0折尊享)' },
  { levelCode: 'DIAMOND', levelName: '黑钻至尊卡', label: '🌌 黑钻至尊卡 (7.5折顶格)' }
]

const handleLevelChange = (row: any, val: string) => {
  const match = standardLevelList.find(l => l.levelName === val)
  if (match) {
    row.levelCode = match.levelCode
  }
}

// ----------------------------------------------------------------------------
// 加载与切换行业
// ----------------------------------------------------------------------------
const loadIndustryPreset = async (ind: string) => {
  try {
    const res: any = await getIndustryPresetTemplateApi(ind)
    const data = res?.data || res
    if (data) {
      cardTemplates.value = Array.isArray(data.cardTemplates) ? data.cardTemplates : []
      preferenceTags.value = Array.isArray(data.preferenceTags) ? data.preferenceTags : []
      chargeOptions.value = Array.isArray(data.chargeOptions) ? data.chargeOptions : []
      departments.value = Array.isArray(data.departments) ? data.departments : []
      positions.value = Array.isArray(data.positions) ? data.positions : []
      lastUpdatedAt.value = data.updatedAt ? String(data.updatedAt).replace('T', ' ').substring(0, 19) : ''
      lastUpdatedBy.value = data.updatedBy || '超级管理员'
    }
  } catch (err: any) {
    ElMessage.error('拉取行业预设数据失败: ' + (err.message || '网络异常'))
  }
}

const handleChangeIndustry = (ind: string) => {
  currentIndustry.value = ind
  loadIndustryPreset(ind)
}

onMounted(() => {
  loadIndustryPreset(currentIndustry.value)
})

// ----------------------------------------------------------------------------
// 保存至云端数据库
// ----------------------------------------------------------------------------
const handleSaveIndustryPreset = async () => {
  saving.value = true
  try {
    const payload = {
      industry: currentIndustry.value,
      industryName: currentIndustryName.value,
      cardTemplates: cardTemplates.value,
      preferenceTags: preferenceTags.value,
      chargeOptions: chargeOptions.value,
      departments: departments.value,
      positions: positions.value
    }
    await saveIndustryPresetTemplateApi(payload)
    ElMessage.success(`🎉 【${currentIndustryName.value}】全景配置已成功保存至系统数据库！全平台商户载入时将即时生效。`)
    await loadIndustryPreset(currentIndustry.value)
  } catch (err: any) {
    ElMessage.error('保存行业全景配置失败: ' + (err.message || '系统异常'))
  } finally {
    saving.value = false
  }
}

// ----------------------------------------------------------------------------
// 恢复出厂预设
// ----------------------------------------------------------------------------
const handleResetIndustryPreset = () => {
  ElMessageBox.confirm(
    `确定要将【${currentIndustryName.value}】恢复为系统出厂标准预设吗？这将覆盖当前已保存的卡种、偏好标签、首充方案与部门岗位编制。`,
    '恢复出厂预设确认',
    { confirmButtonText: '确定重置', cancelButtonText: '取消', type: 'warning' }
  ).then(async () => {
    resetting.value = true
    try {
      await resetIndustryPresetTemplateApi(currentIndustry.value)
      ElMessage.success(`【${currentIndustryName.value}】已成功重置为出厂标准配置！`)
      await loadIndustryPreset(currentIndustry.value)
    } catch (err: any) {
      ElMessage.error('恢复出厂预设失败: ' + (err.message || '系统异常'))
    } finally {
      resetting.value = false
    }
  })
}

// ----------------------------------------------------------------------------
// Tab 1: 会员卡操作
// ----------------------------------------------------------------------------
const cardModalVisible = ref(false)
const editingCardIndex = ref(-1)
const cardForm = ref<any>({
  cardName: '',
  cardType: 'STORED_VALUE',
  cardTypeName: '储值卡',
  price: 1000,
  originalPrice: 1000,
  discountRate: 0.88,
  validityDays: 365,
  themeColor: 'gold',
  contentDescription: ''
})

const getCardTypeName = (type: string) => {
  switch (type) {
    case 'STORED_VALUE': return '储值卡'
    case 'TIME_CARD': return '次卡'
    case 'DURATION_CARD': return '期限卡'
    case 'BENEFIT_CARD': return '权益卡'
    default: return '会员卡'
  }
}

const getCardThemeTag = (color: string) => {
  switch (color) {
    case 'black': return 'info'
    case 'gold': return 'warning'
    case 'purple': return ''
    case 'blue': return 'primary'
    case 'emerald': return 'success'
    case 'rose': return 'danger'
    default: return 'warning'
  }
}

const handleCardTypeSelect = (type: string) => {
  cardForm.value.cardTypeName = getCardTypeName(type)
}

const handleOpenAddCard = () => {
  editingCardIndex.value = -1
  cardForm.value = {
    cardName: '',
    cardType: 'STORED_VALUE',
    cardTypeName: '储值卡',
    price: 1000,
    originalPrice: 1000,
    discountRate: 0.88,
    validityDays: 365,
    themeColor: 'gold',
    contentDescription: ''
  }
  cardModalVisible.value = true
}

const handleEditCard = (row: any, index: number) => {
  editingCardIndex.value = index
  cardForm.value = { ...row }
  cardModalVisible.value = true
}

const handleSaveCardForm = () => {
  if (!cardForm.value.cardName.trim()) {
    ElMessage.warning('请输入会员卡名称')
    return
  }
  if (!cardForm.value.contentDescription.trim()) {
    ElMessage.warning('请输入权益内容描述')
    return
  }
  if (editingCardIndex.value === -1) {
    cardTemplates.value.push({
      ...cardForm.value,
      id: Date.now(),
      status: 'ACTIVE'
    })
    ElMessage.success('已添加会员卡模板')
  } else {
    cardTemplates.value[editingCardIndex.value] = { ...cardForm.value }
    ElMessage.success('会员卡模板已更新')
  }
  cardModalVisible.value = false
}

const handleDeleteCard = (index: number) => {
  cardTemplates.value.splice(index, 1)
  ElMessage.success('已删除该会员卡模板')
}

// ----------------------------------------------------------------------------
// Tab 2: 偏好标签操作
// ----------------------------------------------------------------------------
const newTagInput = ref('')

const handleAddPrefTag = () => {
  const text = newTagInput.value.trim()
  if (!text) return
  if (preferenceTags.value.includes(text)) {
    ElMessage.warning('该标签已在列表中')
    return
  }
  preferenceTags.value.push(text)
  newTagInput.value = ''
  ElMessage.success(`已添加标签【${text}】`)
}

const handleAddSpecificTag = (tag: string) => {
  if (!preferenceTags.value.includes(tag)) {
    preferenceTags.value.push(tag)
    ElMessage.success(`已加入【${tag}】`)
  }
}

const handleRemovePrefTag = (index: number) => {
  preferenceTags.value.splice(index, 1)
}

const getSuggestedTagsForIndustry = (ind: string): string[] => {
  switch (ind) {
    case 'RESTAURANT':
      return ['微辣免葱', '少盐少油少糖', '偏爱安静包厢', '不吃香菜姜蒜', '常带儿童就餐', '自备酒水', '海鲜不过敏', '米饭稍软', '温水伺候', '包厢宴请']
    case 'FOOT_SPA':
      return ['力度偏重', '力度适中', '中药足浴包偏好', '精油开背偏好', '喜好安静免推销', '肩颈重点加强', '修脚去死皮偏好', '饮品偏好红枣枸杞茶', '常备艾草包', '畏寒需加毛毯']
    case 'AUTO':
      return ['全合成机油偏好', '定期深度底盘检查', '车内高温桑拿除味', '原厂配件优先', '空调滤芯定期换', '轮胎动平衡常检', '偏好周末维保', '洗车需深度除尘', '刹车片定期磨损检', '轮毂深度除锈']
    case 'TEA_HOUSE':
      return ['偏爱生普/白茶', '水温要求沸水', '偏爱安静雅间', '自备茶叶仅需茶具', '需要商务投影', '茶点少糖偏好', '常备坚果果盘', '喜好棋牌娱乐', '需要隔音包房', '偏好岩茶大红袍']
    case 'PET':
      return ['胆小敏感易应激', '皮肤敏感需低敏香波', '拒绝强行烘干箱', '洗澡需剪指甲', '定期驱虫', '喜好零食奖励', '长毛易打结需开结', '自备洗护专用品', '怕水需轻柔抚慰', '大体型温顺']
    case 'RETAIL':
      return ['偏好有机绿色无公害', '精致礼盒送礼包装', '积分抵现结算优先', '新品尝鲜品鉴体验', '少塑环保包装', '定期促销推送偏好', '冷链保温配送', '喜欢大份家庭装', '支持送货上门', '喜欢试吃品鉴']
    case 'BEAUTY':
    default:
      return ['发质细软', '敏感头皮', '偏爱自然修剪', '偏爱冷色调烫染', '喜好安静免推销', '定期头皮SPA', '洗头水温偏热', '饮品偏好温柠檬水', '面部敏感受损', '喜欢法式渐变']
  }
}

// ----------------------------------------------------------------------------
// Tab 3: 首充方案操作
// ----------------------------------------------------------------------------
const handleAddChargeOption = () => {
  const nextId = chargeOptions.value.length + 1
  chargeOptions.value.push({
    id: nextId,
    title: `充值档位 ￥${nextId * 300}`,
    principal: nextId * 300,
    gift: nextId * 80,
    badge: '限时特惠',
    levelName: '黄金VIP卡',
    levelCode: 'GOLD'
  })
}

// ----------------------------------------------------------------------------
// Tab 4: 部门与在编岗位操作
// ----------------------------------------------------------------------------
const newDeptInput = ref('')

const handleAddDepartment = () => {
  const name = newDeptInput.value.trim()
  if (!name) return
  if (departments.value.includes(name)) {
    ElMessage.warning('该部门已存在')
    return
  }
  departments.value.push(name)
  newDeptInput.value = ''
  ElMessage.success(`已添加部门【${name}】`)
}

const handleRemoveDepartment = (index: number) => {
  const dept = departments.value[index]
  departments.value.splice(index, 1)
  ElMessage.success(`已移除部门【${dept}】`)
}

const positionModalVisible = ref(false)
const editingPositionIndex = ref(-1)
const positionForm = ref<any>({
  postName: '',
  department: '',
  postCode: 'TECHNICIAN',
  baseSalary: 5000,
  salaryRange: '￥5000-8000元/月',
  commissionRate: 0.15,
  description: '',
  requirements: ''
})

const handleOpenAddPosition = () => {
  editingPositionIndex.value = -1
  positionForm.value = {
    postName: '',
    department: departments.value[0] || '综合管理部',
    postCode: 'TECHNICIAN',
    baseSalary: 5000,
    salaryRange: '￥5000-8000元/月',
    commissionRate: 0.15,
    description: '',
    requirements: '有相关行业工作经验'
  }
  positionModalVisible.value = true
}

const handleEditPosition = (row: any, index: number) => {
  editingPositionIndex.value = index
  positionForm.value = { ...row }
  positionModalVisible.value = true
}

const handleSavePositionForm = () => {
  if (!positionForm.value.postName.trim()) {
    ElMessage.warning('请输入岗位名称')
    return
  }
  if (!positionForm.value.department) {
    ElMessage.warning('请选择所属部门')
    return
  }
  if (editingPositionIndex.value === -1) {
    positions.value.push({
      ...positionForm.value,
      id: Date.now(),
      isRecruiting: true
    })
    ElMessage.success('已新增推荐岗位编制')
  } else {
    positions.value[editingPositionIndex.value] = { ...positionForm.value }
    ElMessage.success('岗位编制已更新')
  }
  positionModalVisible.value = false
}
</script>

<style scoped>
.vendor-industry-presets-page {
  padding: 16px;
  background-color: #f8fafc;
  min-height: calc(100vh - 100px);
}

.page-top-bar {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 16px;
}

.top-title {
  font-size: 20px;
  font-weight: 800;
  color: #1e293b;
  display: flex;
  align-items: center;
  gap: 8px;
}

.top-subtitle {
  font-size: 13px;
  color: #64748b;
  margin-top: 6px;
  line-height: 1.6;
  max-width: 900px;
}

.top-actions {
  display: flex;
  gap: 12px;
  align-items: center;
}

.industry-pills-bar {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  margin-top: 10px;
  padding-top: 12px;
  border-top: 1px solid #f1f5f9;
}

.industry-pill {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 8px 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s ease;
  user-select: none;
}

.industry-pill:hover {
  border-color: #6366f1;
  transform: translateY(-1px);
  box-shadow: 0 2px 6px rgba(99, 102, 241, 0.12);
}

.industry-pill.active {
  background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
  border-color: #4f46e5;
  color: #ffffff;
  box-shadow: 0 4px 10px rgba(99, 102, 241, 0.3);
}

.industry-pill.active .pill-name {
  color: #ffffff;
  font-weight: 700;
}

.industry-pill.active .pill-code {
  color: #c7d2fe;
}

.pill-icon {
  font-size: 18px;
}

.pill-name {
  font-size: 14px;
  font-weight: 600;
  color: #334155;
}

.pill-code {
  font-size: 11px;
  color: #94a3b8;
  font-family: monospace;
}

.status-summary-bar {
  display: flex;
  gap: 24px;
  align-items: center;
  font-size: 12.5px;
  margin-top: 14px;
  padding: 8px 12px;
  background: #f8fafc;
  border-radius: 6px;
}

.section-intro {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 12px;
}

.intro-text {
  font-size: 13px;
  color: #475569;
  line-height: 1.5;
}

.pref-tags-container {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
}

.pref-tags-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 14px;
}

.pref-tags-list {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.pref-tag-item {
  padding: 8px 14px;
  font-size: 13.5px;
}

.add-tag-bar {
  display: flex;
  gap: 10px;
  align-items: center;
  margin-bottom: 16px;
}

.suggested-tags-box {
  background: #f1f5f9;
  border-radius: 8px;
  padding: 12px 16px;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}

.suggest-label {
  font-size: 12.5px;
  font-weight: 600;
  color: #475569;
}

.suggest-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.org-sub-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 16px;
}

.org-sub-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 14px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 12px;
}

.dept-chips-container {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.dept-chip {
  padding: 8px 16px;
  font-size: 14px;
}
</style>
