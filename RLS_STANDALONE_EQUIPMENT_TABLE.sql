-- ============================================================================
-- STANDALONE_EQUIPMENT TABLE - RLS POLICIES
-- ============================================================================
-- Standalone equipment access control (no project_id, uses created_by and team_positions)
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions

-- Step 1: Enable RLS
ALTER TABLE public.standalone_equipment ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all standalone equipment" ON public.standalone_equipment;
DROP POLICY IF EXISTS "Firm admin can view firm standalone equipment" ON public.standalone_equipment;
DROP POLICY IF EXISTS "Users can view assigned standalone equipment" ON public.standalone_equipment;
DROP POLICY IF EXISTS "Super admin can create standalone equipment" ON public.standalone_equipment;
DROP POLICY IF EXISTS "Users can create standalone equipment" ON public.standalone_equipment;
DROP POLICY IF EXISTS "Super admin can update all standalone equipment" ON public.standalone_equipment;
DROP POLICY IF EXISTS "Firm admin can update firm standalone equipment" ON public.standalone_equipment;
DROP POLICY IF EXISTS "Users can update own standalone equipment" ON public.standalone_equipment;
DROP POLICY IF EXISTS "Super admin can delete standalone equipment" ON public.standalone_equipment;
DROP POLICY IF EXISTS "Firm admin can delete firm standalone equipment" ON public.standalone_equipment;
DROP POLICY IF EXISTS "Users can delete own standalone equipment" ON public.standalone_equipment;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all standalone equipment
CREATE POLICY "Super admin can view all standalone equipment"
ON public.standalone_equipment FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view standalone equipment from their firm (via created_by -> users.firm_id)
CREATE POLICY "Firm admin can view firm standalone equipment"
ON public.standalone_equipment FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users u1
    WHERE u1.id = auth.uid()
    AND u1.role = 'firm_admin'
    AND u1.is_active = true
    AND EXISTS (
      SELECT 1 FROM public.users u2
      WHERE u2.id = standalone_equipment.created_by
      AND u2.firm_id = u1.firm_id
    )
  )
);

-- Policy 3: Users can view standalone equipment they're assigned to (via team_positions) or created
-- FIXED: Use SECURITY DEFINER function to avoid infinite recursion when checking team_positions
CREATE OR REPLACE FUNCTION public.is_user_assigned_to_standalone_equipment(equipment_id_param uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.standalone_equipment_team_positions tp
    JOIN public.users u ON LOWER(TRIM(tp.email)) = LOWER(TRIM(u.email))
    WHERE tp.equipment_id = equipment_id_param
    AND u.id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

CREATE POLICY "Users can view assigned standalone equipment"
ON public.standalone_equipment FOR SELECT
TO authenticated
USING (
  public.is_user_assigned_to_standalone_equipment(standalone_equipment.id)
  OR created_by = auth.uid()
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any standalone equipment
CREATE POLICY "Super admin can create standalone equipment"
ON public.standalone_equipment FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Users can create standalone equipment (must set created_by = auth.uid())
CREATE POLICY "Users can create standalone equipment"
ON public.standalone_equipment FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 6: Super Admin can update any standalone equipment
CREATE POLICY "Super admin can update all standalone equipment"
ON public.standalone_equipment FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 7: Firm Admin can update standalone equipment from their firm
CREATE POLICY "Firm admin can update firm standalone equipment"
ON public.standalone_equipment FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users u1
    WHERE u1.id = auth.uid()
    AND u1.role = 'firm_admin'
    AND u1.is_active = true
    AND EXISTS (
      SELECT 1 FROM public.users u2
      WHERE u2.id = standalone_equipment.created_by
      AND u2.firm_id = u1.firm_id
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.users u1
    WHERE u1.id = auth.uid()
    AND u1.role = 'firm_admin'
    AND u1.is_active = true
    AND EXISTS (
      SELECT 1 FROM public.users u2
      WHERE u2.id = standalone_equipment.created_by
      AND u2.firm_id = u1.firm_id
    )
  )
);

-- Policy 8: Users can update standalone equipment they created
CREATE POLICY "Users can update own standalone equipment"
ON public.standalone_equipment FOR UPDATE
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 9: Super Admin can delete any standalone equipment
CREATE POLICY "Super admin can delete standalone equipment"
ON public.standalone_equipment FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 10: Firm Admin can delete standalone equipment from their firm
CREATE POLICY "Firm admin can delete firm standalone equipment"
ON public.standalone_equipment FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users u1
    WHERE u1.id = auth.uid()
    AND u1.role = 'firm_admin'
    AND u1.is_active = true
    AND EXISTS (
      SELECT 1 FROM public.users u2
      WHERE u2.id = standalone_equipment.created_by
      AND u2.firm_id = u1.firm_id
    )
  )
);

-- Policy 11: Users can delete standalone equipment they created
CREATE POLICY "Users can delete own standalone equipment"
ON public.standalone_equipment FOR DELETE
TO authenticated
USING (created_by = auth.uid());

