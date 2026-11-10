<template>
  <div class="marketing-center-page">
    <el-card shadow="hover">
      <template #header>
        <div class="header-box">
          <div class="header-left">
            <span class="title">📈 营销获客与会员关怀中心</span>
            <el-tag effect="plain" type="danger">获客裂变 · 节日企划 · 生日祝福 · 国庆特献</el-tag>
          </div>
          <div class="header-right" style="display: flex; gap: 8px;">
            <el-button type="success" plain icon="Promotion" @click="handleOpenBroadcastMarketingModal">
              📢 推送公众号/生活号
            </el-button>
            <el-button v-if="activeMarketingTab === 'CAMPAIGNS'" type="primary" icon="Plus" @click="handleOpenAddCampaign">
              创建裂变活动
            </el-button>
            <template v-else>
              <el-button type="success" plain icon="Plus" @click="handleOpenAddCareEvent">
                新增自定义关怀
              </el-button>
              <el-button type="primary" icon="Promotion" @click="handleOpenSimulateCare(null)">
                🚀 模拟自动触发测试
              </el-button>
            </template>
          </div>
        </div>
      </template>

      <!-- 一级页签: 🎯 获客裂变与营销活动 VS 💖 会员关怀与节日自动化事件 -->
      <el-tabs v-model="activeMarketingTab" class="marketing-tabs">
        <!-- ========================================================================= -->
        <!-- 页签 1: 获客裂变与活动中心 -->
        <!-- ========================================================================= -->
        <el-tab-pane label="🎯 获客裂变与营销活动" name="CAMPAIGNS">
          <!-- 核心营销指标数据卡片 -->
          <el-row :gutter="16" style="margin-bottom: 20px;">
            <el-col :xs="12" :sm="6" :md="6">
              <div class="stat-card stat-blue">
                <div class="lbl">累计发放优惠券</div>
                <div class="val">{{ systemData.marketingStats.totalIssued }} 张</div>
                <div class="sub">已核销 {{ systemData.marketingStats.usedCoupons }} 张 · 核销率 {{ systemData.marketingStats.redemptionRate }}%</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6" :md="6">
              <div class="stat-card stat-green">
                <div class="lbl">拼团/裂变拉新会员</div>
                <div class="val">+{{ systemData.marketingStats.referredMembers }} 人</div>
                <div class="sub">老客带新客关系链自动绑定</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6" :md="6">
              <div class="stat-card stat-amber">
                <div class="lbl">营销带动营业额</div>
                <div class="val">￥{{ systemData.marketingStats.drivenRevenue.toLocaleString() }}</div>
                <div class="sub">券核销带动实收流水转化</div>
              </div>
            </el-col>
            <el-col :xs="12" :sm="6" :md="6">
              <div class="stat-card stat-purple">
                <div class="lbl">活跃裂变活动</div>
                <div class="val">{{ runningCampaignsCount }} 场运行中</div>
                <div class="sub">共有 {{ systemData.campaigns.length }} 场营销活动</div>
              </div>
            </el-col>
          </el-row>

          <!-- 新人办卡开卡赠券迎新活动策略配置卡片 -->
          <el-card shadow="never" class="welcome-coupon-config-card" style="margin-bottom: 20px; border: 1px solid #bae6fd; background: #f0f9ff;">
            <div class="welcome-card-header">
              <div class="wc-left">
                <span class="wc-badge">🎁 核心获客策略</span>
                <span class="wc-title">新人办卡赠券迎新活动配置</span>
                <el-tag :type="welcomeConfig.enabled ? 'success' : 'info'" size="small" effect="dark">
                  {{ welcomeConfig.enabled ? '● 自动发券运行中' : '○ 活动已暂停' }}
                </el-tag>
              </div>
              <div class="wc-right">
                <el-button size="small" plain @click="handleResetWelcomeConfig">恢复默认</el-button>
                <el-button size="small" type="primary" @click="handleSaveWelcomeConfig">保存营销配置</el-button>
              </div>
            </div>

            <el-form :model="welcomeConfig" label-width="110px" style="margin-top: 16px;">
              <el-row :gutter="20">
                <el-col :xs="24" :sm="12" :md="6">
                  <el-form-item label="活动开启状态">
                    <el-switch
                      v-model="welcomeConfig.enabled"
                      active-text="开卡自动发券"
                      inactive-text="关闭发券"
                    />
                  </el-form-item>
                </el-col>
                <el-col :xs="24" :sm="12" :md="6">
                  <el-form-item label="立减价格/面额" required>
                    <el-input-number
                      v-model="welcomeConfig.amount"
                      :min="1"
                      :max="5000"
                      :step="10"
                      style="width: 100%;"
                    />
                  </el-form-item>
                </el-col>
                <el-col :xs="24" :sm="12" :md="6">
                  <el-form-item label="最低消费门槛" required>
                    <el-input-number
                      v-model="welcomeConfig.minSpend"
                      :min="0"
                      :step="50"
                      placeholder="0为无门槛"
                      style="width: 100%;"
                    />
                  </el-form-item>
                </el-col>
                <el-col :xs="24" :sm="12" :md="6">
                  <el-form-item label="单人限领数量">
                    <el-input-number v-model="welcomeConfig.limitPerMember" :min="1" :max="1" disabled style="width: 100%;" />
                  </el-form-item>
                </el-col>
              </el-row>

              <el-row :gutter="20">
                <el-col :xs="24" :sm="12" :md="8">
                  <el-form-item label="优惠券名称" required>
                    <el-input v-model="welcomeConfig.couponName" placeholder="如：新人开卡专享50元无门槛券" />
                  </el-form-item>
                </el-col>
                <el-col :xs="24" :sm="12" :md="8">
                  <el-form-item label="到期时间模式">
                    <el-radio-group v-model="welcomeConfig.validityMode">
                      <el-radio label="DAYS">自开卡起天数</el-radio>
                      <el-radio label="FIXED">固定截止日期</el-radio>
                    </el-radio-group>
                  </el-form-item>
                </el-col>
                <el-col :xs="24" :sm="12" :md="8">
                  <el-form-item :label="welcomeConfig.validityMode === 'DAYS' ? '有效天数(天)' : '到期截止日期'" required>
                    <el-input-number
                      v-if="welcomeConfig.validityMode === 'DAYS'"
                      v-model="welcomeConfig.validDays"
                      :min="1"
                      :max="365"
                      :step="7"
                      style="width: 100%;"
                    />
                    <el-date-picker
                      v-else
                      v-model="welcomeConfig.fixedExpireDate"
                      type="date"
                      placeholder="选择截止日期"
                      value-format="YYYY-MM-DD"
                      style="width: 100%;"
                    />
                  </el-form-item>
                </el-col>
              </el-row>

              <el-row :gutter="20">
                <el-col :xs="24" :sm="12" :md="8">
                  <el-form-item label="适用业务范围">
                    <el-select v-model="welcomeConfig.serviceScope" style="width: 100%;">
                      <el-option label="全场服务项目及实物商品通用" value="全场通用" />
                      <el-option label="仅限美容/美发/美甲项目" value="美业服务类项目" />
                      <el-option label="仅限汽车洗美及维修保养" value="汽修保养类项目" />
                      <el-option label="仅限餐饮包厢与主推套餐" value="餐饮特色套餐" />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :xs="24" :sm="12" :md="16">
                  <el-form-item label="优惠使用细则">
                    <el-input
                      v-model="welcomeConfig.rulesText"
                      placeholder="如：新会员入会办卡自动入账，单笔结算自动抵扣，可与会员折扣同享，逾期失效。"
                    />
                  </el-form-item>
                </el-col>
              </el-row>
            </el-form>
          </el-card>

          <!-- 活动类型筛选与搜索 -->
          <div class="filter-row">
            <el-radio-group v-model="activityTypeFilter" size="default" @change="currentPage = 1">
              <el-radio-button label="ALL">全部营销活动</el-radio-button>
              <el-radio-button label="COUPON">🎫 满减/折扣券</el-radio-button>
              <el-radio-button label="GROUP">👥 多人拼团立减</el-radio-button>
              <el-radio-button label="REFERRAL">🎁 老带新奖励金</el-radio-button>
              <el-radio-button label="POINTS">💎 积分抵扣/翻倍</el-radio-button>
            </el-radio-group>

            <div style="display: flex; gap: 10px;">
              <el-input
                v-model="searchKeyword"
                placeholder="搜索活动名称/规则"
                style="width: 240px;"
                clearable
                @clear="currentPage = 1"
                @keyup.enter="currentPage = 1"
              >
                <template #append>
                  <el-button icon="Search" @click="currentPage = 1" />
                </template>
              </el-input>
            </div>
          </div>

          <!-- 空状态提示卡片 (新租户无营销活动时展示) -->
          <div v-if="filteredCampaigns.length === 0" class="campaign-empty-card">
            <div class="empty-icon-wrap">
              <el-icon style="font-size: 56px; color: #94a3b8;"><Promotion /></el-icon>
            </div>
            <h3 class="empty-title">当前暂无营销裂变活动</h3>
            <p class="empty-desc">
              新注册租户处于严格纯净初始态。您可以点击下方按钮创建首个裂变满减券、老带新或拼团活动，也可以一键载入适合当前行业的精选营销方案快速开展营销获客！
            </p>
            <div class="empty-actions">
              <el-button type="primary" icon="Plus" size="large" @click="handleOpenAddCampaign">
                ➕ 创建首个裂变活动
              </el-button>
              <el-button type="success" plain icon="MagicStick" size="large" @click="handleLoadIndustryPresets">
                ✨ 载入当前行业精选营销方案
              </el-button>
            </div>
          </div>

          <!-- 活动列表表格与分页 -->
          <template v-else>
            <el-table :data="paginatedCampaigns" stripe style="width: 100%; margin-top: 16px;">
              <el-table-column prop="id" label="活动ID" width="90" />
              <el-table-column prop="name" label="活动主题" min-width="170">
                <template #default="{ row }">
                  <b>{{ row.name }}</b>
                </template>
              </el-table-column>
              <el-table-column prop="type" label="类型" width="130">
                <template #default="{ row }">
                  <el-tag :type="getTypeTag(row.type)">{{ getTypeName(row.type) }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="ruleDesc" label="优惠/返利规则" min-width="180" />
              <el-table-column prop="participateCount" label="参与人次" width="110">
                <template #default="{ row }">
                  <el-tag type="info">{{ row.participateCount }} 人</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="revenueBrought" label="拉动营收 (元)" width="130">
                <template #default="{ row }">
                  <span style="color: #059669; font-weight: 700;">￥{{ Number(row.revenueBrought || 0).toFixed(2) }}</span>
                </template>
              </el-table-column>
              <el-table-column prop="validRange" label="活动有效期" width="200" />
              <el-table-column prop="status" label="状态" width="100">
                <template #default="{ row }">
                  <el-tag :type="row.status === 'RUNNING' ? 'success' : 'info'" size="small">
                    {{ row.status === 'RUNNING' ? '进行中' : '已结束' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="280" fixed="right">
                <template #default="{ row }">
                  <el-button link type="success" @click="handlePushCampaignToChannel(row)">📢 推送公众号</el-button>
                  <el-button link type="primary" @click="handleShareCampaign(row)">推广海报</el-button>
                  <el-button link :type="row.status === 'RUNNING' ? 'warning' : 'success'" @click="handleToggleCampaign(row)">
                    {{ row.status === 'RUNNING' ? '停止' : '开启' }}
                  </el-button>
                  <el-button link type="danger" @click="handleDeleteCampaign(row)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>

            <!-- 标准分页器 -->
            <div class="pagination-bar">
              <el-pagination
                v-model:current-page="currentPage"
                v-model:page-size="pageSize"
                :page-sizes="[5, 10, 20]"
                layout="total, sizes, prev, pager, next, jumper"
                :total="filteredCampaigns.length"
              />
            </div>
          </template>
        </el-tab-pane>

        <!-- ========================================================================= -->
        <!-- 页签 2: 💖 会员关怀与节日自动化事件 (重点结合国庆/生日/春节送礼深度设计) -->
        <!-- ========================================================================= -->
        <el-tab-pane label="💖 会员关怀与节日自动化事件" name="CARE_EVENTS">
          <div class="care-events-container">
            <!-- 运行概览与核心指标 -->
            <el-row :gutter="16" style="margin-bottom: 20px;">
              <el-col :xs="12" :sm="6" :md="6">
                <div class="care-stat-card bg-rose">
                  <div class="c-lbl">运行中关怀事件</div>
                  <div class="c-val">{{ activeCareEventsCount }} 个事件</div>
                  <div class="c-sub">系统每日 09:00 自动巡检触发</div>
                </div>
              </el-col>
              <el-col :xs="12" :sm="6" :md="6">
                <div class="care-stat-card bg-indigo">
                  <div class="c-lbl">今年已关怀会员</div>
                  <div class="c-val">3,860 人次</div>
                  <div class="c-sub">短信网关送达率 99.8%</div>
                </div>
              </el-col>
              <el-col :xs="12" :sm="6" :md="6">
                <div class="care-stat-card bg-amber">
                  <div class="c-lbl">送出关怀礼券/礼品</div>
                  <div class="c-val">￥158,000</div>
                  <div class="c-sub">含无门槛券、双倍积分与实物</div>
                </div>
              </el-col>
              <el-col :xs="12" :sm="6" :md="6">
                <div class="care-stat-card bg-emerald">
                  <div class="c-lbl">关怀唤醒到店核销率</div>
                  <div class="c-val">43.5%</div>
                  <div class="c-sub">老客二次到店复购提升 28%</div>
                </div>
              </el-col>
            </el-row>

            <!-- 🇨🇳 中国国庆节黄金周特别企划高光横幅 (特别结合中国的国庆黄金周设计) -->
            <div class="national-day-banner">
              <div class="nd-left">
                <div class="nd-badge">🇨🇳 祖国华诞 · 国庆黄金周特别企划</div>
                <div class="nd-title">盛世华诞 · 举国同庆 · 惠享金秋特别企划</div>
                <div class="nd-desc">
                  结合中国每年 10月1日~10月7日 国庆黄金周长假，系统自动化为全店会员奉上“国庆专属红运礼金”、“到店消费双倍积分”及“国庆定制伴手礼包”，点燃黄金周进店消费热潮！
                </div>
                <div class="nd-perks-row">
                  <span class="nd-perk">🎁 专属满300减60盛惠立减券</span>
                  <span class="nd-perk">💎 黄金周进店享受双倍积分 (200%)</span>
                  <span class="nd-perk">🏮 进店即赠国庆定制红运礼盒</span>
                </div>
                <div class="nd-sms-preview">
                  <span class="nd-sms-title">📱 国庆专属祝福短信模板：</span>
                  <span class="nd-sms-text">{{ nationalDayEvent?.smsTemplate }}</span>
                </div>
              </div>

              <div class="nd-right">
                <div class="nd-status-box">
                  <span class="st-label">企划运行状态：</span>
                  <el-switch
                    v-if="nationalDayEvent"
                    v-model="nationalDayEvent.enabled"
                    active-text="开启运行"
                    inactive-text="暂时停用"
                    @change="handleSaveCareEvents"
                  />
                </div>
                <div class="nd-actions">
                  <el-button type="warning" @click="handleEditCareEvent(nationalDayEvent)">
                    ⚙️ 编辑国庆配置
                  </el-button>
                  <el-button type="primary" @click="handleOpenSimulateCare(nationalDayEvent)">
                    🚀 模拟派发测试
                  </el-button>
                </div>
              </div>
            </div>

            <!-- 关怀事件矩阵卡片 (生日祝福、春节送礼、中秋节、女神节、沉睡召回等) -->
            <div class="care-section-title">
              <div class="cs-left">
                <span>🎏 自动化节日与会员生命周期关怀矩阵</span>
                <span class="sub-title">系统按农历与公历节日节气自动巡检，支持短信定制、多重好礼赠送与一键开关</span>
              </div>
              <el-button type="primary" icon="Plus" @click="handleOpenAddCareEvent">
                + 新增自定义关怀策略
              </el-button>
            </div>

            <el-row :gutter="16">
              <el-col
                v-for="ev in otherCareEvents"
                :key="ev.id"
                :xs="24"
                :sm="12"
                :md="8"
                style="margin-bottom: 16px;"
              >
                <div class="care-event-card" :class="`border-${ev.themeColor}`">
                  <div class="card-head">
                    <div class="event-meta">
                      <span class="event-icon">{{ ev.icon }}</span>
                      <div>
                        <div class="event-name">
                          {{ ev.name }}
                          <el-tag v-if="ev.isCustom" size="small" type="warning" effect="plain" style="margin-left: 6px;">自定义</el-tag>
                        </div>
                        <div class="event-period">📅 {{ ev.period }}</div>
                      </div>
                    </div>
                    <el-switch v-model="ev.enabled" size="small" @change="handleSaveCareEvents" />
                  </div>

                  <div class="event-trigger-rule">
                    <strong>⏰ 触发规则：</strong>{{ ev.triggerDesc }}
                  </div>

                  <div class="event-perks-box">
                    <div class="perk-item">
                      <span class="p-tag">礼券</span>
                      <span>{{ ev.couponGift }}</span>
                    </div>
                    <div class="perk-item" v-if="ev.bonusPoints">
                      <span class="p-tag">积分</span>
                      <span>赠送 <strong>+{{ ev.bonusPoints }}</strong> 关怀积分</span>
                    </div>
                    <div class="perk-item" v-if="ev.giftItem">
                      <span class="p-tag">实物</span>
                      <span>进店领 <strong>{{ ev.giftItem }}</strong></span>
                    </div>
                  </div>

                  <div class="sms-quote-box">
                    <div class="quote-lbl">💬 关怀短信预览：</div>
                    <div class="quote-text">{{ ev.smsTemplate }}</div>
                  </div>

                  <div class="card-foot">
                    <span class="touched-tip">累计关怀 <b>{{ ev.touchedCount }}</b> 人次</span>
                    <div class="btn-group">
                      <el-button size="small" link type="primary" @click="handleEditCareEvent(ev)">
                        编辑配置
                      </el-button>
                      <el-button size="small" type="primary" plain @click="handleOpenSimulateCare(ev)">
                        模拟触达
                      </el-button>
                      <el-button v-if="ev.isCustom" size="small" link type="danger" @click="handleDeleteCareEvent(ev)">
                        删除
                      </el-button>
                    </div>
                  </div>
                </div>
              </el-col>
            </el-row>

            <!-- 关怀触达历史与短信发送日志 -->
            <el-card shadow="never" style="margin-top: 10px; border: 1px solid #e2e8f0;">
              <template #header>
                <div style="display: flex; justify-content: space-between; align-items: center;">
                  <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-weight: 700; color: #0f172a;">📜 关怀事件执行与短信送达台账记录</span>
                    <el-tag size="small" type="success">实时自动入账</el-tag>
                  </div>
                  <div style="display: flex; gap: 10px; align-items: center;">
                    <el-select
                      v-model="careLogFilterEvent"
                      placeholder="筛选关怀事件"
                      size="small"
                      clearable
                      style="width: 180px;"
                    >
                      <el-option label="全部关怀事件" value="" />
                      <el-option
                        v-for="ev in careEventsList"
                        :key="ev.id"
                        :label="ev.name"
                        :value="ev.name"
                      />
                    </el-select>
                    <el-input
                      v-model="careLogKeyword"
                      placeholder="按会员姓名/手机号检索"
                      size="small"
                      style="width: 200px;"
                      clearable
                    />
                  </div>
                </div>
              </template>

              <el-table :data="paginatedCareLogs" stripe style="width: 100%;">
                <el-table-column prop="memberName" label="受关怀会员" width="140">
                  <template #default="{ row }">
                    <b>{{ row.memberName }}</b>
                    <el-tag size="small" style="margin-left: 6px;">{{ row.memberLevel }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="phone" label="联系手机号" width="130">
                  <template #default="{ row }">
                    <span style="font-family: monospace;">{{ row.phone }}</span>
                  </template>
                </el-table-column>
                <el-table-column prop="eventName" label="关怀事件名称" width="180">
                  <template #default="{ row }">
                    <el-tag :type="getCareThemeTag(row.eventId)">{{ row.eventName }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="giftSummary" label="送达权益礼遇" min-width="190" />
                <el-table-column prop="smsContent" label="短信通知文本" min-width="260" show-overflow-tooltip>
                  <template #default="{ row }">
                    <span style="font-size: 12px; color: #475569;">{{ row.smsContent }}</span>
                  </template>
                </el-table-column>
                <el-table-column prop="sendTime" label="送达时间" width="150" />
                <el-table-column label="触达状态" width="110" align="center">
                  <template #default="{ row }">
                    <el-tag type="success" size="small">{{ row.statusText || '短信已送达' }}</el-tag>
                  </template>
                </el-table-column>
                <template #empty>
                  <el-empty description="暂无关怀事件执行与短信送达台账记录" :image-size="60" />
                </template>
              </el-table>

              <!-- 日志分页器 -->
              <div class="pagination-bar">
                <el-pagination
                  v-model:current-page="careLogCurrentPage"
                  v-model:page-size="careLogPageSize"
                  :page-sizes="[5, 10, 20]"
                  layout="total, sizes, prev, pager, next, jumper"
                  :total="filteredCareLogs.length"
                />
              </div>
            </el-card>
          </div>
        </el-tab-pane>

        <!-- ========================================================================= -->
        <!-- 页签 3: 📅 全年12月营销日历与获客时机助手 (门店常用拓客排期与沟通锦囊) -->
        <!-- ========================================================================= -->
        <el-tab-pane label="📅 全年营销日历与获客时机助手" name="MARKETING_TOOLS">
          <div class="marketing-tools-container">
            <!-- 顶栏横幅 -->
            <div class="tools-hero-banner">
              <div class="th-left">
                <div class="th-badge">📅 2026 全年营销拓客挂图 · 节假日一览与精准沟通助手</div>
                <div class="th-title">掌握全年消费节奏，在最对的时机向最对的顾客发声</div>
                <div class="th-desc">
                  汇聚中国全年法定公休长假、二十四节气与重点消费黄金期，标注最佳短信与电话获客时机及文案工具，助门店淡季不淡、旺季爆单！
                </div>
              </div>
              <div class="th-right">
                <el-button type="warning" plain icon="ChatDotRound" @click="scrollSection('copywriter')">
                  💬 智能拓客文案生成器
                </el-button>
                <el-button type="success" plain icon="Calculator" @click="scrollSection('calculator')">
                  🧮 充值活动毛利测算器
                </el-button>
              </div>
            </div>

            <!-- 1. 全年 12 个月份快速切换导航条 -->
            <div class="month-selector-bar">
              <span class="m-label">🗓️ 选择月份作战挂图：</span>
              <div class="m-buttons">
                <el-button
                  v-for="m in allMonthsData"
                  :key="m.month"
                  :type="selectedMonth === m.month ? 'primary' : 'default'"
                  :effect="selectedMonth === m.month ? 'dark' : 'plain'"
                  size="small"
                  @click="selectedMonth = m.month"
                >
                  {{ m.month }}月 · {{ m.shortTag }}
                  <span v-if="m.month === currentRealMonth" class="current-month-badge">本月</span>
                </el-button>
              </div>
            </div>

            <!-- 当月日历作战卡片 -->
            <el-card shadow="never" class="month-playbook-card">
              <template #header>
                <div class="mp-header">
                  <div class="mp-title">
                    <span class="month-num">{{ currentMonthDetail.month }} 月</span>
                    <span class="month-theme">【{{ currentMonthDetail.theme }}】</span>
                    <el-tag :type="currentMonthDetail.holidayDays > 0 ? 'danger' : 'info'" size="small">
                      {{ currentMonthDetail.holidayDays > 0 ? `包含法定节假日 ${currentMonthDetail.holidayDays} 天` : '无长假·深耕常规客流' }}
                    </el-tag>
                  </div>
                  <div class="mp-sub">
                    <b>建议启动宣发时间：</b>{{ currentMonthDetail.leadTime }}
                  </div>
                </div>
              </template>

              <el-row :gutter="20">
                <!-- 左侧: 当月可视化日历网格 -->
                <el-col :xs="24" :sm="24" :md="13">
                  <div class="calendar-grid-box">
                    <div class="cg-legend">
                      <span class="legend-item"><i class="dot dot-holiday"></i> 法定长假</span>
                      <span class="legend-item"><i class="dot dot-window"></i> 营销预热黄金期</span>
                      <span class="legend-item"><i class="dot dot-weekend"></i> 周末高峰</span>
                      <span class="legend-item"><i class="dot dot-work"></i> 调休工作日</span>
                      <span class="legend-item"><i class="dot dot-solar"></i> 二十四节气</span>
                    </div>

                    <div class="calendar-week-row">
                      <span>日</span><span>一</span><span>二</span><span>三</span><span>四</span><span>五</span><span>六</span>
                    </div>

                    <div class="calendar-days-grid">
                      <!-- 占位空白天 -->
                      <div
                        v-for="blank in currentMonthDetail.startWeekday"
                        :key="'blank-' + blank"
                        class="day-cell day-blank"
                      ></div>

                      <!-- 真实天数单元格 -->
                      <div
                        v-for="d in currentMonthDetail.days"
                        :key="d.day"
                        class="day-cell"
                        :class="[`type-${d.type}`, { 'today-cell': isRealToday(currentMonthDetail.month, d.day) }]"
                      >
                        <div class="d-top">
                          <span class="d-num">{{ d.day }}</span>
                          <span v-if="d.solarTerm" class="d-solar">{{ d.solarTerm }}</span>
                        </div>
                        <div class="d-desc" v-if="d.label">{{ d.label }}</div>
                      </div>
                    </div>
                  </div>
                </el-col>

                <!-- 右侧: 当月营销攻坚指南 -->
                <el-col :xs="24" :sm="24" :md="11">
                  <div class="month-guide-box">
                    <div class="g-section">
                      <div class="g-tit">🎯 重点营销战役与主打策略：</div>
                      <div class="g-val">{{ currentMonthDetail.campaignPlan }}</div>
                    </div>

                    <div class="g-section">
                      <div class="g-tit">🎁 推荐爆款套餐 / 促销项目：</div>
                      <div class="g-val highlight-val">{{ currentMonthDetail.featuredOffer }}</div>
                    </div>

                    <div class="g-section">
                      <div class="g-tit">👥 核心攻坚受众客群：</div>
                      <div class="g-val">{{ currentMonthDetail.targetAudience }}</div>
                    </div>

                    <div class="g-section tips-section">
                      <div class="g-tit">💡 老板经营锦囊与避坑法则：</div>
                      <div class="g-val tip-text">{{ currentMonthDetail.bossAdvice }}</div>
                    </div>
                  </div>
                </el-col>
              </el-row>
            </el-card>

            <!-- 2. 精准获客时机与客群沟通黄金法则 (什么时候给什么群体发短信/打电话) -->
            <div class="section-divider-title">
              <span>🎯 4 大客群精准获客时机与沟通黄金法则</span>
              <span class="sub">告别盲目推销被顾客拉黑，掌握最佳时段与心理痛点，获客转化提升 300%</span>
            </div>

            <el-row :gutter="16">
              <el-col :xs="24" :sm="12" :md="6" v-for="c in customerTimingGuides" :key="c.persona">
                <div class="persona-timing-card" :class="`border-p-${c.theme}`">
                  <div class="pt-head">
                    <span class="pt-icon">{{ c.icon }}</span>
                    <div>
                      <div class="pt-name">{{ c.persona }}</div>
                      <div class="pt-sub">{{ c.subTitle }}</div>
                    </div>
                  </div>

                  <div class="pt-box time-box">
                    <div class="box-lbl">⏰ 最佳触达时间窗口：</div>
                    <div class="box-val highlight-time">{{ c.bestTime }}</div>
                  </div>

                  <div class="pt-box">
                    <div class="box-lbl">🧠 核心心理痛点与需求：</div>
                    <div class="box-val">{{ c.psychology }}</div>
                  </div>

                  <div class="pt-box">
                    <div class="box-lbl">💬 沟通策略与避坑话术：</div>
                    <div class="box-val">{{ c.strategy }}</div>
                  </div>

                  <div class="pt-box offer-box">
                    <div class="box-lbl">🏷️ 最易成交主推项目：</div>
                    <div class="box-val">{{ c.recommendedOffer }}</div>
                  </div>
                </div>
              </el-col>
            </el-row>

            <!-- 短信群发 vs 电话回访 黄金准则对比表 -->
            <el-card shadow="never" style="margin-top: 20px; border: 1px solid #e2e8f0;">
              <template #header>
                <div style="display: flex; justify-content: space-between; align-items: center;">
                  <span style="font-weight: 700; color: #0f172a;">
                    📱 短信群发 vs 📞 电话回访 · 获客黄金法则与防拉黑红线
                  </span>
                  <el-tag type="danger" size="small">严格遵守沟通红线</el-tag>
                </div>
              </template>

              <el-table :data="channelRuleData" stripe style="width: 100%;">
                <el-table-column prop="channel" label="触达方式" width="130">
                  <template #default="{ row }">
                    <b>{{ row.channel }}</b>
                  </template>
                </el-table-column>
                <el-table-column prop="goldenTimes" label="黄金触达时间段" min-width="180">
                  <template #default="{ row }">
                    <span style="color: #0284c7; font-weight: 600;">{{ row.goldenTimes }}</span>
                  </template>
                </el-table-column>
                <el-table-column prop="advantage" label="核心优势与心理接受度" min-width="190" />
                <el-table-column prop="contentTips" label="文案结构与高转化模板" min-width="260" />
                <el-table-column prop="redLine" label="⚠️ 严禁触碰的红线" min-width="200">
                  <template #default="{ row }">
                    <span style="color: #dc2626; font-size: 12px;">{{ row.redLine }}</span>
                  </template>
                </el-table-column>
              </el-table>
            </el-card>

            <!-- 3. 门店营销常用助手工具箱 -->
            <div class="section-divider-title" id="copywriter" style="margin-top: 30px;">
              <span>🧰 门店常用营销智能助手工具箱</span>
              <span class="sub">包含拓客短信/微信文案智能生成器、充值活动毛利测算器，让老板经营精明算账！</span>
            </div>

            <el-row :gutter="20">
              <!-- 工具 A: 智能文案生成器 -->
              <el-col :xs="24" :sm="24" :md="14">
                <el-card shadow="never" class="toolbox-card">
                  <template #header>
                    <div class="tc-header">
                      <span>💬 智能营销拓客文案生成器</span>
                      <el-tag size="small" type="success">按客群与场景一键定制</el-tag>
                    </div>
                  </template>

                  <el-form label-width="90px" size="small">
                    <el-row :gutter="12">
                      <el-col :span="8">
                        <el-form-item label="营销场景">
                          <el-select v-model="copyScene" style="width: 100%;" @change="generateCopyTexts">
                            <el-option label="🇨🇳 国庆黄金周" value="NATIONAL_DAY" />
                            <el-option label="🥮 中秋团圆季" value="MID_AUTUMN" />
                            <el-option label="🎂 生日宠粉礼" value="BIRTHDAY" />
                            <el-option label="💎 高频老客礼" value="HIGH_FREQ" />
                            <el-option label="🌧️ 雨雪降温天" value="RAINY" />
                            <el-option label="🌟 周二会员日" value="MEMBER_DAY" />
                          </el-select>
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="目标客群">
                          <el-select v-model="copyTarget" style="width: 100%;" @change="generateCopyTexts">
                            <el-option label="👑 高净值VIP" value="VIP" />
                            <el-option label="💼 都市白领" value="WHITE_COLLAR" />
                            <el-option label="🤱 全职宝妈" value="MOM" />
                            <el-option label="🎓 年轻学生" value="STUDENT" />
                          </el-select>
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="优惠权益">
                          <el-select v-model="copyDiscount" style="width: 100%;" @change="generateCopyTexts">
                            <el-option label="满减现金券 (减60)" value="COUPON" />
                            <el-option label="爆款折扣 (7折)" value="DISCOUNT" />
                            <el-option label="到店送礼 (红酒/精油)" value="GIFT" />
                          </el-select>
                        </el-form-item>
                      </el-col>
                    </el-row>
                  </el-form>

                  <!-- 实时生成的 3 套文案 -->
                  <div class="generated-copy-list">
                    <div class="copy-card" v-for="(cp, idx) in generatedCopyList" :key="idx">
                      <div class="cp-head">
                        <span class="cp-style">{{ cp.styleName }}</span>
                        <el-button size="small" type="primary" link @click="handleCopyText(cp.content)">
                          📋 复制文案
                        </el-button>
                      </div>
                      <div class="cp-text">{{ cp.content }}</div>
                      <div class="cp-foot">
                        <span>适合通道：{{ cp.channel }} · 预估转化率：<b>{{ cp.convertRate }}</b></span>
                      </div>
                    </div>
                  </div>
                </el-card>
              </el-col>

              <!-- 工具 B: 充值营销毛利与让利测算器 -->
              <el-col :xs="24" :sm="24" :md="10" id="calculator">
                <el-card shadow="never" class="toolbox-card">
                  <template #header>
                    <div class="tc-header">
                      <span>🧮 充值活动赠送与毛利测算器</span>
                      <el-tag size="small" type="warning">帮老板防亏损做营销</el-tag>
                    </div>
                  </template>

                  <div style="font-size: 12px; color: #64748b; margin-bottom: 12px;">
                    很多老板做充 1000 送 300 以为亏了 300 元，实际服务项目毛利率高，真实成本远低于现金赠金！
                  </div>

                  <el-form label-width="120px" size="small">
                    <el-form-item label="充值本金 (元)">
                      <el-input-number v-model="calcRechargeAmount" :min="100" :step="500" style="width: 100%;" />
                    </el-form-item>
                    <el-form-item label="赠送金额 (元)">
                      <el-input-number v-model="calcGiftAmount" :min="0" :step="100" style="width: 100%;" />
                    </el-form-item>
                    <el-form-item label="服务项目毛利率 (%)">
                      <el-slider v-model="calcGrossMargin" :min="30" :max="95" :step="5" show-input />
                    </el-form-item>
                  </el-form>

                  <!-- 测算结论卡片 -->
                  <div class="calc-result-box">
                    <div class="cr-row">
                      <span class="cr-lbl">会员到手总价值：</span>
                      <span class="cr-val">￥{{ (calcRechargeAmount + calcGiftAmount).toFixed(2) }}</span>
                    </div>
                    <div class="cr-row">
                      <span class="cr-lbl">综合等效折扣率：</span>
                      <span class="cr-val" style="color: #d97706; font-size: 18px; font-weight: 800;">
                        {{ calcDiscountRate }} 折
                      </span>
                    </div>
                    <div class="cr-row">
                      <span class="cr-lbl">赠金真实耗材物料成本：</span>
                      <span class="cr-val" style="color: #059669; font-weight: 700;">
                        仅需 ￥{{ calcActualCost.toFixed(2) }} 元 (非现金￥{{ calcGiftAmount }})
                      </span>
                    </div>
                    <div class="cr-row">
                      <span class="cr-lbl">预计锁定到店消费频次：</span>
                      <span class="cr-val">{{ calcLockVisits }} 次以上</span>
                    </div>

                    <div class="cr-verdict" :class="calcIsHealthy ? 'verdict-pass' : 'verdict-warn'">
                      <b>💡 财务评估：</b>{{ calcVerdictText }}
                    </div>
                  </div>
                </el-card>
              </el-col>
            </el-row>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 弹窗 A: 创建裂变营销活动弹窗 -->
    <el-dialog v-model="openAddDialog" title="创建裂变营销活动" width="540px" destroy-on-close>
      <el-form :model="addForm" label-width="110px">
        <el-form-item label="活动类型" required>
          <el-radio-group v-model="addForm.type">
            <el-radio label="COUPON">满减/折扣券</el-radio>
            <el-radio label="GROUP">多人拼团立减</el-radio>
            <el-radio label="REFERRAL">老带新奖励金</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="活动主题名称" required>
          <el-input v-model="addForm.name" placeholder="如：金秋双人拼团烫染5折" />
        </el-form-item>
        <el-form-item label="优惠内容规则" required>
          <el-input v-model="addForm.ruleDesc" placeholder="如：满200减50元，或者2人成团各返30元奖励金" />
        </el-form-item>
        <el-form-item label="发放总名额">
          <el-input-number v-model="addForm.quota" :min="10" :step="50" style="width: 160px;" />
        </el-form-item>
        <el-form-item label="活动有效期">
          <el-date-picker
            v-model="addForm.dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="YYYY-MM-DD"
            style="width: 100%;"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openAddDialog = false">取消</el-button>
        <el-button type="primary" @click="handleSaveCampaign">确认发布活动</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 B: 营销裂变海报工坊与在线设计制作 -->
    <el-dialog
      v-model="openShareDialog"
      :title="'🎨 营销活动裂变海报工坊 - ' + (posterForm.title || currentShareRow?.name || '海报设计')"
      width="920px"
      top="4vh"
      destroy-on-close
      class="poster-studio-dialog"
    >
      <div class="poster-studio-layout">
        <!-- 左侧: 9:16 实时移动端海报预览区 -->
        <div class="poster-preview-panel">
          <div class="preview-card-header">
            <span class="preview-badge">📱 实时手机海报视觉效果 (所见即所得)</span>
            <span class="preview-scale">9 : 16 比例</span>
          </div>

          <!-- 真实海报卡片 DOM (根据选择的主题动态应用渐变和色彩) -->
          <div class="poster-card" :class="`theme-${posterForm.theme}`">
            <div class="poster-card-decor-circle-1"></div>
            <div class="poster-card-decor-circle-2"></div>

            <div class="poster-inner">
              <!-- 顶部品牌与活动标签 -->
              <div class="poster-head">
                <span class="poster-brand-tag">✦ {{ posterForm.storeName || '海马智慧体验店' }} ✦</span>
                <span class="poster-type-badge">{{ getTypeName(currentShareRow?.type) }}</span>
              </div>

              <!-- 主标题与副标题 -->
              <div class="poster-title-box">
                <h2 class="poster-main-title">{{ posterForm.title }}</h2>
                <p class="poster-sub-title">{{ posterForm.subtitle }}</p>
              </div>

              <!-- 核心优惠权益金券卡片 -->
              <div class="poster-voucher-card">
                <div class="voucher-highlight">{{ posterForm.highlightBadge }}</div>
                <div class="voucher-rule">{{ posterForm.ruleDesc }}</div>
                <div class="voucher-divider"></div>
                <div class="voucher-validity">
                  <span>📅 有效期限：{{ posterForm.validDate }}</span>
                </div>
              </div>

              <!-- 中间活动特色优势标签 -->
              <div class="poster-perks-tags">
                <span class="p-tag">✓ 到店即享</span>
                <span class="p-tag">✓ 可转赠亲友</span>
                <span class="p-tag">✓ 官方正品保障</span>
              </div>

              <!-- 底部扫码与门店信息 -->
              <div class="poster-foot">
                <div class="qr-code-box">
                  <img v-if="posterQrCodeUrl" :src="posterQrCodeUrl" alt="微信小程序获客码" class="qr-code-img" />
                  <div v-else class="qr-placeholder">
                    <el-icon class="is-loading"><Loading /></el-icon>
                  </div>
                  <span class="qr-tip">{{ posterForm.scanTip }}</span>
                </div>

                <div class="store-info-box">
                  <div class="store-name">🏢 {{ posterForm.storeName }}</div>
                  <div class="store-phone">📞 电话：{{ posterForm.storePhone }}</div>
                  <div class="store-address">📍 地址：{{ posterForm.storeAddress }}</div>
                </div>
              </div>
            </div>
          </div>

          <!-- 隐藏离屏用于高清 PNG 渲染导出的 Canvas (750 x 1200) -->
          <canvas ref="posterCanvasRef" width="750" height="1200" style="display: none;"></canvas>
        </div>

        <!-- 右侧: 海报元素在线编辑控制台 -->
        <div class="poster-editor-panel">
          <div class="editor-header">
            <span class="e-tit">⚙️ 自定义海报文案与视觉风格</span>
            <el-tag size="small" type="success">实时同步渲染</el-tag>
          </div>

          <el-scrollbar max-height="490px">
            <el-form :model="posterForm" label-width="96px" size="default" style="padding-right: 10px;">
              <!-- 视觉主题切换 -->
              <el-form-item label="视觉风格">
                <div class="theme-picker-group">
                  <div
                    v-for="t in posterThemes"
                    :key="t.key"
                    class="theme-chip"
                    :class="{ active: posterForm.theme === t.key }"
                    :style="{ background: t.previewBg, color: t.textColor }"
                    @click="posterForm.theme = t.key"
                  >
                    {{ t.name }}
                  </div>
                </div>
              </el-form-item>

              <el-form-item label="海报主标题" required>
                <el-input v-model="posterForm.title" placeholder="如：盛夏闺蜜同行 · 双人成团立享7折" maxlength="28" show-word-limit />
              </el-form-item>

              <el-form-item label="促销副标题" required>
                <el-input v-model="posterForm.subtitle" placeholder="如：限时狂欢 · 到店立享精美礼遇 · 全场通用" maxlength="36" show-word-limit />
              </el-form-item>

              <el-form-item label="高光标签" required>
                <el-input v-model="posterForm.highlightBadge" placeholder="如：立减 50 元 / 7 折成团 / 返 50 元奖励金" />
              </el-form-item>

              <el-form-item label="详细优惠规则" required>
                <el-input
                  v-model="posterForm.ruleDesc"
                  type="textarea"
                  :rows="2"
                  placeholder="如：单笔消费满199元即可直接抵扣，可与会员专享折扣同享"
                />
              </el-form-item>

              <el-form-item label="活动有效日期">
                <el-input v-model="posterForm.validDate" placeholder="如：即日起至 2026-10-31 止" />
              </el-form-item>

              <el-divider content-position="left"><span style="font-size: 12px; color: #64748b;">门店品牌与联络信息</span></el-divider>

              <el-form-item label="宣传门店名称">
                <el-input v-model="posterForm.storeName" placeholder="门店招牌全称" />
              </el-form-item>

              <el-form-item label="咨询热线电话">
                <el-input v-model="posterForm.storePhone" placeholder="前台咨询或客服手机号" />
              </el-form-item>

              <el-form-item label="门店详细地址">
                <el-input v-model="posterForm.storeAddress" placeholder="具体街道与门牌号" />
              </el-form-item>

              <el-form-item label="扫码引导文案">
                <el-input v-model="posterForm.scanTip" placeholder="如：微信长按识别小程序码 立即参与" />
              </el-form-item>

              <el-form-item label="推广落地链接">
                <el-input v-model="posterForm.shareUrl" placeholder="推广网址或小程序跳转落地页" readonly>
                  <template #append>
                    <el-button @click="handleCopyShareLink">复制链接</el-button>
                  </template>
                </el-input>
              </el-form-item>
            </el-form>
          </el-scrollbar>

          <div class="editor-actions">
            <el-button type="primary" size="large" icon="Download" style="flex: 1;" :loading="isDownloading" @click="handleDownloadPoster">
              ⬇️ 下载活动专属高清海报 (PNG)
            </el-button>
            <el-button type="info" plain size="large" icon="View" @click="handlePreviewPosterLarge">
              放大预览
            </el-button>
            <el-button plain size="large" @click="openShareDialog = false">
              关闭
            </el-button>
          </div>
        </div>
      </div>
    </el-dialog>

    <!-- 弹窗 B-2: 高清海报大图预览 -->
    <el-dialog v-model="showLargePreview" title="🔍 营销裂变海报高清大图预览" width="520px" destroy-on-close>
      <div style="text-align: center;">
        <img :src="largePreviewUrl" alt="海报大图" style="max-width: 100%; height: auto; border-radius: 12px; box-shadow: 0 12px 30px rgba(0,0,0,0.25);" />
      </div>
      <template #footer>
        <el-button @click="showLargePreview = false">关闭</el-button>
        <el-button type="primary" icon="Download" :loading="isDownloading" @click="handleDownloadPoster">
          立即下载高清海报
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 C: 💖 编辑/新增关怀事件参数与短信模板 -->
    <el-dialog
      v-model="openCareEventDialog"
      :title="editingCareEvent?.isCustom && !careEventsList.some(e => e.id === editingCareEvent?.id) ? '✨ 新增自定义关怀策略与自动化规则' : ('⚙️ 编辑关怀事件策略 - ' + editingCareEvent?.name)"
      width="640px"
      destroy-on-close
    >
      <div v-if="editingCareEvent">
        <!-- 快速推荐预设 -->
        <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px 12px; margin-bottom: 16px;">
          <div style="font-size: 12px; font-weight: 700; color: #334155; margin-bottom: 8px;">
            ⚡ 快速套用精选关怀模板预设（点击一键填充高转化参数与文案）：
          </div>
          <div style="display: flex; flex-wrap: wrap; gap: 8px;">
            <el-button
              v-for="p in carePresets"
              :key="p.name"
              size="small"
              type="primary"
              plain
              @click="handleApplyCarePreset(p)"
            >
              {{ p.name }}
            </el-button>
          </div>
        </div>

        <el-form :model="editingCareEvent" label-width="110px">
          <el-form-item label="事件名称" required>
            <el-input v-model="editingCareEvent.name" placeholder="如：💎 高频消费VIP忠诚回馈礼包" />
          </el-form-item>

          <el-row :gutter="16">
            <el-col :span="8">
              <el-form-item label="图标 Emoji">
                <el-input v-model="editingCareEvent.icon" placeholder="如 💎 / 🎁 / 🎂" />
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="主题色调">
                <el-select v-model="editingCareEvent.themeColor" style="width: 100%;">
                  <el-option label="尊贵紫 (高频忠诚)" value="purple" />
                  <el-option label="经典金 (尊享品质)" value="gold" />
                  <el-option label="喜庆红 (大促欢庆)" value="red" />
                  <el-option label="暖心橙 (生日暖意)" value="orange" />
                  <el-option label="浪漫粉 (女神专宠)" value="pink" />
                  <el-option label="天空蓝 (清爽暖心)" value="blue" />
                  <el-option label="翡翠绿 (健康天然)" value="emerald" />
                  <el-option label="高级灰 (老客温情)" value="slate" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="8">
              <el-form-item label="启用状态">
                <el-switch v-model="editingCareEvent.enabled" active-text="生效" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="关怀周期" required>
            <el-input v-model="editingCareEvent.period" placeholder="如：当月在店消费满 5 次即时触发 / 每年 10月01日~10月07日" />
          </el-form-item>

          <el-form-item label="触发条件描述" required>
            <el-input v-model="editingCareEvent.triggerDesc" placeholder="如：系统每日巡检当月消费满5次或累计消费满1000元活跃会员自动触发" />
          </el-form-item>

          <el-row :gutter="16">
            <el-col :span="14">
              <el-form-item label="赠送优惠券">
                <el-input v-model="editingCareEvent.couponGift" placeholder="如：高频忠诚会员50元无门槛券" />
              </el-form-item>
            </el-col>
            <el-col :span="10">
              <el-form-item label="赠送积分">
                <el-input-number v-model="editingCareEvent.bonusPoints" :min="0" :step="100" style="width: 100%;" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="实物礼品">
            <el-input v-model="editingCareEvent.giftItem" placeholder="如：高端定制旅行精油伴手礼一份" />
          </el-form-item>

          <el-form-item label="短信祝福文案" required>
            <el-input
              v-model="editingCareEvent.smsTemplate"
              type="textarea"
              :rows="4"
              placeholder="可用占位符：{会员姓名}、{门店名称}、{礼品名称}"
            />
            <div style="font-size: 11px; color: #64748b; margin-top: 4px;">
              支持动态变量：<code>{会员姓名}</code>、<code>{门店名称}</code>。巡检触发时将调用短信通道自动下发。
            </div>
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <el-button @click="openCareEventDialog = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmSaveCareEvent">保存并启用策略配置</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 D: 🚀 模拟自动触发关怀测试 -->
    <el-dialog
      v-model="openSimulateCareDialog"
      title="🚀 模拟自动关怀触发与短信下发测试"
      width="560px"
      destroy-on-close
    >
      <div style="background: #f0fdf4; border: 1px solid #bbf7d0; padding: 10px 14px; border-radius: 6px; margin-bottom: 16px;">
        <div style="font-weight: 700; color: #166534;">
          正在模拟系统定时巡检引擎
        </div>
        <div style="font-size: 12px; color: #15803d; margin-top: 2px;">
          选择任一真实会员与关怀事件，系统将立即模拟执行：注入会员卡包礼券、赠送积分、并通过短信网关发送祝福！
        </div>
      </div>

      <el-form :model="simulateForm" label-width="100px">
        <el-form-item label="选择关怀事件" required>
          <el-select
            v-model="simulateForm.eventId"
            style="width: 100%;"
            @change="handleSimulateEventChange"
          >
            <el-option
              v-for="ev in careEventsList"
              :key="ev.id"
              :label="ev.name"
              :value="ev.id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="目标受赠会员" required>
          <el-select
            v-model="simulateForm.memberId"
            filterable
            placeholder="输入会员姓名/手机号检索"
            style="width: 100%;"
            @change="handleSimulateMemberChange"
          >
            <el-option
              v-for="m in systemData.members"
              :key="m.id"
              :label="`${m.name} (${m.phone}) - ${m.levelName || '会员'}`"
              :value="m.id"
            />
          </el-select>
        </el-form-item>

        <!-- 实时生成的祝福短信预览 -->
        <div style="background: #fdf2f8; border: 1px solid #fbcfe8; padding: 10px 12px; border-radius: 8px; margin-bottom: 16px;">
          <div style="font-size: 12px; font-weight: 700; color: #9d174d; margin-bottom: 4px;">
            📱 实时下发短信预览：
          </div>
          <div style="font-size: 13px; color: #1e293b; line-height: 1.6;">
            {{ simulateSmsPreview }}
          </div>
          <div style="font-size: 11px; color: #9d174d; margin-top: 6px;">
            赠送礼遇：{{ currentSimulateEvent?.couponGift }} · 积分：+{{ currentSimulateEvent?.bonusPoints }} · 礼品：{{ currentSimulateEvent?.giftItem || '无' }}
          </div>
        </div>
      </el-form>

      <template #footer>
        <el-button @click="openSimulateCareDialog = false">取消</el-button>
        <el-button type="primary" icon="Promotion" @click="handleExecuteSimulateCare">
          立即执行模拟关怀触达
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗: 全渠道微信/支付宝公众号活动推送 -->
    <el-dialog v-model="openBroadcastModal" title="📢 全渠道微信/支付宝公众号活动即时推送" width="560px" destroy-on-close>
      <el-form label-width="110px">
        <el-alert
          type="success"
          :closable="false"
          show-icon
          title="全渠道即时触达说明"
          description="系统将一键向已关注微信服务号或支付宝生活号的全体粉丝推送卡片通知，提醒会员最新特惠与福利！"
          style="margin-bottom: 16px;"
        />

        <el-form-item label="活动主题" required>
          <el-input v-model="broadcastForm.title" placeholder="如: 🎉 迎金秋特惠季，会员充值享豪礼！" />
        </el-form-item>

        <el-form-item label="优惠简述" required>
          <el-input
            v-model="broadcastForm.content"
            type="textarea"
            :rows="3"
            placeholder="如: 进店即享全场8折，办卡充值立返20%无门槛消费金，点击查看活动详情并领券。"
          />
        </el-form-item>

        <el-form-item label="触达渠道">
          <el-checkbox-group :model-value="['WECHAT_MP', 'ALIPAY_LIFE']" disabled>
            <el-checkbox value="WECHAT_MP">🟢 微信服务号 (已关注粉丝)</el-checkbox>
            <el-checkbox value="ALIPAY_LIFE">🔵 支付宝生活号 (已关注粉丝)</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="openBroadcastModal = false">取消</el-button>
        <el-button
          type="success"
          icon="Promotion"
          :loading="broadcasting"
          @click="handleConfirmBroadcast"
        >
          立即全渠道推送
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox, ElNotification } from 'element-plus'
import QRCode from 'qrcode'
import { broadcastMarketingApi } from '../api'
import { useSystemDataStore } from '../stores/systemDataStore'

const route = useRoute()
const router = useRouter()
const systemData = useSystemDataStore()

const openBroadcastModal = ref(false)
const broadcasting = ref(false)
const broadcastForm = ref({
  title: '',
  content: ''
})

const handleOpenBroadcastMarketingModal = () => {
  broadcastForm.value = {
    title: '🎉 海马汇尊享特惠活动上线！',
    content: '尊敬的会员，门店新上线专属特惠活动，点击立即到店核销或进入会员中心领券享受！'
  }
  openBroadcastModal.value = true
}

const handlePushCampaignToChannel = (row: any) => {
  broadcastForm.value = {
    title: `🎉 门店特惠: ${row.name}`,
    content: `${row.ruleDesc || '进店即享专属优惠折扣'}，有效期至 ${row.validRange?.split('至')[1]?.trim() || '近期'}，全体关注会员可享！`
  }
  openBroadcastModal.value = true
}

const handleConfirmBroadcast = async () => {
  if (!broadcastForm.value.title || !broadcastForm.value.content) {
    ElMessage.warning('请完整填写活动主题与优惠简述')
    return
  }
  broadcasting.value = true
  try {
    const res = await broadcastMarketingApi({
      campaignTitle: broadcastForm.value.title,
      content: broadcastForm.value.content
    })
    if (res && res.code === 200) {
      ElNotification({
        title: '📢 营销活动全渠道推送成功',
        message: (res.data?.message) || '活动模板消息已成功推送给所有已关注微信公众号与支付宝生活号的会员！',
        type: 'success',
        duration: 5000
      })
      openBroadcastModal.value = false
    }
  } catch (err: any) {
    ElMessage.error(err?.message || '推送失败')
  } finally {
    broadcasting.value = false
  }
}

const activeMarketingTab = ref(route.query.tab === 'care' ? 'CARE_EVENTS' : 'CAMPAIGNS')
watch(() => route.query.tab, (val) => {
  if (val === 'care') {
    activeMarketingTab.value = 'CARE_EVENTS'
  }
})

const activityTypeFilter = ref('ALL')
const searchKeyword = ref('')
const currentPage = ref(1)
const pageSize = ref(10)

// 默认新人办卡营销配置
const defaultWelcomeConfig = {
  enabled: true,
  couponName: '新人开卡专享50元无门槛券',
  amount: 50,
  minSpend: 0,
  limitPerMember: 1,
  validityMode: 'DAYS',
  validDays: 30,
  fixedExpireDate: '2026-12-31',
  serviceScope: '全场通用',
  allowStacking: true,
  rulesText: '新会员入会开卡自动入账，单笔结算自动抵扣，可与会员折扣同享，逾期失效。'
}

const loadWelcomeConfig = () => {
  try {
    const raw = localStorage.getItem('seahorse_welcome_coupon_config')
    if (raw) {
      return { ...defaultWelcomeConfig, ...JSON.parse(raw) }
    }
  } catch (e) {
    console.error(e)
  }
  return { ...defaultWelcomeConfig }
}

const welcomeConfig = ref(loadWelcomeConfig())

const handleSaveWelcomeConfig = () => {
  if (!welcomeConfig.value.couponName) {
    ElMessage.warning('请填写优惠券名称')
    return
  }
  try {
    localStorage.setItem('seahorse_welcome_coupon_config', JSON.stringify(welcomeConfig.value))
    // 联动同步表格第一项
    if (systemData.campaigns && systemData.campaigns.length > 0) {
      systemData.campaigns[0].name = welcomeConfig.value.couponName
      systemData.campaigns[0].ruleDesc = welcomeConfig.value.minSpend > 0
        ? `新用户注册即赠${welcomeConfig.value.amount}元券，满${welcomeConfig.value.minSpend}元可用`
        : `新用户注册立赠${welcomeConfig.value.amount}元代金券，${welcomeConfig.value.serviceScope}`
      systemData.campaigns[0].status = welcomeConfig.value.enabled ? 'RUNNING' : 'FINISHED'
    }
    ElMessage.success('🎉 新人办卡赠券迎新活动策略已保存，新开卡会员将自动享受该策略！')
  } catch (e) {
    ElMessage.error('保存配置失败')
  }
}

const handleResetWelcomeConfig = () => {
  welcomeConfig.value = { ...defaultWelcomeConfig }
  localStorage.setItem('seahorse_welcome_coupon_config', JSON.stringify(welcomeConfig.value))
  ElMessage.info('已恢复为官方默认新人迎新发券策略')
}

// 获客裂变与营销活动 (绑定系统数据Store，新租户纯净零数据态)
const campaigns = computed(() => systemData.campaigns || [])

const runningCampaignsCount = computed(() => {
  return campaigns.value.filter(c => c.status === 'RUNNING').length
})

const filteredCampaigns = computed(() => {
  return campaigns.value.filter(item => {
    if (activityTypeFilter.value !== 'ALL' && item.type !== activityTypeFilter.value) return false
    if (searchKeyword.value) {
      const q = searchKeyword.value.toLowerCase()
      return item.name.toLowerCase().includes(q) || item.ruleDesc.toLowerCase().includes(q)
    }
    return true
  })
})

const paginatedCampaigns = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredCampaigns.value.slice(start, start + pageSize.value)
})

const getTypeTag = (type: string) => {
  switch (type) {
    case 'COUPON': return 'warning'
    case 'GROUP': return 'success'
    case 'REFERRAL': return 'danger'
    case 'POINTS': return 'primary'
    default: return 'info'
  }
}

const getTypeName = (type?: string) => {
  switch (type) {
    case 'COUPON': return '满减/折扣券'
    case 'GROUP': return '拼团立减'
    case 'REFERRAL': return '老带新返利'
    case 'POINTS': return '积分加速'
    default: return '裂变特惠'
  }
}

const getCareThemeTag = (eventId?: string) => {
  if (!eventId) return 'info'
  if (eventId.includes('NATIONAL') || eventId.includes('HOLIDAY')) return 'danger'
  if (eventId.includes('BIRTHDAY')) return 'warning'
  if (eventId.includes('LEVEL') || eventId.includes('UPGRADE')) return 'success'
  if (eventId.includes('RETURN') || eventId.includes('WAKE')) return 'primary'
  return 'info'
}

// 载入当前行业精选营销方案
const handleLoadIndustryPresets = () => {
  systemData.loadIndustryCampaigns()
  ElNotification({
    title: '✨ 营销方案装载成功',
    message: `已为当前行业【${systemData.currentIndustry}】成功注入精选获客裂变营销方案！`,
    type: 'success'
  })
}

// 创建活动
const openAddDialog = ref(false)
const addForm = ref({
  name: '',
  type: 'COUPON',
  ruleDesc: '',
  quota: 100,
  dateRange: ['2026-09-06', '2026-10-06']
})

const handleOpenAddCampaign = () => {
  addForm.value = {
    name: '',
    type: 'COUPON',
    ruleDesc: '',
    quota: 100,
    dateRange: ['2026-09-06', '2026-10-06']
  }
  openAddDialog.value = true
}

const handleSaveCampaign = () => {
  if (!addForm.value.name || !addForm.value.ruleDesc) {
    ElMessage.warning('请完整填写活动名称与优惠规则')
    return
  }
  const dates = addForm.value.dateRange || ['2026-09-06', '2026-10-06']
  systemData.addCampaign({
    name: addForm.value.name,
    type: addForm.value.type as any,
    ruleDesc: addForm.value.ruleDesc,
    participateCount: 0,
    revenueBrought: 0,
    validRange: `${dates[0]} ~ ${dates[1]}`,
    status: 'RUNNING'
  })
  ElMessage.success('裂变营销活动创建成功！已生成活动专属裂变码与海报')
  openAddDialog.value = false
}

const handleToggleCampaign = (row: any) => {
  systemData.toggleCampaignStatus(row.id)
  ElMessage.success(`活动【${row.name}】已${row.status === 'RUNNING' ? '开启' : '暂停'}`)
}

const handleDeleteCampaign = (row: any) => {
  ElMessageBox.confirm(`确定要删除营销活动【${row.name}】吗？`, '安全提示', {
    confirmButtonText: '删除',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    systemData.deleteCampaign(row.id)
    ElMessage.success('已删除该活动')
  })
}

// =========================================================================
// 营销裂变海报工坊与在线设计制作逻辑
// =========================================================================
const openShareDialog = ref(false)
const currentShareRow = ref<any>(null)
const posterCanvasRef = ref<HTMLCanvasElement | null>(null)
const posterQrCodeUrl = ref('')
const isDownloading = ref(false)
const showLargePreview = ref(false)
const largePreviewUrl = ref('')

interface PosterFormState {
  theme: 'red_gold' | 'black_gold' | 'ocean_blue' | 'emerald_green' | 'fashion_purple'
  title: string
  subtitle: string
  highlightBadge: string
  ruleDesc: string
  validDate: string
  storeName: string
  storePhone: string
  storeAddress: string
  scanTip: string
  shareUrl: string
}

const posterThemes = [
  { key: 'red_gold', name: '盛典红金', previewBg: 'linear-gradient(135deg, #b91c1c, #e11d48)', textColor: '#fbbf24' },
  { key: 'black_gold', name: '黑金尊享', previewBg: 'linear-gradient(135deg, #18181b, #27272a)', textColor: '#f59e0b' },
  { key: 'ocean_blue', name: '智慧海蓝', previewBg: 'linear-gradient(135deg, #0284c7, #2563eb)', textColor: '#ffffff' },
  { key: 'emerald_green', name: '自然翡翠', previewBg: 'linear-gradient(135deg, #059669, #047857)', textColor: '#ffffff' },
  { key: 'fashion_purple', name: '时尚靓紫', previewBg: 'linear-gradient(135deg, #7c3aed, #9333ea)', textColor: '#ffffff' }
]

const posterForm = ref<PosterFormState>({
  theme: 'red_gold',
  title: '',
  subtitle: '',
  highlightBadge: '',
  ruleDesc: '',
  validDate: '',
  storeName: '',
  storePhone: '',
  storeAddress: '',
  scanTip: '微信长按识别小程序码 立即参与',
  shareUrl: ''
})

const generatePosterQrCode = async (url: string) => {
  try {
    posterQrCodeUrl.value = await QRCode.toDataURL(url, {
      width: 280,
      margin: 1,
      color: {
        dark: '#0f172a',
        light: '#ffffff'
      }
    })
  } catch (err) {
    console.error('Failed to generate poster QR code', err)
  }
}

const handleShareCampaign = async (row: any) => {
  currentShareRow.value = row
  const defaultStoreName = systemData.stores[0]?.name || localStorage.getItem('seahorse_new_store_name') || '海马智慧体验示范店'
  const defaultStorePhone = systemData.stores[0]?.phone || localStorage.getItem('seahorse_new_boss_phone') || '400-888-9988'
  const defaultStoreAddress = systemData.stores[0]?.address || '万达广场1号门首层1028号'

  // 提取优惠亮点
  let highlight = '立享特惠'
  if (row.type === 'COUPON') {
    const match = (row.name + row.ruleDesc).match(/满?\d+减\d+元?/)
    highlight = match ? match[0] : (row.name.includes('折') ? '限时折扣' : '立减专享券')
  } else if (row.type === 'GROUP') {
    highlight = '双人拼团 · 享7折'
  } else if (row.type === 'REFERRAL') {
    highlight = '老带新 · 返50元'
  } else if (row.type === 'POINTS') {
    highlight = '会员日 · 双倍积分'
  }

  const shareUrl = `${window.location.origin}/marketing/join?campaignId=${row.id}&tenant=${localStorage.getItem('seahorse_tenant_id') || 'tenant_1'}`

  posterForm.value = {
    theme: 'red_gold',
    title: row.name,
    subtitle: row.ruleDesc || '限时狂欢 · 到店立享精美礼遇 · 全场通用',
    highlightBadge: highlight,
    ruleDesc: row.ruleDesc || '凭此海报到店出示扫码核销，即可享受活动专属特惠',
    validDate: row.validRange || '2026-09-01 ~ 2026-12-31',
    storeName: defaultStoreName,
    storePhone: defaultStorePhone,
    storeAddress: defaultStoreAddress,
    scanTip: '微信长按识别小程序码 立即参与',
    shareUrl
  }

  await generatePosterQrCode(shareUrl)
  openShareDialog.value = true
}

const handleCopyShareLink = async () => {
  if (!posterForm.value.shareUrl) return
  try {
    await navigator.clipboard.writeText(posterForm.value.shareUrl)
    ElMessage.success('📋 活动推广链接已复制到剪贴板！')
  } catch (e) {
    ElMessage.info('推广链接：' + posterForm.value.shareUrl)
  }
}

function drawRoundedRect(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number, radius: number) {
  ctx.beginPath()
  ctx.moveTo(x + radius, y)
  ctx.arcTo(x + width, y, x + width, y + height, radius)
  ctx.arcTo(x + width, y + height, x, y + height, radius)
  ctx.arcTo(x, y + height, x, y, radius)
  ctx.arcTo(x, y, x + width, y, radius)
  ctx.closePath()
}

function wrapText(ctx: CanvasRenderingContext2D, text: string, x: number, y: number, maxWidth: number, lineHeight: number, maxLines = 3) {
  const chars = text.split('')
  let line = ''
  let currentY = y
  let linesCount = 0

  for (let n = 0; n < chars.length; n++) {
    const testLine = line + chars[n]
    const metrics = ctx.measureText(testLine)
    const testWidth = metrics.width
    if (testWidth > maxWidth && n > 0) {
      linesCount++
      if (linesCount >= maxLines) {
        ctx.fillText(line + '...', x, currentY)
        return currentY + lineHeight
      }
      ctx.fillText(line, x, currentY)
      line = chars[n]
      currentY += lineHeight
    } else {
      line = testLine
    }
  }
  ctx.fillText(line, x, currentY)
  return currentY + lineHeight
}

const renderPosterToCanvas = async (canvas: HTMLCanvasElement, ctx: CanvasRenderingContext2D) => {
  const w = 750
  const h = 1200
  canvas.width = w
  canvas.height = h

  const theme = posterForm.value.theme

  // 1. 背景渐变
  const grad = ctx.createLinearGradient(0, 0, w, h)
  let accentColor = '#fbbf24'
  let cardBg = '#ffffff'
  let cardTextColor = '#1e293b'
  let highlightBg = '#dc2626'
  const highlightTextColor = '#ffffff'

  if (theme === 'red_gold') {
    grad.addColorStop(0, '#991b1b')
    grad.addColorStop(0.5, '#dc2626')
    grad.addColorStop(1, '#7f1d1d')
    accentColor = '#fde047'
    highlightBg = '#dc2626'
  } else if (theme === 'black_gold') {
    grad.addColorStop(0, '#18181b')
    grad.addColorStop(0.6, '#27272a')
    grad.addColorStop(1, '#09090b')
    accentColor = '#fbbf24'
    cardBg = '#27272a'
    cardTextColor = '#f8fafc'
    highlightBg = '#d97706'
  } else if (theme === 'ocean_blue') {
    grad.addColorStop(0, '#0369a1')
    grad.addColorStop(0.5, '#0284c7')
    grad.addColorStop(1, '#075985')
    accentColor = '#7dd3fc'
    highlightBg = '#0284c7'
  } else if (theme === 'emerald_green') {
    grad.addColorStop(0, '#065f46')
    grad.addColorStop(0.5, '#059669')
    grad.addColorStop(1, '#064e3b')
    accentColor = '#6ee7b7'
    highlightBg = '#059669'
  } else if (theme === 'fashion_purple') {
    grad.addColorStop(0, '#6b21a8')
    grad.addColorStop(0.5, '#7e22ce')
    grad.addColorStop(1, '#581c87')
    accentColor = '#f0abfc'
    highlightBg = '#7e22ce'
  }

  ctx.fillStyle = grad
  ctx.fillRect(0, 0, w, h)

  // 2. 装饰光斑和几何线条
  ctx.save()
  ctx.fillStyle = 'rgba(255, 255, 255, 0.06)'
  ctx.beginPath()
  ctx.arc(680, 100, 220, 0, Math.PI * 2)
  ctx.fill()
  ctx.beginPath()
  ctx.arc(80, 1100, 180, 0, Math.PI * 2)
  ctx.fill()
  ctx.restore()

  // 装饰边框
  ctx.save()
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.15)'
  ctx.lineWidth = 2
  drawRoundedRect(ctx, 24, 24, w - 48, h - 48, 24)
  ctx.stroke()
  ctx.restore()

  // 3. 顶部品牌条
  ctx.save()
  ctx.fillStyle = 'rgba(0, 0, 0, 0.25)'
  drawRoundedRect(ctx, 48, 56, w - 96, 48, 24)
  ctx.fill()
  ctx.fillStyle = accentColor
  ctx.font = 'bold 20px sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText(`✦ ${posterForm.value.storeName || '海马智慧门店'} · 官方获客专享特惠 ✦`, w / 2, 88)
  ctx.restore()

  // 4. 活动主标题
  ctx.save()
  ctx.fillStyle = '#ffffff'
  ctx.font = 'bold 44px sans-serif'
  ctx.textAlign = 'center'
  ctx.shadowColor = 'rgba(0, 0, 0, 0.4)'
  ctx.shadowBlur = 12
  wrapText(ctx, posterForm.value.title || '裂变营销特惠活动', w / 2, 180, w - 120, 56, 2)
  ctx.restore()

  // 5. 促销副标题
  ctx.save()
  ctx.fillStyle = 'rgba(255, 255, 255, 0.88)'
  ctx.font = '24px sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText(posterForm.value.subtitle || '限时狂欢 · 到店立享精美礼遇 · 全场通用', w / 2, 280)
  ctx.restore()

  // 6. 优惠券卡片 (Central Voucher Box)
  const cardX = 48
  const cardY = 320
  const cardW = w - 96
  const cardH = 360

  ctx.save()
  ctx.shadowColor = 'rgba(0, 0, 0, 0.25)'
  ctx.shadowBlur = 24
  ctx.shadowOffsetY = 12
  ctx.fillStyle = cardBg
  drawRoundedRect(ctx, cardX, cardY, cardW, cardH, 20)
  ctx.fill()
  if (theme === 'black_gold') {
    ctx.strokeStyle = '#d97706'
    ctx.lineWidth = 3
    ctx.stroke()
  }
  ctx.restore()

  // 卡片内高光标签 (Badge)
  ctx.save()
  ctx.fillStyle = highlightBg
  drawRoundedRect(ctx, w / 2 - 170, cardY + 36, 340, 68, 34)
  ctx.fill()
  ctx.fillStyle = highlightTextColor
  ctx.font = 'bold 34px sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText(posterForm.value.highlightBadge || '立享特惠', w / 2, cardY + 82)
  ctx.restore()

  // 卡片内规则说明
  ctx.save()
  ctx.fillStyle = cardTextColor
  ctx.font = 'bold 28px sans-serif'
  ctx.textAlign = 'center'
  wrapText(ctx, posterForm.value.ruleDesc || '单笔消费满额即可抵扣', w / 2, cardY + 160, cardW - 80, 40, 2)
  ctx.restore()

  // 卡片内虚线分割
  ctx.save()
  ctx.strokeStyle = '#cbd5e1'
  ctx.setLineDash([8, 6])
  ctx.beginPath()
  ctx.moveTo(cardX + 30, cardY + 260)
  ctx.lineTo(cardX + cardW - 30, cardY + 260)
  ctx.stroke()
  ctx.restore()

  // 卡片内有效期说明
  ctx.save()
  ctx.fillStyle = '#64748b'
  ctx.font = '22px sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText(`📅 活动有效期限：${posterForm.value.validDate || '2026-09-01 ~ 2026-12-31'}`, w / 2, cardY + 310)
  ctx.restore()

  // 7. 特色保障标签
  ctx.save()
  const perks = ['✓ 到店即享', '✓ 可转赠亲友', '✓ 官方正品保障', '✓ 专属VIP接待']
  const perkSpacing = (w - 120) / perks.length
  ctx.font = 'bold 20px sans-serif'
  ctx.fillStyle = accentColor
  ctx.textAlign = 'center'
  perks.forEach((p, idx) => {
    ctx.fillText(p, 60 + perkSpacing * (idx + 0.5), 730)
  })
  ctx.restore()

  // 8. 底部白色信息底板 (Footer Box)
  const footY = 770
  const footH = 370
  ctx.save()
  ctx.fillStyle = 'rgba(255, 255, 255, 0.96)'
  drawRoundedRect(ctx, 48, footY, w - 96, footH, 20)
  ctx.fill()
  ctx.restore()

  // 二维码绘制 (左侧)
  if (posterQrCodeUrl.value) {
    try {
      const qrImg = new Image()
      qrImg.src = posterQrCodeUrl.value
      await new Promise<void>((resolve, reject) => {
        if (qrImg.complete) return resolve()
        qrImg.onload = () => resolve()
        qrImg.onerror = () => reject()
      })
      ctx.drawImage(qrImg, 76, footY + 45, 200, 200)
    } catch (e) {
      console.error('Failed to draw QR image', e)
    }
  }

  // 二维码下方提示文字
  ctx.save()
  ctx.fillStyle = '#64748b'
  ctx.font = 'bold 18px sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText(posterForm.value.scanTip || '微信长按识别小程序码 立即参与', 176, footY + 285)
  ctx.fillText('参与即锁定优惠 名额有限', 176, footY + 315)
  ctx.restore()

  // 右侧门店信息
  ctx.save()
  ctx.fillStyle = '#0f172a'
  ctx.textAlign = 'left'
  ctx.font = 'bold 28px sans-serif'
  ctx.fillText(posterForm.value.storeName || '海马智慧体验店', 305, footY + 85)

  ctx.font = '22px sans-serif'
  ctx.fillStyle = '#334155'
  ctx.fillText(`📞 电话：${posterForm.value.storePhone || '400-888-9988'}`, 305, footY + 140)

  ctx.fillText('📍 地址：', 305, footY + 195)
  wrapText(ctx, posterForm.value.storeAddress || '万达广场1号门首层1028号', 390, footY + 195, 270, 32, 3)

  // 推荐人返利防伪小标
  ctx.fillStyle = '#dc2626'
  ctx.font = 'bold 18px sans-serif'
  ctx.fillText('🎁 老客推荐好友立享奖励金返现', 305, footY + 315)
  ctx.restore()
}

const handleDownloadPoster = async () => {
  if (!posterCanvasRef.value) return
  isDownloading.value = true
  try {
    const canvas = posterCanvasRef.value
    const ctx = canvas.getContext('2d')
    if (!ctx) throw new Error('Canvas context not available')

    await renderPosterToCanvas(canvas, ctx)

    const dataUrl = canvas.toDataURL('image/png', 1.0)
    const link = document.createElement('a')
    link.download = `${posterForm.value.title || '活动'}_营销裂变海报.png`
    link.href = dataUrl
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)

    ElMessage.success('🎉 高清营销海报已成功生成并下载！')
  } catch (err: any) {
    console.error(err)
    ElMessage.error('生成海报失败：' + (err.message || '未知错误'))
  } finally {
    isDownloading.value = false
  }
}

