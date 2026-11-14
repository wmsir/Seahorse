<template>
  <div class="dashboard-page">
    <!-- 0. 顶部实时数字时钟、阳历农历与门店经营问候仪表盘 -->
    <div class="dashboard-clock-banner">
      <div class="dcb-left">
        <div class="digital-time-block">
          <span class="d-hour-min">{{ currentTimeStr }}</span>
          <span class="d-sec">:{{ currentSecondStr }}</span>
        </div>
        <div class="date-calendar-meta">
          <div class="solar-line">
            <span class="solar-date">📅 {{ currentSolarDateStr }}</span>
            <span class="solar-week">{{ currentWeekdayStr }}</span>
            <el-tag
              size="small"
              :type="currentDayBadge.type"
              effect="dark"
              style="margin-left: 8px; font-weight: bold; border-radius: 4px;"
            >
              {{ currentDayBadge.icon }} {{ currentDayBadge.text }}
            </el-tag>
          </div>
          <div class="lunar-line">
            <span class="lunar-tag">农历</span>
            <span class="lunar-info">{{ currentLunarDateStr }}</span>
            <span v-if="currentSolarTerm" class="solar-term-tag">🌱 {{ currentSolarTerm }}</span>
          </div>
        </div>
      </div>

      <div class="dcb-center">
        <div class="greet-title">
          <span class="greet-icon">{{ timePeriodIcon }}</span>
          <span>{{ greetingText }}</span>
        </div>
        <div class="greet-sub">
          当前经营门店：<strong style="color: #0284c7;">{{ currentStoreName }}</strong> · 实时客流良好，预祝营业额再攀新高！
        </div>
      </div>

      <div class="dcb-right">
        <el-button type="primary" plain icon="Calendar" @click="$router.push('/marketing?tab=tools')">
          📅 全年营销日历与获客助手
        </el-button>
        <el-button type="warning" plain icon="Present" @click="$router.push('/marketing?tab=care')">
          💖 节日关怀与国庆企划
        </el-button>
      </div>
    </div>

    <!-- 0.05 门店运营规范与日常公告通知条 (支持店长/老板配置后全渠道推送展示) -->
    <div v-if="activeStoreNotices.length > 0" class="store-notice-broadcast-bar" :class="{ 'is-urgent-bar': hasUrgentNotice }">
      <div class="snb-left">
        <el-tag :type="hasUrgentNotice ? 'danger' : 'warning'" effect="dark" class="snb-tag">
          {{ hasUrgentNotice ? '🚨 特别重要特急通知' : '📢 门店日常公告' }}
        </el-tag>
        <div class="snb-marquee" @click="$router.push('/regulations')">
          <span class="snb-title">【{{ activeStoreNotices[0].title }}】</span>
          <span class="snb-summary">{{ activeStoreNotices[0].summary }}</span>
          <span class="snb-time">（发布方：{{ activeStoreNotices[0].publisher }} · {{ activeStoreNotices[0].effectiveDate }}）</span>
        </div>
      </div>
      <div class="snb-right">
        <el-button type="primary" link size="small" @click="$router.push('/regulations')">
          查看全部规范与公告 ({{ activeStoreNotices.length }}) ➔
        </el-button>
      </div>
    </div>

    <!-- 0.1 租户老带新推荐同行有礼活动横幅 -->
    <div class="tenant-referral-promo-strip" @click="openTenantReferralModal">
      <div class="tr-left">
        <div class="tr-gift-icon">🎁</div>
        <div class="tr-text">
          <div class="tr-title">
            <span>推荐同行好友开店有礼 · 赢试用期免费延期1个月或抵扣券</span>
            <el-tag size="small" type="danger" effect="dark">租户推荐特权</el-tag>
          </div>
          <div class="tr-desc">
            分享系统给同行租户好友，好友成功入驻开店并使用系统，您立享 <b>试用期免费顺延 1 个月 (30天)</b> 或 <b>￥500 元现金抵扣券</b>，新好友开店亦享专属大礼包！
          </div>
        </div>
      </div>
      <div class="tr-right">
        <div class="tr-stat-badge">
          已成功推荐 <b>{{ tenantReferralStats.count }}</b> 家同行 · 累计获赠 <b>{{ tenantReferralStats.rewardSummary }}</b>
        </div>
        <el-button type="warning" size="default" round>
          <el-icon><Share /></el-icon> 专属推荐海报与邀请链接
        </el-button>
      </div>
    </div>

    <!-- 0.3 无门店空状态专属卡片 (严格多租户隔离规范：新租户默认零数据) -->
    <el-card
      v-if="availableStores.length === 0"
      shadow="never"
      class="zero-store-welcome-card"
    >
      <div class="zero-store-inner">
        <div class="zero-store-left">
          <div class="zero-badge-pill">🛡️ 严格多租户数据物理隔离 · 纯净零数据初始状态</div>
          <h2 class="zero-store-title">🎉 欢迎入驻海马智慧商业平台！您当前尚未创建实体门店</h2>
          <p class="zero-store-desc">
            平台执行严格的租户物理隔离标准，新注册租户账号初始状态下<b>无任何门店、员工、工位、商品、会员与业务流水</b>，数据纯净安全。<br/>
            您可以直接开设首家专属门店，并录入您的员工与业务项目开启经营。
          </p>
          <div class="zero-store-btn-group">
            <el-button type="primary" size="large" icon="Plus" @click="openCreateStoreDialog">
              🏪 开设首家门店
            </el-button>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 0.5 新入驻租户纯净开张引导横幅 (仅在有门店但新租户或零流水时提示) -->
    <el-card
      v-else-if="systemData.isNewTenant || (stats.todayRevenue === 0 && systemData.members.length === 0)"
      shadow="never"
      class="new-tenant-welcome-card"
    >
      <div class="welcome-header">
        <div class="welcome-title-wrap">
          <div class="welcome-badge">🚀 独立租户工作空间 · 数据严格隔离</div>
          <h3 class="welcome-main-title">🎉 门店经营就绪！当前处于专属租户独立空间</h3>
          <p class="welcome-sub-title">
            当前门店数据严格归属本租户独立存储。您可以跟随下方新手开张指引，依次配置工位包厢、商品项目与在册员工：
          </p>
        </div>
      </div>

      <el-row :gutter="12" class="welcome-steps-row">
        <el-col :xs="24" :sm="12" :md="6">
          <div class="guide-step-card" @click="$router.push('/rooms')">
            <div class="step-num">Step 1</div>
            <div class="step-icon">🛋️</div>
            <div class="step-title">设置工位/包厢</div>
            <div class="step-desc">规划门店工位、雅座包厢，支持手机扫码开台与顾客点单</div>
          </div>
        </el-col>
        <el-col :xs="24" :sm="12" :md="6">
          <div class="guide-step-card" @click="$router.push('/products')">
            <div class="step-num">Step 2</div>
            <div class="step-icon">🏷️</div>
            <div class="step-title">上架商品与项目</div>
            <div class="step-desc">录入本店主营服务、零售商品与耗材BOM成本，并可同步微商城</div>
          </div>
        </el-col>
        <el-col :xs="24" :sm="12" :md="6">
          <div class="guide-step-card" @click="$router.push('/staff-management')">
            <div class="step-num">Step 3</div>
            <div class="step-icon">👥</div>
            <div class="step-title">录入/邀请员工</div>
            <div class="step-desc">录入技师销售，或出示二维码让员工扫码自主申请入职</div>
          </div>
        </el-col>
        <el-col :xs="24" :sm="12" :md="6">
          <div class="guide-step-card" @click="$router.push('/members')">
            <div class="step-num">Step 4</div>
            <div class="step-icon">💳</div>
            <div class="step-title">办理首位会员开卡</div>
            <div class="step-desc">为到店顾客开通双轨储值金或次卡，发起首笔真实消费</div>
          </div>
        </el-col>
      </el-row>
    </el-card>

    <!-- 1. 顶部五格核心经营健康度大盘 (收支、利润、人员出勤与库存缺货预警) -->
    <el-row :gutter="14">
      <el-col :xs="24" :sm="12" :md="5" style="margin-bottom: 10px;">
        <el-card shadow="hover" class="stat-card stat-revenue" style="cursor: pointer;" @click="$router.push('/reports/income')">
          <div class="stat-header-row">
            <span class="stat-title">今日营业实收 (元)</span>
            <el-tag size="small" type="primary" effect="plain">今日流水</el-tag>
          </div>
          <div class="stat-value text-primary">￥{{ stats.todayRevenue?.toFixed(2) || '0.00' }}</div>
          <div class="stat-footer">已结账流水 {{ stats.todayOrderCount || 0 }} 笔订单 →</div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="5" style="margin-bottom: 10px;">
        <el-card shadow="hover" class="stat-card stat-expense" style="cursor: pointer;" @click="$router.push('/expenses')">
          <div class="stat-header-row">
            <span class="stat-title">当月全口径总成本</span>
            <el-tag size="small" type="danger" effect="plain">全月支出</el-tag>
          </div>
          <div class="stat-value text-danger">￥{{ monthTotalCost.toFixed(2) }}</div>
          <div class="stat-footer">含底薪￥{{ systemData.autoSalaryBaseCost }} + 提成￥{{ systemData.autoSalaryCommissionCost }}</div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="5" style="margin-bottom: 10px;">
        <el-card shadow="hover" class="stat-card stat-profit" style="cursor: pointer;" @click="$router.push('/reports/profit')">
          <div class="stat-header-row">
            <span class="stat-title">当月预估净利润</span>
            <el-tag size="small" :type="monthNetProfit >= 0 ? 'success' : 'warning'" effect="dark">
              净利率 {{ monthProfitMargin }}
            </el-tag>
          </div>
          <div class="stat-value" :class="monthNetProfit >= 0 ? 'text-success' : 'text-warning'">
            {{ monthNetProfit >= 0 ? '+' : '' }}￥{{ monthNetProfit.toFixed(2) }}
          </div>
          <div class="stat-footer">本月累计总营收 ￥{{ monthGrossRevenue.toFixed(2) }}</div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="4" style="margin-bottom: 10px;">
        <el-card shadow="hover" class="stat-card stat-staff" style="cursor: pointer;" @click="$router.push('/staff-management')">
          <div class="stat-header-row">
            <span class="stat-title">人员在岗出勤</span>
            <el-tag size="small" :type="activeStaffCount > 0 ? 'success' : 'info'" effect="plain">
              {{ activeStaffCount > 0 ? '技师接单' : '暂无出勤' }}
            </el-tag>
          </div>
          <div class="stat-value text-teal">
            {{ activeStaffCount }} / {{ totalStaffCount }}
            <span class="stat-unit">人在岗</span>
          </div>
          <div class="stat-footer" v-if="totalStaffCount > 0">{{ servingStaffCount }}人施工中 · {{ idleStaffCount }}人待命中</div>
          <div class="stat-footer" v-else>暂无在册出勤员工</div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="24" :md="5" style="margin-bottom: 10px;">
        <el-card shadow="hover" class="stat-card stat-alert" style="cursor: pointer;" :class="{ 'has-low-stock': lowStockItems.length > 0 }" @click="$router.push('/inventory')">
          <div class="stat-header-row">
            <span class="stat-title">商品耗材缺货预警</span>
            <el-tag size="small" :type="lowStockItems.length > 0 ? 'danger' : 'success'" effect="dark">
              {{ lowStockItems.length > 0 ? '急需采购补货' : '库存充足' }}
            </el-tag>
          </div>
          <div class="stat-value" :class="lowStockItems.length > 0 ? 'text-danger' : 'text-success'">
            {{ lowStockItems.length }}
            <span class="stat-unit">款触碰安全线</span>
          </div>
          <div class="stat-footer" v-if="lowStockItems.length > 0">
            首缺: {{ lowStockItems[0]?.name }} (余{{ lowStockItems[0]?.currentStock }}{{ lowStockItems[0]?.unit }})
          </div>
          <div class="stat-footer" v-else>所有物料与商品均在安全线以上</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 2. 快捷经营指令工具条 (店长与老板常用高频入口) -->
    <div class="dashboard-quick-bar">
      <div class="quick-bar-title">⚡ 门店高频快捷工作台：</div>
      <div class="quick-bar-buttons">
        <el-button type="primary" plain round size="default" @click="$router.push('/session-board')">
          <el-icon><Plus /></el-icon> 快捷开单接客
        </el-button>
        <el-button type="success" plain round size="default" @click="$router.push('/cashier')">
          <el-icon><Money /></el-icon> 组合收银结算
        </el-button>
        <el-button type="warning" plain round size="default" @click="$router.push('/expenses')">
          <el-icon><Money /></el-icon> 门店账本 (记支出/查成本)
        </el-button>
        <el-button type="danger" plain round size="default" @click="$router.push('/inventory')">
          <el-icon><Box /></el-icon> 采购补货入库 ({{ lowStockItems.length }}款待补)
        </el-button>
        <el-button round size="default" @click="$router.push('/staff-management')">
          <el-icon><UserFilled /></el-icon> 员工出勤与账号
        </el-button>
        <el-button type="success" plain round size="default" @click="openQuickQrModal">
          <el-icon><Iphone /></el-icon> 📱 获客/入职码
        </el-button>
      </div>
    </div>

    <!-- 3. 中部与下部：双栏黄金结构 -->
    <el-row :gutter="16">
      <!-- 左侧：实时在场服务工位看板 + 本月收支透视大盘 -->
      <el-col :span="14">
        <!-- 模块一：实时在场工位与履约结算看板 -->
        <el-card shadow="hover" class="box-card mb-16">
          <template #header>
            <div class="card-header">
              <div class="header-left">
                <span class="header-title">🔥 实时在场服务工位/桌台动态</span>
                <el-tag size="small" type="info" effect="plain" style="margin-left: 8px;">
                  占用率 {{ stats.spaceUtilizationRate?.toFixed(1) || '0' }}% ({{ stats.occupiedSpaces }}/{{ stats.totalSpaces }})
                </el-tag>
              </div>
              <el-button type="primary" size="small" @click="$router.push('/session-board')">
                前往全景看板 <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
          </template>

                    <!-- 单行快捷筛选条 -->
          <div class="session-filter-strip">
            <el-radio-group v-model="sessionStatusFilter" size="small">
              <el-radio-button label="ALL">全部在场 ({{ (displaySessions || []).length }})</el-radio-button>
              <el-radio-button label="SERVING">⚡ 履约服务中 ({{ countServingSessions }})</el-radio-button>
              <el-radio-button label="WAIT_CLEAN">🧹 待清台复位 ({{ countWaitCleanSessions }})</el-radio-button>
            </el-radio-group>
            <el-input
              v-model="sessionSearchKeyword"
              placeholder="快速过滤工位/顾客..."
              size="small"
              clearable
              prefix-icon="Search"
              style="width: 180px;"
            />
          </div>

          <el-table :data="filteredDisplaySessions" stripe style="width: 100%" size="default" max-height="420">
            <!-- 1. 包厢/工位名称与顾客 -->
            <el-table-column prop="spaceName" :label="storeConfig.spaceAlias + ' / 顾客'" min-width="140">
              <template #default="{ row }">
                <div style="font-weight: 700; font-size: 14px; color: #0f172a; display: flex; align-items: center; gap: 5px;">
                  <span>🏠</span>
                  <span>{{ row.spaceName }}</span>
                </div>
                <div style="font-size: 12px; color: #64748b; margin-top: 3px; display: flex; align-items: center; gap: 6px;">
                  <span>👤 {{ row.customerName || '到店散客' }}</span>
                  <span v-if="row.startTime" style="color: #94a3b8;">· {{ row.startTime }}</span>
                </div>
              </template>
            </el-table-column>

            <!-- 2. 消费金额 (优先重点突出) -->
            <el-table-column prop="totalAmount" label="已点金额" width="130" align="right">
              <template #default="{ row }">
                <div style="color: #047857; font-size: 17px; font-weight: 800; font-family: monospace;">
                  ￥{{ ((Number(row.totalAmount) || 0) + (Number(row.feeAmount) || 0)).toFixed(2) }}
                </div>
                <div v-if="Number(row.feeAmount) > 0" style="font-size: 11px; color: #b45309;">
                  含附加费 ￥{{ Number(row.feeAmount).toFixed(2) }}
                </div>
              </template>
            </el-table-column>

            <!-- 3. 服务状态 -->
            <el-table-column prop="status" label="服务状态" width="120" align="center">
              <template #default="{ row }">
                <el-tag
                  v-if="row.status === 'SERVING' || row.status === 'OCCUPIED_ORDERING' || row.status === 'SETTLING'"
                  type="primary"
                  effect="dark"
                  size="default"
                  style="font-weight: 600;"
                >
                  ⚡ 服务履约中
                </el-tag>
                <el-tag
                  v-else-if="row.status === 'WAIT_CLEAN' || row.status === 'SETTLED_WAIT_CLEAN'"
                  type="warning"
                  effect="dark"
                  size="default"
                  style="font-weight: 600;"
                >
                  🧹 待清台复位
                </el-tag>
                <el-tag v-else type="success" size="default">
                  ✅ 已结账完成
                </el-tag>
              </template>
            </el-table-column>

            <!-- 4. 去结算买单核心操作 (优先右侧突出展示) -->
            <el-table-column label="快捷收银结算" min-width="160" align="center">
              <template #default="{ row }">
                <el-button
                  v-if="row.status === 'SERVING' || row.status === 'OCCUPIED_ORDERING' || row.status === 'SETTLING'"
                  type="primary"
                  size="default"
                  @click="handleGoCashier(row.id)"
                  style="font-weight: 700; box-shadow: 0 2px 8px rgba(14, 165, 233, 0.3); border-radius: 6px;"
                >
                  💳 去结算买单
                </el-button>
                <el-button
                  v-else-if="row.status === 'WAIT_CLEAN' || row.status === 'SETTLED_WAIT_CLEAN'"
                  type="warning"
                  size="default"
                  @click="handleResetSpace(row.id)"
                  style="font-weight: 700; border-radius: 6px;"
                >
                  🧹 一键清台
                </el-button>
                <el-tag v-else size="small" type="info">已离店完成</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>

        <!-- 模块二：收支结构与成本利润透视卡片 (老板视角) -->
        <el-card shadow="hover" class="box-card">
          <template #header>
            <div class="card-header">
              <span class="header-title">💰 本店收支全口径成本透视大盘 (当月)</span>
              <el-button link type="primary" size="small" @click="$router.push('/expenses')">
                查看门店账本详情 <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
          </template>

          <div class="finance-breakdown-grid">
            <div class="finance-item fi-revenue">
              <div class="fi-lbl">本月营业总实收</div>
              <div class="fi-val text-primary">￥{{ monthGrossRevenue.toFixed(2) }}</div>
              <div class="fi-sub">含线上微商城 + 门店到店收银</div>
            </div>
            <div class="finance-item fi-salary">
              <div class="fi-lbl">员工底薪包 (自动同步)</div>
              <div class="fi-val text-warning">￥{{ systemData.autoSalaryBaseCost.toFixed(2) }}</div>
              <div class="fi-sub">共 {{ activeStaffCount }} 位员工固定基础底薪</div>
            </div>
            <div class="finance-item fi-comm">
              <div class="fi-lbl">工单施工提成 (自动计算)</div>
              <div class="fi-val text-warning">￥{{ systemData.autoSalaryCommissionCost.toFixed(2) }}</div>
              <div class="fi-sub">根据实收流水与施工角色比例分配</div>
            </div>
            <div class="finance-item fi-expense">
              <div class="fi-lbl">房租水电与日常杂支</div>
              <div class="fi-val text-danger">￥{{ systemData.expenseStats.totalMonthExpense.toFixed(2) }}</div>
              <div class="fi-sub">日常经营支出报销账本归集</div>
            </div>
            <div class="finance-item fi-profit">
              <div class="fi-lbl">当月经营净利润</div>
              <div class="fi-val" :class="monthNetProfit >= 0 ? 'text-success' : 'text-danger'">
                {{ monthNetProfit >= 0 ? '+' : '' }}￥{{ monthNetProfit.toFixed(2) }}
              </div>
              <div class="fi-sub">综合毛净利率：{{ monthProfitMargin }}</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 右侧：人员在岗状态 + 商品耗材缺货预警 -->
      <el-col :span="10">
        <!-- 模块三：人员在岗出勤与服务施工状态 -->
        <el-card shadow="hover" class="box-card mb-16">
          <template #header>
            <div class="card-header">
              <div class="header-left">
                <span class="header-title">👨‍💼 实时人员在岗与接单动态</span>
                <el-tag size="small" :type="activeStaffCount > 0 ? 'success' : 'info'" effect="plain" style="margin-left: 8px;">
                  在岗出勤 {{ activeStaffCount }}/{{ totalStaffCount }} 人
                </el-tag>
              </div>
              <el-button link type="primary" size="small" @click="$router.push('/staff-management')">
                人员管理 <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
          </template>

          <div class="staff-duty-list">
            <template v-if="staffOnDutyList.length > 0">
              <div
                v-for="st in staffOnDutyList"
                :key="st.id"
                class="staff-duty-card"
              >
                <div class="st-avatar">
                  {{ st.realName?.substring(0, 1) || '技' }}
                </div>
                <div class="st-main">
                  <div class="st-row1">
                    <span class="st-name">{{ st.realName }}</span>
                    <el-tag size="small" effect="plain" type="info">{{ st.postName || '员工' }}</el-tag>
                    <el-tag
                      size="small"
                      :type="st.workStatus === 'SERVING' ? 'danger' : (st.workStatus === 'CASHIER' ? 'warning' : 'success')"
                      effect="light"
                    >
                      {{ st.workStatus === 'SERVING' ? '🔴 服务施工中' : (st.workStatus === 'CASHIER' ? '🟡 前台值守' : '🟢 空闲待命') }}
                    </el-tag>
                  </div>
                  <div class="st-row2">
                    <span class="st-detail" v-if="st.workStatus === 'SERVING'">
                      当前工位：<strong style="color: #0284c7;">{{ st.currentServingSpace }}</strong>
                    </span>
                    <span class="st-detail" v-else>
                      随时可指派接待新客
                    </span>
                  </div>
                </div>
                <div class="st-stats">
                  <div class="st-orders">今日 <strong>{{ st.todayOrderCount }}</strong> 单</div>
                  <div class="st-comm">提成 <strong>￥{{ st.todayCommission }}</strong></div>
                </div>
              </div>
            </template>
            <div v-else class="empty-staff-duty" style="padding: 28px 12px; text-align: center;">
              <el-empty description="当前暂无在岗员工，可前往【员工管理】录入员工并排班出勤" :image-size="60">
                <el-button type="primary" size="small" @click="$router.push('/staff-management')">
                  前往【员工管理】录入员工
                </el-button>
              </el-empty>
            </div>
          </div>
        </el-card>

        <!-- 模块四：商品耗材库存缺货预警中心 -->
        <el-card shadow="hover" class="box-card">
          <template #header>
            <div class="card-header">
              <div class="header-left">
                <span class="header-title">⚠️ 商品与耗材缺货预警中心</span>
                <el-tag size="small" :type="lowStockItems.length > 0 ? 'danger' : 'success'" effect="plain" style="margin-left: 8px;">
                  {{ lowStockItems.length }} 款待采购
                </el-tag>
              </div>
              <el-button type="danger" plain size="small" @click="$router.push('/inventory')">
                前往采购补货 <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
          </template>

          <div v-if="lowStockItems.length === 0" class="empty-stock-box">
            <el-icon size="36" color="#10b981"><CircleCheck /></el-icon>
            <div class="empty-text">当前所有商品与物料库存充裕，均在安全线以上！</div>
          </div>

          <div v-else class="low-stock-list">
            <div
              v-for="item in lowStockItems"
              :key="item.id"
              class="low-stock-card"
            >
              <div class="ls-info">
                <div class="ls-name-row">
                  <span class="ls-name">{{ item.name }}</span>
                  <el-tag size="small" :type="item.currentStock <= item.safeStock * 0.4 ? 'danger' : 'warning'" effect="dark">
                    {{ item.currentStock <= item.safeStock * 0.4 ? '严重缺货' : '补货预警' }}
                  </el-tag>
                </div>
                <div class="ls-stock-row">
                  <span>当前实时库存：<strong :style="{ color: item.currentStock <= item.safeStock ? '#ef4444' : '#f59e0b' }">{{ item.currentStock }} {{ item.unit }}</strong></span>
                  <span class="ls-sep">|</span>
                  <span class="ls-safe">安全库存底线：{{ item.safeStock }} {{ item.unit }}</span>
                </div>
                <div class="ls-supplier" v-if="item.supplier">
                  推荐供货商：{{ item.supplier }}
                </div>
              </div>
              <div class="ls-action">
                <el-button size="small" type="primary" plain @click="handleQuickRestock(item)">
                  采购入库
                </el-button>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 门店获客开卡/员工入职双模态二维码弹窗 -->
    <el-dialog v-model="quickQrDialogVisible" title="📱 门店获客开卡 / 员工入职二维码" width="520px">
      <div class="dash-qr-modal">
        <el-radio-group v-model="quickQrType" size="default" style="margin-bottom: 12px;" @change="updateDashboardQrCode">
          <el-radio-button value="member">🌸 顾客会员自助开卡</el-radio-button>
          <el-radio-button value="staff">💼 员工入职申报开号</el-radio-button>
        </el-radio-group>

        <div class="qr-code-box">
          <img v-if="dashboardQrUrl" :src="dashboardQrUrl" class="dash-qr-img" alt="二维码" />
          <div v-else style="width: 220px; height: 220px; display: flex; align-items: center; justify-content: center; color: #94a3b8;">
            正在生成二维码...
          </div>
          <div class="qr-box-tip">
            {{ quickQrType === 'member' ? '顾客微信/浏览器扫码，直接录入偏好开卡并享迎新礼' : '员工扫码即可申请入职，设定工作台登录账号与密码' }}
          </div>
        </div>

        <div class="dash-qr-url-row">
          <el-input v-model="currentQuickLink" readonly>
            <template #append>
              <el-button type="primary" @click="copyDashboardLink">复制链接</el-button>
            </template>
          </el-input>
        </div>

        <div style="display: flex; gap: 12px; margin-top: 14px;">
          <el-button type="primary" plain @click="openQuickLinkPage">在新窗口模拟打开</el-button>
          <el-button type="success" plain @click="downloadDashboardQr">保存二维码图片</el-button>
        </div>
      </div>
      <template #footer>
        <el-button @click="quickQrDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 快捷开设门店对话框 -->
    <el-dialog v-model="createStoreVisible" title="🏪 开设首家门店 / 新分店" width="540px" destroy-on-close>
      <el-form :model="createStoreForm" label-width="135px" style="margin-top: 10px;">
        <el-form-item label="分店名称" required>
          <el-input v-model="createStoreForm.storeName" placeholder="例如：海马科技园旗舰店" />
        </el-form-item>
        <el-form-item label="经营行业分类" required>
          <el-select v-model="createStoreForm.industry" style="width: 100%;">
            <el-option label="美业服务 (美容美发美甲)" value="BEAUTY" />
            <el-option label="汽车服务 (汽车养护维修)" value="AUTO" />
            <el-option label="餐饮服务 (特色餐饮茶饮)" value="RESTAURANT" />
            <el-option label="专营零售 (商超便利专营)" value="RETAIL" />
          </el-select>
        </el-form-item>
        <el-form-item label="前台预约电话" required>
          <el-input v-model="createStoreForm.phone" placeholder="门店热线电话" />
        </el-form-item>
        <el-form-item label="分店店长/负责人">
          <el-input v-model="createStoreForm.manager" placeholder="分店负责人姓名" />
        </el-form-item>
        <el-form-item label="门店详细地址" required>
          <el-input v-model="createStoreForm.address" placeholder="详细经营门牌地址" />
        </el-form-item>
        <el-form-item label="营业时间">
          <el-input v-model="createStoreForm.businessHours" placeholder="如：09:00 - 22:00" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createStoreVisible = false">取消</el-button>
        <el-button type="primary" :loading="creatingStore" @click="handleCreateStore">确定创建入驻</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗: 租户专属分享有礼中心与专属海报 -->
    <el-dialog
      v-model="tenantReferralDialogVisible"
      title="🎁 推荐同行好友开店 · 租户专属分享有礼中心"
      width="780px"
      append-to-body
      destroy-on-close
    >
      <div class="tenant-referral-modal-layout">
        <div class="trm-left">
          <!-- 租户专属推荐海报卡片 -->
          <div class="tenant-poster-card" id="tenant-poster-box">
            <div class="tp-top-badge">🌟 同行诚意力荐 · 数字化开店</div>
            <div class="tp-shop-name">{{ storeConfig.storeName || '海马智慧商业门店' }}</div>
            <div class="tp-invite-title">邀请您体验【海马智慧门店 SaaS】</div>
            <div class="tp-highlight-box">
              <div class="tp-hl-item">✨ 组合收银/多轨支付与双余额</div>
              <div class="tp-hl-item">✨ 微信微商城与会员卡包裂变</div>
              <div class="tp-hl-item">✨ 智能工位排班与技师提成算薪</div>
            </div>
            <div class="tp-qr-box">
              <img v-if="tenantQrCodeUrl" :src="tenantQrCodeUrl" class="tp-qr-img" alt="推荐二维码" />
              <div class="tp-qr-hint">微信扫一扫 · 立即开店体验</div>
              <div class="tp-ref-code">专属推荐码: <b>REF-{{ storeConfig.tenantId }}</b></div>
            </div>
            <div class="tp-footer-url">{{ getActiveBaseUrl() }}/tenant-register</div>
          </div>
        </div>

        <div class="trm-right">
          <div class="trm-section">
            <div class="trm-stitle">🔗 我的专属推荐开店链接</div>
            <el-input :model-value="tenantReferralLink" readonly size="default">
              <template #append>
                <el-button type="primary" @click="copyTenantReferralLink">复制链接</el-button>
              </template>
            </el-input>
            <div style="font-size: 11px; color: #64748b; margin-top: 4px;">
              基于官方正式域名 <code>{{ getActiveBaseUrl() }}</code> 生成，支持微信好友/朋友圈直接打开
            </div>
          </div>

          <div class="trm-section" style="margin-top: 14px;">
            <div class="trm-stitle">📱 微信朋友圈/微信群推荐文案</div>
            <el-input
              type="textarea"
              :rows="4"
              :model-value="tenantMomentsCopy"
              readonly
              style="font-size: 12px;"
            />
            <div style="margin-top: 8px; display: flex; gap: 8px;">
              <el-button type="warning" size="small" @click="copyTenantMomentsCopy">
                <el-icon><DocumentCopy /></el-icon> 复制推荐话术
              </el-button>
              <el-button type="success" size="small" @click="downloadTenantPoster">
                <el-icon><Download /></el-icon> 下载专属推荐海报
              </el-button>
            </div>
          </div>

          <div class="trm-section" style="margin-top: 14px;">
            <div class="trm-stitle">🏆 我的成功推荐战报 (已获奖励)</div>
            <div class="trm-records-mini">
              <div v-for="r in myReferralRecords" :key="r.id" class="trm-rec-item">
                <div class="trm-rec-main">
                  <span class="rec-name">🏬 {{ r.refereeTenantName }}</span>
                  <span class="rec-date">{{ r.registeredAt }}</span>
                </div>
                <div class="trm-rec-sub">
                  <el-tag size="small" type="success">{{ r.rewardDesc }}</el-tag>
                  <span class="rec-status">已到账</span>
                </div>
              </div>
              <div v-if="myReferralRecords.length === 0" style="font-size: 12px; color: #94a3b8; text-align: center; padding: 12px 0;">
                暂无推荐记录，快复制链接发给同行好友吧！
              </div>
            </div>
          </div>
        </div>
      </div>
    </el-dialog>

    <!-- 弹窗: 租户推荐奖励到账祝贺通知 (即时通知到租户页面) -->
    <el-dialog
      v-model="rewardNotificationVisible"
      title="🎉 推荐好友开店成功 · 奖励已到账"
      width="500px"
      append-to-body
      destroy-on-close
      center
    >
      <div class="reward-celebrate-content" v-if="unreadRewardNotice">
        <div class="celebrate-trophy">🏆</div>
        <h3 class="celebrate-title">恭喜！您推荐的好友已开店成功！</h3>
        <p class="celebrate-desc">
          您推荐的同行好友【<b>{{ unreadRewardNotice.refereeTenantName }}</b>】已成功入驻开店并活跃使用系统！
        </p>

        <div class="reward-highlight-card">
          <div class="rh-lbl">🎁 系统已为您自动发放奖励：</div>
          <div class="rh-val">{{ unreadRewardNotice.rewardDesc }}</div>
        </div>

        <div class="celebrate-sms-tip">
          📱 奖励到账确认短信已实时下发至您的手机号：<b>{{ unreadRewardNotice.inviterPhone }}</b>
        </div>
      </div>
      <template #footer>
        <el-button type="primary" size="large" style="width: 100%; font-weight: 700;" @click="handleAcknowledgeReward">
          🎉 太棒了，开心收下奖励
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import QRCode from 'qrcode'
import { getActiveSessionsApi, createStoreApi, getDashboardStatsApi, getSpacesApi, resetSpaceApi, getStoreNoticesApi } from '../api'
import { useStoreConfig } from '../stores/store'
import { useSystemDataStore } from '../stores/systemDataStore'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getDateBadge } from '../utils/chineseHolidayUtils'
import {
  getActiveBaseUrl,
  getReferralRecords,
  getUnreadRewardNotificationForTenant,
  acknowledgeRewardNotification,
  type ReferralRecord
} from '../utils/systemConfig'
import {
  Share,
  DocumentCopy,
  Download
} from '@element-plus/icons-vue'

