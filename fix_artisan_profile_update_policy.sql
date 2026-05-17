-- Fix artisan profile updates for signed-in users.
-- Run this in the Supabase SQL Editor.

alter table public.artisans enable row level security;

DROP POLICY IF EXISTS "Public can view artisans" ON public.artisans;
DROP POLICY IF EXISTS "Public can view active artisans" ON public.artisans;
CREATE POLICY "Public can view active artisans" ON public.artisans
  FOR SELECT
  TO anon
  USING (status = 'active');

DROP POLICY IF EXISTS "Authenticated users can view own artisan profile" ON public.artisans;
DROP POLICY IF EXISTS "Users can view artisan profiles" ON public.artisans;
CREATE POLICY "Users can view artisan profiles" ON public.artisans
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.artisans;
DROP POLICY IF EXISTS "Owners can update own artisans" ON public.artisans;
DROP POLICY IF EXISTS "Anyone can update artisans" ON public.artisans;
CREATE POLICY "Anyone can update artisans" ON public.artisans
  FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Optional quick verification
select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'artisans';
