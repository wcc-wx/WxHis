<template>
  <div class="dashboard">
    <div class="dashboard-header">
      <div class="header-left">
        <h1 class="greeting">{{ timeGreeting }}，{{ authStore.profile?.real_name || '用户' }}</h1>
        <p class="date-info">{{ currentDate }} · {{ currentWeekday }}</p>
      </div>
      <div class="header-right">
        <span class="role-badge" :class="authStore.profile?.role">{{ roleLabel }}</span>
      </div>
    </div>

    <div class="stats-grid">
      <div class="stat-card patients" @click="router.push('/patients')">
        <div class="stat-icon-wrap">
          <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
            <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
          </svg>
        </div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.totalPatients }}</span>
          <span class="stat-label">患者总数</span>
        </div>
        <div class="stat-trend up" v-if="stats.patientGrowth > 0">+{{ stats.patientGrowth }}%</div>
      </div>

      <div class="stat-card registration" @click="router.push('/registration')">
        <div class="stat-icon-wrap">
          <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
            <line x1="16" y1="2" x2="16" y2="6"/>
            <line x1="8" y1="2" x2="8" y2="6"/>
            <line x1="3" y1="10" x2="21" y2="10"/>
          </svg>
        </div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.todayRegistrations }}</span>
          <span class="stat-label">今日挂号</span>
        </div>
        <div class="stat-sub">{{ stats.pendingRegistrations }} 待诊</div>
      </div>

      <div class="stat-card lab" @click="router.push('/lab')">
        <div class="stat-icon-wrap">
          <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 3h6v4l3 9h-12l3-9V3z"/>
            <line x1="8" y1="22" x2="16" y2="22"/>
            <line x1="12" y1="16" x2="12" y2="22"/>
          </svg>
        </div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.pendingLab }}</span>
          <span class="stat-label">待检检验</span>
        </div>
        <div class="stat-sub">{{ stats.completedLab }} 已完成</div>
      </div>

      <div class="stat-card imaging" @click="router.push('/pacs')">
        <div class="stat-icon-wrap">
          <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="4" y="4" width="16" height="16" rx="2"/>
            <circle cx="12" cy="12" r="3"/>
            <path d="M12 2v2"/>
            <path d="M12 20v2"/>
            <path d="M2 12h2"/>
            <path d="M20 12h2"/>
          </svg>
        </div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.pendingImaging }}</span>
          <span class="stat-label">待检影像</span>
        </div>
        <div class="stat-sub">{{ stats.completedImaging }} 已完成</div>
      </div>

      <div class="stat-card prescription" @click="router.push('/pharmacy')">
        <div class="stat-icon-wrap">
          <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>
          </svg>
        </div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.pendingPrescriptions }}</span>
          <span class="stat-label">待发处方</span>
        </div>
        <div class="stat-sub">{{ stats.todayPrescriptions }} 今日</div>
      </div>

      <div class="stat-card beds" @click="router.push('/inpatient')">
        <div class="stat-icon-wrap">
          <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M2 4v16"/>
            <path d="M22 4v16"/>
            <path d="M2 12h20"/>
            <path d="M2 20h20"/>
            <path d="M6 8h.01"/>
            <path d="M6 16h.01"/>
          </svg>
        </div>
        <div class="stat-body">
          <span class="stat-value">{{ stats.occupiedBeds }}/{{ stats.totalBeds }}</span>
          <span class="stat-label">住院床位</span>
        </div>
        <div class="stat-sub">{{ stats.availableBeds }} 可用</div>
      </div>
    </div>

    <div class="content-grid">
      <el-card class="recent-card">
        <template #header>
          <div class="card-header">
            <span>今日挂号</span>
            <el-button type="primary" link @click="router.push('/registration')">查看全部</el-button>
          </div>
        </template>
        <div class="registration-list" v-if="recentRegistrations.length">
          <div class="reg-item" v-for="reg in recentRegistrations" :key="reg.id">
            <div class="reg-info">
              <span class="reg-name">{{ reg.pat_master?.name }}</span>
              <span class="reg-dept">{{ reg.dept?.name }}</span>
            </div>
            <div class="reg-meta">
              <span class="reg-seq">#{{ reg.sequence_no }}</span>
              <el-tag :type="getStatusType(reg.status)" size="small">{{ getStatusLabel(reg.status) }}</el-tag>
            </div>
          </div>
        </div>
        <el-empty v-else description="今日暂无挂号记录" :image-size="60"/>
      </el-card>

      <el-card class="quick-card">
        <template #header>
          <div class="card-header">
            <span>快捷入口</span>
          </div>
        </template>
        <div class="quick-grid">
          <div class="quick-item" @click="router.push('/patients')">
            <svg class="quick-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/>
              <path d="M12 6v6l4 2"/>
            </svg>
            <span>患者管理</span>
          </div>
          <div class="quick-item" @click="router.push('/registration')">
            <svg class="quick-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/>
              <rect x="8" y="2" width="8" height="4" rx="1"/>
            </svg>
            <span>挂号管理</span>
          </div>
          <div class="quick-item" @click="router.push('/clinic')">
            <svg class="quick-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
            </svg>
            <span>门诊接诊</span>
          </div>
          <div class="quick-item" @click="router.push('/lab')">
            <svg class="quick-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M9 3h6v4l3 9h-12l3-9V3z"/>
              <line x1="8" y1="22" x2="16" y2="22"/>
            </svg>
            <span>检验管理</span>
          </div>
          <div class="quick-item" @click="router.push('/pacs')">
            <svg class="quick-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="4" y="4" width="16" height="16" rx="2"/>
              <circle cx="12" cy="12" r="3"/>
            </svg>
            <span>影像管理</span>
          </div>
          <div class="quick-item" @click="router.push('/pharmacy')">
            <svg class="quick-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z"/>
            </svg>
            <span>药房管理</span>
          </div>
        </div>
      </el-card>

      <el-card class="alerts-card">
        <template #header>
          <div class="card-header">
            <span>系统提醒</span>
            <el-badge :value="alerts.length" :hidden="alerts.length === 0"/>
          </div>
        </template>
        <div class="alerts-list" v-if="alerts.length">
          <div class="alert-item" v-for="alert in alerts" :key="alert.id" :class="alert.type">
            <div class="alert-content">
              <span class="alert-text">{{ alert.text }}</span>
              <span class="alert-time">{{ alert.time }}</span>
            </div>
          </div>
        </div>
        <el-empty v-else description="暂无系统提醒" :image-size="60"/>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/composables/supabase'
