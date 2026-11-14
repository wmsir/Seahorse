const app = getApp()

Page({
  data: {
    profile: {
      member: {},
      dualBalance: {},
      timeCards: [],
      preferences: []
    },
    principalDisplay: '0.00',
    giftDisplay: '0.00',
    totalDisplay: '0.00'
  },

  onLoad() {
    this.loadMemberProfile()
  },

  onPullDownRefresh() {
    this.loadMemberProfile(() => {
      wx.stopPullDownRefresh()
    })
  },

  loadMemberProfile(done) {
    // 通过免登会员自助中心接口拉取当前会员完整画像
    wx.request({
      url: `${app.globalData.baseUrl}/member-portal/profile`,
      data: { memberId: 1 },
      header: {
        'X-Tenant-Id': app.globalData.tenantId,
        'X-Store-Id': app.globalData.storeId
      },
      success: (res) => {
        if (res.data?.code === 200 && res.data.data) {
          const data = res.data.data
          const principal = Number(data.dualBalance?.principalBalance ?? 0) || 0
          const gift = Number(data.dualBalance?.giftBalance ?? 0) || 0
          this.setData({
            profile: data,
            principalDisplay: principal.toFixed(2),
            giftDisplay: gift.toFixed(2),
            totalDisplay: (principal + gift).toFixed(2)
          })
        }
      },
      complete: () => {
        if (typeof done === 'function') done()
      }
    })
  }
})
