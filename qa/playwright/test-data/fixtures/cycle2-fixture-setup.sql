-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 PHASE 1 FIXTURE SETUP
-- Target: Azure Staging Environment Only
-- Run Identifier: QA-C2-RUN-20261001-C2P1
-- Classification: Idempotent Setup with Runtime Reference Resolution & Dynamic Dates
-- 
-- Safety Rules:
-- 1. Idempotent: Can be safely re-run without duplicate key errors.
-- 2. Foreign-Key Safe: Inserts in strict parent -> child dependency order.
-- 3. Dynamic Reference Resolution: Resolves Ranks, Document IDs, Vessel Types from DB.
-- 4. Dynamic Operational Dates: Calculates UTC relative dates dynamically.
-- 5. Exact Isolation: All records tagged with exact run identifier QA-C2-RUN-20261001-C2P1.
-- 6. No Broad Purging: Cleanup conditions target ONLY exact keys of this run.
-- 7. Zero Hardcoded Credentials: All credential values supplied only at runtime via
--    untracked local mechanism. No shared hash/salt pair is used across accounts.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. RUNTIME CONFIGURATION
-- Credential session variables (@QA_MANNING_HASH, @QA_MANNING_SALT, etc.) must be
-- set by the local untracked runner (run-fixture-setup.ps1) before executing this
-- script. The procedure will SIGNAL if any value is missing, blank, or placeholder.
-- ------------------------------------------------------------------------------
SET @RUN_ID = 'QA-C2-RUN-20261001-C2P1';

-- Clean up procedure definition if a previous failed execution left it behind
DROP PROCEDURE IF EXISTS sp_setup_qa_c2_run_20261001_c2p1;

DELIMITER $$

