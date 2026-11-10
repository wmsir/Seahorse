<template>
  <div class="vendor-plans-container">
    <!-- 顶部标题 -->
    <div class="page-hero-header">
      <div class="hero-left">
        <div class="hero-icon-box">
          <el-icon :size="26"><Setting /></el-icon>
        </div>
        <div class="hero-text-box">
          <div class="hero-title-row">
            <h2 class="hero-title">SaaS 套餐定价与全局试用期配置</h2>
            <el-tag type="danger" effect="dark" size="small" class="hero-tag">全局商业定价规则</el-tag>
          </div>
          <p class="hero-subtitle">
            开发商集中设定各版本（体验版、专业版、旗舰版、企业定制版）的官方年度基准价格、连锁分店开设上限、员工账号上限及云存储容量，并随时调整全平台新租户注册时的默认免费试用期天数。
          </p>
        </div>
      </div>
      <div class="hero-right-actions">
        <el-button type="warning" plain @click="openPosterModal(planOptions[2] || planOptions[1] || planOptions[0])">
          <el-icon><Picture /></el-icon> 🎨 生成套餐营销海报
        </el-button>
        <el-button type="primary" plain @click="loadPlans">
          <el-icon><Refresh /></el-icon> 刷新套餐列表
        </el-button>
      </div>
    </div>

    <!-- 快捷试用期设置卡片 -->
    <el-card shadow="never" class="trial-config-card">
      <div class="trial-config-inner">
        <div class="trial-left">
          <div class="trial-title-row">
            <span class="trial-icon">🎁</span>
            <span class="trial-title">全平台新注册租户默认试用期天数</span>
            <el-tag type="warning" effect="dark" size="default">当前默认生效：{{ currentTrialDays }} 天免费试用</el-tag>
          </div>
          <div class="trial-desc">
            💡 开发商在此调整天数后，新注册的租户与体验客户开店即时获得该天数的免费全功能试用权限。支持快捷一键设为 3天、7天、14天、30天或自定义。
          </div>
        </div>
        <div class="trial-right">
          <el-button-group>
            <el-button :type="trialDaysInput === 3 ? 'primary' : 'default'" @click="setQuickTrialDays(3)">3 天体验</el-button>
            <el-button :type="trialDaysInput === 7 ? 'primary' : 'default'" @click="setQuickTrialDays(7)">7 天体验</el-button>
            <el-button :type="trialDaysInput === 14 ? 'primary' : 'default'" @click="setQuickTrialDays(14)">14 天体验</el-button>
            <el-button :type="trialDaysInput === 30 ? 'primary' : 'default'" @click="setQuickTrialDays(30)">30 天体验</el-button>
          </el-button-group>
          <div class="custom-days-box">
            <span class="lbl">自定义:</span>
            <el-input-number v-model="trialDaysInput" :min="1" :max="365" style="width: 110px;" />
            <span class="lbl">天</span>
          </div>
          <el-button type="success" :loading="savingTrialDays" @click="handleSaveTrialDays">
            <el-icon><Check /></el-icon> 保存默认试用天数
          </el-button>
        </div>
      </div>
    </el-card>

    <!-- 套餐定价列表卡片 -->
    <el-card shadow="never" class="table-main-card">
      <template #header>
        <div class="card-header-flex">
          <span style="font-weight: 700; color: #0f172a; font-size: 15px;">SaaS 各等级官方会员套餐定价与配额清单</span>
          <el-tag type="info" size="small">修改即时同步至新购与续费计算器</el-tag>
        </div>
      </template>

      <el-table :data="planOptions" v-loading="loading" stripe border style="width: 100%;">
        <el-table-column prop="planCode" label="套餐标识" width="130">
          <template #default="{ row }">
            <el-tag :type="getPlanTagType(row.planCode)" size="default" effect="dark">
              {{ row.planCode }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="planName" label="套餐商业全称" min-width="170">
          <template #default="{ row }">
            <div style="font-weight: 700; color: #0f172a; font-size: 14px;">{{ row.planName }}</div>
            <div style="font-size: 11px; color: #64748b;">{{ row.description || '官方基准版本' }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="annualPrice" label="官方年费标价 (元/年)" width="180" align="right">
          <template #default="{ row }">
            <div style="font-weight: 800; font-size: 16px; color: #0284c7;">
              ￥{{ (row.annualPrice || 0).toFixed(2) }}
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="storeLimit" label="实体开店上限" width="130" align="center">
          <template #default="{ row }">
            <span style="font-weight: 700; color: #059669;">{{ row.storeLimit }} 家</span>
          </template>
        </el-table-column>
        <el-table-column prop="staffLimit" label="店员账号上限" width="130" align="center">
          <template #default="{ row }">
            <span style="font-weight: 700; color: #475569;">{{ row.staffLimit }} 人</span>
          </template>
        </el-table-column>
        <el-table-column prop="storageQuotaGb" label="云端存储空间" width="140" align="center">
          <template #default="{ row }">
            <el-tag size="small" type="primary">{{ row.storageQuotaGb }} GB</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="对外官网公开售卖" width="150" align="center">
          <template #default="{ row }">
            <el-tag :type="row.isPublic ? 'success' : 'info'" size="small">
              {{ row.isPublic ? '官网公开自选' : '商务线下特约' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="190" align="center">
          <template #default="{ row }">
            <el-button type="warning" size="small" plain @click="openPosterModal(row)">
              🎨 海报
            </el-button>
            <el-button type="primary" size="small" @click="openEditPlanModal(row)">
              编辑配置
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 模式二：普通永久免费 + 流量包 / 云存储按量扩容包配置卡片 -->
    <el-card shadow="never" class="table-main-card" style="margin-top: 18px;">
      <template #header>
        <div class="card-header-flex">
          <div>
            <span style="font-weight: 700; color: #0f172a; font-size: 15px;">🌱 模式二：普通永久免费 + 流量包 / 云端存储按量扩容包配置清单</span>
            <span style="font-size: 12px; color: #64748b; margin-left: 8px;">(适合轻量单店与初创租户，0元基础门槛 + 阶梯加油包按需购买)</span>
          </div>
          <div style="display: flex; gap: 8px; align-items: center; flex-wrap: wrap;">
            <el-button type="success" size="small" @click="openPosterForFreeTier">
              <el-icon><Picture /></el-icon> 🎨 生成“永久免费+按量存储”全景海报
            </el-button>
            <el-button type="primary" size="small" @click="handleOpenAddPackModal">
              <el-icon><Plus /></el-icon> 新增加油扩容包
            </el-button>
            <el-button plain size="small" @click="handleResetDefaultPacks">
              <el-icon><Refresh /></el-icon> 恢复默认包
            </el-button>
          </div>
        </div>
      </template>

      <!-- 免费版赠送初始额度说明 -->
      <div class="freemium-intro-banner">
        <div class="fib-left">
          <span class="fib-icon">🎁</span>
          <div class="fib-text">
            <b>租户开通默认初始赠送：</b>永久免费 <strong>500 MB</strong> 云端存储容量 + 每月 <strong>20,000 次</strong> 基础接口操作额度。
            <br/>
            当租户客流上升、客照与业务数据累积致容量达 100% 上限时，系统自动进入只读保护状态，提醒租户自费选购如下扩容加油包，充值后秒级解除锁定。
          </div>
        </div>
      </div>

      <!-- 加油包表格展示 -->
      <el-table :data="allPacksDisplayList" stripe border size="default" style="width: 100%; margin-top: 12px;">
        <el-table-column prop="type" label="加油包类别" width="140">
          <template #default="{ row }">
            <el-tag :type="row.type === 'STORAGE' ? 'primary' : (row.type === 'SMS' ? 'warning' : 'success')" size="default">
              {{ row.type === 'STORAGE' ? '☁️ 云存储包' : (row.type === 'SMS' ? '📱 短信资源包' : '🚀 接口流量包') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="加油包商业名称" min-width="170">
          <template #default="{ row }">
            <div style="font-weight: 700; color: #0f172a;">{{ row.name }}</div>
            <div style="font-size: 11.5px; color: #64748b;">{{ row.desc }}</div>
          </template>
        </el-table-column>
        <el-table-column prop="price" label="官方销售标价" width="150" align="right">
          <template #default="{ row }">
            <span style="font-weight: 800; font-size: 16px; color: #0284c7;">￥{{ row.price }}</span>
            <span style="font-size: 11px; color: #64748b;"> / {{ row.period || '次' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="capacity" label="扩容配额" width="180" align="center">
          <template #default="{ row }">
            <el-tag :type="row.type === 'STORAGE' ? 'warning' : 'primary'" size="default" effect="plain">
              {{ row.capacity }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="badge" label="促销角标" width="110" align="center">
          <template #default="{ row }">
            <el-tag v-if="row.badge" type="danger" size="small" effect="dark">{{ row.badge }}</el-tag>
            <span v-else style="color: #94a3b8;">-</span>
          </template>
        </el-table-column>
        <el-table-column label="上架状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'ACTIVE' ? 'success' : 'info'" size="small">
              {{ row.status === 'ACTIVE' ? '在售生效' : '暂停下架' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="开发商管控操作" width="230" align="center" fixed="right">
          <template #default="{ row }">
            <div style="display: flex; justify-content: center; gap: 6px;">
              <el-button type="success" size="small" plain @click="openPosterForPack(row)">
                🎨 生成海报
              </el-button>
              <el-button type="primary" size="small" plain @click="handleOpenEditPack(row)">
                ✏️ 编辑
              </el-button>
              <el-button type="danger" size="small" link @click="handleDeletePack(row)">
                删除
              </el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 弹窗：编辑/新增加油扩容包 -->
    <el-dialog
      v-model="editPackModalVisible"
      :title="editPackForm.id.startsWith('pack_') ? '➕ 新增按量扩容加油包' : '⚙️ 编辑按量扩容加油包配置'"
      width="560px"
      destroy-on-close
    >
      <el-form :model="editPackForm" label-width="135px" style="margin-top: 10px;">
        <el-form-item label="加油包类别" required>
          <el-radio-group v-model="editPackForm.type">
            <el-radio value="STORAGE">☁️ 云存储扩容包</el-radio>
            <el-radio value="API">🚀 接口操作流量包</el-radio>
            <el-radio value="SMS">📱 短信充值加油包</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="商业名称" required>
          <el-input v-model="editPackForm.name" placeholder="如: 50GB 高速存储超值季包 / 1,000条短信充值包" />
        </el-form-item>

        <el-form-item label="促销角标">
          <el-input v-model="editPackForm.badge" placeholder="如: 热销推荐 / 连锁优选 / 即充即用" />
        </el-form-item>

        <el-form-item label="销售标价 (元)" required>
          <el-input-number v-model="editPackForm.price" :min="0" :step="10" style="width: 100%;" />
        </el-form-item>

        <el-form-item label="计费周期单位" required>
          <el-radio-group v-model="editPackForm.period">
            <el-radio-button label="月">按月</el-radio-button>
            <el-radio-button label="季">按季</el-radio-button>
            <el-radio-button label="年">按年</el-radio-button>
            <el-radio-button label="包">按包(一次性)</el-radio-button>
          </el-radio-group>
        </el-form-item>

        <el-form-item v-if="editPackForm.type === 'STORAGE'" label="扩容存储容量(MB)" required>
          <div style="display: flex; align-items: center; gap: 8px; width: 100%;">
            <el-input-number v-model="editPackForm.storageMb" :min="100" :step="1024" style="flex: 1;" />
            <span style="font-size: 12px; color: #64748b;">(约 {{ (editPackForm.storageMb / 1024).toFixed(1) }} GB)</span>
          </div>
        </el-form-item>

        <el-form-item v-else-if="editPackForm.type === 'SMS'" label="扩容短信条数" required>
          <div style="display: flex; align-items: center; gap: 8px; width: 100%;">
            <el-input-number v-model="editPackForm.count" :min="100" :step="500" style="flex: 1;" />
            <span style="font-size: 12px; color: #059669; font-weight: 600;">
              (折合 {{ (editPackForm.price / (editPackForm.count || 1)).toFixed(3) }} 元/条)
            </span>
          </div>
        </el-form-item>

        <el-form-item v-else label="扩容接口次数" required>
          <div style="display: flex; align-items: center; gap: 8px; width: 100%;">
            <el-input-number v-model="editPackForm.calls" :min="1000" :step="10000" style="flex: 1;" />
            <span style="font-size: 12px; color: #64748b;">次接口操作</span>
          </div>
        </el-form-item>

        <el-form-item label="商业卖点描述">
          <el-input v-model="editPackForm.desc" type="textarea" :rows="2" placeholder="如: 约可额外存储 2,500 张高清服务客照" />
        </el-form-item>

        <el-form-item label="上架状态">
          <el-switch v-model="editPackForm.status" active-value="ACTIVE" inactive-value="PAUSED" active-text="在售生效" inactive-text="暂停下架" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editPackModalVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSavePack">确认保存配置</el-button>
      </template>
    </el-dialog>

    <!-- 编辑套餐价格与配额对话框 -->
    <el-dialog v-model="editPlanModalVisible" title="⚙️ 调整 SaaS 套餐定价与配额限制" width="540px" destroy-on-close>
      <el-form :model="editPlanForm" label-width="135px" style="margin-top: 10px;">
        <el-form-item label="套餐代号">
          <el-input :model-value="editPlanForm.planCode" disabled />
        </el-form-item>
        <el-form-item label="套餐商业名称" required>
          <el-input v-model="editPlanForm.planName" />
        </el-form-item>
        <el-form-item label="年度官方标价 (元)" required>
          <el-input-number v-model="editPlanForm.annualPrice" :min="0" :step="100" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="允许开设分店上限" required>
          <el-input-number v-model="editPlanForm.storeLimit" :min="1" :max="100" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="员工登录账号上限" required>
          <el-input-number v-model="editPlanForm.staffLimit" :min="1" :max="500" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="云端客照存储容量" required>
          <div style="display: flex; align-items: center; gap: 8px; width: 100%;">
            <el-input-number v-model="editPlanForm.storageQuotaGb" :min="1" :max="5000" style="flex: 1;" />
            <span>GB</span>
          </div>
        </el-form-item>
        <el-form-item label="官网公开自选">
          <el-switch v-model="editPlanForm.isPublic" active-text="公开展示在注册选型页" inactive-text="仅限销售线下签单" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editPlanModalVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingPlan" @click="handleSavePlan">
          确认保存定价
        </el-button>
      </template>
    </el-dialog>

    <!-- 营销海报生成与一键转发对话框 -->
    <el-dialog
      v-model="posterModalVisible"
      title="🎨 SaaS 套餐专属营销海报定制与推广分发中枢"
      width="1120px"
      destroy-on-close
      append-to-body
      class="poster-dialog"
    >
      <div class="poster-dialog-layout">
        <!-- 左侧：高清海报实时交互预览 -->
        <div class="poster-preview-col">
          <div
            class="poster-card-canvas-box"
            :class="`theme-${currentTheme.toLowerCase().replace('_', '-')}`"
            id="poster-display-card"
          >
            <!-- 品牌顶部标 -->
            <div class="poster-brand-row">
              <span class="poster-brand-badge">{{ posterContent.brandBadgeText }}</span>
              <span class="poster-brand-sub">{{ posterContent.brandSubText }}</span>
            </div>

            <!-- 主标题与标语 -->
            <div class="poster-main-title">
              {{ posterContent.mainTitle }}
            </div>
            <div class="poster-slogan">{{ posterContent.slogan }}</div>

            <!-- 套餐商业卡片 -->
            <div class="poster-plan-badge-card">
              <div class="plan-card-tag">{{ posterContent.planTag }}</div>
              <div class="plan-card-name">{{ selectedPosterPlan?.planName }}</div>
              
              <div class="plan-card-price-row">
                <span class="curr">￥</span>
                <span class="price-val">{{ displayAnnualPrice.toFixed(0) }}</span>
                <span class="price-unit">
                  <template v-if="posterTargetType === 'FREE_TIER'">/ 永久免费</template>
                  <template v-else-if="selectedPosterPack">/ {{ selectedPosterPack.period || '次' }}</template>
                  <template v-else>/ 年</template>
                </span>
                <span
                  v-if="posterContent.customOriginalPrice && posterContent.customOriginalPrice > displayAnnualPrice"
                  class="original-price-strike"
                >
                  ￥{{ posterContent.customOriginalPrice.toFixed(0) }}
                </span>
              </div>
              <div class="plan-card-daily">
                <template v-if="posterTargetType === 'FREE_TIER'">
                  🎁 <b>0元永久免费开通</b> · 默认赠送 500MB 存储与 2万次调用
                </template>
                <template v-else-if="selectedPosterPack">
                  ⚡ <b>{{ selectedPosterPack.capacity }}</b> · 充沛算力与存储空间随充即用
                </template>
                <template v-else>
                  低至仅 <b>￥{{ displayDailyPrice }}</b> 元/天 · 支持按月开票抵税
                </template>
              </div>

              <div class="plan-card-quotas">
                <template v-if="posterTargetType === 'FREE_TIER'">
                  <div class="quota-col">
                    <span class="q-val">1 家</span>
                    <span class="q-lbl">实体门面</span>
                  </div>
                  <div class="q-div"></div>
                  <div class="quota-col">
                    <span class="q-val">3 人</span>
                    <span class="q-lbl">店务账号</span>
                  </div>
                  <div class="q-div"></div>
                  <div class="quota-col">
                    <span class="q-val">500 MB</span>
                    <span class="q-lbl">初始存储</span>
                  </div>
                </template>
                <template v-else-if="selectedPosterPack">
                  <div class="quota-col">
                    <span class="q-val">{{ selectedPosterPack.type === 'STORAGE' ? '云端对象存储' : '高频操作算力' }}</span>
                    <span class="q-lbl">业务类别</span>
                  </div>
                  <div class="q-div"></div>
                  <div class="quota-col">
                    <span class="q-val">{{ selectedPosterPack.capacity }}</span>
                    <span class="q-lbl">扩充额度</span>
                  </div>
                  <div class="q-div"></div>
                  <div class="quota-col">
                    <span class="q-val">即充即解封</span>
                    <span class="q-lbl">解除锁定</span>
                  </div>
                </template>
                <template v-else>
                  <div class="quota-col">
                    <span class="q-val">{{ selectedPosterPlan?.storeLimit }} 家</span>
                    <span class="q-lbl">实体分店</span>
                  </div>
                  <div class="q-div"></div>
                  <div class="quota-col">
                    <span class="q-val">{{ selectedPosterPlan?.staffLimit }} 人</span>
                    <span class="q-lbl">店员账号</span>
                  </div>
                  <div class="q-div"></div>
                  <div class="quota-col">
                    <span class="q-val">{{ selectedPosterPlan?.storageQuotaGb }} GB</span>
                    <span class="q-lbl">云端存储</span>
                  </div>
                </template>
              </div>
            </div>

            <!-- 核心功能特权列表 -->
            <div class="poster-perks-box">
              <div class="perk-item" v-if="posterContent.perk1">
                <span class="p-dot">✨</span>
                <span>{{ posterContent.perk1 }}</span>
              </div>
              <div class="perk-item" v-if="posterContent.perk2">
                <span class="p-dot">✨</span>
                <span>{{ posterContent.perk2 }}</span>
              </div>
              <div class="perk-item" v-if="posterContent.perk3">
                <span class="p-dot">✨</span>
                <span>{{ posterContent.perk3 }}</span>
              </div>
              <div class="perk-item" v-if="posterContent.perk4">
                <span class="p-dot">✨</span>
                <span>{{ posterContent.perk4 }}</span>
              </div>
            </div>

            <!-- 试用期保证 -->
            <div class="poster-trial-guarantee">
              <span class="tg-icon">🎁</span>
              <span>{{ posterContent.trialGuaranteeText }}</span>
            </div>

            <!-- 底部真实可扫码二维码与邀请码 -->
            <div class="poster-qr-footer">
              <div class="real-qr-box">
                <img
                  v-if="realPosterQrCodeUrl"
                  :src="realPosterQrCodeUrl"
                  class="real-poster-qr-img"
                  alt="微信或手机相机扫码直达"
                  title="可直接用手机扫码测试跳转"
                />
                <div v-else class="qr-loading-box">
                  <el-icon class="is-loading"><Loading /></el-icon>
                </div>
              </div>
              <div class="qr-hint-box">
                <div class="qh-scan">{{ posterContent.qrHintTitle }}</div>
                <div class="qh-sub">{{ posterContent.qrHintSubtitle }}</div>
                <div class="qh-code">官方专属推荐码: <b>{{ posterContent.recommendCode }}</b></div>
                <div class="qh-url">{{ actualQrTargetUrl }}</div>
              </div>
            </div>
          </div>

          <div class="preview-scan-tip">
            💡 <b>真实二维码可扫测试：</b>手机微信或原生相机直接对准上方二维码扫码，可真实跳转直达租户注册落地页！
          </div>
        </div>

        <!-- 右侧：海报编辑、分发与域名选项 -->
        <div class="poster-actions-col">
          <el-tabs v-model="posterActiveTab" type="border-card" class="poster-tabs-wrap">
            <!-- TAB 1: 海报文案与视觉定制 -->
            <el-tab-pane name="EDIT">
              <template #label>
                <span><el-icon><Edit /></el-icon> ✏️ 海报文案与视觉定制</span>
              </template>

              <div class="edit-tab-scroll">
                <!-- 0. 宣传目标方案切换 -->
                <div class="custom-form-section">
                  <div class="cfs-title">🎯 宣传推广目标方案 / 产品</div>
                  <el-select
                    v-model="posterTargetSelection"
                    @change="handlePosterTargetSelectionChange"
                    style="width: 100%;"
                  >
                    <el-option-group label="👑 模式一：年度包年套餐">
                      <el-option
                        v-for="p in planOptions"
                        :key="p.planCode"
                        :label="`${p.planName} (￥${p.annualPrice}/年)`"
                        :value="`PLAN_${p.planCode}`"
                      />
                    </el-option-group>
                    <el-option-group label="🌱 模式二：普通永久免费方案">
                      <el-option label="🌱 模式二 · 普通永久免费版 (0元永久免年费)" value="FREE_TIER" />
                    </el-option-group>
                    <el-option-group label="⚡ 模式二：按量加油扩容包">
                      <el-option
                        v-for="pack in allPacksDisplayList"
                        :key="pack.id"
                        :label="`${pack.type === 'STORAGE' ? '☁️' : '🚀'} ${pack.name} (￥${pack.price} · ${pack.capacity})`"
                        :value="`PACK_${pack.id}`"
                      />
                    </el-option-group>
                  </el-select>
                </div>

                <!-- 1. 主题视觉风格 -->
                <div class="custom-form-section">
                  <div class="cfs-title">🎨 海报主题色彩风格</div>
                  <div class="theme-options-grid">
                    <div
                      class="theme-btn"
                      :class="{ active: currentTheme === 'TECH_BLUE' }"
                      @click="currentTheme = 'TECH_BLUE'"
                    >
                      <span class="theme-dot" style="background: linear-gradient(135deg, #0284c7, #6366f1);"></span>
                      <span>深邃科技蓝紫</span>
                    </div>
                    <div
                      class="theme-btn"
                      :class="{ active: currentTheme === 'BLACK_GOLD' }"
                      @click="currentTheme = 'BLACK_GOLD'"
                    >
                      <span class="theme-dot" style="background: linear-gradient(135deg, #f59e0b, #d97706);"></span>
                      <span>曜石黑金轻奢</span>
                    </div>
                    <div
                      class="theme-btn"
                      :class="{ active: currentTheme === 'CORAL_ORANGE' }"
                      @click="currentTheme = 'CORAL_ORANGE'"
                    >
                      <span class="theme-dot" style="background: linear-gradient(135deg, #ea580c, #db2777);"></span>
                      <span>活力珊瑚日落</span>
                    </div>
                    <div
                      class="theme-btn"
                      :class="{ active: currentTheme === 'FOREST_GREEN' }"
                      @click="currentTheme = 'FOREST_GREEN'"
                    >
                      <span class="theme-dot" style="background: linear-gradient(135deg, #059669, #0284c7);"></span>
                      <span>翡翠科技森林</span>
                    </div>
                  </div>
                </div>

                <!-- 2. 套餐与展示价格定制 -->
                <div class="custom-form-section" style="margin-top: 14px;">
                  <div class="cfs-title">📦 套餐版本与海报价格微调</div>
                  <el-row :gutter="12">
                    <el-col :span="12">
                      <el-form-item label="切换套餐版本" style="margin-bottom: 8px;">
                        <el-select
                          v-model="selectedPosterPlanCode"
                          @change="onPosterPlanChange"
                          style="width: 100%;"
                        >
                          <el-option
                            v-for="p in planOptions"
                            :key="p.planCode"
                            :label="`${p.planName} (￥${(p.annualPrice || 0).toFixed(0)}/年)`"
                            :value="p.planCode"
                          />
                        </el-select>
                      </el-form-item>
                    </el-col>
                    <el-col :span="12">
                      <el-form-item label="促销标牌/角标" style="margin-bottom: 8px;">
                        <el-input v-model="posterContent.planTag" placeholder="如：限时立减800 / 官方标杆" />
                      </el-form-item>
                    </el-col>
                  </el-row>
                  <el-row :gutter="12">
                    <el-col :span="12">
                      <el-form-item label="海报展示特惠价 (元/年)" style="margin-bottom: 8px;">
                        <el-input-number
                          v-model="posterContent.customPrice"
                          :min="0"
                          :step="100"
                          :placeholder="`${selectedPosterPlan?.annualPrice || 0}`"
                          style="width: 100%;"
                        />
                      </el-form-item>
                    </el-col>
                    <el-col :span="12">
                      <el-form-item label="划线原价对比 (元/年，选填)" style="margin-bottom: 8px;">
                        <el-input-number
                          v-model="posterContent.customOriginalPrice"
                          :min="0"
                          :step="100"
                          placeholder="留空则不显示划线价"
                          style="width: 100%;"
                        />
                      </el-form-item>
                    </el-col>
                  </el-row>
                </div>

                <!-- 3. 品牌与标题标语定制 -->
                <div class="custom-form-section" style="margin-top: 14px;">
                  <div class="cfs-title">🏷️ 品牌大标与宣传语</div>
                  <el-row :gutter="12">
                    <el-col :span="12">
                      <el-form-item label="品牌主标题" style="margin-bottom: 8px;">
                        <el-input v-model="posterContent.mainTitle" placeholder="海马智慧门店 SaaS" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="12">
                      <el-form-item label="顶部徽标说明" style="margin-bottom: 8px;">
                        <el-input v-model="posterContent.brandBadgeText" placeholder="⚡ 数字化开店首选" />
                      </el-form-item>
                    </el-col>
                  </el-row>
                  <el-form-item label="宣传标语 (Slogan)" style="margin-bottom: 8px;">
                    <el-input v-model="posterContent.slogan" placeholder="宣传口号" />
                  </el-form-item>
                </div>

                <!-- 4. 4条核心特权卖点 -->
                <div class="custom-form-section" style="margin-top: 14px;">
                  <div class="cfs-title">✨ 4条核心特权卖点 (支持逐行个性化微调)</div>
                  <el-input v-model="posterContent.perk1" placeholder="特权1" style="margin-bottom: 6px;" />
                  <el-input v-model="posterContent.perk2" placeholder="特权2" style="margin-bottom: 6px;" />
                  <el-input v-model="posterContent.perk3" placeholder="特权3" style="margin-bottom: 6px;" />
                  <el-input v-model="posterContent.perk4" placeholder="特权4" style="margin-bottom: 6px;" />
                </div>

                <!-- 5. 试用保障与推荐码 -->
                <div class="custom-form-section" style="margin-top: 14px;">
                  <div class="cfs-title">🎁 试用保障与二维码导流</div>
                  <el-form-item label="试用期保障文案" style="margin-bottom: 8px;">
                    <el-input v-model="posterContent.trialGuaranteeText" />
                  </el-form-item>
                  <el-row :gutter="12">
                    <el-col :span="12">
                      <el-form-item label="官方推荐码" style="margin-bottom: 8px;">
                        <el-input v-model="posterContent.recommendCode" @input="refreshRealPosterQrCode" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="12">
                      <el-form-item label="扫码引导主标题" style="margin-bottom: 8px;">
                        <el-input v-model="posterContent.qrHintTitle" />
                      </el-form-item>
                    </el-col>
                  </el-row>
                </div>

                <!-- 底部辅助按钮 -->
                <div style="margin-top: 14px; display: flex; justify-content: space-between;">
                  <el-button size="small" @click="resetPosterContentToDefaults">
                    <el-icon><RefreshRight /></el-icon> 恢复当前套餐预设文案
                  </el-button>
                  <el-button size="small" type="primary" plain @click="testOpenQrTargetUrl">
                    <el-icon><TopRight /></el-icon> 测试扫码直达落地页
                  </el-button>
                </div>
              </div>
            </el-tab-pane>

            <!-- TAB 2: 快捷一键分发与转发 -->
            <el-tab-pane name="DISTRIBUTE">
              <template #label>
                <span><el-icon><Share /></el-icon> 🚀 一键分发与渠道推广</span>
              </template>

              <div class="action-buttons-stack" style="margin-top: 8px;">
                <el-button
                  type="primary"
                  size="large"
                  class="distribute-btn"
                  @click="openWechatShareModal"
                >
                  <el-icon><ChatRound /></el-icon> 一键转发到微信 (好友/群聊)
                </el-button>

                <el-button
                  type="success"
                  size="large"
                  class="distribute-btn"
                  @click="copyPromoLink"
                >
                  <el-icon><Link /></el-icon> 复制专属租户推广注册链接
                </el-button>

                <el-button
                  type="warning"
                  size="large"
                  class="distribute-btn"
                  @click="copyMomentsCopywriting"
                >
                  <el-icon><DocumentCopy /></el-icon> 复制朋友圈/社群促单文案
                </el-button>

                <el-button
                  type="info"
                  size="large"
                  class="distribute-btn download-highlight-btn"
                  :loading="generatingPoster"
                  @click="downloadPosterCanvas"
                >
                  <el-icon><Download /></el-icon> 📥 下载高清宣传海报 (PNG - 720×1080)
                </el-button>
              </div>

              <!-- 推广文案实时预览框 -->
              <div class="action-section-card" style="margin-top: 16px;">
                <div class="as-title">📱 微信朋友圈/微信群促单宣传话术</div>
                <el-input
                  type="textarea"
                  :rows="6"
                  :model-value="getMomentsCopyText()"
                  readonly
                  style="margin-top: 8px; font-size: 12px;"
                />
              </div>
            </el-tab-pane>

            <!-- TAB 3: 域名与环境切换 -->
            <el-tab-pane name="DOMAIN">
              <template #label>
                <span><el-icon><Setting /></el-icon> 🌐 推广域名与环境</span>
              </template>

              <div class="action-section-card" style="margin-top: 8px;">
                <div class="as-title" style="display: flex; justify-content: space-between; align-items: center;">
                  <span>🌐 推广落地页网络域名环境</span>
                  <el-tag size="small" :type="currentDomainConfig.activeEnv === 'PROD' ? 'success' : 'warning'">
                    {{ currentDomainConfig.activeEnv === 'PROD' ? '官方域名 fwpt.cn' : '本地开发 localhost:3000' }}
                  </el-tag>
                </div>
                <div style="margin-top: 10px;">
                  <el-radio-group v-model="currentDomainConfig.activeEnv" size="default" @change="handleDomainEnvChange">
                    <el-radio-button label="PROD">官方生产 (fwpt.cn)</el-radio-button>
                    <el-radio-button label="DEV">本地开发 (localhost:3000)</el-radio-button>
                  </el-radio-group>
                </div>
                <div style="font-size: 12px; color: #475569; margin-top: 12px; line-height: 1.6;">
                  当前生效链接前缀：<code style="color: #0284c7; background: #f1f5f9; padding: 2px 8px; border-radius: 4px; font-weight: 700;">{{ activeBaseUrl }}</code>
                </div>
                <div style="font-size: 12px; color: #475569; margin-top: 8px; line-height: 1.6;">
                  二维码扫码实际跳转完整 URL：<br/>
                  <code style="color: #059669; background: #ecfdf5; padding: 4px 8px; border-radius: 4px; word-break: break-all; font-size: 11px;">{{ actualQrTargetUrl }}</code>
                </div>

                <div style="margin-top: 16px;">
                  <el-button type="primary" plain size="default" @click="testOpenQrTargetUrl">
                    <el-icon><TopRight /></el-icon> 立即在浏览器新标签页测试打开此落地页
                  </el-button>
                </div>

                <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; font-size: 12px; color: #64748b; margin-top: 16px; line-height: 1.5;">
                  💡 <b>真实二维码说明：</b>系统使用标准矢量高容错矩阵算法将上述注册 URL 实时编码为真实二维码图片，无论是电脑屏幕预览还是导出保存的宣传海报 PNG，手机微信、浏览器或相机直接扫描均可秒级识别并直达注册落地页。
                </div>
              </div>
            </el-tab-pane>
          </el-tabs>
        </div>
      </div>
    </el-dialog>

    <!-- 微信转发预览与转发辅助弹窗 -->
    <el-dialog
      v-model="wechatShareModalVisible"
      title="💬 微信一键转发与分享指引"
      width="520px"
      destroy-on-close
      append-to-body
    >
      <div class="wechat-share-dialog-content">
        <div class="wechat-preview-box">
          <div class="wechat-bubble-sender">海马智慧门店 SaaS 官方推广</div>
          <div class="wechat-card-preview">
            <div class="wc-top-badge">小程序 / 网页卡片</div>
            <div class="wc-title">【限时直降】海马智慧门店系统 · {{ selectedPosterPlan?.planName }}</div>
            <div class="wc-body">
              <div class="wc-thumb">🌊</div>
              <div class="wc-desc">
                开店选海马！含 {{ selectedPosterPlan?.storeLimit }} 家门店 + {{ selectedPosterPlan?.staffLimit }} 个店员账号。新注册享 {{ currentTrialDays }} 天免费体验！
              </div>
            </div>
            <div class="wc-footer">
              <span>海马智慧门店 SaaS</span>
              <span class="wc-tag">限时特惠</span>
            </div>
          </div>
        </div>

        <div class="wechat-guide-tips">
          <div class="tip-row">
            <el-icon color="#10b981"><Check /></el-icon>
            <span>方式一：点击下方按钮复制文案与链接，直接粘贴发送到微信好友或微信群。</span>
          </div>
          <div class="tip-row">
            <el-icon color="#10b981"><Check /></el-icon>
            <span>方式二：点击“下载海报图片”，将生成的高清 PNG 图片发送到朋友圈。</span>
          </div>
        </div>
      </div>
      <template #footer>
        <el-button @click="wechatShareModalVisible = false">关闭</el-button>
        <el-button type="primary" @click="copyPromoLink">
          <el-icon><Link /></el-icon> 复制微信推广链接
        </el-button>
        <el-button type="success" @click="copyMomentsCopywriting">
          <el-icon><DocumentCopy /></el-icon> 复制整套促单话术
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import QRCode from 'qrcode'
import {
  getSubscriptionPlansApi,
  updatePlanConfigApi,
  updateTrialDaysApi
} from '@/api'
import {
getActiveBaseUrl,
  getSystemDomainConfig,
  saveSystemDomainConfig,
  type SystemDomainConfig
} from '@/utils/systemConfig'
import {
  RECHARGE_PACKAGES,
  getRechargePackagesList,
  resetRechargePackagesList,
  upsertStoragePack,
  deleteStoragePack,
  upsertApiPack,
  deleteApiPack,
  upsertSmsPack,
  deleteSmsPack
} from '@/utils/tenantQuotaService'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Setting,
  Refresh,
  Check,
  Picture,
  Share,
  DocumentCopy,
  Download,
  ChatRound,
  Link,
  Edit,
  RefreshRight,
  Loading,
  TopRight,
  Plus,
  Delete
} from '@element-plus/icons-vue'

const loading = ref(false)
const planOptions = ref<any[]>([])
const currentTrialDays = ref(3)
const trialDaysInput = ref(3)
const savingTrialDays = ref(false)

const editPlanModalVisible = ref(false)
const savingPlan = ref(false)
const editPlanForm = ref<any>({})

// 模式二：可编辑的加油包本地响应式状态
const rechargePacksLocalVersion = ref(0)
const rechargeConfig = ref(getRechargePackagesList())

const refreshRechargeConfig = () => {
  rechargeConfig.value = getRechargePackagesList()
  rechargePacksLocalVersion.value++
}

// 模式二：普通永久免费与流量包/存储按量加油包列表展示
const allPacksDisplayList = computed(() => {
  // 依赖版本触发更新
  void rechargePacksLocalVersion.value
  const list: any[] = []
  rechargeConfig.value.storagePacks.forEach(p => {
    list.push({
      id: p.id,
      type: 'STORAGE',
      name: p.name,
      price: p.price,
      period: p.period,
      storageMb: p.storageMb,
      capacity: `+${p.storageMb >= 1024 ? (p.storageMb / 1024).toFixed(0) + ' GB' : p.storageMb + ' MB'} 容量`,
      badge: p.badge,
      desc: p.desc,
      status: p.status || 'ACTIVE'
    })
  })
  rechargeConfig.value.apiPacks.forEach(p => {
    list.push({
      id: p.id,
      type: 'API',
      name: p.name,
      price: p.price,
      period: p.period || '包',
      calls: p.calls,
      capacity: `+${p.calls.toLocaleString()} 次接口调用`,
      badge: p.badge,
      desc: p.desc,
      status: p.status || 'ACTIVE'
    })
  })
  if (rechargeConfig.value.smsPacks && Array.isArray(rechargeConfig.value.smsPacks)) {
    rechargeConfig.value.smsPacks.forEach(p => {
      list.push({
        id: p.id,
        type: 'SMS',
        name: p.name,
        price: p.price,
        period: '包',
        count: p.count,
        unitPrice: p.unitPrice || (p.price / (p.count || 1)).toFixed(3),
        capacity: `+${p.count.toLocaleString()} 条短信`,
        badge: p.badge,
        desc: p.desc,
        status: p.status || 'ACTIVE'
      })
    })
  }
  return list
})

// 模式二加油包管理对话框与操作逻辑
const editPackModalVisible = ref(false)
const editPackForm = ref<any>({
  id: '',
  type: 'STORAGE',
  name: '',
  badge: '',
  price: 29,
  period: '月',
  storageMb: 10240,
  calls: 50000,
  count: 1000,
  desc: '',
  status: 'ACTIVE'
})

const handleOpenAddPackModal = () => {
  editPackForm.value = {
    id: `pack_${Date.now()}`,
    type: 'STORAGE',
    name: '',
    badge: '热销推荐',
    price: 49,
    period: '月',
    storageMb: 20480,
    calls: 100000,
    count: 1000,
    desc: '约可额外存储 5,000 张高清服务客照及业务凭证',
    status: 'ACTIVE'
  }
  editPackModalVisible.value = true
}

const handleOpenEditPack = (row: any) => {
  editPackForm.value = {
    id: row.id,
    type: row.type,
    name: row.name,
    badge: row.badge,
    price: row.price,
    period: row.period || (row.type === 'STORAGE' ? '月' : '包'),
    storageMb: row.storageMb || 10240,
    calls: row.calls || 50000,
    count: row.count || 1000,
    desc: row.desc,
    status: row.status || 'ACTIVE'
  }
  editPackModalVisible.value = true
}

const handleSavePack = () => {
  if (!editPackForm.value.name || editPackForm.value.price === undefined) {
    ElMessage.warning('请填写完整的加油包商业名称与价格')
    return
  }
  if (editPackForm.value.type === 'STORAGE') {
    upsertStoragePack({
      id: editPackForm.value.id,
      name: editPackForm.value.name,
      badge: editPackForm.value.badge,
      price: editPackForm.value.price,
      period: editPackForm.value.period,
      storageMb: editPackForm.value.storageMb,
      desc: editPackForm.value.desc,
      status: editPackForm.value.status
    })
  } else if (editPackForm.value.type === 'SMS') {
    upsertSmsPack({
      id: editPackForm.value.id,
      name: editPackForm.value.name,
      badge: editPackForm.value.badge,
      price: editPackForm.value.price,
      count: editPackForm.value.count || 1000,
      unitPrice: (editPackForm.value.price / (editPackForm.value.count || 1)).toFixed(3),
      desc: editPackForm.value.desc,
      status: editPackForm.value.status
    })
  } else {
    upsertApiPack({
      id: editPackForm.value.id,
      name: editPackForm.value.name,
      badge: editPackForm.value.badge,
      price: editPackForm.value.price,
      period: editPackForm.value.period,
      calls: editPackForm.value.calls,
      desc: editPackForm.value.desc,
      status: editPackForm.value.status
    })
  }
  refreshRechargeConfig()
  ElMessage.success(`扩容加油包【${editPackForm.value.name}】已成功保存生效！`)
  editPackModalVisible.value = false
}

const handleDeletePack = (row: any) => {
  ElMessageBox.confirm(
    `确定要删除/下架加油包【${row.name}】吗？`,
    '删除确认',
    { confirmButtonText: '确定删除', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    if (row.type === 'STORAGE') {
      deleteStoragePack(row.id)
    } else if (row.type === 'SMS') {
      deleteSmsPack(row.id)
    } else {
      deleteApiPack(row.id)
    }
    refreshRechargeConfig()
    ElMessage.success(`已成功删除加油包【${row.name}】`)
  }).catch(() => {})
}

const handleResetDefaultPacks = () => {
  ElMessageBox.confirm(
    '确认将模式二按量加油包恢复为系统官方预置标准配置吗？自定义扩容包将被重置。',
    '恢复默认加油包',
    { confirmButtonText: '确定重置', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    resetRechargePackagesList()
    refreshRechargeConfig()
    ElMessage.success('已恢复系统默认加油包配置')
  }).catch(() => {})
}

// 域名环境与营销海报相关状态
const currentDomainConfig = ref<SystemDomainConfig>(getSystemDomainConfig())
// 响应式生效前缀：随单选按钮即时联动
const activeBaseUrl = computed(() => getActiveBaseUrl(currentDomainConfig.value))

const posterTargetType = ref<'ANNUAL_PLAN' | 'FREE_TIER' | 'STORAGE_PACK' | 'API_PACK'>('ANNUAL_PLAN')
const selectedPosterPack = ref<any>(null)
const posterTargetSelection = ref<string>('PLAN_FLAGSHIP')

const posterModalVisible = ref(false)
const selectedPosterPlan = ref<any>(null)
const selectedPosterPlanCode = ref('')
const wechatShareModalVisible = ref(false)
const generatingPoster = ref(false)

// 海报编辑控制与主题风格
const posterActiveTab = ref<'EDIT' | 'DISTRIBUTE' | 'DOMAIN'>('EDIT')
const currentTheme = ref<'TECH_BLUE' | 'BLACK_GOLD' | 'CORAL_ORANGE' | 'FOREST_GREEN'>('TECH_BLUE')

interface PosterEditableContent {
  brandBadgeText: string
  brandSubText: string
  mainTitle: string
  slogan: string
  planTag: string
  customPrice: number | null
  customOriginalPrice: number | null
  perk1: string
  perk2: string
  perk3: string
  perk4: string
  trialGuaranteeText: string
  recommendCode: string
  qrHintTitle: string
  qrHintSubtitle: string
}

const posterContent = ref<PosterEditableContent>({
  brandBadgeText: '⚡ 数字化开店首选',
  brandSubText: '智慧中枢 · 连锁协同',
  mainTitle: '🌊 海马智慧门店 SaaS',
  slogan: '全行业全场景多店连锁智慧经营管理云系统',
  planTag: '官方年度标杆',
  customPrice: null,
  customOriginalPrice: null,
  perk1: '组合收银结算台：多轨混合支付、双余额扣款与欠账台账',
  perk2: '微信微商城与裂变：次卡/拼团/秒杀爆款，线上线下互通',
  perk3: '工位调度与提成算薪：工位桌台看板排班，技师阶梯算薪',
  perk4: '财务核算全穿透：全口径利润表、BOM耗材损耗与跨店漫游',
  trialGuaranteeText: '',
  recommendCode: '',
  qrHintTitle: '微信扫一扫 · 开启数字开店',
  qrHintSubtitle: '手机微信扫描左侧二维码，立即领取免费体验配额'
})

// 海报四大主题色彩字典
const posterThemes: Record<string, any> = {
  TECH_BLUE: {
    name: '深邃科技蓝紫',
    bg1: '#090d16',
    bg2: '#0f172a',
    bg3: '#1e1b4b',
    glow1: 'rgba(56, 189, 248, 0.22)',
    glow2: 'rgba(168, 85, 247, 0.22)',
    accent: '#38bdf8',
    cardBg: 'rgba(30, 41, 59, 0.88)',
    tagBg: '#f59e0b',
    tagText: '#0f172a',
    badgeBorder: '#38bdf8'
  },
  BLACK_GOLD: {
    name: '曜石黑金轻奢',
    bg1: '#0a0a0a',
    bg2: '#18181b',
    bg3: '#27272a',
    glow1: 'rgba(245, 158, 11, 0.25)',
    glow2: 'rgba(251, 191, 36, 0.18)',
    accent: '#fbbf24',
    cardBg: 'rgba(39, 39, 42, 0.88)',
    tagBg: '#fbbf24',
    tagText: '#0a0a0a',
    badgeBorder: '#fbbf24'
  },
  CORAL_ORANGE: {
    name: '活力珊瑚日落',
    bg1: '#1c0d1b',
    bg2: '#2a0826',
    bg3: '#451a03',
    glow1: 'rgba(249, 115, 22, 0.26)',
    glow2: 'rgba(236, 72, 153, 0.22)',
    accent: '#fb923c',
    cardBg: 'rgba(67, 20, 7, 0.85)',
    tagBg: '#ef4444',
    tagText: '#ffffff',
    badgeBorder: '#fb923c'
  },
  FOREST_GREEN: {
    name: '翡翠科技森林',
    bg1: '#022c22',
    bg2: '#064e3b',
    bg3: '#0f172a',
    glow1: 'rgba(16, 185, 129, 0.25)',
    glow2: 'rgba(56, 189, 248, 0.2)',
    accent: '#34d399',
    cardBg: 'rgba(6, 78, 59, 0.85)',
    tagBg: '#10b981',
    tagText: '#ffffff',
    badgeBorder: '#34d399'
  }
}

// 实际二维码扫码跳转 URL（真实编码：租户专属注册开通落地页）
const actualQrTargetUrl = computed(() => {
  if (posterTargetType.value === 'FREE_TIER') {
    const refCode = posterContent.value.recommendCode || 'SEAHORSE-FREE'
    return `${activeBaseUrl.value}/tenant-register?plan=FREE&mode=freemium&ref=${encodeURIComponent(refCode)}`
  }
  if (posterTargetType.value === 'STORAGE_PACK' || posterTargetType.value === 'API_PACK') {
    const packId = selectedPosterPack.value?.id || 'store_50g'
    const refCode = posterContent.value.recommendCode || `PACK-${packId}`
    return `${activeBaseUrl.value}/tenant-register?mode=pack&packId=${packId}&ref=${encodeURIComponent(refCode)}`
  }
  const code = selectedPosterPlan.value?.planCode || 'FLAGSHIP'
  const refCode = posterContent.value.recommendCode || `SEAHORSE-${code}`
  return `${activeBaseUrl.value}/tenant-register?plan=${code}&ref=${encodeURIComponent(refCode)}&trial=${currentTrialDays.value}`
})

// 真实可扫码的 DataURL 图片
const realPosterQrCodeUrl = ref('')

const refreshRealPosterQrCode = async () => {
  try {
    const url = actualQrTargetUrl.value
    realPosterQrCodeUrl.value = await QRCode.toDataURL(url, {
      margin: 1,
      width: 240,
      errorCorrectionLevel: 'M',
      color: {
        dark: '#0f172a',
        light: '#ffffff'
      }
    })
  } catch (e) {
    console.warn('Generate real QR code failed:', e)
  }
}

watch([actualQrTargetUrl, posterModalVisible], () => {
  if (posterModalVisible.value) {
    refreshRealPosterQrCode()
  }
})

// 售价与每日计算
const displayAnnualPrice = computed(() => {
  if (posterContent.value.customPrice !== null && posterContent.value.customPrice !== undefined && posterContent.value.customPrice >= 0) {
    return posterContent.value.customPrice
  }
  return selectedPosterPlan.value?.annualPrice || 0
})

const displayDailyPrice = computed(() => {
  return (displayAnnualPrice.value / 365).toFixed(1)
})

const handleDomainEnvChange = (val: any) => {
  currentDomainConfig.value.activeEnv = val
  if (val === 'PROD') {
    currentDomainConfig.value.officialDomain = 'https://fwpt.cn'
  }
  saveSystemDomainConfig(currentDomainConfig.value)
  refreshRealPosterQrCode()
  ElMessage.success(`🎉 推广落地页网络域名已切换为：${activeBaseUrl.value}`)
}

const resetPosterContentToDefaults = () => {
  const p = selectedPosterPlan.value || {}
  posterContent.value = {
    brandBadgeText: '⚡ 数字化开店首选',
    brandSubText: '智慧中枢 · 连锁协同',
    mainTitle: '🌊 海马智慧门店 SaaS',
    slogan: '全行业全场景多店连锁智慧经营管理云系统',
    planTag: `${p.planCode || 'OFFICIAL'} 官方年度标杆`,
    customPrice: null,
    customOriginalPrice: null,
    perk1: '组合收银结算台：多轨混合支付、双余额扣款与欠账台账',
    perk2: '微信微商城与裂变：次卡/拼团/秒杀爆款，线上线下互通',
    perk3: '工位调度与提成算薪：工位桌台看板排班，技师阶梯算薪',
    perk4: '财务核算全穿透：全口径利润表、BOM耗材损耗与跨店漫游',
    trialGuaranteeText: `🎁 官方承诺：新店注册即享 ${currentTrialDays.value} 天全功能无忧免费深度体验！`,
    recommendCode: `SEAHORSE-${p.planCode || 'PROMO'}`,
    qrHintTitle: '微信扫一扫 · 开启数字开店',
    qrHintSubtitle: '手机微信扫描左侧二维码，立即领取免费体验配额'
  }
  refreshRealPosterQrCode()
}

const openPosterModal = (plan: any) => {
  posterTargetType.value = 'ANNUAL_PLAN'
  selectedPosterPack.value = null
  if (!plan && planOptions.value.length > 0) {
    plan = planOptions.value[0]
  }
  selectedPosterPlan.value = { ...plan }
  selectedPosterPlanCode.value = plan?.planCode || 'FLAGSHIP'
  posterTargetSelection.value = `PLAN_${selectedPosterPlanCode.value}`
  resetPosterContentToDefaults()
  posterModalVisible.value = true
  refreshRealPosterQrCode()
}

const openPosterForFreeTier = () => {
  posterTargetType.value = 'FREE_TIER'
  selectedPosterPack.value = null
  selectedPosterPlan.value = {
    planCode: 'FREE',
    planName: '模式二 · 普通永久免费版',
    annualPrice: 0,
    storeLimit: 1,
    staffLimit: 3,
    storageQuotaGb: 0.5
  }
  selectedPosterPlanCode.value = 'FREE'
  posterTargetSelection.value = 'FREE_TIER'
  currentTheme.value = 'CORAL_ORANGE'
  posterContent.value = {
    brandBadgeText: '🎁 零门槛数字化开店',
    brandSubText: '永久免费 · 按需加购',
    mainTitle: '🌊 海马智慧商业 SaaS',
    slogan: '普通永久免费 + 流量包/云存储按量扩容双轨新业态',
    planTag: '0元永久免年费',
    customPrice: 0,
    customOriginalPrice: 980,
    perk1: '开单收银与会员管理永久免费，零软件年费开店',
    perk2: '默认赠送 500MB 高速客照存储 + 20,000次/月操作额度',
    perk3: '客照存储/接口流量随用随充，阶梯按量加购无负担',
    perk4: '超额自动锁屏保护，数据永久安全留存绝不丢失',
    trialGuaranteeText: '永久免费开通 · 支持随时升级企业连锁包年版',
    recommendCode: 'FREE-START',
    qrHintTitle: '微信扫一扫 · 0元开通系统',
    qrHintSubtitle: '手机微信直接扫码，立即创建实体门店与会员系统'
  }
  posterModalVisible.value = true
  refreshRealPosterQrCode()
}

const openPosterForPack = (row: any) => {
  posterTargetType.value = row.type === 'STORAGE' ? 'STORAGE_PACK' : 'API_PACK'
  selectedPosterPack.value = row
  selectedPosterPlan.value = {
    planCode: row.id,
    planName: row.name,
    annualPrice: row.price,
    storeLimit: 1,
    staffLimit: 3,
    storageQuotaGb: row.storageMb ? Number((row.storageMb / 1024).toFixed(0)) : 1
  }
  selectedPosterPlanCode.value = row.id
  posterTargetSelection.value = `PACK_${row.id}`
  currentTheme.value = row.type === 'STORAGE' ? 'TECH_BLUE' : 'FOREST_GREEN'
  const isStorage = row.type === 'STORAGE'
  posterContent.value = {
    brandBadgeText: isStorage ? '☁️ 云端存储特惠扩容' : '🚀 接口高频流量保障',
    brandSubText: '即充即用 · 秒级解封',
    mainTitle: '🌊 海马智慧商业 SaaS',
    slogan: '全行业实体连锁数据存储中心与算力流量包',
    planTag: row.badge || '热销加油包',
    customPrice: row.price,
    customOriginalPrice: Math.round(row.price * 1.35),
    perk1: isStorage ? `额外扩充 ${row.capacity} 高速云端对象存储空间` : `扩充 ${row.capacity}，充沛算力保障高并发`,
    perk2: isStorage ? '约可额外存储 15,000+ 张高清客照、多媒体记忆与电子账单' : '稳定应对节假日大促、全员营销与裂变拓客高频请求',
    perk3: '租户存储/流量超额锁定后，充值任意包即刻自动解除锁定恢复操作',
    perk4: '专线高可用对象存储与数据容灾，多重冷热备份永不丢失',
    trialGuaranteeText: `仅需 ￥${row.price} · 立即充值扩容`,
    recommendCode: `PACK-${row.id.toUpperCase().slice(-6)}`,
    qrHintTitle: '微信扫一扫 · 立即选购扩容',
    qrHintSubtitle: '手机扫码直达租户充值中心，秒级生效恢复操作'
  }
  posterModalVisible.value = true
  refreshRealPosterQrCode()
}

const handlePosterTargetSelectionChange = (val: string) => {
  if (val === 'FREE_TIER') {
    openPosterForFreeTier()
  } else if (val.startsWith('PACK_')) {
    const packId = val.replace('PACK_', '')
    const found = allPacksDisplayList.value.find(p => p.id === packId)
    if (found) {
      openPosterForPack(found)
    }
  } else if (val.startsWith('PLAN_')) {
    const planCode = val.replace('PLAN_', '')
    const found = planOptions.value.find(p => p.planCode === planCode)
    if (found) {
      openPosterModal(found)
    }
  }
}

const onPosterPlanChange = (code: string) => {
  const target = planOptions.value.find(p => p.planCode === code)
  if (target) {
    selectedPosterPlan.value = { ...target }
    posterContent.value.planTag = `${target.planCode} 官方年度标杆`
    posterContent.value.recommendCode = `SEAHORSE-${target.planCode}`
    refreshRealPosterQrCode()
  }
}

const testOpenQrTargetUrl = () => {
  window.open(actualQrTargetUrl.value, '_blank')
  ElMessage.info(`🌐 已在新标签页打开扫码目标落地页：${actualQrTargetUrl.value}`)
}

const copyToClipboard = (text: string, successMsg: string) => {
  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(text).then(() => {
      ElMessage.success(successMsg)
    }).catch(() => {
      fallbackCopy(text, successMsg)
    })
  } else {
    fallbackCopy(text, successMsg)
  }
}

const fallbackCopy = (text: string, successMsg: string) => {
  const textArea = document.createElement('textarea')
  textArea.value = text
  textArea.style.position = 'fixed'
  textArea.style.left = '-999999px'
  document.body.appendChild(textArea)
  textArea.focus()
  textArea.select()
  try {
    document.execCommand('copy')
    ElMessage.success(successMsg)
  } catch (err) {
    ElMessage.error('复制失败，请手动选择复制')
  }
  document.body.removeChild(textArea)
}

const copyPromoLink = () => {
  copyToClipboard(actualQrTargetUrl.value, '🎉 套餐专属推广注册链接已复制！可直接发送给租户或渠道伙伴')
}

const getMomentsCopyText = () => {
  const p = selectedPosterPlan.value || {}
  const price = displayAnnualPrice.value
  const daily = displayDailyPrice.value
  return `📢【海马智慧门店 SaaS 官方限时特惠通道】
🏆 数字化开店首选标杆系统火热开放中！
🔥【${p.planName || '旗舰版套餐'}】限时特惠仅 ￥${price.toFixed(0)}/年（低至 ￥${daily} 元/天）
🏬 享 ${p.storeLimit || 1} 家连锁门店配额 + ${p.staffLimit || 10} 名店员开单协同 + ${p.storageQuotaGb || 20}GB 云端存储
✨ 组合收银/双余额扣款/智能工位排班/拼团秒杀裂变/跨店算薪一站全包
🎁 新租户注册即享 ${currentTrialDays.value} 天全功能无忧免费试用！
👉 官方极速体验直通车：${actualQrTargetUrl.value}`
}

const copyMomentsCopywriting = () => {
  const text = getMomentsCopyText()
  copyToClipboard(text, '📋 朋友圈/社群营销促单话术已成功复制到剪贴板！')
}

const openWechatShareModal = () => {
  wechatShareModalVisible.value = true
}

// 纯原生 HTML5 Canvas 绘制高清营销海报并下载（支持真实二维码与主题动态渲染）
const downloadPosterCanvas = async () => {
  generatingPoster.value = true
  try {
    const canvas = document.createElement('canvas')
    canvas.width = 720
    canvas.height = 1080
    const ctx = canvas.getContext('2d')
    if (!ctx) {
      throw new Error('Canvas context not available')
    }

    const p = selectedPosterPlan.value || {}
    const theme = posterThemes[currentTheme.value] || posterThemes.TECH_BLUE

    // 1. 背景渐变绘制
    const bgGrad = ctx.createLinearGradient(0, 0, 720, 1080)
    bgGrad.addColorStop(0, theme.bg1)
    bgGrad.addColorStop(0.4, theme.bg2)
    bgGrad.addColorStop(1, theme.bg3)
    ctx.fillStyle = bgGrad
    ctx.fillRect(0, 0, 720, 1080)

    // 装饰光晕
    const glow1 = ctx.createRadialGradient(120, 160, 20, 120, 160, 260)
    glow1.addColorStop(0, theme.glow1)
    glow1.addColorStop(1, 'transparent')
    ctx.fillStyle = glow1
    ctx.beginPath()
    ctx.arc(120, 160, 260, 0, Math.PI * 2)
    ctx.fill()

    const glow2 = ctx.createRadialGradient(620, 780, 20, 620, 780, 300)
    glow2.addColorStop(0, theme.glow2)
    glow2.addColorStop(1, 'transparent')
    ctx.fillStyle = glow2
    ctx.beginPath()
    ctx.arc(620, 780, 300, 0, Math.PI * 2)
    ctx.fill()

    // 2. 顶部微标
    ctx.fillStyle = 'rgba(255, 255, 255, 0.08)'
    ctx.beginPath()
    ctx.roundRect(40, 42, 230, 34, 17)
    ctx.fill()
    ctx.strokeStyle = theme.badgeBorder
    ctx.lineWidth = 1.2
    ctx.stroke()

    ctx.font = 'bold 13px system-ui, sans-serif'
    ctx.fillStyle = theme.accent
    ctx.textAlign = 'center'
    ctx.fillText(posterContent.value.brandBadgeText || '⚡ 数字化开店首选', 155, 64)

    // 3. 品牌主标题与宣传语
    ctx.textAlign = 'left'
    ctx.font = '900 36px system-ui, sans-serif'
    ctx.fillStyle = '#ffffff'
    ctx.fillText(posterContent.value.mainTitle || '🌊 海马智慧门店 SaaS', 40, 125)

    ctx.font = '15px system-ui, sans-serif'
    ctx.fillStyle = '#94a3b8'
    ctx.fillText(posterContent.value.slogan || '全行业全场景多店连锁智慧经营管理云系统', 40, 158)

    // 4. 套餐核心卡片容器
    ctx.fillStyle = theme.cardBg
    ctx.beginPath()
    ctx.roundRect(40, 185, 640, 320, 18)
    ctx.fill()
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.12)'
    ctx.lineWidth = 1.5
    ctx.stroke()

    // 套餐标识标签
    ctx.fillStyle = theme.tagBg
    ctx.beginPath()
    ctx.roundRect(64, 210, 160, 28, 6)
    ctx.fill()
    ctx.font = 'bold 12px system-ui, sans-serif'
    ctx.fillStyle = theme.tagText
    ctx.textAlign = 'center'
    ctx.fillText(posterContent.value.planTag || '官方标杆', 144, 228)

    // 套餐名称
    ctx.textAlign = 'left'
    ctx.font = 'bold 28px system-ui, sans-serif'
    ctx.fillStyle = '#ffffff'
    ctx.fillText(p.planName || '官方套餐', 64, 275)

    // 价格与每天单价
    ctx.font = 'bold 22px system-ui, sans-serif'
    ctx.fillStyle = theme.accent
    ctx.fillText('￥', 64, 335)

    const finalPrice = displayAnnualPrice.value
    ctx.font = '900 48px system-ui, sans-serif'
    ctx.fillText(`${finalPrice.toFixed(0)}`, 90, 335)

    const priceWidth = ctx.measureText(`${finalPrice.toFixed(0)}`).width
    ctx.font = '16px system-ui, sans-serif'
    ctx.fillStyle = '#94a3b8'
    ctx.fillText('/ 年', 90 + priceWidth + 8, 335)

    // 若有原价对比划线
    if (posterContent.value.customOriginalPrice && posterContent.value.customOriginalPrice > finalPrice) {
      const origText = `原价 ￥${posterContent.value.customOriginalPrice.toFixed(0)}`
      ctx.font = '14px system-ui, sans-serif'
      ctx.fillStyle = '#64748b'
      const origX = 90 + priceWidth + 55
      ctx.fillText(origText, origX, 335)
      const origW = ctx.measureText(origText).width
      ctx.strokeStyle = '#64748b'
      ctx.lineWidth = 1.5
      ctx.beginPath()
      ctx.moveTo(origX, 330)
      ctx.lineTo(origX + origW, 330)
      ctx.stroke()
    }

    const daily = displayDailyPrice.value
    ctx.font = '14px system-ui, sans-serif'
    ctx.fillStyle = '#cbd5e1'
    ctx.fillText(`每天低至 ￥${daily} 元 · 支持按月开票抵税`, 64, 370)

    // 3格配额条
    ctx.fillStyle = 'rgba(15, 23, 42, 0.6)'
    ctx.beginPath()
    ctx.roundRect(64, 400, 592, 85, 12)
    ctx.fill()

    const qItems = [
      { val: `${p.storeLimit || 1} 家`, lbl: '实体分店上限' },
      { val: `${p.staffLimit || 10} 人`, lbl: '员工登录账号' },
      { val: `${p.storageQuotaGb || 20} GB`, lbl: '高速云端存储' }
    ]

    qItems.forEach((q, i) => {
      const cx = 64 + 98 + i * 197
      ctx.textAlign = 'center'
      ctx.font = 'bold 22px system-ui, sans-serif'
      ctx.fillStyle = theme.accent
      ctx.fillText(q.val, cx, 436)

      ctx.font = '12px system-ui, sans-serif'
      ctx.fillStyle = '#94a3b8'
      ctx.fillText(q.lbl, cx, 465)

      if (i < 2) {
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)'
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(64 + (i + 1) * 197, 415)
        ctx.lineTo(64 + (i + 1) * 197, 470)
        ctx.stroke()
      }
    })

    // 5. 核心特权 Bullet Points
    const perks = [
      `✨  ${posterContent.value.perk1 || '组合收银结算台：多轨混合支付、双余额扣款与欠账台账'}`,
      `✨  ${posterContent.value.perk2 || '微信微商城与裂变：次卡/拼团/秒杀爆款，线上线下互通'}`,
      `✨  ${posterContent.value.perk3 || '工位调度与提成算薪：工位桌台看板排班，技师阶梯算薪'}`,
      `✨  ${posterContent.value.perk4 || '财务核算全穿透：全口径利润表、BOM耗材损耗与跨店漫游'}`
    ]

    ctx.textAlign = 'left'
    ctx.font = '15px system-ui, sans-serif'
    ctx.fillStyle = '#e2e8f0'
    perks.forEach((text, i) => {
      ctx.fillText(text, 50, 550 + i * 40)
    })

    // 6. 试用期保障条
    ctx.fillStyle = 'rgba(16, 185, 129, 0.16)'
    ctx.beginPath()
    ctx.roundRect(40, 725, 640, 60, 12)
    ctx.fill()
    ctx.strokeStyle = '#10b981'
    ctx.lineWidth = 1.2
    ctx.stroke()

    ctx.font = 'bold 16px system-ui, sans-serif'
    ctx.fillStyle = '#34d399'
    ctx.textAlign = 'center'
    ctx.fillText(posterContent.value.trialGuaranteeText || `🎁 官方承诺：新店注册即享 ${currentTrialDays.value} 天免费试用！`, 360, 762)

    // 7. 底部二维码与官方推荐码卡片
    ctx.fillStyle = 'rgba(15, 23, 42, 0.88)'
    ctx.beginPath()
    ctx.roundRect(40, 810, 640, 220, 16)
    ctx.fill()
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.12)'
    ctx.lineWidth = 1
    ctx.stroke()

    // 绘制真实可扫码跳转的二维码图片
    const qx = 75
    const qy = 835
    const qw = 170
    ctx.fillStyle = '#ffffff'
    ctx.beginPath()
    ctx.roundRect(qx, qy, qw, qw, 10)
    ctx.fill()

    if (realPosterQrCodeUrl.value) {
      const qrImg = new Image()
      qrImg.crossOrigin = 'anonymous'
      await new Promise((resolve) => {
        qrImg.onload = resolve
        qrImg.onerror = resolve
        qrImg.src = realPosterQrCodeUrl.value
      })
      ctx.drawImage(qrImg, qx + 8, qy + 8, qw - 16, qw - 16)
    }

    // 二维码右侧说明文字
    ctx.textAlign = 'left'
    ctx.font = 'bold 18px system-ui, sans-serif'
    ctx.fillStyle = '#ffffff'
    ctx.fillText(posterContent.value.qrHintTitle || '微信扫一扫 · 开启数字开店', 275, 875)

    ctx.font = '14px system-ui, sans-serif'
    ctx.fillStyle = '#94a3b8'
    ctx.fillText(posterContent.value.qrHintSubtitle || '手机微信扫描左侧二维码，立即领取免费体验配额', 275, 910)

    ctx.fillStyle = 'rgba(56, 189, 248, 0.15)'
    ctx.beginPath()
    ctx.roundRect(275, 935, 360, 38, 8)
    ctx.fill()

    ctx.font = 'bold 14px system-ui, sans-serif'
    ctx.fillStyle = theme.accent
    ctx.fillText(`官方推荐码：${posterContent.value.recommendCode || ('SEAHORSE-' + (p.planCode || 'PROMO'))}`, 290, 960)

    ctx.font = '12px system-ui, sans-serif'
    ctx.fillStyle = '#64748b'
    ctx.fillText(actualQrTargetUrl.value, 275, 1005)

    // 8. 转换为图片并下载
    const dataUrl = canvas.toDataURL('image/png')
    const link = document.createElement('a')
    link.download = `海马SaaS营销海报-${p.planName || '官方套餐'}.png`
    link.href = dataUrl
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)

    ElMessage.success('🎉 高清真实二维码营销海报已成功生成并下载到本地！手机直接扫码即可跳转！')
  } catch (err: any) {
    ElMessage.error(err.message || '海报生成失败')
  } finally {
    generatingPoster.value = false
  }
}

const setQuickTrialDays = (days: number) => {
  trialDaysInput.value = days
}

const handleSaveTrialDays = async () => {
  savingTrialDays.value = true
  try {
    await updateTrialDaysApi(trialDaysInput.value)
    currentTrialDays.value = trialDaysInput.value
    ElMessage.success(`🎉 全平台新租户默认免费试用期已成功设置为 ${trialDaysInput.value} 天！`)
  } catch (e: any) {
    ElMessage.error(e.message || '更新试用天数失败')
  } finally {
    savingTrialDays.value = false
  }
}

const loadPlans = async () => {
  loading.value = true
  try {
    const res: any = await getSubscriptionPlansApi()
    if (Array.isArray(res) && res.length > 0) {
      planOptions.value = res
    } else {
      planOptions.value = [
        { id: 1, planCode: 'TRIAL', planName: '体验版套餐', annualPrice: 0.00, storeLimit: 1, staffLimit: 3, storageQuotaGb: 5, isPublic: true, description: '免费体验全业务微内核' },
        { id: 2, planCode: 'PROFESSIONAL', planName: '专业版套餐', annualPrice: 1980.00, storeLimit: 1, staffLimit: 8, storageQuotaGb: 20, isPublic: true, description: '单店全套智慧数字化' },
        { id: 3, planCode: 'FLAGSHIP', planName: '旗舰版套餐', annualPrice: 2980.00, storeLimit: 5, staffLimit: 30, storageQuotaGb: 50, isPublic: true, description: '多店连锁协同标杆首选' },
        { id: 4, planCode: 'ENTERPRISE', planName: '企业定制版', annualPrice: 6800.00, storeLimit: 30, staffLimit: 200, storageQuotaGb: 500, isPublic: false, description: '集团化跨城深度定制' }
      ]
    }
  } catch (e) {
    console.warn('Load plans fallback:', e)
  } finally {
    loading.value = false
  }
}

const openEditPlanModal = (plan: any) => {
  editPlanForm.value = { ...plan }
  editPlanModalVisible.value = true
}

const handleSavePlan = async () => {
  savingPlan.value = true
  try {
    if (editPlanForm.value.id) {
      await updatePlanConfigApi(editPlanForm.value.id, editPlanForm.value)
    }
    const idx = planOptions.value.findIndex(p => p.planCode === editPlanForm.value.planCode)
    if (idx !== -1) {
      planOptions.value[idx] = { ...editPlanForm.value }
    }
    ElMessage.success(`套餐【${editPlanForm.value.planName}】定价与配额修改成功！`)
    editPlanModalVisible.value = false
  } catch (e: any) {
    ElMessage.error(e.message || '保存失败')
  } finally {
    savingPlan.value = false
  }
}

const getPlanTagType = (code: string) => {
  switch (code) {
    case 'TRIAL': return 'warning'
    case 'PROFESSIONAL': return 'primary'
    case 'FLAGSHIP': return 'success'
    case 'ENTERPRISE': return 'danger'
    default: return 'info'
  }
}

onMounted(() => {
  // 确保官方生产域名正确初始化为 https://fwpt.cn
  if (!currentDomainConfig.value.officialDomain || currentDomainConfig.value.officialDomain.includes('localhost') || currentDomainConfig.value.officialDomain.includes('seahorse.saas.com')) {
    currentDomainConfig.value.officialDomain = 'https://fwpt.cn'
    saveSystemDomainConfig(currentDomainConfig.value)
  }
  loadPlans()
})
</script>

<style scoped>
.vendor-plans-container {
  padding: 18px 24px 40px;
  background: #f8fafc;
  min-height: calc(100vh - 60px);
}

.page-hero-header {
  background: linear-gradient(135deg, #ffffff 0%, #f1f5f9 100%);
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03);
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
  background: linear-gradient(135deg, #475569 0%, #334155 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(71, 85, 105, 0.25);
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
  max-width: 820px;
}

.trial-config-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  background: #f8fafc;
  margin-bottom: 18px;
}

.trial-config-inner {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
}

.trial-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.trial-icon {
  font-size: 20px;
}

.trial-title {
  font-size: 16px;
  font-weight: 800;
  color: #1e293b;
}

.trial-desc {
  font-size: 12px;
  color: #64748b;
  margin-top: 6px;
  line-height: 1.5;
}

.trial-right {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.custom-days-box {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #475569;
}

.table-main-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.card-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* 营销海报弹窗与预览样式 */
.poster-dialog-layout {
  display: flex;
  gap: 24px;
  align-items: flex-start;
}

.poster-preview-col {
  flex: 0 0 420px;
  max-width: 420px;
}

.poster-card-canvas-box {
  border: 1px solid rgba(255, 255, 255, 0.16);
  border-radius: 16px;
  padding: 22px 20px;
  color: #ffffff;
  box-shadow: 0 12px 36px rgba(0, 0, 0, 0.35);
  position: relative;
  overflow: hidden;
  transition: all 0.3s ease;
}

/* 主题色彩定义 */
.theme-tech-blue {
  background: linear-gradient(135deg, #090d16 0%, #0f172a 40%, #1e1b4b 100%);
  border-color: rgba(56, 189, 248, 0.3);
}

.theme-black-gold {
  background: linear-gradient(135deg, #0a0a0a 0%, #18181b 45%, #27272a 100%);
  border-color: rgba(245, 158, 11, 0.4);
}

.theme-black-gold .poster-brand-badge {
  background: rgba(245, 158, 11, 0.18);
  border-color: #fbbf24;
  color: #fbbf24;
}

.theme-black-gold .curr,
.theme-black-gold .price-val,
.theme-black-gold .q-val,
.theme-black-gold .qh-code {
  color: #fbbf24 !important;
}

.theme-coral-orange {
  background: linear-gradient(135deg, #1c0d1b 0%, #2a0826 45%, #451a03 100%);
  border-color: rgba(249, 115, 22, 0.4);
}

.theme-coral-orange .poster-brand-badge {
  background: rgba(249, 115, 22, 0.2);
  border-color: #fb923c;
  color: #fb923c;
}

.theme-coral-orange .curr,
.theme-coral-orange .price-val,
.theme-coral-orange .q-val,
.theme-coral-orange .qh-code {
  color: #fb923c !important;
}

.theme-forest-green {
  background: linear-gradient(135deg, #022c22 0%, #064e3b 45%, #0f172a 100%);
  border-color: rgba(16, 185, 129, 0.4);
}

.theme-forest-green .poster-brand-badge {
  background: rgba(16, 185, 129, 0.2);
  border-color: #34d399;
  color: #34d399;
}

.theme-forest-green .curr,
.theme-forest-green .price-val,
.theme-forest-green .q-val,
.theme-forest-green .qh-code {
  color: #34d399 !important;
}

.poster-brand-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.poster-brand-badge {
  background: rgba(56, 189, 248, 0.18);
  border: 1px solid #38bdf8;
  color: #38bdf8;
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 700;
}

.poster-brand-sub {
  font-size: 11px;
  color: #94a3b8;
}

.poster-main-title {
  font-size: 22px;
  font-weight: 900;
  letter-spacing: 0.5px;
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 4px;
}

.poster-slogan {
  font-size: 12px;
  color: #94a3b8;
  margin-bottom: 16px;
}

.poster-plan-badge-card {
  background: rgba(30, 41, 59, 0.85);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 14px;
  padding: 16px 18px;
  margin-bottom: 16px;
  position: relative;
}

.plan-card-tag {
  display: inline-block;
  background: #f59e0b;
  color: #0f172a;
  font-size: 10px;
  font-weight: 800;
  padding: 2px 8px;
  border-radius: 4px;
  margin-bottom: 6px;
}

.plan-card-name {
  font-size: 18px;
  font-weight: 800;
  color: #ffffff;
}

.plan-card-price-row {
  display: flex;
  align-items: baseline;
  margin: 6px 0 2px;
}

.plan-card-price-row .curr {
  font-size: 18px;
  font-weight: 800;
  color: #38bdf8;
}

.plan-card-price-row .price-val {
  font-size: 32px;
  font-weight: 900;
  color: #38bdf8;
  line-height: 1;
}

.plan-card-price-row .price-unit {
  font-size: 13px;
  color: #94a3b8;
  margin-left: 6px;
}

.original-price-strike {
  text-decoration: line-through;
  font-size: 14px;
  color: #94a3b8;
  margin-left: 8px;
  font-weight: 500;
}

.plan-card-daily {
  font-size: 12px;
  color: #cbd5e1;
  margin-bottom: 12px;
}

.plan-card-quotas {
  display: flex;
  justify-content: space-around;
  align-items: center;
  background: rgba(15, 23, 42, 0.6);
  border-radius: 10px;
  padding: 10px 8px;
}

.quota-col {
  text-align: center;
}

.quota-col .q-val {
  display: block;
  font-size: 15px;
  font-weight: 800;
  color: #38bdf8;
}

.quota-col .q-lbl {
  font-size: 10px;
  color: #94a3b8;
}

.q-div {
  width: 1px;
  height: 24px;
  background: rgba(255, 255, 255, 0.1);
}

.poster-perks-box {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 16px;
}

.perk-item {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 12px;
  color: #e2e8f0;
  line-height: 1.4;
}

.perk-item .p-dot {
  font-size: 13px;
  flex-shrink: 0;
}

.poster-trial-guarantee {
  background: rgba(16, 185, 129, 0.15);
  border: 1px solid #10b981;
  color: #34d399;
  border-radius: 10px;
  padding: 10px 14px;
  font-size: 12px;
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
}

.poster-qr-footer {
  background: rgba(15, 23, 42, 0.88);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 12px;
  padding: 12px 14px;
  display: flex;
  align-items: center;
  gap: 14px;
}

.real-qr-box {
  width: 82px;
  height: 82px;
  background: #ffffff;
  border-radius: 8px;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.real-poster-qr-img {
  width: 100%;
  height: 100%;
  display: block;
  border-radius: 4px;
}

.qr-loading-box {
  color: #64748b;
  font-size: 20px;
}

.qr-hint-box {
  flex: 1;
  min-width: 0;
}

.qh-scan {
  font-weight: 800;
  font-size: 13px;
  color: #ffffff;
}

.qh-sub {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
}

.qh-code {
  font-size: 11px;
  color: #38bdf8;
  margin-top: 3px;
}

.qh-url {
  font-size: 10px;
  color: #64748b;
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.preview-scan-tip {
  margin-top: 10px;
  font-size: 11px;
  color: #475569;
  background: #f1f5f9;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 12px;
  line-height: 1.5;
}

/* 右侧动作列与标签栏 */
.poster-actions-col {
  flex: 1;
  min-width: 0;
}

.poster-tabs-wrap {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  overflow: hidden;
  background: #ffffff;
}

.edit-tab-scroll {
  max-height: 570px;
  overflow-y: auto;
  padding-right: 4px;
}

.custom-form-section {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
}

.cfs-title {
  font-weight: 800;
  font-size: 13px;
  color: #0f172a;
  margin-bottom: 10px;
}

.theme-options-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
}

.theme-btn {
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 8px 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  font-weight: 700;
  background: #ffffff;
  transition: all 0.2s;
}

.theme-btn:hover {
  border-color: #0284c7;
  background: #f0f9ff;
}

.theme-btn.active {
  border-color: #0284c7;
  background: #e0f2fe;
  color: #0369a1;
  box-shadow: 0 0 0 1px #0284c7;
}

.theme-dot {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  display: inline-block;
  flex-shrink: 0;
}

.download-highlight-btn {
  background: linear-gradient(135deg, #0284c7 0%, #4f46e5 100%) !important;
  border: none !important;
  color: #ffffff !important;
  font-size: 14px;
  box-shadow: 0 4px 12px rgba(2, 132, 199, 0.3);
}

.action-section-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 16px 18px;
}

.as-title {
  font-weight: 800;
  font-size: 13px;
  color: #1e293b;
}

.action-buttons-stack {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 12px;
}

.distribute-btn {
  width: 100%;
  font-weight: 700;
  justify-content: center;
  height: 44px;
}

/* 微信转发预览弹窗 */
.wechat-share-dialog-content {
  padding: 10px 0;
}

.wechat-preview-box {
  background: #ededed;
  border-radius: 10px;
  padding: 18px 20px;
  margin-bottom: 16px;
}

.wechat-bubble-sender {
  font-size: 12px;
  color: #666666;
  margin-bottom: 8px;
}

.wechat-card-preview {
  background: #ffffff;
  border-radius: 8px;
  padding: 12px 14px;
  max-width: 360px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.wc-top-badge {
  font-size: 10px;
  color: #07c160;
  font-weight: 700;
  margin-bottom: 4px;
}

.wc-title {
  font-size: 14px;
  font-weight: 800;
  color: #111111;
  line-height: 1.3;
}

.wc-body {
  display: flex;
  gap: 10px;
  align-items: center;
  margin: 8px 0;
}

.wc-thumb {
  width: 44px;
  height: 44px;
  background: #e0f2fe;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  flex-shrink: 0;
}

.wc-desc {
  font-size: 11px;
  color: #666666;
  line-height: 1.4;
}

.wc-footer {
  border-top: 1px solid #f0f0f0;
  padding-top: 6px;
  font-size: 10px;
  color: #999999;
  display: flex;
  justify-content: space-between;
}

.wc-tag {
  color: #07c160;
  font-weight: 700;
}

.wechat-guide-tips {
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-size: 12px;
  color: #475569;
}

.tip-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.freemium-intro-banner {
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 8px;
}

.fib-left {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}

.fib-icon {
  font-size: 20px;
  line-height: 1;
}

.fib-text {
  font-size: 12.5px;
  color: #166534;
  line-height: 1.6;
}
</style>
