-- ============================================================
-- AUTO-SYNC users.role WHEN profiles_pro IS CREATED
-- Fixes: "Become Pro" flow where RLS blocks client-side role update
-- ============================================================

CREATE OR REPLACE FUNCTION public.sync_role_on_profiles_pro_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.users
  SET role = 'pro'
  WHERE id = NEW.id AND (role IS DISTINCT FROM 'pro');
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_role_on_profiles_pro_insert
  AFTER INSERT ON public.profiles_pro
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_role_on_profiles_pro_insert();
