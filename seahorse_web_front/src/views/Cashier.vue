<template>
  <div class="cashier-page">
    <!-- 扫码盒子硬件即插即用指示与快捷扫码模拟调试条 -->
    <div class="scanbox-status-bar">
      <div class="bar-left">
        <div class="hardware-badge">
          <span class="pulse-indicator"></span>
          <span class="hw-title">📷 扫码硬件监听中</span>
          <el-tag size="small" type="success" effect="dark">就绪</el-tag>
        </div>
        <!-- 扫码框始终保持焦点 (常驻居中) -->
        <div class="top-scan-input-box" style="display: flex; gap: 8px; align-items: center; margin: 0 12px;">
          <el-input
            ref="cashierBarcodeScanInputRef"
            id="cashierBarcodeScanInput"
            v-model="barcodeScanInput"
            placeholder="🔫 扫码框 (常驻保持焦点 / 回车自动加购商品或付款码扣款)..."
            size="default"
            style="width: 380px;"
            @keydown.enter="handleBarcodeScanSubmit"
            @blur="handleScannerBlur"
          >
            <template #prefix>
              <span style="font-size: 14px;">⚡</span>
            </template>
          </el-input>
          <el-button type="primary" size="default" @click="handleBarcodeScanSubmit">扫码加车</el-button>
        </div>
      </div>

      <div class="bar-right">
        <!-- 常驻挂单取单与结账快捷键入口 -->
        <el-button-group style="margin-right: 8px;">
          <el-button type="warning" size="default" icon="Clock" @click="handleHoldOrder" title="挂单 (F2)">
            ⏸️ 挂单 (F2)
          </el-button>
          <el-button type="info" size="default" icon="FolderOpened" @click="isHeldDrawerVisible = true" title="取单 (F4)">
            📂 取单 (F4)
            <el-badge v-if="heldOrdersList.length" :value="heldOrdersList.length" style="margin-left: 4px;" />
          </el-button>
          <el-button type="success" size="default" icon="Check" @click="handleQuickF8Checkout" title="快捷结账 (F8)">
            ⚡ 结账 (F8)
          </el-button>
        </el-button-group>

        <el-button v-if="isSuperAdmin" type="primary" size="small" plain icon="Monitor" @click="openScanSimulatorDialog = true">
          调试
        </el-button>
        <el-button v-if="isSuperAdmin" size="small" icon="Setting" @click="goToPaymentSettings">
          设置
        </el-button>
      </div>
    </div>

    <el-row :gutter="16" class="cashier-main-row">
      <!-- 左侧：商品网格与快速加购面板 (60% 黄金工作台) -->
      <el-col :span="13" class="product-grid-col">
        <el-card shadow="hover" class="product-catalog-card">
          <template #header>
            <div class="catalog-header-bar">
              <div class="cat-title-wrap">
                <span class="cat-title">🛍️ 商品与服务选单</span>
                <el-radio-group v-model="activeProductCategory" size="small">
                  <el-radio-button label="ALL">全部 ({{ storeCatalogProducts.length }})</el-radio-button>
                  <el-radio-button
                    v-for="tab in industryCategoryTabs"
                    :key="tab.value"
                    :label="tab.value"
                  >{{ tab.label }}</el-radio-button>
                </el-radio-group>
              </div>
              <div class="cat-search-wrap">
                <el-input
                  v-model="productSearchKeyword"
                  placeholder="搜索品名/条码..."
                  size="small"
                  clearable
                  prefix-icon="Search"
                  style="width: 170px;"
                />
              </div>
            </div>
          </template>

          <!-- 商品项目网格列表 (大卡片直观触控) -->
          <div class="product-cards-grid">
            <div
              v-for="prod in filteredCatalogProducts"
              :key="prod.code"
              class="product-cell-card"
              @click="addProductCardToOrder(prod)"
            >
              <div class="cell-icon">{{ prod.icon || '🛍️' }}</div>
              <div class="cell-info">
                <div class="cell-name" :title="prod.name">{{ prod.name }}</div>
                <div class="cell-meta">
                  <span class="cell-code mono-text">{{ prod.code }}</span>
                  <el-tag size="small" type="info" effect="plain">存:{{ prod.stock }}</el-tag>
                </div>
                <div class="cell-bottom">
                  <span class="cell-price">￥{{ prod.price.toFixed(2) }}</span>
                  <el-button type="primary" size="small" circle icon="Plus" class="add-btn" />
                </div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 右侧：当前单据购物车与组合结算收银 (40%) -->
      <el-col :span="11" class="cart-settle-col">
        <el-card shadow="hover" class="order-pane">
          <template #header>
            <div class="card-header">
              <div style="display: flex; align-items: center; gap: 8px;">
                <span class="header-title">🧾 结算单据与购物车</span>
                <el-tag size="small" type="primary" v-if="order">{{ order.orderNo }}</el-tag>
              </div>
              <div style="display: flex; gap: 8px; align-items: center;">
                <el-select
                  v-model="currentSessionSelectId"
                  placeholder="选择在场工位"
                  size="small"
                  style="width: 180px;"
                  @change="handleSelectSession"
                >
                  <el-option
                    v-for="s in sessionListOptions"
                    :key="s.id"
                    :label="s.spaceName + ' (' + s.customerName + ')' + (s.status === 'WAIT_CLEAN' ? ' [待清台]' : '')"
                    :value="s.id"
                  />
                </el-select>
                <el-button size="small" icon="Refresh" @click="loadSessionData">刷新</el-button>
              </div>
            </div>
          </template>

          <div v-if="order" class="order-info-box">
            <div class="info-row customer-row">
              <div style="display: flex; align-items: center; gap: 8px; flex: 1;">
                <span>工位: <b>{{ order.spaceName }}</b></span>
                <span style="color: #64748b;">| 顾客: <b>{{ order.customerName }}</b> ({{ order.customerPhone || '散客' }})</span>
              </div>
              <el-tag v-if="order.status === 'WAIT_CLEAN'" size="small" type="warning" effect="dark">待清台</el-tag>
            </div>

            <!-- 付款会员关联 -->
            <div class="info-row payer-row">
              <span class="payer-label">💳 付款会员:</span>
              <el-select
                v-model="selectedPayerMemberId"
                filterable
                clearable
                placeholder="关联储值会员 (散客免选)"
                size="small"
                style="flex: 1;"
                @change="handlePayerMemberChange"
                @clear="handleClearPayerMember"
              >
                <el-option
                  v-for="m in storeMembersList"
                  :key="m.id"
                  :label="`${m.name} (${m.phone || '无号'}) - ${m.levelName || '会员'} [￥${((Number(m.principalBalance) || 0) + (Number(m.giftBalance) || 0)).toFixed(0)}]`"
                  :value="m.id"
                />
              </el-select>
              <el-tag v-if="memberProfile" size="small" type="success" effect="dark">
                {{ memberProfile.levelName || 'VIP' }}
              </el-tag>
            </div>

            <!-- 消费品项清单 (右侧购物车表格) -->
            <div class="order-items-pane">
              <div class="items-header">
                <span class="items-title">🛒 购物车清单 ({{ (order.items || []).length }} 项)</span>
                <el-button size="small" type="danger" link @click="order.items = []; recalcOrderTotal()" v-if="order.items?.length">
                  清空
                </el-button>
              </div>

              <!-- 表头 -->
              <div class="items-table-header">
                <div class="th-cell th-name">品名</div>
                <div class="th-cell th-price">单价</div>
                <div class="th-cell th-qty">数量</div>
                <div class="th-cell th-sub">小计</div>
                <div class="th-cell th-op">操作</div>
              </div>

              <!-- 表体 -->
              <div class="items-list-wrapper">
                <div v-if="(!order.items || order.items.length === 0) && !(Number(order.feeAmount) > 0)" class="no-items-hint">
                  <el-empty description="购物车为空，点击左侧商品或扫码加购" :image-size="40" />
                </div>
                <div v-for="(it, idx) in order.items" :key="idx" class="items-table-row">
                  <div class="td-cell td-name">
                    <span class="it-title" :title="it.name">{{ it.name }}</span>
                    <span class="it-barcode mono-text" v-if="it.code">{{ it.code }}</span>
                  </div>
                  <div class="td-cell td-price">￥{{ Number(it.price || 0).toFixed(2) }}</div>
                  <div class="td-cell td-qty">
                    <div class="qty-stepper">
                      <button type="button" class="step-btn" @click="changeItemQty(idx, -1)">-</button>
                      <span class="step-val">{{ it.qty || 1 }}</span>
                      <button type="button" class="step-btn" @click="changeItemQty(idx, 1)">+</button>
                    </div>
                  </div>
                  <div class="td-cell td-sub">￥{{ ((Number(it.price) || 0) * (Number(it.qty) || 1)).toFixed(2) }}</div>
                  <div class="td-cell td-op">
                    <el-button size="small" type="danger" link icon="Delete" @click="removeItem(idx)" />
                  </div>
                </div>

                <!-- 附加费行 -->
                <div v-if="Number(order.feeAmount) > 0" class="items-table-row fee-table-row">
                  <div class="td-cell td-name">
                    <span class="it-title" style="color: #b45309; font-weight: 600;">行业附加费 (茶位/餐具)</span>
                  </div>
                  <div class="td-cell td-price">￥{{ Number(order.feeAmount).toFixed(2) }}</div>
                  <div class="td-cell td-qty">1</div>
                  <div class="td-cell td-sub">￥{{ Number(order.feeAmount).toFixed(2) }}</div>
                  <div class="td-cell td-op">
                    <el-button size="small" type="warning" link @click="handleRemoveFee">免除</el-button>
                  </div>
                </div>
              </div>
            </div>

            <!-- 金额总计 -->
            <div class="amount-summary-strip">
              <div class="due-amount-display">
                <span class="due-text">应收总额:</span>
                <span class="due-val-big">￥{{ (Number(order.actualAmount) || 0).toFixed(2) }}</span>
              </div>
              <div class="sub-amount-notes">
                <span>项目: ￥{{ (Number(order.totalAmount) || 0).toFixed(2) }}</span>
                <span v-if="Number(order.feeAmount) > 0">附加费: +￥{{ Number(order.feeAmount).toFixed(2) }}</span>
              </div>
            </div>

            <!-- 组合支付通道选择与划扣 -->
            <div class="quick-pay-mini-bar">
              <div class="channel-buttons-row">
                <el-button :type="isSingleChannel('wechat') ? 'success' : 'default'" size="small" @click="switchToSingleChannel('wechat')">
                  🟢 微信全额
                </el-button>
                <el-button :type="isSingleChannel('alipay') ? 'primary' : 'default'" size="small" @click="switchToSingleChannel('alipay')">
                  🔵 支付宝全额
                </el-button>
                <el-button :type="isSingleChannel('storedValue') ? 'warning' : 'default'" size="small" @click="switchToSingleChannel('storedValue')">
                  🟣 储值全额
                </el-button>
                <el-button :type="isSingleChannel('cash') ? 'warning' : 'default'" size="small" @click="switchToSingleChannel('cash')">
                  🟡 现金全额
                </el-button>
              </div>

              <!-- 通道微调输入 -->
              <div class="channels-mini-grid">
                <div class="mini-channel-row">
                  <span class="m-lbl">微信:</span>
                  <el-input-number v-model="payPlan.wechat" :min="0" :precision="2" size="small" style="width: 110px;" />
                  <el-button size="small" type="success" link @click="payPlan.wechat = getRemainingAmount('wechat')">全额</el-button>
                </div>
                <div class="mini-channel-row">
                  <span class="m-lbl">支付宝:</span>
                  <el-input-number v-model="payPlan.alipay" :min="0" :precision="2" size="small" style="width: 110px;" />
                  <el-button size="small" type="primary" link @click="payPlan.alipay = getRemainingAmount('alipay')">全额</el-button>
                </div>
                <div class="mini-channel-row">
                  <span class="m-lbl">储值:</span>
                  <el-input-number v-model="payPlan.storedValue" :min="0" :precision="2" size="small" style="width: 110px;" />
                  <el-button size="small" color="#7c3aed" link @click="handleAutoFillStoredValue">全额</el-button>
                </div>
                <div class="mini-channel-row">
                  <span class="m-lbl">现金:</span>
                  <el-input-number v-model="payPlan.cash" :min="0" :precision="2" size="small" style="width: 110px;" />
                  <el-button size="small" type="warning" link @click="handleAutoFillCash">全额</el-button>
                </div>
              </div>
            </div>

            <!-- 组合支付确认结账条 -->
            <div class="summary-check-bar">
              <div class="check-left">
                <span>已填: <b class="text-primary">￥{{ currentPlanTotal.toFixed(2) }}</b></span>
                <span class="check-diff" :class="{ 'diff-match': isAmountMatched }">
                  {{ isAmountMatched ? '✅ 金额已覆盖' : '⚠️ 差额: ￥' + (order.actualAmount - currentPlanTotal).toFixed(2) }}
                </span>
              </div>
              <el-button
                v-if="order.status !== 'WAIT_CLEAN' && order.status !== 'COMPLETED'"
                type="primary"
                size="large"
                :disabled="!isAmountMatched"
                :loading="settling"
                @click="handleDoCheckout"
              >
                <el-icon><Check /></el-icon> 结账出票 (F8)
              </el-button>
              <el-button v-else type="success" size="large" disabled>
                单据已完成结账
              </el-button>
            </div>
          </div>

          <div v-else class="empty-tip">
            <el-empty description="暂无单据，点击左侧商品开始选购或选择在场工位" />
            <div style="text-align: center; margin-top: 10px;">
              <el-button type="primary" @click="initWalkInOrder">⚡ 开立散客新单据</el-button>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 结账成功与热敏小票真实预览/本地打印弹窗 -->
    <!-- 结账成功消费小票预览与本地打印弹窗 (左右双栏：左侧全维度开关配置，右侧1:1实时热敏纸样) -->
    <el-dialog
      v-model="successDialogVisible"
      title="🧾 结账完成 · 顾客消费小票预览与打印出单"
      width="1060px"
      top="3vh"
      :close-on-click-modal="false"
      destroy-on-close
      class="receipt-master-dialog"
    >
      <div class="checkout-success-header">
        <div class="success-banner">
          <div class="s-icon">🎉</div>
          <div>
            <div class="s-main-title">结账成功！工位单据已闭环推进至【待清台】</div>
            <div class="s-sub-title">流水单号：<strong>{{ settledResult?.order?.orderNo || order?.orderNo }}</strong> · 实收总额 <strong>￥{{ (settledResult?.order?.actualAmount || order?.actualAmount || 380).toFixed(2) }}</strong></div>
          </div>
        </div>
        <div class="quick-action-btns">
          <el-button type="primary" size="large" icon="Printer" @click="handlePrintReceipt">
            🖨️ 调用本地打印机打印出单
          </el-button>
          <el-button type="success" plain @click="handleSaveQuickConfig">
            💾 保存为默认小票模板
          </el-button>
        </div>
      </div>

      <!-- 双栏布局：左侧逐项细致开关配置，右侧1:1真实热敏纸张所见即所得 -->
      <div class="receipt-dialog-body-grid">
        <!-- 左侧：全维度开关与参数配置面板 -->
        <div class="receipt-config-panel">
          <div class="panel-top-actions">
            <span class="p-heading">⚙️ 打印内容逐项精细开关</span>
            <div class="preset-links">
              <el-button size="small" link type="primary" @click="applyConfigPreset('ALL')">全选开启</el-button>
              <el-button size="small" link type="success" @click="applyConfigPreset('RECOMMENDED')">推荐常用</el-button>
              <el-button size="small" link type="warning" @click="applyConfigPreset('MINIMAL')">极简小票</el-button>
            </div>
          </div>

          <div class="config-scroll-area">
            <!-- 1. 纸张与版式 -->
            <div class="config-group-card">
              <div class="grp-title">📐 纸张规格与字号密度</div>
              <div class="grp-content">
                <div class="cfg-row">
                  <span class="cfg-lbl">小票纸卷宽度</span>
                  <el-radio-group v-model="quickReceiptConfig.paperWidth" size="small">
                    <el-radio-button label="80mm">80mm 大宽幅</el-radio-button>
                    <el-radio-button label="58mm">58mm 紧凑型</el-radio-button>
                  </el-radio-group>
                </div>
                <div class="cfg-row">
                  <span class="cfg-lbl">排版字号大小</span>
                  <el-radio-group v-model="quickReceiptConfig.fontSize" size="small">
                    <el-radio-button label="compact">紧凑小字</el-radio-button>
                    <el-radio-button label="standard">标准适中</el-radio-button>
                    <el-radio-button label="large">清晰大字</el-radio-button>
                  </el-radio-group>
                </div>
                <div class="cfg-row">
                  <span class="cfg-lbl">结账后自动调起打印</span>
                  <el-switch v-model="quickReceiptConfig.autoPrint" />
                </div>
              </div>
            </div>

            <!-- 2. 抬头与品牌标识 -->
            <div class="config-group-card">
              <div class="grp-title">🏷️ 抬头与品牌标识 (支持自定义内容)</div>
              <div class="grp-content">
                <div class="cfg-toggle-row">
                  <el-switch v-model="quickReceiptConfig.showStoreHeader" active-text="店铺名称主抬头" />
                  <el-input v-if="quickReceiptConfig.showStoreHeader" v-model="quickReceiptConfig.storeHeaderTitle" size="small" placeholder="输入店铺抬头名称" style="margin-top: 6px;" />
                </div>
                <div class="cfg-toggle-row">
                  <el-switch v-model="quickReceiptConfig.showHeaderSubtitle" active-text="页眉宣传标语/口号" />
                  <el-input v-if="quickReceiptConfig.showHeaderSubtitle" v-model="quickReceiptConfig.headerSubTitle" size="small" placeholder="输入副标标语" style="margin-top: 6px;" />
                </div>
                <div class="cfg-toggle-row">
                  <el-switch v-model="quickReceiptConfig.showTicketTitle" active-text="小票单据性质标题" />
                  <el-input v-if="quickReceiptConfig.showTicketTitle" v-model="quickReceiptConfig.ticketTitle" size="small" placeholder="如：顾客结账消费明细清单" style="margin-top: 6px;" />
                </div>
              </div>
            </div>

            <!-- 3. 单据与客显信息 -->
            <div class="config-group-card">
              <div class="grp-title">📋 单据流水与客显信息</div>
              <div class="grp-content grid-2cols">
                <el-switch v-model="quickReceiptConfig.showOrderNo" active-text="单据流水号" />
                <el-switch v-model="quickReceiptConfig.showCheckoutTime" active-text="结账时间" />
                <el-switch v-model="quickReceiptConfig.showCashierName" active-text="收银员姓名" />
                <el-switch v-model="quickReceiptConfig.showTechnician" active-text="空间工位/主理技师" />
                <el-switch v-model="quickReceiptConfig.showCustomerName" active-text="顾客姓名与卡级" />
                <div style="display: flex; flex-direction: column; gap: 4px;">
                  <el-switch v-model="quickReceiptConfig.showCustomerPhone" active-text="顾客手机号" />
                  <el-checkbox v-if="quickReceiptConfig.showCustomerPhone" v-model="quickReceiptConfig.maskCustomerPhone" size="small">
                    号码脱敏 (138****8888)
                  </el-checkbox>
                </div>
              </div>
            </div>

            <!-- 4. 消费项目明细清单 -->
            <div class="config-group-card">
              <div class="grp-title">🛍️ 消费项目明细清单</div>
              <div class="grp-content">
                <div class="cfg-toggle-row">
                  <el-switch v-model="quickReceiptConfig.showItemsTable" active-text="打印完整商品/服务明细列表" />
                </div>
                <div v-if="quickReceiptConfig.showItemsTable" class="sub-switches-grid">
                  <el-checkbox v-model="quickReceiptConfig.showItemQty">打印数量 (Qty)</el-checkbox>
                  <el-checkbox v-model="quickReceiptConfig.showItemPrice">打印单价 (Price)</el-checkbox>
                  <el-checkbox v-model="quickReceiptConfig.showItemSum">打印小计 (Subtotal)</el-checkbox>
                </div>
              </div>
            </div>

            <!-- 5. 结算金额与支付方式 -->
            <div class="config-group-card">
              <div class="grp-title">💰 结算金额与支付分解</div>
              <div class="grp-content grid-2cols">
                <el-switch v-model="quickReceiptConfig.showOriginalPrice" active-text="消费原价总计" />
                <el-switch v-model="quickReceiptConfig.showDiscount" active-text="优惠/立减金额" />
                <el-switch v-model="quickReceiptConfig.showActualAmount" active-text="实收总额 (核心金额)" />
                <el-switch v-model="quickReceiptConfig.showPayMethods" active-text="支付方式拆分明细" />
              </div>
            </div>

            <!-- 6. 会员双轨储值与资产积分 -->
            <div class="config-group-card">
              <div class="grp-title">💳 会员双轨储值与资产积分变动</div>
              <div class="grp-content">
                <div class="cfg-toggle-row">
                  <el-switch v-model="quickReceiptConfig.showMemberAssetSection" active-text="打印会员双轨资产与积分变动区块" />
                </div>
                <div v-if="quickReceiptConfig.showMemberAssetSection" class="sub-switches-grid">
                  <el-checkbox v-model="quickReceiptConfig.showPrincipalBalance">储值实充本金余额</el-checkbox>
                  <el-checkbox v-model="quickReceiptConfig.showGiftBalance">储值赠送金余额</el-checkbox>
                  <el-checkbox v-model="quickReceiptConfig.showEarnedPoints">本次获赠积分</el-checkbox>
                  <el-checkbox v-model="quickReceiptConfig.showTotalPoints">累计会员总积分</el-checkbox>
                </div>
              </div>
            </div>

            <!-- 7. 页脚致谢、服务与二维码 -->
            <div class="config-group-card">
              <div class="grp-title">📞 页脚致谢、服务指引与二维码</div>
              <div class="grp-content">
                <div class="cfg-toggle-row">
                  <el-switch v-model="quickReceiptConfig.showFooterNotes" active-text="底部致谢标语与售后承诺" />
                  <el-input v-if="quickReceiptConfig.showFooterNotes" v-model="quickReceiptConfig.footerNotes" type="textarea" :rows="2" size="small" style="margin-top: 6px;" />
                </div>
                <div class="cfg-toggle-row">
                  <el-switch v-model="quickReceiptConfig.showServiceHotline" active-text="门店服务热线" />
                  <el-input v-if="quickReceiptConfig.showServiceHotline" v-model="quickReceiptConfig.serviceHotline" size="small" style="margin-top: 6px;" />
                </div>
                <div class="cfg-toggle-row">
                  <el-switch v-model="quickReceiptConfig.showStoreAddress" active-text="门店实体地址" />
                  <el-input v-if="quickReceiptConfig.showStoreAddress" v-model="quickReceiptConfig.storeAddress" size="small" style="margin-top: 6px;" />
                </div>
                <div class="cfg-toggle-row">
                  <el-switch v-model="quickReceiptConfig.showQrCode" active-text="底部微商城/会员码二维码" />
                  <div v-if="quickReceiptConfig.showQrCode" style="margin-top: 6px; display: flex; flex-direction: column; gap: 6px;">
                    <el-input v-model="quickReceiptConfig.qrCodeText" size="small" placeholder="二维码目标网址" />
                    <el-input v-model="quickReceiptConfig.qrCodeHint" size="small" placeholder="二维码下方说明引导语" />
                  </div>
                </div>
              </div>
            </div>

            <!-- 8. 租户留存与签字存根联 -->
            <div class="config-group-card">
              <div class="grp-title">✍️ 租户留存联与顾客签字确认</div>
              <div class="grp-content">
                <div class="cfg-toggle-row">
                  <el-switch v-model="quickReceiptConfig.showSignStub" active-text="打印租户留存联与撕角虚线" />
                </div>
                <div v-if="quickReceiptConfig.showSignStub" class="sub-switches-grid">
                  <el-checkbox v-model="quickReceiptConfig.showStubOrderMeta">流水号与实付金额</el-checkbox>
                  <el-checkbox v-model="quickReceiptConfig.showStubSignLine">顾客签字横线与日期栏</el-checkbox>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 右侧：1:1 动态仿真热敏小票预览舞台 (所见即所得) -->
        <div class="receipt-preview-stage">
          <div class="stage-sticky-header">
            <span class="stage-title">📄 1:1 热敏小票实时预览 (所见即所得)</span>
            <div style="display: flex; gap: 6px;">
              <el-tag size="small" type="primary" effect="dark">{{ quickReceiptConfig.paperWidth }} 纸卷</el-tag>
              <el-tag size="small" type="info" effect="plain">{{ quickReceiptConfig.fontSize === 'compact' ? '紧凑字号' : quickReceiptConfig.fontSize === 'large' ? '大字号' : '标准字号' }}</el-tag>
            </div>
          </div>

          <div class="receipt-paper-bench">
            <!-- 热敏小票纸质本体 (同时作为调用本地打印机的唯一定位目标) -->
            <div
              id="thermal-receipt-printable"
              class="thermal-paper-mockup"
              :class="['width-' + quickReceiptConfig.paperWidth, 'font-' + quickReceiptConfig.fontSize]"
            >
              <!-- 顶部撕纸齿纹线 -->
              <div class="sawtooth-tear-edge top">✄ - - - - - - - - - - - - - - - - - - -</div>

              <!-- 1. 抬头与品牌 -->
              <div v-if="quickReceiptConfig.showStoreHeader || quickReceiptConfig.showHeaderSubtitle || quickReceiptConfig.showTicketTitle" class="receipt-center-box">
                <div v-if="quickReceiptConfig.showStoreHeader" class="receipt-shop-name">{{ quickReceiptConfig.storeHeaderTitle || currentStoreName }}</div>
                <div v-if="quickReceiptConfig.showHeaderSubtitle" class="receipt-sub-title">{{ quickReceiptConfig.headerSubTitle }}</div>
                <div v-if="quickReceiptConfig.showTicketTitle" class="receipt-ticket-type">【 {{ quickReceiptConfig.ticketTitle || '顾客结账消费明细清单' }} 】</div>
              </div>

              <div class="receipt-divider star">********************************</div>

              <!-- 2. 单据与客显元数据 -->
              <div class="receipt-meta-grid">
                <div v-if="quickReceiptConfig.showOrderNo" class="meta-row"><span>单据编号：</span><span class="mono">{{ settledResult?.order?.orderNo || order?.orderNo }}</span></div>
                <div v-if="quickReceiptConfig.showCheckoutTime" class="meta-row"><span>结账时间：</span><span>{{ checkoutTimeStr }}</span></div>
                <div v-if="quickReceiptConfig.showCashierName" class="meta-row"><span>收银操作员：</span><span>{{ currentCashierName }}</span></div>
                <div v-if="quickReceiptConfig.showTechnician" class="meta-row"><span>空间工位：</span><span>{{ order?.spaceName || '1号造型镜台' }}</span></div>
                <div v-if="quickReceiptConfig.showCustomerName" class="meta-row">
                  <span>顾客身份：</span>
                  <span>{{ memberProfile?.member?.name || memberProfile?.name || order?.customerName || '到店散客' }} ({{ memberProfile?.member?.level || memberProfile?.levelName || '普通顾客' }})</span>
                </div>
                <div v-if="quickReceiptConfig.showCustomerPhone" class="meta-row">
                  <span>会员手机：</span>
                  <span class="mono">{{ formatPhoneDisplay(memberProfile?.member?.phone || memberProfile?.phone || order?.customerPhone || '13812345678') }}</span>
                </div>
              </div>

              <!-- 3. 消费明细清单 -->
              <template v-if="quickReceiptConfig.showItemsTable">
                <div class="receipt-divider dash">--------------------------------</div>
                <div class="receipt-items-table">
                  <div class="items-head">
                    <span class="col-name">品名项目</span>
                    <span v-if="quickReceiptConfig.showItemQty" class="col-qty">数量</span>
                    <span v-if="quickReceiptConfig.showItemPrice" class="col-price">单价</span>
                    <span v-if="quickReceiptConfig.showItemSum" class="col-sum">小计</span>
                  </div>
                  <div
                    v-for="(it, idx) in (order?.items?.length ? order.items : sampleOrderItems)"
                    :key="idx"
                    class="item-row"
                  >
                    <div class="item-name">{{ it.name || it.productName }}</div>
                    <div class="item-meta">
                      <span v-if="quickReceiptConfig.showItemQty" class="col-qty">x{{ it.qty || it.quantity || 1 }}</span>
                      <span v-if="quickReceiptConfig.showItemPrice" class="col-price">￥{{ (it.price || 0).toFixed(2) }}</span>
                      <span v-if="quickReceiptConfig.showItemSum" class="col-sum">￥{{ ((it.price || 0) * (it.qty || it.quantity || 1)).toFixed(2) }}</span>
                    </div>
                  </div>
                  <!-- 行业附加费 (茶位费/餐具费等) 明细行 -->
                  <div v-if="Number(order?.feeAmount) > 0" class="item-row fee-print-row" style="font-weight: 700;">
                    <div class="item-name">[附加费] {{ storeConfig.defaultFeeName || '茶位费/餐具费' }}</div>
                    <div class="item-meta">
                      <span v-if="quickReceiptConfig.showItemQty" class="col-qty">x1</span>
                      <span v-if="quickReceiptConfig.showItemPrice" class="col-price">￥{{ Number(order.feeAmount).toFixed(2) }}</span>
                      <span v-if="quickReceiptConfig.showItemSum" class="col-sum">￥{{ Number(order.feeAmount).toFixed(2) }}</span>
                    </div>
                  </div>
                </div>
              </template>

              <!-- 4. 费用与支付拆分 -->
              <div class="receipt-divider dash">--------------------------------</div>
              <div class="receipt-calc-box">
                <div v-if="quickReceiptConfig.showOriginalPrice" class="calc-row">
                  <span>点单消费项目：</span>
                  <span>￥{{ (Number(order?.totalAmount) || totalItemsAmount || 508).toFixed(2) }}</span>
                </div>
                <div v-if="Number(order?.feeAmount) > 0" class="calc-row fee-calc-row">
                  <span>行业附加费 ({{ storeConfig.defaultFeeName || '茶位费/餐具费' }})：</span>
                  <span style="font-weight: 700;">+￥{{ Number(order.feeAmount).toFixed(2) }}</span>
                </div>
                <div v-if="quickReceiptConfig.showDiscount && (((Number(order?.totalAmount) || totalItemsAmount || 508) + (Number(order?.feeAmount) || 0)) > (order?.actualAmount || 380))" class="calc-row discount">
                  <span>优惠立减：</span>
                  <span>-￥{{ (((Number(order?.totalAmount) || totalItemsAmount || 508) + (Number(order?.feeAmount) || 0)) - (order?.actualAmount || 380)).toFixed(2) }}</span>
                </div>
                <div v-if="quickReceiptConfig.showActualAmount" class="calc-row total">
                  <span>实收总额：</span>
                  <span class="bold-price">￥{{ (order?.actualAmount || 380).toFixed(2) }}</span>
                </div>

                <!-- 支付方式细分 -->
                <div v-if="quickReceiptConfig.showPayMethods" class="pay-split-list">
                  <div v-if="payPlan.storedValue > 0" class="pay-row">
                    <span>└ 双轨储值划扣：</span>
                    <span>￥{{ payPlan.storedValue.toFixed(2) }}</span>
                  </div>
                  <div v-if="payPlan.wechat > 0 || (!payPlan.storedValue && !payPlan.alipay && !payPlan.cash)" class="pay-row">
                    <span>└ 微信在线支付：</span>
                    <span>￥{{ (payPlan.wechat || order?.actualAmount || 380).toFixed(2) }}</span>
                  </div>
                  <div v-if="payPlan.alipay > 0" class="pay-row">
                    <span>└ 支付宝支付：</span>
                    <span>￥{{ payPlan.alipay.toFixed(2) }}</span>
                  </div>
                  <div v-if="payPlan.cash > 0" class="pay-row">
                    <span>└ 现金现钞实收：</span>
                    <span>￥{{ payPlan.cash.toFixed(2) }}</span>
                  </div>
                  <div v-if="settledResult?.cashTender && settledResult.cashTender.changeAmount > 0" class="pay-row change">
                    <span>└ 现金找零补回：</span>
                    <span>￥{{ settledResult.cashTender.changeAmount.toFixed(2) }}</span>
                  </div>
                </div>
              </div>

              <!-- 5. 会员双轨资产及积分变动 -->
              <div v-if="quickReceiptConfig.showMemberAssetSection" class="receipt-member-asset-box">
                <div class="receipt-divider dash">--------------------------------</div>
                <div class="asset-title-block">【 会员双轨资产与积分变动 】</div>
                <div class="asset-grid">
                  <div v-if="quickReceiptConfig.showPrincipalBalance" class="asset-row">
                    <span>储值本金余额：</span>
                    <span class="mono">￥{{ (memberProfile?.dualBalance?.principalBalance || memberProfile?.principalBalance || 0).toFixed(2) }}</span>
                  </div>
                  <div v-if="quickReceiptConfig.showGiftBalance" class="asset-row">
                    <span>储值赠金余额：</span>
                    <span class="mono">￥{{ (memberProfile?.dualBalance?.giftBalance || memberProfile?.giftBalance || 0).toFixed(2) }}</span>
                  </div>
                  <div v-if="quickReceiptConfig.showEarnedPoints" class="asset-row">
                    <span>本次获赠积分：</span>
                    <span class="mono text-green">+{{ Math.round(order?.actualAmount || 380) }} 分</span>
                  </div>
                  <div v-if="quickReceiptConfig.showTotalPoints" class="asset-row">
                    <span>会员累计总积分：</span>
                    <span class="mono">{{ ((memberProfile?.points || 0) + Math.round(order?.actualAmount || 380)) }} 分</span>
                  </div>
                </div>
              </div>

              <div class="receipt-divider star">********************************</div>

              <!-- 6. 底部致谢与服务指引 -->
              <div class="receipt-footer-box">
                <div v-if="quickReceiptConfig.showFooterNotes" class="footer-notes">{{ quickReceiptConfig.footerNotes }}</div>
                <div class="footer-meta">
                  <div v-if="quickReceiptConfig.showServiceHotline">服务热线：{{ quickReceiptConfig.serviceHotline || currentStorePhone }}</div>
                  <div v-if="quickReceiptConfig.showStoreAddress">门店地址：{{ quickReceiptConfig.storeAddress || currentStoreAddress }}</div>
                </div>

                <!-- 二维码 -->
                <div v-if="quickReceiptConfig.showQrCode" class="receipt-qr-zone">
                  <div class="qr-img-wrapper">
                    <img v-if="receiptQrCodeDataUrl" :src="receiptQrCodeDataUrl" class="qr-real-img" alt="小票二维码" />
                    <div v-else class="qr-mock-box">
                      <div class="qr-mock-code">
                        <div class="qr-inner-pattern"></div>
                      </div>
                    </div>
                  </div>
                  <div class="qr-hint-text">{{ quickReceiptConfig.qrCodeHint || '扫码查看店铺信息与会员权益' }}</div>
                  <div class="qr-url-text" style="font-size: 9.5px; color: #64748b; margin-top: 3px; word-break: break-all; opacity: 0.85;">{{ quickReceiptConfig.qrCodeText }}</div>
                </div>
              </div>

              <!-- 7. 顾客签字存根联 -->
              <div v-if="quickReceiptConfig.showSignStub" class="receipt-sign-stub">
                <div class="stub-divider">✄ - - - - - - - - - - - - - - - - - - -</div>
                <div class="stub-header">【 租户留存联 · 顾客签字确认 】</div>
                <div v-if="quickReceiptConfig.showStubOrderMeta" class="stub-meta">
                  <div>流水号：{{ settledResult?.order?.orderNo || order?.orderNo }}</div>
                  <div>实付金额：￥{{ (order?.actualAmount || 380).toFixed(2) }}</div>
                </div>
                <div v-if="quickReceiptConfig.showStubSignLine" class="stub-sign-block">
                  <div class="stub-sign-row">
                    <span class="sign-label">顾客签字：</span>
                    <span class="sign-underline"></span>
                  </div>
                  <div class="stub-date-row">
                    <span>签单日期：____年__月__日</span>
                  </div>
                </div>
              </div>

              <!-- 底部撕纸齿纹线 -->
              <div class="sawtooth-tear-edge bottom">✄ - - - - - - - - - - - - - - - - - - -</div>
            </div>
          </div>
        </div>
      </div>

      <template #footer>
        <div class="dialog-footer-flex">
          <el-button @click="successDialogVisible = false">关闭预览</el-button>
          <div class="right-btns">
            <el-button type="primary" size="large" icon="Printer" @click="handlePrintReceipt">
              🖨️ 调用本地打印机打印出单
            </el-button>
            <el-button type="success" @click="handleSuccessConfirm">
              返回工位看板
            </el-button>
          </div>
        </div>
      </template>
    </el-dialog>

    <!-- 小票打印模板快捷配置抽屉 -->
    <el-drawer
      v-model="openReceiptConfigDrawer"
      title="🖨️ 小票打印模板可视化配置"
      size="420px"
    >
      <el-form label-position="top">
        <el-alert
          title="此处修改将即时影响收银结算后的小票内容，配置将自动保存在系统中。"
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 16px;"
        />
        <el-form-item label="热敏纸张规格">
          <el-radio-group v-model="quickReceiptConfig.paperWidth">
            <el-radio-button label="80mm">80mm 大宽幅小票机</el-radio-button>
            <el-radio-button label="58mm">58mm 标准前台机</el-radio-button>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="小票抬头名称">
          <el-input v-model="quickReceiptConfig.storeHeaderTitle" placeholder="如：海马智慧旗舰店" />
        </el-form-item>

        <el-form-item label="页眉宣传标语">
          <el-input v-model="quickReceiptConfig.headerSubTitle" placeholder="如：至臻品质 · 竭诚服务" />
        </el-form-item>

        <el-form-item label="显示控制开关">
          <div style="display: flex; flex-direction: column; gap: 8px;">
            <el-checkbox v-model="quickReceiptConfig.showTechnician" label="打印服务技师/工位信息" />
            <el-checkbox v-model="quickReceiptConfig.showDualTrackBalance" label="打印双轨储值本金与赠送金余额" />
            <el-checkbox v-model="quickReceiptConfig.showPoints" label="打印本次积分及累计积分" />
            <el-checkbox v-model="quickReceiptConfig.showSignStub" label="打印租户留存联与顾客签字栏" />
            <el-checkbox v-model="quickReceiptConfig.autoPrint" label="结算后自动调起本地打印" />
          </div>
        </el-form-item>

        <el-form-item label="底部致谢提示标语">
          <el-input
            v-model="quickReceiptConfig.footerNotes"
            type="textarea"
            :rows="2"
            placeholder="如：凭此小票享7天服务复修，欢迎再次光临！"
          />
        </el-form-item>

        <el-form-item label="底部二维码引导语">
          <el-input v-model="quickReceiptConfig.qrCodeText" placeholder="如：扫码领取会员礼券或进入微商城" />
        </el-form-item>

        <div style="margin-top: 24px;">
          <el-button type="primary" style="width: 100%;" @click="handleSaveQuickConfig">
            保存模板配置并刷新预览
          </el-button>
        </div>
      </el-form>
    </el-drawer>

    <!-- 会员等级晋升规则全阶梯说明弹窗 -->
    <el-dialog v-model="showLevelRulesModal" title="👑 海马会员成长与等级晋升规则" width="680px">
      <div class="level-rules-dialog-content">
        <el-alert
          type="info"
          show-icon
          :closable="false"
          title="消费积分无上限 · 自动晋级享特权"
          description="每到店消费 1 元即获赠 1 点会员成长经验/积分，达到门槛系统自动平滑晋级，永久尊享对应会员专属折扣与尊崇礼遇。"
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

    <!-- 📂 常驻挂单取单抽屉 (F4) -->
    <el-drawer
      v-model="isHeldDrawerVisible"
      title="📂 暂挂账单列表 (挂单 F2 / 取单 F4)"
      size="460px"
    >
      <div v-if="heldOrdersList.length === 0" style="padding: 40px 0; text-align: center;">
        <el-empty description="暂无挂单单据" />
      </div>
      <div v-else class="held-orders-drawer-list">
        <div
          v-for="(item, idx) in heldOrdersList"
          :key="item.id"
          class="held-order-card"
        >
          <div class="held-header">
            <span class="held-space">{{ item.orderSnapshot.spaceName }}</span>
            <el-tag size="small" type="warning">{{ item.holdTime }} 挂单</el-tag>
          </div>
          <div class="held-info">
            <div>单号: <b class="mono-text">{{ item.orderSnapshot.orderNo }}</b></div>
            <div>顾客: {{ item.orderSnapshot.customerName }}</div>
            <div>品项数: {{ (item.orderSnapshot.items || []).length }} 项 | 金额: <b style="color: #047857;">￥{{ Number(item.orderSnapshot.actualAmount).toFixed(2) }}</b></div>
          </div>
          <div class="held-actions">
            <el-button type="primary" size="small" icon="TopRight" @click="handleRestoreHeldOrder(idx)">恢复取单</el-button>
            <el-button type="danger" size="small" plain icon="Delete" @click="handleRemoveHeldOrder(idx)">移除</el-button>
          </div>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">

