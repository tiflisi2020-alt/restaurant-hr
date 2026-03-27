# HRCore — სწორი მიმართულებები (Supabase + აპი)

**სად არის კოდი:** ყველა ფუნქციონალი ერთ ფაილშია — **`index.html`**. ბაზის სქემა და RLS — **`supabase-*.sql`** ფაილებში ამავე საქაღალდეში.

---

## რიგი: რას როდის გაუშვებ (ახალი პროექტი)

| ნაბიჯი | სად | რა გააკეთოთ |
|--------|-----|--------------|
| **1** | [supabase.com](https://supabase.com) | ანგარიში → **New project** → შეინახეთ Database password. |
| **2** | Supabase → **SQL Editor** → New query | გახსენით **`supabase-setup-from-zero.sql`**, მთლიანი ტექსტი ჩასვით → **Run** (ერთხელ, ცარიელ პროექტზე). |
| **3** | SQL Editor (იგივე ან ახალი query) | გაუშვით **`supabase-rls-anon-pin-mode.sql`** — **აუცილებელია**, თუ აპში შესვლა **PIN-ითაა** (ელფოსტით Supabase Auth არ იყენებთ). ეს უშვებს `anon` გასაღებით ცხრილებზე წვდომას; უსესიოდ `is_admin()` ყოველთვის false იყო და აპი „ცარიელ“ იყო. |
| **4** | **Project Settings** → **API** | დააკოპირეთ **Project URL** და **anon public** key. |
| **5** | **`index.html`** (ხაზები `const SU=` და `const SK=`) | ჩასვით **იგივე პროექტის** URL და **anon** გასაღები (არა `service_role`). |
| **6** | ბრაუზერი | გახსენით `index.html` ან GitHub Pages URL → შესვლა **4 ციფრით** (ნაგულისხმევად კოდი ფაილში: `HRCORE_PIN` — შეცვალეთ თუ გინდათ). |

**მნიშვნელოვანი:** `SU`/`SK` და SQL **ერთიდაიგე Supabase პროექტიდან** უნდა იყოს. სხვა პროექტის გასაღები = ცარიელი ან შეცდომიანი მონაცემები.

---

## PIN რეჟიმი vs ელფოსტით Auth

- **ახლა აპი:** შესვლა **მხოლოდ ლოკალური PIN** (`index.html` → `HRCORE_PIN`). Supabase **ელფოსტით შესვლა არ არის** საჭირო ადმინ პანელისთვის.
- **Supabase Auth (Users + profiles):** საჭიროა მხოლოდ თუ გინდათ **თანამშრომლის პორტალი** იუზერით, ან მომავალში უსაფრთხო როლები JWT-ით. PIN ადმინს `profiles` არ სჭირდება.
- **უსაფრთხოება:** PIN და anon გასაღები კოდში/ბრაუზერში ჩანს — გვერდი გამოიყენეთ შიდა ქსელში ან დაცულ URL-ზე.

---

## უკვე არსებული ბაზა (არა ცარიელი პროექტი)

1. თუ **`employees` არ გაქვთ** — ჯერ სრული **`supabase-setup-from-zero.sql`** (ფრთხილად: შეიძლება კონფლიქტი არსებულ ცხრილებთან; backup).
2. თუ **`employees` გაქვთ, მაგრამ `profiles` არა** — **`supabase-fix-profiles-table.sql`**.
3. დამატებითი სვეტები/მიგრაცია — **`supabase-migration.sql`** / **`supabase-production-schema.sql`** (იხილეთ ფაილის შიგთავსი; ზოგი ნაბიჯი setup-ში უკვე შეიძლება იყოს).
4. PIN აპისთვის — ყოველთვის გაუშვით **`supabase-rls-anon-pin-mode.sql`**, თუ ეს ბლოკი setup-ში ჯერ არ გაქვთ გაშვებული.

**შეცდომა `relation "public.employees" does not exist`:** ჯერ **`supabase-setup-from-zero.sql`**, არა მხოლოდ migration.

---

## GitHub Pages

1. რეპოზიტორია (მაგ. [tiflisi2020-alt/restaurant-hr](https://github.com/tiflisi2020-alt/restaurant-hr)) → **Settings** → **Pages** → Source: branch **main**, ფოლდერი **/** (root) → Save.
2. აპის მისამართი ჩვეულებრივ:  
   **`https://tiflisi2020-alt.github.io/restaurant-hr/`**  
   (ბოლო `/` ხშირად სასარგებლოა.)
3. **Supabase → Authentication → URL Configuration:** PIN რეჟიმში redirect ნაკლებად კრიტიკულია; თუ მაინც იყენებთ Auth-ს, **Site URL** და **Redirect URLs** დაამატეთ ზემოთ `github.io` მისამართი (`.../restaurant-hr/**`).

---

## ფაილების ცხრილი

| ფაილი | დანიშნულება |
|--------|-------------|
| `index.html` | მთელი UI + ლოგიკა + `SU`/`SK` + PIN |
| `supabase-setup-from-zero.sql` | ახალი პროექტი: ცხრილები, ხედები, RLS + ბოლოში anon PIN პოლიტიკა |
| `supabase-rls-anon-pin-mode.sql` | მხოლოდ anon-ისთვის სრული წვდომა (გაუშვით, თუ ბაზა ძველია და ეს ბლოკი არ გაქვთ) |
| `supabase-fix-profiles-table.sql` | `profiles` ცხრილის შექმნა, თუ setup სრულად არ გაქვთ |
| `supabase-production-schema.sql` | პროდაქშენის დამატებები + RLS + ბოლოში anon ბლოკი |
| `supabase-migration.sql` | დამატებითი სვეტები (პირობითი) |

---

## ხშირი პრობლემები

| სიმპტომი | რა შეამოწმოთ |
|-----------|----------------|
| დეშბორდი ცარიელი, შენახვა არ მუშაობს | გაუშვით **`supabase-rls-anon-pin-mode.sql`** იმავე პროექტში; `SU`/`SK` იგივე პროექტიდან. |
| `public.profiles` / schema cache | `profiles` შექმნა: **`supabase-fix-profiles-table.sql`** ან სრული setup. |
| `Invalid login credentials` (ძველი ინსტრუქცია) | PIN აპში ელფოსტით შესვლა აღარ გამოიყენება — შეიყვანეთ **4 ციფრიანი კოდი** (`HRCORE_PIN`). |

---

**შეჯამება:** პროექტი Supabase-ზე → **`supabase-setup-from-zero.sql`** → **`supabase-rls-anon-pin-mode.sql`** (თუ ბაზა უკვე იყო და anon პოლიტიკა არ გაქვთ) → **`index.html`-ში `SU`/`SK`** → გახსნა და PIN.
