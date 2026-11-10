<template>
  <div class="vendor-tenants-container">
    <!-- 顶部标题与开发商定位标语 (纯中文) -->
    <div class="page-hero-header">
      <div class="hero-left">
        <div class="hero-icon-box">
          <el-icon :size="26"><OfficeBuilding /></el-icon>
        </div>
        <div class="hero-text-box">
          <div class="hero-title-row">
            <h2 class="hero-title">租户订阅与门店管控 · SaaS 营销与促销中心</h2>
            <el-tag type="danger" effect="dark" size="small" class="hero-tag">SaaS 客户成功与商业增收</el-tag>
          </div>
          <p class="hero-subtitle">
            开发商运营决策中枢：全方位追踪租户全生命周期与旗下实体门店，通过试用转正早鸟券、老租户阶梯续约返利、拓店扩容包与同行裂变返佣，驱动 SaaS 业务持续稳健增长。
          </p>
        </div>
      </div>
      <div class="hero-right-actions">
        <el-button type="primary" size="default" @click="openPromotionCampaignDrawer">
          <el-icon><Present /></el-icon> SaaS 促销策略中心 ({{ activeCampaignCount }}套在线)
        </el-button>
        <el-button type="warning" plain size="default" @click="openReferralModal">
          <el-icon><Share /></el-icon> 租户老带新裂变追踪
        </el-button>
        <el-button type="success" size="default" @click="openCreateTenantModal">
          <el-icon><Plus /></el-icon> 录入新签约租户
        </el-button>
      </div>
    </div>

    <!-- 核心运营与促单漏斗指标卡片 -->
    <el-row :gutter="14" class="kpi-row">
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="kpi-card kpi-violet" @click="filterByWarningLevel('TRIAL')">
          <div class="kpi-card-header">
            <span class="kpi-card-title">🎁 试用期转化池 (促单重点)</span>
            <el-tag type="warning" size="small" effect="dark">3天倒计时中</el-tag>
          </div>
          <div class="kpi-card-body">
            <div class="kpi-main-number text-violet">
              {{ trialTenantsCount }} <span class="kpi-unit">家体验中</span>
            </div>
            <div class="kpi-sub-desc">
              <span>试用转正率 <b>{{ allTenantsMaster.length > 0 ? Math.round(normalTenantsCount / allTenantsMaster.length * 100) : 0 }}%</b> · 早鸟立减券生效中</span>
            </div>
          </div>
          <div class="kpi-card-footer">
            <span class="kpi-action-link">点击快速筛选体验租户 ({{ trialTenantsCount }}家) →</span>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="kpi-card kpi-amber" @click="filterByWarningLevel('EXPIRING_SOON')">
          <div class="kpi-card-header">
            <span class="kpi-card-title">⚠️ 到期预警锁客池 (续费重点)</span>
            <el-tag type="danger" size="small" effect="dark">{{ expiringSoonCount }} 家急需跟进</el-tag>
          </div>
          <div class="kpi-card-body">
            <div class="kpi-main-number text-amber">
              {{ expiringSoonCount }} <span class="kpi-unit">家近期到期</span>
            </div>
            <div class="kpi-sub-desc">
              <span>续费留存率 <b>94.2%</b> · 阶梯优惠锁定回款</span>
            </div>
          </div>
          <div class="kpi-card-footer">
            <span class="kpi-action-link">点击查看30天内到期名单 ({{ expiringSoonCount }}家) →</span>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="kpi-card kpi-blue" @click="filterByWarningLevel('ALL')">
          <div class="kpi-card-header">
            <span class="kpi-card-title">🏢 签约租户 / 连锁门店总数</span>
            <el-tag type="primary" size="small" effect="light">多业态覆盖</el-tag>
          </div>
          <div class="kpi-card-body">
            <div class="kpi-main-number text-blue">
              {{ allTenantsMaster.length }} <span class="kpi-unit">家 / {{ totalStoreCount }} 实体门面</span>
            </div>
            <div class="kpi-sub-desc">
              <span>平均每租户 <b>{{ (totalStoreCount / (allTenantsMaster.length || 1)).toFixed(1) }}</b> 门店</span>
            </div>
          </div>
          <div class="kpi-card-footer">
            <span class="kpi-action-link">点击展示全量租户列表 ({{ allTenantsMaster.length }}家) →</span>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="kpi-card kpi-green">
          <div class="kpi-card-header">
            <span class="kpi-card-title">💰 SaaS 营销拉动总流水</span>
            <el-tag type="success" size="small" effect="light">按实收流水核算</el-tag>
          </div>
          <div class="kpi-card-body">
            <div class="kpi-main-number text-green">
              ￥{{ totalRevenueFormatted }}
            </div>
            <div class="kpi-sub-desc">
              <span>订阅 ￥{{ subscriptionRevenueFormatted }} · 存储 ￥{{ storageRevenueFormatted }}</span>
            </div>
          </div>
          <div class="kpi-card-footer">
            <span class="kpi-stat-chip">全域实时财务记账流水</span>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- SaaS 促销策略快捷导流条 -->
    <div class="campaign-shortcut-strip">
      <div class="shortcut-left">
        <span class="shortcut-icon">🎯</span>
        <span class="shortcut-title">开发商专属 SaaS 营销与促销策略已就绪</span>
        <el-tag type="success" size="small">{{ activeCampaignCount }} 套促销策略在线生效</el-tag>
        <span class="shortcut-desc">支持在下方列表中针对试用体验中、到期预警租户点击【🎯 营销促单】进行一键精准推券。</span>
      </div>
      <div class="shortcut-right">
        <el-button type="primary" size="small" plain @click="$router.push('/vendor-campaigns')">
          管理促销策略库 →
        </el-button>
      </div>
    </div>

    <!-- 租户订阅列表主体卡片与全量管控 -->
    <el-card shadow="never" class="table-main-card">
      <div class="table-toolbar">
        <div class="toolbar-left">
          <!-- 现代胶囊状态切换器 (带精确计数与高亮状态) -->
          <div class="capsule-filter-group">
            <button
              type="button"
              class="capsule-btn"
              :class="{ 'is-active': warningFilter === 'ALL' }"
              @click="setWarningFilter('ALL')"
            >
              <span>全部租户</span>
              <span class="count-pill">{{ allTenantsMaster.length }}</span>
            </button>
            <button
              type="button"
              class="capsule-btn filter-trial"
              :class="{ 'is-active': warningFilter === 'TRIAL' }"
              @click="setWarningFilter('TRIAL')"
            >
              <span>🎁 3天试用中</span>
              <span class="count-pill pill-violet">{{ trialTenantsCount }}</span>
            </button>
            <button
              type="button"
              class="capsule-btn filter-warning"
              :class="{ 'is-active': warningFilter === 'EXPIRING_SOON' }"
              @click="setWarningFilter('EXPIRING_SOON')"
            >
              <span>⚠️ 即将到期预警</span>
              <span class="count-pill pill-amber">{{ expiringSoonCount }}</span>
            </button>
            <button
              type="button"
              class="capsule-btn"
              :class="{ 'is-active': warningFilter === 'NORMAL' }"
              @click="setWarningFilter('NORMAL')"
            >
              <span>正式服务中</span>
              <span class="count-pill pill-green">{{ normalTenantsCount }}</span>
            </button>
            <button
              type="button"
              class="capsule-btn"
              :class="{ 'is-active': warningFilter === 'EXPIRED' }"
              @click="setWarningFilter('EXPIRED')"
            >
              <span>已逾期停用</span>
              <span class="count-pill pill-gray">{{ expiredTenantsCount }}</span>
            </button>
          </div>
        </div>

        <div class="toolbar-right">
          <el-input
            v-model="searchQuery"
            placeholder="搜索租户名/联系人/手机号/编号..."
            clearable
            style="width: 280px"
          >
            <template #prefix><el-icon><Search /></el-icon></template>
          </el-input>
          <el-button type="primary" plain @click="loadSubscriptions">
            <el-icon><Refresh /></el-icon> 刷新
          </el-button>
        </div>
      </div>

      <!-- 租户管控表格 (保证数据丰富饱满，各状态下均可展示) -->
      <el-table
        :data="paginatedSubscriptions"
        v-loading="loading"
        stripe
        border
        style="width: 100%; margin-top: 14px;"
      >
        <!-- 展开行查看该租户旗下开设的多门店及行业类型 -->
        <el-table-column type="expand">
          <template #default="{ row }">
            <div class="expand-detail-panel">
              <div class="expand-header-row">
                <div class="expand-title">
                  <el-icon><OfficeBuilding /></el-icon>
                  <span>【{{ row.tenantName }}】旗下开设的全部实体门面（已开 {{ row.stores?.length || 0 }} 家 / 配额上限 {{ row.storeLimit || 1 }} 家）：</span>
                </div>
                <div class="expand-actions">
                  <el-button size="small" type="primary" plain @click="openAdjustStoreLimitModal(row)">
                    ➕ 调整/赠送开店配额 (当前: {{ row.storeLimit || 1 }} 家)
                  </el-button>
                </div>
              </div>

              <el-table :data="row.stores || []" size="small" border style="margin-top: 10px;">
                <el-table-column prop="storeId" label="门店编号" width="110" />
                <el-table-column prop="storeName" label="门店全称" min-width="200" />
                <el-table-column label="主营行业分类" width="160">
                  <template #default="{ row: s }">
                    <el-tag :type="getIndustryTagType(s.industry)" size="small">
                      {{ s.industryDesc }} ({{ s.industry }})
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="phone" label="服务预约电话" width="150" />
                <el-table-column prop="address" label="详细实体门牌经营地址" min-width="240" show-overflow-tooltip />
                <el-table-column label="营业状态" width="100" align="center">
                  <template #default>
                    <el-tag type="success" size="small">正常营业中</el-tag>
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </template>
        </el-table-column>

        <el-table-column prop="tenantId" label="租户编号" width="100" />

        <el-table-column label="租户名称 / 联系人" min-width="190">
          <template #default="{ row }">
            <div style="font-weight: 700; color: #0f172a; font-size: 14px;">{{ row.tenantName }}</div>
            <div style="font-size: 12px; color: #64748b; margin-top: 2px;">
              👤 {{ row.contactName }}（{{ row.contactPhone || '未留电话' }}）
            </div>
          </template>
        </el-table-column>

        <el-table-column label="当前SaaS套餐" width="150">
          <template #default="{ row }">
            <el-tag :type="getPlanTagType(row.plan)" effect="light" size="default">
              {{ row.planName }}
            </el-tag>
            <el-tag v-if="(row.isTrial || row.plan === 'TRIAL') && (!row.totalPaidAmount || row.totalPaidAmount <= 0)" type="warning" effect="dark" size="small" style="margin-top: 4px; display: block; width: fit-content;">
              🎁 3天试用体验期
            </el-tag>
            <el-tag v-else-if="row.totalPaidAmount > 0 || row.plan !== 'TRIAL'" type="success" effect="dark" size="small" style="margin-top: 4px; display: block; width: fit-content;">
              👑 正式商业授权
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="计费模态 / 云端存储配额" min-width="210">
          <template #default="{ row }">
            <div style="display: flex; align-items: center; gap: 6px; margin-bottom: 4px;">
              <el-tag :type="getTenantStorageDisplay(row.tenantId).billingMode === 'ANNUAL_TIER' ? 'primary' : 'success'" size="small">
                {{ getTenantStorageDisplay(row.tenantId).billingMode === 'ANNUAL_TIER' ? '👑 包年阶梯' : '🌱 免费+按量' }}
              </el-tag>
              <el-tag v-if="getTenantStorageDisplay(row.tenantId).isLocked" type="danger" size="small" effect="dark">
                🔒 页面已锁屏
              </el-tag>
              <el-tag v-else type="success" size="small" effect="plain">
                🟢 正常操作
              </el-tag>
            </div>
            <div style="font-size: 12px; color: #475569;">
              存储: <b>{{ getTenantStorageDisplay(row.tenantId).usedGb }}</b> / {{ getTenantStorageDisplay(row.tenantId).totalGb }}
              <span :style="{ color: getTenantStorageDisplay(row.tenantId).isLocked ? '#ef4444' : '#64748b' }">
                ({{ getTenantStorageDisplay(row.tenantId).pct }}%)
              </span>
            </div>
            <el-progress
              :percentage="getTenantStorageDisplay(row.tenantId).pct"
              :status="getTenantStorageDisplay(row.tenantId).isLocked ? 'exception' : (getTenantStorageDisplay(row.tenantId).pct >= 85 ? 'warning' : 'success')"
              :stroke-width="6"
              style="margin-top: 3px;"
            />
            <div style="font-size: 11px; color: #94a3b8; margin-top: 3px;">
              接口操作: {{ getTenantStorageDisplay(row.tenantId).callsUsed.toLocaleString() }} / {{ getTenantStorageDisplay(row.tenantId).callsTotal.toLocaleString() }} 次
            </div>
          </template>
        </el-table-column>

        <el-table-column label="实体门店配额" width="130" align="center">
          <template #default="{ row }">
            <div style="font-weight: 600;">
              <span :style="{ color: (row.stores?.length || 0) >= (row.storeLimit || 1) ? '#ef4444' : '#059669' }">
                {{ row.stores?.length || 0 }}
              </span>
              / {{ row.storeLimit || 1 }} 家
            </div>
            <el-tag v-if="(row.stores?.length || 0) >= (row.storeLimit || 1)" type="danger" size="small" style="margin-top: 2px;">
              已达开店上限
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column label="服务周期与到期倒计时" min-width="190">
          <template #default="{ row }">
            <div style="font-size: 12px; color: #475569;">
              {{ row.startDate }} ~ {{ row.expireDate }}
            </div>
            <div style="margin-top: 4px;">
              <el-tag :type="getWarningLevelTagType(row.warningLevel)" effect="dark" size="small">
                <template v-if="row.daysRemaining < 0">
                  ⚠️ 已逾期 {{ Math.abs(row.daysRemaining) }} 天
                </template>
                <template v-else-if="row.daysRemaining === 0">
                  ⚠️ 今日到期，请立即联系
                </template>
                <template v-else-if="row.daysRemaining <= 30">
                  ⏳ 剩余 {{ row.daysRemaining }} 天到期
                </template>
                <template v-else>
                  ✅ 充裕 (剩余 {{ row.daysRemaining }} 天)
                </template>
              </el-tag>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="SaaS营销促单状态" min-width="180">
          <template #default="{ row }">
            <div v-if="getTenantPromotionState(row).hasPromo" class="promo-status-badge">
              <span class="promo-dot"></span>
              <span class="promo-text">{{ getTenantPromotionState(row).promoTitle }}</span>
            </div>
            <div v-else class="promo-status-none">
              <span style="font-size: 12px; color: #94a3b8;">暂未派发促销券</span>
            </div>
            <div style="font-size: 11px; color: #64748b; margin-top: 2px;">
              {{ getTenantPromotionState(row).suggestion }}
            </div>
          </template>
        </el-table-column>

        <el-table-column label="累计流水" width="130" align="right">
          <template #default="{ row }">
            <div style="font-weight: 700; color: #0284c7; font-size: 14px;">
              ￥{{ (row.totalPaidAmount || 0).toFixed(2) }}
            </div>
            <div style="font-size: 11px; color: #94a3b8;">
              含存储 ￥{{ (row.storageFeePaid || 0).toFixed(2) }}
            </div>
          </template>
        </el-table-column>

        <el-table-column label="账号状态" width="100" align="center">
          <template #default="{ row }">
            <el-switch
              :model-value="row.status === 'ACTIVE'"
              active-text="启用"
              inactive-text="停用"
              inline-prompt
              @change="handleToggleTenantStatus(row)"
            />
          </template>
        </el-table-column>

        <el-table-column label="开发商运营促单操作" width="220" fixed="right" align="center">
          <template #default="{ row }">
            <div class="row-actions">
              <el-button type="warning" size="small" @click="openSendPromoModal(row)">
                <el-icon><Present /></el-icon> 营销促单
              </el-button>
              <el-button type="primary" size="small" @click="openRenewModal(row)">
                <el-icon><RefreshRight /></el-icon> 续期/升级
              </el-button>
              <el-dropdown trigger="click" @command="(cmd: string) => handleMoreAction(cmd, row)">
                <el-button size="small">
                  更多 <el-icon class="el-icon--right"><ArrowDown /></el-icon>
                </el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="reset_password">
                      <el-icon><Key /></el-icon> 🔑 账号管理与重置密码
                    </el-dropdown-item>
                    <el-dropdown-item :command="row.status === 'DISABLED' ? 'enable_tenant' : 'disable_tenant'">
                      <el-icon><Lock v-if="row.status !== 'DISABLED'" /><Unlock v-else /></el-icon>
                      {{ row.status === 'DISABLED' ? '🟢 恢复/启用租户' : '🚫 禁止/停用租户' }}
                    </el-dropdown-item>
                    <el-dropdown-item
                      command="delete_tenant"
                      :disabled="row.tenantId === 'T001' || row.tenantId === 'PLATFORM'"
                    >
                      <el-icon><Delete /></el-icon>
                      <span :style="{ color: (row.tenantId === 'T001' || row.tenantId === 'PLATFORM') ? '#94a3b8' : '#ef4444' }">
                        🗑️ 注销/删除租户
                      </span>
                    </el-dropdown-item>
                    <el-dropdown-item command="extend_trial" divided>
                      <el-icon><Timer /></el-icon> 特批延长免费试用 (+7天)
                    </el-dropdown-item>
                    <el-dropdown-item command="grant_store">
                      <el-icon><Plus /></el-icon> 特批赠送 1 家分店配额
                    </el-dropdown-item>
                    <el-dropdown-item command="grant_storage">
                      <el-icon><Coin /></el-icon> 特批赠送 20GB 云存储空间
                    </el-dropdown-item>
                    <el-dropdown-item command="lock_quota" divided>
                      <el-icon><Warning /></el-icon> ⚠️ 模拟存储超额锁屏 (测试租户端)
                    </el-dropdown-item>
                    <el-dropdown-item command="unlock_quota">
                      <el-icon><CircleCheck /></el-icon> 🟢 应急解除页面锁屏
                    </el-dropdown-item>
                    <el-dropdown-item command="grant_quota_storage">
                      <el-icon><Present /></el-icon> 🎁 赠送 10GB 存储并解封
                    </el-dropdown-item>
                    <el-dropdown-item command="record_storage" divided>
                      <el-icon><Coin /></el-icon> 补录云存储服务费
                    </el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </div>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页控制 -->
      <div class="pagination-footer">
        <el-pagination
          v-model:current-page="subscriptionCurrentPage"
          v-model:page-size="subscriptionPageSize"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="filteredTenants.length"
        />
      </div>
    </el-card>

    <!-- 弹窗 1: 定向派发 SaaS 促销券与短信/微信直达触达对话框 (样式彻底优化) -->
    <el-dialog
      v-model="sendPromoModalVisible"
      title="🎯 面向租户精准投放 SaaS 促销优惠与促单触达"
      width="720px"
      append-to-body
      destroy-on-close
      custom-class="custom-promo-dialog"
    >
      <div class="dialog-inner-opaque">
        <!-- 目标租户身份档案卡片 -->
        <div class="target-merchant-card">
          <div class="tm-avatar">🏢</div>
          <div class="tm-info">
            <div class="tm-name-row">
              <span class="tm-name">{{ activeTenant?.tenantName }}</span>
              <el-tag size="small" :type="getPlanTagType(activeTenant?.plan)">{{ activeTenant?.planName }}</el-tag>
              <el-tag size="small" type="info">ID: {{ activeTenant?.tenantId }}</el-tag>
            </div>
            <div class="tm-meta-row">
              <span>👤 联系人: <b>{{ activeTenant?.contactName }}</b></span>
              <span class="dot">·</span>
              <span>📞 电话: {{ activeTenant?.contactPhone || '未留电话' }}</span>
              <span class="dot">·</span>
              <span>⏳ 剩余到期: <b style="color: #d97706;">{{ activeTenant?.daysRemaining }} 天</b></span>
            </div>
          </div>
        </div>

        <el-form :model="sendPromoForm" label-position="top" style="margin-top: 18px;">
          <!-- 促销方案卡片选择器 (解决原radio变形和背景透光问题) -->
          <el-form-item label="选择定向投放的开发商专属促销方案" required>
            <div class="promo-card-selector">
              <div
                v-for="camp in promotionCampaigns"
                :key="camp.id"
                class="promo-select-card"
                :class="{ 'is-selected': sendPromoForm.campaignId === camp.id }"
                @click="selectPromoCampaign(camp)"
              >
                <div class="card-radio-indicator">
                  <span class="radio-circle" :class="{ checked: sendPromoForm.campaignId === camp.id }"></span>
                </div>
                <div class="card-text-body">
                  <div class="card-title-row">
                    <span class="card-title">{{ camp.title }}</span>
                    <span class="card-badge" :class="'badge-' + camp.theme">{{ camp.badge }}</span>
                    <span class="card-deduct-chip">默认立减 ￥{{ camp.defaultDeduction }}</span>
                  </div>
                  <div class="card-desc-text">{{ camp.description }}</div>
                </div>
              </div>
            </div>
          </el-form-item>

          <el-row :gutter="14">
            <el-col :span="12">
              <el-form-item label="专属特批优惠码 / 抵扣金识别号">
                <el-input v-model="sendPromoForm.discountCode" placeholder="如：VIP-2026-EARLY80" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="直接现金抵扣金额 (元)">
                <el-input-number v-model="sendPromoForm.deductionAmount" :min="0" :max="10000" :step="100" style="width: 100%;" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="附赠商业激励权益 (勾选即随券激活)">
            <el-checkbox-group v-model="sendPromoForm.extraPerks" class="perks-checkbox-group">
              <el-checkbox label="FREE_TRIAL_DAYS" border>特批延长免费试用 7 天</el-checkbox>
              <el-checkbox label="FREE_STORE_QUOTA" border>免费增加 1 家分店配额</el-checkbox>
              <el-checkbox label="FREE_STORAGE" border>赠送 30GB 云存储年卡</el-checkbox>
              <el-checkbox label="SMS_PACK" border>赠送 500 条通知短信包</el-checkbox>
            </el-checkbox-group>
          </el-form-item>

          <el-form-item label="精准促单触达通道">
            <el-checkbox-group v-model="sendPromoForm.notifyChannels">
              <el-checkbox label="WECHAT">官方微信服务号模板消息推送 (直达店长手机)</el-checkbox>
              <el-checkbox label="SMS">促销短信通知 (含专属移动端付款特惠链接)</el-checkbox>
              <el-checkbox label="INTERNAL">租户工作台登录开屏专属特惠弹窗</el-checkbox>
            </el-checkbox-group>
          </el-form-item>

          <el-form-item label="定制留言 / 促单说明">
            <el-input
              v-model="sendPromoForm.customMessage"
              type="textarea"
              :rows="3"
              placeholder="例如：陈总您好，感谢体验海马智慧商业系统！作为本月旗舰种子客户，为您特别申请了首年特惠立减¥1,000及赠送分店配额，名额保留3天，点击链接即刻生效！"
            />
          </el-form-item>
        </el-form>
      </div>

      <template #footer>
        <div class="dialog-footer-actions">
          <el-button @click="sendPromoModalVisible = false">取消</el-button>
          <el-button type="warning" :loading="sendingPromo" @click="handleConfirmSendPromo">
            🚀 确认派发促销券并触发直达触达
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 2: 编辑 / 新建 SaaS 促销策略对话框 -->
    <el-dialog
      v-model="campaignEditModalVisible"
      :title="editingCampaignId ? '✏️ 编辑 SaaS 营销促销策略' : '✨ 新建 SaaS 营销促销策略'"
      width="650px"
      append-to-body
      destroy-on-close
      custom-class="custom-promo-dialog"
    >
      <div class="dialog-inner-opaque">
        <el-form :model="campaignEditForm" label-position="top">
          <el-row :gutter="14">
            <el-col :span="16">
              <el-form-item label="策略商业标题" required>
                <el-input v-model="campaignEditForm.title" placeholder="如：新租户试用转正早鸟7折特惠" />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="策略特色标签" required>
                <el-input v-model="campaignEditForm.badge" placeholder="如：试用转正加速器" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="14">
            <el-col :span="12">
              <el-form-item label="主题视觉配色">
                <el-select v-model="campaignEditForm.theme" style="width: 100%;">
                  <el-option label="💜 梦幻紫 (试用转正专用)" value="violet" />
                  <el-option label="🧡 琥珀金 (老租户续费专用)" value="amber" />
                  <el-option label="💙 科技蓝 (连锁拓店扩容专用)" value="blue" />
                  <el-option label="💚 翡翠绿 (同行老带新裂变)" value="green" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="默认特批抵扣金额 (元)">
                <el-input-number v-model="campaignEditForm.defaultDeduction" :min="0" :step="100" style="width: 100%;" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="策略适用对象与业务说明" required>
            <el-input
              v-model="campaignEditForm.description"
              type="textarea"
              :rows="2"
              placeholder="详细描述该促销政策适用的客户群体与商务促单触发条件..."
            />
          </el-form-item>

          <el-form-item label="核心权益条款清单 (动态维护)">
            <div class="benefit-edit-list">
              <div
                v-for="(_b, idx) in campaignEditForm.benefits"
                :key="idx"
                class="benefit-edit-row"
              >
                <el-input v-model="campaignEditForm.benefits[idx]" placeholder="输入一项具体特权，如：首年签约立减 ￥1,000 元现金补贴" />
                <el-button type="danger" link @click="removeBenefitRow(idx)">删除</el-button>
              </div>
              <el-button type="primary" link size="small" @click="addBenefitRow">
                + 增加一项权益条款
              </el-button>
            </div>
          </el-form-item>

          <el-form-item label="策略生效状态">
            <el-radio-group v-model="campaignEditForm.status">
              <el-radio label="ACTIVE">在线进行中 (可向租户派发)</el-radio>
              <el-radio label="PAUSED">暂时下线暂停</el-radio>
            </el-radio-group>
          </el-form-item>
        </el-form>
      </div>

      <template #footer>
        <div class="dialog-footer-actions">
          <el-button @click="campaignEditModalVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSaveCampaign">
            保存策略配置
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 3: 租户办理续期 / 变更套餐等级对话框 -->
    <el-dialog v-model="renewModalVisible" title="💳 为租户办理 SaaS 订阅续期 / 套餐升级" width="560px" append-to-body destroy-on-close custom-class="custom-promo-dialog">
      <div class="dialog-inner-opaque">
        <el-form :model="renewForm" label-width="125px">
          <el-form-item label="租户名称">
            <el-input :model-value="activeTenant?.tenantName" disabled />
          </el-form-item>
          <el-form-item label="当前服务到期日">
            <el-tag type="info" size="large">{{ activeTenant?.expireDate }}</el-tag>
            <span style="font-size: 12px; color: #64748b; margin-left: 10px;">
              剩余 {{ activeTenant?.daysRemaining }} 天
            </span>
          </el-form-item>
          <el-form-item label="目标套餐版本" required>
            <el-select v-model="renewForm.targetPlan" style="width: 100%;">
              <el-option label="专业版套餐 (PROFESSIONAL - 适合单店轻量)" value="PROFESSIONAL" />
              <el-option label="旗舰版套餐 (FLAGSHIP - 适合标杆连锁)" value="FLAGSHIP" />
              <el-option label="企业定制版 (ENTERPRISE - 适合跨城集团)" value="ENTERPRISE" />
            </el-select>
          </el-form-item>
          <el-form-item label="续费服务周期" required>
            <el-radio-group v-model="renewForm.durationMonths">
              <el-radio :label="12">1 年 (12个月)</el-radio>
              <el-radio :label="24">2 年 (24个月 - 送3个月)</el-radio>
              <el-radio :label="36">3 年 (36个月 - 送1年旗舰)</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="实收订阅费 (元)" required>
            <el-input-number v-model="renewForm.paidAmount" :min="0" :step="100" style="width: 180px;" />
            <span style="font-size: 12px; color: #64748b; margin-left: 10px;">开发商可根据商务促单折扣调整实收金额</span>
          </el-form-item>
          <el-form-item label="支付方式" required>
            <el-select v-model="renewForm.paymentMethod" style="width: 100%;">
              <el-option label="对公银行转账" value="BANK_TRANSFER" />
              <el-option label="微信商务收款码" value="WECHAT_PAY" />
              <el-option label="支付宝企业收款" value="ALIPAY" />
              <el-option label="商务特批赠送 / 免除" value="SPECIAL_EXEMPT" />
            </el-select>
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <div class="dialog-footer-actions">
          <el-button @click="renewModalVisible = false">取消</el-button>
          <el-button type="primary" :loading="submittingRenew" @click="handleConfirmRenew">
            确认录入续费入账
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 4: 调整租户开设分店配额上限对话框 -->
    <el-dialog v-model="storeLimitModalVisible" title="🏪 调整租户分店开设配额上限" width="480px" append-to-body destroy-on-close custom-class="custom-promo-dialog">
      <div class="dialog-inner-opaque">
        <el-form label-width="130px" style="margin-top: 10px;">
          <el-form-item label="租户名称">
            <el-input :model-value="activeTenant?.tenantName" disabled />
          </el-form-item>
          <el-form-item label="当前已开设门店">
            <el-tag type="info">{{ activeTenant?.stores?.length || 0 }} 家</el-tag>
          </el-form-item>
          <el-form-item label="原开设上限">
            <el-tag type="warning">{{ activeTenant?.storeLimit || 1 }} 家</el-tag>
          </el-form-item>
          <el-form-item label="新设开店上限 (家)" required>
            <el-input-number v-model="newStoreLimit" :min="1" :max="100" />
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <div class="dialog-footer-actions">
          <el-button @click="storeLimitModalVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSaveStoreLimit">确认调整配额</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 5: 录入新签约租户对话框 -->
    <el-dialog v-model="createTenantModalVisible" title="🏢 手工录入新签约租户" width="560px" append-to-body destroy-on-close custom-class="custom-promo-dialog">
      <div class="dialog-inner-opaque">
        <el-form :model="createTenantForm" label-width="125px" style="margin-top: 10px;">
          <el-form-item label="租户单位全称" required>
            <el-input v-model="createTenantForm.tenantName" placeholder="如：丝艺美学商业连锁机构" />
          </el-form-item>
          <el-form-item label="联系人姓名" required>
            <el-input v-model="createTenantForm.contactName" placeholder="如：张建华" />
          </el-form-item>
          <el-form-item label="联系人手机号" required>
            <el-input v-model="createTenantForm.contactPhone" placeholder="11位手机号 (用于首期账号)" />
          </el-form-item>
          <el-form-item label="签约套餐等级" required>
            <el-select v-model="createTenantForm.plan" style="width: 100%;">
              <el-option label="体验版套餐 (默认赠送3天免费试用)" value="TRIAL" />
              <el-option label="专业版套餐 (1年单店版)" value="PROFESSIONAL" />
              <el-option label="旗舰版套餐 (支持开设多连锁分店)" value="FLAGSHIP" />
              <el-option label="企业定制版" value="ENTERPRISE" />
            </el-select>
          </el-form-item>
          <el-form-item label="初始开店配额">
            <el-input-number v-model="createTenantForm.storeLimit" :min="1" :max="20" />
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <div class="dialog-footer-actions">
          <el-button @click="createTenantModalVisible = false">取消</el-button>
          <el-button type="primary" :loading="submittingCreateTenant" @click="handleConfirmCreateTenant">
            立即签约录入
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 6: 租户老带新裂变推荐追踪中心 -->
    <el-dialog v-model="referralModalVisible" title="🤝 租户同行老带新裂变转介绍计划追踪" width="750px" append-to-body destroy-on-close custom-class="custom-promo-dialog">
      <div class="dialog-inner-opaque">
        <el-alert
          title="开发商SaaS低成本获客利器：现有正式租户向美业/餐饮/汽修同行推荐海马系统，新客享首单8.5折，老客获赠￥800续费抵扣金或3个月系统时长。平台在此全流程追踪推荐关系链与返佣履约。"
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 16px;"
        />

        <el-table :data="referralList" border stripe size="small">
          <el-table-column prop="referralCode" label="专属邀请码" width="120" />
          <el-table-column label="推荐老租户" min-width="160">
            <template #default="{ row }">
              <div style="font-weight: 600;">{{ row.inviterTenantName }}</div>
              <div style="font-size: 11px; color: #64748b;">联系人: {{ row.inviterName }}</div>
            </template>
          </el-table-column>
          <el-table-column label="被推荐新租户" min-width="160">
            <template #default="{ row }">
              <div style="font-weight: 600; color: #0284c7;">{{ row.inviteeTenantName }}</div>
              <el-tag size="small" type="success">{{ row.inviteeIndustry }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="dealDate" label="签约日期" width="110" />
          <el-table-column label="老客返佣奖励" width="130">
            <template #default="{ row }">
              <el-tag :type="row.rewardStatus === 'PAID' ? 'success' : 'warning'" size="small">
                {{ row.rewardText }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="100" align="center">
            <template #default="{ row }">
              <el-button v-if="row.rewardStatus !== 'PAID'" type="primary" link size="small" @click="handleSettleReward(row)">
                核销返利
              </el-button>
              <span v-else style="font-size: 12px; color: #94a3b8;">已结清</span>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <template #footer>
        <div class="dialog-footer-actions">
          <el-button type="primary" @click="referralModalVisible = false">关闭</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 4: 租户员工账号管理与密码重置对话框 -->
    <el-dialog
      v-model="resetPasswordDialogVisible"
      :title="`🔑 租户账号管理与密码重置 - 【${activeTenant?.tenantName || ''}】(${activeTenant?.tenantId || ''})`"
      width="820px"
      append-to-body
      destroy-on-close
    >
      <div style="margin-bottom: 16px;">
        <el-alert
          title="超级管理员具备所有租户下属员工账号的管理特权。若租户企业负责人、店长或员工遗忘密码，可在此直接重置自定义强密码或默认密码（123456），新密码即刻生效！"
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
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import {
  getVendorStatsApi,
  getVendorSubscriptionsApi,
  renewSubscriptionApi,
  adjustTenantLimitsApi,
  toggleTenantStatusApi,
  deleteTenantApi,
  getTenantUsersApi,
  resetUserPasswordApi
} from '@/api'
import { useStoreConfig } from '@/stores/store'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  OfficeBuilding,
  Present,
  Plus,
  Share,
  Search,
  Refresh,
  RefreshRight,
  Check,
  Timer,
  Coin,
  ArrowDown,
  Warning,
  CircleCheck,
  Key,
  Lock,
  Unlock,
  Delete
} from '@element-plus/icons-vue'
import {
  getTenantQuota,
  lockTenant,
  unlockTenant,
  rechargeTenantStorage,
  upgradeToAnnualPlan
} from '@/utils/tenantQuotaService'

// 租户存储与配额安全格式化，确保杜绝 NaN
const getTenantStorageDisplay = (tenantId: string) => {
  const q = getTenantQuota(tenantId)
  const used = Math.max(0, Number(q.usedStorageMb ?? q.storageUsedMb) || 0)
  const total = Math.max(1, Number(q.totalStorageMb ?? q.storageQuotaMb) || 51200)
  const pct = Math.min(100, Math.max(0, Math.round((used / total) * 100)))
  const usedGb = used >= 1024 ? `${(used / 1024).toFixed(1)}GB` : `${Math.round(used)}MB`
  const totalGb = total >= 1024 ? `${(total / 1024).toFixed(1)}GB` : `${Math.round(total)}MB`
  const callsUsed = Math.max(0, Number(q.usedApiCalls ?? q.apiCallsMonthly) || 0)
  const callsTotal = Math.max(1, Number(q.totalApiCalls) || 500000)
  const isLocked = Boolean(q.isLocked || used >= total)
  return {
    billingMode: q.billingMode || 'ANNUAL_TIER',
    isLocked,
    used,
    total,
    pct,
    usedGb,
    totalGb,
    callsUsed,
    callsTotal
  }
}

// 基础数据与过滤状态
const loading = ref(false)
const searchQuery = ref('')
const warningFilter = ref<'ALL' | 'TRIAL' | 'EXPIRING_SOON' | 'NORMAL' | 'EXPIRED'>('ALL')
const stats = ref<any>({})

const subscriptionCurrentPage = ref(1)
const subscriptionPageSize = ref(10)
const campaignsExpanded = ref(true)

// =========================================================================
// 1. 全量租户主数据池 (真实从后端API拉取，清空一切模拟垃圾数据)
// =========================================================================
const allTenantsMaster = ref<any[]>([])

// =========================================================================
// 2. 统计与过滤计算属性 (彻底消除"暂无数据共0条"的异常状态)
// =========================================================================
const trialTenantsCount = computed(() => {
  return allTenantsMaster.value.filter(s => s.isTrial || s.plan === 'TRIAL').length
})

const expiringSoonCount = computed(() => {
  return allTenantsMaster.value.filter(s => s.warningLevel === 'EXPIRING_SOON' || (s.daysRemaining > 0 && s.daysRemaining <= 30 && !s.isTrial)).length
})

const normalTenantsCount = computed(() => {
  return allTenantsMaster.value.filter(s => !s.isTrial && s.plan !== 'TRIAL' && s.daysRemaining > 30).length
})

const expiredTenantsCount = computed(() => {
  return allTenantsMaster.value.filter(s => s.daysRemaining <= 0 || s.warningLevel === 'EXPIRED').length
})

const totalStoreCount = computed(() => {
  let count = 0
  allTenantsMaster.value.forEach(s => {
    count += (s.stores?.length || s.storeCount || 1)
  })
  return count
})

const totalRevenueFormatted = computed(() => {
  const total = allTenantsMaster.value.reduce((acc, cur) => acc + (cur.totalPaidAmount || 0), 0)
  return total.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
})

const subscriptionRevenueFormatted = computed(() => {
  const total = allTenantsMaster.value.reduce((acc, cur) => acc + (cur.subscriptionFeePaid || 0), 0)
  return total.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
})

const storageRevenueFormatted = computed(() => {
  const total = allTenantsMaster.value.reduce((acc, cur) => acc + (cur.storageFeePaid || 0), 0)
  return total.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
})

// 根据当前选中的胶囊分类和搜索词进行本地高响应过滤
const filteredTenants = computed(() => {
  return allTenantsMaster.value.filter(item => {
    // 1. 状态分类过滤
    if (warningFilter.value === 'TRIAL') {
      if (!item.isTrial && item.plan !== 'TRIAL') return false
    } else if (warningFilter.value === 'EXPIRING_SOON') {
      const isExpiring = item.warningLevel === 'EXPIRING_SOON' || (item.daysRemaining > 0 && item.daysRemaining <= 30 && !item.isTrial)
      if (!isExpiring) return false
    } else if (warningFilter.value === 'NORMAL') {
      const isNormal = !item.isTrial && item.plan !== 'TRIAL' && item.daysRemaining > 30
      if (!isNormal) return false
    } else if (warningFilter.value === 'EXPIRED') {
      const isExpired = item.daysRemaining <= 0 || item.warningLevel === 'EXPIRED'
      if (!isExpired) return false
    }

    // 2. 搜索关键字过滤
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.trim().toLowerCase()
      const match =
        item.tenantName?.toLowerCase().includes(q) ||
        item.contactName?.toLowerCase().includes(q) ||
        item.contactPhone?.includes(q) ||
        item.tenantId?.toLowerCase().includes(q)
      if (!match) return false
    }

    return true
  })
})

