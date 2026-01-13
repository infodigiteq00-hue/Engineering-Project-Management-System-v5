-- ============================================================================
-- EQUIPMENT_TEAM_POSITIONS TABLE - RLS POLICIES
-- ============================================================================
-- Equipment team positions access control based on equipment's project
-- IMPORTANT: Run RLS_EQUIPMENT_TABLE.sql FIRST (equipment table RLS must exist)
-- IMPORTANT: Run RLS_PROJECT_MEMBERS_TABLE.sql FIRST to create is_assigned_to_project() function
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions

-- Step 1: Enable RLS
ALTER TABLE public.equipment_team_positions ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Firm admin can view firm equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Users can view assigned equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Super admin can create equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Firm admin can create firm equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Users can create equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Super admin can update all equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Firm admin can update firm equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Users can update equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Super admin can delete equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Firm admin can delete firm equipment team positions" ON public.equipment_team_positions;
DROP POLICY IF EXISTS "Users can delete equipment team positions" ON public.equipment_team_positions;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all equipment team positions
CREATE POLICY "Super admin can view all equipment team positions"
ON public.equipment_team_positions FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view equipment team positions in their firm's projects
CREATE POLICY "Firm admin can view firm equipment team positions"
ON public.equipment_team_positions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_team_positions.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 3: Users can view equipment team positions for equipment in projects they're assigned to
CREATE POLICY "Users can view assigned equipment team positions"
ON public.equipment_team_positions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_team_positions.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any equipment team position
CREATE POLICY "Super admin can create equipment team positions"
ON public.equipment_team_positions FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Firm Admin can create equipment team positions in their firm's projects
CREATE POLICY "Firm admin can create firm equipment team positions"
ON public.equipment_team_positions FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_team_positions.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
  AND (assigned_by = auth.uid() OR assigned_by IS NULL)
);

-- Policy 6: Users can create equipment team positions for equipment in projects they're assigned to
CREATE POLICY "Users can create equipment team positions"
ON public.equipment_team_positions FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_team_positions.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
  AND (assigned_by = auth.uid() OR assigned_by IS NULL)
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 7: Super Admin can update any equipment team position
CREATE POLICY "Super admin can update all equipment team positions"
ON public.equipment_team_positions FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 8: Firm Admin can update equipment team positions in their firm's projects
CREATE POLICY "Firm admin can update firm equipment team positions"
ON public.equipment_team_positions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_team_positions.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_team_positions.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 9: Users can update equipment team positions for equipment in projects they're assigned to
CREATE POLICY "Users can update equipment team positions"
ON public.equipment_team_positions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_team_positions.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_team_positions.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 10: Super Admin can delete any equipment team position
CREATE POLICY "Super admin can delete equipment team positions"
ON public.equipment_team_positions FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 11: Firm Admin can delete equipment team positions in their firm's projects
CREATE POLICY "Firm admin can delete firm equipment team positions"
ON public.equipment_team_positions FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_team_positions.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 12: Users can delete equipment team positions for equipment in projects they're assigned to
CREATE POLICY "Users can delete equipment team positions"
ON public.equipment_team_positions FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_team_positions.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

