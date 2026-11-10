<template>
  <div class="vendor-feedback-container">
    <!-- 顶部标题 -->
    <div class="page-hero-header">
      <div class="hero-left">
        <div class="hero-icon-box">
          <el-icon :size="26"><Promotion /></el-icon>
        </div>
        <div class="hero-text-box">
          <div class="hero-title-row">
            <h2 class="hero-title">平台建言与需求受理中心 (一线直达研发)</h2>
            <el-tag type="warning" effect="dark" size="small" class="hero-tag">需求漏斗与产品敏捷迭代</el-tag>
          </div>
          <p class="hero-subtitle">
            租户老板、店长、前台收银、技师等所有非研发业务一线人员提交的功能诉求、操作体验优化及Bug反馈汇聚于此，研发团队直接评审答复并联动Sprint敏捷排期。
          </p>
        </div>
      </div>
      <div class="hero-right-actions">
        <el-tag type="success" size="large" effect="light">
          📬 共受理 {{ systemData.platformFeedbacks.length }} 条业务一线建言
        </el-tag>
      </div>
    </div>

    <!-- 漏斗指标卡片 -->
    <el-row :gutter="14" class="stat-cards-row">
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card" @click="filterStatus = 'PENDING'">
          <div class="stat-title">⏳ 待技术架构评审</div>
          <div class="stat-num text-amber">{{ pendingCount }} <span class="sub">条待办</span></div>
          <div class="stat-tip">新提交诉求，需48h内完成初评</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card" @click="filterStatus = 'PROCESSING'">
          <div class="stat-title">🛠️ 方案技术可行性研讨中</div>
          <div class="stat-num text-blue">{{ processingCount }} <span class="sub">条跟进</span></div>
          <div class="stat-tip">产品经理与架构师正在设计方案</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card" @click="filterStatus = 'ACCEPTED'">
          <div class="stat-title">🎯 已采纳并排入Sprint迭代</div>
          <div class="stat-num text-purple">{{ acceptedCount }} <span class="sub">条开发中</span></div>
          <div class="stat-tip">已进入排期，即将在次周版本发布</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card" @click="filterStatus = 'RESOLVED'">
          <div class="stat-title">🚀 成功开发并全网投产上线</div>
          <div class="stat-num text-green">{{ resolvedCount }} <span class="sub">条已闭环</span></div>
          <div class="stat-tip">功能已实装，一线人员已收到上线推送</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 列表卡片 -->
    <el-card shadow="never" class="table-main-card">
      <div class="table-toolbar">
        <div class="toolbar-left">
          <el-radio-group v-model="filterStatus" size="default">
            <el-radio-button label="ALL">全部建言 ({{ systemData.platformFeedbacks.length }})</el-radio-button>
            <el-radio-button label="PENDING">待技术评审 ({{ pendingCount }})</el-radio-button>
            <el-radio-button label="ACCEPTED">已采纳排期 ({{ acceptedCount }})</el-radio-button>
            <el-radio-button label="RESOLVED">已投产上线 ({{ resolvedCount }})</el-radio-button>
          </el-radio-group>
        </div>
        <div class="toolbar-right">
          <el-input
            v-model="searchQuery"
            placeholder="搜索诉求标题/提交人/模块/租户..."
            clearable
            style="width: 260px;"
          >
            <template #prefix><el-icon><Search /></el-icon></template>
          </el-input>
        </div>
      </div>

      <!-- 反馈内容卡片列表 -->
      <div class="feedback-items-container">
        <el-empty
          v-if="paginatedFeedbacks.length === 0"
          description="暂无一线员工反馈建言，平台建言库已清空"
          style="padding: 40px 0;"
        />
        <div
          v-for="item in paginatedFeedbacks"
          :key="item.id"
          class="fb-card-item"
        >
          <div class="fb-card-header">
            <div class="fb-header-left">
              <el-tag :type="getTypeTagType(item.type)" effect="dark" size="small">{{ item.typeName }}</el-tag>
              <el-tag :type="getUrgencyTagType(item.urgency)" size="small">
                {{ item.urgency === 'HIGH' ? '🚨 急需优化' : (item.urgency === 'NORMAL' ? '⚡ 较为期望' : '💡 日常建议') }}
              </el-tag>
              <span class="fb-title">{{ item.title }}</span>
            </div>
            <div class="fb-header-right">
              <el-tag :type="getStatusTagType(item.status)" effect="light" size="default">
                {{ getStatusText(item.status) }}
              </el-tag>
              <el-button type="primary" size="small" @click="openReplyModal(item)">
                💬 研发答复与评审
              </el-button>
            </div>
          </div>

          <div class="fb-meta-bar">
            <span>租户：<b>{{ item.tenantName }}</b> ({{ item.storeName }})</span>
            <span class="divider">|</span>
            <span>提报人：<b>{{ item.staffName }}</b> ({{ item.roleName }})</span>
            <span class="divider">|</span>
            <span>所属功能：<el-tag size="small" type="info">{{ item.module }}</el-tag></span>
            <span class="divider">|</span>
            <span>提报时间：{{ item.createdAt }}</span>
          </div>

          <div class="fb-content-body">
            {{ item.content }}
          </div>

          <!-- 研发团队官方答复展示 -->
          <div v-if="item.devReply" class="dev-reply-box">
            <div class="dev-reply-header">
              <span style="font-weight: 700; color: #0369a1; display: flex; align-items: center; gap: 6px;">
                <el-icon><ChatDotRound /></el-icon> 研发团队官方受理答复 ({{ item.replyAt || '已同步' }})：
              </span>
              <el-tag size="small" type="success">已推送至该一线员工工作台</el-tag>
            </div>
            <div class="dev-reply-content">
              {{ item.devReply }}
            </div>
          </div>
        </div>
      </div>

      <!-- 分页控制 -->
      <div class="pagination-footer">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[5, 10, 20]"
          layout="total, sizes, prev, pager, next"
          :total="filteredFeedbacks.length"
        />
      </div>
    </el-card>

    <!-- 研发答复与状态流转对话框 -->
    <el-dialog v-model="replyModalVisible" title="💬 平台研发团队直达答复与评审" width="580px" destroy-on-close>
      <el-form :model="replyForm" label-position="top">
        <el-form-item label="建议标题">
          <el-input :model-value="activeFeedback?.title" disabled />
        </el-form-item>
        <el-form-item label="建议详细场景描述">
          <el-input :model-value="activeFeedback?.content" type="textarea" :rows="3" disabled />
        </el-form-item>
        <el-form-item label="流转评审处理状态" required>
          <el-radio-group v-model="replyForm.status">
            <el-radio label="PENDING">待技术评审</el-radio>
            <el-radio label="PROCESSING">方案研讨中</el-radio>
            <el-radio label="ACCEPTED">已采纳排期</el-radio>
            <el-radio label="RESOLVED">已上线实装</el-radio>
            <el-radio label="REJECTED">暂不考虑</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="研发团队官方答复与实施说明 (直达一线提交人)" required>
          <el-input
            v-model="replyForm.reply"
            type="textarea"
            :rows="4"
            placeholder="例如：非常感谢张店长的宝贵建议！我们已确认收银端点单流程确实存在繁琐痛点，已将该交互优化列入下周 Sprint 14 排期，预计 3 个工作日内更新上线！"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="replyModalVisible = false">取消</el-button>
        <el-button type="primary" :loading="submittingReply" @click="handleConfirmReply">
          🚀 确认答复并同步状态
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useSystemDataStore } from '@/stores/systemDataStore'
import { ElMessage } from 'element-plus'
import {
  Promotion,
  Search,
  ChatDotRound
} from '@element-plus/icons-vue'