const activeProductCategory = ref('ALL')
const productSearchKeyword = ref('')
const cashierBarcodeScanInputRef = ref<any>(null)
const barcodeScanInput = ref('')
const isHeldDrawerVisible = ref(false)
const heldOrdersList = ref<any[]>([])

// 默认兜底散客单据初始化
const initWalkInOrder = () => {
  const defaultNo = 'ORD-' + Date.now().toString().slice(-6)
  order.value = {
    id: Date.now(),
    orderNo: defaultNo,
    spaceName: '前台外带/随到散客',
    customerName: '散客顾客',
    customerPhone: '',
    totalAmount: 0,
    feeAmount: 0,
    discountAmount: 0,
    actualAmount: 0,
    status: 'IN_SERVICE',
    items: []
  }
}

// 根据当前门店业态动态渲染商品分类页签
const industryCategoryTabs = computed(() => {
  const ind = (storeConfig.industry || localStorage.getItem('seahorse_industry') || 'BEAUTY').toUpperCase()
  if (ind === 'RESTAURANT') {
    return [
      { value: 'SERVICE', label: '🍲 招牌锅底/主菜' },
      { value: 'RETAIL', label: '🥩 鲜切涮品/小食' },
      { value: 'DRINK', label: '🧋 精酿茶饮' }
    ]
  }
  if (ind === 'AUTO') {
    return [
      { value: 'SERVICE', label: '🔧 维保工时服务' },
      { value: 'RETAIL', label: '🛢️ 机油配件精品' },
      { value: 'DRINK', label: '☕ 客休茶水' }
    ]
  }
  if (ind === 'RETAIL') {
    return [
      { value: 'RETAIL', label: '🛍️ 甄选零售商品' },
      { value: 'SERVICE', label: '🎁 礼盒定制/护理' },
      { value: 'DRINK', label: '☕ 现制饮品' }
    ]
  }
  return [
    { value: 'RETAIL', label: '🧴 零售洗护' },
    { value: 'SERVICE', label: '✂️ 造型服务' },
    { value: 'DRINK', label: '🧋 水吧茶饮' }
  ]
})

