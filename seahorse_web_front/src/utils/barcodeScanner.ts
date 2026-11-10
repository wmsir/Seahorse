/**
 * 扫码盒子免驱即插即用 (USB HID 虚拟键盘) 核心驱动与条码解析器
 * 
 * 硬件特性：
 * 1. 免驱动即插即用：符合 USB HID 标准键盘协议，扫码后如键盘极速键入字符，结尾追加回车符 (Enter/Key 13)；
 * 2. 键入极速特征：击键间隔通常在 5ms ~ 35ms 之间，远快于人工敲键 (人工通常 100ms ~ 300ms)；
 * 3. 智能场景分流：
 *    - 微信付款码：18位数字，以 10/11/12/13/14/15 开头；
 *    - 支付宝付款码：18位数字 (部分16~24位)，以 25~30 开头 (最常见 28 开头)；
 *    - 商品条码：中国大陆 EAN-13 码 (69 开头) 或企业自定义商品/服务编码 (如 BEA-001 等)。
 */

export type BarcodeType = 'MEMBER' | 'WECHAT_PAY' | 'ALIPAY_PAY' | 'PRODUCT' | 'OTHER'

export interface BarcodeScanResult {
  rawCode: string
  type: BarcodeType
  typeName: string
  scannedAt: string
  charCount: number
  durationMs: number
  channelInfo?: {
    channel: 'MEMBER' | 'WECHAT' | 'ALIPAY' | 'PRODUCT'
    displayName: string
    color: string
    icon: string
  }
}

export interface BarcodeScannerOptions {
  keyIntervalThresholdMs?: number // 击键间隔阈值 (毫秒)，默认 50ms
  minCodeLength?: number         // 最小条码长度，默认 3
  beepEnabled?: boolean          // 是否启用扫码蜂鸣提示音
  onScan?: (result: BarcodeScanResult) => void
}

/**
 * 智能判定条码业务类型
 */
export function parseBarcodeType(code: string): { type: BarcodeType; typeName: string; channelInfo: any } {
  const trimmed = (code || '').trim()

  // 0. 会员专属消费码 / 顾客身份凭证 (跨端统一 SEAHORSE:MEMBER:phone 协议与手机号/卡号)
  if (trimmed.startsWith('SEAHORSE:MEMBER:') || /^1[3-9]\d{9}$/.test(trimmed) || /^(M|VIP|CARD)\d+/i.test(trimmed)) {
    const cleanPhone = trimmed.startsWith('SEAHORSE:MEMBER:') ? trimmed.replace('SEAHORSE:MEMBER:', '') : trimmed
    return {
      type: 'MEMBER',
      typeName: `海马体顾客会员凭证 (${cleanPhone})`,
      channelInfo: {
        channel: 'MEMBER',
        displayName: '会员专属凭证',
        color: '#0d9488',
        icon: 'User'
      }
    }
  }

  // 1. 微信支付付款码：18位纯数字，以 10, 11, 12, 13, 14, 15 开头
  if (/^(10|11|12|13|14|15)\d{16}$/.test(trimmed)) {
    return {
      type: 'WECHAT_PAY',
      typeName: '微信支付付款码 (18位)',
      channelInfo: {
        channel: 'WECHAT',
        displayName: '微信反扫收款',
        color: '#07c160',
        icon: 'ChatDotSquare'
      }
    }
  }

  // 2. 支付宝付款码：16-24位纯数字 (标准18位)，以 25, 26, 27, 28, 29, 30 开头 (常见为28)
  if (/^(25|26|27|28|29|30)\d{14,22}$/.test(trimmed)) {
    return {
      type: 'ALIPAY_PAY',
      typeName: '支付宝付款码 (18位)',
      channelInfo: {
        channel: 'ALIPAY',
        displayName: '支付宝反扫收款',
        color: '#1677ff',
        icon: 'Wallet'
      }
    }
  }

  // 3. 商品国标条形码：中国大陆 EAN-13 (以 69 开头的 13 位纯数字，或国际 8/12/13/14 位条码)
  if (/^69\d{11}$/.test(trimmed)) {
    return {
      type: 'PRODUCT',
      typeName: '中国大陆国标 69 商品条码 (EAN-13)',
      channelInfo: {
        channel: 'PRODUCT',
        displayName: '商品/服务零售',
        color: '#fa8c16',
        icon: 'Goods'
      }
    }
  }

  // 4. 其他条码或内部编码 (如 8~14 位数字商品码，或 BEA-001 等业务自编码)
  if (trimmed.length >= 3) {
    return {
      type: 'PRODUCT',
      typeName: '门店自编码/服务项目条码',
      channelInfo: {
        channel: 'PRODUCT',
        displayName: '商品/服务零售',
        color: '#fa8c16',
        icon: 'Goods'
      }
    }
  }

  return {
    type: 'OTHER',
    typeName: '未知或自定义条码',
    channelInfo: {
      channel: 'PRODUCT',
      displayName: '自定义码',
      color: '#8c8c8c',
      icon: 'Document'
    }
  }
}

