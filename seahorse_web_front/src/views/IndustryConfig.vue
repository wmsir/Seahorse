<template>
  <div class="industry-page">
    <!-- 👑 超管专属全景预设配置直达条 -->
    <div style="background: linear-gradient(135deg, #eff6ff 0%, #e0e7ff 100%); border: 1px solid #c7d2fe; border-radius: 8px; padding: 12px 18px; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; box-shadow: 0 1px 3px rgba(0,0,0,0.03);">
      <div style="display: flex; align-items: center; gap: 10px;">
        <span style="font-size: 20px;">👑</span>
        <div>
          <div style="font-weight: 700; color: #1e1b4b; font-size: 14px;">常用行业预设全景配置中心（超级管理员专属）</div>
          <div style="font-size: 12px; color: #4338ca; margin-top: 2px;">
            可对 7 大常用行业（美业、餐饮、足道、汽修、茶楼、宠物、零售）的【会员卡设置】、【常态偏好配置】、【开卡首充方案】与【常用部门岗位】进行全景可视化配置与数据库持久化。
          </div>
        </div>
      </div>
      <el-button type="primary" size="small" icon="SetUp" @click="router.push('/vendor-industry-presets')">
        进入全景配置中心
      </el-button>
    </div>

    <!-- 门店细分行业分类配置 (支持初次使用配置与管理员随时修改) -->
    <el-card shadow="hover" style="border-left: 4px solid #0284c7;">
      <template #header>
        <div class="card-header">
          <div>
            <span class="header-title">🏬 门店细分行业分类 (管理员初次使用与日常修改)</span>
            <div class="header-desc">支持26个细分实体业态（汽车服务、美业服务、餐饮店、便利店等），初次开店或业态调整时可在此配置</div>
          </div>
          <el-tag v-if="currentProfile?.industryCategoryName" type="success" size="large" effect="dark">
            当前行业：{{ currentProfile?.industryCategoryGroup }} · {{ currentProfile?.industryCategoryName }}
          </el-tag>
          <el-tag v-else type="warning" size="large">
            ⚠️ 暂未配置细分行业（请在下方完成初次使用配置）
          </el-tag>
        </div>
      </template>

      <el-form label-width="140px" style="max-width: 600px;">
        <el-form-item label="细分行业归属" required>
          <el-cascader
            v-model="selectedCategoryCascader"
            :options="cascaderOptions"
            placeholder="请选择大类与细分行业 (如: 服务类 > 美业服务)"
            style="width: 100%;"
            @change="handleCategoryCascaderChange"
          />
        </el-form-item>
        <el-form-item label="所选行业详情">
          <div style="font-size: 13px; color: #475569; line-height: 1.6;">
            <div>已选大类：<b>{{ editCategoryGroup || '未选择' }}</b></div>
            <div>细分业态：<b>{{ editCategoryName || '未选择' }}</b> (ID: {{ editCategoryId || '-' }})</div>
          </div>
        </el-form-item>

        <el-form-item label="空间/工位业务称谓" required>
          <div style="width: 100%;">
            <div style="display: flex; gap: 8px; margin-bottom: 8px;">
              <el-input
                v-model="customSpaceAliasInput"
                placeholder="选择或直接输入专属称谓（如：包厢、工位、雅座、展位）"
                clearable
                style="flex: 1;"
              />
              <el-tag type="primary" effect="plain" style="line-height: 32px; font-weight: 600;">
                当前生效：{{ customSpaceAliasInput || '包厢' }}
              </el-tag>
            </div>
            
            <!-- 推荐快捷选择胶囊 -->
            <div class="space-alias-capsules">
              <span class="capsule-label">快捷业态推荐：</span>
              <el-button
                v-for="item in recommendedSpaceAliases"
                :key="item.value"
                size="small"
                :type="customSpaceAliasInput === item.value ? 'primary' : 'default'"
                round
                @click="customSpaceAliasInput = item.value"
              >
                {{ item.icon }} {{ item.label }} ({{ item.desc }})
              </el-button>
            </div>
            <div class="alias-tip-text">
              💡 <b>见名知意规则</b>：在餐饮中称呼为【<b>包厢</b>】，在修理厂中称呼为【<b>工位</b>】，美业推荐【<b>工位</b>】或【<b>镜台</b>】，专营零售推荐【<b>展位</b>】。您可直接点选推荐或自由手动输入任意名称。保存后，左侧导航栏、包厢/工位管理页、卡片看板与开台点单码将全局联动应用！
            </div>
          </div>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" :loading="savingCategory" @click="handleSaveCategory">
            保存细分行业与空间称谓配置
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card shadow="hover">
      <template #header>
        <div class="card-header">
          <div>
            <span class="header-title">⚙️ 全场景通用插拔架构 · 行业模态与策略配置</span>
            <div class="header-desc">一次架构开发，一键切换实体行业业务规则与空间模型</div>
          </div>
        </div>
      </template>

      <!-- 行业卡片选择器 -->
      <div class="industry-cards-grid">
        <div
          v-for="item in templates"
          :key="item.code"
          class="ind-card"
          :class="{ 'ind-card-active': currentProfile?.industry === item.code }"
          @click="handleSelectIndustry(item)"
        >
          <div class="ind-icon">{{ getIndustryEmoji(item.code) }}</div>
          <div class="ind-name">{{ item.name }}</div>
          <div class="ind-code">代码: {{ item.code }}</div>

          <div class="ind-details">
            <div>空间资源称谓: <b>{{ item.spaceAlias }}</b></div>
            <div>追加动作动词: <b>{{ item.appendActionAlias }}</b></div>
            <div>默认附加费: <b>{{ item.defaultFeeName }}</b></div>
          </div>

          <div v-if="currentProfile?.industry === item.code" class="active-badge">
            <el-icon><Check /></el-icon> 当前生效中
          </div>
          <div v-else class="switch-btn">
            点击切换为此行业
          </div>
        </div>
      </div>

      <el-divider />

      <!-- 附加费与规则策略配置 -->
      <div class="policy-form-box">
        <div class="policy-title">💰 行业附加费策略 (随单自动计算)</div>

        <el-form :model="policyForm" label-width="140px" style="max-width: 500px;">
          <el-form-item label="是否启用附加费">
            <el-switch v-model="policyForm.feeEnabled" />
          </el-form-item>

          <el-form-item label="附加费项目名称">
            <el-input v-model="policyForm.feeName" placeholder="如茶位费、毛巾费、工时环保费" />
          </el-form-item>

          <el-form-item label="默认单价 (元/人或车)">
            <el-input-number v-model="policyForm.feeAmount" :min="0" :precision="2" :step="1" />
          </el-form-item>

          <el-form-item>
            <el-button type="primary" :loading="saving" @click="handleSavePolicy">保存策略配置</el-button>
          </el-form-item>
        </el-form>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { getCurrentIndustryApi, switchIndustryApi, getIndustryCategoriesApi, updateStoreCategoryApi } from '../api'
