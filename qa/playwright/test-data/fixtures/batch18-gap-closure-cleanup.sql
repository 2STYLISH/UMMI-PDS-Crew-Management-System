-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 BATCH 18 FIXTURE CLEANUP
-- Target: Azure Staging Environment Only
-- Run Identifier: QA2B18-RUN-20261010
-- Classification: Exact-Key Cleanup with Stored Procedure & Atomic Rollback
--
-- Safety Rules:
-- 1. No Broad Wildcards: Targets ONLY exact usernames, emails, doc numbers, and tokens.
-- 2. Preserves Baseline Fixtures: Strictly preserves A001 (ID 163) and all prior QA fixtures.
-- 3. Failure-Safe: Encapsulated in stored procedure with EXIT HANDLER FOR SQLEXCEPTION.
-- 4. Reverse Foreign-Key Order: Child records purged before parent entities.
-- 5. Atomic Transaction: Wrapped in START TRANSACTION ... COMMIT with rollback on error.
-- 6. Read-Only Inspection: Maintained in separate batch18-gap-closure-cleanup-inspect.sql.
-- ==============================================================================

USE `ummi_crew`;

DROP PROCEDURE IF EXISTS sp_cleanup_qa_c2_batch18;

DELIMITER $$

CREATE PROCEDURE sp_cleanup_qa_c2_batch18()
proc_main: BEGIN
    -- --------------------------------------------------------------------------
    -- 1. EXCEPTION HANDLER: ATOMIC ROLLBACK & RESIGNAL
    -- --------------------------------------------------------------------------
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- --------------------------------------------------------------------------
    -- 2. START ATOMIC CLEANUP TRANSACTION
    -- --------------------------------------------------------------------------
    START TRANSACTION;

    -- Step 1: Delete child sea service records for the exact 26 Batch 18 emails
    DELETE ss FROM tbl_personnel_sea_service ss
    JOIN tbl_personnel_info p ON ss.personnel_id = p.id
    WHERE p.email_address IN (
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

    -- Step 2: Delete document records restricted strictly to the 3 exact document
    -- numbers AND their exact fixture personnel record
    DELETE d FROM tbl_personnel_documents d
    JOIN tbl_personnel_info p ON d.personnel_id = p.id
    WHERE p.email_address = 'qa2b18-tc092-docbound@example.com'
      AND d.document_num IN ('QA2B18-DOC-EXP-MINUS1D', 'QA2B18-DOC-EXP-EXACT3M', 'QA2B18-DOC-EXP-PLUS1D');

    -- Step 3: Delete the 3 controlled applicant generated links
    DELETE FROM tbl_applicant_generated_link
    WHERE link_token IN (
        'TOK-QA2B18-TC152-ACTIVE-TOKEN',
        'TOK-QA2B18-TC152-USED-TOKEN',
        'TOK-QA2B18-TC152-EXPIRED-TOKEN'
    );

    -- Step 4: Delete the exact 26 personnel records
    DELETE FROM tbl_personnel_info
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

    -- Step 5: Delete user vessel assignments for qa2b18.principal.novessels (defensive)
    DELETE uav FROM tbl_user_assigned_vessel uav
    JOIN tbl_users u ON uav.user_id = u.id
    WHERE u.username = 'qa2b18.principal.novessels';

    -- Step 6: Delete dedicated user account
    DELETE FROM tbl_users
    WHERE username = 'qa2b18.principal.novessels';

    -- --------------------------------------------------------------------------
    -- 3. COMMIT TRANSACTION
    -- --------------------------------------------------------------------------
    COMMIT;
END proc_main$$

DELIMITER ;

-- Execute cleanup procedure
CALL sp_cleanup_qa_c2_batch18();

-- Drop procedure definition upon completion
DROP PROCEDURE IF EXISTS sp_cleanup_qa_c2_batch18;

-- ==============================================================================
-- POST-CLEANUP VERIFICATION (Must return 0 for all counts)
-- ==============================================================================
SELECT 
    (SELECT COUNT(*) FROM tbl_personnel_info WHERE email_address IN (
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
    )) AS Residual_Personnel,
    (SELECT COUNT(*) FROM tbl_personnel_documents WHERE document_num IN (
        'QA2B18-DOC-EXP-MINUS1D', 'QA2B18-DOC-EXP-EXACT3M', 'QA2B18-DOC-EXP-PLUS1D'
    )) AS Residual_Documents,
    (SELECT COUNT(*) FROM tbl_applicant_generated_link WHERE link_token IN (
        'TOK-QA2B18-TC152-ACTIVE-TOKEN',
        'TOK-QA2B18-TC152-USED-TOKEN',
        'TOK-QA2B18-TC152-EXPIRED-TOKEN'
    )) AS Residual_Links,
    (SELECT COUNT(*) FROM tbl_users WHERE username = 'qa2b18.principal.novessels') AS Residual_Users;