/**
 * 基于 Web Audio API 的硬件级蜂鸣提示音合成器 (无须任何外部音效文件，零延迟)
 */
class AudioBeepEngine {
  private ctx: AudioContext | null = null

  private getContext(): AudioContext | null {
    if (!this.ctx && typeof window !== 'undefined') {
      const AudioCtx = (window as any).AudioContext || (window as any).webkitAudioContext
      if (AudioCtx) {
        this.ctx = new AudioCtx()
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume()
    }
    return this.ctx
  }

  /**
   * 播放清脆的扫码成功音效 ("滴~" 1760Hz 快速衰减)
   */
  playSuccess() {
    try {
      const ctx = this.getContext()
      if (!ctx) return
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.type = 'sine'
      osc.frequency.setValueAtTime(1760, ctx.currentTime)
      gain.gain.setValueAtTime(0.25, ctx.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.09)
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.start(ctx.currentTime)
      osc.stop(ctx.currentTime + 0.09)
    } catch (e) {
      console.warn('Audio play error:', e)
    }
  }

  /**
   * 播放反扫收款双音提示 ("滴-呤~" 1200Hz -> 2400Hz)
   */
  playPaymentSuccess() {
    try {
      const ctx = this.getContext()
      if (!ctx) return
      const now = ctx.currentTime
      const osc1 = ctx.createOscillator()
      const gain1 = ctx.createGain()
      osc1.type = 'triangle'
      osc1.frequency.setValueAtTime(1200, now)
      gain1.gain.setValueAtTime(0.2, now)
      gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.08)
      osc1.connect(gain1)
      gain1.connect(ctx.destination)
      osc1.start(now)
      osc1.stop(now + 0.08)

      const osc2 = ctx.createOscillator()
      const gain2 = ctx.createGain()
      osc2.type = 'sine'
      osc2.frequency.setValueAtTime(2400, now + 0.08)
      gain2.gain.setValueAtTime(0.28, now + 0.08)
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.22)
      osc2.connect(gain2)
      gain2.connect(ctx.destination)
      osc2.start(now + 0.08)
      osc2.stop(now + 0.22)
    } catch (e) {
      console.warn('Audio play error:', e)
    }
  }

  /**
   * 扫码异常或无法识别时的低音提示
   */
  playError() {
    try {
      const ctx = this.getContext()
      if (!ctx) return
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.type = 'sawtooth'
      osc.frequency.setValueAtTime(320, ctx.currentTime)
      gain.gain.setValueAtTime(0.2, ctx.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.18)
      osc.connect(gain)
      gain.connect(ctx.destination)
      osc.start(ctx.currentTime)
      osc.stop(ctx.currentTime + 0.18)
    } catch (e) {}
  }
}

export const scanAudio = new AudioBeepEngine()

/**
 * 扫码盒子全局监听与分发器单例
 */
export class BarcodeScannerEngine {
  private keyBuffer: string[] = []
  private keyTimes: number[] = []
  private isListening = false
  private options: Required<BarcodeScannerOptions>
  private listeners: Array<(result: BarcodeScanResult) => void> = []

  constructor(options?: BarcodeScannerOptions) {
    this.options = {
      keyIntervalThresholdMs: options?.keyIntervalThresholdMs ?? 60,
      minCodeLength: options?.minCodeLength ?? 3,
      beepEnabled: options?.beepEnabled ?? true,
      onScan: options?.onScan ?? (() => {})
    }
    if (options?.onScan) {
      this.listeners.push(options.onScan)
    }
  }

  public subscribe(callback: (result: BarcodeScanResult) => void): () => void {
    this.listeners.push(callback)
    return () => {
      this.listeners = this.listeners.filter(cb => cb !== callback)
    }
  }

  public startListening() {
    if (this.isListening || typeof window === 'undefined') return
    window.addEventListener('keydown', this.handleKeyDown, true) // capture phase
    this.isListening = true
  }

