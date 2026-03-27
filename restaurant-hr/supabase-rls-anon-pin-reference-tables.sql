-- =============================================================================
-- HRCore — anon + RLS საცნობ ცხრილებზე (პარამეტრები / CRUD)
-- =============================================================================
-- თუ Supabase-ში ჩართულია RLS ამ ცხრილებზე, მაგრამ პოლიტიკა არა — INSERT იბლოკება:
--   „new row violates row-level security policy for table 'departments'“
-- ეს სკრიპტი: RLS რჩება ჩართული + ემატება hrcore_anon_pin მხოლოდ anon როლისთვის.
--
-- გაშვება: SQL Editor → Run (უსაფრთხოა ხელახლა).
-- =============================================================================

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

SELECT pg_notify('pgrst', 'reload schema');
