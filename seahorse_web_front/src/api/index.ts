import request from './request'

// 认证与租户入驻
export const loginApi = (data: any, silent = false) =>
  request.post('/auth/login', data, { headers: silent ? { 'X-Silent-Error': 'true' } : {} })
export const registerMerchantApi = (data: any) => request.post('/auth/register-merchant', data)
export const sendResetCodeApi = (data: { account: string }) => request.post('/auth/send-reset-code', data)
export const resetPasswordByCodeApi = (data: { account: string; code: string; newPassword: string }) =>
  request.post('/auth/reset-password', data)

// 空间与门店 (包厢/台位/工位)
export const getSpacesApi = (storeId?: string) => request.get('/space/list', { params: { storeId } })
export const saveSpaceApi = (data: any) => request.post('/space/save', data)
export const batchCreateSpacesApi = (data: any[]) => request.post('/space/batch-create', data)
export const deleteSpaceApi = (id: number) => request.delete(`/space/${id}`)
export const updateSpaceStatusApi = (id: number, status: string) => request.post(`/space/${id}/status`, null, { params: { status } })
export const resetSpaceApi = (id: number) => request.post(`/space/${id}/reset`)
export const getTenantStoresApi = () => request.get('/space/stores')
export const createStoreApi = (data: any) => request.post('/space/store/create', data)
export const updateStoreApi = (data: any) => request.post('/space/store/update', data)
export const saveStorePositionsApi = (storeId: string, data: any) => request.post(`/space/store/positions?storeId=${encodeURIComponent(storeId)}`, data)

// 在场会话与履约
export const openSessionApi = (data: any) => request.post('/session/open', data)
export const appendItemsApi = (data: any) => request.post('/session/append', data)
export const getSessionDetailApi = (id: number, silent = false) =>
  request.get(`/session/${id}/detail`, { headers: silent ? { 'X-Silent-Error': 'true' } : {} })
export const transferSpaceApi = (id: number, data: any) => request.post(`/session/${id}/transfer`, data)
export const cancelLineItemApi = (itemId: number, data: any) => request.post(`/session/item/${itemId}/cancel`, data)
export const getActiveSessionsApi = () => request.get('/session/active-list')

// 结算与收银
export const requestBillingApi = (sessionId: number, silent = false) =>
  request.post(`/billing/request/${sessionId}`, {}, { headers: silent ? { 'X-Silent-Error': 'true' } : {} })
export const executeCheckoutApi = (data: any, silent = false) =>
  request.post('/billing/checkout', data, { headers: silent ? { 'X-Silent-Error': 'true' } : {} })

// 会员与海马体画像
export const registerMemberApi = (data: any) => request.post('/member/register', data)
export const rechargeMemberApi = (data: any) => request.post('/member/recharge', data)
export const issueTimeCardApi = (data: any) => request.post('/member/issue-time-card', data)
export const savePreferenceApi = (data: any) => request.post('/member/preference', data)
export const getMemberProfileApi = (id: number) => request.get(`/member/${id}/profile`)
export const searchMembersApi = (query?: string, tenantId?: string, storeId?: string) => request.get('/member/search', { params: { query, tenantId, storeId } })

// 商品与BOM配方
export const getProductsApi = (type?: string, storeId?: string) => request.get('/product/list', { params: { type, ...(storeId ? { storeId } : {}) } })
export const getCategoriesApi = (industry?: string, storeId?: string, tenantId?: string) => request.get('/product/categories', { params: { industry, ...(storeId ? { storeId } : {}), ...(tenantId ? { tenantId } : {}) } })
export const saveCategoryApi = (data: any) => request.post('/product/category/save', data)
export const deleteCategoryApi = (id: number) => request.delete(`/product/category/${id}`)
export const saveProductApi = (data: any) => request.post('/product/save', data)
export const deleteProductApi = (id: number) => request.delete(`/product/${id}`)

// 行业模态与门店看板
export const getCurrentIndustryApi = () => request.get('/industry/current')
export const switchIndustryApi = (data: any) => request.post('/industry/switch', data)
export const getIndustryCategoriesApi = () => request.get('/industry/categories')
export const updateStoreCategoryApi = (data: any) => request.post('/industry/store-category', data)
export const getDashboardStatsApi = (storeId?: string) =>
  request.get('/dashboard/stats', { params: storeId ? { storeId } : undefined })