const systemData = useSystemDataStore()

const filterStatus = ref('ALL')
const searchQuery = ref('')
const currentPage = ref(1)
const pageSize = ref(6)

const pendingCount = computed(() => systemData.platformFeedbacks.filter(f => f.status === 'PENDING').length)
const processingCount = computed(() => systemData.platformFeedbacks.filter(f => f.status === 'PROCESSING').length)
const acceptedCount = computed(() => systemData.platformFeedbacks.filter(f => f.status === 'ACCEPTED').length)
const resolvedCount = computed(() => systemData.platformFeedbacks.filter(f => f.status === 'RESOLVED').length)

const filteredFeedbacks = computed(() => {
  return systemData.platformFeedbacks.filter(f => {
    if (filterStatus.value !== 'ALL' && f.status !== filterStatus.value) {
      return false
    }
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.trim().toLowerCase()
      const match =
        f.title.toLowerCase().includes(q) ||
        f.content.toLowerCase().includes(q) ||
        f.staffName.toLowerCase().includes(q) ||
        f.tenantName.toLowerCase().includes(q) ||
        f.module.toLowerCase().includes(q)
      if (!match) return false
    }
    return true
  })
})

const paginatedFeedbacks = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredFeedbacks.value.slice(start, start + pageSize.value)
})

const replyModalVisible = ref(false)
const submittingReply = ref(false)
const activeFeedback = ref<any>(null)
const replyForm = ref({
  status: 'ACCEPTED' as any,
  reply: ''
})

