-- ============================================================================
-- USERS TABLE - FIXED RLS POLICIES (No Infinite Recursion)
-- ============================================================================
-- Issue: Helper functions querying users table cause infinite recursion
-- Solution: Use SECURITY DEFINER with proper settings to bypass RLS

-- Step 1: Drop existing USER policies only (keep functions - they're used by firms table)
DROP POLICY IF EXISTS "Super admin can view all users" ON public.users;
DROP POLICY IF EXISTS "Firm admin can view firm users" ON public.users;
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
DROP POLICY IF EXISTS "Project members can view assigned project users" ON public.users;
DROP POLICY IF EXISTS "Users can view same firm users" ON public.users;
DROP POLICY IF EXISTS "Super admin can create users" ON public.users;
DROP POLICY IF EXISTS "Firm admin can create firm users" ON public.users;
DROP POLICY IF EXISTS "Users can create own record" ON public.users;
DROP POLICY IF EXISTS "Super admin can update all users" ON public.users;
DROP POLICY IF EXISTS "Firm admin can update firm users" ON public.users;
DROP POLICY IF EXISTS "Users can update own data" ON public.users;
DROP POLICY IF EXISTS "Super admin can delete users" ON public.users;
DROP POLICY IF EXISTS "Firm admin can delete firm users" ON public.users;

-- Step 2: Update Helper Functions with SECURITY DEFINER (bypasses RLS)
-- Note: Using CREATE OR REPLACE (NOT DROP) because firms table policies depend on these functions
-- This will update the functions to use plpgsql with SECURITY DEFINER to prevent infinite recursion
-- These functions will bypass RLS when querying users table

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean AS $$
BEGIN
  -- Use SECURITY DEFINER to bypass RLS
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
    AND role = 'super_admin'
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_user_firm_id()
RETURNS uuid AS $$
DECLARE
  result uuid;
BEGIN
  -- Use SECURITY DEFINER to bypass RLS
  SELECT firm_id INTO result
  FROM public.users
  WHERE id = auth.uid()
  AND is_active = true
  LIMIT 1;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_firm_admin()
RETURNS boolean AS $$
BEGIN
  -- Use SECURITY DEFINER to bypass RLS
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
    AND role = 'firm_admin'
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

-- Step 3: Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 4: Create SELECT Policies (READ)
-- Policy 1: Super Admin can view all users
CREATE POLICY "Super admin can view all users"
ON public.users FOR SELECT
TO authenticated
USING (public.is_super_admin());

-- Policy 2: Firm Admin can view users in their firm
CREATE POLICY "Firm admin can view firm users"
ON public.users FOR SELECT
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- Policy 3: Users can view their own data
CREATE POLICY "Users can view own data"
ON public.users FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Policy 4: Users in same firm can view each other (for team visibility)
-- This is simpler and avoids complex project_members join
CREATE POLICY "Users can view same firm users"
ON public.users FOR SELECT
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND firm_id IS NOT NULL
);

-- Step 5: Create INSERT Policies (CREATE)
-- Policy 5: Super Admin can create any user
CREATE POLICY "Super admin can create users"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (public.is_super_admin());

-- Policy 6: Firm Admin can create users in their firm
CREATE POLICY "Firm admin can create firm users"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- Policy 7: Users can create their own record (for signup/login)
-- This allows users to create their own record with id = auth.uid()
-- This is needed when users sign up via invite or first-time login
CREATE POLICY "Users can create own record"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- Step 6: Create UPDATE Policies (MODIFY)
-- Policy 8: Super Admin can update any user
CREATE POLICY "Super admin can update all users"
ON public.users FOR UPDATE
TO authenticated
USING (public.is_super_admin())
WITH CHECK (public.is_super_admin());

-- Policy 9: Firm Admin can update users in their firm
CREATE POLICY "Firm admin can update firm users"
ON public.users FOR UPDATE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
)
WITH CHECK (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
);

-- Policy 10: Users can update their own data (limited - no role/firm_id change)
-- Note: We can't query users table in WITH CHECK, so we allow updates but restrict in application layer
CREATE POLICY "Users can update own data"
ON public.users FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Step 7: Create DELETE Policies
-- Policy 11: Super Admin can delete any user
CREATE POLICY "Super admin can delete users"
ON public.users FOR DELETE
TO authenticated
USING (public.is_super_admin());

-- Policy 12: Firm Admin can delete users in their firm (except themselves)
CREATE POLICY "Firm admin can delete firm users"
ON public.users FOR DELETE
TO authenticated
USING (
  firm_id = public.get_user_firm_id()
  AND public.is_firm_admin()
  AND id != auth.uid()
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- AND tablename = 'users';

-- Check policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd
-- FROM pg_policies
-- WHERE tablename = 'users'
-- ORDER BY policyname;

