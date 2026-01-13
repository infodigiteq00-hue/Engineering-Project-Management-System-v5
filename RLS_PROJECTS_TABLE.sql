-- ============================================================================
-- PROJECTS TABLE - COMPLETE RLS SETUP
-- ============================================================================
-- This script adds Row Level Security (RLS) to the projects table
-- Based on code analysis from src/lib/api.ts and access patterns
-- 
-- IMPORTANT: Run RLS_PROJECT_MEMBERS_TABLE.sql FIRST to create is_assigned_to_project() function

-- Step 1: Enable RLS
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all projects" ON public.projects;
DROP POLICY IF EXISTS "Firm admin can view firm projects" ON public.projects;
DROP POLICY IF EXISTS "Users can view assigned projects" ON public.projects;
DROP POLICY IF EXISTS "Super admin can create projects" ON public.projects;
DROP POLICY IF EXISTS "Firm admin can create firm projects" ON public.projects;
DROP POLICY IF EXISTS "Project managers can create projects" ON public.projects;
DROP POLICY IF EXISTS "Super admin can update all projects" ON public.projects;
DROP POLICY IF EXISTS "Firm admin can update firm projects" ON public.projects;
DROP POLICY IF EXISTS "Project managers can update assigned projects" ON public.projects;
DROP POLICY IF EXISTS "VDCR managers can update assigned projects" ON public.projects;
DROP POLICY IF EXISTS "Super admin can delete projects" ON public.projects;
DROP POLICY IF EXISTS "Firm admin can delete firm projects" ON public.projects;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all projects
CREATE POLICY "Super admin can view all projects"
ON public.projects FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view projects in their firm
CREATE POLICY "Firm admin can view firm projects"
ON public.projects FOR SELECT
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- Policy 3: Users can view projects they're assigned to (via project_members)
-- This covers: project_manager, vdcr_manager, editor, viewer, design_engineer, quality_inspector, welder
CREATE POLICY "Users can view assigned projects"
ON public.projects FOR SELECT
TO authenticated
USING (public.is_assigned_to_project(id));

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any project
CREATE POLICY "Super admin can create projects"
ON public.projects FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Firm Admin can create projects in their firm
CREATE POLICY "Firm admin can create firm projects"
ON public.projects FOR INSERT
TO authenticated
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- Policy 6: Project Managers can create projects (they'll be assigned automatically)
-- Note: This allows project managers to create projects, but they must belong to their firm
CREATE POLICY "Project managers can create projects"
ON public.projects FOR INSERT
TO authenticated
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
    AND role IN ('project_manager', 'vdcr_manager')
    AND is_active = true
  )
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 7: Super Admin can update any project
CREATE POLICY "Super admin can update all projects"
ON public.projects FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 8: Firm Admin can update projects in their firm
CREATE POLICY "Firm admin can update firm projects"
ON public.projects FOR UPDATE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
)
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- Policy 9: Project Managers can update projects they're assigned to
CREATE POLICY "Project managers can update assigned projects"
ON public.projects FOR UPDATE
TO authenticated
USING (
  public.is_assigned_to_project(id)
  AND EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = projects.id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager')
    AND pm.status = 'active'
  )
)
WITH CHECK (
  public.is_assigned_to_project(id)
  AND EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = projects.id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager')
    AND pm.status = 'active'
  )
);

-- Policy 10: VDCR Managers can update projects they're assigned to (limited fields)
-- Note: VDCR managers typically only update VDCR-related fields, but we allow full update for flexibility
CREATE POLICY "VDCR managers can update assigned projects"
ON public.projects FOR UPDATE
TO authenticated
USING (
  public.is_assigned_to_project(id)
  AND EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = projects.id
    AND u.id = auth.uid()
    AND pm.role IN ('vdcr_manager')
    AND pm.status = 'active'
  )
)
WITH CHECK (
  public.is_assigned_to_project(id)
  AND EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = projects.id
    AND u.id = auth.uid()
    AND pm.role IN ('vdcr_manager')
    AND pm.status = 'active'
  )
);

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 11: Super Admin can delete any project
CREATE POLICY "Super admin can delete projects"
ON public.projects FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 12: Firm Admin can delete projects in their firm
CREATE POLICY "Firm admin can delete firm projects"
ON public.projects FOR DELETE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- AND tablename = 'projects';

-- Check policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd
-- FROM pg_policies
-- WHERE tablename = 'projects'
-- ORDER BY policyname;

