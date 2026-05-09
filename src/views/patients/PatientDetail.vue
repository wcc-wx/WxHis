<template>
  <div class="patient-detail" v-if="patient">
    <div class="page-header">
      <el-button @click="router.back()">返回</el-button>
      <h2>患者详情</h2>
    </div>

    <el-row :gutter="20">
      <el-col :span="8">
        <el-card>
          <template #header>
            <span>基本信息</span>
            <el-button type="primary" size="small" @click="editPatient">编辑</el-button>
          </template>
          <el-descriptions :column="1" border>
            <el-descriptions-item label="姓名">{{ patient.name }}</el-descriptions-item>
            <el-descriptions-item label="性别">{{ patient.gender }}</el-descriptions-item>
            <el-descriptions-item label="出生日期">{{ formatDate(patient.birth_date) }}</el-descriptions-item>
            <el-descriptions-item label="身份证号">{{ patient.id_card }}</el-descriptions-item>
            <el-descriptions-item label="联系电话">{{ patient.phone || '-' }}</el-descriptions-item>
            <el-descriptions-item label="住址">{{ patient.address || '-' }}</el-descriptions-item>
            <el-descriptions-item label="血型">{{ patient.blood_type || '-' }}</el-descriptions-item>
            <el-descriptions-item label="过敏史">{{ patient.allergy_history || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>

      <el-col :span="16">
        <el-card>
          <template #header>
            <span>就诊记录</span>
          </template>
          <el-tabs v-model="activeTab">
            <el-tab-pane label="门诊记录" name="outpatient">
              <el-empty v-if="visits.length === 0" description="暂无门诊记录" />
              <el-timeline v-else>
                <el-timeline-item
                  v-for="visit in visits"
                  :key="visit.id"
                  :timestamp="formatDateTime(visit.visit_time)"
                  placement="top"
                >
                  <el-card>
                    <p><strong>主诉：</strong>{{ visit.chief_complaint || '-' }}</p>
                    <p><strong>现病史：</strong>{{ visit.present_illness || '-' }}</p>
                    <p><strong>诊断：</strong>{{ visit.diagnosis || '-' }}</p>
                  </el-card>
                </el-timeline-item>
              </el-timeline>
            </el-tab-pane>

            <el-tab-pane label="检验报告" name="lab">
              <el-empty v-if="labResults.length === 0" description="暂无检验报告" />
              <el-table v-else :data="labResults" stripe>
                <el-table-column prop="test_item_name" label="检验项目" width="150" />
                <el-table-column prop="result_value" label="结果值" width="120" />
                <el-table-column prop="reference_range" label="参考范围" width="150" />
                <el-table-column prop="is_abnormal" label="异常" width="80">
                  <template #default="{ row }">
                    <el-tag :type="row.is_abnormal ? 'danger' : 'success'" size="small">
                      {{ row.is_abnormal ? '异常' : '正常' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="entered_at" label="报告时间">
                  <template #default="{ row }">
                    {{ formatDateTime(row.entered_at) }}
                  </template>
                </el-table-column>
              </el-table>
            </el-tab-pane>

            <el-tab-pane label="影像报告" name="imaging">
              <el-empty v-if="imagingStudies.length === 0" description="暂无影像报告" />
              <el-table v-else :data="imagingStudies" stripe>
                <el-table-column prop="exam_type" label="检查类型" width="100" />
                <el-table-column prop="exam_part" label="检查部位" width="120" />
                <el-table-column prop="report_content" label="报告内容" show-overflow-tooltip />
                <el-table-column prop="exam_time" label="检查时间" width="180">
                  <template #default="{ row }">
                    {{ formatDateTime(row.exam_time) }}
                  </template>
                </el-table-column>
              </el-table>
            </el-tab-pane>

            <el-tab-pane label="处方记录" name="prescriptions">
              <el-empty v-if="prescriptions.length === 0" description="暂无处方记录" />
              <el-table v-else :data="prescriptions" stripe>
                <el-table-column prop="prescription_date" label="处方日期" width="120">
                  <template #default="{ row }">
                    {{ formatDate(row.prescription_date) }}
                  </template>
                </el-table-column>
                <el-table-column prop="status" label="状态" width="100">
                  <template #default="{ row }">
                    <el-tag :type="getPrescriptionStatusType(row.status)" size="small">
                      {{ getPrescriptionStatusLabel(row.status) }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="doctor_name" label="开方医生" width="100" />
              </el-table>
            </el-tab-pane>
          </el-tabs>
        </el-card>
      </el-col>
    </el-row>
  </div>

  <div v-else class="loading">
    <el-skeleton :rows="10" animated />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/composables/supabase'
import { ElMessage } from 'element-plus'
import type { Patient, OutpatientVisit, LabResult, ImagingStudy, Prescription } from '@/types'

const route = useRoute()
const router = useRouter()

const patient = ref<Patient | null>(null)
const activeTab = ref('outpatient')

const visits = ref<OutpatientVisit[]>([])
const labResults = ref<any[]>([])
const imagingStudies = ref<ImagingStudy[]>([])
const prescriptions = ref<any[]>([])

async function fetchPatientDetail() {
  const patientId = route.params.id as string

  try {
    const { data: patientData, error: patientError } = await supabase
      .from('patients')
      .select('*')
      .eq('id', patientId)
      .single()

    if (patientError) throw patientError
    patient.value = patientData

    await Promise.all([
      fetchVisits(patientId),
      fetchLabResults(patientId),
      fetchImagingStudies(patientId),
      fetchPrescriptions(patientId)
    ])
  } catch (error: any) {
    ElMessage.error(error.message || '获取患者详情失败')
  }
}

async function fetchVisits(patientId: string) {
  const { data } = await supabase
    .from('outpatient_visits')
    .select('*')
    .eq('patient_id', patientId)
    .order('visit_time', { ascending: false })

  visits.value = data || []
}

async function fetchLabResults(patientId: string) {
  const { data } = await supabase
    .from('lab_results')
    .select(`
      *,
      test_item:test_items(name),
      lab_request:lab_requests(*)
    `)
    .eq('lab_request.patient_id', patientId)
    .order('entered_at', { ascending: false })

  labResults.value = (data || []).map((item: any) => ({
    ...item,
    test_item_name: item.test_item?.name
  }))
}

async function fetchImagingStudies(patientId: string) {
  const { data } = await supabase
    .from('imaging_studies')
    .select(`
      *,
      imaging_request:imaging_requests(exam_type, exam_part)
    `)
    .eq('patient_id', patientId)
    .order('exam_time', { ascending: false })

  imagingStudies.value = (data || []).map((item: any) => ({
    ...item,
    exam_type: item.imaging_request?.exam_type,
    exam_part: item.imaging_request?.exam_part
  }))
}

async function fetchPrescriptions(patientId: string) {
  const { data } = await supabase
    .from('prescriptions')
    .select(`
      *,
      doctor:users_profile!prescriptions_doctor_id_fkey(real_name)
    `)
    .eq('patient_id', patientId)
    .order('prescription_date', { ascending: false })

  prescriptions.value = (data || []).map((item: any) => ({
    ...item,
    doctor_name: item.doctor?.real_name
  }))
}

function editPatient() {
  // TODO: implement edit patient dialog
}

function formatDate(dateStr: string): string {
  if (!dateStr) return ''
  return dateStr.split('T')[0]
}

function formatDateTime(dateStr: string | null): string {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleString('zh-CN')
}

function getPrescriptionStatusType(status: string): string {
  const typeMap: Record<string, string> = {
    pending: 'warning',
    dispensed: 'success',
    cancelled: 'info'
  }
  return typeMap[status] || 'info'
}

function getPrescriptionStatusLabel(status: string): string {
  const labelMap: Record<string, string> = {
    pending: '待发药',
    dispensed: '已发药',
    cancelled: '已取消'
  }
  return labelMap[status] || status
}

onMounted(() => {
  fetchPatientDetail()
})
</script>

<style scoped>
.patient-detail {
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  align-items: center;
  gap: 20px;
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0;
  font-size: 20px;
  color: #303133;
}

.loading {
  padding: 20px;
}
</style>
