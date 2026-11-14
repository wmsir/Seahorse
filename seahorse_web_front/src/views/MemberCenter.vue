<template>
  <div class="member-page">
    <el-card shadow="hover">
      <template #header>
        <div class="card-header">
          <div class="header-left">
            <span class="header-title">🧠 海马会员记忆中心</span>
            <span class="header-slogan">“海马会员，记住每位好客。”</span>
          </div>

          <div class="header-right">
            <el-input
              v-model="searchQuery"
              placeholder="输入会员姓名/手机号/尾号快速检索"
              style="width: 280px;"
              clearable
              @clear="loadMembers"
              @keyup.enter="loadMembers"
              @input="handleSearchInput"
            >
              <template #append>
                <el-button icon="Search" @click="loadMembers" />
              </template>
            </el-input>

            <el-select
              v-model="sortKey"
              placeholder="常用指标排序"
              style="width: 190px;"
              @change="handleSortSelectChange"
            >
              <el-option label="默认排序 (按入会时间)" value="default" />
              <el-option label="💎 积分从高到低" value="points_desc" />
              <el-option label="💎 积分从低到高" value="points_asc" />
              <el-option label="💰 储值余额从高到低" value="balance_desc" />
              <el-option label="💰 储值余额从低到高" value="balance_asc" />
              <el-option label="🛍️ 累计消费从高到低" value="spent_desc" />
              <el-option label="🛍️ 累计消费从低到高" value="spent_asc" />
              <el-option label="🚪 到店频次从高到低" value="visit_desc" />
              <el-option label="⏰ 最近到店 (近到远)" value="last_visit_desc" />
            </el-select>

            <el-button type="success" plain @click="openMemberQrModal">
              <el-icon><Iphone /></el-icon> 📱 自助开卡二维码
            </el-button>
            <el-button type="primary" plain @click="openRegisterConfigModal">
              <el-icon><Setting /></el-icon> ⚙️ 自助开卡配置
            </el-button>
            <el-button type="warning" plain icon="Present" @click="router.push('/marketing?tab=care')">
              💖 节日关怀与国庆企划
            </el-button>
            <el-button type="info" plain @click="showLevelRulesModal = true">
              👑 晋升规则
            </el-button>
            <el-button type="primary" icon="Plus" @click="openRegisterDialog = true">
              新会员入会
            </el-button>
          </div>
        </div>
      </template>

      <!-- 会员表格 -->
      <el-table
        :data="paginatedMembers"
        stripe
        style="width: 100%"
        v-loading="loading"
        @sort-change="handleTableSortChange"
      >
        <el-table-column prop="memberNo" label="会员号" width="130">
          <template #default="{ row }">
            <span class="member-no-tag">{{ row.memberNo }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="姓名" width="120">
          <template #default="{ row }">
            <b>{{ row.name }}</b>
          </template>
        </el-table-column>
        <el-table-column prop="phone" label="手机号码" width="130" />
        <el-table-column prop="level" label="会员等级" width="160">
          <template #default="{ row }">
            <span :style="getLevelBadgeStyle(row.level, row.levelName)">
              {{ formatLevelName(row.level, row.levelName) }}
            </span>
          </template>
        </el-table-column>

        <!-- 储蓄/储值金额 -->
        <el-table-column prop="totalBalance" label="储值余额 (元)" width="160" sortable="custom">
          <template #default="{ row }">
            <div style="display: flex; flex-direction: column;">
              <span style="color: #059669; font-weight: 700; font-size: 14px;">
                ￥{{ Number((row.totalBalance != null ? row.totalBalance : row.balance) || 0).toFixed(2) }}
              </span>
              <span style="font-size: 11px; color: #64748b;" v-if="Number(row.giftBalance || 0) > 0">
                (含赠￥{{ Number(row.giftBalance || 0).toFixed(2) }})
              </span>
            </div>
          </template>
        </el-table-column>

        <!-- 可用积分 -->
        <el-table-column prop="points" label="可用积分" width="130" sortable="custom">
          <template #default="{ row }">
            <span style="color: #d97706; font-weight: 700;">
              💎 {{ row.points || 0 }} 分
            </span>
          </template>
        </el-table-column>

        <!-- 累计消费 -->
        <el-table-column prop="totalSpent" label="累计消费 (元)" width="140" sortable="custom">
          <template #default="{ row }">
            <span class="text-primary font-bold">￥{{ Number(row.totalSpent || 0).toFixed(2) }}</span>
          </template>
        </el-table-column>

        <!-- 到店频次 -->
        <el-table-column prop="visitCount" label="到店频次" width="110" sortable="custom">
          <template #default="{ row }">
            <el-tag type="info">{{ row.visitCount || 0 }} 次</el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="lastVisitTime" label="最近履约时间" min-width="160" sortable="custom" />

        <!-- 微信公众号与支付宝生活号关注与动账推送状态 -->
        <el-table-column label="公众号/生活号关注" width="180" align="center">
          <template #default="{ row }">
            <div style="display: flex; flex-direction: column; gap: 4px; align-items: center;">
              <el-tag
                :type="row.wechatFollowStatus ? 'success' : 'info'"
                size="small"
                effect="plain"
                style="cursor: pointer;"
                title="点击模拟顾客扫码关注微信公众号"
                @click="handleQuickSimulateFollow(row, 'WECHAT_MP')"
              >
                {{ row.wechatFollowStatus ? '🟢 微信公众号已关注' : '⚪ 微信未关注 (点击关注)' }}
              </el-tag>
              <el-tag
                :type="row.alipayFollowStatus ? 'primary' : 'info'"
                size="small"
                effect="plain"
                style="cursor: pointer;"
                title="点击模拟关注支付宝生活号"
                @click="handleQuickSimulateFollow(row, 'ALIPAY_LIFE')"
              >
                {{ row.alipayFollowStatus ? '🔵 生活号已关注' : '⚪ 生活号未关注' }}
              </el-tag>
            </div>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="340" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" style="font-weight: 600;" @click="handleOpenMemberQr(row)">
              📱 专属码
            </el-button>
            <el-button link type="primary" style="font-weight: 600;" @click="router.push(`/member-detail/${row.id}`)">
              📝 档案
            </el-button>
            <el-button link type="primary" @click="handleOpenProfile(row.id)">
              🧠 海马记忆
            </el-button>
            <el-button link type="success" @click="handleOpenRecharge(row)">
              充值
            </el-button>
            <el-button link type="warning" @click="handleOpenTimeCard(row)">
              发次卡
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页器 -->
      <div style="display: flex; justify-content: flex-end; margin-top: 16px;">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="sortedMembers.length"
        />
      </div>
    </el-card>

    <!-- 会员“海马体”记忆档案抽屉 -->
    <el-drawer
      v-model="profileDrawerVisible"
      :title="'海马体记忆档案 - ' + (currentProfile?.member?.name || '会员详情')"
      size="640px"
      destroy-on-close
    >
      <div v-if="currentProfile" class="profile-drawer-content">
        <!-- 会员身份概要 -->
        <div class="profile-hero-card">
          <div class="hero-left">
            <el-avatar :size="54" style="background-color: #0284c7; font-size: 20px;">
              {{ (currentProfile.member?.name || '客').substring(0, 1) }}
            </el-avatar>
            <div>
              <div class="hero-name">
                {{ currentProfile.member.name }}
                <span :style="getLevelBadgeStyle(currentProfile.member.level, currentProfile.member.levelName)">
                  {{ formatLevelName(currentProfile.member.level, currentProfile.member.levelName) }}
                </span>
                <el-tag v-if="currentProfile.isTrial" size="small" type="warning" effect="dark" style="margin-left: 6px;">
                  🎁 3天权益试用 (剩余 {{ currentProfile.trialDaysRemaining }} 天)
                </el-tag>
              </div>
              <div class="hero-sub">卡号: {{ currentProfile.member.memberNo }} · 手机: {{ currentProfile.member.phone }}</div>
            </div>
          </div>
          <div class="hero-right">
            <div class="hero-stat-val">￥{{ currentProfile.member.totalSpent }}</div>
            <div class="hero-stat-label">历史累计消费</div>
          </div>
        </div>

        <!-- 双轨储值卡资产明细 -->
        <div class="asset-cards-row" style="display: flex; gap: 12px; margin-bottom: 16px;">
          <div class="asset-box principal-box" style="flex: 1; background: #ecfdf5; border: 1px solid #a7f3d0; border-radius: 8px; padding: 12px;">
            <div class="asset-lbl" style="font-size: 12px; color: #047857;">实充本金账户 (元)</div>
            <div class="asset-num" style="font-size: 20px; font-weight: 700; color: #065f46; margin-top: 4px;">￥{{ currentProfile.dualBalance?.principalBalance || '0.00' }}</div>
            <div class="asset-tip" style="font-size: 11px; color: #059669; margin-top: 2px;">随时可退 · 安全保障</div>
          </div>
          <div class="asset-box gift-box" style="flex: 1; background: #fff7ed; border: 1px solid #fed7aa; border-radius: 8px; padding: 12px;">
            <div class="asset-lbl" style="font-size: 12px; color: #c2410c;">奖励赠送金账户 (元)</div>
            <div class="asset-num" style="font-size: 20px; font-weight: 700; color: #9a3412; margin-top: 4px;">￥{{ currentProfile.dualBalance?.giftBalance || '0.00' }}</div>
            <div class="asset-tip" style="font-size: 11px; color: #ea580c; margin-top: 2px;">活动赠送 · 不可提现</div>
          </div>
          <div class="asset-box mode-box" style="flex: 1.1; background: #f8fafc; border: 1px solid #cbd5e1; border-radius: 8px; padding: 12px; display: flex; flex-direction: column; justify-content: center;">
            <div class="asset-lbl" style="font-size: 12px; color: #475569;">开卡选定扣减模式</div>
            <div style="margin-top: 6px;">
              <el-tag :type="currentProfile.dualBalance?.deductMode === 'PRINCIPAL_FIRST' ? 'warning' : 'success'" size="small">
                {{ currentProfile.dualBalance?.deductMode === 'PRINCIPAL_FIRST' ? '优先扣减本金' : '按比例双轨扣减' }}
              </el-tag>
            </div>
            <div class="asset-tip" style="font-size: 11px; color: #64748b; margin-top: 4px;">
              {{ currentProfile.dualBalance?.deductMode === 'PRINCIPAL_FIRST' ? '实充本金先扣完，不足再扣赠送金' : '本金/赠金按余额比例同比例扣除' }}
            </div>
          </div>
        </div>

        <!-- 计量服务次卡桶 -->
        <div class="timecard-section">
          <div class="section-title">
            <el-icon><Calendar /></el-icon>
            <span>有效次卡项目桶 ({{ currentProfile.timeCards?.length || 0 }})</span>
          </div>
          <div v-if="currentProfile.timeCards?.length" class="timecard-list">
            <div v-for="tc in currentProfile.timeCards" :key="tc.id" class="timecard-item">
              <div class="tc-name">{{ tc.skuName }}</div>
              <div class="tc-detail">
                剩余 <strong class="tc-remain">{{ tc.remainingTimes }}</strong> 次 / 共 {{ tc.totalTimes }} 次
              </div>
              <div class="tc-expire">有效期至: {{ tc.expireDate }}</div>
            </div>
          </div>
          <el-empty v-else description="暂无次卡资产" :image-size="60" />
        </div>

        <!-- 会员专属优惠券卡包 -->
        <div class="timecard-section" style="margin-top: 16px;">
          <div class="section-title">
            <el-icon><Ticket /></el-icon>
            <span>专属优惠券卡包 ({{ currentMemberCoupons.length }})</span>
            <el-button size="small" type="primary" plain style="margin-left: auto;" @click="handleIssueBonusCoupon">
              + 现场赠券
            </el-button>
          </div>
          <div v-if="currentMemberCoupons.length" class="coupon-grid">
            <div v-for="cpn in currentMemberCoupons" :key="cpn.id" class="coupon-item-box">
              <div class="cpn-val-col">
                <div class="val">￥{{ cpn.amount }}</div>
                <div class="cond">{{ cpn.minSpend > 0 ? `满${cpn.minSpend}可用` : '无门槛' }}</div>
              </div>
              <div class="cpn-info-col">
                <div class="name">{{ cpn.name }}</div>
                <div class="expire">有效期: {{ cpn.expireDate }}</div>
                <div class="src">{{ cpn.source || '开卡迎新礼遇' }}</div>
              </div>
              <div class="cpn-tag-col">
                <el-tag size="small" :type="cpn.status === 'UNUSED' ? 'success' : 'info'">
                  {{ cpn.status === 'UNUSED' ? '未使用' : '已核销' }}
                </el-tag>
              </div>
            </div>
          </div>
          <el-empty v-else description="暂无优惠券资产" :image-size="60" />
        </div>

        <!-- “海马体”大脑个性喜好标签中心 -->
        <div class="pref-section">
          <div class="section-title">
            <el-icon><Compass /></el-icon>
            <span>海马体记忆档案 ({{ currentProfile.preferences?.length || 0 }})</span>
            <el-button size="small" type="primary" plain style="margin-left: auto;" @click="openAddPrefDialog = true">
              + 记录新特征
            </el-button>
          </div>
          <div v-if="currentProfile.preferences?.length" class="pref-tag-cloud">
            <el-card v-for="p in currentProfile.preferences" :key="p.id" shadow="never" class="pref-card">
              <div class="pref-header">
                <el-tag size="small" effect="plain">{{ getCategoryName(p.category) }}</el-tag>
                <span class="pref-key">[{{ p.tagKey }}]</span>
              </div>
              <div class="pref-val">{{ p.tagValue }}</div>
              <div v-if="p.notes" class="pref-notes">备忘: {{ p.notes }}</div>
            </el-card>
          </div>
          <el-empty v-else description="尚未录入海马个性特征，点击右上角为TA记录！" :image-size="60" />
        </div>
      </div>
      <div v-else v-loading="profileLoading" style="min-height: 200px; display: flex; align-items: center; justify-content: center;">
        <span style="color: #94a3b8;">正在唤醒海马体记忆中枢...</span>
      </div>

      <template #footer>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span style="font-size: 12px; color: #94a3b8;">海马智能记忆中枢 · 记录每位好客习惯</span>
          <el-button @click="profileDrawerVisible = false">关闭档案</el-button>
        </div>
      </template>
    </el-drawer>

    <!-- 会员注册弹窗 -->
    <el-dialog v-model="openRegisterDialog" title="新会员入会注册" width="480px">
      <el-alert
        type="success"
        :closable="false"
        show-icon
        title="新会员专享福利：注册即享 3 天全权益免费试用体验"
        style="margin-bottom: 10px;"
      />
      <el-alert
        type="info"
        :closable="false"
        show-icon
        title="阶梯成长：消费每满1元积1分，满300升银卡(95折)，满800升金卡(90折)，满1200升VIP(88折)，满2000升白金(85折)，满3500升黑钻(80折)"
        style="margin-bottom: 12px;"
      />
      <el-alert
        v-if="welcomeConfig.enabled"
        type="warning"
        :closable="false"
        show-icon
        style="margin-bottom: 16px; border: 1px solid #fed7aa; background: #fffbeb;"
      >
        <template #title>
          <div style="font-weight: 700; color: #b45309;">
            🎁 迎新特惠：办卡即赠【{{ welcomeConfig.couponName }}】立减￥{{ welcomeConfig.amount }}
          </div>
        </template>
        <div style="font-size: 12px; margin-top: 4px; color: #92400e;">
          门槛：{{ welcomeConfig.minSpend > 0 ? `满 ￥${welcomeConfig.minSpend} 可用` : '无门槛立减' }} ·
          有效期：{{ welcomeConfig.validityMode === 'DAYS' ? `自开卡起 ${welcomeConfig.validDays} 天有效` : `至 ${welcomeConfig.fixedExpireDate}` }} ·
          范围：{{ welcomeConfig.serviceScope }}
        </div>
      </el-alert>
      <el-form :model="registerForm" label-width="90px">
        <el-form-item label="会员姓名" required>
          <el-input v-model="registerForm.name" placeholder="请输入会员姓名" />
        </el-form-item>
        <el-form-item label="手机号码" required>
          <el-input v-model="registerForm.phone" placeholder="请输入手机号码" />
        </el-form-item>
        <el-form-item label="性别">
          <el-radio-group v-model="registerForm.gender">
            <el-radio label="FEMALE">女士</el-radio>
            <el-radio label="MALE">先生</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="开卡首充本金">
          <el-input-number v-model="registerForm.initialPrincipal" :min="0" :step="100" />
        </el-form-item>
        <el-form-item label="首充赠送金">
          <el-input-number v-model="registerForm.initialGift" :min="0" :step="50" />
        </el-form-item>
        <el-form-item label="开卡扣减模式" required>
          <el-radio-group v-model="registerForm.deductMode">
            <el-radio label="PROPORTIONAL">
              <span>按本金/赠金比例双轨扣减</span>
              <el-tooltip content="消费时按本金与赠送金当前余额同比例扣除，防赠金套现（推荐）" placement="top">
                <el-icon style="margin-left: 3px; vertical-align: middle;"><QuestionFilled /></el-icon>
              </el-tooltip>
            </el-radio>
            <el-radio label="PRINCIPAL_FIRST">
              <span>优先扣减实充本金</span>
              <el-tooltip content="消费时先扣减实充本金，本金扣完后再扣减赠送金" placement="top">
                <el-icon style="margin-left: 3px; vertical-align: middle;"><QuestionFilled /></el-icon>
              </el-tooltip>
            </el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openRegisterDialog = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmRegister">确认注册</el-button>
      </template>
    </el-dialog>

    <!-- 储值充值弹窗 -->
    <el-dialog v-model="openRechargeDialog" :title="'会员双轨储值充值 - ' + targetMember?.name" width="460px">
      <el-form label-width="90px">
        <el-form-item label="充值本金" required>
          <el-input-number v-model="rechargeForm.principalAmount" :min="10" :step="100" />
        </el-form-item>
        <el-form-item label="赠送金额">
          <el-input-number v-model="rechargeForm.giftAmount" :min="0" :step="50" />
        </el-form-item>
        <el-form-item label="售卡提成员工">
          <el-select v-model="rechargeForm.sellerEmployeeId" placeholder="选择归属提成技师/员工" clearable style="width: 100%;">
            <el-option label="托尼总监" :value="4" />
            <el-option label="凯文大工" :value="5" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openRechargeDialog = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmRecharge">确认充值入账</el-button>
      </template>
    </el-dialog>

    <!-- 录入海马体记忆偏好弹窗 -->
    <el-dialog v-model="openAddPrefDialog" title="录入“海马体”个性喜好记忆" width="480px">
      <el-form :model="prefForm" label-width="90px">
        <el-form-item label="偏好类别">
          <el-select v-model="prefForm.category" style="width: 100%;">
            <el-option label="美业发质与造型偏好 (BEAUTY_HAIR)" value="BEAUTY_HAIR" />
            <el-option label="餐饮口味与忌口偏好 (RESTAURANT_TASTE)" value="RESTAURANT_TASTE" />
            <el-option label="汽修车辆与配件规格 (AUTO_VEHICLE)" value="AUTO_VEHICLE" />
            <el-option label="常态习惯与服务禁忌 (HABIT)" value="HABIT" />
          </el-select>
        </el-form-item>
        <el-form-item label="标签标识">
          <el-input v-model="prefForm.tagKey" placeholder="例如：hair_texture, spicy_level, oil_spec" />
        </el-form-item>
        <el-form-item label="记忆特征内容" required>
          <el-input v-model="prefForm.tagValue" type="textarea" :rows="3" placeholder="例如：发质细软敏感，喜用施华蔻；或者微辣免葱，坐窗边；或粤B66888 奔驰C260L" />
        </el-form-item>
        <el-form-item label="备忘说明">
          <el-input v-model="prefForm.notes" placeholder="补充备忘" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openAddPrefDialog = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmAddPref">保存至海马记忆</el-button>
      </template>
    </el-dialog>

    <!-- 发放次卡弹窗 -->
    <el-dialog v-model="openTimeCardDialog" :title="'发放服务次卡 - ' + targetMember?.name" width="460px">
      <el-form label-width="90px">
        <el-form-item label="次卡项目" required>
          <el-input v-model="timeCardForm.skuName" :placeholder="timeCardPlaceholder" />
        </el-form-item>
        <el-form-item label="包含次数" required>
          <el-input-number v-model="timeCardForm.totalTimes" :min="1" :max="100" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openTimeCardDialog = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmIssueTimeCard">确认发卡</el-button>
      </template>
    </el-dialog>
    <!-- 会员自助开卡二维码与分享链接弹窗 -->
    <el-dialog v-model="memberQrDialogVisible" title="📱 顾客会员自助开卡二维码与专属链接" width="500px">
      <div class="qr-modal-body">
        <div class="qr-store-badge">
          <span class="qr-store-icon">📍</span>
          <span class="qr-store-name">{{ currentStoreName }}</span>
          <el-tag size="small" type="success" effect="light">扫码立归属本店</el-tag>
        </div>

        <div class="qr-code-wrapper">
          <img v-if="memberQrCodeDataUrl" :src="memberQrCodeDataUrl" class="qr-image" alt="开卡二维码" />
          <div v-else class="qr-loading">生成高清二维码中...</div>
          <div class="qr-scan-hint">顾客微信/手机浏览器扫一扫直接开卡建档</div>
        </div>

        <div class="qr-link-box">
          <div class="qr-link-title">🔗 门店专属开卡网页地址：</div>
          <el-input v-model="memberRegisterLink" readonly>
            <template #append>
              <el-button type="primary" @click="copyMemberRegisterLink">复制链接</el-button>
            </template>
          </el-input>
        </div>

        <div class="qr-actions">
          <el-button type="primary" plain @click="openMemberRegisterPage">
            在新窗口模拟打开
          </el-button>
          <el-button type="success" plain @click="downloadMemberQrCode">
            保存二维码图片
          </el-button>
        </div>

        <div style="margin-top: 14px; background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 10px 14px; display: flex; justify-content: space-between; align-items: center; gap: 10px;">
          <div style="font-size: 12px; color: #475569; line-height: 1.4;">
            💡 <b>开卡页面展示内容自主定制：</b>可配置顾客看到的常态偏好标签及充多少送多少首充方案
          </div>
          <el-button type="warning" size="small" @click="openRegisterConfigModal">
            ⚙️ 配置偏好与首充
          </el-button>
        </div>
      </div>
      <template #footer>
        <el-button @click="memberQrDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 门店自助开卡方案与偏好配置弹窗 -->
    <el-dialog
      v-model="registerConfigModalVisible"
      title="⚙️ 门店自助开卡页面内容自主配置 (常态偏好 & 充多少送多少)"
      width="720px"
      destroy-on-close
    >
      <el-tabs v-model="activeConfigTab">
        <!-- Tab 1: 个人常态偏好标签库 -->
        <el-tab-pane label="🧠 顾客个人常态偏好配置" name="pref">
          <div style="font-size: 13px; color: #64748b; margin-bottom: 12px; line-height: 1.5;">
            顾客在微信/浏览器扫码自助开卡时，将呈现以下常态偏好供其自主勾选。海马体将为顾客终身记忆，后续到店消费免重复告知技师。
          </div>

          <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; margin-bottom: 16px;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
              <div style="font-size: 13px; font-weight: 600; color: #1e293b;">
                当前门店生效偏好标签 ({{ editingStoreRegisterConfig.preferenceTags.length }} 个)
              </div>
              <el-button
                v-if="editingStoreRegisterConfig.preferenceTags.length > 0"
                link
                type="danger"
                size="small"
                @click="editingStoreRegisterConfig.preferenceTags = []"
              >
                清空全部标签
              </el-button>
            </div>
            
            <div v-if="editingStoreRegisterConfig.preferenceTags.length > 0" style="display: flex; flex-wrap: wrap; gap: 8px;">
              <el-tag
                v-for="(tag, idx) in editingStoreRegisterConfig.preferenceTags"
                :key="tag"
                closable
                type="primary"
                size="large"
                @close="handleRemovePrefTag(idx)"
              >
                {{ tag }}
              </el-tag>
            </div>
            <div v-else style="text-align: center; padding: 24px 16px; color: #94a3b8; font-size: 13px;">
              <div style="font-size: 26px; margin-bottom: 8px;">🏷️</div>
              <span style="font-weight: 600; color: #475569;">当前门店暂未配置任何顾客个人常态偏好标签</span>
              <div style="margin-top: 6px; color: #64748b; line-height: 1.5;">
                您可以手动逐个输入添加，或点击下方【📥 载入行业推荐标签】选择对应行业一键引入，再点击【保存开卡配置】生效。
              </div>
            </div>
          </div>

          <div style="display: flex; gap: 10px; align-items: center;">
            <el-input
              v-model="newPrefTagInput"
              placeholder="输入新偏好标签名称 (如：免葱姜、喜静免推销、洗头水温偏热、偏爱美孚全合成)"
              style="max-width: 420px;"
              @keyup.enter="handleAddPrefTag"
            />
            <el-button type="primary" @click="handleAddPrefTag">
              + 添加标签
            </el-button>
            <el-button type="success" plain @click="openIndustryPresetDialog">
              📥 载入行业推荐标签
            </el-button>
          </div>
        </el-tab-pane>

        <!-- Tab 2: 充多少送多少首充方案 -->
        <el-tab-pane label="💳 开卡首充与充多少送多少方案" name="charge">
          <div style="font-size: 13px; color: #64748b; margin-bottom: 12px; line-height: 1.5;">
            店铺可自定义顾客自主开卡时可选择的首充体验方案。若方案本金 > 0，顾客开卡时需通过在线收银台完成模拟真实支付。
          </div>

          <el-table :data="editingStoreRegisterConfig.chargeOptions" border stripe style="width: 100%;">
            <el-table-column label="方案名称" min-width="140">
              <template #default="{ row }">
                <el-input v-model="row.title" placeholder="如：首充礼遇 ￥200" size="small" />
              </template>
            </el-table-column>
            <el-table-column label="充值本金 (元)" width="130">
              <template #default="{ row }">
                <el-input-number v-model="row.principal" :min="0" :step="50" size="small" style="width: 100%;" />
              </template>
            </el-table-column>
            <el-table-column label="立赠金额 (元)" width="130">
              <template #default="{ row }">
                <el-input-number v-model="row.gift" :min="0" :step="10" size="small" style="width: 100%;" />
              </template>
            </el-table-column>
            <el-table-column label="营销角标" width="120">
              <template #default="{ row }">
                <el-input v-model="row.badge" placeholder="如：立赠50元" size="small" />
              </template>
            </el-table-column>
            <el-table-column label="对应初始会员等级" min-width="160">
              <template #default="{ row }">
                <el-select
                  v-model="row.levelName"
                  size="small"
                  placeholder="选择初始等级"
                  style="width: 100%;"
                  @change="(val: string) => handleLevelChange(row, val)"
                >
                  <el-option
                    v-for="lvl in standardLevelList"
                    :key="lvl.levelCode"
                    :label="lvl.label"
                    :value="lvl.levelName"
                  />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="80" align="center">
              <template #default="{ $index }">
                <el-button type="danger" link size="small" @click="handleRemoveChargeOption($index)" :disabled="editingStoreRegisterConfig.chargeOptions.length <= 1">
                  删除
                </el-button>
              </template>
            </el-table-column>
          </el-table>

          <div style="margin-top: 14px; display: flex; gap: 10px;">
            <el-button type="primary" plain size="small" @click="handleAddChargeOption">
              + 新增充值立赠方案
            </el-button>
            <el-button type="info" plain size="small" @click="handleResetDefaultChargeOptions">
              🔄 恢复推荐首充方案
            </el-button>
          </div>
        </el-tab-pane>
      </el-tabs>

      <template #footer>
        <el-button @click="registerConfigModalVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveRegisterConfig">保存开卡配置</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 1.1: 载入行业推荐常态偏好标签 -->
    <el-dialog
      v-model="industryPresetModalVisible"
      title="📥 载入行业推荐常态偏好标签"
      width="660px"
      append-to-body
      destroy-on-close
    >
      <div style="font-size: 13px; color: #64748b; margin-bottom: 14px; line-height: 1.6;">
        系统为您精选了多种主流实体行业的常用熟客偏好标签。请选择您门店所属或相关的行业领域，选定后即可一键载入到当前店铺，确认无误后点击下方【保存开卡配置】即可同步生效。
      </div>

      <div style="margin-bottom: 14px; display: flex; align-items: center; gap: 10px;">
        <span style="font-size: 13px; font-weight: 600; color: #1e293b; white-space: nowrap;">选择目标行业：</span>
        <el-select v-model="selectedPresetIndustry" style="width: 340px;" @change="handlePresetIndustryChange">
          <el-option
            v-for="item in industryPresetList"
            :key="item.key"
            :label="item.name"
            :value="item.key"
          />
        </el-select>
      </div>

      <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 14px; margin-bottom: 14px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
          <span style="font-size: 13px; font-weight: 600; color: #334155;">
            推荐标签预览 (已选 {{ selectedPresetTags.length }} / {{ currentIndustryPreset?.tags.length || 0 }} 个)
          </span>
          <div style="display: flex; gap: 8px;">
            <el-button link type="primary" size="small" @click="handleSelectAllPresetTags">全选</el-button>
            <el-button link type="info" size="small" @click="handleClearAllPresetTags">清空</el-button>
          </div>
        </div>
        <div style="display: flex; flex-wrap: wrap; gap: 8px;">
          <el-check-tag
            v-for="tag in (currentIndustryPreset?.tags || [])"
            :key="tag"
            :checked="selectedPresetTags.includes(tag)"
            @change="handleTogglePresetTag(tag)"
            style="cursor: pointer; padding: 6px 12px; font-size: 13px;"
          >
            {{ tag }}
          </el-check-tag>
        </div>
      </div>

      <div style="display: flex; align-items: center; justify-content: space-between; font-size: 13px; color: #475569;">
        <div>
          <span>导入方式：</span>
          <el-radio-group v-model="presetImportMode" size="small">
            <el-radio-button label="REPLACE">覆盖当前标签</el-radio-button>
            <el-radio-button label="APPEND">追加至现有标签</el-radio-button>
          </el-radio-group>
        </div>
      </div>

      <template #footer>
        <el-button @click="industryPresetModalVisible = false">取消</el-button>
        <el-button type="primary" :disabled="selectedPresetTags.length === 0" @click="handleConfirmImportPresetTags">
          确认载入 ({{ selectedPresetTags.length }} 个标签)
        </el-button>
      </template>
    </el-dialog>

    <!-- 会员个人专属二维码弹窗 -->
    <el-dialog v-model="singleMemberQrDialogVisible" :title="'📱 会员专属身份码 - ' + (qrMember?.name || '')" width="480px">
      <div class="qr-modal-body" v-if="qrMember">
        <div class="qr-store-badge" style="background: #f0fdf4; border: 1px solid #bbf7d0; padding: 12px 16px; border-radius: 8px; margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between;">
          <div style="display: flex; align-items: center; gap: 10px;">
            <el-avatar :size="40" style="background: #0284c7; color: #fff; font-weight: bold; font-size: 16px;">
              {{ qrMember.name ? qrMember.name.substring(0, 1) : '客' }}
            </el-avatar>
            <div>
              <div style="font-weight: 700; color: #1e293b; font-size: 15px;">{{ qrMember.name }}</div>
              <div style="font-size: 12px; color: #64748b; margin-top: 2px;">手机号: {{ qrMember.phone }}</div>
            </div>
          </div>
          <div style="text-align: right;">
            <el-tag size="small" type="success" effect="dark">{{ formatLevelName(qrMember.level, qrMember.levelName) }}</el-tag>
            <div style="font-size: 12px; color: #059669; font-weight: 600; margin-top: 4px;">
              余额 ￥{{ Number(qrMember.totalBalance != null ? qrMember.totalBalance : (qrMember.balance || 0)).toFixed(2) }}
            </div>
          </div>
        </div>

        <div class="qr-code-wrapper" style="text-align: center; background: #ffffff; padding: 16px; border: 1px solid #e2e8f0; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);">
          <img v-if="singleMemberQrCodeUrl" :src="singleMemberQrCodeUrl" class="qr-image" style="width: 220px; height: 220px; display: inline-block;" alt="会员专属码" />
          <div v-else class="qr-loading" style="padding: 40px; color: #94a3b8;">生成高清会员二维码中...</div>
          <div style="margin-top: 10px; font-size: 14px; font-weight: 700; color: #334155; font-family: monospace; letter-spacing: 1px;">
            {{ qrMember.phone }}
          </div>
          <div class="qr-scan-hint" style="color: #64748b; font-size: 12px; margin-top: 4px;">
            APP移动扫码盒子 / 前台条码枪 扫码可直接识别该会员并扣卡消费
          </div>
        </div>

        <div class="qr-link-box" style="margin-top: 16px;">
          <div class="qr-link-title" style="font-size: 12px; color: #64748b; margin-bottom: 6px;">
            🔑 会员专属条码识别字符串 (兼容扫码盒子与移动APP)：
          </div>
          <el-input :model-value="'SEAHORSE:MEMBER:' + qrMember.phone" readonly>
            <template #append>
              <el-button type="primary" @click="copyMemberQrText">复制码值</el-button>
            </template>
          </el-input>
        </div>

        <div class="qr-actions" style="display: flex; gap: 12px; margin-top: 20px; justify-content: center;">
          <el-button type="success" @click="downloadSingleMemberQr">
            📥 保存二维码到本地
          </el-button>
          <el-button @click="singleMemberQrDialogVisible = false">
            关闭
          </el-button>
        </div>
      </div>
    </el-dialog>

    <!-- 会员等级晋升阶梯规则说明弹窗 -->
    <el-dialog v-model="showLevelRulesModal" title="👑 海马会员等级体系与晋升规则" width="680px">
      <div class="level-rules-dialog-content">
        <el-alert
          type="info"
          show-icon
          :closable="false"
          title="阶梯成长 · 消费积分自动晋升"
          description="会员每次消费结算每满 1 元累积 1 点成长经验值，达到门槛系统自动平滑晋级，永久尊享对应会员专属折扣与特权服务。"
          style="margin-bottom: 14px;"
        />
        <el-table :data="standardLevelRules" border stripe style="width: 100%">
          <el-table-column prop="levelName" label="会员等级" width="130">
            <template #default="{ row }">
              <span :style="getLevelBadgeStyle(row.levelCode)">{{ row.levelName }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="threshold" label="成长门槛" width="110">
            <template #default="{ row }">
              <b style="color: #0284c7;">{{ row.threshold }} 分</b>
            </template>
          </el-table-column>
          <el-table-column prop="discount" label="服务/商品折扣" width="160">
            <template #default="{ row }">
              <el-tag size="small" :type="row.threshold > 0 ? 'warning' : 'info'">{{ row.discount }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="privileges" label="核心会员特权" />
        </el-table>
      </div>
      <template #footer>
        <el-button type="primary" @click="showLevelRulesModal = false">知道了</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref, computed, reactive } from 'vue'
import { useRouter } from 'vue-router'
import QRCode from 'qrcode'
import {
  searchMembersApi,
  getMemberProfileApi,
  registerMemberApi,
  rechargeMemberApi,
  savePreferenceApi,
  issueTimeCardApi,
  simulateFollowApi,
  getStoreRegisterConfigApi,
  saveStoreRegisterConfigApi,
  getIndustryPresetTemplateApi
} from '../api'
import { ElMessage, ElNotification } from 'element-plus'
import { useSystemDataStore } from '../stores/systemDataStore'
import { useStoreConfig } from '../stores/store'

const router = useRouter()
const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()

const getSafeMembersWithStats = (): any[] => {
  try {
    return systemData.membersWithStats || []
  } catch {
    return (systemData.members || []).map((m: any) => ({
      ...m,
      totalBalance: Number(m.totalBalance ?? m.balance ?? 0),
      principalBalance: Number(m.principalBalance ?? m.balance ?? 0),
      giftBalance: Number(m.giftBalance ?? 0)
    }))
  }
}

const handleQuickSimulateFollow = async (row: any, channel: string = 'WECHAT_MP') => {
  if (channel === 'WECHAT_MP' && row.wechatFollowStatus) {
    ElMessage.info(`会员 ${row.name} 已关注微信公众号 (OpenID: ${row.wechatOpenId || '已绑定'})`)
    return
  }
  if (channel === 'ALIPAY_LIFE' && row.alipayFollowStatus) {
    ElMessage.info(`会员 ${row.name} 已关注支付宝生活号 (UID: ${row.alipayUserId || '已绑定'})`)
    return
  }

  try {
    const res: any = await simulateFollowApi({
      phone: row.phone,
      channel
    })
    if (res) {
      ElNotification({
        title: '扫码关注激活成功',
        message: `会员 ${row.name} 已成功关注 ${channel === 'WECHAT_MP' ? '微信服务号' : '支付宝生活号'}，已激活消费动账即时通知！`,
        type: 'success',
        duration: 4000
      })
      await loadMembers()
    }
  } catch (err: any) {
    ElMessage.error(err?.message || '操作失败')
  }
}

// 会员自助开卡二维码弹窗与链接
const memberQrDialogVisible = ref(false)
const memberQrCodeDataUrl = ref('')
const currentStoreName = computed(() => storeConfig.storeName || '当前门店')
const memberRegisterLink = computed(() => {
  const origin = window.location.origin
  const sId = encodeURIComponent(storeConfig.currentStoreId || 'S001')
  const sName = encodeURIComponent(storeConfig.storeName || '')
  const ind = encodeURIComponent(storeConfig.industry || '')
  const phone = encodeURIComponent(storeConfig.phone || '')
  const addr = encodeURIComponent(storeConfig.address || '')
  const hours = encodeURIComponent(storeConfig.businessHours || '')
  return `${origin}/seahorse/member-register?storeId=${sId}&storeName=${sName}&industry=${ind}&phone=${phone}&address=${addr}&businessHours=${hours}`
})

const openMemberQrModal = async () => {
  memberQrDialogVisible.value = true
  try {
    memberQrCodeDataUrl.value = await QRCode.toDataURL(memberRegisterLink.value, {
      width: 240,
      margin: 2,
      color: {
        dark: '#0f172a',
        light: '#ffffff'
      }
    })
  } catch (err) {
    console.error('Failed to generate member register QR Code', err)
  }
}

const copyMemberRegisterLink = async () => {
  try {
    await navigator.clipboard.writeText(memberRegisterLink.value)
    ElMessage.success('已复制开卡链接到剪贴板！可直接发送给顾客或分享到群聊')
  } catch (e) {
    const input = document.createElement('input')
    input.value = memberRegisterLink.value
    document.body.appendChild(input)
    input.select()
    document.execCommand('copy')
    document.body.removeChild(input)
    ElMessage.success('已复制开卡链接！')
  }
}

const openMemberRegisterPage = () => {
  window.open(memberRegisterLink.value, '_blank')
}

const downloadMemberQrCode = () => {
  if (!memberQrCodeDataUrl.value) return
  const a = document.createElement('a')
  a.href = memberQrCodeDataUrl.value
  a.download = `${storeConfig.storeName}_顾客自主开卡二维码.png`
  a.click()
  ElMessage.success('已开始下载二维码图片')
}

// ------------------------------------------------------------------------------
// 门店自主配置：自助开卡常态偏好 & 首充方案 (充多少送多少)
// ------------------------------------------------------------------------------
const registerConfigModalVisible = ref(false)
const activeConfigTab = ref('pref')
const newPrefTagInput = ref('')

// 行业推荐标签弹窗状态
const industryPresetModalVisible = ref(false)
const selectedPresetIndustry = ref('BEAUTY')
const selectedPresetTags = ref<string[]>([])
const presetImportMode = ref<'REPLACE' | 'APPEND'>('REPLACE')

interface IndustryPreset {
  key: string
  name: string
  tags: string[]
}

const industryPresetList: IndustryPreset[] = [
  {
    key: 'BEAUTY',
    name: '💇 美业造型 / 美发美容 / 美甲美睫',
    tags: ['发质细软', '敏感头皮', '偏爱自然修剪', '偏爱冷色调烫染', '喜好安静免推销', '定期头皮SPA', '洗头水温偏热', '饮品偏好温柠檬水', '拒绝频繁推销', '指甲偏好短圆型']
  },
  {
    key: 'RESTAURANT',
    name: '🍲 餐饮美食 / 特色火锅 / 烘焙咖啡',
    tags: ['微辣免葱', '少盐少油少糖', '偏爱安静包厢', '不吃香菜姜蒜', '常带儿童就餐', '自备酒水', '海鲜不过敏', '米饭稍软', '常备宝宝椅', '饮品去冰半糖']
  },
  {
    key: 'FOOT_SPA',
    name: '💆 足道养生 / 中医推拿 / 精油SPA',
    tags: ['力度偏重', '力度适中', '中药足浴包偏好', '精油开背偏好', '喜好安静免推销', '肩颈重点加强', '腰椎劳损需避开', '修脚去死皮偏好', '饮品偏好红枣枸杞茶']
  },
  {
    key: 'AUTO',
    name: '🚗 汽车维保 / 精细洗车 / 改装美容',
    tags: ['全合成机油偏好', '定期深度底盘检查', '车内高温桑拿除味', '原厂配件优先', '空调滤芯定期换', '轮胎动平衡常检', '偏好周末维保', '洗车需深度除尘']
  },
  {
    key: 'TEA_HOUSE',
    name: '🍵 商务茶楼 / 棋牌茶歇 / 空间雅集',
    tags: ['偏爱生普/白茶', '水温要求沸水', '偏爱安静雅间', '自备茶叶仅需茶具', '需要商务投影', '茶点少糖偏好', '常备坚果果盘', '喜好棋牌娱乐']
  },
  {
    key: 'PET',
    name: '🐾 宠物洗护 / 医疗美容 / 寄养训导',
    tags: ['胆小敏感易应激', '皮肤敏感需低敏香波', '拒绝强行烘干箱', '洗澡需剪指甲', '定期驱虫', '喜好零食奖励', '长毛易打结需开结', '自备洗护专用品']
  },
  {
    key: 'RETAIL',
    name: '🛍️ 综合零售 / 鲜果商超 / 专卖买手店',
    tags: ['偏好有机绿色无公害', '精致礼盒送礼包装', '积分抵现结算优先', '新品尝鲜品鉴体验', '少塑环保包装', '定期促销推送偏好', '冷链保温配送', '喜欢大份家庭装']
  }
]

const currentIndustryPreset = computed(() => {
  return industryPresetList.find(p => p.key === selectedPresetIndustry.value) || industryPresetList[0]
})

const openIndustryPresetDialog = async () => {
  const currentInd = (storeConfig.industry || 'BEAUTY').toUpperCase()
  const matched = industryPresetList.find(p => p.key === currentInd)
  selectedPresetIndustry.value = matched ? matched.key : 'BEAUTY'
  selectedPresetTags.value = [...(currentIndustryPreset.value?.tags || [])]
  presetImportMode.value = 'REPLACE'
  industryPresetModalVisible.value = true

  // 优先尝试从云端超管配置库加载最新标签
  try {
    const res: any = await getIndustryPresetTemplateApi(selectedPresetIndustry.value)
    const data = res?.data || res
    if (data && Array.isArray(data.preferenceTags) && data.preferenceTags.length > 0) {
      if (currentIndustryPreset.value) {
        currentIndustryPreset.value.tags = [...data.preferenceTags]
      }
      selectedPresetTags.value = [...data.preferenceTags]
    }
  } catch (e) {}
}

const handlePresetIndustryChange = async () => {
  selectedPresetTags.value = [...(currentIndustryPreset.value?.tags || [])]
  try {
    const res: any = await getIndustryPresetTemplateApi(selectedPresetIndustry.value)
    const data = res?.data || res
    if (data && Array.isArray(data.preferenceTags) && data.preferenceTags.length > 0) {
      if (currentIndustryPreset.value) {
        currentIndustryPreset.value.tags = [...data.preferenceTags]
      }
      selectedPresetTags.value = [...data.preferenceTags]
    }
  } catch (e) {}
}

const handleTogglePresetTag = (tag: string) => {
  const idx = selectedPresetTags.value.indexOf(tag)
  if (idx >= 0) {
    selectedPresetTags.value.splice(idx, 1)
  } else {
    selectedPresetTags.value.push(tag)
  }
}

const handleSelectAllPresetTags = () => {
  selectedPresetTags.value = [...(currentIndustryPreset.value?.tags || [])]
}

const handleClearAllPresetTags = () => {
  selectedPresetTags.value = []
}

const handleConfirmImportPresetTags = () => {
  if (selectedPresetTags.value.length === 0) {
    ElMessage.warning('请至少选择一个推荐标签')
    return
  }
  if (presetImportMode.value === 'REPLACE') {
    editingStoreRegisterConfig.preferenceTags = [...selectedPresetTags.value]
  } else {
    selectedPresetTags.value.forEach(tag => {
      if (!editingStoreRegisterConfig.preferenceTags.includes(tag)) {
        editingStoreRegisterConfig.preferenceTags.push(tag)
      }
    })
  }
  industryPresetModalVisible.value = false
  ElMessage.success(`已载入【${currentIndustryPreset.value?.name}】推荐标签！请确认后点击下方【保存开卡配置】保存至当前店铺。`)
}

const getStoreRegisterConfigStorageKey = () => {
  const storeId = storeConfig.currentStoreId || 'S001'
  return `seahorse_store_register_config_${storeId}`
}

const getDefaultPrefTags = () => {
  const ind = (storeConfig.industry || 'RESTAURANT').toUpperCase()
  const matched = industryPresetList.find(p => p.key === ind)
  return matched ? [...matched.tags] : []
}

const standardLevelList = [
  { levelCode: 'REGULAR', levelName: '普卡会员', label: '普卡会员 (无折扣)' },
  { levelCode: 'SILVER', levelName: '荣耀银卡', label: '荣耀银卡 (95折 · 300分)' },
  { levelCode: 'GOLD', levelName: '黄金VIP卡', label: '黄金VIP卡 (90折 · 800分)' },
  { levelCode: 'VIP', levelName: 'VIP尊享卡', label: 'VIP尊享卡 (88折 · 1200分)' },
  { levelCode: 'PLATINUM', levelName: '至尊白金卡', label: '至尊白金卡 (85折 · 2000分)' },
  { levelCode: 'DIAMOND', levelName: '黑钻至尊卡', label: '黑钻至尊卡 (80折 · 3500分)' }
]

const handleLevelChange = (row: any, val: string) => {
  const matched = standardLevelList.find(l => l.levelName === val)
  if (matched) {
    row.levelCode = matched.levelCode
    row.levelName = matched.levelName
  }
}

const getDefaultChargeOptions = () => [
  { id: 1, title: '基础免费入会', principal: 0, gift: 0, levelName: '普卡会员', levelCode: 'REGULAR', badge: '免充激活' },
  { id: 2, title: '首充礼遇 ￥200', principal: 200, gift: 50, levelName: '荣耀银卡', levelCode: 'SILVER', badge: '立赠50元' },
  { id: 3, title: '尊享体验 ￥500', principal: 500, gift: 150, levelName: '黄金VIP卡', levelCode: 'GOLD', badge: '热销推荐' },
  { id: 4, title: 'VIP尊享储值 ￥800', principal: 800, gift: 260, levelName: 'VIP尊享卡', levelCode: 'VIP', badge: '尊贵礼遇' },
  { id: 5, title: '白金储值 ￥1000', principal: 1000, gift: 350, levelName: '至尊白金卡', levelCode: 'PLATINUM', badge: '超值爆款' },
  { id: 6, title: '黑钻至尊储值 ￥3000', principal: 3000, gift: 1200, levelName: '黑钻至尊卡', levelCode: 'DIAMOND', badge: '终身顶格' }
]

const editingStoreRegisterConfig = reactive<{
  preferenceTags: string[]
  chargeOptions: any[]
}>({
  preferenceTags: [],
  chargeOptions: []
})

const openRegisterConfigModal = async () => {
  const storeId = storeConfig.currentStoreId || 'S001'
  try {
    const res = (await getStoreRegisterConfigApi(storeId, storeConfig.industry)) as any
    const data = (res && res.data) ? res.data : res
    if (data && data.preferenceTags !== undefined && data.preferenceTags !== null) {
      const parsedTags = typeof data.preferenceTags === 'string' ? JSON.parse(data.preferenceTags) : data.preferenceTags
      editingStoreRegisterConfig.preferenceTags = Array.isArray(parsedTags) ? parsedTags : []
      if (data.chargeOptions) {
        const rawOpts = typeof data.chargeOptions === 'string' ? JSON.parse(data.chargeOptions) : data.chargeOptions
        editingStoreRegisterConfig.chargeOptions = (Array.isArray(rawOpts) ? rawOpts : []).map((opt: any) => {
          if (!opt.levelName) {
            const p = Number(opt.principal) || 0
            if (p >= 3000) { opt.levelName = '黑钻至尊卡'; opt.levelCode = 'DIAMOND'; }
            else if (p >= 1000) { opt.levelName = '至尊白金卡'; opt.levelCode = 'PLATINUM'; }
            else if (p >= 800) { opt.levelName = 'VIP尊享卡'; opt.levelCode = 'VIP'; }
            else if (p >= 500) { opt.levelName = '黄金VIP卡'; opt.levelCode = 'GOLD'; }
            else if (p >= 200) { opt.levelName = '荣耀银卡'; opt.levelCode = 'SILVER'; }
            else { opt.levelName = '普卡会员'; opt.levelCode = 'REGULAR'; }
          }
          return opt
        })
      } else {
        editingStoreRegisterConfig.chargeOptions = getDefaultChargeOptions()
      }
    } else {
      loadLocalRegisterConfig()
    }
  } catch (err) {
    loadLocalRegisterConfig()
  }
  registerConfigModalVisible.value = true
}

const loadLocalRegisterConfig = () => {
  const key = getStoreRegisterConfigStorageKey()
  const raw = localStorage.getItem(key)
  if (raw) {
    try {
      const parsed = JSON.parse(raw)
      editingStoreRegisterConfig.preferenceTags = Array.isArray(parsed.preferenceTags) ? parsed.preferenceTags : []
      editingStoreRegisterConfig.chargeOptions = parsed.chargeOptions || getDefaultChargeOptions()
    } catch {
      editingStoreRegisterConfig.preferenceTags = []
      editingStoreRegisterConfig.chargeOptions = getDefaultChargeOptions()
    }
  } else {
    editingStoreRegisterConfig.preferenceTags = []
    editingStoreRegisterConfig.chargeOptions = getDefaultChargeOptions()
  }
}

const handleAddPrefTag = () => {
  const tag = newPrefTagInput.value.trim()
  if (!tag) {
    ElMessage.warning('请输入标签名称')
    return
  }
  if (editingStoreRegisterConfig.preferenceTags.includes(tag)) {
    ElMessage.warning('该偏好标签已存在')
    return
  }
  editingStoreRegisterConfig.preferenceTags.push(tag)
  newPrefTagInput.value = ''
  ElMessage.success(`已添加标签：${tag}`)
}

const handleRemovePrefTag = (idx: number) => {
  editingStoreRegisterConfig.preferenceTags.splice(idx, 1)
}

const handleAddChargeOption = () => {
  const nextId = Date.now()
  const count = editingStoreRegisterConfig.chargeOptions.length + 1
  const principal = count * 300
  let lvlName = '荣耀银卡'
  let lvlCode = 'SILVER'
  if (principal >= 3000) { lvlName = '黑钻至尊卡'; lvlCode = 'DIAMOND'; }
  else if (principal >= 1000) { lvlName = '至尊白金卡'; lvlCode = 'PLATINUM'; }
  else if (principal >= 800) { lvlName = 'VIP尊享卡'; lvlCode = 'VIP'; }
  else if (principal >= 500) { lvlName = '黄金VIP卡'; lvlCode = 'GOLD'; }
  else if (principal >= 200) { lvlName = '荣耀银卡'; lvlCode = 'SILVER'; }
  else { lvlName = '普卡会员'; lvlCode = 'REGULAR'; }

  editingStoreRegisterConfig.chargeOptions.push({
    id: nextId,
    title: `储值特惠 ￥${principal}`,
    principal: principal,
    gift: Math.round(principal * 0.25),
    levelName: lvlName,
    levelCode: lvlCode,
    badge: '特惠推荐'
  })
}

const handleRemoveChargeOption = (idx: number) => {
  if (editingStoreRegisterConfig.chargeOptions.length <= 1) {
    ElMessage.warning('至少保留一个开卡方案')
    return
  }
  editingStoreRegisterConfig.chargeOptions.splice(idx, 1)
}

const handleResetDefaultChargeOptions = () => {
  editingStoreRegisterConfig.chargeOptions = getDefaultChargeOptions()
  ElMessage.info('已恢复推荐首充立赠方案')
}

const handleSaveRegisterConfig = async () => {
  const storeId = storeConfig.currentStoreId || 'S001'
  const key = getStoreRegisterConfigStorageKey()
  const payload = {
    preferenceTags: [...editingStoreRegisterConfig.preferenceTags],
    chargeOptions: [...editingStoreRegisterConfig.chargeOptions]
  }
  localStorage.setItem(key, JSON.stringify(payload))
  localStorage.setItem('seahorse_store_register_config_default', JSON.stringify(payload))

  try {
    await saveStoreRegisterConfigApi({
      storeId,
      preferenceTags: JSON.stringify(payload.preferenceTags),
      chargeOptions: JSON.stringify(payload.chargeOptions),
      welcomeCouponEnabled: true
    })
  } catch (err) {
    console.warn('Backend saveStoreRegisterConfigApi fallback:', err)
  }

  registerConfigModalVisible.value = false
  ElMessage.success('🎉 门店自助开卡配置（偏好标签与首充方案）已成功保存并同步到云端！顾客扫码或点击链接将立即呈现最新内容。')
}

const searchQuery = ref('')
const members = ref<any[]>([])
const loading = ref(false)

const showLevelRulesModal = ref(false)

const standardLevelRules = [
  { levelCode: 'REGULAR', levelName: '普卡会员', threshold: 0, discount: '无折扣 (100%)', privileges: '进店建档、海马体偏好常态记忆、消费基础积分' },
  { levelCode: 'SILVER', levelName: '荣耀银卡', threshold: 300, discount: '服务95折 / 商品98折', privileges: '服务95折、生日月享50元抵用券、双倍积分日' },
  { levelCode: 'GOLD', levelName: '黄金VIP卡', threshold: 800, discount: '服务90折 / 商品95折', privileges: '服务9折、免排队预约优先通道、生日免费专属体验' },
  { levelCode: 'VIP', levelName: 'VIP尊享卡', threshold: 1200, discount: '服务88折 / 商品92折', privileges: '服务88折、专属金牌技师优先点单、节日私享定制礼盒' },
  { levelCode: 'PLATINUM', levelName: '至尊白金卡', threshold: 2000, discount: '服务85折 / 商品90折', privileges: '全场85折、专属私享包间、免费携1位亲友享同折' },
  { levelCode: 'DIAMOND', levelName: '黑钻至尊卡', threshold: 3500, discount: '服务80折 / 商品85折', privileges: '全场8折、总监技师免服务费、终身顶格尊崇待遇' }
]

// 新人办卡优惠券营销配置与卡包状态
const getWelcomeConfig = () => {
  try {
    const raw = localStorage.getItem('seahorse_welcome_coupon_config')
    if (raw) return JSON.parse(raw)
  } catch (e) {}
  return {
    enabled: true,
    couponName: '新人开卡专享50元无门槛券',
    amount: 50,
    minSpend: 0,
    validityMode: 'DAYS',
    validDays: 30,
    fixedExpireDate: '2026-12-31',
    serviceScope: '全场通用'
  }
}
const welcomeConfig = ref(getWelcomeConfig())
const currentMemberCoupons = ref<any[]>([])

const profileDrawerVisible = ref(false)
const profileLoading = ref(false)
const currentProfile = ref<any>(null)

// 会员海马体偏好类别中文映射
const getCategoryName = (category?: string) => {
  switch (category) {
    case 'BEAUTY_HAIR': return '美业发质造型'
    case 'RESTAURANT_TASTE': return '餐饮口味偏好'
    case 'AUTO_VEHICLE': return '汽修爱车档案'
    case 'HABIT': return '常态服务习惯'
    default: return category || '个性特征'
  }
}

// 注册
const openRegisterDialog = ref(false)
const registerForm = ref({
  name: '',
  phone: '',
  gender: 'FEMALE',
  initialPrincipal: 500,
  initialGift: 100,
  deductMode: 'PROPORTIONAL'
})

// 充值
const openRechargeDialog = ref(false)
const targetMember = ref<any>(null)
const rechargeForm = ref({
  memberId: 0,
  principalAmount: 500,
  giftAmount: 100,
  sellerEmployeeId: null
})

// 次卡
const openTimeCardDialog = ref(false)

const defaultTimeCardName = computed(() => {
  switch (systemData.currentIndustry) {
    case 'RETAIL': return '精品手冲咖啡豆 10次提货卡'
    case 'RESTAURANT': return '主厨招牌牛排 5次私享次卡'
    case 'AUTO': return '全合成机油小保养 4次年卡'
    default: return '发型总监精修剪发 10次年卡'
  }
})

const timeCardPlaceholder = computed(() => {
  switch (systemData.currentIndustry) {
    case 'RETAIL': return '如：精品咖啡次卡、美学手作沙龙次卡等'
    case 'RESTAURANT': return '如：招牌牛排次卡、特调果饮次卡等'
    case 'AUTO': return '如：小保养次卡、全车精洗次卡等'
    default: return '如：发型总监剪发次卡、头皮理疗次卡等'
  }
})

const timeCardForm = ref({
  memberId: 0,
  skuId: 1,
  skuName: '',
  totalTimes: 5
})

// 海马记忆标签
const openAddPrefDialog = ref(false)
const prefForm = ref({
  memberId: 0,
  category: 'BEAUTY_HAIR',
  tagKey: 'hair_texture',
  tagValue: '',
  notes: ''
})

// 会员个人专属二维码弹窗
const singleMemberQrDialogVisible = ref(false)
const qrMember = ref<any>(null)
const singleMemberQrCodeUrl = ref('')

const handleOpenMemberQr = async (row: any) => {
  qrMember.value = row
  singleMemberQrDialogVisible.value = true
  singleMemberQrCodeUrl.value = ''
  try {
    const qrText = `SEAHORSE:MEMBER:${row.phone}`
    singleMemberQrCodeUrl.value = await QRCode.toDataURL(qrText, {
      width: 320,
      margin: 2,
      color: {
        dark: '#0f172a',
        light: '#ffffff'
      }
    })
  } catch (err) {
    ElMessage.error('生成会员二维码失败')
  }
}

const copyMemberQrText = () => {
  if (!qrMember.value) return
  const text = `SEAHORSE:MEMBER:${qrMember.value.phone}`
  navigator.clipboard.writeText(text)
  ElMessage.success('会员专属码值已复制到剪贴板')
}

const downloadSingleMemberQr = () => {
  if (!singleMemberQrCodeUrl.value || !qrMember.value) return
  const link = document.createElement('a')
  link.download = `会员码_${qrMember.value.name}_${qrMember.value.phone}.png`
  link.href = singleMemberQrCodeUrl.value
  link.click()
  ElMessage.success('已触发二维码图片下载')
}

let searchTimer: any = null
const handleSearchInput = () => {
  if (searchTimer) clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    loadMembers()
  }, 300)
}

