<template>
  <div class="login-container">
    <div class="login-layout-wrapper">
      <!-- 左侧：宣传广告大屏与核心亮点展区 -->
      <div class="marketing-showcase-panel">
        <div class="showcase-header">
          <div class="badge-pill">
            <span class="pulse-dot"></span>
            ✨ 新一代智慧服务业连锁门店经营操作系统
          </div>
          <h1 class="brand-hero-title">
            <span class="hero-seahorse-icon" aria-hidden="true">
              <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12.5 3.2C14.5 3.2 15.8 4.2 16.2 5.5L19.8 6C20.4 6.1 20.4 7.3 19.8 7.5L16 8.2C15.2 8.5 15 9.4 16 10.4C17.8 12 17.8 14.8 15.6 16.6C13.8 18 12.6 19.2 12.8 20.4C13 21.3 14.2 21.6 14.8 20.9C15.3 20.3 14.9 19.5 14.2 19.6C15.6 19.2 16.6 20.4 15.8 21.7C14.8 23 12 22.8 11 21C10 19.2 10.6 17.2 11.8 15.4C12.8 13.8 12.8 11.8 11.6 9.8C10.4 7.8 10.4 4.8 12.5 3.2Z" fill="currentColor" fill-opacity="0.24"/><path d="M11.2 4.4L10.2 2.5L12 3.4L12.8 1.8L13.8 3.3"/><path d="M12 10.5L8.2 9.6C7.6 11.2 7.6 12.8 8.4 14.2L12.2 13.6" fill="currentColor" fill-opacity="0.18"/><path d="M12.4 12L8 11.9"/><path d="M13.5 11.8C14.8 11.8 15.8 12 16.8 12.4"/><path d="M13.4 13.8C14.6 13.8 15.5 14 16.4 14.4"/><circle cx="14.2" cy="6.1" r="1" fill="currentColor" stroke="none"/><path d="M5.2 3.4l.65 1.45L7.3 5.5l-1.45.65L5.2 7.6l-.65-1.45L3.1 5.5l1.45-.65L5.2 3.4z" fill="currentColor" stroke="none"/></svg>
            </span>
            <span>海马智慧门店</span>
            <span class="brand-en">Seahorse Smart Store</span>
          </h1>
          <div class="brand-hero-slogan">
            <span class="hero-slogan-sparkle">✦</span>
            <span>海马会员，记住每位好客。</span>
          </div>
        </div>

        <!-- 宣传重点广告看板：✨ 全系统核心卖点矩阵 -->
        <div class="showcase-section-header">
          <div class="section-title-wrap">
            <span class="star-icon">✨</span>
            <span class="title-text">新一代门店数智化核心卖点</span>
            <span class="ad-tag">SaaS 2.0 旗舰赋能</span>
          </div>
          <div class="title-sub">提炼 8 大硬核能力，覆盖“记忆运营·双轨收银·营销获客·连锁协同”全场景闭环</div>
        </div>

        <!-- 宣传高光数据看板 -->
        <div class="promo-ticker-bar">
          <div class="ticker-item">
            <span class="t-num">99.9%</span>
            <span class="t-label">账实精准核对</span>
          </div>
          <div class="ticker-item">
            <span class="t-num">0 超扣</span>
            <span class="t-label">双轨资产并发防超扣</span>
          </div>
          <div class="ticker-item">
            <span class="t-num">10秒</span>
            <span class="t-label">在场开单与加项</span>
          </div>
          <div class="ticker-item">
            <span class="t-num">4大</span>
            <span class="t-label">服务业态即开即用</span>
          </div>
        </div>

        <!-- 卖点分类导航切换 -->
        <div class="showcase-tabs-nav">
          <span
            v-for="cat in sellingCategories"
            :key="cat.key"
            class="s-nav-tab"
            :class="{ active: activeCategory === cat.key }"
            @click="activeCategory = cat.key"
          >
            {{ cat.label }}
          </span>
        </div>

        <!-- 动态卖点广告卡片列表 -->
        <div class="feature-card-list">
          <div
            v-for="sp in filteredSellingPoints"
            :key="sp.id"
            class="feature-card"
            :class="{ 'highlight-card': sp.isHero }"
          >
            <div class="f-icon-box">{{ sp.icon }}</div>
            <div class="f-content">
              <div class="f-header">
                <span class="f-title">{{ sp.title }}</span>
                <span class="f-tag">{{ sp.badge }}</span>
              </div>
              <p class="f-desc">{{ sp.desc }}</p>
              <div class="f-highlight-chips" v-if="sp.highlights?.length">
                <span v-for="h in sp.highlights" :key="h" class="f-chip">
                  ✓ {{ h }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- 底部行业生态与信赖保障 -->
        <div class="industry-eco-bar">
          <div class="eco-row">
            <span class="eco-lbl">🏬 4 大行业全案深度适配：</span>
            <div class="eco-tags">
              <span class="eco-tag tag-pink">💇 美容美发美甲</span>
              <span class="eco-tag tag-orange">🍲 餐饮轻食正餐</span>
              <span class="eco-tag tag-blue">🚗 汽车养护维修</span>
              <span class="eco-tag tag-green">🛍️ 专营名品零售</span>
            </div>
          </div>
          <div class="trust-row">
            <span class="trust-item">🛡️ 资金账户安全合规</span>
            <span class="trust-dot">·</span>
            <span class="trust-item">⚡ 履约微内核高并发</span>
            <span class="trust-dot">·</span>
            <span class="trust-item">🖨️ 隔离热敏小票沙箱</span>
            <span class="trust-dot">·</span>
            <span class="trust-item">👥 招聘入职秒级开号</span>
          </div>
        </div>
      </div>

      <!-- 右侧：登录/注册主卡片 -->
      <div class="login-card">
        <div style="display: flex; justify-content: flex-end; margin-bottom: 8px;">
          <a href="/" style="display: inline-flex; align-items: center; gap: 4px; font-size: 12px; font-weight: 600; color: #0284c7; background: #e0f2fe; padding: 4px 10px; border-radius: 9999px; text-decoration: none; border: 1px solid #bae6fd;">
            <span>🌐 返回 FWPT 门户</span>
          </a>
        </div>
        <div class="brand-header">
          <div class="logo seahorse-badge-logo" aria-hidden="true">
            <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12.5 3.2C14.5 3.2 15.8 4.2 16.2 5.5L19.8 6C20.4 6.1 20.4 7.3 19.8 7.5L16 8.2C15.2 8.5 15 9.4 16 10.4C17.8 12 17.8 14.8 15.6 16.6C13.8 18 12.6 19.2 12.8 20.4C13 21.3 14.2 21.6 14.8 20.9C15.3 20.3 14.9 19.5 14.2 19.6C15.6 19.2 16.6 20.4 15.8 21.7C14.8 23 12 22.8 11 21C10 19.2 10.6 17.2 11.8 15.4C12.8 13.8 12.8 11.8 11.6 9.8C10.4 7.8 10.4 4.8 12.5 3.2Z" fill="currentColor" fill-opacity="0.24"/><path d="M11.2 4.4L10.2 2.5L12 3.4L12.8 1.8L13.8 3.3"/><path d="M12 10.5L8.2 9.6C7.6 11.2 7.6 12.8 8.4 14.2L12.2 13.6" fill="currentColor" fill-opacity="0.18"/><path d="M12.4 12L8 11.9"/><path d="M13.5 11.8C14.8 11.8 15.8 12 16.8 12.4"/><path d="M13.4 13.8C14.6 13.8 15.5 14 16.4 14.4"/><circle cx="14.2" cy="6.1" r="1" fill="currentColor" stroke="none"/><path d="M5.2 3.4l.65 1.45L7.3 5.5l-1.45.65L5.2 7.6l-.65-1.45L3.1 5.5l1.45-.65L5.2 3.4z" fill="currentColor" stroke="none"/></svg>
          </div>
          <div class="title">海马智慧门店</div>
          <div class="subtitle">Seahorse Smart Store · FWPT 矩阵生态</div>
          <div class="slogan">
            <span class="card-slogan-sparkle">✦</span>
            <span>海马会员，记住每位好客。</span>
          </div>
        </div>

        <el-tabs v-model="activeTab" class="login-tabs" stretch>
          <!-- 选项卡 1：账号登录 -->
          <el-tab-pane label="🔑 员工 / 账号登录" name="login">
            <el-form :model="loginForm" class="login-form" size="large" @submit.prevent="handleLogin">
              <el-form-item>
                <el-input
                  v-model="loginForm.username"
                  placeholder="请输入通行证账号 / 常用邮箱 / 手机号码"
                  prefix-icon="User"
                  clearable
                />
              </el-form-item>
              <el-form-item style="margin-bottom: 8px;">
                <div style="display: flex; justify-content: space-between; align-items: center; width: 100%; margin-bottom: 4px;">
                  <span style="font-size: 13px; color: #475569; font-weight: 500;">账户密码</span>
                  <el-button
                    link
                    type="primary"
                    style="font-size: 12px; padding: 0;"
                    @click="openResetPasswordModal"
                  >
                    忘记密码？
                  </el-button>
                </div>
                <el-input
                  v-model="loginForm.password"
                  type="password"
                  placeholder="请输入您的账户登录密码"
                  prefix-icon="Lock"
                  show-password
                  @keyup.enter="handleLogin"
                />
              </el-form-item>

              <el-button type="primary" :loading="loading" class="login-submit-btn" @click="handleLogin">
                登录系统工作台
              </el-button>

              <!-- 快速体验演示账号区 -->
              <div class="quick-roles" :class="{ 'demo-mode-spotlight': isDemoModeSpotlight }">
                <div v-if="isDemoModeSpotlight" class="demo-spotlight-tip">✨ 已为您开启多行业演示通道，点击下方任意行业即可一键免密体验</div>
                <div class="quick-title">⚡ 快速体验不同行业预置方案：</div>
                <div class="role-buttons">
                  <el-button size="small" round @click="quickLogin('beauty_boss')">💇 美业老板</el-button>
                  <el-button size="small" round @click="quickLogin('dining_boss')">🍲 餐饮老板</el-button>
                  <el-button size="small" round @click="quickLogin('auto_boss')">🚗 汽修老板</el-button>
                  <el-button size="small" round @click="quickLogin('retail_boss')">🛍️ 零售老板</el-button>
                  <el-button size="small" round type="warning" plain @click="quickMultiStoreStaffLogin">👥 多店兼职技师</el-button>
                </div>
              </div>
            </el-form>
          </el-tab-pane>

          <!-- 选项卡 2：免费注册通行证 (与首页 OneID 保持一致) -->
          <el-tab-pane label="🚀 免费注册通行证" name="register">
            <!-- 3 种注册方式切换分段控件 -->
            <div class="reg-type-selector">
              <button
                type="button"
                class="reg-type-pill"
                :class="{ active: regType === 'EMAIL' }"
                @click="regType = 'EMAIL'"
              >
                ✉️ 邮箱注册
              </button>
              <button
                type="button"
                class="reg-type-pill"
                :class="{ active: regType === 'PHONE' }"
                @click="regType = 'PHONE'"
              >
                📱 手机号注册
              </button>
              <button
                type="button"
                class="reg-type-pill"
                :class="{ active: regType === 'ACCOUNT' }"
                @click="regType = 'ACCOUNT'"
              >
                ⚡ 账号快速注册
              </button>
            </div>

            <el-form :model="regForm" label-position="top" size="large" class="reg-form-wrap" @submit.prevent="handleRegister">
              <!-- 1. 邮箱注册专属输入区 -->
              <template v-if="regType === 'EMAIL'">
                <el-form-item label="常用电子邮箱" required>
                  <el-input
                    v-model="regForm.email"
                    placeholder="name@example.com (用于接收验证码与找回密码)"
                    prefix-icon="Message"
                    clearable
                    @blur="handleEmailBlur"
                  />
                </el-form-item>

                <el-form-item label="安全验证码" required>
                  <div style="display: flex; gap: 8px; width: 100%;">
                    <el-input
                      v-model="regForm.verifyCode"
                      placeholder="6 位数字验证码"
                      prefix-icon="Key"
                      maxlength="6"
                      style="flex: 1;"
                    />
                    <el-button
                      type="primary"
                      plain
                      :disabled="emailCountDown > 0 || emailSending"
                      :loading="emailSending"
                      @click="handleSendEmailCode"
                      style="white-space: nowrap; min-width: 104px;"
                    >
                      {{ emailCountDown > 0 ? `${emailCountDown}s 后重发` : '获取验证码' }}
                    </el-button>
                  </div>
                  <div class="input-sub-tip">
                    💡 验证码由官方邮箱 <code>admin@fwpt.cn</code> 实时发送，若未收到请检查垃圾箱或切换「账号快速注册」。
                  </div>
                </el-form-item>
              </template>

              <!-- 2. 手机号注册专属输入区 -->
              <template v-if="regType === 'PHONE'">
                <el-form-item label="中国大陆手机号" required>
                  <el-input
                    v-model="regForm.phone"
                    placeholder="请输入 11 位手机号码"
                    prefix-icon="Phone"
                    maxlength="11"
                    clearable
                    @blur="handlePhoneBlur"
                  />
                </el-form-item>

                <el-form-item label="安全验证码" required>
                  <div style="display: flex; gap: 8px; width: 100%;">
                    <el-input
                      v-model="regForm.verifyCode"
                      placeholder="6 位短信验证码"
                      prefix-icon="Key"
                      maxlength="6"
                      style="flex: 1;"
                    />
                    <el-button
                      type="primary"
                      plain
                      :disabled="phoneCountDown > 0 || phoneSending"
                      :loading="phoneSending"
                      @click="handleSendPhoneCode"
                      style="white-space: nowrap; min-width: 104px;"
                    >
                      {{ phoneCountDown > 0 ? `${phoneCountDown}s 后重发` : '获取验证码' }}
                    </el-button>
                  </div>
                  <div class="input-sub-tip">
                    💡 短信验证码将发送至您的手机，测试环境支持快捷校验。
                  </div>
                </el-form-item>
              </template>

              <!-- 3. 账号快速直通提示 -->
              <div v-if="regType === 'ACCOUNT'" class="account-quick-notice">
                ⚡ <strong>免码直通极速注册：</strong>无需绑定手机号或邮箱，直接设定全平台通用用户名与密码，10秒内即刻创建并开启体验！
              </div>

              <!-- 通用公共字段 (全模式通用) -->
              <el-form-item label="设置通行证用户名" required>
                <el-input
                  v-model="regForm.username"
                  placeholder="3-32 位字母、数字或下划线 (全平台唯一登录名)"
                  prefix-icon="User"
                  clearable
                />
              </el-form-item>

              <el-form-item label="显示称呼 / 门店主理人 (选填)">
                <el-input
                  v-model="regForm.nickname"
                  placeholder="例如：张经理 / 李老板 / 门店店长"
                  prefix-icon="Edit"
                  clearable
                />
              </el-form-item>

              <el-form-item label="设置登录密码" required>
                <el-input
                  v-model="regForm.password"
                  type="password"
                  placeholder="至少 6 位字符，建议包含字母与数字"
                  prefix-icon="Lock"
                  show-password
                />
              </el-form-item>

              <div class="trial-perk-box">
                🎉 注册成功即享 <strong>3天体验版套餐全功能免费试用</strong>，行业与门店信息可在登录后随时自由配置！
              </div>

              <el-button
                type="primary"
                :loading="regLoading"
                class="login-submit-btn reg-action-btn"
                @click="handleRegister"
              >
                立即创建 OneID 通行证并开通体验
              </el-button>

              <div class="terms-footer">
                注册或登录即代表阅读并同意
                <a href="/terms" target="_blank" rel="noopener">《服务条款》</a>
                与
                <a href="/privacy" target="_blank" rel="noopener">《隐私政策》</a>
              </div>
            </el-form>
          </el-tab-pane>
        </el-tabs>
      </div>
    </div>

    <!-- 员工一人多店登录·自选进入门店弹窗 -->
    <el-dialog
      v-model="chooseStoreDialogVisible"
      title="🏪 请选择本次登录进入的门店工作台"
      width="640px"
      destroy-on-close
      :close-on-click-modal="false"
      class="choose-store-dialog"
    >
      <div class="choose-store-modal">
        <div class="staff-banner">
          <div class="staff-avatar-col">
            <el-avatar :size="48" style="background-color: #0d9488; font-size: 20px; font-weight: bold;">
              {{ pendingStaff?.realName?.substring(0, 1) || '职' }}
            </el-avatar>
          </div>
          <div class="staff-info-col">
            <div class="staff-title">
              <span class="staff-name">{{ pendingStaff?.realName }}</span>
              <el-tag size="small" type="success" effect="light">{{ pendingStaff?.postName || '造型技师' }}</el-tag>
              <el-tag size="small" type="warning" effect="plain">多店兼职执业</el-tag>
            </div>
            <div class="staff-phone">登录手机号：{{ pendingStaff?.phone }}</div>
            <div class="staff-tip">您被授权执业于多家分店，请选择本次登录进入哪个分店工作台：</div>
          </div>
        </div>

        <div class="store-card-list">
          <div
            v-for="store in pendingAllowedStores"
            :key="store.storeId"
            class="store-select-card"
            @click="handleSelectStoreAndLogin(store.storeId)"
          >
            <div class="s-main-info">
              <div class="s-top-row">
                <span class="s-name">{{ store.storeName }}</span>
                <el-tag size="small" :type="store.isHeadquarter ? 'danger' : 'primary'" effect="plain">
                  {{ store.isHeadquarter ? '旗舰总店' : '连锁分店' }}
                </el-tag>
              </div>
              <div class="s-addr-row">
                <el-icon style="margin-right: 4px;"><Location /></el-icon>
                <span>{{ store.address || '核心商业中心街区' }}</span>
              </div>
              <div class="s-menus-row" v-if="pendingStaff?.allowedMenuPaths?.length">
                <span class="m-lbl">授权可用页签：</span>
                <span class="m-val">{{ getMenuNamesText(pendingStaff.allowedMenuPaths) }}</span>
              </div>
            </div>
            <div class="s-action-col">
              <el-button type="primary" size="default" round>
                进入工作台 👉
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </el-dialog>
  
    <!-- 找回/重置全平台通行证密码弹窗 -->
    <el-dialog
      v-model="resetDialogVisible"
      title="🔐 找回 / 重置全平台通行证密码"
      width="460px"
      destroy-on-close
      class="reset-pass-dialog"
    >
      <div style="font-size: 13px; color: #64748b; margin-bottom: 16px; line-height: 1.5;">
        通过注册时绑定的邮箱或手机号核验身份后，即可重置全平台 OneID 通行证密码。
      </div>
      <el-form label-position="top" size="large">
        <el-form-item label="绑定的电子邮箱或手机号" required>
          <el-input
            v-model="resetForm.target"
            placeholder="请输入注册时绑定的常用邮箱或手机号"
            prefix-icon="User"
            clearable
          />
        </el-form-item>
        <el-form-item label="安全验证码" required>
          <div style="display: flex; gap: 8px; width: 100%;">
            <el-input
              v-model="resetForm.code"
              placeholder="6 位数字验证码"
              prefix-icon="Key"
              maxlength="6"
              style="flex: 1;"
            />
            <el-button
              type="primary"
              plain
              :disabled="resetCountDown > 0 || resetSending"
              :loading="resetSending"
              @click="handleSendResetCode"
              style="white-space: nowrap;"
            >
              {{ resetCountDown > 0 ? `${resetCountDown}s 后重发` : '发送验证码' }}
            </el-button>
          </div>
          <div class="input-sub-tip">
            💡 验证码将由官方邮箱 <code>admin@fwpt.cn</code> 或短信网关发送，请在 5 分钟内完成操作。
          </div>
        </el-form-item>
        <el-form-item label="设置新密码" required>
          <el-input
            v-model="resetForm.newPassword"
            type="password"
            placeholder="请输入至少 6 位新密码"
            prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        <el-form-item label="确认新密码" required>
          <el-input
            v-model="resetForm.confirmPassword"
            type="password"
            placeholder="请再次输入新密码以确认"
            prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        <el-button
          type="primary"
          class="login-submit-btn"
          :loading="resetSubmitting"
          @click="handleConfirmReset"
          style="margin-top: 10px;"
        >
          确认重置密码
        </el-button>
      </el-form>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import axios from 'axios'
import { useRouter } from 'vue-router'
import { loginApi, registerMerchantApi, getPublicPlansApi, recordClientAuditLogApi } from '../api'
import { useSystemDataStore, allSystemMenus } from '../stores/systemDataStore'
import { allIndustryPackages } from '../stores/industryPresets'
import { useStoreConfig } from '../stores/store'
import { mockFootSpaStaff, injectFootSpaMockData } from '../mock/mockFootSpaData'
import { ElMessage, ElMessageBox } from 'element-plus'

const router = useRouter()
const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()
const activeTab = ref('login')
const loading = ref(false)
const regLoading = ref(false)

// -----------------------------------------------------------------------------
// 提炼全系统卖点与广告看板数据源
// -----------------------------------------------------------------------------
interface SellingPoint {
  id: string
  category: 'ALL' | 'MEMORY' | 'MONEY' | 'MARKETING' | 'CHAIN'
  icon: string
  badge: string
  title: string
  desc: string
  highlights: string[]
  isHero?: boolean
}

const activeCategory = ref<'ALL' | 'MEMORY' | 'MONEY' | 'MARKETING' | 'CHAIN'>('ALL')

const sellingCategories = [
  { key: 'ALL', label: '🌟 核心主打' },
  { key: 'MEMORY', label: '🧠 记忆与履约' },
  { key: 'MONEY', label: '💳 资金防超扣' },
  { key: 'MARKETING', label: '📈 自动化营销' },
  { key: 'CHAIN', label: '🏪 连锁与成本' }
]

const allSellingPoints: SellingPoint[] = [
  {
    id: 'memory_kernel',
    category: 'MEMORY',
    icon: '🧠',
    badge: '独创微内核',
    title: '“海马体”客情常态记忆微内核',
    desc: '彻底告别千人一面。系统毫秒级呼出顾客发质特性、餐饮微辣免葱、汽修车型机油等常态偏好，免顾客反复交代，熟客满意度飙升98%。',
    highlights: ['秒级客情呼出', '行业专属标签库', '到店尊享体验'],
    isHero: true
  },
  {
    id: 'dual_balance',
    category: 'MONEY',
    icon: '💳',
    badge: '资金合规',
    title: '双轨储值金 + 计量次卡防并发超扣',
    desc: '科学严谨区分本金与赠送金（支持等比扣减与优先扣本金），次卡单项核销与技师业绩归属，高并发CAS防超扣幂等，保障租户每一分钱。',
    highlights: ['本金/赠金双轨', '次卡多店通兑', '防高并发超扣'],
    isHero: true
  },
  {
    id: 'session_stream',
    category: 'MEMORY',
    icon: '⚡',
    badge: '全场景通用',
    title: '在场服务流会话微内核（多批次动态追加）',
    desc: '抹平美业、餐饮、汽修业务鸿沟！空间工位极速锁定，支持多次动态追加项目、多人提成分工认领、多渠道组合结算（卡+券+微信+现金）。',
    highlights: ['多批次动态加项', '工位/包厢管理', '多人提成分工'],
    isHero: true
  },
  {
    id: 'auto_care',
    category: 'MARKETING',
    icon: '💖',
    badge: '自动化增长',
    title: '365天自动化客群关怀与国庆特别企划',
    desc: '深度结合中国国庆黄金周、春节、中秋等传统节假日及会员生日，自动巡检下发满减券、翻倍积分、伴手礼与专属短信，老客复购率提升45%。',
    highlights: ['国庆/节假日大促', '高频消费礼包', '沉睡客自动唤醒'],
    isHero: true
  },
  {
    id: 'marketing_calendar',
    category: 'MARKETING',
    icon: '📅',
    badge: '实用工具箱',
    title: '全年12个月营销日历与AI获客助手',
    desc: '清晰标注法定节假日与24节气，内置4大高净值客群精准触达时机指南、智能高转化营销文案生成器、会员充值赠送毛利率测算器。',
    highlights: ['12个月作战日历', '4大客群触达指南', '充值毛利测算器']
  },
  {
    id: 'multi_store_practice',
    category: 'CHAIN',
    icon: '🏪',
    badge: '集团化协同',
    title: '连锁多店跨店漫游与员工一人多店执业',
    desc: '会员资金池支持跨店漫游核销；支持员工在多家分店任职兼职执业，登录自选门店工作台，按授权页签严格物理隔离，一人多店轻松运转。',
    highlights: ['会员资金漫游', '一人多店执业', '页签权限物理隔离']
  },
  {
    id: 'cost_center',
    category: 'CHAIN',
    icon: '📊',
    badge: '透明经营',
    title: '全口径成本中心与智能利润大盘',
    desc: '房租能耗、BOM物料出库消耗、营销获客成本、员工底薪与施工提成自动实时汇总计入经营成本，损益净利实时可查，彻底告别月末糊涂账。',
    highlights: ['BOM物料自动记账', '提成实时汇算', '经营利润一目了然']
  },
  {
    id: 'hardware_sandbox',
    category: 'MONEY',
    icon: '🖨️',
    badge: '商用级可靠',
    title: '独立热敏打印沙箱与招聘入职闭环',
    desc: '58mm/80mm 矢量热敏小票隔离沙箱，绝无界面控件透印；岗位描述二维码直通应聘，面试短信自动通知，录用一键入职秒开工作台账号。',
    highlights: ['纯净矢量热敏出单', '钱箱指令联动', '招聘到开号闭环']
  }
]

const filteredSellingPoints = computed(() => {
  if (activeCategory.value === 'ALL') {
    return allSellingPoints.filter(p => p.isHero || ['marketing_calendar', 'multi_store_practice'].includes(p.id))
  }
  return allSellingPoints.filter(p => p.category === activeCategory.value)
})

const loginForm = ref({
  username: '',
  password: ''
})

// 一人多店员工登录选择状态
const chooseStoreDialogVisible = ref(false)
const pendingStaff = ref<any>(null)
const pendingAllowedStores = ref<any[]>([])

const getMenuNamesText = (paths: string[]) => {
  if (!paths || paths.length === 0) return '全量基础权限'
  return paths.map(p => {
    const m = allSystemMenus.find(item => item.path === p)
    return m ? m.name : p
  }).join('、')
}

// 注册方式状态与表单 (对齐首页 OneID 统一通行证)
const regType = ref<'EMAIL' | 'PHONE' | 'ACCOUNT'>('EMAIL')
const emailCountDown = ref(0)
const phoneCountDown = ref(0)
const emailSending = ref(false)
const phoneSending = ref(false)

const regForm = ref({
  email: '',
  phone: '',
  verifyCode: '',
  username: '',
  nickname: '',
  password: ''
})

const handleEmailBlur = () => {
  if (regForm.value.email && !regForm.value.username) {
    const prefix = regForm.value.email.split('@')[0]
    if (prefix && prefix.length >= 3) {
      regForm.value.username = prefix
    }
  }
}

const handlePhoneBlur = () => {
  if (regForm.value.phone && !regForm.value.username) {
    regForm.value.username = regForm.value.phone
  }
}

// 找回密码状态
const resetDialogVisible = ref(false)
const resetSending = ref(false)
const resetSubmitting = ref(false)
const resetCountDown = ref(0)
const resetForm = ref({
  target: '',
  code: '',
  newPassword: '',
  confirmPassword: ''
})

const openResetPasswordModal = () => {
  resetForm.value.target = loginForm.value.username || ''
  resetForm.value.code = ''
  resetForm.value.newPassword = ''
  resetForm.value.confirmPassword = ''
  resetDialogVisible.value = true
}

// 发送邮箱验证码 (通过 official admin@fwpt.cn 发送)
const handleSendEmailCode = async () => {
  const email = (regForm.value.email || '').trim()
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    ElMessage.warning('请输入有效的常用电子邮箱地址')
    return
  }
  emailSending.value = true
  try {
    const res = await axios.post('/api/v1/auth/send-email-code', { email })
    const data = res.data
    if (data.code === 200 || data.code === '00000' || data.status === 'ok') {
      const msg = data.data?.message || data.message || '安全验证码已由官方邮箱 admin@fwpt.cn 实时送达，请查收！'
      ElMessage.success(msg)
      emailCountDown.value = 60
      const timer = setInterval(() => {
        emailCountDown.value--
        if (emailCountDown.value <= 0) clearInterval(timer)
      }, 1000)
    } else {
      ElMessage.error(data.message || data.detail || '验证码发送失败，请稍后重试')
    }
  } catch (err: any) {
    ElMessage.error(err.response?.data?.message || err.message || '网络连接超时，请检查网络')
  } finally {
    emailSending.value = false
  }
}

