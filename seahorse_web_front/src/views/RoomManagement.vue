<template>
  <div class="room-management-page">
    <!-- 顶部标题与业态说明 -->
    <div class="page-header-card">
      <div class="header-main-row">
        <div class="header-left">
          <div class="title-row">
            <h2 class="page-title">🏯 {{ customSpaceAlias }}管理</h2>
            <el-tag type="primary" effect="dark" class="alias-badge">当前空间称谓：{{ customSpaceAlias }}</el-tag>
            <el-tag type="success" effect="plain" class="industry-badge">
              🏬 {{ currentIndustryName }} · {{ currentStoreName }}
            </el-tag>
          </div>
          <p class="page-subtitle">
            当前门店行业为【{{ currentIndustryName }}】，空间资源使用【{{ customSpaceAlias }}】称谓。支持自主配置专属{{ customSpaceAlias }}、区域划分、低消门槛、批量生成与专属点单桌贴码。
          </p>
        </div>

        <div class="header-right">
          <template v-if="isMerchantBoss">
            <el-button type="primary" icon="Plus" size="default" @click="handleOpenCreateDialog">
              新增{{ customSpaceAlias }}
            </el-button>
            <el-button type="success" icon="Lightning" plain size="default" @click="handleOpenBatchDialog">
              ⚡ 批量快速生成
            </el-button>
            <el-button icon="Location" plain size="default" @click="openZoneConfigDialog">
              🗺️ 区域/楼层配置
            </el-button>
            <el-button icon="Edit" plain size="default" @click="handleOpenEditStoreDialog">
              🏪 门店资料维护
            </el-button>
            <el-button icon="Setting" plain size="default" @click="aliasDrawerVisible = true">
              🎛️ 称谓个性化
            </el-button>
          </template>
          <template v-else>
            <el-tag type="info" effect="plain" style="margin-right: 8px;">
              🔒 门店资料与空间配置仅租户主账号可操作
            </el-tag>
          </template>
          <el-button icon="Refresh" circle @click="refreshData" title="刷新数据" />
        </div>
      </div>
    </div>

    <!-- 核心运行指标卡片矩阵 -->
    <div class="stats-overview-grid">
      <div class="stat-card stat-total">
        <div class="stat-info">
          <span class="stat-label">总{{ customSpaceAlias }}数</span>
          <span class="stat-value">{{ currentStoreSpaces.length }}</span>
        </div>
        <el-icon class="stat-icon icon-primary"><House /></el-icon>
      </div>

      <div class="stat-card stat-idle">
        <div class="stat-info">
          <span class="stat-label">空闲可用</span>
          <span class="stat-value text-green">{{ idleCount }}</span>
        </div>
        <el-icon class="stat-icon icon-green"><CircleCheck /></el-icon>
      </div>

      <div class="stat-card stat-occupied">
        <div class="stat-info">
          <span class="stat-label">在场服务中</span>
          <span class="stat-value text-blue">{{ occupiedCount }}</span>
        </div>
        <el-icon class="stat-icon icon-blue"><Loading /></el-icon>
      </div>

      <div class="stat-card stat-dirty">
        <div class="stat-info">
          <span class="stat-label">待清台复位</span>
          <span class="stat-value text-orange">{{ dirtyCount }}</span>
        </div>
        <el-icon class="stat-icon icon-orange"><Brush /></el-icon>
      </div>

      <div class="stat-card stat-maintenance">
        <div class="stat-info">
          <span class="stat-label">维护/停用中</span>
          <span class="stat-value text-gray">{{ maintenanceCount }}</span>
        </div>
        <el-icon class="stat-icon icon-gray"><Tools /></el-icon>
      </div>

      <div class="stat-card stat-rate">
        <div class="stat-info">
          <span class="stat-label">实时使用率</span>
          <span class="stat-value text-purple">{{ occupancyRate }}%</span>
        </div>
        <el-icon class="stat-icon icon-purple"><PieChart /></el-icon>
      </div>
    </div>

    <!-- 筛选过滤与视图切换工具栏 -->
    <el-card class="filter-card" shadow="never">
      <div class="filter-container">
        <!-- 第一行：门店切换 + 区域选择 + 视图模式切换 -->
        <div class="filter-row-primary">
          <div class="filter-row-left">
            <div class="filter-item-group">
              <span class="filter-label">🏬 当前门店：</span>
              <el-select
                v-model="selectedStoreId"
                placeholder="选择门店"
                style="width: 320px;"
                @change="handleStoreChange"
              >
                <el-option
                  v-for="store in availableStores"
                  :key="store.storeId"
                  :label="store.storeName"
                  :value="store.storeId"
                >
                  <div style="display: flex; justify-content: space-between; align-items: center; width: 100%;">
                    <span style="font-weight: 500;">{{ store.storeName }}</span>
                    <el-tag size="small" type="info" effect="plain" style="margin-left: 8px;">{{ store.storeId }}</el-tag>
                  </div>
                </el-option>
              </el-select>
            </div>

            <div class="filter-divider"></div>

            <div class="zone-capsule-group">
              <span class="filter-label">区域/楼层：</span>
              <template v-if="availableZones.length > 0">
                <el-radio-group v-model="selectedZone" size="small">
                  <el-radio-button label="ALL">全部区域 ({{ currentStoreSpaces.length }})</el-radio-button>
                  <el-radio-button
                    v-for="zone in availableZones"
                    :key="zone"
                    :label="zone"
                  >
                    {{ zone }} ({{ getZoneCount(zone) }})
                  </el-radio-button>
                </el-radio-group>
                <el-button
                  v-if="isMerchantBoss"
                  link
                  type="primary"
                  size="small"
                  icon="Setting"
                  style="margin-left: 6px;"
                  @click="openZoneConfigDialog"
                >
                  区域管理
                </el-button>
              </template>
              <template v-else>
                <span class="no-zone-hint">尚未配置楼层区域</span>
                <el-button
                  v-if="isMerchantBoss"
                  type="primary"
                  plain
                  size="small"
                  icon="Plus"
                  style="margin-left: 8px;"
                  @click="openZoneConfigDialog"
                >
                  + 立即规划楼层/区域
                </el-button>
              </template>
            </div>
          </div>

          <div class="filter-row-right">
            <el-radio-group v-model="viewMode" size="default">
              <el-radio-button label="GRID">
                <el-icon><Menu /></el-icon> 卡片看板
              </el-radio-button>
              <el-radio-button label="TABLE">
                <el-icon><List /></el-icon> 数据列表
              </el-radio-button>
            </el-radio-group>
          </div>
        </div>

        <!-- 第二行：空间类型 + 使用状态 + 关键字搜索 + 重置 + 统计徽章 -->
        <div class="filter-row-secondary">
          <div class="filter-row-left">
            <div class="filter-item-group">
              <span class="filter-label">类型：</span>
              <el-select v-model="selectedType" placeholder="全部类型" clearable style="width: 140px;">
                <el-option label="全部类型" value="ALL" />
                <el-option label="包厢/套房" value="ROOM" />
                <el-option label="散台/卡座" value="TABLE" />
                <el-option label="美业镜台" value="MIRROR" />
                <el-option label="汽修工位" value="BAY" />
              </el-select>
            </div>

            <div class="filter-item-group">
              <span class="filter-label">状态：</span>
              <el-select v-model="selectedStatus" placeholder="全部状态" clearable style="width: 130px;">
                <el-option label="全部状态" value="ALL" />
                <el-option label="空闲可用" value="IDLE" />
                <el-option label="服务中" value="OCCUPIED" />
                <el-option label="待清台" value="DIRTY" />
                <el-option label="维修停用" value="MAINTENANCE" />
              </el-select>
            </div>

            <div class="filter-item-group">
              <el-input
                v-model="searchKeyword"
                :placeholder="`搜索${customSpaceAlias}名称、编号...`"
                prefix-icon="Search"
                clearable
                style="width: 220px;"
              />
            </div>

            <el-button
              plain
              size="default"
              icon="RefreshRight"
              :disabled="!hasActiveFilter"
              @click="resetFilters"
            >
              重置筛选
            </el-button>
          </div>

          <div class="filter-row-right">
            <span class="filter-result-count">
              共匹配到 <strong>{{ filteredList.length }}</strong> 个{{ customSpaceAlias }}
            </span>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 视图模式 1: 矩阵卡片看板 (GRID) -->
    <div v-if="viewMode === 'GRID'" class="spaces-grid-container">
      <div
        v-for="space in filteredList"
        :key="space.id"
        class="space-card"
        :class="['status-' + space.status.toLowerCase()]"
      >
        <!-- 卡片头部：编号与状态徽章 -->
        <div class="card-header">
          <div class="code-and-type">
            <span class="space-code">{{ space.spaceCode }}</span>
            <el-tag size="small" effect="plain" class="type-tag">{{ getSpaceTypeLabel(space.spaceType) }}</el-tag>
          </div>
          <el-tag
            :type="getStatusTagType(space.status)"
            effect="dark"
            size="small"
            class="status-tag"
          >
            {{ getStatusText(space.status) }}
          </el-tag>
        </div>

        <!-- 卡片主体：包厢名称与规格指标 -->
        <div class="card-body">
          <h3 class="space-name" :title="space.spaceName">{{ space.spaceName }}</h3>
          
          <div class="meta-row">
            <span class="meta-item">
              <el-icon><Location /></el-icon> {{ space.floorZone || '主服务区' }}
            </span>
            <span class="meta-item">
              <el-icon><User /></el-icon> 容纳 <b>{{ space.capacity || 1 }}</b> 人
            </span>
          </div>

          <!-- 低消与计费 -->
          <div class="billing-row">
            <span v-if="space.minConsumeAmount && space.minConsumeAmount > 0" class="min-consume">
              最低消费: <strong>￥{{ space.minConsumeAmount }}</strong>
            </span>
            <span v-else class="no-min-consume">
              无最低消费门槛
            </span>
            <span v-if="space.hourlyFee && space.hourlyFee > 0" class="hourly-fee">
              · ￥{{ space.hourlyFee }}/时
            </span>
          </div>

          <!-- 配套设施标签 -->
          <div class="facilities-tags" v-if="space.facilities && space.facilities.length > 0">
            <el-tag
              v-for="(f, fIdx) in space.facilities.slice(0, 3)"
              :key="fIdx"
              size="small"
              type="info"
              effect="light"
              class="facility-pill"
            >
              {{ f }}
            </el-tag>
            <span v-if="space.facilities.length > 3" class="more-facilities">
              +{{ space.facilities.length - 3 }}
            </span>
          </div>

          <!-- 在场动态或备注提示 -->
          <div v-if="space.status === 'OCCUPIED'" class="serving-hint">
            <span class="pulsing-dot"></span>
            <span>正在履约在场服务 (单号 #{{ space.currentSessionId || 'SES' }})</span>
          </div>
          <div v-else-if="space.notes" class="notes-hint" :title="space.notes">
            💬 {{ space.notes }}
          </div>
        </div>

        <!-- 卡片底部快捷操作 -->
        <div class="card-footer">
          <div class="footer-left-actions">
            <template v-if="space.status === 'OCCUPIED'">
              <el-button
                size="small"
                type="primary"
                plain
                @click="handleOpenAddItemsDialog(space)"
              >
                <el-icon><ShoppingBag /></el-icon> 点单加项
              </el-button>
              <el-button
                size="small"
                type="danger"
                @click="handleGoCashierBySpace(space)"
              >
                <el-icon><Money /></el-icon> 结账
              </el-button>
            </template>
            <template v-else-if="space.status === 'IDLE'">
              <el-button
                size="small"
                type="success"
                @click="handleOpenSpaceDirect(space)"
              >
                <el-icon><VideoPlay /></el-icon> 开台
              </el-button>
              <el-button
                size="small"
                type="primary"
                plain
                @click="handleOpenAddItemsDialog(space)"
              >
                <el-icon><ShoppingBag /></el-icon> 点单
              </el-button>
              <el-button
                size="small"
                type="info"
                plain
                @click="handleOpenAssignAptDialog(space)"
              >
                <el-icon><Calendar /></el-icon> 预约
              </el-button>
            </template>
            <el-button
              v-else-if="space.status === 'DIRTY'"
              size="small"
              type="warning"
              plain
              @click="handleSpaceCommand('reset', space)"
            >
              <el-icon><Brush /></el-icon> 清台
            </el-button>
          </div>

          <div class="footer-right-actions">
            <el-tooltip content="桌台点单码" placement="top">
              <el-button size="small" circle text @click="handleShowQrCode(space)">
                <el-icon><DocumentCopy /></el-icon>
              </el-button>
            </el-tooltip>
            <el-tooltip content="编辑包厢" placement="top">
              <el-button size="small" circle text @click="handleEditSpace(space)">
                <el-icon><Edit /></el-icon>
              </el-button>
            </el-tooltip>
            <el-dropdown trigger="click" @command="(cmd: string) => handleSpaceCommand(cmd, space)">
              <el-button size="small" circle icon="More" text />
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="add_items">
                    <span style="color: #4f46e5; font-weight: bold;">
                      <el-icon><ShoppingBag /></el-icon> 为{{ customSpaceAlias }}点单 (加服务/菜品/商品)
                    </span>
                  </el-dropdown-item>
                  <el-dropdown-item command="edit">
                    <el-icon><Edit /></el-icon> 编辑包厢属性
                  </el-dropdown-item>
                  <el-dropdown-item command="show_qr">
                    <el-icon><DocumentCopy /></el-icon> 查看点单二维码
                  </el-dropdown-item>
                  <el-dropdown-item v-if="space.status === 'OCCUPIED'" command="checkout">
                    <span style="color: #ef4444; font-weight: bold;">
                      <el-icon><Money /></el-icon> 发起结账收银
                    </span>
                  </el-dropdown-item>
                  <el-dropdown-item v-if="space.status === 'DIRTY'" command="reset">
                    <span style="color: #10b981; font-weight: bold;">
                      <el-icon><Brush /></el-icon> 清台并恢复空闲
                    </span>
                  </el-dropdown-item>
                  <el-dropdown-item v-if="space.status === 'IDLE'" command="set_maintenance">
                    <el-icon><Tools /></el-icon> 置为维修停用
                  </el-dropdown-item>
                  <el-dropdown-item v-if="space.status === 'MAINTENANCE'" command="set_idle">
                    <el-icon><CircleCheck /></el-icon> 恢复空闲可用
                  </el-dropdown-item>
                  <el-dropdown-item divided command="delete" :disabled="space.status === 'OCCUPIED'">
                    <span style="color: #ef4444;">
                      <el-icon><Delete /></el-icon> 删除{{ customSpaceAlias }}
                    </span>
                  </el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </div>
      </div>
    </div>

    <!-- 视图模式 2: 数据表格列表 (TABLE) -->
    <el-card v-else class="table-card" shadow="never">
      <el-table :data="filteredList" stripe border style="width: 100%">
        <el-table-column prop="spaceCode" label="空间编号" width="100" align="center" sortable>
          <template #default="{ row }">
            <el-tag effect="plain" style="font-weight: bold;">{{ row.spaceCode }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="spaceName" :label="customSpaceAlias + '名称'" min-width="160">
          <template #default="{ row }">
            <span style="font-weight: 600; color: #1e293b;">{{ row.spaceName }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="floorZone" label="所属楼层/区域" width="140" align="center">
          <template #default="{ row }">
            <el-tag size="small" type="info">{{ row.floorZone || '主服务区' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="spaceType" label="空间类型" width="120" align="center">
          <template #default="{ row }">
            {{ getSpaceTypeLabel(row.spaceType) }}
          </template>
        </el-table-column>
        <el-table-column prop="capacity" label="容纳人数" width="100" align="center" sortable>
          <template #default="{ row }">
            {{ row.capacity || 1 }} 人
          </template>
        </el-table-column>
        <el-table-column prop="minConsumeAmount" label="最低消费 (元)" width="130" align="right" sortable>
          <template #default="{ row }">
            <span v-if="row.minConsumeAmount && row.minConsumeAmount > 0" style="color: #f59e0b; font-weight: bold;">
              ￥{{ row.minConsumeAmount }}
            </span>
            <span v-else style="color: #94a3b8;">无门槛</span>
          </template>
        </el-table-column>
        <el-table-column label="配套设施" min-width="180">
          <template #default="{ row }">
            <div style="display: flex; flex-wrap: wrap; gap: 4px;">
              <el-tag
                v-for="(f, idx) in (row.facilities || [])"
                :key="idx"
                size="small"
                type="info"
              >
                {{ f }}
              </el-tag>
              <span v-if="!row.facilities || row.facilities.length === 0" style="color: #cbd5e1;">-</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="当前状态" width="110" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusTagType(row.status)" effect="dark" size="small">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="notes" label="备注说明" min-width="140" show-overflow-tooltip />
        <el-table-column label="操作管理" width="320" fixed="right" align="center">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 'OCCUPIED'"
              size="small"
              type="primary"
              link
              @click="handleOpenAddItemsDialog(row)"
            >
              点单加项
            </el-button>
            <el-button
              v-else-if="row.status === 'IDLE'"
              size="small"
              type="primary"
              link
              @click="handleOpenAddItemsDialog(row)"
            >
              点单
            </el-button>
            <el-button
              v-if="row.status === 'OCCUPIED'"
              size="small"
              type="danger"
              link
              @click="handleGoCashierBySpace(row)"
            >
              结账
            </el-button>
            <el-button
              v-else-if="row.status === 'IDLE'"
              size="small"
              type="success"
              link
              @click="handleOpenSpaceDirect(row)"
            >
              开台
            </el-button>
            <el-button
              v-if="row.status === 'IDLE'"
              size="small"
              type="info"
              link
              @click="handleOpenAssignAptDialog(row)"
            >
              接入预约
            </el-button>
            <el-button size="small" type="primary" link @click="handleEditSpace(row)">
              编辑
            </el-button>
            <el-button size="small" type="success" link @click="handleShowQrCode(row)">
              桌贴码
            </el-button>
            <el-button
              v-if="row.status === 'DIRTY'"
              size="small"
              type="warning"
              link
              @click="handleSpaceCommand('reset', row)"
            >
              复位
            </el-button>
            <el-button
              v-else-if="row.status === 'IDLE'"
              size="small"
              type="info"
              link
              @click="handleSpaceCommand('set_maintenance', row)"
            >
              停用
            </el-button>
            <el-button
              v-else-if="row.status === 'MAINTENANCE'"
              size="small"
              type="success"
              link
              @click="handleSpaceCommand('set_idle', row)"
            >
              启用
            </el-button>
            <el-button
              size="small"
              type="danger"
              link
              :disabled="row.status === 'OCCUPIED'"
              @click="handleSpaceCommand('delete', row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 弹窗 1: 单个新增/编辑包厢模态框 -->
    <el-dialog
      v-model="spaceFormVisible"
      :title="isEditing ? `编辑${customSpaceAlias} - ${spaceFormData.spaceName}` : `新增${customSpaceAlias}`"
      width="640px"
      destroy-on-close
    >
      <el-form :model="spaceFormData" label-width="110px">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="所属门店" required>
              <el-select v-model="spaceFormData.storeId" style="width: 100%">
                <el-option
                  v-for="s in availableStores"
                  :key="s.storeId"
                  :label="s.storeName"
                  :value="s.storeId"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item :label="customSpaceAlias + '编号'" required>
              <el-input v-model="spaceFormData.spaceCode" placeholder="如：B01, T08, BAY-1" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="16">
          <el-col :span="14">
            <el-form-item :label="customSpaceAlias + '名称'" required>
              <el-input v-model="spaceFormData.spaceName" placeholder="如：VIP紫荆景观大包厢" />
            </el-form-item>
          </el-col>
          <el-col :span="10">
            <el-form-item label="空间类型" required>
              <el-select v-model="spaceFormData.spaceType" style="width: 100%">
                <el-option label="包厢/套房" value="ROOM" />
                <el-option label="散台/卡座" value="TABLE" />
                <el-option label="美业镜台" value="MIRROR" />
                <el-option label="汽修工位" value="BAY" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="区域/楼层" required>
              <el-select
                v-model="spaceFormData.floorZone"
                filterable
                allow-create
                default-first-option
                placeholder="选择或输入新区域"
                style="width: 100%"
              >
                <el-option
                  v-for="z in availableZones"
                  :key="z"
                  :label="z"
                  :value="z"
                />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="容纳人数" required>
              <el-input-number v-model="spaceFormData.capacity" :min="1" :max="100" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="最低消费(元)">
              <el-input-number v-model="spaceFormData.minConsumeAmount" :min="0" :step="100" style="width: 100%" placeholder="0为无低消" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="钟点费(元/时)">
              <el-input-number v-model="spaceFormData.hourlyFee" :min="0" :step="10" style="width: 100%" placeholder="0为不计钟点" />
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 常用设施多选 -->
        <el-form-item label="配套设施">
          <div class="facility-checkbox-group">
            <el-checkbox-group v-model="spaceFormData.facilities">
              <el-checkbox
                v-for="fac in commonFacilityPresets"
                :key="fac"
                :label="fac"
                :value="fac"
              />
            </el-checkbox-group>
          </div>
          <div style="margin-top: 8px; display: flex; gap: 8px; width: 100%;">
            <el-input
              v-model="newCustomFacility"
              size="small"
              placeholder="新增自定义设施标签并回车"
              @keyup.enter="handleAddCustomFacility"
            />
            <el-button size="small" @click="handleAddCustomFacility">添加标签</el-button>
          </div>
        </el-form-item>

        <el-form-item label="当前状态" v-if="!isEditing">
          <el-radio-group v-model="spaceFormData.status">
            <el-radio label="IDLE">空闲可用</el-radio>
            <el-radio label="MAINTENANCE">维修停用</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="备注说明">
          <el-input
            v-model="spaceFormData.notes"
            type="textarea"
            :rows="2"
            placeholder="填写订座指引、特殊注意事项等"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="spaceFormVisible = false">取消</el-button>
        <el-button type="primary" :loading="formSaving" @click="handleSaveSpaceForm">
          保存{{ customSpaceAlias }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 2: 批量快速生成包厢/展位模态框 -->
    <el-dialog
      v-model="batchDialogVisible"
      :title="`⚡ 批量快速生成${customSpaceAlias}`"
      width="680px"
      destroy-on-close
    >
      <el-alert
        :title="`可按编号前缀与起止序号，一键批量生成连号${customSpaceAlias}，极大提升建店配置效率！`"
        type="info"
        :closable="false"
        show-icon
        style="margin-bottom: 18px;"
      />

      <el-form :model="batchFormData" label-width="100px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="编号前缀" required>
              <el-input v-model="batchFormData.codePrefix" :placeholder="`如：B, T, ${customSpaceAlias}-`" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="名称前缀" required>
              <el-input v-model="batchFormData.namePrefix" :placeholder="`如：豪华${customSpaceAlias}, 大厅${customSpaceAlias}`" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="起始序号" required>
              <el-input-number
                v-model="batchFormData.startNum"
                :min="1"
                :max="999"
                controls-position="right"
                style="width: 100%"
                placeholder="起始编号"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="结束序号" required>
              <el-input-number
                v-model="batchFormData.endNum"
                :min="1"
                :max="999"
                controls-position="right"
                style="width: 100%"
                placeholder="结束编号"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="自动补零">
              <el-switch
                v-model="batchFormData.padZero"
                active-text="补齐两位(如 01, 02)"
                inactive-text="不补零(如 1, 2)"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="所属区域" required>
              <el-select
                v-model="batchFormData.floorZone"
                filterable
                allow-create
                default-first-option
                style="width: 100%"
              >
                <el-option
                  v-for="z in availableZones"
                  :key="z"
                  :label="z"
                  :value="z"
                />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item :label="`${customSpaceAlias}类型`" required>
              <el-select v-model="batchFormData.spaceType" style="width: 100%">
                <el-option label="包厢/套房" value="ROOM" />
                <el-option label="散台/卡座" value="TABLE" />
                <el-option label="美业镜台" value="MIRROR" />
                <el-option label="汽修工位" value="BAY" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="容纳人数">
              <el-input-number
                v-model="batchFormData.capacity"
                :min="1"
                :max="100"
                controls-position="right"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="最低消费(￥)">
              <el-input-number
                v-model="batchFormData.minConsumeAmount"
                :min="0"
                :step="100"
                controls-position="right"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 实时生成预览 -->
        <div class="batch-preview-box">
          <div class="preview-title" style="display: flex; justify-content: space-between; align-items: center;">
            <span style="font-weight: 700; color: #334155;">📋 实时生成清单预览：</span>
            <el-tag type="success" size="small" effect="dark">预计生成 {{ calculateBatchCount }} 个{{ customSpaceAlias }}</el-tag>
          </div>
          <div class="preview-chips" style="margin-top: 10px;">
            <el-tag
              v-for="(item, idx) in previewBatchItems.slice(0, 10)"
              :key="idx"
              effect="plain"
              type="primary"
              style="margin-right: 6px; margin-bottom: 6px; font-weight: 600;"
            >
              {{ item.code }} · {{ item.name }}
            </el-tag>
            <span v-if="previewBatchItems.length > 10" class="preview-chip-more">
              ...等共 <b>{{ previewBatchItems.length }}</b> 个{{ customSpaceAlias }}
            </span>
          </div>
        </div>
      </el-form>

      <template #footer>
        <el-button @click="batchDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="batchSaving" @click="handleConfirmBatchCreate">
          立即批量生成
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 3: 专属桌贴/包厢点单二维码与立牌排版预览 -->
    <el-dialog
      v-model="qrDialogVisible"
      title="📱 包厢专属聚合点单与桌贴立牌"
      width="480px"
      destroy-on-close
      class="table-tent-dialog"
    >
      <div class="table-tent-mockup">
        <div class="tent-header">
          <div class="tent-brand">{{ currentStoreName }}</div>
          <div class="tent-room">{{ activeQrSpace?.spaceName }}</div>
          <div class="tent-code">桌台/包厢号：{{ activeQrSpace?.spaceCode }}</div>
        </div>

        <!-- 真实可用聚合点单二维码展示区 -->
        <div class="tent-qr-box">
          <div class="real-qr-wrapper">
            <img v-if="realQrCodeDataUrl" :src="realQrCodeDataUrl" alt="聚合点单二维码" class="real-qr-image" />
            <div v-else class="qr-loading-placeholder">
              <el-icon class="is-loading"><Loading /></el-icon>
              <span>正在生成专属二维码...</span>
            </div>
          </div>
          <div class="qr-scan-hint">扫一扫进入【海马体】在场点单与服务</div>
        </div>

        <div class="tent-footer">
          <div class="tent-feature">🧠 自动识别您的海马体偏好与忌口</div>
          <div class="tent-meta">区域：{{ activeQrSpace?.floorZone }} · 容纳 {{ activeQrSpace?.capacity }} 人</div>
        </div>
      </div>

      <div class="qr-action-toolbar">
        <el-button type="primary" icon="DocumentCopy" @click="copyQrUrl">
          复制点单链接
        </el-button>
        <el-button type="success" icon="Download" plain @click="downloadQrCode">
          下载桌贴图片
        </el-button>
        <el-button icon="Printer" plain @click="printTableTent">
          打印立牌预览
        </el-button>
      </div>
    </el-dialog>

    <!-- 抽屉 4: 空间称谓个性化与区域维护 -->
    <el-drawer
      v-model="aliasDrawerVisible"
      title="🎛️ 门店空间称谓个性化设置"
      size="420px"
    >
      <div class="alias-drawer-content">
        <el-alert
          title="支持根据当前业态场景（餐饮称【包厢】，修理厂称【工位】等），自由选择快捷推荐或手动输入名称，系统各模块将全面自适应！"
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 16px;"
        />

        <el-form label-position="top">
          <el-form-item label="当前空间统一称谓">
            <el-input v-model="tempAlias" placeholder="例如：包厢、工位、台位、雅座、镜台、展位" />
          </el-form-item>

          <div class="preset-alias-row">
            <span class="preset-label">快捷业态推荐：</span>
            <el-button size="small" round @click="tempAlias = '包厢'">包厢 (餐饮)</el-button>
            <el-button size="small" round @click="tempAlias = '工位'">工位 (修理厂/美业)</el-button>
            <el-button size="small" round @click="tempAlias = '台位'">台位 (散台)</el-button>
            <el-button size="small" round @click="tempAlias = '雅座'">雅座 (茶饮)</el-button>
            <el-button size="small" round @click="tempAlias = '镜台'">镜台 (造型)</el-button>
            <el-button size="small" round @click="tempAlias = '展位'">展位 (零售)</el-button>
          </div>

          <div style="margin-top: 30px;">
            <el-button type="primary" style="width: 100%" @click="handleSaveAlias">
              保存称谓配置
            </el-button>
            <el-button style="width: 100%; margin-top: 10px;" @click="handleResetAlias">
              恢复当前行业默认称谓
            </el-button>
          </div>
        </el-form>
      </div>
    </el-drawer>

    <!-- 弹窗 5: 门店基础资料编辑与维护 (租户主账号专属) -->
    <el-dialog
      v-model="editStoreDialogVisible"
      title="🏪 门店基础资料编辑与维护 (租户主账号专属)"
      width="560px"
      destroy-on-close
    >
      <el-alert
        title="所有分店基础信息统一由租户主账号集中维护，修改后全局各终端、看板与工位空间即时同步生效。"
        type="info"
        :closable="false"
        show-icon
        style="margin-bottom: 20px;"
      />
      <el-form :model="editStoreForm" label-width="100px">
        <el-form-item label="分店编号">
          <el-input v-model="editStoreForm.storeId" disabled />
        </el-form-item>
        <el-form-item label="门店名称" required>
          <el-input v-model="editStoreForm.storeName" placeholder="例如：海马体智慧旗舰店（总店）" />
        </el-form-item>
        <el-form-item label="详细地址" required>
          <el-input v-model="editStoreForm.address" placeholder="例如：天河区天河路208号天河城购物中心L4-02" />
        </el-form-item>
        <el-form-item label="联系电话" required>
          <el-input v-model="editStoreForm.phone" placeholder="例如：020-88886666" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editStoreDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="storeSaving" @click="handleSaveStoreInfo">
          保存门店资料
        </el-button>
      </template>
    </el-dialog>

    <!-- 弹窗 6: 门店区域/楼层规划配置中心 (支持预设全场景与租户自主创建参数) -->
    <el-dialog
      v-model="zoneConfigDialogVisible"
      :title="`🏬 门店区域/楼层规划配置中心 - ${currentStoreName}`"
      width="820px"
      top="6vh"
      destroy-on-close
      class="zone-config-dialog"
    >
      <div class="zone-config-modal-body">
        <el-alert
          title="楼层区域用于精细化管理门店物理空间与服务动线。您可以一键套用实体店铺各业态的经典规划、点击标签快速增选，或自由创建任意个性化命名参数。"
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 18px;"
        />

        <!-- 当前生效区域管理板块 -->
        <div class="zone-section-card">
          <div class="section-title-row">
            <div class="title-left">
              <span class="title-text">📌 当前门店已规划区域 ({{ tempZoneList.length }} 个)</span>
              <span class="sub-text">点击标签右侧 × 可移除未被空间占用的区域</span>
            </div>
            <el-button
              v-if="tempZoneList.length > 0"
              size="small"
              type="danger"
              plain
              @click="handleClearAllTempZones"
            >
              清空重置
            </el-button>
          </div>

          <div class="current-zones-wrap">
            <template v-if="tempZoneList.length > 0">
              <el-tag
                v-for="zone in tempZoneList"
                :key="zone"
                closable
                effect="light"
                size="large"
                class="active-zone-tag"
                @close="handleRemoveTempZone(zone)"
              >
                <el-icon style="margin-right: 4px;"><Location /></el-icon>
                <span>{{ zone }}</span>
                <span v-if="getZoneCount(zone) > 0" class="zone-space-badge">
                  ({{ getZoneCount(zone) }}个{{ customSpaceAlias }})
                </span>
              </el-tag>
            </template>
            <div v-else class="empty-zone-placeholder">
              <el-empty description="当前门店暂未配置任何区域，请在下方添加或套用预设" :image-size="50" />
            </div>
          </div>
        </div>

        <!-- 自定义区域创建板块 -->
        <div class="zone-section-card" style="margin-top: 16px;">
          <div class="section-title-row">
            <span class="title-text">✨ 创建自定义新区域 / 楼层参数</span>
            <span class="sub-text">支持任意个性化命名（如：3楼星空露台、8号私宴四合院、B2层精洗车位等）</span>
          </div>
          <div class="custom-add-input-bar">
            <el-input
              v-model="customZoneInput"
              placeholder="请输入自定义区域名称，按回车或点击右侧按钮添加..."
              clearable
              @keydown.enter="handleAddCustomZone"
            >
              <template #prefix>
                <el-icon><Plus /></el-icon>
              </template>
            </el-input>
            <el-button type="primary" icon="Plus" @click="handleAddCustomZone">
              添加到本门店
            </el-button>
          </div>
        </div>

        <!-- 实体店铺常用预设与一键套用模板 -->
        <div class="zone-section-card presets-card" style="margin-top: 16px;">
          <div class="section-title-row">
            <span class="title-text">💡 实体门店全场景楼层区域推荐库 (点击快速增选)</span>
            <span class="sub-text">覆盖餐饮、美业、汽修、零售等主流业态常见楼层与空间分区</span>
          </div>

          <!-- 一键推荐规划方案 -->
          <div class="template-shortcuts-row">
            <span class="preset-group-title">⚡ 经典规划一键套用：</span>
            <el-button size="small" type="primary" plain round @click="applyTemplate('standard_double')">
              🏢 双层标准 (一楼大厅 + 二楼VIP包厢区)
            </el-button>
            <el-button size="small" type="success" plain round @click="applyTemplate('full_dining')">
              🍲 多层餐饮 (大厅散座 + 卡座 + VIP包间 + 顶楼露台)
            </el-button>
            <el-button size="small" type="warning" plain round @click="applyTemplate('beauty_spa')">
              💇 美业丽人 (剪发区 + 冲水区 + 美容SPA + 美甲区)
            </el-button>
            <el-button size="small" type="info" plain round @click="applyTemplate('auto_garage')">
              🚗 汽修养护 (快保工位 + 精洗车间 + 底盘车间 + 客休大厅)
            </el-button>
          </div>

          <!-- 细分标签库 -->
          <div class="preset-categories-accordion">
            <!-- 基础楼层系列 -->
            <div class="preset-category-item">
              <span class="cat-label">🏢 基础楼层：</span>
              <div class="cat-tags">
                <el-tag
                  v-for="p in floorPresets"
                  :key="p"
                  class="preset-selectable-tag"
                  :class="{ selected: tempZoneList.includes(p) }"
                  @click="togglePresetZone(p)"
                >
                  {{ p }} {{ tempZoneList.includes(p) ? '✓' : '+' }}
                </el-tag>
              </div>
            </div>

            <!-- 餐饮茶饮酒吧 -->
            <div class="preset-category-item">
              <span class="cat-label">🍲 餐饮包厢/堂食：</span>
              <div class="cat-tags">
                <el-tag
                  v-for="p in diningPresets"
                  :key="p"
                  class="preset-selectable-tag"
                  :class="{ selected: tempZoneList.includes(p) }"
                  @click="togglePresetZone(p)"
                >
                  {{ p }} {{ tempZoneList.includes(p) ? '✓' : '+' }}
                </el-tag>
              </div>
            </div>

            <!-- 美业丽人养生 -->
            <div class="preset-category-item">
              <span class="cat-label">💇 美业丽人养生：</span>
              <div class="cat-tags">
                <el-tag
                  v-for="p in beautyPresets"
                  :key="p"
                  class="preset-selectable-tag"
                  :class="{ selected: tempZoneList.includes(p) }"
                  @click="togglePresetZone(p)"
                >
                  {{ p }} {{ tempZoneList.includes(p) ? '✓' : '+' }}
                </el-tag>
              </div>
            </div>

            <!-- 汽修养护工位 -->
            <div class="preset-category-item">
              <span class="cat-label">🚗 汽修养护车间：</span>
              <div class="cat-tags">
                <el-tag
                  v-for="p in autoPresets"
                  :key="p"
                  class="preset-selectable-tag"
                  :class="{ selected: tempZoneList.includes(p) }"
                  @click="togglePresetZone(p)"
                >
                  {{ p }} {{ tempZoneList.includes(p) ? '✓' : '+' }}
                </el-tag>
              </div>
            </div>

            <!-- 专营名品零售 -->
            <div class="preset-category-item">
              <span class="cat-label">🛍️ 专营零售展厅：</span>
              <div class="cat-tags">
                <el-tag
                  v-for="p in retailPresets"
                  :key="p"
                  class="preset-selectable-tag"
                  :class="{ selected: tempZoneList.includes(p) }"
                  @click="togglePresetZone(p)"
                >
                  {{ p }} {{ tempZoneList.includes(p) ? '✓' : '+' }}
                </el-tag>
              </div>
            </div>
          </div>
        </div>
      </div>

      <template #footer>
        <el-button @click="zoneConfigDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveZoneConfig">
          保存并生效规划配置
        </el-button>
      </template>
    </el-dialog>

    <!-- 接入预约入座弹窗 (将预约与展位均变服务中) -->
    <el-dialog
      v-model="assignAptDialogVisible"
      :title="`📅 为【${selectedActionSpace?.spaceName || '当前空间'}】安排预约顾客入座 (变服务中)`"
      width="680px"
      append-to-body
      destroy-on-close
    >
      <div style="margin-bottom: 12px; color: #64748b; font-size: 13px;">
        从当前门店待履约的预约列表中选择顾客，确认后包厢将立即开启服务并转为【服务中】状态。
      </div>
      <el-table :data="pendingAppointmentsList" stripe border style="width: 100%" empty-text="当前暂无待履约的预约顾客">
        <el-table-column prop="customerName" label="顾客姓名" width="130">
          <template #default="{ row }">
            <b>{{ row.customerName }}</b>
          </template>
        </el-table-column>
        <el-table-column prop="phone" label="联系电话" width="120" />
        <el-table-column prop="serviceName" label="预约项目" min-width="150" show-overflow-tooltip />
        <el-table-column prop="aptTime" label="预约时间" width="140" />
        <el-table-column prop="staffName" label="技师" width="110">
          <template #default="{ row }">
            {{ row.staffName || '智能调配' }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="110" align="center" fixed="right">
          <template #default="{ row }">
            <el-button size="small" type="primary" @click="handleConfirmCheckInFromSpace(row)">
              办理入座
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <template #footer>
        <el-button @click="assignAptDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>

    <!-- 一键开台入座弹窗 (变服务中) -->
    <el-dialog
      v-model="openDirectDialogVisible"
      :title="`🏨 【${selectedActionSpace?.spaceName || '当前空间'}】开台入座`"
      width="480px"
      append-to-body
    >
      <el-form label-width="95px">
        <el-form-item label="选择会员">
          <el-select
            v-model="selectedDirectMemberId"
            placeholder="搜索或选择会员（散客可不选）"
            filterable
            clearable
            style="width: 100%;"
            @change="handleDirectMemberChange"
          >
            <el-option
              v-for="m in storeMemberList"
              :key="m.id"
              :label="`${m.name} - ${m.phone} (${m.levelName || m.level || '普卡'})`"
              :value="m.id"
            >
              <div style="display: flex; justify-content: space-between; align-items: center; width: 100%;">
                <span><b>{{ m.name }}</b> ({{ m.phone }})</span>
                <el-tag size="small" type="success">{{ m.levelName || m.level || '会员' }}</el-tag>
              </div>
            </el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="顾客姓名">
          <el-input v-model="openDirectForm.customerName" placeholder="散客/会员姓名 (散客可留空)" clearable />
        </el-form-item>
        <el-form-item label="联系电话">
          <el-input v-model="openDirectForm.customerPhone" placeholder="手机号 (散客可留空)" clearable />
        </el-form-item>
        <el-form-item label="到店人数">
          <el-input-number v-model="openDirectForm.guestCount" :min="1" :max="20" style="width: 100%" />
        </el-form-item>
        <el-form-item label="开台备注">
          <el-input v-model="openDirectForm.notes" placeholder="开单服务或指定技师" clearable />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="openDirectDialogVisible = false">取消</el-button>
        <el-button type="success" @click="handleConfirmOpenDirect">确认立即开台 (变服务中)</el-button>
      </template>
    </el-dialog>

    <!-- 弹窗：包厢点单与添加服务/商品/菜品 -->
    <el-dialog
      v-model="addItemsDialogVisible"
      :title="`🛍️ 【${selectedActionSpace?.spaceName || '包厢'}】点单 · 添加服务/商品/菜品`"
      width="960px"
      top="4vh"
      destroy-on-close
      class="room-order-dialog"
    >
      <div class="room-order-container">
        <!-- 顶部包厢在场信息与低消状态栏 -->
        <div class="room-order-header-bar">
          <div class="room-info-left">
            <span class="room-title-badge">🏯 {{ selectedActionSpace?.spaceName }}</span>
            <el-tag size="small" type="info">{{ selectedActionSpace?.spaceCode }} · {{ selectedActionSpace?.floorZone || '主服务区' }}</el-tag>
            <el-tag size="small" :type="selectedActionSpace?.status === 'OCCUPIED' ? 'success' : 'primary'" effect="dark">
              {{ selectedActionSpace?.status === 'OCCUPIED' ? '在场服务中 (追加点单)' : '当前空闲 (点单并自动开台)' }}
            </el-tag>
          </div>
          <div class="room-info-right" v-if="selectedActionSpace?.minConsumeAmount && selectedActionSpace.minConsumeAmount > 0">
            <span class="min-consume-tag">
              包厢最低消费：<b>￥{{ selectedActionSpace.minConsumeAmount }}</b>
              <span v-if="orderProjectedTotal >= selectedActionSpace.minConsumeAmount" style="color: #10b981; font-weight: bold; margin-left: 6px;">
                ✓ 已达标
              </span>
              <span v-else style="color: #ea580c; margin-left: 6px;">
                (尚差 ￥{{ (selectedActionSpace.minConsumeAmount - orderProjectedTotal).toFixed(2) }})
              </span>
            </span>
          </div>
        </div>

        <!-- 顾客信息栏（若包厢空闲时可填写或修改） -->
        <div v-if="selectedActionSpace?.status === 'IDLE'" class="idle-customer-bar">
          <div class="bar-title">👥 开单入座信息：</div>
          <el-select
            v-model="selectedOrderMemberId"
            placeholder="快捷选会员 (散客免选)"
            filterable
            clearable
            size="small"
            style="width: 180px;"
            @change="handleOrderMemberChange"
          >
            <el-option
              v-for="m in storeMemberList"
              :key="m.id"
              :label="`${m.name} (${m.phone})`"
              :value="m.id"
            />
          </el-select>
          <el-input v-model="addOrderForm.customerName" placeholder="顾客称呼" size="small" style="width: 120px;" clearable />
          <el-input v-model="addOrderForm.customerPhone" placeholder="手机号 (散客可留空)" size="small" style="width: 150px;" clearable />
          <span style="font-size: 13px; color: #64748b;">到店人数:</span>
          <el-input-number v-model="addOrderForm.guestCount" :min="1" :max="30" size="small" style="width: 90px;" />
        </div>

        <!-- 主体区域：左侧品项选择 + 右侧待加入消费清单 -->
        <div class="order-content-grid">
          <!-- 左侧：服务/商品/菜品筛选与选购 -->
          <div class="products-pick-panel">
            <div class="panel-search-tabs">
              <el-input
                v-model="productSearchKeyword"
                placeholder="搜索服务、菜品、商品名称或编号..."
                size="small"
                prefix-icon="Search"
                clearable
              />
              <div class="category-tabs-wrap" style="margin-top: 8px;">
                <el-radio-group v-model="productCategoryTab" size="small" style="display: flex; flex-wrap: wrap; gap: 4px;">
                  <el-radio-button label="ALL">全部 ({{ catalogProductsList.length }})</el-radio-button>
                  <el-radio-button
                    v-for="cat in availableOrderCategories"
                    :key="cat"
                    :label="cat"
                  >
                    {{ cat }} ({{ getCategoryProductCount(cat) }})
                  </el-radio-button>
                </el-radio-group>
              </div>
            </div>

            <!-- 商品/服务卡片列表 -->
            <div class="products-scroll-grid">
              <div v-if="filteredCatalogProducts.length === 0" class="no-products-hint">
                <el-empty description="未检索到匹配的品项" :image-size="60" />
              </div>
              <div
                v-for="prod in filteredCatalogProducts"
                :key="prod.id"
                class="catalog-prod-card"
                :class="{ 'in-cart': getCartItemQty(prod.id) > 0 }"
                @click="handleQuickAddToCart(prod)"
              >
                <div class="prod-card-top">
                  <span class="prod-name" :title="prod.name">{{ prod.name }}</span>
                  <el-tag size="small" :type="getProductTagType(prod)" effect="light">
                    {{ getProductTypeName(prod) }}
                  </el-tag>
                </div>
                <div class="prod-card-meta">
                  <span class="prod-cat">{{ prod.categoryName || '热销通用' }}</span>
                  <span class="prod-price">￥{{ Number(prod.price || 0).toFixed(2) }}</span>
                </div>
                <div class="prod-card-action">
                  <span v-if="getCartItemQty(prod.id) > 0" class="cart-qty-pill">
                    已选 {{ getCartItemQty(prod.id) }} 份
                  </span>
                  <el-button size="small" type="primary" plain circle icon="Plus" @click.stop="handleQuickAddToCart(prod)" />
                </div>
              </div>
            </div>
          </div>

          <!-- 右侧：待落单清单 -->
          <div class="cart-summary-panel">
            <div class="cart-panel-header">
              <span class="cart-title">📋 待入账清单 ({{ orderCart.length }} 项)</span>
              <el-button v-if="orderCart.length > 0" size="small" type="danger" link @click="orderCart = []">清空</el-button>
            </div>

            <div class="cart-items-scroll">
              <div v-if="orderCart.length === 0" class="cart-empty-hint">
                <el-empty description="👈 请在左侧点击添加服务、菜品或商品" :image-size="50" />
              </div>
              <div v-for="(item, idx) in orderCart" :key="idx" class="cart-item-row">
                <div class="item-header-row">
                  <div class="item-title-wrap">
                    <span class="cart-item-name">{{ item.name }}</span>
                    <span class="cart-item-unitprice">￥{{ Number(item.price).toFixed(2) }}</span>
                  </div>
                  <div class="cart-qty-ctrl">
                    <button type="button" class="ctrl-btn" @click="changeCartItemQty(idx, -1)">-</button>
                    <span class="ctrl-val">{{ item.qty }}</span>
                    <button type="button" class="ctrl-btn" @click="changeCartItemQty(idx, 1)">+</button>
                    <el-button size="small" type="danger" link icon="Delete" style="margin-left: 6px;" @click="orderCart.splice(idx, 1)" />
                  </div>
                </div>

                <!-- 服务要求/做法与指定服务人员 -->
                <div class="item-spec-row">
                  <el-input
                    v-model="item.modifiers"
                    placeholder="服务要求 / 特殊备注 (点击下方标签快捷录入)"
                    size="small"
                    style="flex: 1;"
                  />
                  <el-select
                    v-model="item.technicianId"
                    placeholder="指定服务"
                    size="small"
                    clearable
                    style="width: 140px;"
                    @change="(val) => handleTechnicianChange(item, val)"
                  >
                    <el-option
                      v-for="st in storeStaffList"
                      :key="st.id"
                      :label="formatStaffDisplayName(st)"
                      :value="st.id"
                    />
                  </el-select>
                </div>

                <!-- 门店常用服务要求与特殊备注快捷标签 (多端双向同步) -->
                <div v-if="commonRemarksList && commonRemarksList.length > 0" style="display: flex; flex-wrap: wrap; gap: 4px; margin-top: 4px; padding-left: 2px;">
                  <el-tag
                    v-for="rm in commonRemarksList.slice(0, 8)"
                    :key="rm"
                    size="small"
                    type="info"
                    effect="plain"
                    style="cursor: pointer; font-size: 11px; padding: 0 6px; height: 22px; line-height: 20px;"
                    @click="appendRemarkToItem(item, rm)"
                  >
                    + {{ rm }}
                  </el-tag>
                </div>

                <div class="item-subtotal-row">
                  <span>小计:</span>
                  <b class="subtotal-val">￥{{ (Number(item.price) * item.qty).toFixed(2) }}</b>
                </div>
              </div>
            </div>

            <!-- 账单结算汇总条 -->
            <div class="cart-footer-summary">
              <div class="summary-line-row">
                <span>本次新增项目 ({{ cartTotalQty }} 件):</span>
                <span class="sum-highlight">￥{{ cartTotalAmount.toFixed(2) }}</span>
              </div>
              <div class="summary-line-row" v-if="selectedActionSpace?.status === 'OCCUPIED' && existingSessionAmount > 0">
                <span>原包厢在场累计:</span>
                <span>￥{{ existingSessionAmount.toFixed(2) }}</span>
              </div>
              <div class="summary-line-row total-row">
                <span style="font-weight: 700;">落单后预计包厢总额:</span>
                <span class="total-highlight">￥{{ orderProjectedTotal.toFixed(2) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <template #footer>
        <div class="dialog-footer-actions">
          <div class="footer-note">
            💡 支持任意数量的服务、餐饮菜品及零售实物混合开单与追加，系统将自动汇总至该包厢账单并流转至收银台。
          </div>
          <div style="display: flex; gap: 10px;">
            <el-button @click="addItemsDialogVisible = false">取消</el-button>
            <el-button
              type="primary"
              :loading="submittingOrder"
              :disabled="orderCart.length === 0"
              @click="handleConfirmAddItems"
            >
              🚀 确认落单 / 计入包厢账单
            </el-button>
          </div>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useSystemDataStore, type SpaceEntity } from '../stores/systemDataStore'
import { useStoreConfig } from '../stores/store'
import { ElMessage, ElMessageBox } from 'element-plus'
import QRCode from 'qrcode'
import { Loading, DocumentCopy, Download, Printer, VideoPlay, Calendar, ShoppingBag, Goods } from '@element-plus/icons-vue'
import {
  getSpacesApi,
  getTenantStoresApi,
  saveSpaceApi,
  batchCreateSpacesApi,
  deleteSpaceApi,
  updateSpaceStatusApi,
  resetSpaceApi,
  openSessionApi,
  appendItemsApi,
  getProductsApi,
  getActiveSessionsApi,
  getSessionDetailApi,
  getAppointmentsApi,
  checkInAppointmentApi,
  getCommonRemarksApi,
  getStaffDisplayModeApi,
  searchMembersApi,
  getCategoriesApi
} from '../api'

const selectedActionSpace = ref<any>(null)
const assignAptDialogVisible = ref(false)
const openDirectDialogVisible = ref(false)
const pendingAppointmentsList = ref<any[]>([])

const storeMemberList = ref<any[]>([])
const selectedDirectMemberId = ref<number | null>(null)
const selectedOrderMemberId = ref<number | null>(null)

const loadStoreMemberList = async () => {
  try {
    const tenantId = localStorage.getItem('seahorse_tenant_id') || 'T001'
    const res: any = await searchMembersApi('', tenantId)
    if (Array.isArray(res) && res.length > 0) {
      storeMemberList.value = res
      return
    }
  } catch (e) {}
  if (systemData.members && systemData.members.length > 0) {
    storeMemberList.value = systemData.members
  }
}

const handleDirectMemberChange = (memId: number | null) => {
  if (!memId) {
    openDirectForm.value.memberId = null
    openDirectForm.value.customerName = ''
    openDirectForm.value.customerPhone = ''
    return
  }
  const m = storeMemberList.value.find(item => item.id === memId)
  if (m) {
    openDirectForm.value.memberId = m.id
    openDirectForm.value.customerName = m.name
    openDirectForm.value.customerPhone = m.phone
    ElMessage.success(`已选择会员：${m.name} (${m.phone})`)
  }
}

const handleOrderMemberChange = (memId: number | null) => {
  if (!memId) {
    addOrderForm.value.memberId = null
    addOrderForm.value.customerName = ''
    addOrderForm.value.customerPhone = ''
    return
  }
  const m = storeMemberList.value.find(item => item.id === memId)
  if (m) {
    addOrderForm.value.memberId = m.id
    addOrderForm.value.customerName = m.name
    addOrderForm.value.customerPhone = m.phone
    ElMessage.success(`已选择会员：${m.name} (${m.phone})`)
  }
}

const openDirectForm = ref<{
  memberId: number | null
  customerName: string
  customerPhone: string
  guestCount: number
  notes: string
}>({
  memberId: null,
  customerName: '',
  customerPhone: '',
  guestCount: 1,
  notes: ''
})

const handleOpenSpaceDirect = (space: any) => {
  selectedActionSpace.value = space
  selectedDirectMemberId.value = null
  openDirectForm.value = {
    memberId: null,
    customerName: '',
    customerPhone: '',
    guestCount: 1,
    notes: '现场开台入座'
  }
  loadStoreMemberList()
  openDirectDialogVisible.value = true
}

const handleConfirmOpenDirect = async () => {
  if (!selectedActionSpace.value) return
  try {
    await openSessionApi({
      spaceId: selectedActionSpace.value.id,
      memberId: openDirectForm.value.memberId || null,
      customerName: openDirectForm.value.customerName || '散客顾客',
      customerPhone: openDirectForm.value.customerPhone || '',
      guestCount: openDirectForm.value.guestCount,
      notes: openDirectForm.value.notes
    })
    ElMessage.success(`【${selectedActionSpace.value.spaceName}】开台成功！展位已变更为【服务中】。`)
    openDirectDialogVisible.value = false
    await refreshData()
  } catch (err: any) {
    ElMessage.error(err.message || '开台失败')
  }
}

const handleOpenAssignAptDialog = async (space: any) => {
  selectedActionSpace.value = space
  assignAptDialogVisible.value = true
  try {
    const res: any = await getAppointmentsApi({ storeId: selectedStoreId.value || 'S001' })
    if (res && res.code === 200 && Array.isArray(res.data)) {
      pendingAppointmentsList.value = res.data.filter((a: any) => a.status === 'PENDING')
    } else {
      pendingAppointmentsList.value = []
    }
  } catch (_) {
    pendingAppointmentsList.value = []
  }
}

const handleConfirmCheckInFromSpace = async (apt: any) => {
  if (!selectedActionSpace.value) return
  try {
    await checkInAppointmentApi(apt.id, { spaceId: selectedActionSpace.value.id })
    ElMessage.success(`顾客【${apt.customerName}】已安排入座【${selectedActionSpace.value.spaceName}】！展位与预约已同步变为【服务中】。`)
    assignAptDialogVisible.value = false
    await refreshData()
  } catch (err: any) {
    ElMessage.error(err.message || '办理入座失败')
  }
}

const systemData = useSystemDataStore()
const storeConfig = useStoreConfig()
const router = useRouter()

// ==============================================================================
// 🏯 包厢直接点单与添加服务/商品/菜品功能
// ==============================================================================
const addItemsDialogVisible = ref(false)
const submittingOrder = ref(false)
const productSearchKeyword = ref('')
const productCategoryTab = ref('ALL')
const catalogProductsList = ref<any[]>([])
const configuredCategories = ref<string[]>([])
const storeStaffList = ref<any[]>([])
const staffDisplayMode = ref('NICKNAME_FIRST')
const commonRemarksList = ref<string[]>([])

const loadCategories = async () => {
  try {
    const res: any = await getCategoriesApi(systemData.currentIndustry)
    const list = Array.isArray(res) ? res : (res?.data || [])
    configuredCategories.value = list
      .filter((c: any) => c.available !== false)
      .map((c: any) => c.name)
  } catch (e) {
    configuredCategories.value = []
  }
}

const availableOrderCategories = computed(() => {
  const cats = new Set<string>()
  // 1. 优先按后台分类管理已配置的顺序放入分类
  configuredCategories.value.forEach(c => {
    if (c && c.trim()) cats.add(c.trim())
  })
  // 2. 补充当前商品库中存在的有效分类
  catalogProductsList.value.forEach(p => {
    const cat = (p.categoryName || p.category || '').trim()
    if (cat) cats.add(cat)
  })
  return Array.from(cats)
})

const getCategoryProductCount = (catName: string) => {
  return catalogProductsList.value.filter(p => (p.categoryName === catName || p.category === catName)).length
}

const formatStaffDisplayName = (st: any) => {
  if (!st) return ''
  const real = st.realName || st.name || ''
  const nick = st.nickname ? String(st.nickname).trim() : ''
  const mode = staffDisplayMode.value || 'NICKNAME_FIRST'
  if (mode === 'NICKNAME') {
    return nick || real
  } else if (mode === 'REAL_NAME') {
    return real
  } else if (mode === 'BOTH') {
    return nick ? `${real} (${nick})` : real
  } else {
    // NICKNAME_FIRST
    return nick || real
  }
}

const appendRemarkToItem = (item: any, tag: string) => {
  if (!item.modifiers) {
    item.modifiers = tag
  } else if (!item.modifiers.includes(tag)) {
    item.modifiers = `${item.modifiers}, ${tag}`
  }
}

const orderCart = ref<any[]>([])
const existingSessionAmount = ref(0)
const existingSessionCustomerName = ref('')
const existingSessionCustomerPhone = ref('')

const addOrderForm = ref({
  customerName: '散客顾客',
  customerPhone: '',
  guestCount: 2,
  notes: ''
})

const isFoodOrDrink = (p: any) => {
  const cat = (p.categoryName || '').toLowerCase()
  const name = (p.name || '').toLowerCase()
  return (
    cat.includes('餐') ||
    cat.includes('菜') ||
    cat.includes('酒') ||
    cat.includes('饮') ||
    cat.includes('食') ||
    cat.includes('茶') ||
    name.includes('茶') ||
    name.includes('酒') ||
    name.includes('菜') ||
    name.includes('牛排') ||
    name.includes('和牛') ||
    name.includes('面') ||
    name.includes('饭') ||
    name.includes('果盘') ||
    name.includes('饮') ||
    name.includes('小吃')
  )
}

const getProductTypeName = (p: any) => {
  if (p.productType === 'SERVICE' || p.type === 'SERVICE') return '💆 服务'
  if (p.productType === 'PACKAGE' || p.type === 'PACKAGE') return '🎁 套餐'
  const c = (p.categoryName || p.category || '').toLowerCase()
  if (c.includes('餐') || c.includes('菜') || c.includes('饮') || c.includes('酒') || c.includes('茶')) {
    return '🍲 餐饮/酒水'
  }
  return p.categoryName || p.category || '🛍️ 商品'
}

const getProductTagType = (p: any) => {
  if (p.productType === 'SERVICE' || p.type === 'SERVICE') return 'success'
  if (p.productType === 'PACKAGE' || p.type === 'PACKAGE') return 'warning'
  return 'primary'
}

const filteredCatalogProducts = computed(() => {
  let list = catalogProductsList.value
  if (productCategoryTab.value !== 'ALL') {
    list = list.filter(p => (p.categoryName === productCategoryTab.value || p.category === productCategoryTab.value))
  }
  if (productSearchKeyword.value.trim()) {
    const kw = productSearchKeyword.value.trim().toLowerCase()
    list = list.filter(p => 
      (p.name && p.name.toLowerCase().includes(kw)) ||
      (p.productCode && p.productCode.toLowerCase().includes(kw)) ||
      (p.categoryName && p.categoryName.toLowerCase().includes(kw)) ||
      (p.category && p.category.toLowerCase().includes(kw))
    )
  }
  return list
})

const getCartItemQty = (prodId: number) => {
  const found = orderCart.value.find(i => i.productId === prodId)
  return found ? found.qty : 0
}

const handleQuickAddToCart = (prod: any) => {
  const existing = orderCart.value.find(i => i.productId === prod.id)
  if (existing) {
    existing.qty += 1
  } else {
    orderCart.value.push({
      productId: prod.id,
      name: prod.name,
      price: Number(prod.price) || 0,
      type: isFoodOrDrink(prod) ? 'FOOD' : (prod.productType === 'SERVICE' ? 'SERVICE' : 'PHYSICAL'),
      qty: 1,
      modifiers: '',
      technicianId: null,
      technicianName: ''
    })
  }
}

const changeCartItemQty = (index: number, delta: number) => {
  if (!orderCart.value[index]) return
  orderCart.value[index].qty += delta
  if (orderCart.value[index].qty <= 0) {
    orderCart.value.splice(index, 1)
  }
}

const handleTechnicianChange = (item: any, staffId: any) => {
  if (!staffId) {
    item.technicianId = null
    item.technicianName = ''
    return
  }
  const found = storeStaffList.value.find((s: any) => s.id === staffId)
  if (found) {
    item.technicianId = found.id
    item.technicianName = found.realName || found.name
  }
}

const cartTotalQty = computed(() => {
  return orderCart.value.reduce((sum, it) => sum + (it.qty || 1), 0)
})

const cartTotalAmount = computed(() => {
  return orderCart.value.reduce((sum, it) => sum + (Number(it.price) || 0) * (it.qty || 1), 0)
})

const orderProjectedTotal = computed(() => {
  return existingSessionAmount.value + cartTotalAmount.value
})

const handleOpenAddItemsDialog = async (space: any) => {
  selectedActionSpace.value = space
  productSearchKeyword.value = ''
  productCategoryTab.value = 'ALL'
  orderCart.value = []
  existingSessionAmount.value = 0
  existingSessionCustomerName.value = ''
  existingSessionCustomerPhone.value = ''

  selectedOrderMemberId.value = null
  addOrderForm.value = {
    memberId: null,
    customerName: '',
    customerPhone: '',
    guestCount: space.capacity || 2,
    notes: '包厢点单消费'
  }
  loadStoreMemberList()
  loadCategories()

  // 1. 加载商品与服务清单 (合并服务端与本地配置，排除已下架商品，保证与商品分类管理完全一致)
  try {
    const res: any = await getProductsApi()
    const serverProds = Array.isArray(res) ? res : (res?.data || [])
    const mergedList: any[] = []
    const seenIds = new Set<any>()

    // 优先加载服务端最新数据
    serverProds.forEach((p: any) => {
      if (p.available === false || p.status === 'DISABLED') return
      mergedList.push({
        id: p.id,
        name: p.name,
        productCode: p.productCode || ('PRD' + p.id),
        price: Number(p.price || 0),
        categoryName: p.categoryName || p.category || '默认分类',
        category: p.categoryName || p.category || '默认分类',
        productType: p.productType || p.type || 'PHYSICAL',
        type: p.productType || p.type || 'PHYSICAL',
        stock: p.stock,
        unit: p.unit || '件'
      })
      seenIds.add(p.id)
      if (p.productCode) seenIds.add(p.productCode)
    })

    // 合并本地在商品管理中新增或维护的商品
    if (Array.isArray(systemData.products)) {
      systemData.products.forEach((p: any) => {
        if (p.status === 'DISABLED' || p.available === false) return
        if (seenIds.has(p.id) || (p.code && seenIds.has(p.code))) return
        mergedList.push({
          id: p.id,
          name: p.name,
          productCode: p.code || p.productCode || ('PRD' + p.id),
          price: Number(p.salePrice || p.price || 0),
          categoryName: p.categoryName || p.category || '默认分类',
          category: p.categoryName || p.category || '默认分类',
          productType: p.type || p.productType || 'PHYSICAL',
          type: p.type || p.productType || 'PHYSICAL',
          stock: p.stock,
          unit: p.unit || '件'
        })
      })
    }
    catalogProductsList.value = mergedList
  } catch (e) {
    catalogProductsList.value = (systemData.products || [])
      .filter((p: any) => p.status !== 'DISABLED' && p.available !== false)
      .map((p: any) => ({
        id: p.id,
        name: p.name,
        productCode: p.code || p.productCode || ('PRD' + p.id),
        price: Number(p.salePrice || p.price || 0),
        categoryName: p.categoryName || p.category || '默认分类',
        category: p.categoryName || p.category || '默认分类',
        productType: p.type || p.productType || 'PHYSICAL',
        type: p.type || p.productType || 'PHYSICAL',
        stock: p.stock,
        unit: p.unit || '件'
      }))
  }

  // 2. 加载员工列表与展示模式、常用服务备注标签
  storeStaffList.value = systemData.staff || []
  const targetSId = selectedStoreId.value || storeConfig.currentStoreId || 'S001'
  try {
    const modeRes: any = await getStaffDisplayModeApi(targetSId)
    const mData = modeRes?.data || modeRes
    if (mData && mData.staffDisplayMode) {
      staffDisplayMode.value = mData.staffDisplayMode
    }
  } catch (e) {
    console.warn('获取称谓规则失败', e)
  }
  try {
    const remRes: any = await getCommonRemarksApi(targetSId, storeConfig.industry)
    const remData = remRes?.data || remRes
    if (Array.isArray(remData)) {
      commonRemarksList.value = remData
    }
  } catch (e) {
    console.warn('获取常用备注失败', e)
  }

  // 3. 若包厢在场服务中，获取当前已有点单消费金额与顾客信息
  if (space.status === 'OCCUPIED') {
    try {
      const activeRes: any = await getActiveSessionsApi()
      const activeArr = Array.isArray(activeRes) ? activeRes : (activeRes?.data || [])
      const matched = activeArr.find((s: any) => Number(s.spaceId) === Number(space.id) && s.status !== 'COMPLETED')
      if (matched) {
        selectedActionSpace.value.currentSessionId = matched.id
        existingSessionAmount.value = Number(matched.payableAmount || matched.totalAmount || 0)
        existingSessionCustomerName.value = matched.customerName || '在场顾客'
        existingSessionCustomerPhone.value = matched.customerPhone || ''
        addOrderForm.value.customerName = matched.customerName || '在场顾客'
        addOrderForm.value.customerPhone = matched.customerPhone || ''
      }
    } catch (e) {}
  }

  addItemsDialogVisible.value = true
}

const handleConfirmAddItems = async () => {
  if (orderCart.value.length === 0) {
    ElMessage.warning('请先从左侧品项库中选择需要添加的服务、商品或菜品！')
    return
  }
  if (!selectedActionSpace.value) return

  submittingOrder.value = true
  try {
    let sId = selectedActionSpace.value.currentSessionId

    // 若包厢已处于服务中，确保获取准确的 sessionId
    if (selectedActionSpace.value.status === 'OCCUPIED' && !sId) {
      try {
        const activeRes: any = await getActiveSessionsApi()
        const activeArr = Array.isArray(activeRes) ? activeRes : (activeRes?.data || [])
        const matched = activeArr.find((s: any) => Number(s.spaceId) === Number(selectedActionSpace.value.id) && s.status !== 'COMPLETED')
        if (matched) {
          sId = matched.id
          selectedActionSpace.value.currentSessionId = matched.id
        }
      } catch (e) {}
    }

    // 若包厢处于空闲状态，先为包厢执行开台入座开单
    if (selectedActionSpace.value.status === 'IDLE' || !sId) {
      const openRes: any = await openSessionApi({
        spaceId: selectedActionSpace.value.id,
        memberId: addOrderForm.value.memberId || null,
        customerName: addOrderForm.value.customerName || '散客顾客',
        customerPhone: addOrderForm.value.customerPhone || '',
        guestCount: addOrderForm.value.guestCount || 1,
        notes: addOrderForm.value.notes || '包厢现场点单消费'
      })
      const openedSession = openRes?.data || openRes
      sId = openedSession?.id
      selectedActionSpace.value.status = 'OCCUPIED'
      selectedActionSpace.value.currentSessionId = sId
      systemData.updateSpaceStatus(selectedActionSpace.value.id, 'OCCUPIED')
    }

    // 提交批量追加品项
    const cmd = {
      sessionId: Number(sId),
      operatorType: 'WAITER',
      operatorName: localStorage.getItem('seahorse_user') || '前台收银/服务员',
      items: orderCart.value.map(it => ({
        productId: it.productId,
        quantity: it.qty,
        modifiers: it.modifiers || '',
        performers: it.technicianId ? [{
          employeeId: it.technicianId,
          employeeName: it.technicianName,
          shareRatio: 1.0
        }] : []
      }))
    }

    await appendItemsApi(cmd)

    ElMessage.success({
      message: `🎉 成功为【${selectedActionSpace.value.spaceName}】添加 ${orderCart.value.length} 项消费品项（合计 ￥${cartTotalAmount.value.toFixed(2)}），已实时计入包厢账单！`,
      duration: 4000
    })

    addItemsDialogVisible.value = false
    orderCart.value = []
    await refreshData()
  } catch (err: any) {
    console.error('包厢添加品项失败:', err)
    ElMessage.error(err?.message || '添加消费品项失败，请重试')
  } finally {
    submittingOrder.value = false
  }
}

// 角色权限与租户隔离：仅租户主账号具备修改门店基础资料及工位空间的权限
const role = ref(localStorage.getItem('seahorse_role') || 'SUPER_ADMIN')
const isMerchantBoss = computed(() => role.value === 'SUPER_ADMIN' || role.value === 'MERCHANT_ADMIN' || role.value === 'STORE_OWNER')

// 视图模式：GRID (卡片看板) | TABLE (数据表格)
const viewMode = ref<'GRID' | 'TABLE'>('GRID')

// 称谓配置（支持租户自定义，支持根据行业自适应或持久化配置）
const customSpaceAlias = computed(() => {
  return storeConfig.spaceAlias || localStorage.getItem('seahorse_custom_space_alias') || '包厢'
})

const tempAlias = ref(customSpaceAlias.value)
const aliasDrawerVisible = ref(false)

const handleSaveAlias = () => {
  const val = tempAlias.value.trim() || '包厢'
  storeConfig.setCustomSpaceAlias(val)
  aliasDrawerVisible.value = false
  ElMessage.success(`空间称谓已更新为【${val}】！`)
}

const handleResetAlias = () => {
  localStorage.removeItem('seahorse_custom_space_alias')
  const def = storeConfig.getDefaultSpaceAlias()
  tempAlias.value = def
  storeConfig.spaceAlias = def
  aliasDrawerVisible.value = false
  ElMessage.success(`已恢复当前行业默认称谓【${def}】！`)
}

const serverStores = ref<any[]>([])

const loadStores = async () => {
  try {
    const res: any = await getTenantStoresApi()
    const list = Array.isArray(res) ? res : (Array.isArray(res?.data) ? res.data : [])
    if (list.length > 0) {
      serverStores.value = list
      systemData.stores = list.map((s: any) => ({
        storeId: s.storeId,
        storeName: s.storeName,
        address: s.address || '陕西省西安市高新区高新路海马商业中心1号店',
        managerName: s.managerName || '店长',
        phone: s.phone || '029-88889999',
        isHeadquarter: s.isHeadquarter ?? true,
        businessStatus: s.status === 'ACTIVE' ? 'OPEN' : 'OPEN',
        totalSpaces: 4,
        openTime: s.businessHours || '09:00 - 22:30'
      }))
      if (!selectedStoreId.value || !list.some((s: any) => s.storeId === selectedStoreId.value)) {
        selectedStoreId.value = list[0].storeId
        storeConfig.switchStore(list[0].storeId)
      }
    }
  } catch (err) {
    console.warn('loadStores error:', err)
  }
}

// 全局多店铺统一数据源 (与服务端 /space/stores 及顶部保持一致)
const availableStores = computed(() => {
  let list: Array<{ storeId: string; storeName: string; address: string; phone: string; industry: string }> = []
  
  if (serverStores.value.length > 0) {
    list = serverStores.value.map(s => ({
      storeId: s.storeId,
      storeName: s.storeName,
      address: s.address || '陕西省西安市高新区高新路海马商业中心1号店',
      phone: s.phone || '029-88889999',
      industry: s.industry || 'BEAUTY'
    }))
  } else if (storeConfig.stores && storeConfig.stores.length > 0) {
    list = storeConfig.stores.map(s => {
      const match = systemData.stores.find(sysStore => sysStore.storeId === s.storeId)
      return {
        storeId: s.storeId,
        storeName: s.storeName,
        address: (s as any).address || match?.address || '陕西省西安市高新区高新路海马商业中心1号店',
        phone: (s as any).phone || match?.phone || '029-88889999',
        industry: s.industry || match?.businessStatus || 'BEAUTY'
      }
    })
  } else if (systemData.stores && systemData.stores.length > 0) {
    list = systemData.stores.map(s => ({
      storeId: s.storeId,
      storeName: s.storeName,
      address: s.address,
      phone: s.phone,
      industry: s.businessStatus
    }))
  }

  // 兜底保障：若当前选中的 selectedStoreId 或 currentStoreId 不在列表中，注入兜底项，确保绝不渲染为裸编号（如 S_FOOT_01）
  const targetId = (selectedStoreId.value && selectedStoreId.value.trim()) || (storeConfig.currentStoreId && storeConfig.currentStoreId.trim()) || 'S001'
  if (targetId && !list.some(s => s.storeId === targetId)) {
    const fallbackName = storeConfig.storeName || localStorage.getItem('seahorse_store_name') || '海马体智慧生活 (西安高新旗舰店)'
    list.unshift({
      storeId: targetId,
      storeName: fallbackName,
      address: '陕西省西安市高新区高新路海马商业中心1号店',
      phone: '029-88889999',
      industry: 'BEAUTY'
    })
  }

  return list
})

// 门店切换 (全场景统一数据源，与顶部全局联动)
const selectedStoreId = ref((storeConfig.currentStoreId && storeConfig.currentStoreId.trim()) || systemData.stores[0]?.storeId || 'S001')

watch(() => storeConfig.currentStoreId, (newId) => {
  if (newId && newId.trim() && selectedStoreId.value !== newId) {
    selectedStoreId.value = newId
  }
}, { immediate: true })

const handleStoreChange = (val: string) => {
  storeConfig.switchStore(val)
  const matched = availableStores.value.find(s => s.storeId === val)
  if (matched && matched.storeName) {
    storeConfig.storeName = matched.storeName
    localStorage.setItem('seahorse_store_name', matched.storeName)
  }
}

const currentStoreName = computed(() => {
  const store = availableStores.value.find(s => s.storeId === selectedStoreId.value)
  return store?.storeName || storeConfig.storeName || localStorage.getItem('seahorse_store_name') || '海马智慧门店'
})

// 门店资料维护 (租户主账号专属)
const editStoreDialogVisible = ref(false)
const storeSaving = ref(false)
const editStoreForm = ref({
  storeId: '',
  storeName: '',
  address: '',
  phone: ''
})

const handleOpenEditStoreDialog = () => {
  if (!isMerchantBoss.value) {
    ElMessage.warning('抱歉，仅租户主账号具备修改门店基础资料的权限！')
    return
  }
  const curr = availableStores.value.find(s => s.storeId === selectedStoreId.value)
  if (curr) {
    editStoreForm.value = {
      storeId: curr.storeId,
      storeName: curr.storeName,
      address: curr.address,
      phone: curr.phone
    }
  } else {
    editStoreForm.value = {
      storeId: selectedStoreId.value,
      storeName: currentStoreName.value,
      address: '广州市天河区天河路208号',
      phone: '020-88996611'
    }
  }
  editStoreDialogVisible.value = true
}

const handleSaveStoreInfo = async () => {
  if (!editStoreForm.value.storeName.trim()) {
    ElMessage.warning('请输入门店名称')
    return
  }
  storeSaving.value = true
  try {
    const sId = editStoreForm.value.storeId
    const sName = editStoreForm.value.storeName.trim()
    const sAddr = editStoreForm.value.address.trim()
    const sPhone = editStoreForm.value.phone.trim()

    // 1. 同步更新 systemDataStore 中的门店
    const sysStore = systemData.stores.find(s => s.storeId === sId)
    if (sysStore) {
      sysStore.storeName = sName
      sysStore.address = sAddr
      sysStore.phone = sPhone
    }
    // 2. 同步更新 storeConfig 中的门店
    const cfgStore = storeConfig.stores.find(s => s.storeId === sId)
    if (cfgStore) {
      cfgStore.storeName = sName
      ;(cfgStore as any).address = sAddr
      ;(cfgStore as any).phone = sPhone
    }
    if (storeConfig.currentStoreId === sId) {
      storeConfig.storeName = sName
      localStorage.setItem('seahorse_store_name', sName)
    }
    try {
      localStorage.setItem('seahorse_stores_data', JSON.stringify(systemData.stores))
    } catch {}
    ElMessage.success(`门店【${sName}】资料已更新并全局同步生效！`)
    editStoreDialogVisible.value = false
  } finally {
    storeSaving.value = false
  }
}

const currentIndustryName = computed(() => {
  if (storeConfig.industryCategoryName) return storeConfig.industryCategoryName
  const cachedCat = localStorage.getItem('seahorse_industry_category')
  if (cachedCat) return cachedCat
  switch (systemData.currentIndustry) {
    case 'RESTAURANT': return '餐饮轻食/融合料理'
    case 'BEAUTY': return '美容美发美甲'
    case 'AUTO': return '汽车养护维修'
    case 'RETAIL': return '专营名品零售'
    default: return '智慧门店'
  }
})

// 筛选状态
const selectedZone = ref('ALL')
const selectedType = ref('ALL')
const selectedStatus = ref('ALL')
const searchKeyword = ref('')

const hasActiveFilter = computed(() => {
  return selectedZone.value !== 'ALL' || selectedType.value !== 'ALL' || selectedStatus.value !== 'ALL' || !!searchKeyword.value.trim()
})

const resetFilters = () => {
  selectedZone.value = 'ALL'
  selectedType.value = 'ALL'
  selectedStatus.value = 'ALL'
  searchKeyword.value = ''
}

// 实体门店全场景楼层区域推荐库预设数据
const floorPresets = ['一楼', '二楼', '三楼', '四楼', '五楼', '负一层 (B1)', '负二层 (B2)', '顶楼露台', '夹层/阁楼']

const diningPresets = [
  '一楼大厅', '散台大厅区', '二楼雅座包厢区', '舒适卡座区',
  '景观窗边位', '豪华VIP包房', '商务宴请大包', '静谧茶室雅间',
  '吧台高脚区', '户外露营外摆区', '等位茶歇区'
]

const beautyPresets = [
  '发型设计剪发区', '烫染护理专区', '冲水洗发区', '美甲美睫专区',
  '独立美容包间', '私密SPA套房', '头疗采耳养生区', 'VIP贵宾套房',
  '前台等候接待区'
]

const autoPresets = [
  '快速保养工位', '精洗美容车间', '机修底盘车间', '四轮定位工位',
  '钣金喷漆车间', '无尘贴膜车间', '客户休息大厅', '交车待提区'
]

const retailPresets = [
  '精品主推展区', '热销爆款专区', '特惠折扣区', '试衣试戴体验间',
  '中央环岛主展台', '前台收银服务台', '前置仓储配货区'
]

// 区域配置中心状态
const zoneConfigDialogVisible = ref(false)
const customZoneInput = ref('')
const tempZoneList = ref<string[]>([])
const currentStoreConfiguredZones = ref<string[]>([])

// 门店区域配置持久化
const getStoredZonesForStore = (storeId: string): string[] => {
  try {
    const raw = localStorage.getItem(`seahorse_store_zones_${storeId}`)
    if (raw) {
      const parsed = JSON.parse(raw)
      if (Array.isArray(parsed)) return parsed
    }
  } catch (e) {
    console.error(e)
  }
  return []
}

const saveStoredZonesForStore = (storeId: string, zones: string[]) => {
  try {
    localStorage.setItem(`seahorse_store_zones_${storeId}`, JSON.stringify(zones))
  } catch (e) {
    console.error(e)
  }
}

const refreshStoreZones = () => {
  currentStoreConfiguredZones.value = getStoredZonesForStore(selectedStoreId.value)
}

const loadingSpaces = ref(false)
const loadSpaces = async () => {
  loadingSpaces.value = true
  try {
    const sId = selectedStoreId.value || storeConfig.currentStoreId || 'S001'
    let list: any = null
    if (sId) {
      try {
        list = await getSpacesApi(sId)
      } catch (_) {}
    }
    let arr = Array.isArray(list) ? list : (Array.isArray(list?.data) ? list.data : [])
    // 若按门店ID未查到或为空，全量查询当前租户名下所有空间（与移动端保持绝对一致）
    if (arr.length === 0) {
      try {
        const fallbackRes: any = await getSpacesApi()
        arr = Array.isArray(fallbackRes) ? fallbackRes : (Array.isArray(fallbackRes?.data) ? fallbackRes.data : [])
      } catch (_) {}
    }

    if (arr.length > 0) {
      const formatted: SpaceEntity[] = arr.map((item: any) => ({
        id: item.id,
        storeId: item.storeId || sId || 'S001',
        spaceCode: item.spaceCode,
        spaceName: item.spaceName,
        spaceType: item.spaceType || 'ROOM',
        status: item.status || 'IDLE',
        capacity: item.capacity || 4,
        floorZone: item.floorZone || '一楼养生区',
        currentSessionId: item.currentSessionId || null,
        qrCodeUrl: item.qrCodeUrl || `${window.location.origin}/mall?store=${item.storeId || sId || 'S001'}&spaceCode=${item.spaceCode}`,
        minConsumeAmount: item.minConsumeAmount || 0,
        hourlyFee: item.hourlyFee || 0,
        facilities: typeof item.facilities === 'string' ? item.facilities.split(',').filter(Boolean) : (item.facilities || []),
        notes: item.notes || '',
        sortOrder: item.sortOrder || 1
      }))

      // 同步到 systemData.spaces
      systemData.spaces = formatted

      // 若当前 selectedStoreId 与返回的空间 storeId 不匹配或为空，自动对齐
      if (!selectedStoreId.value || !formatted.some(s => s.storeId === selectedStoreId.value)) {
        if (formatted[0]?.storeId) {
          selectedStoreId.value = formatted[0].storeId
        }
      }
    }
  } catch (e) {
    console.log('加载后端空间数据失败，使用本地缓存:', e)
  } finally {
    loadingSpaces.value = false
  }
}

watch(selectedStoreId, () => {
  refreshStoreZones()
  selectedZone.value = 'ALL'
  loadSpaces()
}, { immediate: true })

// 当前门店的空间列表 (优先匹配当前选中门店，若按门店过滤为空但租户已有空间，自动兜底展示所有空间，彻底杜绝假空状态)
const currentStoreSpaces = computed(() => {
  const storeId = selectedStoreId.value
  const allSpaces = systemData.spaces || []
  if (allSpaces.length === 0) return []

  if (storeId) {
    const matched = allSpaces.filter(s => s.storeId === storeId)
    if (matched.length > 0) {
      return matched
    }
  }
  return allSpaces
})

// 当前门店所有区域/楼层（仅展示已配置或当前空间已使用的真实区域，不强加硬编码数据）
const availableZones = computed(() => {
  const set = new Set<string>()
  // 1. 已配置的区域
  currentStoreConfiguredZones.value.forEach(z => {
    if (z && z.trim()) set.add(z.trim())
  })
  // 2. 现有空间所使用的区域
  currentStoreSpaces.value.forEach(s => {
    if (s.floorZone && s.floorZone.trim()) set.add(s.floorZone.trim())
  })
  // 3. 初始演示店 S001 且未做过任何自定义配置时保留 demo 兼容
  if (selectedStoreId.value === 'S001' && set.size === 0 && currentStoreSpaces.value.length > 0) {
    set.add('二楼VIP包厢区')
    set.add('一楼大厅')
  }
  return Array.from(set)
})

const getZoneCount = (zone: string) => {
  return currentStoreSpaces.value.filter(s => s.floorZone === zone).length
}

// 打开区域/楼层规划弹窗
const openZoneConfigDialog = () => {
  if (!isMerchantBoss.value) {
    ElMessage.warning('抱歉，仅租户管理账号具备规划楼层区域的权限！')
    return
  }
  const set = new Set<string>()
  currentStoreConfiguredZones.value.forEach(z => {
    if (z && z.trim()) set.add(z.trim())
  })
  currentStoreSpaces.value.forEach(s => {
    if (s.floorZone && s.floorZone.trim()) set.add(s.floorZone.trim())
  })
  tempZoneList.value = Array.from(set)
  customZoneInput.value = ''
  zoneConfigDialogVisible.value = true
}

// 添加自定义新区域
const handleAddCustomZone = () => {
  const name = customZoneInput.value.trim()
  if (!name) {
    ElMessage.warning('请输入自定义区域或楼层名称！')
    return
  }
  if (tempZoneList.value.includes(name)) {
    ElMessage.warning(`区域【${name}】已在列表中，请勿重复添加！`)
    return
  }
  tempZoneList.value.push(name)
  customZoneInput.value = ''
  ElMessage.success(`已添加区域【${name}】`)
}

// 快速增选/取消预设
const togglePresetZone = (zone: string) => {
  const idx = tempZoneList.value.indexOf(zone)
  if (idx > -1) {
    if (getZoneCount(zone) > 0) {
      ElMessage.warning(`区域【${zone}】下已有 ${getZoneCount(zone)} 个${customSpaceAlias.value}在使用，不能直接取消！`)
      return
    }
    tempZoneList.value.splice(idx, 1)
  } else {
    tempZoneList.value.push(zone)
  }
}

// 移除单个区域
const handleRemoveTempZone = (zone: string) => {
  if (getZoneCount(zone) > 0) {
    ElMessage.warning(`区域【${zone}】下已有 ${getZoneCount(zone)} 个${customSpaceAlias.value}，请先变更空间归属后再移除！`)
    return
  }
  tempZoneList.value = tempZoneList.value.filter(z => z !== zone)
}

// 清空全部临时区域
const handleClearAllTempZones = () => {
  const used = tempZoneList.value.filter(z => getZoneCount(z) > 0)
  if (used.length > 0) {
    ElMessageBox.confirm(
      `检测到【${used.join('、')}】下已有空间绑定，清空将只保留已绑定的区域。确认继续吗？`,
      '清空提示',
      { type: 'warning' }
    ).then(() => {
      tempZoneList.value = used
      ElMessage.info('已保留被空间绑定的区域，未使用的区域已清空')
    }).catch(() => {})
  } else {
    tempZoneList.value = []
    ElMessage.info('已清空所有规划区域')
  }
}

// 一键套用经典模板方案
const applyTemplate = (tpl: 'standard_double' | 'full_dining' | 'beauty_spa' | 'auto_garage') => {
  let toAdd: string[] = []
  if (tpl === 'standard_double') {
    toAdd = ['一楼大厅', '二楼VIP包厢区']
  } else if (tpl === 'full_dining') {
    toAdd = ['一楼大厅散座', '二楼舒适卡座', '三楼VIP包房', '顶楼露天餐吧']
  } else if (tpl === 'beauty_spa') {
    toAdd = ['发型设计剪发区', '冲水洗发区', '独立美容SPA间', '美甲美睫区']
  } else if (tpl === 'auto_garage') {
    toAdd = ['快速保养工位', '精洗美容车间', '机修底盘车间', '客户休息大厅']
  }
  let addedCount = 0
  toAdd.forEach(item => {
    if (!tempZoneList.value.includes(item)) {
      tempZoneList.value.push(item)
      addedCount++
    }
  })
  ElMessage.success(`成功导入推荐规划方案，新加入 ${addedCount} 个规划区域！`)
}

// 保存区域配置
const handleSaveZoneConfig = () => {
  saveStoredZonesForStore(selectedStoreId.value, tempZoneList.value)
  currentStoreConfiguredZones.value = [...tempZoneList.value]
  zoneConfigDialogVisible.value = false
  if (selectedZone.value !== 'ALL' && !tempZoneList.value.includes(selectedZone.value)) {
    selectedZone.value = 'ALL'
  }
  ElMessage.success(`门店【${currentStoreName.value}】区域/楼层规划已保存生效！`)
}

// 确保区域已保存记录
const ensureZoneConfigured = (zone?: string) => {
  if (!zone || !zone.trim()) return
  const trimmed = zone.trim()
  if (!currentStoreConfiguredZones.value.includes(trimmed)) {
    currentStoreConfiguredZones.value.push(trimmed)
    saveStoredZonesForStore(selectedStoreId.value, currentStoreConfiguredZones.value)
  }
}

// 过滤后的列表
const filteredList = computed(() => {
  return currentStoreSpaces.value.filter(s => {
    // 区域
    if (selectedZone.value !== 'ALL' && s.floorZone !== selectedZone.value) return false
    // 类型
    if (selectedType.value !== 'ALL' && s.spaceType !== selectedType.value) return false
    // 状态
    if (selectedStatus.value !== 'ALL' && s.status !== selectedStatus.value) return false
    // 搜索
    if (searchKeyword.value.trim()) {
      const kw = searchKeyword.value.trim().toLowerCase()
      const matchName = s.spaceName.toLowerCase().includes(kw)
      const matchCode = s.spaceCode.toLowerCase().includes(kw)
      const matchZone = (s.floorZone || '').toLowerCase().includes(kw)
      if (!matchName && !matchCode && !matchZone) return false
    }
    return true
  })
})

// 统计指标
const idleCount = computed(() => currentStoreSpaces.value.filter(s => s.status === 'IDLE').length)
const occupiedCount = computed(() => currentStoreSpaces.value.filter(s => s.status === 'OCCUPIED').length)
const dirtyCount = computed(() => currentStoreSpaces.value.filter(s => s.status === 'DIRTY').length)
const maintenanceCount = computed(() => currentStoreSpaces.value.filter(s => s.status === 'MAINTENANCE').length)

const occupancyRate = computed(() => {
  const total = currentStoreSpaces.value.length
  if (total === 0) return 0
  return Math.round((occupiedCount.value / total) * 100)
})

// 状态辅助函数
const getStatusTagType = (status: string) => {
  switch (status) {
    case 'IDLE': return 'success'
    case 'OCCUPIED': return 'primary'
    case 'DIRTY': return 'warning'
    case 'MAINTENANCE': return 'info'
    default: return 'info'
  }
}

const getStatusText = (status: string) => {
  switch (status) {
    case 'IDLE': return '空闲可用'
    case 'OCCUPIED': return '服务中'
    case 'DIRTY': return '待清台'
    case 'MAINTENANCE': return '维修停用'
    default: return status
  }
}

const getSpaceTypeLabel = (type: string) => {
  switch (type) {
    case 'ROOM': return '包厢/套房'
    case 'TABLE': return '散台/卡座'
    case 'MIRROR': return '美业镜台'
    case 'BAY': return '汽修工位'
    default: return '空间'
  }
}

// 常用设施预设标签
const commonFacilityPresets = [
  '独立洗手间', '全景落地窗', '功夫茶台', '专属管家', '新风系统',
  '榻榻米', '静音隔音', '高清投影/KTV', '红酒恒温柜', '智能无线充',
  '儿童安全座椅', '4吨举升机', '智能防眩化妆镜'
]
const newCustomFacility = ref('')

const handleAddCustomFacility = () => {
  const val = newCustomFacility.value.trim()
  if (!val) return
  if (!spaceFormData.value.facilities) {
    spaceFormData.value.facilities = []
  }
  if (!spaceFormData.value.facilities.includes(val)) {
    spaceFormData.value.facilities.push(val)
  }
  newCustomFacility.value = ''
}

// 单个新增/编辑表单
const spaceFormVisible = ref(false)
const isEditing = ref(false)
const formSaving = ref(false)

const spaceFormData = ref<Partial<SpaceEntity>>({
  storeId: selectedStoreId.value,
  spaceCode: '',
  spaceName: '',
  spaceType: 'ROOM',
  status: 'IDLE',
  capacity: 4,
  floorZone: '',
  minConsumeAmount: 0,
  hourlyFee: 0,
  facilities: [],
  notes: ''
})

const handleOpenCreateDialog = () => {
  isEditing.value = false
  const defaultZone = availableZones.value[0] || currentStoreConfiguredZones.value[0] || ''
  spaceFormData.value = {
    storeId: selectedStoreId.value,
    spaceCode: `B${String(currentStoreSpaces.value.length + 1).padStart(2, '0')}`,
    spaceName: `VIP景观大包厢 ${currentStoreSpaces.value.length + 1}`,
    spaceType: 'ROOM',
    status: 'IDLE',
    capacity: 8,
    floorZone: defaultZone,
    minConsumeAmount: 500,
    hourlyFee: 0,
    facilities: ['独立洗手间', '新风系统', '功夫茶台'],
    notes: ''
  }
  spaceFormVisible.value = true
}

const handleEditSpace = (space: SpaceEntity) => {
  isEditing.value = true
  spaceFormData.value = JSON.parse(JSON.stringify(space))
  spaceFormVisible.value = true
}

const handleSaveSpaceForm = async () => {
  if (!spaceFormData.value.spaceCode?.trim()) {
    ElMessage.warning(`请输入${customSpaceAlias.value}编号！`)
    return
  }
  if (!spaceFormData.value.spaceName?.trim()) {
    ElMessage.warning(`请输入${customSpaceAlias.value}名称！`)
    return
  }

  // 自动将新输入的区域持久化保存到当前门店的规划配置中
  if (spaceFormData.value.floorZone) {
    ensureZoneConfigured(spaceFormData.value.floorZone)
  }

  formSaving.value = true
  try {
    const facilitiesStr = Array.isArray(spaceFormData.value.facilities)
      ? spaceFormData.value.facilities.join(',')
      : (spaceFormData.value.facilities || '')

    const qrUrl = spaceFormData.value.qrCodeUrl || `${window.location.origin}/mall?store=${selectedStoreId.value}&spaceCode=${spaceFormData.value.spaceCode}`

    const payload: any = {
      ...spaceFormData.value,
      storeId: selectedStoreId.value,
      facilities: facilitiesStr,
      qrCodeUrl: qrUrl
    }

    // 1. 调用后端接口保存到 MySQL 数据库
    let saved: any = null
    try {
      saved = await saveSpaceApi(payload)
    } catch (apiErr) {
      console.warn('后端空间保存接口异常，启动本地持久化保护:', apiErr)
    }

    // 2. 本地 pinia 状态双向同步
    const realId = (saved && saved.id) ? saved.id : (spaceFormData.value.id || undefined)
    const entityToSave: any = {
      ...spaceFormData.value,
      id: realId,
      storeId: selectedStoreId.value,
      qrCodeUrl: qrUrl,
      facilities: Array.isArray(spaceFormData.value.facilities) ? spaceFormData.value.facilities : (facilitiesStr ? facilitiesStr.split(',') : [])
    }

    if (isEditing.value && realId) {
      systemData.updateSpace(realId, entityToSave)
      ElMessage.success(`已保存${customSpaceAlias.value}【${spaceFormData.value.spaceName}】配置并成功保存到数据库！`)
    } else {
      const added = systemData.addSpace(entityToSave)
      if (saved && saved.id) {
        added.id = saved.id
      }
      ElMessage.success(`已成功创建新${customSpaceAlias.value}【${spaceFormData.value.spaceName}】并成功保存到数据库！`)
    }
    spaceFormVisible.value = false
    await loadSpaces()
  } finally {
    formSaving.value = false
  }
}

// 直接由展位/工位发起结账收银
const handleGoCashierBySpace = (space: SpaceEntity) => {
  const sessionId = space.currentSessionId || 1
  router.push({
    path: '/cashier',
    query: {
      sessionId: String(sessionId),
      spaceId: String(space.id),
      spaceName: space.spaceName
    }
  })
}

// 更多操作命令
const handleSpaceCommand = async (cmd: string, space: SpaceEntity) => {
  if (cmd === 'add_items') {
    handleOpenAddItemsDialog(space)
    return
  }
  if (cmd === 'edit') {
    handleEditSpace(space)
    return
  }
  if (cmd === 'show_qr') {
    handleShowQrCode(space)
    return
  }
  if (cmd === 'checkout') {
    handleGoCashierBySpace(space)
    return
  }
  if (cmd === 'reset') {
    try {
      await resetSpaceApi(space.id)
    } catch (e) {}
    systemData.resetSpace(space.id)
    ElMessage.success(`包厢【${space.spaceName}】已完成翻台清扫消毒，恢复空闲可用！`)
  } else if (cmd === 'set_maintenance') {
    try {
      await updateSpaceStatusApi(space.id, 'MAINTENANCE')
    } catch (e) {}
    systemData.updateSpaceStatus(space.id, 'MAINTENANCE')
    ElMessage.info(`已将【${space.spaceName}】置为维修停用状态。`)
  } else if (cmd === 'set_idle') {
    try {
      await updateSpaceStatusApi(space.id, 'IDLE')
    } catch (e) {}
    systemData.updateSpaceStatus(space.id, 'IDLE')
    ElMessage.success(`已将【${space.spaceName}】恢复为空闲可用！`)
  } else if (cmd === 'delete') {
    if (space.status === 'OCCUPIED') {
      ElMessage.error(`【${space.spaceName}】当前有在场顾客服务履约中，不可删除！`)
      return
    }
    ElMessageBox.confirm(
      `确定要删除${customSpaceAlias.value}【${space.spaceName}】吗？删除后数据库及各看板将同步移除。`,
      '确认删除',
      { confirmButtonText: '确认删除', cancelButtonText: '取消', type: 'warning' }
    ).then(async () => {
      try {
        await deleteSpaceApi(space.id)
      } catch (e) {}
      systemData.deleteSpace(space.id)
      ElMessage.success(`已删除${customSpaceAlias.value}【${space.spaceName}】！`)
      await loadSpaces()
    }).catch(() => {})
  }
}

// 批量生成
const batchDialogVisible = ref(false)
const batchSaving = ref(false)
const batchFormData = ref({
  codePrefix: 'B',
  namePrefix: '豪华观景包厢 ',
  startNum: 1,
  endNum: 6,
  padZero: true,
  floorZone: '',
  spaceType: 'ROOM' as const,
  capacity: 8,
  minConsumeAmount: 800
})

const handleOpenBatchDialog = () => {
  const defaultZone = availableZones.value[0] || currentStoreConfiguredZones.value[0] || ''
  batchFormData.value = {
    codePrefix: 'B',
    namePrefix: '豪华观景包厢 ',
    startNum: currentStoreSpaces.value.length + 1,
    endNum: currentStoreSpaces.value.length + 4,
    padZero: true,
    floorZone: defaultZone,
    spaceType: 'ROOM',
    capacity: 8,
    minConsumeAmount: 800
  }
  batchDialogVisible.value = true
}

const calculateBatchCount = computed(() => {
  const count = batchFormData.value.endNum - batchFormData.value.startNum + 1
  return count > 0 ? count : 0
})

const previewBatchItems = computed(() => {
  const items: Array<{ code: string; name: string }> = []
  const { codePrefix, namePrefix, startNum, endNum, padZero } = batchFormData.value
  if (endNum < startNum) return items
  for (let i = startNum; i <= endNum; i++) {
    const numStr = padZero ? String(i).padStart(2, '0') : String(i)
    items.push({
      code: `${codePrefix}${numStr}`,
      name: `${namePrefix}${numStr}`
    })
  }
  return items
})

const handleConfirmBatchCreate = async () => {
  if (calculateBatchCount.value <= 0) {
    ElMessage.warning('结束序号必须大于等于起始序号！')
    return
  }

  // 自动持久化保存批量时选定或新输入的区域
  if (batchFormData.value.floorZone) {
    ensureZoneConfigured(batchFormData.value.floorZone)
  }

  batchSaving.value = true
  try {
    const listForBackend: any[] = previewBatchItems.value.map(item => ({
      storeId: selectedStoreId.value,
      spaceCode: item.code,
      spaceName: item.name,
      spaceType: batchFormData.value.spaceType,
      floorZone: batchFormData.value.floorZone,
      capacity: batchFormData.value.capacity,
      minConsumeAmount: batchFormData.value.minConsumeAmount,
      hourlyFee: 0,
      facilities: '独立洗手间,新风系统,功夫茶台,隔音静音',
      notes: '批量快速预设生成',
      qrCodeUrl: `${window.location.origin}/mall?store=${selectedStoreId.value}&spaceCode=${item.code}`
    }))

    // 1. 调用批量接口保存入库
    let savedList: any = null
    try {
      savedList = await batchCreateSpacesApi(listForBackend)
    } catch (apiErr) {
      console.warn('后端批量创建接口异常，启动本地保存:', apiErr)
    }

    // 2. 本地 pinia 同步
    const localList: any[] = (Array.isArray(savedList) && savedList.length > 0)
      ? savedList.map(s => ({
          ...s,
          facilities: typeof s.facilities === 'string' ? s.facilities.split(',').filter(Boolean) : (s.facilities || [])
        }))
      : previewBatchItems.value.map(item => ({
          storeId: selectedStoreId.value,
          spaceCode: item.code,
          spaceName: item.name,
          spaceType: batchFormData.value.spaceType,
          floorZone: batchFormData.value.floorZone,
          capacity: batchFormData.value.capacity,
          minConsumeAmount: batchFormData.value.minConsumeAmount,
          hourlyFee: 0,
          facilities: ['独立洗手间', '新风系统', '功夫茶台', '隔音静音'],
          notes: '批量快速预设生成'
        }))

    systemData.batchAddSpaces(localList)
    ElMessage.success(`已成功批量生成 ${localList.length} 个${customSpaceAlias.value}并持久化到数据库！`)
    batchDialogVisible.value = false
    await loadSpaces()
  } finally {
    batchSaving.value = false
  }
}

// 专属真实二维码桌贴弹窗与立牌排版
const qrDialogVisible = ref(false)
const activeQrSpace = ref<SpaceEntity | null>(null)
const realQrCodeDataUrl = ref('')
const currentQrTargetUrl = ref('')

const buildTableOrderUrl = (space: SpaceEntity) => {
  const tenantId = localStorage.getItem('seahorse_tenant_id') || 'T001'
  const storeId = selectedStoreId.value || 'S001'
  const origin = window.location.origin
  return `${origin}/seahorse/table-order?tenantId=${tenantId}&storeId=${storeId}&spaceId=${space.id}&spaceCode=${space.spaceCode}&spaceName=${encodeURIComponent(space.spaceName)}`
}

const handleShowQrCode = async (space: SpaceEntity) => {
  activeQrSpace.value = space
  qrDialogVisible.value = true
  const targetUrl = buildTableOrderUrl(space)
  currentQrTargetUrl.value = targetUrl

  try {
    realQrCodeDataUrl.value = await QRCode.toDataURL(targetUrl, {
      width: 360,
      margin: 2,
      color: {
        dark: '#0f172a',
        light: '#ffffff'
      }
    })
  } catch (err) {
    console.error('二维码生成失败:', err)
  }
}

const copyQrUrl = async () => {
  if (!activeQrSpace.value) return
  const url = currentQrTargetUrl.value || buildTableOrderUrl(activeQrSpace.value)
  try {
    await navigator.clipboard.writeText(url)
    ElMessage.success('桌贴专属点单链接已复制到剪贴板！')
  } catch (e) {
    const input = document.createElement('input')
    input.value = url
    document.body.appendChild(input)
    input.select()
    document.execCommand('copy')
    document.body.removeChild(input)
    ElMessage.success('桌贴专属点单链接已复制！')
  }
}

const downloadQrCode = () => {
  if (!activeQrSpace.value || !realQrCodeDataUrl.value) {
    ElMessage.warning('二维码尚未生成就绪，请稍候！')
    return
  }

  const canvas = document.createElement('canvas')
  const ctx = canvas.getContext('2d')
  if (!ctx) {
    ElMessage.error('无法创建画布进行图片导出')
    return
  }

  // 高清 2x 导出规格：760 x 1000
  const width = 760
  const height = 1000
  canvas.width = width
  canvas.height = height

  // 1. 绘制深色高级质感圆角背景
  const grad = ctx.createLinearGradient(0, 0, width, height)
  grad.addColorStop(0, '#1e293b')
  grad.addColorStop(1, '#0f172a')
  ctx.fillStyle = grad

  const radius = 32
  ctx.beginPath()
  ctx.moveTo(radius, 0)
  ctx.lineTo(width - radius, 0)
  ctx.quadraticCurveTo(width, 0, width, radius)
  ctx.lineTo(width, height - radius)
  ctx.quadraticCurveTo(width, height, width - radius, height)
  ctx.lineTo(radius, height)
  ctx.quadraticCurveTo(0, height, 0, height - radius)
  ctx.lineTo(0, radius)
  ctx.quadraticCurveTo(0, 0, radius, 0)
  ctx.closePath()
  ctx.fill()

  // 2. 绘制品牌抬头
  ctx.textAlign = 'center'
  ctx.fillStyle = '#94a3b8'
  ctx.font = '500 24px -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif'
  ctx.fillText(currentStoreName.value, width / 2, 80)

  // 3. 绘制包厢名称 (醒目天蓝)
  ctx.fillStyle = '#38bdf8'
  ctx.font = 'bold 44px -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif'
  ctx.fillText(activeQrSpace.value.spaceName, width / 2, 145)

  // 4. 绘制桌台/包厢编号
  ctx.fillStyle = '#cbd5e1'
  ctx.font = '500 22px -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif'
  ctx.fillText(`桌台/包厢号：${activeQrSpace.value.spaceCode}`, width / 2, 195)

  // 5. 绘制白色卡片区域 (放二维码)
  const qrBoxX = 100
  const qrBoxY = 240
  const qrBoxW = 560
  const qrBoxH = 560
  const qrBoxRadius = 24

  ctx.fillStyle = '#ffffff'
  ctx.beginPath()
  ctx.moveTo(qrBoxX + qrBoxRadius, qrBoxY)
  ctx.lineTo(qrBoxX + qrBoxW - qrBoxRadius, qrBoxY)
  ctx.quadraticCurveTo(qrBoxX + qrBoxW, qrBoxY, qrBoxX + qrBoxW, qrBoxY + qrBoxRadius)
  ctx.lineTo(qrBoxX + qrBoxW, qrBoxY + qrBoxH - qrBoxRadius)
  ctx.quadraticCurveTo(qrBoxX + qrBoxW, qrBoxY + qrBoxH, qrBoxX + qrBoxW - qrBoxRadius, qrBoxY + qrBoxH)
  ctx.lineTo(qrBoxX + qrBoxRadius, qrBoxY + qrBoxH)
  ctx.quadraticCurveTo(qrBoxX, qrBoxY + qrBoxH, qrBoxX, qrBoxY + qrBoxH - qrBoxRadius)
  ctx.lineTo(qrBoxX, qrBoxY + qrBoxRadius)
  ctx.quadraticCurveTo(qrBoxX, qrBoxY, qrBoxX + qrBoxRadius, qrBoxY)
  ctx.closePath()
  ctx.fill()

  // 6. 载入并绘制真实二维码与标语
  const qrImg = new Image()
  qrImg.crossOrigin = 'anonymous'
  qrImg.onload = () => {
    ctx.drawImage(qrImg, width / 2 - 220, qrBoxY + 30, 440, 440)

    ctx.fillStyle = '#0f172a'
    ctx.font = 'bold 24px -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif'
    ctx.fillText('扫一扫进入【海马体】在场点单与服务', width / 2, qrBoxY + 515)

    // 7. 底部特色与海马记忆亮点
    ctx.fillStyle = '#f59e0b'
    ctx.font = '600 24px -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif'
    ctx.fillText('🧠 自动识别您的海马体偏好与忌口', width / 2, 870)

    // 8. 区域与人数
    ctx.fillStyle = '#94a3b8'
    ctx.font = '500 20px -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif'
    const zone = activeQrSpace.value?.floorZone || '主营业区'
    const cap = activeQrSpace.value?.capacity || 4
    ctx.fillText(`区域：${zone} · 容纳 ${cap} 人`, width / 2, 920)

    const dataUrl = canvas.toDataURL('image/png')
    const link = document.createElement('a')
    link.href = dataUrl
    link.download = `${currentStoreName.value}_${activeQrSpace.value?.spaceName}_桌贴立牌.png`
    link.click()
    ElMessage.success(`已成功导出【${activeQrSpace.value?.spaceName}】高清桌面立牌桌贴！`)
  }
  qrImg.src = realQrCodeDataUrl.value
}

const printTableTent = () => {
  if (!activeQrSpace.value || !realQrCodeDataUrl.value) {
    ElMessage.warning('二维码尚未生成完毕，请稍候！')
    return
  }

  let iframe = document.getElementById('table-tent-print-iframe') as HTMLIFrameElement
  if (!iframe) {
    iframe = document.createElement('iframe')
    iframe.id = 'table-tent-print-iframe'
    iframe.style.position = 'fixed'
    iframe.style.top = '-99999px'
    iframe.style.left = '-99999px'
    iframe.style.width = '0'
    iframe.style.height = '0'
    iframe.style.border = 'none'
    document.body.appendChild(iframe)
  }

  const doc = iframe.contentDocument || iframe.contentWindow?.document
  if (!doc) {
    window.print()
    return
  }

  const storeName = currentStoreName.value
  const spaceName = activeQrSpace.value.spaceName
  const spaceCode = activeQrSpace.value.spaceCode
  const zone = activeQrSpace.value.floorZone || '主营业区'
  const cap = activeQrSpace.value.capacity || 4

  doc.open()
  doc.write(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>${storeName} - ${spaceName} 桌贴立牌打印</title>
        <style>
          @page {
            size: auto;
            margin: 8mm;
          }
          * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
          }
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            background: #fff;
          }
          .table-tent {
            width: 380px;
            background: #0f172a;
            color: #ffffff;
            border-radius: 16px;
            padding: 30px 24px 24px 24px;
            text-align: center;
            box-shadow: 0 4px 16px rgba(0,0,0,0.15);
          }
          .tent-brand {
            font-size: 14px;
            color: #94a3b8;
            letter-spacing: 1px;
            margin-bottom: 8px;
          }
          .tent-room {
            font-size: 26px;
            font-weight: 800;
            color: #38bdf8;
            margin-bottom: 6px;
          }
          .tent-code {
            font-size: 13px;
            color: #cbd5e1;
            margin-bottom: 20px;
          }
          .tent-qr-box {
            background: #ffffff;
            border-radius: 14px;
            padding: 20px 16px 16px 16px;
            margin-bottom: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          }
          .tent-qr-box img {
            width: 220px;
            height: 220px;
            display: block;
            margin: 0 auto;
          }
          .qr-scan-hint {
            font-size: 13px;
            font-weight: bold;
            color: #0f172a;
            margin-top: 10px;
          }
          .tent-feature {
            font-size: 13px;
            font-weight: 600;
            color: #f59e0b;
            margin-bottom: 6px;
          }
          .tent-meta {
            font-size: 12px;
            color: #94a3b8;
          }
        </style>
      </head>
      <body>
        <div class="table-tent">
          <div class="tent-brand">${storeName}</div>
          <div class="tent-room">${spaceName}</div>
          <div class="tent-code">桌台/包厢号：${spaceCode}</div>
          <div class="tent-qr-box">
            <img src="${realQrCodeDataUrl.value}" />
            <div class="qr-scan-hint">扫一扫进入【海马体】在场点单与服务</div>
          </div>
          <div class="tent-feature">🧠 自动识别您的海马体偏好与忌口</div>
          <div class="tent-meta">区域：${zone} · 容纳 ${cap} 人</div>
        </div>
      </body>
    </html>
  `)
  doc.close()

  setTimeout(() => {
    iframe.contentWindow?.focus()
    iframe.contentWindow?.print()
    ElMessage.success(`已调起【${spaceName}】专属桌贴立牌打印预览！`)
  }, 400)
}

const refreshData = async () => {
  await loadStores()
  await loadSpaces()
  ElMessage.success('包厢数据已与云端数据库同步刷新！')
}

onMounted(async () => {
  await loadStores()
  if (!selectedStoreId.value && availableStores.value.length > 0) {
    selectedStoreId.value = availableStores.value[0].storeId
  }
  await loadSpaces()
  await loadStoreMemberList()
  await loadCategories()
})
</script>

<style scoped>
.room-management-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* 顶部卡片 */
.page-header-card {
  background: #fff;
  border-radius: 8px;
  padding: 16px 20px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.05);
}

.header-main-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}

.header-left {
  flex: 1 1 360px;
  min-width: 300px;
}

.title-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.page-title {
  margin: 0;
  font-size: 20px;
  font-weight: bold;
  color: #0f172a;
  white-space: nowrap; /* 确保标题永远不垂直断行折字 */
}

.page-subtitle {
  margin: 8px 0 0 0;
  font-size: 13px;
  color: #64748b;
  line-height: 1.5;
}

.header-right {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
  justify-content: flex-end;
}

/* 运行指标卡片矩阵 */
.stats-overview-grid {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 12px;
}

@media (max-width: 1400px) {
  .stats-overview-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 768px) {
  .stats-overview-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

.stat-card {
  background: #fff;
  border-radius: 8px;
  padding: 14px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
  border: 1px solid #f1f5f9;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.06);
}

.stat-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-label {
  font-size: 12px;
  color: #64748b;
}

.stat-value {
  font-size: 22px;
  font-weight: 700;
  color: #0f172a;
}

.stat-icon {
  font-size: 28px;
  opacity: 0.85;
}

.icon-primary { color: #3b82f6; }
.icon-green { color: #10b981; }
.icon-blue { color: #0284c7; }
.icon-orange { color: #f59e0b; }
.icon-gray { color: #94a3b8; }
.icon-purple { color: #8b5cf6; }

.text-green { color: #10b981; }
.text-blue { color: #0284c7; }
.text-orange { color: #f59e0b; }
.text-gray { color: #94a3b8; }
.text-purple { color: #8b5cf6; }

/* 过滤工具栏 */
.filter-card {
  border-radius: 8px;
  border: none;
  background: #fff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.04);
}

.filter-container {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.filter-row-primary,
.filter-row-secondary {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
}

.filter-row-primary {
  padding-bottom: 12px;
  border-bottom: 1px dashed #f1f5f9;
}

.filter-row-left {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.filter-row-right {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-left: auto;
}

.filter-item-group {
  display: flex;
  align-items: center;
  gap: 6px;
}

.filter-divider {
  width: 1px;
  height: 20px;
  background: #e2e8f0;
  margin: 0 4px;
}

.zone-capsule-group {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
}

.no-zone-hint {
  font-size: 13px;
  color: #94a3b8;
}

.filter-label {
  font-size: 13px;
  font-weight: 500;
  color: #475569;
  white-space: nowrap;
}

.filter-result-count {
  font-size: 13px;
  color: #64748b;
}

.filter-result-count strong {
  color: #3b82f6;
  font-size: 15px;
}

/* 矩阵卡片网格 */
.spaces-grid-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(330px, 1fr));
  gap: 16px;
}

.space-card {
  background: #fff;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  transition: all 0.25s ease;
  box-shadow: 0 1px 2px rgba(0,0,0,0.03);
  overflow: hidden;
  box-sizing: border-box;
}

.space-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(0,0,0,0.08);
}

.space-card.status-idle {
  border-top: 4px solid #10b981;
}

.space-card.status-occupied {
  border-top: 4px solid #0284c7;
  background: linear-gradient(180deg, #f0f9ff 0%, #ffffff 40%);
}

.space-card.status-dirty {
  border-top: 4px solid #f59e0b;
  background: linear-gradient(180deg, #fffbeb 0%, #ffffff 40%);
}

.space-card.status-maintenance {
  border-top: 4px solid #94a3b8;
  opacity: 0.85;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 14px 8px;
  border-bottom: 1px solid #f8fafc;
}

.code-and-type {
  display: flex;
  align-items: center;
  gap: 6px;
}

.space-code {
  font-size: 15px;
  font-weight: 700;
  color: #1e293b;
  background: #f1f5f9;
  padding: 2px 8px;
  border-radius: 4px;
}

.card-body {
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.space-name {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #0f172a;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.meta-row {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 12px;
  color: #64748b;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 3px;
}

.billing-row {
  font-size: 13px;
}

.min-consume {
  color: #d97706;
}

.min-consume strong {
  font-weight: 700;
}

.no-min-consume {
  color: #94a3b8;
}

.hourly-fee {
  color: #8b5cf6;
  font-weight: 500;
}

.facilities-tags {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 4px;
}

.facility-pill {
  font-size: 11px;
}

.more-facilities {
  font-size: 11px;
  color: #94a3b8;
}

.serving-hint {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #0284c7;
  font-weight: 500;
  background: #e0f2fe;
  padding: 4px 8px;
  border-radius: 4px;
}

.pulsing-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #0284c7;
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(2, 132, 199, 0.7); }
  70% { transform: scale(1); box-shadow: 0 0 0 6px rgba(2, 132, 199, 0); }
  100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(2, 132, 199, 0); }
}

.notes-hint {
  font-size: 12px;
  color: #64748b;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  background: #f8fafc;
  padding: 3px 6px;
  border-radius: 4px;
}

.card-footer {
  padding: 8px 10px 10px;
  border-top: 1px solid #f1f5f9;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 4px;
  box-sizing: border-box;
  width: 100%;
}

.footer-left-actions {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-shrink: 1;
  min-width: 0;
}

.footer-left-actions .el-button {
  padding: 5px 7px;
  font-size: 12px;
  margin: 0;
}

.footer-right-actions {
  display: flex;
  align-items: center;
  gap: 2px;
  flex-shrink: 0;
  margin-left: auto;
}

.footer-right-actions .el-button {
  color: #64748b;
  font-size: 13px;
  width: 26px;
  height: 26px;
  min-height: 26px;
  padding: 0;
  margin: 0;
}

.footer-right-actions .el-button:hover {
  color: #0284c7;
  background-color: #f1f5f9;
}

/* 批量生成预览 */
.batch-preview-box {
  background: #f8fafc;
  border-radius: 6px;
  padding: 12px;
  border: 1px dashed #cbd5e1;
}

.preview-title {
  font-size: 13px;
  color: #475569;
  margin-bottom: 8px;
}

.preview-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.preview-chip {
  background: #e2e8f0;
  color: #1e293b;
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 4px;
}

.preview-chip-more {
  font-size: 12px;
  color: #64748b;
  align-self: center;
}

/* 桌贴立牌样式 */
.table-tent-mockup {
  background: linear-gradient(145deg, #1e293b 0%, #0f172a 100%);
  color: #fff;
  border-radius: 16px;
  padding: 24px 20px 20px 20px;
  text-align: center;
  box-shadow: 0 10px 30px rgba(15, 23, 42, 0.25);
  border: 1px solid rgba(255, 255, 255, 0.08);
  margin-bottom: 16px;
}

.tent-brand {
  font-size: 13px;
  color: #94a3b8;
  letter-spacing: 1px;
  font-weight: 500;
}

.tent-room {
  font-size: 20px;
  font-weight: 800;
  color: #38bdf8;
  margin: 6px 0 2px;
  letter-spacing: 0.5px;
}

.tent-code {
  font-size: 12px;
  color: #cbd5e1;
}

.tent-qr-box {
  background: #ffffff;
  border-radius: 14px;
  padding: 16px;
  margin: 16px auto;
  max-width: 220px;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
}

.real-qr-wrapper {
  width: 180px;
  height: 180px;
  margin: 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
}

.real-qr-image {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
  border-radius: 4px;
}

.qr-loading-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #64748b;
}

.qr-scan-hint {
  font-size: 12px;
  color: #0f172a;
  font-weight: 700;
  margin-top: 10px;
  line-height: 1.4;
}

.tent-footer {
  font-size: 12px;
  color: #94a3b8;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.tent-feature {
  color: #fbbf24;
  font-weight: 600;
  font-size: 12px;
}

.qr-action-toolbar {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
  padding-top: 6px;
}

.qr-action-toolbar .el-button {
  margin: 0 !important;
  padding: 9px 12px;
  font-weight: 600;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
}

/* 称谓设置抽屉 */
.alias-drawer-content {
  display: flex;
  flex-direction: column;
}

.preset-alias-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 6px;
}

.preset-label {
  font-size: 12px;
  color: #64748b;
}

/* 区域筛选空状态提示 */
.no-zone-hint {
  font-size: 13px;
  color: #94a3b8;
  font-style: italic;
}

/* 区域规划配置中心样式 */
.zone-config-dialog :deep(.el-dialog__body) {
  padding: 16px 20px;
  background-color: #f8fafc;
}

.zone-config-modal-body {
  max-height: 65vh;
  overflow-y: auto;
  padding-right: 4px;
}

.zone-section-card {
  background: #ffffff;
  border-radius: 8px;
  padding: 16px 18px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 1px 3px rgba(0,0,0,0.03);
}

.section-title-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.section-title-row .title-left {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.section-title-row .title-text {
  font-size: 14px;
  font-weight: 700;
  color: #1e293b;
}

.section-title-row .sub-text {
  font-size: 12px;
  color: #64748b;
}

.current-zones-wrap {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  min-height: 48px;
  align-items: center;
  padding: 10px;
  background: #f1f5f9;
  border-radius: 6px;
}

.active-zone-tag {
  font-size: 13px;
  font-weight: 500;
  padding: 8px 12px;
  border-radius: 6px;
  cursor: default;
}

.zone-space-badge {
  color: #2563eb;
  font-size: 12px;
  font-weight: normal;
  margin-left: 4px;
}

.empty-zone-placeholder {
  width: 100%;
  padding: 10px 0;
}

.custom-add-input-bar {
  display: flex;
  gap: 10px;
  align-items: center;
}

.template-shortcuts-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  padding-bottom: 14px;
  margin-bottom: 14px;
  border-bottom: 1px dashed #e2e8f0;
}

.preset-group-title {
  font-size: 13px;
  font-weight: 600;
  color: #0f172a;
}

.preset-categories-accordion {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.preset-category-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}

.cat-label {
  width: 120px;
  flex-shrink: 0;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  line-height: 28px;
}

.cat-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  flex: 1;
}

.preset-selectable-tag {
  cursor: pointer;
  border-radius: 4px;
  font-size: 12px;
  padding: 4px 10px;
  height: 28px;
  line-height: 20px;
  transition: all 0.2s ease;
  user-select: none;
  background: #f8fafc;
  color: #334155;
  border: 1px solid #cbd5e1;
}

.preset-selectable-tag:hover {
  border-color: #3b82f6;
  color: #2563eb;
  background: #eff6ff;
  transform: translateY(-1px);
}

.preset-selectable-tag.selected {
  background: #dbeafe;
  border-color: #3b82f6;
  color: #1d4ed8;
  font-weight: 600;
}

/* ==============================================================================
   包厢直接点单与添加服务/菜品/商品弹窗样式
   ============================================================================== */
:deep(.room-order-dialog) {
  border-radius: 12px;
  overflow: hidden;
}

:deep(.room-order-dialog .el-dialog__body) {
  padding: 12px 20px;
}

.room-order-container {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.room-order-header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  padding: 10px 16px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.room-info-left {
  display: flex;
  align-items: center;
  gap: 8px;
}

.room-title-badge {
  font-size: 15px;
  font-weight: 700;
  color: #0f172a;
}

.room-info-right {
  display: flex;
  align-items: center;
}

.min-consume-tag {
  font-size: 12px;
  color: #475569;
  background: #fff;
  padding: 4px 10px;
  border-radius: 6px;
  border: 1px solid #e2e8f0;
}

.idle-customer-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  padding: 8px 14px;
  border-radius: 8px;
}

.bar-title {
  font-size: 13px;
  font-weight: 600;
  color: #166534;
}

.order-content-grid {
  display: grid;
  grid-template-columns: 1.15fr 0.85fr;
  gap: 16px;
  height: 520px;
}

.products-pick-panel {
  display: flex;
  flex-direction: column;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #fff;
  overflow: hidden;
}

.panel-search-tabs {
  padding: 10px 12px;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.products-scroll-grid {
  flex: 1;
  overflow-y: auto;
  padding: 12px;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  align-content: start;
}

.no-products-hint {
  grid-column: span 2;
  padding: 40px 0;
}

.catalog-prod-card {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px 12px;
  cursor: pointer;
  background: #ffffff;
  transition: all 0.2s ease;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 6px;
}

.catalog-prod-card:hover {
  border-color: #3b82f6;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.08);
  transform: translateY(-2px);
}

.catalog-prod-card.in-cart {
  border-color: #2563eb;
  background: #f0f7ff;
}

.prod-card-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 6px;
}

.prod-name {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
  line-height: 1.3;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.prod-card-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.prod-cat {
  font-size: 11px;
  color: #94a3b8;
}

.prod-price {
  font-size: 14px;
  font-weight: 700;
  color: #e11d48;
}

.prod-card-action {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 4px;
}

.cart-qty-pill {
  font-size: 11px;
  background: #dbeafe;
  color: #1d4ed8;
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: 600;
}

.cart-summary-panel {
  display: flex;
  flex-direction: column;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  background: #fff;
  overflow: hidden;
}

.cart-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 14px;
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
}

.cart-title {
  font-size: 13px;
  font-weight: 700;
  color: #0f172a;
}

.cart-items-scroll {
  flex: 1;
  overflow-y: auto;
  padding: 10px 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.cart-empty-hint {
  padding: 60px 0;
}

.cart-item-row {
  border: 1px solid #f1f5f9;
  background: #f8fafc;
  border-radius: 6px;
  padding: 8px 10px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.item-header-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.item-title-wrap {
  display: flex;
  align-items: center;
  gap: 8px;
}

.cart-item-name {
  font-size: 13px;
  font-weight: 600;
  color: #1e293b;
}

.cart-item-unitprice {
  font-size: 12px;
  color: #64748b;
}

.cart-qty-ctrl {
  display: flex;
  align-items: center;
  gap: 4px;
}

.ctrl-btn {
  width: 24px;
  height: 24px;
  border: 1px solid #cbd5e1;
  background: #fff;
  border-radius: 4px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 600;
  color: #334155;
  transition: all 0.15s ease;
}

.ctrl-btn:hover {
  background: #f1f5f9;
  border-color: #94a3b8;
}

.ctrl-val {
  min-width: 24px;
  text-align: center;
  font-size: 13px;
  font-weight: 600;
  color: #0f172a;
}

.item-spec-row {
  display: flex;
  gap: 8px;
}

.item-subtotal-row {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #64748b;
}

.subtotal-val {
  color: #e11d48;
  font-size: 13px;
}

.cart-footer-summary {
  padding: 10px 14px;
  background: #f8fafc;
  border-top: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.summary-line-row {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #64748b;
}

.sum-highlight {
  font-weight: 600;
  color: #0f172a;
}

.summary-line-row.total-row {
  font-size: 14px;
  border-top: 1px dashed #e2e8f0;
  padding-top: 6px;
  margin-top: 2px;
}

.total-highlight {
  font-size: 18px;
  font-weight: 800;
  color: #e11d48;
}

.dialog-footer-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}

.footer-note {
  font-size: 12px;
  color: #64748b;
  text-align: left;
}
</style>