import { useStoreConfig } from '../stores/store'
import { ElMessage } from 'element-plus'

const router = useRouter()
const storeConfig = useStoreConfig()
const currentProfile = ref<any>(null)
const saving = ref(false)

// 细分行业配置
const cascaderOptions = ref<any[]>([])
const selectedCategoryCascader = ref<any[]>([])
const editCategoryId = ref<number | null>(null)
const editCategoryName = ref<string>('')
const editCategoryGroup = ref<string>('')
const savingCategory = ref(false)

const customSpaceAliasInput = ref(storeConfig.spaceAlias || localStorage.getItem('seahorse_custom_space_alias') || '包厢')

const recommendedSpaceAliases = [
  { label: '包厢', value: '包厢', icon: '🍲', desc: '餐饮轻食推荐' },
  { label: '工位', value: '工位', icon: '🚗', desc: '修理厂/美业推荐' },
  { label: '台位', value: '台位', icon: '🪑', desc: '散台卡座' },
  { label: '雅座', value: '雅座', icon: '🍵', desc: '茶饮咖啡休闲' },
  { label: '镜台', value: '镜台', icon: '💇', desc: '美发造型' },
  { label: '展位', value: '展位', icon: '🛍️', desc: '专营零售' }
]

const templates = ref<any[]>([
  {
    code: 'BEAUTY',
    name: '美容美发美甲',
    spaceAlias: '工位',
    appendActionAlias: '加护理/烫染',
    defaultFeeName: '造型毛巾费'
  },
  {
    code: 'RESTAURANT',
    name: '餐饮轻食/正餐',
    spaceAlias: '包厢',
    appendActionAlias: '加菜加酒水',
    defaultFeeName: '茶位费/餐具费'
  },
  {
    code: 'AUTO',
    name: '汽车养护维修',
    spaceAlias: '工位',
    appendActionAlias: '增项/配件',
    defaultFeeName: '工时环保处置费'
  },
  {
    code: 'RETAIL',
    name: '专营零售',
    spaceAlias: '展位',
    appendActionAlias: '加购',
    defaultFeeName: '定制包装费'
  }
])

