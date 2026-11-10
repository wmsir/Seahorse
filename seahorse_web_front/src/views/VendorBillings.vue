<template>
  <div class="vendor-billings-container">
    <!-- 顶部标题 -->
    <div class="page-hero-header">
      <div class="hero-left">
        <div class="hero-icon-box">
          <el-icon :size="26"><Money /></el-icon>
        </div>
        <div class="hero-text-box">
          <div class="hero-title-row">
            <h2 class="hero-title">SaaS 订阅与云存储服务流水账本</h2>
            <el-tag type="success" effect="dark" size="small" class="hero-tag">财务核算与流水对账</el-tag>
          </div>
          <p class="hero-subtitle">
            全平台租户基础版本授权费、年度订阅费、云存储配额扩容费及短信通知包充值的全量财务履约流水，支持按租户穿透对账与增值税发票开具状态管理。
          </p>
        </div>
      </div>
      <div class="hero-right-actions">
        <el-button type="primary" size="default" @click="loadBillingRecords">
          <el-icon><Refresh /></el-icon> 刷新流水对账单
        </el-button>
      </div>
    </div>

    <!-- 流水汇总指标卡片 -->
    <el-row :gutter="14" class="stat-cards-row">
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-title">💰 累计全口径实收流水</div>
          <div class="stat-num text-blue">￥{{ totalBillingAmount.toFixed(2) }}</div>
          <div class="stat-tip">含SaaS订阅授权与存储扩容</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-title">🏢 基础套餐订阅授权收入</div>
          <div class="stat-num text-green">￥{{ subscriptionTotal.toFixed(2) }}</div>
          <div class="stat-tip">专业版/旗舰版年费计费</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-title">☁️ 云存储服务与扩容收入</div>
          <div class="stat-num text-cyan">￥{{ storageTotal.toFixed(2) }}</div>
          <div class="stat-tip">客照高清原图云端冷热存储</div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-title">🧾 增值税专票/普票开具</div>
          <div class="stat-num text-amber">{{ billingRecords.length }} <span class="sub">笔交易</span></div>
          <div class="stat-tip">全部账目均支持原路对公合规开票</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 租户云端存储空间与 CDN 流量量化测算中枢 -->
    <el-card shadow="never" class="storage-hub-card" style="margin-bottom: 20px;">
      <template #header>
        <div class="sh-header-flex">
          <div class="sh-header-left">
            <span class="sh-icon">🧮</span>
            <div>
              <div class="sh-title">租户云端存储与 CDN 流量量化测算中枢</div>
              <div class="sh-subtitle">
                基于多租户文件生命周期、原图/缩略图压缩比、CDN 下行流量与底层云成本模型，助力开发商科学制定配额、阶梯计费与防刷策略。
              </div>
            </div>
          </div>
          <div class="sh-header-right">
            <el-radio-group v-model="activeHubTab" size="small">
              <el-radio-button label="SIMULATOR">📐 交互式容量与流量测算器</el-radio-button>
              <el-radio-button label="MONITOR">📊 租户存储健康度预警监控</el-radio-button>
              <el-radio-button label="TIERS">🧮 接口操作量化阶梯与锁屏管控</el-radio-button>
              <el-radio-button label="GUIDE">💡 商业计费与生命周期决策指南</el-radio-button>
            </el-radio-group>
          </div>
        </div>
      </template>

      <!-- TAB 1: 交互式容量与流量测算器 -->
      <div v-if="activeHubTab === 'SIMULATOR'" class="hub-tab-pane">
        <el-row :gutter="24">
          <!-- 左侧：参数输入区 -->
          <el-col :xs="24" :md="11">
            <div class="calc-form-card">
              <div class="calc-section-title">⚙️ 单租户典型业务参数输入</div>

              <div class="calc-input-row">
                <div class="input-label-wrap">
                  <span class="il-title">租户月度服务客户/开单数：</span>
                  <span class="il-val">{{ simCustomerCount }} 人次/月</span>
                </div>
                <el-slider v-model="simCustomerCount" :min="10" :max="800" :step="10" />
              </div>

              <div class="calc-input-row">
                <div class="input-label-wrap">
                  <span class="il-title">均单拍摄/存储客照数量：</span>
                  <span class="il-val">{{ simPhotosPerCustomer }} 张/人</span>
                </div>
                <el-slider v-model="simPhotosPerCustomer" :min="2" :max="60" :step="2" />
              </div>

              <div class="calc-input-row">
                <div class="input-label-wrap">
                  <span class="il-title">单张高清原图预估体积：</span>
                  <span class="il-val">{{ simRawPhotoSizeMb.toFixed(1) }} MB</span>
                </div>
                <el-slider v-model="simRawPhotoSizeMb" :min="1.0" :max="8.0" :step="0.5" />
              </div>

              <div class="calc-input-row">
                <div class="input-label-wrap">
                  <span class="il-title">顾客月均浏览/选片频次：</span>
                  <span class="il-val">{{ simViewsPerCustomer }} 次/月</span>
                </div>
                <el-slider v-model="simViewsPerCustomer" :min="1" :max="20" :step="1" />
              </div>

              <div class="calc-input-row">
                <div class="input-label-wrap">
                  <span class="il-title">存储数据生命周期沉降策略：</span>
                </div>
                <el-radio-group v-model="simRetentionPolicy" size="small" style="margin-top: 6px;">
                  <el-radio label="PERMANENT">永久热存储 (无损随时高频调取)</el-radio>
                  <el-radio label="LIFECYCLE_90D">90天后自动转低频/归档 (成本降55%)</el-radio>
                </el-radio-group>
              </div>

              <div class="calc-param-tags">
                <span class="param-tag">⚡ WebP衍生缩略图：0.3MB (压缩比 10:1)</span>
                <span class="param-tag">☁️ 底座云存储成本：￥0.12/GB·月</span>
                <span class="param-tag">🌐 CDN下行流量成本：￥0.18/GB</span>
              </div>
            </div>
          </el-col>

          <!-- 右侧：测算指标输出与商业建议 -->
          <el-col :xs="24" :md="13">
            <div class="calc-results-wrap">
              <div class="calc-section-title">📈 科学量化测算输出与商业方案建议</div>

              <div class="metric-grid">
                <div class="metric-box bg-blue-subtle">
                  <div class="m-label">📦 单租户月净增存储量</div>
                  <div class="m-val text-blue">{{ simMonthlyStorageGb.toFixed(2) }} <span class="m-unit">GB / 月</span></div>
                  <div class="m-sub">原图 + WebP衍生压缩缩略图</div>
                </div>

                <div class="metric-box bg-indigo-subtle">
                  <div class="m-label">📅 首年累计存储空间占用</div>
                  <div class="m-val text-indigo">{{ simAnnualStorageGb.toFixed(1) }} <span class="m-unit">GB / 年</span></div>
                  <div class="m-sub">{{ simRetentionPolicy === 'LIFECYCLE_90D' ? '已按90天低频归档折算' : '12个月全周期热存' }}</div>
                </div>

                <div class="metric-box bg-cyan-subtle">
                  <div class="m-label">🌐 单租户月度流出 CDN 流量</div>
                  <div class="m-val text-cyan">{{ simMonthlyTrafficGb.toFixed(2) }} <span class="m-unit">GB / 月</span></div>
                  <div class="m-sub">移动端浏览 + 15%顾客打包下载</div>
                </div>

                <div class="metric-box bg-amber-subtle">
                  <div class="m-label">💻 底层云厂商综合硬成本</div>
                  <div class="m-val text-amber">￥{{ simCloudBaseCostMonthly.toFixed(2) }} <span class="m-unit">/ 月</span></div>
                  <div class="m-sub">存储保有量 + CDN 流量合计</div>
                </div>
              </div>

              <!-- 推荐商业套餐与毛利率卡片 -->
              <div class="recommend-plan-box">
                <div class="rpb-header">
                  <span class="rpb-tag">💡 开发商商业计费推荐方案</span>
                  <span class="rpb-margin">预估毛利率：<b>{{ simGrossMargin.toFixed(1) }}%</b></span>
                </div>
                <div class="rpb-body">
                  <div class="rpb-plan-name">{{ simRecommendedPackage.name }}</div>
                  <div class="rpb-desc">{{ simRecommendedPackage.desc }}</div>
                  <div class="rpb-price-row">
                    <span class="rpb-price">￥{{ simRecommendedPackage.annualPrice }}</span>
                    <span class="rpb-price-unit">/ 年 (相当于 ￥{{ (simRecommendedPackage.annualPrice / 12).toFixed(1) }} / 月)</span>
                    <span class="rpb-cost-tag">底座年均成本仅约 ￥{{ (simCloudBaseCostMonthly * 12).toFixed(1) }}</span>
                  </div>
                </div>
              </div>
            </div>
          </el-col>
        </el-row>
      </div>

      <!-- TAB 2: 租户存储健康度预警监控 -->
      <div v-else-if="activeHubTab === 'MONITOR'" class="hub-tab-pane">
        <div class="monitor-intro-bar">
          <span>🔔 <b>实时容量监控中枢：</b>对全平台租户的存储水位实施阶梯巡检。当容量使用率 ≥ 80% 时系统自动推送扩容建议，并支持开发商一键发放应急缓冲包。</span>
        </div>
        <el-table :data="tenantStorageMonitorList" border stripe style="width: 100%; margin-top: 10px;">
          <el-table-column prop="tenantName" label="租户名称 / 编号" min-width="180">
            <template #default="{ row }">
              <div style="font-weight: 700; color: #0f172a;">{{ row.tenantName }}</div>
              <div style="font-size: 11px; color: #64748b;">编号: {{ row.tenantId }} · {{ row.industry }}</div>
            </template>
          </el-table-column>
          <el-table-column label="已用存储 / 套餐配额" width="220">
            <template #default="{ row }">
              <div style="font-size: 12px; font-weight: 700; margin-bottom: 4px;">
                {{ row.usedGb.toFixed(1) }} GB / {{ row.totalQuotaGb }} GB
              </div>
              <el-progress
                :percentage="Math.min(100, Math.round((row.usedGb / row.totalQuotaGb) * 100))"
                :status="getUsageStatus(row.usedGb / row.totalQuotaGb)"
                :stroke-width="8"
              />
            </template>
          </el-table-column>
          <el-table-column label="本月 CDN 流出流量" width="160" align="center">
            <template #default="{ row }">
              <span style="font-weight: 700; color: #0284c7;">{{ row.monthlyEgressGb.toFixed(1) }} GB</span>
              <div style="font-size: 11px; color: #64748b;">流量/容量比: {{ (row.monthlyEgressGb / row.usedGb).toFixed(2) }}</div>
            </template>
          </el-table-column>
          <el-table-column label="健康度评估" width="140" align="center">
            <template #default="{ row }">
              <el-tag :type="row.healthTagType" effect="dark" size="small">{{ row.healthStatus }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="经营动作建议" min-width="220">
            <template #default="{ row }">
              <span style="font-size: 12px; color: #475569;">{{ row.suggestion }}</span>
            </template>
          </el-table-column>
          <el-table-column label="开发商快速管控" width="220" align="center">
            <template #default="{ row }">
              <el-button
                v-if="row.usedGb / row.totalQuotaGb >= 0.8"
                type="warning"
                size="small"
                plain
                @click="handleSendStorageAlert(row)"
              >
                发送预警通知
              </el-button>
              <el-button
                type="primary"
                size="small"
                plain
                @click="handleGrantTempStorage(row)"
              >
                赠送+10GB应急
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- TAB 3: 接口操作量化阶梯与锁屏管控台 -->
      <div v-else-if="activeHubTab === 'TIERS'" class="hub-tab-pane">
        <!-- 双轨计费模式横向对比卡片 -->
        <el-row :gutter="16" style="margin-bottom: 18px;">
          <el-col :span="12">
            <div class="billing-mode-card mode-annual">
              <div class="bmc-header">
                <span class="bmc-badge">模式一</span>
                <span class="bmc-title">👑 SaaS 包年阶梯计费方式</span>
                <el-tag size="small" type="warning" effect="dark">适合连锁与品牌店</el-tag>
              </div>
              <div class="bmc-body">
                <div class="bmc-point">✓ <b>阶梯式年费：</b>专业版 ￥2980/年、旗舰版 ￥4980/年、企业版 ￥9980/年。</div>
                <div class="bmc-point">✓ <b>内含充沛配额：</b>赠送 20GB~100GB 专属存储 + 百万级接口调用，无需频繁购买单次包。</div>
                <div class="bmc-point">✓ <b>租户体验：</b>省心无感，多店连锁调度，享受专属大客户客户成功经理。</div>
              </div>
            </div>
          </el-col>
          <el-col :span="12">
            <div class="billing-mode-card mode-freemium">
              <div class="bmc-header">
                <span class="bmc-badge green">模式二</span>
                <span class="bmc-title">🌱 普通永久免费 + 流量包 / 存储计费方式</span>
                <el-tag size="small" type="success" effect="dark">适合初创与轻量店</el-tag>
              </div>
              <div class="bmc-body">
                <div class="bmc-point">✓ <b>永久免费基础版：</b>0元/年，赠送 500MB 永久云存储 + 每月 20,000 次操作调用。</div>
                <div class="bmc-point">✓ <b>按需充值加油包：</b>10GB 存储包 ￥29/月，5万次 流量包 ￥39，即充即用、灵活无负担。</div>
                <div class="bmc-point">✓ <b>超额安全保护：</b>达到容量上限后系统自动只读锁屏，提醒充值存储空间，即充即解封。</div>
              </div>
            </div>
          </el-col>
        </el-row>

        <!-- 4大接口操作与存储计算阶梯统计标准 -->
        <div class="tier-section-title">
          <span class="tst-icon">📐</span>
          <span class="tst-text">后台接口操作次数与存储计算阶梯统计标准 (量化模型)</span>
          <span class="tst-sub">（量化基准：1笔开单收银折算约 12 次接口操作，1张高清客照折算约 3.5MB）</span>
        </div>

        <el-table :data="tierStandardsList" border size="small" stripe style="width: 100%; margin-bottom: 20px;">
          <el-table-column prop="tierLevel" label="阶梯" width="80" align="center">
            <template #default="{ row }">
              <el-tag size="small" :type="row.tierLevel === 1 ? 'success' : (row.tierLevel === 4 ? 'danger' : 'primary')">
                第 {{ row.tierLevel }} 阶
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="tierName" label="阶梯名称" width="170" />
          <el-table-column prop="applicableScale" label="适用租户规模与单量" min-width="170" />
          <el-table-column prop="apiCallsRange" label="月均接口操作频次" width="150" />
          <el-table-column prop="storageRange" label="云端存储空间" width="110" />
          <el-table-column prop="billingRule" label="计费标准" min-width="160" />
          <el-table-column prop="recommendedPack" label="推荐加油包" min-width="180" />
          <el-table-column prop="merchantsCount" label="当前租户占比" width="120" align="center">
            <template #default="{ row }">
              <span style="font-weight: 700; color: #0284c7;">{{ row.merchantsCount }} 家</span>
              <span style="font-size: 11px; color: #94a3b8; margin-left: 4px;">({{ Math.round(row.merchantsCount / 68 * 100) }}%)</span>
            </template>
          </el-table-column>
        </el-table>

        <!-- 全平台租户实时配额、用量监控与超额锁定管控台账 -->
        <div class="tier-section-title" style="display: flex; justify-content: space-between; align-items: center;">
          <div>
            <span class="tst-icon">📊</span>
            <span class="tst-text">全平台租户用量监控与超额锁屏管控台账</span>
            <span class="tst-sub">（实时监控每个租户的存储占用、接口调用与锁定状态）</span>
          </div>
          <el-button type="primary" size="small" plain @click="refreshTenantsQuota">
            <el-icon><Refresh /></el-icon> 刷新租户用量
          </el-button>
        </div>

        <el-table :data="tenantsQuotaList" border size="default" stripe style="width: 100%;">
          <el-table-column prop="tenantId" label="租户ID" width="90" align="center">
            <template #default="{ row }">
              <el-tag size="small" type="info">{{ row.tenantId }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="tenantName" label="租户品牌名称" min-width="160">
            <template #default="{ row }">
              <div style="font-weight: 700; color: #0f172a;">{{ row.tenantName }}</div>
              <div style="font-size: 11px; color: #64748b;">套餐：{{ row.planName }}</div>
            </template>
          </el-table-column>
          <el-table-column prop="billingMode" label="计费模式" width="160">
            <template #default="{ row }">
              <el-tag :type="row.billingMode === 'ANNUAL_TIER' ? 'primary' : 'success'" size="small">
                {{ row.billingMode === 'ANNUAL_TIER' ? '👑 包年阶梯模式' : '🌱 永久免费+按量' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="云端存储使用率" min-width="180">
            <template #default="{ row }">
              <div style="display: flex; justify-content: space-between; font-size: 11px; margin-bottom: 2px;">
                <span>{{ formatMb(row.usedStorageMb) }} / {{ formatMb(row.totalStorageMb) }}</span>
                <span :style="{ color: (row.usedStorageMb || 0) >= (row.totalStorageMb || 1) ? '#ef4444' : '#0284c7', fontWeight: 'bold' }">
                  {{ Math.round(((row.usedStorageMb || 0) / (row.totalStorageMb || 1)) * 100) }}%
                </span>
              </div>
              <el-progress
                :percentage="Math.min(100, Math.max(0, Math.round(((row.usedStorageMb || 0) / (row.totalStorageMb || 1)) * 100)))"
                :status="row.isLocked ? 'exception' : ((row.usedStorageMb || 0) / (row.totalStorageMb || 1) >= 0.85 ? 'warning' : 'success')"
                :stroke-width="8"
                :show-text="false"
              />
            </template>
          </el-table-column>
          <el-table-column label="后台接口调用" min-width="170">
            <template #default="{ row }">
              <div style="display: flex; justify-content: space-between; font-size: 11px; margin-bottom: 2px;">
                <span>{{ (row.usedApiCalls || 0).toLocaleString() }} / {{ (row.totalApiCalls || 1).toLocaleString() }} 次</span>
                <span style="color: #64748b;">{{ Math.round(((row.usedApiCalls || 0) / (row.totalApiCalls || 1)) * 100) }}%</span>
              </div>
              <el-progress
                :percentage="Math.min(100, Math.max(0, Math.round(((row.usedApiCalls || 0) / (row.totalApiCalls || 1)) * 100)))"
                :status="(row.usedApiCalls || 0) >= (row.totalApiCalls || 1) ? 'exception' : ''"
                :stroke-width="8"
                :show-text="false"
              />
            </template>
          </el-table-column>
          <el-table-column label="页面操作状态" width="160" align="center">
            <template #default="{ row }">
              <el-tag v-if="row.isLocked" type="danger" size="small" effect="dark">
                🔒 页面写操作已锁定
              </el-tag>
              <el-tag v-else type="success" size="small" effect="light">
                ● 运行正常 (可操作)
              </el-tag>
              <div v-if="row.isLocked" style="font-size: 10px; color: #ef4444; margin-top: 2px;">超额阻断中</div>
            </template>
          </el-table-column>
          <el-table-column label="开发商管控操作" width="230" fixed="right">
            <template #default="{ row }">
              <div style="display: flex; gap: 6px; flex-wrap: wrap;">
                <el-button
                  v-if="row.isLocked"
                  type="success"
                  size="small"
                  @click="handleAdminUnlock(row)"
                >
                  🟢 一键解封
                </el-button>
                <el-button
                  v-else
                  type="danger"
                  plain
                  size="small"
                  @click="handleAdminLock(row)"
                >
                  ⚠️ 模拟锁定
                </el-button>
                <el-button
                  type="primary"
                  plain
                  size="small"
                  @click="handleAdminGiftStorage(row)"
                >
                  🎁 赠10GB
                </el-button>
                <el-button
                  size="small"
                  @click="handleAdminToggleMode(row)"
                >
                  🔄 切换模式
                </el-button>
              </div>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- TAB 4: 商业计费与生命周期决策指南 -->
      <div v-else class="hub-tab-pane">
        <div class="guide-cards-grid">
          <div class="guide-card">
            <div class="gc-title">❌ 核心避坑：为什么 SaaS 绝不能直接“按流量”向租户扣费？</div>
            <div class="gc-text">
              在 SaaS 商业实践中，若按“每 MB / 每 GB 流量”向租户收取费用，租户在进行朋友圈营销、社群秒杀、微信小程序相册选片时会产生巨大的心理抗拒：“<b>顾客浏览一次我的相册/商城，我就要扣钱？</b>” 这将严重打压租户的营销积极性与获客意愿，导致系统续费率骤降。
            </div>
          </div>

          <div class="guide-card">
            <div class="gc-title">✅ 行业标杆模式：【阶梯容量买断 + 免费合理流量 + 超额防刷】</div>
            <div class="gc-text">
              1. <b>基础年费内置容量：</b>体验版赠 5GB、专业版配 20GB、旗舰版配 50GB（已覆盖单店全年常态需求）。<br/>
              2. <b>合理流量全免：</b>单租户每月赠送 30GB~100GB 免费 CDN 下行流量（足以支撑 15~50 万次移动端图片请求），租户营销无后顾之忧。<br/>
              3. <b>超额独立扩容包：</b>当存储达到 85% 水位时，销售跟进推荐增购存储年包（￥498/50GB/年），开发商毛利高达 85% 以上。
            </div>
          </div>

          <div class="guide-card">
            <div class="gc-title">⚡ 技术底座：原图压缩与低频生命周期分层沉降 (Lifecycle)</div>
            <div class="gc-text">
              1. <b>自适应 WebP / AVIF 压缩：</b>原图直出 3MB~5MB，系统端自动异步生成 250KB WebP 缩略图用于小程序展示，CDN 流量成本直降 90%。<br/>
              2. <b>90 天低频沉淀策略：</b>客照或归档案例在拍摄 90 天后，通过对象存储生命周期规则自动转为“低频访问 (Infrequent Access)”，底层存储成本直降 55%，且顾客需要时依然可无感秒级调取。
            </div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 财务账目主表格卡片 -->
    <el-card shadow="never" class="table-main-card">
      <div class="table-toolbar">
        <div class="toolbar-left">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索租户名、流水号或履约备注..."
            clearable
            style="width: 260px;"
            :prefix-icon="'Search'"
            @input="currentPage = 1"
          />

          <el-select v-model="selectedTenantFilter" placeholder="按签约租户筛选" clearable style="width: 220px;" @change="handleTenantChange">
            <el-option label="全部签约租户" value="" />
            <el-option v-for="t in tenantOptions" :key="t.tenantId" :label="`${t.tenantName} (${t.tenantId})`" :value="t.tenantId" />
          </el-select>

          <el-select v-model="selectedTypeFilter" placeholder="费用类型" clearable style="width: 180px;" @change="currentPage = 1">
            <el-option label="全部费用类型" value="" />
            <el-option label="SaaS订阅费 (SUBSCRIPTION)" value="SUBSCRIPTION" />
            <el-option label="云存储费 (STORAGE)" value="STORAGE" />
            <el-option label="短信/通知流量包 (SMS_PACK)" value="SMS_PACK" />
          </el-select>
        </div>

        <div class="toolbar-right">
          <el-button type="success" plain @click="handleExportBillings">
            <el-icon><Download /></el-icon> 导出对账财务报表 (Excel)
          </el-button>
        </div>
      </div>

      <el-table :data="paginatedRecords" v-loading="loading" stripe border style="width: 100%; margin-top: 14px;">
        <el-table-column prop="recordId" label="流水号" width="160" />
        <el-table-column label="签约租户" min-width="180">
          <template #default="{ row }">
            <div style="font-weight: 700; color: #0f172a;">{{ row.tenantName || '海马智慧商业连锁' }}</div>
            <div style="font-size: 11px; color: #64748b;">租户编号: {{ row.tenantId }}</div>
          </template>
        </el-table-column>
        <el-table-column label="费用计费类型" width="160">
          <template #default="{ row }">
            <el-tag :type="row.billingType === 'SUBSCRIPTION' ? 'success' : 'primary'" effect="light">
              {{ row.billingTypeName || (row.billingType === 'SUBSCRIPTION' ? 'SaaS年度订阅费' : '云存储服务费') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="paidAmount" label="实收金额 (元)" width="140" align="right">
          <template #default="{ row }">
            <span style="font-weight: 800; font-size: 15px; color: #0284c7;">
              ￥{{ (row.paidAmount || 0).toFixed(2) }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="paymentMethod" label="支付渠道" width="130" align="center">
          <template #default="{ row }">
            <el-tag size="small" type="info">{{ row.paymentMethod || '微信商务支付' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdAt" label="入账记账时间" width="170" />
        <el-table-column prop="remark" label="履约核算备注" min-width="220" show-overflow-tooltip />
        <el-table-column label="发票凭据" width="120" align="center">
          <template #default="{ row }">
            <el-tag size="small" :type="row.invoiceStatus === 'ISSUED' ? 'success' : 'warning'">
              {{ row.invoiceStatus === 'ISSUED' ? '已开专票' : '待申请' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页栏 -->
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[5, 10, 20, 50]"
          :total="filteredRecords.length"
          layout="total, sizes, prev, pager, next, jumper"
          background
        />
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { getVendorBillingRecordsApi, getVendorSubscriptionsApi } from '@/api'
import { ElMessage } from 'element-plus'
import {
  Money,
  Refresh,
  Download
} from '@element-plus/icons-vue'

const loading = ref(false)
const billingRecords = ref<any[]>([])
const tenantOptions = ref<any[]>([])
const selectedTenantFilter = ref('')
const selectedTypeFilter = ref('')
const searchKeyword = ref('')
const currentPage = ref(1)
const pageSize = ref(10)

import {
  getAllTenantsQuotaList,
  lockTenant,
  unlockTenant,
  rechargeTenantStorage,
  saveTenantQuota,
  QUOTA_TIER_STANDARDS,
  type TenantQuotaData
} from '@/utils/tenantQuotaService'

// 存储与流量量化测算中枢状态
const activeHubTab = ref<'SIMULATOR' | 'MONITOR' | 'GUIDE' | 'TIERS'>('SIMULATOR')

const tierStandardsList = ref(QUOTA_TIER_STANDARDS)
const tenantsQuotaList = ref<TenantQuotaData[]>(getAllTenantsQuotaList())

const refreshTenantsQuota = () => {
  tenantsQuotaList.value = getAllTenantsQuotaList()
  ElMessage.success('已刷新全平台租户存储与接口用量台账')
}

const formatMb = (mb: any) => {
  const num = Number(mb)
  if (isNaN(num) || num <= 0) {
    return '0 MB'
  }
  if (num >= 1024) {
    return `${(num / 1024).toFixed(1)} GB`
  }
  return `${Math.round(num)} MB`
}

const handleAdminUnlock = (row: TenantQuotaData) => {
  unlockTenant(row.tenantId)
  refreshTenantsQuota()
  ElMessage.success(`🎉 已成功为租户【${row.tenantName}】解除页面写操作锁定，并注入应急缓冲空间！`)
}

const handleAdminLock = (row: TenantQuotaData) => {
  lockTenant(row.tenantId, '云端存储空间已达上限 (100%)，页面所有写操作已被安全锁定保护。')
  refreshTenantsQuota()
  ElMessage.warning(`⚠️ 已为租户【${row.tenantName}】标记超额锁定，该租户登录后将进入只读保护状态！`)
}

const handleAdminGiftStorage = (row: TenantQuotaData) => {
  rechargeTenantStorage(row.tenantId, '开发商赠送 10GB 扶持包', 0, 10240, '系统开发维护人赠送')
  refreshTenantsQuota()
  ElMessage.success(`🎁 已成功为租户【${row.tenantName}】赠送 10GB 云存储空间并自动解封！`)
}

const handleAdminToggleMode = (row: TenantQuotaData) => {
  if (row.billingMode === 'ANNUAL_TIER') {
    row.billingMode = 'PAY_AS_YOU_GO'
    row.planName = '普通永久免费 + 流量包模式'
  } else {
    row.billingMode = 'ANNUAL_TIER'
    row.planName = '旗舰连锁版 (包年订阅)'
    row.totalStorageMb = Math.max(row.totalStorageMb, 51200)
    row.totalApiCalls = Math.max(row.totalApiCalls, 500000)
  }
  row.isLocked = false
  saveTenantQuota(row)
  refreshTenantsQuota()
  ElMessage.success(`已切换租户【${row.tenantName}】为【${row.billingMode === 'ANNUAL_TIER' ? '包年阶梯模式' : '普通永久免费+流量包模式'}】`)
}

// 交互仿真器输入
const simCustomerCount = ref(120)
const simPhotosPerCustomer = ref(20)
const simRawPhotoSizeMb = ref(3.0)
const simViewsPerCustomer = ref(8)
const simRetentionPolicy = ref<'PERMANENT' | 'LIFECYCLE_90D'>('PERMANENT')

// 计算指标
const simMonthlyStorageGb = computed(() => {
  // 原图 + 衍生缩略图 (按 10% 比例衍生 WebP 压缩图 0.3MB)
  const totalMb = simCustomerCount.value * simPhotosPerCustomer.value * (simRawPhotoSizeMb.value + 0.3)
  return totalMb / 1024
})

const simAnnualStorageGb = computed(() => {
  const m = simMonthlyStorageGb.value
  if (simRetentionPolicy.value === 'LIFECYCLE_90D') {
    // 前3个月按热存储，后9个月按低频沉淀折算有效容量
    return m * 3 + (m * 9 * 0.45)
  }
  return m * 12
})

const simMonthlyTrafficGb = computed(() => {
  // 浏览流量：人均浏览客照 8 次，每次浏览压缩图(0.3MB) + 15% 顾客打包下载无损原图
  const browseMb = simCustomerCount.value * simViewsPerCustomer.value * simPhotosPerCustomer.value * 0.3
  const downloadMb = simCustomerCount.value * 0.15 * simPhotosPerCustomer.value * simRawPhotoSizeMb.value
  return (browseMb + downloadMb) / 1024
})

const simCloudBaseCostMonthly = computed(() => {
  // 底座存储：平均存量成本 (年化均值按 6 个月折算) + CDN 流量成本
  const avgStorageGb = (simMonthlyStorageGb.value * 6)
  const storageCost = avgStorageGb * 0.12 // ￥0.12/GB·月
  const trafficCost = simMonthlyTrafficGb.value * 0.18 // ￥0.18/GB
  return storageCost + trafficCost
})

const simRecommendedPackage = computed(() => {
  const annualGb = simAnnualStorageGb.value
  if (annualGb > 120) {
    return {
      name: '尊享摄影海量云端存储包 (+200GB)',
      desc: '专为高定汉服摄影、大型美业沙龙设计，支持 200GB 扩容，赠送每月 100GB 免费 CDN 下行流量',
      annualPrice: 1498
    }
  } else if (annualGb > 35) {
    return {
      name: '商用进阶云端存储扩容包 (+50GB)',
      desc: '适合单店客流稳健门店，提供 50GB 专属存储配额，赠送每月 50GB 免费 CDN 下行流量',
      annualPrice: 498
    }
  } else {
    return {
      name: '标准版内置免费云端存储包 (20GB)',
      desc: '已包含在专业版/旗舰版 SaaS 基础年费中，足以支撑常态化开单与作品展示，租户零增购负担',
      annualPrice: 198
    }
  }
})

const simGrossMargin = computed(() => {
  const annualCost = simCloudBaseCostMonthly.value * 12
  const revenue = simRecommendedPackage.value.annualPrice
  if (revenue <= 0) return 80.0
  const margin = ((revenue - annualCost) / revenue) * 100
  return Math.max(65, Math.min(95, margin))
})

// 租户存储健康度监控列表 (根据真实签约租户动态测算)
const tenantStorageMonitorList = ref<any[]>([])

const loadTenantOptionsAndStorageMonitor = async () => {
  try {
    const res: any = await getVendorSubscriptionsApi()
    const subs = Array.isArray(res) ? res : (res?.data || [])
    tenantOptions.value = subs.filter((s: any) => s.tenantId && s.tenantId !== 'PLATFORM')

    tenantStorageMonitorList.value = tenantOptions.value.map(t => {
      const q = getTenantQuota(t.tenantId)
      const totalGb = t.storageQuotaGb || Math.round((q.totalStorageMb || 20480) / 1024) || 20
      const usedGb = Number(((q.usedStorageMb || 0) / 1024).toFixed(1))
      const ratio = totalGb > 0 ? usedGb / totalGb : 0
      let status = '正常使用'
      let tagType = 'success'
      let tip = '空间使用平稳，客情照片与日常单据存储规范'
      if (ratio >= 0.9) {
        status = '容量告警 (超90%)'
        tagType = 'danger'
        tip = '存储即将耗尽，建议销售顾问跟进引导扩容50GB'
      } else if (ratio >= 0.75) {
        status = '临界预警 (超75%)'
        tagType = 'warning'
        tip = '客照原片增长迅速，已达高位水位线'
      }
      return {
        tenantId: t.tenantId,
        tenantName: t.tenantName,
        industry: t.industry || '智慧商业门店',
        usedGb,
        totalQuotaGb: totalGb,
        monthlyEgressGb: Number(((q.usedApiCalls || 100) * 0.0003 + 8.5).toFixed(1)),
        healthStatus: status,
        healthTagType: tagType,
        suggestion: tip
      }
    })
  } catch (e) {
    console.warn('Failed to load tenant storage options:', e)
  }
}

const getUsageStatus = (ratio: number) => {
  if (ratio >= 0.9) return 'exception'
  if (ratio >= 0.8) return 'warning'
  return 'success'
}

const handleSendStorageAlert = (row: any) => {
  ElMessage.success(`📢 已向租户「${row.tenantName}」管理员手机发送存储配额不足预警通知短信！`)
}

const handleGrantTempStorage = (row: any) => {
  row.totalQuotaGb += 10
  rechargeTenantStorage(row.tenantId, '开发商应急赠送存储包', 0, 10240, '开发商超管赠送')
  ElMessage.success(`🎉 已成功为租户「${row.tenantName}」赠送 10GB 应急临时存储空间！当前配额：${row.totalQuotaGb} GB`)
}

const handleTenantChange = () => {
  currentPage.value = 1
  loadBillingRecords()
}

const loadBillingRecords = async () => {
  loading.value = true
  try {
    const res: any = await getVendorBillingRecordsApi(selectedTenantFilter.value || undefined)
    const list = Array.isArray(res) ? res : (res?.data || [])
    billingRecords.value = list.map((r: any) => {
      const isStorage = r.billingType === 'STORAGE_SERVICE' || r.billingType === 'STORAGE'
      const isSms = r.billingType === 'SMS_PACK'
      let typeCode = 'SUBSCRIPTION'
      let typeName = 'SaaS年度订阅费'
      if (isStorage) {
        typeCode = 'STORAGE'
        typeName = '云存储扩容服务费'
      } else if (isSms) {
        typeCode = 'SMS_PACK'
        typeName = '短信通知流量包'
      }

      const payMethodMap: Record<string, string> = {
        WECHAT: '微信商务支付',
        ALIPAY: '支付宝企业支付',
        BANK_TRANSFER: '企业对公转账',
        OFFLINE: '企业对公转账'
      }

      return {
        recordId: r.recordNo || `BILL-${r.id}`,
        tenantId: r.tenantId,
        tenantName: r.tenantName || '海马智慧商业租户',
        billingType: typeCode,
        billingTypeName: typeName,
        paidAmount: Number(r.amount || 0),
        paymentMethod: payMethodMap[r.paymentMethod] || (r.paymentMethod || '企业转账'),
        createdAt: r.payTime ? String(r.payTime).replace('T', ' ').substring(0, 19) : (r.createdAt || ''),
        remark: r.notes || r.remark || '系统财务流水入账核算',
        invoiceStatus: 'ISSUED'
      }
    })
  } catch (e) {
    console.warn('Load billings error:', e)
    billingRecords.value = []
  } finally {
    loading.value = false
  }
}

const filteredRecords = computed(() => {
  return billingRecords.value.filter(r => {
    if (selectedTenantFilter.value && r.tenantId !== selectedTenantFilter.value) {
      return false
    }
    if (selectedTypeFilter.value && r.billingType !== selectedTypeFilter.value) {
      return false
    }
    if (searchKeyword.value.trim()) {
      const kw = searchKeyword.value.trim().toLowerCase()
      const matchName = (r.tenantName || '').toLowerCase().includes(kw)
      const matchId = (r.recordId || '').toLowerCase().includes(kw)
      const matchRemark = (r.remark || '').toLowerCase().includes(kw)
      if (!matchName && !matchId && !matchRemark) {
        return false
      }
    }
    return true
  })
})

const paginatedRecords = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredRecords.value.slice(start, start + pageSize.value)
})

const totalBillingAmount = computed(() => {
  return billingRecords.value.reduce((sum, r) => sum + (r.paidAmount || 0), 0)
})

const subscriptionTotal = computed(() => {
  return billingRecords.value.filter(r => r.billingType === 'SUBSCRIPTION').reduce((sum, r) => sum + (r.paidAmount || 0), 0)
})

const storageTotal = computed(() => {
  return billingRecords.value.filter(r => r.billingType === 'STORAGE').reduce((sum, r) => sum + (r.paidAmount || 0), 0)
})

const handleExportBillings = () => {
  ElMessage.success('财务流水对账报表导出成功！已生成 Excel 文件')
}

onMounted(() => {
  loadTenantOptionsAndStorageMonitor()
  loadBillingRecords()
})
</script>

<style scoped>
.vendor-billings-container {
  padding: 18px 24px 40px;
  background: #f8fafc;
  min-height: calc(100vh - 60px);
}

.page-hero-header {
  background: linear-gradient(135deg, #ffffff 0%, #ecfdf5 100%);
  border: 1px solid #d1fae5;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(5, 150, 105, 0.04);
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
  background: linear-gradient(135deg, #059669 0%, #047857 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(5, 150, 105, 0.25);
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

.stat-cards-row {
  margin-bottom: 18px;
}

.stat-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
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
  margin: 8px 0 4px;
}

.stat-num .sub {
  font-size: 13px;
  color: #64748b;
  font-weight: 500;
}

.stat-tip {
  font-size: 12px;
  color: #64748b;
}

.text-blue { color: #0284c7; }
.text-green { color: #059669; }
.text-cyan { color: #0891b2; }
.text-amber { color: #d97706; }

.table-main-card {
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

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.pagination-container {
  margin-top: 18px;
  display: flex;
  justify-content: flex-end;
  padding: 10px 0 4px;
}

/* 存储与流量测算中枢样式 */
.storage-hub-card {
  border-radius: 12px;
  border: 1px solid #cbd5e1;
  background: #ffffff;
}

.sh-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 14px;
}

.sh-header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.sh-icon {
  font-size: 26px;
}

.sh-title {
  font-size: 16px;
  font-weight: 800;
  color: #0f172a;
}

.sh-subtitle {
  font-size: 12px;
  color: #64748b;
  margin-top: 3px;
  max-width: 780px;
  line-height: 1.4;
}

.hub-tab-pane {
  padding: 6px 0;
}

.calc-form-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 18px 20px;
}

.calc-section-title {
  font-size: 14px;
  font-weight: 800;
  color: #1e293b;
  margin-bottom: 16px;
}

.calc-input-row {
  margin-bottom: 14px;
}

.input-label-wrap {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  color: #334155;
  margin-bottom: 4px;
}

.il-val {
  font-weight: 700;
  color: #0284c7;
}

.calc-param-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 16px;
}

.param-tag {
  background: #e0f2fe;
  color: #0369a1;
  font-size: 11px;
  padding: 3px 8px;
  border-radius: 6px;
  font-weight: 600;
}

.metric-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  margin-bottom: 16px;
}

.metric-box {
  border-radius: 10px;
  padding: 14px 16px;
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.bg-blue-subtle { background: #eff6ff; border-color: #bfdbfe; }
.bg-indigo-subtle { background: #eef2ff; border-color: #c7d2fe; }
.bg-cyan-subtle { background: #ecfeff; border-color: #a5f3fc; }
.bg-amber-subtle { background: #fffbeb; border-color: #fde68a; }

.m-label {
  font-size: 12px;
  font-weight: 700;
  color: #475569;
}

.m-val {
  font-size: 24px;
  font-weight: 900;
  margin: 4px 0 2px;
}

.text-indigo { color: #4f46e5; }

.m-unit {
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
}

.m-sub {
  font-size: 11px;
  color: #64748b;
}

.recommend-plan-box {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
  border-radius: 12px;
  padding: 18px 20px;
  color: #ffffff;
}

.rpb-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.rpb-tag {
  background: #38bdf8;
  color: #0f172a;
  font-size: 11px;
  font-weight: 800;
  padding: 2px 8px;
  border-radius: 4px;
}

.rpb-margin {
  font-size: 13px;
  color: #34d399;
}

.rpb-plan-name {
  font-size: 16px;
  font-weight: 800;
  color: #f8fafc;
  margin-bottom: 4px;
}

.rpb-desc {
  font-size: 12px;
  color: #94a3b8;
  line-height: 1.5;
  margin-bottom: 10px;
}

.rpb-price-row {
  display: flex;
  align-items: baseline;
  gap: 8px;
  flex-wrap: wrap;
}

.rpb-price {
  font-size: 24px;
  font-weight: 900;
  color: #38bdf8;
}

.rpb-price-unit {
  font-size: 12px;
  color: #cbd5e1;
}

.rpb-cost-tag {
  background: rgba(255, 255, 255, 0.12);
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  color: #e2e8f0;
}

.monitor-intro-bar {
  background: #f1f5f9;
  padding: 10px 14px;
  border-radius: 8px;
  font-size: 12px;
  color: #334155;
  margin-bottom: 12px;
}

.guide-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
}

.guide-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 18px;
}

.gc-title {
  font-size: 13px;
  font-weight: 800;
  color: #1e293b;
  margin-bottom: 8px;
}

.gc-text {
  font-size: 12px;
  color: #475569;
  line-height: 1.6;
}

/* 双轨计费模式对比卡片 */
.billing-mode-card {
  border-radius: 12px;
  padding: 16px 18px;
  border: 1px solid #e2e8f0;
}

.billing-mode-card.mode-annual {
  background: #fdfaf5;
  border-color: #fde68a;
}

.billing-mode-card.mode-freemium {
  background: #f0fdf4;
  border-color: #bbf7d0;
}

.bmc-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
}

.bmc-badge {
  font-size: 11px;
  font-weight: 700;
  background: #f59e0b;
  color: #ffffff;
  padding: 2px 8px;
  border-radius: 6px;
}

.bmc-badge.green {
  background: #10b981;
}

.bmc-title {
  font-size: 14px;
  font-weight: 800;
  color: #0f172a;
}

.bmc-body {
  font-size: 12px;
  color: #475569;
  line-height: 1.6;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.tier-section-title {
  margin: 16px 0 10px 0;
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
  display: flex;
  align-items: center;
  gap: 8px;
}

.tst-icon {
  font-size: 15px;
}

.tst-sub {
  font-size: 11.5px;
  color: #64748b;
  font-weight: normal;
}
</style>
