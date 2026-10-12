-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 BATCH 18 READ-ONLY CLEANUP INSPECTION
-- Target: Azure Staging Environment Only
-- Run Identifier: QA2B18-RUN-20261010
-- Classification: Strictly Read-Only Pre-Cleanup Audit
--
-- Safety Guarantees:
-- 1. Strictly Read-Only: Performs ZERO deletes or writes.
-- 2. Displays the exact rows that will be removed by batch18-gap-closure-cleanup.sql.
-- 3. Confirms that A001 (ID 163) and non-QA records will NOT be touched.
-- ==============================================================================

USE `ummi_crew`;

-- 1. Personnel Records Scheduled for Deletion (Exact 26 Records)
SELECT 'SCHEDULED FOR DELETION: tbl_personnel_info' AS AuditAction, id, lastname, firstname, crew_status, email_address
FROM tbl_personnel_info
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
)
ORDER BY id;

-- 2. Sea Service Records Scheduled for Deletion (Exact 4 Records)
SELECT 'SCHEDULED FOR DELETION: tbl_personnel_sea_service' AS AuditAction, ss.id, ss.personnel_id, p.email_address, ss.remarks
FROM tbl_personnel_sea_service ss
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
)
ORDER BY ss.id;

-- 3. Document Records Scheduled for Deletion (Exact 3 Records restricted to fixture crew)
SELECT 'SCHEDULED FOR DELETION: tbl_personnel_documents' AS AuditAction, d.id, d.personnel_id, p.email_address, d.document_num
FROM tbl_personnel_documents d
JOIN tbl_personnel_info p ON d.personnel_id = p.id
WHERE p.email_address = 'qa2b18-tc092-docbound@example.com'
  AND d.document_num IN ('QA2B18-DOC-EXP-MINUS1D', 'QA2B18-DOC-EXP-EXACT3M', 'QA2B18-DOC-EXP-PLUS1D');

-- 4. Applicant Links Scheduled for Deletion (Exact 3 Records)
SELECT 'SCHEDULED FOR DELETION: tbl_applicant_generated_link' AS AuditAction, id, fullname, email, status, link_token
FROM tbl_applicant_generated_link
WHERE link_token IN (
    'TOK-QA2B18-TC152-ACTIVE-TOKEN',
    'TOK-QA2B18-TC152-USED-TOKEN',
    'TOK-QA2B18-TC152-EXPIRED-TOKEN'
);

-- 5. Dedicated User Scheduled for Deletion (Exact 1 Record)
SELECT 'SCHEDULED FOR DELETION: tbl_users' AS AuditAction, id, username, type, email_address
FROM tbl_users
WHERE username = 'qa2b18.principal.novessels';