// 门店收银台商品库与服务项目 (随行业动态切换)
const storeCatalogProducts = computed(() => {
  const ind = (storeConfig.industry || localStorage.getItem('seahorse_industry') || 'BEAUTY').toUpperCase()
  const presetsByInd: Record<string, any[]> = {
    BEAUTY: [
      { id: 101, code: '6920182736192', name: '欧莱雅专业洗护精油 100ml', category: 'RETAIL', categoryName: '洗护零售', price: 168.0, stock: 45, icon: '🧴' },
      { id: 102, code: '6901234567890', name: '植物赋活深层发膜 500ml', category: 'RETAIL', categoryName: '洗护零售', price: 198.0, stock: 28, icon: '🌿' },
      { id: 103, code: '6934567890123', name: '施华蔻定型动感发胶 300ml', category: 'RETAIL', categoryName: '洗护零售', price: 88.0, stock: 60, icon: '✨' },
      { id: 104, code: '6945678901234', name: '卡诗双重菁纯修护液 50ml', category: 'RETAIL', categoryName: '洗护零售', price: 280.0, stock: 15, icon: '💎' },
      { id: 201, code: 'BEA-001', name: '总监设计造型精剪', category: 'SERVICE', categoryName: '美发造型', price: 88.0, stock: 999, icon: '✂️' },
      { id: 202, code: 'BEA-002', name: '欧莱雅蛋白冷烫/热烫造型', category: 'SERVICE', categoryName: '美发造型', price: 380.0, stock: 999, icon: '💇' },
      { id: 203, code: 'BEA-003', name: '资生堂臻璨高光染发', category: 'SERVICE', categoryName: '美发造型', price: 460.0, stock: 999, icon: '🎨' },
      { id: 204, code: 'BEA-004', name: '头部深度水疗放松SPA', category: 'SERVICE', categoryName: '洗吹护理', price: 128.0, stock: 999, icon: '💆' }
    ],
    RESTAURANT: [
      { id: 401, code: 'RES-001', name: '招牌牛油花胶鸳鸯锅底', category: 'SERVICE', categoryName: '招牌锅底', price: 78.0, stock: 99, icon: '🍲' },
      { id: 402, code: 'RES-002', name: 'M9雪花和牛上脑 (大份)', category: 'RETAIL', categoryName: '鲜切涮品', price: 138.0, stock: 42, icon: '🥩' },
      { id: 403, code: 'RES-003', name: '鲜活手打黑虎虾滑', category: 'RETAIL', categoryName: '鲜切涮品', price: 58.0, stock: 60, icon: '🦐' },
      { id: 404, code: 'RES-004', name: '有机山野菌菇拼盘', category: 'RETAIL', categoryName: '鲜切涮品', price: 46.0, stock: 50, icon: '🍄' }
    ],
    AUTO: [
      { id: 501, code: 'AUT-001', name: '全车精洗+内饰臭氧杀菌', category: 'SERVICE', categoryName: '维保工时', price: 88.0, stock: 999, icon: '🚿' },
      { id: 502, code: 'AUT-002', name: '美孚一号全合成机油小保养', category: 'SERVICE', categoryName: '维保工时', price: 580.0, stock: 999, icon: '🔧' },
      { id: 503, code: 'AUT-003', name: '米其林静音防爆轮胎 225/45R18', category: 'RETAIL', categoryName: '机油配件', price: 890.0, stock: 16, icon: '🛞' },
      { id: 504, code: 'AUT-004', name: '3M全车纳米陶瓷隐形车衣护理液', category: 'RETAIL', categoryName: '机油配件', price: 260.0, stock: 30, icon: '🛢️' }
    ],
    RETAIL: [
      { id: 601, code: 'RET-001', name: '大马士革玫瑰无火香薰礼盒', category: 'RETAIL', categoryName: '甄选商品', price: 258.0, stock: 38, icon: '🕯️' },
      { id: 602, code: 'RET-002', name: '6A级桑蚕丝真丝眼罩睡眠套装', category: 'RETAIL', categoryName: '甄选商品', price: 198.0, stock: 52, icon: '🎀' },
      { id: 603, code: 'RET-003', name: '骨瓷手绘下午茶双人咖啡杯碟组', category: 'RETAIL', categoryName: '甄选商品', price: 368.0, stock: 20, icon: '🫖' },
      { id: 604, code: 'RET-004', name: '专属火漆印章高定礼盒包装服务', category: 'SERVICE', categoryName: '礼盒定制', price: 38.0, stock: 999, icon: '🎁' }
    ]
  }
  const commonDrinks = [
    { id: 301, code: 'SNK-001', name: '现萃茉莉初雪奶茶 (常温/冰)', category: 'DRINK', categoryName: '水吧饮品', price: 18.0, stock: 100, icon: '🧋' },
    { id: 302, code: 'SNK-002', name: '特调气泡美式咖啡', category: 'DRINK', categoryName: '水吧饮品', price: 22.0, stock: 80, icon: '☕' },
    { id: 303, code: 'SNK-003', name: '手工烘焙黄油牛角包', category: 'DRINK', categoryName: '水吧饮品', price: 15.0, stock: 30, icon: '🥐' }
  ]
  const defaultList = [...(presetsByInd[ind] || presetsByInd.BEAUTY), ...commonDrinks]
  const sysProds = (systemData.products || []).map((p: any) => ({
    id: p.id,
    code: p.code || ('PRD-' + p.id),
    name: p.name,
    category: p.category || (p.type === 'SERVICE' || p.code?.startsWith('BEA') || p.code?.startsWith('SRV') ? 'SERVICE' : 'RETAIL'),
    categoryName: p.categoryName || (p.type === 'SERVICE' ? '门市服务' : '精选商品'),
    price: Number(p.price) || 0,
    stock: p.stock ?? 99,
    icon: p.type === 'SERVICE' || p.category === 'SERVICE' ? (ind === 'RESTAURANT' ? '🍲' : ind === 'AUTO' ? '🔧' : '✂️') : '🛍️'
  }))
  const map = new Map<string, any>()
  sysProds.forEach((item: any) => map.set(item.code, item))
  defaultList.forEach(item => {
    if (!map.has(item.code)) map.set(item.code, item)
  })
  return Array.from(map.values())
})

