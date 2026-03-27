-- =============================================================================
-- HRCore — RLS პოლიტიკა PIN/anon რეჟიმისთვის (Supabase Auth გარეშე)
-- =============================================================================
-- პრობლემა: აპი იყენებს მხოლოდ anon JWT-ს; auth.uid() ცარიელია → is_admin() = false
--          და ყველა admin/employee პოლიტიკა ბლოკავს მოთხოვნებს.
-- გადაწყვეტა: anon როლისთვის ცალკე პოლიტიკა (სრული CRUD), authenticated რჩება ძველ ლოგიკაზე.
--
-- გაშვება: Supabase → SQL Editor → ჩასვით ეს ფაილი → Run (ერთხელ).
--
-- ⚠️ უსაფრთხოება: ვინც იცის პროექტის URL და anon გასაღები, ხედავს/ცვლის მონაცემებს.
--    PIN მხოლოდ UI-ში ფარავს — რეალური დაცვა = გვერდის პირადი URL, ან მომავალში სერვერული API.
-- =============================================================================

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

-- საცნობი ცხრილები (პარამეტრები, სწავლება, KPI …) — თუ Dashboard-ში RLS ჩართულია
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
