-- ============================================================
-- 文贤HIS数据库建表脚本
-- Supabase PostgreSQL
-- ============================================================

-- 启用 UUID 生成
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. 扩展 auth.users 的用户配置表
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users_profile (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    real_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'doctor', 'nurse', 'lab_tech', 'radiology_tech', 'pharmacist')),
    department_id UUID,
    employee_no TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 触发器：自动更新 updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_profile_updated_at
    BEFORE UPDATE ON public.users_profile
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 2. 科室表
-- ============================================================
CREATE TABLE IF NOT EXISTS public.departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. 患者表
-- ============================================================
CREATE TABLE IF NOT EXISTS public.patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('男', '女')),
    birth_date DATE NOT NULL,
    id_card TEXT NOT NULL UNIQUE,
    phone TEXT,
    address TEXT,
    blood_type TEXT,
    allergy_history TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER patients_updated_at
    BEFORE UPDATE ON public.patients
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 4. 挂号表
-- ============================================================
CREATE TABLE IF NOT EXISTS public.registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id),
    department_id UUID NOT NULL REFERENCES public.departments(id),
    doctor_id UUID REFERENCES public.users_profile(id),
    registration_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sequence_no INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'finished', 'cancelled')),
    registration_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
    visit_type TEXT NOT NULL DEFAULT 'first' CHECK (visit_type IN ('first', 'return')),
    complaint TEXT,
    payment_status TEXT NOT NULL DEFAULT 'paid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER registrations_updated_at
    BEFORE UPDATE ON public.registrations
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 4b. 挂号费标准
-- ============================================================
CREATE TABLE IF NOT EXISTS public.registration_fees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID REFERENCES public.departments(id),
    visit_type TEXT NOT NULL CHECK (visit_type IN ('first', 'return')),
    fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(department_id, visit_type)
);

-- ============================================================
-- 5. 门诊就诊记录
-- ============================================================
CREATE TABLE IF NOT EXISTS public.outpatient_visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_id UUID REFERENCES public.registrations(id),
    patient_id UUID NOT NULL REFERENCES public.patients(id),
    doctor_id UUID REFERENCES public.users_profile(id),
    visit_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    chief_complaint TEXT,
    present_illness TEXT,
    diagnosis TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER outpatient_visits_updated_at
    BEFORE UPDATE ON public.outpatient_visits
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 6. 处方表
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prescriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID REFERENCES public.outpatient_visits(id),
    patient_id UUID NOT NULL REFERENCES public.patients(id),
    doctor_id UUID REFERENCES public.users_profile(id),
    prescription_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'dispensed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER prescriptions_updated_at
    BEFORE UPDATE ON public.prescriptions
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 7. 药品字典
-- ============================================================
CREATE TABLE IF NOT EXISTS public.drugs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    spec TEXT,
    unit TEXT,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    stock INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER drugs_updated_at
    BEFORE UPDATE ON public.drugs
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 8. 处方明细
-- ============================================================
CREATE TABLE IF NOT EXISTS public.prescription_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prescription_id UUID NOT NULL REFERENCES public.prescriptions(id) ON DELETE CASCADE,
    drug_id UUID NOT NULL REFERENCES public.drugs(id),
    dosage TEXT NOT NULL,
    usage TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 9. 检验项目字典
-- ============================================================
CREATE TABLE IF NOT EXISTS public.test_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    category TEXT,
    reference_value TEXT,
    unit TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 10. 检验申请
