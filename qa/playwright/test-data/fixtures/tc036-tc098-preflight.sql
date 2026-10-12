-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 FOCUSED PREFLIGHT SCRIPT
-- Test Cases: TC-CM-036 (Availability Date Range) & TC-CM-098 (Total Sea Service)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Batch Identifier: QA2FOC-RUN-20261011
-- Classification: Strictly Read-Only Preflight Verification
--
-- Confirmed Staging Evidence:
-- 1. tbl_personnel_info.available_from & available_to are confirmed nullable DATE columns.
-- 2. spQueryCrewSearchDisplay filters strictly on available_from:
--    available_from >= availFrom_ AND available_from < DATE_ADD(availTo_, INTERVAL 1 DAY).
-- 3. spQueryCrewSearchDisplay returns '0.0 AS total_sea_service' (SP stub).
--    The application runtime behavior on Crew Search and Profile Viewer remains
--    unverified until tested live.
-- 4. Workbench session timezone is UTC. Application runtime connection timezone remains
--    unverified until supported by runtime evidence.
-- ==============================================================================

USE `ummi_crew`;

-- ------------------------------------------------------------------------------
-- 1. STORAGE ENGINE VERIFICATION (InnoDB Required for Atomic Rollback)
-- ------------------------------------------------------------------------------
SELECT 
    '1. Storage Engine Verification' AS Section,
    table_name AS TableName,
    engine AS Engine,
    CASE WHEN engine = 'InnoDB' THEN 'PASS'
         ELSE 'STOP: Non-transactional Engine'
    END AS Status
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN (
    'tbl_personnel_info', 'tbl_contracts', 'tbl_personnel_sea_service',
    'tbl_vessels', 'tbl_rank', 'tbl_dropdown_selection', 'tbl_users'
  )
ORDER BY table_name;

SELECT 
    '1b. Storage Engine Gate' AS Section,
    COUNT(*) AS FoundInnoDBTables,
    7 AS ExpectedInnoDBTables,
    CASE WHEN COUNT(*) = 7 THEN 'PASS'
         ELSE 'STOP: One or more target tables not using InnoDB engine'
    END AS Decision
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN (
    'tbl_personnel_info', 'tbl_contracts', 'tbl_personnel_sea_service',
    'tbl_vessels', 'tbl_rank', 'tbl_dropdown_selection', 'tbl_users'
  )
  AND engine = 'InnoDB';

-- ------------------------------------------------------------------------------
-- 2. CONFIRMED COLUMN VERIFICATION: tbl_personnel_info.available_from & available_to
-- Explicitly binds to the confirmed DATE columns
-- ------------------------------------------------------------------------------
SELECT 
    '2. Confirmed Availability Columns' AS Section,
    column_name AS ColumnName,
    ordinal_position AS OrdinalPos,
    data_type AS DataType,
    column_type AS FullType,
    is_nullable AS IsNullable,
    column_default AS ColumnDefault,
    CASE 
        WHEN column_name IN ('available_from', 'available_to') AND data_type = 'date' 
            THEN 'PASS (Confirmed Staging DATE column)'
        ELSE 'CHECK'
    END AS ColumnStatus
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'tbl_personnel_info'
  AND column_name IN ('available_from', 'available_to')
ORDER BY ordinal_position;

-- ------------------------------------------------------------------------------
-- 3. STORED PROCEDURE CONFIRMATION: spQueryCrewSearchDisplay FILTER & RETURN VALUE
-- Confirms spQueryCrewSearchDisplay parameter signature
-- ------------------------------------------------------------------------------
SELECT 
    '3. Stored Procedure Signature' AS Section,
    specific_name AS ProcedureName,
    ordinal_position AS ParamPosition,
    parameter_name AS ParameterName,
    parameter_mode AS ParamMode,
    data_type AS DataType,
    dtd_identifier AS FullDataType
FROM information_schema.parameters
WHERE specific_schema = DATABASE()
  AND specific_name = 'spQueryCrewSearchDisplay'
ORDER BY ordinal_position;

-- ------------------------------------------------------------------------------
-- 4. REQUIRED REFERENCE UNIQUENESS CHECKS (Must be COUNT(*) = 1 each)
-- ------------------------------------------------------------------------------
SELECT 
    '4. Reference Uniqueness' AS Section,
    'QA Vessel A (QA-C2-RUN-20261001-C2P1-Vessel-A)' AS ReferenceEntity,
    COUNT(*) AS ActualCount,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END AS Status
FROM tbl_vessels WHERE vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A'
UNION ALL
SELECT 
    '4. Reference Uniqueness', 'Rank: AB SEAMAN (Rating)', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating'
UNION ALL
SELECT 
    '4. Reference Uniqueness', 'Crew Status: ACTIVE', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ACTIVE'
UNION ALL
SELECT 
    '4. Reference Uniqueness', 'Authorized QA Manning Control User (qa.manning.control)', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_users WHERE username = 'qa.manning.control' AND disable_user = 0;

