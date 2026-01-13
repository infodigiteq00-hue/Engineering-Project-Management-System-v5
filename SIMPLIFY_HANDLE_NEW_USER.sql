-- ============================================================================
-- SIMPLIFY handle_new_user FUNCTION (Remove invites table query)
-- ============================================================================
-- This simplifies the function to NOT query invites table during signup
-- because SignUp.tsx already handles invites manually
-- ============================================================================

-- Drop and recreate function WITHOUT invites table query
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert into public.users with basic info only
  -- SignUp.tsx will handle invite-based role assignment later
  INSERT INTO public.users (
    id,
    email,
    full_name,
    role,
    is_active
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    'viewer',  -- Default role, SignUp.tsx will update with invite role
    true
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- ============================================================================
-- WHY THIS WORKS:
-- ============================================================================
-- 1. Function no longer queries invites table (no RLS conflict)
-- 2. Function creates basic user record with default 'viewer' role
-- 3. SignUp.tsx already handles invite checking and role assignment
-- 4. SignUp.tsx will update the user record with correct role/firm_id
-- ============================================================================