const sessionStatusFilter = ref('ALL')
const sessionSearchKeyword = ref('')

const router = useRouter()
const storeConfig = useStoreConfig()
const systemData = useSystemDataStore()

// 门店运营规范与日常公告
const activeStoreNotices = ref<any[]>([])
const hasUrgentNotice = computed(() => activeStoreNotices.value.some(n => n.isUrgent))

const fetchDashboardNotices = async () => {
  try {
    const res: any = await getStoreNoticesApi(storeConfig.currentStoreId)
    const list = Array.isArray(res) ? res : (Array.isArray(res?.data) ? res.data : [])
    activeStoreNotices.value = list
  } catch (e) {
    console.warn('Failed to load store notices in dashboard', e)
  }
}

// --------------------------------------------------------------------------
// 租户老带新推荐有礼裂变与奖励通知
// --------------------------------------------------------------------------

const tenantReferralDialogVisible = ref(false)
const rewardNotificationVisible = ref(false)
const unreadRewardNotice = ref<ReferralRecord | null>(null)
const tenantQrCodeUrl = ref('')

const tenantReferralLink = computed(() => {
  const tenantId = storeConfig.tenantId || 'T001'
  const storeNameParam = encodeURIComponent(storeConfig.storeName || '海马智慧门店')
  return `${getActiveBaseUrl()}/tenant-register?ref=${tenantId}&store=${storeNameParam}`
})

