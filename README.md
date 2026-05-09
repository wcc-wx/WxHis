# 文贤HIS - 医院信息系统原型

基于 Vue 3 + Supabase 的医院信息系统（HIS）原型，支持门诊、住院、检验（LIS）、影像（PACS）、电子病历（EMR）等核心模块。

## 技术栈

- **前端**: Vue 3 (Composition API) + Vite + TypeScript + Pinia + Vue Router
- **UI框架**: Element Plus
- **后端/数据库**: Supabase (PostgreSQL + Auth + Storage + RLS)

## 项目结构

```
WXHIS/
├── src/
│   ├── assets/              # 静态资源
│   │   └── main.css         # 全局样式
│   ├── components/
│   │   ├── common/          # 公共组件
│   │   └── layout/          # 布局组件
│   │       └── MainLayout.vue   # 主布局（侧边栏+头部）
│   ├── composables/         # 组合式函数
│   │   └── supabase.ts      # Supabase 客户端
│   ├── router/
│   │   └── index.ts         # 路由配置 + 导航守卫
│   ├── stores/
│   │   └── auth.ts          # 认证状态管理
│   ├── types/
│   │   └── index.ts         # TypeScript 类型定义
│   ├── views/               # 页面组件
│   │   ├── admin/           # 系统设置
│   │   ├── clinic/          # 门诊工作站
│   │   ├── emr/             # 电子病历
│   │   ├── inpatient/       # 住院管理
│   │   ├── lab/             # 检验管理 (LIS)
│   │   ├── login/           # 登录页
│   │   ├── pacs/            # 影像管理 (PACS)
│   │   ├── patients/        # 患者管理
│   │   ├── pharmacy/        # 药房管理
│   │   └── registration/    # 挂号管理
│   ├── App.vue
│   └── main.ts
├── supabase/
│   └── schema.sql           # 数据库建表脚本 + 种子数据
├── .env.example             # 环境变量示例
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 配置 Supabase

1. 在 [Supabase](https://supabase.com) 创建一个新项目
2. 复制 `.env.example` 为 `.env`:
   ```bash
   cp .env.example .env
   ```
3. 填写 `.env` 中的 `VITE_SUPABASE_URL` 和 `VITE_SUPABASE_ANON_KEY`

### 3. 初始化数据库

1. 在 Supabase Dashboard 中打开 **SQL Editor**
2. 复制 `supabase/schema.sql` 的内容并执行
3. 这将创建所有表、索引、触发器、RLS 策略和种子数据

### 4. 创建演示用户

在 Supabase Dashboard 的 **Authentication** 中创建以下用户：

| 邮箱 | 密码 | 角色 |
|------|------|------|
| doctor@his.local | password123 | 医生 |
| nurse@his.local | password123 | 护士 |
| labtech@his.local | password123 | 检验师 |
| radiology@his.local | password123 | 放射技师 |
| pharmacist@his.local | password123 | 药师 |
| admin@his.local | password123 | 管理员 |

创建用户时，设置 metadata:
```json
{
  "real_name": "张医生",
  "role": "doctor",
  "employee_no": "D001"
}
```

### 5. 配置存储桶（用于 PACS 影像上传）

在 Supabase Dashboard 的 **Storage** 中创建两个存储桶：
- `pacs-images` (公开)
- `pacs-reports` (公开)

### 6. 启动开发服务器

```bash
npm run dev
```

访问 http://localhost:3000

## 功能模块

### 已实现

- **患者管理** (`/patients`) - 患者列表、搜索、新建、编辑
- **挂号管理** (`/registration`) - 挂号、待诊列表、叫号
- **门诊工作站** (`/clinic`) - 接诊、病历书写、开医嘱（处方/检验/检查）
- **电子病历** (`/emr`) - 门诊病历查看
- **检验管理** (`/lab`) - LIS 全流程（申请→采样→检验→审核）
- **影像管理** (`/pacs`) - PACS 全流程（申请→登记→检查→上传影像→写报告）
- **药房管理** (`/pharmacy`) - 待发药处方、药品库存
- **住院管理** (`/inpatient`) - 入院登记、在院患者、床位管理
- **系统设置** (`/admin`) - 用户管理、科室管理、字典管理

### 角色权限

| 角色 | 可访问模块 |
|------|-----------|
| admin | 所有模块 |
| doctor | 患者、门诊、EMR、住院 |
| nurse | 患者、挂号、住院 |
| lab_tech | 检验管理 |
| radiology_tech | 影像管理 |
| pharmacist | 药房管理 |

## 数据库表

- `users_profile` - 用户扩展信息
- `departments` - 科室
- `patients` - 患者
- `registrations` - 挂号
- `outpatient_visits` - 门诊就诊
- `prescriptions` / `prescription_items` - 处方
- `drugs` - 药品字典
- `lab_requests` / `lab_results` - 检验申请/结果
- `test_items` - 检验项目字典
- `imaging_requests` / `imaging_studies` - 影像申请/记录
- `beds` - 床位
- `inpatient_encounters` - 住院记录
- `orders` - 通用医嘱

## 后续开发建议

1. **完整测试流程** - 端到端测试各业务流程
2. **增强 EMR** - 结构化病历模板、打印功能
3. **费用管理** - 门诊/住院收费、账单管理
4. **统计报表** - 门诊量统计、收入报表
5. **消息通知** - 检验/影像结果推送
6. **移动端适配** - 响应式布局优化
