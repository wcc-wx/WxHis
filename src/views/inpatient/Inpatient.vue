<template>
  <div class="inpatient-page">
    <h2>住院管理</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="入院登记" name="admit">
          <el-form :inline="true" :model="admitForm" class="admit-form">
            <el-form-item label="患者">
              <el-select
                v-model="admitForm.patId"
                filterable
                remote
                placeholder="搜索患者姓名或身份证"
                :remote-method="searchPatients"
                :loading="searching"
                style="width: 280px"
                @change="onPatientChange"
              >
                <el-option
                  v-for="p in searchResults"
                  :key="p.id"
                  :label="`${p.name} (${p.id_card || '无身份证'})`"
                  :value="p.id"
                />
              </el-select>
            </el-form-item>
            <el-form-item label="患者信息" v-if="selectedPatient">
              <span class="patient-info">
                {{ selectedPatient.name }} / {{ selectedPatient.gender }} / {{ getAge(selectedPatient.birth_date) }}岁
              </span>
            </el-form-item>
          </el-form>

          <el-form :inline="true" :model="admitForm" class="admit-form">
            <el-form-item label="病区" required>
              <el-select v-model="admitForm.wardId" placeholder="选择病区" style="width: 200px" @change="onWardChange">
                <el-option
                  v-for="ward in wards"
                  :key="ward.id"
                  :label="ward.ward_name"
                  :value="ward.id"
                />
              </el-select>
            </el-form-item>
            <el-form-item label="床位" required>
              <el-select v-model="admitForm.bedId" placeholder="选择床位" style="width: 150px">
                <el-option
                  v-for="bed in availableBeds"
                  :key="bed.id"
                  :label="`${bed.bed_no}床 (¥${bed.price / 100}/日)`"
                  :value="bed.id"
                />
              </el-select>
            </el-form-item>
            <el-form-item label="入院科室" required>
              <el-select v-model="admitForm.deptId" placeholder="选择科室" style="width: 200px">
                <el-option
                  v-for="dept in clinicalDepts"
                  :key="dept.id"
                  :label="dept.name"
                  :value="dept.id"
                />
              </el-select>
            </el-form-item>
            <el-form-item label="主治医生">
              <el-select v-model="admitForm.doctorId" placeholder="选择医生" clearable style="width: 180px">
                <el-option
                  v-for="doc in doctors"
                  :key="doc.id"
                  :label="doc.name"
                  :value="doc.id"
                />
              </el-select>
            </el-form-item>
          </el-form>

          <el-form :inline="true" :model="admitForm" class="admit-form">
            <el-form-item label="入院诊断">
              <el-input v-model="admitForm.admissionDiagnosis" placeholder="请输入诊断" style="width: 300px" />
            </el-form-item>
            <el-form-item label="入院情况">
              <el-radio-group v-model="admitForm.admissionCondition">
                <el-radio-button label="normal">一般</el-radio-button>
                <el-radio-button label="urgent">紧急</el-radio-button>
                <el-radio-button label="emergency">急诊</el-radio-button>
              </el-radio-group>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="handleAdmit" :loading="submitting" :disabled="!canAdmit">
                办理入院
              </el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="在院患者" name="inpatients">
          <el-form :inline="true" class="filter-form">
            <el-form-item label="病区">
              <el-select v-model="filterWard" placeholder="全部" clearable style="width: 150px" @change="fetchAdmissions">
                <el-option v-for="ward in wards" :key="ward.id" :label="ward.ward_name" :value="ward.id" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button @click="resetFilter">重置</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="admissions" stripe style="margin-top: 16px">
            <el-table-column prop="pat_master.name" label="姓名" width="100" />
            <el-table-column prop="pat_master.gender" label="性别" width="60" />
            <el-table-column label="年龄" width="70">
              <template #default="{ row }">
                {{ row.pat_master ? getAge(row.pat_master.birth_date) : '-' }}
              </template>
            </el-table-column>
            <el-table-column prop="admission_no" label="住院号" width="140" />
            <el-table-column prop="org_dept.name" label="科室" width="100" />
            <el-table-column prop="ip_bed.bed_no" label="床位" width="80">
              <template #default="{ row }">{{ row.ip_bed?.bed_no }}床</template>
            </el-table-column>
            <el-table-column prop="admission_diagnosis" label="入院诊断" show-overflow-tooltip />
            <el-table-column prop="admission_date" label="入院日期" width="100">
              <template #default="{ row }">{{ row.admission_date }}</template>
            </el-table-column>
            <el-table-column prop="total_expense" label="费用" width="100">
              <template #default="{ row }">¥{{ (row.total_expense || 0) / 100 }}</template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="90">
              <template #default="{ row }">
                <el-tag size="small" :type="row.status === 'in_hospital' ? 'success' : 'info'">
                  {{ row.status === 'in_hospital' ? '在院' : '已出院' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="220">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="viewDetail(row)">详情</el-button>
                <el-button type="warning" size="small" @click="transferBed(row)">转床</el-button>
                <el-button type="success" size="small" @click="discharge(row)">出院</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="床位概览" name="beds">
          <el-row :gutter="20">
            <el-col :span="8" v-for="ward in wardsWithBeds" :key="ward.id">
              <el-card :header="ward.ward_name + ' (' + ward.bed_count + '床)'">
                <el-space wrap>
                  <el-tag
                    v-for="bed in ward.beds"
                    :key="bed.id"
                    :type="getBedType(bed.status)"
                    :color="bed.status === 'occupied' ? undefined : ''"
                    style="margin: 4px; cursor: pointer"
                    @click="bedClick(bed)"
                  >
                    {{ bed.bed_no }}床
                    <span v-if="bed.status === 'occupied'" style="font-size: 10px">
                      ({{ getBedPatient(bed.id)?.pat_master?.name }})
                    </span>
                  </el-tag>
                </el-space>
                <div style="margin-top: 12px; text-align: center">
                  <el-tag type="success" style="margin: 0 4px">可用 {{ ward.availableCount }}</el-tag>
                  <el-tag type="danger" style="margin: 0 4px">占用 {{ ward.occupiedCount }}</el-tag>
                  <el-tag type="warning" style="margin: 0 4px">维护 {{ ward.maintenanceCount }}</el-tag>
                </div>
              </el-card>
            </el-col>
          </el-row>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <el-dialog v-model="transferDialogVisible" title="床位转床" width="400px">
      <el-form :model="transferForm" label-width="80px">
        <el-form-item label="当前床位">
          <el-input :value="currentBed?.bed_no + '床'" disabled />
        </el-form-item>
        <el-form-item label="目标病区">
          <el-select v-model="transferForm.toWardId" placeholder="选择病区" style="width: 100%" @change="onTransferWardChange">
            <el-option v-for="ward in wards" :key="ward.id" :label="ward.ward_name" :value="ward.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="目标床位">
          <el-select v-model="transferForm.toBedId" placeholder="选择床位" style="width: 100%">
            <el-option v-for="bed in transferAvailableBeds" :key="bed.id" :label="`${bed.bed_no}床`" :value="bed.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="转床原因">
          <el-input v-model="transferForm.reason" type="textarea" rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="transferDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmTransfer">确认转床</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { PatMaster, OrgDept, OrgWard, IpBed, HrEmployee } from '@/types'

const activeTab = ref('admit')
const searching = ref(false)
const submitting = ref(false)
const transferDialogVisible = ref(false)

const searchResults = ref<PatMaster[]>([])
const wards = ref<OrgWard[]>([])
const beds = ref<IpBed[]>([])
const departments = ref<OrgDept[]>([])
const doctors = ref<HrEmployee[]>([])
const admissions = ref<any[]>([])
const selectedPatient = ref<PatMaster | null>(null)

const admitForm = reactive({
  patId: '',
  wardId: '',
  bedId: '',
  deptId: '',
  doctorId: '',
  admissionDiagnosis: '',
  admissionCondition: 'normal' as 'normal' | 'urgent' | 'emergency'
})

const transferForm = reactive({
  admissionId: '',
  fromBedId: '',
  toWardId: '',
  toBedId: '',
  reason: ''
})

const filterWard = ref('')

const clinicalDepts = computed(() =>
  departments.value.filter(d => d.dept_type === 'clinical' && d.status === 'active')
)

const availableBeds = computed(() =>
  beds.value.filter(b => b.status === 'available' && b.ward_id === admitForm.wardId)
)

const wardsWithBeds = computed(() => {
  return wards.value.map(ward => {
    const wardBeds = beds.value.filter(b => b.ward_id === ward.id)
    return {
      ...ward,
      beds: wardBeds,
      bed_count: ward.bed_count || wardBeds.length,
      availableCount: wardBeds.filter(b => b.status === 'available').length,
      occupiedCount: wardBeds.filter(b => b.status === 'occupied').length,
      maintenanceCount: wardBeds.filter(b => b.status === 'maintenance').length
    }
  })
})

const transferAvailableBeds = computed(() =>
  beds.value.filter(b => b.status === 'available' && b.ward_id === transferForm.toWardId)
)

const currentBed = computed(() =>
  beds.value.find(b => b.id === transferForm.fromBedId)
)

const canAdmit = computed(() =>
  admitForm.patId && admitForm.wardId && admitForm.bedId && admitForm.deptId
)

function getAge(birthDate: string): number {
  if (!birthDate) return 0
  const today = new Date()
  const birth = new Date(birthDate)
  let age = today.getFullYear() - birth.getFullYear()
  const m = today.getMonth() - birth.getMonth()
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--
  return age
}

function getBedPatient(bedId: string): any {
  return admissions.value.find(a => a.bed_id === bedId && a.status === 'in_hospital')
}

async function searchPatients(query: string) {
  if (!query) { searchResults.value = []; return }
  searching.value = true
  try {
    const { data } = await supabase
      .from('pat_master')
      .select('*')
      .eq('is_deleted', false)
      .or(`name.ilike.%${query}%,id_card.ilike.%${query}%,phone.ilike.%${query}%`)
      .limit(10)
    searchResults.value = data || []
  } finally {
    searching.value = false
  }
}

function onPatientChange(patId: string) {
  selectedPatient.value = searchResults.value.find(p => p.id === patId) || null
}

function onWardChange() {
  admitForm.bedId = ''
}

function onTransferWardChange() {
  transferForm.toBedId = ''
}

async function handleAdmit() {
  if (!canAdmit.value) {
    ElMessage.warning('请选择患者、病区、床位和科室')
    return
  }

  submitting.value = true
  try {
    const today = new Date().toISOString().split('T')[0]
    const admissionNo = `I${today.replace(/-/g, '')}${Date.now().toString(36).toUpperCase()}`
    const visitSn = `V${today.replace(/-/g, '')}${Date.now().toString(36).toUpperCase()}`

    const { error: admitError } = await supabase.from('ip_admission').insert({
      pat_id: admitForm.patId,
      admission_no: admissionNo,
      visit_sn: visitSn,
      dept_id: admitForm.deptId,
      ward_id: admitForm.wardId,
      bed_id: admitForm.bedId,
      doctor_id: admitForm.doctorId || null,
      admitting_doctor_id: admitForm.doctorId || null,
      admission_date: today,
      admission_time: new Date().toISOString(),
      admission_diagnosis: admitForm.admissionDiagnosis || null,
      admission_condition: admitForm.admissionCondition,
      total_expense: 0,
      prepayment_amount: 0,
      status: 'in_hospital'
    })

    if (admitError) throw admitError

    await supabase.from('ip_bed').update({ status: 'occupied' }).eq('id', admitForm.bedId)

    ElMessage.success('入院办理成功')
    Object.assign(admitForm, { patId: '', wardId: '', bedId: '', deptId: '', doctorId: '', admissionDiagnosis: '', admissionCondition: 'normal' })
    selectedPatient.value = null
    await fetchData()
  } catch (error: any) {
    ElMessage.error(error.message || '入院办理失败')
  } finally {
    submitting.value = false
  }
}

async function discharge(row: any) {
  try {
    await ElMessageBox.confirm(
      `确定为患者 "${row.pat_master?.name}" 办理出院吗？`,
      '出院确认',
      { confirmButtonText: '确定出院', cancelButtonText: '取消', type: 'warning' }
    )

    const { error } = await supabase
      .from('ip_admission')
      .update({
        status: 'discharged',
        discharge_date: new Date().toISOString().split('T')[0],
        discharge_time: new Date().toISOString()
      })
      .eq('id', row.id)

    if (error) throw error

    await supabase.from('ip_bed').update({ status: 'available' }).eq('id', row.bed_id)

    ElMessage.success('出院办理成功')
    await fetchAdmissions()
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error(e.message || '出院办理失败')
  }
}

function transferBed(row: any) {
  transferForm.admissionId = row.id
  transferForm.fromBedId = row.bed_id
  transferForm.toWardId = row.ward_id
  transferForm.toBedId = ''
  transferForm.reason = ''
  transferDialogVisible.value = true
}

async function confirmTransfer() {
  if (!transferForm.toBedId) {
    ElMessage.warning('请选择目标床位')
    return
  }

  try {
    const { error } = await supabase.from('ip_bed_transfer').insert({
      admission_id: transferForm.admissionId,
      pat_id: admissions.value.find(a => a.id === transferForm.admissionId)?.pat_id,
      from_ward_id: currentBed.value?.ward_id,
      from_bed_id: transferForm.fromBedId,
      to_ward_id: transferForm.toWardId,
      to_bed_id: transferForm.toBedId,
      transfer_time: new Date().toISOString(),
      transfer_type: 'routine',
      reason: transferForm.reason || null
    })

    if (error) throw error

    await Promise.all([
      supabase.from('ip_bed').update({ status: 'available' }).eq('id', transferForm.fromBedId),
      supabase.from('ip_bed').update({ status: 'occupied' }).eq('id', transferForm.toBedId),
      supabase.from('ip_admission').update({ ward_id: transferForm.toWardId, bed_id: transferForm.toBedId }).eq('id', transferForm.admissionId)
    ])

    ElMessage.success('转床成功')
    transferDialogVisible.value = false
    await fetchData()
  } catch (error: any) {
    ElMessage.error(error.message || '转床失败')
  }
}

function viewDetail(row: any) {
  ElMessage.info('患者详情页开发中: ' + row.admission_no)
}

function bedClick(bed: IpBed) {
  if (bed.status === 'occupied') {
    const patient = getBedPatient(bed.id)
    ElMessage.info(`床位 ${bed.bed_no}：${patient?.pat_master?.name || '患者'}`)
  }
}

function resetFilter() {
  filterWard.value = ''
  fetchAdmissions()
}

async function fetchWards() {
  const { data } = await supabase
    .from('org_ward')
    .select('*')
    .eq('is_deleted', false)
    .eq('status', 'active')
    .order('ward_code')
  wards.value = data || []
}

async function fetchBeds() {
  const { data } = await supabase
    .from('ip_bed')
    .select('*')
    .eq('is_deleted', false)
    .order('bed_no')
  beds.value = data || []
}

async function fetchDepartments() {
  const { data } = await supabase
    .from('org_dept')
    .select('*')
    .eq('is_deleted', false)
    .eq('status', 'active')
    .order('sort_order')
  departments.value = data || []
}

async function fetchDoctors() {
  const { data } = await supabase
    .from('hr_employee')
    .select('*')
    .eq('is_deleted', false)
    .eq('status', 'active')
    .eq('emp_type', 'doctor')
  doctors.value = data || []
}

async function fetchAdmissions() {
  let query = supabase
    .from('ip_admission')
    .select('*, pat_master:pat_master(name,gender,birth_date), org_dept:org_dept(name), ip_bed:ip_bed(bed_no,ward_id)')
    .eq('is_deleted', false)
    .order('admission_time', { ascending: false })

  if (filterWard.value) {
    query = query.eq('ward_id', filterWard.value)
  }

  const { data } = await query
  admissions.value = data || []
}

async function fetchData() {
  await Promise.all([fetchWards(), fetchBeds(), fetchDepartments(), fetchDoctors(), fetchAdmissions()])
}

function getBedType(status: string): string {
  const map: Record<string, string> = { available: 'success', occupied: 'danger', maintenance: 'warning', reserved: 'info' }
  return map[status] || 'info'
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.inpatient-page {
  max-width: 1600px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}

.admit-form {
  padding: 20px 0;
}

.filter-form {
  padding: 8px 0;
}

.patient-info {
  color: #409eff;
  font-weight: 500;
}
</style>