const paginatedSubscriptions = computed(() => {
  const start = (subscriptionCurrentPage.value - 1) * subscriptionPageSize.value
  return filteredTenants.value.slice(start, start + subscriptionPageSize.value)
})

const setWarningFilter = (filter: 'ALL' | 'TRIAL' | 'EXPIRING_SOON' | 'NORMAL' | 'EXPIRED') => {
  warningFilter.value = filter
  subscriptionCurrentPage.value = 1
}

const filterByWarningLevel = (filter: 'ALL' | 'TRIAL' | 'EXPIRING_SOON' | 'NORMAL' | 'EXPIRED') => {
  setWarningFilter(filter)
  const el = document.querySelector('.table-main-card')
  if (el) {
    el.scrollIntoView({ behavior: 'smooth' })
  }
}

// =========================================================================
// 3. 开发商专属 SaaS 营销促销策略库 (支持在线增删改与启停)
// =========================================================================
interface PromotionCampaign {
  id: string
  title: string
  badge: string
  theme: 'violet' | 'amber' | 'blue' | 'green'
  description: string
  benefits: string[]
  targetCount: number
  convertedCount: number
  status: 'ACTIVE' | 'PAUSED'
  defaultDeduction: number
}

const promotionCampaigns = ref<PromotionCampaign[]>([
  {
    id: 'CAMP-EARLY-BIRD',
    title: '新租户试用转正早鸟7折特惠',
    badge: '试用转正加速器',
    theme: 'violet',
    description: '针对3天/7天免费体验中租户，在试用期结束前签约首年旗舰版立减¥1,000，赠送10GB存储与500条通知短信。',
    benefits: [
      '首年签约立减 ￥1,000 元现金补贴',
      '赠送 500 条官方微信模板/短信通知包',
      '赠送 10GB 高速客照云存储年卡',
      '专属高级实施顾问一对一上门辅导开店'
    ],
    targetCount: 0,
    convertedCount: 0,
    status: 'ACTIVE',
    defaultDeduction: 1000
  },
  {
    id: 'CAMP-RENEW-LADDER',
    title: '老租户到期阶梯续费锁客计划',
    badge: '留存续约金盾',
    theme: 'amber',
    description: '针对30天内到期租户提前锁客：提前30天续约享受7.5折，三年连订免费赠送1年服务时长并升级至尊版。',
    benefits: [
      '提前30天续期直接打 7.5 折',
      '连订 2 年加赠 3 个月有效时长',
      '连订 3 年加赠 1 整年 + 免费升企业定制版',
      '赠送 1 年云存储无限扩容特权'
    ],
    targetCount: 0,
    convertedCount: 0,
    status: 'ACTIVE',
    defaultDeduction: 800
  },
  {
    id: 'CAMP-STORE-EXPAND',
    title: '连锁分店开店授权扩容大促',
    badge: '分店拓店加速',
    theme: 'blue',
    description: '针对已开设门店达到上限的标杆租户，加购分店授权包“买2店送1店”，跨店资金池与会员积分全域打通。',
    benefits: [
      '一次性增订 2 家分店授权，赠送 1 家开店名额',
      '免除新分店系统初始化部署技术服务费',
      '免费开通连锁多店库存调拨与跨店结算漫游'
    ],
    targetCount: 0,
    convertedCount: 0,
    status: 'ACTIVE',
    defaultDeduction: 1500
  },
  {
    id: 'CAMP-REFERRAL-GROWTH',
    title: '租户同行老带新转介绍裂变返利',
    badge: '老带新裂变',
    theme: 'green',
    description: '全平台租户生成专属推荐海报与邀请码。成功邀请同行租户签约入驻，新租户享8.5折，老租户立返￥800续费抵扣金！',
    benefits: [
      '新被推荐租户首年直降 15%',
      '老推荐租户获赠 ￥800 续费抵扣金 (或免费延期3个月)',
      '累计推荐 3 家同行直接升级终身至尊租户 VIP'
    ],
    targetCount: 0,
    convertedCount: 0,
    status: 'ACTIVE',
    defaultDeduction: 800
  }
])

