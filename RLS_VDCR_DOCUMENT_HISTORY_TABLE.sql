-- ============================================================================
-- VDCR_DOCUMENT_HISTORY TABLE - RLS POLICIES
-- ============================================================================
-- VDCR document history access control based on vdcr_record -> project assignment
-- IMPORTANT: Run RLS_VDCR_RECORDS_TABLE.sql FIRST
-- IMPORTANT: Run RLS_PROJECT_MEMBERS_TABLE.sql FIRST to create is_assigned_to_project() function
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions

-- Step 1: Enable RLS
ALTER TABLE public.vdcr_document_history ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Firm admin can view firm vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Users can view assigned vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Super admin can create vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Firm admin can create firm vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Users can create vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Super admin can update all vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Firm admin can update firm vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Users can update vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Super admin can delete vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Firm admin can delete firm vdcr document history" ON public.vdcr_document_history;
DROP POLICY IF EXISTS "Users can delete vdcr document history" ON public.vdcr_document_history;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all VDCR document history
CREATE POLICY "Super admin can view all vdcr document history"
ON public.vdcr_document_history FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view VDCR document history in their firm's projects
CREATE POLICY "Firm admin can view firm vdcr document history"
ON public.vdcr_document_history FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    JOIN public.projects p ON p.id = vr.project_id
    WHERE vr.id = vdcr_document_history.vdcr_record_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 3: Users can view VDCR document history for projects they're assigned to
CREATE POLICY "Users can view assigned vdcr document history"
ON public.vdcr_document_history FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_document_history.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any VDCR document history
CREATE POLICY "Super admin can create vdcr document history"
ON public.vdcr_document_history FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Firm Admin can create VDCR document history in their firm's projects
CREATE POLICY "Firm admin can create firm vdcr document history"
ON public.vdcr_document_history FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    JOIN public.projects p ON p.id = vr.project_id
    WHERE vr.id = vdcr_document_history.vdcr_record_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
  AND changed_by = auth.uid()
);

-- Policy 6: Users can create VDCR document history for projects they're assigned to
CREATE POLICY "Users can create vdcr document history"
ON public.vdcr_document_history FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_document_history.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
  AND changed_by = auth.uid()
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 7: Super Admin can update any VDCR document history
CREATE POLICY "Super admin can update all vdcr document history"
ON public.vdcr_document_history FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 8: Firm Admin can update VDCR document history in their firm's projects
CREATE POLICY "Firm admin can update firm vdcr document history"
ON public.vdcr_document_history FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    JOIN public.projects p ON p.id = vr.project_id
    WHERE vr.id = vdcr_document_history.vdcr_record_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    JOIN public.projects p ON p.id = vr.project_id
    WHERE vr.id = vdcr_document_history.vdcr_record_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 9: Users can update VDCR document history for projects they're assigned to
CREATE POLICY "Users can update vdcr document history"
ON public.vdcr_document_history FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_document_history.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_document_history.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
);

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 10: Super Admin can delete any VDCR document history
CREATE POLICY "Super admin can delete vdcr document history"
ON public.vdcr_document_history FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 11: Firm Admin can delete VDCR document history in their firm's projects
CREATE POLICY "Firm admin can delete firm vdcr document history"
ON public.vdcr_document_history FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    JOIN public.projects p ON p.id = vr.project_id
    WHERE vr.id = vdcr_document_history.vdcr_record_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 12: Users can delete VDCR document history for projects they're assigned to
CREATE POLICY "Users can delete vdcr document history"
ON public.vdcr_document_history FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_document_history.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
);

