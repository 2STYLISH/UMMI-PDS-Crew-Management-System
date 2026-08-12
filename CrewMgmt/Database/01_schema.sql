-- ============================================================
-- UMMI PDS — Crew Management Module
-- 01_schema.sql  |  MySQL 5.7 / 8.4 compatible
-- 29 confirmed entities from ERD v1.0
-- ============================================================
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS,     UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE DATABASE IF NOT EXISTS `ummi_crew`
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ummi_crew`;

-- ===================== REFERENCE DATA ========================
CREATE TABLE IF NOT EXISTS `tbl_rank` (
  `id`        INT         NOT NULL AUTO_INCREMENT,
  `rank_code` VARCHAR(50) NOT NULL,
  `rank_type` VARCHAR(50) NOT NULL,
  `sequence`  INT         NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_religion` (
  `id`       INT         NOT NULL AUTO_INCREMENT,
  `religion` VARCHAR(80) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_nationality` (
  `id`          INT         NOT NULL AUTO_INCREMENT,
  `nationality` VARCHAR(80) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_school` (
  `id`          INT          NOT NULL AUTO_INCREMENT,
  `school_name` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_course` (
  `id`     INT          NOT NULL AUTO_INCREMENT,
  `course` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_relationship` (
  `id`           INT         NOT NULL AUTO_INCREMENT,
  `relationship` VARCHAR(80) NOT NULL,
  `remarks`      VARCHAR(200),
  `sequence`     INT         NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_provinces` (
  `id`        INT          NOT NULL AUTO_INCREMENT,
  `provinces` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_cities` (
  `id`       INT          NOT NULL AUTO_INCREMENT,
  `cities`   VARCHAR(100) NOT NULL,
  `province` INT          NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_cities_province` FOREIGN KEY (`province`) REFERENCES `tbl_provinces`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_type_of_vessel` (
  `id`           INT          NOT NULL AUTO_INCREMENT,
  `typeOfVessel` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_dropdown_selection` (
  `id`       INT          NOT NULL AUTO_INCREMENT,
  `type`     VARCHAR(100) NOT NULL,
  `meaning`  VARCHAR(200) NOT NULL,
  `status`   VARCHAR(20)  NOT NULL DEFAULT 'Active',
  `sequence` INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===================== VESSEL ================================
CREATE TABLE IF NOT EXISTS `tbl_principals` (
  `id`   INT          NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_management` (
  `id`         INT          NOT NULL AUTO_INCREMENT,
  `management` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_vessels` (
  `id`         INT          NOT NULL AUTO_INCREMENT,
  `vesselName` VARCHAR(200) NOT NULL,
  `agency`     VARCHAR(200),
  `active`     VARCHAR(10)  NOT NULL DEFAULT 'Active',
  `VesselType` INT,
  `principal`  INT,
  `management` INT,
  `owner`      INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_vessels_vtype` FOREIGN KEY (`VesselType`) REFERENCES `tbl_type_of_vessel`(`id`),
  CONSTRAINT `fk_vessels_princ` FOREIGN KEY (`principal`)  REFERENCES `tbl_principals`(`id`),
  CONSTRAINT `fk_vessels_mgmt`  FOREIGN KEY (`management`) REFERENCES `tbl_management`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_flight_option1` (
  `id`          INT        NOT NULL AUTO_INCREMENT,
  `vessel_id`   INT        NOT NULL,
  `batchNo`     INT        NOT NULL DEFAULT 0,
  `crewtype`    VARCHAR(50),
  `eticket_on`  TINYINT(1) NOT NULL DEFAULT 0,
  `eticket_off` TINYINT(1) NOT NULL DEFAULT 0,
  `selected`    TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_flt_vessel` FOREIGN KEY (`vessel_id`) REFERENCES `tbl_vessels`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===================== PERSONNEL =============================
CREATE TABLE IF NOT EXISTS `tbl_personnel_info` (
  `id`                    INT           NOT NULL AUTO_INCREMENT,
  `firstname`             VARCHAR(100)  NOT NULL,
  `middlename`            VARCHAR(100),
  `lastname`              VARCHAR(100)  NOT NULL,
  `suffix`                VARCHAR(20),
  `position`              INT,
  `religion`              INT,
  `nationality`           INT,
  `school_name`           INT,
  `course`                INT,
  `emp_status`            VARCHAR(50),
  `crew_status`           INT           NOT NULL DEFAULT 1
                          COMMENT '1=ACTIVE,2=INACTIVE,3=ON BOARD,4=ON VACATION,5=APPLICANT,6=LINE UP',
  `crew_availability`     INT           NOT NULL DEFAULT 1
                          COMMENT '1=Available,0=Not Available',
  `date_hired`            DATE,
  `date_of_birth`         DATE,
  `place_of_birth`        VARCHAR(200),
  `gender`                VARCHAR(20),
  `civil_status`          VARCHAR(50),
  `height`                DECIMAL(5,2),
  `weight`                DECIMAL(5,2),
  `email_address`         VARCHAR(200),
  `applicant_contact_num` VARCHAR(50),
  `address`               TEXT,
  `province`              INT,
  `city`                  INT,
  `sss`                   VARCHAR(50),
  `tin`                   VARCHAR(50),
  `pagibig`               VARCHAR(50),
  `philhealth`            VARCHAR(50),
  `verified_benefits`     TINYINT(1)    NOT NULL DEFAULT 0,
  `verified_tin`          TINYINT(1)    NOT NULL DEFAULT 0,
  `picture_id`            VARCHAR(200),
  `note`                  TEXT,
  `cadetship`             TINYINT(1)    NOT NULL DEFAULT 0,
  `jocap`                 TINYINT(1)    NOT NULL DEFAULT 0,
  `higher_license`        TINYINT(1)    NOT NULL DEFAULT 0,
  `date_added`            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_pi_rank`   FOREIGN KEY (`position`)    REFERENCES `tbl_rank`(`id`),
  CONSTRAINT `fk_pi_rel`    FOREIGN KEY (`religion`)    REFERENCES `tbl_religion`(`id`),
  CONSTRAINT `fk_pi_nat`    FOREIGN KEY (`nationality`) REFERENCES `tbl_nationality`(`id`),
  CONSTRAINT `fk_pi_school` FOREIGN KEY (`school_name`) REFERENCES `tbl_school`(`id`),
  CONSTRAINT `fk_pi_course` FOREIGN KEY (`course`)      REFERENCES `tbl_course`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_personnel_comment` (
  `id`             INT        NOT NULL AUTO_INCREMENT,
  `personnel_id`   INT        NOT NULL,
  `comments`       TEXT       NOT NULL,
  `date_sent`      DATE       NOT NULL,
  `img_id`         VARCHAR(200),
  `principal_view` VARCHAR(10) NOT NULL DEFAULT '0',
  `added_by`       INT,
  `added_by_name`  VARCHAR(200),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_pcm_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===================== DOCUMENT ==============================
CREATE TABLE IF NOT EXISTS `tbl_documents` (
  `id`                   INT          NOT NULL AUTO_INCREMENT,
  `documentName`         VARCHAR(200) NOT NULL,
  `docType`              VARCHAR(50)  NOT NULL
                         COMMENT 'Personal/License/Medical/Training/Outsource/UMMI',
  `month_expiry_warning` INT          NOT NULL DEFAULT 3,
  `sequence`             INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_personnel_documents` (
  `id`                 INT          NOT NULL AUTO_INCREMENT,
  `personnel_id`       INT          NOT NULL,
  `document_id`        INT          NOT NULL,
  `document_num`       VARCHAR(200),
  `date_issued`        DATE,
  `date_expiry`        DATE,
  `grade`              VARCHAR(50),
  `img_id`             VARCHAR(200),
  `required_documents` VARCHAR(10)  NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_pd_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info`(`id`),
  CONSTRAINT `fk_pd_doc` FOREIGN KEY (`document_id`)  REFERENCES `tbl_documents`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===================== SEA SERVICE ===========================
CREATE TABLE IF NOT EXISTS `tbl_personnel_sea_service` (
  `id`           INT         NOT NULL AUTO_INCREMENT,
  `personnel_id` INT         NOT NULL,
  `vessel_id`    INT         NOT NULL,
  `rank_id`      INT,
  `date_from`    DATE        NOT NULL,
  `date_to`      DATE,
  `remarks`      VARCHAR(500),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_pss_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info`(`id`),
  CONSTRAINT `fk_pss_vsl` FOREIGN KEY (`vessel_id`)    REFERENCES `tbl_vessels`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_contracts` (
  `id`           INT         NOT NULL AUTO_INCREMENT,
  `personnel_id` INT         NOT NULL,
  `vessel_id`    INT         NOT NULL,
  `rank_id`      INT,
  `date_from`    DATE        NOT NULL,
  `date_to`      DATE,
  `status`       VARCHAR(50) NOT NULL DEFAULT 'Active',
  `remarks`      VARCHAR(500),
  `date_created` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_con_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info`(`id`),
  CONSTRAINT `fk_con_vsl` FOREIGN KEY (`vessel_id`)    REFERENCES `tbl_vessels`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===================== FAMILY & HMO ==========================
CREATE TABLE IF NOT EXISTS `tbl_personnel_family_info` (
  `id`            INT          NOT NULL AUTO_INCREMENT,
  `personnel_id`  INT          NOT NULL,
  `relationship`  INT,
  `fname`         VARCHAR(100) NOT NULL,
  `lname`         VARCHAR(100) NOT NULL,
  `date_of_birth` DATE,
  `contact`       VARCHAR(50),
  `dependent`     TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_pfi_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info`(`id`),
  CONSTRAINT `fk_pfi_rel` FOREIGN KEY (`relationship`) REFERENCES `tbl_relationship`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_hmo_beneficiary` (
  `id`                 INT         NOT NULL AUTO_INCREMENT,
  `personnel_id`       INT         NOT NULL,
  `family_id`          INT         NOT NULL,
  `hmo_number`         VARCHAR(100),
  `date_expiry`        DATE,
  `beneficiary_type`   VARCHAR(50),
  `beneficiary_status` VARCHAR(50),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_hmo_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info`(`id`),
  CONSTRAINT `fk_hmo_fam` FOREIGN KEY (`family_id`)    REFERENCES `tbl_personnel_family_info`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===================== USER & ACCESS =========================
CREATE TABLE IF NOT EXISTS `tbl_user_type` (
  `id`        INT         NOT NULL AUTO_INCREMENT,
  `user_type` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_users` (
  `id`                     INT          NOT NULL AUTO_INCREMENT,
  `username`               VARCHAR(100) NOT NULL UNIQUE,
  `password`               VARCHAR(255) NOT NULL,
  `fullname`               VARCHAR(200) NOT NULL,
  `type`                   VARCHAR(50)  NOT NULL,
  `management`             INT,
  `email_address`          VARCHAR(200),
  `viewcrewcontactdetails` TINYINT(1)   NOT NULL DEFAULT 0,
  `viewcreatecontract`     TINYINT(1)   NOT NULL DEFAULT 0,
  `disable_user`           TINYINT(1)   NOT NULL DEFAULT 0,
  `restrict_pw`            TINYINT(1)   NOT NULL DEFAULT 0,
  `session_id`             VARCHAR(200),
  `date_time_logged_in`    DATETIME,
  `date_password_reset`    DATETIME,
  `date_added`             DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_usr_mgmt` FOREIGN KEY (`management`) REFERENCES `tbl_management`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_user_assigned_vessel` (
  `id`            INT         NOT NULL AUTO_INCREMENT,
  `user_id`       INT         NOT NULL,
  `vessel_id`     INT         NOT NULL,
  `principal_id`  INT,
  `management_id` INT,
  `owner_id`      INT,
  `status`        VARCHAR(20) NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_uav_uid`  FOREIGN KEY (`user_id`)       REFERENCES `tbl_users`(`id`),
  CONSTRAINT `fk_uav_vsl`  FOREIGN KEY (`vessel_id`)     REFERENCES `tbl_vessels`(`id`),
  CONSTRAINT `fk_uav_prin` FOREIGN KEY (`principal_id`)  REFERENCES `tbl_principals`(`id`),
  CONSTRAINT `fk_uav_mgmt` FOREIGN KEY (`management_id`) REFERENCES `tbl_management`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_user_access_list` (
  `id`          INT          NOT NULL AUTO_INCREMENT,
  `description` VARCHAR(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_user_access` (
  `id`             INT         NOT NULL AUTO_INCREMENT,
  `Access_ID`      INT         NOT NULL,
  `UserType_ID`    INT         NOT NULL,
  `CustomizedUser` INT         NOT NULL DEFAULT 0,
  `Access_type`    VARCHAR(50) NOT NULL DEFAULT 'Allow',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_ua_acc`  FOREIGN KEY (`Access_ID`)   REFERENCES `tbl_user_access_list`(`id`),
  CONSTRAINT `fk_ua_utyp` FOREIGN KEY (`UserType_ID`) REFERENCES `tbl_user_type`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `tbl_activity_log` (
  `id`         INT          NOT NULL AUTO_INCREMENT,
  `user_id`    INT,
  `activity`   TEXT         NOT NULL,
  `fullname`   VARCHAR(200),
  `category`   VARCHAR(100),
  `date_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_address` VARCHAR(50),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_log_uid` FOREIGN KEY (`user_id`) REFERENCES `tbl_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===================== APPLICANT LINK ========================
CREATE TABLE IF NOT EXISTS `tbl_applicant_generated_link` (
  `id`               INT          NOT NULL AUTO_INCREMENT,
  `fullname`         VARCHAR(200) NOT NULL,
  `email`            VARCHAR(200) NOT NULL,
  `position_applied` VARCHAR(100),
  `validity`         DATETIME,
  `status`           VARCHAR(20)  NOT NULL DEFAULT 'Active',
  `date_generated`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_date_access` DATETIME,
  `generated_by`     INT,
  `link_token`       VARCHAR(1000),
  `personnel_id`     INT,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_agl_uid` FOREIGN KEY (`generated_by`) REFERENCES `tbl_users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
SET SQL_MODE=@OLD_SQL_MODE;
