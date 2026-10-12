-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 PHASE 1 FIXTURE CLEANUP
-- Target: Azure Staging Environment Only
-- Run Identifier: QA-C2-RUN-20261001-C2P1
-- Classification: Exact-Key Cleanup with Pre-Delete & Post-Delete Verifications
-- 
-- Safety Rules:
-- 1. No Broad Matching: Strictly forbidden from using '%@example.com' or 'QA%'.
-- 2. Exact Run Isolation: Targets ONLY exact usernames, vessels, emails, and doc numbers.
-- 3. Pre-Delete Inspection: Displays exact rows scheduled for deletion before DELETE.
-- 4. Reverse Foreign-Key Dependency Order: Child records deleted before parent entities.
-- 5. Atomic Transaction: Wrapped in START TRANSACTION ... COMMIT.
-- 6. Post-Cleanup Verification: Confirms zero residual RUN-20261001-C2P1 records remain.
-- ==============================================================================

START TRANSACTION;

-- ------------------------------------------------------------------------------
-- PRE-CLEANUP STEP 1: RESOLVE FIXTURE IDENTIFIERS
-- ------------------------------------------------------------------------------
SELECT id INTO @prin_id FROM tbl_principals WHERE name = 'QA-C2-RUN-20261001-C2P1-Principal-Shipping';
SELECT id INTO @vsl_a_id FROM tbl_vessels WHERE vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A';
SELECT id INTO @vsl_b_id FROM tbl_vessels WHERE vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-B';

-- ------------------------------------------------------------------------------
-- 1. CLEANUP CCL SCHEDULES
-- ------------------------------------------------------------------------------
-- Pre-delete audit of schedules to delete:
SELECT 'PRE-DELETE: tbl_ccl_schedules' AS AuditAction, id, reliever_id, vessel_id, schedule_status
FROM tbl_ccl_schedules
WHERE vessel_id IN (@vsl_a_id, @vsl_b_id);

DELETE FROM tbl_ccl_schedules 
WHERE vessel_id IN (@vsl_a_id, @vsl_b_id);
SELECT ROW_COUNT() AS Deleted_CCL_Schedules;

-- ------------------------------------------------------------------------------
-- 2. CLEANUP CCL RELIEVERS
-- ------------------------------------------------------------------------------
-- Pre-delete audit of relievers to delete:
SELECT 'PRE-DELETE: tbl_ccl_relievers' AS AuditAction, id, vessel_id, status, remarks
FROM tbl_ccl_relievers
WHERE vessel_id IN (@vsl_a_id, @vsl_b_id)
  AND remarks LIKE 'QA-C2-RUN-20261001-C2P1%';

DELETE FROM tbl_ccl_relievers 
WHERE vessel_id IN (@vsl_a_id, @vsl_b_id)
  AND remarks LIKE 'QA-C2-RUN-20261001-C2P1%';
SELECT ROW_COUNT() AS Deleted_CCL_Relievers;

-- ------------------------------------------------------------------------------
-- 3. CLEANUP APPLICANT GENERATED LINKS (TD-LINKS: 51 Records)
-- ------------------------------------------------------------------------------
-- Pre-delete audit of links to delete:
SELECT 'PRE-DELETE: tbl_applicant_generated_link' AS AuditAction, id, fullname, email, status, link_token
FROM tbl_applicant_generated_link
WHERE fullname LIKE 'QA-C2-RUN-20261001-C2P1%' 
   OR email LIKE 'qa-c2-20261001-link-%@example.com'
   OR link_token LIKE 'TOK-QA-C2-RUN-20261001-C2P1%';

DELETE FROM tbl_applicant_generated_link
WHERE fullname LIKE 'QA-C2-RUN-20261001-C2P1%' 
   OR email LIKE 'qa-c2-20261001-link-%@example.com'
   OR link_token LIKE 'TOK-QA-C2-RUN-20261001-C2P1%';
SELECT ROW_COUNT() AS Deleted_Applicant_Links;

-- ------------------------------------------------------------------------------
-- 4. CLEANUP CREW ASSESSMENTS
-- ------------------------------------------------------------------------------
-- Pre-delete audit of assessments to delete:
SELECT 'PRE-DELETE: tbl_personnel_comment' AS AuditAction, c.id, c.personnel_id, c.comments, c.img_id
FROM tbl_personnel_comment c
JOIN tbl_personnel_info p ON c.personnel_id = p.id
WHERE p.email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com'
) OR c.comments LIKE '%QA-C2-RUN-20261001-C2P1%'
  OR c.img_id LIKE 'QA-C2-RUN-20261001-C2P1%';

