-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 BATCH 18 FIXTURE SETUP
-- Target: Azure Staging Environment Only
-- Run Identifier: QA2B18-RUN-20261010
-- Classification: Idempotent Setup with Strict Precondition Gates & Atomic Transaction
--
-- Operational Dates Validated For: October 10, 2026
-- 
-- Safety Rules:
-- 1. All schema, engine, uniqueness, and collision checks execute BEFORE any write.
-- 2. Halts with descriptive SIGNAL SQLSTATE '45000' on any missing or duplicate reference.
-- 3. Zero arbitrary fallback to shared vessels or non-QA records; strict COUNT(*) = 1.
-- 4. Does NOT automatically delete previous QA evidence on rerun; requires clean preflight.
-- 5. Atomic transaction with EXIT HANDLER FOR SQLEXCEPTION performing ROLLBACK and RESIGNAL.
-- 6. Zero hardcoded credentials: user password hash and salt provided via runtime parameters.
--    Matches CryptoHelper PBKDF2 v3 format ($pbkdf2:100000$<Base64-key>).
-- ==============================================================================

USE `ummi_crew`;

-- Clean up temporary procedure definition if a prior aborted execution left it behind
DROP PROCEDURE IF EXISTS sp_setup_qa_c2_batch18;

DELIMITER $$

