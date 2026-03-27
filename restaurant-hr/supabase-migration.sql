-- Run in Supabase SQL Editor after backup.
-- Extends HRCore / Restaurant Operations OS schema.
--
-- ⚠️ ჯერ გაუშვით supabase-setup-from-zero.sql (ან სხვა სრული სქემა), სანამ ამ ფაილს გაუშვებთ.
--    თუ public.employees არ არსებობს, ქვემოთ ერორი გეტყვით.
--    ახალი პროექტი: მხოლოდ setup-from-zero.sql საკმარისია — ამ migration-ს ხშირად საერთოდ არ სჭირდება.

DO $guard$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'employees'
  ) THEN
    RAISE EXCEPTION 'public.employees არ არსებობს. ჯერ Supabase SQL Editor-ში გაუშვით სრული ფაილი: supabase-setup-from-zero.sql (მერე საჭიროების შემთხვევაში ეს migration).';
  END IF;
END
$guard$;

-- Employee compliance & uniforms (JSON array: [{"key":"uniform","label":"Uniform","issued":true},...])
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS national_id text,
  ADD COLUMN IF NOT EXISTS contract_start_date date,
  ADD COLUMN IF NOT EXISTS contract_end_date date,
  ADD COLUMN IF NOT EXISTS health_certificate_expiry date,
  ADD COLUMN IF NOT EXISTS issued_items jsonb DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS hr_note text;

-- Payroll: overtime component for net formula
ALTER TABLE public.salary_records
  ADD COLUMN IF NOT EXISTS overtime_pay numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS net_salary numeric;

-- employee_details uses e.*; recreate view so new columns (e.g. hr_note) appear in SELECT *.
CREATE OR REPLACE VIEW public.employee_details AS
SELECT
  e.*,
  d.name AS department,
  p.name AS position
FROM public.employees e
LEFT JOIN public.departments d ON d.id = e.department_id
LEFT JOIN public.positions p ON p.id = e.position_id;

-- salary_summary view: include sr.overtime_pay and either expose sr.net_salary or compute:
--   (COALESCE(sr.base_salary,0) + COALESCE(sr.bonus,0) + COALESCE(sr.overtime_pay,0) - COALESCE(sr.deduction,0)) AS net_salary
-- Example (adapt joins/columns to your schema):
-- CREATE OR REPLACE VIEW public.salary_summary AS
--   SELECT sr.*, e.first_name || ' ' || e.last_name AS full_name, d.name AS department,
--     (COALESCE(sr.base_salary,0) + COALESCE(sr.bonus,0) + COALESCE(sr.overtime_pay,0) - COALESCE(sr.deduction,0)) AS net_salary
--   FROM salary_records sr
--   JOIN employees e ON e.id = sr.employee_id
--   LEFT JOIN departments d ON d.id = e.department_id;

COMMENT ON COLUMN public.employees.health_certificate_expiry IS 'Food safety / health certificate expiry';
COMMENT ON COLUMN public.employees.issued_items IS 'Issued uniforms, badges, keys, etc.';

-- If disciplinary.type is ENUM, add value: performance (verbal warnings / performance notes).
-- ALTER TYPE ... ADD VALUE IF NOT EXISTS 'performance';
