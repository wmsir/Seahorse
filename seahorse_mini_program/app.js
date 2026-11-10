App({
  globalData: {
    baseUrl: 'http://localhost:8082/api',
    tenantId: 'T001',
    storeId: 'S001',
    memberInfo: null,
    currentSession: null
  },
  onLaunch() {
    console.log('海马智慧门店顾客端小程序启动 - 记住每位好客。')
  }
})
