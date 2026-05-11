-- ============================================================
-- 文贤HIS数据库建表脚本
-- 遵循医疗信息化行业规范
-- 第三范式为主，高频查询允许适度冗余
-- 支持多院区数据隔离（org_id）
-- 表命名规范：模块前缀_表名
-- 金额字段统一使用分为单位（INTEGER）
-- 标准审计字段：create_time, update_time, create_by, update_by, is_deleted
-- ============================================================

-- 启用 UUID 生成
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 触发器：自动更新 updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.update_time = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 1. 组织机构模块 (org_*)
-- ============================================================

-- 1.1 院区表
CREATE TABLE IF NOT EXISTS public.org_hospital (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE -- 院区代码,
    name TEXT NOT NULL -- 院区名称,
    short_name TEXT -- 简称,
    hospital_level TEXT CHECK (hospital_level IN ('三级甲等','三级乙等','二级甲等','二级乙等','一级','未定级')) -- 医院等级,
    address TEXT -- 地址,
    phone TEXT -- 联系电话,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','suspended')),
    sort_order INTEGER DEFAULT 0,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER org_hospital_updated_at BEFORE UPDATE ON public.org_hospital FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 1.2 科室表
CREATE TABLE IF NOT EXISTS public.org_dept (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001' -- 所属院区,
    parent_id UUID -- 上级科室,
    code TEXT NOT NULL -- 科室代码,
    name TEXT NOT NULL -- 科室名称,
    dept_type TEXT NOT NULL CHECK (dept_type IN ('clinical','medical_tech','admin','logistics')) -- 科室类型,
    category TEXT -- 科室分类,
    dept_level INTEGER DEFAULT 1 -- 科室级别,
    reg_fee INTEGER DEFAULT 0 -- 挂号费（分）,
    status TEXT DEFAULT 'active' CHECK (status IN ('active','inactive')),
    sort_order INTEGER DEFAULT 0,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, code)
);

CREATE TRIGGER org_dept_updated_at BEFORE UPDATE ON public.org_dept FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 1.3 病区表
CREATE TABLE IF NOT EXISTS public.org_ward (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    dept_id UUID NOT NULL -- 所属科室,
    ward_code TEXT NOT NULL,
    ward_name TEXT NOT NULL,
    ward_type TEXT CHECK (ward_type IN ('general','icu','emergency','observation')),
    bed_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, ward_code)
);

CREATE TRIGGER org_ward_updated_at BEFORE UPDATE ON public.org_ward FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 1.4 护理单元表
CREATE TABLE IF NOT EXISTS public.org_nursing_unit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    ward_id UUID NOT NULL,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    nurse_manager_id UUID,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, code)
);

CREATE TRIGGER org_nursing_unit_updated_at BEFORE UPDATE ON public.org_nursing_unit FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


-- ============================================================
-- 2. 人员模块 (hr_*)
-- ============================================================

-- 2.1 员工档案表
CREATE TABLE IF NOT EXISTS public.hr_employee (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    org_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    emp_no TEXT NOT NULL UNIQUE -- 工号,
    name TEXT NOT NULL -- 姓名,
    name_pinyin TEXT -- 姓名拼音,
    gender TEXT CHECK (gender IN ('男','女','未知')) DEFAULT '未知',
    birth_date DATE -- 出生日期,
    id_card TEXT -- 身份证号,
    phone TEXT -- 联系电话,
    email TEXT,
    dept_id UUID -- 所属科室,
    emp_type TEXT CHECK (emp_type IN ('doctor','nurse','technician','pharmacist','admin','other')),
    title TEXT -- 职称,
    professional_title TEXT -- 专业职称,
    status TEXT DEFAULT 'active' CHECK (status IN ('active','inactive','retired','transferred')),
    hire_date DATE -- 入职日期,
    leave_date DATE -- 离职日期,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER hr_employee_updated_at BEFORE UPDATE ON public.hr_employee FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 2.2 医生执业信息
CREATE TABLE IF NOT EXISTS public.hr_doctor_info (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emp_id UUID NOT NULL REFERENCES public.hr_employee(id),
    license_no TEXT -- 执业医师资格证号,
    license_type TEXT -- 执业类别,
    license_scope TEXT -- 执业范围,
    signature_url TEXT -- 电子签名URL,
    signature_data TEXT -- 电子签名Base64,
    is_attending BOOLEAN DEFAULT FALSE -- 是否主治医师,
    is_chief BOOLEAN DEFAULT FALSE -- 是否主任/副主任医师,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER hr_doctor_info_updated_at BEFORE UPDATE ON public.hr_doctor_info FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 2.3 排班表
CREATE TABLE IF NOT EXISTS public.hr_schedule (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    emp_id UUID NOT NULL REFERENCES public.hr_employee(id),
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    schedule_date DATE NOT NULL -- 排班日期,
    shift_type TEXT CHECK (shift_type IN ('morning','afternoon','night','day','on_call')) NOT NULL,
    shift_start TIME NOT NULL,
    shift_end TIME NOT NULL,
    reg_quota INTEGER DEFAULT 0 -- 挂号限额,
    reg_used INTEGER DEFAULT 0 -- 已用号源,
    status TEXT DEFAULT 'active' CHECK (status IN ('active','cancelled','rest')),
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(emp_id, schedule_date, shift_type)
);

CREATE TRIGGER hr_schedule_updated_at BEFORE UPDATE ON public.hr_schedule FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


-- ============================================================
-- 3. 基础字典模块 (md_*)
-- ============================================================

-- 3.1 ICD-10 诊断字典
CREATE TABLE IF NOT EXISTS public.md_icd10 (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL -- ICD-10编码,
    code_ext TEXT -- 扩展码,
    name TEXT NOT NULL -- 诊断名称,
    name_pinyin TEXT -- 拼音码,
    name_english TEXT -- 英文名称,
    disease_type TEXT CHECK (disease_type IN ('disease','syndrome','injury','poisoning','external_cause','neoplasm','symptom')),
    gender_limit TEXT CHECK (gender_limit IN ('male','female','both')) DEFAULT 'both',
    age_limit_min INTEGER -- 最小年龄,
    age_limit_max INTEGER -- 最大年龄,
    is_chronic BOOLEAN DEFAULT FALSE,
    is_infectious BOOLEAN DEFAULT FALSE,
    reportable BOOLEAN DEFAULT FALSE -- 是否需报告,
    version TEXT DEFAULT '2022',
    effective_date DATE,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(code, code_ext, version)
);

CREATE TRIGGER md_icd10_updated_at BEFORE UPDATE ON public.md_icd10 FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.2 ICD-9-CM3 手术操作字典
CREATE TABLE IF NOT EXISTS public.md_icd9cm3 (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL -- 手术编码,
    name TEXT NOT NULL -- 手术名称,
    name_pinyin TEXT -- 拼音码,
    category TEXT -- 手术类别,
    incision_grade TEXT CHECK (incision_grade IN ('I','II','III','IV')) -- 切口等级,
    surgery_level TEXT CHECK (surgery_level IN ('1','2','3','4')) -- 手术级别,
    anesthesia_type TEXT -- 麻醉方式,
    duration_min INTEGER -- 预计时长(分钟),
    version TEXT DEFAULT '2022',
    effective_date DATE,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER md_icd9cm3_updated_at BEFORE UPDATE ON public.md_icd9cm3 FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.3 中医诊断字典
CREATE TABLE IF NOT EXISTS public.md_tcm_diagnosis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL -- 中医病证分类代码,
    name TEXT NOT NULL -- 病证名称,
    name_pinyin TEXT -- 拼音码,
    category TEXT -- 分类,
    etiology TEXT -- 病因,
    pathogenesis TEXT -- 病机,
    syndrome_type TEXT -- 证型,
    version TEXT DEFAULT '2022',
    effective_date DATE,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER md_tcm_diagnosis_updated_at BEFORE UPDATE ON public.md_tcm_diagnosis FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.4 药品字典
CREATE TABLE IF NOT EXISTS public.md_drug (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    drug_code TEXT NOT NULL -- 药品编码,
    national_code TEXT -- 国家医保药品编码,
    common_name TEXT NOT NULL -- 通用名,
    product_name TEXT -- 商品名,
    english_name TEXT -- 英文名,
    pinyin TEXT -- 拼音码,
    drug_type TEXT CHECK (drug_type IN ('western','chinese','biologic','blood','vaccine','contrast')) NOT NULL,
    pharmacol_category TEXT -- 药理分类,
    atc_code TEXT -- ATC分类代码,
    spec TEXT NOT NULL -- 规格,
    unit TEXT NOT NULL -- 单位,
    package_unit TEXT -- 包装单位,
    package_qty INTEGER DEFAULT 1 -- 包装数量,
    price INTEGER NOT NULL DEFAULT 0 -- 单价（分）,
    price_ratio NUMERIC(10,4) -- 差比价系数,
    dosage_form TEXT -- 剂型,
    route TEXT CHECK (route IN ('口服','静脉注射','肌肉注射','皮下注射','皮内注射','外用','吸入','直肠','其他')),
    frequency_code TEXT -- 频次代码,
    unit_dose INTEGER DEFAULT 1 -- 每次剂量,
    unit_dose_unit TEXT -- 剂量单位,
    antibiotic_level TEXT CHECK (antibiotic_level IN ('non_antibiotic','non_restricted','restricted','special')) DEFAULT 'non_antibiotic',
    controlled_drug_level TEXT CHECK (controlled_drug_level IN ('none','psychotropic','narcotic','radioactive')) DEFAULT 'none',
    anti_infective BOOLEAN DEFAULT FALSE -- 是否抗菌药物,
    immune_modulator BOOLEAN DEFAULT FALSE -- 是否免疫调节剂,
    storage_temp TEXT -- 储存温度,
    shelf_life_months INTEGER -- 有效期（月）,
    min_stock INTEGER DEFAULT 0,
    max_stock INTEGER DEFAULT 0,
    default_supplier TEXT -- 默认供应商,
    is_bacteriostatic BOOLEAN DEFAULT FALSE,
    is_essential BOOLEAN DEFAULT FALSE -- 是否基药,
    medical_insurance BOOLEAN DEFAULT TRUE,
    reimbursement_category TEXT -- 医保报销类别,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, drug_code)
);

CREATE TRIGGER md_drug_updated_at BEFORE UPDATE ON public.md_drug FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.5 收费项目字典
CREATE TABLE IF NOT EXISTS public.md_charge_item (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    item_code TEXT NOT NULL,
    national_code TEXT -- 国家医保诊疗项目编码,
    name TEXT NOT NULL,
    pinyin TEXT,
    item_type TEXT CHECK (item_type IN ('service','material','drug','exam','procedure','bed','nursing')) NOT NULL,
    category TEXT,
    spec TEXT,
    unit TEXT NOT NULL,
    price INTEGER NOT NULL DEFAULT 0 -- 单价（分）,
    consumable_type TEXT CHECK (consumable_type IN ('disposable','reusable','implant','high_value')),
    is_billable BOOLEAN DEFAULT TRUE,
    medical_insurance BOOLEAN DEFAULT TRUE,
    reimbursement_ratio NUMERIC(5,4) -- 医保报销比例,
    default_dept_id UUID -- 执行科室,
    execution_unit TEXT -- 执行单位,
    parent_item_id UUID,
    sort_order INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, item_code)
);

CREATE TRIGGER md_charge_item_updated_at BEFORE UPDATE ON public.md_charge_item FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.6 检验项目字典
CREATE TABLE IF NOT EXISTS public.md_lis_item (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    item_code TEXT NOT NULL,
    name TEXT NOT NULL,
    pinyin TEXT,
    category TEXT -- 血液/体液/生化/免疫/微生物...,
    specimen_type TEXT -- 标本类型,
    specimen_container TEXT -- 采集容器,
    specimen_volume TEXT -- 标本量,
    collection_instruction TEXT -- 采集说明,
    storage_condition TEXT -- 保存条件,
    turnaround_hours NUMERIC(6,2) -- TAT时间（小时）,
    method TEXT -- 检测方法,
    instrument TEXT -- 检测仪器,
    reference_range_low NUMERIC(12,4),
    reference_range_high NUMERIC(12,4),
    reference_range_text TEXT,
    unit TEXT,
    result_type TEXT CHECK (result_type IN ('numeric','text','select','formula')) DEFAULT 'text',
    result_options JSONB -- 结果选项,
    is_abnormal_alert BOOLEAN DEFAULT FALSE,
    critical_value_low TEXT -- 危急值下限,
    critical_value_high TEXT -- 危急值上限,
    price INTEGER DEFAULT 0 -- 价格（分）,
    medical_insurance BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, item_code)
);

CREATE TRIGGER md_lis_item_updated_at BEFORE UPDATE ON public.md_lis_item FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.7 影像检查项目字典
CREATE TABLE IF NOT EXISTS public.md_ris_item (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    item_code TEXT NOT NULL,
    name TEXT NOT NULL,
    pinyin TEXT,
    category TEXT -- X线/CT/MRI/超声/核医学...,
    exam_body_part TEXT -- 检查部位,
    exam_method TEXT -- 检查方法,
    preparation_instruction TEXT -- 检查前准备,
    duration_minutes INTEGER -- 预计时长,
    has_contrast BOOLEAN DEFAULT FALSE -- 是否需造影剂,
    contrast_agent TEXT -- 造影剂,
    report_template TEXT -- 报告模板,
    image_count INTEGER -- 图像数量,
    has_dicom BOOLEAN DEFAULT TRUE -- 是否生成DICOM,
    price INTEGER DEFAULT 0,
    medical_insurance BOOLEAN DEFAULT TRUE,
    dept_id UUID -- 执行科室,
    sort_order INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, item_code)
);

CREATE TRIGGER md_ris_item_updated_at BEFORE UPDATE ON public.md_ris_item FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.8 医嘱项目字典
CREATE TABLE IF NOT EXISTS public.md_order_item (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    item_code TEXT NOT NULL,
    name TEXT NOT NULL,
    pinyin TEXT,
    order_type TEXT CHECK (order_type IN ('drug','lab','exam','procedure','operation','nursing','diet','bed','other')) NOT NULL,
    category TEXT,
    spec TEXT,
    unit TEXT,
    default_dosage TEXT,
    default_usage TEXT,
    default_frequency TEXT,
    default_duration INTEGER -- 默认疗程（天）,
    route TEXT,
    price INTEGER DEFAULT 0,
    is_antibiotic BOOLEAN DEFAULT FALSE,
    antibiotic_level TEXT,
    controlled_drug_level TEXT,
    requires_audit BOOLEAN DEFAULT FALSE -- 是否需审核,
    requires_informed_consent BOOLEAN DEFAULT FALSE,
    max_single_dose INTEGER,
    min_interval_hours INTEGER,
    incompatible_items JSONB -- 配伍禁忌项目列表,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, item_code)
);