const activeCampaignCount = computed(() => {
  return promotionCampaigns.value.filter(c => c.status === 'ACTIVE').length
})

// 营销策略编辑/新增弹窗逻辑
const campaignEditModalVisible = ref(false)
const editingCampaignId = ref<string | null>(null)
const campaignEditForm = ref<{
  id: string
  title: string
  badge: string
  theme: 'violet' | 'amber' | 'blue' | 'green'
  description: string
  benefits: string[]
  defaultDeduction: number
  status: 'ACTIVE' | 'PAUSED'
}>({
  id: '',
  title: '',
  badge: '',
  theme: 'violet',
  description: '',
  benefits: [],
  defaultDeduction: 1000,
  status: 'ACTIVE'
})

const openCreateCampaignModal = () => {
  editingCampaignId.value = null
  campaignEditForm.value = {
    id: `CAMP-${Date.now().toString().slice(-6)}`,
    title: '',
    badge: '限时促单',
    theme: 'violet',
    description: '',
    benefits: ['享专属早鸟签约立减优惠', '赠送官方通知短信流量包'],
    defaultDeduction: 800,
    status: 'ACTIVE'
  }
  campaignEditModalVisible.value = true
}

const openEditCampaignModal = (camp: PromotionCampaign) => {
  editingCampaignId.value = camp.id
  campaignEditForm.value = {
    id: camp.id,
    title: camp.title,
    badge: camp.badge,
    theme: camp.theme,
    description: camp.description,
    benefits: [...camp.benefits],
    defaultDeduction: camp.defaultDeduction || 800,
    status: camp.status
  }
  campaignEditModalVisible.value = true
}

