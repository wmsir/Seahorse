const app = getApp()

function requestAsync(options) {
  return new Promise((resolve, reject) => {
    wx.request({
      ...options,
      header: {
        'Content-Type': 'application/json',
        'X-Tenant-Id': app.globalData.tenantId,
        'X-Store-Id': app.globalData.storeId,
        ...(options.header || {})
      },
      success: (res) => resolve(res),
      fail: (err) => reject(err)
    })
  })
}

Page({
  data: {
    products: [],
    cart: [],
    selectedSpace: null,
    submitting: false,
    totalAmount: '0.00'
  },

  onLoad() {
    this.loadProducts()
  },

  onShow() {
    if (app.globalData.selectedSpace) {
      this.setData({ selectedSpace: app.globalData.selectedSpace })
    }
    if (app.globalData.pendingProduct) {
      const pending = app.globalData.pendingProduct
      app.globalData.pendingProduct = null
      this.appendToCart(pending)
    }
  },

  loadProducts() {
    requestAsync({
      url: `${app.globalData.baseUrl}/product/list?storeId=${app.globalData.storeId}`,
      method: 'GET'
    }).then((res) => {
      if (res.data?.code === 200 && Array.isArray(res.data.data)) {
        this.setData({ products: res.data.data })
      }
    }).catch(() => {})
  },

  appendToCart(item) {
    if (!item) return
    const cart = [...this.data.cart, item]
    const total = cart.reduce((sum, i) => sum + (Number(i.price) || 0), 0)
    this.setData({
      cart,
      totalAmount: total.toFixed(2)
    })
  },

  handleAddItem(e) {
    const item = e.currentTarget.dataset.item
    this.appendToCart(item)
    wx.showToast({ title: '已加入待追加', icon: 'success' })
  },

  async resolveTargetSpace() {
    if (this.data.selectedSpace && this.data.selectedSpace.id) {
      return this.data.selectedSpace
    }
    const res = await requestAsync({
      url: `${app.globalData.baseUrl}/space/list?storeId=${app.globalData.storeId}`,
      method: 'GET'
    })
    const spaces = res.data?.code === 200 && Array.isArray(res.data.data) ? res.data.data : []
    if (spaces.length === 0) {
      throw new Error('当前门店暂无可用桌台/包厢')
    }
    const chosen = spaces.find((s) => s.status === 'OCCUPIED') || spaces.find((s) => s.status === 'IDLE') || spaces[0]
    app.globalData.selectedSpace = chosen
    this.setData({ selectedSpace: chosen })
    return chosen
  },

  async ensureActiveSessionId(space) {
    const activeRes = await requestAsync({
      url: `${app.globalData.baseUrl}/session/active-list`,
      method: 'GET'
    })
    if (activeRes.data?.code === 200 && Array.isArray(activeRes.data.data)) {
      const matched = activeRes.data.data.find(
        (s) => Number(s.spaceId) === Number(space.id) && s.status !== 'CLOSED' && s.status !== 'SETTLED_WAIT_CLEAN'
      )
      if (matched && matched.id) {
        return matched.id
      }
    }

    const openRes = await requestAsync({
      url: `${app.globalData.baseUrl}/session/open`,
      method: 'POST',
      data: {
        spaceId: space.id,
        customerName: '小程序扫码贵宾',
        guestCount: 1,
        notes: '微信小程序自助开台点单'
      }
    })
    if (openRes.data?.code === 200 && openRes.data.data?.id) {
      return openRes.data.data.id
    }
    throw new Error(openRes.data?.message || '自动开台失败，请稍后重试')
  },

  async handleSubmitAppend() {
    if (this.data.cart.length === 0 || this.data.submitting) return

    this.setData({ submitting: true })
    wx.showLoading({ title: '追加下单中...' })

    try {
      const space = await this.resolveTargetSpace()
      const sessionId = await this.ensureActiveSessionId(space)

      const grouped = new Map()
      for (const item of this.data.cart) {
        const pid = Number(item.id) || 1
        const existing = grouped.get(pid)
        if (existing) {
          existing.quantity += 1
        } else {
          grouped.set(pid, {
            productId: pid,
            quantity: 1,
            modifiers: item.name || item.title || ''
          })
        }
      }

      const appendRes = await requestAsync({
        url: `${app.globalData.baseUrl}/session/append`,
        method: 'POST',
        data: {
          sessionId,
          items: Array.from(grouped.values()),
          operatorType: 'CUSTOMER',
          operatorName: '小程序顾客'
        }
      })

      if (appendRes.data?.code !== 200) {
        throw new Error(appendRes.data?.message || '追加下单失败')
      }

      wx.hideLoading()
      this.setData({ cart: [], totalAmount: '0.00', submitting: false })
      wx.showModal({
        title: '追加下单成功',
        content: `已同步推送至【${space.spaceName || space.name || '当前工位'}】，请稍候！`,
        showCancel: false,
        success: () => {
          wx.switchTab({ url: '/pages/index/index' })
        }
      })
    } catch (err) {
      wx.hideLoading()
      this.setData({ submitting: false })
      wx.showToast({
        title: (err && err.message) ? err.message : '网络异常，下单失败',
        icon: 'none',
        duration: 2500
      })
    }
  }
})
