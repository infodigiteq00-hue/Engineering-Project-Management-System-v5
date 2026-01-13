-- ============================================================================
-- FIX on_auth_user_created TRIGGER FOR RLS
-- ============================================================================
-- This script fixes the trigger to work with RLS by making the function
-- SECURITY DEFINER, which allows it to bypass RLS policies
-- ============================================================================

-- Step 1: First, let's see what function the trigger calls
SELECT 
    trigger_name,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created'
AND event_object_schema = 'auth';

-- Step 2: Get the current function definition
-- (Replace 'handle_new_user' with actual function name from Step 1)
SELECT 
    routine_name,
    routine_definition,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'handle_new_user',
    'on_auth_user_created',
    'create_public_user'
);

-- Step 3: Recreate the function with SECURITY DEFINER
-- This allows the function to bypass RLS when inserting into public.users
-- 
-- IMPORTANT: Replace 'handle_new_user' with the actual function name from Step 1
-- Also adjust the INSERT statement based on your actual function definition

-- Example fix (adjust based on your actual function):
-- CREATE OR REPLACE FUNCTION public.handle_new_user()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   INSERT INTO public.users (id, email, full_name, role, is_active)
--   VALUES (
--     NEW.id,
--     NEW.email,
--     COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
--     COALESCE(NEW.raw_user_meta_data->>'role', 'viewer'),
--     true
--   )
--   ON CONFLICT (id) DO UPDATE SET
--     email = EXCLUDED.email,
--     full_name = EXCLUDED.full_name;
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql SECURITY DEFINER
-- SET search_path = public;

-- ============================================================================
-- ALTERNATIVE: If you want to keep the trigger but make it work with RLS
-- without SECURITY DEFINER, you can modify RLS Policy 7 to be more permissive
-- ============================================================================

-- Option 2: Modify RLS Policy 7 to allow trigger inserts
-- (This is less secure, so Option 1 with SECURITY DEFINER is better)

-- DROP POLICY IF EXISTS "Users can create own record" ON public.users;
-- 
-- CREATE POLICY "Users can create own record"
-- ON public.users FOR INSERT
-- TO authenticated, anon
-- WITH CHECK (
--   id = auth.uid() 
--   OR id IN (SELECT id FROM auth.users WHERE id = users.id)
-- );

-- ============================================================================
-- RECOMMENDED APPROACH:
-- ============================================================================
-- 1. Get the function name from Step 1
-- 2. Get the function definition from Step 2
-- 3. Recreate it with SECURITY DEFINER (see Step 3 example)
-- 4. This will allow the trigger to bypass RLS and work correctly
-- ============================================================================