const handlePreviewPosterLarge = async () => {
  if (!posterCanvasRef.value) return
  const canvas = posterCanvasRef.value
  const ctx = canvas.getContext('2d')
  if (ctx) {
    await renderPosterToCanvas(canvas, ctx)
    largePreviewUrl.value = canvas.toDataURL('image/png', 1.0)
    showLargePreview.value = true
  }
}

// =========================================================================
// 💖 会员关怀与节日自动化事件逻辑
// =========================================================================
interface CareEventItem {
  id: string
  name: string
  icon: string
  period: string
  enabled: boolean
  triggerDesc: string
  couponGift: string
  bonusPoints: number
  giftItem: string
  smsTemplate: string
  themeColor: string
  touchedCount: number
}

const defaultCareEvents: CareEventItem[] = [
  {
    id: 'CARE_NATIONAL_DAY',
    name: '🇨🇳 国庆盛世华诞 · 黄金周金秋专宠特别企划',
    icon: '🇨🇳',
    period: '每年 10月01日 ~ 10月07日 (国庆黄金周)',
    enabled: true,
    triggerDesc: '国庆节前夕 09月30日 10:00 自动巡检执行，向全员派发国庆大礼包与盛惠券',
    couponGift: '国庆欢聚满减券 (满300减60元)',
    bonusPoints: 200,
    giftItem: '进店享国庆红运礼盒 (专属洗护/精油伴手礼)',
    smsTemplate: '【海马智慧】盛世华诞，举国同庆！尊贵的{会员姓名}，我们为您备好国庆黄金周专享60元盛惠券及双倍积分礼遇，进店还可领专属国庆红运伴手礼，祝您国庆假期阖家安康，欢度佳节！',
    themeColor: 'red',
    touchedCount: 0
  },
  {
    id: 'CARE_BIRTHDAY',
    name: '🎂 会员生日专属暖心宠粉',
    icon: '🎂',
    period: '会员生日当天 09:00 自动巡检触发',
    enabled: true,
    triggerDesc: '系统每日清晨巡检当天生日会员，自动注入生日礼券并推送定制祝福短信',
    couponGift: '生日专属免单礼金券 (最高立减100元)',
    bonusPoints: 500,
    giftItem: '到店赠精美生日蛋糕/果盘+定制鲜花',
    smsTemplate: '【海马智慧】祝您生日快乐！亲爱的{会员姓名}，海马全体伙伴愿您岁岁常欢愉，万事皆胜意！已为您卡包充入100元生日礼金券及500关怀积分，生日当周到店再享定制生日礼！',
    themeColor: 'orange',
    touchedCount: 0
  },
  {
    id: 'CARE_SPRING_FESTIVAL',
    name: '🧧 岁序更替 · 新春开门大拜年',
    icon: '🧧',
    period: '农历除夕 ~ 正月初七 09:00',
    enabled: true,
    triggerDesc: '除夕前3天自动巡检向在籍会员派发新春压岁大红包与开门利是',
    couponGift: '新春大吉88元压岁抵用券',
    bonusPoints: 300,
    giftItem: '进店赠新春定制春联/福字礼袋',
    smsTemplate: '【海马智慧】岁序更替，华章日新！亲爱的{会员姓名}，给您拜年啦！特为您送上88元新春压岁抵用券与300积分，进店即可领取新春福气礼包，祝您新春吉庆，万事如意！',
    themeColor: 'crimson',
    touchedCount: 0
  },
  {
    id: 'CARE_MID_AUTUMN',
    name: '🥮 中秋花好月圆 · 阖家欢聚',
    icon: '🥮',
    period: '每年农历八月十五 (中秋节前2天)',
    enabled: true,
    triggerDesc: '中秋节前自动派送花好月圆分享礼券，支持亲友同享',
    couponGift: '中秋双人同行立减50元券',
    bonusPoints: 200,
    giftItem: '到店专享定制烘焙月饼礼盒',
    smsTemplate: '【海马智慧】但愿人长久，千里共婵娟！亲爱的{会员姓名}，中秋佳节将至，海马特赠您50元欢聚礼券与中秋定制月饼礼盒，期待与您和家人共赏良宵！',
    themeColor: 'gold',
    touchedCount: 0
  },
  {
    id: 'CARE_WOMEN_DAY',
    name: '🌸 三八国际妇女节 · 女神专宠日',
    icon: '🌸',
    period: '每年 03月08日 09:30',
    enabled: true,
    triggerDesc: '三八节清晨自动定向女性会员派送女神专属美丽津贴',
    couponGift: '全场美丽项目7.5折专宠券',
    bonusPoints: 380,
    giftItem: '到店赠厄瓜多尔进口红玫瑰1支',
    smsTemplate: '【海马智慧】致敬闪闪发光的你！亲爱的{会员姓名}女神，愿你眼里有光芒，手中握繁花！特呈送7.5折美丽礼遇与380积分，3月8日到店更享手捧玫瑰赠礼！',
    themeColor: 'pink',
    touchedCount: 0
  },
  {
    id: 'CARE_WAKE_UP',
    name: '💤 唤醒关怀 · 沉睡老客温情召回',
    icon: '💤',
    period: '距离上次到店超60天未消费',
    enabled: true,
    triggerDesc: '系统每周一定时巡检未到店满60天会员，定向发放无门槛召回礼券',
    couponGift: '老朋友专属无门槛30元抵扣券',
    bonusPoints: 100,
    giftItem: '进店免费体验头皮养护SPA一次',
    smsTemplate: '【海马智慧】好久不见，甚是想念！亲爱的{会员姓名}，海马为您备好了专属30元老朋友回归券及免费头皮SPA护理，期待再次与您相聚！',
    themeColor: 'slate',
    touchedCount: 0
  }
]

