-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 BATCH 18 READ-ONLY PREFLIGHT
-- Target: Azure Staging Environment Only
-- Run Identifier: QA2B18-RUN-20261010
-- Classification: Strictly Read-Only Preflight Verification
--
-- Operational Dates Validated For: October 10, 2026
--
-- Safety Guarantees:
-- 1. Strictly Read-Only: Performs ZERO inserts, updates, deletes, or DDL writes.
-- 2. Strict Uniqueness Verification: Asserts COUNT(*) = 1 for all required references.
-- 3. Preflight Collision Check: Confirms zero conflicting QA2B18 records exist across
--    personnel emails, user accounts, document numbers, and link tokens.
-- 4. Preserves Baseline Fixtures: Validates A001 (ID 163, 180cm, 72kg) and QA vessels.
-- ==============================================================================

USE `ummi_crew`;

-- ------------------------------------------------------------------------------
-- 1. TARGET TABLES STORAGE ENGINE VERIFICATION (InnoDB Required for Atomic Rollback)
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
    'tbl_users', 'tbl_personnel_info', 'tbl_personnel_documents',
    'tbl_personnel_sea_service', 'tbl_applicant_generated_link',
    'tbl_vessels', 'tbl_rank', 'tbl_type_of_vessel',
    'tbl_dropdown_selection', 'tbl_provinces', 'tbl_cities', 'tbl_documents'
  )
ORDER BY table_name;

SELECT 
    '1b. Storage Engine Gate' AS Section,
    COUNT(*) AS FoundInnoDBTables,
    12 AS ExpectedInnoDBTables,
    CASE WHEN COUNT(*) = 12 THEN 'PASS'
         ELSE 'STOP: One or more target tables not using InnoDB engine'
    END AS Decision
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN (
    'tbl_users', 'tbl_personnel_info', 'tbl_personnel_documents',
    'tbl_personnel_sea_service', 'tbl_applicant_generated_link',
    'tbl_vessels', 'tbl_rank', 'tbl_type_of_vessel',
    'tbl_dropdown_selection', 'tbl_provinces', 'tbl_cities', 'tbl_documents'
  )
  AND engine = 'InnoDB';

-- ------------------------------------------------------------------------------
-- 2. COLUMN DATA TYPE VERIFICATION: tbl_users.password & password_salt (PBKDF2 Storage)
-- ------------------------------------------------------------------------------
SELECT 
    '2. Credential Column Capacity' AS Section,
    column_name AS ColumnName,
    data_type AS DataType,
    character_maximum_length AS MaxLength,
    CASE 
        WHEN column_name = 'password' AND character_maximum_length >= 64 
            THEN 'PASS (Accommodates adaptive PBKDF2 v3 format: $pbkdf2:<iter>$<key>)'
        WHEN column_name = 'password_salt' AND character_maximum_length >= 44 
            THEN 'PASS (Accommodates 256-bit Base64 salt)'
        ELSE 'STOP: Insufficient column capacity for PBKDF2 credential format'
    END AS CapacityStatus
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'tbl_users'
  AND column_name IN ('password', 'password_salt')
ORDER BY column_name;

-- ------------------------------------------------------------------------------
-- 3. REQUIRED REFERENCE UNIQUENESS CHECKS (Must be COUNT(*) = 1 each)
-- ------------------------------------------------------------------------------
SELECT 
    '3. Reference Uniqueness' AS Section,
    'Vessel Type: Bulk Carrier' AS ReferenceEntity,
    COUNT(*) AS ActualCount,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END AS Status
