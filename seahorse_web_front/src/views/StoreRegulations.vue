<template>
  <div class="store-regulations-page">
    <!-- 顶部主标题卡片 -->
    <div class="page-header-card">
      <div class="header-main-row">
        <div class="header-left">
          <div class="title-row">
            <h2 class="page-title">📜 门店规章制度与员工协同中心</h2>
            <el-tag type="primary" effect="dark" class="header-badge">制度合规 · 电子签署 · 意见闭环</el-tag>
            <el-tag type="success" effect="plain" class="store-badge">
              🏬 {{ currentStoreName }}
            </el-tag>
          </div>
          <p class="page-subtitle">
            支持店长或租户编辑发布各类规章制度，一键生成高清宣传海报、导出标准红头公文/PDF，支持员工在线查阅与防抵赖电子手写签名，搭建员工心声与匿名意见箱。
          </p>
        </div>

        <div class="header-right">
          <el-button
            v-if="isManagerOrBoss"
            type="primary"
            icon="Plus"
            size="default"
            @click="handleOpenCreateRegulation"
          >
            发布新规章制度
          </el-button>
          <el-button
            type="warning"
            plain
            icon="ChatLineRound"
            size="default"
            @click="handleOpenSubmitFeedback()"
          >
            💡 提交合理化建议/意见
          </el-button>
          <el-button
            icon="Message"
            plain
            size="default"
            @click="activeMainTab = 'FEEDBACK_BOX'"
          >
            📬 全员意见箱与心声{{ isManagerOrBoss && pendingFeedbackCount > 0 ? ` (${pendingFeedbackCount}条待办)` : '' }}
          </el-button>
          <el-button icon="Refresh" circle @click="refreshData" title="刷新数据" />
        </div>
      </div>
    </div>

    <!-- 核心运行指标卡片矩阵 -->
    <div class="stats-overview-grid">
      <div class="stat-card">
        <div class="stat-info">
          <span class="stat-label">规章制度总数</span>
          <span class="stat-value text-blue">{{ currentStoreRegulations.length }}</span>
        </div>
        <el-icon class="stat-icon icon-blue"><Document /></el-icon>
      </div>

      <div class="stat-card">
        <div class="stat-info">
          <span class="stat-label">强制全员签署</span>
          <span class="stat-value text-orange">{{ requireSignatureCount }} 项</span>
        </div>
        <el-icon class="stat-icon icon-orange"><EditPen /></el-icon>
      </div>

      <div class="stat-card">
        <div class="stat-info">
          <span class="stat-label">全员签署达成率</span>
          <span class="stat-value text-green">{{ overallSignatureRate }}%</span>
        </div>
        <el-icon class="stat-icon icon-green"><CircleCheck /></el-icon>
      </div>

      <div class="stat-card">
        <div class="stat-info">
          <span class="stat-label">员工意见建议待办</span>
          <span class="stat-value text-purple">{{ pendingFeedbackCount }} 条</span>
        </div>
        <el-icon class="stat-icon icon-purple"><Bell /></el-icon>
      </div>

      <div class="stat-card">
        <div class="stat-info">
          <span class="stat-label">建议已采纳与改进</span>
          <span class="stat-value text-emerald">{{ acceptedFeedbackCount }} 条</span>
        </div>
        <el-icon class="stat-icon icon-emerald"><Trophy /></el-icon>
      </div>
    </div>

    <!-- 主功能模块切换 Tabs -->
    <el-card class="content-card" shadow="never">
      <el-tabs v-model="activeMainTab" class="custom-nav-tabs">
        <!-- 选项卡 1: 规章制度管理与查阅 -->
        <el-tab-pane label="📜 门店规章制度文库" name="REGULATION_LIST">
          <!-- 筛选与搜索工具栏 -->
          <div class="filter-toolbar">
            <div class="filter-left">
              <!-- 门店选择 (多店统一联动) -->
              <el-select
                v-model="selectedStoreId"
                placeholder="选择门店"
                style="width: 280px;"
                @change="fetchCloudNotices"
              >
                <el-option label="全部适用门店 (集团通用)" value="ALL" />
                <el-option
                  v-for="store in availableStores"
                  :key="store.storeId"
                  :label="store.storeName"
                  :value="store.storeId"
                />
              </el-select>

              <!-- 制度分类过滤 -->
              <el-radio-group v-model="selectedCategory" size="default">
                <el-radio-button label="ALL">全部制度</el-radio-button>
                <el-radio-button label="SERVICE">服务礼仪</el-radio-button>
                <el-radio-button label="ATTENDANCE">考勤考纪</el-radio-button>
                <el-radio-button label="SAFETY">安全作业</el-radio-button>
                <el-radio-button label="COMMISSION">奖惩绩效</el-radio-button>
                <el-radio-button label="CONFIDENTIAL">保密协议</el-radio-button>
              </el-radio-group>

              <!-- 签署要求过滤 -->
              <el-select v-model="selectedSignFilter" placeholder="签署要求" style="width: 140px;">
                <el-option label="全部要求" value="ALL" />
                <el-option label="需电子签字" value="NEED_SIGN" />
                <el-option label="无需签字" value="NO_SIGN" />
              </el-select>

              <!-- 搜索框 -->
              <el-input
                v-model="searchKeyword"
                placeholder="检索规章制度标题、核心条款..."
                prefix-icon="Search"
                clearable
                style="width: 240px;"
              />
            </div>

            <div class="filter-right">
              <span class="filter-stats">
                共找到 <strong>{{ filteredRegulations.length }}</strong> 部现行规章制度
              </span>
            </div>
          </div>

          <!-- 规章制度卡片矩阵 -->
          <div v-if="filteredRegulations.length > 0" class="regulation-cards-grid">
            <div
              v-for="reg in filteredRegulations"
              :key="reg.id"
              class="regulation-card"
              :class="{ 'require-sign-card': reg.requireSignature }"
            >
              <!-- 卡片顶部分类与版本 -->
              <div class="card-top-header">
                <div class="header-tags">
                  <el-tag :type="getCategoryTagType(reg.category)" effect="dark" size="small">
                    {{ reg.categoryName }}
                  </el-tag>
                  <el-tag type="info" effect="plain" size="small">
                    {{ reg.version }}
                  </el-tag>
                  <el-tag v-if="reg.requireSignature" type="danger" effect="plain" size="small" class="sign-tag">
                    ✍️ 强制电子签字确认
                  </el-tag>
                </div>
                <div class="status-indicator">
                  <span class="effective-date">生效日期：{{ reg.effectiveDate }}</span>
                </div>
              </div>

              <!-- 标题与摘要 -->
              <h3 class="reg-title" @click="handleOpenReadDialog(reg)">
                {{ reg.title }}
              </h3>
              <p class="reg-summary">
                “{{ reg.summary }}”
              </p>

              <!-- 提炼核心红线条款 -->
              <div class="keypoints-box">
                <div class="keypoints-header">
                  <span class="kp-icon">📌</span>
                  <span class="kp-label">核心执行要点速览：</span>
                </div>
                <ul class="kp-list">
                  <li v-for="(kp, kidx) in reg.keyPoints.slice(0, 3)" :key="kidx">
                    {{ kp }}
                  </li>
                </ul>
              </div>

              <!-- 员工签署与阅读状态栏 -->
              <div class="reg-progress-section">
                <template v-if="reg.requireSignature">
                  <div class="progress-bar-row">
                    <span class="progress-label">
                      员工签署进度：<strong>{{ reg.signatures?.length || 0 }}</strong> / {{ totalStoreStaffCount }} 人
                    </span>
                    <span class="progress-percent">
                      {{ Math.round(((reg.signatures?.length || 0) / (totalStoreStaffCount || 1)) * 100) }}%
                    </span>
                  </div>
                  <el-progress
                    :percentage="Math.min(100, Math.round(((reg.signatures?.length || 0) / (totalStoreStaffCount || 1)) * 100))"
                    :color="getSignatureProgressColor(reg)"
                    :stroke-width="8"
                    :show-text="false"
                  />
                </template>
                <template v-else>
                  <div class="no-sign-row">
                    <span class="no-sign-desc">📢 普通通告制度，无需员工手写签名</span>
                    <el-tag size="small" type="success" effect="plain">
                      已查阅 {{ reg.readStaffIds?.length || 0 }} 人
                    </el-tag>
                  </div>
                </template>

                <!-- 当前登录员工本人的签署状态提醒 -->
                <div class="my-status-box">
                  <template v-if="isCurrentStaffSigned(reg)">
                    <el-tag type="success" size="small" effect="light">
                      ✅ 本人已于 {{ getCurrentStaffSignTime(reg) }} 签署
                    </el-tag>
                  </template>
                  <template v-else-if="reg.requireSignature">
                    <el-tag type="danger" size="small" effect="light" class="pulse-sign-badge">
                      ⚠️ 您尚未签字确认，请尽快完成手写签署
                    </el-tag>
                  </template>
                  <template v-else>
                    <el-tag type="info" size="small" effect="light">
                      👀 您已了解本制度细则
                    </el-tag>
                  </template>
                </div>
              </div>

              <!-- 底部操作按钮栏 -->
              <div class="card-footer-actions">
                <div class="left-actions">
                  <el-button
                    type="primary"
                    size="small"
                    @click="handleOpenReadDialog(reg)"
                  >
                    📖 查看全文
                  </el-button>
                  <el-button
                    v-if="reg.requireSignature"
                    :type="isCurrentStaffSigned(reg) ? 'default' : 'warning'"
                    size="small"
                    @click="handleOpenSignModal(reg)"
                  >
                    {{ isCurrentStaffSigned(reg) ? '👁️ 查阅我的签名' : '✍️ 立即电子签字' }}
                  </el-button>
                </div>

                <div class="right-actions">
                  <el-dropdown trigger="click">
                    <el-button size="small" plain>
                      分发与管理 <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                    </el-button>
                    <template #dropdown>
                      <el-dropdown-menu>
                        <el-dropdown-item @click="handleOpenPosterGenerator(reg)">
                          <el-icon><Picture /></el-icon> 🎨 生成宣传海报 (图片导出)
                        </el-dropdown-item>
                        <el-dropdown-item @click="handleOpenPdfExport(reg)">
                          <el-icon><Printer /></el-icon> 📄 红头公文打印 / 导出PDF
                        </el-dropdown-item>
                        <el-dropdown-item @click="handleCopyNoticeText(reg)">
                          <el-icon><DocumentCopy /></el-icon> 📋 复制企微/钉钉通知文案
                        </el-dropdown-item>
                        <el-dropdown-item divided @click="handleOpenSubmitFeedback(reg)">
                          <el-icon><ChatLineRound /></el-icon> 💡 对本制度提建议/反馈
                        </el-dropdown-item>
                        <template v-if="isManagerOrBoss">
                          <el-dropdown-item
                            v-if="reg.requireSignature"
                            @click="handleOpenSignatureBoard(reg)"
                          >
                            <el-icon><UserFilled /></el-icon> 👥 查看全员签署看板
                          </el-dropdown-item>
                          <el-dropdown-item divided @click="handleEditRegulation(reg)">
                            <el-icon><Edit /></el-icon> ✏️ 编辑制度条款
                          </el-dropdown-item>
                          <el-dropdown-item @click="handleDeleteRegulation(reg)">
                            <span style="color: #ef4444;"><el-icon><Delete /></el-icon> 🗑️ 下架/删除制度</span>
                          </el-dropdown-item>
                        </template>
                      </el-dropdown-menu>
                    </template>
                  </el-dropdown>
                </div>
              </div>
            </div>
          </div>

          <!-- 空状态 -->
          <div v-else class="empty-state">
            <el-empty description="暂无符合条件的规章制度">
              <el-button v-if="isManagerOrBoss" type="primary" icon="Plus" @click="handleOpenCreateRegulation">
                立即新建制度
              </el-button>
            </el-empty>
          </div>
        </el-tab-pane>

        <!-- 选项卡 2: 员工心声与合理化建议箱 -->
        <el-tab-pane name="FEEDBACK_BOX">
          <template #label>
            <span>
              📬 全员意见箱与心声交流
              <el-badge v-if="pendingFeedbackCount > 0" :value="pendingFeedbackCount" class="tab-badge" />
            </span>
          </template>

          <div class="feedback-page-container">
            <!-- 全员公开透明协同告知条 -->
            <div class="feedback-public-notice">
              <div class="notice-text">
                <el-icon class="notice-icon"><InfoFilled /></el-icon>
                <span><strong>全员公开透明协同机制：</strong>全店所有员工（包括技师、收银员、店长及老板）均有权限公开查阅全员心声、改进建议及管理方的官方答复公示，促进门店共同进步与规章完善；任何员工均可自由提出意见（可勾选完全匿名脱敏保护隐私）。</span>
              </div>
            </div>

            <!-- 建议箱操作与过滤工具栏 -->
            <div class="filter-toolbar">
              <div class="filter-left">
                <el-radio-group v-model="feedbackScopeFilter" size="default" style="margin-right: 8px;">
                  <el-radio-button label="ALL">🌐 全员公开心声 ({{ systemData.staffFeedbacks.length }})</el-radio-button>
                  <el-radio-button label="MY">👤 我提交的反馈 ({{ myFeedbackCount }})</el-radio-button>
                </el-radio-group>

                <el-radio-group v-model="feedbackStatusFilter" size="default">
                  <el-radio-button label="ALL">全部状态</el-radio-button>
                  <el-radio-button label="PENDING">待处理 ({{ pendingFeedbackCount }})</el-radio-button>
                  <el-radio-button label="ACCEPTED">已采纳</el-radio-button>
                  <el-radio-button label="IMPLEMENTED">已落地改进</el-radio-button>
                  <el-radio-button label="EXPLAINED">解释说明</el-radio-button>
                </el-radio-group>

                <el-select v-model="feedbackTypeFilter" placeholder="建议类型" style="width: 140px;">
                  <el-option label="全部类型" value="ALL" />
                  <el-option label="改进建议" value="SUGGESTION" />
                  <el-option label="执行困难" value="DIFFICULTY" />
                  <el-option label="申诉反馈" value="APPEAL" />
                  <el-option label="创新提案" value="INNOVATION" />
                </el-select>

                <el-input
                  v-model="feedbackKeyword"
                  placeholder="搜索建议标题、内容..."
                  prefix-icon="Search"
                  clearable
                  style="width: 220px;"
                />
              </div>

              <div class="filter-right">
                <el-button type="primary" icon="Plus" @click="handleOpenSubmitFeedback()">
                  + 提出我的建议 (支持完全匿名)
                </el-button>
              </div>
            </div>

            <!-- 员工建议卡片列表 -->
            <div v-if="filteredFeedbacks.length > 0" class="feedback-list">
              <div
                v-for="fb in filteredFeedbacks"
                :key="fb.id"
                class="feedback-card"
                :class="['status-' + fb.status.toLowerCase()]"
              >
                <!-- 建议头部 -->
                <div class="fb-header">
                  <div class="fb-user-info">
                    <el-avatar
                      :size="38"
                      :style="{ backgroundColor: fb.isAnonymous ? '#64748b' : '#0284c7' }"
                    >
                      {{ fb.isAnonymous ? '匿' : fb.staffName?.substring(0, 1) || '员' }}
                    </el-avatar>
                    <div>
                      <div class="fb-author-row">
                        <span class="fb-author-name">
                          {{ fb.isAnonymous ? '🕵️ 匿名员工 (已由系统隐私脱敏)' : fb.staffName }}
                        </span>
                        <el-tag :type="getFeedbackTypeTag(fb.type)" size="small" effect="plain">
                          {{ fb.typeName }}
                        </el-tag>
                        <el-tag v-if="fb.priority === 'URGENT'" type="danger" size="small" effect="dark">
                          🔥 紧急关注
                        </el-tag>
                      </div>
                      <div class="fb-time-row">
                        <span>提交时间：{{ fb.createdAt }}</span>
                        <span v-if="fb.regulationTitle" class="fb-target-reg">
                          关联制度：【{{ fb.regulationTitle }}】
                        </span>
                      </div>
                    </div>
                  </div>

                  <div class="fb-status-tag">
                    <el-tag :type="getFeedbackStatusTag(fb.status)" size="default" effect="dark">
                      {{ getFeedbackStatusLabel(fb.status) }}
                    </el-tag>
                  </div>
                </div>

                <!-- 建议标题与正文 -->
                <h4 class="fb-title">{{ fb.title }}</h4>
                <div class="fb-content">
                  {{ fb.content }}
                </div>

                <!-- 官方回复展示区 -->
                <div v-if="fb.replyContent" class="fb-official-reply">
                  <div class="reply-header">
                    <span class="reply-badge">🏢 门店管理方官方答复与处理公示</span>
                    <span class="reply-meta">
                      答复人：{{ fb.replierName || '管理督导' }} · {{ fb.replyTime }}
                    </span>
                  </div>
                  <div class="reply-text">
                    {{ fb.replyContent }}
                  </div>
                </div>

                <!-- 底部操作按钮 -->
                <div class="fb-actions-bar">
                  <span class="fb-id-tag">编号: {{ fb.id }}</span>
                  <div class="fb-btns">
                    <el-button
                      v-if="isManagerOrBoss"
                      type="primary"
                      size="small"
                      plain
                      icon="ChatDotRound"
                      @click="handleOpenReplyFeedback(fb)"
                    >
                      {{ fb.replyContent ? '修改官方答复' : '✍️ 撰写答复与处理' }}
                    </el-button>
                  </div>
                </div>
              </div>
            </div>

            <!-- 空状态 -->
            <div v-else class="empty-state">
              <el-empty description="暂无相关员工建议记录">
                <el-button type="primary" icon="Plus" @click="handleOpenSubmitFeedback()">
                  成为第一个提出建议的员工
                </el-button>
              </el-empty>
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- ========================================================================= -->
    <!-- 弹窗 1: 规章制度创建/编辑对话框 -->
    <!-- ========================================================================= -->
    <el-dialog
      v-model="editDialogVisible"
      :title="isEditing ? '✏️ 编辑规章制度' : '📜 发布新规章制度'"
      width="780px"
      destroy-on-close
    >
      <el-form :model="editForm" label-width="120px">
        <el-row :gutter="16">
          <el-col :span="16">
            <el-form-item label="制度标题" required>
              <el-input v-model="editForm.title" placeholder="如：海马智慧门店员工日常出勤与服务礼仪守则" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="所属分类" required>
              <el-select v-model="editForm.category" style="width: 100%;" @change="handleCategoryChange">
                <el-option label="📜 服务礼仪规范" value="SERVICE" />
                <el-option label="⏰ 考勤考纪规范" value="ATTENDANCE" />
                <el-option label="🛡️ 安全卫生规范" value="SAFETY" />
                <el-option label="🏆 奖惩考核规范" value="COMMISSION" />
                <el-option label="🔒 保密协议规范" value="CONFIDENTIAL" />
                <el-option label="📢 门店日常业务公告" value="NOTICE" />
                <el-option label="🚨 特别重要特急通知" value="URGENT" />
                <el-option label="📋 综合管理制度" value="OTHER" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="16">
          <el-col :span="8">
            <el-form-item label="版本号">
              <el-input v-model="editForm.version" placeholder="如 V2.3" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="生效日期">
              <el-date-picker
                v-model="editForm.effectiveDate"
                type="date"
                value-format="YYYY-MM-DD"
                placeholder="选择生效日期"
                style="width: 100%;"
              />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="适用门店">
              <el-select v-model="editForm.storeId" style="width: 100%;">
                <el-option label="全连锁通用" value="ALL" />
                <el-option
                  v-for="s in availableStores"
                  :key="s.storeId"
                  :label="s.storeName"
                  :value="s.storeId"
                />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="特急重要通知">
              <div style="display: flex; align-items: center; gap: 8px;">
                <el-switch v-model="editForm.isUrgent" active-text="🚨 标记为特别重要特急通知" active-color="#ef4444" />
              </div>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="APP提示音乐">
              <div style="display: flex; align-items: center; gap: 8px;">
                <el-switch v-model="editForm.playMusic" active-text="🔔 推送手机端播放提示音乐" active-color="#f59e0b" />
              </div>
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="强制电子签字">
          <div style="display: flex; align-items: center; gap: 12px;">
            <el-switch v-model="editForm.requireSignature" active-text="强制要求员工手写电子签字确认" />
            <span style="font-size: 12px; color: #94a3b8;">
              (开启后，员工查阅时必须完成手写签名，系统将记录签名笔迹备查)
            </span>
          </div>
        </el-form-item>

        <el-form-item label="制度核心摘要">
          <el-input
            v-model="editForm.summary"
            type="textarea"
            :rows="2"
            placeholder="用一两句话简述制度核心要义，展示在卡片与海报副标题中"
          />
        </el-form-item>

        <el-form-item label="核心红线条款">
          <div class="dynamic-keypoints-editor">
            <div
              v-for="(kp, idx) in editForm.keyPoints"
              :key="idx"
              class="kp-edit-row"
            >
              <el-input v-model="editForm.keyPoints[idx]" placeholder="输入一条红线/核心执行要点" style="flex: 1;" />
              <el-button circle icon="Delete" type="danger" plain size="small" @click="removeKeyPoint(idx)" />
            </div>
            <el-button
              type="primary"
              plain
              size="small"
              icon="Plus"
              style="margin-top: 6px;"
              @click="addKeyPoint"
            >
              + 增加一条执行要点
            </el-button>
          </div>
        </el-form-item>

        <el-form-item label="制度完整正文">
          <el-input
            v-model="editForm.content"
            type="textarea"
            :rows="8"
            placeholder="输入完整章程条款正文内容（支持分章分节排版）"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveRegulation">
          确认并立即发布
        </el-button>
      </template>
    </el-dialog>

    <!-- ========================================================================= -->
    <!-- 弹窗 2: 规章制度全文查阅模态框 -->
    <!-- ========================================================================= -->
    <el-dialog
      v-model="readDialogVisible"
      :title="`📖 规章制度详情 · ${currentViewingReg?.title || ''}`"
      width="780px"
      destroy-on-close
    >
      <div v-if="currentViewingReg" class="read-dialog-content">
        <!-- 头部元信息 -->
        <div class="read-meta-box">
          <div class="read-meta-item">
            <span class="meta-label">类别：</span>
            <el-tag size="small" :type="getCategoryTagType(currentViewingReg.category)">
              {{ currentViewingReg.categoryName }}
            </el-tag>
          </div>
          <div class="read-meta-item">
            <span class="meta-label">版本号：</span>
            <span>{{ currentViewingReg.version }}</span>
          </div>
          <div class="read-meta-item">
            <span class="meta-label">生效执行：</span>
            <span>{{ currentViewingReg.effectiveDate }}</span>
          </div>
          <div class="read-meta-item">
            <span class="meta-label">发布方：</span>
            <span>{{ currentViewingReg.publisher }}</span>
          </div>
        </div>

        <!-- 制度摘要 -->
        <div class="read-summary-quote">
          💡 <strong>制度摘要：</strong>{{ currentViewingReg.summary }}
        </div>

        <!-- 核心条款速览卡片 -->
        <div class="read-keypoints-card">
          <div class="rkp-title">📌 核心红线与重点要求：</div>
          <ol class="rkp-ol">
            <li v-for="(kp, i) in currentViewingReg.keyPoints" :key="i">
              {{ kp }}
            </li>
          </ol>
        </div>

        <!-- 正文 -->
        <div class="read-body-box">
          <pre class="formatted-pre">{{ currentViewingReg.content }}</pre>
        </div>

        <!-- 签署提醒栏 -->
        <div v-if="currentViewingReg.requireSignature" class="sign-callout-box">
          <div v-if="isCurrentStaffSigned(currentViewingReg)" class="signed-done">
            <el-icon class="done-icon"><CircleCheckFilled /></el-icon>
            <div>
              <div style="font-weight: 700; color: #15803d;">您已完成本规章制度的电子签署</div>
              <div style="font-size: 12px; color: #64748b;">
                签署时间：{{ getCurrentStaffSignTime(currentViewingReg) }} · 签名笔迹已加密留存
              </div>
            </div>
          </div>
          <div v-else class="sign-needed">
            <div>
              <div style="font-weight: 700; color: #b91c1c;">⚠️ 本制度要求全体员工手写签名确认</div>
              <div style="font-size: 12px; color: #7f1d1d;">
                请仔细阅读上述全部条款后，点击右侧按钮进行电子签字。
              </div>
            </div>
            <el-button type="danger" icon="EditPen" @click="handleOpenSignModal(currentViewingReg)">
              立即进入手写签字
            </el-button>
          </div>
        </div>
      </div>

      <template #footer>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <el-button icon="ChatLineRound" plain @click="handleOpenSubmitFeedback(currentViewingReg)">
            💡 对本制度提建议
          </el-button>
          <div>
            <el-button @click="readDialogVisible = false">关闭</el-button>
            <el-button type="primary" @click="handleOpenPosterGenerator(currentViewingReg)">
              🎨 生成海报
            </el-button>
          </div>
        </div>
      </template>
    </el-dialog>

    <!-- ========================================================================= -->
    <!-- 弹窗 3: 宣传海报生成与导出模态框 -->
    <!-- ========================================================================= -->
    <el-dialog
      v-model="posterDialogVisible"
      title="🎨 规章制度宣传海报生成器 (支持高清导出)"
      width="700px"
      destroy-on-close
    >
      <div class="poster-modal-body">
        <div class="poster-toolbar">
          <div class="poster-theme-select">
            <span style="font-size: 13px; font-weight: 600; color: #334155;">海报风格主题：</span>
            <el-radio-group v-model="posterTheme" size="small" @change="renderPosterCanvas">
              <el-radio-button label="OCEAN_BLUE">🌊 经典海马蓝</el-radio-button>
              <el-radio-button label="ROYAL_GOLD">👑 雅致品质金</el-radio-button>
              <el-radio-button label="CRIMSON_RED">🏮 严谨合规红</el-radio-button>
            </el-radio-group>
          </div>
          <div class="poster-download-btns">
            <el-button type="primary" icon="Download" @click="downloadPosterImage">
              一键下载海报图片 (PNG)
            </el-button>
          </div>
        </div>

        <!-- 真实渲染海报的 Canvas -->
        <div class="poster-canvas-wrapper">
          <canvas ref="posterCanvasRef" class="poster-canvas" width="640" height="960"></canvas>
        </div>
        <p class="poster-hint">
          💡 提示：海报附带移动端制度直达二维码与公章标识，下载后可直接发送至门店微信群、朋友圈或打印张贴于员工休息室。
        </p>
      </div>

      <template #footer>
        <el-button @click="posterDialogVisible = false">关闭</el-button>
        <el-button type="primary" icon="Download" @click="downloadPosterImage">
          下载高清海报
        </el-button>
      </template>
    </el-dialog>

    <!-- ========================================================================= -->
    <!-- 弹窗 4: 红头公文与 PDF 打印导出模态框 -->
    <!-- ========================================================================= -->
    <el-dialog
      v-model="pdfDialogVisible"
      title="📄 红头公文排版与 PDF 打印中心"
      width="820px"
      destroy-on-close
    >
      <div class="pdf-modal-body">
        <div class="pdf-actions-header">
          <el-button type="primary" icon="Printer" @click="triggerBrowserPrint">
            🖨️ 打印 / 另存为 PDF 文件
          </el-button>
          <el-button icon="DocumentCopy" plain @click="handleCopyNoticeText(currentViewingReg)">
            📋 复制企业微信/钉钉群发公告文本
          </el-button>
        </div>

        <!-- 严格标准的红头公文排版容器 (支持打印) -->
        <div id="printable-document-container" class="printable-doc-sheet">
          <div class="doc-header-red">
            <div class="doc-corp-title">海马智慧门店运营管理中心公文</div>
            <div class="doc-serial-row">
              <span class="doc-serial">海马规字〔2026〕第 {{ currentViewingReg?.id.replace('REG-', '') || '01' }} 号</span>
              <span class="doc-level">【全员签发·遵照执行】</span>
            </div>
            <div class="doc-red-divider">
              <span class="red-star">★</span>
            </div>
          </div>

          <h2 class="doc-subject-title">
            关于印发《{{ currentViewingReg?.title }}》的通知
          </h2>

          <div class="doc-meta-info">
            <span>印发门店：{{ currentStoreName }}</span>
            <span>发文字号：海马规〔2026〕{{ currentViewingReg?.version }}</span>
            <span>签发日期：{{ currentViewingReg?.effectiveDate }}</span>
          </div>

          <div class="doc-greeting">
            各分店店长、主管及全体在册员工：
          </div>

          <div class="doc-intro-p">
            为进一步规范门店日常运营标准，保障客户服务品质与企业合法权益，现将《{{ currentViewingReg?.title }}》正式印发给你们。请各分店主管组织全体员工认真研读，严格贯彻执行。
          </div>

          <!-- 核心红线条款引用 -->
          <div class="doc-sub-block">
            <div class="doc-block-title">【一、核心要点与红线守则】</div>
            <ol class="doc-ol">
              <li v-for="(kp, kidx) in currentViewingReg?.keyPoints" :key="kidx">
                {{ kp }}
              </li>
            </ol>
          </div>

          <!-- 完整章程条款 -->
          <div class="doc-sub-block">
            <div class="doc-block-title">【二、章程规程细则】</div>
            <pre class="doc-pre">{{ currentViewingReg?.content }}</pre>
          </div>

          <!-- 签署回执单栏 -->
          <div class="doc-receipt-box">
            <div class="receipt-title">员工阅知与签署回执确认栏（存根）</div>
            <table class="receipt-table">
              <thead>
                <tr>
                  <th width="120">员工姓名</th>
                  <th width="140">所属岗位/工种</th>
                  <th width="140">签署确认状态</th>
                  <th>手写签名笔迹 / 签章</th>
                  <th width="160">签署时间</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="s in currentStoreStaffList.slice(0, 5)" :key="s.id">
                  <td>{{ s.realName }}</td>
                  <td>{{ s.postName }}</td>
                  <td>
                    <span v-if="getStaffSignature(currentViewingReg, s.id)" style="color: #16a34a; font-weight: bold;">
                      已电子签署
                    </span>
                    <span v-else style="color: #ea580c;">待签署</span>
                  </td>
                  <td>
                    <img
                      v-if="getStaffSignature(currentViewingReg, s.id)?.signatureDataUrl"
                      :src="getStaffSignature(currentViewingReg, s.id)?.signatureDataUrl"
                      style="max-height: 28px; vertical-align: middle;"
                    />
                    <span v-else style="color: #94a3b8; font-size: 11px;">(待签字)</span>
                  </td>
                  <td>{{ getStaffSignature(currentViewingReg, s.id)?.signedAt || '-' }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- 红头公章与落款 -->
          <div class="doc-footer-seal-box">
            <div class="doc-seal-wrap">
              <div class="official-red-seal">
                <div class="seal-star">★</div>
                <div class="seal-text-top">海马智慧门店运营中心</div>
                <div class="seal-text-bottom">业务合规专章</div>
              </div>
            </div>
            <div class="doc-signer-info">
              <div>发文机构：海马智慧连锁运营督导委员会</div>
              <div>签发日期：{{ currentViewingReg?.effectiveDate }}</div>
            </div>
          </div>
        </div>
      </div>

      <template #footer>
        <el-button @click="pdfDialogVisible = false">关闭</el-button>
        <el-button type="primary" icon="Printer" @click="triggerBrowserPrint">
          立即打印 / 另存为PDF
        </el-button>
      </template>
    </el-dialog>

    <!-- ========================================================================= -->
    <!-- 弹窗 5: 员工在线手写电子签名板 (Canvas Signature Pad) -->
    <!-- ========================================================================= -->
    <el-dialog
      v-model="signModalVisible"
      title="✍️ 员工规章制度手写电子签名确认"
      width="640px"
      destroy-on-close
    >
      <div class="sign-modal-container">
        <div class="sign-header-alert">
          <el-alert
            title="电子签名合规须知：根据《中华人民共和国电子签名法》，您在此手写的签名将与纸质手写签字具有同等法律效力。"
            type="warning"
            :closable="false"
            show-icon
          />
        </div>

        <div class="sign-reg-info">
          <div>正在签署制度：<strong>《{{ currentSigningReg?.title }}》</strong></div>
          <div class="signer-meta">
            <span>签署人：<b>{{ currentStaffName }}</b></span>
            <span>所属门店：{{ currentStoreName }}</span>
            <span>日期：{{ todayFormatted }}</span>
          </div>
        </div>

        <!-- 手写画布区域 -->
        <div class="canvas-box">
          <div class="canvas-header-bar">
            <span class="canvas-hint">请在下方白色区域内工整手写您的全名：</span>
            <div class="canvas-tools">
              <el-button size="small" plain @click="clearSignaturePad">
                🧹 清除重签
              </el-button>
            </div>
          </div>

          <div class="canvas-border">
            <canvas
              ref="signCanvasRef"
              class="sign-canvas"
              width="580"
              height="200"
              @mousedown="startDrawing"
              @mousemove="draw"
              @mouseup="stopDrawing"
              @mouseleave="stopDrawing"
              @touchstart.prevent="startTouchDrawing"
              @touchmove.prevent="touchDraw"
              @touchend.prevent="stopDrawing"
            ></canvas>
            <div v-if="!hasSignatureDrawn" class="canvas-watermark">
              ✍️ 请在此处签名
            </div>
          </div>
        </div>

        <!-- 承诺同意复选框 -->
        <div class="sign-agreement-box">
          <el-checkbox v-model="signAgreed">
            本人已认真阅读、充分理解并完全同意遵守《{{ currentSigningReg?.title }}》的各项条款及管理要求。
          </el-checkbox>
        </div>
      </div>

      <template #footer>
        <el-button @click="signModalVisible = false">取消</el-button>
        <el-button
          type="primary"
          :disabled="!hasSignatureDrawn || !signAgreed"
          @click="submitSignature"
        >
          确认并提交电子签名
        </el-button>
      </template>
    </el-dialog>

    <!-- ========================================================================= -->
    <!-- 弹窗 6: 全员签署进度与凭证看板 (Manager Only) -->
    <!-- ========================================================================= -->
    <el-dialog
      v-model="signatureBoardVisible"
      :title="`👥 员工签署看板 · ${currentViewingReg?.title || ''}`"
      width="820px"
      destroy-on-close
    >
      <div v-if="currentViewingReg" class="sign-board-body">
        <!-- 进度概览条 -->
        <div class="board-kpi-bar">
          <div class="kpi-item">
            <span class="lbl">在册应签员工</span>
            <span class="val">{{ currentStoreStaffList.length }} 人</span>
          </div>
          <div class="kpi-item text-green">
            <span class="lbl">已完成签署</span>
            <span class="val text-green">{{ currentViewingReg.signatures?.length || 0 }} 人</span>
          </div>
          <div class="kpi-item text-orange">
            <span class="lbl">待催签人数</span>
            <span class="val text-orange">
              {{ Math.max(0, currentStoreStaffList.length - (currentViewingReg.signatures?.length || 0)) }} 人
            </span>
          </div>
          <div class="board-action-right">
            <el-button type="warning" plain icon="Bell" @click="handleCopyReminderText(currentViewingReg)">
              📢 复制未签人员催交通知文案
            </el-button>
          </div>
        </div>

        <!-- 员工列表与签名查看 -->
        <el-table
          :data="currentStoreStaffList"
          style="width: 100%; margin-top: 16px;"
          :header-cell-style="{ background: '#f8fafc', color: '#475569', fontWeight: '600' }"
        >
          <el-table-column label="员工" min-width="150">
            <template #default="{ row }">
              <div style="display: flex; align-items: center; gap: 8px;">
                <el-avatar :size="32" style="background-color: #0284c7; font-size: 13px;">
                  {{ row.realName?.substring(0, 1) || '员' }}
                </el-avatar>
                <div>
                  <div style="font-weight: 700; color: #0f172a;">{{ row.realName }}</div>
                  <div style="font-size: 11px; color: #64748b;">{{ row.postName }}</div>
                </div>
              </div>
            </template>
          </el-table-column>

          <el-table-column prop="phone" label="联系手机号" width="130" />

          <el-table-column label="签署状态" width="120" align="center">
            <template #default="{ row }">
              <el-tag
                v-if="getStaffSignature(currentViewingReg, row.id)"
                type="success"
                effect="dark"
                size="small"
              >
                ✅ 已签署
              </el-tag>
              <el-tag v-else type="danger" effect="plain" size="small">
                ⏳ 待签署
              </el-tag>
            </template>
          </el-table-column>

          <el-table-column label="电子签名手写笔迹" width="180" align="center">
            <template #default="{ row }">
              <div v-if="getStaffSignature(currentViewingReg, row.id)?.signatureDataUrl">
                <el-image
                  :src="getStaffSignature(currentViewingReg, row.id)?.signatureDataUrl"
                  :preview-src-list="[getStaffSignature(currentViewingReg, row.id)?.signatureDataUrl!]"
                  style="width: 120px; height: 36px; object-fit: contain; background: #fafafa; border: 1px dashed #cbd5e1; border-radius: 4px;"
                />
              </div>
              <span v-else style="font-size: 12px; color: #cbd5e1;">-</span>
            </template>
          </el-table-column>

          <el-table-column label="签署时间 / 设备" min-width="180">
            <template #default="{ row }">
              <div v-if="getStaffSignature(currentViewingReg, row.id)">
                <div style="font-size: 12px; color: #334155;">{{ getStaffSignature(currentViewingReg, row.id)?.signedAt }}</div>
                <div style="font-size: 11px; color: #94a3b8;">{{ getStaffSignature(currentViewingReg, row.id)?.deviceInfo || 'PC工作台' }}</div>
              </div>
              <span v-else style="color: #94a3b8; font-size: 12px;">尚未完成签署</span>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <template #footer>
        <el-button @click="signatureBoardVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- ========================================================================= -->
    <!-- 弹窗 7: 员工提交意见/反馈对话框 -->
    <!-- ========================================================================= -->
    <el-dialog
      v-model="feedbackDialogVisible"
      title="💡 提出员工心声与合理化建议"
      width="640px"
      destroy-on-close
    >
      <el-form :model="feedbackForm" label-width="110px">
        <el-form-item label="关联制度">
          <el-select
            v-model="feedbackForm.regulationId"
            placeholder="对某项具体规章制度提意见（可选）"
            clearable
            style="width: 100%;"
            @change="handleSelectFeedbackReg"
          >
            <el-option label="【全局通用】对门店综合运营提出建议" value="" />
            <el-option
              v-for="r in currentStoreRegulations"
              :key="r.id"
              :label="r.title"
              :value="r.id"
            />
          </el-select>
        </el-form-item>

        <el-row :gutter="12">
          <el-col :span="12">
            <el-form-item label="建议类型" required>
              <el-select v-model="feedbackForm.type" style="width: 100%;">
                <el-option label="改进建议" value="SUGGESTION" />
                <el-option label="执行困难" value="DIFFICULTY" />
                <el-option label="合理化创新" value="INNOVATION" />
                <el-option label="申诉反馈" value="APPEAL" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="紧急程度">
              <el-radio-group v-model="feedbackForm.priority" size="default">
                <el-radio-button label="NORMAL">一般建议</el-radio-button>
                <el-radio-button label="URGENT">紧急关注</el-radio-button>
              </el-radio-group>
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="是否匿名提交">
          <div style="display: flex; align-items: center; gap: 10px;">
            <el-switch v-model="feedbackForm.isAnonymous" active-text="完全匿名提交" />
            <span style="font-size: 12px; color: #64748b;">
              (若开启，店长与后台均无法查看您的姓名与工号，保护真实表达)
            </span>
          </div>
        </el-form-item>

        <el-form-item label="建议标题" required>
          <el-input v-model="feedbackForm.title" placeholder="如：建议优化周末晚高峰的翻台消毒工序" />
        </el-form-item>

        <el-form-item label="建议详细内容" required>
          <el-input
            v-model="feedbackForm.content"
            type="textarea"
            :rows="5"
            placeholder="请详细描述遇到的问题、改进设想及预期效果，管理团队将定期评阅并答复..."
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="feedbackDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmSubmitFeedback">
          确认提交建议
        </el-button>
      </template>
    </el-dialog>

    <!-- ========================================================================= -->
    <!-- 弹窗 8: 店长/租户答复处理员工意见对话框 -->
    <!-- ========================================================================= -->
    <el-dialog
      v-model="replyFeedbackDialogVisible"
      title="✍️ 官方答复与处理公示"
      width="640px"
      destroy-on-close
    >
      <div v-if="activeReplyingFeedback" class="reply-modal-box">
        <div class="orig-fb-preview">
          <div style="font-weight: 700; color: #0f172a; margin-bottom: 4px;">
            {{ activeReplyingFeedback.title }}
          </div>
          <div style="font-size: 13px; color: #475569; line-height: 1.6;">
            {{ activeReplyingFeedback.content }}
          </div>
          <div style="margin-top: 8px; font-size: 11px; color: #94a3b8;">
            提交者：{{ activeReplyingFeedback.isAnonymous ? '匿名员工' : activeReplyingFeedback.staffName }} · {{ activeReplyingFeedback.createdAt }}
          </div>
        </div>

        <el-form :model="replyForm" label-width="100px" style="margin-top: 16px;">
          <el-form-item label="处理结论" required>
            <el-select v-model="replyForm.status" style="width: 100%;">
              <el-option label="💡 已采纳建议" value="ACCEPTED" />
              <el-option label="🚀 已落地推进改进" value="IMPLEMENTED" />
              <el-option label="💬 给予解释与说明" value="EXPLAINED" />
              <el-option label="❌ 暂不予采纳" value="REJECTED" />
            </el-select>
          </el-form-item>

          <el-form-item label="官方答复" required>
            <el-input
              v-model="replyForm.replyContent"
              type="textarea"
              :rows="5"
              placeholder="请输入管理方对该意见的评估结果、采纳措施或解释说明，提交后全体员工可见..."
            />
          </el-form-item>
        </el-form>
      </div>

      <template #footer>
        <el-button @click="replyFeedbackDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmReplyFeedback">
          确认发布官方答复
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import {
  useSystemDataStore,
  type RegulationEntity,
  type RegulationSignature,
  type StaffFeedbackEntity
} from '../stores/systemDataStore'
import { useStoreConfig } from '../stores/store'
import { ElMessage, ElMessageBox } from 'element-plus'
import QRCode from 'qrcode'
import {
  getStoreNoticesApi,
  saveStoreNoticeApi,
  deleteStoreNoticeApi
} from '../api'

const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()

// 角色与权限识别
const role = ref(localStorage.getItem('seahorse_role') || 'SUPER_ADMIN')
const currentUsername = ref(localStorage.getItem('seahorse_real_name') || localStorage.getItem('seahorse_user') || localStorage.getItem('seahorse_username') || '店长/管理')
const isMerchantBoss = computed(() => ['SUPER_ADMIN', 'MERCHANT_ADMIN', 'TENANT_ADMIN', 'STORE_OWNER', 'PLATFORM_DEVELOPER'].includes(role.value))
const isStoreManager = computed(() => role.value === 'STORE_MANAGER' || role.value === 'MANAGER')
const isManagerOrBoss = computed(() => isMerchantBoss.value || isStoreManager.value)

// 当前门店与多店铺列表
const selectedStoreId = ref('ALL')
const availableStores = computed(() => {
  return (storeConfig.stores && storeConfig.stores.length > 0) ? storeConfig.stores : (systemData.stores || [])
})
const currentStoreName = computed(() => {
  if (selectedStoreId.value === 'ALL') return '全部门店 (连锁通用)'
  const s = availableStores.value.find(item => item.storeId === selectedStoreId.value)
  return s ? s.storeName : (storeConfig.storeName || '我的智慧门店')
})

// 当前在册员工名单
const currentStoreStaffList = computed(() => {
  if (selectedStoreId.value === 'ALL') return systemData.staff
  return systemData.staff.filter(s => !s.storeId || s.storeId === selectedStoreId.value || s.allowedStoreIds?.includes(selectedStoreId.value))
})
const totalStoreStaffCount = computed(() => currentStoreStaffList.value.length || 1)

// 当前登录员工姓名
const currentStaffName = computed(() => {
  const matched = systemData.staff.find(s => s.realName === currentUsername.value || s.accountUsername === currentUsername.value || s.phone === currentUsername.value)
  return matched ? matched.realName : (currentUsername.value || '当前员工')
})

const currentStaffId = computed(() => {
  const matched = systemData.staff.find(s => s.realName === currentUsername.value || s.accountUsername === currentUsername.value || s.phone === currentUsername.value)
  return matched ? matched.id : 1
})

const todayFormatted = computed(() => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
})