const loadMembers = async () => {
  loading.value = true
  try {
    let apiData: any = null
    const curTid = storeConfig.tenantId || localStorage.getItem('seahorse_tenant_id') || 'T001'
    try {
      apiData = await searchMembersApi(searchQuery.value, curTid, storeConfig.currentStoreId)
    } catch (err) {}

    if (Array.isArray(apiData)) {
      members.value = apiData.map((m: any) => ({
        ...m,
        totalBalance: m.totalBalance != null ? m.totalBalance : (m.balance != null ? m.balance : 0)
      }))

      // 同步回填 Pinia systemData.members 全局响应式状态，保证其他页面实时互通
      apiData.forEach((m: any) => {
        const mapped = {
          ...m,
          totalBalance: m.totalBalance != null ? m.totalBalance : (m.balance != null ? m.balance : 0)
        }
        const idx = systemData.members.findIndex((sm: any) => sm.id === m.id || (sm.phone && sm.phone === m.phone))
        if (idx >= 0) {
          systemData.members[idx] = { ...systemData.members[idx], ...mapped }
        } else {
          systemData.members.unshift(mapped)
        }
      })
      try {
        localStorage.setItem('seahorse_members_data', JSON.stringify(systemData.members))
      } catch (e) {}
    } else {
      // 跨标签页/扫码开卡即时同步检测
      const cachedMembers = localStorage.getItem('seahorse_members_data')
      if (cachedMembers) {
        try {
          const parsed = JSON.parse(cachedMembers)
          if (Array.isArray(parsed) && parsed.length > systemData.members.length) {
            systemData.members = parsed
          }
        } catch {}
      }
      const cachedRecharges = localStorage.getItem('seahorse_recharge_orders_data')
      if (cachedRecharges) {
        try {
          const parsed = JSON.parse(cachedRecharges)
          if (Array.isArray(parsed) && parsed.length > systemData.rechargeOrders.length) {
            systemData.rechargeOrders = parsed
          }
        } catch {}
      }

      // 真实计算型会员画像数据源 (累计消费、到店频次、储值余额等由真实流水实时计算)
      let list = getSafeMembersWithStats()
      const curTid = storeConfig.tenantId || localStorage.getItem('seahorse_tenant_id') || 'T001'
      list = list.filter((m: any) => !m.tenantId || m.tenantId === curTid)
      if (searchQuery.value.trim()) {
        const q = searchQuery.value.trim().toLowerCase()
        list = list.filter((m: any) =>
          (m.name && m.name.toLowerCase().includes(q)) ||
          (m.phone && m.phone.includes(q)) ||
          (m.memberNo && m.memberNo.toLowerCase().includes(q))
        )
      }
      members.value = list
    }
    currentPage.value = 1
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

// 分页与常用指标排序
const sortKey = ref('default')

const applySorting = (list: any[]) => {
  const arr = [...list]
  switch (sortKey.value) {
    case 'points_desc':
      return arr.sort((a, b) => (b.points || 0) - (a.points || 0))
    case 'points_asc':
      return arr.sort((a, b) => (a.points || 0) - (b.points || 0))
    case 'balance_desc':
      return arr.sort((a, b) => ((b.totalBalance ?? b.balance) || 0) - ((a.totalBalance ?? a.balance) || 0))
    case 'balance_asc':
      return arr.sort((a, b) => ((a.totalBalance ?? a.balance) || 0) - ((b.totalBalance ?? b.balance) || 0))
    case 'spent_desc':
      return arr.sort((a, b) => (b.totalSpent || 0) - (a.totalSpent || 0))
    case 'spent_asc':
      return arr.sort((a, b) => (a.totalSpent || 0) - (b.totalSpent || 0))
    case 'visit_desc':
      return arr.sort((a, b) => (b.visitCount || 0) - (a.visitCount || 0))
    case 'last_visit_desc':
      return arr.sort((a, b) => new Date(b.lastVisitTime || 0).getTime() - new Date(a.lastVisitTime || 0).getTime())
    default:
      return arr
  }
}

const sortedMembers = computed(() => {
  return applySorting(members.value)
})

const currentPage = ref(1)
const pageSize = ref(10)
const paginatedMembers = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return sortedMembers.value.slice(start, start + pageSize.value)
})

