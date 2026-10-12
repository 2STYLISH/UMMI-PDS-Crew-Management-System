-- ==============================================================================
-- CYCLE 2 GAP CLOSURE: CONTACT RESTRICTIONS CLEANUP INSPECTION AUDIT
-- Test Cases: TC-CM-067, TC-CM-069, TC-CM-071
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Execution Mode: READ-ONLY (Exact-key inspection prior to cleanup)
-- ==============================================================================

USE `ummi_crew`;

SELECT 
    'SCHEDULED FOR DELETION: QA2CONTACT Dedicated Accounts' AS AuditAction,
    u.id AS UserID,
    u.username AS Username,
    u.fullname AS DisplayName,
    u.type AS RoleCode,
    u.viewcrewcontactdetails AS ContactPermission,
    u.email_address AS EmailAddress
FROM tbl_users u
WHERE u.username IN (
    'qa2contact.doc.restricted',
    'qa2contact.admin.restricted',
    'qa2contact.superadmin.restricted'
)
ORDER BY u.id;

-- Safety check: Confirm ZERO shared accounts match the deletion filter
SELECT 
    'SAFETY AUDIT: Protected Accounts' AS Section,
    COUNT(*) AS ProtectedAccountsMatchingFilter,
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Safe to proceed with exact-key cleanup)'
         ELSE 'STOP (Shared account collision detected!)'
    END AS SafetyStatus
FROM tbl_users
WHERE username IN ('demo.doc', 'demo.admin', 'demo.superadmin', 'qa.c2.20261001.manning.restricted')
  AND username IN (
    'qa2contact.doc.restricted',
    'qa2contact.admin.restricted',
    'qa2contact.superadmin.restricted'
  );
