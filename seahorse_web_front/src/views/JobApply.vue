<template>
  <div class="job-apply-page">
    <div class="apply-container">
      <!-- 门店品牌顶栏 -->
      <div class="brand-hero">
        <div class="brand-badge">
          <svg viewBox="0 0 64 64" width="38" height="38" style="flex-shrink:0;filter:drop-shadow(0 2px 6px rgba(14,165,233,0.35));" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="shMascotBg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0284c7"/>
      <stop offset="55%" stop-color="#0ea5e9"/>
      <stop offset="100%" stop-color="#38bdf8"/>
    </linearGradient>
    <linearGradient id="shMascotGold" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fde047"/>
      <stop offset="100%" stop-color="#f59e0b"/>
    </linearGradient>
  </defs>
  <rect x="2" y="2" width="60" height="60" rx="16" fill="url(#shMascotBg)" stroke="#bae6fd" stroke-width="1.5"/>
  <path d="M29 11 L32 6 L35 11 L39 8 L38 14 Z" fill="url(#shMascotGold)"/>
  <path d="M38 22 C42 20 44 23 41 26 C44 28 42 32 37 31 Z" fill="url(#shMascotGold)" opacity="0.92"/>
  <path d="M32 12 C24 12 20 17 21 23 C22 27 25 29 24 34 C22 40 26 47 32 49 C37 51 41 47 39 43 C37 40 33 42 34 45 C31 44 29 40 31 35 C33 30 38 28 38 22 C38 19 43 19 45 18 C46 17 45 15 43 15 C40 15 37 12 32 12 Z" fill="#ffffff"/>
  <circle cx="33.5" cy="17.5" r="2" fill="#0f172a"/>
  <circle cx="34.2" cy="16.8" r="0.7" fill="#ffffff"/>
