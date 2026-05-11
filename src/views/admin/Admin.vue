<template>
  <div class="admin-page">
    <h2>系统设置</h2>
    <el-card>
      <el-tabs v-model="activeTab">
        <el-tab-pane label="参数配置" name="config">
          <el-form :inline="true" class="filter-form">
            <el-form-item label="配置组">
              <el-select v-model="filterConfigGroup" placeholder="全部" clearable style="width: 150px" @change="fetchConfigs">
                <el-option label="系统配置" value="system" />
                <el-option label="业务配置" value="business" />
                <el-option label="界面配置" value="ui" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="openConfigDialog(null)">新增配置</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="configs" stripe style="margin-top: 16px">
            <el-table-column prop="config_name" label="配置名称" width="180" />
            <el-table-column prop="config_key" label="配置键" width="200" />
            <el-table-column prop="config_value" label="配置值" show-overflow-tooltip />
            <el-table-column prop="config_type" label="类型" width="80">
              <template #default="{ row }">
                <el-tag size="small">{{ row.config_type }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="config_group" label="分组" width="100" />
            <el-table-column prop="effective_date" label="生效日期" width="110">
              <template #default="{ row }">{{ row.effective_date || '-' }}</template>
            </el-table-column>
            <el-table-column prop="expire_date" label="失效日期" width="110">
              <template #default="{ row }">{{ row.expire_date || '-' }}</template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="80">
              <template #default="{ row }">
                <el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">
                  {{ row.status === 'active' ? '生效' : '失效' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="150" fixed="right">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="openConfigDialog(row)">编辑</el-button>
                <el-button type="danger" size="small" @click="deleteConfig(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="数据字典" name="dict">
          <el-form :inline="true" class="filter-form">
            <el-form-item label="字典类型">
              <el-select v-model="filterDictType" placeholder="全部" clearable style="width: 150px" @change="fetchDicts">
                <el-option label="性别" value="gender" />
                <el-option label="婚姻状况" value="marital_status" />
                <el-option label="学历" value="education" />
                <el-option label="医保类型" value="insurance_type" />
                <el-option label="支付方式" value="payment_method" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="openDictDialog(null)">新增字典</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="dicts" stripe style="margin-top: 16px">
            <el-table-column prop="dict_type" label="类型" width="120" />
            <el-table-column prop="dict_code" label="编码" width="120" />
            <el-table-column prop="dict_label" label="标签" width="150" />
            <el-table-column prop="dict_value" label="值" width="150" />
            <el-table-column prop="sort_order" label="排序" width="70" />
            <el-table-column prop="is_default" label="默认" width="70">
              <template #default="{ row }">
                <el-tag v-if="row.is_default" type="success" size="small">是</el-tag>
                <span v-else>-</span>
              </template>
            </el-table-column>
            <el-table-column prop="is_enabled" label="状态" width="80">
              <template #default="{ row }">
                <el-tag :type="row.is_enabled ? 'success' : 'info'" size="small">
                  {{ row.is_enabled ? '启用' : '禁用' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="150" fixed="right">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="openDictDialog(row)">编辑</el-button>
                <el-button type="danger" size="small" @click="deleteDict(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="操作日志" name="audit">
          <el-form :inline="true" class="filter-form">
            <el-form-item label="日期">
              <el-date-picker
                v-model="filterLogDate"
                type="date"
                placeholder="选择日期"
                style="width: 150px"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
                @change="fetchAuditLogs"
              />
            </el-form-item>
            <el-form-item label="操作类型">
              <el-select v-model="filterActionType" placeholder="全部" clearable style="width: 120px" @change="fetchAuditLogs">
                <el-option label="登录" value="login" />
                <el-option label="新增" value="create" />
                <el-option label="更新" value="update" />
                <el-option label="删除" value="delete" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button @click="resetLogFilter">重置</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="auditLogs" stripe style="margin-top: 16px" height="400">
            <el-table-column prop="create_time" label="时间" width="160">
              <template #default="{ row }">{{ formatDateTime(row.create_time) }}</template>
            </el-table-column>
            <el-table-column prop="user_name" label="用户" width="100" />
            <el-table-column prop="action_type" label="操作" width="80">
              <template #default="{ row }">
                <el-tag size="small">{{ getActionLabel(row.action_type) }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="module_name" label="模块" width="120" />
            <el-table-column prop="action_detail" label="详情" show-overflow-tooltip />
            <el-table-column prop="ip_address" label="IP地址" width="130" />
            <el-table-column prop="result" label="结果" width="80">
              <template #default="{ row }">
                <el-tag :type="row.result === 'success' ? 'success' : 'danger'" size="small">
                  {{ row.result === 'success' ? '成功' : '失败' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="execution_time" label="耗时" width="80">
              <template #default="{ row }">{{ row.execution_time ? row.execution_time + 'ms' : '-' }}</template>
            </el-table-column>
          </el-table>

          <div class="pagination-wrapper">
            <el-pagination
              v-model:current-page="logPagination.page"
              v-model:page-size="logPagination.pageSize"
              :total="logPagination.total"
              :page-sizes="[20, 50, 100]"
              layout="total, sizes, prev, pager, next"
              @size-change="fetchAuditLogs"
              @current-change="fetchAuditLogs"
            />
          </div>
        </el-tab-pane>

        <el-tab-pane label="消息通知" name="message">
          <el-form :inline="true" class="filter-form">
            <el-form-item label="类型">
              <el-select v-model="filterMsgType" placeholder="全部" clearable style="width: 120px" @change="fetchMessages">
                <el-option label="通知" value="notification" />
                <el-option label="提醒" value="reminder" />
                <el-option label="任务" value="task" />
                <el-option label="告警" value="alert" />
              </el-select>
            </el-form-item>
            <el-form-item label="状态">
              <el-select v-model="filterMsgStatus" placeholder="全部" clearable style="width: 100px" @change="fetchMessages">
                <el-option label="未读" value="unread" />
                <el-option label="已读" value="read" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button @click="resetMsgFilter">重置</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="messages" stripe style="margin-top: 16px" @row-click="viewMessage">
            <el-table-column prop="is_read" label="状态" width="70">
              <template #default="{ row }">
                <el-badge is-dot :type="row.is_read ? 'info' : 'danger'" />
              </template>
            </el-table-column>
            <el-table-column prop="priority" label="优先级" width="80">
              <template #default="{ row }">
                <el-tag v-if="row.priority === 'urgent'" type="danger" size="small">紧急</el-tag>
                <el-tag v-else-if="row.priority === 'high'" type="warning" size="small">高</el-tag>
                <el-tag v-else type="info" size="small">普通</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="title" label="标题" show-overflow-tooltip />
            <el-table-column prop="message_type" label="类型" width="80">
              <template #default="{ row }">{{ getMessageTypeLabel(row.message_type) }}</template>
            </el-table-column>
            <el-table-column prop="sender_name" label="发送者" width="100" />
            <el-table-column prop="create_time" label="时间" width="160">
              <template #default="{ row }">{{ formatDateTime(row.create_time) }}</template>
            </el-table-column>
          </el-table>

          <div class="pagination-wrapper">
            <el-pagination
              v-model:current-page="msgPagination.page"
              v-model:page-size="msgPagination.pageSize"
              :total="msgPagination.total"
              :page-sizes="[20, 50, 100]"
              layout="total, sizes, prev, pager, next"
              @size-change="fetchMessages"
              @current-change="fetchMessages"
            />
          </div>
        </el-tab-pane>

        <el-tab-pane label="员工管理" name="employee">
          <el-form :inline="true" class="filter-form">
            <el-form-item label="姓名">
              <el-input v-model="filterEmpName" placeholder="请输入姓名" clearable @change="fetchEmployees" />
            </el-form-item>
            <el-form-item label="科室">
              <el-select v-model="filterEmpDept" placeholder="全部" clearable style="width: 150px" @change="fetchEmployees">
                <el-option v-for="dept in departments" :key="dept.id" :label="dept.name" :value="dept.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="状态">
              <el-select v-model="filterEmpStatus" placeholder="全部" clearable style="width: 100px" @change="fetchEmployees">
                <el-option label="在职" value="active" />
                <el-option label="离职" value="retired" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="openEmployeeDialog(null)">新增员工</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="employees" stripe style="margin-top: 16px">
            <el-table-column prop="emp_no" label="工号" width="100" />
            <el-table-column prop="name" label="姓名" width="100" />
            <el-table-column prop="gender" label="性别" width="60" />
            <el-table-column prop="dept_id" label="科室" width="120">
              <template #default="{ row }">{{ getDeptName(row.dept_id) }}</template>
            </el-table-column>
            <el-table-column prop="emp_type" label="岗位" width="80">
              <template #default="{ row }">{{ getEmpTypeLabel(row.emp_type) }}</template>
            </el-table-column>
            <el-table-column prop="title" label="职称" width="100" />
            <el-table-column prop="professional_title" label="专业职称" width="100" />
            <el-table-column prop="phone" label="电话" width="120" />
            <el-table-column prop="status" label="状态" width="80">
              <template #default="{ row }">
                <el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">
                  {{ row.status === 'active' ? '在职' : row.status === 'retired' ? '离职' : '其他' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="180" fixed="right">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="openEmployeeDialog(row)">编辑</el-button>
                <el-button type="danger" size="small" @click="deleteEmployee(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="科室管理" name="dept">
          <el-form :inline="true" class="filter-form">
            <el-form-item>
              <el-button type="primary" @click="openDeptDialog(null)">新增科室</el-button>
            </el-form-item>
          </el-form>

          <el-table :data="departments" stripe style="margin-top: 16px">
            <el-table-column prop="code" label="科室代码" width="120" />
            <el-table-column prop="name" label="科室名称" />
            <el-table-column prop="dept_type" label="类型" width="100">
              <template #default="{ row }">{{ getDeptTypeLabel(row.dept_type) }}</template>
            </el-table-column>
            <el-table-column prop="category" label="分类" width="100" />
            <el-table-column prop="reg_fee" label="挂号费" width="100">
              <template #default="{ row }">¥{{ (row.reg_fee || 0) / 100 }}</template>
            </el-table-column>
            <el-table-column prop="status" label="状态" width="80">
              <template #default="{ row }">
                <el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">
                  {{ row.status === 'active' ? '启用' : '停用' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="sort_order" label="排序" width="70" />
            <el-table-column label="操作" width="150" fixed="right">
              <template #default="{ row }">
                <el-button type="primary" size="small" @click="openDeptDialog(row)">编辑</el-button>
                <el-button type="danger" size="small" @click="deleteDept(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="基础字典" name="basedict">
          <el-space wrap style="margin-bottom: 16px">
            <el-button :type="activeBaseDict === 'drug' ? 'primary' : ''" @click="activeBaseDict = 'drug'">药品字典</el-button>
            <el-button :type="activeBaseDict === 'icd10' ? 'primary' : ''" @click="activeBaseDict = 'icd10'">ICD-10诊断</el-button>
            <el-button :type="activeBaseDict === 'charge' ? 'primary' : ''" @click="activeBaseDict = 'charge'">收费项目</el-button>
            <el-button :type="activeBaseDict === 'lis' ? 'primary' : ''" @click="activeBaseDict = 'lis'">检验项目</el-button>
            <el-button :type="activeBaseDict === 'ris' ? 'primary' : ''" @click="activeBaseDict = 'ris'">检查项目</el-button>
          </el-space>

          <div v-if="activeBaseDict === 'drug'">
            <el-form :inline="true" class="filter-form">
              <el-form-item label="药品名称">
                <el-input v-model="filterDrugName" placeholder="请输入" clearable @change="fetchBaseDictData" />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="openBaseDictDialog('drug', null)">新增药品</el-button>
              </el-form-item>
            </el-form>
            <el-table :data="baseDictData" stripe style="margin-top: 12px">
              <el-table-column prop="drug_code" label="药品编码" width="120" />
              <el-table-column prop="common_name" label="通用名" width="150" />
              <el-table-column prop="spec" label="规格" width="120" />
              <el-table-column prop="unit" label="单位" width="60" />
              <el-table-column prop="price" label="单价" width="80">
                <template #default="{ row }">¥{{ row.price / 100 }}</template>
              </el-table-column>
              <el-table-column prop="drug_type" label="类型" width="80">
                <template #default="{ row }">{{ getDrugTypeLabel(row.drug_type) }}</template>
              </el-table-column>
              <el-table-column prop="antibiotic_level" label="抗生素分级" width="100">
                <template #default="{ row }">{{ getAntibioticLabel(row.antibiotic_level) }}</template>
              </el-table-column>
              <el-table-column prop="status" label="状态" width="70">
                <template #default="{ row }">
                  <el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">{{ row.status === 'active' ? '启用' : '停用' }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="120" fixed="right">
                <template #default="{ row }">
                  <el-button type="primary" size="small" @click="openBaseDictDialog('drug', row)">编辑</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>

          <div v-if="activeBaseDict === 'icd10'">
            <el-form :inline="true" class="filter-form">
              <el-form-item label="诊断名称">
                <el-input v-model="filterIcdName" placeholder="请输入" clearable @change="fetchBaseDictData" />
              </el-form-item>
              <el-form-item>
                <el-button type="primary" @click="openBaseDictDialog('icd10', null)">新增诊断</el-button>
              </el-form-item>
            </el-form>
            <el-table :data="baseDictData" stripe style="margin-top: 12px">
              <el-table-column prop="code" label="ICD编码" width="120" />
              <el-table-column prop="name" label="诊断名称" />
              <el-table-column prop="disease_type" label="疾病类型" width="100" />
              <el-table-column prop="is_chronic" label="慢性病" width="80">
                <template #default="{ row }">
                  <el-tag v-if="row.is_chronic" type="warning" size="small">是</el-tag>
                  <span v-else>-</span>
                </template>
              </el-table-column>
              <el-table-column prop="is_infectious" label="传染病" width="80">
                <template #default="{ row }">
                  <el-tag v-if="row.is_infectious" type="danger" size="small">是</el-tag>
                  <span v-else>-</span>
                </template>
              </el-table-column>
              <el-table-column prop="reportable" label="上报" width="70">
                <template #default="{ row }">
                  <el-tag v-if="row.reportable" type="warning" size="small">需上报</el-tag>
                  <span v-else>-</span>
                </template>
              </el-table-column>
              <el-table-column prop="status" label="状态" width="70">
                <template #default="{ row }">
                  <el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">{{ row.status === 'active' ? '启用' : '停用' }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="120" fixed="right">
                <template #default="{ row }">
                  <el-button type="primary" size="small" @click="openBaseDictDialog('icd10', row)">编辑</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 配置对话框 -->
    <el-dialog v-model="configDialogVisible" :title="editingConfig ? '编辑配置' : '新增配置'" width="500px">
      <el-form :model="configForm" label-width="100px">
        <el-form-item label="配置名称" required>
          <el-input v-model="configForm.config_name" placeholder="请输入" />
        </el-form-item>
        <el-form-item label="配置键" required>
          <el-input v-model="configForm.config_key" placeholder="请输入" :disabled="!!editingConfig" />
        </el-form-item>
        <el-form-item label="配置值" required>
          <el-input v-model="configForm.config_value" type="textarea" rows="3" placeholder="请输入" />
        </el-form-item>
        <el-form-item label="类型">
          <el-select v-model="configForm.config_type" style="width: 100%">
            <el-option label="字符串" value="string" />
            <el-option label="数字" value="number" />
            <el-option label="布尔值" value="boolean" />
            <el-option label="JSON" value="json" />
          </el-select>
        </el-form-item>
        <el-form-item label="分组">
          <el-select v-model="configForm.config_group" style="width: 100%">
            <el-option label="系统配置" value="system" />
            <el-option label="业务配置" value="business" />
            <el-option label="界面配置" value="ui" />
          </el-select>
        </el-form-item>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="生效日期">
              <el-date-picker v-model="configForm.effective_date" type="date" placeholder="选择日期" format="YYYY-MM-DD" value-format="YYYY-MM-DD" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="失效日期">
              <el-date-picker v-model="configForm.expire_date" type="date" placeholder="选择日期" format="YYYY-MM-DD" value-format="YYYY-MM-DD" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="描述">
          <el-input v-model="configForm.description" type="textarea" rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="configDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveConfig">保存</el-button>
      </template>
    </el-dialog>

    <!-- 字典对话框 -->
    <el-dialog v-model="dictDialogVisible" :title="editingDict ? '编辑字典' : '新增字典'" width="400px">
      <el-form :model="dictForm" label-width="80px">
        <el-form-item label="字典类型" required>
          <el-input v-model="dictForm.dict_type" placeholder="如：gender" :disabled="!!editingDict" />
        </el-form-item>
        <el-form-item label="编码" required>
          <el-input v-model="dictForm.dict_code" placeholder="请输入" />
        </el-form-item>
        <el-form-item label="标签" required>
          <el-input v-model="dictForm.dict_label" placeholder="显示文本" />
        </el-form-item>
        <el-form-item label="值" required>
          <el-input v-model="dictForm.dict_value" placeholder="存储值" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="dictForm.sort_order" :min="0" />
        </el-form-item>
        <el-form-item label="默认">
          <el-switch v-model="dictForm.is_default" />
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="dictForm.is_enabled" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dictDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveDict">保存</el-button>
      </template>
    </el-dialog>

    <!-- 员工对话框 -->
    <el-dialog v-model="employeeDialogVisible" :title="editingEmployee ? '编辑员工' : '新增员工'" width="600px">
      <el-form :model="employeeForm" label-width="100px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="工号" required>
              <el-input v-model="employeeForm.emp_no" placeholder="请输入" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="姓名" required>
              <el-input v-model="employeeForm.name" placeholder="请输入" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="性别">
              <el-radio-group v-model="employeeForm.gender">
                <el-radio label="男">男</el-radio>
                <el-radio label="女">女</el-radio>
                <el-radio label="未知">未知</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="出生日期">
              <el-date-picker v-model="employeeForm.birth_date" type="date" placeholder="选择日期" format="YYYY-MM-DD" value-format="YYYY-MM-DD" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="科室">
              <el-select v-model="employeeForm.dept_id" placeholder="请选择" style="width: 100%">
                <el-option v-for="dept in departments" :key="dept.id" :label="dept.name" :value="dept.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="岗位">
              <el-select v-model="employeeForm.emp_type" placeholder="请选择" style="width: 100%">
                <el-option label="医生" value="doctor" />
                <el-option label="护士" value="nurse" />
                <el-option label="技师" value="technician" />
                <el-option label="药师" value="pharmacist" />
                <el-option label="管理员" value="admin" />
                <el-option label="其他" value="other" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="职称">
              <el-input v-model="employeeForm.title" placeholder="请输入" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="联系电话">
              <el-input v-model="employeeForm.phone" placeholder="请输入" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="入职日期">
              <el-date-picker v-model="employeeForm.hire_date" type="date" placeholder="选择日期" format="YYYY-MM-DD" value-format="YYYY-MM-DD" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="状态">
              <el-select v-model="employeeForm.status" style="width: 100%">
                <el-option label="在职" value="active" />
                <el-option label="离职" value="retired" />
                <el-option label="调离" value="transferred" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button @click="employeeDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveEmployee">保存</el-button>
      </template>
    </el-dialog>

    <!-- 科室对话框 -->
    <el-dialog v-model="deptDialogVisible" :title="editingDept ? '编辑科室' : '新增科室'" width="500px">
      <el-form :model="deptForm" label-width="100px">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="科室代码" required>
              <el-input v-model="deptForm.code" placeholder="如：INT" :disabled="!!editingDept" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="科室名称" required>
              <el-input v-model="deptForm.name" placeholder="如：内科" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="科室类型">
              <el-select v-model="deptForm.dept_type" style="width: 100%">
                <el-option label="临床科室" value="clinical" />
                <el-option label="医技科室" value="medical_tech" />
                <el-option label="行政科室" value="admin" />
                <el-option label="后勤科室" value="logistics" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="科室分类">
              <el-input v-model="deptForm.category" placeholder="如：内科系统" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="12">
            <el-form-item label="挂号费">
              <el-input-number v-model="deptForm.reg_fee" :min="0" :step="100" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="排序">
              <el-input-number v-model="deptForm.sort_order" :min="0" style="width: 100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="状态">
          <el-radio-group v-model="deptForm.status">
            <el-radio label="active">启用</el-radio>
            <el-radio label="inactive">停用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="deptDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveDept">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { supabase } from '@/composables/supabase'
import { ElMessage, ElMessageBox } from 'element-plus'

const activeTab = ref('config')

const saving = ref(false)

const configs = ref<any[]>([])
const dicts = ref<any[]>([])
const auditLogs = ref<any[]>([])
const messages = ref<any[]>([])
const employees = ref<any[]>([])
const departments = ref<any[]>([])
const baseDictData = ref<any[]>([])

const filterConfigGroup = ref('')
const filterDictType = ref('')
const filterLogDate = ref('')
const filterActionType = ref('')
const filterMsgType = ref('')
const filterMsgStatus = ref('')
const filterEmpName = ref('')
const filterEmpDept = ref('')
const filterEmpStatus = ref('')
const filterDrugName = ref('')
const filterIcdName = ref('')

const activeBaseDict = ref('drug')

const logPagination = ref({ page: 1, pageSize: 50, total: 0 })
const msgPagination = ref({ page: 1, pageSize: 20, total: 0 })

const configDialogVisible = ref(false)
const editingConfig = ref<any>(null)
const configForm = reactive({
  config_name: '',
  config_key: '',
  config_value: '',
  config_type: 'string',
  config_group: 'system',
  effective_date: '',
  expire_date: '',
  description: ''
})

const dictDialogVisible = ref(false)
const editingDict = ref<any>(null)
const dictForm = reactive({
  dict_type: '',
  dict_code: '',
  dict_label: '',
  dict_value: '',
  sort_order: 0,
  is_default: false,
  is_enabled: true
})

const employeeDialogVisible = ref(false)
const editingEmployee = ref<any>(null)
const employeeForm = reactive({
  emp_no: '',
  name: '',
  gender: '男',
  birth_date: '',
  dept_id: '',
  emp_type: 'doctor',
  title: '',
  professional_title: '',
  phone: '',
  hire_date: '',
  status: 'active'
})

const deptDialogVisible = ref(false)
const editingDept = ref<any>(null)
const deptForm = reactive({
  code: '',
  name: '',
  dept_type: 'clinical',
  category: '',
  reg_fee: 0,
  sort_order: 0,
  status: 'active'
})

async function fetchConfigs() {
  let query = supabase.from('sys_config').select('*').eq('is_deleted', false).order('sort_order')
  if (filterConfigGroup.value) {
    query = query.eq('config_group', filterConfigGroup.value)
  }
  const { data } = await query
  configs.value = data || []
}

async function fetchDicts() {
  let query = supabase.from('sys_dict').select('*').eq('is_deleted', false).eq('is_enabled', true).order('dict_type, sort_order')
  if (filterDictType.value) {
    query = query.eq('dict_type', filterDictType.value)
  }
  const { data } = await query
  dicts.value = data || []
}

async function fetchAuditLogs() {
  let query = supabase
    .from('sys_audit_log')
    .select('*', { count: 'exact' })
    .order('create_time', { ascending: false })
    .range((logPagination.value.page - 1) * logPagination.value.pageSize, logPagination.value.page * logPagination.value.pageSize - 1)

  if (filterLogDate.value) {
    query = query.gte('create_time', filterLogDate.value + 'T00:00:00').lt('create_time', filterLogDate.value + 'T23:59:59')
  }
  if (filterActionType.value) {
    query = query.eq('action_type', filterActionType.value)
  }

  const { data, count } = await query
  auditLogs.value = data || []
  logPagination.value.total = count || 0
}

async function fetchMessages() {
  let query = supabase
    .from('sys_message')
    .select('*', { count: 'exact' })
    .eq('is_deleted', false)
    .order('create_time', { ascending: false })
    .range((msgPagination.value.page - 1) * msgPagination.value.pageSize, msgPagination.value.page * msgPagination.value.pageSize - 1)

  if (filterMsgType.value) {
    query = query.eq('message_type', filterMsgType.value)
  }

  const { data, count } = await query
  messages.value = data || []
  msgPagination.value.total = count || 0
}

async function fetchEmployees() {
  let query = supabase.from('hr_employee').select('*').eq('is_deleted', false).order('emp_no')

  if (filterEmpName.value) {
    query = query.ilike('name', `%${filterEmpName.value}%`)
  }
  if (filterEmpDept.value) {
    query = query.eq('dept_id', filterEmpDept.value)
  }
  if (filterEmpStatus.value) {
    query = query.eq('status', filterEmpStatus.value)
  }

  const { data } = await query
  employees.value = data || []
}

async function fetchDepartments() {
  const { data } = await supabase.from('org_dept').select('*').eq('is_deleted', false).eq('status', 'active').order('sort_order')
  departments.value = data || []
}

async function fetchBaseDictData() {
  if (activeBaseDict.value === 'drug') {
    let query = supabase.from('md_drug').select('*').eq('is_deleted', false).eq('status', 'active').order('common_name')
    if (filterDrugName.value) {
      query = query.ilike('common_name', `%${filterDrugName.value}%`)
    }
    const { data } = await query
    baseDictData.value = data || []
  } else if (activeBaseDict.value === 'icd10') {
    let query = supabase.from('md_icd10').select('*').eq('status', 'active').order('code')
    if (filterIcdName.value) {
      query = query.ilike('name', `%${filterIcdName.value}%`)
    }
    const { data } = await query
    baseDictData.value = data || []
  }
}

function openConfigDialog(config: any) {
  editingConfig.value = config
  if (config) {
    Object.assign(configForm, {
      config_name: config.config_name,
      config_key: config.config_key,
      config_value: config.config_value,
      config_type: config.config_type,
      config_group: config.config_group,
      effective_date: config.effective_date || '',
      expire_date: config.expire_date || '',
      description: config.description || ''
    })
  } else {
    Object.assign(configForm, { config_name: '', config_key: '', config_value: '', config_type: 'string', config_group: 'system', effective_date: '', expire_date: '', description: '' })
  }
  configDialogVisible.value = true
}

async function saveConfig() {
  if (!configForm.config_name || !configForm.config_key) {
    ElMessage.warning('请填写必填项')
    return
  }
  saving.value = true
  try {
    const payload = {
      config_name: configForm.config_name,
      config_key: configForm.config_key,
      config_value: configForm.config_value,
      config_type: configForm.config_type,
      config_group: configForm.config_group,
      effective_date: configForm.effective_date || null,
      expire_date: configForm.expire_date || null,
      description: configForm.description || null
    }
    if (editingConfig.value) {
      const { error } = await supabase.from('sys_config').update(payload).eq('id', editingConfig.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('sys_config').insert(payload)
      if (error) throw error
    }
    ElMessage.success('保存成功')
    configDialogVisible.value = false
    fetchConfigs()
  } catch (error: any) {
    ElMessage.error(error.message || '保存失败')
  } finally {
    saving.value = false
  }
}

async function deleteConfig(config: any) {
  try {
    await ElMessageBox.confirm(`确定删除配置「${config.config_name}」吗？`, '删除确认', { type: 'warning' })
    const { error } = await supabase.from('sys_config').update({ is_deleted: true }).eq('id', config.id)
    if (error) throw error
    ElMessage.success('删除成功')
    fetchConfigs()
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error(e.message || '删除失败')
  }
}

function openDictDialog(dict: any) {
  editingDict.value = dict
  if (dict) {
    Object.assign(dictForm, dict)
  } else {
    Object.assign(dictForm, { dict_type: filterDictType.value || '', dict_code: '', dict_label: '', dict_value: '', sort_order: 0, is_default: false, is_enabled: true })
  }
  dictDialogVisible.value = true
}

async function saveDict() {
  if (!dictForm.dict_type || !dictForm.dict_code || !dictForm.dict_label) {
    ElMessage.warning('请填写必填项')
    return
  }
  saving.value = true
  try {
    const payload = { ...dictForm }
    if (editingDict.value) {
      const { error } = await supabase.from('sys_dict').update(payload).eq('id', editingDict.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('sys_dict').insert(payload)
      if (error) throw error
    }
    ElMessage.success('保存成功')
    dictDialogVisible.value = false
    fetchDicts()
  } catch (error: any) {
    ElMessage.error(error.message || '保存失败')
  } finally {
    saving.value = false
  }
}

async function deleteDict(dict: any) {
  try {
    await ElMessageBox.confirm(`确定删除字典「${dict.dict_label}」吗？`, '删除确认', { type: 'warning' })
    const { error } = await supabase.from('sys_dict').update({ is_deleted: true }).eq('id', dict.id)
    if (error) throw error
    ElMessage.success('删除成功')
    fetchDicts()
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error(e.message || '删除失败')
  }
}

function openEmployeeDialog(emp: any) {
  editingEmployee.value = emp
  if (emp) {
    Object.assign(employeeForm, emp)
  } else {
    Object.assign(employeeForm, { emp_no: '', name: '', gender: '男', birth_date: '', dept_id: '', emp_type: 'doctor', title: '', professional_title: '', phone: '', hire_date: '', status: 'active' })
  }
  employeeDialogVisible.value = true
}

async function saveEmployee() {
  if (!employeeForm.emp_no || !employeeForm.name) {
    ElMessage.warning('请填写工号和姓名')
    return
  }
  saving.value = true
  try {
    const payload = { ...employeeForm }
    if (editingEmployee.value) {
      const { error } = await supabase.from('hr_employee').update(payload).eq('id', editingEmployee.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('hr_employee').insert({ ...payload, org_id: '00000000-0000-0000-0000-000000000001' })
      if (error) throw error
    }
    ElMessage.success('保存成功')
    employeeDialogVisible.value = false
    fetchEmployees()
  } catch (error: any) {
    ElMessage.error(error.message || '保存失败')
  } finally {
    saving.value = false
  }
}

async function deleteEmployee(emp: any) {
  try {
    await ElMessageBox.confirm(`确定删除员工「${emp.name}」吗？`, '删除确认', { type: 'warning' })
    const { error } = await supabase.from('hr_employee').update({ is_deleted: true }).eq('id', emp.id)
    if (error) throw error
    ElMessage.success('删除成功')
    fetchEmployees()
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error(e.message || '删除失败')
  }
}

function openDeptDialog(dept: any) {
  editingDept.value = dept
  if (dept) {
    Object.assign(deptForm, dept)
  } else {
    Object.assign(deptForm, { code: '', name: '', dept_type: 'clinical', category: '', reg_fee: 0, sort_order: 0, status: 'active' })
  }
  deptDialogVisible.value = true
}

async function saveDept() {
  if (!deptForm.code || !deptForm.name) {
    ElMessage.warning('请填写科室代码和名称')
    return
  }
  saving.value = true
  try {
    const payload = { ...deptForm }
    if (editingDept.value) {
      const { error } = await supabase.from('org_dept').update(payload).eq('id', editingDept.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('org_dept').insert({ ...payload, org_id: '00000000-0000-0000-0000-000000000001' })
      if (error) throw error
    }
    ElMessage.success('保存成功')
    deptDialogVisible.value = false
    fetchDepartments()
  } catch (error: any) {
    ElMessage.error(error.message || '保存失败')
  } finally {
    saving.value = false
  }
}

async function deleteDept(dept: any) {
  try {
    await ElMessageBox.confirm(`确定删除科室「${dept.name}」吗？`, '删除确认', { type: 'warning' })
    const { error } = await supabase.from('org_dept').update({ is_deleted: true }).eq('id', dept.id)
    if (error) throw error
    ElMessage.success('删除成功')
    fetchDepartments()
  } catch (e: any) {
    if (e !== 'cancel') ElMessage.error(e.message || '删除失败')
  }
}

function openBaseDictDialog(type: string, _row: any) {
  ElMessage.info(`${type} 编辑功能开发中`)
}

function viewMessage(row: any) {
  if (!row.is_read) {
    supabase.from('sys_message').update({ is_read: true, read_time: new Date().toISOString() }).eq('id', row.id)
    row.is_read = true
  }
}

function resetLogFilter() {
  filterLogDate.value = ''
  filterActionType.value = ''
  fetchAuditLogs()
}

function resetMsgFilter() {
  filterMsgType.value = ''
  filterMsgStatus.value = ''
  fetchMessages()
}

function getDeptName(deptId: string): string {
  const dept = departments.value.find(d => d.id === deptId)
  return dept?.name || '-'
}

function getEmpTypeLabel(type: string): string {
  const map: Record<string, string> = { doctor: '医生', nurse: '护士', technician: '技师', pharmacist: '药师', admin: '管理员', other: '其他' }
  return map[type] || type
}

function getDeptTypeLabel(type: string): string {
  const map: Record<string, string> = { clinical: '临床', medical_tech: '医技', admin: '行政', logistics: '后勤' }
  return map[type] || type
}

function getActionLabel(type: string): string {
  const map: Record<string, string> = { login: '登录', logout: '登出', query: '查询', create: '新增', update: '更新', delete: '删除', execute: '执行' }
  return map[type] || type
}

function getMessageTypeLabel(type: string): string {
  const map: Record<string, string> = { notification: '通知', alert: '告警', task: '任务', reminder: '提醒', approval: '审批', system: '系统' }
  return map[type] || type
}

function getDrugTypeLabel(type: string): string {
  const map: Record<string, string> = { western: '西药', chinese: '中药', biologic: '生物制品', blood: '血液制品', vaccine: '疫苗', contrast: '造影剂' }
  return map[type] || type
}

function getAntibioticLabel(level: string): string {
  const map: Record<string, string> = { non_antibiotic: '非抗生素', non_restricted: '非限制级', restricted: '限制级', special: '特殊级' }
  return map[level] || level
}

function formatDateTime(dateStr: string): string {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleString('zh-CN')
}

onMounted(() => {
  fetchConfigs()
  fetchDicts()
  fetchDepartments()
  fetchEmployees()
})
</script>

<style scoped>
.admin-page {
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

.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}
</style>