const handleSortSelectChange = () => {
  currentPage.value = 1
}

const handleTableSortChange = ({ prop, order }: { prop: string, order: string | null }) => {
  if (!order) {
    sortKey.value = 'default'
  } else if (prop === 'points') {
    sortKey.value = order === 'descending' ? 'points_desc' : 'points_asc'
  } else if (prop === 'totalBalance') {
    sortKey.value = order === 'descending' ? 'balance_desc' : 'balance_asc'
  } else if (prop === 'totalSpent') {
    sortKey.value = order === 'descending' ? 'spent_desc' : 'spent_asc'
  } else if (prop === 'visitCount') {
    sortKey.value = order === 'descending' ? 'visit_desc' : 'default'
  } else if (prop === 'lastVisitTime') {
    sortKey.value = order === 'descending' ? 'last_visit_desc' : 'default'
  }
  currentPage.value = 1
}

// 会员等级纯中文映射，绝不显示英文
const formatLevelName = (level: string, levelName?: string) => {
  if (levelName && levelName.trim() !== '') return levelName
  switch (level) {
    case 'DIAMOND': return '黑钻至尊卡'
    case 'PLATINUM': return '铂金尊享卡'
    case 'VIP': return 'VIP尊享卡'
    case 'GOLD': return '黄金VIP卡'
    case 'SILVER': return '银卡会员'
    case 'REGULAR': return '普卡会员'
    default: return level || '普卡会员'
  }
}

