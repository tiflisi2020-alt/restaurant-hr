-- =============================================================================
-- HRCore — ყველა „ახალი“ ცვლილების გაშვება Supabase SQL Editor-ში (ერთი Run)
-- =============================================================================
--
-- როდის გამოიყენოთ:
--   • უკვე გაქვთ HRCore ბაზა (ცხრილები employees, departments, notices, …) და
--     გინდათ სვეტები, ხედები, profiles/payroll_logs/operational_daily და PIN (anon) RLS.
--
-- როდის არა:
--   • ცარიელი ახალი პროექტი → მხოლოდ **supabase-setup-from-zero.sql** (სრული სქემა).
--   • თუ public.employees არ არსებობს → ჯერ სრული setup.
--
-- უსაფრთხოება: ხელახლა Run უმეტესი ნაწილი idempotent-ია (IF NOT EXISTS, DROP POLICY IF EXISTS).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0) მინიმალური გვარდი
-- -----------------------------------------------------------------------------
DO $g$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'employees'
  ) THEN
    RAISE EXCEPTION 'public.employees არ არსებობს. ჯერ გაუშვით supabase-setup-from-zero.sql';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'notices'
  ) THEN
    RAISE EXCEPTION 'public.notices არ არსებობს. ჯერ გაუშვით supabase-setup-from-zero.sql';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'schedule'
  ) THEN
    RAISE EXCEPTION 'public.schedule არ არსებობს. ჯერ გაუშვით supabase-setup-from-zero.sql';
  END IF;
END
$g$;

-- -----------------------------------------------------------------------------
-- 1) ცხრილები (რაც ძველ ბაზაში შეიძლება აკლდეს)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  employee_id uuid REFERENCES public.employees (id) ON DELETE SET NULL,
  role text NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
  display_name text,
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_employee ON public.profiles (employee_id);

CREATE TABLE IF NOT EXISTS public.operational_daily (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  record_date date NOT NULL UNIQUE,
  revenue numeric NOT NULL DEFAULT 0,
  labor_cost numeric NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_operational_daily_date ON public.operational_daily (record_date DESC);

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

CREATE TABLE IF NOT EXISTS public.notice_reads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  notice_id uuid NOT NULL REFERENCES public.notices (id) ON DELETE CASCADE,
  read_at timestamptz DEFAULT now(),
  UNIQUE (profile_id, notice_id)
);

-- -----------------------------------------------------------------------------
-- 2) სვეტები თანამშრომელზე / დასწრებაზე / ხელფასზე (აპის ახალი ველები)
-- -----------------------------------------------------------------------------
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS hourly_rate numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS duty_status text DEFAULT 'off_duty';

DO $c$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'employees_duty_status_check'
  ) THEN
    ALTER TABLE public.employees
      ADD CONSTRAINT employees_duty_status_check
      CHECK (duty_status IN ('active', 'on_break', 'off_duty'));
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END
$c$;

COMMENT ON COLUMN public.employees.duty_status IS 'Real-time floor status: active, on_break, off_duty';
COMMENT ON COLUMN public.employees.hourly_rate IS 'Hourly pay for smart payroll';

ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS national_id text,
  ADD COLUMN IF NOT EXISTS contract_start_date date,
  ADD COLUMN IF NOT EXISTS contract_end_date date,
  ADD COLUMN IF NOT EXISTS health_certificate_expiry date,
  ADD COLUMN IF NOT EXISTS issued_items jsonb DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.employees.health_certificate_expiry IS 'Food safety / health certificate expiry';
COMMENT ON COLUMN public.employees.issued_items IS 'Issued uniforms, badges, keys, etc.';

ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS check_in_lat double precision,
  ADD COLUMN IF NOT EXISTS check_in_lng double precision,
  ADD COLUMN IF NOT EXISTS check_out_lat double precision,
  ADD COLUMN IF NOT EXISTS check_out_lng double precision;

ALTER TABLE public.salary_records
  ADD COLUMN IF NOT EXISTS overtime_pay numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS net_salary numeric;