const policyForm = ref({
  feeEnabled: true,
  feeName: '',
  feeAmount: 10
})

const loadCategories = async () => {
  try {
    const res: any = await getIndustryCategoriesApi()
    const groupList = res?.all || res?.data?.all || []
    cascaderOptions.value = groupList.map((g: any) => ({
      value: g.name,
      label: g.name,
      children: (g.data || []).map((item: any) => ({
        value: item.id,
        label: item.name,
        groupName: g.name
      }))
    }))
    syncSelectedCategory()
  } catch (e) {
    console.error(e)
  }
}

const syncSelectedCategory = () => {
  if (currentProfile.value && currentProfile.value.industryCategoryId) {
    editCategoryId.value = currentProfile.value.industryCategoryId
    editCategoryName.value = currentProfile.value.industryCategoryName
    editCategoryGroup.value = currentProfile.value.industryCategoryGroup
    selectedCategoryCascader.value = [
      currentProfile.value.industryCategoryGroup || '服务类',
      currentProfile.value.industryCategoryId
    ]
  }
}

const handleCategoryCascaderChange = (val: any[]) => {
  if (val && val.length === 2) {
    const grp = val[0]
    const catId = val[1]
    editCategoryGroup.value = grp
    editCategoryId.value = catId
    const grpObj = cascaderOptions.value.find((g: any) => g.value === grp)
    const catObj = grpObj?.children?.find((c: any) => c.value === catId)
    if (catObj) {
      editCategoryName.value = catObj.label
      const name = catObj.label
      // 智能识别业态并推荐默认称谓（用户可随时点选其他或手动输入）
      if (name.includes('餐饮') || name.includes('轻食') || name.includes('料理') || name.includes('火锅') || name.includes('茶饮')) {
        customSpaceAliasInput.value = '包厢'
      } else if (name.includes('汽车') || name.includes('汽修') || name.includes('修理') || name.includes('机修')) {
        customSpaceAliasInput.value = '工位'
      } else if (name.includes('美业') || name.includes('美发') || name.includes('美甲') || name.includes('美容')) {
        customSpaceAliasInput.value = '工位'
      } else if (name.includes('零售') || name.includes('便利') || name.includes('专营') || name.includes('百货')) {
        customSpaceAliasInput.value = '展位'
      }
    }
  }
}

const handleSaveCategory = async () => {
  if (!editCategoryId.value) {
    ElMessage.warning('请先在下拉列表中选择细分行业')
    return
  }
  const alias = customSpaceAliasInput.value.trim() || '包厢'
  savingCategory.value = true
  try {
    await updateStoreCategoryApi({
      categoryId: editCategoryId.value,
      categoryName: editCategoryName.value,
      categoryGroup: editCategoryGroup.value
    })
    storeConfig.setCustomSpaceAlias(alias)
    ElMessage.success(`门店细分行业已更新为：${editCategoryGroup.value} · ${editCategoryName.value}，空间称谓已设定为【${alias}】！`)
    await loadCurrent()
    await storeConfig.fetchIndustry()
  } catch (e: any) {
    ElMessage.error(e.message || '保存细分行业配置失败')
  } finally {
    savingCategory.value = false
  }
}