// 选项卡状态
const activeMainTab = ref<'REGULATION_LIST' | 'FEEDBACK_BOX'>('REGULATION_LIST')

// 筛选状态
const selectedCategory = ref('ALL')
const selectedSignFilter = ref('ALL')
const searchKeyword = ref('')

// 现行有效规章制度
const currentStoreRegulations = computed(() => {
  return systemData.regulations.filter(r => {
    if (selectedStoreId.value !== 'ALL' && r.storeId !== 'ALL' && r.storeId !== selectedStoreId.value) {
      return false
    }
    return true
  })
})

const filteredRegulations = computed(() => {
  return currentStoreRegulations.value.filter(r => {
    if (selectedCategory.value !== 'ALL' && r.category !== selectedCategory.value) return false
    if (selectedSignFilter.value === 'NEED_SIGN' && !r.requireSignature) return false
    if (selectedSignFilter.value === 'NO_SIGN' && r.requireSignature) return false
    if (searchKeyword.value.trim()) {
      const kw = searchKeyword.value.trim().toLowerCase()
      const matchTitle = r.title.toLowerCase().includes(kw)
      const matchSummary = r.summary.toLowerCase().includes(kw)
      const matchKp = r.keyPoints.some(kp => kp.toLowerCase().includes(kw))
      if (!matchTitle && !matchSummary && !matchKp) return false
    }
    return true
  })
})