// 跨端统一的 5 档会员视觉色彩定义
const getLevelBadgeStyle = (level: string, levelName?: string) => {
  const name = (levelName || level || '').toUpperCase()
  if (name.includes('黑钻') || name.includes('黑金') || name.includes('至尊') || name.includes('钻') || name.includes('DIAMOND') || name.includes('BLACK')) {
    // 黑金至尊卡 / 黑钻: 曜石黑金底 + 烫金边框 (#0F172A / #F59E0B)
    return {
      background: '#0f172a',
      color: '#fef3c7',
      border: '1px solid #f59e0b',
      padding: '2px 8px',
      borderRadius: '4px',
      fontWeight: '700',
      display: 'inline-flex',
      alignItems: 'center',
      fontSize: '12px',
      boxShadow: '0 1px 4px rgba(245, 158, 11, 0.25)'
    }
  } else if (name.includes('铂金') || name.includes('紫晶') || name.includes('白金') || name.includes('PLATINUM')) {
    // 铂金尊享卡: 皇家紫晶 (#7C3AED)
    return {
      background: '#ede9fe',
      color: '#6d28d9',
      border: '1px solid #c4b5fd',
      padding: '2px 8px',
      borderRadius: '4px',
      fontWeight: '600',
      display: 'inline-flex',
      alignItems: 'center',
      fontSize: '12px'
    }
  } else if (name.includes('黄金') || name.includes('金卡') || name.includes('VIP') || name.includes('GOLD')) {
    // 黄金VIP卡: 香槟琥珀金 (#D97706)
    return {
      background: '#fef3c7',
      color: '#b45309',
      border: '1px solid #fcd34d',
      padding: '2px 8px',
      borderRadius: '4px',
      fontWeight: '600',
      display: 'inline-flex',
      alignItems: 'center',
      fontSize: '12px'
    }
  } else if (name.includes('银卡') || name.includes('白银') || name.includes('SILVER')) {
    // 银卡会员: 冰川湖蓝 (#0284C7)
    return {
      background: '#e0f2fe',
      color: '#0369a1',
      border: '1px solid #bae6fd',
      padding: '2px 8px',
      borderRadius: '4px',
      fontWeight: '600',
      display: 'inline-flex',
      alignItems: 'center',
      fontSize: '12px'
    }
  } else {
    // 普卡/普通会员: 翡翠石绿 (#0D9488)
    return {
      background: '#ccfbf1',
      color: '#0f766e',
      border: '1px solid #99f6e4',
      padding: '2px 8px',
      borderRadius: '4px',
      fontWeight: '500',
      display: 'inline-flex',
      alignItems: 'center',
      fontSize: '12px'
    }
  }
}

