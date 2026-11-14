<template>
  <el-container class="layout-container">
    <!-- 顶部导航栏 -->
    <el-header class="layout-header">
      <div class="brand-box">
        <div class="brand-logo" title="海马智慧门店 · 海马会员，记住每位好客。" aria-hidden="true">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12.5 3.2C14.5 3.2 15.8 4.2 16.2 5.5L19.8 6C20.4 6.1 20.4 7.3 19.8 7.5L16 8.2C15.2 8.5 15 9.4 16 10.4C17.8 12 17.8 14.8 15.6 16.6C13.8 18 12.6 19.2 12.8 20.4C13 21.3 14.2 21.6 14.8 20.9C15.3 20.3 14.9 19.5 14.2 19.6C15.6 19.2 16.6 20.4 15.8 21.7C14.8 23 12 22.8 11 21C10 19.2 10.6 17.2 11.8 15.4C12.8 13.8 12.8 11.8 11.6 9.8C10.4 7.8 10.4 4.8 12.5 3.2Z" fill="currentColor" fill-opacity="0.24"/><path d="M11.2 4.4L10.2 2.5L12 3.4L12.8 1.8L13.8 3.3"/><path d="M12 10.5L8.2 9.6C7.6 11.2 7.6 12.8 8.4 14.2L12.2 13.6" fill="currentColor" fill-opacity="0.18"/><path d="M12.4 12L8 11.9"/><path d="M13.5 11.8C14.8 11.8 15.8 12 16.8 12.4"/><path d="M13.4 13.8C14.6 13.8 15.5 14 16.4 14.4"/><circle cx="14.2" cy="6.1" r="1" fill="currentColor" stroke="none"/><path d="M5.2 3.4l.65 1.45L7.3 5.5l-1.45.65L5.2 7.6l-.65-1.45L3.1 5.5l1.45-.65L5.2 3.4z" fill="currentColor" stroke="none"/></svg>
        </div>
        <div class="brand-text">
          <div class="brand-title">
            <span class="brand-title-main">海马智慧门店</span>
            <span class="brand-sub">Seahorse Store</span>
          </div>
          <div class="brand-slogan" title="品牌口号：海马会员，记住每位好客。">
            <span class="slogan-sparkle" aria-hidden="true">✦</span>
            <span class="slogan-words">海马会员，记住每位好客。</span>
          </div>
        </div>
      </div>

      <div class="header-center">
        <!-- 1. 系统开发商身份提示 -->
        <template v-if="isPlatformDeveloper">
          <el-tag type="danger" size="large" effect="dark" class="role-badge">
            🛠️ 系统开发维护人专席 (全平台SaaS大盘与全局配置，无需介入日常门店业务)
          </el-tag>
        </template>

        <!-- 2. 顾客会员身份提示 -->
        <template v-else-if="isCustomerMember">
          <el-tag type="success" size="large" effect="dark" class="role-badge">
            👤 海马顾客会员中心 (海马体记忆档案与资产明细)
          </el-tag>
        </template>

        <!-- 3. 门店运营身份：多店铺切换器与套餐标识 -->
        <template v-else>
          <!-- 智能连锁多店铺切换中心 -->
          <el-popover
            v-model:visible="storeSwitcherVisible"
            trigger="click"
            placement="bottom-start"
            :width="410"
            popper-class="store-switcher-popover"
            :show-arrow="true"
          >
            <template #reference>
              <div
                class="store-selector-badge"
                :class="{
                  'need-init-badge': !storeConfig.storeName || availableStoresForCurrentUser.length === 0,
                  'is-dropdown-open': storeSwitcherVisible
                }"
              >
                <div class="store-badge-icon-box">
                  <span class="store-badge-emoji">{{ currentStoreEmoji }}</span>
                </div>
                <div class="store-badge-content">
                  <span class="current-store-text" :title="storeConfig.storeName || '待创建首家门店'">
                    {{ storeConfig.storeName || '待创建首家门店' }}
                  </span>
                  <span class="current-store-sub-tag" v-if="currentStoreSubText">
                    {{ currentStoreSubText }}
                  </span>
                </div>
                <el-icon class="store-badge-arrow" :class="{ 'is-rotated': storeSwitcherVisible }">
                  <ArrowDown />
                </el-icon>
              </div>
            </template>

            <!-- 弹窗内部面板 -->
            <div class="store-popover-panel">
              <!-- 顶部标题与配额信息 -->
              <div class="popover-header">
                <div class="popover-header-left">
                  <span class="popover-header-title">🏬 切换当前经营门店</span>
                  <span class="store-count-pill">{{ availableStoresForCurrentUser.length }} 家</span>
                </div>
                <div class="popover-header-right" v-if="isMerchantBoss">
                  <span class="store-quota-text">
                    已入驻 <b>{{ availableStoresForCurrentUser.length }}</b> / {{ storeConfig.storeLimit || 1 }} 家
                  </span>
                </div>
              </div>

              <!-- 搜索过滤栏 (分店数 >= 3 时显示) -->
              <div class="popover-search-box" v-if="availableStoresForCurrentUser.length >= 3">
                <el-input
                  v-model="storeSearchKeyword"
                  placeholder="搜索分店名称、商圈或行业分类..."
                  size="small"
                  clearable
                  :prefix-icon="'Search'"
                />
              </div>

              <!-- 门店卡片列表 -->
              <div class="popover-store-list">
                <div
                  v-for="s in filteredStores"
                  :key="s.storeId"
                  class="store-card-item"
                  :class="{ 'is-active': s.storeId === storeConfig.currentStoreId }"
                  @click="selectAndSwitchStore(s.storeId)"
                >
                  <!-- 行业主题立体头像 -->
                  <div class="store-avatar" :class="getStoreIndustryAvatarClass(s)">
                    <span>{{ getStoreIndustryEmoji(s) }}</span>
                  </div>

                  <!-- 门店核心信息 -->
                  <div class="store-info">
                    <div class="store-title-row">
                      <span class="store-name" :title="s.storeName">{{ s.storeName }}</span>
                      <span class="store-industry-pill" :class="getStoreIndustryBadgeClass(s)">
                        {{ getStoreIndustryDesc(s) }}
                      </span>
                    </div>
                    <div class="store-sub-row">
                      <span class="store-code">编号: {{ s.storeId }}</span>
                      <template v-if="s.address">
                        <span class="store-dot">·</span>
                        <span class="store-address" :title="s.address">
                          <el-icon class="sub-addr-icon"><Location /></el-icon>{{ s.address }}
                        </span>
                      </template>
                      <span class="store-status-badge">
                        <span class="status-dot"></span>营业中
                      </span>
                    </div>
                  </div>

                  <!-- 选中状态 / 切换指示 -->
                  <div class="store-status-indicator">
                    <template v-if="s.storeId === storeConfig.currentStoreId">
                      <div class="active-badge">
                        <el-icon><Check /></el-icon>
                        <span>管理中</span>
                      </div>
                    </template>
                    <template v-else>
                      <div class="switch-hover-btn">
                        <span>切换</span>
                        <el-icon><ArrowRight /></el-icon>
                      </div>
                    </template>
                  </div>
                </div>

                <!-- 搜索无匹配 -->
                <div class="popover-search-empty" v-if="filteredStores.length === 0 && availableStoresForCurrentUser.length > 0">
                  <p class="empty-hint">🔍 未匹配到符合条件的分店</p>
                  <el-button link type="primary" size="small" @click="storeSearchKeyword = ''">清空搜索条件</el-button>
                </div>

                <!-- 暂无门店 -->
                <div class="popover-all-empty" v-if="availableStoresForCurrentUser.length === 0">
                  <el-empty description="暂未创建经营门店" :image-size="48" />
                </div>
              </div>

              <!-- 底部操作与角色提示 -->
              <div class="popover-footer">
                <el-button
                  v-if="isMerchantBoss"
                  type="primary"
                  class="create-store-action-btn"
                  @click="openCreateStoreModal"
                >
                  <el-icon><Plus /></el-icon>
                  <span>{{ availableStoresForCurrentUser.length === 0 ? '完善首家门店基本信息' : '开设 / 入驻新分店' }}</span>
                </el-button>
                <div v-else class="employee-store-hint">
                  <el-icon><InfoFilled /></el-icon>
                  <span>员工模式：仅展示已授权执业的分店，如需跨店授权请联系店长或老板</span>
                </div>
              </div>
            </div>
          </el-popover>

          <!-- 租户 SaaS 订阅套餐等级胶囊 (点击查看配额或升级套餐) -->
          <div
            class="luxury-plan-badge"
            :class="planBadgeConfig.badgeClass"
            role="button"
            tabindex="0"
            title="点击查看当前 SaaS 套餐权益、云存储配额或升级包年方案"
            @click="openQuotaModal"
            @keydown.enter.prevent="openQuotaModal"
          >
            <span class="plan-badge-icon-wrap" aria-hidden="true">
              <svg v-if="storeConfig.plan === 'TRIAL'" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L14.8 8.5L22 9.3L16.5 14L18.2 21L12 17.3L5.8 21L7.5 14L2 9.3L9.2 8.5L12 2Z" fill="currentColor" fill-opacity="0.22"/></svg>
              <svg v-else-if="storeConfig.plan === 'PROFESSIONAL'" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3h12l4 6-10 12L2 9z" fill="currentColor" fill-opacity="0.22"/><path d="M2 9h20"/></svg>
              <svg v-else-if="storeConfig.plan === 'ENTERPRISE'" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L3 7v6c0 5.5 3.8 10.7 9 12 5.2-1.3 9-6.5 9-12V7l-9-5z" fill="currentColor" fill-opacity="0.22"/><path d="M9 12l2 2 4-4"/></svg>
              <svg v-else width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"><path d="M2 6l4.5 5L12 4l5.5 7L22 6l-2 13H4L2 6z" fill="currentColor" fill-opacity="0.25"/></svg>
            </span>
            <span class="plan-badge-text">{{ planBadgeConfig.name }}</span>
            <span class="plan-badge-divider" v-if="planBadgeConfig.subText" aria-hidden="true"></span>
            <span class="plan-badge-sub" v-if="planBadgeConfig.subText">
              <span class="plan-sub-dot" v-if="storeConfig.plan === 'TRIAL'"></span>
              {{ planBadgeConfig.subText }}
            </span>
            <span class="plan-badge-cta" v-if="storeConfig.plan === 'TRIAL'">升级</span>
          </div>
        </template>
      </div>

      <div class="header-right-actions">
        <!-- ⚡ 高频前台收银与快捷指令导航条 (门店前台一键直达) -->
        <div v-if="!isPlatformDeveloper && !isCustomerMember" class="pos-quick-launch-bar">
          <button
            class="pos-quick-pill pill-cashier"
            :class="{ 'is-active': $route.path === '/cashier' }"
            @click="$router.push('/cashier')"
            title="进入全功能前台收银台 (支持扫码、会员扣卡、多码组合支付)"
          >
            <span>⚡ 收银台</span>
          </button>
          <button
            class="pos-quick-pill pill-rooms"
            :class="{ 'is-active': $route.path === '/rooms' }"
            @click="$router.push('/rooms')"
            title="查看实时包厢/工位/桌台开单看板"
          >
            <span>🛋️ {{ storeConfig.spaceAlias }}看板</span>
          </button>
          <button
            class="pos-quick-pill pill-cmd"
            @click="openQuickCommandModal"
            title="打开全局快捷搜索与指令面板 (快捷键 Ctrl + K)"
          >
            <span>🔍 快捷导航</span>
            <kbd class="cmd-kbd">Ctrl K</kbd>
          </button>
        </div>

        <!-- 非系统研发人员向平台研发提建议入口 -->
        <el-button
          v-if="!isPlatformDeveloper"
          type="primary"
          plain
          round
          size="small"
          class="feedback-trigger-btn"
          @click="openPlatformFeedbackModal"
        >
          💡 提建议/向系统反馈
        </el-button>

        <!-- 租户云存储与接口用量快捷胶囊徽标 (点击开启动态扩容与充值中心) -->
        <div
          v-if="!isPlatformDeveloper && !isCustomerMember"
          class="quota-status-pill"
          :class="{
            'pill-danger': isPageLocked,
            'pill-warning': storageUsagePercent >= 85 && !isPageLocked
          }"
          @click="openQuotaModal"
          title="点击查看云存储空间与接口操作配额详情，支持在线充值扩容"
        >
          <span class="pill-icon">{{ isPageLocked ? '🔒' : '☁️' }}</span>
          <span class="pill-title">存储空间:</span>
          <span class="pill-value">
            {{ formatStorage(tenantQuota.usedStorageMb) }} / {{ formatStorage(tenantQuota.totalStorageMb) }}
          </span>
          <el-tag
            :type="isPageLocked ? 'danger' : (storageUsagePercent >= 85 ? 'warning' : 'success')"
            size="small"
            effect="dark"
            class="pill-tag"
          >
            {{ isPageLocked ? '🔒 满载锁定' : storageUsagePercent + '%' }}
          </el-tag>
        </div>

        <!-- 🛎️ 包厢现场呼叫服务与新订单出餐通知徽标 (带红点、动态响铃与语音播报) -->
        <div
          v-if="!isPlatformDeveloper && !isCustomerMember"
          class="service-call-badge-btn"
          :class="{ 'has-pending-calls': totalAlertCount > 0 }"
          @click="serviceCallsDrawerVisible = true"
          title="点击查看包厢呼叫服务与新点单出餐明细"
        >
          <span class="bell-icon" :class="{ 'ringing-bell': totalAlertCount > 0 }">🛎️</span>
          <span class="bell-label">包厢动态</span>
          <span v-if="totalAlertCount > 0" class="bell-counter">
            {{ totalAlertCount }}
          </span>
        </div>

        <div class="user-box">
          <el-dropdown trigger="click">
            <span class="user-info">
              <el-avatar size="small" :style="{ backgroundColor: avatarBgColor }">
                {{ userAvatarText }}
              </el-avatar>
              <span class="user-name">{{ username }}</span>
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item @click="$router.push('/profile')">
                  <el-icon><Avatar /></el-icon> 个人中心
                </el-dropdown-item>
                <el-dropdown-item v-if="isPlatformDeveloper" @click="$router.push('/platform-dashboard')">
                  <el-icon><DataAnalysis /></el-icon> 平台营收与运营大盘
                </el-dropdown-item>
                <el-dropdown-item v-if="isMerchantBoss" @click="$router.push('/staff-permissions')">
                  <el-icon><UserFilled /></el-icon> 店员角色权限配置
                </el-dropdown-item>
                <el-dropdown-item v-if="isCustomerMember" @click="$router.push('/member-portal')">
                  <el-icon><Avatar /></el-icon> 我的个人档案
                </el-dropdown-item>
                <el-dropdown-item divided @click="handleLogout">
                  <el-icon><SwitchButton /></el-icon> 退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </div>
    </el-header>

    <el-container class="main-body">
      <!-- 侧边菜单栏 -->
      <el-aside width="220px" class="layout-aside">
        <el-menu
          :default-active="activeNavPath"
          router
          class="el-menu-vertical"
          background-color="#ffffff"
          text-color="#475569"
          active-text-color="#0284c7"
        >
          <!-- 1. 开发维护人专属菜单 (8大独立页签按业务域与配置域拆分) -->
          <template v-if="isPlatformDeveloper">
            <!-- 业务分区 1: 业务监控与运营大盘 (查看 / 报表 / 流水 / 审计) -->
            <div class="menu-group-header">
              <div class="group-header-inner">
                <span class="group-header-icon">📊</span>
                <span class="group-header-title">业务监控与运营大盘</span>
              </div>
            </div>
            <el-menu-item index="/platform-dashboard">
              <el-icon><DataAnalysis /></el-icon>
              <span>平台营收与运营大盘</span>
            </el-menu-item>
            <el-menu-item index="/vendor-tenants">
              <el-icon><OfficeBuilding /></el-icon>
              <span>租户订阅与门店管控</span>
            </el-menu-item>
            <el-menu-item index="/vendor-campaigns">
              <el-icon><Present /></el-icon>
              <span>SaaS 营销与促销策略库</span>
            </el-menu-item>
            <el-menu-item index="/vendor-activity">
              <el-icon><TrendCharts /></el-icon>
              <span>租户活跃与时段分析</span>
            </el-menu-item>
            <el-menu-item index="/vendor-billings">
              <el-icon><Money /></el-icon>
              <span>SaaS订阅与存储流水</span>
            </el-menu-item>
            <el-menu-item index="/vendor-feedback">
              <el-icon><Promotion /></el-icon>
              <span>平台建言与需求受理</span>
            </el-menu-item>

            <!-- 业务分区 2: 平台规则与全系统配置 (定价 / 试用 / 权限 / 对接) -->
            <div class="menu-group-header" style="margin-top: 14px;">
              <div class="group-header-inner">
                <span class="group-header-icon">⚙️</span>
                <span class="group-header-title">平台规则与全系统配置</span>
              </div>
            </div>
            <el-menu-item index="/vendor-plans">
              <el-icon><Setting /></el-icon>
              <span>套餐定价与试用配置</span>
            </el-menu-item>
            <el-menu-item index="/vendor-industry-presets">
              <el-icon><SetUp /></el-icon>
              <span>常用行业预设全景配置</span>
            </el-menu-item>
            <el-menu-item index="/vendor-permissions">
              <el-icon><Key /></el-icon>
              <span>角色权限全局配置</span>
            </el-menu-item>
            <el-menu-item index="/vendor-developer-notif">
              <el-icon><Connection /></el-icon>
              <span>全渠道通信与短信对接</span>
            </el-menu-item>
            <el-menu-item index="/payment-settings">
              <el-icon><CreditCard /></el-icon>
              <span>扫码盒子与支付通道</span>
            </el-menu-item>
            <el-menu-item index="/map-settings">
              <el-icon><Location /></el-icon>
              <span>高德地图与考勤定位</span>
            </el-menu-item>
          </template>

          <!-- 2. 顾客会员专属菜单 -->
          <template v-else-if="isCustomerMember">
            <el-menu-item index="/member-portal">
              <el-icon><Avatar /></el-icon>
              <span>海马体专属主页</span>
            </el-menu-item>
          </template>

          <!-- 3. 门店老板与员工菜单 (根据员工被授权的页签动态渲染，租户老板拥有全量豁免) -->
          <template v-else>
            <!-- 业务分区 1: 门店前台 -->
            <div class="menu-group-header" v-if="isAnyMenuAllowed(['/dashboard', '/rooms', '/appointments'])">
              <div class="group-header-inner">
                <span class="group-header-icon">🏠</span>
                <span class="group-header-title">门店前台</span>
              </div>
            </div>
            <el-menu-item index="/dashboard" v-if="isMenuAllowed('/dashboard')">
              <el-icon><Odometer /></el-icon>
              <span>系统首页</span>
            </el-menu-item>
            <el-menu-item index="/rooms" v-if="isMenuAllowed('/rooms')">
              <el-icon>
                <House v-if="spaceMenuIcon === 'house'" />
                <Tools v-else-if="spaceMenuIcon === 'tools'" />
                <Shop v-else />
              </el-icon>
              <span>{{ currentSpaceAliasTitle }}</span>
            </el-menu-item>
            <el-menu-item index="/appointments" v-if="isMenuAllowed('/appointments')">
              <el-icon><Calendar /></el-icon>
              <span>预约排班</span>
            </el-menu-item>

            <!-- 业务分区 2: 客源营销 -->
            <div class="menu-group-header" v-if="isAnyMenuAllowed(['/members', '/card-template', '/marketing', '/mall', '/sms-records'])">
              <div class="group-header-inner">
                <span class="group-header-icon">👥</span>
                <span class="group-header-title">客源营销</span>
              </div>
            </div>
            <el-menu-item index="/members" v-if="isMenuAllowed('/members')">
              <el-icon><User /></el-icon>
              <span>会员中心</span>
            </el-menu-item>
            <el-menu-item index="/card-template" v-if="isMenuAllowed('/card-template')">
              <el-icon><CreditCard /></el-icon>
              <span>会员卡包</span>
            </el-menu-item>
            <el-menu-item index="/sms-records" v-if="isMenuAllowed('/sms-records')">
              <el-icon><Message /></el-icon>
              <span>短信管理</span>
            </el-menu-item>
            <el-menu-item index="/marketing" v-if="isMenuAllowed('/marketing')">
              <el-icon><TrendCharts /></el-icon>
              <span>营销裂变</span>
            </el-menu-item>
            <el-menu-item index="/mall" v-if="isMenuAllowed('/mall')">
              <el-icon><Shop /></el-icon>
              <span>线上商城</span>
            </el-menu-item>

            <!-- 业务分区 3: 货品物资 -->
            <div class="menu-group-header" v-if="isAnyMenuAllowed(['/products', '/inventory'])">
              <div class="group-header-inner">
                <span class="group-header-icon">📦</span>
                <span class="group-header-title">货品物资</span>
              </div>
            </div>
            <el-menu-item index="/products" v-if="isMenuAllowed('/products')">
              <el-icon><Goods /></el-icon>
              <span>项目商品</span>
            </el-menu-item>
            <el-menu-item index="/inventory" v-if="isMenuAllowed('/inventory')">
              <el-icon><Box /></el-icon>
              <span>物料库存</span>
            </el-menu-item>

            <!-- 业务分区 4: 财务核算 (成本中心与支出管理合并为【门店账本】) -->
            <div class="menu-group-header" v-if="isAnyMenuAllowed(['/expenses', '/cost-center', '/reports'])">
              <div class="group-header-inner">
                <span class="group-header-icon">💰</span>
                <span class="group-header-title">财务核算</span>
              </div>
            </div>
            <el-menu-item index="/expenses" v-if="isMenuAllowed('/expenses') || isMenuAllowed('/cost-center')">
              <el-icon><Money /></el-icon>
              <span>门店账本</span>
            </el-menu-item>
            <el-sub-menu index="/reports" v-if="isMenuAllowed('/reports')">
              <template #title>
                <el-icon><DataAnalysis /></el-icon>
                <span>统计报表</span>
              </template>
              <el-menu-item index="/reports/income">收入明细</el-menu-item>
              <el-menu-item index="/reports/card-deduct">扣卡统计</el-menu-item>
              <el-menu-item index="/reports/points">积分统计</el-menu-item>
              <el-menu-item index="/reports/rewards">奖励金统计</el-menu-item>
              <el-menu-item index="/reports/new-members">新增会员统计</el-menu-item>
              <el-menu-item index="/reports/payment-methods">收入方式统计</el-menu-item>
              <el-menu-item index="/reports/profit">利润统计</el-menu-item>
              <el-menu-item index="/reports/staff-performance">员工业绩统计</el-menu-item>
              <el-menu-item index="/reports/remaining-times">未消费余次统计</el-menu-item>
              <el-menu-item index="/reports/remaining-balance">未消费余额统计</el-menu-item>
              <el-menu-item index="/reports/item-sales">单项销售统计</el-menu-item>
            </el-sub-menu>

            <div class="menu-group-header" v-if="isAnyMenuAllowed(['/staff-management', '/regulations', '/chain', '/settings', '/profile'])">
              <div class="group-header-inner">
                <span class="group-header-icon">⚙️</span>
                <span class="group-header-title">店务管控</span>
              </div>
            </div>
            <el-menu-item index="/staff-management" v-if="isMenuAllowed('/staff-management')">
              <el-icon><UserFilled /></el-icon>
              <span>员工管理</span>
            </el-menu-item>
            <el-menu-item index="/job-posts" v-if="isMenuAllowed('/job-posts') || isMenuAllowed('/staff-management')">
              <el-icon><Briefcase /></el-icon>
              <span>部门架构与岗位管理</span>
            </el-menu-item>
            <el-menu-item index="/regulations" v-if="isMenuAllowed('/regulations')">
              <el-icon><Document /></el-icon>
              <span>规章制度</span>
            </el-menu-item>
            <el-menu-item index="/chain" v-if="isMenuAllowed('/chain')">
              <el-icon><OfficeBuilding /></el-icon>
              <span>连锁协同</span>
            </el-menu-item>
            <el-menu-item index="/settings" v-if="isMenuAllowed('/settings')">
              <el-icon><Setting /></el-icon>
              <span>店铺设置</span>
            </el-menu-item>
            <el-menu-item index="/profile" v-if="isMenuAllowed('/profile')">
              <el-icon><Avatar /></el-icon>
              <span>个人中心</span>
            </el-menu-item>
          </template>
        </el-menu>
        <!-- 侧边栏底部合规与服务信息 -->
        <div class="aside-footer-legal">
          <div>© 2026 FWPT · 海马智慧门店</div>
          <div class="legal-row">
            <a href="https://beian.miit.gov.cn/" target="_blank" rel="noopener" class="legal-link">陕ICP备2026025219号</a>
          </div>
          <div class="legal-row">
            <a href="mailto:admin@fwpt.cn" class="legal-link">admin@fwpt.cn</a>
          </div>
        </div>
      </el-aside>

      <!-- 主视图区域 -->
      <el-main class="layout-main">
        <!-- 商户已被超级管理员停用强警示条 -->
        <el-alert
          v-if="storeConfig.status === 'DISABLED' && !isPlatformDeveloper"
          title="🚫 【商户已被平台超级管理员禁用】该租户账号已被停用，所有业务写操作与访问权限已冻结。请联系平台运营管理人员办理恢复！"
          type="error"
          show-icon
          :closable="false"
          class="system-alert-banner alert-banner-disabled"
        />

        <!-- 存储空间与接口配额耗尽锁定警告条 -->
        <el-alert
          v-if="isPageLocked && storeConfig.status !== 'DISABLED'"
          title="⚠️ 【云端存储空间已达上限 · 页面写操作已锁定】您的存储空间或接口操作配额已耗尽，系统已进入只读受限保护状态。请立即充值存储空间或选购流量包以解除锁定！"
          type="error"
          show-icon
          :closable="false"
          class="system-alert-banner quota-locked-alert alert-banner-quota"
        >
          <template #default>
            <div class="locked-alert-content">
              <span>原因：{{ tenantQuota.lockReason }}（已累计调用 {{ tenantQuota.usedApiCalls.toLocaleString() }} 次操作）。为了不影响门店日常收银开单与业务录入，请及时充值扩容云端存储空间或选购流量包！</span>
              <div class="alert-actions">
                <el-button type="danger" size="small" @click="openQuotaModal">
                  ⚡ 立即充值扩容解封
                </el-button>
                <el-button type="success" plain size="small" @click="handleTestQuickUnlock">
                  🛠️ 一键应急解封 (测试)
                </el-button>
              </div>
            </div>
          </template>
        </el-alert>

        <div
          v-if="storeConfig.isTrial && storeConfig.status !== 'DISABLED'"
          class="trial-slim-banner"
        >
          <div class="tsb-left">
            <span class="tsb-badge">SaaS 体验版</span>
            <span class="tsb-text">
              当前全功能免费体验中，剩余有效期 <b>{{ storeConfig.trialDaysRemaining }} 天</b>（POS 收银、会员储值、多店报表与业财对账全部开放）
            </span>
          </div>
          <button type="button" class="tsb-btn" @click="openQuotaModal">
            查看套餐权益 / 升级正式版 →
          </button>
        </div>
        <el-alert
          v-if="isMerchantBoss && !storeConfig.industryCategoryName"
          title="【初次使用引导】当前门店尚未配置细分行业分类（如汽车服务、美业服务、餐饮店等），点击此处前往配置！"
          type="info"
          show-icon
          closable
          class="system-alert-banner alert-banner-guide"
          @click="router.push('/industry-config')"
        />

        <!-- 主页面操作受限隔离层 -->
        <div class="main-body-wrapper" :class="{ 'page-locked-active': isPageLocked }">
          <!-- 强提醒居中卡片 -->
          <div v-if="isPageLocked" class="lock-overlay-panel">
            <div class="lock-card-box">
              <div class="lc-icon">{{ storeConfig.status === 'DISABLED' ? '🚫' : '🔒' }}</div>
              <h3 class="lc-title">{{ storeConfig.status === 'DISABLED' ? '商户账号已被平台停用 · 系统操作已冻结' : '云端存储空间已耗尽 · 页面写操作已锁定' }}</h3>
              <p class="lc-desc">
                <template v-if="storeConfig.status === 'DISABLED'">
                  尊敬的租户管理员，您的商户账号已被<strong>平台超级管理员设置为停用/禁用状态</strong>。<br/>
                  当前工作台已全面进入<strong>只读受限保护状态</strong>，无法继续进行开单、充值、办卡、编辑等任何写操作。如有疑问请及时联系平台客服或运营人员。
                </template>
                <template v-else>
                  尊敬的租户管理员，您当前的<strong>云端存储空间已达 100% 上限</strong>（{{ formatStorage(tenantQuota.usedStorageMb) }} / {{ formatStorage(tenantQuota.totalStorageMb) }}）。<br/>
                  为保障云端数据完整性，系统已将工作台切换为<strong>只读受限保护状态</strong>，无法继续进行开单、充值、办卡、编辑等写操作。
                </template>
              </p>
              <div class="lc-stats-grid">
                <div class="lc-s-item">
                  <span class="lbl">当前计费模式：</span>
                  <span class="val">{{ tenantQuota.billingMode === 'ANNUAL_TIER' ? '👑 包年订阅阶梯模式' : '🌱 普通永久免费 + 流量包/存储计费' }}</span>
                </div>
                <div class="lc-s-item">
                  <span class="lbl">存储空间占用：</span>
                  <span class="val text-danger"><b>100% 满载</b> ({{ tenantQuota.usedStorageMb }} MB / {{ tenantQuota.totalStorageMb }} MB)</span>
                </div>
                <div class="lc-s-item">
                  <span class="lbl">接口调用总计：</span>
                  <span class="val text-warning">{{ tenantQuota.usedApiCalls.toLocaleString() }} / {{ tenantQuota.totalApiCalls.toLocaleString() }} 次</span>
                </div>
                <div class="lc-s-item">
                  <span class="lbl">锁定保护状态：</span>
                  <span class="val text-danger">● 只读受限中 (不可操作页面)</span>
                </div>
              </div>
              <div class="lc-actions-row">
                <el-button type="primary" size="large" class="lc-recharge-btn" @click="openQuotaModal">
                  ⚡ 立即在线充值存储空间 / 购买流量包 (即时解封)
                </el-button>
              </div>
              <div class="lc-help-row">
                <span class="help-tip">💡 充值任意存储包或流量加油包后，系统将自动解除锁定并恢复全部功能。</span>
                <el-button link type="success" size="small" @click="handleTestQuickUnlock">
                  🛠️ 模拟应急解除锁定 (测试专用)
                </el-button>
              </div>
            </div>
          </div>

          <router-view />
        </div>
      </el-main>
    </el-container>

    <!-- 新建分店对话框 -->
    <el-dialog v-model="createStoreVisible" title="🏪 开设/入驻新分店" width="540px" destroy-on-close>
      <el-form :model="createStoreForm" label-width="135px" style="margin-top: 10px;">
        <el-form-item label="分店名称" required>
          <el-input v-model="createStoreForm.storeName" placeholder="例如：海马科技园旗舰分店" />
        </el-form-item>
        <el-form-item label="主营行业分类" required>
          <el-cascader
            v-model="createStoreCascaderValue"
            :options="createStoreCascaderOptions"
            :props="{ expandTrigger: 'hover' }"
            placeholder="必选：请选择主营行业大类与精准分类 (如：服务类 · 美业服务)"
            style="width: 100%;"
            @change="handleCreateStoreCascaderChange"
          />
        </el-form-item>
        <el-form-item label="前台预约电话" required>
          <el-input v-model="createStoreForm.phone" placeholder="分店前台热线电话" />
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

    <!-- 新租户开店初始化：完善首家门店基本信息与行业分类 -->
    <el-dialog
      v-model="onboardingVisible"
      title="🏪 新租户开店初始化：完善首家门店基本信息与行业分类"
      width="620px"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      :show-close="availableStoresForCurrentUser.length > 0"
      append-to-body
    >
      <el-alert
        title="欢迎入驻海马智慧商业平台！请先完善您的首家实体门店基本信息并选择主营细分行业，系统将即时为您匹配对应的业务模式与行业看板。"
        type="warning"
        :closable="false"
        show-icon
        style="margin-bottom: 20px;"
      />
      <el-form :model="onboardingForm" label-width="125px">
        <el-form-item label="店铺招牌全称" required>
          <el-input v-model="onboardingForm.storeName" placeholder="例如：丝艺美学形象沙龙 / 栖枫悦食料理 / 极速动力工坊" />
        </el-form-item>

        <el-form-item label="经营大类门类" required>
          <el-radio-group v-model="onboardingSelectedGroup" @change="handleGroupChange">
            <el-radio-button label="服务类">💆‍♂️ 服务类 (美业/汽修/健身/休闲等)</el-radio-button>
            <el-radio-button label="零售类">🛍️ 零售类 (商超便利/餐饮轻食等)</el-radio-button>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="细分行业品类" required>
          <el-select
            v-model="onboardingForm.industryCategoryId"
            placeholder="请选择精准细分行业品类"
            style="width: 100%;"
            @change="handleCategoryChange"
          >
            <el-option
              v-for="cat in availableCategoriesForSelectedGroup"
              :key="cat.id"
              :label="cat.name"
              :value="cat.id"
            >
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <span>{{ cat.name }}</span>
                <el-tag size="small" type="info">{{ cat.defaultIndustryType || '通用' }}</el-tag>
              </div>
            </el-option>
          </el-select>
        </el-form-item>

        <el-form-item label="门店预约电话" required>
          <el-input v-model="onboardingForm.phone" placeholder="门店服务热线，例如：0755-88889999 或 手机号" />
        </el-form-item>

        <el-form-item label="详细经营地址" required>
          <el-input v-model="onboardingForm.address" placeholder="例如：深圳市南山区高新科技园中区1栋101" />
        </el-form-item>

        <el-form-item label="日常营业时间">
          <el-input v-model="onboardingForm.businessHours" placeholder="如：09:00 - 22:00" />
        </el-form-item>
      </el-form>

      <template #footer>
        <div style="display: flex; justify-content: flex-end; gap: 10px;">
          <el-button v-if="availableStoresForCurrentUser.length > 0" @click="onboardingVisible = false">暂不修改</el-button>
          <el-button type="primary" size="large" :loading="submittingOnboarding" @click="handleSubmitOnboarding">
            🚀 确认并开启我的门店
          </el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 全平台非研发人员向研发团队提需求/建议对话框 -->
    <el-dialog
      v-model="feedbackModalVisible"
      title="💡 向海马智慧门店系统研发团队提需求与建言"
      width="650px"
      destroy-on-close
      class="custom-feedback-dialog"
    >
      <div class="feedback-modal-intro">
        <el-alert
          title="您的声音直达研发！欢迎租户老板、店长、前台、技师等所有非技术一线人员提出功能诉求、操作槽点或界面建议，我们将由产品架构团队直接评审并纳入迭代排期。"
          type="success"
          :closable="false"
          show-icon
        />
      </div>

      <el-form :model="feedbackForm" :rules="feedbackRules" ref="feedbackFormRef" label-position="top" style="margin-top: 16px;">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="建议类型" prop="type">
              <el-select v-model="feedbackForm.type" style="width: 100%;">
                <el-option label="✨ 新功能诉求 (期望增加某业务功能)" value="FEATURE_REQUEST" />
                <el-option label="🎨 交互与视觉体验优化 (不好用/想变美)" value="EXPERIENCE_OPT" />
                <el-option label="🐛 缺陷/异常反馈 (发现系统Bug)" value="BUG_REPORT" />
                <el-option label="💡 商业模式与创新方案" value="BUSINESS_IDEA" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="所属功能模块" prop="module">
              <el-select v-model="feedbackForm.module" style="width: 100%;">
                <el-option label="门店前台 (空间/工位/预约)" value="门店前台" />
                <el-option label="客源营销 (会员/卡包/商城)" value="客源营销" />
                <el-option label="收银结算 (开单/买单/储值核销)" value="收银结算" />
                <el-option label="规章制度与协同 (签字/公告)" value="规章协同" />
                <el-option label="货品物资 (商品/库存/BOM)" value="货品物资" />
                <el-option label="财务报表 (账本/利润/核算)" value="财务核算" />
                <el-option label="店务人事 (员工/排班/提成)" value="店务人事" />
                <el-option label="全局系统操作体验" value="系统体验" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="建议/需求标题" prop="title">
          <el-input v-model="feedbackForm.title" placeholder="请用一句简明的话概括您的需求或建议" maxlength="60" show-word-limit />
        </el-form-item>

        <el-form-item label="详细业务场景与期望效果" prop="content">
          <el-input
            v-model="feedbackForm.content"
            type="textarea"
            :rows="5"
            placeholder="请详细描述您在日常经营使用中的痛点、具体业务场景以及期望系统如何改进（例如：在哪个操作步骤、希望怎么点更顺手、希望增加什么字段等）..."
            maxlength="600"
            show-word-limit
          />
        </el-form-item>

        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="期望实现紧迫度">
              <el-radio-group v-model="feedbackForm.urgency">
                <el-radio label="LOW">日常优化</el-radio>
                <el-radio label="NORMAL">较为期望</el-radio>
                <el-radio label="HIGH">急需/影响日常</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="您的联系电话 (选填，方便技术团队沟通细节)">
              <el-input v-model="feedbackForm.phone" placeholder="输入您的手机号" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>

      <template #footer>
        <span class="dialog-footer">
          <el-button @click="feedbackModalVisible = false">取消</el-button>
          <el-button type="primary" :loading="submittingFeedback" @click="handleSubmitPlatformFeedback">
            🚀 提交给系统研发团队
          </el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 租户云存储与接口操作配额充值中心对话框 -->
    <el-dialog
      v-model="quotaModalVisible"
      title="☁️ 租户云端存储空间与接口操作配额充值中心"
      width="820px"
      destroy-on-close
      class="quota-recharge-dialog"
    >
      <div class="quota-modal-body">
        <!-- 顶部状态指示栏 -->
        <div class="qm-top-card">
          <div class="qm-top-row">
            <div class="qm-tenant-info">
              <span class="qm-tenant-name">{{ tenantQuota.tenantName }}</span>
              <el-tag :type="tenantQuota.billingMode === 'ANNUAL_TIER' ? 'primary' : 'success'" size="small" effect="dark">
                {{ tenantQuota.billingMode === 'ANNUAL_TIER' ? '👑 包年订阅阶梯模式' : '🌱 普通永久免费 + 流量包/存储计费' }}
              </el-tag>
              <el-tag v-if="isPageLocked" type="danger" size="small" effect="dark">
                🔒 页面写操作已锁定
              </el-tag>
              <el-tag v-else type="success" size="small" effect="plain">
                ● 运行正常 (未锁定)
              </el-tag>
            </div>
            <div class="qm-plan-tag">当前套餐：{{ tenantQuota.planName }}</div>
          </div>

          <!-- 双进度条：存储空间与接口操作 -->
          <div class="qm-meters-grid">
            <div class="meter-box">
              <div class="mb-label-row">
                <span class="mb-lbl">☁️ 云端存储容量：</span>
                <span class="mb-val" :class="{ 'text-danger': isPageLocked }">
                  {{ formatStorage(tenantQuota.usedStorageMb) }} / {{ formatStorage(tenantQuota.totalStorageMb) }} ({{ storageUsagePercent }}%)
                </span>
              </div>
              <el-progress
                :percentage="storageUsagePercent"
                :status="isPageLocked ? 'exception' : (storageUsagePercent >= 85 ? 'warning' : 'success')"
                :stroke-width="12"
              />
            </div>
            <div class="meter-box">
              <div class="mb-label-row">
                <span class="mb-lbl">⚡ 系统操作接口调用：</span>
                <span class="mb-val">
                  {{ tenantQuota.usedApiCalls.toLocaleString() }} / {{ tenantQuota.totalApiCalls.toLocaleString() }} 次 ({{ apiUsagePercent }}%)
                </span>
              </div>
              <el-progress
                :percentage="apiUsagePercent"
                :status="apiUsagePercent >= 100 ? 'exception' : (apiUsagePercent >= 85 ? 'warning' : '')"
                :stroke-width="12"
              />
            </div>
          </div>
        </div>

        <!-- 选购充值加油包与阶梯说明选项卡 -->
        <el-tabs v-model="activeQuotaTab" class="qm-tabs" style="margin-top: 16px;">
          <!-- 选项卡 1：云存储扩容包 -->
          <el-tab-pane label="☁️ 云存储扩容包" name="STORAGE">
            <div class="packs-grid">
              <div
                v-for="pack in RECHARGE_PACKAGES.storagePacks"
                :key="pack.id"
                class="pack-card"
                :class="{ 'pack-highlight': pack.id === 'store_50g' }"
              >
                <div class="pk-badge" v-if="pack.badge">{{ pack.badge }}</div>
                <div class="pk-name">{{ pack.name }}</div>
                <div class="pk-price-row">
                  <span class="pk-cur">￥</span><span class="pk-val">{{ pack.price }}</span>
                  <span class="pk-unit">/ {{ pack.period }}</span>
                </div>
                <div class="pk-desc">{{ pack.desc }}</div>
                <div class="pk-cap">+{{ formatStorage(pack.storageMb) }} 扩容空间</div>
                <el-button
                  type="primary"
                  size="default"
                  class="pk-buy-btn"
                  @click="handleRechargeStorage(pack)"
                >
                  立即充值并解封
                </el-button>
              </div>
            </div>
          </el-tab-pane>

          <!-- 选项卡 2：接口操作流量包 -->
          <el-tab-pane label="🚀 接口操作流量包" name="API">
            <div class="packs-grid">
              <div
                v-for="pack in RECHARGE_PACKAGES.apiPacks"
                :key="pack.id"
                class="pack-card"
                :class="{ 'pack-highlight': pack.id === 'api_200k' }"
              >
                <div class="pk-badge" v-if="pack.badge">{{ pack.badge }}</div>
                <div class="pk-name">{{ pack.name }}</div>
                <div class="pk-price-row">
                  <span class="pk-cur">￥</span><span class="pk-val">{{ pack.price }}</span>
                  <span class="pk-unit">/ 次</span>
                </div>
                <div class="pk-desc">{{ pack.desc }}</div>
                <div class="pk-cap">+{{ pack.calls.toLocaleString() }} 次后台操作</div>
                <el-button
                  type="success"
                  size="default"
                  class="pk-buy-btn"
                  @click="handleRechargeApiCalls(pack)"
                >
                  立即购买充值
                </el-button>
              </div>
            </div>
          </el-tab-pane>

          <!-- 选项卡 3：升级包年无限版 -->
          <el-tab-pane label="👑 升级包年套餐 (免单次买包)" name="ANNUAL">
            <div class="annual-upgrade-grid">
              <div
                v-for="p in RECHARGE_PACKAGES.annualUpgrades"
                :key="p.id"
                class="annual-card"
              >
                <div class="ac-top">
                  <div>
                    <div class="ac-name">{{ p.name }}</div>
                    <div class="ac-desc">{{ p.desc }}</div>
                  </div>
                  <div class="ac-price">
                    <span class="p-cur">￥</span><span class="p-num">{{ p.price }}</span><span class="p-u">/年</span>
                  </div>
                </div>
                <div class="ac-perks">
                  <span class="perk-tag">✓ 附赠 {{ formatStorage(p.storageMb) }} 专属容量</span>
                  <span class="perk-tag">✓ 赠送 {{ p.calls.toLocaleString() }} 次高频接口</span>
                  <span class="perk-tag">✓ 享专属客户成功顾问</span>
                </div>
                <el-button type="warning" size="default" class="ac-btn" @click="handleUpgradeAnnual(p)">
                  一键升级为包年版
                </el-button>
              </div>
            </div>
          </el-tab-pane>

          <!-- 选项卡 4：4大计算阶梯方式统计说明 -->
          <el-tab-pane label="📐 接口操作量化阶梯标准" name="TIERS">
            <div style="font-size: 13px; color: #475569; margin-bottom: 12px; line-height: 1.6;">
              💡 <b>量化计算方法说明：</b>系统将门店每一次日常操作（开单收银、添加商品、技师排班、会员充值等）统计为后台接口操作频次。1笔标准开单收银（开台+加项+扣卡+写流水+小票下发）折算约 12 次接口操作。平台根据租户每月调用体量划分 4 级阶梯：
            </div>

            <el-table :data="QUOTA_TIER_STANDARDS" border size="small" stripe style="width: 100%;">
              <el-table-column prop="tierLevel" label="阶梯档位" width="85">
                <template #default="{ row }">
                  <el-tag size="small" :type="row.tierLevel === 1 ? 'success' : (row.tierLevel === 4 ? 'danger' : 'primary')">
                    第 {{ row.tierLevel }} 阶梯
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="tierName" label="阶梯名称" width="160" />
              <el-table-column prop="applicableScale" label="适用租户规模" min-width="150" />
              <el-table-column prop="apiCallsRange" label="月均接口操作频次" width="140" />
              <el-table-column prop="storageRange" label="云端存储空间" width="110" />
              <el-table-column prop="billingRule" label="计费阶梯标准" min-width="150" />
            </el-table>
          </el-tab-pane>
        </el-tabs>
      </div>

      <template #footer>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <div style="display: flex; gap: 8px;">
            <el-button size="small" type="danger" plain @click="handleTestQuickLock">
              🛠️ 模拟耗尽锁定 (测试演示)
            </el-button>
            <el-button size="small" type="success" plain @click="handleTestQuickUnlock">
              🛠️ 模拟一键解封 (测试演示)
            </el-button>
          </div>
          <el-button @click="quotaModalVisible = false">关闭窗口</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 🛎️ 包厢现场呼叫服务与新订单受理抽屉 (多端实时同步) -->
    <el-drawer
      v-model="serviceCallsDrawerVisible"
      title="🛎️ 包厢现场呼叫与新订单受理中心"
      size="460px"
      direction="rtl"
    >
      <div class="service-calls-drawer-panel">
        <div class="sc-drawer-header-bar">
          <div>
            <span>待处理：<b style="color: #e11d48; font-size: 15px;">{{ totalAlertCount }} 项</b></span>
            <span style="font-size: 12px; color: #64748b; margin-left: 8px;">(呼叫 {{ pendingServiceCalls.length }} / 新单 {{ pendingOrderNotifications.length }})</span>
          </div>
          <el-button size="small" type="primary" plain @click="testServiceSound">🔊 测试提示音与报单</el-button>
        </div>

        <div v-if="totalAlertCount === 0" class="sc-empty-hint">
          <el-empty description="当前暂无待处理呼叫或新订单，客人在包厢扫码点餐或呼叫时将在此即时语音播报" :image-size="70" />
        </div>

        <div v-else class="sc-calls-list">
          <!-- 1. 新订单待出单/备餐列表 -->
          <div v-for="order in pendingOrderNotifications" :key="order.id" class="sc-order-card">
            <div class="scc-top">
              <span class="scc-room-badge">🍲 {{ order.spaceName }} ({{ order.spaceCode || '包厢' }})</span>
              <el-tag size="small" type="success" effect="dark">新点单 · {{ order.itemsCount }} 项</el-tag>
            </div>
            <div class="scc-order-content">
              <b>品项：</b>{{ order.itemNamesSummary }}
            </div>
            <div class="scc-price-row">
              <span class="scc-time">下单时间：{{ order.createTime }}</span>
              <span class="scc-amount">金额：<b>￥{{ Number(order.totalAmount || 0).toFixed(2) }}</b></span>
            </div>
            <div class="scc-actions">
              <el-button size="small" type="primary" @click="handleMarkOrderNotification(order.id)">
                ✓ 标记为已接单/已备餐
              </el-button>
            </div>
          </div>

          <!-- 2. 包厢现场呼叫服务列表 -->
          <div v-for="call in pendingServiceCalls" :key="call.id" class="sc-call-card">
            <div class="scc-top">
              <span class="scc-room-badge">🛎️ {{ call.spaceName }} ({{ call.spaceCode }})</span>
              <el-tag size="small" type="danger" effect="dark">{{ call.serviceType }}</el-tag>
            </div>
            <div class="scc-time">呼叫时间：{{ call.createTime }}</div>
            <div v-if="call.notes" class="scc-notes">顾客备注：{{ call.notes }}</div>
            <div class="scc-actions">
              <el-button size="small" type="success" @click="handleMarkServiceCall(call.id)">
                ✓ 标记为已前往处理
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </el-drawer>

    <!-- 📜 门店新规章制度与运营规范发布全文查阅弹窗 (全端实时推送强提醒) -->
    <el-dialog
      v-model="noticeModalVisible"
      :title="currentAlertNotice?.isUrgent ? '🚨 门店特急重要通知' : '📜 门店新规章制度与运营规范发布'"
      width="680px"
      destroy-on-close
      class="regulation-notice-dialog"
    >
      <div v-if="currentAlertNotice" class="notice-detail-dialog-body" style="padding: 6px 4px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; border-bottom: 1px solid #f1f5f9; padding-bottom: 10px;">
          <div style="display: flex; gap: 8px; align-items: center;">
            <el-tag :type="currentAlertNotice.isUrgent ? 'danger' : 'primary'" effect="dark">
              {{ currentAlertNotice.categoryName || '规章制度' }}
            </el-tag>
            <el-tag type="info" effect="plain">{{ currentAlertNotice.version || 'V1.0' }}</el-tag>
            <el-tag v-if="currentAlertNotice.requireSignature" type="danger" effect="plain">
              ✍️ 强制手写签字确认
            </el-tag>
          </div>
          <span style="font-size: 12px; color: #64748b;">生效日期：{{ currentAlertNotice.effectiveDate || '即日起生效' }}</span>
        </div>

        <h3 style="font-size: 18px; font-weight: 700; color: #0f172a; margin: 0 0 10px 0;">
          {{ currentAlertNotice.title }}
        </h3>

        <div style="font-size: 12px; color: #64748b; margin-bottom: 14px;">
          发布人：<b style="color: #334155;">{{ currentAlertNotice.publisher || '门店管理委员会' }}</b> · 适用门店：<b style="color: #0284c7;">{{ storeConfig.storeName || '全连锁门店' }}</b>
        </div>

        <!-- 摘要 -->
        <div v-if="currentAlertNotice.summary" style="background: #f8fafc; border-left: 4px solid #0284c7; padding: 10px 14px; border-radius: 4px; margin-bottom: 14px;">
          <div style="font-size: 12px; font-weight: bold; color: #0369a1; margin-bottom: 4px;">💡 核心摘要速览：</div>
          <div style="font-size: 13px; color: #334155; line-height: 1.6;">{{ currentAlertNotice.summary }}</div>
        </div>

        <!-- 条款正文 -->
        <div style="margin-top: 14px;">
          <div style="font-size: 13px; font-weight: bold; color: #1e293b; margin-bottom: 6px;">📋 规章条款正文与执行细则：</div>
          <div style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 6px; padding: 14px; font-size: 13px; line-height: 1.7; color: #334155; max-height: 320px; overflow-y: auto; white-space: pre-wrap;">{{ currentAlertNotice.content }}</div>
        </div>
      </div>

      <template #footer>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span v-if="currentAlertNotice?.requireSignature" style="font-size: 12px; color: #ef4444; font-weight: bold;">
            ⚠️ 本规章制度要求员工在文库中手写签字备案
          </span>
          <span v-else style="font-size: 12px; color: #64748b;">
            已阅读即视为已知悉并严格遵照执行
          </span>
          <div style="display: flex; gap: 10px;">
            <el-button @click="noticeModalVisible = false">我已了解</el-button>
            <el-button type="primary" @click="handleGoToRegulations">
              {{ currentAlertNotice?.requireSignature ? '✍️ 前往文库完成签署' : '📜 前往规章制度文库' }}
            </el-button>
          </div>
        </div>
      </template>
    </el-dialog>

    <!-- 🔍 全局快捷搜索与高频操作指令面板 (Ctrl + K) -->
    <el-dialog
      v-model="quickCommandVisible"
      title="🔍 全局功能直达与门店快捷指令 (Ctrl + K)"
      width="620px"
      destroy-on-close
      class="quick-command-dialog"
    >
      <div class="qc-container">
        <el-input
          v-model="quickCommandKeyword"
          placeholder="输入功能名称、拼音首字母或业务关键字（如：收银、会员、账本、库存、排班...）"
          size="large"
          clearable
          autofocus
          prefix-icon="Search"
        />

        <div class="qc-section-title">⚡ 高频门店动作一键直达</div>
        <div class="qc-shortcuts-grid">
          <div class="qc-shortcut-card" @click="executeQuickCommand('/cashier')">
            <span class="qc-s-icon">💳</span>
            <div class="qc-s-text">
              <div class="qc-s-name">前台收银结算</div>
              <div class="qc-s-desc">散客/会员开单、扫码与扣卡</div>
            </div>
          </div>
          <div class="qc-shortcut-card" @click="executeQuickCommand('/rooms')">
            <span class="qc-s-icon">🛋️</span>
            <div class="qc-s-text">
              <div class="qc-s-name">{{ storeConfig.spaceAlias }}开单看板</div>
              <div class="qc-s-desc">实时桌台/包厢计时与加单</div>
            </div>
          </div>
          <div class="qc-shortcut-card" @click="executeQuickCommand('/members')">
            <span class="qc-s-icon">👥</span>
            <div class="qc-s-text">
              <div class="qc-s-name">会员开卡与充值</div>
              <div class="qc-s-desc">海马体画像、双轨储值与次卡</div>
            </div>
          </div>
          <div class="qc-shortcut-card" @click="executeQuickCommand('/expenses')">
            <span class="qc-s-icon">📔</span>
            <div class="qc-s-text">
              <div class="qc-s-name">记一笔门店开销</div>
              <div class="qc-s-desc">日常支出流水与全口径成本</div>
            </div>
          </div>
        </div>

        <div class="qc-section-title">🧭 全部模块检索 ({{ filteredQuickCommands.length }})</div>
        <div class="qc-list">
          <div
            v-for="item in filteredQuickCommands"
            :key="item.path"
            class="qc-list-item"
            @click="executeQuickCommand(item.path)"
          >
            <div class="qc-item-left">
              <span class="qc-item-icon">{{ item.icon }}</span>
              <div>
                <div class="qc-item-title">{{ item.title }}</div>
                <div class="qc-item-sub">{{ item.desc }}</div>
              </div>
            </div>
            <div class="qc-item-right">
              <el-tag size="small" type="info" effect="plain">{{ item.category }}</el-tag>
              <span class="qc-enter-hint">跳转 ↵</span>
            </div>
          </div>
          <el-empty v-if="filteredQuickCommands.length === 0" description="未找到匹配的功能模块" :image-size="60" />
        </div>
      </div>
    </el-dialog>
  </el-container>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, h } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useStoreConfig } from '../stores/store'