// 系统开发商专属运营管控
export const getVendorStatsApi = () => request.get('/vendor/stats')
export const getVendorSubscriptionsApi = (params?: { query?: string; warningLevel?: string }) =>
  request.get('/vendor/subscriptions', { params })
export const renewSubscriptionApi = (data: any) => request.post('/vendor/renew', data)
export const getVendorBillingRecordsApi = (tenantId?: string) =>
  request.get('/vendor/billing-records', { params: { tenantId } })
export const toggleTenantStatusApi = (tenantId: string, status: string, reason?: string) =>
  request.post(`/vendor/tenant/${tenantId}/toggle-status`, { status, reason })
export const deleteTenantApi = (tenantId: string) =>
  request.delete(`/vendor/tenant/${tenantId}`)
export const getTenantUsersApi = (tenantId: string) =>
  request.get(`/vendor/tenant/${tenantId}/users`)
export const resetUserPasswordApi = (data: { userId?: number; username?: string; newPassword?: string; tenantId?: string }) =>
  request.post('/vendor/users/reset-password', data)
export const getSubscriptionPlansApi = () => request.get('/vendor/plans')
export const updatePlanConfigApi = (id: number, data: any) => request.put(`/vendor/plans/${id}`, data)
export const updateTrialDaysApi = (trialDays: number) => request.put('/vendor/trial-days', { trialDays })
export const getPublicPlansApi = () => request.get('/auth/plans')
export const getCurrentSubscriptionApi = () => request.get('/auth/current-subscription')
export const adjustTenantLimitsApi = (data: any) => request.post('/vendor/adjust-limits', data)

// 系统开发维护人角色与权限管理
export const getVendorPermissionsApi = () => request.get('/vendor/permissions')
export const updateVendorRolePermissionApi = (roleCode: string, data: any) => request.put(`/vendor/permissions/${roleCode}`, data)

// 门店老板店员权限配置
export const getMerchantStaffRolesPermissionsApi = () => request.get('/merchant/staff/roles-permissions')
export const updateMerchantStaffRolePermissionApi = (roleCode: string, data: any) => request.put(`/merchant/staff/roles-permissions/${roleCode}`, data)
export const getMerchantStaffListApi = (storeId?: string) => request.get('/merchant/staff/list', { params: { storeId } })

// 顾客会员端 (自服务与画像)
export const memberLoginApi = (data: any) => request.post('/auth/member-login', data)
export const getMyProfileApi = (memberId?: number, phone?: string) => request.get('/member-portal/profile', { params: { memberId, phone } })
export const updateMyProfileApi = (data: any, memberId?: number, phone?: string) => request.put('/member-portal/profile', data, { params: { memberId, phone } })
export const saveMyPreferenceApi = (data: any, memberId?: number, phone?: string) => request.post('/member-portal/preference', data, { params: { memberId, phone } })
export const getMyOrdersApi = (memberId?: number, phone?: string) => request.get('/member-portal/orders', { params: { memberId, phone } })

// 会员卡设置 (次卡、储值卡、时长卡、独立储值卡、盲盒卡、权益卡)
export const getCardTemplatesApi = (cardType?: string) => request.get('/card-template/list', { params: { cardType } })
export const saveCardTemplateApi = (data: any, silent = false) =>
  request.post('/card-template/save', data, { headers: silent ? { 'X-Silent-Error': 'true' } : {} })
export const deleteCardTemplateApi = (id: number, silent = false) =>
  request.delete(`/card-template/${id}`, { headers: silent ? { 'X-Silent-Error': 'true' } : {} })

// 会员档案高级详情与快捷操作
export const getMemberDetailApi = (id: number) => request.get(`/member/${id}`)
export const updateMemberDetailApi = (id: number, data: any) => request.put(`/member/${id}`, data)
export const adjustMemberPointsApi = (id: number, data: { pointsDelta: number; reason?: string }) => request.post(`/member/${id}/adjust-points`, data)
export const adjustMemberRewardsApi = (id: number, data: { rewardDelta: number; reason?: string }) => request.post(`/member/${id}/adjust-rewards`, data)
export const setMemberCardPasswordApi = (id: number, data: { password: string; enabled: boolean }) => request.post(`/member/${id}/card-password`, data)

