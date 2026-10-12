-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 FOCUSED FIXTURE SETUP
-- Test Cases: TC-CM-036 (Availability Date Range) & TC-CM-098 (Total Sea Service)
-- Target Database: ummi_crew (Azure Database for MySQL, InnoDB engine)
-- Batch Identifier: QA2FOC-RUN-20261011
-- Classification: One-Time Provisioning with Strict Precondition Gates, Collision Protection, and Atomic Transaction (Not Idempotent)
--
-- Safety Guarantees:
-- 1. No Leading Drop: Does NOT drop or overwrite any existing helper procedure.
-- 2. Schema-Bound: Binds explicitly to confirmed tbl_personnel_info.available_from (DATE, nullable).
-- 3. Pre-Commit Assertions: Verifies measured row counts (8 crew, 2 contracts, 0 prior sea service)
--    before COMMIT, reporting actual measured counts rather than hardcoded numbers.
-- 4. Collision Protection: Stops execution with SIGNAL SQLSTATE '45000' on any existing QA2FOC_ record.
-- 5. Atomic Rollback: Rolls back transaction on any error during execution.
-- ==============================================================================

USE `ummi_crew`;

DELIMITER $$

CREATE PROCEDURE sp_setup_qa_c2_focused_tc036_tc098()
proc_main: BEGIN
    -- --------------------------------------------------------------------------
    -- 1. LOCAL VARIABLE DECLARATIONS
    -- --------------------------------------------------------------------------
    DECLARE v_cnt INT DEFAULT 0;
    DECLARE v_actual_crew_count INT DEFAULT 0;
    DECLARE v_actual_contract_count INT DEFAULT 0;

    -- Dynamic Reference Identifiers
    DECLARE v_vsl_a_id       INT;
    DECLARE v_rank_ab_seaman INT;
    DECLARE v_status_active  INT;

    -- Created Personnel Primary Keys (TC-CM-036)
    DECLARE v_crew_036_before_id    INT;
    DECLARE v_crew_036_from_id      INT;
    DECLARE v_crew_036_to_id        INT;
    DECLARE v_crew_036_tolate_id    INT;
    DECLARE v_crew_036_after_id     INT;
    DECLARE v_crew_036_null_id      INT;

    -- Created Personnel Primary Keys (TC-CM-098)
    DECLARE v_crew_098_completed_id INT;
    DECLARE v_crew_098_ongoing_id   INT;

    -- Captured Philippine Date (UTC+8) at execution time
    DECLARE v_ph_today DATE;

    -- --------------------------------------------------------------------------
    -- 2. EXCEPTION HANDLER: ATOMIC ROLLBACK & RESIGNAL
    -- --------------------------------------------------------------------------
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Initialize Philippine Evaluation Date (UTC+8) dynamically
    SET v_ph_today = DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR));

    -- --------------------------------------------------------------------------
    -- 3. PRECONDITION VALIDATION: INNODB ENGINES
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name IN (
        'tbl_personnel_info', 'tbl_contracts', 'tbl_personnel_sea_service',
        'tbl_vessels', 'tbl_rank', 'tbl_dropdown_selection'
      )
      AND engine = 'InnoDB';
    IF v_cnt < 6 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gate Failed: Target tables not using InnoDB engine';
    END IF;

    -- --------------------------------------------------------------------------
    -- 4. PRECONDITION VALIDATION: COLUMN EXISTENCE
    -- Asserts confirmed available_from column exists in tbl_personnel_info
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'tbl_personnel_info'
      AND column_name = 'available_from'
      AND data_type = 'date';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gate Failed: tbl_personnel_info.available_from DATE column not found';
    END IF;

    -- --------------------------------------------------------------------------
    -- 5. PRECONDITION VALIDATION: REFERENCE ENTITIES (Strict COUNT(*) = 1 each)
    -- --------------------------------------------------------------------------
    SELECT id INTO v_vsl_a_id FROM tbl_vessels WHERE vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A';
    IF v_vsl_a_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: QA Vessel A missing in tbl_vessels';
    END IF;

    SELECT id INTO v_rank_ab_seaman FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating';
    IF v_rank_ab_seaman IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: Rank AB SEAMAN missing in tbl_rank';
    END IF;

    SELECT sequence INTO v_status_active FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ACTIVE';
    IF v_status_active IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: Crew status ACTIVE missing in tbl_dropdown_selection';
    END IF;

    -- --------------------------------------------------------------------------
    -- 6. PRECONDITION VALIDATION: COLLISION CHECKS (Must be COUNT(*) = 0)
    -- Stops rather than overwriting existing records
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM tbl_personnel_info
    WHERE lastname LIKE 'QA2FOC_%' OR email_address LIKE 'qa2foc-%@example.com';
    IF v_cnt > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Collision Gate Failed: Existing QA2FOC_ records found in tbl_personnel_info. Stop rather than overwriting.';
    END IF;

    -- --------------------------------------------------------------------------
    -- 7. ATOMIC TRANSACTIONAL PROVISIONING
    -- --------------------------------------------------------------------------
    START TRANSACTION;

    -- ==========================================================================
    -- TC-CM-036: CREW SEARCH AVAILABILITY-DATE RANGE FIXTURES (10–20 September 2026)
    -- Explicitly binds to tbl_personnel_info.available_from
    -- ==========================================================================

    -- Fixture 1: 9 September 2026 (Day before From boundary -> EXCLUDED from 10–20 Sep)
    INSERT INTO tbl_personnel_info (
        firstname, lastname, position, emp_status, crew_status, crew_availability,
        available_from, status_date, date_hired, date_of_birth, place_of_birth, gender,
        civil_status, blood_type, height, weight, email_address, applicant_contact_num,
        address, assigned_vessel_id, note
    ) VALUES (
        'Sep09', 'QA2FOC_Tc036_ExclBefore', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-09', '2026-09-01', '2025-01-15', '1990-01-01', 'Manila', 'Male',
        'Single', 'O+', 170.00, 65.00, 'qa2foc-tc036-excl-before@example.com', '+63 900 036 0001',
        'QA St, Manila', v_vsl_a_id, 'TC-CM-036: Excluded before range (2026-09-09)'
    );
    SET v_crew_036_before_id = LAST_INSERT_ID();

    -- Fixture 2: 10 September 2026 (From boundary -> INCLUDED in 10–20 Sep)
    INSERT INTO tbl_personnel_info (
        firstname, lastname, position, emp_status, crew_status, crew_availability,
        available_from, status_date, date_hired, date_of_birth, place_of_birth, gender,
        civil_status, blood_type, height, weight, email_address, applicant_contact_num,
        address, assigned_vessel_id, note
    ) VALUES (
        'Sep10', 'QA2FOC_Tc036_InclFrom', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-10', '2026-09-01', '2025-01-15', '1991-02-02', 'Manila', 'Male',
        'Single', 'O+', 172.00, 68.00, 'qa2foc-tc036-incl-from@example.com', '+63 900 036 0002',
        'QA St, Manila', v_vsl_a_id, 'TC-CM-036: Included on From boundary (2026-09-10)'
    );
    SET v_crew_036_from_id = LAST_INSERT_ID();

    -- Fixture 3: 20 September 2026 (To boundary fixture 1 -> INCLUDED in 10–20 Sep)
    INSERT INTO tbl_personnel_info (
        firstname, lastname, position, emp_status, crew_status, crew_availability,
        available_from, status_date, date_hired, date_of_birth, place_of_birth, gender,
        civil_status, blood_type, height, weight, email_address, applicant_contact_num,
        address, assigned_vessel_id, note
    ) VALUES (
        'Sep20', 'QA2FOC_Tc036_InclTo', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-20', '2026-09-01', '2025-01-15', '1992-03-03', 'Manila', 'Male',
        'Single', 'A+', 168.00, 62.00, 'qa2foc-tc036-incl-to@example.com', '+63 900 036 0003',
        'QA St, Manila', v_vsl_a_id, 'TC-CM-036: Included on To boundary fixture 1 (2026-09-20)'
    );
    SET v_crew_036_to_id = LAST_INSERT_ID();

    -- Fixture 4: 20 September 2026 (To boundary fixture 2 / Second Sep 20 record -> INCLUDED in 10–20 Sep)
    -- Note: Staging column is DATE (no time component). Late-time assertion is NOT APPLICABLE.
    INSERT INTO tbl_personnel_info (
        firstname, lastname, position, emp_status, crew_status, crew_availability,
        available_from, status_date, date_hired, date_of_birth, place_of_birth, gender,
        civil_status, blood_type, height, weight, email_address, applicant_contact_num,
        address, assigned_vessel_id, note
    ) VALUES (
        'Sep20Late', 'QA2FOC_Tc036_InclToLate', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-20', '2026-09-01', '2025-01-15', '1993-04-04', 'Manila', 'Female',
        'Single', 'B+', 165.00, 55.00, 'qa2foc-tc036-incl-to-late@example.com', '+63 900 036 0004',
        'QA St, Manila', v_vsl_a_id, 'TC-CM-036: Included on To boundary fixture 2 (2026-09-20; DATE type, late-time N/A)'
    );
    SET v_crew_036_tolate_id = LAST_INSERT_ID();

    -- Fixture 5: 21 September 2026 (Day after To boundary -> EXCLUDED from 10–20 Sep)
    INSERT INTO tbl_personnel_info (
        firstname, lastname, position, emp_status, crew_status, crew_availability,
        available_from, status_date, date_hired, date_of_birth, place_of_birth, gender,
        civil_status, blood_type, height, weight, email_address, applicant_contact_num,
        address, assigned_vessel_id, note
    ) VALUES (
        'Sep21', 'QA2FOC_Tc036_ExclAfter', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-21', '2026-09-01', '2025-01-15', '1994-05-05', 'Manila', 'Male',
        'Single', 'AB+', 175.00, 70.00, 'qa2foc-tc036-excl-after@example.com', '+63 900 036 0005',
        'QA St, Manila', v_vsl_a_id, 'TC-CM-036: Excluded after range (2026-09-21)'
    );
    SET v_crew_036_after_id = LAST_INSERT_ID();

    -- Fixture 6: NULL Availability Date (EXCLUDED when either boundary supplied; INCLUDED when both empty)
    INSERT INTO tbl_personnel_info (
        firstname, lastname, position, emp_status, crew_status, crew_availability,
        available_from, status_date, date_hired, date_of_birth, place_of_birth, gender,
        civil_status, blood_type, height, weight, email_address, applicant_contact_num,
        address, assigned_vessel_id, note
    ) VALUES (
        'NullDate', 'QA2FOC_Tc036_ExclNull', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        NULL, '2026-09-01', '2025-01-15', '1995-06-06', 'Manila', 'Female',
        'Single', 'O-', 160.00, 50.00, 'qa2foc-tc036-excl-null@example.com', '+63 900 036 0006',
        'QA St, Manila', v_vsl_a_id, 'TC-CM-036: NULL availability date (excluded when boundary is supplied)'
    );
    SET v_crew_036_null_id = LAST_INSERT_ID();

    -- ==========================================================================
    -- TC-CM-098: TOTAL SEA SERVICE COMPANY CONTRACT FIXTURES (NO PRIOR HISTORY)
    -- ==========================================================================

    -- Fixture 7: Completed Company Contract (2025-01-01 to 2025-10-01, 273 days -> 0.7 yr(s))
    INSERT INTO tbl_personnel_info (
        firstname, lastname, position, emp_status, crew_status, crew_availability,
        available_from, status_date, date_hired, date_of_birth, place_of_birth, gender,
        civil_status, blood_type, height, weight, email_address, applicant_contact_num,
        address, assigned_vessel_id, note
    ) VALUES (
        'Mateo', 'QA2FOC_Tc098_CompletedContract', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        NULL, '2025-01-01', '2025-01-01', '1992-07-15', 'Manila', 'Male',
        'Married', 'O+', 174.00, 68.00, 'qa2foc-tc098-completed@example.com', '+63 900 098 0001',
        'QA St, Manila', v_vsl_a_id, 'TC-CM-098: Completed contract (273 days = 0.7 yr(s)), no prior sea-service'
    );
    SET v_crew_098_completed_id = LAST_INSERT_ID();

    INSERT INTO tbl_contracts (
        personnel_id, vessel_id, rank_id, date_from, date_to, status, remarks
    ) VALUES (
        v_crew_098_completed_id, v_vsl_a_id, v_rank_ab_seaman, '2025-01-01', '2025-10-01',
        'Completed', 'TC-CM-098 FIXTURE: Completed company contract (273 net days)'
    );

    -- Fixture 8: Ongoing Company Contract with No End Date (starts 2026-04-29)
    INSERT INTO tbl_personnel_info (
        firstname, lastname, position, emp_status, crew_status, crew_availability,
        available_from, status_date, date_hired, date_of_birth, place_of_birth, gender,
        civil_status, blood_type, height, weight, email_address, applicant_contact_num,
        address, assigned_vessel_id, note
    ) VALUES (
        'Lucas', 'QA2FOC_Tc098_OngoingContract', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        NULL, '2026-04-29', '2026-04-29', '1993-08-20', 'Manila', 'Male',
        'Single', 'A+', 171.00, 66.00, 'qa2foc-tc098-ongoing@example.com', '+63 900 098 0002',
        'QA St, Manila', v_vsl_a_id, 'TC-CM-098: Ongoing contract (starts 2026-04-29, NULL date_to), no prior sea-service'
    );
    SET v_crew_098_ongoing_id = LAST_INSERT_ID();

    INSERT INTO tbl_contracts (
        personnel_id, vessel_id, rank_id, date_from, date_to, status, remarks
    ) VALUES (
        v_crew_098_ongoing_id, v_vsl_a_id, v_rank_ab_seaman, '2026-04-29', NULL,
        'Active', 'TC-CM-098 FIXTURE: Ongoing company contract without end date'
    );

    -- --------------------------------------------------------------------------
    -- 8. PRE-COMMIT STRICT ASSERTIONS: ZERO PRIOR SEA-SERVICE & MEASURED COUNTS
    -- --------------------------------------------------------------------------
    -- Assert zero prior sea service:
    SELECT COUNT(*) INTO v_cnt FROM tbl_personnel_sea_service
    WHERE personnel_id IN (v_crew_098_completed_id, v_crew_098_ongoing_id);
    IF v_cnt > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assertion Failed: Contract fixtures must have zero prior sea-service records';
    END IF;

    -- Assert measured newly created crew count equals 8:
    SELECT COUNT(*) INTO v_actual_crew_count
    FROM tbl_personnel_info
    WHERE id IN (
        v_crew_036_before_id, v_crew_036_from_id, v_crew_036_to_id,
        v_crew_036_tolate_id, v_crew_036_after_id, v_crew_036_null_id,
        v_crew_098_completed_id, v_crew_098_ongoing_id
    );
    IF v_actual_crew_count <> 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assertion Failed: Measured newly created crew count does not equal 8';
    END IF;

    -- Assert measured newly created contract count equals 2:
    SELECT COUNT(*) INTO v_actual_contract_count
    FROM tbl_contracts
    WHERE personnel_id IN (v_crew_098_completed_id, v_crew_098_ongoing_id);
    IF v_actual_contract_count <> 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assertion Failed: Measured newly created contract count does not equal 2';
    END IF;

    COMMIT;

    -- --------------------------------------------------------------------------
    -- 9. POST-SETUP EXECUTION SUMMARY (Reports measured counts)
    -- --------------------------------------------------------------------------
    SELECT 'PROVISIONING SUCCESS: QA2FOC Fixtures Created' AS Status,
           'available_from' AS BoundAvailabilityColumn,
           'DATE' AS BoundColumnDataType,
           v_actual_crew_count AS MeasuredCrewCreated,
           v_actual_contract_count AS MeasuredContractsCreated,
           v_ph_today AS CapturedPhilippineEvaluationDate;