import { useSystemDataStore } from '../stores/systemDataStore'
import {
  createStoreApi,
  getIndustryCategoriesApi,
  loginApi,
  memberLoginApi,
  getServiceCallsApi,
  handleServiceCallApi,
  getOrderNotificationsApi,
  handleOrderNotificationApi,
  getStoreNoticesApi
} from '../api'
import { ElMessage, ElMessageBox, ElNotification, ElButton } from 'element-plus'
import { isPlatformAdminRole, isTenantBossRole } from '../utils/systemConfig'

const router = useRouter()
const route = useRoute()
const storeConfig = useStoreConfig()
const systemData = useSystemDataStore()
const username = ref(localStorage.getItem('seahorse_user') || '管理员')

// =============================================================================
// 🧭 全局快捷指令面板 (Ctrl + K)
// =============================================================================
const quickCommandVisible = ref(false)
const quickCommandKeyword = ref('')

const openQuickCommandModal = () => {
  quickCommandKeyword.value = ''
  quickCommandVisible.value = true
}

const allQuickCommands = computed(() => [
  { path: '/dashboard', title: '系统首页 · 经营大屏', desc: '全店实时营收、海马熟客动态、预约与耗材预警', icon: '📊', category: '门店前台', keywords: 'dashboard shouye 首页 大盘 营收' },
  { path: '/cashier', title: '前台收银结算中心', desc: '商品服务点单、会员储值/次卡抵扣、组合收款', icon: '💳', category: '门店前台', keywords: 'cashier shouyin 收银 结账 买单 开单' },
  { path: '/rooms', title: `${storeConfig.spaceAlias}开单看板`, desc: `查看全店${storeConfig.spaceAlias}占用状态、计时计费与扫码点单`, icon: '🛋️', category: '门店前台', keywords: 'rooms baoxiang gongwei 包厢 工位 桌台 开台' },
  { path: '/appointments', title: '预约排班日历', desc: '全渠道客户预约登记、技师排班与到店核销', icon: '📅', category: '门店前台', keywords: 'appointments yuyue paiban 预约 排班' },
  { path: '/members', title: '会员中心 · 海马体档案', desc: '会员画像、储值充值、专属喜好记忆与消费轨迹', icon: '👥', category: '客源营销', keywords: 'members huiyuan 会员 充值 储值 档案' },
  { path: '/card-template', title: '会员卡包与次卡管理', desc: '储值卡、次卡、年卡模板配置与办卡激活', icon: '🎫', category: '客源营销', keywords: 'card kabao 会员卡 次卡 年卡' },
  { path: '/marketing', title: '营销裂变与拓客中心', desc: '老带新分销、拼团秒杀、沉睡客唤醒与优惠券', icon: '🚀', category: '客源营销', keywords: 'marketing yingxiao 营销 裂变 优惠券 拓客' },
  { path: '/mall', title: '微信线上商城配置', desc: '小程序在线售卡、团购套餐上架与核销', icon: '🛍️', category: '客源营销', keywords: 'mall shangcheng 商城 小程序 团购' },
  { path: '/sms-records', title: '短信触达与通知管理', desc: '动账提醒、预约通知、生日关怀短信群发记录', icon: '✉️', category: '客源营销', keywords: 'sms duanxin 短信 通知' },
  { path: '/products', title: '项目商品与服务定价', desc: '服务项目、实物商品、套餐BOM配方与提成规则', icon: '📦', category: '货品物资', keywords: 'products shangpin xiangmu 商品 服务 价格' },
  { path: '/inventory', title: '物料库存与智能盘点', desc: '进销存台账、低库存预警、采购入库与BOM扣减', icon: '🏭', category: '货品物资', keywords: 'inventory kucun pandian 库存 物料 盘点 采购' },
  { path: '/expenses', title: '门店账本 · 日常开支记账', desc: '房租水电、耗材采购、杂项报销流水与CSV导出', icon: '📔', category: '财务核算', keywords: 'expenses zhangben 账本 记账 开支 支出 报销' },
  { path: '/cost-center', title: '全口径成本与比重分析', desc: '固定/变动成本占比、六大类目排行与月度预算警戒', icon: '📈', category: '财务核算', keywords: 'cost chengben 成本 预算 利润' },
  { path: '/reports/income', title: '统计报表 · 收入与利润中心', desc: '收入明细、扣卡统计、员工业绩、利润核算11大报表', icon: '📑', category: '财务核算', keywords: 'reports baobiao 报表 统计 业绩 利润' },
  { path: '/staff-management', title: '员工管理与绩效提成', desc: '员工档案、排班考勤、底薪与阶梯提成核算', icon: '🧑‍💼', category: '店务管控', keywords: 'staff yuangong 员工 技师 提成 工资' },
  { path: '/job-posts', title: '部门架构与岗位管理', desc: '门店组织架构、岗位职责与晋升通道设定', icon: '🏢', category: '店务管控', keywords: 'job gangwei 部门 岗位' },
  { path: '/regulations', title: '门店规章制度文库', desc: '标准SOP作业流程、员工手册下发与电子签署', icon: '📜', category: '店务管控', keywords: 'regulations guizhang 规章 制度 公告' },
  { path: '/chain', title: '连锁多店协同管理', desc: '跨店会员通刷结算、分店业绩PK与物资调拨', icon: '🔗', category: '店务管控', keywords: 'chain liansuo 连锁 分店 跨店' },
  { path: '/settings', title: '店铺全局设置与硬件对接', desc: '小票打印机、扫码盒子、高德考勤围栏与营业参数', icon: '⚙️', category: '店务管控', keywords: 'settings shezhi 设置 打印机 硬件' }
])

