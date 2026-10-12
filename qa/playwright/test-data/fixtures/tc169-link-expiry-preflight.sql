-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-169 PREFLIGHT SCRIPT
-- Test Case: TC-CM-169 (Natural Clock Link Expiry and Submit-After-Expiry)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Batch Identifier: QA2FOC-RUN-20261011-TC169
-- Classification: Strictly Read-Only Preflight Verification
-- ==============================================================================

USE `ummi_crew`;

-- 1. Storage Engine Verification (Guaranteed rows for every required table)
SELECT 
    '1. Storage Engine Gate' AS Section,
    req.tbl AS TableName,
    COALESCE(t.engine, 'MISSING TABLE') AS Engine,
    CASE 
        WHEN t.engine = 'InnoDB' THEN 'PASS'
        WHEN t.engine IS NULL THEN 'STOP: Table Missing'
        ELSE CONCAT('STOP: Non-transactional Engine (', t.engine, ')')
    END AS Status
FROM (
    SELECT 'tbl_applicant_generated_link' AS tbl UNION ALL
    SELECT 'tbl_personnel_info' UNION ALL
    SELECT 'tbl_users'
) req
LEFT JOIN information_schema.tables t 
  ON t.table_schema = DATABASE() AND t.table_name = req.tbl
ORDER BY req.tbl;

-- 2. Target Columns Verification (Guaranteed row for every required column)
SELECT 
    '2. Target Columns Gate' AS Section,
    req.tbl AS TableName,
    req.col AS ColumnName,
    COALESCE(c.data_type, 'MISSING COLUMN') AS DataType,
    CASE 
        WHEN c.column_name IS NOT NULL THEN 'PASS'
        ELSE 'STOP: Required Column Missing'
    END AS Status
FROM (
    SELECT 'tbl_applicant_generated_link' AS tbl, 'id' AS col UNION ALL
    SELECT 'tbl_applicant_generated_link', 'fullname' UNION ALL
    SELECT 'tbl_applicant_generated_link', 'email' UNION ALL
    SELECT 'tbl_applicant_generated_link', 'position_applied' UNION ALL
    SELECT 'tbl_applicant_generated_link', 'validity' UNION ALL
    SELECT 'tbl_applicant_generated_link', 'status' UNION ALL
    SELECT 'tbl_applicant_generated_link', 'date_generated' UNION ALL
    SELECT 'tbl_applicant_generated_link', 'generated_by' UNION ALL
    SELECT 'tbl_applicant_generated_link', 'link_token' UNION ALL
    SELECT 'tbl_applicant_generated_link', 'personnel_id' UNION ALL
    SELECT 'tbl_applicant_generated_link', 'last_date_access' UNION ALL
    SELECT 'tbl_personnel_info', 'id' UNION ALL
    SELECT 'tbl_personnel_info', 'firstname' UNION ALL
    SELECT 'tbl_personnel_info', 'lastname' UNION ALL
    SELECT 'tbl_personnel_info', 'email_address' UNION ALL
    SELECT 'tbl_users', 'id' UNION ALL
    SELECT 'tbl_users', 'username'
) req
LEFT JOIN information_schema.columns c
  ON c.table_schema = DATABASE() AND c.table_name = req.tbl AND c.column_name = req.col
ORDER BY req.tbl, req.col;

-- 3. Reference Manning User Gate (Guaranteed single-row decision with uniqueness check)
SELECT 
    '3. Reference Entity Gate' AS Section,
    'qa.manning.control' AS RequiredUsername,
    COUNT(u.id) AS FoundCount,
    MAX(u.id) AS SampleUserID,
    CASE 
        WHEN COUNT(u.id) = 1 THEN 'PASS'
        WHEN COUNT(u.id) = 0 THEN 'STOP: Reference user qa.manning.control missing'
        ELSE 'STOP: Duplicate reference user records found'
    END AS Decision
FROM (SELECT 'qa.manning.control' AS un) req
LEFT JOIN tbl_users u ON u.username = req.un;

-- 4. Collision Detection Gate (Isolated namespace: QA-C2-TC169-CLOCK-%)
SELECT 
    '4. Collision Detection Gate' AS Section,
    COUNT(*) AS ExistingCollisionCount,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS: Clean namespace'
        ELSE 'STOP: Existing TC-CM-169 clock fixtures found. Inspect before proceeding.'
    END AS Decision
FROM tbl_applicant_generated_link
WHERE fullname LIKE 'QA-C2-TC169-CLOCK-%'
   OR email LIKE 'tc169-clock-%@example.com';

-- 5. Helper Procedure Collision Gate (Must be absent before creation)
SELECT 
    '5. Helper Procedure Gate' AS Section,
    'sp_setup_qa_c2_tc169_expiry_fixtures' AS ProcedureName,
    COUNT(*) AS ExistingRoutineCount,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS: Routine absent, safe to create'
        ELSE 'STOP: Procedure already exists. Do NOT drop or replace; inspect definition.'
    END AS Decision
FROM information_schema.routines
WHERE routine_schema = DATABASE()
  AND routine_name = 'sp_setup_qa_c2_tc169_expiry_fixtures';

-- 6. Authoritative Database Clock & Timezone Inspection
SELECT 
    '6. Database Clock & Timezone Gate' AS Section,
    NOW() AS MySQL_Now,
    UTC_TIMESTAMP() AS MySQL_UtcTimestamp,
    CURRENT_TIMESTAMP() AS CurrentTimestamp,
    @@system_time_zone AS SystemTimeZone,
    @@time_zone AS SessionTimeZone;