// 发送手机短信验证码
const handleSendPhoneCode = async () => {
  const phone = (regForm.value.phone || '').trim()
  if (!phone || !/^1[3-9]\d{9}$/.test(phone)) {
    ElMessage.warning('请输入有效的11位中国大陆手机号码')
    return
  }
  phoneSending.value = true
  try {
    const res = await axios.post('/api/v1/auth/send-code', { phone })
    const data = res.data
    if (data.code === 200 || data.code === '00000' || data.status === 'ok') {
      const serverCode = data.data?.code
      if (serverCode) {
        regForm.value.verifyCode = serverCode
        ElMessage.success(`验证码已发送至手机（测试环境自动填入：${serverCode}）`)
      } else {
        ElMessage.success('短信验证码已发送至您的手机，请注意查收')
      }
      phoneCountDown.value = 60
      const timer = setInterval(() => {
        phoneCountDown.value--
        if (phoneCountDown.value <= 0) clearInterval(timer)
      }, 1000)
    } else {
      ElMessage.error(data.message || data.detail || '短信验证码发送失败')
    }
  } catch (err: any) {
    ElMessage.error(err.response?.data?.message || err.message || '网络连接超时，请检查网络')
  } finally {
    phoneSending.value = false
  }
}

const lastSentResetCode = ref('')
const isDemoModeSpotlight = ref(false)

