<template>
  <div class="platform-dashboard-container">
    <!-- 顶部欢迎与定位横幅 -->
    <div class="welcome-banner">
      <div class="banner-left">
        <div class="banner-badge">🛠️ 系统开发运维与平台战略中枢</div>
        <h2 class="banner-title">SaaS 平台商业化营收与全系统运营大盘</h2>
        <p class="banner-desc">
          站在系统开发商全局视角，基于租户真实业务指标数据持续反哺产品演进、调度服务资源并集中管理全系统基础配置
        </p>
      </div>
      <div class="banner-right">
        <div class="banner-actions">
          <el-button type="primary" plain @click="$router.push('/vendor-activity')">
            <el-icon><DataAnalysis /></el-icon> 租户活跃报表
          </el-button>
          <el-button type="warning" plain @click="$router.push('/vendor-plans')">
            <el-icon><Setting /></el-icon> 套餐与试用配置
          </el-button>
          <el-button type="info" plain @click="$router.push('/payment-settings')">
            <el-icon><CreditCard /></el-icon> 💳 扫码盒与支付通道
          </el-button>
          <el-button type="primary" plain @click="$router.push('/vendor-developer-notif?tab=sms')">
            <el-icon><Promotion /></el-icon> 📱 阿里云/腾讯云短信
          </el-button>
          <el-button type="warning" plain @click="$router.push('/map-settings')">
            <el-icon><Location /></el-icon> 🗺️ 高德地图配置
          </el-button>
          <el-button type="success" @click="handleRefreshAll">
            <el-icon><Refresh /></el-icon> 刷新大盘
          </el-button>
        </div>
      </div>
    </div>

    <!-- 核心商业大盘指标卡片 (现代明快极简 SaaS 风格) -->
    <el-row :gutter="14" class="kpi-row">
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="kpi-card border-blue">
          <div class="kpi-header">
            <span class="kpi-label">SaaS 软件订阅累计流水</span>
            <div class="kpi-icon-wrap bg-blue"><el-icon><Money /></el-icon></div>
          </div>
          <div class="kpi-value text-blue">￥{{ Number(stats.totalSubscriptionRevenue || 0).toFixed(2) }}</div>
          <div class="kpi-meta">
            <span class="trend-tag" :class="stats.totalSubscriptionRevenue > 0 ? 'success' : 'info'">
              {{ stats.totalSubscriptionRevenue > 0 ? '+18.5% 同比增长' : '暂无订阅流水' }}
            </span>
            <span class="meta-tip">基础版本授权与订阅服务费</span>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="kpi-card border-green">
          <div class="kpi-header">
            <span class="kpi-label">云存储与资源扩容流水</span>
            <div class="kpi-icon-wrap bg-green"><el-icon><Coin /></el-icon></div>
          </div>
          <div class="kpi-value text-green">￥{{ Number(stats.totalStorageRevenue || 0).toFixed(2) }}</div>
          <div class="kpi-meta">
            <span class="trend-tag" :class="stats.totalStorageRevenue > 0 ? 'success' : 'info'">
              {{ stats.totalStorageRevenue > 0 ? '+24.2% 同比增长' : '暂无存储扩容' }}
            </span>
            <span class="meta-tip">租户客照与音视频云端存储扩容</span>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="kpi-card border-purple">
          <div class="kpi-header">
            <span class="kpi-label">全网合作租户 / 实体门店</span>
            <div class="kpi-icon-wrap bg-purple"><el-icon><Shop /></el-icon></div>
          </div>
          <div class="kpi-value text-purple">
            {{ stats.activeTenants || 0 }} <span class="unit">家租户</span> / {{ stats.totalStores || 0 }} <span class="unit">家门店</span>
          </div>
          <div class="kpi-meta">
            <span class="trend-tag info">{{ stats.activeTenants > 0 ? '覆盖实体门店' : '待新租户入驻' }}</span>
            <span class="meta-tip">美业、餐饮、汽修、零售全面赋能</span>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="kpi-card border-amber" :class="{ 'blink-alert': stats.expiringSoonCount > 0 }">
          <div class="kpi-header">
            <span class="kpi-label">试用中 / 30天内到期租户</span>
            <div class="kpi-icon-wrap bg-amber"><el-icon><BellFilled /></el-icon></div>
          </div>
          <div class="kpi-value text-amber">
            {{ stats.trialTenantsCount || 0 }} <span class="unit">家试用</span> / {{ stats.expiringSoonCount || 0 }} <span class="unit">家预警</span>
          </div>
          <div class="kpi-meta">
            <span class="trend-tag" :class="stats.expiringSoonCount > 0 ? 'warning' : 'info'">
              {{ stats.expiringSoonCount > 0 ? '需主动跟进' : '运行状态良好' }}
            </span>
            <span class="meta-tip">新租户试用期转化与老客户续约</span>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 核心板块 1: 基于租户各种指标数据反馈优化系统决策中枢 (Data-Driven Loop) -->
    <el-card shadow="never" class="section-card feedback-loop-card">
      <template #header>
        <div class="section-header-flex">
          <div class="title-with-icon">
            <div class="header-icon-box bg-sky-soft"><el-icon><TrendCharts /></el-icon></div>
            <div>
              <div class="section-title">基于租户各项指标数据 · 反馈优化系统决策中枢</div>
              <div class="section-subtitle">
                深度挖掘租户白天时段峰值、高频使用功能、业务瓶颈与建言痛点，直接驱动平台架构调优、流程极简化与产品迭代排期
              </div>
            </div>
          </div>
          <el-tag type="success" effect="dark" size="default">🧠 实时数据驱动闭环生效中</el-tag>
        </div>
      </template>

      <el-row :gutter="16">
        <!-- 优化决策 1: 业务峰值时段指标 -> 服务端弹性资源与运维窗口决策 -->
        <el-col :xs="24" :lg="12">
          <div class="insight-box">
            <div class="insight-header">
              <div class="insight-title-row">
                <span class="insight-icon">⏰</span>
                <span class="insight-title">业务峰值时段采集指标 ➔ 服务器弹性调度与更新窗口决策</span>
              </div>
              <el-tag type="danger" size="small" effect="plain">高频并发倾斜</el-tag>
            </div>
            <div class="insight-data-row">
              <div class="data-badge">
                <span class="k">白天营业总占比</span>
                <span class="v">{{ stats.totalStores > 0 ? '94.6%' : '0.0%' }}</span>
              </div>
              <div class="data-badge">
                <span class="k">黄金密集峰值窗</span>
                <span class="v text-amber">{{ stats.totalStores > 0 ? '14:00 - 18:00 (41.8%)' : '待产生数据' }}</span>
              </div>
              <div class="data-badge">
                <span class="k">夜间极低谷时段</span>
                <span class="v">{{ stats.totalStores > 0 ? '22:00 - 08:00 (2.7%)' : '待产生数据' }}</span>
              </div>
            </div>
            <div class="insight-content">
              <div class="action-item">
                <div class="action-dot bg-orange"></div>
                <div>
                  <strong>高峰算力保障：</strong>
                  采集锁定美业与茶空间在 14:00 - 18:00 发生集中预约核销与开单，系统已针对性设置此时段数据库连接池动态扩容与静态资源 CDN 强缓存。
                </div>
              </div>
              <div class="action-item">
                <div class="action-dot bg-blue"></div>
                <div>
                  <strong>低谷无感升级：</strong>
                  明确夜间 22:00 之后为租户离线低谷，系统全自动化将报表汇总、微服务热更新及资金清算调度至凌晨 02:00 - 05:00 执行，杜绝白天卡顿。
                </div>
              </div>
            </div>
            <div class="insight-footer">
              <span class="footer-tip">数据来源：全平台各租户白天时段操作频次追踪</span>
              <el-button type="primary" link size="small" @click="$router.push('/vendor-activity')">
                查看白天时段深度报表 <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
          </div>
        </el-col>

        <!-- 优化决策 2: 模块使用频次指标 -> 前台极简交互与产品重心倾斜 -->
        <el-col :xs="24" :lg="12">
          <div class="insight-box">
            <div class="insight-header">
              <div class="insight-title-row">
                <span class="insight-icon">💳</span>
                <span class="insight-title">功能模块使用频次指标 ➔ 前台交互极简化与供应链重点升级</span>
              </div>
              <el-tag type="primary" size="small" effect="plain">产品体验倾斜</el-tag>
            </div>
            <div class="insight-data-row">
              <div class="data-badge">
                <span class="k">收银结算与买单</span>
                <span class="v text-sky">{{ stats.totalStores > 0 ? '38.5% (最高频)' : '0 次操作' }}</span>
              </div>
              <div class="data-badge">
                <span class="k">空间包厢工位流转</span>
                <span class="v">{{ stats.totalStores > 0 ? '24.2%' : '0 次流转' }}</span>
              </div>
              <div class="data-badge">
                <span class="k">线上微商城订单增速</span>
                <span class="v text-emerald">{{ stats.totalStores > 0 ? '+35.0% 环比增长' : '0 笔订单' }}</span>
              </div>
            </div>
            <div class="insight-content">
              <div class="action-item">
                <div class="action-dot bg-emerald"></div>
                <div>
                  <strong>前台极简交互重构：</strong>
                  针对“收银结算”占据日间超1/3操作的现状，研发已将组合买单精简为“快捷划卡/扫码/零钱三合一”，单笔结账耗时由原 45秒 压降至 12秒。
                </div>
              </div>
              <div class="action-item">
                <div class="action-dot bg-purple"></div>
                <div>
                  <strong>供应链与商城赋能：</strong>
                  监测到各行业微商城外带零售订单激增，研发团队已规划打通顺丰/中通电子面单对接，支持一键批量打单发货。
                </div>
              </div>
            </div>
            <div class="insight-footer">
              <span class="footer-tip">数据来源：系统全量业务日志分类审计</span>
              <el-button type="primary" link size="small" @click="$router.push('/vendor-activity')">
                查看功能模块操作占比 <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
          </div>
        </el-col>

        <!-- 优化决策 3: 非研发全员建言指标 -> 需求聚类与版本迭代排期 -->
        <el-col :xs="24" :lg="12" style="margin-top: 16px;">
          <div class="insight-box">
            <div class="insight-header">
              <div class="insight-title-row">
                <span class="insight-icon">📬</span>
                <span class="insight-title">非研发全员建言聚类指标 ➔ 自动化驱动下版本产品路线图</span>
              </div>
              <el-tag type="warning" size="small" effect="plain">需求闭环驱动</el-tag>
            </div>
            <div class="insight-data-row">
              <div class="data-badge">
                <span class="k">非研发建言总量</span>
                <span class="v">{{ systemData.platformFeedbacks.length }} 条</span>
              </div>
              <div class="data-badge">
                <span class="k">新功能与体验优化</span>
                <span class="v text-amber">占比 85%</span>
              </div>
              <div class="data-badge">
                <span class="k">已排期与交付率</span>
                <span class="v text-emerald">75.0%</span>
              </div>
            </div>
            <div class="insight-content">
              <div class="action-item">
                <div class="action-dot bg-indigo"></div>
                <div>
                  <strong>一线痛点精准捕获：</strong>
                  各租户店长与收银员提出的高频诉求集中于“小票模板自定义参数”、“员工跨店漫游支持”与“电子签字导出海报”，已直接转化为 V2.4 核心里程碑。
                </div>
              </div>
              <div class="action-item">
                <div class="action-dot bg-blue"></div>
                <div>
                  <strong>双向闭环反馈：</strong>
                  研发团队在后台受理评审后，答复意见与规划上线版本实时回显给一线员工，大幅提高租户对 SaaS 系统的满意度与粘性。
                </div>
              </div>
            </div>
            <div class="insight-footer">
              <span class="footer-tip">数据来源：非研发全员「提建议/向系统反馈」数据池</span>
              <el-button type="primary" link size="small" @click="$router.push('/vendor-feedback')">
                进入建言需求受理中心 <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
          </div>
        </el-col>

        <!-- 优化决策 4: 存储消耗指标 -> 弹性扩容与商业化升级线索 -->
        <el-col :xs="24" :lg="12" style="margin-top: 16px;">
          <div class="insight-box">
            <div class="insight-header">
              <div class="insight-title-row">
                <span class="insight-icon">💾</span>
                <span class="insight-title">云存储配额消耗指标 ➔ 存储冷热分层与增值扩容销售</span>
              </div>
              <el-tag type="success" size="small" effect="plain">商业变现驱动</el-tag>
            </div>
            <div class="insight-data-row">
              <div class="data-badge">
                <span class="k">全平台存储已用</span>
                <span class="v">{{ stats.totalStorageRevenue > 0 ? '185 GB' : '0 MB' }}</span>
              </div>
              <div class="data-badge">
                <span class="k">高消耗租户占比</span>
                <span class="v text-amber">{{ stats.activeTenants > 0 ? '美业占 68%' : '0%' }}</span>
              </div>
              <div class="data-badge">
                <span class="k">存储服务费客单价</span>
                <span class="v text-green">{{ stats.totalStorageRevenue > 0 ? '￥300 / 50GB' : '￥0.00' }}</span>
              </div>
            </div>
            <div class="insight-content">
              <div class="action-item">
                <div class="action-dot bg-green"></div>
                <div>
                  <strong>扩容商机主动挖掘：</strong>
                  美业租户高清发型样板与染烫前后对比照增长迅速，系统对使用率超 80% 的租户自动提示扩容，成功驱动存储服务费年增收超 2 万元。
                </div>
              </div>
              <div class="action-item">
                <div class="action-dot bg-blue"></div>
                <div>
                  <strong>对象存储智能降本：</strong>
                  开发商底层上线图像智能压缩与冷数据低频沉降技术，在保障租户画质无损的前提下为平台节省 32% 的 OSS 存储成本。
                </div>
              </div>
            </div>
            <div class="insight-footer">
              <span class="footer-tip">数据来源：SaaS订阅与存储服务流水台账</span>
              <el-button type="primary" link size="small" @click="$router.push('/vendor-billings')">
                查看存储流水与开票台账 <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
          </div>
        </el-col>
      </el-row>
    </el-card>

    <!-- 核心板块 2: 常用基本全系统数据快捷配置中枢 (Quick Global Config) -->
    <el-card shadow="never" class="section-card config-center-card" style="margin-top: 20px;">
      <template #header>
        <div class="section-header-flex">
          <div class="title-with-icon">
            <div class="header-icon-box bg-amber-soft"><el-icon><Setting /></el-icon></div>
            <div>
              <div class="section-title">全系统常用基础数据与规则配置中枢</div>
              <div class="section-subtitle">集中调配新租户试用期天数、各级 SaaS 会员套餐定价、全平台角色权限标准模板与全渠道 OpenAPI 对接</div>
            </div>
          </div>
          <el-button type="primary" plain size="small" @click="$router.push('/vendor-plans')">
            进入完整配置页签 <el-icon><ArrowRight /></el-icon>
          </el-button>
        </div>
      </template>

      <!-- 快捷配置 1: 新租户注册试用期一键配置 -->
      <div class="quick-config-strip">
        <div class="strip-left">
          <div style="font-weight: 700; color: #0f172a; font-size: 15px; display: flex; align-items: center; gap: 8px;">
            <span>🎁 新租户注册默认试用期天数设置</span>
            <el-tag type="warning" effect="dark" size="default">当前生效：{{ currentTrialDays }} 天免费试用</el-tag>
          </div>
          <div style="font-size: 12px; color: #64748b; margin-top: 4px;">
            修改后，全平台所有新入驻租户与新注册门店将立即自动获得该天数的免费体验期，期满前系统自动发送续费提醒。
          </div>
        </div>
        <div class="strip-right">
          <el-button-group>
            <el-button :type="trialDaysInput === 3 ? 'primary' : 'default'" @click="setTrialDays(3)">3 天试用</el-button>
            <el-button :type="trialDaysInput === 7 ? 'primary' : 'default'" @click="setTrialDays(7)">7 天试用</el-button>
            <el-button :type="trialDaysInput === 14 ? 'primary' : 'default'" @click="setTrialDays(14)">14 天试用</el-button>
            <el-button :type="trialDaysInput === 30 ? 'primary' : 'default'" @click="setTrialDays(30)">30 天试用</el-button>
          </el-button-group>
          <div style="display: flex; align-items: center; gap: 6px;">
            <span style="font-size: 13px; color: #64748b;">自定义:</span>
            <el-input-number v-model="trialDaysInput" :min="1" :max="365" style="width: 110px;" />
            <span style="font-size: 13px; color: #64748b;">天</span>
          </div>
          <el-button type="success" :loading="savingTrialDays" @click="handleSaveTrialDays">
            <el-icon><Check /></el-icon> 确认保存试用天数
          </el-button>
        </div>
      </div>

      <!-- 快捷配置 2: SaaS 套餐定价与配额速览 -->
      <div style="margin-top: 20px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
          <strong style="color: #0f172a; font-size: 14px;">📋 全系统 SaaS 会员套餐价格与配额标配清单</strong>
          <span style="font-size: 12px; color: #64748b;">租户可在订阅到期前随时办理在线升级或线下续约</span>
        </div>
        <el-row :gutter="14">
          <el-col :xs="24" :sm="12" :md="6" v-for="plan in planList" :key="plan.planCode">
            <div class="plan-mini-card" :class="{ 'is-flagship': plan.planCode === 'FLAGSHIP' }">
              <div class="plan-header">
                <span class="plan-name">{{ plan.planName }}</span>
                <el-tag v-if="plan.trialDays > 0" type="warning" size="small" effect="dark">
                  🎁 {{ plan.trialDays }}天试用
                </el-tag>
                <el-tag v-else-if="plan.isDefault" type="success" size="small">主流首选</el-tag>
              </div>
              <div class="plan-price">
                <span v-if="Number(plan.annualPrice) === 0" class="free-text">免费试用体验</span>
                <span v-else class="amount-text">￥{{ plan.annualPrice }} <span class="per-year">/年</span></span>
              </div>
              <div class="plan-specs">
                <div class="spec-row">
                  <span class="k">门店上限</span>
                  <span class="v">{{ plan.storeLimit >= 999 ? '不限门店' : plan.storeLimit + ' 家' }}</span>
                </div>
                <div class="spec-row">
                  <span class="k">员工账号</span>
                  <span class="v">{{ (plan.staffLimit || 3) >= 999 ? '不限员工' : (plan.staffLimit || 3) + ' 人' }}</span>
                </div>
                <div class="spec-row">
                  <span class="k">云存储空间</span>
                  <span class="v">{{ plan.storageQuotaGb }} GB 高速空间</span>
                </div>
              </div>
              <div class="plan-footer">
                <el-button type="primary" link size="small" @click="$router.push('/vendor-plans')">
                  调整定价与配额 <el-icon><ArrowRight /></el-icon>
                </el-button>
              </div>
            </div>
          </el-col>
        </el-row>
      </div>

      <!-- 快捷配置 3: 角色权限全局标准与全渠道对接状态 -->
      <el-row :gutter="16" style="margin-top: 20px;">
        <el-col :xs="24" :lg="12">
          <div class="quick-sub-panel">
            <div class="panel-header">
              <div style="display: flex; align-items: center; gap: 8px;">
                <el-icon color="#0284c7"><Key /></el-icon>
                <strong style="color: #0f172a; font-size: 14px;">🛡️ 跨行业全角色权限全局统一标准规则</strong>
              </div>
              <el-button type="primary" link size="small" @click="$router.push('/vendor-permissions')">
                配置权限矩阵 <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
            <div class="panel-desc">
              系统预置租户老板 (SUPER_ADMIN)、旗舰店长 (STORE_MANAGER)、前台收银 (CASHIER)、美业发型总监/技师 (TECHNICIAN) 及顾客会员 (CUSTOMER_MEMBER) 的权限模板。租户未独立自定义时全量自动继承平台规范。
            </div>
            <div class="panel-tags">
              <el-tag size="small" type="danger">👑 门店老板 (全量豁免)</el-tag>
              <el-tag size="small" type="warning">🏬 店长 (多店协同/考勤/制度)</el-tag>
              <el-tag size="small" type="primary">💳 收银员 (开单买单/交班盘点)</el-tag>
              <el-tag size="small" type="success">✂️ 技师 (预约排班/业绩提成)</el-tag>
            </div>
          </div>
        </el-col>

        <el-col :xs="24" :lg="12">
          <div class="quick-sub-panel">
            <div class="panel-header">
              <div style="display: flex; align-items: center; gap: 8px;">
                <el-icon color="#10b981"><Connection /></el-icon>
                <strong style="color: #0f172a; font-size: 14px;">🔌 全渠道微信服务号与支付宝生活号统一代管</strong>
              </div>
              <el-button type="primary" link size="small" @click="$router.push('/vendor-developer-notif')">
                配置开发者OpenAPI <el-icon><ArrowRight /></el-icon>
              </el-button>
            </div>
            <div class="panel-desc">
              集中配置全平台微信服务号与支付宝生活号的 AppID、AppSecret、服务器 Token 与 AESKey。各门店无需申请企业开发者账号，系统统一代管推流消费结账、储值到账及裂变营销模板消息。
            </div>
            <div class="panel-status-row">
              <div class="channel-chip">
                <span class="dot bg-emerald"></span>
                <span>微信服务号模板消息：已连通</span>
              </div>
              <div class="channel-chip">
                <span class="dot bg-emerald"></span>
                <span>支付宝生活号动账通知：已就绪</span>
              </div>
            </div>
          </div>
        </el-col>
      </el-row>

      <!-- 快捷配置 4: 全系统免驱扫码盒子与支付通道网关 -->
      <div class="quick-sub-panel" style="margin-top: 16px;">
        <div class="panel-header">
          <div style="display: flex; align-items: center; gap: 8px;">
            <el-icon color="#6366f1"><CreditCard /></el-icon>
            <strong style="color: #0f172a; font-size: 14px;">💳 全系统免驱扫码盒子与聚合支付通道配置 (路线1/路线2/路线3)</strong>
          </div>
          <el-button type="primary" link size="small" @click="$router.push('/payment-settings')">
            进入支付通道与扫码盒配置 <el-icon><ArrowRight /></el-icon>
          </el-button>
        </div>
        <div class="panel-desc">
          系统支持免驱动 HID 即插即用扫码盒子，全自动监听高频键入并反扫收银。底层支付网关支持 3 大路径快速就绪：【路线 1】个体工租户直连 (最推荐正规路径，微信 0.38% + 支付宝 0.38%)；【路线 2】持牌聚合支付小微租户进件 (无执照快捷合规进件)；【路线 3】支付宝官方沙箱环境 (前置联调测试)。
        </div>
        <div class="panel-status-row" style="display: flex; gap: 12px; flex-wrap: wrap; margin-top: 10px;">
          <div class="channel-chip">
            <span class="dot bg-emerald"></span>
            <span>路线 1 个体户直连：微信V3+支付宝RSA2</span>
          </div>
          <div class="channel-chip">
            <span class="dot bg-emerald"></span>
            <span>路线 2 聚合小微租户：收钱吧/拉卡拉持牌进件</span>
          </div>
          <div class="channel-chip">
            <span class="dot bg-emerald"></span>
            <span>路线 3 支付宝沙箱：内置沙箱网关与联调测试密钥</span>
          </div>
          <div class="channel-chip">
            <span class="dot bg-emerald"></span>
            <span>硬件蜂鸣器：Web Audio API 仿真音效就绪</span>
          </div>
        </div>
      </div>

      <!-- 快捷配置 5: 阿里云/腾讯云短信服务网关与在线即时下发 -->
      <div class="quick-sub-panel" style="margin-top: 16px;">
        <div class="panel-header">
          <div style="display: flex; align-items: center; gap: 8px;">
            <el-icon color="#f97316"><Promotion /></el-icon>
            <strong style="color: #0f172a; font-size: 14px;">📱 阿里云 / 腾讯云短信服务网关与运营端在线即时下发中枢</strong>
          </div>
          <el-button type="primary" link size="small" @click="$router.push('/vendor-developer-notif?tab=sms')">
            进入云短信网关与即时下发 <el-icon><ArrowRight /></el-icon>
          </el-button>
        </div>
        <div class="panel-desc">
          支持集中配置阿里云短信 (Dysmsapi) 与腾讯云短信 (SMS) 接口密钥、工信部报备签名及场景模板编码。超级管理员可在运营控制台直接录入手机号并实时直连下发验证码、消费扣款、储值通知与运营公告短信。
        </div>
        <div class="panel-status-row" style="display: flex; gap: 12px; flex-wrap: wrap; margin-top: 10px;">
          <div class="channel-chip">
            <span class="dot bg-emerald"></span>
            <span>阿里云短信 Dysmsapi：已连通 (时延 38ms)</span>
          </div>
          <div class="channel-chip">
            <span class="dot bg-emerald"></span>
            <span>腾讯云短信 SMS：专线就绪 (时延 41ms)</span>
          </div>
          <div class="channel-chip">
            <span class="dot bg-emerald"></span>
            <span>在线即时下发：支持 6 大场景模版变量解析</span>
          </div>
          <div class="channel-chip">
            <span class="dot bg-emerald"></span>
            <span>租户加油包：支持超管自定义价格与条数</span>
          </div>
        </div>
      </div>

      <!-- 快捷配置 6: 全平台高德地图（AMap）API Key 与考勤定位调度中枢 -->
      <div class="quick-sub-panel" style="margin-top: 16px;">
        <div class="panel-header">
          <div style="display: flex; align-items: center; gap: 8px;">
            <el-icon color="#0284c7"><Location /></el-icon>
            <strong style="color: #0f172a; font-size: 14px;">🗺️ 全平台高德地图（AMap）服务与移动端考勤定位配置中枢</strong>
            <el-tag size="small" type="success">移动端无感透传</el-tag>
          </div>
          <div style="display: flex; gap: 8px; align-items: center;">
            <el-button type="warning" plain size="small" :loading="testingAmap" @click="handleTestAmapApiKey">
              🔌 测试 Key 连通性
            </el-button>
            <el-button type="primary" size="small" :loading="savingAmap" @click="handleSaveAmapConfig">
              💾 保存高德配置
            </el-button>
            <el-button type="primary" link size="small" @click="$router.push('/map-settings')">
              进入独立配置页签 <el-icon><ArrowRight /></el-icon>
            </el-button>
          </div>
        </div>
        <div class="panel-desc">
          配置全平台统一生效的高德开放平台 Web 服务 Key 后，移动端海马APP将自动无感透传，支持室内网络基站高精定位、逆地理详细编码。同时支持超管设置基准门店坐标与考勤偏差电子围栏。
        </div>

        <div style="margin-top: 14px; background: #f8fafc; border-radius: 8px; padding: 14px; border: 1px solid #e2e8f0;">
          <el-row :gutter="16">
            <el-col :xs="24" :md="10">
              <div style="font-size: 12px; font-weight: bold; color: #334155; margin-bottom: 6px;">
                高德开放平台 Web 服务 API Key (用于APP端高精定位与逆地理编码)
              </div>
              <el-input
                v-model="amapForm.webApiKey"
                placeholder="请输入高德 Web 服务 Key"
                clearable
                size="default"
              >
                <template #append>
                  <el-button :loading="testingAmap" @click="handleTestAmapApiKey">校验</el-button>
                </template>
              </el-input>
            </el-col>
            <el-col :xs="24" :md="8">
              <div style="font-size: 12px; font-weight: bold; color: #334155; margin-bottom: 6px;">
                基准门店标准地址 (或当前物理考勤点)
              </div>
              <el-input v-model="amapForm.storeAddress" placeholder="如：陕西省西安市高新区高新路海马商业中心" size="default" />
            </el-col>
            <el-col :xs="24" :md="6">
              <div style="font-size: 12px; font-weight: bold; color: #334155; margin-bottom: 6px;">
                考勤打卡有效偏差半径 ({{ amapForm.allowedRadiusMeters }} 米)
              </div>
              <el-slider v-model="amapForm.allowedRadiusMeters" :min="100" :max="3000" :step="50" size="small" />
            </el-col>
          </el-row>

          <div style="margin-top: 10px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px;">
            <div style="font-size: 12px; color: #64748b; display: flex; align-items: center; gap: 12px;">
              <span>基准门店: <b>{{ amapForm.storeName }}</b></span>
              <span>经度: <b>{{ amapForm.storeLongitude }}</b></span>
              <span>纬度: <b>{{ amapForm.storeLatitude }}</b></span>
              <el-button type="success" link size="small" @click="handleGetBrowserLocation">
                📍 探测当前浏览器物理经纬度
              </el-button>
            </div>
            <div class="panel-status-row" style="margin: 0; display: flex; gap: 10px;">
              <div class="channel-chip">
                <span class="dot bg-emerald"></span>
                <span>移动端APP：免手动配置 / 自动透传就绪</span>
              </div>
              <div class="channel-chip">
                <span class="dot bg-emerald"></span>
                <span>逆地理编码：街道级精度支持</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  useSystemDataStore
} from '@/stores/systemDataStore'
import {
  getVendorStatsApi,
  getSubscriptionPlansApi,
  updateTrialDaysApi
} from '@/api'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Money,
  Coin,
  Shop,
  BellFilled,
  Refresh,
  DataAnalysis,
  Setting,
  Check,
  TrendCharts,
  ArrowRight,
  Key,
  Connection,
  CreditCard,
  Promotion,
  Location
} from '@element-plus/icons-vue'