const loadCurrent = async () => {
  try {
    const data: any = await getCurrentIndustryApi()
    currentProfile.value = data
    policyForm.value = {
      feeEnabled: data.feeEnabled ?? true,
      feeName: data.defaultFeeName || '',
      feeAmount: data.defaultFeeAmount || 10
    }
    const savedCustom = localStorage.getItem('seahorse_custom_space_alias')
    if (savedCustom) {
      customSpaceAliasInput.value = savedCustom
    } else if (data.spaceAlias) {
      customSpaceAliasInput.value = data.spaceAlias
    } else {
      customSpaceAliasInput.value = data.industry === 'RESTAURANT' ? '包厢' : (data.industry === 'AUTO' ? '工位' : '工位')
    }
    syncSelectedCategory()
  } catch (e) {
    console.error(e)
  }
}

const getIndustryEmoji = (code: string) => {
  switch (code) {
    case 'BEAUTY': return '💇‍♀️'
    case 'RESTAURANT': return '🍲'
    case 'AUTO': return '🚗'
    case 'RETAIL': return '🛍️'
    default: return '🏬'
  }
}

const handleSelectIndustry = async (item: any) => {
  if (currentProfile.value?.industry === item.code) return
  saving.value = true
  try {
    await switchIndustryApi({
      industry: item.code,
      feeName: item.defaultFeeName,
      feeAmount: policyForm.value.feeAmount,
      feeEnabled: policyForm.value.feeEnabled
    })
    customSpaceAliasInput.value = item.spaceAlias
    storeConfig.setCustomSpaceAlias(item.spaceAlias)
    ElMessage.success(`行业模式已切换为：${item.name}，空间称谓已自动更新为【${item.spaceAlias}】！`)
    await loadCurrent()
    await storeConfig.fetchIndustry()
  } catch (e) {
    console.error(e)
  } finally {
    saving.value = false
  }
}

const handleSavePolicy = async () => {
  saving.value = true
  try {
    await switchIndustryApi({
      industry: currentProfile.value.industry,
      feeName: policyForm.value.feeName,
      feeAmount: policyForm.value.feeAmount,
      feeEnabled: policyForm.value.feeEnabled
    })
    if (customSpaceAliasInput.value.trim()) {
      storeConfig.setCustomSpaceAlias(customSpaceAliasInput.value.trim())
    }
    ElMessage.success('附加费策略与空间称谓配置保存成功')
    await loadCurrent()
    await storeConfig.fetchIndustry()
  } catch (e) {
    console.error(e)
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  loadCategories()
  loadCurrent()
})
</script>

<style scoped>
.industry-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.header-title {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}

.header-desc {
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
}

.industry-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
  margin: 16px 0;
}

.ind-card {
  background-color: #f8fafc;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  padding: 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.ind-card:hover {
  transform: translateY(-2px);
  border-color: #94a3b8;
}

.ind-card-active {
  border-color: #0284c7;
  background-color: #f0f9ff;
}

.ind-icon {
  font-size: 40px;
  margin-bottom: 8px;
}

.ind-name {
  font-size: 16px;
  font-weight: 700;
  color: #1e293b;
}

.ind-code {
  font-size: 11px;
  color: #94a3b8;
  margin-bottom: 12px;
}

.ind-details {
  text-align: left;
  font-size: 12px;
  color: #475569;
  line-height: 1.8;
  width: 100%;
  background: #fff;
  padding: 10px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
  margin-bottom: 12px;
}

.active-badge {
  color: #0284c7;
  font-size: 13px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 4px;
}

.switch-btn {
  font-size: 12px;
  color: #64748b;
}

.policy-form-box {
  padding: 8px 0;
}

.policy-title {
  font-size: 15px;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 16px;
}

.space-alias-capsules {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-top: 6px;
}

.capsule-label {
  font-size: 12px;
  color: #64748b;
  font-weight: 500;
}

.alias-tip-text {
  font-size: 12px;
  color: #64748b;
  line-height: 1.6;
  margin-top: 8px;
  background-color: #f8fafc;
  padding: 8px 12px;
  border-radius: 6px;
  border: 1px dashed #cbd5e1;
}
</style>
