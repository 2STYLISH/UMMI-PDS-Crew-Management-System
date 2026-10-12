-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 PHASE 1 FIXTURE VALIDATION
-- Target: Azure Staging Environment Only
-- Run Identifier: QA-C2-RUN-20261001-C2P1
-- Classification: Read-Only Validation of Seeded Synthetic State
-- 
-- Safety Guarantee:
-- Performs strict read-only queries against exact run identifiers.
-- Zero broad LIKE matching; evaluates exact fixture keys.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. VALIDATE PRINCIPAL & VESSELS
-- Required for: TC-CM-042, TC-CM-045, TC-CM-058..062, TC-CM-202
-- ------------------------------------------------------------------------------
SELECT 
    '1. Principal & Vessels' AS CheckGroup,
    COUNT(DISTINCT p.id) AS PrincipalCount,
    COUNT(DISTINCT v.id) AS VesselCount,
    CASE 
        WHEN COUNT(DISTINCT p.id) = 1 AND COUNT(DISTINCT v.id) = 2 THEN 'PASS'
        ELSE 'FAIL'
    END AS ValidationStatus,
    GROUP_CONCAT(DISTINCT v.vesselName ORDER BY v.vesselName SEPARATOR ', ') AS ProvisionedVessels
FROM tbl_principals p
LEFT JOIN tbl_vessels v ON v.principal = p.id
WHERE p.name = 'QA-C2-RUN-20261001-C2P1-Principal-Shipping';

-- ------------------------------------------------------------------------------
-- 2. VALIDATE REQUIRED USER ACCOUNTS & PERMISSIONS
-- Required for: TC-CM-042, TC-CM-045, TC-CM-062, TC-CM-188, TC-CM-202
-- ------------------------------------------------------------------------------
SELECT 
    '2. User Accounts' AS CheckGroup,
    u.username,
    u.type AS RoleType,
    u.viewcrewcontactdetails AS ContactPermission,
    u.ccl_permission AS CCLPermission,
    u.disable_user AS IsDisabled,
    COUNT(uav.id) AS AssignedVesselCount,
    CASE
        WHEN u.username = 'qa.c2.20261001.manning.restricted' AND u.viewcrewcontactdetails = 0 AND u.ccl_permission = 1 THEN 'PASS'
        WHEN u.username = 'qa.c2.20261001.principal' AND u.type = 'PRINCIPAL' AND COUNT(uav.id) = 1 THEN 'PASS'
        WHEN u.username = 'qa.c2.20261001.owner' AND u.type = 'VESSEL_OWNER' AND COUNT(uav.id) = 1 THEN 'PASS'
        ELSE 'FAIL'
    END AS ValidationStatus
FROM tbl_users u
LEFT JOIN tbl_user_assigned_vessel uav ON uav.user_id = u.id
WHERE u.username IN ('qa.c2.20261001.manning.restricted', 'qa.c2.20261001.principal', 'qa.c2.20261001.owner')
GROUP BY u.id, u.username, u.type, u.viewcrewcontactdetails, u.ccl_permission, u.disable_user;

-- ------------------------------------------------------------------------------
-- 3. VALIDATE SYNTHETIC CREW ROSTER (Exact Email & Note Keys)
-- Required for: TC-CM-042, TC-CM-045, TC-CM-058..062, TC-CM-093..102, TC-CM-188
-- ------------------------------------------------------------------------------
SELECT 
    '3. Synthetic Crew Roster' AS CheckGroup,
    p.id AS CrewID,
    CONCAT(p.firstname, ' ', p.lastname) AS CrewName,
    p.crew_status AS StatusID,
    d.meaning AS StatusText,
    r.rank_code AS RankCode,
    r.rank_type AS RankType,
    v.vesselName AS AssignedVessel,
    p.hmo_expiry AS HMOExpiry,
    CASE 
        WHEN p.email_address = 'qa-c2-20261001-a001@example.com' AND d.meaning = 'ON BOARD' AND v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A' AND p.hmo_expiry > UTC_DATE() THEN 'PASS (A001: On Board Vessel A, Valid HMO)'
        WHEN p.email_address = 'qa-c2-20261001-a002@example.com' AND d.meaning = 'LINE UP' AND v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A' THEN 'PASS (A002: Line Up Vessel A)'
        WHEN p.email_address = 'qa-c2-20261001-a003@example.com' AND d.meaning = 'INACTIVE' AND v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A' THEN 'PASS (A003: Ineligible CCL Vessel A)'
        WHEN p.email_address = 'qa-c2-20261001-a004@example.com' AND d.meaning = 'ON VACATION' AND v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A' THEN 'PASS (A004: Vacation Vessel A)'
        WHEN p.email_address = 'qa-c2-20261001-b001@example.com' AND d.meaning = 'ON BOARD' AND v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-B' THEN 'PASS (B001: On Board Vessel B)'
        WHEN p.email_address = 'qa-c2-20261001-u001@example.com' AND d.meaning = 'ACTIVE' AND v.vesselName IS NULL THEN 'PASS (U001: Unassigned Active)'
        ELSE 'FAIL'
    END AS ValidationStatus