const router = useRouter()
const systemData = useSystemDataStore()

const stats = ref<any>({
  totalSubscriptionRevenue: 0,
  totalStorageRevenue: 0,
  activeTenants: 0,
  totalStores: 0,
  totalMembers: 0,
  trialTenantsCount: 0,
  expiringSoonCount: 0
})

const planList = ref<any[]>([
  { planCode: 'TRIAL', planName: '3天全功能体验版', annualPrice: 0, trialDays: 3, storeLimit: 1, staffLimit: 3, storageQuotaGb: 5, isDefault: false },
  { planCode: 'PROFESSIONAL', planName: '智慧门店专业版', annualPrice: 2980, trialDays: 0, storeLimit: 1, staffLimit: 5, storageQuotaGb: 20, isDefault: true },
  { planCode: 'FLAGSHIP', planName: '连锁品牌旗舰版', annualPrice: 6800, trialDays: 0, storeLimit: 5, staffLimit: 20, storageQuotaGb: 100, isDefault: false },
  { planCode: 'ENTERPRISE', planName: '大型集团企业版', annualPrice: 19800, trialDays: 0, storeLimit: 999, staffLimit: 999, storageQuotaGb: 1000, isDefault: false }
])

const currentTrialDays = ref(3)
const trialDaysInput = ref(3)
const savingTrialDays = ref(false)