// 核心 KPI 统计
const requireSignatureCount = computed(() => {
  return currentStoreRegulations.value.filter(r => r.requireSignature).length
})

const overallSignatureRate = computed(() => {
  const needSignList = currentStoreRegulations.value.filter(r => r.requireSignature)
  if (needSignList.length === 0) return 0
  let totalSigned = 0
  let totalExpected = needSignList.length * (totalStoreStaffCount.value || 1)
  needSignList.forEach(r => {
    totalSigned += (r.signatures?.length || 0)
  })
  return Math.min(100, Math.round((totalSigned / totalExpected) * 100))
})

const pendingFeedbackCount = computed(() => {
  return systemData.staffFeedbacks.filter(f => f.status === 'PENDING').length
})

const acceptedFeedbackCount = computed(() => {
  return systemData.staffFeedbacks.filter(f => f.status === 'ACCEPTED' || f.status === 'IMPLEMENTED').length
})

// 标签色彩辅助
const getCategoryTagType = (cat: string) => {
  switch (cat) {
    case 'SERVICE': return 'primary'
    case 'ATTENDANCE': return 'warning'
    case 'SAFETY': return 'danger'
    case 'URGENT': return 'danger'
    case 'COMMISSION': return 'success'
    case 'CONFIDENTIAL': return 'info'
    case 'NOTICE': return 'info'
    default: return 'info'
  }
}

