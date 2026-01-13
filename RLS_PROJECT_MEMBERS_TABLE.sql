-- ============================================================================
-- PROJECT_MEMBERS TABLE - COMPLETE RLS SETUP
-- ============================================================================
-- This script adds Row Level Security (RLS) to the project_members table
-- Based on code analysis from src/lib/api.ts and access patterns

-- Step 1: Enable RLS
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all project members" ON public.project_members;
DROP POLICY IF EXISTS "Firm admin can view firm project members" ON public.project_members;
DROP POLICY IF EXISTS "Users can view assigned project members" ON public.project_members;
DROP POLICY IF EXISTS "Users can view own project memberships" ON public.project_members;
DROP POLICY IF EXISTS "Project managers can view project members" ON public.project_members;
DROP POLICY IF EXISTS "Super admin can create project members" ON public.project_members;
DROP POLICY IF EXISTS "Firm admin can create firm project members" ON public.project_members;
DROP POLICY IF EXISTS "Project managers can create project members" ON public.project_members;
DROP POLICY IF EXISTS "Super admin can update all project members" ON public.project_members;
DROP POLICY IF EXISTS "Firm admin can update firm project members" ON public.project_members;
DROP POLICY IF EXISTS "Project managers can update project members" ON public.project_members;
DROP POLICY IF EXISTS "Super admin can delete project members" ON public.project_members;
DROP POLICY IF EXISTS "Firm admin can delete firm project members" ON public.project_members;
DROP POLICY IF EXISTS "Project managers can delete project members" ON public.project_members;

-- ============================================================================
-- HELPER FUNCTION: Check if user is assigned to a project
-- ============================================================================
-- This function checks if the current user is assigned to a project via project_members table
-- Uses SECURITY DEFINER to bypass RLS when querying project_members (needed for recursive checks)
-- FIXED: Better structure to avoid recursion issues
-- NOTE: Parameter name must remain as project_id_param (cannot change without dropping function first)
CREATE OR REPLACE FUNCTION public.is_assigned_to_project(project_id_param uuid)
RETURNS boolean AS $$
BEGIN
  -- Use SECURITY DEFINER to bypass RLS when checking project_members
  -- This is necessary because this function is used in RLS policies for project_members itself
  RETURN EXISTS (
    SELECT 1 FROM public.project_members pm
    WHERE pm.project_id = project_id_param
    AND EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid()
      AND LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    )
    AND pm.status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all project members
CREATE POLICY "Super admin can view all project members"
ON public.project_members FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view project members in their firm's projects
CREATE POLICY "Firm admin can view firm project members"
ON public.project_members FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 3: Users can view project members for projects they're assigned to
-- This allows team members to see who else is on their project
CREATE POLICY "Users can view assigned project members"
ON public.project_members FOR SELECT
TO authenticated
USING (public.is_assigned_to_project(project_id));

-- Policy 4: Users can view their own project memberships
-- This allows users to see which projects they're assigned to
-- FIXED: No recursion - checks users table directly
CREATE POLICY "Users can view own project memberships"
ON public.project_members FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid()
    AND LOWER(TRIM(u.email)) = LOWER(TRIM(project_members.email))
  )
);

-- Policy 5: Project managers/VDCR managers can view all members of their projects
-- This allows project managers to see all team members even if they're not explicitly in project_members
CREATE POLICY "Project managers can view project members"
ON public.project_members FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND (
      -- User is project manager (via project_manager_id)
      p.project_manager_id = auth.uid()
      OR
      -- User is VDCR manager (via vdcr_manager_id)
      p.vdcr_manager_id = auth.uid()
    )
  )
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 6: Super Admin can create any project member
CREATE POLICY "Super admin can create project members"
ON public.project_members FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 7: Firm Admin can create project members in their firm's projects
CREATE POLICY "Firm admin can create firm project members"
ON public.project_members FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 8: Project Managers can create project members in their projects
-- This allows project managers and VDCR managers to add team members to their projects
-- FIXED: Checks projects table, users table role, and firm_id match (avoids recursion)
CREATE POLICY "Project managers can create project members"
ON public.project_members FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND (
      -- User is project manager (via project_manager_id in projects table)
      p.project_manager_id = auth.uid()
      OR
      -- User is VDCR manager (via vdcr_manager_id in projects table)
      p.vdcr_manager_id = auth.uid()
      OR
      -- User created the project (created_by in projects table)
      p.created_by = auth.uid()
      OR
      -- User has project_manager or vdcr_manager role in users table
      -- AND project belongs to user's firm (allows role-based access)
      (
        EXISTS (
          SELECT 1 FROM public.users u
          WHERE u.id = auth.uid()
          AND u.role IN ('project_manager', 'vdcr_manager')
          AND u.is_active = true
          AND (
            (u.firm_id IS NOT NULL AND u.firm_id = p.firm_id)
            OR (u.firm_id IS NULL AND p.firm_id IS NULL)
          )
        )
      )
    )
  )
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 9: Super Admin can update any project member
CREATE POLICY "Super admin can update all project members"
ON public.project_members FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 10: Firm Admin can update project members in their firm's projects
CREATE POLICY "Firm admin can update firm project members"
ON public.project_members FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 11: Project Managers can update project members in their projects
-- FIXED: No recursion - checks projects table directly instead of project_members
CREATE POLICY "Project managers can update project members"
ON public.project_members FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND (
      -- User is project manager (via project_manager_id)
      p.project_manager_id = auth.uid()
      OR
      -- User is VDCR manager (via vdcr_manager_id)
      p.vdcr_manager_id = auth.uid()
    )
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND (
      -- User is project manager (via project_manager_id)
      p.project_manager_id = auth.uid()
      OR
      -- User is VDCR manager (via vdcr_manager_id)
      p.vdcr_manager_id = auth.uid()
    )
  )
);

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 12: Super Admin can delete any project member
CREATE POLICY "Super admin can delete project members"
ON public.project_members FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 13: Firm Admin can delete project members in their firm's projects
CREATE POLICY "Firm admin can delete firm project members"
ON public.project_members FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 14: Project Managers can delete project members in their projects
-- FIXED: No recursion - checks projects table directly instead of project_members
CREATE POLICY "Project managers can delete project members"
ON public.project_members FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND (
      -- User is project manager (via project_manager_id)
      p.project_manager_id = auth.uid()
      OR
      -- User is VDCR manager (via vdcr_manager_id)
      p.vdcr_manager_id = auth.uid()
    )
  )
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- AND tablename = 'project_members';

-- Check policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd
-- FROM pg_policies
-- WHERE tablename = 'project_members'
-- ORDER BY policyname;

