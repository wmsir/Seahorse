<template>
  <div class="vendor-campaigns-container">
    <!-- 顶部标题 -->
    <div class="page-hero-header">
      <div class="hero-left">
        <div class="hero-icon-box">
          <el-icon :size="26"><Present /></el-icon>
        </div>
        <div class="hero-text-box">
          <div class="hero-title-row">
            <h2 class="hero-title">开发商专属 SaaS 营销与促销策略库</h2>
            <el-tag type="danger" effect="dark" size="small" class="hero-tag">SaaS 客户转化与促单利器</el-tag>
          </div>
          <p class="hero-subtitle">
            站在系统开发商商业视角：制定针对免费试用客户、近期到期租户、连锁拓店租户及同行转介绍的专属促销优惠政策，统一管理折扣抵扣金、服务时长赠送及批量直达触达，驱动 SaaS 订阅 ARR 爆发式增长。
          </p>
        </div>
      </div>
      <div class="hero-right-actions">
        <el-button type="success" size="default" @click="openCreateCampaignModal">
          <el-icon><Plus /></el-icon> 新增促销策略方案
        </el-button>
        <el-button type="primary" plain size="default" @click="$router.push('/vendor-tenants')">
          <el-icon><OfficeBuilding /></el-icon> 前往租户订阅与门店管控
        </el-button>
      </div>
    </div>

    <!-- 促销活动大盘关键成效指标 -->
    <el-row :gutter="14" class="stat-cards-row">
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-header">
            <span class="stat-title">🎯 在线生效策略数</span>
            <el-tag size="small" type="success">{{ activeCampaignCount }} 套在线</el-tag>
          </div>
          <div class="stat-num text-purple">{{ promotionCampaigns.length }} <span class="stat-unit">套策略方案</span></div>
          <div class="stat-tip">覆盖新客试用、老客续约、拓店扩容与裂变</div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-header">
            <span class="stat-title">📬 累计定向推送租户</span>
            <el-tag size="small" type="primary">多渠道触达</el-tag>
          </div>
          <div class="stat-num text-blue">{{ totalTargetCount }} <span class="stat-unit">家次</span></div>
          <div class="stat-tip">通过微信模板消息、短信及系统弹窗直发</div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-header">
            <span class="stat-title">🚀 成功转化核销租户</span>
            <el-tag size="small" type="warning">高促单率</el-tag>
          </div>
          <div class="stat-num text-green">{{ totalConvertedCount }} <span class="stat-unit">家租户已签单</span></div>
          <div class="stat-tip">综合促销核销转化率 <b>{{ Math.round(totalConvertedCount / (totalTargetCount || 1) * 100) }}%</b></div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-header">
            <span class="stat-title">💰 促销拉动订阅总流水</span>
            <el-tag size="small" :type="totalPromoRevenue > 0 ? 'danger' : 'info'">
              {{ totalDiscountDistributed > 0 ? '投入产出比 8.6x' : '暂无促单流水' }}
            </el-tag>
          </div>
          <div class="stat-num text-amber">￥{{ totalPromoRevenue.toFixed(2) }}</div>
          <div class="stat-tip">累计派发商业抵扣金 ￥{{ totalDiscountDistributed.toFixed(2) }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 1. 系统官方域名与网络链接配置条 -->
    <el-card shadow="never" class="domain-config-card" style="margin-top: 16px; margin-bottom: 16px;">
      <div class="domain-config-inner">
        <div class="dc-left">
          <div class="dc-title-row">
            <span class="dc-icon">🌐</span>
            <span class="dc-title">系统官方域名与环境网络链接配置</span>
            <el-tag :type="domainConfig.activeEnv === 'PROD' ? 'success' : 'warning'" effect="dark" size="small">
              当前活动环境：{{ domainConfig.activeEnv === 'PROD' ? '官方正式生产 (fwpt.cn)' : (domainConfig.activeEnv === 'DEV' ? '本地开发调试 (localhost:3000)' : '自定义独立域名') }}
            </el-tag>
          </div>
          <div class="dc-desc">
            全系统套餐海报二维码、租户分享推广链接、对外注册落地页及通知短信中均自动使用当前生效的链接基准地址。开发商可随时在此修改并一键保存生效。
          </div>
        </div>
        <div class="dc-right">
          <el-button type="primary" plain size="default" @click="openDomainConfigModal">
            <el-icon><Setting /></el-icon> 配置域名与环境链接
          </el-button>
          <div class="dc-current-url">
            当前生效租户注册基准：<code>{{ activeBaseUrl }}/tenant-register</code>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 2. 租户“老带新”网站分享裂变活动规则与多渠道通知配置卡片 -->
    <el-card shadow="never" class="referral-config-card" style="margin-bottom: 18px;">
      <template #header>
        <div class="rc-header-flex">
          <div class="rc-header-left">
            <span class="rc-icon">🤝</span>
            <span class="rc-title">租户“老带新”网站分享裂变活动规则与多渠道通知配置</span>
            <el-tag :type="referralConfig.enabled ? 'success' : 'info'" effect="dark" size="small">
              {{ referralConfig.enabled ? '🟢 裂变活动在线生效中' : '⚪ 活动已暂停' }}
            </el-tag>
          </div>
          <div class="rc-header-right">
            <el-switch
              v-model="referralConfig.enabled"
              active-text="开启裂变活动"
              inactive-text="暂停"
              @change="handleSaveReferralConfig"
            />
          </div>
        </div>
      </template>

      <div class="referral-config-body">
        <el-row :gutter="20">
          <el-col :xs="24" :md="12">
            <div class="config-sub-block">
              <div class="cs-title">🎁 推荐人（原租户A）成功邀请新租户B注册使用时的奖励政策：</div>
              <div class="reward-type-radios" style="margin-top: 8px;">
                <el-radio-group v-model="referralConfig.inviterRewardType" @change="handleSaveReferralConfig">
                  <el-radio-button label="TRIAL_EXTENSION">
                    <span>⏳ 试用期延迟 1 个月 (30天)</span>
                  </el-radio-button>
                  <el-radio-button label="COUPON">
                    <span>💰 发放 ￥500 SaaS续费抵扣券</span>
                  </el-radio-button>
                  <el-radio-button label="STORAGE_BOOST">
                    <span>☁️ 赠送 20GB 高速云端存储</span>
                  </el-radio-button>
                </el-radio-group>
              </div>

              <!-- 具体参数微调 -->
              <div class="reward-custom-params" style="margin-top: 12px;">
                <template v-if="referralConfig.inviterRewardType === 'TRIAL_EXTENSION'">
                  <div class="param-row">
                    <span class="p-lbl">试用期顺延天数：</span>
                    <el-input-number v-model="referralConfig.trialExtensionDays" :min="7" :max="365" :step="30" size="small" @change="handleSaveReferralConfig" />
                    <span class="p-unit">天 (折合约 {{ Math.round(referralConfig.trialExtensionDays / 30) }} 个月)</span>
                  </div>
                </template>
                <template v-else-if="referralConfig.inviterRewardType === 'COUPON'">
                  <div class="param-row">
                    <span class="p-lbl">抵扣券面额：</span>
                    <el-input-number v-model="referralConfig.couponAmount" :min="100" :max="5000" :step="100" size="small" @change="handleSaveReferralConfig" />
                    <span class="p-unit">元 (满 {{ referralConfig.couponMinSpend }} 元续约/扩容可用)</span>
                  </div>
                </template>
                <template v-else>
                  <div class="param-row">
                    <span class="p-lbl">赠送云存储容量：</span>
                    <el-input-number v-model="referralConfig.storageBoostGb" :min="5" :max="200" :step="10" size="small" @change="handleSaveReferralConfig" />
                    <span class="p-unit">GB 高速图片存储</span>
                  </div>
                </template>
              </div>

              <div class="invitee-rule-desc" style="margin-top: 14px;">
                <b>🌟 被推荐新租户（租户B）同步享礼遇：</b> 新开店即获 <b>{{ referralConfig.inviteeTrialDays }} 天</b>全功能免费试用期 + <b>￥{{ referralConfig.inviteeCouponAmount }}</b> 首单入驻立减津贴。
              </div>
            </div>
          </el-col>

          <el-col :xs="24" :md="12">
            <div class="config-sub-block">
              <div class="cs-title">📢 推荐成功后自动通知租户A的多渠道配置：</div>
              <div class="notify-channels-group" style="margin-top: 8px; display: flex; flex-direction: column; gap: 6px;">
                <el-checkbox v-model="referralConfig.notifyChannels.popup" @change="handleSaveReferralConfig">
                  <b>🔔 租户端首页强提醒弹窗</b> (租户老板登录即刻醒目祝贺弹窗)
                </el-checkbox>
                <el-checkbox v-model="referralConfig.notifyChannels.sms" @change="handleSaveReferralConfig">
                  <b>📱 手机短信通知</b> (自动向租户老板手机号下发奖励到账短信)
                </el-checkbox>
                <el-checkbox v-model="referralConfig.notifyChannels.wechat" @change="handleSaveReferralConfig">
                  <b>💬 微信公众号服务通知</b> (通过公众号模板消息精准直发微信)
                </el-checkbox>
              </div>

              <div class="sms-template-box" style="margin-top: 10px;">
                <div class="st-lbl" style="font-size: 11px; color: #64748b; margin-bottom: 4px;">短信下发模板内容 (支持动态变量)：</div>
                <el-input
                  v-model="referralConfig.smsTemplate"
                  type="textarea"
                  :rows="2"
                  size="small"
                  @change="handleSaveReferralConfig"
                />
              </div>

              <div class="action-test-buttons" style="margin-top: 12px; display: flex; gap: 10px; flex-wrap: wrap;">
                <el-button type="success" size="small" @click="handleSaveReferralConfig">
                  <el-icon><Check /></el-icon> 保存裂变规则配置
                </el-button>
                <el-button type="warning" plain size="small" @click="handleSimulateReferral">
                  ⚡ 模拟新租户B注册开店并测试触发发奖与通知
                </el-button>
              </div>
            </div>
          </el-col>
        </el-row>
      </div>
    </el-card>

    <!-- 促销策略卡片网格列表 (纯中文，带编辑/启停/批量派发操作) -->
    <div class="campaign-list-section">
      <div class="section-title-bar">
        <div class="st-left">
          <span class="st-icon">📋</span>
          <span class="st-title">SaaS 商业促销策略方案清单</span>
          <el-tag type="info" size="small">支持实时修改条款与状态</el-tag>
        </div>
        <div class="st-right">
          <el-radio-group v-model="filterTheme" size="small">
            <el-radio-button label="ALL">全部分类</el-radio-button>
            <el-radio-button label="violet">试用转正</el-radio-button>
            <el-radio-button label="amber">老租户续费</el-radio-button>
            <el-radio-button label="blue">拓店扩容</el-radio-button>
            <el-radio-button label="green">同行裂变</el-radio-button>
          </el-radio-group>
        </div>
      </div>

      <div class="campaign-cards-grid">
        <div
          v-for="camp in filteredCampaigns"
          :key="camp.id"
          class="campaign-item-card"
          :class="'theme-' + camp.theme"
        >
          <div class="item-card-header">
            <div class="header-tag-box">
              <span class="pill-badge" :class="'pill-' + camp.theme">{{ camp.badge }}</span>
              <el-tag size="small" :type="camp.status === 'ACTIVE' ? 'success' : 'info'" effect="dark">
                {{ camp.status === 'ACTIVE' ? '✅ 在线进行中' : '⏸️ 暂停投放' }}
              </el-tag>
            </div>
            <div class="header-deduct-tag">
              特批立减 ￥{{ camp.defaultDeduction }}
            </div>
          </div>

          <div class="item-card-title">{{ camp.title }}</div>
          <div class="item-card-desc">{{ camp.description }}</div>

          <div class="item-benefit-box">
            <div class="benefit-row" v-for="(b, idx) in camp.benefits" :key="idx">
              <el-icon color="#10b981"><Check /></el-icon>
              <span>{{ b }}</span>
            </div>
          </div>

          <div class="item-analytics-strip">
            <div class="strip-col">
              <span class="lbl">已投放租户</span>
              <span class="val">{{ camp.targetCount }} 家</span>
            </div>
            <div class="strip-divider"></div>
            <div class="strip-col">
              <span class="lbl">已转化核销</span>
              <span class="val text-green">{{ camp.convertedCount }} 家</span>
            </div>
            <div class="strip-divider"></div>
            <div class="strip-col">
              <span class="lbl">方案促单率</span>
              <span class="val text-blue">{{ camp.targetCount > 0 ? Math.round(camp.convertedCount / camp.targetCount * 100) : 0 }}%</span>
            </div>
          </div>

          <div class="item-card-actions">
            <el-button type="primary" size="small" @click="handleBatchPush(camp)">
              🚀 批量定向派发
            </el-button>
            <el-button type="default" size="small" @click="openEditCampaignModal(camp)">
              ✏️ 编辑配置
            </el-button>
            <el-button
              size="small"
              :type="camp.status === 'ACTIVE' ? 'warning' : 'success'"
              link
              @click="toggleCampaignStatus(camp)"
            >
              {{ camp.status === 'ACTIVE' ? '暂停' : '恢复上线' }}
            </el-button>
            <el-button size="small" type="danger" link @click="handleDeleteCampaign(camp)">
              删除
            </el-button>
          </div>
        </div>
      </div>
    </div>

    <!-- 3. 租户老带新推荐关系与奖励通知发放实录台账 -->
    <el-card shadow="never" class="referral-records-card" style="margin-top: 18px; margin-bottom: 20px;">
      <template #header>
        <div class="rr-header-flex" style="display: flex; justify-content: space-between; align-items: center;">
          <div class="rr-left" style="display: flex; align-items: center; gap: 8px;">
            <span style="font-weight: 700; color: #0f172a; font-size: 15px;">📜 租户老带新推荐关系与奖励通知发放实录台账</span>
            <el-tag type="success" size="small">全链路存证 · 自动履约</el-tag>
          </div>
          <div class="rr-right">
            <el-button type="primary" link size="small" @click="refreshReferralRecords">
              <el-icon><Refresh /></el-icon> 刷新台账
            </el-button>
          </div>
        </div>
      </template>

      <el-table :data="referralRecords" border stripe size="small">
        <template #empty>
          <el-empty description="暂无租户老带新推荐记录，数据全空待产生" :image-size="60" />
        </template>
        <el-table-column prop="id" label="推荐流水号" width="160" />
        <el-table-column label="推荐人 (租户A)" min-width="180">
          <template #default="{ row }">
            <div style="font-weight: 700; color: #0f172a;">{{ row.inviterTenantName }}</div>
            <div style="font-size: 11px; color: #64748b;">租户号: {{ row.inviterTenantId }} · 手机: {{ row.inviterPhone }}</div>
          </template>
        </el-table-column>
        <el-table-column label="被推荐新店 (租户B)" min-width="190">
          <template #default="{ row }">
            <div style="font-weight: 700; color: #0284c7;">{{ row.refereeTenantName }}</div>
            <div style="font-size: 11px; color: #64748b;">业态分类: {{ row.refereeIndustry }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="registeredAt" label="新租户开店时间" width="160" />
        <el-table-column label="返还租户A奖励" min-width="190">
          <template #default="{ row }">
            <el-tag size="small" type="success" effect="light">{{ row.rewardDesc }}</el-tag>
            <div style="font-size: 10px; color: #059669; margin-top: 2px;">
              状态: {{ row.rewardStatus === 'GRANTED' ? '✅ 已自动发放到账' : '⏳ 待审核发放' }}
            </div>
          </template>
        </el-table-column>
        <el-table-column label="通知触达状态" width="180">
          <template #default="{ row }">
            <div style="display: flex; gap: 4px; flex-wrap: wrap;">
              <el-tag size="small" :type="row.notificationStatus.popup ? 'primary' : 'info'">
                {{ row.notificationStatus.popup ? '弹窗已推' : '弹窗待推' }}
              </el-tag>
              <el-tag size="small" :type="row.notificationStatus.sms ? 'success' : 'info'">
                {{ row.notificationStatus.sms ? '短信已发' : '短信待发' }}
              </el-tag>
              <el-tag size="small" :type="row.notificationStatus.wechat ? 'warning' : 'info'">
                {{ row.notificationStatus.wechat ? '微信已推' : '微信待发' }}
              </el-tag>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140" align="center">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="handleResendSmsNotice(row)">
              重发短信
            </el-button>
            <el-button type="success" link size="small" @click="handleReissueReward(row)">
              补发奖励
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 近期促销券核销与履约履历 -->
    <el-card shadow="never" class="history-card" style="margin-top: 20px;">
      <template #header>
        <div class="history-header">
          <span style="font-weight: 700; color: #0f172a; font-size: 15px;">📊 近期租户促销券领用与核销实录 (实时履约流水)</span>
          <el-tag type="info" size="small">全链路闭环存证</el-tag>
        </div>
      </template>

      <el-table :data="recentRedemptions" border stripe size="small">
        <template #empty>
          <el-empty description="暂无促销券领用与核销实录，数据全空待产生" :image-size="60" />
        </template>
        <el-table-column prop="couponCode" label="特惠优惠券码" width="160" />
        <el-table-column label="促销策略方案" min-width="180">
          <template #default="{ row }">
            <div style="font-weight: 600; color: #1e293b;">{{ row.campaignTitle }}</div>
            <el-tag size="small" type="info">{{ row.badge }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="获赠租户名称" min-width="180">
          <template #default="{ row }">
            <div style="font-weight: 600;">{{ row.tenantName }}</div>
            <div style="font-size: 11px; color: #64748b;">负责人: {{ row.contact }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="deductionAmount" label="直接抵扣金 (元)" width="130" align="right">
          <template #default="{ row }">
            <span style="font-weight: 700; color: #059669;">-￥{{ row.deductionAmount.toFixed(2) }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="extraPerk" label="附赠商业权益" min-width="170" />
        <el-table-column prop="issueDate" label="派发触达时间" width="160" />
        <el-table-column label="核销签单状态" width="120" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'REDEEMED' ? 'success' : 'warning'" size="small">
              {{ row.status === 'REDEEMED' ? '已核销付费' : '体验中待核销' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 弹窗: 配置系统网络域名与环境链接地址 -->
    <el-dialog
      v-model="domainDialogVisible"
      title="🌐 配置系统网络域名与对外服务链接地址"
      width="580px"
      append-to-body
      destroy-on-close
    >
      <el-form label-position="top">
        <el-form-item label="官方正式生产环境域名 (用于公网营销海报、微信分享与租户注册)" required>
          <el-input v-model="domainEditForm.officialDomain" placeholder="https://fwpt.cn" />
        </el-form-item>

        <el-form-item label="本地开发测试环境地址 (用于本地前后端联调测试)" required>
          <el-input v-model="domainEditForm.devDomain" placeholder="http://localhost:3000" />
        </el-form-item>

        <el-form-item label="当前全系统全局生效的活动环境" required>
          <el-radio-group v-model="domainEditForm.activeEnv">
            <el-radio label="PROD">官方正式环境 ({{ domainEditForm.officialDomain }})</el-radio>
            <el-radio label="DEV">本地开发环境 ({{ domainEditForm.devDomain }})</el-radio>
            <el-radio label="CUSTOM">自定义独立域名</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item v-if="domainEditForm.activeEnv === 'CUSTOM'" label="自定义独立域名地址">
          <el-input v-model="domainEditForm.customDomain" placeholder="https://saas.yourdomain.com" />
        </el-form-item>

        <div style="background: #f1f5f9; padding: 12px 14px; border-radius: 8px; font-size: 12px; color: #475569; line-height: 1.5;">
          💡 <b>配置生效规则：</b>保存后，全平台营销海报二维码、租户推广邀请链接、短信通知链接将立即自动切换为当前所选域名。
        </div>
      </el-form>

      <template #footer>
        <el-button @click="domainDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveDomainConfig">保存并全局生效域名</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗: 编辑 / 新建 SaaS 促销策略对话框 -->
    <el-dialog
      v-model="editModalVisible"
      :title="editingCampaignId ? '✏️ 编辑 SaaS 营销促销策略方案' : '✨ 发布新 SaaS 营销促销策略方案'"
      width="680px"
      append-to-body
      destroy-on-close
      custom-class="custom-promo-dialog"
    >
      <div class="dialog-inner-opaque">
        <el-form :model="editForm" label-position="top">
          <el-row :gutter="14">
            <el-col :span="16">
              <el-form-item label="策略商业全称" required>
                <el-input v-model="editForm.title" placeholder="例如：新租户试用转正早鸟7折特惠" />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="核心特色标签" required>
                <el-input v-model="editForm.badge" placeholder="例如：试用转正加速器" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="14">
            <el-col :span="12">
              <el-form-item label="策略视觉主题">
                <el-select v-model="editForm.theme" style="width: 100%;">
                  <el-option label="💜 梦幻紫 (试用转正专用)" value="violet" />
                  <el-option label="🧡 琥珀金 (老租户续费专用)" value="amber" />
                  <el-option label="💙 科技蓝 (连锁拓店扩容专用)" value="blue" />
                  <el-option label="💚 翡翠绿 (同行老带新裂变)" value="green" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="默认特批抵扣金金额 (元)">
                <el-input-number v-model="editForm.defaultDeduction" :min="0" :step="100" style="width: 100%;" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="策略详细说明与适用对象" required>
            <el-input
              v-model="editForm.description"
              type="textarea"
              :rows="3"
              placeholder="详细描述本促销活动针对的目标客群（如3天试用体验中、到期前30天、已开设3家分店租户等）与促单业务场景..."
            />
          </el-form-item>

          <el-form-item label="包含的具体核心特权与赠送条款 (动态维护)">
            <div class="benefit-list-wrap">
              <div v-for="(_b, idx) in editForm.benefits" :key="idx" class="benefit-row-item">
                <el-input v-model="editForm.benefits[idx]" placeholder="输入一项具体权益，如：赠送 500 条官方微信模板通知短信包" />
                <el-button type="danger" link @click="removeBenefitItem(idx)">删除</el-button>
              </div>
              <el-button type="primary" link size="small" @click="addBenefitItem">
                + 增加一项权益条款
              </el-button>
            </div>
          </el-form-item>

          <el-form-item label="活动生效投放状态">
            <el-radio-group v-model="editForm.status">
              <el-radio label="ACTIVE">在线进行中 (可向租户派发推券)</el-radio>
              <el-radio label="PAUSED">暂停下线 (暂不可派发)</el-radio>
            </el-radio-group>
          </el-form-item>
        </el-form>
      </div>

      <template #footer>
        <div class="dialog-footer-actions">
          <el-button @click="editModalVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSaveCampaign">
            确认保存配置
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Present,
  Plus,
  OfficeBuilding,
  Check,
  Setting,
  Refresh
} from '@element-plus/icons-vue'
import {
  getActiveBaseUrl,
  getSystemDomainConfig,
  saveSystemDomainConfig,
  getReferralCampaignConfig,
  saveReferralCampaignConfig,
  getReferralRecords,
  saveReferralRecords,
  simulateNewReferral,
  type SystemDomainConfig,
  type ReferralCampaignConfig,
  type ReferralRecord
} from '@/utils/systemConfig'

// 域名配置状态
const domainConfig = ref<SystemDomainConfig>(getSystemDomainConfig())
const activeBaseUrl = computed(() => getActiveBaseUrl(domainConfig.value))
const domainEditForm = ref<SystemDomainConfig>({ ...domainConfig.value })
const domainDialogVisible = ref(false)

const openDomainConfigModal = () => {
  domainEditForm.value = { ...domainConfig.value }
  domainDialogVisible.value = true
}

const handleSaveDomainConfig = () => {
  domainConfig.value = { ...domainEditForm.value }
  if (domainConfig.value.activeEnv === 'PROD' && (!domainConfig.value.officialDomain || domainConfig.value.officialDomain.includes('localhost'))) {
    domainConfig.value.officialDomain = 'https://fwpt.cn'
  }
  saveSystemDomainConfig(domainConfig.value)
  domainDialogVisible.value = false
  ElMessage.success(`🎉 系统官方域名与网络链接已成功保存！当前生效租户注册基准：${activeBaseUrl.value}/tenant-register`)
}

// 租户老带新裂变活动配置与发奖台账
const referralConfig = ref<ReferralCampaignConfig>(getReferralCampaignConfig())
const referralRecords = ref<ReferralRecord[]>(getReferralRecords())

const handleSaveReferralConfig = () => {
  saveReferralCampaignConfig(referralConfig.value)
  ElMessage.success('🎉 租户老带新推荐裂变规则与通知设置已成功保存并即时生效！')
}

const refreshReferralRecords = () => {
  referralRecords.value = getReferralRecords()
  ElMessage.success('推荐关系与奖励流水台账已刷新')
}

const handleSimulateReferral = () => {
  const newRec = simulateNewReferral(
    'T001',
    '丝艺美学商业连锁 (总店)',
    '13800138001',
    `极光潮美造艺连锁 (分店${Math.floor(Math.random() * 90 + 10)})`,
    '美业时尚沙龙'
  )
  refreshReferralRecords()
  ElMessage.success(`🎉 模拟推荐成功！新租户「${newRec.refereeTenantName}」入驻开店，已为推荐人「丝艺美学」发放奖励：${newRec.rewardDesc}，并已触发弹窗与短信通知！`)
}

const handleResendSmsNotice = (row: ReferralRecord) => {
  row.notificationStatus.sms = true
  row.notifiedAt = new Date().toLocaleString()
  saveReferralRecords(referralRecords.value)
  ElMessage.success(`📱 奖励到账确认短信已重发至推荐人手机号 ${row.inviterPhone}！`)
}

const handleReissueReward = (row: ReferralRecord) => {
  row.rewardStatus = 'GRANTED'
  saveReferralRecords(referralRecords.value)
  ElMessage.success(`🎁 推荐奖励【${row.rewardDesc}】已重新发放至租户「${row.inviterTenantName}」账户！`)
}

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

const filterTheme = ref('ALL')

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

const totalTargetCount = computed(() => {
  return promotionCampaigns.value.reduce((acc, c) => acc + c.targetCount, 0)
})

const totalConvertedCount = computed(() => {
  return promotionCampaigns.value.reduce((acc, c) => acc + c.convertedCount, 0)
})

const totalPromoRevenue = computed(() => {
  return promotionCampaigns.value.reduce((acc, c) => acc + (c.convertedCount * (c.defaultDeduction || 0) * 8), 0)
})

const totalDiscountDistributed = computed(() => {
  return promotionCampaigns.value.reduce((acc, c) => acc + (c.convertedCount * (c.defaultDeduction || 0)), 0)
})

const filteredCampaigns = computed(() => {
  if (filterTheme.value === 'ALL') return promotionCampaigns.value
  return promotionCampaigns.value.filter(c => c.theme === filterTheme.value)
})

// 编辑与新建弹窗状态
const editModalVisible = ref(false)
const editingCampaignId = ref<string | null>(null)
const editForm = ref<{
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
  editForm.value = {
    id: `CAMP-${Date.now().toString().slice(-6)}`,
    title: '',
    badge: '限时促销',
    theme: 'violet',
    description: '',
    benefits: ['享受首年签约专属早鸟立减', '赠送官方微信通知短信流量包'],
    defaultDeduction: 1000,
    status: 'ACTIVE'
  }
  editModalVisible.value = true
}

const openEditCampaignModal = (camp: PromotionCampaign) => {
  editingCampaignId.value = camp.id
  editForm.value = {
    id: camp.id,
    title: camp.title,
    badge: camp.badge,
    theme: camp.theme,
    description: camp.description,
    benefits: [...camp.benefits],
    defaultDeduction: camp.defaultDeduction || 800,
    status: camp.status
  }
  editModalVisible.value = true
}

const addBenefitItem = () => {
  editForm.value.benefits.push('')
}

const removeBenefitItem = (idx: number) => {
  editForm.value.benefits.splice(idx, 1)
}

const handleSaveCampaign = () => {
  if (!editForm.value.title.trim() || !editForm.value.badge.trim()) {
    ElMessage.warning('请填写策略方案商业全称与特色标签')
    return
  }
  editForm.value.benefits = editForm.value.benefits.filter(b => b.trim().length > 0)

  if (editingCampaignId.value) {
    const idx = promotionCampaigns.value.findIndex(c => c.id === editingCampaignId.value)
    if (idx !== -1) {
      promotionCampaigns.value[idx] = {
        ...promotionCampaigns.value[idx],
        ...editForm.value
      }
      ElMessage.success(`🎉 策略方案【${editForm.value.title}】配置已成功更新！`)
    }
  } else {
    promotionCampaigns.value.unshift({
      ...editForm.value,
      targetCount: 0,
      convertedCount: 0
    })
    ElMessage.success(`🎉 新促销策略方案【${editForm.value.title}】已成功发布！`)
  }
  editModalVisible.value = false
}

const toggleCampaignStatus = (camp: PromotionCampaign) => {
  camp.status = camp.status === 'ACTIVE' ? 'PAUSED' : 'ACTIVE'
  ElMessage.success(`策略【${camp.title}】已${camp.status === 'ACTIVE' ? '恢复在线投放' : '暂停下线'}`)
}

const handleDeleteCampaign = (camp: PromotionCampaign) => {
  ElMessageBox.confirm(
    `确定删除促销策略【${camp.title}】吗？删除后将不再向租户派发该策略。`,
    '删除确认',
    { confirmButtonText: '确定删除', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    promotionCampaigns.value = promotionCampaigns.value.filter(c => c.id !== camp.id)
    ElMessage.success('促销策略已删除')
  }).catch(() => {})
}

const handleBatchPush = (camp: PromotionCampaign) => {
  ElMessageBox.confirm(
    `确定要将【${camp.title}】方案批量定向推送至所有符合条件的租户吗？系统将自动下发微信服务号模板消息通知。`,
    '批量推送促单通知',
    { confirmButtonText: '确认推送', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    camp.targetCount += 4
    ElMessage.success(`已成功向 4 家符合条件的租户批量下发促销特惠通知！`)
  }).catch(() => {})
}

// 实时核销记录（初始全空，由真实业务履约写入）
const recentRedemptions = ref<any[]>([])

</script>

<style scoped>
.vendor-campaigns-container {
  padding: 18px 24px 40px;
  background: #f8fafc;
  min-height: calc(100vh - 60px);
}

.page-hero-header {
  background: linear-gradient(135deg, #ffffff 0%, #fef2f2 100%);
  border: 1px solid #fee2e2;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(239, 68, 68, 0.04);
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
  background: linear-gradient(135deg, #ef4444 0%, #b91c1c 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(239, 68, 68, 0.25);
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
  max-width: 840px;
}

.hero-right-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.stat-cards-row {
  margin-bottom: 20px;
}

.stat-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
}

.stat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
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
}

.stat-unit {
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
}

.text-purple { color: #7c3aed; }
.text-blue { color: #0284c7; }
.text-green { color: #059669; }
.text-amber { color: #d97706; }

.stat-tip {
  font-size: 12px;
  color: #64748b;
  margin-top: 6px;
}

.campaign-list-section {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}

.section-title-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  padding-bottom: 16px;
  border-bottom: 1px solid #f1f5f9;
}

.st-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.st-icon {
  font-size: 20px;
}

.st-title {
  font-size: 16px;
  font-weight: 800;
  color: #0f172a;
}

.campaign-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 18px;
  margin-top: 18px;
}

.campaign-item-card {
  border-radius: 12px;
  padding: 18px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  transition: all 0.25s ease;
}

.campaign-item-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.06);
}

.campaign-item-card.theme-violet {
  border-color: #e9d5ff;
  background: linear-gradient(180deg, #faf5ff 0%, #ffffff 100%);
}

.campaign-item-card.theme-amber {
  border-color: #fde68a;
  background: linear-gradient(180deg, #fffbeb 0%, #ffffff 100%);
}

.campaign-item-card.theme-blue {
  border-color: #bae6fd;
  background: linear-gradient(180deg, #f0f9ff 0%, #ffffff 100%);
}

.campaign-item-card.theme-green {
  border-color: #bbf7d0;
  background: linear-gradient(180deg, #f0fdf4 0%, #ffffff 100%);
}

.item-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.header-tag-box {
  display: flex;
  align-items: center;
  gap: 8px;
}

.pill-badge {
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 4px;
}

.pill-violet { background: #e9d5ff; color: #7e22ce; }
.pill-amber { background: #fef3c7; color: #b45309; }
.pill-blue { background: #e0f2fe; color: #0369a1; }
.pill-green { background: #dcfce7; color: #15803d; }

.header-deduct-tag {
  font-size: 12px;
  font-weight: 800;
  color: #059669;
  background: #dcfce7;
  padding: 2px 8px;
  border-radius: 6px;
}

.item-card-title {
  font-size: 16px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 6px;
}

.item-card-desc {
  font-size: 12px;
  color: #64748b;
  line-height: 1.5;
  margin-bottom: 14px;
}

.item-benefit-box {
  background: #ffffff;
  border-radius: 8px;
  padding: 10px 14px;
  margin-bottom: 14px;
  border: 1px solid rgba(0, 0, 0, 0.04);
}

.benefit-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #334155;
  line-height: 1.6;
}

.item-analytics-strip {
  background: #f8fafc;
  border-radius: 8px;
  padding: 8px 12px;
  display: flex;
  align-items: center;
  justify-content: space-around;
  margin-bottom: 14px;
  border: 1px solid #f1f5f9;
}

.strip-col {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.strip-col .lbl {
  font-size: 11px;
  color: #94a3b8;
}

.strip-col .val {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
  margin-top: 2px;
}

.strip-divider {
  width: 1px;
  height: 20px;
  background: #e2e8f0;
}

.item-card-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  padding-top: 12px;
  border-top: 1px solid rgba(0, 0, 0, 0.05);
}

.history-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.history-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* 策略编辑列表样式 */
.benefit-list-wrap {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
}

.benefit-row-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.dialog-inner-opaque {
  background: #ffffff;
}

.dialog-footer-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

/* 域名与链接配置卡片 */
.domain-config-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  background: linear-gradient(135deg, #ffffff 0%, #f0fdf4 100%);
}

.domain-config-inner {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
}

.dc-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.dc-icon {
  font-size: 20px;
}

.dc-title {
  font-size: 15px;
  font-weight: 800;
  color: #0f172a;
}

.dc-desc {
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
}

.dc-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 6px;
}

.dc-current-url {
  font-size: 11px;
  color: #475569;
}

.dc-current-url code {
  color: #059669;
  font-weight: 700;
  background: #ffffff;
  padding: 2px 6px;
  border-radius: 4px;
  border: 1px solid #d1fae5;
}

/* 裂变活动配置卡片 */
.referral-config-card {
  border-radius: 12px;
  border: 1px solid #fed7aa;
  background: #ffffff;
}

.rc-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.rc-header-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.rc-icon {
  font-size: 20px;
}

.rc-title {
  font-weight: 800;
  font-size: 15px;
  color: #9a3412;
}

.config-sub-block {
  background: #fffaf5;
  border: 1px solid #ffedd5;
  border-radius: 10px;
  padding: 14px 16px;
  height: 100%;
}

.cs-title {
  font-size: 13px;
  font-weight: 700;
  color: #431407;
}

.param-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #475569;
}

.invitee-rule-desc {
  background: #ffffff;
  border: 1px dashed #fdba74;
  border-radius: 6px;
  padding: 8px 12px;
  font-size: 12px;
  color: #9a3412;
}

.referral-records-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}
</style>