const getSignatureProgressColor = (reg: RegulationEntity) => {
  const percent = Math.round(((reg.signatures?.length || 0) / (totalStoreStaffCount.value || 1)) * 100)
  if (percent >= 100) return '#10b981'
  if (percent >= 60) return '#3b82f6'
  return '#f59e0b'
}

// 员工个人签署状态
const isCurrentStaffSigned = (reg: RegulationEntity) => {
  if (!reg.signatures || reg.signatures.length === 0) return false
  return reg.signatures.some(s => String(s.staffId) === String(currentStaffId.value) || s.staffName === currentStaffName.value)
}

const getCurrentStaffSignTime = (reg: RegulationEntity) => {
  const found = reg.signatures?.find(s => String(s.staffId) === String(currentStaffId.value) || s.staffName === currentStaffName.value)
  return found?.signedAt || '已签署'
}

const getStaffSignature = (reg?: RegulationEntity, staffId?: number | string) => {
  if (!reg || !reg.signatures || !staffId) return null
  return reg.signatures.find(s => String(s.staffId) === String(staffId)) || null
}

// 刷新数据
const refreshData = async () => {
  await fetchCloudNotices()
  ElMessage.success('规章制度与签署数据已实时刷新！')
}

// =========================================================================
// 弹窗 1: 制度新建与编辑
// =========================================================================
const editDialogVisible = ref(false)
const isEditing = ref(false)
const editForm = ref<{
  id: string
  title: string
  category: string
  version: string
  effectiveDate: string
  storeId: string
  requireSignature: boolean
  isUrgent: boolean
  playMusic: boolean
  summary: string
  keyPoints: string[]
  content: string
}>({
  id: '',
  title: '',
  category: 'SERVICE',
  version: 'V1.0',
  effectiveDate: todayFormatted.value,
  storeId: 'ALL',
  requireSignature: true,
  isUrgent: false,
  playMusic: false,
  summary: '',
  keyPoints: [''],
  content: ''
})

