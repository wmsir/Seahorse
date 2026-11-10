const app = getApp()

Page({
  data: {
    profile: {
      member: {},
      dualBalance: {},
      timeCards: [],
      preferences: []
    }
  },

  onLoad() {
    this.loadMemberProfile()
  },

  onPullDownRefresh() {
    this.loadMemberProfile()
    wx.stopPullDownRefresh()
  },

  loadMemberProfile() {
    // 默认演示拉取 1 号会员 (林清雅) 的全量档案
    wx.request({
      url: `${app.globalData.baseUrl}/member/1/profile`,
      header: { 'X-Store-Id': app.globalData.storeId },
      success: (res) => {
        if (res.data?.code === 200) {
          this.setData({ profile: res.data.data })
        }
      }
    })
  }
})
