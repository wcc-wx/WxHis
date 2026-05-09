<template>
  <div class="pharmacy-page">
    <h2>药房管理</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="待发药处方" name="pending">
          <el-table :data="pendingPrescriptions" stripe>
            <el-table-column prop="prescription_date" label="处方日期" width="120">
              <template #default="{ row }">
                {{ formatDate(row.prescription_date) }}
              </template>
            </el-table-column>
            <el-table-column prop="patient.name" label="患者姓名" width="120" />
            <el-table-column prop="doctor.real_name" label="开方医生" width="100" />
            <el-table-column label="药品信息" show-overflow-tooltip>
              <template #default="{ row }">
                {{ getPrescriptionItems(row) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="100" fixed="right">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="dispense(row)">发药</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="药品库存" name="inventory">
          <el-table :data="drugs" stripe>
            <el-table-column prop="name" label="药品名称" width="150" />
            <el-table-column prop="spec" label="规格" width="120" />
            <el-table-column prop="unit" label="单位" width="80" />
            <el-table-column prop="price" label="单价" width="100" />
            <el-table-column prop="stock" label="库存" width="100">
              <template #default="{ row }">
                <el-tag :type="row.stock < 10 ? 'danger' : 'success'" size="small">
                  {{ row.stock }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { ElMessage, ElMessageBox } from 'element-plus'

const activeTab = ref('pending')

const pendingPrescriptions = ref<any[]>([])
const drugs = ref<any[]>([])

async function fetchPendingPrescriptions() {
  const { data } = await supabase
    .from('prescriptions')
    .select(`
      *,
      patient:patients(name),
      doctor:users_profile!prescriptions_doctor_id_fkey(real_name),
      items:prescription_items(*, drug:drugs(name, spec))
    `)
    .eq('status', 'pending')
    .order('prescription_date')

  pendingPrescriptions.value = data || []
}

async function fetchDrugs() {
  const { data } = await supabase.from('drugs').select('*').order('name')
  drugs.value = data || []
}

async function dispense(row: any) {
  try {
    await ElMessageBox.confirm('确认发药？', '发药确认', { type: 'success' })

    await supabase
      .from('prescriptions')
      .update({ status: 'dispensed' })
      .eq('id', row.id)

    ElMessage.success('发药成功')
    await fetchPendingPrescriptions()
  } catch {
    // cancelled
  }
}

function getPrescriptionItems(row: any): string {
  if (!row.items) return '-'
  return row.items.map((item: any) => `${item.drug?.name} ${item.dosage} ${item.usage}`).join('; ')
}

function formatDate(dateStr: string): string {
  return dateStr?.split('T')[0] || '-'
}

onMounted(() => {
  fetchPendingPrescriptions()
  fetchDrugs()
})
</script>

<style scoped>
.pharmacy-page {
  max-width: 1400px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}
</style>
