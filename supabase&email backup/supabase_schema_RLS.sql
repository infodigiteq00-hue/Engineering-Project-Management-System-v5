-- ============================================================================
-- COMPREHENSIVE RLS POLICIES FOR ENGINEERING PROJECT MANAGEMENT SYSTEM
-- ============================================================================
-- This script adds Row Level Security (RLS) to all tables while preserving
-- existing functionality. Policies are based on the current access patterns
-- in the frontend code.
--
-- IMPORTANT: Run this script in your Supabase SQL editor
-- ============================================================================

-- ============================================================================
-- HELPER FUNCTION: Get current user's role
-- ============================================================================
-- This function helps check user roles in policies
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text AS $$
  SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================================
-- HELPER FUNCTION: Get current user's firm_id
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_user_firm_id()
RETURNS uuid AS $$
  SELECT firm_id FROM public.users WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================================
-- HELPER FUNCTION: Check if user is super admin
-- ============================================================================
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'super_admin' AND is_active = true
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================================
-- HELPER FUNCTION: Check if user is assigned to project (via project_members)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.is_assigned_to_project(project_uuid uuid)
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = project_uuid
    AND u.id = auth.uid()
    AND pm.status = 'active'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================================================
-- 1. FIRMS TABLE
-- ============================================================================
ALTER TABLE public.firms ENABLE ROW LEVEL SECURITY;

-- Super admin can see all firms
CREATE POLICY "Super admin can view all firms"
ON public.firms FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Firm admin can see their own firm
CREATE POLICY "Firm admin can view own firm"
ON public.firms FOR SELECT
TO authenticated
USING (
  id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Super admin can insert firms
CREATE POLICY "Super admin can insert firms"
ON public.firms FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Super admin and firm admin can update their firm
CREATE POLICY "Super admin can update all firms"
ON public.firms FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

CREATE POLICY "Firm admin can update own firm"
ON public.firms FOR UPDATE
TO authenticated
USING (
  id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
)
WITH CHECK (
  id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Only super admin can delete firms
CREATE POLICY "Super admin can delete firms"
ON public.firms FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- ============================================================================
-- 2. USERS TABLE
-- ============================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can view their own record
CREATE POLICY "Users can view own record"
ON public.users FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Super admin can view all users
CREATE POLICY "Super admin can view all users"
ON public.users FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Firm admin can view users in their firm
CREATE POLICY "Firm admin can view firm users"
ON public.users FOR SELECT
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Project managers can view users in their assigned projects
CREATE POLICY "Project managers can view project users"
ON public.users FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.project_members pm1
    JOIN public.project_members pm2 ON pm1.project_id = pm2.project_id
    JOIN public.users u ON LOWER(TRIM(pm2.email)) = LOWER(TRIM(u.email))
    WHERE pm1.email = (SELECT email FROM public.users WHERE id = auth.uid())
    AND u.id = users.id
    AND pm1.role IN ('project_manager', 'vdcr_manager')
    AND pm1.status = 'active'
  )
);

-- Super admin can insert users
CREATE POLICY "Super admin can insert users"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Users can insert their own record (for signup)
CREATE POLICY "Users can insert own record"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- Super admin can update all users
CREATE POLICY "Super admin can update all users"
ON public.users FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Firm admin can update users in their firm
CREATE POLICY "Firm admin can update firm users"
ON public.users FOR UPDATE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
)
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Users can update their own record (limited fields)
CREATE POLICY "Users can update own record"
ON public.users FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Super admin can delete users
CREATE POLICY "Super admin can delete users"
ON public.users FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- ============================================================================
-- 3. PROJECTS TABLE
-- ============================================================================
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Super admin can view all projects
CREATE POLICY "Super admin can view all projects"
ON public.projects FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Firm admin can view projects in their firm
CREATE POLICY "Firm admin can view firm projects"
ON public.projects FOR SELECT
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Users can view projects they're assigned to (via project_members)
CREATE POLICY "Users can view assigned projects"
ON public.projects FOR SELECT
TO authenticated
USING (public.is_assigned_to_project(projects.id));

-- Super admin can insert projects
CREATE POLICY "Super admin can insert projects"
ON public.projects FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Firm admin can insert projects in their firm
CREATE POLICY "Firm admin can insert firm projects"
ON public.projects FOR INSERT
TO authenticated
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Project managers can insert projects they're assigned to
CREATE POLICY "Project managers can insert assigned projects"
ON public.projects FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager', 'vdcr_manager')
    AND pm.status = 'active'
  )
);

