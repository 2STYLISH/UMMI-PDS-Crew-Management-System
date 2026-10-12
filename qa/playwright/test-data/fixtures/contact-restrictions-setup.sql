-- ==============================================================================
-- CYCLE 2 GAP CLOSURE: ATOMIC SETUP SCRIPT FOR RESTRICTED QA ACCOUNTS
-- Test Cases: TC-CM-067, TC-CM-069, TC-CM-071
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Isolation Guarantee: Creates ONLY 3 dedicated QA accounts with prefix qa2contact.*
-- Zero Credentials in SQL: Hashes and salts supplied via runtime session variables
-- Hash Standard: PBKDF2-HMAC-SHA256, 100k iterations ($pbkdf2:100000$<Base64Key>)
-- ==============================================================================

USE `ummi_crew`;

DROP PROCEDURE IF EXISTS sp_setup_qa2contact_accounts;

DELIMITER $$

CREATE PROCEDURE sp_setup_qa2contact_accounts(
    IN in_doc_hash        VARCHAR(255),
    IN in_doc_salt        VARCHAR(64),
    IN in_admin_hash      VARCHAR(255),
    IN in_admin_salt      VARCHAR(64),
    IN in_superadmin_hash VARCHAR(255),
    IN in_superadmin_salt VARCHAR(64)
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
    -- 1. CREDENTIAL FORMAT ENFORCEMENT GATE (TC-CM-186 PBKDF2 v3 Standard)
    -- --------------------------------------------------------------------------
    IF in_doc_hash NOT LIKE '$pbkdf2:100000$%' OR in_doc_salt IS NULL OR LENGTH(in_doc_salt) < 16 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gate Failed: in_doc_hash must use CryptoHelper PBKDF2 v3 ($pbkdf2:100000$)';
    END IF;

    IF in_admin_hash NOT LIKE '$pbkdf2:100000$%' OR in_admin_salt IS NULL OR LENGTH(in_admin_salt) < 16 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gate Failed: in_admin_hash must use CryptoHelper PBKDF2 v3 ($pbkdf2:100000$)';
    END IF;

    IF in_superadmin_hash NOT LIKE '$pbkdf2:100000$%' OR in_superadmin_salt IS NULL OR LENGTH(in_superadmin_salt) < 16 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gate Failed: in_superadmin_hash must use CryptoHelper PBKDF2 v3 ($pbkdf2:100000$)';
    END IF;

    -- --------------------------------------------------------------------------
    -- 2. USERNAME COLLISION & PRECONDITION GATE
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM tbl_users 
    WHERE username IN ('qa2contact.doc.restricted', 'qa2contact.admin.restricted', 'qa2contact.superadmin.restricted');
    IF v_cnt > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gate Failed: One or more QA2CONTACT accounts already exist. Run cleanup first.';
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_user_type WHERE user_type = 'DOCUMENTATION_OFFICER';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: DOCUMENTATION_OFFICER role missing'; END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_user_type WHERE user_type = 'ADMIN';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: ADMIN role missing'; END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_user_type WHERE user_type = 'SUPER_ADMIN';
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: SUPER_ADMIN role missing'; END IF;

    -- --------------------------------------------------------------------------
    -- 3. ATOMIC TRANSACTIONAL PROVISIONING
    -- --------------------------------------------------------------------------
    START TRANSACTION;

    -- TC-CM-067: Documentation Officer with viewcrewcontactdetails = 0
    INSERT INTO tbl_users (
        username, password, password_salt, fullname, type, management, 
        email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
    ) VALUES (
        'qa2contact.doc.restricted', in_doc_hash, in_doc_salt,
        'QA2CONTACT Documentation Officer (Restricted)', 'DOCUMENTATION_OFFICER', 1,
        'qa2contact-doc@example.com', 0, 0, 0, 0
    );

    -- TC-CM-069: Admin with viewcrewcontactdetails = 0
    INSERT INTO tbl_users (
        username, password, password_salt, fullname, type, management, 
        email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
    ) VALUES (
        'qa2contact.admin.restricted', in_admin_hash, in_admin_salt,
        'QA2CONTACT Admin (Restricted)', 'ADMIN', 1,
        'qa2contact-admin@example.com', 0, 0, 1, 0
    );

    -- TC-CM-071: Super-Admin with viewcrewcontactdetails = 0
    INSERT INTO tbl_users (
        username, password, password_salt, fullname, type, management, 
        email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
    ) VALUES (
        'qa2contact.superadmin.restricted', in_superadmin_hash, in_superadmin_salt,
        'QA2CONTACT Super-Admin (Restricted)', 'SUPER_ADMIN', 1,
        'qa2contact-superadmin@example.com', 0, 0, 1, 0
    );

    COMMIT;

    -- Post-Setup Confirmation
    SELECT 'PROVISIONING SUCCESS: QA2CONTACT Accounts Created' AS Status,
           COUNT(*) AS TotalCreated
    FROM tbl_users
    WHERE username IN ('qa2contact.doc.restricted', 'qa2contact.admin.restricted', 'qa2contact.superadmin.restricted');

END proc_main $$

DELIMITER ;

-- ==============================================================================
-- INVOCATION TEMPLATE (MySQL Workbench / Runtime Execution)
-- Values must be supplied via runtime session variables derived by runner:
--
-- SET @QA2CONTACT_DOC_HASH        = '$pbkdf2:100000$<derived-key-base64>';
-- SET @QA2CONTACT_DOC_SALT        = '<random-salt-base64>';
-- SET @QA2CONTACT_ADMIN_HASH      = '$pbkdf2:100000$<derived-key-base64>';
-- SET @QA2CONTACT_ADMIN_SALT      = '<random-salt-base64>';
-- SET @QA2CONTACT_SUPERADMIN_HASH = '$pbkdf2:100000$<derived-key-base64>';
-- SET @QA2CONTACT_SUPERADMIN_SALT = '<random-salt-base64>';
--
-- CALL sp_setup_qa2contact_accounts(
--     @QA2CONTACT_DOC_HASH, @QA2CONTACT_DOC_SALT,
--     @QA2CONTACT_ADMIN_HASH, @QA2CONTACT_ADMIN_SALT,
--     @QA2CONTACT_SUPERADMIN_HASH, @QA2CONTACT_SUPERADMIN_SALT
-- );
-- ==============================================================================