// 员工管理与奖罚/提成
export const createStaffApi = (data: any) => request.post('/merchant/staff', data)
export const updateStaffApi = (id: number, data: any) => request.put(`/merchant/staff/${id}`, data)
export const deleteStaffApi = (id: number) => request.delete(`/merchant/staff/${id}`)
export const restoreStaffApi = (id: number) => request.post(`/merchant/staff/restore/${id}`)
export const getDeletedStaffListApi = () => request.get('/merchant/staff/deleted-list')
export const createRewardPunishApi = (data: any) => request.post('/merchant/staff/reward-punish', data)
export const getRewardPunishListApi = (employeeId?: number) => request.get('/merchant/staff/reward-punish', { params: { employeeId } })
export const getStaffCommissionsApi = (employeeId: number) => request.get('/merchant/staff/commissions', { params: { employeeId } })
export const getStaffAuditListApi = (params?: { storeId?: string; status?: string; tenantId?: string }) => request.get('/merchant/staff/audit-list', { params })
export const approveStaffAuditApi = (id: number, data?: any) => request.post(`/merchant/staff/audit/${id}/approve`, data)
export const rejectStaffAuditApi = (id: number, reason?: string) => request.post(`/merchant/staff/audit/${id}/reject`, null, { params: { reason } })

// 个人中心 (修改密码、修改手机号、修改个人信息)
export const getUserProfileApi = () => request.get('/auth/profile')
export const changePasswordApi = (data: { oldPassword?: string; newPassword: string }) => request.put('/auth/profile/change-password', data)
export const updatePhoneApi = (data: { phone: string; verifyCode?: string }) => request.put('/auth/profile/update-phone', data)
export const updateProfileInfoApi = (data: { realName?: string; gender?: string; avatar?: string }) => request.put('/auth/profile/info', data)

// 考勤打卡与企业微信/钉钉数据对接
export const getAttendanceConfigApi = () => request.get('/attendance/config')
export const saveAttendanceConfigApi = (data: any) => request.post('/attendance/config', data)
export const syncAttendanceDataApi = (platformOrParams?: string | { platform?: string }) => {
  const platform = typeof platformOrParams === 'string' ? platformOrParams : platformOrParams?.platform
  return request.post('/attendance/sync', null, { params: { platform } })
}
export const getAttendanceRecordsApi = (params?: any) => request.get('/attendance/records', { params })

// 员工请假申请与审批流
export const getLeaveListApi = (params?: any) => request.get('/leave/list', { params })
export const applyLeaveApi = (data: any) => request.post('/leave/apply', data)
export const auditLeaveApi = (data: any) => request.post('/leave/audit', data)

// 租户测试数据生成与数据清空重置
export const initTenantDemoDataApi = (data: { industry: string }) => request.post('/tenant/init-demo-data', data)
export const clearTenantDataApi = () => request.post('/tenant/clear-data')
export const getTenantDataStatusApi = () => request.get('/tenant/data-status')

// 微信公众号与支付宝生活号全渠道消息推送
export const getNotificationConfigApi = () => request.get('/notification/config')
export const saveNotificationConfigApi = (data: any) => request.post('/notification/config', data)
export const sendTestNotificationApi = (data: { channel: string; targetPhone?: string; msgType?: string }) => request.post('/notification/send-test', data)
export const broadcastMarketingApi = (data: { campaignTitle: string; content: string; linkUrl?: string }) => request.post('/notification/broadcast-marketing', data)
export const getNotificationLogsApi = (params?: number | { memberId?: number }) => {
  const query = typeof params === 'number' ? { memberId: params } : params
  return request.get('/notification/logs', { params: query })
}
export const simulateFollowApi = (data: { phone: string; channel: string }) => request.post('/notification/member/simulate-follow', data)