const handleCategoryChange = (val: string) => {
  if (val === 'URGENT') {
    editForm.value.isUrgent = true
    editForm.value.playMusic = true
  }
}

const handleOpenCreateRegulation = () => {
  isEditing.value = false
  editForm.value = {
    id: `REG-${Date.now().toString().slice(-8)}`,
    title: '',
    category: 'SERVICE',
    version: 'V1.0',
    effectiveDate: todayFormatted.value,
    storeId: selectedStoreId.value || 'ALL',
    requireSignature: true,
    isUrgent: false,
    playMusic: false,
    summary: '',
    keyPoints: ['提前15分钟到岗，保持工装仪容整洁', '严禁在顾客视线内进食或玩手机'],
    content: ''
  }
  editDialogVisible.value = true
}

const handleEditRegulation = (reg: RegulationEntity) => {
  isEditing.value = true
  editForm.value = {
    id: reg.id,
    title: reg.title,
    category: reg.category,
    version: reg.version,
    effectiveDate: reg.effectiveDate,
    storeId: reg.storeId,
    requireSignature: reg.requireSignature,
    isUrgent: (reg as any).isUrgent || false,
    playMusic: (reg as any).playMusic || false,
    summary: reg.summary,
    keyPoints: [...reg.keyPoints],
    content: reg.content
  }
  editDialogVisible.value = true
}

const addKeyPoint = () => {
  editForm.value.keyPoints.push('')
}

const removeKeyPoint = (idx: number) => {
  editForm.value.keyPoints.splice(idx, 1)
}

const handleSaveRegulation = async () => {
  if (!editForm.value.title.trim()) {
    ElMessage.warning('请输入规章制度标题！')
    return
  }
  const catNames: Record<string, string> = {
    SERVICE: '服务礼仪',
    ATTENDANCE: '考勤考纪',
    SAFETY: '安全卫生',
    COMMISSION: '奖惩考核',
    NOTICE: '日常公告',
    URGENT: '特急通知',
    CONFIDENTIAL: '保密协议',
    OTHER: '综合制度'
  }
  const cleanedKp = editForm.value.keyPoints.map(k => k.trim()).filter(Boolean)
  const existing = systemData.regulations.find(r => r.id === editForm.value.id)

  const entity: RegulationEntity = {
    id: editForm.value.id,
    storeId: editForm.value.storeId,
    title: editForm.value.title.trim(),
    category: editForm.value.category as any,
    categoryName: catNames[editForm.value.category] || '综合制度',
    version: editForm.value.version.trim() || 'V1.0',
    effectiveDate: editForm.value.effectiveDate,
    status: 'PUBLISHED',
    requireSignature: editForm.value.requireSignature,
    publisher: currentStaffName.value || '门店管理委员会',
    publishTime: new Date().toLocaleString(),
    summary: editForm.value.summary.trim() || editForm.value.title,
    keyPoints: cleanedKp.length > 0 ? cleanedKp : ['认真阅读并遵守本项管理规定'],
    content: editForm.value.content.trim() || '（规章条款细则已生效，请严格遵照执行）',
    readStaffIds: existing?.readStaffIds || [],
    signatures: existing?.signatures || []
  };
  (entity as any).isUrgent = editForm.value.isUrgent;
  (entity as any).playMusic = editForm.value.playMusic;

  // 1. 同步保存至本地 Pinia
  systemData.saveRegulation(entity)

  // 2. 实时推送并保存至云端数据库，向手机端与全平台发布
  try {
    const cloudNumericId = entity.id.startsWith('CLOUD-')
      ? Number(entity.id.replace('CLOUD-', '')) || undefined
      : undefined
    const savedRes: any = await saveStoreNoticeApi({
      ...(cloudNumericId ? { id: cloudNumericId } : {}),
      storeId: entity.storeId,
      title: entity.title,
      category: entity.category,
      categoryName: catNames[editForm.value.category] || '综合制度',
      summary: entity.summary,
      content: entity.content,
      keyPoints: entity.keyPoints.join(';'),
      version: entity.version,
      effectiveDate: entity.effectiveDate,
      publisher: currentStaffName.value || '门店管理',
      isUrgent: editForm.value.isUrgent,
      playMusic: editForm.value.playMusic,
      requireSignature: entity.requireSignature,
      status: 'PUBLISHED'
    })

    const cloudNotice = savedRes?.data || savedRes
    if (cloudNotice && cloudNotice.id) {
      const nextCloudId = `CLOUD-${cloudNotice.id}`
      if (entity.id !== nextCloudId) {
        const localIdx = systemData.regulations.findIndex(r => r.id === entity.id)
        if (localIdx >= 0) {
          const updatedEntity = { ...systemData.regulations[localIdx], id: nextCloudId }
          systemData.deleteRegulation(entity.id)
          systemData.saveRegulation(updatedEntity)
        }
      }

      // 记录在本地已知集合中，发布人本机无需重复收到右下角弹窗
      try {
        const raw = localStorage.getItem('seahorse_notified_notice_ids')
        const set = raw ? new Set(JSON.parse(raw)) : new Set()
        set.add(String(cloudNotice.id))
        localStorage.setItem('seahorse_notified_notice_ids', JSON.stringify(Array.from(set)))
      } catch (e) {}

      // 派发全局事件，通知本页面及其他同源窗口免刷新更新
      window.dispatchEvent(new CustomEvent('seahorse-notice-updated', { detail: cloudNotice }))
    }

    ElMessage.success(`规章制度/运营规范【${entity.title}】已成功发布，并已实时推送到全店员工APP与在线浏览器！`)
  } catch (e) {
    console.warn('Cloud save notice API warning:', e)
    ElMessage.success(`规章制度【${entity.title}】已在系统生效！`)
  }

  editDialogVisible.value = false
}

const handleDeleteRegulation = async (reg: RegulationEntity) => {
  ElMessageBox.confirm(`确认要废止并删除规章制度【${reg.title}】吗？删除后不可撤销。`, '下架确认', {
    type: 'warning',
    confirmButtonText: '确认删除',
    cancelButtonText: '取消'
  }).then(async () => {
    systemData.deleteRegulation(reg.id)
    if (reg.id.startsWith('CLOUD-')) {
      try {
        const rawId = reg.id.replace('CLOUD-', '')
        await deleteStoreNoticeApi(rawId)
      } catch (e) {}
    }
    ElMessage.success('规章制度已成功下架删除！')
  }).catch(() => {})
}

// 异步从云端拉取门店现行规范与日常公告
const fetchCloudNotices = async () => {
  try {
    const queryStoreId = selectedStoreId.value !== 'ALL'
      ? selectedStoreId.value
      : (storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || availableStores.value[0]?.storeId || 'ALL')
    const res: any = await getStoreNoticesApi(queryStoreId)
    const list: any[] = Array.isArray(res) ? res : (Array.isArray(res?.data) ? res.data : [])
    if (list.length > 0) {
      list.forEach((cn: any) => {
        const cloudId = `CLOUD-${cn.id}`
        const existIdx = systemData.regulations.findIndex(r => r.id === cloudId || r.title === cn.title)
        const existingItem = existIdx >= 0 ? systemData.regulations[existIdx] : null
        const regObj: RegulationEntity = {
          id: cloudId,
          storeId: cn.storeId || 'ALL',
          title: cn.title,
          category: cn.category || 'SERVICE',
          categoryName: cn.categoryName || '规章制度',
          summary: cn.summary || cn.title,
          content: cn.content || '',
          keyPoints: cn.keyPoints ? cn.keyPoints.split(';').map((s: string) => s.trim()).filter(Boolean) : [cn.summary || cn.title],
          version: cn.version || 'V1.0',
          effectiveDate: cn.effectiveDate || todayFormatted.value,
          status: cn.status || 'PUBLISHED',
          requireSignature: !!cn.requireSignature,
          publisher: cn.publisher || '门店管理',
          publishTime: cn.createdAt ? String(cn.createdAt).replace('T', ' ').slice(0, 19) : todayFormatted.value,
          readStaffIds: existingItem?.readStaffIds || [],
          signatures: existingItem?.signatures || []
        };
        (regObj as any).isUrgent = !!cn.isUrgent;
        (regObj as any).playMusic = !!cn.playMusic;

        if (existIdx >= 0) {
          const oldId = systemData.regulations[existIdx].id
          if (oldId !== cloudId) {
            systemData.deleteRegulation(oldId)
          }
          systemData.saveRegulation({ ...existingItem, ...regObj })
        } else {
          systemData.saveRegulation(regObj)
        }
      })
    }
  } catch (e) {
    console.warn('Failed to fetch cloud notices', e)
  }
}

// =========================================================================
// 弹窗 2: 全文查阅
// =========================================================================
const readDialogVisible = ref(false)
const currentViewingReg = ref<RegulationEntity | null>(null)

const handleOpenReadDialog = (reg: RegulationEntity) => {
  currentViewingReg.value = reg
  systemData.markRegulationRead(reg.id, currentStaffId.value)
  readDialogVisible.value = true
}

// =========================================================================
// 弹窗 3: 宣传海报生成器 (Canvas)
// =========================================================================
const posterDialogVisible = ref(false)
const posterTheme = ref<'OCEAN_BLUE' | 'ROYAL_GOLD' | 'CRIMSON_RED'>('OCEAN_BLUE')
const posterCanvasRef = ref<HTMLCanvasElement | null>(null)

