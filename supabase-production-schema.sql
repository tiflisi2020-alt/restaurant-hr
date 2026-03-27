-- =============================================================================
-- HRCore / Restaurant Operations OS — Production schema, RLS, triggers
-- Run in Supabase SQL Editor after backup. Adjust if tables already exist.
--
-- ⚠️ ახალი / ცარიელი პროექტი: ჯერ გაუშვით supabase-setup-from-zero.sql (ქმნის employees და სხვა ცხრილებს).
--    ეს ფაილი ძირითადად უკვე არსებულ ბაზაზე დასამატებლადაა (profiles, RLS, დამატებითი სვეტები).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Auth profiles (links auth.users ↔ employees)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  employee_id uuid REFERENCES public.employees (id) ON DELETE SET NULL,
  role text NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
  display_name text,
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_employee ON public.profiles (employee_id);

ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS hourly_rate numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS duty_status text DEFAULT 'off_duty'
    CHECK (duty_status IN ('active', 'on_break', 'off_duty'));

COMMENT ON COLUMN public.employees.duty_status IS 'Real-time floor status: active, on_break, off_duty';
COMMENT ON COLUMN public.employees.hourly_rate IS 'Hourly pay for smart payroll: hours × rate + bonus − fines';

-- -----------------------------------------------------------------------------
-- 2) Attendance: geolocation for digital clock-in/out
-- -----------------------------------------------------------------------------
ALTER TABLE public.attendance
  ADD COLUMN IF NOT EXISTS check_in_lat double precision,
  ADD COLUMN IF NOT EXISTS check_in_lng double precision,
  ADD COLUMN IF NOT EXISTS check_out_lat double precision,
  ADD COLUMN IF NOT EXISTS check_out_lng double precision;

-- -----------------------------------------------------------------------------
-- 3) Operational metrics (Labor vs Revenue trends)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.operational_daily (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  record_date date NOT NULL UNIQUE,
  revenue numeric NOT NULL DEFAULT 0,
  labor_cost numeric NOT NULL DEFAULT 0,
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_operational_daily_date ON public.operational_daily (record_date DESC);

-- -----------------------------------------------------------------------------
-- 4) Payroll audit log (optional; mirrors salary_records events)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 5) Requests: ensure types include day_off & shift_swap (text column)
-- If `requests.type` uses CHECK, alter accordingly. Example for text:
-- -----------------------------------------------------------------------------
-- No-op if type is free text; admins should use: vacation | sick_leave | day_off | shift_swap | shift_change | other

-- -----------------------------------------------------------------------------
-- 6) Notice reads (optional bell “unread”)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notice_reads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  notice_id uuid NOT NULL REFERENCES public.notices (id) ON DELETE CASCADE,
  read_at timestamptz DEFAULT now(),
  UNIQUE (profile_id, notice_id)
);

-- -----------------------------------------------------------------------------
-- 7) KPI: optional DB trigger (DISABLE if you rely on app-only penalty in index.html)
-- App also calls applyKpiPenaltyFromDisc — use ONE approach to avoid double penalty.
-- To use only DB: remove JS applyKpiPenaltyFromDisc from saveDisc() in index.html.
-- -----------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION public.apply_disciplinary_kpi_penalty()
-- RETURNS TRIGGER AS $$
-- ...
-- $$ LANGUAGE plpgsql SECURITY DEFINER;
-- DROP TRIGGER IF EXISTS tr_disciplinary_kpi ON public.disciplinary;
-- CREATE TRIGGER tr_disciplinary_kpi AFTER INSERT ON public.disciplinary
--   FOR EACH ROW EXECUTE FUNCTION public.apply_disciplinary_kpi_penalty();

-- -----------------------------------------------------------------------------
-- 8) Row Level Security
-- -----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notice_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operational_daily ENABLE ROW LEVEL SECURITY;

-- Profiles: own row
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Admins (role in profiles): broad read — duplicate policies per table
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Employees
DROP POLICY IF EXISTS "emp_admin_all" ON public.employees;
CREATE POLICY "emp_admin_all" ON public.employees FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "emp_self_read" ON public.employees;
CREATE POLICY "emp_self_read" ON public.employees FOR SELECT USING (
  id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);

-- Salary records: admin all; employee own only
DROP POLICY IF EXISTS "sal_admin_all" ON public.salary_records;
CREATE POLICY "sal_admin_all" ON public.salary_records FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "sal_employee_own" ON public.salary_records;
CREATE POLICY "sal_employee_own" ON public.salary_records FOR SELECT USING (
  employee_id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);

-- Payroll logs
DROP POLICY IF EXISTS "plog_admin_all" ON public.payroll_logs;
CREATE POLICY "plog_admin_all" ON public.payroll_logs FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "plog_employee_own" ON public.payroll_logs;
CREATE POLICY "plog_employee_own" ON public.payroll_logs FOR SELECT USING (
  employee_id = (SELECT employee_id FROM public.profiles WHERE id = auth.uid())
);

-- Attendance
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

-- Requests: employees insert/select own; admin all
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

-- operational_daily: admin only (sensitive financials)
DROP POLICY IF EXISTS "opday_admin" ON public.operational_daily;
CREATE POLICY "opday_admin" ON public.operational_daily FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- notice_reads
DROP POLICY IF EXISTS "nr_own" ON public.notice_reads;
CREATE POLICY "nr_own" ON public.notice_reads FOR ALL USING (profile_id = auth.uid()) WITH CHECK (profile_id = auth.uid());

-- -----------------------------------------------------------------------------
-- 9) Bootstrap first admin (run once with a real user id from auth.users)
-- -----------------------------------------------------------------------------
-- INSERT INTO public.profiles (id, role, employee_id) VALUES
--   ('YOUR-UUID-FROM-AUTH-USERS', 'admin', NULL);

-- Link employee user after signup (match email):
-- UPDATE public.profiles p SET employee_id = e.id
-- FROM public.employees e, auth.users u
-- WHERE p.id = u.id AND lower(u.email) = lower(e.email);

COMMENT ON TABLE public.profiles IS 'Maps Supabase Auth users to employees and roles (admin vs employee portal).';

-- -----------------------------------------------------------------------------
-- 10) Schedule & notices (employee self-service reads)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- RLS rollout: if the app breaks, temporarily DISABLE RLS on a table and add
-- policies incrementally. Anonymous (anon) key + no session = no row access.
-- -----------------------------------------------------------------------------
