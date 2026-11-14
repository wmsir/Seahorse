import axios, { type AxiosInstance, type AxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'
import { recordApiCall } from '../utils/tenantQuotaService'
import { getApiBaseUrl } from '../utils/systemConfig'

interface UnwrappedAxiosInstance extends Omit<AxiosInstance, 'get' | 'post' | 'put' | 'delete' | 'patch' | 'request'> {
  request<T = any>(config: AxiosRequestConfig): Promise<T>
  get<T = any>(url: string, config?: AxiosRequestConfig): Promise<T>
  delete<T = any>(url: string, config?: AxiosRequestConfig): Promise<T>
  post<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T>
  put<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T>
  patch<T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T>
}

const checkIsSilent = (headers: any) => {
  if (!headers) return false
  if (typeof headers.get === 'function') {
    return headers.get('X-Silent-Error') === 'true' || headers.get('x-silent-error') === 'true'
  }
  return headers['X-Silent-Error'] === 'true' || headers['x-silent-error'] === 'true'
}

const service = axios.create({
  baseURL: getApiBaseUrl(),
  timeout: 10000
})

service.interceptors.request.use(
  config => {
    config.baseURL = getApiBaseUrl()
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

    // 非开发维护人且非后台静默轮询时，自动累计租户后台接口操作调用
    const role = localStorage.getItem('seahorse_role')
    if (role !== 'PLATFORM_DEVELOPER' && !checkIsSilent(config.headers)) {
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

export default service as unknown as UnwrappedAxiosInstance