CREATE PROCEDURE sp_setup_qa_c2_run_20261001_c2p1(
    -- Restricted Manning account credentials
    IN in_manning_hash VARCHAR(64),
    IN in_manning_salt VARCHAR(64),
    -- Isolated Principal account credentials
    IN in_principal_hash VARCHAR(64),
    IN in_principal_salt VARCHAR(64),
    -- Isolated Vessel Owner account credentials
    IN in_owner_hash   VARCHAR(64),
    IN in_owner_salt   VARCHAR(64)
)
proc_main: BEGIN
    -- --------------------------------------------------------------------------
    -- 1. LOCAL VARIABLE DECLARATIONS
    -- --------------------------------------------------------------------------
    DECLARE v_cnt INT DEFAULT 0;

    -- --------------------------------------------------------------------------
    -- 2. EXCEPTION HANDLER: ATOMIC ROLLBACK & RESIGNAL
    -- Any SQLEXCEPTION triggers an immediate ROLLBACK and passes the error outward.
    -- --------------------------------------------------------------------------
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- --------------------------------------------------------------------------
    -- CREDENTIAL SAFETY GATE (BEFORE START TRANSACTION)
    -- Validates all six per-account credential parameters before any persistent
    -- write is attempted. This is a temporary staging compatibility mechanism
    -- for the QA synthetic accounts; it does not indicate compliance with
    -- SR-04 or TC-CM-186.
    --
    -- Hash format expected by the deployed login code (login.aspx.vb / CryptoHelper.vb):
    --   SHA256( UTF8Bytes(plaintext_password + salt_string) ) -> lowercase hex, 64 chars
    --   Salt: 32 random bytes -> Base64 string (44 chars incl. padding)
    -- --------------------------------------------------------------------------

    -- NULL check
    IF in_manning_hash   IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_hash is NULL'; END IF;
    IF in_manning_salt   IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_salt is NULL'; END IF;
    IF in_principal_hash IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash is NULL'; END IF;
    IF in_principal_salt IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_salt is NULL'; END IF;
    IF in_owner_hash     IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_owner_hash is NULL'; END IF;
    IF in_owner_salt     IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_owner_salt is NULL'; END IF;

    -- Blank / whitespace check
    IF TRIM(in_manning_hash)   = '' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_hash is blank or whitespace'; END IF;
    IF TRIM(in_manning_salt)   = '' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_salt is blank or whitespace'; END IF;
    IF TRIM(in_principal_hash) = '' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash is blank or whitespace'; END IF;
    IF TRIM(in_principal_salt) = '' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_salt is blank or whitespace'; END IF;
    IF TRIM(in_owner_hash)     = '' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_owner_hash is blank or whitespace'; END IF;
    IF TRIM(in_owner_salt)     = '' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_owner_salt is blank or whitespace'; END IF;

    -- Placeholder / unchanged value check (hash: SHA256 of empty string; salt: legacy placeholder pattern)
    IF in_manning_hash   = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_hash is unchanged placeholder (empty-string SHA256)'; END IF;
    IF in_principal_hash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash is unchanged placeholder (empty-string SHA256)'; END IF;
    IF in_owner_hash     = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_owner_hash is unchanged placeholder (empty-string SHA256)'; END IF;
    IF in_manning_salt   LIKE '%C2P1Salt%' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_salt is unchanged placeholder'; END IF;
    IF in_principal_salt LIKE '%C2P1Salt%' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_salt is unchanged placeholder'; END IF;
    IF in_owner_salt     LIKE '%C2P1Salt%' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_owner_salt is unchanged placeholder'; END IF;
    IF in_manning_hash   LIKE '%placeholder%' OR in_manning_hash   LIKE '%changeme%' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_hash contains placeholder text'; END IF;
    IF in_principal_hash LIKE '%placeholder%' OR in_principal_hash LIKE '%changeme%' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash contains placeholder text'; END IF;
    IF in_owner_hash     LIKE '%placeholder%' OR in_owner_hash     LIKE '%changeme%' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_owner_hash contains placeholder text'; END IF;
    IF in_manning_salt   LIKE '%placeholder%' OR in_manning_salt   LIKE '%changeme%' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_salt contains placeholder text'; END IF;
    IF in_principal_salt LIKE '%placeholder%' OR in_principal_salt LIKE '%changeme%' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_salt contains placeholder text'; END IF;
    IF in_owner_salt     LIKE '%placeholder%' OR in_owner_salt     LIKE '%changeme%' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_owner_salt contains placeholder text'; END IF;

    -- Hash length check: SHA-256 lowercase hex must be exactly 64 characters
    IF LENGTH(TRIM(in_manning_hash))   <> 64 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_hash must be 64 hex characters'; END IF;
    IF LENGTH(TRIM(in_principal_hash)) <> 64 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash must be 64 hex characters'; END IF;
    IF LENGTH(TRIM(in_owner_hash))     <> 64 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_owner_hash must be 64 hex characters'; END IF;

    -- Distinct salts: all three salts must be different
    IF in_manning_salt = in_principal_salt THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_salt and in_principal_salt must be distinct'; END IF;
    IF in_manning_salt = in_owner_salt     THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_salt and in_owner_salt must be distinct'; END IF;
    IF in_principal_salt = in_owner_salt   THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_salt and in_owner_salt must be distinct'; END IF;

    -- Distinct hashes: all three hashes must be different (passwords must not collide)
    IF in_manning_hash = in_principal_hash THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_hash and in_principal_hash must be distinct'; END IF;
    IF in_manning_hash = in_owner_hash     THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_manning_hash and in_owner_hash must be distinct'; END IF;
    IF in_principal_hash = in_owner_hash   THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Credential gate: in_principal_hash and in_owner_hash must be distinct'; END IF;

    -- --------------------------------------------------------------------------
    -- 3. STRICT PRECONDITION VALIDATION (BEFORE TRANSACTION)
    -- Signal SQLSTATE '45000' with descriptive message if any count <> 1.
    -- Zero persistent writes can occur if any precondition fails.
    -- --------------------------------------------------------------------------

    -- Target Table Storage Engines: Verify all 11 modified tables use InnoDB
    SELECT COUNT(*) INTO v_cnt FROM information_schema.tables 
    WHERE table_schema = DATABASE() 
      AND table_name IN (
        'tbl_principals', 'tbl_vessels', 'tbl_users', 'tbl_user_assigned_vessel',
        'tbl_personnel_info', 'tbl_personnel_documents', 'tbl_personnel_comment',
        'tbl_personnel_family_info', 'tbl_applicant_generated_link', 
        'tbl_ccl_relievers', 'tbl_ccl_schedules'
      ) AND engine = 'InnoDB';
    IF v_cnt <> 11 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: All 11 target tables modified by setup must use InnoDB transactional engine';
    END IF;

    -- Vessel Types Uniqueness Checks
    SELECT COUNT(*) INTO v_cnt FROM tbl_type_of_vessel WHERE typeOfVessel = 'Bulk Carrier';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Vessel type Bulk Carrier must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_type_of_vessel WHERE typeOfVessel = 'Container Ship';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Vessel type Container Ship must have COUNT(*) = 1';
    END IF;

    -- Ranks Uniqueness Checks
    SELECT COUNT(*) INTO v_cnt FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Rank AB SEAMAN (Rating) must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_rank WHERE rank_code = 'BOSUN' AND rank_type = 'Rating';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Rank BOSUN (Rating) must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_rank WHERE rank_code = 'CHIEF COOK' AND rank_type = 'Catering';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Rank CHIEF COOK (Catering) must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_rank WHERE rank_code = '4TH ENGINEER' AND rank_type = 'Engine';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Rank 4TH ENGINEER (Engine) must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_rank WHERE rank_code = 'MASTER' AND rank_type = 'Deck';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Rank MASTER (Deck) must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_rank WHERE rank_code = '3RD OFFICER' AND rank_type = 'Deck';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Rank 3RD OFFICER (Deck) must have COUNT(*) = 1';
    END IF;

    -- Document Definitions Uniqueness Checks
    SELECT COUNT(*) INTO v_cnt FROM tbl_documents WHERE docType = 'License' AND documentName = 'Seafarer\'s Book (Seaman\'s Book)';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Document Seafarer\'s Book (License) must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_documents WHERE docType = 'Medical' AND documentName = 'PEME (Pre-Employment Medical Exam)';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Document PEME (Medical) must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_documents WHERE docType = 'Personal' AND documentName = 'Passport';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Document Passport (Personal) must have COUNT(*) = 1';
    END IF;

    -- Individual Crew Status Codes Uniqueness Checks (Strict COUNT(*) = 1 each)
    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ACTIVE';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status ACTIVE must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'INACTIVE';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status INACTIVE must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ON BOARD';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status ON BOARD must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ON VACATION';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status ON VACATION must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'APPLICANT';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status APPLICANT must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'LINE UP';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: Crew status LINE UP must have COUNT(*) = 1';
    END IF;

    -- User Roles Uniqueness Checks
    SELECT COUNT(*) INTO v_cnt FROM tbl_user_type WHERE user_type = 'MANNING_STAFF';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: User type MANNING_STAFF must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_user_type WHERE user_type = 'PRINCIPAL';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: User type PRINCIPAL must have COUNT(*) = 1';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_user_type WHERE user_type = 'VESSEL_OWNER';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Precondition Failed: User type VESSEL_OWNER must have COUNT(*) = 1';
    END IF;

    -- --------------------------------------------------------------------------
    -- 4. RUNTIME REFERENCE ID RESOLUTION
    -- --------------------------------------------------------------------------
    SELECT id INTO @vtype_bulk FROM tbl_type_of_vessel WHERE typeOfVessel = 'Bulk Carrier';
    SELECT id INTO @vtype_container FROM tbl_type_of_vessel WHERE typeOfVessel = 'Container Ship';

    SELECT id INTO @rank_ab_seaman FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating';
    SELECT id INTO @rank_bosun FROM tbl_rank WHERE rank_code = 'BOSUN' AND rank_type = 'Rating';
    SELECT id INTO @rank_chief_cook FROM tbl_rank WHERE rank_code = 'CHIEF COOK' AND rank_type = 'Catering';
    SELECT id INTO @rank_4th_eng FROM tbl_rank WHERE rank_code = '4TH ENGINEER' AND rank_type = 'Engine';
    SELECT id INTO @rank_master FROM tbl_rank WHERE rank_code = 'MASTER' AND rank_type = 'Deck';
    SELECT id INTO @rank_3rd_off FROM tbl_rank WHERE rank_code = '3RD OFFICER' AND rank_type = 'Deck';

    SELECT id INTO @doc_seaman_book FROM tbl_documents WHERE docType = 'License' AND documentName = 'Seafarer\'s Book (Seaman\'s Book)';
    SELECT id INTO @doc_peme FROM tbl_documents WHERE docType = 'Medical' AND documentName = 'PEME (Pre-Employment Medical Exam)';
    SELECT id INTO @doc_passport FROM tbl_documents WHERE docType = 'Personal' AND documentName = 'Passport';

    SELECT sequence INTO @status_active FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ACTIVE';
    SELECT sequence INTO @status_inactive FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'INACTIVE';
    SELECT sequence INTO @status_onboard FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ON BOARD';
    SELECT sequence INTO @status_vacation FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ON VACATION';
    SELECT sequence INTO @status_applicant FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'APPLICANT';
    SELECT sequence INTO @status_lineup FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'LINE UP';

    -- --------------------------------------------------------------------------
    -- 5. START FIXTURE TRANSACTION
    -- Initiated ONLY after every precondition check has passed.
    -- Any subsequent SQLEXCEPTION triggers the EXIT HANDLER, which executes
    -- ROLLBACK and RESIGNAL, ensuring zero partial data is committed.
    -- --------------------------------------------------------------------------
    START TRANSACTION;

    -- --------------------------------------------------------------------------
    -- 6. EXACT RUN-SPECIFIC IDEMPOTENT PURGE (PREVIOUS RUN REVERSE CLEANUP)
    -- Strictly matches ONLY records created by QA-C2-RUN-20261001-C2P1.
    -- --------------------------------------------------------------------------
