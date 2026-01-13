-- ============================================================================
-- EQUIPMENT_PROGRESS_IMAGES TABLE - RLS POLICIES
-- ============================================================================
-- Equipment progress images access control based on equipment's project
-- IMPORTANT: Run RLS_EQUIPMENT_TABLE.sql FIRST (equipment table RLS must exist)
-- IMPORTANT: Run RLS_PROJECT_MEMBERS_TABLE.sql FIRST to create is_assigned_to_project() function
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions

-- Step 1: Enable RLS
ALTER TABLE public.equipment_progress_images ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Firm admin can view firm equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Users can view assigned equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Super admin can create equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Firm admin can create firm equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Users can create equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Super admin can update all equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Firm admin can update firm equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Users can update equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Super admin can delete equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Firm admin can delete firm equipment progress images" ON public.equipment_progress_images;
DROP POLICY IF EXISTS "Users can delete equipment progress images" ON public.equipment_progress_images;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all equipment progress images
CREATE POLICY "Super admin can view all equipment progress images"
ON public.equipment_progress_images FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view equipment progress images in their firm's projects
CREATE POLICY "Firm admin can view firm equipment progress images"
ON public.equipment_progress_images FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_progress_images.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 3: Users can view equipment progress images for equipment in projects they're assigned to
CREATE POLICY "Users can view assigned equipment progress images"
ON public.equipment_progress_images FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_progress_images.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any equipment progress image
CREATE POLICY "Super admin can create equipment progress images"
ON public.equipment_progress_images FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Firm Admin can create equipment progress images in their firm's projects
CREATE POLICY "Firm admin can create firm equipment progress images"
ON public.equipment_progress_images FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_progress_images.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 6: Users can create equipment progress images for equipment in projects they're assigned to
CREATE POLICY "Users can create equipment progress images"
ON public.equipment_progress_images FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_progress_images.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 7: Super Admin can update any equipment progress image
CREATE POLICY "Super admin can update all equipment progress images"
ON public.equipment_progress_images FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 8: Firm Admin can update equipment progress images in their firm's projects
CREATE POLICY "Firm admin can update firm equipment progress images"
ON public.equipment_progress_images FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_progress_images.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_progress_images.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 9: Users can update equipment progress images for equipment in projects they're assigned to
CREATE POLICY "Users can update equipment progress images"
ON public.equipment_progress_images FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_progress_images.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_progress_images.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 10: Super Admin can delete any equipment progress image
CREATE POLICY "Super admin can delete equipment progress images"
ON public.equipment_progress_images FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 11: Firm Admin can delete equipment progress images in their firm's projects
CREATE POLICY "Firm admin can delete firm equipment progress images"
ON public.equipment_progress_images FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    JOIN public.projects p ON p.id = e.project_id
    WHERE e.id = equipment_progress_images.equipment_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 12: Users can delete equipment progress images for equipment in projects they're assigned to
CREATE POLICY "Users can delete equipment progress images"
ON public.equipment_progress_images FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_progress_images.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