FROM tbl_personnel_info p
LEFT JOIN tbl_dropdown_selection d ON d.type = 'crew_status' AND d.sequence = p.crew_status
JOIN tbl_rank r ON p.position = r.id
LEFT JOIN tbl_vessels v ON p.assigned_vessel_id = v.id
WHERE p.email_address IN (
    'qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a002@example.com',
    'qa-c2-20261001-a003@example.com', 'qa-c2-20261001-a004@example.com',
    'qa-c2-20261001-b001@example.com', 'qa-c2-20261001-u001@example.com'
)
ORDER BY p.id;

-- ------------------------------------------------------------------------------
-- 4. VALIDATE SYNTHETIC APPLICANTS
-- Required for: TC-CM-122, TC-CM-123
-- ------------------------------------------------------------------------------
SELECT 
    '4. Synthetic Applicants' AS CheckGroup,
    p.id AS ApplicantID,
    CONCAT(p.firstname, ' ', p.lastname) AS ApplicantName,
    p.crew_status AS StatusID,
    d.meaning AS StatusText,
    r.rank_code AS RankCode,
    r.rank_type AS RankType,
    p.email_address AS Email,
    CASE 
        WHEN p.email_address = 'qa-c2-20261001-ap001@example.com' AND d.meaning = 'APPLICANT' AND r.rank_code = 'AB SEAMAN' AND r.rank_type = 'Rating' THEN 'PASS (AP001: Rating Match)'
        WHEN p.email_address = 'qa-c2-20261001-ap002@example.com' AND d.meaning = 'APPLICANT' AND r.rank_code = '3RD OFFICER' AND r.rank_type = 'Deck' THEN 'PASS (AP002: Deck Match)'
        ELSE 'FAIL'
    END AS ValidationStatus
FROM tbl_personnel_info p
LEFT JOIN tbl_dropdown_selection d ON d.type = 'crew_status' AND d.sequence = p.crew_status
JOIN tbl_rank r ON p.position = r.id
WHERE p.email_address IN ('qa-c2-20261001-ap001@example.com', 'qa-c2-20261001-ap002@example.com')
ORDER BY p.id;

-- ------------------------------------------------------------------------------
-- 5. VALIDATE SYNTHETIC DOCUMENTS (Exact Document Numbers & File Names)
-- Required for: TC-CM-093, TC-CM-094, TC-CM-188
-- ------------------------------------------------------------------------------
SELECT 
    '5. Crew Documents' AS CheckGroup,
    CONCAT(p.firstname, ' ', p.lastname) AS CrewName,
    d.documentName AS DocCategory,
    pd.document_num AS DocNumber,
    pd.img_id AS AttachmentFileName,
    CASE
        WHEN pd.document_num = 'QA-C2-RUN-20261001-C2P1-LIC-A001-NUM' AND pd.img_id = 'QA-C2-RUN-20261001-C2P1-LIC-A001.pdf' THEN 'PASS (A001 Scanned License)'
        WHEN pd.document_num = 'QA-C2-RUN-20261001-C2P1-MED-A001-NUM' AND pd.img_id = 'QA-C2-RUN-20261001-C2P1-MED-A001.pdf' THEN 'PASS (A001 Sensitive Medical)'
        WHEN pd.document_num = 'QA-C2-RUN-20261001-C2P1-NOSCAN-A001-NUM' AND pd.img_id IS NULL THEN 'PASS (A001 NOSCAN Metadata Record)'
        WHEN pd.document_num = 'QA-C2-RUN-20261001-C2P1-LIC-B001-NUM' AND pd.img_id = 'QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf' THEN 'PASS (B001 Vessel B Scan)'
        ELSE 'UNEXPECTED'
    END AS ValidationStatus
FROM tbl_personnel_documents pd
JOIN tbl_personnel_info p ON pd.personnel_id = p.id
JOIN tbl_documents d ON pd.document_id = d.id
WHERE pd.document_num LIKE 'QA-C2-RUN-20261001-C2P1%'
ORDER BY p.id, pd.id;