</svg>
          <span class="store-name">{{ storeInfo.storeName || '海马智慧门店' }}</span>
        </div>
        <div class="recruit-slogan">{{ storeInfo.slogan || '海马会员，记住每位好客 · 期待优秀的您加入团队' }}</div>
      </div>

      <!-- 招聘岗位核心卡片 -->
      <div class="post-hero-card">
        <div class="ph-top">
          <h1 class="post-name">{{ postData.postName || '诚聘英才' }}</h1>
          <el-tag size="small" type="success" effect="dark">热招中</el-tag>
        </div>

        <div class="salary-highlight">
          <span class="salary-val">{{ postData.salaryRange || '面议' }}</span>
          <span class="salary-tip">（底薪 ￥{{ postData.baseSalary }} + {{ (postData.commissionRate * 100).toFixed(0) }}% 提成）</span>
        </div>

        <div class="meta-chips">
          <span class="meta-chip">👥 招 {{ postData.recruitHeadcount || 1 }} 人</span>
          <span class="meta-chip">🎓 {{ postData.educationReq || '学历不限' }}</span>
          <span class="meta-chip">💼 {{ postData.experienceReq || '经验不限' }}</span>
          <span class="meta-chip">🏬 {{ postData.department || '门店现场' }}</span>
        </div>

        <div v-if="postData.benefits && postData.benefits.length" class="benefits-row">
          <span v-for="b in postData.benefits" :key="b" class="benefit-badge">
            ✓ {{ b }}
          </span>
        </div>
      </div>

      <!-- 岗位工作职责与要求说明书 -->
      <div class="detail-card">
        <div class="section-title">
          <span class="dot">📌</span>
          <span>岗位职责与工作内容</span>
        </div>
        <div class="section-body duty-text">
          {{ postData.description || '负责门店日常专业技能实操服务，维护顾客客情关系，达成品质交付。' }}
        </div>

        <div class="section-divider"></div>

        <div class="section-title">
          <span class="dot">🎯</span>
          <span>任职考核要求</span>
        </div>
        <div class="section-body req-text">
          {{ postData.requirements || '严格遵守服务规章与门店考勤纪律，具备良好的沟通服务礼仪与进取心。' }}
        </div>

        <div class="section-divider"></div>

        <div class="section-title">
          <span class="dot">🏪</span>
          <span>工作地点与工作环境</span>
        </div>
        <div class="section-body store-loc">
          <div><b>门店地址：</b>{{ storeInfo.address || '门店现场接待中心' }}</div>
          <div><b>营业服务时间：</b>09:30 - 21:30</div>
          <div><b>前台联系电话：</b>{{ storeInfo.phone || '到店咨询' }}</div>
        </div>
      </div>

      <!-- 申请表单区 -->
      <div id="apply-form-section" class="form-card">
        <div class="form-header">
          <div class="form-title">📝 填写求职者基本资料</div>
          <div class="form-subtitle">资料将直接加密投递给店长，承诺严格保护求职者隐私</div>
        </div>

        <div v-if="submittedSuccess" class="success-banner">
          <div class="s-icon">🎉</div>
          <div class="s-tit">应聘申请已成功提交！</div>
          <div class="s-desc">
            亲爱的 <b>{{ form.candidateName }}</b>，您的应聘资料已成功送达【{{ storeInfo.storeName }}】店长，请保持电话 <b>{{ form.phone }}</b> 畅通，我们将尽快与您联系安排面试！
          </div>
          <el-button type="primary" plain style="margin-top: 14px;" @click="submittedSuccess = false">
            重新修改 / 投递其他岗位
          </el-button>
        </div>

        <el-form v-else :model="form" label-width="90px" label-position="left">
          <el-form-item label="真实姓名" required>
            <el-input v-model="form.candidateName" placeholder="请输入您的姓名" />
          </el-form-item>

          <el-form-item label="您的性别" required>
            <el-radio-group v-model="form.gender">
              <el-radio label="男">男</el-radio>
              <el-radio label="女">女</el-radio>
            </el-radio-group>
          </el-form-item>

          <el-form-item label="联系电话" required>
            <el-input v-model="form.phone" placeholder="用于接收面试通知短信/电话" />
          </el-form-item>

          <el-row :gutter="12">
            <el-col :span="12">
              <el-form-item label="年龄">
                <el-input-number v-model="form.age" :min="18" :max="65" style="width: 100%;" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="最高学历">
                <el-select v-model="form.education" style="width: 100%;">
                  <el-option label="中专 / 高中" value="中专/高中" />
                  <el-option label="大专" value="大专" />
                  <el-option label="本科" value="本科" />
                  <el-option label="其他" value="其他" />
                </el-select>
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="12">
            <el-col :span="12">
              <el-form-item label="工作年限">
                <el-input-number v-model="form.experienceYears" :min="0" :max="40" style="width: 100%;" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="期望月薪">
                <el-input v-model="form.expectedSalary" placeholder="如: 7500元" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="最快到岗">
            <el-radio-group v-model="form.availableDate" size="small">
              <el-radio-button label="随时到岗">随时到岗</el-radio-button>
              <el-radio-button label="3天内">3天内</el-radio-button>
              <el-radio-button label="1周内">1周内</el-radio-button>
              <el-radio-button label="1个月内">1个月内</el-radio-button>
            </el-radio-group>
          </el-form-item>

          <el-form-item label="个人优势">
            <el-input
              v-model="form.personalAdvantage"
              type="textarea"
              :rows="2"
              placeholder="简述您的专业技能、特长或个人风格..."
            />
          </el-form-item>

          <el-form-item label="工作经历">
            <el-input
              v-model="form.workHistory"
              type="textarea"
              :rows="2"
              placeholder="既往工作单位、负责内容及履历情况..."
            />
          </el-form-item>

          <div style="margin-top: 18px;">
            <el-button
              type="primary"
              size="large"
              style="width: 100%; font-weight: 700; height: 46px; font-size: 16px;"
              :loading="submitting"
              @click="handleSubmit"
            >
              🚀 立即提交应聘申请
            </el-button>
          </div>
        </el-form>
      </div>

      <!-- 底部版权与声明 -->
      <div class="page-footer">
        <div>{{ storeInfo.storeName || '海马智慧连锁' }} · 招聘管理系统</div>
        <div style="font-size: 11px; color: #94a3b8; margin-top: 4px;">本页面由海马智慧门店系统提供技术支持</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'

