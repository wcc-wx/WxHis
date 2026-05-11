<template>
  <div class="patients-page">
    <div class="page-header">
      <h2>患者主索引</h2>
      <el-button type="primary" @click="showAddDialog">新建患者档案</el-button>
    </div>

    <el-card class="search-card">
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="患者姓名">
          <el-input v-model="searchForm.name" placeholder="请输入姓名" clearable />
        </el-form-item>
        <el-form-item label="患者ID">
          <el-input v-model="searchForm.patIndexNo" placeholder="请输入患者ID" clearable />
        </el-form-item>
        <el-form-item label="身份证号">
          <el-input v-model="searchForm.idCard" placeholder="请输入身份证号" clearable />
        </el-form-item>
        <el-form-item label="联系电话">
          <el-input v-model="searchForm.phone" placeholder="请输入联系电话" clearable />
        </el-form-item>
        <el-form-item label="医保类型">
          <el-select v-model="searchForm.insuranceType" placeholder="请选择" clearable style="width: 120px">
            <el-option label="自费" value="自费" />
            <el-option label="职工医保" value="职工医保" />
            <el-option label="居民医保" value="居民医保" />
            <el-option label="新农合" value="新农合" />
          </el-select>
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
        <el-table-column prop="pat_index_no" label="患者ID" width="120" />
        <el-table-column prop="name" label="姓名" width="100" />
        <el-table-column prop="gender" label="性别" width="60" />
        <el-table-column prop="age" label="年龄" width="70">
          <template #default="{ row }">
            {{ row.age }}{{ row.age_unit || '岁' }}
          </template>
        </el-table-column>
        <el-table-column prop="id_card" label="身份证号" width="170" />
        <el-table-column prop="phone" label="联系电话" width="120" />
        <el-table-column prop="insurance_type" label="医保类型" width="100" />
        <el-table-column prop="vip_level" label="VIP" width="70">
          <template #default="{ row }">
            <el-tag v-if="row.vip_level > 0" type="warning" size="small">
              Lv{{ row.vip_level }}
            </el-tag>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="risk_level" label="风险等级" width="90">
          <template #default="{ row }">
            <el-tag v-if="row.risk_level === 'high'" type="danger" size="small">高危</el-tag>
            <el-tag v-else-if="row.risk_level === 'medium'" type="warning" size="small">中危</el-tag>
            <el-tag v-else type="success" size="small">低危</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="create_time" label="建档时间" width="160">
          <template #default="{ row }">
            {{ formatDateTime(row.create_time) }}
          </template>
        </el-table-column>
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
      width="700px"
      :close-on-click-modal="false"
    >
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="100px"
      >
        <el-divider content-position="left">基本信息</el-divider>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="患者姓名" prop="name">
              <el-input v-model="form.name" placeholder="请输入姓名" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="患者ID" prop="pat_index_no">
              <el-input v-model="form.pat_index_no" placeholder="系统自动生成" disabled />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="性别" prop="gender">
              <el-radio-group v-model="form.gender">
                <el-radio label="男">男</el-radio>
                <el-radio label="女">女</el-radio>
                <el-radio label="未知">未知</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="出生日期" prop="birth_date">
              <el-date-picker
                v-model="form.birth_date"
                type="date"
                placeholder="选择日期"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
                style="width: 100%"
              />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="身份证号" prop="id_card">
              <el-input v-model="form.id_card" placeholder="请输入身份证号" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="民族">
              <el-input v-model="form.ethnicity" placeholder="请输入民族" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="婚姻状况">
              <el-select v-model="form.marital_status" placeholder="请选择" style="width: 100%">
                <el-option label="未婚" value="未婚" />
                <el-option label="已婚" value="已婚" />
                <el-option label="丧偶" value="丧偶" />
                <el-option label="离婚" value="离婚" />
                <el-option label="未知" value="未知" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="职业">
              <el-input v-model="form.occupation" placeholder="请输入职业" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-divider content-position="left">联系方式</el-divider>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="联系电话" prop="phone">
              <el-input v-model="form.phone" placeholder="请输入手机号" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="紧急联系电话">
              <el-input v-model="form.phone_emergency" placeholder="请输入" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="现住址">
          <el-input v-model="form.address" placeholder="请输入现住址" />
        </el-form-item>

        <el-form-item label="户籍地址">
          <el-input v-model="form.address_registered" placeholder="请输入户籍地址" />
        </el-form-item>

        <el-divider content-position="left">医保信息</el-divider>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="医保类型">
              <el-select v-model="form.insurance_type" placeholder="请选择" style="width: 100%">
                <el-option label="自费" value="自费" />
                <el-option label="职工医保" value="职工医保" />
                <el-option label="居民医保" value="居民医保" />
                <el-option label="新农合" value="新农合" />
                <el-option label="商业保险" value="商业保险" />
                <el-option label="其他" value="其他" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="医保卡号">
              <el-input v-model="form.insurance_no" placeholder="请输入医保卡号" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-divider content-position="left">紧急联系人</el-divider>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="联系人姓名">
              <el-input v-model="form.emergency_contact_name" placeholder="请输入" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="关系">
              <el-input v-model="form.emergency_contact_relation" placeholder="请输入关系" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="联系人电话">
              <el-input v-model="form.emergency_contact_phone" placeholder="请输入" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-divider content-position="left">其他信息</el-divider>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="VIP等级">
              <el-input-number v-model="form.vip_level" :min="0" :max="5" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="风险等级">
              <el-select v-model="form.risk_level" placeholder="请选择" style="width: 100%">
                <el-option label="低危" value="low" />
                <el-option label="中危" value="medium" />
                <el-option label="高危" value="high" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
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
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/composables/supabase'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type { PatMaster } from '@/types'