CREATE PROCEDURE sp_setup_qa_c2_batch18(
    -- Isolated Principal account credentials (CryptoHelper PBKDF2 v3 format)
    IN in_principal_hash VARCHAR(255),
    IN in_principal_salt VARCHAR(64)
)
proc_main: BEGIN
    -- --------------------------------------------------------------------------
    -- 1. LOCAL VARIABLE DECLARATIONS
    -- --------------------------------------------------------------------------
    DECLARE v_cnt INT DEFAULT 0;

    -- Dynamic Reference Identifiers
    DECLARE v_rank_ab_seaman INT;
    DECLARE v_rank_master    INT;
    DECLARE v_rank_3rd_off   INT;
    DECLARE v_vtype_bulk     INT;
    DECLARE v_vtype_container INT;
    DECLARE v_vsl_a_id       INT;
    DECLARE v_vsl_b_id       INT;
    DECLARE v_status_active  INT;
    DECLARE v_status_inactive INT;
    DECLARE v_status_onboard INT;
    DECLARE v_status_vacation INT;
    DECLARE v_status_applicant INT;
    DECLARE v_status_lineup  INT;
    DECLARE v_prov_batangas  INT;
    DECLARE v_prov_manila    INT;
    DECLARE v_city_batangas  INT;
    DECLARE v_city_manila    INT;
    DECLARE v_doc_passport   INT;
    DECLARE v_doc_seaman_book INT;
    DECLARE v_doc_peme       INT;
    DECLARE v_u_staff_id     INT;

    -- Created Row Primary Keys
    DECLARE v_crew_030_match_id INT;
    DECLARE v_crew_030_ctrl_id  INT;
    DECLARE v_crew_031_match_id INT;
    DECLARE v_crew_031_ctrl_id  INT;
    DECLARE v_crew_032_match_id INT;
    DECLARE v_crew_032_ctrl_id  INT;
    DECLARE v_crew_033_match_id INT;
    DECLARE v_crew_033_ctrl_id  INT;
    DECLARE v_crew_034_match_id INT;
    DECLARE v_crew_034_ctrl_id  INT;
    DECLARE v_u_prin_novessels_id INT;
    DECLARE v_crew_050_vslb_id  INT;
    DECLARE v_crew_050_unassigned_id INT;
    DECLARE v_crew_055_lt4m_id  INT;
    DECLARE v_crew_055_exact4m_id INT;
    DECLARE v_crew_055_exact8m_id INT;
    DECLARE v_crew_055_gt8m_id  INT;
    DECLARE v_crew_055_ineligible_id INT;
    DECLARE v_crew_076_blank_id INT;
    DECLARE v_crew_076_zero_id  INT;
    DECLARE v_crew_092_docbound_id INT;
    DECLARE v_app_125_before_id INT;
    DECLARE v_app_125_start_id  INT;
    DECLARE v_app_125_end_id    INT;
    DECLARE v_app_125_after_id  INT;
    DECLARE v_app_134_target_id INT;
    DECLARE v_app_134_ctrl_id   INT;
    DECLARE v_link_152_active_id INT;
    DECLARE v_link_152_used_id   INT;
    DECLARE v_link_152_expired_id INT;
    DECLARE v_ph_today           DATE;

    -- --------------------------------------------------------------------------
    -- 2. EXCEPTION HANDLER: ATOMIC ROLLBACK & RESIGNAL
    -- --------------------------------------------------------------------------
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Initialize Philippine Date (UTC+8) when setup runs
    SET v_ph_today = DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR));

    -- --------------------------------------------------------------------------
    -- 3. CREDENTIAL SAFETY GATE (BEFORE WRITES)
    -- Validates PBKDF2 v3 format: $pbkdf2:100000$<Base64-derived-key>
    -- --------------------------------------------------------------------------
    IF in_principal_hash IS NULL THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash is NULL'; 
    END IF;
    IF in_principal_salt IS NULL THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_salt is NULL'; 
    END IF;
    IF TRIM(in_principal_hash) = '' THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash is blank'; 
    END IF;
    IF TRIM(in_principal_salt) = '' THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_salt is blank'; 
    END IF;
    IF NOT (in_principal_hash LIKE '$pbkdf2:%') THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash must use CryptoHelper PBKDF2 v3 prefix ($pbkdf2:)'; 
    END IF;
    IF LENGTH(TRIM(in_principal_hash)) < 40 OR LENGTH(TRIM(in_principal_hash)) > 255 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash length must be between 40 and 255 characters'; 
    END IF;
    IF LENGTH(TRIM(in_principal_salt)) < 16 OR LENGTH(TRIM(in_principal_salt)) > 64 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_salt length must be between 16 and 64 characters'; 
    END IF;
    IF in_principal_hash LIKE '%placeholder%' OR in_principal_hash LIKE '%changeme%' THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash contains placeholder text'; 
    END IF;
    IF in_principal_salt LIKE '%placeholder%' OR in_principal_salt LIKE '%changeme%' THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_salt contains placeholder text'; 
    END IF;

    -- --------------------------------------------------------------------------
    -- 4. STRICT PRECONDITION VALIDATION: STORAGE ENGINES & COLUMN CAPACITIES
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name IN (
        'tbl_users', 'tbl_personnel_info', 'tbl_personnel_documents',
        'tbl_personnel_sea_service', 'tbl_applicant_generated_link'
      ) AND engine = 'InnoDB';
    IF v_cnt <> 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: All modified target tables must use InnoDB transactional engine';
    END IF;

    -- Verify tbl_users.password can store the actual adaptive PBKDF2 format ($pbkdf2:100000$<key>)
    SELECT COUNT(*) INTO v_cnt FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'tbl_users'
      AND column_name = 'password'
      AND character_maximum_length >= 64;
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: tbl_users.password column must have capacity >= 64 to store PBKDF2 format';
    END IF;

    -- Verify tbl_users.password_salt can store the 256-bit Base64 salt (44 chars)
    SELECT COUNT(*) INTO v_cnt FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'tbl_users'
      AND column_name = 'password_salt'
      AND character_maximum_length >= 44;
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: tbl_users.password_salt column must have capacity >= 44 to store Base64 salt';
    END IF;

    -- --------------------------------------------------------------------------
    -- 5. STRICT PRECONDITION VALIDATION: REFERENCE UNIQUENESS (COUNT(*) = 1 EACH)
    -- --------------------------------------------------------------------------
    -- Vessel Types
    SELECT COUNT(*) INTO v_cnt FROM tbl_type_of_vessel WHERE typeOfVessel = 'Bulk Carrier';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Vessel type Bulk Carrier must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_vtype_bulk FROM tbl_type_of_vessel WHERE typeOfVessel = 'Bulk Carrier';

    SELECT COUNT(*) INTO v_cnt FROM tbl_type_of_vessel WHERE typeOfVessel = 'Container Ship';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Vessel type Container Ship must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_vtype_container FROM tbl_type_of_vessel WHERE typeOfVessel = 'Container Ship';

    -- QA Fleet Vessels & Vessel Type Verification (Strict match, zero fallback to arbitrary vessels)
    SELECT COUNT(*) INTO v_cnt 
    FROM tbl_vessels v
    JOIN tbl_type_of_vessel vt ON v.VesselType = vt.id
    WHERE v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A' AND vt.typeOfVessel = 'Bulk Carrier';
    IF v_cnt <> 1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: QA-C2-RUN-20261001-C2P1-Vessel-A must exist and have vessel type Bulk Carrier'; 
    END IF;
    SELECT id INTO v_vsl_a_id FROM tbl_vessels WHERE vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A';

    SELECT COUNT(*) INTO v_cnt 
    FROM tbl_vessels v
    JOIN tbl_type_of_vessel vt ON v.VesselType = vt.id
    WHERE v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-B' AND vt.typeOfVessel = 'Container Ship';
    IF v_cnt <> 1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: QA-C2-RUN-20261001-C2P1-Vessel-B must exist and have vessel type Container Ship'; 
    END IF;
    SELECT id INTO v_vsl_b_id FROM tbl_vessels WHERE vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-B';

    -- Ranks
    SELECT COUNT(*) INTO v_cnt FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Rank AB SEAMAN (Rating) must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_rank_ab_seaman FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating';

    SELECT COUNT(*) INTO v_cnt FROM tbl_rank WHERE rank_code = 'MASTER' AND rank_type = 'Deck';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Rank MASTER (Deck) must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_rank_master FROM tbl_rank WHERE rank_code = 'MASTER' AND rank_type = 'Deck';

    SELECT COUNT(*) INTO v_cnt FROM tbl_rank WHERE rank_code = '3RD OFFICER' AND rank_type = 'Deck';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Rank 3RD OFFICER (Deck) must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_rank_3rd_off FROM tbl_rank WHERE rank_code = '3RD OFFICER' AND rank_type = 'Deck';

    -- Crew Statuses
    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ACTIVE';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status ACTIVE must have COUNT(*) = 1'; END IF;
    SELECT sequence INTO v_status_active FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ACTIVE';

    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'INACTIVE';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status INACTIVE must have COUNT(*) = 1'; END IF;
    SELECT sequence INTO v_status_inactive FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'INACTIVE';

    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ON BOARD';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status ON BOARD must have COUNT(*) = 1'; END IF;
    SELECT sequence INTO v_status_onboard FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ON BOARD';

    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ON VACATION';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status ON VACATION must have COUNT(*) = 1'; END IF;
    SELECT sequence INTO v_status_vacation FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ON VACATION';

    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'APPLICANT';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status APPLICANT must have COUNT(*) = 1'; END IF;
    SELECT sequence INTO v_status_applicant FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'APPLICANT';

    -- Provinces & Cities
    SELECT COUNT(*) INTO v_cnt FROM tbl_provinces WHERE provinces = 'Batangas';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Province Batangas must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_prov_batangas FROM tbl_provinces WHERE provinces = 'Batangas';

    SELECT COUNT(*) INTO v_cnt FROM tbl_provinces WHERE provinces = 'Metro Manila';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Province Metro Manila must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_prov_manila FROM tbl_provinces WHERE provinces = 'Metro Manila';

    SELECT COUNT(*) INTO v_cnt 
    FROM tbl_cities c
    JOIN tbl_provinces p ON c.province = p.id
    WHERE c.cities = 'Batangas City' AND p.provinces = 'Batangas';
    IF v_cnt <> 1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: City Batangas City must exist and belong to province Batangas'; 
    END IF;
    SELECT id INTO v_city_batangas FROM tbl_cities WHERE cities = 'Batangas City';

    SELECT COUNT(*) INTO v_cnt 
    FROM tbl_cities c
    JOIN tbl_provinces p ON c.province = p.id
    WHERE c.cities = 'Manila' AND p.provinces = 'Metro Manila';
    IF v_cnt <> 1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: City Manila must exist and belong to province Metro Manila'; 
    END IF;
    SELECT id INTO v_city_manila FROM tbl_cities WHERE cities = 'Manila';

    -- Document Definitions
    SELECT COUNT(*) INTO v_cnt FROM tbl_documents WHERE docType = 'Personal' AND documentName = 'Passport';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Document Passport must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_doc_passport FROM tbl_documents WHERE docType = 'Personal' AND documentName = 'Passport';

    SELECT COUNT(*) INTO v_cnt FROM tbl_documents WHERE docType = 'License' AND documentName = 'Seafarer\'s Book (Seaman\'s Book)';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Document Seafarer\'s Book must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_doc_seaman_book FROM tbl_documents WHERE docType = 'License' AND documentName = 'Seafarer\'s Book (Seaman\'s Book)';

    SELECT COUNT(*) INTO v_cnt FROM tbl_documents WHERE docType = 'Medical' AND documentName = 'PEME (Pre-Employment Medical Exam)';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Document PEME must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_doc_peme FROM tbl_documents WHERE docType = 'Medical' AND documentName = 'PEME (Pre-Employment Medical Exam)';

    -- Staff User for Link Generation
    SELECT COUNT(*) INTO v_cnt FROM tbl_users WHERE username = 'qa.c2.20261001.manning.restricted' AND disable_user = 0;
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Staff user qa.c2.20261001.manning.restricted must have COUNT(*) = 1'; END IF;
    SELECT id INTO v_u_staff_id FROM tbl_users WHERE username = 'qa.c2.20261001.manning.restricted';

    -- Baseline Crew A001 Preservation Check
    SELECT COUNT(*) INTO v_cnt FROM tbl_personnel_info WHERE id = 163 AND height = 180.00 AND weight = 72.00;
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Baseline Crew A001 (ID 163, 180cm, 72kg) must exist unchanged'; END IF;

    -- --------------------------------------------------------------------------
    -- 6. STRICT PRECONDITION VALIDATION: COLLISION SAFETY GATE
    -- Does NOT automatically delete previous QA evidence on setup rerun.
    -- If any exact record already exists, signal error to run cleanup script first.
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM tbl_personnel_info
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
    );
    IF v_cnt > 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Batch 18 personnel records already exist. Run batch18-gap-closure-cleanup.sql before re-running setup.'; 
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_personnel_documents
    WHERE document_num IN ('QA2B18-DOC-EXP-MINUS1D', 'QA2B18-DOC-EXP-EXACT3M', 'QA2B18-DOC-EXP-PLUS1D');
    IF v_cnt > 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Batch 18 documents already exist. Run batch18-gap-closure-cleanup.sql before re-running setup.'; 
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_users WHERE username = 'qa2b18.principal.novessels';
    IF v_cnt > 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: User qa2b18.principal.novessels already exists. Run batch18-gap-closure-cleanup.sql before re-running setup.'; 
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_applicant_generated_link 
    WHERE link_token IN (
        'TOK-QA2B18-TC152-ACTIVE-TOKEN',
        'TOK-QA2B18-TC152-USED-TOKEN',
        'TOK-QA2B18-TC152-EXPIRED-TOKEN'
    );
    IF v_cnt > 0 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Batch 18 links already exist. Run batch18-gap-closure-cleanup.sql before re-running setup.'; 
    END IF;

    -- --------------------------------------------------------------------------
    -- 7. ATOMIC TRANSACTION: COMMENCE WRITES ONLY AFTER ALL GATES PASS
    -- --------------------------------------------------------------------------
    START TRANSACTION;

    -- --------------------------------------------------------------------------
    -- TC-CM-030: Search by City (Batangas City vs Manila)
    -- --------------------------------------------------------------------------
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, cadetship, jocap, higher_license, note
    ) VALUES (
        'Maria', 'Clara', 'QA2B18_BatangasMatch', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1992-05-10', 'Batangas', 'Female', 'Single', 'O+',
        165.00, 55.00, NULL, 'qa2b18-tc030-match@example.com', '+63 911 030 0001', '100 Rizal St, Batangas',
        v_prov_batangas, v_city_batangas, v_vsl_a_id, 0, 0, 0, 'TC-CM-030 MATCH: Batangas City'
    );
    SET v_crew_030_match_id = LAST_INSERT_ID();

    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, cadetship, jocap, higher_license, note
    ) VALUES (
        'Carlos', 'Perez', 'QA2B18_ManilaControl', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1993-08-20', 'Manila', 'Male', 'Single', 'A+',
        170.00, 65.00, NULL, 'qa2b18-tc030-ctrl@example.com', '+63 911 030 0002', '200 Mabini St, Manila',
        v_prov_manila, v_city_manila, v_vsl_a_id, 0, 0, 0, 'TC-CM-030 CONTROL: Manila'
    );
    SET v_crew_030_ctrl_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- TC-CM-031: Vessel Type Experience (Bulk Carrier vs Container Ship)
    -- --------------------------------------------------------------------------
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, cadetship, jocap, higher_license, note
    ) VALUES (
        'Pedro', 'Santos', 'QA2B18_BulkMatch', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1991-03-12', 'Manila', 'Male', 'Married', 'B+',
        168.00, 62.00, NULL, 'qa2b18-tc031-match@example.com', '+63 911 031 0001', '300 Bonifacio St, Manila',
        v_prov_manila, v_city_manila, v_vsl_a_id, 0, 0, 0, 'TC-CM-031 MATCH: Bulk Carrier experience'
    );
    SET v_crew_031_match_id = LAST_INSERT_ID();

    INSERT INTO tbl_personnel_sea_service (
        personnel_id, vessel_id, rank_id, date_from, date_to, remarks
    ) VALUES (
        v_crew_031_match_id, v_vsl_a_id, v_rank_ab_seaman, '2024-01-01', '2024-12-31',
        'QA2B18 TC-CM-031 Bulk Carrier sea time'
    );

    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, cadetship, jocap, higher_license, note
    ) VALUES (
        'Roberto', 'Gomez', 'QA2B18_ContainerControl', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1990-11-25', 'Manila', 'Male', 'Single', 'O+',
        172.00, 68.00, NULL, 'qa2b18-tc031-ctrl@example.com', '+63 911 031 0002', '400 Luna St, Manila',
        v_prov_manila, v_city_manila, v_vsl_a_id, 0, 0, 0, 'TC-CM-031 CONTROL: Container Ship experience'
    );
    SET v_crew_031_ctrl_id = LAST_INSERT_ID();

    INSERT INTO tbl_personnel_sea_service (
        personnel_id, vessel_id, rank_id, date_from, date_to, remarks
    ) VALUES (
        v_crew_031_ctrl_id, v_vsl_b_id, v_rank_ab_seaman, '2024-01-01', '2024-12-31',
        'QA2B18 TC-CM-031 Container Ship sea time'
    );

    -- --------------------------------------------------------------------------
    -- TC-CM-032: Cadetship (Selected=1 vs Cleared=0)
    -- --------------------------------------------------------------------------
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, cadetship, jocap, higher_license, note
    ) VALUES (
        'Juan', 'Luna', 'QA2B18_CadetshipMatch', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1995-04-10', 'Manila', 'Male', 'Single', 'A+',
        175.00, 70.00, NULL, 'qa2b18-tc032-match@example.com', '+63 911 032 0001', '500 Burgos St, Manila',
        v_prov_manila, v_city_manila, v_vsl_a_id, 1, 0, 0, 'TC-CM-032 MATCH: Cadetship=1'
    );
    SET v_crew_032_match_id = LAST_INSERT_ID();

    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, cadetship, jocap, higher_license, note
    ) VALUES (
        'Ramon', 'Valdez', 'QA2B18_CadetshipControl', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1994-07-18', 'Manila', 'Male', 'Single', 'B+',
        173.00, 67.00, NULL, 'qa2b18-tc032-ctrl@example.com', '+63 911 032 0002', '502 Burgos St, Manila',
        v_prov_manila, v_city_manila, v_vsl_a_id, 0, 0, 0, 'TC-CM-032 CONTROL: Cadetship=0'
    );
    SET v_crew_032_ctrl_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- TC-CM-033: JOCAP (Selected=1 vs Cleared=0)
    -- --------------------------------------------------------------------------
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, cadetship, jocap, higher_license, note
    ) VALUES (
        'Diego', 'Silang', 'QA2B18_JocapMatch', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1993-02-14', 'Manila', 'Male', 'Single', 'O+',
        169.00, 64.00, NULL, 'qa2b18-tc033-match@example.com', '+63 911 033 0001', '600 Del Pilar St, Manila',
        v_prov_manila, v_city_manila, v_vsl_a_id, 0, 1, 0, 'TC-CM-033 MATCH: JOCAP=1'
    );
    SET v_crew_033_match_id = LAST_INSERT_ID();

    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, cadetship, jocap, higher_license, note
    ) VALUES (
        'Marco', 'Aquino', 'QA2B18_JocapControl', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1992-09-09', 'Manila', 'Male', 'Single', 'AB+',
        171.00, 66.00, NULL, 'qa2b18-tc033-ctrl@example.com', '+63 911 033 0002', '602 Del Pilar St, Manila',
        v_prov_manila, v_city_manila, v_vsl_a_id, 0, 0, 0, 'TC-CM-033 CONTROL: JOCAP=0'
    );
    SET v_crew_033_ctrl_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- TC-CM-034: Higher License (Selected=1 vs Cleared=0)
    -- --------------------------------------------------------------------------
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, cadetship, jocap, higher_license, note
    ) VALUES (
        'Antonio', 'Luna', 'QA2B18_HigherLicMatch', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1989-10-29', 'Manila', 'Male', 'Married', 'A+',
        174.00, 71.00, NULL, 'qa2b18-tc034-match@example.com', '+63 911 034 0001', '700 Kalaw St, Manila',
        v_prov_manila, v_city_manila, v_vsl_a_id, 0, 0, 1, 'TC-CM-034 MATCH: Higher License=1'
    );
    SET v_crew_034_match_id = LAST_INSERT_ID();

    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, cadetship, jocap, higher_license, note
    ) VALUES (
        'Mateo', 'Roxas', 'QA2B18_HigherLicControl', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1988-12-15', 'Manila', 'Male', 'Single', 'O+',
        170.00, 68.00, NULL, 'qa2b18-tc034-ctrl@example.com', '+63 911 034 0002', '702 Kalaw St, Manila',
        v_prov_manila, v_city_manila, v_vsl_a_id, 0, 0, 0, 'TC-CM-034 CONTROL: Higher License=0'
    );
    SET v_crew_034_ctrl_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- TC-CM-046: Principal Account with ZERO Vessel Assignments
    -- Credential hash & salt supplied via runtime parameters in_principal_hash / in_principal_salt
    -- --------------------------------------------------------------------------
    INSERT INTO tbl_users (
        username, password, password_salt, fullname, type, management,
        email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
    ) VALUES (
        'qa2b18.principal.novessels', in_principal_hash, in_principal_salt,
        'QA2B18 Principal Zero Vessels', 'PRINCIPAL', 1,
        'qa2b18-tc046-principal@example.com', 0, 0, 0, 0
    );
    SET v_u_prin_novessels_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- TC-CM-050: Vessel Grouping & Complete Displayed Fields Populated
    -- Photo resolution: picture_id = NULL with gender = 'Male' renders
    -- ~/images/silhouette_user.png which is confirmed 200 OK on Azure staging.
    -- --------------------------------------------------------------------------
    -- Vessel B Assigned Crew (On Board, Master)
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Andres', 'Bonifacio', 'QA2B18_VesselBCrew', v_rank_master, 'Regular', v_status_onboard, 0,
        '2026-08-10', '2023-05-01', '1985-11-30', 'Manila', 'Male', 'Married', 'AB+',
        175.00, 75.00, NULL, 'qa2b18-tc050-vslb@example.com', '+63 911 050 0001',
        '800 Tondo St, Manila', v_prov_manila, v_city_manila, v_vsl_b_id,
        'TC-CM-050: Vessel B Assigned Master with complete displayed fields'
    );
    SET v_crew_050_vslb_id = LAST_INSERT_ID();

    INSERT INTO tbl_personnel_sea_service (
        personnel_id, vessel_id, rank_id, date_from, date_to, remarks
    ) VALUES (
        v_crew_050_vslb_id, v_vsl_b_id, v_rank_master, '2024-01-01', '2025-01-01',
        'QA2B18 TC-CM-050 Vessel B prior sea time'
    );

    -- Unassigned Active Crew (Active, 3rd Officer, assigned_vessel_id = NULL)
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Lucas', 'Perez', 'QA2B18_UnassignedCrew', v_rank_3rd_off, 'Regular', v_status_active, 1,
        '2026-09-15', '2024-03-01', '1992-06-15', 'Manila', 'Male', 'Single', 'B+',
        171.00, 68.00, NULL, 'qa2b18-tc050-unassigned@example.com', '+63 911 050 0002',
        '802 Ermita St, Manila', v_prov_manila, v_city_manila, NULL,
        'TC-CM-050: Unassigned 3rd Officer with complete displayed fields'
    );
    SET v_crew_050_unassigned_id = LAST_INSERT_ID();

    INSERT INTO tbl_personnel_sea_service (
        personnel_id, vessel_id, rank_id, date_from, date_to, remarks
    ) VALUES (
        v_crew_050_unassigned_id, v_vsl_a_id, v_rank_3rd_off, '2024-03-01', '2025-03-01',
        'QA2B18 TC-CM-050 Unassigned prior sea time'
    );

    -- --------------------------------------------------------------------------
    -- TC-CM-055: Availability / Status Elapsed Months Warning Boundaries
    -- Evaluated against Philippine date when setup runs (v_ph_today)
    -- Formula: (DateTime.Now.Year - sd.Year)*12 + DateTime.Now.Month - sd.Month
    -- Eligible statuses: Active (1), Inactive (2), On Vacation (4)
    -- --------------------------------------------------------------------------
    -- < 4 calendar months (3 months elapsed) -> Normal unhighlighted
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Felix', 'Resurreccion', 'QA2B18_StatusLt4m', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        DATE_SUB(v_ph_today, INTERVAL 3 MONTH), '2025-01-15', '1993-01-10', 'Manila', 'Male', 'Single', 'O+',
        170.00, 65.00, NULL, 'qa2b18-tc055-lt4m@example.com', '+63 911 055 0001',
        '901 Status Way, Manila', v_prov_manila, v_city_manila, v_vsl_a_id,
        'TC-CM-055: Status date 3 months elapsed (Normal uncolored)'
    );
    SET v_crew_055_lt4m_id = LAST_INSERT_ID();

    -- Exactly 4 calendar months (4 months elapsed) -> status-date-amber
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Graciano', 'Lopez', 'QA2B18_StatusExact4m', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        DATE_SUB(v_ph_today, INTERVAL 4 MONTH), '2025-01-15', '1992-02-15', 'Manila', 'Male', 'Single', 'A+',
        172.00, 67.00, NULL, 'qa2b18-tc055-exact4m@example.com', '+63 911 055 0002',
        '902 Status Way, Manila', v_prov_manila, v_city_manila, v_vsl_a_id,
        'TC-CM-055: Status date exactly 4 months elapsed (status-date-amber)'
    );
    SET v_crew_055_exact4m_id = LAST_INSERT_ID();

    -- Exactly 8 calendar months (8 months elapsed) -> status-date-amber
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Mariano', 'Ponce', 'QA2B18_StatusExact8m', v_rank_ab_seaman, 'Regular', v_status_vacation, 1,
        DATE_SUB(v_ph_today, INTERVAL 8 MONTH), '2025-01-15', '1991-03-20', 'Manila', 'Male', 'Married', 'B+',
        168.00, 63.00, NULL, 'qa2b18-tc055-exact8m@example.com', '+63 911 055 0003',
        '903 Status Way, Manila', v_prov_manila, v_city_manila, v_vsl_a_id,
        'TC-CM-055: Status date exactly 8 months elapsed (status-date-amber)'
    );
    SET v_crew_055_exact8m_id = LAST_INSERT_ID();

    -- > 8 calendar months (9 months elapsed) -> status-date-red
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Melchora', 'Aquino', 'QA2B18_StatusGt8m', v_rank_ab_seaman, 'Regular', v_status_inactive, 0,
        DATE_SUB(v_ph_today, INTERVAL 9 MONTH), '2025-01-15', '1990-04-25', 'Manila', 'Female', 'Single', 'O+',
        163.00, 58.00, NULL, 'qa2b18-tc055-gt8m@example.com', '+63 911 055 0004',
        '904 Status Way, Manila', v_prov_manila, v_city_manila, v_vsl_a_id,
        'TC-CM-055: Status date 9 months elapsed (status-date-red)'
    );
    SET v_crew_055_gt8m_id = LAST_INSERT_ID();

    -- Ineligible status control (Status ON BOARD = 3, status_date 9 months elapsed)
    -- Must remain unhighlighted because status is On Board
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Gregorio', 'del Pilar', 'QA2B18_StatusIneligible', v_rank_ab_seaman, 'Regular', v_status_onboard, 0,
        DATE_SUB(v_ph_today, INTERVAL 9 MONTH), '2025-01-15', '1994-11-14', 'Manila', 'Male', 'Single', 'A+',
        169.00, 64.00, NULL, 'qa2b18-tc055-ineligible@example.com', '+63 911 055 0005',
        '905 Status Way, Manila', v_prov_manila, v_city_manila, v_vsl_a_id,
        'TC-CM-055: Status date 9 mos but ON BOARD (Normal uncolored)'
    );
    SET v_crew_055_ineligible_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- TC-CM-076: BMI Calculation Controls (Blank and Zero Biometrics)
    -- A001 (180 cm, 72 kg, ID 163) displays 22.2 Normal.
    -- Controls verify suppression without arithmetic exceptions.
    -- --------------------------------------------------------------------------
    -- Control 1: NULL Height and NULL Weight
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Teresa', 'Magbanua', 'QA2B18_BmiBlank', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1993-10-13', 'Manila', 'Female', 'Single', 'O+',
        NULL, NULL, NULL, 'qa2b18-tc076-blank@example.com', '+63 911 076 0001',
        '1001 Bio Way, Manila', v_prov_manila, v_city_manila, v_vsl_a_id,
        'TC-CM-076: Blank Biometrics (Height=NULL, Weight=NULL)'
    );
    SET v_crew_076_blank_id = LAST_INSERT_ID();

    -- Control 2: Zero Height (0.00) and Zero Weight (0.00)
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Gabriela', 'Silang', 'QA2B18_BmiZero', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        '2026-09-01', '2025-01-15', '1992-03-19', 'Manila', 'Female', 'Married', 'A+',
        0.00, 0.00, NULL, 'qa2b18-tc076-zero@example.com', '+63 911 076 0002',
        '1002 Bio Way, Manila', v_prov_manila, v_city_manila, v_vsl_a_id,
        'TC-CM-076: Zero Biometrics (Height=0, Weight=0)'
    );
    SET v_crew_076_zero_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- TC-CM-092: Document Expiry 3-Month Boundaries
    -- Evaluated against Philippine date when setup runs (v_ph_today)
    -- Warning formula in deployed app: Date.Now.AddMonths(3) >= expiryDate
    -- img_id left NULL (scanned image viewer is not evaluated in expiry test)
    -- --------------------------------------------------------------------------
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Vicente', 'Enriquez', 'QA2B18_DocBoundCrew', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        DATE_SUB(v_ph_today, INTERVAL 1 MONTH), '2025-01-15', '1991-08-05', 'Manila', 'Male', 'Single', 'B+',
        173.00, 68.00, NULL, 'qa2b18-tc092-docbound@example.com', '+63 911 092 0001',
        '1100 Doc Way, Manila', v_prov_manila, v_city_manila, v_vsl_a_id,
        'TC-CM-092: Crew profile for Document Expiry 3m boundaries'
    );
    SET v_crew_092_docbound_id = LAST_INSERT_ID();

    -- Boundary -1 day: Date.Now.AddMonths(3) - 1 day (Date.Now.AddMonths(3) >= expiryDate is TRUE -> DarkRed)
    INSERT INTO tbl_personnel_documents (
        personnel_id, document_id, document_num, date_issued, date_expiry, grade, img_id
    ) VALUES (
        v_crew_092_docbound_id, v_doc_seaman_book, 'QA2B18-DOC-EXP-MINUS1D',
        DATE_SUB(v_ph_today, INTERVAL 5 YEAR), DATE_SUB(DATE_ADD(v_ph_today, INTERVAL 3 MONTH), INTERVAL 1 DAY), 'A', NULL
    );

    -- Boundary exact day: Date.Now.AddMonths(3) (Date.Now.AddMonths(3) >= expiryDate is TRUE -> DarkRed)
    INSERT INTO tbl_personnel_documents (
        personnel_id, document_id, document_num, date_issued, date_expiry, grade, img_id
    ) VALUES (
        v_crew_092_docbound_id, v_doc_passport, 'QA2B18-DOC-EXP-EXACT3M',
        DATE_SUB(v_ph_today, INTERVAL 5 YEAR), DATE_ADD(v_ph_today, INTERVAL 3 MONTH), 'A', NULL
    );

    -- Boundary +1 day: Date.Now.AddMonths(3) + 1 day (Date.Now.AddMonths(3) >= expiryDate is FALSE -> Normal)
    INSERT INTO tbl_personnel_documents (
        personnel_id, document_id, document_num, date_issued, date_expiry, grade, img_id
    ) VALUES (
        v_crew_092_docbound_id, v_doc_peme, 'QA2B18-DOC-EXP-PLUS1D',
        DATE_SUB(v_ph_today, INTERVAL 1 YEAR), DATE_ADD(DATE_ADD(v_ph_today, INTERVAL 3 MONTH), INTERVAL 1 DAY), 'FIT', NULL
    );

    -- --------------------------------------------------------------------------
    -- TC-CM-125: Applicant Search Date Boundaries (10-20 Sep 2026)
    -- Defect Isolation: Application registration date is stored in date_added,
    -- but deployed spApplicantPoolSearchDisplay checks date_hired.
    -- date_added is set to the September 10-20 test boundary window, while
    -- date_hired is deliberately placed in August (2026-08-01..04) so QA can
    -- prove definitively whether the search queries date_added or date_hired.
    -- --------------------------------------------------------------------------
    -- 125.1: Before range (date_added = 2026-09-09, date_hired = 2026-08-01) -> Excluded
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_added, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Basilio', 'Sison', 'QA2B18_AppBeforeRange', v_rank_ab_seaman, 'Applicant', v_status_applicant, 1,
        '2026-09-09', '2026-08-01', '2026-09-09 10:00:00', '1996-01-05', 'Manila', 'Male', 'Single', 'O+',
        170.00, 65.00, NULL, 'qa2b18-tc125-before@example.com', '+63 911 125 0001',
        '1201 App Way, Manila', v_prov_manila, v_city_manila, NULL,
        'TC-CM-125: date_added=2026-09-09 (Before Range), date_hired=2026-08-01'
    );
    SET v_app_125_before_id = LAST_INSERT_ID();

    -- 125.2: Start boundary (date_added = 2026-09-10, date_hired = 2026-08-02) -> Included under date_added
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_added, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Crispin', 'Sison', 'QA2B18_AppStartBound', v_rank_ab_seaman, 'Applicant', v_status_applicant, 1,
        '2026-09-10', '2026-08-02', '2026-09-10 10:00:00', '1997-02-10', 'Manila', 'Male', 'Single', 'A+',
        168.00, 63.00, NULL, 'qa2b18-tc125-start@example.com', '+63 911 125 0002',
        '1202 App Way, Manila', v_prov_manila, v_city_manila, NULL,
        'TC-CM-125: date_added=2026-09-10 (Start Bound), date_hired=2026-08-02'
    );
    SET v_app_125_start_id = LAST_INSERT_ID();

    -- 125.3: End boundary (date_added = 2026-09-20, date_hired = 2026-08-03) -> Included under date_added
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_added, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Elias', 'Alvarez', 'QA2B18_AppEndBound', v_rank_ab_seaman, 'Applicant', v_status_applicant, 1,
        '2026-09-20', '2026-08-03', '2026-09-20 10:00:00', '1995-03-15', 'Manila', 'Male', 'Single', 'B+',
        172.00, 66.00, NULL, 'qa2b18-tc125-end@example.com', '+63 911 125 0003',
        '1203 App Way, Manila', v_prov_manila, v_city_manila, NULL,
        'TC-CM-125: date_added=2026-09-20 (End Bound), date_hired=2026-08-03'
    );
    SET v_app_125_end_id = LAST_INSERT_ID();

    -- 125.4: After range (date_added = 2026-09-21, date_hired = 2026-08-04) -> Excluded
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_added, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Salome', 'Santos', 'QA2B18_AppAfterRange', v_rank_ab_seaman, 'Applicant', v_status_applicant, 1,
        '2026-09-21', '2026-08-04', '2026-09-21 10:00:00', '1994-04-20', 'Manila', 'Female', 'Single', 'O+',
        164.00, 56.00, NULL, 'qa2b18-tc125-after@example.com', '+63 911 125 0004',
        '1204 App Way, Manila', v_prov_manila, v_city_manila, NULL,
        'TC-CM-125: date_added=2026-09-21 (After Range), date_hired=2026-08-04'
    );
    SET v_app_125_after_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- TC-CM-134: Hire Applicant (Target vs Control)
    -- --------------------------------------------------------------------------
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_added, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Danilo', 'Magtanggol', 'QA2B18_HireTarget', v_rank_ab_seaman, 'Applicant', v_status_applicant, 1,
        '2026-09-25', '2026-09-25', '2026-09-25 10:00:00', '1995-07-07', 'Manila', 'Male', 'Single', 'A+',
        170.00, 66.00, NULL, 'qa2b18-tc134-target@example.com', '+63 911 134 0001',
        '1301 Hire Way, Manila', v_prov_manila, v_city_manila, NULL,
        'TC-CM-134 TARGET: Applicant to be hired (transitions from 5 to 1)'
    );
    SET v_app_134_target_id = LAST_INSERT_ID();

    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_added, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Eduardo', 'Tinio', 'QA2B18_HireControl', v_rank_ab_seaman, 'Applicant', v_status_applicant, 1,
        '2026-09-25', '2026-09-25', '2026-09-25 10:00:00', '1996-08-08', 'Manila', 'Male', 'Single', 'B+',
        172.00, 68.00, NULL, 'qa2b18-tc134-ctrl@example.com', '+63 911 134 0002',
        '1302 Hire Way, Manila', v_prov_manila, v_city_manila, NULL,
        'TC-CM-134 CONTROL: Untouched applicant (remains status 5)'
    );
    SET v_app_134_ctrl_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- TC-CM-152: Controlled Active, Used, and Expired Links
    -- Provides isolated records to test lifecycle transitions (Active -> Expired)
    -- and verify terminal state immutability (Used and Expired cannot transition back)
    -- without relying on shared demo or legacy staging links.
    -- --------------------------------------------------------------------------
    -- 152.1: Controlled Active link for transition to Expired
    INSERT INTO tbl_applicant_generated_link (
        fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
    ) VALUES (
        'QA2B18_LinkActive', 'qa2b18-tc152-active@example.com', 'Able Seaman',
        DATE_ADD(UTC_TIMESTAMP(), INTERVAL 14 DAY), 'Active', UTC_TIMESTAMP(), NULL,
        v_u_staff_id, 'TOK-QA2B18-TC152-ACTIVE-TOKEN'
    );
    SET v_link_152_active_id = LAST_INSERT_ID();

    -- 152.2: Controlled Used link (Terminal state: no status-change dropdown rendered)
    INSERT INTO tbl_applicant_generated_link (
        fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
    ) VALUES (
        'QA2B18_LinkUsed', 'qa2b18-tc152-used@example.com', 'Able Seaman',
        DATE_ADD(UTC_TIMESTAMP(), INTERVAL 7 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 HOUR),
        UTC_TIMESTAMP(), v_u_staff_id, 'TOK-QA2B18-TC152-USED-TOKEN'
    );
    SET v_link_152_used_id = LAST_INSERT_ID();

    -- 152.3: Controlled Expired link (Terminal state: no status-change dropdown rendered)
    INSERT INTO tbl_applicant_generated_link (
        fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
    ) VALUES (
        'QA2B18_LinkExpired', 'qa2b18-tc152-expired@example.com', 'Able Seaman',
        DATE_SUB(UTC_TIMESTAMP(), INTERVAL 7 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 14 DAY),
        NULL, v_u_staff_id, 'TOK-QA2B18-TC152-EXPIRED-TOKEN'
    );
    SET v_link_152_expired_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- 8. COMMIT TRANSACTION
    -- --------------------------------------------------------------------------
    COMMIT;
