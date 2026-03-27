# Supabase ონლაინ დაყენება (HRCore)

**მნიშვნელოვანი:** Supabase პროექტს **ვებგვერდზე** ქმნით — ერთი HTML/JS ფაილი ვერ „შექმნის“ თქვენს ღრუბლოვან ბაზას თქვენი სახელით. ქვემოთ არის ზუსტი ნაბიჯები და ბაზის **SQL კოდი** პროექტში ფაილად.

## 1. ანგარიში და პროექტი

1. გახსენით **https://supabase.com** → **Start your project** / **Sign up** (GitHub ან ელფოსტა).
2. **New project** → აირჩიეთ ორგანიზაცია, **Database password** (შეინახეთ!), რეგიონი.
3. დაელოდეთ რამდენიმე წუთს, სანამ პროექტი მზად იქნება.

## 2. ბაზის სქემა (SQL)

1. Supabase დაფაში: **SQL Editor** → **New query**.
2. გახსენით პროექტის ფაილი **`supabase-setup-from-zero.sql`** და **მთლიანი შიგთავსი** ჩასვით რედაქტორში → **Run**.

ეს ქმნის ცხრილებს, ხედებს (`employee_details`, `salary_summary`, …), საწყის მონაცემებს და RLS პოლიტიკებს.

თუ რაღაც უკვე არსებობს ძველ პროექტში, Run-მა შეიძლება შეცდომა მისცეს — ახალ (ცარიელ) პროექტზე გაუშვით.

**შეცდომა `relation "public.employees" does not exist`:** ნიშნავს, რომ **`supabase-migration.sql`** ან **`supabase-production-schema.sql`** გაუშვით **ადრე**, ვიდრე სრულ სქემას. **ჯერ** გაუშვით მხოლოდ **`supabase-setup-from-zero.sql`**. ახალ პროექტზე `supabase-migration.sql` ჩვეულებრივ **არ არის საჭირო** (იგივე სვეტები setup ფაილში უკვე შედის).

## 3. API გასაღებები აპში

1. **Project Settings** (ხინჯი) → **API**.
2 დააკოპირეთ:
   - **Project URL**
   - **anon public** key (არა `service_role` — ეს საიდუმლოა და არ უნდა ჩაეწეროს საიტზე).

3. ფაილში **`index.html`** იპოვეთ:

```js
const SU='https://....supabase.co';
const SK='eyJhbGciOiJIUzI1NiIs...';
```

ჩასვით თქვენი **URL** და **anon** გასაღები.

## 4. პირველი ადმინისტრატორი

1. **Authentication** → **Users** → **Add user** → ელფოსტა + პაროლი (ან **Sign up** აპიდან).
2. იმავე გვერდზე დააკოპირეთ მომხმარებლის **UUID**.
3. **SQL Editor**:

```sql
INSERT INTO public.profiles (id, role, employee_id, display_name)
VALUES (
  'აქ-ჩასვით-UUID',
  'admin',
  NULL,
  'თქვენი სახელი'
);
```

თუ **Confirm email** ჩართულია, ჯერ დაადასტურეთ ელფოსტა, შემდეგ შედით აპში.

## 5. თანამშრომლის პორტალი

როცა თანამშრომელს ცალკე ანგარიში უნდა:

- `profiles.role` = `'employee'`
- `profiles.employee_id` = `employees.id` (იგივე პირი ცხრილ `employees`-ში).

## ფაილები პროექტში

| ფაილი | დანიშნულება |
|--------|-------------|
| `supabase-setup-from-zero.sql` | ახალი პროექტი სრულად |
| `supabase-production-schema.sql` | დამატება უკვე არსებულ ბაზაზე (profiles, RLS, სვეტები) |
| `supabase-migration.sql` | დამატებითი სვეტები (ჯანმრთელობა, issued_items, overtime …) |

## 6. GitHub Pages მისამართის მიბმა Supabase-ზე

როცა აპი ეშვება **GitHub Pages**-ზე (მაგ. რეპო [tiflisi2020-alt/restaurant-hr](https://github.com/tiflisi2020-alt/restaurant-hr)), სრული მისამართი ჩვეულებრივ არის:

**`https://tiflisi2020-alt.github.io/restaurant-hr/`**

(ბოლო `/` ხშირად მნიშვნელოვანია Redirect URL-ებისთვის.)

### 6.1 GitHub-ში Pages ჩართვა

1. რეპოზიტორია → **Settings** → **Pages**.
2. **Source**: Deploy from branch **main**, ფოლდერი **/ (root)** → **Save**.
3. 1–2 წუთში გაიხსნება ზემოთ მოცემული `github.io` მისამართი (შეამოწმე **Actions** თუ build-ს ითხოვს).

### 6.2 Supabase-ში URL-ების დაყენება

1. [Supabase Dashboard](https://supabase.com/dashboard) → შენი პროექტი.
2. **Authentication** → **URL Configuration** (ან **Redirect URLs** / **Site URL** — ინტერფეისის მიხედვით).
3. **Site URL** (ძირითადი საიტის მისამართი):  
   `https://tiflisi2020-alt.github.io/restaurant-hr/`
4. **Redirect URLs** (დაშვებული გადამისამართებები) — დაამატე ერთი ხაზით თითო (ან ორივე, თუ ლოკალურადაც იყენებ):

   - `https://tiflisi2020-alt.github.io/restaurant-hr/**`
   - `http://localhost:8080/**` (ან სადაც `npm run start` გაქვს)

5. **Save**.

ამის შემდეგ **ელფოსტის დადასტურების ბმულები**, **პაროლის აღდგენა** და სხვა Auth redirect-ები აღარ „დაეცემა“ არასწორ დომენზე.

**შენიშვნა:** `index.html`-ში უკვე ჩაწერილია **Project URL** და **anon key** — ისინი **იგივე რჩება**; იცვლება მხოლოდ Supabase-ის **დაშვებული მისამართების სია**, არა კოდის `SU`/`SK` (თუ პროექტს არ ცვლი).

### შეცდომა: `Could not find the table 'public.profiles' in the schema cache`

ეს ნიშნავს, რომ **`profiles` ცხრილი არ არსებობს** იმ Supabase პროექტში, რომლის **URL/anon key**-იც `index.html`-ში გაქვს (ან API ჯერ ვერ დაინახა ცხრილი).

1. **Table Editor** → ნახე, არის თუ არა `profiles`. თუ არა:
2. თუ **`employees` უკვე გაქვს** → SQL Editor-ში გაუშვი **`supabase-fix-profiles-table.sql`**.
3. თუ **`employees`-იც არ გაქვს** → გაუშვი სრული **`supabase-setup-from-zero.sql`** (ერთი Run).
4. გვერდი განაახლე; საჭიროების შემთხვევაში Supabase **Settings → API** → **Reload schema** (თუ ჩანს).

---

**შეჯამება:** „ონლაინ Supabase-ის შექმნა“ = **supabase.com-ზე პროექტის შექმნა**; „კოდი“ ბაზისთვის = **`supabase-setup-from-zero.sql`**-ის გაშვება SQL Editor-ში.
