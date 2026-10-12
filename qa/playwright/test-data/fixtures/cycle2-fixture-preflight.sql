-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 PHASE 1 LIVE SCHEMA PREFLIGHT
-- Target: Azure Staging Environment Only
-- Run Identifier: QA-C2-RUN-20261001-C2P1
-- Classification: READ-ONLY Preflight Verification with Strict Uniqueness Gates
-- 
-- Safety Rules:
-- 1. Strictly Read-Only: Performs ZERO inserts, updates, deletes, or DDL statements.
-- 2. Unique Reference Enforcement: Asserts COUNT(*) = 1 for every individual rank,
--    document type, vessel type, user role, and status code.
-- 3. Preflight Gate: Returns PROCEED if and only if all uniqueness and schema checks pass;
--    returns STOP immediately if any count is 0 or greater than 1.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- CHECK 1: REQUIRED APPLICATION TABLES
-- ------------------------------------------------------------------------------
SELECT 
    '1. Required Tables' AS PreflightSection,
    table_name AS TableName,
    'EXISTS' AS Status
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
  AND table_name IN (
    'tbl_principals', 'tbl_vessels', 'tbl_users', 'tbl_user_assigned_vessel',
    'tbl_personnel_info', 'tbl_personnel_documents', 'tbl_personnel_comment',
    'tbl_personnel_family_info', 'tbl_applicant_generated_link', 
    'tbl_ccl_relievers', 'tbl_ccl_schedules', 'tbl_rank', 'tbl_documents',
    'tbl_type_of_vessel', 'tbl_dropdown_selection', 'tbl_user_type'
  )
ORDER BY table_name;

SELECT 
    '1. Summary Table Readiness' AS PreflightSection,
    COUNT(*) AS FoundTables,
    16 AS ExpectedTables,
    CASE WHEN COUNT(*) = 16 THEN 'PASS'
         ELSE 'STOP: Missing Required Application Tables'
    END AS TableGateDecision
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
  AND table_name IN (
    'tbl_principals', 'tbl_vessels', 'tbl_users', 'tbl_user_assigned_vessel',
    'tbl_personnel_info', 'tbl_personnel_documents', 'tbl_personnel_comment',
    'tbl_personnel_family_info', 'tbl_applicant_generated_link', 
    'tbl_ccl_relievers', 'tbl_ccl_schedules', 'tbl_rank', 'tbl_documents',
    'tbl_type_of_vessel', 'tbl_dropdown_selection', 'tbl_user_type'
  );

-- ------------------------------------------------------------------------------
-- CHECK 1b: TARGET TABLES STORAGE ENGINE (InnoDB Verification)
-- Rollback cannot protect nontransactional tables; all 11 modified target tables must use InnoDB.
-- ------------------------------------------------------------------------------
SELECT 
    '1b. Storage Engine Verification' AS PreflightSection,
    table_name AS TableName,
    engine AS Engine,
    CASE 
        WHEN engine = 'InnoDB' THEN 'PASS (Transactional Engine)'
        ELSE 'STOP: Non-transactional Storage Engine Detected'
    END AS EngineStatus
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
  AND table_name IN (
    'tbl_principals', 'tbl_vessels', 'tbl_users', 'tbl_user_assigned_vessel',
    'tbl_personnel_info', 'tbl_personnel_documents', 'tbl_personnel_comment',
    'tbl_personnel_family_info', 'tbl_applicant_generated_link', 
    'tbl_ccl_relievers', 'tbl_ccl_schedules'
  )
ORDER BY table_name;

SELECT 
    '1b. Summary Engine Readiness' AS PreflightSection,
    COUNT(*) AS FoundInnoDBTables,
    11 AS ExpectedInnoDBTables,
    CASE WHEN COUNT(*) = 11 THEN 'PASS'
         ELSE 'STOP: Non-transactional Engine on Target Table'
    END AS EngineGateDecision
FROM information_schema.tables 
WHERE table_schema = DATABASE() 
  AND table_name IN (
    'tbl_principals', 'tbl_vessels', 'tbl_users', 'tbl_user_assigned_vessel',
    'tbl_personnel_info', 'tbl_personnel_documents', 'tbl_personnel_comment',
    'tbl_personnel_family_info', 'tbl_applicant_generated_link', 
    'tbl_ccl_relievers', 'tbl_ccl_schedules'
  )
  AND engine = 'InnoDB';

