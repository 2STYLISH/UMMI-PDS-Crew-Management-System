-- ==============================================================================
-- CYCLE 2 GAP CLOSURE: CONTACT RESTRICTIONS EXACT-KEY CLEANUP SCRIPT
-- Test Cases: TC-CM-067, TC-CM-069, TC-CM-071
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Execution Gate: DO NOT RUN YET - Hold until evidence review is complete
-- Exact Keys: Deletes strictly the 3 dedicated qa2contact.* user records
-- ==============================================================================

USE `ummi_crew`;

START TRANSACTION;

-- Exact-key deletion restricted exclusively to dedicated QA2CONTACT usernames
DELETE FROM tbl_users 
WHERE username IN (
    'qa2contact.doc.restricted',
    'qa2contact.admin.restricted',
    'qa2contact.superadmin.restricted'
);

-- Drop temporary stored procedure if present
DROP PROCEDURE IF EXISTS sp_setup_qa2contact_accounts;

COMMIT;

-- Post-cleanup confirmation: Count must be 0
SELECT 
    'POST-CLEANUP AUDIT: QA2CONTACT Remaining Records' AS Summary,
    COUNT(*) AS RemainingCount,
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Cleaned completely)'
         ELSE 'STOP (Records remain)'
    END AS Status
FROM tbl_users 
WHERE username IN (
    'qa2contact.doc.restricted',
    'qa2contact.admin.restricted',
    'qa2contact.superadmin.restricted'
);