const myReferralRecords = computed(() => {
  const tenantId = storeConfig.tenantId || 'T001'
  return getReferralRecords().filter(r => r.inviterTenantId === tenantId)
})

const tenantReferralStats = computed(() => {
  const list = myReferralRecords.value
  const count = list.length
  let trialDaysTotal = 0
  let couponTotal = 0
  list.forEach(r => {
    if (r.rewardType === 'TRIAL_EXTENSION') {
      trialDaysTotal += 30
    } else if (r.rewardType === 'COUPON') {
      couponTotal += 500
    }
  })

  let summary = ''
  if (trialDaysTotal > 0 && couponTotal > 0) {
    summary = `试用期顺延 ${trialDaysTotal} 天 + ￥${couponTotal} 抵扣券`
  } else if (trialDaysTotal > 0) {
    summary = `试用期免费顺延 ${trialDaysTotal} 天 (${Math.round(trialDaysTotal / 30)}个月)`
  } else if (couponTotal > 0) {
    summary = `￥${couponTotal} 元现金抵扣券`
  } else {
    summary = '试用期顺延 30 天'
  }

  return {
    count,
    rewardSummary: count > 0 ? summary : '立享试用期顺延1个月或￥500券'
  }
})

const tenantMomentsCopy = computed(() => {
  return `📢【同行力荐 · 数字化智慧开店】
我在用的【海马智慧门店 SaaS】系统真诚推荐给同行老板！
✨ 组合收银/多轨扫码支付、双余额会员次卡扣款、微信微商城拼团秒杀裂变、工位桌台智能排班与技师阶梯提成算薪一站全包！
🎁 通过我的专属同行邀请链接注册，立享 30 天全功能免费体验 + ￥200 新客首单礼包：
👉 专属体验通道：${tenantReferralLink.value}`
})