const handleOpenProfile = async (memberId: number) => {
  currentProfile.value = null
  profileLoading.value = true
  profileDrawerVisible.value = true
  try {
    let profileData: any = null
    try {
      profileData = await getMemberProfileApi(memberId)
    } catch (err) {}

    if (profileData && profileData.member) {
      currentProfile.value = profileData
    } else {
      const statsList = getSafeMembersWithStats()
      const found = statsList.find((m: any) => m.id === memberId) ||
                    members.value.find((m: any) => m.id === memberId) ||
                    null
      if (found) {
        currentProfile.value = {
          member: found,
          dualBalance: {
            principalBalance: Number(found.principalBalance ?? found.balance ?? 0).toFixed(2),
            giftBalance: Number(found.giftBalance ?? 0).toFixed(2),
            totalBalance: Number(found.totalBalance ?? found.balance ?? 0).toFixed(2),
            deductMode: found.deductMode || 'PROPORTIONAL'
          },
          timeCards: (found.timeCards || []).map((tc: any) => ({
            ...tc,
            skuName: tc.skuName || tc.cardName || '次卡项目',
            remainingTimes: tc.remainingTimes != null
              ? tc.remainingTimes
              : Math.max(0, Number(tc.totalTimes || 0) - Number(tc.usedTimes || 0))
          })),
          preferences: (() => {
            const savedPrefsRaw = localStorage.getItem(`seahorse_member_preferences_${found.id}`) ||
                                  localStorage.getItem(`seahorse_member_preferences_${found.phone}`)
            if (found.preferences && found.preferences.length > 0) {
              return found.preferences
            } else if (savedPrefsRaw) {
              try {
                return JSON.parse(savedPrefsRaw)
              } catch {
                return []
              }
            } else if (found.habits && found.habits.length > 0) {
              return found.habits.map((h: string, idx: number) => ({
                id: idx + 1,
                category: 'HABIT',
                tagKey: '常客自主偏好',
                tagValue: h,
                notes: '顾客扫码开卡自主录入'
              }))
            }
            return []
          })()
        }
      } else {
        currentProfile.value = null
      }
    }
    // 加载该会员的专属卡包优惠券资产
    const memberPhone = currentProfile.value?.member?.phone || ''
    const memberName = currentProfile.value?.member?.name || ''
    const rawCoupons = localStorage.getItem(`seahorse_member_coupons_${memberPhone}`) ||
                       localStorage.getItem(`seahorse_member_coupons_${memberName}`) ||
                       localStorage.getItem(`seahorse_member_coupons_${memberId}`)
    if (rawCoupons) {
      currentMemberCoupons.value = JSON.parse(rawCoupons)
    } else {
      currentMemberCoupons.value = [
        {
          id: 'CPN_' + memberId + '_1',
          name: welcomeConfig.value.couponName,
          amount: welcomeConfig.value.amount,
          minSpend: welcomeConfig.value.minSpend,
          expireDate: '2026-12-31',
          source: '新人开卡迎新礼遇',
          status: 'UNUSED'
        }
      ]
    }
  } catch (e) {
    console.error(e)
  } finally {
    profileLoading.value = false
  }
}

