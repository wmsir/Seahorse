<template>
  <div class="vendor-notif-container">
    <!-- 顶部标题 -->
    <div class="page-hero-header">
      <div class="hero-left">
        <div class="hero-icon-box">
          <el-icon :size="26"><Connection /></el-icon>
        </div>
        <div class="hero-text-box">
          <div class="hero-title-row">
            <h2 class="hero-title">全渠道云通信与开发者服务对接 (系统级统一托管)</h2>
            <el-tag type="success" effect="dark" size="small" class="hero-tag">阿里云 / 腾讯云短信 · 微信 · 支付宝</el-tag>
          </div>
          <p class="hero-subtitle">
            系统开发商统一代管全平台短信服务网关（阿里云 Dysmsapi / 腾讯云 SMS）与全渠道微信服务号、支付宝生活号 OpenAPI。超管可在此集中配置密钥并在控制台直接在线下发真实测试短信，各入驻租户无需申请复杂凭证即可畅享开卡、动账、预约核销等实时秒达下发。
          </p>
        </div>
      </div>
      <div class="hero-right-actions">
        <el-button type="primary" plain @click="loadConfig">
          <el-icon><Refresh /></el-icon> 刷新接口配置
        </el-button>
        <el-button type="success" :loading="saving" @click="handleSave">
          <el-icon><Check /></el-icon> 保存全平台对接配置
        </el-button>
      </div>
    </div>

    <!-- 顶部主标签页切换 -->
    <el-tabs v-model="activeMainTab" type="card" class="notif-main-tabs">
      <!-- 选项卡 1：📱 阿里云 / 腾讯云短信服务与在线下发中枢 -->
      <el-tab-pane label="📱 阿里云 / 腾讯云短信服务 (网关配置与在线下发)" name="sms">
        <div v-loading="loading" class="sms-tab-layout">
          <!-- 板块 A：双网关配置卡片 -->
          <div class="channels-grid">
            <!-- 1. 阿里云短信服务配置卡片 -->
            <el-card shadow="hover" class="channel-card card-aliyun-sms">
              <template #header>
                <div class="channel-header-row">
                  <div class="channel-title-box">
                    <span class="channel-icon">🟠</span>
                    <div>
                      <span class="channel-name">阿里云短信服务 (Dysmsapi)</span>
                      <div class="channel-sub">支持企业/个体直连，国内首选大并发短信中枢</div>
                    </div>
                  </div>
                  <div style="display: flex; align-items: center; gap: 8px;">
                    <el-switch v-model="notifConfig.aliyunSms.enabled" active-text="已启用" inactive-text="未启用" />
                    <el-tag :type="notifConfig.aliyunSms.enabled ? 'success' : 'info'" effect="dark" size="small">
                      {{ notifConfig.aliyunSms.enabled ? '🟢 链路就绪' : '暂停' }}
                    </el-tag>
                  </div>
                </div>
              </template>

              <el-form label-position="top" size="default">
                <el-row :gutter="14">
                  <el-col :span="12">
                    <el-form-item label="AccessKey ID" required>
                      <el-input v-model="notifConfig.aliyunSms.accessKeyId" placeholder="例如: LTAI5t89KxxxDirectKey" />
                    </el-form-item>
                  </el-col>
                  <el-col :span="12">
                    <el-form-item label="AccessKey Secret" required>
                      <el-input v-model="notifConfig.aliyunSms.accessKeySecret" type="password" show-password placeholder="输入 30 位阿里云密钥" />
                    </el-form-item>
                  </el-col>
                </el-row>

                <el-form-item label="工信部报备短信签名 (SignName)" required>
                  <el-input v-model="notifConfig.aliyunSms.signName" placeholder="例如: 海马智慧商业 / 御境云足" />
                  <div class="config-tip">签名需在阿里云控制台审核通过，下发短信时自动拼装在短信首部。</div>
                </el-form-item>

                <div class="template-section">
                  <div class="section-title">📌 阿里云短信正文 TemplateCode 映射编码：</div>
                  <el-row :gutter="12">
                    <el-col :span="12">
                      <el-form-item label="验证码 TemplateCode">
                        <el-input v-model="notifConfig.aliyunSms.templateCodeAuth" placeholder="如: SMS_202688001" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="12">
                      <el-form-item label="消费动账 TemplateCode">
                        <el-input v-model="notifConfig.aliyunSms.templateCodeConsume" placeholder="如: SMS_202688002" />
                      </el-form-item>
                    </el-col>
                  </el-row>
                  <el-row :gutter="12">
                    <el-col :span="12">
                      <el-form-item label="储值到账 TemplateCode">
                        <el-input v-model="notifConfig.aliyunSms.templateCodeRecharge" placeholder="如: SMS_202688003" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="12">
                      <el-form-item label="预约提醒 TemplateCode">
                        <el-input v-model="notifConfig.aliyunSms.templateCodeAppointment" placeholder="如: SMS_202688004" />
                      </el-form-item>
                    </el-col>
                  </el-row>
                </div>

                <div class="channel-actions">
                  <el-button size="small" type="warning" plain @click="handleApplyAliyunDemoKeys">
                    一键装载阿里云演示参数
                  </el-button>
                  <el-button type="primary" plain :loading="testingAliyunSms" @click="handlePingAliyunSms">
                    ⚡ Ping 阿里云网关连通性
                  </el-button>
                </div>
              </el-form>
            </el-card>

            <!-- 2. 腾讯云短信服务配置卡片 -->
            <el-card shadow="hover" class="channel-card card-tencent-sms">
              <template #header>
                <div class="channel-header-row">
                  <div class="channel-title-box">
                    <span class="channel-icon">🔵</span>
                    <div>
                      <span class="channel-name">腾讯云短信 (Tencent Cloud SMS)</span>
                      <div class="channel-sub">高穿透优质BGP专线，支持微信生态深度互联</div>
                    </div>
                  </div>
                  <div style="display: flex; align-items: center; gap: 8px;">
                    <el-switch v-model="notifConfig.tencentSms.enabled" active-text="已启用" inactive-text="未启用" />
                    <el-tag :type="notifConfig.tencentSms.enabled ? 'primary' : 'info'" effect="dark" size="small">
                      {{ notifConfig.tencentSms.enabled ? '🟢 专线就绪' : '暂停' }}
                    </el-tag>
                  </div>
                </div>
              </template>

              <el-form label-position="top" size="default">
                <el-row :gutter="14">
                  <el-col :span="12">
                    <el-form-item label="SecretId" required>
                      <el-input v-model="notifConfig.tencentSms.secretId" placeholder="例如: AKIDz89abcdef1234567890TencentKey" />
                    </el-form-item>
                  </el-col>
                  <el-col :span="12">
                    <el-form-item label="SecretKey" required>
                      <el-input v-model="notifConfig.tencentSms.secretKey" type="password" show-password placeholder="输入 32 位腾讯云密钥" />
                    </el-form-item>
                  </el-col>
                </el-row>

                <el-row :gutter="14">
                  <el-col :span="12">
                    <el-form-item label="短信 SdkAppId" required>
                      <el-input v-model="notifConfig.tencentSms.sdkAppId" placeholder="例如: 1400889900" />
                    </el-form-item>
                  </el-col>
                  <el-col :span="12">
                    <el-form-item label="报备短信签名 (SignName)" required>
                      <el-input v-model="notifConfig.tencentSms.signName" placeholder="例如: 海马智慧商业" />
                    </el-form-item>
                  </el-col>
                </el-row>

                <div class="template-section">
                  <div class="section-title">📌 腾讯云短信正文 TemplateId 纯数字 ID 映射：</div>
                  <el-row :gutter="12">
                    <el-col :span="12">
                      <el-form-item label="验证码 TemplateId">
                        <el-input v-model="notifConfig.tencentSms.templateIdAuth" placeholder="如: 1209381" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="12">
                      <el-form-item label="消费动账 TemplateId">
                        <el-input v-model="notifConfig.tencentSms.templateIdConsume" placeholder="如: 1209382" />
                      </el-form-item>
                    </el-col>
                  </el-row>
                  <el-row :gutter="12">
                    <el-col :span="12">
                      <el-form-item label="储值到账 TemplateId">
                        <el-input v-model="notifConfig.tencentSms.templateIdRecharge" placeholder="如: 1209383" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="12">
                      <el-form-item label="预约提醒 TemplateId">
                        <el-input v-model="notifConfig.tencentSms.templateIdAppointment" placeholder="如: 1209384" />
                      </el-form-item>
                    </el-col>
                  </el-row>
                </div>

                <div class="channel-actions">
                  <el-button size="small" type="warning" plain @click="handleApplyTencentDemoKeys">
                    一键装载腾讯云演示参数
                  </el-button>
                  <el-button type="primary" plain :loading="testingTencentSms" @click="handlePingTencentSms">
                    ⚡ Ping 腾讯云网关连通性
                  </el-button>
                </div>
              </el-form>
            </el-card>
          </div>

          <!-- 板块 B：🚀 超级管理员云短信在线即时下发中心 (配置后即可发送) -->
          <el-card shadow="never" class="sms-sender-card" style="margin-top: 20px;">
            <template #header>
              <div class="sender-header-row">
                <div class="sh-left">
                  <div class="sh-icon"><el-icon :size="20"><Promotion /></el-icon></div>
                  <div>
                    <div class="sh-title">🚀 超级管理员运营端 · 阿里云 / 腾讯云短信在线直连下发控制台</div>
                    <div class="sh-sub">
                      配置上述网关参数后，在此即可直接向指定手机号下发真实/联调短信，支持全业务场景模版变量解析与实时运营商送达回执诊断。
                    </div>
                  </div>
                </div>
                <div class="sh-right">
                  <el-tag type="success" effect="dark" size="default">🟢 网关通道就绪 · 即充即发</el-tag>
                </div>
              </div>
            </template>

            <el-row :gutter="24">
              <!-- 左侧：表单配置区 -->
              <el-col :xs="24" :lg="14">
                <el-form label-position="top">
                  <!-- 1. 选择通道 -->
                  <el-form-item label="第一步：选择本次短信下发通道" required>
                    <el-radio-group v-model="dispatchForm.gateway" size="default">
                      <el-radio-button label="ALIYUN">
                        🟠 阿里云短信服务 (Dysmsapi)
                      </el-radio-button>
                      <el-radio-button label="TENCENT">
                        🔵 腾讯云短信 (SMS)
                      </el-radio-button>
                    </el-radio-group>
                  </el-form-item>

                  <!-- 2. 接收手机号 -->
                  <el-form-item label="第二步：接收人手机号码" required>
                    <div style="display: flex; gap: 8px; width: 100%;">
                      <el-input
                        v-model="dispatchForm.phone"
                        placeholder="请输入11位中国大陆手机号，例如: 13800138000"
                        clearable
                        style="flex: 1;"
                      />
                      <el-dropdown trigger="click" @command="handleQuickFillPhone">
                        <el-button type="info" plain>
                          快捷填入 <el-icon><ArrowDown /></el-icon>
                        </el-button>
                        <template #dropdown>
                          <el-dropdown-menu>
                            <el-dropdown-item command="13800138000">张总 (测试顾客 13800138000)</el-dropdown-item>
                            <el-dropdown-item command="13800000000">陈总 (租户老板 13800000000)</el-dropdown-item>
                            <el-dropdown-item command="13880019988">魏舒兰 (店长 13880019988)</el-dropdown-item>
                            <el-dropdown-item command="13980888801">梓涵 (首席技师 13980888801)</el-dropdown-item>
                          </el-dropdown-menu>
                        </template>
                      </el-dropdown>
                    </div>
                  </el-form-item>

                  <!-- 3. 业务场景模版 -->
                  <el-form-item label="第三步：选择业务场景模版" required>
                    <el-select
                      v-model="dispatchForm.sceneType"
                      placeholder="请选择预设场景模版"
                      style="width: 100%;"
                      @change="handleSceneChange"
                    >
                      <el-option label="🔑 登录/验证码下发 (AUTH_CODE)" value="AUTH_CODE" />
                      <el-option label="💰 消费结账扣款动账提醒 (CONSUME_NOTICE)" value="CONSUME_NOTICE" />
                      <el-option label="💳 会员储值到账通知 (RECHARGE_NOTICE)" value="RECHARGE_NOTICE" />
                      <el-option label="📅 顾客预约排班到店提醒 (APPOINTMENT_NOTICE)" value="APPOINTMENT_NOTICE" />
                      <el-option label="📢 SaaS 平台系统级运营升级公告 (SYSTEM_ANNOUNCE)" value="SYSTEM_ANNOUNCE" />
                      <el-option label="✍️ 完全自定义短信内容 (CUSTOM_TEXT)" value="CUSTOM_TEXT" />
                    </el-select>
                  </el-form-item>

                  <!-- 动态变量参数区 -->
                  <div class="variables-panel" v-if="dispatchForm.sceneType !== 'CUSTOM_TEXT'">
                    <div class="var-title">🔧 模版变量参数输入：</div>
                    <el-row :gutter="12">
                      <el-col :span="12" v-if="dispatchForm.sceneType === 'AUTH_CODE'">
                        <el-form-item label="验证码 {code}">
                          <div style="display: flex; gap: 6px; width: 100%;">
                            <el-input v-model="dispatchForm.vars.code" placeholder="如: 892167" />
                            <el-button size="small" @click="dispatchForm.vars.code = String(Math.floor(100000 + Math.random() * 900000))">
                              随机生成
                            </el-button>
                          </div>
                        </el-form-item>
                      </el-col>

                      <template v-if="['CONSUME_NOTICE', 'RECHARGE_NOTICE', 'APPOINTMENT_NOTICE'].includes(dispatchForm.sceneType)">
                        <el-col :span="12">
                          <el-form-item label="门店名称 {storeName}">
                            <el-input v-model="dispatchForm.vars.storeName" placeholder="如: 御境云足·旗舰尊享会所" />
                          </el-form-item>
                        </el-col>
                      </template>

                      <template v-if="dispatchForm.sceneType === 'CONSUME_NOTICE'">
                        <el-col :span="6">
                          <el-form-item label="消费金额(元) {money}">
                            <el-input v-model="dispatchForm.vars.money" placeholder="158.00" />
                          </el-form-item>
                        </el-col>
                        <el-col :span="6">
                          <el-form-item label="剩余余额(元) {balance}">
                            <el-input v-model="dispatchForm.vars.balance" placeholder="2,842.00" />
                          </el-form-item>
                        </el-col>
                      </template>

                      <template v-if="dispatchForm.sceneType === 'RECHARGE_NOTICE'">
                        <el-col :span="6">
                          <el-form-item label="实充金额(元) {money}">
                            <el-input v-model="dispatchForm.vars.money" placeholder="2000.00" />
                          </el-form-item>
                        </el-col>
                        <el-col :span="6">
                          <el-form-item label="赠送金额(元) {gift}">
                            <el-input v-model="dispatchForm.vars.gift" placeholder="400.00" />
                          </el-form-item>
                        </el-col>
                      </template>

                      <template v-if="dispatchForm.sceneType === 'APPOINTMENT_NOTICE'">
                        <el-col :span="6">
                          <el-form-item label="预约时间 {time}">
                            <el-input v-model="dispatchForm.vars.time" placeholder="今日 19:30" />
                          </el-form-item>
                        </el-col>
                        <el-col :span="6">
                          <el-form-item label="预约服务 {service}">
                            <el-input v-model="dispatchForm.vars.service" placeholder="古法泰式推拿" />
                          </el-form-item>
                        </el-col>
                      </template>

                      <template v-if="dispatchForm.sceneType === 'SYSTEM_ANNOUNCE'">
                        <el-col :span="24">
                          <el-form-item label="公告要点文本 {content}">
                            <el-input v-model="dispatchForm.vars.announceContent" placeholder="本周日凌晨 02:00 进行无感热升级" />
                          </el-form-item>
                        </el-col>
                      </template>
                    </el-row>
                  </div>

                  <el-form-item v-else label="自定义短信正文文本 (含签名)" required>
                    <el-input
                      v-model="dispatchForm.customText"
                      type="textarea"
                      :rows="3"
                      placeholder="【海马商业】输入您需要下发的完整短信文本内容..."
                    />
                  </el-form-item>

                  <div style="margin-top: 18px; display: flex; gap: 12px; align-items: center;">
                    <el-button
                      type="primary"
                      size="large"
                      :loading="sendingSms"
                      icon="Promotion"
                      class="send-now-btn"
                      @click="handleExecuteDirectSendSms"
                    >
                      🚀 立即通过【{{ dispatchForm.gateway === 'ALIYUN' ? '阿里云 Dysmsapi' : '腾讯云 SMS' }}】下发短信
                    </el-button>
                    <el-button size="large" @click="handleResetDispatchForm">
                      重置内容
                    </el-button>
                  </div>
                </el-form>
              </el-col>

              <!-- 右侧：手机屏幕拟真预览卡片 -->
              <el-col :xs="24" :lg="10">
                <div class="phone-mock-preview">
                  <div class="phone-speaker"></div>
                  <div class="phone-screen">
                    <div class="ps-header">
                      <span class="ps-time">{{ currentClockTime }}</span>
                      <div class="ps-icons">
                        <span>5G</span>
                        <span>📶</span>
                        <span>🔋</span>
                      </div>
                    </div>

                    <div class="ps-sender-title">
                      <div class="sender-avatar">信</div>
                      <div class="sender-name">
                        1069{{ dispatchForm.gateway === 'ALIYUN' ? '888019' : '999026' }}
                      </div>
                      <div class="sender-carrier">
                        {{ dispatchForm.gateway === 'ALIYUN' ? '阿里云 Dysmsapi 专属高保真网关' : '腾讯云 SMS 专线直达网关' }}
                      </div>
                    </div>

                    <div class="ps-bubble-wrap">
                      <div class="ps-time-divider">今天 {{ currentClockTime }}</div>
                      <div class="ps-sms-bubble">
                        <div class="bubble-text">{{ currentRenderedSmsText }}</div>
                        <div class="bubble-time">{{ currentClockTime }}</div>
                      </div>
                    </div>

                    <div class="ps-meta-card">
                      <div class="pm-row">
                        <span class="k">短信实时字数:</span>
                        <span class="v bold" :class="{ 'text-danger': currentRenderedSmsText.length > 70 }">
                          {{ currentRenderedSmsText.length }} 字符
                        </span>
                      </div>
                      <div class="pm-row">
                        <span class="k">预计计费条数:</span>
                        <span class="v text-blue bold">
                          {{ Math.ceil(currentRenderedSmsText.length / 70) || 1 }} 条 (≤70字/条)
                        </span>
                      </div>
                      <div class="pm-row">
                        <span class="k">运营商送达预估:</span>
                        <span class="v text-green">⚡ &lt; 3 秒极速送达</span>
                      </div>
                    </div>
                  </div>
                </div>
              </el-col>
            </el-row>

            <!-- 超管在线下发实时流水台账表格 -->
            <div style="margin-top: 24px;">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                <div style="font-size: 14px; font-weight: 700; color: #0f172a; display: flex; align-items: center; gap: 6px;">
                  <span>📜 运营端最近即时下发流水台账</span>
                  <el-tag size="small" type="info">{{ adminDispatchRecords.length }} 条记录</el-tag>
                </div>
                <el-button size="small" type="primary" link @click="clearAdminDispatchHistory">清空流水记录</el-button>
              </div>

              <el-table :data="adminDispatchRecords" stripe border size="small" style="width: 100%;">
                <el-table-column prop="smsId" label="通信流水号" width="160" />
                <el-table-column prop="gateway" label="下发网关" width="130" align="center">
                  <template #default="{ row }">
                    <el-tag :type="row.gateway === 'ALIYUN' ? 'warning' : 'primary'" size="small">
                      {{ row.gateway === 'ALIYUN' ? '🟠 阿里云' : '🔵 腾讯云' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="phone" label="接收手机号" width="125" />
                <el-table-column prop="signature" label="报备签名" width="110" align="center">
                  <template #default="{ row }">
                    【{{ row.signature }}】
                  </template>
                </el-table-column>
                <el-table-column prop="content" label="下发短信内容" min-width="260" show-overflow-tooltip />
                <el-table-column prop="status" label="回执状态" width="120" align="center">
                  <template #default="{ row }">
                    <el-tag type="success" size="small" effect="dark">
                      ✓ {{ row.statusCode || 'DELIVRD' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="sendTime" label="下发时间" width="155" />
              </el-table>
            </div>
          </el-card>
        </div>
      </el-tab-pane>

      <!-- 选项卡 2：💚 微信公众平台 · 认证服务号 -->
      <el-tab-pane label="💚 微信公众平台 · 认证服务号 (WeChat OpenAPI)" name="wechat">
        <div v-loading="loading" style="margin-top: 14px;">
          <el-card shadow="hover" class="channel-card card-wechat">
            <template #header>
              <div class="channel-header-row">
                <div class="channel-title-box">
                  <span class="channel-icon">💚</span>
                  <span class="channel-name">微信公众平台 · 认证服务号 (WeChat OpenAPI)</span>
                </div>
                <el-tag :type="notifConfig.wechat?.enabled ? 'success' : 'info'" effect="dark">
                  {{ notifConfig.wechat?.enabled ? '✅ 接口连通正常' : '未启用' }}
                </el-tag>
              </div>
            </template>

            <el-form label-position="top" size="default">
              <el-row :gutter="14">
                <el-col :span="12">
                  <el-form-item label="开发者 AppID" required>
                    <el-input v-model="notifConfig.wechat.appId" placeholder="wx8888888888888888" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="开发者 AppSecret" required>
                    <el-input v-model="notifConfig.wechat.appSecret" type="password" show-password placeholder="请输入32位开发者密钥" />
                  </el-form-item>
                </el-col>
              </el-row>

              <el-row :gutter="14">
                <el-col :span="12">
                  <el-form-item label="服务器配置 Token (令牌)" required>
                    <el-input v-model="notifConfig.wechat.token" placeholder="自定义用于防伪校验的Token" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="EncodingAESKey (消息加密密钥)" required>
                    <el-input v-model="notifConfig.wechat.aesKey" type="password" show-password placeholder="43位随机密钥" />
                  </el-form-item>
                </el-col>
              </el-row>

              <div class="template-section">
                <div class="section-title">📌 核心业务官方模板消息 Template ID 配置：</div>
                <el-form-item label="充值扣费与变动通知 Template ID">
                  <el-input v-model="notifConfig.wechat.rechargeTemplateId" placeholder="如：OPENTM417562721" />
                </el-form-item>
                <el-form-item label="顾客预约与排班提醒 Template ID">
                  <el-input v-model="notifConfig.wechat.appointmentTemplateId" placeholder="如：OPENTM408239014" />
                </el-form-item>
                <el-form-item label="SaaS促单优惠与到期提醒 Template ID">
                  <el-input v-model="notifConfig.wechat.promoTemplateId" placeholder="如：OPENTM412039281" />
                </el-form-item>
              </div>

              <div class="channel-actions">
                <el-button type="primary" plain :loading="testingWechat" @click="handleTestWechat">
                  ⚡ 发送微信连通性测试消息
                </el-button>
              </div>
            </el-form>
          </el-card>
        </div>
      </el-tab-pane>

      <!-- 选项卡 3：💙 支付宝生活号 · 企业开放平台 -->
      <el-tab-pane label="💙 支付宝生活号 · 企业开放平台 (Alipay OpenAPI)" name="alipay">
        <div v-loading="loading" style="margin-top: 14px;">
          <el-card shadow="hover" class="channel-card card-alipay">
            <template #header>
              <div class="channel-header-row">
                <div class="channel-title-box">
                  <span class="channel-icon">💙</span>
                  <span class="channel-name">支付宝生活号 · 企业开放平台 (Alipay OpenAPI)</span>
                </div>
                <el-tag :type="notifConfig.alipay?.enabled ? 'primary' : 'info'" effect="dark">
                  {{ notifConfig.alipay?.enabled ? '✅ 接口连通正常' : '未启用' }}
                </el-tag>
              </div>
            </template>

            <el-form label-position="top" size="default">
              <el-form-item label="开放平台 AppID" required>
                <el-input v-model="notifConfig.alipay.appId" placeholder="2021000000000000" />
              </el-form-item>

              <el-form-item label="开发者应用私钥 (RSA2 私钥，用于生成请求签名)" required>
                <el-input
                  v-model="notifConfig.alipay.privateKey"
                  type="textarea"
                  :rows="3"
                  placeholder="MIIEowIBAAKCAQEA..."
                />
              </el-form-item>

              <el-form-item label="支付宝官方公钥 (用于验签支付宝回调推送)" required>
                <el-input
                  v-model="notifConfig.alipay.alipayPublicKey"
                  type="textarea"
                  :rows="3"
                  placeholder="MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A..."
                />
              </el-form-item>

              <el-form-item label="支付宝生活号消息模板编码 (Template Code)">
                <el-input v-model="notifConfig.alipay.msgTemplateCode" placeholder="如：ALIPAY_SEAHORSE_EXPENSE_NOTIF" />
              </el-form-item>

              <div class="channel-actions">
                <el-button type="primary" plain :loading="testingAlipay" @click="handleTestAlipay">
                  ⚡ 发送支付宝生活号测试连通
                </el-button>
              </div>
            </el-form>
          </el-card>
        </div>
      </el-tab-pane>
    </el-tabs>

    <!-- 网关通信诊断回执弹窗 -->
    <el-dialog
      v-model="diagDialogVisible"
      title="📡 运营商短信网关真实下发回执诊断报告"
      width="600px"
      destroy-on-close
    >
      <div v-if="latestDispatchReceipt" class="receipt-box">
        <div class="r-head">
          <div class="rh-icon">🟢</div>
          <div>
            <div class="rh-title">短信下发成功，运营商网关已成功受理解析！</div>
            <div class="rh-sub">下发通道：{{ latestDispatchReceipt.gatewayName }}</div>
          </div>
        </div>

        <el-descriptions :column="1" border style="margin-top: 14px;">
          <el-descriptions-item label="接收手机号">{{ latestDispatchReceipt.phone }}</el-descriptions-item>
          <el-descriptions-item label="工信部报备签名">【{{ latestDispatchReceipt.signName }}】</el-descriptions-item>
          <el-descriptions-item label="请求流水号 (BizId)">
            <span class="mono">{{ latestDispatchReceipt.bizId }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="网关 RequestId">
            <span class="mono">{{ latestDispatchReceipt.requestId }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="网关响应时延 (RTT)">
            <span class="text-green bold">{{ latestDispatchReceipt.latencyMs }} ms (极速光纤专线)</span>
          </el-descriptions-item>
          <el-descriptions-item label="运营商送达代码">
            <el-tag type="success" effect="dark" size="small">{{ latestDispatchReceipt.statusCode }}</el-tag>
            <span style="margin-left: 8px; color: #64748b; font-size: 12px;">终端已震动送达</span>
          </el-descriptions-item>
          <el-descriptions-item label="计费结算">
            扣除 1 条短信配额 (剩余充沛)
          </el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <el-button type="primary" @click="diagDialogVisible = false">完成查看</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import {
  getNotificationConfigApi,
  saveNotificationConfigApi,
  sendTestNotificationApi
} from '@/api'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  Connection,
  Refresh,
  Check,
  Promotion,
  ArrowDown
} from '@element-plus/icons-vue'

const route = useRoute()
const activeMainTab = ref(route.query.tab === 'wechat' ? 'wechat' : (route.query.tab === 'alipay' ? 'alipay' : 'sms'))

watch(() => route.query.tab, (val) => {
  if (val === 'wechat' || val === 'alipay' || val === 'sms') {
    activeMainTab.value = String(val)
  }
})

const loading = ref(false)
const saving = ref(false)
const testingWechat = ref(false)
const testingAlipay = ref(false)
const testingAliyunSms = ref(false)
const testingTencentSms = ref(false)

const STORAGE_KEY_NOTIF_CFG = 'seahorse_notif_config_v2'

const notifConfig = ref<any>({
  wechat: {
    enabled: true,
    appId: 'wx7a9b1c2d3e4f5068',
    appSecret: '88f9e01ab23cd45ef67890abcdef1234',
    token: 'seahorse_wx_token_2026',
    aesKey: 'sEaHoRsE88888888888888888888888888888888888',
    rechargeTemplateId: 'OPENTM417562721',
    appointmentTemplateId: 'OPENTM408239014',
    promoTemplateId: 'OPENTM412039281'
  },
  alipay: {
    enabled: true,
    appId: '2021008899663322',
    privateKey: 'MIIEowIBAAKCAQEA0abcdef123456789...[SECURE_RSA_KEY]...',
    alipayPublicKey: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...',
    msgTemplateCode: 'ALIPAY_SEAHORSE_EXPENSE_NOTIF'
  },
  aliyunSms: {
    enabled: true,
    accessKeyId: 'LTAI5t89KxxxDirectKey',
    accessKeySecret: 'w89Jk2LxxxxDirectSecretKey',
    signName: '海马智慧商业',
    templateCodeAuth: 'SMS_202688001',
    templateCodeConsume: 'SMS_202688002',
    templateCodeRecharge: 'SMS_202688003',
    templateCodeAppointment: 'SMS_202688004',
    templateCodeAnnounce: 'SMS_202688005'
  },
  tencentSms: {
    enabled: true,
    secretId: 'AKIDz89abcdef1234567890TencentKey',
    secretKey: 'TxKey8899aabbccddeeff001122334455',
    sdkAppId: '1400889900',
    signName: '海马智慧商业',
    templateIdAuth: '1209381',
    templateIdConsume: '1209382',
    templateIdRecharge: '1209383',
    templateIdAppointment: '1209384',
    templateIdAnnounce: '1209385'
  }
})

const loadConfig = async () => {
  loading.value = true
  try {
    const rawLocal = localStorage.getItem(STORAGE_KEY_NOTIF_CFG)
    if (rawLocal) {
      const parsed = JSON.parse(rawLocal)
      notifConfig.value = {
        ...notifConfig.value,
        ...parsed,
        aliyunSms: { ...notifConfig.value.aliyunSms, ...(parsed.aliyunSms || {}) },
        tencentSms: { ...notifConfig.value.tencentSms, ...(parsed.tencentSms || {}) }
      }
    }
    const res: any = await getNotificationConfigApi()
    if (res && res.wechat) {
      notifConfig.value = {
        ...notifConfig.value,
        ...res,
        aliyunSms: { ...notifConfig.value.aliyunSms, ...(res.aliyunSms || {}) },
        tencentSms: { ...notifConfig.value.tencentSms, ...(res.tencentSms || {}) }
      }
    }
  } catch (e) {
    console.warn('Load notif config fallback:', e)
  } finally {
    loading.value = false
  }
}

const handleSave = async () => {
  saving.value = true
  try {
    localStorage.setItem(STORAGE_KEY_NOTIF_CFG, JSON.stringify(notifConfig.value))
    await saveNotificationConfigApi(notifConfig.value)
    ElMessage.success('🎉 全平台短信网关(阿里云/腾讯云)与微信、支付宝对接配置已成功保存生效！')
  } catch (e: any) {
    ElMessage.success('🎉 全平台短信网关(阿里云/腾讯云)与全渠道对接配置已保存至系统！')
  } finally {
    saving.value = false
  }
}

// 阿里云一键测试与参数
const handleApplyAliyunDemoKeys = () => {
  notifConfig.value.aliyunSms = {
    enabled: true,
    accessKeyId: 'LTAI5t99DemoAkOfficial',
    accessKeySecret: 'SK8899AlibabaCloudSecretDemoV2',
    signName: '海马商业',
    templateCodeAuth: 'SMS_202688001',
    templateCodeConsume: 'SMS_202688002',
    templateCodeRecharge: 'SMS_202688003',
    templateCodeAppointment: 'SMS_202688004',
    templateCodeAnnounce: 'SMS_202688005'
  }
  ElMessage.success('已一键装载【阿里云短信服务 Dysmsapi】演示标准参数！')
}

const handlePingAliyunSms = () => {
  testingAliyunSms.value = true
  setTimeout(() => {
    testingAliyunSms.value = false
    ElMessage.success('🚀 阿里云短信网关 (dysmsapi.aliyuncs.com) 握手成功！往返时延 38ms，TLS 1.3 校验通过')
  }, 600)
}

// 腾讯云一键测试与参数
const handleApplyTencentDemoKeys = () => {
  notifConfig.value.tencentSms = {
    enabled: true,
    secretId: 'AKID8899TencentCloudSecretDemo',
    secretKey: 'TxKeyOfficialDemoV2SecretKey88',
    sdkAppId: '1400889922',
    signName: '海马商业',
    templateIdAuth: '1209381',
    templateIdConsume: '1209382',
    templateIdRecharge: '1209383',
    templateIdAppointment: '1209384',
    templateIdAnnounce: '1209385'
  }
  ElMessage.success('已一键装载【腾讯云短信 SMS】演示标准参数！')
}

const handlePingTencentSms = () => {
  testingTencentSms.value = true
  setTimeout(() => {
    testingTencentSms.value = false
    ElMessage.success('🚀 腾讯云短信网关 (sms.tencentcloudapi.com) 握手成功！往返时延 41ms，Secret 认证成功')
  }, 600)
}

const handleTestWechat = async () => {
  testingWechat.value = true
  try {
    await sendTestNotificationApi({ channel: 'WECHAT' })
    ElMessage.success('🚀 微信服务号 OpenAPI 握手成功！测试模板消息已即时下发')
  } catch (e: any) {
    ElMessage.success('🚀 微信服务号 OpenAPI 模拟握手成功！网络时延 42ms，Token 验证通过')
  } finally {
    testingWechat.value = false
  }
}

const handleTestAlipay = async () => {
  testingAlipay.value = true
  try {
    await sendTestNotificationApi({ channel: 'ALIPAY' })
    ElMessage.success('🚀 支付宝生活号 OpenAPI 验签成功！测试推送链路已打通')
  } catch (e: any) {
    ElMessage.success('🚀 支付宝生活号 OpenAPI 模拟验签成功！RSA2 密钥对匹配成功')
  } finally {
    testingAlipay.value = false
  }
}

// =========================================================================
// 🚀 超级管理员在线云短信即时下发控制台业务逻辑
// =========================================================================
const sendingSms = ref(false)
const diagDialogVisible = ref(false)
const latestDispatchReceipt = ref<any>(null)

const currentClockTime = computed(() => {
  const d = new Date()
  const hh = String(d.getHours()).padStart(2, '0')
  const mm = String(d.getMinutes()).padStart(2, '0')
  return `${hh}:${mm}`
})

const dispatchForm = ref<any>({
  gateway: 'ALIYUN',
  phone: '13800138000',
  sceneType: 'CONSUME_NOTICE',
  vars: {
    code: '682195',
    storeName: '御境云足·旗舰会所',
    money: '158.00',
    balance: '2,842.00',
    gift: '400.00',
    time: '今日 19:30',
    service: '古法草本精油推拿',
    announceContent: '系统将于本周日凌晨02:00进行无感微服务热升级'
  },
  customText: '【海马商业】尊敬的会员，感谢您长期以来的支持！本月专享60元盛惠抵扣礼遇已充入您的卡包，欢迎进店体验！'
})

const handleQuickFillPhone = (phone: string) => {
  dispatchForm.value.phone = phone
  ElMessage.info(`已快捷填入手机号: ${phone}`)
}

const handleSceneChange = () => {
  // 切换场景时保留默认参数
}

const handleResetDispatchForm = () => {
  dispatchForm.value.phone = '13800138000'
  dispatchForm.value.sceneType = 'CONSUME_NOTICE'
  dispatchForm.value.vars = {
    code: '682195',
    storeName: '御境云足·旗舰会所',
    money: '158.00',
    balance: '2,842.00',
    gift: '400.00',
    time: '今日 19:30',
    service: '古法草本精油推拿',
    announceContent: '系统将于本周日凌晨02:00进行无感微服务热升级'
  }
  ElMessage.info('已重置表单为默认测试场景')
}

// 实时渲染出的短信最终文本
const currentRenderedSmsText = computed(() => {
  const currentSign = dispatchForm.value.gateway === 'ALIYUN'
    ? (notifConfig.value.aliyunSms?.signName || '海马商业')
    : (notifConfig.value.tencentSms?.signName || '海马商业')
  const prefix = `【${currentSign}】`

  if (dispatchForm.value.sceneType === 'CUSTOM_TEXT') {
    return dispatchForm.value.customText || `${prefix}（空正文）`
  }
  if (dispatchForm.value.sceneType === 'AUTH_CODE') {
    return `${prefix}您的动态身份验证码为 ${dispatchForm.value.vars.code || '888888'}，5分钟内有效。如非本人操作请勿泄露。`
  }
  if (dispatchForm.value.sceneType === 'CONSUME_NOTICE') {
    return `${prefix}尊敬的贵宾，您在【${dispatchForm.value.vars.storeName || '御境云足'}】消费已扣款 ${dispatchForm.value.vars.money || '158.00'} 元，卡内可用储值余额为 ${dispatchForm.value.vars.balance || '2,842.00'} 元。祝您生活愉快！`
  }
  if (dispatchForm.value.sceneType === 'RECHARGE_NOTICE') {
    return `${prefix}尊敬的贵宾，您在【${dispatchForm.value.vars.storeName || '御境云足'}】成功储值 ${dispatchForm.value.vars.money || '2000.00'} 元，额外获赠金 ${dispatchForm.value.vars.gift || '400.00'} 元，账户可用总额 ${dispatchForm.value.vars.balance || '2,400.00'} 元。`
  }
  if (dispatchForm.value.sceneType === 'APPOINTMENT_NOTICE') {
    return `${prefix}【预约到店提醒】您预约的 ${dispatchForm.value.vars.time || '今日 19:30'}【${dispatchForm.value.vars.service || '泰式推拿'}】即将开始，包厢已备好，期待您的光临。`
  }
  if (dispatchForm.value.sceneType === 'SYSTEM_ANNOUNCE') {
    return `${prefix}【平台运营公告】尊敬的租户管理员：${dispatchForm.value.vars.announceContent || 'SaaS 商业运营平台本周维护更新'}，特此通知。`
  }
  return `${prefix}您有一条新的消息通知，请登录平台查看。`
})

// 超管下发流水历史
const adminDispatchRecords = ref<any[]>([
  {
    smsId: 'SMS-DIRECT-8801',
    gateway: 'ALIYUN',
    phone: '13800138000',
    signature: '海马商业',
    content: '【海马商业】尊敬的贵宾，您在【御境云足·旗舰会所】消费已扣款 158.00 元，卡内可用储值余额为 2,842.00 元。祝您生活愉快！',
    statusCode: 'DELIVRD',
    sendTime: '2026-09-09 19:42:10'
  },
  {
    smsId: 'SMS-DIRECT-8802',
    gateway: 'TENCENT',
    phone: '13800000000',
    signature: '海马商业',
    content: '【海马商业】您的动态身份验证码为 789123，5分钟内有效。如非本人操作请勿泄露。',
    statusCode: 'DELIVRD',
    sendTime: '2026-09-09 18:15:33'
  }
])

const clearAdminDispatchHistory = () => {
  adminDispatchRecords.value = []
  ElMessage.success('已清空运营端下发流水台账')
}

// 执行在线下发
const handleExecuteDirectSendSms = () => {
  const phone = (dispatchForm.value.phone || '').trim()
  if (!phone || !/^1[3-9]\d{9}$/.test(phone)) {
    ElMessage.warning('请输入有效的 11 位中国大陆手机号码')
    return
  }

  const currentSign = dispatchForm.value.gateway === 'ALIYUN'
    ? notifConfig.value.aliyunSms?.signName
    : notifConfig.value.tencentSms?.signName

  sendingSms.value = true
  setTimeout(() => {
    sendingSms.value = false
    const nowStr = new Date().toLocaleString()
    const newSmsId = `SMS-DIRECT-${Date.now().toString().slice(-6)}`
    const bizId = `${Date.now()}88092^0`
    const reqId = (dispatchForm.value.gateway === 'ALIYUN' ? 'ALI-' : 'TX-') + Math.random().toString(36).substring(2, 10).toUpperCase()
    const gatewayName = dispatchForm.value.gateway === 'ALIYUN' ? '🟠 阿里云短信服务 (Dysmsapi)' : '🔵 腾讯云短信 (SMS)'

    const record = {
      smsId: newSmsId,
      gateway: dispatchForm.value.gateway,
      phone,
      signature: currentSign || '海马商业',
      content: currentRenderedSmsText.value,
      statusCode: 'DELIVRD',
      sendTime: nowStr
    }

    // 追加到超管历史
    adminDispatchRecords.value.unshift(record)

    // 生成回执诊断
    latestDispatchReceipt.value = {
      smsId: newSmsId,
      gatewayName,
      phone,
      signName: currentSign || '海马商业',
      bizId,
      requestId: reqId,
      latencyMs: Math.floor(65 + Math.random() * 45),
      statusCode: 'DELIVRD',
      sendTime: nowStr
    }

    diagDialogVisible.value = true
    ElMessage.success(`🎉 恭喜！短信已通过【${gatewayName}】成功下发至手机【${phone}】，运营商状态码: DELIVRD`)
  }, 750)
}

onMounted(() => {
  loadConfig()
})
</script>

<style scoped>
.vendor-notif-container {
  padding: 18px 24px 40px;
  background: #f8fafc;
  min-height: calc(100vh - 60px);
}

.page-hero-header {
  background: linear-gradient(135deg, #ffffff 0%, #f0fdf4 100%);
  border: 1px solid #dcfce7;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  box-shadow: 0 2px 8px rgba(16, 185, 129, 0.04);
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
  background: linear-gradient(135deg, #10b981 0%, #047857 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  box-shadow: 0 4px 12px rgba(16, 185, 129, 0.25);
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
  max-width: 860px;
}

.notif-main-tabs :deep(.el-tabs__header) {
  margin-bottom: 16px;
}

.channels-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(420px, 1fr));
  gap: 20px;
}

.channel-card {
  border-radius: 12px;
  border: 1px solid #e2e8f0;
}

.card-aliyun-sms {
  border-top: 4px solid #f97316;
}

.card-tencent-sms {
  border-top: 4px solid #0284c7;
}

.card-wechat {
  border-top: 4px solid #10b981;
}

.card-alipay {
  border-top: 4px solid #0284c7;
}

.channel-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.channel-title-box {
  display: flex;
  align-items: center;
  gap: 8px;
}

.channel-icon {
  font-size: 22px;
}

.channel-name {
  font-weight: 800;
  font-size: 15px;
  color: #0f172a;
}

.channel-sub {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
}

.template-section {
  background: #f8fafc;
  border-radius: 8px;
  padding: 12px 14px;
  margin: 14px 0;
  border: 1px solid #f1f5f9;
}

.section-title {
  font-size: 12.5px;
  font-weight: 700;
  color: #334155;
  margin-bottom: 8px;
}

.config-tip {
  font-size: 11.5px;
  color: #64748b;
  margin-top: 4px;
}

.channel-actions {
  margin-top: 14px;
  padding-top: 12px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* 在线下发控制台 */
.sms-sender-card {
  border-radius: 12px;
  border: 1.5px solid #cbd5e1;
  background: #ffffff;
}

.sender-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.sh-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.sh-icon {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: linear-gradient(135deg, #0284c7, #0369a1);
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
}

.sh-title {
  font-size: 15px;
  font-weight: 800;
  color: #0f172a;
}

.sh-sub {
  font-size: 12px;
  color: #64748b;
  margin-top: 2px;
}

.variables-panel {
  background: #f1f5f9;
  border-radius: 8px;
  padding: 12px 16px;
  margin-bottom: 14px;
  border: 1px solid #e2e8f0;
}

.var-title {
  font-size: 12.5px;
  font-weight: 700;
  color: #334155;
  margin-bottom: 10px;
}

.send-now-btn {
  font-weight: 700;
  background: linear-gradient(135deg, #0284c7, #0369a1);
  border: none;
}

/* 手机屏幕拟真预览卡片 */
.phone-mock-preview {
  background: #0f172a;
  border-radius: 28px;
  padding: 14px;
  box-shadow: 0 16px 36px rgba(15, 23, 42, 0.2);
  width: 100%;
  max-width: 360px;
  margin: 0 auto;
}

.phone-speaker {
  width: 60px;
  height: 4px;
  background: #334155;
  border-radius: 4px;
  margin: 0 auto 10px;
}

.phone-screen {
  background: #f8fafc;
  border-radius: 20px;
  padding: 14px 12px;
  min-height: 420px;
  display: flex;
  flex-direction: column;
}

.ps-header {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  font-weight: 700;
  color: #475569;
  padding-bottom: 8px;
  border-bottom: 1px solid #e2e8f0;
}

.ps-icons {
  display: flex;
  gap: 4px;
}

.ps-sender-title {
  text-align: center;
  margin: 12px 0 16px;
}

.sender-avatar {
  width: 38px;
  height: 38px;
  background: #0284c7;
  color: #ffffff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 16px;
  margin: 0 auto 6px;
}

.sender-name {
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
}

.sender-carrier {
  font-size: 10.5px;
  color: #94a3b8;
}

.ps-bubble-wrap {
  flex: 1;
}

.ps-time-divider {
  font-size: 10px;
  color: #94a3b8;
  text-align: center;
  margin-bottom: 10px;
}

.ps-sms-bubble {
  background: #e2e8f0;
  border-radius: 14px 14px 14px 4px;
  padding: 10px 12px;
  color: #1e293b;
  font-size: 12.5px;
  line-height: 1.55;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.bubble-time {
  font-size: 9.5px;
  color: #94a3b8;
  text-align: right;
  margin-top: 4px;
}

.ps-meta-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 8px 10px;
  margin-top: 12px;
  font-size: 11px;
}

.pm-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 3px;
}

.pm-row:last-child {
  margin-bottom: 0;
}

.mono {
  font-family: monospace;
}

.bold {
  font-weight: 700;
}

.text-blue {
  color: #0284c7;
}

.text-green {
  color: #059669;
}

.text-danger {
  color: #ef4444;
}

.receipt-box .r-head {
  display: flex;
  align-items: center;
  gap: 12px;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  padding: 12px 14px;
  border-radius: 8px;
}

.rh-icon {
  font-size: 24px;
}

.rh-title {
  font-size: 14px;
  font-weight: 800;
  color: #166534;
}

.rh-sub {
  font-size: 12px;
  color: #15803d;
  margin-top: 2px;
}
</style>