const loadCareEvents = (): CareEventItem[] => {
  try {
    const raw = localStorage.getItem('seahorse_member_care_events')
    if (raw) {
      const parsed = JSON.parse(raw)
      if (Array.isArray(parsed) && parsed.length > 0) {
        // 重置历史遗留的虚假触达次数
        parsed.forEach((e: any) => {
          if ([680, 142, 520, 388, 295, 86].includes(e.touchedCount)) {
            e.touchedCount = 0
          }
        })
        localStorage.setItem('seahorse_member_care_events', JSON.stringify(parsed))
        return parsed
      }
    }
  } catch (e) {
    console.error(e)
  }
  return JSON.parse(JSON.stringify(defaultCareEvents))
}

const careEventsList = ref<CareEventItem[]>(loadCareEvents())

const handleSaveCareEvents = () => {
  try {
    localStorage.setItem('seahorse_member_care_events', JSON.stringify(careEventsList.value))
    ElMessage.success('会员关怀事件配置已成功保存更新！')
  } catch (e) {
    ElMessage.error('保存关怀配置失败')
  }
}

const nationalDayEvent = computed(() => careEventsList.value.find(e => e.id === 'CARE_NATIONAL_DAY'))
const otherCareEvents = computed(() => careEventsList.value.filter(e => e.id !== 'CARE_NATIONAL_DAY'))
const activeCareEventsCount = computed(() => careEventsList.value.filter(e => e.enabled).length)

