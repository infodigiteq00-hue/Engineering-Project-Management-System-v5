-- ============================================================================
-- CHECK TRIGGER DETAILS: on_auth_user_created
-- ============================================================================
-- This script shows what the trigger does and which function it calls
-- ============================================================================

-- Step 1: Get full trigger details
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing,
    action_orientation
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created'
AND event_object_schema = 'auth';

-- Step 2: Find the function that this trigger calls
-- The action_statement will show the function name
-- Example: "EXECUTE FUNCTION public.handle_new_user()"

-- Step 3: Get the function definition to see what it does
SELECT 
    routine_name,
    routine_type,
    security_type,
    routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'handle_new_user',
    'on_auth_user_created',
    'create_public_user',
    'sync_user_to_public'
);

-- Step 4: Alternative - Get function definition using pg_proc
SELECT 
    p.proname AS function_name,
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND (
    p.proname LIKE '%user%'
    OR p.proname LIKE '%auth%'
    OR p.proname LIKE '%handle_new%'
    OR p.proname LIKE '%on_auth%'
);