const router = useRouter()

const loading = ref(false)
const submitting = ref(false)
const dialogVisible = ref(false)
const isEdit = ref(false)
const formRef = ref<FormInstance>()

const patients = ref<PatMaster[]>([])
const pagination = ref({
  page: 1,
  pageSize: 10,
  total: 0
})

const searchForm = reactive({
  name: '',
  patIndexNo: '',
  idCard: '',
  phone: '',
  insuranceType: ''
})

const getDefaultForm = () => ({
  id: '',
  org_id: '00000000-0000-0000-0000-000000000001',
  pat_index_no: '',
  name: '',
  name_pinyin: '',
  gender: '未知' as '男' | '女' | '未知',
  birth_date: '',
  age: undefined as number | undefined,
  age_unit: '岁' as '岁' | '月' | '天',
  id_card: '',
  id_card_type: 'id_card' as const,
  birth_place: '',
  nationality: '中国',
  ethnicity: '',
  marital_status: '未知' as '未婚' | '已婚' | '丧偶' | '离婚' | '未知',
  education: '',
  occupation: '',
  phone: '',
  phone_emergency: '',
  email: '',
  address: '',
  address_registered: '',
  household_register: '',
  insurance_type: '自费' as '职工医保' | '居民医保' | '新农合' | '商业保险' | '自费' | '其他',
  insurance_no: '',
  insurance_org: '',
  emergency_contact_name: '',
  emergency_contact_relation: '',
  emergency_contact_phone: '',
  vip_level: 0,
  risk_level: 'low' as 'low' | 'medium' | 'high',
  photo_url: ''
})

const form = reactive(getDefaultForm())

const rules: FormRules = {
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  gender: [{ required: true, message: '请选择性别', trigger: 'change' }],
  birth_date: [{ required: true, message: '请选择出生日期', trigger: 'change' }],
  id_card: [
    { pattern: /(^\d{15}$)|(^\d{18}$)|(^\d{17}(\d|X|x)$)/, message: '身份证号格式不正确', trigger: 'blur' }
  ],
  phone: [{ pattern: /^1[3-9]\d{9}$/, message: '手机号格式不正确', trigger: 'blur' }]
}

const dialogTitle = computed(() => isEdit.value ? '编辑患者档案' : '新建患者档案')

function calculateAge(birthDate: string): number {
  if (!birthDate) return 0
  const birth = new Date(birthDate)
  const today = new Date()
  let age = today.getFullYear() - birth.getFullYear()
  const monthDiff = today.getMonth() - birth.getMonth()
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--
  }
  return age
}

