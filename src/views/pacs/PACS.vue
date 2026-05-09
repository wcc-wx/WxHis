<template>
  <div class="pacs-page">
    <h2>影像管理</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="检查申请" name="requests">
          <el-table :data="imagingRequests" stripe>
            <el-table-column prop="created_at" label="申请时间" width="180">
              <template #default="{ row }">
                {{ formatDateTime(row.created_at) }}
              </template>
            </el-table-column>
            <el-table-column prop="patient.name" label="患者姓名" width="120" />
            <el-table-column prop="exam_type" label="检查类型" width="100" />
            <el-table-column prop="exam_part" label="检查部位" width="120" />
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
                  v-if="row.status === 'pending'"
                  type="primary"
                  size="small"
                  @click="registerExam(row)"
                >
                  登记
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="影像管理" name="studies">
          <el-table :data="imagingStudies" stripe>
            <el-table-column prop="exam_time" label="检查时间" width="180">
              <template #default="{ row }">
                {{ formatDateTime(row.exam_time) }}
              </template>
            </el-table-column>
            <el-table-column prop="imaging_request.patient.name" label="患者姓名" width="120" />
            <el-table-column prop="imaging_request.exam_type" label="检查类型" width="100" />
            <el-table-column prop="imaging_request.exam_part" label="检查部位" width="120" />
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="getStudyStatusType(row.status)" size="small">
                  {{ getStudyStatusLabel(row.status) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="200">
              <template #default="{ row }">
                <el-button
                  v-if="row.status === 'pending'"
                  type="primary"
                  size="small"
                  @click="startImaging(row)"
                >
                  开始检查
                </el-button>
                <el-button
                  v-if="row.status === 'in_progress'"
                  type="success"
                  size="small"
                  @click="showUploadDialog(row)"
                >
                  上传影像
                </el-button>
                <el-button
                  v-if="row.status === 'completed'"
                  type="warning"
                  size="small"
                  @click="showReportDialog(row)"
                >
                  写报告
                </el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 上传影像对话框 -->
    <el-dialog v-model="uploadDialogVisible" title="上传影像" width="500px">
      <el-upload
        ref="uploadRef"
        :auto-upload="false"
        :on-change="handleFileChange"
        :file-list="fileList"
        accept="image/*,.dcm"
        multiple
        drag
      >
        <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
        <div class="el-upload__text">拖拽文件到此处或<em>点击上传</em></div>
        <template #tip>
          <div class="el-upload__tip">支持 JPG、PNG、DICOM 格式</div>
        </template>
      </el-upload>
      <template #footer>
        <el-button @click="uploadDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleUpload" :loading="uploading">上传</el-button>
      </template>
    </el-dialog>

    <!-- 写报告对话框 -->
    <el-dialog v-model="reportDialogVisible" title="编写报告" width="600px">
      <el-form label-width="100px">
        <el-form-item label="报告内容">
          <el-input
            v-model="reportContent"
            type="textarea"
            :rows="10"
            placeholder="请输入影像报告内容..."
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="reportDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveReport">保存报告</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'
import type { UploadFile } from 'element-plus'

const authStore = useAuthStore()
const activeTab = ref('requests')

const imagingRequests = ref<any[]>([])
const imagingStudies = ref<any[]>([])

const uploadDialogVisible = ref(false)
const reportDialogVisible = ref(false)
const uploading = ref(false)

const currentStudy = ref<any | null>(null)
const reportContent = ref('')
const fileList = ref<UploadFile[]>([])

async function fetchImagingRequests() {
  const { data } = await supabase
    .from('imaging_requests')
    .select(`
      *,
      patient:patients(name)
    `)
    .eq('status', 'pending')
    .order('created_at', { ascending: false })

  imagingRequests.value = data || []
}

async function fetchImagingStudies() {
  const { data } = await supabase
    .from('imaging_studies')
    .select(`
      *,
      imaging_request:imaging_requests(*, patient:patients(name))
    `)
    .in('status', ['pending', 'in_progress', 'completed'])
    .order('exam_time', { ascending: false })

  imagingStudies.value = data || []
}

async function registerExam(row: any) {
  const { error } = await supabase.from('imaging_studies').insert({
    imaging_request_id: row.id,
    patient_id: row.patient_id,
    status: 'pending'
  })

  if (error) {
    ElMessage.error('登记失败')
  } else {
    await supabase.from('imaging_requests').update({ status: 'registered' }).eq('id', row.id)
    ElMessage.success('已登记')
    await fetchImagingRequests()
    await fetchImagingStudies()
  }
}

async function startImaging(row: any) {
  await supabase
    .from('imaging_studies')
    .update({ status: 'in_progress', exam_time: new Date().toISOString() })
    .eq('id', row.id)

  ElMessage.success('已开始检查')
  await fetchImagingStudies()
}

function showUploadDialog(row: any) {
  currentStudy.value = row
  fileList.value = []
  uploadDialogVisible.value = true
}

function handleFileChange(file: UploadFile) {
  fileList.value.push(file)
}

async function handleUpload() {
  if (!currentStudy.value || fileList.value.length === 0) {
    ElMessage.warning('请选择要上传的文件')
    return
  }

  uploading.value = true
  try {
    const urls: string[] = []

    for (const file of fileList.value) {
      const filePath = `pacs/${currentStudy.value.id}/${file.name}`

      const { error: uploadError } = await supabase.storage
        .from('pacs-images')
        .upload(filePath, file.raw)

      if (uploadError) throw uploadError

      const { data: urlData } = supabase.storage
        .from('pacs-images')
        .getPublicUrl(filePath)

      urls.push(urlData.publicUrl)
    }

    await supabase
      .from('imaging_studies')
      .update({
        status: 'completed',
        image_urls: urls
      })
      .eq('id', currentStudy.value.id)

    ElMessage.success('影像上传成功')
    uploadDialogVisible.value = false
    await fetchImagingStudies()
  } catch (error: any) {
    ElMessage.error(error.message || '上传失败')
  } finally {
    uploading.value = false
  }
}

function showReportDialog(row: any) {
  currentStudy.value = row
  reportContent.value = row.report_content || ''
  reportDialogVisible.value = true
}

async function saveReport() {
  const { error } = await supabase
    .from('imaging_studies')
    .update({
      report_content: reportContent.value,
      report_doctor_id: authStore.profile?.id
    })
    .eq('id', currentStudy.value.id)

  if (error) {
    ElMessage.error('保存失败')
  } else {
    ElMessage.success('报告已保存')
    reportDialogVisible.value = false
    await fetchImagingStudies()
  }
}

function getStatusType(status: string): string {
  const map: Record<string, string> = {
    pending: 'info',
    registered: 'warning',
    imaging: 'primary',
    reported: 'success',
    cancelled: 'danger'
  }
  return map[status] || 'info'
}

function getStatusLabel(status: string): string {
  const map: Record<string, string> = {
    pending: '待登记',
    registered: '已登记',
    imaging: '检查中',
    reported: '已报告',
    cancelled: '已取消'
  }
  return map[status] || status
}

function getStudyStatusType(status: string): string {
  const map: Record<string, string> = {
    pending: 'info',
    in_progress: 'warning',
    completed: 'success',
    reported: 'primary'
  }
  return map[status] || 'info'
}

function getStudyStatusLabel(status: string): string {
  const map: Record<string, string> = {
    pending: '待检查',
    in_progress: '检查中',
    completed: '待报告',
    reported: '已报告'
  }
  return map[status] || status
}

function formatDateTime(dateStr: string | null): string {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchImagingRequests()
  fetchImagingStudies()
})
</script>

<style scoped>
.pacs-page {
  max-width: 1400px;
  margin: 0 auto;
}

h2 {
  margin-bottom: 20px;
  color: #303133;
}
</style>
