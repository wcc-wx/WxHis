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

// Department Types
export interface Department {
  id: string
  name: string
  code: string
  created_at: string
}

// Patient Types
export interface Patient {
  id: string
  name: string
  gender: '男' | '女'
  birth_date: string
  id_card: string
  phone: string | null
  address: string | null
  blood_type: string | null
  allergy_history: string | null
  created_at: string
  updated_at: string
}

// Registration Types
export type RegistrationStatus = 'pending' | 'in_progress' | 'finished' | 'cancelled'
export type VisitType = 'first' | 'return'
export type PaymentStatus = 'unpaid' | 'paid' | 'refunded'

export interface Registration {
  id: string
  patient_id: string
  department_id: string
  doctor_id: string | null
  registration_time: string
  sequence_no: number
  status: RegistrationStatus
  registration_fee: number
  visit_type: VisitType
  complaint: string | null
  payment_status: PaymentStatus
  created_at: string
  updated_at: string
  patient?: Patient
  department?: Department
  doctor?: UserProfile
}

export interface RegistrationFee {
  id: string
  department_id: string
  visit_type: VisitType
  fee: number
  created_at: string
}

// Outpatient Visit Types
export interface OutpatientVisit {
  id: string
  registration_id: string
  patient_id: string
  doctor_id: string
  visit_time: string
  chief_complaint: string | null
  present_illness: string | null
  diagnosis: string | null
  notes: string | null
  created_at: string
  updated_at: string
}

// Prescription Types
export type PrescriptionStatus = 'pending' | 'dispensed' | 'cancelled'

export interface Prescription {
  id: string
  visit_id: string
  patient_id: string
  doctor_id: string
  prescription_date: string
  status: PrescriptionStatus
  created_at: string
  updated_at: string
}

export interface PrescriptionItem {
  id: string
  prescription_id: string
  drug_id: string
  dosage: string
  usage: string
  quantity: number
  created_at: string
}

// Drug Types
export interface Drug {
  id: string
  name: string
  spec: string
  unit: string
  price: number
  stock: number
  created_at: string
}

// Lab Request Types
export type LabRequestStatus = 'pending' | 'sampled' | 'testing' | 'reported' | 'cancelled'

export interface LabRequest {
  id: string
  visit_id: string | null
  encounter_id: string | null
  patient_id: string
  doctor_id: string
  test_item_id: string
  specimen_type: string
  status: LabRequestStatus
  created_at: string
  updated_at: string
}

export interface TestItem {
  id: string
  name: string
  code: string
  category: string
  reference_value: string
  unit: string
  created_at: string
}

export interface LabResult {
  id: string
  lab_request_id: string
  test_item_id: string
  result_value: string
  reference_range: string
  is_abnormal: boolean
  entered_by: string
  entered_at: string
  verified_by: string | null
  verified_at: string | null
  status: 'entered' | 'verified'
  created_at: string
  updated_at: string
}

// Imaging Types
export type ImagingRequestStatus = 'pending' | 'registered' | 'imaging' | 'reported' | 'cancelled'
export type ImagingStudyStatus = 'pending' | 'in_progress' | 'completed' | 'reported'

export interface ImagingRequest {
  id: string
  visit_id: string | null
  patient_id: string
  doctor_id: string
  exam_type: 'CT' | 'MR' | 'X-Ray' | '超声'
  exam_part: string
  clinical_diagnosis: string | null
  status: ImagingRequestStatus
  created_at: string
  updated_at: string
}

export interface ImagingStudy {
  id: string
  imaging_request_id: string
  patient_id: string
  technician_id: string | null
  exam_time: string | null
  image_urls: string[]
  report_content: string | null
  report_doctor_id: string | null
  status: ImagingStudyStatus
  created_at: string
  updated_at: string
}

// Inpatient Types
export type EncounterStatus = 'admitted' | 'discharged'
export type BedStatus = 'occupied' | 'available' | 'maintenance'

export interface Bed {
  id: string
  department_id: string
  bed_no: string
  status: BedStatus
  created_at: string
  updated_at: string
}

export interface InpatientEncounter {
  id: string
  patient_id: string
  admission_time: string
  discharge_time: string | null
  bed_id: string
  diagnosis: string | null
  status: EncounterStatus
  created_at: string
  updated_at: string
}

// Order Types
export type OrderType = 'prescription' | 'lab' | 'imaging'
export type OrderStatus = 'pending' | 'executed' | 'cancelled' | 'completed'

export interface Order {
  id: string
  patient_id: string
  encounter_id: string | null
  visit_id: string | null
  order_type: OrderType
  order_content: string
  ordered_by: string
  ordered_at: string
  status: OrderStatus
  created_at: string
  updated_at: string
}
