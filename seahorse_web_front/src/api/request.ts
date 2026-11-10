import axios from 'axios'
import { ElMessage } from 'element-plus'

const service = axios.create({
  baseURL: '/api',
  timeout: 10000
})

import { recordApiCall } from '../utils/tenantQuotaService'

service.interceptors.request.use(
  config => {
    const token = localStorage.getItem('seahorse_token')
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }
    const storeId = localStorage.getItem('seahorse_store_id') || 'S001'
    const tenantId = localStorage.getItem('seahorse_tenant_id') || 'T001'
    config.headers['X-Store-Id'] = storeId
    config.headers['X-Tenant-Id'] = tenantId
    const uname = localStorage.getItem('seahorse_username') || localStorage.getItem('seahorse_user') || ''
    if (uname) {
      config.headers['X-User-Name'] = encodeURIComponent(uname)
    }

    // 非开发维护人自动累计租户后台接口操作调用
    const role = localStorage.getItem('seahorse_role')
    if (role !== 'PLATFORM_DEVELOPER') {
      try {
        recordApiCall(tenantId)
      } catch (e) {
        // ignore
      }
    }

    return config
  },
  error => {
    return Promise.reject(error)
  }
)

const checkIsSilent = (headers: any) => {
  if (!headers) return false
  if (typeof headers.get === 'function') {
    return headers.get('X-Silent-Error') === 'true' || headers.get('x-silent-error') === 'true'
  }
  return headers['X-Silent-Error'] === 'true' || headers['x-silent-error'] === 'true'
}

service.interceptors.response.use(
  response => {
    const res = response.data
    const isSilent = checkIsSilent(response.config?.headers)
    if (res.code !== 200) {
      if (!isSilent) {
        ElMessage.error(res.message || '请求处理异常')
      }
      return Promise.reject(new Error(res.message || 'Error'))
    }
    return res.data
  },
  error => {
    const isSilent = checkIsSilent(error.config?.headers)
    if (!isSilent) {
      const msg = error.response?.data?.message || error.message || '网络连接超时'
      ElMessage.error(msg)
    }
    return Promise.reject(error)
  }
)

export default service
