<template>
  <div class="lab-page">
    <h2>检验管理 (LIS)</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="检验申请" name="requests">
          <el-form :inline="true" class="filter-form">
            <el-form-item label="日期">
              <el-date-picker
                v-model="filterDate"
                type="date"
                placeholder="选择日期"
                style="width: 150px"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
                @change="fetchRequests"
              />
            </el-form-item>
            <el-form-item label="状态">
              <el-select v-model="filterStatus" placeholder="全部" clearable style="width: 120px" @change="fetchRequests">
                <el-option label="待采样" value="pending" />
                <el-option label="已采样" value="sampled" />
                <el-option label="已接收" value="received" />
                <el-option label="检验中" value="testing" />
                <el-option label="已报告" value="reported" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button @click="resetFilter">重置</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="requests" stripe style="margin-top: 16px">
            <el-table-column prop="request_no" label="申请单号" width="160" />
            <el-table-column prop="pat_master.name" label="患者姓名" width="100" />
            <el-table-column prop="pat_master.gender" label="性别" width="60" />
            <el-table-column label="年龄" width="70">
              <template #default="{ row }">
                {{ row.pat_master ? getAge(row.pat_master.birth_date) : '-' }}
              </template>
            </el-table-column>
            <el-table-column prop="specimen_type" label="标本类型" width="100" />
            <el-table-column prop="test_items" label="检验项目" show-overflow-tooltip>
              <template #default="{ row }">
                {{ formatTestItems(row.test_items) }}
              </template>
            </el-table-column>
            <el-table-column prop="priority" label="优先级" width="80">
              <template #default="{ row }">
                <el-tag v-if="row.priority === 'stat'" type="danger" size="small">急</el-tag>
                <el-tag v-else-if="row.priority === 'urgent'" type="warning" size="small">优先</el-tag>
                <span v-else>普通</span>
              </template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="getStatusType(row.status)" size="small">
                  {{ getStatusLabel(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="create_time" label="申请时间" width="160">
              <template #default="{ row }">
                {{ formatDateTime(row.create_time) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="180">
              <template #default="{ row }">
                <el-button v-if="row.status === 'pending'" type="primary" size="small" @click="sample(row)">采样</el-button>
                <el-button v-if="row.status === 'sampled'" type="primary" size="small" @click="receive(row)">接收</el-button>
                <el-button v-if="row.status === 'received'" type="warning" size="small" @click="startTest(row)">开始检验</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="结果录入" name="results">
          <el-table :data="pendingResults" stripe>
            <el-table-column prop="lis_request.request_no" label="申请单号" width="160" />
            <el-table-column prop="lis_request.pat_master?.name" label="患者姓名" width="100" />
            <el-table-column prop="test_item_name" label="检验项目" width="150" />
            <el-table-column label="结果值" width="150">
              <template #default="{ row }">
                <el-input v-model="row.result_value" placeholder="输入结果" size="small" />
              </template>
            </el-table-column>
            <el-table-column label="参考范围" width="150">
              <template #default="{ row }">
                {{ row.reference_range || '-' }}
              </template>
            </el-table-column>
            <el-table-column label="异常" width="80">
              <template #default="{ row }">
                <el-tag v-if="row.is_abnormal" type="danger" size="small">{{ row.abnormal_flag }}</el-tag>
                <span v-else>-</span>
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
            <el-table-column prop="lis_request.request_no" label="申请单号" width="160" />
            <el-table-column prop="lis_request.pat_master?.name" label="患者姓名" width="100" />
            <el-table-column prop="test_item_name" label="检验项目" width="150" />
            <el-table-column prop="result_value" label="结果值" width="120" />
            <el-table-column label="参考范围" width="150">
              <template #default="{ row }">{{ row.reference_range || '-' }}</template>
            </el-table-column>
            <el-table-column prop="is_abnormal" label="异常" width="80">
              <template #default="{ row }">
                <el-tag :type="row.is_abnormal ? 'danger' : 'success'" size="small">
                  {{ row.is_abnormal ? row.abnormal_flag || '异常' : '正常' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="entered_time" label="录入时间" width="160">
              <template #default="{ row }">{{ formatDateTime(row.entered_time) }}</template>
            </el-table-column>
            <el-table-column label="操作" width="150">
              <template #default="{ row }">
                <el-button type="success" size="small" @click="verifyResult(row)">审核通过</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="危急值" name="critical">
          <el-table :data="criticalValues" stripe>
            <el-table-column prop="lis_request.request_no" label="申请单号" width="160" />
            <el-table-column prop="pat_master?.name" label="患者姓名" width="100" />
            <el-table-column prop="item_name" label="检验项目" width="150" />
            <el-table-column prop="critical_value" label="危急值" width="100">
              <template #default="{ row }">
                <el-tag type="danger">{{ row.critical_value }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="critical_type" label="类型" width="80">
              <template #default="{ row }">{{ row.critical_type === 'H' ? '过高' : '过低' }}</template>
            </el-table-column>
            <el-table-column prop="notify_time" label="通知时间" width="160">
              <template #default="{ row }">{{ formatDateTime(row.notify_time) }}</template>
            </el-table-column>
            <el-table-column prop="notify_response" label="处理措施" show-overflow-tooltip />
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

const requests = ref<any[]>([])
const results = ref<any[]>([])
const criticalValues = ref<any[]>([])

const filterDate = ref('')
const filterStatus = ref('')

const pendingResults = computed(() =>
  results.value.filter(r => r.status === 'entered')
)

const pendingVerify = computed(() =>
  results.value.filter(r => r.status === 'verified')
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

function formatTestItems(items: any): string {
  if (!items) return ''
  if (typeof items === 'string') {
    try {
      items = JSON.parse(items)
    } catch { return items }
  }
  if (Array.isArray(items)) {
    return items.map((i: any) => i.name || i.item_name || i).join(', ')
  }
  return String(items)
}

async function fetchRequests() {
  let query = supabase
    .from('lis_request')
    .select('*, pat_master:pat_master(name,gender,birth_date)')
    .order('create_time', { ascending: false })
    .limit(100)

  if (filterStatus.value) {
    query = query.eq('status', filterStatus.value)
  }

  const { data } = await query
  requests.value = data || []
}

async function fetchResults() {
  const { data } = await supabase
    .from('lis_result')
    .select('*, lis_request:lis_request(*, pat_master:pat_master(name))')
    .in('status', ['entered', 'verified'])
    .order('create_time', { ascending: false })

  results.value = data || []
}

async function fetchCriticalValues() {
  const { data } = await supabase
    .from('lis_critical_value')
    .select('*, lis_request:lis_request(*, pat_master:pat_master(name))')
    .order('create_time', { ascending: false })

  criticalValues.value = data || []
}

async function sample(row: any) {
  const { error } = await supabase
    .from('lis_request')
    .update({ status: 'sampled', specimen_collection_time: new Date().toISOString() })
    .eq('id', row.id)

  if (error) ElMessage.error('采样失败')
  else {
    ElMessage.success('已采样')
    fetchRequests()
  }
}

async function receive(row: any) {
  const { error } = await supabase
    .from('lis_request')
    .update({ status: 'received', specimen_received_time: new Date().toISOString() })
    .eq('id', row.id)

  if (error) ElMessage.error('接收失败')
  else {
    ElMessage.success('已接收')
    fetchRequests()
  }
}

async function startTest(row: any) {
  const { error } = await supabase
    .from('lis_request')
    .update({ status: 'testing' })
    .eq('id', row.id)

  if (error) ElMessage.error('操作失败')
  else {
    ElMessage.success('已开始检验')
    fetchRequests()
  }
}

async function saveResult(row: any) {
  const { error } = await supabase
    .from('lis_result')
    .update({
      result_value: row.result_value,
      is_abnormal: row.is_abnormal || false,
      entered_by: authStore.profile?.id,
      entered_time: new Date().toISOString(),
      status: 'entered'
    })
    .eq('id', row.id)

  if (error) ElMessage.error('保存失败')
  else {
    ElMessage.success('结果已保存')
    fetchResults()
  }
}

async function verifyResult(row: any) {
  const { error } = await supabase
    .from('lis_result')
    .update({
      status: 'verified',
      verified_by: authStore.profile?.id,
      verified_time: new Date().toISOString()
    })
    .eq('id', row.id)

  if (error) ElMessage.error('审核失败')
  else {
    ElMessage.success('审核通过')
    fetchResults()
  }
}

function resetFilter() {
  filterDate.value = ''
  filterStatus.value = ''
  fetchRequests()
}

function getStatusType(status: string): string {
  const map: Record<string, string> = {
    pending: 'info',
    sampled: 'warning',
    received: 'primary',
    testing: 'warning',
    reported: 'success',
    cancelled: 'danger'
  }
  return map[status] || 'info'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    pending: '待采样',
    sampled: '已采样',
    received: '已接收',
    testing: '检验中',
    reported: '已报告',
    cancelled: '已取消'
  }
  return map[status] || status
}

function formatDateTime(dateStr: string | null): string {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchRequests()
  fetchResults()
  fetchCriticalValues()
})
</script>

<style scoped>
.lab-page {
  max-width: 1600px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}

.filter-form {
  padding: 8px 0;
}
</style>