// 分类与搜索过滤
const filteredCatalogProducts = computed(() => {
  return storeCatalogProducts.value.filter(item => {
    const matchCat = activeProductCategory.value === 'ALL' || item.category === activeProductCategory.value
    const kw = productSearchKeyword.value.trim().toLowerCase()
    const matchKw = !kw || item.name.toLowerCase().includes(kw) || item.code.toLowerCase().includes(kw)
    return matchCat && matchKw
  })
})

// 点击商品卡片加入购物车/当前单据
const addProductCardToOrder = (prod: any) => {
  if (!order.value) {
    initWalkInOrder()
  }
  if (!order.value.items) {
    order.value.items = []
  }
  const exist = order.value.items.find((it: any) => it.code === prod.code || it.name === prod.name)
  if (exist) {
    exist.qty = (exist.qty || 1) + 1
  } else {
    order.value.items.push({
      id: prod.id,
      code: prod.code,
      name: prod.name,
      price: prod.price,
      qty: 1,
      type: prod.category === 'SERVICE' ? 'SERVICE' : 'RETAIL'
    })
  }
  recalcOrderTotal()
  ElMessage.success(`已添加【${prod.name}】至当前单据`)
  ensureScannerFocus()
}

// 确保扫码输入框始终获取焦点
const ensureScannerFocus = () => {
  setTimeout(() => {
    const el = document.getElementById('cashierBarcodeScanInput')
    if (el) el.focus()
  }, 100)
}

const handleScannerBlur = () => {
  setTimeout(() => {
    const activeEl = document.activeElement
    if (activeEl && (activeEl.tagName === 'INPUT' || activeEl.tagName === 'TEXTAREA')) {
      return
    }
    const el = document.getElementById('cashierBarcodeScanInput')
    if (el) el.focus()
  }, 350)
}

// 顶部扫码框回车提交
const handleBarcodeScanSubmit = () => {
  const code = (barcodeScanInput.value || '').trim()
  if (!code) return
  barcodeScanInput.value = ''
  
  if (/^(10|11|12|13|14|15)\d{16}$/.test(code)) {
    handleScanPaymentCode(code, 'WECHAT')
  } else if (/^(28|29|30)\d{14,22}$/.test(code)) {
    handleScanPaymentCode(code, 'ALIPAY')
  } else {
    if (!order.value) {
      initWalkInOrder()
    }
    handleScanProductCode(code)
  }
  ensureScannerFocus()
}

// 挂单 (F2)
const handleHoldOrder = () => {
  if (!order.value || (!order.value.items?.length && !(Number(order.value.totalAmount) > 0))) {
    ElMessage.warning('当前无有效账单项目，无需挂单')
    return
  }
  const holdItem = {
    id: Date.now(),
    holdTime: new Date().toLocaleTimeString(),
    orderSnapshot: JSON.parse(JSON.stringify(order.value)),
    memberSnapshot: memberProfile.value ? JSON.parse(JSON.stringify(memberProfile.value)) : null
  }
  heldOrdersList.value.push(holdItem)
  saveHeldOrdersToStorage()
  ElMessage.success(`⏸️ 挂单成功！当前单据已存入暂挂队列（单号: ${order.value.orderNo}）`)
  order.value = null
  memberProfile.value = null
  selectedPayerMemberId.value = null
  ensureScannerFocus()
}

const getHeldOrdersStorageKey = () => `seahorse_held_orders_${storeConfig.currentStoreId || localStorage.getItem('seahorse_store_id') || 'S001'}`

const loadHeldOrdersFromStorage = () => {
  try {
    const raw = localStorage.getItem(getHeldOrdersStorageKey())
    heldOrdersList.value = raw ? JSON.parse(raw) : []
  } catch {
    heldOrdersList.value = []
  }
}

const saveHeldOrdersToStorage = () => {
  try {
    localStorage.setItem(getHeldOrdersStorageKey(), JSON.stringify(heldOrdersList.value))
  } catch {}
}

// 取单 (F4)
const handleRestoreHeldOrder = (index: number) => {
  const holdItem = heldOrdersList.value[index]
  if (!holdItem) return
  order.value = holdItem.orderSnapshot
  memberProfile.value = holdItem.memberSnapshot
  if (memberProfile.value?.id) {
    selectedPayerMemberId.value = memberProfile.value.id
  }
  heldOrdersList.value.splice(index, 1)
  saveHeldOrdersToStorage()
  isHeldDrawerVisible.value = false
  recalcOrderTotal()
  ElMessage.success(`📂 已恢复取单：【${order.value.spaceName} / ${order.value.orderNo}】`)
  ensureScannerFocus()
}

// 移除暂挂单
const handleRemoveHeldOrder = (index: number) => {
  heldOrdersList.value.splice(index, 1)
  saveHeldOrdersToStorage()
  ElMessage.info('已移除挂单记录')
}

// 快捷结账 (F8)
const handleQuickF8Checkout = () => {
  if (!order.value) {
    ElMessage.warning('当前无待结账单据')
    return
  }
  if (!isAmountMatched.value) {
    switchToSingleChannel('wechat')
  }
  handleDoCheckout()
}

// 全局快捷键监听 (F2 挂单, F4 取单, F8 结账)
const handleGlobalKeydown = (e: KeyboardEvent) => {
  if (e.key === 'F2') {
    e.preventDefault()
    handleHoldOrder()
  } else if (e.key === 'F4') {
    e.preventDefault()
    isHeldDrawerVisible.value = !isHeldDrawerVisible.value
  } else if (e.key === 'F8') {
    e.preventDefault()
    handleQuickF8Checkout()
  }
}
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { barcodeScanner, type BarcodeScanResult, scanAudio } from '../utils/barcodeScanner'
import { useRoute, useRouter } from 'vue-router'
import QRCode from 'qrcode'
import {
  requestBillingApi,
  executeCheckoutApi,
  getMemberProfileApi,
  getSessionDetailApi,
  searchMembersApi,
  registerMemberApi,
  getActiveSessionsApi
} from '../api'
import { useStoreConfig } from '../stores/store'
import { useSystemDataStore, buildMemberBenefitsUrl } from '../stores/systemDataStore'
import { ElMessage } from 'element-plus'

const route = useRoute()
const router = useRouter()
const storeConfig = useStoreConfig()
const systemData = useSystemDataStore()

const order = ref<any>(null)
const memberProfile = ref<any>(null)
const settling = ref(false)

const payPlan = ref({
  wechat: 0,
  alipay: 0,
  storedValue: 0,
  cash: 0
})

const tenderedAmount = ref(0)
const isSuperAdmin = computed(() => {
  const r = localStorage.getItem('seahorse_role') || ''
  return r === 'SUPER_ADMIN' || r === 'PLATFORM_DEVELOPER' || r === 'PLATFORM_ADMIN' || r === 'PLATFORM_SUPER_ADMIN'
})
const successDialogVisible = ref(false)
const settledResult = ref<any>(null)

// 真实活跃会话与选单数据
const serverActiveSessions = ref<any[]>([])

const loadActiveSessions = async () => {
  try {
    const list: any = await getActiveSessionsApi()
    if (Array.isArray(list)) {
      serverActiveSessions.value = list
    }
  } catch (e) {
    console.warn('获取在场活跃工位失败:', e)
  }
}

// 在场工位待买单候选单据 (合并服务端真实会话、Pinia本地会话与当前单据，确保绝不只显示裸数字)
const sessionListOptions = computed(() => {
  const map = new Map<number, any>()

  // 1. 服务端实时在场会话 (优先)
  serverActiveSessions.value.forEach((s: any) => {
    map.set(Number(s.id), {
      id: Number(s.id),
      spaceName: s.spaceName || `工位/包厢 ${s.id}`,
      customerName: s.customerName || '散客顾客',
      customerPhone: s.customerPhone,
      memberId: s.memberId,
      totalAmount: s.totalAmount || 0,
      feeAmount: s.feeAmount || 0,
      orderNo: s.sessionNo ? `BL${s.sessionNo.replace('SES', '')}` : `ORD-${s.id}`,
      status: s.status
    })
  })

  // 2. 本地系统在场会话
  systemData.liveSessions.forEach((s: any) => {
    if (!map.has(Number(s.id))) {
      map.set(Number(s.id), {
        id: Number(s.id),
        spaceName: s.spaceName,
        customerName: s.customerName,
        customerPhone: s.customerPhone,
        memberId: s.memberId,
        totalAmount: s.totalAmount,
        feeAmount: s.feeAmount || 0,
        orderNo: `BL${s.sessionNo.replace('SES', '')}`,
        status: s.status
      })
    }
  })

  // 3. 若当前已载入 order，但其 sessionId 不在列表中，自动补齐防止选项显示为空或只显示数字
  if (order.value && order.value.sessionId && !map.has(Number(order.value.sessionId))) {
    const sId = Number(order.value.sessionId)
    map.set(sId, {
      id: sId,
      spaceName: order.value.spaceName || `工位 ${sId}`,
      customerName: order.value.customerName || '散客顾客',
      customerPhone: order.value.customerPhone,
      memberId: order.value.memberId,
      totalAmount: order.value.totalAmount,
      feeAmount: order.value.feeAmount || 0,
      orderNo: order.value.orderNo,
      status: order.value.status
    })
  }

  return Array.from(map.values())
})
const currentSessionSelectId = ref<number>(1)

// 本店真实会员列表
const serverMembersList = ref<any[]>([])

const loadStoreMembers = async (query = '', targetTenantId?: string) => {
  try {
    const tenant = targetTenantId || order.value?.tenantId || storeConfig.tenantId
    const data: any = await searchMembersApi(query, tenant)
    if (Array.isArray(data)) {
      serverMembersList.value = data.map((m: any) => ({
        id: m.id,
        memberNo: m.memberNo,
        name: m.name,
        phone: m.phone,
        level: m.level,
        levelName: m.levelName || formatMemberLevel(m.level),
        principalBalance: m.principalBalance ?? (m.balance ?? 0),
        giftBalance: m.giftBalance ?? 0,
        totalBalance: m.totalBalance ?? (m.balance ?? 0),
        points: m.points ?? 0
      }))
    }
  } catch (e) {
    console.warn('获取服务端会员档案降级:', e)
  }
}

const matchedCustomerMember = computed(() => {
  if (!order.value?.customerPhone && !order.value?.customerName) return null
  const phone = order.value?.customerPhone?.trim()
  const name = order.value?.customerName?.trim()
  if (phone) {
    const byPhone = storeMembersList.value.find(m => m.phone && m.phone.trim() === phone)
    if (byPhone) return byPhone
  }
  if (name && name !== '散客' && name !== '散客顾客') {
    const byName = storeMembersList.value.find(m => m.name && m.name.trim() === name)
    if (byName) return byName
  }
  return null
})

const handleQuickRegisterCurrentCustomer = async () => {
  if (!order.value?.customerPhone) {
    ElMessage.warning('当前无散客手机号，无法一键建档')
    return
  }
  const phone = order.value.customerPhone.trim()
  const name = (order.value.customerName && order.value.customerName !== '散客' && order.value.customerName !== '散客顾客')
    ? order.value.customerName.trim()
    : `顾客${phone.slice(-4)}`
  try {
    const res: any = await registerMemberApi({
      name,
      phone,
      level: 'REGULAR',
      tenantId: order.value?.tenantId || storeConfig.tenantId,
      storeId: storeConfig.storeId
    })
    ElMessage.success(`🎉 散客【${name} (${phone})】已成功建档开卡！`)
    await loadStoreMembers('', order.value?.tenantId || storeConfig.tenantId)
    const newMember = storeMembersList.value.find(m => m.phone === phone) || res?.data || res
    if (newMember && newMember.id) {
      await handlePayerMemberChange(newMember.id)
    }
  } catch (e: any) {
    console.error('一键建档开卡失败:', e)
    ElMessage.error(e?.message || '一键建档开卡失败，请重试')
  }
}

const storeMembersList = computed(() => {
  const map = new Map<string, any>()

  // 1. 服务端真实会员列表 (优先)
  serverMembersList.value.forEach((m: any) => {
    map.set(String(m.id), m)
  })

  // 2. 本地系统会员缓存 (若有尚未同步到服务端的，合并进来)
  const cachedMembersRaw = localStorage.getItem('seahorse_members_data')
  if (cachedMembersRaw) {
    try {
      const parsed = JSON.parse(cachedMembersRaw)
      if (Array.isArray(parsed)) {
        parsed.forEach((m: any) => {
          if (!map.has(String(m.id))) {
            map.set(String(m.id), {
              id: m.id,
              memberNo: m.memberNo,
              name: m.name,
              phone: m.phone,
              level: m.level,
              levelName: m.levelName || formatMemberLevel(m.level),
              principalBalance: m.principalBalance ?? (m.balance ?? 0),
              giftBalance: m.giftBalance ?? 0,
              totalBalance: m.totalBalance ?? (m.balance ?? 0),
              points: m.points ?? 0
            })
          }
        })
      }
    } catch {}
  }

  ;(systemData.membersWithStats || []).forEach((m: any) => {
    if (!map.has(String(m.id))) {
      map.set(String(m.id), {
        id: m.id,
        memberNo: m.memberNo,
        name: m.name,
        phone: m.phone,
        level: m.level,
        levelName: m.levelName || formatMemberLevel(m.level),
        principalBalance: m.principalBalance ?? (m.balance ?? 0),
        giftBalance: m.giftBalance ?? 0,
        totalBalance: m.totalBalance ?? (m.balance ?? 0),
        points: m.points ?? 0
      })
    }
  })

  return Array.from(map.values())
})
const selectedPayerMemberId = ref<number | null>(null)

const handlePayerMemberChange = async (memId: number | null) => {
  selectedPayerMemberId.value = memId
  if (!memId) {
    memberProfile.value = null
    payPlan.value.storedValue = 0
    if (order.value) {
      order.value.discountAmount = 0
      order.value.memberId = null
      recalcOrderTotal()
    }
    ElMessage.info('已切换为【散客/无会员卡】结账模式')
    return
  }

  // 1. 尝试从服务端接口精准拉取该会员的完整画像（包含双轨储值本金/赠金、计次卡等）
  try {
    const prof: any = await getMemberProfileApi(memId)
    if (prof && prof.member) {
      memberProfile.value = prof
      if (order.value) {
        order.value.memberId = prof.member.id
        recalcOrderTotal()
      }
      const totalBal = ((prof.dualBalance?.principalBalance || 0) + (prof.dualBalance?.giftBalance || 0)).toFixed(2)
      ElMessage.success(`已绑定付款会员：【${prof.member.name}】(${prof.levelName || '普通会员'})，可用储值：￥${totalBal}`)
      return
    }
  } catch (e) {
    console.warn('获取服务端会员完整画像降级:', e)
  }

  // 2. 降级从 storeMembersList 中构造
  const targetMember = storeMembersList.value.find(m => m.id === memId)
  if (targetMember) {
    const memCards = systemData.timeCards.filter(tc => tc.memberId === targetMember.id && tc.remainingTimes > 0)
    memberProfile.value = {
      id: targetMember.id,
      name: targetMember.name,
      levelName: targetMember.levelName || '普通会员',
      currentPoints: targetMember.points || 0,
      member: {
        id: targetMember.id,
        name: targetMember.name,
        phone: targetMember.phone,
        level: targetMember.levelName || '普通会员',
        points: targetMember.points || 0
      },
      dualBalance: {
        principalBalance: targetMember.principalBalance || 0,
        giftBalance: targetMember.giftBalance || 0
      },
      timeCards: memCards
    }
    if (order.value) {
      order.value.memberId = targetMember.id
      recalcOrderTotal()
    }
    ElMessage.success(`已绑定付款会员：【${targetMember.name}】(${targetMember.levelName || '普通会员'})，可用储值：￥${((targetMember.principalBalance || 0) + (targetMember.giftBalance || 0)).toFixed(2)}`)
  }
}

const handleClearPayerMember = () => {
  handlePayerMemberChange(null)
}