// 预约排班管理 (到店时间、状态流转与展位联动)
export const getAppointmentsApi = (params?: { storeId?: string; date?: string; startDate?: string; endDate?: string }) =>
  request.get('/appointment/list', { params })
export const createAppointmentApi = (data: any) => request.post('/appointment/create', data)
export const checkInAppointmentApi = (id: number, data?: { spaceId?: number }) => request.post(`/appointment/${id}/check-in`, data || {})
export const updateAppointmentStatusApi = (id: number, status: string) => request.post(`/appointment/${id}/status`, { status })
export const deleteAppointmentApi = (id: number) => request.delete(`/appointment/${id}`)

// 门店运营规范与日常公告
export const getStoreNoticesApi = (storeId?: string, category?: string) =>
  request.get('/store/notice/list', { params: { storeId, category } })
export const saveStoreNoticeApi = (data: any) => request.post('/store/notice/save', data)
export const deleteStoreNoticeApi = (id: number | string) =>
  request.post('/store/notice/delete', null, { params: { id } })

// 会员真实订单与充值流水
export const getMemberOrdersApi = (id: number) => request.get(`/member/${id}/orders`)
export const getMemberRechargesApi = (id: number) => request.get(`/member/${id}/recharges`)

// 门店信息与顾客自助开卡配置
export const getStoreInfoApi = (storeId: string) => request.get('/store/info', { params: { storeId } })
export const getStoreRegisterConfigApi = (storeId: string, industry?: string) =>
  request.get('/store/register-config', { params: { storeId, industry } })
export const saveStoreRegisterConfigApi = (data: any) => request.post('/store/register-config', data)

// 服务要求与常用特殊备注标签
export const getCommonRemarksApi = (storeId: string, industry?: string) =>
  request.get('/store/common-remarks', { params: { storeId, industry } })
export const saveCommonRemarksApi = (data: { storeId: string; remarks: string[] }) =>
  request.post('/store/common-remarks', data)

// 服务人员对外称谓展示规则
export const getStaffDisplayModeApi = (storeId: string) =>
  request.get('/store/staff-display-mode', { params: { storeId } })
export const saveStaffDisplayModeApi = (data: { storeId: string; staffDisplayMode: string }) =>
  request.post('/store/staff-display-mode', data)

// 系统登录与安全审计日志及超管策略配置
export const getAuditLogsApi = (params?: { tenantId?: string; username?: string; keyword?: string; page?: number; size?: number }) =>
  request.get('/audit/logs', { params })
export const getAuditPolicyApi = () => request.get('/audit/policy')
export const saveAuditPolicyApi = (data: any) => request.post('/audit/policy/save', data)
export const clearAuditLogsApi = (tenantId?: string) => request.delete('/audit/logs/clear', { params: { tenantId } })
export const recordClientAuditLogApi = (data: any) => request.post('/audit/log', data)

// 包厢扫码呼叫管家与前台多端通知
export const callSpaceServiceApi = (data: {
  spaceId?: number
  spaceCode?: string
  spaceName?: string
  serviceType: string
  notes?: string
  storeId?: string
  tenantId?: string
}) => request.post('/space/call-service', data)

export const getServiceCallsApi = (params?: { storeId?: string; status?: string; limit?: number }) =>
  request.get('/space/service-calls', { params, headers: { 'X-Silent-Error': 'true' } })

export const handleServiceCallApi = (id: string) =>
  request.post(`/space/service-calls/${id}/handle`, {})

// 包厢/桌台新点单语音报单与前台出单强提醒通知
export const getOrderNotificationsApi = (params?: { storeId?: string; status?: string; limit?: number }) =>
  request.get('/space/order-notifications', { params, headers: { 'X-Silent-Error': 'true' } })

export const handleOrderNotificationApi = (id: string) =>
  request.post(`/space/order-notifications/${id}/handle`, {})

// 常用行业全景预设配置
export const getIndustryPresetTemplateApi = (industry: string) =>
  request.get(`/industry/preset-template/${industry}`)

export const saveIndustryPresetTemplateApi = (data: any) =>
  request.post('/industry/preset-template/save', data)

export const resetIndustryPresetTemplateApi = (industry: string) =>
  request.post(`/industry/preset-template/reset/${industry}`)
