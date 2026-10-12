-- ==============================================================================
-- CYCLE 2 GAP CLOSURE: ATOMIC CLEANUP SCRIPT FOR ISOLATED QA CONTROL ACCOUNTS
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Isolation Scope: Deletes strictly the 3 dedicated qa.*.control user records:
--   - qa.manning.control
--   - qa.doc.control
--   - qa.admin.control
-- Preservation Guarantee:
--   - Leaves all audit evidence (tbl_activity_logs) untouched
--   - Leaves all pre-existing demo accounts and unrelated QA fixtures untouched
-- ==============================================================================

USE `ummi_crew`;

-- ------------------------------------------------------------------------------
-- 1. PRE-CLEANUP AUDIT INSPECTION
-- ------------------------------------------------------------------------------
SELECT 'PRE-CLEANUP AUDIT: QA Control Accounts to Delete' AS AuditAction,
       id, username, fullname, type, management, created_at
FROM tbl_users
WHERE username IN (
    'qa.manning.control',
    'qa.doc.control',
    'qa.admin.control'
);

-- ------------------------------------------------------------------------------
-- 2. SCOPED DELETION OF DEPENDENT ASSIGNMENTS (IF CREATED)
-- ------------------------------------------------------------------------------
DELETE FROM tbl_user_assigned_vessel
WHERE user_id IN (
    SELECT id FROM (
        SELECT id FROM tbl_users 
        WHERE username IN ('qa.manning.control', 'qa.doc.control', 'qa.admin.control')
    ) AS tmp_u
);

-- ------------------------------------------------------------------------------
-- 3. SCOPED DELETION OF USER ACCOUNTS
-- ------------------------------------------------------------------------------
DELETE FROM tbl_users 
WHERE username IN (
    'qa.manning.control',
    'qa.doc.control',
    'qa.admin.control'
);

-- ------------------------------------------------------------------------------
-- 4. CLEANUP DEDICATED STORED PROCEDURE
-- ------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_setup_qa_control_accounts;

-- ------------------------------------------------------------------------------
-- 5. POST-CLEANUP VERIFICATION
-- ------------------------------------------------------------------------------
SELECT 'POST-CLEANUP AUDIT: Remaining Control Accounts (Must be 0)' AS Summary,
       COUNT(*) AS RemainingCount
FROM tbl_users
WHERE username IN (
    'qa.manning.control',
    'qa.doc.control',
    'qa.admin.control'
);