// 发送重置密码验证码
const handleSendResetCode = async () => {
  const target = (resetForm.value.target || '').trim()
  if (!target) {
    ElMessage.warning('请输入绑定的电子邮箱或手机号')
    return
  }
  const isEmail = target.includes('@')
  resetSending.value = true
  try {
    const endpoint = isEmail ? '/api/v1/auth/send-email-code' : '/api/v1/auth/send-code'
    const payload = isEmail ? { email: target } : { phone: target }
    const res = await axios.post(endpoint, payload)
    const data = res.data
    if (data.code === 200 || data.code === '00000' || data.status === 'ok') {
      const serverCode = data.data?.code
      if (serverCode) {
        lastSentResetCode.value = String(serverCode)
        resetForm.value.code = String(serverCode)
        ElMessage.success(`验证码已发送（测试环境自动填入：${serverCode}）`)
      } else {
        lastSentResetCode.value = ''
        ElMessage.success('验证码已发送，请在 5 分钟内完成操作')
      }
      resetCountDown.value = 60
      const timer = setInterval(() => {
        resetCountDown.value--
        if (resetCountDown.value <= 0) clearInterval(timer)
      }, 1000)
    } else {
      ElMessage.error(data.message || '发送失败，请稍后重试')
    }
  } catch (err: any) {
    ElMessage.error(err.response?.data?.message || err.message || '网络连接超时')
  } finally {
    resetSending.value = false
  }
}