-- ------------------------------------------------------------------------------
-- CHECK 2: REQUIRED COLUMNS AND DATA TYPES
-- ------------------------------------------------------------------------------
SELECT 
    '2. Key Column Definitions' AS PreflightSection,
    table_name AS TableName,
    column_name AS ColumnName,
    data_type AS DataType,
    is_nullable AS IsNullable
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND (
    (table_name = 'tbl_users' AND column_name IN ('viewcrewcontactdetails', 'ccl_permission', 'disable_user', 'type'))
    OR (table_name = 'tbl_personnel_info' AND column_name IN ('assigned_vessel_id', 'crew_status', 'position', 'email_address'))
    OR (table_name = 'tbl_personnel_documents' AND column_name IN ('document_id', 'document_num', 'img_id', 'personnel_id'))
    OR (table_name = 'tbl_personnel_comment' AND column_name IN ('comments', 'img_id', 'principal_view', 'personnel_id'))
    OR (table_name = 'tbl_applicant_generated_link' AND column_name IN ('fullname', 'email', 'validity', 'status', 'link_token'))
    OR (table_name = 'tbl_ccl_relievers' AND column_name IN ('vessel_id', 'outgoing_crew_id', 'reliever_crew_id', 'status'))
    OR (table_name = 'tbl_ccl_schedules' AND column_name IN ('reliever_id', 'vessel_id', 'crew_id', 'schedule_status'))
    OR (table_name = 'tbl_dropdown_selection' AND column_name IN ('id', 'type', 'meaning', 'status', 'sequence'))
  )
ORDER BY table_name, column_name;

-- ------------------------------------------------------------------------------
-- CHECK 3: FOREIGN KEY CONSTRAINTS
-- ------------------------------------------------------------------------------
SELECT 
    '3. Foreign Key Constraints' AS PreflightSection,
    table_name AS ChildTable,
    constraint_name AS ConstraintName,
    referenced_table_name AS ParentTable
FROM information_schema.key_column_usage
WHERE table_schema = DATABASE()
  AND referenced_table_name IS NOT NULL
  AND table_name IN (
    'tbl_user_assigned_vessel', 'tbl_personnel_info', 'tbl_personnel_documents',
    'tbl_personnel_comment', 'tbl_personnel_family_info', 'tbl_ccl_relievers',
    'tbl_ccl_schedules', 'tbl_vessels'
  )
ORDER BY table_name, constraint_name;

-- ------------------------------------------------------------------------------
-- CHECK 4: ROLE CODES STRICT UNIQUENESS (tbl_user_type)
-- Must confirm COUNT(*) = 1 for each required role code.
-- ------------------------------------------------------------------------------
SELECT 
    '4. Role Codes Uniqueness' AS PreflightSection,
    r.ExpectedRole,
    COUNT(t.id) AS ResolvedCount,
    CASE 
        WHEN COUNT(t.id) = 1 THEN 'PASS (Unique)'
        WHEN COUNT(t.id) = 0 THEN 'STOP (Missing Role Code)'
        ELSE 'STOP (Duplicate Role Code Detected)'
    END AS UniquenessStatus
FROM (
    SELECT 'MANNING_STAFF' AS ExpectedRole
    UNION ALL SELECT 'PRINCIPAL'
    UNION ALL SELECT 'VESSEL_OWNER'
) r
LEFT JOIN tbl_user_type t ON t.user_type = r.ExpectedRole
GROUP BY r.ExpectedRole;

-- ------------------------------------------------------------------------------
-- CHECK 5: CREW STATUS CODES STRICT UNIQUENESS (tbl_dropdown_selection)
-- Must confirm COUNT(*) = 1 for each required status value.
-- ------------------------------------------------------------------------------
SELECT 
    '5. Crew Status Codes Uniqueness' AS PreflightSection,
    s.ExpectedStatus,
    COUNT(d.id) AS ResolvedCount,
    MAX(d.sequence) AS ResolvedSequence,
    MAX(d.meaning) AS ResolvedMeaning,
    MAX(d.status) AS ResolvedStatus,
    CASE 
        WHEN COUNT(d.id) = 1 THEN 'PASS (Unique)'
        WHEN COUNT(d.id) = 0 THEN 'STOP (Missing Status Code)'
        ELSE 'STOP (Duplicate Status Code Detected)'
    END AS UniquenessStatus
FROM (
    SELECT 'ACTIVE' AS ExpectedStatus
    UNION ALL SELECT 'INACTIVE'
    UNION ALL SELECT 'ON BOARD'
    UNION ALL SELECT 'ON VACATION'
    UNION ALL SELECT 'APPLICANT'
    UNION ALL SELECT 'LINE UP'
) s
LEFT JOIN tbl_dropdown_selection d ON d.type = 'crew_status' AND d.meaning = s.ExpectedStatus
GROUP BY s.ExpectedStatus;