const filteredQuickCommands = computed(() => {
  const kw = quickCommandKeyword.value.trim().toLowerCase()
  if (!kw) return allQuickCommands.value
  return allQuickCommands.value.filter(item =>
    item.title.toLowerCase().includes(kw) ||
    item.desc.toLowerCase().includes(kw) ||
    item.category.toLowerCase().includes(kw) ||
    item.keywords.toLowerCase().includes(kw)
  )
})

const executeQuickCommand = (path: string) => {
  quickCommandVisible.value = false
  router.push(path)
}

const handleGlobalKeydown = (e: KeyboardEvent) => {
  if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
    e.preventDefault()
    openQuickCommandModal()
  }
}

// =============================================================================
// 🛎️ 包厢现场扫码呼叫管家与新点单（菜品/服务）语音报单及强提醒引擎
// =============================================================================
const pendingServiceCalls = ref<any[]>([])
const pendingOrderNotifications = ref<any[]>([])
const serviceCallsDrawerVisible = ref(false)
const notifiedCallIds = new Set<string>()
const notifiedOrderIds = new Set<string>()

const totalAlertCount = computed(() => pendingServiceCalls.value.length + pendingOrderNotifications.value.length)

// 1. Web Audio API 合成服务铃声 (复用单例 AudioContext，避免多通知句柄泄漏)
let sharedAudioCtx: AudioContext | null = null
const playDingDongChime = () => {
  try {
    const AudioCtx = window.AudioContext || (window as any).webkitAudioContext
    if (!AudioCtx) return
    if (!sharedAudioCtx || sharedAudioCtx.state === 'closed') {
      sharedAudioCtx = new AudioCtx()
    }
    if (sharedAudioCtx.state === 'suspended') {
      sharedAudioCtx.resume().catch(() => {})
    }
    const ctx = sharedAudioCtx
    const now = ctx.currentTime

    // 叮 (D5 587.33Hz)
    const osc1 = ctx.createOscillator()
    const gain1 = ctx.createGain()
    osc1.type = 'sine'
    osc1.frequency.setValueAtTime(587.33, now)
    gain1.gain.setValueAtTime(0.4, now)
    gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.45)
    osc1.connect(gain1)
    gain1.connect(ctx.destination)
    osc1.start(now)
    osc1.stop(now + 0.45)

    // 咚 (A5 880Hz)
    const osc2 = ctx.createOscillator()
    const gain2 = ctx.createGain()
    osc2.type = 'sine'
    osc2.frequency.setValueAtTime(880, now + 0.22)
    gain2.gain.setValueAtTime(0.5, now + 0.22)
    gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.85)
    osc2.connect(gain2)
    gain2.connect(ctx.destination)
    osc2.start(now + 0.22)
    osc2.stop(now + 0.85)
  } catch (e) {
    console.warn('播放叮咚提示音失败:', e)
  }
}