const route = useRoute()

const storeInfo = ref({
  storeName: '海马智慧门店',
  slogan: '智慧连锁 · 竭诚为您提供至臻服务',
  address: '门店现场接待中心',
  phone: '到店咨询'
})

const postData = ref<any>({
  id: 2,
  postName: '发型总监/主理人',
  department: '美业设计部',
  salaryRange: '8000-11000元/月',
  baseSalary: 5500,
  commissionRate: 0.25,
  recruitHeadcount: 1,
  educationReq: '大专及以上',
  experienceReq: '3-5年',
  benefits: ['包吃包住', '五险一金', '带薪年假', '技能培训', '定期团建'],
  description: '负责高端发型设计与私人定制造型方案，指导店内发型师技术培训，把控出品服务标准，主理高客单客户群。',
  requirements: '熟练掌握各类潮流烫染剪发技术，拥有独立客户资源与良好的审美沟通能力。'
})

const form = ref({
  candidateName: '',
  gender: '男' as '男' | '女',
  phone: '',
  age: 26,
  education: '大专',
  experienceYears: 3,
  expectedSalary: '8000元/月',
  availableDate: '随时到岗',
  personalAdvantage: '',
  workHistory: ''
})

const submitting = ref(false)
const submittedSuccess = ref(false)

const loadPostInfo = () => {
  const queryPostId = Number(route.query.postId) || 2

  // 1. 优先从 URL 动态提取当前店铺的真实信息 (门店、地址、电话、标语)
  if (route.query.store) {
    storeInfo.value.storeName = decodeURIComponent(String(route.query.store))
  }
  if (route.query.addr) {
    storeInfo.value.address = decodeURIComponent(String(route.query.addr))
  }
  if (route.query.phone) {
    storeInfo.value.phone = decodeURIComponent(String(route.query.phone))
  }

  // 2. 优先从 URL 参数中直接获取预览海报中绑定的岗位完整真实信息 (确保手机扫码打开与管理端预览100%绝对一致)
  if (route.query.postName) {
    const rawBenefits = route.query.benefits ? decodeURIComponent(String(route.query.benefits)).split('、') : ['包吃包住', '五险一金', '带薪年假']
    postData.value = {
      id: queryPostId,
      postName: decodeURIComponent(String(route.query.postName)),
      salaryRange: route.query.salary ? decodeURIComponent(String(route.query.salary)) : '面议',
      baseSalary: route.query.baseSalary ? Number(route.query.baseSalary) : 4500,
      commissionRate: route.query.commRate ? Number(route.query.commRate) : 0.1,
      recruitHeadcount: route.query.headcount ? Number(route.query.headcount) : 1,
      educationReq: route.query.edu ? decodeURIComponent(String(route.query.edu)) : '学历不限',
      experienceReq: route.query.exp ? decodeURIComponent(String(route.query.exp)) : '经验不限',
      department: route.query.dept ? decodeURIComponent(String(route.query.dept)) : '门店现场',
      benefits: rawBenefits,
      description: route.query.desc ? decodeURIComponent(String(route.query.desc)) : '负责门店日常专业服务交付与顾客接待。',
      requirements: route.query.req ? decodeURIComponent(String(route.query.req)) : '品貌端正，具备良好服务意识与团队沟通协作精神。'
    }
    return
  }

  // 3. 次级降级策略：尝试从本地持久化补全
  try {
    const rawStore = localStorage.getItem('seahorse_basic_settings')
    if (rawStore) {
      const st = JSON.parse(rawStore)
      if (!route.query.store && st.storeName) storeInfo.value.storeName = st.storeName
      if (!route.query.addr && st.address) storeInfo.value.address = st.address
      if (!route.query.phone && st.phone) storeInfo.value.phone = st.phone
      if (st.slogan) storeInfo.value.slogan = st.slogan
    }
  } catch (e) {}

  try {
    const rawPos = localStorage.getItem('seahorse_system_positions')
    if (rawPos) {
      const arr = JSON.parse(rawPos)
      const found = arr.find((p: any) => p.id === queryPostId)
      if (found) {
        postData.value = {
          ...found,
          salaryRange: found.salaryRange || (found.baseSalary ? `￥${found.baseSalary}-${found.baseSalary + 3000}元/月` : '6000-9000元/月'),
          benefits: found.benefits || ['包吃包住', '五险一金', '带薪年假']
        }
      }
    }
  } catch (e) {}
}