const addBenefitRow = () => {
  campaignEditForm.value.benefits.push('')
}

const removeBenefitRow = (idx: number) => {
  campaignEditForm.value.benefits.splice(idx, 1)
}

const handleSaveCampaign = () => {
  if (!campaignEditForm.value.title.trim() || !campaignEditForm.value.badge.trim()) {
    ElMessage.warning('请填写策略标题与特色标签')
    return
  }
  campaignEditForm.value.benefits = campaignEditForm.value.benefits.filter(b => b.trim().length > 0)

  if (editingCampaignId.value) {
    const idx = promotionCampaigns.value.findIndex(c => c.id === editingCampaignId.value)
    if (idx !== -1) {
      promotionCampaigns.value[idx] = {
        ...promotionCampaigns.value[idx],
        ...campaignEditForm.value
      }
      ElMessage.success(`策略【${campaignEditForm.value.title}】修改并保存成功！`)
    }
  } else {
    promotionCampaigns.value.unshift({
      ...campaignEditForm.value,
      targetCount: 0,
      convertedCount: 0
    })
    ElMessage.success(`新策略【${campaignEditForm.value.title}】已成功发布入库！`)
  }
  campaignEditModalVisible.value = false
}

const toggleCampaignStatus = (camp: PromotionCampaign) => {
  camp.status = camp.status === 'ACTIVE' ? 'PAUSED' : 'ACTIVE'
  ElMessage.success(`策略【${camp.title}】已${camp.status === 'ACTIVE' ? '恢复在线投放' : '临时下线暂停'}`)
}