CREATE TRIGGER md_order_item_updated_at BEFORE UPDATE ON public.md_order_item FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.9 频次字典
CREATE TABLE IF NOT EXISTS public.md_frequency (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    times_per_day INTEGER -- 每日次数,
    interval_hours INTEGER -- 间隔小时数,
    time_points JSONB -- 具体时间点,
    instruction TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER md_frequency_updated_at BEFORE UPDATE ON public.md_frequency FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.10 用法字典
CREATE TABLE IF NOT EXISTS public.md_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    category TEXT,
    instruction TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER md_usage_updated_at BEFORE UPDATE ON public.md_usage FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.11 剂量单位字典
CREATE TABLE IF NOT EXISTS public.md_dose_unit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    unit_type TEXT CHECK (unit_type IN ('weight','volume','length','count','other')),
    conversion_factor NUMERIC(12,4) -- 转换为基本单位的系数,
    base_unit TEXT -- 基本单位,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER md_dose_unit_updated_at BEFORE UPDATE ON public.md_dose_unit FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.12 物资字典
CREATE TABLE IF NOT EXISTS public.md_material (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    material_code TEXT NOT NULL,
    national_code TEXT -- 国家医保耗材编码,
    name TEXT NOT NULL,
    pinyin TEXT,
    category TEXT CHECK (category IN ('disposable','implant','reusable','consumable','high_value')),
    spec TEXT -- 规格型号,
    unit TEXT NOT NULL,
    price INTEGER DEFAULT 0,
    is_billable BOOLEAN DEFAULT TRUE,
    medical_insurance BOOLEAN DEFAULT TRUE,
    is_high_value BOOLEAN DEFAULT FALSE -- 是否高值耗材,
    is_implant BOOLEAN DEFAULT FALSE -- 是否植入物,
    traceability_required BOOLEAN DEFAULT FALSE -- 是否需追溯,
    manufacturer TEXT -- 生产厂家,
    supplier TEXT -- 供应商,
    min_stock INTEGER DEFAULT 0,
    max_stock INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, material_code)
);

CREATE TRIGGER md_material_updated_at BEFORE UPDATE ON public.md_material FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 4. 患者管理模块 (pat_*)
-- ============================================================

-- 4.1 患者主索引 (EMPI)
CREATE TABLE IF NOT EXISTS public.pat_master (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_index_no TEXT NOT NULL -- 患者ID号（主索引号）,
    name TEXT NOT NULL -- 姓名,
    name_pinyin TEXT -- 姓名拼音,
    gender TEXT CHECK (gender IN ('男','女','未知')) NOT NULL DEFAULT '未知',
    birth_date DATE NOT NULL -- 出生日期,
    age INTEGER -- 年龄,
    age_unit TEXT CHECK (age_unit IN ('岁','月','天')) DEFAULT '岁',
    id_card TEXT -- 身份证号,
    id_card_type TEXT CHECK (id_card_type IN ('id_card','passport','military','other')) DEFAULT 'id_card',
    birth_place TEXT -- 出生地,
    nationality TEXT DEFAULT '中国',
    ethnicity TEXT -- 民族,
    marital_status TEXT CHECK (marital_status IN ('未婚','已婚','丧偶','离婚','未知')) DEFAULT '未知',
    education TEXT CHECK (education IN ('文盲','小学','初中','高中','中专','大专','本科','硕士','博士','未知')),
    occupation TEXT -- 职业,
    phone TEXT -- 联系电话,
    phone_emergency TEXT -- 紧急联系电话,
    email TEXT,
    address TEXT -- 现住址,
    address_registered TEXT -- 户籍地址,
    household_register TEXT -- 户口性质,
    insurance_type TEXT CHECK (insurance_type IN ('职工医保','居民医保','新农合','商业保险','自费','其他')) DEFAULT '自费',
    insurance_no TEXT -- 医保卡号,
    insurance_org TEXT -- 医保经办机构,
    emergency_contact_name TEXT -- 紧急联系人,
    emergency_contact_relation TEXT -- 关系,
    emergency_contact_phone TEXT -- 紧急联系人电话,
    vip_level INTEGER DEFAULT 0 -- VIP等级,
    risk_level TEXT CHECK (risk_level IN ('low','medium','high')) DEFAULT 'low',
    photo_url TEXT -- 照片URL,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, pat_index_no)
);

CREATE TRIGGER pat_master_updated_at BEFORE UPDATE ON public.pat_master FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4.2 患者就诊卡
CREATE TABLE IF NOT EXISTS public.pat_card (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    card_type TEXT CHECK (card_type IN ('health_card','medical_card','social_security','electronic','other')) NOT NULL,
    card_no TEXT NOT NULL,
    binding_time TIMESTAMPTZ DEFAULT NOW(),
    is_primary BOOLEAN DEFAULT FALSE -- 是否主卡,
    is_active BOOLEAN DEFAULT TRUE,
    issue_org TEXT -- 发卡机构,
    expire_date DATE -- 有效期,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(pat_id, card_type, card_no)
);

CREATE TRIGGER pat_card_updated_at BEFORE UPDATE ON public.pat_card FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4.3 患者过敏史
CREATE TABLE IF NOT EXISTS public.pat_allergy (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    allergen_type TEXT CHECK (allergen_type IN ('drug','food','environmental','other')) NOT NULL,
    allergen_name TEXT NOT NULL,
    allergen_code TEXT -- 过敏原编码,
    reaction TEXT -- 过敏反应,
    reaction_level TEXT CHECK (reaction_level IN ('mild','moderate','severe','anaphylactic')),
    onset_date DATE -- 发现日期,
    source TEXT CHECK (source IN ('patient_report','medical_record','test')) DEFAULT 'patient_report',
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER pat_allergy_updated_at BEFORE UPDATE ON public.pat_allergy FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4.4 患者既往病史
CREATE TABLE IF NOT EXISTS public.pat_medical_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    disease_name TEXT NOT NULL,
    disease_code TEXT -- ICD编码,
    diagnosis_date DATE -- 诊断日期,
    hospital TEXT -- 就诊医院,
    treatment TEXT -- 治疗情况,
    outcome TEXT -- 结局,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER pat_medical_history_updated_at BEFORE UPDATE ON public.pat_medical_history FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4.5 患者联系人
CREATE TABLE IF NOT EXISTS public.pat_contact (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    name TEXT NOT NULL,
    relation TEXT NOT NULL -- 与患者关系,
    phone TEXT NOT NULL,
    address TEXT,
    is_emergency BOOLEAN DEFAULT FALSE -- 是否紧急联系人,
    is_primary BOOLEAN DEFAULT FALSE,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER pat_contact_updated_at BEFORE UPDATE ON public.pat_contact FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 5. 门诊流程模块 (op_*)
-- ============================================================

-- 5.1 门诊号源池
CREATE TABLE IF NOT EXISTS public.op_reg_source (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    doctor_id UUID REFERENCES public.hr_employee(id),
    schedule_date DATE NOT NULL,
    shift_type TEXT CHECK (shift_type IN ('morning','afternoon','night','day','all')) NOT NULL,
    time_slot_start TIME NOT NULL,
    time_slot_end TIME NOT NULL,
    total_quota INTEGER NOT NULL DEFAULT 0,
    used_quota INTEGER DEFAULT 0,
    remain_quota INTEGER DEFAULT 0,
    reg_fee INTEGER DEFAULT 0 -- 挂号费（分）,
    service_fee INTEGER DEFAULT 0 -- 诊疗费（分）,
    status TEXT DEFAULT 'available' CHECK (status IN ('available','full','suspended','finished')),
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, dept_id, doctor_id, schedule_date, shift_type, time_slot_start)
);

CREATE TRIGGER op_reg_source_updated_at BEFORE UPDATE ON public.op_reg_source FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5.2 门诊挂号记录
CREATE TABLE IF NOT EXISTS public.op_registration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL -- 就诊流水号,
    reg_no TEXT NOT NULL -- 挂号单号,
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    doctor_id UUID REFERENCES public.hr_employee(id),
    reg_source_id UUID REFERENCES public.op_reg_source(id),
    visit_date DATE NOT NULL,
    visit_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    shift_type TEXT,
    sequence_no INTEGER NOT NULL -- 顺序号,
    visit_type TEXT CHECK (visit_type IN ('first','return')) NOT NULL DEFAULT 'first',
    clinic_type TEXT CHECK (clinic_type IN ('general','special','expert','emergency','fast')),
    complaint TEXT -- 主诉,
    reg_fee INTEGER NOT NULL DEFAULT 0 -- 挂号费（分）,
    service_fee INTEGER DEFAULT 0,
    total_fee INTEGER DEFAULT 0,
    payment_method TEXT CHECK (payment_method IN ('cash','card','wechat','alipay','insurance','mixed')) DEFAULT 'cash',
    payment_status TEXT CHECK (payment_status IN ('unpaid','paid','refunded','partial_refund')) DEFAULT 'unpaid',
    payment_time TIMESTAMPTZ,
    insurance_adjustment INTEGER DEFAULT 0 -- 医保调整金额（分）,
    discount_amount INTEGER DEFAULT 0,
    status TEXT DEFAULT 'registered' CHECK (status IN ('registered','checked_in','in_progress','finished','cancelled','no_show')),
    check_in_time TIMESTAMPTZ,
    check_in_method TEXT,
    cancel_time TIMESTAMPTZ,
    cancel_reason TEXT,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, visit_sn)
);

CREATE TRIGGER op_registration_updated_at BEFORE UPDATE ON public.op_registration FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5.3 门诊分诊记录
CREATE TABLE IF NOT EXISTS public.op_triage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    reg_id UUID NOT NULL REFERENCES public.op_registration(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    doctor_id UUID REFERENCES public.hr_employee(id),
    queue_no INTEGER -- 排队号,
    triage_time TIMESTAMPTZ DEFAULT NOW(),
    triage_nurse_id UUID REFERENCES public.hr_employee(id),
    vital_signs JSONB -- 生命体征,
    pain_level INTEGER -- 疼痛等级 0-10,
    urgency_level TEXT CHECK (urgency_level IN ('1','2','3','4')) DEFAULT '3',
    waiting_time_minutes INTEGER,
    call_status TEXT CHECK (call_status IN ('waiting','called','arrived','skipped')) DEFAULT 'waiting',
    call_time TIMESTAMPTZ,
    arrival_time TIMESTAMPTZ,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER op_triage_updated_at BEFORE UPDATE ON public.op_triage FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5.4 门诊就诊记录
CREATE TABLE IF NOT EXISTS public.op_visit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    reg_id UUID REFERENCES public.op_registration(id),
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    doctor_id UUID REFERENCES public.hr_employee(id),
    visit_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    chief_complaint TEXT -- 主诉,
    present_illness TEXT -- 现病史,
    past_history TEXT -- 既往史,
    personal_history TEXT -- 个人史,
    family_history TEXT -- 家族史,
    physical_exam TEXT -- 体格检查,
    primary_diagnosis JSONB -- 主诊断,
    secondary_diagnosis JSONB -- 次诊断,
    tcm_diagnosis JSONB -- 中医诊断,
    visit_type TEXT CHECK (visit_type IN ('first','return')) DEFAULT 'first',
    illness_severity TEXT CHECK (illness_severity IN ('mild','moderate','severe','critical')) DEFAULT 'moderate',
    treatment_plan TEXT -- 治疗方案,
    notes TEXT,
    next_visit_advice TEXT -- 复诊建议,
    structured_data JSONB -- 结构化病历数据,
    emr_content XML -- 电子病历XML内容,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER op_visit_updated_at BEFORE UPDATE ON public.op_visit FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5.5 门诊诊断记录
CREATE TABLE IF NOT EXISTS public.op_diagnosis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    visit_id UUID NOT NULL REFERENCES public.op_visit(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    diagnosis_type TEXT CHECK (diagnosis_type IN ('primary','secondary','tcm','supplementary')) NOT NULL,
    diagnosis_no INTEGER DEFAULT 1,
    icd_code TEXT -- ICD编码,
    icd_name TEXT -- ICD名称,
    tcm_code TEXT -- 中医证型编码,
    tcm_name TEXT -- 中医证型名称,
    diagnosis_name TEXT NOT NULL -- 诊断名称（原始描述）,
    diagnosis_status TEXT CHECK (diagnosis_status IN ('suspected','confirmed','ruled_out')) DEFAULT 'confirmed',
    diagnosis_doctor_id UUID REFERENCES public.hr_employee(id),
    diagnosis_time TIMESTAMPTZ DEFAULT NOW(),
    is_main BOOLEAN DEFAULT FALSE -- 是否主诊断,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER op_diagnosis_updated_at BEFORE UPDATE ON public.op_diagnosis FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5.6 门诊电子处方
CREATE TABLE IF NOT EXISTS public.op_prescription (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    visit_id UUID REFERENCES public.op_visit(id),
    prescription_no TEXT NOT NULL -- 处方号,
    prescription_type TEXT CHECK (prescription_type IN ('western','chinese','mixed','tcm')) DEFAULT 'western',
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    doctor_id UUID NOT NULL REFERENCES public.hr_employee(id),
    diagnosis JSONB -- 诊断信息,
    tcm_syndrome TEXT -- 中医证型（辨证论治）,
    tcm_therapy TEXT -- 中医治法,
    total_amount INTEGER DEFAULT 0 -- 处方总金额（分）,
    dispensation_status TEXT CHECK (dispensation_status IN ('undispensed','partial','dispensed','returned','cancelled')) DEFAULT 'undispensed',
    dispensation_time TIMESTAMPTZ,
    dispensation_dept_id UUID,
    dispensation_pharmacist_id UUID REFERENCES public.hr_employee(id),
    audit_status TEXT CHECK (audit_status IN ('pending','passed','rejected','modified')) DEFAULT 'pending',
    audit_time TIMESTAMPTZ,
    audit_pharmacist_id UUID,
    audit_remarks TEXT,
    return_amount INTEGER DEFAULT 0,
    return_time TIMESTAMPTZ,
    requires_pivas BOOLEAN DEFAULT FALSE,
    pivas_batch_no TEXT,
    notes TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, prescription_no)
);

CREATE TRIGGER op_prescription_updated_at BEFORE UPDATE ON public.op_prescription FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5.7 处方明细
CREATE TABLE IF NOT EXISTS public.op_prescription_item (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prescription_id UUID NOT NULL REFERENCES public.op_prescription(id) ON DELETE CASCADE,
    item_no INTEGER NOT NULL,
    drug_id UUID REFERENCES public.md_drug(id),
    drug_name TEXT NOT NULL,
    drug_spec TEXT,
    drug_code TEXT,
    unit TEXT,
    dosage INTEGER NOT NULL -- 剂量（分）,
    dosage_unit TEXT,
    usage TEXT NOT NULL -- 用法,
    frequency TEXT NOT NULL -- 频次,
    route TEXT -- 给药途径,
    duration INTEGER -- 疗程（天）,
    quantity INTEGER -- 数量,
    quantity_unit TEXT,
    price INTEGER DEFAULT 0,
    amount INTEGER DEFAULT 0 -- 金额（分）,
    preparation_instruction TEXT -- 调配说明,
    usage_instruction TEXT -- 用药指导,
    is_skin_test BOOLEAN DEFAULT FALSE -- 是否皮试,
    skin_test_result TEXT CHECK (skin_test_result IN ('positive','negative','not_done')),
    is_urgent BOOLEAN DEFAULT FALSE,
    drug_group TEXT -- 药品组号,
    incompatible_warning JSONB -- 配伍禁忌警告,
    audit_result TEXT CHECK (audit_result IN ('passed','rejected','modified')) DEFAULT 'passed',
    audit_remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER op_prescription_item_updated_at BEFORE UPDATE ON public.op_prescription_item FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5.8 门诊费用明细
CREATE TABLE IF NOT EXISTS public.op_charge (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    visit_id UUID REFERENCES public.op_visit(id),
    prescription_id UUID,
    charge_no TEXT NOT NULL -- 收费单号,
    item_id UUID,
    item_code TEXT,
    item_name TEXT NOT NULL,
    item_type TEXT CHECK (item_type IN ('drug','exam','procedure','service','material','bed','nursing','other')) NOT NULL,
    spec TEXT,
    unit TEXT,
    quantity INTEGER NOT NULL DEFAULT 1,
    price INTEGER NOT NULL DEFAULT 0 -- 单价（分）,
    amount INTEGER NOT NULL DEFAULT 0,
    discount_ratio NUMERIC(5,4) DEFAULT 1,
    discount_amount INTEGER DEFAULT 0,
    actual_amount INTEGER NOT NULL DEFAULT 0,
    insurance_amount INTEGER DEFAULT 0,
    self_payment_amount INTEGER DEFAULT 0,
    payment_method TEXT,
    charge_time TIMESTAMPTZ DEFAULT NOW(),
    charge_status TEXT CHECK (charge_status IN ('pending','charged','refunded','cancelled')) DEFAULT 'charged',
    refund_time TIMESTAMPTZ,
    refund_reason TEXT,
    refund_by UUID,
    exec_dept_id UUID -- 执行科室,
    exec_status TEXT CHECK (exec_status IN ('pending','executed','cancelled')) DEFAULT 'pending',
    exec_time TIMESTAMPTZ,
    executor_id UUID,
    invoice_no TEXT -- 发票号,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, charge_no)
);

CREATE TRIGGER op_charge_updated_at BEFORE UPDATE ON public.op_charge FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5.9 门诊会诊记录
CREATE TABLE IF NOT EXISTS public.op_consultation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    visit_id UUID REFERENCES public.op_visit(id),
    consultation_no TEXT NOT NULL -- 会诊单号,
    consultation_type TEXT CHECK (consultation_type IN ('department','special','multi','remote','emergency')) NOT NULL,
    apply_dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    apply_doctor_id UUID NOT NULL REFERENCES public.hr_employee(id),
    target_dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    target_doctor_id UUID REFERENCES public.hr_employee(id),
    diagnosis JSONB -- 诊断信息,
    chief_complaint TEXT -- 会诊目的/主要症状,
    consultation_detail TEXT -- 会诊意见,
    apply_time TIMESTAMPTZ DEFAULT NOW(),
    scheduled_time TIMESTAMPTZ -- 计划会诊时间,
    consultation_time TIMESTAMPTZ -- 实际会诊时间,
    status TEXT CHECK (status IN ('pending','scheduled','completed','cancelled','rejected')) DEFAULT 'pending',
    urgency_level TEXT CHECK (urgency_level IN ('normal','urgent','stat')) DEFAULT 'normal',
    response_time TIMESTAMPTZ -- 响应时间,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, consultation_no)
);

