-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-074 CLEANUP SCRIPT (UNEXECUTED)
-- Test Case: TC-CM-074 (Vessel Owner Authorized Contact & Profile Access)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Classification: Strictly Scoped Teardown (Do NOT execute automatically on collision)
--
-- Note on Transaction Safety & Implicit Commits:
-- MySQL DDL statements (like DROP PROCEDURE) trigger an implicit commit, terminating
-- any active transaction immediately. Therefore, DML deletes are transacted and committed
-- first; DDL procedure removal is executed afterward outside the transaction.
-- ==============================================================================

USE `ummi_crew`;

-- 1. Atomic DML Teardown (Scoped strictly to qa2contact.owner.authorized)
START TRANSACTION;

DELETE uav FROM tbl_user_assigned_vessel uav
JOIN tbl_users u ON uav.user_id = u.id
WHERE u.username = 'qa2contact.owner.authorized';

DELETE FROM tbl_users
WHERE username = 'qa2contact.owner.authorized'
  AND email_address = 'qa2contact-owner@example.com';

COMMIT;

-- 2. DDL Procedure Teardown (Executed outside DML transaction to prevent implicit commit side-effects)
DROP PROCEDURE IF EXISTS sp_setup_qa_c2_tc074_vessel_owner;

SELECT 'TC-CM-074 CLEANUP COMPLETE' AS Status;
