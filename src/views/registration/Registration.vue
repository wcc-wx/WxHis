<template>
  <div class="registration-page">
    <h2>挂号管理</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <!-- 挂号 -->
        <el-tab-pane label="挂号" name="register">
          <el-form :inline="true" :model="registerForm" class="register-form">
            <el-form-item label="患者" required>
              <el-select
                v-model="registerForm.patientId"
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
                  :label="`${p.name} (${p.id_card})`"
                  :value="p.id"
                />
              </el-select>
              <el-button type="success" @click="openNewPatientDialog" style="margin-left: 8px">
                + 新增患者
              </el-button>
            </el-form-item>

            <el-form-item label="患者信息" v-if="selectedPatient">
              <span class="patient-info">
                {{ selectedPatient.name }} / {{ selectedPatient.gender }} / {{ getAge(selectedPatient.birth_date) }}岁
              </span>
            </el-form-item>
          </el-form>

          <el-form :inline="true" :model="registerForm" class="register-form">
            <el-form-item label="科室" required>
              <el-select v-model="registerForm.departmentId" placeholder="选择科室" style="width: 200px" @change="onDepartmentChange">
                <el-option
                  v-for="dept in departments"
                  :key="dept.id"
                  :label="dept.name"
                  :value="dept.id"
                />
              </el-select>
            </el-form-item>

            <el-form-item label="就诊类型" required>
              <el-radio-group v-model="registerForm.visitType" @change="onVisitTypeChange">
                <el-radio-button label="first">初诊</el-radio-button>
                <el-radio-button label="return">复诊</el-radio-button>
              </el-radio-group>
            </el-form-item>

            <el-form-item label="挂号费">
              <span class="fee-display">¥{{ currentFee }}</span>
            </el-form-item>
          </el-form>

          <el-form :inline="true" :model="registerForm" class="register-form">
            <el-form-item label="主诉">
              <el-input v-model="registerForm.complaint" placeholder="简要描述症状" style="width: 300px" />
            </el-form-item>

            <el-form-item label="医生">
              <el-select v-model="registerForm.doctorId" placeholder="可选" clearable style="width: 200px">
                <el-option
                  v-for="doc in filteredDoctors"
                  :key="doc.id"
                  :label="doc.real_name"
                  :value="doc.id"
                />
              </el-select>
            </el-form-item>

            <el-form-item>
              <el-button type="primary" @click="handleRegister" :loading="submitting" :disabled="!canRegister">
                确认挂号 ({{ currentFee }}元)
              </el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <!-- 待诊列表 -->
        <el-tab-pane label="待诊列表" name="pending">
          <el-form :inline="true" class="filter-form">
            <el-form-item label="日期">
              <el-date-picker
                v-model="filterDate"
                type="date"
                placeholder="选择日期"
                style="width: 150px"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
                @change="fetchRegistrations"
              />
            </el-form-item>
            <el-form-item label="科室">
              <el-select v-model="filterDept" placeholder="全部科室" clearable style="width: 150px" @change="fetchRegistrations">
                <el-option v-for="dept in departments" :key="dept.id" :label="dept.name" :value="dept.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="状态">
              <el-select v-model="filterStatus" placeholder="全部" clearable style="width: 120px" @change="fetchRegistrations">
                <el-option label="待诊" value="pending" />
                <el-option label="就诊中" value="in_progress" />
                <el-option label="已完成" value="finished" />
                <el-option label="已退号" value="cancelled" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button @click="resetFilters">重置</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="registrations" stripe style="margin-top: 16px">
            <el-table-column prop="sequence_no" label="序号" width="70" />
            <el-table-column prop="patient.name" label="患者姓名" width="100" />
            <el-table-column prop="patient.gender" label="性别" width="60" />
            <el-table-column label="年龄" width="70">
              <template #default="{ row }">
                {{ row.patient ? getAge(row.patient.birth_date) : '-' }}
              </template>
            </el-table-column>
            <el-table-column prop="department.name" label="科室" width="100" />
            <el-table-column prop="visit_type" label="类型" width="70">
              <template #default="{ row }">
                {{ row.visit_type === 'first' ? '初诊' : '复诊' }}
              </template>
            </el-table-column>
            <el-table-column prop="registration_fee" label="挂号费" width="80">
              <template #default="{ row }">¥{{ row.registration_fee }}</template>
            </el-table-column>
            <el-table-column prop="payment_status" label="支付" width="80">
              <template #default="{ row }">
                <el-tag size="small" :type="row.payment_status === 'paid' ? 'success' : row.payment_status === 'refunded' ? 'info' : 'warning'">
                  {{ row.payment_status === 'paid' ? '已付' : row.payment_status === 'refunded' ? '已退' : '未付' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="80">
              <template #default="{ row }">
                <el-tag size="small" :type="getStatusType(row.status)">
                  {{ getStatusLabel(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="registration_time" label="挂号时间" width="160">
              <template #default="{ row }">
                {{ formatDateTime(row.registration_time) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="200">
              <template #default="{ row }">
                <el-button v-if="row.status === 'pending'" type="primary" size="small" @click="callPatient(row)">叫号</el-button>
                <el-button v-if="row.status === 'pending'" type="warning" size="small" @click="editRegistration(row)">编辑</el-button>
                <el-button v-if="row.status === 'pending'" type="danger" size="small" @click="cancelRegistration(row)">退号</el-button>
                <span v-if="row.status !== 'pending'" class="action-hint">-</span>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 新增患者对话框 -->
    <el-dialog v-model="newPatientDialogVisible" title="新增患者" width="500px">
      <el-form :model="newPatientForm" label-width="80px">
        <el-form-item label="姓名" required>
          <el-input v-model="newPatientForm.name" placeholder="请输入姓名" />
        </el-form-item>
        <el-form-item label="性别" required>
          <el-radio-group v-model="newPatientForm.gender">
            <el-radio label="男">男</el-radio>
            <el-radio label="女">女</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="出生日期" required>
          <el-date-picker
            v-model="newPatientForm.birth_date"
            type="date"
            placeholder="选择日期"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="身份证号" required>
          <el-input v-model="newPatientForm.id_card" placeholder="请输入身份证号" />
        </el-form-item>
        <el-form-item label="电话">
          <el-input v-model="newPatientForm.phone" placeholder="请输入电话" />
        </el-form-item>
        <el-form-item label="地址">
          <el-input v-model="newPatientForm.address" placeholder="请输入地址" />
        </el-form-item>
        <el-form-item label="血型">
          <el-select v-model="newPatientForm.blood_type" placeholder="请选择" clearable style="width: 100%">
            <el-option label="A型" value="A" />
            <el-option label="B型" value="B" />
            <el-option label="O型" value="O" />
            <el-option label="AB型" value="AB" />
          </el-select>
        </el-form-item>
        <el-form-item label="过敏史">
          <el-input v-model="newPatientForm.allergy_history" type="textarea" placeholder="请输入过敏史（无则留空）" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="newPatientDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingPatient" @click="saveNewPatient">保存并选择</el-button>
      </template>
    </el-dialog>

    <!-- 编辑对话框 -->
    <el-dialog v-model="editDialogVisible" title="编辑挂号" width="450px">
      <el-form :model="editForm" label-width="80px">
        <el-form-item label="科室">
          <el-select v-model="editForm.departmentId" style="width: 100%">
            <el-option v-for="dept in departments" :key="dept.id" :label="dept.name" :value="dept.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="医生">
          <el-select v-model="editForm.doctorId" placeholder="可选" clearable style="width: 100%">
            <el-option v-for="doc in editFormDoctors" :key="doc.id" :label="doc.real_name" :value="doc.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="主诉">
          <el-input v-model="editForm.complaint" type="textarea" rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveRegistration">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { Patient, Department, UserProfile } from '@/types'
import type { VisitType } from '@/types'

const activeTab = ref('register')
const searching = ref(false)
const submitting = ref(false)
const saving = ref(false)
const searchResults = ref<Patient[]>([])
const departments = ref<Department[]>([])
const doctors = ref<UserProfile[]>([])
const registrations = ref<any[]>([])
const selectedPatient = ref<Patient | null>(null)
const registrationFees = ref<Record<string, Record<string, number>>>({})
const editDialogVisible = ref(false)
const editFormDoctors = ref<UserProfile[]>([])
const newPatientDialogVisible = ref(false)
const savingPatient = ref(false)

const newPatientForm = reactive({
  name: '',
  gender: '男' as '男' | '女',
  birth_date: '',
  id_card: '',
  phone: '',
  address: '',
  blood_type: '',
  allergy_history: ''
})

const registerForm = reactive({
  patientId: '',
  departmentId: '',
  visitType: 'first' as VisitType,
  doctorId: '',
  complaint: ''
})

const editForm = reactive({
  id: '',
  departmentId: '',
  doctorId: '',
  complaint: ''
})

const filterDate = ref('')
const filterDept = ref('')
const filterStatus = ref('')

const currentFee = computed(() => {
  if (!registerForm.departmentId || !registerForm.visitType) return 0
  return registrationFees.value[registerForm.departmentId]?.[registerForm.visitType] || 0
})

const filteredDoctors = computed(() => {
  if (!registerForm.departmentId) return []
  return doctors.value.filter(d => d.department_id === registerForm.departmentId && d.role === 'doctor')
})

const canRegister = computed(() => {
  return registerForm.patientId && registerForm.departmentId && registerForm.visitType
})

function getAge(birthDate: string): number {
  const today = new Date()
  const birth = new Date(birthDate)
  let age = today.getFullYear() - birth.getFullYear()
  const m = today.getMonth() - birth.getMonth()
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--
  return age
}

async function searchPatients(query: string) {
  if (!query) { searchResults.value = []; return }
  searching.value = true
  try {
    const { data } = await supabase
      .from('patients')
      .select('*')
      .or(`name.ilike.%${query}%,id_card.ilike.%${query}%`)
      .limit(10)
    searchResults.value = data || []
  } finally {
    searching.value = false
  }
}

function onPatientChange(patientId: string) {
  selectedPatient.value = searchResults.value.find(p => p.id === patientId) || null
}

async function onDepartmentChange() {
  registerForm.doctorId = ''
}

function onVisitTypeChange() {
  // fee will auto-update via computed
}

function openNewPatientDialog() {
  newPatientForm.name = ''
  newPatientForm.gender = '男'
  newPatientForm.birth_date = ''
  newPatientForm.id_card = ''
  newPatientForm.phone = ''
  newPatientForm.address = ''
  newPatientForm.blood_type = ''
  newPatientForm.allergy_history = ''
  newPatientDialogVisible.value = true
}

async function saveNewPatient() {
  if (!newPatientForm.name || !newPatientForm.birth_date || !newPatientForm.id_card) {
    ElMessage.warning('请填写姓名、出生日期和身份证号')
    return
  }

  savingPatient.value = true
  try {
    const { data, error } = await supabase
      .from('patients')
      .insert({
        name: newPatientForm.name,
        gender: newPatientForm.gender,
        birth_date: newPatientForm.birth_date,
        id_card: newPatientForm.id_card,
        phone: newPatientForm.phone || null,
        address: newPatientForm.address || null,
        blood_type: newPatientForm.blood_type || null,
        allergy_history: newPatientForm.allergy_history || null
      })
      .select()
      .single()

    if (error) throw error

    ElMessage.success('患者添加成功')
    newPatientDialogVisible.value = false

    // Auto select the new patient
    registerForm.patientId = data.id
    selectedPatient.value = data
    searchResults.value = [data]
  } catch (error: any) {
    ElMessage.error(error.message || '添加患者失败')
  } finally {
    savingPatient.value = false
  }
}

async function handleRegister() {
  if (!canRegister.value) {
    ElMessage.warning('请选择患者、科室和就诊类型')
    return
  }

  submitting.value = true
  try {
    const { data: maxSeq } = await supabase
      .from('registrations')
      .select('sequence_no')
      .eq('department_id', registerForm.departmentId)
      .gte('registration_time', new Date().toISOString().split('T')[0])
      .order('sequence_no', { ascending: false })
      .limit(1)

    const nextSeq = maxSeq && maxSeq.length > 0 ? (maxSeq[0].sequence_no || 0) + 1 : 1

    const { error } = await supabase.from('registrations').insert({
      patient_id: registerForm.patientId,
      department_id: registerForm.departmentId,
      doctor_id: registerForm.doctorId || null,
      registration_time: new Date().toISOString(),
      sequence_no: nextSeq,
      status: 'pending',
      registration_fee: currentFee.value,
      visit_type: registerForm.visitType,
      complaint: registerForm.complaint || null,
      payment_status: 'paid'
    })

    if (error) throw error

    ElMessage.success('挂号成功')
    registerForm.patientId = ''
    registerForm.departmentId = ''
    registerForm.visitType = 'first'
    registerForm.doctorId = ''
    registerForm.complaint = ''
    selectedPatient.value = null
    searchResults.value = []
    activeTab.value = 'pending'
    fetchRegistrations()
  } catch (error: any) {
    ElMessage.error(error.message || '挂号失败')
  } finally {
    submitting.value = false
  }
}

async function fetchDepartments() {
  const { data } = await supabase.from('departments').select('*').order('name')
  departments.value = data || []
}

async function fetchDoctors() {
  const { data } = await supabase.from('users_profile').select('*').eq('role', 'doctor')
  doctors.value = data || []
}

async function fetchRegistrationFees() {
  const { data } = await supabase.from('registration_fees').select('*')
  const fees: Record<string, Record<string, number>> = {}
  for (const f of (data || [])) {
    if (!fees[f.department_id]) fees[f.department_id] = {}
    fees[f.department_id][f.visit_type] = parseFloat(f.fee)
  }
  registrationFees.value = fees
}

async function fetchRegistrations() {
  let query = supabase
    .from('registrations')
    .select('*, patient:patients(*), department:departments(*)')
    .order('registration_time', { ascending: false })
    .limit(100)

  if (filterDate.value) {
    query = query.gte('registration_time', filterDate.value + 'T00:00:00')
         .lt('registration_time', filterDate.value + 'T23:59:59')
  }
  if (filterDept.value) {
    query = query.eq('department_id', filterDept.value)
  }
  if (filterStatus.value) {
    query = query.eq('status', filterStatus.value)
  }

  const { data } = await query
  registrations.value = data || []
}

function resetFilters() {
  filterDate.value = ''
  filterDept.value = ''
  filterStatus.value = ''
  fetchRegistrations()
}

function editRegistration(row: any) {
  editForm.id = row.id
  editForm.departmentId = row.department_id
  editForm.doctorId = row.doctor_id || ''
  editForm.complaint = row.complaint || ''
  editFormDoctors.value = doctors.value.filter(d => d.department_id === row.department_id && d.role === 'doctor')
  editDialogVisible.value = true
}

async function saveRegistration() {
  saving.value = true
  try {
    const { error } = await supabase
      .from('registrations')
      .update({
        department_id: editForm.departmentId,
        doctor_id: editForm.doctorId || null,
        complaint: editForm.complaint || null
      })
      .eq('id', editForm.id)
    if (error) throw error
    ElMessage.success('保存成功')
    editDialogVisible.value = false
    fetchRegistrations()
  } catch (error: any) {
    ElMessage.error(error.message || '保存失败')
  } finally {
    saving.value = false
  }
}

async function cancelRegistration(row: any) {
  try {
    await ElMessageBox.confirm(`确定退号给 "${row.patient?.name}" 吗？挂号费将退还。`, '退号确认', {
      confirmButtonText: '确定退号',
      cancelButtonText: '取消',
      type: 'warning'
    })

    const { error } = await supabase
      .from('registrations')
      .update({ status: 'cancelled', payment_status: 'refunded' })
      .eq('id', row.id)

    if (error) throw error
    ElMessage.success('退号成功')
    fetchRegistrations()
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error(e.message || '退号失败')
  }
}

function callPatient(row: any) {
  ElMessage.success(`叫号：${row.patient?.name}，请到${row.department?.name}就诊`)
}

function formatDateTime(dateStr: string): string {
  return new Date(dateStr).toLocaleString('zh-CN')
}

function getStatusType(status: string): string {
  const map: Record<string, string> = {
    pending: 'warning',
    in_progress: 'primary',
    finished: 'success',
    cancelled: 'info'
  }
  return map[status] || 'info'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    pending: '待诊',
    in_progress: '就诊中',
    finished: '已完成',
    cancelled: '已退号'
  }
  return map[status] || status
}

onMounted(() => {
  const today = new Date().toISOString().split('T')[0]
  filterDate.value = today
  fetchDepartments()
  fetchDoctors()
  fetchRegistrationFees()
  fetchRegistrations()
})
</script>

<style scoped>
.registration-page {
  max-width: 1400px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}

.register-form {
  padding: 16px 0;
}

.patient-info {
  color: #409eff;
  font-weight: 500;
}

.fee-display {
  font-size: 18px;
  font-weight: bold;
  color: #f56c6c;
}

.filter-form {
  padding: 8px 0;
}

.action-hint {
  color: #c0c4cc;
}
</style>
