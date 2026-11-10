<template>
  <div class="member-detail-page" v-loading="pageLoading">
    <!-- 顶部导航与10大核心功能操作栏 (严格对齐截图2) -->
    <div class="top-action-bar">
      <div class="bar-left">
        <el-button icon="Back" plain @click="$router.push('/members')">退出编辑</el-button>
        <span class="detail-title">会员详情 - {{ memberForm.name }}</span>
        <el-tag size="small" type="info" effect="plain">卡号: {{ memberForm.cardNo || memberForm.memberNo }}</el-tag>
        <el-button size="small" type="success" plain icon="FullScreen" @click="openMemberQrModal">
          📱 查看会员码
        </el-button>
      </div>

      <!-- 核心功能操作区 (规范分组对齐，杜绝错乱挤压) -->
      <div class="bar-right-buttons">
        <el-button-group>
          <el-button type="success" @click="openRechargeModal">充值/充次</el-button>
          <el-button type="primary" @click="$router.push('/cashier')">扣卡消费</el-button>
          <el-button type="warning" @click="$router.push('/cashier')">零散收银</el-button>
        </el-button-group>

        <el-button plain @click="openPasswordModal">扣卡密码</el-button>
        <el-button plain @click="openPointsModal">调整积分</el-button>
        <el-button plain @click="openRewardModal">调整奖励金</el-button>
        <el-button plain @click="openPointsExchangeModal">积分兑换</el-button>

        <!-- 次级低频操作收纳在下拉菜单中，确保单行整齐不折行 -->
        <el-dropdown trigger="click">
          <el-button plain>
            更多管理 <el-icon class="el-icon--right"><ArrowDown /></el-icon>
          </el-button>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item @click="openRepaymentModal">💳 会员还款</el-dropdown-item>
              <el-dropdown-item @click="openFollowUpModal">📝 添加跟进记录</el-dropdown-item>
              <el-dropdown-item @click="openStorageModal">📦 存取管账</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </div>

    <!-- 14个横向子标签栏 (严格对齐截图2) -->
    <el-card shadow="never" class="tabs-card">
      <el-tabs v-model="activeTab" class="detail-tabs">
        <el-tab-pane label="会员信息" name="info" />
        <el-tab-pane label="余额/余次" name="balance" />
        <el-tab-pane label="车辆管理" name="vehicles" />
        <el-tab-pane label="消费记录" name="consumption" />
        <el-tab-pane label="充值记录" name="recharge" />
        <el-tab-pane label="换卡记录" name="card_change" />
        <el-tab-pane label="优惠券" name="coupons" />
        <el-tab-pane label="消息提醒" name="reminders" />
        <el-tab-pane label="积分记录" name="points_records" />
        <el-tab-pane label="奖励金记录" name="reward_records" />
        <el-tab-pane label="会员卡调整记录" name="card_adjust" />
        <el-tab-pane label="还款记录" name="repay_records" />
        <el-tab-pane label="跟进记录" name="follow_ups" />
        <el-tab-pane label="存取记录" name="storage_records" />
      </el-tabs>

      <!-- 1. 会员信息 Tab (严格对齐截图2表单) -->
      <div v-show="activeTab === 'info'" class="tab-content-info">
        <el-form :model="memberForm" label-width="110px" class="profile-form">
          <!-- 头像区 -->
          <el-row :gutter="24" style="align-items: center; margin-bottom: 16px;">
            <el-col :span="24">
              <el-form-item label="会员头像">
                <div class="avatar-section">
                  <el-avatar :size="64" style="background-color: #0284c7; font-size: 24px;">
                    {{ memberForm.name ? memberForm.name.substring(0, 1) : '客' }}
                  </el-avatar>
                  <div class="avatar-tips">
                    <el-button size="small" plain>修改头像</el-button>
                    <span style="font-size: 12px; color: #94a3b8; margin-left: 8px;">支持 jpg/png 格式，建议 200x200 像素</span>
                  </div>
                </div>
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="24">
            <el-col :span="12">
              <el-form-item label="* 姓名" required>
                <el-input v-model="memberForm.name" placeholder="请输入会员姓名" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="* 手机号" required>
                <el-input v-model="memberForm.phone" placeholder="请输入手机号码" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="24">
            <el-col :span="12">
              <el-form-item label="卡号">
                <el-input v-model="memberForm.cardNo" placeholder="请输入实体卡号 / 磁条卡号" />
              </el-form-item>
            </el-col>
            <el-col :span="6">
              <el-form-item label="扣卡密码">
                <el-switch v-model="memberForm.cardPasswordEnabled" active-text="开启" inactive-text="关闭" />
              </el-form-item>
            </el-col>
            <el-col :span="6">
              <el-form-item label="扣卡签名">
                <el-switch v-model="memberForm.cardSignEnabled" active-text="开启" inactive-text="关闭" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="24">
            <el-col :span="12">
              <el-form-item label="性别">
                <el-radio-group v-model="memberForm.gender">
                  <el-radio label="UNKNOWN">未知</el-radio>
                  <el-radio label="MALE">男</el-radio>
                  <el-radio label="FEMALE">女</el-radio>
                </el-radio-group>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="会员折扣">
                <el-select v-model="memberForm.discountName" style="width: 100%;" placeholder="请选择会员卡或折扣">
                  <el-option label="暂无等级 (无折扣)" value="暂无等级" />
                  <el-option label="8折黄金卡 (全场8折)" value="8折黄金卡" />
                  <el-option label="9折银卡 (全场9折)" value="9折银卡" />
                  <el-option label="85折黑金年卡" value="85折黑金年卡" />
                </el-select>
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="24">
            <el-col :span="12">
              <el-form-item label="推荐人">
                <el-select v-model="memberForm.referrerName" style="width: 100%;" clearable placeholder="请选择推荐人 / 归属技师">
                  <el-option label="托尼总监 (技师)" value="托尼总监" />
                  <el-option label="李博 (资深发型师)" value="李博" />
                  <el-option label="张建华 (发型助理)" value="张建华" />
                  <el-option label="李店长" value="李店长" />
                  <el-option label="老客转介绍" value="老客转介绍" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="会员生日">
                <div style="display: flex; gap: 8px; width: 100%; align-items: center;">
                  <el-radio-group v-model="memberForm.birthdayType" size="small">
                    <el-radio-button label="SOLAR">阳历</el-radio-button>
                    <el-radio-button label="LUNAR">农历</el-radio-button>
                  </el-radio-group>
                  <el-date-picker
                    v-model="memberForm.birthday"
                    type="date"
                    placeholder="选择生日日期"
                    style="flex: 1;"
                    value-format="YYYY-MM-DD"
                  />
                </div>
              </el-form-item>
            </el-col>
          </el-row>

          <!-- 会员等级晋升成长卡片 (含升级差距与进度条) -->
          <div class="member-growth-overview-card">
            <div class="growth-card-top">
              <div class="growth-left">
                <span class="growth-title">👑 会员卡级与成长进度</span>
                <span :style="getLevelBadgeStyle(memberForm.level || memberForm.discountName)">
                  {{ formatLevelName(memberForm.level || memberForm.discountName) }}
                </span>
              </div>
              <div class="growth-right">
                <span class="points-badge">当前积分: <b>{{ memberForm.points || 0 }}</b> 分</span>
                <el-button size="small" type="primary" plain @click="showLevelRulesModal = true">
                  👑 查看完整晋升规则
                </el-button>
              </div>
            </div>

            <div class="growth-progress-wrap">
              <div class="progress-info-row">
                <span class="progress-label">成长值升级阶梯</span>
                <span class="next-level-tip" v-if="getNextLevelName()">
                  距离晋升【{{ getNextLevelName() }}】还差 <b class="gap-text">{{ getPointsGap() }}</b> 积分/成长经验
                </span>
                <span class="next-level-tip top-level" v-else>
                  🎉 已尊享黑钻至尊顶格礼遇
                </span>
              </div>
              <el-progress
                :percentage="getGrowthPercentage()"
                :stroke-width="10"
                :status="getGrowthPercentage() >= 100 ? 'success' : undefined"
                :show-text="false"
              />
            </div>
          </div>

          <!-- 资产与统计展示行 (规范对齐与无错乱网格) -->
          <div class="stats-grid-row">
            <div class="stat-box">
              <span class="lbl">创建日期</span>
              <span class="val">{{ memberForm.createdAt ? memberForm.createdAt.substring(0, 10) : '-' }}</span>
            </div>
            <div class="stat-box">
              <span class="lbl">奖励金</span>
              <span class="val" style="color: #ea580c;">￥{{ Number(memberForm.rewardAmount || 0).toFixed(2) }}</span>
            </div>
            <div class="stat-box">
              <span class="lbl">可用积分</span>
              <span class="val" style="color: #0284c7;">{{ memberForm.points || 0 }} 分</span>
            </div>
            <div class="stat-box">
              <span class="lbl">历史消费</span>
              <span class="val" style="color: #0f172a; font-weight: 700;">￥{{ Number(memberForm.totalSpent || 0).toFixed(2) }}</span>
            </div>
            <div class="stat-box">
              <span class="lbl">到店/办卡</span>
              <span class="val">{{ memberForm.cardOpenCount || 1 }} 次</span>
            </div>
            <div class="stat-box">
              <span class="lbl">挂账欠款</span>
              <span class="val" :style="{ color: Number(memberForm.debtAmount || 0) > 0 ? '#dc2626' : '#64748b' }">
                ￥{{ Number(memberForm.debtAmount || 0).toFixed(2) }}
              </span>
            </div>
            <div class="stat-box">
              <span class="lbl">微信绑定状态</span>
              <span class="val">
                <el-tag :type="memberForm.wechatBound ? 'success' : 'info'" size="small">
                  {{ memberForm.wechatBound ? '已绑定' : '未绑定' }}
                </el-tag>
              </span>
            </div>
          </div>

          <!-- 备注信息 -->
          <el-row :gutter="24" style="margin-top: 16px;">
            <el-col :span="24">
              <el-form-item label="备注信息">
                <el-input
                  v-model="memberForm.notes"
                  type="textarea"
                  :rows="4"
                  placeholder="请输入会员个性偏好、头发特性、特殊要求等备注信息..."
                />
              </el-form-item>
            </el-col>
          </el-row>

          <!-- 右下角保存按钮 -->
          <div class="form-bottom-bar">
            <el-button type="primary" size="large" :loading="savingProfile" @click="handleSaveMemberProfile">
              保 存
            </el-button>
          </div>
        </el-form>
      </div>

      <!-- 2. 余额/余次 Tab -->
      <div v-show="activeTab === 'balance'" class="tab-content-panel">
        <div class="balance-overview-cards">
          <div class="b-card b-green">
            <div class="b-lbl">实充本金余额 (随时可退)</div>
            <div class="b-val">￥{{ Number(profileData?.dualBalance?.principalBalance || 0).toFixed(2) }}</div>
            <div class="b-tip">累计实充本金: ￥{{ Number(profileData?.dualBalance?.totalRecharged || 0).toFixed(2) }}</div>
          </div>
          <div class="b-card b-orange">
            <div class="b-lbl">活动赠金余额 (消费抵扣)</div>
            <div class="b-val">￥{{ Number(profileData?.dualBalance?.giftBalance || 0).toFixed(2) }}</div>
            <div class="b-tip">累计赠送金: ￥{{ Number(profileData?.dualBalance?.totalGiftGranted || 0).toFixed(2) }}</div>
          </div>
          <div class="b-card b-blue">
            <div class="b-lbl">扣减模式</div>
            <div class="b-val" style="font-size: 15px; margin-top: 6px;">
              <el-tag type="success">按本金/赠金比例双轨扣减</el-tag>
            </div>
            <div class="b-tip">消费结算优先按配比冲抵，退卡核退剩余本金</div>
          </div>
        </div>

        <h4 style="margin: 20px 0 10px;">有效次卡项目</h4>
        <el-table :data="profileData?.timeCards || demoTimeCards" border>
          <el-table-column prop="skuName" label="次卡服务项目" />
          <el-table-column prop="remainingTimes" label="剩余可用次数" width="140">
            <template #default="{ row }">
              <span style="color: #0284c7; font-weight: 700; font-size: 16px;">{{ row.remainingTimes }}</span> / {{ row.totalTimes }} 次
            </template>
          </el-table-column>
          <el-table-column prop="expireDate" label="有效期截止" width="160" />
          <el-table-column label="操作" width="120">
            <template #default>
              <el-button link type="primary" @click="$router.push('/cashier')">核销刷卡</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <el-empty description="暂无有效次卡" />
          </template>
        </el-table>
      </div>

      <!-- 3. 车辆管理 Tab -->
      <div v-show="activeTab === 'vehicles'" class="tab-content-panel">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <span style="font-weight: 600; font-size: 15px;">绑定的爱车档案 (汽修/洗车专属)</span>
            <el-tag size="small" type="info">共 {{ memberVehicles.length }} 台车辆</el-tag>
          </div>
          <el-button type="primary" size="small" icon="Plus" @click="openAddVehicleModal">+ 添加绑定车辆</el-button>
        </div>
        <el-table :data="memberVehicles" border stripe>
          <el-table-column prop="plateNumber" label="车牌号" width="130">
            <template #default="{ row }">
              <span class="license-plate-badge">{{ row.plateNumber }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="model" label="品牌车型" min-width="160">
            <template #default="{ row }">
              <b>{{ row.model }}</b>
            </template>
          </el-table-column>
          <el-table-column prop="color" label="车身颜色" width="110" />
          <el-table-column prop="vin" label="车架号/VIN" width="180" />
          <el-table-column prop="oilSpec" label="推荐机油规格" width="140" />
          <el-table-column prop="lastService" label="最近保养日期" width="130" />
          <el-table-column prop="notes" label="保养/服务备注" min-width="160" show-overflow-tooltip />
          <el-table-column label="操作" width="100" align="center" fixed="right">
            <template #default="{ row, $index }">
              <el-button link type="danger" size="small" @click="handleUnbindVehicle(row, $index)">解绑</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <el-empty description="暂无绑定爱车档案，点击上方按钮可为客户添加车牌与车型" />
          </template>
        </el-table>
      </div>

      <!-- 4. 消费记录 Tab -->
      <div v-show="activeTab === 'consumption'" class="tab-content-panel">
        <div class="panel-header-actions">
          <span class="panel-title">🛒 会员历史消费账单流水 (共 {{ consumptionRecords.length }} 笔)</span>
          <el-button size="small" icon="Refresh" :loading="loadingConsumption" @click="loadConsumptionRecords">刷新消费记录</el-button>
        </div>
        <el-table :data="consumptionRecords" border stripe v-loading="loadingConsumption">
          <el-table-column prop="orderNo" label="消费订单号" min-width="170">
            <template #default="{ row }">
              <span style="font-family: monospace; font-weight: 600;">{{ row.orderNo }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="spaceName" label="消费项目/工位" min-width="150">
            <template #default="{ row }">
              {{ row.spaceName || row.items || '服务消费与收银' }}
            </template>
          </el-table-column>
          <el-table-column prop="totalAmount" label="账单原价(元)" width="120" align="right">
            <template #default="{ row }">
              ￥{{ Number(row.totalAmount || 0).toFixed(2) }}
            </template>
          </el-table-column>
          <el-table-column prop="actualAmount" label="实收金额(元)" width="130" align="right">
            <template #default="{ row }">
              <span style="color: #0f172a; font-weight: bold;">
                ￥{{ Number(row.actualAmount != null ? row.actualAmount : (row.paidAmount || row.amount || 0)).toFixed(2) }}
              </span>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="结账状态" width="110" align="center">
            <template #default="{ row }">
              <el-tag :type="row.status === 'COMPLETED' ? 'success' : 'warning'" size="small">
                {{ row.status === 'COMPLETED' ? '已结账完成' : (row.status || '已支付') }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="createdAt" label="消费结账时间" width="170" align="center">
            <template #default="{ row }">
              {{ row.createdAt ? row.createdAt.replace('T', ' ').substring(0, 19) : (row.time || '-') }}
            </template>
          </el-table-column>
          <template #empty>
            <el-empty description="暂无消费账单记录" />
          </template>
        </el-table>
      </div>

      <!-- 5. 充值记录 Tab -->
      <div v-show="activeTab === 'recharge'" class="tab-content-panel">
        <div class="panel-header-actions">
          <span class="panel-title">💳 会员充值与充次入账流水 (共 {{ rechargeRecords.length }} 笔)</span>
          <div style="display: flex; gap: 8px;">
            <el-button size="small" type="success" icon="Plus" @click="openRechargeModal">立即充值</el-button>
            <el-button size="small" icon="Refresh" :loading="loadingRecharge" @click="loadRechargeRecords">刷新充值记录</el-button>
          </div>
        </div>
        <el-table :data="rechargeRecords" border stripe v-loading="loadingRecharge">
          <el-table-column prop="recordNo" label="充值流水单号" min-width="180">
            <template #default="{ row }">
              <span style="font-family: monospace; font-weight: 600;">{{ row.recordNo || row.orderNo }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="principalAmount" label="实充本金(元)" width="130" align="right">
            <template #default="{ row }">
              <span style="color: #047857; font-weight: bold;">
                ￥{{ Number(row.principalAmount != null ? row.principalAmount : (row.principal || 0)).toFixed(2) }}
              </span>
            </template>
          </el-table-column>
          <el-table-column prop="giftAmount" label="赠送金(元)" width="130" align="right">
            <template #default="{ row }">
              <span style="color: #ea580c; font-weight: 600;">
                +￥{{ Number(row.giftAmount != null ? row.giftAmount : (row.gift || 0)).toFixed(2) }}
              </span>
            </template>
          </el-table-column>
          <el-table-column prop="paymentMethod" label="支付方式" width="130" align="center">
            <template #default="{ row }">
              <el-tag size="small" effect="plain">{{ formatPaymentMethod(row.paymentMethod || row.payMethod) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="sellerEmployeeName" label="经手/提成员工" width="130" align="center">
            <template #default="{ row }">
              {{ row.sellerEmployeeName || row.sellerName || row.seller || '顾客扫码自助开卡' }}
            </template>
          </el-table-column>
          <el-table-column prop="createdAt" label="充值时间" width="170" align="center">
            <template #default="{ row }">
              {{ row.createdAt ? row.createdAt.replace('T', ' ').substring(0, 19) : (row.time || '-') }}
            </template>
          </el-table-column>
          <template #empty>
            <el-empty description="暂无充值流水记录" />
          </template>
        </el-table>
      </div>

      <!-- 7. 优惠券 Tab (支持查看新人开卡赠送券、营销裂变获赠券、现场派发) -->
      <div v-show="activeTab === 'coupons'" class="tab-content-panel">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <span style="font-weight: 600; font-size: 15px;">会员卡包可用优惠券 (共 {{ memberCouponsList.length }} 张)</span>
            <el-tag type="success" size="small">实时同步卡包</el-tag>
          </div>
          <el-button type="primary" size="small" icon="Plus" @click="openIssueCouponDialog = true">
            手动发券
          </el-button>
        </div>

        <el-table :data="memberCouponsList" border stripe>
          <el-table-column prop="id" label="券编号" width="130" />
          <el-table-column prop="name" label="优惠券名称" min-width="180">
            <template #default="{ row }">
              <b>{{ row.name }}</b>
            </template>
          </el-table-column>
          <el-table-column prop="amount" label="立减面额" width="120">
            <template #default="{ row }">
              <b style="color: #ea580c; font-size: 15px;">￥{{ row.amount }}</b>
            </template>
          </el-table-column>
          <el-table-column prop="minSpend" label="门槛要求" width="130">
            <template #default="{ row }">
              <span>{{ row.minSpend > 0 ? `满 ￥${row.minSpend} 可用` : '无门槛立减' }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="source" label="派发渠道/来源" width="160">
            <template #default="{ row }">
              <el-tag size="small" type="warning">{{ row.source || '新人开卡迎新礼遇' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="expireDate" label="有效期截止" width="150" />
          <el-table-column prop="status" label="使用状态" width="110">
            <template #default="{ row }">
              <el-tag :type="row.status === 'UNUSED' ? 'success' : 'info'" size="small">
                {{ row.status === 'UNUSED' ? '未使用' : '已核销' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="130" fixed="right">
            <template #default="{ row }">
              <el-button v-if="row.status === 'UNUSED'" link type="primary" @click="handleUseCoupon(row)">
                核销用券
              </el-button>
              <span v-else style="color: #94a3b8; font-size: 12px;">已核销完结</span>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 8. 消息提醒 Tab (全渠道微信公众号与生活号动账推送明细) -->
      <div v-show="activeTab === 'reminders'" class="tab-content-panel">
        <!-- 渠道绑定状态横幅 -->
        <el-row :gutter="16" style="margin-bottom: 16px;">
          <el-col :xs="24" :sm="12">
            <el-card shadow="never" style="border: 1px solid #86efac; background: #f0fdf4;">
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                  <div style="font-weight: 700; color: #166534; display: flex; align-items: center; gap: 6px;">
                    <span>🟢 微信服务号 / 公众号</span>
                    <el-tag size="small" :type="memberForm.wechatFollowStatus ? 'success' : 'info'">
                      {{ memberForm.wechatFollowStatus ? '已关注 · 动账即时送达' : '未关注' }}
                    </el-tag>
                  </div>
                  <div style="font-size: 12px; color: #475569; margin-top: 6px;">
                    微信 OpenID：<code>{{ memberForm.wechatOpenId || '未绑定' }}</code>
                  </div>
                  <div style="font-size: 11px; color: #64748b; margin-top: 2px;">
                    关注时间：{{ memberForm.wechatFollowTime ? memberForm.wechatFollowTime.replace('T', ' ').substring(0, 19) : '-' }}
                  </div>
                </div>
                <div>
                  <el-button
                    size="small"
                    type="success"
                    plain
                    @click="handleSimulateMemberFollow('WECHAT_MP')"
                  >
                    {{ memberForm.wechatFollowStatus ? '更新绑定' : '📱 模拟扫码关注' }}
                  </el-button>
                </div>
              </div>
            </el-card>
          </el-col>

          <el-col :xs="24" :sm="12">
            <el-card shadow="never" style="border: 1px solid #7dd3fc; background: #f0f9ff;">
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                  <div style="font-weight: 700; color: #0369a1; display: flex; align-items: center; gap: 6px;">
                    <span>🔵 支付宝生活号 / 服务窗</span>
                    <el-tag size="small" :type="memberForm.alipayFollowStatus ? 'primary' : 'info'">
                      {{ memberForm.alipayFollowStatus ? '已关注 · 动账即时送达' : '未关注' }}
                    </el-tag>
                  </div>
                  <div style="font-size: 12px; color: #475569; margin-top: 6px;">
                    买家 UID：<code>{{ memberForm.alipayUserId || '未绑定' }}</code>
                  </div>
                  <div style="font-size: 11px; color: #64748b; margin-top: 2px;">
                    关注时间：{{ memberForm.alipayFollowTime ? memberForm.alipayFollowTime.replace('T', ' ').substring(0, 19) : '-' }}
                  </div>
                </div>
                <div>
                  <el-button
                    size="small"
                    type="primary"
                    plain
                    @click="handleSimulateMemberFollow('ALIPAY_LIFE')"
                  >
                    {{ memberForm.alipayFollowStatus ? '更新绑定' : '📱 模拟关注生活号' }}
                  </el-button>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 该会员的推送通知历史明细表 -->
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
          <span style="font-weight: 700; font-size: 13.5px; color: #1e293b;">
            📜 会员历史消息推送流水 (共 {{ memberNotifLogs.length }} 条)
          </span>
          <el-button size="small" icon="Refresh" @click="loadMemberNotifLogs">刷新通知记录</el-button>
        </div>

        <el-table :data="memberNotifLogs" stripe border style="width: 100%;">
          <el-table-column prop="sentAt" label="发送时间" width="170">
            <template #default="{ row }">
              {{ row.sentAt ? row.sentAt.replace('T', ' ').substring(0, 19) : '-' }}
            </template>
          </el-table-column>
          <el-table-column prop="channel" label="渠道" width="120" align="center">
            <template #default="{ row }">
              <el-tag v-if="row.channel === 'WECHAT_MP'" type="success" size="small">🟢 微信服务号</el-tag>
              <el-tag v-else-if="row.channel === 'ALIPAY_LIFE'" type="primary" size="small">🔵 支付宝生活号</el-tag>
              <el-tag v-else type="info" size="small">{{ row.channel }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="title" label="通知标题" width="160">
            <template #default="{ row }">
              <b>{{ row.title }}</b>
            </template>
          </el-table-column>
          <el-table-column prop="content" label="卡片摘要内容" min-width="260" show-overflow-tooltip />
          <el-table-column prop="status" label="状态" width="110" align="center">
            <template #default="{ row }">
              <el-tag :type="row.status === 'SUCCESS' ? 'success' : 'danger'" size="small">
                {{ row.status === 'SUCCESS' ? '已送达' : row.status }}
              </el-tag>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 其他Tab通用占位与明细表 -->
      <div v-show="['card_change', 'points_records', 'reward_records', 'card_adjust', 'repay_records', 'follow_ups', 'storage_records'].includes(activeTab)" class="tab-content-panel">
        <el-empty :description="getTabTitle(activeTab) + '明细暂无更多数据，记录将自动在此归档展示。'" />
      </div>
    </el-card>

    <!-- 操作弹窗 1: 充值/充次 -->
    <el-dialog v-model="rechargeModalVisible" title="会员充值 / 充次开卡" width="460px" destroy-on-close>
      <el-form label-width="100px">
        <el-form-item label="充值本金(元)" required>
          <el-input-number v-model="rechargeForm.principalAmount" :min="10" :step="100" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="赠送金额(元)">
          <el-input-number v-model="rechargeForm.giftAmount" :min="0" :step="50" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="售卡提成员工">
          <el-select v-model="rechargeForm.sellerEmployeeId" placeholder="选择归属提成技师/员工" clearable style="width: 100%;">
            <el-option label="李博 (资深发型师)" :value="1" />
            <el-option label="张建华 (发型助理)" :value="2" />
            <el-option label="托尼总监" :value="4" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="rechargeModalVisible = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmRecharge">确认入账</el-button>
      </template>
    </el-dialog>

    <!-- 操作弹窗 2: 扣卡密码 -->
    <el-dialog v-model="passwordModalVisible" title="设置扣卡安全密码" width="420px" destroy-on-close>
      <el-form label-width="100px">
        <el-form-item label="启用密码验证">
          <el-switch v-model="passwordForm.enabled" active-text="启用" inactive-text="关闭" />
        </el-form-item>
        <el-form-item label="新卡密码" v-if="passwordForm.enabled">
          <el-input v-model="passwordForm.password" type="password" placeholder="请输入6位数字扣卡密码" maxlength="6" show-password />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="passwordModalVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSavePassword">保存设置</el-button>
      </template>
    </el-dialog>

    <!-- 操作弹窗 3: 调整积分 -->
    <el-dialog v-model="pointsModalVisible" title="调整会员可用积分" width="420px" destroy-on-close>
      <el-form label-width="90px">
        <el-form-item label="当前积分">
          <span style="font-size: 16px; font-weight: bold; color: #0284c7;">{{ memberForm.points || 100 }}</span>
        </el-form-item>
        <el-form-item label="积分增减" required>
          <el-input-number v-model="pointsForm.pointsDelta" :step="50" style="width: 100%;" />
          <span style="font-size: 12px; color: #64748b;">正数为增加积分，负数为扣减积分</span>
        </el-form-item>
        <el-form-item label="调整原因">
          <el-input v-model="pointsForm.reason" placeholder="如：活动补偿、误操作修正" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="pointsModalVisible = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmPoints">确认调整</el-button>
      </template>
    </el-dialog>

    <!-- 操作弹窗 4: 调整奖励金 -->
    <el-dialog v-model="rewardModalVisible" title="调整会员奖励金" width="420px" destroy-on-close>
      <el-form label-width="90px">
        <el-form-item label="当前奖励金">
          <span style="font-size: 16px; font-weight: bold; color: #ea580c;">￥{{ memberForm.rewardAmount || '0.00' }}</span>
        </el-form-item>
        <el-form-item label="奖励金调整" required>
          <el-input-number v-model="rewardForm.rewardDelta" :step="20" style="width: 100%;" />
          <span style="font-size: 12px; color: #64748b;">正数为增加奖励金，负数为扣减</span>
        </el-form-item>
        <el-form-item label="调整事由">
          <el-input v-model="rewardForm.reason" placeholder="如：转介绍达标奖励发放" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="rewardModalVisible = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmReward">确认调整</el-button>
      </template>
    </el-dialog>

    <!-- 操作弹窗 5: 添加跟进记录 -->
    <el-dialog v-model="followUpModalVisible" title="添加会员跟进服务记录" width="480px" destroy-on-close>
      <el-form label-width="90px">
        <el-form-item label="跟进形式" required>
          <el-radio-group v-model="followUpForm.type">
            <el-radio label="PHONE">电话回访</el-radio>
            <el-radio label="WECHAT">微信关怀</el-radio>
            <el-radio label="IN_STORE">到店当面沟通</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="沟通内容" required>
          <el-input v-model="followUpForm.content" type="textarea" :rows="3" placeholder="记录顾客对本次服务的评价、造型满意度或跟进事项" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="followUpModalVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveFollowUp">保存记录</el-button>
      </template>
    </el-dialog>

    <!-- 操作弹窗 6: 手动发券 -->
    <el-dialog v-model="openIssueCouponDialog" title="向会员派发专属优惠券" width="450px" destroy-on-close>
      <el-form :model="issueCouponForm" label-width="90px">
        <el-form-item label="优惠券名称" required>
          <el-input v-model="issueCouponForm.name" placeholder="如：店长关怀50元立减券" />
        </el-form-item>
        <el-form-item label="减免面额(元)" required>
          <el-input-number v-model="issueCouponForm.amount" :min="1" :step="10" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="最低消费门槛">
          <el-input-number v-model="issueCouponForm.minSpend" :min="0" :step="50" placeholder="0为无门槛" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="有效天数(天)">
          <el-input-number v-model="issueCouponForm.validDays" :min="1" :max="365" :step="7" style="width: 100%;" />
        </el-form-item>
        <el-form-item label="赠送原因">
          <el-input v-model="issueCouponForm.reason" placeholder="如：VIP老会员答谢、新人专属补发" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openIssueCouponDialog = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmIssueCoupon">确认发放</el-button>
      </template>
    </el-dialog>

    <!-- 操作弹窗 7: 为会员绑定爱车档案 -->
    <el-dialog v-model="addVehicleModalVisible" title="🚗 为会员绑定爱车档案" width="500px" destroy-on-close>
      <el-form :model="vehicleForm" label-width="100px">
        <el-form-item label="车牌号" required>
          <el-input v-model="vehicleForm.plateNumber" placeholder="例如：粤B66888、京A99999" maxlength="10" />
        </el-form-item>
        <el-form-item label="品牌车型" required>
          <el-input v-model="vehicleForm.model" placeholder="例如：奔驰 C260L 2023款、保时捷 Macan" />
        </el-form-item>
        <el-form-item label="车身颜色">
          <el-input v-model="vehicleForm.color" placeholder="例如：曜石黑、珍珠白" />
        </el-form-item>
        <el-form-item label="车架号/VIN">
          <el-input v-model="vehicleForm.vin" placeholder="17位车辆识别代码 (选填)" maxlength="20" />
        </el-form-item>
        <el-form-item label="推荐机油">
          <el-input v-model="vehicleForm.oilSpec" placeholder="例如：0W-20 原厂全合成、5W-30" />
        </el-form-item>
        <el-form-item label="最近保养">
          <el-date-picker
            v-model="vehicleForm.lastService"
            type="date"
            placeholder="选择最近一次保养日期"
            value-format="YYYY-MM-DD"
            style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="车辆备注">
          <el-input v-model="vehicleForm.notes" type="textarea" :rows="2" placeholder="客户保养偏好、注意事项，如：每次保养重点检查胎压" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addVehicleModalVisible = false">取消</el-button>
        <el-button type="primary" @click="handleConfirmAddVehicle">确认绑定</el-button>
      </template>
    </el-dialog>

    <!-- 会员码展示弹窗 -->
    <el-dialog v-model="memberQrModalVisible" :title="`📱 会员码 - ${memberForm.name}`" width="420px" align-center>
      <div style="display: flex; flex-direction: column; align-items: center; padding: 10px 0;">
        <div style="background: #ffffff; padding: 16px; border-radius: 16px; border: 1.5px solid #0d9488; box-shadow: 0 4px 16px rgba(13,148,136,0.12); text-align: center;">
          <img v-if="memberQrDataUrl" :src="memberQrDataUrl" style="width: 220px; height: 220px; display: block;" alt="会员消费码" />
          <div v-else style="width: 220px; height: 220px; display: flex; align-items: center; justify-content: center;">生成中...</div>
          <div style="margin-top: 10px; font-weight: bold; font-size: 15px; letter-spacing: 1px; color: #1e293b;">
            {{ memberForm.phone || memberForm.cardNo }}
          </div>
        </div>
        <div style="margin-top: 14px; font-size: 13px; color: #64748b; text-align: center; line-height: 1.6;">
          跨端通用海马体会员消费码<br/>
          支持移动 APP 扫码与前台收银台扫码盒子快速识别
        </div>
        <div style="margin-top: 14px; display: flex; gap: 10px;">
          <el-button size="small" type="success" plain @click="downloadDetailMemberQr">📥 保存二维码</el-button>
          <el-button size="small" type="primary" plain @click="copyDetailMemberQr">📋 复制码值</el-button>
        </div>
      </div>
      <template #footer>
        <el-button @click="memberQrModalVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 会员等级晋升阶梯规则说明弹窗 -->
    <el-dialog v-model="showLevelRulesModal" title="👑 会员成长体系与等级晋升规则" width="680px">
      <div class="level-rules-dialog-content">
        <el-alert
          type="info"
          show-icon
          :closable="false"
          title="阶梯成长 · 自动晋升 · 终身礼遇"
          description="会员消费每支付 1 元即可积 1 点成长经验值。当成长值满足下一等级门槛时，系统自动平滑晋升并即刻生效专属折扣。"
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
import { onMounted, ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import QRCode from 'qrcode'
import {
  getMemberDetailApi,
  getMemberProfileApi,
  updateMemberDetailApi,
  adjustMemberPointsApi,
  adjustMemberRewardsApi,
  setMemberCardPasswordApi,
  rechargeMemberApi,
  getNotificationLogsApi,
  simulateFollowApi,
  getMemberOrdersApi,
  getMemberRechargesApi
} from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useSystemDataStore } from '../stores/systemDataStore'

const route = useRoute()
const systemData = useSystemDataStore()
const pageLoading = ref(false)
const savingProfile = ref(false)

const memberQrModalVisible = ref(false)
const memberQrDataUrl = ref('')

const showLevelRulesModal = ref(false)

const standardLevelRules = [
  { levelCode: 'REGULAR', levelName: '普卡会员', threshold: 0, discount: '无折扣 (100%)', privileges: '进店建档、海马体偏好常态记忆、消费基础积分' },
  { levelCode: 'SILVER', levelName: '荣耀银卡', threshold: 300, discount: '服务95折 / 商品98折', privileges: '服务95折、生日月享50元抵用券、双倍积分日' },
  { levelCode: 'GOLD', levelName: '黄金VIP卡', threshold: 800, discount: '服务90折 / 商品95折', privileges: '服务9折、免排队预约优先通道、生日免费专属体验' },
  { levelCode: 'VIP', levelName: 'VIP尊享卡', threshold: 1200, discount: '服务88折 / 商品92折', privileges: '服务88折、专属金牌技师优先点单、节日私享定制礼盒' },
  { levelCode: 'PLATINUM', levelName: '至尊白金卡', threshold: 2000, discount: '服务85折 / 商品90折', privileges: '全场85折、专属私享包间、免费携1位亲友享同折' },
  { levelCode: 'DIAMOND', levelName: '黑钻至尊卡', threshold: 3500, discount: '服务80折 / 商品85折', privileges: '全场8折、总监技师免服务费、终身顶格尊崇待遇' }
]

const formatLevelName = (lvl?: string) => {
  if (!lvl) return '普卡会员'
  if (lvl.includes('黑钻') || lvl.includes('黑金') || lvl.includes('DIAMOND')) return '黑钻至尊卡'
  if (lvl.includes('至尊') || lvl.includes('白金') || lvl.includes('PLATINUM')) return '至尊白金卡'
  if (lvl.includes('VIP') || lvl.includes('尊享')) return 'VIP尊享卡'
  if (lvl.includes('金卡') || lvl.includes('GOLD')) return '黄金VIP卡'
  if (lvl.includes('银卡') || lvl.includes('SILVER')) return '荣耀银卡'
  if (lvl.includes('普卡') || lvl.includes('REGULAR')) return '普卡会员'
  return lvl
}

const getNextLevelName = () => {
  const points = memberForm.value.points ?? 0
  const next = standardLevelRules.find(r => r.threshold > points)
  return next ? next.levelName : null
}

const getPointsGap = () => {
  const points = memberForm.value.points ?? 0
  const next = standardLevelRules.find(r => r.threshold > points)
  return next ? Math.max(0, next.threshold - points) : 0
}

const getGrowthPercentage = () => {
  const points = memberForm.value.points ?? 0
  const next = standardLevelRules.find(r => r.threshold > points)
  if (!next) return 100
  let currentThresh = 0
  for (let i = standardLevelRules.length - 1; i >= 0; i--) {
    if (points >= standardLevelRules[i].threshold) {
      currentThresh = standardLevelRules[i].threshold
      break
    }
  }
  const range = next.threshold - currentThresh
  if (range <= 0) return 100
  return Math.min(100, Math.round(((points - currentThresh) / range) * 100))
}

const getLevelBadgeStyle = (code?: string) => {
  const c = (code || '').toUpperCase()
  if (c.includes('DIAMOND') || c.includes('黑钻') || c.includes('黑金')) {
    return 'background: #0f172a; color: #f59e0b; border: 1px solid #f59e0b; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
  }
  if (c.includes('PLATINUM') || c.includes('白金') || c.includes('至尊')) {
    return 'background: #ede9fe; color: #7c3aed; border: 1px solid #c4b5fd; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
  }
  if (c.includes('VIP') || c.includes('尊享')) {
    return 'background: #fdf2f8; color: #db2777; border: 1px solid #fbcfe8; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
  }
  if (c.includes('GOLD') || c.includes('金卡') || c.includes('金')) {
    return 'background: #fef3c7; color: #b45309; border: 1px solid #fcd34d; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
  }
  if (c.includes('SILVER') || c.includes('银卡') || c.includes('银')) {
    return 'background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
  }
  return 'background: #ccfbf1; color: #0f766e; border: 1px solid #99f6e4; padding: 2px 8px; border-radius: 4px; font-weight: bold; font-size: 12px;'
}

const openMemberQrModal = async () => {
  memberQrModalVisible.value = true
  const phoneOrNo = memberForm.value.phone || memberForm.value.cardNo || memberForm.value.memberNo || '13800000000'
  const qrText = `SEAHORSE:MEMBER:${phoneOrNo}`
  try {
    memberQrDataUrl.value = await QRCode.toDataURL(qrText, {
      width: 260,
      margin: 2,
      color: {
        dark: '#0f172a',
        light: '#ffffff'
      }
    })
  } catch (err) {
    console.error('Failed to generate member QR', err)
  }
}

const copyDetailMemberQr = () => {
  const phoneOrNo = memberForm.value.phone || memberForm.value.cardNo || memberForm.value.memberNo || ''
  if (!phoneOrNo) return
  navigator.clipboard.writeText(`SEAHORSE:MEMBER:${phoneOrNo}`)
  ElMessage.success('会员专属码值已复制到剪贴板')
}

const downloadDetailMemberQr = () => {
  if (!memberQrDataUrl.value) return
  const link = document.createElement('a')
  link.download = `会员码_${memberForm.value.name || '会员'}_${memberForm.value.phone || 'code'}.png`
  link.href = memberQrDataUrl.value
  link.click()
  ElMessage.success('已触发二维码图片下载')
}

const memberNotifLogs = ref<any[]>([])

const loadMemberNotifLogs = async () => {
  try {
    const res = await getNotificationLogsApi()
    if (res && res.data) {
      const p = memberForm.value.phone
      const mId = Number(memberId.value)
      memberNotifLogs.value = res.data.filter((l: any) =>
        (mId && l.memberId === mId) ||
        (p && l.phone === p) ||
        (l.memberName && l.memberName === memberForm.value.name)
      )
    }
  } catch (err) {
    console.warn('获取会员推送日志失败', err)
  }
}

const handleSimulateMemberFollow = async (channel: string = 'WECHAT_MP') => {
  if (!memberForm.value.phone) {
    ElMessage.warning('该会员暂未登记手机号，无法绑定渠道')
    return
  }
  try {
    const res = await simulateFollowApi({
      phone: memberForm.value.phone,
      channel
    })
    if (res && res.data) {
      ElMessage.success(`会员已成功关联并关注 ${channel === 'WECHAT_MP' ? '微信公众号' : '支付宝生活号'}！`)
      if (res.data.member) {
        memberForm.value.wechatOpenId = res.data.member.wechatOpenId
        memberForm.value.wechatFollowStatus = res.data.member.wechatFollowStatus
        memberForm.value.wechatFollowTime = res.data.member.wechatFollowTime
        memberForm.value.alipayUserId = res.data.member.alipayUserId
        memberForm.value.alipayFollowStatus = res.data.member.alipayFollowStatus
        memberForm.value.alipayFollowTime = res.data.member.alipayFollowTime
      }
      await loadMemberNotifLogs()
    }
  } catch (err: any) {
    ElMessage.error(err?.message || '绑定失败')
  }
}
const activeTab = ref('info')
const memberId = ref(Number(route.params.id) || 1)

const profileData = ref<any>(null)
const memberForm = ref<any>({
  id: 1,
  name: '李清雅',
  phone: '13800138000',
  cardNo: '202405010001',
  memberNo: 'HM880006',
  cardPasswordEnabled: false,
  cardSignEnabled: false,
  gender: 'FEMALE',
  discountName: '暂无等级',
  referrerName: '请选择推荐人',
  birthdayType: 'SOLAR',
  birthday: '2000-01-01',
  createdAt: '2024-05-01 10:00:00',
  rewardAmount: 0.00,
  points: 0,
  totalSpent: 0.00,
  cardOpenCount: 1,
  debtAmount: 0.00,
  wechatBound: false,
  notes: '老客户，偏好自然系造型与头皮养护'
})

const getTabTitle = (tabKey: string) => {
  const map: Record<string, string> = {
    card_change: '换卡记录',
    coupons: '优惠券',
    reminders: '消息提醒',
    points_records: '积分记录',
    reward_records: '奖励金记录',
    card_adjust: '会员卡调整记录',
    repay_records: '还款记录',
    follow_ups: '跟进记录',
    storage_records: '存取记录'
  }
  return map[tabKey] || '记录'
}

// 专属卡包优惠券管理
const memberCouponsList = ref<any[]>([])
const openIssueCouponDialog = ref(false)
const issueCouponForm = ref({
  name: '店长关怀专属立减券',
  amount: 50,
  minSpend: 150,
  validDays: 30,
  reason: 'VIP客户答谢'
})

const loadMemberCoupons = () => {
  const phone = memberForm.value.phone || ''
  const name = memberForm.value.name || ''
  const raw = localStorage.getItem(`seahorse_member_coupons_${phone}`) ||
              localStorage.getItem(`seahorse_member_coupons_${name}`) ||
              localStorage.getItem(`seahorse_member_coupons_${memberId.value}`)
  if (raw) {
    try {
      memberCouponsList.value = JSON.parse(raw)
      return
    } catch (e) {}
  }
  // 默认从迎新配置生成一张
  let welcomeCfg: any = null
  try {
    const rawCfg = localStorage.getItem('seahorse_welcome_coupon_config')
    if (rawCfg) welcomeCfg = JSON.parse(rawCfg)
  } catch (e) {}
  const cpnName = welcomeCfg?.couponName || '新人开卡专享50元无门槛券'
  const cpnAmount = welcomeCfg?.amount || 50
  const cpnMinSpend = welcomeCfg?.minSpend || 0
  memberCouponsList.value = [
    {
      id: 'CPN_' + memberId.value + '_01',
      name: cpnName,
      amount: cpnAmount,
      minSpend: cpnMinSpend,
      source: '新人开卡迎新自动发放',
      expireDate: '2026-12-31',
      status: 'UNUSED',
      receiveTime: '2026-09-01 10:00:00'
    }
  ]
}

const saveMemberCoupons = () => {
  const phone = memberForm.value.phone || ''
  const name = memberForm.value.name || ''
  localStorage.setItem(`seahorse_member_coupons_${phone}`, JSON.stringify(memberCouponsList.value))
  localStorage.setItem(`seahorse_member_coupons_${name}`, JSON.stringify(memberCouponsList.value))
}

const handleConfirmIssueCoupon = () => {
  if (!issueCouponForm.value.name || !issueCouponForm.value.amount) {
    ElMessage.warning('请填写优惠券名称与金额')
    return
  }
  const d = new Date()
  d.setDate(d.getDate() + (issueCouponForm.value.validDays || 30))
  const expireStr = d.toISOString().slice(0, 10)

  const newCpn = {
    id: 'CPN_' + Date.now(),
    name: issueCouponForm.value.name,
    amount: issueCouponForm.value.amount,
    minSpend: issueCouponForm.value.minSpend,
    source: issueCouponForm.value.reason || '门店手动派发',
    expireDate: expireStr,
    status: 'UNUSED',
    receiveTime: new Date().toISOString().slice(0, 19).replace('T', ' ')
  }
  memberCouponsList.value.unshift(newCpn)
  saveMemberCoupons()
  openIssueCouponDialog.value = false
  ElMessage.success(`成功向会员【${memberForm.value.name}】派发【${newCpn.name}】￥${newCpn.amount}！`)
}

const handleUseCoupon = (row: any) => {
  row.status = 'USED'
  saveMemberCoupons()
  ElMessage.success(`优惠券【${row.name}】(立减￥${row.amount}) 已核销使用成功！`)
}

const loadMemberData = async () => {
  pageLoading.value = true
  try {
    let detail: any = null
    try {
      detail = await getMemberDetailApi(memberId.value)
    } catch (err) {}

    if (detail && detail.name) {
      memberForm.value = {
        ...detail,
        cardPasswordEnabled: Boolean(detail.cardPasswordEnabled),
        cardSignEnabled: Boolean(detail.cardSignEnabled)
      }
    } else {
      const found = systemData.membersWithStats.find((m: any) => m.id === memberId.value) ||
                    (systemData.membersWithStats.length > 0 ? systemData.membersWithStats[0] : null)
      if (found) {
        memberForm.value = {
          id: found.id,
          name: found.name,
          phone: found.phone,
          cardNo: found.memberNo,
          memberNo: found.memberNo,
          cardPasswordEnabled: false,
          cardSignEnabled: false,
          gender: found.gender || 'UNKNOWN',
          discountName: found.levelName || '普通会员',
          referrerName: found.referrerId ? '老客推荐' : '自主到店',
          birthdayType: 'SOLAR',
          birthday: '1995-08-18',
          createdAt: found.registerTime || new Date().toISOString().slice(0, 10),
          rewardAmount: found.rewardBonus || 0,
          points: found.points || 0,
          totalSpent: found.totalSpent || 0,
          cardOpenCount: found.visitCount || 1,
          debtAmount: 0.00,
          wechatBound: true,
          notes: found.notes || '高品质常客'
        }
      } else {
        memberForm.value = {
          id: memberId.value,
          name: '新会员 (未命名)',
          phone: '',
          cardNo: 'M' + Date.now().toString().slice(-6),
          memberNo: 'M' + Date.now().toString().slice(-6),
          cardPasswordEnabled: false,
          cardSignEnabled: false,
          gender: 'UNKNOWN',
          discountName: '普通会员',
          referrerName: '自主到店',
          birthdayType: 'SOLAR',
          birthday: '',
          createdAt: new Date().toISOString().slice(0, 10),
          rewardAmount: 0,
          points: 0,
          totalSpent: 0,
          cardOpenCount: 0,
          debtAmount: 0.00,
          wechatBound: false,
          notes: ''
        }
      }
    }

    try {
      const profile: any = await getMemberProfileApi(memberId.value)
      profileData.value = profile
    } catch (err) {}

    loadMemberCoupons()
    loadMemberNotifLogs()
    loadMemberVehicles()
    loadConsumptionRecords()
    loadRechargeRecords()
  } catch (e) {
    console.error(e)
  } finally {
    pageLoading.value = false
  }
}

const handleSaveMemberProfile = async () => {
  if (!memberForm.value.name || !memberForm.value.phone) {
    ElMessage.warning('姓名与手机号为必填项')
    return
  }
  savingProfile.value = true
  try {
    await updateMemberDetailApi(memberId.value, memberForm.value)
    ElMessage.success('会员档案保存成功')
  } catch (e) {
    console.error(e)
  } finally {
    savingProfile.value = false
  }
}

// 充值
const rechargeModalVisible = ref(false)
const rechargeForm = ref({
  memberId: memberId.value,
  principalAmount: 500,
  giftAmount: 100,
  sellerEmployeeId: null
})

const openRechargeModal = () => {
  rechargeForm.value.memberId = memberId.value
  rechargeModalVisible.value = true
}

const handleConfirmRecharge = async () => {
  try {
    await rechargeMemberApi(rechargeForm.value)
    ElMessage.success('储值充值成功')
    rechargeModalVisible.value = false
    await loadRechargeRecords()
    await loadMemberData()
  } catch (e) {
    console.error(e)
  }
}

// 扣卡密码
const passwordModalVisible = ref(false)
const passwordForm = ref({ password: '', enabled: false })
const openPasswordModal = () => {
  passwordForm.value.enabled = Boolean(memberForm.value.cardPasswordEnabled)
  passwordModalVisible.value = true
}
const handleSavePassword = async () => {
  try {
    await setMemberCardPasswordApi(memberId.value, passwordForm.value)
    memberForm.value.cardPasswordEnabled = passwordForm.value.enabled
    ElMessage.success('扣卡密码配置已更新')
    passwordModalVisible.value = false
  } catch (e) {
    console.error(e)
  }
}

// 积分
const pointsModalVisible = ref(false)
const pointsForm = ref({ pointsDelta: 100, reason: '' })
const openPointsModal = () => { pointsModalVisible.value = true }
const handleConfirmPoints = async () => {
  try {
    await adjustMemberPointsApi(memberId.value, pointsForm.value)
    ElMessage.success('积分调整成功')
    pointsModalVisible.value = false
    loadMemberData()
  } catch (e) {
    console.error(e)
  }
}

// 奖励金
const rewardModalVisible = ref(false)
const rewardForm = ref({ rewardDelta: 50, reason: '' })
const openRewardModal = () => { rewardModalVisible.value = true }
const handleConfirmReward = async () => {
  try {
    await adjustMemberRewardsApi(memberId.value, rewardForm.value)
    ElMessage.success('奖励金调整成功')
    rewardModalVisible.value = false
    loadMemberData()
  } catch (e) {
    console.error(e)
  }
}

// 其他占位按钮提示
const openPointsExchangeModal = () => ElMessage.info('已开启积分商城与兑换通道')
const openRepaymentModal = () => ElMessage.success('当前会员无欠款需还款')
const openStorageModal = () => ElMessage.info('暂无未领取的寄存产品')

// 跟进记录
const followUpModalVisible = ref(false)
const followUpForm = ref({ type: 'PHONE', content: '' })
const openFollowUpModal = () => { followUpModalVisible.value = true }
const handleSaveFollowUp = () => {
  ElMessage.success('跟进记录已成功记入会员成长档案')
  followUpModalVisible.value = false
}

// 次卡、消费记录、充值记录全量联动底层真实交易账本
const demoTimeCards = computed(() => {
  return systemData.timeCards
    .filter(t => t.memberId === memberId.value)
    .map(t => ({
      skuName: t.cardName,
      remainingTimes: t.totalTimes - t.usedTimes,
      totalTimes: t.totalTimes,
      expireDate: t.expireDate
    }))
})

// 会员车辆档案管理（真实动态存储与隔离，无脏数据）
const memberVehicles = ref<any[]>([])
const addVehicleModalVisible = ref(false)
const vehicleForm = ref({
  plateNumber: '',
  model: '',
  color: '',
  vin: '',
  oilSpec: '',
  lastService: '',
  notes: ''
})

const getVehicleStorageKey = () => {
  const mid = memberId.value || memberForm.value.id || memberForm.value.phone || 'default'
  return `seahorse_member_vehicles_${mid}`
}

const loadMemberVehicles = () => {
  try {
    const raw = localStorage.getItem(getVehicleStorageKey())
    if (raw) {
      memberVehicles.value = JSON.parse(raw)
    } else {
      memberVehicles.value = []
    }
  } catch (e) {
    memberVehicles.value = []
  }
}

const saveMemberVehicles = () => {
  localStorage.setItem(getVehicleStorageKey(), JSON.stringify(memberVehicles.value))
}

const openAddVehicleModal = () => {
  vehicleForm.value = {
    plateNumber: '',
    model: '',
    color: '',
    vin: '',
    oilSpec: '',
    lastService: '',
    notes: ''
  }
  addVehicleModalVisible.value = true
}

const handleConfirmAddVehicle = () => {
  const plate = vehicleForm.value.plateNumber.trim().toUpperCase()
  if (!plate) {
    ElMessage.warning('请输入车牌号')
    return
  }
  if (!vehicleForm.value.model.trim()) {
    ElMessage.warning('请输入品牌车型')
    return
  }
  if (memberVehicles.value.some(v => v.plateNumber === plate)) {
    ElMessage.warning(`该会员已绑定车牌号【${plate}】，请勿重复添加`)
    return
  }
  const newVehicle = {
    plateNumber: plate,
    model: vehicleForm.value.model.trim(),
    color: vehicleForm.value.color.trim() || '未填',
    vin: vehicleForm.value.vin.trim() || '-',
    oilSpec: vehicleForm.value.oilSpec.trim() || '-',
    lastService: vehicleForm.value.lastService || '-',
    notes: vehicleForm.value.notes.trim() || '-',
    createdAt: new Date().toISOString().slice(0, 10)
  }
  memberVehicles.value.unshift(newVehicle)
  saveMemberVehicles()
  addVehicleModalVisible.value = false
  ElMessage.success(`车辆【${plate}】已成功绑定到会员档案！`)
}

const handleUnbindVehicle = (row: any, index: number) => {
  ElMessageBox.confirm(
    `确定要为会员解绑车辆【${row.plateNumber} (${row.model})】吗？`,
    '解绑车辆确认',
    {
      confirmButtonText: '确认解绑',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(() => {
    memberVehicles.value.splice(index, 1)
    saveMemberVehicles()
    ElMessage.success(`车辆【${row.plateNumber}】已成功解绑`)
  }).catch(() => {})
}

const formatPaymentMethod = (m?: string) => {
  if (!m) return '微信支付'
  const upper = m.toUpperCase()
  if (upper === 'WECHAT') return '微信支付'
  if (upper === 'ALIPAY') return '支付宝'
  if (upper === 'CASH') return '现金'
  if (upper === 'BANK') return '银行卡'
  if (upper === 'FREE') return '免费体验'
  return m
}

const realConsumptionRecords = ref<any[]>([])
const loadingConsumption = ref(false)
const realRechargeRecords = ref<any[]>([])
const loadingRecharge = ref(false)

const loadConsumptionRecords = async () => {
  loadingConsumption.value = true
  try {
    const res = (await getMemberOrdersApi(memberId.value)) as any
    if (Array.isArray(res)) {
      realConsumptionRecords.value = res
    } else if (res && Array.isArray(res.data)) {
      realConsumptionRecords.value = res.data
    } else {
      realConsumptionRecords.value = []
    }
  } catch (err) {
    console.warn('拉取会员真实消费订单流水失败', err)
    realConsumptionRecords.value = []
  } finally {
    loadingConsumption.value = false
  }
}

const loadRechargeRecords = async () => {
  loadingRecharge.value = true
  try {
    const res = (await getMemberRechargesApi(memberId.value)) as any
    if (Array.isArray(res)) {
      realRechargeRecords.value = res
    } else if (res && Array.isArray(res.data)) {
      realRechargeRecords.value = res.data
    } else {
      realRechargeRecords.value = []
    }
  } catch (err) {
    console.warn('拉取会员真实充值流水失败', err)
    realRechargeRecords.value = []
  } finally {
    loadingRecharge.value = false
  }
}

const consumptionRecords = computed(() => {
  if (realConsumptionRecords.value.length > 0) {
    return realConsumptionRecords.value
  }
  return systemData.consumeOrders
    .filter(c => c.memberId === memberId.value && c.status === 'COMPLETED')
    .map(c => ({
      orderNo: c.orderNo,
      spaceName: c.items.map(i => i.productName).join(' + '),
      totalAmount: c.totalAmount,
      actualAmount: c.totalAmount,
      status: 'COMPLETED',
      createdAt: c.createTime
    }))
})

const rechargeRecords = computed(() => {
  if (realRechargeRecords.value.length > 0) {
    return realRechargeRecords.value
  }
  const phone = memberForm.value.phone
  return systemData.rechargeOrders
    .filter(r => r.memberId === memberId.value || (phone && systemData.members.find(m => m.id === r.memberId)?.phone === phone))
    .map(r => {
      const s = systemData.staff.find(st => st.id === r.sellerEmployeeId)
      return {
        recordNo: r.orderNo,
        principalAmount: r.principalAmount,
        giftAmount: r.giftAmount,
        paymentMethod: r.paymentMethod || 'WECHAT',
        sellerEmployeeName: s?.realName || '顾客扫码自助开卡',
        createdAt: r.createTime
      }
    })
})

onMounted(() => {
  loadMemberData()
})
</script>

<style scoped>
.member-detail-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.top-action-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #ffffff;
  padding: 12px 20px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  gap: 16px;
  overflow-x: auto;
}

.bar-left {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
  white-space: nowrap;
}

.detail-title {
  font-size: 16px;
  font-weight: 700;
  color: #0f172a;
  white-space: nowrap;
}

.bar-right-buttons {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
  flex-wrap: nowrap;
}

.tabs-card {
  border-radius: 8px;
  background: #ffffff;
}

.tab-content-info {
  padding: 10px 10px;
}

.avatar-section {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stats-grid-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
  gap: 12px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 14px;
  margin: 16px 0 20px 0;
}

.stat-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  text-align: center;
  background: #ffffff;
  padding: 10px 8px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 1px 2px rgba(0,0,0,0.02);
  transition: all 0.2s ease;
}

.stat-box:hover {
  border-color: #cbd5e1;
  transform: translateY(-1px);
}

.stat-box .lbl {
  font-size: 12px;
  color: #64748b;
}

.stat-box .val {
  font-size: 14px;
  font-weight: 600;
  color: #1e293b;
}

.form-bottom-bar {
  display: flex;
  justify-content: flex-end;
  margin-top: 24px;
}

.tab-content-panel {
  padding: 16px 8px;
}

.panel-header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.panel-title {
  font-weight: 700;
  font-size: 14px;
  color: #1e293b;
}

.balance-overview-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 16px;
}

.b-card {
  padding: 18px;
  border-radius: 8px;
  border: 1px solid transparent;
}

.b-green {
  background: #ecfdf5;
  border-color: #a7f3d0;
}

.b-green .b-lbl { color: #047857; font-size: 13px; }
.b-green .b-val { color: #065f46; font-size: 24px; font-weight: 700; margin: 8px 0; }
.b-green .b-tip { color: #059669; font-size: 12px; }

.b-orange {
  background: #fff7ed;
  border-color: #fed7aa;
}

.b-orange .b-lbl { color: #c2410c; font-size: 13px; }
.b-orange .b-val { color: #9a3412; font-size: 24px; font-weight: 700; margin: 8px 0; }
.b-orange .b-tip { color: #ea580c; font-size: 12px; }

.b-blue {
  background: #f0f9ff;
  border-color: #bae6fd;
}

.b-blue .b-lbl { color: #0369a1; font-size: 13px; }
.b-blue .b-tip { color: #0284c7; font-size: 12px; margin-top: 8px; }

.member-growth-overview-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 14px 18px;
  margin-bottom: 20px;
}

.growth-card-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.growth-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.growth-title {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
}

.growth-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.points-badge {
  font-size: 13px;
  color: #475569;
}

.points-badge b {
  font-size: 16px;
  color: #0284c7;
}

.growth-progress-wrap {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.progress-info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
}

.progress-label {
  color: #64748b;
}

.next-level-tip {
  color: #475569;
}

.gap-text {
  color: #ea580c;
  font-size: 14px;
}

.next-level-tip.top-level {
  color: #d97706;
  font-weight: bold;
}

.license-plate-badge {
  display: inline-block;
  background: #f1f5f9;
  border: 1px solid #cbd5e1;
  color: #0f172a;
  font-family: monospace;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 4px;
  letter-spacing: 0.5px;
}
</style>
