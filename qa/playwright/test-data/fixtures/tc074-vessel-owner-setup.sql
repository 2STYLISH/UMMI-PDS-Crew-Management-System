-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-074 SETUP SCRIPT
-- Test Case: TC-CM-074 (Vessel Owner Authorized Contact & Profile Access)
-- Target Database: ummi_crew (Azure Database for MySQL, InnoDB engine)
-- Isolation Guarantee: Creates ONLY 1 dedicated QA account 'qa2contact.owner.authorized'
-- Zero Credentials in SQL: Hashes and salts supplied via runtime session variables
-- Hash Standard: PBKDF2-HMAC-SHA256, 100k iterations ($pbkdf2:100000$<Base64Key>)
-- Schema Verified: tbl_vessels (principal, management, owner; no principal_id)
-- Safety: No leading DROP PROCEDURE. Creation and invocation are kept separate.
-- ==============================================================================

USE `ummi_crew`;

DELIMITER $$

CREATE PROCEDURE sp_setup_qa_c2_tc074_vessel_owner(
    IN in_owner_hash VARCHAR(255),
    IN in_owner_salt VARCHAR(64)
)
proc_main: BEGIN
    DECLARE v_cnt INT DEFAULT 0;
    DECLARE v_role_id INT DEFAULT 0;
    DECLARE v_role_name VARCHAR(50);
    DECLARE v_vsl_id INT DEFAULT 0;
    DECLARE v_prin_id INT DEFAULT 0;
    DECLARE v_mgmt_id INT DEFAULT 0;
    DECLARE v_owner_id INT DEFAULT NULL;
    DECLARE v_new_user_id INT DEFAULT 0;

    -- Exit handler with automatic rollback on any SQL exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- --------------------------------------------------------------------------
    -- 1. STORAGE ENGINE GATE: INNODB ENGINE VERIFICATION
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name IN (
        'tbl_users', 'tbl_user_assigned_vessel', 'tbl_vessels', 
        'tbl_principals', 'tbl_management', 'tbl_user_type'
      )
      AND engine = 'InnoDB';
    IF v_cnt < 6 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gate Failed: Target tables not using InnoDB engine';
    END IF;

    -- --------------------------------------------------------------------------
    -- 2. CREDENTIAL FORMAT ENFORCEMENT GATE (CryptoHelper PBKDF2-HMAC-SHA256 v3)
    -- Enforces exact CryptoHelper specification:
    -- - Salt: 32 bytes (256-bit) -> 44 chars Base64 (^[A-Za-z0-9+/]{43}=$)
    -- - Hash: "$pbkdf2:100000$" (15 chars) + 32-byte derived key (44 chars Base64) -> exactly 59 chars
    -- --------------------------------------------------------------------------
    IF in_owner_salt IS NULL OR LENGTH(in_owner_salt) <> 44 OR in_owner_salt NOT REGEXP '^[A-Za-z0-9+/]{43}=$' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Gate Failed: in_owner_salt must be 44 chars Base64 representing a 256-bit salt from CryptoHelper.GenerateSalt()';
    END IF;

    IF in_owner_hash IS NULL 
       OR in_owner_hash NOT LIKE '$pbkdf2:100000$%' 
       OR LENGTH(in_owner_hash) <> 59 
       OR SUBSTRING(in_owner_hash, 16) NOT REGEXP '^[A-Za-z0-9+/]{43}=$' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Gate Failed: in_owner_hash must be exactly 59 chars ($pbkdf2:100000$ + 44 chars Base64 256-bit derived key from CryptoHelper.CreatePBKDF2Hash)';
    END IF;

    -- --------------------------------------------------------------------------
    -- 3. RESOLVE CONFIRMED ROLE ID 7 & VARCHAR REPRESENTATION (tbl_user_type)
    -- Confirms Role ID 7 and resolves string 'VESSEL_OWNER' accepted by RoleHelper
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM tbl_user_type WHERE user_type = 'VESSEL_OWNER' AND id = 7;
    IF v_cnt <> 1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: VESSEL_OWNER role with ID 7 missing in tbl_user_type'; 
    END IF;
    SELECT id, user_type INTO v_role_id, v_role_name FROM tbl_user_type WHERE user_type = 'VESSEL_OWNER' AND id = 7;

    -- --------------------------------------------------------------------------
    -- 4. RESOLVE VESSEL PRINCIPAL & MANAGEMENT REFERENCES (tbl_vessels)
    -- Validates live staging columns: v.principal -> tbl_principals.id, v.management -> tbl_management.id
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt 
    FROM tbl_vessels v
    JOIN tbl_principals p ON v.principal = p.id
    JOIN tbl_management m ON v.management = m.id
    WHERE v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A';
    IF v_cnt <> 1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: QA Vessel A, bound Principal, or Management missing'; 
    END IF;

    SELECT v.id, v.principal, v.management, v.owner 
    INTO v_vsl_id, v_prin_id, v_mgmt_id, v_owner_id
    FROM tbl_vessels v
    JOIN tbl_principals p ON v.principal = p.id
    JOIN tbl_management m ON v.management = m.id
    WHERE v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A';

    -- --------------------------------------------------------------------------
    -- 5. USERNAME & EMAIL COLLISION DETECTION GATE
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM tbl_users 
    WHERE username = 'qa2contact.owner.authorized' OR email_address = 'qa2contact-owner@example.com';
    IF v_cnt > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gate Failed: Collision detected. Stop and inspect collision records; do not run automatic cleanup.';
    END IF;

    -- --------------------------------------------------------------------------
    -- 6. ATOMIC TRANSACTION START
    -- --------------------------------------------------------------------------
    START TRANSACTION;

    -- Insert Vessel Owner user:
    -- type is populated with 'VESSEL_OWNER' (representation accepted by RoleHelper)
    -- management is populated with actual validated tenant ID from vessel (v_mgmt_id)
    INSERT INTO tbl_users (
        username, password, password_salt, fullname, type, management, 
        email_address, viewcrewcontactdetails, viewcreatecontract, ccl_permission, disable_user
    ) VALUES (
        'qa2contact.owner.authorized', in_owner_hash, in_owner_salt,
        'QA2CONTACT Vessel Owner (Authorized Contact)', v_role_name, v_mgmt_id,
        'qa2contact-owner@example.com', 1, 0, 0, 0
    );
    SET v_new_user_id = LAST_INSERT_ID();

    -- Provision Vessel Assignment:
    -- Populates assignment principal_id and management_id from validated vessel references
    -- Preserves v.owner as owner_id without guessing or altering vessel ownership
    INSERT INTO tbl_user_assigned_vessel (
        user_id, vessel_id, principal_id, management_id, owner_id, status
    ) VALUES (
        v_new_user_id, v_vsl_id, v_prin_id, v_mgmt_id, v_owner_id, 'Active'
    );

    -- Post-Condition Gate: Assert row counts using captured primary keys
    SELECT COUNT(*) INTO v_cnt FROM tbl_users WHERE id = v_new_user_id;
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Post-Condition Failed: User creation verification failed'; END IF;

    SELECT COUNT(*) INTO v_cnt FROM tbl_user_assigned_vessel WHERE user_id = v_new_user_id AND vessel_id = v_vsl_id;
    IF v_cnt <> 1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Post-Condition Failed: Vessel assignment verification failed'; END IF;

    COMMIT;

    -- --------------------------------------------------------------------------
    -- 7. DEPLOYMENT AUDIT REPORT
    -- --------------------------------------------------------------------------
    SELECT 
        'PROVISIONING SUCCESS: TC-CM-074 Authorized Vessel Owner' AS Status,
        v_new_user_id AS UserID,
        'qa2contact.owner.authorized' AS Username,
        v_role_id AS ConfirmedRoleID,
        v_role_name AS StoredRoleRepresentation,
        1 AS ViewCrewContactDetails,
        v_vsl_id AS AssignedVesselID,
        'QA-C2-RUN-20261001-C2P1-Vessel-A' AS AssignedVesselName,
        v_prin_id AS AssignedPrincipalID,
        v_mgmt_id AS AssignedManagementID,
        v_owner_id AS AssignedOwnerID;

END proc_main $$

DELIMITER ;