// 2. 语音播报：朗读包厢号、呼叫服务及下单菜品明细 (如：“请注意，烟波致爽包厢新下单：龙井虾仁、清蒸桂鱼”)
const playVoiceAnnouncement = (text: string) => {
  try {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel()
      const utter = new SpeechSynthesisUtterance(text)
      utter.lang = 'zh-CN'
      utter.rate = 1.05
      utter.pitch = 1.1
      utter.volume = 1.0
      window.speechSynthesis.speak(utter)
    }
  } catch (e) {
    console.warn('语音播报失败:', e)
  }
}

const testServiceSound = () => {
  playDingDongChime()
  setTimeout(() => {
    playVoiceAnnouncement('测试订单语音播报：请注意，A01包厢新下单：龙井虾仁、清蒸桂鱼，共两项，请及时备餐出单！')
  }, 350)
  ElMessage.success('已播放测试双音提示铃声与菜品语音报单！')
}

// 3. 轮询后台包厢呼叫服务通知与新订单出餐事件 (APP与浏览器通用，页面隐藏时自动挂起节流)
let serviceCallTimer: any = null
const checkServiceCalls = async () => {
  if (isPlatformDeveloper.value || isCustomerMember.value) return
  if (typeof document !== 'undefined' && document.hidden) return
  const storeId = storeConfig.currentStoreId || 'S001'

  // 1) 检查包厢现场呼叫服务 (加茶水/换骨碟/催单)
  try {
    const res: any = await getServiceCallsApi({ storeId, status: 'PENDING', limit: 20 })
    const list = Array.isArray(res) ? res : (res?.data || [])
    pendingServiceCalls.value = list

    const newCalls = list.filter((c: any) => !notifiedCallIds.has(c.id))
    if (newCalls.length > 0) {
      for (const call of newCalls) {
        notifiedCallIds.add(call.id)

        playDingDongChime()
        setTimeout(() => {
          playVoiceAnnouncement(`请注意，${call.spaceName}呼叫${call.serviceType}`)
        }, 300)

        ElNotification({
          title: `🛎️ 包厢呼叫：${call.serviceType}`,
          message: `【${call.spaceName} (${call.spaceCode})】呼叫服务：${call.serviceType}，请前台/服务员及时前往处理！`,
          type: 'warning',
          duration: 12000,
          position: 'top-right'
        })
      }
    }
  } catch (e) {}

  // 2) 检查包厢/桌台新点单与出单语音报单 (报出菜品、服务、商品明细)
  try {
    const orderRes: any = await getOrderNotificationsApi({ storeId, status: 'PENDING', limit: 20 })
    const orderList = Array.isArray(orderRes) ? orderRes : (orderRes?.data || [])
    pendingOrderNotifications.value = orderList

    const newOrders = orderList.filter((o: any) => !notifiedOrderIds.has(o.id))
    if (newOrders.length > 0) {
      for (const order of newOrders) {
        notifiedOrderIds.add(order.id)

        playDingDongChime()
        setTimeout(() => {
          playVoiceAnnouncement(order.broadcastText || `请注意，${order.spaceName}新下单：${order.itemNamesSummary}`)
        }, 350)

        ElNotification({
          title: `🍲 新订单出单：${order.spaceName}`,
          message: `${order.broadcastText} (总金额: ￥${Number(order.totalAmount || 0).toFixed(2)})`,
          type: 'success',
          duration: 15000,
          position: 'top-right'
        })
      }
    }
  } catch (e) {}

  // 3) 检查当前门店最新生效规章制度与日常公告 (全端实时推送强提醒，无需手动刷新)
  await checkStoreNotices()
}

// =============================================================================
// 📜 门店规章制度与运营规范全渠道跨端推送强提醒引擎 (全端免刷新实时响应)
// =============================================================================
const noticeModalVisible = ref(false)
const currentAlertNotice = ref<any>(null)
const isNoticeInitLoaded = ref(false)

const getStoredNotifiedNoticeIds = (): Set<string> => {
  try {
    const raw = localStorage.getItem('seahorse_notified_notice_ids')
    if (raw) {
      return new Set(JSON.parse(raw))
    }
  } catch (e) {}
  return new Set()
}

const saveStoredNotifiedNoticeIds = (ids: Set<string>) => {
  try {
    localStorage.setItem('seahorse_notified_notice_ids', JSON.stringify(Array.from(ids).slice(-200)))
  } catch (e) {}
}

const checkStoreNotices = async () => {
  if (isPlatformDeveloper.value || isCustomerMember.value) return
  const storeId = storeConfig.currentStoreId || 'S001'
  try {
    const res: any = await getStoreNoticesApi(storeId)
    const list = Array.isArray(res) ? res : (res?.data || [])
    if (!Array.isArray(list) || list.length === 0) return

    const storedIds = getStoredNotifiedNoticeIds()

    // 首次进入系统时，将线上已有历史规章与公告标记为已知，防止用户登录时出现弹窗轰炸
    if (!isNoticeInitLoaded.value) {
      list.forEach((n: any) => {
        if (n.id) storedIds.add(String(n.id))
      })
      saveStoredNotifiedNoticeIds(storedIds)
      isNoticeInitLoaded.value = true
      return
    }

    // 检测新增发布的规章制度或日常公告
    const newNotices = list.filter((n: any) => n.id && !storedIds.has(String(n.id)))
    if (newNotices.length > 0) {
      for (const notice of newNotices) {
        storedIds.add(String(notice.id))
        saveStoredNotifiedNoticeIds(storedIds)

        // 触发提示音与语音朗读
        playDingDongChime()
        setTimeout(() => {
          if (notice.isUrgent) {
            playVoiceAnnouncement(`特急重要通知提醒：${notice.title}`)
          } else {
            playVoiceAnnouncement(`请注意，门店发布了最新规章制度：${notice.title}`)
          }
        }, 350)

        // 右侧高亮通知卡片弹窗
        ElNotification({
          title: notice.isUrgent ? `🚨 特急重要通知：${notice.title}` : `📜 门店新规章制度发布：${notice.title}`,
          message: h('div', { style: 'font-size: 13px; line-height: 1.6; color: #334155;' }, [
            h('div', { style: 'display: flex; gap: 6px; align-items: center; margin-bottom: 6px;' }, [
              h('span', { style: 'background: #e0f2fe; color: #0284c7; padding: 2px 6px; border-radius: 4px; font-size: 11px; font-weight: bold;' }, notice.categoryName || '规章制度'),
              h('span', { style: 'background: #f1f5f9; color: #64748b; padding: 2px 6px; border-radius: 4px; font-size: 11px;' }, notice.version || 'V1.0'),
              notice.requireSignature ? h('span', { style: 'background: #fee2e2; color: #ef4444; padding: 2px 6px; border-radius: 4px; font-size: 11px; font-weight: bold;' }, '✍️ 需手写签署') : null
            ]),
            h('p', { style: 'margin: 4px 0; color: #475569;' }, notice.summary || notice.title),
            h('div', { style: 'margin-top: 10px; display: flex; justify-content: flex-end;' }, [
              h(ElButton, {
                size: 'small',
                type: 'primary',
                onClick: () => handleOpenRegulationModal(notice)
              }, () => '📄 立即查阅细则')
            ])
          ]),
          type: notice.isUrgent ? 'error' : 'warning',
          duration: notice.requireSignature || notice.isUrgent ? 0 : 15000,
          position: 'top-right'
        })

        // 若要求强制手写签字确认或特急通知，直接自动全屏置顶弹窗展示规章细则
        if (notice.requireSignature || notice.isUrgent) {
          handleOpenRegulationModal(notice)
        }

        // 向浏览器内部派发全局事件，通知各子页面（规章制度文库、工作台等）即时同步，免去手动刷新
        window.dispatchEvent(new CustomEvent('seahorse-notice-updated', { detail: notice }))
      }
    }
  } catch (e) {}
}

const handleOpenRegulationModal = (notice: any) => {
  currentAlertNotice.value = notice
  noticeModalVisible.value = true
}

const handleGoToRegulations = () => {
  noticeModalVisible.value = false
  router.push('/regulations')
}

const handleMarkServiceCall = async (id: string) => {
  try {
    await handleServiceCallApi(id)
    pendingServiceCalls.value = pendingServiceCalls.value.filter((c: any) => c.id !== id)
    ElMessage.success('已标记该呼叫为已处理')
  } catch (e: any) {
    ElMessage.error(e?.message || '处理呼叫失败')
  }
}

const handleMarkOrderNotification = async (id: string) => {
  try {
    await handleOrderNotificationApi(id)
    pendingOrderNotifications.value = pendingOrderNotifications.value.filter((o: any) => o.id !== id)
    ElMessage.success('已标记该订单为已出单备餐')
  } catch (e: any) {
    ElMessage.error(e?.message || '受理订单失败')
  }
}

import {
  getTenantQuota,
  saveTenantQuota,
  lockTenant,
  unlockTenant,
  rechargeTenantStorage,
  rechargeTenantApiCalls,
  upgradeToAnnualPlan,
  QUOTA_TIER_STANDARDS,
  RECHARGE_PACKAGES,
  type TenantQuotaData
} from '../utils/tenantQuotaService'

// 租户云端存储空间与接口操作配额管理
const tenantQuota = ref<TenantQuotaData>(getTenantQuota())

