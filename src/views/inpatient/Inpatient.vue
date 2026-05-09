<template>
  <div class="inpatient-page">
    <h2>住院管理</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="入院登记" name="admit">
          <el-form :inline="true" :model="admitForm" class="admit-form">
            <el-form-item label="患者">
              <el-select
                v-model="admitForm.patientId"
                filterable
                remote
                placeholder="搜索患者"
                :remote-method="searchPatients"
                :loading="searching"
                style="width: 300px"
              >
                <el-option
                  v-for="p in searchResults"
                  :key="p.id"
                  :label="p.name"
                  :value="p.id"
                />
              </el-select>
            </el-form-item>
            <el-form-item label="科室">
              <el-select v-model="admitForm.departmentId" placeholder="选择科室" style="width: 200px">
                <el-option
                  v-for="dept in departments"
                  :key="dept.id"
                  :label="dept.name"
                  :value="dept.id"
                />
              </el-select>
            </el-form-item>
            <el-form-item label="床位">
              <el-select v-model="admitForm.bedId" placeholder="选择床位" style="width: 150px">
                <el-option
                  v-for="bed in availableBeds"
                  :key="bed.id"
                  :label="`${bed.bed_no}床`"
                  :value="bed.id"
                />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="handleAdmit" :loading="submitting">办理入院</el-button>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="在院患者" name="inpatients">
          <el-table :data="inpatients" stripe>
            <el-table-column prop="patient.name" label="姓名" width="100" />
            <el-table-column prop="patient.gender" label="性别" width="60" />
            <el-table-column prop="admission_time" label="入院时间" width="180">
              <template #default="{ row }">
                {{ formatDateTime(row.admission_time) }}
              </template>
            </el-table-column>
            <el-table-column prop="bed.bed_no" label="床位" width="100">
              <template #default="{ row }">
                {{ row.bed?.bed_no }}床
              </template>
            </el-table-column>
            <el-table-column prop="diagnosis" label="诊断" show-overflow-tooltip />
            <el-table-column label="操作" width="150">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="viewEncounter(row)">详情</el-button>
                <el-button type="success" size="small" @click="discharge(row)">出院</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="床位管理" name="beds">
          <el-row :gutter="20">
            <el-col :span="6" v-for="dept in departmentsWithBeds" :key="dept.id">
              <el-card :header="dept.name">
                <el-space wrap>
                  <el-tag
                    v-for="bed in dept.beds"
                    :key="bed.id"
                    :type="getBedType(bed.status)"
                    style="margin: 4px"
                  >
                    {{ bed.bed_no }}床
                  </el-tag>
                </el-space>
              </el-card>
            </el-col>
          </el-row>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { Patient, Department, Bed } from '@/types'

const activeTab = ref('admit')
const searching = ref(false)
const submitting = ref(false)

const searchResults = ref<Patient[]>([])
const departments = ref<Department[]>([])
const beds = ref<Bed[]>([])
const inpatients = ref<any[]>([])

const admitForm = reactive({
  patientId: '',
  departmentId: '',
  bedId: ''
})

const availableBeds = computed(() =>
  beds.value.filter(b => b.status === 'available' && (!admitForm.departmentId || true))
)

const departmentsWithBeds = computed(() => {
  return departments.value.map(dept => ({
    ...dept,
    beds: beds.value.filter(b => b.department_id === dept.id)
  }))
})

async function searchPatients(query: string) {
  if (!query) { searchResults.value = []; return }
  searching.value = true
  try {
    const { data } = await supabase
      .from('patients')
      .select('*')
      .ilike('name', `%${query}%`)
      .limit(10)
    searchResults.value = data || []
  } finally {
    searching.value = false
  }
}

async function handleAdmit() {
  if (!admitForm.patientId || !admitForm.bedId) {
    ElMessage.warning('请选择患者和床位')
    return
  }

  submitting.value = true
  try {
    await supabase.from('inpatient_encounters').insert({
      patient_id: admitForm.patientId,
      bed_id: admitForm.bedId,
      admission_time: new Date().toISOString(),
      status: 'admitted'
    })

    await supabase.from('beds').update({ status: 'occupied' }).eq('id', admitForm.bedId)

    ElMessage.success('入院办理成功')
    admitForm.patientId = ''
    admitForm.departmentId = ''
    admitForm.bedId = ''
    await fetchData()
  } catch (error: any) {
    ElMessage.error(error.message || '入院办理失败')
  } finally {
    submitting.value = false
  }
}

async function discharge(row: any) {
  try {
    await ElMessageBox.confirm('确认办理出院？', '出院确认', { type: 'success' })

    await supabase
      .from('inpatient_encounters')
      .update({
        status: 'discharged',
        discharge_time: new Date().toISOString()
      })
      .eq('id', row.id)

    await supabase.from('beds').update({ status: 'available' }).eq('id', row.bed_id)

    ElMessage.success('出院办理成功')
    await fetchData()
  } catch {
    // cancelled
  }
}

async function fetchData() {
  const [deptsRes, bedsRes, encountersRes] = await Promise.all([
    supabase.from('departments').select('*').order('name'),
    supabase.from('beds').select('*').order('bed_no'),
    supabase
      .from('inpatient_encounters')
      .select(`
        *,
        patient:patients(*),
        bed:beds(*)
      `)
      .eq('status', 'admitted')
  ])

  departments.value = deptsRes.data || []
  beds.value = bedsRes.data || []
  inpatients.value = encountersRes.data || []
}

function viewEncounter(row: any) {
  // TODO: navigate to encounter detail
  ElMessage.info('详情页开发中')
}

function getBedType(status: string): string {
  const map: Record<string, string> = { available: 'success', occupied: 'danger', maintenance: 'warning' }
  return map[status] || 'info'
}

function formatDateTime(dateStr: string): string {
  return new Date(dateStr).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.inpatient-page {
  max-width: 1400px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}

.admit-form {
  padding: 20px 0;
}
</style>