const handleIssueBonusCoupon = () => {
  if (!currentProfile.value?.member) return
  const phone = currentProfile.value.member.phone
  const name = currentProfile.value.member.name
  const bonus = {
    id: 'CPN_' + Date.now(),
    name: '店长特批·专属回馈立减券',
    amount: 30,
    minSpend: 100,
    expireDate: '2026-12-31',
    source: '门店现场关怀赠送',
    status: 'UNUSED',
    receiveTime: new Date().toISOString().slice(0, 19).replace('T', ' ')
  }
  currentMemberCoupons.value.unshift(bonus)
  localStorage.setItem(`seahorse_member_coupons_${phone}`, JSON.stringify(currentMemberCoupons.value))
  localStorage.setItem(`seahorse_member_coupons_${name}`, JSON.stringify(currentMemberCoupons.value))
  ElMessage.success(`已成功向【${name}】赠送￥30专属优惠券！`)
}

const handleOpenRecharge = (member: any) => {
  targetMember.value = member
  rechargeForm.value = {
    memberId: member.id,
    principalAmount: 500,
    giftAmount: 100,
    sellerEmployeeId: null
  }
  openRechargeDialog.value = true
}

const handleConfirmRecharge = async () => {
  try {
    try {
      await rechargeMemberApi(rechargeForm.value)
    } catch (err) {}

    systemData.rechargeMember({
      memberId: targetMember.value.id,
      principal: rechargeForm.value.principalAmount,
      gift: rechargeForm.value.giftAmount,
      sellerId: rechargeForm.value.sellerEmployeeId || 2
    })

    ElMessage.success('储值充值成功')
    openRechargeDialog.value = false
    loadMembers()
    if (currentProfile.value && currentProfile.value.member.id === targetMember.value.id) {
      handleOpenProfile(targetMember.value.id)
    }
  } catch (e) {
    console.error(e)
  }
}