-- Purge CCL schedules on QA-C2 vessels
DELETE s FROM tbl_ccl_schedules s
JOIN tbl_vessels v ON s.vessel_id = v.id
WHERE v.vesselName IN ('QA-C2-RUN-20261001-C2P1-Vessel-A', 'QA-C2-RUN-20261001-C2P1-Vessel-B');

-- Purge CCL relievers on QA-C2 vessels
DELETE r FROM tbl_ccl_relievers r
JOIN tbl_vessels v ON r.vessel_id = v.id
WHERE v.vesselName IN ('QA-C2-RUN-20261001-C2P1-Vessel-A', 'QA-C2-RUN-20261001-C2P1-Vessel-B');

-- Purge 51 generated links for this exact run
DELETE FROM tbl_applicant_generated_link 
WHERE fullname LIKE 'QA-C2-RUN-20261001-C2P1%' 
   OR email LIKE 'qa-c2-20261001-link-%@example.com';

-- Purge crew assessment comments for this exact run
DELETE c FROM tbl_personnel_comment c
JOIN tbl_personnel_info p ON c.personnel_id = p.id
WHERE p.email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com',
    'qa-c2-20261001-ap001@example.com', 'qa-c2-20261001-ap002@example.com'
) OR c.comments LIKE '%QA-C2-RUN-20261001-C2P1%';

-- Purge crew documents for this exact run
DELETE d FROM tbl_personnel_documents d
JOIN tbl_personnel_info p ON d.personnel_id = p.id
WHERE p.email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com',
    'qa-c2-20261001-ap001@example.com', 'qa-c2-20261001-ap002@example.com'
) OR d.document_num LIKE 'QA-C2-RUN-20261001-C2P1%';

-- Purge family info for this exact run
DELETE f FROM tbl_personnel_family_info f
JOIN tbl_personnel_info p ON f.personnel_id = p.id
WHERE p.email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com',
    'qa-c2-20261001-ap001@example.com', 'qa-c2-20261001-ap002@example.com'
);

-- Purge personnel info for this exact run
DELETE FROM tbl_personnel_info 
WHERE email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com',
    'qa-c2-20261001-ap001@example.com', 'qa-c2-20261001-ap002@example.com'
);

-- Purge user assigned vessels
DELETE uav FROM tbl_user_assigned_vessel uav
JOIN tbl_users u ON uav.user_id = u.id
WHERE u.username IN ('qa.c2.20261001.manning.restricted', 'qa.c2.20261001.principal', 'qa.c2.20261001.owner');

