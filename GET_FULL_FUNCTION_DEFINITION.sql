-- ============================================================================
-- GET FULL FUNCTION DEFINITION: handle_new_user
-- ============================================================================
-- This script gets the complete function definition to see what it's doing
-- ============================================================================

-- Method 1: Get from information_schema (might be truncated)
SELECT 
    routine_name,
    routine_definition,
    security_type,
    routine_body
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'handle_new_user';

-- Method 2: Get complete definition using pg_get_functiondef (BETTER)
SELECT 
    p.proname AS function_name,
    pg_get_functiondef(p.oid) AS complete_function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'handle_new_user';

-- Method 3: Check if function is trying to query invites table (which might have RLS)
-- This will help us understand if the function is failing due to RLS on invites table
SELECT 
    p.proname,
    pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'handle_new_user'
AND pg_get_functiondef(p.oid) LIKE '%invite%';