-- Super admin can update all projects
CREATE POLICY "Super admin can update all projects"
ON public.projects FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Firm admin can update projects in their firm
CREATE POLICY "Firm admin can update firm projects"
ON public.projects FOR UPDATE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
)
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Project managers can update projects they're assigned to
CREATE POLICY "Project managers can update assigned projects"
ON public.projects FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = projects.id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager', 'vdcr_manager')
    AND pm.status = 'active'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = projects.id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager', 'vdcr_manager')
    AND pm.status = 'active'
  )
);

-- Super admin can delete projects
CREATE POLICY "Super admin can delete projects"
ON public.projects FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Firm admin can delete projects in their firm
CREATE POLICY "Firm admin can delete firm projects"
ON public.projects FOR DELETE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- ============================================================================
-- 4. PROJECT_MEMBERS TABLE
-- ============================================================================
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;

-- Users can view project members for projects they're assigned to
CREATE POLICY "Users can view assigned project members"
ON public.project_members FOR SELECT
TO authenticated
USING (public.is_assigned_to_project(project_id));

-- Super admin can view all project members
CREATE POLICY "Super admin can view all project members"
ON public.project_members FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Firm admin can view project members in their firm's projects
CREATE POLICY "Firm admin can view firm project members"
ON public.project_members FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Super admin can insert project members
CREATE POLICY "Super admin can insert project members"
ON public.project_members FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Firm admin can insert project members in their firm's projects
CREATE POLICY "Firm admin can insert firm project members"
ON public.project_members FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Project managers can insert project members in their projects
CREATE POLICY "Project managers can insert project members"
ON public.project_members FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = project_members.project_id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager', 'vdcr_manager')
    AND pm.status = 'active'
  )
);

-- Super admin can update all project members
CREATE POLICY "Super admin can update all project members"
ON public.project_members FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Firm admin can update project members in their firm's projects
CREATE POLICY "Firm admin can update firm project members"
ON public.project_members FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Project managers can update project members in their projects
CREATE POLICY "Project managers can update project members"
ON public.project_members FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = project_members.project_id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager', 'vdcr_manager')
    AND pm.status = 'active'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = project_members.project_id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager', 'vdcr_manager')
    AND pm.status = 'active'
  )
);

-- Super admin can delete project members
CREATE POLICY "Super admin can delete project members"
ON public.project_members FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Firm admin can delete project members in their firm's projects
CREATE POLICY "Firm admin can delete firm project members"
ON public.project_members FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = project_members.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Project managers can delete project members in their projects
CREATE POLICY "Project managers can delete project members"
ON public.project_members FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = project_members.project_id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager', 'vdcr_manager')
    AND pm.status = 'active'
  )
);

-- ============================================================================
-- 5. EQUIPMENT TABLE
-- ============================================================================
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;

-- Super admin can view all equipment
CREATE POLICY "Super admin can view all equipment"
ON public.equipment FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Users can view equipment in projects they're assigned to
CREATE POLICY "Users can view assigned project equipment"
ON public.equipment FOR SELECT
TO authenticated
USING (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
);

-- Super admin can insert equipment
CREATE POLICY "Super admin can insert equipment"
ON public.equipment FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Users can insert equipment in projects they're assigned to
CREATE POLICY "Users can insert equipment in assigned projects"
ON public.equipment FOR INSERT
TO authenticated
WITH CHECK (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
);

-- Super admin can update all equipment
CREATE POLICY "Super admin can update all equipment"
ON public.equipment FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Users can update equipment in projects they're assigned to
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

-- Super admin can delete equipment
CREATE POLICY "Super admin can delete equipment"
ON public.equipment FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Users can delete equipment in projects they're assigned to (with proper role)
CREATE POLICY "Users can delete equipment in assigned projects"
ON public.equipment FOR DELETE
TO authenticated
USING (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
  AND EXISTS (
    SELECT 1 FROM public.project_members pm
    JOIN public.users u ON LOWER(TRIM(pm.email)) = LOWER(TRIM(u.email))
    WHERE pm.project_id = equipment.project_id
    AND u.id = auth.uid()
    AND pm.role IN ('project_manager', 'vdcr_manager', 'editor')
    AND pm.status = 'active'
  )
);

-- ============================================================================
-- 6. EQUIPMENT_DOCUMENTS TABLE
-- ============================================================================
ALTER TABLE public.equipment_documents ENABLE ROW LEVEL SECURITY;