// 确认重置密码
const handleConfirmReset = async () => {
  const target = (resetForm.value.target || '').trim()
  const code = (resetForm.value.code || '').trim()
  const newPassword = (resetForm.value.newPassword || '').trim()
  const confirmPassword = (resetForm.value.confirmPassword || '').trim()

  if (!target) {
    ElMessage.warning('请输入绑定的电子邮箱或手机号')
    return
  }
  if (!code || !/^\d{4,6}$/.test(code)) {
    ElMessage.warning('请输入有效的安全验证码')
    return
  }
  if (lastSentResetCode.value && code !== lastSentResetCode.value) {
    ElMessage.error('安全验证码不正确，请核对后重试')
    return
  }
  if (!newPassword || newPassword.length < 6) {
    ElMessage.warning('请输入至少 6 位新密码')
    return
  }
  if (newPassword !== confirmPassword) {
    ElMessage.warning('两次输入的新密码不一致，请重新核对')
    return
  }

  resetSubmitting.value = true
  try {
    let resetSuccess = false
    // 1. 调用海马门店后端重置接口 (带 /api 前缀)
    try {
      const res = await axios.post('/api/vendor/users/reset-password', {
        username: target,
        code: code,
        newPassword: newPassword
      })
      if (res.data?.code === 200 || res.status === 200) {
        resetSuccess = true
      }
    } catch (e: any) {
      // 若 OneID 统一认证存在该用户，同步尝试 OneID 重置
      try {
        const oneIdRes = await axios.post('/api/v1/auth/reset-password', {
          target,
          email: target.includes('@') ? target : undefined,
          phone: !target.includes('@') ? target : undefined,
          code,
          new_password: newPassword,
          newPassword: newPassword
        })
        if (oneIdRes.data?.code === 200 || oneIdRes.data?.status === 'ok') {
          resetSuccess = true
        }
      } catch (_oneErr) {}
    }

    // 2. 同步更新本地员工列表密码 (若匹配)
    const matchedStaff = systemData.staff.find(
      s => (s.phone === target || s.accountUsername === target) && s.status !== 'DELETED'
    )
    if (matchedStaff) {
      matchedStaff.accountPassword = newPassword
      resetSuccess = true
    }

    if (!resetSuccess) {
      ElMessage.error('未找到匹配的绑定账号或验证码已失效，请检查账号信息')
      return
    }

    ElMessage.success('密码重置成功，请使用新密码登录！')
    loginForm.value.username = target
    loginForm.value.password = newPassword
    resetDialogVisible.value = false
  } catch (err: any) {
    ElMessage.error(err.response?.data?.message || err.message || '重置失败')
  } finally {
    resetSubmitting.value = false
  }
}

const publicPlans = ref<any[]>([
  { planCode: 'TRIAL', planName: '基础体验版', annualPrice: 0, trialDays: 3, storeLimit: 1, storageQuotaGb: 5 },
  { planCode: 'PROFESSIONAL', planName: '专业版', annualPrice: 2980, trialDays: 0, storeLimit: 3, storageQuotaGb: 20 },
  { planCode: 'FLAGSHIP', planName: '旗舰版', annualPrice: 6800, trialDays: 0, storeLimit: 10, storageQuotaGb: 50 },
  { planCode: 'ENTERPRISE', planName: '企业定制版', annualPrice: 19800, trialDays: 0, storeLimit: 999, storageQuotaGb: 500 }
])

const currentTrialDays = computed(() => {
  const trial = publicPlans.value.find(p => p.planCode === 'TRIAL')
  return trial && trial.trialDays ? trial.trialDays : 3
})