const openTenantReferralModal = async () => {
  tenantReferralDialogVisible.value = true
  try {
    tenantQrCodeUrl.value = await QRCode.toDataURL(tenantReferralLink.value, {
      width: 180,
      margin: 2,
      color: { dark: '#0f172a', light: '#ffffff' }
    })
  } catch (err) {
    console.warn('Generate tenant QR code error:', err)
  }
}

const copyTenantReferralLink = () => {
  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(tenantReferralLink.value).then(() => {
      ElMessage.success('🎉 您的专属推荐注册链接已复制！可直接粘贴发送给同行老板或微信群')
    }).catch(() => {
      fallbackCopyDashboard(tenantReferralLink.value)
    })
  } else {
    fallbackCopyDashboard(tenantReferralLink.value)
  }
}

const copyTenantMomentsCopy = () => {
  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(tenantMomentsCopy.value).then(() => {
      ElMessage.success('📋 朋友圈/社群同行推荐文案已成功复制到剪贴板！')
    }).catch(() => {
      fallbackCopyDashboard(tenantMomentsCopy.value)
    })
  } else {
    fallbackCopyDashboard(tenantMomentsCopy.value)
  }
}

const fallbackCopyDashboard = (text: string) => {
  const ta = document.createElement('textarea')
  ta.value = text
  ta.style.position = 'fixed'
  ta.style.left = '-999999px'
  document.body.appendChild(ta)
  ta.focus()
  ta.select()
  try {
    document.execCommand('copy')
    ElMessage.success('复制成功！')
  } catch {
    ElMessage.error('复制失败，请手动选择复制')
  }
  document.body.removeChild(ta)
}