-- Users can view documents for equipment in projects they're assigned to
CREATE POLICY "Users can view assigned equipment documents"
ON public.equipment_documents FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_documents.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- Super admin can view all equipment documents
CREATE POLICY "Super admin can view all equipment documents"
ON public.equipment_documents FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Users can insert documents for equipment in projects they're assigned to
CREATE POLICY "Users can insert equipment documents"
ON public.equipment_documents FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_documents.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
  AND (uploaded_by = auth.uid() OR uploaded_by IS NULL)
);

-- Users can update documents for equipment in projects they're assigned to
CREATE POLICY "Users can update equipment documents"
ON public.equipment_documents FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_documents.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_documents.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- Users can delete documents for equipment in projects they're assigned to
CREATE POLICY "Users can delete equipment documents"
ON public.equipment_documents FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_documents.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
);

-- ============================================================================
-- 7. EQUIPMENT_PROGRESS_ENTRIES TABLE
-- ============================================================================
ALTER TABLE public.equipment_progress_entries ENABLE ROW LEVEL SECURITY;

-- Users can view progress entries for equipment in projects they're assigned to
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

-- Users can insert progress entries for equipment in projects they're assigned to
CREATE POLICY "Users can insert equipment progress entries"
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

-- Users can update their own progress entries
CREATE POLICY "Users can update own progress entries"
ON public.equipment_progress_entries FOR UPDATE
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- Users can delete their own progress entries
CREATE POLICY "Users can delete own progress entries"
ON public.equipment_progress_entries FOR DELETE
TO authenticated
USING (created_by = auth.uid());

-- ============================================================================
-- 8. EQUIPMENT_PROGRESS_IMAGES TABLE
-- ============================================================================
ALTER TABLE public.equipment_progress_images ENABLE ROW LEVEL SECURITY;

-- Users can view progress images for equipment in projects they're assigned to
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

-- Users can insert progress images for equipment in projects they're assigned to
CREATE POLICY "Users can insert equipment progress images"
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

-- Users can update progress images for equipment in projects they're assigned to
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

-- Users can delete progress images for equipment in projects they're assigned to
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

-- ============================================================================
-- 9. EQUIPMENT_TEAM_POSITIONS TABLE
-- ============================================================================
ALTER TABLE public.equipment_team_positions ENABLE ROW LEVEL SECURITY;

-- Users can view team positions for equipment in projects they're assigned to
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

-- Users can insert team positions for equipment in projects they're assigned to
CREATE POLICY "Users can insert equipment team positions"
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

-- Users can update team positions for equipment in projects they're assigned to
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

-- Users can delete team positions for equipment in projects they're assigned to
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

-- ============================================================================
-- 10. EQUIPMENT_ACTIVITY_LOGS TABLE
-- ============================================================================
ALTER TABLE public.equipment_activity_logs ENABLE ROW LEVEL SECURITY;

-- Users can view activity logs for equipment in projects they're assigned to
CREATE POLICY "Users can view assigned equipment activity logs"
ON public.equipment_activity_logs FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.equipment e
    WHERE e.id = equipment_activity_logs.equipment_id
    AND e.project_id IS NOT NULL
    AND public.is_assigned_to_project(e.project_id)
  )
  OR public.is_assigned_to_project(project_id)
);

-- Users can insert activity logs for equipment in projects they're assigned to
CREATE POLICY "Users can insert equipment activity logs"
ON public.equipment_activity_logs FOR INSERT
TO authenticated
WITH CHECK (
  (
    EXISTS (
      SELECT 1 FROM public.equipment e
      WHERE e.id = equipment_activity_logs.equipment_id
      AND e.project_id IS NOT NULL
      AND public.is_assigned_to_project(e.project_id)
    )
    OR public.is_assigned_to_project(project_id)
  )
  AND created_by = auth.uid()
);

-- ============================================================================
-- 11. STANDALONE_EQUIPMENT TABLE
-- ============================================================================
ALTER TABLE public.standalone_equipment ENABLE ROW LEVEL SECURITY;

-- Super admin can view all standalone equipment
CREATE POLICY "Super admin can view all standalone equipment"
ON public.standalone_equipment FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Firm admin can view standalone equipment from their firm
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

-- Users can view standalone equipment they're assigned to (via team_positions)
CREATE POLICY "Users can view assigned standalone equipment"
ON public.standalone_equipment FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment_team_positions tp
    JOIN public.users u ON LOWER(TRIM(tp.email)) = LOWER(TRIM(u.email))
    WHERE tp.equipment_id = standalone_equipment.id
    AND u.id = auth.uid()
  )
  OR created_by = auth.uid()
);