END proc_main $$

DELIMITER ;

-- ==============================================================================
-- INVOCATION INSTRUCTIONS (EXECUTE IN WORKBENCH ONLY AFTER PROCEDURE CREATION SUCCEEDS)
-- ==============================================================================
-- 1. Execute the CREATE PROCEDURE block above.
-- 2. Once procedure creation succeeds with zero errors, execute the CALL block below.
-- 3. Never continue after any SQL error.
-- ==============================================================================

CALL sp_setup_qa_c2_focused_tc036_tc098();

-- Drop the helper procedure only after invocation completes successfully
DROP PROCEDURE IF EXISTS sp_setup_qa_c2_focused_tc036_tc098;

-- ==============================================================================
-- READ-ONLY POST-SETUP VERIFICATION SUMMARY
-- Outputs actual personnel IDs, stored availability dates, contract dates,
-- prior sea-service counts (0), session timezone, DB date, and Philippine date.
-- ==============================================================================
SELECT 
    'TC-CM-036 Actual Fixture Output' AS TestScope,
    p.id AS PersonnelID,
    p.lastname AS LastName,
    p.firstname AS FirstName,
    p.available_from AS StoredAvailableFrom,
    p.assigned_vessel_id AS VesselID,
    v.vesselName AS VesselName,
    p.email_address AS Email,
    CASE 
        WHEN p.available_from BETWEEN '2026-09-10' AND '2026-09-20' THEN 'INCLUDED (10-20 Sep)'
        ELSE 'EXCLUDED (10-20 Sep)'
    END AS ExpectedSearchBehavior
