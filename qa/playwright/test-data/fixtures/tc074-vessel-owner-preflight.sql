-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-074 PREFLIGHT SCRIPT
-- Test Case: TC-CM-074 (Vessel Owner Authorized Contact & Profile Access)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Classification: Strictly Read-Only Preflight Verification
-- Schema Verified: tbl_vessels (principal, management, owner; no principal_id)
-- ==============================================================================

USE `ummi_crew`;

-- 1. Storage Engine Gate (InnoDB Required for all referenced tables)
SELECT 
    '1. Storage Engine Gate' AS Section,
    table_name AS TableName,
    engine AS Engine,
    CASE WHEN engine = 'InnoDB' THEN 'PASS'
         ELSE 'STOP: Non-transactional Engine'
    END AS Status
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN (
    'tbl_users', 'tbl_user_assigned_vessel', 'tbl_vessels', 
    'tbl_principals', 'tbl_management', 'tbl_user_type'
  )
ORDER BY table_name;

-- 2. Target Columns Verification (Explicit Left Join to catch missing columns)
SELECT 
    '2. Target Columns Gate' AS Section,
    e.table_name AS TableName,
    e.column_name AS ColumnName,
    COALESCE(c.data_type, 'MISSING') AS DataType,
    CASE 
        WHEN c.column_name IS NOT NULL THEN 'PASS'
        ELSE 'STOP: Required column missing in schema'
    END AS Status
FROM (
    SELECT 'tbl_vessels' AS table_name, 'id' AS column_name UNION ALL
    SELECT 'tbl_vessels', 'vesselName' UNION ALL
    SELECT 'tbl_vessels', 'principal' UNION ALL
    SELECT 'tbl_vessels', 'management' UNION ALL
    SELECT 'tbl_vessels', 'owner' UNION ALL
    SELECT 'tbl_principals', 'id' UNION ALL
    SELECT 'tbl_principals', 'name' UNION ALL
    SELECT 'tbl_management', 'id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'user_id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'vessel_id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'principal_id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'management_id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'owner_id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'status' UNION ALL
    SELECT 'tbl_users', 'id' UNION ALL
    SELECT 'tbl_users', 'username' UNION ALL
    SELECT 'tbl_users', 'password' UNION ALL
    SELECT 'tbl_users', 'password_salt' UNION ALL
    SELECT 'tbl_users', 'fullname' UNION ALL
    SELECT 'tbl_users', 'type' UNION ALL
    SELECT 'tbl_users', 'management' UNION ALL
    SELECT 'tbl_users', 'email_address' UNION ALL
    SELECT 'tbl_users', 'viewcrewcontactdetails' UNION ALL
    SELECT 'tbl_users', 'viewcreatecontract' UNION ALL
    SELECT 'tbl_users', 'ccl_permission' UNION ALL
    SELECT 'tbl_users', 'disable_user' UNION ALL
    SELECT 'tbl_user_type', 'id' UNION ALL
    SELECT 'tbl_user_type', 'user_type'
) e
LEFT JOIN information_schema.columns c
  ON c.table_schema = DATABASE()
 AND c.table_name = e.table_name
 AND c.column_name = e.column_name
ORDER BY e.table_name, e.column_name;

-- 2b. Target Columns Summary Assertion Gate
SELECT 
    '2b. Target Columns Summary Gate' AS Section,
    COUNT(e.column_name) AS ExpectedColumnsCount,
    COUNT(c.column_name) AS FoundColumnsCount,
    CASE 
        WHEN COUNT(e.column_name) = COUNT(c.column_name) THEN 'PASS'
        ELSE 'STOP: One or more required columns are missing from staging schema'
    END AS Decision