-- ============================================================
CREATE TABLE IF NOT EXISTS public.lab_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID REFERENCES public.outpatient_visits(id),
    encounter_id UUID,  -- 住院记录外键（简化版暂不关联）
    patient_id UUID NOT NULL REFERENCES public.patients(id),
    doctor_id UUID REFERENCES public.users_profile(id),
    test_item_id UUID NOT NULL REFERENCES public.test_items(id),
    specimen_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sampled', 'testing', 'reported', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER lab_requests_updated_at
    BEFORE UPDATE ON public.lab_requests
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 11. 检验结果
-- ============================================================
CREATE TABLE IF NOT EXISTS public.lab_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lab_request_id UUID NOT NULL REFERENCES public.lab_requests(id),
    test_item_id UUID NOT NULL REFERENCES public.test_items(id),
    result_value TEXT,
    reference_range TEXT,
    is_abnormal BOOLEAN DEFAULT FALSE,
    entered_by UUID REFERENCES public.users_profile(id),
    entered_at TIMESTAMPTZ,
    verified_by UUID REFERENCES public.users_profile(id),
    verified_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'entered' CHECK (status IN ('entered', 'verified')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER lab_results_updated_at
    BEFORE UPDATE ON public.lab_results
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 12. 影像检查申请
-- ============================================================
CREATE TABLE IF NOT EXISTS public.imaging_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID REFERENCES public.outpatient_visits(id),
    patient_id UUID NOT NULL REFERENCES public.patients(id),
    doctor_id UUID REFERENCES public.users_profile(id),
    exam_type TEXT NOT NULL CHECK (exam_type IN ('CT', 'MR', 'X-Ray', '超声')),
    exam_part TEXT NOT NULL,
    clinical_diagnosis TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'registered', 'imaging', 'reported', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER imaging_requests_updated_at
    BEFORE UPDATE ON public.imaging_requests
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 13. 影像检查记录
-- ============================================================
CREATE TABLE IF NOT EXISTS public.imaging_studies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    imaging_request_id UUID NOT NULL REFERENCES public.imaging_requests(id),
    patient_id UUID NOT NULL REFERENCES public.patients(id),
    technician_id UUID REFERENCES public.users_profile(id),
    exam_time TIMESTAMPTZ,
    image_urls TEXT[] DEFAULT '{}',
    report_content TEXT,
    report_doctor_id UUID REFERENCES public.users_profile(id),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'reported')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER imaging_studies_updated_at
    BEFORE UPDATE ON public.imaging_studies
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 14. 床位表
-- ============================================================
CREATE TABLE IF NOT EXISTS public.beds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    department_id UUID NOT NULL REFERENCES public.departments(id),
    bed_no TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'maintenance')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(department_id, bed_no)
);

