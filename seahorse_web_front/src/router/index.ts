import { createRouter, createWebHistory } from 'vue-router'
import MainLayout from '../layout/MainLayout.vue'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: { title: '员工登录' }
  },
  {
    path: '/tenant-register',
    name: 'TenantRegister',
    component: () => import('../views/TenantRegister.vue'),
    meta: { title: 'SaaS 租户开店入驻与试用开通' }
  },
  {
    path: '/register',
    name: 'TenantRegisterAlias',
    component: () => import('../views/TenantRegister.vue'),
    meta: { title: 'SaaS 租户开店入驻与试用开通' }
  },
  {
    path: '/member-register',
    name: 'MemberRegister',
    component: () => import('../views/MemberRegister.vue'),
    meta: { title: '顾客会员自助开卡' }
  },
  {
    path: '/staff-register',
    name: 'StaffRegister',
    component: () => import('../views/StaffRegister.vue'),
    meta: { title: '员工入职申请与开号' }
  },
  {
    path: '/job-apply',
    name: 'JobApply',
    component: () => import('../views/JobApply.vue'),
    meta: { title: '门店职位招聘与在线应聘' }
  },
  {
    path: '/table-order',
    name: 'TableOrder',
    component: () => import('../views/TableOrder.vue'),
    meta: { title: '包厢专属聚合点单' }
  },
  {
    path: '/member/benefits',
    name: 'MemberBenefits',
    component: () => import('../views/MemberBenefits.vue'),
    meta: { title: '顾客会员权益与门店主页' }
  },
  {
    path: '/member-benefits',
    redirect: '/member/benefits'
  },
  {
    path: '/',
    component: MainLayout,
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('../views/Dashboard.vue'),
        meta: { title: '系统首页', icon: 'Odometer' }
      },
      {
        path: 'members',
        name: 'Members',
        component: () => import('../views/MemberCenter.vue'),
        meta: { title: '会员管理', icon: 'User' }
      },
      {
        path: 'rooms',
        name: 'Rooms',
        component: () => import('../views/RoomManagement.vue'),
        meta: { title: '包厢管理', icon: 'House' }
      },
      {
        path: 'products',
        name: 'Products',
        component: () => import('../views/ProductManagement.vue'),
        meta: { title: '项目商品', icon: 'Goods' }
      },
      {
        path: 'card-template',
        name: 'CardTemplate',
        component: () => import('../views/CardTemplateConfig.vue'),
        meta: { title: '会员卡设置', icon: 'CreditCard' }
      },
      {
        path: 'staff-management',
        name: 'StaffManagement',
        component: () => import('../views/StaffManagement.vue'),
        meta: { title: '员工管理', icon: 'UserFilled' }
      },
      {
        path: 'marketing',
        name: 'Marketing',
        component: () => import('../views/MarketingCenter.vue'),
        meta: { title: '营销裂变', icon: 'TrendCharts' }
      },
      {
        path: 'mall',
        name: 'Mall',
        component: () => import('../views/MicroMall.vue'),
        meta: { title: '微商城', icon: 'Shop' }
      },
      {
        path: 'appointments',
        name: 'Appointments',
        component: () => import('../views/AppointmentManagement.vue'),
        meta: { title: '预约管理', icon: 'Calendar' }
      },
      {
        path: 'chain',
        name: 'Chain',
        component: () => import('../views/ChainManagement.vue'),
        meta: { title: '连锁管理', icon: 'OfficeBuilding' }
      },
      {
        path: 'expenses',
        name: 'Expenses',
        component: () => import('../views/StoreLedger.vue'),
        meta: { title: '门店账本', icon: 'Money' }
      },
      {
        path: 'cost-center',
        name: 'CostCenter',
        component: () => import('../views/StoreLedger.vue'),
        meta: { title: '门店账本 · 成本分析', icon: 'PieChart' }
      },
      {
        path: 'inventory',
        name: 'Inventory',
        component: () => import('../views/InventoryManagement.vue'),
        meta: { title: '库存管理', icon: 'Box' }
      },
      {
        path: 'reports',
        name: 'Reports',
        component: () => import('../views/ReportAnalytics.vue'),
        meta: { title: '统计报表', icon: 'DataAnalysis' }
      },
      {
        path: 'reports/:tab',
        name: 'ReportDetail',
        component: () => import('../views/ReportAnalytics.vue'),
        meta: { title: '统计报表', icon: 'DataAnalysis' }
      },
      {
        path: 'regulations',
        name: 'Regulations',
        component: () => import('../views/StoreRegulations.vue'),
        meta: { title: '门店规章制度与员工协同', icon: 'Document' }
      },
      {
        path: 'sms-records',
        name: 'SmsRecords',
        component: () => import('../views/SmsRecords.vue'),
        meta: { title: '短信发送与管理记录', icon: 'Message' }
      },
      {
        path: 'settings',
        name: 'Settings',
        component: () => import('../views/SystemSettings.vue'),
        meta: { title: '店铺设置', icon: 'Setting' }
      },
      {
        path: 'payment-settings',
        name: 'PaymentSettings',
        component: () => import('../views/SystemSettings.vue'),
        meta: { title: '扫码盒子与支付通道', icon: 'CreditCard' }
      },
      {
        path: 'map-settings',
        name: 'MapSettings',
        component: () => import('../views/SystemSettings.vue'),
        meta: { title: '考勤定位', icon: 'Location' }
      },
      {
        path: 'job-posts',
        name: 'JobPosts',
        component: () => import('../views/SystemSettings.vue'),
        meta: { title: '部门架构与岗位管理', icon: 'Briefcase' }
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('../views/UserProfile.vue'),
        meta: { title: '个人中心', icon: 'Avatar' }
      },
      // 辅助兼容页面
      {
        path: 'session-board',
        name: 'SessionBoard',
        component: () => import('../views/SessionBoard.vue'),
        meta: { title: '工位/桌台看板', icon: 'Grid' }
      },
      {
        path: 'cashier',
        name: 'Cashier',
        component: () => import('../views/Cashier.vue'),
        meta: { title: '组合收银结算台', icon: 'Money' }
      },
      {
        path: 'shift',
        name: 'Shift',
        component: () => import('../views/ShiftHandover.vue'),
        meta: { title: '收银交班与盲盘', icon: 'Checked' }
      },
      {
        path: 'industry-config',
        name: 'IndustryConfig',
        component: () => import('../views/IndustryConfig.vue'),
        meta: { title: '行业模态配置', icon: 'Setting' }
      },
      {
        path: 'staff-permissions',
        name: 'StaffPermissions',
        component: () => import('../views/StaffPermissionConfig.vue'),
        meta: { title: '店员角色权限配置', icon: 'UserFilled' }
      },
      {
        path: 'member-portal',
        name: 'MemberPortal',
        component: () => import('../views/MemberPortal.vue'),
        meta: { title: '顾客会员档案主页', icon: 'Avatar' }
      },
      {
        path: 'platform-dashboard',
        name: 'PlatformDashboard',
        component: () => import('../views/PlatformDashboard.vue'),
        meta: { title: '平台营收与运营大盘', icon: 'DataAnalysis' }
      },
      {
        path: 'vendor-tenants',
        name: 'VendorTenants',
        component: () => import('../views/VendorTenants.vue'),
        meta: { title: '租户订阅与门店管控', icon: 'OfficeBuilding' }
      },
      {
        path: 'vendor-campaigns',
        name: 'VendorCampaigns',
        component: () => import('../views/VendorCampaigns.vue'),
        meta: { title: 'SaaS 营销与促销策略库', icon: 'Present' }
      },
      {
        path: 'vendor-activity',
        name: 'VendorActivity',
        component: () => import('../views/VendorActivity.vue'),
        meta: { title: '租户活跃与时段分析', icon: 'TrendCharts' }
      },
      {
        path: 'vendor-billings',
        name: 'VendorBillings',
        component: () => import('../views/VendorBillings.vue'),
        meta: { title: 'SaaS订阅与存储流水', icon: 'Money' }
      },
      {
        path: 'vendor-feedback',
        name: 'VendorFeedback',
        component: () => import('../views/VendorFeedback.vue'),
        meta: { title: '平台建言与需求受理', icon: 'Promotion' }
      },
      {
        path: 'vendor-plans',
        name: 'VendorPlans',
        component: () => import('../views/VendorPlans.vue'),
        meta: { title: '套餐定价与试用配置', icon: 'Setting' }
      },
      {
        path: 'vendor-industry-presets',
        name: 'VendorIndustryPresets',
        component: () => import('../views/VendorIndustryPresets.vue'),
        meta: { title: '常用行业预设全景配置', icon: 'SetUp' }
      },
      {
        path: 'vendor-permissions',
        name: 'VendorPermissions',
        component: () => import('../views/VendorPermissions.vue'),
        meta: { title: '角色权限全局配置', icon: 'Key' }
      },
      {
        path: 'vendor-developer-notif',
        name: 'VendorDeveloperNotif',
        component: () => import('../views/VendorDeveloperNotif.vue'),
        meta: { title: '全渠道公众号对接', icon: 'Connection' }
      },
      {
        path: 'vendor',
        name: 'VendorConsole',
        component: () => import('../views/VendorTenants.vue'),
        meta: { title: '开发商运维控制台', icon: 'Platform' }
      },
      {
        path: 'member-detail/:id',
        name: 'MemberDetail',
        component: () => import('../views/MemberDetail.vue'),
        meta: { title: '会员详情', icon: 'User' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

// 路由全局守卫：统一鉴权与员工可见页签权限拦截
router.beforeEach((to, _from, next) => {
  // 0. 兼容性支持：若通过 hash (如 /settings#/job-apply 或 /#/job-apply) 访问，自动重定向至纯净独立求职页面
  if (typeof window !== 'undefined' && window.location.hash && window.location.hash.includes('/job-apply')) {
    const rawHash = window.location.hash
    const applyIdx = rawHash.indexOf('/job-apply')
    const targetPathWithQuery = rawHash.substring(applyIdx)
    window.location.hash = ''
    return next(targetPathWithQuery)
  }

  // 设置页面标题
  if (to.meta && to.meta.title) {
    document.title = `${to.meta.title} - 海马智慧门店系统`
  }

  // 1. 兼容老链接：如果带 type=member 或 type=staff 访问 /register，自动重定向到对应独立 URL
  if (to.path === '/register') {
    if (to.query.type === 'member') {
      return next({ path: '/member-register', query: { storeId: to.query.storeId } })
    }
    if (to.query.type === 'staff') {
      return next({ path: '/staff-register', query: { storeId: to.query.storeId } })
    }
  }

  // 1.5 支持 FWPT 统一通行证 (OneID) ?sso_token= 单点免密直达
  try {
    const rawSsoToken = (to.query.sso_token as string) || new URLSearchParams(window.location.search).get('sso_token')
    if (rawSsoToken) {
      localStorage.setItem('fwpt_token', rawSsoToken)
      localStorage.setItem('seahorse_token', rawSsoToken)
      let uname = 'admin'
      let rname = 'FWPT通行证用户'
      try {
        const parts = rawSsoToken.split('.')
        if (parts.length === 3) {
          const b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/')
          const payload = JSON.parse(decodeURIComponent(escape(window.atob(b64))))
          if (payload && payload.sub) {
            uname = payload.sub
            rname = payload.realName || payload.sub
          }
        }
      } catch (_e) {}
      const isDev = uname.toLowerCase() === 'admin'
      const existingStoreId = localStorage.getItem('seahorse_store_id') || 'S001'
      const existingTenantId = localStorage.getItem('seahorse_tenant_id') || 'T001'
      const existingTenantName = localStorage.getItem('seahorse_tenant_name') || '海马智慧商业连锁集团'
      localStorage.setItem('seahorse_user', rname)
      localStorage.setItem('seahorse_username', uname)
      localStorage.setItem('seahorse_real_name', rname)
      localStorage.setItem('seahorse_role', isDev ? 'PLATFORM_DEVELOPER' : (localStorage.getItem('seahorse_role') || 'SUPER_ADMIN'))
      localStorage.setItem('seahorse_store_id', existingStoreId)
      localStorage.setItem('seahorse_tenant_id', existingTenantId)
      localStorage.setItem('seahorse_tenant_name', existingTenantName)
      localStorage.setItem('seahorse_plan', localStorage.getItem('seahorse_plan') || 'FLAGSHIP')
      localStorage.removeItem('seahorse_user_menu_paths')
      localStorage.removeItem('seahorse_allowed_stores')
      localStorage.removeItem('seahorse_staff_id')
      if (to.path === '/login' || to.path === '/') {
        return next(isDev ? '/platform-dashboard' : '/dashboard')
      }
    }
  } catch (_err) {}

  // 2. 登录页、租户注册页、对外自助开卡/员工入职页、求职微页面、包厢专属扫码点餐、顾客小票会员主页直接放行 (免登录)
  const publicPaths = ['/login', '/tenant-register', '/register', '/member-register', '/staff-register', '/job-apply', '/table-order', '/member/benefits', '/member-benefits']
  if (publicPaths.includes(to.path)) {
    return next()
  }

  // 2. 未登录统一重定向到登录页
  const token = localStorage.getItem('seahorse_token')
  if (!token) {
    return next('/login')
  }

  const role = localStorage.getItem('seahorse_role') || ''

  // 2.5 扫码盒与支付通道权限守卫：非超级管理员严禁访问支付通道配置，一律重定向至工作台
  const isSuperAdminRole = role === 'SUPER_ADMIN' || role === 'PLATFORM_DEVELOPER' || role === 'PLATFORM_ADMIN' || role === 'PLATFORM_SUPER_ADMIN'
  if (to.path === '/payment-settings' && !isSuperAdminRole) {
    return next('/dashboard')
  }

  // 3. 开发商专席重定向
  if (role === 'PLATFORM_DEVELOPER') {
    const devAllowedPaths = [
      '/platform-dashboard',
      '/vendor-tenants',
      '/vendor-campaigns',
      '/vendor-activity',
      '/vendor-billings',
      '/vendor-feedback',
      '/vendor-plans',
      '/vendor-industry-presets',
      '/vendor-permissions',
      '/vendor-developer-notif',
      '/payment-settings',
      '/map-settings',
      '/settings',
      '/vendor',
      '/profile'
    ]
    if (devAllowedPaths.includes(to.path)) {
      return next()
    }
    return next('/platform-dashboard')
  }

  // 4. 顾客会员专席重定向
  if (role === 'CUSTOMER_MEMBER') {
    if (to.path === '/member-portal' || to.path === '/profile') {
      return next()
    }
    return next('/member-portal')
  }

  // 5. 租户老板拥有业务豁免权限（平台总控级支付通道与考勤定位仅限平台开发维护人）
  if (role === 'SUPER_ADMIN' || role === 'MERCHANT_ADMIN' || role === 'TENANT_ADMIN') {
    if (to.path === '/payment-settings' || to.path === '/map-settings') {
      return next('/settings')
    }
    return next()
  }

  // 6. 员工岗位按租户配置的【可见与可用功能页签】进行权限校验与越权拦截
  try {
    const rawPaths = localStorage.getItem('seahorse_user_menu_paths')
    if (rawPaths) {
      const allowedPaths: string[] = JSON.parse(rawPaths)
      if (Array.isArray(allowedPaths) && allowedPaths.length > 0) {
        const path = to.path
        const isAllowed =
          path === '/profile' ||
          path === '/regulations' ||
          allowedPaths.includes(path) ||
          (path.startsWith('/reports') && allowedPaths.includes('/reports')) ||
          (path.startsWith('/member-detail') && allowedPaths.includes('/members')) ||
          (['/session-board', '/cashier', '/shift'].includes(path) && allowedPaths.includes('/dashboard'))

        if (!isAllowed) {
          // 越权拦截，自动跳转至该员工拥有的首个合法页签
          const fallback = allowedPaths[0] || '/profile'
          return next(fallback)
        }
      }
    }
  } catch (e) {
    console.warn('Check menu permission error:', e)
  }

  next()
})

export default router
