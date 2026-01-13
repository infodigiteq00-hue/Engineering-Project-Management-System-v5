-- ============================================================================
-- REMOVE AUTH.USERS TRIGGERS THAT AUTO-CREATE PUBLIC.USERS ENTRIES
-- ============================================================================
-- This script removes any triggers on auth.users that automatically create
-- entries in public.users table, as our SignUp.tsx already handles this manually
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

-- Step 2: Drop common trigger names that might auto-create users
-- (Adjust trigger names based on what you find in Step 1)

-- Common trigger names to check and remove:
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP TRIGGER IF EXISTS create_public_user ON auth.users;
DROP TRIGGER IF EXISTS sync_user_to_public ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_insert ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_user_profile ON auth.users;

-- Step 3: Drop associated functions (if they exist and are no longer needed)
-- Only drop if they're ONLY used by the removed triggers
-- Be careful - check dependencies first!

-- Check for functions that might be used by triggers:
SELECT 
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND (
    routine_name LIKE '%user%' 
    OR routine_name LIKE '%auth%'
    OR routine_name LIKE '%handle_new%'
    OR routine_name LIKE '%on_auth%'
)
ORDER BY routine_name;

-- Common function names to check (ONLY drop if confirmed they're not used elsewhere):
-- DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
-- DROP FUNCTION IF EXISTS public.on_auth_user_created() CASCADE;
-- DROP FUNCTION IF EXISTS public.create_public_user() CASCADE;
-- DROP FUNCTION IF EXISTS public.sync_user_to_public() CASCADE;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- After running this script, verify no triggers remain:
SELECT 
    trigger_name,
    event_object_table
FROM information_schema.triggers
WHERE event_object_schema = 'auth'
AND event_object_table = 'users';

-- If the query returns no rows, all triggers have been removed successfully.
-- ============================================================================
