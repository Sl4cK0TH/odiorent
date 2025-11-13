-- Row Level Security policies for the `properties` table.
-- These statements ensure landlords can only act on their own rows while
-- admins (role stored in public.profiles) retain full visibility.

-- Enable RLS if it is not already enabled.
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;

-- Helper condition reused across policies.
-- (Can be copied inline when running via the SQL editor if DO blocks are unsupported.)
-- CREATE OR REPLACE FUNCTION public.is_admin()
-- RETURNS BOOLEAN
-- LANGUAGE sql
-- STABLE
-- AS $$
--   SELECT EXISTS (
--     SELECT 1
--     FROM public.profiles
--     WHERE id = auth.uid()
--       AND role = 'admin'
--   );
-- $$;

DROP POLICY IF EXISTS landlords_select_own_properties ON public.properties;
-- Landlords (or admins) can only read their own properties unless they are admins.
CREATE POLICY landlords_select_own_properties
  ON public.properties
  FOR SELECT
  USING (
    landlord_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

DROP POLICY IF EXISTS landlords_insert_own_properties ON public.properties;
-- Landlords must insert rows tied to their own auth user id (admins bypass).
CREATE POLICY landlords_insert_own_properties
  ON public.properties
  FOR INSERT
  WITH CHECK (
    landlord_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

DROP POLICY IF EXISTS landlords_update_own_properties ON public.properties;
-- Landlords can only update their own rows; admins can update any row.
CREATE POLICY landlords_update_own_properties
  ON public.properties
  FOR UPDATE
  USING (
    landlord_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  )
  WITH CHECK (
    landlord_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );

DROP POLICY IF EXISTS landlords_delete_own_properties ON public.properties;
-- Landlords can only delete their own rows; admins keep full delete privileges.
CREATE POLICY landlords_delete_own_properties
  ON public.properties
  FOR DELETE
  USING (
    landlord_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'admin'
    )
  );