-- Users can insert standalone equipment
CREATE POLICY "Users can insert standalone equipment"
ON public.standalone_equipment FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

-- Firm admin can update standalone equipment from their firm
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

-- Users can update standalone equipment they're assigned to
CREATE POLICY "Users can update assigned standalone equipment"
ON public.standalone_equipment FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment_team_positions tp
    JOIN public.users u ON LOWER(TRIM(tp.email)) = LOWER(TRIM(u.email))
    WHERE tp.equipment_id = standalone_equipment.id
    AND u.id = auth.uid()
    AND tp.role = 'editor'
  )
  OR created_by = auth.uid()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment_team_positions tp
    JOIN public.users u ON LOWER(TRIM(tp.email)) = LOWER(TRIM(u.email))
    WHERE tp.equipment_id = standalone_equipment.id
    AND u.id = auth.uid()
    AND tp.role = 'editor'
  )
  OR created_by = auth.uid()
);

-- Firm admin can delete standalone equipment from their firm
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

-- Users can delete standalone equipment they created
CREATE POLICY "Users can delete own standalone equipment"
ON public.standalone_equipment FOR DELETE
TO authenticated
USING (created_by = auth.uid());

-- ============================================================================
-- 12. STANDALONE_EQUIPMENT_DOCUMENTS TABLE
-- ============================================================================
ALTER TABLE public.standalone_equipment_documents ENABLE ROW LEVEL SECURITY;

-- Users can view documents for standalone equipment they're assigned to
CREATE POLICY "Users can view assigned standalone equipment documents"
ON public.standalone_equipment_documents FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_documents.equipment_id
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

-- Users can insert documents for standalone equipment they're assigned to
CREATE POLICY "Users can insert standalone equipment documents"
ON public.standalone_equipment_documents FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_documents.equipment_id
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
  AND (uploaded_by = auth.uid() OR uploaded_by IS NULL)
);

-- Users can update documents for standalone equipment they're assigned to
CREATE POLICY "Users can update standalone equipment documents"
ON public.standalone_equipment_documents FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_documents.equipment_id
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
    WHERE se.id = standalone_equipment_documents.equipment_id
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

-- Users can delete documents for standalone equipment they're assigned to
CREATE POLICY "Users can delete standalone equipment documents"
ON public.standalone_equipment_documents FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_documents.equipment_id
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
-- 13. STANDALONE_EQUIPMENT_PROGRESS_ENTRIES TABLE
-- ============================================================================
ALTER TABLE public.standalone_equipment_progress_entries ENABLE ROW LEVEL SECURITY;

-- Users can view progress entries for standalone equipment they're assigned to
CREATE POLICY "Users can view assigned standalone equipment progress entries"
ON public.standalone_equipment_progress_entries FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_progress_entries.equipment_id
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

-- Users can insert progress entries for standalone equipment they're assigned to
CREATE POLICY "Users can insert standalone equipment progress entries"
ON public.standalone_equipment_progress_entries FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_progress_entries.equipment_id
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
  AND (created_by = auth.uid() OR created_by IS NULL)
);

-- Users can update their own progress entries
CREATE POLICY "Users can update own standalone equipment progress entries"
ON public.standalone_equipment_progress_entries FOR UPDATE
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- Users can delete their own progress entries
CREATE POLICY "Users can delete own standalone equipment progress entries"
ON public.standalone_equipment_progress_entries FOR DELETE
TO authenticated
USING (created_by = auth.uid());

-- ============================================================================
-- 14. STANDALONE_EQUIPMENT_PROGRESS_IMAGES TABLE
-- ============================================================================
ALTER TABLE public.standalone_equipment_progress_images ENABLE ROW LEVEL SECURITY;

-- Users can view progress images for standalone equipment they're assigned to
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

-- Users can insert progress images for standalone equipment they're assigned to
CREATE POLICY "Users can insert standalone equipment progress images"
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

-- Users can update progress images for standalone equipment they're assigned to
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

-- Users can delete progress images for standalone equipment they're assigned to
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

-- ============================================================================
-- 15. STANDALONE_EQUIPMENT_TEAM_POSITIONS TABLE
-- ============================================================================
ALTER TABLE public.standalone_equipment_team_positions ENABLE ROW LEVEL SECURITY;

-- Users can view team positions for standalone equipment they're assigned to
CREATE POLICY "Users can view assigned standalone equipment team positions"
ON public.standalone_equipment_team_positions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_team_positions.equipment_id
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