CREATE TRIGGER op_consultation_updated_at BEFORE UPDATE ON public.op_consultation FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5.10 处方流转记录表
CREATE TABLE IF NOT EXISTS public.op_prescription_flow (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    prescription_id UUID NOT NULL REFERENCES public.op_prescription(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    flow_no INTEGER NOT NULL -- 流转步骤序号,
    flow_type TEXT CHECK (flow_type IN ('create','submit','audit','pass','reject','modify','dispense','send','receive','administer','complete','cancel')) NOT NULL -- 流转类型,
    flow_status TEXT CHECK (flow_status IN ('pending','processing','completed','failed','cancelled')) NOT NULL DEFAULT 'pending',
    from_dept_id UUID REFERENCES public.org_dept(id) -- 来源科室,
    to_dept_id UUID REFERENCES public.org_dept(id) -- 目标科室,
    from_role TEXT -- 来源角色,
    to_role TEXT -- 目标角色,
    operator_id UUID REFERENCES public.hr_employee(id) -- 操作人,
    operator_name TEXT -- 操作人姓名,
    operate_time TIMESTAMPTZ DEFAULT NOW() -- 操作时间,
    remarks TEXT -- 备注说明,
    result_data JSONB -- 结果数据,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER op_prescription_flow_updated_at BEFORE UPDATE ON public.op_prescription_flow FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 6. 住院流程模块 (ip_*)
-- ============================================================

-- 6.1 住院床位
CREATE TABLE IF NOT EXISTS public.ip_bed (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    ward_id UUID NOT NULL REFERENCES public.org_ward(id),
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    bed_no TEXT NOT NULL -- 床位号,
    bed_type TEXT CHECK (bed_type IN ('normal','special','icu','observation','emergency')) DEFAULT 'normal',
    bed_level TEXT CHECK (bed_level IN ('1','2','3')) DEFAULT '2',
    price INTEGER DEFAULT 0 -- 床位费（分/天）,
    status TEXT CHECK (status IN ('available','occupied','reserved','maintenance','cleaning')) DEFAULT 'available',
    features JSONB -- 床位特性,
    sort_order INTEGER DEFAULT 0,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, ward_id, bed_no)
);

CREATE TRIGGER ip_bed_updated_at BEFORE UPDATE ON public.ip_bed FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.2 住院登记
CREATE TABLE IF NOT EXISTS public.ip_admission (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL -- 就诊流水号,
    admission_no TEXT NOT NULL -- 住院号,
    dept_id UUID NOT NULL REFERENCES public.org_dept(id) -- 入院科室,
    ward_id UUID REFERENCES public.org_ward(id) -- 入院病区,
    bed_id UUID REFERENCES public.ip_bed(id),
    admission_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    admission_type TEXT CHECK (admission_type IN ('emergency','elective','transfer')) NOT NULL,
    admission_way TEXT CHECK (admission_way IN ('outpatient','emergency','transfer','other')) DEFAULT 'outpatient',
    referring_dept_id UUID -- 转诊科室,
    referring_doctor_id UUID -- 转诊医生,
    admission_diagnosis JSONB -- 入院诊断,
    admission_condition TEXT CHECK (admission_condition IN ('stable','unstable','critical')) DEFAULT 'stable',
    emergency_level TEXT CHECK (emergency_level IN ('1','2','3','4')),
    expected_days INTEGER -- 预计住院天数,
    deposit_amount INTEGER DEFAULT 0 -- 预交金额（分）,
    deposit_balance INTEGER DEFAULT 0 -- 押金余额（分）,
    insurance_status TEXT CHECK (insurance_status IN ('unregistered','registered','uploaded','settled')) DEFAULT 'unregistered',
    insurance_reg_time TIMESTAMPTZ,
    nursing_level TEXT CHECK (nursing_level IN ('1','2','3','special')) DEFAULT '2',
    diet_type TEXT -- 饮食类型,
    isolation_type TEXT CHECK (isolation_type IN ('none','respiratory','contact','droplet','aerosol','protective')) DEFAULT 'none',
    is_informed_consent BOOLEAN DEFAULT FALSE,
    is_advance_directive BOOLEAN DEFAULT FALSE,
    remarks TEXT,
    status TEXT DEFAULT 'admitted' CHECK (status IN ('admitted','in_hospital','transferred','discharged','deceased')),
    discharge_time TIMESTAMPTZ,
    discharge_type TEXT CHECK (discharge_type IN ('cured','improved','not_improved','transferred','deceased','other')),
    total_expense INTEGER DEFAULT 0,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, admission_no)
);

CREATE TRIGGER ip_admission_updated_at BEFORE UPDATE ON public.ip_admission FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.3 住院诊断
CREATE TABLE IF NOT EXISTS public.ip_diagnosis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    diagnosis_type TEXT CHECK (diagnosis_type IN ('admission','chief','secondary','complication','death','other')) NOT NULL,
    diagnosis_no INTEGER DEFAULT 1,
    icd_code TEXT,
    icd_name TEXT,
    diagnosis_name TEXT NOT NULL,
    diagnosis_status TEXT CHECK (diagnosis_status IN ('suspected','confirmed','ruled_out')) DEFAULT 'confirmed',
    is_main BOOLEAN DEFAULT FALSE,
    doctor_id UUID REFERENCES public.hr_employee(id),
    diagnosis_time TIMESTAMPTZ DEFAULT NOW(),
    is_first_diagnosis BOOLEAN DEFAULT FALSE,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER ip_diagnosis_updated_at BEFORE UPDATE ON public.ip_diagnosis FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.4 住院长期医嘱
CREATE TABLE IF NOT EXISTS public.ip_long_order (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    order_no TEXT NOT NULL -- 医嘱编号,
    order_type TEXT CHECK (order_type IN ('drug','lab','exam','procedure','nursing','diet','bed','other')) NOT NULL,
    order_sub_type TEXT,
    item_id UUID,
    item_name TEXT NOT NULL,
    item_spec TEXT,
    dosage INTEGER,
    dosage_unit TEXT,
    route TEXT,
    frequency TEXT,
    duration_days INTEGER -- 持续天数,
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    stop_time TIMESTAMPTZ,
    stop_reason TEXT,
    stop_by UUID,
    order_status TEXT CHECK (order_status IN ('pending','verified','ongoing','paused','stopped','cancelled','completed')) NOT NULL DEFAULT 'pending',
    order_action TEXT CHECK (order_action IN ('start','pause','resume','stop','cancel','reorder')) NOT NULL DEFAULT 'start',
    audit_status TEXT CHECK (audit_status IN ('pending','passed','rejected')) DEFAULT 'pending',
    audit_time TIMESTAMPTZ,
    audit_by UUID,
    audit_remarks TEXT,
    infusion_volume INTEGER -- 输液量（ml）,
    infusion_rate INTEGER -- 输液速度,
    self_pay_ratio INTEGER -- 自付比例(%),
    dc_reorder_flag TEXT -- 重整标记,
    dc_reorder_no TEXT -- 重整后新医嘱号,
    order_group TEXT -- 医嘱组号,
    urgent_level TEXT CHECK (urgent_level IN ('normal','urgent','stat')) DEFAULT 'normal',
    instructions TEXT -- 嘱托,
    nursing_instructions TEXT -- 护理要求,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID NOT NULL,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, order_no)
);

CREATE TRIGGER ip_long_order_updated_at BEFORE UPDATE ON public.ip_long_order FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.5 住院临时医嘱
CREATE TABLE IF NOT EXISTS public.ip_temp_order (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    order_no TEXT NOT NULL,
    order_type TEXT NOT NULL,
    item_id UUID,
    item_name TEXT NOT NULL,
    item_spec TEXT,
    dosage INTEGER,
    dosage_unit TEXT,
    route TEXT,
    frequency TEXT,
    quantity INTEGER -- 数量,
    unit TEXT,
    price INTEGER DEFAULT 0,
    amount INTEGER DEFAULT 0,
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    execute_time TIMESTAMPTZ,
    execute_by UUID,
    order_status TEXT CHECK (order_status IN ('pending','executed','cancelled')) DEFAULT 'pending',
    cancel_time TIMESTAMPTZ,
    cancel_reason TEXT,
    cancel_by UUID,
    urgent_level TEXT DEFAULT 'normal',
    is_immediate BOOLEAN DEFAULT FALSE,
    requires_consent BOOLEAN DEFAULT FALSE,
    consent_url TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID NOT NULL,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, order_no)
);

CREATE TRIGGER ip_temp_order_updated_at BEFORE UPDATE ON public.ip_temp_order FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.6 医嘱审核记录
CREATE TABLE IF NOT EXISTS public.op_order_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    order_id UUID NOT NULL,
    order_type TEXT NOT NULL CHECK (order_type IN ('long','temp','op_prescription')),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    doctor_id UUID NOT NULL REFERENCES public.hr_employee(id),
    audit_type TEXT CHECK (audit_type IN ('rational_drug','interaction','allergy','dosage','method','other')) NOT NULL,
    audit_result TEXT CHECK (audit_result IN ('passed','warning','rejected','modified')) NOT NULL,
    warning_level TEXT CHECK (warning_level IN ('info','warn','error','critical')),
    alert_message TEXT -- 警告信息,
    alert_details JSONB -- 详细警告内容,
    cdss_response JSONB -- CDSS系统返回,
    auditor_id UUID REFERENCES public.hr_employee(id),
    audit_time TIMESTAMPTZ DEFAULT NOW(),
    action_taken TEXT CHECK (action_taken IN ('accept','modify','cancel','override')),
    override_reason TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER op_order_audit_updated_at BEFORE UPDATE ON public.op_order_audit FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.7 医嘱执行闭环
CREATE TABLE IF NOT EXISTS public.op_order_execution (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    order_id UUID NOT NULL,
    order_type TEXT NOT NULL CHECK (order_type IN ('long','temp','op_prescription','op_prescription_item')),
    prescription_item_id UUID,
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT,
    admission_id UUID,
    exec_no TEXT NOT NULL -- 执行编号,
    exec_type TEXT CHECK (exec_type IN ('dispense','administer','collect','inspect','monitor','other')) NOT NULL -- 执行类型,
    exec_action TEXT CHECK (exec_action IN ('submit','verify','start','in_progress','complete','abort','cancel')) NOT NULL -- 执行动作,
    exec_status TEXT CHECK (exec_status IN ('pending','verified','in_progress','completed','failed','cancelled')) NOT NULL DEFAULT 'pending',
    plan_time TIMESTAMPTZ -- 计划时间,
    start_time TIMESTAMPTZ -- 开始时间,
    complete_time TIMESTAMPTZ -- 完成时间,
    performer_id UUID REFERENCES public.hr_employee(id),
    performer_name TEXT,
    performer_dept_id UUID,
    verify_by UUID,
    verify_time TIMESTAMPTZ,
    location TEXT -- 执行地点,
    method TEXT -- 执行方式,
    result TEXT -- 执行结果,
    notes TEXT,
    signature_data TEXT -- 签名数据,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, exec_no)
);