-- Purge dedicated users
DELETE FROM tbl_users 
WHERE username IN ('qa.c2.20261001.manning.restricted', 'qa.c2.20261001.principal', 'qa.c2.20261001.owner');

-- Purge vessels
DELETE FROM tbl_vessels 
WHERE vesselName IN ('QA-C2-RUN-20261001-C2P1-Vessel-A', 'QA-C2-RUN-20261001-C2P1-Vessel-B');

-- Purge principal
DELETE FROM tbl_principals 
WHERE name = 'QA-C2-RUN-20261001-C2P1-Principal-Shipping';

-- ------------------------------------------------------------------------------
-- 3. PROVISION PRINCIPAL
-- ------------------------------------------------------------------------------
INSERT INTO tbl_principals (name) 
VALUES ('QA-C2-RUN-20261001-C2P1-Principal-Shipping');
SET @prin_id = LAST_INSERT_ID();

-- ------------------------------------------------------------------------------
-- 4. PROVISION VESSELS (Using Dynamically Resolved Vessel Types)
-- ------------------------------------------------------------------------------
-- QA-C2 Vessel A: Bulk Carrier
INSERT INTO tbl_vessels (vesselName, agency, active, VesselType, principal, management, owner)
VALUES ('QA-C2-RUN-20261001-C2P1-Vessel-A', 'QA-C2 Maritime Agency', 'Active', @vtype_bulk, @prin_id, 1, NULL);
SET @vsl_a_id = LAST_INSERT_ID();

-- QA-C2 Vessel B: Container Ship
INSERT INTO tbl_vessels (vesselName, agency, active, VesselType, principal, management, owner)
VALUES ('QA-C2-RUN-20261001-C2P1-Vessel-B', 'QA-C2 Maritime Agency', 'Active', @vtype_container, @prin_id, 1, NULL);
SET @vsl_b_id = LAST_INSERT_ID();

-- ------------------------------------------------------------------------------
-- 5. PROVISION USER ACCOUNTS
-- ------------------------------------------------------------------------------
-- Account 1: Restricted Manning Staff (viewcrewcontactdetails=0, ccl_permission=1)
-- Uses in_manning_hash / in_manning_salt (validated by credential gate above)
INSERT INTO tbl_users (
    username, password, password_salt, fullname, type, management, 
    email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
) VALUES (
    'qa.c2.20261001.manning.restricted', in_manning_hash, in_manning_salt,
    'QA-C2-RUN-20261001-C2P1 Restricted Manning Staff', 'MANNING_STAFF', 1,
    'qa-c2-20261001-manning-restricted@example.com', 0, 1, 1, 0
);
SET @u_manning_id = LAST_INSERT_ID();

-- Account 2: Dedicated Principal (assigned ONLY to QA-C2 Vessel A)
-- Uses in_principal_hash / in_principal_salt (validated by credential gate above)
INSERT INTO tbl_users (
    username, password, password_salt, fullname, type, management, 
    email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
) VALUES (
    'qa.c2.20261001.principal', in_principal_hash, in_principal_salt,
    'QA-C2-RUN-20261001-C2P1 Dedicated Principal', 'PRINCIPAL', 1,
    'qa-c2-20261001-principal@example.com', 0, 0, 0, 0
);
SET @u_principal_id = LAST_INSERT_ID();

-- Account 3: Dedicated Vessel Owner (assigned ONLY to QA-C2 Vessel A)
-- Uses in_owner_hash / in_owner_salt (validated by credential gate above)
INSERT INTO tbl_users (
    username, password, password_salt, fullname, type, management, 
    email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
) VALUES (
    'qa.c2.20261001.owner', in_owner_hash, in_owner_salt,
    'QA-C2-RUN-20261001-C2P1 Dedicated Vessel Owner', 'VESSEL_OWNER', 1,
    'qa-c2-20261001-owner@example.com', 0, 0, 0, 0
);
SET @u_owner_id = LAST_INSERT_ID();

-- ------------------------------------------------------------------------------
-- 6. PROVISION USER VESSEL ASSIGNMENTS (ISOLATED TO QA-C2 VESSEL A ONLY)
-- ------------------------------------------------------------------------------
INSERT INTO tbl_user_assigned_vessel (user_id, vessel_id, principal_id, management_id, status)
VALUES (@u_principal_id, @vsl_a_id, @prin_id, 1, 'Active');

INSERT INTO tbl_user_assigned_vessel (user_id, vessel_id, principal_id, management_id, status)
VALUES (@u_owner_id, @vsl_a_id, @prin_id, 1, 'Active');

