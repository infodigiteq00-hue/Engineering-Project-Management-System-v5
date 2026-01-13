-- ============================================================================
-- VDCR_RECORDS TABLE - RLS POLICIES
-- ============================================================================
-- VDCR records access control based on project assignment
-- IMPORTANT: Run RLS_PROJECTS_TABLE.sql FIRST
-- IMPORTANT: Run RLS_PROJECT_MEMBERS_TABLE.sql FIRST to create is_assigned_to_project() function
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions

-- Step 1: Enable RLS
ALTER TABLE public.vdcr_records ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Firm admin can view firm vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Users can view assigned project vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Super admin can create vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Firm admin can create firm vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Users can create vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Super admin can update all vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Firm admin can update firm vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Users can update vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Super admin can delete vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Firm admin can delete firm vdcr records" ON public.vdcr_records;
DROP POLICY IF EXISTS "Users can delete vdcr records" ON public.vdcr_records;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all VDCR records
CREATE POLICY "Super admin can view all vdcr records"
ON public.vdcr_records FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view VDCR records in their firm's projects
CREATE POLICY "Firm admin can view firm vdcr records"
ON public.vdcr_records FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = vdcr_records.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 3: Users can view VDCR records for projects they're assigned to
CREATE POLICY "Users can view assigned project vdcr records"
ON public.vdcr_records FOR SELECT
TO authenticated
USING (public.is_assigned_to_project(project_id));

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any VDCR record
CREATE POLICY "Super admin can create vdcr records"
ON public.vdcr_records FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Firm Admin can create VDCR records in their firm's projects
CREATE POLICY "Firm admin can create firm vdcr records"
ON public.vdcr_records FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = vdcr_records.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 6: Users can create VDCR records for projects they're assigned to
CREATE POLICY "Users can create vdcr records"
ON public.vdcr_records FOR INSERT
TO authenticated
WITH CHECK (public.is_assigned_to_project(project_id));

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 7: Super Admin can update any VDCR record
CREATE POLICY "Super admin can update all vdcr records"
ON public.vdcr_records FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 8: Firm Admin can update VDCR records in their firm's projects
CREATE POLICY "Firm admin can update firm vdcr records"
ON public.vdcr_records FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = vdcr_records.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = vdcr_records.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 9: Users can update VDCR records for projects they're assigned to
CREATE POLICY "Users can update vdcr records"
ON public.vdcr_records FOR UPDATE
TO authenticated
USING (public.is_assigned_to_project(project_id))
WITH CHECK (public.is_assigned_to_project(project_id));

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 10: Super Admin can delete any VDCR record
CREATE POLICY "Super admin can delete vdcr records"
ON public.vdcr_records FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 11: Firm Admin can delete VDCR records in their firm's projects
CREATE POLICY "Firm admin can delete firm vdcr records"
ON public.vdcr_records FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = vdcr_records.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 12: Users can delete VDCR records for projects they're assigned to (with proper role: project_manager or vdcr_manager)
CREATE POLICY "Users can delete vdcr records"
ON public.vdcr_records FOR DELETE
TO authenticated
USING (
  public.is_assigned_to_project(project_id)
  AND EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = vdcr_records.project_id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager', 'vdcr_manager')
    AND pm.status = 'active'
  )
);

