-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-169 FIXTURE SETUP SCRIPT
-- Test Case: TC-CM-169 (Natural Clock Link Expiry and Submit-After-Expiry)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Batch Identifier: QA2FOC-RUN-20261011-TC169
-- Purpose: Defines sp_setup_qa_c2_tc169_expiry_fixtures_v2 to provision an isolated
--          invitation link that stays Active and expires solely through natural
--          clock passage.
--
-- DIAGNOSIS NOTE (Error 1267 Fix):
-- Original procedure failed on MySQL 8.0 because table columns in ummi_crew
-- (fullname, email) use `utf8mb4_unicode_ci` (coercibility level: IMPLICIT),
-- while routine variables declared without an explicit collation inherited the
-- session's `utf8mb4_0900_ai_ci` (coercibility level: IMPLICIT).
-- Comparing two IMPLICIT operands with differing collations causes Error 1267.
-- Version 2 resolves this by declaring all parameters, local variables, and string
-- operations with explicit `CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`.
-- The original `sp_setup_qa_c2_tc169_expiry_fixtures` is preserved intact.
--
-- WORKBENCH EXECUTION WORKFLOW:
-- 1. Run the READ-ONLY DIAGNOSTIC & RESIDUAL CHECK block.
-- 2. Run STEP 1 (Create Procedure v2).
-- 3. Confirm procedure creation succeeded.
-- 4. Run STEP 2 (Invocation) separately only when ready to trigger browser runner.
-- ==============================================================================

USE `ummi_crew`;

-- ------------------------------------------------------------------------------
-- READ-ONLY DIAGNOSTIC & RESIDUAL FIXTURE CHECK
-- Run this block first to confirm:
-- 1. Whether the failed invocation left any residual clock fixtures (Rollback audit)
-- 2. The exact collation configuration of table columns vs session
-- ------------------------------------------------------------------------------

-- Check 1: Residual Fixture Audit (Confirms failed invocation rolled back cleanly)
SELECT 
    '1. Residual Fixture Audit' AS DiagnosticSection,
    COUNT(*) AS ResidualClockFixtureCount,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS: Clean state confirmed (Failed invocation rolled back completely)'
        ELSE 'WARNING: Residual fixture found. Inspect before invoking v2.'
    END AS Status
FROM tbl_applicant_generated_link
WHERE fullname LIKE 'QA-C2-TC169-CLOCK-%'
   OR email LIKE 'tc169-clock-%@example.com';

-- Check 2: Column Collation Verification in ummi_crew
SELECT 
    '2. Target Column Collations' AS DiagnosticSection,
    table_name AS TableName,
    column_name AS ColumnName,
    character_set_name AS CharsetName,
    collation_name AS CollationName
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name IN ('tbl_applicant_generated_link', 'tbl_users', 'tbl_personnel_info')
  AND column_name IN ('fullname', 'email', 'status', 'username', 'firstname', 'lastname', 'email_address')
ORDER BY table_name, column_name;

-- Check 3: Session & Database Collation Context
SELECT 
    '3. Session vs Database Collation' AS DiagnosticSection,
    @@character_set_database AS DatabaseCharset,
    @@collation_database AS DatabaseCollation,
    @@character_set_connection AS ConnectionCharset,
    @@collation_connection AS ConnectionCollation;

