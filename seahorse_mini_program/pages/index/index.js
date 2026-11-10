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
    this.loadSpaces()
    wx.stopPullDownRefresh()
  },

  loadStoreInfo() {
    wx.request({
      url: `${app.globalData.baseUrl}/industry/current`,
      header: { 'X-Store-Id': app.globalData.storeId },
      success: (res) => {
        if (res.data?.code === 200) {
          this.setData({ storeInfo: res.data.data })
        }
      }
    })
  },

  loadSpaces() {
    wx.request({
      url: `${app.globalData.baseUrl}/space/list`,
      header: { 'X-Store-Id': app.globalData.storeId },
      success: (res) => {
        if (res.data?.code === 200) {
          this.setData({ spaces: res.data.data })
        }
      }
    })
  },

  loadHotProducts() {
    wx.request({
      url: `${app.globalData.baseUrl}/product/list`,
      header: { 'X-Store-Id': app.globalData.storeId },
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
    wx.switchTab({ url: '/pages/order/order' })
  },

  handleDirectOrder(e) {
    wx.switchTab({ url: '/pages/order/order' })
  }
})