FROM tbl_type_of_vessel WHERE typeOfVessel = 'Bulk Carrier'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Vessel Type: Container Ship', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_type_of_vessel WHERE typeOfVessel = 'Container Ship'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Vessel: QA Vessel A has type Bulk Carrier', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: QA Vessel A missing or incorrect type' END
FROM tbl_vessels v
JOIN tbl_type_of_vessel vt ON v.VesselType = vt.id
WHERE v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A' AND vt.typeOfVessel = 'Bulk Carrier'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Vessel: QA Vessel B has type Container Ship', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: QA Vessel B missing or incorrect type' END
FROM tbl_vessels v
JOIN tbl_type_of_vessel vt ON v.VesselType = vt.id
WHERE v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-B' AND vt.typeOfVessel = 'Container Ship'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Rank: AB SEAMAN (Rating)', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Rank: MASTER (Deck)', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_rank WHERE rank_code = 'MASTER' AND rank_type = 'Deck'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Rank: 3RD OFFICER (Deck)', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_rank WHERE rank_code = '3RD OFFICER' AND rank_type = 'Deck'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Crew Status: ACTIVE', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ACTIVE'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Crew Status: INACTIVE', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'INACTIVE'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Crew Status: ON BOARD', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ON BOARD'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Crew Status: ON VACATION', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ON VACATION'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Crew Status: APPLICANT', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'APPLICANT'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Province: Batangas', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_provinces WHERE provinces = 'Batangas'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Province: Metro Manila', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_provinces WHERE provinces = 'Metro Manila'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'City: Batangas City belongs to Batangas province', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Batangas City missing or province mismatch' END
FROM tbl_cities c
JOIN tbl_provinces p ON c.province = p.id
WHERE c.cities = 'Batangas City' AND p.provinces = 'Batangas'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'City: Manila belongs to Metro Manila province', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Manila missing or province mismatch' END
FROM tbl_cities c
JOIN tbl_provinces p ON c.province = p.id
WHERE c.cities = 'Manila' AND p.provinces = 'Metro Manila'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Document: Passport', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_documents WHERE docType = 'Personal' AND documentName = 'Passport'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Document: Seafarer\'s Book', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_documents WHERE docType = 'License' AND documentName = 'Seafarer\'s Book (Seaman\'s Book)'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Document: PEME', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Ambiguous or missing' END
FROM tbl_documents WHERE docType = 'Medical' AND documentName = 'PEME (Pre-Employment Medical Exam)'
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Staff User: qa.c2.20261001.manning.restricted', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Manning Staff user missing' END
FROM tbl_users WHERE username = 'qa.c2.20261001.manning.restricted' AND disable_user = 0
UNION ALL
SELECT 
    '3. Reference Uniqueness', 'Baseline Crew A001 (ID 163, 180cm, 72kg, On Board)', COUNT(*),
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'STOP: Crew A001 baseline mismatch' END
FROM tbl_personnel_info WHERE id = 163 AND height = 180.00 AND weight = 72.00;

-- ------------------------------------------------------------------------------
-- 4. COLLISION PREFLIGHT CHECK (Confirms zero conflicting Batch 18 records exist)
-- ------------------------------------------------------------------------------
SELECT 
    '4. Collision Check' AS Section,
    'Residual QA2B18 Personnel' AS CheckEntity,
    COUNT(*) AS ResidualCount,
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Clean for setup)'
         ELSE 'STOP: Run batch18-gap-closure-cleanup.sql first'
    END AS Status
FROM tbl_personnel_info
WHERE email_address IN (
    'qa2b18-tc030-match@example.com', 'qa2b18-tc030-ctrl@example.com',
    'qa2b18-tc031-match@example.com', 'qa2b18-tc031-ctrl@example.com',
    'qa2b18-tc032-match@example.com', 'qa2b18-tc032-ctrl@example.com',
    'qa2b18-tc033-match@example.com', 'qa2b18-tc033-ctrl@example.com',
    'qa2b18-tc034-match@example.com', 'qa2b18-tc034-ctrl@example.com',
    'qa2b18-tc050-vslb@example.com',  'qa2b18-tc050-unassigned@example.com',
    'qa2b18-tc055-lt4m@example.com',  'qa2b18-tc055-exact4m@example.com',
    'qa2b18-tc055-exact8m@example.com', 'qa2b18-tc055-gt8m@example.com',
    'qa2b18-tc055-ineligible@example.com',
    'qa2b18-tc076-blank@example.com', 'qa2b18-tc076-zero@example.com',
    'qa2b18-tc092-docbound@example.com',
    'qa2b18-tc125-before@example.com', 'qa2b18-tc125-start@example.com',
    'qa2b18-tc125-end@example.com',    'qa2b18-tc125-after@example.com',
    'qa2b18-tc134-target@example.com', 'qa2b18-tc134-ctrl@example.com'
)
UNION ALL
SELECT 
    '4. Collision Check', 'Residual QA2B18 Documents', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Clean for setup)'
         ELSE 'STOP: Run batch18-gap-closure-cleanup.sql first'
    END
FROM tbl_personnel_documents
WHERE document_num IN ('QA2B18-DOC-EXP-MINUS1D', 'QA2B18-DOC-EXP-EXACT3M', 'QA2B18-DOC-EXP-PLUS1D')
UNION ALL
SELECT 
    '4. Collision Check', 'Residual QA2B18 Dedicated User', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Clean for setup)'
         ELSE 'STOP: Run batch18-gap-closure-cleanup.sql first'
    END
FROM tbl_users WHERE username = 'qa2b18.principal.novessels'
UNION ALL
SELECT 
    '4. Collision Check', 'Residual QA2B18 Generated Links', COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS (Clean for setup)'
         ELSE 'STOP: Run batch18-gap-closure-cleanup.sql first'
    END
FROM tbl_applicant_generated_link
WHERE link_token IN (
    'TOK-QA2B18-TC152-ACTIVE-TOKEN',
    'TOK-QA2B18-TC152-USED-TOKEN',
    'TOK-QA2B18-TC152-EXPIRED-TOKEN'
);
