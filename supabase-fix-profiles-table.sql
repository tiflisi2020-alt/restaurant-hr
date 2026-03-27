-- =============================================================================
-- თუ აპი წერს: Could not find the table 'public.profiles' in the schema cache
-- =============================================================================
-- ჯერ Supabase → Table Editor: უნდა არსებობდეს public.employees.
-- თუ employees არ გაქვს — გაუშვით მთლიანად supabase-setup-from-zero.sql (არა მხოლოდ ეს ფაილი).
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  employee_id uuid REFERENCES public.employees (id) ON DELETE SET NULL,
  role text NOT NULL DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
  display_name text,
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_employee ON public.profiles (employee_id);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- API სქემის განახლება (PostgREST)
SELECT pg_notify('pgrst', 'reload schema');