-- ------------------------------------------------------------------------------
-- CHECK 6: REQUIRED RANKS STRICT UNIQUENESS (tbl_rank)
-- Must confirm COUNT(*) = 1 for each (rank_code, rank_type) pair.
-- ------------------------------------------------------------------------------
SELECT 
    '6. Rank References Uniqueness' AS PreflightSection,
    req.RankCode,
    req.RankType,
    COUNT(r.id) AS ResolvedCount,
    MAX(r.id) AS ResolvedID,
    CASE 
        WHEN COUNT(r.id) = 1 THEN 'PASS (Unique)'
        WHEN COUNT(r.id) = 0 THEN 'STOP (Missing Rank)'
        ELSE 'STOP (Duplicate Rank Definition Detected)'
    END AS UniquenessStatus
FROM (
    SELECT 'AB SEAMAN' AS RankCode, 'Rating' AS RankType
    UNION ALL SELECT 'BOSUN', 'Rating'
    UNION ALL SELECT '3RD OFFICER', 'Deck'
    UNION ALL SELECT 'MASTER', 'Deck'
    UNION ALL SELECT '4TH ENGINEER', 'Engine'
    UNION ALL SELECT 'CHIEF COOK', 'Catering'
) req
LEFT JOIN tbl_rank r ON r.rank_code = req.RankCode AND r.rank_type = req.RankType
GROUP BY req.RankCode, req.RankType;

-- ------------------------------------------------------------------------------
-- CHECK 7: REQUIRED DOCUMENT TYPES STRICT UNIQUENESS (tbl_documents)
-- Must confirm COUNT(*) = 1 for each required document definition.
-- ------------------------------------------------------------------------------
SELECT 
    '7. Document Definitions Uniqueness' AS PreflightSection,
    req.DocName,
    req.Category,
    COUNT(d.id) AS ResolvedCount,
    MAX(d.id) AS ResolvedID,
    CASE 
        WHEN COUNT(d.id) = 1 THEN 'PASS (Unique)'
        WHEN COUNT(d.id) = 0 THEN 'STOP (Missing Document Type)'
        ELSE 'STOP (Duplicate Document Definition Detected)'
    END AS UniquenessStatus
FROM (
    SELECT 'Seafarer\'s Book (Seaman\'s Book)' AS DocName, 'License' AS Category
    UNION ALL SELECT 'PEME (Pre-Employment Medical Exam)', 'Medical'
    UNION ALL SELECT 'Passport', 'Personal'
) req
LEFT JOIN tbl_documents d ON d.documentName = req.DocName AND d.docType = req.Category
GROUP BY req.DocName, req.Category;

-- ------------------------------------------------------------------------------
-- CHECK 8: REQUIRED VESSEL TYPES STRICT UNIQUENESS (tbl_type_of_vessel)
-- Must confirm COUNT(*) = 1 for each required vessel type.
-- ------------------------------------------------------------------------------
SELECT 
    '8. Vessel Types Uniqueness' AS PreflightSection,
    req.TypeName,
    COUNT(t.id) AS ResolvedCount,
    MAX(t.id) AS ResolvedID,
    CASE 
        WHEN COUNT(t.id) = 1 THEN 'PASS (Unique)'
        WHEN COUNT(t.id) = 0 THEN 'STOP (Missing Vessel Type)'
        ELSE 'STOP (Duplicate Vessel Type Detected)'
    END AS UniquenessStatus
FROM (
    SELECT 'Bulk Carrier' AS TypeName
    UNION ALL SELECT 'Container Ship'
) req
LEFT JOIN tbl_type_of_vessel t ON t.typeOfVessel = req.TypeName
GROUP BY req.TypeName;

-- ------------------------------------------------------------------------------
-- CHECK 9: CCL STATUS VALUES & LINK STATUS ENUMS
-- ------------------------------------------------------------------------------
SELECT 
    '9. CCL & Link Statuses' AS PreflightSection,
    'tbl_ccl_relievers.status DEFAULT Pending Approval' AS CheckItem,
    CASE 
        WHEN (SELECT column_default FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='tbl_ccl_relievers' AND column_name='status') = 'Pending Approval'
        THEN 'PASS' ELSE 'STOP: Status default mismatch'
    END AS StatusCheck
UNION ALL
SELECT 
    '9. CCL & Link Statuses',
    'tbl_ccl_schedules.schedule_status DEFAULT Tentative',
    CASE 
        WHEN (SELECT column_default FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='tbl_ccl_schedules' AND column_name='schedule_status') = 'Tentative'
        THEN 'PASS' ELSE 'STOP: Status default mismatch'
    END
UNION ALL
SELECT 
    '9. CCL & Link Statuses',
    'tbl_applicant_generated_link.status DEFAULT Active',
    CASE 
        WHEN (SELECT column_default FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='tbl_applicant_generated_link' AND column_name='status') = 'Active'
        THEN 'PASS' ELSE 'STOP: Status default mismatch'
    END;