import type { OpRegistration } from '@/types'

const router = useRouter()
const authStore = useAuthStore()

const recentRegistrations = ref<OpRegistration[]>([])
const alerts = ref<Array<{ id: number; text: string; time: string; type: string }>>([])

const now = new Date()
const currentDate = now.toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric' })
const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']
const currentWeekday = weekdays[now.getDay()]

const hour = now.getHours()
const timeGreeting = computed(() => {
  if (hour < 6) return '凌晨好'
  if (hour < 9) return '早上好'
  if (hour < 12) return '上午好'
  if (hour < 14) return '中午好'
  if (hour < 18) return '下午好'
  return '晚上好'
})

const roleLabelMap: Record<string, string> = {
  admin: '管理员',
  doctor: '医生',
  nurse: '护士',
  lab_tech: '检验师',
  radiology_tech: '影像技师',
  pharmacist: '药师'
}
const roleLabel = computed(() => roleLabelMap[authStore.profile?.role || ''] || '用户')

const stats = ref({
  totalPatients: 0,
  patientGrowth: 0,
  todayRegistrations: 0,
  pendingRegistrations: 0,
  pendingLab: 0,
  completedLab: 0,
  pendingImaging: 0,
  completedImaging: 0,
  pendingPrescriptions: 0,
  todayPrescriptions: 0,
  totalBeds: 0,
  occupiedBeds: 0,
  availableBeds: 0
})