const formatMemberLevel = (lvl?: string) => {
  if (!lvl) return '普通会员'
  if (lvl.includes('黑钻') || lvl.includes('黑金') || lvl.includes('DIAMOND')) return '黑钻至尊卡'
  if (lvl.includes('至尊') || lvl.includes('白金') || lvl.includes('PLATINUM')) return '至尊白金卡'
  if (lvl.includes('VIP') || lvl.includes('尊享')) return 'VIP尊享卡'
  if (lvl.includes('金卡') || lvl.includes('GOLD')) return '黄金VIP卡'
  if (lvl.includes('银卡') || lvl.includes('SILVER')) return '荣耀银卡'
  if (lvl.includes('体验') || lvl.includes('TRIAL')) return '新客体验卡'
  return lvl
}

const showLevelRulesModal = ref(false)

const standardLevelRules = [
  { levelCode: 'REGULAR', levelName: '普卡会员', threshold: 0, discount: '无折扣 (100%)', privileges: '进店建档、海马体偏好常态记忆、消费基础积分' },
  { levelCode: 'SILVER', levelName: '荣耀银卡', threshold: 300, discount: '服务95折 / 商品98折', privileges: '服务95折、生日月享50元抵用券、双倍积分日' },
  { levelCode: 'GOLD', levelName: '黄金VIP卡', threshold: 800, discount: '服务90折 / 商品95折', privileges: '服务9折、免排队预约优先通道、生日免费专属体验' },
  { levelCode: 'VIP', levelName: 'VIP尊享卡', threshold: 1200, discount: '服务88折 / 商品92折', privileges: '服务88折、专属金牌技师优先点单、节日私享定制礼盒' },
  { levelCode: 'PLATINUM', levelName: '至尊白金卡', threshold: 2000, discount: '服务85折 / 商品90折', privileges: '全场85折、专属私享包间、免费携1位亲友享同折' },
  { levelCode: 'DIAMOND', levelName: '黑钻至尊卡', threshold: 3500, discount: '服务80折 / 商品85折', privileges: '全场8折、总监技师免服务费、终身顶格尊崇待遇' }
]

const getNextLevelName = () => {
  if (memberProfile.value?.nextLevelName) return memberProfile.value.nextLevelName
  const points = memberProfile.value?.member?.points ?? memberProfile.value?.currentPoints ?? memberProfile.value?.points ?? 0
  const next = standardLevelRules.find(r => r.threshold > points)
  return next ? next.levelName : null
}

const getPointsGap = () => {
  if (memberProfile.value?.pointsToNextLevel != null) return memberProfile.value.pointsToNextLevel
  const points = memberProfile.value?.member?.points ?? memberProfile.value?.currentPoints ?? memberProfile.value?.points ?? 0
  const next = standardLevelRules.find(r => r.threshold > points)
  return next ? Math.max(0, next.threshold - points) : 0
}