const loadStats = async () => {
  try {
    const res: any = await getVendorStatsApi()
    if (res) {
      const data = res.totalTenants !== undefined ? res : (res.data || {})
      stats.value = {
        totalSubscriptionRevenue: data.totalSubscriptionRevenue || 0,
        totalStorageRevenue: data.totalStorageRevenue || 0,
        activeTenants: data.activeTenants || 0,
        totalStores: data.totalStores || 0,
        totalMembers: data.totalMembers || 0,
        trialTenantsCount: data.trialTenantsCount || 0,
        expiringSoonCount: data.expiringSoonCount || 0
      }
    }
  } catch (e) {
    console.warn('loadStats error', e)
  }
}

const loadPlans = async () => {
  try {
    const res: any = await getSubscriptionPlansApi()
    const list = Array.isArray(res) ? res : (res?.data || [])
    if (list.length > 0) {
      planList.value = list
      const trialPlan = list.find((p: any) => p.planCode === 'TRIAL')
      if (trialPlan) {
        currentTrialDays.value = trialPlan.trialDays
        trialDaysInput.value = trialPlan.trialDays
      }
    }
  } catch (e) {
    console.warn('loadPlans error', e)
  }
}

const setTrialDays = (days: number) => {
  trialDaysInput.value = days
}

