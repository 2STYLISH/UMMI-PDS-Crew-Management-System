-- ==============================================================================
-- CYCLE 2 GAP CLOSURE: CONTACT RESTRICTIONS PREFLIGHT AUDIT
-- Test Cases: TC-CM-067, TC-CM-069, TC-CM-071
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Execution Mode: READ-ONLY (Zero write operations)
-- ==============================================================================

USE `ummi_crew`;

-- ------------------------------------------------------------------------------
-- 1. SCHEMA & TABLE EXISTENCE GATE
-- ------------------------------------------------------------------------------
SELECT 
    '1. Table Existence Gate' AS Section,
    table_name AS TargetTable,
    engine AS StorageEngine,
    table_rows AS EstimatedRows,
    'PASS' AS Status
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN ('tbl_users', 'tbl_user_type', 'tbl_personnel_info')
ORDER BY table_name;

-- ------------------------------------------------------------------------------
-- 2. COLUMN SCHEMA VERIFICATION (tbl_users)
-- ------------------------------------------------------------------------------
SELECT 
    '2. tbl_users Column Verification' AS Section,
    column_name AS TargetColumn,
    data_type AS DataType,
    character_maximum_length AS MaxLength,
    is_nullable AS IsNullable,
    column_default AS DefaultValue,
    CASE 
        WHEN column_name IN (
            'id', 'username', 'password', 'password_salt', 'fullname', 
            'type', 'management', 'viewcrewcontactdetails', 
            'viewcreatecontract', 'ccl_permission', 'disable_user'
        ) THEN 'PASS'
        ELSE 'FAIL'
    END AS Status
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'tbl_users'
  AND column_name IN (
      'id', 'username', 'password', 'password_salt', 'fullname', 
      'type', 'management', 'viewcrewcontactdetails', 
      'viewcreatecontract', 'ccl_permission', 'disable_user'
  )
ORDER BY ordinal_position;

-- ------------------------------------------------------------------------------
-- 3. ROLE VALUES VERIFICATION (tbl_user_type)
-- ------------------------------------------------------------------------------
SELECT 
    '3. Role Reference Verification' AS Section,
    id AS RoleID,
    user_type AS RoleType,
    CASE 
        WHEN user_type = 'DOCUMENTATION_OFFICER' AND id = 5 THEN 'PASS (TC-CM-067)'
        WHEN user_type = 'ADMIN' AND id = 6 THEN 'PASS (TC-CM-069)'
        WHEN user_type = 'SUPER_ADMIN' AND id = 2 THEN 'PASS (TC-CM-071)'
        ELSE 'INFO'
    END AS RoleStatus
FROM tbl_user_type
WHERE user_type IN ('DOCUMENTATION_OFFICER', 'ADMIN', 'SUPER_ADMIN', 'MANNING_STAFF')
ORDER BY id;

-- ------------------------------------------------------------------------------
-- 4. USERNAME COLLISION CHECK (Dedicated QA Accounts)
-- ------------------------------------------------------------------------------
SELECT 
    '4. Username Collision Check' AS Section,
    'qa2contact.doc.restricted' AS TargetUsername,
    COUNT(*) AS ExistingCount,
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Available)' ELSE 'STOP (Collision Detected)' END AS Status
FROM tbl_users WHERE username = 'qa2contact.doc.restricted'
UNION ALL
SELECT 
    '4. Username Collision Check',
    'qa2contact.admin.restricted',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Available)' ELSE 'STOP (Collision Detected)' END
FROM tbl_users WHERE username = 'qa2contact.admin.restricted'
UNION ALL
SELECT 
    '4. Username Collision Check',
    'qa2contact.superadmin.restricted',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Available)' ELSE 'STOP (Collision Detected)' END
FROM tbl_users WHERE username = 'qa2contact.superadmin.restricted';

-- ------------------------------------------------------------------------------
-- 5. EXISTING DEMO & QA ACCOUNTS PROTECTION AUDIT
-- ------------------------------------------------------------------------------
SELECT 
    '5. Shared Accounts Audit' AS Section,
    username,
    type AS role,
    viewcrewcontactdetails,
    'DO NOT MODIFY - Shared Account' AS ProtectionRule
FROM tbl_users
WHERE username IN ('demo.doc', 'demo.admin', 'demo.superadmin', 'qa.c2.20261001.manning.restricted')
ORDER BY id;
