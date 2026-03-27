-- =============================================================================
-- HRCore — სრული ბაზა ცარიელი Supabase პროექტისთვის
-- რიგი: 1) ანგარიში supabase.com-ზე → ახალი პროექტი  2) SQL Editor → ჩასვით ეს ფაილი → Run
-- შენიშვნა: profiles ცხრილი იყენებს auth.users-ს — Supabase-ში ეს უკვე არსებობს.
-- =============================================================================

-- განყოფილებები
CREATE TABLE IF NOT EXISTS public.departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- პოზიციები
CREATE TABLE IF NOT EXISTS public.positions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  department_id uuid REFERENCES public.departments (id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- თანამშრომლები (აპის ყველა ველი)
CREATE TABLE IF NOT EXISTS public.employees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text,
  phone text,
  department_id uuid REFERENCES public.departments (id) ON DELETE SET NULL,
  position_id uuid REFERENCES public.positions (id) ON DELETE SET NULL,
  salary numeric DEFAULT 0,
  status text DEFAULT 'active',
  hire_date date,
  national_id text,
  contract_start_date date,
  contract_end_date date,
  health_certificate_expiry date,
  issued_items jsonb DEFAULT '[]'::jsonb,
  hourly_rate numeric DEFAULT 0,
  duty_status text DEFAULT 'off_duty' CHECK (duty_status IN ('active', 'on_break', 'off_duty')),
  created_at timestamptz DEFAULT now(),
  CONSTRAINT employees_email_unique UNIQUE (email)
);

CREATE INDEX IF NOT EXISTS idx_employees_dept ON public.employees (department_id);

-- ცვლები
CREATE TABLE IF NOT EXISTS public.shifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  start_time time,
  end_time time,
  created_at timestamptz DEFAULT now()
);

-- განრიგი
CREATE TABLE IF NOT EXISTS public.schedule (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  work_date date NOT NULL,
  shift_id uuid NOT NULL REFERENCES public.shifts (id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (employee_id, work_date)
);

CREATE INDEX IF NOT EXISTS idx_schedule_range ON public.schedule (work_date);

-- დასწრება
CREATE TABLE IF NOT EXISTS public.attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  work_date date NOT NULL,
  status text DEFAULT 'present',
  check_in timestamptz,
  check_out timestamptz,
  check_in_lat double precision,
  check_in_lng double precision,
  check_out_lat double precision,
  check_out_lng double precision,
  created_at timestamptz DEFAULT now(),
  UNIQUE (employee_id, work_date)
);

CREATE INDEX IF NOT EXISTS idx_attendance_date ON public.attendance (work_date);

-- ხელფასის ჩანაწერები
CREATE TABLE IF NOT EXISTS public.salary_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  period_year int NOT NULL,
  period_month int NOT NULL,
  base_salary numeric DEFAULT 0,
  bonus numeric DEFAULT 0,
  deduction numeric DEFAULT 0,
  overtime_pay numeric DEFAULT 0,
  net_salary numeric,
  total_hours numeric DEFAULT 0,
  note text,
  paid boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  UNIQUE (employee_id, period_year, period_month)
);

-- მოთხოვნები
CREATE TABLE IF NOT EXISTS public.requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  type text NOT NULL,
  description text,
  start_date date,
  end_date date,
  status text DEFAULT 'pending',
  reviewed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- შეტყობინებები
CREATE TABLE IF NOT EXISTS public.notices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text,
  priority text DEFAULT 'normal',
  created_at timestamptz DEFAULT now()
);

-- KPI
CREATE TABLE IF NOT EXISTS public.kpi_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  year int NOT NULL,
  month int NOT NULL,
  metric_name text NOT NULL,
  target numeric DEFAULT 0,
  actual numeric DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE (employee_id, year, month, metric_name)
);

-- შეფასებები
CREATE TABLE IF NOT EXISTS public.performance_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  period_year int NOT NULL,
  period_quarter int NOT NULL,
  score numeric,
  punctuality int,
  teamwork int,
  quality int,
  attitude int,
  comment text,
  created_at timestamptz DEFAULT now()
);

-- სწავლება
CREATE TABLE IF NOT EXISTS public.trainings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  trainer text,
  duration_minutes int,
  scheduled_at timestamptz,
  mandatory boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.training_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  training_id uuid NOT NULL REFERENCES public.trainings (id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  attended boolean DEFAULT false,
  UNIQUE (training_id, employee_id)
);