// 页面是否处于超额阻断锁屏保护中 (支持刷新即时自愈)
const isPageLocked = computed(() => {
  if (isPlatformDeveloper.value) return false
  // 若商户已被超级管理员禁用或注销，工作台立即进入冻结锁屏状态
  if (storeConfig.status === 'DISABLED' || storeConfig.status === 'DELETED') {
    return true
  }
  // 商业正式版租户（黑金旗舰版、星光专业版、私有化企业定制版）绝不阻断锁屏
  if (storeConfig.plan && storeConfig.plan !== 'TRIAL') {
    if (tenantQuota.value?.isLocked && tenantQuota.value?.lockReason?.includes('测试模式')) {
      return true
    }
    return false
  }
  // 体验版如果在有效体验期内（trialDaysRemaining > 0），且非测试主动模拟锁屏，自动放行
  if (storeConfig.isTrial && storeConfig.trialDaysRemaining > 0 && !tenantQuota.value?.lockReason?.includes('测试模式')) {
    return false
  }
  return Boolean(tenantQuota.value?.isLocked)
})
const quotaModalVisible = ref(false)
const activeQuotaTab = ref('STORAGE')

const storageUsagePercent = computed(() => {
  const total = Number(tenantQuota.value?.totalStorageMb ?? tenantQuota.value?.storageQuotaMb) || 0
  const used = Number(tenantQuota.value?.usedStorageMb ?? tenantQuota.value?.storageUsedMb) || 0
  if (total <= 0) return 0
  const pct = Math.round((used / total) * 100)
  if (isNaN(pct)) return 0
  return Math.min(100, Math.max(0, pct))
})

const apiUsagePercent = computed(() => {
  const total = Number(tenantQuota.value?.totalApiCalls) || 0
  const used = Number(tenantQuota.value?.usedApiCalls ?? tenantQuota.value?.apiCallsMonthly) || 0
  if (total <= 0) return 0
  const pct = Math.round((used / total) * 100)
  if (isNaN(pct)) return 0
  return Math.min(100, Math.max(0, pct))
})

const formatStorage = (mb: any) => {
  const num = Number(mb)
  if (isNaN(num) || num <= 0) {
    return '0 MB'
  }
  if (num >= 1024) {
    return `${(num / 1024).toFixed(1)} GB`
  }
  return `${Math.round(num)} MB`
}

const openQuotaModal = () => {
  tenantQuota.value = getTenantQuota()
  quotaModalVisible.value = true
}

const handleRechargeStorage = (pack: any) => {
  rechargeTenantStorage(undefined, pack.name, pack.price, pack.storageMb)
  tenantQuota.value = getTenantQuota()
  ElMessage.success(`🎉 充值成功！已成功扩容 ${formatStorage(pack.storageMb)} 云端存储空间，工作台已全面解除锁定并恢复正常操作！`)
  quotaModalVisible.value = false
}

const handleRechargeApiCalls = (pack: any) => {
  rechargeTenantApiCalls(undefined, pack.name, pack.price, pack.calls)
  tenantQuota.value = getTenantQuota()
  ElMessage.success(`🎉 充值成功！已成功增加 ${pack.calls.toLocaleString()} 次接口操作配额，系统已解除锁定！`)
  quotaModalVisible.value = false
}

const handleUpgradeAnnual = (p: any) => {
  upgradeToAnnualPlan(undefined, p.code, p.name, p.price, p.storageMb, p.calls)
  tenantQuota.value = getTenantQuota()
  ElMessage.success(`🎉 恭喜！已成功升级为【${p.name}】，赠送专属海量存储与接口调用，工作台锁定已全面解除！`)
  quotaModalVisible.value = false
}

const handleTestQuickLock = () => {
  lockTenant(undefined, '云端存储空间已达上限 (100%)，页面所有写操作已被安全锁定保护。')
  tenantQuota.value = getTenantQuota()
  ElMessage.error('⚠️ [测试模式] 已成功模拟存储空间耗尽！工作台已进入只读受限保护状态，页面写操作已锁定。')
}

const handleTestQuickUnlock = () => {
  unlockTenant(undefined)
  tenantQuota.value = getTenantQuota()
  ElMessage.success('🎉 [测试模式] 已应急解除页面锁定，并自动赠送应急缓冲空间！工作台恢复正常操作。')
}

const handleQuotaUpdatedEvent = (e: any) => {
  if (e?.detail) {
    tenantQuota.value = e.detail
  }
}

onMounted(() => {
  tenantQuota.value = getTenantQuota()
  if (typeof window !== 'undefined') {
    window.addEventListener('seahorse-quota-updated', handleQuotaUpdatedEvent)
  }
})

const activeNavPath = computed(() => {
  if (route.path.startsWith('/reports')) {
    if (route.params.tab) {
      return `/reports/${route.params.tab}`
    }
    if (route.query.tab) {
      return `/reports/${route.query.tab}`
    }
    return '/reports/income'
  }
  if (route.path === '/cost-center') {
    return '/expenses'
  }
  if (route.path === '/vendor') {
    return '/vendor-tenants'
  }
  return route.path
})

const currentSpaceAliasTitle = computed(() => {
  return storeConfig.spaceAlias || localStorage.getItem('seahorse_custom_space_alias') || '包厢'
})

const spaceMenuIcon = computed(() => {
  const name = currentSpaceAliasTitle.value
  if (name.includes('工位') || name.includes('修') || name.includes('车')) {
    return 'tools'
  }
  if (name.includes('展') || name.includes('柜') || name.includes('台') || name.includes('位')) {
    return 'shop'
  }
  return 'house'
})

const role = ref(localStorage.getItem('seahorse_role') || 'SUPER_ADMIN')
const permissions = ref<string[]>([])

try {
  permissions.value = JSON.parse(localStorage.getItem('seahorse_permissions') || '[]')
} catch {
  permissions.value = []
}

const isPlatformDeveloper = computed(() =>
  role.value === 'PLATFORM_DEVELOPER' || role.value === 'PLATFORM_ADMIN' || role.value === 'PLATFORM_SUPER_ADMIN'
)
const isMerchantBoss = computed(() => isTenantBossRole(role.value))
const isSuperAdmin = computed(() => {
  const r = localStorage.getItem('seahorse_role') || role.value || ''
  return isPlatformAdminRole(r, localStorage.getItem('seahorse_username')) || r === 'SUPER_ADMIN'
})
const isCustomerMember = computed(() => role.value === 'CUSTOMER_MEMBER')

const currentRoleDisplayName = computed(() => {
  const indMap: Record<string, string> = {
    BEAUTY: '美业老板 (海马造型)',
    RESTAURANT: '餐饮老板 (栖枫悦食)',
    AUTO: '汽修老板 (极速动力)',
    RETAIL: '零售老板 (云缦甄选)'
  }
  if (role.value === 'SUPER_ADMIN' || role.value === 'MERCHANT_ADMIN' || role.value === 'TENANT_ADMIN') {
    return indMap[storeConfig.industry] || '租户老板'
  }
  const map: Record<string, string> = {
    PLATFORM_DEVELOPER: '开发维护人',
    SUPER_ADMIN: '门店老板',
    MERCHANT_ADMIN: '租户老板',
    TENANT_ADMIN: '租户老板',
    STORE_MANAGER: '旗舰店长',
    CASHIER: '前台收银',
    TECHNICIAN: '托尼老师',
    CUSTOMER_MEMBER: '顾客会员'
  }
  return map[role.value] || role.value
})

const userAvatarText = computed(() => {
  if (isPlatformDeveloper.value) return '开'
  if (isCustomerMember.value) return '客'
  if (isMerchantBoss.value) return '商'
  return username.value.substring(0, 1) || '职'
})

const avatarBgColor = computed(() => {
  if (isPlatformDeveloper.value) return '#ef4444'
  if (isCustomerMember.value) return '#ec4899'
  if (isMerchantBoss.value) return '#8b5cf6'
  return '#0d9488'
})

const hasPerm = (code: string) => {
  if (isPlatformDeveloper.value) return false
  if (isMerchantBoss.value) return true
  return permissions.value.includes(code)
}

// =========================================================================
// 非研发人员向平台研发团队建言反馈表单状态与提交
// =========================================================================
const feedbackModalVisible = ref(false)
const submittingFeedback = ref(false)
const feedbackFormRef = ref<any>(null)

const feedbackForm = ref({
  type: 'FEATURE_REQUEST' as any,
  module: '门店前台',
  title: '',
  content: '',
  urgency: 'NORMAL' as any,
  phone: ''
})

const feedbackRules = {
  title: [{ required: true, message: '请输入建议/需求标题', trigger: 'blur' }],
  content: [{ required: true, message: '请详细描述具体业务场景与期望效果', trigger: 'blur' }]
}

const openPlatformFeedbackModal = () => {
  feedbackForm.value = {
    type: 'FEATURE_REQUEST',
    module: '门店前台',
    title: '',
    content: '',
    urgency: 'NORMAL',
    phone: ''
  }
  feedbackModalVisible.value = true
}

const handleSubmitPlatformFeedback = async () => {
  if (!feedbackFormRef.value) return
  await feedbackFormRef.value.validate(async (valid: boolean) => {
    if (!valid) return
    submittingFeedback.value = true
    try {
      const typeNameMap: Record<string, string> = {
        FEATURE_REQUEST: '新功能需求',
        EXPERIENCE_OPT: '体验优化',
        BUG_REPORT: '缺陷反馈',
        BUSINESS_IDEA: '商业方案'
      }

      systemData.submitPlatformFeedback({
        id: `PFB-${Date.now().toString().slice(-6)}`,
        tenantId: storeConfig.tenantId || localStorage.getItem('seahorse_tenant_id') || 'T001',
        tenantName: localStorage.getItem('seahorse_tenant_name') || storeConfig.storeName || '海马智慧商业连锁',
        storeName: storeConfig.storeName || '当前经营门店',
        staffName: username.value || '当前店员',
        role: role.value || 'STAFF',
        roleName: currentRoleDisplayName.value || '店员',
        phone: feedbackForm.value.phone || '',
        type: feedbackForm.value.type,
        typeName: typeNameMap[feedbackForm.value.type] || '业务建言',
        module: feedbackForm.value.module,
        title: feedbackForm.value.title.trim(),
        content: feedbackForm.value.content.trim(),
        urgency: feedbackForm.value.urgency,
        createdAt: new Date().toLocaleString(),
        status: 'PENDING'
      })

      ElMessage.success('🎉 您的宝贵建言已直达系统研发团队！感谢您帮助系统变得更好！')
      feedbackModalVisible.value = false
    } catch (e: any) {
      ElMessage.error(e.message || '提交失败，请稍后重试')
    } finally {
      submittingFeedback.value = false
    }
  })
}

// 员工可见与可用页签权限控制
const userMenuPaths = ref<string[]>([])
try {
  const raw = localStorage.getItem('seahorse_user_menu_paths')
  if (raw) {
    userMenuPaths.value = JSON.parse(raw)
  }
} catch {
  userMenuPaths.value = []
}

// 员工被授权的执业门店
const userAllowedStores = ref<string[]>([])
try {
  const rawStores = localStorage.getItem('seahorse_allowed_stores')
  if (rawStores) {
    userAllowedStores.value = JSON.parse(rawStores)
  }
} catch {
  userAllowedStores.value = []
}

const isMenuAllowed = (menuPath: string) => {
  // 0. 扫码盒与支付通道、高德考勤总控：仅开发维护人/平台超级管理员可配置
  if (menuPath === '/payment-settings' || menuPath === '/map-settings') {
    return isPlatformDeveloper.value
  }
  // 1. 租户老板或系统开发商拥有全量豁免权限
  if (isMerchantBoss.value || isPlatformDeveloper.value) {
    return true
  }
  // 2. 个人中心与门店规章制度（含员工意见箱与建言）始终对所有登录员工开放
  if (menuPath === '/profile' || menuPath === '/regulations') {
    return true
  }
  // 3. 如果员工配置了具体的可见页签白名单
  if (userMenuPaths.value && userMenuPaths.value.length > 0) {
    return userMenuPaths.value.includes(menuPath)
  }
  // 4. 若未单独配置页签白名单，默认允许
  return true
}

const isAnyMenuAllowed = (paths: string[]) => {
  return paths.some(p => isMenuAllowed(p))
}

const isNewTenant = computed(() => {
  return localStorage.getItem('seahorse_is_new_tenant') === 'true' ||
    (storeConfig.tenantId && storeConfig.tenantId !== 'T001' && storeConfig.tenantId !== 'T002' && storeConfig.tenantId !== 'PLATFORM')
})

const showDemoRoleSwitcher = computed(() => false)

// 员工是否具备跨店铺权限
const canCrossStore = ref(false)
try {
  canCrossStore.value = localStorage.getItem('seahorse_can_cross_store') === 'true'
} catch {
  canCrossStore.value = false
}

const availableStoresForCurrentUser = computed(() => {
  const isCustomTenant = storeConfig.tenantId && storeConfig.tenantId !== 'T001' && storeConfig.tenantId !== 'PLATFORM'
  const sourceStores = (isCustomTenant || isNewTenant.value)
    ? (storeConfig.stores && storeConfig.stores.length > 0 ? storeConfig.stores : [])
    : (storeConfig.stores && storeConfig.stores.length > 0 ? storeConfig.stores : systemData.stores)

  // 1. 租户老板或平台开发商拥有全量跨店漫游豁免权限
  if (isMerchantBoss.value || isPlatformDeveloper.value) {
    return sourceStores
  }

  // 2. 若员工被明确配置了跨店铺权限，则允许查看全部门店
  if (canCrossStore.value) {
    return sourceStores
  }

  // 3. 员工未配置跨店权限：严格限制仅能查看当前配置被授权可使用的店铺
  if (userAllowedStores.value && userAllowedStores.value.length > 0) {
    const filtered = sourceStores.filter((s: any) => userAllowedStores.value.includes(s.storeId))
    if (filtered.length > 0) {
      return filtered
    }
  }

  // 4. 若未单独配置授权店铺，默认锁定当前单店，严禁跨店访问
  if (storeConfig.currentStoreId) {
    const matched = sourceStores.filter((s: any) => s.storeId === storeConfig.currentStoreId)
    if (matched.length > 0) return matched
  }

  return sourceStores.slice(0, 1)
})

// 多门店智能切换中心状态与逻辑
const storeSwitcherVisible = ref(false)
const storeSearchKeyword = ref('')

const getStoreIndustryDesc = (s: any) => {
  if (s.industryCategoryName) return s.industryCategoryName
  if (s.industryDesc) return s.industryDesc
  const ind = s.industry || storeConfig.industry
  const map: Record<string, string> = {
    BEAUTY: '美业造型',
    RESTAURANT: '餐饮美食',
    AUTO: '汽车养护',
    RETAIL: '轻奢零售',
    FOOT_SPA: '足疗养生',
    TEA_HOUSE: '茶空间雅座',
    PET: '萌宠洗护'
  }
  const name = s.storeName || ''
  if (name.includes('火锅') || name.includes('餐') || name.includes('茶') || name.includes('酒')) return '餐饮美食'
  if (name.includes('美业') || name.includes('造型') || name.includes('发') || name.includes('美甲') || name.includes('养生')) return '美业造型'
  if (name.includes('车') || name.includes('养护') || name.includes('汽修') || name.includes('动力')) return '汽车养护'
  if (name.includes('甄选') || name.includes('美学') || name.includes('生活') || name.includes('零售') || name.includes('商行')) return '轻奢零售'
  return map[ind] || '品质门店'
}

const getStoreIndustryEmoji = (s: any) => {
  const desc = getStoreIndustryDesc(s)
  const name = s.storeName || ''
  if (desc.includes('美业') || desc.includes('造型') || name.includes('美业') || name.includes('造型')) return '💇‍♀️'
  if (desc.includes('餐') || desc.includes('火锅') || name.includes('火锅') || name.includes('餐')) return '🍲'
  if (desc.includes('车') || desc.includes('养护') || name.includes('车') || name.includes('养护')) return '🚗'
  if (desc.includes('零售') || desc.includes('美学') || desc.includes('甄选') || name.includes('美学') || name.includes('甄选')) return '🛍️'
  return '🏬'
}

const getStoreIndustryAvatarClass = (s: any) => {
  const desc = getStoreIndustryDesc(s)
  if (desc.includes('美业') || desc.includes('造型')) return 'avatar-beauty'
  if (desc.includes('餐') || desc.includes('火锅')) return 'avatar-restaurant'
  if (desc.includes('车') || desc.includes('养护')) return 'avatar-auto'
  if (desc.includes('零售') || desc.includes('美学') || desc.includes('甄选')) return 'avatar-retail'
  return 'avatar-default'
}

const getStoreIndustryBadgeClass = (s: any) => {
  const desc = getStoreIndustryDesc(s)
  if (desc.includes('美业') || desc.includes('造型')) return 'badge-beauty'
  if (desc.includes('餐') || desc.includes('火锅')) return 'badge-restaurant'
  if (desc.includes('车') || desc.includes('养护')) return 'badge-auto'
  if (desc.includes('零售') || desc.includes('美学') || desc.includes('甄选')) return 'badge-retail'
  return 'badge-default'
}

const currentStoreEmoji = computed(() => {
  const curStore = availableStoresForCurrentUser.value.find((s: any) => s.storeId === storeConfig.currentStoreId)
  if (curStore) {
    return getStoreIndustryEmoji(curStore)
  }
  return '🏬'
})

const currentStoreSubText = computed(() => {
  const curStore = availableStoresForCurrentUser.value.find((s: any) => s.storeId === storeConfig.currentStoreId)
  if (curStore) {
    return getStoreIndustryDesc(curStore)
  }
  return storeConfig.industryCategoryName || ''
})

const filteredStores = computed(() => {
  const q = storeSearchKeyword.value.trim().toLowerCase()
  if (!q) {
    return availableStoresForCurrentUser.value
  }
  return availableStoresForCurrentUser.value.filter((s: any) => {
    const name = (s.storeName || '').toLowerCase()
    const id = (s.storeId || '').toLowerCase()
    const addr = (s.address || '').toLowerCase()
    const desc = getStoreIndustryDesc(s).toLowerCase()
    return name.includes(q) || id.includes(q) || addr.includes(q) || desc.includes(q)
  })
})

const selectAndSwitchStore = async (storeId: string) => {
  storeSwitcherVisible.value = false
  if (storeId === storeConfig.currentStoreId) {
    return
  }
  await storeConfig.switchStore(storeId)
  ElMessage.success('已切换至门店：' + storeConfig.storeName)
  router.go(0)
}

const openCreateStoreModal = () => {
  storeSwitcherVisible.value = false
  handleStoreCommand('create_store')
}

// 新租户入驻开店与行业细分初始化向导
const onboardingVisible = ref(false)
const submittingOnboarding = ref(false)
const categoryGroups = ref<any[]>([])
const onboardingSelectedGroup = ref('服务类')