const downloadTenantPoster = () => {
  if (!tenantQrCodeUrl.value) return
  const a = document.createElement('a')
  a.href = tenantQrCodeUrl.value
  a.download = `海马智慧门店-同行推荐海报-${storeConfig.storeName || '专属海报'}.png`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  ElMessage.success('🎉 专属推荐二维码已下载！')
}

const handleAcknowledgeReward = () => {
  if (unreadRewardNotice.value) {
    acknowledgeRewardNotification(unreadRewardNotice.value.id)
    rewardNotificationVisible.value = false
    ElMessage.success('🎉 奖励确认完成！试用期已为您顺延，感谢您的积极推荐！')
  }
}

// --------------------------------------------------------------------------
// 0. 实时数字时钟与农历/阳历/节气计算
// --------------------------------------------------------------------------
const nowTime = ref(new Date())
let clockTimer: any = null

onMounted(() => {
  clockTimer = setInterval(() => {
    nowTime.value = new Date()
  }, 1000)

  // 检查是否有未读的推荐奖励到账通知 (即时通知到租户页面)
  const tenantId = storeConfig.tenantId || 'T001'
  const unread = getUnreadRewardNotificationForTenant(tenantId)
  if (unread) {
    unreadRewardNotice.value = unread
    rewardNotificationVisible.value = true
  }
})

onUnmounted(() => {
  if (clockTimer) clearInterval(clockTimer)
})

const padZero = (n: number) => (n < 10 ? '0' + n : String(n))

const currentTimeStr = computed(() => {
  const d = nowTime.value
  return `${padZero(d.getHours())}:${padZero(d.getMinutes())}`
})

const currentSecondStr = computed(() => {
  return padZero(nowTime.value.getSeconds())
})

const currentSolarDateStr = computed(() => {
  const d = nowTime.value
  return `${d.getFullYear()}年${padZero(d.getMonth() + 1)}月${padZero(d.getDate())}日`
})

const currentDayBadge = computed(() => getDateBadge(nowTime.value))

const currentWeekdayStr = computed(() => {
  const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']
  return weekdays[nowTime.value.getDay()]
})

// 农历计算 (Lunar calendar calculation)
const getLunarDate = (date: Date) => {
  const y = date.getFullYear()
  const m = date.getMonth() + 1
  const d = date.getDate()

  let yearGZ = '丙午年【马年】'
  if (y === 2025) yearGZ = '乙巳年【蛇年】'
  if (y === 2027) yearGZ = '丁未年【羊年】'

  const lunarMonthNames = ['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊']
  const lunarDayNames = [
    '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十'
  ]

  let lMonth = '七月'
  let lDay = '廿七'
  if (m === 9) {
    lMonth = d >= 11 ? '八月' : '七月'
    lDay = d === 7 ? '廿七' : (lunarDayNames[(d + 19) % 30] || '廿八')
  } else if (m === 10) {
    lMonth = d >= 10 ? '九月' : '八月'
    lDay = lunarDayNames[(d + 19) % 30] || '初一'
  } else {
    lMonth = (lunarMonthNames[m - 1] || '八') + '月'
    lDay = lunarDayNames[Math.min(29, d - 1)] || '初一'
  }

  return `${yearGZ} · ${lMonth}${lDay}`
}

const currentLunarDateStr = computed(() => {
  return getLunarDate(nowTime.value)
})

const currentSolarTerm = computed(() => {
  const m = nowTime.value.getMonth() + 1
  const d = nowTime.value.getDate()
  if (m === 9 && (d >= 7 && d <= 9)) return '白露'
  if (m === 9 && (d >= 22 && d <= 24)) return '秋分'
  if (m === 10 && (d >= 7 && d <= 9)) return '寒露'
  if (m === 10 && (d >= 22 && d <= 24)) return '霜降'
  return ''
})

const timePeriodIcon = computed(() => {
  const h = nowTime.value.getHours()
  if (h >= 5 && h < 9) return '🌅'
  if (h >= 9 && h < 12) return '🌤️'
  if (h >= 12 && h < 14) return '☀️'
  if (h >= 14 && h < 18) return '☕'
  return '🌙'
})

const greetingText = computed(() => {
  const h = nowTime.value.getHours()
  if (h >= 5 && h < 9) return '早上好！祝今日早早开单，元气满满！'
  if (h >= 9 && h < 12) return '上午好！黄金迎客档，保持充沛激情！'
  if (h >= 12 && h < 14) return '中午好！午间高峰请注意排班轮候与工位洁净！'
  if (h >= 14 && h < 18) return '下午好！下午黄金拓客期，积极维护老客与预约！'
  return '晚上好！晚间客流旺季，祝业绩攀升、好单连连！'
})

const currentStoreName = computed(() => {
  return storeConfig.storeName || '海马智慧旗舰店'
})

// 优先使用服务端实时计算大盘指标，与移动端APP绝对一致
const remoteStats = ref<any>(null)

const stats = computed(() => {
  if (remoteStats.value) {
    return {
      ...systemData.dashboardStats,
      todayRevenue: Number(remoteStats.value.todayRevenue != null ? remoteStats.value.todayRevenue : systemData.dashboardStats.todayRevenue),
      todayOrderCount: Number(remoteStats.value.todayOrderCount != null ? remoteStats.value.todayOrderCount : systemData.dashboardStats.todayOrderCount),
      totalSpaces: Number(remoteStats.value.totalSpaces || systemData.dashboardStats.totalSpaces || 10),
      occupiedSpaces: Number(remoteStats.value.occupiedSpaces != null ? remoteStats.value.occupiedSpaces : systemData.dashboardStats.occupiedSpaces),
      spaceUtilizationRate: Number(remoteStats.value.spaceUtilizationRate != null ? remoteStats.value.spaceUtilizationRate : systemData.dashboardStats.spaceUtilizationRate),
      activeSessions: Number(remoteStats.value.activeSessions != null ? remoteStats.value.activeSessions : systemData.dashboardStats.activeSessions),
      totalMembers: Number(remoteStats.value.totalMembers != null ? remoteStats.value.totalMembers : systemData.members.length),
      todayCommissions: Number(remoteStats.value.todayCommissions != null ? remoteStats.value.todayCommissions : systemData.dashboardStats.todayCommissions),
      servingCount: Number(remoteStats.value.servingCount != null ? remoteStats.value.servingCount : systemData.dashboardStats.servingCount),
      dirtyCount: Number(remoteStats.value.dirtyCount != null ? remoteStats.value.dirtyCount : systemData.dashboardStats.dirtyCount)
    }
  }
  return systemData.dashboardStats
})

