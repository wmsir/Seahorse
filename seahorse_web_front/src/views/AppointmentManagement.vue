<template>
  <div class="appointment-page">
    <el-card shadow="never" class="main-card">
      <template #header>
        <div class="header-box">
          <div class="header-left">
            <span class="title">📅 顾客预约排班调度中心</span>
            <el-tag effect="plain" type="primary">当前行业：{{ currentIndustryName }}</el-tag>
            <el-tag effect="plain" type="success">多态看板 · 0-24小时全时域 · 技师/包厢双视角</el-tag>
          </div>
          <div class="header-right">
            <!-- 视图模式切换器 (支持 列表 / 日看板 0-24h / 周看板 / 月看板) -->
            <el-radio-group v-model="viewMode" size="default" style="margin-right: 12px;">
              <el-radio-button label="table">
                <el-icon style="vertical-align: middle;"><List /></el-icon> 列表视图
              </el-radio-button>
              <el-radio-button label="day">
                <el-icon style="vertical-align: middle;"><Clock /></el-icon> 日看板 (0-24h)
              </el-radio-button>
              <el-radio-button label="week">
                <el-icon style="vertical-align: middle;"><Calendar /></el-icon> 周看板
              </el-radio-button>
              <el-radio-button label="month">
                <el-icon style="vertical-align: middle;"><Grid /></el-icon> 月看板
              </el-radio-button>
            </el-radio-group>

            <el-button icon="Refresh" @click="refreshAllData">
              刷新数据
            </el-button>
            <el-button type="primary" icon="Plus" @click="handleOpenAddDialog()">
              登记新预约
            </el-button>
          </div>
        </div>
      </template>

      <!-- ====================================================================== -->
      <!-- 视图 1: 预约列表表格视图 (Table View) -->
      <!-- ====================================================================== -->
      <div v-if="viewMode === 'table'">
        <!-- 筛选栏 -->
        <div class="filter-row">
          <el-radio-group v-model="statusFilter" size="default" @change="currentPage = 1">
            <el-radio-button label="ALL">全部预约 ({{ allAppointments.length }})</el-radio-button>
            <el-radio-button label="PENDING">待履约 ({{ pendingCount }})</el-radio-button>
            <el-radio-button label="SERVING">服务中 ({{ servingCount }})</el-radio-button>
            <el-radio-button label="COMPLETED">已完成 ({{ completedCount }})</el-radio-button>
            <el-radio-button label="CANCELLED">已取消 ({{ cancelledCount }})</el-radio-button>
          </el-radio-group>

          <div style="display: flex; gap: 10px;">
            <el-date-picker
              v-model="dateFilter"
              type="date"
              placeholder="选择预约日期"
              value-format="YYYY-MM-DD"
              style="width: 160px;"
              clearable
              @change="currentPage = 1"
            />
            <el-tag
              v-if="dateFilter"
              size="default"
              :type="getDateBadge(dateFilter).type"
              effect="plain"
              style="margin-left: 8px; font-weight: 600;"
            >
              {{ getDateBadge(dateFilter).icon }} {{ getWeekdayText(dateFilter) }} · {{ getDateBadge(dateFilter).text }}
            </el-tag>
            <el-input
              v-model="searchKeyword"
              placeholder="搜索顾客姓名/手机号/技师"
              style="width: 220px;"
              clearable
              @input="currentPage = 1"
              @clear="currentPage = 1"
            />
          </div>
        </div>

        <!-- 列表表格 -->
        <el-table :data="paginatedAppointments" stripe style="width: 100%; margin-top: 16px;">
          <el-table-column prop="aptNo" label="预约编号" width="160">
            <template #default="{ row }">
              <span class="apt-no">{{ row.aptNo }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="customerName" label="顾客姓名" width="150">
            <template #default="{ row }">
              <b>{{ row.customerName }}</b>
              <el-tag v-if="row.isMember" size="small" type="warning" effect="dark" style="margin-left: 4px;">VIP</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="phone" label="联系电话" width="130" />
          <el-table-column prop="serviceName" label="预约项目" min-width="190">
            <template #default="{ row }">
              <span style="font-weight: 600; color: #1e293b;">{{ row.serviceName }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="aptTime" label="预约到店时间" width="240">
            <template #default="{ row }">
              <div style="display: flex; align-items: center; gap: 6px;">
                <span style="font-weight: 600; color: #0284c7;">{{ row.aptTime }}</span>
                <el-tag
                  size="small"
                  :type="getDateBadge(row.aptDate || row.aptTime).type"
                  effect="light"
                  style="font-size: 11px; padding: 0 5px;"
                >
                  {{ getDateBadge(row.aptDate || row.aptTime).shortText }}
                </el-tag>
              </div>
            </template>
          </el-table-column>
          <el-table-column prop="technicianName" label="指定技师/顾问" width="160">
            <template #default="{ row }">
              <el-tag effect="plain" type="primary">{{ row.technicianName || '智能调配' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="spaceName" label="包厢/工位" width="160" show-overflow-tooltip />
          <el-table-column prop="status" label="预约状态" width="110" align="center">
            <template #default="{ row }">
              <el-tag :type="getStatusTag(row.status)" effect="light">{{ getStatusName(row.status) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="200" fixed="right">
            <template #default="{ row }">
              <el-button link type="success" v-if="row.status === 'PENDING'" @click="handleCheckIn(row)">
                到店接待
              </el-button>
              <el-button link type="primary" v-if="row.status === 'SERVING'" @click="handleComplete(row)">
                服务结算
              </el-button>
              <el-button link type="danger" v-if="row.status === 'PENDING'" @click="handleCancel(row)">
                取消预约
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <!-- 分页 -->
        <div class="pagination-bar">
          <el-pagination
            v-model:current-page="currentPage"
            v-model:page-size="pageSize"
            :page-sizes="[5, 10, 20]"
            layout="total, sizes, prev, pager, next, jumper"
            :total="filteredAppointments.length"
          />
        </div>
      </div>

      <!-- ====================================================================== -->
      <!-- 视图 2: ⏱️ 按日看板 0-24小时排班时间轴 (Day Timeline Board) -->
      <!-- ====================================================================== -->
      <div v-else-if="viewMode === 'day'" class="day-timeline-board">
        <!-- 日看板头部控制器 -->
        <div class="board-top-bar">
          <div class="bar-left">
            <div class="date-stepper">
              <el-button icon="ArrowLeft" circle size="small" @click="changeDayOffset(-1)" />
              <el-date-picker
                v-model="selectedDayDate"
                type="date"
                value-format="YYYY-MM-DD"
                placeholder="选择看板日期"
                style="width: 140px;"
                :clearable="false"
              />
              <el-button icon="ArrowRight" circle size="small" @click="changeDayOffset(1)" />
              <el-button size="small" plain @click="setDayToday">今天</el-button>
            </div>
            <span class="day-date-label">{{ selectedDayDate }} ({{ getDayOfWeekStr(selectedDayDate) }})</span>
            <el-tag
              :type="getDateBadge(selectedDayDate).type"
              size="small"
              effect="dark"
              style="margin-left: 6px; font-weight: bold; border-radius: 4px;"
            >
              {{ getDateBadge(selectedDayDate).icon }} {{ getDateBadge(selectedDayDate).text }}
            </el-tag>
            <el-tag type="info" size="small">足疗/SPA常营运至凌晨，支持全天 00:00 - 24:00 完整时间刻度</el-tag>
          </div>

          <div class="bar-right">
            <!-- 泳道视角切换：按技师 / 按包厢 -->
            <span style="font-size: 13px; color: #475569; font-weight: 500;">排班视角：</span>
            <el-radio-group v-model="dayLanesMode" size="small">
              <el-radio-button label="TECH">按技师工号泳道</el-radio-button>
              <el-radio-button label="SPACE">按包厢房间泳道</el-radio-button>
            </el-radio-group>
          </div>
        </div>

        <!-- 暂无在册员工/工位空状态提示 -->
        <div v-if="currentDayLanes.length === 0" style="padding: 50px 20px; text-align: center; background: #f8fafc; border-radius: 8px; margin: 16px 0; border: 1px dashed #cbd5e1;">
          <el-empty :description="dayLanesMode === 'TECH' ? '当前租户暂无在册员工，请前往【员工管理】添加员工后开启排班调度' : '当前租户暂无工位包厢，请前往【工位/桌台看板】添加工位后排班'">
            <el-button type="primary" size="default" icon="Plus" @click="$router.push(dayLanesMode === 'TECH' ? '/staff-management' : '/rooms')">
              {{ dayLanesMode === 'TECH' ? '录入本店在册员工' : '规划门店工位包厢' }}
            </el-button>
          </el-empty>
        </div>

        <!-- 0-24小时时间轴网格矩阵 (仅在有本租户人员/工位时展示) -->
        <div v-else class="timeline-scroll-container">
          <div class="timeline-grid">
            <!-- 头部列：左上角角标 + 各泳道名称 -->
            <div class="grid-header-row">
              <div class="time-col-header">时间刻度 (0-24h)</div>
              <div
                v-for="lane in currentDayLanes"
                :key="lane.id"
                class="lane-col-header"
              >
                <div class="lane-title">{{ lane.name }}</div>
                <div class="lane-sub">{{ lane.subInfo }}</div>
              </div>
            </div>

            <!-- 24小时时间行 (00:00 - 23:00) -->
            <div
              v-for="hour in 24"
              :key="hour - 1"
              class="grid-hour-row"
            >
              <!-- 时间标记单元格 -->
              <div class="time-cell">
                <span class="hour-mark">{{ padZero(hour - 1) }}:00</span>
              </div>

              <!-- 每个泳道对应这一小时的槽位 -->
              <div
                v-for="lane in currentDayLanes"
                :key="lane.id + '_' + (hour - 1)"
                class="slot-cell"
                @click="handleClickTimeSlot(selectedDayDate, hour - 1, lane)"
              >
                <!-- 在该时间段内的预约卡片 -->
                <template v-for="apt in getAppointmentsForSlot(lane, hour - 1)" :key="apt.aptNo">
                  <div
                    class="timeline-appointment-card"
                    :class="'status-' + apt.status.toLowerCase()"
                    @click.stop
                  >
                    <div class="c-head">
                      <span class="c-time">{{ apt.rawStartTime || apt.aptTime }}</span>
                      <el-tag size="small" :type="getStatusTag(apt.status)" effect="dark">
                        {{ getStatusName(apt.status) }}
                      </el-tag>
                    </div>
                    <div class="c-body">
                      <div class="c-name">
                        <span>👤 {{ apt.customerName }}</span>
                        <span v-if="apt.isMember" class="vip-tag">VIP</span>
                      </div>
                      <div class="c-proj" :title="apt.serviceName">{{ apt.serviceName }}</div>
                      <div class="c-meta">
                        <span>{{ dayLanesMode === 'TECH' ? (apt.spaceName || '包厢待配') : (apt.technicianName || '技师待配') }}</span>
                      </div>
                    </div>
                    <div class="c-actions">
                      <el-button
                        v-if="apt.status === 'PENDING'"
                        size="small"
                        type="success"
                        @click.stop="handleCheckIn(apt)"
                      >
                        接待
                      </el-button>
                      <el-button
                        v-if="apt.status === 'SERVING'"
                        size="small"
                        type="primary"
                        @click.stop="handleComplete(apt)"
                      >
                        结算
                      </el-button>
                    </div>
                  </div>
                </template>

                <div v-if="getAppointmentsForSlot(lane, hour - 1).length === 0" class="slot-free-hint">
                  + 点击约此时段
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- ====================================================================== -->
      <!-- 视图 3: 📆 按周看板 (Week Board: 7天周历) -->
      <!-- ====================================================================== -->
      <div v-else-if="viewMode === 'week'" class="week-board-container">
        <!-- 周切换控制器 -->
        <div class="board-top-bar">
          <div class="bar-left">
            <el-button-group>
              <el-button icon="ArrowLeft" @click="changeWeekOffset(-1)">上一周</el-button>
              <el-button @click="setWeekCurrent">本周</el-button>
              <el-button @click="changeWeekOffset(1)">下一周 <el-icon class="el-icon--right"><ArrowRight /></el-icon></el-button>
            </el-button-group>
            <span class="week-range-text">
              🗓️ {{ currentWeekDays[0]?.date }} 至 {{ currentWeekDays[6]?.date }}
            </span>
          </div>
          <div class="bar-right">
            <span style="font-size: 13px; color: #64748b;">
              本周预约共计: <b style="color: #0284c7;">{{ weekTotalCount }}</b> 单
            </span>
          </div>
        </div>

        <!-- 7天列卡片布局 -->
        <div class="week-columns-grid">
          <div
            v-for="day in currentWeekDays"
            :key="day.date"
            class="week-day-col"
            :class="{ 'is-today': day.isToday }"
          >
            <!-- 星期卡头 -->
            <div class="week-col-head">
              <div class="day-name">{{ day.dayName }}</div>
              <div class="day-date">{{ day.date.substring(5) }}</div>
              <el-tag
                v-if="day.badge"
                size="small"
                :type="day.badge.type"
                effect="dark"
                style="margin: 2px 0 4px; font-weight: bold; border-radius: 4px;"
              >
                {{ day.badge.icon }} {{ day.badge.shortText }}
              </el-tag>
              <el-tag size="small" :type="day.appointments.length > 0 ? 'primary' : 'info'" effect="plain">
                {{ day.appointments.length }} 单预约
              </el-tag>
            </div>

            <!-- 当日预约卡片流 -->
            <div class="week-col-body">
              <div
                v-for="apt in day.appointments"
                :key="apt.aptNo"
                class="week-apt-card"
                :class="'status-' + apt.status.toLowerCase()"
              >
                <div class="w-time-row">
                  <span class="w-time">{{ apt.rawStartTime || apt.aptTime.split(' ')[1] || '待定' }}</span>
                  <el-tag size="small" :type="getStatusTag(apt.status)" effect="plain">
                    {{ getStatusName(apt.status) }}
                  </el-tag>
                </div>
                <div class="w-cust-row">
                  <b>{{ apt.customerName }}</b>
                  <span class="w-tech">{{ apt.technicianName }}</span>
                </div>
                <div class="w-proj-row" :title="apt.serviceName">{{ apt.serviceName }}</div>
                <div class="w-space-row">📍 {{ apt.spaceName || '默认包房' }}</div>

                <div class="w-card-actions">
                  <el-button
                    v-if="apt.status === 'PENDING'"
                    size="small"
                    link
                    type="success"
                    @click="handleCheckIn(apt)"
                  >
                    到店接待
                  </el-button>
                  <el-button
                    v-if="apt.status === 'SERVING'"
                    size="small"
                    link
                    type="primary"
                    @click="handleComplete(apt)"
                  >
                    完成结算
                  </el-button>
                </div>
              </div>

              <!-- 快速加单按钮 -->
              <div class="week-quick-add" @click="handleClickWeekQuickAdd(day.date)">
                + 预约此日
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- ====================================================================== -->
      <!-- 视图 4: 🗓️ 按月看板 (Month Board: 整月日历) -->
      <!-- ====================================================================== -->
      <div v-else-if="viewMode === 'month'" class="month-board-container">
        <!-- 月份控制器 -->
        <div class="board-top-bar">
          <div class="bar-left">
            <el-button-group>
              <el-button icon="ArrowLeft" @click="changeMonthOffset(-1)">上个月</el-button>
              <el-button @click="setMonthCurrent">本月</el-button>
              <el-button @click="changeMonthOffset(1)">下个月 <el-icon class="el-icon--right"><ArrowRight /></el-icon></el-button>
            </el-button-group>
            <span class="month-range-text">
              📅 {{ currentYearMonthStr }} 预约排期全景
            </span>
          </div>
          <div class="bar-right">
            <el-tag type="success">当月累计完成: {{ monthCompletedCount }} 单</el-tag>
            <el-tag type="warning" style="margin-left: 6px;">当月待接待: {{ monthPendingCount }} 单</el-tag>
          </div>
        </div>

        <!-- 7x5 标准日历网格 -->
        <div class="month-calendar-grid">
          <!-- 星期标题行 (周一至周日) -->
          <div class="m-week-header-row">
            <div class="m-week-header-cell">周一</div>
            <div class="m-week-header-cell">周二</div>
            <div class="m-week-header-cell">周三</div>
            <div class="m-week-header-cell">周四</div>
            <div class="m-week-header-cell">周五</div>
            <div class="m-week-header-cell weekend">周六 <span class="wk-rest-badge">休</span></div>
            <div class="m-week-header-cell weekend">周日 <span class="wk-rest-badge">休</span></div>
          </div>

          <!-- 42天网格单元格 -->
          <div class="m-days-grid">
            <div
              v-for="day in monthCalendarCells"
              :key="day.dateStr"
              class="m-day-cell"
              :class="{
                'not-current-month': !day.isCurrentMonth,
                'is-today': day.isToday,
                'is-selected': selectedMonthDay?.dateStr === day.dateStr,
                'is-weekend-cell': day.badge?.isWeekend,
                'is-holiday-cell': day.badge?.isHoliday
              }"
              @click="handleSelectMonthDay(day)"
            >
              <div class="m-day-top">
                <div class="m-day-left-meta">
                  <span class="m-day-number">{{ day.dayNumber }}</span>
                  <span
                    v-if="day.badge?.isHoliday"
                    class="m-holiday-tag"
                    :title="day.badge.text"
                  >
                    🎉 {{ day.badge.shortText }}
                  </span>
                  <span
                    v-else-if="day.badge?.isWeekend"
                    class="m-weekend-tag"
                    title="周末休息"
                  >
                    休
                  </span>
                </div>
                <span v-if="day.appointments.length > 0" class="m-apt-badge">
                  {{ day.appointments.length }}单
                </span>
              </div>

              <!-- 单元格内最多显示2条预约摘要胶囊 -->
              <div class="m-day-pills">
                <div
                  v-for="apt in day.appointments.slice(0, 2)"
                  :key="apt.aptNo"
                  class="m-apt-pill"
                  :class="'status-' + apt.status.toLowerCase()"
                  :title="`${apt.rawStartTime || ''} ${apt.customerName} - ${apt.serviceName}`"
                >
                  <span class="pill-t">{{ apt.rawStartTime || apt.aptTime.split(' ')[1] }}</span>
                  <span class="pill-n">{{ apt.customerName }}</span>
                </div>
                <div v-if="day.appointments.length > 2" class="m-more-text">
                  +{{ day.appointments.length - 2 }} 更多...
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 选定日期的排期明细抽屉/抽屉栏 -->
        <el-card v-if="selectedMonthDay" shadow="never" class="month-day-detail-box">
          <template #header>
            <div style="display: flex; justify-content: space-between; align-items: center;">
              <div style="display: flex; align-items: center; gap: 8px;">
                <b>📅 {{ selectedMonthDay.dateStr }} ({{ selectedMonthDay.dayOfWeekName }}) 预约排班明细</b>
                <el-tag
                  v-if="selectedMonthDay.badge"
                  :type="selectedMonthDay.badge.type"
                  size="small"
                  effect="dark"
                  style="font-weight: bold; border-radius: 4px;"
                >
                  {{ selectedMonthDay.badge.icon }} {{ selectedMonthDay.badge.text }}
                </el-tag>
                <span style="font-size: 13px; color: #64748b;">
                  共 {{ selectedMonthDay.appointments.length }} 笔预约
                </span>
              </div>
              <el-button type="primary" size="small" icon="Plus" @click="handleOpenAddDialog(selectedMonthDay.dateStr)">
                在此日期新增预约
              </el-button>
            </div>
          </template>

          <el-table
            :data="selectedMonthDay.appointments"
            empty-text="该日暂无预约记录，点击右上角快速添加"
            size="small"
            style="width: 100%;"
          >
            <el-table-column prop="rawStartTime" label="到店时间" width="130">
              <template #default="{ row }">
                <span style="font-weight: 700; color: #0284c7;">{{ row.rawStartTime || row.aptTime }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="customerName" label="顾客姓名" width="140">
              <template #default="{ row }">
                <b>{{ row.customerName }}</b>
                <el-tag v-if="row.isMember" size="small" type="warning" style="margin-left: 4px;">VIP</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="phone" label="联系电话" width="130" />
            <el-table-column prop="serviceName" label="服务项目" min-width="180" />
            <el-table-column prop="technicianName" label="指定技师" width="150" />
            <el-table-column prop="spaceName" label="分配包厢/工位" width="160" />
            <el-table-column prop="status" label="状态" width="100" align="center">
              <template #default="{ row }">
                <el-tag :type="getStatusTag(row.status)" size="small">{{ getStatusName(row.status) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="160" fixed="right">
              <template #default="{ row }">
                <el-button v-if="row.status === 'PENDING'" link type="success" @click="handleCheckIn(row)">
                  到店接待
                </el-button>
                <el-button v-if="row.status === 'SERVING'" link type="primary" @click="handleComplete(row)">
                  完成结算
                </el-button>
                <el-button v-if="row.status === 'PENDING'" link type="danger" @click="handleCancel(row)">
                  取消
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </div>
    </el-card>

    <!-- 新建预约弹窗 -->
    <el-dialog v-model="openAddDialog" title="📝 登记新顾客预约排班" width="560px" destroy-on-close>
      <el-form :model="addForm" label-width="110px">
        <el-form-item label="快捷选择会员">
          <el-select
            v-model="selectedMemberId"
            filterable
            clearable
            placeholder="输入会员姓名/手机号快速检索已有会员 (散客留空)..."
            style="width: 100%;"
            @change="handleSelectMemberForApt"
          >
            <el-option
              v-for="m in storeMembersOptions"
              :key="m.id"
              :label="m.name + ' - ' + m.phone + ' (' + (m.levelName || '普通会员') + ((m.principalBalance || m.giftBalance) ? ' · 余额￥' + ((m.principalBalance || 0) + (m.giftBalance || 0)).toFixed(1) : '') + ')'"
              :value="m.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="顾客姓名" required>
          <el-input v-model="addForm.customerName" placeholder="顾客称呼，如：李女士 / 张总" />
        </el-form-item>
        <el-form-item label="手机号码" required>
          <el-input v-model="addForm.phone" placeholder="11位手机号码" />
          <div v-if="matchedMember" style="margin-top: 4px; font-size: 12px; color: #059669; display: flex; align-items: center; gap: 4px;">
            <span>👑</span>
            <span>已匹配已有会员：<b>{{ matchedMember.name }}</b>（{{ matchedMember.levelName || '普通会员' }}）</span>
          </div>
          <div v-else-if="addForm.phone && addForm.phone.length >= 7" style="margin-top: 4px; font-size: 12px; color: #64748b;">
            💡 提示：该手机号暂未登记为会员，确认预约后系统将自动为其建档（默认普通会员）。
          </div>
        </el-form-item>
        <el-form-item label="预约项目" required>
          <template v-if="availableServices.length > 0">
            <el-select v-model="addForm.serviceName" filterable style="width: 100%;" placeholder="请选择已配置的预约服务项目">
              <el-option
                v-for="item in availableServices"
                :key="item.name"
                :label="item.label"
                :value="item.name"
              />
            </el-select>
          </template>
          <template v-else>
            <div style="display: flex; align-items: center; justify-content: space-between; width: 100%; background: #fef2f2; border: 1px dashed #f87171; border-radius: 6px; padding: 8px 12px;">
              <span style="font-size: 13px; color: #b91c1c;">⚠️ 门店暂未配置可预约的服务项目</span>
              <el-button type="danger" size="small" @click="goToConfigProducts">
                👉 前往配置服务
              </el-button>
            </div>
          </template>
        </el-form-item>
        <el-form-item label="到店时间" required>
          <div style="display: flex; gap: 8px; width: 100%;">
            <el-date-picker
              v-model="addForm.aptDate"
              type="date"
              placeholder="选择日期"
              value-format="YYYY-MM-DD"
              style="width: 55%;"
            />
            <el-time-select
              v-model="addForm.aptTimeSlot"
              start="00:00"
              step="00:30"
              end="23:30"
              placeholder="时段"
              style="width: 45%;"
            />
          </div>
          <div v-if="addForm.aptDate" style="margin-top: 6px;">
            <el-tag
              size="small"
              :type="getDateBadge(addForm.aptDate).type"
              effect="plain"
              style="font-weight: 600;"
            >
              {{ getDateBadge(addForm.aptDate).icon }} {{ getWeekdayText(addForm.aptDate) }} · {{ getDateBadge(addForm.aptDate).text }}
            </el-tag>
          </div>
        </el-form-item>
        <el-form-item label="指定技师">
          <el-select v-model="addForm.technicianName" clearable filterable style="width: 100%;" placeholder="请选择当前店铺在职技师/员工">
            <el-option label="系统前台智能派单" value="" />
            <el-option
              v-for="s in availableTechnicians"
              :key="s.name"
              :label="s.label"
              :value="s.name"
            />
          </el-select>
          <div v-if="availableTechnicians.length === 0" style="font-size: 12px; color: #94a3b8; margin-top: 4px; display: flex; align-items: center; justify-content: space-between;">
            <span>当前店铺暂无在册员工</span>
            <el-button link type="primary" size="small" @click="goToConfigStaff">前往【员工管理】录入</el-button>
          </div>
        </el-form-item>
        <el-form-item label="分配包厢/工位">
          <el-select v-model="addForm.spaceName" clearable filterable style="width: 100%;" placeholder="请选择当前店铺创建好的包厢/工位">
            <el-option label="无需分配 / 到店自选" value="" />
            <el-option
              v-for="sp in availableSpaceOptions"
              :key="sp"
              :label="sp"
              :value="sp"
            />
          </el-select>
          <div v-if="availableSpaceOptions.length === 0" style="font-size: 12px; color: #94a3b8; margin-top: 4px; display: flex; align-items: center; justify-content: space-between;">
            <span>当前店铺暂未创建包厢/工位</span>
            <el-button link type="primary" size="small" @click="goToConfigRooms">前往【包厢/工位】规划</el-button>
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openAddDialog = false">取消</el-button>
        <el-button type="primary" :disabled="availableServices.length === 0" @click="handleSaveAppointment">
          {{ availableServices.length === 0 ? '需先配置服务项目' : '确认登记预约' }}
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { List, Clock, Calendar, Grid, ArrowLeft, ArrowRight } from '@element-plus/icons-vue'
import { useSystemDataStore } from '../stores/systemDataStore'
import { useStoreConfig } from '../stores/store'
import { getDateBadge, getWeekdayText } from '../utils/chineseHolidayUtils'
import {
  getAppointmentsApi,
  createAppointmentApi,
  checkInAppointmentApi,
  updateAppointmentStatusApi,
  deleteAppointmentApi,
  getProductsApi,
  getMerchantStaffListApi,
  getSpacesApi,
  registerMemberApi,
  searchMembersApi
} from '../api'

const router = useRouter()
const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()
const serverAppointments = ref<any[]>([])
const serverServices = ref<any[]>([])
const serverStaff = ref<any[]>([])
const serverSpaces = ref<any[]>([])

const currentStoreId = computed(() => {
  return storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || systemData.stores[0]?.storeId || 'S001'
})

const goToConfigProducts = () => {
  openAddDialog.value = false
  router.push('/products')
}

const goToConfigStaff = () => {
  openAddDialog.value = false
  router.push('/staff-management')
}

const goToConfigRooms = () => {
  openAddDialog.value = false
  router.push('/rooms')
}

const formatLocalDate = (d: Date = new Date()): string => {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const date = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${date}`
}

const getInitialWeekMonday = (): string => {
  const now = new Date()
  const day = now.getDay()
  const diff = now.getDate() - day + (day === 0 ? -6 : 1)
  return formatLocalDate(new Date(now.getFullYear(), now.getMonth(), diff))
}

const loadServerAppointments = async (targetDate?: string) => {
  const effectiveDate = targetDate || selectedDayDate.value || formatLocalDate()
  try {
    const sId = currentStoreId.value
    const tenantId = localStorage.getItem('seahorse_tenant_id') || ''
    const res: any = await getAppointmentsApi({ storeId: sId, date: effectiveDate })
    let list: any[] = Array.isArray(res) ? res : (Array.isArray(res?.data) ? res.data : [])
    if (list.length === 0 && sId && !systemData.isNewTenant) {
      try {
        const fallbackRes: any = await getAppointmentsApi({ date: effectiveDate })
        list = Array.isArray(fallbackRes) ? fallbackRes : (Array.isArray(fallbackRes?.data) ? fallbackRes.data : [])
      } catch (_) {}
    }
    if (systemData.isNewTenant) {
      list = list.filter((a: any) => {
        if (tenantId && a.tenantId && a.tenantId !== tenantId) return false
        if (sId && a.storeId && a.storeId !== sId) return false
        return true
      })
    }
    const others = serverAppointments.value.filter((a: any) => a.aptDate !== effectiveDate && !list.some((n: any) => n.id === a.id))
    serverAppointments.value = [...others, ...list]
  } catch (err) {
    console.error('loadServerAppointments error:', err)
  }
}

const loadServerAppointmentsRange = async (startDate: string, endDate: string) => {
  if (!startDate || !endDate) return
  try {
    const sId = currentStoreId.value
    const tenantId = localStorage.getItem('seahorse_tenant_id') || ''
    const res: any = await getAppointmentsApi({ storeId: sId, startDate, endDate } as any)
    let list: any[] = Array.isArray(res) ? res : (Array.isArray(res?.data) ? res.data : [])
    if (list.length === 0 && sId && !systemData.isNewTenant) {
      try {
        const fallbackRes: any = await getAppointmentsApi({ startDate, endDate } as any)
        list = Array.isArray(fallbackRes) ? fallbackRes : (Array.isArray(fallbackRes?.data) ? fallbackRes.data : [])
      } catch (_) {}
    }
    if (systemData.isNewTenant) {
      list = list.filter((a: any) => {
        if (tenantId && a.tenantId && a.tenantId !== tenantId) return false
        if (sId && a.storeId && a.storeId !== sId) return false
        return true
      })
    }
    const others = serverAppointments.value.filter((a: any) => {
      const d = a.aptDate || ''
      const inRange = d >= startDate && d <= endDate
      return !inRange && !list.some((n: any) => n.id === a.id)
    })
    serverAppointments.value = [...others, ...list]
  } catch (err) {
    console.error('loadServerAppointmentsRange error:', err)
  }
}

const loadServerServices = async () => {
  try {
    const res: any = await getProductsApi()
    const list = Array.isArray(res) ? res : (res?.data || [])
    if (list.length > 0) {
      serverServices.value = list
    }
  } catch (err) {
    console.warn('loadServerServices error:', err)
  }
}

const loadServerStaff = async () => {
  try {
    let res: any = null
    const sId = currentStoreId.value
    // 1. 优先尝试按当前店铺ID获取在册员工
    if (sId) {
      try {
        res = await getMerchantStaffListApi(sId)
      } catch (_) {}
    }
    let list = Array.isArray(res) ? res : (Array.isArray(res?.data) ? res.data : [])
    // 2. 若按店铺未查到或为空，则全量获取当前租户在册员工（与【员工管理】完全对齐）
    if (list.length === 0) {
      try {
        res = await getMerchantStaffListApi()
        list = Array.isArray(res) ? res : (Array.isArray(res?.data) ? res.data : [])
      } catch (_) {}
    }
    if (list.length > 0) {
      serverStaff.value = list.filter((item: any) =>
        item.role !== 'PLATFORM_DEVELOPER' &&
        item.username !== 'admin' &&
        (!item.realName || !item.realName.includes('开发维护人'))
      )
    }
  } catch (err) {
    console.warn('loadServerStaff error:', err)
  }
}

const loadServerSpaces = async () => {
  try {
    let res: any = null
    const sId = currentStoreId.value
    if (sId) {
      try {
        res = await getSpacesApi(sId)
      } catch (_) {}
    }
    let list = Array.isArray(res) ? res : (Array.isArray(res?.data) ? res.data : [])
    if (list.length === 0) {
      try {
        res = await getSpacesApi()
        list = Array.isArray(res) ? res : (Array.isArray(res?.data) ? res.data : [])
      } catch (_) {}
    }
    if (list.length > 0) {
      serverSpaces.value = list
    }
  } catch (err) {
    console.warn('loadServerSpaces error:', err)
  }
}

const loadActiveViewAppointments = async () => {
  if (viewMode.value === 'week') {
    const parts = currentWeekMonday.value.split('-')
    const monday = parts.length === 3
      ? new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
      : new Date()
    const sunday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 6)
    await loadServerAppointmentsRange(formatLocalDate(monday), formatLocalDate(sunday))
  } else if (viewMode.value === 'month') {
    const y = currentMonthDate.value.getFullYear()
    const m = currentMonthDate.value.getMonth()
    const rangeStart = formatLocalDate(new Date(y, m, -6))
    const rangeEnd = formatLocalDate(new Date(y, m + 1, 7))
    await loadServerAppointmentsRange(rangeStart, rangeEnd)
  } else if (viewMode.value === 'table') {
    if (dateFilter.value) {
      await loadServerAppointments(dateFilter.value)
    } else {
      const now = new Date()
      const start = formatLocalDate(new Date(now.getFullYear(), now.getMonth(), now.getDate() - 30))
      const end = formatLocalDate(new Date(now.getFullYear(), now.getMonth(), now.getDate() + 60))
      await loadServerAppointmentsRange(start, end)
    }
  } else {
    await loadServerAppointments(selectedDayDate.value)
  }
}

const refreshAllData = async () => {
  await Promise.allSettled([
    loadActiveViewAppointments(),
    loadServerServices(),
    loadServerStaff(),
    loadServerSpaces()
  ])
  ElMessage.success('已刷新最新预约、员工与工位数据')
}

onMounted(() => {
  Promise.allSettled([
    loadActiveViewAppointments(),
    loadServerServices(),
    loadServerStaff(),
    loadServerSpaces()
  ])
})

// 视图模式：'table' | 'day' | 'week' | 'month'
const viewMode = ref<'table' | 'day' | 'week' | 'month'>('day')
const statusFilter = ref('ALL')
const dateFilter = ref('')
const searchKeyword = ref('')
const currentPage = ref(1)
const pageSize = ref(10)

const industryMap: Record<string, string> = {
  BEAUTY: '美业足疗推拿SPA',
  RESTAURANT: '餐饮美食',
  AUTO: '汽车养护维修',
  RETAIL: '轻奢专营零售'
}

const currentIndustryName = computed(() => {
  return industryMap[systemData.currentIndustry] || '品质商业'
})

// 服务项目清单：必须从配置的商品中提取真实服务项目，坚决杜绝任何脏数据假数据！
const availableServices = computed(() => {
  const source = serverServices.value.length > 0 ? serverServices.value : (systemData.products || [])
  const hasTypeField = source.some((p: any) => p.type || p.productType)
  const filtered = hasTypeField
    ? source.filter((p: any) => {
        const t = (p.type || p.productType || '').toUpperCase()
        return t === 'SERVICE' || t === 'PACKAGE'
      })
    : source

  return filtered.map((p: any) => {
    const priceText = p.price !== undefined ? ` (¥${p.price})` : (p.salePrice !== undefined ? ` (¥${p.salePrice})` : '')
    const durText = p.durationMinutes ? ` · ${p.durationMinutes}分钟` : ''
    return {
      name: p.name,
      price: p.price || p.salePrice || 0,
      label: `${p.name}${priceText}${durText}`
    }
  })
})

// 可用技师清单：优先精确匹配当前店铺名下员工；若当前店铺尚未分配或过滤为空，则兜底展示租户名下所有在册员工，杜绝假空状态
const availableTechnicians = computed(() => {
  const source = serverStaff.value.length > 0 ? serverStaff.value : (systemData.staff || [])
  const storeId = currentStoreId.value
  const nonDeleted = source.filter((s: any) => s.status !== 'DELETED')
  if (nonDeleted.length === 0) return []

  // 1. 如果有指定门店，优先筛选归属于该门店（或授权该门店）的员工
  if (storeId) {
    const matched = nonDeleted.filter((s: any) => {
      if (!s.storeId || s.storeId === storeId) return true
      if (Array.isArray(s.allowedStoreIds) && s.allowedStoreIds.includes(storeId)) return true
      return false
    })
    if (matched.length > 0) {
      return matched.map((s: any) => ({
        name: s.realName || s.name,
        label: `${s.realName || s.name} (${s.postName || s.role || '员工'}${s.staffNo ? ` · ${s.staffNo}` : ''})`
      }))
    }
  }

  // 2. 兜底策略：若按门店过滤后为空，但租户本身已有在册员工，则展示该租户全部员工
  return nonDeleted.map((s: any) => ({
    name: s.realName || s.name,
    label: `${s.realName || s.name} (${s.postName || s.role || '员工'}${s.staffNo ? ` · ${s.staffNo}` : ''})`
  }))
})

// 可用工位包厢清单：优先匹配当前店铺创建好的包厢/工位，若未分店则兜底展示租户工位
const availableSpaceOptions = computed(() => {
  const source = serverSpaces.value.length > 0 ? serverSpaces.value : (systemData.spaces || [])
  const storeId = currentStoreId.value
  
  let targetSpaces = source
  if (storeId) {
    const storeMatched = source.filter((sp: any) => !sp.storeId || sp.storeId === storeId)
    if (storeMatched.length > 0) {
      targetSpaces = storeMatched
    }
  }

  const list: string[] = []
  targetSpaces.forEach((sp: any) => {
    const name = sp.spaceName || sp.name
    if (name && !list.includes(name)) {
      list.push(name)
    }
  })
  return list
})

// 综合预约清单：100% 严格来自后端数据库真实排班数据，彻底清除任何 Mock 垃圾数据
const allAppointments = computed(() => {
  if (!serverAppointments.value || serverAppointments.value.length === 0) {
    return []
  }
  return serverAppointments.value.map((a: any) => {
    const rawStartTime = a.aptTime?.split(' - ')[0]?.split(' ')[1] || a.aptTime?.split(' - ')[0] || '14:00'
    const parsedHour = parseInt(rawStartTime.split(':')[0] || '14', 10)
    return {
      id: a.id,
      aptNo: a.aptNo,
      customerName: a.customerName,
      isMember: true,
      phone: a.phone,
      serviceName: a.serviceName,
      aptTime: a.aptTime?.includes(' ') ? a.aptTime : `${a.aptDate} ${a.aptTime}`,
      rawStartTime,
      date: a.aptDate,
      hour: Number.isNaN(parsedHour) ? 14 : parsedHour,
      technicianName: a.staffName || a.technicianName || '智能调配',
      spaceName: a.spaceName || '1号包厢/镜台',
      status: a.status
    }
  })
})

const pendingCount = computed(() => allAppointments.value.filter(a => a.status === 'PENDING').length)
const servingCount = computed(() => allAppointments.value.filter(a => a.status === 'SERVING').length)
const completedCount = computed(() => allAppointments.value.filter(a => a.status === 'COMPLETED').length)
const cancelledCount = computed(() => allAppointments.value.filter(a => a.status === 'CANCELLED').length)

const filteredAppointments = computed(() => {
  return allAppointments.value.filter(item => {
    if (statusFilter.value !== 'ALL' && item.status !== statusFilter.value) return false
    if (dateFilter.value && !item.date?.includes(dateFilter.value)) return false
    if (searchKeyword.value) {
      const q = searchKeyword.value.toLowerCase()
      const matchN = item.customerName?.toLowerCase().includes(q)
      const matchP = item.phone?.includes(q)
      const matchT = item.technicianName?.toLowerCase().includes(q)
      if (!matchN && !matchP && !matchT) return false
    }
    return true
  })
})

const paginatedAppointments = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredAppointments.value.slice(start, start + pageSize.value)
})

const padZero = (n: number) => n < 10 ? '0' + n : String(n)

// ============================================================================
// 日看板逻辑 (Day Board: 0-24小时时间轴刻度)
// ============================================================================
const selectedDayDate = ref(formatLocalDate())
const dayLanesMode = ref<'TECH' | 'SPACE'>('TECH')

watch(selectedDayDate, (val) => {
  if (val) {
    loadServerAppointments(val)
  }
})

watch(dateFilter, (val) => {
  if (val) {
    loadServerAppointments(val)
  } else if (viewMode.value === 'table') {
    loadActiveViewAppointments()
  }
})

watch(viewMode, () => {
  loadActiveViewAppointments()
})

const changeDayOffset = (days: number) => {
  const parts = selectedDayDate.value.split('-')
  const d = parts.length === 3
    ? new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
    : new Date()
  d.setDate(d.getDate() + days)
  selectedDayDate.value = formatLocalDate(d)
}

const setDayToday = () => {
  selectedDayDate.value = formatLocalDate()
}

const getDayOfWeekStr = (dateStr: string) => {
  const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
  const d = new Date(dateStr)
  return days[d.getDay()] || '周'
}

// 当前日看板泳道列表
const currentDayLanes = computed(() => {
  if (dayLanesMode.value === 'TECH') {
    return availableTechnicians.value.map((t, idx) => ({
      id: 'tech_' + idx,
      name: t.name,
      subInfo: '专职在岗技师',
      key: t.name
    }))
  } else {
    return availableSpaceOptions.value.map((sp, idx) => ({
      id: 'space_' + idx,
      name: sp,
      subInfo: '包厢床位',
      key: sp
    }))
  }
})

// 获取指定泳道和指定小时内的预约
const getAppointmentsForSlot = (lane: any, hour: number) => {
  return allAppointments.value.filter(a => {
    if (a.date !== selectedDayDate.value) return false
    const aptHour = a.hour !== undefined ? a.hour : parseInt(a.rawStartTime?.split(':')[0] || '0', 10)
    if (aptHour !== hour) return false
    if (dayLanesMode.value === 'TECH') {
      return a.technicianName === lane.key || (a.technicianName && a.technicianName.includes(lane.key.split(' ')[0]))
    } else {
      return a.spaceName === lane.key || (a.spaceName && a.spaceName.includes(lane.key.split(' ')[0]))
    }
  })
}

const handleClickTimeSlot = (dateStr: string, hour: number, lane: any) => {
  addForm.value.aptDate = dateStr
  addForm.value.aptTimeSlot = `${padZero(hour)}:00`
  if (dayLanesMode.value === 'TECH') {
    addForm.value.technicianName = lane.key
  } else {
    addForm.value.spaceName = lane.key
  }
  openAddDialog.value = true
}

// ============================================================================
// 周看板逻辑 (Week Board: 7天视图)
// ============================================================================
const currentWeekMonday = ref(getInitialWeekMonday())

watch(currentWeekMonday, () => {
  if (viewMode.value === 'week') {
    loadActiveViewAppointments()
  }
})

const changeWeekOffset = (weeks: number) => {
  const parts = currentWeekMonday.value.split('-')
  const d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
  d.setDate(d.getDate() + weeks * 7)
  currentWeekMonday.value = formatLocalDate(d)
}

const setWeekCurrent = () => {
  const now = new Date()
  const day = now.getDay()
  const diff = now.getDate() - day + (day === 0 ? -6 : 1) // 调整到周一
  const monday = new Date(now.getFullYear(), now.getMonth(), diff)
  currentWeekMonday.value = formatLocalDate(monday)
}

const currentWeekDays = computed(() => {
  const result: any[] = []
  const parts = currentWeekMonday.value.split('-')
  const monday = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
  const dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  const todayStr = formatLocalDate(new Date())

  for (let i = 0; i < 7; i++) {
    const d = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + i)
    const dateStr = formatLocalDate(d)
    const apts = allAppointments.value.filter(a => a.date === dateStr)
    result.push({
      dayName: dayNames[i],
      date: dateStr,
      isToday: dateStr === todayStr,
      badge: getDateBadge(dateStr),
      appointments: apts
    })
  }
  return result
})

const weekTotalCount = computed(() => {
  return currentWeekDays.value.reduce((sum, d) => sum + d.appointments.length, 0)
})

const handleClickWeekQuickAdd = (dateStr: string) => {
  addForm.value.aptDate = dateStr
  addForm.value.aptTimeSlot = '18:00'
  openAddDialog.value = true
}

// ============================================================================
// 月看板逻辑 (Month Board: 整月日历)
// ============================================================================
const currentMonthDate = ref(new Date())

watch(currentMonthDate, () => {
  if (viewMode.value === 'month') {
    loadActiveViewAppointments()
  }
})

const currentYearMonthStr = computed(() => {
  const y = currentMonthDate.value.getFullYear()
  const m = currentMonthDate.value.getMonth() + 1
  return `${y}年 ${m}月`
})

const changeMonthOffset = (months: number) => {
  const d = new Date(currentMonthDate.value)
  d.setMonth(d.getMonth() + months)
  currentMonthDate.value = d
}

const setMonthCurrent = () => {
  currentMonthDate.value = new Date()
}

const monthCalendarCells = computed(() => {
  const year = currentMonthDate.value.getFullYear()
  const month = currentMonthDate.value.getMonth()
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)

  // 计算当月第一天是周几 (周一为0，周日为6)
  let startDayOfWeek = firstDay.getDay() - 1
  if (startDayOfWeek < 0) startDayOfWeek = 6

  const daysInPrevMonth = new Date(year, month, 0).getDate()
  const daysInCurrentMonth = lastDay.getDate()

  const cells: any[] = []
  const todayStr = formatLocalDate(new Date())

  // 1. 上月末尾天数
  for (let i = startDayOfWeek - 1; i >= 0; i--) {
    const dayNum = daysInPrevMonth - i
    const d = new Date(year, month - 1, dayNum)
    const dateStr = formatLocalDate(d)
    const badge = getDateBadge(dateStr)
    cells.push({
      dayNumber: dayNum,
      dateStr,
      isCurrentMonth: false,
      isToday: dateStr === todayStr,
      badge,
      appointments: allAppointments.value.filter(a => a.date === dateStr)
    })
  }

  // 2. 当月天数
  for (let i = 1; i <= daysInCurrentMonth; i++) {
    const d = new Date(year, month, i)
    const dateStr = formatLocalDate(d)
    const badge = getDateBadge(dateStr)
    cells.push({
      dayNumber: i,
      dateStr,
      isCurrentMonth: true,
      isToday: dateStr === todayStr,
      badge,
      appointments: allAppointments.value.filter(a => a.date === dateStr)
    })
  }

  // 3. 下月起始天数补齐至 35 或 42 格
  const remaining = (7 - (cells.length % 7)) % 7
  for (let i = 1; i <= remaining; i++) {
    const d = new Date(year, month + 1, i)
    const dateStr = formatLocalDate(d)
    const badge = getDateBadge(dateStr)
    cells.push({
      dayNumber: i,
      dateStr,
      isCurrentMonth: false,
      isToday: dateStr === todayStr,
      badge,
      appointments: allAppointments.value.filter(a => a.date === dateStr)
    })
  }

  return cells
})

const selectedMonthDateStr = ref('')

const selectedMonthDay = computed(() => {
  if (!selectedMonthDateStr.value) return null
  const matchedCell = monthCalendarCells.value.find(c => c.dateStr === selectedMonthDateStr.value)
  const dateStr = selectedMonthDateStr.value
  return {
    ...(matchedCell || {
      dayNumber: parseInt(dateStr.split('-')[2] || '1', 10),
      dateStr,
      isCurrentMonth: true,
      isToday: dateStr === formatLocalDate(),
      appointments: allAppointments.value.filter(a => a.date === dateStr)
    }),
    dayOfWeekName: getDayOfWeekStr(dateStr),
    badge: matchedCell?.badge || getDateBadge(dateStr)
  }
})

const handleSelectMonthDay = (day: any) => {
  selectedMonthDateStr.value = day.dateStr
  if (day.dateStr) {
    loadServerAppointments(day.dateStr)
  }
}

const currentYearMonthPrefix = computed(() => {
  const y = currentMonthDate.value.getFullYear()
  const m = String(currentMonthDate.value.getMonth() + 1).padStart(2, '0')
  return `${y}-${m}`
})

const monthCompletedCount = computed(() => {
  return allAppointments.value.filter(a => a.date?.startsWith(currentYearMonthPrefix.value) && a.status === 'COMPLETED').length
})

const monthPendingCount = computed(() => {
  return allAppointments.value.filter(a => a.date?.startsWith(currentYearMonthPrefix.value) && a.status === 'PENDING').length
})

// ============================================================================
// 状态与生命周期操作
// ============================================================================
const getStatusTag = (status: string) => {
  switch (status) {
    case 'PENDING': return 'warning'
    case 'SERVING': return 'danger'
    case 'COMPLETED': return 'success'
    case 'CANCELLED': return 'info'
    default: return 'info'
  }
}

const getStatusName = (status: string) => {
  switch (status) {
    case 'PENDING': return '待履约'
    case 'SERVING': return '服务中'
    case 'COMPLETED': return '已完成'
    case 'CANCELLED': return '已取消'
    default: return status
  }
}

const handleCheckIn = async (row: any) => {
  try {
    if (row.id) {
      await checkInAppointmentApi(row.id)
    }
    row.status = 'SERVING'
    ElMessage.success(`顾客【${row.customerName}】已顺利到店接待并安排在【${row.spaceName || '展位'}】！展位与预约已同步变为【服务中】。`)
    if (systemData.spaces) {
      const sp = systemData.spaces.find((s: any) => s.spaceName === row.spaceName || s.name === row.spaceName)
      if (sp) {
        sp.status = 'OCCUPIED'
      }
    }
    await loadServerAppointments(row.date)
  } catch (err: any) {
    console.error('handleCheckIn error:', err)
  }
}

const handleComplete = async (row: any) => {
  try {
    if (row.id) {
      await updateAppointmentStatusApi(row.id, 'COMPLETED')
    }
    row.status = 'COMPLETED'
    ElMessage.success(`预约工单【${row.aptNo}】服务完成！`)
    await loadServerAppointments(row.date)
  } catch (err: any) {
    console.error('handleComplete error:', err)
  }
}

const handleCancel = (row: any) => {
  ElMessageBox.confirm(`确定要取消顾客【${row.customerName}】的预约吗？`, '安全提示', {
    confirmButtonText: '确认取消',
    cancelButtonText: '返回',
    type: 'warning'
  }).then(async () => {
    try {
      if (row.id) {
        await deleteAppointmentApi(row.id)
      }
      const target = serverAppointments.value.find((a: any) => a.id === row.id)
      if (target) {
        target.status = 'CANCELLED'
      }
      row.status = 'CANCELLED'
      ElMessage.success('已取消预约，记录已归档至【已取消】列表')
      await loadActiveViewAppointments()
    } catch (err: any) {
      console.error('handleCancel error:', err)
    }
  }).catch(() => {})
}

// ============================================================================
// 新建预约表单与会员快捷选择
// ============================================================================
const openAddDialog = ref(false)
const selectedMemberId = ref<number | null>(null)
const addForm = ref({
  customerName: '',
  phone: '',
  serviceName: '',
  aptDate: '',
  aptTimeSlot: '',
  technicianName: '',
  spaceName: ''
})

const serverMembers = ref<any[]>([])

const loadStoreMembersForApt = async () => {
  try {
    const data: any = await searchMembersApi('')
    if (Array.isArray(data)) {
      serverMembers.value = data
    }
  } catch (e) {
    console.warn('获取预约会员列表降级:', e)
  }
}

// 本店铺会员选项 (优先展示真实服务端会员，合并本地缓存，并优先匹配当前门店)
const storeMembersOptions = computed(() => {
  const map = new Map<string, any>()
  serverMembers.value.forEach((m: any) => {
    map.set(String(m.id), m)
  })
  const cachedMembersRaw = localStorage.getItem('seahorse_members_data')
  if (cachedMembersRaw) {
    try {
      const parsed = JSON.parse(cachedMembersRaw)
      if (Array.isArray(parsed)) {
        parsed.forEach((m: any) => {
          if (!map.has(String(m.id))) map.set(String(m.id), m)
        })
      }
    } catch {}
  }
  ;(systemData.membersWithStats || systemData.members || []).forEach((m: any) => {
    if (!map.has(String(m.id))) map.set(String(m.id), m)
  })
  const all = Array.from(map.values())
  const sId = currentStoreId.value
  if (!sId) return all
  const filtered = all.filter((m: any) => !m.registeredStoreId || m.registeredStoreId === sId)
  return filtered.length > 0 ? filtered : all
})

// 根据填入的手机号实时匹配是否为已有会员
const matchedMember = computed(() => {
  const phone = addForm.value.phone.trim()
  if (!phone) return null
  return storeMembersOptions.value.find((m: any) => m.phone === phone)
})

const handleSelectMemberForApt = (memId: number | null) => {
  if (!memId) return
  const m = storeMembersOptions.value.find((item: any) => item.id === memId)
  if (m) {
    addForm.value.customerName = m.name
    addForm.value.phone = m.phone
  }
}

const handleOpenAddDialog = (targetDate?: string) => {
  loadStoreMembersForApt()
  const now = new Date()
  const y = now.getFullYear()
  const m = String(now.getMonth() + 1).padStart(2, '0')
  const d = String(now.getDate()).padStart(2, '0')
  const hh = String(now.getHours()).padStart(2, '0')
  const mm = String(now.getMinutes()).padStart(2, '0')
  const todayStr = `${y}-${m}-${d}`
  const nowTimeStr = `${hh}:${mm}`

  selectedMemberId.value = null
  addForm.value = {
    customerName: '',
    phone: '',
    serviceName: availableServices.value[0]?.name || '',
    aptDate: targetDate || selectedDayDate.value || todayStr,
    aptTimeSlot: nowTimeStr,
    technicianName: availableTechnicians.value[0]?.name || '',
    spaceName: availableSpaceOptions.value[0] || ''
  }
  openAddDialog.value = true
}

const handleSaveAppointment = async () => {
  const name = addForm.value.customerName.trim()
  const phone = addForm.value.phone.trim()

  if (!name || !phone) {
    ElMessage.warning('请填写顾客姓名与联系电话')
    return
  }
  if (!addForm.value.serviceName) {
    ElMessage.warning('当前门店暂无可预约的服务项目，请先配置服务项目')
    return
  }
  if (!addForm.value.aptDate || !addForm.value.aptTimeSlot) {
    ElMessage.warning('请选择完整的预约日期与到店时段')
    return
  }

  // 校验是否为本店铺已有会员；若不是，则自动新增该信息到会员体系，默认是普通会员
  const existingMember = storeMembersOptions.value.find((m: any) => m.phone === phone)
  let isNewMemberCreated = false
  if (!existingMember) {
    systemData.registerMember({
      name: name,
      phone: phone,
      registeredStoreId: currentStoreId.value
    })
    isNewMemberCreated = true

    // 异步同步到后端会员注册接口
    try {
      registerMemberApi({
        name: name,
        phone: phone,
        storeId: currentStoreId.value
      }).catch(() => {})
    } catch (_) {}
  }

  const parsedStartHour = parseInt(addForm.value.aptTimeSlot.split(':')[0] || '14', 10)
  const aptHour = Number.isNaN(parsedStartHour) ? 14 : parsedStartHour
  const endHour = (aptHour + 1) % 24
  const timeSlotStr = `${addForm.value.aptTimeSlot} - ${padZero(endHour)}:00`

  // 获取所选服务的真实价格
  const selectedSvc = availableServices.value.find((s: any) => s.name === addForm.value.serviceName)
  const svcPrice = selectedSvc?.price ?? 0

  try {
    const targetAptDate = addForm.value.aptDate
    await createAppointmentApi({
      storeId: currentStoreId.value,
      customerName: name,
      phone: phone,
      serviceName: addForm.value.serviceName,
      servicePrice: svcPrice,
      aptDate: targetAptDate,
      aptTime: timeSlotStr,
      spaceName: addForm.value.spaceName,
      staffName: addForm.value.technicianName,
      status: 'PENDING'
    })
    if (isNewMemberCreated) {
      ElMessage.success(`已自动为新顾客【${name}】建档开通本店普通会员，预约排班登记成功！`)
    } else {
      ElMessage.success(`会员【${name}】预约排班登记成功！`)
    }
    openAddDialog.value = false
    await loadServerAppointments(targetAptDate)
  } catch (err: any) {
    console.error('handleSaveAppointment error:', err)
  }
}
</script>

<style scoped>
.appointment-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.main-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
}

.header-box {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.title {
  font-size: 16px;
  font-weight: 800;
  color: #0f172a;
}

.header-right {
  display: flex;
  align-items: center;
}

.filter-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.apt-no {
  font-family: monospace;
  font-weight: 600;
  color: #0284c7;
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

/* 控制条通用样式 */
.board-top-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  background: #f8fafc;
  padding: 10px 16px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  margin-bottom: 16px;
}

.bar-left {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.bar-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.date-stepper {
  display: flex;
  align-items: center;
  gap: 6px;
}

.day-date-label, .week-range-text, .month-range-text {
  font-weight: 700;
  font-size: 14px;
  color: #1e293b;
}

/* ========================================================================== */
/* 日看板样式 (0-24h 网格矩阵) */
/* ========================================================================== */
.timeline-scroll-container {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
}

.timeline-grid {
  min-width: 980px;
}

.grid-header-row {
  display: flex;
  background: #f1f5f9;
  border-bottom: 1px solid #cbd5e1;
  position: sticky;
  top: 0;
  z-index: 2;
}

.time-col-header {
  width: 110px;
  flex-shrink: 0;
  padding: 10px 12px;
  font-weight: 700;
  font-size: 12px;
  color: #475569;
  border-right: 1px solid #e2e8f0;
  text-align: center;
}

.lane-col-header {
  flex: 1;
  min-width: 170px;
  padding: 8px 12px;
  border-right: 1px solid #e2e8f0;
  text-align: center;
}

.lane-title {
  font-weight: 700;
  font-size: 13px;
  color: #0f172a;
}

.lane-sub {
  font-size: 11px;
  color: #64748b;
  margin-top: 2px;
}

.grid-hour-row {
  display: flex;
  border-bottom: 1px solid #f1f5f9;
  min-height: 72px;
}

.time-cell {
  width: 110px;
  flex-shrink: 0;
  border-right: 1px solid #e2e8f0;
  background: #fafafa;
  display: flex;
  align-items: center;
  justify-content: center;
}

.hour-mark {
  font-family: monospace;
  font-size: 13px;
  font-weight: 700;
  color: #64748b;
}

.slot-cell {
  flex: 1;
  min-width: 170px;
  border-right: 1px solid #f1f5f9;
  padding: 4px;
  position: relative;
  cursor: pointer;
  transition: background-color 0.2s;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.slot-cell:hover {
  background-color: #f8fafc;
}

.slot-cell:hover .slot-free-hint {
  opacity: 1;
}

.slot-free-hint {
  opacity: 0;
  font-size: 11px;
  color: #94a3b8;
  text-align: center;
  margin-top: 18px;
  transition: opacity 0.2s;
}

/* 预约卡片 */
.timeline-appointment-card {
  border-radius: 6px;
  padding: 6px 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  font-size: 11px;
}

.timeline-appointment-card.status-pending {
  background: #fffbeb;
  border-left: 3px solid #f59e0b;
}

.timeline-appointment-card.status-serving {
  background: #fef2f2;
  border-left: 3px solid #ef4444;
}

.timeline-appointment-card.status-completed {
  background: #f0fdf4;
  border-left: 3px solid #10b981;
}

.timeline-appointment-card.status-cancelled {
  background: #f8fafc;
  border-left: 3px solid #94a3b8;
  opacity: 0.6;
}

.c-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 3px;
}

.c-time {
  font-weight: 700;
  color: #0f172a;
}

.c-name {
  font-weight: 600;
  color: #1e293b;
  display: flex;
  align-items: center;
  gap: 4px;
}

.vip-tag {
  background: #fef08a;
  color: #854d0e;
  font-size: 10px;
  font-weight: 700;
  padding: 0 4px;
  border-radius: 3px;
}

.c-proj {
  color: #475569;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin: 2px 0;
}

.c-meta {
  color: #64748b;
  font-size: 10px;
}

.c-actions {
  margin-top: 4px;
  display: flex;
  justify-content: flex-end;
}

/* ========================================================================== */
/* 周看板样式 */
/* ========================================================================== */
.week-columns-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 10px;
}

.week-day-col {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  min-height: 480px;
  display: flex;
  flex-direction: column;
}

.week-day-col.is-today {
  border-color: #38bdf8;
  background: #f0f9ff;
}

.week-col-head {
  padding: 10px 8px;
  text-align: center;
  border-bottom: 1px solid #e2e8f0;
  background: #ffffff;
  border-top-left-radius: 7px;
  border-top-right-radius: 7px;
}

.day-name {
  font-weight: 700;
  font-size: 13px;
  color: #0f172a;
}

.day-date {
  font-size: 12px;
  color: #64748b;
  margin: 2px 0 6px;
}

.week-col-body {
  padding: 8px 6px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
}

.week-apt-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 8px;
  font-size: 12px;
  transition: all 0.2s;
}

.week-apt-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
}

.week-apt-card.status-pending {
  border-left: 3px solid #f59e0b;
}

.week-apt-card.status-serving {
  border-left: 3px solid #ef4444;
}

.week-apt-card.status-completed {
  border-left: 3px solid #10b981;
}

.w-time-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.w-time {
  font-weight: 700;
  color: #0284c7;
}

.w-cust-row {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  margin-bottom: 2px;
}

.w-tech {
  color: #64748b;
  font-size: 11px;
}

.w-proj-row {
  font-size: 11px;
  color: #334155;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.w-space-row {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
}

.w-card-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 4px;
  border-top: 1px dashed #f1f5f9;
  padding-top: 4px;
}

.week-quick-add {
  text-align: center;
  padding: 8px;
  border: 1px dashed #cbd5e1;
  border-radius: 6px;
  color: #94a3b8;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
  margin-top: auto;
}

.week-quick-add:hover {
  border-color: #0284c7;
  color: #0284c7;
  background: #ffffff;
}

/* ========================================================================== */
/* 月看板样式 */
/* ========================================================================== */
.month-calendar-grid {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  background: #ffffff;
}

.m-week-header-row {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  background: #f1f5f9;
  border-bottom: 1px solid #e2e8f0;
}

.m-week-header-cell {
  padding: 10px;
  text-align: center;
  font-weight: 700;
  font-size: 13px;
  color: #475569;
}

.m-week-header-cell.weekend {
  color: #ea580c;
}

.m-days-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
}

.m-day-cell {
  min-height: 95px;
  border-right: 1px solid #f1f5f9;
  border-bottom: 1px solid #f1f5f9;
  padding: 6px;
  cursor: pointer;
  transition: background-color 0.2s;
  display: flex;
  flex-direction: column;
}

.m-day-cell:hover {
  background-color: #f8fafc;
}

.m-day-cell.not-current-month {
  background-color: #fafafa;
  opacity: 0.45;
}

.m-day-cell.is-today {
  background-color: #eff6ff;
}

.m-day-cell.is-selected {
  background-color: #e0f2fe;
  box-shadow: inset 0 0 0 2px #0284c7;
}

.m-day-cell.is-weekend-cell {
  background-color: #fbfdff;
}

.m-day-cell.is-holiday-cell {
  background-color: #fff9f9;
}

.wk-rest-badge {
  font-size: 10px;
  background: #ea580c;
  color: #fff;
  padding: 1px 4px;
  border-radius: 4px;
  margin-left: 4px;
  font-weight: bold;
}

.m-day-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.m-day-left-meta {
  display: flex;
  align-items: center;
  gap: 4px;
}

.m-day-number {
  font-weight: 700;
  font-size: 13px;
  color: #1e293b;
}

.m-holiday-tag {
  font-size: 10px;
  font-weight: 700;
  color: #dc2626;
  background: #fee2e2;
  padding: 1px 5px;
  border-radius: 4px;
  line-height: 1.2;
  border: 1px solid #fca5a5;
  white-space: nowrap;
}

.m-weekend-tag {
  font-size: 10px;
  font-weight: 700;
  color: #d97706;
  background: #fef3c7;
  padding: 1px 4px;
  border-radius: 4px;
  line-height: 1.2;
}

.m-apt-badge {
  background: #0284c7;
  color: #ffffff;
  font-size: 10px;
  font-weight: 700;
  padding: 1px 5px;
  border-radius: 10px;
}

.m-day-pills {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.m-apt-pill {
  font-size: 10px;
  padding: 2px 4px;
  border-radius: 4px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  display: flex;
  gap: 4px;
}

.m-apt-pill.status-pending {
  background: #fef3c7;
  color: #92400e;
}

.m-apt-pill.status-serving {
  background: #fee2e2;
  color: #b91c1c;
}

.m-apt-pill.status-completed {
  background: #dcfce7;
  color: #166534;
}

.m-more-text {
  font-size: 10px;
  color: #64748b;
  text-align: right;
  margin-top: 1px;
}

.month-day-detail-box {
  margin-top: 16px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}
</style>