-- ------------------------------------------------------------------------------
-- 7. PROVISION SYNTHETIC CREW RECORDS (Dynamic Dates & Resolved Ranks & Statuses)
-- ------------------------------------------------------------------------------
-- A001: QA Maria Santos (Assigned: Vessel A, Status: ON BOARD, Rank: AB SEAMAN)
INSERT INTO tbl_personnel_info (
    firstname, middlename, lastname, position, religion, nationality, school_name, course,
    emp_status, crew_status, crew_availability, status_date, date_hired, date_of_birth, place_of_birth,
    gender, civil_status, blood_type, height, weight, email_address, applicant_contact_num,
    address, province, city, assigned_vessel_id, sss, tin, pagibig, philhealth,
    hmo_number, hmo_expiry, num_dependents, verified_benefits, verified_tin,
    uniform_coverall, uniform_shoes, uniform_polo, uniform_pants, note
) VALUES (
    'QA Maria', 'Clara', 'Santos', @rank_ab_seaman, 1, 1, 1, 1,
    'Regular', @status_onboard, 0, DATE_SUB(UTC_DATE(), INTERVAL 60 DAY), DATE_SUB(UTC_DATE(), INTERVAL 1 YEAR), '1992-08-15', 'Manila',
    'Female', 'Married', 'O+', 180.00, 72.00, 'qa-c2-20261001-a001@example.com', '+63 900 000 0001',
    '100 Synthetic Way, Manila', 1, 1, @vsl_a_id, '01-2345678-9', '123-456-789-000', '1234-5678-9012', '12-345678901-2',
    'HMO-QAC2-001', DATE_ADD(UTC_DATE(), INTERVAL 1 YEAR), 2, 1, 1,
    'L', '42', 'L', '32', 'QA-C2-RUN-20261001-C2P1-A001 On Board'
);
SET @crew_a001_id = LAST_INSERT_ID();

-- A002: QA Jose Rizal (Assigned: Vessel A, Status: LINE UP, Rank: BOSUN)
INSERT INTO tbl_personnel_info (
    firstname, middlename, lastname, position, religion, nationality, school_name, course,
    emp_status, crew_status, crew_availability, status_date, date_hired, date_of_birth, place_of_birth,
    gender, civil_status, blood_type, height, weight, email_address, applicant_contact_num,
    address, province, city, assigned_vessel_id, note
) VALUES (
    'QA Jose', 'Protacio', 'Rizal', @rank_bosun, 1, 1, 1, 1,
    'Regular', @status_lineup, 1, DATE_SUB(UTC_DATE(), INTERVAL 30 DAY), DATE_SUB(UTC_DATE(), INTERVAL 1 YEAR), '1990-06-19', 'Calamba',
    'Male', 'Single', 'A+', 170.00, 68.00, 'qa-c2-20261001-a002@example.com', '+63 900 000 0002',
    '102 Synthetic Way, Manila', 1, 1, @vsl_a_id, 'QA-C2-RUN-20261001-C2P1-A002 Line Up'
);
SET @crew_a002_id = LAST_INSERT_ID();

-- A003: QA Emilio Aguinaldo (Assigned: Vessel A, Status: INACTIVE [Ineligible CCL], Rank: CHIEF COOK)
INSERT INTO tbl_personnel_info (
    firstname, middlename, lastname, position, religion, nationality, school_name, course,
    emp_status, crew_status, crew_availability, status_date, date_hired, date_of_birth, place_of_birth,
    gender, civil_status, blood_type, height, weight, email_address, applicant_contact_num,
    address, province, city, assigned_vessel_id, note
) VALUES (
    'QA Emilio', 'Famy', 'Aguinaldo', @rank_chief_cook, 1, 1, 1, 1,
    'Contractual', @status_inactive, 0, DATE_SUB(UTC_DATE(), INTERVAL 90 DAY), DATE_SUB(UTC_DATE(), INTERVAL 2 YEAR), '1988-03-22', 'Kawit',
    'Male', 'Married', 'B+', 168.00, 65.00, 'qa-c2-20261001-a003@example.com', '+63 900 000 0003',
    '103 Synthetic Way, Manila', 1, 1, @vsl_a_id, 'QA-C2-RUN-20261001-C2P1-A003 Ineligible CCL'
);
SET @crew_a003_id = LAST_INSERT_ID();

-- A004: QA Apolinario Mabini (Assigned: Vessel A, Status: ON VACATION, Rank: 4TH ENGINEER, 0 Assessments)
INSERT INTO tbl_personnel_info (
    firstname, middlename, lastname, position, religion, nationality, school_name, course,
    emp_status, crew_status, crew_availability, status_date, date_hired, date_of_birth, place_of_birth,
    gender, civil_status, blood_type, height, weight, email_address, applicant_contact_num,
    address, province, city, assigned_vessel_id, note
) VALUES (
    'QA Apolinario', 'Marasigan', 'Mabini', @rank_4th_eng, 1, 1, 1, 1,
    'Regular', @status_vacation, 1, DATE_SUB(UTC_DATE(), INTERVAL 45 DAY), DATE_SUB(UTC_DATE(), INTERVAL 1 YEAR), '1989-07-23', 'Tanauan',
    'Male', 'Single', 'O-', 165.00, 58.00, 'qa-c2-20261001-a004@example.com', '+63 900 000 0004',
    '104 Synthetic Way, Manila', 1, 1, @vsl_a_id, 'QA-C2-RUN-20261001-C2P1-A004 Empty Assessment'
);
SET @crew_a004_id = LAST_INSERT_ID();

-- B001: QA Andres Bonifacio (Assigned: Vessel B, Status: ON BOARD, Rank: MASTER)
INSERT INTO tbl_personnel_info (
    firstname, middlename, lastname, position, religion, nationality, school_name, course,
    emp_status, crew_status, crew_availability, status_date, date_hired, date_of_birth, place_of_birth,
    gender, civil_status, blood_type, height, weight, email_address, applicant_contact_num,
    address, province, city, assigned_vessel_id, note
) VALUES (
    'QA Andres', 'de Castro', 'Bonifacio', @rank_master, 1, 1, 1, 1,
    'Regular', @status_onboard, 0, DATE_SUB(UTC_DATE(), INTERVAL 60 DAY), DATE_SUB(UTC_DATE(), INTERVAL 3 YEAR), '1985-11-30', 'Tondo',
    'Male', 'Married', 'AB+', 175.00, 75.00, 'qa-c2-20261001-b001@example.com', '+63 900 000 0005',
    '200 Synthetic Way, Cebu', 2, 2, @vsl_b_id, 'QA-C2-RUN-20261001-C2P1-B001 Vessel B Master'
);
SET @crew_b001_id = LAST_INSERT_ID();

