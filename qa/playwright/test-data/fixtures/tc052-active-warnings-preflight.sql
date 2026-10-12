-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-052 PREFLIGHT SCRIPT
-- Test Case: TC-CM-052 (Active Status Elapsed Date Warnings)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Batch Identifier: QA2FOC-RUN-20261011-TC052
-- Classification: Strictly Read-Only Preflight Verification
-- ==============================================================================

USE `ummi_crew`;

-- 1. Storage Engine Verification (InnoDB Required for all referenced tables)
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
    'tbl_personnel_info', 'tbl_vessels', 'tbl_rank', 
    'tbl_dropdown_selection', 'tbl_provinces', 'tbl_cities'
  )
ORDER BY table_name;

-- 2. Target Columns Verification (All inserted/referenced columns)
SELECT 
    '2. Target Columns Gate' AS Section,
    table_name AS TableName,
    column_name AS ColumnName,
    data_type AS DataType,
    'PASS' AS Status
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND (
    (table_name = 'tbl_personnel_info' AND column_name IN (
        'firstname', 'middlename', 'lastname', 'position', 'emp_status', 
        'crew_status', 'crew_availability', 'status_date', 'date_hired', 
        'date_of_birth', 'place_of_birth', 'gender', 'civil_status', 
        'blood_type', 'height', 'weight', 'picture_id', 'email_address', 
        'applicant_contact_num', 'address', 'province', 'city', 
        'assigned_vessel_id', 'note'
    ))
    OR (table_name = 'tbl_dropdown_selection' AND column_name IN ('id', 'type', 'sequence', 'meaning'))
    OR (table_name = 'tbl_vessels' AND column_name IN ('id', 'vesselName'))
    OR (table_name = 'tbl_rank' AND column_name IN ('id', 'rank_code', 'rank_type'))
    OR (table_name = 'tbl_provinces' AND column_name IN ('id', 'provinces'))
    OR (table_name = 'tbl_cities' AND column_name IN ('id', 'cities', 'province'))
  )
ORDER BY table_name, column_name;

-- 3. Reference Entities Verification (Strict COUNT(*) = 1 each)
SELECT 
    '3. Reference Entities Gate' AS Section,
    'QA-C2-RUN-20261001-C2P1-Vessel-A' AS EntityName,
    COUNT(*) AS FoundCount,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: QA Vessel A Missing' END AS Decision
FROM tbl_vessels WHERE vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A'
UNION ALL
SELECT 
    '3. Reference Entities Gate' AS Section,
    'Rank AB SEAMAN' AS EntityName,
    COUNT(*) AS FoundCount,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Rank AB SEAMAN Missing' END AS Decision
FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating'
UNION ALL
SELECT 
    '3. Reference Entities Gate' AS Section,
    'Crew Status ACTIVE' AS EntityName,
    COUNT(*) AS FoundCount,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Status ACTIVE Missing' END AS Decision
FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ACTIVE'
UNION ALL
SELECT 
    '3. Reference Entities Gate' AS Section,
    'Province Metro Manila' AS EntityName,
    COUNT(*) AS FoundCount,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Province Metro Manila Missing' END AS Decision
FROM tbl_provinces WHERE provinces = 'Metro Manila'
UNION ALL
SELECT 
    '3. Reference Entities Gate' AS Section,
    'City Manila (under Metro Manila)' AS EntityName,
    COUNT(*) AS FoundCount,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: City Manila Missing under Metro Manila' END AS Decision
FROM tbl_cities c
JOIN tbl_provinces p ON c.province = p.id
WHERE c.cities = 'Manila' AND p.provinces = 'Metro Manila';

-- 4. Collision Detection Gate (Must be 0)
SELECT 
    '4. Collision Detection Gate' AS Section,
    COUNT(*) AS ExistingCollisionCount,
    CASE WHEN COUNT(*) = 0 THEN 'PASS'
         ELSE 'STOP: Existing TC-CM-052 fixtures found. Stop and inspect collision records before proceeding.'
    END AS Decision
FROM tbl_personnel_info
WHERE lastname LIKE 'QA2FOC_Tc052_%'
   OR email_address IN ('qa2foc-tc052-active6m@example.com', 'qa2foc-tc052-active9m@example.com');

-- 5. Helper Procedure Collision Gate (Must be 0)
SELECT 
    '5. Helper Procedure Gate' AS Section,
    'sp_setup_qa_c2_tc052_active_warnings' AS ProcedureName,
    COUNT(*) AS ExistingRoutineCount,
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Clean routine namespace)'
         ELSE 'STOP: Procedure already exists. Stop and inspect existing routine.'
    END AS Decision
FROM information_schema.routines
WHERE routine_schema = DATABASE()
  AND routine_name = 'sp_setup_qa_c2_tc052_active_warnings';
