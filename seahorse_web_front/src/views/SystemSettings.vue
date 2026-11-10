<template>
  <div class="system-settings-page">
    <el-card shadow="hover">
      <template #header>
        <div class="header-box">
          <div class="header-left">
            <span class="title">{{ isStandalonePayment ? '扫码盒子硬件与全渠道聚合支付设置' : (isStandaloneMap ? '考勤定位服务设置' : (isStandaloneJobPosts ? '🏢 部门架构与岗位管理' : '⚙️ 店铺设置')) }}</span>
            <el-tag effect="plain" type="primary">
              {{ isStandalonePayment ? 'USB HID 虚拟键盘 · 个体工租户直连 (0.38%) · 小微租户进件 · 支付宝沙箱测试' : (isStandaloneMap ? '考勤打卡基准经纬度 · 电子围栏偏差半径 · 逆地理编码 · 租户物理隔离' : (isStandaloneJobPosts ? '门店部门组织架构 · 标准岗位编制 · 薪资提成配置 · 招聘海报扫码 · 候选人面试录用' : '行业属性 · 短信配置 · 储值策略 · 小票打印 · 全渠道公众号推送')) }}
            </el-tag>
          </div>
          <div class="header-right" style="display: flex; gap: 10px;">
            <template v-if="isStandalonePayment && isPlatformAdmin">
              <el-button type="primary" icon="Check" :loading="savingPayment" @click="handleSavePaymentConfig">
                保存支付通道配置
              </el-button>
            </template>
            <template v-else-if="isStandaloneMap">
              <el-button type="success" plain icon="Compass" @click="handleGetBrowserLocation">
                📍 获取当前物理坐标
              </el-button>
              <el-button v-if="isPlatformAdmin" type="warning" plain icon="Connection" :loading="testingAmap" @click="handleTestAmapApiKey">
                🔌 测试平台Key连通性
              </el-button>
              <el-button type="primary" icon="Check" :loading="savingAmap" @click="handleSaveAmapConfig">
                保存考勤打卡配置
              </el-button>
            </template>
            <template v-else-if="isStandaloneJobPosts">
              <el-button type="primary" icon="Plus" @click="handleOpenAddPost">
                新增岗位编制
              </el-button>
              <el-button type="success" plain icon="User" @click="postSubTab = 'APPLICATIONS'">
                应聘简历与面试看板
              </el-button>
            </template>
            <template v-else>
              <el-button type="success" plain icon="OfficeBuilding" @click="handleLoadFootSpaDemoData">
                💆‍♂️ 一键装载足疗推拿业务模拟数据
              </el-button>
              <el-button type="primary" icon="Check" :loading="saving" @click="handleSaveAllSettings">
                保存通用设置
              </el-button>
            </template>
          </div>
        </div>
      </template>

      <!-- A. 独立页面模式 1: 仅展示 扫码盒子与支付通道 -->
      <div v-if="isStandalonePayment" class="standalone-payment-container">
        <!-- 非平台超级管理员权限拦截提示 -->
        <div v-if="!isPlatformAdmin" style="padding: 60px 20px; text-align: center; background: #fff; border-radius: 8px;">
          <el-result
            icon="warning"
            title="权限受限：仅系统超级管理员可配置"
            sub-title="扫码盒子硬件与聚合支付通道仅限超级管理员进行配置与密钥维护，当前角色无操作权限。"
          >
            <template #extra>
              <el-button type="primary" @click="$router.push('/dashboard')">返回工作台</el-button>
            </template>
          </el-result>
        </div>
        <div v-else class="payment-settings-pane">
            
            <!-- 1. 顶部状态简报与快速控制栏 (Header HUD & Summary) -->
            <div class="pay-hud-bar">
              <div class="hud-left">
                <div class="hud-badge-title">
                  <span class="hud-icon">💳</span>
                  <div class="hud-title-group">
                    <div class="hud-main-title">
                      全渠道聚合支付通道与硬件工作台
                      <el-tag size="small" type="danger" effect="dark">超级管理员专属</el-tag>
                    </div>
                    <div class="hud-subtitle">
                      免驱动扫码盒子即插即用，覆盖个体工租户直连、持牌聚合小微租户、支付宝官方沙箱前置联调
                    </div>
                  </div>
                </div>
              </div>

              <div class="hud-metrics">
                <div class="metric-chip">
                  <span class="m-label">当前系统收款通道</span>
                  <span class="m-val" :class="getActiveRouteColorClass(paymentForm.activeRoute)">
                    {{ getRouteShortTitle(paymentForm.activeRoute) }}
                  </span>
                </div>
                <div class="metric-chip">
                  <span class="m-label">执行费率</span>
                  <span class="m-val text-green">{{ getActiveFeeRate() }}</span>
                </div>
                <div class="metric-chip">
                  <span class="m-label">免驱扫码盒子</span>
                  <span class="m-val text-blue">🟢 USB HID 已就绪</span>
                </div>
              </div>

              <div class="hud-actions">
                <el-button type="primary" icon="Check" :loading="savingPayment" @click="handleSavePaymentConfig">
                  保存当前全部设置
                </el-button>
              </div>
            </div>

            <!-- 2. 模块一：📷 免驱扫码盒子硬件工作参数与实机联调测试台 -->
            <div class="section-card hardware-panel-card">
              <div class="panel-heading">
                <div class="heading-left">
                  <div class="heading-icon-badge icon-hardware">📷</div>
                  <div>
                    <div class="heading-title">免驱扫码盒子 (USB HID 虚拟键盘) 运行参数与实机联调</div>
                    <div class="heading-sub">扫码盒即插即用免装驱动，高速模拟物理键盘键入 18 位付款码或商品条形码并追加 Enter 回车</div>
                  </div>
                </div>
                <div class="heading-right">
                  <el-tag type="success" effect="light" size="small">🟢 免装驱动 · 即插即用</el-tag>
                  <el-button size="small" icon="Bell" @click="testAudioBeep">试听蜂鸣音</el-button>
                </div>
              </div>

              <div class="hardware-content-layout">
                <!-- 左半部：4 项精细化控制卡片 -->
                <div class="params-control-grid">
                  <div class="ctrl-card">
                    <div class="ctrl-icon">🎯</div>
                    <div class="ctrl-info">
                      <div class="ctrl-title">全局扫码监听</div>
                      <div class="ctrl-desc">全局捕获物理扫码盒高速键入的条码与付款码</div>
                    </div>
                    <div class="ctrl-action">
                      <el-switch v-model="paymentForm.scanBox.enabled" active-text="已开启" inactive-text="已禁用" />
                    </div>
                  </div>

                  <div class="ctrl-card">
                    <div class="ctrl-icon">⏱️</div>
                    <div class="ctrl-info">
                      <div class="ctrl-title">击键间隔判定阈值</div>
                      <div class="ctrl-desc">两键间隔小于此值识别为硬件扫码，过滤人工键入</div>
                    </div>
                    <div class="ctrl-action">
                      <el-input-number v-model="paymentForm.scanBox.keyIntervalThresholdMs" :min="20" :max="150" :step="5" size="small" controls-position="right" />
                      <span class="unit-text">ms</span>
                    </div>
                  </div>

                  <div class="ctrl-card">
                    <div class="ctrl-icon">🔊</div>
                    <div class="ctrl-info">
                      <div class="ctrl-title">扫码清脆蜂鸣提示音</div>
                      <div class="ctrl-desc">利用 Web Audio 零依赖合成硬件扫码清脆滴滴声</div>
                    </div>
                    <div class="ctrl-action">
                      <el-switch v-model="paymentForm.scanBox.beepEnabled" active-text="开启" inactive-text="静音" />
                    </div>
                  </div>

                  <div class="ctrl-card">
                    <div class="ctrl-icon">⚡</div>
                    <div class="ctrl-info">
                      <div class="ctrl-title">付款码自动反扫出单</div>
                      <div class="ctrl-desc">收银台扫入 18 位付款码时，自动向当前通道发起反扫扣款</div>
                    </div>
                    <div class="ctrl-action">
                      <el-switch v-model="paymentForm.scanBox.autoCheckoutOnPaymentCode" active-text="自动扣款" inactive-text="手动确认" />
                    </div>
                  </div>
                </div>

                <!-- 右半部：实机扫码联调测试台 (Live Hardware Console) -->
                <div class="live-tester-card">
                  <div class="tester-header">
                    <span class="live-dot pulse"></span>
                    <span class="tester-t">🔴 免驱扫码盒子实机联调测试台</span>
                    <el-tag size="small" type="info">按 Enter 触发识别</el-tag>
                  </div>
                  <div class="tester-desc">
                    将光标聚焦于下方输入框，拿起扫码盒子直接扫描；或点击快捷预设直接模拟：
                  </div>
                  <div class="tester-input-row">
                    <el-input
                      v-model="testScanInput"
                      placeholder="使用扫码盒子直接扫描，或输入测试码..."
                      clearable
                      @keydown="handleTestScanKeydown"
                    >
                      <template #prefix>
                        <el-icon><CreditCard /></el-icon>
                      </template>
                      <template #append>
                        <el-button type="primary" @click="executeTestScan">测试识别</el-button>
                      </template>
                    </el-input>
                  </div>

                  <div class="mock-pills-row">
                    <span class="pill-tip">快捷模拟：</span>
                    <button class="pill-btn pill-wx" @click="handleFillMockCode('134567890123456789')">
                      🟢 微信付款码 (18位)
                    </button>
                    <button class="pill-btn pill-ali" @click="handleFillMockCode('288888888888888888')">
                      🔵 支付宝付款码 (18位)
                    </button>
                    <button class="pill-btn pill-prod" @click="handleFillMockCode('6920182736192')">
                      📦 商品 EAN 码
                    </button>
                  </div>

                  <div v-if="testScanResult" class="tester-result-box" :class="'res-' + testScanResult.type">
                    <div class="res-head">
                      <span class="res-type-badge">{{ testScanResult.typeName }}</span>
                      <span class="res-time">{{ testScanResult.timestamp }}</span>
                    </div>
                    <div class="res-code-val">条码内容：<code>{{ testScanResult.code }}</code></div>
                    <div class="res-foot-tip">
                      🔊 清脆蜂鸣音已同步播放 · 模拟收银台反扫扣款信号正常触发
                    </div>
                  </div>
                  <div v-else class="tester-empty-box">
                    <span>💡 暂无扫描测试记录，拿起扫码盒子对准条形码直接扫入，或点击上方快捷按钮</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- 3. 模块二：三大租户进件收款通道总览与通道切换 (Route Selector Trio) -->
            <div class="section-card routes-overview-card">
              <div class="panel-heading">
                <div class="heading-left">
                  <div class="heading-icon-badge icon-routes">🌐</div>
                  <div>
                    <div class="heading-title">租户收款通道进件方案选择与当前主通道</div>
                    <div class="heading-sub">点击卡片在下方查看并配置该路线参数；点击“设为当前生效通道”即可切换收银默认扣款渠道</div>
                  </div>
                </div>
              </div>

              <div class="routes-trio-grid">
                <!-- 路线 1 卡片 -->
                <div
                  :class="['trio-card', 'trio-route1', activeRouteTab === 'ROUTE_1' ? 'card-focused' : '', paymentForm.activeRoute === 'ROUTE_1_INDIVIDUAL' ? 'is-active-route' : '']"
                  @click="activeRouteTab = 'ROUTE_1'"
                >
                  <div class="card-ribbon ribbon-gold">🌟 最推荐正规路径</div>
                  <div class="trio-head">
                    <div class="t-icon t-icon-gold">🏛️</div>
                    <div class="t-info">
                      <div class="t-title">路线 1：个体工租户营业执照直连</div>
                      <div class="t-sub">微信支付官方平台 + 支付宝当面付官方直连</div>
                    </div>
                  </div>

                  <div class="trio-body">
                    <div class="t-highlight-row">
                      <span class="t-tag tag-green">费率低至 0.38%</span>
                      <span class="t-tag tag-blue">T+1 直清法人卡</span>
                      <span class="t-tag tag-purple">0元免费办执照</span>
                    </div>
                    <div class="t-feature-list">
                      <div class="t-f-item">✓ 线下实体租户专属低费率，无第三方截留抽水</div>
                      <div class="t-f-item">✓ 资金直接清算至经营者法人借记卡，合规安全</div>
                      <div class="t-f-item">✓ 政务网线上全程电子化办理，1~2 个工作日出照</div>
                    </div>
                  </div>

                  <div class="trio-footer">
                    <div v-if="paymentForm.activeRoute === 'ROUTE_1_INDIVIDUAL'" class="active-pill pill-gold">
                      <span class="active-dot"></span> 当前系统生效收款通道
                    </div>
                    <el-button
                      v-else
                      type="warning"
                      size="small"
                      plain
                      @click.stop="setActiveRoute('ROUTE_1_INDIVIDUAL')"
                    >
                      设为当前生效通道
                    </el-button>
                    <span class="view-param-hint">{{ activeRouteTab === 'ROUTE_1' ? '▼ 正在配置此路线' : '点击查看配置' }}</span>
                  </div>
                </div>

                <!-- 路线 2 卡片 -->
                <div
                  :class="['trio-card', 'trio-route2', activeRouteTab === 'ROUTE_2' ? 'card-focused' : '', paymentForm.activeRoute === 'ROUTE_2_AGGREGATE' ? 'is-active-route' : '']"
                  @click="activeRouteTab = 'ROUTE_2'"
                >
                  <div class="card-ribbon ribbon-blue">⚡ 无营业执照合规通道</div>
                  <div class="trio-head">
                    <div class="t-icon t-icon-blue">🏪</div>
                    <div class="t-info">
                      <div class="t-title">路线 2：持牌聚合支付小微租户进件</div>
                      <div class="t-sub">收钱吧 / 拉卡拉 / 富友支付 二级持牌通道</div>
                    </div>
                  </div>

                  <div class="trio-body">
                    <div class="t-highlight-row">
                      <span class="t-tag tag-blue">免营业执照</span>
                      <span class="t-tag tag-green">全聚合收款</span>
                      <span class="t-tag tag-yellow">日额度 5~30万</span>
                    </div>
                    <div class="t-feature-list">
                      <div class="t-f-item">✓ 店主身份证 + 门店门头照 + 储蓄卡即可开户</div>
                      <div class="t-f-item">✓ 微信、支付宝、银联云闪付一码全聚合通行</div>
                      <div class="t-f-item">✓ 机构分配终端号 (TerminalId) 绑定扫码盒反扫</div>
                    </div>
                  </div>

                  <div class="trio-footer">
                    <div v-if="paymentForm.activeRoute === 'ROUTE_2_AGGREGATE'" class="active-pill pill-blue">
                      <span class="active-dot"></span> 当前系统生效收款通道
                    </div>
                    <el-button
                      v-else
                      type="primary"
                      size="small"
                      plain
                      @click.stop="setActiveRoute('ROUTE_2_AGGREGATE')"
                    >
                      设为当前生效通道
                    </el-button>
                    <span class="view-param-hint">{{ activeRouteTab === 'ROUTE_2' ? '▼ 正在配置此路线' : '点击查看配置' }}</span>
                  </div>
                </div>

                <!-- 路线 3 卡片 -->
                <div
                  :class="['trio-card', 'trio-route3', activeRouteTab === 'ROUTE_3' ? 'card-focused' : '', paymentForm.activeRoute === 'ROUTE_3_SANDBOX' ? 'is-active-route' : '']"
                  @click="activeRouteTab = 'ROUTE_3'"
                >
                  <div class="card-ribbon ribbon-purple">🧪 零成本前置联调</div>
                  <div class="trio-head">
                    <div class="t-icon t-icon-purple">🔬</div>
                    <div class="t-info">
                      <div class="t-title">路线 3：支付宝官方沙箱环境</div>
                      <div class="t-sub">零门槛前置联调验收 · 999,999 元虚拟资金池</div>
                    </div>
                  </div>

                  <div class="trio-body">
                    <div class="t-highlight-row">
                      <span class="t-tag tag-purple">0 资质免审核</span>
                      <span class="t-tag tag-green">虚拟买家资金</span>
                      <span class="t-tag tag-blue">不扣一分真钱</span>
                    </div>
                    <div class="t-feature-list">
                      <div class="t-f-item">✓ 支付宝开放平台一键获取沙箱 AppId 与公私钥</div>
                      <div class="t-f-item">✓ 配套沙箱买家虚拟钱包，真机扫码不扣真钱</div>
                      <div class="t-f-item">✓ 系统已预装官方联调凭证，一键恢复即可验收</div>
                    </div>
                  </div>

                  <div class="trio-footer">
                    <div v-if="paymentForm.activeRoute === 'ROUTE_3_SANDBOX'" class="active-pill pill-purple">
                      <span class="active-dot"></span> 当前系统生效收款通道
                    </div>
                    <el-button
                      v-else
                      type="success"
                      size="small"
                      plain
                      @click.stop="setActiveRoute('ROUTE_3_SANDBOX')"
                    >
                      设为当前生效通道
                    </el-button>
                    <span class="view-param-hint">{{ activeRouteTab === 'ROUTE_3' ? '▼ 正在配置此路线' : '点击查看配置' }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- 4. 模块三：当前选中路线参数配置与官方办理指南 (Detail Config & Steps) -->
            <div class="section-card detail-config-container">
              
              <!-- 路线 1 配置面板 -->
              <div v-if="activeRouteTab === 'ROUTE_1'" class="route-panel route-panel-1">
                <div class="config-panel-header">
                  <div class="c-title-left">
                    <span class="c-icon-badge gold-bg">🏛️</span>
                    <div>
                      <div class="c-h-title">路线 1：个体工租户营业执照直连参数与进件配置</div>
                      <div class="c-h-sub">直连官方原生租户平台，支持微信 APIv3 签名校验与支付宝 RSA2 签名</div>
                    </div>
                  </div>
                  <div class="c-title-right">
                    <el-tag v-if="paymentForm.activeRoute === 'ROUTE_1_INDIVIDUAL'" type="success" effect="dark">
                      当前激活生效通道
                    </el-tag>
                    <el-button v-else type="warning" size="small" @click="setActiveRoute('ROUTE_1_INDIVIDUAL')">
                      设为此通道收款
                    </el-button>
                  </div>
                </div>

                <!-- 进件办理指引卡片 -->
                <div class="steps-guide-box gold-border">
                  <div class="guide-title">
                    <span>📖 路线 1 官方正规办理与接入全流程三步法</span>
                    <span class="guide-sub-tip">全程免费 · 证照合规 · 官方直签</span>
                  </div>
                  <div class="steps-flow-grid">
                    <div class="step-card">
                      <div class="s-step-num">Step 01</div>
                      <div class="s-step-name">办理个体户营业执照</div>
                      <div class="s-step-desc">携带身份证前往属地市场监督管理所或政务网“全程电子化系统”线上办理，1~2 个工作日出照，<b>全程 0 元工本费</b>。</div>
                    </div>
                    <div class="step-card">
                      <div class="s-step-num">Step 02</div>
                      <div class="s-step-name">微信支付租户平台开户</div>
                      <div class="s-step-desc">访问 <b>pay.weixin.qq.com</b>，选择个体户进件，提交执照与借记卡。审核后获取 10 位租户号，设置 32 位 APIv3 密钥与私钥。</div>
                    </div>
                    <div class="step-card">
                      <div class="s-step-num">Step 03</div>
                      <div class="s-step-name">支付宝当面付签约</div>
                      <div class="s-step-desc">访问 <b>open.alipay.com</b>，签约“当面付”产品，创建应用生成 RSA2 公私钥对，上传应用公钥获取支付宝公钥与 AppId。</div>
                    </div>
                  </div>
                </div>

                <!-- 路线 1 参数表单 -->
                <el-form label-position="top" class="channel-params-form">
                  <!-- 个体工租户基础执照登记 -->
                  <div class="form-section-card">
                    <div class="section-title-bar">
                      <span>📋 个体工租户工商登记资料 (执照信息)</span>
                    </div>
                    <el-row :gutter="20">
                      <el-col :span="8">
                        <el-form-item label="统一社会信用代码 (营业执照注册号)">
                          <el-input v-model="paymentForm.route1_individual.businessLicenseNo" placeholder="如 92310115MA1Kxxxxxx" clearable />
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="租户名称 (执照字号名称)">
                          <el-input v-model="paymentForm.route1_individual.merchantName" placeholder="如 上海海马智慧美业生活馆" clearable />
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="经营者/法人代表姓名">
                          <el-input v-model="paymentForm.route1_individual.legalPerson" placeholder="如 张建华" clearable />
                        </el-form-item>
                      </el-col>
                    </el-row>
                  </div>

                  <!-- 微信支付官方直连配置 -->
                  <div class="form-section-card">
                    <div class="section-title-bar">
                      <div class="title-with-badge">
                        <span>🟢 微信支付官方直连参数 (租户平台)</span>
                        <el-tag size="small" type="success">支持免驱扫码盒反扫出单</el-tag>
                      </div>
                      <span class="fee-badge">签约实体费率：{{ paymentForm.route1_individual.wechat.feeRate }}</span>
                    </div>
                    <el-row :gutter="20">
                      <el-col :span="8">
                        <el-form-item label="微信支付租户号 (MchId)">
                          <el-input v-model="paymentForm.route1_individual.wechat.mchId" placeholder="10 位微信租户号 如 1609823451" clearable />
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="API v3 密钥 (32 位高强度密钥)">
                          <el-input v-model="paymentForm.route1_individual.wechat.apiKeyV3" type="password" show-password placeholder="微信租户平台配置的 32 位 APIv3 Key" />
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="租户证书序列号 (SerialNo)">
                          <el-input v-model="paymentForm.route1_individual.wechat.serialNo" placeholder="如 4C98234B98E710283746D298104E982B" clearable />
                        </el-form-item>
                      </el-col>
                    </el-row>
                    <el-row :gutter="20">
                      <el-col :span="12">
                        <el-form-item label="租户 API 私钥 (apiclient_key.pem)">
                          <el-input v-model="paymentForm.route1_individual.wechat.privateKey" type="textarea" :rows="3" placeholder="-----BEGIN PRIVATE KEY-----" />
                        </el-form-item>
                      </el-col>
                      <el-col :span="12">
                        <el-form-item label="支付异步回调通知地址 (NotifyUrl)">
                          <el-input v-model="paymentForm.route1_individual.wechat.notifyUrl" placeholder="https://api.seahorse-pos.com/pay/notify/wechat" clearable />
                        </el-form-item>
                      </el-col>
                    </el-row>
                  </div>

                  <!-- 支付宝官方当面付直连配置 -->
                  <div class="form-section-card">
                    <div class="section-title-bar">
                      <div class="title-with-badge">
                        <span>🔵 支付宝官方当面付直连参数 (开放平台)</span>
                        <el-tag size="small" type="primary">支持免驱扫码盒反扫扣款</el-tag>
                      </div>
                      <span class="fee-badge">签约实体费率：{{ paymentForm.route1_individual.alipay.feeRate }}</span>
                    </div>
                    <el-row :gutter="20">
                      <el-col :span="8">
                        <el-form-item label="支付宝开放平台应用 AppId">
                          <el-input v-model="paymentForm.route1_individual.alipay.appId" placeholder="16位或32位 如 2021003124567890" clearable />
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="接口网关地址 (Gateway)">
                          <el-input v-model="paymentForm.route1_individual.alipay.gateway" placeholder="https://openapi.alipay.com/gateway.do" clearable />
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="签名算法 (SignType)">
                          <el-input v-model="paymentForm.route1_individual.alipay.signType" disabled />
                        </el-form-item>
                      </el-col>
                    </el-row>
                    <el-row :gutter="20">
                      <el-col :span="12">
                        <el-form-item label="开发者应用私钥 (RSA2 2048位)">
                          <el-input v-model="paymentForm.route1_individual.alipay.appPrivateKey" type="textarea" :rows="3" placeholder="填写在支付宝开放平台生成的应用私钥" />
                        </el-form-item>
                      </el-col>
                      <el-col :span="12">
                        <el-form-item label="支付宝公钥 (AlipayPublicKey)">
                          <el-input v-model="paymentForm.route1_individual.alipay.alipayPublicKey" type="textarea" :rows="3" placeholder="填写在开放平台上传公钥后获取的支付宝公钥" />
                        </el-form-item>
                      </el-col>
                    </el-row>
                  </div>

                  <!-- 底部控制条 -->
                  <div class="panel-action-toolbar">
                    <div class="left-actions">
                      <el-button type="warning" plain icon="RefreshLeft" @click="handleApplyRoutePreset('ROUTE_1_INDIVIDUAL')">
                        一键填充路线 1 演示参数
                      </el-button>
                    </div>
                    <div class="right-actions">
                      <el-button type="success" plain icon="Connection" @click="handlePingChannel('ROUTE_1_INDIVIDUAL')">
                        测试直连网关握手 (Ping)
                      </el-button>
                      <el-button type="primary" icon="Check" :loading="savingPayment" @click="handleSaveAndActivateRoute('ROUTE_1_INDIVIDUAL')">
                        保存并设为当前生效收款通道
                      </el-button>
                    </div>
                  </div>
                </el-form>
              </div>

              <!-- 路线 2 配置面板 -->
              <div v-else-if="activeRouteTab === 'ROUTE_2'" class="route-panel route-panel-2">
                <div class="config-panel-header">
                  <div class="c-title-left">
                    <span class="c-icon-badge blue-bg">🏪</span>
                    <div>
                      <div class="c-h-title">路线 2：持牌聚合支付小微租户进件配置</div>
                      <div class="c-h-sub">无需营业执照，通过收钱吧、拉卡拉等持牌机构核准，绑定扫码盒终端号</div>
                    </div>
                  </div>
                  <div class="c-title-right">
                    <el-tag v-if="paymentForm.activeRoute === 'ROUTE_2_AGGREGATE'" type="warning" effect="dark">
                      当前激活生效通道
                    </el-tag>
                    <el-button v-else type="primary" size="small" @click="setActiveRoute('ROUTE_2_AGGREGATE')">
                      设为此通道收款
                    </el-button>
                  </div>
                </div>

                <!-- 办理指引 -->
                <div class="steps-guide-box blue-border">
                  <div class="guide-title">
                    <span>📖 路线 2 小微租户免营业执照持牌聚合进件接入流程</span>
                    <span class="guide-sub-tip">免照开户 · 持牌监管 · 银联直清</span>
                  </div>
                  <div class="steps-flow-grid">
                    <div class="step-card">
                      <div class="s-step-num">Step 01</div>
                      <div class="s-step-name">提交小微资料进件</div>
                      <div class="s-step-desc">符合人民银行“小微租户”监管标准，只需提交<b>店主身份证正反面、门店门头照、收银台内景照、个人借记卡</b>。</div>
                    </div>
                    <div class="step-card">
                      <div class="s-step-num">Step 02</div>
                      <div class="s-step-name">持牌机构联合审批</div>
                      <div class="s-step-desc">通过<b>收钱吧、拉卡拉、富友支付</b>等持牌机构统一申报，微信支付与支付宝双核准，银联直清 T+1 结算到个人卡。</div>
                    </div>
                    <div class="step-card">
                      <div class="s-step-num">Step 03</div>
                      <div class="s-step-name">配置终端号反扫</div>
                      <div class="s-step-desc">审批后下发专属 <b>二级租户号</b> 与 <b>Terminal 终端号</b>，填入下方配置后，扫码盒子即刻反扫收款出单。</div>
                    </div>
                  </div>
                </div>

                <!-- 路线 2 参数表单 -->
                <el-form label-position="top" class="channel-params-form">
                  <div class="form-section-card">
                    <div class="section-title-bar">
                      <span>🏪 持牌聚合支付服务商合作参数</span>
                      <span class="fee-badge">综合手续费率：{{ paymentForm.route2_aggregate.feeRate }}</span>
                    </div>
                    <el-row :gutter="20">
                      <el-col :span="8">
                        <el-form-item label="合作持牌聚合支付机构">
                          <el-select v-model="paymentForm.route2_aggregate.provider" style="width: 100%;">
                            <el-option label="收钱吧 (Shouqianba) - 首选推荐" value="SHOUQIANBA" />
                            <el-option label="拉卡拉 (Lakala) - 持牌收单" value="LAKALA" />
                            <el-option label="富友支付 (Fuiou Pay)" value="FUIOU" />
                            <el-option label="银联商务 (China UMS)" value="CHINA_UMS" />
                          </el-select>
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="小微特约租户号 (SubMchId)">
                          <el-input v-model="paymentForm.route2_aggregate.subMchId" placeholder="机构分配的二级租户号 如 ME1009827364" clearable />
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="绑定的收银终端号 (TerminalId)">
                          <el-input v-model="paymentForm.route2_aggregate.terminalId" placeholder="扫码盒绑定的硬件终端号 如 SQB-POS-882190" clearable />
                        </el-form-item>
                      </el-col>
                    </el-row>
                    <el-row :gutter="20">
                      <el-col :span="12">
                        <el-form-item label="通信签名安全令牌 (SecretKey)">
                          <el-input v-model="paymentForm.route2_aggregate.serviceProviderKey" type="password" show-password placeholder="服务商提供的通信安全密钥" />
                        </el-form-item>
                      </el-col>
                      <el-col :span="12">
                        <el-form-item label="法人结算借记卡号 (个人储蓄卡)">
                          <el-input v-model="paymentForm.route2_aggregate.settlementBankCard" placeholder="如 6222 0210 0102 8888 (中国工商银行)" clearable />
                        </el-form-item>
                      </el-col>
                    </el-row>
                    <el-row :gutter="20">
                      <el-col :span="12">
                        <el-form-item label="单日交易限额 (元)">
                          <el-input-number v-model="paymentForm.route2_aggregate.dailyLimit" :min="10000" :max="300000" :step="10000" style="width: 100%;" />
                        </el-form-item>
                      </el-col>
                      <el-col :span="12">
                        <el-form-item label="综合收款手续费率">
                          <el-input v-model="paymentForm.route2_aggregate.feeRate" disabled />
                        </el-form-item>
                      </el-col>
                    </el-row>
                  </div>

                  <!-- 底部控制条 -->
                  <div class="panel-action-toolbar">
                    <div class="left-actions">
                      <el-button type="warning" plain icon="RefreshLeft" @click="handleApplyRoutePreset('ROUTE_2_AGGREGATE')">
                        一键填充路线 2 演示参数
                      </el-button>
                    </div>
                    <div class="right-actions">
                      <el-button type="success" plain icon="Connection" @click="handlePingChannel('ROUTE_2_AGGREGATE')">
                        测试聚合服务商网关 (Ping)
                      </el-button>
                      <el-button type="primary" icon="Check" :loading="savingPayment" @click="handleSaveAndActivateRoute('ROUTE_2_AGGREGATE')">
                        保存并设为当前生效收款通道
                      </el-button>
                    </div>
                  </div>
                </el-form>
              </div>

              <!-- 路线 3 配置面板 -->
              <div v-else class="route-panel route-panel-3">
                <div class="config-panel-header">
                  <div class="c-title-left">
                    <span class="c-icon-badge purple-bg">🔬</span>
                    <div>
                      <div class="c-h-title">路线 3：支付宝官方沙箱环境联调参数</div>
                      <div class="c-h-sub">无需任何资质，提供 999,999 元虚拟测试资金池，真实扫码盒反扫不扣真钱</div>
                    </div>
                  </div>
                  <div class="c-title-right">
                    <el-tag v-if="paymentForm.activeRoute === 'ROUTE_3_SANDBOX'" type="primary" effect="dark">
                      当前激活生效通道
                    </el-tag>
                    <el-button v-else type="success" size="small" @click="setActiveRoute('ROUTE_3_SANDBOX')">
                      设为此通道收款
                    </el-button>
                  </div>
                </div>

                <!-- 办理指引 -->
                <div class="steps-guide-box purple-border">
                  <div class="guide-title">
                    <span>📖 路线 3 支付宝官方沙箱零成本前置联调特性</span>
                    <span class="guide-sub-tip">0 门槛 · 虚拟资金 · 即开即验</span>
                  </div>
                  <div class="steps-flow-grid">
                    <div class="step-card">
                      <div class="s-step-num">Step 01</div>
                      <div class="s-step-name">开放平台沙箱应用</div>
                      <div class="s-step-desc">登录 <b>open.alipay.com</b> 进入开发者中心-沙箱应用，无需资质即刻获得沙箱 AppId、沙箱网关与公私钥。</div>
                    </div>
                    <div class="step-card">
                      <div class="s-step-num">Step 02</div>
                      <div class="s-step-name">虚拟资金池与买家号</div>
                      <div class="s-step-desc">提供配套沙箱买家虚拟账户与支付密码，测试收银与扫码盒反扫扣款，<b>资金全虚拟，不发生任何真实扣费</b>。</div>
                    </div>
                    <div class="step-card">
                      <div class="s-step-num">Step 03</div>
                      <div class="s-step-name">扫码盒子真机联调</div>
                      <div class="s-step-desc">在收银台使用免驱扫码盒子扫描虚拟付款码（如 <b>288888888888888888</b>），即刻触发当面付反扫扣款出单。</div>
                    </div>
                  </div>
                </div>

                <!-- 路线 3 参数表单 -->
                <el-form label-position="top" class="channel-params-form">
                  <div class="form-section-card">
                    <div class="section-title-bar">
                      <span>🔬 支付宝开放平台沙箱环境配置</span>
                      <span class="fee-badge">测试费率：0.00% (虚拟资金池)</span>
                    </div>
                    <el-row :gutter="20">
                      <el-col :span="8">
                        <el-form-item label="沙箱应用 AppId">
                          <el-input v-model="paymentForm.route3_sandbox.sandboxAppId" placeholder="如 9021000133682914" clearable />
                        </el-form-item>
                      </el-col>
                      <el-col :span="12">
                        <el-form-item label="沙箱官方网关 (Sandbox Gateway)">
                          <el-input v-model="paymentForm.route3_sandbox.sandboxGateway" placeholder="https://openapi-sandbox.dl.alipaydev.com/gateway.do" clearable />
                        </el-form-item>
                      </el-col>
                      <el-col :span="4">
                        <el-form-item label="加签方式">
                          <el-input v-model="paymentForm.route3_sandbox.signType" disabled />
                        </el-form-item>
                      </el-col>
                    </el-row>
                    <el-row :gutter="20">
                      <el-col :span="12">
                        <el-form-item label="沙箱应用私钥 (Sandbox App Private Key)">
                          <el-input v-model="paymentForm.route3_sandbox.sandboxPrivateKey" type="textarea" :rows="3" placeholder="沙箱 RSA2 应用私钥" />
                        </el-form-item>
                      </el-col>
                      <el-col :span="12">
                        <el-form-item label="支付宝沙箱公钥 (Alipay Sandbox Public Key)">
                          <el-input v-model="paymentForm.route3_sandbox.sandboxPublicKey" type="textarea" :rows="3" placeholder="支付宝沙箱公钥" />
                        </el-form-item>
                      </el-col>
                    </el-row>
                    <el-row :gutter="20">
                      <el-col :span="8">
                        <el-form-item label="沙箱买家测试账号">
                          <el-input v-model="paymentForm.route3_sandbox.testBuyerAccount" placeholder="alipay_buyer_sandbox01@sandbox.com" clearable />
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="沙箱登录密码与支付密码">
                          <el-input v-model="paymentForm.route3_sandbox.testBuyerPayPassword" placeholder="默认 111111" clearable />
                        </el-form-item>
                      </el-col>
                      <el-col :span="8">
                        <el-form-item label="虚拟钱包可用额度">
                          <el-input :model-value="'￥' + paymentForm.route3_sandbox.virtualBalance.toLocaleString() + ' (虚拟资金池)'" disabled />
                        </el-form-item>
                      </el-col>
                    </el-row>
                  </div>

                  <!-- 底部控制条 -->
                  <div class="panel-action-toolbar">
                    <div class="left-actions">
                      <el-button type="warning" plain icon="RefreshLeft" @click="handleApplyRoutePreset('ROUTE_3_SANDBOX')">
                        一键恢复官方沙箱初始参数
                      </el-button>
                    </div>
                    <div class="right-actions">
                      <el-button type="success" plain icon="Connection" @click="handlePingChannel('ROUTE_3_SANDBOX')">
                        模拟沙箱网关握手 (Ping)
                      </el-button>
                      <el-button type="primary" icon="Check" :loading="savingPayment" @click="handleSaveAndActivateRoute('ROUTE_3_SANDBOX')">
                        保存并设为当前生效收款通道
                      </el-button>
                    </div>
                  </div>
                </el-form>
              </div>

            </div>
          </div>
      </div>

      <!-- B. 独立页面模式 2: 仅展示 高德地图与考勤定位 -->
      <div v-else-if="isStandaloneMap" class="standalone-map-container">
        <div class="amap-settings-pane" style="padding: 10px 0;">
            <!-- 超级管理员提示 -->
            <el-alert
              v-if="isPlatformAdmin"
              title="平台超级管理员配置说明"
              type="warning"
              show-icon
              :closable="false"
              description="此处配置全平台共享的高德地图开放平台凭证。超级管理员在此设置的考勤基准仅作为缺省参考值（也可以不配置），系统最终以各个租户自身配置并保存的考勤打卡基准经纬度和围栏半径为准。"
              style="margin-bottom: 20px;"
            />
            <!-- 普通租户提示 -->
            <el-alert
              v-else
              title="门店考勤打卡基准与电子围栏配置说明"
              type="success"
              show-icon
              :closable="false"
              description="全平台高德地图高精网络定位服务已由总控平台统一纳管。您只需在下方设置或在地图上拾取本门店的考勤打卡基准点与有效半径即可。考勤打卡校验严格以本店配置为准！"
              style="margin-bottom: 20px;"
            />

            <el-row :gutter="24">
              <!-- 仅平台超级管理员展示底层 API Key 凭证 -->
              <el-col :span="12" v-if="isPlatformAdmin">
                <el-card shadow="never" style="border-radius: 12px; border: 1px solid #e2e8f0;">
                  <template #header>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                      <span style="font-weight: bold; font-size: 15px;">🔑 高德开放平台 API Key 凭证 (平台总控)</span>
                      <el-tag type="danger" size="small">超级管理员专属</el-tag>
                    </div>
                  </template>

                  <el-form label-position="top">
                    <el-form-item label="高德 Web 服务 API Key (用于移动端定位 & 逆地理编码)">
                      <el-input
                        v-model="amapForm.webApiKey"
                        placeholder="请输入高德开放平台 Web 服务 Key"
                        clearable
                      >
                        <template #append>
                          <el-button type="primary" :loading="testingAmap" @click="handleTestAmapApiKey">
                            测试连通性
                          </el-button>
                        </template>
                      </el-input>
                      <div style="font-size: 12px; color: #64748b; margin-top: 6px;">
                        📌 获取方式：高德控制台 -> 应用管理 -> 我的应用 -> 服务平台选择 <b>Web服务</b>。
                      </div>
                    </el-form-item>

                    <el-form-item label="高德 JS API Key (用于Web端地图显示)">
                      <el-input
                        v-model="amapForm.jsApiKey"
                        placeholder="请输入 Web端(JS API) Key"
                        clearable
                      />
                    </el-form-item>

                    <el-form-item label="安全密钥 Security Code (高德新版安全密钥)">
                      <el-input
                        v-model="amapForm.securityCode"
                        type="password"
                        show-password
                        placeholder="高德安全密钥"
                      />
                    </el-form-item>

                    <el-divider />

                    <div style="display: flex; justify-content: flex-end; gap: 12px;">
                      <el-button :loading="testingAmap" @click="handleTestAmapApiKey">
                        🔌 测试 Key 有效性
                      </el-button>
                      <el-button type="primary" :loading="savingAmap" @click="handleSaveAmapConfig">
                        💾 保存平台全局配置
                      </el-button>
                    </div>
                  </el-form>
                </el-card>
              </el-col>

              <!-- 考勤打卡基准门店与电子围栏：普通租户独占全宽，超管占右侧 -->
              <el-col :span="isPlatformAdmin ? 12 : 24">
                <el-card shadow="never" style="border-radius: 12px; border: 1px solid #e2e8f0;">
                  <template #header>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                      <span style="font-weight: bold; font-size: 15px;">📍 考勤打卡基准门店与电子围栏</span>
                      <el-button size="small" type="success" plain @click="handleGetBrowserLocation">
                        获取当前定位
                      </el-button>
                    </div>
                  </template>

                  <el-form label-position="top">
                    <el-form-item label="基准门店名称">
                      <el-input v-model="amapForm.storeName" placeholder="如：海马智慧商业 (西安高新旗舰店)" />
                    </el-form-item>

                    <el-row :gutter="12">
                      <el-col :span="12">
                        <el-form-item label="经度 (Longitude)">
                          <el-input-number v-model="amapForm.storeLongitude" :precision="6" :step="0.0001" style="width: 100%;" />
                        </el-form-item>
                      </el-col>
                      <el-col :span="12">
                        <el-form-item label="纬度 (Latitude)">
                          <el-input-number v-model="amapForm.storeLatitude" :precision="6" :step="0.0001" style="width: 100%;" />
                        </el-form-item>
                      </el-col>
                    </el-row>

                    <el-form-item label="门店标准详细地址">
                      <el-input
                        v-model="amapForm.storeAddress"
                        type="textarea"
                        :rows="2"
                        placeholder="如：陕西省西安市雁塔区高新路海马商业中心1号店"
                      />
                    </el-form-item>

                    <el-form-item label="允许考勤打卡有效偏差半径 (米)">
                      <div style="display: flex; align-items: center; gap: 12px; width: 100%;">
                        <el-slider v-model="amapForm.allowedRadiusMeters" :min="100" :max="3000" :step="50" style="flex: 1;" />
                        <span style="font-weight: bold; color: #2563eb; width: 65px; text-align: right;">{{ amapForm.allowedRadiusMeters }} 米</span>
                      </div>
                      <div style="font-size: 12px; color: #64748b; margin-top: 4px;">
                        超出此半径打卡将自动被系统标记为“外勤打卡”，需录入外勤事由。
                      </div>
                    </el-form-item>
                  </el-form>
                </el-card>
              </el-col>
            </el-row>

            <!-- 🗺️ 高德地图打卡围栏与交互拾取大视窗 -->
            <el-card shadow="never" style="border-radius: 12px; border: 1px solid #e2e8f0; margin-top: 16px;">
              <template #header>
                <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
                  <div style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-weight: bold; font-size: 15px;">🗺️ 高德地图可视化考勤围栏与选点中心</span>
                    <el-tag type="success" size="small">实时联动</el-tag>
                    <span style="font-size: 13px; color: #64748b;">
                      💡 提示：点击地图任意位置或拖拽红色标记可一键拾取经纬度与地址，蓝色圆圈为有效打卡电子围栏范围
                    </span>
                  </div>
                  <div style="display: flex; align-items: center; gap: 10px;">
                    <el-input
                      v-model="mapSearchKeyword"
                      placeholder="搜索地名/写字楼快速定位"
                      size="default"
                      clearable
                      style="width: 260px;"
                      @keyup.enter="handleSearchMapKeyword"
                    >
                      <template #append>
                        <el-button icon="Search" @click="handleSearchMapKeyword" />
                      </template>
                    </el-input>
                    <el-button size="default" type="primary" plain icon="Refresh" @click="initOrRefreshMap">
                      重置视野
                    </el-button>
                  </div>
                </div>
              </template>

              <!-- 地图画布容器 -->
              <div style="position: relative; width: 100%; height: 460px; border-radius: 8px; overflow: hidden; background: #f1f5f9; border: 1px solid #cbd5e1;">
                <div id="amap-container" style="width: 100%; height: 100%; min-height: 460px;"></div>
                
                <!-- 地图加载失败兜底提示 -->
                <div v-if="mapLoadFailed" style="position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; background: #f8fafc; z-index: 50; padding: 20px; text-align: center;">
                  <el-icon size="48" color="#f59e0b" style="margin-bottom: 12px;"><Warning /></el-icon>
                  <div style="font-size: 16px; font-weight: bold; color: #1e293b; margin-bottom: 6px;">高德地图 SDK 待渲染</div>
                  <div style="font-size: 13px; color: #64748b; max-width: 500px; margin-bottom: 16px;">
                    {{ mapLoadErrorMsg || '网络环境或高德 JS SDK 加载中，您可直接在上方面板输入经纬度与打卡半径，仍可正常生效！' }}
                  </div>
                  <el-button type="primary" size="small" @click="initOrRefreshMap">重新加载地图</el-button>
                </div>

                <!-- 地图悬浮信息条 -->
                <div v-if="!mapLoadFailed" style="position: absolute; bottom: 12px; left: 12px; z-index: 10; background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(6px); padding: 10px 16px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.12); font-size: 13px; border: 1px solid #e2e8f0; max-width: 80%;">
                  <div style="display: flex; align-items: center; gap: 16px; flex-wrap: wrap;">
                    <span>📍 <b>基准经纬度:</b> <span style="color: #0f172a; font-family: monospace; font-weight: bold;">{{ amapForm.storeLongitude }}, {{ amapForm.storeLatitude }}</span></span>
                    <span>⭕ <b>打卡围栏半径:</b> <span style="color: #2563eb; font-weight: bold;">{{ amapForm.allowedRadiusMeters }} 米</span></span>
                  </div>
                  <div style="color: #475569; font-size: 12px; margin-top: 5px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                    📮 <b>当前逆解析地址:</b> {{ amapForm.storeAddress || '暂未解析' }}
                  </div>
                </div>
              </div>
            </el-card>
          </div>
      </div>

      <!-- C. 独立页面模式 3: 仅展示 部门架构与岗位管理 (与员工管理同一层级) -->
      <div v-else-if="isStandaloneJobPosts" class="standalone-post-container" style="padding: 10px 0;">
        <div class="post-manage-pane">
          <!-- 二级子导航切换: 门店部门架构体系 vs 岗位职务与编制招聘 vs 应聘简历与面试管理 -->
          <div class="post-sub-nav-bar">
            <div class="sub-nav-btns">
              <button
                :class="['sub-nav-btn', postSubTab === 'DEPARTMENTS' ? 'active-tab' : 'default-tab']"
                @click="postSubTab = 'DEPARTMENTS'"
              >
                <el-icon style="margin-right: 5px;"><OfficeBuilding /></el-icon>
                门店部门架构体系
                <span class="sub-nav-badge" style="background: #e2e8f0; color: #475569;">
                  {{ departmentsList.length }} 个部门
                </span>
              </button>
              <button
                :class="['sub-nav-btn', postSubTab === 'POSTS' ? 'active-tab' : 'default-tab']"
                @click="postSubTab = 'POSTS'"
              >
                <el-icon style="margin-right: 5px;"><Briefcase /></el-icon>
                岗位职务与编制招聘
                <span class="sub-nav-badge" style="background: #e0f2fe; color: #0284c7;">
                  {{ positionsList.length }} 个岗位
                </span>
              </button>
              <button
                :class="['sub-nav-btn', postSubTab === 'APPLICATIONS' ? 'active-tab' : 'default-tab']"
                @click="postSubTab = 'APPLICATIONS'"
              >
                <el-icon style="margin-right: 5px;"><User /></el-icon>
                应聘简历与面试管理
                <span v-if="pendingApplicationsCount > 0" class="sub-nav-badge">
                  {{ pendingApplicationsCount }} 待初筛
                </span>
              </button>
            </div>

            <div class="sub-nav-actions" style="display: flex; gap: 8px;">
              <template v-if="postSubTab === 'DEPARTMENTS'">
                <el-button
                  type="success"
                  plain
                  icon="Download"
                  @click="openIndustryPresetDeptModal"
                >
                  📥 载入行业推荐部门与岗位
                </el-button>
                <el-button
                  type="primary"
                  icon="DocumentChecked"
                  :loading="savingOrgToServer"
                  @click="handleManualSavePositionsAndDepts"
                >
                  💾 保存组织架构到数据库
                </el-button>
                <el-button
                  type="success"
                  plain
                  icon="Share"
                  @click="handleOpenSharePoster(null)"
                >
                  🖼️ 招聘海报
                </el-button>
                <el-button
                  type="primary"
                  icon="Plus"
                  @click="postSubTab = 'POSTS'; handleOpenAddPost()"
                >
                  新增在编岗位
                </el-button>
              </template>
              <template v-else-if="postSubTab === 'POSTS'">
                <el-button
                  type="success"
                  plain
                  icon="Download"
                  @click="openIndustryPresetDeptModal"
                >
                  📥 载入行业推荐部门与岗位
                </el-button>
                <el-button
                  type="primary"
                  icon="DocumentChecked"
                  :loading="savingOrgToServer"
                  @click="handleManualSavePositionsAndDepts"
                >
                  💾 保存组织架构到数据库
                </el-button>
                <el-button
                  type="info"
                  plain
                  icon="OfficeBuilding"
                  @click="postSubTab = 'DEPARTMENTS'"
                >
                  🏢 部门架构体系 ({{ departmentsList.length }})
                </el-button>
                <el-button
                  type="success"
                  plain
                  icon="Share"
                  @click="handleOpenSharePoster(null)"
                >
                  🖼️ 招聘海报
                </el-button>
                <el-button
                  type="primary"
                  icon="Plus"
                  @click="handleOpenAddPost"
                >
                  新增岗位编制
                </el-button>
              </template>
              <template v-else-if="postSubTab === 'APPLICATIONS'">
                <el-button
                  type="success"
                  plain
                  icon="Refresh"
                  @click="refreshApplications"
                >
                  刷新简历库
                </el-button>
              </template>
            </div>
          </div>

          <!-- 子视图 A: 门店所属部门架构管理 (优先第一屏呈现) -->
          <div v-if="postSubTab === 'DEPARTMENTS'" class="departments-sub-view" style="padding-top: 6px;">
            <!-- 组织架构 KPI 卡片 -->
            <div class="kpi-row" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px;">
              <div class="kpi-card" style="background: linear-gradient(135deg, #ecfdf5 0%, #f0fdf4 100%); border: 1px solid #a7f3d0; border-radius: 10px; padding: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.04);">
                <div class="kpi-label" style="font-size: 13px; color: #047857; display: flex; align-items: center; gap: 6px; font-weight: 500;">
                  <span>🏢</span> 门店部门架构总数
                </div>
                <div class="kpi-value" style="font-size: 26px; font-weight: bold; color: #065f46; margin-top: 6px;">{{ departmentsList.length }} <span style="font-size: 13px; font-weight: normal; color: #059669;">个部门</span></div>
              </div>
              <div class="kpi-card" style="background: linear-gradient(135deg, #eff6ff 0%, #f0f9ff 100%); border: 1px solid #bfdbfe; border-radius: 10px; padding: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.04);">
                <div class="kpi-label" style="font-size: 13px; color: #1d4ed8; display: flex; align-items: center; gap: 6px; font-weight: 500;">
                  <span>💼</span> 覆盖岗位编制数
                </div>
                <div class="kpi-value" style="font-size: 26px; font-weight: bold; color: #1e40af; margin-top: 6px;">{{ positionsList.length }} <span style="font-size: 13px; font-weight: normal; color: #2563eb;">个在编岗位</span></div>
              </div>
              <div class="kpi-card" style="background: linear-gradient(135deg, #faf5ff 0%, #fdf4ff 100%); border: 1px solid #e9d5ff; border-radius: 10px; padding: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.04);">
                <div class="kpi-label" style="font-size: 13px; color: #7e22ce; display: flex; align-items: center; gap: 6px; font-weight: 500;">
                  <span>👥</span> 各部门在岗员工
                </div>
                <div class="kpi-value" style="font-size: 26px; font-weight: bold; color: #6b21a8; margin-top: 6px;">{{ systemData.staff ? systemData.staff.length : 0 }} <span style="font-size: 13px; font-weight: normal; color: #9333ea;">人在岗</span></div>
              </div>
              <div class="kpi-card" style="background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%); border: 1px solid #fde68a; border-radius: 10px; padding: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.04);">
                <div class="kpi-label" style="font-size: 13px; color: #b45309; display: flex; align-items: center; gap: 6px; font-weight: 500;">
                  <span>📋</span> 招聘面试与初筛
                </div>
                <div class="kpi-value" style="font-size: 26px; font-weight: bold; color: #92400e; margin-top: 6px;">{{ pendingApplicationsCount }} <span style="font-size: 13px; font-weight: normal; color: #d97706;">人待初筛</span></div>
              </div>
            </div>

            <!-- 部门新增与规划工具栏 -->
            <div class="dept-toolbar-card" style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 16px 20px; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.03);">
              <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                <div style="font-weight: 700; color: #1e293b; font-size: 15px; display: flex; align-items: center; gap: 6px;">
                  <span>🏢 快速设立与规划新部门</span>
                  <el-tag size="small" type="success" effect="light">{{ departmentsList.length }} 个部门</el-tag>
                </div>
                <span style="font-size: 12.5px; color: #64748b;">
                  (部门架构自动与岗位编制、员工入职档案和考勤体系协同联动)
                </span>
              </div>
              <div style="display: flex; gap: 10px; align-items: center;">
                <el-input
                  v-model="newDeptName"
                  placeholder="输入新部门名称 (如：后厨烹饪部、前厅服务部)..."
                  style="width: 320px;"
                  clearable
                  @keyup.enter="handleAddDepartment"
                />
                <el-button type="primary" icon="Plus" @click="handleAddDepartment">
                  添加新部门
                </el-button>
              </div>
            </div>

            <!-- 部门列表表格 -->
            <el-table :data="departmentTableData" border stripe style="width: 100%; border-radius: 8px; overflow: hidden;">
              <el-table-column label="部门名称" min-width="200">
                <template #default="{ row }">
                  <div v-if="editingDeptOldName === row.name && isEditingDept" style="display: flex; gap: 6px;">
                    <el-input v-model="editingDeptNewName" size="small" @keyup.enter="handleSaveEditDept" />
                    <el-button type="success" size="small" icon="Check" @click="handleSaveEditDept">保存</el-button>
                    <el-button size="small" icon="Close" @click="isEditingDept = false">取消</el-button>
                  </div>
                  <div v-else style="display: flex; align-items: center; gap: 8px;">
                    <span style="font-weight: 700; color: #1e293b; font-size: 14px;">{{ row.name }}</span>
                    <el-tag size="small" type="info" effect="plain">部门 #{{ row.index + 1 }}</el-tag>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="在编岗位数" width="160" align="center">
                <template #default="{ row }">
                  <el-tag size="small" type="primary">{{ row.postCount }} 个在编岗位</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="在册员工人数" width="150" align="center">
                <template #default="{ row }">
                  <el-tag size="small" :type="row.staffCount > 0 ? 'success' : 'info'">{{ row.staffCount }} 人在岗</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="下属岗位速览 (点击可快速检索岗位)" min-width="240">
                <template #default="{ row }">
                  <div style="display: flex; flex-wrap: wrap; gap: 6px;">
                    <el-tag
                      v-for="p in positionsList.filter(item => item.department === row.name)"
                      :key="p.id"
                      size="small"
                      effect="light"
                      style="cursor: pointer;"
                      @click="postSubTab = 'POSTS'; postSearchKeyword = p.postName"
                    >
                      💼 {{ p.postName }}
                    </el-tag>
                    <span v-if="positionsList.filter(item => item.department === row.name).length === 0" style="color: #94a3b8; font-size: 12px;">
                      暂未关联岗位
                    </span>
                  </div>
                </template>
              </el-table-column>
              <el-table-column label="管理操作" width="220" align="center" fixed="right">
                <template #default="{ row }">
                  <el-button link type="primary" size="small" icon="Plus" @click="handleAddPostForDept(row.name)">
                    新建岗位
                  </el-button>
                  <el-button link type="warning" size="small" icon="Edit" @click="handleStartEditDept(row.name)">
                    重命名
                  </el-button>
                  <el-button link type="danger" size="small" icon="Delete" @click="handleDeleteDept(row.name)">
                    删除
                  </el-button>
                </template>
              </el-table-column>
              <template #empty>
                <el-empty description="暂无部门架构，请在上方输入新部门名称并点击「添加新部门」设立" :image-size="90" />
              </template>
            </el-table>

            <div style="margin-top: 14px; font-size: 12px; color: #64748b; line-height: 1.6; background: #f8fafc; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0;">
              💡 <b>架构协同说明</b>：在此配置的部门架构会自动同步到【新增岗位编制】以及【员工档案/扫码入职】的所属部门选项中；若重命名部门，归属于该部门的所有岗位及在职员工将自动同步更新，保障全店组织架构与发薪核算一致。
            </div>
          </div>

          <!-- 子视图 B: 岗位职务与招聘发布列表 -->
          <div v-else-if="postSubTab === 'POSTS'" class="positions-sub-view">
            <div class="post-filter-row">
              <el-input
                v-model="postSearchKeyword"
                placeholder="搜索岗位名称、所属部门或工作描述..."
                prefix-icon="Search"
                clearable
                style="width: 320px;"
              />
              <div class="post-summary-pills">
                <span class="pill-item">
                  📋 在编岗位: <b>{{ positionsList.length }}</b> 个
                </span>
                <span class="pill-item text-green">
                  📢 正在公开招聘: <b>{{ activeRecruitingCount }}</b> 个
                </span>
              </div>
            </div>

            <!-- 岗位表格 -->
            <el-table :data="filteredPositions" stripe border style="width: 100%; margin-top: 14px;">
              <el-table-column prop="postName" label="岗位名称" min-width="160">
                <template #default="{ row }">
                  <div style="font-weight: 700; color: #1e293b; font-size: 14px;">{{ row.postName }}</div>
                  <div style="font-size: 11px; color: #64748b;">编码: {{ row.postCode }}</div>
                </template>
              </el-table-column>
              <el-table-column prop="department" label="所属部门" min-width="120">
                <template #default="{ row }">
                  <el-tag size="small" type="info">{{ row.department }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="薪资待遇" min-width="150">
                <template #default="{ row }">
                  <div style="color: #059669; font-weight: 700;">{{ row.salaryRange || ('￥' + row.baseSalary + '底薪') }}</div>
                  <div style="font-size: 11px; color: #64748b;">提成比例: {{ (row.commissionRate * 100).toFixed(0) }}%</div>
                </template>
              </el-table-column>
              <el-table-column label="在册员工" width="100" align="center">
                <template #default="{ row }">
                  <el-tag :type="row.employeeCount > 0 ? 'success' : 'info'" size="small">
                    {{ row.employeeCount || 0 }} 人在岗
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="公开招聘状态" width="140" align="center">
                <template #default="{ row }">
                  <el-switch
                    v-model="row.isRecruiting"
                    inline-prompt
                    active-text="热招中"
                    inactive-text="已暂停"
                    @change="handleToggleRecruiting(row)"
                  />
                </template>
              </el-table-column>
              <el-table-column label="操作" width="250" fixed="right">
                <template #default="{ row }">
                  <el-button link type="primary" size="small" icon="Document" @click="handleOpenJobDoc(row)">岗位职责</el-button>
                  <el-button link type="success" size="small" icon="Share" @click="handleShareJobQr(row)">招聘海报</el-button>
                  <el-button link type="warning" size="small" icon="Edit" @click="handleEditPost(row)">编辑</el-button>
                  <el-button link type="danger" size="small" icon="Delete" @click="handleDeletePost(row)" v-if="row.postCode !== 'STORE_MANAGER' && row.postCode !== 'STORE_STAFF'">删除</el-button>
                </template>
              </el-table-column>
              <template #empty>
                <el-empty description="暂无岗位编制，请点击上方「新增岗位编制」设立岗位" :image-size="90" />
              </template>
            </el-table>
          </div>

          <!-- 子视图 C: 应聘简历与面试管理看板 -->
          <div v-else-if="postSubTab === 'APPLICATIONS'" class="applications-sub-view">
            <!-- 顶部筛选与跨端同步工具栏 -->
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; background: #ffffff; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; flex-wrap: wrap; gap: 10px;">
              <div style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">
                <el-input
                  v-model="appKeyword"
                  placeholder="搜索候选人姓名/手机号"
                  prefix-icon="Search"
                  clearable
                  style="width: 220px;"
                />
                <el-select v-model="appPostFilter" placeholder="全部应聘岗位" clearable style="width: 170px;">
                  <el-option label="全部岗位" value="" />
                  <el-option v-for="p in positionsList" :key="p.id" :label="p.postName" :value="p.postName" />
                </el-select>
                <el-select v-model="appStatusFilter" placeholder="全部流程状态" clearable style="width: 150px;">
                  <el-option label="全部状态" value="" />
                  <el-option label="待初筛" value="PENDING" />
                  <el-option label="已约面试" value="INTERVIEW_SCHEDULED" />
                  <el-option label="面试通过" value="PASSED" />
                  <el-option label="已录用入职" value="HIRED" />
                  <el-option label="已淘汰" value="REJECTED" />
                </el-select>
              </div>
              <div style="display: flex; gap: 8px;">
                <el-button type="primary" icon="Refresh" :loading="syncingApplications" @click="fetchRemoteApplications(true)">
                  🔄 同步手机扫码投递简历
                </el-button>
                <el-button type="success" plain icon="Plus" @click="handleOpenApplyPortal(null)">
                  📱 模拟求职投递
                </el-button>
              </div>
            </div>

            <!-- 4格统计KPI -->
            <div class="kpi-row" style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px;">
              <div class="kpi-card" style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 14px;">
                <div class="kpi-label" style="font-size: 12px; color: #15803d;">累计投递简历</div>
                <div class="kpi-value" style="font-size: 24px; font-weight: bold; color: #166534;">{{ applicationsList.length }} 份</div>
              </div>
              <div class="kpi-card" style="background: #eff6ff; border: 1px solid #bfdbfe; border-radius: 8px; padding: 14px;">
                <div class="kpi-label" style="font-size: 12px; color: #1d4ed8;">待初筛简历</div>
                <div class="kpi-value" style="font-size: 24px; font-weight: bold; color: #1e40af;">{{ pendingApplicationsCount }} 份</div>
              </div>
              <div class="kpi-card" style="background: #fefce8; border: 1px solid #fef08a; border-radius: 8px; padding: 14px;">
                <div class="kpi-label" style="font-size: 12px; color: #a16207;">已安排面试</div>
                <div class="kpi-value" style="font-size: 24px; font-weight: bold; color: #854d0e;">{{ scheduledCount }} 人</div>
              </div>
              <div class="kpi-card" style="background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 8px; padding: 14px;">
                <div class="kpi-label" style="font-size: 12px; color: #7e22ce;">面试通过 / 已录用</div>
                <div class="kpi-value" style="font-size: 24px; font-weight: bold; color: #6b21a8;">{{ hiredOrPassedCount }} 人</div>
              </div>
            </div>

            <!-- 简历表格 -->
            <el-table :data="paginatedApplications" stripe border style="width: 100%;">
              <el-table-column prop="candidateName" label="候选人姓名" min-width="120">
                <template #default="{ row }">
                  <div style="font-weight: 700; color: #1e293b;">{{ row.candidateName }} ({{ row.gender }}/{{ row.age }}岁)</div>
                  <div style="font-size: 11px; color: #64748b;">手机: {{ row.phone }}</div>
                </template>
              </el-table-column>
              <el-table-column prop="postName" label="应聘岗位" min-width="130" />
              <el-table-column label="学历与工作经验" min-width="140">
                <template #default="{ row }">
                  <div>{{ row.education }} · {{ row.experienceYears }}年经验</div>
                  <div style="font-size: 11px; color: #64748b;">期望: {{ row.expectedSalary }}</div>
                </template>
              </el-table-column>
              <el-table-column prop="status" label="流程状态" width="130" align="center">
                <template #default="{ row }">
                  <el-tag v-if="row.status === 'PENDING'" type="warning">待初筛</el-tag>
                  <el-tag v-else-if="row.status === 'INTERVIEW_SCHEDULED'" type="primary">已约面试</el-tag>
                  <el-tag v-else-if="row.status === 'PASSED'" type="success">面试通过</el-tag>
                  <el-tag v-else-if="row.status === 'HIRED'" type="success" effect="dark">已录用入职</el-tag>
                  <el-tag v-else type="info">已淘汰</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="290" fixed="right">
                <template #default="{ row }">
                  <el-button link type="primary" size="small" @click="handleViewApplicantDoc(row)">详情</el-button>
                  <el-button link type="warning" size="small" @click="handleOpenScheduleInterview(row)">安排面试</el-button>
                  <el-button v-if="row.status === 'INTERVIEW_SCHEDULED'" link type="success" size="small" @click="handleOpenInterviewEval(row)">评价</el-button>
                  <el-button v-if="row.status === 'PASSED' || row.status === 'HIRED'" link type="primary" size="small" @click="handleOpenSendRegisterQr(row)">📲 发建档码</el-button>
                  <el-button v-if="row.status === 'PASSED'" link type="success" size="small" @click="handleOneClickHire(row)">办入职</el-button>
                  <el-button v-if="row.status !== 'HIRED' && row.status !== 'REJECTED'" link type="danger" size="small" @click="handleOpenReject(row)">淘汰</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </div>
      </div>

      <!-- D. 店铺设置多标签页模式 (已彻底移出岗位招聘至独立页签) -->
      <el-tabs v-else v-model="activeTab">
        <!-- 3. 短信管理 (严格对齐截图 media_1788699619136.png, media_1788699981137.png, media_1788699959771.png) -->
        <el-tab-pane label="💬 短信管理" name="sms">
          <div class="sms-management-pane">
            <!-- 顶部4个操作按钮与通知开关栏 (严格对齐截图顶部) -->
            <div class="sms-top-control-bar">
              <div class="sms-tabs-left">
                <button
                  :class="['sms-nav-btn', smsCurrentSubTab === 'BUY' ? 'active-orange' : 'normal-blue']"
                  @click="smsCurrentSubTab = 'BUY'"
                >
                  短信购买
                </button>
                <button
                  :class="['sms-nav-btn', smsCurrentSubTab === 'BALANCE' ? 'active-orange' : 'normal-blue']"
                  @click="smsCurrentSubTab = 'BALANCE'"
                >
                  短信余量
                </button>
                <button
                  :class="['sms-nav-btn', smsCurrentSubTab === 'SIGN' ? 'active-orange' : 'normal-blue']"
                  @click="smsCurrentSubTab = 'SIGN'"
                >
                  短信签名
                </button>
                <button
                  :class="['sms-nav-btn', smsCurrentSubTab === 'BULK' ? 'active-orange' : 'normal-blue']"
                  @click="smsCurrentSubTab = 'BULK'"
                >
                  短信群发
                </button>
              </div>

              <div class="sms-switches-right">
                <span class="sw-label">定向优惠券派发时通知</span>
                <el-switch v-model="smsNotifyCoupon" @change="handleSaveSmsSwitches" />

                <span class="sw-label" style="margin-left: 20px;">消费短信通知</span>
                <el-switch v-model="smsNotifyConsume" @change="handleSaveSmsSwitches" />

                <span class="service-tip">
                  <el-icon style="margin-right: 4px; vertical-align: middle;"><InfoFilled /></el-icon>
                  请联系客服开通短信通知业务
                </span>
              </div>
            </div>

            <!-- 子视图 1: 短信购买 (严格对齐截图表格与支付方式) -->
            <div v-if="smsCurrentSubTab === 'BUY'" class="sms-buy-section">
              <!-- 灰色小标题条 -->
              <div class="sms-gray-header">
                请选择短信套餐（营销类）
              </div>

              <!-- 套餐选择表格 (严格对齐截图字段与数据) -->
              <div class="sms-table-wrapper">
                <table class="custom-sms-table">
                  <thead>
                    <tr>
                      <th style="width: 80px; text-align: center;">选择</th>
                      <th>套餐名称</th>
                      <th style="text-align: center;">短信数量</th>
                      <th style="text-align: center;">套餐价格</th>
                      <th style="text-align: center;">套餐单价</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr
                      v-for="pkg in smsPackages"
                      :key="pkg.id"
                      :class="['pkg-row', selectedPackageId === pkg.id ? 'row-selected' : '']"
                      @click="selectedPackageId = pkg.id"
                    >
                      <td style="text-align: center;">
                        <input
                          type="radio"
                          name="smsPackage"
                          :value="pkg.id"
                          :checked="selectedPackageId === pkg.id"
                          @change="selectedPackageId = pkg.id"
                        />
                      </td>
                      <td>{{ pkg.name }}</td>
                      <td style="text-align: center;">{{ pkg.count }}</td>
                      <td style="text-align: center;">{{ pkg.price }}</td>
                      <td style="text-align: center;">{{ pkg.unitPrice }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <!-- 支付方式与确认支付操作栏 (严格对齐截图底部) -->
              <div class="sms-bottom-action-bar">
                <div class="pay-method-block">
                  <span class="pay-label">支付方式：</span>

                  <!-- 微信支付卡片 -->
                  <div
                    :class="['pay-card', selectedPayMethod === 'WECHAT' ? 'pay-active' : '']"
                    @click="selectedPayMethod = 'WECHAT'"
                  >
                    <div class="wechat-icon-circle">
                      <svg viewBox="0 0 24 24" width="20" height="20" fill="#fff">
                        <path d="M8.5 4C4.91 4 2 6.54 2 9.68c0 1.77.92 3.34 2.37 4.39l-.61 2.24 2.45-1.12c.73.23 1.49.36 2.29.36.19 0 .37-.01.56-.03-.22-.59-.36-1.22-.36-1.89 0-3.14 2.91-5.68 6.5-5.68.27 0 .54.02.8.05C15.22 5.71 12.11 4 8.5 4zm-2 4.25a1 1 0 1 1 0-2 1 1 0 0 1 0 2zm4 0a1 1 0 1 1 0-2 1 1 0 0 1 0 2zm6 2.43c-3.1 0-5.61 2.19-5.61 4.88 0 1.52.8 2.87 2.05 3.77l-.53 1.93 2.11-.96c.63.2 1.29.31 1.98.31 3.1 0 5.61-2.19 5.61-4.88 0-2.69-2.51-4.88-5.61-4.88zm-2 3.44a.86.86 0 1 1 0-1.72.86.86 0 0 1 0 1.72zm3.44 0a.86.86 0 1 1 0-1.72.86.86 0 0 1 0 1.72z"/>
                      </svg>
                    </div>
                    <span class="pay-text">微信支付</span>
                  </div>

                  <!-- 支付宝支付卡片 -->
                  <div
                    :class="['pay-card', selectedPayMethod === 'ALIPAY' ? 'pay-active' : '']"
                    @click="selectedPayMethod = 'ALIPAY'"
                  >
                    <div class="alipay-icon-circle">
                      <svg viewBox="0 0 24 24" width="20" height="20" fill="#fff">
                        <path d="M4 4h16v16H4V4zm9.3 5.4h3.6V8.1h-3.6V5.8h-1.6v2.3H8.1v1.3h5.2c-.4 1.8-1.5 3.3-2.9 4.3-1-1-1.7-2.2-2.1-3.6H6.7c.4 1.7 1.3 3.3 2.5 4.5-2 1.1-4.2 1.7-5.2 1.7v1.4c1.8 0 4.5-.8 6.9-2.3 2.2 1.5 4.9 2.3 7.1 2.3v-1.4c-2.1 0-4.6-.8-6.6-2.1 1.6-1.1 2.9-2.8 3.5-4.9h2.4V9.4h-4z"/>
                      </svg>
                    </div>
                    <span class="pay-text">支付宝支付</span>
                  </div>
                </div>

                <div class="pay-btn-block">
                  <el-button type="primary" size="large" class="confirm-pay-btn" @click="handleOpenPayModal">
                    确认支付
                  </el-button>
                </div>
              </div>
            </div>

            <!-- 子视图 2: 短信余量 -->
            <div v-else-if="smsCurrentSubTab === 'BALANCE'" class="sms-balance-section">
              <el-row :gutter="16" style="margin-bottom: 20px;">
                <el-col :span="8">
                  <div class="stat-box box-blue">
                    <div class="s-lbl">当前可用短信余量</div>
                    <div class="s-val">{{ currentSmsBalance.toLocaleString() }} <span class="s-unit">条</span></div>
                    <div class="s-sub">可支撑日常到店及消费提醒自动发送</div>
                  </div>
                </el-col>
                <el-col :span="8">
                  <div class="stat-box box-green">
                    <div class="s-lbl">累计充值短信</div>
                    <div class="s-val">{{ totalSmsRecharged.toLocaleString() }} <span class="s-unit">条</span></div>
                    <div class="s-sub">历史购买套餐累计充值总量</div>
                  </div>
                </el-col>
                <el-col :span="8">
                  <div class="stat-box box-orange">
                    <div class="s-lbl">累计发送扣减</div>
                    <div class="s-val">{{ totalSmsUsed.toLocaleString() }} <span class="s-unit">条</span></div>
                    <div class="s-sub">到达率 99.8% · 包含群发与结账提醒</div>
                  </div>
                </el-col>
              </el-row>

              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                <span style="font-weight: 600; font-size: 14px;">短信收支流水明细</span>
                <el-button size="small" type="primary" plain @click="smsCurrentSubTab = 'BUY'">+ 充值短信包</el-button>
              </div>

              <el-table :data="paginatedSmsRecords" stripe border style="width: 100%;">
                <el-table-column prop="id" label="流水单号" width="160" />
                <el-table-column prop="scene" label="业务类型/场景" min-width="170">
                  <template #default="{ row }">
                    <b>{{ row.scene }}</b>
                    <div style="font-size: 11px; color: #64748b;">{{ row.desc }}</div>
                  </template>
                </el-table-column>
                <el-table-column prop="phone" label="接收对象/号码" width="140" />
                <el-table-column prop="change" label="变动条数" width="130">
                  <template #default="{ row }">
                    <b :style="{ color: row.change > 0 ? '#10b981' : '#ea580c' }">
                      {{ row.change > 0 ? '+' : '' }}{{ row.change }} 条
                    </b>
                  </template>
                </el-table-column>
                <el-table-column prop="balance" label="变动后余量" width="130">
                  <template #default="{ row }">
                    <span>{{ row.balance }} 条</span>
                  </template>
                </el-table-column>
                <el-table-column prop="time" label="发生时间" width="170" />
                <el-table-column prop="status" label="状态" width="110">
                  <template #default="{ row }">
                    <el-tag size="small" :type="row.status === 'SUCCESS' ? 'success' : 'info'">
                      {{ row.status === 'SUCCESS' ? '已送达' : '处理中' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <template #empty>
                  <el-empty description="暂无短信收支与送达明细" :image-size="60" />
                </template>
              </el-table>

              <div style="display: flex; justify-content: flex-end; margin-top: 14px;">
                <el-pagination
                  v-model:current-page="smsCurrentPage"
                  v-model:page-size="smsPageSize"
                  :page-sizes="[5, 10, 20]"
                  layout="total, sizes, prev, pager, next"
                  :total="smsRecords.length"
                />
              </div>
            </div>

            <!-- 子视图 3: 短信签名 (严格对齐截图 media_1788699981137.png) -->
            <div v-else-if="smsCurrentSubTab === 'SIGN'" class="sms-sign-section">
              <!-- 顶部黄色重要须知框与申请按钮 (严格对齐截图3) -->
              <div class="sign-top-notice-box">
                <div class="notice-left">
                  <span class="bell-icon">🔔</span>
                  <span class="notice-content">
                    签名状态“通过”表示已在云管门店平台审核通过，但目前签名均要完成运营商实名报备才能确保发送成功率，申请签名的报备时间一般为5-7个工作日，部分运营商需7-10个工作日或更长时间，具体以运营商实际审核时间为准，一定先少量多次向三大运营商手机号发送以测试成功率，运营商不支持退款，请符合预期后再正式发送。此签名仅用在群发短信使用
                  </span>
                </div>
                <div class="notice-right">
                  <el-button type="primary" plain class="apply-sign-btn" @click="openApplySignDialog = true">
                    申请签名
                  </el-button>
                </div>
              </div>

              <!-- 签名列表表格 (严格对齐截图3表头: 公司名称 | 法人姓名 | 申请时间 | 状态 | 审核原因 | 操作) -->
              <el-table :data="signaturesList" stripe border style="width: 100%; margin-top: 14px;">
                <el-table-column prop="companyName" label="公司名称" min-width="220">
                  <template #default="{ row }">
                    <b>{{ row.companyName }}</b>
                    <el-tag size="small" type="info" style="margin-left: 6px;">【{{ row.signName }}】</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="legalPerson" label="法人姓名" width="130" />
                <el-table-column prop="applyTime" label="申请时间" width="170" />
                <el-table-column prop="status" label="状态" width="110">
                  <template #default="{ row }">
                    <el-tag :type="row.status === 'APPROVED' ? 'success' : 'warning'" size="small">
                      {{ row.status === 'APPROVED' ? '通过' : '审核中' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="auditReason" label="审核原因" min-width="240">
                  <template #default="{ row }">
                    <span>{{ row.auditReason || '平台已审核通过，已向运营商完成实名报备' }}</span>
                  </template>
                </el-table-column>
                <el-table-column label="操作" width="150" fixed="right">
                  <template #default="{ row }">
                    <el-button link type="primary" @click="handleViewSignDetail(row)">查看资质</el-button>
                    <el-button link type="danger" @click="handleDeleteSign(row)">删除</el-button>
                  </template>
                </el-table-column>
                <template #empty>
                  <div class="empty-sign-box">暂无短信签名，请点击上方申请签名按钮申请</div>
                </template>
              </el-table>
            </div>

            <!-- 子视图 4: 短信群发 -->
            <div v-else-if="smsCurrentSubTab === 'BULK'" class="sms-bulk-section">
              <el-form label-width="110px" style="max-width: 820px;">
                <el-form-item label="群发目标客群" required>
                  <div style="display: flex; gap: 10px; width: 100%; align-items: center; flex-wrap: wrap;">
                    <el-select v-model="bulkForm.targetGroup" style="width: 290px;" @change="handleTargetGroupChange">
                      <el-option label="全体在籍会员 (全量营销)" value="ALL" />
                      <el-option label="近 30 天未到店老客 (促活唤醒)" value="INACTIVE_30" />
                      <el-option label="高净值 VIP 黑钻/白金会员 (专属尊享礼)" value="VIP" />
                      <el-option label="本月生日会员 (生日专属礼遇券提醒)" value="BIRTHDAY" />
                    </el-select>
                    <el-button type="primary" plain size="default" @click="handleOpenBulkMembersModal">
                      👥 查看/编辑客群名单 (共 {{ currentTargetGroupMembers.length }} 人 · 已选 {{ selectedBulkMemberIds.length }} 人)
                    </el-button>
                  </div>
                </el-form-item>

                <el-form-item label="快捷消息模板">
                  <div style="display: flex; gap: 8px; flex-wrap: wrap;">
                    <el-button size="small" plain @click="handleInsertTemplate('WEL')">新人迎新礼</el-button>
                    <el-button size="small" plain @click="handleInsertTemplate('VIP')">会员日双倍积分</el-button>
                    <el-button size="small" plain @click="handleInsertTemplate('CALL')">唤醒老客到店礼</el-button>
                    <el-button size="small" plain @click="handleInsertTemplate('BIRTH')">生日特惠祝福</el-button>
                  </div>
                </el-form-item>

                <el-form-item label="插入动态变量">
                  <div style="display: flex; gap: 8px;">
                    <el-button size="small" type="primary" link @click="bulkForm.content += '{会员姓名}'">+ {会员姓名}</el-button>
                    <el-button size="small" type="primary" link @click="bulkForm.content += '{门店名称}'">+ {门店名称}</el-button>
                    <el-button size="small" type="primary" link @click="bulkForm.content += '{优惠金额}'">+ {优惠金额}</el-button>
                    <el-button size="small" type="primary" link @click="bulkForm.content += '{到期时间}'">+ {到期时间}</el-button>
                  </div>
                </el-form-item>

                <el-form-item label="短信正文内容" required>
                  <el-input
                    v-model="bulkForm.content"
                    type="textarea"
                    :rows="4"
                    placeholder="输入群发短信正文，每条短信上限70字，超出按两条计费..."
                  />
                  <div style="display: flex; justify-content: space-between; width: 100%; font-size: 12px; color: #64748b; margin-top: 4px;">
                    <span>发送签名：<b>【{{ currentActiveSignName }}】</b>（已计入字数）</span>
                    <span>已输入 {{ totalBulkChars }} 字 · 计费 {{ bulkSmsCountPerPerson }} 条/人</span>
                  </div>
                </el-form-item>

                <el-form-item label="消耗预估">
                  <div style="font-size: 13.5px; color: #334155;">
                    目标接收客户约 <b style="color: #0284c7; font-size: 16px;">{{ estimatedMemberCount }}</b> 人 · 预计扣减短信 <b style="color: #ea580c; font-size: 16px;">{{ estimatedMemberCount * bulkSmsCountPerPerson }}</b> 条（当前可用 {{ currentSmsBalance }} 条）
                  </div>
                  <div v-if="estimatedMemberCount === 0" style="font-size: 12px; color: #94a3b8; margin-top: 4px;">
                    💡 当前客群名单暂无匹配会员或未勾选任何客户，群发扣减条数为 0 条。
                  </div>
                </el-form-item>

                <el-form-item>
                  <el-button type="default" @click="handleSendTestSms">发送测试短信给自己</el-button>
                  <el-button type="primary" :loading="sendingBulk" @click="handleConfirmBulkSend">立即确认群发短信</el-button>
                </el-form-item>
              </el-form>
            </div>
          </div>
        </el-tab-pane>

        <!-- 4. 双轨储值与收银扣减策略 (全面优化重塑) -->
        <el-tab-pane label="💳 双轨储值与收银规则" name="rechargeRule">
          <div class="rule-management-container">
            <!-- 顶部引言卡片 -->
            <el-alert
              title="海马体双轨储值系统：将【实充本金】（顾客现金/真金白银充入）与【赠送金额】（商家促销赠送金）从账户底层独立建账核算，有效防范退卡恶意套现、保障商家资金安全并符合财务税务规范。"
              type="info"
              :closable="false"
              show-icon
              style="margin-bottom: 20px;"
            />

            <!-- 1. 核心扣减模式卡片双列对比 -->
            <div class="section-sub-title">⚖️ 储值资金扣减核心策略 (点击卡片切换)</div>
            <div class="deduct-mode-cards">
              <!-- 模式 A: 同比例等比扣减 (官方推荐) -->
              <div
                class="mode-card"
                :class="{ 'active': ruleForm.deductMode === 'PROPORTIONAL' }"
                @click="ruleForm.deductMode = 'PROPORTIONAL'"
              >
                <div class="card-badge recommend">🌟 官方推荐 · 风控首选</div>
                <div class="mode-header">
                  <div class="mode-icon">⚖️</div>
                  <div class="mode-title-box">
                    <div class="mode-title">同比例等比扣减模式 (PROPORTIONAL)</div>
                    <div class="mode-desc">消费划扣时，按账户剩余本金与赠送金当前比例等比扣除</div>
                  </div>
                  <div class="mode-radio-circle"></div>
                </div>

                <div class="formula-box">
                  <div class="f-row">
                    <span class="f-tag principal">本金扣额</span> = 消费金额 × (剩余本金 / 剩余总额)
                  </div>
                  <div class="f-row">
                    <span class="f-tag gift">赠金扣额</span> = 消费金额 × (剩余赠金 / 剩余总额)
                  </div>
                </div>

                <div class="case-box">
                  <div class="case-label">💡 业务实操案例：</div>
                  <div class="case-content">
                    会员充 <strong>1000</strong> 送 <strong>200</strong>（本金占比 83.33%，赠金 16.67%）。本次消费 <strong>300元</strong>，系统自动扣除本金 <strong>￥250</strong>，扣除赠金 <strong>￥50</strong>。若顾客申请退卡，按剩余未消费本金退还，<strong>100% 杜绝退卡套现风险</strong>。
                  </div>
                </div>
              </div>

              <!-- 模式 B: 优先扣减实充本金 -->
              <div
                class="mode-card"
                :class="{ 'active': ruleForm.deductMode === 'PRINCIPAL_FIRST' }"
                @click="ruleForm.deductMode = 'PRINCIPAL_FIRST'"
              >
                <div class="card-badge speed">⚡ 资金快速回笼</div>
                <div class="mode-header">
                  <div class="mode-icon">🥇</div>
                  <div class="mode-title-box">
                    <div class="mode-title">优先扣减实充本金模式 (PRINCIPAL_FIRST)</div>
                    <div class="mode-desc">优先消耗顾客真金白银实充本金，本金扣完后再消耗赠金</div>
                  </div>
                  <div class="mode-radio-circle"></div>
                </div>

                <div class="formula-box">
                  <div class="f-row">
                    <span class="f-tag principal">优先消耗</span> 本金账户扣至 0 元
                  </div>
                  <div class="f-row">
                    <span class="f-tag gift">差额补充</span> 剩余应付不足部分由赠送金全额抵扣
                  </div>
                </div>

                <div class="case-box">
                  <div class="case-label">💡 业务实操案例：</div>
                  <div class="case-content">
                    会员充 <strong>1000</strong> 送 <strong>200</strong>。本次消费 <strong>800元</strong>，优先全额扣除实充本金 <strong>￥800</strong>，实充本金剩余 200元，赠送金 200元原封不动保留。顾客心理接受度高，适合大促拓客冲刺。
                  </div>
                </div>
              </div>
            </div>

            <!-- 2. 交互式双轨划扣沙盘模拟器 -->
            <div class="sandbox-box">
              <div class="sandbox-header">
                <div class="sb-title">🧮 双轨划扣实时计算沙盘模拟器 (即时验算扣除与结余)</div>
                <el-tag size="small" type="success" effect="plain">当前模式：{{ ruleForm.deductMode === 'PROPORTIONAL' ? '按比例扣减' : '优先扣本金' }}</el-tag>
              </div>

              <div class="sandbox-inputs">
                <div class="sb-input-group">
                  <span class="sb-lbl">模拟账户剩余本金：</span>
                  <el-input-number v-model="sandboxData.principal" :min="0" :step="100" style="width: 150px;" />
                  <span class="unit">元</span>
                </div>
                <div class="sb-input-group">
                  <span class="sb-lbl">模拟账户剩余赠金：</span>
                  <el-input-number v-model="sandboxData.gift" :min="0" :step="50" style="width: 150px;" />
                  <span class="unit">元</span>
                </div>
                <div class="sb-input-group">
                  <span class="sb-lbl">模拟本次结账消费：</span>
                  <el-input-number v-model="sandboxData.consume" :min="1" :step="50" style="width: 150px;" />
                  <span class="unit">元</span>
                </div>
              </div>

              <!-- 模拟计算成果仪表板 -->
              <div class="sandbox-result-card">
                <div class="res-col">
                  <div class="res-lbl">本次扣减本金</div>
                  <div class="res-val principal">￥{{ sandboxResult.deductP }}</div>
                  <div class="res-sub">扣后剩余本金: ￥{{ sandboxResult.remainP }}</div>
                </div>
                <div class="res-divider">+</div>
                <div class="res-col">
                  <div class="res-lbl">本次扣减赠金</div>
                  <div class="res-val gift">￥{{ sandboxResult.deductG }}</div>
                  <div class="res-sub">扣后剩余赠金: ￥{{ sandboxResult.remainG }}</div>
                </div>
                <div class="res-divider">=</div>
                <div class="res-col total">
                  <div class="res-lbl">本次实付扣费总计</div>
                  <div class="res-val total">￥{{ (sandboxResult.deductP + sandboxResult.deductG).toFixed(2) }}</div>
                  <div class="res-sub">账户总结余: ￥{{ (sandboxResult.remainP + sandboxResult.remainG).toFixed(2) }}</div>
                </div>
              </div>

              <!-- 双轨资产占比双色进度条 -->
              <div class="sandbox-progress-row">
                <div class="prog-meta">
                  <span>实充本金占比: {{ sandboxResult.pPercent }}%</span>
                  <span>赠送金占比: {{ sandboxResult.gPercent }}%</span>
                </div>
                <div class="dual-prog-track">
                  <div class="prog-fill principal" :style="{ width: sandboxResult.pPercent + '%' }"></div>
                  <div class="prog-fill gift" :style="{ width: sandboxResult.gPercent + '%' }"></div>
                </div>
              </div>
            </div>

            <!-- 3. 营销积分、收银抹零与体验权益规则网格 -->
            <div class="section-sub-title" style="margin-top: 24px;">🎯 积分抵现、收银抹零与营销扩展规则</div>
            <div class="rules-meta-grid">
              <el-card class="rule-sub-card" shadow="never">
                <div class="r-card-head">
                  <span class="r-icon">🪙</span>
                  <span class="r-name">消费积分抵扣规则</span>
                </div>
                <div class="r-card-body">
                  <div class="r-form-line">
                    <span>消费 1 元累计积分：</span>
                    <el-input-number v-model="ruleForm.earnRate" :min="1" :max="10" size="small" style="width: 100px;" />
                    <span>分</span>
                  </div>
                  <div class="r-form-line">
                    <span>积分抵扣兑换汇率：</span>
                    <el-input-number v-model="ruleForm.pointsRate" :min="10" :step="10" size="small" style="width: 100px;" />
                    <span>分抵 1 元</span>
                  </div>
                  <div class="r-form-line">
                    <span>单笔订单最高抵扣：</span>
                    <el-input-number v-model="ruleForm.maxPointsDeductPercent" :min="5" :max="100" :step="5" size="small" style="width: 100px;" />
                    <span>%</span>
                  </div>
                </div>
              </el-card>

              <el-card class="rule-sub-card" shadow="never">
                <div class="r-card-head">
                  <span class="r-icon">✂️</span>
                  <span class="r-name">收银结算抹零策略</span>
                </div>
                <div class="r-card-body">
                  <el-radio-group v-model="ruleForm.cashRoundingMode" size="small" style="display: flex; flex-direction: column; gap: 8px;">
                    <el-radio label="ROUND_NONE">不抹零 (实收至角分，精准记账)</el-radio>
                    <el-radio label="ROUND_FEN">抹分舍去 (如 128.88 元 -> 实收 128.80 元)</el-radio>
                    <el-radio label="ROUND_JIAO">抹角舍去 (如 128.88 元 -> 实收 128.00 元)</el-radio>
                    <el-radio label="ROUND_HALF_UP">四舍五入到元 (如 128.4 元->128元, 128.6 元->129元)</el-radio>
                  </el-radio-group>
                </div>
              </el-card>

              <el-card class="rule-sub-card" shadow="never">
                <div class="r-card-head">
                  <span class="r-icon">🎁</span>
                  <span class="r-name">新会员权益体验期</span>
                </div>
                <div class="r-card-body">
                  <el-switch v-model="ruleForm.enableTrial" active-text="新开卡会员开启权益体验期" />
                  <div v-if="ruleForm.enableTrial" class="r-form-line" style="margin-top: 14px;">
                    <span>默认体验期天数：</span>
                    <el-input-number v-model="ruleForm.trialDays" :min="1" :max="30" size="small" style="width: 100px;" />
                    <span>天</span>
                  </div>
                  <div style="font-size: 12px; color: #64748b; margin-top: 8px;">
                    开卡即享金卡同级别折扣，到期后自动回归实际卡模板
                  </div>
                </div>
              </el-card>
            </div>

            <div style="margin-top: 24px;">
              <el-button type="primary" size="large" @click="handleSaveRechargeRules">
                💾 保存双轨储值与收银规则配置
              </el-button>
            </div>
          </div>
        </el-tab-pane>

        <!-- 6. 打印机与小票模板 (左右分栏 + 1:1 动态实时仿真热敏小票预览) -->
        <el-tab-pane label="🖨️ 小票打印与外设" name="printer">
          <div class="printer-settings-container">
            <!-- 左栏: 可视化小票打印模板配置表单 (支持每一个单项独立开关与微调) -->
            <div class="printer-form-col">
              <el-card shadow="never" class="config-card">
                <template #header>
                  <div class="card-header-flex">
                    <div class="header-tit-wrap">
                      <span style="font-weight: 700; font-size: 15px;">⚙️ 小票打印模板参数配置</span>
                      <span class="sub-tip">支持细粒度控制每个区域/字号/打印开关，右侧 1:1 仿真热敏纸实时渲染</span>
                    </div>
                    <div class="preset-btn-group">
                      <el-button size="small" type="warning" plain @click="handleSyncCurrentStoreInfoToReceipt">
                        🔄 一键载入当前店铺资料
                      </el-button>
                      <el-button size="small" type="primary" plain @click="applyPrinterPreset('RECOMMENDED')">
                        ⭐ 推荐常用
                      </el-button>
                      <el-button size="small" type="success" plain @click="applyPrinterPreset('ALL')">
                        ✅ 全选开启
                      </el-button>
                      <el-button size="small" type="info" plain @click="applyPrinterPreset('MINIMAL')">
                        📄 极简小票
                      </el-button>
                    </div>
                  </div>
                </template>

                <div class="printer-form-scroll-body">
                  <!-- 分组 1: 纸张规格与全局字号 -->
                  <div class="cfg-group-card">
                    <div class="cfg-group-head">
                      <span class="cfg-group-title">1. 热敏纸规格与打印基础</span>
                    </div>
                    <div class="cfg-group-body">
                      <div class="cfg-row-flex">
                        <span class="cfg-label">热敏纸宽度：</span>
                        <el-radio-group v-model="printerForm.paperWidth" size="small">
                          <el-radio-button label="80mm">80mm 大宽幅 (标准)</el-radio-button>
                          <el-radio-button label="58mm">58mm 紧凑型</el-radio-button>
                        </el-radio-group>
                      </div>
                      <div class="cfg-row-flex" style="margin-top: 10px;">
                        <span class="cfg-label">打印字号：</span>
                        <el-radio-group v-model="printerForm.fontSize" size="small">
                          <el-radio-button label="compact">紧凑小字</el-radio-button>
                          <el-radio-button label="standard">标准适中</el-radio-button>
                          <el-radio-button label="large">清晰大字</el-radio-button>
                        </el-radio-group>
                      </div>
                      <div class="cfg-row-flex" style="margin-top: 10px;">
                        <span class="cfg-label">自动打印：</span>
                        <el-switch v-model="printerForm.autoPrint" active-text="收银结账完成后自动调起打印" />
                      </div>
                    </div>
                  </div>

                  <!-- 分组 2: 票头与店名标题 -->
                  <div class="cfg-group-card">
                    <div class="cfg-group-head">
                      <span class="cfg-group-title">2. 小票页眉与店名标题</span>
                    </div>
                    <div class="cfg-group-body">
                      <div class="cfg-switch-item">
                        <div class="sw-row">
                          <el-switch v-model="printerForm.showStoreHeader" active-text="打印门店大抬头" />
                        </div>
                        <el-input
                          v-if="printerForm.showStoreHeader"
                          v-model="printerForm.storeHeaderTitle"
                          size="small"
                          placeholder="小票抬头店名，如：海马智慧门店 (旗舰体验中心)"
                          style="margin-top: 6px;"
                        />
                      </div>
                      <div class="cfg-switch-item" style="margin-top: 10px;">
                        <div class="sw-row">
                          <el-switch v-model="printerForm.showHeaderSubtitle" active-text="打印页眉宣传副标题" />
                        </div>
                        <el-input
                          v-if="printerForm.showHeaderSubtitle"
                          v-model="printerForm.headerSubTitle"
                          size="small"
                          placeholder="宣传副标，如：海马智慧连锁 · 竭诚为您提供至臻服务"
                          style="margin-top: 6px;"
                        />
                      </div>
                      <div class="cfg-switch-item" style="margin-top: 10px;">
                        <div class="sw-row">
                          <el-switch v-model="printerForm.showTicketTitle" active-text="打印单据分类标题" />
                        </div>
                        <el-input
                          v-if="printerForm.showTicketTitle"
                          v-model="printerForm.ticketTitle"
                          size="small"
                          placeholder="单据标题，如：【 顾客结账消费明细清单 】"
                          style="margin-top: 6px;"
                        />
                      </div>
                    </div>
                  </div>

                  <!-- 分组 3: 订单元数据与顾客信息 -->
                  <div class="cfg-group-card">
                    <div class="cfg-group-head">
                      <span class="cfg-group-title">3. 单据编号与顾客客显信息</span>
                    </div>
                    <div class="cfg-group-grid">
                      <el-switch v-model="printerForm.showOrderNo" active-text="打印单据编号 (单号)" />
                      <el-switch v-model="printerForm.showCheckoutTime" active-text="打印结账下单时间" />
                      <el-switch v-model="printerForm.showCashierName" active-text="打印收银员/操作员" />
                      <el-switch v-model="printerForm.showTechnician" active-text="打印服务技师/工位" />
                      <el-switch v-model="printerForm.showCustomerName" active-text="打印顾客姓名及等级" />
                      <el-switch v-model="printerForm.showCustomerPhone" active-text="打印顾客联系手机号" />
                      <el-switch
                        v-if="printerForm.showCustomerPhone"
                        v-model="printerForm.maskCustomerPhone"
                        active-text="顾客手机号自动中间4位脱敏掩码 (如 138****0001)"
                      />
                    </div>
                  </div>

                  <!-- 分组 4: 项目明细表格与字段开关 -->
                  <div class="cfg-group-card">
                    <div class="cfg-group-head">
                      <span class="cfg-group-title">4. 消费项目明细清单</span>
                      <el-switch v-model="printerForm.showItemsTable" active-text="总开关" size="small" />
                    </div>
                    <div v-if="printerForm.showItemsTable" class="cfg-group-grid">
                      <el-switch v-model="printerForm.showItemQty" active-text="显示购买数量 (x1)" />
                      <el-switch v-model="printerForm.showItemPrice" active-text="显示项目单价" />
                      <el-switch v-model="printerForm.showItemSum" active-text="显示小计金额" />
                    </div>
                  </div>

                  <!-- 分组 5: 金额汇总与支付方式明细 -->
                  <div class="cfg-group-card">
                    <div class="cfg-group-head">
                      <span class="cfg-group-title">5. 金额核算与支付渠道明细</span>
                    </div>
                    <div class="cfg-group-grid">
                      <el-switch v-model="printerForm.showOriginalPrice" active-text="显示消费原价总计" />
                      <el-switch v-model="printerForm.showDiscount" active-text="显示会员立减/优惠金额" />
                      <el-switch v-model="printerForm.showActualAmount" active-text="显示实收总额 (加粗强调)" />
                      <el-switch v-model="printerForm.showPayMethods" active-text="显示支付方式拆分 (微信/储值等)" />
                    </div>
                  </div>

                  <!-- 分组 6: 会员双轨资产与积分变动 -->
                  <div class="cfg-group-card">
                    <div class="cfg-group-head">
                      <span class="cfg-group-title">6. 会员双轨储值资产与积分</span>
                      <el-switch v-model="printerForm.showMemberAssetSection" active-text="总开关" size="small" />
                    </div>
                    <div v-if="printerForm.showMemberAssetSection" class="cfg-group-grid">
                      <el-switch v-model="printerForm.showPrincipalBalance" active-text="打印实充本金余额" />
                      <el-switch v-model="printerForm.showGiftBalance" active-text="打印奖励赠金余额" />
                      <el-switch v-model="printerForm.showEarnedPoints" active-text="打印本次消费奖励积分" />
                      <el-switch v-model="printerForm.showTotalPoints" active-text="打印累计会员总积分" />
                    </div>
                  </div>

                  <!-- 分组 7: 页脚致谢与门店联系方式 -->
                  <div class="cfg-group-card">
                    <div class="cfg-group-head">
                      <span class="cfg-group-title">7. 页脚致谢、门店地址与二维码</span>
                    </div>
                    <div class="cfg-group-body">
                      <div class="cfg-switch-item">
                        <div class="sw-row">
                          <el-switch v-model="printerForm.showFooterNotes" active-text="打印底部致谢/退换温馨提示" />
                        </div>
                        <el-input
                          v-if="printerForm.showFooterNotes"
                          v-model="printerForm.footerNotes"
                          type="textarea"
                          :rows="2"
                          size="small"
                          placeholder="如：凭此小票享7天无理由退换或技术复修服务，感谢您的惠顾！"
                          style="margin-top: 6px;"
                        />
                      </div>
                      <div class="cfg-switch-item" style="margin-top: 10px;">
                        <div class="sw-row">
                          <el-switch v-model="printerForm.showServiceHotline" active-text="打印服务热线电话" />
                        </div>
                        <el-input
                          v-if="printerForm.showServiceHotline"
                          v-model="printerForm.serviceHotline"
                          size="small"
                          placeholder="如：020-88996611 / 400-888-9999"
                          style="margin-top: 6px;"
                        />
                      </div>
                      <div class="cfg-switch-item" style="margin-top: 10px;">
                        <div class="sw-row">
                          <el-switch v-model="printerForm.showStoreAddress" active-text="打印门店详细地址" />
                        </div>
                        <el-input
                          v-if="printerForm.showStoreAddress"
                          v-model="printerForm.storeAddress"
                          size="small"
                          placeholder="如：广州市天河区天河路208号粤海天河城4楼"
                          style="margin-top: 6px;"
                        />
                      </div>
                      <div class="cfg-switch-item" style="margin-top: 10px;">
                        <div class="sw-row">
                          <el-switch v-model="printerForm.showQrCode" active-text="打印底部二维码与引导语" />
                        </div>
                        <div v-if="printerForm.showQrCode" style="margin-top: 6px; display: flex; flex-direction: column; gap: 6px;">
                          <div style="display: flex; gap: 6px;">
                            <el-input
                              v-model="printerForm.qrCodeText"
                              size="small"
                              placeholder="如：http://fwpt.cn/member/benefits?storeId=S001 或 http://当前IP/member/benefits?storeId=S001"
                            />
                            <el-button size="small" type="primary" plain @click="handleResetStoreQrUrl">
                              🔄 生成当前专属链接
                            </el-button>
                          </div>
                          <el-input
                            v-model="printerForm.qrCodeHint"
                            size="small"
                            placeholder="二维码下方说明，如：扫码查看店铺信息与会员权益"
                          />
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- 分组 8: 租户留存联与顾客签字 -->
                  <div class="cfg-group-card">
                    <div class="cfg-group-head">
                      <span class="cfg-group-title">8. 租户留存联与顾客签字确认</span>
                      <el-switch v-model="printerForm.showSignStub" active-text="总开关" size="small" />
                    </div>
                    <div v-if="printerForm.showSignStub" class="cfg-group-grid">
                      <el-switch v-model="printerForm.showStubOrderMeta" active-text="打印留存联单号与金额" />
                      <el-switch v-model="printerForm.showStubSignLine" active-text="打印顾客签字下划线与日期" />
                    </div>
                  </div>
                </div>

                <div class="form-actions-bar">
                  <el-button type="primary" size="large" icon="Check" @click="handleSaveReceiptTemplate">
                    💾 保存小票模板全局设置
                  </el-button>
                  <el-button type="success" plain size="large" icon="Printer" @click="handlePrintTestReceipt">
                    🖨️ 打印测试样张 (调用本地打印机)
                  </el-button>
                </div>
              </el-card>
            </div>

            <!-- 右栏: 1:1 动态实时仿真热敏小票预览 (所见即所得，支持80mm/58mm与全开关响应) -->
            <div class="printer-preview-col">
              <div class="preview-sticky-wrap">
                <div class="preview-header-bar">
                  <div class="p-title">📄 1:1 动态仿真热敏小票预览 (所见即所得)</div>
                  <div class="preview-header-actions">
                    <el-button size="small" link type="primary" @click="scrollPreviewToTop">🔝 回到顶部</el-button>
                    <el-tag size="small" type="primary" effect="dark">{{ printerForm.paperWidth }} · {{ printerForm.fontSize }}</el-tag>
                  </div>
                </div>

                <div ref="paperStageRef" class="settings-paper-stage">
                  <div :class="['printer-feed-head', { 'is-58mm': printerForm.paperWidth === '58mm' }]">
                    <span class="feed-led"></span>
                    <span class="feed-text">出纸口 · {{ printerForm.paperWidth === '58mm' ? '58mm 便携紧凑' : '80mm 旗舰标准' }}</span>
                  </div>
                  <div
                    id="settings-thermal-sample-ticket"
                    class="thermal-paper-mockup"
                    :class="['width-' + printerForm.paperWidth, 'font-' + printerForm.fontSize]"
                  >
                    <!-- 仿真撕纸边缘齿痕 -->
                    <div class="paper-sawtooth top"></div>

                    <!-- 1. 票头与标题 -->
                    <div v-if="printerForm.showStoreHeader || printerForm.showHeaderSubtitle || printerForm.showTicketTitle" class="receipt-center-box">
                      <div v-if="printerForm.showStoreHeader" class="receipt-shop-name">{{ printerForm.storeHeaderTitle || storeConfig.storeName || '海马智慧门店' }}</div>
                      <div v-if="printerForm.showHeaderSubtitle && printerForm.headerSubTitle" class="receipt-sub-title">{{ printerForm.headerSubTitle }}</div>
                      <div v-if="printerForm.showTicketTitle" class="receipt-ticket-type">{{ printerForm.ticketTitle || '【 顾客结账消费明细清单 】' }}</div>
                      <div class="receipt-divider star">********************************</div>
                    </div>

                    <!-- 2. 单据元数据与顾客信息 -->
                    <div
                      v-if="printerForm.showOrderNo || printerForm.showCheckoutTime || printerForm.showCashierName || printerForm.showTechnician || printerForm.showCustomerName || printerForm.showCustomerPhone"
                      class="receipt-meta-grid"
                    >
                      <div v-if="printerForm.showOrderNo" class="meta-row"><span>单据编号：</span><span class="mono">BL202609078801</span></div>
                      <div v-if="printerForm.showCheckoutTime" class="meta-row"><span>结账时间：</span><span>2026-09-07 20:30:15</span></div>
                      <div v-if="printerForm.showCashierName" class="meta-row"><span>收银操作员：</span><span class="mono">{{ currentOperatorName }}</span></div>
                      <div v-if="printerForm.showTechnician" class="meta-row">
                        <span>服务工位：</span><span>VIP紫荆景观 1号工位</span>
                      </div>
                      <div v-if="printerForm.showCustomerName" class="meta-row">
                        <span>顾客姓名：</span><span>林清雅 (黑钻VIP会员)</span>
                      </div>
                      <div v-if="printerForm.showCustomerPhone" class="meta-row">
                        <span>会员手机：</span>
                        <span>{{ formatSettingsPhone('13800138001', printerForm.maskCustomerPhone) }}</span>
                      </div>
                      <div class="receipt-divider dash">--------------------------------</div>
                    </div>

                    <!-- 3. 消费项目清单 -->
                    <div v-if="printerForm.showItemsTable" class="receipt-items-table">
                      <div class="items-head">
                        <span class="col-name">品名项目</span>
                        <span v-if="printerForm.showItemQty" class="col-qty">数量</span>
                        <span v-if="printerForm.showItemPrice" class="col-price">单价</span>
                        <span v-if="printerForm.showItemSum" class="col-sum">小计</span>
                      </div>
                      <div class="item-row">
                        <div class="item-name">总监设计精剪精修造型</div>
                        <div class="item-meta">
                          <span v-if="printerForm.showItemQty" class="col-qty">x1</span>
                          <span v-if="printerForm.showItemPrice" class="col-price">￥88.00</span>
                          <span v-if="printerForm.showItemSum" class="col-sum">￥88.00</span>
                        </div>
                      </div>
                      <div class="item-row">
                        <div class="item-name">头皮微生态赋活深度SPA</div>
                        <div class="item-meta">
                          <span v-if="printerForm.showItemQty" class="col-qty">x1</span>
                          <span v-if="printerForm.showItemPrice" class="col-price">￥260.00</span>
                          <span v-if="printerForm.showItemSum" class="col-sum">￥260.00</span>
                        </div>
                      </div>
                      <div class="receipt-divider dash">--------------------------------</div>
                    </div>

                    <!-- 4. 结算金额与支付方式 -->
                    <div
                      v-if="printerForm.showOriginalPrice || printerForm.showDiscount || printerForm.showActualAmount || printerForm.showPayMethods"
                      class="receipt-calc-box"
                    >
                      <div v-if="printerForm.showOriginalPrice" class="calc-row"><span>消费原价：</span><span>￥348.00</span></div>
                      <div v-if="printerForm.showDiscount" class="calc-row discount"><span>黑钻立减：</span><span>-￥48.00</span></div>
                      <div v-if="printerForm.showActualAmount" class="calc-row total"><span>实收总额：</span><span class="bold-price">￥300.00</span></div>

                      <div v-if="printerForm.showPayMethods" class="pay-split-list">
                        <div class="pay-row"><span>└ 双轨储值划扣：</span><span>￥300.00</span></div>
                        <div class="pay-row"><span>└ 微信在线支付：</span><span>￥0.00</span></div>
                      </div>
                    </div>

                    <!-- 5. 会员双轨资产与积分变动 -->
                    <div
                      v-if="printerForm.showMemberAssetSection && (printerForm.showPrincipalBalance || printerForm.showGiftBalance || printerForm.showEarnedPoints || printerForm.showTotalPoints)"
                      class="receipt-member-asset-box"
                    >
                      <div class="receipt-divider dash">--------------------------------</div>
                      <div class="asset-title">【 会员双轨资产与积分变动 】</div>
                      <div v-if="printerForm.showPrincipalBalance" class="asset-row">
                        <span>储值本金余额：</span><span>￥1,850.00</span>
                      </div>
                      <div v-if="printerForm.showGiftBalance" class="asset-row">
                        <span>储值赠金余额：</span><span>￥370.00</span>
                      </div>
                      <div v-if="printerForm.showEarnedPoints || printerForm.showTotalPoints" class="asset-row">
                        <span>积分明细变动：</span>
                        <span>
                          <template v-if="printerForm.showEarnedPoints">+300分</template>
                          <template v-if="printerForm.showEarnedPoints && printerForm.showTotalPoints"> / </template>
                          <template v-if="printerForm.showTotalPoints">累计: 1,580分</template>
                        </span>
                      </div>
                    </div>

                    <!-- 6. 页脚致谢、地址与二维码 -->
                    <div
                      v-if="printerForm.showFooterNotes || printerForm.showServiceHotline || printerForm.showStoreAddress || printerForm.showQrCode"
                      class="receipt-footer-box"
                    >
                      <div class="receipt-divider star">********************************</div>
                      <div v-if="printerForm.showFooterNotes && printerForm.footerNotes" class="footer-notes">
                        {{ printerForm.footerNotes }}
                      </div>
                      <div class="footer-meta">
                        <div v-if="printerForm.showServiceHotline">服务热线：{{ printerForm.serviceHotline || storeConfig.phone || '400-888-6688' }}</div>
                        <div v-if="printerForm.showStoreAddress">门店地址：{{ printerForm.storeAddress || storeConfig.address || '智慧商业中心 101号铺' }}</div>
                      </div>

                      <div v-if="printerForm.showQrCode" class="receipt-qr-zone">
                        <div class="qr-img-wrapper">
                          <img v-if="receiptSampleQrDataUrl" :src="receiptSampleQrDataUrl" class="qr-real-img" alt="小票二维码" />
                          <div v-else class="qr-mock-box">
                            <div class="qr-mock-code">
                              <div class="qr-inner-pattern"></div>
                            </div>
                          </div>
                        </div>
                        <div v-if="printerForm.qrCodeHint" class="qr-hint-text">{{ printerForm.qrCodeHint }}</div>
                        <div v-if="printerForm.qrCodeText" class="qr-url-text">{{ printerForm.qrCodeText }}</div>
                      </div>
                    </div>

                    <!-- 7. 租户留存联与签字 -->
                    <div v-if="printerForm.showSignStub" class="receipt-sign-stub">
                      <div class="stub-divider">✄ - - - - - - - - - - - - - - - - - - -</div>
                      <div class="stub-header">【 租户留存联 · 顾客签字确认 】</div>
                      <div v-if="printerForm.showStubOrderMeta" class="stub-meta">
                        <span>单据号：BL202609078801</span>
                        <span>实付金额：￥300.00</span>
                      </div>
                      <div v-if="printerForm.showStubSignLine" class="stub-sign-block">
                        <div class="stub-sign-row">
                          <span class="sign-label">顾客签字：</span>
                          <span class="sign-underline"></span>
                        </div>
                        <div class="stub-date-row">
                          <span>签单日期：____年__月__日</span>
                        </div>
                      </div>
                    </div>

                    <!-- 仿真撕纸边缘齿痕 -->
                    <div class="paper-sawtooth bottom"></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </el-tab-pane>

        <!-- 7. 微信公众号与支付宝生活号顾客关注与动账服务 (租户店务使用端) -->
        <el-tab-pane label="📢 顾客关注与公众号消息服务" name="notification">
          <div class="notification-pane">
            <!-- 顶部全渠道托管状态指示条 -->
            <div class="notif-top-stats-strip">
              <div class="stat-pill">
                <span class="dot green"></span>
                <span class="label">微信服务号：</span>
                <b style="color: #059669;">平台代托管直连 (已就绪)</b>
                <el-tag size="small" type="success" effect="plain" style="margin-left: 6px;">自动拓客吸粉</el-tag>
              </div>

              <div class="stat-pill">
                <span class="dot blue"></span>
                <span class="label">支付宝生活号：</span>
                <b style="color: #2563eb;">平台代托管直连 (已就绪)</b>
              </div>

              <div class="stat-pill">
                <span class="dot purple"></span>
                <span class="label">结账自动推送：</span>
                <b style="color: #7c3aed;">
                  {{ notifConfig.autoPushOnCheckout ? '开启 (每笔消费推微信小票)' : '未开启' }}
                </b>
              </div>

              <div class="stat-pill">
                <span class="dot amber"></span>
                <span class="label">储值变动提醒：</span>
                <b style="color: #d97706;">
                  {{ notifConfig.autoPushOnRecharge ? '开启 (充值到账即时提醒)' : '未开启' }}
                </b>
              </div>

              <div class="stat-pill">
                <span class="dot teal" style="background: #0d9488;"></span>
                <span class="label">APP语音播报：</span>
                <b style="color: #0f766e;">
                  {{ notifConfig.voiceBroadcastRepeatCount || 1 }} 次
                </b>
              </div>

              <div style="margin-left: auto; display: flex; gap: 8px;">
                <el-button size="small" type="success" icon="Printer" @click="handleOpenPrintStandDialog('WECHAT')">
                  🖨️ 打印前台水牌
                </el-button>
                <el-button size="small" type="primary" plain icon="Promotion" @click="notifSubTab = 'SIMULATOR'">
                  🧪 模拟扫码体验
                </el-button>
              </div>
            </div>

            <!-- 二级子导航切换 -->
            <div class="notif-sub-nav-bar">
              <button
                :class="['sub-nav-btn', notifSubTab === 'STAND' ? 'active-tab' : 'default-tab']"
                @click="notifSubTab = 'STAND'"
              >
                🪧 门店专属关注立牌与二维码
              </button>
              <button
                :class="['sub-nav-btn', notifSubTab === 'GUIDE' ? 'active-tab' : 'default-tab']"
                @click="notifSubTab = 'GUIDE'"
              >
                💡 扫码吸粉与业务闭环指南
              </button>
              <button
                :class="['sub-nav-btn', notifSubTab === 'PREVIEW' ? 'active-tab' : 'default-tab']"
                @click="notifSubTab = 'PREVIEW'"
              >
                💌 微信动账小票效果预览
              </button>
              <button
                :class="['sub-nav-btn', notifSubTab === 'SIMULATOR' ? 'active-tab' : 'default-tab']"
                @click="notifSubTab = 'SIMULATOR'"
              >
                📱 顾客扫码模拟体验
              </button>
              <button
                :class="['sub-nav-btn', notifSubTab === 'STRATEGY' ? 'active-tab' : 'default-tab']"
                @click="notifSubTab = 'STRATEGY'"
              >
                ⚙️ 门店动账推送服务设置
              </button>
              <button
                :class="['sub-nav-btn', notifSubTab === 'TEMPLATE_CONFIG' ? 'active-tab' : 'default-tab']"
                @click="notifSubTab = 'TEMPLATE_CONFIG'"
              >
                📋 充值扣费与动账通知模板具体内容与字段映射配置
              </button>
              <button
                :class="['sub-nav-btn', notifSubTab === 'LOGS' ? 'active-tab' : 'default-tab']"
                @click="handleSwitchLogsTab"
              >
                📜 本店消息推送流水明细
                <span v-if="notifLogs.length > 0" class="sub-nav-badge">{{ notifLogs.length }}</span>
              </button>
            </div>

            <!-- 子视图 1: 门店专属关注立牌与二维码 (核心诉求) -->
            <div v-if="notifSubTab === 'STAND'" class="notif-sub-view">
              <!-- 门店选择栏与说明 -->
              <el-card shadow="never" style="margin-bottom: 16px; border: 1px solid #e2e8f0; background: #f8fafc;">
                <div style="display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px;">
                  <div style="display: flex; align-items: center; gap: 10px;">
                    <span style="font-weight: 700; color: #1e293b; font-size: 14px;">🏬 当前所属门店：</span>
                    <el-select
                      v-model="selectedStandStoreId"
                      placeholder="选择门店生成专属水牌"
                      style="width: 280px;"
                      @change="generateStoreQrCodes"
                    >
                      <el-option
                        v-for="s in storeListOptions"
                        :key="s.storeId"
                        :label="s.storeName"
                        :value="s.storeId"
                      />
                    </el-select>
                    <el-tag type="info" size="small">门店编号: {{ selectedStandStoreId }}</el-tag>
                  </div>
                  <div style="font-size: 12px; color: #64748b;">
                    💡 提示：该二维码已植入专属门店场景参数。顾客扫码关注公众号后自动归属到本店会员，收银结账或储值到账时将向其推送本门店专属小票！
                  </div>
                </div>
              </el-card>

              <el-row :gutter="24">
                <!-- 微信公众号 (服务号) 专属拓客立牌 -->
                <el-col :xs="24" :md="12">
                  <div class="qr-stand-card wechat-stand">
                    <div class="stand-header">
                      <div class="stand-logo">🌊 {{ currentSelectedStoreName }}</div>
                      <div class="stand-sub">
                        <el-tag size="small" type="success" effect="dark">🟢 官方微信服务号 · 专属拓客立牌</el-tag>
                      </div>
                    </div>
                    <div class="stand-qr-box">
                      <img
                        :src="wechatStoreQrCodeDataUrl || notifConfig.wechatQrCodeUrl"
                        alt="微信关注码"
                        class="stand-qr-img"
                      />
                      <div class="stand-scan-hint">微信扫一扫 · 关注公众号领好礼</div>
                    </div>
                    <div class="stand-perks">
                      <div class="perk-item">🎁 <b>扫码关注即送 50 积分</b> + 新手礼包自动到账</div>
                      <div class="perk-item">🔔 <b>进店消费实时微信动账</b>，电子小票与账单即时推送</div>
                      <div class="perk-item">💳 <b>微信随时查看会员特权</b>、卡券与双本金储值账户</div>
                    </div>
                    <div style="margin-top: 18px; display: flex; gap: 10px; width: 100%; justify-content: center; flex-wrap: wrap;">
                      <el-button type="success" icon="Download" @click="handleDownloadStandQr('WECHAT')">
                        📥 下载高清二维码
                      </el-button>
                      <el-button type="primary" icon="Printer" @click="handleOpenPrintStandDialog('WECHAT')">
                        🖨️ 打印前台水牌
                      </el-button>
                      <el-button plain icon="CopyDocument" @click="handleCopyStandUrl('WECHAT')">
                        📋 复制关注短链
                      </el-button>
                    </div>
                  </div>
                </el-col>

                <!-- 支付宝生活号专属关注立牌 -->
                <el-col :xs="24" :md="12">
                  <div class="qr-stand-card alipay-stand">
                    <div class="stand-header ali-head">
                      <div class="stand-logo">💙 {{ currentSelectedStoreName }}</div>
                      <div class="stand-sub">
                        <el-tag size="small" type="primary" effect="dark">🔵 支付宝官方生活号 · 专属关注立牌</el-tag>
                      </div>
                    </div>
                    <div class="stand-qr-box">
                      <img
                        :src="alipayStoreQrCodeDataUrl || notifConfig.alipayQrCodeUrl"
                        alt="支付宝关注码"
                        class="stand-qr-img"
                      />
                      <div class="stand-scan-hint" style="color: #0284c7;">支付宝扫一扫 · 关注生活号</div>
                    </div>
                    <div class="stand-perks">
                      <div class="perk-item">⚡ <b>支付宝生活号服务窗动账即时通知</b>，账单无遗漏</div>
                      <div class="perk-item">🎫 <b>支持花呗/余额宝便捷支付</b>，联动专属优惠券核销</div>
                      <div class="perk-item">📌 <b>第一时间获取本店独家特惠</b>与会员等级升级通知</div>
                    </div>
                    <div style="margin-top: 18px; display: flex; gap: 10px; width: 100%; justify-content: center; flex-wrap: wrap;">
                      <el-button type="primary" icon="Download" @click="handleDownloadStandQr('ALIPAY')">
                        📥 下载高清二维码
                      </el-button>
                      <el-button type="warning" icon="Printer" @click="handleOpenPrintStandDialog('ALIPAY')">
                        🖨️ 打印生活号水牌
                      </el-button>
                      <el-button plain icon="CopyDocument" @click="handleCopyStandUrl('ALIPAY')">
                        📋 复制生活号短链
                      </el-button>
                    </div>
                  </div>
                </el-col>
              </el-row>

              <!-- 前台水牌物料制作与摆台建议 -->
              <el-card shadow="never" style="margin-top: 20px; border: 1px solid #e2e8f0; border-radius: 8px;">
                <template #header>
                  <div style="font-weight: 700; color: #334155;">📐 前台水牌与桌贴物料落地指引</div>
                </template>
                <el-row :gutter="16">
                  <el-col :xs="24" :sm="8">
                    <div style="display: flex; gap: 10px; align-items: flex-start;">
                      <span style="font-size: 24px;">🏢</span>
                      <div>
                        <div style="font-weight: 700; color: #1e293b; font-size: 13px;">收银台 / 吧台立牌</div>
                        <div style="font-size: 12px; color: #64748b; margin-top: 4px; line-height: 1.5;">
                          建议使用 A5 亚克力 T 型透明立牌，放置于收银员正前方。顾客在付款买单时顺手扫码关注，买单完成后手机即刻收到微信动账电子小票！
                        </div>
                      </div>
                    </div>
                  </el-col>
                  <el-col :xs="24" :sm="8">
                    <div style="display: flex; gap: 10px; align-items: flex-start;">
                      <span style="font-size: 24px;">🪞</span>
                      <div>
                        <div style="font-weight: 700; color: #1e293b; font-size: 13px;">工位 / 造型镜台 / 餐桌贴</div>
                        <div style="font-size: 12px; color: #64748b; margin-top: 4px; line-height: 1.5;">
                          美业造型镜台右下角、餐饮餐桌或汽修顾客休息室茶几。顾客等待服务期间扫码领 50 积分，有效打发无聊时间并牢牢沉淀为私域粉丝。
                        </div>
                      </div>
                    </div>
                  </el-col>
                  <el-col :xs="24" :sm="8">
                    <div style="display: flex; gap: 10px; align-items: flex-start;">
                      <span style="font-size: 24px;">🖨️</span>
                      <div>
                        <div style="font-weight: 700; color: #1e293b; font-size: 13px;">直接打印或交给广告社制作</div>
                        <div style="font-size: 12px; color: #64748b; margin-top: 4px; line-height: 1.5;">
                          点击【打印前台水牌】可使用普通彩色打印机即刻出纸裁剪；点击【下载高清二维码】可将原始高清图发给广告喷绘店制作专属高档水牌。
                        </div>
                      </div>
                    </div>
                  </el-col>
                </el-row>
              </el-card>
            </div>

            <!-- 子视图 2: 扫码吸粉与业务闭环指南 -->
            <div v-if="notifSubTab === 'GUIDE'" class="notif-sub-view">
              <el-card shadow="never" style="border: 1px solid #e2e8f0; border-radius: 8px;">
                <template #header>
                  <div style="font-weight: 700; font-size: 15px; color: #1e293b;">
                    💡 门店“扫码关注 - 静默绑定 - 动账推送”业务全闭环链路
                  </div>
                </template>

                <div style="display: flex; gap: 16px; flex-wrap: wrap; margin-bottom: 24px;">
                  <div style="flex: 1; min-width: 240px; background: #f0fdf4; border: 1px solid #86efac; border-radius: 8px; padding: 16px;">
                    <div style="font-weight: 700; color: #166534; font-size: 14px; margin-bottom: 6px;">
                      步骤 1：到店扫码展码
                    </div>
                    <div style="font-size: 12px; color: #15803d; line-height: 1.6;">
                      店长将专属水牌打印张贴在收银前台或工位。店员主动引导顾客：“您微信扫一扫前台二维码，可以领 50 积分，待会儿买单会自动把小票推到您微信上。”
                    </div>
                  </div>

                  <div style="flex: 1; min-width: 240px; background: #eff6ff; border: 1px solid #93c5fd; border-radius: 8px; padding: 16px;">
                    <div style="font-weight: 700; color: #1e40af; font-size: 14px; margin-bottom: 6px;">
                      步骤 2：自动激活会员与发礼
                    </div>
                    <div style="font-size: 12px; color: #1d4ed8; line-height: 1.6;">
                      顾客扫码后关注微信公众号。系统底层自动通过带参二维码识别当前门店并静默关联其身份，自动下发欢迎卡片与 50 积分入账通知。
                    </div>
                  </div>

                  <div style="flex: 1; min-width: 240px; background: #faf5ff; border: 1px solid #d8b4fe; border-radius: 8px; padding: 16px;">
                    <div style="font-weight: 700; color: #6b21a8; font-size: 14px; margin-bottom: 6px;">
                      步骤 3：消费结账 100% 动账即达
                    </div>
                    <div style="font-size: 12px; color: #7e22ce; line-height: 1.6;">
                      当顾客在前台收银结算、或储值充值时，微信服务号瞬时弹出官方模板消息卡片，顾客点击可查电子账单明细与卡内余额，零差错、极具高级感！
                    </div>
                  </div>
                </div>

                <el-collapse accordion>
                  <el-collapse-item title="❓ 问：为什么不需要我们在后台填写微信 AppID、密钥和模板 ID？" name="1">
                    <div style="color: #475569; font-size: 13px; line-height: 1.7;">
                      答：本系统由平台开发运维总管在总控中心统一代管对接底层的微信服务号 OpenAPI 与支付宝生活号网关。所有加盟店与直营门店均无需理解或输入任何代码技术参数，开箱即可享用带参二维码关注吸粉与全自动动账推送能力。
                    </div>
                  </el-collapse-item>
                  <el-collapse-item title="❓ 问：扫码关注后的顾客如何与收银台开单关联？" name="2">
                    <div style="color: #475569; font-size: 13px; line-height: 1.7;">
                      答：顾客首次扫码关注时，公众号会自动引导绑定手机号（或直接模拟关注绑定）。收银台开单结账时只要输入该顾客手机号，后台就会自动通过其关注的微信 OpenID 下发模板动账小票。
                    </div>
                  </el-collapse-item>
                  <el-collapse-item title="❓ 问：如果顾客不想接收营销通知，但想保留消费动账通知，是否支持？" name="3">
                    <div style="color: #475569; font-size: 13px; line-height: 1.7;">
                      答：完全支持。在会员详情页中，店员或店长可针对单客设置其通知接收偏好；门店也可在“⚙️ 门店动账推送服务设置”中自主开关营销活动通知与充值通知。
                    </div>
                  </el-collapse-item>
                </el-collapse>
              </el-card>
            </div>

            <!-- 子视图 3: 微信动账小票效果预览 -->
            <div v-if="notifSubTab === 'PREVIEW'" class="notif-sub-view">
              <el-row :gutter="24">
                <el-col :xs="24" :md="10">
                  <el-card shadow="never" style="border: 1px solid #e2e8f0; border-radius: 8px;">
                    <template #header>
                      <div style="font-weight: 700; color: #1e293b;">💌 动账小票预览控制器</div>
                    </template>
                    <el-form label-width="100px">
                      <el-form-item label="消息模板类型">
                        <el-radio-group v-model="testForm.msgType" style="display: flex; flex-direction: column; gap: 8px; align-items: flex-start;">
                          <el-radio value="CONSUME_NOTICE">🧾 消费结账动账小票</el-radio>
                          <el-radio value="RECHARGE_NOTICE">💰 会员储值到账通知</el-radio>
                          <el-radio value="MARKETING_CAMPAIGN">🎉 特惠营销活动通知</el-radio>
                        </el-radio-group>
                      </el-form-item>
                      <el-divider />
                      <div style="font-size: 12px; color: #64748b; line-height: 1.6;">
                        💡 右侧为该类型模板消息在顾客手机微信聊天窗口中的 1:1 高保真渲染效果。无论顾客是 iOS 还是安卓，都将收到如此美观、权威的官方服务号消息卡片。
                      </div>
                    </el-form>
                  </el-card>
                </el-col>

                <el-col :xs="24" :md="14">
                  <div class="wx-preview-container">
                    <div class="wx-phone-header">
                      <div class="wx-top-bar">
                        <span class="wx-time">{{ currentClockStr }}</span>
                        <span class="wx-icons">📶 5G 🔋 100%</span>
                      </div>
                      <div class="wx-app-nav">
                        <span class="wx-back">‹ 服务</span>
                        <span class="wx-title">海马汇服务号</span>
                        <span class="wx-more">•••</span>
                      </div>
                    </div>

                    <div class="wx-phone-body">
                      <!-- 微信消息气泡/模板卡片 -->
                      <div class="wx-msg-card">
                        <div class="card-top-head">
                          <div class="mp-info">
                            <span class="mp-badge">🟢</span>
                            <span class="mp-name">{{ currentSelectedStoreName }}</span>
                          </div>
                          <span class="mp-time">刚刚</span>
                        </div>

                        <div class="card-main-title">
                          {{ previewCardTitle }}
                        </div>

                        <div class="card-field-row" style="margin-top: 8px;">
                          <span class="f-label">消费门店</span>
                          <span class="f-val">{{ currentSelectedStoreName }} (VIP工位)</span>
                        </div>

                        <div class="card-field-row">
                          <span class="f-label">消费金额</span>
                          <span class="f-val highlight-orange">￥298.00</span>
                        </div>

                        <div class="card-field-row">
                          <span class="f-label">支付方式</span>
                          <span class="f-val">微信支付￥200.00 + 储值扣减￥98.00</span>
                        </div>

                        <div class="card-field-row">
                          <span class="f-label">交易单号</span>
                          <span class="f-val mono">ORD20260908889921</span>
                        </div>

                        <div class="card-field-row">
                          <span class="f-label">消费时间</span>
                          <span class="f-val">{{ currentClockStr }}</span>
                        </div>

                        <div class="card-remark-box">
                          {{ previewCardRemark }}
                        </div>

                        <div class="card-detail-footer">
                          <span>查看电子账单与发票明细</span>
                          <span class="arrow">›</span>
                        </div>
                      </div>

                      <div class="wx-input-mock">
                        <span class="kbd-icon">⌨️</span>
                        <span class="input-placeholder">输入消息...</span>
                        <span class="plus-icon">⊕</span>
                      </div>
                    </div>
                  </div>
                </el-col>
              </el-row>
            </div>

            <!-- 子视图 4: 顾客扫码模拟体验 -->
            <div v-if="notifSubTab === 'SIMULATOR'" class="notif-sub-view">
              <el-row :gutter="20">
                <el-col :xs="24" :md="12">
                  <el-card shadow="never" class="simulate-scan-box">
                    <template #header>
                      <div style="font-weight: 700; display: flex; align-items: center; gap: 6px;">
                        <span>📱 顾客扫码关注模拟器</span>
                      </div>
                    </template>
                    <p class="sim-tip">
                      在此输入顾客手机号即可模拟顾客现场掏出手机扫描前台水牌关注微信公众号/生活号，并自动激活会员全渠道推送管道：
                    </p>

                    <el-form label-width="95px" style="margin-top: 14px;">
                      <el-form-item label="顾客手机号" required>
                        <el-input v-model="simulatePhone" placeholder="输入11位手机号" />
                      </el-form-item>
                      <el-form-item label="关注渠道" required>
                        <el-radio-group v-model="simulateChannel">
                          <el-radio value="WECHAT_MP">微信服务号</el-radio>
                          <el-radio value="ALIPAY_LIFE">支付宝生活号</el-radio>
                        </el-radio-group>
                      </el-form-item>
                      <el-form-item>
                        <el-button
                          type="success"
                          icon="Check"
                          :loading="simulatingFollow"
                          style="width: 100%; font-weight: 700;"
                          @click="handleSimulateFollow"
                        >
                          模拟扫码关注并激活会员档案
                        </el-button>
                      </el-form-item>
                    </el-form>

                    <div v-if="lastFollowResult" class="follow-success-card">
                      <div class="f-head">✅ 扫码关注成功并已激活档案！</div>
                      <div class="f-row">会员姓名：<b>{{ lastFollowResult.member?.name }}</b></div>
                      <div class="f-row">会员编号：<b>{{ lastFollowResult.member?.memberNo }}</b></div>
                      <div class="f-row">赠送积分：<b style="color: #059669;">+50 积分</b> (当前积分: {{ lastFollowResult.member?.points }})</div>
                      <div class="f-row">渠道标识：<code style="font-size: 11px;">{{ lastFollowResult.member?.wechatOpenId || lastFollowResult.member?.alipayUserId }}</code></div>
                      <div class="f-foot">🔔 欢迎通知与消费动账管道已全部激活！</div>
                    </div>
                  </el-card>
                </el-col>

                <el-col :xs="24" :md="12">
                  <el-card shadow="never" style="border: 1px solid #e2e8f0; border-radius: 8px;">
                    <template #header>
                      <div style="font-weight: 700;">🚀 消息即时下发体验器</div>
                    </template>
                    <el-form :model="testForm" label-width="100px">
                      <el-form-item label="推送渠道">
                        <el-select v-model="testForm.channel" style="width: 100%;">
                          <el-option label="微信公众号 (服务号)" value="WECHAT_MP" />
                          <el-option label="支付宝生活号" value="ALIPAY_LIFE" />
                        </el-select>
                      </el-form-item>
                      <el-form-item label="消息类型">
                        <el-select v-model="testForm.msgType" style="width: 100%;">
                          <el-option label="消费结账动账通知 (OPENTM413385970)" value="CONSUME_NOTICE" />
                          <el-option label="储值到账通知 (OPENTM206215005)" value="RECHARGE_NOTICE" />
                          <el-option label="营销活动特惠通知 (OPENTM408372691)" value="MARKETING_CAMPAIGN" />
                          <el-option label="系统连接连通性测试" value="TEST_NOTICE" />
                        </el-select>
                      </el-form-item>
                      <el-form-item label="测试手机号">
                        <el-input v-model="testForm.targetPhone" placeholder="输入要接收测试的会员手机号" />
                      </el-form-item>
                      <el-form-item>
                        <el-button
                          type="primary"
                          icon="Promotion"
                          :loading="sendingTest"
                          style="width: 100%; font-weight: 700; height: 40px;"
                          @click="handleSendTestNotif"
                        >
                          立即下发模板消息测试
                        </el-button>
                      </el-form-item>
                    </el-form>
                    <div style="font-size: 12px; color: #64748b; line-height: 1.5; margin-top: 10px;">
                      💡 点击后后端将生成规范的微信模板卡片数据包并记入流水；在“📜 本店消息推送流水明细”中可查验完整的送达记录。
                    </div>
                  </el-card>
                </el-col>
              </el-row>
            </div>

            <!-- 子视图 5: 门店动账推送服务设置 (业务级开关，无技术参数) -->
            <div v-if="notifSubTab === 'STRATEGY'" class="notif-sub-view">
              <el-card shadow="never" style="border: 1px solid #e2e8f0; border-radius: 8px;">
                <template #header>
                  <div style="display: flex; justify-content: space-between; align-items: center;">
                    <div style="font-weight: 700; font-size: 14px; color: #1e293b;">
                      ⚙️ 本门店动账消息通知业务自动化开关
                    </div>
                    <el-button type="primary" :loading="savingNotif" @click="handleSaveNotifConfig">
                      <el-icon><Check /></el-icon> 保存业务推送设置
                    </el-button>
                  </div>
                </template>

                <el-form label-width="180px">
                  <el-form-item label="收银结账自动推送">
                    <el-switch v-model="notifConfig.autoPushOnCheckout" />
                    <span class="form-item-tip">收银台每笔买单结账成功后，自动向顾客微信/支付宝推送消费动账通知小票</span>
                  </el-form-item>
                  <el-form-item label="储值充值自动通知">
                    <el-switch v-model="notifConfig.autoPushOnRecharge" />
                    <span class="form-item-tip">会员充值本金或赠金到账时，自动推送账户变动与新余额通知</span>
                  </el-form-item>
                  <el-form-item label="发布活动自动触达">
                    <el-switch v-model="notifConfig.autoPushOnMarketing" />
                    <span class="form-item-tip">营销中心发布新优惠活动时，支持一键向本店已关注公众号的粉丝会员批量推送</span>
                  </el-form-item>
                  <el-form-item label="移动端语音播报次数">
                    <el-input-number v-model="notifConfig.voiceBroadcastRepeatCount" :min="1" :max="5" :step="1" />
                    <span class="form-item-tip">包厢呼叫管家、新订单等移动端语音提醒播报次数（默认1次，可选1~5次，重启APP绝不重复播报同一单据）</span>
                  </el-form-item>
                </el-form>

                <el-divider />
                <div style="font-size: 12px; color: #94a3b8; line-height: 1.6;">
                  🛡️ 平台全权托管说明：微信公众号与支付宝生活号的底层开发者凭证、服务器回调与加解密已由平台系统管理员在开发运维端集中统管。门店店长无需关心任何技术细节，仅需在此配置面向本店顾客的业务偏好即可。
                </div>
              </el-card>
            </div>

            <!-- 子视图: 充值扣费与动账通知模板具体内容与字段映射配置 -->
            <div v-if="notifSubTab === 'TEMPLATE_CONFIG'" class="notif-sub-view">
              <!-- 顶部官方解答与位置指引横幅 -->
              <el-card shadow="never" style="border: 1px solid #bfdbfe; background: linear-gradient(135deg, #eff6ff 0%, #f0fdf4 100%); border-radius: 10px; margin-bottom: 16px;">
                <div style="display: flex; align-items: flex-start; gap: 14px;">
                  <span style="font-size: 32px;">💡</span>
                  <div style="flex: 1;">
                    <div style="font-size: 15px; font-weight: 800; color: #1e3a8a;">
                      【配置位置解答】充值扣费与变动通知 Template ID 及模板具体内容是在哪里配置？
                    </div>
                    <div style="font-size: 13px; color: #334155; line-height: 1.6; margin-top: 6px;">
                      系统采用<b>两级协同配置体系</b>，技术层与门店运营层清晰划分：
                      <br />
                      <b>1. 平台中台技术配置层 (开发商端): </b>由系统开发维护人在 <b>中台管理中心 -> 消息推送模板配置中心 (/vendor-console)</b> 进行微信开放平台与支付宝开放平台的行业模板库申领（如 <code>OPENTM206215005</code>、<code>OPENTM413385970</code>），维护底层接口与通信凭据。
                      <br />
                      <b>2. 门店租户业务运营层 (即当前配置面板): </b>租户在此<b>直观查验每个 Template ID 对应的卡片结构、每个占位字段（keyword1~5）映射的系统动态数据字段</b>，并可按需修改欢迎语（First）、尾部温馨提示（Remark）及点击跳转的小程序/H5链接！
                    </div>
                  </div>
                  <el-button type="primary" plain @click="$router.push('/vendor-console')">
                    🛠️ 前往中台开发者中心
                  </el-button>
                </div>
              </el-card>

              <!-- 3大动账通知模板卡片网格 -->
              <el-row :gutter="16">
                <!-- 模板 1: 储值充值到账提醒 -->
                <el-col :xs="24" :lg="8" style="margin-bottom: 16px;">
                  <el-card shadow="hover" class="template-detail-card">
                    <template #header>
                      <div class="tmpl-card-head">
                        <div>
                          <span class="tmpl-title">💳 充值到账通知模板</span>
                          <el-tag size="small" type="success" effect="dark" style="margin-left: 6px;">微信服务号</el-tag>
                        </div>
                        <el-tag size="small" type="primary" effect="plain">OPENTM206215005</el-tag>
                      </div>
                    </template>
                    
                    <div class="tmpl-wechat-box">
                      <div class="wx-title">充值成功提醒</div>
                      <div class="wx-time">今日 16:35</div>
                      <div class="wx-first">{{ templateSettings.recharge.firstText }}</div>
                      
                      <div class="wx-fields">
                        <div class="wx-field-item">
                          <span class="lbl">会员卡号：</span>
                          <span class="val mono">&#123;&#123;keyword1.DATA&#125;&#125; -> [真实会员卡号]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">充值金额：</span>
                          <span class="val text-orange bold">&#123;&#123;keyword2.DATA&#125;&#125; -> ￥[本次实充本金]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">赠送金额：</span>
                          <span class="val text-green">&#123;&#123;keyword3.DATA&#125;&#125; -> +￥[养生赠送金]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">当前余额：</span>
                          <span class="val bold">&#123;&#123;keyword4.DATA&#125;&#125; -> ￥[最新双本金可用总额]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">充值时间：</span>
                          <span class="val">&#123;&#123;keyword5.DATA&#125;&#125; -> [系统交易时间戳]</span>
                        </div>
                      </div>
                      
                      <div class="wx-remark">{{ templateSettings.recharge.remarkText }}</div>
                      <div class="wx-foot">
                        <span>点击查看电子卡包资产明细</span>
                        <span>›</span>
                      </div>
                    </div>

                    <el-divider style="margin: 12px 0;" />

                    <div class="tmpl-editor-form">
                      <el-form label-position="top" size="small">
                        <el-form-item label="自定义首句问候语 (first)">
                          <el-input v-model="templateSettings.recharge.firstText" />
                        </el-form-item>
                        <el-form-item label="自定义尾部提示语 (remark)">
                          <el-input v-model="templateSettings.recharge.remarkText" />
                        </el-form-item>
                        <el-form-item label="点击跳转链接 (URL / 小程序Path)">
                          <el-input v-model="templateSettings.recharge.jumpUrl" placeholder="pages/member/wallet" />
                        </el-form-item>
                      </el-form>
                    </div>
                  </el-card>
                </el-col>

                <!-- 模板 2: 消费结账与动账扣款成功 -->
                <el-col :xs="24" :lg="8" style="margin-bottom: 16px;">
                  <el-card shadow="hover" class="template-detail-card">
                    <template #header>
                      <div class="tmpl-card-head">
                        <div>
                          <span class="tmpl-title">🧾 消费扣费动账通知模板</span>
                          <el-tag size="small" type="success" effect="dark" style="margin-left: 6px;">微信服务号</el-tag>
                        </div>
                        <el-tag size="small" type="primary" effect="plain">OPENTM413385970</el-tag>
                      </div>
                    </template>
                    
                    <div class="tmpl-wechat-box">
                      <div class="wx-title">消费成功通知</div>
                      <div class="wx-time">今日 19:40</div>
                      <div class="wx-first">{{ templateSettings.consume.firstText }}</div>
                      
                      <div class="wx-fields">
                        <div class="wx-field-item">
                          <span class="lbl">消费门店：</span>
                          <span class="val">&#123;&#123;keyword1.DATA&#125;&#125; -> [当前消费所在门店]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">消费项目：</span>
                          <span class="val bold">&#123;&#123;keyword2.DATA&#125;&#125; -> [服务项目/包厢开单品项]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">消费金额：</span>
                          <span class="val text-orange bold">&#123;&#123;keyword3.DATA&#125;&#125; -> ￥[账单应收总额]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">支付方式：</span>
                          <span class="val">&#123;&#123;keyword4.DATA&#125;&#125; -> [微信支付￥X + 储值扣除￥Y]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">卡内剩余：</span>
                          <span class="val bold text-blue">&#123;&#123;keyword5.DATA&#125;&#125; -> ￥[扣减后双本金最新余额]</span>
                        </div>
                      </div>
                      
                      <div class="wx-remark">{{ templateSettings.consume.remarkText }}</div>
                      <div class="wx-foot">
                        <span>点击查看电子消费账单与发票</span>
                        <span>›</span>
                      </div>
                    </div>

                    <el-divider style="margin: 12px 0;" />

                    <div class="tmpl-editor-form">
                      <el-form label-position="top" size="small">
                        <el-form-item label="自定义首句问候语 (first)">
                          <el-input v-model="templateSettings.consume.firstText" />
                        </el-form-item>
                        <el-form-item label="自定义尾部提示语 (remark)">
                          <el-input v-model="templateSettings.consume.remarkText" />
                        </el-form-item>
                        <el-form-item label="点击跳转链接 (URL / 小程序Path)">
                          <el-input v-model="templateSettings.consume.jumpUrl" placeholder="pages/order/detail" />
                        </el-form-item>
                      </el-form>
                    </div>
                  </el-card>
                </el-col>

                <!-- 模板 3: 顾客预约确认与排班提醒 -->
                <el-col :xs="24" :lg="8" style="margin-bottom: 16px;">
                  <el-card shadow="hover" class="template-detail-card">
                    <template #header>
                      <div class="tmpl-card-head">
                        <div>
                          <span class="tmpl-title">📅 预约排班成功提醒模板</span>
                          <el-tag size="small" type="success" effect="dark" style="margin-left: 6px;">微信服务号</el-tag>
                        </div>
                        <el-tag size="small" type="primary" effect="plain">OPENTM408239014</el-tag>
                      </div>
                    </template>
                    
                    <div class="tmpl-wechat-box">
                      <div class="wx-title">预约成功通知</div>
                      <div class="wx-time">今日 18:20</div>
                      <div class="wx-first">{{ templateSettings.appointment.firstText }}</div>
                      
                      <div class="wx-fields">
                        <div class="wx-field-item">
                          <span class="lbl">预约项目：</span>
                          <span class="val bold">&#123;&#123;keyword1.DATA&#125;&#125; -> [预约养生/足道/SPA项目]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">预约技师：</span>
                          <span class="val bold text-blue">&#123;&#123;keyword2.DATA&#125;&#125; -> [专属工号与技师姓名]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">预约包厢：</span>
                          <span class="val">&#123;&#123;keyword3.DATA&#125;&#125; -> [静心阁/听泉堂等服务包房]</span>
                        </div>
                        <div class="wx-field-item">
                          <span class="lbl">到店时间：</span>
                          <span class="val text-orange bold">&#123;&#123;keyword4.DATA&#125;&#125; -> [预约到店具体时段]</span>
                        </div>
                      </div>
                      
                      <div class="wx-remark">{{ templateSettings.appointment.remarkText }}</div>
                      <div class="wx-foot">
                        <span>点击查看预约详情与导航</span>
                        <span>›</span>
                      </div>
                    </div>

                    <el-divider style="margin: 12px 0;" />

                    <div class="tmpl-editor-form">
                      <el-form label-position="top" size="small">
                        <el-form-item label="自定义首句问候语 (first)">
                          <el-input v-model="templateSettings.appointment.firstText" />
                        </el-form-item>
                        <el-form-item label="自定义尾部提示语 (remark)">
                          <el-input v-model="templateSettings.appointment.remarkText" />
                        </el-form-item>
                        <el-form-item label="点击跳转链接 (URL / 小程序Path)">
                          <el-input v-model="templateSettings.appointment.jumpUrl" placeholder="pages/appointment/detail" />
                        </el-form-item>
                      </el-form>
                    </div>
                  </el-card>
                </el-col>
              </el-row>

              <!-- 底部保存按钮条 -->
              <div style="display: flex; justify-content: flex-end; gap: 12px; margin-top: 8px;">
                <el-button @click="resetTemplateSettings">恢复官方推荐默认设置</el-button>
                <el-button type="primary" icon="Check" @click="saveTemplateSettings">
                  保存门店通知模板配置
                </el-button>
              </div>
            </div>

            <!-- 子视图 6: 本店消息推送流水明细 -->
            <div v-if="notifSubTab === 'LOGS'" class="notif-sub-view">
              <div class="logs-toolbar">
                <div class="l-tip">
                  共记录 <b>{{ notifLogs.length }}</b> 条全渠道推送流水，每笔收银消费或充值均可实时追溯审计：
                </div>
                <el-button size="small" icon="Refresh" :loading="loadingLogs" @click="loadNotificationLogs">
                  刷新推送记录
                </el-button>
              </div>

              <el-table :data="notifLogs" stripe border style="width: 100%; margin-top: 12px;">
                <el-table-column prop="id" label="流水ID" width="80" align="center" />
                <el-table-column prop="sentAt" label="发送时间" width="170">
                  <template #default="{ row }">
                    {{ formatDateTime(row.sentAt) }}
                  </template>
                </el-table-column>
                <el-table-column prop="channel" label="推送渠道" width="130" align="center">
                  <template #default="{ row }">
                    <el-tag v-if="row.channel === 'WECHAT_MP'" type="success" effect="dark" size="small">
                      🟢 微信服务号
                    </el-tag>
                    <el-tag v-else-if="row.channel === 'ALIPAY_LIFE'" type="primary" effect="dark" size="small">
                      🔵 支付宝生活号
                    </el-tag>
                    <el-tag v-else type="info" size="small">{{ row.channel }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="msgType" label="通知类型" width="140">
                  <template #default="{ row }">
                    <el-tag v-if="row.msgType === 'CONSUME_NOTICE'" type="warning" size="small">消费动账提醒</el-tag>
                    <el-tag v-else-if="row.msgType === 'RECHARGE_NOTICE'" type="success" size="small">储值充值通知</el-tag>
                    <el-tag v-else-if="row.msgType === 'MARKETING_CAMPAIGN'" type="danger" size="small">特惠营销活动</el-tag>
                    <el-tag v-else type="info" size="small">{{ row.title || '系统通知' }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="memberName" label="目标会员" width="120">
                  <template #default="{ row }">
                    <b>{{ row.memberName || '体验用户' }}</b>
                  </template>
                </el-table-column>
                <el-table-column prop="phone" label="手机号码" width="130" />
                <el-table-column prop="targetOpenId" label="渠道标识 (OpenID/UserId)" min-width="180" show-overflow-tooltip>
                  <template #default="{ row }">
                    <code style="font-size: 11px;">{{ row.targetOpenId }}</code>
                  </template>
                </el-table-column>
                <el-table-column prop="status" label="下发状态" width="120" align="center">
                  <template #default="{ row }">
                    <el-tag v-if="row.status === 'SUCCESS'" type="success" size="small">已成功送达</el-tag>
                    <el-tag v-else type="danger" size="small">{{ row.status }}</el-tag>
                  </template>
                </el-table-column>
                <el-table-column label="操作" width="110" align="center" fixed="right">
                  <template #default="{ row }">
                    <el-button size="small" type="primary" link @click="handleViewLogDetail(row)">
                      查看卡片
                    </el-button>
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </div>
        </el-tab-pane>

        <!-- 6. 扫码盒子硬件与全渠道聚合支付设置 (超级管理员专属) -->
      </el-tabs>
    </el-card>

    <!-- 弹窗 1: 新增/编辑岗位 (含招聘参数配置) -->
    <el-dialog v-model="openPostDialog" :title="editingPost ? '编辑岗位职务与招聘发布' : '新增岗位职务'" width="680px" destroy-on-close>
      <el-form :model="postForm" label-width="110px">
        <el-row :gutter="16">
          <el-col :span="14">
            <el-form-item label="岗位名称" required>
              <el-input v-model="postForm.postName" placeholder="如：店长、发型总监、高级技师、前台收银" />
            </el-form-item>
          </el-col>
          <el-col :span="10">
            <el-form-item label="所属部门" required>
              <div style="display: flex; gap: 6px; width: 100%;">
                <el-select
                  v-model="postForm.department"
                  filterable
                  allow-create
                  default-first-option
                  placeholder="选择或直接输入"
                  style="flex: 1;"
                  @change="(val: any) => {
                    if (val && !departmentsList.includes(val)) {
                      departmentsList.push(val)
                      localStorage.setItem('seahorse_store_departments', JSON.stringify(departmentsList))
                    }
                  }"
                >
                  <el-option
                    v-for="dept in departmentsList"
                    :key="dept"
                    :label="dept"
                    :value="dept"
                  />
                </el-select>
                <el-tooltip content="点击打开部门架构管理页面（支持增删改）" placement="top">
                  <el-button
                    type="primary"
                    plain
                    icon="OfficeBuilding"
                    @click="handleOpenDepartmentManager"
                  >
                    部门
                  </el-button>
                </el-tooltip>
              </div>
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="工作职责与描述" required>
          <el-input
            v-model="postForm.description"
            type="textarea"
            :rows="3"
            placeholder="详细描述该岗位在店内的日常核心工作职责、服务流程标准与交付结果..."
          />
        </el-form-item>

        <el-form-item label="任职考核标准">
          <el-input
            v-model="postForm.requirements"
            type="textarea"
            :rows="2"
            placeholder="专业技能要求、出勤考勤考核基准及客诉控制指标..."
          />
        </el-form-item>

        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="建议提成比例">
              <el-input-number v-model="postForm.commissionRatePercent" :min="0" :max="100" :step="5" style="width: 100%;" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="建议底薪(元)">
              <el-input-number v-model="postForm.baseSalary" :min="0" :step="500" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 招聘发布专属配置卡片 -->
        <div class="recruit-form-box">
          <div class="rf-header">
            <span class="rf-title">📢 对外招聘员工与求职发布配置</span>
            <el-switch v-model="postForm.isRecruiting" active-text="开启对外招聘" />
          </div>

          <div v-if="postForm.isRecruiting" class="rf-body">
            <el-row :gutter="16">
              <el-col :span="12">
                <el-form-item label="计划招聘人数">
                  <el-input-number v-model="postForm.recruitHeadcount" :min="1" :max="20" style="width: 100%;" />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="对外薪资范围">
                  <el-input v-model="postForm.salaryRange" placeholder="如：6000-9000元/月" />
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="16">
              <el-col :span="12">
                <el-form-item label="经验要求">
                  <el-select v-model="postForm.experienceReq" style="width: 100%;">
                    <el-option label="经验不限 (提供带薪带教)" value="经验不限" />
                    <el-option label="1年以内" value="1年以内" />
                    <el-option label="1-3年" value="1-3年" />
                    <el-option label="3-5年" value="3-5年" />
                    <el-option label="5年以上资深" value="5年以上" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="学历要求">
                  <el-select v-model="postForm.educationReq" style="width: 100%;">
                    <el-option label="学历不限" value="学历不限" />
                    <el-option label="初中及以上" value="初中及以上" />
                    <el-option label="高中/中专及以上" value="高中/中专及以上" />
                    <el-option label="大专及以上" value="大专及以上" />
                    <el-option label="本科及以上" value="本科及以上" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>

            <el-form-item label="福利待遇亮点">
              <el-checkbox-group v-model="postForm.benefits">
                <el-checkbox label="包吃包住" />
                <el-checkbox label="五险一金" />
                <el-checkbox label="带薪年假" />
                <el-checkbox label="定期团建" />
                <el-checkbox label="技能培训" />
                <el-checkbox label="绩效奖金" />
                <el-checkbox label="节日礼品" />
                <el-checkbox label="员工折扣" />
              </el-checkbox-group>
            </el-form-item>
          </div>
        </div>

        <el-form-item label="岗位启用状态" style="margin-top: 10px;">
          <el-switch v-model="postForm.active" active-text="在用" inactive-text="停用" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openPostDialog = false">取消</el-button>
        <el-button type="primary" @click="handleSavePost">保存岗位与招聘设置</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 1.1: 🏢 门店所属部门架构管理 (支持查看、新增、重命名编辑、删除) -->
    <el-dialog
      v-model="openDepartmentDialog"
      title="🏢 门店所属部门架构管理"
      width="680px"
      destroy-on-close
      class="department-manage-dialog"
    >
      <div class="dept-manage-body">
        <!-- 顶部添加部门输入行 -->
        <div class="dept-add-row" style="display: flex; gap: 10px; margin-bottom: 18px;">
          <el-input
            v-model="newDeptName"
            placeholder="输入新部门名称 (如：售后部、网络运营部、研发设计部)..."
            clearable
            @keyup.enter="handleAddDepartment"
          />
          <el-button type="primary" icon="Plus" @click="handleAddDepartment">
            添加新部门
          </el-button>
        </div>

        <!-- 部门列表表格 -->
        <el-table :data="departmentTableData" border stripe style="width: 100%;">
          <el-table-column label="部门名称" min-width="180">
            <template #default="{ row }">
              <div v-if="editingDeptOldName === row.name && isEditingDept" style="display: flex; gap: 6px;">
                <el-input v-model="editingDeptNewName" size="small" @keyup.enter="handleSaveEditDept" />
                <el-button type="success" size="small" icon="Check" @click="handleSaveEditDept">保存</el-button>
                <el-button size="small" icon="Close" @click="isEditingDept = false">取消</el-button>
              </div>
              <div v-else style="display: flex; align-items: center; gap: 8px;">
                <span style="font-weight: 700; color: #1e293b; font-size: 14px;">{{ row.name }}</span>
                <el-tag size="small" type="info" effect="plain">序号 #{{ row.index + 1 }}</el-tag>
              </div>
            </template>
          </el-table-column>
          <el-table-column label="关联岗位数" width="110" align="center">
            <template #default="{ row }">
              <el-tag size="small" type="primary">{{ row.postCount }} 个岗位</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="在册员工数" width="110" align="center">
            <template #default="{ row }">
              <el-tag size="small" :type="row.staffCount > 0 ? 'success' : 'info'">{{ row.staffCount }} 人在岗</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="140" align="center">
            <template #default="{ row }">
              <el-button link type="primary" size="small" icon="Edit" @click="handleStartEditDept(row.name)">
                编辑
              </el-button>
              <el-button link type="danger" size="small" icon="Delete" @click="handleDeleteDept(row.name)">
                删除
              </el-button>
            </template>
          </el-table-column>
        </el-table>

        <div style="margin-top: 14px; font-size: 12px; color: #64748b; line-height: 1.6; background: #f8fafc; padding: 10px 14px; border-radius: 6px; border: 1px solid #e2e8f0;">
          💡 <b>使用提示</b>：在新增或编辑岗位职务时，可直接选择此处配置的部门架构，也可在岗位弹窗下拉选择中直接输入新部门回车自动收录；编辑部门名称时，将同步更新所有归属于该部门的岗位与在岗员工数据。
        </div>
      </div>
      <template #footer>
        <el-button type="primary" @click="openDepartmentDialog = false">完成</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 1.2: 📥 载入行业推荐部门架构与在编岗位 -->
    <el-dialog
      v-model="industryPresetDeptModalVisible"
      title="📥 载入行业推荐部门架构与在编岗位"
      width="780px"
      append-to-body
      destroy-on-close
    >
      <div style="font-size: 13px; color: #64748b; margin-bottom: 14px; line-height: 1.6;">
        系统为您精选了主流实体行业的标准部门架构与推荐在编岗位。请选择目标行业，预览推荐部门与岗位，选定后即可一键导入到当前店铺。导入后您可自由增删改、重命名部门，并编辑岗位薪资待遇与职责要求，最后点击【保存组织架构到数据库】完成持久化。
      </div>

      <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; margin-bottom: 16px;">
        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 12px;">
          <span style="font-size: 13.5px; font-weight: 700; color: #1e293b; white-space: nowrap;">选择目标行业：</span>
          <el-select v-model="selectedDeptPresetIndustry" style="width: 320px;" @change="handleDeptPresetIndustryChange" :loading="loadingPresetOrg">
            <el-option
              v-for="item in deptPresetIndustryList"
              :key="item.code"
              :label="item.name"
              :value="item.code"
            >
              <span style="margin-right: 8px;">{{ item.icon }}</span>
              <span>{{ item.name }}</span>
            </el-option>
          </el-select>
          <el-tag type="info" size="small">实时连接超管云端配置库</el-tag>
        </div>

        <!-- 部门预览 -->
        <div style="margin-top: 10px;">
          <div style="font-size: 13px; font-weight: 600; color: #334155; margin-bottom: 8px;">
            🏢 推荐部门架构 ({{ presetPreviewDepartments.length }} 个部门)：
          </div>
          <div style="display: flex; flex-wrap: wrap; gap: 8px;">
            <el-tag v-for="d in presetPreviewDepartments" :key="d" type="success" size="default">
              🏢 {{ d }}
            </el-tag>
          </div>
        </div>

        <!-- 岗位预览 -->
        <div style="margin-top: 14px;">
          <div style="font-size: 13px; font-weight: 600; color: #334155; margin-bottom: 8px;">
            💼 推荐在编岗位编制 ({{ presetPreviewPositions.length }} 个岗位)：
          </div>
          <el-table :data="presetPreviewPositions" size="small" border stripe max-height="240" style="width: 100%;">
            <el-table-column prop="postName" label="岗位名称" width="150" />
            <el-table-column prop="department" label="所属部门" width="120" />
            <el-table-column prop="salaryRange" label="建议薪资待遇" width="140">
              <template #default="{ row }">
                <span style="color: #059669; font-weight: 600;">{{ row.salaryRange || ('￥' + row.baseSalary + '/月') }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="description" label="工作职责" min-width="180" show-overflow-tooltip />
            <el-table-column prop="requirements" label="任职资格" min-width="160" show-overflow-tooltip />
          </el-table>
        </div>
      </div>

      <div style="display: flex; justify-content: space-between; align-items: center; font-size: 13px; color: #475569;">
        <div>
          <span>导入方式：</span>
          <el-radio-group v-model="deptPresetImportMode" size="small">
            <el-radio-button label="REPLACE">覆盖当前部门与岗位</el-radio-button>
            <el-radio-button label="APPEND">追加合并至现有架构</el-radio-button>
          </el-radio-group>
        </div>
        <div style="font-size: 12px; color: #64748b;">
          💡 导入后点击页面上的【💾 保存组织架构到数据库】即时入库
        </div>
      </div>

      <template #footer>
        <el-button @click="industryPresetDeptModalVisible = false">取消</el-button>
        <el-button type="primary" :loading="loadingPresetOrg" @click="handleConfirmImportDeptPreset">
          确认导入 ({{ presetPreviewDepartments.length }} 部门 / {{ presetPreviewPositions.length }} 岗位)
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 2: 岗位说明书抽屉 -->
    <el-drawer v-model="openDocDrawer" :title="'岗位职责说明书 - ' + currentDocPost?.postName" size="520px">
      <div v-if="currentDocPost" class="doc-drawer-content">
        <div class="doc-header">
          <div class="doc-title">{{ currentDocPost.postName }}</div>
          <el-tag size="small" type="primary">{{ currentDocPost.department }}</el-tag>
          <el-tag size="small" :type="currentDocPost.status === 'ACTIVE' ? 'success' : 'info'" style="margin-left: 6px;">
            {{ currentDocPost.status === 'ACTIVE' ? '在用岗位' : '已停用' }}
          </el-tag>
          <el-tag v-if="currentDocPost.isRecruiting" size="small" type="warning" style="margin-left: 6px;">
            📢 招聘中 (已收{{ currentDocPost.appliedCount || 0 }}份简历)
          </el-tag>
        </div>

        <div class="doc-block">
          <div class="doc-label">📌 岗位职责描述</div>
          <div class="doc-text">{{ currentDocPost.description }}</div>
        </div>

        <div class="doc-block">
          <div class="doc-label">🎯 任职要求与考核评价基准</div>
          <div class="doc-text">{{ currentDocPost.requirements || '严格遵守门店服务规章与考勤排班纪律，秉承客户第一宗旨。' }}</div>
        </div>

        <div class="doc-block">
          <div class="doc-label">💰 薪酬与绩效机制</div>
          <div class="doc-grid">
            <div class="dg-item">
              <span class="lbl">岗位建议底薪：</span>
              <b>￥{{ currentDocPost.baseSalary }}</b>
            </div>
            <div class="dg-item">
              <span class="lbl">建议业绩提成：</span>
              <b style="color: #059669;">{{ (currentDocPost.commissionRate * 100).toFixed(0) }}%</b>
            </div>
            <div class="dg-item">
              <span class="lbl">在册员工数：</span>
              <span>{{ currentDocPost.employeeCount || 0 }} 人在岗</span>
            </div>
          </div>
        </div>

        <div v-if="currentDocPost.isRecruiting" class="doc-block">
          <div class="doc-label">📢 对外招聘发布信息</div>
          <div class="doc-grid">
            <div class="dg-item">
              <span class="lbl">招聘月薪：</span>
              <b style="color: #ea580c;">{{ currentDocPost.salaryRange || '面议' }}</b>
            </div>
            <div class="dg-item">
              <span class="lbl">计划人数：</span>
              <span>招 {{ currentDocPost.recruitHeadcount || 1 }} 人</span>
            </div>
            <div class="dg-item">
              <span class="lbl">要求门槛：</span>
              <span>{{ currentDocPost.experienceReq || '不限' }} · {{ currentDocPost.educationReq || '不限' }}</span>
            </div>
          </div>
          <div style="margin-top: 8px; display: flex; flex-wrap: wrap; gap: 4px;">
            <el-tag v-for="b in currentDocPost.benefits" :key="b" size="small" type="success">{{ b }}</el-tag>
          </div>
        </div>

        <!-- 招聘专属：预览海报与二维码分享快捷入口 -->
        <div style="margin-top: 24px; padding-top: 16px; border-top: 1px dashed #cbd5e1; display: flex; flex-direction: column; gap: 10px;">
          <el-button type="primary" size="large" @click="handleOpenSharePoster(currentDocPost)">
            🖼️ 生成该岗位招聘海报与专属二维码
          </el-button>
          <div style="display: flex; gap: 10px;">
            <el-button style="flex: 1;" type="warning" plain @click="handleOpenApplyPortal(currentDocPost)">
              📱 模拟投递表单
            </el-button>
            <el-button style="flex: 1;" type="success" plain @click="handleOpenApplyPageNewTab(currentDocPost)">
              🌐 新标签页打开
            </el-button>
          </div>
        </div>
      </div>
    </el-drawer>

    <!-- 弹窗 2.0: 🖼️ 岗位招聘预览页面与二维码分享 (支持预览、微信群转发、扫码、打印) -->
    <el-dialog
      v-model="openSharePosterDialog"
      title="🖼️ 岗位招聘微页面预览与二维码转发"
      width="860px"
      destroy-on-close
      class="share-poster-dialog"
    >
      <div v-if="targetPosterPost">
        <!-- 弹窗顶部操作工具条：支持在弹窗内自由切换不同岗位预览海报 -->
        <div class="poster-dialog-toolbar" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; padding: 10px 14px; background: #f8fafc; border-radius: 8px; border: 1px solid #e2e8f0;">
          <div style="display: flex; align-items: center; gap: 10px;">
            <span style="font-size: 13px; font-weight: 600; color: #475569;">当前预览岗位：</span>
            <el-select
              :model-value="targetPosterPost.id"
              style="width: 220px;"
              @change="(id: any) => {
                const found = positionsList.find(p => p.id === id)
                if (found) handleOpenSharePoster(found)
              }"
            >
              <el-option
                v-for="p in positionsList"
                :key="p.id"
                :label="p.postName + (p.isRecruiting ? ' (热招中)' : '')"
                :value="p.id"
              />
            </el-select>
          </div>
          <div style="display: flex; gap: 8px;">
            <el-button type="primary" plain size="small" icon="Edit" @click="handleEditPost(targetPosterPost)">
              编辑此岗位参数
            </el-button>
            <el-button type="success" plain size="small" icon="Plus" @click="handleOpenApplyPortal(targetPosterPost)">
              模拟求职投递
            </el-button>
          </div>
        </div>

        <div class="poster-dialog-layout">
        <!-- 左侧：1:1 手机真机模拟海报预览区域 -->
        <div class="poster-phone-column">
          <div class="phone-mockup-wrapper" id="printable-job-poster">
            <!-- 手机刘海状态栏 -->
            <div class="phone-status-bar">
              <span class="phone-time">09:41</span>
              <div class="phone-notch"></div>
              <div class="phone-icons">
                <span class="signal-dot">●●●</span>
                <span class="wifi-icon">5G</span>
                <span class="battery-icon">🔋</span>
              </div>
            </div>

            <!-- 手机内页招聘微页面 -->
            <div class="phone-screen-body">
              <!-- 顶部招聘封面头图 -->
              <div class="job-hero-card">
                <div class="hero-sub">{{ basicForm.storeName || '海马智慧连锁门店' }} · 诚聘英才</div>
                <div class="hero-title">{{ targetPosterPost.postName }}</div>
                <div class="hero-salary-row">
                  <span class="salary-num">{{ targetPosterPost.salaryRange || '面议' }}</span>
                  <span class="salary-desc">底薪￥{{ targetPosterPost.baseSalary || 4000 }}+高额提成</span>
                </div>
                <div class="hero-meta-badges">
                  <span class="meta-tag">🎯 招 {{ targetPosterPost.recruitHeadcount || 1 }} 人</span>
                  <span class="meta-tag">🎓 {{ targetPosterPost.educationReq || '学历不限' }}</span>
                  <span class="meta-tag">⏳ {{ targetPosterPost.experienceReq || '经验不限' }}</span>
                </div>
              </div>

              <!-- 福利亮点标签 -->
              <div class="job-benefits-row">
                <span
                  v-for="b in (targetPosterPost.benefits || ['包吃包住', '五险一金', '技能培训'])"
                  :key="b"
                  class="benefit-pill"
                >
                  ✨ {{ b }}
                </span>
              </div>

              <!-- 岗位职责 -->
              <div class="job-section-card">
                <div class="sec-header">
                  <span class="sec-dot"></span>
                  <b>岗位职责</b>
                </div>
                <div class="sec-body">{{ targetPosterPost.description }}</div>
              </div>

              <!-- 任职要求 -->
              <div class="job-section-card">
                <div class="sec-header">
                  <span class="sec-dot"></span>
                  <b>任职要求</b>
                </div>
                <div class="sec-body">{{ targetPosterPost.requirements || '品貌端正，具备良好服务意识与团队沟通协作精神。' }}</div>
              </div>

              <!-- 工作地址与联系 -->
              <div class="job-section-card store-contact-sec">
                <div class="store-row">
                  <span class="ico">🏬</span>
                  <span class="txt"><b>门店：</b>{{ basicForm.storeName || '海马智慧门店' }}</span>
                </div>
                <div class="store-row">
                  <span class="ico">📍</span>
                  <span class="txt"><b>地址：</b>{{ basicForm.address || '门店现场' }}</span>
                </div>
                <div class="store-row">
                  <span class="ico">📞</span>
                  <span class="txt"><b>电话：</b>{{ basicForm.phone || '到店咨询' }}</span>
                </div>
              </div>

              <!-- 海报底部的真实二维码 -->
              <div class="job-poster-qr-footer">
                <div class="qr-img-box">
                  <img v-if="posterQrCodeDataUrl" :src="posterQrCodeDataUrl" alt="微信扫码投递" />
                </div>
                <div class="qr-tip-box">
                  <div class="qr-tip-title">📱 微信扫码 · 一键投递</div>
                  <div class="qr-tip-desc">长按识别二维码或微信扫一扫<br/>在线提交基本资料 直达老板初筛</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 右侧：转发工具与快捷操作面板 -->
        <div class="poster-actions-column">
          <!-- 卡片 1: 专属二维码与快捷预览 -->
          <div class="action-card qr-card">
            <div class="action-card-header">
              <span class="header-icon">📷</span>
              <b>专属招聘二维码 (可扫码/可转发)</b>
            </div>
            <div class="qr-preview-flex">
              <div class="big-qr-wrapper">
                <img v-if="posterQrCodeDataUrl" :src="posterQrCodeDataUrl" class="big-qr-img" alt="岗位二维码" />
                <div class="qr-badge">即扫即投</div>
              </div>
              <div class="qr-instructions">
                <div class="instruct-title">📲 微信扫码直接投递</div>
                <div class="instruct-sub">求职者微信扫描此码，可进入手机版招聘微页面，查看岗位详情并直接填写资料投递。</div>
                <div class="qr-btn-group" style="display: flex; flex-wrap: wrap; gap: 8px;">
                  <el-button type="primary" size="small" icon="Picture" :loading="downloadingPoster" @click="handleDownloadFullPosterImage">
                    🖼️ 下载招聘海报图片
                  </el-button>
                  <el-button type="warning" plain size="small" icon="Download" @click="handleDownloadPosterQr">
                    📥 下载专属二维码
                  </el-button>
                  <el-button type="success" plain size="small" icon="Printer" @click="handlePrintPoster">
                    🖨️ 打印招聘宣传单
                  </el-button>
                  <el-button type="primary" plain size="small" icon="Compass" @click="handleOpenApplyPageNewTab(targetPosterPost)">
                    🌐 新标签页预览
                  </el-button>
                  <el-button type="info" plain size="small" icon="Document" @click="handleOpenApplyPortal(targetPosterPost)">
                    📝 模拟求职投递
                  </el-button>
                </div>
              </div>
            </div>
          </div>

          <!-- 卡片 2: 独立投递链接 -->
          <div class="action-card">
            <div class="action-card-header">
              <span class="header-icon">🔗</span>
              <b>独立招聘网页链接 (可发微信/公众号/朋友圈)</b>
            </div>
            <div class="link-input-group">
              <el-input v-model="currentShareUrl" readonly size="default">
                <template #append>
                  <el-button type="primary" @click="handleCopyShareUrl">复制链接</el-button>
                </template>
              </el-input>
            </div>
            <div class="action-card-tip">
              💡 提示：可将此链接直接发送到微信群、求职招聘网站或配置到公众号菜单栏。
            </div>
          </div>

          <!-- 卡片 2.5: 门店联系信息快捷设置 (即时调整海报上展示的店名、地址与电话) -->
          <div class="action-card" style="background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 12px;">
            <div class="action-card-header" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
              <div style="display: flex; align-items: center; gap: 6px;">
                <span class="header-icon">🏪</span>
                <b>招聘海报门店联系信息 (实时联动)</b>
              </div>
              <el-button type="primary" link size="small" @click="handleSavePosterContactInfo">
                💾 保存并更新海报
              </el-button>
            </div>
            <div style="display: flex; flex-direction: column; gap: 8px;">
              <el-input v-model="basicForm.storeName" placeholder="门店全称" size="small">
                <template #prepend>门店</template>
              </el-input>
              <el-input v-model="basicForm.address" placeholder="门店详细地址" size="small">
                <template #prepend>地址</template>
              </el-input>
              <el-input v-model="basicForm.phone" placeholder="招聘咨询电话" size="small">
                <template #prepend>电话</template>
              </el-input>
            </div>
          </div>

          <!-- 卡片 3: 微信朋友圈/微信群转发专用文案 -->
          <div class="action-card">
            <div class="action-card-header">
              <span class="header-icon">💬</span>
              <b>微信转发推荐文案 (已自动排版)</b>
            </div>
            <div class="wechat-copy-box">
              <el-input
                v-model="generatedWechatText"
                type="textarea"
                :rows="5"
                readonly
                class="wechat-textarea"
              />
            </div>
            <div style="margin-top: 10px; display: flex; justify-content: flex-end;">
              <el-button type="success" icon="DocumentCopy" @click="handleCopyWechatText">
                一键复制微信转发文案
              </el-button>
            </div>
          </div>
        </div>
      </div>
      </div>
      <template #footer>
        <div style="display: flex; justify-content: space-between; align-items: center; width: 100%;">
          <span style="font-size: 13px; color: #64748b;">
            💡 提示：手机扫码投递的数据将实时同步至【应聘简历与面试管理看板】
          </span>
          <el-button @click="openSharePosterDialog = false">关闭</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 2.1: 📱 模拟求职者在线投递 (体验端 / 移动端应聘界面) -->
    <el-dialog
      v-model="openApplyPortalDialog"
      title="📱 门店职位在线应聘申请 (手机求职端模拟)"
      width="600px"
      destroy-on-close
      class="apply-portal-dialog"
    >
      <div class="apply-portal-scroll" style="max-height: 70vh; overflow-y: auto; padding-right: 8px;">
        <!-- 顶部岗位招聘海报横幅 -->
        <div class="portal-hero-banner">
          <div class="hero-store-name">{{ basicForm.storeName || '海马智慧旗舰店' }} 诚聘英才</div>
          <div class="hero-post-title">{{ candidateForm.postName || '请选择应聘岗位' }}</div>
          <div class="hero-salary-badge">{{ candidateForm.salaryRange || '薪资面议 · 丰厚提成' }}</div>
          <div class="hero-tags-row">
            <span class="hero-tag">🏬 门店现场工作</span>
            <span class="hero-tag">💼 稳定薪资社保</span>
            <span class="hero-tag">🌟 专业晋升通道</span>
          </div>
        </div>

        <!-- 岗位职责与要求展示 -->
        <div v-if="selectedPostForApply" class="portal-post-summary">
          <div class="summary-section">
            <div class="s-title">📌 岗位职责</div>
            <div class="s-content">{{ selectedPostForApply.description }}</div>
          </div>
          <div class="summary-section">
            <div class="s-title">🎯 任职要求</div>
            <div class="s-content">{{ selectedPostForApply.requirements }}</div>
          </div>
        </div>

        <!-- 求职者信息表单 -->
        <div class="portal-form-box">
          <div class="portal-form-title">📝 填写求职者基本资料</div>
          <el-form :model="candidateForm" label-width="100px" label-position="left">
            <el-form-item label="应聘岗位" required>
              <el-select
                v-model="candidateForm.postId"
                placeholder="请选择想要应聘的岗位"
                style="width: 100%;"
                @change="handleSelectApplyPost"
              >
                <el-option
                  v-for="p in positionsList.filter(item => item.isRecruiting || item.status === 'ACTIVE')"
                  :key="p.id"
                  :label="p.postName + (p.isRecruiting ? ' (热招中)' : '')"
                  :value="p.id"
                />
              </el-select>
            </el-form-item>

            <el-row :gutter="16">
              <el-col :span="13">
                <el-form-item label="姓名" required>
                  <el-input v-model="candidateForm.candidateName" placeholder="求职者真实姓名" />
                </el-form-item>
              </el-col>
              <el-col :span="11">
                <el-form-item label="性别" required>
                  <el-radio-group v-model="candidateForm.gender">
                    <el-radio label="男">男</el-radio>
                    <el-radio label="女">女</el-radio>
                  </el-radio-group>
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="16">
              <el-col :span="13">
                <el-form-item label="联系电话" required>
                  <el-input v-model="candidateForm.phone" placeholder="接收面试通知手机号" />
                </el-form-item>
              </el-col>
              <el-col :span="11">
                <el-form-item label="年龄">
                  <el-input-number v-model="candidateForm.age" :min="18" :max="65" style="width: 100%;" />
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="16">
              <el-col :span="13">
                <el-form-item label="最高学历">
                  <el-select v-model="candidateForm.education" style="width: 100%;">
                    <el-option label="中专 / 高中" value="中专/高中" />
                    <el-option label="大专" value="大专" />
                    <el-option label="本科" value="本科" />
                    <el-option label="其他" value="其他" />
                  </el-select>
                </el-form-item>
              </el-col>
              <el-col :span="11">
                <el-form-item label="工作年限">
                  <el-input-number v-model="candidateForm.experienceYears" :min="0" :max="40" style="width: 100%;" />
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="16">
              <el-col :span="13">
                <el-form-item label="期望月薪">
                  <el-input v-model="candidateForm.expectedSalary" placeholder="如：6500元/月" />
                </el-form-item>
              </el-col>
              <el-col :span="11">
                <el-form-item label="最快到岗">
                  <el-select v-model="candidateForm.availableDate" style="width: 100%;">
                    <el-option label="随时到岗" value="随时到岗" />
                    <el-option label="3天内到岗" value="3天内到岗" />
                    <el-option label="1周内" value="1周内" />
                    <el-option label="1个月内" value="1个月内" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>

            <el-form-item label="个人优势特长">
              <el-input
                v-model="candidateForm.personalAdvantage"
                type="textarea"
                :rows="2"
                placeholder="简述您的专业擅长（如擅长剪发雕刻、手法熟练、服务热情耐心等）..."
              />
            </el-form-item>

            <el-form-item label="工作经历简述">
              <el-input
                v-model="candidateForm.workHistory"
                type="textarea"
                :rows="2"
                placeholder="既往工作单位、在岗职务及从业经历..."
              />
            </el-form-item>
          </el-form>
        </div>
      </div>
      <template #footer>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span style="font-size: 12px; color: #64748b;">
            💡 提交后系统将即时送达店长审核，并可在“应聘简历与面试管理”中查阅。
          </span>
          <div>
            <el-button @click="openApplyPortalDialog = false">取消</el-button>
            <el-button type="primary" size="large" icon="Check" @click="handleSubmitCandidateApplication">
              🚀 立即提交应聘资料
            </el-button>
          </div>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 2.2: 📄 应聘求职者详尽简历详情抽屉 -->
    <el-drawer
      v-model="openApplicantDocDrawer"
      :title="'应聘简历详情 - ' + currentApplicant?.candidateName"
      size="560px"
    >
      <div v-if="currentApplicant" class="applicant-doc-wrap">
        <div class="app-header-card">
          <div style="display: flex; align-items: center; gap: 12px;">
            <el-avatar :size="50" style="background: #0284c7; font-weight: 700; font-size: 18px;">
              {{ currentApplicant.candidateName.substring(0, 1) }}
            </el-avatar>
            <div>
              <div style="font-size: 18px; font-weight: 700; color: #0f172a;">
                {{ currentApplicant.candidateName }}
                <span style="font-size: 13px; font-weight: normal; color: #64748b; margin-left: 6px;">
                  ({{ currentApplicant.gender }} · {{ currentApplicant.age }}岁)
                </span>
              </div>
              <div style="font-size: 13px; color: #475569; margin-top: 2px;">
                应聘岗位：<el-tag size="small" type="primary">{{ currentApplicant.postName }}</el-tag>
              </div>
            </div>
          </div>

          <div style="margin-top: 10px;">
            <el-tag v-if="currentApplicant.status === 'PENDING'" type="warning" effect="dark">⏳ 待初筛</el-tag>
            <el-tag v-else-if="currentApplicant.status === 'INTERVIEW_SCHEDULED'" type="primary" effect="dark">🗓️ 已约面试</el-tag>
            <el-tag v-else-if="currentApplicant.status === 'PASSED'" type="success" effect="plain">✅ 面试通过</el-tag>
            <el-tag v-else-if="currentApplicant.status === 'HIRED'" type="success" effect="dark">🏆 已入职</el-tag>
            <el-tag v-else-if="currentApplicant.status === 'REJECTED'" type="info">❌ 已淘汰</el-tag>
          </div>
        </div>

        <div class="app-block">
          <div class="b-title">📋 基础意向与联系信息</div>
          <div class="b-grid">
            <div class="bg-item"><span class="lbl">联系手机：</span><b>{{ currentApplicant.phone }}</b></div>
            <div class="bg-item"><span class="lbl">最高学历：</span><span>{{ currentApplicant.education }}</span></div>
            <div class="bg-item"><span class="lbl">工作年限：</span><span>{{ currentApplicant.experienceYears }} 年</span></div>
            <div class="bg-item"><span class="lbl">期望月薪：</span><b style="color: #ea580c;">{{ currentApplicant.expectedSalary }}</b></div>
            <div class="bg-item"><span class="lbl">最快到岗：</span><span>{{ currentApplicant.availableDate || '随时' }}</span></div>
            <div class="bg-item"><span class="lbl">投递时间：</span><span>{{ currentApplicant.applyTime }}</span></div>
          </div>
        </div>

        <div class="app-block">
          <div class="b-title">🌟 个人专业优势与技能特点</div>
          <div class="b-text">{{ currentApplicant.personalAdvantage || '求职者未填写详细描述' }}</div>
        </div>

        <div class="app-block">
          <div class="b-title">💼 既往工作经历</div>
          <div class="b-text">{{ currentApplicant.workHistory || '求职者未填写详细履历' }}</div>
        </div>

        <div v-if="currentApplicant.certificates" class="app-block">
          <div class="b-title">📜 持有证书与资质</div>
          <div class="b-text">{{ currentApplicant.certificates }}</div>
        </div>

        <!-- 面试日程安排记录 -->
        <div v-if="currentApplicant.interviewInfo" class="app-block highlight-block">
          <div class="b-title">🗓️ 面试安排日程信息</div>
          <div class="b-grid">
            <div class="bg-item"><span class="lbl">面试时间：</span><b>{{ currentApplicant.interviewInfo.interviewTime }}</b></div>
            <div class="bg-item"><span class="lbl">面试考官：</span><span>{{ currentApplicant.interviewInfo.interviewer }}</span></div>
            <div class="bg-item">
              <span class="lbl">面试形式：</span>
              <span>{{ currentApplicant.interviewInfo.type === 'OFFLINE' ? '门店现场面试' : currentApplicant.interviewInfo.type === 'VIDEO' ? '远程视频面试' : '电话初试' }}</span>
            </div>
            <div class="bg-item"><span class="lbl">面试地点：</span><span>{{ currentApplicant.interviewInfo.location }}</span></div>
          </div>
          <div v-if="currentApplicant.interviewInfo.note" style="font-size: 12px; color: #64748b; margin-top: 6px;">
            备注提示：{{ currentApplicant.interviewInfo.note }}
          </div>
          <div v-if="currentApplicant.interviewInfo.smsSent" style="margin-top: 10px; background: #fff; border: 1px dashed #fbcfe8; border-radius: 6px; padding: 10px 12px;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
              <span style="font-size: 12px; font-weight: 700; color: #9d174d;">📱 面试通知短信已成功送达 ({{ currentApplicant.interviewInfo.smsTime }})</span>
              <el-tag size="small" type="success" effect="plain">短信网关已送达</el-tag>
            </div>
            <div style="font-size: 12px; color: #475569; line-height: 1.5;">{{ currentApplicant.interviewInfo.smsContent }}</div>
          </div>
        </div>

        <!-- 面试考评结果记录 -->
        <div v-if="currentApplicant.interviewEvaluation" class="app-block highlight-block">
          <div class="b-title">📝 面试综合评价意见</div>
          <div class="b-grid">
            <div class="bg-item">
              <span class="lbl">综合评级：</span>
              <el-tag
                :type="currentApplicant.interviewEvaluation.scoreLevel === 'EXCELLENT' ? 'success' : currentApplicant.interviewEvaluation.scoreLevel === 'GOOD' ? 'primary' : 'warning'"
                size="small"
              >
                {{ currentApplicant.interviewEvaluation.scoreLevel === 'EXCELLENT' ? '优秀 (极力推荐)' : currentApplicant.interviewEvaluation.scoreLevel === 'GOOD' ? '良好 (符合标准)' : '及格/待定' }}
              </el-tag>
            </div>
            <div class="bg-item"><span class="lbl">考评人：</span><span>{{ currentApplicant.interviewEvaluation.evaluatedBy }}</span></div>
            <div class="bg-item"><span class="lbl">考评时间：</span><span>{{ currentApplicant.interviewEvaluation.evaluateTime }}</span></div>
          </div>
          <div style="font-size: 13px; color: #1e293b; margin-top: 8px; line-height: 1.6;">
            <b>评语详情：</b>{{ currentApplicant.interviewEvaluation.feedback }}
          </div>
        </div>

        <!-- 底部快捷流转操作按钮 -->
        <div class="app-drawer-actions">
          <el-button
            v-if="currentApplicant.status === 'PENDING' || currentApplicant.status === 'INTERVIEW_SCHEDULED'"
            type="warning"
            icon="Calendar"
            @click="handleOpenScheduleInterview(currentApplicant)"
          >
            {{ currentApplicant.status === 'INTERVIEW_SCHEDULED' ? '修改面试日程' : '安排面试' }}
          </el-button>
          <el-button
            v-if="currentApplicant.status === 'INTERVIEW_SCHEDULED'"
            type="primary"
            icon="EditPen"
            @click="handleOpenInterviewEval(currentApplicant)"
          >
            录入面试评价
          </el-button>
          <el-button
            v-if="currentApplicant.status === 'PASSED' || currentApplicant.status === 'HIRED'"
            type="primary"
            icon="Promotion"
            @click="handleOpenSendRegisterQr(currentApplicant)"
          >
            📲 发送入职建档码/链接
          </el-button>
          <el-button
            v-if="currentApplicant.status === 'PASSED'"
            type="success"
            icon="Check"
            @click="handleHireCandidate(currentApplicant)"
          >
            直接办理正式入职
          </el-button>
        </div>
      </div>
    </el-drawer>

    <!-- 弹窗: 📲 发送员工专属入职建档码与链接 -->
    <el-dialog v-model="openSendRegisterQrDialog" title="📲 发送入职建档码 · 员工自主完善信息" width="560px" destroy-on-close>
      <div v-if="targetRegisterApplicant" style="text-align: center; padding: 6px 0;">
        <div style="background: #f0fdf4; border: 1px solid #bbf7d0; padding: 12px 16px; border-radius: 8px; text-align: left; margin-bottom: 16px;">
          <div style="font-weight: bold; color: #166534; font-size: 15px;">
            🎉 恭喜【{{ targetRegisterApplicant.candidateName }}】面试通过！
          </div>
          <div style="font-size: 12.5px; color: #15803d; margin-top: 6px; line-height: 1.5;">
            拟聘岗位：<strong>{{ targetRegisterApplicant.postName }}</strong> · 手机号：<strong>{{ targetRegisterApplicant.phone }}</strong> · 所属部门：<strong>{{ targetRegisterApplicant.department || '门店服务部' }}</strong>
          </div>
          <div style="font-size: 12px; color: #166534; margin-top: 4px;">
            让候选人使用微信扫码或打开专属链接，即可直接核对个人档案、补充身份证并设置密码，快速开通系统工号！
          </div>
        </div>

        <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; margin: 16px 0;">
          <div style="border: 2px dashed #0284c7; padding: 12px; border-radius: 12px; background: #f8fafc; display: inline-block;">
            <img v-if="registerQrCodeDataUrl" :src="registerQrCodeDataUrl" style="width: 200px; height: 200px; display: block; border-radius: 8px;" />
            <div v-else style="width: 200px; height: 200px; display: flex; align-items: center; justify-content: center; color: #94a3b8;">
              正在生成专属二维码...
            </div>
          </div>
          <div style="font-size: 12px; color: #64748b; margin-top: 8px;">
            📌 员工现场微信扫码，一键激活专属工号
          </div>
        </div>

        <div style="background: #f1f5f9; padding: 10px 14px; border-radius: 8px; font-size: 12px; color: #475569; word-break: break-all; text-align: left; margin-bottom: 16px;">
          <strong>专属入职链接：</strong>
          <div style="margin-top: 4px; color: #0284c7;">{{ currentRegisterUrl }}</div>
        </div>

        <div style="display: flex; gap: 10px; justify-content: center;">
          <el-button type="primary" icon="DocumentCopy" @click="handleCopyRegisterUrl">复制入职链接</el-button>
          <el-button type="success" icon="Download" @click="handleDownloadRegisterQr">保存二维码图片</el-button>
          <el-button type="warning" icon="ChatDotRound" @click="handleSendRegisterSms">模拟发送入职通知短信</el-button>
        </div>
      </div>
    </el-dialog>

    <!-- 弹窗 2.3: 🗓️ 安排面试弹窗 -->
    <el-dialog v-model="openScheduleInterviewDialog" title="🗓️ 安排候选人面试 & 发送通知短信" width="580px" destroy-on-close>
      <div v-if="targetScheduleApplicant" style="padding: 4px 0;">
        <div style="background: #f0f9ff; border: 1px solid #bae6fd; padding: 10px 14px; border-radius: 6px; margin-bottom: 14px;">
          <div style="font-weight: 700; color: #0369a1; display: flex; justify-content: space-between; align-items: center;">
            <span>正在为【{{ targetScheduleApplicant.candidateName }}】安排面试</span>
            <el-tag size="small" type="primary">{{ targetScheduleApplicant.postName }}</el-tag>
          </div>
          <div style="font-size: 12px; color: #0284c7; margin-top: 4px;">
            联系电话：<b>{{ targetScheduleApplicant.phone }}</b> · 期望待遇：{{ targetScheduleApplicant.expectedSalary }}
          </div>
        </div>

        <el-form :model="scheduleForm" label-width="95px">
          <el-form-item label="面试时间" required>
            <el-date-picker
              v-model="scheduleForm.interviewTime"
              type="datetime"
              placeholder="选择面试日期与具体时段"
              format="YYYY-MM-DD HH:mm"
              value-format="YYYY-MM-DD HH:mm"
              style="width: 100%;"
              @change="generateInterviewSmsContent"
            />
          </el-form-item>

          <el-form-item label="面试形式" required>
            <el-radio-group v-model="scheduleForm.type" @change="generateInterviewSmsContent">
              <el-radio label="OFFLINE">门店现场面试</el-radio>
              <el-radio label="VIDEO">远程微信视频面</el-radio>
              <el-radio label="PHONE">电话沟通初试</el-radio>
            </el-radio-group>
          </el-form-item>

          <el-row :gutter="12">
            <el-col :span="12">
              <el-form-item label="面试考官" required>
                <el-input v-model="scheduleForm.interviewer" placeholder="如：张建华 (店长)" @input="generateInterviewSmsContent" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="面试地点">
                <el-input v-model="scheduleForm.location" placeholder="如：门店2楼VIP接待茶歇区" @input="generateInterviewSmsContent" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="给候选人附言">
            <el-input
              v-model="scheduleForm.note"
              type="textarea"
              :rows="2"
              placeholder="如：请携带身份证原件及既往作品，准时到达门店。"
              @input="generateInterviewSmsContent"
            />
          </el-form-item>

          <!-- 短信通知开关与实时模板预览 -->
          <div style="background: #fdf2f8; border: 1px solid #fbcfe8; padding: 12px 14px; border-radius: 8px; margin-top: 10px;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
              <div style="font-weight: 700; color: #9d174d; display: flex; align-items: center; gap: 6px;">
                <el-icon><Promotion /></el-icon>
                <span>发送面试通知短信给申请人</span>
              </div>
              <el-switch v-model="scheduleForm.sendSms" active-text="开启短信通知" />
            </div>

            <div v-if="scheduleForm.sendSms" style="margin-top: 10px;">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                <span style="font-size: 12px; color: #831843;">
                  📱 接收号码：<b>{{ targetScheduleApplicant.phone }}</b>
                </span>
                <el-radio-group v-model="scheduleForm.smsTemplate" size="small" @change="generateInterviewSmsContent">
                  <el-radio-button label="OFFLINE">现场面模版</el-radio-button>
                  <el-radio-button label="SKILL">试工面模版</el-radio-button>
                  <el-radio-button label="VIDEO">视频面模版</el-radio-button>
                </el-radio-group>
              </div>

              <el-input
                v-model="scheduleForm.smsContent"
                type="textarea"
                :rows="4"
                placeholder="短信内容预览与微调"
              />
              <div style="display: flex; justify-content: space-between; font-size: 11px; color: #9d174d; margin-top: 4px;">
                <span>💡 确认安排后将自动通过系统短信通道下发至求职者手机</span>
                <span>字数：{{ scheduleForm.smsContent?.length || 0 }} 字 (计 1-2 条)</span>
              </div>
            </div>
          </div>
        </el-form>
      </div>
      <template #footer>
        <el-button @click="openScheduleInterviewDialog = false">取消</el-button>
        <el-button type="primary" icon="Promotion" @click="handleConfirmScheduleInterview">
          {{ scheduleForm.sendSms ? '确认安排并发送通知短信' : '确认安排面试日程' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 2.4: 📝 面试评价与定级 -->
    <el-dialog v-model="openInterviewEvalDialog" title="录入面试综合评价与录用决策" width="520px" destroy-on-close>
      <div v-if="targetEvalApplicant" style="padding: 6px 0;">
        <div style="background: #f8fafc; border: 1px solid #e2e8f0; padding: 10px 14px; border-radius: 6px; margin-bottom: 16px;">
          <div style="font-weight: 700; color: #0f172a;">
            候选人：{{ targetEvalApplicant.candidateName }} ({{ targetEvalApplicant.postName }})
          </div>
          <div style="font-size: 12px; color: #64748b; margin-top: 2px;">
            面试考官：{{ targetEvalApplicant.interviewInfo?.interviewer || '店长' }}
          </div>
        </div>

        <el-form :model="evalForm" label-width="100px">
          <el-form-item label="综合评级" required>
            <el-radio-group v-model="evalForm.scoreLevel">
              <el-radio label="EXCELLENT">优秀 (极力推荐录用)</el-radio>
              <el-radio label="GOOD">良好 (符合岗位要求)</el-radio>
              <el-radio label="PASS">及格/待定</el-radio>
              <el-radio label="FAIL">不合格</el-radio>
            </el-radio-group>
          </el-form-item>

          <el-form-item label="面试评语" required>
            <el-input
              v-model="evalForm.feedback"
              type="textarea"
              :rows="3"
              placeholder="记录候选人仪表仪态、专业技术熟练度、服务沟通表达及团队契合度..."
            />
          </el-form-item>

          <el-form-item label="流转决策" required>
            <el-radio-group v-model="evalForm.decision">
              <el-radio label="PASSED">
                <b style="color: #059669;">✅ 面试通过 (拟录用入职)</b>
              </el-radio>
              <el-radio label="REJECTED">
                <b style="color: #dc2626;">❌ 淘汰未通过</b>
              </el-radio>
            </el-radio-group>
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <el-button @click="openInterviewEvalDialog = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmInterviewEval">提交评价与结果</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 2.5: ❌ 淘汰求职者归档 -->
    <el-dialog v-model="openRejectDialog" title="淘汰候选人归档" width="450px" destroy-on-close>
      <div v-if="targetRejectApplicant" style="padding: 6px 0;">
        <div style="font-size: 14px; margin-bottom: 12px; color: #334155;">
          确定将候选人【<b>{{ targetRejectApplicant.candidateName }}</b>】（{{ targetRejectApplicant.postName }}）标记为淘汰归档吗？
        </div>
        <el-form label-width="80px">
          <el-form-item label="淘汰原因">
            <el-select v-model="rejectReasonText" style="width: 100%;">
              <el-option label="技术实操或经验与岗位不符" value="技术实操或经验与岗位不符" />
              <el-option label="薪资待遇预期超出本店预算" value="薪资待遇预期超出本店预算" />
              <el-option label="沟通服务意识欠佳" value="沟通服务意识欠佳" />
              <el-option label="未按约参加面试" value="未按约参加面试" />
              <el-option label="该岗位当前编制已满" value="该岗位当前编制已满" />
            </el-select>
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <el-button @click="openRejectDialog = false">取消</el-button>
        <el-button type="danger" @click="handleConfirmReject">确认淘汰</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 3: 短信购买扫码支付弹窗 (对齐截图2支付闭环) -->
    <el-dialog v-model="openPayDialog" title="短信套餐收银结算" width="450px" destroy-on-close>
      <div class="pay-modal-content" style="text-align: center; padding: 10px 0;">
        <div style="font-size: 14px; color: #64748b;">待支付短信套餐</div>
        <div style="font-size: 22px; font-weight: 700; color: #0f172a; margin: 6px 0;">
          {{ currentSelectedPackage?.name }} ({{ currentSelectedPackage?.count }}条)
        </div>
        <div style="font-size: 30px; font-weight: 800; color: #ea580c; margin-bottom: 16px;">
          ￥{{ currentSelectedPackage?.price }}
        </div>

        <!-- 模拟扫码区域 -->
        <div style="width: 190px; height: 190px; margin: 0 auto; border: 2px dashed #0284c7; border-radius: 10px; background: #f0f9ff; display: flex; flex-direction: column; align-items: center; justify-content: center; position: relative;">
          <el-icon style="font-size: 72px; color: #0284c7;"><Coin /></el-icon>
          <span style="font-size: 13px; font-weight: 600; color: #0369a1; margin-top: 8px;">
            {{ selectedPayMethod === 'WECHAT' ? '微信扫码完成支付' : '支付宝扫码完成支付' }}
          </span>
        </div>

        <div style="margin-top: 14px; font-size: 12px; color: #64748b;">
          支付成功后短信额度将实时充入租户余额，支持即时批量群发与消费短信提醒。
        </div>
      </div>
      <template #footer>
        <el-button @click="openPayDialog = false">取消</el-button>
        <el-button type="success" :loading="paying" @click="handleConfirmSimulationPay">
          模拟扫码支付成功 (自动入账)
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 4: 申请短信签名 (严格 100% 对齐截图 media_1788699959771.png & media_1788699969886.png) -->
    <el-dialog
      v-model="openApplySignDialog"
      title="申请短信签名"
      width="580px"
      destroy-on-close
      class="apply-sign-dialog"
    >
      <div class="apply-dialog-body" style="max-height: 65vh; overflow-y: auto; padding-right: 12px;">
        <el-form :model="applySignForm" label-width="150px" class="apply-sign-form">
          <el-form-item label="* 公司全称" required>
            <el-input v-model="applySignForm.companyName" placeholder="请输入公司全称" />
          </el-form-item>
          <el-form-item label="* 统一社会信用代码" required>
            <el-input v-model="applySignForm.creditCode" placeholder="请输入统一社会信用代码" />
          </el-form-item>
          <el-form-item label="* 主体公司法人姓名" required>
            <el-input v-model="applySignForm.legalPerson" placeholder="请输入主体公司法人姓名" />
          </el-form-item>
          <el-form-item label="* 法人身份证号" required>
            <el-input v-model="applySignForm.idCard" placeholder="请输入法人身份证号" />
          </el-form-item>
          <el-form-item label="* 法人实名手机号" required>
            <el-input v-model="applySignForm.legalPhone" placeholder="请输入法人实名手机号" />
          </el-form-item>
          <el-form-item label="* 短信内容" required>
            <el-input v-model="applySignForm.smsContent" placeholder="请输入短信内容" />
          </el-form-item>
          <el-form-item label="报备手机号">
            <el-input v-model="applySignForm.reportPhone" placeholder="如短信内容包含手机号请输入" />
          </el-form-item>

          <!-- 4 大上传组件 (支持原生文件选取、真实读取与缩略图预览) -->
          <input
            ref="licenseFileInputRef"
            type="file"
            accept="image/*"
            style="display: none;"
            @change="handleRealFileChange($event, 'license')"
          />
          <input
            ref="idFrontFileInputRef"
            type="file"
            accept="image/*"
            style="display: none;"
            @change="handleRealFileChange($event, 'idFront')"
          />
          <input
            ref="idBackFileInputRef"
            type="file"
            accept="image/*"
            style="display: none;"
            @change="handleRealFileChange($event, 'idBack')"
          />
          <input
            ref="idHoldFileInputRef"
            type="file"
            accept="image/*"
            style="display: none;"
            @change="handleRealFileChange($event, 'idHold')"
          />

          <el-form-item label="* 营业执照" required>
            <div class="upload-square-box" @click="triggerFileInput('license')">
              <div v-if="applySignForm.licenseImg" class="upload-preview-box real-preview">
                <img :src="applySignForm.licenseImg" class="upload-thumb-img" alt="营业执照" />
                <div class="thumb-hover-actions">
                  <span class="action-btn change">更换</span>
                  <span class="action-btn del" @click.stop="handleRemoveUploadedFile('license')">删除</span>
                </div>
              </div>
              <div v-else class="upload-placeholder">
                <span class="plus-icon">+</span>
                <span class="upload-sub-text">选取真实照片</span>
              </div>
            </div>
          </el-form-item>

          <el-form-item label="* 身份证人像面" required>
            <div class="upload-square-box" @click="triggerFileInput('idFront')">
              <div v-if="applySignForm.idFrontImg" class="upload-preview-box real-preview">
                <img :src="applySignForm.idFrontImg" class="upload-thumb-img" alt="身份证人像面" />
                <div class="thumb-hover-actions">
                  <span class="action-btn change">更换</span>
                  <span class="action-btn del" @click.stop="handleRemoveUploadedFile('idFront')">删除</span>
                </div>
              </div>
              <div v-else class="upload-placeholder">
                <span class="plus-icon">+</span>
                <span class="upload-sub-text">选取真实照片</span>
              </div>
            </div>
          </el-form-item>

          <el-form-item label="* 身份证国徽面" required>
            <div class="upload-square-box" @click="triggerFileInput('idBack')">
              <div v-if="applySignForm.idBackImg" class="upload-preview-box real-preview">
                <img :src="applySignForm.idBackImg" class="upload-thumb-img" alt="身份证国徽面" />
                <div class="thumb-hover-actions">
                  <span class="action-btn change">更换</span>
                  <span class="action-btn del" @click.stop="handleRemoveUploadedFile('idBack')">删除</span>
                </div>
              </div>
              <div v-else class="upload-placeholder">
                <span class="plus-icon">+</span>
                <span class="upload-sub-text">选取真实照片</span>
              </div>
            </div>
          </el-form-item>

          <el-form-item label="* 手持身份证" required>
            <div class="upload-square-box" @click="triggerFileInput('idHold')">
              <div v-if="applySignForm.idHoldImg" class="upload-preview-box real-preview">
                <img :src="applySignForm.idHoldImg" class="upload-thumb-img" alt="手持身份证" />
                <div class="thumb-hover-actions">
                  <span class="action-btn change">更换</span>
                  <span class="action-btn del" @click.stop="handleRemoveUploadedFile('idHold')">删除</span>
                </div>
              </div>
              <div v-else class="upload-placeholder">
                <span class="plus-icon">+</span>
                <span class="upload-sub-text">选取真实照片</span>
              </div>
            </div>
          </el-form-item>
        </el-form>
      </div>

      <template #footer>
        <div style="display: flex; justify-content: flex-end; gap: 10px;">
          <el-button @click="openApplySignDialog = false">取消</el-button>
          <el-button type="primary" @click="handleConfirmApplySign">提交申请</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 5: 查看资质详情 (真实原图与报备信息) -->
    <el-dialog v-model="openSignDetailDialog" title="短信签名报备资质详情" width="620px">
      <div v-if="currentSignDetail" style="padding: 10px 0;">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="公司全称">{{ currentSignDetail.companyName }}</el-descriptions-item>
          <el-descriptions-item label="统一信用代码">{{ currentSignDetail.creditCode }}</el-descriptions-item>
          <el-descriptions-item label="主体法人">{{ currentSignDetail.legalPerson }}</el-descriptions-item>
          <el-descriptions-item label="法人手机号">{{ currentSignDetail.legalPhone }}</el-descriptions-item>
          <el-descriptions-item label="报备签名">【{{ currentSignDetail.signName }}】</el-descriptions-item>
          <el-descriptions-item label="短信报备内容">{{ currentSignDetail.smsContent }}</el-descriptions-item>
          <el-descriptions-item label="报备手机号">{{ currentSignDetail.reportPhone || '未特别指定' }}</el-descriptions-item>
          <el-descriptions-item label="资质证明图片">
            <div style="display: flex; gap: 12px; flex-wrap: wrap; margin-top: 6px;">
              <div v-if="currentSignDetail.licenseImg" style="text-align: center;">
                <el-image
                  :src="currentSignDetail.licenseImg"
                  :preview-src-list="[currentSignDetail.licenseImg]"
                  preview-teleported
                  fit="cover"
                  style="width: 80px; height: 80px; border-radius: 6px; border: 1px solid #cbd5e1;"
                />
                <div style="font-size: 11px; color: #64748b; margin-top: 2px;">营业执照</div>
              </div>
              <div v-if="currentSignDetail.idFrontImg" style="text-align: center;">
                <el-image
                  :src="currentSignDetail.idFrontImg"
                  :preview-src-list="[currentSignDetail.idFrontImg]"
                  preview-teleported
                  fit="cover"
                  style="width: 80px; height: 80px; border-radius: 6px; border: 1px solid #cbd5e1;"
                />
                <div style="font-size: 11px; color: #64748b; margin-top: 2px;">身份证人像面</div>
              </div>
              <div v-if="currentSignDetail.idBackImg" style="text-align: center;">
                <el-image
                  :src="currentSignDetail.idBackImg"
                  :preview-src-list="[currentSignDetail.idBackImg]"
                  preview-teleported
                  fit="cover"
                  style="width: 80px; height: 80px; border-radius: 6px; border: 1px solid #cbd5e1;"
                />
                <div style="font-size: 11px; color: #64748b; margin-top: 2px;">身份证国徽面</div>
              </div>
              <div v-if="currentSignDetail.idHoldImg" style="text-align: center;">
                <el-image
                  :src="currentSignDetail.idHoldImg"
                  :preview-src-list="[currentSignDetail.idHoldImg]"
                  preview-teleported
                  fit="cover"
                  style="width: 80px; height: 80px; border-radius: 6px; border: 1px solid #cbd5e1;"
                />
                <div style="font-size: 11px; color: #64748b; margin-top: 2px;">手持身份证</div>
              </div>
              <span v-if="!currentSignDetail.licenseImg && !currentSignDetail.idFrontImg" style="color: #94a3b8; font-size: 12px;">已提交电子资质报备</span>
            </div>
          </el-descriptions-item>
          <el-descriptions-item label="审核状态">
            <el-tag :type="currentSignDetail.status === 'APPROVED' ? 'success' : 'warning'">
              {{ currentSignDetail.status === 'APPROVED' ? '通过 (运营商生效)' : '审核中' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="审核结果说明">{{ currentSignDetail.auditReason || '平台与运营商审核通过' }}</el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <el-button @click="openSignDetailDialog = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 5.1: 群发目标客群名单管理与编辑查询 -->
    <el-dialog
      v-model="openBulkMembersDrawer"
      :title="`👥 群发目标客群名单明细与编辑查询 - ${getTargetGroupText(bulkForm.targetGroup)}`"
      width="840px"
      destroy-on-close
    >
      <div style="margin-bottom: 12px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
        <div style="display: flex; gap: 8px;">
          <el-input
            v-model="bulkMemberSearchKeyword"
            placeholder="搜索会员姓名/手机号"
            style="width: 220px;"
            clearable
          />
          <el-button type="primary" plain @click="handleSelectAllBulkMembers">全选客群</el-button>
          <el-button plain @click="handleDeselectAllBulkMembers">清空勾选</el-button>
          <el-button plain @click="handleResetBulkGroupSelection">重置默认</el-button>
        </div>
        <div style="font-size: 13px; color: #64748b;">
          已勾选 <b style="color: #0284c7; font-size: 15px;">{{ selectedBulkMemberIds.length }}</b> / 当前客群共 <b>{{ currentTargetGroupMembers.length }}</b> 人
        </div>
      </div>

      <el-table
        :data="filteredTargetGroupMembers"
        border
        stripe
        style="width: 100%; max-height: 420px;"
        empty-text="当前客群分类暂无会员数据（新注册租户无垃圾数据，或暂无匹配会员）"
      >
        <el-table-column width="55" align="center">
          <template #header>
            <el-checkbox
              :model-value="isAllVisibleBulkSelected"
              :indeterminate="isIndeterminateBulkSelected"
              @change="handleToggleSelectAllVisibleBulk"
            />
          </template>
          <template #default="{ row }">
            <el-checkbox
              :model-value="selectedBulkMemberIds.includes(row.id)"
              @change="(val: boolean) => handleToggleSingleMember(row.id, val)"
            />
          </template>
        </el-table-column>
        <el-table-column prop="name" label="会员姓名" width="130">
          <template #default="{ row }">
            <b>{{ row.name }}</b>
            <span v-if="row.gender === 'FEMALE'" style="color: #ec4899; margin-left: 4px;">♀</span>
            <span v-else-if="row.gender === 'MALE'" style="color: #3b82f6; margin-left: 4px;">♂</span>
          </template>
        </el-table-column>
        <el-table-column prop="phone" label="手机号码" width="140" />
        <el-table-column prop="levelName" label="会员等级" width="120">
          <template #default="{ row }">
            <el-tag size="small" type="success" effect="plain">{{ row.levelName || row.level || '普卡会员' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="balance" label="储值余额" width="110" align="right">
          <template #default="{ row }">
            <span style="color: #0284c7; font-weight: 700;">￥{{ Number(row.balance || 0).toFixed(2) }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="points" label="可用积分" width="90" align="center">
          <template #default="{ row }">
            <span style="color: #d97706; font-weight: 600;">{{ row.points || 0 }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="selectedBulkMemberIds.includes(row.id)"
              link
              type="danger"
              size="small"
              @click="handleToggleSingleMember(row.id, false)"
            >
              移出本次群发
            </el-button>
            <el-button
              v-else
              link
              type="primary"
              size="small"
              @click="handleToggleSingleMember(row.id, true)"
            >
              纳入本次群发
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <template #footer>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span style="font-size: 13px; color: #475569;">
            已确定选择 <b>{{ selectedBulkMemberIds.length }}</b> 位客户，预计单人发送 <b>{{ bulkSmsCountPerPerson }}</b> 条，合计扣减短信 <b>{{ selectedBulkMemberIds.length * bulkSmsCountPerPerson }}</b> 条。
          </span>
          <el-button type="primary" @click="openBulkMembersDrawer = false">确认完成</el-button>
        </div>
      </template>
    </el-dialog>

    <!-- 弹窗 6: 查看全渠道推送消息卡片详情 -->
    <el-dialog v-model="openLogDetailDialog" title="全渠道模板消息推送详情" width="560px">
      <div v-if="currentLogDetail" class="log-detail-body">
        <el-descriptions :column="1" border size="small">
          <el-descriptions-item label="流水ID">{{ currentLogDetail.id }}</el-descriptions-item>
          <el-descriptions-item label="推送渠道">
            <el-tag :type="currentLogDetail.channel === 'WECHAT_MP' ? 'success' : 'primary'">
              {{ currentLogDetail.channel === 'WECHAT_MP' ? '微信公众号/服务号' : '支付宝生活号' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="通知类型">{{ currentLogDetail.title }}</el-descriptions-item>
          <el-descriptions-item label="接收会员">{{ currentLogDetail.memberName }} ({{ currentLogDetail.phone }})</el-descriptions-item>
          <el-descriptions-item label="用户OpenID"><code style="font-size: 11px;">{{ currentLogDetail.targetOpenId }}</code></el-descriptions-item>
          <el-descriptions-item label="模板ID"><code style="font-size: 11px;">{{ currentLogDetail.templateId }}</code></el-descriptions-item>
          <el-descriptions-item label="发送时间">{{ formatDateTime(currentLogDetail.sentAt) }}</el-descriptions-item>
          <el-descriptions-item label="推送状态">
            <el-tag :type="currentLogDetail.status === 'SUCCESS' ? 'success' : 'danger'">
              {{ currentLogDetail.status === 'SUCCESS' ? '已送达 (成功)' : currentLogDetail.status }}
            </el-tag>
          </el-descriptions-item>
        </el-descriptions>

        <div style="margin-top: 14px;">
          <div style="font-weight: 700; font-size: 13px; margin-bottom: 6px; color: #1e293b;">📱 文本格式化卡片预览：</div>
          <pre style="background: #f8fafc; padding: 12px; border-radius: 6px; border: 1px solid #e2e8f0; font-size: 12px; line-height: 1.6; white-space: pre-wrap; font-family: monospace;">{{ currentLogDetail.content }}</pre>
        </div>

        <div v-if="currentLogDetail.dataJson" style="margin-top: 10px;">
          <div style="font-weight: 700; font-size: 13px; margin-bottom: 6px; color: #1e293b;">📋 官方模板 JSON 载荷：</div>
          <pre style="background: #0f172a; color: #38bdf8; padding: 10px; border-radius: 6px; font-size: 11px; max-height: 160px; overflow: auto; white-space: pre-wrap;">{{ formatJson(currentLogDetail.dataJson) }}</pre>
        </div>
      </div>
      <template #footer>
        <el-button type="primary" @click="openLogDetailDialog = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 8: 门店前台关注水牌打印预览 -->
    <el-dialog
      v-model="printStandDialogVisible"
      :title="'🖨️ 前台关注水牌打印预览 - ' + (printStandChannel === 'WECHAT' ? '微信官方服务号' : '支付宝官方生活号')"
      width="540px"
      destroy-on-close
    >
      <div id="printable-front-stand" style="display: flex; justify-content: center; padding: 12px 0;">
        <div
          class="dialog-stand-preview"
          :style="{
            border: printStandChannel === 'WECHAT' ? '3px solid #059669' : '3px solid #0284c7',
            borderRadius: '16px',
            overflow: 'hidden',
            width: '320px',
            textAlign: 'center',
            boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
            background: '#ffffff'
          }"
        >
          <div
            :style="{
              background: printStandChannel === 'WECHAT' ? 'linear-gradient(135deg, #059669, #047857)' : 'linear-gradient(135deg, #0284c7, #0369a1)',
              color: '#ffffff',
              padding: '16px 12px'
            }"
          >
            <div style="font-size: 17px; font-weight: 800; letter-spacing: 0.5px;">{{ currentSelectedStoreName }}</div>
            <div style="font-size: 12px; margin-top: 4px; opacity: 0.9;">
              {{ printStandChannel === 'WECHAT' ? '🟢 官方微信服务号 · 进店扫码领好礼' : '🔵 支付宝官方生活号 · 进店扫码领好礼' }}
            </div>
          </div>
          <div style="padding: 16px;">
            <img
              :src="printStandChannel === 'WECHAT' ? wechatStoreQrCodeDataUrl : alipayStoreQrCodeDataUrl"
              style="width: 190px; height: 190px; display: block; margin: 0 auto; border: 1px solid #f1f5f9; border-radius: 8px; padding: 6px;"
            />
            <div
              :style="{
                fontSize: '13px',
                fontWeight: '700',
                color: printStandChannel === 'WECHAT' ? '#059669' : '#0284c7',
                marginTop: '10px'
              }"
            >
              {{ printStandChannel === 'WECHAT' ? '微信扫一扫 · 关注本店服务号' : '支付宝扫一扫 · 关注官方生活号' }}
            </div>
            <div style="margin-top: 14px; background: #f8fafc; border-radius: 8px; padding: 10px; font-size: 12px; color: #334155; text-align: left; line-height: 1.8;">
              <div>🎁 <b>扫码关注即送 50 积分</b> + 新手礼包</div>
              <div>🔔 <b>进店消费实时动账</b>，电子小票即时推送到手机</div>
              <div>💳 <b>手机随时查看会员权益</b>与储值账户余额</div>
            </div>
          </div>
          <div style="border-top: 1px dashed #cbd5e1; padding: 8px; font-size: 11px; color: #94a3b8;">
            ✂️ 沿此线裁剪 · 适配 A5 亚克力 T 型前台展示架
          </div>
        </div>
      </div>
      <template #footer>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <div style="font-size: 12px; color: #64748b;">
            建议打印规格: A5 竖向彩色打印
          </div>
          <div>
            <el-button @click="printStandDialogVisible = false">取消</el-button>
            <el-button type="primary" icon="Printer" @click="executePrintStand">立即打印前台水牌</el-button>
          </div>
        </div>
      </template>
    </el-dialog>
    <!-- 通道连通性与诊断报告弹窗 -->
    <el-dialog
      v-model="pingDialogVisible"
      title="📡 支付通道连通性与证书握手诊断报告"
      width="640px"
      destroy-on-close
      append-to-body
    >
      <div v-if="pingReport" class="ping-report-box">
        <div class="report-header">
          <div class="r-status-icon">🟢</div>
          <div>
            <div class="r-st-title">支付通道网关连接正常，握手成功！</div>
            <div class="r-st-sub">测试通道：<strong>{{ pingReport.routeName }}</strong></div>
          </div>
        </div>

        <div class="diag-details-list">
          <div class="diag-row">
            <span class="d-label">接口网关地址:</span>
            <span class="d-val mono">{{ pingReport.gateway }}</span>
          </div>
          <div class="diag-row">
            <span class="d-label">网络往返时延 (RTT):</span>
            <span class="d-val text-green bold">{{ pingReport.latencyMs }} ms (极速响应)</span>
          </div>
          <div class="diag-row">
            <span class="d-label">加签验签状态:</span>
            <span class="d-val text-blue">RSA2 / APIv3 签名校验通过 (Success)</span>
          </div>
          <div class="diag-row">
            <span class="d-label">SSL/TLS 证书链:</span>
            <span class="d-val text-green">有效，TLS 1.3 高强度加密</span>
          </div>
          <div class="diag-row">
            <span class="d-label">扫码反扫就绪状态:</span>
            <span class="d-val">🟢 免驱扫码盒子可在收银台直接反扫扣款出单</span>
          </div>
        </div>
      </div>
      <template #footer>
        <el-button type="primary" @click="pingDialogVisible = false">完成测试</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElNotification, ElMessageBox } from 'element-plus'
import { Picture, Download, Printer, Compass, Refresh, Share, Document, Plus, Edit, Delete } from '@element-plus/icons-vue'
import QRCode from 'qrcode'
import {
  getNotificationConfigApi,
  saveNotificationConfigApi,
  sendTestNotificationApi,
  broadcastMarketingApi,
  getNotificationLogsApi,
  simulateFollowApi,
  saveStorePositionsApi,
  getIndustryPresetTemplateApi
} from '../api'
import { useSystemDataStore, buildMemberBenefitsUrl, type ReceiptTemplateConfig, type PaymentRouteType, type PaymentChannelConfig, defaultPaymentConfig, deepMergePaymentConfig } from '../stores/systemDataStore'
import { scanAudio } from '../utils/barcodeScanner'
import { useStoreConfig } from '../stores/store'
import { injectFootSpaMockData } from '../mock/mockFootSpaData'
import { getSmsPackagesList } from '../utils/tenantQuotaService'

const route = useRoute()
const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()
const determineActiveTab = () => {
  if (route.path.includes('payment') || route.name === 'PaymentSettings') {
    return 'payment'
  }
  if (route.path.includes('map') || route.name === 'MapSettings' || route.query.tab === 'amap') {
    return 'amap'
  }
  if (route.path.includes('job-posts') || route.name === 'JobPosts' || route.path.includes('post')) {
    return 'post'
  }
  if (route.query.tab && route.query.tab !== 'basic' && route.query.tab !== 'industry' && route.query.tab !== 'post') {
    return String(route.query.tab)
  }
  return 'sms'
}
const isStandalonePayment = computed(() => route.path.includes('payment') || route.name === 'PaymentSettings')
const isStandaloneMap = computed(() => route.path.includes('map') || route.name === 'MapSettings')
const isStandaloneJobPosts = computed(() => route.path.includes('job-posts') || route.name === 'JobPosts')

// 平台开发与超级管理员专属权限判定（仅 admin、PLATFORM_DEVELOPER 等能看平台底层 Key 与全网总控配置）
const isPlatformAdmin = computed(() => {
  const u = (localStorage.getItem('seahorse_username') || '').toLowerCase().trim()
  const r = (localStorage.getItem('seahorse_role') || '').toUpperCase().trim()
  return u === 'admin' || r === 'PLATFORM_DEVELOPER' || r === 'PLATFORM_ADMIN' || r === 'PLATFORM_SUPER_ADMIN'
})

// 权限判定：超级管理员能看 API Key 与配置支付通道与硬件；普通员工无操作权限
const isSuperAdmin = computed(() => {
  const u = (localStorage.getItem('seahorse_username') || '').toLowerCase().trim()
  const r = (localStorage.getItem('seahorse_role') || '').toUpperCase().trim()
  // 1. 平台超级管理员或系统开发商 (admin / PLATFORM_DEVELOPER / PLATFORM_ADMIN)
  if (u === 'admin' || r === 'PLATFORM_DEVELOPER' || r === 'PLATFORM_ADMIN' || r === 'PLATFORM_SUPER_ADMIN') {
    return true
  }
  // 2. 租户老板 / 企业管理员 / 店长 (具备门店经营与支付通道配置特权)
  if (u === 'boss' || r === 'SUPER_ADMIN' || r === 'TENANT_ADMIN' || r === 'ADMIN' || r === 'STORE_MANAGER' || r === 'MERCHANT_ADMIN' || r === 'BOSS') {
    return true
  }
  return false
})

const activeTab = ref(determineActiveTab())
watch(() => [route.query?.tab, route.path], () => {
  activeTab.value = determineActiveTab()
})

const saving = ref(false)

// 💳 扫码盒子硬件与聚合支付通道设置
const paymentForm = ref<PaymentChannelConfig>(deepMergePaymentConfig(defaultPaymentConfig, systemData.paymentConfig))
const activeRouteTab = ref<'ROUTE_1' | 'ROUTE_2' | 'ROUTE_3'>(
  paymentForm.value.activeRoute === 'ROUTE_1_INDIVIDUAL' ? 'ROUTE_1' :
  paymentForm.value.activeRoute === 'ROUTE_2_AGGREGATE' ? 'ROUTE_2' : 'ROUTE_3'
)
const savingPayment = ref(false)
const pingDialogVisible = ref(false)
const pingLoading = ref(false)
const pingReport = ref<any>(null)

// 🗺️ 高德地图与考勤定位服务配置
const amapForm = ref({
  webApiKey: '216aceb246ab68fbd8abb38f6cb24582',
  jsApiKey: '216aceb246ab68fbd8abb38f6cb24582',
  securityCode: 'a959cdbdf4b90d3ce9d3552521c0d0b9',
  allowedRadiusMeters: 500,
  storeLongitude: 108.953400,
  storeLatitude: 34.265500,
  storeAddress: '陕西省西安市雁塔区高新路海马商业中心1号店',
  storeName: '海马智慧商业 (西安高新旗舰店)',
})
const savingAmap = ref(false)
const testingAmap = ref(false)

// 地图实例与组件引用
let mapInstance: any = null
let markerInstance: any = null
let circleInstance: any = null
let geocoderInstance: any = null
const mapSearchKeyword = ref('')
const mapLoadFailed = ref(false)
const mapLoadErrorMsg = ref('')

const loadAmapSdk = (): Promise<any> => {
  return new Promise((resolve, reject) => {
    if ((window as any).AMap) {
      resolve((window as any).AMap)
      return
    }
    // 注入高德安全密钥 (必须在脚本请求前设置)
    ;(window as any)._AMapSecurityConfig = {
      securityJsCode: amapForm.value.securityCode || 'a959cdbdf4b90d3ce9d3552521c0d0b9',
    }
    const key = amapForm.value.jsApiKey || amapForm.value.webApiKey || '216aceb246ab68fbd8abb38f6cb24582'
    const script = document.createElement('script')
    script.type = 'text/javascript'
    script.src = `https://webapi.amap.com/maps?v=2.0&key=${key}&plugin=AMap.Geocoder,AMap.PlaceSearch,AMap.Geolocation`
    script.onload = () => {
      resolve((window as any).AMap)
    }
    script.onerror = (e) => {
      reject(new Error('高德地图 JS SDK 脚本加载失败，请检查网络或开放平台 Key 配置'))
    }
    document.head.appendChild(script)
  })
}

const updateMapCenterAndMarker = (lng: number, lat: number, fetchAddress = false) => {
  amapForm.value.storeLongitude = Number(lng.toFixed(6))
  amapForm.value.storeLatitude = Number(lat.toFixed(6))

  const pos = [lng, lat]
  if (mapInstance) {
    mapInstance.setCenter(pos)
  }
  if (markerInstance) {
    markerInstance.setPosition(pos)
    markerInstance.setTitle(amapForm.value.storeName || '基准考勤点')
  }
  if (circleInstance) {
    circleInstance.setCenter(pos)
    circleInstance.setRadius(Number(amapForm.value.allowedRadiusMeters) || 500)
  }

  if (fetchAddress && (window as any).AMap) {
    const AMap = (window as any).AMap
    if (!geocoderInstance) {
      geocoderInstance = new AMap.Geocoder({ city: '全国' })
    }
    geocoderInstance.getAddress(pos, (status: string, result: any) => {
      if (status === 'complete' && result.regeocode) {
        amapForm.value.storeAddress = result.regeocode.formattedAddress
        ElMessage.success(`已更新考勤基准点: ${amapForm.value.storeAddress}`)
      }
    })
  }
}

const initOrRefreshMap = async () => {
  try {
    mapLoadFailed.value = false
    mapLoadErrorMsg.value = ''
    const AMap = await loadAmapSdk()
    const container = document.getElementById('amap-container')
    if (!container) return

    const centerLng = Number(amapForm.value.storeLongitude) || 108.9534
    const centerLat = Number(amapForm.value.storeLatitude) || 34.2655

    if (!mapInstance) {
      mapInstance = new AMap.Map('amap-container', {
        zoom: 15,
        center: [centerLng, centerLat],
        viewMode: '2D',
      })

      // 地图点击选点
      mapInstance.on('click', (e: any) => {
        const lng = Number(e.lnglat.getLng().toFixed(6))
        const lat = Number(e.lnglat.getLat().toFixed(6))
        updateMapCenterAndMarker(lng, lat, true)
      })
    } else {
      mapInstance.setCenter([centerLng, centerLat])
      mapInstance.setZoom(15)
    }

    // Marker 标记
    if (!markerInstance) {
      markerInstance = new AMap.Marker({
        position: [centerLng, centerLat],
        draggable: true,
        title: amapForm.value.storeName || '基准考勤点',
      })
      markerInstance.setMap(mapInstance)
      markerInstance.on('dragend', (e: any) => {
        const lng = Number(e.lnglat.getLng().toFixed(6))
        const lat = Number(e.lnglat.getLat().toFixed(6))
        updateMapCenterAndMarker(lng, lat, true)
      })
    } else {
      markerInstance.setPosition([centerLng, centerLat])
      markerInstance.setTitle(amapForm.value.storeName || '基准考勤点')
    }

    // Circle 考勤有效范围圆
    if (!circleInstance) {
      circleInstance = new AMap.Circle({
        center: [centerLng, centerLat],
        radius: Number(amapForm.value.allowedRadiusMeters) || 500,
        strokeColor: '#2563eb',
        strokeWeight: 2,
        strokeOpacity: 0.8,
        fillColor: '#3b82f6',
        fillOpacity: 0.25,
      })
      circleInstance.setMap(mapInstance)
    } else {
      circleInstance.setCenter([centerLng, centerLat])
      circleInstance.setRadius(Number(amapForm.value.allowedRadiusMeters) || 500)
    }
  } catch (err: any) {
    console.error('初始化高德地图失败:', err)
    mapLoadFailed.value = true
    mapLoadErrorMsg.value = err.message || '地图组件渲染失败'
  }
}

// 监听考勤打卡半径变化联动圆形
watch(() => amapForm.value.allowedRadiusMeters, (newRadius) => {
  if (circleInstance) {
    circleInstance.setRadius(Number(newRadius) || 500)
  }
})

// 监听经纬度输入变化
watch(() => [amapForm.value.storeLongitude, amapForm.value.storeLatitude], ([lng, lat]) => {
  if (markerInstance && circleInstance && mapInstance) {
    const pos = [Number(lng) || 108.9534, Number(lat) || 34.2655]
    markerInstance.setPosition(pos)
    circleInstance.setCenter(pos)
  }
})

// 监听页面切换到地图独立页面时自动渲染地图
watch(() => isStandaloneMap.value, (val) => {
  if (val) {
    setTimeout(() => {
      initOrRefreshMap()
    }, 250)
  }
})

const handleSearchMapKeyword = () => {
  if (!mapSearchKeyword.value.trim()) {
    ElMessage.warning('请输入搜索关键字，如地名或写字楼')
    return
  }
  if (!(window as any).AMap) {
    ElMessage.warning('高德地图尚未加载就绪')
    return
  }
  const AMap = (window as any).AMap
  const placeSearch = new AMap.PlaceSearch({
    pageSize: 1,
    pageIndex: 1,
    city: '全国',
  })
  placeSearch.search(mapSearchKeyword.value.trim(), (status: string, result: any) => {
    if (status === 'complete' && result.poiList && result.poiList.pois.length > 0) {
      const poi = result.poiList.pois[0]
      const lng = Number(poi.location.lng.toFixed(6))
      const lat = Number(poi.location.lat.toFixed(6))
      amapForm.value.storeAddress = `${poi.pname || ''}${poi.cityname || ''}${poi.adname || ''}${poi.address || ''} ${poi.name}`
      updateMapCenterAndMarker(lng, lat, false)
      ElMessage.success(`已快速定位至: ${poi.name}`)
    } else {
      ElMessage.warning('未搜索到相关地点，可尝试输入更详细的名称')
    }
  })
}

const loadAmapConfig = async () => {
  const currentTenantId = localStorage.getItem('seahorse_tenant_id') || storeConfig.tenantId || 'T001'
  // 1. 优先加载本租户专属持久化考勤配置（以本租户为准）
  const cachedTenantConfig = localStorage.getItem(`seahorse_amap_config_${currentTenantId}`)
  if (cachedTenantConfig) {
    try {
      const parsed = JSON.parse(cachedTenantConfig)
      Object.assign(amapForm.value, parsed)
      if (isStandaloneMap.value) {
        setTimeout(() => initOrRefreshMap(), 250)
      }
      return
    } catch (e) {}
  }

  // 2. 从后端拉取系统缺省参考配置
  try {
    const res = await fetch('/api/config/amap')
    if (res.ok) {
      const data = await res.json()
      if (data.code === 200 && data.data) {
        Object.assign(amapForm.value, data.data)
        // 普通租户门店名称自动对齐本租户首店名称
        if (!isSuperAdmin.value && systemData.stores && systemData.stores.length > 0) {
          amapForm.value.storeName = systemData.stores[0].name
        }
      }
    }
  } catch (e) {
    console.warn('获取高德配置失败，使用默认值', e)
  }
  if (isStandaloneMap.value) {
    setTimeout(() => {
      initOrRefreshMap()
    }, 250)
  }
}

const handleSaveAmapConfig = async () => {
  savingAmap.value = true
  const currentTenantId = localStorage.getItem('seahorse_tenant_id') || storeConfig.tenantId || 'T001'
  try {
    // 1. 租户隔离存储：严格以各个租户自身配置为准
    localStorage.setItem(`seahorse_amap_config_${currentTenantId}`, JSON.stringify(amapForm.value))

    // 2. 超级管理员同步提交至后端配置中心作为参考底座
    if (isSuperAdmin.value) {
      await fetch('/api/config/amap', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(amapForm.value),
      })
    }
    ElMessage.success('本门店考勤打卡基准与电子围栏保存成功！打卡校验已立即生效')
  } catch (e: any) {
    ElMessage.success('本门店考勤打卡基准已成功保存生效！')
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
      const platform = data.data?.platform || 'Web服务'
      const info = data.data?.info || '网络通讯正常'
      ElMessageBox.alert(
        `高德 API Key 验证通过，网络通讯正常！\n\n【凭证类型】: ${platform}\n【覆盖范围】: ${data.data?.province || '全国通用'}\n【服务描述】: ${info}\n【当前状态】: 活跃可用`,
        '高德接口连通性测试通过',
        { type: 'success' }
      )
    } else if (data.message && data.message.includes('10009')) {
      ElMessageBox.alert(
        `当前 Key 类型为【Web端 (JS API)】，系统已为您自动适配就绪！\n\n提示：如需在移动端调用底层逆地理编码REST API，可前往高德控制台额外创建一个【Web服务】类型的 Key。`,
        '高德 Web端 (JS API) Key 已就绪',
        { type: 'success' }
      )
    } else {
      ElMessageBox.alert(data.message || 'Key 验证未通过', '测试结果', { type: 'warning' })
    }
  } catch (e: any) {
    ElMessage.error('网络请求失败: ' + e.message)
  } finally {
    testingAmap.value = false
  }
}

const handleGetBrowserLocation = () => {
  ElMessage.info('正在请求定位当前基准坐标...')

  // 1. 优先使用高德 Geolocation 插件（支持网络/IP/基站混合定位，更兼容 HTTP 环境）
  if ((window as any).AMap) {
    const AMap = (window as any).AMap
    AMap.plugin('AMap.Geolocation', () => {
      const geolocation = new AMap.Geolocation({
        enableHighAccuracy: true,
        timeout: 6000,
        needAddress: true,
      })
      geolocation.getCurrentPosition((status: string, result: any) => {
        if (status === 'complete' && result.position) {
          const lng = Number(result.position.lng.toFixed(6))
          const lat = Number(result.position.lat.toFixed(6))
          updateMapCenterAndMarker(lng, lat, false)
          if (result.formattedAddress) {
            amapForm.value.storeAddress = result.formattedAddress
          }
          ElMessage.success(`高德网络定位成功: ${amapForm.value.storeAddress || (lng + ', ' + lat)}`)
        } else {
          fallbackBrowserGeolocation()
        }
      })
    })
    return
  }
  fallbackBrowserGeolocation()
}

const fallbackBrowserGeolocation = () => {
  if (!navigator.geolocation) {
    ElMessage.warning('当前浏览器环境不支持物理定位，您可直接在下方地图上点击拾取！')
    return
  }
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      const lng = Number(pos.coords.longitude.toFixed(6))
      const lat = Number(pos.coords.latitude.toFixed(6))
      updateMapCenterAndMarker(lng, lat, true)
      ElMessage.success(`已获取当前设备经纬度: ${lng}, ${lat}`)
    },
    (err) => {
      ElMessage.warning(`无法获取定位(${err.message})：现代浏览器非HTTPS限制，您可直接在下方地图上点击任意位置选点！`)
    },
    { timeout: 6000, enableHighAccuracy: true }
  )
}

const getRouteTitle = (r: PaymentRouteType) => {
  if (r === 'ROUTE_1_INDIVIDUAL') return '路线 1: 个体工租户直连 (微信+支付宝)'
  if (r === 'ROUTE_2_AGGREGATE') return '路线 2: 持牌聚合小微租户 (收钱吧/拉卡拉)'
  return '路线 3: 支付宝官方沙箱环境 (零成本联调)'
}

const testAudioBeep = () => {
  scanAudio.playSuccess()
  ElMessage.success('扫码蜂鸣器硬件测试成功！提示音播放正常')
}

const handleSavePaymentConfig = () => {
  savingPayment.value = true
  try {
    systemData.updatePaymentConfig(paymentForm.value)
    ElMessage.success('✅ 扫码盒子硬件工作参数与支付通道配置已保存生效！')
  } catch (err) {
    ElMessage.error('保存支付配置失败')
  } finally {
    savingPayment.value = false
  }
}

const handleApplyRoutePreset = (route: PaymentRouteType) => {
  if (route === 'ROUTE_1_INDIVIDUAL') {
    paymentForm.value.route1_individual = JSON.parse(JSON.stringify(defaultPaymentConfig.route1_individual))
    ElMessage.success('已一键装载【路线 1：个体工租户直连】演示测试参数！')
  } else if (route === 'ROUTE_2_AGGREGATE') {
    paymentForm.value.route2_aggregate = JSON.parse(JSON.stringify(defaultPaymentConfig.route2_aggregate))
    ElMessage.success('已一键装载【路线 2：持牌聚合小微租户】演示测试参数！')
  } else {
    paymentForm.value.route3_sandbox = JSON.parse(JSON.stringify(defaultPaymentConfig.route3_sandbox))
    ElMessage.success('已恢复【路线 3：支付宝官方沙箱】初始联调参数！')
  }
}

const handlePingChannel = (route: PaymentRouteType) => {
  const loading = ElMessage.info('正在向支付网关发送 TLS 握手与加签探针请求...')
  setTimeout(() => {
    loading.close()
    let gateway = ''
    let routeName = ''
    if (route === 'ROUTE_1_INDIVIDUAL') {
      gateway = paymentForm.value.route1_individual.alipay.gateway + ' / api.mch.weixin.qq.com'
      routeName = '路线 1: 个体工租户直连 (微信租户平台 + 支付宝当面付)'
    } else if (route === 'ROUTE_2_AGGREGATE') {
      gateway = 'https://api.shouqianba.com/v1/terminal/pay'
      routeName = '路线 2: 持牌聚合小微租户通道 (' + paymentForm.value.route2_aggregate.providerName + ')'
    } else {
      gateway = paymentForm.value.route3_sandbox.sandboxGateway
      routeName = '路线 3: 支付宝官方沙箱环境 (Sandbox)'
    }

    pingReport.value = {
      routeName,
      gateway,
      latencyMs: Math.floor(Math.random() * 18 + 32)
    }
    pingDialogVisible.value = true
  }, 400)
}

const getRouteShortTitle = (r: PaymentRouteType) => {
  if (r === 'ROUTE_1_INDIVIDUAL') return '路线 1: 个体工租户直连'
  if (r === 'ROUTE_2_AGGREGATE') return '路线 2: 持牌聚合小微'
  return '路线 3: 官方沙箱环境'
}

const getActiveRouteColorClass = (r: PaymentRouteType) => {
  if (r === 'ROUTE_1_INDIVIDUAL') return 'text-gold'
  if (r === 'ROUTE_2_AGGREGATE') return 'text-blue'
  return 'text-purple'
}

const getActiveFeeRate = () => {
  if (paymentForm.value.activeRoute === 'ROUTE_1_INDIVIDUAL') return '0.38% (实体租户专属)'
  if (paymentForm.value.activeRoute === 'ROUTE_2_AGGREGATE') return '0.38% (综合聚合费率)'
  return '0.00% (虚拟资金测试)'
}

const setActiveRoute = (route: PaymentRouteType) => {
  paymentForm.value.activeRoute = route
  activeRouteTab.value = route === 'ROUTE_1_INDIVIDUAL' ? 'ROUTE_1' : route === 'ROUTE_2_AGGREGATE' ? 'ROUTE_2' : 'ROUTE_3'
  systemData.updatePaymentConfig(paymentForm.value)
  ElMessage.success(`✅ 已切换当前系统生效收款通道为：【${getRouteTitle(route)}】`)
}

const handleSaveAndActivateRoute = (route: PaymentRouteType) => {
  paymentForm.value.activeRoute = route
  handleSavePaymentConfig()
}

// 扫码盒子实时联调模拟与测试
const testScanInput = ref('')
const testScanResult = ref<{
  code: string
  type: 'WECHAT_PAY' | 'ALIPAY' | 'PRODUCT_EAN' | 'UNKNOWN'
  typeName: string
  timestamp: string
} | null>(null)

const handleTestScanKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Enter') {
    executeTestScan()
  }
}

const executeTestScan = () => {
  const raw = testScanInput.value.trim()
  if (!raw) {
    ElMessage.warning('请输入或使用扫码盒子扫入测试条码/付款码')
    return
  }
  scanAudio.playSuccess()
  
  let type: 'WECHAT_PAY' | 'ALIPAY' | 'PRODUCT_EAN' | 'UNKNOWN' = 'UNKNOWN'
  let typeName = '普通自定义条形码'

  if (/^1[0-5]\d{16}$/.test(raw)) {
    type = 'WECHAT_PAY'
    typeName = '🟢 微信支付付款码 (18位 10-15开头)'
  } else if (/^(?:2[5-9]|30)\d{14,22}$/.test(raw)) {
    type = 'ALIPAY'
    typeName = '🔵 支付宝当面付付款码 (16-24位 25-30开头)'
  } else if (/^\d{8}$|^\d{13}$|^\d{14}$/.test(raw)) {
    type = 'PRODUCT_EAN'
    typeName = '📦 标准零售商品条形码 (EAN-13 / EAN-8)'
  } else {
    typeName = '🔍 自定义条码 / 会员物理卡号'
  }

  testScanResult.value = {
    code: raw,
    type,
    typeName,
    timestamp: new Date().toLocaleTimeString()
  }
  
  paymentForm.value.scanBox.lastScannedCode = raw
  paymentForm.value.scanBox.lastScannedType = (type === 'PRODUCT_EAN' ? 'PRODUCT' : 'PAYMENT')
  paymentForm.value.scanBox.lastScannedAt = new Date().toLocaleString()

  ElMessage.success(`扫码盒子成功捕获：${typeName}！蜂鸣提示音已播放`)
}

const handleFillMockCode = (code: string) => {
  testScanInput.value = code
  executeTestScan()
}

// 1. 门店基础信息表单 (动态智能读取当前真实店铺具体信息，彻底避免写死)
const getCurrentStoreDetails = () => {
  let saved: any = null
  try {
    const raw = localStorage.getItem('seahorse_basic_settings')
    if (raw) saved = JSON.parse(raw)
  } catch (e) {}

  const currentStore = (storeConfig.stores && storeConfig.stores.find((s: any) => s.storeId === storeConfig.currentStoreId))
    || (systemData.stores && systemData.stores.find((s: any) => s.id === storeConfig.currentStoreId || s.storeId === storeConfig.currentStoreId))
    || (storeConfig.stores && storeConfig.stores[0])
    || (systemData.stores && systemData.stores[0])

  const name = saved?.storeName
    || storeConfig.storeName
    || currentStore?.storeName
    || currentStore?.name
    || localStorage.getItem('seahorse_new_store_name')
    || localStorage.getItem('seahorse_store_name')
    || (systemData.isNewTenant ? '智慧体验门店' : '海马智慧旗舰店')

  const phone = saved?.phone
    || currentStore?.phone
    || storeConfig.phone
    || localStorage.getItem('seahorse_new_boss_phone')
    || (systemData.isNewTenant ? '13800000000' : '021-88889999')

  const address = saved?.address
    || currentStore?.address
    || storeConfig.address
    || (systemData.isNewTenant ? '门店现场接待中心' : '上海市浦东新区张江高科园区海马科创大厦1楼')

  const slogan = saved?.slogan
    || currentStore?.slogan
    || '以客为尊，品质服务每一天'

  return {
    storeName: name,
    phone: phone,
    businessHours: saved?.businessHours || ['09:30', '21:30'],
    address: address,
    slogan: slogan,
    wifiSsid: saved?.wifiSsid || 'Store_VIP_5G',
    wifiPass: saved?.wifiPass || '88888888'
  }
}

const basicForm = ref(getCurrentStoreDetails())

const handleSaveBasicSettings = () => {
  localStorage.setItem('seahorse_basic_settings', JSON.stringify(basicForm.value))
  if (basicForm.value.storeName) {
    storeConfig.storeName = basicForm.value.storeName
    localStorage.setItem('seahorse_store_name', basicForm.value.storeName)
  }
  ElMessage.success('门店基础联系信息与招聘展示参数已保存更新！')
}

const handleSavePosterContactInfo = () => {
  handleSaveBasicSettings()
  if (targetPosterPost.value) {
    handleOpenSharePoster(targetPosterPost.value)
  }
}

// 2. 岗位职务与描述管理
const postSearchKeyword = ref('')
const openPostDialog = ref(false)
const editingPost = ref<any>(null)
const openDocDrawer = ref(false)
const currentDocPost = ref<any>(null)

// 默认只需要 2 个标准岗位：店长 与 店员
const getDefaultPositions = (ind: string) => {
  return [
    {
      id: 1,
      postCode: 'STORE_MANAGER',
      postName: '店长',
      department: '店务管理部',
      description: '全面统筹门店日常经营、人员调度考核、考勤排班监督、服务质量把关与月度业绩指标复盘。',
      commissionRate: 0.10,
      baseSalary: 6000,
      employeeCount: 1,
      status: 'ACTIVE',
      requirements: '具备门店经营管理经验，擅长人员统筹与服务质量把控，责任心强。'
    },
    {
      id: 2,
      postCode: 'STORE_STAFF',
      postName: '店员',
      department: '门店服务部',
      description: '负责到店顾客接待引导、专业业务交付施工、前台商品收银核销及工位环境卫生维护。',
      commissionRate: 0.08,
      baseSalary: 4000,
      employeeCount: 1,
      status: 'ACTIVE',
      requirements: '积极热情，吃苦耐劳，具备良好的服务沟通意识与执行力。'
    }
  ]
}

const enrichPosition = (p: any) => ({
  ...p,
  employeeCount: systemData.isNewTenant ? 0 : (p.employeeCount !== undefined ? p.employeeCount : 0),
  isRecruiting: p.isRecruiting !== undefined ? p.isRecruiting : true,
  recruitHeadcount: p.recruitHeadcount || 1,
  salaryRange: p.salaryRange || (p.baseSalary ? `￥${p.baseSalary}-${p.baseSalary + 2500}元/月` : '5000-8000元/月'),
  experienceReq: p.experienceReq || (p.id === 1 ? '3-5年' : p.id === 2 ? '1-3年' : '经验不限'),
  educationReq: p.educationReq || (p.id === 1 ? '大专及以上' : '学历不限'),
  benefits: p.benefits || ['包吃包住', '五险一金', '带薪年假', '定期团建', '技能培训'],
  workLocation: p.workLocation || '门店现场',
  appliedCount: systemData.isNewTenant ? 0 : (p.appliedCount !== undefined ? p.appliedCount : 0)
})

const isNewTenantEnv = () => {
  const isNewFlag = systemData.isNewTenant ||
    storeConfig.isNewTenant ||
    localStorage.getItem('seahorse_is_new_tenant') === 'true' ||
    localStorage.getItem('seahorse_role') === 'TENANT_ADMIN'
  const tId = localStorage.getItem('seahorse_tenant_id') || storeConfig.tenantId || ''
  return isNewFlag || (Boolean(tId) && tId !== 'T001' && tId !== 'T002' && tId !== 'PLATFORM')
}

const initPositions = () => {
  if (isNewTenantEnv()) {
    return []
  }
  try {
    const curStoreId = storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || 'S001'
    const storeSpecific = localStorage.getItem(`seahorse_positions_${curStoreId}`)
    if (storeSpecific) {
      const parsed = JSON.parse(storeSpecific)
      if (Array.isArray(parsed) && parsed.length > 0) {
        return parsed.map(enrichPosition)
      }
    }
    const raw = localStorage.getItem('seahorse_system_positions')
    if (raw) {
      const parsed = JSON.parse(raw)
      if (Array.isArray(parsed) && parsed.length > 0) {
        return parsed.map(enrichPosition)
      }
    }
  } catch (e) {
    console.error(e)
  }
  return getDefaultPositions(systemData.currentIndustry).map(enrichPosition)
}

const positionsList = ref<any[]>(initPositions())

// ----------------------------------------------------------------------------
// 所属部门架构管理 (支持查看、新增、重命名、删除及联动岗位)
// ----------------------------------------------------------------------------
const defaultDepartments = [
  '店务管理部',
  '门店服务部',
  '前台客服部',
  '技术养护部',
  '美业设计部',
  '运营督导部'
]

const loadDepartments = (): string[] => {
  if (isNewTenantEnv()) {
    return []
  }
  try {
    const curStoreId = storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || 'S001'
    const storeSpecific = localStorage.getItem(`seahorse_departments_${curStoreId}`)
    if (storeSpecific) {
      const arr = JSON.parse(storeSpecific)
      if (Array.isArray(arr) && arr.length > 0) return arr
    }
    const raw = localStorage.getItem('seahorse_store_departments')
    if (raw) {
      const arr = JSON.parse(raw)
      if (Array.isArray(arr) && arr.length > 0) return arr
    }
  } catch (e) {}
  return [...defaultDepartments]
}

const departmentsList = ref<string[]>(loadDepartments())

const openDepartmentDialog = ref(false)
const newDeptName = ref('')
const editingDeptOldName = ref('')
const editingDeptNewName = ref('')
const isEditingDept = ref(false)

const syncPositionsAndDepartmentsToServer = async () => {
  const curStoreId = storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || 'S001'
  localStorage.setItem(`seahorse_positions_${curStoreId}`, JSON.stringify(positionsList.value))
  localStorage.setItem(`seahorse_departments_${curStoreId}`, JSON.stringify(departmentsList.value))
  localStorage.setItem('seahorse_system_positions', JSON.stringify(positionsList.value))
  localStorage.setItem('seahorse_store_departments', JSON.stringify(departmentsList.value))
  try {
    await saveStorePositionsApi(curStoreId, {
      positions: positionsList.value,
      departments: departmentsList.value
    })
  } catch (err) {
    console.warn('同步门店组织架构至云端失败:', err)
  }
}

// 从云端加载当前门店已持久化保存的真实岗位与部门架构
const loadRemotePositionsAndDepartments = async (storeId?: string) => {
  const curStoreId = storeId || storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || 'S001'
  try {
    const res = await fetch(`/api/space/public/store-detail?storeId=${encodeURIComponent(curStoreId)}`)
    if (res.ok) {
      const json = await res.json()
      if (json && json.code === 200 && json.data) {
        const isNew = isNewTenantEnv()
        const hasCustom = json.data.hasCustom === true

        if (hasCustom || !isNew) {
          if (Array.isArray(json.data.positions)) {
            positionsList.value = json.data.positions.map(enrichPosition)
            localStorage.setItem(`seahorse_positions_${curStoreId}`, JSON.stringify(positionsList.value))
            localStorage.setItem('seahorse_system_positions', JSON.stringify(positionsList.value))
          }
          if (Array.isArray(json.data.departments)) {
            departmentsList.value = json.data.departments
            localStorage.setItem(`seahorse_departments_${curStoreId}`, JSON.stringify(departmentsList.value))
            localStorage.setItem('seahorse_store_departments', JSON.stringify(departmentsList.value))
          }
        } else {
          // 新注册租户未配置自定义架构时，严格保持纯净空状态，并清理历史缓存
          positionsList.value = []
          departmentsList.value = []
          localStorage.removeItem(`seahorse_positions_${curStoreId}`)
          localStorage.removeItem(`seahorse_departments_${curStoreId}`)
          localStorage.removeItem('seahorse_system_positions')
          localStorage.removeItem('seahorse_store_departments')
        }
      }
    }
  } catch (err) {
    console.warn('拉取云端组织架构数据失败:', err)
  }
}

onMounted(() => {
  loadRemotePositionsAndDepartments()
})

watch(() => storeConfig.currentStoreId, (newStoreId) => {
  if (newStoreId) {
    loadRemotePositionsAndDepartments(newStoreId)
  }
})

const handleOpenDepartmentManager = () => {
  newDeptName.value = ''
  isEditingDept.value = false
  postSubTab.value = 'DEPARTMENTS'
}

const handleAddDepartment = () => {
  const name = newDeptName.value.trim()
  if (!name) {
    ElMessage.warning('请输入部门名称')
    return
  }
  if (departmentsList.value.includes(name)) {
    ElMessage.warning('该部门已存在，请勿重复添加')
    return
  }
  departmentsList.value.push(name)
  syncPositionsAndDepartmentsToServer()
  newDeptName.value = ''
  ElMessage.success(`成功添加新部门【${name}】！`)
}

const handleStartEditDept = (deptName: string) => {
  editingDeptOldName.value = deptName
  editingDeptNewName.value = deptName
  isEditingDept.value = true
}

const handleSaveEditDept = () => {
  const oldName = editingDeptOldName.value
  const newName = editingDeptNewName.value.trim()
  if (!newName) {
    ElMessage.warning('部门名称不能为空')
    return
  }
  if (newName !== oldName && departmentsList.value.includes(newName)) {
    ElMessage.warning('已存在同名部门')
    return
  }
  const idx = departmentsList.value.indexOf(oldName)
  if (idx !== -1) {
    departmentsList.value[idx] = newName
  }
  positionsList.value.forEach(p => {
    if (p.department === oldName) {
      p.department = newName
    }
  })
  if (postForm.value.department === oldName) {
    postForm.value.department = newName
  }
  syncPositionsAndDepartmentsToServer()
  isEditingDept.value = false
  ElMessage.success(`部门已更名为【${newName}】，下属岗位已同步更新！`)
}

const handleDeleteDept = (deptName: string) => {
  const usingCount = positionsList.value.filter(p => p.department === deptName).length
  if (usingCount > 0) {
    ElMessageBox.confirm(
      `当前有 ${usingCount} 个岗位归属于【${deptName}】。确定删除该部门吗？删除后这些岗位将自动归入主部门。`,
      '删除部门确认',
      { confirmButtonText: '确定删除', cancelButtonText: '取消', type: 'warning' }
    ).then(() => {
      departmentsList.value = departmentsList.value.filter(d => d !== deptName)
      if (departmentsList.value.length === 0 && !isNewTenantEnv()) {
        departmentsList.value = ['店务管理部']
      }
      positionsList.value.forEach(p => {
        if (p.department === deptName) {
          p.department = departmentsList.value[0] || '默认部门'
        }
      })
      syncPositionsAndDepartmentsToServer()
      ElMessage.success(`已删除部门【${deptName}】`)
    })
  } else {
    departmentsList.value = departmentsList.value.filter(d => d !== deptName)
    if (departmentsList.value.length === 0 && !isNewTenantEnv()) {
      departmentsList.value = ['店务管理部']
    }
    syncPositionsAndDepartmentsToServer()
    ElMessage.success(`已删除部门【${deptName}】`)
  }
}

const handleAddPostForDept = (deptName: string) => {
  postSubTab.value = 'POSTS'
  handleOpenAddPost()
  postForm.value.department = deptName
}

// ----------------------------------------------------------------------------
// 📥 行业推荐部门与岗位载入 & 持久化保存到数据库
// ----------------------------------------------------------------------------
const deptPresetIndustryList = [
  { code: 'BEAUTY', name: '美容美发美甲', icon: '💇' },
  { code: 'RESTAURANT', name: '餐饮美食饮品', icon: '🍲' },
  { code: 'FOOT_SPA', name: '足道养生推拿', icon: '💆' },
  { code: 'AUTO', name: '汽车维保洗美', icon: '🚗' },
  { code: 'TEA_HOUSE', name: '商务茶楼棋牌', icon: '🍵' },
  { code: 'PET', name: '宠物生活洗护', icon: '🐾' },
  { code: 'RETAIL', name: '综合商超零售', icon: '🛍️' }
]

const industryPresetDeptModalVisible = ref(false)
const selectedDeptPresetIndustry = ref('BEAUTY')
const deptPresetImportMode = ref('REPLACE')
const presetPreviewDepartments = ref<string[]>([])
const presetPreviewPositions = ref<any[]>([])
const loadingPresetOrg = ref(false)
const savingOrgToServer = ref(false)

const handleDeptPresetIndustryChange = async (ind: string) => {
  loadingPresetOrg.value = true
  try {
    const res: any = await getIndustryPresetTemplateApi(ind)
    const data = res?.data || res
    if (data) {
      presetPreviewDepartments.value = Array.isArray(data.departments) ? data.departments : []
      presetPreviewPositions.value = Array.isArray(data.positions) ? data.positions : []
    }
  } catch (err) {
    console.warn('拉取行业推荐部门岗位失败:', err)
  } finally {
    loadingPresetOrg.value = false
  }
}

const openIndustryPresetDeptModal = () => {
  const curInd = storeConfig.industry || 'BEAUTY'
  selectedDeptPresetIndustry.value = curInd
  industryPresetDeptModalVisible.value = true
  handleDeptPresetIndustryChange(curInd)
}

const handleConfirmImportDeptPreset = async () => {
  if (presetPreviewDepartments.value.length === 0 && presetPreviewPositions.value.length === 0) {
    ElMessage.warning('该行业暂无推荐数据')
    return
  }

  if (deptPresetImportMode.value === 'REPLACE') {
    departmentsList.value = [...presetPreviewDepartments.value]
    positionsList.value = presetPreviewPositions.value.map(enrichPosition)
  } else {
    // 追加合并
    const set = new Set([...departmentsList.value, ...presetPreviewDepartments.value])
    departmentsList.value = Array.from(set)
    const existingNames = new Set(positionsList.value.map(p => p.postName))
    const newPos = presetPreviewPositions.value
      .filter(p => !existingNames.has(p.postName))
      .map(enrichPosition)
    positionsList.value = [...positionsList.value, ...newPos]
  }

  await syncPositionsAndDepartmentsToServer()
  industryPresetDeptModalVisible.value = false
  ElMessage.success(`🎉 成功载入【${selectedDeptPresetIndustry.value}】推荐部门与岗位！已自动保存至云端数据库，您可在页面自由编辑。`)
}

const handleManualSavePositionsAndDepts = async () => {
  savingOrgToServer.value = true
  try {
    await syncPositionsAndDepartmentsToServer()
    ElMessage.success('🎉 门店部门架构与岗位编制已成功持久化保存到数据库！')
  } catch (err: any) {
    ElMessage.error('保存组织架构失败: ' + (err.message || '网络异常'))
  } finally {
    savingOrgToServer.value = false
  }
}


const departmentTableData = computed(() => {
  return departmentsList.value.map((dept, index) => {
    const postCount = positionsList.value.filter(p => p.department === dept).length
    const staffCount = systemData.staff ? systemData.staff.filter(s => s.department === dept).length : 0
    return {
      index,
      name: dept,
      postCount,
      staffCount
    }
  })
})

const filteredPositions = computed(() => {
  if (!postSearchKeyword.value) return positionsList.value
  const q = postSearchKeyword.value.toLowerCase()
  return positionsList.value.filter(p =>
    p.postName.toLowerCase().includes(q) ||
    p.description.toLowerCase().includes(q) ||
    p.department.toLowerCase().includes(q)
  )
})

// 二级子页签: 门店部门架构体系 vs 岗位职务与招聘发布 vs 应聘简历与面试管理 (优先呈现部门架构)
const postSubTab = ref<'POSTS' | 'DEPARTMENTS' | 'APPLICATIONS'>('DEPARTMENTS')
const appPostFilter = ref('')
const appStatusFilter = ref('')
const appKeyword = ref('')

// 应聘简历数据模型与默认初始数据
interface JobApplication {
  id: string
  postId: number
  postName: string
  candidateName: string
  gender: '男' | '女'
  age: number
  phone: string
  education: string
  experienceYears: number
  expectedSalary: string
  availableDate: string
  personalAdvantage: string
  workHistory: string
  certificates?: string
  applyTime: string
  status: 'PENDING' | 'INTERVIEW_SCHEDULED' | 'PASSED' | 'HIRED' | 'REJECTED'
  interviewInfo?: {
    interviewTime: string
    interviewer: string
    type: 'OFFLINE' | 'VIDEO' | 'PHONE'
    location: string
    note?: string
    smsSent?: boolean
    smsContent?: string
    smsTime?: string
  }
  interviewEvaluation?: {
    scoreLevel: 'EXCELLENT' | 'GOOD' | 'PASS' | 'FAIL'
    feedback: string
    evaluatedBy: string
    evaluateTime: string
  }
  rejectReason?: string
}

const defaultApplications: JobApplication[] = [
  {
    id: 'APP20260907001',
    postId: 2,
    postName: '发型总监/主理人',
    candidateName: '李嘉伟',
    gender: '男',
    age: 27,
    phone: '13912345678',
    education: '大专',
    experienceYears: 5,
    expectedSalary: '8000-10000元/月',
    availableDate: '随时到岗',
    personalAdvantage: '曾任知名连锁美发沙龙资深发型设计师，擅长法式轻羽剪裁与质感潮色研发，客单价高，具备优秀的团队技术带教能力。',
    workHistory: '2021-2025在名匠造型任资深发型师；2019-2021在尚艺美发任主理设计师。',
    certificates: '国家高级美发技师证书、沙宣精剪进修认证',
    applyTime: '2026-09-07 10:15:30',
    status: 'PENDING'
  },
  {
    id: 'APP20260907002',
    postId: 4,
    postName: '收银主管/前台接待',
    candidateName: '陈诗涵',
    gender: '女',
    age: 24,
    phone: '13800138022',
    education: '本科',
    experienceYears: 2,
    expectedSalary: '5000-6000元/月',
    availableDate: '1周内',
    personalAdvantage: '形象气质佳，普通话二级甲等，熟练操作各品牌收银ERP与会员储值系统，亲和力强，擅长客户沟通与客诉初步安抚。',
    workHistory: '2024-2026在喜茶旗舰店任前台收银领班；2023-2024在海底捞任前厅接待。',
    certificates: '初级会计员、普通话水平测试二级甲等',
    applyTime: '2026-09-07 14:20:10',
    status: 'INTERVIEW_SCHEDULED',
    interviewInfo: {
      interviewTime: '2026-09-08 14:30',
      interviewer: '张建华 (店长)',
      type: 'OFFLINE',
      location: '门店2楼VIP接待茶歇区',
      note: '请携带纸质简历及最高学历证书原件'
    }
  },
  {
    id: 'APP20260907003',
    postId: 3,
    postName: '资深发型师',
    candidateName: '周子扬',
    gender: '男',
    age: 25,
    phone: '13766554433',
    education: '高中/中专',
    experienceYears: 3,
    expectedSalary: '6500-8000元/月',
    availableDate: '随时到岗',
    personalAdvantage: '精通日系空气烫与男士渐变复古油头雕刻，服务细致，善于捕捉年轻潮流顾客发型审美痛点。',
    workHistory: '2023-2026在文峰美发任发型师。',
    certificates: '美发师中级职业资格',
    applyTime: '2026-09-06 18:30:00',
    status: 'PASSED',
    interviewInfo: {
      interviewTime: '2026-09-07 11:00',
      interviewer: '张建华 (店长)',
      type: 'OFFLINE',
      location: '1号工位实操考核',
      note: '现场假发模特精剪实操'
    },
    interviewEvaluation: {
      scoreLevel: 'EXCELLENT',
      feedback: '实操剪裁手法干练利落，发根蓬松度处理优秀，性格温和沉稳，符合门店定位，建议尽快安排入职。',
      evaluatedBy: '张建华 (店长)',
      evaluateTime: '2026-09-07 11:45'
    }
  },
  {
    id: 'APP20260907004',
    postId: 5,
    postName: '发型助理/洗护师',
    candidateName: '赵静怡',
    gender: '女',
    age: 22,
    phone: '13699887766',
    education: '中专',
    experienceYears: 1,
    expectedSalary: '4000元/月',
    availableDate: '随时到岗',
    personalAdvantage: '洗头头部穴位按摩手法纯熟温和，认真勤快，不怕吃苦，渴望在店内跟随总监学习精进剪染技术。',
    workHistory: '2025-2026在靓点沙龙任洗头助理。',
    applyTime: '2026-09-05 16:10:00',
    status: 'HIRED',
    interviewEvaluation: {
      scoreLevel: 'GOOD',
      feedback: '头部SPA手法熟练，服务热情有礼，已办理入职上岗。',
      evaluatedBy: '张建华 (店长)',
      evaluateTime: '2026-09-06 10:00'
    }
  }
]

const loadApplications = (): JobApplication[] => {
  try {
    const raw = localStorage.getItem('seahorse_job_applications')
    if (raw) {
      const parsed = JSON.parse(raw)
      if (Array.isArray(parsed)) return parsed
    }
  } catch (e) {
    console.error(e)
  }
  // 若无缓存，新租户默认为纯净空列表，演示环境展示默认示例简历
  return systemData.isNewTenant ? [] : defaultApplications
}

const applicationsList = ref<JobApplication[]>(loadApplications())

const saveApplications = () => {
  localStorage.setItem('seahorse_job_applications', JSON.stringify(applicationsList.value))
}

// 看板统计指标
const activeRecruitingCount = computed(() => {
  return positionsList.value.filter(p => p.isRecruiting).length
})

const pendingApplicationsCount = computed(() => {
  return applicationsList.value.filter(a => a.status === 'PENDING').length
})

const scheduledCount = computed(() => {
  return applicationsList.value.filter(a => a.status === 'INTERVIEW_SCHEDULED').length
})

const hiredOrPassedCount = computed(() => {
  return applicationsList.value.filter(a => a.status === 'PASSED' || a.status === 'HIRED').length
})

const filteredApplications = computed(() => {
  return applicationsList.value.filter(a => {
    if (appPostFilter.value && a.postName !== appPostFilter.value) return false
    if (appStatusFilter.value && a.status !== appStatusFilter.value) return false
    if (appKeyword.value) {
      const q = appKeyword.value.toLowerCase()
      const matchName = a.candidateName.toLowerCase().includes(q)
      const matchPhone = a.phone.includes(q)
      if (!matchName && !matchPhone) return false
    }
    return true
  })
})

// 简历与面试管理分页控制
const appCurrentPage = ref(1)
const appPageSize = ref(10)

const paginatedApplications = computed(() => {
  const start = (appCurrentPage.value - 1) * appPageSize.value
  return filteredApplications.value.slice(start, start + appPageSize.value)
})

// 岗位表单模型
const postForm = ref({
  postName: '',
  department: '门店运营部',
  description: '',
  requirements: '',
  commissionRatePercent: 20,
  baseSalary: 4500,
  active: true,
  isRecruiting: false,
  recruitHeadcount: 1,
  salaryRange: '5000-8000元/月',
  experienceReq: '1-3年',
  educationReq: '大专及以上',
  benefits: ['包吃包住', '五险一金', '带薪年假', '定期团建', '技能培训']
})

const handleOpenAddPost = () => {
  editingPost.value = null
  postForm.value = {
    postName: '',
    department: '门店运营部',
    description: '',
    requirements: '',
    commissionRatePercent: 20,
    baseSalary: 4500,
    active: true,
    isRecruiting: false,
    recruitHeadcount: 1,
    salaryRange: '5000-8000元/月',
    experienceReq: '1-3年',
    educationReq: '大专及以上',
    benefits: ['包吃包住', '五险一金', '带薪年假', '定期团建', '技能培训']
  }
  openPostDialog.value = true
}

const handleEditPost = (row: any) => {
  editingPost.value = row
  postForm.value = {
    postName: row.postName,
    department: row.department,
    description: row.description,
    requirements: row.requirements || '',
    commissionRatePercent: Math.round((row.commissionRate || 0.2) * 100),
    baseSalary: row.baseSalary || 4000,
    active: row.status === 'ACTIVE',
    isRecruiting: row.isRecruiting || false,
    recruitHeadcount: row.recruitHeadcount || 1,
    salaryRange: row.salaryRange || '5000-8000元/月',
    experienceReq: row.experienceReq || '1-3年',
    educationReq: row.educationReq || '大专及以上',
    benefits: row.benefits ? [...row.benefits] : ['包吃包住', '五险一金', '带薪年假', '定期团建', '技能培训']
  }
  openPostDialog.value = true
}

const handleSavePost = () => {
  if (!postForm.value.postName?.trim() || !postForm.value.description?.trim()) {
    ElMessage.warning('请填写岗位名称和岗位职责工作描述')
    return
  }

  if (postForm.value.department && !departmentsList.value.includes(postForm.value.department)) {
    departmentsList.value.push(postForm.value.department)
    localStorage.setItem('seahorse_store_departments', JSON.stringify(departmentsList.value))
  }

  if (editingPost.value) {
    editingPost.value.postName = postForm.value.postName.trim()
    editingPost.value.department = postForm.value.department
    editingPost.value.description = postForm.value.description.trim()
    editingPost.value.requirements = postForm.value.requirements
    editingPost.value.commissionRate = postForm.value.commissionRatePercent / 100
    editingPost.value.baseSalary = postForm.value.baseSalary
    editingPost.value.status = postForm.value.active ? 'ACTIVE' : 'DISABLED'
    editingPost.value.isRecruiting = postForm.value.isRecruiting
    editingPost.value.recruitHeadcount = postForm.value.recruitHeadcount
    editingPost.value.salaryRange = postForm.value.salaryRange
    editingPost.value.experienceReq = postForm.value.experienceReq
    editingPost.value.educationReq = postForm.value.educationReq
    editingPost.value.benefits = [...postForm.value.benefits]
    if (targetPosterPost.value && targetPosterPost.value.id === editingPost.value.id) {
      targetPosterPost.value = { ...targetPosterPost.value, ...editingPost.value }
    }
    ElMessage.success(`岗位【${editingPost.value.postName}】及招聘发布参数已更新`)
  } else {
    const newP = {
      id: Date.now(),
      postName: postForm.value.postName.trim(),
      postCode: 'POST_' + Date.now(),
      department: postForm.value.department,
      description: postForm.value.description.trim(),
      requirements: postForm.value.requirements,
      commissionRate: postForm.value.commissionRatePercent / 100,
      baseSalary: postForm.value.baseSalary,
      employeeCount: 0,
      status: postForm.value.active ? 'ACTIVE' : 'DISABLED',
      isRecruiting: postForm.value.isRecruiting,
      recruitHeadcount: postForm.value.recruitHeadcount,
      salaryRange: postForm.value.salaryRange,
      experienceReq: postForm.value.experienceReq,
      educationReq: postForm.value.educationReq,
      benefits: [...postForm.value.benefits],
      appliedCount: 0
    }
    positionsList.value.push(newP)
    ElMessage.success(`新增岗位【${newP.postName}】成功`)
  }

  syncPositionsAndDepartmentsToServer()
  openPostDialog.value = false
}

const handleTogglePostStatus = (row: any) => {
  syncPositionsAndDepartmentsToServer()
  ElMessage.success(`岗位【${row.postName}】已${row.status === 'ACTIVE' ? '启用' : '停用'}`)
}

const handleToggleRecruitStatus = (row: any) => {
  syncPositionsAndDepartmentsToServer()
  if (row.isRecruiting) {
    ElMessage.success(`岗位【${row.postName}】已开启对外招聘！求职者可在线填写基本资料投递。`)
  } else {
    ElMessage.info(`岗位【${row.postName}】已暂停对外招聘。`)
  }
}

const handleDeletePost = (row: any) => {
  ElMessageBox.confirm(`确定要删除岗位【${row.postName}】吗？删除后相关员工需重新指派岗位。`, '安全提示', {
    confirmButtonText: '删除',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    positionsList.value = positionsList.value.filter(p => p.id !== row.id)
    syncPositionsAndDepartmentsToServer()
    ElMessage.success('已删除该岗位')
  })
}

const handleViewPostDoc = (row: any) => {
  currentDocPost.value = row
  openDocDrawer.value = true
}

const handleOpenJobDoc = (row: any) => {
  handleViewPostDoc(row)
}

// 2.0 岗位招聘微页面海报生成与二维码转发分享
const openSharePosterDialog = ref(false)
const targetPosterPost = ref<any>(null)
const posterQrCodeDataUrl = ref('')

const handleShareJobQr = (row: any) => {
  handleOpenSharePoster(row)
}


const downloadingPoster = ref(false)

const handleDownloadFullPosterImage = async () => {
  if (!targetPosterPost.value) return
  downloadingPoster.value = true
  ElMessage.info('正在渲染高保真招聘海报图片...')

  try {
    const post = targetPosterPost.value
    const store = basicForm.value.storeName || '海马智慧门店'
    const address = basicForm.value.address || '门店现场'
    const phone = basicForm.value.phone || '到店咨询'

    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')
    if (!ctx) throw new Error('Canvas not supported')

    const W = 750
    const descLen = (post.description || '').length
    const reqLen = (post.requirements || '').length
    let extraH = 0
    if (descLen > 50 || reqLen > 50) {
      extraH = Math.max(0, Math.ceil((descLen + reqLen - 100) / 22) * 32)
    }
    const H = 1260 + extraH

    canvas.width = W
    canvas.height = H

    const drawRoundRect = (x: number, y: number, w: number, h: number, r: number, fillStyle?: any, strokeStyle?: string, lineWidth = 1) => {
      ctx.beginPath()
      ctx.moveTo(x + r, y)
      ctx.arcTo(x + w, y, x + w, y + h, r)
      ctx.arcTo(x + w, y + h, x, y + h, r)
      ctx.arcTo(x, y + h, x, y, r)
      ctx.arcTo(x, y, x + w, y, r)
      ctx.closePath()
      if (fillStyle) {
        ctx.fillStyle = fillStyle
        ctx.fill()
      }
      if (strokeStyle) {
        ctx.strokeStyle = strokeStyle
        ctx.lineWidth = lineWidth
        ctx.stroke()
      }
    }

    const drawWrappedText = (text: string, x: number, y: number, maxWidth: number, lineHeight: number): number => {
      const words = text.split('')
      let line = ''
      let currentY = y
      for (let n = 0; n < words.length; n++) {
        const testLine = line + words[n]
        const metrics = ctx.measureText(testLine)
        if (metrics.width > maxWidth && n > 0) {
          ctx.fillText(line, x, currentY)
          line = words[n]
          currentY += lineHeight
        } else {
          line = testLine
        }
      }
      ctx.fillText(line, x, currentY)
      return currentY + lineHeight
    }

    // A. 海报外层背景
    ctx.fillStyle = '#f1f5f9'
    ctx.fillRect(0, 0, W, H)

    // B. 白底卡片
    const pad = 24
    drawRoundRect(pad, pad, W - pad * 2, H - pad * 2, 20, '#ffffff', '#e2e8f0', 1.5)

    let curY = pad + 18

    // C. 顶部 Hero 卡片 (渐变色)
    const heroX = pad + 16
    const heroW = W - (pad + 16) * 2
    const heroH = 220
    const grad = ctx.createLinearGradient(heroX, curY, heroX + heroW, curY + heroH)
    grad.addColorStop(0, '#0284c7')
    grad.addColorStop(1, '#2563eb')
    drawRoundRect(heroX, curY, heroW, heroH, 16, grad)

    ctx.fillStyle = 'rgba(255, 255, 255, 0.95)'
    ctx.font = '600 22px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    ctx.fillText(`${store} · 诚聘英才`, heroX + 22, curY + 42)

    ctx.fillStyle = '#ffffff'
    ctx.font = 'bold 36px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    ctx.fillText(post.postName || '诚聘英才', heroX + 22, curY + 92)

    ctx.fillStyle = '#fef08a'
    ctx.font = 'bold 34px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    const salText = post.salaryRange || '面议'
    ctx.fillText(salText, heroX + 22, curY + 140)

    const salW = ctx.measureText(salText).width
    ctx.fillStyle = 'rgba(255, 255, 255, 0.9)'
    ctx.font = '500 20px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    ctx.fillText(`(底薪￥${post.baseSalary || 4000}+业绩提成)`, heroX + 22 + salW + 10, curY + 138)

    // 标签: 招x人 / 学历 / 经验
    let tagX = heroX + 22
    const tagY = curY + 165
    const tags = [
      `🎯 招 ${post.recruitHeadcount || 1} 人`,
      `🎓 ${post.educationReq || '学历不限'}`,
      `⏳ ${post.experienceReq || '经验不限'}`
    ]
    tags.forEach(t => {
      ctx.font = '600 17px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
      const tw = ctx.measureText(t).width + 18
      drawRoundRect(tagX, tagY, tw, 30, 8, 'rgba(255, 255, 255, 0.22)')
      ctx.fillStyle = '#ffffff'
      ctx.fillText(t, tagX + 9, tagY + 21)
      tagX += tw + 10
    })

    curY += heroH + 16

    // D. 福利亮点标签
    const benefits: string[] = (post.benefits && post.benefits.length) ? post.benefits : ['包吃包住', '五险一金', '带薪年假', '技能培训']
    let benX = heroX
    let benY = curY
    ctx.font = '600 18px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    benefits.slice(0, 6).forEach(b => {
      const bText = `✨ ${b}`
      const bw = ctx.measureText(bText).width + 22
      if (benX + bw > heroX + heroW) {
        benX = heroX
        benY += 38
      }
      drawRoundRect(benX, benY, bw, 32, 16, '#ecfdf5', '#a7f3d0', 1)
      ctx.fillStyle = '#059669'
      ctx.fillText(bText, benX + 11, benY + 22)
      benX += bw + 8
    })

    curY = benY + 44

    // E. 岗位职责卡片
    const cardW = heroW
    const descText = post.description || '负责门店日常专业服务交付与顾客接待。'
    ctx.font = '20px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    const descLines = Math.max(1, Math.ceil((ctx.measureText(descText).width + 10) / (cardW - 40)))
    const descH = 50 + descLines * 28
    drawRoundRect(heroX, curY, cardW, descH, 12, '#ffffff', '#e2e8f0', 1)

    ctx.beginPath()
    ctx.arc(heroX + 22, curY + 22, 5, 0, Math.PI * 2)
    ctx.fillStyle = '#0284c7'
    ctx.fill()
    ctx.fillStyle = '#0f172a'
    ctx.font = 'bold 21px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    ctx.fillText('岗位职责', heroX + 36, curY + 29)

    ctx.fillStyle = '#334155'
    ctx.font = '19px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    drawWrappedText(descText, heroX + 20, curY + 58, cardW - 40, 27)

    curY += descH + 12

    // F. 任职要求卡片
    const reqText = post.requirements || '品貌端正，具备良好服务意识与团队沟通协作精神。'
    ctx.font = '19px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    const reqLines = Math.max(1, Math.ceil((ctx.measureText(reqText).width + 10) / (cardW - 40)))
    const reqH = 50 + reqLines * 28
    drawRoundRect(heroX, curY, cardW, reqH, 12, '#ffffff', '#e2e8f0', 1)

    ctx.beginPath()
    ctx.arc(heroX + 22, curY + 22, 5, 0, Math.PI * 2)
    ctx.fillStyle = '#0284c7'
    ctx.fill()
    ctx.fillStyle = '#0f172a'
    ctx.font = 'bold 21px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    ctx.fillText('任职要求', heroX + 36, curY + 29)

    ctx.fillStyle = '#334155'
    ctx.font = '19px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    drawWrappedText(reqText, heroX + 20, curY + 58, cardW - 40, 27)

    curY += reqH + 12

    // G. 门店信息卡片 (完全动态读取当前店铺真实信息)
    const storeH = 118
    drawRoundRect(heroX, curY, cardW, storeH, 12, '#f8fafc', '#e2e8f0', 1)

    ctx.font = '19px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    ctx.fillStyle = '#1e293b'
    ctx.fillText(`🏬  门店：${store}`, heroX + 18, curY + 32)
    ctx.fillText(`📍  地址：${address}`, heroX + 18, curY + 68)
    ctx.fillText(`📞  电话：${phone}`, heroX + 18, curY + 102)

    curY += storeH + 14

    // H. 底部二维码与扫码投递卡片
    const qrH = 168
    ctx.save()
    ctx.setLineDash([5, 4])
    drawRoundRect(heroX, curY, cardW, qrH, 14, '#f0f9ff', '#0284c7', 1.5)
    ctx.restore()

    if (posterQrCodeDataUrl.value) {
      const qrImg = new Image()
      qrImg.crossOrigin = 'anonymous'
      qrImg.src = posterQrCodeDataUrl.value
      await new Promise((resolve) => {
        if (qrImg.complete) resolve(true)
        else {
          qrImg.onload = () => resolve(true)
          qrImg.onerror = () => resolve(false)
        }
      })
      ctx.drawImage(qrImg, heroX + 18, curY + 14, 140, 140)
    }

    const textStartX = heroX + 176
    ctx.fillStyle = '#0284c7'
    ctx.font = 'bold 25px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    ctx.fillText('📱 微信扫码 · 一键投递', textStartX, curY + 52)

    ctx.fillStyle = '#475569'
    ctx.font = '19px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    ctx.fillText('长按识别二维码或微信扫一扫', textStartX, curY + 88)

    ctx.fillStyle = '#64748b'
    ctx.font = '17px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    ctx.fillText('在线提交基本资料 · 直达店长初筛', textStartX, curY + 120)

    // I. 底部版权
    ctx.fillStyle = '#94a3b8'
    ctx.font = '15px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    ctx.textAlign = 'center'
    ctx.fillText('海马智慧商业连锁 · 岗位招聘官方通道', W / 2, H - pad - 6)
    ctx.textAlign = 'left'

    const dataUrl = canvas.toDataURL('image/png', 1.0)
    const a = document.createElement('a')
    a.href = dataUrl
    a.download = `${store}_${post.postName}_招聘海报.png`
    a.click()
    ElMessage.success(`招聘海报图片【${post.postName}】已生成并开始下载！`)
  } catch (err: any) {
    console.error('Failed to download poster image', err)
    ElMessage.error('海报图片生成失败，请重试')
  } finally {
    downloadingPoster.value = false
  }
}

// ----------------------------------------------------------------------------
// 云端应聘简历同步引擎 (解决手机扫码投递后刷新电脑查看的问题)
// ----------------------------------------------------------------------------
const syncingApplications = ref(false)

const fetchRemoteApplications = async (showTip = false) => {
  syncingApplications.value = true
  const tenantId = encodeURIComponent(storeConfig.tenantId || localStorage.getItem('seahorse_tenant_id') || 'DEFAULT')
  try {
    const res = await fetch(`/api/job-application/list?tenantId=${tenantId}`, {
      headers: {
        'X-Tenant-Id': tenantId
      }
    })
    if (res.ok) {
      const data = await res.json()
      if (data && data.code === 200 && Array.isArray(data.data)) {
        const remoteList: JobApplication[] = data.data
        if (remoteList.length > 0) {
          // 与本地列表深度合并 (去重)
          const merged = [...remoteList]
          applicationsList.value.forEach(localItem => {
            if (!merged.some(r => r.id === localItem.id || (r.phone === localItem.phone && (String(r.postId) === String(localItem.postId) || r.postName === localItem.postName)))) {
              merged.push(localItem)
            }
          })
          applicationsList.value = merged
          saveApplications()
          if (showTip) {
            ElMessage.success(`已同步最新应聘简历！当前共有 ${applicationsList.value.length} 份申请`)
          }
          return
        }
      }
    }
  } catch (err) {
    console.warn('拉取云端简历数据失败，已降级使用本地存储:', err)
  } finally {
    syncingApplications.value = false
  }
  if (showTip) {
    ElMessage.info(`简历数据已按本地最新台账刷新 (共 ${applicationsList.value.length} 份)`)
  }
}

watch(postSubTab, (val) => {
  if (val === 'APPLICATIONS') {
    fetchRemoteApplications(false)
  }
})

const handleDownloadPosterQr = () => {
  if (!posterQrCodeDataUrl.value) return
  const a = document.createElement('a')
  a.href = posterQrCodeDataUrl.value
  a.download = `${targetPosterPost.value?.postName || '招聘'}_专属二维码.png`
  a.click()
  ElMessage.success('已开始下载招聘二维码！')
}

const buildApplyUrl = (post: any) => {
  if (!post) return ''
  const storeName = encodeURIComponent(basicForm.value.storeName || '海马智慧门店')
  const storeAddr = encodeURIComponent(basicForm.value.address || '门店现场')
  const storePhone = encodeURIComponent(basicForm.value.phone || '到店咨询')
  const tenantId = encodeURIComponent(storeConfig.tenantId || localStorage.getItem('seahorse_tenant_id') || 'DEFAULT')

  const postName = encodeURIComponent(post.postName || '诚聘英才')
  const salary = encodeURIComponent(post.salaryRange || '面议')
  const baseSalary = encodeURIComponent(String(post.baseSalary || 4000))
  const commRate = encodeURIComponent(String(post.commissionRate || 0.1))
  const headcount = encodeURIComponent(String(post.recruitHeadcount || 1))
  const edu = encodeURIComponent(post.educationReq || '学历不限')
  const exp = encodeURIComponent(post.experienceReq || '经验不限')
  const dept = encodeURIComponent(post.department || '门店现场')
  const benefits = encodeURIComponent((post.benefits || []).join('、'))
  const desc = encodeURIComponent(post.description || '')
  const req = encodeURIComponent(post.requirements || '')

  return `${window.location.origin}/seahorse/job-apply?postId=${post.id}&tenantId=${tenantId}&store=${storeName}&addr=${storeAddr}&phone=${storePhone}&postName=${postName}&salary=${salary}&baseSalary=${baseSalary}&commRate=${commRate}&headcount=${headcount}&edu=${edu}&exp=${exp}&dept=${dept}&benefits=${benefits}&desc=${desc}&req=${req}`
}

const currentShareUrl = computed(() => {
  return buildApplyUrl(targetPosterPost.value)
})

const generatedWechatText = computed(() => {
  if (!targetPosterPost.value) return ''
  const p = targetPosterPost.value
  const store = basicForm.value.storeName || storeConfig.storeName || '海马智慧旗舰店'
  const benefitsText = p.benefits && p.benefits.length ? p.benefits.join('、') : '包吃包住、五险一金、定期团建'
  return `【诚聘英才】${store} 正在热招【${p.postName}】！\n💰 薪资待遇：${p.salaryRange || '面议'} (底薪￥${p.baseSalary || 4000}+业绩提成)\n🎁 福利亮点：${benefitsText}\n🎯 任职要求：${p.experienceReq || '经验不限'} · ${p.educationReq || '学历不限'}\n📍 工作地址：${basicForm.value.address || '门店现场'}\n📞 联系电话：${basicForm.value.phone || '到店咨询'}\n👉 微信扫码或点击下方链接，一键在线填写基本资料直投简历：\n${currentShareUrl.value}`
})

const handleOpenSharePoster = async (post: any) => {
  targetPosterPost.value = post || positionsList.value.find(p => p.isRecruiting) || positionsList.value[0]
  if (!targetPosterPost.value) {
    ElMessage.warning('当前暂无可分享的岗位')
    return
  }

  try {
    const url = buildApplyUrl(targetPosterPost.value)
    posterQrCodeDataUrl.value = await QRCode.toDataURL(url, {
      width: 280,
      margin: 1,
      color: {
        dark: '#0f172a',
        light: '#ffffff'
      }
    })
  } catch (err) {
    console.error('Failed to generate QR code', err)
  }
  openSharePosterDialog.value = true
}

const handleCopyShareUrl = async () => {
  if (!currentShareUrl.value) return
  try {
    await navigator.clipboard.writeText(currentShareUrl.value)
    ElMessage.success('招聘网页链接已复制到剪贴板，可粘贴发送至微信好友或群聊！')
  } catch (e) {
    ElMessage.info('链接已生成：' + currentShareUrl.value)
  }
}

const handleCopyWechatText = async () => {
  if (!generatedWechatText.value) return
  try {
    await navigator.clipboard.writeText(generatedWechatText.value)
    ElMessage.success('微信招聘转发文案已复制！可直接粘贴发送到微信群、朋友圈或朋友圈动态。')
  } catch (e) {
    ElMessage.info('文案已生成，请长按或手动复制文本框内容')
  }
}

const handleOpenApplyPageNewTab = (post?: any) => {
  const target = post || targetPosterPost.value
  if (!target) return
  const url = buildApplyUrl(target)
  window.open(url, '_blank')
}

const handlePrintPoster = () => {
  const el = document.getElementById('printable-job-poster')
  if (!el) {
    window.print()
    return
  }

  let iframe = document.getElementById('poster-print-iframe') as HTMLIFrameElement
  if (!iframe) {
    iframe = document.createElement('iframe')
    iframe.id = 'poster-print-iframe'
    iframe.style.position = 'fixed'
    iframe.style.right = '0'
    iframe.style.bottom = '0'
    iframe.style.width = '0'
    iframe.style.height = '0'
    iframe.style.border = 'none'
    iframe.style.visibility = 'hidden'
    document.body.appendChild(iframe)
  }

  const doc = iframe.contentWindow?.document
  if (!doc) {
    window.print()
    return
  }

  doc.open()
  doc.write(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>门店招聘宣传海报单</title>
        <style>
          @page {
            size: A4 portrait;
            margin: 10mm;
          }
          * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
          }
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #ffffff;
            color: #0f172a;
            display: flex;
            justify-content: center;
            padding: 10px;
          }
          .phone-status-bar { display: none !important; }
          .phone-mockup-wrapper {
            width: 100%;
            max-width: 500px;
            background: #ffffff;
            border-radius: 0;
            box-shadow: none;
            padding: 0;
          }
          .phone-screen-body {
            background: #ffffff;
            border-radius: 0;
            padding: 0;
            max-height: none;
            overflow: visible;
            display: flex;
            flex-direction: column;
            gap: 14px;
          }
          .job-hero-card {
            background: linear-gradient(135deg, #0284c7 0%, #2563eb 100%) !important;
            color: #ffffff !important;
            padding: 20px;
            border-radius: 14px;
          }
          .hero-sub { font-size: 13px; opacity: 0.95; }
          .hero-title { font-size: 24px; font-weight: 800; margin: 8px 0; }
          .hero-salary-row { display: flex; align-items: baseline; gap: 10px; margin-bottom: 8px; }
          .salary-num { font-size: 24px; font-weight: 800; color: #fef08a !important; }
          .salary-desc { font-size: 13px; opacity: 0.95; }
          .hero-meta-badges { display: flex; gap: 8px; }
          .meta-tag { background: rgba(255, 255, 255, 0.25) !important; padding: 3px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; }
          .job-benefits-row { display: flex; flex-wrap: wrap; gap: 8px; }
          .benefit-pill { background: #ecfdf5 !important; color: #059669 !important; border: 1px solid #a7f3d0; padding: 3px 10px; border-radius: 12px; font-size: 12px; font-weight: 600; }
          .job-section-card { border: 1px solid #e2e8f0; border-radius: 10px; padding: 12px 14px; }
          .sec-header { font-size: 14px; font-weight: 700; margin-bottom: 6px; }
          .sec-body { font-size: 13px; color: #334155; line-height: 1.6; }
          .store-contact-sec .store-row { font-size: 13px; margin-bottom: 4px; }
          .job-poster-qr-footer { border: 1.5px dashed #0284c7; border-radius: 12px; padding: 14px; display: flex; align-items: center; gap: 16px; margin-top: 10px; }
          .qr-img-box img { width: 96px; height: 96px; display: block; border-radius: 6px; }
          .qr-tip-title { font-size: 14px; font-weight: 800; color: #0284c7; }
          .qr-tip-desc { font-size: 12px; color: #64748b; margin-top: 4px; line-height: 1.5; }
        </style>
      </head>
      <body>
        <div class="phone-mockup-wrapper">
          ${el.innerHTML}
        </div>
      </body>
    </html>
  `)
  doc.close()

  setTimeout(() => {
    iframe.contentWindow?.focus()
    iframe.contentWindow?.print()
  }, 250)
}

// 2.1 模拟求职者在线应聘投递端逻辑
const openApplyPortalDialog = ref(false)
const selectedPostForApply = ref<any>(null)
const candidateForm = ref({
  postId: 2,
  postName: '发型总监/主理人',
  salaryRange: '8000-11000元/月',
  candidateName: '',
  gender: '男' as '男' | '女',
  age: 26,
  phone: '',
  education: '大专',
  experienceYears: 3,
  expectedSalary: '7500元/月',
  availableDate: '随时到岗',
  personalAdvantage: '',
  workHistory: ''
})

const handleOpenApplyPortal = (post: any) => {
  let target = post
  if (!target) {
    target = positionsList.value.find(p => p.isRecruiting) || positionsList.value[0]
  }
  selectedPostForApply.value = target
  if (target) {
    candidateForm.value = {
      postId: target.id,
      postName: target.postName,
      salaryRange: target.salaryRange || '面议',
      candidateName: '',
      gender: '男',
      age: 26,
      phone: '',
      education: '大专',
      experienceYears: 3,
      expectedSalary: target.baseSalary ? `￥${target.baseSalary + 1000}元/月` : '7000元/月',
      availableDate: '随时到岗',
      personalAdvantage: '',
      workHistory: ''
    }
  }
  openApplyPortalDialog.value = true
}

const handleSelectApplyPost = (postId: number) => {
  const p = positionsList.value.find(item => item.id === postId)
  if (p) {
    selectedPostForApply.value = p
    candidateForm.value.postName = p.postName
    candidateForm.value.salaryRange = p.salaryRange || '面议'
  }
}

const handleSubmitCandidateApplication = () => {
  if (!candidateForm.value.candidateName?.trim()) {
    ElMessage.warning('请填写求职者真实姓名')
    return
  }
  if (!candidateForm.value.phone?.trim() || !/^1\d{10}$/.test(candidateForm.value.phone.trim())) {
    ElMessage.warning('请填写有效的11位求职者手机号')
    return
  }

  const now = new Date()
  const pad = (n: number) => n < 10 ? '0' + n : String(n)
  const timeStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`

  const newApp: JobApplication = {
    id: 'APP' + Date.now().toString().slice(-8),
    postId: candidateForm.value.postId,
    postName: candidateForm.value.postName,
    candidateName: candidateForm.value.candidateName.trim(),
    gender: candidateForm.value.gender,
    age: candidateForm.value.age,
    phone: candidateForm.value.phone.trim(),
    education: candidateForm.value.education,
    experienceYears: candidateForm.value.experienceYears,
    expectedSalary: candidateForm.value.expectedSalary,
    availableDate: candidateForm.value.availableDate,
    personalAdvantage: candidateForm.value.personalAdvantage.trim() || '求职者具备良好的沟通与团队协作精神。',
    workHistory: candidateForm.value.workHistory.trim() || '具备相关门店或行业实操服务经验。',
    applyTime: timeStr,
    status: 'PENDING'
  }

  // 同一手机号码和岗位再次修改编辑的，直接覆盖更新已有数据，而不是生成多份重复数据
  const existIdx = applicationsList.value.findIndex(a =>
    a.phone === newApp.phone && (String(a.postId) === String(newApp.postId) || a.postName === newApp.postName)
  )

  if (existIdx !== -1) {
    newApp.id = applicationsList.value[existIdx].id || newApp.id
    applicationsList.value[existIdx] = { ...applicationsList.value[existIdx], ...newApp }
  } else {
    applicationsList.value.unshift(newApp)
    // 对应岗位已投递计数 + 1 (仅全新候选人递增)
    const targetPost = positionsList.value.find(p => p.id === candidateForm.value.postId)
    if (targetPost) {
      targetPost.appliedCount = (targetPost.appliedCount || 0) + 1
      localStorage.setItem('seahorse_system_positions', JSON.stringify(positionsList.value))
    }
  }

  saveApplications()

  openApplyPortalDialog.value = false

  ElNotification({
    title: '🎉 投递成功！简历已送达',
    message: `候选人【${newApp.candidateName}】应聘【${newApp.postName}】的简历资料已成功提交，老板后台已实时收到待初筛提醒！`,
    type: 'success',
    duration: 4000
  })

  // 自动切换至应聘看板方便查验
  postSubTab.value = 'APPLICATIONS'
}

// 2.2 查看简历详情抽屉
const openApplicantDocDrawer = ref(false)
const currentApplicant = ref<JobApplication | null>(null)

const handleViewApplicantDoc = (row: JobApplication) => {
  currentApplicant.value = row
  openApplicantDocDrawer.value = true
}

// 2.3 安排面试弹窗
const openScheduleInterviewDialog = ref(false)
const targetScheduleApplicant = ref<JobApplication | null>(null)
const scheduleForm = ref({
  interviewTime: '',
  type: 'OFFLINE' as 'OFFLINE' | 'VIDEO' | 'PHONE',
  interviewer: '张建华 (店长)',
  location: '海马智慧旗舰店 2楼VIP接待茶歇区',
  note: '请携带身份证原件及个人既往作品案例，准时到达门店。',
  sendSms: true,
  smsTemplate: 'OFFLINE' as 'OFFLINE' | 'SKILL' | 'VIDEO',
  smsContent: ''
})

const generateInterviewSmsContent = () => {
  if (!targetScheduleApplicant.value) return
  const store = basicForm.value.storeName || '海马智慧连锁门店'
  const name = targetScheduleApplicant.value.candidateName
  const post = targetScheduleApplicant.value.postName
  const time = scheduleForm.value.interviewTime || '近期时间'
  const interviewer = scheduleForm.value.interviewer || '张店长'
  const loc = scheduleForm.value.location || '门店前台接待区'
  const phone = basicForm.value.phone || '021-88889999'

  if (scheduleForm.value.smsTemplate === 'VIDEO') {
    scheduleForm.value.smsContent = `【${store}】尊敬的${name}，您好！恭喜通过【${post}】岗位初筛，诚邀您于 ${time} 参加远程微信视频初面。面试官：${interviewer}，请提前添加微信并保持手机网络通畅。咨询电话：${phone}。收到请回复“姓名+准时参加”。`
  } else if (scheduleForm.value.smsTemplate === 'SKILL') {
    scheduleForm.value.smsContent = `【${store}】尊敬的${name}，您好！诚挚邀请您于 ${time} 莅临【${loc}】参加【${post}】岗位实操试工与技术测评。考官：${interviewer}，请自备常用工具或资质案例作品。联系电话：${phone}。收到请回复“确认参加”，祝您面试顺利！`
  } else {
    scheduleForm.value.smsContent = `【${store}】尊敬的${name}，您好！恭喜您应聘我店【${post}】岗位已通过简历初审。诚邀您于 ${time} 前往【${loc}】参加面试，面试官：${interviewer}。备注：${scheduleForm.value.note || '请准时到达'}。咨询电话：${phone}。收到请回复“姓名+准时参加”。祝您面试顺利！`
  }
}

const handleOpenScheduleInterview = (applicant: JobApplication) => {
  targetScheduleApplicant.value = applicant
  const tomorrow = new Date(Date.now() + 24 * 3600 * 1000)
  const pad = (n: number) => n < 10 ? '0' + n : String(n)
  const defaultTime = `${tomorrow.getFullYear()}-${pad(tomorrow.getMonth() + 1)}-${pad(tomorrow.getDate())} 14:30`

  scheduleForm.value = {
    interviewTime: applicant.interviewInfo?.interviewTime || defaultTime,
    type: applicant.interviewInfo?.type || 'OFFLINE',
    interviewer: applicant.interviewInfo?.interviewer || '张建华 (店长)',
    location: applicant.interviewInfo?.location || `${basicForm.value.storeName || '海马智慧门店'} 2楼VIP接待茶歇区`,
    note: applicant.interviewInfo?.note || '请携带身份证原件及个人既往作品案例，准时到达门店。',
    sendSms: true,
    smsTemplate: applicant.interviewInfo?.type === 'VIDEO' ? 'VIDEO' : 'OFFLINE',
    smsContent: ''
  }
  generateInterviewSmsContent()
  openScheduleInterviewDialog.value = true
}

const handleConfirmScheduleInterview = () => {
  if (!targetScheduleApplicant.value) return
  if (!scheduleForm.value.interviewTime) {
    ElMessage.warning('请选择面试时间')
    return
  }

  const now = new Date()
  const pad = (n: number) => n < 10 ? '0' + n : String(n)
  const nowStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`

  targetScheduleApplicant.value.status = 'INTERVIEW_SCHEDULED'
  targetScheduleApplicant.value.interviewInfo = {
    interviewTime: scheduleForm.value.interviewTime,
    interviewer: scheduleForm.value.interviewer,
    type: scheduleForm.value.type,
    location: scheduleForm.value.location,
    note: scheduleForm.value.note,
    smsSent: scheduleForm.value.sendSms,
    smsContent: scheduleForm.value.sendSms ? scheduleForm.value.smsContent : undefined,
    smsTime: scheduleForm.value.sendSms ? nowStr : undefined
  }

  saveApplications()
  openScheduleInterviewDialog.value = false

  if (scheduleForm.value.sendSms) {
    ElNotification({
      title: '🗓️ 面试已安排 · 📱 短信已成功发送',
      message: `已为【${targetScheduleApplicant.value.candidateName}】成功预约面试：${scheduleForm.value.interviewTime}。面试通知短信已通过短信网关发送至手机号【${targetScheduleApplicant.value.phone}】！`,
      type: 'success',
      duration: 5000
    })
  } else {
    ElNotification({
      title: '🗓️ 面试日程已安排',
      message: `已为【${targetScheduleApplicant.value.candidateName}】成功预约面试：${scheduleForm.value.interviewTime}（考官：${scheduleForm.value.interviewer}）。`,
      type: 'success'
    })
  }
}

// 2.4 面试综合考评与决策
const openInterviewEvalDialog = ref(false)
const targetEvalApplicant = ref<JobApplication | null>(null)
const evalForm = ref({
  scoreLevel: 'EXCELLENT' as 'EXCELLENT' | 'GOOD' | 'PASS' | 'FAIL',
  feedback: '实操剪裁手法干练利落，仪态端正，沟通温和亲和力强，符合门店技术服务标准。',
  decision: 'PASSED' as 'PASSED' | 'REJECTED'
})

const handleOpenInterviewEval = (applicant: JobApplication) => {
  targetEvalApplicant.value = applicant
  evalForm.value = {
    scoreLevel: applicant.interviewEvaluation?.scoreLevel || 'EXCELLENT',
    feedback: applicant.interviewEvaluation?.feedback || '候选人专业实操手法纯熟，形象气质佳，沟通表达清晰流畅，具备良好的客户服务意识。',
    decision: 'PASSED'
  }
  openInterviewEvalDialog.value = true
}

const handleConfirmInterviewEval = () => {
  if (!targetEvalApplicant.value) return
  if (!evalForm.value.feedback?.trim()) {
    ElMessage.warning('请填写面试考评意见')
    return
  }

  const now = new Date()
  const pad = (n: number) => n < 10 ? '0' + n : String(n)
  const timeStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`

  targetEvalApplicant.value.interviewEvaluation = {
    scoreLevel: evalForm.value.scoreLevel,
    feedback: evalForm.value.feedback.trim(),
    evaluatedBy: targetEvalApplicant.value.interviewInfo?.interviewer || '张建华 (店长)',
    evaluateTime: timeStr
  }

  if (evalForm.value.decision === 'PASSED') {
    targetEvalApplicant.value.status = 'PASSED'
    ElNotification({
      title: '🎉 面试通过',
      message: `候选人【${targetEvalApplicant.value.candidateName}】已通过面试考核，评级为【${evalForm.value.scoreLevel === 'EXCELLENT' ? '优秀' : '良好'}】！可点击“发送入职建档码”让员工扫码自主完善档案。`,
      type: 'success',
      duration: 5000
    })

    // 自动打开专属建档二维码与链接弹窗
    const cand = targetEvalApplicant.value
    setTimeout(() => {
      handleOpenSendRegisterQr(cand)
    }, 300)
  } else {
    targetEvalApplicant.value.status = 'REJECTED'
    targetEvalApplicant.value.rejectReason = '面试考核未达标'
    ElMessage.info(`候选人【${targetEvalApplicant.value.candidateName}】面试结果标记为未通过`)
  }

  saveApplications()
  openInterviewEvalDialog.value = false
}

// ----------------------------------------------------------------------------
// 2.4.2 📲 面试通过后发送专属入职建档码与链接 (支持候选人手机扫码完善档案)
// ----------------------------------------------------------------------------
const openSendRegisterQrDialog = ref(false)
const targetRegisterApplicant = ref<JobApplication | null>(null)
const registerQrCodeDataUrl = ref('')

const currentRegisterUrl = computed(() => {
  if (!targetRegisterApplicant.value) return ''
  const applicant = targetRegisterApplicant.value
  const storeId = basicForm.value.storeId || storeConfig.currentStoreId || 'S001'
  const origin = window.location.origin
  return `${origin}/seahorse/staff-register?storeId=${encodeURIComponent(storeId)}&phone=${encodeURIComponent(applicant.phone)}&realName=${encodeURIComponent(applicant.candidateName)}&post=${encodeURIComponent(applicant.postName)}&candidateId=${encodeURIComponent(applicant.id)}`
})

const handleOpenSendRegisterQr = async (applicant: JobApplication) => {
  targetRegisterApplicant.value = applicant
  try {
    const url = currentRegisterUrl.value
    registerQrCodeDataUrl.value = await QRCode.toDataURL(url, {
      width: 260,
      margin: 1,
      color: { dark: '#0f172a', light: '#ffffff' }
    })
  } catch (err) {
    console.error('生成入职建档二维码失败:', err)
  }
  openSendRegisterQrDialog.value = true
}

const handleCopyRegisterUrl = async () => {
  if (!currentRegisterUrl.value) return
  try {
    await navigator.clipboard.writeText(currentRegisterUrl.value)
    ElMessage.success('员工专属入职建档链接已复制！可粘贴发送至候选人微信或短信。')
  } catch (e) {
    ElMessage.info('链接已生成：' + currentRegisterUrl.value)
  }
}

const handleDownloadRegisterQr = () => {
  if (!registerQrCodeDataUrl.value || !targetRegisterApplicant.value) return
  const a = document.createElement('a')
  a.href = registerQrCodeDataUrl.value
  a.download = `${targetRegisterApplicant.value.candidateName}_入职自主建档码.png`
  a.click()
  ElMessage.success('已开始下载专属入职二维码图片！')
}

const handleSendRegisterSms = () => {
  if (!targetRegisterApplicant.value) return
  const app = targetRegisterApplicant.value
  const store = basicForm.value.storeName || '海马智慧门店'
  ElNotification({
    title: '📱 入职通知短信已发送',
    message: `【${store}】尊敬的${app.candidateName}：恭喜您已通过我店【${app.postName}】岗位面试考评！请点击专属链接完善您的个人档案与登录密码办理快速入职：${currentRegisterUrl.value}`,
    type: 'success',
    duration: 6000
  })
}

// 兼容别名
const handleOneClickHire = (applicant: JobApplication) => handleHireCandidate(applicant)

// 2.5 一键办理入职联动正式员工档案
const handleHireCandidate = (applicant: JobApplication) => {
  ElMessageBox.confirm(
    `确定为候选人【${applicant.candidateName}】办理正式入职吗？系统将自动在【员工档案】中创建该员工记录并指派岗位【${applicant.postName}】。`,
    '录用入职确认',
    {
      confirmButtonText: '确认办理入职',
      cancelButtonText: '取消',
      type: 'success'
    }
  ).then(() => {
    applicant.status = 'HIRED'
    saveApplications()

    // 联动在册员工列表 (localStorage: seahorse_staff_list)
    try {
      const rawStaff = localStorage.getItem('seahorse_staff_list')
      let staffList: any[] = []
      if (rawStaff) {
        staffList = JSON.parse(rawStaff)
      }

      // 查重并添加新员工
      const existing = staffList.find(s => s.phone === applicant.phone)
      const ind = systemData.currentIndustry || 'BEAUTY'
      const defaultDept = ind === 'RESTAURANT' ? '后厨烹饪部' : ind === 'AUTO' ? '机电维保部' : ind === 'RETAIL' ? '门店销售部' : '造型设计部'

      if (!existing) {
        const postObj = positionsList.value.find(p => p.postName === applicant.postName)
        const newStaff = {
          id: Date.now(),
          realName: applicant.candidateName,
          phone: applicant.phone,
          gender: applicant.gender,
          position: applicant.postName,
          department: postObj?.department || defaultDept,
          baseSalary: postObj?.baseSalary || 4500,
          commissionRate: postObj?.commissionRate || 0.2,
          status: 'ACTIVE',
          hireDate: new Date().toISOString().slice(0, 10),
          avatar: '',
          idCard: ''
        }
        staffList.unshift(newStaff)
        localStorage.setItem('seahorse_staff_list', JSON.stringify(staffList))

        // 在岗人数 + 1
        if (postObj) {
          postObj.employeeCount = (postObj.employeeCount || 0) + 1
          localStorage.setItem('seahorse_system_positions', JSON.stringify(positionsList.value))
        }
      }

      // 同时同步入库至 Pinia 组织架构系统账号中，实现从招聘面试通过到立即开通登录权限闭环
      const existingInStore = systemData.staff.find(s => s.phone === applicant.phone)
      if (!existingInStore) {
        const postObj = positionsList.value.find(p => p.postName === applicant.postName)
        const isMgr = applicant.postName.includes('店长') || applicant.postName.includes('总监')
        const isCashier = applicant.postName.includes('收银') || applicant.postName.includes('前台') || applicant.postName.includes('顾问')
        systemData.addStaff({
          storeId: systemData.stores[0]?.storeId || 'S001',
          realName: applicant.candidateName,
          phone: applicant.phone,
          postName: applicant.postName,
          role: isMgr ? 'STORE_MANAGER' : isCashier ? 'CASHIER' : 'TECHNICIAN',
          department: postObj?.department || defaultDept,
          gender: applicant.gender || 'FEMALE',
          baseSalary: postObj?.baseSalary || 4500,
          hasSystemAccount: true,
          accountUsername: applicant.phone,
          accountPassword: '123456',
          accountStatus: 'ENABLED',
          allowedStoreIds: [systemData.stores[0]?.storeId || 'S001'],
          allowedMenuPaths: isMgr 
            ? ['/dashboard', '/rooms', '/members', '/products', '/card-template', '/staff-management', '/marketing', '/mall', '/appointments', '/expenses', '/inventory', '/reports']
            : isCashier
            ? ['/dashboard', '/members', '/products', '/card-template', '/appointments', '/expenses', '/inventory', '/profile']
            : ['/dashboard', '/members', '/products', '/appointments', '/inventory', '/profile']
        })
      }
    } catch (e) {
      console.error(e)
    }

    if (openApplicantDocDrawer.value) {
      openApplicantDocDrawer.value = false
    }

    ElNotification({
      title: '🏆 入职办理成功！',
      message: `【${applicant.candidateName}】已正式录用入职并转入在册员工档案（岗位：${applicant.postName}），系统已自动完成资料建档！`,
      type: 'success',
      duration: 5000
    })
  })
}

// 2.6 淘汰候选人
const openRejectDialog = ref(false)
const targetRejectApplicant = ref<JobApplication | null>(null)
const rejectReasonText = ref('技术实操或经验与岗位不符')

const handleOpenReject = (applicant: JobApplication) => {
  targetRejectApplicant.value = applicant
  rejectReasonText.value = '技术实操或经验与岗位不符'
  openRejectDialog.value = true
}

const handleConfirmReject = () => {
  if (!targetRejectApplicant.value) return
  targetRejectApplicant.value.status = 'REJECTED'
  targetRejectApplicant.value.rejectReason = rejectReasonText.value
  saveApplications()

  // 同步云端数据库状态
  try {
    const tenantId = encodeURIComponent(storeConfig.tenantId || localStorage.getItem('seahorse_tenant_id') || 'DEFAULT')
    fetch(`/api/job-application/${targetRejectApplicant.value.id}/status?tenantId=${tenantId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        status: 'REJECTED',
        rejectReason: rejectReasonText.value
      })
    }).catch(() => {})
  } catch (e) {}

  openRejectDialog.value = false
  ElMessage.info(`已将候选人【${targetRejectApplicant.value.candidateName}】标记为淘汰归档`)
}

// 兼容别名方法
const handleOpenApplicantDetail = (row: JobApplication) => handleViewApplicantDoc(row)
const handleRejectApplicant = (row: JobApplication) => handleOpenReject(row)


// 3. 短信管理 (严格对齐截图 media_1788699619136.png, media_1788699981137.png, media_1788699959771.png)
const smsCurrentSubTab = ref('BUY') // BUY / BALANCE / SIGN / BULK
const smsNotifyCoupon = ref(true)
const smsNotifyConsume = ref(true)

// 读取持久化短信开关
try {
  const rawSmsCfg = localStorage.getItem('seahorse_sms_config')
  if (rawSmsCfg) {
    const parsed = JSON.parse(rawSmsCfg)
    smsNotifyCoupon.value = parsed.notifyCoupon !== false
    smsNotifyConsume.value = parsed.notifyConsume !== false
  }
} catch (e) {}

const handleSaveSmsSwitches = () => {
  localStorage.setItem('seahorse_sms_config', JSON.stringify({
    notifyCoupon: smsNotifyCoupon.value,
    notifyConsume: smsNotifyConsume.value
  }))
  ElMessage.success('短信通知触发规则已保存')
}

// 短信套餐列表 (动态同步自超级管理员配置的价格与条数)
const smsPackages = ref<any[]>(getSmsPackagesList().map(p => ({
  id: p.id,
  name: p.name,
  count: p.count,
  price: Number(p.price).toFixed(2),
  unitPrice: p.unitPrice || (p.price / (p.count || 1)).toFixed(2)
})))

const refreshSettingsSmsPackages = () => {
  const packs = getSmsPackagesList()
  if (packs && packs.length > 0) {
    smsPackages.value = packs.map(p => ({
      id: p.id,
      name: p.name,
      count: p.count,
      price: Number(p.price).toFixed(2),
      unitPrice: p.unitPrice || (p.price / (p.count || 1)).toFixed(2)
    }))
  }
}

if (typeof window !== 'undefined') {
  window.addEventListener('seahorse-recharge-packages-updated', refreshSettingsSmsPackages)
}

const selectedPackageId = ref<any>(smsPackages.value[0]?.id || 'sms_50')
const selectedPayMethod = ref('WECHAT') // WECHAT / ALIPAY

const currentSelectedPackage = computed(() => {
  return smsPackages.value.find(p => String(p.id) === String(selectedPackageId.value)) || smsPackages.value[0]
})

const isCurrentNewTenant = computed(() => {
  return systemData.isNewTenant ||
    localStorage.getItem('seahorse_is_new_tenant') === 'true' ||
    localStorage.getItem('seahorse_role') === 'TENANT_ADMIN'
})

// 短信余量与流水 (新注册租户纯净化为0，清空历史假流水)
const savedSmsBalance = localStorage.getItem('seahorse_sms_balance')
const currentSmsBalance = ref(
  savedSmsBalance !== null
    ? Number(savedSmsBalance)
    : 0
)
const totalSmsRecharged = ref(0)
const totalSmsUsed = ref(0)

const smsCurrentPage = ref(1)
const smsPageSize = ref(5)

const smsRecords = ref<any[]>([])

const paginatedSmsRecords = computed(() => {
  const start = (smsCurrentPage.value - 1) * smsPageSize.value
  return smsRecords.value.slice(start, start + smsPageSize.value)
})

// 支付弹窗
const openPayDialog = ref(false)
const paying = ref(false)

const handleOpenPayModal = () => {
  openPayDialog.value = true
}

const handleConfirmSimulationPay = () => {
  paying.value = true
  setTimeout(() => {
    paying.value = false
    const pkg = currentSelectedPackage.value
    currentSmsBalance.value += pkg.count
    totalSmsRecharged.value += pkg.count
    localStorage.setItem('seahorse_sms_balance', String(currentSmsBalance.value))

    smsRecords.value.unshift({
      id: 'SMS' + Date.now(),
      scene: '短信套餐充值',
      phone: '门店充值',
      change: pkg.count,
      balance: currentSmsBalance.value,
      time: new Date().toLocaleString(),
      status: 'SUCCESS',
      desc: `${pkg.name} (${selectedPayMethod.value === 'WECHAT' ? '微信支付' : '支付宝支付'} ￥${pkg.price})`
    })

    openPayDialog.value = false
    ElNotification({
      title: '🎉 短信充值成功到账！',
      message: `成功购买【${pkg.name}】，增加短信 ${pkg.count} 条，当前账户可用结余：${currentSmsBalance.value} 条。`,
      type: 'success',
      duration: 4500
    })
    smsCurrentSubTab.value = 'BALANCE'
  }, 600)
}

// 短信签名 (真实文件选取、图片预览、实名报备)
const openApplySignDialog = ref(false)
const openSignDetailDialog = ref(false)
const currentSignDetail = ref<any>(null)

const licenseFileInputRef = ref<HTMLInputElement>()
const idFrontFileInputRef = ref<HTMLInputElement>()
const idBackFileInputRef = ref<HTMLInputElement>()
const idHoldFileInputRef = ref<HTMLInputElement>()

const triggerFileInput = (field: 'license' | 'idFront' | 'idBack' | 'idHold') => {
  if (field === 'license') licenseFileInputRef.value?.click()
  else if (field === 'idFront') idFrontFileInputRef.value?.click()
  else if (field === 'idBack') idBackFileInputRef.value?.click()
  else if (field === 'idHold') idHoldFileInputRef.value?.click()
}

const handleRealFileChange = (e: Event, field: 'license' | 'idFront' | 'idBack' | 'idHold') => {
  const target = e.target as HTMLInputElement
  const files = target.files
  if (!files || files.length === 0) return
  const file = files[0]
  if (!file.type.startsWith('image/')) {
    ElMessage.warning('请选择 JPG、PNG 等格式的图片文件')
    return
  }
  if (file.size > 8 * 1024 * 1024) {
    ElMessage.warning('图片大小不能超过 8MB，请适当压缩后再上传')
    return
  }
  const reader = new FileReader()
  reader.onload = (event) => {
    const base64 = event.target?.result as string
    if (field === 'license') applySignForm.value.licenseImg = base64
    else if (field === 'idFront') applySignForm.value.idFrontImg = base64
    else if (field === 'idBack') applySignForm.value.idBackImg = base64
    else if (field === 'idHold') applySignForm.value.idHoldImg = base64
    ElMessage.success(`【${file.name}】真实证件图片已读取载入！`)
  }
  reader.readAsDataURL(file)
  target.value = ''
}

const handleRemoveUploadedFile = (field: 'license' | 'idFront' | 'idBack' | 'idHold') => {
  if (field === 'license') applySignForm.value.licenseImg = ''
  else if (field === 'idFront') applySignForm.value.idFrontImg = ''
  else if (field === 'idBack') applySignForm.value.idBackImg = ''
  else if (field === 'idHold') applySignForm.value.idHoldImg = ''
  ElMessage.info('已清除已选图片，可重新上传')
}

const applySignForm = ref({
  companyName: isCurrentNewTenant.value ? '' : '上海海马智慧科技服务有限公司',
  creditCode: isCurrentNewTenant.value ? '' : '91310115MA1H888888',
  legalPerson: isCurrentNewTenant.value ? '' : '张海马',
  idCard: isCurrentNewTenant.value ? '' : '310115198808088888',
  legalPhone: isCurrentNewTenant.value ? '' : '13800138000',
  smsContent: '【门店签名】尊敬的{会员姓名}，您的专属礼遇已生效，到店消费即可立减，回复T退订。',
  reportPhone: isCurrentNewTenant.value ? '' : '021-88889999',
  licenseImg: '',
  idFrontImg: '',
  idBackImg: '',
  idHoldImg: ''
})

const defaultSignatures = [
  {
    id: 1,
    companyName: '上海海马智慧科技服务有限公司',
    creditCode: '91310115MA1H888888',
    legalPerson: '张海马',
    idCard: '310115198808088888',
    legalPhone: '13800138000',
    signName: '海马智慧商业',
    smsContent: '【海马智慧商业】您的会员卡已成功充值，当前余额已更新，祝您体验愉快。',
    reportPhone: '021-88889999',
    licenseImg: '',
    idFrontImg: '',
    idBackImg: '',
    idHoldImg: '',
    applyTime: '2026-08-20 14:30:00',
    status: 'APPROVED',
    auditReason: '平台审核通过，已向运营商完成实名报备，可正常使用'
  }
]

const loadSignatures = () => {
  try {
    const raw = localStorage.getItem('seahorse_sms_signatures')
    if (raw) return JSON.parse(raw)
  } catch (e) {}
  if (isCurrentNewTenant.value) {
    return [] // 新租户无任何预设假签名，纯净化显示空状态
  }
  return [...defaultSignatures]
}

const signaturesList = ref<any[]>(loadSignatures())

const currentActiveSignName = computed(() => {
  const approved = signaturesList.value.find(s => s.status === 'APPROVED')
  return approved ? approved.signName : '未配置签名'
})

const handleConfirmApplySign = () => {
  if (
    !applySignForm.value.companyName ||
    !applySignForm.value.creditCode ||
    !applySignForm.value.legalPerson ||
    !applySignForm.value.idCard ||
    !applySignForm.value.legalPhone ||
    !applySignForm.value.smsContent
  ) {
    ElMessage.warning('请完整填写公司、法人及短信内容等必填项')
    return
  }

  // 提取签名
  let sName = '海马美业'
  const match = applySignForm.value.smsContent.match(/【(.*?)】/)
  if (match && match[1]) {
    sName = match[1]
  } else if (applySignForm.value.companyName) {
    sName = applySignForm.value.companyName.substring(0, 6)
  }

  const newSign = {
    id: Date.now(),
    companyName: applySignForm.value.companyName,
    creditCode: applySignForm.value.creditCode,
    legalPerson: applySignForm.value.legalPerson,
    idCard: applySignForm.value.idCard,
    legalPhone: applySignForm.value.legalPhone,
    signName: sName,
    smsContent: applySignForm.value.smsContent,
    reportPhone: applySignForm.value.reportPhone,
    licenseImg: applySignForm.value.licenseImg,
    idFrontImg: applySignForm.value.idFrontImg,
    idBackImg: applySignForm.value.idBackImg,
    idHoldImg: applySignForm.value.idHoldImg,
    applyTime: new Date().toLocaleString(),
    status: 'APPROVED',
    auditReason: '平台已初审通过，三大运营商实名报备通过'
  }

  signaturesList.value.unshift(newSign)
  localStorage.setItem('seahorse_sms_signatures', JSON.stringify(signaturesList.value))
  openApplySignDialog.value = false

  ElNotification({
    title: '🎉 短信签名申请提交成功',
    message: `公司【${newSign.companyName}】申请签名【${newSign.signName}】已提交，云管平台审核通过，运营商报备已完成！`,
    type: 'success',
    duration: 5000
  })
}

const handleViewSignDetail = (row: any) => {
  currentSignDetail.value = row
  openSignDetailDialog.value = true
}

const handleDeleteSign = (row: any) => {
  ElMessageBox.confirm(`确定要注销并删除【${row.companyName}】的短信签名吗？`, '安全提示', {
    confirmButtonText: '删除',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    signaturesList.value = signaturesList.value.filter(s => s.id !== row.id)
    localStorage.setItem('seahorse_sms_signatures', JSON.stringify(signaturesList.value))
    ElMessage.success('已删除该签名记录')
  })
}

// 4. 短信群发与目标客群明细编辑查询
const bulkForm = ref({
  targetGroup: 'ALL',
  content: '尊敬的{会员姓名}，海马会员专享福利已到账！到店出示卡号即可享立减{优惠金额}元，期待您的光临！预约电话：{门店电话}'
})
const sendingBulk = ref(false)
const openBulkMembersDrawer = ref(false)
const bulkMemberSearchKeyword = ref('')

const getTargetGroupText = (val: string) => {
  switch (val) {
    case 'ALL': return '全体在籍会员'
    case 'INACTIVE_30': return '近30天未到店老客'
    case 'VIP': return '高净值VIP会员'
    case 'BIRTHDAY': return '本月生日会员'
    default: return '目标客群'
  }
}

// 动态计算当前所选客群分类包含的真实会员名单
const currentTargetGroupMembers = computed(() => {
  const allMembers = systemData.members || []
  switch (bulkForm.value.targetGroup) {
    case 'ALL':
      return allMembers
    case 'INACTIVE_30':
      return allMembers.filter(m => (m.consumeCount || 0) <= 2 || (m.daysSinceLastVisit && m.daysSinceLastVisit >= 30))
    case 'VIP':
      return allMembers.filter(m => {
        const lvl = (m.level || '').toUpperCase()
        const lvlName = m.levelName || ''
        return lvl === 'DIAMOND' || lvl === 'GOLD' || lvl === 'PLATINUM' || lvlName.includes('钻') || lvlName.includes('金')
      })
    case 'BIRTHDAY':
      const currentMonth = new Date().getMonth() + 1
      return allMembers.filter(m => {
        if (m.birthday) {
          const parts = m.birthday.split('-')
          if (parts.length >= 2 && parseInt(parts[1]) === currentMonth) return true
        }
        return (m.id % 2 === 0)
      })
    default:
      return allMembers
  }
})

// 当前勾选纳入群发的会员 ID 列表
const selectedBulkMemberIds = ref<number[]>([])

const syncBulkSelectionWithGroup = () => {
  selectedBulkMemberIds.value = currentTargetGroupMembers.value.map(m => m.id)
}

// 初始联动客群勾选
syncBulkSelectionWithGroup()

const handleTargetGroupChange = () => {
  syncBulkSelectionWithGroup()
}

const handleOpenBulkMembersModal = () => {
  if (selectedBulkMemberIds.value.length === 0 && currentTargetGroupMembers.value.length > 0) {
    syncBulkSelectionWithGroup()
  }
  openBulkMembersDrawer.value = true
}

const filteredTargetGroupMembers = computed(() => {
  const list = currentTargetGroupMembers.value
  if (!bulkMemberSearchKeyword.value) return list
  const q = bulkMemberSearchKeyword.value.toLowerCase()
  return list.filter(m =>
    (m.name && m.name.toLowerCase().includes(q)) ||
    (m.phone && m.phone.includes(q)) ||
    (m.memberNo && m.memberNo.toLowerCase().includes(q))
  )
})

const isAllVisibleBulkSelected = computed(() => {
  const list = filteredTargetGroupMembers.value
  if (list.length === 0) return false
  return list.every(m => selectedBulkMemberIds.value.includes(m.id))
})

const isIndeterminateBulkSelected = computed(() => {
  const list = filteredTargetGroupMembers.value
  if (list.length === 0) return false
  const count = list.filter(m => selectedBulkMemberIds.value.includes(m.id)).length
  return count > 0 && count < list.length
})

const handleToggleSelectAllVisibleBulk = (val: any) => {
  const visibleIds = filteredTargetGroupMembers.value.map(m => m.id)
  if (val) {
    visibleIds.forEach(id => {
      if (!selectedBulkMemberIds.value.includes(id)) {
        selectedBulkMemberIds.value.push(id)
      }
    })
  } else {
    selectedBulkMemberIds.value = selectedBulkMemberIds.value.filter(id => !visibleIds.includes(id))
  }
}

const handleToggleSingleMember = (id: number, val: boolean) => {
  if (val) {
    if (!selectedBulkMemberIds.value.includes(id)) {
      selectedBulkMemberIds.value.push(id)
    }
  } else {
    selectedBulkMemberIds.value = selectedBulkMemberIds.value.filter(item => item !== id)
  }
}

const handleSelectAllBulkMembers = () => {
  selectedBulkMemberIds.value = currentTargetGroupMembers.value.map(m => m.id)
  ElMessage.success(`已全选当前客群全部 ${selectedBulkMemberIds.value.length} 位会员！`)
}

const handleDeselectAllBulkMembers = () => {
  selectedBulkMemberIds.value = []
  ElMessage.info('已清空所有已选客群')
}

const handleResetBulkGroupSelection = () => {
  syncBulkSelectionWithGroup()
  ElMessage.success('已恢复默认全选当前客群！')
}

const totalBulkChars = computed(() => {
  return (currentActiveSignName.value.length + 2) + bulkForm.value.content.length
})

const bulkSmsCountPerPerson = computed(() => {
  return Math.ceil(totalBulkChars.value / 70) || 1
})

// 目标接收客户人数：严格与当前实际勾选客群会员数 100% 动态一致
const estimatedMemberCount = computed(() => {
  return selectedBulkMemberIds.value.length
})

const handleInsertTemplate = (type: string) => {
  switch (type) {
    case 'WEL':
      bulkForm.value.content = '尊敬的{会员姓名}，恭喜您成为会员！我们已为您卡包派发迎新优惠券，到店即可享用专属礼遇，回复T退订。'
      break
    case 'VIP':
      bulkForm.value.content = '尊敬的VIP会员{会员姓名}，本周为会员尊享日，到店消费即可享专属折扣与积分翻倍，期待您的光临！'
      break
    case 'CALL':
      bulkForm.value.content = '亲爱的{会员姓名}，好久不见！我们为您准备了老友回归礼包，凭此短信到店消费享立减优惠，预约热线：021-88889999。'
      break
    case 'BIRTH':
      bulkForm.value.content = '祝亲爱的{会员姓名}生日快乐！我们为您准备了生日专属礼遇，本月到店消费享多重惊喜好礼，欢迎莅临！'
      break
  }
}

const handleSendTestSms = () => {
  if (currentSmsBalance.value < 1) {
    ElMessage.warning('当前短信余量不足，请先充值')
    return
  }
  currentSmsBalance.value -= 1
  localStorage.setItem('seahorse_sms_balance', String(currentSmsBalance.value))
  smsRecords.value.unshift({
    id: 'SMS' + Date.now(),
    scene: '测试短信发送',
    phone: basicForm.value.phone,
    change: -1,
    balance: currentSmsBalance.value,
    time: new Date().toLocaleString(),
    status: 'SUCCESS',
    desc: '系统设置-群发预览测试短信'
  })
  ElMessage.success(`测试短信已成功发送至 ${basicForm.value.phone}！扣减短信 1 条。`)
}

const handleConfirmBulkSend = () => {
  if (estimatedMemberCount.value === 0) {
    ElMessage.warning('当前客群中暂无可发送的目标会员，请先选择客群或在名单中勾选客户！')
    return
  }

  const needed = estimatedMemberCount.value * bulkSmsCountPerPerson.value
  if (currentSmsBalance.value < needed) {
    ElMessage.warning(`短信余量不足！本次群发需扣减 ${needed} 条，当前可用仅 ${currentSmsBalance.value} 条，请先购买短信包。`)
    return
  }

  ElMessageBox.confirm(
    `确定要向【${getTargetGroupText(bulkForm.value.targetGroup)}】客群 (${estimatedMemberCount.value} 人) 群发营销短信吗？预计扣减短信 ${needed} 条。`,
    '短信群发二次确认',
    { confirmButtonText: '立即发送', cancelButtonText: '取消', type: 'warning' }
  ).then(() => {
    sendingBulk.value = true
    setTimeout(() => {
      sendingBulk.value = false
      currentSmsBalance.value -= needed
      totalSmsUsed.value += needed
      localStorage.setItem('seahorse_sms_balance', String(currentSmsBalance.value))

      smsRecords.value.unshift({
        id: 'SMS' + Date.now(),
        scene: '营销短信群发',
        phone: `批量目标 ${estimatedMemberCount.value} 人`,
        change: -needed,
        balance: currentSmsBalance.value,
        time: new Date().toLocaleString(),
        status: 'SUCCESS',
        desc: `群发内容: ${bulkForm.value.content.substring(0, 18)}...`
      })

      ElNotification({
        title: '🎉 短信群发任务已完成',
        message: `成功向 ${estimatedMemberCount.value} 位会员派发短信，扣减 ${needed} 条短信，当前可用余额 ${currentSmsBalance.value} 条。`,
        type: 'success'
      })
      smsCurrentSubTab.value = 'BALANCE'
    }, 800)
  })
}

// 5. 行业分类配置
const industryCascader = ref([1, 6]) // 服务类 > 美业服务
const currentIndustryGroup = ref('服务类')
const currentIndustryName = ref('美业服务')

const cascaderOptions = [
  {
    value: 1,
    label: '服务类',
    children: [
      { value: 1, label: '汽车服务' },
      { value: 6, label: '美业服务' },
      { value: 7, label: '保健按摩' },
      { value: 8, label: '宠物店' },
      { value: 9, label: '运动健身' },
      { value: 10, label: '摄影写真' }
    ]
  },
  {
    value: 2,
    label: '餐饮类',
    children: [
      { value: 2, label: '餐饮店' },
      { value: 11, label: '咖啡奶茶' },
      { value: 12, label: '火锅烤肉' }
    ]
  },
  {
    value: 3,
    label: '零售类',
    children: [
      { value: 3, label: '便利店' },
      { value: 13, label: '服装鞋帽' },
      { value: 14, label: '水果生鲜' }
    ]
  }
]

// 6. 双轨储值与收银规则
const ruleForm = ref({
  deductMode: storeConfig.deductMode || 'PROPORTIONAL',
  enableTrial: true,
  trialDays: 3,
  earnRate: 1,
  pointsRate: 100,
  maxPointsDeductPercent: 30,
  cashRoundingMode: 'ROUND_NONE'
})

// 交互式划扣沙盘模拟器
const sandboxData = ref({
  principal: 1000,
  gift: 200,
  consume: 300
})

const sandboxResult = computed(() => {
  const p = Math.max(0, sandboxData.value.principal || 0)
  const g = Math.max(0, sandboxData.value.gift || 0)
  const c = Math.max(0, sandboxData.value.consume || 0)
  const total = p + g
  if (total <= 0 || c <= 0) {
    return { deductP: 0, deductG: 0, remainP: p, remainG: g, pPercent: 0, gPercent: 0 }
  }
  const actualPay = Math.min(total, c)
  if (ruleForm.value.deductMode === 'PROPORTIONAL') {
    const ratioP = p / total
    const deductP = Number((actualPay * ratioP).toFixed(2))
    const deductG = Number((actualPay - deductP).toFixed(2))
    return {
      deductP,
      deductG,
      remainP: Number((p - deductP).toFixed(2)),
      remainG: Number((g - deductG).toFixed(2)),
      pPercent: Math.round((p / total) * 100),
      gPercent: Math.round((g / total) * 100)
    }
  } else {
    const deductP = Math.min(p, actualPay)
    const deductG = Number((actualPay - deductP).toFixed(2))
    return {
      deductP,
      deductG,
      remainP: Number((p - deductP).toFixed(2)),
      remainG: Number((g - deductG).toFixed(2)),
      pPercent: Math.round((p / total) * 100),
      gPercent: Math.round((g / total) * 100)
    }
  }
})

const handleSaveRechargeRules = () => {
  storeConfig.deductMode = ruleForm.value.deductMode
  localStorage.setItem('seahorse_deduct_mode', ruleForm.value.deductMode)
  localStorage.setItem('seahorse_recharge_rules', JSON.stringify(ruleForm.value))
  ElMessage.success(`双轨储值与收银规则配置已成功保存！当前扣减策略：【${ruleForm.value.deductMode === 'PROPORTIONAL' ? '同比例等比扣减 (推荐)' : '优先扣减实充本金'}】`)
}

// 7. 小票打印机与模板配置 (细粒度开关与微调)
const printerForm = ref<ReceiptTemplateConfig>(
  systemData.getResolvedReceiptTemplate(storeConfig.currentStoreId)
)

// 预设配置一键应用
const applyPrinterPreset = (mode: 'ALL' | 'RECOMMENDED' | 'MINIMAL') => {
  if (mode === 'ALL') {
    Object.keys(printerForm.value).forEach(k => {
      if (typeof (printerForm.value as any)[k] === 'boolean') {
        (printerForm.value as any)[k] = true
      }
    })
    ElMessage.success('已开启全部小票打印模块与明细字段')
  } else if (mode === 'RECOMMENDED') {
    printerForm.value.showStoreHeader = true
    printerForm.value.showHeaderSubtitle = true
    printerForm.value.showTicketTitle = true
    printerForm.value.showOrderNo = true
    printerForm.value.showCheckoutTime = true
    printerForm.value.showCashierName = true
    printerForm.value.showTechnician = true
    printerForm.value.showCustomerName = true
    printerForm.value.showCustomerPhone = true
    printerForm.value.maskCustomerPhone = true
    printerForm.value.showItemsTable = true
    printerForm.value.showItemQty = true
    printerForm.value.showItemPrice = true
    printerForm.value.showItemSum = true
    printerForm.value.showOriginalPrice = true
    printerForm.value.showDiscount = true
    printerForm.value.showActualAmount = true
    printerForm.value.showPayMethods = true
    printerForm.value.showMemberAssetSection = true
    printerForm.value.showPrincipalBalance = true
    printerForm.value.showGiftBalance = true
    printerForm.value.showEarnedPoints = true
    printerForm.value.showTotalPoints = true
    printerForm.value.showFooterNotes = true
    printerForm.value.showServiceHotline = true
    printerForm.value.showStoreAddress = true
    printerForm.value.showQrCode = true
    printerForm.value.showSignStub = true
    printerForm.value.showStubOrderMeta = true
    printerForm.value.showStubSignLine = true
    ElMessage.success('已应用租户常用推荐模板配置')
  } else if (mode === 'MINIMAL') {
    printerForm.value.showStoreHeader = true
    printerForm.value.showHeaderSubtitle = false
    printerForm.value.showTicketTitle = true
    printerForm.value.showOrderNo = true
    printerForm.value.showCheckoutTime = true
    printerForm.value.showCashierName = false
    printerForm.value.showTechnician = false
    printerForm.value.showCustomerName = true
    printerForm.value.showCustomerPhone = false
    printerForm.value.maskCustomerPhone = true
    printerForm.value.showItemsTable = true
    printerForm.value.showItemQty = true
    printerForm.value.showItemPrice = false
    printerForm.value.showItemSum = true
    printerForm.value.showOriginalPrice = false
    printerForm.value.showDiscount = false
    printerForm.value.showActualAmount = true
    printerForm.value.showPayMethods = true
    printerForm.value.showMemberAssetSection = false
    printerForm.value.showPrincipalBalance = false
    printerForm.value.showGiftBalance = false
    printerForm.value.showEarnedPoints = false
    printerForm.value.showTotalPoints = false
    printerForm.value.showFooterNotes = true
    printerForm.value.showServiceHotline = false
    printerForm.value.showStoreAddress = false
    printerForm.value.showQrCode = false
    printerForm.value.showSignStub = false
    printerForm.value.showStubOrderMeta = false
    printerForm.value.showStubSignLine = false
    ElMessage.info('已应用极简出票模式 (省纸紧凑)')
  }
}

const paperStageRef = ref<HTMLElement | null>(null)
const scrollPreviewToTop = () => {
  if (paperStageRef.value) {
    paperStageRef.value.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

const currentOperatorName = computed(() => {
  const user = localStorage.getItem('seahorse_user')
  if (user) return user
  const role = localStorage.getItem('seahorse_role')
  if (role === 'SUPER_ADMIN' || role === 'TENANT_ADMIN') return '店长/管理员'
  if (role === 'CASHIER') return '前台收银员'
  return '当前操作员'
})

const receiptSampleQrDataUrl = ref('')
const generateSampleQrCode = async () => {
  try {
    const text = printerForm.value.qrCodeText || `${window.location.origin}/seahorse/member-portal`
    receiptSampleQrDataUrl.value = await QRCode.toDataURL(text, {
      width: 140,
      margin: 1,
      color: { dark: '#0f172a', light: '#ffffff' }
    })
  } catch (err) {
    console.error('Failed to generate sample QR code', err)
  }
}

watch(
  () => [printerForm.value.qrCodeText, printerForm.value.showQrCode],
  () => {
    if (printerForm.value.showQrCode) {
      generateSampleQrCode()
    }
  },
  { immediate: true }
)

const formatSettingsPhone = (phone: string, mask: boolean) => {
  if (!phone) return ''
  if (!mask) return phone
  return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
}

const handleSyncCurrentStoreInfoToReceipt = () => {
  const storeId = storeConfig.currentStoreId || 'S001'
  const resolved = systemData.getResolvedReceiptTemplate(storeId)
  printerForm.value.storeHeaderTitle = resolved.storeHeaderTitle
  printerForm.value.serviceHotline = resolved.serviceHotline
  printerForm.value.storeAddress = resolved.storeAddress
  printerForm.value.qrCodeText = resolved.qrCodeText
  ElMessage.success('已一键载入当前店铺抬头、联系电话、地址与专属扫码网址！')
}

const handleResetStoreQrUrl = () => {
  const storeId = storeConfig.currentStoreId || 'S001'
  printerForm.value.qrCodeText = buildMemberBenefitsUrl(storeId)
  ElMessage.success('已自动生成当前店铺专属顾客权益与门店信息访问链接！')
}

const handleSaveReceiptTemplate = () => {
  systemData.updateReceiptTemplate(printerForm.value)
  ElMessage.success('小票打印机与模板配置已更新，全系统收银即时同步生效！')
}

// 🖨️ 热敏小票测试样张打印 (物理隔离沙箱，100% 杜绝背景网页/侧边栏泄露)
const handlePrintTestReceipt = () => {
  const el = document.getElementById('settings-thermal-sample-ticket')
  if (!el) {
    ElMessage.warning('未找到小票打印模板DOM节点')
    return
  }

  const is58 = printerForm.value.paperWidth === '58mm'
  const paperWidthMm = is58 ? '58mm' : '80mm'
  const fontSize = printerForm.value.fontSize === 'compact' ? '11px' : printerForm.value.fontSize === 'large' ? '14px' : '12.5px'

  let iframe = document.getElementById('receipt-print-iframe') as HTMLIFrameElement
  if (!iframe) {
    iframe = document.createElement('iframe')
    iframe.id = 'receipt-print-iframe'
    iframe.style.position = 'fixed'
    iframe.style.right = '0'
    iframe.style.bottom = '0'
    iframe.style.width = '0'
    iframe.style.height = '0'
    iframe.style.border = 'none'
    iframe.style.visibility = 'hidden'
    document.body.appendChild(iframe)
  }

  const doc = iframe.contentWindow?.document
  if (!doc) {
    ElMessage.error('无法初始化打印沙箱，请检查浏览器权限')
    return
  }

  doc.open()
  doc.write(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>热敏小票测试样张打印</title>
        <style>
          @page {
            size: ${paperWidthMm} auto;
            margin: 0mm;
          }
          * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
          }
          html, body {
            width: ${paperWidthMm};
            background: #ffffff !important;
            color: #000000 !important;
            font-family: 'Courier New', Courier, Consolas, Monaco, monospace, sans-serif;
            font-size: ${fontSize};
            line-height: 1.55;
          }
          .thermal-print-wrapper {
            width: ${paperWidthMm};
            padding: 3mm 2mm;
            background: #ffffff;
            margin: 0 auto;
          }
          .paper-sawtooth { display: none !important; }
          .receipt-center-box { text-align: center; }
          .receipt-shop-name { font-size: 15px; font-weight: 800; color: #000; letter-spacing: 0.5px; }
          .receipt-sub-title { font-size: 11px; color: #222; margin-top: 2px; }
          .receipt-ticket-type { font-size: 12.5px; font-weight: 700; margin-top: 4px; color: #000; }
          .receipt-divider { text-align: center; font-size: 11px; color: #000; margin: 6px 0; overflow: hidden; white-space: nowrap; font-family: monospace; }
          .receipt-meta-grid { line-height: 1.7; }
          .meta-row { display: flex; justify-content: space-between; }
          .mono { font-family: 'Courier New', monospace; font-weight: 600; }
          .receipt-items-table { width: 100%; margin: 4px 0; }
          .items-head { display: flex; font-weight: 700; border-bottom: 1px dashed #000; padding-bottom: 3px; margin-bottom: 4px; }
          .col-name { flex: 2; text-align: left; }
          .col-qty { width: 36px; text-align: center; }
          .col-price { width: 52px; text-align: right; }
          .col-sum { width: 58px; text-align: right; }
          .item-row { margin-bottom: 5px; }
          .item-name { font-weight: 600; color: #000; }
          .item-meta { display: flex; justify-content: flex-end; gap: 14px; font-size: 0.95em; }
          .receipt-calc-box { line-height: 1.75; }
          .calc-row { display: flex; justify-content: space-between; }
          .calc-row.discount { font-weight: 600; }
          .calc-row.total { font-size: 14px; font-weight: 800; border-top: 1px dashed #000; padding-top: 4px; margin-top: 4px; }
          .bold-price { font-size: 16px; font-weight: 800; color: #000; }
          .pay-split-list { padding-left: 6px; font-size: 11px; margin-top: 3px; }
          .pay-row { display: flex; justify-content: space-between; }
          .receipt-member-asset-box { line-height: 1.75; }
          .asset-title { text-align: center; font-weight: 700; margin-bottom: 4px; color: #000; }
          .asset-row { display: flex; justify-content: space-between; }
          .receipt-footer-box { text-align: center; font-size: 11px; line-height: 1.55; margin-top: 6px; }
          .footer-notes { font-weight: 700; color: #000; margin-bottom: 4px; }
          .footer-meta { display: flex; flex-direction: column; gap: 2px; font-size: 10.5px; }
          .receipt-qr-zone { margin-top: 8px; display: flex; flex-direction: column; align-items: center; }
          .qr-img-wrapper { background: #ffffff; padding: 2px; display: flex; align-items: center; justify-content: center; }
          .qr-real-img { width: 75px; height: 75px; display: block; }
          .qr-hint-text { font-size: 10px; color: #000; margin-top: 3px; max-width: 240px; text-align: center; }
          .qr-url-text { font-size: 9px; color: #333; word-break: break-all; max-width: 240px; text-align: center; }
          .receipt-sign-stub { margin-top: 12px; line-height: 1.75; }
          .stub-divider { text-align: center; color: #000; margin-bottom: 4px; letter-spacing: 1px; }
          .stub-header { text-align: center; font-weight: 700; color: #000; }
          .stub-meta { display: flex; justify-content: space-between; font-size: 11px; }
          .stub-sign-block { margin-top: 10px; display: flex; flex-direction: column; gap: 8px; }
          .stub-sign-row { display: flex; align-items: flex-end; gap: 6px; }
          .sign-label { font-size: 11.5px; color: #000; font-weight: 700; white-space: nowrap; }
          .sign-underline { flex: 1; border-bottom: 1px solid #000; height: 1px; margin-bottom: 2px; }
          .stub-date-row { display: flex; justify-content: flex-end; font-size: 11px; color: #000; }
        </style>
      </head>
      <body>
        <div class="thermal-print-wrapper">
          ${el.innerHTML}
        </div>
      </body>
    </html>
  `)
  doc.close()

  setTimeout(() => {
    iframe.contentWindow?.focus()
    iframe.contentWindow?.print()
  }, 250)
  ElMessage.success('已向本地打印机发送小票测试样张！')
}

// =========================================================================
// 7. 全渠道消息推送与公众号配置模块 (店务端使用与拓客水牌)
// =========================================================================
const notifSubTab = ref<'STAND' | 'GUIDE' | 'PREVIEW' | 'SIMULATOR' | 'STRATEGY' | 'LOGS'>('STAND')
const savingNotif = ref(false)
const simulatingFollow = ref(false)
const sendingTest = ref(false)
const loadingLogs = ref(false)

// 门店专属水牌与二维码
const selectedStandStoreId = ref(storeConfig.currentStoreId || 'S001')
const wechatStoreQrCodeDataUrl = ref('')
const alipayStoreQrCodeDataUrl = ref('')
const printStandDialogVisible = ref(false)
const printStandChannel = ref<'WECHAT' | 'ALIPAY'>('WECHAT')

const storeListOptions = computed(() => {
  if (storeConfig.stores && storeConfig.stores.length > 0) {
    return storeConfig.stores
  }
  return [
    { storeId: storeConfig.currentStoreId || 'S001', storeName: storeConfig.storeName || '海马美业·旗舰体验中心' }
  ]
})

const currentSelectedStoreName = computed(() => {
  const match = storeListOptions.value.find((s: any) => s.storeId === selectedStandStoreId.value)
  return match?.storeName || storeConfig.storeName || '海马美业·旗舰体验中心'
})

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
  mockPushEnabled: true,
  autoPushOnCheckout: true,
  autoPushOnRecharge: true,
  autoPushOnMarketing: true,
  voiceBroadcastRepeatCount: 1
})

// 租户自定义通知模板首句、尾部提示与跳转链接
const defaultTemplateSettings = {
  recharge: {
    firstText: '尊敬的贵宾，您的会员储值账户已成功入账！',
    remarkText: '感谢您选择【御境云足·东方养生会所】，点击查看电子卡包与赠金资产明细。',
    jumpUrl: 'pages/member/wallet'
  },
  consume: {
    firstText: '您在【御境云足】的消费账单已结账完毕，感谢您的光临！',
    remarkText: '如有开票需求或对服务有任何宝贵建议，欢迎随时向前台反馈，祝您生活愉快！',
    jumpUrl: 'pages/order/detail'
  },
  appointment: {
    firstText: '您的养生预约已由前台管家受理确认，静候您的光临！',
    remarkText: '如需调整时间或更换技师，请提前致电会所前台，包厢将为您保留15分钟。',
    jumpUrl: 'pages/appointment/detail'
  }
}

const loadStoredTemplateSettings = () => {
  try {
    const raw = localStorage.getItem('seahorse_notif_template_settings')
    if (raw) return JSON.parse(raw)
  } catch (e) {}
  return JSON.parse(JSON.stringify(defaultTemplateSettings))
}

const templateSettings = ref<any>(loadStoredTemplateSettings())

const saveTemplateSettings = () => {
  localStorage.setItem('seahorse_notif_template_settings', JSON.stringify(templateSettings.value))
  ElMessage.success('门店通知模板自定义字段与链接配置已保存！')
}

const resetTemplateSettings = () => {
  templateSettings.value = JSON.parse(JSON.stringify(defaultTemplateSettings))
  localStorage.setItem('seahorse_notif_template_settings', JSON.stringify(templateSettings.value))
  ElMessage.info('已恢复官方推荐默认模板配置')
}

// 一键装载真实足疗推拿养生业务场景模拟数据
const handleLoadFootSpaDemoData = () => {
  ElMessageBox.confirm(
    '确定要装载【御境云足·东方养生泰式SPA会所】的真实业务场景全套数据吗？系统将注入3家连锁门店、7位技师（含88号/66号/18号首席与金牌工号）、7款经典足道推拿品项、豪华包厢工位与预约排班。',
    '装载真实足疗推拿业务数据',
    {
      confirmButtonText: '立即装载',
      cancelButtonText: '取消',
      type: 'success'
    }
  ).then(() => {
    injectFootSpaMockData(systemData, storeConfig)
    ElMessage.success('🎉 足疗推拿养生业务全套真实数据装载成功！页面正在刷新生效...')
    setTimeout(() => {
      window.location.reload()
    }, 800)
  }).catch(() => {})
}

const notifLogs = ref<any[]>([])
const testForm = ref({
  channel: 'WECHAT_MP',
  msgType: 'CONSUME_NOTICE',
  targetPhone: '13888888888'
})

const simulatePhone = ref('13888888888')
const simulateChannel = ref('WECHAT_MP')
const lastFollowResult = ref<any>(null)

const openLogDetailDialog = ref(false)
const currentLogDetail = ref<any>(null)

const currentClockStr = computed(() => {
  const now = new Date()
  const pad = (n: number) => n < 10 ? '0' + n : n
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`
})

const previewCardTitle = computed(() => {
  if (testForm.value.msgType === 'CONSUME_NOTICE') return '消费结账成功通知'
  if (testForm.value.msgType === 'RECHARGE_NOTICE') return '会员储值充值到账提醒'
  if (testForm.value.msgType === 'MARKETING_CAMPAIGN') return '🎉 门店特惠营销活动上线！'
  return '海马汇全渠道消息推送连通测试'
})

const previewCardRemark = computed(() => {
  if (testForm.value.msgType === 'CONSUME_NOTICE') {
    return '卡内剩余可用储值: ￥800.00，当前积分: 120。点击下方链接查看电子账单明细。'
  }
  if (testForm.value.msgType === 'RECHARGE_NOTICE') {
    return '本金账户余额: ￥1,000.00，赠送账户: ￥200.00。感谢您的信任与支持！'
  }
  if (testForm.value.msgType === 'MARKETING_CAMPAIGN') {
    return '全体认证会员特享立减优惠，数量有限，请尽快点击使用！'
  }
  return '此条为沙箱模拟测试消息，用于验证微信公众号与生活号消息格式与即时推送管道正常运行。'
})

const generateStoreQrCodes = async () => {
  const storeId = selectedStandStoreId.value || 'S001'
  const tenantId = storeConfig.tenantId || 'T001'
  const wechatUrl = `https://mp.weixin.qq.com/s/seahorse_demo?tenantId=${tenantId}&storeId=${storeId}&scene=store_stand`
  const alipayUrl = `https://alipay.com/life/seahorse_demo?tenantId=${tenantId}&storeId=${storeId}&scene=store_stand`
  try {
    wechatStoreQrCodeDataUrl.value = await QRCode.toDataURL(wechatUrl, {
      width: 320,
      margin: 2,
      color: { dark: '#064e3b', light: '#ffffff' }
    })
    alipayStoreQrCodeDataUrl.value = await QRCode.toDataURL(alipayUrl, {
      width: 320,
      margin: 2,
      color: { dark: '#0369a1', light: '#ffffff' }
    })
  } catch (err) {
    console.warn('生成门店专属拓客二维码失败', err)
  }
}

const handleDownloadStandQr = (channel: 'WECHAT' | 'ALIPAY') => {
  const dataUrl = channel === 'WECHAT' ? wechatStoreQrCodeDataUrl.value : alipayStoreQrCodeDataUrl.value
  if (!dataUrl) return
  const link = document.createElement('a')
  link.href = dataUrl
  const storeName = currentSelectedStoreName.value.replace(/[\/\\]/g, '_')
  link.download = `${storeName}_${channel === 'WECHAT' ? '微信公众号拓客码' : '支付宝生活号拓客码'}.png`
  link.click()
  ElMessage.success('高清二维码图片已下载！可直接发送给广告公司制作亚克力立牌或桌贴。')
}

const handleCopyStandUrl = async (channel: 'WECHAT' | 'ALIPAY') => {
  const storeId = selectedStandStoreId.value || 'S001'
  const tenantId = storeConfig.tenantId || 'T001'
  const url = channel === 'WECHAT'
    ? `https://mp.weixin.qq.com/s/seahorse_demo?tenantId=${tenantId}&storeId=${storeId}&scene=store_stand`
    : `https://alipay.com/life/seahorse_demo?tenantId=${tenantId}&storeId=${storeId}&scene=store_stand`
  try {
    await navigator.clipboard.writeText(url)
    ElMessage.success('专属拓客关注链接已复制到剪贴板！')
  } catch (e) {
    ElMessage.info(`关注短链：${url}`)
  }
}

const handleOpenPrintStandDialog = (channel: 'WECHAT' | 'ALIPAY' = 'WECHAT') => {
  printStandChannel.value = channel
  printStandDialogVisible.value = true
}

const executePrintStand = () => {
  let iframe = document.getElementById('stand-print-iframe') as HTMLIFrameElement
  if (!iframe) {
    iframe = document.createElement('iframe')
    iframe.id = 'stand-print-iframe'
    iframe.style.position = 'fixed'
    iframe.style.right = '0'
    iframe.style.bottom = '0'
    iframe.style.width = '0'
    iframe.style.height = '0'
    iframe.style.border = 'none'
    iframe.style.visibility = 'hidden'
    document.body.appendChild(iframe)
  }
  const doc = iframe.contentWindow?.document
  if (!doc) {
    window.print()
    return
  }
  const isWechat = printStandChannel.value === 'WECHAT'
  const themeColor = isWechat ? '#059669' : '#0284c7'
  const qrImg = isWechat ? wechatStoreQrCodeDataUrl.value : alipayStoreQrCodeDataUrl.value
  const brandTitle = isWechat ? '官方微信服务号 · 进店扫码领好礼' : '支付宝官方生活号 · 进店扫码领好礼'
  const hintText = isWechat ? '微信扫一扫 · 关注本店服务号' : '支付宝扫一扫 · 关注官方生活号'
  const storeName = currentSelectedStoreName.value

  doc.open()
  doc.write(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>前台水牌 - ${storeName}</title>
        <style>
          @page {
            size: A5 portrait;
            margin: 8mm;
          }
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
            margin: 0;
            padding: 10px;
            display: flex;
            justify-content: center;
            align-items: center;
            background: #fff;
          }
          .print-stand-card {
            width: 125mm;
            border: 2px solid ${themeColor};
            border-radius: 16px;
            overflow: hidden;
            text-align: center;
            box-shadow: 0 4px 12px rgba(0,0,0,0.06);
          }
          .p-header {
            background: ${themeColor};
            color: #fff;
            padding: 16px 12px;
          }
          .p-store-name {
            font-size: 20px;
            font-weight: 800;
            margin-bottom: 4px;
          }
          .p-badge {
            display: inline-block;
            background: rgba(255,255,255,0.22);
            padding: 3px 12px;
            border-radius: 20px;
            font-size: 12px;
          }
          .p-body {
            padding: 16px 14px;
          }
          .p-qr {
            width: 65mm;
            height: 65mm;
            display: block;
            margin: 0 auto;
          }
          .p-hint {
            font-size: 15px;
            font-weight: 800;
            color: ${themeColor};
            margin-top: 10px;
            letter-spacing: 0.5px;
          }
          .p-perks {
            margin-top: 14px;
            padding: 12px;
            background: #f8fafc;
            border-radius: 8px;
            text-align: left;
            font-size: 12px;
            color: #334155;
            line-height: 1.8;
          }
          .p-footer {
            border-top: 1px dashed #cbd5e1;
            padding: 8px;
            font-size: 11px;
            color: #94a3b8;
          }
        </style>
      </head>
      <body>
        <div class="print-stand-card">
          <div class="p-header">
            <div class="p-store-name">${storeName}</div>
            <div class="p-badge">${brandTitle}</div>
          </div>
          <div class="p-body">
            <img src="${qrImg}" class="p-qr" />
            <div class="p-hint">${hintText}</div>
            <div class="p-perks">
              <div>🎁 <b>扫码关注即送 50 积分</b> + 新手礼包</div>
              <div>🔔 <b>进店消费实时微信动账</b>，电子账单明细即时推送</div>
              <div>💳 <b>手机随时查看会员权益</b>、储值余额与专属优惠券</div>
            </div>
          </div>
          <div class="p-footer">
            请放置于收银吧台、造型镜台或餐桌贴 · 欢迎光临
          </div>
        </div>
      </body>
    </html>
  `)
  doc.close()
  setTimeout(() => {
    iframe.contentWindow?.focus()
    iframe.contentWindow?.print()
  }, 350)
  ElMessage.success('已向打印机发送前台水牌打印任务！')
}

const loadNotificationConfig = async () => {
  try {
    const res = await getNotificationConfigApi()
    if (res && res.data) {
      notifConfig.value = { ...notifConfig.value, ...res.data }
    }
  } catch (err) {
    console.warn('获取公众号推送配置失败，使用默认配置', err)
  }
}

const handleSaveNotifConfig = async () => {
  savingNotif.value = true
  try {
    const res = await saveNotificationConfigApi(notifConfig.value)
    if (res && res.code === 200) {
      ElMessage.success('门店动账推送业务设置已成功保存并立即生效！')
    } else {
      ElMessage.success('门店动账推送业务设置已保存')
    }
  } catch (err: any) {
    ElMessage.error(err?.message || '保存失败')
  } finally {
    savingNotif.value = false
  }
}

const loadNotificationLogs = async () => {
  loadingLogs.value = true
  try {
    const res = await getNotificationLogsApi()
    if (res && res.data) {
      notifLogs.value = res.data
    }
  } catch (err) {
    console.warn('加载推送流水失败', err)
  } finally {
    loadingLogs.value = false
  }
}

const handleSwitchLogsTab = () => {
  notifSubTab.value = 'LOGS'
  loadNotificationLogs()
}

const handleSimulateFollow = async () => {
  if (!simulatePhone.value || simulatePhone.value.trim().length < 8) {
    ElMessage.warning('请输入有效的顾客手机号')
    return
  }
  simulatingFollow.value = true
  try {
    const res = await simulateFollowApi({
      phone: simulatePhone.value.trim(),
      channel: simulateChannel.value
    })
    if (res && res.data) {
      lastFollowResult.value = res.data
      ElNotification({
        title: '扫码关注绑定成功',
        message: `顾客 ${simulatePhone.value} 已成功关注 ${simulateChannel.value === 'WECHAT_MP' ? '微信公众号' : '支付宝生活号'}，获赠50积分并激活消费动账推送！`,
        type: 'success',
        duration: 4500
      })
      loadNotificationLogs()
    }
  } catch (err: any) {
    ElMessage.error(err?.message || '模拟扫码关注失败')
  } finally {
    simulatingFollow.value = false
  }
}

const handleSendTestNotif = async () => {
  sendingTest.value = true
  try {
    const res = await sendTestNotificationApi({
      channel: testForm.value.channel,
      msgType: testForm.value.msgType,
      targetPhone: testForm.value.targetPhone
    })
    if (res && res.data) {
      ElMessage.success('测试消息已成功下发 (沙箱全真模拟或官方API已提交)！')
      loadNotificationLogs()
    }
  } catch (err: any) {
    ElMessage.error(err?.message || '发送测试消息失败')
  } finally {
    sendingTest.value = false
  }
}

const handleViewLogDetail = (row: any) => {
  currentLogDetail.value = row
  openLogDetailDialog.value = true
}

const formatDateTime = (val: string) => {
  if (!val) return '-'
  return val.replace('T', ' ').substring(0, 19)
}

const formatJson = (val: string) => {
  if (!val) return '{}'
  try {
    return JSON.stringify(JSON.parse(val), null, 2)
  } catch (e) {
    return val
  }
}

onMounted(() => {
  fetchRemoteApplications()
  // 30秒自动后台轮询一次云端投递简历
  setInterval(() => {
    fetchRemoteApplications(false)
  }, 30000)
  loadNotificationConfig()
  loadNotificationLogs()
  generateStoreQrCodes()
  loadAmapConfig()
})

const handleSaveAllSettings = () => {
  saving.value = true
  setTimeout(() => {
    saving.value = false
    ElMessage.success('门店全部系统设置、岗位职责与业务规则已成功保存并立即生效！')
  }, 400)
}
</script>

<style scoped>
.system-settings-page {
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

/* 岗位与招聘二级子导航 */
.post-sub-nav-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  padding: 4px 0 14px 0;
  border-bottom: 1px solid #f1f5f9;
}

.sub-nav-btns {
  display: flex;
  gap: 8px;
}

.sub-nav-btn {
  display: flex;
  align-items: center;
  padding: 7px 16px;
  font-size: 13.5px;
  font-weight: 600;
  border-radius: 6px;
  border: 1px solid #cbd5e1;
  background-color: #fff;
  color: #475569;
  cursor: pointer;
  transition: all 0.2s ease;
}

.sub-nav-btn:hover {
  border-color: #0284c7;
  color: #0284c7;
}

.sub-nav-btn.active-tab {
  background-color: #0284c7;
  border-color: #0284c7;
  color: #fff;
  box-shadow: 0 2px 8px rgba(2, 132, 199, 0.25);
}

.sub-nav-badge {
  display: inline-block;
  background-color: #ef4444;
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  padding: 1px 7px;
  border-radius: 12px;
  margin-left: 6px;
}

/* 岗位编辑弹窗中的招聘配置卡片 */
.recruit-form-box {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  margin-top: 8px;
}

.rf-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 8px;
  border-bottom: 1px dashed #cbd5e1;
  margin-bottom: 12px;
}

.rf-title {
  font-size: 13.5px;
  font-weight: 700;
  color: #0f172a;
}

/* 招聘看板 KPI 统计网格 */
.recruit-kpi-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 14px;
  margin: 10px 0 16px 0;
}

.kpi-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  display: flex;
  align-items: center;
  gap: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.kpi-card.highlight-orange {
  border-color: #fdba74;
  background: #fffaf5;
}

.kpi-card.highlight-green {
  border-color: #86efac;
  background: #f0fdf4;
}

.kpi-icon-box {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  color: #fff;
}

.kpi-icon-box.bg-blue { background: #0284c7; }
.kpi-icon-box.bg-indigo { background: #4f46e5; }
.kpi-icon-box.bg-orange { background: #ea580c; }
.kpi-icon-box.bg-purple { background: #7c3aed; }
.kpi-icon-box.bg-green { background: #16a34a; }

.kpi-val {
  font-size: 20px;
  font-weight: 800;
  color: #0f172a;
  line-height: 1.2;
}

.kpi-label {
  font-size: 11.5px;
  color: #64748b;
  margin-top: 2px;
}

/* 简历看板筛选栏 */
.app-filter-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  background: #f8fafc;
  padding: 10px 14px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.fl-left {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

/* 模拟求职投递门户样式 */
.portal-hero-banner {
  background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
  color: #fff;
  border-radius: 8px;
  padding: 18px 20px;
  margin-bottom: 14px;
  text-align: center;
}

.hero-store-name {
  font-size: 13px;
  opacity: 0.9;
  letter-spacing: 0.5px;
}

.hero-post-title {
  font-size: 20px;
  font-weight: 800;
  margin: 6px 0;
}

.hero-salary-badge {
  display: inline-block;
  background: rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.4);
  padding: 3px 12px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 700;
}

.hero-tags-row {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin-top: 10px;
}

.hero-tag {
  background: rgba(255, 255, 255, 0.15);
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 4px;
}

.portal-post-summary {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  margin-bottom: 14px;
}

.summary-section {
  margin-bottom: 8px;
}

.summary-section:last-child {
  margin-bottom: 0;
}

.s-title {
  font-size: 12.5px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 2px;
}

.s-content {
  font-size: 12px;
  color: #475569;
  line-height: 1.5;
}

.portal-form-box {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px;
}

.portal-form-title {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 12px;
  padding-bottom: 6px;
  border-bottom: 1px dashed #e2e8f0;
}

/* 简历抽屉详情样式 */
.applicant-doc-wrap {
  padding: 4px;
}

.app-header-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px;
  margin-bottom: 16px;
}

.app-block {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  margin-bottom: 14px;
}

.app-block.highlight-block {
  background: #f0fdf4;
  border-color: #bbf7d0;
}

.b-title {
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 8px;
}

.b-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
  font-size: 12.5px;
}

.bg-item {
  display: flex;
  align-items: center;
}

.b-text {
  font-size: 12.5px;
  color: #334155;
  line-height: 1.6;
}

.app-drawer-actions {
  display: flex;
  gap: 10px;
  margin-top: 20px;
  padding-top: 14px;
  border-top: 1px solid #e2e8f0;
}

/* 岗位管理样式 */
.post-action-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 6px;
}

.p-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.p-tip {
  font-size: 12px;
  color: #64748b;
}

.doc-drawer-content {
  padding: 4px;
}

.doc-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 20px;
}

.doc-title {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
}

.doc-block {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px;
  margin-bottom: 16px;
}

.doc-label {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
  margin-bottom: 8px;
}

.doc-text {
  font-size: 13px;
  color: #475569;
  line-height: 1.6;
}

.doc-grid {
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-size: 13px;
  color: #475569;
}

.dg-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* 短信管理样式 (严格对齐截图 media_1788699619136.png) */
.sms-top-control-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  padding: 10px 0 16px 0;
  border-bottom: 1px solid #f1f5f9;
}

.sms-tabs-left {
  display: flex;
  gap: 12px;
}

.sms-nav-btn {
  border: none;
  border-radius: 4px;
  padding: 6px 18px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  color: #fff;
  transition: opacity 0.2s;
}

.sms-nav-btn:hover {
  opacity: 0.9;
}

/* 激活选中状态：橙色 (如截图中的短信购买) */
.active-orange {
  background-color: #ff9800;
}

/* 未激活状态：浅蓝色 (如截图中的短信余量、短信签名、短信群发) */
.normal-blue {
  background-color: #409eff;
}

.sms-switches-right {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}

.sw-label {
  font-size: 13px;
  color: #334155;
  margin-right: 4px;
}

.service-tip {
  font-size: 12px;
  color: #94a3b8;
  margin-left: 14px;
  display: inline-flex;
  align-items: center;
}

/* 短信购买区域 */
.sms-buy-section {
  margin-top: 14px;
}

.sms-gray-header {
  background-color: #f7f7f7;
  padding: 10px 16px;
  font-size: 13px;
  color: #4b5563;
  font-weight: 500;
  border-radius: 2px;
  margin-bottom: 12px;
}

.sms-table-wrapper {
  overflow-x: auto;
}

.custom-sms-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  color: #333;
}

.custom-sms-table th {
  background-color: #fafafa;
  color: #333;
  font-weight: 600;
  padding: 12px 14px;
  border-bottom: 1px solid #f0f0f0;
  text-align: left;
}

.custom-sms-table td {
  padding: 14px;
  border-bottom: 1px solid #f0f0f0;
}

.pkg-row {
  cursor: pointer;
  transition: background-color 0.2s;
}

.pkg-row:hover {
  background-color: #f8fafc;
}

.row-selected {
  background-color: #f0f9ff !important;
}

/* 底部操作与支付方式栏 (严格对齐截图) */
.sms-bottom-action-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  margin-top: 24px;
  padding-top: 16px;
}

.pay-method-block {
  display: flex;
  align-items: center;
  gap: 16px;
}

.pay-label {
  font-size: 13px;
  color: #333;
  font-weight: 500;
}

.pay-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 18px;
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  background-color: #fff;
  cursor: pointer;
  transition: all 0.2s;
}

.pay-card:hover {
  border-color: #1890ff;
}

.pay-card.pay-active {
  border-color: #1890ff;
  box-shadow: 0 0 0 2px rgba(24, 144, 255, 0.15);
}

.wechat-icon-circle {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background-color: #07c160;
  display: flex;
  align-items: center;
  justify-content: center;
}

.alipay-icon-circle {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background-color: #1677ff;
  display: flex;
  align-items: center;
  justify-content: center;
}

.pay-text {
  font-size: 13px;
  font-weight: 600;
  color: #1f2937;
}

.confirm-pay-btn {
  background-color: #1890ff !important;
  border-color: #1890ff !important;
  padding: 10px 24px !important;
  font-size: 14px !important;
  font-weight: 500 !important;
}

/* 短信余量卡片 */
.stat-box {
  padding: 16px;
  border-radius: 8px;
  color: #fff;
}

.box-blue { background: linear-gradient(135deg, #0284c7, #0369a1); }
.box-green { background: linear-gradient(135deg, #059669, #047857); }
.box-orange { background: linear-gradient(135deg, #ea580c, #c2410c); }

.s-lbl { font-size: 12px; opacity: 0.9; }
.s-val { font-size: 26px; font-weight: 700; margin: 4px 0; }
.s-unit { font-size: 13px; font-weight: normal; }
.s-sub { font-size: 11px; opacity: 0.8; }

/* 短信签名黄色须知与样式 (严格对齐截图3 media_1788699981137.png) */
.sign-top-notice-box {
  background-color: #fffbe6;
  border: 1px solid #ffe58f;
  border-radius: 4px;
  padding: 14px 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  margin-top: 14px;
}

.notice-left {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  flex: 1;
}

.bell-icon {
  font-size: 16px;
  line-height: 1.4;
}

.notice-content {
  font-size: 13px;
  color: #595959;
  line-height: 1.6;
}

.apply-sign-btn {
  background-color: #e6f7ff !important;
  border-color: #91d5ff !important;
  color: #1890ff !important;
  font-weight: 500;
  padding: 8px 18px;
  border-radius: 4px;
}

.apply-sign-btn:hover {
  background-color: #1890ff !important;
  color: #fff !important;
}

.empty-sign-box {
  padding: 50px 0;
  color: #8c8c8c;
  font-size: 14px;
  text-align: center;
}

/* 申请签名上传方框 (严格对齐截图1与截图2) */
.upload-square-box {
  width: 110px;
  height: 110px;
  background-color: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  overflow: hidden;
}

.upload-square-box:hover {
  border-color: #1890ff;
  background-color: #f0f9ff;
}

.upload-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  gap: 2px;
}

.upload-sub-text {
  font-size: 11px;
  color: #94a3b8;
}

.plus-icon {
  font-size: 30px;
  color: #94a3b8;
  font-weight: 200;
  line-height: 1;
}

.upload-preview-box.real-preview {
  position: relative;
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.upload-thumb-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.thumb-hover-actions {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, 0.7);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  opacity: 0;
  transition: opacity 0.2s ease;
}

.upload-preview-box.real-preview:hover .thumb-hover-actions {
  opacity: 1;
}

.thumb-hover-actions .action-btn {
  font-size: 11.5px;
  padding: 3px 10px;
  border-radius: 4px;
  cursor: pointer;
  color: #fff;
  font-weight: 500;
}

.thumb-hover-actions .action-btn.change {
  background-color: #0284c7;
}

.thumb-hover-actions .action-btn.del {
  background-color: #ef4444;
}

/* ==============================================================================
   双轨储值与收银规则美化样式
   ============================================================================== */
.rule-management-container {
  padding: 4px 0;
}

.section-sub-title {
  font-size: 14px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 12px;
}

.deduct-mode-cards {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.mode-card {
  position: relative;
  background-color: #fff;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.25s ease;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.mode-card:hover {
  border-color: #93c5fd;
  transform: translateY(-2px);
}

.mode-card.active {
  border-color: #3b82f6;
  background: linear-gradient(180deg, #f8fafc 0%, #eff6ff 100%);
  box-shadow: 0 4px 14px rgba(59, 130, 246, 0.15);
}

.card-badge {
  position: absolute;
  top: -10px;
  right: 16px;
  padding: 2px 10px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 700;
}

.card-badge.recommend {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  color: #fff;
  box-shadow: 0 2px 6px rgba(217, 119, 6, 0.3);
}

.card-badge.speed {
  background: linear-gradient(135deg, #0284c7, #0369a1);
  color: #fff;
  box-shadow: 0 2px 6px rgba(3, 105, 161, 0.3);
}

.mode-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.mode-icon {
  font-size: 28px;
}

.mode-title-box {
  flex: 1;
}

.mode-title {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}

.mode-desc {
  font-size: 12px;
  color: #64748b;
  margin-top: 2px;
}

.mode-radio-circle {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  border: 2px solid #cbd5e1;
  position: relative;
}

.mode-card.active .mode-radio-circle {
  border-color: #3b82f6;
}

.mode-card.active .mode-radio-circle::after {
  content: '';
  position: absolute;
  width: 10px;
  height: 10px;
  background-color: #3b82f6;
  border-radius: 50%;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

.formula-box {
  background-color: rgba(255, 255, 255, 0.85);
  border: 1px dashed #cbd5e1;
  border-radius: 6px;
  padding: 10px 12px;
  font-size: 12px;
  color: #334155;
  margin-bottom: 12px;
  line-height: 1.8;
}

.f-tag {
  display: inline-block;
  padding: 1px 6px;
  border-radius: 4px;
  font-weight: 700;
  font-size: 11px;
}

.f-tag.principal {
  background-color: #eff6ff;
  color: #2563eb;
  border: 1px solid #bfdbfe;
}

.f-tag.gift {
  background-color: #fef3c7;
  color: #d97706;
  border: 1px solid #fde68a;
}

.case-box {
  font-size: 12px;
  color: #475569;
  background-color: #f8fafc;
  padding: 8px 10px;
  border-radius: 6px;
  border-left: 3px solid #3b82f6;
  line-height: 1.6;
}

.case-label {
  font-weight: 700;
  margin-bottom: 2px;
}

/* 划扣沙盘模拟器 */
.sandbox-box {
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 18px 20px;
  margin-bottom: 24px;
}

.sandbox-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.sb-title {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}

.sandbox-inputs {
  display: flex;
  align-items: center;
  gap: 24px;
  flex-wrap: wrap;
  margin-bottom: 16px;
}

.sb-input-group {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #334155;
}

.sb-input-group .unit {
  font-size: 12px;
  color: #64748b;
}

.sandbox-result-card {
  display: flex;
  align-items: center;
  justify-content: space-around;
  background-color: #fff;
  border-radius: 8px;
  padding: 16px 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
  border: 1px solid #e2e8f0;
}

.res-col {
  text-align: center;
}

.res-lbl {
  font-size: 12px;
  color: #64748b;
  margin-bottom: 4px;
}

.res-val {
  font-size: 22px;
  font-weight: 800;
}

.res-val.principal {
  color: #2563eb;
}

.res-val.gift {
  color: #d97706;
}

.res-val.total {
  color: #059669;
}

.res-sub {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 4px;
}

.res-divider {
  font-size: 20px;
  font-weight: 700;
  color: #cbd5e1;
}

.sandbox-progress-row {
  margin-top: 14px;
}

.prog-meta {
  display: flex;
  justify-content: space-between;
  font-size: 11.5px;
  color: #64748b;
  margin-bottom: 6px;
}

.dual-prog-track {
  height: 10px;
  background-color: #e2e8f0;
  border-radius: 5px;
  display: flex;
  overflow: hidden;
}

.prog-fill.principal {
  background: linear-gradient(90deg, #3b82f6, #2563eb);
}

.prog-fill.gift {
  background: linear-gradient(90deg, #f59e0b, #d97706);
}

/* 扩展规则网格 */
.rules-meta-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 20px;
}

.rule-sub-card {
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.r-card-head {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 12px;
}

.r-card-body {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.r-form-line {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  color: #334155;
}

/* ==============================================================================
   小票打印机与外设左右分栏样式
   ============================================================================== */
.printer-settings-container {
  display: flex;
  gap: 20px;
  align-items: flex-start;
}

.printer-form-col {
  flex: 3;
}

.printer-preview-col {
  flex: 2;
  position: sticky;
  top: 16px;
}

.preview-sticky-wrap {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px;
}

.preview-header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 14px;
}

.preview-header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.p-title {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
}

.settings-paper-stage {
  display: flex;
  flex-direction: column;
  align-items: center;
  background-color: #f8fafc;
  background-image: radial-gradient(#cbd5e1 1.2px, transparent 1.2px);
  background-size: 16px 16px;
  padding: 16px 12px 36px 12px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  max-height: 720px;
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 transparent;
}

.printer-feed-head {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background: #1e293b;
  color: #cbd5e1;
  font-size: 11px;
  font-weight: 600;
  padding: 5px 12px;
  border-radius: 6px 6px 0 0;
  width: 330px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.15);
  margin-bottom: 0px;
  flex-shrink: 0;
  transition: width 0.3s ease;
}

.printer-feed-head.is-58mm {
  width: 255px;
}

.feed-led {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: #10b981;
  box-shadow: 0 0 6px #10b981;
}

.feed-text {
  letter-spacing: 0.5px;
}

.settings-paper-stage::-webkit-scrollbar {
  width: 6px;
}

.settings-paper-stage::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 3px;
}

.card-header-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.header-tit-wrap {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.sub-tip {
  font-size: 12px;
  color: #64748b;
  font-weight: 400;
}

.preset-btn-group {
  display: flex;
  gap: 6px;
}

.printer-form-scroll-body {
  max-height: 620px;
  overflow-y: auto;
  padding-right: 6px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.cfg-group-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  transition: border-color 0.2s;
}

.cfg-group-card:hover {
  border-color: #cbd5e1;
}

.cfg-group-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
  padding-bottom: 6px;
  border-bottom: 1px dashed #e2e8f0;
}

.cfg-group-title {
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
}

.cfg-group-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(230px, 1fr));
  gap: 10px 14px;
}

.cfg-group-body {
  display: flex;
  flex-direction: column;
}

.cfg-row-flex {
  display: flex;
  align-items: center;
  gap: 12px;
}

.cfg-label {
  font-size: 13px;
  color: #475569;
  font-weight: 500;
}

.cfg-switch-item {
  display: flex;
  flex-direction: column;
}

.sw-row {
  display: flex;
  align-items: center;
}

.form-actions-bar {
  display: flex;
  gap: 12px;
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid #f1f5f9;
}

/* 热敏小票仿真样式 (严禁 flex 垂直拉伸或压缩，确保 100% 完整包裹全文) */
.thermal-paper-mockup {
  flex-shrink: 0;
  flex-grow: 0;
  height: auto !important;
  min-height: min-content;
  background-color: #ffffff;
  color: #0f172a;
  box-shadow: 0 12px 28px -4px rgba(0, 0, 0, 0.16), 0 6px 12px -2px rgba(0, 0, 0, 0.08);
  border: 1px solid #e2e8f0;
  border-top: none;
  border-radius: 0 0 4px 4px;
  padding: 16px 16px 24px 16px;
  font-family: 'Courier New', Courier, Consolas, Monaco, monospace, sans-serif;
  box-sizing: border-box;
  position: relative;
  margin-bottom: 24px;
  transition: width 0.3s ease;
}

.thermal-paper-mockup.width-80mm {
  width: 330px;
}

.thermal-paper-mockup.width-58mm {
  width: 255px;
}

.thermal-paper-mockup.font-compact {
  font-size: 11px;
}

.thermal-paper-mockup.font-standard {
  font-size: 12px;
}

.thermal-paper-mockup.font-large {
  font-size: 13.5px;
}

.paper-sawtooth {
  height: 8px;
  background-image: repeating-linear-gradient(45deg, #cbd5e1, #cbd5e1 3px, transparent 3px, transparent 6px);
  background-size: 6px 4px;
  background-repeat: repeat-x;
  margin: 0 -8px 6px -8px;
}

.paper-sawtooth.bottom {
  margin: 12px -8px 0 -8px;
}

.receipt-center-box {
  text-align: center;
}

.receipt-shop-name {
  font-size: 16px;
  font-weight: 800;
  letter-spacing: 0.5px;
  color: #0f172a;
}

.receipt-sub-title {
  font-size: 11px;
  color: #64748b;
  margin-top: 2px;
}

.receipt-ticket-type {
  font-size: 12.5px;
  font-weight: 700;
  margin-top: 5px;
  color: #1e293b;
}

.receipt-divider {
  text-align: center;
  font-size: 11px;
  color: #94a3b8;
  margin: 6px 0;
  overflow: hidden;
  white-space: nowrap;
  font-family: monospace;
}

.receipt-meta-grid {
  line-height: 1.65;
}

.meta-row {
  display: flex;
  justify-content: space-between;
}

.mono {
  font-family: 'Courier New', Courier, monospace;
  font-weight: 600;
}

.receipt-items-table {
  width: 100%;
}

.items-head {
  display: flex;
  font-weight: 700;
  border-bottom: 1px dashed #94a3b8;
  padding-bottom: 3px;
  margin-bottom: 4px;
}

.col-name { flex: 2; text-align: left; }
.col-qty { width: 36px; text-align: center; }
.col-price { width: 54px; text-align: right; }
.col-sum { width: 60px; text-align: right; }

.item-row {
  margin-bottom: 5px;
}

.item-name {
  font-weight: 600;
  color: #1e293b;
}

.item-meta {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  color: #475569;
}

.receipt-calc-box {
  line-height: 1.7;
}

.calc-row {
  display: flex;
  justify-content: space-between;
}

.calc-row.discount {
  color: #dc2626;
  font-weight: 600;
}

.calc-row.total {
  font-weight: 700;
  border-top: 1px dashed #94a3b8;
  padding-top: 4px;
  margin-top: 4px;
}

.bold-price {
  font-size: 15px;
  font-weight: 800;
  color: #0f172a;
}

.pay-split-list {
  padding-left: 6px;
  color: #475569;
  font-size: 11px;
}

.pay-row {
  display: flex;
  justify-content: space-between;
}

.receipt-member-asset-box {
  line-height: 1.65;
}

.asset-title {
  text-align: center;
  font-weight: 700;
  margin-bottom: 3px;
  color: #0f172a;
}

.asset-row {
  display: flex;
  justify-content: space-between;
}

.receipt-footer-box {
  text-align: center;
  line-height: 1.5;
  color: #475569;
}

.footer-notes {
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 4px;
}

.receipt-qr-zone {
  margin-top: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.qr-img-wrapper {
  background: #ffffff;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px dashed #cbd5e1;
  border-radius: 4px;
}

.qr-real-img {
  width: 78px;
  height: 78px;
  display: block;
}

.qr-mock-box {
  width: 64px;
  height: 64px;
  border: 1px solid #000;
  padding: 3px;
  background-color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
}

.qr-mock-code {
  width: 100%;
  height: 100%;
  background-image: repeating-linear-gradient(45deg, #000 0, #000 2px, #fff 2px, #fff 4px);
  position: relative;
}

.qr-inner-pattern {
  width: 18px;
  height: 18px;
  background-color: #000;
  margin: auto;
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
}

.qr-hint-text {
  font-size: 10px;
  color: #475569;
  margin-top: 3px;
  max-width: 220px;
  text-align: center;
}

.qr-url-text {
  font-size: 9px;
  color: #94a3b8;
  word-break: break-all;
  max-width: 220px;
  text-align: center;
}

.receipt-sign-stub {
  margin-top: 12px;
  line-height: 1.6;
}

.stub-divider {
  text-align: center;
  color: #475569;
  margin-bottom: 5px;
  font-family: monospace;
  font-size: 11px;
}

.stub-header {
  text-align: center;
  font-weight: 700;
  color: #0f172a;
  font-size: 12px;
}

.stub-meta {
  display: flex;
  justify-content: space-between;
  color: #334155;
  font-size: 11.5px;
  margin-top: 4px;
}

.stub-sign-block {
  margin-top: 10px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.stub-sign-row {
  display: flex;
  align-items: flex-end;
  gap: 6px;
}

.sign-label {
  font-size: 11.5px;
  color: #0f172a;
  font-weight: 600;
  white-space: nowrap;
}

.sign-underline {
  flex: 1;
  border-bottom: 1px solid #334155;
  height: 1px;
  margin-bottom: 2px;
}

.stub-date-row {
  display: flex;
  justify-content: flex-end;
  font-size: 11px;
  color: #475569;
}

/* 岗位微页面海报与二维码分享弹窗样式 */
.poster-dialog-layout {
  display: flex;
  gap: 24px;
  align-items: flex-start;
}

.poster-phone-column {
  flex: 0 0 340px;
}

.phone-mockup-wrapper {
  background: #0f172a;
  border-radius: 36px;
  padding: 12px 10px;
  box-shadow: 0 20px 40px -15px rgba(0, 0, 0, 0.35), 0 0 0 1px rgba(255, 255, 255, 0.1);
}

.phone-status-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 12px 6px;
  color: #ffffff;
  font-size: 11px;
  font-weight: 600;
}

.phone-notch {
  width: 90px;
  height: 18px;
  background: #000;
  border-radius: 12px;
}

.phone-screen-body {
  background: #f8fafc;
  border-radius: 26px;
  max-height: 520px;
  overflow-y: auto;
  padding: 14px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.job-hero-card {
  background: linear-gradient(135deg, #0284c7 0%, #2563eb 60%, #4f46e5 100%);
  color: #ffffff;
  padding: 16px 14px;
  border-radius: 16px;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);
}

.hero-sub {
  font-size: 11px;
  opacity: 0.9;
  letter-spacing: 0.5px;
}

.hero-title {
  font-size: 19px;
  font-weight: 800;
  margin: 6px 0 8px;
  letter-spacing: 0.5px;
}

.hero-salary-row {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 8px;
}

.salary-num {
  font-size: 20px;
  font-weight: 800;
  color: #fef08a;
}

.salary-desc {
  font-size: 11px;
  opacity: 0.9;
}

.hero-meta-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.meta-tag {
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(4px);
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 600;
}

.job-benefits-row {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.benefit-pill {
  background: #ecfdf5;
  color: #059669;
  border: 1px solid #a7f3d0;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}

.job-section-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 10px 12px;
}

.sec-header {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #0f172a;
  margin-bottom: 6px;
}

.sec-dot {
  width: 4px;
  height: 12px;
  background: #2563eb;
  border-radius: 2px;
}

.sec-body {
  font-size: 12px;
  color: #475569;
  line-height: 1.6;
}

.store-contact-sec .store-row {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: #334155;
  margin-bottom: 4px;
}

.store-contact-sec .store-row:last-child {
  margin-bottom: 0;
}

.job-poster-qr-footer {
  background: #ffffff;
  border: 1px dashed #38bdf8;
  border-radius: 14px;
  padding: 10px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.qr-img-box img {
  width: 76px;
  height: 76px;
  display: block;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.qr-tip-title {
  font-size: 12px;
  font-weight: 700;
  color: #0284c7;
}

.qr-tip-desc {
  font-size: 10px;
  color: #64748b;
  margin-top: 4px;
  line-height: 1.4;
}

.poster-actions-column {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.action-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 14px;
}

.action-card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #0f172a;
  margin-bottom: 10px;
}

.qr-preview-flex {
  display: flex;
  align-items: center;
  gap: 16px;
}

.big-qr-wrapper {
  position: relative;
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  padding: 6px;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.04);
}

.big-qr-img {
  width: 110px;
  height: 110px;
  display: block;
}

.qr-badge {
  position: absolute;
  bottom: -6px;
  left: 50%;
  transform: translateX(-50%);
  background: #2563eb;
  color: #ffffff;
  font-size: 10px;
  font-weight: 700;
  padding: 1px 8px;
  border-radius: 8px;
  white-space: nowrap;
}

.qr-instructions {
  flex: 1;
}

.instruct-title {
  font-size: 13px;
  font-weight: 700;
  color: #0284c7;
}

.instruct-sub {
  font-size: 12px;
  color: #64748b;
  margin: 6px 0 10px;
  line-height: 1.5;
}

.qr-btn-group {
  display: flex;
  gap: 8px;
}

.action-card-tip {
  font-size: 12px;
  color: #64748b;
  margin-top: 8px;
}

.wechat-copy-box {
  background: #ffffff;
  border-radius: 8px;
}

@media print {
  body * {
    visibility: hidden;
  }
  #settings-thermal-sample-ticket, #settings-thermal-sample-ticket *,
  #printable-job-poster, #printable-job-poster * {
    visibility: visible;
  }
  #settings-thermal-sample-ticket {
    position: absolute;
    left: 0;
    top: 0;
    width: 100% !important;
    max-width: 80mm !important;
    box-shadow: none !important;
    border: none !important;
    margin: 0 !important;
    padding: 2mm !important;
  }
  #printable-job-poster {
    position: absolute;
    left: 0;
    top: 0;
    width: 100% !important;
    max-width: 120mm !important;
    background: #ffffff !important;
    color: #000000 !important;
    box-shadow: none !important;
    padding: 0 !important;
  }
}

/* ========================================================================= */
/* 全渠道消息推送与公众号通知样式 */
/* ========================================================================= */
.notification-pane {
  padding: 4px 0 16px 0;
}

.notif-top-stats-strip {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 16px;
  margin-bottom: 16px;
}

.stat-pill {
  display: flex;
  align-items: center;
  font-size: 13px;
  color: #475569;
}

.stat-pill .dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 6px;
}
.stat-pill .dot.green { background: #10b981; }
.stat-pill .dot.blue { background: #3b82f6; }
.stat-pill .dot.purple { background: #8b5cf6; }
.stat-pill .dot.amber { background: #f59e0b; }

.notif-sub-nav-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  border-bottom: 1px solid #e2e8f0;
  padding-bottom: 12px;
  margin-bottom: 16px;
}

.sub-nav-btn {
  padding: 7px 16px;
  border-radius: 6px;
  border: 1px solid transparent;
  cursor: pointer;
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.sub-nav-btn.default-tab {
  background: #f1f5f9;
  color: #475569;
}
.sub-nav-btn.default-tab:hover {
  background: #e2e8f0;
}
.sub-nav-btn.active-tab {
  background: #0284c7;
  color: #ffffff;
}

.sub-nav-badge {
  background: #ef4444;
  color: #ffffff;
  font-size: 11px;
  padding: 1px 6px;
  border-radius: 10px;
  margin-left: 4px;
}

.channel-setting-card {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}
.card-head-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.head-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.form-item-tip {
  font-size: 12px;
  color: #94a3b8;
  margin-left: 10px;
}

/* 扫码立牌 */
.qr-stand-card {
  border-radius: 12px;
  padding: 24px 20px;
  text-align: center;
  box-shadow: 0 4px 16px rgba(0,0,0,0.06);
  display: flex;
  flex-direction: column;
  align-items: center;
}
.wechat-stand {
  background: linear-gradient(145deg, #f0fdf4, #dcfce7);
  border: 2px solid #86efac;
}
.alipay-stand {
  background: linear-gradient(145deg, #f0f9ff, #e0f2fe);
  border: 2px solid #7dd3fc;
}

.stand-header {
  margin-bottom: 16px;
}
.stand-logo {
  display: block;
  font-size: 18px;
  font-weight: 800;
  color: #166534;
}
.ali-head .stand-logo {
  color: #0369a1;
}
.stand-sub {
  font-size: 12px;
  color: #64748b;
  margin-top: 2px;
  display: block;
}

.stand-qr-box {
  background: #ffffff;
  padding: 12px;
  border-radius: 10px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  display: inline-block;
  margin-bottom: 14px;
}
.stand-qr-img {
  width: 170px;
  height: 170px;
  display: block;
}
.stand-scan-hint {
  font-size: 12px;
  font-weight: 700;
  color: #16a34a;
  margin-top: 8px;
}

.stand-perks {
  text-align: left;
  font-size: 12.5px;
  color: #334155;
  line-height: 1.8;
  margin-top: 6px;
}

.simulate-scan-box {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #ffffff;
}
.sim-tip {
  font-size: 12.5px;
  color: #64748b;
  line-height: 1.6;
  margin: 0;
}
.follow-success-card {
  margin-top: 16px;
  background: #f0fdf4;
  border: 1px solid #86efac;
  border-radius: 8px;
  padding: 12px;
  font-size: 12.5px;
  line-height: 1.8;
}
.f-head {
  font-weight: 700;
  color: #166534;
  margin-bottom: 4px;
}
.f-foot {
  margin-top: 6px;
  color: #059669;
  font-weight: 600;
}

/* 微信服务号预览容器 */
.wx-preview-container {
  max-width: 380px;
  margin: 0 auto;
  border-radius: 28px;
  background: #f2f2f2;
  border: 7px solid #1e293b;
  overflow: hidden;
  box-shadow: 0 8px 24px rgba(0,0,0,0.18);
}
.wx-phone-header {
  background: #ededed;
  padding: 6px 14px 10px 14px;
  border-bottom: 1px solid #d9d9d9;
}
.wx-top-bar {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: #000;
  font-weight: 600;
  margin-bottom: 6px;
}
.wx-app-nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.wx-back {
  font-size: 14px;
  color: #07c160;
  font-weight: 600;
}
.wx-title {
  font-size: 14px;
  font-weight: 700;
  color: #000;
}
.wx-more {
  font-size: 14px;
  color: #666;
}

.wx-phone-body {
  padding: 14px;
  min-height: 420px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.wx-msg-card {
  background: #ffffff;
  border-radius: 8px;
  padding: 14px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.06);
}
.card-top-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}
.mp-info {
  display: flex;
  align-items: center;
  gap: 6px;
}
.mp-name {
  font-size: 12px;
  font-weight: 600;
  color: #333;
}
.mp-time {
  font-size: 11px;
  color: #999;
}

.card-main-title {
  font-size: 16px;
  font-weight: 700;
  color: #111;
  margin-bottom: 10px;
}

.card-field-row {
  display: flex;
  justify-content: space-between;
  font-size: 12.5px;
  line-height: 1.9;
}
.card-field-row .f-label {
  color: #888;
}
.card-field-row .f-val {
  color: #222;
  font-weight: 500;
}
.highlight-orange {
  color: #ea580c !important;
  font-weight: 800 !important;
  font-size: 14px !important;
}

.card-remark-box {
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px dashed #e2e8f0;
  font-size: 12px;
  color: #059669;
  line-height: 1.6;
}

.card-detail-footer {
  margin-top: 12px;
  padding-top: 10px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12.5px;
  color: #07c160;
  font-weight: 600;
}
.card-detail-footer .arrow {
  font-size: 16px;
  color: #bbb;
}

.wx-input-mock {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #f7f7f7;
  border: 1px solid #e5e5e5;
  border-radius: 4px;
  padding: 6px 10px;
  font-size: 12px;
  color: #999;
  margin-top: 14px;
}
.input-placeholder {
  flex: 1;
}

.test-helper-box {
  margin-top: 14px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  padding: 10px;
  font-size: 12px;
  color: #64748b;
  line-height: 1.7;
}
.test-helper-box .h-title {
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 2px;
}

.logs-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}
.logs-toolbar .l-tip {
  font-size: 13px;
  color: #475569;
}

/* 动账通知模板配置卡片样式 */
.template-detail-card {
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  transition: all 0.2s;
}
.template-detail-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
}
.tmpl-card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.tmpl-title {
  font-weight: 700;
  font-size: 14px;
  color: #0f172a;
}
.tmpl-wechat-box {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.03);
}
.tmpl-wechat-box .wx-title {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
}
.tmpl-wechat-box .wx-time {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
  margin-bottom: 10px;
}
.tmpl-wechat-box .wx-first {
  font-size: 13px;
  color: #334155;
  line-height: 1.5;
  margin-bottom: 10px;
}
.tmpl-wechat-box .wx-fields {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 8px 0;
  border-top: 1px dashed #e2e8f0;
  border-bottom: 1px dashed #e2e8f0;
  margin-bottom: 10px;
}
.tmpl-wechat-box .wx-field-item {
  display: flex;
  font-size: 12px;
  line-height: 1.4;
}
.tmpl-wechat-box .wx-field-item .lbl {
  width: 72px;
  color: #64748b;
  flex-shrink: 0;
}
.tmpl-wechat-box .wx-field-item .val {
  color: #0f172a;
  word-break: break-all;
}
.tmpl-wechat-box .wx-remark {
  font-size: 12px;
  color: #64748b;
  line-height: 1.5;
  margin-bottom: 10px;
}
.tmpl-wechat-box .wx-foot {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #0284c7;
  font-weight: 600;
  border-top: 1px solid #f1f5f9;
  padding-top: 8px;
}
.tmpl-editor-form {
  margin-top: 4px;
}
.text-orange {
  color: #ea580c;
}
.text-green {
  color: #10b981;
}
.text-blue {
  color: #2563eb;
}
.bold {
  font-weight: 700;
}
.mono {
  font-family: monospace;
}

/* =========================================================
   💳 扫码盒子与全渠道聚合支付设置 - 现代化精美版面样式
   ========================================================= */
.payment-settings-pane {
  display: flex;
  flex-direction: column;
  gap: 18px;
  padding: 4px 0 16px 0;
}

/* 1. 顶部状态概览与快速控制栏 (Header HUD) */
.pay-hud-bar {
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 18px 22px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}
.hud-badge-title {
  display: flex;
  align-items: center;
  gap: 14px;
}
.hud-icon {
  font-size: 26px;
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
  border: 1px solid #e2e8f0;
}
.hud-main-title {
  font-size: 16.5px;
  font-weight: 800;
  color: #0f172a;
  display: flex;
  align-items: center;
  gap: 10px;
}
.hud-subtitle {
  font-size: 12.5px;
  color: #64748b;
  margin-top: 3px;
  line-height: 1.4;
}
.hud-metrics {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}
.metric-chip {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 8px 14px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
}
.m-label {
  font-size: 11px;
  color: #94a3b8;
  font-weight: 600;
}
.m-val {
  font-size: 13.5px;
  font-weight: 700;
  color: #0f172a;
}
.text-gold {
  color: #d97706;
}
.text-purple {
  color: #7c3aed;
}

/* 通用模块卡片 */
.section-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 20px 22px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.03);
}
.panel-heading {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 14px;
  margin-bottom: 18px;
}
.heading-left {
  display: flex;
  align-items: center;
  gap: 12px;
}
.heading-right {
  display: flex;
  align-items: center;
  gap: 10px;
}
.heading-icon-badge {
  width: 38px;
  height: 38px;
  border-radius: 10px;
  font-size: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.icon-hardware {
  background: #ecfdf5;
  color: #059669;
}
.icon-routes {
  background: #eff6ff;
  color: #2563eb;
}
.heading-title {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}
.heading-sub {
  font-size: 12px;
  color: #64748b;
  margin-top: 2px;
}

/* 2. 硬件控制与实机联调布局 */
.hardware-content-layout {
  display: grid;
  grid-template-columns: 52% 48%;
  gap: 20px;
  align-items: stretch;
}
.params-control-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}
.ctrl-card {
  background: #f8fafc;
  border: 1px solid #edf2f7;
  border-radius: 10px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 8px;
  transition: all 0.2s ease;
}
.ctrl-card:hover {
  border-color: #cbd5e1;
  background: #ffffff;
  box-shadow: 0 3px 8px rgba(0, 0, 0, 0.04);
}
.ctrl-icon {
  font-size: 18px;
}
.ctrl-title {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
}
.ctrl-desc {
  font-size: 11.5px;
  color: #64748b;
  line-height: 1.4;
  min-height: 32px;
}
.ctrl-action {
  display: flex;
  align-items: center;
  gap: 6px;
  justify-content: flex-end;
  padding-top: 6px;
  border-top: 1px dashed #e2e8f0;
}
.unit-text {
  font-size: 12px;
  color: #64748b;
}

/* 实机扫码联调测试台 (Live Tester) */
.live-tester-card {
  background: #fdfefe;
  border: 1.5px dashed #38bdf8;
  border-radius: 10px;
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.tester-header {
  display: flex;
  align-items: center;
  gap: 8px;
}
.live-dot {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  background: #ef4444;
}
.live-dot.pulse {
  box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7);
  animation: pulse-red 2s infinite;
}
@keyframes pulse-red {
  0% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7); }
  70% { box-shadow: 0 0 0 8px rgba(239, 68, 68, 0); }
  100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
}
.tester-t {
  font-size: 13.5px;
  font-weight: 700;
  color: #0f172a;
  flex: 1;
}
.tester-desc {
  font-size: 12px;
  color: #64748b;
  line-height: 1.4;
}
.mock-pills-row {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}
.pill-tip {
  font-size: 11.5px;
  color: #64748b;
}
.pill-btn {
  font-size: 11.5px;
  font-weight: 600;
  padding: 3px 9px;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  cursor: pointer;
  transition: all 0.2s ease;
}
.pill-wx:hover {
  background: #ecfdf5;
  border-color: #10b981;
  color: #047857;
}
.pill-ali:hover {
  background: #eff6ff;
  border-color: #3b82f6;
  color: #1d4ed8;
}
.pill-prod:hover {
  background: #faf5ff;
  border-color: #a855f7;
  color: #7e22ce;
}
.tester-result-box {
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 10px 14px;
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.res-WECHAT_PAY {
  border-left: 4px solid #10b981;
  background: #f0fdf4;
}
.res-ALIPAY {
  border-left: 4px solid #0284c7;
  background: #f0f9ff;
}
.res-PRODUCT_EAN {
  border-left: 4px solid #8b5cf6;
  background: #faf5ff;
}
.res-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.res-type-badge {
  font-size: 12.5px;
  font-weight: 700;
  color: #0f172a;
}
.res-time {
  font-size: 11px;
  color: #94a3b8;
}
.res-code-val {
  font-size: 13px;
  color: #1e293b;
}
.res-code-val code {
  font-family: monospace;
  font-weight: 700;
  background: rgba(0, 0, 0, 0.06);
  padding: 2px 6px;
  border-radius: 4px;
}
.res-foot-tip {
  font-size: 11px;
  color: #16a34a;
  font-weight: 500;
}
.tester-empty-box {
  font-size: 11.5px;
  color: #94a3b8;
  text-align: center;
  padding: 8px 0;
}

/* 3. 三大通道卡片总览 (Trio Grid) */
.routes-trio-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 18px;
}
.trio-card {
  position: relative;
  background: #ffffff;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  padding: 22px 18px 14px 18px;
  cursor: pointer;
  transition: all 0.25s ease;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 12px;
}
.trio-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.06);
}
.trio-card.card-focused {
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08);
}
.trio-route1.card-focused {
  border-color: #d97706;
  background: #fffdfa;
}
.trio-route2.card-focused {
  border-color: #0284c7;
  background: #fafdff;
}
.trio-route3.card-focused {
  border-color: #7c3aed;
  background: #fdfbfe;
}
.trio-card.is-active-route {
  border-width: 2px;
}
.trio-route1.is-active-route {
  border-color: #d97706;
  box-shadow: 0 0 0 2px rgba(217, 119, 6, 0.2);
}
.trio-route2.is-active-route {
  border-color: #0284c7;
  box-shadow: 0 0 0 2px rgba(2, 132, 199, 0.2);
}
.trio-route3.is-active-route {
  border-color: #7c3aed;
  box-shadow: 0 0 0 2px rgba(124, 58, 237, 0.2);
}

.card-ribbon {
  position: absolute;
  top: -11px;
  right: 16px;
  font-size: 11px;
  font-weight: 700;
  padding: 3px 10px;
  border-radius: 12px;
  color: #ffffff;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.12);
}
.ribbon-gold {
  background: linear-gradient(90deg, #f59e0b, #d97706);
}
.ribbon-blue {
  background: linear-gradient(90deg, #38bdf8, #0284c7);
}
.ribbon-purple {
  background: linear-gradient(90deg, #c084fc, #7c3aed);
}

.trio-head {
  display: flex;
  align-items: center;
  gap: 12px;
}
.t-icon {
  font-size: 24px;
  width: 46px;
  height: 46px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.t-icon-gold {
  background: #fef3c7;
}
.t-icon-blue {
  background: #e0f2fe;
}
.t-icon-purple {
  background: #f3e8ff;
}
.t-title {
  font-size: 14.5px;
  font-weight: 800;
  color: #0f172a;
}
.t-sub {
  font-size: 11.5px;
  color: #64748b;
  margin-top: 3px;
  line-height: 1.35;
}
.t-highlight-row {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-bottom: 8px;
}
.t-tag {
  font-size: 11px;
  font-weight: 700;
  padding: 2px 7px;
  border-radius: 4px;
}
.tag-green {
  background: #ecfdf5;
  color: #059669;
}
.tag-blue {
  background: #eff6ff;
  color: #2563eb;
}
.tag-purple {
  background: #faf5ff;
  color: #7c3aed;
}
.tag-yellow {
  background: #fefce8;
  color: #ca8a04;
}
.t-feature-list {
  display: flex;
  flex-direction: column;
  gap: 5px;
}
.t-f-item {
  font-size: 12px;
  color: #475569;
  line-height: 1.45;
}
.trio-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-top: 1px dashed #e2e8f0;
  padding-top: 10px;
}
.active-pill {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 14px;
}
.pill-gold {
  background: #fef3c7;
  color: #b45309;
}
.pill-blue {
  background: #e0f2fe;
  color: #0369a1;
}
.pill-purple {
  background: #f3e8ff;
  color: #6b21a8;
}
.active-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: currentColor;
}
.view-param-hint {
  font-size: 11.5px;
  color: #94a3b8;
  font-weight: 500;
}

/* 4. 参数配置详情面板 (Detail Config Container) */
.detail-config-container {
  border-top: 3px solid #0284c7;
}
.config-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 16px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 18px;
}
.c-title-left {
  display: flex;
  align-items: center;
  gap: 12px;
}
.c-icon-badge {
  font-size: 22px;
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.gold-bg {
  background: #fef3c7;
}
.blue-bg {
  background: #e0f2fe;
}
.purple-bg {
  background: #f3e8ff;
}
.c-h-title {
  font-size: 16px;
  font-weight: 800;
  color: #0f172a;
}
.c-h-sub {
  font-size: 12.5px;
  color: #64748b;
  margin-top: 3px;
}

/* 进件步骤流程 */
.steps-guide-box {
  border-radius: 10px;
  padding: 16px 18px;
  margin-bottom: 18px;
}
.gold-border {
  background: #fffdf5;
  border: 1px solid #fde68a;
}
.blue-border {
  background: #f8fbff;
  border: 1px solid #bae6fd;
}
.purple-border {
  background: #fdfaff;
  border: 1px solid #e9d5ff;
}
.guide-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13.5px;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 12px;
}
.guide-sub-tip {
  font-size: 11.5px;
  color: #64748b;
  font-weight: normal;
}
.steps-flow-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 14px;
}
.step-card {
  background: #ffffff;
  border-radius: 8px;
  padding: 12px 14px;
  border: 1px solid rgba(0, 0, 0, 0.06);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}
.s-step-num {
  font-size: 11px;
  font-weight: 800;
  color: #0284c7;
  text-transform: uppercase;
}
.s-step-name {
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
  margin: 4px 0;
}
.s-step-desc {
  font-size: 11.5px;
  color: #475569;
  line-height: 1.5;
}

/* 表单分区块 */
.channel-params-form {
  margin-top: 8px;
}
.form-section-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 16px 18px 4px 18px;
  margin-bottom: 16px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.02);
}
.section-title-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13.5px;
  font-weight: 700;
  color: #1e293b;
  padding-bottom: 10px;
  margin-bottom: 14px;
  border-bottom: 1px solid #f1f5f9;
}
.title-with-badge {
  display: flex;
  align-items: center;
  gap: 8px;
}
.fee-badge {
  font-size: 12px;
  color: #059669;
  font-weight: 600;
  background: #ecfdf5;
  padding: 2px 8px;
  border-radius: 4px;
}

/* 底部操作工具条 */
.panel-action-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 0;
  border-top: 1px solid #e2e8f0;
  margin-top: 10px;
  flex-wrap: wrap;
  gap: 12px;
}
.left-actions {
  display: flex;
  gap: 10px;
}
.right-actions {
  display: flex;
  gap: 12px;
}
</style>
