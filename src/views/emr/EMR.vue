<template>
  <div class="emr-page">
    <h2>电子病历</h2>
    <el-card>
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="患者">
          <el-input v-model="searchForm.patientName" placeholder="患者姓名" clearable />
        </el-form-item>
        <el-form-item label="日期范围">
          <el-date-picker
            v-model="searchForm.dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <el-table :data="emrRecords" stripe>
        <el-table-column prop="visit_time" label="就诊时间" width="180">
          <template #default="{ row }">
            {{ formatDateTime(row.visit_time) }}
          </template>
        </el-table-column>
        <el-table-column prop="patient.name" label="患者姓名" width="120" />
        <el-table-column prop="doctor.real_name" label="医生" width="100" />
        <el-table-column prop="chief_complaint" label="主诉" show-overflow-tooltip />
        <el-table-column prop="diagnosis" label="诊断" show-overflow-tooltip />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="viewEmr(row)">查看</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="viewDialogVisible" title="病历详情" width="700px">
      <el-descriptions :column="2" border v-if="currentEmr">
        <el-descriptions-item label="患者">{{ currentEmr.patient?.name }}</el-descriptions-item>
        <el-descriptions-item label="性别">{{ currentEmr.patient?.gender }}</el-descriptions-item>
        <el-descriptions-item label="就诊时间">{{ formatDateTime(currentEmr.visit_time) }}</el-descriptions-item>
        <el-descriptions-item label="科室">{{ currentEmr.department?.name }}</el-descriptions-item>
        <el-descriptions-item label="医生">{{ currentEmr.doctor?.real_name }}</el-descriptions-item>
        <el-descriptions-item label="诊断">{{ currentEmr.diagnosis || '-' }}</el-descriptions-item>
      </el-descriptions>

      <el-divider>病史</el-divider>

      <div class="emr-content" v-if="currentEmr">
        <p><strong>主诉：</strong>{{ currentEmr.chief_complaint || '-' }}</p>
        <p><strong>现病史：</strong>{{ currentEmr.present_illness || '-' }}</p>
        <p><strong>备注：</strong>{{ currentEmr.notes || '-' }}</p>
      </div>

      <template #footer>
        <el-button @click="viewDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { ElMessage } from 'element-plus'

const searchForm = reactive({
  patientName: '',
  dateRange: []
})

const emrRecords = ref<any[]>([])
const viewDialogVisible = ref(false)
const currentEmr = ref<any | null>(null)

async function fetchEmrRecords() {
  let query = supabase
    .from('outpatient_visits')
    .select(`
      *,
      patient:patients(name, gender),
      doctor:users_profile!outpatient_visits_doctor_id_fkey(real_name),
      registration:registrations(*, department:departments(name))
    `)
    .order('visit_time', { ascending: false })
    .limit(50)

  const { data, error } = await query

  if (error) {
    ElMessage.error('获取病历失败')
    return
  }

  emrRecords.value = (data || []).map((item: any) => ({
    ...item,
    department: item.registration?.department
  }))
}

function handleSearch() {
  fetchEmrRecords()
}

function viewEmr(row: any) {
  currentEmr.value = row
  viewDialogVisible.value = true
}

function formatDateTime(dateStr: string): string {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchEmrRecords()
})
</script>

<style scoped>
.emr-page {
  max-width: 1400px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}

.search-form {
  padding: 10px 0;
}

.table-card {
  margin-top: 20px;
}

.emr-content p {
  margin: 10px 0;
  line-height: 1.8;
}
</style>