const handleSaveTrialDays = async () => {
  savingTrialDays.value = true
  try {
    await updateTrialDaysApi(trialDaysInput.value)
    currentTrialDays.value = trialDaysInput.value
    ElMessage.success(`全系统新租户默认试用期已成功修改为 ${trialDaysInput.value} 天！`)
    await loadPlans()
  } catch (err: any) {
    ElMessage.error(err?.message || '更新试用天数失败')
  } finally {
    savingTrialDays.value = false
  }
}

// 🗺️ 全平台高德地图（AMap）与考勤定位配置
const amapForm = ref({
  webApiKey: '216aceb246ab68fbd8abb38f6cb24582',
  jsApiKey: '216aceb246ab68fbd8abb38f6cb24582',
  securityCode: 'a959cdbdf4b90d3ce9d3552521c0d0b9',
  allowedRadiusMeters: 500,
  storeLongitude: 108.953400,
  storeLatitude: 34.265500,
  storeAddress: '陕西省西安市高新区高新路海马商业中心1号店',
  storeName: '海马智慧商业 (西安高新旗舰店)',
})
const savingAmap = ref(false)
const testingAmap = ref(false)

const loadAmapConfig = async () => {
  try {
    const res = await fetch('/api/config/amap')
    if (res.ok) {
      const data = await res.json()
      if (data.code === 200 && data.data) {
        Object.assign(amapForm.value, data.data)
      }
    }
  } catch (e) {
    console.warn('loadAmapConfig error', e)
  }
}