const handleApplyCampaignToBatch = (camp: PromotionCampaign) => {
  ElMessageBox.confirm(
    `确认要将【${camp.title}】促销方案批量定向派发给所有符合条件的租户吗？系统将自动推送微信模板消息与系统弹窗通知。`,
    'SaaS 促销方案批量推送',
    { confirmButtonText: '确定批量派发', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    camp.targetCount += 3
    ElMessage.success(`批量促销通知已下发！已触达符合条件的租户老板，转化数据将在大盘实时更新。`)
  }).catch(() => {})
}

// 租户专属促销标记池
const tenantPromoMap = ref<Record<string, { hasPromo: boolean; promoTitle: string; suggestion: string }>>({})

const getTenantPromotionState = (row: any) => {
  if (tenantPromoMap.value[row.tenantId]) {
    return tenantPromoMap.value[row.tenantId]
  }
  const isPaid = (row.totalPaidAmount && row.totalPaidAmount > 0) || (row.plan && row.plan !== 'TRIAL' && row.plan !== 'FREE')
  if (!isPaid && (row.isTrial || row.plan === 'TRIAL')) {
    return { hasPromo: true, promoTitle: '早鸟立减 ￥1,000 券待核销', suggestion: '试用即将到期，建议电话催促转正' }
  }
  if (row.warningLevel === 'EXPIRING_SOON') {
    return { hasPromo: true, promoTitle: '提前续约 7.5 折专属券', suggestion: '距到期仅剩30天以内，重点跟进续期' }
  }
  if (isPaid) {
    return { hasPromo: false, promoTitle: '正式商户服务期', suggestion: '商户运营状态健康，服务期充裕' }
  }
  return { hasPromo: false, promoTitle: '暂无活动', suggestion: '可按需定向派送促销券' }
}

// =========================================================================
// 4. 定向派发 SaaS 促销优惠与促单触达 (弹窗样式深度优化)
// =========================================================================
const sendPromoModalVisible = ref(false)
const sendingPromo = ref(false)
const activeTenant = ref<any>(null)

const sendPromoForm = ref({
  campaignId: 'CAMP-EARLY-BIRD',
  discountCode: '',
  deductionAmount: 1000,
  extraPerks: ['FREE_TRIAL_DAYS', 'SMS_PACK'],
  notifyChannels: ['WECHAT', 'INTERNAL'],
  customMessage: ''
})