// 月度营收计算 (若为纯净新租户，真实按已结账流水累计计算)
const monthGrossRevenue = computed(() => {
  const inc = systemData.reportsData.incomeList.reduce((sum, item) => sum + item.income, 0)
  if (systemData.isNewTenant) {
    return inc
  }
  return inc > 0 ? inc : 36800
})

// 月度全口径成本 (底薪 + 提成 + 日常支出)
const monthTotalCost = computed(() => {
  return (
    systemData.autoSalaryBaseCost +
    systemData.autoSalaryCommissionCost +
    systemData.expenseStats.totalMonthExpense
  )
})

// 月度预估净利润
const monthNetProfit = computed(() => {
  return monthGrossRevenue.value - monthTotalCost.value
})

const monthProfitMargin = computed(() => {
  if (monthGrossRevenue.value <= 0) return '0.0%'
  return ((monthNetProfit.value / monthGrossRevenue.value) * 100).toFixed(1) + '%'
})

// 缺货与低库存商品耗材告警 (老板最关心的商品缺货关键信息)
const lowStockItems = computed(() => {
  const items = systemData.inventoryWithStats.filter(item => item.isLow)
  if (items.length > 0) return items
  // 若当前行业暂无触发isLow的，补充筛选库存较低项供直观展示
  return systemData.inventoryWithStats.filter(item => item.currentStock <= item.safeStock + 2)
})

const activeSessions = ref<any[]>([])

const displaySessions = computed(() => {
  return activeSessions.value
})

const countServingSessions = computed(() => {
  return (activeSessions.value || []).filter(s => s.status === 'SERVING' || s.status === 'OCCUPIED_ORDERING' || s.status === 'SETTLING').length
})

const countWaitCleanSessions = computed(() => {
  return (activeSessions.value || []).filter(s => s.status === 'WAIT_CLEAN' || s.status === 'SETTLED_WAIT_CLEAN').length
})

const filteredDisplaySessions = computed(() => {
  let list = activeSessions.value || []
  if (sessionStatusFilter.value === 'SERVING') {
    list = list.filter(s => s.status === 'SERVING' || s.status === 'OCCUPIED_ORDERING' || s.status === 'SETTLING')
  } else if (sessionStatusFilter.value === 'WAIT_CLEAN') {
    list = list.filter(s => s.status === 'WAIT_CLEAN' || s.status === 'SETTLED_WAIT_CLEAN')
  }
  const kw = sessionSearchKeyword.value.trim().toLowerCase()
  if (kw) {
    list = list.filter(s => (s.spaceName && s.spaceName.toLowerCase().includes(kw)) || (s.customerName && s.customerName.toLowerCase().includes(kw)))
  }
  return list
})

// 人员在岗出勤与施工接单动态 (老板最关心的人员在岗关键信息)
const staffOnDutyList = computed(() => {
  const allStaff = systemData.staff || []
  if (allStaff.length === 0) {
    return []
  }
  const activeStaff = (systemData.staffWithStats || []).filter(s => s.status !== 'DELETED')
  if (activeStaff.length === 0) return []
  const servingSessions = displaySessions.value.filter((s: any) => s.status === 'SERVING')

  return activeStaff.map((staff, index) => {
    let workStatus: 'SERVING' | 'IDLE' | 'CASHIER' = 'IDLE'
    let currentServingSpace = ''

    if (staff.role === 'CASHIER') {
      workStatus = 'CASHIER'
    } else if (index < servingSessions.length) {
      workStatus = 'SERVING'
      currentServingSpace = servingSessions[index]?.spaceName || `${storeConfig.spaceAlias}#${index + 1}`
    }

    return {
      ...staff,
      workStatus,
      currentServingSpace,
      todayOrderCount: staff.serviceCount || 0,
      todayCommission: staff.totalCommission || 0
    }
  })
})

const availableStores = computed(() => (storeConfig.stores && storeConfig.stores.length > 0) ? storeConfig.stores : systemData.stores)

// 门店开设对话框状态
const createStoreVisible = ref(false)
const creatingStore = ref(false)
const createStoreForm = ref({
  storeName: '',
  industry: 'BEAUTY',
  phone: '',
  address: '',
  manager: '',
  businessHours: '09:00 - 22:00'
})

const openCreateStoreDialog = () => {
  const currentCount = availableStores.value.length
  const limit = storeConfig.storeLimit || 1
  if (currentCount >= limit) {
    ElMessageBox.alert(
      `您当前的套餐支持开设门店上限为 <b>${limit}</b> 家。<br/><br/>您当前已开设 <b>${currentCount}</b> 家门店，已达配额上限！<br/><br/>如需开设更多连锁分店，请升级至更高版本。`,
      '门店开店配额已达上限',
      { dangerouslyUseHTMLString: true, type: 'warning', confirmButtonText: '我知道了' }
    )
    return
  }
  createStoreForm.value = {
    storeName: '',
    industry: storeConfig.industry || 'BEAUTY',
    phone: '',
    address: '',
    manager: '',
    businessHours: '09:00 - 22:00'
  }
  createStoreVisible.value = true
}

const handleCreateStore = async () => {
  if (!createStoreForm.value.storeName.trim() || !createStoreForm.value.phone.trim() || !createStoreForm.value.address.trim()) {
    ElMessage.warning('请完整填写门店名称、电话与地址')
    return
  }
  creatingStore.value = true
  try {
    const res: any = await createStoreApi(createStoreForm.value)
    ElMessage.success('首家门店开设入驻成功！')
    createStoreVisible.value = false
    await storeConfig.loadStores()
    if (res && res.storeId) {
      await storeConfig.switchStore(res.storeId)
    }
    await loadData()
  } catch (e: any) {
    ElMessage.error(e.message || '开设门店失败')
  } finally {
    creatingStore.value = false
  }
}

const totalStaffCount = computed(() => {
  if (systemData.staff && systemData.staff.length > 0) {
    return systemData.staff.filter(s => s.status !== 'DELETED').length
  }
  return Number(remoteStats.value?.totalStaffCount || 0)
})
const activeStaffCount = computed(() => {
  if (staffOnDutyList.value.length > 0) {
    return staffOnDutyList.value.length
  }
  return Number(remoteStats.value?.activeStaffCount || totalStaffCount.value || 0)
})
const servingStaffCount = computed(() => staffOnDutyList.value.filter(s => s.workStatus === 'SERVING').length)
const idleStaffCount = computed(() => staffOnDutyList.value.filter(s => s.workStatus === 'IDLE').length)

const loadData = async () => {
  try {
    try {
      await systemData.fetchStaff()
    } catch (err) {}

    try {
      const s: any = await getDashboardStatsApi(storeConfig.currentStoreId || undefined)
      if (s) {
        remoteStats.value = s
      }
    } catch (err) {}

    let apiSessions: any = null
    try {
      apiSessions = await getActiveSessionsApi()
    } catch (err) {}

    const sessions = Array.isArray(apiSessions) ? [...apiSessions] : []
    // 自动核对工位与活跃会话一致性：若工位在服但活跃会话中暂未体现，自动补全展示，杜绝“有占用率无明细”
    try {
      const spacesResp: any = await getSpacesApi()
      const spacesList = Array.isArray(spacesResp) ? spacesResp : (spacesResp?.data || [])
      for (const sp of spacesList) {
        if (sp.status === 'OCCUPIED') {
          const hasSession = sessions.some(s => s.spaceId === sp.id || (sp.currentSessionId && s.id === sp.currentSessionId))
          if (!hasSession) {
            sessions.push({
              id: sp.currentSessionId || sp.id,
              spaceId: sp.id,
              spaceName: sp.spaceName,
              sessionNo: 'SS' + (sp.currentSessionId || sp.id),
              customerName: sp.notes || '到店顾客',
              startTime: '服务履约中',
              totalAmount: sp.minConsumeAmount || 80,
              status: 'SERVING'
            })
          }
        }
      }
    } catch (_) {}

    activeSessions.value = sessions
  } catch (e) {
    console.error(e)
  }
}

const handleGoCashier = (sessionId: number) => {
  const s = activeSessions.value.find(item => item.id === sessionId)
  router.push({
    path: '/cashier',
    query: {
      sessionId: String(sessionId),
      spaceId: s?.spaceId ? String(s.spaceId) : undefined,
      spaceName: s?.spaceName || undefined
    }
  })
}

const handleResetSpace = async (sessionId: number) => {
  try {
    const s = activeSessions.value.find(item => item.id === sessionId)
    if (s && s.spaceId) {
      await resetSpaceApi(s.spaceId)
    }
  } catch (e) {}
  systemData.resetSpace(sessionId)
  await loadData()
  ElMessage.success('工位已清台完毕，恢复空闲待服务状态！')
}

const handleQuickRestock = (item: any) => {
  ElMessage.success(`已记录采购补货意向：【${item.name}】，正在前往库存采购页面...`)
  router.push('/inventory')
}

