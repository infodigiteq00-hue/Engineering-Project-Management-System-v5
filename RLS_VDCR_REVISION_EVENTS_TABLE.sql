-- ============================================================================
-- VDCR_REVISION_EVENTS TABLE - RLS POLICIES
-- ============================================================================
-- VDCR revision events access control based on vdcr_record -> project assignment
-- IMPORTANT: Run RLS_VDCR_RECORDS_TABLE.sql FIRST
-- IMPORTANT: Run RLS_PROJECT_MEMBERS_TABLE.sql FIRST to create is_assigned_to_project() function
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions

-- Step 1: Enable RLS
ALTER TABLE public.vdcr_revision_events ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Firm admin can view firm vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Users can view assigned vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Super admin can create vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Firm admin can create firm vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Users can create vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Super admin can update all vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Firm admin can update firm vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Users can update vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Super admin can delete vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Firm admin can delete firm vdcr revision events" ON public.vdcr_revision_events;
DROP POLICY IF EXISTS "Users can delete vdcr revision events" ON public.vdcr_revision_events;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all VDCR revision events
CREATE POLICY "Super admin can view all vdcr revision events"
ON public.vdcr_revision_events FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view VDCR revision events in their firm's projects
CREATE POLICY "Firm admin can view firm vdcr revision events"
ON public.vdcr_revision_events FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    JOIN public.projects p ON p.id = vr.project_id
    WHERE vr.id = vdcr_revision_events.vdcr_record_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 3: Users can view VDCR revision events for projects they're assigned to
CREATE POLICY "Users can view assigned vdcr revision events"
ON public.vdcr_revision_events FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_revision_events.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any VDCR revision event
CREATE POLICY "Super admin can create vdcr revision events"
ON public.vdcr_revision_events FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Firm Admin can create VDCR revision events in their firm's projects
CREATE POLICY "Firm admin can create firm vdcr revision events"
ON public.vdcr_revision_events FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    JOIN public.projects p ON p.id = vr.project_id
    WHERE vr.id = vdcr_revision_events.vdcr_record_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
  AND (created_by = auth.uid() OR created_by IS NULL)
);

-- Policy 6: Users can create VDCR revision events for projects they're assigned to
CREATE POLICY "Users can create vdcr revision events"
ON public.vdcr_revision_events FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_revision_events.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
  AND (created_by = auth.uid() OR created_by IS NULL)
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 7: Super Admin can update any VDCR revision event
CREATE POLICY "Super admin can update all vdcr revision events"
ON public.vdcr_revision_events FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 8: Firm Admin can update VDCR revision events in their firm's projects
CREATE POLICY "Firm admin can update firm vdcr revision events"
ON public.vdcr_revision_events FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    JOIN public.projects p ON p.id = vr.project_id
    WHERE vr.id = vdcr_revision_events.vdcr_record_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    JOIN public.projects p ON p.id = vr.project_id
    WHERE vr.id = vdcr_revision_events.vdcr_record_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 9: Users can update VDCR revision events for projects they're assigned to
CREATE POLICY "Users can update vdcr revision events"
ON public.vdcr_revision_events FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_revision_events.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_revision_events.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
);

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 10: Super Admin can delete any VDCR revision event
CREATE POLICY "Super admin can delete vdcr revision events"
ON public.vdcr_revision_events FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 11: Firm Admin can delete VDCR revision events in their firm's projects
CREATE POLICY "Firm admin can delete firm vdcr revision events"
ON public.vdcr_revision_events FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    JOIN public.projects p ON p.id = vr.project_id
    WHERE vr.id = vdcr_revision_events.vdcr_record_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 12: Users can delete VDCR revision events for projects they're assigned to
CREATE POLICY "Users can delete vdcr revision events"
ON public.vdcr_revision_events FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_revision_events.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
);

