const app = getApp()

Page({
  data: {
    selectedChannel: 'WECHAT'
  },

  handleChannelChange(e) {
    this.setData({ selectedChannel: e.detail.value })
  },

  handleDoPay() {
    wx.showLoading({ title: '正在调起支付...' })
    setTimeout(() => {
      wx.hideLoading()
      wx.showToast({ title: '支付成功！', icon: 'success' })
      setTimeout(() => {
        wx.switchTab({ url: '/pages/index/index' })
      }, 1500)
    }, 800)
  }
})