FROM (
    SELECT 'tbl_vessels' AS table_name, 'id' AS column_name UNION ALL
    SELECT 'tbl_vessels', 'vesselName' UNION ALL
    SELECT 'tbl_vessels', 'principal' UNION ALL
    SELECT 'tbl_vessels', 'management' UNION ALL
    SELECT 'tbl_vessels', 'owner' UNION ALL
    SELECT 'tbl_principals', 'id' UNION ALL
    SELECT 'tbl_principals', 'name' UNION ALL
    SELECT 'tbl_management', 'id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'user_id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'vessel_id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'principal_id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'management_id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'owner_id' UNION ALL
    SELECT 'tbl_user_assigned_vessel', 'status' UNION ALL
    SELECT 'tbl_users', 'id' UNION ALL
    SELECT 'tbl_users', 'username' UNION ALL
    SELECT 'tbl_users', 'password' UNION ALL
    SELECT 'tbl_users', 'password_salt' UNION ALL
    SELECT 'tbl_users', 'fullname' UNION ALL
    SELECT 'tbl_users', 'type' UNION ALL
    SELECT 'tbl_users', 'management' UNION ALL
    SELECT 'tbl_users', 'email_address' UNION ALL
    SELECT 'tbl_users', 'viewcrewcontactdetails' UNION ALL
    SELECT 'tbl_users', 'viewcreatecontract' UNION ALL
    SELECT 'tbl_users', 'ccl_permission' UNION ALL
    SELECT 'tbl_users', 'disable_user' UNION ALL
    SELECT 'tbl_user_type', 'id' UNION ALL
    SELECT 'tbl_user_type', 'user_type'
) e
LEFT JOIN information_schema.columns c
  ON c.table_schema = DATABASE()
 AND c.table_name = e.table_name
 AND c.column_name = e.column_name;

-- 3. Role Gate: VESSEL_OWNER (Confirm Role ID 7 & VARCHAR Type Representation)
SELECT 
    '3. Role Gate' AS Section,
    id AS RoleID,
    user_type AS UserTypeName,
    COUNT(*) AS FoundCount,
    CASE 
        WHEN COUNT(*) = 1 AND id = 7 THEN 'PASS (Role ID 7 confirmed; RoleHelper string VESSEL_OWNER verified)'
        ELSE 'STOP: Role VESSEL_OWNER missing or ID mismatch' 
    END AS Decision
FROM tbl_user_type
WHERE user_type = 'VESSEL_OWNER'
GROUP BY id, user_type;

-- 4. Assigned Vessel, Principal & Management Reference Gate
-- Joins tbl_principals using v.principal = p.id (no principal_id column)
SELECT 
    '4. Vessel, Principal & Management Gate' AS Section,
    v.id AS VesselID,
    v.vesselName AS VesselName,
    p.id AS PrincipalID,
    p.name AS PrincipalName,
    m.id AS ManagementID,
    v.owner AS VesselOwnerRef,
    CASE 
        WHEN v.id IS NOT NULL AND p.id IS NOT NULL AND m.id IS NOT NULL THEN 'PASS'
        ELSE 'STOP: Vessel A, bound Principal, or Management missing'
    END AS Decision
FROM tbl_vessels v
JOIN tbl_principals p ON v.principal = p.id
JOIN tbl_management m ON v.management = m.id
WHERE v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A';

-- 5. Collision Detection Gate (Must be 0)
SELECT 
    '5. Collision Gate' AS Section,
    COUNT(*) AS CollisionCount,
    CASE WHEN COUNT(*) = 0 THEN 'PASS'
         ELSE 'STOP: User qa2contact.owner.authorized already exists. Stop and inspect collision records; do not run automatic cleanup.'
    END AS Decision
FROM tbl_users
WHERE username = 'qa2contact.owner.authorized'
   OR email_address = 'qa2contact-owner@example.com';

-- 6. Helper Procedure Collision Gate (Must be 0)
SELECT 
    '6. Helper Procedure Gate' AS Section,
    'sp_setup_qa_c2_tc074_vessel_owner' AS ProcedureName,
    COUNT(*) AS ExistingRoutineCount,
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Clean routine namespace)'
         ELSE 'STOP: Procedure already exists. Stop and inspect existing routine.'
    END AS Decision
FROM information_schema.routines
WHERE routine_schema = DATABASE()
  AND routine_name = 'sp_setup_qa_c2_tc074_vessel_owner';