-- U001: QA Juan Luna (Assigned: NULL [Unassigned], Status: ACTIVE, Rank: 3RD OFFICER)
INSERT INTO tbl_personnel_info (
    firstname, middlename, lastname, position, religion, nationality, school_name, course,
    emp_status, crew_status, crew_availability, status_date, date_hired, date_of_birth, place_of_birth,
    gender, civil_status, blood_type, height, weight, email_address, applicant_contact_num,
    address, province, city, assigned_vessel_id, note
) VALUES (
    'QA Juan', 'Novicio', 'Luna', @rank_3rd_off, 1, 1, 1, 1,
    'Regular', @status_active, 1, DATE_SUB(UTC_DATE(), INTERVAL 15 DAY), DATE_SUB(UTC_DATE(), INTERVAL 6 MONTH), '1991-10-23', 'Badoc',
    'Male', 'Single', 'B-', 172.00, 70.00, 'qa-c2-20261001-u001@example.com', '+63 900 000 0006',
    '300 Synthetic Way, Batangas', 3, 3, NULL, 'QA-C2-RUN-20261001-C2P1-U001 Unassigned'
);
SET @crew_u001_id = LAST_INSERT_ID();

-- AP001: QA Ana Reyes (Status: APPLICANT, Rank: AB SEAMAN [Rating])
INSERT INTO tbl_personnel_info (
    firstname, middlename, lastname, position, religion, nationality, school_name, course,
    emp_status, crew_status, crew_availability, status_date, date_of_birth,
    gender, civil_status, email_address, applicant_contact_num, note
) VALUES (
    'QA Ana', 'Dela', 'Reyes', @rank_ab_seaman, 1, 1, 1, 1,
    'Applicant', @status_applicant, 1, DATE_SUB(UTC_DATE(), INTERVAL 10 DAY), '1995-04-12',
    'Female', 'Single', 'qa-c2-20261001-ap001@example.com', '+63 900 000 0007',
    'QA-C2-RUN-20261001-C2P1-AP001 Rating Applicant'
);
SET @applicant_ap001_id = LAST_INSERT_ID();

-- AP002: QA Ben Cruz (Status: APPLICANT, Rank: 3RD OFFICER [Deck])
INSERT INTO tbl_personnel_info (
    firstname, middlename, lastname, position, religion, nationality, school_name, course,
    emp_status, crew_status, crew_availability, status_date, date_of_birth,
    gender, civil_status, email_address, applicant_contact_num, note
) VALUES (
    'QA Ben', 'San', 'Cruz', @rank_3rd_off, 1, 1, 1, 1,
    'Applicant', @status_applicant, 1, DATE_SUB(UTC_DATE(), INTERVAL 8 DAY), '1993-12-05',
    'Male', 'Single', 'qa-c2-20261001-ap002@example.com', '+63 900 000 0008',
    'QA-C2-RUN-20261001-C2P1-AP002 Deck Applicant'
);
SET @applicant_ap002_id = LAST_INSERT_ID();

-- ------------------------------------------------------------------------------
-- 8. PROVISION CREW FAMILY INFO (A001)
-- ------------------------------------------------------------------------------
INSERT INTO tbl_personnel_family_info (personnel_id, relationship, fname, lname, date_of_birth, contact, dependent)
VALUES 
(@crew_a001_id, 1, 'Mateo', 'Santos', '1990-05-15', '+63 900 000 0011', 1),
(@crew_a001_id, 2, 'Clara', 'Santos', '2018-09-20', NULL, 1);

-- ------------------------------------------------------------------------------
-- 9. PROVISION CREW DOCUMENTS (Dynamic Dates & Exact File Names)
-- ------------------------------------------------------------------------------
-- A001 License with Scan (QA-C2-RUN-20261001-C2P1-LIC-A001.pdf)
INSERT INTO tbl_personnel_documents (personnel_id, document_id, document_num, date_issued, date_expiry, grade, img_id)
VALUES (
    @crew_a001_id, @doc_seaman_book, 'QA-C2-RUN-20261001-C2P1-LIC-A001-NUM',
    DATE_SUB(UTC_DATE(), INTERVAL 6 MONTH), DATE_ADD(UTC_DATE(), INTERVAL 2 YEAR), 'A',
    'QA-C2-RUN-20261001-C2P1-LIC-A001.pdf'
);

-- A001 Medical with Scan (Sensitive Medical Category for TC-CM-188)
INSERT INTO tbl_personnel_documents (personnel_id, document_id, document_num, date_issued, date_expiry, grade, img_id)
VALUES (
    @crew_a001_id, @doc_peme, 'QA-C2-RUN-20261001-C2P1-MED-A001-NUM',
    DATE_SUB(UTC_DATE(), INTERVAL 2 MONTH), DATE_ADD(UTC_DATE(), INTERVAL 10 MONTH), 'FIT',
    'QA-C2-RUN-20261001-C2P1-MED-A001.pdf'
);

