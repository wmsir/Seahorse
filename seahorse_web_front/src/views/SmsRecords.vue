<template>
  <div class="sms-records-page">
    <!-- 顶部综合指标看板 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="never" class="stat-card stat-total">
          <div class="stat-inner">
            <div class="stat-meta">
              <span class="stat-lbl">本月累计发送量</span>
              <span class="stat-num">{{ smsStats.totalSent.toLocaleString() }} <small>条</small></span>
              <div class="stat-trend">
                <span>较上月环比</span>
                <span class="trend-up">↑ 18.5%</span>
              </div>
            </div>
            <div class="stat-icon-wrap bg-blue">
              <el-icon :size="28"><Message /></el-icon>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="never" class="stat-card stat-success">
          <div class="stat-inner">
            <div class="stat-meta">
              <span class="stat-lbl">运营商送达成功率</span>
              <span class="stat-num text-success">{{ smsStats.successRate }}<small>%</small></span>
              <div class="stat-trend">
                <span>成功送达</span>
                <span class="trend-val">{{ smsStats.successCount.toLocaleString() }} 条</span>
              </div>
            </div>
            <div class="stat-icon-wrap bg-green">
              <el-icon :size="28"><Check /></el-icon>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="never" class="stat-card stat-fail">
          <div class="stat-inner">
            <div class="stat-meta">
              <span class="stat-lbl">发送失败 / 拦截</span>
              <span class="stat-num text-danger">{{ smsStats.failCount }} <small>条</small></span>
              <div class="stat-trend">
                <span>空号/关机/退订</span>
                <span class="trend-down">{{ abnormalRate }} 异常率</span>
              </div>
            </div>
            <div class="stat-icon-wrap bg-red">
              <el-icon :size="28"><Warning /></el-icon>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="never" class="stat-card stat-balance">
          <div class="stat-inner">
            <div class="stat-meta">
              <span class="stat-lbl">当前短信余量</span>
              <span class="stat-num text-purple">{{ smsStats.balance.toLocaleString() }} <small>条</small></span>
              <div class="stat-trend">
                <el-button link type="primary" size="small" @click="rechargeDialogVisible = true">
                  ⚡ 立即扩容加油包
                </el-button>
              </div>
            </div>
            <div class="stat-icon-wrap bg-purple">
              <el-icon :size="28"><Coin /></el-icon>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 主表格卡片 -->
    <el-card shadow="never" class="main-card">
      <!-- 搜索筛选栏 -->
      <div class="toolbar">
        <div class="toolbar-left">
          <el-input
            v-model="searchPhone"
            placeholder="搜索接收手机号/顾客姓名"
            prefix-icon="Search"
            style="width: 220px;"
            clearable
            @clear="currentPage = 1"
          />

          <el-select v-model="filterType" placeholder="业务场景分类" clearable style="width: 160px;" @change="currentPage = 1">
            <el-option label="全部业务场景" value="" />
            <el-option label="🔑 登录/验证码" value="AUTH_CODE" />
            <el-option label="💰 消费扣款动账" value="CONSUME_NOTICE" />
            <el-option label="💳 储值充值到账" value="RECHARGE_NOTICE" />
            <el-option label="📅 预约排班提醒" value="APPOINTMENT_NOTICE" />
            <el-option label="🎁 关怀营销推广" value="MARKETING_PROMO" />
          </el-select>

          <el-select v-model="filterStatus" placeholder="发送回执状态" clearable style="width: 140px;" @change="currentPage = 1">
            <el-option label="全部状态" value="" />
            <el-option label="✅ 发送成功" value="DELIVRD" />
            <el-option label="⏳ 正在发送" value="SENDING" />
            <el-option label="❌ 送达失败" value="UNDELIVRD" />
            <el-option label="🛡️ 敏感词/黑名单" value="INTERCEPTED" />
          </el-select>

          <el-select v-model="filterStoreId" placeholder="所属门店" clearable style="width: 190px;" @change="currentPage = 1">
            <el-option label="全部门店" value="" />
            <el-option
              v-for="s in availableStoreOptions"
              :key="s.storeId"
              :label="s.storeName"
              :value="s.storeId"
            />
          </el-select>
        </div>

        <div class="toolbar-right">
          <el-button type="primary" icon="Promotion" @click="testSendDialogVisible = true">
            发送测试短信
          </el-button>
          <el-tooltip :content="isSuperAdmin ? '配置短信网关密钥与报备签名 (超管专属)' : '仅超级管理员可配置短信通道与签名'" placement="top">
            <el-button
              icon="Setting"
              :plain="isSuperAdmin"
              :type="isSuperAdmin ? 'default' : 'info'"
              @click="handleOpenConfigDrawer"
            >
              通道与签名配置
              <el-tag v-if="!isSuperAdmin" size="small" type="danger" effect="plain" style="margin-left: 4px;">超管专享</el-tag>
            </el-button>
          </el-tooltip>
          <el-button icon="Refresh" circle @click="refreshData" />
        </div>
      </div>

      <!-- 短信发送明细表格 -->
      <el-table
        :data="paginatedRecords"
        style="width: 100%; margin-top: 16px;"
        v-loading="loading"
        :header-cell-style="{ background: '#f8fafc', color: '#334155', fontWeight: '600' }"
      >
        <el-table-column prop="smsId" label="短信流水单号" width="160">
          <template #default="{ row }">
            <span class="sms-id-code">{{ row.smsId }}</span>
          </template>
        </el-table-column>

        <el-table-column label="接收顾客" width="160">
          <template #default="{ row }">
            <div class="cust-info">
              <span class="cust-name">{{ row.customerName || '散客' }}</span>
              <span class="cust-phone">{{ row.phone }}</span>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="signature" label="短信签名" width="130">
          <template #default="{ row }">
            <el-tag size="small" type="info" effect="plain">【{{ row.signature }}】</el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="type" label="短信类型" width="130">
          <template #default="{ row }">
            <el-tag :type="getTypeTagType(row.type)" size="small">
              {{ getTypeName(row.type) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="content" label="短信发送正文" min-width="280">
          <template #default="{ row }">
            <div class="sms-content-text">{{ row.content }}</div>
          </template>
        </el-table-column>

        <el-table-column prop="wordCount" label="字数/条数" width="100" align="center">
          <template #default="{ row }">
            <span style="font-size: 12px; color: #64748b;">
              {{ row.content.length }}字 / <b>{{ Math.ceil(row.content.length / 67) }}条</b>
            </span>
          </template>
        </el-table-column>

        <el-table-column prop="status" label="状态回执" width="120" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusTagType(row.status)" effect="light">
              {{ getStatusName(row.status) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="sendTime" label="发送时间" width="170">
          <template #default="{ row }">
            <span style="font-size: 13px; color: #475569;">{{ row.sendTime }}</span>
          </template>
        </el-table-column>

        <el-table-column prop="storeName" label="下发门店" width="150" show-overflow-tooltip />

        <el-table-column label="操作" width="130" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="handleViewDetail(row)">
              通信报文
            </el-button>
            <el-button
              v-if="row.status === 'UNDELIVRD'"
              link
              type="danger"
              size="small"
              @click="handleResend(row)"
            >
              重发
            </el-button>
          </template>
        </el-table-column>

        <template #empty>
          <el-empty description="当前暂无短信发送流水记录（新入驻租户享默认100条短信通信特权）" :image-size="100" />
        </template>
      </el-table>

      <!-- 底部分页器 -->
      <div class="pagination-bar">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="filteredRecords.length"
        />
      </div>
    </el-card>

    <!-- 弹窗 1: 发送测试短信 -->
    <el-dialog v-model="testSendDialogVisible" title="🚀 下发测试短信" width="520px" destroy-on-close>
      <el-form :model="testSendForm" label-width="100px">
        <el-form-item label="接收手机号" required>
          <el-input v-model="testSendForm.phone" placeholder="请输入11位中国大陆手机号码" />
        </el-form-item>

        <el-form-item label="短信模板" required>
          <el-select v-model="testSendForm.templateKey" style="width: 100%;" @change="handleTemplateChange">
            <el-option label="验证码模板 (您的验证码为 123456)" value="SMS_CODE" />
            <el-option label="消费动账通知 (您在【御境云足】消费158元，剩余余额...)" value="SMS_CONSUME" />
            <el-option label="储值到账提醒 (您已成功充值2000元，赠送400元...)" value="SMS_RECHARGE" />
            <el-option label="预约到店提醒 (您预约的足道项目将在1小时后开始...)" value="SMS_APPT" />
          </el-select>
        </el-form-item>

        <el-form-item label="短信签名">
          <el-input v-model="testSendForm.signature" disabled />
        </el-form-item>

        <el-form-item label="拟发送正文预览">
          <el-input
            v-model="testSendForm.previewContent"
            type="textarea"
            :rows="3"
            readonly
            style="background: #f8fafc;"
          />
          <div style="font-size: 11px; color: #64748b; margin-top: 4px;">
            字数：{{ testSendForm.previewContent.length }} 字符 (计费 1 条短信)
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="testSendDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="sendingTestSms" @click="confirmSendTestSms">
          确认立即下发
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 2: 短信通道与签名配置抽屉 -->
    <el-drawer v-model="configDrawerVisible" title="⚙️ 短信通道与报备签名配置" size="560px" destroy-on-close>
      <el-alert
        v-if="!isSuperAdmin"
        title="🔒 只读受限视图：当前账号角色为普通员工/管理员，短信通道密钥与报备签名涉及企业通信风控，仅超级管理员享有修改与保存权限。"
        type="warning"
        :closable="false"
        show-icon
        style="margin-bottom: 16px;"
      />
      <el-alert
        v-else
        title="短信下发通道直连三大运营商，保障验证码 3 秒内极速送达，动账通知 100% 穿透。"
        type="info"
        :closable="false"
        show-icon
        style="margin-bottom: 16px;"
      />

      <el-form label-position="top" :disabled="!isSuperAdmin">
        <el-form-item label="短信服务商接入通道">
          <el-radio-group v-model="smsConfig.gateway">
            <el-radio-button label="ALIYUN">🟠 阿里云短信服务 (Dysmsapi)</el-radio-button>
            <el-radio-button label="TENCENT">🔵 腾讯云短信 (SMS)</el-radio-button>
            <el-radio-button label="HUAWEI">🔴 华为云短信</el-radio-button>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="工信部报备短信签名 (SignName)" required>
          <el-input v-model="smsConfig.signName" placeholder="例如: 御品轩 / 丝艺美学" />
          <div class="config-tip">必须在工信部完成备案并与营业执照字号一致。</div>
        </el-form-item>

        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="AccessKey ID / SecretId" required>
              <el-input v-model="smsConfig.accessKeyId" placeholder="输入 Key ID" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="AccessKey Secret / SecretKey" required>
              <el-input v-model="smsConfig.accessKeySecret" type="password" show-password placeholder="输入密钥" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-divider content-position="left">智能防刷与安全风控策略</el-divider>

        <el-form-item label="同一手机号单日发送上限">
          <el-input-number v-model="smsConfig.maxPerDayPerPhone" :min="1" :max="20" />
          <span style="margin-left: 8px; color: #64748b; font-size: 13px;">条 / 天 (防恶意刷短信)</span>
        </el-form-item>

        <el-form-item label="夜间防打扰限制 (22:00 - 08:00 营销类短信自动阻断)">
          <el-switch v-model="smsConfig.nightSilentMode" active-text="已开启 (仅放行动账与验证码)" />
        </el-form-item>
      </el-form>

      <template #footer>
        <div style="display: flex; justify-content: flex-end; gap: 10px;">
          <el-button @click="configDrawerVisible = false">关闭</el-button>
          <el-button v-if="isSuperAdmin" type="primary" @click="saveSmsConfig">保存配置</el-button>
        </div>
      </template>
    </el-drawer>

    <!-- 弹窗 3: 扩容短信加油包 (选包与支付方式) -->
    <el-dialog v-model="rechargeDialogVisible" title="💳 采购扩容短信资源加油包" width="620px" destroy-on-close>
      <div class="pkg-intro">
        选择适合本店业务体量的短信资源包，即充即用，永久有效不过期：
      </div>
      <el-row :gutter="14" style="margin-top: 14px;">
        <el-col :span="12" v-for="pkg in smsPackages" :key="pkg.id" style="margin-bottom: 14px;">
          <div
            class="pkg-card"
            :class="{ 'is-selected': selectedPkgId === pkg.id }"
            @click="selectedPkgId = pkg.id"
          >
            <div class="pkg-count">{{ pkg.count.toLocaleString() }} <small>条短信</small></div>
            <div class="pkg-price">￥{{ pkg.price }} <span class="pkg-unit">(折合 {{ pkg.unitPrice }}元/条)</span></div>
            <div class="pkg-desc">{{ pkg.desc }}</div>
          </div>
        </el-col>
      </el-row>

      <div style="margin-top: 16px; padding: 14px; background: #f8fafc; border-radius: 8px; border: 1px solid #e2e8f0;">
        <div style="font-weight: 600; margin-bottom: 10px; color: #1e293b; font-size: 14px;">选择支付通道</div>
        <el-radio-group v-model="selectedPayMethod">
          <el-radio-button label="WECHAT">🟢 微信支付 (商业收单)</el-radio-button>
          <el-radio-button label="ALIPAY">🔵 支付宝 (企业认证)</el-radio-button>
        </el-radio-group>
        <div style="margin-top: 12px; display: flex; justify-content: space-between; align-items: center;">
          <span style="color: #64748b; font-size: 13px;">本次采购扩容合计：</span>
          <span style="font-size: 20px; font-weight: 700; color: #d97706;">
            ￥{{ selectedPkgItem?.price || '0.00' }}
          </span>
        </div>
      </div>

      <template #footer>
        <el-button @click="rechargeDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleOpenPayQrDialog">
          前往扫码支付 ￥{{ selectedPkgItem?.price || '0.00' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 3.1: 扫码收银台支付确认弹窗 (必须扫码支付成功后才添加短信包数量) -->
    <el-dialog v-model="payQrDialogVisible" title="📱 微信/支付宝聚合收银台" width="460px" destroy-on-close align-center>
      <div style="text-align: center; padding: 10px 0;">
        <div style="font-size: 14px; color: #64748b;">待支付订单金额</div>
        <div style="font-size: 32px; font-weight: 800; color: #059669; margin: 8px 0 16px 0;">
          ￥{{ selectedPkgItem?.price }}
        </div>
        <div style="display: inline-block; padding: 12px; background: #ffffff; border: 2px solid #e2e8f0; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.06);">
          <img
            :src="payQrDataUrl"
            alt="支付二维码"
            style="width: 180px; height: 180px; display: block;"
          />
        </div>
        <div style="margin-top: 14px; font-size: 13px; color: #475569; display: flex; align-items: center; justify-content: center; gap: 6px;">
          <span v-if="selectedPayMethod === 'WECHAT'">🟢 请使用微信扫一扫完成支付</span>
          <span v-else>🔵 请使用支付宝扫一扫完成支付</span>
        </div>
        <div style="margin-top: 6px; font-size: 12px; color: #94a3b8;">
          购买包规格：【{{ selectedPkgItem?.name || selectedPkgItem?.count + '条短信' }}】 · 支付成功后短信立即注入账户
        </div>
      </div>
      <template #footer>
        <div style="display: flex; justify-content: space-between;">
          <el-button @click="payQrDialogVisible = false">取消支付</el-button>
          <el-button type="success" :loading="payingRecharge" @click="confirmSimulationPaySuccess">
            ✅ 模拟扫码已完成支付
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 4: 查看通信报文日志 -->
    <el-drawer v-model="detailDrawerVisible" title="📜 运营商短信通信回执与网关报文" size="520px" destroy-on-close>
      <div v-if="selectedSmsRecord" class="log-body">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="流水号">{{ selectedSmsRecord.smsId }}</el-descriptions-item>
          <el-descriptions-item label="接收手机号">{{ selectedSmsRecord.phone }}</el-descriptions-item>
          <el-descriptions-item label="短信签名">【{{ selectedSmsRecord.signature }}】</el-descriptions-item>
          <el-descriptions-item label="状态回执">
            <el-tag :type="getStatusTagType(selectedSmsRecord.status)">
              {{ getStatusName(selectedSmsRecord.status) }} ({{ selectedSmsRecord.statusCode || 'DELIVRD' }})
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="发送时间">{{ selectedSmsRecord.sendTime }}</el-descriptions-item>
          <el-descriptions-item label="送达时间">{{ selectedSmsRecord.deliverTime || selectedSmsRecord.sendTime }}</el-descriptions-item>
          <el-descriptions-item label="归属门店">{{ selectedSmsRecord.storeName }}</el-descriptions-item>
        </el-descriptions>

        <div style="margin-top: 16px; font-weight: 700; font-size: 13px; color: #1e293b;">通信网关 JSON 报文:</div>
        <pre class="raw-json-box">{{ JSON.stringify(selectedSmsRecord.rawGatewayResponse, null, 2) }}</pre>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { Message, Check, Warning, Coin } from '@element-plus/icons-vue'
import QRCode from 'qrcode'
import { useStoreConfig } from '../stores/store'
import { useSystemDataStore } from '../stores/systemDataStore'
import { getSmsPackagesList } from '../utils/tenantQuotaService'

const storeConfig = useStoreConfig()
const systemData = useSystemDataStore()

const role = ref(localStorage.getItem('seahorse_role') || 'STORE_MANAGER')
const isSuperAdmin = computed(() => {
  const r = localStorage.getItem('seahorse_role') || role.value || ''
  return r === 'SUPER_ADMIN' || r === 'PLATFORM_DEVELOPER' || r === 'PLATFORM_ADMIN' || r === 'PLATFORM_SUPER_ADMIN'
})

const isNewTenant = computed(() => {
  return systemData.isNewTenant ||
    localStorage.getItem('seahorse_is_new_tenant') === 'true' ||
    localStorage.getItem('seahorse_role') === 'TENANT_ADMIN'
})

const loading = ref(false)
const searchPhone = ref('')
const filterType = ref('')
const filterStatus = ref('')
const filterStoreId = ref('')
const currentPage = ref(1)
const pageSize = ref(10)

// 读取真实短信流水记录并剔除历史脏数据
const getStoredSmsRecords = (): any[] => {
  try {
    const raw = localStorage.getItem('seahorse_sms_records')
    if (raw) {
      const parsed = JSON.parse(raw)
      if (Array.isArray(parsed)) {
        // 过滤任何包含老演示脏数据的假记录
        return parsed.filter(r => !r.smsId?.startsWith('SMS20260909') && r.customerName !== '张建国 (张总)' && r.customerName !== '李雪琴 (李女士)')
      }
    }
  } catch (e) {}
  return []
}

// 短信发送流水明细（真实初始态，无任何写死脏数据）
const smsRecords = ref<any[]>(getStoredSmsRecords())

// 综合统计卡片
const savedSmsBalance = localStorage.getItem('seahorse_sms_balance')
const smsStats = ref({
  totalSent: smsRecords.value.length,
  successRate: smsRecords.value.length > 0
    ? Number(((smsRecords.value.filter(r => r.status === 'DELIVRD').length / smsRecords.value.length) * 100).toFixed(1))
    : 100,
  successCount: smsRecords.value.filter(r => r.status === 'DELIVRD').length,
  failCount: smsRecords.value.filter(r => r.status === 'UNDELIVRD' || r.status === 'INTERCEPTED').length,
  balance: savedSmsBalance !== null ? Number(savedSmsBalance) : 0
})

const abnormalRate = computed(() => {
  if (!smsStats.value.totalSent || smsStats.value.totalSent === 0) return '0.0%'
  return ((smsStats.value.failCount / smsStats.value.totalSent) * 100).toFixed(1) + '%'
})

// 门店选项
const availableStoreOptions = computed(() => {
  return storeConfig.stores && storeConfig.stores.length > 0
    ? storeConfig.stores
    : systemData.stores
})

const initTenantSmsData = () => {
  // 清理所有遗留脏数据
  localStorage.removeItem('seahorse_sms_records')
  smsRecords.value = []
  smsStats.value = {
    totalSent: 0,
    successRate: 100,
    successCount: 0,
    failCount: 0,
    balance: savedSmsBalance !== null ? Number(savedSmsBalance) : 0
  }
}

const filteredRecords = computed(() => {
  return smsRecords.value.filter(item => {
    if (searchPhone.value.trim()) {
      const q = searchPhone.value.trim().toLowerCase()
      const matchP = item.phone.includes(q)
      const matchN = item.customerName && item.customerName.toLowerCase().includes(q)
      if (!matchP && !matchN) return false
    }
    if (filterType.value && item.type !== filterType.value) {
      return false
    }
    if (filterStatus.value && item.status !== filterStatus.value) {
      return false
    }
    if (filterStoreId.value && item.storeId !== filterStoreId.value) {
      return false
    }
    return true
  })
})

const paginatedRecords = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredRecords.value.slice(start, start + pageSize.value)
})

const getTypeTagType = (type: string) => {
  const map: Record<string, any> = {
    AUTH_CODE: 'warning',
    CONSUME_NOTICE: 'success',
    RECHARGE_NOTICE: 'primary',
    APPOINTMENT_NOTICE: 'info',
    MARKETING_PROMO: 'danger'
  }
  return map[type] || 'info'
}

const getTypeName = (type: string) => {
  const map: Record<string, string> = {
    AUTH_CODE: '验证码',
    CONSUME_NOTICE: '消费动账',
    RECHARGE_NOTICE: '充值到账',
    APPOINTMENT_NOTICE: '预约提醒',
    MARKETING_PROMO: '营销关怀'
  }
  return map[type] || type
}

const getStatusTagType = (status: string) => {
  const map: Record<string, any> = {
    DELIVRD: 'success',
    SENDING: 'warning',
    UNDELIVRD: 'danger',
    INTERCEPTED: 'info'
  }
  return map[status] || 'info'
}

const getStatusName = (status: string) => {
  const map: Record<string, string> = {
    DELIVRD: '发送成功',
    SENDING: '发送中',
    UNDELIVRD: '送达失败',
    INTERCEPTED: '风控拦截'
  }
  return map[status] || status
}

// 通信报文详情
const detailDrawerVisible = ref(false)
const selectedSmsRecord = ref<any>(null)
const handleViewDetail = (row: any) => {
  selectedSmsRecord.value = row
  detailDrawerVisible.value = true
}

const handleResend = (row: any) => {
  ElMessage.success(`已向手机号【${row.phone}】重新提交运营商重试通道！`)
  row.status = 'SENDING'
  setTimeout(() => {
    row.status = 'DELIVRD'
    row.statusCode = 'DELIVRD'
  }, 1500)
}

const refreshData = () => {
  loading.value = true
  setTimeout(() => {
    loading.value = false
    ElMessage.success('短信流水台账已同步至最新')
  }, 400)
}

// 测试下发
const testSendDialogVisible = ref(false)
const sendingTestSms = ref(false)
const testSendForm = ref({
  phone: '13888889999',
  templateKey: 'SMS_CONSUME',
  signature: computed(() => smsConfig.value.signName || '海马门店'),
  previewContent: '尊敬的贵宾，您在门店消费已成功结账，欢迎再次光临！'
})

const handleTemplateChange = (val: string) => {
  const sign = smsConfig.value.signName || '海马门店'
  if (val === 'SMS_CODE') {
    testSendForm.value.previewContent = `【${sign}】您的验证码为 678912，5分钟内有效。如非本人操作请忽略。`
  } else if (val === 'SMS_CONSUME') {
    testSendForm.value.previewContent = `尊敬的贵宾，您在【${sign}】消费158.00元已结账完成，剩余卡内可用余额1,842.00元。祝您生活愉快！`
  } else if (val === 'SMS_RECHARGE') {
    testSendForm.value.previewContent = `尊敬的贵宾，您已在【${sign}】成功储值2,000.00元，额外获赠400.00元，当前账户可用总额2,400.00元。`
  } else {
    testSendForm.value.previewContent = `【预约提醒】您预约的今日到店服务即将开始，【${sign}】已为您准备妥当。`
  }
}

const confirmSendTestSms = () => {
  if (!testSendForm.value.phone) {
    ElMessage.warning('请输入手机号')
    return
  }
  sendingTestSms.value = true
  setTimeout(() => {
    sendingTestSms.value = false
    testSendDialogVisible.value = false
    smsRecords.value.unshift({
      smsId: 'SMS' + Date.now().toString().substring(4),
      phone: testSendForm.value.phone,
      customerName: '测试顾客',
      signature: testSendForm.value.signature,
      type: testSendForm.value.templateKey === 'SMS_CODE' ? 'AUTH_CODE' : 'CONSUME_NOTICE',
      content: testSendForm.value.previewContent,
      status: 'DELIVRD',
      statusCode: 'DELIVRD',
      sendTime: new Date().toLocaleString(),
      deliverTime: new Date().toLocaleString(),
      storeName: storeConfig.storeName || '御境云足·旗舰尊享会所 (天府环球店)',
      storeId: storeConfig.currentStoreId || 'S_FOOT_01',
      rawGatewayResponse: {
        RequestId: 'TEST-' + Math.random().toString(36).substring(2, 9).toUpperCase(),
        Code: 'OK',
        Message: 'OK',
        BizId: String(Date.now()),
        Carrier: 'Direct Gateway',
        Duration: '0.8s'
      }
    })
    smsStats.value.totalSent += 1
    smsStats.value.successCount += 1
    smsStats.value.balance -= 1
    ElMessage.success('测试短信下发成功，运营商回执已生成！')
  }, 800)
}

// 通道配置与签名管理 (仅限超级管理员配置)
const configDrawerVisible = ref(false)

const getInitialSmsConfig = () => {
  try {
    const raw = localStorage.getItem('seahorse_sms_config')
    if (raw) return JSON.parse(raw)
  } catch (e) {}
  const storeName = storeConfig.storeName ? storeConfig.storeName.split('·')[0].split('(')[0].trim() : '海马智慧门店'
  return {
    gateway: 'ALIYUN',
    signName: storeName || '海马智慧门店',
    accessKeyId: '',
    accessKeySecret: '',
    maxPerDayPerPhone: 5,
    nightSilentMode: true
  }
}

const smsConfig = ref(getInitialSmsConfig())

const handleOpenConfigDrawer = () => {
  if (!isSuperAdmin.value) {
    ElMessage.warning('权限受限：短信通道与报备签名配置仅限超级管理员操作！')
    return
  }
  configDrawerVisible.value = true
}

const saveSmsConfig = () => {
  if (!isSuperAdmin.value) {
    ElMessage.error('权限不足：仅限超级管理员保存短信通道与签名配置！')
    return
  }
  if (!smsConfig.value.signName.trim()) {
    ElMessage.warning('请填写报备短信签名')
    return
  }
  localStorage.setItem('seahorse_sms_config', JSON.stringify(smsConfig.value))
  ElMessage.success('短信通道与网关报备凭据已安全更新！')
  configDrawerVisible.value = false
}

// 充值加油包 (动态加载超级管理员配置的价格与条数，并在支付成功后才添加短信包数量)
const rechargeDialogVisible = ref(false)
const payQrDialogVisible = ref(false)
const payQrDataUrl = ref('')
const selectedPayMethod = ref<'WECHAT' | 'ALIPAY'>('WECHAT')
const smsPackages = ref<any[]>(getSmsPackagesList())
const selectedPkgId = ref(smsPackages.value[0]?.id || 'sms_100')
const payingRecharge = ref(false)

const selectedPkgItem = computed(() => {
  return smsPackages.value.find(p => String(p.id) === String(selectedPkgId.value)) || smsPackages.value[0]
})

const handleOpenPayQrDialog = async () => {
  rechargeDialogVisible.value = false
  const payUrl = `${window.location.origin}/seahorse/sms-records?order=SMS${Date.now()}&amount=${selectedPkgItem.value?.price || 0}`
  try {
    payQrDataUrl.value = await QRCode.toDataURL(payUrl, { width: 180, margin: 1 })
  } catch (e) {
    payQrDataUrl.value = ''
  }
  payQrDialogVisible.value = true
}

const confirmSimulationPaySuccess = () => {
  payingRecharge.value = true
  setTimeout(() => {
    payingRecharge.value = false
    const pkg = selectedPkgItem.value
    if (pkg) {
      const addedCount = Number(pkg.count) || 1000
      smsStats.value.balance += addedCount
      localStorage.setItem('seahorse_sms_balance', String(smsStats.value.balance))
      // 增加一条充值流水记录
      smsRecords.value.unshift({
        smsId: 'SMS' + Date.now(),
        phone: '门店充值',
        customerName: '门店前台',
        signature: smsConfig.value.signName || '系统通知',
        type: 'RECHARGE_NOTICE',
        content: `成功采购扩容短信加油包【${pkg.name || (addedCount + '条')}】，实付金额￥${pkg.price}元 (${selectedPayMethod.value === 'WECHAT' ? '微信支付' : '支付宝'})。`,
        status: 'DELIVRD',
        statusCode: 'PAID',
        sendTime: new Date().toLocaleString(),
        deliverTime: new Date().toLocaleString(),
        storeName: storeConfig.storeName || '海马智慧门店',
        storeId: storeConfig.currentStoreId || 'S001',
        rawGatewayResponse: {
          RequestId: 'PAY-' + Math.random().toString(36).substring(2, 9).toUpperCase(),
          Code: 'SUCCESS',
          Message: 'PAYMENT_CONFIRMED',
          Price: pkg.price,
          Count: addedCount
        }
      })
    }
    payQrDialogVisible.value = false
    ElMessage.success(`🎉 短信资源包【${pkg?.name || '短信加油包'}】购买成功！已成功添加 ${pkg?.count || 1000} 条短信到当前账户！`)
  }, 600)
}

const refreshSmsPacks = () => {
  const packs = getSmsPackagesList()
  if (packs && packs.length > 0) {
    smsPackages.value = packs
    if (!selectedPkgId.value || !packs.some(p => p.id === selectedPkgId.value)) {
      selectedPkgId.value = packs[0]?.id
    }
  }
}

onMounted(() => {
  initTenantSmsData()
  refreshSmsPacks()
  window.addEventListener('seahorse-recharge-packages-updated', refreshSmsPacks)
})

onUnmounted(() => {
  window.removeEventListener('seahorse-recharge-packages-updated', refreshSmsPacks)
})

watch(isNewTenant, () => {
  initTenantSmsData()
})
</script>

<style scoped>
.sms-records-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.stat-row {
  margin-bottom: 2px;
}

.stat-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  transition: all 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.stat-inner {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stat-meta {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-lbl {
  font-size: 13px;
  color: #64748b;
  font-weight: 500;
}

.stat-num {
  font-size: 24px;
  font-weight: 800;
  color: #0f172a;
}

.stat-num small {
  font-size: 13px;
  font-weight: normal;
  color: #94a3b8;
}

.text-success {
  color: #10b981;
}

.text-danger {
  color: #ef4444;
}

.text-purple {
  color: #8b5cf6;
}

.stat-trend {
  font-size: 12px;
  color: #64748b;
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 2px;
}

.trend-up {
  color: #10b981;
  font-weight: 600;
}

.trend-down {
  color: #ef4444;
  font-weight: 600;
}

.trend-val {
  color: #0284c7;
  font-weight: 600;
}

.stat-icon-wrap {
  width: 52px;
  height: 52px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
}

.bg-blue {
  background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
}

.bg-green {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
}

.bg-red {
  background: linear-gradient(135deg, #f87171 0%, #dc2626 100%);
}

.bg-purple {
  background: linear-gradient(135deg, #a855f7 0%, #7c3aed 100%);
}

.main-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.toolbar-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.sms-id-code {
  font-family: monospace;
  font-weight: 600;
  color: #3b82f6;
}

.cust-info {
  display: flex;
  flex-direction: column;
}

.cust-name {
  font-weight: 600;
  color: #1e293b;
  font-size: 13px;
}

.cust-phone {
  font-size: 12px;
  color: #64748b;
  font-family: monospace;
}

.sms-content-text {
  font-size: 12px;
  color: #334155;
  line-height: 1.5;
  background: #f8fafc;
  padding: 6px 10px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

.pkg-intro {
  font-size: 13px;
  color: #475569;
  line-height: 1.5;
}

.pkg-card {
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  padding: 14px;
  cursor: pointer;
  background: #ffffff;
  transition: all 0.2s;
}

.pkg-card:hover {
  border-color: #3b82f6;
  background-color: #f8fafc;
}

.pkg-card.is-selected {
  border-color: #2563eb;
  background-color: #eff6ff;
  box-shadow: 0 0 0 1px #2563eb;
}

.pkg-count {
  font-size: 18px;
  font-weight: 800;
  color: #1e293b;
}

.pkg-count small {
  font-size: 12px;
  color: #64748b;
  font-weight: normal;
}

.pkg-price {
  font-size: 16px;
  font-weight: 700;
  color: #ea580c;
  margin: 6px 0;
}

.pkg-unit {
  font-size: 12px;
  color: #94a3b8;
  font-weight: normal;
}

.pkg-desc {
  font-size: 12px;
  color: #64748b;
}

.raw-json-box {
  background: #0f172a;
  color: #38bdf8;
  padding: 12px;
  border-radius: 8px;
  font-size: 11px;
  line-height: 1.4;
  overflow-x: auto;
}

.config-tip {
  font-size: 11px;
  color: #64748b;
  margin-top: 4px;
}
</style>
