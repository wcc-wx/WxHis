<template>
  <div class="patients-page">
    <div class="page-header">
      <h2>患者管理</h2>
      <el-button type="primary" @click="showAddDialog">新增患者</el-button>
    </div>

    <el-card class="search-card">
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="姓名">
          <el-input v-model="searchForm.name" placeholder="请输入姓名" clearable />
        </el-form-item>
        <el-form-item label="身份证号">
          <el-input v-model="searchForm.idCard" placeholder="请输入身份证号" clearable />
        </el-form-item>
        <el-form-item label="联系电话">
          <el-input v-model="searchForm.phone" placeholder="请输入联系电话" clearable />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch" :loading="loading">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <el-table
        :data="patients"
        :loading="loading"
        stripe
        style="width: 100%"
        @row-click="handleRowClick"
      >
        <el-table-column prop="name" label="姓名" width="100" />
        <el-table-column prop="gender" label="性别" width="60" />
        <el-table-column prop="birth_date" label="出生日期" width="120">
          <template #default="{ row }">
            {{ formatDate(row.birth_date) }}
          </template>
        </el-table-column>
        <el-table-column prop="id_card" label="身份证号" width="180" />
        <el-table-column prop="phone" label="联系电话" width="130" />
        <el-table-column prop="blood_type" label="血型" width="80" />
        <el-table-column prop="allergy_history" label="过敏史" show-overflow-tooltip />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click.stop="handleEdit(row)">编辑</el-button>
            <el-button type="danger" size="small" @click.stop="handleDelete(row)">删除</el-button>
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
    </el-card>

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="600px"
      :close-on-click-modal="false"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item label="姓名" prop="name">
          <el-input v-model="form.name" placeholder="请输入姓名" />
        </el-form-item>

        <el-form-item label="性别" prop="gender">
          <el-radio-group v-model="form.gender">
            <el-radio label="男">男</el-radio>
            <el-radio label="女">女</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item label="出生日期" prop="birth_date">
          <el-date-picker
            v-model="form.birth_date"
            type="date"
            placeholder="选择出生日期"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
            style="width: 100%"
          />
        </el-form-item>

        <el-form-item label="身份证号" prop="id_card">
          <el-input v-model="form.id_card" placeholder="请输入身份证号" />
        </el-form-item>

        <el-form-item label="联系电话" prop="phone">
          <el-input v-model="form.phone" placeholder="请输入联系电话" />
        </el-form-item>

        <el-form-item label="住址" prop="address">
          <el-input v-model="form.address" type="textarea" placeholder="请输入住址" />
        </el-form-item>

        <el-form-item label="血型" prop="blood_type">
          <el-select v-model="form.blood_type" placeholder="请选择血型" style="width: 100%">
            <el-option label="A型" value="A" />
            <el-option label="B型" value="B" />
            <el-option label="AB型" value="AB" />
            <el-option label="O型" value="O" />
            <el-option label="未知" value="未知" />
          </el-select>
        </el-form-item>

        <el-form-item label="过敏史" prop="allergy_history">
          <el-input v-model="form.allergy_history" type="textarea" placeholder="请输入过敏史" />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/composables/supabase'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type { Patient } from '@/types'

const router = useRouter()

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref<FormInstance>()

const patients = ref<Patient[]>([])
const pagination = ref({
  page: 1,
  pageSize: 10,
  total: 0
})

const searchForm = reactive({
  name: '',
  idCard: '',
  phone: ''
})

const form = reactive({
  id: '',
  name: '',
  gender: '男' as '男' | '女',
  birth_date: '',
  id_card: '',
  phone: '',
  address: '',
  blood_type: '',
  allergy_history: ''
})

const rules: FormRules = {
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  gender: [{ required: true, message: '请选择性别', trigger: 'change' }],
  birth_date: [{ required: true, message: '请选择出生日期', trigger: 'change' }],
  id_card: [
    { required: true, message: '请输入身份证号', trigger: 'blur' },
    { pattern: /(^\d{15}$)|(^\d{18}$)|(^\d{17}(\d|X|x)$)/, message: '身份证号格式不正确', trigger: 'blur' }
  ],
  phone: [{ pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }]
}

