-- Fix artisan profile updates for signed-in users.
-- Applied via Supabase CLI migration.

alter table public.artisans enable row level security;

DROP POLICY IF EXISTS "Public can view artisans" ON public.artisans;
DROP POLICY IF EXISTS "Public can view active artisans" ON public.artisans;
CREATE POLICY "Public can view active artisans" ON public.artisans
  FOR SELECT
  TO anon
  USING (status = 'active');

DROP POLICY IF EXISTS "Authenticated users can view own artisan profile" ON public.artisans;
CREATE POLICY "Authenticated users can view own artisan profile" ON public.artisans
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.artisans;
DROP POLICY IF EXISTS "Owners can update own artisans" ON public.artisans;
CREATE POLICY "Users can update own profile" ON public.artisans
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);
