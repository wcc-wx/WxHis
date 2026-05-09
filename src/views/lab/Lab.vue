<template>
  <div class="lab-page">
    <h2>检验管理</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="检验申请" name="requests">
          <el-table :data="labRequests" stripe>
            <el-table-column prop="created_at" label="申请时间" width="180">
              <template #default="{ row }">
                {{ formatDateTime(row.created_at) }}
              </template>
            </el-table-column>
            <el-table-column prop="patient.name" label="患者姓名" width="120" />
            <el-table-column prop="test_item.name" label="检验项目" width="150" />
            <el-table-column prop="specimen_type" label="标本类型" width="100" />
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="getStatusType(row.status)" size="small">
                  {{ getStatusLabel(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="150">
              <template #default="{ row }">
                <el-button
                  v-if="row.status === 'sampled'"
                  type="primary"
                  size="small"
                  @click="startTesting(row)"
                >
                  开始检验
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="结果录入" name="results">
          <el-table :data="pendingResults" stripe>
            <el-table-column prop="lab_request.patient.name" label="患者姓名" width="120" />
            <el-table-column prop="test_item.name" label="检验项目" width="150" />
            <el-table-column prop="reference_range" label="参考范围" width="150" />
            <el-table-column label="结果值" width="150">
              <template #default="{ row }">
                <el-input v-model="row.result_value" placeholder="输入结果" size="small" />
              </template>
            </el-table-column>
            <el-table-column label="异常" width="100">
              <template #default="{ row }">
                <el-checkbox v-model="row.is_abnormal">异常</el-checkbox>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="100">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="saveResult(row)">保存</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="报告审核" name="verify">
          <el-table :data="pendingVerify" stripe>
            <el-table-column prop="lab_request.patient.name" label="患者姓名" width="120" />
            <el-table-column prop="test_item.name" label="检验项目" width="150" />
            <el-table-column prop="result_value" label="结果值" width="120" />
            <el-table-column prop="reference_range" label="参考范围" width="150" />
            <el-table-column prop="is_abnormal" label="异常" width="80">
              <template #default="{ row }">
                <el-tag :type="row.is_abnormal ? 'danger' : 'success'" size="small">
                  {{ row.is_abnormal ? '异常' : '正常' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="150">
              <template #default="{ row }">
                <el-button type="success" size="small" @click="verifyResult(row)">审核通过</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'

const authStore = useAuthStore()
const activeTab = ref('requests')

const labRequests = ref<any[]>([])
const labResults = ref<any[]>([])

const pendingResults = computed(() =>
  labResults.value.filter(r => r.status === 'testing')
)

const pendingVerify = computed(() =>
  labResults.value.filter(r => r.status === 'entered')
)

async function fetchLabRequests() {
  const { data } = await supabase
    .from('lab_requests')
    .select(`
      *,
      patient:patients(name),
      test_item:test_items(name)
    `)
    .in('status', ['pending', 'sampled'])
    .order('created_at', { ascending: false })

  labRequests.value = data || []
}

async function fetchLabResults() {
  const { data } = await supabase
    .from('lab_results')
    .select(`
      *,
      test_item:test_items(name, reference_range),
      lab_request:lab_requests(*, patient:patients(name))
    `)
    .in('status', ['testing', 'entered'])
    .order('created_at', { ascending: false })

  labResults.value = data || []
}

async function startTesting(row: any) {
  await supabase
    .from('lab_requests')
    .update({ status: 'testing' })
    .eq('id', row.id)

  await supabase.from('lab_results').insert({
    lab_request_id: row.id,
    test_item_id: row.test_item_id,
    result_value: '',
    reference_range: '',
    is_abnormal: false,
    entered_by: authStore.profile?.id,
    entered_at: new Date().toISOString(),
    status: 'testing'
  })

  ElMessage.success('已开始检验')
  await fetchLabRequests()
  await fetchLabResults()
}

async function saveResult(row: any) {
  const { error } = await supabase
    .from('lab_results')
    .update({
      result_value: row.result_value,
      is_abnormal: row.is_abnormal,
      status: 'entered'
    })
    .eq('id', row.id)

  if (error) {
    ElMessage.error('保存失败')
  } else {
    ElMessage.success('结果已保存')
    await fetchLabResults()
  }
}

async function verifyResult(row: any) {
  const { error } = await supabase
    .from('lab_results')
    .update({
      status: 'verified',
      verified_by: authStore.profile?.id,
      verified_at: new Date().toISOString()
    })
    .eq('id', row.id)

  if (error) {
    ElMessage.error('审核失败')
  } else {
    ElMessage.success('审核通过')
    await fetchLabResults()
  }
}

function getStatusType(status: string): string {
  const map: Record<string, string> = {
    pending: 'info',
    sampled: 'warning',
    testing: 'primary',
    reported: 'success',
    cancelled: 'danger'
  }
  return map[status] || 'info'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    pending: '待采样',
    sampled: '已采样',
    testing: '检验中',
    reported: '已报告',
    cancelled: '已取消'
  }
  return map[status] || status
}

function formatDateTime(dateStr: string): string {
  return new Date(dateStr).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchLabRequests()
  fetchLabResults()
})
</script>

<style scoped>
.lab-page {
  max-width: 1400px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}
</style>