-- -----------------------------------------------------------------------------
-- 3) ხედები (დუბლირებული სვეტის გარეშე, overtime + computed_net)
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

COMMENT ON TABLE public.profiles IS 'Supabase Auth ↔ admin/employee + employee_id (PIN აპში ნაკლებად სავალდებულო)';

-- -----------------------------------------------------------------------------
-- 4) is_admin() + RLS (იგივე ლოგიკა setup + PIN/anon პოლიტიკა)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

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

-- PIN / anon (index.html ლოკალური კოდი — JWT სესია არა)
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.profiles;
CREATE POLICY "hrcore_anon_pin" ON public.profiles FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.employees;
CREATE POLICY "hrcore_anon_pin" ON public.employees FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.salary_records;
CREATE POLICY "hrcore_anon_pin" ON public.salary_records FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.payroll_logs;
CREATE POLICY "hrcore_anon_pin" ON public.payroll_logs FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.attendance;
CREATE POLICY "hrcore_anon_pin" ON public.attendance FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.requests;
CREATE POLICY "hrcore_anon_pin" ON public.requests FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.notice_reads;
CREATE POLICY "hrcore_anon_pin" ON public.notice_reads FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.operational_daily;
CREATE POLICY "hrcore_anon_pin" ON public.operational_daily FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.schedule;
CREATE POLICY "hrcore_anon_pin" ON public.schedule FOR ALL TO anon USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.notices;
CREATE POLICY "hrcore_anon_pin" ON public.notices FOR ALL TO anon USING (true) WITH CHECK (true);

-- საცნობი ცხრილები (პარამეტრებში INSERT — თუ RLS ჩართულია Dashboard-ში)
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.departments;
CREATE POLICY "hrcore_anon_pin" ON public.departments FOR ALL TO anon USING (true) WITH CHECK (true);
ALTER TABLE public.positions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.positions;
CREATE POLICY "hrcore_anon_pin" ON public.positions FOR ALL TO anon USING (true) WITH CHECK (true);
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.shifts;
CREATE POLICY "hrcore_anon_pin" ON public.shifts FOR ALL TO anon USING (true) WITH CHECK (true);
ALTER TABLE public.payroll_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.payroll_settings;
CREATE POLICY "hrcore_anon_pin" ON public.payroll_settings FOR ALL TO anon USING (true) WITH CHECK (true);
ALTER TABLE public.trainings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.trainings;
CREATE POLICY "hrcore_anon_pin" ON public.trainings FOR ALL TO anon USING (true) WITH CHECK (true);
ALTER TABLE public.training_participants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.training_participants;
CREATE POLICY "hrcore_anon_pin" ON public.training_participants FOR ALL TO anon USING (true) WITH CHECK (true);
ALTER TABLE public.kpi_metrics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.kpi_metrics;
CREATE POLICY "hrcore_anon_pin" ON public.kpi_metrics FOR ALL TO anon USING (true) WITH CHECK (true);
ALTER TABLE public.performance_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.performance_reviews;
CREATE POLICY "hrcore_anon_pin" ON public.performance_reviews FOR ALL TO anon USING (true) WITH CHECK (true);
ALTER TABLE public.overtime ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.overtime;
CREATE POLICY "hrcore_anon_pin" ON public.overtime FOR ALL TO anon USING (true) WITH CHECK (true);
ALTER TABLE public.employee_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.employee_documents;
CREATE POLICY "hrcore_anon_pin" ON public.employee_documents FOR ALL TO anon USING (true) WITH CHECK (true);
ALTER TABLE public.disciplinary ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "hrcore_anon_pin" ON public.disciplinary;
CREATE POLICY "hrcore_anon_pin" ON public.disciplinary FOR ALL TO anon USING (true) WITH CHECK (true);

-- -----------------------------------------------------------------------------
-- 5) API სქემის განახლება
-- -----------------------------------------------------------------------------
SELECT pg_notify('pgrst', 'reload schema');

-- =============================================================================
-- დასრულებულია. აპში განაახლეთ გვერდი; თუ რამე ერორია — გადააგზავნეთ შეტყობინების ტექსტი.
-- =============================================================================
