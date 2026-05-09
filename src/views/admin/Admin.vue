<template>
  <div class="admin-page">
    <h2>系统设置</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <!-- 用户管理 -->
        <el-tab-pane label="用户管理" name="users">
          <el-button type="primary" @click="openUserDialog(null)">添加用户</el-button>
          <el-table :data="users" stripe style="margin-top: 16px">
            <el-table-column prop="real_name" label="姓名" width="120" />
            <el-table-column prop="employee_no" label="工号" width="100" />
            <el-table-column prop="role" label="角色" width="120">
              <template #default="{ row }">
                <el-tag>{{ roleLabels[row.role] || row.role }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="department_id" label="科室" width="150">
              <template #default="{ row }">
                {{ getDeptName(row.department_id) }}
              </template>
            </el-table-column>
            <el-table-column prop="phone" label="电话" width="150" />
            <el-table-column prop="created_at" label="创建时间" width="180">
              <template #default="{ row }">
                {{ formatDateTime(row.created_at) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="180">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="openUserDialog(row)">编辑</el-button>
                <el-button type="danger" size="small" @click="deleteUser(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 科室管理 -->
        <el-tab-pane label="科室管理" name="departments">
          <el-button type="primary" @click="openDeptDialog(null)">添加科室</el-button>
          <el-table :data="departments" stripe style="margin-top: 16px">
            <el-table-column prop="code" label="科室代码" width="150" />
            <el-table-column prop="name" label="科室名称" />
            <el-table-column prop="created_at" label="创建时间" width="180">
              <template #default="{ row }">
                {{ formatDateTime(row.created_at) }}
              </template>
            </el-table-column>
            <el-table-column label="操作" width="180">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="openDeptDialog(row)">编辑</el-button>
                <el-button type="danger" size="small" @click="deleteDepartment(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 字典管理 -->
        <el-tab-pane label="字典管理" name="dictionaries">
          <el-space wrap>
            <el-button @click="activeDict = 'drugs'">药品字典</el-button>
            <el-button @click="activeDict = 'test_items'">检验项目</el-button>
            <el-button @click="activeDict = 'beds'">床位字典</el-button>
          </el-space>

          <div v-if="activeDict === 'drugs'" style="margin-top: 16px">
            <el-table :data="drugs" stripe>
              <el-table-column prop="name" label="药品名称" width="150" />
              <el-table-column prop="spec" label="规格" width="120" />
              <el-table-column prop="unit" label="单位" width="80" />
              <el-table-column prop="price" label="单价" width="100" />
            </el-table>
          </div>

          <div v-if="activeDict === 'test_items'" style="margin-top: 16px">
            <el-table :data="testItems" stripe>
              <el-table-column prop="code" label="项目代码" width="100" />
              <el-table-column prop="name" label="项目名称" width="150" />
              <el-table-column prop="category" label="类别" width="120" />
              <el-table-column prop="reference_value" label="参考值" />
            </el-table>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 用户对话框 -->
    <el-dialog v-model="userDialogVisible" :title="editingUser ? '编辑用户' : '添加用户'" width="500px">
      <el-form :model="userForm" label-width="80px">
        <el-form-item label="姓名" required>
          <el-input v-model="userForm.real_name" placeholder="请输入姓名" />
        </el-form-item>
        <el-form-item label="工号" required>
          <el-input v-model="userForm.employee_no" placeholder="请输入工号" />
        </el-form-item>
        <el-form-item label="角色" required>
          <el-select v-model="userForm.role" placeholder="请选择角色" style="width: 100%">
            <el-option v-for="(label, value) in roleLabels" :key="value" :label="label" :value="value" />
          </el-select>
        </el-form-item>
        <el-form-item label="科室">
          <el-select v-model="userForm.department_id" placeholder="请选择科室" clearable style="width: 100%">
            <el-option v-for="dept in departments" :key="dept.id" :label="dept.name" :value="dept.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="电话">
          <el-input v-model="userForm.phone" placeholder="请输入电话" />
        </el-form-item>
        <template v-if="!editingUser">
          <el-form-item label="邮箱" required>
            <el-input v-model="userForm.email" placeholder="请输入邮箱" />
          </el-form-item>
          <el-form-item label="密码" required>
            <el-input v-model="userForm.password" type="password" placeholder="请输入密码" show-password />
          </el-form-item>
        </template>
      </el-form>
      <template #footer>
        <el-button @click="userDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveUser">保存</el-button>
      </template>
    </el-dialog>

    <!-- 科室对话框 -->
    <el-dialog v-model="deptDialogVisible" :title="editingDept ? '编辑科室' : '添加科室'" width="400px">
      <el-form :model="deptForm" label-width="80px">
        <el-form-item label="科室代码" required>
          <el-input v-model="deptForm.code" placeholder="如：INT" :disabled="!!editingDept" />
        </el-form-item>
        <el-form-item label="科室名称" required>
          <el-input v-model="deptForm.name" placeholder="如：内科" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="deptDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveDepartment">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { supabaseAdmin } from '@/composables/supabaseAdmin'
import type { UserRole } from '@/types'

const activeTab = ref('users')
const activeDict = ref('drugs')

// 角色选项
const roleLabels: Record<string, string> = {
  admin: '管理员',
  doctor: '医生',
  nurse: '护士',
  lab_tech: '检验师',
  radiology_tech: '放射技师',
  pharmacist: '药师'
}

// 数据
const users = ref<any[]>([])
const departments = ref<any[]>([])
const drugs = ref<any[]>([])
const testItems = ref<any[]>([])

// 用户对话框
const userDialogVisible = ref(false)
const editingUser = ref<any>(null)
const saving = ref(false)
const userForm = ref({
  real_name: '',
  employee_no: '',
  role: '' as UserRole | '',
  department_id: '',
  phone: '',
  email: '',
  password: ''
})

// 科室对话框
const deptDialogVisible = ref(false)
const editingDept = ref<any>(null)
const deptForm = ref({
  code: '',
  name: ''
})

// 获取用户列表
async function fetchUsers() {
  const { data } = await supabase
    .from('users_profile')
    .select('*')
    .order('created_at', { ascending: false })
  users.value = data || []
}

// 获取科室列表
async function fetchDepartments() {
  const { data } = await supabase.from('departments').select('*').order('name')
  departments.value = data || []
}

// 获取科室名称
function getDeptName(deptId: string | null): string {
  if (!deptId) return '-'
  const dept = departments.value.find(d => d.id === deptId)
  return dept?.name || '-'
}

// 打开用户对话框
function openUserDialog(user: any) {
  editingUser.value = user
  if (user) {
    userForm.value = {
      real_name: user.real_name || '',
      employee_no: user.employee_no || '',
      role: user.role || '',
      department_id: user.department_id || '',
      phone: user.phone || '',
      email: '',
      password: ''
    }
  } else {
    userForm.value = {
      real_name: '',
      employee_no: '',
      role: '' as UserRole | '',
      department_id: '',
      phone: '',
      email: '',
      password: ''
    }
  }
  userDialogVisible.value = true
}

// 保存用户
async function saveUser() {
  if (!userForm.value.real_name || !userForm.value.employee_no || !userForm.value.role) {
    return
  }

  saving.value = true
  try {
    if (editingUser.value) {
      // 更新 profile
      const { error } = await supabase
        .from('users_profile')
        .update({
          real_name: userForm.value.real_name,
          employee_no: userForm.value.employee_no,
          role: userForm.value.role,
          department_id: userForm.value.department_id || null,
          phone: userForm.value.phone || null
        })
        .eq('id', editingUser.value.id)

      if (error) throw error
    } else {
      // 创建用户 (需要 supabaseAdmin)
      if (!userForm.value.email || !userForm.value.password) return

      const { data, error } = await supabaseAdmin.auth.admin.createUser({
        email: userForm.value.email,
        password: userForm.value.password,
        email_confirm: true,
        user_metadata: {
          real_name: userForm.value.real_name,
          role: userForm.value.role,
          employee_no: userForm.value.employee_no,
          department_id: userForm.value.department_id || null,
          phone: userForm.value.phone || null
        }
      })

      if (error) throw error
    }

    userDialogVisible.value = false
    await fetchUsers()
  } catch (error: any) {
    console.error('保存用户失败:', error)
    alert('保存失败: ' + (error.message || error))
  } finally {
    saving.value = false
  }
}

// 删除用户
async function deleteUser(user: any) {
  if (!confirm(`确定删除用户 "${user.real_name}" 吗？`)) return

  try {
    const { error } = await supabaseAdmin.auth.admin.deleteUser(user.id)
    if (error) throw error
    await fetchUsers()
  } catch (error: any) {
    console.error('删除用户失败:', error)
    alert('删除失败: ' + (error.message || error))
  }
}

// 打开科室对话框
function openDeptDialog(dept: any) {
  editingDept.value = dept
  if (dept) {
    deptForm.value = { code: dept.code, name: dept.name }
  } else {
    deptForm.value = { code: '', name: '' }
  }
  deptDialogVisible.value = true
}

// 保存科室
async function saveDepartment() {
  if (!deptForm.value.code || !deptForm.value.name) return

  saving.value = true
  try {
    if (editingDept.value) {
      const { error } = await supabase
        .from('departments')
        .update({ name: deptForm.value.name })
        .eq('id', editingDept.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase
        .from('departments')
        .insert({ code: deptForm.value.code, name: deptForm.value.name })
      if (error) throw error
    }
    deptDialogVisible.value = false
    await fetchDepartments()
  } catch (error: any) {
    console.error('保存科室失败:', error)
    alert('保存失败: ' + (error.message || error))
  } finally {
    saving.value = false
  }
}

// 删除科室
async function deleteDepartment(dept: any) {
  if (!confirm(`确定删除科室 "${dept.name}" 吗？`)) return

  try {
    const { error } = await supabase.from('departments').delete().eq('id', dept.id)
    if (error) throw error
    await fetchDepartments()
  } catch (error: any) {
    console.error('删除科室失败:', error)
    alert('删除失败: ' + (error.message || error))
  }
}

// 字典数据
async function fetchDrugs() {
  const { data } = await supabase.from('drugs').select('*').order('name')
  drugs.value = data || []
}

async function fetchTestItems() {
  const { data } = await supabase.from('test_items').select('*').order('name')
  testItems.value = data || []
}

function formatDateTime(dateStr: string): string {
  return new Date(dateStr).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchUsers()
  fetchDepartments()
  fetchDrugs()
  fetchTestItems()
})
</script>

<style scoped>
.admin-page {
  max-width: 1400px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}
</style>