// 关怀日志台账
interface CareLogItem {
  id: number
  memberName: string
  phone: string
  memberLevel: string
  eventId: string
  eventName: string
  giftSummary: string
  smsContent: string
  sendTime: string
  statusText: string
}

// 真实初始状态下无任何假记录
const defaultCareLogs: CareLogItem[] = []

const loadCareLogs = (): CareLogItem[] => {
  try {
    const raw = localStorage.getItem('seahorse_care_logs')
    if (raw) {
      const parsed = JSON.parse(raw)
      if (Array.isArray(parsed)) {
        // 彻底剔除林心如、张国荣等历史演示假数据
        const dummyNames = ['林心如', '张国荣', '王菲菲', '陈伟霆', '周慧敏']
        const clean = parsed.filter(item => !dummyNames.includes(item.memberName) && item.id > 100)
        if (clean.length !== parsed.length) {
          localStorage.setItem('seahorse_care_logs', JSON.stringify(clean))
        }
        return clean
      }
    }
  } catch (e) {
    console.error(e)
  }
  return []
}

const careLogsList = ref<CareLogItem[]>(loadCareLogs())
const careLogFilterEvent = ref('')
const careLogKeyword = ref('')
const careLogCurrentPage = ref(1)
const careLogPageSize = ref(10)