const dialogTitle = computed(() => isEdit.value ? '编辑患者' : '新增患者')

async function fetchPatients() {
  loading.value = true
  try {
    let query = supabase
      .from('patients')
      .select('*', { count: 'exact' })

    if (searchForm.name) {
      query = query.ilike('name', `%${searchForm.name}%`)
    }
    if (searchForm.idCard) {
      query = query.eq('id_card', searchForm.idCard)
    }
    if (searchForm.phone) {
      query = query.eq('phone', searchForm.phone)
    }

    const from = (pagination.value.page - 1) * pagination.value.pageSize
    query = query.range(from, from + pagination.value.pageSize - 1)

    const { data, error, count } = await query.order('created_at', { ascending: false })

    if (error) throw error

    patients.value = data || []
    pagination.value.total = count || 0
  } catch (error: any) {
    ElMessage.error(error.message || '获取患者列表失败')
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  pagination.value.page = 1
  fetchPatients()
}

function handleReset() {
  searchForm.name = ''
  searchForm.idCard = ''
  searchForm.phone = ''
  pagination.value.page = 1
  fetchPatients()
}

function handlePageChange() {
  fetchPatients()
}

function handleSizeChange() {
  pagination.value.page = 1
  fetchPatients()
}

function handleRowClick(row: Patient) {
  router.push(`/patients/${row.id}`)
}

function handleEdit(row: Patient) {
  isEdit.value = true
  Object.assign(form, {
    id: row.id,
    name: row.name,
    gender: row.gender,
    birth_date: row.birth_date,
    id_card: row.id_card,
    phone: row.phone || '',
    address: row.address || '',
    blood_type: row.blood_type || '',
    allergy_history: row.allergy_history || ''
  })
  dialogVisible.value = true
}

function handleDelete(row: Patient) {
  ElMessageBox.confirm(`确定要删除患者「${row.name}」吗？`, '删除确认', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    try {
      const { error } = await supabase
        .from('patients')
        .delete()
        .eq('id', row.id)

      if (error) throw error

      ElMessage.success('删除成功')
      fetchPatients()
    } catch (error: any) {
      ElMessage.error(error.message || '删除失败')
    }
  }).catch(() => {})
}

function showAddDialog() {
  isEdit.value = false
  Object.assign(form, {
    id: '',
    name: '',
    gender: '男',
    birth_date: '',
    id_card: '',
    phone: '',
    address: '',
    blood_type: '',
    allergy_history: ''
  })
  dialogVisible.value = true
}

async function handleSubmit() {
  if (!formRef.value) return

  await formRef.value.validate(async (valid) => {
    if (!valid) return

    submitting.value = true
    try {
      const payload = {
        name: form.name,
        gender: form.gender,
        birth_date: form.birth_date,
        id_card: form.id_card,
        phone: form.phone || null,
        address: form.address || null,
        blood_type: form.blood_type || null,
        allergy_history: form.allergy_history || null
      }

      let error
      if (isEdit.value) {
        const { error: updateError } = await supabase
          .from('patients')
          .update(payload)
          .eq('id', form.id)
        error = updateError
      } else {
        const { error: insertError } = await supabase
          .from('patients')
          .insert(payload)
        error = insertError
      }

      if (error) throw error

      ElMessage.success(isEdit.value ? '更新成功' : '添加成功')
      dialogVisible.value = false
      fetchPatients()
    } catch (error: any) {
      ElMessage.error(error.message || '操作失败')
    } finally {
      submitting.value = false
    }
  })
}

function formatDate(dateStr: string): string {
  if (!dateStr) return ''
  return dateStr.split('T')[0]
}

onMounted(() => {
  fetchPatients()
})
</script>

<style scoped>
.patients-page {
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0;
  font-size: 20px;
  color: #303133;
}

.search-card {
  margin-bottom: 20px;
}

.table-card {
  margin-bottom: 20px;
}

.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}

:deep(.el-table__row) {
  cursor: pointer;
}
</style>