const handleOpenPosterGenerator = (reg: RegulationEntity) => {
  currentViewingReg.value = reg
  posterDialogVisible.value = true
  nextTick(() => {
    renderPosterCanvas()
  })
}

const renderPosterCanvas = async () => {
  const canvas = posterCanvasRef.value
  if (!canvas || !currentViewingReg.value) return
  const ctx = canvas.getContext('2d')
  if (!ctx) return

  const reg = currentViewingReg.value
  const width = canvas.width
  const height = canvas.height

  // 1. 背景渐变
  let grad = ctx.createLinearGradient(0, 0, 0, height)
  if (posterTheme.value === 'OCEAN_BLUE') {
    grad.addColorStop(0, '#0284c7')
    grad.addColorStop(0.25, '#0369a1')
    grad.addColorStop(1, '#082f49')
  } else if (posterTheme.value === 'ROYAL_GOLD') {
    grad.addColorStop(0, '#d97706')
    grad.addColorStop(0.25, '#b45309')
    grad.addColorStop(1, '#451a03')
  } else {
    grad.addColorStop(0, '#dc2626')
    grad.addColorStop(0.25, '#991b1b')
    grad.addColorStop(1, '#450a0a')
  }
  ctx.fillStyle = grad
  ctx.fillRect(0, 0, width, height)

  // 装饰性光晕底纹
  ctx.save()
  ctx.fillStyle = 'rgba(255, 255, 255, 0.04)'
  ctx.beginPath()
  ctx.arc(width * 0.9, height * 0.1, 200, 0, Math.PI * 2)
  ctx.fill()
  ctx.restore()

  // 2. 顶部品牌条
  ctx.fillStyle = 'rgba(255, 255, 255, 0.9)'
  ctx.font = 'bold 18px sans-serif'
  ctx.textAlign = 'left'
  ctx.fillText('🌊 海马智慧门店 · 运营合规管理公报', 40, 55)

  ctx.fillStyle = 'rgba(255, 255, 255, 0.65)'
  ctx.font = '13px sans-serif'
  ctx.textAlign = 'right'
  ctx.fillText(`发布门店：${currentStoreName.value}`, width - 40, 55)

  // 白色分割线
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.25)'
  ctx.lineWidth = 1
  ctx.beginPath()
  ctx.moveTo(40, 75)
  ctx.lineTo(width - 40, 75)
  ctx.stroke()

  // 3. 标签与版本徽章
  ctx.fillStyle = '#ffffff'
  ctx.beginPath()
  ctx.roundRect(40, 95, 80, 26, 4)
  ctx.fill()
  ctx.fillStyle = '#0f172a'
  ctx.font = 'bold 12px sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText(reg.categoryName, 80, 112)

  ctx.fillStyle = 'rgba(255, 255, 255, 0.2)'
  ctx.beginPath()
  ctx.roundRect(130, 95, 60, 26, 4)
  ctx.fill()
  ctx.fillStyle = '#ffffff'
  ctx.font = 'bold 12px sans-serif'
  ctx.fillText(reg.version, 160, 112)

  if (reg.requireSignature) {
    ctx.fillStyle = '#ef4444'
    ctx.beginPath()
    ctx.roundRect(200, 95, 120, 26, 4)
    ctx.fill()
    ctx.fillStyle = '#ffffff'
    ctx.font = 'bold 11px sans-serif'
    ctx.fillText('✍️ 需员工手写签字', 260, 112)
  }

  // 4. 制度主标题 (自动折行绘制)
  ctx.fillStyle = '#ffffff'
  ctx.font = 'bold 26px sans-serif'
  ctx.textAlign = 'left'
  let curY = 165
  const maxWidth = width - 80
  const words = reg.title
  let line = ''
  for (let n = 0; n < words.length; n++) {
    const testLine = line + words[n]
    const metrics = ctx.measureText(testLine)
    if (metrics.width > maxWidth && n > 0) {
      ctx.fillText(line, 40, curY)
      line = words[n]
      curY += 36
    } else {
      line = testLine
    }
  }
  ctx.fillText(line, 40, curY)
  curY += 24

  // 副标题/摘要
  ctx.fillStyle = 'rgba(255, 255, 255, 0.8)'
  ctx.font = 'italic 14px sans-serif'
  ctx.fillText(`“${reg.summary}”`, 40, curY)
  curY += 35

  // 5. 核心红线条款白底卡片容器
  const cardY = curY
  const cardHeight = 360
  ctx.fillStyle = '#ffffff'
  ctx.beginPath()
  ctx.roundRect(40, cardY, maxWidth, cardHeight, 12)
  ctx.fill()

  // 卡片标题
  ctx.fillStyle = '#0f172a'
  ctx.font = 'bold 17px sans-serif'
  ctx.fillText('📌 门店合规重点要求与红线速览', 60, cardY + 40)

  // 红线列表
  let itemY = cardY + 78
  reg.keyPoints.slice(0, 5).forEach((kp, idx) => {
    // 序号圆圈
    ctx.fillStyle = posterTheme.value === 'OCEAN_BLUE' ? '#0284c7' : (posterTheme.value === 'ROYAL_GOLD' ? '#d97706' : '#dc2626')
    ctx.beginPath()
    ctx.arc(70, itemY - 5, 11, 0, Math.PI * 2)
    ctx.fill()

    ctx.fillStyle = '#ffffff'
    ctx.font = 'bold 11px sans-serif'
    ctx.textAlign = 'center'
    ctx.fillText(String(idx + 1), 70, itemY - 1)

    // 文字描述
    ctx.fillStyle = '#1e293b'
    ctx.font = '500 14px sans-serif'
    ctx.textAlign = 'left'
    // 若文字过长截断并换行
    if (kp.length > 24) {
      ctx.fillText(kp.substring(0, 24), 92, itemY - 2)
      ctx.fillText(kp.substring(24), 92, itemY + 18)
      itemY += 56
    } else {
      ctx.fillText(kp, 92, itemY)
      itemY += 46
    }
  })

  // 6. 底部二维码与落款区
  const bottomY = cardY + cardHeight + 35

  // 生成真实可用二维码
  try {
    const basePrefix = (import.meta.env.BASE_URL || '/').replace(/\/$/, '')
    const qrUrl = `${window.location.origin}${basePrefix}/regulations?id=${encodeURIComponent(reg.id)}`
    const qrDataUrl = await QRCode.toDataURL(qrUrl, { margin: 1, width: 110 })
    const img = new Image()
    img.src = qrDataUrl
    await new Promise((resolve) => { img.onload = resolve })

    // 绘制白底圆角背景
    ctx.fillStyle = '#ffffff'
    ctx.beginPath()
    ctx.roundRect(40, bottomY, 120, 120, 8)
    ctx.fill()
    ctx.drawImage(img, 45, bottomY + 5, 110, 110)
  } catch (e) {
    console.error('QR code generation error:', e)
  }

  // 二维码右侧文字说明
  ctx.fillStyle = '#ffffff'
  ctx.font = 'bold 15px sans-serif'
  ctx.textAlign = 'left'
  ctx.fillText('📱 员工手机端扫码随时查阅', 180, bottomY + 30)

  ctx.fillStyle = 'rgba(255, 255, 255, 0.75)'
  ctx.font = '12px sans-serif'
  ctx.fillText('手机微信扫码直达移动端，支持随时复习要点与完成电子签署', 180, bottomY + 54)
  ctx.fillText(`发布部门：${reg.publisher}`, 180, bottomY + 80)
  ctx.fillText(`生效日期：${reg.effectiveDate} · 长期执行`, 180, bottomY + 102)

  // 7. 盖上醒目红色管理公章
  ctx.save()
  ctx.translate(width - 120, bottomY + 60)
  ctx.rotate(-15 * Math.PI / 180)
  ctx.strokeStyle = '#ef4444'
  ctx.lineWidth = 3
  ctx.beginPath()
  ctx.arc(0, 0, 48, 0, Math.PI * 2)
  ctx.stroke()

  ctx.fillStyle = '#ef4444'
  ctx.font = 'bold 11px sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText('海马智慧连锁', 0, -20)
  ctx.font = '16px sans-serif'
  ctx.fillText('★', 0, 0)
  ctx.font = 'bold 11px sans-serif'
  ctx.fillText('合规执行章', 0, 22)
  ctx.restore()
}

const downloadPosterImage = () => {
  const canvas = posterCanvasRef.value
  if (!canvas || !currentViewingReg.value) return
  const dataUrl = canvas.toDataURL('image/png')
  const link = document.createElement('a')
  link.download = `门店制度海报_${currentViewingReg.value.title}.png`
  link.href = dataUrl
  link.click()
  ElMessage.success('规章制度高清海报图片已成功下载！')
}

// =========================================================================
// 弹窗 4: 红头公文与 PDF 打印
// =========================================================================
const pdfDialogVisible = ref(false)

const handleOpenPdfExport = (reg: RegulationEntity) => {
  currentViewingReg.value = reg
  pdfDialogVisible.value = true
}

const triggerBrowserPrint = () => {
  window.print()
}

const handleCopyNoticeText = (reg?: RegulationEntity | null) => {
  if (!reg) return
  const basePrefix = (import.meta.env.BASE_URL || '/').replace(/\/$/, '')
  const kps = reg.keyPoints.map((k, i) => `${i + 1}. ${k}`).join('\n')
  const text = `【📢 ${currentStoreName.value} · 规章制度贯彻通知】
------------------------------------------
各位伙伴，门店正式发布印发《${reg.title}》（版本：${reg.version}，生效日：${reg.effectiveDate}）。
核心管理要求与红线要点如下：
${kps}

${reg.requireSignature ? '⚠️【特别提醒】：本制度要求全员完成在线手写电子签名，请大家在入职/今日下班前登录海马工作台完成签字确认备查。' : ''}
制度详情与签署入口：${window.location.origin}${basePrefix}/regulations
请大家严格遵照执行，树立专业标准服务形象！`

  navigator.clipboard.writeText(text).then(() => {
    ElMessage.success('群发公告文案已复制至剪贴板，可直接粘贴发至微信/企业微信/钉钉群！')
  }).catch(() => {
    ElMessage.info('请手动复制文本内容')
  })
}

// =========================================================================
// 弹窗 5: 员工在线手写电子签名 (Canvas Pad)
// =========================================================================
const signModalVisible = ref(false)
const currentSigningReg = ref<RegulationEntity | null>(null)
const signCanvasRef = ref<HTMLCanvasElement | null>(null)
const isDrawing = ref(false)
const hasSignatureDrawn = ref(false)
const signAgreed = ref(false)

const handleOpenSignModal = (reg: RegulationEntity) => {
  currentSigningReg.value = reg
  signModalVisible.value = true
  signAgreed.value = false
  hasSignatureDrawn.value = false
  nextTick(() => {
    clearSignaturePad()
  })
}

const clearSignaturePad = () => {
  const canvas = signCanvasRef.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  if (!ctx) return
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  hasSignatureDrawn.value = false
}

const getCanvasScaledPoint = (canvas: HTMLCanvasElement, clientX: number, clientY: number) => {
  const rect = canvas.getBoundingClientRect()
  const scaleX = rect.width ? canvas.width / rect.width : 1
  const scaleY = rect.height ? canvas.height / rect.height : 1
  return {
    x: (clientX - rect.left) * scaleX,
    y: (clientY - rect.top) * scaleY
  }
}

const startDrawing = (e: MouseEvent) => {
  const canvas = signCanvasRef.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  if (!ctx) return
  const pt = getCanvasScaledPoint(canvas, e.clientX, e.clientY)
  isDrawing.value = true
  hasSignatureDrawn.value = true
  ctx.beginPath()
  ctx.moveTo(pt.x, pt.y)
  ctx.strokeStyle = '#0f172a'
  ctx.lineWidth = 3
  ctx.lineCap = 'round'
  ctx.lineJoin = 'round'
}

