const app = getApp()

Page({
  data: {
    products: [],
    cart: [],
    totalAmount: 0
  },

  onLoad() {
    this.loadProducts()
  },

  loadProducts() {
    wx.request({
      url: `${app.globalData.baseUrl}/product/list`,
      header: { 'X-Store-Id': app.globalData.storeId },
      success: (res) => {
        if (res.data?.code === 200) {
          this.setData({ products: res.data.data })
        }
      }
    })
  },

  handleAddItem(e) {
    const item = e.currentTarget.dataset.item
    const cart = this.data.cart
    cart.push(item)
    const total = cart.reduce((sum, i) => sum + i.price, 0)
    this.setData({
      cart,
      totalAmount: total.toFixed(2)
    })
    wx.showToast({ title: '已加入待追加', icon: 'success' })
  },

  handleSubmitAppend() {
    if (this.data.cart.length === 0) return

    wx.showLoading({ title: '追加下单中...' })
    setTimeout(() => {
      wx.hideLoading()
      wx.showModal({
        title: '追加下单成功',
        content: '已同步推送至服务工位/后厨打印机，请稍候！',
        showCancel: false,
        success: () => {
          this.setData({ cart: [], totalAmount: 0 })
          wx.switchTab({ url: '/pages/index/index' })
        }
      })
    }, 600)
  }
})