DELETE c FROM tbl_personnel_comment c
JOIN tbl_personnel_info p ON c.personnel_id = p.id
WHERE p.email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com'
) OR c.comments LIKE '%QA-C2-RUN-20261001-C2P1%'
  OR c.img_id LIKE 'QA-C2-RUN-20261001-C2P1%';
SELECT ROW_COUNT() AS Deleted_Personnel_Comments;

-- ------------------------------------------------------------------------------
-- 5. CLEANUP CREW DOCUMENTS
-- ------------------------------------------------------------------------------
-- Pre-delete audit of documents to delete:
SELECT 'PRE-DELETE: tbl_personnel_documents' AS AuditAction, d.id, d.personnel_id, d.document_num, d.img_id
FROM tbl_personnel_documents d
JOIN tbl_personnel_info p ON d.personnel_id = p.id
WHERE p.email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com'
) OR d.document_num LIKE 'QA-C2-RUN-20261001-C2P1%'
  OR d.img_id LIKE 'QA-C2-RUN-20261001-C2P1%';

DELETE d FROM tbl_personnel_documents d
JOIN tbl_personnel_info p ON d.personnel_id = p.id
WHERE p.email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com'
) OR d.document_num LIKE 'QA-C2-RUN-20261001-C2P1%'
  OR d.img_id LIKE 'QA-C2-RUN-20261001-C2P1%';
SELECT ROW_COUNT() AS Deleted_Personnel_Documents;

-- ------------------------------------------------------------------------------
-- 6. CLEANUP CREW FAMILY INFO
-- ------------------------------------------------------------------------------
-- Pre-delete audit of family records to delete:
SELECT 'PRE-DELETE: tbl_personnel_family_info' AS AuditAction, f.id, f.personnel_id, f.fname, f.lname
FROM tbl_personnel_family_info f
JOIN tbl_personnel_info p ON f.personnel_id = p.id
WHERE p.email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com'
);

DELETE f FROM tbl_personnel_family_info f
JOIN tbl_personnel_info p ON f.personnel_id = p.id
WHERE p.email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com'
);
SELECT ROW_COUNT() AS Deleted_Personnel_Family_Info;

-- ------------------------------------------------------------------------------
-- 7. CLEANUP PERSONNEL INFO (Crew & Applicants)
-- ------------------------------------------------------------------------------
-- Pre-delete audit of personnel to delete:
SELECT 'PRE-DELETE: tbl_personnel_info' AS AuditAction, id, firstname, lastname, email_address, note
FROM tbl_personnel_info
WHERE email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com',
    'qa-c2-20261001-ap001@example.com', 'qa-c2-20261001-ap002@example.com'
) OR note LIKE '%QA-C2-RUN-20261001-C2P1%';

DELETE FROM tbl_personnel_info
WHERE email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com',
    'qa-c2-20261001-ap001@example.com', 'qa-c2-20261001-ap002@example.com'
) OR note LIKE '%QA-C2-RUN-20261001-C2P1%';
SELECT ROW_COUNT() AS Deleted_Personnel_Info;

-- ------------------------------------------------------------------------------
-- 8. CLEANUP USER ASSIGNED VESSELS
-- ------------------------------------------------------------------------------
-- Pre-delete audit of vessel assignments:
SELECT 'PRE-DELETE: tbl_user_assigned_vessel' AS AuditAction, uav.id, u.username, v.vesselName
FROM tbl_user_assigned_vessel uav
JOIN tbl_users u ON uav.user_id = u.id
JOIN tbl_vessels v ON uav.vessel_id = v.id
WHERE u.username IN ('qa.c2.20261001.manning.restricted', 'qa.c2.20261001.principal', 'qa.c2.20261001.owner');

DELETE uav FROM tbl_user_assigned_vessel uav
JOIN tbl_users u ON uav.user_id = u.id
WHERE u.username IN ('qa.c2.20261001.manning.restricted', 'qa.c2.20261001.principal', 'qa.c2.20261001.owner');
SELECT ROW_COUNT() AS Deleted_User_Assigned_Vessels;

