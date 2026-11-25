-- =============================================================================
-- SB Consultants — Production Security Hardening Migration
-- Generated during Phase 3 & 4 Pre-Launch Security Audit
-- =============================================================================

-- 1. APPLICATION PROCEDURES: Fix data leakage and unrestricted insert
-- Issue: Previous policy qual was `true`, exposing private case procedures of all applicants
DROP POLICY IF EXISTS "Users can view procedures for own applications" ON public.application_procedures;
CREATE POLICY "Users can view procedures for own applications"
ON public.application_procedures
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.applications
    WHERE applications.id = application_procedures.application_id
      AND (applications.user_id = auth.uid() OR public.is_staff())
  )
);

DROP POLICY IF EXISTS "Anyone can insert procedures" ON public.application_procedures;
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

-- 2. APPLICATION STATUS HISTORY: Fix unrestricted public insert
DROP POLICY IF EXISTS "Anyone can insert application history" ON public.application_status_history;
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

-- 3. APPLICATIONS: Prevent anonymous row exposure and enforce authenticated user_id
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

-- 4. CONSULTANCY BOOKINGS: Prevent anonymous booking leakage
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

-- 5. PAYMENTS: Remove anonymous payment exposure and enforce caller ownership
DROP POLICY IF EXISTS "Users can view own payments" ON public.payments;
CREATE POLICY "Users can view own payments"
ON public.payments
FOR SELECT
USING (
  (auth.uid() = user_id) OR public.is_staff() OR public.is_admin()
);

DROP POLICY IF EXISTS "Users can create payments" ON public.payments;
CREATE POLICY "Users can create payments"
ON public.payments
FOR INSERT
WITH CHECK (
  (auth.uid() = user_id) OR public.is_staff()
);

-- 6. TRIGGER: Prevent applicants from self-approving or modifying internal review fields
CREATE OR REPLACE FUNCTION public.prevent_unauthorized_application_escalation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    IF NEW.status IS DISTINCT FROM OLD.status OR
       NEW.current_step IS DISTINCT FROM OLD.current_step OR
       NEW.progress_percent IS DISTINCT FROM OLD.progress_percent OR
       NEW.assigned_consultant_id IS DISTINCT FROM OLD.assigned_consultant_id OR
       NEW.assigned_consultant_name IS DISTINCT FROM OLD.assigned_consultant_name OR
       NEW.admin_internal_notes IS DISTINCT FROM OLD.admin_internal_notes THEN
      RAISE EXCEPTION 'Security error: Only authorized staff members can modify application review status, steps, consultant assignments, or staff notes';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_unauthorized_application_escalation ON public.applications;
CREATE TRIGGER trg_prevent_unauthorized_application_escalation
BEFORE UPDATE ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.prevent_unauthorized_application_escalation();

-- 7. TRIGGER: Prevent unauthenticated/unpaid user_directory_unlocks
CREATE OR REPLACE FUNCTION public.prevent_unauthorized_directory_unlock()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.is_active = true AND (OLD IS NULL OR OLD.is_active IS DISTINCT FROM NEW.is_active) THEN
    IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
      IF NEW.payment_id IS NOT NULL THEN
        IF NOT EXISTS (
          SELECT 1 FROM public.payments
          WHERE id = NEW.payment_id AND status = 'completed' AND user_id = NEW.user_id
        ) THEN
          RAISE EXCEPTION 'Security error: Directory unlock requires a verified, completed payment record';
        END IF;
      ELSE
        RAISE EXCEPTION 'Security error: Unauthorized directory unlock activation';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_unauthorized_directory_unlock ON public.user_directory_unlocks;
CREATE TRIGGER trg_prevent_unauthorized_directory_unlock
BEFORE INSERT OR UPDATE ON public.user_directory_unlocks
FOR EACH ROW
EXECUTE FUNCTION public.prevent_unauthorized_directory_unlock();