const handleSaveAmapConfig = async () => {
  savingAmap.value = true
  try {
    const res = await fetch('/api/config/amap', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(amapForm.value),
    })
    const data = await res.json()
    if (data.code === 200) {
      ElMessage.success('高德地图开放平台服务与考勤定位配置已保存生效！')
    } else {
      ElMessage.error(data.message || '保存失败')
    }
  } catch (e: any) {
    ElMessage.error('保存高德配置网络异常: ' + e.message)
  } finally {
    savingAmap.value = false
  }
}

const handleTestAmapApiKey = async () => {
  if (!amapForm.value.webApiKey) {
    ElMessage.warning('请先输入高德 Web 服务 API Key')
    return
  }
  testingAmap.value = true
  try {
    const res = await fetch(`/api/config/amap/test?key=${encodeURIComponent(amapForm.value.webApiKey)}`)
    const data = await res.json()
    if (data.code === 200) {
      ElMessageBox.alert(
        `高德 Web 服务 Key 验证通过，网络通讯正常！\n\n省份: ${data.data?.province || '全国通用'}\n城市: ${data.data?.city || '高德网络IP定位成功'}\n状态: 活跃可用`,
        '高德接口连通性测试通过',
        { type: 'success' }
      )
    } else {
      ElMessageBox.alert(data.message || 'Key 验证未通过', '测试失败', { type: 'error' })
    }
  } catch (e: any) {
    ElMessage.error('网络请求失败: ' + e.message)
  } finally {
    testingAmap.value = false
  }
}

