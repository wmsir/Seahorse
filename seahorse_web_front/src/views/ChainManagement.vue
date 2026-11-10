<template>
  <div class="chain-management-page">
    <el-card shadow="hover">
      <template #header>
        <div class="header-box">
          <div class="header-left">
            <span class="title">🏢 连锁门店与多店协同管理</span>
            <el-tag effect="plain" type="primary">总店直营 · 加盟分店 · 门店基础档案 · 跨店对账结算 · 会员一卡通全网漫游</el-tag>
          </div>
          <div class="header-right">
            <!-- 严格与顶部权限保持一致：仅租户老板/超管可见 -->
            <el-button
              v-if="isMerchantBoss"
              type="primary"
              icon="Plus"
              @click="handleOpenCreateStore"
            >
              开设直营/加盟新分店
            </el-button>
          </div>
        </div>
      </template>

      <!-- 连锁运营核心指标 (全量对接真实关联计算引擎) -->
      <el-row :gutter="16" style="margin-bottom: 20px;">
        <el-col :xs="12" :sm="6" :md="6">
          <div class="stat-card stat-blue">
            <div class="lbl">连锁直营/加盟分店总数</div>
            <div class="val">{{ stores.length }} 家</div>
            <div class="sub">{{ stores.length <= 1 ? '总店正常营业中 (单店直营)' : '全部正常营业中 (多店联动)' }}</div>
          </div>
        </el-col>
        <el-col :xs="12" :sm="6" :md="6">
          <div class="stat-card stat-green">
            <div class="lbl">全网通漫游跨店储值余额</div>
            <div class="val">￥{{ (stores.length > 1 ? systemData.chainStats.roamCardBalance : singleStoreRoamBalance).toLocaleString() }}</div>
            <div class="sub">{{ stores.length > 1 ? '全网会员实时储值资金池' : '本店在册会员储值资金池' }}</div>
          </div>
        </el-col>
        <el-col :xs="12" :sm="6" :md="6">
          <div class="stat-card stat-purple">
            <div class="lbl">本月跨店履约对账结算额</div>
            <div class="val">￥{{ (stores.length > 1 ? systemData.chainStats.crossStoreSettlement : 0).toLocaleString() }}</div>
            <div class="sub">{{ stores.length > 1 ? '异店履约自动清算' : '单店直营模式无跨店清算' }}</div>
          </div>
        </el-col>
        <el-col :xs="12" :sm="6" :md="6">
          <div class="stat-card stat-amber">
            <div class="lbl">连锁在职员工总数</div>
            <div class="val">{{ actualStaffCount }} 人</div>
            <div class="sub">{{ actualStaffSub }}</div>
          </div>
        </el-col>
      </el-row>

      <el-tabs v-model="activeTab">
        <!-- 1. 分店列表名录 -->
        <el-tab-pane label="🏬 连锁分店名录" name="stores">
          <div class="filter-row">
            <el-input
              v-model="storeSearchKeyword"
              placeholder="搜索门店名称/分店编号/店长/地址/行业分类"
              style="width: 320px;"
              clearable
              @clear="currentPage = 1"
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
          </div>

          <el-table :data="paginatedStores" stripe style="width: 100%; margin-top: 16px;">
            <el-table-column prop="storeId" label="分店编号" width="120">
              <template #default="{ row }">
                <span class="store-id">{{ row.storeId }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="storeName" label="门店名称" min-width="170">
              <template #default="{ row }">
                <b>{{ row.storeName }}</b>
                <el-tag v-if="row.isHeadquarter" size="small" type="danger" effect="dark" style="margin-left: 6px;">总店直营</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="industryDesc" label="经营行业分类" width="160">
              <template #default="{ row }">
                <el-tag :type="getIndustryTagType(row)" effect="light">
                  {{ (row.industryCategoryGroup ? row.industryCategoryGroup + ' · ' : '') + (row.industryCategoryName || row.industryDesc || '综合服务') }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="manager" label="店长/负责人" width="120">
              <template #default="{ row }">
                <span>{{ row.manager || '未指定' }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="phone" label="联系电话" width="130" />
            <el-table-column prop="address" label="门店经营地址" min-width="200" show-overflow-tooltip />
            <el-table-column prop="monthlyRevenue" label="本月营收 (元)" width="130">
              <template #default="{ row }">
                <span style="color: #059669; font-weight: 700;">￥{{ getStoreMonthlyRevenue(row.storeId).toFixed(2) }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="运营状态" width="100">
              <template #default="{ row }">
                <el-tag :type="row.status === 'ACTIVE' ? 'success' : 'danger'" size="small">
                  {{ row.status === 'ACTIVE' ? '营业中' : '暂停' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="180" fixed="right">
              <template #default="{ row }">
                <template v-if="isMerchantBoss">
                  <el-button link type="primary" icon="Edit" @click="handleEditStore(row)">编辑分店</el-button>
                  <el-button link :type="row.status === 'ACTIVE' ? 'warning' : 'success'" @click="handleToggleStatus(row)">
                    {{ row.status === 'ACTIVE' ? '暂停营业' : '恢复营业' }}
                  </el-button>
                </template>
                <template v-else>
                  <span style="font-size: 12px; color: #94a3b8;">🔒 仅租户主账号可操作</span>
                </template>
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
              :total="filteredStores.length"
            />
          </div>
        </el-tab-pane>

        <!-- 2. 门店基础档案与运行设置 (从系统通用设置挪至此处) -->
        <el-tab-pane label="⚙️ 门店基础档案与运行设置" name="basic_config">
          <div class="store-config-pane">
            <div class="store-switch-toolbar">
              <div class="s-left">
                <span class="label">当前配置门店：</span>
                <el-select
                  v-model="selectedStoreIdForConfig"
                  style="width: 320px;"
                  @change="handleSelectStoreForConfig"
                >
                  <el-option
                    v-for="st in stores"
                    :key="st.storeId"
                    :label="st.storeName + ' (' + (st.industryCategoryName || st.industryDesc || '门店') + ')'"
                    :value="st.storeId"
                  >
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                      <span>{{ st.storeName }}</span>
                      <el-tag size="small" :type="st.isHeadquarter ? 'danger' : 'info'">
                        {{ st.isHeadquarter ? '总店' : st.storeId }}
                      </el-tag>
                    </div>
                  </el-option>
                </el-select>
              </div>
              <div class="s-right">
                <el-button type="primary" icon="Check" :loading="savingStoreConfig" @click="handleSaveStoreBasicConfig">
                  保存当前门店档案与运行设置
                </el-button>
              </div>
            </div>

            <el-form :model="storeConfigForm" label-width="140px" style="max-width: 720px; margin-top: 24px;">
              <el-form-item label="分店编号">
                <el-tag size="large" type="info" class="code-tag">{{ storeConfigForm.storeId || '-' }}</el-tag>
                <span style="font-size: 12px; color: #94a3b8; margin-left: 10px;">系统自动生成的唯一分店机构标识，不可变更</span>
              </el-form-item>

              <el-form-item label="门店招牌全称" required>
                <el-input v-model="storeConfigForm.storeName" placeholder="如：海马造型·旗舰体验中心 / 栖枫悦食料理" />
              </el-form-item>

              <el-form-item label="主营行业细分分类" required>
                <el-cascader
                  v-model="storeConfigForm.industryCascaderValue"
                  :options="categoryCascaderOptions"
                  :props="{ expandTrigger: 'hover' }"
                  placeholder="必选：请选择主营行业大类与精准分类 (如：服务类 · 美业服务)"
                  style="width: 100%;"
                  @change="handleStoreConfigCascaderChange"
                />
              </el-form-item>

              <el-form-item label="前台预约电话" required>
                <el-input v-model="storeConfigForm.phone" placeholder="门店服务预约或热线电话" />
              </el-form-item>

              <el-form-item label="日常营业时间" required>
                <el-input v-model="storeConfigForm.businessHours" placeholder="如：09:00 - 22:00 或 10:00 - 23:30" />
              </el-form-item>

              <el-form-item label="详细经营地址" required>
                <el-input v-model="storeConfigForm.address" placeholder="详细门牌地址，如：深圳市南山区高新科技园中区1栋101" />
              </el-form-item>

              <el-form-item label="分店店长/负责人">
                <el-input v-model="storeConfigForm.manager" placeholder="分店店长姓名或负责人" />
              </el-form-item>

              <el-form-item label="客显屏迎宾标语">
                <el-input v-model="storeConfigForm.slogan" placeholder="如：海马会员，记住每位好客" />
              </el-form-item>

              <el-form-item label="顾客WiFi名称与密码">
                <div style="display: flex; gap: 10px; width: 100%;">
                  <el-input v-model="storeConfigForm.wifiSsid" placeholder="WiFi网络SSID名称" />
                  <el-input v-model="storeConfigForm.wifiPass" placeholder="WiFi连接密码" />
                </div>
              </el-form-item>

              <el-form-item label="门店运营状态">
                <el-radio-group v-model="storeConfigForm.status">
                  <el-radio-button label="ACTIVE">🟢 正常营业</el-radio-button>
                  <el-radio-button label="PAUSED">🔴 暂停营业 (打烊/装修)</el-radio-button>
                </el-radio-group>
              </el-form-item>
            </el-form>
          </div>
        </el-tab-pane>

        <!-- 3. 跨店结算对账清算 -->
        <el-tab-pane label="💰 跨店消费结算与清算对账" name="settlement">
          <el-alert
            :title="stores.length <= 1 ? '单店直营提示：当前租户处于单店运营模式，会员在本店储值并在本店消费，无需跨店划扣清算。开设新分店后系统将自动激活全网漫游清算体系。' : '连锁跨店会员卡消费对账：当会员在A店开卡充值，前往B店消费时，系统根据双轨结算规则自动将B店服务成本从总店资金池划扣结算。'"
            :type="stores.length <= 1 ? 'success' : 'info'"
            :closable="false"
            style="margin-bottom: 16px;"
          />
          <el-table :data="activeSettlementList" stripe style="width: 100%;" empty-text="当前处于单店直营运营，暂无异店跨店清算记录。开设新分店后系统将自动在此进行跨店资金池清算与对账。">
            <el-table-column prop="settleNo" label="结算批次号" width="150" />
            <el-table-column prop="cardOpenStore" label="开卡充值门店" width="150" />
            <el-table-column prop="consumeStore" label="实际履约门店" width="150" />
            <el-table-column prop="memberPhone" label="消费会员" width="140" />
            <el-table-column prop="consumeItem" label="消费服务项目" min-width="160" />
            <el-table-column prop="settleAmount" label="清算结算金额 (元)" width="140">
              <template #default="{ row }">
                <span style="color: #ea580c; font-weight: 700;">￥{{ Number(row.settleAmount || 0).toFixed(2) }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="settleTime" label="结算时间" width="160" />
            <el-table-column prop="status" label="清算状态" width="110">
              <template #default="{ row }">
                <el-tag :type="row.status === 'SETTLED' ? 'success' : 'warning'" size="small">
                  {{ row.status === 'SETTLED' ? '已对账打款' : '待期末清算' }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 弹窗 1: 开设/入驻连锁新分店 -->
    <el-dialog v-model="openCreateStoreDialog" title="🏪 开设/入驻连锁新分店" width="580px" destroy-on-close>
      <el-form :model="createForm" label-width="140px" style="margin-top: 10px;">
        <el-form-item label="分店招牌全称" required>
          <el-input v-model="createForm.storeName" placeholder="例如：海马科技园旗舰分店 / 云缦甄选美学馆" />
        </el-form-item>

        <el-form-item label="主营行业分类" required>
          <el-cascader
            v-model="createCascaderValue"
            :options="categoryCascaderOptions"
            :props="{ expandTrigger: 'hover' }"
            placeholder="必选：选择主营行业大类与精准分类 (如：服务类 · 美业服务)"
            style="width: 100%;"
            @change="handleCreateCascaderChange"
          />
        </el-form-item>

        <el-form-item label="前台预约电话" required>
          <el-input v-model="createForm.phone" placeholder="分店前台热线电话或手机" />
        </el-form-item>

        <el-form-item label="分店店长/负责人">
          <el-input v-model="createForm.manager" placeholder="分店负责人姓名" />
        </el-form-item>

        <el-form-item label="门店详细地址" required>
          <el-input v-model="createForm.address" placeholder="详细经营门牌地址，如：科技园科苑路15号" />
        </el-form-item>

        <el-form-item label="日常营业时间">
          <el-input v-model="createForm.businessHours" placeholder="如：09:00 - 22:00" />
        </el-form-item>

        <el-form-item label="客显屏迎宾标语">
          <el-input v-model="createForm.slogan" placeholder="如：海马会员，记住每位好客" />
        </el-form-item>

        <el-form-item label="顾客WiFi信息">
          <div style="display: flex; gap: 8px; width: 100%;">
            <el-input v-model="createForm.wifiSsid" placeholder="WiFi名称" />
            <el-input v-model="createForm.wifiPass" placeholder="WiFi密码" />
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openCreateStoreDialog = false">取消</el-button>
        <el-button type="primary" :loading="creatingStore" @click="handleConfirmCreateStore">确定创建入驻</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 2: 编辑分店参数设置 -->
    <el-dialog v-model="openEditStoreDialog" title="✏️ 编辑分店参数与基础档案" width="580px" destroy-on-close>
      <el-form :model="editStoreForm" label-width="140px" style="margin-top: 10px;">
        <el-form-item label="分店编号">
          <el-tag size="large" type="info">{{ editStoreForm.storeId }}</el-tag>
          <span style="font-size: 12px; color: #94a3b8; margin-left: 10px;">机构唯一编码不可更改</span>
        </el-form-item>

        <el-form-item label="门店招牌全称" required>
          <el-input v-model="editStoreForm.storeName" placeholder="分店招牌名称" />
        </el-form-item>

        <el-form-item label="主营行业分类" required>
          <el-cascader
            v-model="editCascaderValue"
            :options="categoryCascaderOptions"
            :props="{ expandTrigger: 'hover' }"
            placeholder="必选：选择主营行业大类与精准分类 (如：服务类 · 美业服务)"
            style="width: 100%;"
            @change="handleEditCascaderChange"
          />
        </el-form-item>

        <el-form-item label="前台预约电话" required>
          <el-input v-model="editStoreForm.phone" placeholder="分店前台预约热线" />
        </el-form-item>

        <el-form-item label="分店店长/负责人">
          <el-input v-model="editStoreForm.manager" placeholder="分店负责人姓名" />
        </el-form-item>

        <el-form-item label="门店详细地址" required>
          <el-input v-model="editStoreForm.address" placeholder="详细经营门牌地址" />
        </el-form-item>

        <el-form-item label="日常营业时间">
          <el-input v-model="editStoreForm.businessHours" placeholder="如：09:00 - 22:00" />
        </el-form-item>

        <el-form-item label="客显屏迎宾标语">
          <el-input v-model="editStoreForm.slogan" placeholder="如：海马会员，记住每位好客" />
        </el-form-item>

        <el-form-item label="顾客WiFi信息">
          <div style="display: flex; gap: 8px; width: 100%;">
            <el-input v-model="editStoreForm.wifiSsid" placeholder="WiFi名称" />
            <el-input v-model="editStoreForm.wifiPass" placeholder="WiFi密码" />
          </div>
        </el-form-item>

        <el-form-item label="门店运营状态">
          <el-radio-group v-model="editStoreForm.status">
            <el-radio-button label="ACTIVE">正常营业</el-radio-button>
            <el-radio-button label="PAUSED">暂停营业</el-radio-button>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openEditStoreDialog = false">取消</el-button>
        <el-button type="primary" :loading="savingEditStore" @click="handleConfirmSaveEditStore">保存修改</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { useStoreConfig } from '../stores/store'
import { useSystemDataStore } from '../stores/systemDataStore'
import {
  createStoreApi,
  updateStoreApi,
  getTenantStoresApi,
  getIndustryCategoriesApi,
  getMerchantStaffListApi
} from '../api'

const storeConfig = useStoreConfig()
const systemData = useSystemDataStore()

// 严格与顶部权限逻辑保持完全一致
const role = ref(localStorage.getItem('seahorse_role') || 'SUPER_ADMIN')
const isMerchantBoss = computed(() => role.value === 'SUPER_ADMIN' || role.value === 'MERCHANT_ADMIN' || role.value === 'STORE_OWNER')

const activeTab = ref('stores')
const storeSearchKeyword = ref('')
const currentPage = ref(1)
const pageSize = ref(10)

// 真实动态自洽的门店列表
const stores = ref<any[]>([])

// 行业分类级联选项
const categoryCascaderOptions = ref<any[]>([])
const defaultCategoryTree = [
  {
    value: '服务类',
    label: '服务类 (到店体验/丽人/出行/健康)',
    children: [
      { value: 1, label: '美业服务 (美容美发美甲SPA)', groupName: '服务类', defaultIndustryType: 'BEAUTY' },
      { value: 2, label: '汽车服务 (维修改装养护洗车)', groupName: '服务类', defaultIndustryType: 'AUTO' },
      { value: 3, label: '餐饮美食 (特色火锅正餐茶饮)', groupName: '服务类', defaultIndustryType: 'RESTAURANT' },
      { value: 4, label: '休闲娱乐 (棋牌茶室影院轰趴)', groupName: '服务类', defaultIndustryType: 'RESTAURANT' },
      { value: 5, label: '运动健身 (健身房私教球馆)', groupName: '服务类', defaultIndustryType: 'BEAUTY' },
      { value: 6, label: '家政洗护 (干洗皮具深度保洁)', groupName: '服务类', defaultIndustryType: 'BEAUTY' }
    ]
  },
  {
    value: '零售类',
    label: '零售类 (商超/生活美学/专营专卖)',
    children: [
      { value: 10, label: '专营零售 (精品百货潮品专卖)', groupName: '零售类', defaultIndustryType: 'RETAIL' },
      { value: 11, label: '生活美学 (轻奢文创家居香氛)', groupName: '零售类', defaultIndustryType: 'RETAIL' },
      { value: 12, label: '商超便利 (便利店生鲜零食)', groupName: '零售类', defaultIndustryType: 'RETAIL' },
      { value: 13, label: '生鲜水果 (精品果蔬冷链冻品)', groupName: '零售类', defaultIndustryType: 'RETAIL' },
      { value: 14, label: '服饰箱包 (潮流服饰皮具配饰)', groupName: '零售类', defaultIndustryType: 'RETAIL' }
    ]
  }
]

const loadCategories = async () => {
  try {
    const res: any = await getIndustryCategoriesApi()
    const groupList = res?.all || res?.data?.all || []
    if (Array.isArray(groupList) && groupList.length > 0) {
      categoryCascaderOptions.value = groupList.map((g: any) => ({
        value: g.name,
        label: g.name,
        children: (g.data || []).map((item: any) => ({
          value: item.id,
          label: item.name,
          groupName: g.name,
          defaultIndustryType: item.defaultIndustryType
        }))
      }))
      return
    }
  } catch (e) {
    console.warn('获取行业分类接口失败，使用高可用默认分类树', e)
  }
  categoryCascaderOptions.value = defaultCategoryTree
}

// 真实租户在册员工列表
const actualStaffList = ref<any[]>([])
const actualStaffCount = computed(() => {
  if (actualStaffList.value.length > 0) {
    return actualStaffList.value.filter(s => s.status === 'ACTIVE' && !s.isDeleted).length
  }
  return 1
})
const actualStaffSub = computed(() => {
  if (actualStaffCount.value <= 1) {
    return '当前在职：老板/负责人'
  }
  return '包含店长/技师/收银等'
})

const singleStoreRoamBalance = computed(() => {
  return systemData.membersWithStats.reduce((sum, m) => sum + m.totalBalance, 0)
})

const settlementList = computed(() => {
  switch (systemData.currentIndustry) {
    case 'RETAIL':
      return [
        { settleNo: 'QS20260906401', cardOpenStore: '云缦甄选·正佳广场店', consumeStore: '云缦甄选·日韩快闪店', memberPhone: '13800449901 (薛梦瑶)', consumeItem: '沙龙小众冷杉雪松无火香薰礼盒', settleAmount: 298, settleTime: '2026-09-06 16:30', status: 'SETTLED' },
        { settleNo: 'QS20260905401', cardOpenStore: '云缦甄选·正佳广场店', consumeStore: '云缦甄选·日韩快闪店', memberPhone: '13911669988 (陆文彬)', consumeItem: '耶加雪菲日晒精品原装咖啡豆 500g', settleAmount: 168, settleTime: '2026-09-05 14:15', status: 'SETTLED' },
        { settleNo: 'QS20260904401', cardOpenStore: '云缦甄选·日韩快闪店', consumeStore: '云缦甄选·正佳广场店', memberPhone: '13766553344 (郑敏)', consumeItem: '北欧极简耐热双层玻璃品茗杯', settleAmount: 128, settleTime: '2026-09-04 11:20', status: 'WAIT_SETTLE' }
      ]
    case 'RESTAURANT':
      return [
        { settleNo: 'QS20260906201', cardOpenStore: '栖枫悦食·天河城旗舰店', consumeStore: '栖枫悦食·珠江新城店', memberPhone: '13900223301 (高逸轩)', consumeItem: '主厨精选M9和牛双人餐', settleAmount: 398, settleTime: '2026-09-06 18:30', status: 'SETTLED' },
        { settleNo: 'QS20260905201', cardOpenStore: '栖枫悦食·天河城旗舰店', consumeStore: '栖枫悦食·珠江新城店', memberPhone: '13811223344 (苏雅菲)', consumeItem: '慢炖法式勃艮第红酒牛肋排', settleAmount: 188, settleTime: '2026-09-05 19:15', status: 'SETTLED' }
      ]
    case 'AUTO':
      return [
        { settleNo: 'QS20260906301', cardOpenStore: '极速动力·科创园区店', consumeStore: '极速动力·高新大道店', memberPhone: '13900334401 (赵天宇)', consumeItem: '美孚1号全合成机油小保养套餐', settleAmount: 380, settleTime: '2026-09-06 15:30', status: 'SETTLED' },
        { settleNo: 'QS20260905301', cardOpenStore: '极速动力·科创园区店', consumeStore: '极速动力·高新大道店', memberPhone: '13822334455 (孙伟东)', consumeItem: '德国3D高清红外四轮定位', settleAmount: 260, settleTime: '2026-09-05 11:20', status: 'WAIT_SETTLE' }
      ]
    default:
      return [
        { settleNo: 'QS20260906001', cardOpenStore: '海马造型·轻奢沙龙总店 (S001)', consumeStore: '海马造型·广州天河二分店 (S002)', memberPhone: '13800138001 (李清雅)', consumeItem: '欧莱雅植物蛋白染发', settleAmount: 298, settleTime: '2026-09-06 14:30', status: 'SETTLED' },
        { settleNo: 'QS20260905001', cardOpenStore: '海马造型·轻奢沙龙总店 (S001)', consumeStore: '海马造型·广州天河二分店 (S002)', memberPhone: '13912345678 (张小曼)', consumeItem: '头皮微生态赋活深度SPA', settleAmount: 198, settleTime: '2026-09-05 16:15', status: 'SETTLED' },
        { settleNo: 'QS20260904001', cardOpenStore: '海马造型·广州天河二分店 (S002)', consumeStore: '海马造型·轻奢沙龙总店 (S001)', memberPhone: '13799887766 (陈伟)', consumeItem: '发型总监精修洗剪吹', settleAmount: 88, settleTime: '2026-09-04 11:20', status: 'WAIT_SETTLE' }
      ]
  }
})

const activeSettlementList = computed(() => {
  if (stores.value.length <= 1) {
    return []
  }
  return settlementList.value
})

const getIndustryDesc = (ind: string) => {
  switch (ind) {
    case 'BEAUTY': return '美业服务'
    case 'AUTO': return '汽车服务'
    case 'RESTAURANT': return '餐饮服务'
    case 'RETAIL': return '专营零售'
    default: return ind || '综合商业'
  }
}

const getIndustryTagType = (row: any) => {
  const desc = row.industryCategoryName || row.industryDesc || ''
  const ind = row.industry || ''
  if (desc.includes('美业') || ind === 'BEAUTY') return 'danger'
  if (desc.includes('餐') || ind === 'RESTAURANT') return 'warning'
  if (desc.includes('车') || ind === 'AUTO') return 'primary'
  if (desc.includes('零售') || ind === 'RETAIL') return 'success'
  return 'info'
}

const loadStoresData = async () => {
  try {
    const list: any = await getTenantStoresApi()
    if (Array.isArray(list) && list.length > 0) {
      stores.value = list.map((s: any, idx: number) => ({
        storeId: s.storeId,
        storeName: s.storeName,
        isHeadquarter: idx === 0 || s.storeName.includes('总店'),
        industry: s.industry || 'BEAUTY',
        industryCategoryId: s.industryCategoryId,
        industryCategoryName: s.industryCategoryName,
        industryCategoryGroup: s.industryCategoryGroup,
        industryDesc: s.industryCategoryName || s.industryDesc || getIndustryDesc(s.industry),
        manager: s.manager || (idx === 0 ? (s.storeName.includes('王老板') ? '王老板' : '张总 (老板)') : '分店店长'),
        phone: s.phone || '13800000000',
        address: s.address || '科技大道88号海马科创大厦',
        businessHours: s.businessHours || '09:00 - 22:00',
        monthlyRevenue: 0,
        status: s.status || 'ACTIVE',
        slogan: s.slogan || '海马会员，记住每位好客',
        wifiSsid: s.wifiSsid || 'Seahorse_VIP_5G',
        wifiPass: s.wifiPass || '88888888'
      }))
    } else {
      const sourceList = (storeConfig.stores && storeConfig.stores.length > 0)
        ? storeConfig.stores
        : ((systemData.stores && systemData.stores.length > 0) ? systemData.stores : [])

      if (sourceList.length > 0) {
        stores.value = sourceList.map((s: any, idx: number) => ({
          storeId: s.storeId,
          storeName: s.storeName,
          isHeadquarter: s.isHeadquarter !== undefined ? s.isHeadquarter : (idx === 0 || s.storeName?.includes('总店')),
          industry: s.industry || 'BEAUTY',
          industryCategoryId: s.industryCategoryId,
          industryCategoryName: s.industryCategoryName,
          industryCategoryGroup: s.industryCategoryGroup,
          industryDesc: s.industryCategoryName || s.industryDesc || getIndustryDesc(s.industry),
          manager: s.manager || s.managerName || (idx === 0 ? '行政总店长' : '分店店长'),
          phone: s.phone || '028-85338899',
          address: s.address || '成都市高新区天府大道北段1199号新世纪环球中心E2座3层',
          businessHours: s.businessHours || s.openTime || '11:00 - 次日02:00',
          monthlyRevenue: 0,
          status: s.status || (s.businessStatus === 'OPEN' ? 'ACTIVE' : 'ACTIVE'),
          slogan: s.slogan || '御境云足，东方大健康养生连锁',
          wifiSsid: s.wifiSsid || 'Seahorse_VIP_5G',
          wifiPass: s.wifiPass || '88888888'
        }))
      } else {
        stores.value = [
          {
            storeId: storeConfig.currentStoreId || 'S001',
            storeName: storeConfig.storeName || '海马美业·旗舰体验中心 (总店)',
            isHeadquarter: true,
            industry: 'BEAUTY',
            industryCategoryId: 1,
            industryCategoryName: '美业服务',
            industryCategoryGroup: '服务类',
            industryDesc: '美业服务',
            manager: '王老板',
            phone: '13800138000',
            address: '深圳市南山区粤海街道科技园中区科苑路15号海马创新大厦',
            businessHours: '09:00 - 22:00',
            monthlyRevenue: 0,
            status: 'ACTIVE',
            slogan: '海马会员，记住每位好客',
            wifiSsid: 'Seahorse_VIP_5G',
            wifiPass: '88888888'
          }
        ]
      }
    }
    systemData.syncStores(stores.value)
    // 同步设置第一家为当前配置门店
    if (!selectedStoreIdForConfig.value && stores.value.length > 0) {
      selectedStoreIdForConfig.value = stores.value[0].storeId
      syncStoreConfigForm(stores.value[0])
    }
  } catch (e) {
    console.error(e)
  }
}

const loadStaffData = async () => {
  try {
    const list: any = await getMerchantStaffListApi()
    if (Array.isArray(list) && list.length > 0) {
      actualStaffList.value = list
      systemData.syncStaff(list)
    } else {
      actualStaffList.value = [
        {
          id: 1,
          storeId: stores.value[0]?.storeId || 'S001',
          realName: '王老板 (总负责人)',
          postName: '租户总负责人/老板',
          role: 'SUPER_ADMIN',
          status: 'ACTIVE'
        }
      ]
      systemData.syncStaff(actualStaffList.value)
    }
  } catch (e) {
    console.error(e)
  }
}

const getStoreMonthlyRevenue = (storeId: string) => {
  const isNew = systemData.isNewTenant ||
    localStorage.getItem('seahorse_is_new_tenant') === 'true' ||
    localStorage.getItem('seahorse_role') === 'TENANT_ADMIN'
  if (isNew) return 0

  const thisMonthStr = new Date().toISOString().slice(0, 7)
  const consumeRev = (systemData.consumeOrders || [])
    .filter(o => (o.storeId === storeId || !o.storeId) && o.status === 'COMPLETED' && (o.createTime?.startsWith(thisMonthStr)))
    .reduce((sum, o) => sum + Number(o.cashierPaidAmount || o.payAmount || 0), 0)
  const rechargeRev = (systemData.rechargeOrders || [])
    .filter(r => (r.storeId === storeId || !r.storeId) && (r.createTime?.startsWith(thisMonthStr)))
    .reduce((sum, r) => sum + Number(r.principalAmount || 0), 0)

  return consumeRev + rechargeRev
}

const filteredStores = computed(() => {
  if (!storeSearchKeyword.value) return stores.value
  const q = storeSearchKeyword.value.toLowerCase()
  return stores.value.filter(s =>
    s.storeName.toLowerCase().includes(q) ||
    s.storeId.toLowerCase().includes(q) ||
    (s.manager && s.manager.includes(q)) ||
    (s.address && s.address.includes(q)) ||
    (s.industryDesc && s.industryDesc.includes(q))
  )
})

const paginatedStores = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredStores.value.slice(start, start + pageSize.value)
})

// ==============================================================================
// 1. 开设新分店逻辑 (主营行业为必选)
// ==============================================================================
const openCreateStoreDialog = ref(false)
const creatingStore = ref(false)
const createCascaderValue = ref<any[]>([])

const createForm = ref({
  storeName: '',
  industry: 'BEAUTY',
  industryCategoryId: null as number | null,
  industryCategoryName: '',
  industryCategoryGroup: '服务类',
  manager: '',
  phone: '',
  address: '',
  businessHours: '09:00 - 22:00',
  slogan: '海马会员，记住每位好客',
  wifiSsid: 'Seahorse_VIP_5G',
  wifiPass: '88888888'
})

const handleCreateCascaderChange = (vals: any[]) => {
  if (vals && vals.length === 2) {
    createForm.value.industryCategoryGroup = vals[0]
    createForm.value.industryCategoryId = vals[1]
    const group = categoryCascaderOptions.value.find(g => g.value === vals[0])
    const child = group?.children?.find((c: any) => c.value === vals[1])
    if (child) {
      createForm.value.industryCategoryName = child.label
      createForm.value.industry = child.defaultIndustryType || (vals[0] === '零售类' ? 'RETAIL' : 'BEAUTY')
    }
  } else {
    createForm.value.industryCategoryId = null
    createForm.value.industryCategoryName = ''
  }
}

const handleOpenCreateStore = () => {
  createForm.value = {
    storeName: '',
    industry: 'BEAUTY',
    industryCategoryId: null,
    industryCategoryName: '',
    industryCategoryGroup: '服务类',
    manager: '',
    phone: '',
    address: '',
    businessHours: '09:00 - 22:00',
    slogan: '海马会员，记住每位好客',
    wifiSsid: 'Seahorse_VIP_5G',
    wifiPass: '88888888'
  }
  createCascaderValue.value = []
  openCreateStoreDialog.value = true
}

const handleConfirmCreateStore = async () => {
  if (!createForm.value.storeName.trim()) {
    ElMessage.warning('请填写分店全称')
    return
  }
  if (!createForm.value.industryCategoryId) {
    ElMessage.warning('请选择分店主营行业分类 (如：服务类 · 美业服务)')
    return
  }
  if (!createForm.value.phone.trim()) {
    ElMessage.warning('请填写前台预约联系电话')
    return
  }
  if (!createForm.value.address.trim()) {
    ElMessage.warning('请填写门店详细经营地址')
    return
  }

  creatingStore.value = true
  try {
    await createStoreApi({
      storeName: createForm.value.storeName.trim(),
      industry: createForm.value.industry,
      industryCategoryId: createForm.value.industryCategoryId,
      industryCategoryName: createForm.value.industryCategoryName,
      industryCategoryGroup: createForm.value.industryCategoryGroup,
      phone: createForm.value.phone.trim(),
      address: createForm.value.address.trim(),
      manager: createForm.value.manager.trim(),
      businessHours: createForm.value.businessHours || '09:00 - 22:00'
    })
    ElMessage.success(`连锁新分店【${createForm.value.storeName}】开设入驻成功！`)
    openCreateStoreDialog.value = false
    await storeConfig.loadStores()
    await loadStoresData()
  } catch (e: any) {
    ElMessage.error(e.message || '开设分店失败')
  } finally {
    creatingStore.value = false
  }
}

// ==============================================================================
// 2. 编辑分店参数设置逻辑 (行级弹窗)
// ==============================================================================
const openEditStoreDialog = ref(false)
const savingEditStore = ref(false)
const editCascaderValue = ref<any[]>([])

const editStoreForm = ref({
  storeId: '',
  storeName: '',
  industry: 'BEAUTY',
  industryCategoryId: null as number | null,
  industryCategoryName: '',
  industryCategoryGroup: '服务类',
  manager: '',
  phone: '',
  address: '',
  businessHours: '09:00 - 22:00',
  status: 'ACTIVE',
  slogan: '海马会员，记住每位好客',
  wifiSsid: '',
  wifiPass: ''
})

const handleEditCascaderChange = (vals: any[]) => {
  if (vals && vals.length === 2) {
    editStoreForm.value.industryCategoryGroup = vals[0]
    editStoreForm.value.industryCategoryId = vals[1]
    const group = categoryCascaderOptions.value.find(g => g.value === vals[0])
    const child = group?.children?.find((c: any) => c.value === vals[1])
    if (child) {
      editStoreForm.value.industryCategoryName = child.label
      editStoreForm.value.industry = child.defaultIndustryType || (vals[0] === '零售类' ? 'RETAIL' : 'BEAUTY')
    }
  }
}

const handleEditStore = (row: any) => {
  if (!isMerchantBoss.value) {
    ElMessage.warning('抱歉，仅租户主账号具备修改编辑分店资料的权限！')
    return
  }
  const grp = row.industryCategoryGroup || (row.industry === 'RETAIL' ? '零售类' : '服务类')
  const catId = row.industryCategoryId || (row.industry === 'AUTO' ? 2 : row.industry === 'RESTAURANT' ? 3 : row.industry === 'RETAIL' ? 10 : 1)

  editStoreForm.value = {
    storeId: row.storeId,
    storeName: row.storeName,
    industry: row.industry || 'BEAUTY',
    industryCategoryId: catId,
    industryCategoryName: row.industryCategoryName || row.industryDesc || '美业服务',
    industryCategoryGroup: grp,
    manager: row.manager || '',
    phone: row.phone || '',
    address: row.address || '',
    businessHours: row.businessHours || '09:00 - 22:00',
    status: row.status || 'ACTIVE',
    slogan: row.slogan || '海马会员，记住每位好客',
    wifiSsid: row.wifiSsid || 'Seahorse_VIP_5G',
    wifiPass: row.wifiPass || '88888888'
  }
  editCascaderValue.value = [grp, catId]
  openEditStoreDialog.value = true
}

const handleConfirmSaveEditStore = async () => {
  if (!editStoreForm.value.storeName?.trim()) {
    ElMessage.warning('请填写分店全称')
    return
  }
  if (!editStoreForm.value.industryCategoryId) {
    ElMessage.warning('请选择所属行业分类')
    return
  }
  if (!editStoreForm.value.phone?.trim()) {
    ElMessage.warning('请填写前台预约联系电话')
    return
  }
  if (!editStoreForm.value.address?.trim()) {
    ElMessage.warning('请填写门店详细经营地址')
    return
  }

  savingEditStore.value = true
  try {
    await updateStoreApi({
      storeId: editStoreForm.value.storeId,
      storeName: editStoreForm.value.storeName.trim(),
      industry: editStoreForm.value.industry,
      industryCategoryId: editStoreForm.value.industryCategoryId,
      industryCategoryName: editStoreForm.value.industryCategoryName,
      industryCategoryGroup: editStoreForm.value.industryCategoryGroup,
      phone: editStoreForm.value.phone.trim(),
      address: editStoreForm.value.address.trim(),
      manager: editStoreForm.value.manager ? editStoreForm.value.manager.trim() : '',
      businessHours: editStoreForm.value.businessHours || '09:00 - 22:00',
      status: editStoreForm.value.status
    })
    ElMessage.success(`分店【${editStoreForm.value.storeName}】参数与档案已成功保存！`)
    openEditStoreDialog.value = false

    // 同步更新本地行
    const item = stores.value.find(s => s.storeId === editStoreForm.value.storeId)
    if (item) {
      Object.assign(item, editStoreForm.value)
      item.industryDesc = editStoreForm.value.industryCategoryName
    }
    // 联动全局更新顶部下拉面板
    await storeConfig.loadStores()
  } catch (e: any) {
    ElMessage.error(e.message || '保存修改失败')
  } finally {
    savingEditStore.value = false
  }
}

const handleToggleStatus = async (row: any) => {
  if (!isMerchantBoss.value) {
    ElMessage.warning('抱歉，仅租户主账号具备变更分店运营状态的权限！')
    return
  }
  const nextStatus = row.status === 'ACTIVE' ? 'PAUSED' : 'ACTIVE'
  try {
    await updateStoreApi({
      storeId: row.storeId,
      status: nextStatus
    })
    row.status = nextStatus
    ElMessage.success(`分店【${row.storeName}】已更新为：${row.status === 'ACTIVE' ? '正常营业' : '暂停营业'}`)
    await storeConfig.loadStores()
  } catch (e: any) {
    ElMessage.error(e.message || '变更运营状态失败')
  }
}

// ==============================================================================
// 3. 门店基础档案与运行设置 Tab (从通用设置挪入)
// ==============================================================================
const selectedStoreIdForConfig = ref('')
const savingStoreConfig = ref(false)
const storeConfigForm = ref({
  storeId: '',
  storeName: '',
  industry: 'BEAUTY',
  industryCategoryId: null as number | null,
  industryCategoryName: '',
  industryCategoryGroup: '服务类',
  industryCascaderValue: [] as any[],
  manager: '',
  phone: '',
  address: '',
  businessHours: '09:00 - 22:00',
  status: 'ACTIVE',
  slogan: '海马会员，记住每位好客',
  wifiSsid: 'Seahorse_VIP_5G',
  wifiPass: '88888888'
})

const syncStoreConfigForm = (st: any) => {
  if (!st) return
  const grp = st.industryCategoryGroup || (st.industry === 'RETAIL' ? '零售类' : '服务类')
  const catId = st.industryCategoryId || (st.industry === 'AUTO' ? 2 : st.industry === 'RESTAURANT' ? 3 : st.industry === 'RETAIL' ? 10 : 1)

  storeConfigForm.value = {
    storeId: st.storeId,
    storeName: st.storeName,
    industry: st.industry || 'BEAUTY',
    industryCategoryId: catId,
    industryCategoryName: st.industryCategoryName || st.industryDesc || '美业服务',
    industryCategoryGroup: grp,
    industryCascaderValue: [grp, catId],
    manager: st.manager || '',
    phone: st.phone || '',
    address: st.address || '',
    businessHours: st.businessHours || '09:00 - 22:00',
    status: st.status || 'ACTIVE',
    slogan: st.slogan || '海马会员，记住每位好客',
    wifiSsid: st.wifiSsid || 'Seahorse_VIP_5G',
    wifiPass: st.wifiPass || '88888888'
  }
}

const handleSelectStoreForConfig = (sId: string) => {
  const target = stores.value.find(s => s.storeId === sId)
  if (target) {
    syncStoreConfigForm(target)
  }
}

const handleStoreConfigCascaderChange = (vals: any[]) => {
  if (vals && vals.length === 2) {
    storeConfigForm.value.industryCategoryGroup = vals[0]
    storeConfigForm.value.industryCategoryId = vals[1]
    const group = categoryCascaderOptions.value.find(g => g.value === vals[0])
    const child = group?.children?.find((c: any) => c.value === vals[1])
    if (child) {
      storeConfigForm.value.industryCategoryName = child.label
      storeConfigForm.value.industry = child.defaultIndustryType || (vals[0] === '零售类' ? 'RETAIL' : 'BEAUTY')
    }
  }
}

const handleSaveStoreBasicConfig = async () => {
  if (!storeConfigForm.value.storeName?.trim()) {
    ElMessage.warning('请输入门店全称')
    return
  }
  if (!storeConfigForm.value.industryCategoryId) {
    ElMessage.warning('请选择门店所属行业分类')
    return
  }
  if (!storeConfigForm.value.phone?.trim()) {
    ElMessage.warning('请输入前台预约电话')
    return
  }
  if (!storeConfigForm.value.address?.trim()) {
    ElMessage.warning('请输入门店详细经营地址')
    return
  }

  savingStoreConfig.value = true
  try {
    await updateStoreApi({
      storeId: storeConfigForm.value.storeId,
      storeName: storeConfigForm.value.storeName.trim(),
      industry: storeConfigForm.value.industry,
      industryCategoryId: storeConfigForm.value.industryCategoryId,
      industryCategoryName: storeConfigForm.value.industryCategoryName,
      industryCategoryGroup: storeConfigForm.value.industryCategoryGroup,
      phone: storeConfigForm.value.phone.trim(),
      address: storeConfigForm.value.address.trim(),
      manager: storeConfigForm.value.manager ? storeConfigForm.value.manager.trim() : '',
      businessHours: storeConfigForm.value.businessHours || '09:00 - 22:00',
      status: storeConfigForm.value.status
    })
    ElMessage.success(`门店【${storeConfigForm.value.storeName}】基础档案与运行参数已成功保存！`)

    // 同步到 stores 列表中
    const target = stores.value.find(s => s.storeId === storeConfigForm.value.storeId)
    if (target) {
      Object.assign(target, storeConfigForm.value)
      target.industryDesc = storeConfigForm.value.industryCategoryName
    }
    await storeConfig.loadStores()
  } catch (e: any) {
    ElMessage.error(e.message || '保存设置失败')
  } finally {
    savingStoreConfig.value = false
  }
}

onMounted(async () => {
  await loadCategories()
  await loadStoresData()
  await loadStaffData()
})
</script>

<style scoped>
.chain-management-page {
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

.stat-card {
  padding: 16px;
  border-radius: 8px;
  color: #fff;
}

.stat-blue { background: linear-gradient(135deg, #0284c7, #0369a1); }
.stat-green { background: linear-gradient(135deg, #059669, #047857); }
.stat-purple { background: linear-gradient(135deg, #7c3aed, #6d28d9); }
.stat-amber { background: linear-gradient(135deg, #d97706, #b45309); }

.stat-card .lbl { font-size: 13px; opacity: 0.9; }
.stat-card .val { font-size: 24px; font-weight: 700; margin: 4px 0; }
.stat-card .sub { font-size: 11px; opacity: 0.8; }

.filter-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.store-id {
  font-family: monospace;
  font-weight: 600;
  color: #0284c7;
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

/* 门店基础设置面板 */
.store-config-pane {
  background: #ffffff;
  padding: 10px 4px;
}

.store-switch-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #f8fafc;
  padding: 12px 18px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.store-switch-toolbar .label {
  font-size: 13.5px;
  font-weight: 700;
  color: #1e293b;
  margin-right: 8px;
}

.code-tag {
  font-family: monospace;
  font-weight: 700;
  letter-spacing: 0.5px;
}

:deep(.el-form-item__label) {
  white-space: nowrap !important;
  font-weight: 500;
}
</style>
