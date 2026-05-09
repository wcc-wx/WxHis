import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/composables/supabase'
import type { UserProfile, UserRole } from '@/types'
import type { User } from '@supabase/supabase-js'
import router from '@/router'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const profile = ref<UserProfile | null>(null)
  const loading = ref(true)
  const initialized = ref(false)

  const isAuthenticated = computed(() => !!user.value)
  const userRole = computed(() => profile.value?.role || null)
  const isAdmin = computed(() => {
    const admin = profile.value?.role === 'admin'
    console.log('[Auth] isAdmin computed:', admin, 'role:', profile.value?.role)
    return admin
  })
  const isDoctor = computed(() => profile.value?.role === 'doctor')
  const isNurse = computed(() => profile.value?.role === 'nurse')
  const isLabTech = computed(() => profile.value?.role === 'lab_tech')
  const isRadiologyTech = computed(() => profile.value?.role === 'radiology_tech')
  const isPharmacist = computed(() => profile.value?.role === 'pharmacist')

  async function initialize() {
    if (initialized.value) return

    loading.value = true
    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (session?.user) {
        user.value = session.user
        await fetchProfile()
      }
    } catch (error) {
      console.error('Auth initialization error:', error)
    } finally {
      loading.value = false
      initialized.value = true
    }

    supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN' && session?.user) {
        user.value = session.user
        await fetchProfile()
      } else if (event === 'SIGNED_OUT') {
        user.value = null
        profile.value = null
        router.push('/login')
      }
    })
  }

  async function fetchProfile() {
    if (!user.value) {
      console.log('[Auth] fetchProfile skipped: no user')
      return
    }

    console.log('[Auth] Fetching profile for user:', user.value.id)
    const { data, error } = await supabase
      .from('users_profile')
      .select('*')
      .eq('id', user.value.id)

    if (error) {
      console.error('[Auth] Error fetching profile:', error)
      return
    }

    if (!data || data.length === 0) {
      console.error('[Auth] No profile found for user:', user.value.id, '— user needs a profile entry in users_profile table')
      return
    }

    console.log('[Auth] Profile loaded:', data[0])
    profile.value = data[0]
  }

  async function signIn(email: string, password: string) {
    loading.value = true
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      })

      if (error) {
        console.error('[Auth] signIn error:', error)
        return { error: error.message }
      }

      // Wait for profile to be loaded via onAuthStateChange
      if (data.user) {
        user.value = data.user
        console.log('[Auth] signIn success, fetching profile for:', data.user.id)
        await fetchProfile()
        console.log('[Auth] signIn complete, profile role:', profile.value?.role, 'profile:', profile.value)
      } else {
        console.log('[Auth] signIn returned no user data')
      }

      return { success: true }
    } catch (error: any) {
      console.error('[Auth] signIn exception:', error)
      return { error: error.message || '登录失败' }
    } finally {
      loading.value = false
    }
  }

  async function signOut() {
    const { error } = await supabase.auth.signOut()
    if (error) {
      console.error('Sign out error:', error)
    }
    user.value = null
    profile.value = null
    router.push('/login')
  }

  async function register(email: string, password: string, realName: string, role: UserRole, employeeNo: string, departmentId: string) {
    loading.value = true
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            real_name: realName,
            role,
            employee_no: employeeNo,
            department_id: departmentId
          }
        }
      })

      if (error) {
        return { error: error.message }
      }

      return { success: true, user: data.user }
    } catch (error: any) {
      return { error: error.message || '注册失败' }
    } finally {
      loading.value = false
    }
  }

  function hasRole(...roles: UserRole[]): boolean {
    console.log('[Auth] hasRole check:', { profileRole: profile.value?.role, requiredRoles: roles })
    if (!profile.value?.role) return false
    return roles.includes(profile.value.role)
  }

  return {
    user,
    profile,
    loading,
    initialized,
    isAuthenticated,
    userRole,
    isAdmin,
    isDoctor,
    isNurse,
    isLabTech,
    isRadiologyTech,
    isPharmacist,
    initialize,
    fetchProfile,
    signIn,
    signOut,
    register,
    hasRole
  }
})