-- ოვერთაიმი
CREATE TABLE IF NOT EXISTS public.overtime (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  work_date date NOT NULL,
  hours numeric NOT NULL,
  reason text,
  approved boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- დოკუმენტები
CREATE TABLE IF NOT EXISTS public.employee_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  doc_type text NOT NULL,
  title text NOT NULL,
  expiry_date date,
  note text,
  created_at timestamptz DEFAULT now()
);

-- დისციპლინა
CREATE TABLE IF NOT EXISTS public.disciplinary (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  type text NOT NULL,
  reason text,
  issued_at timestamptz DEFAULT now()
);

-- ხელფასის პარამეტრები (გადასახადი, სადაზღვევო, OT კოეფიციენტი)
CREATE TABLE IF NOT EXISTS public.payroll_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  value numeric NOT NULL DEFAULT 0,
  type text NOT NULL,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- ოპერაციული (მოგება vs შრომა)
CREATE TABLE IF NOT EXISTS public.operational_daily (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  record_date date NOT NULL UNIQUE,
  revenue numeric NOT NULL DEFAULT 0,
  labor_cost numeric NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Payroll ლოგი
CREATE TABLE IF NOT EXISTS public.payroll_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES public.employees (id) ON DELETE CASCADE,
  period_year int NOT NULL,
  period_month int NOT NULL,
  worked_hours numeric DEFAULT 0,
  hourly_rate_snapshot numeric DEFAULT 0,
  bonus numeric DEFAULT 0,
  fines numeric DEFAULT 0,
  computed_gross numeric DEFAULT 0,
  net_salary numeric DEFAULT 0,
  source text DEFAULT 'app',
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payroll_logs_emp_period ON public.payroll_logs (employee_id, period_year, period_month);

-- პროფილები (Auth ↔ თანამშრომელი)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  employee_id uuid REFERENCES public.employees (id) ON DELETE SET NULL,
  role text NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
  display_name text,
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_employee ON public.profiles (employee_id);

CREATE TABLE IF NOT EXISTS public.notice_reads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  notice_id uuid NOT NULL REFERENCES public.notices (id) ON DELETE CASCADE,
  read_at timestamptz DEFAULT now(),
  UNIQUE (profile_id, notice_id)
);

-- -----------------------------------------------------------------------------
-- ხედები (Views) — აპი ამ ცხრილებს კითხულობს
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.employee_details AS
SELECT
  e.*,
  d.name AS department,
  p.name AS position
FROM public.employees e
LEFT JOIN public.departments d ON d.id = e.department_id
LEFT JOIN public.positions p ON p.id = e.position_id;

CREATE OR REPLACE VIEW public.pending_requests AS
SELECT
  r.*,
  (e.first_name || ' ' || e.last_name) AS full_name
FROM public.requests r
JOIN public.employees e ON e.id = r.employee_id
WHERE r.status = 'pending';

CREATE OR REPLACE VIEW public.today_attendance AS
SELECT
  a.*,
  (e.first_name || ' ' || e.last_name) AS full_name,
  pos.name AS position
FROM public.attendance a
JOIN public.employees e ON e.id = a.employee_id
LEFT JOIN public.positions pos ON pos.id = e.position_id
WHERE a.work_date = ((now() AT TIME ZONE 'Asia/Tbilisi'))::date;

CREATE OR REPLACE VIEW public.salary_summary AS
SELECT
  sr.*,
  (e.first_name || ' ' || e.last_name) AS full_name,
  d.name AS department,
  COALESCE(sr.net_salary,
    COALESCE(sr.base_salary,0) + COALESCE(sr.bonus,0) + COALESCE(sr.overtime_pay,0) - COALESCE(sr.deduction,0)
  ) AS computed_net
FROM public.salary_records sr
JOIN public.employees e ON e.id = sr.employee_id
LEFT JOIN public.departments d ON d.id = e.department_id;

-- -----------------------------------------------------------------------------
-- საწყისი მონაცემები (გაეშვება უსაფრთხოდ მხოლოდ ცარიელ ბაზაზე; ხელახლა Run-ზე დუბლირება არ ქმნის)
-- -----------------------------------------------------------------------------
INSERT INTO public.departments (name)
SELECT v FROM (VALUES
  ('სამზარეული'),
  ('სალონი / სერვისი'),
  ('ბარი'),
  ('ადმინისტრაცია')
) AS t(v)
WHERE NOT EXISTS (SELECT 1 FROM public.departments d WHERE d.name = t.v);

