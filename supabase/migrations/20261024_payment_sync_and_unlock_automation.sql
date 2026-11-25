-- =============================================================================
-- SB Consultants — Payment Sync, Directory Unlock & Application Escalation Fix
-- Migration: 20261024_payment_sync_and_unlock_automation.sql
-- =============================================================================

-- 1. FIX APPLICATION ESCALATION TRIGGER
-- Allow initial bank transfer applications with status 'under_review' and progress_percent <= 25.
CREATE OR REPLACE FUNCTION public.prevent_unauthorized_application_escalation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    IF TG_OP = 'INSERT' THEN
      -- Standard applicants can submit with initial status (submitted, pending, new, under_review)
      -- and step 1 (progress <= 25%)
      IF NEW.status NOT IN ('submitted', 'pending', 'new', 'under_review') OR
         NEW.current_step > 1 OR
         NEW.progress_percent > 25 OR
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

-- 2. ENHANCE DIRECTORY UNLOCK VALIDATION TRIGGER
-- Allow automatic resolution of completed payment when payment_id is null or omitted by client.
CREATE OR REPLACE FUNCTION public.prevent_unauthorized_directory_unlock()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_matching_payment_id uuid;
BEGIN
  IF NEW.is_active = true AND (OLD IS NULL OR OLD.is_active IS DISTINCT FROM NEW.is_active) THEN
    IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
      IF NEW.payment_id IS NOT NULL THEN
        IF NOT EXISTS (
          SELECT 1 FROM public.payments
          WHERE id = NEW.payment_id AND status IN ('completed', 'success') AND user_id = NEW.user_id
        ) THEN
          RAISE EXCEPTION 'Security error: Directory unlock requires a verified, completed payment record';
        END IF;
      ELSE
        -- If payment_id is null, verify if a completed payment exists for this user and directory type
        SELECT id INTO v_matching_payment_id
        FROM public.payments
        WHERE user_id = NEW.user_id
          AND status IN ('completed', 'success')
          AND (
            (NEW.directory_type = 'scholarships' AND (listing_id ILIKE '%scholarship%' OR reference_id ILIKE '%scholarship%')) OR
            (NEW.directory_type = 'sponsored_jobs' AND (listing_id ILIKE '%job%' OR reference_id ILIKE '%job%'))
          )
        ORDER BY created_at DESC
        LIMIT 1;

        IF v_matching_payment_id IS NOT NULL THEN
          NEW.payment_id := v_matching_payment_id;
        ELSE
          RAISE EXCEPTION 'Security error: Unauthorized directory unlock activation. No completed payment found for %', NEW.directory_type;
        END IF;
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- 3. AUTOMATIC PAYMENT STATUS SYNCHRONIZATION TRIGGER
-- When any payment is marked completed or success, immediately:
-- a) Unlock scholarships directory if listing_id contains scholarship
-- b) Unlock sponsored jobs directory if listing_id contains job
-- c) Clear application bank transfer verification alert and advance to Step 1: Profile Review
CREATE OR REPLACE FUNCTION public.on_payment_status_changed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_listing_id text;
  v_ref_id text;
  v_item_title text;
  v_app_id uuid;
BEGIN
  IF (NEW.status IN ('completed', 'success')) AND (OLD IS NULL OR OLD.status NOT IN ('completed', 'success')) THEN
    v_listing_id := LOWER(COALESCE(NEW.listing_id, ''));
    v_ref_id := LOWER(COALESCE(NEW.reference_id, ''));
    v_item_title := LOWER(COALESCE(NEW.gateway_response->>'itemTitle', ''));

    -- A. SCHOLARSHIPS UNLOCK
    IF v_listing_id LIKE '%scholarship%' OR v_ref_id LIKE '%scholarship%' OR v_item_title LIKE '%scholarship%' THEN
      IF NEW.user_id IS NOT NULL THEN
        INSERT INTO public.user_directory_unlocks (user_id, directory_type, payment_id, is_active, created_at)
        VALUES (NEW.user_id, 'scholarships', NEW.id, true, now())
        ON CONFLICT (user_id, directory_type)
        DO UPDATE SET is_active = true, payment_id = EXCLUDED.payment_id;
      END IF;
    END IF;

    -- B. SPONSORED JOBS UNLOCK
    IF v_listing_id LIKE '%job%' OR v_ref_id LIKE '%job%' OR v_item_title LIKE '%job%' THEN
      IF NEW.user_id IS NOT NULL THEN
        INSERT INTO public.user_directory_unlocks (user_id, directory_type, payment_id, is_active, created_at)
        VALUES (NEW.user_id, 'sponsored_jobs', NEW.id, true, now())
        ON CONFLICT (user_id, directory_type)
        DO UPDATE SET is_active = true, payment_id = EXCLUDED.payment_id;
      END IF;
    END IF;

    -- C. APPLICATION STATUS SYNC (Clear Bank Transfer alert and move to Step 1: Profile Review)
    v_app_id := NEW.application_id;
    IF v_app_id IS NULL AND NEW.user_id IS NOT NULL THEN
      SELECT id INTO v_app_id
      FROM public.applications
      WHERE (reference_number = NEW.reference_id OR (user_id = NEW.user_id AND listing_id = NEW.listing_id))
      ORDER BY applied_at DESC
      LIMIT 1;
    END IF;

    IF v_app_id IS NOT NULL THEN
      UPDATE public.applications
      SET status = 'submitted',
          status_label = 'Profile Review',
          status_bg_color = 4008637433,
          status_text_color = 4030587270,
          has_alert = false,
          alert_title = null,
          alert_body = null,
          current_step = 1,
          step_text = 'Step 1 of 5: Profile Review',
          progress_percent = 20,
          form_data = COALESCE(form_data, '{}'::jsonb) || '{"payment_verified": true}'::jsonb,
          updated_at = now()
      WHERE id = v_app_id;

      NEW.application_id := v_app_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_on_payment_status_changed'
  ) THEN
    CREATE TRIGGER trg_on_payment_status_changed
    BEFORE INSERT OR UPDATE ON public.payments
    FOR EACH ROW
    EXECUTE FUNCTION public.on_payment_status_changed();
  END IF;
END $$;