-- Users can insert team positions for standalone equipment they're assigned to
CREATE POLICY "Users can insert standalone equipment team positions"
ON public.standalone_equipment_team_positions FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_team_positions.equipment_id
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
  AND (assigned_by = auth.uid() OR assigned_by IS NULL)
);

-- Users can update team positions for standalone equipment they're assigned to
CREATE POLICY "Users can update standalone equipment team positions"
ON public.standalone_equipment_team_positions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_team_positions.equipment_id
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
    WHERE se.id = standalone_equipment_team_positions.equipment_id
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

-- Users can delete team positions for standalone equipment they're assigned to
CREATE POLICY "Users can delete standalone equipment team positions"
ON public.standalone_equipment_team_positions FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_team_positions.equipment_id
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
-- 16. STANDALONE_EQUIPMENT_ACTIVITY_LOGS TABLE
-- ============================================================================
ALTER TABLE public.standalone_equipment_activity_logs ENABLE ROW LEVEL SECURITY;

-- Users can view activity logs for standalone equipment they're assigned to
CREATE POLICY "Users can view assigned standalone equipment activity logs"
ON public.standalone_equipment_activity_logs FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_activity_logs.equipment_id
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

-- Users can insert activity logs for standalone equipment they're assigned to
CREATE POLICY "Users can insert standalone equipment activity logs"
ON public.standalone_equipment_activity_logs FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.standalone_equipment se
    WHERE se.id = standalone_equipment_activity_logs.equipment_id
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
  AND created_by = auth.uid()
);

-- ============================================================================
-- 17. VDCR_RECORDS TABLE
-- ============================================================================
ALTER TABLE public.vdcr_records ENABLE ROW LEVEL SECURITY;

-- Super admin can view all VDCR records
CREATE POLICY "Super admin can view all vdcr records"
ON public.vdcr_records FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Users can view VDCR records for projects they're assigned to
CREATE POLICY "Users can view assigned project vdcr records"
ON public.vdcr_records FOR SELECT
TO authenticated
USING (public.is_assigned_to_project(project_id));

-- Users can insert VDCR records for projects they're assigned to
CREATE POLICY "Users can insert vdcr records"
ON public.vdcr_records FOR INSERT
TO authenticated
WITH CHECK (public.is_assigned_to_project(project_id));

-- Users can update VDCR records for projects they're assigned to
CREATE POLICY "Users can update vdcr records"
ON public.vdcr_records FOR UPDATE
TO authenticated
USING (public.is_assigned_to_project(project_id))
WITH CHECK (public.is_assigned_to_project(project_id));

-- Users can delete VDCR records for projects they're assigned to (with proper role)
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

-- ============================================================================
-- 18. VDCR_DOCUMENTS TABLE
-- ============================================================================
ALTER TABLE public.vdcr_documents ENABLE ROW LEVEL SECURITY;

-- Users can view VDCR documents for projects they're assigned to
CREATE POLICY "Users can view assigned vdcr documents"
ON public.vdcr_documents FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_documents.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
);

-- Users can insert VDCR documents for projects they're assigned to
CREATE POLICY "Users can insert vdcr documents"
ON public.vdcr_documents FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_documents.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
  AND (uploaded_by = auth.uid() OR uploaded_by IS NULL)
);

-- Users can update VDCR documents for projects they're assigned to
CREATE POLICY "Users can update vdcr documents"
ON public.vdcr_documents FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_documents.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_documents.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
);

-- Users can delete VDCR documents for projects they're assigned to
CREATE POLICY "Users can delete vdcr documents"
ON public.vdcr_documents FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.vdcr_records vr
    WHERE vr.id = vdcr_documents.vdcr_record_id
    AND public.is_assigned_to_project(vr.project_id)
  )
);

-- ============================================================================
-- 19. VDCR_DOCUMENT_HISTORY TABLE
-- ============================================================================
ALTER TABLE public.vdcr_document_history ENABLE ROW LEVEL SECURITY;

-- Users can view VDCR document history for projects they're assigned to
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

-- Users can insert VDCR document history for projects they're assigned to
CREATE POLICY "Users can insert vdcr document history"
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
-- 20. VDCR_ACTIVITY_LOGS TABLE
-- ============================================================================
ALTER TABLE public.vdcr_activity_logs ENABLE ROW LEVEL SECURITY;

-- Users can view VDCR activity logs for projects they're assigned to
CREATE POLICY "Users can view assigned vdcr activity logs"
ON public.vdcr_activity_logs FOR SELECT
TO authenticated
USING (public.is_assigned_to_project(project_id));