INSERT INTO public.shifts (name, start_time, end_time)
SELECT * FROM (VALUES
  ('დილა', '09:00'::time, '17:00'::time),
  ('საღამო', '14:00'::time, '22:00'::time),
  ('ღამე', '22:00'::time, '06:00'::time)
) AS t(n, st, et)
WHERE NOT EXISTS (SELECT 1 FROM public.shifts s WHERE s.name = t.n);

INSERT INTO public.payroll_settings (name, value, type, active)
SELECT * FROM (VALUES
  ('income_tax', 20::numeric, 'tax'::text, true),
  ('social_insurance', 2::numeric, 'insurance'::text, true),
  ('overtime_rate', 1.5::numeric, 'overtime_rate'::text, true)
) AS t(n, val, typ, act)
WHERE NOT EXISTS (SELECT 1 FROM public.payroll_settings p WHERE p.name = t.n);

COMMENT ON TABLE public.profiles IS 'Supabase Auth მომხმარებელი → admin/employee + თანამშრომლის id';

-- =============================================================================
-- Row Level Security (იგივე ლოგიკა რაც supabase-production-schema.sql-ში)
-- პირველი ადმინის profiles ჩანაწერი შექმენით Auth-ის მომხმარებლის UUID-ით (იხ. ქვემოთ).
-- =============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notice_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operational_daily ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

DROP POLICY IF EXISTS "emp_admin_all" ON public.employees;
CREATE POLICY "emp_admin_all" ON public.employees FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "emp_self_read" ON public.employees;
CREATE POLICY "emp_self_read" ON public.employees FOR SELECT USING (
  id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "sal_admin_all" ON public.salary_records;
CREATE POLICY "sal_admin_all" ON public.salary_records FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "sal_employee_own" ON public.salary_records;
CREATE POLICY "sal_employee_own" ON public.salary_records FOR SELECT USING (
  employee_id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "plog_admin_all" ON public.payroll_logs;
CREATE POLICY "plog_admin_all" ON public.payroll_logs FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "plog_employee_own" ON public.payroll_logs;
CREATE POLICY "plog_employee_own" ON public.payroll_logs FOR SELECT USING (
  employee_id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "att_admin_all" ON public.attendance;
CREATE POLICY "att_admin_all" ON public.attendance FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "att_employee_own" ON public.attendance;
CREATE POLICY "att_employee_own" ON public.attendance FOR SELECT USING (
  employee_id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);
DROP POLICY IF EXISTS "att_employee_upsert_own" ON public.attendance;
CREATE POLICY "att_employee_upsert_own" ON public.attendance FOR INSERT WITH CHECK (
  employee_id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);
DROP POLICY IF EXISTS "att_employee_update_own" ON public.attendance;
CREATE POLICY "att_employee_update_own" ON public.attendance FOR UPDATE USING (
  employee_id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "req_admin_all" ON public.requests;
CREATE POLICY "req_admin_all" ON public.requests FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "req_employee_own" ON public.requests;
CREATE POLICY "req_employee_own" ON public.requests FOR SELECT USING (
  employee_id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);
DROP POLICY IF EXISTS "req_employee_insert" ON public.requests;
CREATE POLICY "req_employee_insert" ON public.requests FOR INSERT WITH CHECK (
  employee_id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "opday_admin" ON public.operational_daily;
CREATE POLICY "opday_admin" ON public.operational_daily FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "nr_own" ON public.notice_reads;
CREATE POLICY "nr_own" ON public.notice_reads FOR ALL USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

ALTER TABLE public.schedule ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sched_admin" ON public.schedule;
CREATE POLICY "sched_admin" ON public.schedule FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "sched_self" ON public.schedule;
CREATE POLICY "sched_self" ON public.schedule FOR SELECT USING (
  employee_id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);

ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notices_read_auth" ON public.notices;
CREATE POLICY "notices_read_auth" ON public.notices FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "notices_admin_write" ON public.notices;
CREATE POLICY "notices_admin_write" ON public.notices FOR INSERT WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "notices_admin_update" ON public.notices;
CREATE POLICY "notices_admin_update" ON public.notices FOR UPDATE USING (public.is_admin());
DROP POLICY IF EXISTS "notices_admin_delete" ON public.notices;
CREATE POLICY "notices_admin_delete" ON public.notices FOR DELETE USING (public.is_admin());

-- დანარჩენ ცხრილებს (departments, positions, shifts, trainings, …) RLS არ ერთვება —
-- ტესტზე ეს ხშირად საკმარისია; პროდაქშენში დაამატეთ admin-only პოლიტიკები ან გამოიყენეთ service role სერვერზე.
