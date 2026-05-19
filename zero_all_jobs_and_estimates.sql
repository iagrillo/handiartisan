-- =============================================
-- ZERO ALL JOBS, ESTIMATES, AND PENDING QUOTES (PRODUCTION SAFE)
-- Run as service_role or with admin privileges in Supabase SQL Editor
-- =============================================

-- 1. Reset all jobs to initial state
UPDATE jobs
SET status = 'pending',
    estimate_status = 'pending',
    amount_paid = 0,
    payment_reference = NULL,
    updated_at = NOW()
WHERE TRUE;

-- 2. Reset all estimates (if you have a separate estimates table)
-- Uncomment and adjust the table/column names if needed
-- UPDATE estimates
-- SET status = 'pending',
--     total = 0,
--     materials_cost = 0,
--     labor_cost = 0,
--     updated_at = NOW()
-- WHERE TRUE;

-- 3. Reset all pending quotes (if you have a quotes table)
-- Uncomment and adjust the table/column names if needed
-- UPDATE quotes
-- SET status = 'pending',
--     amount = 0,
--     updated_at = NOW()
-- WHERE TRUE;

-- 4. Verify jobs reset (show 10 most recent jobs)
SELECT id, status, estimate_status, amount_paid, payment_reference, updated_at
FROM jobs
ORDER BY updated_at DESC NULLS LAST
LIMIT 10;

-- 5. Health check (count jobs with non-pending status)
SELECT 
  SUM(CASE WHEN status != 'pending' THEN 1 ELSE 0 END) AS jobs_not_pending,
  SUM(CASE WHEN estimate_status != 'pending' THEN 1 ELSE 0 END) AS jobs_estimate_not_pending
FROM jobs;

-- If all counts above are zero, all jobs are reset to pending.