CREATE TRIGGER op_order_execution_updated_at BEFORE UPDATE ON public.op_order_execution FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.8 转床记录
CREATE TABLE IF NOT EXISTS public.ip_bed_transfer (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    from_bed_id UUID REFERENCES public.ip_bed(id),
    to_bed_id UUID REFERENCES public.ip_bed(id),
    from_ward_id UUID REFERENCES public.org_ward(id),
    to_ward_id UUID REFERENCES public.org_ward(id),
    from_dept_id UUID REFERENCES public.org_dept(id),
    to_dept_id UUID REFERENCES public.org_dept(id),
    transfer_type TEXT CHECK (transfer_type IN ('bed','ward','dept')) NOT NULL,
    transfer_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reason TEXT,
    nurse_id UUID REFERENCES public.hr_employee(id),
    doctor_order_id UUID,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER ip_bed_transfer_updated_at BEFORE UPDATE ON public.ip_bed_transfer FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.9 会诊记录
CREATE TABLE IF NOT EXISTS public.ip_consultation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    consultation_no TEXT NOT NULL,
    consultation_type TEXT CHECK (consultation_type IN ('department','special','multi','remote','emergency')) NOT NULL,
    apply_dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    apply_doctor_id UUID NOT NULL REFERENCES public.hr_employee(id),
    target_dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    target_doctor_id UUID REFERENCES public.hr_employee(id),
    diagnosis JSONB,
    chief_complaint TEXT -- 会诊目的,
    consultation_detail TEXT -- 会诊意见,
    apply_time TIMESTAMPTZ DEFAULT NOW(),
    scheduled_time TIMESTAMPTZ,
    consultation_time TIMESTAMPTZ,
    status TEXT CHECK (status IN ('pending','scheduled','completed','cancelled','rejected')) DEFAULT 'pending',
    urgency_level TEXT CHECK (urgency_level IN ('normal','urgent','stat')) DEFAULT 'normal',
    response_time TIMESTAMPTZ,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, consultation_no)
);

CREATE TRIGGER ip_consultation_updated_at BEFORE UPDATE ON public.ip_consultation FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.10 住院费用明细
CREATE TABLE IF NOT EXISTS public.ip_charge (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    visit_sn TEXT NOT NULL,
    charge_no TEXT NOT NULL -- 费用单号,
    bill_date DATE NOT NULL -- 计费日期,
    item_id UUID,
    item_code TEXT,
    item_name TEXT NOT NULL,
    item_type TEXT NOT NULL,
    spec TEXT,
    unit TEXT,
    quantity NUMERIC(12,4) NOT NULL DEFAULT 1,
    price INTEGER NOT NULL DEFAULT 0 -- 单价（分）,
    amount INTEGER NOT NULL DEFAULT 0 -- 金额（分）,
    discount_amount INTEGER DEFAULT 0,
    actual_amount INTEGER NOT NULL DEFAULT 0,
    insurance_amount INTEGER DEFAULT 0,
    self_payment_amount INTEGER DEFAULT 0,
    charge_source TEXT CHECK (charge_source IN ('order','manual','daily','package','fixed')) NOT NULL,
    order_id UUID -- 关联医嘱,
    order_no TEXT,
    exec_time TIMESTAMPTZ,
    exec_dept_id UUID,
    nursing_order_id UUID,
    performer_id UUID,
    performer_name TEXT,
    is_settled BOOLEAN DEFAULT FALSE,
    settle_id UUID,
    invoice_no TEXT,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, charge_no)
);

CREATE TRIGGER ip_charge_updated_at BEFORE UPDATE ON public.ip_charge FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.11 住院日清单
CREATE TABLE IF NOT EXISTS public.ip_daily_bill (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    bill_date DATE NOT NULL,
    total_amount INTEGER NOT NULL DEFAULT 0,
    insurance_amount INTEGER DEFAULT 0,
    self_payment_amount INTEGER DEFAULT 0,
    deposit_amount INTEGER DEFAULT 0,
    balance_amount INTEGER DEFAULT 0,
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT CHECK (status IN ('generated','confirmed','printed','sent')) DEFAULT 'generated',
    confirm_by UUID,
    confirm_time TIMESTAMPTZ,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(admission_id, bill_date)
);

CREATE TRIGGER ip_daily_bill_updated_at BEFORE UPDATE ON public.ip_daily_bill FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.12 出院结算
CREATE TABLE IF NOT EXISTS public.ip_settlement (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    settle_no TEXT NOT NULL -- 结算单号,
    settle_type TEXT CHECK (settle_type IN ('final','interim','transfer')) NOT NULL,
    settle_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total_amount INTEGER NOT NULL DEFAULT 0,
    insurance_amount INTEGER DEFAULT 0 -- 医保支付（分）,
    self_payment_amount INTEGER DEFAULT 0 -- 自付金额（分）,
    deposit_used INTEGER DEFAULT 0,
    deposit_refund INTEGER DEFAULT 0,
    additional_payment INTEGER DEFAULT 0 -- 补缴金额（分）,
    payment_method TEXT CHECK (payment_method IN ('cash','card','wechat','alipay','transfer','mixed')),
    insurance_settlement_data JSONB -- 医保结算数据,
    invoice_no TEXT,
    invoice_url TEXT,
    operator_id UUID REFERENCES public.hr_employee(id),
    status TEXT DEFAULT 'completed',
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, settle_no)
);

CREATE TRIGGER ip_settlement_updated_at BEFORE UPDATE ON public.ip_settlement FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.13 护理记录
CREATE TABLE IF NOT EXISTS public.ip_nursing_record (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    record_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    record_type TEXT CHECK (record_type IN ('vital_signs','intake_output','nursing_note','assessment','care_plan','tube','wound','activity')) NOT NULL,
    vital_signs JSONB -- 生命体征,
    intake JSONB -- 入量,
    output JSONB -- 出量,
    assessment_data JSONB,
    nursing_actions JSONB,
    nursing_problems TEXT,
    goals TEXT,
    evaluation TEXT,
    pain_score INTEGER,
    fall_risk_score INTEGER,
    pressure_ulcer_risk TEXT,
    nurse_id UUID NOT NULL REFERENCES public.hr_employee(id),
    signature_data TEXT,
    attachment_urls TEXT[],
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER ip_nursing_record_updated_at BEFORE UPDATE ON public.ip_nursing_record FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.14 体温单
CREATE TABLE IF NOT EXISTS public.ip_temperature_sheet (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    record_date DATE NOT NULL,
    record_time TIMESTAMPTZ NOT NULL,
    temperature NUMERIC(4,1) -- 体温,
    pulse INTEGER -- 脉搏,
    respiration INTEGER -- 呼吸,
    blood_pressure_sys INTEGER -- 收缩压,
    blood_pressure_dia INTEGER -- 舒张压,
    spo2 NUMERIC(4,1),
    consciousness TEXT CHECK (consciousness IN ('清醒','嗜睡','昏睡','浅昏迷','深昏迷')),
    pupil_left TEXT,
    pupil_right TEXT,
    pupil_reflex TEXT,
    nursing_level TEXT,
    diet TEXT,
    fluid_intake INTEGER -- 入量（ml）,
    fluid_output INTEGER -- 出量（ml）,
    stool TEXT,
    urine TEXT,
    weight NUMERIC(5,1),
    height NUMERIC(5,1),
    bmi NUMERIC(4,1),
    bed_rest TEXT CHECK (bed_rest IN ('绝对卧床','卧床','半卧','下床活动','离床活动')),
    notes TEXT,
    nurse_id UUID NOT NULL REFERENCES public.hr_employee(id),
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(admission_id, record_date, record_time)
);

CREATE TRIGGER ip_temperature_sheet_updated_at BEFORE UPDATE ON public.ip_temperature_sheet FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6.15 住院输血记录
CREATE TABLE IF NOT EXISTS public.ip_blood_transfusion (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    admission_id UUID NOT NULL REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT NOT NULL,
    transfusion_no TEXT NOT NULL -- 输血单号/血袋号,
    blood_type TEXT NOT NULL -- 血型,
    rh_type TEXT -- Rh(D)血型,
    blood_product TEXT NOT NULL -- 血液成分,
    blood_volume INTEGER NOT NULL -- 输血量(ml),
    blood_unit_no TEXT -- 血袋编号,
    donor_code TEXT -- 献血者代码,
    collection_date DATE -- 采集日期,
    expire_date DATE -- 失效日期,
    crossmatch_time TIMESTAMPTZ -- 配血时间,
    crossmatch_result TEXT CHECK (crossmatch_result IN ('compatible','incompatible','pending')) DEFAULT 'pending',
    crossmatch_by UUID REFERENCES public.hr_employee(id),
    transfusion_start_time TIMESTAMPTZ -- 开始输血时间,
    transfusion_end_time TIMESTAMPTZ -- 结束输血时间,
    transfusion_rate TEXT -- 输血速度,
    transfusion_route TEXT -- 输血途径,
    pre_temp NUMERIC(4,1) -- 输血前体温,
    pre_bp_sys INTEGER -- 输血前收缩压,
    pre_bp_dia INTEGER -- 输血前舒张压,
    pre_pulse INTEGER -- 输血前脉搏,
    during_reactions JSONB -- 输血中反应记录,
    post_temp NUMERIC(4,1) -- 输血后体温,
    post_bp_sys INTEGER -- 输血后收缩压,
    post_bp_dia INTEGER -- 输血后舒张压,
    post_pulse INTEGER -- 输血后脉搏,
    reaction_type TEXT CHECK (reaction_type IN ('none','mild','moderate','severe','anaphylactic')) DEFAULT 'none' -- 输血反应类型,
    reaction_description TEXT -- 反应描述,
    reaction_handle TEXT -- 处理措施,
    reaction_result TEXT -- 处理结果,
    order_id UUID -- 关联医嘱,
    doctor_id UUID NOT NULL REFERENCES public.hr_employee(id),
    nurse_id UUID REFERENCES public.hr_employee(id) -- 执行护士,
    transfusion_dept_id UUID REFERENCES public.org_dept(id) -- 输血科室,
    remarks TEXT,
    status TEXT CHECK (status IN ('prescribed','crossmatched','in_progress','completed','cancelled','reaction')) DEFAULT 'prescribed',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, transfusion_no)
);

CREATE TRIGGER ip_blood_transfusion_updated_at BEFORE UPDATE ON public.ip_blood_transfusion FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 7. 药品管理模块 (pha_*)
-- ============================================================

-- 7.1 药品批次管理
CREATE TABLE IF NOT EXISTS public.pha_drug_batch (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    drug_id UUID NOT NULL REFERENCES public.md_drug(id),
    batch_no TEXT NOT NULL -- 批号,
    production_date DATE -- 生产日期,
    expire_date DATE NOT NULL -- 有效期,
    manufacture TEXT -- 生产厂家,
    supplier TEXT -- 供应商,
    cost_price INTEGER -- 成本价（分）,
    retail_price INTEGER -- 零售价（分）,
    quantity INTEGER NOT NULL DEFAULT 0 -- 当前库存,
    locked_quantity INTEGER DEFAULT 0 -- 锁定数量,
    storage_location TEXT -- 存放位置,
    warehouse_id UUID -- 仓库ID,
    status TEXT CHECK (status IN ('available','locked','expired','recalled','used_up')) DEFAULT 'available',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, drug_id, batch_no)
);

CREATE TRIGGER pha_drug_batch_updated_at BEFORE UPDATE ON public.pha_drug_batch FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7.2 药库库存
CREATE TABLE IF NOT EXISTS public.pha_warehouse_stock (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    warehouse_id UUID NOT NULL,
    drug_id UUID NOT NULL REFERENCES public.md_drug(id),
    batch_id UUID REFERENCES public.pha_drug_batch(id),
    quantity INTEGER NOT NULL DEFAULT 0,
    locked_quantity INTEGER DEFAULT 0,
    min_stock INTEGER DEFAULT 0,
    max_stock INTEGER DEFAULT 0,
    avg_cost_price INTEGER -- 平均成本价（分）,
    status TEXT DEFAULT 'available',
    last_check_date DATE -- 最后盘点日期,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(warehouse_id, drug_id, batch_id)
);

CREATE TRIGGER pha_warehouse_stock_updated_at BEFORE UPDATE ON public.pha_warehouse_stock FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7.3 药房库存
CREATE TABLE IF NOT EXISTS public.pha_pharmacy_stock (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pharmacy_dept_id UUID NOT NULL -- 药房科室,
    drug_id UUID NOT NULL REFERENCES public.md_drug(id),
    batch_id UUID REFERENCES public.pha_drug_batch(id),
    quantity INTEGER NOT NULL DEFAULT 0,
    locked_quantity INTEGER DEFAULT 0,
    min_stock INTEGER DEFAULT 0,
    max_stock INTEGER DEFAULT 0,
    upper_limit INTEGER -- 库存上限,
    lower_limit INTEGER -- 库存下限,
    avg_price INTEGER,
    status TEXT DEFAULT 'available',
    last_check_date DATE,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(pharmacy_dept_id, drug_id, batch_id)
);

CREATE TRIGGER pha_pharmacy_stock_updated_at BEFORE UPDATE ON public.pha_pharmacy_stock FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7.4 药品入库
CREATE TABLE IF NOT EXISTS public.pha_stock_in (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    in_no TEXT NOT NULL -- 入库单号,
    in_type TEXT CHECK (in_type IN ('purchase','transfer_in','return','adjustment','other')) NOT NULL,
    warehouse_id UUID REFERENCES public.msd_warehouse(id),
    pharmacy_dept_id UUID REFERENCES public.org_dept(id),
    supplier TEXT -- 供应商,
    invoice_no TEXT -- 发票号,
    invoice_date DATE,
    total_amount INTEGER NOT NULL DEFAULT 0 -- 总金额（分）,
    payment_status TEXT CHECK (payment_status IN ('unpaid','paid','partial')) DEFAULT 'unpaid',
    handler_id UUID -- 经手人,
    in_time TIMESTAMPTZ DEFAULT NOW(),
    status TEXT CHECK (status IN ('pending','confirmed','cancelled')) DEFAULT 'pending',
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, in_no)
);

