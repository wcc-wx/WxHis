<template>
  <div class="clinic-page">
    <h2>门诊工作站</h2>
    <el-row :gutter="20">
      <el-col :span="8">
        <el-card header="今日接诊">
          <el-table :data="todayQueue" stripe height="400">
            <el-table-column prop="sequence_no" label="序号" width="60" />
            <el-table-column prop="patient.name" label="患者" />
            <el-table-column prop="status" label="状态" width="80">
              <template #default="{ row }">
                <el-tag :type="getStatusType(row.status)" size="small">
                  {{ getStatusLabel(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="80">
              <template #default="{ row }">
                <el-button
                  type="primary"
                  size="small"
                  :disabled="row.status !== 'pending'"
                  @click="startVisit(row)"
                >
                  接诊
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>

      <el-col :span="16">
        <el-card v-if="currentVisit" header="当前就诊">
          <el-form label-width="100px">
            <el-form-item label="患者姓名">
              <span>{{ currentVisit.patient?.name }}</span>
            </el-form-item>
            <el-form-item label="主诉">
              <el-input v-model="currentVisit.chief_complaint" type="textarea" rows="2" />
            </el-form-item>
            <el-form-item label="现病史">
              <el-input v-model="currentVisit.present_illness" type="textarea" rows="3" />
            </el-form-item>
            <el-form-item label="诊断">
              <el-input v-model="currentVisit.diagnosis" />
            </el-form-item>
            <el-form-item label="处理">
              <el-space wrap>
                <el-button type="primary" @click="showPrescriptionDialog = true">开处方</el-button>
                <el-button type="success" @click="showLabDialog = true">开检验</el-button>
                <el-button type="warning" @click="showImagingDialog = true">开检查</el-button>
              </el-space>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="saveVisit">保存病历</el-button>
              <el-button type="success" @click="finishVisit">完成就诊</el-button>
            </el-form-item>
          </el-form>
        </el-card>
        <el-card v-else>
          <el-empty description="请从左侧选择患者接诊" />
        </el-card>
      </el-col>
    </el-row>

    <!-- 处方对话框 -->
    <el-dialog v-model="showPrescriptionDialog" title="开具处方" width="600px">
      <el-form :model="prescriptionForm" label-width="80px">
        <el-form-item label="药品">
          <el-select v-model="prescriptionForm.drugId" placeholder="选择药品" style="width: 100%">
            <el-option v-for="drug in drugs" :key="drug.id" :label="`${drug.name} (${drug.spec})`" :value="drug.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="剂量">
          <el-input v-model="prescriptionForm.dosage" placeholder="如：0.5g" />
        </el-form-item>
        <el-form-item label="用法">
          <el-select v-model="prescriptionForm.usage" placeholder="选择用法">
            <el-option label="口服" value="口服" />
            <el-option label="静注" value="静注" />
            <el-option label="肌注" value="肌注" />
            <el-option label="外用" value="外用" />
            <el-option label="雾化" value="雾化" />
          </el-select>
        </el-form-item>
        <el-form-item label="数量">
          <el-input-number v-model="prescriptionForm.quantity" :min="1" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showPrescriptionDialog = false">取消</el-button>
        <el-button type="primary" @click="addPrescriptionItem">添加</el-button>
      </template>
    </el-dialog>

    <!-- 检验对话框 -->
    <el-dialog v-model="showLabDialog" title="开具检验申请" width="500px">
      <el-form label-width="80px">
        <el-form-item label="检验项目">
          <el-select v-model="labForm.testItemId" placeholder="选择检验项目" style="width: 100%">
            <el-option v-for="item in testItems" :key="item.id" :label="item.name" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="标本类型">
          <el-select v-model="labForm.specimenType" placeholder="选择标本类型">
            <el-option label="血液" value="血液" />
            <el-option label="尿液" value="尿液" />
            <el-option label="粪便" value="粪便" />
            <el-option label="痰液" value="痰液" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showLabDialog = false">取消</el-button>
        <el-button type="primary" @click="submitLabRequest">提交</el-button>
      </template>
    </el-dialog>

    <!-- 影像检查对话框 -->
    <el-dialog v-model="showImagingDialog" title="开具检查申请" width="500px">
      <el-form label-width="80px">
        <el-form-item label="检查类型">
          <el-select v-model="imagingForm.examType" placeholder="选择检查类型">
            <el-option label="CT" value="CT" />
            <el-option label="MR" value="MR" />
            <el-option label="X-Ray" value="X-Ray" />
            <el-option label="超声" value="超声" />
          </el-select>
        </el-form-item>
        <el-form-item label="检查部位">
          <el-input v-model="imagingForm.examPart" placeholder="如：胸部、腹部" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showImagingDialog = false">取消</el-button>
        <el-button type="primary" @click="submitImagingRequest">提交</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'
import type { Registration, Drug, TestItem } from '@/types'

const authStore = useAuthStore()

const todayQueue = ref<any[]>([])
const currentVisit = ref<any | null>(null)
const drugs = ref<Drug[]>([])
const testItems = ref<TestItem[]>([])

const showPrescriptionDialog = ref(false)
const showLabDialog = ref(false)
const showImagingDialog = ref(false)

const prescriptionForm = reactive({
  drugId: '',
  dosage: '',
  usage: '',
  quantity: 1
})

const labForm = reactive({
  testItemId: '',
  specimenType: ''
})

const imagingForm = reactive({
  examType: '',
  examPart: ''
})

async function fetchTodayQueue() {
  const today = new Date().toISOString().split('T')[0]

  const { data } = await supabase
    .from('registrations')
    .select(`
      *,
      patient:patients(*),
      department:departments(*)
    `)
    .gte('registration_time', `${today}T00:00:00`)
    .lte('registration_time', `${today}T23:59:59`)
    .order('sequence_no')

  todayQueue.value = data || []
}

async function startVisit(row: any) {
  await supabase
    .from('registrations')
    .update({ status: 'in_progress' })
    .eq('id', row.id)

  const { data } = await supabase
    .from('outpatient_visits')
    .insert({
      registration_id: row.id,
      patient_id: row.patient_id,
      doctor_id: authStore.profile?.id,
      visit_time: new Date().toISOString()
    })
    .select()
    .single()

  currentVisit.value = { ...row, visit: data }
  await fetchTodayQueue()
}

async function saveVisit() {
  if (!currentVisit.value?.visit) return

  const { error } = await supabase
    .from('outpatient_visits')
    .update({
      chief_complaint: currentVisit.value.chief_complaint,
      present_illness: currentVisit.value.present_illness,
      diagnosis: currentVisit.value.diagnosis
    })
    .eq('id', currentVisit.value.visit.id)

  if (error) {
    ElMessage.error('保存失败')
  } else {
    ElMessage.success('保存成功')
  }
}

async function finishVisit() {
  if (!currentVisit.value) return

  await Promise.all([
    supabase.from('registrations').update({ status: 'finished' }).eq('id', currentVisit.value.id),
    supabase.from('outpatient_visits').update({ diagnosis: currentVisit.value.diagnosis }).eq('id', currentVisit.value.visit.id)
  ])

  ElMessage.success('就诊完成')
  currentVisit.value = null
  await fetchTodayQueue()
}

async function addPrescriptionItem() {
  if (!prescriptionForm.drugId || !prescriptionForm.usage) {
    ElMessage.warning('请填写完整信息')
    return
  }

  ElMessage.success('已添加到处方')
  showPrescriptionDialog.value = false
}

async function submitLabRequest() {
  if (!labForm.testItemId || !labForm.specimenType) {
    ElMessage.warning('请填写完整信息')
    return
  }

  ElMessage.success('检验申请已提交')
  showLabDialog.value = false
}

async function submitImagingRequest() {
  if (!imagingForm.examType || !imagingForm.examPart) {
    ElMessage.warning('请填写完整信息')
    return
  }

  ElMessage.success('检查申请已提交')
  showImagingDialog.value = false
}

function getStatusType(status: string): string {
  const map: Record<string, string> = { pending: 'warning', in_progress: 'primary', finished: 'success' }
  return map[status] || 'info'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = { pending: '待诊', in_progress: '就诊中', finished: '已完成' }
  return map[status] || status
}

onMounted(async () => {
  await fetchTodayQueue()

  const [drugsRes, testItemsRes] = await Promise.all([
    supabase.from('drugs').select('*').limit(50),
    supabase.from('test_items').select('*')
  ])

  drugs.value = drugsRes.data || []
  testItems.value = testItemsRes.data || []
})
</script>

<style scoped>
.clinic-page {
  max-width: 1400px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}
</style>