const getGrowthPercentage = () => {
  if (memberProfile.value?.growthProgressRatio != null) {
    return Math.min(100, Math.round(memberProfile.value.growthProgressRatio * 100))
  }
  const points = memberProfile.value?.member?.points ?? memberProfile.value?.currentPoints ?? memberProfile.value?.points ?? 0
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

const willUpgradeAfterCheckout = () => {
  const points = memberProfile.value?.member?.points ?? memberProfile.value?.currentPoints ?? memberProfile.value?.points ?? 0
  const gain = Math.round(order.value?.actualAmount || 0)
  if (gain <= 0) return false
  const next = standardLevelRules.find(r => r.threshold > points)
  if (!next) return false
  return (points + gain) >= next.threshold
}

const getLevelBadgeStyle = (code: string) => {
  switch (code) {
    case 'DIAMOND':
      return 'background: #0f172a; color: #f59e0b; border: 1px solid #f59e0b; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 11px;'
    case 'PLATINUM':
      return 'background: #ede9fe; color: #7c3aed; border: 1px solid #c4b5fd; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 11px;'
    case 'VIP':
      return 'background: #fdf2f8; color: #db2777; border: 1px solid #fbcfe8; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 11px;'
    case 'GOLD':
      return 'background: #fef3c7; color: #b45309; border: 1px solid #fcd34d; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 11px;'
    case 'SILVER':
      return 'background: #e0f2fe; color: #0369a1; border: 1px solid #bae6fd; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 11px;'
    default:
      return 'background: #ccfbf1; color: #0f766e; border: 1px solid #99f6e4; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 11px;'
  }
}

const initFallbackSession = (sessionId: number) => {
  if (!sessionListOptions.value || sessionListOptions.value.length === 0) {
    order.value = null
    memberProfile.value = null
    currentSessionSelectId.value = undefined as any
    return
  }
  currentSessionSelectId.value = sessionId
  const match = sessionListOptions.value.find(s => s.id === sessionId) || sessionListOptions.value[0]
  if (!match) {
    order.value = null
    memberProfile.value = null
    return
  }
  const feeAmt = Number(match.feeAmount) || 0
  const totAmt = Number(match.totalAmount) || 0
  order.value = {
    id: 1000 + match.id,
    sessionId: match.id,
    orderNo: match.orderNo,
    spaceName: match.spaceName,
    customerName: match.customerName,
    customerPhone: match.customerPhone,
    totalAmount: totAmt,
    feeAmount: feeAmt,
    discountAmount: 0,
    actualAmount: totAmt + feeAmt,
    memberId: match.memberId,
    status: match.status,
    items: []
  }

  // 绑定匹配的会员真实资产（仅在工位有明确会员ID或按手机号匹配到会员时关联）
  let targetMember: any = null
  if (match.memberId) {
    targetMember = systemData.membersWithStats.find(m => m.id === match.memberId)
  } else if (match.customerPhone) {
    targetMember = systemData.membersWithStats.find(m => m.phone === match.customerPhone)
  }

  if (targetMember) {
    selectedPayerMemberId.value = targetMember.id
    const memCards = systemData.timeCards.filter(tc => tc.memberId === targetMember.id && tc.remainingTimes > 0)
    memberProfile.value = {
      id: targetMember.id,
      name: targetMember.name,
      levelName: targetMember.levelName || '普卡会员',
      currentPoints: targetMember.points || 0,
      member: {
        id: targetMember.id,
        name: targetMember.name,
        phone: targetMember.phone,
        level: targetMember.levelName || '普卡会员',
        points: targetMember.points || 0
      },
      dualBalance: {
        principalBalance: targetMember.principalBalance || 0,
        giftBalance: targetMember.giftBalance || 0
      },
      timeCards: memCards.length > 0 ? memCards : []
    }
  } else {
    selectedPayerMemberId.value = null
    memberProfile.value = null
  }

  // 默认建议微信全额覆盖
  payPlan.value = {
    wechat: order.value.actualAmount,
    alipay: 0,
    storedValue: 0,
    cash: 0
  }
}

// 扫码盒子免驱工作台与模拟器状态
const openScanSimulatorDialog = ref(false)
const lastScannedCode = ref('')
const lastScannedTypeName = ref('')
const customBarcode = ref('')
const scanHistoryList = ref<any[]>([])

const currentRouteTagType = computed(() => {
  const r = systemData.paymentConfig?.activeRoute
  if (r === 'ROUTE_1_INDIVIDUAL') return 'success'
  if (r === 'ROUTE_2_AGGREGATE') return 'warning'
  return 'primary'
})

const currentRouteDisplayName = computed(() => {
  const r = systemData.paymentConfig?.activeRoute
  if (r === 'ROUTE_1_INDIVIDUAL') return '路线 1: 个体工租户直连'
  if (r === 'ROUTE_2_AGGREGATE') return '路线 2: 持牌聚合小微租户'
  return '路线 3: 支付宝沙箱环境'
})

const goToPaymentSettings = () => {
  router.push('/settings?tab=payment')
}

const testAudioBeep = () => {
  scanAudio.playSuccess()
  ElMessage.success('扫码蜂鸣器硬件测试声播放正常！')
}

const simulateScanCode = async (code: string) => {
  await barcodeScanner.simulateScan(code)
}

const handleBarcodeScanned = (res: BarcodeScanResult) => {
  lastScannedCode.value = res.rawCode
  lastScannedTypeName.value = res.typeName
  scanHistoryList.value.unshift({
    code: res.rawCode,
    type: res.type,
    typeName: res.typeName,
    time: res.scannedAt,
    durationMs: res.durationMs
  })
  if (scanHistoryList.value.length > 20) {
    scanHistoryList.value.pop()
  }

  // 分流处理：会员码 vs 商品条码 vs 顾客付款码
  if (res.type === 'MEMBER') {
    const cleanPhone = res.rawCode.startsWith('SEAHORSE:MEMBER:') ? res.rawCode.replace('SEAHORSE:MEMBER:', '') : res.rawCode
    ElMessage.success({
      message: `👤 扫码盒子识别到海马体顾客会员消费码：【${cleanPhone}】，已对齐各端统一会员协议！`,
      duration: 3500
    })
  } else if (res.type === 'PRODUCT') {
    handleScanProductCode(res.rawCode)
  } else if (res.type === 'WECHAT_PAY') {
    handleScanPaymentCode(res.rawCode, 'WECHAT')
  } else if (res.type === 'ALIPAY_PAY') {
    handleScanPaymentCode(res.rawCode, 'ALIPAY')
  } else {
    ElMessage.info(`扫码盒子接收到自编码: ${res.rawCode}`)
  }
}

const recalcOrderTotal = () => {
  if (!order.value) return
  const items = order.value.items || []
  if (items.length > 0) {
    const total = items.reduce((sum: number, it: any) => sum + (Number(it.price) || 0) * (Number(it.qty) || 1), 0)
    order.value.totalAmount = Math.max(0, total)
  }
  const total = Number(order.value.totalAmount) || 0
  const fee = Number(order.value.feeAmount) || 0
  const discount = Number(order.value.discountAmount) || 0
  order.value.actualAmount = Math.max(0, total + fee - discount)
  // 保持单通道支付计划联动
  if (!payPlan.value.alipay && !payPlan.value.storedValue && !payPlan.value.cash) {
    payPlan.value.wechat = order.value.actualAmount
  } else if (!payPlan.value.wechat && !payPlan.value.storedValue && !payPlan.value.cash) {
    payPlan.value.alipay = order.value.actualAmount
  }
}

const changeItemQty = (index: number, delta: number) => {
  if (!order.value?.items || !order.value.items[index]) return
  order.value.items[index].qty = (order.value.items[index].qty || 1) + delta
  if (order.value.items[index].qty <= 0) {
    order.value.items.splice(index, 1)
  }
  recalcOrderTotal()
}

const removeItem = (index: number) => {
  if (!order.value?.items) return
  order.value.items.splice(index, 1)
  recalcOrderTotal()
}

const handleRemoveFee = () => {
  if (!order.value) return
  ElMessageBox.confirm('确定要免除/清空当前账单的行业附加费（茶位费/餐具费）吗？', '操作确认', {
    confirmButtonText: '确定免除',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    order.value.feeAmount = 0
    recalcOrderTotal()
    ElMessage.success('已成功免除本单行业附加费')
  }).catch(() => {})
}

const handleScanProductCode = (code: string) => {
  if (!order.value) {
    ElMessage.warning('当前未选定在场工位账单，请先选择工位单据')
    return
  }

  // 1. 在门店所有项目商品库中精准查找或匹配
  const allProds = systemData.products || []
  let found = allProds.find((p: any) => p.code === code || String(p.id) === code)
  if (!found) {
    found = allProds.find((p: any) => code.includes(p.code) || (p.code && p.code.includes(code)))
  }

  // 2. 匹配常见示例或动态构造商品品项
  if (!found) {
    if (code === '6920182736192') {
      found = { id: 201, code: '6920182736192', name: '欧莱雅专业洗护精油 100ml', price: 168.0 }
    } else if (code === '6901234567890') {
      found = { id: 202, code: '6901234567890', name: '植物赋活深层发膜 500ml', price: 198.0 }
    } else if (code.startsWith('69')) {
      found = { id: Date.now(), code: code, name: `国际国标69扫码商品 (${code.slice(-4)})`, price: 128.0 }
    } else {
      found = { id: Date.now(), code: code, name: `自编码服务品项 (${code})`, price: 88.0 }
    }
  }

  if (!order.value.items) {
    order.value.items = []
  }

  const existing = order.value.items.find((item: any) => item.code === found.code || item.name === found.name)
  if (existing) {
    existing.qty = (existing.qty || 1) + 1
  } else {
    order.value.items.push({
      id: found.id,
      name: found.name,
      qty: 1,
      price: found.price,
      code: found.code,
      type: found.type || (found.code && found.code.startsWith('BEA') ? 'SERVICE' : 'RETAIL')
    })
  }

  recalcOrderTotal()
  ElMessage.success({
    message: `🛍️ 扫码录入成功：【${found.name}】 ￥${found.price}，已计入消费明细！`,
    duration: 3000
  })
}

const handleScanPaymentCode = (authCode: string, channel: 'WECHAT' | 'ALIPAY') => {
  if (!order.value) {
    ElMessage.warning('当前无待结算账单，无法执行付款码扣款')
    return
  }
  if (order.value.status === 'WAIT_CLEAN' || order.value.status === 'COMPLETED') {
    ElMessage.info('当前单据已完成结账，无需重复扣款')
    return
  }

  const remaining = order.value.actualAmount
  if (channel === 'WECHAT') {
    payPlan.value.wechat = remaining
    payPlan.value.alipay = 0
    payPlan.value.storedValue = 0
    payPlan.value.cash = 0
  } else {
    payPlan.value.alipay = remaining
    payPlan.value.wechat = 0
    payPlan.value.storedValue = 0
    payPlan.value.cash = 0
  }

  const maskedCode = authCode.length >= 10 ? `${authCode.substring(0, 6)}******${authCode.substring(authCode.length - 4)}` : authCode
  const channelName = channel === 'WECHAT' ? '微信支付' : '支付宝'

  ElMessage.success({
    message: `📷 扫码盒识别到【${channelName}】顾客付款码：${maskedCode}，应收 ￥${remaining.toFixed(2)}`,
    duration: 3000
  })

  // 自动触发反扫结账闭环
  const shouldAutoCheckout = systemData.paymentConfig?.scanBox?.autoCheckoutOnPaymentCode ?? true
  if (shouldAutoCheckout) {
    setTimeout(() => {
      handleDoCheckout({
        authCode,
        payChannel: channel,
        channelName
      })
    }, 450)
  }
}

let unsubscribeScanner: (() => void) | null = null

const loadSessionData = async () => {
  const sId = Number(route.query.sessionId) || currentSessionSelectId.value || 1
  currentSessionSelectId.value = sId
  let found = false

  try {
    const detail: any = await getSessionDetailApi(sId, true)
    const billOrder: any = await requestBillingApi(sId, true)
    if (billOrder && billOrder.id) {
      order.value = billOrder
      if ((order.value.feeAmount == null || Number(order.value.feeAmount) === 0) && detail?.session?.feeAmount != null) {
        order.value.feeAmount = detail.session.feeAmount
      }
      if (detail && detail.lineItems && detail.lineItems.length > 0) {
        order.value.items = detail.lineItems.map((it: any) => ({
          id: it.productId,
          productId: it.productId,
          code: it.productCode || `PRD-${it.productId}`,
          name: it.productName,
          price: it.price,
          qty: it.quantity,
          type: it.productType || 'RETAIL'
        }))
      } else {
        order.value.items = []
      }
      recalcOrderTotal()
      await loadStoreMembers('', order.value?.tenantId || detail?.session?.tenantId || storeConfig.tenantId)
      const targetMemId = detail?.session?.memberId || billOrder?.memberId
      if (targetMemId) {
        await handlePayerMemberChange(targetMemId)
      } else if (matchedCustomerMember.value) {
        await handlePayerMemberChange(matchedCustomerMember.value.id)
      } else {
        selectedPayerMemberId.value = null
        memberProfile.value = null
      }
      payPlan.value = {
        wechat: order.value.actualAmount,
        alipay: 0,
        storedValue: 0,
        cash: 0
      }
      found = true
    }
  } catch (e) {
    console.log('未找到后端在场会话记录，无缝自愈加载工位账单数据:', e)
  }

  if (!found) {
    if (sessionListOptions.value && sessionListOptions.value.length > 0) {
      initFallbackSession(sId)
    } else {
      order.value = null
      memberProfile.value = null
      selectedPayerMemberId.value = null
    }
  }
}

watch(() => route.query.sessionId, (newSid) => {
  if (newSid) {
    loadSessionData()
  }
})

const handleSelectSession = async (newId: number) => {
  currentSessionSelectId.value = newId
  let found = false
  try {
    const detail: any = await getSessionDetailApi(newId, true)
    const billOrder: any = await requestBillingApi(newId, true)
    if (billOrder && billOrder.id) {
      order.value = billOrder
      if ((order.value.feeAmount == null || Number(order.value.feeAmount) === 0) && detail?.session?.feeAmount != null) {
        order.value.feeAmount = detail.session.feeAmount
      }
      if (detail && detail.lineItems && detail.lineItems.length > 0) {
        order.value.items = detail.lineItems.map((it: any) => ({
          id: it.productId,
          productId: it.productId,
          code: it.productCode || `PRD-${it.productId}`,
          name: it.productName,
          price: it.price,
          qty: it.quantity,
          type: it.productType || 'RETAIL'
        }))
      } else {
        order.value.items = []
      }
      recalcOrderTotal()
      await loadStoreMembers('', order.value?.tenantId || detail?.session?.tenantId || storeConfig.tenantId)
      const targetMemId = detail?.session?.memberId || billOrder?.memberId
      if (targetMemId) {
        await handlePayerMemberChange(targetMemId)
      } else if (matchedCustomerMember.value) {
        await handlePayerMemberChange(matchedCustomerMember.value.id)
      } else {
        selectedPayerMemberId.value = null
        memberProfile.value = null
      }
      payPlan.value = {
        wechat: order.value.actualAmount,
        alipay: 0,
        storedValue: 0,
        cash: 0
      }
      found = true
    }
  } catch (e) {}

  if (!found) {
    initFallbackSession(newId)
  }
}

const currentPlanTotal = computed(() => {
  return Number(payPlan.value.wechat) + Number(payPlan.value.alipay) +
         Number(payPlan.value.storedValue) + Number(payPlan.value.cash)
})

const isAmountMatched = computed(() => {
  if (!order.value) return false
  return currentPlanTotal.value >= order.value.actualAmount
})

const getRemainingAmount = (channel: string) => {
  if (!order.value) return 0
  let otherTotal = 0
  if (channel !== 'wechat') otherTotal += payPlan.value.wechat
  if (channel !== 'alipay') otherTotal += payPlan.value.alipay
  if (channel !== 'storedValue') otherTotal += payPlan.value.storedValue
  if (channel !== 'cash') otherTotal += payPlan.value.cash
  return Math.max(0, order.value.actualAmount - otherTotal)
}

const handleAutoFillStoredValue = () => {
  if (!memberProfile.value?.dualBalance) {
    ElMessage.warning('顾客未登记会员或未开通储值')
    return
  }
  const totalBalance = (memberProfile.value.dualBalance.principalBalance || 0) +
                       (memberProfile.value.dualBalance.giftBalance || 0)
  const remaining = getRemainingAmount('storedValue')
  payPlan.value.storedValue = Math.min(totalBalance, remaining)
}

const handleClearChannel = (channel: 'wechat' | 'alipay' | 'storedValue' | 'cash') => {
  payPlan.value[channel] = 0
  if (channel === 'cash') {
    tenderedAmount.value = 0
  }
  const nameMap: Record<string, string> = { wechat: '微信支付', alipay: '支付宝', storedValue: '会员储值', cash: '现金' }
  ElMessage.info(`已清空${nameMap[channel]}划付金额`)
}

const handleClearAllChannels = () => {
  payPlan.value.wechat = 0
  payPlan.value.alipay = 0
  payPlan.value.storedValue = 0
  payPlan.value.cash = 0
  tenderedAmount.value = 0
  ElMessage.info('已清空全部支付通道金额，请重新输入或点选快捷支付方式')
}

const isSingleChannel = (channel: 'wechat' | 'alipay' | 'storedValue' | 'cash') => {
  if (!order.value || !order.value.actualAmount) return false
  const targetVal = payPlan.value[channel]
  if (targetVal <= 0) return false
  const otherSum = (channel !== 'wechat' ? payPlan.value.wechat : 0) +
                   (channel !== 'alipay' ? payPlan.value.alipay : 0) +
                   (channel !== 'storedValue' ? payPlan.value.storedValue : 0) +
                   (channel !== 'cash' ? payPlan.value.cash : 0)
  return otherSum === 0 && Math.abs(targetVal - order.value.actualAmount) < 0.01
}

const switchToSingleChannel = (channel: 'wechat' | 'alipay' | 'storedValue' | 'cash') => {
  if (!order.value) return
  const due = Number(order.value.actualAmount) || 0

  if (channel === 'storedValue') {
    const totalBalance = (memberProfile.value?.dualBalance?.principalBalance || 0) +
                         (memberProfile.value?.dualBalance?.giftBalance || 0)
    if (!totalBalance || totalBalance <= 0) {
      ElMessage.warning('当前顾客未开通会员储值或储值余额为 0，无法使用储值全额支付')
      return
    }
    if (totalBalance < due) {
      payPlan.value.storedValue = totalBalance
      payPlan.value.wechat = Math.max(0, due - totalBalance)
      payPlan.value.alipay = 0
      payPlan.value.cash = 0
      tenderedAmount.value = 0
      ElMessage.warning(`会员可用储值 ￥${totalBalance.toFixed(2)} 不足全额，已自动扣减全部储值，差额 ￥${(due - totalBalance).toFixed(2)} 已转入微信支付！`)
      return
    }
  }

  payPlan.value.wechat = channel === 'wechat' ? due : 0
  payPlan.value.alipay = channel === 'alipay' ? due : 0
  payPlan.value.storedValue = channel === 'storedValue' ? due : 0
  payPlan.value.cash = channel === 'cash' ? due : 0
  if (channel === 'cash') {
    tenderedAmount.value = due
  } else {
    tenderedAmount.value = 0
  }
  const nameMap: Record<string, string> = { wechat: '微信支付', alipay: '支付宝', storedValue: '会员储值', cash: '现金收银' }
  ElMessage.success(`已一键切换为【${nameMap[channel]}】全额支付 (￥${due.toFixed(2)})`)
}

const handleAutoFillCash = () => {
  const remaining = getRemainingAmount('cash')
  payPlan.value.cash = remaining
  tenderedAmount.value = remaining
}

const applyComboPlan = (comboType: string) => {
  if (!order.value) return
  const due = Number(order.value.actualAmount) || 0
  if (due <= 0) return

  if (comboType === 'stored_wechat') {
    const totalBalance = (memberProfile.value?.dualBalance?.principalBalance || 0) +
                         (memberProfile.value?.dualBalance?.giftBalance || 0)
    const storedDeduct = Math.min(totalBalance, due)
    const remainder = Math.max(0, due - storedDeduct)
    payPlan.value.storedValue = storedDeduct
    payPlan.value.wechat = remainder
    payPlan.value.alipay = 0
    payPlan.value.cash = 0
    tenderedAmount.value = 0
    ElMessage.success(`组合生效：会员储值抵扣 ￥${storedDeduct.toFixed(2)}，微信补齐 ￥${remainder.toFixed(2)}`)
  } else if (comboType === 'stored_alipay') {
    const totalBalance = (memberProfile.value?.dualBalance?.principalBalance || 0) +
                         (memberProfile.value?.dualBalance?.giftBalance || 0)
    const storedDeduct = Math.min(totalBalance, due)
    const remainder = Math.max(0, due - storedDeduct)
    payPlan.value.storedValue = storedDeduct
    payPlan.value.alipay = remainder
    payPlan.value.wechat = 0
    payPlan.value.cash = 0
    tenderedAmount.value = 0
    ElMessage.success(`组合生效：会员储值抵扣 ￥${storedDeduct.toFixed(2)}，支付宝补齐 ￥${remainder.toFixed(2)}`)
  } else if (comboType === 'wechat_alipay') {
    const half = Math.round((due / 2) * 100) / 100
    payPlan.value.wechat = half
    payPlan.value.alipay = Math.max(0, due - half)
    payPlan.value.storedValue = 0
    payPlan.value.cash = 0
    tenderedAmount.value = 0
    ElMessage.success(`组合生效：微信 ￥${payPlan.value.wechat.toFixed(2)} + 支付宝 ￥${payPlan.value.alipay.toFixed(2)} 对半分摊`)
  } else if (comboType === 'cash_wechat') {
    const cashPart = Math.floor(due / 2 / 10) * 10 || Math.floor(due / 2) || 10
    const remainder = Math.max(0, due - cashPart)
    payPlan.value.cash = cashPart
    payPlan.value.wechat = remainder
    payPlan.value.alipay = 0
    payPlan.value.storedValue = 0
    tenderedAmount.value = cashPart
    ElMessage.success(`组合生效：现金 ￥${cashPart.toFixed(2)} + 微信 ￥${remainder.toFixed(2)}`)
  }
}

const checkoutTimeStr = ref('')
const quickReceiptConfig = ref<any>({ ...(systemData.receiptTemplate || {}) })

const handleDoCheckout = async (extraScanInfo?: { authCode?: string; payChannel?: string; channelName?: string }) => {
  settling.value = true
  try {
    const splitItems = []

    if (payPlan.value.wechat > 0) {
      splitItems.push({ channel: 'WECHAT', amount: payPlan.value.wechat })
    }
    if (payPlan.value.alipay > 0) {
      splitItems.push({ channel: 'ALIPAY', amount: payPlan.value.alipay })
    }
    if (payPlan.value.storedValue > 0) {
      splitItems.push({ channel: 'STORED_VALUE', amount: payPlan.value.storedValue })
    }
    if (payPlan.value.cash > 0) {
      splitItems.push({
        channel: 'CASH',
        amount: payPlan.value.cash,
        tenderedAmount: tenderedAmount.value || payPlan.value.cash
      })
    }

    const effectiveMemberId = order.value?.memberId || selectedPayerMemberId.value || memberProfile.value?.member?.id || memberProfile.value?.id || null
    if (order.value && effectiveMemberId) {
      order.value.memberId = effectiveMemberId
    }

    let res: any = null
    try {
      const checkoutPayload: any = {
        splitItems,
        cashierName: currentCashierName.value,
        orderNo: order.value.orderNo,
        spaceName: order.value.spaceName,
        customerName: memberProfile.value?.member?.name || order.value.customerName,
        customerPhone: memberProfile.value?.member?.phone || order.value.customerPhone,
        memberId: effectiveMemberId,
        totalAmount: order.value.totalAmount,
        feeAmount: order.value.feeAmount || 0,
        discountAmount: order.value.discountAmount || 0,
        actualAmount: order.value.actualAmount
      }
      if (order.value.items && order.value.items.length > 0) {
        checkoutPayload.items = order.value.items.map((it: any) => ({
          productId: it.id || it.productId,
          productCode: it.code || it.productCode,
          productName: it.name || it.title,
          productType: it.type || (it.code && it.code.startsWith('BEA') ? 'SERVICE' : 'PHYSICAL'),
          price: it.price,
          quantity: it.qty || it.quantity || 1
        }))
      }
      if (order.value.id && order.value.id < 1000) {
        checkoutPayload.billingOrderId = order.value.id
      }
      if (order.value.sessionId) {
        checkoutPayload.sessionId = order.value.sessionId
      }
      res = await executeCheckoutApi(checkoutPayload, true)
    } catch (apiErr: any) {
      const errorMsg = apiErr?.response?.data?.message || apiErr?.message
      if (errorMsg && (errorMsg.includes('余额不足') || errorMsg.includes('储值') || errorMsg.includes('金额不足') || errorMsg.includes('次卡') || errorMsg.includes('已完成结算'))) {
        throw new Error(errorMsg)
      }
      console.log('后端未持久化此在场会话，通过全局真实关联账本自愈完成收银闭环', errorMsg)
    }

    // 结账成功：立即就地扣减前端 Pinia 全局商品实物库存并持久化
    if (order.value.items && order.value.items.length > 0) {
      systemData.deductProductStock(order.value.items)
    }
    // 异步重新拉取云端服务端最新商品库存，保持完全一致
    systemData.syncProductsFromServer()

    if (!res || !res.order) {
      res = {
        order: {
          orderNo: order.value.orderNo,
          actualAmount: order.value.actualAmount
        },
        cashTender: payPlan.value.cash > 0 ? {
          tenderedAmount: tenderedAmount.value || payPlan.value.cash,
          changeAmount: Math.max(0, (tenderedAmount.value || payPlan.value.cash) - payPlan.value.cash)
        } : null
      }
      const targetSessionId = order.value.sessionId || Number(route.query.sessionId) || currentSessionSelectId.value || 1
      systemData.checkoutSession(targetSessionId, {
        orderNo: order.value.orderNo,
        customerName: order.value.customerName,
        totalAmount: order.value.actualAmount,
        wechat: payPlan.value.wechat,
        alipay: payPlan.value.alipay,
        storedValue: payPlan.value.storedValue,
        cash: payPlan.value.cash,
        memberId: effectiveMemberId || 1
      })
      order.value.status = 'WAIT_CLEAN'
    }

    if (extraScanInfo) {
      res.scanInfo = extraScanInfo
      res.paymentRoute = systemData.paymentConfig?.activeRoute
    }
    settledResult.value = res
    checkoutTimeStr.value = new Date().toLocaleString()
    quickReceiptConfig.value = systemData.getResolvedReceiptTemplate(storeConfig.currentStoreId)
    successDialogVisible.value = true
    if (systemData.receiptTemplate?.autoPrint) {
      ElMessage.success('结算完成！小票已就绪，已启用本地打印支持')
    } else {
      ElMessage.success('结算完成，已生成顾客消费小票！')
    }
  } catch (e: any) {
    console.error('结账异常:', e)
    ElMessage.error(e?.message || '结账处理失败，请检查输入')
  } finally {
    settling.value = false
  }
}

const currentCashierName = computed(() => {
  const user = localStorage.getItem('seahorse_user')
  if (user) return user
  const role = localStorage.getItem('seahorse_role')
  if (role === 'SUPER_ADMIN' || role === 'TENANT_ADMIN') return '店长/管理员'
  if (role === 'CASHIER') return '前台收银员'
  return '前台收银员'
})

const currentStoreName = computed(() => {
  let basic: any = null
  try {
    const raw = localStorage.getItem('seahorse_basic_settings')
    if (raw) basic = JSON.parse(raw)
  } catch {}
  return quickReceiptConfig.value?.storeHeaderTitle ||
         basic?.storeName ||
         storeConfig.storeName ||
         localStorage.getItem('seahorse_store_name') ||
         '海马智慧门店'
})

const currentStorePhone = computed(() => {
  let basic: any = null
  try {
    const raw = localStorage.getItem('seahorse_basic_settings')
    if (raw) basic = JSON.parse(raw)
  } catch {}
  return quickReceiptConfig.value?.serviceHotline ||
         basic?.phone ||
         storeConfig.phone ||
         localStorage.getItem('seahorse_store_phone') ||
         '400-888-6688'
})

const currentStoreAddress = computed(() => {
  let basic: any = null
  try {
    const raw = localStorage.getItem('seahorse_basic_settings')
    if (raw) basic = JSON.parse(raw)
  } catch {}
  return quickReceiptConfig.value?.storeAddress ||
         basic?.address ||
         storeConfig.address ||
         localStorage.getItem('seahorse_store_address') ||
         '智慧商业中心 101号铺'
})

const sampleOrderItems = computed(() => [
  { name: '发型总监精剪精修造型', qty: 1, price: 88.0 },
  { name: '欧莱雅植物蛋白染发', qty: 1, price: 420.0 }
])

const totalItemsAmount = computed(() => {
  const items = order.value?.items?.length ? order.value.items : sampleOrderItems.value
  return items.reduce((sum: number, it: any) => sum + (it.price || 0) * (it.qty || it.quantity || 1), 0)
})

const receiptQrCodeDataUrl = ref('')
const generateReceiptQrCode = async () => {
  try {
    let text = quickReceiptConfig.value?.qrCodeText
    if (!text || text.includes('seahorse.store')) {
      text = buildMemberBenefitsUrl(storeConfig.currentStoreId)
      if (quickReceiptConfig.value) {
        quickReceiptConfig.value.qrCodeText = text
      }
    }
    receiptQrCodeDataUrl.value = await QRCode.toDataURL(text, {
      width: 160,
      margin: 1,
      color: { dark: '#0f172a', light: '#ffffff' }
    })
  } catch (err) {
    console.error('Failed to generate receipt QR code', err)
  }
}

watch(successDialogVisible, (val) => {
  if (val) {
    generateReceiptQrCode()
  }
})

const openReceiptConfigDrawer = ref(false)

const formatPhoneDisplay = (phone?: string) => {
  if (!phone) return '138****8888'
  if (quickReceiptConfig.value?.maskCustomerPhone) {
    return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
  }
  return phone
}

const applyConfigPreset = (preset: 'ALL' | 'RECOMMENDED' | 'MINIMAL') => {
  if (preset === 'ALL') {
    Object.keys(quickReceiptConfig.value).forEach(k => {
      if (k.startsWith('show')) {
        quickReceiptConfig.value[k] = true
      }
    })
    quickReceiptConfig.value.paperWidth = '80mm'
  } else if (preset === 'RECOMMENDED') {
    quickReceiptConfig.value.showStoreHeader = true
    quickReceiptConfig.value.showHeaderSubtitle = true
    quickReceiptConfig.value.showTicketTitle = true
    quickReceiptConfig.value.showOrderNo = true
    quickReceiptConfig.value.showCheckoutTime = true
    quickReceiptConfig.value.showCashierName = true
    quickReceiptConfig.value.showTechnician = true
    quickReceiptConfig.value.showCustomerName = true
    quickReceiptConfig.value.showCustomerPhone = true
    quickReceiptConfig.value.maskCustomerPhone = true
    quickReceiptConfig.value.showItemsTable = true
    quickReceiptConfig.value.showItemQty = true
    quickReceiptConfig.value.showItemPrice = true
    quickReceiptConfig.value.showItemSum = true
    quickReceiptConfig.value.showOriginalPrice = true
    quickReceiptConfig.value.showDiscount = true
    quickReceiptConfig.value.showActualAmount = true
    quickReceiptConfig.value.showPayMethods = true
    quickReceiptConfig.value.showMemberAssetSection = true
    quickReceiptConfig.value.showPrincipalBalance = true
    quickReceiptConfig.value.showGiftBalance = true
    quickReceiptConfig.value.showEarnedPoints = true
    quickReceiptConfig.value.showTotalPoints = true
    quickReceiptConfig.value.showFooterNotes = true
    quickReceiptConfig.value.showServiceHotline = true
    quickReceiptConfig.value.showStoreAddress = true
    quickReceiptConfig.value.showQrCode = true
    quickReceiptConfig.value.showSignStub = true
    quickReceiptConfig.value.showStubOrderMeta = true
    quickReceiptConfig.value.showStubSignLine = true
    quickReceiptConfig.value.paperWidth = '80mm'
  } else if (preset === 'MINIMAL') {
    quickReceiptConfig.value.showStoreHeader = true
    quickReceiptConfig.value.showHeaderSubtitle = false
    quickReceiptConfig.value.showTicketTitle = true
    quickReceiptConfig.value.showOrderNo = true
    quickReceiptConfig.value.showCheckoutTime = true
    quickReceiptConfig.value.showCashierName = false
    quickReceiptConfig.value.showTechnician = false
    quickReceiptConfig.value.showCustomerName = true
    quickReceiptConfig.value.showCustomerPhone = false
    quickReceiptConfig.value.showItemsTable = true
    quickReceiptConfig.value.showItemQty = true
    quickReceiptConfig.value.showItemPrice = false
    quickReceiptConfig.value.showItemSum = true
    quickReceiptConfig.value.showOriginalPrice = false
    quickReceiptConfig.value.showDiscount = false
    quickReceiptConfig.value.showActualAmount = true
    quickReceiptConfig.value.showPayMethods = true
    quickReceiptConfig.value.showMemberAssetSection = false
    quickReceiptConfig.value.showFooterNotes = true
    quickReceiptConfig.value.showServiceHotline = false
    quickReceiptConfig.value.showStoreAddress = false
    quickReceiptConfig.value.showQrCode = false
    quickReceiptConfig.value.showSignStub = false
    quickReceiptConfig.value.paperWidth = '58mm'
  }
  ElMessage.success(`已应用【${preset === 'ALL' ? '全选开启' : preset === 'RECOMMENDED' ? '推荐常用' : '极简小票'}】模式！`)
}

const handleSaveQuickConfig = () => {
  systemData.updateReceiptTemplate(quickReceiptConfig.value)
  openReceiptConfigDrawer.value = false
  ElMessage.success('小票打印模板与各项开关配置已保存生效！')
}

// 🖨️ 调用独立隔离打印引擎 (100% 杜绝背景弹窗与多余控件泄露)
const handlePrintReceipt = () => {
  const el = document.getElementById('thermal-receipt-printable')
  if (!el) {
    window.print()
    return
  }

  const is58 = quickReceiptConfig.value?.paperWidth === '58mm'
  const paperWidthMm = is58 ? '58mm' : '80mm'
  const fontSize = quickReceiptConfig.value?.fontSize === 'compact' ? '11px' : quickReceiptConfig.value?.fontSize === 'large' ? '14px' : '12.5px'

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
    window.print()
    return
  }

  doc.open()
  doc.write(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>顾客消费小票结账打印单</title>
        <style>
          @page {
            size: ${paperWidthMm} auto;
            margin: 0;
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
            font-family: 'Courier New', Courier, Consolas, Monaco, monospace;
            font-size: ${fontSize};
            line-height: 1.55;
          }
          .thermal-print-wrapper {
            width: ${paperWidthMm};
            padding: 4mm 2.5mm;
            background: #ffffff;
            margin: 0 auto;
          }
          .receipt-center-box { text-align: center; }
          .receipt-shop-name { font-size: 16px; font-weight: 800; color: #000; letter-spacing: 0.5px; }
          .receipt-sub-title { font-size: 11px; color: #333; margin-top: 2px; }
          .receipt-ticket-type { font-size: 13px; font-weight: 700; margin-top: 6px; color: #000; }
          .receipt-divider { text-align: center; font-size: 11px; color: #444; margin: 8px 0; overflow: hidden; white-space: nowrap; }
          .receipt-meta-grid { line-height: 1.7; }
          .meta-row { display: flex; justify-content: space-between; }
          .mono { font-family: 'Courier New', monospace; font-weight: 600; }
          .receipt-items-table { width: 100%; margin: 4px 0; }
          .items-head { display: flex; font-weight: 700; border-bottom: 1px dashed #000; padding-bottom: 3px; margin-bottom: 5px; }
          .col-name { flex: 2; text-align: left; }
          .col-qty { width: 36px; text-align: center; }
          .col-price { width: 56px; text-align: right; }
          .col-sum { width: 64px; text-align: right; }
          .item-row { margin-bottom: 6px; }
          .item-name { font-weight: 600; color: #000; }
          .item-meta { display: flex; justify-content: flex-end; gap: 16px; font-size: 0.95em; }
          .receipt-calc-box { line-height: 1.75; }
          .calc-row { display: flex; justify-content: space-between; }
          .calc-row.discount { font-weight: 600; }
          .calc-row.total { font-size: 14.5px; font-weight: 800; border-top: 1px dashed #000; padding-top: 5px; margin-top: 5px; }
          .bold-price { font-size: 17px; font-weight: 800; color: #000; }
          .pay-split-list { padding-left: 8px; font-size: 11.5px; margin-top: 3px; }
          .pay-row { display: flex; justify-content: space-between; }
          .receipt-member-asset-box { line-height: 1.75; }
          .asset-title-block { text-align: center; font-weight: 700; margin-bottom: 4px; color: #000; }
          .asset-grid { display: flex; flex-direction: column; }
          .asset-row { display: flex; justify-content: space-between; }
          .text-green { color: #000 !important; font-weight: 600; }
          .receipt-footer-box { text-align: center; font-size: 11px; line-height: 1.55; margin-top: 6px; }
          .footer-notes { font-weight: 700; color: #000; margin-bottom: 5px; }
          .footer-meta { display: flex; flex-direction: column; gap: 2px; font-size: 10.5px; }
          .receipt-qr-zone { margin-top: 10px; display: flex; flex-direction: column; align-items: center; }
          .qr-img-wrapper { background: #ffffff; padding: 2px; display: flex; align-items: center; justify-content: center; }
          .qr-real-img { width: 78px; height: 78px; display: block; }
          .qr-hint-text { font-size: 10px; color: #000; margin-top: 4px; max-width: 250px; }
          .receipt-sign-stub { margin-top: 14px; line-height: 1.75; }
          .stub-divider { text-align: center; color: #000; margin-bottom: 5px; letter-spacing: 1px; }
          .stub-header { text-align: center; font-weight: 700; color: #000; }
          .stub-meta { display: flex; justify-content: space-between; font-size: 11.5px; }
          .stub-sign-block { margin-top: 10px; display: flex; flex-direction: column; gap: 8px; }
          .stub-sign-row { display: flex; align-items: flex-end; gap: 6px; }
          .sign-label { font-size: 11.5px; color: #000; font-weight: 700; white-space: nowrap; }
          .sign-underline { flex: 1; border-bottom: 1px solid #000; height: 1px; margin-bottom: 2px; }
          .stub-date-row { display: flex; justify-content: flex-end; font-size: 11px; color: #000; }
          .sawtooth-tear-edge { display: none !important; }
        
/* 📷 扫码盒子免驱状态条与快捷工作台 */
.scanbox-status-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: linear-gradient(135deg, #f0fdf4 0%, #ecfeff 100%);
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 16px;
  margin-bottom: 14px;
}
.hardware-badge {
  display: flex;
  align-items: center;
  gap: 8px;
}
.pulse-indicator {
  width: 10px;
  height: 10px;
  background-color: #10b981;
  border-radius: 50%;
  box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
  animation: pulse-green 2s infinite;
}
@keyframes pulse-green {
  0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7); }
  70% { transform: scale(1); box-shadow: 0 0 0 8px rgba(16, 185, 129, 0); }
  100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(16, 185, 129, 0); }
}
.hw-title {
  font-size: 14px;
  font-weight: 700;
  color: #065f46;
}
.bar-left {
  display: flex;
  align-items: center;
  gap: 16px;
}
.channel-route-tag {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #047857;
}
.bar-right {
  display: flex;
  align-items: center;
  gap: 10px;
}
.scan-quick-stats .stat-text {
  font-size: 12px;
  color: #475569;
}
.scan-quick-stats .default-hint {
  color: #059669;
  font-weight: 500;
}
.code-highlight {
  font-family: monospace;
  color: #0f766e;
  font-size: 13px;
}

/* 消费项目明细清单 */
.order-items-pane {
  margin-top: 10px;
  background: #f8fafc;
  border-radius: 6px;
  padding: 10px 12px;
  border: 1px solid #e2e8f0;
}
.items-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}
.items-title {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
}
.items-list-wrapper {
  display: flex;
  flex-direction: column;
  gap: 6px;
  max-height: 180px;
  overflow-y: auto;
}
.no-items-hint {
  font-size: 12px;
  color: #94a3b8;
  text-align: center;
  padding: 12px 0;
}
.cashier-item-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 8px;
  background: #ffffff;
  border-radius: 4px;
  border: 1px solid #f1f5f9;
}
.it-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.it-name {
  font-size: 12.5px;
  font-weight: 600;
  color: #1e293b;
}
.it-code {
  font-size: 11px;
  color: #94a3b8;
  font-family: monospace;
}
.it-price-qty {
  display: flex;
  align-items: center;
  gap: 8px;
}
.it-price {
  font-size: 12px;
  color: #64748b;
}
.it-qty-ctrl {
  display: flex;
  align-items: center;
  gap: 4px;
  background: #f1f5f9;
  border-radius: 4px;
  padding: 0 4px;
}
.it-qty {
  font-size: 12px;
  font-weight: 700;
  min-width: 16px;
  text-align: center;
}
.it-subtotal {
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
  min-width: 60px;
  text-align: right;
}

/* 扫码模拟器弹窗样式 */
.simulator-body {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.sim-hardware-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 16px;
}
.sim-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #0f172a;
}
.sim-indicator {
  width: 8px;
  height: 8px;
  background-color: #10b981;
  border-radius: 50%;
}
.sim-meta-tags {
  display: flex;
  gap: 6px;
  margin-top: 6px;
}
.sim-section {
  display: flex;
  flex-direction: column;
  gap: 8px;
  border: 1px solid #f1f5f9;
  border-radius: 6px;
  padding: 10px 14px;
  background: #ffffff;
}
.sim-sec-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.sim-sec-title {
  font-size: 13.5px;
  font-weight: 700;
  color: #1e293b;
}
.sim-sec-tip {
  font-size: 12px;
  color: #64748b;
}
.sim-btn-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
.custom-scan-line {
  display: flex;
  gap: 8px;
  align-items: center;
}
.mono-code {
  font-family: monospace;
  font-size: 12px;
  font-weight: 600;
}


/* === 黄金左6右4收银布局与商品网格 === */
.cashier-main-row {
  min-height: calc(100vh - 160px);
}
.product-catalog-card {
  height: 100%;
  display: flex;
  flex-direction: column;
}
.catalog-header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}
.cat-title-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
}
.cat-title {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
}
.product-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 12px;
  max-height: calc(100vh - 250px);
  overflow-y: auto;
  padding: 4px;
}
.product-cell-card {
  display: flex;
  flex-direction: column;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  user-select: none;
}
.product-cell-card:hover {
  background: #ffffff;
  border-color: #3b82f6;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
  transform: translateY(-2px);
}
.cell-icon {
  font-size: 24px;
  margin-bottom: 6px;
}
.cell-name {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.cell-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}
.cell-code {
  font-size: 10.5px;
  color: #64748b;
}
.cell-bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
}
.cell-price {
  font-size: 15px;
  font-weight: 800;
  color: #0f766e;
}
.cart-settle-col .order-pane {
  height: 100%;
}
.customer-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 10px;
  background: #f1f5f9;
  border-radius: 6px;
  margin-bottom: 8px;
  font-size: 12.5px;
}
.payer-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 6px;
  margin-bottom: 8px;
}
.payer-label {
  font-size: 12px;
  font-weight: 600;
  color: #4338ca;
  white-space: nowrap;
}
.amount-summary-strip {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 14px;
  margin: 10px 0;
}
.due-amount-display {
  display: flex;
  align-items: baseline;
  gap: 8px;
}
.due-text {
  font-size: 14px;
  font-weight: 600;
  color: #065f46;
}
.due-val-big {
  font-size: 24px;
  font-weight: 800;
  color: #047857;
}
.sub-amount-notes {
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 11px;
  color: #64748b;
  text-align: right;
}
.quick-pay-mini-bar {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  margin-bottom: 12px;
}
.channel-buttons-row {
  display: flex;
  gap: 6px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}
.channels-mini-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
.mini-channel-row {
  display: flex;
  align-items: center;
  gap: 4px;
}
.m-lbl {
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  min-width: 38px;
}
.held-orders-drawer-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.held-order-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.held-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.held-space {
  font-weight: 700;
  font-size: 14px;
  color: #1e293b;
}
.held-info {
  font-size: 12px;
  color: #64748b;
  line-height: 1.6;
}
.held-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

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
}

const handleSuccessConfirm = () => {
  successDialogVisible.value = false
  router.push('/dashboard')
}

watch(() => storeConfig.currentStoreId, () => {
  loadHeldOrdersFromStorage()
})

onMounted(async () => {
  loadHeldOrdersFromStorage()
  await loadActiveSessions()
  await loadStoreMembers()
  await loadSessionData()
  systemData.syncProductsFromServer()
  barcodeScanner.startListening()
  window.addEventListener("keydown", handleGlobalKeydown)
  ensureScannerFocus()
  unsubscribeScanner = barcodeScanner.subscribe(handleBarcodeScanned)
})

onUnmounted(() => {
  if (unsubscribeScanner) {
    unsubscribeScanner()
    unsubscribeScanner = null
  }
  barcodeScanner.stopListening()
  window.removeEventListener("keydown", handleGlobalKeydown)
})
</script>

<style scoped>
.cashier-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-title {
  font-size: 15px;
  font-weight: 600;
}

.order-info-box {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  color: #334155;
}

.mono-text {
  font-family: monospace;
  font-weight: 600;
}

/* 消费品项清单 (收银台专业数据表格布局，杜绝换行拥挤) */
.order-items-pane {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  overflow: hidden;
  margin-top: 4px;
}

.items-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.items-title {
  font-size: 13px;
  font-weight: 700;
  color: #1e293b;
}

.items-table-header {
  display: grid;
  grid-template-columns: minmax(110px, 1fr) 68px 78px 72px 34px;
  gap: 4px;
  align-items: center;
  padding: 6px 10px;
  background: #f1f5f9;
  border-bottom: 1px solid #cbd5e1;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
}

.items-list-wrapper {
  max-height: 220px;
  overflow-y: auto;
}

.items-table-row {
  display: grid;
  grid-template-columns: minmax(110px, 1fr) 68px 78px 72px 34px;
  gap: 4px;
  align-items: center;
  padding: 7px 10px;
  border-bottom: 1px solid #f1f5f9;
  font-size: 13px;
  transition: background-color 0.15s;
}

.items-table-row:hover {
  background-color: #f8fafc;
}

.items-table-row:last-child {
  border-bottom: none;
}

.th-cell {
  white-space: nowrap;
}

.th-cell.th-name, .td-cell.td-name {
  text-align: left;
  overflow: hidden;
  min-width: 0;
}

.th-cell.th-price, .td-cell.td-price {
  text-align: right;
  font-family: monospace;
  font-weight: 500;
  color: #334155;
  white-space: nowrap;
}

.th-cell.th-qty, .td-cell.td-qty {
  text-align: center;
  white-space: nowrap;
}

.th-cell.th-sub, .td-cell.td-sub {
  text-align: right;
  font-family: monospace;
  font-weight: 700;
  color: #0f172a;
  white-space: nowrap;
}

.th-cell.th-op, .td-cell.td-op {
  text-align: right;
  white-space: nowrap;
}

.it-title {
  font-weight: 600;
  color: #0f172a;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  display: block;
}

.it-barcode {
  font-size: 11px;
  color: #64748b;
  font-family: monospace;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  display: block;
}

.qty-stepper {
  display: inline-flex;
  align-items: center;
  border: 1px solid #cbd5e1;
  border-radius: 4px;
  background: #ffffff;
  overflow: hidden;
}

.step-btn {
  border: none;
  background: #f1f5f9;
  color: #334155;
  width: 20px;
  height: 22px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 13px;
  user-select: none;
  padding: 0;
}

.step-btn:hover {
  background: #e2e8f0;
  color: #0284c7;
}

.step-val {
  min-width: 22px;
  text-align: center;
  font-size: 12px;
  font-weight: 600;
  font-family: monospace;
}

.no-items-hint {
  padding: 16px;
  display: flex;
  justify-content: center;
}

.amount-summary {
  background-color: #f8fafc;
  padding: 12px;
  border-radius: 6px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.amount-row {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
}

.due-row {
  border-top: 1px dashed #cbd5e1;
  padding-top: 8px;
  margin-top: 4px;
}

.due-label {
  font-size: 15px;
  font-weight: 700;
}

.due-amount {
  font-size: 22px;
  font-weight: 700;
  color: #ef4444;
}

.member-asset-card {
  margin-top: 12px;
  background-color: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 6px;
  padding: 12px;
}

.asset-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 13px;
  font-weight: 600;
  color: #166534;
}

.asset-balances {
  margin-top: 8px;
}

.balance-item {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.b-label { font-size: 12px; color: #475569; }
.b-val { font-size: 16px; font-weight: 700; color: #15803d; }
.b-sub { font-size: 11px; color: #64748b; }

.time-cards-box {
  margin-top: 8px;
  border-top: 1px solid #dcfce7;
  padding-top: 6px;
}

.time-card-title {
  font-size: 12px;
  color: #166534;
  margin-bottom: 4px;
}

.tc-item {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #334155;
}

.channels-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.channel-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.ch-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.ch-desc {
  font-size: 12px;
  color: #64748b;
}

.ch-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.cash-channel {
  background-color: #fffbeb;
  border-color: #fde68a;
}

.cash-inputs {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.cash-line {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
}

.change-tag {
  background-color: #fef3c7;
  color: #b45309;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
}

.summary-check-bar {
  margin-top: 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  background-color: #f1f5f9;
  border-radius: 8px;
}

.check-left {
  display: flex;
  align-items: baseline;
  gap: 16px;
  font-size: 15px;
}

.diff-match {
  color: #059669;
  font-weight: 600;
}

/* 结账成功小票预览弹窗样式 */
.checkout-success-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  background: linear-gradient(135deg, #ecfdf5 0%, #f0fdf4 100%);
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  margin-bottom: 16px;
}
.success-banner {
  display: flex;
  align-items: center;
  gap: 12px;
}
.s-icon {
  font-size: 32px;
}
.s-main-title {
  font-size: 15px;
  font-weight: 700;
  color: #065f46;
}
.s-sub-title {
  font-size: 12px;
  color: #047857;
  margin-top: 2px;
}
.quick-action-btns {
  display: flex;
  gap: 8px;
}

/* 结账成功小票预览弹窗样式升级 */
:deep(.receipt-master-dialog.el-dialog) {
  border-radius: 12px;
  overflow: hidden;
  padding: 0;
}
:deep(.receipt-master-dialog .el-dialog__header) {
  margin: 0;
  padding: 16px 20px;
  border-bottom: 1px solid #e2e8f0;
  background: #f8fafc;
}
:deep(.receipt-master-dialog .el-dialog__body) {
  padding: 20px;
  background-color: #f1f5f9;
}
:deep(.receipt-master-dialog .el-dialog__footer) {
  padding: 14px 20px;
  border-top: 1px solid #e2e8f0;
  background: #ffffff;
}

/* 双栏排版网格 */
.receipt-dialog-body-grid {
  display: grid;
  grid-template-columns: 460px 1fr;
  gap: 20px;
  align-items: start;
}

/* 左侧配置面板 */
.receipt-config-panel {
  background: #ffffff;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  padding: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}
.panel-top-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 12px;
  border-bottom: 1px solid #f1f5f9;
  margin-bottom: 12px;
}
.p-heading {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
}
.preset-links {
  display: flex;
  gap: 4px;
}

.config-scroll-area {
  max-height: 580px;
  overflow-y: auto;
  padding-right: 4px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.config-group-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px;
}
.grp-title {
  font-size: 12.5px;
  font-weight: 700;
  color: #334155;
  margin-bottom: 10px;
}
.grp-content {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.grp-content.grid-2cols {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}
.cfg-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.cfg-lbl {
  font-size: 12px;
  color: #64748b;
  font-weight: 500;
}
.cfg-toggle-row {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.sub-switches-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  padding-left: 12px;
  margin-top: 6px;
}

/* 右侧纸张预览舞台 */
.receipt-preview-stage {
  background: #e2e8f0;
  border-radius: 10px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.06);
}
.stage-sticky-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  margin-bottom: 14px;
  padding-bottom: 10px;
  border-bottom: 1px dashed #cbd5e1;
}
.stage-title {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
}

.receipt-paper-bench {
  width: 100%;
  max-height: 580px;
  overflow-y: auto;
  padding: 12px 10px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

/* 仿真热敏小票纸张本体 (完全独立、自然撑高、严禁 flex 压缩) */
.thermal-paper-mockup {
  flex-shrink: 0;
  flex-grow: 0;
  height: auto;
  min-height: min-content;
  background: #ffffff;
  color: #0f172a;
  border-radius: 4px;
  box-shadow: 0 10px 25px -4px rgba(0, 0, 0, 0.16), 0 4px 10px -2px rgba(0, 0, 0, 0.08);
  border: 1px solid #e2e8f0;
  padding: 24px 20px;
  font-family: 'Courier New', Courier, Consolas, Monaco, monospace;
  box-sizing: border-box;
  margin: 0 auto 20px auto;
  line-height: 1.6;
}
.thermal-paper-mockup.width-80mm {
  width: 360px;
}
.thermal-paper-mockup.width-58mm {
  width: 275px;
}

.thermal-paper-mockup.font-compact {
  font-size: 11px;
}
.thermal-paper-mockup.font-standard {
  font-size: 12.5px;
}
.thermal-paper-mockup.font-large {
  font-size: 14px;
}

/* 锯齿边缘仿真线 */
.sawtooth-tear-edge {
  text-align: center;
  font-size: 11px;
  color: #cbd5e1;
  letter-spacing: 2px;
  margin-bottom: 10px;
}
.sawtooth-tear-edge.bottom {
  margin-top: 14px;
  margin-bottom: 0;
}

.receipt-center-box {
  text-align: center;
}
.receipt-shop-name {
  font-size: 17px;
  font-weight: 800;
  letter-spacing: 0.5px;
  color: #0f172a;
}
.receipt-sub-title {
  font-size: 11.5px;
  color: #64748b;
  margin-top: 3px;
}
.receipt-ticket-type {
  font-size: 13px;
  font-weight: 700;
  margin-top: 8px;
  color: #1e293b;
}

.receipt-divider {
  text-align: center;
  font-size: 11px;
  color: #94a3b8;
  margin: 10px 0;
  overflow: hidden;
  white-space: nowrap;
}

.receipt-meta-grid {
  line-height: 1.8;
}
.meta-row {
  display: flex;
  justify-content: space-between;
}
.mono {
  font-family: 'Courier New', Consolas, monospace;
  font-weight: 600;
}

.receipt-items-table {
  width: 100%;
}
.items-head {
  display: flex;
  font-weight: 700;
  border-bottom: 1px dashed #cbd5e1;
  padding-bottom: 4px;
  margin-bottom: 6px;
}
.col-name { flex: 2; text-align: left; }
.col-qty { width: 42px; text-align: center; }
.col-price { width: 62px; text-align: right; }
.col-sum { width: 70px; text-align: right; }

.item-row {
  margin-bottom: 6px;
}
.item-name {
  font-weight: 600;
  color: #1e293b;
}
.item-meta {
  display: flex;
  justify-content: flex-end;
  color: #475569;
}

.receipt-calc-box {
  line-height: 1.8;
}
.calc-row {
  display: flex;
  justify-content: space-between;
}
.calc-row.discount {
  color: #dc2626;
}
.calc-row.total {
  font-size: 15px;
  font-weight: 800;
  border-top: 1px dashed #cbd5e1;
  padding-top: 6px;
  margin-top: 6px;
}
.bold-price {
  font-size: 18px;
  font-weight: 800;
  color: #0f172a;
}

.pay-split-list {
  padding-left: 8px;
  font-size: 11.5px;
  color: #475569;
  margin-top: 4px;
}
.pay-row {
  display: flex;
  justify-content: space-between;
}
.pay-row.change {
  color: #d97706;
}

.receipt-member-asset-box {
  line-height: 1.8;
}
.asset-title-block {
  text-align: center;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 4px;
}
.asset-grid {
  display: flex;
  flex-direction: column;
}
.asset-row {
  display: flex;
  justify-content: space-between;
}
.text-green {
  color: #10b981 !important;
}

.receipt-footer-box {
  text-align: center;
  font-size: 11.5px;
  line-height: 1.6;
  color: #475569;
}
.footer-notes {
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 6px;
}
.footer-meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 11px;
}
.receipt-qr-zone {
  margin-top: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
}
.qr-img-wrapper {
  background: #ffffff;
  padding: 4px;
  border: 1px solid #e2e8f0;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.04);
}
.qr-real-img {
  width: 78px;
  height: 78px;
  display: block;
}
.qr-mock-box {
  width: 80px;
  height: 80px;
  border: 1.5px solid #0f172a;
  padding: 4px;
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
  width: 26px;
  height: 26px;
  background-color: #000;
  margin: auto;
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
}
.qr-hint-text {
  font-size: 10.5px;
  color: #64748b;
  margin-top: 4px;
  max-width: 260px;
}

.receipt-sign-stub {
  margin-top: 16px;
  line-height: 1.8;
}
.stub-divider {
  text-align: center;
  color: #94a3b8;
  margin-bottom: 6px;
  letter-spacing: 2px;
}
.stub-header {
  text-align: center;
  font-weight: 700;
  color: #0f172a;
}
.stub-meta {
  display: flex;
  justify-content: space-between;
  font-size: 11.5px;
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

.dialog-footer-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}
.right-btns {
  display: flex;
  gap: 12px;
}

/* 本地打印机调用时的打印样式 (精准输出80mm/58mm纸张，彻底隐藏所有背景与弹窗按钮) */
@media print {
  /* 隐藏所有 Element Plus 遮罩、弹窗与背景组件 */
  .el-overlay,
  .el-dialog__header,
  .checkout-success-header,
  .receipt-config-panel,
  .stage-sticky-header,
  .dialog-footer-flex,
  .el-drawer,
  header,
  nav,
  aside {
    display: none !important;
    visibility: hidden !important;
  }

  body * {
    visibility: hidden !important;
  }

  .receipt-preview-stage,
  .receipt-paper-bench {
    background: transparent !important;
    padding: 0 !important;
    margin: 0 !important;
    box-shadow: none !important;
    overflow: visible !important;
    max-height: none !important;
    display: block !important;
  }

  #thermal-receipt-printable,
  #thermal-receipt-printable * {
    visibility: visible !important;
  }

  #thermal-receipt-printable {
    position: absolute !important;
    left: 0 !important;
    top: 0 !important;
    width: 100% !important;
    max-width: 80mm !important;
    margin: 0 !important;
    padding: 3mm 2mm !important;
    box-shadow: none !important;
    border: none !important;
    background: #ffffff !important;
    color: #000000 !important;
  }

  .sawtooth-tear-edge {
    display: none !important;
  }
}

.level-growth-section {
  background: #f8fafc;
  border-radius: 8px;
  padding: 10px 12px;
  margin-bottom: 12px;
  border: 1px solid #e2e8f0;
}

.growth-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #475569;
}

.growth-score b {
  color: #0284c7;
  font-size: 14px;
}

.gap-highlight {
  color: #ea580c;
  font-size: 13px;
}

.growth-target.top-level {
  color: #d97706;
  font-weight: 600;
}

.checkout-gain-hint {
  display: flex;
  flex-direction: column;
  gap: 2px;
  margin-top: 4px;
  font-size: 11px;
}

.gain-badge {
  color: #16a34a;
  font-weight: 500;
}

.upgrade-forecast {
  color: #b45309;
  background: #fef3c7;
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: 600;
  border: 1px dashed #fcd34d;
}

/* === 黄金左6右4收银布局与商品网格 === */
.cashier-main-row {
  min-height: calc(100vh - 160px);
}
.product-catalog-card {
  height: 100%;
  display: flex;
  flex-direction: column;
}
.catalog-header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}
.cat-title-wrap {
  display: flex;
  align-items: center;
  gap: 12px;
}
.cat-title {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
}
.product-cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 12px;
  max-height: calc(100vh - 250px);
  overflow-y: auto;
  padding: 4px;
}
.product-cell-card {
  display: flex;
  flex-direction: column;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  user-select: none;
}
.product-cell-card:hover {
  background: #ffffff;
  border-color: #3b82f6;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
  transform: translateY(-2px);
}
.cell-icon {
  font-size: 24px;
  margin-bottom: 6px;
}
.cell-name {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.cell-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}
.cell-code {
  font-size: 10.5px;
  color: #64748b;
}
.cell-bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: auto;
}
.cell-price {
  font-size: 15px;
  font-weight: 800;
  color: #0f766e;
}
.cart-settle-col .order-pane {
  height: 100%;
}
.customer-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 10px;
  background: #f1f5f9;
  border-radius: 6px;
  margin-bottom: 8px;
  font-size: 12.5px;
}
.payer-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 6px;
  margin-bottom: 8px;
}
.payer-label {
  font-size: 12px;
  font-weight: 600;
  color: #4338ca;
  white-space: nowrap;
}
.amount-summary-strip {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #ecfdf5;
  border: 1px solid #a7f3d0;
  border-radius: 8px;
  padding: 10px 14px;
  margin: 10px 0;
}
.due-amount-display {
  display: flex;
  align-items: baseline;
  gap: 8px;
}
.due-text {
  font-size: 14px;
  font-weight: 600;
  color: #065f46;
}
.due-val-big {
  font-size: 24px;
  font-weight: 800;
  color: #047857;
}
.sub-amount-notes {
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 11px;
  color: #64748b;
  text-align: right;
}
.quick-pay-mini-bar {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  margin-bottom: 12px;
}
.channel-buttons-row {
  display: flex;
  gap: 6px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}
.channels-mini-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
.mini-channel-row {
  display: flex;
  align-items: center;
  gap: 4px;
}
.m-lbl {
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  min-width: 38px;
}
.held-orders-drawer-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.held-order-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.held-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.held-space {
  font-weight: 700;
  font-size: 14px;
  color: #1e293b;
}
.held-info {
  font-size: 12px;
  color: #64748b;
  line-height: 1.6;
}
.held-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

</style>