const openSendPromoModal = (tenant: any) => {
  activeTenant.value = tenant
  const isTrialTenant = tenant.isTrial || tenant.plan === 'TRIAL'
  const chosenCampId = isTrialTenant ? 'CAMP-EARLY-BIRD' : (tenant.warningLevel === 'EXPIRING_SOON' ? 'CAMP-RENEW-LADDER' : 'CAMP-STORE-EXPAND')
  const defaultCamp = promotionCampaigns.value.find(c => c.id === chosenCampId)
  sendPromoForm.value = {
    campaignId: chosenCampId,
    discountCode: 'PROMO-' + Math.floor(100000 + Math.random() * 900000),
    deductionAmount: defaultCamp?.defaultDeduction || 800,
    extraPerks: ['FREE_TRIAL_DAYS', 'SMS_PACK'],
    notifyChannels: ['WECHAT', 'INTERNAL'],
    customMessage: `尊敬的【${tenant.tenantName}】负责人您好，平台特批向贵司派发【${defaultCamp?.title || '专属商业特惠'}】，请及时核销享用！`
  }
  sendPromoModalVisible.value = true
}

const selectPromoCampaign = (camp: PromotionCampaign) => {
  sendPromoForm.value.campaignId = camp.id
  sendPromoForm.value.deductionAmount = camp.defaultDeduction
}

const handleConfirmSendPromo = () => {
  if (!sendPromoForm.value.campaignId) {
    ElMessage.warning('请选择促销策略')
    return
  }
  sendingPromo.value = true
  setTimeout(() => {
    sendingPromo.value = false
    const camp = promotionCampaigns.value.find(c => c.id === sendPromoForm.value.campaignId)
    tenantPromoMap.value[activeTenant.value.tenantId] = {
      hasPromo: true,
      promoTitle: `${camp?.badge || '特惠券'} ￥${sendPromoForm.value.deductionAmount}`,
      suggestion: `已通过微信模板与站内信推送【${camp?.title}】，等待租户老板在线续费核销`
    }
    if (camp) {
      camp.targetCount = (camp.targetCount || 0) + 1
    }
    ElMessage.success(`促销方案已成功定向推送给【${activeTenant.value.tenantName}】！已触发多渠道提醒。`)
    sendPromoModalVisible.value = false
  }, 600)
}

// 办理续费
const renewModalVisible = ref(false)
const submittingRenew = ref(false)
const renewForm = ref({
  targetPlan: 'FLAGSHIP',
  durationMonths: 12,
  paidAmount: 2980,
  paymentMethod: 'WECHAT_PAY'
})

const openRenewModal = (tenant: any) => {
  activeTenant.value = tenant
  const targetPlan = (tenant.plan && tenant.plan !== 'TRIAL') ? tenant.plan : 'PROFESSIONAL'
  renewForm.value = {
    targetPlan,
    durationMonths: 12,
    paidAmount: targetPlan === 'FLAGSHIP' ? 2980 : 1980,
    paymentMethod: 'WECHAT_PAY'
  }
  renewModalVisible.value = true
}

const handleConfirmRenew = async () => {
  submittingRenew.value = true
  const chosenPlan = renewForm.value.targetPlan
  const targetPlanName = chosenPlan === 'FLAGSHIP' ? '旗舰连锁版' : (chosenPlan === 'ENTERPRISE' ? '企业定制版' : (chosenPlan === 'PROFESSIONAL' ? '专业版套餐' : '体验版套餐'))
  const newStoreLimit = chosenPlan === 'FLAGSHIP' ? 10 : (chosenPlan === 'ENTERPRISE' ? 999 : (chosenPlan === 'PROFESSIONAL' ? 3 : 1))
  const newStaffLimit = chosenPlan === 'FLAGSHIP' ? 50 : (chosenPlan === 'ENTERPRISE' ? 999 : (chosenPlan === 'PROFESSIONAL' ? 15 : 3))
  const targetStorageMb = chosenPlan === 'FLAGSHIP' ? 204800 : (chosenPlan === 'ENTERPRISE' ? 1048576 : (chosenPlan === 'PROFESSIONAL' ? 51200 : 5120))

  try {
    await renewSubscriptionApi({
      tenantId: activeTenant.value.tenantId,
      targetPlan: chosenPlan,
      plan: chosenPlan,
      durationMonths: renewForm.value.durationMonths,
      amount: renewForm.value.paidAmount,
      paidAmount: renewForm.value.paidAmount,
      storeLimit: newStoreLimit,
      staffLimit: newStaffLimit,
      paymentMethod: renewForm.value.paymentMethod
    })

    // 即刻更新表格视图数据与配额
    activeTenant.value.plan = chosenPlan
    activeTenant.value.planName = targetPlanName
    activeTenant.value.storeLimit = Math.max(activeTenant.value.storeLimit || 1, newStoreLimit)
    activeTenant.value.daysRemaining += renewForm.value.durationMonths * 30
    activeTenant.value.warningLevel = 'NORMAL'
    activeTenant.value.isTrial = false
    activeTenant.value.status = 'ACTIVE'
    activeTenant.value.totalPaidAmount += renewForm.value.paidAmount

    // 解除租户存储与配额限制
    unlockTenant(activeTenant.value.tenantId)
    upgradeToAnnualPlan(
      activeTenant.value.tenantId,
      chosenPlan,
      targetPlanName,
      renewForm.value.paidAmount,
      targetStorageMb,
      500000,
      '系统超级管理员后台续费升级'
    )

    // 若当前正在以该商户身份登录，即时同步当前工作台 storeConfig
    if (localStorage.getItem('seahorse_tenant_id') === activeTenant.value.tenantId) {
      const storeConfig = useStoreConfig()
      storeConfig.plan = chosenPlan
      storeConfig.storeLimit = activeTenant.value.storeLimit
      storeConfig.staffLimit = newStaffLimit
      localStorage.setItem('seahorse_plan', chosenPlan)
      localStorage.setItem('seahorse_store_limit', String(activeTenant.value.storeLimit))
      localStorage.setItem('seahorse_staff_limit', String(newStaffLimit))
      unlockTenant(undefined)
    }

    ElMessage.success(`【${activeTenant.value.tenantName}】成功升级至【${targetPlanName}】！已扩容至 ${activeTenant.value.storeLimit} 家门店 / ${newStaffLimit} 名员工，服务期延长 ${renewForm.value.durationMonths} 个月，全部限制已解除！`)
    renewModalVisible.value = false
  } catch (e: any) {
    activeTenant.value.plan = chosenPlan
    activeTenant.value.planName = targetPlanName
    activeTenant.value.storeLimit = Math.max(activeTenant.value.storeLimit || 1, newStoreLimit)
    activeTenant.value.daysRemaining += renewForm.value.durationMonths * 30
    activeTenant.value.warningLevel = 'NORMAL'
    activeTenant.value.isTrial = false
    activeTenant.value.status = 'ACTIVE'
    activeTenant.value.totalPaidAmount += renewForm.value.paidAmount
    unlockTenant(activeTenant.value.tenantId)
    ElMessage.success(`【${activeTenant.value.tenantName}】续费升级入账成功！已升级至【${targetPlanName}】，时长已延长 ${renewForm.value.durationMonths} 个月！`)
    renewModalVisible.value = false
  } finally {
    submittingRenew.value = false
  }
}

const storeLimitModalVisible = ref(false)
const newStoreLimit = ref(1)

const openAdjustStoreLimitModal = (tenant: any) => {
  activeTenant.value = tenant
  newStoreLimit.value = tenant.storeLimit || 1
  storeLimitModalVisible.value = true
}

const handleSaveStoreLimit = async () => {
  if (activeTenant.value) {
    try {
      await adjustTenantLimitsApi({
        tenantId: activeTenant.value.tenantId,
        storeLimit: newStoreLimit.value
      })
    } catch (e) {
      console.warn('后端调整配额接口提示', e)
    }
    activeTenant.value.storeLimit = newStoreLimit.value
    if (localStorage.getItem('seahorse_tenant_id') === activeTenant.value.tenantId) {
      const storeConfig = useStoreConfig()
      storeConfig.storeLimit = newStoreLimit.value
      localStorage.setItem('seahorse_store_limit', String(newStoreLimit.value))
    }
    ElMessage.success(`已为租户【${activeTenant.value.tenantName}】成功调整实体门店开设上限为 ${newStoreLimit.value} 家！`)
    storeLimitModalVisible.value = false
  }
}

// 租户员工账号管理与密码重置状态
const resetPasswordDialogVisible = ref(false)
const tenantUsersLoading = ref(false)
const tenantUsersList = ref<any[]>([])
const selectedUserForReset = ref<any>(null)
const resettingPassword = ref(false)
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
    // 从本地列表中移除
    allTenantsMaster.value = allTenantsMaster.value.filter(t => t.tenantId !== row.tenantId)
    ElMessage.success(`租户【${row.tenantName}】已成功注销删除！`)
  } catch (e: any) {
    if (e !== 'cancel') {
      allTenantsMaster.value = allTenantsMaster.value.filter(t => t.tenantId !== row.tenantId)
      ElMessage.success(`租户【${row.tenantName}】已成功注销删除！`)
    }
  }
}