const filteredCareLogs = computed(() => {
  return careLogsList.value.filter(item => {
    if (careLogFilterEvent.value && !item.eventName.includes(careLogFilterEvent.value)) return false
    if (careLogKeyword.value) {
      const q = careLogKeyword.value.trim().toLowerCase()
      const matchName = item.memberName.toLowerCase().includes(q)
      const matchPhone = item.phone.includes(q)
      const matchSms = item.smsContent.toLowerCase().includes(q)
      if (!matchName && !matchPhone && !matchSms) return false
    }
    return true
  })
})

const paginatedCareLogs = computed(() => {
  const start = (careLogCurrentPage.value - 1) * careLogPageSize.value
  return filteredCareLogs.value.slice(start, start + careLogPageSize.value)
})

// 关怀预设模板
const carePresets = [
  {
    name: '💎 高频消费VIP忠诚回馈礼包',
    icon: '💎',
    period: '当月在店消费满 5 次即时触发',
    triggerDesc: '系统每日巡检当月消费满5次或累计消费满1000元活跃会员自动触发',
    couponGift: '高频忠诚会员50元无门槛券',
    bonusPoints: 300,
    giftItem: '高端定制旅行精油伴手礼一份',
    smsTemplate: '【海马智慧】尊贵的{会员姓名}，感谢您本月多次莅临支持！您已成功解锁本店【高频消费忠诚挚友】专享礼遇：50元无门槛立减券已入账，并赠300积分，进店还可免费领定制精油礼盒，期待再次为您服务！',
    themeColor: 'purple'
  },
  {
    name: '💰 大额充值VIP尊享礼遇',
    icon: '💰',
    period: '单笔储值充值达标即时触发',
    triggerDesc: '会员单笔储值本金满 2000 元自动巡检发放',
    couponGift: 'VIP私享项目升级券 (可升尊享包间)',
    bonusPoints: 500,
    giftItem: '高端红酒品鉴礼盒 / 奢养发膜正装',
    smsTemplate: '【海马智慧】感谢您的鼎力支持！亲爱的{会员姓名}，您已晋级为本店尊享VIP，为您奉上私享升级礼遇与500积分，特供礼品已为您备好，随时恭候您的光临！',
    themeColor: 'gold'
  },
  {
    name: '💖 入会一周年感恩回馈礼',
    icon: '💖',
    period: '注册入会满 365 天当天 10:00',
    triggerDesc: '系统每日巡检入会满 1 周年的老会员，发放感恩厚礼',
    couponGift: '周年感恩免单券 (最高立减80元)',
    bonusPoints: 365,
    giftItem: '品牌定制香氛卡 / 手工润唇膏',
    smsTemplate: '【海马智慧】时光飞逝，感谢相伴365天！亲爱的{会员姓名}，今天是我们相伴一周年纪念日，为您呈上80元周年礼券与365感恩积分，期待未来继续陪伴您的每一刻！',
    themeColor: 'pink'
  },
  {
    name: '🌧️ 恶劣天气 · 暖心雨雪专属关怀',
    icon: '🌧️',
    period: '雨雪降温或台风恶劣天气当天',
    triggerDesc: '暴雨、大雪或断崖降温天气由店长一键巡检触发定向关怀',
    couponGift: '雨天暖心同行立减30元券',
    bonusPoints: 100,
    giftItem: '进店享热特调姜茶/咖啡 + 暖手宝',
    smsTemplate: '【海马智慧】天寒风雨骤，海马暖人心！亲爱的{会员姓名}，今日气温骤降且有降雨，外出注意保暖避雨！海马已为您准备热饮姜茶与暖心30元立减券，累了欢迎进店避雨小憩！',
    themeColor: 'blue'
  }
]