const draw = (e: MouseEvent) => {
  if (!isDrawing.value) return
  const canvas = signCanvasRef.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  if (!ctx) return
  const pt = getCanvasScaledPoint(canvas, e.clientX, e.clientY)
  ctx.lineTo(pt.x, pt.y)
  ctx.stroke()
}

const stopDrawing = () => {
  isDrawing.value = false
}

const startTouchDrawing = (e: TouchEvent) => {
  if (e.touches.length === 0) return
  const canvas = signCanvasRef.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  if (!ctx) return
  const touch = e.touches[0]
  const pt = getCanvasScaledPoint(canvas, touch.clientX, touch.clientY)
  isDrawing.value = true
  hasSignatureDrawn.value = true
  ctx.beginPath()
  ctx.moveTo(pt.x, pt.y)
  ctx.strokeStyle = '#0f172a'
  ctx.lineWidth = 3
  ctx.lineCap = 'round'
  ctx.lineJoin = 'round'
}

const touchDraw = (e: TouchEvent) => {
  if (!isDrawing.value || e.touches.length === 0) return
  const canvas = signCanvasRef.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  if (!ctx) return
  const touch = e.touches[0]
  const pt = getCanvasScaledPoint(canvas, touch.clientX, touch.clientY)
  ctx.lineTo(pt.x, pt.y)
  ctx.stroke()
}

const submitSignature = () => {
  if (!signAgreed.value) {
    ElMessage.warning('请先勾选确认同意规章制度条款！')
    return
  }
  const canvas = signCanvasRef.value
  if (!canvas || !currentSigningReg.value) return
  const signatureDataUrl = canvas.toDataURL('image/png')

  const signature: RegulationSignature = {
    staffId: currentStaffId.value,
    staffName: currentStaffName.value,
    signatureDataUrl,
    signedAt: new Date().toLocaleString(),
    deviceInfo: 'PC端智慧工作台 Chrome'
  }

  systemData.signRegulation(currentSigningReg.value.id, signature)
  ElMessage.success(`恭喜！您已成功签署规章制度【${currentSigningReg.value.title}】，签名凭据已归档！`)
  signModalVisible.value = false
}

// =========================================================================
// 弹窗 6: 全员签署看板 (Manager Only)
// =========================================================================
const signatureBoardVisible = ref(false)

const handleOpenSignatureBoard = (reg: RegulationEntity) => {
  currentViewingReg.value = reg
  signatureBoardVisible.value = true
}

const handleCopyReminderText = (reg: RegulationEntity) => {
  const signedIds = (reg.signatures || []).map(s => String(s.staffId))
  const unsignedStaff = currentStoreStaffList.value.filter(s => !signedIds.includes(String(s.id)))
  const unsignedNames = unsignedStaff.map(s => `@${s.realName}`).join(' ')

  const text = `【📢 催缴签署提醒：${reg.title}】
各位伙伴，截止目前以下员工尚未完成在线电子签名确认：
${unsignedNames || '（全员已签署，感谢配合）'}

请上述伙伴在今日打烊前登录系统完成手写签名，谢谢配合！`

  navigator.clipboard.writeText(text).then(() => {
    ElMessage.success('催缴签署名单与文案已复制至剪贴板！')
  }).catch(() => {
    ElMessage.info('文案复制失败')
  })
}

// =========================================================================
// 弹窗 7 & 8: 员工意见与建议箱模块
// =========================================================================
const feedbackScopeFilter = ref<'ALL' | 'MY'>('ALL')
const feedbackStatusFilter = ref('ALL')
const feedbackTypeFilter = ref('ALL')
const feedbackKeyword = ref('')

const myFeedbackCount = computed(() => {
  return systemData.staffFeedbacks.filter(f => {
    return String(f.staffId) === String(currentStaffId.value) || f.staffName === currentStaffName.value
  }).length
})

const filteredFeedbacks = computed(() => {
  return systemData.staffFeedbacks.filter(f => {
    if (feedbackScopeFilter.value === 'MY') {
      const isMine = String(f.staffId) === String(currentStaffId.value) || f.staffName === currentStaffName.value
      if (!isMine) return false
    }
    if (feedbackStatusFilter.value !== 'ALL' && f.status !== feedbackStatusFilter.value) return false
    if (feedbackTypeFilter.value !== 'ALL' && f.type !== feedbackTypeFilter.value) return false
    if (feedbackKeyword.value.trim()) {
      const kw = feedbackKeyword.value.trim().toLowerCase()
      const matchTitle = f.title.toLowerCase().includes(kw)
      const matchContent = f.content.toLowerCase().includes(kw)
      if (!matchTitle && !matchContent) return false
    }
    return true
  })
})

const getFeedbackTypeTag = (type: string) => {
  switch (type) {
    case 'SUGGESTION': return 'primary'
    case 'DIFFICULTY': return 'warning'
    case 'INNOVATION': return 'success'
    case 'APPEAL': return 'danger'
    default: return 'info'
  }
}

const getFeedbackStatusTag = (status: string) => {
  switch (status) {
    case 'PENDING': return 'warning'
    case 'ACCEPTED': return 'primary'
    case 'IMPLEMENTED': return 'success'
    case 'EXPLAINED': return 'info'
    case 'REJECTED': return 'danger'
    default: return 'info'
  }
}

const getFeedbackStatusLabel = (status: string) => {
  switch (status) {
    case 'PENDING': return '⏳ 待管理评审'
    case 'ACCEPTED': return '💡 已采纳建议'
    case 'IMPLEMENTED': return '🚀 已落地改进'
    case 'EXPLAINED': return '💬 解释说明'
    case 'REJECTED': return '暂不采纳'
    default: return status
  }
}

const feedbackDialogVisible = ref(false)
const feedbackForm = ref<{
  regulationId: string
  regulationTitle: string
  type: 'SUGGESTION' | 'DIFFICULTY' | 'INNOVATION' | 'APPEAL'
  priority: 'NORMAL' | 'URGENT'
  isAnonymous: boolean
  title: string
  content: string
}>({
  regulationId: '',
  regulationTitle: '',
  type: 'SUGGESTION',
  priority: 'NORMAL',
  isAnonymous: false,
  title: '',
  content: ''
})

const handleOpenSubmitFeedback = (reg?: RegulationEntity | null) => {
  feedbackForm.value = {
    regulationId: reg ? reg.id : '',
    regulationTitle: reg ? reg.title : '',
    type: 'SUGGESTION',
    priority: 'NORMAL',
    isAnonymous: false,
    title: '',
    content: ''
  }
  feedbackDialogVisible.value = true
}

const handleSelectFeedbackReg = (val: string) => {
  const match = systemData.regulations.find(r => r.id === val)
  feedbackForm.value.regulationTitle = match ? match.title : ''
}

const handleConfirmSubmitFeedback = () => {
  if (!feedbackForm.value.title.trim()) {
    ElMessage.warning('请输入建议标题！')
    return
  }
  if (!feedbackForm.value.content.trim()) {
    ElMessage.warning('请输入建议详细内容！')
    return
  }

  const typeNames: Record<string, string> = {
    SUGGESTION: '改进建议',
    DIFFICULTY: '执行困难',
    INNOVATION: '合理化创新',
    APPEAL: '申诉反馈'
  }

  const fb: StaffFeedbackEntity = {
    id: `FB-${Date.now().toString().slice(-8)}`,
    storeId: selectedStoreId.value !== 'ALL' ? selectedStoreId.value : (storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || 'S001'),
    regulationId: feedbackForm.value.regulationId || undefined,
    regulationTitle: feedbackForm.value.regulationTitle || undefined,
    staffId: feedbackForm.value.isAnonymous ? undefined : currentStaffId.value,
    staffName: feedbackForm.value.isAnonymous ? '匿名员工' : currentStaffName.value,
    isAnonymous: feedbackForm.value.isAnonymous,
    type: feedbackForm.value.type,
    typeName: typeNames[feedbackForm.value.type] || '改进建议',
    priority: feedbackForm.value.priority,
    title: feedbackForm.value.title.trim(),
    content: feedbackForm.value.content.trim(),
    createdAt: new Date().toLocaleString(),
    status: 'PENDING'
  }

  systemData.submitStaffFeedback(fb)
  ElMessage.success(feedbackForm.value.isAnonymous ? '匿名建议已成功提交至店长意见箱，感谢您的宝贵发声！' : '您的建议已提交，管理团队将尽快评阅与答复！')
  feedbackDialogVisible.value = false
  activeMainTab.value = 'FEEDBACK_BOX'
}

// 官方答复弹窗
const replyFeedbackDialogVisible = ref(false)
const activeReplyingFeedback = ref<StaffFeedbackEntity | null>(null)
const replyForm = ref<{
  status: StaffFeedbackEntity['status']
  replyContent: string
}>({
  status: 'ACCEPTED',
  replyContent: ''
})

const handleOpenReplyFeedback = (fb: StaffFeedbackEntity) => {
  activeReplyingFeedback.value = fb
  replyForm.value = {
    status: fb.status === 'PENDING' ? 'ACCEPTED' : fb.status,
    replyContent: fb.replyContent || ''
  }
  replyFeedbackDialogVisible.value = true
}

const handleConfirmReplyFeedback = () => {
  if (!activeReplyingFeedback.value) return
  if (!replyForm.value.replyContent.trim()) {
    ElMessage.warning('请输入官方答复内容！')
    return
  }
  systemData.replyStaffFeedback(
    activeReplyingFeedback.value.id,
    replyForm.value.status,
    replyForm.value.replyContent.trim(),
    currentStaffName.value || '门店管理团队'
  )
  ElMessage.success('官方答复已公示，全体员工均可查阅处理结论！')
  replyFeedbackDialogVisible.value = false
}

const handleRemoteNoticeUpdated = (e: any) => {
  const notice = e.detail
  if (!notice) return
  // 如果新发布的规章制度适用于当前选中的门店或全店，立即静默重载，无需用户点击刷新按钮
  if (notice.storeId === 'ALL' || selectedStoreId.value === 'ALL' || notice.storeId === selectedStoreId.value) {
    fetchCloudNotices()
  }
}

onMounted(async () => {
  await fetchCloudNotices()
  window.addEventListener('seahorse-notice-updated', handleRemoteNoticeUpdated)
  // 如果链接带有特定制度ID参数，直接打开详情
  const params = new URLSearchParams(window.location.search)
  const regId = params.get('id')
  if (regId) {
    const match = systemData.regulations.find(r => r.id === regId)
    if (match) {
      handleOpenReadDialog(match)
    }
  }
})

onUnmounted(() => {
  window.removeEventListener('seahorse-notice-updated', handleRemoteNoticeUpdated)
})
</script>

<style scoped>
.store-regulations-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* 顶部标题卡片 */
.page-header-card {
  background: #fff;
  border-radius: 8px;
  padding: 16px 20px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.header-main-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.header-left {
  flex: 1 1 380px;
  min-width: 320px;
}

.title-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.page-title {
  margin: 0;
  font-size: 20px;
  font-weight: bold;
  color: #0f172a;
  white-space: nowrap;
}

.page-subtitle {
  margin: 8px 0 0 0;
  font-size: 13px;
  color: #64748b;
  line-height: 1.5;
}

.header-right {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
  justify-content: flex-end;
}

/* 核心运行指标卡片矩阵 */
.stats-overview-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
}