CREATE TRIGGER beds_updated_at
    BEFORE UPDATE ON public.beds
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 15. 住院记录
-- ============================================================
CREATE TABLE IF NOT EXISTS public.inpatient_encounters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id),
    admission_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    discharge_time TIMESTAMPTZ,
    bed_id UUID REFERENCES public.beds(id),
    diagnosis TEXT,
    status TEXT NOT NULL DEFAULT 'admitted' CHECK (status IN ('admitted', 'discharged')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER inpatient_encounters_updated_at
    BEFORE UPDATE ON public.inpatient_encounters
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 16. 通用医嘱表
-- ============================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES public.patients(id),
    encounter_id UUID REFERENCES public.inpatient_encounters(id),
    visit_id UUID REFERENCES public.outpatient_visits(id),
    order_type TEXT NOT NULL CHECK (order_type IN ('prescription', 'lab', 'imaging')),
    order_content JSONB NOT NULL,
    ordered_by UUID NOT NULL REFERENCES public.users_profile(id),
    ordered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'executed', 'cancelled', 'completed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 用户注册触发器：自动创建 users_profile
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users_profile (id, real_name, role, employee_no)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'real_name', '新用户'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'doctor'),
        NEW.raw_user_meta_data->>'employee_no'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 索引
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_patients_name ON public.patients(name);
CREATE INDEX IF NOT EXISTS idx_patients_id_card ON public.patients(id_card);
CREATE INDEX IF NOT EXISTS idx_registrations_patient ON public.registrations(patient_id);
CREATE INDEX IF NOT EXISTS idx_registrations_status ON public.registrations(status);
CREATE INDEX IF NOT EXISTS idx_outpatient_visits_patient ON public.outpatient_visits(patient_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_patient ON public.prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_status ON public.prescriptions(status);
CREATE INDEX IF NOT EXISTS idx_lab_requests_patient ON public.lab_requests(patient_id);
CREATE INDEX IF NOT EXISTS idx_lab_requests_status ON public.lab_requests(status);
CREATE INDEX IF NOT EXISTS idx_lab_results_request ON public.lab_results(lab_request_id);
CREATE INDEX IF NOT EXISTS idx_imaging_requests_patient ON public.imaging_requests(patient_id);
CREATE INDEX IF NOT EXISTS idx_imaging_studies_request ON public.imaging_studies(imaging_request_id);
CREATE INDEX IF NOT EXISTS idx_inpatient_encounters_patient ON public.inpatient_encounters(patient_id);
CREATE INDEX IF NOT EXISTS idx_inpatient_encounters_status ON public.inpatient_encounters(status);
CREATE INDEX IF NOT EXISTS idx_beds_department ON public.beds(department_id);
CREATE INDEX IF NOT EXISTS idx_orders_patient ON public.orders(patient_id);

-- ============================================================
-- RLS (行级安全策略)
-- ============================================================

-- 启用 RLS
ALTER TABLE public.users_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outpatient_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescription_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lab_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lab_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.imaging_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.imaging_studies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.beds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inpatient_encounters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- 管理员可以访问所有数据
CREATE POLICY "admin_full_access" ON public.users_profile
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.departments
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.patients
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.registrations
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.outpatient_visits
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.prescriptions
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.prescription_items
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.drugs
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.test_items
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.lab_requests
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.lab_results
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.imaging_requests
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.imaging_studies
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.beds
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.inpatient_encounters
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "admin_full_access" ON public.orders
    FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- 医生可以读写自己的诊疗数据
CREATE POLICY "doctor_self_access" ON public.outpatient_visits
    FOR ALL USING (
        (auth.jwt() ->> 'role' = 'doctor') AND
        (doctor_id = (SELECT id FROM public.users_profile WHERE id = auth.uid()))
    );

CREATE POLICY "doctor_self_access" ON public.prescriptions
    FOR ALL USING (
        (auth.jwt() ->> 'role' = 'doctor') AND
        (doctor_id = (SELECT id FROM public.users_profile WHERE id = auth.uid()))
    );

CREATE POLICY "doctor_read_access" ON public.lab_results
    FOR SELECT USING (auth.jwt() ->> 'role' IN ('doctor', 'admin'));

CREATE POLICY "doctor_read_access" ON public.imaging_studies
    FOR SELECT USING (auth.jwt() ->> 'role' IN ('doctor', 'admin'));

-- 护士可以读写挂号、住院相关数据
CREATE POLICY "nurse_access" ON public.registrations
    FOR ALL USING (auth.jwt() ->> 'role' IN ('nurse', 'admin'));

CREATE POLICY "nurse_access" ON public.inpatient_encounters
    FOR ALL USING (auth.jwt() ->> 'role' IN ('nurse', 'admin'));

CREATE POLICY "nurse_access" ON public.beds
    FOR SELECT USING (auth.jwt() ->> 'role' IN ('nurse', 'admin'));

-- 检验师可以读写检验相关数据
CREATE POLICY "lab_tech_access" ON public.lab_requests
    FOR ALL USING (auth.jwt() ->> 'role' IN ('lab_tech', 'admin'));

CREATE POLICY "lab_tech_access" ON public.lab_results
    FOR ALL USING (auth.jwt() ->> 'role' IN ('lab_tech', 'admin'));

-- 放射技师可以读写影像相关数据
CREATE POLICY "radiology_tech_access" ON public.imaging_requests
    FOR ALL USING (auth.jwt() ->> 'role' IN ('radiology_tech', 'admin'));

CREATE POLICY "radiology_tech_access" ON public.imaging_studies
    FOR ALL USING (auth.jwt() ->> 'role' IN ('radiology_tech', 'admin'));

-- 药师可以读写处方、药品数据
CREATE POLICY "pharmacist_access" ON public.prescriptions
    FOR ALL USING (auth.jwt() ->> 'role' IN ('pharmacist', 'admin'));

CREATE POLICY "pharmacist_access" ON public.drugs
    FOR SELECT USING (auth.jwt() ->> 'role' IN ('pharmacist', 'admin'));

-- 所有认证用户可以读取患者表（用于诊疗）
CREATE POLICY "authenticated_read_patients" ON public.patients
    FOR SELECT USING (auth.role() = 'authenticated');

-- 所有认证用户可以读取科室和字典表
CREATE POLICY "authenticated_read_departments" ON public.departments
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "authenticated_read_drugs" ON public.drugs
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "authenticated_read_test_items" ON public.test_items
    FOR SELECT USING (auth.role() = 'authenticated');

-- ============================================================
-- 存储桶设置 (通过 Supabase Dashboard 或以下SQL)
-- ============================================================
-- 注意：在 Supabase Dashboard 中手动创建以下存储桶：
-- 1. pacs-images (公开)
-- 2. pacs-reports (公开)
--
-- 或使用以下代码通过 API 创建：
/*
INSERT INTO storage.buckets (id, name, public)
VALUES ('pacs-images', 'pacs-images', true),
       ('pacs-reports', 'pacs-reports', true);
*/

-- 存储桶 RLS 策略
CREATE POLICY "public_read_pacs_images" ON storage.objects
    FOR SELECT USING (bucket_id = 'pacs-images');

CREATE POLICY "public_upload_pacs_images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'pacs-images');

CREATE POLICY "public_update_pacs_images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'pacs-images');

-- ============================================================
-- 种子数据
-- ============================================================

-- 科室
INSERT INTO public.departments (id, name, code) VALUES
    ('da000000-0000-0000-0000-000000000001', '内科', 'INT'),
    ('da000000-0000-0000-0000-000000000002', '外科', 'SUR'),
    ('da000000-0000-0000-0000-000000000003', '儿科', 'PED'),
    ('da000000-0000-0000-0000-000000000004', '妇产科', 'OBS'),
    ('da000000-0000-0000-0000-000000000005', '检验科', 'LAB'),
    ('da000000-0000-0000-0000-000000000006', '放射科', 'RAD'),
    ('da000000-0000-0000-0000-000000000007', '急诊科', 'ER'),
    ('da000000-0000-0000-0000-000000000008', '麻醉科', 'ANE')
ON CONFLICT (code) DO NOTHING;

-- 挂号费标准 (初诊10元，复诊5元)
-- 注意：实际数据库中 department_id 为 d1000000-... 格式
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'first', 10.00 FROM public.departments WHERE code = 'INT'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'return', 5.00 FROM public.departments WHERE code = 'INT'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'first', 10.00 FROM public.departments WHERE code = 'SUR'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'return', 5.00 FROM public.departments WHERE code = 'SUR'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'first', 10.00 FROM public.departments WHERE code = 'PED'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'return', 5.00 FROM public.departments WHERE code = 'PED'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'first', 10.00 FROM public.departments WHERE code = 'OBS'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'return', 5.00 FROM public.departments WHERE code = 'OBS'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'first', 10.00 FROM public.departments WHERE code = 'LAB'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'return', 5.00 FROM public.departments WHERE code = 'LAB'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'first', 10.00 FROM public.departments WHERE code = 'RAD'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'return', 5.00 FROM public.departments WHERE code = 'RAD'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'first', 10.00 FROM public.departments WHERE code = 'ER'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'return', 5.00 FROM public.departments WHERE code = 'ER'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'first', 10.00 FROM public.departments WHERE code = 'ANE'
ON CONFLICT (department_id, visit_type) DO NOTHING;
INSERT INTO public.registration_fees (department_id, visit_type, fee)
SELECT id, 'return', 5.00 FROM public.departments WHERE code = 'ANE'
ON CONFLICT (department_id, visit_type) DO NOTHING;

-- 药品
INSERT INTO public.drugs (id, name, spec, unit, price, stock) VALUES
    ('ca000000-0000-0000-0000-000000000001', '阿莫西林胶囊', '0.25g*24粒', '盒', 18.50, 500),
    ('ca000000-0000-0000-0000-000000000002', '布洛芬片', '0.2g*20片', '盒', 8.00, 800),
    ('ca000000-0000-0000-0000-000000000003', '氨溴索口服液', '100ml', '瓶', 25.00, 200),
    ('ca000000-0000-0000-0000-000000000004', '头孢克肟分散片', '0.1g*6片', '盒', 35.00, 300),
    ('ca000000-0000-0000-0000-000000000005', '维生素C片', '100mg*100片', '瓶', 5.00, 1000),
    ('ca000000-0000-0000-0000-000000000006', '氯雷他定片', '10mg*12片', '盒', 15.00, 400),
    ('ca000000-0000-0000-0000-000000000007', '奥美拉唑肠溶胶囊', '20mg*14粒', '盒', 22.00, 350),
    ('ca000000-0000-0000-0000-000000000008', '蒙脱石散', '3g*10袋', '盒', 28.00, 250),
    ('ca000000-0000-0000-0000-000000000009', '复方甘草片', '100片', '瓶', 6.00, 600),
    ('ca000000-0000-0000-0000-000000000010', '地氯雷他定片', '5mg*12片', '盒', 28.00, 300)
ON CONFLICT DO NOTHING;

-- 检验项目
INSERT INTO public.test_items (id, name, code, category, reference_value, unit) VALUES
    ('ta000000-0000-0000-0000-000000000001', '血常规', 'CBC', '血液', NULL, NULL),
    ('ta000000-0000-0000-0000-000000000002', '尿常规', 'URT', '尿液', NULL, NULL),
    ('ta000000-0000-0000-0000-000000000003', '肝功能', 'LFT', '血液', NULL, NULL),
    ('ta000000-0000-0000-0000-000000000004', '肾功能', 'RFT', '血液', NULL, NULL),
    ('ta000000-0000-0000-0000-000000000005', '血糖', 'GLU', '血液', '3.9-6.1', 'mmol/L'),
    ('ta000000-0000-0000-0000-000000000006', '血脂', 'LIP', '血液', NULL, NULL),
    ('ta000000-0000-0000-0000-000000000007', '凝血功能', 'COAG', '血液', NULL, NULL),
    ('ta000000-0000-0000-0000-000000000008', '电解质', 'ELY', '血液', NULL, NULL),
    ('ta000000-0000-0000-0000-000000000009', '乙肝两对半', 'HBV', '血液', NULL, NULL),
    ('ta000000-0000-0000-0000-000000000010', '甲状腺功能', 'THY', '血液', NULL, NULL)
ON CONFLICT (code) DO NOTHING;

-- 床位
INSERT INTO public.beds (id, department_id, bed_no, status) VALUES
    ('ba000000-0000-0000-0000-000000000001', 'da000000-0000-0000-0000-000000000001', '101', 'available'),
    ('ba000000-0000-0000-0000-000000000002', 'da000000-0000-0000-0000-000000000001', '102', 'available'),
    ('ba000000-0000-0000-0000-000000000003', 'da000000-0000-0000-0000-000000000001', '103', 'available'),
    ('ba000000-0000-0000-0000-000000000004', 'da000000-0000-0000-0000-000000000001', '104', 'available'),
    ('ba000000-0000-0000-0000-000000000005', 'da000000-0000-0000-0000-000000000002', '201', 'available'),
    ('ba000000-0000-0000-0000-000000000006', 'da000000-0000-0000-0000-000000000002', '202', 'available'),
    ('ba000000-0000-0000-0000-000000000007', 'da000000-0000-0000-0000-000000000002', '203', 'available'),
    ('ba000000-0000-0000-0000-000000000008', 'da000000-0000-0000-0000-000000000003', '301', 'available'),
    ('ba000000-0000-0000-0000-000000000009', 'da000000-0000-0000-0000-000000000003', '302', 'available'),
    ('ba000000-0000-0000-0000-000000000010', 'da000000-0000-0000-0000-000000000004', '401', 'available')
ON CONFLICT DO NOTHING;

-- 测试患者
INSERT INTO public.patients (id, name, gender, birth_date, id_card, phone, address, blood_type, allergy_history) VALUES
    ('pa000000-0000-0000-0000-000000000001', '张三', '男', '1985-06-15', '310101198506151234', '13800138001', '上海市浦东新区张江路100号', 'A', '青霉素'),
    ('pa000000-0000-0000-0000-000000000002', '李四', '女', '1990-03-22', '310101199003221234', '13800138002', '上海市徐汇区漕溪北路200号', 'B', NULL),
    ('pa000000-0000-0000-0000-000000000003', '王五', '男', '1978-11-08', '310101197811081234', '13800138003', '上海市静安区南京西路300号', 'O', '磺胺类'),
    ('pa000000-0000-0000-0000-000000000004', '赵六', '女', '1995-07-30', '310101199507301234', '13800138004', '上海市长宁区延安西路500号', 'AB', '花粉'),
    ('pa000000-0000-0000-0000-000000000005', '钱七', '男', '1982-02-14', '310101198202141234', '13800138005', '上海市杨浦区国定路100号', 'A', NULL)
ON CONFLICT (id_card) DO NOTHING;

-- ============================================================
-- 演示用户（通过 Supabase Auth 注册后自动创建 profiles）
-- ============================================================
-- 在 Supabase Dashboard 的 Authentication 中创建以下用户：
--
-- 1. doctor@his.local / password123 (医生 - 内科)
-- 2. nurse@his.local / password123 (护士)
-- 3. labtech@his.local / password123 (检验师)
-- 4. radiology@his.local / password123 (放射技师)
-- 5. pharmacist@his.local / password123 (药师)
-- 6. admin@his.local / password123 (管理员)
--
-- 创建用户时，在 user metadata 中设置：
-- {
--   "real_name": "张医生",
--   "role": "doctor",
--   "employee_no": "D001",
--   "department_id": "d1000000-0000-0000-0000-000000000001"
-- }
--
-- 以下 SQL 可用于更新已创建用户的 profile：
/*
UPDATE public.users_profile SET
    real_name = CASE id
        WHEN (SELECT id FROM auth.users WHERE email = 'doctor@his.local') THEN '张医生'
        WHEN (SELECT id FROM auth.users WHERE email = 'nurse@his.local') THEN '李护士'
        WHEN (SELECT id FROM auth.users WHERE email = 'labtech@his.local') THEN '王检验'
        WHEN (SELECT id FROM auth.users WHERE email = 'radiology@his.local') THEN '赵技师'
        WHEN (SELECT id FROM auth.users WHERE email = 'pharmacist@his.local') THEN '钱药师'
        WHEN (SELECT id FROM auth.users WHERE email = 'admin@his.local') THEN '系统管理员'
    END,
    role = CASE id
        WHEN (SELECT id FROM auth.users WHERE email = 'doctor@his.local') THEN 'doctor'
        WHEN (SELECT id FROM auth.users WHERE email = 'nurse@his.local') THEN 'nurse'
        WHEN (SELECT id FROM auth.users WHERE email = 'labtech@his.local') THEN 'lab_tech'
        WHEN (SELECT id FROM auth.users WHERE email = 'radiology@his.local') THEN 'radiology_tech'
        WHEN (SELECT id FROM auth.users WHERE email = 'pharmacist@his.local') THEN 'pharmacist'
        WHEN (SELECT id FROM auth.users WHERE email = 'admin@his.local') THEN 'admin'
    END
WHERE id IN (
    SELECT id FROM auth.users WHERE email IN (
        'doctor@his.local', 'nurse@his.local', 'labtech@his.local',
        'radiology@his.local', 'pharmacist@his.local', 'admin@his.local'
    )
);
*/

-- ============================================================
-- 完整权限授予（确保 service_role 可以访问）
-- ============================================================
GRANT USAGE ON SCHEMA public TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
