-- ==============================================================================
-- UMMI CREW MANAGEMENT SYSTEM — CYCLE 2 TC-CM-052 SCOPED FIXTURE SETUP
-- Test Case: TC-CM-052 (Active Status Elapsed Date Warnings)
-- Target Database: ummi_crew (Azure Database for MySQL, InnoDB engine)
-- Batch Identifier: QA2FOC-RUN-20261011-TC052
-- Classification: One-Time Provisioning with Strict Precondition Gates, Collision Protection, and Atomic Transaction
--
-- Scope:
-- Completes the Active-status elapsed-date warning matrix alongside existing ID 231 (3m - No Warning):
-- 1. Active at 6 months elapsed -> Amber warning badge (status-date-amber)
-- 2. Active at 9 months elapsed -> Red warning badge (status-date-red)
--
-- Safety Guarantees:
-- 1. No Leading Drop: Does NOT drop or overwrite any existing helper procedure.
-- 2. Pre-Commit Assertions: Verifies measured row count using captured PersonnelIDs before COMMIT.
-- 3. Collision Protection: Stops execution with SIGNAL SQLSTATE '45000' on collision (inspect, do not clean).
-- 4. Atomic Rollback: Rolls back transaction on any error during execution.
-- ==============================================================================

USE `ummi_crew`;

DELIMITER $$

