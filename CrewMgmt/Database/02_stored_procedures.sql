-- ============================================================
-- UMMI PDS — Crew Management Module
-- 02_stored_procedures.sql
-- ============================================================
USE `ummi_crew`;

DROP PROCEDURE IF EXISTS `spQueryCrewSearchDisplay`;
DELIMITER $$
CREATE PROCEDURE `spQueryCrewSearchDisplay`(
  IN `lastname_`        VARCHAR(100),
  IN `firstname_`       VARCHAR(100),
  IN `crewstatusID_`    INT,
  IN `crewavailbility_` INT,
  IN `activeInactive_`  VARCHAR(20),
  IN `rankID_`          INT,
  IN `ranktypeID_`      VARCHAR(50),
  IN `vesselID_`        INT,
  IN `vesselTypeExpID_` INT,
  IN `provinceID_`      INT,
  IN `cityID_`          INT,
  IN `cadetship_`       TINYINT,
  IN `jocap_`           TINYINT,
  IN `higherlic_`       TINYINT,
  IN `date_`            DATE,
  IN `userID_`          INT,
  IN `userType_`        VARCHAR(50)
)
BEGIN
  SELECT
    pi.id,
    pi.lastname,
    pi.firstname,
    pi.middlename,
    pi.picture_id,
    pi.gender,
    r.rank_code  AS rank_code,
    r.rank_type  AS rank_type,
    ds.meaning   AS crew_status_text,
    pi.crew_availability,
    TIMESTAMPDIFF(YEAR, pi.date_of_birth, CURDATE()) AS age,
    pr.provinces AS province_name,
    ct.cities    AS city_name,
    pi.cadetship,
    pi.jocap,
    pi.higher_license,
    pi.emp_status,
    pi.date_hired,
    pi.crew_status,
    pi.date_of_birth
  FROM `tbl_personnel_info` pi
  LEFT JOIN `tbl_rank`               r  ON r.id   = pi.position
  LEFT JOIN `tbl_dropdown_selection` ds ON ds.type = 'crew_status' AND ds.sequence = pi.crew_status
  LEFT JOIN `tbl_provinces`          pr ON pr.id   = pi.province
  LEFT JOIN `tbl_cities`             ct ON ct.id   = pi.city
  -- Principal restriction: only show crew on assigned vessels
  WHERE 1=1
    AND (lastname_  = '' OR pi.lastname  LIKE CONCAT('%', lastname_,  '%'))
    AND (firstname_ = '' OR pi.firstname LIKE CONCAT('%', firstname_, '%'))
    AND (crewstatusID_    IS NULL OR pi.crew_status = crewstatusID_)
    AND (crewavailbility_ IS NULL OR pi.crew_availability = crewavailbility_)
    AND (rankID_          IS NULL OR pi.position = rankID_)
    AND (ranktypeID_      = ''    OR r.rank_type = ranktypeID_)
    AND (provinceID_      IS NULL OR pi.province = provinceID_)
    AND (cityID_          IS NULL OR pi.city     = cityID_)
    AND (cadetship_  = 0 OR pi.cadetship     = 1)
    AND (jocap_      = 0 OR pi.jocap         = 1)
    AND (higherlic_  = 0 OR pi.higher_license = 1)
    AND (vesselTypeExpID_ IS NULL OR EXISTS (
          SELECT 1 FROM tbl_personnel_sea_service pss
          JOIN tbl_vessels v ON v.id = pss.vessel_id
          WHERE pss.personnel_id = pi.id AND v.VesselType = vesselTypeExpID_
        ))
    AND (vesselID_ IS NULL OR EXISTS (
          SELECT 1 FROM tbl_personnel_sea_service pss2
          WHERE pss2.personnel_id = pi.id AND pss2.vessel_id = vesselID_
        ))
  ORDER BY pi.lastname, pi.firstname;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS `spApplicantPoolSearchDisplay`;
DELIMITER $$
CREATE PROCEDURE `spApplicantPoolSearchDisplay`(
  IN `lastname_`        VARCHAR(100),
  IN `firstname_`       VARCHAR(100),
  IN `rank_`            INT,
  IN `ranktype_`        VARCHAR(50),
  IN `vslexpID_`        INT,
  IN `datefrom_`        DATE,
  IN `dateto_`          DATE
)
BEGIN
  SELECT
    pi.id,
    pi.lastname,
    pi.firstname,
    pi.middlename,
    pi.picture_id,
    pi.gender,
    r.rank_code  AS rank_code,
    TIMESTAMPDIFF(YEAR, pi.date_of_birth, CURDATE()) AS age,
    pi.date_hired,
    pi.applicant_contact_num
  FROM `tbl_personnel_info` pi
  LEFT JOIN `tbl_rank` r ON r.id = pi.position
  WHERE pi.crew_status = 5   -- APPLICANT status
    AND (lastname_  = '' OR pi.lastname  LIKE CONCAT('%', lastname_,  '%'))
    AND (firstname_ = '' OR pi.firstname LIKE CONCAT('%', firstname_, '%'))
    AND (rank_      IS NULL OR pi.position = rank_)
    AND (ranktype_  = ''   OR r.rank_type  = ranktype_)
    AND (datefrom_  IS NULL OR pi.date_hired >= datefrom_)
    AND (dateto_    IS NULL OR pi.date_hired <= dateto_)
    AND (vslexpID_  IS NULL OR EXISTS (
          SELECT 1 FROM tbl_personnel_sea_service pss
          JOIN tbl_vessels v ON v.id = pss.vessel_id
          WHERE pss.personnel_id = pi.id AND v.VesselType = vslexpID_
        ))
  ORDER BY pi.date_hired DESC, pi.lastname;
END$$
DELIMITER ;