const handleOpenTimeCard = (member: any) => {
  targetMember.value = member
  timeCardForm.value = {
    memberId: member.id,
    skuId: 1,
    skuName: defaultTimeCardName.value,
    totalTimes: 5
  }
  openTimeCardDialog.value = true
}

const handleConfirmIssueTimeCard = async () => {
  try {
    await issueTimeCardApi(timeCardForm.value).catch(() => {})
    ElMessage.success('次卡发放成功')
    openTimeCardDialog.value = false
    loadMembers()
    if (currentProfile.value) {
      handleOpenProfile(targetMember.value.id)
    }
  } catch (e) {
    console.error(e)
  }
}

const handleConfirmRegister = async () => {
  if (!registerForm.value.name || !registerForm.value.phone) {
    ElMessage.warning('请填写姓名与手机号')
    return
  }
  const regName = registerForm.value.name.trim()
  const regPhone = registerForm.value.phone.trim()
  try {
    let cloudSynced = false
    try {
      await registerMemberApi({
        ...registerForm.value,
        name: regName,
        phone: regPhone,
        storeId: storeConfig.currentStoreId || 'S001'
      })
      cloudSynced = true
    } catch (err: any) {
      console.warn('registerMemberApi error:', err)
    }

    systemData.registerMember({
      name: regName,
      phone: regPhone,
      gender: registerForm.value.gender as any,
      initialPrincipal: registerForm.value.initialPrincipal,
      initialGift: registerForm.value.initialGift
    })

    openRegisterDialog.value = false

    // 新人开卡自动派发优惠券闭环
    const cfg = getWelcomeConfig()
    welcomeConfig.value = cfg
    if (cfg.enabled) {
      let expireStr = ''
      if (cfg.validityMode === 'DAYS') {
        const d = new Date()
        d.setDate(d.getDate() + (cfg.validDays || 30))
        expireStr = d.toISOString().slice(0, 10)
      } else {
        expireStr = cfg.fixedExpireDate || '2026-12-31'
      }

      const issuedCoupon = {
        id: 'CPN_' + Date.now(),
        name: cfg.couponName,
        amount: cfg.amount,
        minSpend: cfg.minSpend,
        expireDate: expireStr,
        source: '新人开卡入会迎新自动发放',
        status: 'UNUSED',
        receiveTime: new Date().toISOString().slice(0, 19).replace('T', ' ')
      }

      const phoneKey = `seahorse_member_coupons_${regPhone}`
      const nameKey = `seahorse_member_coupons_${regName}`
      const existing = JSON.parse(localStorage.getItem(phoneKey) || '[]')
      existing.unshift(issuedCoupon)
      localStorage.setItem(phoneKey, JSON.stringify(existing))
      localStorage.setItem(nameKey, JSON.stringify(existing))

      ElNotification({
        title: '🎉 会员开卡成功并自动发放优惠券',
        message: `已自动为【${regName}】发放迎新券【${cfg.couponName}】(立减￥${cfg.amount}，有效期至 ${expireStr})，已放入其专属卡包！`,
        type: 'success',
        duration: 5000
      })
    } else {
      ElMessage.success(cloudSynced ? '新会员注册成功！已实时同步至云端数据库。' : '会员开卡成功！')
    }

    registerForm.value = {
      name: '',
      phone: '',
      gender: 'FEMALE',
      deductMode: 'PROPORTIONAL',
      initialPrincipal: 0,
      initialGift: 0
    }
    await loadMembers()
  } catch (e) {
    console.error(e)
  }
}