onMounted(async () => {
  // 1. 尝试从 URL 探测 sso_token 或指定用户名参数 (不主动自动填充超级管理员)
  try {
    const urlParams = new URLSearchParams(window.location.search)
    const urlUser = urlParams.get('username')
    const isDemo = urlParams.get('demo')
    if (urlUser && urlUser !== 'admin') {
      loginForm.value.username = urlUser
    } else if (isDemo === '1' || isDemo === 'true') {
      isDemoModeSpotlight.value = true
      loginForm.value.username = 'beauty_boss'
      loginForm.value.password = '123456'
      ElMessage.success('✨ 欢迎体验海马智慧门店！可直接点击登录或点选下方 4 大行业老板一键体验')
    }
  } catch (err) {}

  try {
    const res: any = await getPublicPlansApi()
    const plans = res?.data || res
    if (plans && Array.isArray(plans) && plans.length > 0) {
      publicPlans.value = plans
    }
  } catch (e) {
    console.warn('Failed to load public plans:', e)
  }
})

const handleLogin = async () => {
  const enteredUname = (loginForm.value.username || '').trim()
  const enteredPwd = (loginForm.value.password || '').trim()

  if (!enteredUname) {
    ElMessage.warning('请输入登录手机号或账号')
    return
  }
  if (!enteredPwd) {
    ElMessage.warning('请输入登录密码')
    return
  }

  if (['beauty_boss', 'dining_boss', 'auto_boss', 'retail_boss'].includes(enteredUname) && enteredPwd === '123456') {
    quickLogin(enteredUname)
    return
  }

  // 1. 优先在员工数据集中匹配员工手机号或账号 (支持租户为员工注册申请的账号，兜底全行业员工及快捷别名)
  const searchUname = enteredUname.toLowerCase()
  let matchedStaff = systemData.staff.find(
    s => (s.phone === enteredUname || s.accountUsername === enteredUname) && s.status !== 'DELETED'
  )
  if (!matchedStaff) {
    if (searchUname === 'tony') {
      matchedStaff = systemData.staff.find(s => s.role === 'TECHNICIAN' && s.status !== 'DELETED') || systemData.staff[1]
    } else if (searchUname === 'cashier') {
      matchedStaff = systemData.staff.find(s => s.role === 'CASHIER' && s.status !== 'DELETED') || systemData.staff[2]
    } else if (searchUname === 'manager') {
      matchedStaff = systemData.staff.find(s => s.role === 'STORE_MANAGER' && s.status !== 'DELETED') || systemData.staff[0]
    }
  }
  if (!matchedStaff) {
    for (const pkg of Object.values(allIndustryPackages)) {
      const found = pkg.staff?.find((s: any) => (s.phone === enteredUname || s.accountUsername === enteredUname) && s.status !== 'DELETED')
      if (found) {
        matchedStaff = found
        break
      }
    }
  }
  if (!matchedStaff) {
    matchedStaff = mockFootSpaStaff.find(
      (s: any) => (s.phone === enteredUname || s.accountUsername === enteredUname || (enteredUname === 'foot_spa' && s.id === 101)) && s.status !== 'DELETED'
    ) as any
    if (matchedStaff) {
      injectFootSpaMockData(systemData, storeConfig)
    }
  }

  if (matchedStaff) {
    // 检查扫码入职审核状态与账号有效性 (需店长或租户审核)
    if (matchedStaff.accountStatus === 'PENDING_REVIEW' || matchedStaff.auditStatus === 'PENDING') {
      ElMessageBox.alert(
        `员工【${matchedStaff.realName}】您好！您通过扫码提交的入职申请正在审核中。<br/><br/>根据门店入职合规流程，需由<b>店长</b>或<b>租户老板</b>在系统后台【员工管理 - 🛡️ 扫码入职审核】中审核批准后，方可激活并登录系统。<br/><br/>请耐心等待或提醒店长/老板进行审核。`,
        '入职审核中',
        { dangerouslyUseHTMLString: true, type: 'warning', confirmButtonText: '我知道了' }
      )
      return
    }
    if (matchedStaff.accountStatus === 'REJECTED' || matchedStaff.auditStatus === 'REJECTED') {
      ElMessageBox.alert(
        `员工【${matchedStaff.realName}】您好！您的入职申请已被驳回。<br/><br/><b>驳回原因：</b>${matchedStaff.rejectReason || '未通过门店资质或岗位审核，详情请咨询店长'}<br/><br/>如有疑问请联系门店管理员或重新扫码申请。`,
        '入职申请已驳回',
        { dangerouslyUseHTMLString: true, type: 'error', confirmButtonText: '我知道了' }
      )
      return
    }

    // 检查是否开通系统账号
    if (matchedStaff.hasSystemAccount === false) {
      ElMessage.error(`员工【${matchedStaff.realName}】尚未开通系统登录账号，请联系租户老板开通！`)
      return
    }
    // 检查账号运行状态
    if (matchedStaff.accountStatus === 'DISABLED') {
      ElMessage.error(`员工【${matchedStaff.realName}】系统账号已被暂停使用，请联系门店管理员！`)
      return
    }
    // 校验登录密码 (默认123456)
    const correctPwd = matchedStaff.accountPassword || '123456'
    if (enteredPwd && enteredPwd !== correctPwd && enteredPwd !== '123456') {
      ElMessage.error('员工登录密码错误，请重新核对')
      return
    }

    // 获取该员工被授权的多店铺列表 (支持一人在多家店铺任职)
    const allowedIds = Array.isArray(matchedStaff.allowedStoreIds) && matchedStaff.allowedStoreIds.length > 0
      ? matchedStaff.allowedStoreIds
      : [matchedStaff.storeId || 'S001']

    const allowedStores = systemData.stores.filter(s => allowedIds.includes(s.storeId))
    const finalStores = allowedStores.length > 0 ? allowedStores : systemData.stores.slice(0, 1)

    // 若被授权了 2 家及以上店铺，拦截并弹出【选择本次登录进入的门店】
    if (finalStores.length > 1) {
      pendingStaff.value = matchedStaff
      pendingAllowedStores.value = finalStores
      chooseStoreDialogVisible.value = true
      return
    }

    // 仅授权 1 家店铺，直接绑定并完成登录
    completeStaffLogin(matchedStaff, finalStores[0]?.storeId || 'S001')
    return
  }

  // 2. 非普通员工手机号，走常规租户老板/开发商系统登录通道
  loading.value = true
  try {
    const res: any = await loginApi(loginForm.value)
    localStorage.removeItem('seahorse_demo_mode')
    localStorage.setItem('seahorse_token', res.token)
    localStorage.setItem('seahorse_user', res.realName || res.username)
    localStorage.setItem('seahorse_username', res.username || enteredUname)
    localStorage.setItem('seahorse_real_name', res.realName || res.username || '')
    localStorage.setItem('seahorse_role', res.role)
    try {
      localStorage.setItem('fwpt_auth_token', res.token)
      localStorage.setItem('fwpt_auth_user', JSON.stringify({
        username: res.username || enteredUname,
        nickname: res.realName || res.username || enteredUname,
        role: res.role
      }))
    } catch (e) {}
    localStorage.setItem('seahorse_permissions', JSON.stringify(res.permissions || []))
    localStorage.setItem('seahorse_store_id', res.storeId || '')
    localStorage.setItem('seahorse_store_name', res.storeName || '')
    localStorage.setItem('seahorse_tenant_id', res.tenantId || '')
    localStorage.setItem('seahorse_tenant_name', res.tenantName || '海马智慧门店')
    localStorage.setItem('seahorse_plan', res.plan || 'TRIAL')
    localStorage.setItem('seahorse_store_limit', String(res.storeLimit || 1))
    localStorage.setItem('seahorse_staff_limit', String(res.staffLimit || 3))
    localStorage.setItem('seahorse_expire_date', res.expireDate || '')
    localStorage.setItem('seahorse_deduct_mode', res.deductMode || 'PROPORTIONAL')

    // 同步 Pinia 全局状态
    storeConfig.currentStoreId = res.storeId || ''
    storeConfig.storeName = res.storeName || ''
    storeConfig.tenantId = res.tenantId || ''
    storeConfig.tenantName = res.tenantName || ''
    storeConfig.plan = res.plan || 'TRIAL'
    storeConfig.expireDate = res.expireDate || ''
    storeConfig.storeLimit = res.storeLimit || 1
    storeConfig.staffLimit = res.staffLimit || 3
    storeConfig.stores = res.stores || []

    // 租户老板与平台开发商解除页签限制
    localStorage.removeItem('seahorse_user_menu_paths')
    localStorage.removeItem('seahorse_allowed_stores')
    localStorage.removeItem('seahorse_staff_id')

    if (res.tenantId && res.tenantId !== 'T001' && res.tenantId !== 'T002' && res.tenantId !== 'PLATFORM' && enteredUname !== 'admin' && res.role !== 'PLATFORM_DEVELOPER') {
      // 真实新租户入驻，启用纯净独立工作空间
      localStorage.setItem('seahorse_is_new_tenant', 'true')
      systemData.initNewTenantWorkspace(
        res.tenantName,
        res.storeName || `${res.tenantName} (总店)`,
        res.realName || res.username,
        enteredUname
      )
    } else {
      localStorage.removeItem('seahorse_is_new_tenant')
      systemData.isNewTenant = false
    }
    
    ElMessage.success('登录成功，欢迎使用海马智慧门店！')
    if (res.role === 'PLATFORM_DEVELOPER') {
      router.push('/platform-dashboard')
    } else {
      router.push('/dashboard')
    }
  } catch (e: any) {
    console.error('Backend login failed:', e)
    ElMessage.error(e?.response?.data?.message || e?.message || '账号或密码错误，请核对后重试')
  } finally {
    loading.value = false
  }
}

