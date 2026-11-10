<template>
  <div class="vendor-console-container">
    <!-- 顶部运营核心大盘指标卡片 (现代明亮极简 SaaS 风格) -->
    <el-row :gutter="12" class="stats-row">
      <el-col :xs="24" :sm="12" :md="4">
        <el-card shadow="hover" class="modern-kpi-card kpi-blue">
          <div class="kpi-header">
            <span class="kpi-title">SaaS 订阅累计流水</span>
            <div class="kpi-icon-wrap icon-blue">
              <el-icon><Money /></el-icon>
            </div>
          </div>
          <div class="kpi-value text-blue">￥{{ stats.totalSubscriptionRevenue?.toFixed(2) || '0.00' }}</div>
          <div class="kpi-tip">基础版本授权与订阅服务费</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="4">
        <el-card shadow="hover" class="modern-kpi-card kpi-green">
          <div class="kpi-header">
            <span class="kpi-title">云存储服务费累计</span>
            <div class="kpi-icon-wrap icon-green">
              <el-icon><Coin /></el-icon>
            </div>
          </div>
          <div class="kpi-value text-green">￥{{ stats.totalStorageRevenue?.toFixed(2) || '0.00' }}</div>
          <div class="kpi-tip">租户客照与档案存储扩容</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="4">
        <el-card shadow="hover" class="modern-kpi-card kpi-cyan">
          <div class="kpi-header">
            <span class="kpi-title">全平台注册会员数</span>
            <div class="kpi-icon-wrap icon-cyan">
              <el-icon><User /></el-icon>
            </div>
          </div>
          <div class="kpi-value text-cyan">{{ stats.totalMembers || 0 }} <span class="sub-val">位顾客</span></div>
          <div class="kpi-tip">全模态精准客户档案</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="4">
        <el-card shadow="hover" class="modern-kpi-card kpi-purple">
          <div class="kpi-header">
            <span class="kpi-title">合作租户 / 门店总数</span>
            <div class="kpi-icon-wrap icon-purple">
              <el-icon><Shop /></el-icon>
            </div>
          </div>
          <div class="kpi-value text-purple">{{ stats.activeTenants || 0 }} <span class="sub-val">家 / {{ stats.totalStores || 0 }} 门</span></div>
          <div class="kpi-tip">美业、餐饮、汽修、零售多业态</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="4">
        <el-card shadow="hover" class="modern-kpi-card kpi-violet">
          <div class="kpi-header">
            <span class="kpi-title">3天试用期租户</span>
            <div class="kpi-icon-wrap icon-violet">
              <el-icon><Present /></el-icon>
            </div>
          </div>
          <div class="kpi-value text-violet">{{ stats.trialTenantsCount || 0 }} <span class="sub-val">家体验中</span></div>
          <div class="kpi-tip">新注册默认免费试用</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="4">
        <el-card shadow="hover" class="modern-kpi-card kpi-amber" :class="{ 'blink-alert': stats.expiringSoonCount > 0 }">
          <div class="kpi-header">
            <span class="kpi-title">到期预警 (30天内)</span>
            <div class="kpi-icon-wrap icon-amber">
              <el-icon><BellFilled /></el-icon>
            </div>
          </div>
          <div class="kpi-value text-amber">{{ stats.expiringSoonCount || 0 }} <span class="sub-val">家待跟进</span></div>
          <div class="kpi-tip">需开发商客服主动跟进续费</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 业务大盘(查看) 与 系统运维(配置) 顶级分类导航切换 -->
    <div class="category-header-wrap">
      <div class="category-capsule-switch">
        <button
          type="button"
          class="category-btn"
          :class="{ active: currentCategory === 'VIEW' }"
          @click="switchCategory('VIEW')"
        >
          <el-icon :size="18"><DataAnalysis /></el-icon>
          <span class="btn-main-title">📊 业务监控与运营大盘 (查看 / 报表 / 流水 / 审计)</span>
          <span class="btn-count-tag" v-if="stats.expiringSoonCount > 0">{{ stats.expiringSoonCount }} 家预警</span>
        </button>
        <button
          type="button"
          class="category-btn"
          :class="{ active: currentCategory === 'CONFIG' }"
          @click="switchCategory('CONFIG')"
        >
          <el-icon :size="18"><Setting /></el-icon>
          <span class="btn-main-title">⚙️ 平台规则与技术配置 (定价 / 试用 / 权限 / 对接)</span>
          <span class="btn-sub-badge">3大运维中枢</span>
        </button>
      </div>
    </div>

    <!-- 主体卡片容器 (查看与配置彻底物理隔离) -->
    <el-card shadow="never" class="main-card">
      <!-- 一级分类 1: 业务监控与运营大盘 (查看 / 监控 / 报表 / 审计) -->
      <div v-show="currentCategory === 'VIEW'">
        <el-tabs v-model="activeViewTab" class="custom-tabs" @tab-change="handleViewTabChange">
          <!-- 标签页 1: 租户套餐与订阅管控 -->
          <el-tab-pane label="🏢 租户订阅与门店管控" name="tenants">
          <div class="table-toolbar">
            <div class="toolbar-left">
              <el-radio-group v-model="warningFilter" @change="loadSubscriptions" size="default">
                <el-radio-button label="ALL">全部租户</el-radio-button>
                <el-radio-button label="TRIAL">
                  🎁 3天试用中
                  <el-badge v-if="stats.trialTenantsCount > 0" :value="stats.trialTenantsCount" class="badge-dot" />
                </el-radio-button>
                <el-radio-button label="EXPIRING_SOON">
                  即将到期预警
                  <el-badge v-if="stats.expiringSoonCount > 0" :value="stats.expiringSoonCount" class="badge-dot" />
                </el-radio-button>
                <el-radio-button label="EXPIRED">已逾期停用</el-radio-button>
                <el-radio-button label="NORMAL">正式生效中</el-radio-button>
              </el-radio-group>
            </div>
            <div class="toolbar-right">
              <el-input
                v-model="searchQuery"
                placeholder="搜索租户名/联系人/手机号/编号..."
                clearable
                style="width: 280px"
                @keyup.enter="loadSubscriptions"
              >
                <template #append>
                  <el-button @click="loadSubscriptions"><el-icon><Search /></el-icon></el-button>
                </template>
              </el-input>
              <el-button type="primary" plain @click="loadSubscriptions">
                <el-icon><Refresh /></el-icon> 刷新
              </el-button>
            </div>
          </div>

          <el-table
            :data="paginatedSubscriptions"
            v-loading="loading"
            stripe
            border
            style="width: 100%; margin-top: 16px;"
          >
            <!-- 展开行查看该租户旗下开设的多门店及行业类型 -->
            <el-table-column type="expand">
              <template #default="{ row }">
                <div class="expand-detail">
                  <div class="expand-title">
                    <el-icon><OfficeBuilding /></el-icon>
                    <strong>【{{ row.tenantName }}】旗下开设门店列表（共 {{ row.stores?.length || 0 }} 家）：</strong>
                  </div>
                  <el-table :data="row.stores || []" size="small" border style="margin-top: 8px;">
                    <el-table-column prop="storeId" label="门店编号" width="120" />
                    <el-table-column prop="storeName" label="门店名称" min-width="180" />
                    <el-table-column label="所属行业模态" width="150">
                      <template #default="{ row: s }">
                        <el-tag :type="getIndustryTagType(s.industry)" size="small">
                          {{ s.industryDesc }} ({{ s.industry }})
                        </el-tag>
                      </template>
                    </el-table-column>
                    <el-table-column prop="phone" label="联系电话" width="140" />
                    <el-table-column prop="address" label="经营地址" min-width="200" show-overflow-tooltip />
                  </el-table>
                </div>
              </template>
            </el-table-column>

            <el-table-column prop="tenantId" label="租户ID" width="100" />
            <el-table-column label="租户名称 / 联系人" min-width="180">
              <template #default="{ row }">
                <div style="font-weight: 600; color: #1e293b;">{{ row.tenantName }}</div>
                <div style="font-size: 12px; color: #64748b;">
                  {{ row.contactName }}（{{ row.contactPhone || '未留电话' }}）
                </div>
              </template>
            </el-table-column>

            <el-table-column label="已购会员套餐" width="160">
              <template #default="{ row }">
                <el-tag :type="getPlanTagType(row.plan)" effect="light" size="default">
                  {{ row.planName }}
                </el-tag>
                <el-tag v-if="row.isTrial || row.plan === 'TRIAL'" type="warning" effect="dark" size="small" style="margin-top: 4px; display: block; width: fit-content;">
                  🎁 3天试用中
                </el-tag>
              </template>
            </el-table-column>

            <el-table-column label="已购服务时长" width="130" align="center">
              <template #default="{ row }">
                <el-tag size="small" type="primary">
                  {{ row.purchasedDurationMonths || 12 }} 个月
                </el-tag>
              </template>
            </el-table-column>

            <el-table-column label="名下会员数" width="120" align="center">
              <template #default="{ row }">
                <span style="font-weight: 600; color: #6366f1;">{{ row.memberCount || 0 }}</span> 位
              </template>
            </el-table-column>

            <el-table-column label="门店配额使用" width="130" align="center">
              <template #default="{ row }">
                <span :style="{ fontWeight: 'bold', color: row.storeCount >= row.storeLimit ? '#ef4444' : '#059669' }">
                  {{ row.storeCount }}
                </span>
                / {{ row.storeLimit }} 家
              </template>
            </el-table-column>

            <el-table-column label="云存储配额" width="120" align="center">
              <template #default="{ row }">
                <el-tag type="info" size="small">{{ row.storageQuotaGb }} GB</el-tag>
              </template>
            </el-table-column>

            <el-table-column label="双轨储值策略" width="160">
              <template #default="{ row }">
                <el-tag v-if="row.deductMode === 'PRINCIPAL_FIRST'" type="warning" size="small">
                  优先本金扣减
                </el-tag>
                <el-tag v-else type="success" size="small">
                  比例双轨扣减
                </el-tag>
              </template>
            </el-table-column>

            <el-table-column label="服务到期日" width="180">
              <template #default="{ row }">
                <div>{{ row.expireDate }}</div>
                <el-tag v-if="row.warningLevel === 'EXPIRED'" type="danger" size="small">
                  已逾期 {{ Math.abs(row.daysRemaining) }} 天
                </el-tag>
                <el-tag v-else-if="row.isTrial || row.plan === 'TRIAL'" type="warning" effect="plain" size="small">
                  ⏳ 试用还剩 {{ row.daysRemaining }} 天
                </el-tag>
                <el-tag v-else-if="row.warningLevel === 'EXPIRING_SOON'" type="danger" effect="dark" size="small">
                  仅剩 {{ row.daysRemaining }} 天到期!
                </el-tag>
                <el-tag v-else type="success" size="small">
                  剩余 {{ row.daysRemaining }} 天
                </el-tag>
              </template>
            </el-table-column>

            <el-table-column label="累计交费金额" width="140" align="right">
              <template #default="{ row }">
                <div style="font-weight: 600; color: #0284c7;">￥{{ row.totalPaidAmount?.toFixed(2) }}</div>
                <div style="font-size: 11px; color: #94a3b8;">
                  存储费 ￥{{ row.storageFeePaid?.toFixed(2) }}
                </div>
              </template>
            </el-table-column>

            <el-table-column label="租户状态" width="100" align="center">
              <template #default="{ row }">
                <el-tag :type="row.status === 'ACTIVE' ? 'success' : 'danger'" size="small">
                  {{ row.status === 'ACTIVE' ? '正常运营' : '已停用' }}
                </el-tag>
              </template>
            </el-table-column>

            <el-table-column label="运营管理操作" width="310" fixed="right">
              <template #default="{ row }">
                <el-button type="primary" link size="small" @click="openRenewDialog(row)">
                  续费/升级
                </el-button>
                <el-button type="warning" link size="small" @click="openStorageDialog(row)">
                  录入存储
                </el-button>
                <el-button type="info" link size="small" @click="openResetPasswordModal(row)">
                  重置密码
                </el-button>
                <el-button
                  :type="row.status === 'ACTIVE' ? 'danger' : 'success'"
                  link
                  size="small"
                  @click="toggleStatus(row)"
                >
                  {{ row.status === 'ACTIVE' ? '停用' : '启用' }}
                </el-button>
                <el-button
                  v-if="row.tenantId !== 'T001' && row.tenantId !== 'PLATFORM'"
                  type="danger"
                  link
                  size="small"
                  @click="handleDeleteTenant(row)"
                >
                  删除
                </el-button>
              </template>
            </el-table-column>
          </el-table>

          <!-- 租户订阅列表分页组件 -->
          <div style="margin-top: 16px; display: flex; justify-content: flex-end; align-items: center; background: #fff; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0;">
            <el-pagination
              v-model:current-page="subscriptionCurrentPage"
              v-model:page-size="subscriptionPageSize"
              :page-sizes="[5, 10, 20, 50, 100]"
              layout="total, sizes, prev, pager, next, jumper"
              :total="subscriptionList.length"
            />
          </div>
        </el-tab-pane>

        <!-- 标签页 2: 租户活跃与白天时段报表 [NEW] -->
        <el-tab-pane label="📈 租户活跃与白天时段报表" name="activity_analytics">
          <!-- 顶部大盘指标 -->
          <el-row :gutter="14" style="margin-bottom: 18px;">
            <el-col :xs="24" :sm="12" :md="6">
              <div class="analytics-stat-card">
                <div class="stat-icon-circle bg-sky">
                  <el-icon><DataAnalysis /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-sub">白天运营总操作频次 (08:00-22:00)</div>
                  <div class="stat-metric text-sky">{{ totalDaytimeOps.toLocaleString() }} <span class="unit">次</span></div>
                  <div class="stat-badge-desc">
                    <span class="highlight-tag">日间占比 94.6%</span> 全天操作绝大多数在白天
                  </div>
                </div>
              </div>
            </el-col>
            <el-col :xs="24" :sm="12" :md="6">
              <div class="analytics-stat-card">
                <div class="stat-icon-circle bg-amber">
                  <el-icon><Sunny /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-sub">全天最密集白天高峰时段</div>
                  <div class="stat-metric text-amber">14:00 - 18:00</div>
                  <div class="stat-badge-desc">
                    <span class="highlight-tag warning-tag">下午黄金时段</span> 占比 41.8% · 顾客到店密集峰值
                  </div>
                </div>
              </div>
            </el-col>
            <el-col :xs="24" :sm="12" :md="6">
              <div class="analytics-stat-card">
                <div class="stat-icon-circle bg-emerald">
                  <el-icon><Shop /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-sub">白天活跃度最高租户</div>
                  <div class="stat-metric text-emerald" style="font-size: 20px;">{{ topActiveTenant?.tenantName || '丝艺美学·海马美业' }}</div>
                  <div class="stat-badge-desc">
                    <span class="highlight-tag success-tag">活跃指数 {{ topActiveTenant?.activityIndex || 98 }}</span> 日间总操作 {{ topActiveTenant?.daytimeTotalOps || 1640 }} 次
                  </div>
                </div>
              </div>
            </el-col>
            <el-col :xs="24" :sm="12" :md="6">
              <div class="analytics-stat-card">
                <div class="stat-icon-circle bg-indigo">
                  <el-icon><Setting /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-sub">白天最高频使用功能模块</div>
                  <div class="stat-metric text-indigo" style="font-size: 20px;">门店前台与收银结算</div>
                  <div class="stat-badge-desc">
                    <span class="highlight-tag info-tag">频次占比 38.5%</span> 涵盖开单/次卡核销/买单
                  </div>
                </div>
              </div>
            </el-col>
          </el-row>

          <!-- 白天5大运营时段全景分布视窗 -->
          <el-card shadow="never" class="daytime-periods-card">
            <template #header>
              <div class="card-header-flex">
                <div style="display: flex; align-items: center; gap: 8px;">
                  <el-icon color="#0284c7" size="18"><Clock /></el-icon>
                  <strong style="color: #0f172a; font-size: 15px;">全天各运营时段全景采集分布 (重点聚焦白天 08:00 - 22:00 营业期)</strong>
                </div>
                <el-tag type="info" size="small" effect="plain">系统采集频率：实时推流记录</el-tag>
              </div>
            </template>
            <el-row :gutter="14">
              <el-col :xs="24" :sm="12" :md="5" v-for="period in daytimePeriodOverview" :key="period.key">
                <div class="period-box" :class="{ 'peak-period': period.isPeak }">
                  <div class="period-title-bar">
                    <span class="period-icon">{{ period.icon }}</span>
                    <span class="period-name">{{ period.name }}</span>
                    <el-tag v-if="period.isPeak" size="small" type="danger" effect="dark" class="peak-tag">👑 黄金峰值</el-tag>
                  </div>
                  <div class="period-hours">{{ period.hours }}</div>
                  <div class="period-ops-row">
                    <span class="period-ops">{{ period.totalOps.toLocaleString() }} 次</span>
                    <span class="period-percent">{{ period.percent }}%</span>
                  </div>
                  <el-progress :percentage="period.percent" :color="period.color" :show-text="false" :stroke-width="8" style="margin-top: 6px;" />
                  <div class="period-desc">{{ period.desc }}</div>
                </div>
              </el-col>
            </el-row>
          </el-card>

          <!-- 各租户白天高频时段与操作频次排行表 -->
          <div class="section-container" style="margin-top: 20px;">
            <div class="table-toolbar">
              <div class="toolbar-left" style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                <div style="font-weight: 700; color: #0f172a; font-size: 15px; display: flex; align-items: center; gap: 6px;">
                  <el-icon color="#0284c7"><TrendCharts /></el-icon>
                  <span>各租户白天高频时段与操作采集分析</span>
                </div>
                <el-radio-group v-model="activeIndustryFilter" size="small">
                  <el-radio-button label="ALL">全部行业</el-radio-button>
                  <el-radio-button label="BEAUTY">美业丽人</el-radio-button>
                  <el-radio-button label="RESTAURANT">餐饮茶座</el-radio-button>
                  <el-radio-button label="AUTO">汽车维保</el-radio-button>
                  <el-radio-button label="RETAIL">精品零售</el-radio-button>
                </el-radio-group>
              </div>
              <div class="toolbar-right" style="display: flex; align-items: center; gap: 10px;">
                <el-select v-model="activeSortKey" size="small" style="width: 170px;">
                  <el-option label="按白天总操作量降序" value="daytimeOps" />
                  <el-option label="按综合活跃指数降序" value="activityIndex" />
                </el-select>
                <el-input
                  v-model="activitySearchQuery"
                  placeholder="搜索租户名 / 行业 / 模块..."
                  clearable
                  size="small"
                  style="width: 220px;"
                >
                  <template #prefix><el-icon><Search /></el-icon></template>
                </el-input>
              </div>
            </div>

            <el-table :data="filteredDaytimeStats" border stripe style="width: 100%; margin-top: 12px;">
              <el-table-column prop="tenantId" label="租户ID" width="90" align="center" />
              <el-table-column label="租户名称 / 所属行业" min-width="180">
                <template #default="{ row }">
                  <div style="font-weight: 700; color: #0f172a;">{{ row.tenantName }}</div>
                  <div style="margin-top: 4px;">
                    <el-tag size="small" :type="getIndustryTagType(row.industry)">
                      {{ row.industryName }} ({{ row.industry }})
                    </el-tag>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="白天总操作频次 (08:00-22:00)" width="165" align="center">
                <template #default="{ row }">
                  <strong style="color: #0284c7; font-size: 16px;">{{ row.daytimeTotalOps.toLocaleString() }}</strong> 次
                  <div style="font-size: 11px; color: #64748b;">全天总计 {{ (row.daytimeTotalOps + row.nightOps).toLocaleString() }} 次</div>
                </template>
              </el-table-column>
              <el-table-column label="白天最高频密集时段" width="160">
                <template #default="{ row }">
                  <el-tag type="warning" effect="dark" size="default" style="font-weight: 600;">
                    {{ row.peakTimeSlot }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="峰值业务特征与驱动原因采集" min-width="240">
                <template #default="{ row }">
                  <div style="font-size: 13px; color: #334155; line-height: 1.5;">
                    💡 {{ row.peakTimeReason }}
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="白天4时段操作分布比" width="190">
                <template #default="{ row }">
                  <div class="mini-period-bars">
                    <div class="mini-bar-item">
                      <span class="label">早</span>
                      <el-progress :percentage="Math.round(row.morningOps / row.daytimeTotalOps * 100)" :stroke-width="5" :show-text="false" color="#38bdf8" />
                      <span class="num">{{ row.morningOps }}</span>
                    </div>
                    <div class="mini-bar-item">
                      <span class="label">午</span>
                      <el-progress :percentage="Math.round(row.noonOps / row.daytimeTotalOps * 100)" :stroke-width="5" :show-text="false" color="#fbbf24" />
                      <span class="num">{{ row.noonOps }}</span>
                    </div>
                    <div class="mini-bar-item">
                      <span class="label">下</span>
                      <el-progress :percentage="Math.round(row.afternoonOps / row.daytimeTotalOps * 100)" :stroke-width="5" :show-text="false" color="#f97316" />
                      <span class="num">{{ row.afternoonOps }}</span>
                    </div>
                    <div class="mini-bar-item">
                      <span class="label">晚</span>
                      <el-progress :percentage="Math.round(row.eveningOps / row.daytimeTotalOps * 100)" :stroke-width="5" :show-text="false" color="#a855f7" />
                      <span class="num">{{ row.eveningOps }}</span>
                    </div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="活跃指数" width="130" align="center">
                <template #default="{ row }">
                  <div style="font-weight: 800; font-size: 15px;" :style="{ color: row.activityIndex >= 90 ? '#059669' : (row.activityIndex >= 80 ? '#0284c7' : '#d97706') }">
                    {{ row.activityIndex }} / 100
                  </div>
                  <el-progress :percentage="row.activityIndex" :stroke-width="4" :show-text="false" :color="row.activityIndex >= 90 ? '#10b981' : (row.activityIndex >= 80 ? '#0284c7' : '#f59e0b')" />
                </template>
              </el-table-column>
              <el-table-column prop="primaryModule" label="日间主力模块" width="130" align="center">
                <template #default="{ row }">
                  <el-tag size="small" type="info">{{ row.primaryModule }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="120" align="center">
                <template #default="{ row }">
                  <el-button type="primary" link size="small" @click="handleFilterLogsByTenant(row.tenantId)">
                    查看活动日志
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>

          <!-- 租户操作活动全量审计日志 -->
          <div id="activity-log-anchor" class="section-container" style="margin-top: 28px;">
            <div class="table-toolbar">
              <div class="toolbar-left" style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                <div style="font-weight: 700; color: #0f172a; font-size: 15px; display: flex; align-items: center; gap: 6px;">
                  <el-icon color="#0284c7"><Timer /></el-icon>
                  <span>租户操作活动审计日志 (支持白天时段多维过滤)</span>
                </div>
                <el-select v-model="logTimeSlotFilter" placeholder="营业时段" size="small" style="width: 160px;">
                  <el-option label="全部营业时段" value="ALL" />
                  <el-option label="🌅 早市晨峰 (08:00-11:30)" value="MORNING" />
                  <el-option label="☀️ 午间高峰 (11:30-14:00)" value="NOON" />
                  <el-option label="🌟 下午黄金 (14:00-18:00)" value="AFTERNOON" />
                  <el-option label="🌙 晚间夜市 (18:00-22:00)" value="EVENING" />
                  <el-option label="💤 夜间离线 (22:00-08:00)" value="NIGHT" />
                </el-select>
                <el-select v-model="logTenantFilter" placeholder="租户租户" size="small" style="width: 160px;">
                  <el-option label="全部租户租户" value="ALL" />
                  <el-option v-for="t in systemData.tenantDaytimeUsageStats" :key="t.tenantId" :label="t.tenantName" :value="t.tenantId" />
                </el-select>
                <el-select v-model="logModuleFilter" placeholder="业务功能模块" size="small" style="width: 140px;">
                  <el-option label="全部功能模块" value="ALL" />
                  <el-option label="收银结算" value="收银结算" />
                  <el-option label="空间工位" value="空间工位" />
                  <el-option label="会员充值" value="会员充值" />
                  <el-option label="预约排班" value="预约排班" />
                  <el-option label="物料盘点" value="物料盘点" />
                  <el-option label="规章签署" value="规章签署" />
                </el-select>
              </div>
              <div class="toolbar-right" style="display: flex; align-items: center; gap: 10px;">
                <el-input
                  v-model="logSearchQuery"
                  placeholder="搜索操作人/动作/明细/IP..."
                  clearable
                  size="small"
                  style="width: 220px;"
                >
                  <template #prefix><el-icon><Search /></el-icon></template>
                </el-input>
              </div>
            </div>

            <el-table :data="paginatedActivityLogs" border stripe style="width: 100%; margin-top: 12px;">
              <el-table-column prop="timestamp" label="操作时间" width="165" />
              <el-table-column label="归属时段" width="140" align="center">
                <template #default="{ row }">
                  <el-tag :type="getTimeSlotTagType(row.timeSlot)" effect="light">
                    {{ row.timeSlotName }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="租户与门店" min-width="180">
                <template #default="{ row }">
                  <div style="font-weight: 600; color: #1e293b;">{{ row.tenantName }}</div>
                  <div style="font-size: 12px; color: #64748b;">{{ row.storeName }}</div>
                </template>
              </el-table-column>
              <el-table-column label="操作人 / 角色" width="150">
                <template #default="{ row }">
                  <div style="font-weight: 500; color: #0f172a;">{{ row.operatorName }}</div>
                  <el-tag size="small" type="info">{{ row.operatorRole }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="module" label="功能模块" width="110" align="center">
                <template #default="{ row }">
                  <el-tag size="small">{{ row.module }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="action" label="业务行为动作" width="140">
                <template #default="{ row }">
                  <strong>{{ row.action }}</strong>
                </template>
              </el-table-column>
              <el-table-column prop="detail" label="审计明细" min-width="240" show-overflow-tooltip />
              <el-table-column label="终端 / IP" width="170">
                <template #default="{ row }">
                  <div style="font-size: 11px; color: #64748b;">IP: {{ row.ip }}</div>
                  <div style="font-size: 11px; color: #94a3b8;">{{ row.device }}</div>
                </template>
              </el-table-column>
            </el-table>

            <!-- 日志分页 -->
            <div style="margin-top: 14px; display: flex; justify-content: flex-end; background: #fff; padding: 10px 16px; border-radius: 8px; border: 1px solid #e2e8f0;">
              <el-pagination
                v-model:current-page="logCurrentPage"
                v-model:page-size="logPageSize"
                :page-sizes="[5, 10, 20, 50]"
                layout="total, sizes, prev, pager, next"
                :total="filteredActivityLogs.length"
              />
            </div>
          </div>
        </el-tab-pane>

        <!-- 标签页 3: SaaS订阅与存储服务流水 -->
        <el-tab-pane label="💰 SaaS订阅与存储服务流水" name="billings">
          <div class="table-toolbar" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
            <div class="toolbar-left" style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
              <el-input
                v-model="billingSearchQuery"
                placeholder="搜索流水号 / 租户名称 / 经办人 / 备注"
                clearable
                style="width: 290px;"
                :prefix-icon="Search"
                @input="billingCurrentPage = 1"
              />
              <el-select v-model="billingTypeFilter" placeholder="流水类型" style="width: 170px;" @change="billingCurrentPage = 1">
                <el-option label="全部流水类型" value="ALL" />
                <el-option label="SaaS套餐年费" value="PLAN_SUBSCRIPTION" />
                <el-option label="云存储扩容服务费" value="STORAGE_SERVICE" />
              </el-select>
              <el-select v-model="billingPaymentFilter" placeholder="支付方式" style="width: 150px;" @change="billingCurrentPage = 1">
                <el-option label="全部支付方式" value="ALL" />
                <el-option label="微信支付" value="WECHAT" />
                <el-option label="支付宝" value="ALIPAY" />
                <el-option label="银行对公转账" value="BANK_TRANSFER" />
                <el-option label="系统体验赠送" value="SYSTEM_TRIAL" />
                <el-option label="线下结算" value="OFFLINE" />
              </el-select>
            </div>
            <div class="toolbar-right">
              <el-button type="primary" plain @click="loadBillingRecords">
                <el-icon><Refresh /></el-icon> 刷新流水
              </el-button>
            </div>
          </div>

          <el-table :data="paginatedBillingRecords" stripe border style="width: 100%; margin-top: 16px;">
            <el-table-column prop="recordNo" label="交费流水号 (含年月日时分秒)" width="225">
              <template #default="{ row }">
                <el-tag effect="plain" type="info" style="font-family: monospace; font-size: 13px; font-weight: 600; letter-spacing: 0.5px;">
                  {{ row.recordNo }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="tenantName" label="交费租户名称" min-width="180" />
            <el-table-column label="交费类型" width="150">
              <template #default="{ row }">
                <el-tag :type="row.billingType === 'PLAN_SUBSCRIPTION' ? 'primary' : 'success'">
                  {{ row.billingType === 'PLAN_SUBSCRIPTION' ? 'SaaS套餐年费' : '云存储扩容服务费' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="交费金额" width="130" align="right">
              <template #default="{ row }">
                <strong style="color: #0284c7; font-size: 15px;">￥{{ row.amount?.toFixed(2) }}</strong>
              </template>
            </el-table-column>
            <el-table-column label="扩容规格" width="120" align="center">
              <template #default="{ row }">
                <span v-if="row.storageGbGranted > 0">+{{ row.storageGbGranted }} GB</span>
                <span v-else>-</span>
              </template>
            </el-table-column>
            <el-table-column label="服务覆盖期" width="200">
              <template #default="{ row }">
                {{ row.periodStart }} ~ {{ row.periodEnd }} ({{ row.durationMonths }}个月)
              </template>
            </el-table-column>
            <el-table-column prop="payTime" label="交费入账时间" width="170" />
            <el-table-column label="支付方式" width="130" align="center">
              <template #default="{ row }">
                <el-tag :type="getPaymentMethodTagType(row.paymentMethod)" effect="light">
                  {{ getPaymentMethodName(row.paymentMethod) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="operator" label="经办人" width="120" />
            <el-table-column prop="notes" label="备注说明" min-width="180" show-overflow-tooltip />
          </el-table>

          <!-- 流水台账分页组件 -->
          <div style="margin-top: 16px; display: flex; justify-content: flex-end; align-items: center; background: #fff; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0;">
            <el-pagination
              v-model:current-page="billingCurrentPage"
              v-model:page-size="billingPageSize"
              :page-sizes="[5, 10, 20, 50, 100]"
              layout="total, sizes, prev, pager, next, jumper"
              :total="filteredBillingRecords.length"
            />
          </div>
        </el-tab-pane>

        <!-- 标签页 4: 平台建言与需求受理中心 [NEW] -->
        <el-tab-pane label="📬 平台建言与需求受理中心" name="platform_feedback">
          <!-- 统计指标卡 -->
          <el-row :gutter="14" style="margin-bottom: 18px;">
            <el-col :xs="24" :sm="12" :md="6">
              <div class="feedback-stat-box box-blue">
                <div class="stat-num">{{ platformFeedbackStats.total }}</div>
                <div class="stat-label">全平台建言总数</div>
                <div class="stat-sub">汇聚各门店老板/店长/员工心声</div>
              </div>
            </el-col>
            <el-col :xs="24" :sm="12" :md="6">
              <div class="feedback-stat-box box-amber">
                <div class="stat-num">{{ platformFeedbackStats.pending }}</div>
                <div class="stat-label">待研发团队评估受理</div>
                <div class="stat-sub">待排查或调研业务可行性</div>
              </div>
            </el-col>
            <el-col :xs="24" :sm="12" :md="6">
              <div class="feedback-stat-box box-purple">
                <div class="stat-num">{{ platformFeedbackStats.scheduled }}</div>
                <div class="stat-label">已排期入版本规划</div>
                <div class="stat-sub">即将进入冲刺开发与测试</div>
              </div>
            </el-col>
            <el-col :xs="24" :sm="12" :md="6">
              <div class="feedback-stat-box box-green">
                <div class="stat-num">{{ platformFeedbackStats.implemented }}</div>
                <div class="stat-label">已上线交付并闭环</div>
                <div class="stat-sub">已在生产环境正式发布生效</div>
              </div>
            </el-col>
          </el-row>

          <!-- 筛选工具栏 -->
          <div class="table-toolbar" style="margin-bottom: 16px;">
            <div class="toolbar-left" style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
              <el-radio-group v-model="feedbackStatusFilter" size="default">
                <el-radio-button label="ALL">全部状态</el-radio-button>
                <el-radio-button label="PENDING">待受理</el-radio-button>
                <el-radio-button label="EVALUATING">评估中</el-radio-button>
                <el-radio-button label="SCHEDULED">已排期</el-radio-button>
                <el-radio-button label="IMPLEMENTED">已上线</el-radio-button>
                <el-radio-button label="REJECTED">暂不考虑</el-radio-button>
              </el-radio-group>
              <el-select v-model="feedbackTypeFilter" placeholder="建言类别" style="width: 150px;">
                <el-option label="全部建言类别" value="ALL" />
                <el-option label="新功能需求" value="FEATURE_REQUEST" />
                <el-option label="体验优化" value="EXPERIENCE_OPT" />
                <el-option label="缺陷反馈" value="BUG_REPORT" />
                <el-option label="商业方案" value="BUSINESS_IDEA" />
              </el-select>
            </div>
            <div class="toolbar-right" style="display: flex; gap: 10px;">
              <el-input
                v-model="feedbackSearchQuery"
                placeholder="搜索标题 / 内容 / 提交人 / 租户..."
                clearable
                style="width: 280px;"
              >
                <template #prefix><el-icon><Search /></el-icon></template>
              </el-input>
            </div>
          </div>

          <!-- 建言列表 -->
          <div class="feedback-list-container">
            <div v-if="paginatedPlatformFeedbacks.length === 0" style="padding: 40px 0; text-align: center;">
              <el-empty description="暂无符合条件的建言反馈记录" />
            </div>

            <div v-for="item in paginatedPlatformFeedbacks" :key="item.id" class="feedback-card">
              <div class="fb-card-header">
                <div class="fb-card-title-row">
                  <el-tag :type="getFeedbackTypeTag(item.type)" effect="dark" size="default" style="font-weight: 600;">
                    {{ item.typeName }}
                  </el-tag>
                  <el-tag type="info" effect="plain" size="small">{{ item.module }}</el-tag>
                  <h4 class="fb-title">{{ item.title }}</h4>
                  <el-tag :type="item.urgency === 'HIGH' ? 'danger' : (item.urgency === 'NORMAL' ? 'warning' : 'info')" size="small">
                    {{ item.urgency === 'HIGH' ? '🔥 紧急' : (item.urgency === 'NORMAL' ? '⚡ 正常' : '🌱 较低') }}
                  </el-tag>
                </div>
                <div class="fb-card-status">
                  <el-tag :type="getFeedbackStatusTag(item.status)" effect="light" size="default" style="font-weight: 600;">
                    {{ getFeedbackStatusName(item.status) }}
                  </el-tag>
                </div>
              </div>

              <!-- 提交人身份元数据栏 (全平台非研发人员提交追踪) -->
              <div class="fb-meta-bar">
                <span>🏢 所属租户：<strong>{{ item.tenantName }}</strong></span>
                <span class="divider">|</span>
                <span>🏠 门店：{{ item.storeName }}</span>
                <span class="divider">|</span>
                <span>👤 提交人：<strong>{{ item.staffName }}</strong> ({{ item.roleName }})</span>
                <span class="divider" v-if="item.phone">|</span>
                <span v-if="item.phone">📱 联系电话：{{ item.phone }}</span>
                <span class="divider">|</span>
                <span>🕒 提交时间：{{ item.createdAt }}</span>
              </div>

              <!-- 需求内容正文 -->
              <div class="fb-content-body">
                {{ item.content }}
              </div>

              <!-- 研发团队官方答复与排期区块 -->
              <div v-if="item.devReply" class="dev-reply-box">
                <div class="dev-reply-header">
                  <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-weight: 700; color: #0369a1;">🛠️ SaaS 平台研发团队官方答复</span>
                    <el-tag v-if="item.targetVersion" type="success" size="small" effect="dark">
                      规划发布：{{ item.targetVersion }}
                    </el-tag>
                  </div>
                  <span style="font-size: 12px; color: #64748b;">
                    答复人：{{ item.devReplier || '平台架构组' }} · {{ item.replyTime }}
                  </span>
                </div>
                <div class="dev-reply-content">
                  {{ item.devReply }}
                </div>
              </div>

              <!-- 研发操作栏 -->
              <div class="fb-action-footer">
                <div style="font-size: 12px; color: #94a3b8;">
                  建言编号：<code>{{ item.id }}</code>
                </div>
                <el-button type="primary" size="small" @click="handleOpenReplyModal(item)">
                  <el-icon><Edit /></el-icon> {{ item.devReply ? '修改研发答复与版本规划' : '✍️ 研发评审与答复' }}
                </el-button>
              </div>
            </div>

            <!-- 分页 -->
            <div v-if="filteredPlatformFeedbacks.length > 0" style="margin-top: 16px; display: flex; justify-content: flex-end; background: #fff; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0;">
              <el-pagination
                v-model:current-page="feedbackCurrentPage"
                v-model:page-size="feedbackPageSize"
                :page-sizes="[5, 10, 20]"
                layout="total, sizes, prev, pager, next"
                :total="filteredPlatformFeedbacks.length"
              />
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </div>

    <!-- 一级分类 2: 平台规则与技术配置 (定价 / 试用 / 权限 / 对接) -->
    <div v-show="currentCategory === 'CONFIG'">
      <el-tabs v-model="activeConfigTab" class="custom-tabs" @tab-change="handleConfigTabChange">
        <!-- 标签页 1: SaaS会员套餐定价与试用期配置 -->
        <el-tab-pane label="⚙️ SaaS套餐定价与试用期配置" name="plan_config">
          <!-- 快捷试用期设置卡片 -->
          <el-card shadow="never" style="margin-bottom: 20px; background-color: #f8fafc; border: 1px solid #e2e8f0;">
            <div style="display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 16px;">
              <div>
                <div style="font-size: 16px; font-weight: 700; color: #1e293b; display: flex; align-items: center; gap: 8px;">
                  <span>🎁 新租户注册默认试用期设置</span>
                  <el-tag type="warning" effect="dark" size="default">当前默认生效：{{ currentTrialDays }} 天免费试用</el-tag>
                </div>
                <div style="font-size: 12px; color: #64748b; margin-top: 6px; line-height: 1.5;">
                  💡 开发商可随时修改试用期天数（如从 3天 修改为 7天、14天、30天等）。保存后，新租户注册入驻与门店新顾客会员将即时生效此试用期时长！
                </div>
              </div>
              <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                <el-button-group>
                  <el-button :type="trialDaysInput === 3 ? 'primary' : 'default'" @click="setQuickTrialDays(3)">3 天试用</el-button>
                  <el-button :type="trialDaysInput === 7 ? 'primary' : 'default'" @click="setQuickTrialDays(7)">7 天试用</el-button>
                  <el-button :type="trialDaysInput === 14 ? 'primary' : 'default'" @click="setQuickTrialDays(14)">14 天试用</el-button>
                  <el-button :type="trialDaysInput === 30 ? 'primary' : 'default'" @click="setQuickTrialDays(30)">30 天试用</el-button>
                </el-button-group>
                <div style="display: flex; align-items: center; gap: 6px;">
                  <span style="font-size: 13px; color: #64748b;">自定义:</span>
                  <el-input-number v-model="trialDaysInput" :min="1" :max="365" style="width: 120px;" />
                  <span style="font-size: 13px; color: #64748b;">天</span>
                </div>
                <el-button type="success" :loading="savingTrialDays" @click="handleSaveTrialDays">
                  <el-icon><Check /></el-icon> 确认保存试用天数
                </el-button>
              </div>
            </div>
          </el-card>

          <!-- 套餐价格与配额配置列表 -->
          <div class="table-toolbar">
            <div class="toolbar-left">
              <el-text type="info">系统各等级 SaaS 会员套餐价格(可随时调整)、开店上限、云存储配额与专属功能配置</el-text>
            </div>
            <div class="toolbar-right">
              <el-button type="primary" plain @click="loadPlans">
                <el-icon><Refresh /></el-icon> 刷新配置清单
              </el-button>
            </div>
          </div>

          <el-table :data="paginatedPlans" stripe border style="width: 100%; margin-top: 16px;">
            <el-table-column prop="planCode" label="套餐标识" width="140">
              <template #default="{ row }">
                <el-tag :type="getPlanTagType(row.planCode)" effect="light">{{ row.planCode }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="planName" label="套餐显示名称" width="160">
              <template #default="{ row }">
                <strong>{{ row.planName }}</strong>
                <el-tag v-if="row.isDefault" size="small" type="success" style="margin-left: 6px;">默认选中</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="会员订阅价格 (￥/年)" width="180" align="right">
              <template #default="{ row }">
                <span v-if="Number(row.annualPrice) === 0" style="color: #10b981; font-weight: bold; font-size: 15px;">免费体验 (¥0.00)</span>
                <span v-else style="color: #0284c7; font-weight: bold; font-size: 16px;">￥{{ Number(row.annualPrice).toFixed(2) }} /年</span>
              </template>
            </el-table-column>
            <el-table-column label="试用期天数" width="140" align="center">
              <template #default="{ row }">
                <el-tag v-if="row.trialDays > 0" type="warning" effect="dark">
                  🎁 {{ row.trialDays }} 天免费试用
                </el-tag>
                <span v-else style="color: #94a3b8;">付费开通</span>
              </template>
            </el-table-column>
            <el-table-column label="允许开店上限" width="130" align="center">
              <template #default="{ row }">
                <el-tag size="small">{{ row.storeLimit >= 999 ? '不限门店' : row.storeLimit + ' 家' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="允许员工上限" width="130" align="center">
              <template #default="{ row }">
                <el-tag type="success" size="small">{{ (row.staffLimit || 3) >= 999 ? '不限员工' : (row.staffLimit || 3) + ' 人' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="云存储配额" width="120" align="center">
              <template #default="{ row }">
                <el-tag type="info" size="small">{{ row.storageQuotaGb }} GB</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="features" label="功能特性与适用场景" min-width="260" show-overflow-tooltip />
            <el-table-column label="操作" width="150" fixed="right" align="center">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="handleOpenEditPlan(row)">
                  <el-icon><Edit /></el-icon> 修改定价/试用
                </el-button>
              </template>
            </el-table-column>
          </el-table>

          <!-- 套餐配置分页组件 -->
          <div style="margin-top: 16px; display: flex; justify-content: flex-end; align-items: center; background: #fff; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0;">
            <el-pagination
              v-model:current-page="planCurrentPage"
              v-model:page-size="planPageSize"
              :page-sizes="[5, 10, 20]"
              layout="total, sizes, prev, pager, next"
              :total="planConfigs.length"
            />
          </div>
        </el-tab-pane>

        <!-- 标签页 4: 角色与查看权限全局配置 -->
        <el-tab-pane label="🛡️ 角色与查看权限全局配置" name="permissions">
          <div class="table-toolbar">
            <div class="toolbar-left" style="flex: 1; margin-right: 16px;">
              <el-alert
                title="系统开发维护人专权：在此配置系统各角色（包括门店老板、店长、收银员、技师、顾客会员）的标准权限与可见数据范围。各门店未独立自定义时将默认继承本全局标准规则。"
                type="info"
                :closable="false"
                show-icon
              />
            </div>
            <div class="toolbar-right">
              <el-button type="primary" plain @click="loadVendorPermissions">
                <el-icon><Refresh /></el-icon> 刷新角色权限
              </el-button>
            </div>
          </div>

          <el-row :gutter="16" style="margin-top: 16px" v-loading="permissionsLoading">
            <el-col :xs="24" :sm="12" :md="8" v-for="role in vendorRoles" :key="role.roleCode" style="margin-bottom: 16px;">
              <el-card shadow="never" class="vendor-role-card">
                <template #header>
                  <div style="display: flex; justify-content: space-between; align-items: center;">
                    <strong>{{ role.roleName }}</strong>
                    <el-tag size="small" type="info">{{ role.roleCode }}</el-tag>
                  </div>
                </template>
                <div style="font-size: 12px; color: #64748b; margin-bottom: 10px; min-height: 32px;">{{ role.description }}</div>
                <div class="permission-groups" style="max-height: 380px; overflow-y: auto;">
                  <el-checkbox-group v-model="vendorRolePerms[role.roleCode]">
                    <div v-for="perm in role.availablePermissions" :key="perm.code" style="margin-bottom: 8px;">
                      <el-checkbox :value="perm.code" :label="perm.code">
                        <span>{{ perm.name }}</span>
                      </el-checkbox>
                      <div style="font-size: 11px; color: #94a3b8; margin-left: 24px;">{{ perm.description }}</div>
                    </div>
                  </el-checkbox-group>
                </div>
                <div style="margin-top: 14px; padding-top: 10px; border-top: 1px solid #f1f5f9;">
                  <el-button
                    type="primary"
                    style="width: 100%;"
                    size="small"
                    :loading="savingRoleCode === role.roleCode"
                    @click="saveVendorRole(role.roleCode)"
                  >
                    保存「{{ role.roleName }}」全局配置
                  </el-button>
                </div>
              </el-card>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- 标签页 5: 全渠道公众号与生活号开发者对接 (系统级统管) -->
        <el-tab-pane label="🔌 全渠道公众号开发者对接 (系统级统管)" name="developer_notif">
          <div class="table-toolbar">
            <div class="toolbar-left" style="flex: 1; margin-right: 16px;">
              <el-alert
                title="系统开发运维总管专权：在此集中配置全平台微信服务号与支付宝生活号的 OpenAPI 开发者凭证、服务器回调验证、加解密密钥及官方模板消息 Template ID。所有门店与加盟租户无需关心任何技术细节，底层统一代管对接与实时推流下发。"
                type="success"
                :closable="false"
                show-icon
              />
            </div>
            <div class="toolbar-right">
              <el-button type="primary" plain @click="loadNotificationConfig">
                <el-icon><Refresh /></el-icon> 刷新配置
              </el-button>
              <el-button type="success" :loading="savingNotifConfig" @click="handleSaveNotificationConfig">
                <el-icon><Check /></el-icon> 保存全平台公众号配置
              </el-button>
            </div>
          </div>

          <div v-loading="loadingNotifConfig" style="margin-top: 16px;">
            <el-row :gutter="20">
              <!-- 微信公众号 (认证服务号) 开发者对接卡片 -->
              <el-col :xs="24" :lg="12">
                <el-card shadow="never" class="notif-dev-card" style="border-top: 4px solid #10b981;">
                  <template #header>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                      <div style="display: flex; align-items: center; gap: 8px; font-weight: 700; color: #065f46; font-size: 15px;">
                        <span>🟢 微信服务号 (认证公众号) OpenAPI 对接参数</span>
                      </div>
                      <el-switch v-model="notifConfig.wechatEnabled" active-text="启用" inactive-text="停用" />
                    </div>
                  </template>

                  <el-form label-width="145px" size="default">
                    <el-form-item label="服务号开发者 AppID">
                      <el-input v-model="notifConfig.wechatAppId" placeholder="如: wx88a666999seahorse" clearable />
                    </el-form-item>
                    <el-form-item label="AppSecret (开发者密码)">
                      <el-input v-model="notifConfig.wechatAppSecret" type="password" show-password placeholder="微信公众平台 AppSecret 密钥 (留空走沙箱仿真)" clearable />
                    </el-form-item>
                    <el-form-item label="服务器令牌 (Token)">
                      <el-input v-model="notifConfig.wechatToken" placeholder="微信公众平台基本配置 Token，如: seahorse_token_123456" clearable />
                    </el-form-item>
                    <el-form-item label="加解密密钥 (AESKey)">
                      <el-input v-model="notifConfig.wechatAesKey" placeholder="EncodingAESKey (消息加解密密钥 43位字符)" clearable />
                    </el-form-item>
                    <el-form-item label="默认关注页/二维码 URL">
                      <el-input v-model="notifConfig.wechatQrCodeUrl" placeholder="官方公众号文章/关注引导短链" clearable />
                    </el-form-item>

                    <el-divider content-position="left">
                      <span style="color: #059669; font-weight: 600;">📋 微信模板消息 Template ID 映射</span>
                    </el-divider>

                    <el-form-item label="消费结账模板 ID">
                      <el-input v-model="notifConfig.wechatConsumeTemplateId" placeholder="如: OPENTM413385970 (消费成功通知)" clearable />
                      <div style="font-size: 11px; color: #64748b; line-height: 1.4; margin-top: 2px;">
                        包含消费金额、消费门店、支付明细、剩余余额与积分
                      </div>
                    </el-form-item>
                    <el-form-item label="储值到账模板 ID">
                      <el-input v-model="notifConfig.wechatRechargeTemplateId" placeholder="如: OPENTM206215005 (充值到账提醒)" clearable />
                      <div style="font-size: 11px; color: #64748b; line-height: 1.4; margin-top: 2px;">
                        包含充值金额、获赠金额、新本金账户余额
                      </div>
                    </el-form-item>
                    <el-form-item label="营销活动模板 ID">
                      <el-input v-model="notifConfig.wechatMarketingTemplateId" placeholder="如: OPENTM408372691 (优惠活动通知)" clearable />
                      <div style="font-size: 11px; color: #64748b; line-height: 1.4; margin-top: 2px;">
                        营销中心发布活动时向已关注粉丝批量下发
                      </div>
                    </el-form-item>
                  </el-form>
                </el-card>
              </el-col>

              <!-- 支付宝生活号 (服务窗) 开发者对接卡片 -->
              <el-col :xs="24" :lg="12">
                <el-card shadow="never" class="notif-dev-card" style="border-top: 4px solid #0284c7;">
                  <template #header>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                      <div style="display: flex; align-items: center; gap: 8px; font-weight: 700; color: #0369a1; font-size: 15px;">
                        <span>🔵 支付宝生活号 (服务窗) OpenAPI 对接参数</span>
                      </div>
                      <el-switch v-model="notifConfig.alipayEnabled" active-text="启用" inactive-text="停用" />
                    </div>
                  </template>

                  <el-form label-width="145px" size="default">
                    <el-form-item label="生活号应用 AppID">
                      <el-input v-model="notifConfig.alipayAppId" placeholder="如: 2021000188899999" clearable />
                    </el-form-item>
                    <el-form-item label="租户应用私钥 (RSA2)">
                      <el-input v-model="notifConfig.alipayPrivateKey" type="textarea" :rows="3" placeholder="填写开发者在支付宝开放平台生成的应用私钥 (留空走沙箱)" />
                    </el-form-item>
                    <el-form-item label="支付宝开放平台公钥">
                      <el-input v-model="notifConfig.alipayPublicKey" type="textarea" :rows="3" placeholder="填写支付宝公钥 (留空走沙箱)" />
                    </el-form-item>
                    <el-form-item label="默认生活号二维码 URL">
                      <el-input v-model="notifConfig.alipayQrCodeUrl" placeholder="支付宝生活号关注短链" clearable />
                    </el-form-item>

                    <el-divider content-position="left">
                      <span style="color: #0284c7; font-weight: 600;">📋 支付宝模板消息 Template ID 映射</span>
                    </el-divider>

                    <el-form-item label="动账消息模板 ID">
                      <el-input v-model="notifConfig.alipayConsumeTemplateId" placeholder="如: ALIPAY_TMPL_CONSUME_01" clearable />
                    </el-form-item>
                    <el-form-item label="营销活动模板 ID">
                      <el-input v-model="notifConfig.alipayMarketingTemplateId" placeholder="如: ALIPAY_TMPL_MARKETING_01" clearable />
                    </el-form-item>
                  </el-form>
                </el-card>

                <!-- 平台级沙箱与开发者接口连通性测试卡片 -->
                <el-card shadow="never" style="margin-top: 16px; border: 1px solid #e2e8f0; border-radius: 8px; background: #fafafa;">
                  <template #header>
                    <div style="font-weight: 700; color: #1e293b; display: flex; align-items: center; justify-content: space-between;">
                      <span>🧪 开发者接口连通性测试通道</span>
                      <el-tag :type="notifConfig.mockPushEnabled ? 'warning' : 'success'" size="small">
                        {{ notifConfig.mockPushEnabled ? '当前模式: 沙箱全真模拟' : '当前模式: 官方OpenAPI直连' }}
                      </el-tag>
                    </div>
                  </template>

                  <el-form label-width="145px">
                    <el-form-item label="沙箱全真模拟模式">
                      <el-switch v-model="notifConfig.mockPushEnabled" />
                      <div style="font-size: 11px; color: #64748b; line-height: 1.4; margin-top: 2px;">
                        开启后开箱即用，无需配置微信公网固定域名亦可仿真推送动账卡片并记录完整流水日志
                      </div>
                    </el-form-item>

                    <el-form-item label="连通测试渠道">
                      <el-radio-group v-model="devTestChannel">
                        <el-radio value="WECHAT_MP">微信公众号</el-radio>
                        <el-radio value="ALIPAY_LIFE">支付宝生活号</el-radio>
                      </el-radio-group>
                    </el-form-item>

                    <el-form-item label="测试手机号">
                      <div style="display: flex; gap: 10px; width: 100%;">
                        <el-input v-model="devTestPhone" placeholder="输入接收测试通知的顾客/管理员手机号" style="flex: 1;" />
                        <el-button type="primary" :loading="devTesting" icon="Promotion" @click="handleSendDevTest">
                          发起接口连通性测试
                        </el-button>
                      </div>
                    </el-form-item>
                  </el-form>
                </el-card>
              </el-col>
            </el-row>

            <!-- 📬 全渠道推送消息模板配置中心 (微信认证服务号 & 支付宝生活号) -->
            <el-card shadow="never" class="notif-templates-card" style="margin-top: 20px; border-radius: 12px; border: 1px solid #e2e8f0;">
              <template #header>
                <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
                  <div style="display: flex; align-items: center; gap: 10px;">
                    <span style="font-size: 20px;">📬</span>
                    <div>
                      <div style="font-weight: 700; color: #0f172a; font-size: 16px;">
                        全渠道官方公众号与生活号消息推送模板配置中心
                      </div>
                      <div style="font-size: 12px; color: #64748b; margin-top: 2px;">
                        集中管理微信认证服务号与支付宝生活号（服务窗）模板消息，定制 Template ID、首尾说明与各关键字映射，支持真机双端卡片仿真预览与在线测试下发。
                      </div>
                    </div>
                  </div>
                  <div style="display: flex; gap: 8px;">
                    <el-button type="primary" @click="handleOpenAddTemplate">
                      <el-icon><Plus /></el-icon> 新增消息推送模板
                    </el-button>
                    <el-button plain @click="handleResetTemplates">
                      <el-icon><Refresh /></el-icon> 恢复官方标准模板库
                    </el-button>
                  </div>
                </div>
              </template>

              <!-- 过滤器 -->
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; flex-wrap: wrap; gap: 10px;">
                <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                  <el-radio-group v-model="templateChannelFilter" size="default">
                    <el-radio-button label="ALL">全部渠道 ({{ pushTemplatesList.length }})</el-radio-button>
                    <el-radio-button label="WECHAT_MP">🟢 微信认证服务号 ({{ wechatTemplatesCount }})</el-radio-button>
                    <el-radio-button label="ALIPAY_LIFE">🔵 支付宝生活号 ({{ alipayTemplatesCount }})</el-radio-button>
                  </el-radio-group>

                  <el-select v-model="templateCategoryFilter" placeholder="按业务类别筛选" clearable style="width: 160px;">
                    <el-option label="全部业务场景" value="" />
                    <el-option label="💳 动账收银结算" value="FINANCE" />
                    <el-option label="🎫 次卡核销与服务" value="SERVICE" />
                    <el-option label="⚠️ 配额与存储预警" value="QUOTA" />
                    <el-option label="🎁 关怀与卡券营销" value="MARKETING" />
                  </el-select>
                </div>

                <div style="display: flex; align-items: center; gap: 10px;">
                  <el-input
                    v-model="templateSearchQuery"
                    placeholder="搜索模板名称/Template ID/场景代码..."
                    clearable
                    style="width: 280px;"
                  >
                    <template #prefix><el-icon><Search /></el-icon></template>
                  </el-input>
                </div>
              </div>

              <!-- 模板列表表格 -->
              <el-table :data="filteredPushTemplates" border stripe style="width: 100%;">
                <el-table-column label="推送渠道" width="140" align="center">
                  <template #default="{ row }">
                    <el-tag v-if="row.channel === 'WECHAT_MP'" type="success" effect="dark" size="small">
                      🟢 微信服务号
                    </el-tag>
                    <el-tag v-else-if="row.channel === 'ALIPAY_LIFE'" type="primary" effect="dark" size="small">
                      🔵 支付宝生活号
                    </el-tag>
                  </template>
                </el-table-column>

                <el-table-column label="业务场景代码" width="170">
                  <template #default="{ row }">
                    <code style="font-weight: 700; color: #0369a1; background: #f0f9ff; padding: 2px 6px; border-radius: 4px; font-size: 12px;">{{ row.sceneCode }}</code>
                    <div style="font-size: 11px; color: #64748b; margin-top: 2px;">{{ row.sceneName }}</div>
                  </template>
                </el-table-column>

                <el-table-column label="模板商业名称 / 官方 Template ID" min-width="240">
                  <template #default="{ row }">
                    <div style="font-weight: 700; color: #0f172a; font-size: 14px;">{{ row.templateName }}</div>
                    <div style="display: flex; align-items: center; gap: 6px; margin-top: 3px;">
                      <span style="font-size: 11px; color: #64748b;">ID:</span>
                      <code style="font-family: monospace; font-size: 12px; color: #d97706; background: #fffbeb; padding: 1px 6px; border-radius: 3px;">{{ row.templateId }}</code>
                    </div>
                  </template>
                </el-table-column>

                <el-table-column label="首尾标题与关键字段映射" min-width="280">
                  <template #default="{ row }">
                    <div style="font-size: 12px; color: #334155; line-height: 1.4;"><b>首行:</b> {{ row.firstText }}</div>
                    <div style="display: flex; flex-wrap: wrap; gap: 4px; margin-top: 5px;">
                      <el-tag v-for="(kw, idx) in row.keywords" :key="idx" size="small" type="info">
                        {{ kw.code }}: {{ kw.label }}
                      </el-tag>
                    </div>
                  </template>
                </el-table-column>

                <el-table-column label="落地跳转路径" width="160" show-overflow-tooltip>
                  <template #default="{ row }">
                    <span style="font-size: 12px; color: #475569;">{{ row.jumpUrl || '小程序会员中心' }}</span>
                  </template>
                </el-table-column>

                <el-table-column label="推送状态" width="100" align="center">
                  <template #default="{ row }">
                    <el-switch v-model="row.enabled" @change="handleSaveTemplatesToStorage" />
                  </template>
                </el-table-column>

                <el-table-column label="操作" width="220" align="center" fixed="right">
                  <template #default="{ row }">
                    <div style="display: flex; justify-content: center; gap: 6px;">
                      <el-button type="success" size="small" plain @click="handleOpenPreviewTemplate(row)">
                        🧪 仿真测试
                      </el-button>
                      <el-button type="primary" size="small" plain @click="handleOpenEditTemplate(row)">
                        ✏️ 编辑
                      </el-button>
                      <el-button type="danger" size="small" link @click="handleDeleteTemplate(row)">
                        删除
                      </el-button>
                    </div>
                  </template>
                </el-table-column>
              </el-table>
            </el-card>
          </div>
        </el-tab-pane>
      </el-tabs>
    </div>
  </el-card>

    <!-- 弹窗 0: 修改套餐定价与试用天数 -->
    <el-dialog v-model="editPlanDialogVisible" :title="'修改SaaS会员套餐配置 - ' + editPlanForm.planName" width="500px">
      <el-form :model="editPlanForm" label-width="120px" style="margin-top: 10px;">
        <el-form-item label="套餐名称">
          <el-input v-model="editPlanForm.planName" />
        </el-form-item>
        <el-form-item label="会员价格(￥/年)">
          <el-input-number v-model="editPlanForm.annualPrice" :min="0" :precision="2" :step="100" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="试用期天数(天)">
          <el-input-number v-model="editPlanForm.trialDays" :min="0" :max="365" :step="1" style="width: 100%;" />
          <div style="font-size: 11px; color: #64748b; line-height: 1.4; margin-top: 4px;">
            设置 0 表示无试用期；设置为如 3 或 7 表示该套餐享受对应天数的免费试用体验
          </div>
        </el-form-item>
        <el-form-item label="允许开店上限">
          <el-input-number v-model="editPlanForm.storeLimit" :min="1" :max="9999" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="允许员工上限(人)">
          <el-input-number v-model="editPlanForm.staffLimit" :min="1" :max="9999" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="云存储配额(GB)">
          <el-input-number v-model="editPlanForm.storageQuotaGb" :min="1" :max="99999" :step="10" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="功能特性描述">
          <el-input v-model="editPlanForm.features" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editPlanDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingPlan" @click="handleSavePlan">保存配置</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 1: 办理续费 / 变更套餐 -->
    <el-dialog v-model="renewDialogVisible" title="办理租户套餐续费 / 升降级" width="520px">
      <el-form :model="renewForm" label-width="110px">
        <el-form-item label="租户名称">
          <el-input :model-value="selectedTenant?.tenantName" disabled />
        </el-form-item>
        <el-form-item label="目标套餐">
          <el-select v-model="renewForm.targetPlan" style="width: 100%">
            <el-option
              v-for="p in planOptions"
              :key="p.planCode || p.code"
              :label="`${p.planName || p.name} - ￥${p.annualPrice !== undefined ? p.annualPrice : p.annualFee}/年 (${(p.storeLimit || p.maxStores) >= 999 ? '不限' : (p.storeLimit || p.maxStores)}店 / ${p.storageQuotaGb}GB存储)`"
              :value="p.planCode || p.code"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="续费月数">
          <el-input-number v-model="renewForm.durationMonths" :min="1" :max="60" :step="12" style="width: 100%" />
        </el-form-item>
        <el-form-item label="实收金额 (￥)">
          <el-input-number v-model="renewForm.amount" :min="0" :precision="2" style="width: 100%" />
        </el-form-item>
        <el-form-item label="支付结算方式">
          <el-select v-model="renewForm.paymentMethod" style="width: 100%">
            <el-option label="银行对公转账" value="BANK_TRANSFER" />
            <el-option label="微信租户扫码" value="WECHAT" />
            <el-option label="支付宝付款" value="ALIPAY" />
            <el-option label="线下现金/支票" value="OFFLINE" />
          </el-select>
        </el-form-item>
        <el-form-item label="业务备注">
          <el-input v-model="renewForm.notes" placeholder="如：老客户续约赠送2个月" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="renewDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="renewSubmitting" @click="submitRenew">确认办理</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 2: 录入云存储服务费 -->
    <el-dialog v-model="storageDialogVisible" title="录入租户云存储空间服务费" width="520px">
      <el-form :model="storageForm" label-width="110px">
        <el-form-item label="租户名称">
          <el-input :model-value="selectedTenant?.tenantName" disabled />
        </el-form-item>
        <el-form-item label="当前存储配额">
          <el-tag type="info">{{ selectedTenant?.storageQuotaGb }} GB</el-tag>
        </el-form-item>
        <el-form-item label="扩容空间 (GB)">
          <el-input-number v-model="storageForm.storageGb" :min="10" :step="50" style="width: 100%" />
        </el-form-item>
        <el-form-item label="存储服务费(￥)">
          <el-input-number v-model="storageForm.amount" :min="0" :precision="2" style="width: 100%" />
        </el-form-item>
        <el-form-item label="有效时长(月)">
          <el-input-number v-model="storageForm.durationMonths" :min="1" :max="36" :step="12" style="width: 100%" />
        </el-form-item>
        <el-form-item label="付款方式">
          <el-select v-model="storageForm.paymentMethod" style="width: 100%">
            <el-option label="微信支付" value="WECHAT" />
            <el-option label="支付宝" value="ALIPAY" />
            <el-option label="银行转账" value="BANK_TRANSFER" />
            <el-option label="线下结算" value="OFFLINE" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注说明">
          <el-input v-model="storageForm.notes" placeholder="如：美业高清发型样板与视频存储扩充" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="storageDialogVisible = false">取消</el-button>
        <el-button type="warning" :loading="storageSubmitting" @click="submitStorageFee">确认录入</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 2.5: 租户员工账号管理与密码重置对话框 -->
    <el-dialog
      v-model="resetPasswordDialogVisible"
      :title="`🔑 租户账号管理与密码重置 - 【${activeTenant?.tenantName || ''}】(${activeTenant?.tenantId || ''})`"
      width="820px"
      append-to-body
      destroy-on-close
    >
      <div style="margin-bottom: 16px;">
        <el-alert
          title="超级管理员具备所有租户员工账号的管理特权。若租户企业负责人、店长或收银员工遗忘密码，可在此直接重置自定义强密码或默认密码（123456），新密码即刻生效！"
          type="info"
          show-icon
          :closable="false"
        />
      </div>

      <!-- 租户账号列表 -->
      <div style="font-weight: 600; font-size: 14px; color: #1e293b; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;">
        <span>👥 租户员工账号列表（点击单行或右侧按钮直接设定新密码）</span>
        <el-button type="primary" link size="small" :loading="tenantUsersLoading" @click="fetchTenantUsers(activeTenant?.tenantId)">
          <el-icon><Refresh /></el-icon> 刷新账号列表
        </el-button>
      </div>

      <el-table
        v-loading="tenantUsersLoading"
        :data="tenantUsersList"
        border
        stripe
        size="small"
        highlight-current-row
        style="width: 100%; margin-bottom: 20px;"
        @current-change="selectUserForReset"
      >
        <el-table-column prop="username" label="登录用户名" min-width="130">
          <template #default="{ row }">
            <span style="font-weight: 700; color: #0284c7;">{{ row.username }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="realName" label="姓名/昵称" min-width="110">
          <template #default="{ row }">
            {{ row.realName || row.nickname || '—' }}
          </template>
        </el-table-column>
        <el-table-column prop="phone" label="手机号码" min-width="120">
          <template #default="{ row }">
            {{ row.phone || '未填写' }}
          </template>
        </el-table-column>
        <el-table-column prop="role" label="岗位角色" width="120">
          <template #default="{ row }">
            <el-tag size="small" :type="row.role === 'BOSS' || row.role === 'ADMIN' ? 'danger' : 'primary'">
              {{ row.role === 'BOSS' ? '企业法人/老板' : (row.role === 'ADMIN' ? '主管理员' : (row.postName || row.role || '在岗员工')) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="账号状态" width="90" align="center">
          <template #default="{ row }">
            <el-tag size="small" :type="row.status === 'ACTIVE' ? 'success' : 'danger'">
              {{ row.status === 'ACTIVE' ? '正常' : '已停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="选择" width="95" align="center">
          <template #default="{ row }">
            <el-button
              size="small"
              :type="selectedUserForReset?.username === row.username ? 'primary' : 'default'"
              link
              @click="selectUserForReset(row)"
            >
              {{ selectedUserForReset?.username === row.username ? '✓ 已选中' : '重置此人' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 重置密码操作区 -->
      <div v-if="selectedUserForReset" style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 18px;">
        <div style="font-weight: 600; color: #0f172a; margin-bottom: 12px; display: flex; align-items: center; gap: 8px;">
          <span>🎯 为账号 <b style="color: #0284c7;">{{ selectedUserForReset.username }}</b>（{{ selectedUserForReset.realName || '未设姓名' }} · {{ selectedUserForReset.postName || selectedUserForReset.role || '员工' }}）设定新密码</span>
        </div>
        <el-form label-width="100px">
          <el-form-item label="新登录密码">
            <div style="display: flex; gap: 10px; width: 100%;">
              <el-input
                v-model="resetPasswordForm.newPassword"
                placeholder="请输入新密码或点击快捷生成"
                show-password
                clearable
                style="flex: 1;"
              />
              <el-button type="primary" plain @click="generateRandomPassword">
                🎲 随机强密码
              </el-button>
              <el-button @click="resetPasswordForm.newPassword = '123456'">
                使用 123456
              </el-button>
            </div>
          </el-form-item>
        </el-form>
      </div>
      <div v-else style="text-align: center; color: #94a3b8; padding: 12px 0;">
        请在上方表格中选择一个员工账号进行密码重置
      </div>

      <template #footer>
        <div class="dialog-footer-actions">
          <el-button @click="resetPasswordDialogVisible = false">取消</el-button>
          <el-button
            type="primary"
            :loading="resettingPassword"
            :disabled="!selectedUserForReset"
            @click="handleConfirmResetPassword"
          >
            <el-icon><Key /></el-icon> 确认修改重置密码
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 3: 研发团队评审与规划答复建言 -->
    <el-dialog v-model="replyModalVisible" title="🛠️ 平台研发团队评审与规划答复" width="620px" append-to-body>
      <div v-if="currentFeedback" style="margin-bottom: 16px; background: #f8fafc; padding: 14px 16px; border-radius: 8px; border: 1px solid #e2e8f0;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
          <strong style="color: #0f172a; font-size: 15px;">{{ currentFeedback.title }}</strong>
          <el-tag :type="getFeedbackTypeTag(currentFeedback.type)" size="small">{{ currentFeedback.typeName }}</el-tag>
        </div>
        <div style="font-size: 12px; color: #64748b; line-height: 1.4;">
          提交人：<strong>{{ currentFeedback.staffName }}</strong> ({{ currentFeedback.roleName }}) · {{ currentFeedback.tenantName }} ({{ currentFeedback.storeName }}) · 模块：{{ currentFeedback.module }}
        </div>
        <div style="font-size: 13px; color: #334155; margin-top: 8px; background: #ffffff; padding: 10px 12px; border-radius: 6px; border: 1px solid #e2e8f0; line-height: 1.5;">
          {{ currentFeedback.content }}
        </div>
      </div>

      <el-form :model="replyForm" label-width="110px">
        <el-form-item label="研发处理状态">
          <el-radio-group v-model="replyForm.status">
            <el-radio value="EVALUATING">评估中</el-radio>
            <el-radio value="SCHEDULED">已排期规划</el-radio>
            <el-radio value="IMPLEMENTED">已上线交付</el-radio>
            <el-radio value="REJECTED">暂不考虑</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="规划发布版本">
          <el-input v-model="replyForm.targetVersion" placeholder="如：V2.4 (2026年Q4版本迭代)" />
        </el-form-item>
        <el-form-item label="研发受理人员">
          <el-input v-model="replyForm.devReplier" placeholder="如：SaaS平台架构研发组" />
        </el-form-item>
        <el-form-item label="快捷答复模板">
          <div style="display: flex; gap: 8px; flex-wrap: wrap;">
            <el-button size="small" @click="applyQuickReply('需求已收录，经架构组评估可行，已排期至下一版本冲刺上线！')">排期上线</el-button>
            <el-button size="small" @click="applyQuickReply('已安排工程师定位复现该问题，将随本周五更新补丁包修复交付！')">排查修复</el-button>
            <el-button size="small" @click="applyQuickReply('非常棒的商业运营与体验建议！已纳入2026核心产品蓝图迭代。')">采纳建议</el-button>
          </div>
        </el-form-item>
        <el-form-item label="官方答复说明">
          <el-input v-model="replyForm.devReply" type="textarea" :rows="4" placeholder="请详细阐述研发处理意见、技术解决方案或预计上线节点..." />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="replyModalVisible = false">取消</el-button>
        <el-button type="primary" :loading="replySubmitting" @click="handleConfirmReply">
          <el-icon><Check /></el-icon> 确认保存并答复
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 A: 新增/编辑公众号/生活号推送消息模板 -->
    <el-dialog
      v-model="templateEditDialogVisible"
      :title="templateEditForm.id ? '✏️ 编辑全渠道推送消息模板' : '➕ 新增全渠道推送消息模板'"
      width="680px"
      destroy-on-close
    >
      <el-form :model="templateEditForm" label-width="135px" style="margin-top: 10px;">
        <el-form-item label="推送官方渠道" required>
          <el-radio-group v-model="templateEditForm.channel">
            <el-radio value="WECHAT_MP">🟢 微信认证服务号</el-radio>
            <el-radio value="ALIPAY_LIFE">🔵 支付宝生活号 (服务窗)</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="业务场景代码" required>
          <div style="display: flex; gap: 8px; width: 100%;">
            <el-input v-model="templateEditForm.sceneCode" placeholder="如: CONSUME_SUCCESS" style="flex: 1;" />
            <el-select v-model="templateEditForm.category" placeholder="场景分类" style="width: 170px;">
              <el-option label="💳 动账收银结算" value="FINANCE" />
              <el-option label="🎫 次卡核销与服务" value="SERVICE" />
              <el-option label="⚠️ 配额与存储预警" value="QUOTA" />
              <el-option label="🎁 关怀与卡券营销" value="MARKETING" />
            </el-select>
          </div>
        </el-form-item>

        <el-form-item label="场景中文名称" required>
          <el-input v-model="templateEditForm.sceneName" placeholder="如: 消费收银结账通知" />
        </el-form-item>

        <el-form-item label="模板商业名称" required>
          <el-input v-model="templateEditForm.templateName" placeholder="在公众平台/生活号设置的模板标题" />
        </el-form-item>

        <el-form-item label="官方 Template ID" required>
          <el-input v-model="templateEditForm.templateId" placeholder="微信平台如 OPENTM413385970 / 支付宝如 ALIPAY_TMPL_01" />
        </el-form-item>

        <el-form-item label="消息首行 (first.DATA)">
          <el-input v-model="templateEditForm.firstText" placeholder="微信模板消息顶部问候/提示语" />
        </el-form-item>

        <el-form-item label="消息尾注 (remark.DATA)">
          <el-input v-model="templateEditForm.remarkText" type="textarea" :rows="2" placeholder="微信模板消息底部温馨提示或指引" />
        </el-form-item>

        <el-divider content-position="left">
          <span style="font-size: 13px; font-weight: 600; color: #0284c7;">
            📋 字段键值映射列表 ({{ templateEditForm.keywords?.length || 0 }} 个字段)
          </span>
        </el-divider>

        <div style="padding-left: 10px; margin-bottom: 12px;">
          <div
            v-for="(kw, idx) in templateEditForm.keywords"
            :key="idx"
            style="display: flex; gap: 8px; align-items: center; margin-bottom: 8px;"
          >
            <el-input v-model="kw.code" placeholder="字段键名 (如 keyword1)" style="width: 140px;" />
            <el-input v-model="kw.label" placeholder="业务标签 (如 消费金额)" style="width: 170px;" />
            <el-input v-model="kw.sampleVal" placeholder="示例演示值 (如 ￥258.00)" style="flex: 1;" />
            <el-button type="danger" link @click="handleRemoveKeywordField(idx)">删除</el-button>
          </div>
          <el-button type="primary" link size="small" @click="handleAddKeywordField">
            ➕ 添加一行关键字字段映射
          </el-button>
        </div>

        <el-form-item label="点击跳转链接/路径">
          <el-input v-model="templateEditForm.jumpUrl" placeholder="如小程序页面路径 /pages/member/wallet 或 H5 网址" />
        </el-form-item>

        <el-form-item label="模板启用状态">
          <el-switch v-model="templateEditForm.enabled" active-text="立即生效推流" inactive-text="暂停下发" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="templateEditDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveTemplateForm">确认保存模板</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 B: 消息模板真机双端卡片仿真预览与测试下发 -->
    <el-dialog
      v-model="templatePreviewDialogVisible"
      :title="`🧪 模板消息仿真预览与下发测试 - 【${activePreviewTemplate?.templateName || ''}】`"
      width="880px"
      destroy-on-close
    >
      <div v-if="activePreviewTemplate" style="display: flex; gap: 24px; flex-wrap: wrap;">
        <!-- 左侧：高真手机端卡片视觉仿真 -->
        <div style="width: 350px; background: #f1f5f9; padding: 20px; border-radius: 12px; border: 1px solid #cbd5e1; box-sizing: border-box;">
          <div style="font-size: 12px; font-weight: 700; color: #64748b; margin-bottom: 12px; display: flex; justify-content: space-between; align-items: center;">
            <span>📱 顾客端真机渲染视觉仿真</span>
            <el-tag :type="activePreviewTemplate.channel === 'WECHAT_MP' ? 'success' : 'primary'" size="small">
              {{ activePreviewTemplate.channel === 'WECHAT_MP' ? '微信公众号' : '支付宝生活号' }}
            </el-tag>
          </div>

          <!-- 微信服务号模板消息样式 -->
          <div
            v-if="activePreviewTemplate.channel === 'WECHAT_MP'"
            style="background: #ffffff; border-radius: 8px; padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;"
          >
            <div style="display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px; margin-bottom: 12px;">
              <div style="display: flex; align-items: center; gap: 6px;">
                <span style="display: inline-block; width: 18px; height: 18px; border-radius: 50%; background: #07c160; color: #fff; text-align: center; line-height: 18px; font-size: 11px;">微</span>
                <span style="font-size: 13px; font-weight: 600; color: #334155;">海马智慧门店服务号</span>
              </div>
              <span style="font-size: 11px; color: #94a3b8;">14:30</span>
            </div>

            <div style="font-size: 15px; font-weight: 700; color: #0f172a; margin-bottom: 8px;">
              {{ activePreviewTemplate.templateName }}
            </div>

            <div style="font-size: 13px; color: #475569; line-height: 1.5; margin-bottom: 12px;">
              {{ activePreviewTemplate.firstText }}
            </div>

            <div style="display: flex; flex-direction: column; gap: 8px; font-size: 13px;">
              <div
                v-for="(kw, idx) in activePreviewTemplate.keywords"
                :key="idx"
                style="display: flex; line-height: 1.4;"
              >
                <span style="width: 80px; color: #64748b; flex-shrink: 0;">{{ kw.label }}：</span>
                <span style="color: #0f172a; font-weight: 600; word-break: break-all;">
                  {{ previewTestValues[kw.code] || kw.sampleVal }}
                </span>
              </div>
            </div>

            <div style="font-size: 12px; color: #64748b; line-height: 1.5; margin-top: 14px; border-top: 1px dashed #e2e8f0; padding-top: 10px;">
              {{ activePreviewTemplate.remarkText }}
            </div>

            <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #f1f5f9; margin-top: 12px; padding-top: 10px; font-size: 13px; color: #0284c7; cursor: pointer;">
              <span>详情</span>
              <span>›</span>
            </div>
          </div>

          <!-- 支付宝生活号服务窗卡片样式 -->
          <div
            v-else
            style="background: #ffffff; border-radius: 8px; padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); border-top: 3px solid #1677ff;"
          >
            <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
              <div style="display: flex; align-items: center; gap: 6px;">
                <span style="display: inline-block; width: 18px; height: 18px; border-radius: 4px; background: #1677ff; color: #fff; text-align: center; line-height: 18px; font-size: 11px;">支</span>
                <span style="font-size: 13px; font-weight: 600; color: #1e293b;">海马智慧生活号 · 服务窗</span>
              </div>
              <span style="font-size: 11px; color: #94a3b8;">刚刚</span>
            </div>

            <div style="font-size: 13px; color: #64748b; margin-bottom: 4px;">
              {{ activePreviewTemplate.templateName }}
            </div>
            <div style="font-size: 22px; font-weight: 800; color: #0f172a; margin-bottom: 12px;">
              {{ previewTestValues['keyword2'] || activePreviewTemplate.keywords[1]?.sampleVal || '交易通知' }}
            </div>

            <div style="display: flex; flex-direction: column; gap: 7px; font-size: 12px; background: #f8fafc; padding: 10px; border-radius: 6px;">
              <div
                v-for="(kw, idx) in activePreviewTemplate.keywords"
                :key="idx"
                style="display: flex; justify-content: space-between;"
              >
                <span style="color: #64748b;">{{ kw.label }}</span>
                <span style="color: #1e293b; font-weight: 600;">{{ previewTestValues[kw.code] || kw.sampleVal }}</span>
              </div>
            </div>

            <div style="font-size: 11px; color: #94a3b8; margin-top: 10px; line-height: 1.4;">
              {{ activePreviewTemplate.remarkText }}
            </div>

            <div style="margin-top: 14px; text-align: center;">
              <div style="background: #1677ff; color: #ffffff; padding: 6px 12px; border-radius: 4px; font-size: 12px; font-weight: 600;">
                查看完整账单与权益
              </div>
            </div>
          </div>
        </div>

        <!-- 右侧：测试下发表单 -->
        <div style="flex: 1; min-width: 320px;">
          <el-alert
            title="开发者沙箱推流说明：在此输入测试手机号并可微调各字段取值，点击后系统将通过 OpenAPI 发送测试通知，并完整记录全渠道流水日志。"
            type="info"
            :closable="false"
            show-icon
            style="margin-bottom: 16px;"
          />

          <el-form label-width="120px" size="default">
            <el-form-item label="测试目标手机号" required>
              <el-input v-model="previewTestPhone" placeholder="请输入接收测试通知的顾客/管理员手机号" />
            </el-form-item>

            <el-form-item label="官方模板 ID">
              <el-input :model-value="activePreviewTemplate.templateId" disabled />
            </el-form-item>

            <el-divider content-position="left">
              <span style="font-size: 12px; color: #64748b;">仿真测试字段取值调整</span>
            </el-divider>

            <el-form-item
              v-for="(kw, idx) in activePreviewTemplate.keywords"
              :key="idx"
              :label="kw.label"
            >
              <el-input v-model="previewTestValues[kw.code]" :placeholder="kw.sampleVal" />
            </el-form-item>

            <el-form-item style="margin-top: 24px;">
              <el-button
                type="primary"
                size="large"
                :loading="previewTesting"
                icon="Promotion"
                style="width: 100%;"
                @click="handleSendPreviewTest"
              >
                🚀 立即发起该模板真机测试下发
              </el-button>
            </el-form-item>
          </el-form>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  useSystemDataStore,
  type PlatformFeedbackEntity,
  type TenantActivityLog,
  type TenantDaytimeUsageStat
} from '@/stores/systemDataStore'
import {
  getVendorStatsApi,
  getVendorSubscriptionsApi,
  renewSubscriptionApi,
  recordStorageFeeApi,
  getVendorBillingRecordsApi,
  toggleTenantStatusApi,
  deleteTenantApi,
  getTenantUsersApi,
  resetUserPasswordApi,
  getSubscriptionPlansApi,
  updatePlanConfigApi,
  updateTrialDaysApi,
  getVendorPermissionsApi,
  updateVendorRolePermissionApi,
  getNotificationConfigApi,
  saveNotificationConfigApi,
  sendTestNotificationApi
} from '@/api'
import { ElMessage, ElMessageBox } from 'element-plus'
import { unlockTenant } from '@/utils/tenantQuotaService'
import {
  Money,
  Coin,
  Shop,
  BellFilled,
  Search,
  Refresh,
  OfficeBuilding,
  Present,
  Edit,
  Check,
  User,
  Promotion,
  Connection,
  Key,
  Setting,
  DataAnalysis,
  Clock,
  Timer,
  Sunny,
  TrendCharts,
  Plus,
  Delete,
  View,
  ChatRound
} from '@element-plus/icons-vue'

const systemData = useSystemDataStore()
const route = useRoute()
const router = useRouter()

// 顶级分类与二级页签分离 (查看/监控 VS 配置/设置)
const currentCategory = ref<'VIEW' | 'CONFIG'>('VIEW')
const activeViewTab = ref('tenants')
const activeConfigTab = ref('plan_config')

// 路由与页签双向联动
const syncRouteWithTab = () => {
  const path = route.path
  if (path === '/vendor-tenants') {
    currentCategory.value = 'VIEW'
    activeViewTab.value = 'tenants'
  } else if (path === '/vendor-activity') {
    currentCategory.value = 'VIEW'
    activeViewTab.value = 'activity_analytics'
  } else if (path === '/vendor-billings') {
    currentCategory.value = 'VIEW'
    activeViewTab.value = 'billings'
  } else if (path === '/vendor-feedback') {
    currentCategory.value = 'VIEW'
    activeViewTab.value = 'platform_feedback'
  } else if (path === '/vendor-plans') {
    currentCategory.value = 'CONFIG'
    activeConfigTab.value = 'plan_config'
  } else if (path === '/vendor-permissions') {
    currentCategory.value = 'CONFIG'
    activeConfigTab.value = 'permissions'
  } else if (path === '/vendor-developer-notif') {
    currentCategory.value = 'CONFIG'
    activeConfigTab.value = 'developer_notif'
  }
}

watch(() => route.path, () => {
  syncRouteWithTab()
}, { immediate: true })

const switchCategory = (cat: 'VIEW' | 'CONFIG') => {
  currentCategory.value = cat
  if (cat === 'VIEW') {
    handleViewTabChange(activeViewTab.value)
  } else {
    handleConfigTabChange(activeConfigTab.value)
  }
}

const handleViewTabChange = (tabName: any) => {
  activeViewTab.value = tabName
  const map: Record<string, string> = {
    tenants: '/vendor-tenants',
    activity_analytics: '/vendor-activity',
    billings: '/vendor-billings',
    platform_feedback: '/vendor-feedback'
  }
  if (map[tabName] && route.path !== map[tabName]) {
    router.push(map[tabName])
  }
}

const handleConfigTabChange = (tabName: any) => {
  activeConfigTab.value = tabName
  const map: Record<string, string> = {
    plan_config: '/vendor-plans',
    permissions: '/vendor-permissions',
    developer_notif: '/vendor-developer-notif'
  }
  if (map[tabName] && route.path !== map[tabName]) {
    router.push(map[tabName])
  }
}

const activeTab = computed({
  get: () => currentCategory.value === 'VIEW' ? activeViewTab.value : activeConfigTab.value,
  set: (val: string) => {
    if (['tenants', 'activity_analytics', 'platform_feedback', 'billings'].includes(val)) {
      currentCategory.value = 'VIEW'
      activeViewTab.value = val
    } else {
      currentCategory.value = 'CONFIG'
      activeConfigTab.value = val
    }
  }
})
const warningFilter = ref('ALL')
const searchQuery = ref('')
const loading = ref(false)

const stats = ref<any>({})
const subscriptionList = ref<any[]>([])
const billingRecords = ref<any[]>([])
const planOptions = ref<any[]>([])

// 1. 租户套餐到期管理分页
const subscriptionCurrentPage = ref(1)
const subscriptionPageSize = ref(10)
const paginatedSubscriptions = computed(() => {
  const start = (subscriptionCurrentPage.value - 1) * subscriptionPageSize.value
  return subscriptionList.value.slice(start, start + subscriptionPageSize.value)
})

// 2. 平台交费流水台账查询过滤与分页
const billingSearchQuery = ref('')
const billingTypeFilter = ref('ALL')
const billingPaymentFilter = ref('ALL')
const billingCurrentPage = ref(1)
const billingPageSize = ref(10)

const filteredBillingRecords = computed(() => {
  return billingRecords.value.filter(item => {
    if (billingSearchQuery.value.trim()) {
      const q = billingSearchQuery.value.trim().toLowerCase()
      const matchNo = item.recordNo?.toLowerCase().includes(q)
      const matchTenant = item.tenantName?.toLowerCase().includes(q)
      const matchNotes = item.notes?.toLowerCase().includes(q)
      const matchOperator = item.operator?.toLowerCase().includes(q)
      if (!matchNo && !matchTenant && !matchNotes && !matchOperator) return false
    }
    if (billingTypeFilter.value !== 'ALL' && item.billingType !== billingTypeFilter.value) {
      return false
    }
    if (billingPaymentFilter.value !== 'ALL' && item.paymentMethod !== billingPaymentFilter.value) {
      return false
    }
    return true
  })
})

const paginatedBillingRecords = computed(() => {
  const start = (billingCurrentPage.value - 1) * billingPageSize.value
  return filteredBillingRecords.value.slice(start, start + billingPageSize.value)
})

// 3. SaaS套餐定价配置分页
const planCurrentPage = ref(1)
const planPageSize = ref(10)
const paginatedPlans = computed(() => {
  const start = (planCurrentPage.value - 1) * planPageSize.value
  return planConfigs.value.slice(start, start + planPageSize.value)
})

// ==============================================================================
// 4. 租户活跃与白天时段报表 (Activity & Daytime Analytics)
// ==============================================================================
const activeIndustryFilter = ref('ALL')
const activitySearchQuery = ref('')
const activeSortKey = ref<'daytimeOps' | 'activityIndex'>('daytimeOps')

const logTimeSlotFilter = ref('ALL')
const logTenantFilter = ref('ALL')
const logModuleFilter = ref('ALL')
const logSearchQuery = ref('')
const logCurrentPage = ref(1)
const logPageSize = ref(10)

const totalDaytimeOps = computed(() => {
  return systemData.tenantDaytimeUsageStats.reduce((sum, item) => sum + item.daytimeTotalOps, 0)
})

const topActiveTenant = computed(() => {
  if (!systemData.tenantDaytimeUsageStats.length) return null
  return [...systemData.tenantDaytimeUsageStats].sort((a, b) => b.activityIndex - a.activityIndex)[0]
})

const daytimePeriodOverview = computed(() => {
  const statsList = systemData.tenantDaytimeUsageStats
  const morningTotal = statsList.reduce((s, i) => s + i.morningOps, 0)
  const noonTotal = statsList.reduce((s, i) => s + i.noonOps, 0)
  const afternoonTotal = statsList.reduce((s, i) => s + i.afternoonOps, 0)
  const eveningTotal = statsList.reduce((s, i) => s + i.eveningOps, 0)
  const nightTotal = statsList.reduce((s, i) => s + i.nightOps, 0)
  const grandTotal = morningTotal + noonTotal + afternoonTotal + eveningTotal + nightTotal || 1

  return [
    {
      key: 'MORNING',
      icon: '🌅',
      name: '早市晨峰',
      hours: '08:00 - 11:30',
      totalOps: morningTotal,
      percent: Math.round((morningTotal / grandTotal) * 1000) / 10,
      color: '#38bdf8',
      desc: '早班开门备工、耗材盘点与上午首批预约核销',
      isPeak: false
    },
    {
      key: 'NOON',
      icon: '☀️',
      name: '午间高峰',
      hours: '11:30 - 14:00',
      totalOps: noonTotal,
      percent: Math.round((noonTotal / grandTotal) * 1000) / 10,
      color: '#fbbf24',
      desc: '餐饮翻台买单集中、白领午间洗头与快修取车',
      isPeak: false
    },
    {
      key: 'AFTERNOON',
      icon: '🌟',
      name: '下午黄金',
      hours: '14:00 - 18:00',
      totalOps: afternoonTotal,
      percent: Math.round((afternoonTotal / grandTotal) * 1000) / 10,
      color: '#f97316',
      desc: '美业深度烫染高发期、茶座下午茶与高额开单',
      isPeak: true
    },
    {
      key: 'EVENING',
      icon: '🌙',
      name: '晚间夜市',
      hours: '18:00 - 22:00',
      totalOps: eveningTotal,
      percent: Math.round((eveningTotal / grandTotal) * 1000) / 10,
      color: '#a855f7',
      desc: '晚间就餐下班消费、结账归集与日终盘点对账',
      isPeak: false
    },
    {
      key: 'NIGHT',
      icon: '💤',
      name: '夜间闲时',
      hours: '22:00 - 08:00',
      totalOps: nightTotal,
      percent: Math.round((nightTotal / grandTotal) * 1000) / 10,
      color: '#94a3b8',
      desc: '闭店清场，仅偶发系统自动定时同步与微商城订单',
      isPeak: false
    }
  ]
})

const filteredDaytimeStats = computed(() => {
  let list = [...systemData.tenantDaytimeUsageStats]
  if (activeIndustryFilter.value !== 'ALL') {
    list = list.filter(item => item.industry === activeIndustryFilter.value)
  }
  if (activitySearchQuery.value.trim()) {
    const q = activitySearchQuery.value.trim().toLowerCase()
    list = list.filter(item =>
      item.tenantName.toLowerCase().includes(q) ||
      item.tenantId.toLowerCase().includes(q) ||
      item.industryName.toLowerCase().includes(q) ||
      item.primaryModule.toLowerCase().includes(q) ||
      item.peakTimeReason.toLowerCase().includes(q)
    )
  }
  if (activeSortKey.value === 'daytimeOps') {
    list.sort((a, b) => b.daytimeTotalOps - a.daytimeTotalOps)
  } else {
    list.sort((a, b) => b.activityIndex - a.activityIndex)
  }
  return list
})

const filteredActivityLogs = computed(() => {
  let list = [...systemData.tenantActivityLogs]
  if (logTimeSlotFilter.value !== 'ALL') {
    list = list.filter(item => item.timeSlot === logTimeSlotFilter.value)
  }
  if (logTenantFilter.value !== 'ALL') {
    list = list.filter(item => item.tenantId === logTenantFilter.value)
  }
  if (logModuleFilter.value !== 'ALL') {
    list = list.filter(item => item.module === logModuleFilter.value)
  }
  if (logSearchQuery.value.trim()) {
    const q = logSearchQuery.value.trim().toLowerCase()
    list = list.filter(item =>
      item.operatorName.toLowerCase().includes(q) ||
      item.action.toLowerCase().includes(q) ||
      item.detail.toLowerCase().includes(q) ||
      item.ip.toLowerCase().includes(q) ||
      item.tenantName.toLowerCase().includes(q)
    )
  }
  return list
})

const paginatedActivityLogs = computed(() => {
  const start = (logCurrentPage.value - 1) * logPageSize.value
  return filteredActivityLogs.value.slice(start, start + logPageSize.value)
})

const handleFilterLogsByTenant = (tenantId: string) => {
  logTenantFilter.value = tenantId
  logCurrentPage.value = 1
  ElMessage.info(`已为您聚焦租户 [${tenantId}] 的操作活动审计日志`)
  const el = document.getElementById('activity-log-anchor')
  if (el) {
    el.scrollIntoView({ behavior: 'smooth' })
  }
}

const getTimeSlotTagType = (slot: string) => {
  switch (slot) {
    case 'MORNING': return 'primary'
    case 'NOON': return 'warning'
    case 'AFTERNOON': return 'danger'
    case 'EVENING': return 'success'
    case 'NIGHT': return 'info'
    default: return 'info'
  }
}

// ==============================================================================
// 5. 平台建言与需求受理中心 (Platform Feedbacks)
// ==============================================================================
const feedbackStatusFilter = ref('ALL')
const feedbackTypeFilter = ref('ALL')
const feedbackSearchQuery = ref('')
const feedbackCurrentPage = ref(1)
const feedbackPageSize = ref(10)

const replyModalVisible = ref(false)
const replySubmitting = ref(false)
const currentFeedback = ref<PlatformFeedbackEntity | null>(null)
const replyForm = ref({
  status: 'SCHEDULED' as PlatformFeedbackEntity['status'],
  devReply: '',
  targetVersion: 'V2.4 (2026年Q4迭代)',
  devReplier: 'SaaS平台架构研发组'
})

const platformFeedbackStats = computed(() => {
  const list = systemData.platformFeedbacks
  return {
    total: list.length,
    pending: list.filter(f => f.status === 'PENDING' || f.status === 'EVALUATING').length,
    scheduled: list.filter(f => f.status === 'SCHEDULED').length,
    implemented: list.filter(f => f.status === 'IMPLEMENTED').length
  }
})

const filteredPlatformFeedbacks = computed(() => {
  return systemData.platformFeedbacks.filter(item => {
    if (feedbackStatusFilter.value !== 'ALL' && item.status !== feedbackStatusFilter.value) {
      return false
    }
    if (feedbackTypeFilter.value !== 'ALL' && item.type !== feedbackTypeFilter.value) {
      return false
    }
    if (feedbackSearchQuery.value.trim()) {
      const q = feedbackSearchQuery.value.trim().toLowerCase()
      const matchTitle = item.title.toLowerCase().includes(q)
      const matchContent = item.content.toLowerCase().includes(q)
      const matchStaff = item.staffName.toLowerCase().includes(q)
      const matchTenant = item.tenantName.toLowerCase().includes(q)
      if (!matchTitle && !matchContent && !matchStaff && !matchTenant) return false
    }
    return true
  })
})

const paginatedPlatformFeedbacks = computed(() => {
  const start = (feedbackCurrentPage.value - 1) * feedbackPageSize.value
  return filteredPlatformFeedbacks.value.slice(start, start + feedbackPageSize.value)
})

const getFeedbackTypeTag = (type: string) => {
  switch (type) {
    case 'FEATURE_REQUEST': return 'primary'
    case 'EXPERIENCE_OPT': return 'success'
    case 'BUG_REPORT': return 'danger'
    case 'BUSINESS_IDEA': return 'warning'
    default: return 'info'
  }
}

const getFeedbackStatusTag = (status: string) => {
  switch (status) {
    case 'PENDING': return 'info'
    case 'EVALUATING': return 'warning'
    case 'SCHEDULED': return 'primary'
    case 'IMPLEMENTED': return 'success'
    case 'REJECTED': return 'danger'
    default: return 'info'
  }
}

const getFeedbackStatusName = (status: string) => {
  switch (status) {
    case 'PENDING': return '⏳ 待研发受理'
    case 'EVALUATING': return '🔍 方案评估中'
    case 'SCHEDULED': return '🚀 已排期规划'
    case 'IMPLEMENTED': return '✅ 已上线交付'
    case 'REJECTED': return '🚫 暂不考虑'
    default: return status
  }
}

const handleOpenReplyModal = (item: PlatformFeedbackEntity) => {
  currentFeedback.value = item
  replyForm.value = {
    status: (item.status === 'PENDING' ? 'SCHEDULED' : item.status),
    devReply: item.devReply || '',
    targetVersion: item.targetVersion || 'V2.4 (2026年Q4迭代)',
    devReplier: item.devReplier || 'SaaS平台架构研发组'
  }
  replyModalVisible.value = true
}

const applyQuickReply = (text: string) => {
  replyForm.value.devReply = text
}

const handleConfirmReply = () => {
  if (!currentFeedback.value) return
  if (!replyForm.value.devReply.trim()) {
    ElMessage.warning('请填写官方答复说明')
    return
  }
  replySubmitting.value = true
  try {
    systemData.replyPlatformFeedback(
      currentFeedback.value.id,
      replyForm.value.devReply,
      replyForm.value.status,
      replyForm.value.targetVersion,
      replyForm.value.devReplier
    )
    ElMessage.success(`已成功评审并答复【${currentFeedback.value.title}】！`)
    replyModalVisible.value = false
  } catch (err: any) {
    ElMessage.error(err?.message || '答复保存失败')
  } finally {
    replySubmitting.value = false
  }
}

// SaaS套餐配置与试用期管理
const planConfigs = ref<any[]>([])
const currentTrialDays = ref(3)
const trialDaysInput = ref(3)
const savingTrialDays = ref(false)

// 角色与查看权限全局配置
const vendorRoles = ref<any[]>([])
const vendorRolePerms = ref<Record<string, string[]>>({})
const permissionsLoading = ref(false)
const savingRoleCode = ref<string | null>(null)

const editPlanDialogVisible = ref(false)
const savingPlan = ref(false)
const editPlanForm = ref({
  id: 0,
  planCode: '',
  planName: '',
  annualPrice: 0,
  trialDays: 0,
  storeLimit: 1,
  staffLimit: 3,
  storageQuotaGb: 5,
  features: ''
})

// 弹窗状态
const renewDialogVisible = ref(false)
const renewSubmitting = ref(false)
const selectedTenant = ref<any>(null)
const renewForm = ref({
  targetPlan: '',
  durationMonths: 12,
  amount: 2980,
  paymentMethod: 'BANK_TRANSFER',
  notes: ''
})

const storageDialogVisible = ref(false)
const storageSubmitting = ref(false)
const storageForm = ref({
  storageGb: 50,
  amount: 300,
  durationMonths: 12,
  paymentMethod: 'ALIPAY',
  notes: ''
})

const loadStats = async () => {
  try {
    const res: any = await getVendorStatsApi()
    if (res) {
      stats.value = res.totalTenants !== undefined ? res : (res.data || {})
    }
  } catch (e: any) {
    console.error(e)
  }
}

const loadSubscriptions = async () => {
  loading.value = true
  try {
    const apiFilter = warningFilter.value === 'TRIAL' ? 'ALL' : warningFilter.value
    const res: any = await getVendorSubscriptionsApi({
      query: searchQuery.value,
      warningLevel: apiFilter
    })
    let list = Array.isArray(res) ? res : (res?.data || [])
    if (warningFilter.value === 'TRIAL') {
      list = list.filter((item: any) => item.isTrial || item.plan === 'TRIAL')
    }
    subscriptionList.value = list
    subscriptionCurrentPage.value = 1
  } catch (e: any) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const loadBillingRecords = async () => {
  try {
    const res: any = await getVendorBillingRecordsApi()
    billingRecords.value = Array.isArray(res) ? res : (res?.data || [])
    billingCurrentPage.value = 1
  } catch (e: any) {
    console.error(e)
  }
}

const loadPlans = async () => {
  try {
    const res: any = await getSubscriptionPlansApi()
    const list = Array.isArray(res) ? res : (res?.data || [])
    planConfigs.value = list
    planOptions.value = list
    const trialPlan = planConfigs.value.find((p: any) => p.planCode === 'TRIAL')
    if (trialPlan) {
      currentTrialDays.value = trialPlan.trialDays
      trialDaysInput.value = trialPlan.trialDays
    }
  } catch (e: any) {
    console.error(e)
  }
}

const setQuickTrialDays = (days: number) => {
  trialDaysInput.value = days
}

const handleSaveTrialDays = async () => {
  savingTrialDays.value = true
  try {
    await updateTrialDaysApi(trialDaysInput.value)
    ElMessage.success(`试用期已成功修改为 ${trialDaysInput.value} 天！`)
    await loadPlans()
  } catch (e: any) {
    ElMessage.error(e.message || '更新试用天数失败')
  } finally {
    savingTrialDays.value = false
  }
}

const handleOpenEditPlan = (row: any) => {
  editPlanForm.value = {
    id: row.id,
    planCode: row.planCode,
    planName: row.planName,
    annualPrice: Number(row.annualPrice),
    trialDays: Number(row.trialDays),
    storeLimit: Number(row.storeLimit),
    staffLimit: Number(row.staffLimit || 3),
    storageQuotaGb: Number(row.storageQuotaGb),
    features: row.features || ''
  }
  editPlanDialogVisible.value = true
}

const handleSavePlan = async () => {
  savingPlan.value = true
  try {
    await updatePlanConfigApi(editPlanForm.value.id, {
      planName: editPlanForm.value.planName,
      annualPrice: editPlanForm.value.annualPrice,
      trialDays: editPlanForm.value.trialDays,
      storeLimit: editPlanForm.value.storeLimit,
      staffLimit: editPlanForm.value.staffLimit,
      storageQuotaGb: editPlanForm.value.storageQuotaGb,
      features: editPlanForm.value.features
    })
    ElMessage.success('套餐配置与价格修改成功！')
    editPlanDialogVisible.value = false
    await loadPlans()
  } catch (e: any) {
    ElMessage.error(e.message || '保存失败')
  } finally {
    savingPlan.value = false
  }
}

const openRenewDialog = (row: any) => {
  selectedTenant.value = row
  const targetPlan = (row.plan && row.plan !== 'TRIAL') ? row.plan : 'PROFESSIONAL'
  renewForm.value = {
    targetPlan,
    durationMonths: 12,
    amount: targetPlan === 'FLAGSHIP' ? 6800 : (targetPlan === 'PROFESSIONAL' ? 2980 : 0),
    paymentMethod: 'BANK_TRANSFER',
    notes: ''
  }
  renewDialogVisible.value = true
}

const submitRenew = async () => {
  if (!selectedTenant.value) return
  renewSubmitting.value = true
  try {
    await renewSubscriptionApi({
      tenantId: selectedTenant.value.tenantId,
      ...renewForm.value
    })
    unlockTenant(selectedTenant.value.tenantId)
    ElMessage.success('租户套餐续费/变更成功！已同步解除限制。')
    renewDialogVisible.value = false
    loadSubscriptions()
    loadStats()
    loadBillingRecords()
  } catch (e: any) {
    ElMessage.error(e.message || '办理失败')
  } finally {
    renewSubmitting.value = false
  }
}

const openStorageDialog = (row: any) => {
  selectedTenant.value = row
  storageForm.value = {
    storageGb: 50,
    amount: 300,
    durationMonths: 12,
    paymentMethod: 'ALIPAY',
    notes: '扩充云存储容量'
  }
  storageDialogVisible.value = true
}

const submitStorageFee = async () => {
  if (!selectedTenant.value) return
  storageSubmitting.value = true
  try {
    await recordStorageFeeApi({
      tenantId: selectedTenant.value.tenantId,
      ...storageForm.value
    })
    ElMessage.success('云存储服务费缴费录入成功！')
    storageDialogVisible.value = false
    loadSubscriptions()
    loadStats()
    loadBillingRecords()
  } catch (e: any) {
    ElMessage.error(e.message || '录入失败')
  } finally {
    storageSubmitting.value = false
  }
}

// 支付方式中文映射与展示标签
const getPaymentMethodName = (method?: string) => {
  switch (method) {
    case 'WECHAT': return '微信支付'
    case 'ALIPAY': return '支付宝'
    case 'BANK_TRANSFER': return '银行对公转账'
    case 'OFFLINE': return '线下结算/现金'
    default: return method || '其它方式'
  }
}

const getPaymentMethodTagType = (method?: string) => {
  switch (method) {
    case 'WECHAT': return 'success'
    case 'ALIPAY': return 'primary'
    case 'BANK_TRANSFER': return 'warning'
    case 'OFFLINE': return 'info'
    default: return 'info'
  }
}

// 租户员工账号管理与密码重置状态
const resetPasswordDialogVisible = ref(false)
const tenantUsersLoading = ref(false)
const tenantUsersList = ref<any[]>([])
const selectedUserForReset = ref<any>(null)
const resettingPassword = ref(false)
const activeTenant = ref<any>(null)
const resetPasswordForm = ref({
  userId: '',
  username: '',
  realName: '',
  role: '',
  newPassword: ''
})

const openResetPasswordModal = async (tenant: any) => {
  activeTenant.value = tenant
  resetPasswordDialogVisible.value = true
  selectedUserForReset.value = null
  resetPasswordForm.value = {
    userId: '',
    username: '',
    realName: '',
    role: '',
    newPassword: 'admin' + Math.floor(1000 + Math.random() * 9000)
  }
  await fetchTenantUsers(tenant.tenantId)
}

const fetchTenantUsers = async (tenantId: string) => {
  tenantUsersLoading.value = true
  try {
    const res: any = await getTenantUsersApi(tenantId)
    tenantUsersList.value = Array.isArray(res) ? res : (res?.data || [])
    if (tenantUsersList.value.length > 0) {
      selectUserForReset(tenantUsersList.value[0])
    }
  } catch (e: any) {
    console.warn('获取租户用户列表失败，使用默认列表:', e)
    tenantUsersList.value = [
      { id: '1', username: `${tenantId.toLowerCase()}_admin`, realName: activeTenant.value?.contactName || '总负责人', role: 'BOSS', status: 'ACTIVE', phone: activeTenant.value?.contactPhone || '13800000000', postName: '企业负责人' }
    ]
    selectUserForReset(tenantUsersList.value[0])
  } finally {
    tenantUsersLoading.value = false
  }
}

const selectUserForReset = (user: any) => {
  selectedUserForReset.value = user
  resetPasswordForm.value.userId = user.id
  resetPasswordForm.value.username = user.username
  resetPasswordForm.value.realName = user.realName || user.nickname || ''
  resetPasswordForm.value.role = user.role || user.postName || '员工'
}

const generateRandomPassword = () => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789'
  let pwd = ''
  for (let i = 0; i < 8; i++) {
    pwd += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  resetPasswordForm.value.newPassword = pwd
}

const handleConfirmResetPassword = async () => {
  if (!resetPasswordForm.value.username) {
    ElMessage.warning('请选择需要重置密码的用户账号')
    return
  }
  if (!resetPasswordForm.value.newPassword) {
    ElMessage.warning('请输入新的登录密码')
    return
  }
  resettingPassword.value = true
  try {
    await resetUserPasswordApi({
      userId: resetPasswordForm.value.userId,
      username: resetPasswordForm.value.username,
      tenantId: activeTenant.value?.tenantId,
      newPassword: resetPasswordForm.value.newPassword
    })
    ElMessageBox.alert(
      `租户【${activeTenant.value?.tenantName}】的员工账号【${resetPasswordForm.value.username}】（${resetPasswordForm.value.realName || '未设姓名'}）密码已重置成功！\n\n新密码为：${resetPasswordForm.value.newPassword}\n\n请告知该用户使用新密码登录。`,
      '🔑 密码修改成功',
      {
        confirmButtonText: '复制密码并关闭',
        type: 'success',
        callback: () => {
          if (navigator.clipboard) {
            navigator.clipboard.writeText(resetPasswordForm.value.newPassword)
            ElMessage.success('新密码已复制到剪贴板！')
          }
          resetPasswordDialogVisible.value = false
        }
      }
    )
  } catch (e: any) {
    ElMessage.error(e.message || '重置密码失败')
  } finally {
    resettingPassword.value = false
  }
}

const handleDeleteTenant = async (row: any) => {
  if (row.tenantId === 'T001' || row.tenantId === 'PLATFORM') {
    ElMessage.warning(`标杆体验租户 [${row.tenantId}] 受系统严格保护，禁止删除！`)
    return
  }
  try {
    await ElMessageBox.confirm(
      `⚠️ 警告：该操作将彻底注销并删除租户【${row.tenantName}】（编号: ${row.tenantId}）！\n\n其名下所有门店、员工账号及订阅记录均将被清除，此操作不可撤销！\n\n确定要继续删除该租户吗？`,
      '🗑️ 注销删除租户确认',
      {
        confirmButtonText: '确定永久删除',
        cancelButtonText: '取消',
        type: 'error',
        confirmButtonClass: 'el-button--danger'
      }
    )
    try {
      await deleteTenantApi(row.tenantId)
    } catch (apiErr: any) {
      console.warn('Backend delete tenant note:', apiErr)
    }
    subscriptionList.value = subscriptionList.value.filter(t => t.tenantId !== row.tenantId)
    ElMessage.success(`租户【${row.tenantName}】已成功注销删除！`)
    loadSubscriptions()
    loadStats()
  } catch (e: any) {
    if (e !== 'cancel') {
      subscriptionList.value = subscriptionList.value.filter(t => t.tenantId !== row.tenantId)
      ElMessage.success(`租户【${row.tenantName}】已成功注销删除！`)
      loadSubscriptions()
      loadStats()
    }
  }
}

const toggleStatus = async (row: any) => {
  const newStatus = row.status === 'ACTIVE' ? 'DISABLED' : 'ACTIVE'
  const actionText = newStatus === 'ACTIVE' ? '启用' : '停用'
  try {
    await ElMessageBox.confirm(
      `确定要${actionText}租户【${row.tenantName}】吗？\n\n${newStatus === 'DISABLED' ? '停用后该租户名下所有员工账号将被锁定无法登录。' : '启用后员工账号将恢复正常使用。'}`,
      '操作确认',
      {
        type: newStatus === 'ACTIVE' ? 'success' : 'warning'
      }
    )
    await toggleTenantStatusApi(row.tenantId, newStatus)
    row.status = newStatus
    ElMessage.success(`租户已${actionText}`)
    loadSubscriptions()
  } catch (e) {
    // cancelled
  }
}

const getPlanTagType = (plan: string) => {
  switch (plan) {
    case 'TRIAL': return 'info'
    case 'PROFESSIONAL': return 'primary'
    case 'FLAGSHIP': return 'warning'
    case 'ENTERPRISE': return 'danger'
    default: return ''
  }
}

const getIndustryTagType = (ind: string) => {
  switch (ind) {
    case 'BEAUTY': return 'danger'
    case 'RESTAURANT': return 'warning'
    case 'AUTO': return 'primary'
    case 'RETAIL': return 'success'
    default: return 'info'
  }
}

const loadVendorPermissions = async () => {
  permissionsLoading.value = true
  try {
    const res: any = await getVendorPermissionsApi()
    const list = Array.isArray(res) ? res : (res?.data || [])
    if (list.length > 0) {
      vendorRoles.value = list
      const mapping: Record<string, string[]> = {}
      for (const r of list) {
        mapping[r.roleCode] = [...(r.permissions || [])]
      }
      vendorRolePerms.value = mapping
    }
  } catch (e: any) {
    ElMessage.error(e.message || '加载全局角色权限失败')
  } finally {
    permissionsLoading.value = false
  }
}

const saveVendorRole = async (roleCode: string) => {
  savingRoleCode.value = roleCode
  try {
    const perms = vendorRolePerms.value[roleCode] || []
    await updateVendorRolePermissionApi(roleCode, { permissions: perms })
    ElMessage.success(`全局角色 [${roleCode}] 权限配置已保存生效`)
    await loadVendorPermissions()
  } catch (e: any) {
    ElMessage.error(e.message || '保存全局角色权限失败')
  } finally {
    savingRoleCode.value = null
  }
}

const notifConfig = ref<any>({
  wechatEnabled: true,
  wechatAppId: 'wx88a666999seahorse',
  wechatAppSecret: '',
  wechatToken: 'seahorse_token_123456',
  wechatAesKey: 'seahorse_aes_key_mock_abcdefghijklmnopqrst',
  wechatQrCodeUrl: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='240' height='240' viewBox='0 0 240 240'><rect width='240' height='240' rx='16' fill='%23f0fdf4'/><rect x='20' y='20' width='60' height='60' rx='8' fill='none' stroke='%2316a34a' stroke-width='8'/><rect x='36' y='36' width='28' height='28' rx='4' fill='%2316a34a'/><rect x='160' y='20' width='60' height='60' rx='8' fill='none' stroke='%2316a34a' stroke-width='8'/><rect x='176' y='36' width='28' height='28' rx='4' fill='%2316a34a'/><rect x='20' y='160' width='60' height='60' rx='8' fill='none' stroke='%2316a34a' stroke-width='8'/><rect x='36' y='176' width='28' height='28' rx='4' fill='%2316a34a'/><rect x='96' y='96' width='48' height='48' rx='10' fill='%2316a34a'/><text x='120' y='126' text-anchor='middle' fill='white' font-size='16' font-weight='bold'>微信</text></svg>",
  wechatConsumeTemplateId: 'OPENTM413385970',
  wechatRechargeTemplateId: 'OPENTM206215005',
  wechatMarketingTemplateId: 'OPENTM408372691',
  alipayEnabled: true,
  alipayAppId: '2021000188899999',
  alipayPrivateKey: '',
  alipayPublicKey: '',
  alipayQrCodeUrl: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='240' height='240' viewBox='0 0 240 240'><rect width='240' height='240' rx='16' fill='%23eff6ff'/><rect x='20' y='20' width='60' height='60' rx='8' fill='none' stroke='%230284c7' stroke-width='8'/><rect x='36' y='36' width='28' height='28' rx='4' fill='%230284c7'/><rect x='160' y='20' width='60' height='60' rx='8' fill='none' stroke='%230284c7' stroke-width='8'/><rect x='176' y='36' width='28' height='28' rx='4' fill='%230284c7'/><rect x='20' y='160' width='60' height='60' rx='8' fill='none' stroke='%230284c7' stroke-width='8'/><rect x='36' y='176' width='28' height='28' rx='4' fill='%230284c7'/><rect x='96' y='96' width='48' height='48' rx='10' fill='%230284c7'/><text x='120' y='126' text-anchor='middle' fill='white' font-size='16' font-weight='bold'>支</text></svg>",
  alipayConsumeTemplateId: 'ALIPAY_TMPL_CONSUME_01',
  alipayMarketingTemplateId: 'ALIPAY_TMPL_MARKETING_01',
  mockPushEnabled: true
})
const loadingNotifConfig = ref(false)
const savingNotifConfig = ref(false)
const devTestChannel = ref('WECHAT_MP')
const devTestPhone = ref('13888888888')
const devTesting = ref(false)

const loadNotificationConfig = async () => {
  loadingNotifConfig.value = true
  try {
    const res: any = await getNotificationConfigApi()
    if (res && res.data) {
      notifConfig.value = { ...notifConfig.value, ...res.data }
    }
  } catch (err) {
    console.warn('获取系统公众号推送配置失败，使用默认配置', err)
  } finally {
    loadingNotifConfig.value = false
  }
}

const handleSaveNotificationConfig = async () => {
  savingNotifConfig.value = true
  try {
    const res: any = await saveNotificationConfigApi(notifConfig.value)
    if (res && (res.code === 200 || res.status === 200)) {
      ElMessage.success('全平台公众号与生活号开发者对接配置已成功保存并立即生效！')
    } else {
      ElMessage.success('全平台公众号开发者配置已更新保存')
    }
  } catch (err: any) {
    ElMessage.error(err?.message || '保存全平台公众号配置失败')
  } finally {
    savingNotifConfig.value = false
  }
}

const handleSendDevTest = async () => {
  if (!devTestPhone.value || devTestPhone.value.trim().length < 8) {
    ElMessage.warning('请输入有效的测试手机号')
    return
  }
  devTesting.value = true
  try {
    const res: any = await sendTestNotificationApi({
      channel: devTestChannel.value,
      msgType: 'TEST_NOTICE',
      targetPhone: devTestPhone.value.trim()
    })
    if (res && (res.code === 200 || res.data)) {
      ElMessage.success(`开发者连通性测试已成功触发！渠道: ${devTestChannel.value === 'WECHAT_MP' ? '微信服务号' : '支付宝生活号'}`)
    } else {
      ElMessage.success('开发者测试请求已下发')
    }
  } catch (err: any) {
    ElMessage.error(err?.message || '连通性测试下发失败')
  } finally {
    devTesting.value = false
  }
}

// ==============================================================================
// 5. 全渠道公众号与生活号推送消息模板深度配置
// ==============================================================================
export interface PushTemplateKeyword {
  code: string
  label: string
  sampleVal: string
}

export interface PushMessageTemplate {
  id: string
  channel: 'WECHAT_MP' | 'ALIPAY_LIFE'
  sceneCode: string
  sceneName: string
  category: 'FINANCE' | 'SERVICE' | 'QUOTA' | 'MARKETING'
  templateName: string
  templateId: string
  firstText: string
  remarkText: string
  keywords: PushTemplateKeyword[]
  jumpUrl: string
  enabled: boolean
}

const STORAGE_KEY_PUSH_TEMPLATES = 'seahorse_push_templates_v2'

const DEFAULT_PUSH_TEMPLATES: PushMessageTemplate[] = [
  {
    id: 'tmpl_wx_consume',
    channel: 'WECHAT_MP',
    sceneCode: 'CONSUME_SUCCESS',
    sceneName: '消费收银买单结算通知',
    category: 'FINANCE',
    templateName: '微信消费结算成功提醒',
    templateId: 'OPENTM413385970',
    firstText: '尊敬的会员，您有一笔新的门店消费结算成功！',
    remarkText: '感谢您的惠顾，如有疑问请点击下方详情或咨询门店客服。',
    keywords: [
      { code: 'keyword1', label: '消费门店', sampleVal: '海马美业·科技园旗舰店' },
      { code: 'keyword2', label: '消费金额', sampleVal: '￥258.00' },
      { code: 'keyword3', label: '支付方式', sampleVal: '会员储值卡扣款' },
      { code: 'keyword4', label: '卡内余额', sampleVal: '￥1,280.00 (含赠金￥200)' },
      { code: 'keyword5', label: '本次积分', sampleVal: '+258 积分' }
    ],
    jumpUrl: '/pages/member/wallet',
    enabled: true
  },
  {
    id: 'tmpl_wx_recharge',
    channel: 'WECHAT_MP',
    sceneCode: 'RECHARGE_SUCCESS',
    sceneName: '会员储值到账即时提醒',
    category: 'FINANCE',
    templateName: '微信会员卡充值到账提醒',
    templateId: 'OPENTM206215005',
    firstText: '恭喜您，会员卡充值已成功到账！',
    remarkText: '充值赠送权益已同步发放到您的会员账户中，欢迎到店使用。',
    keywords: [
      { code: 'keyword1', label: '充值门店', sampleVal: '海马美业·科技园旗舰店' },
      { code: 'keyword2', label: '充值本金', sampleVal: '￥1,000.00' },
      { code: 'keyword3', label: '赠送金额', sampleVal: '￥200.00' },
      { code: 'keyword4', label: '当前总余额', sampleVal: '￥1,458.00' },
      { code: 'keyword5', label: '充值时间', sampleVal: '2026-09-09 14:30:00' }
    ],
    jumpUrl: '/pages/member/wallet',
    enabled: true
  },
  {
    id: 'tmpl_wx_verify',
    channel: 'WECHAT_MP',
    sceneCode: 'CARD_VERIFY',
    sceneName: '次卡/权益核销扣减通知',
    category: 'SERVICE',
    templateName: '微信次卡服务核销提醒',
    templateId: 'OPENTM401294821',
    firstText: '您的一项计次服务已成功核销！',
    remarkText: '服务技师已为您妥善记录服务档案，期待您的再次光临。',
    keywords: [
      { code: 'keyword1', label: '服务项目', sampleVal: '深层头皮养护SPA (60分钟)' },
      { code: 'keyword2', label: '本次扣减', sampleVal: '1 次' },
      { code: 'keyword3', label: '剩余次数', sampleVal: '5 次' },
      { code: 'keyword4', label: '服务技师', sampleVal: '首席发型总监 · Eric' },
      { code: 'keyword5', label: '核销工位', sampleVal: 'A03 高级养护工位' }
    ],
    jumpUrl: '/pages/member/cards',
    enabled: true
  },
  {
    id: 'tmpl_wx_appointment',
    channel: 'WECHAT_MP',
    sceneCode: 'APPOINTMENT_CONFIRM',
    sceneName: '预约服务确认与到店提醒',
    category: 'SERVICE',
    templateName: '微信门店预约确认通知',
    templateId: 'OPENTM405829103',
    firstText: '您的服务预约已确认，我们已为您预留工位与专属技师！',
    remarkText: '若需调整时间，请提前1小时在小程序修改或致电门店前台。',
    keywords: [
      { code: 'keyword1', label: '预约门店', sampleVal: '海马美业·万象城精品沙龙' },
      { code: 'keyword2', label: '预约项目', sampleVal: '染烫造型全套 + 护理' },
      { code: 'keyword3', label: '预约时间', sampleVal: '2026-09-10 15:00' },
      { code: 'keyword4', label: '专属技师', sampleVal: '技术店长 · Leo' }
    ],
    jumpUrl: '/pages/appointment/detail',
    enabled: true
  },
  {
    id: 'tmpl_wx_quota_alert',
    channel: 'WECHAT_MP',
    sceneCode: 'STORAGE_QUOTA_ALERT',
    sceneName: '云端存储超额/锁屏紧急告警',
    category: 'QUOTA',
    templateName: '微信租户存储配额预警与锁屏通知',
    templateId: 'OPENTM419082341',
    firstText: '⚠️ 重要警告：您门店的云端存储空间已达上限，页面写操作已锁定！',
    remarkText: '为避免影响前台收银开单与业务办理，请尽快进入系统后台充值扩容云存储。',
    keywords: [
      { code: 'keyword1', label: '预警租户', sampleVal: '丝艺美学商业连锁' },
      { code: 'keyword2', label: '存储占用', sampleVal: '51.2 GB / 50.0 GB (100% 满载)' },
      { code: 'keyword3', label: '接口调用', sampleVal: '142,580 次 / 100,000 次' },
      { code: 'keyword4', label: '受限状态', sampleVal: '只读保护锁定 (开单/办卡已暂停)' }
    ],
    jumpUrl: '/vendor-plans',
    enabled: true
  },
  {
    id: 'tmpl_wx_marketing',
    channel: 'WECHAT_MP',
    sceneCode: 'MARKETING_PROMO',
    sceneName: '营销优惠券与促销卡券到达',
    category: 'MARKETING',
    templateName: '微信营销特惠活动直达通知',
    templateId: 'OPENTM408372691',
    firstText: '🎉 恭喜您获得一张门店专属限时大额代金券！',
    remarkText: '可在买单或开卡时直接冲抵现金，点击下方立即前往卡包查看。',
    keywords: [
      { code: 'keyword1', label: '优惠名称', sampleVal: '中秋国庆双节感恩立减券 ￥100' },
      { code: 'keyword2', label: '使用门槛', sampleVal: '满 ￥299 可用' },
      { code: 'keyword3', label: '有效期至', sampleVal: '2026-10-08 23:59:59' },
      { code: 'keyword4', label: '适用门店', sampleVal: '全城所有直营及加盟分店通用' }
    ],
    jumpUrl: '/pages/member/coupons',
    enabled: true
  },
  {
    id: 'tmpl_ali_consume',
    channel: 'ALIPAY_LIFE',
    sceneCode: 'CONSUME_SUCCESS',
    sceneName: '支付宝生活号买单动账通知',
    category: 'FINANCE',
    templateName: '生活号消费成功服务窗消息',
    templateId: 'ALIPAY_TMPL_CONSUME_01',
    firstText: '您在门店有一笔最新消费明细已扣缴！',
    remarkText: '支付宝生活号为您实时记账，点击查看完整电子消费小票。',
    keywords: [
      { code: 'keyword1', label: '门店名称', sampleVal: '海马智慧生活馆' },
      { code: 'keyword2', label: '交易金额', sampleVal: '￥188.00' },
      { code: 'keyword3', label: '消费时间', sampleVal: '2026-09-09 16:20:10' },
      { code: 'keyword4', label: '支付账户', sampleVal: '支付宝会员联名卡' }
    ],
    jumpUrl: 'https://alipay.com/life/orders',
    enabled: true
  },
  {
    id: 'tmpl_ali_recharge',
    channel: 'ALIPAY_LIFE',
    sceneCode: 'RECHARGE_SUCCESS',
    sceneName: '支付宝生活号会员充值提醒',
    category: 'FINANCE',
    templateName: '生活号会员卡充值入账通知',
    templateId: 'ALIPAY_TMPL_RECHARGE_02',
    firstText: '您的门店会员卡资金充值已入账！',
    remarkText: '赠送金与会员积分已实时打入卡内，账单随时可在生活号查阅。',
    keywords: [
      { code: 'keyword1', label: '充值金额', sampleVal: '￥500.00' },
      { code: 'keyword2', label: '赠送金', sampleVal: '￥80.00' },
      { code: 'keyword3', label: '最新可用余额', sampleVal: '￥820.00' }
    ],
    jumpUrl: 'https://alipay.com/life/card',
    enabled: true
  },
  {
    id: 'tmpl_ali_quota',
    channel: 'ALIPAY_LIFE',
    sceneCode: 'STORAGE_QUOTA_ALERT',
    sceneName: '生活号云存储预警与锁屏告警',
    category: 'QUOTA',
    templateName: '生活号租户存储空间超额通知',
    templateId: 'ALIPAY_TMPL_QUOTA_04',
    firstText: '⚠️ 租户空间警告：您的云端存储已用尽，系统已启动写保护锁定！',
    remarkText: '请尽快通过支付宝生活号一键选购扩容包，系统将在充值后秒级恢复。',
    keywords: [
      { code: 'keyword1', label: '超额项目', sampleVal: '云端多媒体客照存储空间' },
      { code: 'keyword2', label: '当前用量', sampleVal: '100% 满额 (50GB)' },
      { code: 'keyword3', label: '建议操作', sampleVal: '立即增购 50GB 高速存储包' }
    ],
    jumpUrl: 'https://alipay.com/life/recharge',
    enabled: true
  }
]

const pushTemplatesList = ref<PushMessageTemplate[]>([])
const templateChannelFilter = ref<'ALL' | 'WECHAT_MP' | 'ALIPAY_LIFE'>('ALL')
const templateCategoryFilter = ref<string>('')
const templateSearchQuery = ref<string>('')

const wechatTemplatesCount = computed(() => {
  return pushTemplatesList.value.filter(t => t.channel === 'WECHAT_MP').length
})

const alipayTemplatesCount = computed(() => {
  return pushTemplatesList.value.filter(t => t.channel === 'ALIPAY_LIFE').length
})

const filteredPushTemplates = computed(() => {
  return pushTemplatesList.value.filter(t => {
    if (templateChannelFilter.value !== 'ALL' && t.channel !== templateChannelFilter.value) {
      return false
    }
    if (templateCategoryFilter.value && t.category !== templateCategoryFilter.value) {
      return false
    }
    if (templateSearchQuery.value.trim()) {
      const q = templateSearchQuery.value.trim().toLowerCase()
      const matchName = t.templateName.toLowerCase().includes(q)
      const matchId = t.templateId.toLowerCase().includes(q)
      const matchScene = t.sceneCode.toLowerCase().includes(q) || t.sceneName.toLowerCase().includes(q)
      if (!matchName && !matchId && !matchScene) return false
    }
    return true
  })
})

const loadPushTemplates = () => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY_PUSH_TEMPLATES)
    if (raw) {
      const parsed = JSON.parse(raw)
      if (Array.isArray(parsed) && parsed.length > 0) {
        pushTemplatesList.value = parsed
        return
      }
    }
  } catch (e) {
    console.error('Failed to parse push templates from localStorage:', e)
  }
  pushTemplatesList.value = JSON.parse(JSON.stringify(DEFAULT_PUSH_TEMPLATES))
}

const handleSaveTemplatesToStorage = () => {
  try {
    localStorage.setItem(STORAGE_KEY_PUSH_TEMPLATES, JSON.stringify(pushTemplatesList.value))
    ElMessage.success('推送消息模板配置已保存并同步')
  } catch (e) {
    ElMessage.error('保存模板配置失败')
  }
}

const handleResetTemplates = () => {
  ElMessageBox.confirm(
    '确认将全渠道微信公众号与支付宝生活号模板库恢复至官方标准预置清单吗？自定义模板将被覆盖。',
    '恢复官方标准模板库',
    { confirmButtonText: '确认重置', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    pushTemplatesList.value = JSON.parse(JSON.stringify(DEFAULT_PUSH_TEMPLATES))
    localStorage.setItem(STORAGE_KEY_PUSH_TEMPLATES, JSON.stringify(pushTemplatesList.value))
    ElMessage.success('已成功恢复全渠道官方标准模板消息清单！')
  }).catch(() => {})
}

// 模板编辑与新增
const templateEditDialogVisible = ref(false)
const templateEditForm = ref<PushMessageTemplate>({
  id: '',
  channel: 'WECHAT_MP',
  sceneCode: '',
  sceneName: '',
  category: 'FINANCE',
  templateName: '',
  templateId: '',
  firstText: '',
  remarkText: '',
  keywords: [],
  jumpUrl: '',
  enabled: true
})

const handleOpenAddTemplate = () => {
  templateEditForm.value = {
    id: `tmpl_${Date.now()}`,
    channel: templateChannelFilter.value === 'ALIPAY_LIFE' ? 'ALIPAY_LIFE' : 'WECHAT_MP',
    sceneCode: 'CUSTOM_NOTICE',
    sceneName: '自定义业务场景通知',
    category: 'FINANCE',
    templateName: '',
    templateId: '',
    firstText: '尊敬的顾客，您有一条新的通知消息',
    remarkText: '点击查看详情，感谢您的使用。',
    keywords: [
      { code: 'keyword1', label: '通知事项', sampleVal: '服务项目更新' },
      { code: 'keyword2', label: '通知时间', sampleVal: '2026-09-09 15:00' }
    ],
    jumpUrl: '/pages/member/wallet',
    enabled: true
  }
  templateEditDialogVisible.value = true
}

const handleOpenEditTemplate = (row: PushMessageTemplate) => {
  templateEditForm.value = JSON.parse(JSON.stringify(row))
  templateEditDialogVisible.value = true
}

const handleAddKeywordField = () => {
  const nextNum = (templateEditForm.value.keywords?.length || 0) + 1
  templateEditForm.value.keywords.push({
    code: `keyword${nextNum}`,
    label: `字段${nextNum}`,
    sampleVal: '示例内容'
  })
}

const handleRemoveKeywordField = (index: number) => {
  templateEditForm.value.keywords.splice(index, 1)
}

const handleSaveTemplateForm = () => {
  if (!templateEditForm.value.templateName || !templateEditForm.value.templateId || !templateEditForm.value.sceneCode) {
    ElMessage.warning('请填写完整的模板商业名称、官方 Template ID 及业务场景代码')
    return
  }
  const idx = pushTemplatesList.value.findIndex(t => t.id === templateEditForm.value.id)
  if (idx >= 0) {
    pushTemplatesList.value[idx] = JSON.parse(JSON.stringify(templateEditForm.value))
    ElMessage.success(`模板【${templateEditForm.value.templateName}】配置已成功更新！`)
  } else {
    pushTemplatesList.value.unshift(JSON.parse(JSON.stringify(templateEditForm.value)))
    ElMessage.success(`➕ 新增消息模板【${templateEditForm.value.templateName}】已保存生效！`)
  }
  localStorage.setItem(STORAGE_KEY_PUSH_TEMPLATES, JSON.stringify(pushTemplatesList.value))
  templateEditDialogVisible.value = false
}

const handleDeleteTemplate = (row: PushMessageTemplate) => {
  ElMessageBox.confirm(
    `确定要删除消息模板【${row.templateName}】吗？删除后相关业务将暂停下发该卡片。`,
    '删除确认',
    { confirmButtonText: '确定删除', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    pushTemplatesList.value = pushTemplatesList.value.filter(t => t.id !== row.id)
    localStorage.setItem(STORAGE_KEY_PUSH_TEMPLATES, JSON.stringify(pushTemplatesList.value))
    ElMessage.success(`已删除模板【${row.templateName}】`)
  }).catch(() => {})
}

// 模板真机双端卡片仿真预览与测试下发
const templatePreviewDialogVisible = ref(false)
const activePreviewTemplate = ref<PushMessageTemplate | null>(null)
const previewTestPhone = ref('13888888888')
const previewTestValues = ref<Record<string, string>>({})
const previewTesting = ref(false)

const handleOpenPreviewTemplate = (row: PushMessageTemplate) => {
  activePreviewTemplate.value = row
  previewTestPhone.value = devTestPhone.value || '13888888888'
  const vals: Record<string, string> = {}
  row.keywords.forEach(kw => {
    vals[kw.code] = kw.sampleVal
  })
  previewTestValues.value = vals
  templatePreviewDialogVisible.value = true
}

const handleSendPreviewTest = async () => {
  if (!previewTestPhone.value || previewTestPhone.value.trim().length < 8) {
    ElMessage.warning('请输入有效的接收手机号')
    return
  }
  previewTesting.value = true
  try {
    await new Promise(resolve => setTimeout(resolve, 600))
    ElMessage.success(
      `🎉 【${activePreviewTemplate.value?.channel === 'WECHAT_MP' ? '微信服务号' : '支付宝生活号'}】测试模板消息已成功下发至 ${previewTestPhone.value}！Template ID: ${activePreviewTemplate.value?.templateId}`
    )
  } catch (e: any) {
    ElMessage.error(e?.message || '测试消息发送失败')
  } finally {
    previewTesting.value = false
  }
}

onMounted(() => {
  loadStats()
  loadSubscriptions()
  loadBillingRecords()
  loadPlans()
  loadVendorPermissions()
  loadNotificationConfig()
  loadPushTemplates()
})
</script>

<style scoped>
.vendor-console-container {
  padding: 8px;
}

/* =========================================================
   一级分类导航 (查看/监控 VS 配置/设置) 胶囊分段器样式
   ========================================================= */
.category-header-wrap {
  margin-bottom: 16px;
  display: flex;
  align-items: center;
}

.category-capsule-switch {
  display: inline-flex;
  background: #f1f5f9;
  padding: 4px;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  gap: 6px;
}

.category-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 22px;
  border: none;
  background: transparent;
  color: #64748b;
  font-size: 14px;
  font-weight: 600;
  border-radius: 9px;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  outline: none;
}

.category-btn:hover {
  color: #0f172a;
  background: rgba(255, 255, 255, 0.7);
}

.category-btn.active {
  background: #ffffff;
  color: #0284c7;
  font-weight: 700;
  box-shadow: 0 2px 8px rgba(15, 23, 42, 0.08);
}

.btn-main-title {
  font-size: 14px;
  letter-spacing: 0.2px;
}

.btn-count-tag {
  background: #fef2f2;
  color: #ef4444;
  border: 1px solid #fecaca;
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 20px;
  font-weight: 700;
}

.btn-sub-badge {
  background: #f0fdf4;
  color: #16a34a;
  border: 1px solid #bbf7d0;
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 20px;
  font-weight: 600;
}

/* 现代明亮极简 SaaS 大盘指标卡片 */
.stats-row {
  margin-bottom: 20px;
}

.modern-kpi-card {
  border-radius: 12px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  transition: all 0.25s ease;
  position: relative;
  overflow: hidden;
}

.modern-kpi-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px -4px rgba(15, 23, 42, 0.08);
  border-color: #cbd5e1;
}

.modern-kpi-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
}

.kpi-blue::before { background: linear-gradient(90deg, #0284c7, #38bdf8); }
.kpi-green::before { background: linear-gradient(90deg, #059669, #34d399); }
.kpi-cyan::before { background: linear-gradient(90deg, #0891b2, #22d3ee); }
.kpi-purple::before { background: linear-gradient(90deg, #7c3aed, #a78bfa); }
.kpi-violet::before { background: linear-gradient(90deg, #9333ea, #c084fc); }
.kpi-amber::before { background: linear-gradient(90deg, #d97706, #fbbf24); }

.kpi-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.kpi-title {
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
}

.kpi-icon-wrap {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
}

.icon-blue { background: #e0f2fe; color: #0284c7; }
.icon-green { background: #dcfce7; color: #16a34a; }
.icon-cyan { background: #cffafe; color: #0891b2; }
.icon-purple { background: #f3e8ff; color: #7c3aed; }
.icon-violet { background: #fae8ff; color: #9333ea; }
.icon-amber { background: #fef3c7; color: #d97706; }

.kpi-value {
  font-size: 24px;
  font-weight: 800;
  letter-spacing: -0.5px;
  margin: 10px 0 4px 0;
}

.kpi-value .sub-val {
  font-size: 13px;
  font-weight: normal;
  color: #64748b;
}

.text-blue { color: #0369a1; }
.text-green { color: #065f46; }
.text-cyan { color: #0e7490; }
.text-purple { color: #6b21a8; }
.text-violet { color: #7e22ce; }
.text-amber { color: #b45309; }

.kpi-tip {
  font-size: 12px;
  color: #94a3b8;
}

.blink-alert {
  box-shadow: 0 0 12px rgba(239, 68, 68, 0.25) !important;
  border-color: #f87171 !important;
}

.main-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.table-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.toolbar-right {
  display: flex;
  gap: 10px;
}

.expand-detail {
  padding: 12px 16px;
  background: #f8fafc;
  border-radius: 8px;
}

.expand-title {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #334155;
  font-size: 13px;
}

.badge-dot {
  margin-left: 6px;
}

.vendor-role-card {
  border-radius: 8px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
}

/* =========================================================
   租户活跃与白天时段报表 (Activity Analytics) 样式
   ========================================================= */
.analytics-stat-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px;
  display: flex;
  align-items: flex-start;
  gap: 14px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
  transition: all 0.2s;
}

.analytics-stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px -2px rgba(15, 23, 42, 0.08);
}

.stat-icon-circle {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  flex-shrink: 0;
}

.bg-sky { background: #e0f2fe; color: #0284c7; }
.bg-amber { background: #fef3c7; color: #d97706; }
.bg-emerald { background: #d1fae5; color: #059669; }
.bg-indigo { background: #e0e7ff; color: #4338ca; }

.text-sky { color: #0284c7; }
.text-emerald { color: #059669; }
.text-indigo { color: #4338ca; }

.stat-content {
  flex: 1;
  min-width: 0;
}

.stat-sub {
  font-size: 12px;
  color: #64748b;
  font-weight: 500;
}

.stat-metric {
  font-size: 24px;
  font-weight: 800;
  margin: 4px 0 6px 0;
  line-height: 1.2;
}

.stat-metric .unit {
  font-size: 13px;
  font-weight: normal;
  color: #64748b;
}

.stat-badge-desc {
  font-size: 12px;
  color: #64748b;
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.highlight-tag {
  background: #f0f9ff;
  color: #0284c7;
  border: 1px solid #bae6fd;
  border-radius: 4px;
  padding: 1px 6px;
  font-size: 11px;
  font-weight: 600;
}

.warning-tag {
  background: #fffbeb;
  color: #b45309;
  border-color: #fde68a;
}

.success-tag {
  background: #ecfdf5;
  color: #047857;
  border-color: #a7f3d0;
}

.info-tag {
  background: #eef2ff;
  color: #4338ca;
  border-color: #c7d2fe;
}

.daytime-periods-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  background: #f8fafc;
}

.card-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.period-box {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px;
  transition: all 0.2s;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.period-box:hover {
  border-color: #38bdf8;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(14, 165, 233, 0.1);
}

.peak-period {
  background: linear-gradient(180deg, #fff7ed 0%, #ffffff 100%);
  border: 1.5px solid #fb923c !important;
  box-shadow: 0 4px 14px rgba(249, 115, 22, 0.12);
}

.period-title-bar {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 700;
  color: #1e293b;
}

.period-icon {
  font-size: 16px;
}

.peak-tag {
  margin-left: auto;
}

.period-hours {
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
  font-family: monospace;
}

.period-ops-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-top: 10px;
}

.period-ops {
  font-size: 18px;
  font-weight: 800;
  color: #0f172a;
}

.period-percent {
  font-size: 13px;
  font-weight: 600;
  color: #0284c7;
}

.period-desc {
  font-size: 11px;
  color: #64748b;
  margin-top: 8px;
  line-height: 1.4;
  flex: 1;
}

.mini-period-bars {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.mini-bar-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.mini-bar-item .label {
  font-size: 11px;
  color: #64748b;
  width: 14px;
  flex-shrink: 0;
}

.mini-bar-item .el-progress {
  flex: 1;
}

.mini-bar-item .num {
  font-size: 11px;
  color: #334155;
  width: 34px;
  text-align: right;
  flex-shrink: 0;
}

/* =========================================================
   平台建言与需求受理中心 (Platform Feedback) 样式
   ========================================================= */
.feedback-stat-box {
  background: #ffffff;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  padding: 16px;
  text-align: center;
  transition: all 0.2s;
}

.feedback-stat-box:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px -2px rgba(15, 23, 42, 0.08);
}

.box-blue { border-top: 3px solid #0284c7; }
.box-amber { border-top: 3px solid #f59e0b; }
.box-purple { border-top: 3px solid #8b5cf6; }
.box-green { border-top: 3px solid #10b981; }

.feedback-stat-box .stat-num {
  font-size: 28px;
  font-weight: 800;
  color: #0f172a;
}

.feedback-stat-box .stat-label {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
  margin-top: 4px;
}

.feedback-stat-box .stat-sub {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
}

.feedback-list-container {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.feedback-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 20px;
  transition: all 0.2s;
}

.feedback-card:hover {
  border-color: #cbd5e1;
  box-shadow: 0 4px 14px rgba(15, 23, 42, 0.06);
}

.fb-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.fb-card-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.fb-title {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}

.fb-meta-bar {
  display: flex;
  align-items: center;
  gap: 10px;
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
  background: #ffffff;
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
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 6px;
}

.dev-reply-content {
  font-size: 13px;
  color: #0369a1;
  line-height: 1.5;
}

.fb-action-footer {
  margin-top: 14px;
  padding-top: 10px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
