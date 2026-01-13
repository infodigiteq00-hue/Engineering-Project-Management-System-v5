-- ============================================================================
-- STANDALONE_EQUIPMENT_PROGRESS_IMAGES TABLE - RLS POLICIES
-- ============================================================================
-- Standalone equipment progress images access control (via standalone_equipment -> team_positions)
-- IMPORTANT: Run RLS_STANDALONE_EQUIPMENT_TABLE.sql FIRST
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions

-- Step 1: Enable RLS
ALTER TABLE public.standalone_equipment_progress_images ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Firm admin can view firm standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Users can view assigned standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Super admin can create standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Firm admin can create firm standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Users can create standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Super admin can update all standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Firm admin can update firm standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Users can update standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Super admin can delete standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Firm admin can delete firm standalone equipment progress images" ON public.standalone_equipment_progress_images;
DROP POLICY IF EXISTS "Users can delete standalone equipment progress images" ON public.standalone_equipment_progress_images;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all standalone equipment progress images
CREATE POLICY "Super admin can view all standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view standalone equipment progress images from their firm
CREATE POLICY "Firm admin can view firm standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    JOIN public.users u1 ON u1.id = se.created_by
    JOIN public.users u2 ON u2.id = auth.uid()
    WHERE se.id = standalone_equipment_progress_images.equipment_id
    AND u2.role = 'firm_admin'
    AND u2.is_active = true
    AND u1.firm_id = u2.firm_id
  )
);

-- Policy 3: Users can view progress images for standalone equipment they're assigned to
CREATE POLICY "Users can view assigned standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_progress_images.equipment_id
    AND (
      EXISTS (
        SELECT 1 FROM public.standalone_equipment_team_positions tp
        JOIN public.users u ON LOWER(TRIM(tp.email)) = LOWER(TRIM(u.email))
        WHERE tp.equipment_id = se.id
        AND u.id = auth.uid()
      )
      OR se.created_by = auth.uid()
    )
  )
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any standalone equipment progress image
CREATE POLICY "Super admin can create standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Firm Admin can create standalone equipment progress images in their firm
CREATE POLICY "Firm admin can create firm standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    JOIN public.users u1 ON u1.id = se.created_by
    JOIN public.users u2 ON u2.id = auth.uid()
    WHERE se.id = standalone_equipment_progress_images.equipment_id
    AND u2.role = 'firm_admin'
    AND u2.is_active = true
    AND u1.firm_id = u2.firm_id
  )
);

-- Policy 6: Users can create progress images for standalone equipment they're assigned to
CREATE POLICY "Users can create standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_progress_images.equipment_id
    AND (
      EXISTS (
        SELECT 1 FROM public.standalone_equipment_team_positions tp
        JOIN public.users u ON LOWER(TRIM(tp.email)) = LOWER(TRIM(u.email))
        WHERE tp.equipment_id = se.id
        AND u.id = auth.uid()
      )
      OR se.created_by = auth.uid()
    )
  )
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 7: Super Admin can update any standalone equipment progress image
CREATE POLICY "Super admin can update all standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 8: Firm Admin can update standalone equipment progress images in their firm
CREATE POLICY "Firm admin can update firm standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    JOIN public.users u1 ON u1.id = se.created_by
    JOIN public.users u2 ON u2.id = auth.uid()
    WHERE se.id = standalone_equipment_progress_images.equipment_id
    AND u2.role = 'firm_admin'
    AND u2.is_active = true
    AND u1.firm_id = u2.firm_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    JOIN public.users u1 ON u1.id = se.created_by
    JOIN public.users u2 ON u2.id = auth.uid()
    WHERE se.id = standalone_equipment_progress_images.equipment_id
    AND u2.role = 'firm_admin'
    AND u2.is_active = true
    AND u1.firm_id = u2.firm_id
  )
);

-- Policy 9: Users can update progress images for standalone equipment they're assigned to
CREATE POLICY "Users can update standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_progress_images.equipment_id
    AND (
      EXISTS (
        SELECT 1 FROM public.standalone_equipment_team_positions tp
        JOIN public.users u ON LOWER(TRIM(tp.email)) = LOWER(TRIM(u.email))
        WHERE tp.equipment_id = se.id
        AND u.id = auth.uid()
      )
      OR se.created_by = auth.uid()
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_progress_images.equipment_id
    AND (
      EXISTS (
        SELECT 1 FROM public.standalone_equipment_team_positions tp
        JOIN public.users u ON LOWER(TRIM(tp.email)) = LOWER(TRIM(u.email))
        WHERE tp.equipment_id = se.id
        AND u.id = auth.uid()
      )
      OR se.created_by = auth.uid()
    )
  )
);

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 10: Super Admin can delete any standalone equipment progress image
CREATE POLICY "Super admin can delete standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 11: Firm Admin can delete standalone equipment progress images in their firm
CREATE POLICY "Firm admin can delete firm standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    JOIN public.users u1 ON u1.id = se.created_by
    JOIN public.users u2 ON u2.id = auth.uid()
    WHERE se.id = standalone_equipment_progress_images.equipment_id
    AND u2.role = 'firm_admin'
    AND u2.is_active = true
    AND u1.firm_id = u2.firm_id
  )
);

-- Policy 12: Users can delete progress images for standalone equipment they're assigned to
CREATE POLICY "Users can delete standalone equipment progress images"
ON public.standalone_equipment_progress_images FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_progress_images.equipment_id
    AND (
      EXISTS (
        SELECT 1 FROM public.standalone_equipment_team_positions tp
        JOIN public.users u ON LOWER(TRIM(tp.email)) = LOWER(TRIM(u.email))
        WHERE tp.equipment_id = se.id
        AND u.id = auth.uid()
      )
      OR se.created_by = auth.uid()
    )
  )
);

