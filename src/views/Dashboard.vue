<template>
  <div class="dashboard">
    <el-row :gutter="20">
      <el-col :span="24">
        <h2 class="page-title">欢迎使用文贤HIS医院信息系统</h2>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="stats-row">
      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" color="#409eff"><User /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ stats.todayPatients }}</div>
              <div class="stat-label">今日患者</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" color="#67c23a"><Tickets /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ stats.pendingRegistrations }}</div>
              <div class="stat-label">待诊挂号</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" color="#e6a23c"><Tools /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ stats.pendingLabRequests }}</div>
              <div class="stat-label">待检检验</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :sm="12" :md="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" color="#f56c6c"><Monitor /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ stats.pendingImagingRequests }}</div>
              <div class="stat-label">待检影像</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20">
      <el-col :xs="24" :md="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>快捷操作</span>
            </div>
          </template>
          <div class="quick-actions">
            <el-button type="primary" @click="router.push('/patients')">患者管理</el-button>
            <el-button type="success" @click="router.push('/registration')">挂号管理</el-button>
            <el-button type="warning" @click="router.push('/clinic')">门诊接诊</el-button>
            <el-button type="info" @click="router.push('/lab')">检验管理</el-button>
            <el-button type="danger" @click="router.push('/pacs')">影像管理</el-button>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :md="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>待办事项</span>
            </div>
          </template>
          <el-empty v-if="todos.length === 0" description="暂无待办事项" />
          <el-list v-else>
            <el-list-item v-for="todo in todos" :key="todo.id">
              <div class="todo-item">
                <span class="todo-text">{{ todo.text }}</span>
                <el-tag :type="todo.type">{{ todo.label }}</el-tag>
              </div>
            </el-list-item>
          </el-list>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { User, Tickets, Tools, Monitor } from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()

const stats = ref({
  todayPatients: 0,
  pendingRegistrations: 0,
  pendingLabRequests: 0,
  pendingImagingRequests: 0
})

const todos = ref<Array<{ id: number; text: string; label: string; type: string }>>([])

onMounted(async () => {
  // TODO: Fetch actual stats from database
  stats.value = {
    todayPatients: 0,
    pendingRegistrations: 0,
    pendingLabRequests: 0,
    pendingImagingRequests: 0
  }
})
</script>

<style scoped>
.dashboard {
  max-width: 1400px;
  margin: 0 auto;
}

.page-title {
  font-size: 24px;
  margin-bottom: 20px;
  color: #303133;
}

.stats-row {
  margin-bottom: 20px;
}

.stat-card {
  cursor: pointer;
  transition: transform 0.2s;
}

.stat-card:hover {
  transform: translateY(-4px);
}

.stat-content {
  display: flex;
  align-items: center;
}

.stat-icon {
  font-size: 48px;
  margin-right: 20px;
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  color: #303133;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-top: 4px;
}

.card-header {
  font-weight: 500;
  font-size: 16px;
}

.quick-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.todo-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  padding: 8px 0;
}

.todo-text {
  flex: 1;
}
</style>