const handleSelectStoreAndLogin = (storeId: string) => {
  if (!pendingStaff.value) return
  const staff = pendingStaff.value
  chooseStoreDialogVisible.value = false
  completeStaffLogin(staff, storeId)
}

const reportLoginAuditLog = async (
  username: string,
  realName: string,
  role: string,
  storeId?: string,
  storeName?: string,
  tenantId?: string
) => {
  try {
    const tid = tenantId || localStorage.getItem('seahorse_tenant_id') || 'T001'
    const sid = storeId || localStorage.getItem('seahorse_store_id') || 'S001'
    const sname = storeName || localStorage.getItem('seahorse_store_name') || '海马智慧门店'
    await recordClientAuditLogApi({
      action: '账号密码登录',
      actionType: 'LOGIN',
      username: username || 'user',
      realName: realName || username || '员工',
      tenantId: tid,
      storeId: sid,
      storeName: sname,
      status: 'SUCCESS',
      notes: `登录成功 · 身份: ${role || 'STAFF'}`,
      device: navigator.userAgent.includes('Mobile') ? '移动端手机浏览器' : 'Chrome 浏览器 (PC)'
    })
  } catch (err) {
    console.warn('登录审计上报异常:', err)
  }
}

const completeStaffLogin = (staff: any, storeId: string) => {
  const store = systemData.stores.find(s => s.storeId === storeId) ||
                (systemData.stores.length > 0 ? systemData.stores[0] : null)

  // 设置当前工作台生效门店
  storeConfig.currentStoreId = storeId
  storeConfig.storeName = store?.storeName || '丝艺美学·旗舰店'

  localStorage.removeItem('seahorse_demo_mode')
  localStorage.setItem('seahorse_token', `token_staff_${staff.id}_${Date.now()}`)
  localStorage.setItem('seahorse_user', `${staff.realName}【${staff.postName || '员工'}】`)
  localStorage.setItem('seahorse_username', staff.phone || staff.accountUsername || staff.username || String(staff.id))
  localStorage.setItem('seahorse_real_name', staff.realName || '')
  localStorage.setItem('seahorse_role', staff.role || 'TECHNICIAN')
  localStorage.setItem('seahorse_store_id', storeId)
  localStorage.setItem('seahorse_tenant_id', 'T001')
  localStorage.setItem('seahorse_tenant_name', '海马智慧连锁商业')
  localStorage.setItem('seahorse_plan', 'FLAGSHIP')
  localStorage.setItem('seahorse_deduct_mode', 'PROPORTIONAL')
  localStorage.setItem('seahorse_staff_id', String(staff.id))

  // 存储员工专属可见和可使用的功能页签 (保证全员默认均可查阅规章与意见箱 /regulations 及个人中心 /profile)
  const menuPaths = Array.isArray(staff.allowedMenuPaths) && staff.allowedMenuPaths.length > 0
    ? [...staff.allowedMenuPaths]
    : ['/dashboard', '/rooms', '/members', '/products', '/appointments', '/inventory', '/regulations', '/profile']
  if (!menuPaths.includes('/regulations')) {
    menuPaths.push('/regulations')
  }
  if (!menuPaths.includes('/profile')) {
    menuPaths.push('/profile')
  }
  localStorage.setItem('seahorse_user_menu_paths', JSON.stringify(menuPaths))

  // 存储员工授权执业的多店列表与跨店漫游权限
  const allowedStores = Array.isArray(staff.allowedStoreIds) && staff.allowedStoreIds.length > 0
    ? staff.allowedStoreIds
    : [storeId]
  localStorage.setItem('seahorse_allowed_stores', JSON.stringify(allowedStores))
  localStorage.setItem('seahorse_can_cross_store', String(staff.canCrossStore === true))

  // 上报员工登录安全审计日志
  reportLoginAuditLog(
    staff.phone || staff.username || String(staff.id),
    staff.realName,
    staff.role || 'TECHNICIAN',
    storeId,
    store?.storeName,
    'T001'
  )

  ElMessage.success(`登录成功！已成功进入【${store?.storeName}】工作台`)

  // 导航至首页或首个被授权的页签
  if (menuPaths.includes('/dashboard')) {
    router.push('/dashboard')
  } else if (menuPaths.length > 0) {
    router.push(menuPaths[0])
  } else {
    router.push('/profile')
  }
}

const quickMultiStoreStaffLogin = () => {
  loginForm.value.username = '13966668888'
  loginForm.value.password = '123456'
  handleLogin()
}

const handleRegister = async () => {
  const currentType = regType.value
  const email = (regForm.value.email || '').trim()
  const phone = (regForm.value.phone || '').trim()
  const code = (regForm.value.verifyCode || '').trim()
  const username = (regForm.value.username || '').trim()
  const nickname = (regForm.value.nickname || '').trim()
  const password = (regForm.value.password || '').trim()

  // 1. 字段校验
  if (currentType === 'EMAIL') {
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      ElMessage.warning('请输入有效的常用电子邮箱地址')
      return
    }
    if (!code) {
      ElMessage.warning('请输入邮箱接收到的 6 位安全验证码')
      return
    }
  } else if (currentType === 'PHONE') {
    if (!phone || !/^1[3-9]\d{9}$/.test(phone)) {
      ElMessage.warning('请输入有效的 11 位中国大陆手机号码')
      return
    }
    if (!code) {
      ElMessage.warning('请输入手机短信收到的安全验证码')
      return
    }
  }

  if (!username) {
    ElMessage.warning('请设置通行证登录用户名 (全平台唯一)')
    return
  }
  if (username.length < 3 || username.length > 32) {
    ElMessage.warning('用户名长度需在 3 到 32 位之间')
    return
  }
  if (!password || password.length < 6) {
    ElMessage.warning('请设置至少 6 位长度的账户登录密码')
    return
  }

  regLoading.value = true
  try {
    // 2. 首先在 FWPT OneID 统一通行证中心注册
    try {
      await axios.post('/api/v1/auth/register', {
        registerType: currentType,
        username: username,
        realName: nickname || username,
        password: password,
        email: currentType === 'EMAIL' ? email : undefined,
        phone: currentType === 'PHONE' ? phone : undefined,
        code: (currentType === 'EMAIL' || currentType === 'PHONE') ? code : undefined,
        source: 'SEAHORSE_PORTAL'
      })
    } catch (oneIdErr: any) {
      console.warn('OneID registration call notice:', oneIdErr)
      const errMsg = oneIdErr.response?.data?.message || oneIdErr.response?.data?.detail
      if (errMsg && (errMsg.includes('已存在') || errMsg.includes('重复'))) {
        ElMessage.error(errMsg)
        regLoading.value = false
        return
      }
    }

    // 3. 联动开通海马专属商户工作区
    const merchantPayload = {
      contactPhone: phone || (username.match(/^1[3-9]\d{9}$/) ? username : '13800000000'),
      username: username,
      password: password,
      contactName: nickname || username,
      tenantName: `${nickname || username}的智慧门店`,
      initialStoreName: `${nickname || username}的门店 (总店)`,
      smsCode: code || '123456',
      plan: 'TRIAL'
    }

    try {
      await registerMerchantApi(merchantPayload)
      localStorage.setItem('seahorse_is_new_tenant', 'true')
      localStorage.setItem('seahorse_new_store_name', merchantPayload.initialStoreName)
      localStorage.setItem('seahorse_new_tenant_name', merchantPayload.tenantName)
      localStorage.setItem('seahorse_new_boss_name', merchantPayload.contactName)
      localStorage.setItem('seahorse_new_boss_phone', merchantPayload.contactPhone)

      systemData.initNewTenantWorkspace(
        merchantPayload.tenantName,
        merchantPayload.initialStoreName,
        merchantPayload.contactName,
        merchantPayload.contactPhone
      )
      storeConfig.storeName = merchantPayload.initialStoreName
    } catch (merchantErr: any) {
      console.warn('Seahorse merchant tenant registration fallback:', merchantErr)
    }

    // 4. 自动登录并载入系统工作台
    ElMessage.success('🎉 通行证创建成功！已开辟专属门店工作台，正在为您自动登录...')
    loginForm.value.username = username
    loginForm.value.password = password
    activeTab.value = 'login'
    await handleLogin()
  } catch (e: any) {
    ElMessage.error(e.response?.data?.message || e.message || '注册失败，请核对输入信息后重试')
  } finally {
    regLoading.value = false
  }
}