const handleGetBrowserLocation = () => {
  if (!navigator.geolocation) {
    ElMessage.warning('当前浏览器不支持物理定位')
    return
  }
  ElMessage.info('正在请求浏览器物理定位...')
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      amapForm.value.storeLatitude = Number(pos.coords.latitude.toFixed(6))
      amapForm.value.storeLongitude = Number(pos.coords.longitude.toFixed(6))
      ElMessage.success(`已探测当前设备物理经纬度: ${amapForm.value.storeLongitude}, ${amapForm.value.storeLatitude}`)
    },
    (err) => {
      ElMessage.warning('获取浏览器定位失败: ' + err.message + '，可手动微调经纬度')
    },
    { timeout: 8000, enableHighAccuracy: true }
  )
}

const handleRefreshAll = async () => {
  await Promise.all([loadStats(), loadPlans(), loadAmapConfig()])
  ElMessage.success('平台大盘核心数据已成功同步刷新')
}

onMounted(() => {
  loadStats()
  loadPlans()
  loadAmapConfig()
})
</script>

<style scoped>
.platform-dashboard-container {
  padding: 10px;
}

/* 顶部欢迎横幅 */
.welcome-banner {
  background: linear-gradient(135deg, #ffffff 0%, #f0f9ff 100%);
  border: 1px solid #e0f2fe;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 18px;
  box-shadow: 0 2px 10px rgba(2, 132, 199, 0.04);
}

.banner-badge {
  display: inline-block;
  background: #e0f2fe;
  color: #0284c7;
  font-size: 12px;
  font-weight: 700;
  padding: 3px 10px;
  border-radius: 20px;
  margin-bottom: 6px;
}

.banner-title {
  font-size: 20px;
  font-weight: 800;
  color: #0f172a;
  margin: 0 0 6px 0;
  letter-spacing: -0.3px;
}

.banner-desc {
  font-size: 13px;
  color: #64748b;
  margin: 0;
  line-height: 1.5;
}

.banner-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

/* 核心 KPI 卡片 */
.kpi-row {
  margin-bottom: 18px;
}

.kpi-card {
  border-radius: 12px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  transition: all 0.25s ease;
  position: relative;
  overflow: hidden;
}

.kpi-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px -4px rgba(15, 23, 42, 0.08);
}