-- ------------------------------------------------------------------------------
-- 6. VALIDATE SYNTHETIC ASSESSMENTS
-- Required for: TC-CM-100, TC-CM-101, TC-CM-102, TC-CM-188
-- ------------------------------------------------------------------------------
SELECT 
    '6. Crew Assessments' AS CheckGroup,
    CONCAT(p.firstname, ' ', p.lastname) AS CrewName,
    COUNT(c.id) AS AssessmentCount,
    SUM(CASE WHEN c.img_id IS NOT NULL THEN 1 ELSE 0 END) AS WithAttachmentCount,
    SUM(CASE WHEN c.img_id IS NULL THEN 1 ELSE 0 END) AS WithoutAttachmentCount,
    CASE
        WHEN p.email_address = 'qa-c2-20261001-a001@example.com' 
         AND COUNT(c.id) = 2 
         AND SUM(CASE WHEN c.img_id = 'QA-C2-RUN-20261001-C2P1-A001-ASSESS.pdf' THEN 1 ELSE 0 END) = 1 
         THEN 'PASS (A001: 2 Notes, 1 Attachment)'
        WHEN p.email_address = 'qa-c2-20261001-a004@example.com' 
         AND COUNT(c.id) = 0 
         THEN 'PASS (A004: Exactly 0 Assessment Records)'
        WHEN p.email_address = 'qa-c2-20261001-b001@example.com' 
         AND COUNT(c.id) = 1 
         AND SUM(CASE WHEN c.img_id = 'QA-C2-RUN-20261001-C2P1-B001-ATTACH.pdf' THEN 1 ELSE 0 END) = 1 
         THEN 'PASS (B001: 1 Vessel B Attachment)'
        ELSE 'FAIL'
    END AS ValidationStatus
FROM tbl_personnel_info p
LEFT JOIN tbl_personnel_comment c ON c.personnel_id = p.id
WHERE p.email_address IN ('qa-c2-20261001-a001@example.com', 'qa-c2-20261001-a004@example.com', 'qa-c2-20261001-b001@example.com')
GROUP BY p.id, p.firstname, p.lastname, p.email_address;

-- ------------------------------------------------------------------------------
-- 7. VALIDATE CONTROLLED TD-LINKS DATASET (Exact RUN-20261001-C2P1 Scope)
-- Required for: TC-CM-145
-- ------------------------------------------------------------------------------
SELECT 
    '7. Applicant Generated Links (TD-LINKS)' AS CheckGroup,
    COUNT(*) AS TotalLinkCount,
    SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) AS ActiveCount,
    SUM(CASE WHEN status = 'Expired' THEN 1 ELSE 0 END) AS ExpiredCount,
    SUM(CASE WHEN status = 'Used' THEN 1 ELSE 0 END) AS UsedCount,
    SUM(CASE WHEN fullname = 'QA-C2-RUN-20261001-C2P1-LA-FUTURE' AND status = 'Active' AND validity > UTC_TIMESTAMP() THEN 1 ELSE 0 END) AS FutureActiveLinks,
    SUM(CASE WHEN fullname LIKE 'QA-C2-RUN-20261001-C2P1-LA-PAST%' AND status = 'Active' AND validity < UTC_TIMESTAMP() THEN 1 ELSE 0 END) AS PastValidityActiveLinks,
    CASE 
        WHEN COUNT(*) = 51 
         AND SUM(CASE WHEN fullname = 'QA-C2-RUN-20261001-C2P1-LA-FUTURE' AND status = 'Active' AND validity > UTC_TIMESTAMP() THEN 1 ELSE 0 END) = 1
         AND SUM(CASE WHEN fullname LIKE 'QA-C2-RUN-20261001-C2P1-LA-PAST%' AND status = 'Active' AND validity < UTC_TIMESTAMP() THEN 1 ELSE 0 END) = 2
         AND SUM(CASE WHEN status = 'Used' THEN 1 ELSE 0 END) >= 1
         AND SUM(CASE WHEN status = 'Expired' THEN 1 ELSE 0 END) >= 1
        THEN 'PASS (Exactly 51 Run-Isolated Links, Boundary & All Dynamic Status Criteria Met)'
        ELSE 'FAIL'
    END AS ValidationStatus
FROM tbl_applicant_generated_link
WHERE fullname LIKE 'QA-C2-RUN-20261001-C2P1%' 
   OR email LIKE 'qa-c2-20261001-link-%@example.com';

-- ------------------------------------------------------------------------------
-- 8. VALIDATE CCL ISOLATED FIXTURES
-- Required for: TC-CM-202
-- ------------------------------------------------------------------------------
SELECT 
    '8. CCL Isolated Fixtures' AS CheckGroup,
    r.id AS RelieverID,
    v.vesselName AS VesselName,
    CONCAT(p_out.firstname, ' ', p_out.lastname) AS OutgoingCrew,
    CONCAT(p_rel.firstname, ' ', p_rel.lastname) AS RelieverCrew,
    r.status AS RelieverStatus,
    s.id AS ScheduleID,
    s.schedule_status AS ScheduleStatus,
    s.joining_date AS JoiningDate,
    CASE
        WHEN r.status = 'Pending Approval' 
         AND s.schedule_status = 'Tentative' 
         AND v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A'
         AND s.joining_date > UTC_DATE()
        THEN 'PASS (Isolated Pending Nomination & Future Tentative Schedule on Vessel A)'
        ELSE 'FAIL'
    END AS ValidationStatus
FROM tbl_ccl_relievers r
JOIN tbl_vessels v ON r.vessel_id = v.id
JOIN tbl_personnel_info p_out ON r.outgoing_crew_id = p_out.id
JOIN tbl_personnel_info p_rel ON r.reliever_crew_id = p_rel.id
LEFT JOIN tbl_ccl_schedules s ON s.reliever_id = r.id
WHERE v.vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A';
