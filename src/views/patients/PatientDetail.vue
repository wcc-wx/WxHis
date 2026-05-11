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
            <el-descriptions-item label="患者ID">{{ patient.pat_index_no }}</el-descriptions-item>
            <el-descriptions-item label="姓名">{{ patient.name }}</el-descriptions-item>
            <el-descriptions-item label="性别">{{ patient.gender }}</el-descriptions-item>
            <el-descriptions-item label="年龄">{{ patient.age }}{{ patient.age_unit || '岁' }}</el-descriptions-item>
            <el-descriptions-item label="出生日期">{{ formatDate(patient.birth_date) }}</el-descriptions-item>
            <el-descriptions-item label="身份证号">{{ patient.id_card || '-' }}</el-descriptions-item>
            <el-descriptions-item label="联系电话">{{ patient.phone || '-' }}</el-descriptions-item>
            <el-descriptions-item label="现住址">{{ patient.address || '-' }}</el-descriptions-item>
            <el-descriptions-item label="医保类型">{{ patient.insurance_type || '-' }}</el-descriptions-item>
            <el-descriptions-item label="VIP等级">
              <el-tag v-if="patient.vip_level > 0" type="warning" size="small">VIP Lv{{ patient.vip_level }}</el-tag>
              <span v-else>-</span>
            </el-descriptions-item>
            <el-descriptions-item label="风险等级">
              <el-tag v-if="patient.risk_level === 'high'" type="danger" size="small">高危</el-tag>
              <el-tag v-else-if="patient.risk_level === 'medium'" type="warning" size="small">中危</el-tag>
              <el-tag v-else type="success" size="small">低危</el-tag>
            </el-descriptions-item>
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
                    <p><strong>体格检查：</strong>{{ visit.physical_exam || '-' }}</p>
                    <p><strong>治疗方案：</strong>{{ visit.treatment_plan || '-' }}</p>
                  </el-card>
                </el-timeline-item>
              </el-timeline>
            </el-tab-pane>

            <el-tab-pane label="检验报告" name="lab">
              <el-empty v-if="labResults.length === 0" description="暂无检验报告" />
              <el-table v-else :data="labResults" stripe>
                <el-table-column prop="lis_request.request_no" label="申请单号" width="140" />
                <el-table-column prop="test_item_name" label="检验项目" width="150" />
                <el-table-column prop="result_value" label="结果值" width="120" />
                <el-table-column prop="reference_range" label="参考范围" width="150" />
                <el-table-column prop="is_abnormal" label="异常" width="80">
                  <template #default="{ row }">
                    <el-tag :type="row.is_abnormal ? 'danger' : 'success'" size="small">
                      {{ row.is_abnormal ? row.abnormal_flag || '异常' : '正常' }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="entered_time" label="报告时间">
                  <template #default="{ row }">{{ formatDateTime(row.entered_time) }}</template>
                </el-table-column>
              </el-table>
            </el-tab-pane>

            <el-tab-pane label="影像报告" name="imaging">
              <el-empty v-if="imagingStudies.length === 0" description="暂无影像报告" />
              <el-table v-else :data="imagingStudies" stripe>
                <el-table-column prop="ris_request.exam_item_name" label="检查项目" width="120" />
                <el-table-column prop="ris_request.exam_body_part" label="检查部位" width="100" />
                <el-table-column prop="exam_conclusion" label="诊断意见" show-overflow-tooltip />
                <el-table-column prop="report_time" label="报告时间" width="160">
                  <template #default="{ row }">{{ formatDateTime(row.report_time) }}</template>
                </el-table-column>
              </el-table>
            </el-tab-pane>

            <el-tab-pane label="处方记录" name="prescriptions">
              <el-empty v-if="prescriptions.length === 0" description="暂无处方记录" />
              <el-table v-else :data="prescriptions" stripe>
                <el-table-column prop="prescription_no" label="处方号" width="140" />
                <el-table-column prop="prescription_type" label="处方类型" width="100">
                  <template #default="{ row }">{{ getPrescriptionTypeLabel(row.prescription_type) }}</template>
                </el-table-column>
                <el-table-column prop="total_amount" label="金额" width="80">
                  <template #default="{ row }">¥{{ row.total_amount / 100 }}</template>
                </el-table-column>
                <el-table-column prop="dispensation_status" label="状态" width="100">
                  <template #default="{ row }">
                    <el-tag :type="getPrescriptionStatusType(row.dispensation_status)" size="small">
                      {{ getDispensationLabel(row.dispensation_status) }}
                    </el-tag>
                  </template>
                </el-table-column>
                <el-table-column prop="create_time" label="开方时间" width="160">
                  <template #default="{ row }">{{ formatDateTime(row.create_time) }}</template>
                </el-table-column>
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
import type { PatMaster, OpVisit, LisResult, RisReport, OpPrescription } from '@/types'

const route = useRoute()
const router = useRouter()

const patient = ref<PatMaster | null>(null)
const activeTab = ref('outpatient')

const visits = ref<OpVisit[]>([])
const labResults = ref<LisResult[]>([])
const imagingStudies = ref<RisReport[]>([])
const prescriptions = ref<OpPrescription[]>([])

async function fetchPatientDetail() {
  const patientId = route.params.id as string

  try {
    const { data: patientData, error: patientError } = await supabase
      .from('pat_master')
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
    .from('op_visit')
    .select('*')
    .eq('pat_id', patientId)
    .order('visit_time', { ascending: false })

  visits.value = data || []
}

async function fetchLabResults(patientId: string) {
  const { data } = await supabase
    .from('lis_result')
    .select('*, lis_request:lis_request(request_no)')
    .eq('lis_request.pat_id', patientId)
    .order('create_time', { ascending: false })

  labResults.value = data || []
}

async function fetchImagingStudies(patientId: string) {
  const { data } = await supabase
    .from('ris_report')
    .select('*, ris_request:ris_request(exam_item_name, exam_body_part)')
    .eq('pat_id', patientId)
    .order('create_time', { ascending: false })

  imagingStudies.value = data || []
}

async function fetchPrescriptions(patientId: string) {
  const { data } = await supabase
    .from('op_prescription')
    .select('*')
    .eq('pat_id', patientId)
    .order('create_time', { ascending: false })

  prescriptions.value = data || []
}

function editPatient() {
  ElMessage.info('编辑功能开发中')
}

function formatDate(dateStr: string): string {
  if (!dateStr) return ''
  return dateStr.split('T')[0]
}

function formatDateTime(dateStr: string | null): string {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleString('zh-CN')
}

function getPrescriptionTypeLabel(type: string): string {
  const map: Record<string, string> = {
    western: '西药',
    chinese: '中药',
    mixed: '中西药',
    tcm: '中医'
  }
  return map[type] || type
}

function getPrescriptionStatusType(status: string): string {
  const map: Record<string, string> = {
    undispensed: 'warning',
    partial: 'warning',
    dispensed: 'success',
    returned: 'info',
    cancelled: 'info'
  }
  return map[status] || 'info'
}

function getDispensationLabel(status: string): string {
  const map: Record<string, string> = {
    undispensed: '待发药',
    partial: '部分发药',
    dispensed: '已发药',
    returned: '已退药',
    cancelled: '已取消'
  }
  return map[status] || status
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
