<template>
  <div class="clinic-page">
    <h2>门诊工作站</h2>
    <el-row :gutter="20">
      <el-col :span="8">
        <el-card header="今日接诊">
          <el-table :data="todayQueue" stripe height="400">
            <el-table-column prop="sequence_no" label="序号" width="60" />
            <el-table-column prop="pat_master.name" label="患者" />
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
                  :disabled="!['registered', 'checked_in'].includes(row.status)"
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
              <span>{{ currentVisit.pat_master?.name }}</span>
            </el-form-item>
            <el-form-item label="主诉">
              <el-input v-model="currentVisit.chief_complaint" type="textarea" rows="2" />
            </el-form-item>
            <el-form-item label="现病史">
              <el-input v-model="currentVisit.present_illness" type="textarea" rows="3" />
            </el-form-item>
            <el-form-item label="既往史">
              <el-input v-model="currentVisit.past_history" type="textarea" rows="2" />
            </el-form-item>
            <el-form-item label="体格检查">
              <el-input v-model="currentVisit.physical_exam" type="textarea" rows="2" />
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

    <el-dialog v-model="showPrescriptionDialog" title="开具处方" width="600px">
      <el-form :model="prescriptionForm" label-width="80px">
        <el-form-item label="药品">
          <el-select v-model="prescriptionForm.drugId" placeholder="选择药品" filterable style="width: 100%">
            <el-option v-for="drug in drugs" :key="drug.id" :label="`${drug.common_name} (${drug.spec}) ¥${drug.price / 100}`" :value="drug.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="剂量">
          <el-input v-model="prescriptionForm.dosage" placeholder="如：0.5g" />
        </el-form-item>
        <el-form-item label="用法">
          <el-select v-model="prescriptionForm.usage" placeholder="选择用法">
            <el-option label="口服" value="口服" />
            <el-option label="静注" value="静脉注射" />
            <el-option label="肌注" value="肌肉注射" />
            <el-option label="外用" value="外用" />
            <el-option label="雾化" value="吸入" />
          </el-select>
        </el-form-item>
        <el-form-item label="频次">
          <el-select v-model="prescriptionForm.frequency" placeholder="选择频次">
            <el-option label="每日1次" value="QD" />
            <el-option label="每日2次" value="BID" />
            <el-option label="每日3次" value="TID" />
            <el-option label="每日4次" value="QID" />
            <el-option label="必要时" value="PRN" />
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

    <el-dialog v-model="showLabDialog" title="开具检验申请" width="500px">
      <el-form label-width="80px">
        <el-form-item label="检验项目">
          <el-select v-model="labForm.testItemId" placeholder="选择检验项目" filterable style="width: 100%">
            <el-option v-for="item in testItems" :key="item.id" :label="`${item.name} (${item.category || '常规'})`" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="标本类型">
          <el-select v-model="labForm.specimenType" placeholder="选择标本类型">
            <el-option label="血液" value="血液" />
            <el-option label="尿液" value="尿液" />
            <el-option label="粪便" value="粪便" />
            <el-option label="痰液" value="痰液" />
            <el-option label="脑脊液" value="脑脊液" />
            <el-option label="胸腹水" value="胸腹水" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showLabDialog = false">取消</el-button>
        <el-button type="primary" @click="submitLabRequest">提交</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="showImagingDialog" title="开具检查申请" width="500px">
      <el-form label-width="80px">
        <el-form-item label="检查项目">
          <el-select v-model="imagingForm.examItemId" placeholder="选择检查项目" filterable style="width: 100%">
            <el-option v-for="item in examItems" :key="item.id" :label="`${item.name} (${item.category})`" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="检查部位">
          <el-input v-model="imagingForm.examBodyPart" placeholder="如：胸部、腹部" />
        </el-form-item>
        <el-form-item label="检查方法">
          <el-input v-model="imagingForm.examMethod" placeholder="如：平扫、增强" />
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
import type { MdDrug, MdLisItem, MdRisItem } from '@/types'

const authStore = useAuthStore()

const todayQueue = ref<any[]>([])
const currentVisit = ref<any | null>(null)
const drugs = ref<MdDrug[]>([])
const testItems = ref<MdLisItem[]>([])
const examItems = ref<MdRisItem[]>([])

const showPrescriptionDialog = ref(false)
const showLabDialog = ref(false)
const showImagingDialog = ref(false)

const prescriptionForm = reactive({
  drugId: '',
  dosage: '',
  usage: '',
  frequency: '',
  quantity: 1
})

const labForm = reactive({
  testItemId: '',
  specimenType: ''
})

const imagingForm = reactive({
  examItemId: '',
  examBodyPart: '',
  examMethod: ''
})

async function fetchTodayQueue() {
  const today = new Date().toISOString().split('T')[0]

  const { data } = await supabase
    .from('op_registration')
    .select('*, pat_master:pat_master(name), dept:org_dept(name)')
    .eq('visit_date', today)
    .in('status', ['registered', 'checked_in', 'in_progress'])
    .order('sequence_no')

  todayQueue.value = data || []
}