CREATE PROCEDURE sp_setup_qa_c2_tc052_active_warnings()
proc_main: BEGIN
    -- --------------------------------------------------------------------------
    -- 1. LOCAL VARIABLE DECLARATIONS
    -- --------------------------------------------------------------------------
    DECLARE v_cnt INT DEFAULT 0;
    DECLARE v_actual_crew_count INT DEFAULT 0;

    -- Dynamic Reference Identifiers
    DECLARE v_vsl_a_id       INT;
    DECLARE v_rank_ab_seaman INT;
    DECLARE v_status_active  INT;
    DECLARE v_prov_manila    INT;
    DECLARE v_city_manila    INT;

    -- Created Personnel Primary Keys
    DECLARE v_crew_052_act6m_id INT;
    DECLARE v_crew_052_act9m_id INT;

    -- Captured Philippine Date (UTC+8) at execution time
    DECLARE v_ph_today DATE;

    -- --------------------------------------------------------------------------
    -- 2. EXCEPTION HANDLER: ATOMIC ROLLBACK & RESIGNAL
    -- --------------------------------------------------------------------------
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Initialize Philippine Evaluation Date (UTC+8) dynamically
    SET v_ph_today = DATE(DATE_ADD(UTC_TIMESTAMP(), INTERVAL 8 HOUR));

    -- --------------------------------------------------------------------------
    -- 3. PRECONDITION VALIDATION: INNODB ENGINES (All 6 referenced tables)
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name IN (
        'tbl_personnel_info', 'tbl_vessels', 'tbl_rank', 
        'tbl_dropdown_selection', 'tbl_provinces', 'tbl_cities'
      )
      AND engine = 'InnoDB';
    IF v_cnt < 6 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gate Failed: Target tables not using InnoDB engine';
    END IF;

    -- --------------------------------------------------------------------------
    -- 4. PRECONDITION VALIDATION: REFERENCE ENTITIES (Strict COUNT(*) = 1 each)
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM tbl_vessels WHERE vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: QA Vessel A missing in tbl_vessels';
    END IF;
    SELECT id INTO v_vsl_a_id FROM tbl_vessels WHERE vesselName = 'QA-C2-RUN-20261001-C2P1-Vessel-A';

    SELECT COUNT(*) INTO v_cnt FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: Rank AB SEAMAN missing in tbl_rank';
    END IF;
    SELECT id INTO v_rank_ab_seaman FROM tbl_rank WHERE rank_code = 'AB SEAMAN' AND rank_type = 'Rating';

    SELECT COUNT(*) INTO v_cnt FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ACTIVE';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: Crew Status ACTIVE missing in tbl_dropdown_selection';
    END IF;
    SELECT sequence INTO v_status_active FROM tbl_dropdown_selection WHERE type = 'crew_status' AND meaning = 'ACTIVE';

    -- Approved, uniquely resolved location references (tbl_provinces & tbl_cities)
    SELECT COUNT(*) INTO v_cnt FROM tbl_provinces WHERE provinces = 'Metro Manila';
    IF v_cnt <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: Province Metro Manila missing in tbl_provinces';
    END IF;
    SELECT id INTO v_prov_manila FROM tbl_provinces WHERE provinces = 'Metro Manila';

    SELECT COUNT(*) INTO v_cnt 
    FROM tbl_cities c
    JOIN tbl_provinces p ON c.province = p.id
    WHERE c.cities = 'Manila' AND p.provinces = 'Metro Manila';
    IF v_cnt <> 1 THEN 
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reference Failed: City Manila missing or not uniquely bound to Metro Manila in tbl_cities'; 
    END IF;
    SELECT c.id INTO v_city_manila 
    FROM tbl_cities c 
    WHERE c.cities = 'Manila' AND c.province = v_prov_manila;

    -- --------------------------------------------------------------------------
    -- 5. COLLISION DETECTION: TC-CM-052 IDENTIFIERS
    -- --------------------------------------------------------------------------
    SELECT COUNT(*) INTO v_cnt FROM tbl_personnel_info
    WHERE lastname LIKE 'QA2FOC_Tc052_%'
       OR email_address IN ('qa2foc-tc052-active6m@example.com', 'qa2foc-tc052-active9m@example.com');
    IF v_cnt > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gate Failed: Collision detected. Stop and inspect collision records; do not run automatic cleanup.';
    END IF;

    -- --------------------------------------------------------------------------
    -- 6. ATOMIC TRANSACTION START
    -- --------------------------------------------------------------------------
    START TRANSACTION;

    -- --------------------------------------------------------------------------
    -- Fixture 1: Active at 6 Calendar Months Elapsed -> status-date-amber
    -- Formula: (DateTime.Now.Year - sd.Year)*12 + DateTime.Now.Month - sd.Month = 6
    -- --------------------------------------------------------------------------
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Apolinario', 'Mabini', 'QA2FOC_Tc052_Active6m', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        DATE_SUB(v_ph_today, INTERVAL 6 MONTH), '2025-01-15', '1992-07-23', 'Batangas', 'Male', 'Single', 'O+',
        170.00, 66.00, NULL, 'qa2foc-tc052-active6m@example.com', '+63 911 052 0001',
        '101 Mabini St, Manila', v_prov_manila, v_city_manila, v_vsl_a_id,
        'TC-CM-052: Active status date 6 calendar months elapsed (Amber warning badge)'
    );
    SET v_crew_052_act6m_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- Fixture 2: Active at 9 Calendar Months Elapsed -> status-date-red
    -- Formula: (DateTime.Now.Year - sd.Year)*12 + DateTime.Now.Month - sd.Month = 9 (> 8)
    -- --------------------------------------------------------------------------
    INSERT INTO tbl_personnel_info (
        firstname, middlename, lastname, position, emp_status, crew_status, crew_availability,
        status_date, date_hired, date_of_birth, place_of_birth, gender, civil_status, blood_type,
        height, weight, picture_id, email_address, applicant_contact_num, address, province, city,
        assigned_vessel_id, note
    ) VALUES (
        'Emilio', 'Jacinto', 'QA2FOC_Tc052_Active9m', v_rank_ab_seaman, 'Regular', v_status_active, 1,
        DATE_SUB(v_ph_today, INTERVAL 9 MONTH), '2025-01-15', '1995-12-15', 'Manila', 'Male', 'Single', 'B+',
        172.00, 68.00, NULL, 'qa2foc-tc052-active9m@example.com', '+63 911 052 0002',
        '102 Jacinto St, Manila', v_prov_manila, v_city_manila, v_vsl_a_id,
        'TC-CM-052: Active status date 9 calendar months elapsed (Red warning badge)'
    );
    SET v_crew_052_act9m_id = LAST_INSERT_ID();

    -- --------------------------------------------------------------------------
    -- 7. PRE-COMMIT ASSERTIONS (Measured specifically by captured PersonnelIDs)
    -- --------------------------------------------------------------------------
    IF v_crew_052_act6m_id IS NULL OR v_crew_052_act9m_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Post-Condition Failed: Captured PersonnelIDs must not be null';
    END IF;

    SELECT COUNT(*) INTO v_actual_crew_count 
    FROM tbl_personnel_info 
    WHERE id IN (v_crew_052_act6m_id, v_crew_052_act9m_id);

    IF v_actual_crew_count <> 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Post-Condition Failed: Expected exactly 2 personnel records measured by captured PersonnelIDs';
    END IF;

    -- Commit transaction atomically
    COMMIT;

    -- --------------------------------------------------------------------------
    -- 8. OUTPUT DEPLOYMENT AUDIT REPORT
    -- --------------------------------------------------------------------------
    SELECT 
        'PROVISIONING SUCCESS: TC-CM-052 Active Elapsed Warnings' AS Status,
        v_ph_today AS PhilippineEvaluationDate,
        v_crew_052_act6m_id AS Active6m_PersonnelID,
        DATE_SUB(v_ph_today, INTERVAL 6 MONTH) AS Active6m_StoredDate,
        'status-date-amber' AS Active6m_ExpectedBadge,
        v_crew_052_act9m_id AS Active9m_PersonnelID,
        DATE_SUB(v_ph_today, INTERVAL 9 MONTH) AS Active9m_StoredDate,
        'status-date-red' AS Active9m_ExpectedBadge;

END proc_main $$

DELIMITER ;
