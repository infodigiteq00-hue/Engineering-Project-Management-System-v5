-- ============================================================================
-- EQUIPMENT_PROGRESS_ENTRIES TABLE - RLS POLICIES
-- ============================================================================
-- Equipment progress entries access control based on equipment's project
-- IMPORTANT: Run RLS_EQUIPMENT_TABLE.sql FIRST (equipment table RLS must exist)
-- IMPORTANT: Run RLS_PROJECT_MEMBERS_TABLE.sql FIRST to create is_assigned_to_project() function
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions

-- Step 1: Enable RLS
ALTER TABLE public.equipment_progress_entries ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Firm admin can view firm equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Users can view assigned equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Super admin can create equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Firm admin can create firm equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Users can create equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Super admin can update all equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Firm admin can update firm equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Users can update own equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Super admin can delete equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Firm admin can delete firm equipment progress entries" ON public.equipment_progress_entries;
DROP POLICY IF EXISTS "Users can delete own equipment progress entries" ON public.equipment_progress_entries;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all equipment progress entries
CREATE POLICY "Super admin can view all equipment progress entries"
ON public.equipment_progress_entries FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view equipment progress entries in their firm's projects
CREATE POLICY "Firm admin can view firm equipment progress entries"
ON public.equipment_progress_entries FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_progress_entries.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 3: Users can view equipment progress entries for equipment in projects they're assigned to
CREATE POLICY "Users can view assigned equipment progress entries"
ON public.equipment_progress_entries FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_progress_entries.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any equipment progress entry
CREATE POLICY "Super admin can create equipment progress entries"
ON public.equipment_progress_entries FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Firm Admin can create equipment progress entries in their firm's projects
CREATE POLICY "Firm admin can create firm equipment progress entries"
ON public.equipment_progress_entries FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_progress_entries.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
  AND (created_by = auth.uid() OR created_by IS NULL)
);

-- Policy 6: Users can create equipment progress entries for equipment in projects they're assigned to
CREATE POLICY "Users can create equipment progress entries"
ON public.equipment_progress_entries FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_progress_entries.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
  AND (created_by = auth.uid() OR created_by IS NULL)
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 7: Super Admin can update any equipment progress entry
CREATE POLICY "Super admin can update all equipment progress entries"
ON public.equipment_progress_entries FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 8: Firm Admin can update equipment progress entries in their firm's projects
CREATE POLICY "Firm admin can update firm equipment progress entries"
ON public.equipment_progress_entries FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_progress_entries.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_progress_entries.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 9: Users can update their own equipment progress entries (created_by = auth.uid())
CREATE POLICY "Users can update own equipment progress entries"
ON public.equipment_progress_entries FOR UPDATE
TO authenticated
USING (
  created_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_progress_entries.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
)
WITH CHECK (
  created_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_progress_entries.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 10: Super Admin can delete any equipment progress entry
CREATE POLICY "Super admin can delete equipment progress entries"
ON public.equipment_progress_entries FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 11: Firm Admin can delete equipment progress entries in their firm's projects
CREATE POLICY "Firm admin can delete firm equipment progress entries"
ON public.equipment_progress_entries FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_progress_entries.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 12: Users can delete their own equipment progress entries (created_by = auth.uid())
CREATE POLICY "Users can delete own equipment progress entries"
ON public.equipment_progress_entries FOR DELETE
TO authenticated
USING (
  created_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_progress_entries.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- AND tablename = 'equipment_progress_entries';

-- Check policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd
-- FROM pg_policies
-- WHERE tablename = 'equipment_progress_entries'
-- ORDER BY policyname;