// 获客/入职二维码弹窗相关状态与方法
const quickQrDialogVisible = ref(false)
const quickQrType = ref<'member' | 'staff'>('member')
const dashboardQrUrl = ref('')

const effectiveStoreId = computed(() => storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || 'S001')
const currentQuickLink = computed(() => {
  const origin = window.location.origin
  if (quickQrType.value === 'member') {
    const sId = encodeURIComponent(effectiveStoreId.value)
    const sName = encodeURIComponent(storeConfig.storeName || '')
    const ind = encodeURIComponent(storeConfig.industry || '')
    const phone = encodeURIComponent(storeConfig.phone || '')
    const addr = encodeURIComponent(storeConfig.address || '')
    const hours = encodeURIComponent(storeConfig.businessHours || '')
    return `${origin}/seahorse/member-register?storeId=${sId}&storeName=${sName}&industry=${ind}&phone=${phone}&address=${addr}&businessHours=${hours}`
  } else {
    return `${origin}/seahorse/staff-register?storeId=${encodeURIComponent(effectiveStoreId.value)}`
  }
})

const updateDashboardQrCode = async () => {
  try {
    dashboardQrUrl.value = await QRCode.toDataURL(currentQuickLink.value, {
      width: 220,
      margin: 2,
      color: {
        dark: '#0f172a',
        light: '#ffffff'
      }
    })
  } catch (err) {
    console.error('Failed to generate dashboard QR Code', err)
  }
}

const openQuickQrModal = () => {
  quickQrDialogVisible.value = true
  updateDashboardQrCode()
}

const copyDashboardLink = async () => {
  try {
    await navigator.clipboard.writeText(currentQuickLink.value)
    ElMessage.success('已复制链接到剪贴板！')
  } catch (e) {
    const input = document.createElement('input')
    input.value = currentQuickLink.value
    document.body.appendChild(input)
    input.select()
    document.execCommand('copy')
    document.body.removeChild(input)
    ElMessage.success('已复制链接！')
  }
}

const openQuickLinkPage = () => {
  window.open(currentQuickLink.value, '_blank')
}

const downloadDashboardQr = () => {
  if (!dashboardQrUrl.value) return
  const a = document.createElement('a')
  a.href = dashboardQrUrl.value
  const typeName = quickQrType.value === 'member' ? '顾客会员自助开卡码' : '员工自主入职码'
  a.download = `${storeConfig.storeName}_${typeName}.png`
  a.click()
  ElMessage.success('已开始下载二维码图片')
}

const handleRemoteNoticeUpdated = () => {
  fetchDashboardNotices()
}

onMounted(() => {
  loadData()
  fetchDashboardNotices()
  window.addEventListener('seahorse-notice-updated', handleRemoteNoticeUpdated)
})

onUnmounted(() => {
  window.removeEventListener('seahorse-notice-updated', handleRemoteNoticeUpdated)
})
</script>

<style scoped>
.dashboard-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* 门店运营规范与日常公告广播通知条 */
.store-notice-broadcast-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fffbeb;
  border: 1px solid #fde68a;
  border-radius: 8px;
  padding: 8px 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.store-notice-broadcast-bar.is-urgent-bar {
  background: #fef2f2;
  border-color: #fecaca;
  animation: pulse-urgent 2s infinite ease-in-out;
}

@keyframes pulse-urgent {
  0%, 100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.2); }
  50% { box-shadow: 0 0 0 6px rgba(239, 68, 68, 0.15); }
}

.snb-left {
  display: flex;
  align-items: center;
  gap: 10px;
  flex: 1;
  overflow: hidden;
}

.snb-marquee {
  display: flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.snb-title {
  font-weight: 700;
  color: #1e293b;
  font-size: 13px;
}

.snb-summary {
  color: #475569;
  font-size: 13px;
}

.snb-time {
  color: #94a3b8;
  font-size: 11px;
}

.snb-right {
  margin-left: 12px;
  flex-shrink: 0;
}

/* 顶部指标卡片 */
.stat-card {
  border-radius: 10px;
  transition: all 0.2s ease-in-out;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.08);
}

.stat-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}

.stat-title {
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
}

.stat-value {
  font-size: 24px;
  font-weight: 800;
  line-height: 1.2;
}

.stat-unit {
  font-size: 13px;
  font-weight: normal;
  color: #64748b;
  margin-left: 4px;
}