-- A001 Metadata Record WITHOUT Scan (NOSCAN for TC-CM-094)
INSERT INTO tbl_personnel_documents (personnel_id, document_id, document_num, date_issued, date_expiry, grade, img_id)
VALUES (
    @crew_a001_id, @doc_passport, 'QA-C2-RUN-20261001-C2P1-NOSCAN-A001-NUM',
    DATE_SUB(UTC_DATE(), INTERVAL 1 YEAR), DATE_ADD(UTC_DATE(), INTERVAL 9 YEAR), 'A',
    NULL
);

-- B001 Document on Vessel B (for TC-CM-188 Vessel Scope check)
INSERT INTO tbl_personnel_documents (personnel_id, document_id, document_num, date_issued, date_expiry, grade, img_id)
VALUES (
    @crew_b001_id, @doc_seaman_book, 'QA-C2-RUN-20261001-C2P1-LIC-B001-NUM',
    DATE_SUB(UTC_DATE(), INTERVAL 6 MONTH), DATE_ADD(UTC_DATE(), INTERVAL 2 YEAR), 'A',
    'QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf'
);

-- ------------------------------------------------------------------------------
-- 10. PROVISION CREW ASSESSMENTS (A001 & B001)
-- ------------------------------------------------------------------------------
-- A001 Assessment Note 1 (With Attachment QA-C2-RUN-20261001-C2P1-A001-ASSESS.pdf)
INSERT INTO tbl_personnel_comment (personnel_id, comments, date_sent, img_id, principal_view, added_by, added_by_name)
VALUES (
    @crew_a001_id,
    'QA-C2-RUN-20261001-C2P1 Performance assessment report with attached evaluation form.',
    DATE_SUB(UTC_DATE(), INTERVAL 15 DAY), 'QA-C2-RUN-20261001-C2P1-A001-ASSESS.pdf', '1',
    @u_manning_id, 'QA-C2-RUN-20261001-C2P1 Restricted Manning Staff'
);

-- A001 Assessment Note 2 (Without Attachment)
INSERT INTO tbl_personnel_comment (personnel_id, comments, date_sent, img_id, principal_view, added_by, added_by_name)
VALUES (
    @crew_a001_id,
    'QA-C2-RUN-20261001-C2P1 Routine quarterly operational performance assessment note.',
    DATE_SUB(UTC_DATE(), INTERVAL 10 DAY), NULL, '1',
    @u_manning_id, 'QA-C2-RUN-20261001-C2P1 Restricted Manning Staff'
);

-- B001 Assessment Note on Vessel B (for TC-CM-188 Vessel Scope check)
INSERT INTO tbl_personnel_comment (personnel_id, comments, date_sent, img_id, principal_view, added_by, added_by_name)
VALUES (
    @crew_b001_id,
    'QA-C2-RUN-20261001-C2P1 Vessel B master appraisal note with attachment.',
    DATE_SUB(UTC_DATE(), INTERVAL 5 DAY), 'QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf', '1',
    @u_manning_id, 'QA-C2-RUN-20261001-C2P1 Restricted Manning Staff'
);

-- (NOTE: Crew A004 has intentionally ZERO assessment comments for TC-CM-101)

-- ------------------------------------------------------------------------------
-- 11. PROVISION CONTROLLED TD-LINKS DATASET (51 SYNTHETIC RECORDS FOR TC-CM-145)
-- Dynamic dates: LA-FUTURE (+14d), LA-PAST1 (-1d), LA-PAST2 (-2d), LU-USED (+7d), LE-EXPIRED (-14d)
-- ------------------------------------------------------------------------------
-- LA-FUTURE: Active link with future validity (T+14 days)
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-LA-FUTURE', 'qa-c2-20261001-link-future@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 14 DAY), 'Active', UTC_TIMESTAMP(), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-LA-FUTURE'
);

-- LA-PAST1: Active link with expired validity (expired yesterday -> red highlight)
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-LA-PAST1', 'qa-c2-20261001-link-past1@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-LA-PAST1'
);

-- LA-PAST2: Active link with expired validity (expired 2 days ago -> red highlight)
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-LA-PAST2', 'qa-c2-20261001-link-past2@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 2 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 2 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-LA-PAST2'
);

-- LU-USED: Used link (validity T+7 days)
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-LU-USED', 'qa-c2-20261001-link-used@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 7 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 3 MINUTE),
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 HOUR), @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-LU-USED'
);

-- LE-EXPIRED: Expired link (validity T-14 days)
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-LE-EXPIRED', 'qa-c2-20261001-link-expired@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 14 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 4 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-LE-EXPIRED'
);

INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-06', 'qa-c2-20261001-link-batch06@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 6 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-06'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-07', 'qa-c2-20261001-link-batch07@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 7 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-07'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-08', 'qa-c2-20261001-link-batch08@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 8 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-08'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-09', 'qa-c2-20261001-link-batch09@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 9 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-09'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-10', 'qa-c2-20261001-link-batch10@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 10 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-10'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-11', 'qa-c2-20261001-link-batch11@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 11 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-11'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-12', 'qa-c2-20261001-link-batch12@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 12 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-12'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-13', 'qa-c2-20261001-link-batch13@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 13 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-13'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-14', 'qa-c2-20261001-link-batch14@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 14 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-14'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-15', 'qa-c2-20261001-link-batch15@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 15 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-15'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-16', 'qa-c2-20261001-link-batch16@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 16 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-16'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-17', 'qa-c2-20261001-link-batch17@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 17 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-17'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-18', 'qa-c2-20261001-link-batch18@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 18 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-18'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-19', 'qa-c2-20261001-link-batch19@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 19 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-19'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-20', 'qa-c2-20261001-link-batch20@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-20'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-21', 'qa-c2-20261001-link-batch21@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 21 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-21'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-22', 'qa-c2-20261001-link-batch22@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 22 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-22'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-23', 'qa-c2-20261001-link-batch23@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 23 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-23'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-24', 'qa-c2-20261001-link-batch24@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 24 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-24'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-25', 'qa-c2-20261001-link-batch25@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 25 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-25'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-26', 'qa-c2-20261001-link-batch26@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 26 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-26'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-27', 'qa-c2-20261001-link-batch27@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 27 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-27'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-28', 'qa-c2-20261001-link-batch28@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 28 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-28'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-29', 'qa-c2-20261001-link-batch29@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 29 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-29'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-30', 'qa-c2-20261001-link-batch30@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 30 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-30'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-31', 'qa-c2-20261001-link-batch31@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 31 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-31'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-32', 'qa-c2-20261001-link-batch32@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 32 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-32'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-33', 'qa-c2-20261001-link-batch33@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 33 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-33'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-34', 'qa-c2-20261001-link-batch34@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 34 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-34'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-35', 'qa-c2-20261001-link-batch35@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 35 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-35'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-36', 'qa-c2-20261001-link-batch36@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 36 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-36'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-37', 'qa-c2-20261001-link-batch37@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 37 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-37'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-38', 'qa-c2-20261001-link-batch38@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 38 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-38'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-39', 'qa-c2-20261001-link-batch39@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 39 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-39'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-40', 'qa-c2-20261001-link-batch40@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 40 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-40'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-41', 'qa-c2-20261001-link-batch41@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 41 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-41'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-42', 'qa-c2-20261001-link-batch42@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 42 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-42'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-43', 'qa-c2-20261001-link-batch43@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 43 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-43'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-44', 'qa-c2-20261001-link-batch44@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 44 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-44'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-45', 'qa-c2-20261001-link-batch45@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 45 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-45'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-46', 'qa-c2-20261001-link-batch46@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 46 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-46'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-47', 'qa-c2-20261001-link-batch47@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 47 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-47'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-48', 'qa-c2-20261001-link-batch48@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 48 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-48'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-49', 'qa-c2-20261001-link-batch49@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Used', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 49 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-49'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-50', 'qa-c2-20261001-link-batch50@example.com', 'Able Seaman',
    DATE_SUB(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Expired', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 50 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-50'
);
INSERT INTO tbl_applicant_generated_link (
    fullname, email, position_applied, validity, status, date_generated, last_date_access, generated_by, link_token
) VALUES (
    'QA-C2-RUN-20261001-C2P1-BATCH-51', 'qa-c2-20261001-link-batch51@example.com', 'Able Seaman',
    DATE_ADD(UTC_TIMESTAMP(), INTERVAL 20 DAY), 'Active', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 51 MINUTE), NULL,
    @u_manning_id, 'TOK-QA-C2-RUN-20261001-C2P1-BATCH-51'
);

-- ------------------------------------------------------------------------------
-- 12. PROVISION CCL FIXTURES (tbl_ccl_relievers & tbl_ccl_schedules)
-- Dynamic dates: joining date T+30 days, onsign date T+31 days
-- ------------------------------------------------------------------------------
INSERT INTO tbl_ccl_relievers (
    vessel_id, outgoing_crew_id, reliever_crew_id, status, remarks, created_by, date_created
) VALUES (
    @vsl_a_id, @crew_a001_id, @crew_a002_id, 'Pending Approval',
    'QA-C2-RUN-20261001-C2P1 Reliever nomination', @u_manning_id, UTC_TIMESTAMP()
);
SET @ccl_rel_id = LAST_INSERT_ID();

INSERT INTO tbl_ccl_schedules (
    reliever_id, vessel_id, crew_id, joining_date, joining_port, departure_date,
    ship_onsign_date, schedule_status, created_by, date_created
) VALUES (
    @ccl_rel_id, @vsl_a_id, @crew_a001_id, DATE_ADD(UTC_DATE(), INTERVAL 30 DAY), 'Port of Manila',
    DATE_ADD(UTC_DATE(), INTERVAL 30 DAY), DATE_ADD(UTC_DATE(), INTERVAL 31 DAY), 'Tentative',
    @u_manning_id, UTC_TIMESTAMP()
);

    COMMIT;
END proc_main$$

DELIMITER ;

-- ------------------------------------------------------------------------------
-- EXECUTE FIXTURE SETUP PROCEDURE
-- Credential session variables must be set by run-fixture-setup.ps1 before
-- sourcing this script. The procedure will SIGNAL and abort if any value is
-- missing, blank, a placeholder, or non-distinct.
-- ------------------------------------------------------------------------------
CALL sp_setup_qa_c2_run_20261001_c2p1(
    @QA_MANNING_HASH,   @QA_MANNING_SALT,
    @QA_PRINCIPAL_HASH, @QA_PRINCIPAL_SALT,
    @QA_OWNER_HASH,     @QA_OWNER_SALT
);

-- ------------------------------------------------------------------------------
-- CLEANUP TEMPORARY SETUP PROCEDURE
-- Cleaned up only after successful execution. If execution fails, the procedure
-- remains available for inspection and will be dropped on subsequent re-runs.
-- ------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_setup_qa_c2_run_20261001_c2p1;

-- ==============================================================================
-- END OF DYNAMIC FIXTURE SETUP SCRIPT
-- ==============================================================================
