-- ============================================================================
-- ACTIVITY LOGS TABLES - BASIC RLS (Authenticated Users Only)
-- ============================================================================
-- These tables only need basic RLS - authenticated users can view/insert
-- No complex firm/project isolation needed as per user requirements

-- ============================================================================
-- 1. EQUIPMENT_ACTIVITY_LOGS TABLE
-- ============================================================================
ALTER TABLE public.equipment_activity_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Authenticated users can view equipment activity logs" ON public.equipment_activity_logs;
DROP POLICY IF EXISTS "Authenticated users can insert equipment activity logs" ON public.equipment_activity_logs;

-- Policy: Authenticated users can view all equipment activity logs
CREATE POLICY "Authenticated users can view equipment activity logs"
ON public.equipment_activity_logs FOR SELECT
TO authenticated
USING (true);

-- Policy: Authenticated users can insert equipment activity logs
CREATE POLICY "Authenticated users can insert equipment activity logs"
ON public.equipment_activity_logs FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================================================
-- 2. STANDALONE_EQUIPMENT_ACTIVITY_LOGS TABLE
-- ============================================================================
ALTER TABLE public.standalone_equipment_activity_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Authenticated users can view standalone equipment activity logs" ON public.standalone_equipment_activity_logs;
DROP POLICY IF EXISTS "Authenticated users can insert standalone equipment activity logs" ON public.standalone_equipment_activity_logs;

-- Policy: Authenticated users can view all standalone equipment activity logs
CREATE POLICY "Authenticated users can view standalone equipment activity logs"
ON public.standalone_equipment_activity_logs FOR SELECT
TO authenticated
USING (true);

-- Policy: Authenticated users can insert standalone equipment activity logs
CREATE POLICY "Authenticated users can insert standalone equipment activity logs"
ON public.standalone_equipment_activity_logs FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================================================
-- 3. VDCR_ACTIVITY_LOGS TABLE
-- ============================================================================
ALTER TABLE public.vdcr_activity_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Authenticated users can view vdcr activity logs" ON public.vdcr_activity_logs;
DROP POLICY IF EXISTS "Authenticated users can insert vdcr activity logs" ON public.vdcr_activity_logs;

-- Policy: Authenticated users can view all VDCR activity logs
CREATE POLICY "Authenticated users can view vdcr activity logs"
ON public.vdcr_activity_logs FOR SELECT
TO authenticated
USING (true);

-- Policy: Authenticated users can insert VDCR activity logs
CREATE POLICY "Authenticated users can insert vdcr activity logs"
ON public.vdcr_activity_logs FOR INSERT
TO authenticated
WITH CHECK (true);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- AND tablename IN ('equipment_activity_logs', 'standalone_equipment_activity_logs', 'vdcr_activity_logs');

-- Check policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd
-- FROM pg_policies
-- WHERE tablename IN ('equipment_activity_logs', 'standalone_equipment_activity_logs', 'vdcr_activity_logs')
-- ORDER BY tablename, policyname;

