// ============================================================
// 文贤HIS - TypeScript类型定义
// 匹配 supabase/schema.sql 数据库结构
// ============================================================

// User and Auth Types
export type UserRole = 'admin' | 'doctor' | 'nurse' | 'lab_tech' | 'radiology_tech' | 'pharmacist'

export interface UserProfile {
  id: string
  real_name: string
  role: UserRole
  department_id: string | null
  employee_no: string | null
  phone: string | null
  created_at: string
  updated_at: string
}

export interface AuthState {
  user: any | null
  profile: UserProfile | null
  loading: boolean
}

// ============================================================
// 1. 组织机构模块 (org_*)
// ============================================================

export interface OrgHospital {
  id: string
  code: string
  name: string
  short_name?: string
  hospital_level?: '三级甲等' | '三级乙等' | '二级甲等' | '二级乙等' | '一级' | '未定级'
  address?: string
  phone?: string
  status: 'active' | 'inactive' | 'suspended'
  sort_order: number
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface OrgDept {
  id: string
  org_id: string
  parent_id?: string
  code: string
  name: string
  dept_type: 'clinical' | 'medical_tech' | 'admin' | 'logistics'
  category?: string
  dept_level: number
  reg_fee: number
  status: 'active' | 'inactive'
  sort_order: number
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface OrgWard {
  id: string
  org_id: string
  dept_id: string
  ward_code: string
  ward_name: string
  ward_type?: 'general' | 'icu' | 'emergency' | 'observation'
  bed_count: number
  status: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface OrgNursingUnit {
  id: string
  org_id: string
  ward_id: string
  code: string
  name: string
  nurse_manager_id?: string
  status: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 2. 人员模块 (hr_*)
// ============================================================

export interface HrEmployee {
  id: string
  org_id: string
  emp_no: string
  name: string
  name_pinyin?: string
  gender: '男' | '女' | '未知'
  birth_date?: string
  id_card?: string
  phone?: string
  email?: string
  dept_id?: string
  emp_type: 'doctor' | 'nurse' | 'technician' | 'pharmacist' | 'admin' | 'other'
  title?: string
  professional_title?: string
  status: 'active' | 'inactive' | 'retired' | 'transferred'
  hire_date?: string
  leave_date?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface HrDoctorInfo {
  id: string
  emp_id: string
  license_no?: string
  license_type?: string
  license_scope?: string
  signature_url?: string
  signature_data?: string
  is_attending: boolean
  is_chief: boolean
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface HrSchedule {
  id: string
  org_id: string
  emp_id: string
  dept_id: string
  schedule_date: string
  shift_type: 'morning' | 'afternoon' | 'night' | 'day' | 'on_call'
  shift_start: string
  shift_end: string
  reg_quota: number
  reg_used: number
  status: 'active' | 'cancelled' | 'rest'
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 3. 基础字典模块 (md_*)
// ============================================================

export interface MdIcd10 {
  id: string
  code: string
  code_ext?: string
  name: string
  name_pinyin?: string
  name_english?: string
  disease_type?: 'disease' | 'syndrome' | 'injury' | 'poisoning' | 'external_cause' | 'neoplasm' | 'symptom'
  gender_limit?: 'male' | 'female' | 'both'
  age_limit_min?: number
  age_limit_max?: number
  is_chronic: boolean
  is_infectious: boolean
  reportable: boolean
  version: string
  effective_date?: string
  status: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface MdDrug {
  id: string
  org_id: string
  drug_code: string
  national_code?: string
  common_name: string
  product_name?: string
  english_name?: string
  pinyin?: string
  drug_type: 'western' | 'chinese' | 'biologic' | 'blood' | 'vaccine' | 'contrast'
  pharmacol_category?: string
  atc_code?: string
  spec: string
  unit: string
  package_unit?: string
  package_qty: number
  price: number
  price_ratio?: number
  dosage_form?: string
  route?: '口服' | '静脉注射' | '肌肉注射' | '皮下注射' | '皮内注射' | '外用' | '吸入' | '直肠' | '其他'
  frequency_code?: string
  unit_dose?: number
  unit_dose_unit?: string
  antibiotic_level?: 'non_antibiotic' | 'non_restricted' | 'restricted' | 'special'
  controlled_drug_level?: 'none' | 'psychotropic' | 'narcotic' | 'radioactive'
  anti_infective: boolean
  immune_modulator: boolean
  storage_temp?: string
  shelf_life_months?: number
  min_stock?: number
  max_stock?: number
  default_supplier?: string
  is_bacteriostatic: boolean
  is_essential: boolean
  medical_insurance: boolean
  reimbursement_category?: string
  status: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface MdChargeItem {
  id: string
  org_id: string
  item_code: string
  national_code?: string
  name: string
  pinyin?: string
  item_type: 'service' | 'material' | 'drug' | 'exam' | 'procedure' | 'bed' | 'nursing'
  category?: string
  spec?: string
  unit: string
  price: number
  consumable_type?: 'disposable' | 'reusable' | 'implant' | 'high_value'
  is_billable: boolean
  medical_insurance: boolean
  reimbursement_ratio?: number
  default_dept_id?: string
  execution_unit?: string
  parent_item_id?: string
  sort_order: number
  status: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface MdLisItem {
  id: string
  org_id: string
  item_code: string
  name: string
  pinyin?: string
  category?: string
  specimen_type?: string
  specimen_container?: string
  specimen_volume?: string
  collection_instruction?: string
  storage_condition?: string
  turnaround_hours?: number
  method?: string
  instrument?: string
  reference_range_low?: number
  reference_range_high?: number
  reference_range_text?: string
  unit?: string
  result_type: 'numeric' | 'text' | 'select' | 'formula'
  result_options?: any
  is_abnormal_alert: boolean
  critical_value_low?: string
  critical_value_high?: string
  price: number
  medical_insurance: boolean
  sort_order: number
  status: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface MdRisItem {
  id: string
  org_id: string
  item_code: string
  name: string
  pinyin?: string
  category?: string
  exam_body_part?: string
  exam_method?: string
  preparation_instruction?: string
  duration_minutes?: number
  has_contrast: boolean
  contrast_agent?: string
  report_template?: string
  image_count?: number
  has_dicom: boolean
  price: number
  medical_insurance: boolean
  dept_id?: string
  sort_order: number
  status: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface MdOrderItem {
  id: string
  org_id: string
  item_code: string
  name: string
  pinyin?: string
  order_type: 'drug' | 'lab' | 'exam' | 'procedure' | 'operation' | 'nursing' | 'diet' | 'bed' | 'other'
  category?: string
  spec?: string
  unit?: string
  default_dosage?: string
  default_usage?: string
  price?: number
  status: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 4. 患者管理模块 (pat_*)
// ============================================================

export interface PatMaster {
  id: string
  org_id: string
  pat_index_no: string
  name: string
  name_pinyin?: string
  gender: '男' | '女' | '未知'
  birth_date: string
  age?: number
  age_unit?: '岁' | '月' | '天'
  id_card?: string
  id_card_type?: 'id_card' | 'passport' | 'military' | 'other'
  birth_place?: string
  nationality?: string
  ethnicity?: string
  marital_status?: '未婚' | '已婚' | '丧偶' | '离婚' | '未知'
  education?: string
  occupation?: string
  phone?: string
  phone_emergency?: string
  email?: string
  address?: string
  address_registered?: string
  household_register?: string
  insurance_type?: '职工医保' | '居民医保' | '新农合' | '商业保险' | '自费' | '其他'
  insurance_no?: string
  insurance_org?: string
  emergency_contact_name?: string
  emergency_contact_relation?: string
  emergency_contact_phone?: string
  vip_level: number
  risk_level?: 'low' | 'medium' | 'high'
  photo_url?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface PatCard {
  id: string
  pat_id: string
  card_type: 'health_card' | 'medical_card' | 'social_security' | 'electronic' | 'other'
  card_no: string
  binding_time: string
  is_primary: boolean
  is_active: boolean
  issue_org?: string
  expire_date?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface PatAllergy {
  id: string
  pat_id: string
  allergen: string
  allergy_type?: 'drug' | 'food' | 'environmental' | 'other'
  severity?: 'mild' | 'moderate' | 'severe' | 'life_threatening'
  reaction?: string
  onset_date?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface PatMedicalHistory {
  id: string
  pat_id: string
  disease_name: string
  icd_code?: string
  diagnosis_date?: string
  treatment?: string
  outcome?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface PatContact {
  id: string
  pat_id: string
  name: string
  relation?: string
  phone?: string
  email?: string
  address?: string
  is_emergency_contact: boolean
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 5. 门诊模块 (op_*)
// ============================================================

export interface OpRegSource {
  id: string
  org_id: string
  dept_id: string
  doctor_id: string
  schedule_date: string
  shift_type: 'morning' | 'afternoon' | 'night' | 'day' | 'on_call'
  time_slot_start: string
  time_slot_end: string
  reg_quota: number
  reg_used: number
  reg_fee: number
  service_fee: number
  status: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface OpRegistration {
  id: string
  org_id: string
  pat_id: string
  visit_sn: string
  reg_no: string
  dept_id: string
  doctor_id?: string
  reg_source_id?: string
  visit_date: string
  visit_time: string
  shift_type?: string
  sequence_no: number
  visit_type: 'first' | 'return'
  clinic_type: 'general' | 'special' | 'expert' | 'emergency' | 'fast'
  complaint?: string
  reg_fee: number
  service_fee: number
  total_fee: number
  payment_method: 'cash' | 'card' | 'wechat' | 'alipay' | 'insurance' | 'mixed'
  payment_status: 'unpaid' | 'paid' | 'refunded' | 'partial_refund'
  payment_time?: string
  insurance_adjustment: number
  discount_amount: number
  status: 'registered' | 'checked_in' | 'in_progress' | 'finished' | 'cancelled' | 'no_show'
  check_in_time?: string
  check_in_method?: string
  cancel_time?: string
  cancel_reason?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
  pat_master?: PatMaster
  dept?: OrgDept
  doctor?: HrEmployee
}

export interface OpTriage {
  id: string
  org_id: string
  reg_id: string
  pat_id: string
  dept_id: string
  doctor_id?: string
  queue_no?: number
  triage_time: string
  triage_nurse_id?: string
  vital_signs?: any
  pain_level?: number
  urgency_level?: '1' | '2' | '3' | '4'
  waiting_time_minutes?: number
  call_status?: 'waiting' | 'called' | 'arrived' | 'skipped'
  call_time?: string
  arrival_time?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface OpVisit {
  id: string
  org_id: string
  pat_id: string
  visit_sn: string
  reg_id?: string
  dept_id: string
  doctor_id?: string
  visit_time: string
  chief_complaint?: string
  present_illness?: string
  past_history?: string
  personal_history?: string
  family_history?: string
  physical_exam?: string
  primary_diagnosis?: any
  secondary_diagnosis?: any
  tcm_diagnosis?: any
  visit_type?: 'first' | 'return'
  illness_severity?: 'mild' | 'moderate' | 'severe' | 'critical'
  treatment_plan?: string
  notes?: string
  next_visit_advice?: string
  structured_data?: any
  emr_content?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface OpDiagnosis {
  id: string
  org_id: string
  visit_id: string
  pat_id: string
  visit_sn: string
  diagnosis_type: 'primary' | 'secondary' | 'tcm' | 'supplementary'
  diagnosis_no: number
  icd_code?: string
  icd_name?: string
  tcm_code?: string
  tcm_name?: string
  diagnosis_name: string
  diagnosis_status?: 'suspected' | 'confirmed' | 'ruled_out'
  diagnosis_doctor_id?: string
  diagnosis_time: string
  is_main: boolean
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface OpPrescription {
  id: string
  org_id: string
  pat_id: string
  visit_sn: string
  visit_id?: string
  prescription_no: string
  prescription_type?: 'western' | 'chinese' | 'mixed' | 'tcm'
  dept_id: string
  doctor_id: string
  diagnosis?: any
  tcm_syndrome?: string
  tcm_therapy?: string
  total_amount: number
  dispensation_status?: 'undispensed' | 'partial' | 'dispensed' | 'returned' | 'cancelled'
  dispensation_time?: string
  dispensation_dept_id?: string
  dispensation_pharmacist_id?: string
  audit_status?: 'pending' | 'passed' | 'rejected' | 'modified'
  audit_time?: string
  audit_pharmacist_id?: string
  audit_remarks?: string
  return_amount: number
  return_time?: string
  requires_pivas: boolean
  pivas_batch_no?: string
  notes?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface OpPrescriptionItem {
  id: string
  org_id: string
  prescription_id: string
  drug_id: string
  drug_name: string
  drug_spec: string
  unit: string
  dosage: string
  dosage_unit?: string
  quantity: number
  unit_price: number
  total_price: number
  usage: string
  frequency: string
  duration: string
  route?: string
  batch_no?: string
  expiry_date?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface OpCharge {
  id: string
  org_id: string
  pat_id: string
  visit_sn: string
  visit_id?: string
  item_type: 'drug' | 'exam' | 'procedure' | 'material' | 'service' | 'bed' | 'nursing' | 'other'
  item_id: string
  item_name: string
  item_spec?: string
  unit: string
  quantity: number
  unit_price: number
  total_price: number
  dept_id: string
  doctor_id?: string
  charge_time: string
  operator_id?: string
  payment_method?: string
  payment_status?: 'unpaid' | 'paid' | 'refunded' | 'partial_refund'
  payment_time?: string
  insurance_adjustment?: number
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 6. 住院模块 (ip_*)
// ============================================================

export interface IpBed {
  id: string
  org_id: string
  ward_id: string
  bed_no: string
  bed_type?: 'general' | 'special' | 'icu' | 'observation' | 'emergency'
  bed_level?: 'I' | 'II' | 'III'
  status: 'occupied' | 'available' | 'maintenance' | 'reserved'
  price: number
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface IpAdmission {
  id: string
  org_id: string
  pat_id: string
  admission_no: string
  visit_sn: string
  dept_id: string
  ward_id: string
  bed_id: string
  doctor_id: string
  admitting_doctor_id: string
  admission_date: string
  admission_time: string
  diagnosis?: string
  admission_diagnosis?: string
  admission_condition?: 'emergency' | 'urgent' | 'normal'
  visit_type?: 'first' | 'return'
  expected_stay_days?: number
  actual_stay_days?: number
  discharge_date?: string
  discharge_time?: string
  discharge_diagnosis?: string
  discharge_summary?: string
  total_expense: number
  prepayment_amount: number
  settlement_status?: 'unsettled' | 'partial' | 'settled'
  status: 'in_hospital' | 'discharged' | 'transferred' | 'deceased'
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface IpDiagnosis {
  id: string
  org_id: string
  admission_id: string
  pat_id: string
  diagnosis_type: 'admission' | 'discharge' | 'concurrent' | 'complication' | 'underlying'
  diagnosis_no: number
  icd_code?: string
  icd_name?: string
  diagnosis_name: string
  is_main: boolean
  diagnosis_status?: 'suspected' | 'confirmed'
  doctor_id?: string
  diagnosis_time: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface IpLongOrder {
  id: string
  org_id: string
  admission_id: string
  pat_id: string
  order_no: string
  order_type: 'drug' | 'lab' | 'exam' | 'procedure' | 'operation' | 'nursing' | 'diet' | 'bed' | 'other'
  order_sub_type?: string
  item_id?: string
  item_name: string
  item_spec?: string
  unit?: string
  dosage?: string
  dosage_unit?: string
  route?: string
  frequency?: string
  start_time: string
  end_time?: string
  duration_days?: number
  cycle_count?: number
  cycle_days?: number
  administration_time?: string[]
  usage?: string
  speed?: string
  is_urgent: boolean
  is_as_needed: boolean
  is_stopped: boolean
  stop_time?: string
  stop_reason?: string
  stop_doctor_id?: string
  audit_status?: 'pending' | 'passed' | 'rejected' | 'modified'
  audit_time?: string
  audit_pharmacist_id?: string
  audit_remarks?: string
  dispensing_status?: 'undispensed' | 'partial' | 'dispensed'
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface IpTempOrder {
  id: string
  org_id: string
  admission_id: string
  pat_id: string
  order_no: string
  order_type: 'drug' | 'lab' | 'exam' | 'procedure' | 'operation' | 'nursing' | 'diet' | 'bed' | 'other'
  item_id?: string
  item_name: string
  item_spec?: string
  unit?: string
  dosage?: string
  dosage_unit?: string
  route?: string
  frequency?: string
  start_time: string
  end_time?: string
  execute_time?: string
  is_urgent: boolean
  is_performed: boolean
  execution_status?: 'pending' | 'executed' | 'cancelled'
  executor_id?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface IpOrderExecution {
  id: string
  org_id: string
  order_id: string
  order_type: 'long' | 'temp'
  admission_id: string
  pat_id: string
  item_name: string
  spec: string
  dosage: string
  dosage_unit?: string
  route?: string
  administration_time: string
  planned_time: string
  actual_time?: string
  executor_id?: string
  execution_status: 'pending' | 'executed' | 'missed' | 'cancelled'
  execution_result?: string
  signature_data?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface IpBedTransfer {
  id: string
  org_id: string
  admission_id: string
  pat_id: string
  from_ward_id: string
  from_bed_id: string
  to_ward_id: string
  to_bed_id: string
  transfer_time: string
  transfer_type: 'routine' | 'emergency' | 'icu_transfer'
  reason?: string
  doctor_order?: string
  nurse_confirm?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface IpNursingRecord {
  id: string
  org_id: string
  admission_id: string
  pat_id: string
  record_time: string
  record_type: 'vital_signs' | 'input_output' | 'nursing_care' | 'observation' | 'other'
  content: any
  nurse_id: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface IpTemperatureSheet {
  id: string
  org_id: string
  admission_id: string
  pat_id: string
  record_date: string
  temperature_am?: string
  temperature_pm?: string
  pulse?: number
  respiration?: number
  blood_pressure_high?: number
  blood_pressure_low?: number
  fluid_input?: number
  fluid_output?: number
  stool?: number
  urine?: number
  remarks?: string
  nurse_id?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface IpDailyBill {
  id: string
  org_id: string
  admission_id: string
  pat_id: string
  bill_date: string
  item_type: string
  item_id: string
  item_name: string
  item_spec?: string
  unit: string
  quantity: number
  unit_price: number
  total_price: number
  dept_id: string
  operator_id?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface IpSettlement {
  id: string
  org_id: string
  admission_id: string
  pat_id: string
  settlement_no: string
  settlement_date: string
  total_amount: number
  insurance_payment?: number
  patient_payment: number
  prepayment_deducted: number
  refund_amount: number
  payment_method?: string
  payment_time?: string
  operator_id?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 7. 检验模块 (lis_*)
// ============================================================

export interface LisRequest {
  id: string
  org_id: string
  request_no: string
  pat_id: string
  visit_id?: string
  visit_sn?: string
  patient_name: string
  gender?: string
  age?: number
  dept_id: string
  doctor_id: string
  specimen_type: string
  specimen_collection_time?: string
  specimen_received_time?: string
  clinical_diagnosis?: string
  clinical_info?: string
  test_items: any
  priority?: 'normal' | 'urgent' | 'stat'
  status: 'pending' | 'sampled' | 'received' | 'testing' | 'reported' | 'cancelled'
  report_time?: string
  report_doctor_id?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface LisResult {
  id: string
  org_id: string
  request_id: string
  test_item_id: string
  test_item_name: string
  result_value: string
  result_unit?: string
  reference_range?: string
  reference_low?: number
  reference_high?: number
  is_abnormal: boolean
  abnormal_flag?: 'L' | 'H' | 'LL' | 'HH' | 'N'
  instrument?: string
  method?: string
  result_time?: string
  entered_by?: string
  entered_time?: string
  verified_by?: string
  verified_time?: string
  status: 'entered' | 'verified' | 'reported'
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface LisCriticalValue {
  id: string
  org_id: string
  request_id: string
  pat_id: string
  item_name: string
  critical_value: string
  critical_type: 'L' | 'H' | 'LL' | 'HH'
  report_time?: string
  notify_time?: string
  notify_to?: string
  notify_response?: string
  handle_time?: string
  handler_id?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 8. 影像模块 (ris_*)
// ============================================================

export interface RisRequest {
  id: string
  org_id: string
  request_no: string
  pat_id: string
  visit_id?: string
  visit_sn?: string
  patient_name: string
  gender?: string
  age?: number
  dept_id: string
  doctor_id: string
  exam_item_id: string
  exam_item_name: string
  exam_body_part?: string
  exam_method?: string
  clinical_diagnosis?: string
  clinical_info?: string
  exam_indications?: string
  has_contrast: boolean
  contrast_agent?: string
  priority?: 'normal' | 'urgent' | 'stat'
  status: 'pending' | 'registered' | 'imaging' | 'imaging_completed' | 'reported' | 'cancelled'
  exam_time?: string
  exam_end_time?: string
  report_time?: string
  radiologist_id?: string
  report_content?: string
  report_template?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface RisReport {
  id: string
  org_id: string
  request_id: string
  pat_id: string
  report_no: string
  exam_findings: string
  exam_conclusion: string
  impression: string
  radiologist_id: string
  report_time: string
  verified_by?: string
  verified_time?: string
  is_print: boolean
  print_time?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 9. 药房模块 (pha_*)
// ============================================================

export interface PhaOpDispense {
  id: string
  org_id: string
  prescription_id: string
  pat_id: string
  dispense_no: string
  dept_id: string
  pharmacist_id: string
  dispense_time: string
  status: 'preparing' | 'ready' | 'dispensed' | 'returned'
  return_time?: string
  return_reason?: string
  total_amount: number
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface PhaIpDispense {
  id: string
  org_id: string
  admission_id: string
  pat_id: string
  dispense_no: string
  ward_id: string
  dept_id: string
  pharmacist_id: string
  dispense_time: string
  status: 'preparing' | 'ready' | 'dispensed' | 'returned'
  return_time?: string
  return_reason?: string
  total_amount: number
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface PhaControlledDrugAccount {
  id: string
  org_id: string
  drug_id: string
  drug_name: string
  spec: string
  unit: string
  dept_id: string
  ward_id?: string
  record_date: string
  opening_stock: number
  receive_qty: number
  dispense_qty: number
  closing_stock: number
  patient_name?: string
  prescription_no?: string
  operator_id: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 10. 手术模块 (op_*)
// ============================================================

export interface OpSurgery {
  id: string
  org_id: string
  surgery_no: string
  pat_id: string
  admission_id?: string
  visit_id?: string
  patient_name: string
  gender?: string
  age?: number
  dept_id: string
  ward_id?: string
  operating_room?: string
  surgery_date: string
  surgery_start?: string
  surgery_end?: string
  surgery_name: string
  surgery_code?: string
  icd_code?: string
  incision_grade?: 'I' | 'II' | 'III' | 'IV'
  surgery_level?: '1' | '2' | '3' | '4'
  surgeon_id: string
  assistant1_id?: string
  assistant2_id?: string
  anesthesiologist_id?: string
  anesthesia_type?: string
  scrub_nurse_id?: string
  circulating_nurse_id?: string
  surgery_status?: 'scheduled' | 'in_progress' | 'completed' | 'cancelled'
  preoperative_diagnosis?: string
  postoperative_diagnosis?: string
  surgery_findings?: string
  procedure_details?: string
  blood_loss?: number
  blood_transfusion?: number
  intraoperative_notes?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 11. 麻醉模块 (op_*)
// ============================================================

export interface OpAnesthesia {
  id: string
  org_id: string
  surgery_id: string
  pat_id: string
  anesthesia_no: string
  anesthesia_type: string
  anesthesia_start: string
  anesthesia_end?: string
  anesthesiologist_id: string
  nurse_id?: string
  pre_visit_status?: 'pending' | 'completed'
  pre_visit_time?: string
  pre_visit_asa?: string
  pre_visit_notes?: string
  vital_signs_during?: any
  medications_given?: any
  events_during?: any
  emergence_status?: 'calm' | 'restless' | 'sedated'
  recovery_score?: number
  postop_pacu?: string
  complications?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 12. 输血模块 (ip_/op_*)
// ============================================================

export interface IpBloodTransfusion {
  id: string
  org_id: string
  transfusion_no: string
  pat_id: string
  admission_id: string
  patient_name: string
  blood_type?: string
  rh_factor?: string
  transfusion_date: string
  start_time?: string
  end_time?: string
  blood_product?: string
  blood_product_code?: string
  volume?: number
  unit?: string
  blood_donor?: string
  blood_bank_no?: string
  blood_expire_date?: string
  ABO_reaction?: string
  Rh_reaction?: string
  transfusion_rate?: string
  transfusion反应?: 'none' | 'mild' | 'moderate' | 'severe'
  doctor_id: string
  nurse_id?: string
  transfusion_status?: 'ordered' | 'started' | 'completed' | 'stopped' | 'reaction'
  reaction_time?: string
  reaction_description?: string
  handle_measures?: string
  remarks?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

// ============================================================
// 13. 系统模块 (sys_*)
// ============================================================

export interface SysConfig {
  id: string
  org_id: string
  config_key: string
  config_value: string
  config_type: string
  config_group?: string
  description?: string
  sort_order?: number
  status?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface SysRole {
  id: string
  org_id: string
  role_code: string
  role_name: string
  role_type: 'system' | 'business'
  permissions: any
  status?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}

export interface SysLoginLog {
  id: string
  org_id: string
  user_id: string
  username: string
  login_time: string
  logout_time?: string
  ip_address?: string
  user_agent?: string
  login_status?: 'success' | 'failed'
  failure_reason?: string
  create_time: string
}

export interface SysOperLog {
  id: string
  org_id: string
  user_id: string
  username: string
  module: string
  operation: string
  request_method?: string
  request_url?: string
  request_params?: any
  response_code?: string
  operation_status?: 'success' | 'failed'
  error_message?: string
  operation_time?: string
  duration_ms?: number
  create_time: string
}

export interface SysNotification {
  id: string
  org_id: string
  notification_type: 'system' | 'alert' | 'message' | 'reminder'
  title: string
  content: string
  target_type: 'all' | 'role' | 'user' | 'dept'
  target_id?: string
  priority?: 'low' | 'normal' | 'high' | 'urgent'
  valid_from?: string
  valid_until?: string
  is_read?: boolean
  read_time?: string
  read_by?: string
  create_time: string
  update_time: string
  create_by?: string
  update_by?: string
  is_deleted: boolean
}
