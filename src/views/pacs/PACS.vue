<template>
  <div class="pacs-page">
    <h2>影像管理 (PACS)</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="检查申请" name="requests">
          <el-form :inline="true" class="filter-form">
            <el-form-item label="日期">
              <el-date-picker
                v-model="filterDate"
                type="date"
                placeholder="选择日期"
                style="width: 150px"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
                @change="fetchRequests"
              />
            </el-form-item>
            <el-form-item label="状态">
              <el-select v-model="filterStatus" placeholder="全部" clearable style="width: 120px" @change="fetchRequests">
                <el-option label="待登记" value="pending" />
                <el-option label="已登记" value="registered" />
                <el-option label="检查中" value="imaging" />
                <el-option label="已完成" value="imaging_completed" />
                <el-option label="已报告" value="reported" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button @click="resetFilter">重置</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="requests" stripe style="margin-top: 16px">
            <el-table-column prop="request_no" label="申请单号" width="160" />
            <el-table-column prop="pat_master.name" label="患者姓名" width="100" />
            <el-table-column prop="pat_master.gender" label="性别" width="60" />
            <el-table-column label="年龄" width="70">
              <template #default="{ row }">
                {{ row.pat_master ? getAge(row.pat_master.birth_date) : '-' }}
              </template>
            </el-table-column>
            <el-table-column prop="exam_item_name" label="检查项目" width="150" />
            <el-table-column prop="exam_body_part" label="检查部位" width="100" />
            <el-table-column prop="has_contrast" label="造影" width="70">
              <template #default="{ row }">
                <el-tag v-if="row.has_contrast" type="warning" size="small">需造影</el-tag>
                <span v-else>-</span>
              </template>
            </el-table-column>
            <el-table-column prop="priority" label="优先级" width="80">
              <template #default="{ row }">
                <el-tag v-if="row.priority === 'stat'" type="danger" size="small">急</el-tag>
                <el-tag v-else-if="row.priority === 'urgent'" type="warning" size="small">优先</el-tag>
                <span v-else>普通</span>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="getStatusType(row.status)" size="small">
                  {{ getStatusLabel(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="create_time" label="申请时间" width="160">
              <template #default="{ row }">{{ formatDateTime(row.create_time) }}</template>
            </el-table-column>
            <el-table-column label="操作" width="120">
              <template #default="{ row }">
                <el-button v-if="row.status === 'pending'" type="primary" size="small" @click="registerExam(row)">登记</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="影像管理" name="studies">
          <el-table :data="studies" stripe>
            <el-table-column prop="ris_request.request_no" label="申请单号" width="160" />
            <el-table-column prop="ris_request.pat_master?.name" label="患者姓名" width="100" />
            <el-table-column prop="ris_request.exam_item_name" label="检查项目" width="150" />
            <el-table-column prop="ris_request.exam_body_part" label="检查部位" width="100" />
            <el-table-column prop="exam_time" label="检查时间" width="160">
              <template #default="{ row }">{{ formatDateTime(row.exam_time) }}</template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="getStudyStatusType(row.status)" size="small">
                  {{ getStudyStatusLabel(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="radiologist_id" label="影像医生" width="100">
              <template #default="{ row }">{{ row.radiologist_id ? '已指派' : '-' }}</template>
            </el-table-column>
            <el-table-column label="操作" width="220">
              <template #default="{ row }">
                <el-button v-if="row.status === 'registered'" type="primary" size="small" @click="startImaging(row)">开始检查</el-button>
                <el-button v-if="row.status === 'imaging'" type="success" size="small" @click="completeImaging(row)">检查完成</el-button>
                <el-button v-if="row.status === 'imaging_completed'" type="warning" size="small" @click="showReportDialog(row)">写报告</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="报告管理" name="reports">
          <el-table :data="reports" stripe>
            <el-table-column prop="report_no" label="报告编号" width="160" />
            <el-table-column prop="ris_request?.pat_master?.name" label="患者姓名" width="100" />
            <el-table-column prop="ris_request?.exam_item_name" label="检查项目" width="150" />
            <el-table-column prop="exam_findings" label="检查所见" show-overflow-tooltip />
            <el-table-column prop="exam_conclusion" label="诊断意见" show-overflow-tooltip />
            <el-table-column prop="report_time" label="报告时间" width="160">
              <template #default="{ row }">{{ formatDateTime(row.report_time) }}</template>
            </el-table-column>
            <el-table-column prop="is_print" label="已打印" width="80">
              <template #default="{ row }">
                <el-tag v-if="row.is_print" type="success" size="small">是</el-tag>
                <span v-else>否</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="120">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="viewReport(row)">查看</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <el-dialog v-model="reportDialogVisible" title="编写报告" width="700px">
      <el-form label-width="100px">
        <el-form-item label="检查所见">
          <el-input v-model="reportForm.exam_findings" type="textarea" :rows="6" placeholder="请输入检查所见..." />
        </el-form-item>
        <el-form-item label="诊断意见">
          <el-input v-model="reportForm.exam_conclusion" type="textarea" :rows="4" placeholder="请输入诊断意见..." />
        </el-form-item>
        <el-form-item label="印象">
          <el-input v-model="reportForm.impression" type="textarea" :rows="2" placeholder="请输入印象..." />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="reportDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveReport">保存报告</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="viewDialogVisible" title="报告查看" width="700px">
      <el-descriptions :column="2" border v-if="currentReport">
        <el-descriptions-item label="患者姓名">{{ currentReport.ris_request?.pat_master?.name }}</el-descriptions-item>
        <el-descriptions-item label="检查项目">{{ currentReport.ris_request?.exam_item_name }}</el-descriptions-item>
        <el-descriptions-item label="检查部位" :span="2">{{ currentReport.ris_request?.exam_body_part }}</el-descriptions-item>
        <el-descriptions-item label="检查所见" :span="2">{{ currentReport.exam_findings }}</el-descriptions-item>
        <el-descriptions-item label="诊断意见" :span="2">{{ currentReport.exam_conclusion }}</el-descriptions-item>
        <el-descriptions-item label="印象" :span="2">{{ currentReport.impression }}</el-descriptions-item>
        <el-descriptions-item label="报告时间">{{ formatDateTime(currentReport.report_time) }}</el-descriptions-item>
        <el-descriptions-item label="报告医生">已审核</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="viewDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'

const authStore = useAuthStore()
const activeTab = ref('requests')

const requests = ref<any[]>([])
const studies = ref<any[]>([])
const reports = ref<any[]>([])

const reportDialogVisible = ref(false)
const viewDialogVisible = ref(false)
const currentStudy = ref<any | null>(null)
const currentReport = ref<any | null>(null)

const reportForm = reactive({
  exam_findings: '',
  exam_conclusion: '',
  impression: ''
})

const filterDate = ref('')
const filterStatus = ref('')

function getAge(birthDate: string): number {
  if (!birthDate) return 0
  const today = new Date()
  const birth = new Date(birthDate)
  let age = today.getFullYear() - birth.getFullYear()
  const m = today.getMonth() - birth.getMonth()
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--
  return age
}

async function fetchRequests() {
  let query = supabase
    .from('ris_request')
    .select('*, pat_master:pat_master(name,gender,birth_date)')
    .order('create_time', { ascending: false })
    .limit(100)

  if (filterStatus.value) {
    query = query.eq('status', filterStatus.value)
  }

  const { data } = await query
  requests.value = data || []
}

async function fetchStudies() {
  const { data } = await supabase
    .from('ris_request')
    .select('*, pat_master:pat_master(name)')
    .in('status', ['registered', 'imaging', 'imaging_completed', 'reported'])
    .order('create_time', { ascending: false })

  studies.value = data || []
}

async function fetchReports() {
  const { data } = await supabase
    .from('ris_report')
    .select('*, ris_request:ris_request(*, pat_master:pat_master(name))')
    .order('report_time', { ascending: false })

  reports.value = data || []
}

async function registerExam(row: any) {
  const { error } = await supabase
    .from('ris_request')
    .update({ status: 'registered', exam_time: new Date().toISOString() })
    .eq('id', row.id)

  if (error) ElMessage.error('登记失败')
  else {
    ElMessage.success('已登记')
    fetchRequests()
  }
}

async function startImaging(row: any) {
  const { error } = await supabase
    .from('ris_request')
    .update({ status: 'imaging', exam_time: new Date().toISOString() })
    .eq('id', row.id)

  if (error) ElMessage.error('操作失败')
  else {
    ElMessage.success('已开始检查')
    fetchStudies()
  }
}

async function completeImaging(row: any) {
  const { error } = await supabase
    .from('ris_request')
    .update({ status: 'imaging_completed', exam_end_time: new Date().toISOString() })
    .eq('id', row.id)

  if (error) ElMessage.error('操作失败')
  else {
    ElMessage.success('检查已完成，请书写报告')
    fetchStudies()
  }
}

function showReportDialog(row: any) {
  currentStudy.value = row
  reportForm.exam_findings = ''
  reportForm.exam_conclusion = ''
  reportForm.impression = ''
  reportDialogVisible.value = true
}

async function saveReport() {
  if (!currentStudy.value) return

  const reportNo = `RP${Date.now().toString(36).toUpperCase()}`

  const { error } = await supabase.from('ris_report').insert({
    request_id: currentStudy.value.id,
    pat_id: currentStudy.value.pat_id,
    report_no: reportNo,
    exam_findings: reportForm.exam_findings,
    exam_conclusion: reportForm.exam_conclusion,
    impression: reportForm.impression,
    radiologist_id: authStore.profile?.id,
    report_time: new Date().toISOString(),
    verified_by: authStore.profile?.id,
    verified_time: new Date().toISOString()
  })

  if (error) {
    ElMessage.error('保存失败')
  } else {
    await supabase.from('ris_request').update({ status: 'reported', report_time: new Date().toISOString() }).eq('id', currentStudy.value.id)
    ElMessage.success('报告已保存')
    reportDialogVisible.value = false
    fetchStudies()
    fetchReports()
  }
}

function viewReport(row: any) {
  currentReport.value = row
  viewDialogVisible.value = true
}

function resetFilter() {
  filterDate.value = ''
  filterStatus.value = ''
  fetchRequests()
}

function getStatusType(status: string): string {
  const map: Record<string, string> = {
    pending: 'info',
    registered: 'warning',
    imaging: 'primary',
    imaging_completed: 'success',
    reported: 'success',
    cancelled: 'danger'
  }
  return map[status] || 'info'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    pending: '待登记',
    registered: '已登记',
    imaging: '检查中',
    imaging_completed: '已完成',
    reported: '已报告',
    cancelled: '已取消'
  }
  return map[status] || status
}

function getStudyStatusType(status: string): string {
  const map: Record<string, string> = {
    pending: 'info',
    registered: 'warning',
    imaging: 'primary',
    imaging_completed: 'success',
    reported: 'success'
  }
  return map[status] || 'info'
}

function getStudyStatusLabel(status: string): string {
  const map: Record<string, string> = {
    pending: '待检查',
    registered: '已登记',
    imaging: '检查中',
    imaging_completed: '待报告',
    reported: '已报告'
  }
  return map[status] || status
}

function formatDateTime(dateStr: string | null): string {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchRequests()
  fetchStudies()
  fetchReports()
})
</script>

<style scoped>
.pacs-page {
  max-width: 1600px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}

.filter-form {
  padding: 8px 0;
}
</style>