async function startVisit(row: any) {
  await supabase
    .from('op_registration')
    .update({ status: 'in_progress' })
    .eq('id', row.id)

  const visitSn = `V${new Date().toISOString().split('T')[0].replace(/-/g, '')}${Date.now().toString(36).toUpperCase()}`

  const { data } = await supabase
    .from('op_visit')
    .insert({
      pat_id: row.pat_id,
      visit_sn: visitSn,
      reg_id: row.id,
      dept_id: row.dept_id,
      doctor_id: authStore.profile?.id,
      visit_time: new Date().toISOString(),
      chief_complaint: row.complaint,
      visit_type: row.visit_type
    })
    .select()
    .single()

  currentVisit.value = { ...row, visit: data }
  await fetchTodayQueue()
}

async function saveVisit() {
  if (!currentVisit.value?.visit) return

  const { error } = await supabase
    .from('op_visit')
    .update({
      chief_complaint: currentVisit.value.chief_complaint,
      present_illness: currentVisit.value.present_illness,
      past_history: currentVisit.value.past_history,
      physical_exam: currentVisit.value.physical_exam
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
    supabase.from('op_registration').update({ status: 'finished' }).eq('id', currentVisit.value.id),
    supabase.from('op_visit').update({}).eq('id', currentVisit.value.visit.id)
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

  const drug = drugs.value.find(d => d.id === prescriptionForm.drugId)
  if (!drug) return

  const prescriptionNo = `RX${Date.now().toString(36).toUpperCase()}`

  const { error } = await supabase.from('op_prescription').insert({
    pat_id: currentVisit.value.pat_id,
    visit_sn: currentVisit.value.visit_sn,
    visit_id: currentVisit.value.visit.id,
    prescription_no: prescriptionNo,
    dept_id: currentVisit.value.dept_id,
    doctor_id: authStore.profile?.id,
    diagnosis: JSON.stringify([{ name: currentVisit.value.diagnosis || '待定' }]),
    total_amount: drug.price * prescriptionForm.quantity,
    prescription_type: 'western'
  })

  if (error) {
    ElMessage.error('开方失败')
  } else {
    ElMessage.success('处方已开具')
    showPrescriptionDialog.value = false
    prescriptionForm.drugId = ''
    prescriptionForm.dosage = ''
    prescriptionForm.usage = ''
    prescriptionForm.frequency = ''
    prescriptionForm.quantity = 1
  }
}

async function submitLabRequest() {
  if (!labForm.testItemId || !labForm.specimenType) {
    ElMessage.warning('请填写完整信息')
    return
  }

  const item = testItems.value.find(t => t.id === labForm.testItemId)
  if (!item) return

  const requestNo = `LIS${Date.now().toString(36).toUpperCase()}`

  const { error } = await supabase.from('lis_request').insert({
    request_no: requestNo,
    pat_id: currentVisit.value.pat_id,
    visit_id: currentVisit.value.visit.id,
    visit_sn: currentVisit.value.visit_sn,
    patient_name: currentVisit.value.pat_master?.name,
    dept_id: currentVisit.value.dept_id,
    doctor_id: authStore.profile?.id,
    specimen_type: labForm.specimenType,
    test_items: JSON.stringify([{ id: item.id, name: item.name }]),
    status: 'pending'
  })

  if (error) {
    ElMessage.error('提交失败')
  } else {
    ElMessage.success('检验申请已提交')
    showLabDialog.value = false
    labForm.testItemId = ''
    labForm.specimenType = ''
  }
}

async function submitImagingRequest() {
  if (!imagingForm.examItemId) {
    ElMessage.warning('请选择检查项目')
    return
  }

  const item = examItems.value.find(e => e.id === imagingForm.examItemId)
  if (!item) return

  const requestNo = `RIS${Date.now().toString(36).toUpperCase()}`

  const { error } = await supabase.from('ris_request').insert({
    request_no: requestNo,
    pat_id: currentVisit.value.pat_id,
    visit_id: currentVisit.value.visit.id,
    visit_sn: currentVisit.value.visit_sn,
    patient_name: currentVisit.value.pat_master?.name,
    dept_id: currentVisit.value.dept_id,
    doctor_id: authStore.profile?.id,
    exam_item_id: item.id,
    exam_item_name: item.name,
    exam_body_part: imagingForm.examBodyPart || item.exam_body_part,
    exam_method: imagingForm.examMethod,
    has_contrast: item.has_contrast,
    priority: 'normal',
    status: 'pending'
  })

  if (error) {
    ElMessage.error('提交失败')
  } else {
    ElMessage.success('检查申请已提交')
    showImagingDialog.value = false
    imagingForm.examItemId = ''
    imagingForm.examBodyPart = ''
    imagingForm.examMethod = ''
  }
}

function getStatusType(status: string): string {
  const map: Record<string, string> = {
    registered: 'warning',
    checked_in: 'primary',
    in_progress: 'danger',
    finished: 'success',
    cancelled: 'info'
  }
  return map[status] || 'info'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    registered: '已挂号',
    checked_in: '已报到',
    in_progress: '就诊中',
    finished: '已完成',
    cancelled: '已退号'
  }
  return map[status] || status
}

onMounted(async () => {
  await fetchTodayQueue()

  const [drugsRes, testItemsRes, examItemsRes] = await Promise.all([
    supabase.from('md_drug').select('*').eq('status', 'active').limit(100),
    supabase.from('md_lis_item').select('*').eq('status', 'active'),
    supabase.from('md_ris_item').select('*').eq('status', 'active')
  ])

  drugs.value = drugsRes.data || []
  testItems.value = testItemsRes.data || []
  examItems.value = examItemsRes.data || []
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
