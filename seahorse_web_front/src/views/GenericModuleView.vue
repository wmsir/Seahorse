<template>
  <div class="generic-module-page">
    <el-card shadow="never">
      <div class="module-header">
        <div class="header-left">
          <span class="module-icon">{{ currentMeta.iconText }}</span>
          <div>
            <h3 class="module-title">{{ currentMeta.title }}</h3>
            <p class="module-desc">{{ currentMeta.desc }}</p>
          </div>
        </div>
        <el-button type="primary" icon="Plus">新建业务工单 / 策略</el-button>
      </div>

      <div class="stat-cards-grid">
        <div v-for="s in currentMeta.stats" :key="s.label" class="stat-card">
          <div class="stat-lbl">{{ s.label }}</div>
          <div class="stat-num">{{ s.val }}</div>
          <div class="stat-tip">{{ s.tip }}</div>
        </div>
      </div>

      <div style="margin-top: 24px;">
        <el-tabs v-model="activeTab">
          <el-tab-pane label="实时运营总览" name="overview">
            <el-table :data="currentMeta.tableData" border style="margin-top: 12px;">
              <el-table-column prop="code" label="单据/编号" width="160" />
              <el-table-column prop="name" label="业务项 / 名称" />
              <el-table-column prop="status" label="状态" width="120">
                <template #default="{ row }">
                  <el-tag :type="row.statusTag ? row.statusTag : 'success'" size="small">{{ row.status }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="amount" label="涉及金额(元)" width="140" />
              <el-table-column prop="operator" label="经办人" width="120" />
              <el-table-column prop="time" label="更新时间" width="160" />
              <el-table-column label="操作" width="110">
                <template #default>
                  <el-button link type="primary">查看详情</el-button>
                </template>
              </el-table-column>
            </el-table>
          </el-tab-pane>
          <el-tab-pane label="策略与规则配置" name="rules">
            <el-empty description="自动化策略运行正常，参数配置已按租户套餐全局生效。" />
          </el-tab-pane>
        </el-tabs>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const activeTab = ref('overview')

const metaMap: Record<string, any> = {
  marketing: {
    title: '营销裂变中心',
    iconText: '📈',
    desc: '裂变分销、老带新拼团、优惠券核销与会员推荐奖励管理',
    stats: [
      { label: '活动裂变人次', val: '1,280 人', tip: '较上周环比 +15%' },
      { label: '优惠券核销率', val: '76.4%', tip: '已核销 452 张' },
      { label: '转介绍新增会员', val: '48 位', tip: '推荐返利已自动发放' }
    ],
    tableData: [
      { code: 'MKT20240501', name: '老带新特权礼包发放', status: '进行中', amount: '3,200', operator: '李店长', time: '2024-05-01 10:00' },
      { code: 'MKT20240428', name: '五一劳动节充值返券活动', status: '已结束', amount: '12,500', operator: '系统自动', time: '2024-04-28 18:30' }
    ]
  },
  mall: {
    title: '微商城运营管理',
    iconText: '🏬',
    desc: '线上商城、次卡在线购买、到店自提与配送订单调度',
    stats: [
      { label: '今日线上销售', val: '￥3,480.00', tip: '共 18 笔订单' },
      { label: '待核销自提单', val: '6 笔', tip: '到店即享快速履约' },
      { label: '商城访客数', val: '520 PV', tip: '转化率 3.4%' }
    ],
    tableData: [
      { code: 'MAL2024050101', name: '欧莱雅洗护套装 (线上直购)', status: '待自提', amount: '268.00', operator: '线上顾客', time: '2024-05-01 12:15' },
      { code: 'MAL2024050102', name: '300元8折卡【在线办理】', status: '已生效', amount: '300.00', operator: '林清雅', time: '2024-05-01 09:30' }
    ]
  },
  appointments: {
    title: '预约排班管理',
    iconText: '📅',
    desc: '客户线上线下预约、技师排班日历与工位防撞单中枢',
    stats: [
      { label: '今日预约总数', val: '12 场', tip: '已履约 8 场' },
      { label: '指定技师率', val: '83.3%', tip: '托尼总监预约满档' },
      { label: '平均等候时长', val: '0 分钟', tip: '准点到店零等待' }
    ],
    tableData: [
      { code: 'APT2024050101', name: '尊享特色服务/商品体验 (李清雅)', status: '已到店履约', amount: '88.00', operator: '资深顾问', time: '14:30 - 15:15' },
      { code: 'APT2024050102', name: '玫瑰精油深层SPA (张浩然)', status: '待履约', amount: '220.00', operator: '李博', time: '16:00 - 17:00' }
    ]
  },
  chain: {
    title: '连锁多店协同管理',
    iconText: '🏢',
    desc: '跨店结算、跨店会员卡通用、多门店资金调拨与权限总控',
    stats: [
      { label: '连锁总分店数', val: '3 家', tip: '美业旗舰、潮汕牛肉锅、汽修' },
      { label: '跨店消费笔数', val: '42 笔', tip: '双轨储值全店通刷' },
      { label: '多店总营收', val: '￥32,680.00', tip: '按日自动结算' }
    ],
    tableData: [
      { code: 'CHN001', name: '海马美业·旗舰体验中心 (S001)', status: '营业中', amount: '18,500.00', operator: '李店长', time: '09:30 - 22:00' },
      { code: 'CHN002', name: '海马潮汕牛肉养生火锅 (S002)', status: '营业中', amount: '9,200.00', operator: '王店长', time: '10:30 - 22:30' },
      { code: 'CHN003', name: '海马精工汽车深度养护中心 (S003)', status: '营业中', amount: '4,980.00', operator: '张主管', time: '08:30 - 20:00' }
    ]
  },
  expenses: {
    title: '门店日常支出管理',
    iconText: '💸',
    desc: '房租水电、耗材物料采购、日常报销与杂费支出记账',
    stats: [
      { label: '本月支出总计', val: '￥14,200.00', tip: '预算使用率 62%' },
      { label: '耗材原料采购', val: '￥8,400.00', tip: '欧莱雅染膏与精油' },
      { label: '房租水电杂费', val: '￥5,800.00', tip: '已按期足额缴纳' }
    ],
    tableData: [
      { code: 'EXP2024050101', name: '欧莱雅沙龙级染膏采购入库', status: '已报销', amount: '3,200.00', operator: '李店长', time: '2024-05-01' },
      { code: 'EXP2024042002', name: '门店光纤宽带与电话费', status: '已扣款', amount: '480.00', operator: '财务', time: '2024-04-20' }
    ]
  },
  inventory: {
    title: '商品耗材与库存管理',
    iconText: '📦',
    desc: '原液耗材BOM扣减、商品进销存、安全库存预警与盘点',
    stats: [
      { label: '在库商品品类', val: '24 种', tip: '涵盖耗材、洗护与配件' },
      { label: '库存资产估值', val: '￥48,600.00', tip: '周转天数 18 天' },
      { label: '预警缺货项', val: '0 项', tip: '全量原料储备充足' }
    ],
    tableData: [
      { code: 'MAT01', name: '欧莱雅沙龙级精油染烫膏', status: '库存充裕', amount: '120 支', operator: '仓管', time: '今日盘点' },
      { code: 'MAT02', name: '大马士革玫瑰头皮精油', status: '库存正常', amount: '85 瓶', operator: '仓管', time: '昨日盘点' },
      { code: 'MAT03', name: '美孚1号全合成机油 0W-20', status: '库存充裕', amount: '60 升', operator: '仓管', time: '今日盘点' }
    ]
  },
  reports: {
    title: '综合经营统计报表',
    iconText: '⏱️',
    desc: '每日营业汇总、技师绩效提成报表、会员复购率与品类销售占比',
    stats: [
      { label: '累计营业额', val: '￥58,920.00', tip: '环比上月 +22.4%' },
      { label: '会员复购频次', val: '3.6 次/月', tip: '老客忠诚度显著提升' },
      { label: '毛利贡献率', val: '68.5%', tip: '服务项目高毛利带动' }
    ],
    tableData: [
      { code: 'RPT20240501', name: '2024年5月第一周营收分析表', status: '已生成', amount: '￥18,500.00', operator: '系统自动', time: '2024-05-01' },
      { code: 'RPT20240430', name: '4月份全店技师提成与工时汇总', status: '已核算', amount: '￥8,420.00', operator: '财务归档', time: '2024-04-30' }
    ]
  }
}

const currentMeta = computed(() => {
  const path = route.path.replace('/', '')
  return metaMap[path] || metaMap['marketing']
})
</script>

<style scoped>
.generic-module-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.module-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 16px;
  border-bottom: 1px solid #f1f5f9;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 14px;
}

.module-icon {
  font-size: 32px;
}

.module-title {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
  margin: 0;
}

.module-desc {
  font-size: 13px;
  color: #64748b;
  margin: 4px 0 0 0;
}

.stat-cards-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-top: 16px;
}

.stat-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 16px;
}

.stat-lbl {
  font-size: 13px;
  color: #64748b;
}

.stat-num {
  font-size: 24px;
  font-weight: 700;
  color: #0f172a;
  margin: 8px 0;
}

.stat-tip {
  font-size: 12px;
  color: #10b981;
}
</style>