const quickLogin = (uname: string) => {
  // 演示账号清除新租户纯净模式，载入行业演示数据集
  localStorage.removeItem('seahorse_is_new_tenant')

  if (uname === 'foot_spa' || uname === 'foot_spa_boss') {
    injectFootSpaMockData(systemData, storeConfig)
    loginForm.value.username = '13880019988'
    loginForm.value.password = '123456'
    handleLogin()
    return
  }
  if (uname === 'foot_spa_tech') {
    injectFootSpaMockData(systemData, storeConfig)
    loginForm.value.username = '13980888801'
    loginForm.value.password = '123456'
    handleLogin()
    return
  }
  if (uname === 'foot_spa_cashier') {
    injectFootSpaMockData(systemData, storeConfig)
    loginForm.value.username = '13880010106'
    loginForm.value.password = '123456'
    handleLogin()
    return
  }

  if (['beauty_boss', 'dining_boss', 'auto_boss', 'retail_boss'].includes(uname)) {
    const indMap: Record<string, { code: 'BEAUTY' | 'RESTAURANT' | 'AUTO' | 'RETAIL'; name: string; user: string }> = {
      beauty_boss: { code: 'BEAUTY', name: '美容美发美甲', user: '美业老板 (张建华)' },
      dining_boss: { code: 'RESTAURANT', name: '餐饮轻食/正餐', user: '餐饮老板 (刘震宇)' },
      auto_boss: { code: 'AUTO', name: '汽车养护维修', user: '汽修老板 (陆国强)' },
      retail_boss: { code: 'RETAIL', name: '专营零售', user: '零售老板 (周海峰)' }
    }
    const target = indMap[uname]
    const pkg = systemData.switchIndustry(target.code)

    storeConfig.industry = target.code
    storeConfig.stores = pkg.stores as any
    storeConfig.currentStoreId = pkg.stores[0]?.storeId || 'S001'
    storeConfig.spaceAlias = pkg.spaceAlias
    storeConfig.appendActionAlias = pkg.appendActionAlias
    storeConfig.defaultFeeName = pkg.defaultFeeName
    storeConfig.storeName = pkg.stores[0]?.storeName || target.name
    storeConfig.industryCategoryName = target.name
    storeConfig.industryCategoryGroup = target.name

    localStorage.setItem('seahorse_demo_mode', target.code)
    localStorage.setItem('seahorse_stores_data', JSON.stringify(pkg.stores))
    localStorage.setItem('seahorse_token', `token_${uname}_${Date.now()}`)
    localStorage.setItem('seahorse_user', target.user)
    localStorage.setItem('seahorse_username', uname)
    localStorage.setItem('seahorse_real_name', target.user)
    localStorage.setItem('seahorse_role', 'SUPER_ADMIN')
    localStorage.setItem('seahorse_industry', target.code)
    localStorage.setItem('seahorse_store_id', pkg.stores[0]?.storeId || 'S001')
    localStorage.setItem('seahorse_store_name', pkg.stores[0]?.storeName || target.name)
    localStorage.setItem('seahorse_tenant_id', 'T001')
    localStorage.setItem('seahorse_tenant_name', target.name + '连锁商业集团')
    localStorage.setItem('seahorse_plan', 'FLAGSHIP')
    localStorage.setItem('seahorse_deduct_mode', 'PROPORTIONAL')

    reportLoginAuditLog(
      uname,
      target.user,
      'SUPER_ADMIN',
      pkg.stores[0]?.storeId || 'S001',
      pkg.stores[0]?.storeName || (target.name + '连锁商业集团'),
      'T001'
    )

    ElMessage.success(`欢迎进入【${target.name}】真实行业体验模式！`)
    router.push('/dashboard')
    return
  }

  loginForm.value.username = uname
  loginForm.value.password = '123456'
  handleLogin()
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle at 10% 20%, #0f172a 0%, #1e293b 40%, #090d16 100%);
  padding: 36px 20px;
  box-sizing: border-box;
}

.login-layout-wrapper {
  display: flex;
  align-items: stretch;
  max-width: 1240px;
  width: 100%;
  gap: 32px;
}

/* 左侧：宣传广告大屏与核心亮点展区 */
.marketing-showcase-panel {
  flex: 1.25;
  background: rgba(30, 41, 59, 0.72);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(56, 189, 248, 0.22);
  border-radius: 20px;
  padding: 32px 36px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255, 255, 255, 0.1);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  color: #fff;
}

.badge-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 5px 14px;
  background: rgba(56, 189, 248, 0.12);
  border: 1px solid rgba(56, 189, 248, 0.35);
  border-radius: 9999px;
  color: #38bdf8;
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 12px;
}

.pulse-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #38bdf8;
  box-shadow: 0 0 10px #38bdf8;
  animation: pulse-glow 2s infinite;
}

@keyframes pulse-glow {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.5; transform: scale(1.2); }
}

.brand-hero-title {
  font-size: 28px;
  font-weight: 800;
  color: #f8fafc;
  letter-spacing: 0.5px;
  margin: 0 0 4px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.hero-seahorse-icon {
  width: 44px;
  height: 44px;
  border-radius: 13px;
  background: linear-gradient(135deg, #0284c7 0%, #0d9488 55%, #14b8a6 100%);
  color: #ffffff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: inset 0 1px 0.5px rgba(255, 255, 255, 0.45), 0 8px 20px -4px rgba(14, 165, 233, 0.55);
}

.brand-en {
  font-size: 15px;
  font-weight: 400;
  color: #94a3b8;
  margin-left: 6px;
}

.brand-hero-slogan {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 16.5px;
  color: #ffffff;
  font-weight: 800;
  letter-spacing: 0.04em;
  margin: 6px 0 16px 0;
  padding: 6px 16px 6px 12px;
  border-radius: 999px;
  background: linear-gradient(90deg, rgba(2, 132, 199, 0.42) 0%, rgba(13, 148, 136, 0.35) 100%);
  border: 1px solid rgba(56, 189, 248, 0.55);
  box-shadow: 0 4px 16px rgba(2, 132, 199, 0.28);
  width: fit-content;
}

.hero-slogan-sparkle {
  color: #fde047;
  font-size: 15px;
  line-height: 1;
}

.showcase-section-header {
  margin-bottom: 14px;
  padding-bottom: 10px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.section-title-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.star-icon {
  font-size: 18px;
}

.title-text {
  font-size: 17px;
  font-weight: 800;
  color: #ffffff;
  background: linear-gradient(90deg, #ffffff 0%, #38bdf8 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.ad-tag {
  font-size: 10.5px;
  background: linear-gradient(135deg, #f59e0b, #d97706);
  color: #fff;
  padding: 2px 7px;
  border-radius: 4px;
  font-weight: 700;
  margin-left: 6px;
}

.title-sub {
  font-size: 12px;
  color: #94a3b8;
}

/* 宣传高光数据看板 */
.promo-ticker-bar {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  margin-bottom: 12px;
  background: rgba(15, 23, 42, 0.65);
  border: 1px solid rgba(56, 189, 248, 0.2);
  border-radius: 12px;
  padding: 8px 10px;
}

.ticker-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  border-right: 1px solid rgba(255, 255, 255, 0.08);
}

.ticker-item:last-child {
  border-right: none;
}

.t-num {
  font-size: 15px;
  font-weight: 800;
  color: #38bdf8;
  letter-spacing: 0.5px;
}

.t-label {
  font-size: 10.5px;
  color: #94a3b8;
  margin-top: 1px;
}

/* 卖点分类导航选项卡 */
.showcase-tabs-nav {
  display: flex;
  gap: 6px;
  margin-bottom: 12px;
  overflow-x: auto;
  padding-bottom: 4px;
}

.showcase-tabs-nav::-webkit-scrollbar {
  height: 3px;
}

.showcase-tabs-nav::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.15);
  border-radius: 3px;
}

.s-nav-tab {
  font-size: 11.5px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 20px;
  background: rgba(15, 23, 42, 0.5);
  color: #94a3b8;
  border: 1px solid rgba(255, 255, 255, 0.08);
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.2s ease;
}

.s-nav-tab:hover {
  color: #f1f5f9;
  border-color: rgba(56, 189, 248, 0.3);
}

.s-nav-tab.active {
  background: rgba(14, 165, 233, 0.2);
  color: #38bdf8;
  border-color: #38bdf8;
  box-shadow: 0 0 10px rgba(14, 165, 233, 0.25);
}

.feature-card-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 14px;
  max-height: 400px;
  overflow-y: auto;
  padding-right: 4px;
}

.feature-card-list::-webkit-scrollbar {
  width: 4px;
}

.feature-card-list::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.15);
  border-radius: 4px;
}

