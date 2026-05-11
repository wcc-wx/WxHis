<template>
  <div class="registration-page">
    <h2>门诊挂号</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="挂号" name="register">
          <el-form :inline="true" :model="registerForm" class="register-form">
            <el-form-item label="患者" required>
              <el-select
                v-model="registerForm.patId"
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
              <el-button type="success" @click="openNewPatientDialog" style="margin-left: 8px">
                + 新建患者
              </el-button>
            </el-form-item>

            <el-form-item label="患者信息" v-if="selectedPatient">
              <span class="patient-info">
                {{ selectedPatient.name }} / {{ selectedPatient.gender }} /
                {{ getAge(selectedPatient.birth_date) }}岁 /
                <el-tag v-if="selectedPatient.vip_level > 0" type="warning" size="small">VIP Lv{{ selectedPatient.vip_level }}</el-tag>
                <el-tag v-if="selectedPatient.risk_level === 'high'" type="danger" size="small">高危</el-tag>
              </span>
            </el-form-item>
          </el-form>

          <el-form :inline="true" :model="registerForm" class="register-form">
            <el-form-item label="科室" required>
              <el-select v-model="registerForm.deptId" placeholder="选择科室" style="width: 200px" @change="onDepartmentChange">
                <el-option
                  v-for="dept in departments"
                  :key="dept.id"
                  :label="dept.name"
                  :value="dept.id"
                />
              </el-select>
            </el-form-item>

            <el-form-item label="门诊类型" required>
              <el-radio-group v-model="registerForm.clinicType" @change="onClinicTypeChange">
                <el-radio-button label="general">普通门诊</el-radio-button>
                <el-radio-button label="special">专科门诊</el-radio-button>
                <el-radio-button label="expert">专家门诊</el-radio-button>
                <el-radio-button label="emergency">急诊</el-radio-button>
              </el-radio-group>
            </el-form-item>

            <el-form-item label="号源医生">
              <el-select v-model="registerForm.doctorId" placeholder="可选" clearable style="width: 200px">
                <el-option
                  v-for="doc in filteredDoctors"
                  :key="doc.id"
                  :label="doc.name"
                  :value="doc.id"
                />
              </el-select>
            </el-form-item>
          </el-form>

          <el-form :inline="true" :model="registerForm" class="register-form">
            <el-form-item label="就诊类型" required>
              <el-radio-group v-model="registerForm.visitType" @change="onVisitTypeChange">
                <el-radio-button label="first">初诊</el-radio-button>
                <el-radio-button label="return">复诊</el-radio-button>
              </el-radio-group>
            </el-form-item>

            <el-form-item label="主诉">
              <el-input v-model="registerForm.complaint" placeholder="简要描述症状" style="width: 300px" />
            </el-form-item>

            <el-form-item label="挂号费">
              <span class="fee-display">¥{{ (currentRegFee + currentServiceFee) / 100 }}元</span>
            </el-form-item>

            <el-form-item>
              <el-button type="primary" @click="handleRegister" :loading="submitting" :disabled="!canRegister">
                确认挂号
              </el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

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
                <el-option label="已挂号" value="registered" />
                <el-option label="已报到" value="checked_in" />
                <el-option label="就诊中" value="in_progress" />
                <el-option label="已完成" value="finished" />
                <el-option label="已退号" value="cancelled" />
                <el-option label="爽约" value="no_show" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button @click="resetFilters">重置</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="registrations" stripe style="margin-top: 16px">
            <el-table-column prop="sequence_no" label="顺序号" width="70" />
            <el-table-column prop="visit_sn" label="就诊流水号" width="140" />
            <el-table-column prop="pat_master.name" label="患者姓名" width="100" />
            <el-table-column prop="pat_master.gender" label="性别" width="60" />
            <el-table-column label="年龄" width="70">
              <template #default="{ row }">
                {{ row.pat_master ? getAge(row.pat_master.birth_date) : '-' }}
              </template>
            </el-table-column>
            <el-table-column prop="dept.name" label="科室" width="100" />
            <el-table-column prop="doctor.name" label="医生" width="80" />
            <el-table-column prop="visit_type" label="类型" width="70">
              <template #default="{ row }">
                {{ row.visit_type === 'first' ? '初诊' : '复诊' }}
              </template>
            </el-table-column>
            <el-table-column prop="clinic_type" label="门诊" width="90">
              <template #default="{ row }">
                {{ getClinicTypeLabel(row.clinic_type) }}
              </template>
            </el-table-column>
            <el-table-column prop="total_fee" label="费用" width="80">
              <template #default="{ row }">¥{{ row.total_fee / 100 }}</template>
            </el-table-column>
            <el-table-column prop="payment_status" label="支付" width="80">
              <template #default="{ row }">
                <el-tag size="small" :type="getPaymentType(row.payment_status)">
                  {{ getPaymentLabel(row.payment_status) }}
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
            <el-table-column prop="visit_time" label="挂号时间" width="160">
              <template #default="{ row }">
                {{ formatDateTime(row.visit_time) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="200">
              <template #default="{ row }">
                <el-button v-if="row.status === 'registered'" type="primary" size="small" @click="checkIn(row)">报到</el-button>
                <el-button v-if="['registered', 'checked_in'].includes(row.status)" type="warning" size="small" @click="editRegistration(row)">编辑</el-button>
                <el-button v-if="['registered', 'checked_in'].includes(row.status)" type="danger" size="small" @click="cancelRegistration(row)">退号</el-button>
                <span v-if="!['registered', 'checked_in'].includes(row.status)" class="action-hint">-</span>
              </template>
            </el-table-column>
          </el-table>

          <div class="pagination-wrapper">
            <el-pagination
              v-model:current-page="pagination.page"
              v-model:page-size="pagination.pageSize"
              :total="pagination.total"
              :page-sizes="[10, 20, 50, 100]"
              layout="total, sizes, prev, pager, next, jumper"
              @size-change="handleSizeChange"
              @current-change="handlePageChange"
            />
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <el-dialog v-model="newPatientDialogVisible" title="新建患者档案" width="600px">
      <el-form :model="newPatientForm" label-width="100px" :rules="patientRules" ref="newPatientFormRef">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="姓名" prop="name">
              <el-input v-model="newPatientForm.name" placeholder="请输入姓名" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="性别" prop="gender">
              <el-radio-group v-model="newPatientForm.gender">
                <el-radio label="男">男</el-radio>
                <el-radio label="女">女</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="出生日期" prop="birth_date">
              <el-date-picker
                v-model="newPatientForm.birth_date"
                type="date"
                placeholder="选择日期"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="身份证号" prop="id_card">
              <el-input v-model="newPatientForm.id_card" placeholder="请输入身份证号" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="联系电话">
              <el-input v-model="newPatientForm.phone" placeholder="请输入手机号" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="医保类型">
              <el-select v-model="newPatientForm.insurance_type" placeholder="请选择" style="width: 100%">
                <el-option label="自费" value="自费" />
                <el-option label="职工医保" value="职工医保" />
                <el-option label="居民医保" value="居民医保" />
                <el-option label="新农合" value="新农合" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="现住址">
          <el-input v-model="newPatientForm.address" placeholder="请输入现住址" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="newPatientDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingPatient" @click="saveNewPatient">保存并选择</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="editDialogVisible" title="编辑挂号" width="450px">
      <el-form :model="editForm" label-width="80px">
        <el-form-item label="科室">
          <el-select v-model="editForm.deptId" style="width: 100%" @change="onEditDeptChange">
            <el-option v-for="dept in departments" :key="dept.id" :label="dept.name" :value="dept.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="医生">
          <el-select v-model="editForm.doctorId" placeholder="可选" clearable style="width: 100%">
            <el-option v-for="doc in editFormDoctors" :key="doc.id" :label="doc.name" :value="doc.id" />
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
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import type { PatMaster, OrgDept, HrEmployee } from '@/types'

const activeTab = ref('register')
const searching = ref(false)
const submitting = ref(false)
const saving = ref(false)
const searchResults = ref<PatMaster[]>([])
const departments = ref<OrgDept[]>([])
const doctors = ref<HrEmployee[]>([])
const registrations = ref<any[]>([])
const selectedPatient = ref<PatMaster | null>(null)
const editDialogVisible = ref(false)
const editFormDoctors = ref<HrEmployee[]>([])
const newPatientDialogVisible = ref(false)
const savingPatient = ref(false)
const newPatientFormRef = ref<FormInstance>()

const pagination = ref({ page: 1, pageSize: 10, total: 0 })

const newPatientForm = reactive({
  name: '',
  gender: '男' as '男' | '女',
  birth_date: '',
  id_card: '',
  phone: '',
  insurance_type: '自费',
  address: ''
})

const patientRules: FormRules = {
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  gender: [{ required: true, message: '请选择性别', trigger: 'change' }],
  birth_date: [{ required: true, message: '请选择出生日期', trigger: 'change' }]
}

const registerForm = reactive({
  patId: '',
  deptId: '',
  clinicType: 'general' as 'general' | 'special' | 'expert' | 'emergency',
  visitType: 'first' as 'first' | 'return',
  doctorId: '',
  complaint: ''
})

const editForm = reactive({
  id: '',
  deptId: '',
  doctorId: '',
  complaint: ''
})

const filterDate = ref('')
const filterDept = ref('')
const filterStatus = ref('')

const currentRegFee = computed(() => {
  const dept = departments.value.find(d => d.id === registerForm.deptId)
  return dept?.reg_fee || 0
})

const currentServiceFee = computed(() => {
  if (registerForm.clinicType === 'expert') return 5000
  if (registerForm.clinicType === 'special') return 3000
  return 0
})

const filteredDoctors = computed(() => {
  if (!registerForm.deptId) return []
  return doctors.value.filter(d => d.dept_id === registerForm.deptId && d.emp_type === 'doctor' && d.status === 'active')
})

const canRegister = computed(() => {
  return registerForm.patId && registerForm.deptId && registerForm.visitType
})

function getAge(birthDate: string): number {
  if (!birthDate) return 0
  const today = new Date()
  const birth = new Date(birthDate)
  let age = today.getFullYear() - birth.getFullYear()
  const m = today.getMonth() - birth.getMonth()
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--
  return age
}

function calculateAge(birthDate: string): number {
  return getAge(birthDate)
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

function onDepartmentChange() {
  registerForm.doctorId = ''
}

function onClinicTypeChange() {
  registerForm.doctorId = ''
}

function onVisitTypeChange() {}

function onEditDeptChange() {
  editFormDoctors.value = doctors.value.filter(d => d.dept_id === editForm.deptId && d.emp_type === 'doctor' && d.status === 'active')
}

function openNewPatientDialog() {
  newPatientForm.name = ''
  newPatientForm.gender = '男'
  newPatientForm.birth_date = ''
  newPatientForm.id_card = ''
  newPatientForm.phone = ''
  newPatientForm.insurance_type = '自费'
  newPatientForm.address = ''
  newPatientDialogVisible.value = true
}

async function saveNewPatient() {
  if (!newPatientForm.name || !newPatientForm.birth_date) {
    ElMessage.warning('请填写姓名和出生日期')
    return
  }

  savingPatient.value = true
  try {
    const age = calculateAge(newPatientForm.birth_date)
    const patIndexNo = 'P' + Date.now().toString(36).toUpperCase()
    const { data, error } = await supabase
      .from('pat_master')
      .insert({
        pat_index_no: patIndexNo,
        name: newPatientForm.name,
        gender: newPatientForm.gender,
        birth_date: newPatientForm.birth_date,
        age: age,
        age_unit: '岁',
        id_card: newPatientForm.id_card || null,
        phone: newPatientForm.phone || null,
        insurance_type: newPatientForm.insurance_type,
        address: newPatientForm.address || null
      })
      .select()
      .single()

    if (error) throw error

    ElMessage.success('患者建档成功')
    newPatientDialogVisible.value = false

    registerForm.patId = data.id
    selectedPatient.value = data
    searchResults.value = [data]
  } catch (error: any) {
    ElMessage.error(error.message || '建档失败')
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
    const today = new Date().toISOString().split('T')[0]
    const visitSn = `V${today.replace(/-/g, '')}${Date.now().toString(36).toUpperCase()}`
    const regNo = `R${today.replace(/-/g, '')}${Date.now().toString(36).toUpperCase()}`

    const { data: maxSeq } = await supabase
      .from('op_registration')
      .select('sequence_no')
      .eq('dept_id', registerForm.deptId)
      .eq('visit_date', today)
      .order('sequence_no', { ascending: false })
      .limit(1)

    const nextSeq = maxSeq && maxSeq.length > 0 ? (maxSeq[0].sequence_no || 0) + 1 : 1

    const payload = {
      pat_id: registerForm.patId,
      visit_sn: visitSn,
      reg_no: regNo,
      dept_id: registerForm.deptId,
      doctor_id: registerForm.doctorId || null,
      visit_date: today,
      visit_time: new Date().toISOString(),
      shift_type: new Date().getHours() < 12 ? 'morning' : 'afternoon',
      sequence_no: nextSeq,
      visit_type: registerForm.visitType,
      clinic_type: registerForm.clinicType,
      complaint: registerForm.complaint || null,
      reg_fee: currentRegFee.value,
      service_fee: currentServiceFee.value,
      total_fee: currentRegFee.value + currentServiceFee.value,
      payment_method: 'cash',
      payment_status: 'paid',
      payment_time: new Date().toISOString(),
      status: 'registered'
    }

    const { error } = await supabase.from('op_registration').insert(payload)

    if (error) throw error

    ElMessage.success(`挂号成功！顺序号：${nextSeq}`)
    registerForm.patId = ''
    registerForm.deptId = ''
    registerForm.clinicType = 'general'
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
  doctors.value = data || []
}

async function fetchRegistrations() {
  const today = new Date().toISOString().split('T')[0]
  if (!filterDate.value) {
    filterDate.value = today
  }

  let query = supabase
    .from('op_registration')
    .select('*, pat_master:pat_master(*), dept:org_dept(*), doctor:hr_employee(name)', { count: 'exact' })
    .eq('is_deleted', false)
    .order('visit_time', { ascending: false })
    .range((pagination.value.page - 1) * pagination.value.pageSize, pagination.value.page * pagination.value.pageSize - 1)

  if (filterDate.value) {
    query = query.eq('visit_date', filterDate.value)
  }
  if (filterDept.value) {
    query = query.eq('dept_id', filterDept.value)
  }
  if (filterStatus.value) {
    query = query.eq('status', filterStatus.value)
  }

  const { data, error, count } = await query
  if (!error) {
    registrations.value = data || []
    pagination.value.total = count || 0
  }
}

function handlePageChange() {
  fetchRegistrations()
}

function handleSizeChange() {
  pagination.value.page = 1
  fetchRegistrations()
}

function resetFilters() {
  filterDate.value = new Date().toISOString().split('T')[0]
  filterDept.value = ''
  filterStatus.value = ''
  pagination.value.page = 1
  fetchRegistrations()
}

function editRegistration(row: any) {
  editForm.id = row.id
  editForm.deptId = row.dept_id
  editForm.doctorId = row.doctor_id || ''
  editForm.complaint = row.complaint || ''
  editFormDoctors.value = doctors.value.filter(d => d.dept_id === row.dept_id && d.emp_type === 'doctor' && d.status === 'active')
  editDialogVisible.value = true
}

async function saveRegistration() {
  saving.value = true
  try {
    const { error } = await supabase
      .from('op_registration')
      .update({
        dept_id: editForm.deptId,
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

async function checkIn(row: any) {
  try {
    const { error } = await supabase
      .from('op_registration')
      .update({
        status: 'checked_in',
        check_in_time: new Date().toISOString(),
        check_in_method: '前台报到'
      })
      .eq('id', row.id)
    if (error) throw error
    ElMessage.success('报到成功')
    fetchRegistrations()
  } catch (error: any) {
    ElMessage.error(error.message || '报到失败')
  }
}

async function cancelRegistration(row: any) {
  try {
    await ElMessageBox.confirm(
      `确定要为 "${row.pat_master?.name}" 退号吗？`,
      '退号确认',
      { confirmButtonText: '确定退号', cancelButtonText: '取消', type: 'warning' }
    )

    const { error } = await supabase
      .from('op_registration')
      .update({
        status: 'cancelled',
        payment_status: 'refunded',
        cancel_time: new Date().toISOString(),
        cancel_reason: '患者退号'
      })
      .eq('id', row.id)

    if (error) throw error
    ElMessage.success('退号成功')
    fetchRegistrations()
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error(e.message || '退号失败')
  }
}

function formatDateTime(dateStr: string): string {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleString('zh-CN')
}

function getClinicTypeLabel(type: string): string {
  const map: Record<string, string> = {
    general: '普通',
    special: '专科',
    expert: '专家',
    emergency: '急诊',
    fast: '快速'
  }
  return map[type] || type
}

function getPaymentType(status: string): string {
  const map: Record<string, string> = {
    unpaid: 'warning',
    paid: 'success',
    refunded: 'info',
    partial_refund: 'warning'
  }
  return map[status] || 'info'
}

function getPaymentLabel(status: string): string {
  const map: Record<string, string> = {
    unpaid: '未付',
    paid: '已付',
    refunded: '已退',
    partial_refund: '部分退'
  }
  return map[status] || status
}

function getStatusType(status: string): string {
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

function getStatusLabel(status: string): string {
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

onMounted(() => {
  filterDate.value = new Date().toISOString().split('T')[0]
  fetchDepartments()
  fetchDoctors()
  fetchRegistrations()
})
</script>

<style scoped>
.registration-page {
  max-width: 1600px;
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

.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}
</style>
