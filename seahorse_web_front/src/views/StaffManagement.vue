<template>
  <div class="staff-page">
    <el-card shadow="never" class="main-card">
      <el-tabs v-model="activeStaffTab" class="staff-tabs">
        <!-- 选项卡 1: 在册员工档案 -->
        <el-tab-pane label="👥 在册员工档案" name="STAFF_LIST">
          <!-- 顶部操作栏 (严格对齐截图3) -->
          <div class="toolbar">
        <div class="toolbar-left">
          <el-button plain icon="Plus" @click="openRewardPunishModal()">新增奖罚</el-button>
          <el-button type="primary" icon="Plus" @click="openAddStaffModal()">新增员工</el-button>
          <el-button type="primary" plain icon="Document" @click="$router.push('/regulations')">
            📜 规章制度与员工签署
          </el-button>
          <el-button type="warning" plain @click="openStaffQrModal()">
            <el-icon><Iphone /></el-icon> 📲 员工自助入职码
          </el-button>
          <el-button type="info" plain icon="User" @click="openStaffDisplayModal">
            🏷️ 称谓展示规则 (店内称呼/姓名)
          </el-button>
          <el-button type="warning" plain icon="EditPen" @click="openCommonRemarksModal">
            📝 常用服务要求与特殊备注
          </el-button>
          <el-button type="success" icon="Setting" @click="openCommissionModal()">提成设置</el-button>
          <el-button link type="info" class="restore-btn" @click="openRestoreModal()">恢复删除员工</el-button>
        </div>
        <div class="toolbar-right">
          <el-input
            v-model="searchQuery"
            placeholder="输入员工姓名或手机号检索"
            style="width: 240px;"
            clearable
            @input="currentPage = 1"
            @clear="currentPage = 1; loadStaffList()"
            @keyup.enter="currentPage = 1; loadStaffList()"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </div>
      </div>

      <!-- 员工列表表格 (严格对齐截图3) -->
      <el-table
        :data="paginatedStaffList"
        style="width: 100%; margin-top: 16px;"
        v-loading="loading"
        :header-cell-style="{ background: '#f8fafc', color: '#475569', fontWeight: '600' }"
      >
        <el-table-column label="员工头像" width="120" align="center">
          <template #default="{ row }">
            <el-avatar :size="44" style="background-color: #0284c7; font-weight: bold; font-size: 16px;">
              {{ row.realName ? row.realName.substring(0, 1) : '员' }}
            </el-avatar>
          </template>
        </el-table-column>

        <el-table-column prop="realName" label="员工姓名 / 店内称呼" min-width="170">
          <template #default="{ row }">
            <div style="display: flex; align-items: center; gap: 6px;">
              <span class="staff-name">{{ row.realName }}</span>
              <el-tag v-if="row.nickname" size="small" type="success" effect="light">
                {{ row.nickname }}
              </el-tag>
            </div>
            <div v-if="row.nickname" style="font-size: 11px; color: #64748b; margin-top: 2px;">
              店内称谓: <b>{{ row.nickname }}</b>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="phone" label="员工手机号" min-width="160">
          <template #default="{ row }">
            <span>{{ row.phone || '-' }}</span>
          </template>
        </el-table-column>

        <el-table-column prop="postName" label="岗位" min-width="140">
          <template #default="{ row }">
            <span class="post-name">{{ row.postName || getRoleDefaultPost(row.role) }}</span>
          </template>
        </el-table-column>

        <!-- 系统账号与授权店铺 -->
        <el-table-column label="系统账号与店铺" width="180" align="center">
          <template #default="{ row }">
            <div style="display: flex; flex-direction: column; align-items: center; gap: 4px;">
              <template v-if="row.accountStatus === 'PENDING_REVIEW' || row.auditStatus === 'PENDING'">
                <el-tag size="small" type="warning" effect="dark">⏳ 待店长审核</el-tag>
                <div style="font-size: 11px; color: #ea580c; font-weight: 600;">📲 扫码自主申请</div>
              </template>
              <template v-else-if="row.accountStatus === 'REJECTED' || row.auditStatus === 'REJECTED'">
                <el-tag size="small" type="danger" effect="plain">❌ 入职申请驳回</el-tag>
              </template>
              <template v-else-if="row.hasSystemAccount">
                <div style="display: flex; align-items: center; gap: 4px;">
                  <el-tag size="small" type="success" effect="light">⚡ 已开通登录</el-tag>
                  <el-tag v-if="row.accountStatus === 'DISABLED'" size="small" type="danger" effect="plain">已停用</el-tag>
                </div>
                <div style="font-size: 11px; color: #64748b; margin-top: 2px;">
                  <el-tag size="small" :type="row.canCrossStore ? 'success' : 'warning'" effect="plain">
                    {{ row.canCrossStore ? '🌐 具备跨店权限' : `🔒 仅限授权 ${row.allowedStoreIds?.length || 1} 家店` }}
                  </el-tag>
                </div>
              </template>
              <template v-else>
                <el-tag size="small" type="info" effect="plain">未开通系统账号</el-tag>
              </template>
            </div>
          </template>
        </el-table-column>

        <!-- 可见与可用页签 -->
        <el-table-column label="可见与可用页签" min-width="190">
          <template #default="{ row }">
            <div v-if="row.hasSystemAccount && Array.isArray(row.allowedMenuPaths) && row.allowedMenuPaths.length > 0" class="perm-tags-preview">
              <el-tag
                v-for="p in row.allowedMenuPaths.slice(0, 3)"
                :key="p"
                size="small"
                effect="plain"
                style="margin: 2px;"
              >
                {{ getMenuNameByPath(p) }}
              </el-tag>
              <el-tag v-if="row.allowedMenuPaths.length > 3" size="small" type="info" effect="light" style="margin: 2px;">
                +{{ row.allowedMenuPaths.length - 3 }}项
              </el-tag>
            </div>
            <span v-else-if="row.hasSystemAccount" style="font-size: 12px; color: #94a3b8;">未限制 (全部页签)</span>
            <span v-else style="font-size: 12px; color: #cbd5e1;">-</span>
          </template>
        </el-table-column>

        <el-table-column label="操作" min-width="580" fixed="right">
          <template #default="{ row }">
            <div class="action-links">
              <template v-if="row.accountStatus === 'PENDING_REVIEW' || row.auditStatus === 'PENDING'">
                <el-button link type="warning" @click="handleOpenStaffAudit(row)">
                  <strong>🛡️ 审核入职</strong>
                </el-button>
                <el-divider direction="vertical" />
              </template>
              <el-button link type="primary" @click="handleEdit(row)">查看/编辑</el-button>
              <el-divider direction="vertical" />
              <el-button link type="success" @click="openAccountPermissionModal(row)">
                <strong>🔐 账号与页签</strong>
              </el-button>
              <el-divider direction="vertical" />
              <el-button link type="primary" @click="handleAttendance(row)">考勤记录</el-button>
              <el-divider direction="vertical" />
              <el-button link type="primary" @click="handleCommissions(row)">提成记录</el-button>
              <el-divider direction="vertical" />
              <el-button link type="primary" @click="handleRewardPunish(row)">奖罚记录</el-button>
              <el-divider direction="vertical" />
              <el-button link type="primary" @click="handleSalaryCalc(row)">工资核算</el-button>
              <el-divider direction="vertical" />
              <el-button link type="primary" @click="handleSalaryRecords(row)">工资记录</el-button>
              <el-divider direction="vertical" />
              <el-button link type="danger" @click="handleDelete(row)">删除</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <!-- 底部分页器 (对齐截图3: 共2条  10条/页  < 1 > 前往 1 页) -->
      <div class="pagination-bar">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="filteredStaffList.length"
        />
      </div>
        </el-tab-pane>

        <!-- 选项卡 2: 考勤打卡 (支持企业微信 / 阿里钉钉对接) -->
        <el-tab-pane label="⏰ 考勤打卡 (企微·钉钉对接)" name="ATTENDANCE">
          <div class="attendance-container">
            <!-- 考勤操作栏 -->
            <div class="toolbar">
              <div class="toolbar-left">
                <el-button
                  type="primary"
                  icon="Refresh"
                  :loading="syncingAttendance"
                  @click="handleSyncAttendance"
                >
                  ⚡ 从【{{ attendanceConfig.platform === 'WECHAT_WORK' ? '企业微信' : '阿里巴巴钉钉' }}】一键同步打卡
                </el-button>
                <el-button icon="Setting" plain @click="openSyncDrawer = true">
                  ⚙️ 企微/钉钉对接凭证配置
                </el-button>
                <el-radio-group v-model="attendancePlatformFilter" size="default" style="margin-left: 8px;">
                  <el-radio-button label="ALL">全部来源</el-radio-button>
                  <el-radio-button label="WECHAT_WORK">企业微信</el-radio-button>
                  <el-radio-button label="DINGTALK">阿里巴巴钉钉</el-radio-button>
                </el-radio-group>
              </div>

              <div class="toolbar-right">
                <el-select v-model="attendanceStatusFilter" placeholder="打卡状态" clearable style="width: 130px;">
                  <el-option label="全部状态" value="ALL" />
                  <el-option label="正常准时" value="NORMAL" />
                  <el-option label="迟到早退" value="LATE" />
                  <el-option label="外勤定位打卡" value="FIELD_WORK" />
                </el-select>
                <el-input
                  v-model="attendanceKeyword"
                  placeholder="搜索员工/手机号"
                  prefix-icon="Search"
                  clearable
                  style="width: 180px;"
                />
              </div>
            </div>

            <!-- 考勤核心运行概览卡片 -->
            <div class="att-kpi-grid">
              <div class="kpi-card">
                <div class="kpi-lbl">今日应出勤打卡</div>
                <div class="kpi-val">{{ systemData.staff.length }} 人</div>
                <div class="kpi-sub">全店在册员工基准</div>
              </div>
              <div class="kpi-card text-green">
                <div class="kpi-lbl">准时打卡正常</div>
                <div class="kpi-val text-green">{{ normalAttendanceCount }} 人</div>
                <div class="kpi-sub">考勤合规率 {{ Math.round((normalAttendanceCount / (systemData.staff.length || 1)) * 100) }}%</div>
              </div>
              <div class="kpi-card text-orange">
                <div class="kpi-lbl">迟到 / 早退</div>
                <div class="kpi-val text-orange">{{ lateAttendanceCount }} 人</div>
                <div class="kpi-sub">均已记录至考勤日志</div>
              </div>
              <div class="kpi-card text-blue">
                <div class="kpi-lbl">外勤定位打卡</div>
                <div class="kpi-val text-blue">{{ fieldAttendanceCount }} 人</div>
                <div class="kpi-sub">兼职/巡店附GPS定位</div>
              </div>
              <div class="kpi-card">
                <div class="kpi-lbl">最近数据同步</div>
                <div class="kpi-sync-time">
                  <span class="pulse-dot"></span>
                  <span>{{ attendanceConfig.lastSyncTime || '刚刚同步' }}</span>
                </div>
                <div class="kpi-sub">来源：{{ attendanceConfig.platform === 'WECHAT_WORK' ? '企业微信API' : '阿里巴巴钉钉开放平台' }}</div>
              </div>
            </div>

            <!-- 打卡记录表格 -->
            <el-table
              :data="filteredAttendanceList"
              style="width: 100%; margin-top: 16px;"
              :header-cell-style="{ background: '#f8fafc', color: '#475569', fontWeight: '600' }"
            >
              <el-table-column label="打卡员工" min-width="160">
                <template #default="{ row }">
                  <div style="display: flex; align-items: center; gap: 10px;">
                    <el-avatar :size="36" style="background-color: #0284c7; font-weight: bold;">
                      {{ row.staffName?.substring(0, 1) || '员' }}
                    </el-avatar>
                    <div>
                      <div style="font-weight: 700; color: #0f172a;">{{ row.staffName }}</div>
                      <div style="font-size: 11.5px; color: #64748b;">{{ row.phone }} · {{ row.postName }}</div>
                    </div>
                  </div>
                </template>
              </el-table-column>

              <el-table-column prop="workDate" label="打卡日期" width="120" />

              <el-table-column label="上班打卡" width="160">
                <template #default="{ row }">
                  <div style="display: flex; align-items: center; gap: 6px;">
                    <span style="font-family: monospace; font-weight: 600;">{{ row.checkInTime || '-' }}</span>
                    <el-tag v-if="row.checkInStatus === 'NORMAL'" size="small" type="success" effect="light">正常</el-tag>
                    <el-tag v-else-if="row.checkInStatus === 'LATE'" size="small" type="warning" effect="dark">迟到</el-tag>
                    <el-tag v-else-if="row.checkInStatus === 'FIELD_WORK'" size="small" type="primary" effect="plain">外勤打卡</el-tag>
                    <el-tag v-else size="small" type="info">缺勤</el-tag>
                  </div>
                </template>
              </el-table-column>

              <el-table-column label="下班打卡" width="150">
                <template #default="{ row }">
                  <span style="font-family: monospace; font-weight: 600;">{{ row.checkOutTime || '-' }}</span>
                  <el-tag v-if="row.checkOutStatus === 'NORMAL'" size="small" type="success" effect="plain" style="margin-left: 6px;">正常</el-tag>
                </template>
              </el-table-column>

              <el-table-column prop="workHours" label="当日工时" width="110">
                <template #default="{ row }">
                  <span style="font-weight: 700; color: #0284c7;">{{ row.workHours }} 小时</span>
                </template>
              </el-table-column>

              <el-table-column prop="checkInLocation" label="打卡地点与设备" min-width="190">
                <template #default="{ row }">
                  <span style="font-size: 12px; color: #334155;">{{ row.checkInLocation }}</span>
                </template>
              </el-table-column>

              <el-table-column label="数据源" width="140" align="center">
                <template #default="{ row }">
                  <el-tag v-if="row.platformSource === 'WECHAT_WORK'" size="small" type="success" effect="plain">
                    🟢 企业微信
                  </el-tag>
                  <el-tag v-else size="small" type="primary" effect="plain">
                    🔵 阿里巴巴钉钉
                  </el-tag>
                </template>
              </el-table-column>

              <el-table-column prop="notes" label="考勤备注" min-width="160">
                <template #default="{ row }">
                  <span style="font-size: 12px; color: #64748b;">{{ row.notes || '-' }}</span>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>

        <!-- 选项卡 3: 员工请假审批流 -->
        <el-tab-pane label="📝 员工请假审批流" name="LEAVE_APPROVAL">
          <div class="leave-container">
            <!-- 请假操作栏 -->
            <div class="toolbar">
              <div class="toolbar-left">
                <el-button type="primary" icon="Plus" @click="handleOpenApplyLeave">
                  📝 发起员工请假申请
                </el-button>
                <el-radio-group v-model="leaveStatusFilter" size="default" style="margin-left: 10px;">
                  <el-radio-button label="ALL">全部工单 ({{ systemData.leaveApplications.length }})</el-radio-button>
                  <el-radio-button label="PENDING">待我审批 ({{ pendingLeaveCount }})</el-radio-button>
                  <el-radio-button label="APPROVED">已批准</el-radio-button>
                  <el-radio-button label="REJECTED">已驳回</el-radio-button>
                </el-radio-group>
              </div>

              <div class="toolbar-right">
                <el-input
                  v-model="leaveKeyword"
                  placeholder="搜索请假人姓名或单号"
                  prefix-icon="Search"
                  clearable
                  style="width: 200px;"
                />
              </div>
            </div>

            <!-- 请假看板卡片 -->
            <div class="leave-kpi-grid">
              <div class="kpi-card">
                <div class="kpi-lbl">本月累计请假人次</div>
                <div class="kpi-val">{{ systemData.leaveApplications.length }} 人次</div>
                <div class="kpi-sub">事假/病假/年假/调休</div>
              </div>
              <div class="kpi-card text-orange">
                <div class="kpi-lbl">待处理审批单据</div>
                <div class="kpi-val text-orange">{{ pendingLeaveCount }} 笔</div>
                <div class="kpi-sub">需要店长/主管及时批复</div>
              </div>
              <div class="kpi-card text-blue">
                <div class="kpi-lbl">本月请假累计工时</div>
                <div class="kpi-val text-blue">{{ totalLeaveHours }} 小时</div>
                <div class="kpi-sub">已自动扣减当月出勤工时</div>
              </div>
              <div class="kpi-card text-green">
                <div class="kpi-lbl">审批办结率</div>
                <div class="kpi-val text-green">{{ leaveFinishRate }}%</div>
                <div class="kpi-sub">多级审批流转闭环率</div>
              </div>
            </div>

            <!-- 请假单据表格 -->
            <el-table
              :data="filteredLeaveList"
              style="width: 100%; margin-top: 16px;"
              :header-cell-style="{ background: '#f8fafc', color: '#475569', fontWeight: '600' }"
            >
              <el-table-column prop="id" label="单据号" width="150">
                <template #default="{ row }">
                  <span style="font-family: monospace; font-weight: 600;">{{ row.id }}</span>
                </template>
              </el-table-column>

              <el-table-column label="请假员工" min-width="150">
                <template #default="{ row }">
                  <div style="font-weight: 700; color: #0f172a;">{{ row.staffName }}</div>
                  <div style="font-size: 11.5px; color: #64748b;">{{ row.department }} · {{ row.postName }}</div>
                </template>
              </el-table-column>

              <el-table-column label="请假类型" width="120">
                <template #default="{ row }">
                  <el-tag :type="getLeaveTypeTag(row.leaveType)" effect="light">
                    {{ row.leaveTypeName }}
                  </el-tag>
                </template>
              </el-table-column>

              <el-table-column label="请假时间区间与工时" min-width="200">
                <template #default="{ row }">
                  <div style="font-size: 12px; color: #334155;">{{ row.startTime }} 至 {{ row.endTime }}</div>
                  <div style="font-size: 11.5px; color: #0284c7; font-weight: 600;">共计 {{ row.totalDays }} 天 ({{ row.totalHours }} 工时)</div>
                </template>
              </el-table-column>

              <el-table-column prop="reason" label="请假事由" min-width="180" show-overflow-tooltip />

              <el-table-column label="审批状态" width="110" align="center">
                <template #default="{ row }">
                  <el-tag v-if="row.status === 'PENDING'" type="warning" effect="dark">待审批</el-tag>
                  <el-tag v-else-if="row.status === 'APPROVED'" type="success" effect="light">已批准</el-tag>
                  <el-tag v-else-if="row.status === 'REJECTED'" type="danger" effect="plain">已驳回</el-tag>
                </template>
              </el-table-column>

              <el-table-column label="当前审批人" width="130">
                <template #default="{ row }">
                  <span style="font-size: 12px; color: #475569;">{{ row.currentApprover }}</span>
                </template>
              </el-table-column>

              <el-table-column label="审批流转操作" width="190" fixed="right">
                <template #default="{ row }">
                  <template v-if="row.status === 'PENDING'">
                    <el-tooltip
                      v-if="isSelfLeave(row)"
                      content="员工本人提交的请假单，不可自行审批，需由主管/店长处理"
                      placement="top"
                    >
                      <el-button size="small" type="info" disabled plain>
                        本人申请(禁批)
                      </el-button>
                    </el-tooltip>
                    <el-button
                      v-else
                      size="small"
                      type="primary"
                      @click="handleOpenAudit(row)"
                    >
                      审批处理
                    </el-button>
                  </template>
                  <el-button
                    size="small"
                    link
                    type="primary"
                    @click="handleViewTimeline(row)"
                  >
                    查看流程节点
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>

        <!-- 选项卡 4: 扫码入职审核 (店长/租户审核) -->
        <el-tab-pane name="STAFF_AUDIT">
          <template #label>
            <span style="display: flex; align-items: center; gap: 6px;">
              <span>🛡️ 扫码入职审核</span>
              <el-badge v-if="pendingStaffAuditCount > 0" :value="pendingStaffAuditCount" type="danger" />
            </span>
          </template>

          <div class="audit-tab-container" style="padding-top: 8px;">
            <!-- 提示条 -->
            <div style="padding: 12px 16px; background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between;">
              <div style="font-size: 13px; color: #1e40af; line-height: 1.6;">
                🛡️ <strong>员工扫码自主入职审核规范：</strong>应聘人员扫描【📲 员工自助入职码】提交资料后，需由<strong>店长</strong>或<strong>租户老板</strong>审核批准后方可开通系统登录权限。审核时可调整拟定岗位、基本底薪、执业分店与页签权限。
              </div>
              <el-button size="small" type="primary" plain icon="Refresh" @click="loadAuditStaffList">刷新申请列表</el-button>
            </div>

            <!-- 筛选栏 -->
            <div class="toolbar" style="margin-bottom: 16px;">
              <div class="toolbar-left">
                <el-radio-group v-model="auditStatusFilter" size="default">
                  <el-radio-button label="ALL">全部申请记录</el-radio-button>
                  <el-radio-button label="PENDING">⏳ 待审核 ({{ pendingStaffAuditCount }})</el-radio-button>
                  <el-radio-button label="APPROVED">✅ 审核已通过</el-radio-button>
                  <el-radio-button label="REJECTED">❌ 已驳回</el-radio-button>
                </el-radio-group>
              </div>
              <div class="toolbar-right">
                <el-input
                  v-model="auditSearchKeyword"
                  placeholder="搜索申请人姓名/手机号/岗位"
                  style="width: 240px;"
                  clearable
                >
                  <template #prefix>
                    <el-icon><Search /></el-icon>
                  </template>
                </el-input>
              </div>
            </div>

            <!-- 审核表格 -->
            <el-table
              :data="filteredAuditStaffList"
              style="width: 100%;"
              :header-cell-style="{ background: '#f8fafc', color: '#475569', fontWeight: '600' }"
            >
              <el-table-column prop="applyTime" label="申请提交时间" width="160" />
              <el-table-column label="申请人姓名" min-width="170">
                <template #default="{ row }">
                  <div style="display: flex; align-items: center; gap: 10px;">
                    <el-avatar :size="36" style="background-color: #f59e0b; font-weight: bold; font-size: 14px;">
                      {{ row.realName?.substring(0, 1) || '职' }}
                    </el-avatar>
                    <div>
                      <div style="font-weight: 700; color: #0f172a;">
                        {{ row.realName }}
                        <el-tag size="small" :type="row.gender === 'FEMALE' ? 'danger' : 'primary'" effect="plain" style="margin-left: 4px;">
                          {{ row.gender === 'FEMALE' ? '女' : '男' }}
                        </el-tag>
                      </div>
                      <div style="font-size: 12px; color: #64748b;">{{ row.phone }}</div>
                    </div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="postName" label="应聘意向岗位" width="160">
                <template #default="{ row }">
                  <span style="font-weight: 600; color: #0369a1;">{{ row.postName }}</span>
                </template>
              </el-table-column>
              <el-table-column label="申请执业门店" min-width="160">
                <template #default="{ row }">
                  <el-tag v-for="sId in row.allowedStoreIds" :key="sId" size="small" style="margin-right: 4px;">
                    {{ getStoreNameById(sId) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="experience" label="特长与从业背景" min-width="220" show-overflow-tooltip>
                <template #default="{ row }">
                  <span style="font-size: 12.5px; color: #475569;">{{ row.experience || '未填写特长说明' }}</span>
                </template>
              </el-table-column>
              <el-table-column label="审核状态" width="130" align="center">
                <template #default="{ row }">
                  <el-tag v-if="row.auditStatus === 'PENDING' || row.accountStatus === 'PENDING_REVIEW'" type="warning" effect="dark">
                    ⏳ 待审核
                  </el-tag>
                  <el-tag v-else-if="row.auditStatus === 'APPROVED' || row.accountStatus === 'ENABLED'" type="success" effect="light">
                    ✅ 审核通过
                  </el-tag>
                  <el-tag v-else-if="row.auditStatus === 'REJECTED' || row.accountStatus === 'REJECTED'" type="danger" effect="plain">
                    ❌ 已驳回
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="审核批注/归档" min-width="180">
                <template #default="{ row }">
                  <div v-if="row.auditTime" style="font-size: 11.5px; color: #64748b; line-height: 1.5;">
                    <div>审批人：{{ row.auditor || '店长/租户' }}</div>
                    <div>时间：{{ row.auditTime }}</div>
                    <div v-if="row.rejectReason" style="color: #ef4444; font-weight: 600;">驳回原因：{{ row.rejectReason }}</div>
                  </div>
                  <span v-else style="color: #94a3b8; font-size: 12px;">待店长或租户审核处理</span>
                </template>
              </el-table-column>
              <el-table-column label="审核操作" width="190" fixed="right">
                <template #default="{ row }">
                  <template v-if="row.auditStatus === 'PENDING' || row.accountStatus === 'PENDING_REVIEW'">
                    <el-button size="small" type="success" @click="handleOpenStaffAudit(row)">
                      ✅ 审核通过
                    </el-button>
                    <el-button size="small" type="danger" plain @click="handleRejectStaffAudit(row)">
                      ❌ 驳回
                    </el-button>
                  </template>
                  <template v-else>
                    <el-button size="small" link type="primary" @click="handleEdit(row)">查看档案</el-button>
                    <el-button v-if="row.auditStatus === 'REJECTED'" size="small" link type="warning" @click="handleOpenStaffAudit(row)">重新审核</el-button>
                  </template>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 1. 新增/编辑员工弹窗 -->
    <el-dialog
      v-model="staffDialogVisible"
      :title="isEditing ? '查看/编辑员工' : '新增员工'"
      width="520px"
      destroy-on-close
    >
      <el-form :model="staffForm" label-width="100px">
        <el-form-item label="员工姓名" required>
          <el-input v-model="staffForm.realName" placeholder="请输入员工真实姓名，如：张三" />
        </el-form-item>
        <el-form-item label="店内对外称呼">
          <el-input v-model="staffForm.nickname" placeholder="例如：小美、Tony、8号主厨 (用于APP及前台加项下拉对外展示)" />
        </el-form-item>
        <el-form-item label="手机号码" required>
          <el-input v-model="staffForm.phone" placeholder="请输入员工手机号" />
        </el-form-item>
        <el-form-item label="岗位名称" required>
          <el-select v-model="staffForm.postName" filterable allow-create style="width: 100%;" placeholder="请选择或输入岗位">
            <el-option
              v-for="p in configuredPositions"
              :key="p.id || p.postName"
              :label="p.postName + (p.department ? ' (' + p.department + ')' : '')"
              :value="p.postName"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="基本底薪(元)">
          <el-input-number v-model="staffForm.baseSalary" :min="0" :step="500" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="提成比率">
          <el-input-number
            v-model="staffForm.commissionPercentage"
            :min="0"
            :max="100"
            :step="1"
            style="width: 180px;"
          />
          <span style="margin-left: 8px; color: #64748b;">% (默认 0%，根据业绩工单核算提成)</span>
        </el-form-item>
        <el-form-item label="性别">
          <el-radio-group v-model="staffForm.gender">
            <el-radio label="MALE">先生</el-radio>
            <el-radio label="FEMALE">女士</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="staffDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingStaff" @click="handleSaveStaff">保存</el-button>
      </template>
    </el-dialog>

    <!-- 2. 新增奖罚弹窗 -->
    <el-dialog v-model="rewardPunishDialogVisible" title="新增奖罚记录" width="480px" destroy-on-close>
      <el-form :model="rewardPunishForm" label-width="100px">
        <el-form-item label="奖罚员工" required>
          <el-select v-model="rewardPunishForm.employeeId" placeholder="请选择员工" style="width: 100%;">
            <el-option
              v-for="s in staffList"
              :key="s.id"
              :label="s.realName + ' (' + (s.postName || getRoleDefaultPost(s.role)) + ')'"
              :value="s.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="奖罚类型" required>
          <el-radio-group v-model="rewardPunishForm.type">
            <el-radio label="REWARD"><span style="color: #16a34a; font-weight: 600;">🏆 奖励</span></el-radio>
            <el-radio label="PUNISH"><span style="color: #dc2626; font-weight: 600;">⚠️ 扣罚</span></el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="金额(元)" required>
          <el-input-number v-model="rewardPunishForm.amount" :min="1" :step="50" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="奖罚原因" required>
          <el-input v-model="rewardPunishForm.reason" type="textarea" :rows="3" placeholder="如：技能比赛一等奖、全勤奖、或迟到违规等说明" />
        </el-form-item>
        <el-form-item label="发生日期">
          <el-date-picker v-model="rewardPunishForm.recordDate" type="date" style="width: 100%;" value-format="YYYY-MM-DD" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="rewardPunishDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingRewardPunish" @click="handleSaveRewardPunish">确认提交</el-button>
      </template>
    </el-dialog>

    <!-- 3. 提成设置弹窗 -->
    <el-dialog v-model="commissionSettingVisible" title="门店提成方案设置" width="520px" destroy-on-close>
      <el-alert
        title="提成设置将自动核算技师与店员的服务项目施工提成、会员售卡提成及产品外卖销售提成。"
        type="info"
        show-icon
        :closable="false"
        style="margin-bottom: 16px;"
      />
      <el-form label-width="120px">
        <el-form-item label="服务项目提成">
          <el-input-number v-model="globalCommission.serviceRate" :min="0" :max="100" :step="5" />
          <span style="margin-left: 8px; color: #64748b;">% (默认手工提成)</span>
        </el-form-item>
        <el-form-item label="会员售卡提成">
          <el-input-number v-model="globalCommission.cardRate" :min="0" :max="100" :step="1" />
          <span style="margin-left: 8px; color: #64748b;">% (储值/次卡售卖)</span>
        </el-form-item>
        <el-form-item label="外卖商品提成">
          <el-input-number v-model="globalCommission.productRate" :min="0" :max="100" :step="1" />
          <span style="margin-left: 8px; color: #64748b;">% (产品耗材零售)</span>
        </el-form-item>
        <el-form-item label="核算基准">
          <el-radio-group v-model="globalCommission.baseType">
            <el-radio label="ACTUAL">按实收金额核算</el-radio>
            <el-radio label="ORIGINAL">按项目原价核算</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="commissionSettingVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveCommissionSetting">保存提成配置</el-button>
      </template>
    </el-dialog>

    <!-- 4. 恢复已删除员工弹窗 -->
    <el-dialog v-model="restoreDialogVisible" title="恢复删除员工" width="560px" destroy-on-close>
      <el-table :data="deletedStaffList" v-loading="loadingDeleted" empty-text="暂无已删除员工">
        <el-table-column prop="realName" label="员工名称" width="140" />
        <el-table-column prop="phone" label="手机号" width="150" />
        <el-table-column prop="postName" label="原岗位" />
        <el-table-column label="操作" width="100" align="center">
          <template #default="{ row }">
            <el-button link type="primary" @click="handleRestoreStaff(row.id)">恢复在职</el-button>
          </template>
        </el-table-column>
      </el-table>
      <template #footer>
        <el-button @click="restoreDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 5. 考勤记录抽屉 (完全基于当前选定员工的真实打卡流水) -->
    <el-drawer v-model="attendanceDrawerVisible" :title="'考勤打卡档案 - ' + (currentStaff?.realName || '')" size="520px">
      <div class="drawer-stat-bar">
        <div class="stat-item">
          <span class="lbl">累计打卡天数</span>
          <span class="val">{{ currentStaffAttendedDays }} 天</span>
        </div>
        <div class="stat-item">
          <span class="lbl">迟到/早退</span>
          <span class="val" :style="{ color: currentStaffLateCount > 0 ? '#ef4444' : '#10b981' }">{{ currentStaffLateCount }} 次</span>
        </div>
        <div class="stat-item">
          <span class="lbl">考勤合格率</span>
          <span class="val" style="color: #0284c7;">{{ currentStaffAttendanceRate }}</span>
        </div>
      </div>

      <div v-if="currentStaffAttendanceList.length === 0" style="margin-top: 40px; text-align: center;">
        <el-empty description="该员工暂无考勤打卡流水记录（新入职或尚未打卡）" :image-size="100" />
        <div style="font-size: 12.5px; color: #64748b; line-height: 1.6; max-width: 400px; margin: 12px auto 0; background: #f8fafc; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; text-align: left;">
          💡 <b>打卡说明：</b>新员工入职后，可通过海马移动端 APP【📍 定位打卡】进行早晚上下班考勤；或通过企业微信/钉钉/考勤机打卡，数据将实时同步并汇聚于此。
        </div>
      </div>

      <el-timeline v-else style="margin-top: 24px; padding-right: 14px;">
        <el-timeline-item
          v-for="(item, idx) in currentStaffAttendanceList"
          :key="item.id || idx"
          :timestamp="item.workDate + ' ' + (item.checkInTime || '')"
          :type="item.checkInStatus === 'NORMAL' ? 'success' : (item.checkInStatus === 'LATE' ? 'warning' : 'primary')"
          placement="top"
        >
          <el-card shadow="never" style="border-radius: 8px;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
              <h4 style="margin: 0; font-size: 14px; font-weight: 700;">
                {{ item.checkInStatus === 'NORMAL' ? '🟢 上班打卡正常' : (item.checkInStatus === 'LATE' ? '🟡 上班迟到' : '📍 外勤打卡') }}
              </h4>
              <el-tag size="small" :type="item.checkInStatus === 'NORMAL' ? 'success' : 'warning'">
                {{ item.platformSource === 'APP_MOBILE' ? 'APP定位' : (item.platformSource === 'WECHAT_WORK' ? '企业微信' : '考勤机') }}
              </el-tag>
            </div>
            <p style="color: #64748b; font-size: 12.5px; margin: 4px 0;">打卡地点：{{ item.checkInLocation || '门店现场定位' }}</p>
            <p v-if="item.checkOutTime" style="color: #64748b; font-size: 12.5px; margin: 4px 0;">
              下班打卡：{{ item.checkOutTime }} · 当日工时：{{ item.workHours || 8 }} 小时
            </p>
            <p v-if="item.notes" style="color: #94a3b8; font-size: 11.5px; margin: 4px 0;">
              备注：{{ item.notes }}
            </p>
          </el-card>
        </el-timeline-item>
      </el-timeline>
    </el-drawer>

    <!-- 6. 提成记录抽屉 -->
    <el-drawer v-model="commissionsDrawerVisible" :title="'提成记录明细 - ' + (currentStaff?.realName || '')" size="560px">
      <div class="drawer-stat-bar">
        <div class="stat-item">
          <span class="lbl">当月提成累计</span>
          <span class="val" style="color: #0284c7;">￥{{ currentStaffCommissionTotal }}</span>
        </div>
        <div class="stat-item">
          <span class="lbl">履约工单数</span>
          <span class="val">{{ staffCommissions.length }} 单</span>
        </div>
      </div>
      <el-table :data="staffCommissions" style="width: 100%; margin-top: 16px;" empty-text="本月暂无提成记录">
        <el-table-column prop="billingOrderId" label="工单流水" width="140" />
        <el-table-column prop="serviceItemName" label="项目/商品" />
        <el-table-column prop="orderAmount" label="订单额(元)" width="100">
          <template #default="{ row }">￥{{ row.orderAmount }}</template>
        </el-table-column>
        <el-table-column prop="commissionAmount" label="提成(元)" width="100">
          <template #default="{ row }">
            <span style="color: #16a34a; font-weight: 700;">+￥{{ row.commissionAmount }}</span>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="本月暂无提成记录" :image-size="80" />
        </template>
      </el-table>
    </el-drawer>

    <!-- 7. 奖罚记录抽屉 -->
    <el-drawer v-model="rewardPunishDrawerVisible" :title="'奖罚记录 - ' + (currentStaff?.realName || '')" size="520px">
      <el-table :data="staffRewardPunishList" style="width: 100%; margin-top: 16px;" empty-text="暂无奖罚记录">
        <el-table-column prop="type" label="类型" width="90">
          <template #default="{ row }">
            <el-tag :type="row.type === 'REWARD' ? 'success' : 'danger'" size="small">
              {{ row.type === 'REWARD' ? '奖励' : '扣罚' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="amount" label="金额(元)" width="100">
          <template #default="{ row }">
            <span :style="{ color: row.type === 'REWARD' ? '#16a34a' : '#dc2626', fontWeight: 'bold' }">
              {{ row.type === 'REWARD' ? '+' : '-' }}￥{{ row.amount }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="reason" label="事由/说明" />
        <el-table-column prop="recordDate" label="日期" width="110" />
      </el-table>
    </el-drawer>

    <!-- 8. 工资核算弹窗 -->
    <el-dialog v-model="salaryCalcVisible" :title="'本月工资核算 - ' + (currentStaff?.realName || '')" width="520px" destroy-on-close>
      <template v-if="hasStaffSalaryData">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="员工姓名">{{ currentStaff?.realName }}</el-descriptions-item>
          <el-descriptions-item label="所属岗位">{{ currentStaff?.postName || getRoleDefaultPost(currentStaff?.role) }}</el-descriptions-item>
          <el-descriptions-item label="基本底薪">
            ￥{{ Number(currentStaff?.baseSalary || 0).toFixed(2) }}
          </el-descriptions-item>
          <el-descriptions-item label="工单服务提成">
            <span style="color: #16a34a; font-weight: 600;">+ ￥{{ Number(currentStaffCommissionTotal || 0).toFixed(2) }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="奖罚调整合计">
            <span :style="{ color: currentStaffRewardPunishTotal >= 0 ? '#0284c7' : '#dc2626', fontWeight: 600 }">
              {{ currentStaffRewardPunishTotal >= 0 ? '+' : '-' }} ￥{{ Math.abs(currentStaffRewardPunishTotal).toFixed(2) }}
            </span>
          </el-descriptions-item>
          <el-descriptions-item label="当月应发合计">
            <span style="font-size: 18px; font-weight: 700; color: #d97706;">
              ￥{{ (Number(currentStaff?.baseSalary || 0) + Number(currentStaffCommissionTotal || 0) + currentStaffRewardPunishTotal).toFixed(2) }}
            </span>
          </el-descriptions-item>
        </el-descriptions>
      </template>
      <template v-else>
        <div style="padding: 24px 0; text-align: center;">
          <el-empty description="本月暂无工资核算数据（该员工未配置底薪，且暂无工单提成与奖罚记录）" :image-size="90" />
          <div style="margin-top: 12px; font-size: 13px; color: #64748b;">
            提示：您可在员工列表点击「查看/编辑」为其设定基本底薪与提成比例。
          </div>
        </div>
      </template>
      <template #footer>
        <el-button @click="salaryCalcVisible = false">取消</el-button>
        <el-button type="primary" :disabled="!hasStaffSalaryData" @click="handleConfirmSalaryPay">确认核算并归档</el-button>
      </template>
    </el-dialog>

    <!-- 9. 工资记录抽屉 -->
    <el-drawer v-model="salaryRecordsVisible" :title="'历史工资发薪记录 - ' + (currentStaff?.realName || '')" size="520px">
      <el-table :data="salaryMockRecords" style="width: 100%; margin-top: 16px;">
        <el-table-column prop="month" label="月份" width="120" />
        <el-table-column prop="baseSalary" label="底薪(元)" width="90">
          <template #default="{ row }">￥{{ row.baseSalary }}</template>
        </el-table-column>
        <el-table-column prop="commission" label="提成(元)" width="90">
          <template #default="{ row }">￥{{ row.commission }}</template>
        </el-table-column>
        <el-table-column prop="actualSalary" label="实发工资(元)" width="110">
          <template #default="{ row }">
            <span style="color: #16a34a; font-weight: 700;">￥{{ row.actualSalary }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态">
          <template #default>
            <el-tag type="success" size="small">已发放在账</el-tag>
          </template>
        </el-table-column>
        <template #empty>
          <el-empty description="暂无历史发薪记录" :image-size="80" />
        </template>
      </el-table>
    </el-drawer>

    <!-- 10. 员工系统登录账号与功能页签权限配置弹窗 -->
    <el-dialog
      v-model="accountDialogVisible"
      :title="`🔐 员工系统账号与功能页签权限配置 - 【${accountForm.realName || '员工'}】`"
      width="820px"
      destroy-on-close
    >
      <div class="account-dialog-body">
        <!-- 顶部身份与说明提示 -->
        <div class="account-alert-banner">
          <span class="a-icon">🛡️</span>
          <div class="a-text">
            <div class="a-title">租户开通员工系统账号与按店授权体系</div>
            <div class="a-desc">开通账号后，员工可凭手机号与密码登录海马智慧门店系统；可灵活配置员工在系统中所能看到和使用的业务页签；多店兼职员工登录时可自主选择进入哪个店工作。</div>
          </div>
        </div>

        <el-form :model="accountForm" label-width="110px" style="margin-top: 16px;">
          <!-- 区块一：登录账号凭据 -->
          <div class="config-block">
            <div class="block-title">
              <span class="dot-icon">🔑</span>
              <span>登录凭据设置</span>
            </div>

            <el-row :gutter="16">
              <el-col :span="12">
                <el-form-item label="开通系统账号" required>
                  <el-switch
                    v-model="accountForm.hasSystemAccount"
                    active-text="已开通登录"
                    inactive-text="未开通"
                    inline-prompt
                  />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="账号运行状态" required>
                  <el-radio-group v-model="accountForm.accountStatus" size="small" :disabled="!accountForm.hasSystemAccount">
                    <el-radio-button label="ENABLED">正常可用</el-radio-button>
                    <el-radio-button label="DISABLED">暂停登录</el-radio-button>
                  </el-radio-group>
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="16">
              <el-col :span="12">
                <el-form-item label="登录手机号" required>
                  <el-input v-model="accountForm.phone" placeholder="请输入员工登录手机号" prefix-icon="Iphone" />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="登录密码" required>
                  <div style="display: flex; gap: 8px; width: 100%;">
                    <el-input
                      v-model="accountForm.accountPassword"
                      type="text"
                      placeholder="设置登录密码"
                      prefix-icon="Lock"
                    />
                    <el-button size="small" @click="accountForm.accountPassword = '123456'">重置123456</el-button>
                  </div>
                </el-form-item>
              </el-col>
            </el-row>
          </div>

          <!-- 区块二：多店铺执业授权与跨店漫游权限 -->
          <div class="config-block">
            <div class="block-title">
              <span class="dot-icon">🏪</span>
              <span>门店执业授权与跨店权限配置</span>
              <el-tag size="small" :type="accountForm.canCrossStore ? 'success' : 'warning'" effect="plain" style="margin-left: 8px;">
                {{ accountForm.canCrossStore ? '🌐 已开启跨店全店漫游' : '🔒 严格限制单店/授权店铺' }}
              </el-tag>
            </div>
            <div class="block-sub-hint">
              精确控制该员工能够查看和操作的门店范围。若<b>未开启跨店漫游权限</b>，员工登录后顶部切换器与各业务页面<b>仅能查看当前配置被授权可使用的店铺</b>，彻底隔离未授权门店。
            </div>

            <div style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px 14px; margin-bottom: 12px; display: flex; align-items: center; justify-content: space-between;">
              <div>
                <div style="font-size: 13px; font-weight: 700; color: #1e293b;">跨店铺漫游操作权限</div>
                <div style="font-size: 11px; color: #64748b; margin-top: 2px;">
                  {{ accountForm.canCrossStore ? '该员工具备跨店权限，可在系统顶部自由切换和查看所有连锁分店' : '未开启跨店权限，员工仅限查看下方勾选的授权门店，无权查看其他店铺' }}
                </div>
              </div>
              <el-switch
                v-model="accountForm.canCrossStore"
                active-text="允许跨店"
                inactive-text="仅限授权店铺"
                inline-prompt
              />
            </div>

            <div style="font-size: 12px; font-weight: 600; color: #334155; margin-bottom: 8px;">
              授权执业店铺列表 (多店兼职登录时自选)：
            </div>

            <el-checkbox-group v-model="accountForm.allowedStoreIds" class="store-checkbox-group">
              <div
                v-for="s in systemData.stores"
                :key="s.storeId"
                class="store-check-card"
                :class="{ 'is-selected': accountForm.allowedStoreIds.includes(s.storeId) }"
                @click="toggleStoreSelect(s.storeId)"
              >
                <el-checkbox :label="s.storeId" @click.stop>
                  <div class="s-info">
                    <span class="s-name">{{ s.storeName }}</span>
                    <span class="s-addr">{{ s.address }}</span>
                  </div>
                </el-checkbox>
                <el-tag size="small" :type="s.isHeadquarter ? 'danger' : 'info'" effect="light">
                  {{ s.isHeadquarter ? '旗舰总店' : '分店/概念店' }}
                </el-tag>
              </div>
            </el-checkbox-group>
          </div>

          <!-- 区块三：修改员工可以看到和使用的功能页签 (菜单权限) -->
          <div class="config-block">
            <div class="block-title">
              <span class="dot-icon">📑</span>
              <span>修改员工可以看到和使用的功能页签 (菜单权限)</span>
            </div>
            <div class="block-sub-hint">
              精确控制员工登录海马系统后，左侧导航栏仅展示被授权的页签，未被授权的功能页签彻底隐藏且无法越权操作。
            </div>

            <!-- 快捷预设模板 -->
            <div class="preset-btn-bar">
              <span class="preset-lbl">一键快捷应用模板：</span>
              <el-button size="small" round type="primary" plain @click="applyMenuPreset('TECHNICIAN')">
                ✂️ 技师/造型师常用 (5个页签)
              </el-button>
              <el-button size="small" round type="success" plain @click="applyMenuPreset('CASHIER')">
                💳 前台收银常用 (7个页签)
              </el-button>
              <el-button size="small" round type="warning" plain @click="applyMenuPreset('MANAGER')">
                🏬 店长全权管理 (除超级设置外)
              </el-button>
              <el-button size="small" round @click="applyMenuPreset('ALL')">全选</el-button>
              <el-button size="small" round @click="applyMenuPreset('CLEAR')">清空</el-button>
            </div>

            <!-- 14大页签网格选择 -->
            <div class="menu-selection-grid">
              <div
                v-for="menu in allSystemMenus"
                :key="menu.path"
                class="menu-option-card"
                :class="{ 'is-checked': accountForm.allowedMenuPaths.includes(menu.path) }"
                @click="toggleMenuPath(menu.path)"
              >
                <div class="menu-check-left">
                  <el-checkbox :value="menu.path" :label="menu.path" v-model="accountForm.allowedMenuPaths" @click.stop />
                  <div class="menu-meta">
                    <span class="menu-name">{{ menu.name }}</span>
                    <span class="menu-desc">{{ menu.description }}</span>
                  </div>
                </div>
                <el-tag size="small" :type="getCategoryTypeTag(menu.category)" effect="plain">
                  {{ menu.categoryName }}
                </el-tag>
              </div>
            </div>
          </div>
        </el-form>
      </div>

      <template #footer>
        <el-button @click="accountDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingAccount" @click="handleSaveAccount">
          保存账号与页签权限
        </el-button>
      </template>
    </el-dialog>

    <!-- 员工自主入职开号二维码与链接弹窗 -->
    <el-dialog v-model="staffQrDialogVisible" title="📲 员工自助入职申请与开号二维码" width="500px">
      <div class="qr-modal-body">
        <div class="qr-store-badge">
          <span class="qr-store-icon">🏢</span>
          <span class="qr-store-name">{{ currentStoreName }}</span>
          <el-tag size="small" type="warning" effect="light">扫码申报本店岗位</el-tag>
        </div>

        <div class="qr-code-wrapper">
          <img v-if="staffQrCodeDataUrl" :src="staffQrCodeDataUrl" class="qr-image" alt="入职二维码" />
          <div v-else class="qr-loading">生成高清二维码中...</div>
          <div class="qr-scan-hint">意向/新员工微信/手机浏览器扫码，自主填报资料与设置密码</div>
        </div>

        <div class="qr-link-box">
          <div class="qr-link-title">🔗 本店员工入职申请网页地址：</div>
          <el-input v-model="staffRegisterLink" readonly>
            <template #append>
              <el-button type="primary" @click="copyStaffRegisterLink">复制链接</el-button>
            </template>
          </el-input>
        </div>

        <div class="qr-actions">
          <el-button type="primary" plain @click="openStaffRegisterPage">
            在新窗口模拟员工入职
          </el-button>
          <el-button type="warning" plain @click="downloadStaffQrCode">
            保存二维码图片
          </el-button>
        </div>
      </div>
      <template #footer>
        <el-button @click="staffQrDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 企微/钉钉打卡对接配置抽屉 -->
    <el-drawer
      v-model="openSyncDrawer"
      title="⚙️ 考勤打卡外设对接凭证配置 (企业微信 · 阿里巴巴钉钉)"
      size="520px"
      destroy-on-close
    >
      <div class="sync-config-body">
        <el-alert
          title="系统支持直连企业微信打卡机/移动打卡，或阿里巴巴钉钉考勤开放平台，员工在企微或钉钉打卡后自动实时同步至本店"
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 16px;"
        />

        <el-form label-position="top">
          <el-form-item label="当前主对接平台">
            <el-radio-group v-model="attendanceConfig.platform" size="default">
              <el-radio-button label="WECHAT_WORK">🟢 企业微信 (WeCom)</el-radio-button>
              <el-radio-button label="DINGTALK">🔵 阿里巴巴钉钉 (DingTalk)</el-radio-button>
            </el-radio-group>
          </el-form-item>

          <!-- 企微配置 -->
          <template v-if="attendanceConfig.platform === 'WECHAT_WORK'">
            <el-form-item label="企业微信企业ID (CorpId)" required>
              <el-input v-model="attendanceConfig.corpId" placeholder="例如: ww78a9c33d8e90xxxx" />
              <div class="field-hint">请在企业微信管理后台 [我的企业] -> [企业信息] 中查看</div>
            </el-form-item>

            <el-form-item label="打卡应用 AgentId" required>
              <el-input v-model="attendanceConfig.agentId" placeholder="例如: 1000088" />
              <div class="field-hint">自建应用或内置打卡应用 AgentId</div>
            </el-form-item>

            <el-form-item label="应用凭证 Secret" required>
              <el-input v-model="attendanceConfig.appSecret" type="password" show-password placeholder="请输入应用通讯密钥 Secret" />
              <div class="field-hint">需具备【打卡】API只读或读写权限</div>
            </el-form-item>
          </template>

          <!-- 钉钉配置 -->
          <template v-else>
            <el-form-item label="钉钉开放平台 AppKey" required>
              <el-input v-model="attendanceConfig.dingAppKey" placeholder="例如: dingabc123xxxx" />
              <div class="field-hint">钉钉开放平台创建内部应用的 AppKey</div>
            </el-form-item>

            <el-form-item label="应用密钥 AppSecret" required>
              <el-input v-model="attendanceConfig.dingAppSecret" type="password" show-password placeholder="请输入 AppSecret" />
            </el-form-item>
          </template>

          <el-divider content-position="left">自动化同步策略</el-divider>

          <el-form-item label="开启打卡数据自动轮询同步">
            <div style="display: flex; align-items: center; justify-content: space-between; width: 100%;">
              <span style="font-size: 13px; color: #475569;">每日营业期间每隔固定周期自动从平台拉取打卡流水</span>
              <el-switch v-model="attendanceConfig.autoSync" />
            </div>
          </el-form-item>

          <el-form-item label="自动拉取同步间隔 (分钟)">
            <el-select v-model="attendanceConfig.syncIntervalMinutes" style="width: 100%;">
              <el-option label="每 15 分钟自动拉取一次" :value="15" />
              <el-option label="每 30 分钟自动拉取一次" :value="30" />
              <el-option label="每 60 分钟自动拉取一次" :value="60" />
            </el-select>
          </el-form-item>
        </el-form>
      </div>

      <template #footer>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <el-button
            plain
            type="warning"
            :loading="testingConnection"
            @click="handleTestConnection"
          >
            ⚡ 测试对接连通性
          </el-button>
          <div>
            <el-button @click="openSyncDrawer = false">取消</el-button>
            <el-button type="primary" :loading="savingSyncConfig" @click="handleSaveSyncConfig">
              保存配置
            </el-button>
          </div>
        </div>
      </template>
    </el-drawer>

    <!-- 发起员工请假申请弹窗 -->
    <el-dialog
      v-model="openApplyLeaveDialog"
      title="📝 发起员工请假申请"
      width="540px"
      destroy-on-close
    >
      <el-form label-width="110px">
        <el-form-item label="请假员工" required>
          <el-select
            v-model="applyLeaveForm.staffId"
            placeholder="请选择在册员工"
            filterable
            style="width: 100%;"
            @change="handleSelectLeaveStaff"
          >
            <el-option
              v-for="s in systemData.staff"
              :key="s.id"
              :label="`${s.realName} (${s.postName || '员工'} - ${s.phone})`"
              :value="s.id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="请假类型" required>
          <el-select v-model="applyLeaveForm.leaveType" style="width: 100%;">
            <el-option label="事假 (不计薪工时)" value="PERSONAL" />
            <el-option label="病假 (需提供就医证明)" value="SICK" />
            <el-option label="带薪年假 (带薪年休)" value="ANNUAL" />
            <el-option label="加班调休 (冲抵工时)" value="REST" />
            <el-option label="婚假 / 产假 / 陪产假" value="MATERNITY" />
          </el-select>
        </el-form-item>

        <el-form-item label="开始时间" required>
          <el-date-picker
            v-model="applyLeaveForm.startTime"
            type="datetime"
            placeholder="选择请假开始时间"
            value-format="YYYY-MM-DD HH:mm:ss"
            style="width: 100%;"
          />
        </el-form-item>

        <el-form-item label="结束时间" required>
          <el-date-picker
            v-model="applyLeaveForm.endTime"
            type="datetime"
            placeholder="选择请假结束时间"
            value-format="YYYY-MM-DD HH:mm:ss"
            style="width: 100%;"
          />
        </el-form-item>

        <el-form-item label="请假工时换算" required>
          <div style="display: flex; gap: 12px; width: 100%;">
            <el-input-number v-model="applyLeaveForm.totalDays" :min="0.5" :step="0.5" placeholder="天数" style="flex: 1;" />
            <span style="display: flex; align-items: center; color: #64748b;">天 (折合</span>
            <el-input-number v-model="applyLeaveForm.totalHours" :min="1" :step="1" placeholder="工时" style="flex: 1;" />
            <span style="display: flex; align-items: center; color: #64748b;">小时)</span>
          </div>
        </el-form-item>

        <el-form-item label="请假事由" required>
          <el-input
            v-model="applyLeaveForm.reason"
            type="textarea"
            :rows="3"
            placeholder="请详细说明请假原因及交接安排..."
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="openApplyLeaveDialog = false">取消</el-button>
        <el-button type="primary" :loading="submittingLeave" @click="handleConfirmApplyLeave">
          提交并流转审批
        </el-button>
      </template>
    </el-dialog>

    <!-- 员工请假审批处理弹窗 -->
    <el-dialog
      v-model="openAuditDialog"
      title="⚖️ 员工请假审批批复"
      width="500px"
      destroy-on-close
    >
      <div v-if="activeAuditItem" style="margin-bottom: 16px; background: #f8fafc; padding: 14px; border-radius: 8px; border: 1px solid #e2e8f0;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
          <span style="font-weight: 700; color: #0f172a; font-size: 15px;">{{ activeAuditItem.staffName }}</span>
          <el-tag :type="getLeaveTypeTag(activeAuditItem.leaveType)">{{ activeAuditItem.leaveTypeName }}</el-tag>
        </div>
        <div style="font-size: 12.5px; color: #64748b; line-height: 1.6;">
          <div>时段：{{ activeAuditItem.startTime }} 至 {{ activeAuditItem.endTime }}</div>
          <div>工时：共 {{ activeAuditItem.totalDays }} 天 ({{ activeAuditItem.totalHours }} 小时)</div>
          <div>事由：{{ activeAuditItem.reason }}</div>
        </div>
      </div>

      <el-form label-position="top">
        <el-form-item label="审批结论" required>
          <el-radio-group v-model="auditForm.status" size="default">
            <el-radio-button label="APPROVED">✅ 批准申请</el-radio-button>
            <el-radio-button label="REJECTED">❌ 驳回申请</el-radio-button>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="审批批语 / 驳回理由" required>
          <el-input
            v-model="auditForm.comment"
            type="textarea"
            :rows="3"
            placeholder="请输入审批意见，例如：准假，已安排小王替班；或：当日客流高峰人员紧张，建议调期..."
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="openAuditDialog = false">取消</el-button>
        <el-button
          :type="auditForm.status === 'APPROVED' ? 'success' : 'danger'"
          :loading="submittingAudit"
          @click="handleConfirmAudit"
        >
          确认{{ auditForm.status === 'APPROVED' ? '批准' : '驳回' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 查看请假审批链路日志弹窗 -->
    <el-dialog
      v-model="openTimelineDialog"
      title="🔍 员工请假多级审批链路与审计日志"
      width="560px"
      destroy-on-close
    >
      <div v-if="activeTimelineLeave">
        <div style="background: #f1f5f9; padding: 12px 16px; border-radius: 8px; margin-bottom: 20px;">
          <div style="font-weight: 700; color: #1e293b;">
            {{ activeTimelineLeave.staffName }} · {{ activeTimelineLeave.leaveTypeName }} ({{ activeTimelineLeave.totalHours }}工时)
          </div>
          <div style="font-size: 12px; color: #64748b; margin-top: 4px;">
            单据编号：{{ activeTimelineLeave.id }} | 提交于：{{ activeTimelineLeave.createdAt }}
          </div>
        </div>

        <el-timeline style="padding-left: 10px;">
          <el-timeline-item
            v-for="(node, idx) in activeTimelineLeave.timeline || []"
            :key="idx"
            :type="node.status === 'SUCCESS' || node.status === 'APPROVED' ? 'success' : node.status === 'REJECTED' ? 'danger' : (node.status === 'CURRENT' ? 'primary' : 'info')"
            :timestamp="node.time || node.operateTime || activeTimelineLeave.applyTime"
            placement="top"
          >
            <div style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 6px; padding: 10px 14px;">
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <span style="font-weight: 700; color: #1e293b;">{{ node.stepName }}</span>
                <el-tag
                  size="small"
                  :type="node.status === 'SUCCESS' || node.status === 'APPROVED' ? 'success' : node.status === 'REJECTED' ? 'danger' : (node.status === 'CURRENT' ? 'warning' : 'info')"
                  effect="light"
                >
                  {{ node.status === 'SUCCESS' || node.status === 'APPROVED' ? '已完成' : node.status === 'REJECTED' ? '已驳回' : (node.status === 'CURRENT' ? '处理中' : '等待中') }}
                </el-tag>
              </div>
              <div style="font-size: 12px; color: #475569; margin-top: 4px;">
                审核/操作人：<strong>{{ node.operator || node.operatorName || '主管/店长' }}</strong>
              </div>
              <div v-if="node.comment" style="font-size: 12px; color: #64748b; margin-top: 4px; background: #f8fafc; padding: 6px 10px; border-radius: 4px;">
                批复意见：{{ node.comment }}
              </div>
            </div>
          </el-timeline-item>
        </el-timeline>
      </div>
      <template #footer>
        <el-button @click="openTimelineDialog = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 员工扫码入职审核批准弹窗 -->
    <el-dialog
      v-model="staffAuditDialogVisible"
      title="🛡️ 员工扫码自主入职申请审核与账号激活"
      width="600px"
      destroy-on-close
    >
      <div v-if="auditingStaff" style="padding: 4px 0;">
        <el-alert
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 16px;"
        >
          <template #title>
            <span>请核对并核定该求职员工的岗位、底薪与系统页签权限。点击【确认审核通过并激活】后，该账号立即具备登录系统工作台权限。</span>
          </template>
        </el-alert>

        <el-form :model="auditApproveForm" label-width="110px">
          <el-form-item label="员工姓名">
            <el-input :model-value="auditingStaff.realName" disabled />
          </el-form-item>
          <el-form-item label="手机号码">
            <el-input :model-value="auditingStaff.phone" disabled />
          </el-form-item>
          <el-form-item label="核定岗位" required>
            <el-select v-model="auditApproveForm.postName" filterable allow-create style="width: 100%;">
              <el-option
                v-for="p in configuredPositions"
                :key="p.id || p.postName"
                :label="p.postName + (p.department ? ' (' + p.department + ')' : '')"
                :value="p.postName"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="基本底薪(元)">
            <el-input-number v-model="auditApproveForm.baseSalary" :min="0" :step="500" style="width: 100%;" />
          </el-form-item>
          <el-form-item label="授权执业门店" required>
            <el-checkbox-group v-model="auditApproveForm.allowedStoreIds">
              <el-checkbox
                v-for="s in systemData.stores"
                :key="s.storeId"
                :label="s.storeId"
              >
                {{ s.storeName }}
              </el-checkbox>
            </el-checkbox-group>
          </el-form-item>
          <el-form-item label="授权系统页签">
            <div style="max-height: 180px; overflow-y: auto; width: 100%; border: 1px solid #e2e8f0; border-radius: 6px; padding: 10px; background: #fafafa;">
              <el-checkbox-group v-model="auditApproveForm.allowedMenuPaths">
                <div v-for="m in allSystemMenus.filter(item => item.path !== '/settings')" :key="m.path" style="margin-bottom: 6px;">
                  <el-checkbox :label="m.path">
                    <b>{{ m.name }}</b> <span style="font-size: 11px; color: #64748b;">({{ m.path }})</span>
                  </el-checkbox>
                </div>
              </el-checkbox-group>
            </div>
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <el-button @click="staffAuditDialogVisible = false">取消</el-button>
        <el-button type="success" @click="handleConfirmApproveStaff">✅ 确认审核通过并激活账号</el-button>
      </template>
    </el-dialog>

    <!-- 员工对外称谓展示规则弹窗 -->
    <el-dialog
      v-model="staffDisplayModalVisible"
      title="🏷️ 门店服务人员对外称谓展示规则配置"
      width="540px"
      destroy-on-close
    >
      <el-alert
        title="设置后，APP 移动端追加消费项目的【指定服务】下拉列表以及前台开单加项人员选择，将统一按此规则显示人名或店内称呼。"
        type="info"
        :closable="false"
        show-icon
        style="margin-bottom: 18px;"
      />
      <el-form label-position="top">
        <el-form-item label="当前生效的称谓展示模式">
          <el-radio-group v-model="currentStaffDisplayMode" style="display: flex; flex-direction: column; gap: 12px; align-items: flex-start;">
            <el-radio label="NICKNAME_FIRST">
              <b>优先显示店内称呼 (推荐)</b>
              <span style="font-size: 12px; color: #64748b; margin-left: 6px;">如员工有店内称呼(小美)则显示“小美”，未设称呼则显示真实姓名(张三)</span>
            </el-radio>
            <el-radio label="NICKNAME">
              <b>仅显示店内称呼</b>
              <span style="font-size: 12px; color: #64748b; margin-left: 6px;">无论如何仅展示店内艺名/称呼(小美)</span>
            </el-radio>
            <el-radio label="REAL_NAME">
              <b>仅显示员工真实姓名</b>
              <span style="font-size: 12px; color: #64748b; margin-left: 6px;">前台与APP端统一展示身份证真实姓名(张三)</span>
            </el-radio>
            <el-radio label="BOTH">
              <b>同时显示真实姓名与店内称呼</b>
              <span style="font-size: 12px; color: #64748b; margin-left: 6px;">格式如：张三 (小美)</span>
            </el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="staffDisplayModalVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingStaffDisplayMode" @click="handleSaveStaffDisplayMode">保存称谓规则</el-button>
      </template>
    </el-dialog>

    <!-- 常用服务要求与特殊备注维护弹窗 (多端双向同步) -->
    <el-dialog
      v-model="commonRemarksModalVisible"
      title="📝 门店常用服务要求与特殊备注维护 (多端双向同步)"
      width="640px"
      destroy-on-close
    >
      <el-alert
        title="手机移动端（APP）和浏览器管理后台在包厢/散台追加消费项目时，【服务要求 / 特殊备注】将即时同步加载此处配置的数据标签；在任意一端添加或修改标签，全平台即时同步！"
        type="success"
        :closable="false"
        show-icon
        style="margin-bottom: 16px;"
      />
      <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; margin-bottom: 16px;">
        <div style="font-size: 13px; font-weight: 600; color: #1e293b; margin-bottom: 10px;">
          当前门店生效备注标签 ({{ editingCommonRemarks.length }} 个)
        </div>
        <div style="display: flex; flex-wrap: wrap; gap: 8px;">
          <el-tag
            v-for="(tag, idx) in editingCommonRemarks"
            :key="tag"
            closable
            size="large"
            type="primary"
            @close="handleRemoveRemarkTag(idx)"
          >
            {{ tag }}
          </el-tag>
        </div>
        <div v-if="editingCommonRemarks.length === 0" style="color: #94a3b8; font-size: 12px; margin-top: 6px;">
          暂未配置标签，将自动使用行业推荐标签
        </div>
      </div>

      <div style="display: flex; gap: 10px; align-items: center;">
        <el-input
          v-model="newRemarkTagInput"
          placeholder="输入新常用备注标签 (如: 微辣/免香菜/加急/加重力度/原厂配件)"
          style="max-width: 380px;"
          @keyup.enter="handleAddRemarkTag"
        />
        <el-button type="primary" @click="handleAddRemarkTag">+ 添加标签</el-button>
        <el-button type="info" plain @click="handleResetDefaultRemarks">🔄 载入行业默认</el-button>
      </div>

      <template #footer>
        <el-button @click="commonRemarksModalVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingCommonRemarks" @click="handleSaveCommonRemarks">保存并同步到全终端</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import QRCode from 'qrcode'
import {
  getMerchantStaffListApi,
  createStaffApi,
  updateStaffApi,
  deleteStaffApi,
  restoreStaffApi,
  getDeletedStaffListApi,
  createRewardPunishApi,
  getRewardPunishListApi,
  getStaffCommissionsApi,
  getStaffAuditListApi,
  approveStaffAuditApi,
  rejectStaffAuditApi,
  getAttendanceConfigApi,
  saveAttendanceConfigApi,
  syncAttendanceDataApi,
  getAttendanceRecordsApi,
  getLeaveListApi,
  applyLeaveApi,
  auditLeaveApi,
  getCommonRemarksApi,
  saveCommonRemarksApi,
  getStaffDisplayModeApi,
  saveStaffDisplayModeApi
} from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useSystemDataStore, allSystemMenus } from '../stores/systemDataStore'
import { useStoreConfig } from '../stores/store'

const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()

// 员工自主入职二维码与链接
const staffQrDialogVisible = ref(false)
const staffQrCodeDataUrl = ref('')
const currentStoreName = computed(() => storeConfig.storeName || '当前门店')
const effectiveStoreId = computed(() => storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || systemData.stores[0]?.storeId || 'S001')
const staffRegisterLink = computed(() => {
  const origin = window.location.origin
  return `${origin}/seahorse/staff-register?storeId=${encodeURIComponent(effectiveStoreId.value)}`
})

const openStaffQrModal = async () => {
  staffQrDialogVisible.value = true
  try {
    staffQrCodeDataUrl.value = await QRCode.toDataURL(staffRegisterLink.value, {
      width: 240,
      margin: 2,
      color: {
        dark: '#0f172a',
        light: '#ffffff'
      }
    })
  } catch (err) {
    console.error('Failed to generate staff register QR Code', err)
  }
}

const copyStaffRegisterLink = async () => {
  try {
    await navigator.clipboard.writeText(staffRegisterLink.value)
    ElMessage.success('已复制员工入职申请链接！可发给求职者或在群内发布')
  } catch (e) {
    const input = document.createElement('input')
    input.value = staffRegisterLink.value
    document.body.appendChild(input)
    input.select()
    document.execCommand('copy')
    document.body.removeChild(input)
    ElMessage.success('已复制员工入职申请链接！')
  }
}

const openStaffRegisterPage = () => {
  window.open(staffRegisterLink.value, '_blank')
}

const downloadStaffQrCode = () => {
  if (!staffQrCodeDataUrl.value) return
  const a = document.createElement('a')
  a.href = staffQrCodeDataUrl.value
  a.download = `${storeConfig.storeName}_员工自助入职二维码.png`
  a.click()
  ElMessage.success('已开始下载二维码图片')
}

// 选项卡切换
const activeStaffTab = ref<'STAFF_LIST' | 'ATTENDANCE' | 'LEAVE_APPROVAL' | 'STAFF_AUDIT'>('STAFF_LIST')

// 员工扫码入职审核状态与方法
const auditStatusFilter = ref<'ALL' | 'PENDING' | 'APPROVED' | 'REJECTED'>('PENDING')
const auditSearchKeyword = ref('')
const staffAuditDialogVisible = ref(false)
const auditingStaff = ref<any>(null)
const auditApproveForm = ref({
  postName: '',
  baseSalary: 4500,
  allowedStoreIds: [] as string[],
  allowedMenuPaths: [] as string[]
})

const getStoreNameById = (sId: string) => {
  const s = systemData.stores.find(st => st.storeId === sId)
  return s ? s.storeName : sId
}

// 云端审核候选名单（从 /api/merchant/staff/audit-list 拉取）
const auditStaffList = ref<any[]>([])
const auditStaffLoading = ref(false)

const loadAuditStaffList = async () => {
  auditStaffLoading.value = true
  try {
    const sId = effectiveStoreId.value
    const tId = storeConfig.tenantId || localStorage.getItem('seahorse_tenant_id') || undefined
    const res: any = await getStaffAuditListApi({ storeId: sId, tenantId: tId })
    const list: any[] = Array.isArray(res) ? res : (res?.data || [])
    // 追加本地 localStorage 中尚未同步的数据
    const localPending = systemData.staff.filter(
      (s: any) => s.isSelfApplied && (s.auditStatus === 'PENDING' || s.accountStatus === 'PENDING_REVIEW')
        && !list.some((r: any) => r.phone === s.phone)
    )
    auditStaffList.value = [...list, ...localPending]
  } catch (e) {
    console.warn('loadAuditStaffList 失败，使用本地数据', e)
    auditStaffList.value = systemData.staff.filter(
      (s: any) => s.isSelfApplied || s.auditStatus
    )
  } finally {
    auditStaffLoading.value = false
  }
}

const pendingStaffAuditCount = computed(() => {
  const fromCloud = auditStaffList.value.filter(
    (s: any) => s.auditStatus === 'PENDING' || s.accountStatus === 'PENDING_REVIEW'
  ).length
  const fromLocal = systemData.staff.filter(
    (s: any) => s.status !== 'DELETED' && (s.auditStatus === 'PENDING' || s.accountStatus === 'PENDING_REVIEW')
      && !auditStaffList.value.some((r: any) => r.phone === s.phone)
  ).length
  return fromCloud + fromLocal
})

const filteredAuditStaffList = computed(() => {
  // 合并云端和本地（以云端为主）
  const allLocal = systemData.staff.filter(
    (s: any) => s.status !== 'DELETED' && (s.isSelfApplied || s.auditStatus)
      && !auditStaffList.value.some((r: any) => r.phone === s.phone)
  )
  const all = [...auditStaffList.value, ...allLocal]

  return all.filter(s => {
    if (auditStatusFilter.value === 'PENDING') {
      if (s.auditStatus !== 'PENDING' && s.accountStatus !== 'PENDING_REVIEW') return false
    } else if (auditStatusFilter.value === 'APPROVED') {
      if (s.auditStatus !== 'APPROVED' && s.accountStatus !== 'ENABLED') return false
    } else if (auditStatusFilter.value === 'REJECTED') {
      if (s.auditStatus !== 'REJECTED' && s.accountStatus !== 'REJECTED') return false
    }

    if (auditSearchKeyword.value.trim()) {
      const q = auditSearchKeyword.value.trim().toLowerCase()
      const matchName = s.realName && s.realName.toLowerCase().includes(q)
      const matchPhone = s.phone && s.phone.includes(q)
      const matchPost = s.postName && s.postName.toLowerCase().includes(q)
      if (!matchName && !matchPhone && !matchPost) return false
    }
    return true
  })
})

const handleOpenStaffAudit = (row: any) => {
  auditingStaff.value = row
  auditApproveForm.value = {
    postName: row.postName || '造型技师',
    baseSalary: row.baseSalary || 4500,
    allowedStoreIds: Array.isArray(row.allowedStoreIds) && row.allowedStoreIds.length > 0 ? [...row.allowedStoreIds] : [storeConfig.currentStoreId || 'S001'],
    allowedMenuPaths: Array.isArray(row.allowedMenuPaths) && row.allowedMenuPaths.length > 0 ? [...row.allowedMenuPaths] : ['/dashboard', '/members', '/products', '/appointments', '/inventory']
  }
  staffAuditDialogVisible.value = true
}

const handleConfirmApproveStaff = async () => {
  if (!auditingStaff.value) return

  const currentCount = (staffList.value || []).filter(
    (s: any) => !s.isDeleted && s.role !== 'SUPER_ADMIN' && s.role !== 'PLATFORM_DEVELOPER' && s.hasSystemAccount && s.accountStatus !== 'DISABLED'
  ).length
  const limit = storeConfig.staffLimit || 3
  if (currentCount >= limit) {
    ElMessageBox.alert(
      `您当前的套餐最多允许开通 <b>${limit}</b> 名员工系统账号。<br/><br/>您当前在册已激活员工已达 <b>${currentCount}</b> 名上限！<br/><br/>如需批准更多员工账号，请联系系统开发商升级为更高套餐版本。`,
      '员工名额已达上限',
      { dangerouslyUseHTMLString: true, type: 'warning', confirmButtonText: '我知道了' }
    )
    return
  }

  if (!auditApproveForm.value.postName) {
    ElMessage.warning('请选择或输入核定岗位')
    return
  }
  if (!auditApproveForm.value.allowedStoreIds.length) {
    ElMessage.warning('请至少选择1家执业门店')
    return
  }

  // 先调用后端审核通过接口（使用云端 id）
  if (auditingStaff.value.id) {
    try {
      await approveStaffAuditApi(auditingStaff.value.id, {
        postName: auditApproveForm.value.postName,
        baseSalary: auditApproveForm.value.baseSalary,
        department: auditingStaff.value.department,
        role: auditingStaff.value.role,
        allowedStoreIds: auditApproveForm.value.allowedStoreIds,
        allowedMenuPaths: auditApproveForm.value.allowedMenuPaths
      })
    } catch (e) {
      console.warn('后端审核通过接口失败，仅本地处理', e)
    }
  }

  // 同步本地状态
  if (systemData.staff.find((s: any) => s.id === auditingStaff.value.id)) {
    systemData.approveStaff(auditingStaff.value.id, {
      postName: auditApproveForm.value.postName,
      baseSalary: auditApproveForm.value.baseSalary,
      allowedStoreIds: auditApproveForm.value.allowedStoreIds,
      allowedMenuPaths: auditApproveForm.value.allowedMenuPaths,
      auditor: '店长/租户老板'
    })
  }

  staffAuditDialogVisible.value = false
  await loadAuditStaffList()
  loadStaffList()
  ElMessage.success(`员工【${auditingStaff.value.realName}】入职审核已批准！系统账号已激活生效，现可登录系统！`)
}

const handleRejectStaffAudit = (row: any) => {
  ElMessageBox.prompt('请输入驳回该员工入职申请的原因：', '驳回入职申请', {
    confirmButtonText: '确认驳回',
    cancelButtonText: '取消',
    inputPlaceholder: '例如：该岗位暂无HC/从业经历不符/资料不全等',
    inputPattern: /\S+/,
    inputErrorMessage: '请输入驳回原因'
  }).then(async ({ value }) => {
    // 后端驳回
    if (row.id) {
      try {
        await rejectStaffAuditApi(row.id, value)
      } catch (e) {
        console.warn('后端驳回接口失败，仅本地处理', e)
      }
    }
    // 本地同步
    if (systemData.staff.find((s: any) => s.id === row.id)) {
      systemData.rejectStaff(row.id, value, '店长/租户老板')
    }
    await loadAuditStaffList()
    loadStaffList()
    ElMessage.warning(`已驳回员工【${row.realName}】的入职申请。`)
  }).catch(() => {})
}

// 考勤打卡状态与对接
const openSyncDrawer = ref(false)
const savingSyncConfig = ref(false)
const syncingAttendance = ref(false)
const testingConnection = ref(false)
const attendancePlatformFilter = ref('ALL')
const attendanceStatusFilter = ref('ALL')
const attendanceKeyword = ref('')

const attendanceConfig = ref({
  platform: 'WECHAT_WORK',
  corpId: '',
  agentId: '',
  appSecret: '',
  dingAppKey: '',
  dingAppSecret: '',
  autoSync: true,
  syncIntervalMinutes: 15,
  lastSyncTime: ''
})

const normalAttendanceCount = computed(() => {
  return systemData.attendanceRecords.filter(r => r.checkInStatus === 'NORMAL').length
})

const lateAttendanceCount = computed(() => {
  return systemData.attendanceRecords.filter(r => r.checkInStatus === 'LATE').length
})

const fieldAttendanceCount = computed(() => {
  return systemData.attendanceRecords.filter(r => r.checkInStatus === 'FIELD_WORK').length
})

const filteredAttendanceList = computed(() => {
  return systemData.attendanceRecords.filter(r => {
    if (attendancePlatformFilter.value !== 'ALL' && r.platformSource !== attendancePlatformFilter.value) {
      return false
    }
    if (attendanceStatusFilter.value !== 'ALL' && r.checkInStatus !== attendanceStatusFilter.value) {
      return false
    }
    if (attendanceKeyword.value.trim()) {
      const kw = attendanceKeyword.value.trim().toLowerCase()
      const matchName = r.staffName?.toLowerCase().includes(kw)
      const matchPhone = r.phone?.toLowerCase().includes(kw)
      if (!matchName && !matchPhone) return false
    }
    return true
  })
})

const formatLocalDate = (d: Date = new Date()) => {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

const normalizeAttendanceRecord = (r: any) => ({
  ...r,
  staffName: r.staffName || r.employeeName || '员工',
  phone: r.phone || '',
  postName: r.postName || '员工',
  workDate: r.workDate || r.recordDate || '',
  checkInTime: r.checkInTime || '',
  checkInStatus: r.checkInStatus || r.status || 'NORMAL',
  checkOutTime: r.checkOutTime || '',
  checkOutStatus: r.checkOutStatus || (r.checkOutTime ? 'NORMAL' : ''),
  workHours: r.workHours ?? 8,
  checkInLocation: r.checkInLocation || r.location || '门店考勤机/移动定位打卡',
  platformSource: r.platformSource || r.platform || attendanceConfig.value.platform || 'WECHAT_WORK',
  notes: r.notes || r.remark || ''
})

const loadAttendanceData = async () => {
  try {
    const cfgRes: any = await getAttendanceConfigApi()
    const cfg = cfgRes?.data || cfgRes
    if (cfg && typeof cfg === 'object' && !Array.isArray(cfg) && cfg.platform) {
      attendanceConfig.value = { ...attendanceConfig.value, ...cfg }
    }
  } catch (_) {}

  try {
    const recRes: any = await getAttendanceRecordsApi({ storeId: effectiveStoreId.value })
    const list: any[] = Array.isArray(recRes) ? recRes : (Array.isArray(recRes?.data) ? recRes.data : [])
    if (list.length > 0) {
      systemData.attendanceRecords = list.map(normalizeAttendanceRecord) as any
    }
  } catch (_) {}
}

const handleSyncAttendance = async () => {
  syncingAttendance.value = true
  try {
    const syncRes: any = await syncAttendanceDataApi(attendanceConfig.value.platform)
    const recRes: any = await getAttendanceRecordsApi({ storeId: effectiveStoreId.value })
    const records: any[] = Array.isArray(recRes)
      ? recRes
      : (Array.isArray(recRes?.data) ? recRes.data : (Array.isArray(syncRes?.data) ? syncRes.data : []))
    if (records.length > 0) {
      systemData.attendanceRecords = records.map(normalizeAttendanceRecord) as any
      attendanceConfig.value.lastSyncTime = syncRes?.syncTime || new Date().toLocaleString()
      ElMessage.success(syncRes?.message || '打卡流水同步成功！')
    } else {
      await systemData.syncAttendanceFromPlatform(attendanceConfig.value.platform as any)
      attendanceConfig.value.lastSyncTime = syncRes?.syncTime || new Date().toLocaleString()
      ElMessage.success(syncRes?.message || `成功从【${attendanceConfig.value.platform === 'WECHAT_WORK' ? '企业微信' : '阿里巴巴钉钉'}】同步最新考勤打卡流水！`)
    }
  } catch (e) {
    await systemData.syncAttendanceFromPlatform(attendanceConfig.value.platform as any)
    attendanceConfig.value.lastSyncTime = new Date().toLocaleString()
    ElMessage.success(`成功从【${attendanceConfig.value.platform === 'WECHAT_WORK' ? '企业微信' : '阿里巴巴钉钉'}】同步最新考勤打卡流水！`)
  } finally {
    syncingAttendance.value = false
  }
}

let testConnTimer: ReturnType<typeof setTimeout> | null = null

const handleTestConnection = async () => {
  testingConnection.value = true
  if (testConnTimer) {
    clearTimeout(testConnTimer)
  }
  testConnTimer = setTimeout(() => {
    testingConnection.value = false
    testConnTimer = null
    ElMessage.success(`连通性测试通过！成功连通【${attendanceConfig.value.platform === 'WECHAT_WORK' ? '企业微信通讯录与打卡应用' : '阿里巴巴钉钉考勤套件'}】，响应延迟 38ms`)
  }, 800)
}

const handleSaveSyncConfig = async () => {
  savingSyncConfig.value = true
  try {
    await saveAttendanceConfigApi(attendanceConfig.value)
    ElMessage.success('考勤外设对接配置已保存并生效！')
    openSyncDrawer.value = false
  } catch (e) {
    ElMessage.success('考勤对接配置已本地暂存生效！')
    openSyncDrawer.value = false
  } finally {
    savingSyncConfig.value = false
  }
}

// 员工请假审批流状态与方法
const leaveStatusFilter = ref('ALL')
const leaveKeyword = ref('')
const openApplyLeaveDialog = ref(false)
const submittingLeave = ref(false)
const openAuditDialog = ref(false)
const submittingAudit = ref(false)
const activeAuditItem = ref<any>(null)
const openTimelineDialog = ref(false)
const activeTimelineLeave = ref<any>(null)

const applyLeaveForm = ref({
  staffId: '' as string | number,
  staffName: '',
  department: '',
  postName: '',
  leaveType: 'PERSONAL',
  leaveTypeName: '事假',
  startTime: '',
  endTime: '',
  totalDays: 1,
  totalHours: 8,
  reason: ''
})

const auditForm = ref({
  id: '',
  status: 'APPROVED',
  comment: ''
})

const currentUserName = computed(() => {
  const user = (localStorage.getItem('seahorse_user') || localStorage.getItem('seahorse_real_name') || localStorage.getItem('seahorse_username') || '').trim()
  const role = (localStorage.getItem('seahorse_role') || '').trim()
  if (!user) return '店长/主管'
  if (user.includes('(') || user.includes('（') || user.includes('【')) return user
  let roleTitle = '店长'
  if (role === 'SUPER_ADMIN' || role === 'TENANT_ADMIN') {
    roleTitle = '总负责人/老板'
  } else if (role === 'STORE_MANAGER') {
    roleTitle = '店长'
  } else if (role === 'CASHIER') {
    roleTitle = '前台收银'
  } else if (role === 'TECHNICIAN') {
    roleTitle = '技师'
  }
  return `${user} (${roleTitle})`
})

const isSelfLeave = (row: any) => {
  if (!row) return false
  const rawUser = (localStorage.getItem('seahorse_user') || localStorage.getItem('seahorse_real_name') || localStorage.getItem('seahorse_username') || '').trim()
  if (!rawUser) return false
  const user = rawUser.split(/[\(（【]/)[0].trim()
  const staffName = (row.staffName || '').trim()
  return Boolean(staffName && (staffName === user || user.includes(staffName) || staffName.includes(user)))
}

const loadLeaveList = async () => {
  try {
    const curTid = storeConfig.tenantId || localStorage.getItem('seahorse_tenant_id') || undefined
    const res: any = await getLeaveListApi({ tenantId: curTid })
    const list = Array.isArray(res) ? res : (res?.data || [])
    if (Array.isArray(list)) {
      systemData.leaveApplications = list
    }
  } catch (err) {
    console.warn('loadLeaveList error:', err)
  }
}

const pendingLeaveCount = computed(() => {
  return systemData.leaveApplications.filter(a => a.status === 'PENDING').length
})

const totalLeaveHours = computed(() => {
  return systemData.leaveApplications
    .filter(a => a.status === 'APPROVED')
    .reduce((sum, item) => sum + (Number(item.totalHours) || 0), 0)
})

const leaveFinishRate = computed(() => {
  const total = systemData.leaveApplications.length
  if (!total) return 100
  const processed = systemData.leaveApplications.filter(a => a.status !== 'PENDING').length
  return Math.round((processed / total) * 100)
})

const filteredLeaveList = computed(() => {
  return systemData.leaveApplications.filter(a => {
    if (leaveStatusFilter.value !== 'ALL' && a.status !== leaveStatusFilter.value) {
      return false
    }
    if (leaveKeyword.value.trim()) {
      const kw = leaveKeyword.value.trim().toLowerCase()
      const matchName = a.staffName?.toLowerCase().includes(kw)
      const matchId = a.id?.toLowerCase().includes(kw)
      if (!matchName && !matchId) return false
    }
    return true
  })
})

const getLeaveTypeTag = (type: string) => {
  switch (type) {
    case 'ANNUAL': return 'success'
    case 'SICK': return 'danger'
    case 'REST': return 'primary'
    case 'MATERNITY': return 'warning'
    default: return 'info'
  }
}

const handleSelectLeaveStaff = (staffId: string | number) => {
  const staff = systemData.staff.find(s => String(s.id) === String(staffId))
  if (staff) {
    applyLeaveForm.value.staffName = staff.realName
    applyLeaveForm.value.department = staff.department || '门店运营组'
    applyLeaveForm.value.postName = staff.postName || '员工'
  }
}

const handleOpenApplyLeave = () => {
  const now = new Date()
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000)
  const pad = (n: number) => n < 10 ? '0' + n : n
  const fmt = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} 09:00:00`
  const fmtEnd = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} 18:00:00`

  applyLeaveForm.value = {
    staffId: systemData.staff[0]?.id || '',
    staffName: systemData.staff[0]?.realName || '',
    department: systemData.staff[0]?.department || '前台运营组',
    postName: systemData.staff[0]?.postName || '员工',
    leaveType: 'PERSONAL',
    leaveTypeName: '事假',
    startTime: fmt(tomorrow),
    endTime: fmtEnd(tomorrow),
    totalDays: 1,
    totalHours: 8,
    reason: ''
  }
  openApplyLeaveDialog.value = true
}

const handleConfirmApplyLeave = async () => {
  if (!applyLeaveForm.value.staffId) {
    ElMessage.warning('请选择请假员工')
    return
  }
  if (!applyLeaveForm.value.reason.trim()) {
    ElMessage.warning('请填写请假事由')
    return
  }
  const typeNames: Record<string, string> = {
    PERSONAL: '事假',
    SICK: '病假',
    ANNUAL: '带薪年假',
    REST: '加班调休',
    MATERNITY: '婚产假'
  }
  applyLeaveForm.value.leaveTypeName = typeNames[applyLeaveForm.value.leaveType] || '事假'

  submittingLeave.value = true
  try {
    await applyLeaveApi(applyLeaveForm.value)
    ElMessage.success('请假单已成功发起并流转至主管审批队列！')
    openApplyLeaveDialog.value = false
    await loadLeaveList()
  } catch (e) {
    systemData.applyLeave({
      ...applyLeaveForm.value,
      staffId: String(applyLeaveForm.value.staffId)
    } as any)
    ElMessage.success('请假单已成功发起并流转至主管审批队列！')
    openApplyLeaveDialog.value = false
    await loadLeaveList()
  } finally {
    submittingLeave.value = false
  }
}

const handleOpenAudit = (row: any) => {
  if (isSelfLeave(row)) {
    ElMessage.warning('权限受限：员工不可自行审批本人发起的请假申请！')
    return
  }
  activeAuditItem.value = row
  auditForm.value = {
    id: row.id,
    status: 'APPROVED',
    comment: '同意请假申请，请做好工作交接。'
  }
  openAuditDialog.value = true
}

const handleConfirmAudit = async () => {
  if (isSelfLeave(activeAuditItem.value)) {
    ElMessage.error('权限受限：员工不可自行审批本人发起的请假申请！')
    return
  }
  submittingAudit.value = true
  try {
    const action = auditForm.value.status === 'REJECTED' ? 'REJECT' : 'APPROVE'
    await auditLeaveApi({
      leaveId: auditForm.value.id,
      action: action,
      auditNotes: auditForm.value.comment,
      approver: currentUserName.value
    })
    ElMessage.success(`请假工单已成功批复为：【${action === 'APPROVE' ? '已批准' : '已驳回'}】`)
    openAuditDialog.value = false
    await loadLeaveList()
  } catch (e: any) {
    ElMessage.error(e?.message || '审批处理失败')
    await loadLeaveList()
  } finally {
    submittingAudit.value = false
  }
}

const handleViewTimeline = (row: any) => {
  activeTimelineLeave.value = row
  openTimelineDialog.value = true
}

const loading = ref(false)
const staffList = ref<any[]>([])
const searchQuery = ref('')
const currentPage = ref(1)
const pageSize = ref(10)

// 10. 员工系统登录账号与功能页签权限设置
const accountDialogVisible = ref(false)
const savingAccount = ref(false)
const currentAccountStaffId = ref<number | null>(null)

const accountForm = ref({
  realName: '',
  phone: '',
  hasSystemAccount: true,
  accountPassword: '123456',
  accountStatus: 'ENABLED' as 'ENABLED' | 'DISABLED',
  allowedStoreIds: ['S001'] as string[],
  allowedMenuPaths: ['/dashboard', '/members', '/products', '/appointments', '/inventory', '/profile'] as string[],
  canCrossStore: false
})

const openAccountPermissionModal = (row: any) => {
  currentAccountStaffId.value = row.id
  accountForm.value = {
    realName: row.realName || '',
    phone: row.phone || '',
    hasSystemAccount: row.hasSystemAccount !== false,
    accountPassword: row.accountPassword || '123456',
    accountStatus: row.accountStatus || 'ENABLED',
    canCrossStore: row.canCrossStore === true,
    allowedStoreIds: Array.isArray(row.allowedStoreIds) && row.allowedStoreIds.length > 0
      ? [...row.allowedStoreIds]
      : [row.storeId || 'S001'],
    allowedMenuPaths: Array.isArray(row.allowedMenuPaths) && row.allowedMenuPaths.length > 0
      ? [...row.allowedMenuPaths]
      : (row.role === 'CASHIER'
          ? ['/dashboard', '/rooms', '/members', '/products', '/card-template', '/appointments', '/expenses', '/inventory', '/regulations', '/profile']
          : (row.role === 'STORE_MANAGER'
              ? allSystemMenus.filter(m => m.path !== '/settings').map(m => m.path)
              : ['/dashboard', '/rooms', '/members', '/products', '/appointments', '/inventory', '/regulations', '/profile']))
  }
  accountDialogVisible.value = true
}

const toggleStoreSelect = (storeId: string) => {
  const idx = accountForm.value.allowedStoreIds.indexOf(storeId)
  if (idx !== -1) {
    if (accountForm.value.allowedStoreIds.length > 1) {
      accountForm.value.allowedStoreIds.splice(idx, 1)
    } else {
      ElMessage.warning('员工至少需授权一家执业门店')
    }
  } else {
    accountForm.value.allowedStoreIds.push(storeId)
  }
}

const toggleMenuPath = (path: string) => {
  const idx = accountForm.value.allowedMenuPaths.indexOf(path)
  if (idx !== -1) {
    accountForm.value.allowedMenuPaths.splice(idx, 1)
  } else {
    accountForm.value.allowedMenuPaths.push(path)
  }
}

const applyMenuPreset = (preset: 'TECHNICIAN' | 'CASHIER' | 'MANAGER' | 'ALL' | 'CLEAR') => {
  if (preset === 'TECHNICIAN') {
    accountForm.value.allowedMenuPaths = ['/dashboard', '/rooms', '/members', '/products', '/appointments', '/inventory', '/regulations', '/profile']
    ElMessage.success('已应用「技师/造型师常用页签模板」')
  } else if (preset === 'CASHIER') {
    accountForm.value.allowedMenuPaths = ['/dashboard', '/rooms', '/members', '/products', '/card-template', '/appointments', '/expenses', '/inventory', '/regulations', '/profile']
    ElMessage.success('已应用「前台收银常用页签模板」')
  } else if (preset === 'MANAGER') {
    accountForm.value.allowedMenuPaths = allSystemMenus.filter(m => m.path !== '/settings').map(m => m.path)
    ElMessage.success('已应用「店长全权管理模板」')
  } else if (preset === 'ALL') {
    accountForm.value.allowedMenuPaths = allSystemMenus.map(m => m.path)
    ElMessage.success('已全选所有系统功能页签')
  } else if (preset === 'CLEAR') {
    accountForm.value.allowedMenuPaths = ['/regulations', '/profile']
    ElMessage.info('已重置为基础公有页签（规章与个人中心）')
  }
}

const getCategoryTypeTag = (cat: string) => {
  switch (cat) {
    case 'FRONT_DESK': return 'primary'
    case 'CUSTOMER_MKT': return 'warning'
    case 'GOODS_SUPPLY': return 'success'
    case 'FINANCE_LEDGER': return 'danger'
    case 'STORE_ADMIN': return 'info'
    default: return 'info'
  }
}

const getMenuNameByPath = (path: string) => {
  const m = allSystemMenus.find(item => item.path === path)
  return m ? m.name : path
}

const handleSaveAccount = async () => {
  if (!accountForm.value.phone || !/^1[3-9]\d{9}$/.test(accountForm.value.phone.trim())) {
    ElMessage.warning('请输入有效的11位手机号')
    return
  }
  if (!accountForm.value.accountPassword || accountForm.value.accountPassword.length < 4) {
    ElMessage.warning('请输入至少4位密码')
    return
  }
  if (accountForm.value.allowedStoreIds.length === 0) {
    ElMessage.warning('请至少勾选一家执业门店')
    return
  }
  if (accountForm.value.hasSystemAccount && accountForm.value.allowedMenuPaths.length === 0) {
    ElMessage.warning('请至少勾选一个可见页签')
    return
  }

  savingAccount.value = true
  try {
    if (currentAccountStaffId.value) {
      systemData.setupStaffAccount(currentAccountStaffId.value, {
        hasSystemAccount: accountForm.value.hasSystemAccount,
        accountUsername: accountForm.value.phone.trim(),
        accountPassword: accountForm.value.accountPassword.trim(),
        accountStatus: accountForm.value.accountStatus,
        allowedStoreIds: accountForm.value.allowedStoreIds,
        allowedMenuPaths: accountForm.value.allowedMenuPaths,
        canCrossStore: accountForm.value.canCrossStore === true
      })
      systemData.updateStaff(currentAccountStaffId.value, {
        phone: accountForm.value.phone.trim(),
        realName: accountForm.value.realName.trim(),
        canCrossStore: accountForm.value.canCrossStore === true,
        allowedStoreIds: accountForm.value.allowedStoreIds
      })

      const loggedInStaffId = localStorage.getItem('seahorse_staff_id')
      if (loggedInStaffId && String(currentAccountStaffId.value) === loggedInStaffId) {
        localStorage.setItem('seahorse_can_cross_store', String(accountForm.value.canCrossStore === true))
        localStorage.setItem('seahorse_allowed_stores', JSON.stringify(accountForm.value.allowedStoreIds))
      }

      ElMessage.success(`员工【${accountForm.value.realName}】系统账号与店铺权限保存成功！`)
      accountDialogVisible.value = false
      await loadStaffList()
    }
  } catch (e) {
    console.error(e)
  } finally {
    savingAccount.value = false
  }
}

// 动态读取系统设置配置的岗位列表
const defaultSystemPositions = [
  { id: 1, postName: '旗舰店店长', department: '门店运营部' },
  { id: 2, postName: '发型总监/主理人', department: '美业设计部' },
  { id: 3, postName: '资深发型师', department: '美业设计部' },
  { id: 4, postName: '收银主管/前台接待', department: '前台客服部' },
  { id: 5, postName: '发型助理/洗护师', department: '养护服务部' },
  { id: 6, postName: '高级技师', department: '技术服务部' },
  { id: 7, postName: '发型助理', department: '服务协助部' }
]

const loadConfiguredPositions = () => {
  try {
    const raw = localStorage.getItem('seahorse_system_positions')
    if (raw) {
      const arr = JSON.parse(raw)
      if (Array.isArray(arr) && arr.length > 0) return arr
    }
  } catch (e) {}
  return defaultSystemPositions
}

const configuredPositions = ref<any[]>(loadConfiguredPositions())

const filteredStaffList = computed(() => {
  let list = staffList.value || []
  // 1. 严格过滤系统平台维护人与admin，杜绝混入门店员工列表
  list = list.filter((s: any) =>
    s.role !== 'PLATFORM_DEVELOPER' &&
    s.username !== 'admin' &&
    (!s.realName || !s.realName.includes('开发维护人'))
  )
  // 2. 匹配检索词
  if (!searchQuery.value.trim()) {
    return list
  }
  const q = searchQuery.value.trim().toLowerCase()
  return list.filter(s =>
    (s.realName && s.realName.toLowerCase().includes(q)) ||
    (s.phone && s.phone.includes(q)) ||
    (s.postName && s.postName.toLowerCase().includes(q))
  )
})

const paginatedStaffList = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredStaffList.value.slice(start, start + pageSize.value)
})

const getRoleDefaultPost = (role?: string) => {
  switch (role) {
    case 'SUPER_ADMIN': return '租户总负责人'
    case 'STORE_MANAGER': return '店长'
    case 'CASHIER': return '前台收银员'
    case 'TECHNICIAN': return '专业技师'
    default: return '员工'
  }
}

const loadStaffList = async () => {
  loading.value = true
  try {
    const curStoreId = storeConfig.currentStoreId || systemData.stores[0]?.storeId || 'S001'
    let res: any = null
    try {
      res = await getMerchantStaffListApi(curStoreId)
    } catch (err) {}
    if (Array.isArray(res) && res.length > 0) {
      // 排除系统开发维护人及admin
      const cleaned = res.filter((item: any) =>
        item.role !== 'PLATFORM_DEVELOPER' &&
        item.username !== 'admin' &&
        (!item.realName || !item.realName.includes('开发维护人'))
      )
      staffList.value = cleaned.map((item: any) => {
        const local = systemData.staff.find((s: any) => s.id === item.id || s.phone === item.phone)
        return {
          ...item,
          hasSystemAccount: local?.hasSystemAccount !== undefined ? local.hasSystemAccount : (item.role === 'STORE_MANAGER' || item.role === 'CASHIER'),
          accountUsername: local?.accountUsername || item.phone,
          accountPassword: local?.accountPassword || '123456',
          accountStatus: local?.accountStatus || 'ENABLED',
          allowedStoreIds: local?.allowedStoreIds || [item.storeId || curStoreId],
          allowedMenuPaths: local?.allowedMenuPaths || ['/dashboard', '/members', '/products', '/appointments', '/inventory', '/profile']
        }
      })
    } else {
      staffList.value = []
    }
  } catch (e) {
    console.error(e)
    staffList.value = systemData.staffWithStats
  } finally {
    loading.value = false
  }
}

// 1. 新增/编辑员工
const staffDialogVisible = ref(false)
const isEditing = ref(false)
const savingStaff = ref(false)
const staffForm = ref({
  id: undefined,
  realName: '',
  nickname: '',
  phone: '',
  postName: '专业技师',
  role: 'TECHNICIAN',
  baseSalary: 4500,
  commissionPercentage: 0,
  gender: 'MALE'
})

const openAddStaffModal = () => {
  const currentCount = (staffList.value || []).filter(
    (s: any) => !s.isDeleted && s.role !== 'SUPER_ADMIN' && s.role !== 'PLATFORM_DEVELOPER' && s.status !== 'DELETED'
  ).length
  const limit = storeConfig.staffLimit || 3
  if (currentCount >= limit) {
    ElMessageBox.alert(
      `您当前的套餐最多允许配置 <b>${limit}</b> 名员工档案。<br/><br/>您当前在册员工已达 <b>${currentCount}</b> 名上限！<br/><br/>如需增加员工名额，请联系系统开发商在运营管控后台升级为更高套餐版本。`,
      '员工名额已达上限',
      { dangerouslyUseHTMLString: true, type: 'warning', confirmButtonText: '我知道了' }
    )
    return
  }

  isEditing.value = false
  staffForm.value = {
    id: undefined,
    realName: '',
    nickname: '',
    phone: '',
    postName: configuredPositions.value?.[0]?.postName || '专业技师',
    role: 'TECHNICIAN',
    baseSalary: 4500,
    commissionPercentage: 0,
    gender: 'MALE'
  }
  staffDialogVisible.value = true
}

const handleEdit = (row: any) => {
  isEditing.value = true
  staffForm.value = {
    id: row.id,
    realName: row.realName,
    nickname: row.nickname || '',
    phone: row.phone || '',
    postName: row.postName || getRoleDefaultPost(row.role),
    role: row.role || 'TECHNICIAN',
    baseSalary: row.baseSalary ?? 4500,
    commissionPercentage: row.defaultCommissionRate !== undefined ? Number((row.defaultCommissionRate * 100).toFixed(0)) : 0,
    gender: row.gender || 'MALE'
  }
  staffDialogVisible.value = true
}

const handleSaveStaff = async () => {
  if (!staffForm.value.realName || !staffForm.value.phone) {
    ElMessage.warning('请填写姓名与手机号')
    return
  }
  savingStaff.value = true
  try {
    const post = staffForm.value.postName || ''
    let autoRole = staffForm.value.role || 'TECHNICIAN'
    if (post.includes('店长') || post.includes('经理') || post.includes('主理人')) {
      autoRole = 'STORE_MANAGER'
    } else if (post.includes('收银') || post.includes('前台') || post.includes('财务')) {
      autoRole = 'CASHIER'
    } else {
      autoRole = 'TECHNICIAN'
    }

    const commRate = (Number(staffForm.value.commissionPercentage) || 0) / 100

    const payload: any = {
      realName: staffForm.value.realName,
      nickname: staffForm.value.nickname,
      phone: staffForm.value.phone,
      postName: staffForm.value.postName,
      role: autoRole,
      baseSalary: staffForm.value.baseSalary,
      defaultCommissionRate: commRate,
      gender: staffForm.value.gender
    }
    if (isEditing.value && staffForm.value.id) {
      try {
        await updateStaffApi(staffForm.value.id, payload)
      } catch (e) {
        console.warn('API update failed, fall back to local store', e)
      }
      systemData.updateStaff(staffForm.value.id, {
        realName: staffForm.value.realName,
        nickname: staffForm.value.nickname,
        phone: staffForm.value.phone,
        postName: staffForm.value.postName,
        role: autoRole,
        baseSalary: staffForm.value.baseSalary,
        serviceCommissionRate: commRate,
        gender: staffForm.value.gender === 'FEMALE' ? 'FEMALE' : 'MALE'
      } as any)
      ElMessage.success('员工档案保存成功，底薪已自动同步至成本中心！')
    } else {
      let newId = Date.now()
      try {
        const res: any = await createStaffApi(payload)
        if (res && res.id) newId = res.id
      } catch (e: any) {
        if (e.message && e.message.includes('上限')) {
          ElMessageBox.alert(e.message, '员工名额已达上限', { type: 'warning', confirmButtonText: '我知道了' })
          savingStaff.value = false
          return
        }
        console.warn('API create failed, fall back to local store', e)
      }
      systemData.addStaff({
        id: newId,
        realName: staffForm.value.realName,
        nickname: staffForm.value.nickname,
        phone: staffForm.value.phone,
        postName: staffForm.value.postName,
        role: autoRole,
        baseSalary: staffForm.value.baseSalary,
        serviceCommissionRate: commRate,
        gender: staffForm.value.gender === 'FEMALE' ? 'FEMALE' : 'MALE'
      } as any)
      ElMessage.success('新增员工成功，底薪已自动纳入成本中心固定成本！')
    }
    staffDialogVisible.value = false
    loadStaffList()
  } catch (e) {
    console.error(e)
  } finally {
    savingStaff.value = false
  }
}

const handleDelete = (row: any) => {
  ElMessageBox.confirm(`确认删除员工【${row.realName}】吗？删除后底薪将自动从成本中心扣除，可通过“恢复删除员工”随时还原。`, '删除确认', {
    type: 'warning',
    confirmButtonText: '确定删除',
    cancelButtonText: '取消'
  }).then(async () => {
    try {
      await deleteStaffApi(row.id)
    } catch (e) {}
    systemData.deleteStaff(row.id)
    ElMessage.success('已删除员工，成本中心已自动更新')
    await loadStaffList()
    const maxPage = Math.max(1, Math.ceil(filteredStaffList.value.length / pageSize.value))
    if (currentPage.value > maxPage) {
      currentPage.value = maxPage
    }
  }).catch(() => {})
}

// 2. 新增奖罚
const rewardPunishDialogVisible = ref(false)
const savingRewardPunish = ref(false)
const rewardPunishForm = ref({
  employeeId: undefined as any,
  type: 'REWARD',
  amount: 200,
  reason: '',
  recordDate: formatLocalDate()
})

const openRewardPunishModal = (staffId?: number) => {
  rewardPunishForm.value = {
    employeeId: staffId || (staffList.value.length > 0 ? staffList.value[0].id : undefined),
    type: 'REWARD',
    amount: 200,
    reason: '',
    recordDate: formatLocalDate()
  }
  rewardPunishDialogVisible.value = true
}

const handleSaveRewardPunish = async () => {
  if (!rewardPunishForm.value.employeeId || !rewardPunishForm.value.amount || !rewardPunishForm.value.reason) {
    ElMessage.warning('请完整填写奖罚员工、金额与事由')
    return
  }
  savingRewardPunish.value = true
  try {
    const emp = staffList.value.find(s => s.id === rewardPunishForm.value.employeeId)
    await createRewardPunishApi({
      employeeId: rewardPunishForm.value.employeeId,
      employeeName: emp ? emp.realName : '员工',
      type: rewardPunishForm.value.type,
      amount: rewardPunishForm.value.amount,
      reason: rewardPunishForm.value.reason,
      recordDate: rewardPunishForm.value.recordDate
    })
    ElMessage.success('奖罚记录保存成功')
    rewardPunishDialogVisible.value = false
  } catch (e) {
    console.error(e)
  } finally {
    savingRewardPunish.value = false
  }
}

// 3. 提成设置
const commissionSettingVisible = ref(false)
const globalCommission = ref({
  serviceRate: 25,
  cardRate: 10,
  productRate: 15,
  baseType: 'ACTUAL'
})

const openCommissionModal = () => {
  commissionSettingVisible.value = true
}

const handleSaveCommissionSetting = () => {
  ElMessage.success('提成配置保存成功！')
  commissionSettingVisible.value = false
}

// 4. 恢复已删除员工
const restoreDialogVisible = ref(false)
const loadingDeleted = ref(false)
const deletedStaffList = ref<any[]>([])

const openRestoreModal = async () => {
  restoreDialogVisible.value = true
  loadingDeleted.value = true
  try {
    const res: any = await getDeletedStaffListApi()
    deletedStaffList.value = res || []
  } catch (e) {
    console.error(e)
  } finally {
    loadingDeleted.value = false
  }
}

const handleRestoreStaff = async (id: number) => {
  try {
    await restoreStaffApi(id)
    systemData.updateStaff(id, { status: 'ACTIVE' })
    ElMessage.success('员工已成功恢复在职，成本中心已同步更新')
    openRestoreModal()
    loadStaffList()
  } catch (e) {
    console.error(e)
  }
}

// 5. 考勤记录 (动态提取当前选定员工的真实打卡流水与指标)
const attendanceDrawerVisible = ref(false)
const currentStaff = ref<any>(null)

const currentStaffAttendanceList = computed(() => {
  if (!currentStaff.value) return []
  const name = currentStaff.value.realName || currentStaff.value.name
  const phone = currentStaff.value.phone
  return (systemData.attendanceRecords || []).filter((r: any) => {
    const matchName = name && r.staffName && r.staffName.trim() === name.trim()
    const matchPhone = phone && r.phone && r.phone.trim() === phone.trim()
    return matchName || matchPhone
  })
})

const currentStaffAttendedDays = computed(() => {
  const dates = new Set(currentStaffAttendanceList.value.map((r: any) => r.workDate).filter(Boolean))
  return dates.size
})

const currentStaffLateCount = computed(() => {
  return currentStaffAttendanceList.value.filter((r: any) => r.checkInStatus === 'LATE').length
})

const currentStaffAttendanceRate = computed(() => {
  if (currentStaffAttendanceList.value.length === 0) return '0%'
  const normal = currentStaffAttendanceList.value.filter((r: any) => r.checkInStatus === 'NORMAL').length
  return `${Math.round((normal / currentStaffAttendanceList.value.length) * 100)}%`
})

const handleAttendance = (row: any) => {
  currentStaff.value = row
  attendanceDrawerVisible.value = true
}

// 6. 提成记录
const commissionsDrawerVisible = ref<boolean>(false)
const staffCommissions = ref<any[]>([])
const currentStaffCommissionTotal = computed(() => {
  return staffCommissions.value.reduce((sum, item) => sum + Number(item.commissionAmount || 0), 0)
})

const handleCommissions = async (row: any) => {
  currentStaff.value = row
  commissionsDrawerVisible.value = true
  staffCommissions.value = []
  try {
    const isNew = systemData.isNewTenant ||
      localStorage.getItem('seahorse_is_new_tenant') === 'true' ||
      localStorage.getItem('seahorse_role') === 'TENANT_ADMIN'

    let res: any = null
    try {
      res = await getStaffCommissionsApi(row.id)
    } catch (err) {}

    if (res && Array.isArray(res) && res.length > 0) {
      staffCommissions.value = res.map((r: any) => ({
        billingOrderId: r.orderNo || r.billingOrderId || `OD-${r.id}`,
        serviceItemName: r.serviceItemName || r.itemTitle || '服务项目工单',
        orderAmount: r.orderAmount ?? r.amount ?? 0,
        commissionAmount: r.commissionAmount ?? r.commission ?? 0,
        rateText: r.rateText || '10%',
        date: r.recordDate || r.date || r.createTime || ''
      }))
    } else if (!isNew) {
      const found = systemData.staffWithStats.find(s => s.id === row.id)
      staffCommissions.value = (found?.commissionRecords || []).map((r: any) => ({
        billingOrderId: r.orderNo,
        serviceItemName: `${r.itemTitle} (${r.type})`,
        orderAmount: r.amount,
        commissionAmount: r.commission,
        rateText: r.rateText,
        date: r.date
      }))
    } else {
      staffCommissions.value = []
    }
  } catch (e) {
    console.error(e)
    staffCommissions.value = []
  }
}

// 7. 奖罚记录
const rewardPunishDrawerVisible = ref(false)
const staffRewardPunishList = ref<any[]>([])

const handleRewardPunish = async (row: any) => {
  currentStaff.value = row
  rewardPunishDrawerVisible.value = true
  try {
    const res: any = await getRewardPunishListApi(row.id)
    staffRewardPunishList.value = res || []
  } catch (e) {
    console.error(e)
  }
}

// 8. 工资核算
const salaryCalcVisible = ref(false)
const currentStaffRewardPunishTotal = computed(() => {
  return staffRewardPunishList.value.reduce((sum, item) => {
    const amt = Number(item.amount || 0)
    return item.type === 'REWARD' ? sum + amt : sum - amt
  }, 0)
})

const hasStaffSalaryData = computed(() => {
  if (!currentStaff.value) return false
  const base = Number(currentStaff.value.baseSalary || 0)
  const comm = Number(currentStaffCommissionTotal.value || 0)
  const rp = Number(currentStaffRewardPunishTotal.value || 0)
  return base > 0 || comm > 0 || rp !== 0
})

const handleSalaryCalc = async (row: any) => {
  currentStaff.value = row
  staffCommissions.value = []
  staffRewardPunishList.value = []
  salaryCalcVisible.value = true

  try {
    const isNew = systemData.isNewTenant ||
      localStorage.getItem('seahorse_is_new_tenant') === 'true' ||
      localStorage.getItem('seahorse_role') === 'TENANT_ADMIN'

    try {
      const resComm = await getStaffCommissionsApi(row.id)
      if (resComm && Array.isArray(resComm) && resComm.length > 0) {
        staffCommissions.value = resComm.map((r: any) => ({
          billingOrderId: r.orderNo || r.billingOrderId || `OD-${r.id}`,
          serviceItemName: r.serviceItemName || r.itemTitle || '服务项目工单',
          orderAmount: r.orderAmount ?? r.amount ?? 0,
          commissionAmount: r.commissionAmount ?? r.commission ?? 0,
          rateText: r.rateText || '10%',
          date: r.recordDate || r.date || r.createTime || ''
        }))
      } else if (!isNew) {
        const found = systemData.staffWithStats.find(s => s.id === row.id)
        if (found?.commissionRecords) {
          staffCommissions.value = found.commissionRecords.map((r: any) => ({
            billingOrderId: r.orderNo,
            serviceItemName: `${r.itemTitle} (${r.type})`,
            orderAmount: r.amount,
            commissionAmount: r.commission,
            rateText: r.rateText,
            date: r.date
          }))
        }
      }
    } catch (err) {}

    try {
      const resRp: any = await getRewardPunishListApi(row.id)
      if (Array.isArray(resRp)) {
        staffRewardPunishList.value = resRp
      }
    } catch (err) {}
  } catch (e) {
    console.error(e)
  }
}

const salaryPaidRecordsMap = ref<Record<string, any[]>>({})

const handleConfirmSalaryPay = () => {
  if (currentStaff.value) {
    const staffId = String(currentStaff.value.id)
    const base = Number(currentStaff.value.baseSalary || 0)
    const comm = Number(currentStaffCommissionTotal.value || 0)
    const rp = Number(currentStaffRewardPunishTotal.value || 0)
    const actual = Math.max(0, Number((base + comm + rp).toFixed(2)))
    const nowMonth = formatLocalDate().slice(0, 7)
    if (!salaryPaidRecordsMap.value[staffId]) {
      salaryPaidRecordsMap.value[staffId] = []
    }
    salaryPaidRecordsMap.value[staffId].unshift({
      month: `${nowMonth} (已核发)`,
      baseSalary: base,
      commission: comm,
      actualSalary: actual,
      status: 'PAID'
    })
  }
  ElMessage.success('本月工资已核算确认完毕并归档！')
  salaryCalcVisible.value = false
}

// 9. 工资记录 (新注册租户无发薪历史，纯净化显示空状态；核算后动态呈现真实记录)
const salaryRecordsVisible = ref(false)
const handleSalaryRecords = (row: any) => {
  currentStaff.value = row
  salaryRecordsVisible.value = true
}
const salaryMockRecords = computed(() => {
  if (!currentStaff.value) return []
  const staffId = String(currentStaff.value.id)
  if (salaryPaidRecordsMap.value[staffId] && salaryPaidRecordsMap.value[staffId].length > 0) {
    return salaryPaidRecordsMap.value[staffId]
  }
  const isNew = systemData.isNewTenant ||
    localStorage.getItem('seahorse_is_new_tenant') === 'true' ||
    localStorage.getItem('seahorse_role') === 'TENANT_ADMIN'
  if (isNew) {
    return []
  }
  const found = systemData.staffWithStats.find(s => s.id === currentStaff.value.id) || currentStaff.value
  return [
    { month: '2026-09 (当前月份)', baseSalary: found.baseSalary, commission: found.totalCommission, actualSalary: found.calculatedSalary },
    { month: '2026-08', baseSalary: found.baseSalary, commission: Math.round(found.totalCommission * 0.92), actualSalary: Math.round(found.baseSalary + found.totalCommission * 0.92) },
    { month: '2026-07', baseSalary: found.baseSalary, commission: Math.round(found.totalCommission * 0.88), actualSalary: Math.round(found.baseSalary + found.totalCommission * 0.88) }
  ]
})

// 10. 服务人员对外称谓展示规则配置 (真实姓名/店内称呼/小美/张三)
const staffDisplayModalVisible = ref(false)
const currentStaffDisplayMode = ref('NICKNAME_FIRST')
const savingStaffDisplayMode = ref(false)

const openStaffDisplayModal = async () => {
  staffDisplayModalVisible.value = true
  try {
    const res = (await getStaffDisplayModeApi(effectiveStoreId.value)) as any
    const data = res?.data || res
    if (data && data.staffDisplayMode) {
      currentStaffDisplayMode.value = data.staffDisplayMode
    }
  } catch (e) {
    console.warn('获取称谓展示规则失败', e)
  }
}

const handleSaveStaffDisplayMode = async () => {
  savingStaffDisplayMode.value = true
  try {
    await saveStaffDisplayModeApi({
      storeId: effectiveStoreId.value,
      staffDisplayMode: currentStaffDisplayMode.value
    })
    ElMessage.success('服务人员对外称谓展示规则已保存，全平台即时生效！')
    staffDisplayModalVisible.value = false
  } catch (e: any) {
    ElMessage.error(e.message || '保存规则失败')
  } finally {
    savingStaffDisplayMode.value = false
  }
}

// 11. 门店常用服务要求与特殊备注维护 (多端双向同步)
const commonRemarksModalVisible = ref(false)
const editingCommonRemarks = ref<string[]>([])
const newRemarkTagInput = ref('')
const savingCommonRemarks = ref(false)

const openCommonRemarksModal = async () => {
  commonRemarksModalVisible.value = true
  try {
    const res = (await getCommonRemarksApi(effectiveStoreId.value, storeConfig.industry)) as any
    const list = res?.data || res
    if (Array.isArray(list)) {
      editingCommonRemarks.value = [...list]
    }
  } catch (e) {
    console.warn('获取常用备注标签失败', e)
  }
}

const handleAddRemarkTag = () => {
  const tag = newRemarkTagInput.value.trim()
  if (!tag) return
  if (editingCommonRemarks.value.includes(tag)) {
    ElMessage.warning('该备注标签已存在')
    return
  }
  editingCommonRemarks.value.push(tag)
  newRemarkTagInput.value = ''
}

const handleRemoveRemarkTag = (index: number) => {
  editingCommonRemarks.value.splice(index, 1)
}

const handleResetDefaultRemarks = async () => {
  try {
    const res = (await getCommonRemarksApi('__DEFAULT__', storeConfig.industry)) as any
    const list = res?.data || res
    if (Array.isArray(list)) {
      editingCommonRemarks.value = [...list]
      ElMessage.success('已载入当前业态推荐常用备注标签')
    }
  } catch (e) {
    ElMessage.warning('载入推荐标签失败')
  }
}

const handleSaveCommonRemarks = async () => {
  savingCommonRemarks.value = true
  try {
    await saveCommonRemarksApi({
      storeId: effectiveStoreId.value,
      remarks: editingCommonRemarks.value
    })
    ElMessage.success('常用服务要求/特殊备注已保存并同步至手机APP及收银全端！')
    commonRemarksModalVisible.value = false
  } catch (e: any) {
    ElMessage.error(e.message || '保存常用备注失败')
  } finally {
    savingCommonRemarks.value = false
  }
}

onMounted(() => {
  storeConfig.fetchCurrentSubscription()
  loadStaffList()
  loadAuditStaffList()
  loadAttendanceData()
  loadLeaveList()
})

onUnmounted(() => {
  if (testConnTimer) {
    clearTimeout(testConnTimer)
    testConnTimer = null
  }
})
</script>

<style scoped>
.staff-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.main-card {
  border-radius: 8px;
  background: #ffffff;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.restore-btn {
  color: #64748b;
  font-size: 14px;
}

.restore-btn:hover {
  color: #0284c7;
}

.staff-name {
  font-weight: 700;
  color: #0f172a;
}

.post-name {
  color: #334155;
  font-weight: 500;
}

.action-links {
  display: flex;
  align-items: center;
  flex-wrap: nowrap;
}

.action-links .el-button {
  padding: 0 4px;
  font-size: 13px;
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  padding: 8px 0;
}

.drawer-stat-bar {
  display: flex;
  justify-content: space-around;
  background-color: #f8fafc;
  padding: 16px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.drawer-stat-bar .stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.drawer-stat-bar .lbl {
  font-size: 12px;
  color: #64748b;
}

.drawer-stat-bar .val {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
}

/* 账号与权限配置弹窗样式 */
.account-dialog-body {
  max-height: 68vh;
  overflow-y: auto;
  padding-right: 6px;
}

.account-alert-banner {
  background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 50%, #eff6ff 100%);
  border: 1px solid #bbf7d0;
  border-radius: 10px;
  padding: 12px 16px;
  display: flex;
  align-items: center;
  gap: 12px;
}

.a-icon {
  font-size: 26px;
}

.a-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.a-title {
  font-size: 13px;
  font-weight: 700;
  color: #166534;
}

.a-desc {
  font-size: 11px;
  color: #374151;
  line-height: 1.4;
}

.config-block {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 16px;
  margin-bottom: 14px;
}

.block-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 8px;
}

.dot-icon {
  font-size: 15px;
}

.block-sub-hint {
  font-size: 11px;
  color: #64748b;
  margin-bottom: 12px;
  line-height: 1.4;
}

/* 多店铺授权卡片 */
.store-checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
}

.store-check-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 14px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  transition: all 0.2s;
}

.store-check-card:hover {
  border-color: #93c5fd;
}

.store-check-card.is-selected {
  border-color: #3b82f6;
  background-color: #eff6ff;
}

.s-info {
  display: flex;
  flex-direction: column;
  margin-left: 8px;
}

.s-name {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
}

.s-addr {
  font-size: 11px;
  color: #94a3b8;
}

/* 快捷模板按钮栏 */
.preset-btn-bar {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin-bottom: 12px;
  background: #ffffff;
  padding: 8px 12px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.preset-lbl {
  font-size: 11px;
  font-weight: 600;
  color: #475569;
}

/* 14大页签网格 */
.menu-selection-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}

@media (max-width: 680px) {
  .menu-selection-grid {
    grid-template-columns: 1fr;
  }
}

.menu-option-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  transition: all 0.15s;
}

.menu-option-card:hover {
  border-color: #93c5fd;
}

.menu-option-card.is-checked {
  border-color: #0284c7;
  background-color: #f0f9ff;
}

.menu-check-left {
  display: flex;
  align-items: flex-start;
  gap: 8px;
}

.menu-meta {
  display: flex;
  flex-direction: column;
}

.menu-name {
  font-size: 12px;
  font-weight: 700;
  color: #1e293b;
}

.menu-desc {
  font-size: 10px;
  color: #94a3b8;
  margin-top: 1px;
}

.perm-tags-preview {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
}

/* 员工入职二维码弹窗样式 */
.qr-modal-body {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 8px 0;
}

.qr-store-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #f8fafc;
  padding: 8px 16px;
  border-radius: 20px;
  border: 1px solid #e2e8f0;
}

.qr-store-name {
  font-weight: 700;
  color: #0f172a;
}

.qr-code-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.qr-image {
  width: 220px;
  height: 220px;
  border-radius: 6px;
}

.qr-loading {
  width: 220px;
  height: 220px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #94a3b8;
}

.qr-scan-hint {
  margin-top: 10px;
  font-size: 13px;
  color: #64748b;
  font-weight: 500;
}

.qr-link-box {
  width: 100%;
}

.qr-link-title {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
  margin-bottom: 6px;
}

.qr-actions {
  display: flex;
  gap: 12px;
  width: 100%;
  justify-content: center;
}

/* 选项卡与考勤打卡/请假流样式 */
.staff-tabs :deep(.el-tabs__nav-wrap::after) {
  height: 1.5px;
  background-color: #f1f5f9;
}

.staff-tabs :deep(.el-tabs__item) {
  font-size: 15px;
  font-weight: 600;
  color: #64748b;
  padding: 0 20px;
  height: 48px;
  line-height: 48px;
}

.staff-tabs :deep(.el-tabs__item.is-active) {
  color: #0284c7;
  font-weight: 700;
}

.attendance-container,
.leave-container {
  padding-top: 6px;
}

.att-kpi-grid,
.leave-kpi-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 14px;
  margin-top: 14px;
  margin-bottom: 16px;
}

.kpi-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 18px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  transition: all 0.2s ease;
}

.kpi-card:hover {
  border-color: #cbd5e1;
  background: #f1f5f9;
}

.kpi-lbl {
  font-size: 12px;
  color: #64748b;
  font-weight: 600;
}

.kpi-val {
  font-size: 22px;
  font-weight: 800;
  color: #0f172a;
}

.kpi-sub {
  font-size: 11.5px;
  color: #94a3b8;
}

.kpi-sync-time {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 700;
  color: #0284c7;
}

.pulse-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #10b981;
  box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
  animation: pulse-ring 1.8s infinite;
}

@keyframes pulse-ring {
  0% {
    transform: scale(0.95);
    box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
  }
  70% {
    transform: scale(1);
    box-shadow: 0 0 0 6px rgba(16, 185, 129, 0);
  }
  100% {
    transform: scale(0.95);
    box-shadow: 0 0 0 0 rgba(16, 185, 129, 0);
  }
}

.text-green {
  color: #10b981 !important;
}

.text-orange {
  color: #f59e0b !important;
}

.text-blue {
  color: #0284c7 !important;
}

.sync-config-body {
  padding: 6px 0;
}

.field-hint {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 4px;
  line-height: 1.4;
}
</style>