.feature-card {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 11px 13px;
  background: rgba(15, 23, 42, 0.55);
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 12px;
  transition: all 0.22s ease-in-out;
}

.feature-card:hover {
  background: rgba(30, 41, 59, 0.85);
  border-color: rgba(56, 189, 248, 0.4);
  transform: translateX(4px);
  box-shadow: 0 6px 18px rgba(2, 132, 199, 0.15);
}

.feature-card.highlight-card {
  border-left: 3.5px solid #38bdf8;
}

.f-icon-box {
  font-size: 22px;
  line-height: 1;
  padding: 8px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.05);
  flex-shrink: 0;
}

.f-content {
  flex: 1;
}

.f-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 4px;
}

.f-title {
  font-size: 13.5px;
  font-weight: 700;
  color: #f1f5f9;
}

.f-tag {
  font-size: 10.5px;
  padding: 1px 7px;
  border-radius: 999px;
  background: rgba(56, 189, 248, 0.15);
  color: #38bdf8;
  font-weight: 600;
  border: 1px solid rgba(56, 189, 248, 0.25);
}

.f-desc {
  font-size: 12px;
  color: #cbd5e1;
  line-height: 1.5;
  margin: 0;
}

.f-highlight-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
  margin-top: 6px;
}

.f-chip {
  font-size: 10px;
  color: #38bdf8;
  background: rgba(56, 189, 248, 0.08);
  border: 1px solid rgba(56, 189, 248, 0.2);
  padding: 1px 6px;
  border-radius: 4px;
}

.industry-eco-bar {
  padding-top: 10px;
  border-top: 1px dashed rgba(255, 255, 255, 0.12);
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.eco-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  width: 100%;
}

.eco-lbl {
  font-size: 11.5px;
  font-weight: 600;
  color: #94a3b8;
}

.eco-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.eco-tag {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 6px;
}

.trust-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  width: 100%;
  margin-top: 2px;
}

.trust-item {
  color: #94a3b8;
}

.trust-dot {
  color: #475569;
}

.tag-pink { background: rgba(236, 72, 153, 0.15); color: #f472b6; border: 1px solid rgba(236, 72, 153, 0.3); }
.tag-orange { background: rgba(245, 158, 11, 0.15); color: #fbbf24; border: 1px solid rgba(245, 158, 11, 0.3); }
.tag-blue { background: rgba(2, 132, 199, 0.15); color: #38bdf8; border: 1px solid rgba(2, 132, 199, 0.3); }
.tag-green { background: rgba(16, 185, 129, 0.15); color: #34d399; border: 1px solid rgba(16, 185, 129, 0.3); }

/* 右侧：登录与注册主卡片 */
.login-card {
  width: 480px;
  flex-shrink: 0;
  background: #ffffff;
  border-radius: 20px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
  padding: 30px 34px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.brand-header {
  text-align: center;
  margin-bottom: 20px;
}

.logo.seahorse-badge-logo {
  width: 54px;
  height: 54px;
  border-radius: 16px;
  background: linear-gradient(135deg, #0284c7 0%, #0d9488 55%, #14b8a6 100%);
  color: #ffffff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 10px auto;
  box-shadow: inset 0 1px 0.5px rgba(255, 255, 255, 0.45), 0 10px 22px -6px rgba(13, 148, 136, 0.5);
}

.title {
  font-size: 22px;
  font-weight: 800;
  color: #0f172a;
  letter-spacing: 0.5px;
}

.subtitle {
  font-size: 12px;
  color: #64748b;
  margin-top: 2px;
}

.slogan {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13.5px;
  font-weight: 800;
  color: #0369a1;
  background: linear-gradient(90deg, #e0f2fe 0%, #ccfbf1 55%, #fef3c7 100%);
  border: 1px solid #38bdf8;
  padding: 4px 14px 4px 11px;
  border-radius: 999px;
  margin-top: 8px;
  letter-spacing: 0.03em;
  box-shadow: 0 2px 8px -1px rgba(2, 132, 199, 0.18);
}

.card-slogan-sparkle {
  color: #d97706;
  font-size: 12.5px;
  line-height: 1;
}

.login-tabs {
  margin-top: 8px;
}

.login-form {
  margin-top: 16px;
}

.login-submit-btn {
  width: 100%;
  margin-top: 10px;
  font-weight: 600;
  letter-spacing: 1px;
  height: 42px;
}

.demo-mode-spotlight {
  border: 1.5px solid #0ea5e9 !important;
  background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%) !important;
  box-shadow: 0 0 0 4px rgba(14, 165, 233, 0.14);
  animation: demo-pulse 2.2s infinite ease-in-out;
}
.demo-spotlight-tip {
  font-size: 12px;
  font-weight: 700;
  color: #0369a1;
  margin-bottom: 6px;
}
@keyframes demo-pulse {
  0%, 100% { box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.12); }
  50% { box-shadow: 0 0 0 6px rgba(14, 165, 233, 0.24); }
}
.quick-roles {
  margin-top: 20px;
  padding-top: 14px;
  border-top: 1px dashed #e2e8f0;
}

.quick-title {
  font-size: 12px;
  font-weight: 600;
  color: #64748b;
  margin-bottom: 8px;
}

.role-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

@media (max-width: 1080px) {
  .login-layout-wrapper {
    flex-direction: column;
    align-items: center;
  }
  .marketing-showcase-panel {
    width: 100%;
    box-sizing: border-box;
  }
  .login-card {
    width: 100% !important;
    max-width: 500px;
    box-sizing: border-box;
  }
}

/* 一人多店登录门店选择弹窗 */
.choose-store-modal {
  padding: 4px 8px;
}

.staff-banner {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%);
  border: 1px solid #a7f3d0;
  border-radius: 12px;
  margin-bottom: 20px;
}

.staff-info-col {
  flex: 1;
}

.staff-title {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.staff-name {
  font-size: 16px;
  font-weight: 700;
  color: #064e3b;
}

.staff-phone {
  font-size: 13px;
  color: #047857;
  margin-bottom: 4px;
}

.staff-tip {
  font-size: 12px;
  color: #059669;
}

.store-card-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.store-select-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  background: #ffffff;
  border: 1.5px solid #e2e8f0;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
}

.store-select-card:hover {
  border-color: #0284c7;
  box-shadow: 0 6px 18px rgba(2, 132, 199, 0.12);
  transform: translateY(-2px);
}

.s-main-info {
  flex: 1;
  padding-right: 16px;
}

.s-top-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 6px;
}

.s-name {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}

.s-addr-row {
  display: flex;
  align-items: center;
  font-size: 13px;
  color: #64748b;
  margin-bottom: 6px;
}

.s-menus-row {
  font-size: 12px;
  display: flex;
  align-items: baseline;
  gap: 4px;
}

.s-menus-row .m-lbl {
  color: #0284c7;
  font-weight: 600;
  white-space: nowrap;
}

.s-menus-row .m-val {
  color: #334155;
  line-height: 1.4;
}

.s-action-col {
  flex-shrink: 0;
}

/* 注册分段模式切换器 (对齐首页 OneID 规范) */
.reg-type-selector {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 6px;
  background: #f1f5f9;
  padding: 4px;
  border-radius: 10px;
  margin-top: 10px;
  margin-bottom: 16px;
}

.reg-type-pill {
  padding: 8px 4px;
  border-radius: 8px;
  border: none;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  background: transparent;
  color: #64748b;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.reg-type-pill:hover {
  color: #0f172a;
}

.reg-type-pill.active {
  background: #ffffff;
  color: #0284c7;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.input-sub-tip {
  font-size: 11.5px;
  color: #64748b;
  line-height: 1.5;
  margin-top: 4px;
  width: 100%;
}

.input-sub-tip code {
  color: #0284c7;
  font-weight: 600;
  background: #e0f2fe;
  padding: 1px 5px;
  border-radius: 4px;
}

.account-quick-notice {
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 8px;
  padding: 10px 14px;
  font-size: 12.5px;
  color: #166534;
  margin-bottom: 14px;
  line-height: 1.5;
}

.trial-perk-box {
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  padding: 10px 14px;
  font-size: 12.5px;
  color: #0369a1;
  margin-bottom: 16px;
  line-height: 1.5;
}

.reg-action-btn {
  background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%) !important;
  border: none !important;
  color: #fff !important;
  font-weight: 700;
  height: 44px;
  font-size: 15px;
}

.reg-action-btn:hover {
  background: linear-gradient(135deg, #0369a1 0%, #075985 100%) !important;
}

.terms-footer {
  text-align: center;
  font-size: 12px;
  color: #94a3b8;
  margin-top: 14px;
}

.terms-footer a {
  color: #0284c7;
  text-decoration: none;
}

.terms-footer a:hover {
  text-decoration: underline;
}
</style>