  public stopListening() {
    if (!this.isListening || typeof window === 'undefined') return
    window.removeEventListener('keydown', this.handleKeyDown, true)
    this.isListening = false
    this.keyBuffer = []
    this.keyTimes = []
  }

  public setOptions(newOpts: Partial<BarcodeScannerOptions>) {
    if (newOpts.keyIntervalThresholdMs !== undefined) {
      this.options.keyIntervalThresholdMs = newOpts.keyIntervalThresholdMs
    }
    if (newOpts.minCodeLength !== undefined) {
      this.options.minCodeLength = newOpts.minCodeLength
    }
    if (newOpts.beepEnabled !== undefined) {
      this.options.beepEnabled = newOpts.beepEnabled
    }
  }

  private handleKeyDown = (event: KeyboardEvent) => {
    const now = Date.now()

    // 过滤控制键（Shift, Control, Alt, Meta 等无字符输出键）
    if (['Shift', 'Control', 'Alt', 'Meta', 'CapsLock', 'Tab'].includes(event.key)) {
      return
    }

    // 遇到回车键：检测是否为扫码枪完成输入
    if (event.key === 'Enter') {
      if (this.keyBuffer.length >= this.options.minCodeLength) {
        // 计算击键平均间隔与总耗时
        const totalDuration = now - this.keyTimes[0]
        const avgInterval = totalDuration / Math.max(1, this.keyBuffer.length - 1)

        // 若平均击键间隔低于阈值（扫码枪特征），则确认为扫码事件
        if (avgInterval <= this.options.keyIntervalThresholdMs * 1.6 || totalDuration <= 500) {
          event.preventDefault()
          event.stopPropagation()

          const rawCode = this.keyBuffer.join('')
          const { type, typeName, channelInfo } = parseBarcodeType(rawCode)

          const scanResult: BarcodeScanResult = {
            rawCode,
            type,
            typeName,
            scannedAt: new Date().toLocaleTimeString(),
            charCount: rawCode.length,
            durationMs: totalDuration,
            channelInfo
          }

          if (this.options.beepEnabled) {
            if (type === 'WECHAT_PAY' || type === 'ALIPAY_PAY') {
              scanAudio.playPaymentSuccess()
            } else {
              scanAudio.playSuccess()
            }
          }

          // 分发给所有已注册监听器
          this.listeners.forEach(cb => {
            try {
              cb(scanResult)
            } catch (err) {
              console.error('Scan listener callback error:', err)
            }
          })

          // 消费完后清空缓存
          this.keyBuffer = []
          this.keyTimes = []
          return
        }
      }
      // 人工回车或缓存不足，重置缓存
      this.keyBuffer = []
      this.keyTimes = []
      return
    }

    // 普通字符按键（单个字符）
    if (event.key.length === 1) {
      const lastTime = this.keyTimes[this.keyTimes.length - 1]
      const interval = lastTime ? (now - lastTime) : 0

      // 如果两次按键间隔过长（超过阈值），说明不是扫码枪高速连续输入，重置清空
      if (this.keyBuffer.length > 0 && interval > this.options.keyIntervalThresholdMs * 2.2) {
        this.keyBuffer = []
        this.keyTimes = []
      }

      this.keyBuffer.push(event.key)
      this.keyTimes.push(now)
    }
  }

  /**
   * 仿真调试器：模拟 USB HID 扫码盒子以 12ms 极速敲击键入条码并回车
   */
  public simulateScan(code: string, charDelayMs = 12): Promise<BarcodeScanResult> {
    return new Promise((resolve) => {
      const { type, typeName, channelInfo } = parseBarcodeType(code)

      // 播放蜂鸣音
      if (this.options.beepEnabled) {
        if (type === 'WECHAT_PAY' || type === 'ALIPAY_PAY') {
          scanAudio.playPaymentSuccess()
        } else {
          scanAudio.playSuccess()
        }
      }

      const scanResult: BarcodeScanResult = {
        rawCode: code,
        type,
        typeName,
        scannedAt: new Date().toLocaleTimeString(),
        charCount: code.length,
        durationMs: code.length * charDelayMs,
        channelInfo
      }

      // 触发回调
      setTimeout(() => {
        this.listeners.forEach(cb => {
          try {
            cb(scanResult)
          } catch (e) {
            console.error('Simulate scan listener error:', e)
          }
        })
        resolve(scanResult)
      }, 50)
    })
  }
}

// 导出全局单例引擎
export const barcodeScanner = new BarcodeScannerEngine()
