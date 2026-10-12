-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-052 CLEANUP SCRIPT (UNEXECUTED)
-- Test Case: TC-CM-052 (Active Status Elapsed Date Warnings)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Classification: Strictly Scoped Teardown (Do NOT execute automatically on collision)
--
-- Note on Transaction Safety & Implicit Commits:
-- MySQL DDL statements (like DROP PROCEDURE) trigger an implicit commit, terminating
-- any active transaction immediately. Therefore, DML deletes are transacted and committed
-- first; DDL procedure removal is executed afterward outside the transaction.
-- ==============================================================================

USE `ummi_crew`;

-- 1. Atomic DML Teardown (Strictly Scoped Deletions)
START TRANSACTION;

DELETE FROM tbl_personnel_info
WHERE (lastname IN ('QA2FOC_Tc052_Active6m', 'QA2FOC_Tc052_Active9m')
   AND email_address IN ('qa2foc-tc052-active6m@example.com', 'qa2foc-tc052-active9m@example.com'));

COMMIT;

-- 2. DDL Procedure Teardown (Executed outside DML transaction to prevent implicit commit side-effects)
DROP PROCEDURE IF EXISTS sp_setup_qa_c2_tc052_active_warnings;

SELECT 'TC-CM-052 CLEANUP COMPLETE' AS Status;
