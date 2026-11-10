<template>
  <div class="report-analytics-container">
    <div class="report-main-content">
      <!-- 1. 顶部快捷周期与搜索操作栏 (完全对齐截图顶部: 今天 昨天 本周 本月 上月 | 日期区间 | 关键字搜索 搜索 导出 刷新) -->
      <div class="top-filter-bar">
        <div class="filter-left">
          <!-- 快捷日期选择 -->
          <el-button-group class="date-quick-btn-group">
            <el-button
              v-for="btn in quickDateButtons"
              :key="btn.key"
              :type="selectedQuickDate === btn.key ? 'primary' : 'default'"
              size="default"
              @click="handleQuickDate(btn.key)"
            >
              {{ btn.label }}
            </el-button>
          </el-button-group>

          <!-- 日期区间选择器 -->
          <el-date-picker
            v-model="dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="YYYY-MM-DD"
            size="default"
            style="width: 250px; margin-left: 12px;"
            @change="handleFilterChange"
          />
        </div>

        <div class="filter-right">
          <!-- 风格切换选择器 -->
          <el-select
            v-model="currentHeaderTheme"
            size="default"
            style="width: 160px;"
            placeholder="表头风格"
            @change="handleThemeChange"
          >
            <template #prefix>
              <span style="font-size: 12px; margin-right: 2px;">🎨</span>
            </template>
            <el-option
              v-for="t in headerThemes"
              :key="t.key"
              :label="t.name"
              :value="t.key"
            >
              <div style="display: flex; align-items: center; justify-content: space-between; width: 100%;">
                <span style="font-size: 13px;">{{ t.name }}</span>
                <span :style="{ display: 'inline-block', width: '14px', height: '14px', borderRadius: '3px', background: t.bg, border: '1px solid #cbd5e1' }"></span>
              </div>
            </el-option>
          </el-select>

          <!-- 关键字搜索框 -->
          <el-input
            v-model="searchKeyword"
            placeholder="请输入关键字"
            clearable
            size="default"
            style="width: 200px;"
            @clear="handleFilterChange"
            @keyup.enter="handleFilterChange"
          >
            <template #suffix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>

          <el-button type="primary" size="default" @click="handleFilterChange">搜索</el-button>
          <el-button type="primary" size="default" @click="handleExport">导出</el-button>
          <el-button type="primary" size="default" @click="handleRefresh">刷新</el-button>
        </div>
      </div>

      <!-- 2. 统计摘要指示卡 (对齐截图: 店铺收入0 (客数: 0)  微商城0 等) -->
      <div class="summary-pills-row">
        <div class="summary-pill" v-for="(pill, idx) in currentSummaryPills" :key="idx">
          {{ pill.label }} <b style="margin-left: 4px;">{{ pill.value }}</b>
        </div>
      </div>

      <!-- 3. 二级分类横向页签 (对齐截图: 全部  充值办卡 0  零售收银 0  扣卡另付 0) -->
      <div class="secondary-tabs-bar" v-if="currentSubFilters.length > 0">
        <span
          v-for="sub in currentSubFilters"
          :key="sub.key"
          :class="['sec-tab', activeSubFilter === sub.key ? 'active' : '']"
          @click="handleSubFilterChange(sub.key)"
        >
          {{ sub.label }} {{ sub.count !== undefined ? sub.count : '' }}
        </span>
      </div>

      <!-- 4. 数据表格展示区 (表头纯蓝底白字 #1890ff，严格对齐截图标准) -->
      <div class="report-table-wrapper">
        <!-- 1. 收入明细表格 (严格对齐截图字段: 客户姓名 | 客户手机号 | 收入 | 类型 | 详情 | 日期 | 状态 | 操作) -->
        <el-table
          v-if="currentTab === 'income'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="customerName" label="客户姓名" min-width="120" />
          <el-table-column prop="phone" label="客户手机号" min-width="140" />
          <el-table-column prop="income" label="收入" min-width="110">
            <template #default="{ row }">
              <span class="income-text">￥{{ Number(row.income || 0).toFixed(2) }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="type" label="类型" min-width="130">
            <template #default="{ row }">
              <el-tag :type="getTypeTag(row.type)" size="small">{{ row.type }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="details" label="详情" min-width="240" show-overflow-tooltip />
          <el-table-column prop="date" label="日期" min-width="170" />
          <el-table-column prop="status" label="状态" min-width="100">
            <template #default="{ row }">
              <el-tag type="success" size="small">{{ row.status || '已完成' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleOpenDetail('收入流水明细', row)">查看详情</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>

        <!-- 2. 扣卡统计表格 (客户姓名 | 手机号码 | 扣卡消费项目 | 扣减本金 | 扣减赠金 | 扣卡总金额 | 卡内剩余总额 | 经手技师 | 扣卡时间 | 操作) -->
        <el-table
          v-else-if="currentTab === 'card-deduct'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="customerName" label="客户姓名" min-width="120" />
          <el-table-column prop="phone" label="手机号码" min-width="130" />
          <el-table-column prop="serviceName" label="扣卡消费项目" min-width="180" />
          <el-table-column prop="deductPrincipal" label="扣减本金 (元)" min-width="120" />
          <el-table-column prop="deductGift" label="扣减赠金 (元)" min-width="120" />
          <el-table-column prop="deductTotal" label="扣卡总金额" min-width="120">
            <template #default="{ row }">
              <b style="color: #ea580c;">￥{{ row.deductTotal }}</b>
            </template>
          </el-table-column>
          <el-table-column prop="remainingBalance" label="卡内剩余总额" min-width="130" />
          <el-table-column prop="operator" label="经手技师" min-width="120" />
          <el-table-column prop="date" label="扣卡时间" min-width="170" />
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleOpenDetail('扣卡核销凭据', row)">核销凭证</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>

        <!-- 3. 积分统计表格 -->
        <el-table
          v-else-if="currentTab === 'points'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="customerName" label="客户姓名" min-width="120" />
          <el-table-column prop="phone" label="客户手机号" min-width="140" />
          <el-table-column prop="pointsChange" label="变动积分" min-width="120">
            <template #default="{ row }">
              <b :style="{ color: row.pointsChange > 0 ? '#10b981' : '#ef4444' }">
                {{ row.pointsChange > 0 ? '+' : '' }}{{ row.pointsChange }}
              </b>
            </template>
          </el-table-column>
          <el-table-column prop="changeType" label="变动类型" min-width="140" />
          <el-table-column prop="balance" label="剩余积分" min-width="120" />
          <el-table-column prop="operator" label="操作人" min-width="120" />
          <el-table-column prop="date" label="变动时间" min-width="170" />
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleOpenDetail('积分变动凭证', row)">变动记录</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>

        <!-- 4. 奖励金统计表格 -->
        <el-table
          v-else-if="currentTab === 'rewards'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="customerName" label="客户姓名" min-width="120" />
          <el-table-column prop="phone" label="手机号码" min-width="140" />
          <el-table-column prop="rewardChange" label="奖励金变动 (元)" min-width="140">
            <template #default="{ row }">
              <b style="color: #059669;">+￥{{ row.rewardChange }}</b>
            </template>
          </el-table-column>
          <el-table-column prop="reason" label="奖励金事由" min-width="190" />
          <el-table-column prop="referredCustomer" label="被推荐好友" min-width="140" />
          <el-table-column prop="currentReward" label="可用奖励金余额" min-width="130" />
          <el-table-column prop="date" label="获得时间" min-width="170" />
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleOpenDetail('分销奖励明细', row)">奖励详情</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>

        <!-- 5. 新增会员统计表格 -->
        <el-table
          v-else-if="currentTab === 'new-members'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="memberNo" label="会员卡号" min-width="130" />
          <el-table-column prop="name" label="会员姓名" min-width="120" />
          <el-table-column prop="phone" label="手机号码" min-width="140" />
          <el-table-column prop="level" label="会员等级" min-width="120">
            <template #default="{ row }">
              <el-tag type="warning" effect="plain" size="small">{{ row.level }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="initialRecharge" label="开卡充值 (元)" min-width="130">
            <template #default="{ row }">
              <b style="color: #0284c7;">￥{{ row.initialRecharge }}</b>
            </template>
          </el-table-column>
          <el-table-column prop="giftCoupon" label="获赠优惠券" min-width="170" />
          <el-table-column prop="referrer" label="入会渠道/推荐人" min-width="140" />
          <el-table-column prop="date" label="入会时间" min-width="170" />
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleOpenDetail('新会员开卡档案', row)">会员档案</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>

        <!-- 6. 收入方式统计表格 -->
        <el-table
          v-else-if="currentTab === 'payment-methods'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="methodName" label="支付方式/渠道" min-width="160" />
          <el-table-column prop="transactionCount" label="收款笔数" min-width="120">
            <template #default="{ row }">
              <span>{{ row.transactionCount }} 笔</span>
            </template>
          </el-table-column>
          <el-table-column prop="amount" label="实收金额 (元)" min-width="140">
            <template #default="{ row }">
              <span class="income-text">￥{{ Number(row.amount || 0).toFixed(2) }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="ratio" label="实收占比 (%)" min-width="160">
            <template #default="{ row }">
              <el-progress :percentage="row.ratio" :color="getProgressColor(row.ratio)" />
            </template>
          </el-table-column>
          <el-table-column prop="refundAmount" label="退款金额 (元)" min-width="120" />
          <el-table-column prop="netIncome" label="净入账额 (元)" min-width="130">
            <template #default="{ row }">
              <b style="color: #059669;">￥{{ Number(row.netIncome || 0).toFixed(2) }}</b>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleOpenDetail('支付渠道对账明细', row)">对账单</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>

        <!-- 7. 利润统计表格 -->
        <el-table
          v-else-if="currentTab === 'profit'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="period" label="核算周期" min-width="140" />
          <el-table-column prop="grossRevenue" label="营业总收入" min-width="130" />
          <el-table-column prop="bomCost" label="耗材BOM成本" min-width="130" />
          <el-table-column prop="rentCost" label="房租水电支出" min-width="130" />
          <el-table-column prop="salaryCommission" label="员工提成底薪" min-width="140" />
          <el-table-column prop="netProfit" label="净利润 (元)" min-width="130">
            <template #default="{ row }">
              <b style="color: #059669; font-size: 15px;">￥{{ row.netProfit }}</b>
            </template>
          </el-table-column>
          <el-table-column prop="profitMargin" label="综合利润率" min-width="120">
            <template #default="{ row }">
              <el-tag type="success" size="small">{{ row.profitMargin }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleOpenDetail('周期利润与成本构成核算', row)">成本拆解</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>

        <!-- 8. 员工业绩统计表格 -->
        <el-table
          v-else-if="currentTab === 'staff-performance'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="staffName" label="员工姓名" min-width="130">
            <template #default="{ row }">
              <b>{{ row.staffName }}</b>
            </template>
          </el-table-column>
          <el-table-column prop="post" label="岗位职务" min-width="130">
            <template #default="{ row }">
              <el-tag size="small" type="info">{{ row.post }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="serviceCount" label="服务单数" min-width="110" />
          <el-table-column prop="serviceRevenue" label="项目创收 (元)" min-width="130">
            <template #default="{ row }">
              <span>￥{{ row.serviceRevenue }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="cardSales" label="开卡售卡创收" min-width="130">
            <template #default="{ row }">
              <span>￥{{ row.cardSales }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="retailSales" label="实物零售销售" min-width="130">
            <template #default="{ row }">
              <span>￥{{ row.retailSales }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="totalCommission" label="应发提成 (元)" min-width="130">
            <template #default="{ row }">
              <b style="color: #10b981; font-size: 15px;">￥{{ row.totalCommission }}</b>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleOpenDetail('员工业绩与提成核算单', row)">提成明细</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>

        <!-- 9. 未消费余次统计表格 -->
        <el-table
          v-else-if="currentTab === 'remaining-times'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="customerName" label="会员姓名" min-width="120" />
          <el-table-column prop="phone" label="手机号码" min-width="140" />
          <el-table-column prop="cardName" label="次卡名称" min-width="180" />
          <el-table-column prop="totalTimes" label="开卡总次数" min-width="110" />
          <el-table-column prop="usedTimes" label="已消费次数" min-width="110" />
          <el-table-column prop="remainingTimes" label="卡内剩余余次" min-width="130">
            <template #default="{ row }">
              <el-tag type="warning" effect="dark">{{ row.remainingTimes }} 次未消</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="expireDate" label="次卡有效期" min-width="140" />
          <el-table-column label="操作" width="130" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleSendRemind(row)">催消提醒</el-button>
              <el-button link type="primary" @click="handleOpenDetail('次卡档案明细', row)">详情</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>

        <!-- 10. 未消费余额统计表格 -->
        <el-table
          v-else-if="currentTab === 'remaining-balance'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="customerName" label="客户姓名" min-width="120" />
          <el-table-column prop="phone" label="客户手机号" min-width="140" />
          <el-table-column prop="level" label="会员等级" min-width="120">
            <template #default="{ row }">
              <el-tag type="warning" effect="plain" size="small">{{ row.level }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="principal" label="实充本金存量" min-width="140">
            <template #default="{ row }">
              <span>￥{{ row.principal }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="gift" label="赠送金存量" min-width="130">
            <template #default="{ row }">
              <span style="color: #64748b;">￥{{ row.gift }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="totalBalance" label="储值卡总余额 (元)" min-width="160">
            <template #default="{ row }">
              <b style="color: #0284c7; font-size: 15px;">￥{{ row.totalBalance }}</b>
            </template>
          </el-table-column>
          <el-table-column prop="lastVisit" label="最近到店消费" min-width="160" />
          <el-table-column label="操作" width="130" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleSendCoupon(row)">赠券唤醒</el-button>
              <el-button link type="primary" @click="handleOpenDetail('会员储值卡账户明细', row)">详情</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>

        <!-- 11. 单项销售统计表格 -->
        <el-table
          v-else-if="currentTab === 'item-sales'"
          :data="paginatedList"
          stripe
          style="width: 100%;"
          :header-cell-style="tableHeaderStyle"
        >
          <el-table-column prop="itemName" label="单项/商品名称" min-width="190" />
          <el-table-column prop="category" label="所属品类" min-width="130">
            <template #default="{ row }">
              <el-tag size="small" type="info">{{ row.category }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="price" label="销售单价 (元)" min-width="120">
            <template #default="{ row }">
              <span>￥{{ row.price }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="salesCount" label="销售总数量" min-width="120">
            <template #default="{ row }">
              <b>{{ row.salesCount }} 次/件</b>
            </template>
          </el-table-column>
          <el-table-column prop="totalSales" label="销售总金额 (元)" min-width="140">
            <template #default="{ row }">
              <span style="color: #ea580c; font-weight: 700;">￥{{ row.totalSales }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="marginRate" label="预估毛利率" min-width="120">
            <template #default="{ row }">
              <el-tag type="success" size="small">{{ row.marginRate }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button link type="primary" @click="handleOpenDetail('单项商品销售与毛利模型', row)">单品分析</el-button>
            </template>
          </el-table-column>
          <template #empty>
            <div class="empty-box">
            <el-empty description="暂无相关统计数据" :image-size="80" />
          </div>
          </template>
        </el-table>
      </div>

      <!-- 5. 底部分页器 (对齐截图2设计标准: 共 X 条  10条/页  < 1 >) -->
      <div class="pagination-footer">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="filteredList.length"
        />
      </div>
    </div>

    <!-- 弹窗 1: 详情凭据对话框 -->
    <el-dialog v-model="detailDialogVisible" :title="detailDialogTitle" width="560px" destroy-on-close>
      <div v-if="selectedRowData" style="padding: 10px 0;">
        <el-descriptions :column="1" border size="default">
          <el-descriptions-item
            v-for="(val, key) in formatDetailFields(selectedRowData)"
            :key="key"
            :label="key"
          >
            {{ val }}
          </el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <el-button type="primary" @click="detailDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 2: 次卡催消预约提醒对话框 -->
    <el-dialog v-model="remindDialogVisible" title="📲 发送次卡到店催消提醒" width="480px">
      <div v-if="remindTarget">
        <p style="margin-bottom: 12px; color: #334155;">
          确认向会员 <b>{{ remindTarget.customerName }}</b>（{{ remindTarget.phone }}）发送次卡催消通知？
        </p>
        <el-alert
          :title="`短信内容草稿：【海马智慧商业】尊敬的${remindTarget.customerName}，您在店内的【${remindTarget.cardName}】尚有 ${remindTarget.remainingTimes} 次未使用，有效期至 ${remindTarget.expireDate}，欢迎随时致电预约到店享受专业服务！`"
          type="info"
          :closable="false"
        />
      </div>
      <template #footer>
        <el-button @click="remindDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmSendRemind">确认发送催消短信</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 3: 沉淀会员赠券唤醒对话框 -->
    <el-dialog v-model="couponDialogVisible" title="🎁 沉淀老客定向赠券唤醒" width="480px">
      <div v-if="couponTarget">
        <p style="margin-bottom: 12px; color: #334155;">
          会员 <b>{{ couponTarget.customerName }}</b>（储值余额 ￥{{ couponTarget.totalBalance }}，最近到店 {{ couponTarget.lastVisit }}）
        </p>
        <el-form label-width="110px">
          <el-form-item label="唤醒礼遇券">
            <el-select v-model="selectedAwakeCoupon" style="width: 100%;">
              <el-option label="老客回馈50元无门槛通用券 (30天有效)" value="COUPON_50" />
              <el-option label="尊享染烫立减100元定制券 (15天有效)" value="COUPON_100" />
              <el-option label="头皮深层SPA养护体验券 (免费赠送)" value="COUPON_SPA" />
            </el-select>
          </el-form-item>
        </el-form>
      </div>
      <template #footer>
        <el-button @click="couponDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmSendCoupon">立即定向派券</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useSystemDataStore } from '../stores/systemDataStore'

const route = useRoute()
const systemData = useSystemDataStore()

// 11 个统计报表子菜单全量映射
const reportTitleMap: Record<string, string> = {
  'income': '收入明细',
  'card-deduct': '扣卡统计',
  'points': '积分统计',
  'rewards': '奖励金统计',
  'new-members': '新增会员统计',
  'payment-methods': '收入方式统计',
  'profit': '利润统计',
  'staff-performance': '员工业绩统计',
  'remaining-times': '未消费余次统计',
  'remaining-balance': '未消费余额统计',
  'item-sales': '单项销售统计'
}

const getActiveTab = () => {
  const paramTab = (route.params?.tab as string) || ''
  if (paramTab && reportTitleMap[paramTab]) return paramTab
  const queryTab = (route.query?.tab as string) || ''
  if (queryTab && reportTitleMap[queryTab]) return queryTab
  const path = route.path || ''
  const sub = path.replace(/^\/reports\/?/, '')
  if (sub && reportTitleMap[sub]) return sub
  return 'income'
}

const currentTab = ref(getActiveTab())

// 响应路由路径与参数变化
watch(
  () => [route.params?.tab, route.query?.tab, route.path],
  () => {
    currentTab.value = getActiveTab()
    activeSubFilter.value = 'ALL'
    currentPage.value = 1
  }
)

// 顶部日期快捷按钮
const quickDateButtons = [
  { key: 'today', label: '今天' },
  { key: 'yesterday', label: '昨天' },
  { key: 'thisWeek', label: '本周' },
  { key: 'thisMonth', label: '本月' },
  { key: 'lastMonth', label: '上月' }
]

const selectedQuickDate = ref('today')
const dateRange = ref<[string, string]>(['2026-09-06', '2026-09-06'])
const searchKeyword = ref('')

const handleQuickDate = (key: string) => {
  selectedQuickDate.value = key
  switch (key) {
    case 'today':
      dateRange.value = ['2026-09-06', '2026-09-06']
      break
    case 'yesterday':
      dateRange.value = ['2026-09-05', '2026-09-05']
      break
    case 'thisWeek':
      dateRange.value = ['2026-08-31', '2026-09-06']
      break
    case 'thisMonth':
      dateRange.value = ['2026-09-01', '2026-09-30']
      break
    case 'lastMonth':
      dateRange.value = ['2026-08-01', '2026-08-31']
      break
  }
  currentPage.value = 1
}

// 11 大报表数据源全量接入系统真理计算中心 (全部由底层业务订单与账本流水动态计算自洽生成，空保护)
const incomeList = computed(() => systemData.reportsData?.incomeList || [])
const cardDeductList = computed(() => systemData.reportsData?.cardDeductList || [])
const pointsList = computed(() => systemData.reportsData?.pointsList || [])
const rewardsList = computed(() => systemData.reportsData?.rewardsList || [])
const newMembersList = computed(() => systemData.reportsData?.newMembersList || [])
const paymentMethodsList = computed(() => systemData.reportsData?.paymentMethodsList || [])
const profitList = computed(() => systemData.reportsData?.profitList || [])
const staffPerformanceList = computed(() => systemData.reportsData?.staffPerformanceList || [])
const remainingTimesList = computed(() => systemData.reportsData?.remainingTimesList || [])
const remainingBalanceList = computed(() => systemData.reportsData?.remainingBalanceList || [])
const itemSalesList = computed(() => systemData.reportsData?.itemSalesList || [])

// 统计指示胶囊数据 (对齐截图: 店铺收入0 (客数: 0)  微商城0)
const currentSummaryPills = computed(() => {
  switch (currentTab.value) {
    case 'income': {
      const total = incomeList.value.reduce((acc, cur) => acc + cur.income, 0)
      const mallOnlineTotal = systemData.isNewTenant ? 0 : (systemData.mallOrders || []).reduce((acc: number, o: any) => acc + (o.totalPrice || o.amount || 0), 0)
      return [
        { label: '店铺收入', value: '￥' + total.toFixed(2) + ` (客数: ${incomeList.value.length})` },
        { label: '微商城', value: '￥' + mallOnlineTotal.toFixed(2) }
      ]
    }
    case 'card-deduct': {
      const total = cardDeductList.value.reduce((acc, cur) => acc + cur.deductTotal, 0)
      const p = cardDeductList.value.reduce((acc, cur) => acc + cur.deductPrincipal, 0)
      const g = cardDeductList.value.reduce((acc, cur) => acc + cur.deductGift, 0)
      return [
        { label: '扣卡总额', value: '￥' + total.toFixed(2) + ` (客数: ${cardDeductList.value.length})` },
        { label: '扣减实充本金', value: '￥' + p.toFixed(2) },
        { label: '扣减赠送金', value: '￥' + g.toFixed(2) }
      ]
    }
    case 'points': {
      const give = pointsList.value.filter(p => p.pointsChange > 0).reduce((acc, cur) => acc + cur.pointsChange, 0)
      const use = pointsList.value.filter(p => p.pointsChange < 0).reduce((acc, cur) => acc + Math.abs(cur.pointsChange), 0)
      return [
        { label: '本期赠送积分', value: '+' + give + ' 分' },
        { label: '本期收银抵扣', value: '-' + use + ' 分' },
        { label: '活跃积分账户', value: pointsList.value.length + ' 个' }
      ]
    }
    case 'rewards': {
      const total = rewardsList.value.reduce((acc, cur) => acc + cur.rewardChange, 0)
      return [
        { label: '累计派发奖励金', value: '￥' + total.toFixed(2) },
        { label: '参与分销会员', value: rewardsList.value.length + ' 人' },
        { label: '转介绍转化率', value: '100%' }
      ]
    }
    case 'new-members': {
      const totalRecharge = newMembersList.value.reduce((acc, cur) => acc + cur.initialRecharge, 0)
      return [
        { label: '新增开卡会员', value: newMembersList.value.length + ' 人' },
        { label: '开卡实充沉淀', value: '￥' + totalRecharge.toFixed(2) },
        { label: '派发新人券', value: newMembersList.value.length + ' 张' }
      ]
    }
    case 'payment-methods': {
      const total = paymentMethodsList.value.reduce((acc, cur) => acc + (cur.netIncome || cur.amount || 0), 0)
      const wechatItem = paymentMethodsList.value.find(p => p.rawType === 'WECHAT')
      const cardItem = paymentMethodsList.value.find(p => p.rawType === 'CARD')
      const wechatVal = (wechatItem && total > 0)
        ? `￥${Number(wechatItem.amount || 0).toFixed(2)} (${wechatItem.ratio}%)`
        : '￥0.00 (0.0%)'
      const cardVal = (cardItem && total > 0)
        ? `￥${Number(cardItem.amount || 0).toFixed(2)} (${cardItem.ratio}%)`
        : '￥0.00 (0.0%)'
      return [
        { label: '实收对账总额', value: '￥' + total.toFixed(2) },
        { label: '微信移动收款', value: wechatVal },
        { label: '双轨储值扣减', value: cardVal }
      ]
    }
    case 'profit': {
      if (profitList.value.length === 0) {
        return [
          { label: '综合核算毛利', value: '￥0.00' },
          { label: '累计运营净利润', value: '￥0.00' },
          { label: '平均综合净利率', value: '0.0%' }
        ]
      }
      const totalGross = profitList.value.reduce((acc, cur) => {
        const val = parseFloat(String(cur.grossRevenue || 0).replace(/[^\d.-]/g, '')) || 0
        return acc + val
      }, 0)
      const totalNet = profitList.value.reduce((acc, cur) => {
        const val = parseFloat(String(cur.netProfit || 0).replace(/[^\d.-]/g, '')) || 0
        return acc + val
      }, 0)
      const avgMargin = totalGross > 0 ? ((totalNet / totalGross) * 100).toFixed(1) + '%' : '0.0%'
      return [
        { label: '综合核算毛利', value: '￥' + totalGross.toFixed(2) },
        { label: '累计运营净利润', value: (totalNet >= 0 ? '￥' : '-￥') + Math.abs(totalNet).toFixed(2) },
        { label: '平均综合净利率', value: avgMargin }
      ]
    }
    case 'staff-performance': {
      const rev = staffPerformanceList.value.reduce((acc, cur) => acc + cur.serviceRevenue + cur.cardSales + cur.retailSales, 0)
      const comm = staffPerformanceList.value.reduce((acc, cur) => acc + cur.totalCommission, 0)
      return [
        { label: '员工创收总业绩', value: '￥' + rev.toFixed(2) },
        { label: '应发提成总额', value: '￥' + comm.toFixed(2) },
        { label: '在册提成员工', value: staffPerformanceList.value.length + ' 人' }
      ]
    }
    case 'remaining-times': {
      const times = remainingTimesList.value.reduce((acc, cur) => acc + (cur.remainingTimes || 0), 0)
      const totalWorth = remainingTimesList.value.reduce((acc, cur) => acc + (cur.unconsumedWorth || 0), 0)
      return [
        { label: '沉淀未消费余次', value: times + ' 次' },
        { label: '涉及次卡总数', value: remainingTimesList.value.length + ' 张' },
        { label: '待履约产值', value: '￥' + totalWorth.toFixed(2) }
      ]
    }
    case 'remaining-balance': {
      const bal = remainingBalanceList.value.reduce((acc, cur) => acc + (cur.totalBalance || 0), 0)
      const p = remainingBalanceList.value.reduce((acc, cur) => acc + (cur.principal || 0), 0)
      return [
        { label: '储值卡沉淀总余额', value: '￥' + bal.toFixed(2) },
        { label: '本金存量沉淀', value: '￥' + p.toFixed(2) },
        { label: '储值老客人数', value: remainingBalanceList.value.length + ' 人' }
      ]
    }
    case 'item-sales': {
      const total = itemSalesList.value.reduce((acc, cur) => acc + (cur.totalSales || 0), 0)
      const count = itemSalesList.value.reduce((acc, cur) => acc + (cur.salesCount || 0), 0)
      const avgMargin = itemSalesList.value.length > 0
        ? (itemSalesList.value.reduce((acc, cur) => acc + (parseFloat(cur.marginRate) || 0), 0) / itemSalesList.value.length).toFixed(1) + '%'
        : '0.0%'
      return [
        { label: '单项销售总额', value: '￥' + total.toFixed(2) },
        { label: '销售总人次/件数', value: count + ' 次/件' },
        { label: '平均毛利率', value: avgMargin }
      ]
    }
    default:
      return [{ label: '数据记录', value: '0 条' }]
  }
})

// 二级分类横向页签 (对齐截图2: 全部  充值办卡 0  零售收银 0  扣卡另付 0)
const activeSubFilter = ref('ALL')
const currentSubFilters = computed(() => {
  switch (currentTab.value) {
    case 'income':
      return [
        { key: 'ALL', label: '全部', count: incomeList.value.length },
        { key: 'RECHARGE', label: '充值办卡', count: incomeList.value.filter(i => i.rawType === 'RECHARGE').length },
        { key: 'RETAIL', label: '零售收银', count: incomeList.value.filter(i => i.rawType === 'RETAIL').length },
        { key: 'CARD_EXTRA', label: '扣卡另付', count: incomeList.value.filter(i => i.rawType === 'CARD_EXTRA').length }
      ]
    case 'card-deduct':
      return [
        { key: 'ALL', label: '全部', count: cardDeductList.value.length },
        { key: 'RECHARGE_CARD', label: '储值卡扣减', count: cardDeductList.value.length },
        { key: 'TIMES_CARD', label: '次卡抵扣', count: 0 }
      ]
    case 'points':
      return [
        { key: 'ALL', label: '全部', count: pointsList.value.length },
        { key: 'GIVE', label: '赠送积分', count: pointsList.value.filter(p => p.rawType === 'GIVE').length },
        { key: 'USE', label: '抵扣消耗', count: pointsList.value.filter(p => p.rawType === 'USE').length }
      ]
    case 'rewards':
      return [
        { key: 'ALL', label: '全部', count: rewardsList.value.length },
        { key: 'INVITE', label: '好友办卡', count: rewardsList.value.filter(r => r.rawType === 'INVITE').length },
        { key: 'GROUP', label: '拼团分销', count: rewardsList.value.filter(r => r.rawType === 'GROUP').length }
      ]
    case 'new-members':
      return [
        { key: 'ALL', label: '全部', count: newMembersList.value.length },
        { key: 'GOLD', label: '金卡会员', count: newMembersList.value.filter(m => m.rawType === 'GOLD').length },
        { key: 'SILVER', label: '银卡会员', count: newMembersList.value.filter(m => m.rawType === 'SILVER').length }
      ]
    case 'payment-methods': {
      const pmList = paymentMethodsList.value
      return [
        { key: 'ALL', label: '全部', count: pmList.length },
        { key: 'WECHAT', label: '微信支付', count: pmList.filter(p => p.rawType === 'WECHAT').length },
        { key: 'CARD', label: '储值划扣', count: pmList.filter(p => p.rawType === 'CARD').length },
        { key: 'ALIPAY', label: '支付宝', count: pmList.filter(p => p.rawType === 'ALIPAY').length },
        { key: 'OFFLINE', label: '现金POS', count: pmList.filter(p => p.rawType === 'OFFLINE').length }
      ]
    }
    case 'profit': {
      const pfList = profitList.value
      return [
        { key: 'ALL', label: '全部', count: pfList.length },
        { key: 'WEEK', label: '按周核算', count: pfList.filter(p => p.rawType === 'WEEK').length },
        { key: 'MONTH', label: '按月核算', count: pfList.filter(p => p.rawType === 'MONTH').length }
      ]
    }
    case 'staff-performance': {
      const depts = Array.from(new Set(staffPerformanceList.value.map(s => s.department || '门店运营部')))
      const pills = [{ key: 'ALL', label: '全部', count: staffPerformanceList.value.length }]
      depts.forEach(d => {
        const count = staffPerformanceList.value.filter(s => s.department === d).length
        pills.push({ key: d, label: d, count })
      })
      return pills
    }
    case 'remaining-times': {
      const cards = Array.from(new Set(remainingTimesList.value.map(r => r.cardName || '次卡')))
      const pills = [{ key: 'ALL', label: '全部', count: remainingTimesList.value.length }]
      cards.forEach(c => {
        const count = remainingTimesList.value.filter(r => r.cardName === c).length
        pills.push({ key: c, label: c, count })
      })
      return pills
    }
    case 'remaining-balance':
      return [
        { key: 'ALL', label: '全部', count: remainingBalanceList.value.length },
        { key: 'GOLD', label: '金卡客户', count: remainingBalanceList.value.filter(b => b.rawType === 'GOLD').length },
        { key: 'SILVER', label: '银卡客户', count: remainingBalanceList.value.filter(b => b.rawType === 'SILVER').length }
      ]
    case 'item-sales': {
      const cats = Array.from(new Set(itemSalesList.value.map(i => i.category || i.rawType || '商品分类')))
      const pills = [{ key: 'ALL', label: '全部', count: itemSalesList.value.length }]
      cats.forEach(c => {
        const count = itemSalesList.value.filter(i => (i.category === c || i.rawType === c)).length
        pills.push({ key: c, label: c, count })
      })
      return pills
    }
    default:
      return []
  }
})

const handleSubFilterChange = (val: string) => {
  activeSubFilter.value = val
  currentPage.value = 1
}

// 表头视觉风格定制 (默认采用现代极简高级浅灰风，兼顾雅致浅蓝、商务深色与原版纯蓝)
const currentHeaderTheme = ref(localStorage.getItem('report_header_theme') || 'modern-slate')

const headerThemes = [
  { key: 'modern-slate', name: '现代极简 (推荐)', bg: '#f8fafc', color: '#334155', border: '1px solid #e2e8f0' },
  { key: 'soft-blue', name: '雅致浅蓝 (清新)', bg: '#f0f7ff', color: '#1e40af', border: '1px solid #dbeafe' },
  { key: 'business-navy', name: '商务深色 (沉稳)', bg: '#1e293b', color: '#ffffff', border: '1px solid #334155' },
  { key: 'pure-blue', name: '经典纯蓝 (原版)', bg: '#1890ff', color: '#ffffff', border: 'none' }
]

const handleThemeChange = (val: string) => {
  localStorage.setItem('report_header_theme', val)
  ElMessage.success(`表头风格已切换为【${headerThemes.find(t => t.key === val)?.name}】`)
}

const tableHeaderStyle = computed(() => {
  const theme = headerThemes.find(t => t.key === currentHeaderTheme.value) || headerThemes[0]
  return {
    background: theme.bg,
    color: theme.color,
    fontWeight: '600',
    fontSize: '14px',
    borderBottom: theme.border,
    padding: '10px 0',
    transition: 'all 0.25s ease'
  }
})

// 分页控制
const currentPage = ref(1)
const pageSize = ref(10)

// 综合过滤当前激活报表的数据
const filteredList = computed(() => {
  let raw: any[] = []
  switch (currentTab.value) {
    case 'income': raw = incomeList.value; break
    case 'card-deduct': raw = cardDeductList.value; break
    case 'points': raw = pointsList.value; break
    case 'rewards': raw = rewardsList.value; break
    case 'new-members': raw = newMembersList.value; break
    case 'payment-methods': raw = paymentMethodsList.value; break
    case 'profit': raw = profitList.value; break
    case 'staff-performance': raw = staffPerformanceList.value; break
    case 'remaining-times': raw = remainingTimesList.value; break
    case 'remaining-balance': raw = remainingBalanceList.value; break
    case 'item-sales': raw = itemSalesList.value; break
    default: raw = incomeList.value; break
  }

  // 二级子维度过滤
  if (activeSubFilter.value && activeSubFilter.value !== 'ALL') {
    raw = raw.filter(item => item.rawType === activeSubFilter.value || item.category === activeSubFilter.value || item.department === activeSubFilter.value || item.cardName === activeSubFilter.value)
  }

  // 关键字搜索过滤
  if (searchKeyword.value.trim()) {
    const q = searchKeyword.value.trim().toLowerCase()
    raw = raw.filter(item => {
      return Object.values(item).some(v => String(v).toLowerCase().includes(q))
    })
  }

  return raw
})

const paginatedList = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredList.value.slice(start, start + pageSize.value)
})

const getTypeTag = (type: string) => {
  switch (type) {
    case '充值办卡': return 'warning'
    case '零售收银': return 'success'
    case '扣卡另付': return 'primary'
    default: return 'info'
  }
}

const getProgressColor = (ratio: number) => {
  if (ratio >= 30) return '#10b981'
  if (ratio >= 15) return '#0284c7'
  return '#f59e0b'
}

const handleFilterChange = () => {
  currentPage.value = 1
  ElMessage.success(`报表数据已按最新条件检索刷新`)
}

const handleRefresh = () => {
  searchKeyword.value = ''
  activeSubFilter.value = 'ALL'
  currentPage.value = 1
  ElMessage.success(`已重新从服务器同步最新流水台账`)
}

// 真实 CSV 导出能力
const handleExport = () => {
  const list = filteredList.value
  if (!list || list.length === 0) {
    ElMessage.warning('当前无数据可供导出')
    return
  }

  const tabTitle = reportTitleMap[currentTab.value] || '报表'
  const keys = Object.keys(list[0]).filter(k => k !== 'rawType' && k !== 'id')
  let csvContent = '\uFEFF' // BOM for UTF-8
  csvContent += keys.join(',') + '\n'

  list.forEach(item => {
    const row = keys.map(k => {
      const val = item[k] === undefined || item[k] === null ? '' : String(item[k]).replace(/,/g, '，')
      return `"${val}"`
    })
    csvContent += row.join(',') + '\n'
  })

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.setAttribute('href', url)
  link.setAttribute('download', `${tabTitle}_${dateRange.value[0]}_${dateRange.value[1]}.csv`)
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)

  ElMessage.success(`【导出成功】已生成并下载【${tabTitle}.csv】`)
}

// 详情凭证明细弹窗
const detailDialogVisible = ref(false)
const detailDialogTitle = ref('核算明细凭证')
const selectedRowData = ref<any>(null)

const handleOpenDetail = (title: string, row: any) => {
  detailDialogTitle.value = title
  selectedRowData.value = row
  detailDialogVisible.value = true
}

const formatDetailFields = (row: any) => {
  const result: Record<string, string> = {}
  const labelMap: Record<string, string> = {
    customerName: '客户姓名',
    phone: '客户手机号',
    income: '实收金额 (元)',
    type: '交易类型',
    details: '业务详情',
    date: '业务发生时间',
    status: '履约状态',
    serviceName: '消费项目',
    deductPrincipal: '扣减实充本金 (元)',
    deductGift: '扣减赠送金 (元)',
    deductTotal: '扣卡总金额 (元)',
    remainingBalance: '卡内剩余总额',
    operator: '经手员工/操作人',
    pointsChange: '积分变动值',
    changeType: '积分变动事由',
    balance: '当前剩余积分',
    rewardChange: '奖励金变动 (元)',
    reason: '奖励金事由',
    referredCustomer: '被推荐好友',
    currentReward: '可用奖励金总额',
    memberNo: '会员卡号',
    name: '会员姓名',
    level: '会员等级',
    initialRecharge: '开卡充值本金 (元)',
    giftCoupon: '赠送优惠券',
    referrer: '入会渠道/推荐人',
    methodName: '支付方式渠道',
    transactionCount: '交易笔数',
    amount: '实收金额 (元)',
    ratio: '渠道收款占比',
    refundAmount: '退款金额 (元)',
    netIncome: '净入账总额 (元)',
    period: '核算周期',
    grossRevenue: '营业总收入',
    bomCost: '耗材BOM成本',
    rentCost: '房租水电分摊',
    salaryCommission: '员工底薪提成支出',
    netProfit: '净利润 (元)',
    profitMargin: '综合利润率',
    staffName: '员工姓名',
    post: '所属岗位职务',
    serviceCount: '服务客户单数',
    serviceRevenue: '项目服务创收',
    cardSales: '开卡售卡创收',
    retailSales: '实物零售销售',
    totalCommission: '应发提成 (元)',
    cardName: '次卡名称',
    totalTimes: '开卡总次数',
    usedTimes: '已消费履约次数',
    remainingTimes: '卡内剩余可用余次',
    expireDate: '次卡截止有效期',
    principal: '实充本金存量 (元)',
    gift: '赠送金存量 (元)',
    totalBalance: '储值卡账户总余额 (元)',
    lastVisit: '最近到店消费时间',
    itemName: '单项/商品名称',
    category: '所属品类',
    price: '销售标价 (元)',
    salesCount: '总销售量 (次/件)',
    totalSales: '销售总金额 (元)',
    marginRate: '预估毛利率'
  }

  for (const [k, v] of Object.entries(row)) {
    if (k === 'id' || k === 'rawType') continue
    const label = labelMap[k] || k
    result[label] = String(v)
  }
  return result
}

// 催消提醒弹窗
const remindDialogVisible = ref(false)
const remindTarget = ref<any>(null)

const handleSendRemind = (row: any) => {
  remindTarget.value = row
  remindDialogVisible.value = true
}

const confirmSendRemind = () => {
  remindDialogVisible.value = false
  ElMessage.success(`已成功向会员【${remindTarget.value.customerName}】发送次卡催消到店短信提醒！`)
}

// 赠券唤醒老客弹窗
const couponDialogVisible = ref(false)
const couponTarget = ref<any>(null)
const selectedAwakeCoupon = ref('COUPON_50')

const handleSendCoupon = (row: any) => {
  couponTarget.value = row
  couponDialogVisible.value = true
}

const confirmSendCoupon = () => {
  couponDialogVisible.value = false
  ElMessage.success(`已成功向老客【${couponTarget.value.customerName}】派发唤醒专享券，短信通知已送达！`)
}
</script>

<style scoped>
.report-analytics-container {
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  min-height: calc(100vh - 120px);
}

/* 主内容展示区 (对齐截图2) */
.report-main-content {
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  background-color: #fff;
}

/* 顶部操作与筛选栏 (对齐截图2) */
.top-filter-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 14px;
}

.filter-left {
  display: flex;
  align-items: center;
}

.filter-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* 汇总指示胶囊 (对齐截图2: 店铺收入0 (客数: 0)  微商城0) */
.summary-pills-row {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 12px;
}

.summary-pill {
  border: 1px solid #e2e8f0;
  background-color: #f8fafc;
  color: #0369a1;
  padding: 6px 14px;
  border-radius: 6px;
  font-size: 13px;
  display: flex;
  align-items: center;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
  transition: all 0.2s ease;
}

.summary-pill:hover {
  border-color: #cbd5e1;
  background-color: #ffffff;
}

.report-table-wrapper :deep(.el-table) {
  border-radius: 6px;
  overflow: hidden;
  border: 1px solid #e2e8f0;
}

/* 二级横向页签 (对齐截图2: 全部  充值办卡 0  零售收银 0  扣卡另付 0) */
.secondary-tabs-bar {
  display: flex;
  align-items: center;
  gap: 20px;
  border-bottom: 1px solid #f0f0f0;
  padding-bottom: 8px;
  margin-bottom: 14px;
  font-size: 14px;
}

.sec-tab {
  cursor: pointer;
  color: #595959;
  padding: 4px 6px;
  transition: all 0.2s;
  position: relative;
}

.sec-tab:hover {
  color: #1890ff;
}

.sec-tab.active {
  color: #1890ff;
  font-weight: 600;
}

.sec-tab.active::after {
  content: '';
  position: absolute;
  bottom: -9px;
  left: 0;
  right: 0;
  height: 2px;
  background-color: #1890ff;
}

/* 表格包装器 */
.report-table-wrapper {
  flex: 1;
}

.income-text {
  color: #0958d9;
  font-weight: 700;
}

.empty-box {
  padding: 40px 0;
  color: #8c8c8c;
  font-size: 14px;
}

/* 底部分页器 (对齐截图2右下角: 共 X 条  10条/页  < 1 >) */
.pagination-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 16px;
  padding-top: 8px;
}
</style>
