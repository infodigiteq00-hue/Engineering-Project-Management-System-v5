-- ============================================================================
-- OTHER_DOCUMENTS TABLE - RLS POLICIES
-- ============================================================================
-- Other documents access control based on project assignment
-- IMPORTANT: Run RLS_PROJECTS_TABLE.sql FIRST
-- IMPORTANT: Run RLS_PROJECT_MEMBERS_TABLE.sql FIRST to create is_assigned_to_project() function
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions

-- Step 1: Enable RLS
ALTER TABLE public.other_documents ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Firm admin can view firm other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Users can view assigned other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Super admin can create other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Firm admin can create firm other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Users can create other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Super admin can update all other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Firm admin can update firm other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Users can update other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Super admin can delete other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Firm admin can delete firm other documents" ON public.other_documents;
DROP POLICY IF EXISTS "Users can delete other documents" ON public.other_documents;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all other documents
CREATE POLICY "Super admin can view all other documents"
ON public.other_documents FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view other documents in their firm's projects
CREATE POLICY "Firm admin can view firm other documents"
ON public.other_documents FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = other_documents.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 3: Users can view other documents for projects they're assigned to
CREATE POLICY "Users can view assigned other documents"
ON public.other_documents FOR SELECT
TO authenticated
USING (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 4: Super Admin can create any other document
CREATE POLICY "Super admin can create other documents"
ON public.other_documents FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 5: Firm Admin can create other documents in their firm's projects
CREATE POLICY "Firm admin can create firm other documents"
ON public.other_documents FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = other_documents.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
  AND (uploaded_by = auth.uid() OR uploaded_by IS NULL)
);

-- Policy 6: Users can create other documents for projects they're assigned to
CREATE POLICY "Users can create other documents"
ON public.other_documents FOR INSERT
TO authenticated
WITH CHECK (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
  AND (uploaded_by = auth.uid() OR uploaded_by IS NULL)
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 7: Super Admin can update any other document
CREATE POLICY "Super admin can update all other documents"
ON public.other_documents FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 8: Firm Admin can update other documents in their firm's projects
CREATE POLICY "Firm admin can update firm other documents"
ON public.other_documents FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = other_documents.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = other_documents.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 9: Users can update other documents for projects they're assigned to
CREATE POLICY "Users can update other documents"
ON public.other_documents FOR UPDATE
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

-- Policy 10: Super Admin can delete any other document
CREATE POLICY "Super admin can delete other documents"
ON public.other_documents FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 11: Firm Admin can delete other documents in their firm's projects
CREATE POLICY "Firm admin can delete firm other documents"
ON public.other_documents FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = other_documents.project_id
    AND p.firm_id = public.get_user_firm_id()
  )
  AND public.is_firm_admin()
);

-- Policy 12: Users can delete other documents for projects they're assigned to
CREATE POLICY "Users can delete other documents"
ON public.other_documents FOR DELETE
TO authenticated
USING (
  project_id IS NOT NULL
  AND public.is_assigned_to_project(project_id)
);

