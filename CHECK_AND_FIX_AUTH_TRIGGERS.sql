-- ============================================================================
-- CHECK AND FIX AUTH.USERS TRIGGERS
-- ============================================================================
-- This script checks for triggers on auth.users that might be causing
-- "Database error saving new user" during signup
-- ============================================================================

-- Step 1: Check existing triggers on auth.users
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE event_object_schema = 'auth'
AND event_object_table = 'users';

-- Step 2: Check for functions that might be called by triggers
SELECT 
    routine_name,
    routine_type,
    security_type,
    routine_definition
FROM information_schema.routines
WHERE routine_schema = 'auth'
AND routine_name LIKE '%user%'
ORDER BY routine_name;

-- Step 3: If there's a trigger that creates users in public.users, we need to:
-- Option A: Make the trigger function SECURITY DEFINER
-- Option B: Disable the trigger temporarily
-- Option C: Fix the trigger to handle RLS properly

-- Example: If you find a trigger like "on_auth_user_created", you can:
-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Or if you want to keep the trigger but fix it:
-- CREATE OR REPLACE FUNCTION public.handle_new_user()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   INSERT INTO public.users (id, email, full_name, role, is_active)
--   VALUES (
--     NEW.id,
--     NEW.email,
--     NEW.raw_user_meta_data->>'full_name',
--     'viewer',
--     true
--   )
--   ON CONFLICT (id) DO NOTHING;
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql SECURITY DEFINER;

-- CREATE TRIGGER on_auth_user_created
--   AFTER INSERT ON auth.users
--   FOR EACH ROW
--   EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- IMPORTANT NOTES:
-- ============================================================================
-- 1. If you have a trigger, it MUST use SECURITY DEFINER to bypass RLS
-- 2. The trigger function should handle conflicts gracefully (ON CONFLICT)
-- 3. If you don't need automatic user creation, disable the trigger
-- 4. Our SignUp.tsx already handles user creation manually, so a trigger
--    might be redundant and causing conflicts
-- ============================================================================
