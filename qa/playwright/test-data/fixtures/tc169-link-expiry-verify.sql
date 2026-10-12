-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-169 VERIFICATION SCRIPT
-- Test Case: TC-CM-169 (Natural Clock Link Expiry and Submit-After-Expiry)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Classification: Strictly Read-Only Scoped Verification
-- ==============================================================================

USE `ummi_crew`;

-- Replace with the LinkID returned by sp_setup_qa_c2_tc169_expiry_fixtures
SET @test_link_id = 0; -- <-- Set to returned LinkID before executing

-- 1. Scoped Verification of Tested Link Fixture
-- Must confirm: status is STILL 'Active', validity has passed, personnel_id is 0
SELECT 
    '1. Invitation State Gate' AS Section,
    id AS LinkID,
    fullname AS ApplicantName,
    email AS Email,
    status AS StoredStatus,
    validity AS ConfiguredValidity,
    NOW() AS DatabaseClockNow,
    TIMESTAMPDIFF(SECOND, NOW(), validity) AS RemainingSeconds,
    CASE 
        WHEN status <> 'Active' THEN 'FAIL: Status was modified (Not purely natural clock expiry)'
        WHEN validity < NOW() THEN 'PASS: Natural clock expiry confirmed (status=Active, validity < NOW())'
        WHEN validity = NOW() THEN 'HOLD: Exact equality timestamp (Awaits CL-10 clarification)'
        ELSE 'FAIL: Validity has not yet elapsed (Still in the future)'
    END AS ExpiryEvaluationDecision,
    CASE 
        WHEN personnel_id = 0 OR personnel_id IS NULL THEN 'PASS: Link remains unlinked (personnel_id=0)'
        ELSE 'FAIL: Link was linked to personnel record'
    END AS LinkageDecision,
    last_date_access AS LastAccessTimestamp
FROM tbl_applicant_generated_link
WHERE (@test_link_id > 0 AND id = @test_link_id)
   OR (@test_link_id = 0 AND fullname LIKE 'QA-C2-TC169-CLOCK-%')
ORDER BY id DESC
LIMIT 1;

-- 2. Scoped Zero Persistence Gate
-- Must confirm: 0 records created for submitted applicant identity
SELECT 
    '2. Zero Persistence Gate' AS Section,
    COUNT(*) AS PersistedRecordCount,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS: Zero Persistence Confirmed (No records saved)'
        ELSE 'FAIL: Expired Submission Was Persisted In Error'
    END AS PersistenceAuditDecision
FROM tbl_personnel_info
WHERE firstname = 'QAExpiredTester' 
   OR lastname = 'QAExpiredTester'
   OR email_address LIKE 'tc169-clock-%@example.com';