// 编辑/新增关怀事件弹窗
const openCareEventDialog = ref(false)
const editingCareEvent = ref<any>(null)

const handleOpenAddCareEvent = () => {
  editingCareEvent.value = {
    id: 'CARE_CUSTOM_' + Date.now(),
    name: '💎 高频消费VIP忠诚回馈礼包',
    icon: '💎',
    period: '当月在店消费满 5 次即时触发',
    enabled: true,
    triggerDesc: '系统每日巡检当月消费满5次或累计消费满1000元活跃会员自动触发',
    couponGift: '高频忠诚会员50元无门槛券',
    bonusPoints: 300,
    giftItem: '高端定制旅行精油伴手礼一份',
    smsTemplate: '【海马智慧】尊贵的{会员姓名}，感谢您本月多次莅临支持！您已成功解锁本店【高频消费忠诚挚友】专享礼遇：50元无门槛立减券已入账，并赠300积分，进店还可免费领定制精油礼盒，期待再次为您服务！',
    themeColor: 'purple',
    touchedCount: 0,
    isCustom: true
  }
  openCareEventDialog.value = true
}

const handleApplyCarePreset = (preset: any) => {
  if (!editingCareEvent.value) return
  editingCareEvent.value = {
    ...editingCareEvent.value,
    name: preset.name,
    icon: preset.icon,
    period: preset.period,
    triggerDesc: preset.triggerDesc,
    couponGift: preset.couponGift,
    bonusPoints: preset.bonusPoints,
    giftItem: preset.giftItem,
    smsTemplate: preset.smsTemplate,
    themeColor: preset.themeColor
  }
  ElMessage.success(`已套用【${preset.name}】策略预设模板`)
}

const handleDeleteCareEvent = (ev: any) => {
  ElMessageBox.confirm(`确定要删除自定义关怀事件【${ev.name}】吗？`, '删除确认', {
    confirmButtonText: '删除',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    careEventsList.value = careEventsList.value.filter(e => e.id !== ev.id)
    handleSaveCareEvents()
    ElMessage.success('已删除该自定义关怀事件')
  })
}

const handleEditCareEvent = (ev: any) => {
  if (!ev) return
  editingCareEvent.value = JSON.parse(JSON.stringify(ev))
  openCareEventDialog.value = true
}

const handleConfirmSaveCareEvent = () => {
  if (!editingCareEvent.value) return
  const index = careEventsList.value.findIndex(e => e.id === editingCareEvent.value.id)
  if (index !== -1) {
    careEventsList.value[index] = { ...editingCareEvent.value }
  } else {
    careEventsList.value.push({ ...editingCareEvent.value })
  }
  handleSaveCareEvents()
  openCareEventDialog.value = false
  ElMessage.success(`关怀事件【${editingCareEvent.value.name}】策略配置更新成功！`)
}

// 模拟自动关怀触达
const openSimulateCareDialog = ref(false)
const simulateForm = ref({
  eventId: 'CARE_NATIONAL_DAY',
  memberId: '' as any
})

const currentSimulateEvent = computed(() => {
  return careEventsList.value.find(e => e.id === simulateForm.value.eventId) || (careEventsList.value.length > 0 ? careEventsList.value[0] : null)
})

const currentSimulateMember = computed(() => {
  return systemData.members.find(m => String(m.id) === String(simulateForm.value.memberId)) ||
         (systemData.members.length > 0 ? systemData.members[0] : null)
})

const simulateSmsPreview = computed(() => {
  const tpl = currentSimulateEvent.value?.smsTemplate || ''
  const mName = currentSimulateMember.value?.name || '贵宾'
  return tpl.replace(/\{会员姓名\}/g, mName).replace(/\{门店名称\}/g, '海马智慧旗舰店')
})

const handleOpenSimulateCare = (ev?: any) => {
  if (ev?.id) {
    simulateForm.value.eventId = ev.id
  } else {
    simulateForm.value.eventId = 'CARE_NATIONAL_DAY'
  }
  if (systemData.members && systemData.members.length > 0) {
    simulateForm.value.memberId = systemData.members[0].id
  } else {
    simulateForm.value.memberId = undefined
  }
  openSimulateCareDialog.value = true
}

const handleSimulateEventChange = () => {}
const handleSimulateMemberChange = () => {}