const onboardingForm = ref({
  storeName: '',
  industryCategoryId: null as number | null,
  industryCategoryName: '',
  industryCategoryGroup: '服务类',
  industry: 'BEAUTY',
  phone: '',
  address: '',
  businessHours: '09:00 - 22:00'
})

const availableCategoriesForSelectedGroup = computed(() => {
  const grp = categoryGroups.value.find(g => g.name === onboardingSelectedGroup.value)
  return grp ? grp.data : []
})

const handleGroupChange = () => {
  onboardingForm.value.industryCategoryId = null
  onboardingForm.value.industryCategoryName = ''
  onboardingForm.value.industryCategoryGroup = onboardingSelectedGroup.value
  onboardingForm.value.industry = onboardingSelectedGroup.value === '零售类' ? 'RETAIL' : 'BEAUTY'
}

const handleCategoryChange = (val: number) => {
  const item = availableCategoriesForSelectedGroup.value.find((c: any) => c.id === val)
  if (item) {
    onboardingForm.value.industryCategoryId = item.id
    onboardingForm.value.industryCategoryName = item.name
    onboardingForm.value.industryCategoryGroup = onboardingSelectedGroup.value
    onboardingForm.value.industry = item.defaultIndustryType || (onboardingSelectedGroup.value === '零售类' ? 'RETAIL' : 'BEAUTY')
  }
}

const loadIndustryCategoriesList = async () => {
  try {
    const res: any = await getIndustryCategoriesApi()
    if (res && res.all) {
      categoryGroups.value = res.all
    }
  } catch (e) {
    console.error('加载行业分类失败', e)
  }
}

const openOnboardingModal = () => {
  onboardingVisible.value = true
}

const handleSubmitOnboarding = async () => {
  if (!onboardingForm.value.storeName?.trim()) {
    ElMessage.warning('请输入店铺招牌全称')
    return
  }
  if (!onboardingForm.value.industryCategoryId) {
    ElMessage.warning('请选择细分行业品类')
    return
  }
  if (!onboardingForm.value.phone?.trim()) {
    ElMessage.warning('请输入门店联系电话')
    return
  }
  if (!onboardingForm.value.address?.trim()) {
    ElMessage.warning('请输入门店详细经营地址')
    return
  }

  submittingOnboarding.value = true
  try {
    const res: any = await createStoreApi({
      storeName: onboardingForm.value.storeName.trim(),
      industry: onboardingForm.value.industry,
      industryCategoryId: onboardingForm.value.industryCategoryId,
      industryCategoryName: onboardingForm.value.industryCategoryName,
      industryCategoryGroup: onboardingForm.value.industryCategoryGroup,
      phone: onboardingForm.value.phone.trim(),
      address: onboardingForm.value.address.trim(),
      businessHours: onboardingForm.value.businessHours || '09:00 - 22:00'
    })
    ElMessage.success('首家门店基本信息与主营行业配置成功！已进入专属工作台')
    onboardingVisible.value = false
    localStorage.removeItem('seahorse_is_new_tenant')
    if (onboardingForm.value.storeName) {
      localStorage.setItem('seahorse_store_name', onboardingForm.value.storeName.trim())
      storeConfig.storeName = onboardingForm.value.storeName.trim()
    }
    if (onboardingForm.value.industryCategoryName) {
      localStorage.setItem('seahorse_industry_category', onboardingForm.value.industryCategoryName)
      storeConfig.industryCategoryName = onboardingForm.value.industryCategoryName
    }
    await storeConfig.loadStores()
    if (res && res.storeId) {
      await storeConfig.switchStore(res.storeId)
    } else {
      await storeConfig.fetchIndustry()
    }
    router.go(0)
  } catch (e: any) {
    ElMessage.error(e.message || '开店初始化失败')
  } finally {
    submittingOnboarding.value = false
  }
}

const createStoreVisible = ref(false)
const creatingStore = ref(false)
const createStoreCascaderValue = ref<any[]>([])

const createStoreCascaderOptions = computed(() => {
  if (categoryGroups.value && categoryGroups.value.length > 0) {
    return categoryGroups.value.map(g => ({
      value: g.name,
      label: g.name,
      children: (g.data || []).map((item: any) => ({
        value: item.id,
        label: item.name,
        groupName: g.name,
        defaultIndustryType: item.defaultIndustryType
      }))
    }))
  }
  return [
    {
      value: '服务类',
      label: '服务类',
      children: [
        { value: 1, label: '美业服务', groupName: '服务类', defaultIndustryType: 'BEAUTY' },
        { value: 2, label: '汽车服务', groupName: '服务类', defaultIndustryType: 'AUTO' },
        { value: 3, label: '餐饮美食', groupName: '服务类', defaultIndustryType: 'RESTAURANT' }
      ]
    },
    {
      value: '零售类',
      label: '零售类',
      children: [
        { value: 10, label: '专营零售', groupName: '零售类', defaultIndustryType: 'RETAIL' },
        { value: 11, label: '生活美学', groupName: '零售类', defaultIndustryType: 'RETAIL' }
      ]
    }
  ]
})

const createStoreForm = ref({
  storeName: '',
  industry: 'BEAUTY',
  industryCategoryId: null as number | null,
  industryCategoryName: '',
  industryCategoryGroup: '服务类',
  phone: '',
  address: '',
  manager: '',
  businessHours: '09:00 - 22:00'
})

const handleCreateStoreCascaderChange = (vals: any[]) => {
  if (vals && vals.length === 2) {
    createStoreForm.value.industryCategoryGroup = vals[0]
    createStoreForm.value.industryCategoryId = vals[1]
    const group = createStoreCascaderOptions.value.find(g => g.value === vals[0])
    const child = group?.children?.find((c: any) => c.value === vals[1])
    if (child) {
      createStoreForm.value.industryCategoryName = child.label
      createStoreForm.value.industry = child.defaultIndustryType || (vals[0] === '零售类' ? 'RETAIL' : 'BEAUTY')
    }
  } else {
    createStoreForm.value.industryCategoryId = null
    createStoreForm.value.industryCategoryName = ''
  }
}

const industryTagType = computed(() => {
  switch (storeConfig.industry) {
    case 'BEAUTY': return 'success'
    case 'RESTAURANT': return 'warning'
    case 'AUTO': return 'primary'
    default: return 'info'
  }
})

const planName = computed(() => {
  switch (storeConfig.plan) {
    case 'TRIAL': return '体验版套餐'
    case 'PROFESSIONAL': return '专业版套餐'
    case 'FLAGSHIP': return '旗舰版套餐'
    case 'ENTERPRISE': return '企业定制版'
    default: return '旗舰版套餐'
  }
})

const deductModeName = computed(() => {
  return storeConfig.deductMode === 'PRINCIPAL_FIRST' ? '优先本金扣减' : '本金/赠金双轨扣减'
})

const planBadgeConfig = computed(() => {
  switch (storeConfig.plan) {
    case 'TRIAL':
      return {
        icon: '🎁',
        name: 'SaaS 体验版',
        subText: `剩余 ${storeConfig.trialDaysRemaining} 天`,
        badgeClass: 'badge-plan-trial'
      }
    case 'PROFESSIONAL':
      return {
        icon: '💎',
        name: '星光专业版',
        subText: 'PRO',
        badgeClass: 'badge-plan-pro'
      }
    case 'ENTERPRISE':
      return {
        icon: '🏛️',
        name: '企业定制版',
        subText: 'ENT',
        badgeClass: 'badge-plan-enterprise'
      }
    case 'FLAGSHIP':
    default:
      return {
        icon: '👑',
        name: '黑金旗舰版',
        subText: 'MAX',
        badgeClass: 'badge-plan-flagship'
      }
  }
})

let isLayoutUnmounted = false
const handleWindowFocusSync = () => {
  if (!isPlatformDeveloper.value && !isCustomerMember.value) {
    storeConfig.fetchCurrentSubscription().then(() => {
      if (!isLayoutUnmounted) {
        tenantQuota.value = getTenantQuota()
      }
    })
  }
}

const handleVisibilityChange = () => {
  if (typeof document !== 'undefined' && !document.hidden) {
    void checkServiceCalls()
  }
}

onMounted(async () => {
  isLayoutUnmounted = false
  window.addEventListener('keydown', handleGlobalKeydown)
  document.addEventListener('visibilitychange', handleVisibilityChange)
  // 如果是开发维护人，且当前在dashboard或根路径，重定向到全平台大盘概览
  if (isPlatformDeveloper.value && (router.currentRoute.value.path === '/dashboard' || router.currentRoute.value.path === '/')) {
    router.replace('/platform-dashboard')
    return
  }
  // 如果是顾客会员，且当前在dashboard，重定向到member-portal
  if (isCustomerMember.value && (router.currentRoute.value.path === '/dashboard' || router.currentRoute.value.path === '/')) {
    router.replace('/member-portal')
    return
  }

  if (!isPlatformDeveloper.value && !isCustomerMember.value) {
    await storeConfig.fetchCurrentSubscription()
    await storeConfig.fetchIndustry()
    await storeConfig.loadStores()
    await loadIndustryCategoriesList()

    // 确保无论何种套餐版本，页面初始化时自动依据最新状态同步配额并解除旧限制
    tenantQuota.value = getTenantQuota()

    const hasExistingStores = (storeConfig.stores && storeConfig.stores.length > 0) ||
                              (availableStoresForCurrentUser.value && availableStoresForCurrentUser.value.length > 0)

    // 如果已有门店，确保 Pinia 状态中门店名和行业名称已与当前门店同步
    if (hasExistingStores) {
      const cur = (storeConfig.stores && storeConfig.stores.find((s: any) => s.storeId === storeConfig.currentStoreId)) ||
                  (storeConfig.stores && storeConfig.stores[0]) ||
                  (availableStoresForCurrentUser.value && availableStoresForCurrentUser.value[0])
      if (cur) {
        if (!storeConfig.storeName && cur.storeName) {
          storeConfig.storeName = cur.storeName
          localStorage.setItem('seahorse_store_name', cur.storeName)
        }
        if (!storeConfig.industryCategoryName && (cur.industryCategoryName || cur.industryDesc)) {
          storeConfig.industryCategoryName = cur.industryCategoryName || cur.industryDesc
          localStorage.setItem('seahorse_industry_category', storeConfig.industryCategoryName)
        }
      }
    }

    // 仅在真实无任何门店的全新未开店租户老板登录时，才强制弹出开店初始化向导
    if (isMerchantBoss.value && !hasExistingStores) {
      openOnboardingModal()
    }

    if (isLayoutUnmounted) return

    // 开启包厢现场呼叫管家与服务实时监听与声音播报 (4秒轮询)
    checkServiceCalls()
    serviceCallTimer = setInterval(checkServiceCalls, 4000)

    // 监听窗口重新获得焦点，自动静默同步最新套餐与配额，杜绝超管升级后租户端有延迟
    window.addEventListener('focus', handleWindowFocusSync)
  }
})

onUnmounted(() => {
  isLayoutUnmounted = true
  window.removeEventListener('keydown', handleGlobalKeydown)
  document.removeEventListener('visibilitychange', handleVisibilityChange)
  window.removeEventListener('seahorse-quota-updated', handleQuotaUpdatedEvent)
  window.removeEventListener('focus', handleWindowFocusSync)
  if (serviceCallTimer) {
    clearInterval(serviceCallTimer)
    serviceCallTimer = null
  }
  if (sharedAudioCtx && sharedAudioCtx.state !== 'closed') {
    sharedAudioCtx.close().catch(() => {})
    sharedAudioCtx = null
  }
})

const handleStoreCommand = async (cmd: string) => {
  if (cmd.startsWith('switch:')) {
    const storeId = cmd.replace('switch:', '')
    await storeConfig.switchStore(storeId)
    ElMessage.success('已切换至门店：' + storeConfig.storeName)
    router.go(0)
  } else if (cmd === 'create_store') {
    const hasExistingStores = (storeConfig.stores && storeConfig.stores.length > 0) ||
                              (availableStoresForCurrentUser.value && availableStoresForCurrentUser.value.length > 0)
    if (!hasExistingStores) {
      openOnboardingModal()
      return
    }
    const currentCount = availableStoresForCurrentUser.value.length
    const limit = storeConfig.storeLimit || 1
    if (currentCount >= limit) {
      ElMessageBox.alert(
        `您当前的套餐【${planName.value}】支持开设门店上限为 <b>${limit}</b> 家。<br/><br/>您当前已开设 <b>${currentCount}</b> 家门店，已达套餐配额上限！<br/><br/>如需开设更多连锁分店，请前往系统开发运维端升级至更高套餐版本。`,
        '门店开店配额已达上限',
        { dangerouslyUseHTMLString: true, type: 'warning', confirmButtonText: '我知道了' }
      )
      return
    }
    createStoreForm.value = {
      storeName: '',
      industry: 'BEAUTY',
      industryCategoryId: null,
      industryCategoryName: '',
      industryCategoryGroup: '服务类',
      phone: '',
      address: '',
      manager: '',
      businessHours: '09:00 - 22:00'
    }
    createStoreCascaderValue.value = []
    createStoreVisible.value = true
  }
}

const handleCreateStore = async () => {
  if (!createStoreForm.value.storeName.trim() || !createStoreForm.value.phone.trim() || !createStoreForm.value.address.trim()) {
    ElMessage.warning('请完整填写分店名称、电话与地址')
    return
  }
  if (!createStoreForm.value.industryCategoryId) {
    ElMessage.warning('请选择分店主营行业分类 (如：服务类 · 美业服务)')
    return
  }
  creatingStore.value = true
  try {
    const res: any = await createStoreApi({
      storeName: createStoreForm.value.storeName.trim(),
      industry: createStoreForm.value.industry,
      industryCategoryId: createStoreForm.value.industryCategoryId,
      industryCategoryName: createStoreForm.value.industryCategoryName,
      industryCategoryGroup: createStoreForm.value.industryCategoryGroup,
      phone: createStoreForm.value.phone.trim(),
      address: createStoreForm.value.address.trim(),
      manager: createStoreForm.value.manager ? createStoreForm.value.manager.trim() : '',
      businessHours: createStoreForm.value.businessHours || '09:00 - 22:00'
    })
    ElMessage.success('连锁新分店开设入驻成功！')
    createStoreVisible.value = false
    await storeConfig.loadStores()
    if (res && res.storeId) {
      await storeConfig.switchStore(res.storeId)
    }
    router.go(0)
  } catch (e: any) {
    ElMessage.error(e.message || '开设分店失败')
  } finally {
    creatingStore.value = false
  }
}

const handleQuickRoleSwitch = async (roleKey: string) => {
  try {
    // 4 大行业即时切换
    if (['beauty_boss', 'dining_boss', 'auto_boss', 'retail_boss'].includes(roleKey)) {
      const indMap: Record<string, { code: 'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL'; name: string; user: string }> = {
        beauty_boss: { code: 'BEAUTY', name: '美容美发美甲', user: '美业老板 (张建华)' },
        dining_boss: { code: 'RESTAURANT', name: '餐饮轻食/正餐', user: '餐饮老板 (刘震宇)' },
        auto_boss: { code: 'AUTO', name: '汽车养护维修', user: '汽修老板 (陆国强)' },
        retail_boss: { code: 'RETAIL', name: '专营零售', user: '零售老板 (周海峰)' }
      }
      const target = indMap[roleKey]
      const pkg = systemData.switchIndustry(target.code)

      storeConfig.industry = target.code
      storeConfig.currentStoreId = pkg.stores[0]?.storeId || 'S001'
      storeConfig.setCustomSpaceAlias(pkg.spaceAlias)
      storeConfig.appendActionAlias = pkg.appendActionAlias
      storeConfig.defaultFeeName = pkg.defaultFeeName
      storeConfig.storeName = pkg.stores[0]?.storeName || target.name
      storeConfig.industryCategoryName = target.name
      storeConfig.industryCategoryGroup = target.name

      localStorage.setItem('seahorse_user', target.user)
      localStorage.setItem('seahorse_role', 'SUPER_ADMIN')
      localStorage.setItem('seahorse_industry', target.code)
      localStorage.setItem('seahorse_store_id', pkg.stores[0]?.storeId || 'S001')
      username.value = target.user
      role.value = 'SUPER_ADMIN'

      ElMessage.success(`已切换至【${target.name}】真实行业数据与测试租户账号！`)
      if (router.currentRoute.value.path !== '/dashboard') {
        router.push('/dashboard')
      }
      return
    }

    if (roleKey === 'member') {
      const res: any = await memberLoginApi({ phone: '13800138001' })
      if (res && res.token) {
        localStorage.setItem('seahorse_token', res.token)
        localStorage.setItem('seahorse_user', res.realName || res.username)
        localStorage.setItem('seahorse_role', res.role)
        localStorage.setItem('seahorse_permissions', JSON.stringify(res.permissions || []))
        localStorage.setItem('seahorse_tenant_id', res.tenantId)
        localStorage.setItem('seahorse_member_id', String(res.userId))
        ElMessage.success('已切换为顾客会员：林清雅')
        router.push('/member-portal').then(() => router.go(0))
      }
    } else {
      const res: any = await loginApi({ username: roleKey, password: '123456' })
      if (res.token) {
        localStorage.setItem('seahorse_token', res.token)
        localStorage.setItem('seahorse_user', res.realName || res.username)
        localStorage.setItem('seahorse_role', res.role)
        localStorage.setItem('seahorse_permissions', JSON.stringify(res.permissions || []))
        localStorage.setItem('seahorse_store_id', res.storeId || 'S001')
        localStorage.setItem('seahorse_tenant_id', res.tenantId || 'T001')
        localStorage.setItem('seahorse_tenant_name', res.tenantName || '海马智慧门店')
        localStorage.setItem('seahorse_plan', res.plan || 'FLAGSHIP')
        localStorage.setItem('seahorse_deduct_mode', res.deductMode || 'PROPORTIONAL')

        // 快捷岗位预设页签设置
        if (roleKey === 'boss' || roleKey === 'admin') {
          localStorage.removeItem('seahorse_user_menu_paths')
          localStorage.removeItem('seahorse_allowed_stores')
        } else if (roleKey === 'manager') {
          const managerMenus = ['/dashboard', '/members', '/rooms', '/products', '/card-template', '/staff-management', '/marketing', '/mall', '/appointments', '/chain', '/expenses', '/inventory', '/reports', '/regulations', '/profile']
          localStorage.setItem('seahorse_user_menu_paths', JSON.stringify(managerMenus))
        } else if (roleKey === 'cashier') {
          const cashierMenus = ['/dashboard', '/members', '/rooms', '/products', '/card-template', '/appointments', '/expenses', '/inventory', '/regulations', '/profile']
          localStorage.setItem('seahorse_user_menu_paths', JSON.stringify(cashierMenus))
        } else if (roleKey === 'tony') {
          const tonyMenus = ['/dashboard', '/members', '/rooms', '/products', '/appointments', '/inventory', '/regulations', '/profile']
          localStorage.setItem('seahorse_user_menu_paths', JSON.stringify(tonyMenus))
        }

        ElMessage.success(`已切换为：${res.realName || res.username}`)
        if (res.role === 'PLATFORM_DEVELOPER') {
          router.push('/platform-dashboard').then(() => router.go(0))
        } else {
          router.push('/dashboard').then(() => router.go(0))
        }
      }
    }
  } catch (e: any) {
    ElMessage.error(e.message || '切换角色失败')
  }
}