const openReplyModal = (item: any) => {
  activeFeedback.value = item
  replyForm.value = {
    status: item.status || 'ACCEPTED',
    reply: item.devReply || ''
  }
  replyModalVisible.value = true
}

const handleConfirmReply = async () => {
  if (!replyForm.value.reply.trim()) {
    ElMessage.warning('请输入官方答复内容')
    return
  }
  submittingReply.value = true
  try {
    systemData.updatePlatformFeedbackStatus(
      activeFeedback.value.id,
      replyForm.value.status,
      replyForm.value.reply.trim()
    )
    ElMessage.success('🎉 官方答复已成功发送！一线提报员工将在工作台接收到更新提醒')
    replyModalVisible.value = false
  } catch (e: any) {
    ElMessage.error(e.message || '答复失败')
  } finally {
    submittingReply.value = false
  }
}

const getTypeTagType = (type: string) => {
  switch (type) {
    case 'FEATURE_REQUEST': return 'primary'
    case 'EXPERIENCE_OPT': return 'success'
    case 'BUG_REPORT': return 'danger'
    case 'BUSINESS_IDEA': return 'warning'
    default: return 'info'
  }
}

const getUrgencyTagType = (urgency: string) => {
  switch (urgency) {
    case 'HIGH': return 'danger'
    case 'NORMAL': return 'warning'
    default: return 'info'
  }
}

const getStatusTagType = (status: string) => {
  switch (status) {
    case 'PENDING': return 'warning'
    case 'PROCESSING': return 'primary'
    case 'ACCEPTED': return 'info'
    case 'RESOLVED': return 'success'
    case 'REJECTED': return 'danger'
    default: return 'info'
  }
}

const getStatusText = (status: string) => {
  const map: Record<string, string> = {
    PENDING: '⏳ 待技术评审',
    PROCESSING: '🛠️ 方案研讨中',
    ACCEPTED: '🎯 已采纳排期',
    RESOLVED: '🚀 已上线实装',
    REJECTED: '暂不考虑'
  }
  return map[status] || status
}
</script>

<style scoped>
.vendor-feedback-container {
  padding: 18px 24px 40px;
  background: #f8fafc;
  min-height: calc(100vh - 60px);
}

.page-hero-header {
  background: linear-gradient(135deg, #ffffff 0%, #fffbeb 100%);
  border: 1px solid #fef3c7;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(217, 119, 6, 0.04);
  margin-bottom: 18px;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hero-icon-box {
  width: 52px;
  height: 52px;
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(217, 119, 6, 0.25);
}

.hero-title-row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.hero-title {
  margin: 0;
  font-size: 20px;
  font-weight: 800;
  color: #0f172a;
}

.hero-subtitle {
  margin: 6px 0 0;
  font-size: 13px;
  color: #64748b;
  line-height: 1.5;
  max-width: 820px;
}

.stat-cards-row {
  margin-bottom: 18px;
}

.stat-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  cursor: pointer;
  transition: all 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.stat-title {
  font-size: 13px;
  font-weight: 700;
  color: #475569;
}

.stat-num {
  font-size: 24px;
  font-weight: 800;
  line-height: 1.2;
  margin: 8px 0 4px;
}

.stat-num .sub {
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
}

.stat-tip {
  font-size: 12px;
  color: #64748b;
}

.text-amber { color: #d97706; }
.text-blue { color: #0284c7; }
.text-purple { color: #7c3aed; }
.text-green { color: #059669; }

.table-main-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.table-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 16px;
}

.feedback-items-container {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.fb-card-item {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
  transition: all 0.2s;
}

.fb-card-item:hover {
  border-color: #cbd5e1;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
}

.fb-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.fb-header-left {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.fb-title {
  font-size: 15px;
  font-weight: 800;
  color: #0f172a;
}

.fb-header-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

.fb-meta-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  font-size: 12px;
  color: #64748b;
  margin-top: 10px;
  padding: 6px 12px;
  background: #f8fafc;
  border-radius: 6px;
  border: 1px solid #f1f5f9;
}

.fb-meta-bar .divider {
  color: #cbd5e1;
}

.fb-content-body {
  font-size: 14px;
  color: #334155;
  line-height: 1.6;
  margin-top: 12px;
}

.dev-reply-box {
  margin-top: 12px;
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  padding: 12px 16px;
}

.dev-reply-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.dev-reply-content {
  font-size: 13px;
  color: #0369a1;
  line-height: 1.5;
}

.pagination-footer {
  margin-top: 18px;
  display: flex;
  justify-content: flex-end;
}
</style>
