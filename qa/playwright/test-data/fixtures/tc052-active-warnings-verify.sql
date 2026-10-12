-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-052 VERIFICATION SCRIPT
-- Test Case: TC-CM-052 (Active Status Elapsed Date Warnings)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Classification: Strictly Read-Only Audit & Verification
-- ==============================================================================

USE `ummi_crew`;

SELECT 
    'TC-CM-052 Active Status Warnings Audit' AS Scope,
    p.id AS PersonnelID,
    CONCAT(p.lastname, ', ', p.firstname) AS CrewMemberName,
    ds.meaning AS StoredStatus,
    p.status_date AS StoredStatusDate,
    DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR)) AS PhilippineEvaluationDate,
    (YEAR(DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))) - YEAR(p.status_date)) * 12 +
    (MONTH(DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))) - MONTH(p.status_date)) AS ElapsedMonths,
    CASE
        WHEN ds.meaning NOT IN ('ACTIVE', 'ON VACATION', 'INACTIVE') THEN 'SUPPRESSED (No Badge)'
        WHEN ((YEAR(DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))) - YEAR(p.status_date)) * 12 +
              (MONTH(DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))) - MONTH(p.status_date))) > 8 THEN 'RED (status-date-red)'
        WHEN ((YEAR(DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))) - YEAR(p.status_date)) * 12 +
              (MONTH(DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))) - MONTH(p.status_date))) >= 4 THEN 'AMBER (status-date-amber)'
        ELSE 'NORMAL (No Badge)'
    END AS ExpectedWarningBadge,
    v.vesselName AS AssignedVessel
FROM tbl_personnel_info p
JOIN tbl_dropdown_selection ds ON ds.type = 'crew_status' AND ds.sequence = p.crew_status
LEFT JOIN tbl_vessels v ON p.assigned_vessel_id = v.id
WHERE p.lastname LIKE 'QA2FOC_Tc052_%'
   OR p.lastname IN ('QA2B18_StatusLt4m', 'QA2B18_StatusExact4m', 'QA2B18_StatusExact8m', 'QA2B18_StatusGt8m', 'QA2B18_StatusIneligible')
ORDER BY p.id;