-- ------------------------------------------------------------------------------
-- 5. PREFLIGHT COLLISION CHECKS: PERSONNEL, EMAILS, AND CONTRACTS
-- Must be COUNT(*) = 0 across all QA2FOC_ tags
-- ------------------------------------------------------------------------------
SELECT 
    '5. Collision Check' AS Section,
    'Personnel Records with QA2FOC_ LastName' AS TargetCollisionGroup,
    COUNT(*) AS ExistingCount,
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Clean namespace)' ELSE 'STOP: Collision detected' END AS Status
FROM tbl_personnel_info
WHERE lastname LIKE 'QA2FOC_%'
UNION ALL
SELECT 
    '5. Collision Check', 'Personnel Records with qa2foc- Email',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Clean namespace)' ELSE 'STOP: Collision detected' END
FROM tbl_personnel_info
WHERE email_address LIKE 'qa2foc-%@example.com'
UNION ALL
SELECT 
    '5. Collision Check', 'Contracts for QA2FOC_ Personnel',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Clean namespace)' ELSE 'STOP: Collision detected' END
FROM tbl_contracts c
JOIN tbl_personnel_info p ON c.personnel_id = p.id
WHERE p.lastname LIKE 'QA2FOC_%' OR p.email_address LIKE 'qa2foc-%@example.com';

-- ------------------------------------------------------------------------------
-- 5b. HELPER PROCEDURE COLLISION GATE
-- Verifies that sp_setup_qa_c2_focused_tc036_tc098 does NOT already exist.
-- If it exists, STOP without dropping, replacing, or calling it.
-- ------------------------------------------------------------------------------
SELECT 
    '5b. Helper Procedure Gate' AS Section,
    'sp_setup_qa_c2_focused_tc036_tc098' AS HelperProcedureName,
    COUNT(*) AS ExistingRoutineCount,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS (Clean routine namespace)'
        ELSE 'STOP: Procedure already exists. Do not drop, replace, or call without manual inspection.'
    END AS Decision
FROM information_schema.routines
WHERE routine_schema = DATABASE()
  AND routine_name = 'sp_setup_qa_c2_focused_tc036_tc098';

-- ------------------------------------------------------------------------------
-- 6. SESSION DATE, TIMEZONE, AND PHILIPPINE EVALUATION DATE
-- Note: Workbench session timezone is UTC; application runtime connection timezone
-- remains unverified until supported by runtime evidence.
-- ------------------------------------------------------------------------------
SELECT 
    '6. Timezone & Operational Dates' AS Section,
    @@session.time_zone AS WorkbenchSessionTimeZone,
    @@global.time_zone AS GlobalTimeZone,
    NOW() AS DbSessionDateTime,
    UTC_TIMESTAMP() AS UtcDateTime,
    CURDATE() AS DbSessionDate,
    DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR)) AS PhilippineEvaluationDate;

-- ------------------------------------------------------------------------------
-- 7. TC-CM-098 SEA-SERVICE CALCULATION SIMULATION (READ-ONLY)
-- Simulates contract service days under documented formulas:
--   Fixture 1: Completed company contract (2025-01-01 to 2025-10-01)
--   Fixture 2: Ongoing company contract without date_to (starting 2026-04-29)
-- ------------------------------------------------------------------------------
SELECT 
    '7. TC-CM-098 Service Calculation' AS Section,
    'Completed Contract Fixture' AS FixtureType,
    '2025-01-01' AS DateFrom,
    '2025-10-01' AS DateTo,
    DATEDIFF('2025-10-01', '2025-01-01') AS RawServiceDays,
    DATEDIFF('2025-10-01', '2025-01-01') / 365.25 AS RawYearsExact,
    CONCAT(ROUND(DATEDIFF('2025-10-01', '2025-01-01') / 365.25, 1), ' yr(s)') AS DisplayedTotalExpected,
    'N/A (Fixed historical dates)' AS OneDayAsOfErrorSensitivity
UNION ALL
SELECT 
    '7. TC-CM-098 Service Calculation',
    'Ongoing Contract Fixture (Philippine Date UTC+8)',
    '2026-04-29',
    DATE_FORMAT(DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR)), '%Y-%m-%d'),
    DATEDIFF(DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR)), '2026-04-29'),
    DATEDIFF(DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR)), '2026-04-29') / 365.25,
    CONCAT(ROUND(DATEDIFF(DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR)), '2026-04-29') / 365.25, 1), ' yr(s)'),
    CONCAT(
        'If evaluated as-of DB Session UTC Date (', DATE_FORMAT(CURDATE(), '%Y-%m-%d'), '): ',
        DATEDIFF(CURDATE(), '2026-04-29'), ' days / 365.25 = ',
        ROUND(DATEDIFF(CURDATE(), '2026-04-29') / 365.25, 4), ' -> Display: ',
        ROUND(DATEDIFF(CURDATE(), '2026-04-29') / 365.25, 1), ' yr(s)'
    );