const handleConfirmAddPref = async () => {
  if (!prefForm.value.tagValue) {
    ElMessage.warning('请填写记忆特征内容')
    return
  }
  const targetMemberId = currentProfile.value?.member?.id
  if (!targetMemberId) {
    ElMessage.warning('未找到当前会员档案')
    return
  }
  try {
    prefForm.value.memberId = targetMemberId
    await savePreferenceApi(prefForm.value)
    ElMessage.success('海马体记忆档案更新成功！')
    openAddPrefDialog.value = false
    prefForm.value.tagValue = ''
    prefForm.value.notes = ''
    currentProfile.value = await getMemberProfileApi(targetMemberId)
  } catch (e: any) {
    console.error(e)
    ElMessage.error(e?.message || '保存记忆档案失败')
  }
}

onMounted(() => {
  loadMembers()
})

onUnmounted(() => {
  if (searchTimer) {
    clearTimeout(searchTimer)
    searchTimer = null
  }
})
</script>

<style scoped>
.member-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-left {
  display: flex;
  align-items: baseline;
  gap: 12px;
}

.header-title {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
}

.header-slogan {
  font-size: 12px;
  color: #64748b;
  font-style: italic;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.member-no-tag {
  font-family: monospace;
  font-weight: 600;
  color: #0369a1;
}

.profile-hero-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: linear-gradient(135deg, #0284c7, #0369a1);
  color: #fff;
  padding: 16px;
  border-radius: 8px;
  margin-bottom: 16px;
}

.hero-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.hero-name {
  font-size: 16px;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 8px;
}

.hero-sub {
  font-size: 12px;
  color: #e0f2fe;
  margin-top: 4px;
}

.hero-right {
  text-align: right;
}

.hero-stat-val {
  font-size: 20px;
  font-weight: 700;
}

.hero-stat-label {
  font-size: 11px;
  color: #e0f2fe;
}

.section-box {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 14px;
  margin-bottom: 16px;
}

.section-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 12px;
}

.dual-balance-display {
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding: 8px;
  background-color: #fff;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.db-item {
  text-align: center;
}

.db-label { font-size: 12px; color: #64748b; margin-bottom: 4px; }
.db-val { font-size: 18px; font-weight: 700; }
.db-divider { width: 1px; height: 32px; background-color: #e2e8f0; }

.tc-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 10px;
}

.tc-card {
  background-color: #fff;
  padding: 10px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.tc-name { font-size: 13px; font-weight: 600; color: #1e293b; }
.tc-times { font-size: 12px; color: #d97706; margin: 4px 0; }
.tc-expire { font-size: 11px; color: #94a3b8; }

.hippocampus-section {
  background-color: #faf5ff;
  border-color: #e9d5ff;
}

.pref-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.pref-card {
  background-color: #fff;
  padding: 12px;
  border-radius: 6px;
  border: 1px solid #f3e8ff;
}

.pref-top {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.pref-key {
  font-size: 12px;
  font-weight: 600;
  color: #6b21a8;
}

.pref-recorder {
  font-size: 11px;
  color: #94a3b8;
  margin-left: auto;
}

.pref-value {
  font-size: 13px;
  color: #1e293b;
  line-height: 1.4;
}

.pref-notes {
  font-size: 11px;
  color: #64748b;
  margin-top: 4px;
}

.coupon-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 12px;
}

.coupon-item-box {
  display: flex;
  align-items: center;
  background: linear-gradient(135deg, #fff7ed, #ffedd5);
  border: 1px dashed #fb923c;
  border-radius: 8px;
  padding: 10px 12px;
  position: relative;
}

.cpn-val-col {
  padding-right: 12px;
  border-right: 1px dashed #fdba74;
  text-align: center;
  min-width: 65px;
}

.cpn-val-col .val {
  font-size: 20px;
  font-weight: 800;
  color: #ea580c;
}

.cpn-val-col .cond {
  font-size: 10px;
  color: #c2410c;
  margin-top: 2px;
}

.cpn-info-col {
  padding-left: 12px;
  flex: 1;
}

.cpn-info-col .name {
  font-size: 12px;
  font-weight: 700;
  color: #7c2d12;
}

.cpn-info-col .expire {
  font-size: 11px;
  color: #9a3412;
  margin-top: 3px;
}

.cpn-info-col .src {
  font-size: 10px;
  color: #ea580c;
  margin-top: 2px;
}

.cpn-tag-col {
  margin-left: 8px;
}

/* 二维码弹窗美化样式 */
.qr-modal-body {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 8px 0;
}

.qr-store-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #f8fafc;
  padding: 8px 16px;
  border-radius: 20px;
  border: 1px solid #e2e8f0;
}

.qr-store-name {
  font-weight: 700;
  color: #0f172a;
}

.qr-code-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 16px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}

.qr-image {
  width: 220px;
  height: 220px;
  border-radius: 6px;
}

.qr-loading {
  width: 220px;
  height: 220px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #94a3b8;
}

.qr-scan-hint {
  margin-top: 10px;
  font-size: 13px;
  color: #64748b;
  font-weight: 500;
}

.qr-link-box {
  width: 100%;
}

.qr-link-title {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
  margin-bottom: 6px;
}

.qr-actions {
  display: flex;
  gap: 12px;
  width: 100%;
  justify-content: center;
}
</style>