function getStatusType(status: string) {
  const map: Record<string, string> = {
    registered: 'warning',
    checked_in: 'primary',
    in_progress: 'danger',
    finished: 'success',
    cancelled: 'info',
    no_show: 'danger'
  }
  return map[status] || 'info'
}

function getStatusLabel(status: string) {
  const map: Record<string, string> = {
    registered: '已挂号',
    checked_in: '已报到',
    in_progress: '就诊中',
    finished: '已完成',
    cancelled: '已退号',
    no_show: '爽约'
  }
  return map[status] || status
}

async function fetchDashboardData() {
  const today = new Date().toISOString().split('T')[0]

  const [patientsRes, regRes, labRes, imagingRes, prescriptionRes, bedRes] = await Promise.all([
    supabase.from('pat_master').select('id', { count: 'exact' }).eq('is_deleted', false),
    supabase.from('op_registration').select('*, pat_master:pat_master(name), dept:org_dept(name)').eq('visit_date', today).order('visit_time', { ascending: false }).limit(5),
    supabase.from('lis_request').select('id, status'),
    supabase.from('ris_request').select('id, status'),
    supabase.from('op_prescription').select('id, dispensation_status').gte('create_time', today),
    supabase.from('ip_bed').select('id, status')
  ])

  if (patientsRes.data) {
    stats.value.totalPatients = patientsRes.data.length
  }

  if (regRes.data) {
    stats.value.todayRegistrations = regRes.data.length
    stats.value.pendingRegistrations = regRes.data.filter(r => r.status === 'pending' || r.status === 'in_progress').length
    recentRegistrations.value = regRes.data
  }

  if (labRes.data) {
    const labs = labRes.data
    stats.value.pendingLab = labs.filter(l => l.status === 'pending' || l.status === 'sampled' || l.status === 'testing').length
    stats.value.completedLab = labs.filter(l => l.status === 'reported').length
  }

  if (imagingRes.data) {
    const imaging = imagingRes.data
    stats.value.pendingImaging = imaging.filter(i => i.status === 'pending' || i.status === 'registered' || i.status === 'imaging').length
    stats.value.completedImaging = imaging.filter(i => i.status === 'reported').length
  }

  if (prescriptionRes.data) {
    const scripts = prescriptionRes.data
    stats.value.pendingPrescriptions = scripts.filter(p => p.dispensation_status === 'undispensed').length
    stats.value.todayPrescriptions = scripts.length
  }

  if (bedRes.data) {
    const beds = bedRes.data
    stats.value.totalBeds = beds.length
    stats.value.occupiedBeds = beds.filter(b => b.status === 'occupied').length
    stats.value.availableBeds = beds.filter(b => b.status === 'available').length
  }

  alerts.value = []
  if (stats.value.pendingRegistrations > 0) {
    alerts.value.push({ id: 1, text: `${stats.value.pendingRegistrations} 名患者等待就诊`, time: '现在', type: 'warning' })
  }
  if (stats.value.pendingLab > 0) {
    alerts.value.push({ id: 2, text: `${stats.value.pendingLab} 项检验待完成`, time: '现在', type: 'info' })
  }
  if (stats.value.pendingImaging > 0) {
    alerts.value.push({ id: 3, text: `${stats.value.pendingImaging} 项影像待检查`, time: '现在', type: 'info' })
  }
  if (stats.value.pendingPrescriptions > 0) {
    alerts.value.push({ id: 4, text: `${stats.value.pendingPrescriptions} 张处方待发放`, time: '现在', type: 'warning' })
  }
}

onMounted(() => {
  fetchDashboardData()
})
</script>

<style scoped>
.dashboard {
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 24px 24px;
}

.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 0 20px;
}

.greeting {
  font-size: 24px;
  font-weight: 600;
  color: #1a1a1a;
  margin: 0;
}

.date-info {
  color: #8c8c8c;
  font-size: 14px;
  margin-top: 4px;
}