CREATE TRIGGER pha_stock_in_updated_at BEFORE UPDATE ON public.pha_stock_in FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7.5 药品出库
CREATE TABLE IF NOT EXISTS public.pha_stock_out (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    out_no TEXT NOT NULL -- 出库单号,
    out_type TEXT CHECK (out_type IN ('prescription','dispense','transfer_out','return','adjustment','damage','expired','other')) NOT NULL,
    warehouse_id UUID REFERENCES public.msd_warehouse(id),
    pharmacy_dept_id UUID REFERENCES public.org_dept(id),
    target_dept_id UUID REFERENCES public.org_dept(id) -- 领用科室,
    total_amount INTEGER DEFAULT 0,
    handler_id UUID,
    out_time TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending',
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, out_no)
);

CREATE TRIGGER pha_stock_out_updated_at BEFORE UPDATE ON public.pha_stock_out FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7.6 门诊发药记录
CREATE TABLE IF NOT EXISTS public.pha_op_dispense (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    prescription_id UUID NOT NULL REFERENCES public.op_prescription(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    dispense_no TEXT NOT NULL -- 发药单号,
    dispense_time TIMESTAMPTZ DEFAULT NOW(),
    dispense_dept_id UUID NOT NULL,
    pharmacist_id UUID NOT NULL REFERENCES public.hr_employee(id),
    total_amount INTEGER NOT NULL DEFAULT 0,
    actual_amount INTEGER NOT NULL DEFAULT 0,
    status TEXT CHECK (status IN ('prepared','dispensed','partial','returned','cancelled')) DEFAULT 'dispensed',
    return_amount INTEGER DEFAULT 0,
    return_time TIMESTAMPTZ,
    return_reason TEXT,
    signature_data TEXT,
    notes TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, dispense_no)
);

CREATE TRIGGER pha_op_dispense_updated_at BEFORE UPDATE ON public.pha_op_dispense FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7.7 住院摆药
CREATE TABLE IF NOT EXISTS public.pha_ip_dispense (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    dispense_no TEXT NOT NULL -- 摆药单号,
    dispense_type TEXT CHECK (dispense_type IN ('single','whole','pivas','unit_dose')) NOT NULL,
    dept_id UUID NOT NULL -- 病区科室,
    ward_id UUID,
    bed_ids UUID[] -- 涉及床位,
    dispense_time TIMESTAMPTZ NOT NULL,
    plan_admin_time TIMESTAMPTZ -- 计划给药时间,
    status TEXT CHECK (status IN ('pending','prepared','verified','sent','administered','cancelled')) DEFAULT 'pending',
    prepared_by UUID -- 备药人,
    prepared_time TIMESTAMPTZ,
    verified_by UUID -- 核对人,
    verified_time TIMESTAMPTZ,
    sent_by UUID -- 发送人,
    sent_time TIMESTAMPTZ,
    pivas_batch_no TEXT -- PIVAS批次,
    notes TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, dispense_no)
);

CREATE TRIGGER pha_ip_dispense_updated_at BEFORE UPDATE ON public.pha_ip_dispense FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7.8 毒麻精放药品台账
CREATE TABLE IF NOT EXISTS public.pha_controlled_drug_account (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    dept_id UUID NOT NULL -- 使用科室,
    drug_id UUID NOT NULL REFERENCES public.md_drug(id),
    batch_id UUID REFERENCES public.pha_drug_batch(id),
    account_type TEXT CHECK (account_type IN ('receive','dispense','use','return','inventory','waste')) NOT NULL,
    quantity INTEGER NOT NULL -- 数量,
    balance_quantity INTEGER NOT NULL -- 结余数量,
    prescription_id UUID -- 处方ID,
    patient_id UUID -- 患者ID,
    patient_name TEXT,
    use_time TIMESTAMPTZ,
    use_by UUID NOT NULL -- 使用人,
    witness_by UUID -- 见证人,
    waste_quantity INTEGER -- 报废数量,
    waste_reason TEXT,
    waste_handle TEXT -- 报废处理方式,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER pha_controlled_drug_account_updated_at BEFORE UPDATE ON public.pha_controlled_drug_account FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7.9 药品盘点
CREATE TABLE IF NOT EXISTS public.pha_stock_check (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    check_no TEXT NOT NULL -- 盘点单号,
    check_type TEXT CHECK (check_type IN ('warehouse','pharmacy','dept','partial','full')) NOT NULL,
    dept_id UUID -- 科室（药房或病区）,
    check_date DATE NOT NULL,
    checker_id UUID NOT NULL,
    status TEXT CHECK (status IN ('pending','in_progress','completed','cancelled')) DEFAULT 'pending',
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    total_amount INTEGER -- 账面金额（分）,
    actual_amount INTEGER -- 实盘金额（分）,
    profit_loss_amount INTEGER -- 损溢金额（分）,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, check_no)
);

CREATE TRIGGER pha_stock_check_updated_at BEFORE UPDATE ON public.pha_stock_check FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7.10 药品不良反应报告
CREATE TABLE IF NOT EXISTS public.pha_adr_report (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    report_no TEXT NOT NULL -- ADR报告编号,
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT -- 就诊流水号,
    admission_id UUID REFERENCES public.ip_admission(id),
    patient_type TEXT CHECK (patient_type IN ('outpatient','inpatient','emergency')) NOT NULL,
    dept_id UUID NOT NULL REFERENCES public.org_dept(id) -- 报告科室,
    doctor_id UUID NOT NULL REFERENCES public.hr_employee(id) -- 报告医生,
    report_time TIMESTAMPTZ NOT NULL DEFAULT NOW() -- 发现时间,
    drug_name TEXT NOT NULL -- 怀疑药品名称,
    drug_code TEXT -- 药品编码,
    drug_spec TEXT -- 药品规格,
    drug_manufacturer TEXT -- 生产厂家,
    batch_no TEXT -- 批号,
    usage TEXT -- 用法用量,
    route TEXT -- 给药途径,
    daily_dose TEXT -- 日剂量,
    treatment_course TEXT -- 用药疗程,
    indication TEXT -- 用药原因/适应症,
    reaction_date TIMESTAMPTZ -- 反应发生时间,
    reaction_type TEXT NOT NULL -- 不良反应类型,
    reaction_description TEXT NOT NULL -- 不良反应描述,
    reaction_severity TEXT CHECK (reaction_severity IN ('mild','moderate','severe','dead')) NOT NULL -- 严重程度,
    reaction_result TEXT CHECK (reaction_result IN ('recovered','recovering','not_recovered','recovered_with_sequelae','dead','unknown')) -- 结果,
    is_serious BOOLEAN DEFAULT FALSE -- 是否严重,
    serious_reason TEXT -- 严重原因,
    causal_relationship TEXT CHECK (causal_relationship IN ('certain','probable','possible','unlikely','conditional','unassessable')) NOT NULL -- 因果关系评价,
    related_drugs JSONB -- 并用药品,
    lab_results JSONB -- 实验室检查,
    handling_measures TEXT -- 处理措施,
    handling_result TEXT -- 处理结果,
    is_reported BOOLEAN DEFAULT FALSE -- 是否已上报药监部门,
    report_org TEXT -- 上报机构,
    report_time_outer TIMESTAMPTZ -- 外部上报时间,
    remarks TEXT,
    status TEXT CHECK (status IN ('preliminary','confirmed','submitted','accepted','rejected','closed')) DEFAULT 'preliminary',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, report_no)
);

CREATE TRIGGER pha_adr_report_updated_at BEFORE UPDATE ON public.pha_adr_report FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7.11 营养液配置记录
CREATE TABLE IF NOT EXISTS public.pha_nutrition_solution (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    solution_no TEXT NOT NULL -- 配置单号,
    solution_type TEXT CHECK (solution_type IN ('tpn','enn','HEN','PEN','customized')) NOT NULL -- 营养液类型,
    admission_id UUID REFERENCES public.ip_admission(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    ward_id UUID REFERENCES public.org_ward(id),
    bed_no TEXT -- 床位号,
    patient_weight NUMERIC(5,1) -- 体重(kg),
    patient_height NUMERIC(5,1) -- 身高(cm),
    nutritional_requirement JSONB NOT NULL -- 营养需求,
    formula_components JSONB NOT NULL -- 配方成分,
    total_volume INTEGER NOT NULL -- 总体积(ml),
    total_calorie INTEGER NOT NULL -- 总热量(kcal),
    total_nitrogen INTEGER -- 总氮量(g),
    osmolarity INTEGER -- 渗透压(mOsm/L),
    infusion_rate INTEGER -- 输注速度(ml/h),
    administration_route TEXT NOT NULL -- 输入途径,
    administration_method TEXT -- 输注方式,
    plan_start_time TIMESTAMPTZ -- 计划开始时间,
    plan_end_time TIMESTAMPTZ -- 计划结束时间,
    actual_start_time TIMESTAMPTZ -- 实际开始时间,
    actual_end_time TIMESTAMPTZ -- 实际结束时间,
    prepared_by UUID REFERENCES public.hr_employee(id) -- 配制人,
    prepared_time TIMESTAMPTZ -- 配制时间,
    verified_by UUID REFERENCES public.hr_employee(id) -- 核对人,
    administered_by UUID REFERENCES public.hr_employee(id) -- 执行人,
    administration_status TEXT CHECK (administration_status IN ('prescribed','prepared','verified','in_progress','completed','cancelled','paused')) DEFAULT 'prescribed',
    tolerance_status TEXT -- 耐受情况,
    adverse_reactions TEXT -- 不良反应,
    tolerance_evaluation JSONB -- 耐受性评估,
    residual_volume INTEGER -- 残余量(ml),
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, solution_no)
);

CREATE TRIGGER pha_nutrition_solution_updated_at BEFORE UPDATE ON public.pha_nutrition_solution FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 8. 检查检验模块 (lis_*/ris_*)
-- ============================================================

-- 8.1 LIS 检验申请
CREATE TABLE IF NOT EXISTS public.lis_request (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    request_no TEXT NOT NULL -- 检验申请单号,
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT -- 就诊流水号（门诊）,
    admission_id UUID -- 住院登记ID,
    dept_id UUID NOT NULL REFERENCES public.org_dept(id) -- 申请科室,
    doctor_id UUID NOT NULL REFERENCES public.hr_employee(id),
    patient_type TEXT CHECK (patient_type IN ('outpatient','inpatient','emergency','health_check')) NOT NULL,
    clinical_diagnosis TEXT -- 临床诊断,
    specimen_type TEXT NOT NULL -- 标本类型,
    specimen_container TEXT -- 采集容器,
    collection_place TEXT -- 采集地点,
    collection_time TIMESTAMPTZ -- 采集时间,
    collector_id UUID -- 采集人,
    received_time TIMESTAMPTZ -- 接收时间,
    receiver_id UUID -- 接收人,
    specimen_condition TEXT -- 标本状态,
    urgency_level TEXT CHECK (urgency_level IN ('normal','urgent','stat')) DEFAULT 'normal',
    test_purpose TEXT -- 检验目的,
    remarks TEXT,
    status TEXT CHECK (status IN ('pending','collected','received','testing','reported','cancelled')) DEFAULT 'pending',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, request_no)
);