@media (max-width: 1200px) {
  .stats-overview-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 768px) {
  .stats-overview-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.stat-card {
  background: #fff;
  border-radius: 8px;
  padding: 14px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
  border: 1px solid #f1f5f9;
}

.stat-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-label {
  font-size: 12px;
  color: #64748b;
}

.stat-value {
  font-size: 22px;
  font-weight: 700;
  color: #0f172a;
}

.stat-icon {
  font-size: 28px;
  opacity: 0.85;
}

.icon-blue { color: #0284c7; }
.icon-orange { color: #f59e0b; }
.icon-green { color: #10b981; }
.icon-purple { color: #8b5cf6; }
.icon-emerald { color: #059669; }

.text-blue { color: #0284c7; }
.text-orange { color: #f59e0b; }
.text-green { color: #10b981; }
.text-purple { color: #8b5cf6; }
.text-emerald { color: #059669; }

/* 内容卡片 */
.content-card {
  border-radius: 8px;
  border: none;
}

.custom-nav-tabs :deep(.el-tabs__item) {
  font-size: 15px;
  font-weight: 600;
}

.tab-badge {
  margin-left: 6px;
}

/* 过滤工具栏 */
.filter-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  padding-bottom: 16px;
  border-bottom: 1px dashed #f1f5f9;
  margin-bottom: 16px;
}

.filter-left {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.filter-right {
  display: flex;
  align-items: center;
  margin-left: auto;
}

.filter-stats {
  font-size: 13px;
  color: #64748b;
}

.filter-stats strong {
  color: #0284c7;
  font-size: 15px;
}

/* 规章制度卡片网格 */
.regulation-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
  gap: 16px;
}

.regulation-card {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 18px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
  transition: all 0.25s ease;
}

.regulation-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(0,0,0,0.08);
  border-color: #cbd5e1;
}

.require-sign-card {
  border-left: 4px solid #f97316;
}

.card-top-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.header-tags {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.effective-date {
  font-size: 11.5px;
  color: #94a3b8;
}

.reg-title {
  margin: 0 0 6px 0;
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
  cursor: pointer;
  line-height: 1.4;
  transition: color 0.2s;
}

.reg-title:hover {
  color: #0284c7;
}

.reg-summary {
  margin: 0 0 12px 0;
  font-size: 13px;
  color: #475569;
  line-height: 1.5;
  background: #f8fafc;
  padding: 8px 12px;
  border-radius: 6px;
}

.keypoints-box {
  background: #fdfdfd;
  border: 1px dashed #e2e8f0;
  border-radius: 6px;
  padding: 10px 12px;
  margin-bottom: 12px;
}

.keypoints-header {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 600;
  color: #334155;
  margin-bottom: 6px;
}

.kp-list {
  margin: 0;
  padding-left: 18px;
  font-size: 12px;
  color: #64748b;
  line-height: 1.6;
}

.reg-progress-section {
  padding-top: 8px;
  margin-bottom: 12px;
  border-top: 1px solid #f1f5f9;
}

.progress-bar-row {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #475569;
  margin-bottom: 6px;
}

.progress-bar-row strong {
  color: #0284c7;
}

.progress-percent {
  font-weight: 700;
  color: #0f172a;
}

.no-sign-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #64748b;
}

.my-status-box {
  margin-top: 8px;
}

.card-footer-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: 10px;
  border-top: 1px solid #f1f5f9;
}

.left-actions, .right-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* 员工建议箱样式 */
.feedback-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.feedback-card {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 16px 20px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.03);
}

.fb-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
}

.fb-user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.fb-author-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.fb-author-name {
  font-weight: 700;
  color: #0f172a;
  font-size: 14px;
}

.fb-time-row {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 2px;
  display: flex;
  gap: 12px;
}

.fb-target-reg {
  color: #0284c7;
}

.fb-title {
  margin: 0 0 8px 0;
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
}

.fb-content {
  font-size: 13.5px;
  color: #475569;
  line-height: 1.6;
  margin-bottom: 12px;
}

.fb-official-reply {
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 6px;
  padding: 12px 14px;
  margin-bottom: 12px;
}

.reply-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.reply-badge {
  font-size: 12px;
  font-weight: 700;
  color: #166534;
}

.reply-meta {
  font-size: 11.5px;
  color: #65a30d;
}

.reply-text {
  font-size: 13px;
  color: #14532d;
  line-height: 1.5;
}

.fb-actions-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 8px;
  border-top: 1px dashed #f1f5f9;
}

.fb-id-tag {
  font-size: 11.5px;
  color: #94a3b8;
  font-family: monospace;
}

/* 动态核心要点编辑 */
.dynamic-keypoints-editor {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
}

.kp-edit-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* 查阅弹窗样式 */
.read-meta-box {
  display: flex;
  align-items: center;
  gap: 20px;
  flex-wrap: wrap;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 12px;
  font-size: 13px;
  color: #475569;
}

.read-summary-quote {
  background: #f8fafc;
  padding: 10px 14px;
  border-radius: 6px;
  font-size: 13px;
  color: #334155;
  margin-bottom: 14px;
}

.read-keypoints-card {
  background: #fffbeb;
  border: 1px solid #fef3c7;
  border-radius: 6px;
  padding: 12px 16px;
  margin-bottom: 16px;
}

.rkp-title {
  font-weight: 700;
  color: #b45309;
  font-size: 13px;
  margin-bottom: 6px;
}

.rkp-ol {
  margin: 0;
  padding-left: 20px;
  font-size: 13px;
  color: #78350f;
  line-height: 1.6;
}

.read-body-box {
  background: #fdfdfd;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 16px;
  max-height: 380px;
  overflow-y: auto;
}

.formatted-pre {
  margin: 0;
  font-family: inherit;
  font-size: 13px;
  color: #1e293b;
  line-height: 1.7;
  white-space: pre-wrap;
}

.sign-callout-box {
  margin-top: 16px;
  padding: 12px 16px;
  border-radius: 6px;
}

.sign-needed {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #fef2f2;
  border: 1px solid #fecaca;
  padding: 12px 16px;
  border-radius: 6px;
}

.signed-done {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  padding: 12px 16px;
  border-radius: 6px;
}

.done-icon {
  font-size: 24px;
  color: #16a34a;
}

/* 海报模态框 */
.poster-modal-body {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
}

.poster-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.poster-canvas-wrapper {
  background: #334155;
  padding: 16px;
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.15);
  display: flex;
  justify-content: center;
}

.poster-canvas {
  max-width: 100%;
  height: auto;
  border-radius: 6px;
}

.poster-hint {
  font-size: 12px;
  color: #64748b;
  margin: 0;
  text-align: center;
}

/* 红头公文排版样式 */
.pdf-actions-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 16px;
}

.printable-doc-sheet {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  padding: 40px 48px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
  color: #0f172a;
}

.doc-header-red {
  text-align: center;
  border-bottom: 2px solid #dc2626;
  padding-bottom: 10px;
  margin-bottom: 20px;
}

.doc-corp-title {
  font-size: 22px;
  font-weight: 900;
  color: #dc2626;
  letter-spacing: 2px;
  margin-bottom: 8px;
}

.doc-serial-row {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  color: #334155;
  margin-bottom: 6px;
}

.doc-red-divider {
  position: relative;
  text-align: center;
  height: 12px;
}

.red-star {
  color: #dc2626;
  font-size: 16px;
  background: #ffffff;
  padding: 0 6px;
  position: absolute;
  top: -10px;
  left: 50%;
  transform: translateX(-50%);
}

.doc-subject-title {
  text-align: center;
  font-size: 20px;
  font-weight: bold;
  color: #0f172a;
  margin: 18px 0;
  line-height: 1.4;
}

.doc-meta-info {
  display: flex;
  justify-content: space-around;
  font-size: 12px;
  color: #64748b;
  padding-bottom: 12px;
  border-bottom: 1px dashed #e2e8f0;
  margin-bottom: 16px;
}

.doc-greeting {
  font-weight: 700;
  font-size: 14px;
  margin-bottom: 10px;
}

.doc-intro-p {
  font-size: 13.5px;
  line-height: 1.8;
  text-indent: 2em;
  margin-bottom: 14px;
}

.doc-sub-block {
  margin-bottom: 16px;
}

.doc-block-title {
  font-weight: 700;
  font-size: 14px;
  color: #1e293b;
  margin-bottom: 8px;
}

.doc-ol {
  margin: 0;
  padding-left: 28px;
  font-size: 13px;
  line-height: 1.8;
}

.doc-pre {
  font-family: inherit;
  font-size: 13px;
  line-height: 1.8;
  white-space: pre-wrap;
  background: #f8fafc;
  padding: 12px 16px;
  border-radius: 4px;
}

.doc-receipt-box {
  margin-top: 24px;
  border-top: 1px solid #0f172a;
  padding-top: 14px;
}

.receipt-title {
  font-weight: 700;
  font-size: 13px;
  margin-bottom: 10px;
}

.receipt-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.receipt-table th, .receipt-table td {
  border: 1px solid #cbd5e1;
  padding: 6px 10px;
  text-align: center;
}

.receipt-table th {
  background: #f1f5f9;
  font-weight: 600;
}

.doc-footer-seal-box {
  margin-top: 36px;
  display: flex;
  justify-content: flex-end;
  position: relative;
}

.doc-seal-wrap {
  position: absolute;
  right: 60px;
  top: -24px;
  pointer-events: none;
}

.official-red-seal {
  width: 100px;
  height: 100px;
  border: 2px solid #ef4444;
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #ef4444;
  transform: rotate(-12deg);
  opacity: 0.85;
}

.seal-star {
  font-size: 16px;
  line-height: 1;
}

.seal-text-top {
  font-size: 9px;
  font-weight: bold;
}

.seal-text-bottom {
  font-size: 9px;
  font-weight: bold;
  margin-top: 2px;
}

.doc-signer-info {
  text-align: right;
  font-size: 13px;
  line-height: 1.8;
  color: #334155;
  z-index: 1;
}

/* 打印机媒体查询 */
@media print {
  body * {
    visibility: hidden;
  }
  #printable-document-container, #printable-document-container * {
    visibility: visible;
  }
  #printable-document-container {
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    border: none;
    box-shadow: none;
    padding: 0;
  }
}

/* 手写电子签名板样式 */
.sign-modal-container {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.sign-reg-info {
  background: #f8fafc;
  padding: 10px 14px;
  border-radius: 6px;
  font-size: 13px;
  color: #334155;
}

.signer-meta {
  display: flex;
  gap: 16px;
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
}

.canvas-box {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.canvas-header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.canvas-hint {
  font-size: 12px;
  font-weight: 600;
  color: #475569;
}

.canvas-border {
  position: relative;
  background: #ffffff;
  border: 2px dashed #94a3b8;
  border-radius: 8px;
  overflow: hidden;
}

.sign-canvas {
  width: 100%;
  height: 200px;
  cursor: crosshair;
  touch-action: none;
}

.canvas-watermark {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 20px;
  color: #cbd5e1;
  pointer-events: none;
  font-weight: bold;
}

.sign-agreement-box {
  background: #f1f5f9;
  padding: 10px 12px;
  border-radius: 6px;
}

/* 签署看板 */
.board-kpi-bar {
  display: flex;
  align-items: center;
  gap: 24px;
  background: #f8fafc;
  padding: 14px 18px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.kpi-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.kpi-item .lbl {
  font-size: 12px;
  color: #64748b;
}

.kpi-item .val {
  font-size: 20px;
  font-weight: 700;
  color: #0f172a;
}

.board-action-right {
  margin-left: auto;
}

.orig-fb-preview {
  background: #f8fafc;
  border-left: 4px solid #0284c7;
  padding: 12px 14px;
  border-radius: 0 6px 6px 0;
}

.empty-state {
  padding: 40px 0;
}

.feedback-public-notice {
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 16px;
}

.feedback-public-notice .notice-text {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  color: #166534;
  font-size: 13px;
  line-height: 1.6;
}

.feedback-public-notice .notice-icon {
  font-size: 18px;
  color: #15803d;
  flex-shrink: 0;
  margin-top: 2px;
}
</style>