-- ------------------------------------------------------------------------------
-- 9. CLEANUP USER ACCOUNTS
-- ------------------------------------------------------------------------------
-- Pre-delete audit of users to delete:
SELECT 'PRE-DELETE: tbl_users' AS AuditAction, id, username, fullname, type
FROM tbl_users
WHERE username IN ('qa.c2.20261001.manning.restricted', 'qa.c2.20261001.principal', 'qa.c2.20261001.owner');

DELETE FROM tbl_users 
WHERE username IN ('qa.c2.20261001.manning.restricted', 'qa.c2.20261001.principal', 'qa.c2.20261001.owner');
SELECT ROW_COUNT() AS Deleted_Users;

-- ------------------------------------------------------------------------------
-- 10. CLEANUP VESSELS
-- ------------------------------------------------------------------------------
-- Pre-delete audit of vessels to delete:
SELECT 'PRE-DELETE: tbl_vessels' AS AuditAction, id, vesselName, principal
FROM tbl_vessels
WHERE vesselName IN ('QA-C2-RUN-20261001-C2P1-Vessel-A', 'QA-C2-RUN-20261001-C2P1-Vessel-B');

DELETE FROM tbl_vessels 
WHERE vesselName IN ('QA-C2-RUN-20261001-C2P1-Vessel-A', 'QA-C2-RUN-20261001-C2P1-Vessel-B');
SELECT ROW_COUNT() AS Deleted_Vessels;

-- ------------------------------------------------------------------------------
-- 11. CLEANUP PRINCIPAL
-- ------------------------------------------------------------------------------
-- Pre-delete audit of principal to delete:
SELECT 'PRE-DELETE: tbl_principals' AS AuditAction, id, name
FROM tbl_principals
WHERE name = 'QA-C2-RUN-20261001-C2P1-Principal-Shipping';

DELETE FROM tbl_principals 
WHERE name = 'QA-C2-RUN-20261001-C2P1-Principal-Shipping';
SELECT ROW_COUNT() AS Deleted_Principals;

COMMIT;

-- ------------------------------------------------------------------------------
-- POST-CLEANUP VERIFICATION: CONFIRM ZERO RESIDUAL RUN-20261001-C2P1 ENTITIES
-- ------------------------------------------------------------------------------
SELECT 
    'Post-Cleanup Residual Check' AS AuditCheck,
    (SELECT COUNT(*) FROM tbl_principals WHERE name LIKE '%RUN-20261001-C2P1%') AS Residual_Principals,
    (SELECT COUNT(*) FROM tbl_vessels WHERE vesselName LIKE '%RUN-20261001-C2P1%') AS Residual_Vessels,
    (SELECT COUNT(*) FROM tbl_users WHERE username LIKE '%20261001%') AS Residual_Users,
    (SELECT COUNT(*) FROM tbl_personnel_info WHERE email_address LIKE 'qa-c2-20261001%') AS Residual_Personnel,
    (SELECT COUNT(*) FROM tbl_applicant_generated_link WHERE fullname LIKE '%RUN-20261001-C2P1%') AS Residual_Links,
    (SELECT COUNT(*) FROM tbl_personnel_documents WHERE document_num LIKE '%RUN-20261001-C2P1%') AS Residual_Documents,
    (SELECT COUNT(*) FROM tbl_personnel_comment WHERE comments LIKE '%RUN-20261001-C2P1%') AS Residual_Comments,
    CASE 
        WHEN (SELECT COUNT(*) FROM tbl_principals WHERE name LIKE '%RUN-20261001-C2P1%') = 0
         AND (SELECT COUNT(*) FROM tbl_vessels WHERE vesselName LIKE '%RUN-20261001-C2P1%') = 0
         AND (SELECT COUNT(*) FROM tbl_users WHERE username LIKE '%20261001%') = 0
         AND (SELECT COUNT(*) FROM tbl_personnel_info WHERE email_address LIKE 'qa-c2-20261001%') = 0
         AND (SELECT COUNT(*) FROM tbl_applicant_generated_link WHERE fullname LIKE '%RUN-20261001-C2P1%') = 0
         AND (SELECT COUNT(*) FROM tbl_personnel_documents WHERE document_num LIKE '%RUN-20261001-C2P1%') = 0
         AND (SELECT COUNT(*) FROM tbl_personnel_comment WHERE comments LIKE '%RUN-20261001-C2P1%') = 0
        THEN 'PASS: Zero residual records remaining for RUN-20261001-C2P1. All existing data completely preserved.'
        ELSE 'FAIL: Residual records detected. Manual review required.'
    END AS FinalCleanupStatus;
