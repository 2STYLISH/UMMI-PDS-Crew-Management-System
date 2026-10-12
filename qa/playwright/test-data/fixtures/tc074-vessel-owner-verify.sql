-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-074 VERIFICATION SCRIPT
-- Test Case: TC-CM-074 (Vessel Owner Authorized Contact & Profile Access)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Classification: Strictly Read-Only Audit & Verification
-- Schema Verified: tbl_vessels (principal, management, owner; no principal_id)
-- ==============================================================================

USE `ummi_crew`;

SELECT 
    'TC-CM-074 Vessel Owner Audit' AS Scope,
    u.id AS UserID,
    u.username AS Username,
    u.type AS StoredRoleValue,
    ut.id AS ConfirmedRoleID,
    ut.user_type AS ResolvedRoleName,
    u.fullname AS FullName,
    u.email_address AS Email,
    u.management AS UserManagementTenant,
    u.viewcrewcontactdetails AS StoredContactPermission,
    CASE WHEN u.viewcrewcontactdetails = 1 THEN 'PASS (Contact Access Enabled)'
         ELSE 'FAIL (Contact Access Restricted)'
    END AS ContactAccessAudit,
    LENGTH(u.password) AS StoredHashLength,
    LEFT(u.password, 15) AS StoredHashPrefix,
    LENGTH(u.password_salt) AS StoredSaltLength,
    CASE 
        WHEN u.password LIKE '$pbkdf2:100000$%' 
         AND LENGTH(u.password) = 59 
         AND LENGTH(u.password_salt) = 44 
         AND SUBSTRING(u.password, 16) REGEXP '^[A-Za-z0-9+/]{43}=$'
         AND u.password_salt REGEXP '^[A-Za-z0-9+/]{43}=$' 
        THEN 'PASS (CryptoHelper PBKDF2 v3 Compliant: 100k iters, 256-bit key & salt)'
        ELSE 'FAIL (Non-compliant credential format)'
    END AS CredentialFormatAudit,
    v.id AS AssignedVesselID,
    v.vesselName AS AssignedVesselName,
    v.principal AS VesselPrincipalRef,
    p.name AS PrincipalName,
    v.management AS VesselManagementRef,
    uav.principal_id AS AssignedPrincipalID,
    uav.management_id AS AssignedManagementID,
    uav.owner_id AS AssignedOwnerID,
    uav.status AS AssignmentStatus
FROM tbl_users u
LEFT JOIN tbl_user_type ut ON ut.user_type = u.type OR ut.id = u.type
JOIN tbl_user_assigned_vessel uav ON uav.user_id = u.id
JOIN tbl_vessels v ON uav.vessel_id = v.id
LEFT JOIN tbl_principals p ON v.principal = p.id
LEFT JOIN tbl_management m ON v.management = m.id
WHERE u.username = 'qa2contact.owner.authorized';
