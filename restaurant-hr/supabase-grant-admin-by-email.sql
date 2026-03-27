-- =============================================================================
-- ადმინის პროფილი ელფოსტით (HRCore)
-- =============================================================================
-- 1) Supabase → Authentication → Users → Add user
--    Email: merabtamoevi@gmail.com
--    Password: თქვენი პაროლი (Dashboard-ში — არ ჩაწეროთ SQL ფაილში).
-- 2) SQL Editor → Run ეს ფაილი.
--
-- თუ ჩანაწერი უკვე არსებობს — role განახლდება admin-ზე.
-- =============================================================================

INSERT INTO public.profiles (id, role, employee_id, display_name)
SELECT
  u.id,
  'admin',
  NULL,
  COALESCE(NULLIF(TRIM(u.raw_user_meta_data->>'full_name'),''), 'Admin')
FROM auth.users u
WHERE lower(u.email) = lower('merabtamoevi@gmail.com')
ON CONFLICT (id) DO UPDATE SET
  role = 'admin',
  display_name = COALESCE(EXCLUDED.display_name, public.profiles.display_name);

-- თუ 0 rows affected — მომხმარებელი auth.users-ში არ არის; ჯერ დაამატეთ Users-იდან.

SELECT pg_notify('pgrst', 'reload schema');
