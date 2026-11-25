-- =============================================================================
-- SB Consultants — Two-Tier RBAC Hardening & Policy Refinement
-- 1. Allow Consultants / Staff to read client profiles (for case management)
-- 2. Restrict Payments table so that only Super Admins (role = 'admin') or 
--    the paying user themselves can view payments
-- =============================================================================

-- 1. Profiles Table Policy
DROP POLICY IF EXISTS "Staff can view client profiles" ON public.profiles;
CREATE POLICY "Staff can view client profiles"
ON public.profiles
FOR SELECT
USING (public.is_staff());

-- 2. Payments Table Policy
DROP POLICY IF EXISTS "Users can view own payments" ON public.payments;
CREATE POLICY "Users can view own payments"
ON public.payments
FOR SELECT
USING (
  (auth.uid() = user_id) OR public.is_admin()
);
