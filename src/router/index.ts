import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'Login',
      component: () => import('@/views/login/Login.vue'),
      meta: { requiresAuth: false, title: '登录' }
    },
    {
      path: '/',
      component: () => import('@/components/layout/MainLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          redirect: '/dashboard'
        },
        {
          path: 'dashboard',
          name: 'Dashboard',
          component: () => import('@/views/Dashboard.vue'),
          meta: { title: '仪表盘', roles: ['admin', 'doctor', 'nurse', 'lab_tech', 'radiology_tech', 'pharmacist'] }
        },
        {
          path: 'patients',
          name: 'Patients',
          component: () => import('@/views/patients/Patients.vue'),
          meta: { title: '患者管理', roles: ['admin', 'doctor', 'nurse'] }
        },
        {
          path: 'patients/:id',
          name: 'PatientDetail',
          component: () => import('@/views/patients/PatientDetail.vue'),
          meta: { title: '患者详情', roles: ['admin', 'doctor', 'nurse'] }
        },
        {
          path: 'registration',
          name: 'Registration',
          component: () => import('@/views/registration/Registration.vue'),
          meta: { title: '挂号管理', roles: ['admin', 'nurse'] }
        },
        {
          path: 'clinic',
          name: 'Clinic',
          component: () => import('@/views/clinic/Clinic.vue'),
          meta: { title: '门诊工作站', roles: ['admin', 'doctor'] }
        },
        {
          path: 'emr',
          name: 'EMR',
          component: () => import('@/views/emr/EMR.vue'),
          meta: { title: '电子病历', roles: ['admin', 'doctor'] }
        },
        {
          path: 'lab',
          name: 'Lab',
          component: () => import('@/views/lab/Lab.vue'),
          meta: { title: '检验管理', roles: ['admin', 'lab_tech'] }
        },
        {
          path: 'pacs',
          name: 'PACS',
          component: () => import('@/views/pacs/PACS.vue'),
          meta: { title: '影像管理', roles: ['admin', 'radiology_tech'] }
        },
        {
          path: 'pharmacy',
          name: 'Pharmacy',
          component: () => import('@/views/pharmacy/Pharmacy.vue'),
          meta: { title: '药房管理', roles: ['admin', 'pharmacist'] }
        },
        {
          path: 'inpatient',
          name: 'Inpatient',
          component: () => import('@/views/inpatient/Inpatient.vue'),
          meta: { title: '住院管理', roles: ['admin', 'doctor', 'nurse'] }
        },
        {
          path: 'admin',
          name: 'Admin',
          component: () => import('@/views/admin/Admin.vue'),
          meta: { title: '系统设置', roles: ['admin'] }
        }
      ]
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/login'
    }
  ]
})

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  if (!authStore.initialized) {
    await authStore.initialize()
  }

  const requiresAuth = to.matched.some(record => record.meta.requiresAuth !== false)
  const allowedRoles = to.meta.roles as string[] | undefined

  if (requiresAuth && !authStore.isAuthenticated) {
    next('/login')
    return
  }

  if (to.path === '/login' && authStore.isAuthenticated) {
    next('/dashboard')
    return
  }

  if (allowedRoles && authStore.profile) {
    if (!allowedRoles.includes(authStore.profile.role)) {
      next('/dashboard')
      return
    }
  }

  document.title = `${to.meta.title || 'HIS'} - 文贤HIS`
  next()
})

export default router
