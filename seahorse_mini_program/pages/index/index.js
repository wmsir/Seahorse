const app = getApp()

Page({
  data: {
    storeInfo: {},
    spaces: [],
    hotProducts: []
  },

  onLoad() {
    this.loadStoreInfo()
    this.loadSpaces()
    this.loadHotProducts()
  },

  onPullDownRefresh() {
    this.loadSpaces(() => {
      wx.stopPullDownRefresh()
    })
  },

  loadStoreInfo() {
    wx.request({
      url: `${app.globalData.baseUrl}/industry/current`,
      header: {
        'X-Tenant-Id': app.globalData.tenantId,
        'X-Store-Id': app.globalData.storeId
      },
      success: (res) => {
        if (res.data?.code === 200) {
          this.setData({ storeInfo: res.data.data })
        }
      }
    })
  },

  loadSpaces(done) {
    wx.request({
      url: `${app.globalData.baseUrl}/space/list`,
      header: {
        'X-Tenant-Id': app.globalData.tenantId,
        'X-Store-Id': app.globalData.storeId
      },
      success: (res) => {
        if (res.data?.code === 200) {
          this.setData({ spaces: res.data.data })
        }
      },
      complete: () => {
        if (typeof done === 'function') done()
      }
    })
  },

  loadHotProducts() {
    wx.request({
      url: `${app.globalData.baseUrl}/product/list`,
      header: {
        'X-Tenant-Id': app.globalData.tenantId,
        'X-Store-Id': app.globalData.storeId
      },
      success: (res) => {
        if (res.data?.code === 200) {
          this.setData({ hotProducts: res.data.data })
        }
      }
    })
  },

  handleScanTable() {
    wx.scanCode({
      success: (res) => {
        if (res && res.result) {
          app.globalData.scannedCode = res.result
        }
        wx.showToast({ title: '扫码联动成功', icon: 'success' })
        wx.switchTab({ url: '/pages/order/order' })
      },
      fail: () => {
        // 模拟扫码进入
        wx.switchTab({ url: '/pages/order/order' })
      }
    })
  },

  handleSelectSpace(e) {
    const item = e.currentTarget.dataset.item
    if (item) {
      app.globalData.selectedSpace = item
    }
    wx.switchTab({ url: '/pages/order/order' })
  },

  handleDirectOrder(e) {
    const item = e.currentTarget.dataset.item
    if (item) {
      app.globalData.pendingProduct = item
    }
    wx.switchTab({ url: '/pages/order/order' })
  }
})