const handleExecuteSimulateCare = () => {
  const member = currentSimulateMember.value
  const ev = currentSimulateEvent.value
  if (!member || !ev) {
    ElMessage.warning('请选择有效的关怀事件和会员')
    return
  }

  // 1. 生成关怀流水台账
  const now = new Date()
  const timeStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`
  const perks = [ev.couponGift, ev.bonusPoints ? `+${ev.bonusPoints}关怀积分` : '', ev.giftItem ? `赠${ev.giftItem}` : ''].filter(Boolean).join(' · ')
  const smsText = simulateSmsPreview.value

  const newLog: CareLogItem = {
    id: Date.now(),
    memberName: member.name,
    phone: member.phone,
    memberLevel: member.levelName || '标准会员',
    eventId: ev.id,
    eventName: ev.name,
    giftSummary: perks,
    smsContent: smsText,
    sendTime: timeStr,
    statusText: '短信已送达'
  }

  careLogsList.value.unshift(newLog)
  try {
    localStorage.setItem('seahorse_care_logs', JSON.stringify(careLogsList.value))
  } catch (e) {}

  // 2. 累加事件触达人次
  ev.touchedCount = (ev.touchedCount || 0) + 1
  handleSaveCareEvents()

  // 3. 给会员卡包充入关怀积分
  if (ev.bonusPoints && member) {
    member.points = (member.points || 0) + ev.bonusPoints
  }

  openSimulateCareDialog.value = false

  ElNotification({
    title: '🎉 关怀触达模拟执行成功！',
    message: `已向会员【${member.name} (${member.phone})】下发了【${ev.name}】关怀礼遇：${perks}，祝福短信已通过短信网关秒级送达！`,
    type: 'success',
    duration: 5000
  })
}

// =========================================================================
// 📅 全年12月营销日历与获客时机助手数据及逻辑
// =========================================================================
const currentRealMonth = 9
const selectedMonth = ref(9)

const scrollSection = (id: string) => {
  const el = document.getElementById(id)
  if (el) el.scrollIntoView({ behavior: 'smooth' })
}

const isRealToday = (m: number, d: number) => {
  return m === 9 && d === 7
}

// 生成 1~12 月完整日历
const generateMonthDays = (month: number, totalDays: number, startWeekday: number, holidayRanges: [number, number][], windowRanges: [number, number][], solars: Record<number, string>) => {
  const list: any[] = []
  for (let i = 1; i <= totalDays; i++) {
    const isHoliday = holidayRanges.some(r => i >= r[0] && i <= r[1])
    const isWindow = windowRanges.some(r => i >= r[0] && i <= r[1])
    const weekday = (startWeekday + i - 1) % 7
    const isWeekend = weekday === 0 || weekday === 6

    let type = 'normal'
    let label = ''

    if (isHoliday) {
      type = 'holiday'
      label = '假'
    } else if (isWindow) {
      type = 'window'
      label = '黄金期'
    } else if (isWeekend) {
      type = 'weekend'
      label = '周末档'
    }

    list.push({
      day: i,
      type,
      label,
      solarTerm: solars[i] || ''
    })
  }
  return list
}

const allMonthsData = ref<any[]>([
  {
    month: 1,
    shortTag: '元旦开门红',
    theme: '元旦开门红 · 新年焕新季',
    holidayDays: 3,
    leadTime: '提前 5 天宣发 (12月26日前后)',
    campaignPlan: '主打“新年新气象，从头美到脚”。发起元旦满减券与老带新开门利是红包，主推年度尊享储值与家庭次卡。',
    featuredOffer: '全家欢聚洗护烫染套餐 / 1000元新年开门红储值特惠 (送300)',
    targetAudience: '高净值在籍VIP老客、返乡团聚白领、全家消费客群',
    bossAdvice: '元旦假期是全年首个消费高峰，全员取消轮休提前备料，确保洗护耗材与礼盒库存充裕。',
    startWeekday: 4,
    days: generateMonthDays(1, 31, 4, [[1, 3]], [[4, 6]], { 5: '小寒', 20: '大寒' })
  },
  {
    month: 2,
    shortTag: '喜迎新春',
    theme: '岁序更替 · 欢度新春大拜年',
    holidayDays: 8,
    leadTime: '提前 10 天启动 (节前扫尘高峰)',
    campaignPlan: '年前 15 天进入美业洗发剪烫高峰期！除夕前大派新春压岁大红包与拜年福礼，锁定年后复购回头客。',
    featuredOffer: '新春大吉88元压岁抵用券 / 到店领定制春联红运福袋',
    targetAudience: '全体活跃与沉睡会员、走亲访友形象升级客群',
    bossAdvice: '腊月二十三到除夕客流爆发，建议实行分时段预约错峰到店，避免排队客怨。',
    startWeekday: 0,
    days: generateMonthDays(2, 28, 0, [[15, 23]], [[5, 14]], { 4: '立春', 19: '雨水' })
  },
  {
    month: 3,
    shortTag: '女神盛典',
    theme: '三八妇女节 · 丽人专宠美丽盛典',
    holidayDays: 0,
    leadTime: '提前 4 天宣发 (3月4日前后)',
    campaignPlan: '致敬女性力量！全场美丽项目 7.5 折起，闺蜜同行第二人半价，到店赠厄瓜多尔进口玫瑰与定制伴手礼。',
    featuredOffer: '女神专属美丽7.5折专宠券 / 头皮逆龄SPA+面部水润焕肤组合',
    targetAudience: '职场精英女性、全职宝妈、女性闺蜜客群',
    bossAdvice: '3月是春季过敏与干枯高发期，主打“水润修复抗衰”概念，极易促成大额年卡转化。',
    startWeekday: 0,
    days: generateMonthDays(3, 31, 0, [], [[5, 8]], { 5: '惊蛰', 20: '春分' })
  },
  {
    month: 4,
    shortTag: '清明踏青',
    theme: '清明春暖 · 户外踏青防晒修护',
    holidayDays: 3,
    leadTime: '提前 3 天启动宣发',
    campaignPlan: '结合春季户外出游与换季护理需求，推出“清透防敏护发”与小长假出游妆造预约，赠送防晒便携喷雾。',
    featuredOffer: '春日踏青头皮清爽排毒SPA (立减50元) / 闺蜜美甲双人拼团',
    targetAudience: '热爱户外露营、摄影拍照的年轻白领与学生',
    bossAdvice: '清明假期多为短途出行，可在假日前一天下午重点邀约晚间洗吹与美甲。',
    startWeekday: 3,
    days: generateMonthDays(4, 30, 3, [[4, 6]], [[1, 3]], { 4: '清明', 20: '谷雨' })
  },
  {
    month: 5,
    shortTag: '五一/520',
    theme: '致敬劳动者 · 520心动表白季',
    holidayDays: 5,
    leadTime: '提前 6 天启动 (4月25日)',
    campaignPlan: '五一长假出游客流爆棚，紧随其后520心动告白日。推出情侣双人同行立减、情侣香氛礼盒与夏日亮色烫染。',
    featuredOffer: '520二人心动浪漫套餐 (直降131.4元) / 满300减80欢聚券',
    targetAudience: '年轻情侣、闺蜜同伴、五一长假出游变美客群',
    bossAdvice: '五一前夕是全店客流峰值，合理规划技师提成激励，最大化拉动客单价。',
    startWeekday: 5,
    days: generateMonthDays(5, 31, 5, [[1, 5]], [[18, 20]], { 5: '立夏', 21: '小满' })
  },
  {
    month: 6,
    shortTag: '端午/年中',
    theme: '端午佳节 · 618年中大促狂欢',
    holidayDays: 3,
    leadTime: '提前 7 天预热 (6月11日)',
    campaignPlan: '打响年中保卫战！线上微商城与线下门店同步推出 618 狂欢秒杀，次卡买5送2，充值赠送翻倍。',
    featuredOffer: '618年中狂欢卡 (充2000送600) / 经典次卡买五送二',
    targetAudience: '高消费储值老客、精打细算型囤卡会员',
    bossAdvice: '618大促是锁定会员下半年到店现金流的关键战役，赠品可用实物礼盒替代现金折让。',
    startWeekday: 1,
    days: generateMonthDays(6, 30, 1, [[19, 21]], [[15, 18]], { 5: '芒种', 21: '夏至' })
  },
  {
    month: 7,
    shortTag: '盛夏暑期',
    theme: '盛夏热浪 · 暑期畅爽降温狂欢',
    holidayDays: 0,
    leadTime: '每周五定期推送',
    campaignPlan: '高温防晒降温季！推出“冰凉薄荷头皮清凉SPA”、“毕业季学生凭准考证立减60元”，发力夜间微醺经济。',
    featuredOffer: '冰爽薄荷沁凉头皮护理单次体验 (仅需￥68) / 学生专享染发7折',
    targetAudience: '毕业生、暑期休假学生、下班避暑白领',
    bossAdvice: '夏日白天户外较热，客流集中在 18:00~21:30，建议延长晚间营业时间并提供冷饮特调。',
    startWeekday: 3,
    days: generateMonthDays(7, 31, 3, [], [[10, 12], [24, 26]], { 7: '小暑', 23: '大暑' })
  },
  {
    month: 8,
    shortTag: '七夕良辰',
    theme: '金风玉露 · 七夕中国情人节浪漫季',
    holidayDays: 0,
    leadTime: '提前 5 天宣发 (8月14日前后)',
    campaignPlan: '农历七月初七中国情人节！全店布置鲜花与浪漫气球打卡点，情侣同行第二单免单或送红酒，拍照小红书打卡返利。',
    featuredOffer: '七夕双人同行浪漫剪染礼包 (赠定制鲜花) / 情侣约会心动造型套餐',
    targetAudience: '年轻情侣、夫妻周年庆会员、潮流达人',
    bossAdvice: '七夕当天下午15:00~19:00约会造型需求激增，主推“30分钟快捷精致出街约会造型”。',
    startWeekday: 6,
    days: generateMonthDays(8, 31, 6, [], [[15, 19]], { 7: '立秋', 23: '处暑' })
  },
  {
    month: 9,
    shortTag: '金秋中秋',
    theme: '感念师恩 · 中秋花好月圆人团圆',
    holidayDays: 3,
    leadTime: '提前 6 天启动 (9月9日前后)',
    campaignPlan: '双节同庆！教师节凭教师资格证尊享免费头皮检测与洗护，中秋节向老会员派发中秋定制月饼礼盒与阖家团圆满减券。',
    featuredOffer: '中秋双人同行立减50元券 / 满300赠定制手工流心月饼礼盒',
    targetAudience: '教师及知识分子、合家团聚家庭客、商务伴手礼需求老客',
    bossAdvice: '中秋假期后立刻进入国庆黄金周倒计时，此阶段需同步启动国庆大客排期锁定！',
    startWeekday: 2,
    days: generateMonthDays(9, 30, 2, [[15, 17]], [[26, 30]], { 7: '白露', 23: '秋分' })
  },
  {
    month: 10,
    shortTag: '国庆黄金周',
    theme: '盛世华诞 · 举国同庆黄金周金秋特别企划',
    holidayDays: 7,
    leadTime: '提前 7 天深度宣发 (9月24日启动)',
    campaignPlan: '全年消费与客流巅峰！结合7天长假，上线“满300减60盛惠券”、“消费双倍积分(200%)”及进店赠“国庆红运伴手礼盒”。',
    featuredOffer: '国庆盛惠欢聚券 (满300减60元) / 进店享国庆红运精油礼盒',
    targetAudience: '全店活跃在籍会员、假日至本地旅游的流动品质客群',
    bossAdvice: '国庆长假前3天客流最集中，必须提前锁定制预约；国庆后3天可主推“返程修护SPA”。',
    startWeekday: 4,
    days: generateMonthDays(10, 31, 4, [[1, 7]], [[24, 30]], { 8: '寒露', 23: '霜降' })
  },
  {
    month: 11,
    shortTag: '双11狂欢',
    theme: '初冬暖心 · 双十一全民狂欢购物季',
    holidayDays: 0,
    leadTime: '提前 10 天蓄水 (11月1日启动)',
    campaignPlan: '线上微商城拼团+线下实体店同权！主推“冬季头皮滋养大促”、“充值满赠大牌好礼”，全面锁定年终消费额。',
    featuredOffer: '双11狂欢储值卡 (充3000立赠800+进口吹风机) / BOM耗材爆款买一送一',
    targetAudience: '高客单储值客群、家庭集中囤货型会员',
    bossAdvice: '双11避免简单打折降价损伤品牌，应用“买赠高品质实物礼品”提升顾客感知价值。',
    startWeekday: 0,
    days: generateMonthDays(11, 30, 0, [], [[1, 11]], { 7: '立冬', 22: '小雪' })
  },
  {
    month: 12,
    shortTag: '双12跨年',
    theme: '双12年终盛典 · 平安圣诞跨年倒计时',
    holidayDays: 0,
    leadTime: '提前 8 天宣发 (12月4日与12月20日两波)',
    campaignPlan: '年终收官冲刺战！打响双12年终盛典与平安夜跨年趴，推出“年终积分清零兑好礼”、“跨年新年倒计时变美专列”。',
    featuredOffer: '跨年换装定制洗剪烫染尊享套票 / 积分兑换年终高端伴手礼',
    targetAudience: '年终公司年会聚会人员、年轻跨年打卡人群、年度积分累积VIP',
    bossAdvice: '12月下旬是公司年会和元旦跨年的造型爆发期，提前3周排班调休，迎接年终业绩大丰收！',
    startWeekday: 2,
    days: generateMonthDays(12, 31, 2, [], [[10, 12], [23, 25]], { 7: '大雪', 21: '冬至' })
  }
])

const currentMonthDetail = computed(() => {
  return allMonthsData.value.find(m => m.month === selectedMonth.value) || allMonthsData.value[8]
})

// 4 大客群获客沟通时机指南
const customerTimingGuides = [
  {
    persona: '👑 高净值VIP / 老板企业高管',
    subTitle: '看重私密尊贵、高效品质',
    icon: '👑',
    theme: 'gold',
    bestTime: '周四 15:30~17:30 / 周五 10:00~11:30',
    psychology: '工作节奏快但时间自由度高。周末往往留给家庭或商务应酬，习惯在周四/周五下午提前规划周末个人放松时间。极度厌恶群发低质促销。',
    strategy: '由店长或总监一对一专属微信私聊，强调“尊贵私密、免等包厢、专属定制新品试用”，语言恭敬典雅。',
    recommendedOffer: '私享包厢极光抗衰SPA / 大额储值定制红酒礼遇'
  },
  {
    persona: '💼 都市白领 / 上班族',
    subTitle: '注重效率性价比、下班变美',
    icon: '💼',
    theme: 'blue',
    bestTime: '工作日午休 12:15~13:15 / 傍晚 18:00~19:30',
    psychology: '久坐伏案颈椎疲惫，下班后或周末渴望彻底放松。午休刷手机和下班通勤地铁上是浏览短信和微信的最高峰。',
    strategy: '突出“下班直达、高效解压、早鸟特惠、支持在线秒约”。文案简明扼要，直奔主题与利益点。',
    recommendedOffer: '午间快享洗吹造型 / 下班肩颈减压+周末烫染7.5折'
  },
  {
    persona: '🤱 全职宝妈 / 家庭客群',
    subTitle: '注重安全舒适、闺蜜拼团',
    icon: '🤱',
    theme: 'pink',
    bestTime: '周一至周五上午 09:30~11:30 / 下午 14:00~15:30',
    psychology: '孩子送去学校后的独处时光最放松。必须严格避开早晨 07:00~09:00 做早餐送娃和下午 16:00 后接娃买菜做饭的忙碌期。',
    strategy: '温情关怀风格，主打“犒劳辛苦的自己”、“有机天然孕婴可用耗材”、“闺蜜两人同行一人免单”。',
    recommendedOffer: '闺蜜同行二人拼团优惠 / 亲子温和洗护礼遇'
  },
  {
    persona: '🎓 年轻学生 / 潮流Z世代',
    subTitle: '追求潮流出片、价格敏感',
    icon: '🎓',
    theme: 'purple',
    bestTime: '晚间 20:30~22:30 / 周五下午',
    psychology: '夜猫子属性，晚间是刷抖音小红书活跃期。极度看重发型发色和美甲的出片率与社交货币，看重低门槛拼团与学生认证特惠。',
    strategy: '运用网感潮流语言，突出“小红书爆款同款、拍照超显白、出片率100%”，配图精美短视频链接。',
    recommendedOffer: '学生证立减60元 / 闺蜜双人拼团极光染发'
  }
]

// 短信 vs 电话触达黄金对比表
const channelRuleData = [
  {
    channel: '📱 短信精准触达',
    goldenTimes: '上午 10:30 / 下午 16:30 / 节假日前 3 天 11:00',
    advantage: '打扰度低、顾客可随时查看并长久留存、附带链接点击即可一键跳转预约或开卡。',
    contentTips: '前15字必须直接点名利益（如：【海马丝艺】60元国庆立减券已入账），附带尊称与到店有效截止期。',
    redLine: '严禁工作日中午 12:00~14:00 及夜间 21:00 后群发！严禁一周内向同一会员重复发送超过 2 条营销推销短信。'
  },
  {
    channel: '📞 电话预约回访',
    goldenTimes: '周二至周四 10:00~11:30 / 15:00~16:30',
    advantage: '沟通温度高、能精准探知顾客痛点与顾虑、即时确认到店时间和排班技师，成单确定性最强。',
    contentTips: '黄金3秒礼貌法则：“您好李女士，我是海马丝艺小张，耽误您1分钟，现在方便说话吗...为您留好上次最喜欢的工位”。',
    redLine: '严禁周一上午（客户忙于周例会）、周五下班前致电！绝不在周末早晨9点前或晚饭点致电！遇客户拒绝立即礼貌挂断，严禁纠缠。'
  }
]

// 工具 A: 智能文案生成器
const copyScene = ref('NATIONAL_DAY')
const copyTarget = ref('VIP')
const copyDiscount = ref('COUPON')

interface CopyItem {
  styleName: string
  content: string
  channel: string
  convertRate: string
}

const generatedCopyList = ref<CopyItem[]>([])

const generateCopyTexts = () => {
  const storeName = '海马智慧沙龙'
  const sceneName = copyScene.value === 'NATIONAL_DAY' ? '国庆黄金周'
    : copyScene.value === 'MID_AUTUMN' ? '中秋佳节'
    : copyScene.value === 'BIRTHDAY' ? '生日专宠'
    : copyScene.value === 'HIGH_FREQ' ? '忠诚老客回馈'
    : copyScene.value === 'RAINY' ? '降温雨雪暖心'
    : '会员专属日'

  const perkText = copyDiscount.value === 'COUPON' ? '专属满300减60盛惠券'
    : copyDiscount.value === 'DISCOUNT' ? '全场王牌项目7.5折特惠'
    : '进店即可免费领取定制精油礼盒'

  generatedCopyList.value = [
    {
      styleName: '🌟 温情关怀走心版 (适合VIP与忠诚老客)',
      content: `【${storeName}】见字如面！亲爱的{会员姓名}，${sceneName}将至，感恩您一直以来的信赖与相伴。我们已为您专属注入${perkText}，特备私密包厢与手工茶歇，盼与您共度惬意时光。预约电话：020-88996611，期待您的光临！`,
      channel: '微信一对一私信 / 高端短信',
      convertRate: '38.5%'
    },
    {
      styleName: '🔥 高让利利益直达版 (适合都市白领/上班族)',
      content: `【${storeName}】好消息！${sceneName}专享宠粉礼遇已送达您的卡包：${perkText}，本周提前预约再享双倍积分！仅限前50名预约顾客享特惠工位，点击回复“1”立即为您锁定总监档期，退订回T。`,
      channel: '短信网关秒级群发',
      convertRate: '46.2%'
    },
    {
      styleName: '⚡ 限量抢订紧迫感版 (适合假期前夕爆发期)',
      content: `【${storeName}】紧迫提醒！距离${sceneName}假期还有3天，店内金牌技师档期已预约满80%！特为VIP会员预留${perkText}及快速通道名额，今晚22:00前回复电话即可优先锁位，不排队速享高品质变美！`,
      channel: '短信 / 电话回访话术',
      convertRate: '52.8%'
    }
  ]
}

generateCopyTexts()

const handleCopyText = (txt: string) => {
  navigator.clipboard.writeText(txt).then(() => {
    ElMessage.success('文案已成功复制到剪贴板！可直接粘贴至微信私聊或短信群发通道')
  }).catch(() => {
    ElMessage.info('已选择文案，请手动 Ctrl+C 复制')
  })
}

// 工具 B: 充值活动赠送与毛利测算器
const calcRechargeAmount = ref(1000)
const calcGiftAmount = ref(300)
const calcGrossMargin = ref(70)

const calcDiscountRate = computed(() => {
  const total = calcRechargeAmount.value + calcGiftAmount.value
  if (total <= 0) return '10.0'
  return ((calcRechargeAmount.value / total) * 10).toFixed(1)
})

const calcActualCost = computed(() => {
  const marginRatio = calcGrossMargin.value / 100
  // 赠送金在服务核销时，真实物料成本为：赠金 * (1 - 毛利率)
  return calcGiftAmount.value * (1 - marginRatio)
})

const calcLockVisits = computed(() => {
  const total = calcRechargeAmount.value + calcGiftAmount.value
  // 按平均客单价 200 元估算核销频次
  return Math.max(3, Math.ceil(total / 200))
})

const calcIsHealthy = computed(() => {
  const discount = Number(calcDiscountRate.value)
  return discount >= 7.0 && calcActualCost.value <= calcRechargeAmount.value * 0.25
})

const calcVerdictText = computed(() => {
  if (calcIsHealthy.value) {
    return `极佳方案！综合等效折让仅 ${calcDiscountRate.value} 折，赠送耗材成本仅占本金 ${((calcActualCost.value / calcRechargeAmount.value) * 100).toFixed(1)}%，既对顾客吸引力巨大，又牢牢锁定 ${calcLockVisits.value} 次以上到店，利润健康安全！`
  } else {
    return `风险提示！综合等效折扣偏深（低于7折）或赠送真实成本偏高，建议适当调低赠送金，或改用“赠送实物礼盒 / 体验券”替代现金储值金。`
  }
})
</script>

<style scoped>
.marketing-center-page {
  padding: 4px 0;
}

.header-box {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.title {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}

.stat-card {
  padding: 16px;
  border-radius: 8px;
  color: #fff;
}

.stat-blue { background: linear-gradient(135deg, #0284c7, #0369a1); }
.stat-green { background: linear-gradient(135deg, #059669, #047857); }
.stat-amber { background: linear-gradient(135deg, #d97706, #b45309); }
.stat-purple { background: linear-gradient(135deg, #7c3aed, #6d28d9); }

.stat-card .lbl { font-size: 13px; opacity: 0.9; }
.stat-card .val { font-size: 24px; font-weight: 700; margin: 4px 0; }
.stat-card .sub { font-size: 11px; opacity: 0.8; }

.filter-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.pagination-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
}

.welcome-coupon-config-card {
  border-radius: 8px;
}

.welcome-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.wc-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.wc-badge {
  background: #0284c7;
  color: #fff;
  font-size: 12px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 4px;
}

.wc-title {
  font-size: 15px;
  font-weight: 700;
  color: #0369a1;
}

.wc-right {
  display: flex;
  gap: 8px;
}

/* =========================================
   💖 会员关怀与节日自动化事件样式
========================================= */
.care-events-container {
  padding-top: 4px;
}

.care-stat-card {
  padding: 16px;
  border-radius: 8px;
  color: #fff;
}
.bg-rose { background: linear-gradient(135deg, #e11d48, #be123c); }
.bg-indigo { background: linear-gradient(135deg, #4f46e5, #4338ca); }
.bg-amber { background: linear-gradient(135deg, #d97706, #b45309); }
.bg-emerald { background: linear-gradient(135deg, #059669, #047857); }

.care-stat-card .c-lbl { font-size: 13px; opacity: 0.9; }
.care-stat-card .c-val { font-size: 22px; font-weight: 700; margin: 4px 0; }
.care-stat-card .c-sub { font-size: 11px; opacity: 0.85; }

/* 🇨🇳 国庆节黄金周特别企划高光横幅 */
.national-day-banner {
  background: linear-gradient(135deg, #991b1b 0%, #b91c1c 40%, #dc2626 100%);
  border: 2px solid #fbbf24;
  border-radius: 12px;
  padding: 22px 26px;
  color: #fff;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 10px 25px -5px rgba(220, 38, 38, 0.35);
  margin-bottom: 24px;
  position: relative;
  overflow: hidden;
}

.national-day-banner::after {
  content: '🇨🇳';
  position: absolute;
  right: 180px;
  bottom: -20px;
  font-size: 120px;
  opacity: 0.12;
  pointer-events: none;
}

.nd-left {
  flex: 1;
  max-width: 75%;
}

.nd-badge {
  display: inline-block;
  background: #fbbf24;
  color: #7f1d1d;
  font-size: 12px;
  font-weight: 800;
  padding: 3px 10px;
  border-radius: 20px;
  margin-bottom: 8px;
  letter-spacing: 0.5px;
}

.nd-title {
  font-size: 20px;
  font-weight: 800;
  letter-spacing: 1px;
  color: #fff;
  text-shadow: 0 2px 4px rgba(0,0,0,0.25);
}

.nd-desc {
  font-size: 13px;
  color: #fecaca;
  margin-top: 6px;
  line-height: 1.5;
}

.nd-perks-row {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 12px;
}

.nd-perk {
  background: rgba(255, 255, 255, 0.16);
  border: 1px solid rgba(251, 191, 36, 0.6);
  color: #fef08a;
  font-size: 12px;
  font-weight: 600;
  padding: 4px 12px;
  border-radius: 6px;
  backdrop-filter: blur(4px);
}

.nd-sms-preview {
  margin-top: 12px;
  background: rgba(0, 0, 0, 0.25);
  border-radius: 6px;
  padding: 8px 12px;
  font-size: 12px;
  color: #fee2e2;
  line-height: 1.5;
}

.nd-sms-title {
  font-weight: 700;
  color: #fde047;
  margin-right: 4px;
}

.nd-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 14px;
  z-index: 1;
}

.nd-status-box {
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(0, 0, 0, 0.2);
  padding: 6px 12px;
  border-radius: 8px;
}

.st-label {
  font-size: 13px;
  font-weight: 600;
}

.nd-actions {
  display: flex;
  gap: 10px;
}

/* 关怀矩阵卡片 */
.care-section-title {
  display: flex;
  align-items: baseline;
  gap: 12px;
  margin-bottom: 14px;
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}

.care-section-title .sub-title {
  font-size: 12px;
  font-weight: 400;
  color: #64748b;
}

.care-event-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  transition: all 0.2s ease;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.care-event-card:hover {
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.08);
  transform: translateY(-2px);
}

.border-red { border-top: 4px solid #ef4444; }
.border-orange { border-top: 4px solid #f97316; }
.border-crimson { border-top: 4px solid #be123c; }
.border-gold { border-top: 4px solid #eab308; }
.border-pink { border-top: 4px solid #ec4899; }
.border-slate { border-top: 4px solid #64748b; }

.card-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 10px;
}

.event-meta {
  display: flex;
  gap: 10px;
  align-items: center;
}

.event-icon {
  font-size: 28px;
}

.event-name {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}

.event-period {
  font-size: 11px;
  color: #64748b;
  margin-top: 2px;
}

.event-trigger-rule {
  font-size: 12px;
  color: #334155;
  background: #f8fafc;
  padding: 6px 8px;
  border-radius: 6px;
  margin-bottom: 10px;
  line-height: 1.4;
}

.event-perks-box {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-bottom: 10px;
}

.perk-item {
  font-size: 12px;
  color: #1e293b;
  display: flex;
  align-items: center;
  gap: 6px;
}

.p-tag {
  font-size: 10px;
  font-weight: 700;
  padding: 1px 5px;
  border-radius: 4px;
  background: #e0f2fe;
  color: #0369a1;
}

.sms-quote-box {
  background: #f1f5f9;
  border-left: 3px solid #94a3b8;
  padding: 8px 10px;
  border-radius: 4px;
  margin-bottom: 12px;
  flex: 1;
}

.quote-lbl {
  font-size: 11px;
  font-weight: 700;
  color: #475569;
  margin-bottom: 3px;
}

.quote-text {
  font-size: 12px;
  color: #334155;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.card-foot {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-top: 1px dashed #e2e8f0;
  padding-top: 10px;
  margin-top: auto;
}

.touched-tip {
  font-size: 12px;
  color: #64748b;
}

.touched-tip b {
  color: #0284c7;
}

.btn-group {
  display: flex;
  gap: 6px;
}

.border-purple { border-top: 4px solid #9333ea; }
.border-blue { border-top: 4px solid #0284c7; }
.border-emerald { border-top: 4px solid #10b981; }

.care-section-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.care-section-title .cs-left {
  display: flex;
  align-items: baseline;
  gap: 12px;
}

/* =========================================
   📅 页签 3: 营销日历与获客时机助手样式
========================================= */
.tools-hero-banner {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0369a1 100%);
  border-radius: 12px;
  padding: 22px 26px;
  color: #fff;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  box-shadow: 0 10px 25px -5px rgba(2, 132, 199, 0.25);
}

.th-left {
  flex: 1;
  max-width: 75%;
}

.th-badge {
  display: inline-block;
  background: #38bdf8;
  color: #0f172a;
  font-size: 12px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 4px;
  margin-bottom: 6px;
}

.th-title {
  font-size: 18px;
  font-weight: 800;
  letter-spacing: 0.5px;
}

.th-desc {
  font-size: 13px;
  color: #cbd5e1;
  margin-top: 6px;
  line-height: 1.5;
}

.th-right {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.month-selector-bar {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 12px 16px;
  margin-bottom: 16px;
}

.m-label {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
  white-space: nowrap;
}

.m-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.current-month-badge {
  background: #ef4444;
  color: #fff;
  font-size: 10px;
  border-radius: 10px;
  padding: 0 4px;
  margin-left: 4px;
}

.month-playbook-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  margin-bottom: 24px;
}

.mp-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.mp-title {
  display: flex;
  align-items: center;
  gap: 8px;
}

.month-num {
  font-size: 20px;
  font-weight: 800;
  color: #0284c7;
}

.month-theme {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}

.mp-sub {
  font-size: 13px;
  color: #475569;
}

.mp-sub b {
  color: #d97706;
}

/* 日历网格 */
.calendar-grid-box {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px;
}

.cg-legend {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  font-size: 11px;
  color: #475569;
  margin-bottom: 12px;
  padding-bottom: 10px;
  border-bottom: 1px solid #f1f5f9;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 5px;
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 3px;
  display: inline-block;
}

.dot-holiday { background: #ef4444; }
.dot-window { background: #f59e0b; }
.dot-weekend { background: #10b981; }
.dot-work { background: #3b82f6; }
.dot-solar { background: #8b5cf6; }

.calendar-week-row {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  text-align: center;
  font-size: 12px;
  font-weight: 700;
  color: #64748b;
  margin-bottom: 8px;
}

.calendar-days-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 6px;
}

.day-cell {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 6px 4px;
  min-height: 48px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  transition: all 0.2s;
}

.day-blank {
  background: transparent;
  border: none;
}

.d-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.d-num {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
}

.d-solar {
  font-size: 10px;
  color: #8b5cf6;
  font-weight: 600;
}

.d-desc {
  font-size: 10px;
  font-weight: 700;
  text-align: center;
  border-radius: 3px;
  padding: 1px 2px;
  margin-top: 2px;
}

.type-holiday {
  background: #fef2f2;
  border-color: #fecaca;
}
.type-holiday .d-num { color: #dc2626; }
.type-holiday .d-desc { background: #ef4444; color: #fff; }

.type-window {
  background: #fffbeb;
  border-color: #fde68a;
}
.type-window .d-num { color: #b45309; }
.type-window .d-desc { background: #f59e0b; color: #fff; }

.type-weekend {
  background: #f0fdf4;
  border-color: #bbf7d0;
}
.type-weekend .d-num { color: #15803d; }
.type-weekend .d-desc { background: #10b981; color: #fff; }

.today-cell {
  box-shadow: 0 0 0 2px #0284c7;
  position: relative;
}

/* 右侧指南 */
.month-guide-box {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.g-section {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
}

.g-tit {
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 6px;
}

.g-val {
  font-size: 13px;
  color: #334155;
  line-height: 1.5;
}

.highlight-val {
  color: #0284c7;
  font-weight: 700;
}

.tips-section {
  background: #fffbeb;
  border-color: #fef3c7;
}

.tips-section .g-tit {
  color: #b45309;
}

.tip-text {
  color: #92400e;
  font-weight: 500;
}

/* 客群卡片 */
.section-divider-title {
  display: flex;
  align-items: baseline;
  gap: 12px;
  font-size: 16px;
  font-weight: 800;
  color: #0f172a;
  margin-bottom: 16px;
}

.section-divider-title .sub {
  font-size: 12px;
  font-weight: 400;
  color: #64748b;
}

.persona-timing-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  display: flex;
  flex-direction: column;
  gap: 10px;
  height: 100%;
}

.border-p-gold { border-top: 4px solid #eab308; }
.border-p-blue { border-top: 4px solid #0284c7; }
.border-p-pink { border-top: 4px solid #ec4899; }
.border-p-purple { border-top: 4px solid #8b5cf6; }

.pt-head {
  display: flex;
  align-items: center;
  gap: 10px;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 8px;
}

.pt-icon {
  font-size: 26px;
}

.pt-name {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}

.pt-sub {
  font-size: 11px;
  color: #64748b;
}

.pt-box {
  background: #f8fafc;
  border-radius: 6px;
  padding: 8px 10px;
}

.box-lbl {
  font-size: 11px;
  font-weight: 700;
  color: #475569;
  margin-bottom: 3px;
}

.box-val {
  font-size: 12px;
  color: #1e293b;
  line-height: 1.4;
}

.highlight-time {
  color: #0284c7;
  font-weight: 700;
}

.time-box {
  background: #f0f9ff;
  border: 1px solid #bae6fd;
}

.offer-box {
  background: #fdf2f8;
  border: 1px solid #fbcfe8;
}

/* 助手工具箱 */
.toolbox-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  height: 100%;
}

.tc-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: 700;
  color: #0f172a;
}

.generated-copy-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 10px;
}

.copy-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px;
}

.cp-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
}

.cp-style {
  font-size: 12px;
  font-weight: 700;
  color: #0284c7;
}

.cp-text {
  font-size: 13px;
  color: #334155;
  line-height: 1.5;
  background: #ffffff;
  border: 1px dashed #cbd5e1;
  padding: 8px 10px;
  border-radius: 6px;
}

.cp-foot {
  font-size: 11px;
  color: #64748b;
  margin-top: 6px;
}

.cp-foot b {
  color: #059669;
}

/* 测算器结论 */
.calc-result-box {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.cr-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
}

.cr-lbl {
  color: #475569;
}

.cr-val {
  font-weight: 700;
  color: #0f172a;
}

.cr-verdict {
  padding: 10px 12px;
  border-radius: 6px;
  font-size: 12px;
  line-height: 1.5;
  margin-top: 4px;
}

.verdict-pass {
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  color: #166534;
}

.verdict-warn {
  background: #fef2f2;
  border: 1px solid #fecaca;
  color: #991b1b;
}

/* ========================================================================= */
/* 空状态卡片 */
/* ========================================================================= */
.campaign-empty-card {
  text-align: center;
  padding: 48px 24px;
  background: #f8fafc;
  border: 2px dashed #cbd5e1;
  border-radius: 12px;
  margin-top: 16px;
}

.campaign-empty-card .empty-icon-wrap {
  width: 80px;
  height: 80px;
  margin: 0 auto 16px;
  border-radius: 50%;
  background: #e2e8f0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.campaign-empty-card .empty-title {
  font-size: 18px;
  font-weight: 700;
  color: #1e293b;
  margin: 0 0 8px;
}

.campaign-empty-card .empty-desc {
  font-size: 14px;
  color: #64748b;
  max-width: 580px;
  margin: 0 auto 24px;
  line-height: 1.6;
}

.campaign-empty-card .empty-actions {
  display: flex;
  justify-content: center;
  gap: 16px;
}

/* ========================================================================= */
/* 营销裂变海报工坊 Studio 样式 */
/* ========================================================================= */
.poster-studio-layout {
  display: flex;
  gap: 24px;
}

.poster-preview-panel {
  flex: 0 0 350px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.preview-card-header {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  font-size: 12px;
}

.preview-badge {
  color: #0284c7;
  font-weight: 700;
}

.preview-scale {
  color: #64748b;
  background: #e2e8f0;
  padding: 2px 8px;
  border-radius: 4px;
}

.poster-card {
  width: 320px;
  min-height: 520px;
  border-radius: 16px;
  padding: 16px 14px;
  box-sizing: border-box;
  position: relative;
  overflow: hidden;
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.18);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.poster-card-decor-circle-1 {
  position: absolute;
  top: -40px;
  right: -40px;
  width: 160px;
  height: 160px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.08);
  pointer-events: none;
}

.poster-card-decor-circle-2 {
  position: absolute;
  bottom: -40px;
  left: -40px;
  width: 140px;
  height: 140px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.06);
  pointer-events: none;
}

/* 主题色彩 */
.poster-card.theme-red_gold {
  background: linear-gradient(145deg, #991b1b 0%, #dc2626 50%, #7f1d1d 100%);
  color: #ffffff;
}

.poster-card.theme-black_gold {
  background: linear-gradient(145deg, #18181b 0%, #27272a 60%, #09090b 100%);
  color: #fbbf24;
  border: 1px solid rgba(251, 191, 36, 0.35);
}

.poster-card.theme-ocean_blue {
  background: linear-gradient(145deg, #0369a1 0%, #0284c7 50%, #075985 100%);
  color: #ffffff;
}

.poster-card.theme-emerald_green {
  background: linear-gradient(145deg, #065f46 0%, #059669 50%, #064e3b 100%);
  color: #ffffff;
}

.poster-card.theme-fashion_purple {
  background: linear-gradient(145deg, #6b21a8 0%, #7e22ce 50%, #581c87 100%);
  color: #ffffff;
}

.poster-inner {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  height: 100%;
  justify-content: space-between;
}

.poster-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: rgba(0, 0, 0, 0.2);
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 11px;
}

.poster-brand-tag {
  font-weight: 700;
  letter-spacing: 0.5px;
}

.poster-type-badge {
  background: rgba(255, 255, 255, 0.2);
  padding: 2px 6px;
  border-radius: 10px;
  font-size: 10px;
}

.poster-title-box {
  text-align: center;
  margin: 12px 0 10px;
}

.poster-main-title {
  font-size: 19px;
  font-weight: 800;
  margin: 0 0 6px;
  line-height: 1.3;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.poster-sub-title {
  font-size: 12px;
  opacity: 0.9;
  margin: 0;
  line-height: 1.4;
}

.poster-voucher-card {
  background: #ffffff;
  color: #1e293b;
  border-radius: 12px;
  padding: 12px;
  text-align: center;
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.15);
  margin: 4px 0 10px;
}

.poster-card.theme-black_gold .poster-voucher-card {
  background: #27272a;
  color: #f8fafc;
  border: 1px solid rgba(251, 191, 36, 0.4);
}

.voucher-highlight {
  display: inline-block;
  background: #dc2626;
  color: #ffffff;
  font-size: 15px;
  font-weight: 800;
  padding: 4px 14px;
  border-radius: 16px;
  margin-bottom: 6px;
}

.poster-card.theme-ocean_blue .voucher-highlight { background: #0284c7; }
.poster-card.theme-emerald_green .voucher-highlight { background: #059669; }
.poster-card.theme-fashion_purple .voucher-highlight { background: #7e22ce; }
.poster-card.theme-black_gold .voucher-highlight { background: #d97706; color: #fff; }

.voucher-rule {
  font-size: 13px;
  font-weight: 700;
  line-height: 1.4;
  margin-bottom: 6px;
}

.voucher-divider {
  height: 1px;
  border-top: 1px dashed #cbd5e1;
  margin: 6px 0;
}

.poster-card.theme-black_gold .voucher-divider {
  border-color: #52525b;
}

.voucher-validity {
  font-size: 11px;
  color: #64748b;
}

.poster-card.theme-black_gold .voucher-validity {
  color: #a1a1aa;
}

.poster-perks-tags {
  display: flex;
  justify-content: space-around;
  font-size: 10px;
  font-weight: 600;
  margin-bottom: 10px;
  opacity: 0.95;
}

.poster-foot {
  background: rgba(255, 255, 255, 0.96);
  color: #0f172a;
  border-radius: 10px;
  padding: 8px 10px;
  display: flex;
  align-items: center;
  gap: 10px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.qr-code-box {
  flex: 0 0 88px;
  text-align: center;
}

.qr-code-img {
  width: 80px;
  height: 80px;
  display: block;
  margin: 0 auto;
  border-radius: 4px;
}

.qr-placeholder {
  width: 80px;
  height: 80px;
  background: #f1f5f9;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  color: #0284c7;
}

.qr-tip {
  display: block;
  font-size: 9px;
  color: #64748b;
  margin-top: 2px;
  line-height: 1.2;
}

.store-info-box {
  flex: 1;
  font-size: 10px;
  line-height: 1.4;
  color: #334155;
}

.store-info-box .store-name {
  font-weight: 700;
  color: #0f172a;
  font-size: 12px;
  margin-bottom: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.store-info-box .store-phone,
.store-info-box .store-address {
  white-space: normal;
  word-break: break-all;
}

/* 编辑控制台 */
.poster-editor-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.editor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 12px;
  border-bottom: 1px solid #e2e8f0;
  margin-bottom: 12px;
}

.editor-header .e-tit {
  font-weight: 700;
  font-size: 15px;
  color: #0f172a;
}

.theme-picker-group {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.theme-chip {
  padding: 4px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  border: 2px solid transparent;
  transition: all 0.2s;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.theme-chip:hover {
  transform: translateY(-1px);
}

.theme-chip.active {
  border-color: #0284c7;
  box-shadow: 0 0 0 2px rgba(2, 132, 199, 0.4);
}

.editor-actions {
  display: flex;
  gap: 12px;
  margin-top: 14px;
  padding-top: 12px;
  border-top: 1px solid #e2e8f0;
}

</style>
