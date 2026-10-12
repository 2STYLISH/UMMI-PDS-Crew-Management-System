-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 FOCUSED FIXTURE CLEANUP
-- Test Cases: TC-CM-036 & TC-CM-098
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Batch Identifier: QA2FOC-RUN-20261011
-- Mode: Strictly Scoped Atomic Cleanup (Modifies ONLY QA2FOC_ batch records)
-- ==============================================================================

USE `ummi_crew`;

START TRANSACTION;

-- 1. Remove contracts created for QA2FOC_ fixtures
DELETE c FROM tbl_contracts c
JOIN tbl_personnel_info p ON c.personnel_id = p.id
WHERE p.lastname LIKE 'QA2FOC_%' OR p.email_address LIKE 'qa2foc-%@example.com';

-- 2. Remove personnel records created for QA2FOC_ fixtures
DELETE FROM tbl_personnel_info
WHERE lastname LIKE 'QA2FOC_%' OR email_address LIKE 'qa2foc-%@example.com';

COMMIT;

-- Post-cleanup verification (Assert COUNT = 0)
SELECT 
    'CLEANUP VERIFICATION' AS Status,
    (SELECT COUNT(*) FROM tbl_personnel_info WHERE lastname LIKE 'QA2FOC_%' OR email_address LIKE 'qa2foc-%@example.com') AS RemainingPersonnel,
    (SELECT COUNT(*) FROM tbl_contracts c JOIN tbl_personnel_info p ON c.personnel_id = p.id WHERE p.lastname LIKE 'QA2FOC_%') AS RemainingContracts;