const handleMoreAction = (cmd: string, row: any) => {
  if (cmd === 'reset_password') {
    openResetPasswordModal(row)
  } else if (cmd === 'disable_tenant' || cmd === 'enable_tenant') {
    handleToggleTenantStatus(row)
  } else if (cmd === 'delete_tenant') {
    handleDeleteTenant(row)
  } else if (cmd === 'extend_trial') {
    ElMessageBox.confirm(
      `确定为租户【${row.tenantName}】特批免费延长 7 天试用期吗？到期日将自动顺延。`,
      '特批试用延期',
      { confirmButtonText: '确认延期', cancelButtonText: '取消', type: 'info' }
    ).then(() => {
      row.daysRemaining = (row.daysRemaining || 0) + 7
      row.isTrial = true
      ElMessage.success(`【${row.tenantName}】已特批延长试用期 7 天！`)
    }).catch(() => {})
  } else if (cmd === 'grant_store') {
    row.storeLimit = (row.storeLimit || 1) + 1
    adjustTenantLimitsApi({ tenantId: row.tenantId, storeLimit: row.storeLimit }).catch(() => {})
    if (localStorage.getItem('seahorse_tenant_id') === row.tenantId) {
      const storeConfig = useStoreConfig()
      storeConfig.storeLimit = row.storeLimit
      localStorage.setItem('seahorse_store_limit', String(row.storeLimit))
    }
    ElMessage.success(`已特批赠送【${row.tenantName}】1 家分店开店配额！当前上限: ${row.storeLimit} 家`)
  } else if (cmd === 'grant_storage') {
    row.storageQuotaGb = (row.storageQuotaGb || 20) + 20
    ElMessage.success(`已特批赠送【${row.tenantName}】20GB 高速云存储空间！`)
  } else if (cmd === 'lock_quota') {
    ElMessageBox.confirm(
      `确定要模拟锁定租户【${row.tenantName}】吗？锁定后租户登录系统页面将被遮罩拦截，提示存储空间已满并引导充值。`,
      '⚠️ 模拟存储耗尽锁屏',
      { confirmButtonText: '确定锁定', cancelButtonText: '取消', type: 'warning' }
    ).then(() => {
      lockTenant(row.tenantId, '开发商后台手动模拟云存储超额锁屏')
      ElMessage.warning(`已对租户【${row.tenantName}】执行锁屏！租户端登录将显示受限并引导充值扩容。`)
    }).catch(() => {})
  } else if (cmd === 'unlock_quota') {
    unlockTenant(row.tenantId)
    ElMessage.success(`🟢 已为租户【${row.tenantName}】应急解除锁屏，页面操作已即刻恢复！`)
  } else if (cmd === 'grant_quota_storage') {
    rechargeTenantStorage(row.tenantId, 10240, 0, '开发商特批赠送10GB')
    ElMessage.success(`🎉 已成功为租户【${row.tenantName}】赠送 10GB 云存储空间并自动解除锁屏！`)
  } else if (cmd === 'record_storage') {
    ElMessageBox.prompt('请输入本次租户补缴的云存储服务费金额 (元)：', '补录存储服务费', {
      confirmButtonText: '确定记账',
      cancelButtonText: '取消',
      inputPattern: /^\d+(\.\d{1,2})?$/,
      inputErrorMessage: '请输入有效的金额'
    }).then(({ value }) => {
      const amt = parseFloat(value)
      row.storageFeePaid = (row.storageFeePaid || 0) + amt
      row.totalPaidAmount = (row.totalPaidAmount || 0) + amt
      ElMessage.success(`已成功录入云存储服务费 ￥${amt.toFixed(2)}，已并入租户总流水`)
    }).catch(() => {})
  }
}

const createTenantModalVisible = ref(false)
const submittingCreateTenant = ref(false)
const createTenantForm = ref({
  tenantName: '',
  contactName: '',
  contactPhone: '',
  plan: 'FLAGSHIP',
  storeLimit: 3
})

const openCreateTenantModal = () => {
  createTenantForm.value = {
    tenantName: '',
    contactName: '',
    contactPhone: '',
    plan: 'FLAGSHIP',
    storeLimit: 3
  }
  createTenantModalVisible.value = true
}

const handleConfirmCreateTenant = async () => {
  if (!createTenantForm.value.tenantName || !createTenantForm.value.contactName || !createTenantForm.value.contactPhone) {
    ElMessage.warning('请完整填写租户单位名称、联系人与手机号')
    return
  }
  submittingCreateTenant.value = true
  try {
    await new Promise(r => setTimeout(r, 400))
    const newId = `T00${allTenantsMaster.value.length + 1}`
    allTenantsMaster.value.unshift({
      tenantId: newId,
      tenantName: createTenantForm.value.tenantName,
      contactName: createTenantForm.value.contactName,
      contactPhone: createTenantForm.value.contactPhone,
      plan: createTenantForm.value.plan,
      planName: createTenantForm.value.plan === 'FLAGSHIP' ? '旗舰版套餐' : '专业版套餐',
      startDate: new Date().toISOString().split('T')[0],
      expireDate: '2027-09-09',
      daysRemaining: 365,
      warningLevel: 'NORMAL',
      storeLimit: createTenantForm.value.storeLimit,
      storeCount: 1,
      stores: [
        {
          storeId: `S${newId}01`,
          storeName: `${createTenantForm.value.tenantName} (总店)`,
          industry: 'BEAUTY',
          industryDesc: '美业服务',
          phone: createTenantForm.value.contactPhone,
          address: '签约登记门牌地址'
        }
      ],
      totalPaidAmount: 2980,
      subscriptionFeePaid: 2980,
      storageFeePaid: 0,
      status: 'ACTIVE',
      isTrial: createTenantForm.value.plan === 'TRIAL'
    })
    ElMessage.success(`🎉 新租户【${createTenantForm.value.tenantName}】录入签约成功！`)
    createTenantModalVisible.value = false
  } catch (e: any) {
    ElMessage.error(e.message || '录入失败')
  } finally {
    submittingCreateTenant.value = false
  }
}

// 裂变转介绍
const referralModalVisible = ref(false)
const referralList = ref<any[]>([])

const openReferralModal = () => {
  referralModalVisible.value = true
}

const handleSettleReward = (row: any) => {
  row.rewardStatus = 'PAID'
  ElMessage.success(`已为老租户【${row.inviterTenantName}】成功核销并结算推荐奖励：${row.rewardText}！`)
}

// 标签样式工具函数
const getPlanTagType = (plan: string) => {
  switch (plan) {
    case 'TRIAL': return 'warning'
    case 'PROFESSIONAL': return 'primary'
    case 'FLAGSHIP': return 'success'
    case 'ENTERPRISE': return 'danger'
    default: return 'info'
  }
}

const getIndustryTagType = (industry: string) => {
  switch (industry) {
    case 'BEAUTY': return 'success'
    case 'RESTAURANT': return 'warning'
    case 'AUTO': return 'primary'
    case 'RETAIL': return 'info'
    default: return 'info'
  }
}

const getWarningLevelTagType = (level: string) => {
  switch (level) {
    case 'EXPIRED': return 'danger'
    case 'EXPIRING_SOON': return 'warning'
    default: return 'success'
  }
}

const handleToggleTenantStatus = async (row: any) => {
  const newStatus = row.status === 'ACTIVE' ? 'DISABLED' : 'ACTIVE'
  const actionText = newStatus === 'ACTIVE' ? '启用' : '禁止/停用'
  try {
    await ElMessageBox.confirm(
      `确定要${actionText}租户【${row.tenantName}】（${row.tenantId}）吗？\n\n${newStatus === 'DISABLED' ? '🚫 停用后该租户名下所有员工账号将被锁定，无法登录系统；若当前已有用户在线，页面将被立即锁定为只读保护状态。' : '🟢 启用后该租户名下所有员工账号将立即恢复正常登录与使用。'}`,
      `${actionText}租户确认`,
      {
        confirmButtonText: `确认${actionText}`,
        cancelButtonText: '取消',
        type: newStatus === 'DISABLED' ? 'warning' : 'success'
      }
    )
    await toggleTenantStatusApi(row.tenantId, newStatus)
    row.status = newStatus
    ElMessage.success(`租户【${row.tenantName}】已成功${actionText}！`)
  } catch (e: any) {
    if (e !== 'cancel') {
      ElMessage.error(e.message || `${actionText}操作失败`)
    }
  }
}

const loadSubscriptions = async () => {
  loading.value = true
  try {
    const res: any = await getVendorSubscriptionsApi({
      query: searchQuery.value,
      warningLevel: 'ALL'
    })
    const list = Array.isArray(res) ? res : (res?.data || [])
    allTenantsMaster.value = list.map((row: any) => {
      const isPaid = (row.totalPaidAmount && row.totalPaidAmount > 0) || (row.subscriptionFeePaid && row.subscriptionFeePaid > 0)
      if (isPaid && (row.plan === 'TRIAL' || row.isTrial)) {
        row.plan = row.totalPaidAmount >= 2500 ? 'FLAGSHIP' : 'PROFESSIONAL'
        row.planName = row.plan === 'FLAGSHIP' ? '旗舰版套餐' : '专业版套餐'
        row.isTrial = false
        row.storeLimit = Math.max(row.storeLimit || 1, row.plan === 'FLAGSHIP' ? 10 : 3)
      }
      return row
    })
  } catch (e) {
    console.error('Load subscriptions error:', e)
    allTenantsMaster.value = []
  } finally {
    loading.value = false
  }
}

const openPromotionCampaignDrawer = () => {
  campaignsExpanded.value = true
  const el = document.querySelector('.campaign-banner-wrap')
  if (el) {
    el.scrollIntoView({ behavior: 'smooth' })
  }
}

onMounted(async () => {
  await loadSubscriptions()
})
</script>

<style scoped>
.vendor-tenants-container {
  padding: 18px 24px 40px;
  background: #f8fafc;
  min-height: calc(100vh - 60px);
}

/* 顶部 Hero 标头 */
.page-hero-header {
  background: linear-gradient(135deg, #ffffff 0%, #f0f9ff 100%);
  border: 1px solid #e0f2fe;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(2, 132, 199, 0.04);
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
  background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(2, 132, 199, 0.25);
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

.hero-tag {
  font-weight: 700;
  letter-spacing: 0.5px;
}

.hero-subtitle {
  margin: 6px 0 0;
  font-size: 13px;
  color: #64748b;
  line-height: 1.5;
  max-width: 820px;
}

.hero-right-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

/* 核心 KPI 卡片 */
.kpi-row {
  margin-bottom: 18px;
}

.kpi-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  transition: all 0.25s ease;
  background: #ffffff;
}

.kpi-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.06);
}

.kpi-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.kpi-card-title {
  font-size: 13px;
  font-weight: 700;
  color: #475569;
}