.role-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
  background: #f0f0f0;
  color: #666;
}

.role-badge.admin { background: #fff2e8; color: #d46b08; }
.role-badge.doctor { background: #e6f7ff; color: #1890ff; }
.role-badge.nurse { background: #f6ffed; color: #52c41a; }

.stats-grid {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 16px;
  margin-bottom: 20px;
}

@media (max-width: 1200px) {
  .stats-grid { grid-template-columns: repeat(3, 1fr); }
}

@media (max-width: 768px) {
  .stats-grid { grid-template-columns: repeat(2, 1fr); }
}

.stat-card {
  background: #fff;
  border-radius: 12px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.2s;
  border: 1px solid #f0f0f0;
  position: relative;
  overflow: hidden;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}

.stat-icon-wrap {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 12px;
}

.stat-card.patients .stat-icon-wrap { background: #e6f7ff; color: #1890ff; }
.stat-card.registration .stat-icon-wrap { background: #fff7e6; color: #fa8c16; }
.stat-card.lab .stat-icon-wrap { background: #f6ffed; color: #52c41a; }
.stat-card.imaging .stat-icon-wrap { background: #fff1f0; color: #ff4d4f; }
.stat-card.prescription .stat-icon-wrap { background: #f9f0ff; color: #722ed1; }
.stat-card.beds .stat-icon-wrap { background: #f0f5ff; color: #2f54eb; }

.stat-icon {
  width: 22px;
  height: 22px;
}

.stat-body {
  display: flex;
  flex-direction: column;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: #1a1a1a;
  line-height: 1.2;
}

.stat-label {
  font-size: 13px;
  color: #8c8c8c;
  margin-top: 4px;
}

.stat-trend {
  position: absolute;
  top: 16px;
  right: 16px;
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 10px;
}

.stat-trend.up { background: #f6ffed; color: #52c41a; }

.stat-sub {
  position: absolute;
  bottom: 16px;
  right: 16px;
  font-size: 12px;
  color: #8c8c8c;
}

.content-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 16px;
}

@media (max-width: 1200px) {
  .content-grid { grid-template-columns: 1fr 1fr; }
}

@media (max-width: 768px) {
  .content-grid { grid-template-columns: 1fr; }
}

.recent-card, .quick-card, .alerts-card {
  border-radius: 12px;
  border: 1px solid #f0f0f0;
}

:deep(.el-card__header) {
  padding: 16px 20px;
  border-bottom: 1px solid #f5f5f5;
}

:deep(.el-card__body) {
  padding: 16px 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 15px;
  font-weight: 500;
  color: #1a1a1a;
}

.registration-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.reg-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px;
  background: #fafafa;
  border-radius: 8px;
  transition: background 0.2s;
}

.reg-item:hover {
  background: #f0f0f0;
}

.reg-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.reg-name {
  font-weight: 500;
  color: #1a1a1a;
}

.reg-dept {
  font-size: 12px;
  color: #8c8c8c;
}

.reg-meta {
  display: flex;
  align-items: center;
  gap: 8px;
}

.reg-seq {
  font-size: 12px;
  color: #8c8c8c;
}

.quick-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.quick-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 16px 8px;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  background: #fafafa;
}

.quick-item:hover {
  background: #e6f7ff;
}

.quick-icon {
  width: 24px;
  height: 24px;
  color: #1890ff;
}

.quick-item span {
  font-size: 12px;
  color: #666;
}

.alerts-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.alert-item {
  padding: 12px;
  border-radius: 8px;
  border-left: 3px solid;
  background: #fafafa;
}

.alert-item.warning { border-left-color: #fa8c16; background: #fff7e6; }
.alert-item.info { border-left-color: #1890ff; background: #e6f7ff; }
.alert-item.success { border-left-color: #52c41a; background: #f6ffed; }

.alert-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.alert-text {
  font-size: 13px;
  color: #1a1a1a;
}

.alert-time {
  font-size: 11px;
  color: #8c8c8c;
}
</style>