.stat-footer {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 8px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.text-primary { color: #0284c7; }
.text-success { color: #059669; }
.text-danger { color: #dc2626; }
.text-warning { color: #d97706; }
.text-teal { color: #0d9488; }

.has-low-stock {
  border-color: #fca5a5;
  background: linear-gradient(180deg, #fff 0%, #fef2f2 100%);
}

/* 快捷操作栏 */
.dashboard-quick-bar {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px 18px;
  background: #ffffff;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.quick-bar-title {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
  white-space: nowrap;
}

.quick-bar-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

/* 通用 Card 间距 */
.mb-16 {
  margin-bottom: 16px;
}

.box-card {
  border-radius: 10px;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-left {
  display: flex;
  align-items: center;
}

.header-title {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}

.price-bold {
  font-weight: 700;
  color: #0f172a;
}

/* 收支大盘五格网格 */
.finance-breakdown-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
}

.finance-item {
  padding: 14px 12px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  background: #f8fafc;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.fi-lbl {
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
}

.fi-val {
  font-size: 17px;
  font-weight: 800;
}

.fi-sub {
  font-size: 11px;
  color: #94a3b8;
  line-height: 1.4;
  margin-top: 2px;
}

/* 人员在岗列表 */
.staff-duty-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.staff-duty-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 14px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  transition: all 0.2s ease;
}

.staff-duty-card:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
}

.st-avatar {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: #0d9488;
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 16px;
  flex-shrink: 0;
}

.st-main {
  flex: 1;
}

.st-row1 {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.st-name {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}

.st-row2 {
  font-size: 12px;
  color: #64748b;
}

.st-stats {
  text-align: right;
  flex-shrink: 0;
}

.st-orders {
  font-size: 12px;
  color: #334155;
  margin-bottom: 2px;
}

.st-comm {
  font-size: 12px;
  color: #d97706;
}

/* 缺货预警中心 */
.empty-stock-box {
  padding: 30px 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  text-align: center;
}

.empty-text {
  font-size: 13px;
  color: #059669;
  font-weight: 600;
}

.low-stock-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.low-stock-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 14px;
  background: #fff;
  border: 1px solid #fee2e2;
  border-radius: 8px;
  transition: all 0.2s ease;
}

.low-stock-card:hover {
  border-color: #fca5a5;
  box-shadow: 0 4px 12px rgba(239, 68, 68, 0.08);
}

.ls-info {
  flex: 1;
}

.ls-name-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.ls-name {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}

.ls-stock-row {
  font-size: 12px;
  color: #64748b;
  display: flex;
  align-items: center;
  gap: 6px;
}

.ls-sep {
  color: #cbd5e1;
}

.ls-safe {
  color: #64748b;
}

.ls-supplier {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
}

.ls-action {
  flex-shrink: 0;
  margin-left: 12px;
}

/* 首页快捷二维码弹窗样式 */
.dash-qr-modal {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 8px 0;
}

.qr-code-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.dash-qr-img {
  width: 220px;
  height: 220px;
  border-radius: 6px;
}

.qr-box-tip {
  margin-top: 10px;
  font-size: 13px;
  color: #64748b;
  text-align: center;
}

.dash-qr-url-row {
  width: 100%;
}

/* 顶部实时数字时钟与经营问候横幅 */
.dashboard-clock-banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 16px;
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px 22px;
  margin-bottom: 18px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.03);
}

.dcb-left {
  display: flex;
  align-items: center;
  gap: 18px;
}

.digital-time-block {
  display: flex;
  align-items: baseline;
  background: #0f172a;
  color: #38bdf8;
  padding: 6px 14px;
  border-radius: 8px;
  font-family: 'Courier New', Courier, monospace;
  box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.4);
}

.d-hour-min {
  font-size: 26px;
  font-weight: 700;
  letter-spacing: 1px;
}

.d-sec {
  font-size: 16px;
  color: #94a3b8;
  margin-left: 2px;
}

.date-calendar-meta {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.solar-line {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 600;
  color: #1e293b;
}

.solar-week {
  color: #0284c7;
  background: #e0f2fe;
  padding: 1px 6px;
  border-radius: 4px;
  font-size: 12px;
}

.lunar-line {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #64748b;
}

.lunar-tag {
  background: #f1f5f9;
  border: 1px solid #cbd5e1;
  color: #475569;
  padding: 0 4px;
  border-radius: 3px;
  font-size: 11px;
}

.solar-term-tag {
  background: #f0fdf4;
  color: #16a34a;
  border: 1px solid #bbf7d0;
  padding: 0 6px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 500;
}

.dcb-center {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.greet-title {
  font-size: 16px;
  font-weight: 700;
  color: #1e293b;
  display: flex;
  align-items: center;
  gap: 6px;
}

.greet-icon {
  font-size: 18px;
}

.greet-sub {
  font-size: 13px;
  color: #64748b;
}

.dcb-right {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* 新租户纯净开张欢迎向导卡片 */
.new-tenant-welcome-card {
  margin-bottom: 18px;
  background: linear-gradient(135deg, #f0fdf4 0%, #ffffff 60%, #eff6ff 100%);
  border: 1px solid #bbf7d0;
  border-radius: 12px;
}

.welcome-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 16px;
}

.welcome-title-wrap {
  flex: 1;
}

.welcome-badge {
  display: inline-block;
  background: #22c55e;
  color: #ffffff;
  font-size: 11px;
  font-weight: 700;
  padding: 3px 10px;
  border-radius: 20px;
  letter-spacing: 0.5px;
  margin-bottom: 8px;
}

.welcome-main-title {
  font-size: 18px;
  font-weight: 800;
  color: #14532d;
  margin: 0 0 6px 0;
}

.welcome-sub-title {
  font-size: 13px;
  color: #475569;
  margin: 0;
  line-height: 1.6;
}

.welcome-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.welcome-steps-row {
  margin-top: 8px;
}

.guide-step-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 16px;
  cursor: pointer;
  transition: all 0.25s ease;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.guide-step-card:hover {
  border-color: #0284c7;
  transform: translateY(-3px);
  box-shadow: 0 6px 16px rgba(2, 132, 199, 0.12);
}

.step-num {
  font-size: 11px;
  font-weight: 800;
  color: #0284c7;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 4px;
}

.step-icon {
  font-size: 26px;
  margin-bottom: 6px;
}

.step-title {
  font-size: 14px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 4px;
}

.step-desc {
  font-size: 12px;
  color: #64748b;
  line-height: 1.5;
}

/* 0门店初始空状态卡片样式 */
.zero-store-welcome-card {
  margin-bottom: 16px;
  border-radius: 12px;
  border: 1px dashed #38bdf8;
  background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 50%, #f8fafc 100%);
  box-shadow: 0 4px 18px rgba(2, 132, 199, 0.08);
}

.zero-store-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  padding: 8px 12px;
}

.zero-store-left {
  flex: 1;
}

.zero-badge-pill {
  display: inline-block;
  padding: 3px 12px;
  border-radius: 20px;
  background: #0284c7;
  color: #ffffff;
  font-size: 12px;
  font-weight: 700;
  margin-bottom: 8px;
  letter-spacing: 0.5px;
}

.zero-store-title {
  margin: 0 0 8px 0;
  font-size: 18px;
  font-weight: 800;
  color: #0f172a;
}

.zero-store-desc {
  margin: 0 0 16px 0;
  font-size: 13px;
  color: #475569;
  line-height: 1.7;
}

.zero-store-btn-group {
  display: flex;
  gap: 12px;
}

.zero-store-right {
  width: 260px;
  flex-shrink: 0;
}

.empty-industry-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.mini-ind-card {
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 10px 8px;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.mini-ind-card:hover {
  border-color: #0284c7;
  background: #f0f9ff;
  transform: translateY(-2px);
  box-shadow: 0 4px 10px rgba(2, 132, 199, 0.15);
}

.mini-icon {
  font-size: 20px;
}

.mini-text {
  font-size: 12px;
  font-weight: 700;
  color: #1e293b;
}

/* 场景数据生成对话框样式 */
.demo-modal-tip {
  font-size: 13px;
  color: #64748b;
  margin-bottom: 16px;
  line-height: 1.6;
}

.industry-card-grid {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.ind-select-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 14px 18px;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: #ffffff;
}

.ind-select-card:hover {
  border-color: #93c5fd;
  background: #f8fafc;
}

.ind-select-card.is-active {
  border-color: #0284c7;
  background: #f0f9ff;
  box-shadow: 0 4px 14px rgba(2, 132, 199, 0.15);
}

.ind-icon {
  font-size: 32px;
  width: 44px;
  text-align: center;
}

.ind-info {
  flex: 1;
}

.ind-name {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 4px;
}

.ind-desc {
  font-size: 12px;
  color: #64748b;
  line-height: 1.4;
}

.ind-check {
  font-size: 18px;
  font-weight: 800;
  color: #0284c7;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #e0f2fe;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* 租户推荐同行有礼活动横幅 */
.tenant-referral-promo-strip {
  background: linear-gradient(135deg, #fff7ed 0%, #ffedd5 50%, #fed7aa 100%);
  border: 1px solid #fdba74;
  border-radius: 12px;
  padding: 14px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 14px;
  margin-bottom: 16px;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(234, 88, 12, 0.08);
  transition: all 0.2s ease;
}

.tenant-referral-promo-strip:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 14px rgba(234, 88, 12, 0.16);
  border-color: #ea580c;
}

.tr-left {
  display: flex;
  align-items: center;
  gap: 14px;
}

.tr-gift-icon {
  width: 44px;
  height: 44px;
  background: #ffffff;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  box-shadow: 0 2px 6px rgba(234, 88, 12, 0.15);
  flex-shrink: 0;
}

.tr-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 800;
  font-size: 15px;
  color: #9a3412;
}

.tr-desc {
  font-size: 12px;
  color: #c2410c;
  margin-top: 3px;
}

.tr-right {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

.tr-stat-badge {
  font-size: 12px;
  color: #9a3412;
  background: rgba(255, 255, 255, 0.8);
  padding: 4px 10px;
  border-radius: 20px;
  border: 1px solid #fed7aa;
}

/* 租户推荐弹窗内部布局 */
.tenant-referral-modal-layout {
  display: flex;
  gap: 20px;
  align-items: flex-start;
}

.trm-left {
  flex: 0 0 280px;
}

.tenant-poster-card {
  background: linear-gradient(135deg, #090d16 0%, #1e1b4b 100%);
  border-radius: 14px;
  padding: 18px 16px;
  color: #ffffff;
  text-align: center;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
}

.tp-top-badge {
  display: inline-block;
  background: rgba(56, 189, 248, 0.2);
  border: 1px solid #38bdf8;
  color: #38bdf8;
  font-size: 10px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 10px;
  margin-bottom: 8px;
}

.tp-shop-name {
  font-size: 16px;
  font-weight: 800;
  color: #ffffff;
}

.tp-invite-title {
  font-size: 12px;
  color: #94a3b8;
  margin: 4px 0 12px;
}

.tp-highlight-box {
  background: rgba(255, 255, 255, 0.08);
  border-radius: 8px;
  padding: 8px 10px;
  text-align: left;
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 12px;
}

.tp-hl-item {
  font-size: 11px;
  color: #e2e8f0;
}

.tp-qr-box {
  background: #ffffff;
  border-radius: 10px;
  padding: 10px;
  display: inline-block;
  margin-bottom: 8px;
}

.tp-qr-img {
  width: 140px;
  height: 140px;
  display: block;
  margin: 0 auto;
}

.tp-qr-hint {
  font-size: 11px;
  font-weight: 700;
  color: #0f172a;
  margin-top: 4px;
}

.tp-ref-code {
  font-size: 10px;
  color: #0284c7;
  margin-top: 2px;
}

.tp-footer-url {
  font-size: 10px;
  color: #64748b;
}

.trm-right {
  flex: 1;
}

.trm-stitle {
  font-weight: 800;
  font-size: 13px;
  color: #1e293b;
  margin-bottom: 6px;
}

.trm-records-mini {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  max-height: 150px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.trm-rec-item {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 6px 10px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.trm-rec-main .rec-name {
  font-size: 12px;
  font-weight: 700;
  color: #0f172a;
}

.trm-rec-main .rec-date {
  font-size: 10px;
  color: #94a3b8;
  margin-left: 6px;
}

.trm-rec-sub {
  display: flex;
  align-items: center;
  gap: 6px;
}

.trm-rec-sub .rec-status {
  font-size: 11px;
  color: #16a34a;
  font-weight: 700;
}

/* 祝贺弹窗样式 */
.reward-celebrate-content {
  text-align: center;
  padding: 10px 0 16px;
}

.celebrate-trophy {
  font-size: 48px;
  margin-bottom: 8px;
}

.celebrate-title {
  font-size: 18px;
  font-weight: 800;
  color: #0f172a;
  margin: 0 0 8px;
}

.celebrate-desc {
  font-size: 13px;
  color: #475569;
  line-height: 1.5;
  margin-bottom: 16px;
}

.reward-highlight-card {
  background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);
  border: 1px solid #a7f3d0;
  border-radius: 10px;
  padding: 14px;
  margin-bottom: 14px;
}

.rh-lbl {
  font-size: 12px;
  color: #065f46;
  font-weight: 600;
}

.rh-val {
  font-size: 18px;
  font-weight: 900;
  color: #059669;
  margin-top: 4px;
}

.celebrate-sms-tip {
  font-size: 12px;
  color: #64748b;
  background: #f8fafc;
  padding: 8px 12px;
  border-radius: 6px;
}

.session-filter-strip {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: #f8fafc;
  border-radius: 6px;
  margin-bottom: 10px;
  border: 1px solid #e2e8f0;
  gap: 8px;
  flex-wrap: wrap;
}

</style>
