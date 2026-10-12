-- ==============================================================================
-- CYCLE 2 GAP CLOSURE: ATOMIC SETUP SCRIPT FOR ISOLATED ALLOWED CONTROL ACCOUNTS
-- Test Cases: TC-CM-002, TC-CM-004, TC-CM-006, TC-CM-008, TC-CM-010, TC-CM-013
-- Target Database: ummi_crew (Azure Database for MySQL, InnoDB engine)
-- Isolation Guarantee: Creates ONLY 3 dedicated QA control accounts:
--   1. qa.manning.control (Role: MANNING_STAFF, Role ID: 1)
--   2. qa.doc.control     (Role: DOCUMENTATION_OFFICER, Role ID: 5)
--   3. qa.admin.control   (Role: ADMIN, Role ID: 6)
-- Password Standard: CryptoHelper PBKDF2 v3 ($pbkdf2:100000$<44-char-base64>, 44-char salt)
-- Routine Isolation: Dedicated procedure sp_setup_qa_control_accounts
-- ==============================================================================

USE `ummi_crew`;

-- Drop only the procedure specifically dedicated to this control account setup
DROP PROCEDURE IF EXISTS sp_setup_qa_control_accounts;

DELIMITER $$

CREATE PROCEDURE sp_setup_qa_control_accounts(
    IN in_manning_hash VARCHAR(255),
    IN in_manning_salt VARCHAR(64),
    IN in_doc_hash     VARCHAR(255),
    IN in_doc_salt     VARCHAR(64),
    IN in_admin_hash   VARCHAR(255),
    IN in_admin_salt   VARCHAR(64)
)
proc_main: BEGIN
    DECLARE v_cnt INT DEFAULT 0;

    -- Exit handler with automatic rollback on any SQL exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- --------------------------------------------------------------------------
    -- 1. CREDENTIAL FORMAT & NULL/EMPTY ENFORCEMENT GATES (TC-CM-186 v3 Standard)
    -- Explicitly rejects NULL, empty/whitespace, and malformed strings
    -- Format: "$pbkdf2:100000$<44-char base64 derived key>" (len >= 59)
    -- Salt: 44-character Base64 string (256-bit salt, len >= 44)
    -- --------------------------------------------------------------------------
    IF in_manning_hash IS NULL OR TRIM(in_manning_hash) = '' 
       OR in_manning_hash NOT LIKE '$pbkdf2:100000$%' OR LENGTH(in_manning_hash) < 59
       OR in_manning_salt IS NULL OR TRIM(in_manning_salt) = '' OR LENGTH(in_manning_salt) < 44 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Gate Failed: in_manning_hash and in_manning_salt must be valid CryptoHelper PBKDF2 v3 credentials ($pbkdf2:100000$<44-char-base64>, 44-char salt)';
    END IF;

    IF in_doc_hash IS NULL OR TRIM(in_doc_hash) = '' 
       OR in_doc_hash NOT LIKE '$pbkdf2:100000$%' OR LENGTH(in_doc_hash) < 59
       OR in_doc_salt IS NULL OR TRIM(in_doc_salt) = '' OR LENGTH(in_doc_salt) < 44 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Gate Failed: in_doc_hash and in_doc_salt must be valid CryptoHelper PBKDF2 v3 credentials ($pbkdf2:100000$<44-char-base64>, 44-char salt)';
    END IF;

    IF in_admin_hash IS NULL OR TRIM(in_admin_hash) = '' 
       OR in_admin_hash NOT LIKE '$pbkdf2:100000$%' OR LENGTH(in_admin_hash) < 59
       OR in_admin_salt IS NULL OR TRIM(in_admin_salt) = '' OR LENGTH(in_admin_salt) < 44 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Gate Failed: in_admin_hash and in_admin_salt must be valid CryptoHelper PBKDF2 v3 credentials ($pbkdf2:100000$<44-char-base64>, 44-char salt)';
    END IF;

    -- --------------------------------------------------------------------------
    -- 2. USERNAME COLLISION GATE (Pre-Transaction Assertion)
    -- Stops execution if ANY intended username already exists
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM tbl_users 
    WHERE username IN ('qa.manning.control', 'qa.doc.control', 'qa.admin.control');
    IF v_cnt > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Gate Failed: One or more QA control accounts already exist. Run control-accounts-cleanup.sql first.';
    END IF;

    -- --------------------------------------------------------------------------
    -- 3. ROLE EXISTENCE GATE (tbl_user_type Verification)
    -- Authoritative Role IDs: MANNING_STAFF=1, DOCUMENTATION_OFFICER=5, ADMIN=6
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM tbl_user_type WHERE user_type = 'MANNING_STAFF' AND id = 1;
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: MANNING_STAFF role (ID 1) missing in tbl_user_type'; END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_user_type WHERE user_type = 'DOCUMENTATION_OFFICER' AND id = 5;
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: DOCUMENTATION_OFFICER role (ID 5) missing in tbl_user_type'; END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_user_type WHERE user_type = 'ADMIN' AND id = 6;
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: ADMIN role (ID 6) missing in tbl_user_type'; END IF;

    -- --------------------------------------------------------------------------
    -- 4. ATOMIC TRANSACTIONAL PROVISIONING (InnoDB Engine)
    -- management = 1 designates the primary UMMI Manning operational tenant
    -- disable_user = 0 ensures accounts are active
    -- Standard role baselines grant Crew Search and Applicant Pool by default
    -- --------------------------------------------------------------------------
    START TRANSACTION;

    -- Account 1: Control Manning Staff (baseline allowed for Crew Search & Applicant Pool)
    INSERT INTO tbl_users (
        username, password, password_salt, fullname, type, management, 
        email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
    ) VALUES (
        'qa.manning.control', in_manning_hash, in_manning_salt,
        'QA Isolated Manning Staff (Control)', 'MANNING_STAFF', 1,
        'qa-manning-control@example.com', 1, 1, 1, 0
    );

    -- Account 2: Control Documentation Officer (baseline allowed for Crew Search & Applicant Pool)
    INSERT INTO tbl_users (
        username, password, password_salt, fullname, type, management, 
        email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
    ) VALUES (
        'qa.doc.control', in_doc_hash, in_doc_salt,
        'QA Isolated Documentation Officer (Control)', 'DOCUMENTATION_OFFICER', 1,
        'qa-doc-control@example.com', 1, 0, 0, 0
    );

    -- Account 3: Control Admin (baseline allowed for Crew Search & Applicant Pool)
    INSERT INTO tbl_users (
        username, password, password_salt, fullname, type, management, 
        email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
    ) VALUES (
        'qa.admin.control', in_admin_hash, in_admin_salt,
        'QA Isolated Admin (Control)', 'ADMIN', 1,
        'qa-admin-control@example.com', 1, 0, 1, 0
    );

    COMMIT;

    -- --------------------------------------------------------------------------
    -- 5. POST-SETUP CONFIRMATION
    -- --------------------------------------------------------------------------
    SELECT 'PROVISIONING SUCCESS: QA Control Accounts Created' AS Status,
           COUNT(*) AS TotalCreated
    FROM tbl_users
    WHERE username IN ('qa.manning.control', 'qa.doc.control', 'qa.admin.control');

END proc_main $$

DELIMITER ;