CREATE TRIGGER lis_request_updated_at BEFORE UPDATE ON public.lis_request FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 8.2 LIS 检验结果
CREATE TABLE IF NOT EXISTS public.lis_result (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    request_id UUID NOT NULL REFERENCES public.lis_request(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    result_no TEXT NOT NULL -- 结果报告单号,
    test_item_id UUID NOT NULL REFERENCES public.md_lis_item(id),
    item_code TEXT NOT NULL,
    item_name TEXT NOT NULL,
    result_value TEXT,
    result_value_numeric NUMERIC(12,4) -- 数值结果,
    result_unit TEXT -- 单位,
    reference_range TEXT -- 参考范围,
    reference_low NUMERIC(12,4) -- 参考下限,
    reference_high NUMERIC(12,4) -- 参考上限,
    is_abnormal BOOLEAN DEFAULT FALSE -- 是否异常,
    abnormal_flag TEXT CHECK (abnormal_flag IN ('normal','low','high','critical_low','critical_high')) DEFAULT 'normal',
    is_critical BOOLEAN DEFAULT FALSE -- 是否危急值,
    result_status TEXT CHECK (result_status IN ('preliminary','final','corrected','alert')) DEFAULT 'preliminary',
    instrument TEXT -- 检测仪器,
    method_used TEXT -- 使用方法,
    reagent_lot TEXT -- 试剂批号,
    enter_time TIMESTAMPTZ DEFAULT NOW(),
    enter_by UUID NOT NULL REFERENCES public.hr_employee(id),
    verify_time TIMESTAMPTZ,
    verify_by UUID REFERENCES public.hr_employee(id),
    verify_status TEXT CHECK (verify_status IN ('unverified','verified','corrected')) DEFAULT 'unverified',
    remarks TEXT -- 结果备注,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(request_id, test_item_id)
);

CREATE TRIGGER lis_result_updated_at BEFORE UPDATE ON public.lis_result FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 8.3 LIS 危急值记录
CREATE TABLE IF NOT EXISTS public.lis_critical_value (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    result_id UUID NOT NULL REFERENCES public.lis_result(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT,
    item_name TEXT NOT NULL,
    critical_value TEXT NOT NULL -- 危急值,
    critical_type TEXT CHECK (critical_type IN ('critical_low','critical_high')) NOT NULL,
    report_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    report_to_id UUID NOT NULL -- 报告给谁,
    report_to_name TEXT NOT NULL,
    report_by_id UUID NOT NULL -- 报告人,
    report_by_name TEXT,
    confirm_time TIMESTAMPTZ -- 确认时间,
    confirm_by_id UUID -- 确认人,
    confirm_method TEXT -- 确认方式,
    handling_status TEXT CHECK (handling_status IN ('unhandled','handling','handled')) DEFAULT 'unhandled',
    handling_result TEXT,
    handling_time TIMESTAMPTZ,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER lis_critical_value_updated_at BEFORE UPDATE ON public.lis_critical_value FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 8.4 LIS 室内质控
CREATE TABLE IF NOT EXISTS public.lis_qc_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    test_item_id UUID NOT NULL REFERENCES public.md_lis_item(id),
    qc_material_id UUID -- 质控品ID,
    qc_lot_no TEXT -- 质控品批号,
    qc_level TEXT CHECK (qc_level IN ('1','2','3')) NOT NULL -- 质控水平,
    result_value NUMERIC(12,4) NOT NULL,
    result_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    instrument TEXT -- 仪器,
    reagent_lot TEXT -- 试剂批号,
    target_value NUMERIC(12,4) -- 靶值,
    target_sd NUMERIC(12,4) -- 标准差,
    cv_percent NUMERIC(6,3) -- 变异系数,
    is_pass BOOLEAN -- 是否合格,
    westgard_rules JSONB -- Westgard规则判定,
    status TEXT CHECK (status IN ('pending','verified','rejected')) DEFAULT 'pending',
    verify_by UUID,
    verify_time TIMESTAMPTZ,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER lis_qc_data_updated_at BEFORE UPDATE ON public.lis_qc_data FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 8.5 RIS 影像检查申请
CREATE TABLE IF NOT EXISTS public.ris_request (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    request_no TEXT NOT NULL -- 检查申请单号,
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT,
    admission_id UUID,
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    doctor_id UUID NOT NULL REFERENCES public.hr_employee(id),
    patient_type TEXT NOT NULL,
    clinical_diagnosis TEXT -- 临床诊断,
    exam_type TEXT NOT NULL -- 检查类型,
    exam_subtype TEXT -- 检查子类型,
    exam_part TEXT NOT NULL -- 检查部位,
    exam_method TEXT -- 检查方法,
    exam_indications TEXT -- 检查指征,
    has_contrast BOOLEAN DEFAULT FALSE,
    contrast_agent TEXT -- 造影剂,
    has_allergy_risk BOOLEAN DEFAULT FALSE,
    preparation_instruction TEXT -- 检查前准备,
    urgency_level TEXT DEFAULT 'normal',
    appointment_time TIMESTAMPTZ -- 预约时间,
    appointment_no TEXT -- 预约号,
    exam_location TEXT -- 检查地点,
    exam_time TIMESTAMPTZ -- 检查时间,
    exam_duration INTEGER -- 检查时长（分钟）,
    has_pacs BOOLEAN DEFAULT TRUE,
    has_dicom BOOLEAN DEFAULT TRUE,
    remarks TEXT,
    status TEXT CHECK (status IN ('registered','appointed','checked_in','imaging','reported','cancelled')) DEFAULT 'registered',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, request_no)
);

CREATE TRIGGER ris_request_updated_at BEFORE UPDATE ON public.ris_request FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 8.6 RIS 影像报告
CREATE TABLE IF NOT EXISTS public.ris_report (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    request_id UUID NOT NULL REFERENCES public.ris_request(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    report_no TEXT NOT NULL -- 报告编号,
    finding TEXT -- 所见,
    impression TEXT -- 印象/结论,
    diagnosis JSONB -- 诊断,
    exam_start_time TIMESTAMPTZ -- 检查开始时间,
    exam_end_time TIMESTAMPTZ -- 检查结束时间,
    radiologist_id UUID REFERENCES public.hr_employee(id),
    report_time TIMESTAMPTZ -- 报告时间,
    is_critical BOOLEAN DEFAULT FALSE -- 是否危急值,
    critical_findings TEXT -- 危急值描述,
    critical_reported_time TIMESTAMPTZ,
    critical_reported_to TEXT -- 报告给谁,
    verified_by UUID -- 审核人,
    verified_time TIMESTAMPTZ -- 审核时间,
    report_status TEXT CHECK (report_status IN ('draft','preliminary','final','amended','cancelled')) DEFAULT 'draft',
    image_count INTEGER -- 图像数量,
    image_urls TEXT[] -- 图像URL列表,
    thumbnail_urls TEXT[] -- 缩略图URL,
    dicom_study_uid TEXT -- DICOM Study UID,
    pacs_accession_no TEXT -- PACS Accession Number,
    amended_reason TEXT -- 修改原因,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, report_no)
);

CREATE TRIGGER ris_report_updated_at BEFORE UPDATE ON public.ris_report FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 8.7 RIS 危急值
CREATE TABLE IF NOT EXISTS public.ris_critical_findings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    report_id UUID NOT NULL REFERENCES public.ris_report(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    finding_type TEXT NOT NULL -- 危急值类型,
    finding_description TEXT NOT NULL -- 危急值描述,
    exam_type TEXT -- 检查类型,
    report_time TIMESTAMPTZ DEFAULT NOW(),
    report_doctor_id UUID NOT NULL,
    report_doctor_name TEXT,
    reported_to_id UUID -- 报告给谁（医生）,
    reported_to_name TEXT,
    reported_to_dept TEXT,
    confirm_time TIMESTAMPTZ,
    confirm_by_id UUID,
    handling_status TEXT DEFAULT 'unhandled',
    handling_result TEXT,
    handling_time TIMESTAMPTZ,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER ris_critical_findings_updated_at BEFORE UPDATE ON public.ris_critical_findings FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 9. 手术麻醉模块 (opt_*)
-- ============================================================

-- 9.1 手术申请
CREATE TABLE IF NOT EXISTS public.opt_surgery_request (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    request_no TEXT NOT NULL -- 手术申请单号,
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT,
    admission_id UUID REFERENCES public.ip_admission(id),
    dept_id UUID NOT NULL REFERENCES public.org_dept(id) -- 申请科室,
    bed_no TEXT -- 床位号,
    doctor_id UUID NOT NULL REFERENCES public.hr_employee(id),
    patient_type TEXT NOT NULL,
    clinical_diagnosis JSONB -- 临床诊断,
    surgery_intention TEXT -- 手术目的,
    surgery_name TEXT NOT NULL -- 拟手术名称,
    surgery_code TEXT -- ICD-9-CM3编码,
    incision_grade TEXT CHECK (incision_grade IN ('I','II','III','IV')) -- 切口等级,
    surgery_level TEXT CHECK (surgery_level IN ('1','2','3','4')) -- 手术级别,
    has_implant BOOLEAN DEFAULT FALSE,
    implant_info JSONB -- 植入物信息,
    has_blood_transfusion BOOLEAN DEFAULT FALSE,
    blood_type TEXT -- 血型,
    blood_units INTEGER -- 备血单位,
    has_anesthesia BOOLEAN DEFAULT TRUE,
    anesthesia_type TEXT -- 麻醉方式,
    emergency_level TEXT CHECK (emergency_level IN ('elective','urgent','emergency')) DEFAULT 'elective',
    has_allergy_risk BOOLEAN DEFAULT FALSE,
    preferred_date DATE -- 期望手术日期,
    preferred_surgeon_id UUID -- 期望主刀,
    preferred_anesthesiologist_id UUID -- 期望麻醉医生,
    required_equipment JSONB -- 特殊设备需求,
    infection_status TEXT CHECK (infection_status IN ('clean','contaminated','dirty')) DEFAULT 'clean',
    is_informed_consent BOOLEAN DEFAULT FALSE,
    consent_document_url TEXT,
    remarks TEXT,
    status TEXT CHECK (status IN ('pending','scheduled','preoperated','in_surgery','recovery','completed','cancelled')) DEFAULT 'pending',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, request_no)
);

CREATE TRIGGER opt_surgery_request_updated_at BEFORE UPDATE ON public.opt_surgery_request FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 9.2 手术排台
CREATE TABLE IF NOT EXISTS public.opt_surgery_schedule (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    request_id UUID NOT NULL REFERENCES public.opt_surgery_request(id),
    schedule_no TEXT NOT NULL -- 排台编号,
    surgery_date DATE NOT NULL -- 手术日期,
    surgery_room TEXT NOT NULL -- 手术间,
    sequence_no INTEGER -- 台次,
    start_time TIMESTAMPTZ -- 计划开始时间,
    end_time TIMESTAMPTZ -- 计划结束时间,
    actual_start_time TIMESTAMPTZ -- 实际开始时间,
    actual_end_time TIMESTAMPTZ -- 实际结束时间,
    surgeon_id UUID REFERENCES public.hr_employee(id),
    first_assistant_id UUID,
    second_assistant_id UUID,
    anesthesiologist_id UUID,
    anesthesia_assistant_id UUID,
    instrument_nurse_id UUID,
    circulating_nurse_id UUID,
    surgery_status TEXT CHECK (surgery_status IN ('scheduled','preparing','in_progress','completed','cancelled','postponed')) DEFAULT 'scheduled',
    cancel_reason TEXT,
    post_op_location TEXT -- 术后去向,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, schedule_no)
);

CREATE TRIGGER opt_surgery_schedule_updated_at BEFORE UPDATE ON public.opt_surgery_schedule FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 9.3 手术安全核查
CREATE TABLE IF NOT EXISTS public.opt_safety_check (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    schedule_id UUID NOT NULL REFERENCES public.opt_surgery_schedule(id),
    patient_id UUID NOT NULL REFERENCES public.pat_master(id),
    check_phase TEXT CHECK (check_phase IN ('before_induction','before_incision','before_leaving')) NOT NULL -- 核查阶段,
    check_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    patient_name_correct BOOLEAN DEFAULT FALSE,
    procedure_consent BOOLEAN DEFAULT FALSE,
    anesthesia_consent BOOLEAN DEFAULT FALSE,
    fasting_confirmed BOOLEAN DEFAULT FALSE,
    allergy_checked BOOLEAN DEFAULT FALSE,
    site_marked BOOLEAN DEFAULT FALSE,
    skin_integrity BOOLEAN DEFAULT FALSE,
    iv_access BOOLEAN DEFAULT FALSE,
    blood_available BOOLEAN DEFAULT FALSE,
    imaging_available BOOLEAN DEFAULT FALSE,
    equipment_checked BOOLEAN DEFAULT FALSE,
    implant_ready BOOLEAN DEFAULT FALSE,
    wrong_site_risk BOOLEAN DEFAULT FALSE,
    wrong_patient_risk BOOLEAN DEFAULT FALSE,
    wrong_procedure_risk BOOLEAN DEFAULT FALSE,
    nurse_checker_id UUID,
    surgeon_id UUID,
    anesthesiologist_id UUID,
    signature_surgeon TEXT,
    signature_anesthesiologist TEXT,
    signature_nurse TEXT,
    status TEXT CHECK (status IN ('pending','completed','cancelled','discrepancy')) DEFAULT 'pending',
    discrepancy_detail TEXT -- 不符详情,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER opt_safety_check_updated_at BEFORE UPDATE ON public.opt_safety_check FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 9.4 手术记录
CREATE TABLE IF NOT EXISTS public.opt_surgery_record (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    schedule_id UUID NOT NULL REFERENCES public.opt_surgery_schedule(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    record_no TEXT NOT NULL -- 手术记录编号,
    surgery_name TEXT NOT NULL -- 手术名称,
    surgery_code TEXT -- ICD-9-CM3,
    surgery_start_time TIMESTAMPTZ NOT NULL -- 手术开始时间,
    surgery_end_time TIMESTAMPTZ -- 手术结束时间,
    total_duration INTEGER -- 手术时长（分钟）,
    anesthesia_start_time TIMESTAMPTZ -- 麻醉开始时间,
    anesthesia_end_time TIMESTAMPTZ -- 麻醉结束时间,
    anesthesia_type TEXT -- 麻醉方式,
    anesthesia_method_detail TEXT,
    blood_loss INTEGER DEFAULT 0 -- 出血量（ml）,
    blood_transfusion INTEGER DEFAULT 0 -- 输血量（ml）,
    urine_output INTEGER DEFAULT 0 -- 尿量（ml）,
    positioning TEXT -- 体位,
    incision_site TEXT -- 切口部位,
    surgical_approach TEXT -- 手术入路,
    findings TEXT -- 术中所见,
    procedure_performed TEXT NOT NULL -- 手术经过,
    specimens_collected TEXT[] -- 采集标本,
    implant_used JSONB -- 使用植入物,
    complications JSONB -- 并发症,
    drainage_tubes JSONB -- 引流管,
    post_op_diagnosis JSONB -- 术后诊断,
    post_op_orders TEXT -- 术后医嘱,
    surgeon_id UUID NOT NULL,
    first_assistant_id UUID,
    recorder_id UUID -- 记录人,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, record_no)
);

CREATE TRIGGER opt_surgery_record_updated_at BEFORE UPDATE ON public.opt_surgery_record FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 9.5 麻醉记录
CREATE TABLE IF NOT EXISTS public.opt_anesthesia_record (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    schedule_id UUID NOT NULL REFERENCES public.opt_surgery_schedule(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    record_no TEXT NOT NULL,
    anesthesia_type TEXT NOT NULL,
    anesthesia_induction_time TIMESTAMPTZ -- 麻醉诱导时间,
    anesthesia_maintenance TEXT -- 麻醉维持,
    position_changes JSONB -- 体位变动,
    vital_signs JSONB[] -- 生命体征数组,
    events JSONB -- 麻醉事件,
    drug_administrations JSONB -- 用药记录,
    blood_transfusions JSONB -- 输血记录,
    fluid_input_summary JSONB -- 液体输入总结,
    airway_management_detail TEXT -- 气道管理详情,
    complications JSONB -- 麻醉并发症,
    post_op_pacu_arrival_time TIMESTAMPTZ -- 入恢复室时间,
    post_op_pacu_stay_duration INTEGER -- 恢复室停留时间（分钟）,
    post_op_pacu_score INTEGER -- 恢复室评分,
    post_op_conditions TEXT -- 离开恢复室时状况,
    anesthesiologist_id UUID NOT NULL,
    crna_id UUID -- 麻醉护士,
    record_complete_time TIMESTAMPTZ,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, record_no)
);

CREATE TRIGGER opt_anesthesia_record_updated_at BEFORE UPDATE ON public.opt_anesthesia_record FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 9.6 手术计费
CREATE TABLE IF NOT EXISTS public.opt_surgery_charge (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    admission_id UUID REFERENCES public.ip_admission(id),
    schedule_id UUID NOT NULL REFERENCES public.opt_surgery_schedule(id),
    charge_no TEXT NOT NULL,
    charge_type TEXT CHECK (charge_type IN ('surgery','anesthesia','material','drug','other')) NOT NULL,
    item_id UUID,
    item_code TEXT,
    item_name TEXT NOT NULL,
    item_spec TEXT,
    quantity NUMERIC(12,4) DEFAULT 1,
    price INTEGER NOT NULL DEFAULT 0 -- 单价（分）,
    amount INTEGER NOT NULL DEFAULT 0 -- 金额（分）,
    discount_amount INTEGER DEFAULT 0,
    actual_amount INTEGER NOT NULL DEFAULT 0,
    charge_time TIMESTAMPTZ DEFAULT NOW(),
    charge_status TEXT DEFAULT 'charged',
    invoice_no TEXT,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, charge_no)
);

CREATE TRIGGER opt_surgery_charge_updated_at BEFORE UPDATE ON public.opt_surgery_charge FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 10. 费用与医保模块 (fee_*)
-- ============================================================

-- 10.1 收费项目分类
CREATE TABLE IF NOT EXISTS public.fee_category (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    parent_id UUID REFERENCES public.fee_category(id),
    level INTEGER DEFAULT 1,
    sort_order INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE
);

CREATE TRIGGER fee_category_updated_at BEFORE UPDATE ON public.fee_category FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 10.2 医保目录对照
CREATE TABLE IF NOT EXISTS public.fee_insurance_catalog (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    item_type TEXT CHECK (item_type IN ('drug','item','material')) NOT NULL,
    item_id UUID NOT NULL,
    item_code TEXT NOT NULL,
    item_name TEXT NOT NULL,
    spec TEXT,
    unit TEXT,
    insurance_code TEXT NOT NULL -- 医保编码,
    insurance_name TEXT,
    insurance_category TEXT -- 医保类别,
    reimbursement_ratio NUMERIC(5,4) -- 报销比例,
    pay_limit INTEGER -- 限价（分）,
    self_ratio INTEGER -- 自付比例(%),
    is_overall BOOLEAN DEFAULT FALSE -- 是否甲类,
    is_chronic BOOLEAN DEFAULT FALSE -- 是否慢性病,
    chronic_require TEXT,
    effective_date DATE,
    expire_date DATE,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, item_type, item_id)
);

