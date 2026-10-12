-- ==============================================================================
-- CYCLE 2 GAP CLOSURE: CONTACT RESTRICTIONS POST-SETUP VERIFICATION
-- Test Cases: TC-CM-067, TC-CM-069, TC-CM-071
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Execution Mode: READ-ONLY (Sanitized Verification - Zero Credential Exposure)
-- ==============================================================================

USE `ummi_crew`;

SELECT 
    u.id AS UserID,
    u.username AS Username,
    u.fullname AS DisplayName,
    u.type AS RoleCode,
    ut.user_type AS UserTypeLookup,
    u.viewcrewcontactdetails AS ContactPermission,
    u.ccl_permission AS CCLPermission,
    u.disable_user AS IsDisabled,
    CASE 
        WHEN u.password LIKE '$pbkdf2:100000$%' 
         AND u.password_salt IS NOT NULL 
         AND LENGTH(u.password_salt) >= 32 THEN 'CONFIRMED: PBKDF2-HMAC-SHA256 (100k rounds, 256-bit salt)'
        ELSE 'INVALID: Missing or non-standard hash'
    END AS CredentialFormatStatus,
    CASE 
        WHEN u.username = 'qa2contact.doc.restricted' 
         AND u.type = 'DOCUMENTATION_OFFICER' 
         AND u.viewcrewcontactdetails = 0 THEN 'PASS (TC-CM-067 Verified Ready)'
        WHEN u.username = 'qa2contact.admin.restricted' 
         AND u.type = 'ADMIN' 
         AND u.viewcrewcontactdetails = 0 THEN 'PASS (TC-CM-069 Verified Ready)'
        WHEN u.username = 'qa2contact.superadmin.restricted' 
         AND u.type = 'SUPER_ADMIN' 
         AND u.viewcrewcontactdetails = 0 THEN 'PASS (TC-CM-071 Verified Ready)'
        ELSE 'FAIL (Requirement mismatch)'
    END AS FixtureReadiness
FROM tbl_users u
LEFT JOIN tbl_user_type ut ON ut.user_type = u.type
WHERE u.username IN (
    'qa2contact.doc.restricted',
    'qa2contact.admin.restricted',
    'qa2contact.superadmin.restricted'
)
ORDER BY u.id;
