-- ==============================================================================
-- CYCLE 2 GAP CLOSURE: TC-CM-050 DATABASE INSPECTION QUERY
-- Target Database: ummi_crew (Azure Database for MySQL)
-- Target Fixtures: QA2B18_VesselBCrew and QA2B18_UnassignedCrew
-- Mode: READ-ONLY AUDIT (Zero modifications to fixtures or schema)
-- ==============================================================================

USE `ummi_crew`;

-- 1. Personnel Header Record & Current Assigned Vessel
SELECT 
    '1. Personnel Record' AS Section,
    p.id AS personnel_id,
    p.lastname,
    p.firstname,
    p.middlename,
    r.rank_code,
    ds.meaning AS crew_status,
    p.crew_availability AS availability_flag,
    p.status_date,
    p.date_of_birth,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS calculated_age,
    p.assigned_vessel_id,
    v_curr.vesselName AS assigned_vessel_name,
    p.email_address
FROM tbl_personnel_info p
LEFT JOIN tbl_rank r ON p.position = r.id
LEFT JOIN tbl_dropdown_selection ds ON ds.type = 'crew_status' AND ds.sequence = p.crew_status
LEFT JOIN tbl_vessels v_curr ON p.assigned_vessel_id = v_curr.id
WHERE p.email_address IN ('qa2b18-tc050-vslb@example.com', 'qa2b18-tc050-unassigned@example.com')
ORDER BY p.id;

-- 2. Sea Service Records (Voyage History & Last Vessel Source Data)
SELECT 
    '2. Sea Service Voyage Records' AS Section,
    ss.id AS sea_service_id,
    ss.personnel_id,
    p.lastname,
    ss.vessel_id,
    ss.vessel_name AS ss_raw_vessel_name,
    v_hist.vesselName AS tbl_vessel_name,
    r.rank_code AS voyage_rank,
    ss.port,
    ss.date_from,
    ss.date_to,
    ROUND(DATEDIFF(COALESCE(ss.date_to, CURDATE()), ss.date_from) / 365.25, 1) AS calculated_voyage_years,
    ss.remarks,
    -- Expected Last Vessel based on most recent voyage:
    COALESCE(v_hist.vesselName, ss.vessel_name, 'No Sea Service') AS expected_last_vessel_name
FROM tbl_personnel_sea_service ss
JOIN tbl_personnel_info p ON ss.personnel_id = p.id
LEFT JOIN tbl_vessels v_hist ON ss.vessel_id = v_hist.id
LEFT JOIN tbl_rank r ON ss.rank_id = r.id
WHERE p.email_address IN ('qa2b18-tc050-vslb@example.com', 'qa2b18-tc050-unassigned@example.com')
ORDER BY ss.personnel_id, ss.date_from DESC;

-- 3. Stored Procedure Query Comparison (What spQueryCrewSearchDisplay evaluates)
SELECT 
    '3. Staging SP Column Comparison' AS Section,
    p.id AS personnel_id,
    CONCAT(p.lastname, ', ', p.firstname) AS crew_name,
    v_curr.vesselName AS current_vessel,
    (
        SELECT COALESCE(v2.vesselName, s2.vessel_name)
        FROM tbl_personnel_sea_service s2
        LEFT JOIN tbl_vessels v2 ON s2.vessel_id = v2.id
        WHERE s2.personnel_id = p.id
        ORDER BY s2.date_from DESC
        LIMIT 1
    ) AS expected_last_vessel_from_history,
    (
        SELECT s3.vessel_name
        FROM tbl_personnel_sea_service s3
        WHERE s3.personnel_id = p.id
        ORDER BY s3.date_from DESC
        LIMIT 1
    ) AS raw_ss_column_vessel_name
FROM tbl_personnel_info p
LEFT JOIN tbl_vessels v_curr ON p.assigned_vessel_id = v_curr.id
WHERE p.email_address IN ('qa2b18-tc050-vslb@example.com', 'qa2b18-tc050-unassigned@example.com')
ORDER BY p.id;