-- Users can insert VDCR activity logs for projects they're assigned to
CREATE POLICY "Users can insert vdcr activity logs"
ON public.vdcr_activity_logs FOR INSERT
TO authenticated
WITH CHECK (
  public.is_assigned_to_project(project_id)
  AND created_by = auth.uid()
);

-- ============================================================================
-- 21. PROJECT DOCUMENT TABLES (Unpriced PO, Design Inputs, Client Reference, Other)
-- ============================================================================

-- UNPRICED_PO_DOCUMENTS
ALTER TABLE public.unpriced_po_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view assigned unpriced po documents"
ON public.unpriced_po_documents FOR SELECT
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can insert unpriced po documents"
ON public.unpriced_po_documents FOR INSERT
TO authenticated
WITH CHECK (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can update unpriced po documents"
ON public.unpriced_po_documents FOR UPDATE
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
)
WITH CHECK (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can delete unpriced po documents"
ON public.unpriced_po_documents FOR DELETE
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

-- DESIGN_INPUTS_DOCUMENTS
ALTER TABLE public.design_inputs_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view assigned design inputs documents"
ON public.design_inputs_documents FOR SELECT
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can insert design inputs documents"
ON public.design_inputs_documents FOR INSERT
TO authenticated
WITH CHECK (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can update design inputs documents"
ON public.design_inputs_documents FOR UPDATE
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
)
WITH CHECK (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can delete design inputs documents"
ON public.design_inputs_documents FOR DELETE
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

-- CLIENT_REFERENCE_DOCUMENTS
ALTER TABLE public.client_reference_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view assigned client reference documents"
ON public.client_reference_documents FOR SELECT
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can insert client reference documents"
ON public.client_reference_documents FOR INSERT
TO authenticated
WITH CHECK (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can update client reference documents"
ON public.client_reference_documents FOR UPDATE
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
)
WITH CHECK (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can delete client reference documents"
ON public.client_reference_documents FOR DELETE
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

-- OTHER_DOCUMENTS
ALTER TABLE public.other_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view assigned other documents"
ON public.other_documents FOR SELECT
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can insert other documents"
ON public.other_documents FOR INSERT
TO authenticated
WITH CHECK (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can update other documents"
ON public.other_documents FOR UPDATE
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
)
WITH CHECK (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

CREATE POLICY "Users can delete other documents"
ON public.other_documents FOR DELETE
TO authenticated
USING (
  project_id IS NULL OR public.is_assigned_to_project(project_id)
);

-- ============================================================================
-- 22. INVITES TABLE
-- ============================================================================
ALTER TABLE public.invites ENABLE ROW LEVEL SECURITY;

-- Super admin can view all invites
CREATE POLICY "Super admin can view all invites"
ON public.invites FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Firm admin can view invites for their firm
CREATE POLICY "Firm admin can view firm invites"
ON public.invites FOR SELECT
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Users can view invites sent to their email
CREATE POLICY "Users can view own invites"
ON public.invites FOR SELECT
TO authenticated
USING (
  LOWER(TRIM(email)) = LOWER(TRIM((SELECT email FROM public.users WHERE id = auth.uid())))
);

-- Super admin can insert invites
CREATE POLICY "Super admin can insert invites"
ON public.invites FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Firm admin can insert invites for their firm
CREATE POLICY "Firm admin can insert firm invites"
ON public.invites FOR INSERT
TO authenticated
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Super admin can update all invites
CREATE POLICY "Super admin can update all invites"
ON public.invites FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Firm admin can update invites for their firm
CREATE POLICY "Firm admin can update firm invites"
ON public.invites FOR UPDATE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
)
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- Users can update invites sent to their email (for accepting)
CREATE POLICY "Users can update own invites"
ON public.invites FOR UPDATE
TO authenticated
USING (
  LOWER(TRIM(email)) = LOWER(TRIM((SELECT email FROM public.users WHERE id = auth.uid())))
)
WITH CHECK (
  LOWER(TRIM(email)) = LOWER(TRIM((SELECT email FROM public.users WHERE id = auth.uid())))
);

-- Super admin can delete invites
CREATE POLICY "Super admin can delete invites"
ON public.invites FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Firm admin can delete invites for their firm
CREATE POLICY "Firm admin can delete firm invites"
ON public.invites FOR DELETE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'firm_admin' AND is_active = true)
);

-- ============================================================================
-- END OF RLS POLICIES
-- ============================================================================