CREATE TRIGGER fee_insurance_catalog_updated_at BEFORE UPDATE ON public.fee_insurance_catalog FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 10.3 医保政策参数
CREATE TABLE IF NOT EXISTS public.fee_insurance_policy (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    policy_code TEXT NOT NULL,
    policy_name TEXT NOT NULL,
    insurance_type TEXT NOT NULL CHECK (insurance_type IN ('employee','resident','rural')),
    deductible_amount INTEGER DEFAULT 0 -- 起付线（分）,
    deductible_remark TEXT,
    reimbursement_ratio_base NUMERIC(5,4) -- 基础报销比例,
    reimbursement_ratio_overall NUMERIC(5,4) -- 甲类报销比例,
    reimbursement_ratio_chronic NUMERIC(5,4) -- 慢性病报销比例,
    ceiling_amount INTEGER -- 封顶线（分）,
    ceiling_remark TEXT,
    family_account_enabled BOOLEAN DEFAULT FALSE,
    family_account_ratio NUMERIC(5,4),
    account_usage_rule TEXT,
    region_code TEXT -- 统筹区编码,
    effective_date DATE NOT NULL,
    expire_date DATE,
    status TEXT DEFAULT 'active',
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, policy_code)
);

CREATE TRIGGER fee_insurance_policy_updated_at BEFORE UPDATE ON public.fee_insurance_policy FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 10.4 结算记录
CREATE TABLE IF NOT EXISTS public.fee_settlement (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    settle_no TEXT NOT NULL -- 结算单号,
    patient_type TEXT CHECK (patient_type IN ('outpatient','inpatient')) NOT NULL,
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT,
    admission_id UUID,
    settle_type TEXT CHECK (settle_type IN ('self_pay','insurance','mixed')) NOT NULL,
    settle_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total_amount INTEGER NOT NULL DEFAULT 0,
    insurance_amount INTEGER DEFAULT 0,
    self_payment_amount INTEGER DEFAULT 0,
    cash_payment INTEGER DEFAULT 0,
    account_payment INTEGER DEFAULT 0,
    supplemental_payment INTEGER DEFAULT 0,
    deposit_used INTEGER DEFAULT 0,
    deposit_refund INTEGER DEFAULT 0,
    additional_payment INTEGER DEFAULT 0,
    change_amount INTEGER DEFAULT 0,
    payment_details JSONB -- 支付详情,
    insurance_policy_id UUID,
    insurance_settlement_data JSONB,
    insurance_settlement_no TEXT,
    medical_record_no TEXT -- 病案号,
    invoice_no TEXT,
    invoice_url TEXT,
    invoice_print_count INTEGER DEFAULT 0,
    operator_id UUID,
    dept_id UUID,
    terminal_no TEXT -- 终端编号,
    remarks TEXT,
    status TEXT DEFAULT 'completed',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, settle_no)
);

CREATE TRIGGER fee_settlement_updated_at BEFORE UPDATE ON public.fee_settlement FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 10.5 发票管理
CREATE TABLE IF NOT EXISTS public.fee_invoice (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    invoice_no TEXT NOT NULL,
    invoice_code TEXT,
    invoice_type TEXT CHECK (invoice_type IN ('normal','special','electronic','replacement')) DEFAULT 'normal',
    patient_name TEXT NOT NULL,
    patient_id_no TEXT,
    pat_id UUID REFERENCES public.pat_master(id),
    settle_id UUID REFERENCES public.fee_settlement(id),
    invoice_amount INTEGER NOT NULL -- 发票金额（分）,
    invoice_tax INTEGER DEFAULT 0,
    invoice_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    invoice_status TEXT CHECK (invoice_status IN ('issued','void','red','returned')) DEFAULT 'issued',
    void_time TIMESTAMPTZ,
    void_reason TEXT,
    void_by UUID,
    printed_count INTEGER DEFAULT 0,
    last_print_time TIMESTAMPTZ,
    last_print_by UUID,
    settle_no TEXT,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, invoice_no)
);

CREATE TRIGGER fee_invoice_updated_at BEFORE UPDATE ON public.fee_invoice FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 11. 物资耗材模块 (msd_*)
-- ============================================================

-- 11.1 物资仓库
CREATE TABLE IF NOT EXISTS public.msd_warehouse (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    warehouse_code TEXT NOT NULL,
    warehouse_name TEXT NOT NULL,
    warehouse_type TEXT CHECK (warehouse_type IN ('central','department','consumable')) DEFAULT 'central',
    location TEXT,
    manager_id UUID,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, warehouse_code)
);

CREATE TRIGGER msd_warehouse_updated_at BEFORE UPDATE ON public.msd_warehouse FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 11.2 科室二级库
CREATE TABLE IF NOT EXISTS public.msd_dept_stock (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    material_id UUID NOT NULL REFERENCES public.md_material(id),
    warehouse_id UUID REFERENCES public.msd_warehouse(id),
    quantity INTEGER DEFAULT 0,
    locked_quantity INTEGER DEFAULT 0,
    min_stock INTEGER DEFAULT 0,
    max_stock INTEGER DEFAULT 0,
    last_replenish_date DATE,
    last_check_date DATE,
    status TEXT DEFAULT 'available',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(dept_id, material_id)
);

CREATE TRIGGER msd_dept_stock_updated_at BEFORE UPDATE ON public.msd_dept_stock FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 11.3 物资入库
CREATE TABLE IF NOT EXISTS public.msd_stock_in (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    in_no TEXT NOT NULL,
    in_type TEXT CHECK (in_type IN ('purchase','transfer','return','adjust','other')) NOT NULL,
    warehouse_id UUID NOT NULL,
    supplier TEXT,
    invoice_no TEXT,
    total_amount INTEGER DEFAULT 0,
    handler_id UUID,
    in_time TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending',
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, in_no)
);

CREATE TRIGGER msd_stock_in_updated_at BEFORE UPDATE ON public.msd_stock_in FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 11.4 物资出库
CREATE TABLE IF NOT EXISTS public.msd_stock_out (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    out_no TEXT NOT NULL,
    out_type TEXT CHECK (out_type IN ('replenish','apply','consume','return','adjust','other')) NOT NULL,
    warehouse_id UUID NOT NULL,
    target_dept_id UUID,
    total_amount INTEGER DEFAULT 0,
    handler_id UUID,
    out_time TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending',
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, out_no)
);

CREATE TRIGGER msd_stock_out_updated_at BEFORE UPDATE ON public.msd_stock_out FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 11.5 科室申领
CREATE TABLE IF NOT EXISTS public.msd_apply (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    apply_no TEXT NOT NULL,
    dept_id UUID NOT NULL REFERENCES public.org_dept(id),
    warehouse_id UUID REFERENCES public.msd_warehouse(id),
    apply_reason TEXT,
    total_amount INTEGER DEFAULT 0,
    apply_time TIMESTAMPTZ DEFAULT NOW(),
    apply_by UUID,
    status TEXT CHECK (status IN ('pending','approved','partial','shipped','received','cancelled')) DEFAULT 'pending',
    approve_by UUID,
    approve_time TIMESTAMPTZ,
    ship_time TIMESTAMPTZ,
    receive_time TIMESTAMPTZ,
    received_by UUID,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, apply_no)
);

CREATE TRIGGER msd_apply_updated_at BEFORE UPDATE ON public.msd_apply FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 11.6 高值耗材追溯
CREATE TABLE IF NOT EXISTS public.msd_traceability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    material_id UUID NOT NULL REFERENCES public.md_material(id),
    serial_no TEXT NOT NULL -- 唯一序列号,
    batch_no TEXT,
    manufacturer TEXT,
    production_date DATE,
    expire_date DATE,
    purchase_price INTEGER -- 采购价（分）,
    invoice_no TEXT,
    supplier TEXT,
    warehouse_id UUID,
    dept_id UUID,
    patient_id UUID,
    patient_name TEXT,
    use_time TIMESTAMPTZ,
    use_by UUID,
    surgery_name TEXT,
    surgery_date DATE,
    charge_id UUID -- 收费ID,
    status TEXT CHECK (status IN ('in_stock','in_transit','in_use','used','expired','returned')) DEFAULT 'in_stock',
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, serial_no)
);

CREATE TRIGGER msd_traceability_updated_at BEFORE UPDATE ON public.msd_traceability FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 12. 临床支持模块 (clinic_*)
-- ============================================================

-- 12.1 临床路径定义
CREATE TABLE IF NOT EXISTS public.clinic_pathway (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pathway_code TEXT NOT NULL,
    pathway_name TEXT NOT NULL,
    version TEXT DEFAULT '1.0',
    disease_code TEXT -- 对应疾病ICD,
    disease_name TEXT,
    dept_id UUID -- 适用科室,
    standard_days INTEGER -- 标准住院天数,
    pathway_type TEXT CHECK (pathway_type IN ('full','partial','single')) DEFAULT 'full',
    indications TEXT -- 入径标准,
    contraindications TEXT -- 出径标准,
    phases JSONB -- 阶段定义,
    effective_date DATE,
    expire_date DATE,
    status TEXT DEFAULT 'active',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, pathway_code, version)
);

CREATE TRIGGER clinic_pathway_updated_at BEFORE UPDATE ON public.clinic_pathway FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 12.2 临床路径执行记录
CREATE TABLE IF NOT EXISTS public.clinic_pathway_record (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pathway_id UUID NOT NULL REFERENCES public.clinic_pathway(id),
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    admission_id UUID REFERENCES public.ip_admission(id),
    record_no TEXT NOT NULL,
    entry_date DATE NOT NULL,
    expected_discharge_date DATE,
    actual_discharge_date DATE,
    current_phase TEXT,
    current_day INTEGER,
    pathway_status TEXT CHECK (pathway_status IN ('in_progress','completed','varied','exited','suspended')) DEFAULT 'in_progress',
    variances JSONB -- 变异记录,
    completed_items JSONB,
    pending_items JSONB,
    outcome TEXT CHECK (outcome IN ('cured','improved','not_improved','transferred','death')),
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, record_no)
);

CREATE TRIGGER clinic_pathway_record_updated_at BEFORE UPDATE ON public.clinic_pathway_record FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 12.3 抗生素分级授权
CREATE TABLE IF NOT EXISTS public.clinic_antibiotic_auth (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    emp_id UUID NOT NULL REFERENCES public.hr_employee(id),
    antibiotic_level TEXT CHECK (antibiotic_level IN ('non_restricted','restricted','special')) NOT NULL,
    auth_range TEXT,
    auth_diseases TEXT[] -- 授权病种,
    auth_start_date DATE NOT NULL,
    auth_end_date DATE,
    auth_document_url TEXT,
    issuer_id UUID,
    issue_date DATE NOT NULL,
    revoke_date DATE,
    revoke_reason TEXT,
    status TEXT CHECK (status IN ('active','expired','revoked','suspended')) DEFAULT 'active',
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, emp_id, antibiotic_level)
);

CREATE TRIGGER clinic_antibiotic_auth_updated_at BEFORE UPDATE ON public.clinic_antibiotic_auth FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 12.4 传染病报卡
CREATE TABLE IF NOT EXISTS public.clinic_infection_report (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT,
    report_no TEXT NOT NULL,
    disease_code TEXT NOT NULL,
    disease_name TEXT NOT NULL,
    infection_type TEXT NOT NULL,
    diagnosis_basis TEXT,
    diagnosis_date DATE NOT NULL,
    onset_date DATE,
    patient_type TEXT,
    dept_id UUID,
    doctor_id UUID NOT NULL,
    report_time TIMESTAMPTZ DEFAULT NOW(),
    report_to_dept TEXT -- 报告地疾控,
    report_to_time TIMESTAMPTZ,
    patient_condition TEXT,
    death_date DATE,
    is_severe BOOLEAN DEFAULT FALSE,
    is_cluster BOOLEAN DEFAULT FALSE,
    cluster_info JSONB,
    lab_result TEXT,
    epidemiology_investigation TEXT,
    public_health_measures TEXT,
    status TEXT CHECK (status IN ('preliminary','confirmed','cancelled')) DEFAULT 'preliminary',
    confirm_date DATE,
    confirm_by UUID,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, report_no)
);

CREATE TRIGGER clinic_infection_report_updated_at BEFORE UPDATE ON public.clinic_infection_report FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 12.5 死亡报卡
CREATE TABLE IF NOT EXISTS public.clinic_death_report (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT,
    report_no TEXT NOT NULL,
    death_date TIMESTAMPTZ NOT NULL,
    death_place TEXT CHECK (death_place IN ('hospital','home','other')) NOT NULL,
    death_cause_immediate TEXT NOT NULL,
    death_cause_immediate_icd TEXT,
    death_cause_underlying TEXT,
    death_cause_underlying_icd TEXT,
    death_cause_contributory TEXT[],
    diagnosis_basis TEXT,
    deceased_info JSONB -- 死者信息,
    informant_info JSONB -- 报告人信息,
    dept_id UUID,
    doctor_id UUID NOT NULL,
    status TEXT CHECK (status IN ('preliminary','confirmed','cancelled')) DEFAULT 'preliminary',
    confirm_date DATE,
    confirm_by UUID,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, report_no)
);

CREATE TRIGGER clinic_death_report_updated_at BEFORE UPDATE ON public.clinic_death_report FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 12.6 随访管理
CREATE TABLE IF NOT EXISTS public.clinic_followup (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    pat_id UUID NOT NULL REFERENCES public.pat_master(id),
    visit_sn TEXT,
    followup_no TEXT NOT NULL,
    followup_type TEXT CHECK (followup_type IN ('disease','surgery','chemotherapy','radiotherapy','rehab','other')) NOT NULL,
    disease_name TEXT,
    disease_code TEXT,
    dept_id UUID,
    doctor_id UUID NOT NULL,
    followup_date DATE NOT NULL,
    followup_method TEXT CHECK (followup_method IN ('phone','outpatient','home_visit','letter','internet')) NOT NULL,
    followup_result TEXT,
    disease_status TEXT CHECK (disease_status IN ('cured','remission','stable','progress','relapse','death','unknown')),
    survival_status TEXT CHECK (survival_status IN ('alive','dead','lost')) DEFAULT 'alive',
    survival_months INTEGER,
    physical_exam JSONB,
    lab_results JSONB,
    imaging_results JSONB,
    treatment_response TEXT,
    adverse_events JSONB,
    next_followup_date DATE,
    next_followup_type TEXT,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, followup_no)
);

