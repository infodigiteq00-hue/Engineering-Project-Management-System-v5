-- ============================================================================
-- EQUIPMENT TABLE - RLS POLICIES
-- ============================================================================
-- Project-based equipment access control
-- IMPORTANT: Run RLS_PROJECT_MEMBERS_TABLE.sql FIRST to create is_assigned_to_project() function
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions (is_super_admin, get_user_firm_id, is_firm_admin)

-- Step 1: Enable RLS
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all equipment" ON public.equipment;
DROP POLICY IF EXISTS "Firm admin can view firm equipment" ON public.equipment;
DROP POLICY IF EXISTS "Users can view assigned project equipment" ON public.equipment;
DROP POLICY IF EXISTS "Super admin can create equipment" ON public.equipment;
DROP POLICY IF EXISTS "Firm admin can create firm equipment" ON public.equipment;
DROP POLICY IF EXISTS "Users can create equipment in assigned projects" ON public.equipment;
DROP POLICY IF EXISTS "Super admin can update all equipment" ON public.equipment;
DROP POLICY IF EXISTS "Firm admin can update firm equipment" ON public.equipment;
DROP POLICY IF EXISTS "Users can update equipment in assigned projects" ON public.equipment;
DROP POLICY IF EXISTS "Super admin can delete equipment" ON public.equipment;
DROP POLICY IF EXISTS "Firm admin can delete firm equipment" ON public.equipment;
DROP POLICY IF EXISTS "Users can delete equipment in assigned projects" ON public.equipment;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all equipment
CREATE POLICY "Super admin can view all equipment"
ON public.equipment FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view equipment in their firm's projects
CREATE POLICY "Firm admin can view firm equipment"
ON public.equipment FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = equipment.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 3: Users can view equipment in projects they're assigned to
CREATE POLICY "Users can view assigned project equipment"
ON public.equipment FOR SELECT
TO authenticated
USING (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any equipment
CREATE POLICY "Super admin can create equipment"
ON public.equipment FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Firm Admin can create equipment in their firm's projects
CREATE POLICY "Firm admin can create firm equipment"
ON public.equipment FOR INSERT
TO authenticated
WITH CHECK (
  project_id IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = equipment.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 6: Users can create equipment in projects they're assigned to
CREATE POLICY "Users can create equipment in assigned projects"
ON public.equipment FOR INSERT
TO authenticated
WITH CHECK (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 7: Super Admin can update any equipment
CREATE POLICY "Super admin can update all equipment"
ON public.equipment FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 8: Firm Admin can update equipment in their firm's projects
CREATE POLICY "Firm admin can update firm equipment"
ON public.equipment FOR UPDATE
TO authenticated
USING (
  project_id IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = equipment.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
)
WITH CHECK (
  project_id IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = equipment.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 9: Users can update equipment in projects they're assigned to
CREATE POLICY "Users can update equipment in assigned projects"
ON public.equipment FOR UPDATE
TO authenticated
USING (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
)
WITH CHECK (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
);

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 10: Super Admin can delete any equipment
CREATE POLICY "Super admin can delete equipment"
ON public.equipment FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 11: Firm Admin can delete equipment in their firm's projects
CREATE POLICY "Firm admin can delete firm equipment"
ON public.equipment FOR DELETE
TO authenticated
USING (
  project_id IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = equipment.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 12: Users can delete equipment in projects they're assigned to
-- Note: Typically only Project Managers/VDCR Managers should delete, but we allow all assigned users
CREATE POLICY "Users can delete equipment in assigned projects"
ON public.equipment FOR DELETE
TO authenticated
USING (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- AND tablename = 'equipment';

-- Check policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd
-- FROM pg_policies
-- WHERE tablename = 'equipment'
-- ORDER BY policyname;