async function fetchPatients() {
  loading.value = true
  try {
    let query = supabase
      .from('pat_master')
      .select('*', { count: 'exact' })
      .eq('is_deleted', false)

    if (searchForm.name) {
      query = query.ilike('name', `%${searchForm.name}%`)
    }
    if (searchForm.patIndexNo) {
      query = query.eq('pat_index_no', searchForm.patIndexNo)
    }
    if (searchForm.idCard) {
      query = query.eq('id_card', searchForm.idCard)
    }
    if (searchForm.phone) {
      query = query.eq('phone', searchForm.phone)
    }
    if (searchForm.insuranceType) {
      query = query.eq('insurance_type', searchForm.insuranceType)
    }

    const from = (pagination.value.page - 1) * pagination.value.pageSize
    query = query.range(from, from + pagination.value.pageSize - 1)

    const { data, error, count } = await query.order('create_time', { ascending: false })

    if (error) throw error

    patients.value = (data || []).map(p => {
      if (p.birth_date && !p.age) {
        p.age = calculateAge(p.birth_date)
      }
      return p
    })
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
  searchForm.patIndexNo = ''
  searchForm.idCard = ''
  searchForm.phone = ''
  searchForm.insuranceType = ''
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

function handleRowClick(row: PatMaster) {
  router.push(`/patients/${row.id}`)
}

function handleEdit(row: PatMaster) {
  isEdit.value = true
  Object.assign(form, getDefaultForm(), {
    id: row.id,
    pat_index_no: row.pat_index_no,
    name: row.name,
    name_pinyin: row.name_pinyin || '',
    gender: row.gender,
    birth_date: row.birth_date,
    age: row.age,
    age_unit: row.age_unit || '岁',
    id_card: row.id_card || '',
    nationality: row.nationality || '中国',
    ethnicity: row.ethnicity || '',
    marital_status: row.marital_status || '未知',
    education: row.education || '',
    occupation: row.occupation || '',
    phone: row.phone || '',
    phone_emergency: row.phone_emergency || '',
    address: row.address || '',
    address_registered: row.address_registered || '',
    insurance_type: row.insurance_type || '自费',
    insurance_no: row.insurance_no || '',
    emergency_contact_name: row.emergency_contact_name || '',
    emergency_contact_relation: row.emergency_contact_relation || '',
    emergency_contact_phone: row.emergency_contact_phone || '',
    vip_level: row.vip_level || 0,
    risk_level: row.risk_level || 'low'
  })
  dialogVisible.value = true
}

function handleDelete(row: PatMaster) {
  ElMessageBox.confirm(`确定要删除患者「${row.name}」（ID: ${row.pat_index_no}）吗？`, '删除确认', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    try {
      const { error } = await supabase
        .from('pat_master')
        .update({ is_deleted: true })
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
  Object.assign(form, getDefaultForm())
  dialogVisible.value = true
}

async function handleSubmit() {
  if (!formRef.value) return

  await formRef.value.validate(async (valid) => {
    if (!valid) return

    submitting.value = true
    try {
      const age = calculateAge(form.birth_date)
      const payload = {
        org_id: form.org_id,
        name: form.name,
        name_pinyin: form.name_pinyin,
        gender: form.gender,
        birth_date: form.birth_date,
        age: age,
        age_unit: form.age_unit,
        id_card: form.id_card || null,
        id_card_type: form.id_card_type,
        nationality: form.nationality || '中国',
        ethnicity: form.ethnicity || null,
        marital_status: form.marital_status,
        education: form.education || null,
        occupation: form.occupation || null,
        phone: form.phone || null,
        phone_emergency: form.phone_emergency || null,
        address: form.address || null,
        address_registered: form.address_registered || null,
        insurance_type: form.insurance_type,
        insurance_no: form.insurance_no || null,
        emergency_contact_name: form.emergency_contact_name || null,
        emergency_contact_relation: form.emergency_contact_relation || null,
        emergency_contact_phone: form.emergency_contact_phone || null,
        vip_level: form.vip_level,
        risk_level: form.risk_level
      }

      let error
      if (isEdit.value) {
        const { error: updateError } = await supabase
          .from('pat_master')
          .update(payload)
          .eq('id', form.id)
        error = updateError
      } else {
        const patIndexNo = 'P' + Date.now().toString(36).toUpperCase()
        const { error: insertError } = await supabase
          .from('pat_master')
          .insert({ ...payload, pat_index_no: patIndexNo })
        error = insertError
      }

      if (error) throw error

      ElMessage.success(isEdit.value ? '更新成功' : '建档成功')
      dialogVisible.value = false
      fetchPatients()
    } catch (error: any) {
      ElMessage.error(error.message || '操作失败')
    } finally {
      submitting.value = false
    }
  })
}

function formatDateTime(dateStr: string): string {
  if (!dateStr) return ''
  return dateStr.replace('T', ' ').substring(0, 19)
}

onMounted(() => {
  fetchPatients()
})
</script>

<style scoped>
.patients-page {
  max-width: 1600px;
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

:deep(.el-divider) {
  margin: 16px 0 20px;
}
</style>