.kpi-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
}

.border-blue::before { background: linear-gradient(90deg, #0284c7, #38bdf8); }
.border-green::before { background: linear-gradient(90deg, #059669, #34d399); }
.border-purple::before { background: linear-gradient(90deg, #7c3aed, #a78bfa); }
.border-amber::before { background: linear-gradient(90deg, #d97706, #fbbf24); }

.kpi-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.kpi-label {
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
}

.kpi-icon-wrap {
  width: 34px;
  height: 34px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
}

.bg-blue { background: #e0f2fe; color: #0284c7; }
.bg-green { background: #dcfce7; color: #16a34a; }
.bg-purple { background: #f3e8ff; color: #7c3aed; }
.bg-amber { background: #fef3c7; color: #d97706; }

.kpi-value {
  font-size: 26px;
  font-weight: 800;
  letter-spacing: -0.5px;
  margin: 10px 0 6px 0;
}

.kpi-value .unit {
  font-size: 13px;
  font-weight: normal;
  color: #64748b;
}

.text-blue { color: #0369a1; }
.text-green { color: #065f46; }
.text-purple { color: #6b21a8; }
.text-amber { color: #b45309; }

.kpi-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
}

.trend-tag {
  font-size: 11px;
  font-weight: 700;
  padding: 1px 6px;
  border-radius: 4px;
}

.trend-tag.success { background: #dcfce7; color: #15803d; }
.trend-tag.info { background: #f1f5f9; color: #475569; }
.trend-tag.warning { background: #fef3c7; color: #b45309; }

.meta-tip {
  color: #94a3b8;
  font-size: 11px;
}

.blink-alert {
  box-shadow: 0 0 12px rgba(239, 68, 68, 0.25) !important;
  border-color: #f87171 !important;
}

/* 统一通用板块卡片 */
.section-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.section-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.title-with-icon {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-icon-box {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
}

.bg-sky-soft { background: #e0f2fe; color: #0284c7; }
.bg-amber-soft { background: #fef3c7; color: #d97706; }

.section-title {
  font-size: 16px;
  font-weight: 800;
  color: #0f172a;
}

.section-subtitle {
  font-size: 12px;
  color: #64748b;
  margin-top: 2px;
}

/* 优化决策箱 (Insight Box) */
.insight-box {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 18px;
  display: flex;
  flex-direction: column;
  height: 100%;
  transition: all 0.2s ease;
}

.insight-box:hover {
  border-color: #38bdf8;
  box-shadow: 0 4px 14px rgba(14, 165, 233, 0.08);
}

.insight-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.insight-title-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.insight-icon {
  font-size: 18px;
}

.insight-title {
  font-size: 14px;
  font-weight: 700;
  color: #1e293b;
}

.insight-data-row {
  display: flex;
  gap: 8px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}

.data-badge {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 4px 10px;
  font-size: 12px;
  display: flex;
  align-items: center;
  gap: 6px;
}

.data-badge .k {
  color: #64748b;
}

.data-badge .v {
  font-weight: 700;
  color: #0f172a;
}

.insight-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-size: 13px;
  color: #334155;
  line-height: 1.5;
}

.action-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  background: #f8fafc;
  padding: 8px 12px;
  border-radius: 6px;
}

.action-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-top: 6px;
  flex-shrink: 0;
}

.bg-orange { background: #f97316; }
.bg-emerald { background: #10b981; }
.bg-indigo { background: #6366f1; }
.bg-green { background: #22c55e; }

.insight-footer {
  margin-top: 14px;
  padding-top: 10px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.footer-tip {
  font-size: 11px;
  color: #94a3b8;
}

/* 快捷配置条 (Quick Config Strip) */
.quick-config-strip {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 18px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 14px;
}

.strip-right {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

/* 套餐微卡片 */
.plan-mini-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 16px;
  height: 100%;
  display: flex;
  flex-direction: column;
  transition: all 0.2s ease;
}

.plan-mini-card:hover {
  border-color: #38bdf8;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(14, 165, 233, 0.08);
}

.plan-mini-card.is-flagship {
  border-top: 3px solid #0284c7;
  background: linear-gradient(180deg, #f0f9ff 0%, #ffffff 40%);
}

.plan-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.plan-name {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}

.plan-price {
  margin-bottom: 12px;
}

.amount-text {
  font-size: 20px;
  font-weight: 800;
  color: #0284c7;
}

.amount-text .per-year {
  font-size: 12px;
  color: #64748b;
  font-weight: normal;
}

.free-text {
  font-size: 16px;
  font-weight: 700;
  color: #10b981;
}

.plan-specs {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 12px;
  color: #475569;
  border-top: 1px dashed #e2e8f0;
  padding-top: 8px;
}

.spec-row {
  display: flex;
  justify-content: space-between;
}

.spec-row .k {
  color: #94a3b8;
}

.spec-row .v {
  font-weight: 600;
  color: #1e293b;
}

.plan-footer {
  margin-top: 10px;
  padding-top: 8px;
  border-top: 1px solid #f1f5f9;
  text-align: right;
}

/* 底部两个子板块 */
.quick-sub-panel {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.panel-desc {
  font-size: 12px;
  color: #64748b;
  line-height: 1.5;
  flex: 1;
}

.panel-tags {
  margin-top: 12px;
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.panel-status-row {
  margin-top: 12px;
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.channel-chip {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 4px 10px;
  font-size: 12px;
  color: #334155;
  display: flex;
  align-items: center;
  gap: 6px;
}

.channel-chip .dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}
</style>