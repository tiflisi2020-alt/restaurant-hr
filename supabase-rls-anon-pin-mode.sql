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