FROM tbl_personnel_info p
LEFT JOIN tbl_vessels v ON p.assigned_vessel_id = v.id
WHERE p.lastname LIKE 'QA2FOC_Tc036_%'
ORDER BY p.id;

SELECT 
    'TC-CM-098 Actual Fixture Output' AS TestScope,
    p.id AS PersonnelID,
    CONCAT(p.lastname, ', ', p.firstname) AS CrewMemberName,
    c.id AS ContractID,
    c.date_from AS ContractDateFrom,
    c.date_to AS ContractDateTo,
    c.status AS ContractStatus,
    -- Prior sea service assertion:
    (SELECT COUNT(*) FROM tbl_personnel_sea_service ss WHERE ss.personnel_id = p.id) AS PriorSeaServiceRecords,
    -- Session timezone and dates:
    @@session.time_zone AS WorkbenchSessionTimeZone,
    CURDATE() AS DbSessionDate,
    DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR)) AS PhilippineEvaluationDate,
    -- Service days calculations:
    DATEDIFF(COALESCE(c.date_to, DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))), c.date_from) AS ExpectedRawDaysPHT,
    CONCAT(ROUND(DATEDIFF(COALESCE(c.date_to, DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))), c.date_from) / 365.25, 1), ' yr(s)') AS ExpectedDisplayedTotalPHT,
    CONCAT(ROUND(DATEDIFF(COALESCE(c.date_to, CURDATE()), c.date_from) / 365.25, 1), ' yr(s)') AS ExpectedDisplayedIfDbSessionDate
FROM tbl_personnel_info p
JOIN tbl_contracts c ON c.personnel_id = p.id
WHERE p.lastname LIKE 'QA2FOC_Tc098_%'
ORDER BY p.id;
