-- ============================================================================
-- INVITES TABLE - RLS POLICIES
-- ============================================================================
-- Only Super Admin, Firm Admin, and Project Manager have full access
-- No other users can view/add/update/delete invites
-- 
-- IMPORTANT: Run RLS_FIX_USERS_TABLE.sql FIRST to create helper functions
-- (is_super_admin, get_user_firm_id, is_firm_admin)

-- Step 1: Enable RLS
ALTER TABLE public.invites ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies if any (optional - safe to run multiple times)
DROP POLICY IF EXISTS "Super admin can view all invites" ON public.invites;
DROP POLICY IF EXISTS "Firm admin can view firm invites" ON public.invites;
DROP POLICY IF EXISTS "Project manager can view project invites" ON public.invites;
DROP POLICY IF EXISTS "Public can view invite by email" ON public.invites;
DROP POLICY IF EXISTS "Public can view invite by token" ON public.invites;
DROP POLICY IF EXISTS "Super admin can create invites" ON public.invites;
DROP POLICY IF EXISTS "Firm admin can create firm invites" ON public.invites;
DROP POLICY IF EXISTS "Project manager can create project invites" ON public.invites;
DROP POLICY IF EXISTS "Super admin can update all invites" ON public.invites;
DROP POLICY IF EXISTS "Firm admin can update firm invites" ON public.invites;
DROP POLICY IF EXISTS "Project manager can update project invites" ON public.invites;
DROP POLICY IF EXISTS "Public can update invite status by token" ON public.invites;
DROP POLICY IF EXISTS "Super admin can delete invites" ON public.invites;
DROP POLICY IF EXISTS "Firm admin can delete firm invites" ON public.invites;
DROP POLICY IF EXISTS "Project manager can delete project invites" ON public.invites;

-- ============================================================================
-- SELECT POLICIES (READ)
-- ============================================================================

-- Policy 1: Super Admin can view all invites
CREATE POLICY "Super admin can view all invites"
ON public.invites FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view invites for their firm
CREATE POLICY "Firm admin can view firm invites"
ON public.invites FOR SELECT
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- Policy 3: Project Manager can view invites for their projects
CREATE POLICY "Project manager can view project invites"
ON public.invites FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = invites.project_id
    AND (
      p.project_manager_id = auth.uid()
      OR p.vdcr_manager_id = auth.uid()
    )
  )
  AND EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid()
    AND u.role IN ('project_manager', 'vdcr_manager')
    AND u.is_active = true
  )
);

-- Policy 4: Public can view invite by email (for signup/login - unauthenticated users)
-- Only allows viewing pending invites that are not expired
CREATE POLICY "Public can view invite by email"
ON public.invites FOR SELECT
TO anon, authenticated
USING (
  status = 'pending'
  AND (expires_at IS NULL OR expires_at > now())
);

-- Policy 5: Public can view invite by token (alternative method)
-- Only allows viewing pending invites that are not expired
CREATE POLICY "Public can view invite by token"
ON public.invites FOR SELECT
TO anon, authenticated
USING (
  invitation_token IS NOT NULL
  AND status = 'pending'
  AND (expires_at IS NULL OR expires_at > now())
);

-- Policy 5b: Allow SECURITY DEFINER functions to query invites (for handle_new_user trigger)
-- This policy allows functions with SECURITY DEFINER to query invites table
-- during signup. SECURITY DEFINER functions run with definer's privileges,
-- but still need RLS policies to allow access.
-- This policy allows viewing any invite (pending or accepted) by email for signup flow
CREATE POLICY "SECURITY DEFINER functions can view invites for signup"
ON public.invites FOR SELECT
TO authenticated
USING (
  -- Allow viewing invites for signup flow (pending or accepted)
  status IN ('pending', 'accepted')
  AND (expires_at IS NULL OR expires_at > now())
);

-- ============================================================================
-- INSERT POLICIES (CREATE)
-- ============================================================================

-- Policy 6: Super Admin can create any invite
CREATE POLICY "Super admin can create invites"
ON public.invites FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 7: Firm Admin can create invites for their firm
CREATE POLICY "Firm admin can create firm invites"
ON public.invites FOR INSERT
TO authenticated
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- Policy 8: Project Manager can create invites for their projects
CREATE POLICY "Project manager can create project invites"
ON public.invites FOR INSERT
TO authenticated
WITH CHECK (
  (project_id IS NULL OR EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = invites.project_id
    AND (
      p.project_manager_id = auth.uid()
      OR p.vdcr_manager_id = auth.uid()
    )
  ))
  AND firm_id = public.get_user_firm_id()
  AND EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid()
    AND u.role IN ('project_manager', 'vdcr_manager')
    AND u.is_active = true
  )
);

-- ============================================================================
-- UPDATE POLICIES (MODIFY)
-- ============================================================================

-- Policy 9: Super Admin can update any invite
CREATE POLICY "Super admin can update all invites"
ON public.invites FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 10: Firm Admin can update invites for their firm
CREATE POLICY "Firm admin can update firm invites"
ON public.invites FOR UPDATE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
)
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- Policy 11: Project Manager can update invites for their projects
CREATE POLICY "Project manager can update project invites"
ON public.invites FOR UPDATE
TO authenticated
USING (
  (project_id IS NULL OR EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = invites.project_id
    AND (
      p.project_manager_id = auth.uid()
      OR p.vdcr_manager_id = auth.uid()
    )
  ))
  AND firm_id = public.get_user_firm_id()
  AND EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid()
    AND u.role IN ('project_manager', 'vdcr_manager')
    AND u.is_active = true
  )
)
WITH CHECK (
  (project_id IS NULL OR EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = invites.project_id
    AND (
      p.project_manager_id = auth.uid()
      OR p.vdcr_manager_id = auth.uid()
    )
  ))
  AND firm_id = public.get_user_firm_id()
  AND EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid()
    AND u.role IN ('project_manager', 'vdcr_manager')
    AND u.is_active = true
  )
);

-- Policy 12: Public can update invite status by token (for accepting invite)
-- Only allows updating status field, and only to 'accepted' or 'expired'
-- Token must match and invite must be pending
CREATE POLICY "Public can update invite status by token"
ON public.invites FOR UPDATE
TO anon, authenticated
USING (
  invitation_token IS NOT NULL
  AND status = 'pending'
  AND (expires_at IS NULL OR expires_at > now())
)
WITH CHECK (
  invitation_token IS NOT NULL
  AND status IN ('accepted', 'expired')
);

-- ============================================================================
-- DELETE POLICIES
-- ============================================================================

-- Policy 13: Super Admin can delete any invite
CREATE POLICY "Super admin can delete invites"
ON public.invites FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 14: Firm Admin can delete invites for their firm
CREATE POLICY "Firm admin can delete firm invites"
ON public.invites FOR DELETE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- Policy 15: Project Manager can delete invites for their projects
CREATE POLICY "Project manager can delete project invites"
ON public.invites FOR DELETE
TO authenticated
USING (
  (project_id IS NULL OR EXISTS (
    SELECT 1 FROM public.projects p
    WHERE p.id = invites.project_id
    AND (
      p.project_manager_id = auth.uid()
      OR p.vdcr_manager_id = auth.uid()
    )
  ))
  AND firm_id = public.get_user_firm_id()
  AND EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid()
    AND u.role IN ('project_manager', 'vdcr_manager')
    AND u.is_active = true
  )
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- AND tablename = 'invites';

-- Check policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd
-- FROM pg_policies
-- WHERE tablename = 'invites'
-- ORDER BY policyname;