const handleSubmit = async () => {
  if (!form.value.candidateName?.trim()) {
    ElMessage.warning('请填写您的真实姓名')
    return
  }
  if (!form.value.phone?.trim() || !/^1\d{10}$/.test(form.value.phone.trim())) {
    ElMessage.warning('请填写有效的11位手机号码')
    return
  }

  submitting.value = true
  const now = new Date()
  const pad = (n: number) => n < 10 ? '0' + n : String(n)
  const timeStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`

  const targetTenantId = String(route.query.tenantId || localStorage.getItem('seahorse_tenant_id') || 'DEFAULT')
  const newApp = {
    id: 'APP' + Date.now().toString().slice(-8),
    tenantId: targetTenantId,
    storeName: storeInfo.value.storeName,
    postId: postData.value.id,
    postName: postData.value.postName,
    candidateName: form.value.candidateName.trim(),
    gender: form.value.gender,
    age: form.value.age,
    phone: form.value.phone.trim(),
    education: form.value.education,
    experienceYears: form.value.experienceYears,
    expectedSalary: form.value.expectedSalary,
    availableDate: form.value.availableDate,
    personalAdvantage: form.value.personalAdvantage.trim() || '求职者具备良好的服务沟通意愿与协作态度。',
    workHistory: form.value.workHistory.trim() || '具备相关门店或行业实操经验。',
    applyTime: timeStr,
    status: 'PENDING'
  }

  // 1. 同步提交至云端后端 API (支持手机与电脑跨端协同实时呈现)
  try {
    await fetch('/api/job-application/submit', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Tenant-Id': targetTenantId
      },
      body: JSON.stringify(newApp)
    })
  } catch (err) {
    console.warn('API sync fallback to local storage:', err)
  }

  // 2. 本地缓存留底 (同手机号同岗位覆盖更新之前内容，避免生成多份重复数据)
  try {
    localStorage.setItem('seahorse_applicant_profile', JSON.stringify(form.value))
    const raw = localStorage.getItem('seahorse_job_applications')
    let list: any[] = []
    if (raw) list = JSON.parse(raw)

    const existIdx = list.findIndex((a: any) =>
      a.phone === newApp.phone && (String(a.postId) === String(newApp.postId) || a.postName === newApp.postName)
    )

    if (existIdx !== -1) {
      newApp.id = list[existIdx].id || newApp.id
      list[existIdx] = { ...list[existIdx], ...newApp }
    } else {
      list.unshift(newApp)
      // 仅全新候选人递增该岗位投递统计
      const rawPos = localStorage.getItem('seahorse_system_positions')
      if (rawPos) {
        const arr = JSON.parse(rawPos)
        const pos = arr.find((p: any) => p.id === postData.value.id)
        if (pos) {
          pos.appliedCount = (pos.appliedCount || 0) + 1
          localStorage.setItem('seahorse_system_positions', JSON.stringify(arr))
        }
      }
    }
    localStorage.setItem('seahorse_job_applications', JSON.stringify(list))
  } catch (e) {
    console.error(e)
  }

  submitting.value = false
  submittedSuccess.value = true
  ElMessage.success(`您的简历已成功送达【${storeInfo.value.storeName}】店长，请保持手机畅通！`)
}

onMounted(() => {
  loadPostInfo()
  try {
    const cachedProfile = localStorage.getItem('seahorse_applicant_profile')
    if (cachedProfile) {
      const parsed = JSON.parse(cachedProfile)
      form.value = { ...form.value, ...parsed }
    }
  } catch (e) {}
})
</script>

<style scoped>
.job-apply-page {
  min-height: 100vh;
  background: #f1f5f9;
  padding: 16px 12px 40px 12px;
  font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
  box-sizing: border-box;
}

.apply-container {
  max-width: 640px;
  margin: 0 auto;
}

.brand-hero {
  text-align: center;
  margin-bottom: 14px;
}

.brand-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: rgba(2, 132, 199, 0.1);
  padding: 4px 14px;
  border-radius: 20px;
}

.brand-icon {
  font-size: 16px;
}

.store-name {
  font-size: 14px;
  font-weight: 700;
  color: #0369a1;
}

.recruit-slogan {
  font-size: 12px;
  color: #64748b;
  margin-top: 4px;
}

.post-hero-card {
  background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
  color: #fff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 4px 16px rgba(2, 132, 199, 0.25);
  margin-bottom: 14px;
}

.ph-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.post-name {
  margin: 0;
  font-size: 22px;
  font-weight: 800;
  letter-spacing: 0.5px;
}

.salary-highlight {
  margin: 10px 0 14px 0;
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 6px;
}

.salary-val {
  font-size: 24px;
  font-weight: 800;
  color: #fef08a;
}

.salary-tip {
  font-size: 12px;
  opacity: 0.9;
}

.meta-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 12px;
}

.meta-chip {
  background: rgba(255, 255, 255, 0.18);
  font-size: 12px;
  padding: 3px 10px;
  border-radius: 4px;
}

.benefits-row {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  border-top: 1px dashed rgba(255, 255, 255, 0.3);
  padding-top: 10px;
}

.benefit-badge {
  background: rgba(255, 255, 255, 0.9);
  color: #0369a1;
  font-size: 11.5px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 4px;
}

.detail-card {
  background: #fff;
  border-radius: 12px;
  padding: 18px 16px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.05);
  margin-bottom: 14px;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14.5px;
  font-weight: 700;
  color: #0f172a;
  margin-bottom: 8px;
}

.section-body {
  font-size: 13px;
  color: #475569;
  line-height: 1.6;
}

.section-divider {
  height: 1px;
  background: #f1f5f9;
  margin: 14px 0;
}

.store-loc {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-size: 12.5px;
}

.form-card {
  background: #fff;
  border-radius: 12px;
  padding: 18px 16px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.05);
  margin-bottom: 16px;
}

.form-header {
  margin-bottom: 16px;
  padding-bottom: 10px;
  border-bottom: 1px dashed #e2e8f0;
}

.form-title {
  font-size: 16px;
  font-weight: 800;
  color: #0f172a;
}

.form-subtitle {
  font-size: 12px;
  color: #64748b;
  margin-top: 2px;
}

.success-banner {
  text-align: center;
  padding: 24px 10px;
}

.s-icon {
  font-size: 46px;
  margin-bottom: 8px;
}

.s-tit {
  font-size: 18px;
  font-weight: 800;
  color: #059669;
  margin-bottom: 8px;
}

.s-desc {
  font-size: 13px;
  color: #475569;
  line-height: 1.6;
  max-width: 440px;
  margin: 0 auto;
}

.page-footer {
  text-align: center;
  font-size: 12px;
  color: #64748b;
  padding: 10px 0 20px 0;
}
</style>
