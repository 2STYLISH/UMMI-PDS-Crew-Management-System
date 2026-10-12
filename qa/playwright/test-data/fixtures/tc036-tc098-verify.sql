-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 FOCUSED VERIFICATION SCRIPT (CORRECTED)
-- Test Cases: TC-CM-036 (Availability Date Range) & TC-CM-098 (Total Sea Service)
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Batch Identifier: QA2FOC-RUN-20261011
-- Classification: Strictly Read-Only Audit & Verification
-- ==============================================================================

USE `ummi_crew`;

-- ------------------------------------------------------------------------------
-- 1. TC-CM-036: AVAILABILITY-DATE FIXTURES VERIFICATION
-- Explicitly audits tbl_personnel_info.available_from
-- ------------------------------------------------------------------------------
SELECT 
    'TC-CM-036 Fixtures' AS Scope,
    p.id AS PersonnelID,
    p.lastname AS LastName,
    p.firstname AS FirstName,
    p.available_from AS StoredAvailableFrom,
    p.assigned_vessel_id AS VesselID,
    v.vesselName AS VesselName,
    p.email_address AS Email,
    CASE 
        WHEN p.available_from BETWEEN '2026-09-10' AND '2026-09-20' THEN 'MATCH (Included in 10-20 Sep)'
        ELSE 'EXCLUDED (Outside 10-20 Sep)'
    END AS RangeMatch_10_to_20_Sep,
    CASE 
        WHEN p.available_from >= '2026-09-10' THEN 'MATCH (From-Only >= 10 Sep)'
        ELSE 'EXCLUDED (From-Only)'
    END AS FromOnlyMatch,
    CASE 
        WHEN p.available_from <= '2026-09-20' THEN 'MATCH (To-Only <= 20 Sep)'
        ELSE 'EXCLUDED (To-Only)'
    END AS ToOnlyMatch,
    'MATCH (Both-Empty)' AS BothEmptyMatch
FROM tbl_personnel_info p
LEFT JOIN tbl_vessels v ON p.assigned_vessel_id = v.id
WHERE p.lastname LIKE 'QA2FOC_Tc036_%'
ORDER BY p.id;

-- ------------------------------------------------------------------------------
-- 2. TC-CM-098: COMPANY CONTRACTS TOTAL SEA SERVICE VERIFICATION
-- Shows:
-- - Actual fixture personnel IDs and names
-- - Source contract dates and status
-- - Absence of prior history in tbl_personnel_sea_service (PriorSeaServiceRecords = 0)
-- - The Philippine evaluation date (UTC+8) dynamically evaluated at execution time
-- - Database session date and timezone
-- - Expected raw service days and displayed totals (0.7 yr(s) and 0.5 yr(s))
-- ------------------------------------------------------------------------------
SELECT 
    'TC-CM-098 Sea Service Audit' AS Scope,
    p.id AS PersonnelID,
    CONCAT(p.lastname, ', ', p.firstname) AS CrewMemberName,
    c.id AS ContractID,
    c.date_from AS SourceDateFrom,
    c.date_to AS SourceDateTo,
    c.status AS ContractStatus,
    -- Zero prior sea-service assertion:
    (SELECT COUNT(*) FROM tbl_personnel_sea_service ss WHERE ss.personnel_id = p.id) AS PriorSeaServiceRecords,
    -- Operational and session dates:
    @@session.time_zone AS WorkbenchSessionTimeZone,
    CURDATE() AS DbSessionDate,
    DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR)) AS PhilippineEvaluationDate,
    -- Service days calculation:
    DATEDIFF(COALESCE(c.date_to, DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))), c.date_from) AS ExpectedRawDaysPHT,
    ROUND(DATEDIFF(COALESCE(c.date_to, DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))), c.date_from) / 365.25, 4) AS ExactYearsCalculatedPHT,
    CONCAT(ROUND(DATEDIFF(COALESCE(c.date_to, DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR))), c.date_from) / 365.25, 1), ' yr(s)') AS ExpectedDisplayedTotalPHT,
    CONCAT(ROUND(DATEDIFF(COALESCE(c.date_to, CURDATE()), c.date_from) / 365.25, 1), ' yr(s)') AS ExpectedDisplayedIfDbSessionDate
FROM tbl_personnel_info p
JOIN tbl_contracts c ON c.personnel_id = p.id
WHERE p.lastname LIKE 'QA2FOC_Tc098_%'
ORDER BY p.id;
