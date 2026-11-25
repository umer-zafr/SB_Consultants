-- =============================================================================
-- SB Consultants — Comprehensive Production Security Hardening Migration
-- Generated during Production Security Audit (Phase 3, 4, 8 & 9)
-- =============================================================================

-- 1. STAFF INVITATIONS: Enable RLS and restrict all access to Super Admins only
-- CRITICAL FIX: Previously rls_enabled was false, exposing invite links and allowing
-- arbitrary privilege escalation.
ALTER TABLE public.staff_invitations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins have full access to staff invitations" ON public.staff_invitations;
CREATE POLICY "Admins have full access to staff invitations"
ON public.staff_invitations
FOR ALL
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- 2. APPLICATION PROCEDURES: Fix data leakage and unrestricted insert
DROP POLICY IF EXISTS "Users can view procedures for own applications" ON public.application_procedures;
CREATE POLICY "Users can view procedures for own applications"
ON public.application_procedures
FOR SELECT
USING (
  public.is_staff() OR
  EXISTS (
    SELECT 1 FROM public.applications
    WHERE applications.id = application_procedures.application_id
      AND applications.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Anyone can insert procedures" ON public.application_procedures;
DROP POLICY IF EXISTS "Users can insert procedures for own applications" ON public.application_procedures;
CREATE POLICY "Users can insert procedures for own applications"
ON public.application_procedures
FOR INSERT
WITH CHECK (
  public.is_staff() OR
  EXISTS (
    SELECT 1 FROM public.applications
    WHERE applications.id = application_procedures.application_id
      AND applications.user_id = auth.uid()
  )
);

-- 3. APPLICATION STATUS HISTORY: Restrict insert to staff or applicant
DROP POLICY IF EXISTS "Anyone can insert application history" ON public.application_status_history;
DROP POLICY IF EXISTS "Users can insert application history for own applications" ON public.application_status_history;
CREATE POLICY "Users can insert application history for own applications"
ON public.application_status_history
FOR INSERT
WITH CHECK (
  public.is_staff() OR
  EXISTS (
    SELECT 1 FROM public.applications
    WHERE applications.id = application_status_history.application_id
      AND applications.user_id = auth.uid()
  )
);

-- 4. APPLICATIONS: Prevent anonymous row exposure and enforce authenticated user_id
DROP POLICY IF EXISTS "Users can view own applications" ON public.applications;
CREATE POLICY "Users can view own applications"
ON public.applications
FOR SELECT
USING (
  (auth.uid() = user_id) OR public.is_staff() OR public.is_admin()
);

DROP POLICY IF EXISTS "Users can submit applications" ON public.applications;
CREATE POLICY "Users can submit applications"
ON public.applications
FOR INSERT
WITH CHECK (
  (auth.uid() = user_id) OR public.is_staff()
);

-- 5. CONSULTANCY BOOKINGS: Prevent anonymous booking leakage and enforce caller ownership
DROP POLICY IF EXISTS "Users can view own bookings" ON public.consultancy_bookings;
CREATE POLICY "Users can view own bookings"
ON public.consultancy_bookings
FOR SELECT
USING (
  (auth.uid() = user_id) OR public.is_staff() OR public.is_admin()
);

DROP POLICY IF EXISTS "Users can insert own bookings" ON public.consultancy_bookings;
CREATE POLICY "Users can insert own bookings"
ON public.consultancy_bookings
FOR INSERT
WITH CHECK (
  (auth.uid() = user_id) OR public.is_staff()
);

-- 6. PAYMENTS: Remove anonymous payment exposure, enforce caller ownership & initial pending status
DROP POLICY IF EXISTS "Users can view own payments" ON public.payments;
CREATE POLICY "Users can view own payments"
ON public.payments
FOR SELECT
USING (
  (auth.uid() = user_id) OR public.is_admin()
);

DROP POLICY IF EXISTS "Users can create payments" ON public.payments;
CREATE POLICY "Users can create payments"
ON public.payments
FOR INSERT
WITH CHECK (
  ((auth.uid() = user_id) OR public.is_admin()) AND
  (status = 'pending' OR public.is_admin())
);

-- Prevent unauthorized payment updates (status manipulation) by client users
CREATE OR REPLACE FUNCTION public.prevent_unauthorized_payment_tampering()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT (public.is_admin() OR auth.role() = 'service_role') THEN
    IF NEW.status IS DISTINCT FROM OLD.status OR
       NEW.amount IS DISTINCT FROM OLD.amount OR
       NEW.user_id IS DISTINCT FROM OLD.user_id OR
       NEW.transaction_id IS DISTINCT FROM OLD.transaction_id THEN
      RAISE EXCEPTION 'Security error: Only the payment gateway webhook or administrators can update payment status or financial details';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_unauthorized_payment_tampering ON public.payments;
CREATE TRIGGER trg_prevent_unauthorized_payment_tampering
BEFORE UPDATE ON public.payments
FOR EACH ROW
EXECUTE FUNCTION public.prevent_unauthorized_payment_tampering();

-- 7. USER DIRECTORY UNLOCKS: Remove anonymous access and enforce authenticated user_id
DROP POLICY IF EXISTS "Users can insert own unlocks" ON public.user_directory_unlocks;
CREATE POLICY "Users can insert own unlocks"
ON public.user_directory_unlocks
FOR INSERT
WITH CHECK (
  (auth.uid() = user_id) OR public.is_admin()
);

DROP POLICY IF EXISTS "Users can update own unlocks" ON public.user_directory_unlocks;
CREATE POLICY "Users can update own unlocks"
ON public.user_directory_unlocks
FOR UPDATE
USING (
  (auth.uid() = user_id) OR public.is_admin()
)
WITH CHECK (
  (auth.uid() = user_id) OR public.is_admin()
);

-- 8. PROFILES: Allow Staff/Consultants to view client profiles for case management
DROP POLICY IF EXISTS "Staff can view client profiles" ON public.profiles;
CREATE POLICY "Staff can view client profiles"
ON public.profiles
FOR SELECT
USING (public.is_staff());

-- 9. TRIGGER: Prevent unauthorized application escalation on INSERT or UPDATE
CREATE OR REPLACE FUNCTION public.prevent_unauthorized_application_escalation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    IF TG_OP = 'INSERT' THEN
      -- Standard applicants can only submit with initial status and progress <= 15
      IF NEW.status NOT IN ('submitted', 'pending', 'new') OR
         NEW.current_step > 1 OR
         NEW.progress_percent > 15 OR
         NEW.assigned_consultant_id IS NOT NULL OR
         NEW.admin_internal_notes IS NOT NULL THEN
        RAISE EXCEPTION 'Security error: New applications cannot be submitted with pre-approved status, consultant assignments, or staff notes';
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.status IS DISTINCT FROM OLD.status OR
         NEW.current_step IS DISTINCT FROM OLD.current_step OR
         NEW.progress_percent IS DISTINCT FROM OLD.progress_percent OR
         NEW.assigned_consultant_id IS DISTINCT FROM OLD.assigned_consultant_id OR
         NEW.assigned_consultant_name IS DISTINCT FROM OLD.assigned_consultant_name OR
         NEW.admin_internal_notes IS DISTINCT FROM OLD.admin_internal_notes THEN
        RAISE EXCEPTION 'Security error: Only authorized staff members can modify application review status, steps, consultant assignments, or staff notes';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_unauthorized_application_escalation ON public.applications;
CREATE TRIGGER trg_prevent_unauthorized_application_escalation
BEFORE INSERT OR UPDATE ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.prevent_unauthorized_application_escalation();
