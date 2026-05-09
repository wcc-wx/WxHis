<template>
  <el-container class="main-layout">
    <el-aside width="220px" class="sidebar">
      <div class="logo">
        <span class="logo-text">文贤HIS</span>
      </div>
      <el-menu
        :default-active="activeMenu"
        class="sidebar-menu"
        background-color="#304156"
        text-color="#bfcbd9"
        active-text-color="#409eff"
        :router="true"
      >
        <el-menu-item index="/dashboard">
          <el-icon><Odometer /></el-icon>
          <span>仪表盘</span>
        </el-menu-item>

        <el-sub-menu index="patients" v-if="showMenu(['admin', 'doctor', 'nurse'])">
          <template #title>
            <el-icon><User /></el-icon>
            <span>患者管理</span>
          </template>
          <el-menu-item index="/patients">患者列表</el-menu-item>
          <el-menu-item index="/patients/search">患者搜索</el-menu-item>
        </el-sub-menu>

        <el-menu-item index="/registration" v-if="showMenu(['admin', 'nurse'])">
          <el-icon><Tickets /></el-icon>
          <span>挂号管理</span>
        </el-menu-item>

        <el-menu-item index="/clinic" v-if="showMenu(['admin', 'doctor'])">
          <el-icon><FirstAidKit /></el-icon>
          <span>门诊工作站</span>
        </el-menu-item>

        <el-menu-item index="/emr" v-if="showMenu(['admin', 'doctor'])">
          <el-icon><Document /></el-icon>
          <span>电子病历</span>
        </el-menu-item>

        <el-sub-menu index="lab" v-if="showMenu(['admin', 'lab_tech'])">
          <template #title>
            <el-icon><Tools /></el-icon>
            <span>检验管理</span>
          </template>
          <el-menu-item index="/lab">检验申请</el-menu-item>
          <el-menu-item index="/lab/results">结果录入</el-menu-item>
          <el-menu-item index="/lab/reports">报告审核</el-menu-item>
        </el-sub-menu>

        <el-sub-menu index="pacs" v-if="showMenu(['admin', 'radiology_tech'])">
          <template #title>
            <el-icon><Monitor /></el-icon>
            <span>影像管理</span>
          </template>
          <el-menu-item index="/pacs">检查申请</el-menu-item>
          <el-menu-item index="/pacs/studies">影像管理</el-menu-item>
        </el-sub-menu>

        <el-menu-item index="/pharmacy" v-if="showMenu(['admin', 'pharmacist'])">
          <el-icon><Box /></el-icon>
          <span>药房管理</span>
        </el-menu-item>

        <el-menu-item index="/inpatient" v-if="showMenu(['admin', 'doctor', 'nurse'])">
          <el-icon><House /></el-icon>
          <span>住院管理</span>
        </el-menu-item>

        <el-menu-item index="/admin" v-if="showMenu(['admin'])">
          <el-icon><Setting /></el-icon>
          <span>系统设置</span>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="header">
        <div class="header-left">
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/dashboard' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item v-if="route.meta.title !== '仪表盘'">{{ route.meta.title }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="header-right">
          <el-dropdown @command="handleCommand">
            <span class="user-info">
              <el-icon><UserFilled /></el-icon>
              <span class="user-name">{{ authStore.profile?.real_name || '用户' }}</span>
              <span class="user-role">({{ roleLabel }})</span>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人资料</el-dropdown-item>
                <el-dropdown-item command="password">修改密码</el-dropdown-item>
                <el-dropdown-item divided command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-main class="main-content">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import {
  Odometer,
  User,
  Tickets,
  FirstAidKit,
  Document,
  Tools,
  Monitor,
  Box,
  House,
  Setting,
  UserFilled
} from '@element-plus/icons-vue'
import type { UserRole } from '@/types'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const activeMenu = computed(() => route.path)

const roleLabels: Record<UserRole, string> = {
  admin: '管理员',
  doctor: '医生',
  nurse: '护士',
  lab_tech: '检验师',
  radiology_tech: '放射技师',
  pharmacist: '药师'
}

const roleLabel = computed(() => {
  if (!authStore.profile?.role) return ''
  return roleLabels[authStore.profile.role]
})

function showMenu(roles: UserRole[]): boolean {
  return authStore.hasRole(...roles)
}

function handleCommand(command: string) {
  switch (command) {
    case 'logout':
      authStore.signOut()
      break
    case 'profile':
      // TODO: implement profile page
      break
    case 'password':
      // TODO: implement password change
      break
  }
}
</script>

<style scoped>
.main-layout {
  height: 100vh;
}

.sidebar {
  background-color: #304156;
}

.logo {
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #263445;
}

.logo-text {
  color: #fff;
  font-size: 20px;
  font-weight: bold;
}

.sidebar-menu {
  border-right: none;
  height: calc(100vh - 60px);
}

.header {
  background-color: #fff;
  box-shadow: 0 1px 4px rgba(0, 21, 41, 0.08);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
}

.header-left {
  display: flex;
  align-items: center;
}

.header-right {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 0 10px;
}

.user-info:hover {
  background-color: #f5f7fa;
}

.user-name {
  margin-left: 8px;
  font-weight: 500;
}

.user-role {
  margin-left: 4px;
  color: #909399;
  font-size: 12px;
}

.main-content {
  background-color: #f0f2f5;
  padding: 20px;
}
</style>