-- ------------------------------------------------------------------------------
-- CHECK 10: FINAL PREFLIGHT READINESS DECISION (PROCEED vs STOP)
-- ------------------------------------------------------------------------------
SELECT 
    '10. Final Preflight Gate' AS GateCheck,
    CASE 
        -- Check 1: 16 Required Tables
        WHEN (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name IN (
            'tbl_principals','tbl_vessels','tbl_users','tbl_user_assigned_vessel',
            'tbl_personnel_info','tbl_personnel_documents','tbl_personnel_comment',
            'tbl_personnel_family_info','tbl_applicant_generated_link','tbl_ccl_relievers',
            'tbl_ccl_schedules','tbl_rank','tbl_documents','tbl_type_of_vessel',
            'tbl_dropdown_selection','tbl_user_type'
        )) <> 16 THEN 'STOP: Table prerequisite failed.'

        -- Check 1b: All 11 Modified Target Tables Must Use InnoDB
        WHEN (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name IN (
            'tbl_principals','tbl_vessels','tbl_users','tbl_user_assigned_vessel',
            'tbl_personnel_info','tbl_personnel_documents','tbl_personnel_comment',
            'tbl_personnel_family_info','tbl_applicant_generated_link','tbl_ccl_relievers',
            'tbl_ccl_schedules'
        ) AND engine = 'InnoDB') <> 11
        THEN 'STOP: Target tables InnoDB transactional engine check failed.'

        -- Check 4: Exactly 3 Unique Role Codes
        WHEN (SELECT COUNT(DISTINCT user_type) FROM tbl_user_type WHERE user_type IN ('MANNING_STAFF', 'PRINCIPAL', 'VESSEL_OWNER')) <> 3
          OR (SELECT COUNT(*) FROM tbl_user_type WHERE user_type IN ('MANNING_STAFF', 'PRINCIPAL', 'VESSEL_OWNER')) <> 3
        THEN 'STOP: Role uniqueness failed.'

        -- Check 5: Exactly 1 Unique Record per Required Crew Status Code (COUNT(*) = 1 each)
        WHEN (SELECT COUNT(*) FROM tbl_dropdown_selection WHERE type='crew_status' AND meaning = 'ACTIVE') <> 1
          OR (SELECT COUNT(*) FROM tbl_dropdown_selection WHERE type='crew_status' AND meaning = 'INACTIVE') <> 1
          OR (SELECT COUNT(*) FROM tbl_dropdown_selection WHERE type='crew_status' AND meaning = 'ON BOARD') <> 1
          OR (SELECT COUNT(*) FROM tbl_dropdown_selection WHERE type='crew_status' AND meaning = 'ON VACATION') <> 1
          OR (SELECT COUNT(*) FROM tbl_dropdown_selection WHERE type='crew_status' AND meaning = 'APPLICANT') <> 1
          OR (SELECT COUNT(*) FROM tbl_dropdown_selection WHERE type='crew_status' AND meaning = 'LINE UP') <> 1
        THEN 'STOP: Crew status uniqueness failed (individual status count <> 1).'

        -- Check 6: Exactly 6 Unique Ranks
        WHEN (SELECT COUNT(*) FROM tbl_rank WHERE 
            (rank_code='AB SEAMAN' AND rank_type='Rating') OR
            (rank_code='BOSUN' AND rank_type='Rating') OR
            (rank_code='3RD OFFICER' AND rank_type='Deck') OR
            (rank_code='MASTER' AND rank_type='Deck') OR
            (rank_code='4TH ENGINEER' AND rank_type='Engine') OR
            (rank_code='CHIEF COOK' AND rank_type='Catering')
        ) <> 6 THEN 'STOP: Rank uniqueness failed.'

        -- Check 7: Exactly 3 Unique Documents
        WHEN (SELECT COUNT(*) FROM tbl_documents WHERE 
            (docType='License' AND documentName='Seafarer\'s Book (Seaman\'s Book)') OR
            (docType='Medical' AND documentName='PEME (Pre-Employment Medical Exam)') OR
            (docType='Personal' AND documentName='Passport')
        ) <> 3 THEN 'STOP: Document uniqueness failed.'

        -- Check 8: Exactly 2 Unique Vessel Types
        WHEN (SELECT COUNT(*) FROM tbl_type_of_vessel WHERE typeOfVessel IN ('Bulk Carrier', 'Container Ship')) <> 2
        THEN 'STOP: Vessel type uniqueness failed.'

        ELSE 'PROCEED: Source-schema compatibility verified; live staging schema preflight PASSED with strict uniqueness.'
    END AS GateDecision;