-- ------------------------------------------------------------------------------
-- STEP 1: CREATE PROCEDURE v2 (Run this block separately in MySQL Workbench)
-- NOTE: Preserves existing sp_setup_qa_c2_tc169_expiry_fixtures. Does NOT DROP.
-- ------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `sp_setup_qa_c2_tc169_expiry_fixtures_v2`(
    IN p_lead_seconds INT,
    OUT p_link_id INT,
    OUT p_applicant_name VARCHAR(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    OUT p_validity DATETIME
)
BEGIN
    DECLARE v_now DATETIME;
    DECLARE v_validity DATETIME;
    DECLARE v_name VARCHAR(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE v_email VARCHAR(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE v_manning_uid INT DEFAULT NULL;
    DECLARE v_engine VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE v_existing_count INT DEFAULT 0;
    DECLARE v_inserted_rows INT DEFAULT 0;
    DECLARE v_readback_id INT DEFAULT 0;
    DECLARE v_readback_status VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE v_readback_validity DATETIME;

    -- Transactional error handler with guaranteed rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- 1. Setup-Time Lead Seconds Validation
    IF p_lead_seconds IS NULL OR p_lead_seconds < 30 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lead seconds must be at least 30 seconds to allow browser initialization.';
    END IF;

    -- 2. Setup-Time Transactional Engine Gate
    SELECT engine INTO v_engine
    FROM information_schema.tables
    WHERE table_schema = 'ummi_crew'
      AND table_name = 'tbl_applicant_generated_link'
    LIMIT 1;

    IF v_engine IS NULL OR v_engine <> ('InnoDB' COLLATE utf8mb4_unicode_ci) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'tbl_applicant_generated_link must use InnoDB engine.';
    END IF;

    -- 3. Setup-Time Reference User Uniqueness Gate
    SELECT COUNT(*), MAX(id) INTO v_existing_count, v_manning_uid
    FROM tbl_users 
    WHERE username = ('qa.manning.control' COLLATE utf8mb4_unicode_ci);

    IF v_existing_count <> 1 OR v_manning_uid IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reference user qa.manning.control missing or ambiguous in tbl_users.';
    END IF;

    START TRANSACTION;

    -- 4. Authoritative Evaluation Clock from MySQL Engine
    SET v_now = NOW();
    SET v_validity = DATE_ADD(v_now, INTERVAL p_lead_seconds SECOND);

    -- 5. Collision Protection with Explicit Collation Matching
    SET v_name = CONCAT('QA-C2-TC169-CLOCK-', UNIX_TIMESTAMP()) COLLATE utf8mb4_unicode_ci;
    SET v_email = CONCAT('tc169-clock-', UNIX_TIMESTAMP(), '@example.com') COLLATE utf8mb4_unicode_ci;

    SELECT COUNT(*) INTO v_existing_count
    FROM tbl_applicant_generated_link
    WHERE fullname = (v_name COLLATE utf8mb4_unicode_ci) 
       OR email = (v_email COLLATE utf8mb4_unicode_ci);

    IF v_existing_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Collision detected for generated fixture identifier.';
    END IF;

    -- 6. Insert Active Invitation (link_token=NULL, personnel_id=0 per application contract)
    INSERT INTO `tbl_applicant_generated_link` (
        `fullname`,
        `email`,
        `position_applied`,
        `validity`,
        `status`,
        `date_generated`,
        `last_date_access`,
        `generated_by`,
        `link_token`,
        `personnel_id`
    ) VALUES (
        v_name,
        v_email,
        'DECK CADET' COLLATE utf8mb4_unicode_ci,
        v_validity,
        'Active' COLLATE utf8mb4_unicode_ci,
        v_now,
        NULL,
        v_manning_uid,
        NULL,
        0
    );

    SET v_inserted_rows = ROW_COUNT();
    SET p_link_id = LAST_INSERT_ID();

    -- 7. Captured Inserted-Row Gate
    IF v_inserted_rows <> 1 OR p_link_id <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insert failed: row count or last_insert_id invalid.';
    END IF;

    -- Read back row within transaction to verify exact persisted state
    SELECT id, status, validity 
    INTO v_readback_id, v_readback_status, v_readback_validity
    FROM tbl_applicant_generated_link
    WHERE id = p_link_id;

    IF v_readback_id <> p_link_id 
       OR v_readback_status <> ('Active' COLLATE utf8mb4_unicode_ci) 
       OR v_readback_validity <> v_validity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Captured row verification mismatch inside transaction.';
    END IF;

    SET p_applicant_name = v_name;
    SET p_validity = v_validity;

    COMMIT;

    -- 8. Return Comprehensive Result Set with Clock Context
    SELECT 
        p_link_id AS NewLinkID,
        p_applicant_name AS ApplicantName,
        v_email AS ApplicantEmail,
        'Active' AS InitialStatus,
        v_now AS DatabaseClockAtCreation,
        p_validity AS ConfiguredValidity,
        p_lead_seconds AS LeadSecondsConfigured,
        TIMESTAMPDIFF(SECOND, NOW(), p_validity) AS RemainingSecondsAtOutput,
        @@system_time_zone AS DatabaseSystemTimeZone,
        @@time_zone AS DatabaseSessionTimeZone;

END$$

DELIMITER ;

-- ------------------------------------------------------------------------------
-- STEP 2: INVOCATION (Execute separately when browser test runner is ready)
-- Recommended lead time for manual handoff: 180 seconds (3 minutes)
-- ------------------------------------------------------------------------------
/*
USE `ummi_crew`;

SET @out_link_id = 0;
SET @out_name = '';
SET @out_validity = NULL;

CALL sp_setup_qa_c2_tc169_expiry_fixtures_v2(180, @out_link_id, @out_name, @out_validity);

SELECT 
    @out_link_id AS LinkID,
    @out_name AS ApplicantName,
    @out_validity AS ValidityTimestamp,
    NOW() AS InvocationClock,
    TIMESTAMPDIFF(SECOND, NOW(), @out_validity) AS RemainingLeadSeconds;
*/