END proc_main$$

DELIMITER ;

-- ------------------------------------------------------------------------------
-- EXECUTE FIXTURE SETUP PROCEDURE
-- Pass staging principal account hash and salt via untracked session variables.
-- Example execution in MySQL Workbench:
--   SET @QA2B18_PRINCIPAL_HASH = '$pbkdf2:100000$<Base64-derived-key>';
--   SET @QA2B18_PRINCIPAL_SALT = '<Base64-salt-string>';
--   CALL sp_setup_qa_c2_batch18(@QA2B18_PRINCIPAL_HASH, @QA2B18_PRINCIPAL_SALT);
-- ------------------------------------------------------------------------------
CALL sp_setup_qa_c2_batch18(@QA2B18_PRINCIPAL_HASH, @QA2B18_PRINCIPAL_SALT);

-- Drop procedure definition upon successful execution
DROP PROCEDURE IF EXISTS sp_setup_qa_c2_batch18;

-- ==============================================================================
-- POST-SETUP VERIFICATION SUMMARY
-- ==============================================================================
SELECT 'POST-SETUP AUDIT: QA2B18 Personnel' AS Summary, id, lastname, firstname, crew_status, status_date, date_hired, date_added
FROM tbl_personnel_info
WHERE email_address LIKE 'qa2b18-%@example.com'
ORDER BY id;

SELECT 'POST-SETUP AUDIT: QA2B18 Sea Service' AS Summary, ss.id, ss.personnel_id, ss.vessel_id, ss.remarks
FROM tbl_personnel_sea_service ss
JOIN tbl_personnel_info p ON ss.personnel_id = p.id
WHERE p.email_address LIKE 'qa2b18-%@example.com';

SELECT 'POST-SETUP AUDIT: QA2B18 Documents' AS Summary, d.id, d.personnel_id, d.document_num, d.date_expiry, d.img_id
FROM tbl_personnel_documents d
JOIN tbl_personnel_info p ON d.personnel_id = p.id
WHERE p.email_address LIKE 'qa2b18-%@example.com';

SELECT 'POST-SETUP AUDIT: QA2B18 Links' AS Summary, id, fullname, email, status, validity, link_token
FROM tbl_applicant_generated_link
WHERE link_token LIKE 'TOK-QA2B18-TC152-%';

SELECT 'POST-SETUP AUDIT: QA2B18 User' AS Summary, id, username, type, disable_user
FROM tbl_users
WHERE username = 'qa2b18.principal.novessels';