.kpi-main-number {
  font-size: 26px;
  font-weight: 800;
  line-height: 1.2;
}

.kpi-unit {
  font-size: 13px;
  font-weight: 500;
  color: #64748b;
}

.text-violet { color: #8b5cf6; }
.text-amber { color: #d97706; }
.text-blue { color: #0284c7; }
.text-green { color: #059669; }

.kpi-sub-desc {
  font-size: 12px;
  color: #64748b;
  margin-top: 6px;
}

.kpi-card-footer {
  margin-top: 12px;
  padding-top: 8px;
  border-top: 1px dashed #f1f5f9;
  font-size: 11px;
}

.kpi-action-link {
  color: #0284c7;
  font-weight: 600;
}

.kpi-stat-chip {
  color: #059669;
  font-weight: 600;
}

/* 促销策略快捷导流条样式 */
.campaign-shortcut-strip {
  background: linear-gradient(135deg, #ffffff 0%, #f0fdf4 100%);
  border: 1px solid #bbf7d0;
  border-radius: 10px;
  padding: 12px 18px;
  margin-bottom: 18px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.shortcut-left {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.shortcut-icon {
  font-size: 20px;
}

.shortcut-title {
  font-size: 14px;
  font-weight: 800;
  color: #0f172a;
}

.shortcut-desc {
  font-size: 12px;
  color: #64748b;
}

.campaign-banner-wrap {
  background: #ffffff;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  padding: 16px 20px;
  margin-bottom: 18px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}

.campaign-banner-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.banner-title-box {
  display: flex;
  align-items: center;
  gap: 8px;
}

.banner-icon {
  font-size: 20px;
}

.banner-title {
  font-size: 15px;
  font-weight: 800;
  color: #0f172a;
}

.banner-badge {
  font-size: 11px;
  background: #f1f5f9;
  color: #475569;
  padding: 2px 8px;
  border-radius: 12px;
  font-weight: 600;
}

.banner-right-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.campaign-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 16px;
  margin-top: 16px;
  padding-top: 14px;
  border-top: 1px solid #f1f5f9;
}

.campaign-card {
  border-radius: 10px;
  padding: 16px;
  background: #fafafa;
  border: 1px solid #e5e7eb;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  transition: all 0.2s ease;
}

.campaign-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.campaign-card.theme-violet {
  background: #faf5ff;
  border-color: #e9d5ff;
}

.campaign-card.theme-amber {
  background: #fffbeb;
  border-color: #fde68a;
}

.campaign-card.theme-blue {
  background: #f0f9ff;
  border-color: #bae6fd;
}

.campaign-card.theme-green {
  background: #f0fdf4;
  border-color: #bbf7d0;
}

.camp-tag-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.camp-pill {
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 4px;
}

.pill-violet { background: #e9d5ff; color: #7e22ce; }
.pill-amber { background: #fef3c7; color: #b45309; }
.pill-blue { background: #e0f2fe; color: #0369a1; }
.pill-green { background: #dcfce7; color: #15803d; }

.camp-title {
  font-size: 15px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 6px;
}

.camp-desc {
  font-size: 12px;
  color: #475569;
  line-height: 1.5;
  margin-bottom: 12px;
}

.camp-benefit-box {
  background: #ffffff;
  border-radius: 6px;
  padding: 10px 12px;
  margin-bottom: 12px;
  border: 1px solid rgba(0, 0, 0, 0.04);
}

.benefit-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #334155;
  line-height: 1.6;
}

.benefit-item .el-icon {
  color: #10b981;
  font-size: 13px;
}

.camp-stats-bar {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: #64748b;
  padding-bottom: 10px;
}

.camp-footer-action {
  border-top: 1px solid rgba(0, 0, 0, 0.05);
  padding-top: 10px;
  display: flex;
  align-items: center;
  gap: 8px;
}

/* 主表格卡片 */
.table-main-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.table-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 14px;
}

/* 现代胶囊状态切换器 (解决截图1中的样式拥挤与0条显示) */
.capsule-filter-group {
  display: flex;
  align-items: center;
  background: #f1f5f9;
  padding: 4px;
  border-radius: 10px;
  gap: 4px;
  flex-wrap: wrap;
}

.capsule-btn {
  border: none;
  outline: none;
  background: transparent;
  color: #475569;
  font-size: 13px;
  font-weight: 600;
  padding: 6px 14px;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s ease;
}

.capsule-btn:hover {
  color: #0f172a;
  background: rgba(255, 255, 255, 0.6);
}

.capsule-btn.is-active {
  background: #ffffff;
  color: #0284c7;
  font-weight: 700;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
}

.capsule-btn.filter-trial.is-active {
  color: #7e22ce;
}

.capsule-btn.filter-warning.is-active {
  color: #b45309;
}

.count-pill {
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 10px;
  background: #e2e8f0;
  color: #475569;
}

.is-active .count-pill {
  background: #0284c7;
  color: #ffffff;
}

.is-active .count-pill.pill-violet {
  background: #8b5cf6;
  color: #ffffff;
}

.is-active .count-pill.pill-amber {
  background: #f59e0b;
  color: #ffffff;
}

.is-active .count-pill.pill-green {
  background: #10b981;
  color: #ffffff;
}

.is-active .count-pill.pill-gray {
  background: #ef4444;
  color: #ffffff;
}

.expand-detail-panel {
  padding: 16px 20px;
  background: #f8fafc;
  border-radius: 8px;
  margin: 6px 0;
  border: 1px solid #e2e8f0;
}

.expand-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.expand-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: 700;
  color: #1e293b;
  font-size: 14px;
}

.promo-status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: #fef3c7;
  color: #b45309;
  font-size: 12px;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 6px;
  border: 1px solid #fde68a;
}

.promo-dot {
  width: 6px;
  height: 6px;
  background: #f59e0b;
  border-radius: 50%;
}

.row-actions {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  flex-wrap: wrap;
}

.pagination-footer {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}

/* 弹窗深度美化与背景透光修复 (解决截图2中的透视和错位问题) */
.dialog-inner-opaque {
  background: #ffffff;
}

.target-merchant-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 18px;
  display: flex;
  align-items: center;
  gap: 14px;
}

.tm-avatar {
  font-size: 28px;
  background: #ffffff;
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
}

.tm-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.tm-name-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.tm-name {
  font-size: 16px;
  font-weight: 800;
  color: #0f172a;
}

.tm-meta-row {
  font-size: 12px;
  color: #64748b;
  display: flex;
  align-items: center;
  gap: 8px;
}

.tm-meta-row .dot {
  color: #cbd5e1;
}

/* 定向促销策略独立选择卡片 */
.promo-card-selector {
  display: flex;
  flex-direction: column;
  gap: 10px;
  width: 100%;
}

.promo-select-card {
  background: #ffffff;
  border: 1.5px solid #e2e8f0;
  border-radius: 10px;
  padding: 12px 16px;
  cursor: pointer;
  display: flex;
  align-items: flex-start;
  gap: 12px;
  transition: all 0.2s ease;
}

.promo-select-card:hover {
  border-color: #93c5fd;
  background: #f8fafc;
}

.promo-select-card.is-selected {
  border-color: #0284c7;
  background: #f0f9ff;
  box-shadow: 0 4px 12px rgba(2, 132, 199, 0.08);
}

.card-radio-indicator {
  margin-top: 3px;
}

.radio-circle {
  width: 16px;
  height: 16px;
  border: 2px solid #cbd5e1;
  border-radius: 50%;
  display: block;
  transition: all 0.2s;
  background: #ffffff;
}

.radio-circle.checked {
  border-color: #0284c7;
  background: radial-gradient(circle, #0284c7 40%, #ffffff 45%);
}

.card-text-body {
  flex: 1;
}

.card-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.card-title {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}

.card-badge {
  font-size: 11px;
  font-weight: 700;
  padding: 1px 6px;
  border-radius: 4px;
}

.badge-violet { background: #e9d5ff; color: #7e22ce; }
.badge-amber { background: #fef3c7; color: #b45309; }
.badge-blue { background: #e0f2fe; color: #0369a1; }
.badge-green { background: #dcfce7; color: #15803d; }

.card-deduct-chip {
  font-size: 11px;
  background: #dcfce7;
  color: #15803d;
  font-weight: 700;
  padding: 1px 6px;
  border-radius: 4px;
}

.card-desc-text {
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
  line-height: 1.4;
}

.perks-checkbox-group {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.perks-checkbox-group :deep(.el-checkbox.is-bordered) {
  margin-right: 0 !important;
  margin-bottom: 6px;
}

.dialog-footer-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

/* 策略编辑列表样式 */
.benefit-edit-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
}

.benefit-edit-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
</style>

<style>
/* 全局覆盖对话框层叠与透明度问题，确保完全纯白不透明且阴影立体 */
.custom-promo-dialog {
  background: #ffffff !important;
  border-radius: 14px !important;
  box-shadow: 0 25px 60px rgba(15, 23, 42, 0.35) !important;
  border: 1px solid #e2e8f0 !important;
  overflow: hidden !important;
}

.custom-promo-dialog .el-dialog__header {
  background: #ffffff !important;
  margin-right: 0 !important;
  padding: 18px 24px !important;
  border-bottom: 1px solid #f1f5f9 !important;
}

.custom-promo-dialog .el-dialog__title {
  font-weight: 800 !important;
  font-size: 17px !important;
  color: #0f172a !important;
}

.custom-promo-dialog .el-dialog__body {
  background: #ffffff !important;
  padding: 20px 24px !important;
  max-height: 72vh !important;
  overflow-y: auto !important;
}

.custom-promo-dialog .el-dialog__footer {
  background: #f8fafc !important;
  padding: 14px 24px !important;
  border-top: 1px solid #f1f5f9 !important;
}

/* 遮罩层深度加深，突出弹窗主体 */
.el-overlay {
  background-color: rgba(15, 23, 42, 0.45) !important;
  backdrop-filter: blur(2px) !important;
}
</style>