const handleLogout = () => {
  localStorage.removeItem('seahorse_token')
  localStorage.removeItem('seahorse_user')
  localStorage.removeItem('seahorse_role')
  localStorage.removeItem('seahorse_permissions')
  localStorage.removeItem('seahorse_tenant_id')
  localStorage.removeItem('seahorse_store_id')
  localStorage.removeItem('seahorse_member_id')
  localStorage.removeItem('seahorse_user_menu_paths')
  localStorage.removeItem('seahorse_allowed_stores')
  localStorage.removeItem('seahorse_staff_id')
  ElMessage.success('已安全退出')
  router.push('/login')
}
</script>

<style scoped>
.layout-container {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.layout-header {
  height: 66px;
  background: rgba(255, 255, 255, 0.96);
  backdrop-filter: saturate(180%) blur(12px);
  color: #0f172a;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 0 18px;
  border-bottom: 1px solid #e2e8f0;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.03);
  z-index: 10;
}

.brand-box {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

.brand-logo {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: linear-gradient(135deg, #0284c7 0%, #0d9488 55%, #14b8a6 100%);
  color: #ffffff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: inset 0 1px 0.5px rgba(255, 255, 255, 0.45), 0 8px 16px -6px rgba(13, 148, 136, 0.5);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.brand-logo:hover {
  transform: translateY(-1px) scale(1.03);
  box-shadow: inset 0 1px 0.5px rgba(255, 255, 255, 0.5), 0 10px 20px -6px rgba(2, 132, 199, 0.55);
}

.brand-text {
  display: flex;
  flex-direction: column;
  justify-content: center;
  line-height: 1.2;
  white-space: nowrap;
}

.brand-title {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 16.5px;
  font-weight: 900;
  letter-spacing: -0.01em;
  color: #0284c7;
  white-space: nowrap;
}

.brand-title-main {
  background: linear-gradient(90deg, #0369a1 0%, #0284c7 55%, #0d9488 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  color: #0284c7;
}

.brand-sub {
  font-size: 10px;
  font-weight: 700;
  color: #475569;
  background: #f1f5f9;
  border: 1px solid #cbd5e1;
  padding: 1px 6px;
  border-radius: 999px;
  letter-spacing: 0.01em;
}

.brand-slogan {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  margin-top: 3px;
  padding: 2px 10px 2px 8px;
  border-radius: 999px;
  background: linear-gradient(90deg, #e0f2fe 0%, #ccfbf1 55%, #fef3c7 100%);
  border: 1px solid #38bdf8;
  box-shadow: 0 2px 6px -1px rgba(2, 132, 199, 0.2), inset 0 1px 0 rgba(255, 255, 255, 0.8);
  width: fit-content;
}

.slogan-sparkle {
  color: #d97706;
  font-size: 11.5px;
  line-height: 1;
  font-weight: 900;
}

.slogan-words {
  font-size: 12.5px;
  font-weight: 800;
  color: #0369a1;
  letter-spacing: 0.03em;
}

.header-center {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
  min-width: 0;
}

.role-badge {
  font-weight: 600;
  letter-spacing: 0.5px;
}

.store-selector-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 34px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 0 12px 0 8px;
  border-radius: 999px;
  cursor: pointer;
  color: #1e293b;
  transition: all 0.2s ease;
  user-select: none;
  white-space: nowrap;
  flex-shrink: 0;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.03);
}

.store-selector-badge:hover,
.store-selector-badge.is-dropdown-open {
  background: #f0f9ff;
  border-color: #7dd3fc;
  box-shadow: 0 3px 10px -2px rgba(2, 132, 199, 0.16);
}

.store-badge-icon-box {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  flex-shrink: 0;
}

.store-badge-content {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  max-width: 230px;
}

.current-store-text {
  font-weight: 700;
  font-size: 13px;
  color: #0f172a;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.current-store-sub-tag {
  font-size: 10.5px;
  padding: 1px 6px;
  border-radius: 999px;
  background: #e0f2fe;
  color: #0369a1;
  border: 1px solid #bae6fd;
  white-space: nowrap;
  font-weight: 600;
  flex-shrink: 0;
}

.store-badge-arrow {
  font-size: 12px;
  color: #64748b;
  transition: transform 0.22s ease;
  flex-shrink: 0;
}

.store-badge-arrow.is-rotated {
  transform: rotate(180deg);
  color: #0284c7;
}

/* ==========================================================================
   SaaS 套餐等级胶囊 (现代高定单行胶囊 · 绝不挤压折行)
   ========================================================================== */
.luxury-plan-badge {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  height: 34px;
  padding: 0 6px 0 6px;
  border-radius: 999px;
  cursor: pointer;
  user-select: none;
  white-space: nowrap;
  flex-shrink: 0;
  position: relative;
  transition: transform 0.18s ease, box-shadow 0.18s ease, border-color 0.18s ease;
}

.luxury-plan-badge:hover {
  transform: translateY(-1px);
}

.plan-badge-icon-wrap {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.plan-badge-text {
  font-size: 12.5px;
  font-weight: 700;
  letter-spacing: -0.01em;
  line-height: 1;
  white-space: nowrap;
}

.plan-badge-divider {
  width: 1px;
  height: 12px;
  background: currentColor;
  opacity: 0.18;
  flex-shrink: 0;
}

.plan-badge-sub {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 999px;
  line-height: 1.2;
  white-space: nowrap;
  font-variant-numeric: tabular-nums;
}

.plan-sub-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: #f59e0b;
  box-shadow: 0 0 0 2px rgba(245, 158, 11, 0.22);
  flex-shrink: 0;
}

.plan-badge-cta {
  font-size: 11px;
  font-weight: 700;
  padding: 2px 7px;
  border-radius: 999px;
  background: linear-gradient(135deg, #f59e0b 0%, #ea580c 100%);
  color: #ffffff;
  line-height: 1.25;
  white-space: nowrap;
  box-shadow: 0 2px 6px -1px rgba(234, 88, 12, 0.4);
  transition: filter 0.15s ease;
}

.luxury-plan-badge:hover .plan-badge-cta {
  filter: brightness(1.06);
}

/* 1. 👑 黑金旗舰版 (精致深曜石金) */
.badge-plan-flagship {
  background: linear-gradient(135deg, #18181b 0%, #27272a 100%);
  border: 1px solid rgba(251, 191, 36, 0.65);
  box-shadow: 0 2px 8px -2px rgba(24, 24, 27, 0.25), inset 0 1px 0 rgba(255, 255, 255, 0.14);
  color: #fde68a;
  padding-right: 8px;
}
.badge-plan-flagship .plan-badge-icon-wrap {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  color: #ffffff;
}
.badge-plan-flagship .plan-badge-text {
  color: #fef3c7;
}
.badge-plan-flagship .plan-badge-sub {
  background: rgba(251, 191, 36, 0.16);
  color: #fcd34d;
  border: 1px solid rgba(251, 191, 36, 0.3);
}

/* 2. 💎 星光专业版 (清透天青蓝钻) */
.badge-plan-pro {
  background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
  border: 1px solid #7dd3fc;
  box-shadow: 0 2px 8px -2px rgba(2, 132, 199, 0.14), inset 0 1px 0 #ffffff;
  color: #0369a1;
  padding-right: 8px;
}
.badge-plan-pro .plan-badge-icon-wrap {
  background: linear-gradient(135deg, #0284c7, #0d9488);
  color: #ffffff;
}
.badge-plan-pro .plan-badge-text {
  color: #0c4a6e;
}
.badge-plan-pro .plan-badge-sub {
  background: #ffffff;
  color: #0284c7;
  border: 1px solid #bae6fd;
}

/* 3. 🏛️ 企业定制版 (雅致皇家紫晶) */
.badge-plan-enterprise {
  background: linear-gradient(135deg, #faf5ff 0%, #f3e8ff 100%);
  border: 1px solid #d8b4fe;
  box-shadow: 0 2px 8px -2px rgba(126, 34, 206, 0.14), inset 0 1px 0 #ffffff;
  color: #6b21a8;
  padding-right: 8px;
}
.badge-plan-enterprise .plan-badge-icon-wrap {
  background: linear-gradient(135deg, #7e22ce, #6366f1);
  color: #ffffff;
}
.badge-plan-enterprise .plan-badge-text {
  color: #581c87;
}
.badge-plan-enterprise .plan-badge-sub {
  background: #ffffff;
  color: #7e22ce;
  border: 1px solid #e9d5ff;
}

/* 4. ✨ SaaS 体验版 (清爽琥珀晨曦胶囊 · 与浅色顶栏浑然一体) */
.badge-plan-trial {
  background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 55%, #ffedd5 100%);
  border: 1px solid #fcd34d;
  box-shadow: 0 2px 8px -2px rgba(217, 119, 6, 0.16), inset 0 1px 0 rgba(255, 255, 255, 0.85);
  color: #92400e;
}
.badge-plan-trial:hover {
  border-color: #f59e0b;
  box-shadow: 0 4px 12px -2px rgba(217, 119, 6, 0.24), inset 0 1px 0 #ffffff;
}
.badge-plan-trial .plan-badge-icon-wrap {
  background: linear-gradient(135deg, #f59e0b 0%, #ea580c 100%);
  color: #ffffff;
  box-shadow: 0 2px 5px -1px rgba(234, 88, 12, 0.4);
}
.badge-plan-trial .plan-badge-text {
  color: #9a3412;
  font-weight: 700;
}
.badge-plan-trial .plan-badge-sub {
  background: rgba(255, 255, 255, 0.88);
  color: #b45309;
  border: 1px solid rgba(251, 191, 36, 0.55);
}

.luxury-industry-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background-color: rgba(255, 255, 255, 0.07);
  border: 1px solid rgba(255, 255, 255, 0.14);
  padding: 5px 12px;
  border-radius: 20px;
  color: #cbd5e1;
  font-size: 12.5px;
  font-weight: 600;
}
.luxury-industry-badge.clickable-badge {
  cursor: pointer;
  border-color: rgba(56, 189, 248, 0.5);
  color: #7dd3fc;
  background-color: rgba(56, 189, 248, 0.15);
  transition: all 0.2s ease;
}
.luxury-industry-badge.clickable-badge:hover {
  background-color: rgba(56, 189, 248, 0.28);
  border-color: #38bdf8;
  color: #ffffff;
}
.industry-badge-icon {
  font-size: 14px;
}

.header-right-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
  white-space: nowrap;
}

.role-switch-btn {
  font-weight: 600;
}

.user-box {
  cursor: pointer;
}

.feedback-trigger-btn {
  font-weight: 600;
  background: #f0fdf4;
  border-color: #86efac;
  color: #16a34a;
  transition: all 0.25s ease;
  box-shadow: 0 1px 2px rgba(22, 163, 74, 0.08);
}
.feedback-trigger-btn:hover {
  background: #16a34a;
  border-color: #16a34a;
  color: #ffffff;
  box-shadow: 0 3px 12px rgba(22, 163, 74, 0.25);
  transform: translateY(-1px);
}

.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #0f172a;
  padding: 4px 8px;
  border-radius: 8px;
  transition: background 0.2s ease;
}

.user-info:hover {
  background: #f1f5f9;
}

.user-name {
  font-size: 13.5px;
  font-weight: 600;
  color: #0f172a;
}

.main-body {
  flex: 1;
  overflow: hidden;
}

.layout-aside {
  background-color: #ffffff;
  border-right: 1px solid #e2e8f0;
  box-shadow: 1px 0 3px rgba(0, 0, 0, 0.02);
}

.el-menu-vertical {
  border-right: none;
  background-color: #ffffff;
  padding: 8px 0;
}

:deep(.el-menu-item) {
  height: 42px;
  line-height: 42px;
  margin: 2px 10px;
  border-radius: 8px;
  color: #475569;
  font-weight: 500;
  font-size: 13.5px;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

:deep(.el-menu-item:hover) {
  background-color: var(--fwpt-neutral-100, #f1f5f9);
  color: var(--fwpt-brand-seahorse, #0284c7);
  transform: translateX(2px);
}

:deep(.el-menu-item.is-active) {
  background: linear-gradient(90deg, #f0f9ff 0%, #e0f2fe 100%);
  color: var(--fwpt-brand-seahorse, #0284c7);
  font-weight: 700;
  border-left: 3px solid var(--fwpt-brand-seahorse, #0284c7);
  box-shadow: 0 1px 4px rgba(2, 132, 199, 0.12);
}

:deep(.el-sub-menu__title) {
  height: 42px;
  line-height: 42px;
  margin: 2px 10px;
  border-radius: 8px;
  color: var(--fwpt-neutral-600, #475569);
  font-weight: 500;
  font-size: 13.5px;
  transition: all 0.2s ease;
}

:deep(.el-sub-menu__title:hover) {
  background-color: var(--fwpt-neutral-100, #f1f5f9);
  color: var(--fwpt-brand-seahorse, #0284c7);
}

.menu-group-header {
  padding: 14px 12px 4px;
  user-select: none;
}

.group-header-inner {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 6px;
  background: #f8fafc;
  border: 1px solid #f1f5f9;
  border-left: 3px solid #0284c7;
}

.group-header-icon {
  font-size: 13px;
  line-height: 1;
}

.group-header-title {
  font-size: 12px;
  font-weight: 700;
  color: #334155;
  letter-spacing: 0.04em;
}

.layout-main {
  background-color: #f8fafc;
  padding: 20px;
  overflow-y: auto;
}

:deep(.el-form-item__label) {
  white-space: nowrap !important;
  font-weight: 500;
}
</style>

<style>
/* ==============================================================================
   多门店智能切换中心 Popover 弹窗样式 (全局穿透)
   ============================================================================== */
.el-popover.store-switcher-popover {
  padding: 0 !important;
  border-radius: 14px !important;
  box-shadow: 0 20px 40px -8px rgba(15, 23, 42, 0.18), 0 4px 16px rgba(0, 0, 0, 0.06) !important;
  border: 1px solid #e2e8f0 !important;
  overflow: hidden !important;
}

.store-popover-panel {
  display: flex;
  flex-direction: column;
  background: #ffffff;
  color: #1e293b;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}

/* 顶部标题栏 */
.popover-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  background: #f8fafc;
  border-bottom: 1px solid #edf2f7;
}

.popover-header-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.popover-header-title {
  font-size: 13.5px;
  font-weight: 700;
  color: #1e293b;
}

.store-count-pill {
  font-size: 11px;
  background: #e2e8f0;
  color: #475569;
  padding: 2px 7px;
  border-radius: 12px;
  font-weight: 600;
}

.store-quota-text {
  font-size: 11.5px;
  color: #64748b;
}

.store-quota-text b {
  color: #0284c7;
}

/* 搜索过滤框 */
.popover-search-box {
  padding: 10px 14px 4px;
  background: #ffffff;
}

/* 门店卡片列表滚动区 */
.popover-store-list {
  max-height: 330px;
  overflow-y: auto;
  padding: 8px 10px;
}

.popover-store-list::-webkit-scrollbar {
  width: 5px;
}
.popover-store-list::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}
.popover-store-list::-webkit-scrollbar-track {
  background: transparent;
}

/* 单个门店卡片项 */
.store-card-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-radius: 10px;
  margin-bottom: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  border: 1px solid transparent;
  background: #ffffff;
  position: relative;
}

.store-card-item:hover {
  background: #f8fafc;
  border-color: #e2e8f0;
  transform: translateY(-1px);
}

/* 激活选中的门店卡片高亮 */
.store-card-item.is-active {
  background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
  border: 1px solid #7dd3fc;
  box-shadow: 0 2px 10px rgba(56, 189, 248, 0.16);
}

/* 行业立体头像徽章 */
.store-avatar {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  flex-shrink: 0;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.04);
}

.store-avatar.avatar-beauty {
  background: linear-gradient(135deg, #fdf2f8 0%, #fce7f3 100%);
  border: 1px solid #fbcfe8;
}

.store-avatar.avatar-restaurant {
  background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
  border: 1px solid #fde68a;
}

.store-avatar.avatar-auto {
  background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
  border: 1px solid #bfdbfe;
}

.store-avatar.avatar-retail {
  background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
  border: 1px solid #bbf7d0;
}

.store-avatar.avatar-default {
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border: 1px solid #cbd5e1;
}

/* 门店信息主体 */
.store-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.store-title-row {
  display: flex;
  align-items: center;
  gap: 6px;
}

.store-name {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.store-card-item.is-active .store-name {
  color: #0284c7;
  font-weight: 700;
}

/* 行业标签徽章 */
.store-industry-pill {
  font-size: 10.5px;
  padding: 1px 6px;
  border-radius: 4px;
  font-weight: 500;
  white-space: nowrap;
  flex-shrink: 0;
}

.store-industry-pill.badge-beauty {
  color: #be185d;
  background: #fdf2f8;
  border: 1px solid #fbcfe8;
}

.store-industry-pill.badge-restaurant {
  color: #b45309;
  background: #fffbeb;
  border: 1px solid #fde68a;
}

.store-industry-pill.badge-auto {
  color: #0369a1;
  background: #f0f9ff;
  border: 1px solid #bae6fd;
}

.store-industry-pill.badge-retail {
  color: #047857;
  background: #f0fdf4;
  border: 1px solid #a7f3d0;
}

.store-industry-pill.badge-default {
  color: #475569;
  background: #f1f5f9;
  border: 1px solid #cbd5e1;
}

/* 二级元数据行 */
.store-sub-row {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  color: #64748b;
  overflow: hidden;
  white-space: nowrap;
}

.store-code {
  color: #94a3b8;
  font-size: 10.5px;
}

.store-dot {
  color: #cbd5e1;
}

.store-address {
  display: flex;
  align-items: center;
  gap: 2px;
  max-width: 130px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.sub-addr-icon {
  font-size: 11px;
  color: #94a3b8;
}

.store-status-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 10.5px;
  color: #10b981;
  margin-left: auto;
  flex-shrink: 0;
}

.status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #10b981;
  box-shadow: 0 0 5px rgba(16, 185, 129, 0.6);
  animation: pulse-dot 1.8s infinite ease-in-out;
}

@keyframes pulse-dot {
  0%, 100% { opacity: 0.5; transform: scale(0.9); }
  50% { opacity: 1; transform: scale(1.2); }
}

/* 状态指示器与切换提示 */
.store-status-indicator {
  flex-shrink: 0;
  display: flex;
  align-items: center;
}

.active-badge {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  font-size: 11px;
  font-weight: 700;
  color: #0284c7;
  background: #ffffff;
  padding: 3px 8px;
  border-radius: 12px;
  border: 1px solid #7dd3fc;
  box-shadow: 0 1px 3px rgba(2, 132, 199, 0.12);
}

.switch-hover-btn {
  font-size: 11.5px;
  color: #94a3b8;
  display: inline-flex;
  align-items: center;
  gap: 2px;
  opacity: 0;
  transform: translateX(-4px);
  transition: all 0.2s ease;
}

.store-card-item:hover .switch-hover-btn {
  opacity: 1;
  transform: translateX(0);
  color: #0284c7;
  font-weight: 600;
}

/* 空状态 */
.popover-search-empty {
  padding: 24px 12px;
  text-align: center;
  color: #64748b;
  font-size: 12.5px;
}

.popover-search-empty .empty-hint {
  margin-bottom: 6px;
}

.popover-all-empty {
  padding: 16px 0;
}

/* 底部操作区 */
.popover-footer {
  padding: 10px 14px;
  background: #f8fafc;
  border-top: 1px solid #edf2f7;
}

.popover-footer .el-button.create-store-action-btn {
  width: 100%;
  height: var(--fwpt-control-height-base, 36px);
  border-radius: var(--fwpt-radius-md, 8px);
  font-size: var(--fwpt-font-size-sm, 13px);
  font-weight: 600;
  background: var(--fwpt-brand-seahorse, #0284c7);
  border-color: var(--fwpt-brand-seahorse, #0284c7);
  color: #ffffff;
  box-shadow: 0 2px 6px rgba(2, 132, 199, 0.25);
  transition: all 0.2s;
}

.popover-footer .el-button.create-store-action-btn:hover {
  background: var(--fwpt-brand-seahorse-hover, #0369a1);
  border-color: var(--fwpt-brand-seahorse-hover, #0369a1);
  box-shadow: 0 4px 10px rgba(2, 132, 199, 0.35);
  transform: translateY(-1px);
}

.employee-store-hint {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  color: #64748b;
  line-height: 1.4;
  padding: 4px 6px;
}

/* ================= 租户配额徽标与超额锁屏相关样式 ================= */
.quota-status-pill {
  display: flex;
  align-items: center;
  gap: 6px;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  padding: 4px 10px;
  border-radius: 20px;
  cursor: pointer;
  margin-right: 10px;
  transition: all 0.2s;
  user-select: none;
}

.quota-status-pill:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.08);
}

.quota-status-pill.pill-warning {
  background: #fffbeb;
  border-color: #fde68a;
}

.quota-status-pill.pill-danger {
  background: #fef2f2;
  border-color: #fecaca;
  animation: pulse-danger 2s infinite;
}

@keyframes pulse-danger {
  0% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.4); }
  70% { box-shadow: 0 0 0 8px rgba(239, 68, 68, 0); }
  100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
}

.pill-icon {
  font-size: 14px;
}

.pill-title {
  font-size: 12px;
  color: #475569;
  font-weight: 500;
}

.pill-value {
  font-size: 12px;
  font-weight: 700;
  color: #0f172a;
  font-family: monospace;
}

.pill-tag {
  font-size: 10px;
  height: 20px;
  padding: 0 6px;
}

/* 主页面受限锁定层 */
.main-body-wrapper {
  position: relative;
  min-height: 500px;
}

.main-body-wrapper.page-locked-active > :not(.lock-overlay-panel) {
  filter: blur(2px) grayscale(30%);
  pointer-events: none !important;
  user-select: none !important;
  opacity: 0.5;
}

.lock-overlay-panel {
  position: sticky;
  top: 20px;
  z-index: 999;
  display: flex;
  justify-content: center;
  align-items: center;
  margin-bottom: 24px;
}

.lock-card-box {
  background: #ffffff;
  border-radius: 16px;
  border: 2px solid #ef4444;
  box-shadow: 0 20px 40px -10px rgba(239, 68, 68, 0.25);
  padding: 28px 36px;
  max-width: 680px;
  width: 100%;
  text-align: center;
  position: relative;
}

.lc-icon {
  font-size: 46px;
  margin-bottom: 10px;
}

.lc-title {
  font-size: 20px;
  font-weight: 800;
  color: #ef4444;
  margin: 0 0 8px 0;
}

.lc-desc {
  font-size: 13.5px;
  color: #475569;
  line-height: 1.6;
  margin-bottom: 18px;
}

.lc-stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  background: #fef2f2;
  border: 1px solid #fee2e2;
  border-radius: 10px;
  padding: 12px 16px;
  text-align: left;
  margin-bottom: 20px;
}

.lc-s-item {
  font-size: 12.5px;
  display: flex;
}

.lc-s-item .lbl {
  color: #64748b;
  width: 110px;
  flex-shrink: 0;
}

.lc-s-item .val {
  color: #1e293b;
}

.text-danger {
  color: var(--fwpt-status-error, #ef4444);
  font-weight: bold;
}

.text-warning {
  color: var(--fwpt-status-warning, #f59e0b);
  font-weight: bold;
}

.lc-actions-row {
  margin-bottom: 12px;
}

.lc-recharge-btn {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 800;
  border-radius: 12px;
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  border: none;
  box-shadow: 0 6px 18px rgba(239, 68, 68, 0.35);
}

.lc-help-row {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.help-tip {
  font-size: 12px;
  color: #64748b;
}

/* 充值弹窗内部样式 */
.qm-top-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px 20px;
}

.qm-top-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 14px;
}

.qm-tenant-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.qm-tenant-name {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}

.qm-plan-tag {
  font-size: 12px;
  color: #64748b;
}

.qm-meters-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.mb-label-row {
  display: flex;
  justify-content: space-between;
  font-size: 12.5px;
  margin-bottom: 6px;
}

.mb-lbl {
  color: #475569;
}

.mb-val {
  font-weight: 700;
  color: #0284c7;
}

.packs-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 14px;
  margin-top: 10px;
}

.pack-card {
  position: relative;
  background: #ffffff;
  border: 1.5px solid #e2e8f0;
  border-radius: 12px;
  padding: 18px 14px;
  text-align: center;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
}

.pack-card:hover {
  border-color: #0284c7;
  transform: translateY(-2px);
  box-shadow: 0 8px 18px rgba(2, 132, 199, 0.12);
}

.pack-card.pack-highlight {
  border-color: #0284c7;
  background: #f0f9ff;
}

.pk-badge {
  position: absolute;
  top: -9px;
  right: 10px;
  background: #f43f5e;
  color: #ffffff;
  font-size: 10px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 10px;
}

.pk-name {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 8px;
}

.pk-price-row {
  margin-bottom: 8px;
}

.pk-cur {
  font-size: 14px;
  color: #0284c7;
  font-weight: 700;
}

.pk-val {
  font-size: 26px;
  font-weight: 900;
  color: #0284c7;
}

.pk-unit {
  font-size: 12px;
  color: #64748b;
}

.pk-desc {
  font-size: 11.5px;
  color: #64748b;
  line-height: 1.4;
  margin-bottom: 10px;
  min-height: 32px;
}

.pk-cap {
  font-size: 12px;
  font-weight: 700;
  color: #10b981;
  margin-bottom: 14px;
}

.pk-buy-btn {
  width: 100%;
  margin-top: auto;
  border-radius: 8px;
  font-weight: 700;
}

.annual-upgrade-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin-top: 10px;
}

.annual-card {
  border: 1.5px solid #fed7aa;
  background: #fffaf5;
  border-radius: 12px;
  padding: 18px;
  display: flex;
  flex-direction: column;
}

.ac-top {
  display: flex;
  justify-content: space-between;
  margin-bottom: 12px;
}

.ac-name {
  font-size: 15px;
  font-weight: 800;
  color: #9a3412;
}

.ac-desc {
  font-size: 11.5px;
  color: #c2410c;
  margin-top: 2px;
}

.ac-price {
  text-align: right;
}

.p-cur {
  font-size: 14px;
  color: #ea580c;
}

.p-num {
  font-size: 24px;
  font-weight: 900;
  color: #ea580c;
}

.p-u {
  font-size: 11px;
  color: #9a3412;
}

.ac-perks {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 12px;
  color: #7c2d12;
  margin-bottom: 16px;
}

.ac-btn {
  width: 100%;
  border-radius: 8px;
  font-weight: 700;
  margin-top: auto;
}

/* 🛎️ 包厢现场扫码呼叫服务通知徽标与抽屉 */
.service-call-badge-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.25s ease;
  user-select: none;
  font-size: 13px;
  color: #475569;
}

.service-call-badge-btn:hover {
  background: #e2e8f0;
  border-color: #cbd5e1;
}

.service-call-badge-btn.has-pending-calls {
  background: linear-gradient(135deg, #fff1f2, #ffe4e6);
  border-color: #fecdd3;
  color: #e11d48;
  box-shadow: 0 2px 8px rgba(225, 29, 72, 0.15);
}

.bell-icon {
  font-size: 15px;
  display: inline-block;
}

.bell-icon.ringing-bell {
  animation: bell-ring 1s infinite ease-in-out;
  transform-origin: 50% 0%;
}

@keyframes bell-ring {
  0% { transform: rotate(0); }
  10% { transform: rotate(14deg); }
  20% { transform: rotate(-14deg); }
  30% { transform: rotate(10deg); }
  40% { transform: rotate(-10deg); }
  50% { transform: rotate(6deg); }
  60% { transform: rotate(-6deg); }
  70% { transform: rotate(0); }
  100% { transform: rotate(0); }
}

.bell-label {
  font-weight: 600;
  font-size: 12.5px;
}

.bell-counter {
  background: #e11d48;
  color: #fff;
  font-size: 11px;
  font-weight: 800;
  padding: 1px 6px;
  border-radius: 10px;
  line-height: 1.3;
}

.service-calls-drawer-panel {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.sc-drawer-header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 14px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 14px;
}

.sc-empty-hint {
  padding: 40px 0;
}

.sc-calls-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  overflow-y: auto;
}

.sc-call-card {
  background: #ffffff;
  border: 1px solid #fecdd3;
  border-left: 4px solid #e11d48;
  border-radius: 10px;
  padding: 14px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
  transition: transform 0.2s;
}

.sc-call-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(225, 29, 72, 0.12);
}

.scc-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.scc-room-badge {
  font-size: 15px;
  font-weight: 800;
  color: #1e293b;
}

.scc-time {
  font-size: 12px;
  color: #64748b;
  margin-bottom: 6px;
}

.scc-notes {
  font-size: 13px;
  color: #0f172a;
  background: #fff1f2;
  border-radius: 6px;
  padding: 6px 10px;
  margin-bottom: 10px;
  border: 1px dashed #fda4af;
}

.scc-actions {
  display: flex;
  justify-content: flex-end;
}

/* 🍲 新订单出单卡片样式 */
.sc-order-card {
  background: #ffffff;
  border: 1px solid #bbf7d0;
  border-left: 4px solid #16a34a;
  border-radius: 10px;
  padding: 14px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
  transition: transform 0.2s;
}

.sc-order-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(22, 163, 74, 0.12);
}

.scc-order-content {
  font-size: 13.5px;
  color: #15803d;
  background: #f0fdf4;
  border-radius: 6px;
  padding: 8px 10px;
  margin: 6px 0 8px 0;
  border: 1px dashed #86efac;
  line-height: 1.4;
}

.scc-price-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.scc-amount {
  font-size: 13px;
  color: #b91c1c;
}

/* 侧边栏底部合规与服务信息抽离样式 */
.aside-footer-legal {
  padding: 10px 12px;
  font-size: var(--fwpt-font-size-legal, 11px);
  color: var(--fwpt-neutral-400, #94a3b8);
  text-align: center;
  border-top: 1px solid var(--fwpt-neutral-100, #f1f5f9);
  background: #fafafa;
  margin-top: auto;
  flex-shrink: 0;
}
.aside-footer-legal .legal-row {
  margin-top: 2px;
}
.aside-footer-legal .legal-link {
  color: inherit;
  text-decoration: none;
}
.aside-footer-legal .legal-link:hover {
  color: var(--fwpt-brand-seahorse, #0284c7);
  text-decoration: underline;
}

/* 顶部与主视图系统警示条语义样式 */
.system-alert-banner {
  margin-bottom: 12px;
}
.alert-banner-disabled {
  border: 2px solid var(--fwpt-status-error, #ef4444);
  font-weight: 700;
}
.alert-banner-quota {
  border: 1.5px solid var(--fwpt-status-error, #ef4444);
}
.trial-slim-banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 14px;
  margin-bottom: 14px;
  border-radius: 10px;
  background: linear-gradient(90deg, #fffbeb 0%, #fef3c7 50%, #fff7ed 100%);
  border: 1px solid #fde68a;
  color: #92400e;
  font-size: 12.5px;
  box-shadow: 0 1px 2px rgba(217, 119, 6, 0.06);
}
.tsb-left {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}
.tsb-badge {
  background: linear-gradient(135deg, #f59e0b, #ea580c);
  color: #ffffff;
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 999px;
  white-space: nowrap;
  flex-shrink: 0;
}
.tsb-text {
  color: #78350f;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.tsb-text b {
  color: #c2410c;
  font-weight: 800;
}
.tsb-btn {
  background: #ffffff;
  border: 1px solid #fcd34d;
  color: #b45309;
  font-size: 12px;
  font-weight: 700;
  padding: 4px 12px;
  border-radius: 999px;
  cursor: pointer;
  white-space: nowrap;
  flex-shrink: 0;
  transition: all 0.18s ease;
}
.tsb-btn:hover {
  background: #f59e0b;
  border-color: #f59e0b;
  color: #ffffff;
}
.alert-banner-guide {
  cursor: pointer;
}
.alert-actions {
  margin-top: 6px;
  display: flex;
  gap: 8px;
}

/* ================= 顶部 POS 高频快捷导航条 ================= */
.pos-quick-launch-bar {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 3px 6px;
  border-radius: 20px;
}

.pos-quick-pill {
  border: 1px solid transparent;
  background: transparent;
  color: #334155;
  font-size: 12.5px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 14px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  transition: all 0.2s ease;
  white-space: nowrap;
}
.pos-quick-pill:hover {
  background: #ffffff;
  color: #0284c7;
  border-color: #bae6fd;
  box-shadow: 0 1px 4px rgba(2, 132, 199, 0.12);
}
.pos-quick-pill.is-active {
  background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
  color: #ffffff;
  box-shadow: 0 2px 6px rgba(2, 132, 199, 0.28);
}
.pos-quick-pill.pill-cashier:not(.is-active) {
  color: #0284c7;
  background: #f0f9ff;
  border-color: #bae6fd;
}
.cmd-kbd {
  font-size: 10px;
  font-family: monospace;
  background: #e2e8f0;
  color: #475569;
  padding: 1px 5px;
  border-radius: 4px;
  line-height: 1.2;
}

/* 全局快捷指令面板样式 */
.qc-container {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.qc-section-title {
  font-size: 12px;
  font-weight: 700;
  color: #64748b;
  margin-top: 4px;
}
.qc-shortcuts-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
}
.qc-shortcut-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #f8fafc;
  cursor: pointer;
  transition: all 0.2s ease;
}
.qc-shortcut-card:hover {
  background: #f0f9ff;
  border-color: #38bdf8;
  transform: translateY(-1px);
}
.qc-s-icon {
  font-size: 22px;
}
.qc-s-name {
  font-size: 13.5px;
  font-weight: 700;
  color: #0f172a;
}
.qc-s-desc {
  font-size: 11.5px;
  color: #64748b;
}
.qc-list {
  max-height: 280px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding-right: 4px;
}
.qc-list-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 9px 12px;
  border-radius: 8px;
  border: 1px solid #f1f5f9;
  cursor: pointer;
  transition: all 0.15s ease;
}
.qc-list-item:hover {
  background: #f0f9ff;
  border-color: #bae6fd;
}
.qc-item-left {
  display: flex;
  align-items: center;
  gap: 10px;
}
.qc-item-icon {
  font-size: 18px;
  width: 30px;
  height: 30px;
  border-radius: 8px;
  background: #f8fafc;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
.qc-item-title {
  font-size: 13.5px;
  font-weight: 700;
  color: #1e293b;
}
.qc-item-sub {
  font-size: 11.5px;
  color: #64748b;
}
.qc-item-right {
  display: flex;
  align-items: center;
  gap: 8px;
}
.qc-enter-hint {
  font-size: 11px;
  color: #0284c7;
  font-weight: 600;
}

@media (max-width: 1440px) {
  .pill-title,
  .feedback-trigger-btn {
    display: none;
  }
  .store-badge-content {
    max-width: 180px;
  }
}
@media (max-width: 1200px) {
  .luxury-plan-badge .plan-badge-sub,
  .luxury-plan-badge .plan-badge-divider {
    display: none;
  }
  .header-right-actions {
    gap: 6px;
  }
}
@media (max-width: 960px) {
  .pos-quick-pill.pill-rooms,
  .pos-quick-pill.pill-handover,
  .feedback-trigger-btn {
    display: none;
  }
}
</style>
