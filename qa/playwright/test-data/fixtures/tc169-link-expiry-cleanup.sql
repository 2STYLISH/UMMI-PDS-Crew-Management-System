-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-169 CLEANUP SCRIPT
-- Test Case: TC-CM-169 (Link Expiry Cutoff and Boundary Precision)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- NOTE: Execute ONLY when explicitly authorized after evidence review.
-- ==============================================================================

USE `ummi_crew`;

-- Delete isolated test invitations created specifically for TC-CM-169 boundary tests
DELETE FROM tbl_applicant_generated_link
WHERE fullname LIKE 'QA-C2-TC169-BOUNDARY-%'
   OR email LIKE 'tc169-boundary-%@example.com';

-- Drop helper routine
DROP PROCEDURE IF EXISTS `sp_setup_qa_c2_tc169_expiry_fixtures`;