CREATE TRIGGER clinic_followup_updated_at BEFORE UPDATE ON public.clinic_followup FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 13. 系统管理模块 (sys_*)
-- ============================================================

-- 13.1 参数配置表
CREATE TABLE IF NOT EXISTS public.sys_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    config_key TEXT NOT NULL,
    config_value TEXT,
    config_type TEXT CHECK (config_type IN ('string','number','boolean','json','xml')) DEFAULT 'string',
    config_group TEXT,
    config_name TEXT NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_system BOOLEAN DEFAULT FALSE,
    is_editable BOOLEAN DEFAULT TRUE,
    status TEXT DEFAULT 'active',
    effective_date DATE,
    expire_date DATE,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, config_key)
);

CREATE TRIGGER sys_config_updated_at BEFORE UPDATE ON public.sys_config FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 13.2 操作日志
CREATE TABLE IF NOT EXISTS public.sys_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    log_no TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    user_name TEXT,
    emp_id UUID,
    emp_name TEXT,
    ip_address TEXT,
    mac_address TEXT,
    module_code TEXT,
    module_name TEXT,
    action_type TEXT CHECK (action_type IN ('login','logout','query','create','update','delete','execute','export','import','approve','reject','other')) NOT NULL,
    action_table TEXT,
    action_table_id UUID,
    action_detail JSONB,
    before_value JSONB,
    after_value JSONB,
    result TEXT CHECK (result IN ('success','failure','partial')) DEFAULT 'success',
    error_message TEXT,
    session_id TEXT,
    user_agent TEXT,
    request_url TEXT,
    request_method TEXT,
    execution_time INTEGER -- 执行时间（毫秒）,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, log_no)
);

CREATE TRIGGER sys_audit_log_updated_at BEFORE UPDATE ON public.sys_audit_log FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 13.3 消息队列
CREATE TABLE IF NOT EXISTS public.sys_message (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    message_no TEXT NOT NULL,
    message_type TEXT CHECK (message_type IN ('notification','alert','task','reminder','approval','system')) NOT NULL,
    priority TEXT CHECK (priority IN ('low','normal','high','urgent')) DEFAULT 'normal',
    title TEXT NOT NULL,
    content TEXT,
    sender_id UUID,
    sender_name TEXT,
    sender_type TEXT DEFAULT 'system',
    receiver_id UUID NOT NULL,
    receiver_name TEXT,
    receiver_type TEXT DEFAULT 'user',
    related_module TEXT,
    related_id UUID,
    action_url TEXT,
    expire_time TIMESTAMPTZ,
    read_time TIMESTAMPTZ,
    is_read BOOLEAN DEFAULT FALSE,
    read_platform TEXT,
    is_starred BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'sent',
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, message_no)
);

CREATE TRIGGER sys_message_updated_at BEFORE UPDATE ON public.sys_message FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 13.4 数据字典（通用）
CREATE TABLE IF NOT EXISTS public.sys_dict (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID DEFAULT '00000000-0000-0000-0000-000000000001',
    dict_type TEXT NOT NULL,
    dict_code TEXT NOT NULL,
    dict_label TEXT NOT NULL,
    dict_value TEXT NOT NULL,
    sort_order INTEGER DEFAULT 0,
    is_default BOOLEAN DEFAULT FALSE,
    is_enabled BOOLEAN DEFAULT TRUE,
    css_class TEXT,
    list_class TEXT,
    remarks TEXT,
    create_time TIMESTAMPTZ DEFAULT NOW(),
    update_time TIMESTAMPTZ DEFAULT NOW(),
    create_by UUID,
    update_by UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    UNIQUE(org_id, dict_type, dict_code)
);

CREATE TRIGGER sys_dict_updated_at BEFORE UPDATE ON public.sys_dict FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 索引（针对高频查询和大数据量表）
-- ============================================================

-- 患者索引（优化）
CREATE INDEX idx_pat_master_pat_index_no ON public.pat_master(pat_index_no) WHERE NOT is_deleted;
CREATE INDEX idx_pat_master_name ON public.pat_master(name) WHERE NOT is_deleted;
CREATE INDEX idx_pat_master_id_card ON public.pat_master(id_card) WHERE NOT is_deleted;
CREATE INDEX idx_pat_master_phone ON public.pat_master(phone) WHERE NOT is_deleted;
CREATE INDEX idx_pat_master_insurance_no ON public.pat_master(insurance_no) WHERE NOT is_deleted;

-- 员工索引
CREATE INDEX idx_hr_employee_org_dept ON public.hr_employee(org_id, dept_id) WHERE NOT is_deleted;
CREATE INDEX idx_hr_employee_status ON public.hr_employee(status) WHERE NOT is_deleted;
CREATE INDEX idx_hr_employee_emp_no ON public.hr_employee(emp_no) WHERE NOT is_deleted;

-- 门诊索引
CREATE INDEX idx_op_registration_org_date ON public.op_registration(org_id, visit_date) WHERE NOT is_deleted;
CREATE INDEX idx_op_registration_pat ON public.op_registration(pat_id) WHERE NOT is_deleted;
CREATE INDEX idx_op_registration_reg_no ON public.op_registration(reg_no) WHERE NOT is_deleted;
CREATE INDEX idx_op_registration_visit_sn ON public.op_registration(visit_sn) WHERE NOT is_deleted;
CREATE INDEX idx_op_registration_status ON public.op_registration(status) WHERE NOT is_deleted;
CREATE INDEX idx_op_visit_pat_sn ON public.op_visit(pat_id, visit_sn) WHERE NOT is_deleted;
CREATE INDEX idx_op_prescription_visit_sn ON public.op_prescription(visit_sn) WHERE NOT is_deleted;
CREATE INDEX idx_op_charge_pat_date ON public.op_charge(pat_id, create_time) WHERE NOT is_deleted;

-- 住院索引
CREATE INDEX idx_ip_admission_pat ON public.ip_admission(pat_id) WHERE NOT is_deleted;
CREATE INDEX idx_ip_admission_admission_no ON public.ip_admission(admission_no) WHERE NOT is_deleted;
CREATE INDEX idx_ip_admission_status ON public.ip_admission(status) WHERE NOT is_deleted;
CREATE INDEX idx_ip_admission_date ON public.ip_admission(admission_time) WHERE NOT is_deleted;
CREATE INDEX idx_ip_long_order_adm ON public.ip_long_order(admission_id) WHERE NOT is_deleted;
CREATE INDEX idx_ip_long_order_status ON public.ip_long_order(order_status) WHERE NOT is_deleted;
CREATE INDEX idx_ip_charge_adm_date ON public.ip_charge(admission_id, bill_date) WHERE NOT is_deleted;
CREATE INDEX idx_ip_blood_transfusion_adm ON public.ip_blood_transfusion(admission_id) WHERE NOT is_deleted;

-- 药品索引
CREATE INDEX idx_pha_drug_batch_expire ON public.pha_drug_batch(expire_date) WHERE NOT is_deleted;
CREATE INDEX idx_pha_pharmacy_stock ON public.pha_pharmacy_stock(pharmacy_dept_id, drug_id) WHERE NOT is_deleted;
CREATE INDEX idx_pha_drug_national_code ON public.md_drug(national_code) WHERE NOT is_deleted;

-- 检验检查索引
CREATE INDEX idx_lis_request_pat_sn ON public.lis_request(pat_id, visit_sn) WHERE NOT is_deleted;
CREATE INDEX idx_lis_request_date ON public.lis_request(create_time) WHERE NOT is_deleted;
CREATE INDEX idx_lis_result_request ON public.lis_result(request_id) WHERE NOT is_deleted;
CREATE INDEX idx_ris_request_pat_sn ON public.ris_request(pat_id, visit_sn) WHERE NOT is_deleted;
CREATE INDEX idx_ris_request_date ON public.ris_request(create_time) WHERE NOT is_deleted;
CREATE INDEX idx_ris_report_request ON public.ris_report(request_id) WHERE NOT is_deleted;

-- 手术索引
CREATE INDEX idx_opt_schedule_date ON public.opt_surgery_schedule(surgery_date) WHERE NOT is_deleted;
CREATE INDEX idx_opt_surgery_request_pat ON public.opt_surgery_request(pat_id) WHERE NOT is_deleted;

-- 费用索引
CREATE INDEX idx_fee_settlement_pat ON public.fee_settlement(pat_id) WHERE NOT is_deleted;
CREATE INDEX idx_fee_invoice_org ON public.fee_invoice(org_id, invoice_no) WHERE NOT is_deleted;
CREATE INDEX idx_op_consultation_visit_sn ON public.op_consultation(visit_sn) WHERE NOT is_deleted;

-- 物资索引
CREATE INDEX idx_msd_apply_dept ON public.msd_apply(dept_id) WHERE NOT is_deleted;

-- ============================================================
-- RLS (行级安全策略)
-- ============================================================

-- 启用 RLS（扩展关键敏感表）
ALTER TABLE public.pat_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.op_registration ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.op_visit ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.op_prescription ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ip_admission ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ip_long_order ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ip_charge ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lis_request ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lis_result ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ris_request ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ris_report ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sys_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hr_employee ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hr_doctor_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pat_allergy ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.op_consultation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.op_prescription_flow ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ip_blood_transfusion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pha_adr_report ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pha_nutrition_solution ENABLE ROW LEVEL SECURITY;

-- 管理员可以访问所有数据
CREATE POLICY "admin_full_access" ON public.pat_master FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.op_registration FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.op_visit FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.op_prescription FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.ip_admission FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.ip_long_order FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.ip_charge FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.lis_request FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.lis_result FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.ris_request FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.ris_report FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.sys_audit_log FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.hr_employee FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.hr_doctor_info FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.pat_allergy FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.op_consultation FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.op_prescription_flow FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.ip_blood_transfusion FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.pha_adr_report FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "admin_full_access" ON public.pha_nutrition_solution FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'admin');

-- 所有认证用户可以读取患者表（用于诊疗）
CREATE POLICY "authenticated_read_patients" ON public.pat_master FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_read_patients" ON public.pat_allergy FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_read_patients" ON public.pat_medical_history FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_read_patients" ON public.pat_contact FOR SELECT USING (auth.role() = 'authenticated');

-- 员工信息：本人可读，管理可写
CREATE POLICY "employee_self_read" ON public.hr_employee FOR SELECT USING (auth.uid() = id OR (SELECT auth.jwt() ->> 'role') = 'admin');
CREATE POLICY "employee_self_read" ON public.hr_doctor_info FOR SELECT USING (EXISTS (SELECT 1 FROM public.hr_employee WHERE hr_employee.id = auth.uid() AND (hr_employee.id = emp_id OR (SELECT auth.jwt() ->> 'role') = 'admin')));

-- 所有认证用户可以读取字典表
CREATE POLICY "authenticated_read_dicts" ON public.org_dept FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_read_dicts" ON public.md_drug FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_read_dicts" ON public.md_charge_item FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_read_dicts" ON public.md_lis_item FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_read_dicts" ON public.md_ris_item FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_read_dicts" ON public.md_icd10 FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "authenticated_read_dicts" ON public.sys_dict FOR SELECT USING (auth.role() = 'authenticated');

-- 医生可以读写自己的诊疗数据
CREATE POLICY "doctor_self_access" ON public.op_visit FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'doctor' AND doctor_id = auth.uid());
CREATE POLICY "doctor_self_access" ON public.op_prescription FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'doctor' AND doctor_id = auth.uid());
CREATE POLICY "doctor_self_access" ON public.op_diagnosis FOR ALL USING ((SELECT auth.jwt() ->> 'role') = 'doctor' AND diagnosis_doctor_id = auth.uid());

-- 护士可以读写挂号、住院相关数据
CREATE POLICY "nurse_access" ON public.op_registration FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('nurse', 'admin'));
CREATE POLICY "nurse_access" ON public.op_triage FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('nurse', 'admin'));
CREATE POLICY "nurse_access" ON public.ip_admission FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('nurse', 'admin'));
CREATE POLICY "nurse_access" ON public.ip_nursing_record FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('nurse', 'admin'));
CREATE POLICY "nurse_access" ON public.ip_temperature_sheet FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('nurse', 'admin'));
CREATE POLICY "nurse_access" ON public.op_consultation FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('nurse', 'admin'));
CREATE POLICY "nurse_access" ON public.ip_blood_transfusion FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('nurse', 'admin'));
CREATE POLICY "nurse_access" ON public.pha_nutrition_solution FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('nurse', 'admin'));

-- 检验师可以读写检验相关数据
CREATE POLICY "lab_tech_access" ON public.lis_request FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('lab_tech', 'admin'));
CREATE POLICY "lab_tech_access" ON public.lis_result FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('lab_tech', 'admin'));
CREATE POLICY "lab_tech_access" ON public.lis_critical_value FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('lab_tech', 'admin'));

-- 放射技师可以读写影像相关数据
CREATE POLICY "radiology_tech_access" ON public.ris_request FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('radiology_tech', 'admin'));
CREATE POLICY "radiology_tech_access" ON public.ris_report FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('radiology_tech', 'admin'));

-- 药师可以读写处方、药品数据
CREATE POLICY "pharmacist_access" ON public.op_prescription FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('pharmacist', 'admin'));
CREATE POLICY "pharmacist_access" ON public.pha_op_dispense FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('pharmacist', 'admin'));
CREATE POLICY "pharmacist_access" ON public.pha_controlled_drug_account FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('pharmacist', 'admin'));
CREATE POLICY "pharmacist_access" ON public.op_prescription_flow FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('pharmacist', 'admin'));
CREATE POLICY "pharmacist_access" ON public.pha_adr_report FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('pharmacist', 'admin', 'doctor'));
CREATE POLICY "pharmacist_access" ON public.pha_nutrition_solution FOR ALL USING ((SELECT auth.jwt() ->> 'role') IN ('pharmacist', 'admin'));

-- ============================================================
-- 用户注册触发器：自动创建 hr_employee
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.hr_employee (id, emp_no, name, emp_type)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'employee_no', NEW.id::TEXT),
        COALESCE(NEW.raw_user_meta_data->>'real_name', '新用户'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'other')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 完整权限授予（确保 service_role 可以访问）
-- ============================================================
GRANT USAGE ON SCHEMA public TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
