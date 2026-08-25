-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: ummi_crew
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `tbl_activity_log`
--

DROP TABLE IF EXISTS `tbl_activity_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_activity_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `activity` text NOT NULL,
  `fullname` varchar(200) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `date_time` datetime NOT NULL DEFAULT current_timestamp(),
  `ip_address` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_log_uid` (`user_id`),
  CONSTRAINT `fk_log_uid` FOREIGN KEY (`user_id`) REFERENCES `tbl_users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=754 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_activity_log`
--

LOCK TABLES `tbl_activity_log` WRITE;
/*!40000 ALTER TABLE `tbl_activity_log` DISABLE KEYS */;
INSERT INTO `tbl_activity_log` VALUES (1,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 22:21:55','::1'),(2,NULL,'Failed Login Attempt demo.superadmin','','Login','2026-08-12 22:26:22','::1'),(3,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 22:26:30','::1'),(4,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 22:28:46','::1'),(5,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 22:28:54','::1'),(6,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 22:28:54','::1'),(7,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 22:30:31','::1'),(8,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 22:30:31','::1'),(9,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 22:30:34','::1'),(10,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 22:30:35','::1'),(11,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 22:30:44','::1'),(12,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 22:30:47','::1'),(13,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 22:31:11','::1'),(14,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 22:31:11','::1'),(15,2,'Logged Out Super Admin Demo','Super Admin Demo','Login','2026-08-12 22:33:25','::1'),(16,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 22:39:39','::1'),(17,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 22:39:47','::1'),(18,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 22:39:47','::1'),(19,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 22:47:46','::1'),(20,2,'Logged Out Super Admin Demo','Super Admin Demo','Login','2026-08-12 22:47:49','::1'),(21,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-12 22:47:56','::1'),(22,4,'Logged Out Applicant Demo','Applicant Demo','Login','2026-08-12 22:48:21','::1'),(23,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-12 22:48:26','::1'),(24,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-12 22:48:32','::1'),(25,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-12 22:48:32','::1'),(26,1,'Logged Out Manning Staff Demo','Manning Staff Demo','Login','2026-08-12 22:48:48','::1'),(27,3,'Logged In Principal Demo [PRINCIPAL]','Principal Demo','Login','2026-08-12 22:48:58','::1'),(28,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 23:19:05','::1'),(29,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:19:20','::1'),(30,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:19:20','::1'),(31,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:19:21','::1'),(32,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:19:21','::1'),(33,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:20:00','::1'),(34,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:20:00','::1'),(35,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:21:06','::1'),(36,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:21:06','::1'),(37,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 23:26:41','::1'),(38,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:26:46','::1'),(39,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:26:46','::1'),(40,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:26:58','::1'),(41,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:26:58','::1'),(42,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:26:59','::1'),(43,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:27:00','::1'),(44,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:27:06','::1'),(45,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:27:08','::1'),(46,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-12 23:27:17','::1'),(47,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-12 23:27:17','::1'),(48,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 23:36:40','::1'),(49,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:36:42','::1'),(50,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:36:42','::1'),(51,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 23:45:33','::1'),(52,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-12 23:45:35','::1'),(53,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-12 23:45:35','::1'),(54,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:45:37','::1'),(55,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:45:37','::1'),(56,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-12 23:45:38','::1'),(57,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:45:49','::1'),(58,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:45:49','::1'),(59,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-12 23:45:54','::1'),(60,2,'Logged Out Super Admin Demo','Super Admin Demo','Login','2026-08-12 23:45:59','::1'),(61,3,'Logged In Principal Demo [PRINCIPAL]','Principal Demo','Login','2026-08-12 23:46:04','::1'),(62,3,'Visited Crew Search','Principal Demo','QueryCrew','2026-08-12 23:46:04','::1'),(63,3,'Searched   Status:ACTIVE Rank:ALL','Principal Demo','QueryCrew','2026-08-12 23:46:04','::1'),(64,3,'Viewed Profile 9','Principal Demo','ProfileViewer','2026-08-12 23:46:07','::1'),(65,3,'Logged Out Principal Demo','Principal Demo','Login','2026-08-12 23:46:21','::1'),(66,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-12 23:46:25','::1'),(67,4,'Logged Out Applicant Demo','Applicant Demo','Login','2026-08-12 23:46:31','::1'),(68,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-12 23:46:35','::1'),(69,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-12 23:46:36','::1'),(70,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-12 23:46:36','::1'),(71,1,'Visited Personnel File','Manning Staff Demo','PersonnelFile','2026-08-12 23:46:39','::1'),(72,1,'Generated COE | Personnel COE | PDS-ID: 4','Manning Staff Demo','COE','2026-08-12 23:46:41','::1'),(73,1,'Logged Out Manning Staff Demo','Manning Staff Demo','Login','2026-08-12 23:47:01','::1'),(74,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 23:47:04','::1'),(75,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:47:05','::1'),(76,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:47:05','::1'),(77,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-12 23:47:07','::1'),(78,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-12 23:47:10','::1'),(79,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-12 23:47:10','::1'),(80,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:47:12','::1'),(81,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:47:12','::1'),(82,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-12 23:47:15','::1'),(83,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:48:39','::1'),(84,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:48:39','::1'),(85,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:53:16','::1'),(86,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:53:16','::1'),(87,2,'Viewed Profile 15','Super Admin Demo','ProfileViewer','2026-08-12 23:53:17','::1'),(88,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-12 23:53:24','::1'),(89,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-12 23:53:24','::1'),(90,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:53:29','::1'),(91,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:53:29','::1'),(92,2,'Viewed Profile 15','Super Admin Demo','ProfileViewer','2026-08-12 23:53:31','::1'),(93,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-12 23:53:38','::1'),(94,2,'Logged Out Super Admin Demo','Super Admin Demo','Login','2026-08-12 23:53:49','::1'),(95,3,'Logged In Principal Demo [PRINCIPAL]','Principal Demo','Login','2026-08-12 23:53:53','::1'),(96,3,'Visited Crew Search','Principal Demo','QueryCrew','2026-08-12 23:53:53','::1'),(97,3,'Searched   Status:ACTIVE Rank:ALL','Principal Demo','QueryCrew','2026-08-12 23:53:53','::1'),(98,3,'Visited Crew Search','Principal Demo','QueryCrew','2026-08-12 23:54:00','::1'),(99,3,'Searched   Status:ACTIVE Rank:ALL','Principal Demo','QueryCrew','2026-08-12 23:54:00','::1'),(100,3,'Attempted to access restricted page /Applicant/ApplicantPool.aspx','Principal Demo','Security','2026-08-12 23:54:02','::1'),(101,3,'Logged Out Principal Demo','Principal Demo','Login','2026-08-12 23:54:06','::1'),(102,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-12 23:54:10','::1'),(104,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-12 23:56:10','::1'),(105,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-12 23:56:12','::1'),(106,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-12 23:56:12','::1'),(107,1,'Hired Applicant | Changed status to Active | PDS-ID: 16','Manning Staff Demo','ApplicantPool','2026-08-12 23:56:25','::1'),(108,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-12 23:56:25','::1'),(109,1,'Logged Out Manning Staff Demo','Manning Staff Demo','Login','2026-08-12 23:56:29','::1'),(110,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-12 23:56:33','::1'),(111,4,'Logged Out Applicant Demo','Applicant Demo','Login','2026-08-12 23:56:37','::1'),(112,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 23:57:00','::1'),(113,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-12 23:57:02','::1'),(114,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-12 23:57:02','::1'),(115,2,'Generated Applicant Link Cruz, Angelo Bernardo | nealpblo@gmail.com','Super Admin Demo','ApplicantPool','2026-08-12 23:57:27','::1'),(116,4,'Accessed encoding link Cruz, Angelo Bernardo','Cruz, Angelo Bernardo','ApplicantLink','2026-08-12 23:57:29','::1'),(117,NULL,'Attempted to access restricted page /Applicant/ApplicantPool.aspx','Cruz, Angelo Bernardo','Security','2026-08-12 23:57:50','::1'),(118,NULL,'Logged Out Cruz, Angelo Bernardo','Cruz, Angelo Bernardo','Login','2026-08-12 23:57:56','::1'),(119,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-12 23:58:02','::1'),(120,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-12 23:58:03','::1'),(121,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-13 00:00:24','::1'),(122,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-13 00:00:24','::1'),(123,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-13 00:00:27','::1'),(124,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-13 00:00:27','::1'),(125,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-13 00:00:37','::1'),(126,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-13 00:00:37','::1'),(127,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-13 00:00:51','::1'),(128,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-13 00:00:53','::1'),(129,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-13 00:00:57','::1'),(130,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-13 00:00:58','::1'),(131,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-13 00:01:05','::1'),(132,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-13 00:01:05','::1'),(133,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-13 07:30:44','::1'),(134,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-13 07:30:47','::1'),(135,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-13 07:30:47','::1'),(136,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-13 07:33:11','::1'),(137,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-13 07:33:14','::1'),(138,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-13 07:33:14','::1'),(139,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-13 07:35:49','127.0.0.1'),(140,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-13 07:35:51','::1'),(141,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-13 07:35:51','::1'),(142,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-13 07:35:56','::1'),(143,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-13 07:36:07','::1'),(144,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-13 07:36:20','::1'),(145,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-15 20:43:29','::1'),(146,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-15 20:43:35','::1'),(147,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-15 20:43:35','::1'),(148,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-15 20:43:43','::1'),(149,2,'Generated COE | Personnel COE | PDS-ID: 1','Super Admin Demo','COE','2026-08-15 20:43:51','::1'),(150,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-18 02:57:06','::1'),(151,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-18 02:57:10','::1'),(152,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-18 02:57:10','::1'),(153,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-18 02:57:14','::1'),(154,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-21 05:36:37','::1'),(155,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-21 05:36:49','::1'),(156,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-21 05:37:09','::1'),(157,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 05:37:09','::1'),(158,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-21 05:37:12','::1'),(159,2,'Printed Personnel Data Sheet Bautista, Ernesto Cruz','Super Admin Demo','Print','2026-08-21 05:37:15','::1'),(160,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-21 05:37:20','::1'),(161,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-21 05:38:58','::1'),(162,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 05:38:58','::1'),(163,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-21 05:41:41','::1'),(164,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-21 06:16:57','::1'),(165,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-21 06:17:00','::1'),(166,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-21 06:19:53','::1'),(167,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-21 06:19:56','::1'),(168,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:19:56','::1'),(169,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-21 06:20:15','::1'),(170,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:20:15','::1'),(171,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-21 06:20:18','::1'),(172,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:20:18','::1'),(173,2,'Hired Applicant | Changed status to Active | PDS-ID: 15','Super Admin Demo','ApplicantPool','2026-08-21 06:20:23','::1'),(174,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:20:23','::1'),(175,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-21 06:20:35','::1'),(176,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-21 06:20:43','::1'),(177,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:20:43','::1'),(178,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-21 06:20:45','::1'),(179,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-21 06:22:54','::1'),(180,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-21 06:22:57','::1'),(181,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:22:57','::1'),(182,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-21 06:22:59','::1'),(183,2,'Printed Personnel Data Sheet Bautista, Ernesto Cruz','Super Admin Demo','Print','2026-08-21 06:26:23','::1'),(184,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-21 06:27:23','::1'),(185,2,'Generated COE | Personnel COE | PDS-ID: 13','Super Admin Demo','COE','2026-08-21 06:28:16','::1'),(186,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-21 06:28:19','::1'),(187,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-21 06:28:31','::1'),(188,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:28:31','::1'),(189,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:28:35','::1'),(190,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:28:36','::1'),(191,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:28:39','::1'),(192,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:28:45','::1'),(193,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:28:48','::1'),(194,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:28:50','::1'),(195,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-21 06:29:28','::1'),(196,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:29:28','::1'),(197,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:29:34','::1'),(198,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:29:35','::1'),(199,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:29:52','::1'),(200,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:29:53','::1'),(201,2,'Resent Applicant Link Cruz, Angelo Bernardo | nealpblo@gmail.com','Super Admin Demo','ApplicantPool','2026-08-21 06:29:58','::1'),(202,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-21 06:30:18','::1'),(203,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:30:18','::1'),(204,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-21 06:30:20','::1'),(205,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-21 06:30:20','::1'),(206,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-21 06:30:23','::1'),(207,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:30:23','::1'),(208,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-21 06:49:00','::1'),(209,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-21 06:49:02','::1'),(210,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:49:02','::1'),(211,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-21 06:49:18','::1'),(212,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:49:18','::1'),(213,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:49:21','::1'),(214,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:49:22','::1'),(215,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-21 06:49:23','::1'),(216,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-23 21:05:54','::1'),(217,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-23 21:07:12','::1'),(218,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:07:12','::1'),(219,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-23 21:07:53','::1'),(220,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:07:53','::1'),(221,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-23 21:11:09','::1'),(222,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-23 21:13:15','::1'),(223,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:13:15','::1'),(224,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-23 21:15:45','::1'),(225,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:15:45','::1'),(226,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-23 21:16:35','::1'),(227,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-23 21:16:44','::1'),(228,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:16:44','::1'),(229,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-23 21:17:59','::1'),(230,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:17:59','::1'),(231,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:18:26','::1'),(232,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:18:26','::1'),(233,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:18:47','::1'),(234,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:00','::1'),(235,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:10','::1'),(236,2,'Searched   Status:ON BOARD Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:12','::1'),(237,2,'Searched   Status:INACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:13','::1'),(238,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:14','::1'),(239,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:14','::1'),(240,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:15','::1'),(241,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:16','::1'),(242,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:17','::1'),(243,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:21','::1'),(244,2,'Searched Perez  Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:32','::1'),(245,2,'Searched Perez  Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-23 21:20:32','::1'),(246,2,'Viewed Profile 16','Super Admin Demo','ProfileViewer','2026-08-23 21:21:27','::1'),(247,NULL,'Failed Login Attempt demo.superadmin','','Login','2026-08-25 01:40:14','::1'),(248,NULL,'Failed Login Attempt demo.superadmin','','Login','2026-08-25 01:40:17','::1'),(249,NULL,'Failed Login Attempt demo.superadmin','','Login','2026-08-25 01:40:21','::1'),(250,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 01:40:24','::1'),(251,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 01:41:50','::1'),(252,NULL,'Failed Login Attempt demo.superadmin','','Login','2026-08-25 01:43:00','::1'),(253,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 01:43:04','::1'),(254,NULL,'Failed Login Attempt demo.superadmin','','Login','2026-08-25 02:39:27','::1'),(255,NULL,'Failed Login Attempt demo.superadmin','','Login','2026-08-25 02:39:30','::1'),(256,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 02:39:34','::1'),(257,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 02:39:40','::1'),(258,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 02:39:40','::1'),(259,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 02:48:45','::1'),(260,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 02:48:45','::1'),(261,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 02:49:12','::1'),(262,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 02:49:12','::1'),(263,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 02:49:19','::1'),(264,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 02:49:19','::1'),(265,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 02:49:34','::1'),(266,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 02:49:34','::1'),(267,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 02:55:20','::1'),(268,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 02:55:20','::1'),(269,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 02:56:28','::1'),(270,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 02:56:32','::1'),(271,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 02:56:33','::1'),(272,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 02:56:47','::1'),(273,2,'Viewed Profile 6','Super Admin Demo','ProfileViewer','2026-08-25 02:56:54','::1'),(274,NULL,'Failed Login Attempt demo.principal','','Login','2026-08-25 02:57:51','::1'),(275,3,'Logged In Principal Demo [PRINCIPAL]','Principal Demo','Login','2026-08-25 02:58:15','::1'),(276,3,'Visited Crew Search','Principal Demo','QueryCrew','2026-08-25 02:58:15','::1'),(277,3,'Searched   Status:ACTIVE Rank:ALL','Principal Demo','QueryCrew','2026-08-25 02:58:15','::1'),(278,3,'Visited Crew Search','Principal Demo','QueryCrew','2026-08-25 02:58:24','::1'),(279,3,'Searched   Status:ACTIVE Rank:ALL','Principal Demo','QueryCrew','2026-08-25 02:58:24','::1'),(280,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 02:59:51','::1'),(281,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 02:59:51','::1'),(282,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:14','::1'),(283,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:16','::1'),(284,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:19','::1'),(285,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:19','::1'),(286,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:20','::1'),(287,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:23','::1'),(288,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:00:24','::1'),(289,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:24','::1'),(290,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:26','::1'),(291,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:29','::1'),(292,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:30','::1'),(293,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:32','::1'),(294,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:33','::1'),(295,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:34','::1'),(296,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:34','::1'),(297,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:37','::1'),(298,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:38','::1'),(299,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:43','::1'),(300,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:44','::1'),(301,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:46','::1'),(302,2,'Searched perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:53','::1'),(303,2,'Searched perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:53','::1'),(304,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:55','::1'),(305,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:56','::1'),(306,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:00:56','::1'),(307,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:01:39','::1'),(308,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:01:39','::1'),(309,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:02:40','::1'),(310,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:02:40','::1'),(311,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:04:12','::1'),(312,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:04:12','::1'),(313,2,'Searched Perez  Status:INACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:07:49','::1'),(314,2,'Searched Perez  Status:INACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:07:49','::1'),(315,2,'Searched Perez  Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:07:50','::1'),(316,2,'Searched Perez  Status:ON VACATION Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:07:51','::1'),(317,2,'Searched Perez  Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:07:52','::1'),(318,2,'Searched Perez  Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:07:53','::1'),(319,2,'Searched Perez  Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:07:58','::1'),(320,2,'Searched Perez  Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:28','::1'),(321,2,'Searched Perez  Status:ON BOARD Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:31','::1'),(322,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:32','::1'),(323,2,'Searched Perez  Status:APPLICANT Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:34','::1'),(324,2,'Searched Perez  Status:INACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:34','::1'),(325,2,'Searched Perez  Status:ON BOARD Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:35','::1'),(326,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:36','::1'),(327,2,'Searched Perez  Status:ON BOARD Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:37','::1'),(328,2,'Searched Perez  Status:APPLICANT Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:38','::1'),(329,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:39','::1'),(330,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:40','::1'),(331,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:43','::1'),(332,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:43','::1'),(333,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:44','::1'),(334,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:45','::1'),(335,2,'Searched Perez  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:46','::1'),(336,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:08:52','::1'),(337,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:09:03','::1'),(338,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:09:10','::1'),(339,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:09:11','::1'),(340,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:09:12','::1'),(341,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:09:14','::1'),(342,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:26','::1'),(343,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:31','::1'),(344,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:31','::1'),(345,2,'Searched Perez  Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:38','::1'),(346,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:41','::1'),(347,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:43','::1'),(348,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:47','::1'),(349,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:50','::1'),(350,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:51','::1'),(351,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:51','::1'),(352,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:14:56','::1'),(353,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:15:03','::1'),(354,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:15:04','::1'),(355,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:15:07','::1'),(356,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:15:07','::1'),(357,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:15:54','::1'),(358,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:15:55','::1'),(359,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:15:56','::1'),(360,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:15:57','::1'),(361,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:15:58','::1'),(362,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:15:59','::1'),(363,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:00','::1'),(364,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:01','::1'),(365,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:02','::1'),(366,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:03','::1'),(367,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:05','::1'),(368,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:06','::1'),(369,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:13','::1'),(370,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:15','::1'),(371,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:16','::1'),(372,2,'Searched PEREZ  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:29','::1'),(373,2,'Searched PEREZ  Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:16:29','::1'),(374,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:19:26','::1'),(375,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:19:27','::1'),(376,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:19:33','::1'),(377,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:19:50','::1'),(378,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:19:52','::1'),(379,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:19:59','::1'),(380,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:20:11','::1'),(381,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:20:33','::1'),(382,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:22:49','::1'),(383,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:22:55','::1'),(384,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-25 03:22:57','::1'),(385,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 03:23:07','::1'),(386,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 03:23:07','::1'),(387,2,'Viewed Profile 14','Super Admin Demo','ProfileViewer','2026-08-25 03:23:10','::1'),(388,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:24:31','::1'),(389,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:24:32','::1'),(390,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:25:12','::1'),(391,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:25:52','::1'),(392,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:25:54','::1'),(393,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:25:55','::1'),(394,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:32:24','::1'),(395,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:32:24','::1'),(396,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:39:53','::1'),(397,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:39:55','::1'),(398,2,'Searched   Status:INACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:39:56','::1'),(399,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:39:57','::1'),(400,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:39:58','::1'),(401,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:40:48','::1'),(402,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:40:55','::1'),(403,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:40:56','::1'),(404,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:41:00','::1'),(405,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:42:54','::1'),(406,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:13','::1'),(407,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:15','::1'),(408,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:16','::1'),(409,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:17','::1'),(410,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:18','::1'),(411,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:19','::1'),(412,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:21','::1'),(413,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:21','::1'),(414,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:22','::1'),(415,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:24','::1'),(416,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:25','::1'),(417,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:27','::1'),(418,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:28','::1'),(419,2,'Exported Crew List Status:ALL|Rank:ALL|Province:ALL|Vessel:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:29','::1'),(420,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:44:29','::1'),(421,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 03:46:16','127.0.0.1'),(422,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:46:21','::1'),(423,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:46:21','::1'),(424,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 03:46:30','127.0.0.1'),(425,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 03:46:32','127.0.0.1'),(426,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 03:46:32','127.0.0.1'),(427,1,'Logged Out Manning Staff Demo','Manning Staff Demo','Login','2026-08-25 03:46:38','127.0.0.1'),(428,3,'Logged In Principal Demo [PRINCIPAL]','Principal Demo','Login','2026-08-25 03:46:42','127.0.0.1'),(429,3,'Visited Crew Search','Principal Demo','QueryCrew','2026-08-25 03:46:42','127.0.0.1'),(430,3,'Searched   Status:ACTIVE Rank:ALL','Principal Demo','QueryCrew','2026-08-25 03:46:42','127.0.0.1'),(431,3,'Attempted to access restricted page /Applicant/ApplicantPool.aspx','Principal Demo','Security','2026-08-25 03:46:45','127.0.0.1'),(432,3,'Visited Crew Search','Principal Demo','QueryCrew','2026-08-25 03:46:46','127.0.0.1'),(433,3,'Searched   Status:ACTIVE Rank:ALL','Principal Demo','QueryCrew','2026-08-25 03:46:46','127.0.0.1'),(434,3,'Logged Out Principal Demo','Principal Demo','Login','2026-08-25 03:46:49','127.0.0.1'),(435,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:46:59','::1'),(436,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:46:59','::1'),(437,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-25 03:47:11','::1'),(438,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-25 03:47:12','::1'),(439,2,'Viewed Profile 14','Super Admin Demo','ProfileViewer','2026-08-25 03:49:29','::1'),(440,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:49:32','::1'),(441,2,'Viewed Profile 10','Super Admin Demo','ProfileViewer','2026-08-25 03:49:32','::1'),(442,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 03:50:10','::1'),(443,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 03:50:10','::1'),(444,2,'Logged Out Super Admin Demo','Super Admin Demo','Login','2026-08-25 03:50:18','::1'),(445,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 03:50:22','::1'),(446,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 03:50:23','::1'),(447,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 03:50:23','::1'),(448,1,'Searched Cruz  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 03:51:35','::1'),(449,1,'Searched Cruz  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 03:51:35','::1'),(450,1,'Viewed Profile 1','Manning Staff Demo','ProfileViewer','2026-08-25 03:51:41','::1'),(451,1,'Logged Out Manning Staff Demo','Manning Staff Demo','Login','2026-08-25 03:52:18','::1'),(452,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 03:53:00','::1'),(453,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 03:53:10','::1'),(454,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 03:53:10','::1'),(455,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:53:33','::1'),(456,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:53:33','::1'),(457,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 03:53:52','::1'),(458,2,'Viewed Profile 14','Super Admin Demo','ProfileViewer','2026-08-25 03:53:55','::1'),(459,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:54:52','::1'),(460,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:54:52','::1'),(461,2,'Searched   Status:ON BOARD Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:55:04','::1'),(462,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-25 03:57:30','::1'),(463,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-25 03:57:40','::1'),(464,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 03:58:32','::1'),(465,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 03:58:32','::1'),(466,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-25 03:58:45','::1'),(467,2,'Viewed Profile 9','Super Admin Demo','ProfileViewer','2026-08-25 04:01:15','::1'),(468,2,'Viewed Profile 13','Super Admin Demo','ProfileViewer','2026-08-25 04:01:16','::1'),(469,2,'Viewed Profile 3','Super Admin Demo','ProfileViewer','2026-08-25 04:01:21','::1'),(470,2,'Viewed Profile 8','Super Admin Demo','ProfileViewer','2026-08-25 04:01:21','::1'),(471,2,'Viewed Profile 3','Super Admin Demo','ProfileViewer','2026-08-25 04:03:39','::1'),(472,2,'Viewed Profile 8','Super Admin Demo','ProfileViewer','2026-08-25 04:03:39','::1'),(473,2,'Viewed Profile 14','Super Admin Demo','ProfileViewer','2026-08-25 04:03:40','::1'),(474,2,'Printed Personnel Data Sheet Bautista, Ernesto Cruz','Super Admin Demo','Print','2026-08-25 04:09:56','::1'),(475,2,'Viewed Profile 4','Super Admin Demo','ProfileViewer','2026-08-25 04:11:07','::1'),(476,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 04:14:56','::1'),(477,1,'Viewed Profile 4','Manning Staff Demo','ProfileViewer','2026-08-25 04:14:59','::1'),(478,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 04:15:30','::1'),(479,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:15:30','::1'),(480,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:16:53','::1'),(481,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:16:56','::1'),(482,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:16:59','::1'),(483,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:17:05','::1'),(484,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:17:18','::1'),(485,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:17:19','::1'),(486,2,'Viewed Profile 14','Super Admin Demo','ProfileViewer','2026-08-25 04:18:20','::1'),(487,2,'Viewed Profile 14','Super Admin Demo','ProfileViewer','2026-08-25 04:18:45','::1'),(488,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 04:18:58','::1'),(489,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:18:58','::1'),(490,1,'Logged Out Manning Staff Demo','Manning Staff Demo','Login','2026-08-25 04:19:50','::1'),(491,NULL,'Failed Login Attempt demo.applicant','','Login','2026-08-25 04:19:54','::1'),(492,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-25 04:19:57','::1'),(494,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 04:23:57','::1'),(495,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 04:24:04','::1'),(496,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:24:04','::1'),(497,4,'Attempted to access restricted page /Crew/ProfileViewer.aspx?ID=qvnrrNic0XVrAgA_amq5IBjIL3t47IpdJQY0_4Nj8VU%7e&Type=NmnFcbQtd4aNC9_ynOWncZ3TdoHBRWNprZOLKFbO3XQ%7e','Applicant Demo','Security','2026-08-25 04:24:19','::1'),(499,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 04:24:50','::1'),(500,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:24:50','::1'),(501,2,'Generated Applicant Link Isaac, Establo | isaac@gmail.com','Super Admin Demo','ApplicantPool','2026-08-25 04:25:41','::1'),(505,NULL,'Attempted to access restricted page /Applicant/ApplicantPool.aspx','Isaac, Establo','Security','2026-08-25 04:27:20','::1'),(506,NULL,'Logged Out Isaac, Establo','Isaac, Establo','Login','2026-08-25 04:27:24','::1'),(507,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 04:27:27','::1'),(508,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 04:27:29','::1'),(509,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:27:29','::1'),(510,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 04:28:42','::1'),(511,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:28:42','::1'),(512,2,'Generated Applicant Link Neal Pablo | nealpblo@gmail.com','Super Admin Demo','ApplicantPool','2026-08-25 04:28:52','::1'),(513,2,'Sent Applicant Link Email Neal Pablo | nealpblo@gmail.com','Super Admin Demo','ApplicantPool','2026-08-25 04:28:55','::1'),(514,2,'Sent Applicant Link Email Neal Pablo | nealpblo@gmail.com','Super Admin Demo','ApplicantPool','2026-08-25 04:28:56','::1'),(515,2,'Sent Applicant Link Email Neal Pablo | nealpblo@gmail.com','Super Admin Demo','ApplicantPool','2026-08-25 04:28:59','::1'),(516,2,'Sent Applicant Link Email Neal Pablo | nealpblo@gmail.com','Super Admin Demo','ApplicantPool','2026-08-25 04:29:06','::1'),(517,2,'Sent Applicant Link Email Neal Pablo | nealpblo@gmail.com','Super Admin Demo','ApplicantPool','2026-08-25 04:29:12','::1'),(518,2,'Sent Applicant Link Email Neal Pablo | nealpblo@gmail.com','Super Admin Demo','ApplicantPool','2026-08-25 04:30:13','::1'),(519,2,'Updated Link Status to Expired LinkID=4','Super Admin Demo','ApplicantPool','2026-08-25 04:34:36','::1'),(520,2,'Updated Link Status to Expired LinkID=6','Super Admin Demo','ApplicantPool','2026-08-25 04:34:41','::1'),(521,2,'Updated Link Status to Expired LinkID=3','Super Admin Demo','ApplicantPool','2026-08-25 04:36:25','::1'),(522,2,'Deleted Link LinkID=5','Super Admin Demo','ApplicantPool','2026-08-25 04:37:40','::1'),(523,2,'Resent Applicant Link Pedro Magsaysay | pedro@email.com','Super Admin Demo','ApplicantPool','2026-08-25 04:39:37','::1'),(524,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 04:40:55','::1'),(525,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:40:55','::1'),(526,2,'Hired Applicant | Changed status to Active | PDS-ID: 14','Super Admin Demo','ApplicantPool','2026-08-25 04:41:04','::1'),(527,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:41:04','::1'),(528,2,'Hired Applicant | Changed status to Active | PDS-ID: 17','Super Admin Demo','ApplicantPool','2026-08-25 04:41:11','::1'),(529,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:41:11','::1'),(530,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 04:41:25','::1'),(531,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:41:25','::1'),(532,2,'Logged Out Super Admin Demo','Super Admin Demo','Login','2026-08-25 04:42:06','::1'),(533,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-25 04:42:11','::1'),(534,4,'Logged Out Applicant Demo','Applicant Demo','Login','2026-08-25 04:42:36','::1'),(535,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 04:42:40','::1'),(536,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-25 04:42:42','::1'),(537,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:42:42','::1'),(538,2,'Hired Applicant | Changed status to Active | PDS-ID: 18','Super Admin Demo','ApplicantPool','2026-08-25 04:42:48','::1'),(539,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-25 04:42:48','::1'),(540,2,'Logged Out Super Admin Demo','Super Admin Demo','Login','2026-08-25 04:42:51','::1'),(541,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-25 04:42:55','::1'),(542,4,'Logged Out Applicant Demo','Applicant Demo','Login','2026-08-25 04:44:37','::1'),(543,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 04:44:41','::1'),(544,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-25 04:44:53','::1'),(545,2,'Visited Personnel File','Super Admin Demo','PersonnelFile','2026-08-25 04:44:58','::1'),(546,2,'Viewed Profile 18','Super Admin Demo','ProfileViewer','2026-08-25 04:44:59','::1'),(547,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-25 04:46:32','::1'),(548,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:46:32','::1'),(549,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:46:37','::1'),(550,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:46:45','::1'),(551,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:46:47','::1'),(552,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:46:57','::1'),(553,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:46:58','::1'),(554,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:46:58','::1'),(555,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:47:00','::1'),(556,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:47:01','::1'),(557,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:47:01','::1'),(558,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:47:32','::1'),(559,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:47:33','::1'),(560,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:47:35','::1'),(561,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:47:35','::1'),(562,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:47:36','::1'),(563,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:47:37','::1'),(564,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-25 04:47:38','::1'),(565,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 20:12:48','::1'),(566,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 20:12:52','::1'),(567,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:12:52','::1'),(568,1,'Searched Perez Jeross Reilan Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:13:12','::1'),(569,1,'Searched Perez Jeross Reilan Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:13:12','::1'),(570,1,'Searched Perez  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:13:17','::1'),(571,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:13:21','::1'),(572,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:13:22','::1'),(573,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 20:17:12','::1'),(574,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 20:18:41','::1'),(575,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:18:41','::1'),(576,1,'Searched Perez Jeross Reilan Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:18:46','::1'),(577,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:18:59','::1'),(578,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:18:59','::1'),(579,1,'Searched   Status:ACTIVE Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:19:14','::1'),(580,1,'Searched Perez  Status:ON BOARD Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:19:37','::1'),(581,1,'Searched Perez  Status:ON BOARD Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:19:37','::1'),(582,1,'Searched Perez  Status:ON BOARD Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:21:01','::1'),(583,1,'Searched Perez  Status:ON BOARD Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:21:01','::1'),(584,1,'Searched Perez  Status:ON BOARD Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:21:02','::1'),(585,1,'Searched Perez  Status:ON BOARD Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:21:03','::1'),(586,1,'Searched Perez  Status:ON BOARD Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:21:04','::1'),(587,1,'Searched Perez  Status:ON BOARD Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:21:37','::1'),(588,1,'Searched Perez  Status:ON BOARD Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:21:37','::1'),(589,1,'Searched Perez  Status:ON BOARD Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:21:37','::1'),(590,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:21:39','::1'),(591,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:21:40','::1'),(592,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 20:24:13','::1'),(593,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:24:13','::1'),(594,1,'Searched Bautista  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:24:21','::1'),(595,1,'Searched Bautista  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:24:39','::1'),(596,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:24:42','::1'),(597,1,'Searched Isaac  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:25:08','::1'),(598,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:25:09','::1'),(599,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:26:46','::1'),(600,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:26:47','::1'),(601,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:26:48','::1'),(602,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:26:49','::1'),(603,1,'Searched Perez  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:28:06','::1'),(604,1,'Searched Perez  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:28:07','::1'),(605,1,'Searched Perez  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:28:07','::1'),(606,1,'Searched Perez  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:28:08','::1'),(607,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:28:09','::1'),(608,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 20:36:29','::1'),(609,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 20:36:31','::1'),(610,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:36:31','::1'),(611,1,'Searched Perez  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:36:40','::1'),(612,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:36:41','::1'),(613,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 20:36:52','::1'),(614,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:36:52','::1'),(615,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 20:40:59','::1'),(616,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 20:41:02','::1'),(617,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:41:02','::1'),(618,1,'Searched Perez  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:41:14','::1'),(619,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:41:21','::1'),(620,1,'Exported Crew List Status:ALL|Rank:ALL|Province:ALL|Vessel:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:41:47','::1'),(621,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 20:44:21','::1'),(622,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:44:21','::1'),(623,1,'Searched Perez  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:44:43','::1'),(624,1,'Searched Perez  Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:44:43','::1'),(625,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 20:44:50','::1'),(626,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:44:50','::1'),(627,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 20:50:10','::1'),(628,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 20:50:13','::1'),(629,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 20:50:13','::1'),(630,7,'Logged In Vessel Owner Demo [VESSEL_OWNER]','Vessel Owner Demo','Login','2026-08-25 22:19:15','::1'),(631,7,'Visited Crew Search','Vessel Owner Demo','QueryCrew','2026-08-25 22:19:16','::1'),(632,7,'Searched   Status:ACTIVE Rank:ALL','Vessel Owner Demo','QueryCrew','2026-08-25 22:19:16','::1'),(633,7,'Logged Out Vessel Owner Demo','Vessel Owner Demo','Login','2026-08-25 22:19:25','::1'),(634,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-25 22:19:38','::1'),(635,2,'Logged Out Super Admin Demo','Super Admin Demo','Login','2026-08-25 22:19:49','::1'),(636,NULL,'Failed Login Attempt demo.admin','','Login','2026-08-25 22:20:00','::1'),(637,6,'Logged In Admin Demo [ADMIN]','Admin Demo','Login','2026-08-25 22:20:07','::1'),(638,6,'Logged Out Admin Demo','Admin Demo','Login','2026-08-25 22:20:21','::1'),(639,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 22:20:30','::1'),(640,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 22:20:35','::1'),(641,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 22:20:35','::1'),(642,1,'Logged Out Manning Staff Demo','Manning Staff Demo','Login','2026-08-25 22:20:48','::1'),(643,5,'Logged In Documentation Officer Demo [DOCUMENTATION_OFFICER]','Documentation Officer Demo','Login','2026-08-25 22:20:55','::1'),(644,5,'Logged Out Documentation Officer Demo','Documentation Officer Demo','Login','2026-08-25 22:20:59','::1'),(645,NULL,'Failed Login Attempt demo.manning','','Login','2026-08-25 22:45:53','::1'),(646,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 22:46:07','::1'),(647,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-25 22:46:16','::1'),(648,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-25 22:46:16','::1'),(649,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 22:46:55','::1'),(650,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-25 22:46:56','::1'),(651,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-25 22:46:56','::1'),(652,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-25 22:48:12','::1'),(653,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-25 22:48:12','::1'),(654,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 22:48:24','::1'),(655,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-25 22:48:27','::1'),(656,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-25 22:48:27','::1'),(657,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 22:50:01','127.0.0.1'),(658,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-25 22:50:04','::1'),(659,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-25 22:50:04','::1'),(660,1,'Viewed Profile 19','Manning Staff Demo','ProfileViewer','2026-08-25 22:50:51','::1'),(661,1,'Generated Applicant Link asdasdsa | 12312312@gmail.com','Manning Staff Demo','ApplicantPool','2026-08-25 22:51:37','::1'),(662,7,'Accessed encoding link asdasdsa','asdasdsa','ApplicantLink','2026-08-25 22:51:53','::1'),(664,1,'Generated Applicant Link asdasdsa | 12312312@gmail.com','Manning Staff Demo','ApplicantPool','2026-08-25 22:53:30','::1'),(665,1,'Resent Applicant Link asdasdsa | 12312312@gmail.com','Manning Staff Demo','ApplicantPool','2026-08-25 22:53:44','::1'),(666,1,'Resent Applicant Link asdasdsa | 12312312@gmail.com','Manning Staff Demo','ApplicantPool','2026-08-25 22:54:07','::1'),(667,1,'Resent Applicant Link asdasdsa | 12312312@gmail.com','Manning Staff Demo','ApplicantPool','2026-08-25 22:56:55','::1'),(668,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 22:59:24','::1'),(669,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-25 22:59:28','::1'),(670,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-25 22:59:28','::1'),(671,1,'Resent Applicant Link asdasdsa | 12312312@gmail.com','Manning Staff Demo','ApplicantPool','2026-08-25 22:59:32','::1'),(672,1,'Resent Applicant Link asdasdsa | 12312312@gmail.com','Manning Staff Demo','ApplicantPool','2026-08-25 23:00:32','::1'),(674,NULL,'Logged Out asdasdsa','asdasdsa','Login','2026-08-25 23:03:34','::1'),(675,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 23:03:36','::1'),(676,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-25 23:03:37','::1'),(677,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-25 23:03:37','::1'),(678,1,'Resent Applicant Link asdasdsa | 12312312@gmail.com','Manning Staff Demo','ApplicantPool','2026-08-25 23:03:42','::1'),(679,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 23:04:48','::1'),(680,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 23:04:48','::1'),(681,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 23:08:06','::1'),(682,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 23:08:09','::1'),(683,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 23:08:09','::1'),(684,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-25 23:08:13','::1'),(685,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-25 23:08:13','::1'),(686,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 23:08:15','::1'),(687,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 23:08:15','::1'),(688,1,'Logged In Manning Staff Demo [MANNING_STAFF]','Manning Staff Demo','Login','2026-08-25 23:09:14','::1'),(689,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-25 23:09:18','::1'),(690,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-25 23:09:18','::1'),(691,1,'Visited Applicant Pool','Manning Staff Demo','ApplicantPool','2026-08-25 23:09:21','::1'),(692,1,'Searched Applicants  ','Manning Staff Demo','ApplicantPool','2026-08-25 23:09:21','::1'),(693,1,'Visited Crew Search','Manning Staff Demo','QueryCrew','2026-08-25 23:09:23','::1'),(694,1,'Searched   Status:ALL Rank:ALL','Manning Staff Demo','QueryCrew','2026-08-25 23:09:23','::1'),(695,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-26 03:03:57','::1'),(697,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-26 03:05:25','::1'),(698,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-26 03:09:25','::1'),(699,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-26 03:13:01','::1'),(700,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-26 03:15:08','::1'),(701,4,'Logged In Applicant Demo [APPLICANT]','Applicant Demo','Login','2026-08-26 03:18:25','::1'),(702,4,'Logged Out Applicant Demo','Applicant Demo','Login','2026-08-26 03:18:55','::1'),(703,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-26 03:19:09','::1'),(704,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-26 03:19:12','::1'),(705,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-26 03:19:12','::1'),(706,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-26 03:29:50','::1'),(707,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-26 03:29:50','::1'),(708,2,'Visited Applicant Pool','Super Admin Demo','ApplicantPool','2026-08-26 03:29:55','::1'),(709,2,'Searched Applicants  ','Super Admin Demo','ApplicantPool','2026-08-26 03:29:55','::1'),(710,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 03:48:48','::1'),(711,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 03:48:48','::1'),(712,2,'Logged In Super Admin Demo [SUPER_ADMIN]','Super Admin Demo','Login','2026-08-26 04:09:37','::1'),(713,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 04:09:40','::1'),(714,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:09:40','::1'),(715,2,'Searched   Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:09:55','::1'),(716,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 04:14:58','::1'),(717,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:14:58','::1'),(718,2,'Searched   Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:15:01','::1'),(719,2,'Exported Releasing Checklist Vessel:MT MINDANAO Batch:BATCH-001','Super Admin Demo','QueryCrew','2026-08-26 04:20:16','::1'),(720,2,'Printed Releasing Checklist MT MINDANAO | BATCH-001','Super Admin Demo','Print','2026-08-26 04:20:16','::1'),(721,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 04:20:26','::1'),(722,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:20:26','::1'),(723,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 04:20:43','::1'),(724,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:20:43','::1'),(725,2,'Visited CCL VesselID=2','Super Admin Demo','CrewChangeList','2026-08-26 04:20:54','::1'),(726,2,'Searched   Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:23:19','::1'),(727,2,'Exported Releasing Checklist Vessel:MT MINDANAO Batch:BATCH 25','Super Admin Demo','QueryCrew','2026-08-26 04:23:58','::1'),(728,2,'Printed Releasing Checklist MT MINDANAO | BATCH 25','Super Admin Demo','Print','2026-08-26 04:23:58','::1'),(729,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 04:29:36','::1'),(730,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:29:36','::1'),(731,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:29:55','::1'),(732,2,'Searched   Status:ACTIVE Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:29:59','::1'),(733,2,'Viewed Profile 18','Super Admin Demo','ProfileViewer','2026-08-26 04:30:10','::1'),(734,2,'Searched   Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:30:21','::1'),(735,2,'Visited CCL VesselID=1','Super Admin Demo','CrewChangeList','2026-08-26 04:30:28','::1'),(736,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 04:30:42','::1'),(737,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:30:42','::1'),(738,2,'Searched   Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:30:52','::1'),(739,2,'Searched   Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:30:55','::1'),(740,2,'Searched   Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:30:56','::1'),(741,2,'Searched   Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:30:59','::1'),(742,2,'Searched   Status:LINE UP Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:31:26','::1'),(743,2,'Viewed Profile 1','Super Admin Demo','ProfileViewer','2026-08-26 04:32:59','::1'),(744,2,'Exported Releasing Checklist Vessel:MV PACIFIC DAWN Batch:BATCH','Super Admin Demo','QueryCrew','2026-08-26 04:33:07','::1'),(745,2,'Printed Releasing Checklist MV PACIFIC DAWN | BATCH','Super Admin Demo','Print','2026-08-26 04:33:07','::1'),(746,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 04:33:18','::1'),(747,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:33:18','::1'),(748,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 04:33:18','::1'),(749,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:33:18','::1'),(750,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 04:44:20','::1'),(751,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 04:44:20','::1'),(752,2,'Visited Crew Search','Super Admin Demo','QueryCrew','2026-08-26 05:21:54','::1'),(753,2,'Searched   Status:ALL Rank:ALL','Super Admin Demo','QueryCrew','2026-08-26 05:21:54','::1');
/*!40000 ALTER TABLE `tbl_activity_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_applicant_generated_link`
--

DROP TABLE IF EXISTS `tbl_applicant_generated_link`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_applicant_generated_link` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fullname` varchar(200) NOT NULL,
  `email` varchar(200) NOT NULL,
  `position_applied` varchar(100) DEFAULT NULL,
  `validity` datetime DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  `date_generated` datetime NOT NULL DEFAULT current_timestamp(),
  `last_date_access` datetime DEFAULT NULL,
  `generated_by` int(11) DEFAULT NULL,
  `link_token` varchar(1000) DEFAULT NULL,
  `personnel_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_agl_uid` (`generated_by`),
  CONSTRAINT `fk_agl_uid` FOREIGN KEY (`generated_by`) REFERENCES `tbl_users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_applicant_generated_link`
--

LOCK TABLES `tbl_applicant_generated_link` WRITE;
/*!40000 ALTER TABLE `tbl_applicant_generated_link` DISABLE KEYS */;
INSERT INTO `tbl_applicant_generated_link` VALUES (1,'Pedro Magsaysay','pedro@email.com','AB SEAMAN','2026-08-31 23:59:59','Active','2026-08-01 09:00:00',NULL,1,'DEMO_TOKEN_001',NULL),(2,'Rosa Aguinaldo','rosa@email.com','3RD OFFICER','2026-07-15 23:59:59','Expired','2026-07-01 09:00:00',NULL,1,'DEMO_TOKEN_002',NULL),(3,'Andres Bonifacio Jr.','andres@email.com','OS','2026-09-30 23:59:59','Expired','2026-08-05 10:00:00',NULL,1,'DEMO_TOKEN_003',NULL),(4,'Cruz, Angelo Bernardo','nealpblo@gmail.com','ENGINE CADET','2026-09-11 23:59:00','Expired','2026-08-12 23:57:27','2026-08-12 23:57:29',2,'http://localhost:54776/login.aspx?e=Po13Q5hDBadRctFZ_0PlPXi6iVft4v9yfeuciShnySw%7e',NULL),(6,'Neal Pablo','nealpblo@gmail.com','4TH ENGINEER','2026-08-26 23:59:00','Expired','2026-08-25 04:28:52',NULL,2,'http://localhost:54776/login.aspx?e=u4LUB4ewv10sqq2JHxr-yXCZ6Q6Zg-Ia4oFvxKZ0Wvs%7e',NULL),(7,'asdasdsa','12312312@gmail.com','','2026-08-26 23:59:00','Used','2026-08-25 22:51:37','2026-08-25 22:51:53',1,'http://localhost:54776/login.aspx?e=Jfv4eCdAvCnBxqlJuQT9cmrsp4RJcnZten8jIZnEqV0%7e',20),(8,'asdasdsa','12312312@gmail.com','','2026-08-26 23:59:00','Active','2026-08-25 22:53:30','2026-08-25 23:01:52',1,'http://localhost:54776/login.aspx?e=s9rfeex13NW6GGEG2ZA5UfnO8ZtYKkq3VOE8xWaJn3k%7e',NULL);
/*!40000 ALTER TABLE `tbl_applicant_generated_link` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_cities`
--

DROP TABLE IF EXISTS `tbl_cities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_cities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cities` varchar(100) NOT NULL,
  `province` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_cities_province` (`province`),
  CONSTRAINT `fk_cities_province` FOREIGN KEY (`province`) REFERENCES `tbl_provinces` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_cities`
--

LOCK TABLES `tbl_cities` WRITE;
/*!40000 ALTER TABLE `tbl_cities` DISABLE KEYS */;
INSERT INTO `tbl_cities` VALUES (1,'Manila',1),(2,'Quezon City',1),(3,'Makati',1),(4,'Cebu City',2),(5,'Mandaue',2),(6,'Lapu-Lapu',2),(7,'Batangas City',3),(8,'Lipa City',3),(9,'Dagupan City',4),(10,'Alaminos',4),(11,'Bacoor',5),(12,'Imus',5);
/*!40000 ALTER TABLE `tbl_cities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_contracts`
--

DROP TABLE IF EXISTS `tbl_contracts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_contracts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `personnel_id` int(11) NOT NULL,
  `vessel_id` int(11) NOT NULL,
  `rank_id` int(11) DEFAULT NULL,
  `date_from` date NOT NULL,
  `date_to` date DEFAULT NULL,
  `status` varchar(50) NOT NULL DEFAULT 'Active',
  `remarks` varchar(500) DEFAULT NULL,
  `date_created` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_con_pid` (`personnel_id`),
  KEY `fk_con_vsl` (`vessel_id`),
  CONSTRAINT `fk_con_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info` (`id`),
  CONSTRAINT `fk_con_vsl` FOREIGN KEY (`vessel_id`) REFERENCES `tbl_vessels` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_contracts`
--

LOCK TABLES `tbl_contracts` WRITE;
/*!40000 ALTER TABLE `tbl_contracts` DISABLE KEYS */;
INSERT INTO `tbl_contracts` VALUES (1,1,1,2,'2023-02-01','2024-01-31','Completed','Regular 9-month contract','2026-08-12 21:20:45'),(2,3,3,5,'2023-09-01',NULL,'Active','Current contract','2026-08-12 21:20:45'),(3,4,1,1,'2022-05-01','2023-04-30','Completed','Completed full term','2026-08-12 21:20:45'),(4,8,3,12,'2023-07-01',NULL,'Active','Current contract','2026-08-12 21:20:45');
/*!40000 ALTER TABLE `tbl_contracts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_course`
--

DROP TABLE IF EXISTS `tbl_course`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_course` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `course` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_course`
--

LOCK TABLES `tbl_course` WRITE;
/*!40000 ALTER TABLE `tbl_course` DISABLE KEYS */;
INSERT INTO `tbl_course` VALUES (1,'Bachelor of Science in Marine Transportation'),(2,'Bachelor of Science in Marine Engineering'),(3,'Others (Please specify)');
/*!40000 ALTER TABLE `tbl_course` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_documents`
--

DROP TABLE IF EXISTS `tbl_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `documentName` varchar(200) NOT NULL,
  `docType` varchar(50) NOT NULL COMMENT 'Personal/License/Medical/Training/Outsource/UMMI',
  `month_expiry_warning` int(11) NOT NULL DEFAULT 3,
  `sequence` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_documents`
--

LOCK TABLES `tbl_documents` WRITE;
/*!40000 ALTER TABLE `tbl_documents` DISABLE KEYS */;
INSERT INTO `tbl_documents` VALUES (1,'Passport','Personal',3,1),(2,'NBI Clearance','Personal',1,2),(3,'Driver\'s License','Personal',3,3),(4,'Birth Certificate','Personal',0,4),(5,'Marriage Certificate','Personal',0,5),(6,'Seafarer\'s Book (Seaman\'s Book)','License',3,1),(7,'COC (Certificate of Competency)','License',3,2),(8,'GOC (GMDSS)','License',3,3),(9,'Officer\'s Watch Permit','License',3,4),(10,'PEME (Pre-Employment Medical Exam)','Medical',1,1),(11,'Yellow Fever Vaccination','Medical',6,2),(12,'Drug Test Result','Medical',1,3),(13,'STCW BST Certificate','Training',6,1),(14,'PDOS Certificate','Training',12,2),(15,'APAT Certificate','Training',12,3),(16,'PETE Certificate','Training',12,4),(17,'Proficiency in Tanker','Training',12,5),(18,'Flag State Certificate','Outsource',6,1),(19,'UMMI Training Certificate','UMMI',12,1),(20,'UMMI COE','UMMI',0,2);
/*!40000 ALTER TABLE `tbl_documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_dropdown_selection`
--

DROP TABLE IF EXISTS `tbl_dropdown_selection`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_dropdown_selection` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(100) NOT NULL,
  `meaning` varchar(200) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  `sequence` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_dropdown_selection`
--

LOCK TABLES `tbl_dropdown_selection` WRITE;
/*!40000 ALTER TABLE `tbl_dropdown_selection` DISABLE KEYS */;
INSERT INTO `tbl_dropdown_selection` VALUES (1,'crew_status','ACTIVE','Active',1),(2,'crew_status','INACTIVE','Active',2),(3,'crew_status','ON BOARD','Active',3),(4,'crew_status','ON VACATION','Active',4),(5,'crew_status','APPLICANT','Active',5),(6,'crew_status','LINE UP','Active',6);
/*!40000 ALTER TABLE `tbl_dropdown_selection` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_flight_booking`
--

DROP TABLE IF EXISTS `tbl_flight_booking`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_flight_booking` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vessel_id` int(11) NOT NULL,
  `personnel_id` int(11) NOT NULL,
  `booking_type` varchar(20) NOT NULL DEFAULT 'on_signer' COMMENT 'on_signer or off_signer',
  `is_booked` tinyint(1) NOT NULL DEFAULT 0,
  `date_added` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_fb_vsl` (`vessel_id`),
  KEY `fk_fb_pid` (`personnel_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_flight_booking`
--

LOCK TABLES `tbl_flight_booking` WRITE;
/*!40000 ALTER TABLE `tbl_flight_booking` DISABLE KEYS */;
INSERT INTO `tbl_flight_booking` VALUES (1,1,1,'on_signer',1,'2026-08-21 04:50:41'),(2,1,3,'on_signer',0,'2026-08-21 04:50:41'),(3,2,2,'off_signer',1,'2026-08-21 04:50:41'),(4,1,1,'on_signer',1,'2026-08-21 04:50:44'),(5,1,3,'on_signer',0,'2026-08-21 04:50:44'),(6,2,2,'off_signer',1,'2026-08-21 04:50:44'),(7,1,1,'on_signer',1,'2026-08-21 04:50:45'),(8,1,3,'on_signer',0,'2026-08-21 04:50:45'),(9,2,2,'off_signer',1,'2026-08-21 04:50:45'),(10,1,1,'on_signer',1,'2026-08-21 04:50:57'),(11,1,3,'on_signer',0,'2026-08-21 04:50:57'),(12,2,2,'off_signer',1,'2026-08-21 04:50:57');
/*!40000 ALTER TABLE `tbl_flight_booking` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_flight_option1`
--

DROP TABLE IF EXISTS `tbl_flight_option1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_flight_option1` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vessel_id` int(11) NOT NULL,
  `batchNo` int(11) NOT NULL DEFAULT 0,
  `crewtype` varchar(50) DEFAULT NULL,
  `eticket_on` tinyint(1) NOT NULL DEFAULT 0,
  `eticket_off` tinyint(1) NOT NULL DEFAULT 0,
  `selected` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `fk_flt_vessel` (`vessel_id`),
  CONSTRAINT `fk_flt_vessel` FOREIGN KEY (`vessel_id`) REFERENCES `tbl_vessels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_flight_option1`
--

LOCK TABLES `tbl_flight_option1` WRITE;
/*!40000 ALTER TABLE `tbl_flight_option1` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_flight_option1` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_hmo_beneficiary`
--

DROP TABLE IF EXISTS `tbl_hmo_beneficiary`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_hmo_beneficiary` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `personnel_id` int(11) NOT NULL,
  `family_id` int(11) NOT NULL,
  `hmo_number` varchar(100) DEFAULT NULL,
  `date_expiry` date DEFAULT NULL,
  `beneficiary_type` varchar(50) DEFAULT NULL,
  `beneficiary_status` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_hmo_pid` (`personnel_id`),
  KEY `fk_hmo_fam` (`family_id`),
  CONSTRAINT `fk_hmo_fam` FOREIGN KEY (`family_id`) REFERENCES `tbl_personnel_family_info` (`id`),
  CONSTRAINT `fk_hmo_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_hmo_beneficiary`
--

LOCK TABLES `tbl_hmo_beneficiary` WRITE;
/*!40000 ALTER TABLE `tbl_hmo_beneficiary` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_hmo_beneficiary` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_management`
--

DROP TABLE IF EXISTS `tbl_management`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_management` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `management` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_management`
--

LOCK TABLES `tbl_management` WRITE;
/*!40000 ALTER TABLE `tbl_management` DISABLE KEYS */;
INSERT INTO `tbl_management` VALUES (1,'UMMI Manning Office');
/*!40000 ALTER TABLE `tbl_management` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_nationality`
--

DROP TABLE IF EXISTS `tbl_nationality`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_nationality` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nationality` varchar(80) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_nationality`
--

LOCK TABLES `tbl_nationality` WRITE;
/*!40000 ALTER TABLE `tbl_nationality` DISABLE KEYS */;
INSERT INTO `tbl_nationality` VALUES (1,'Filipino'),(2,'Others (Please specify)');
/*!40000 ALTER TABLE `tbl_nationality` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_personnel_comment`
--

DROP TABLE IF EXISTS `tbl_personnel_comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_personnel_comment` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `personnel_id` int(11) NOT NULL,
  `comments` text NOT NULL,
  `date_sent` date NOT NULL,
  `img_id` varchar(200) DEFAULT NULL,
  `principal_view` varchar(10) NOT NULL DEFAULT '0',
  `added_by` int(11) DEFAULT NULL,
  `added_by_name` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pcm_pid` (`personnel_id`),
  CONSTRAINT `fk_pcm_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_personnel_comment`
--

LOCK TABLES `tbl_personnel_comment` WRITE;
/*!40000 ALTER TABLE `tbl_personnel_comment` DISABLE KEYS */;
INSERT INTO `tbl_personnel_comment` VALUES (1,1,'Excellent leadership. Highly recommended for promotion.','2023-12-01',NULL,'0',NULL,'Manning Staff Demo'),(2,1,'On time for sign-on. No disciplinary issues on record.','2024-01-15',NULL,'0',NULL,'Manning Staff Demo'),(3,3,'Strong engine room performance. JOCAP eligible.','2023-09-15',NULL,'0',NULL,'Manning Staff Demo'),(4,4,'Senior master with exemplary record. 24 years of experience.','2024-02-01',NULL,'0',NULL,'Super Admin Demo');
/*!40000 ALTER TABLE `tbl_personnel_comment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_personnel_documents`
--

DROP TABLE IF EXISTS `tbl_personnel_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_personnel_documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `personnel_id` int(11) NOT NULL,
  `document_id` int(11) NOT NULL,
  `document_num` varchar(200) DEFAULT NULL,
  `date_issued` date DEFAULT NULL,
  `date_expiry` date DEFAULT NULL,
  `grade` varchar(50) DEFAULT NULL,
  `img_id` varchar(200) DEFAULT NULL,
  `required_documents` varchar(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_pd_pid` (`personnel_id`),
  KEY `fk_pd_doc` (`document_id`),
  CONSTRAINT `fk_pd_doc` FOREIGN KEY (`document_id`) REFERENCES `tbl_documents` (`id`),
  CONSTRAINT `fk_pd_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_personnel_documents`
--

LOCK TABLES `tbl_personnel_documents` WRITE;
/*!40000 ALTER TABLE `tbl_personnel_documents` DISABLE KEYS */;
INSERT INTO `tbl_personnel_documents` VALUES (1,1,1,'P123456789','2020-01-10','2030-01-09',NULL,NULL,'0'),(2,1,6,'SB-2023-001','2023-01-15','2028-01-14',NULL,NULL,'0'),(3,1,7,'COC-2022-01','2022-06-01','2027-05-31',NULL,NULL,'0'),(4,1,10,'PEME-001','2026-06-01','2027-05-31',NULL,NULL,'0'),(5,1,13,'BST-001','2021-03-01','2026-03-01',NULL,NULL,'0'),(6,2,1,'P234567890','2021-05-20','2031-05-19',NULL,NULL,'0'),(7,2,6,'SB-2023-002','2023-05-01','2028-04-30',NULL,NULL,'0'),(8,3,1,'P345678901','2019-08-12','2029-08-11',NULL,NULL,'0'),(9,3,5,'COE-001','2022-01-01',NULL,NULL,NULL,'0'),(10,4,1,'P456789012','2018-11-30','2028-11-29',NULL,NULL,'0');
/*!40000 ALTER TABLE `tbl_personnel_documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_personnel_family_info`
--

DROP TABLE IF EXISTS `tbl_personnel_family_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_personnel_family_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `personnel_id` int(11) NOT NULL,
  `relationship` int(11) DEFAULT NULL,
  `fname` varchar(100) NOT NULL,
  `lname` varchar(100) NOT NULL,
  `date_of_birth` date DEFAULT NULL,
  `contact` varchar(50) DEFAULT NULL,
  `dependent` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `fk_pfi_pid` (`personnel_id`),
  KEY `fk_pfi_rel` (`relationship`),
  CONSTRAINT `fk_pfi_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info` (`id`),
  CONSTRAINT `fk_pfi_rel` FOREIGN KEY (`relationship`) REFERENCES `tbl_relationship` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_personnel_family_info`
--

LOCK TABLES `tbl_personnel_family_info` WRITE;
/*!40000 ALTER TABLE `tbl_personnel_family_info` DISABLE KEYS */;
INSERT INTO `tbl_personnel_family_info` VALUES (1,1,1,'Maria','Dela Cruz','1987-06-10','09171111111',1),(2,1,2,'Jose','Dela Cruz','2010-01-05',NULL,1),(3,3,1,'Anna','Garcia','1980-03-15','09391111111',1),(4,4,1,'Elena','Bautista','1974-09-20','09501111111',1),(5,4,2,'Ramon','Bautista','2000-11-11',NULL,0);
/*!40000 ALTER TABLE `tbl_personnel_family_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_personnel_info`
--

DROP TABLE IF EXISTS `tbl_personnel_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_personnel_info` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `firstname` varchar(100) NOT NULL,
  `middlename` varchar(100) DEFAULT NULL,
  `lastname` varchar(100) NOT NULL,
  `suffix` varchar(20) DEFAULT NULL,
  `position` int(11) DEFAULT NULL,
  `religion` int(11) DEFAULT NULL,
  `nationality` int(11) DEFAULT NULL,
  `school_name` int(11) DEFAULT NULL,
  `course` int(11) DEFAULT NULL,
  `emp_status` varchar(50) DEFAULT NULL,
  `crew_status` int(11) NOT NULL DEFAULT 1 COMMENT '1=ACTIVE,2=INACTIVE,3=ON BOARD,4=ON VACATION,5=APPLICANT,6=LINE UP',
  `crew_availability` int(11) NOT NULL DEFAULT 1 COMMENT '1=Available,0=Not Available',
  `status_date` date DEFAULT NULL,
  `date_hired` date DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `place_of_birth` varchar(200) DEFAULT NULL,
  `gender` varchar(20) DEFAULT NULL,
  `civil_status` varchar(50) DEFAULT NULL,
  `blood_type` varchar(10) DEFAULT NULL,
  `height` decimal(5,2) DEFAULT NULL,
  `weight` decimal(5,2) DEFAULT NULL,
  `email_address` varchar(200) DEFAULT NULL,
  `applicant_contact_num` varchar(50) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `province` int(11) DEFAULT NULL,
  `city` int(11) DEFAULT NULL,
  `last_vessel_id` int(11) DEFAULT NULL,
  `assigned_vessel_id` int(11) DEFAULT NULL,
  `sss` varchar(50) DEFAULT NULL,
  `tin` varchar(50) DEFAULT NULL,
  `pagibig` varchar(50) DEFAULT NULL,
  `philhealth` varchar(50) DEFAULT NULL,
  `hmo_number` varchar(50) DEFAULT NULL,
  `hmo_expiry` date DEFAULT NULL,
  `num_dependents` int(11) DEFAULT 0,
  `verified_benefits` tinyint(1) NOT NULL DEFAULT 0,
  `verified_tin` tinyint(1) NOT NULL DEFAULT 0,
  `picture_id` varchar(200) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `personal_notes` text DEFAULT NULL,
  `cadetship` tinyint(1) NOT NULL DEFAULT 0,
  `jocap` tinyint(1) NOT NULL DEFAULT 0,
  `higher_license` tinyint(1) NOT NULL DEFAULT 0,
  `uniform_coverall` varchar(20) DEFAULT NULL,
  `uniform_shoes` varchar(20) DEFAULT NULL,
  `uniform_polo` varchar(20) DEFAULT NULL,
  `uniform_pants` varchar(20) DEFAULT NULL,
  `date_added` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_pi_rank` (`position`),
  KEY `fk_pi_rel` (`religion`),
  KEY `fk_pi_nat` (`nationality`),
  KEY `fk_pi_school` (`school_name`),
  KEY `fk_pi_course` (`course`),
  CONSTRAINT `fk_pi_course` FOREIGN KEY (`course`) REFERENCES `tbl_course` (`id`),
  CONSTRAINT `fk_pi_nat` FOREIGN KEY (`nationality`) REFERENCES `tbl_nationality` (`id`),
  CONSTRAINT `fk_pi_rank` FOREIGN KEY (`position`) REFERENCES `tbl_rank` (`id`),
  CONSTRAINT `fk_pi_rel` FOREIGN KEY (`religion`) REFERENCES `tbl_religion` (`id`),
  CONSTRAINT `fk_pi_school` FOREIGN KEY (`school_name`) REFERENCES `tbl_school` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=162 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_personnel_info`
--

LOCK TABLES `tbl_personnel_info` WRITE;
/*!40000 ALTER TABLE `tbl_personnel_info` DISABLE KEYS */;
INSERT INTO `tbl_personnel_info` VALUES (1,'Juan','Santos','Dela Cruz',NULL,2,1,1,NULL,NULL,NULL,6,0,'2023-01-10','2010-06-01','1985-03-15',NULL,'Male','Married','O+',175.00,75.00,'juan.delacruz@email.com','09171234567','123 Rizal St., Brgy. Bagong Buhay',1,1,2,1,'03-4567890-1','123-456-789-000','1234567890','12-345678901-2','HMO-2024-0001','2027-06-30',2,0,0,NULL,NULL,'Reliable crew member. Available for emergency deployment.',0,0,1,'L','10','L','32','2026-08-12 21:20:45'),(2,'Maria','Reyes','Santos',NULL,3,1,1,NULL,NULL,NULL,6,1,'2025-11-01','2015-03-10','1990-07-22',NULL,'Female','Single','A+',160.00,55.00,'maria.santos@email.com','09281234567','456 Mabini Ave, Cebu City',2,4,2,1,'03-5678901-2','234-567-890-000','2345678901','23-456789012-3','HMO-2024-0002','2027-03-31',0,0,0,NULL,NULL,NULL,0,0,0,'S','7','S','26','2026-08-12 21:20:45'),(3,'Roberto','Lim','Garcia',NULL,5,2,1,NULL,NULL,NULL,6,0,'2023-07-20','2005-01-15','1978-11-08',NULL,'Male','Married','B+',170.00,80.00,'roberto.garcia@email.com','09391234567','789 Bonifacio St., Batangas',3,7,1,2,'03-6789012-3','345-678-901-000','3456789012','34-567890123-4','HMO-2024-0003','2026-12-31',1,0,0,NULL,NULL,'JOCAP program participant. Engine department specialist.',0,1,1,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(4,'Ernesto','Cruz','Bautista',NULL,1,1,1,NULL,NULL,NULL,6,1,'2023-05-15','2000-08-20','1972-05-30',NULL,'Male','Married','AB+',168.00,78.00,'ernesto.bautista@email.com','09501234567','321 Luna St., Dagupan',4,9,2,2,'03-7890123-4','456-789-012-000','4567890123','45-678901234-5',NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,1,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(5,'Ana','Villanueva','Torres',NULL,4,1,1,NULL,NULL,NULL,1,1,'2026-06-15','2018-02-28','1992-12-01',NULL,'Female','Single',NULL,158.00,52.00,'ana.torres@email.com','09611234567','654 Quezon Blvd, Bacoor',5,11,NULL,NULL,'03-8901234-5','567-890-123-000','5678901234','56-789012345-6',NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(6,'Carlos','Mendoza','Flores',NULL,6,1,1,NULL,NULL,NULL,1,1,NULL,'2013-07-01','1988-09-14',NULL,'Male','Married',NULL,172.00,77.00,'carlos.flores@email.com','09721234567','987 Del Pilar St., Manila',1,1,NULL,NULL,'03-9012345-6','678-901-234-000','6789012345','67-890123456-7',NULL,NULL,0,0,0,NULL,NULL,NULL,1,0,0,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(7,'Jose','Aquino','Reyes',NULL,9,3,1,NULL,NULL,NULL,1,1,NULL,'2012-04-15','1987-04-18',NULL,'Male','Married',NULL,165.00,70.00,'jose.reyes@email.com','09831234567','147 Taft Ave, Makati',1,3,NULL,NULL,'04-0123456-7','789-012-345-000','7890123456','78-901234567-8',NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(8,'Patricia','Gonzales','Marquez',NULL,12,1,1,NULL,NULL,NULL,3,0,'2023-08-01','2008-11-30','1983-08-25',NULL,'Female','Married',NULL,155.00,58.00,'patricia.marquez@email.com','09941234567','258 Shaw Blvd, Cebu City',2,4,3,4,'04-1234567-8','890-123-456-000','8901234567','89-012345678-9',NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(9,'Michael','Rivera','Castillo',NULL,7,1,1,NULL,NULL,NULL,1,1,'2023-02-14','2019-09-01','1993-02-14',NULL,'Male','Single',NULL,175.00,73.00,'michael.castillo@email.com','09051234567','369 EDSA, Quezon City',1,2,4,NULL,'04-2345678-9','901-234-567-000','9012345678','90-123456789-0',NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(10,'Lourdes','Serrano','Padilla',NULL,3,1,1,NULL,NULL,NULL,2,0,NULL,'2014-05-20','1989-06-30',NULL,'Female','Single',NULL,162.00,57.00,'lourdes.padilla@email.com','09161234567','741 Quirino Ave, Lipa City',3,8,NULL,NULL,'04-3456789-0','012-345-678-000','0123456789','01-234567890-1',NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(11,'Ferdinand','Hidalgo','Navarro',NULL,2,2,1,NULL,NULL,NULL,1,1,NULL,'2011-12-01','1986-10-05',NULL,'Male','Married',NULL,173.00,76.00,'ferdinand.navarro@email.com','09271234567','852 Claro M. Recto, Mandaue',2,5,NULL,NULL,'04-4567890-1','123-456-780-000','1234567891','12-345678902-3',NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,1,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(12,'Gloria','Aguilar','Santos',NULL,13,1,1,NULL,NULL,NULL,4,1,NULL,'2017-07-15','1991-03-22',NULL,'Female','Single',NULL,157.00,54.00,'gloria.santos2@email.com','09381234567','963 Rizal Ave, Lapu-Lapu',2,6,NULL,NULL,'04-5678901-2','234-567-890-111','2345678902','23-456789013-4',NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(13,'Angelo','Bernardo','Cruz',NULL,10,1,1,NULL,NULL,NULL,5,1,NULL,'2026-01-10','1998-11-20',NULL,'Male','Single',NULL,170.00,68.00,'angelo.cruz@email.com','09491234567','147 Gen. Luna, Manila',1,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(14,'Josefa','Castillo','Morales',NULL,4,1,1,NULL,NULL,NULL,1,1,NULL,'2026-02-20','1999-05-15',NULL,'Female','Single',NULL,160.00,53.00,'josefa.morales@email.com','09601234567','258 Taft Ave, Cebu City',2,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(15,'Renato','Lopez','Villanueva',NULL,14,1,1,NULL,NULL,NULL,1,1,NULL,'2026-03-05','2000-08-08',NULL,'Male','Single',NULL,168.00,65.00,'renato.villanueva@email.com','09711234567','369 Shaw, Bacoor',5,11,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,1,0,0,NULL,NULL,NULL,NULL,'2026-08-12 21:20:45'),(16,'Jeross','Reilan','Perez','Jr.',15,5,1,4,2,NULL,1,1,NULL,NULL,'2004-11-16','Quezon City','Male','Single',NULL,170.00,75.00,'nealpblo@gmail.com','09176050583','3220 F Roxas ST',1,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-12 23:56:01'),(17,'Establo','','Isaac','Jr.',2,3,1,6,2,NULL,1,1,NULL,NULL,'2004-11-16','QUEZON','Male','Married',NULL,135.00,50.00,'isaac@gmail.com','09176050583','234123 J BLD',1,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-25 04:23:50'),(18,'Applicant Demo','Applicant Demo','Applicant Demo','Jr.',15,3,1,5,2,NULL,1,1,NULL,NULL,'2026-08-05','Quezon City','Male','Single',NULL,124.00,124.00,'isaac@gmail.com','09176050583','234123 J BLD',3,8,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-25 04:24:48'),(19,'Jeross','Reilan','Isaac, Establo','Jr.',8,2,1,5,2,NULL,5,1,NULL,NULL,'2026-08-12','Quezon City','Male','Single',NULL,999.99,999.99,'12312312@gmail.com','09176050583','123123123',5,11,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-25 04:27:17'),(20,'Ryan elijah','sigue','asdasdsa','',4,NULL,1,NULL,NULL,NULL,5,1,NULL,NULL,'1999-02-02','mandaluyong','Male','',NULL,123.00,52.00,'ryanelijah23@gmail.com','09669600151','14b',1,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-25 22:53:15'),(21,'Isaac','De Guzman','Applicant Demo','Jr.',10,NULL,NULL,NULL,NULL,NULL,5,1,NULL,NULL,'2026-08-15','MANILA','Male','Single',NULL,172.00,80.00,'icyestabillo@gmail.com','09950369395','287 Haig',1,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 03:05:09'),(22,'Miguel',NULL,'Garcia',NULL,1,1,1,1,1,NULL,2,0,NULL,'2010-01-01','1975-01-01','Manila','Male','Single',NULL,165.00,60.00,NULL,'09120000000','10 Rizal St., Manila',1,1,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(23,'Jose',NULL,'Sanchez',NULL,2,1,1,1,1,NULL,1,1,NULL,'2011-02-02','1976-02-02','Manila','Male','Single',NULL,166.00,61.00,NULL,'09120000001','20 Rizal St., Manila',2,2,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(24,'Antonio',NULL,'Cruz',NULL,3,1,1,1,1,NULL,3,0,NULL,'2012-03-03','1977-03-03','Manila','Male','Single',NULL,167.00,62.00,NULL,'09120000002','30 Rizal St., Manila',3,3,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(25,'Luis',NULL,'Vargas',NULL,4,1,1,1,1,NULL,4,0,NULL,'2013-04-04','1978-04-04','Manila','Male','Single',NULL,168.00,63.00,NULL,'09120000003','40 Rizal St., Manila',4,4,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(26,'Carlos',NULL,'Ruiz',NULL,5,1,1,1,1,NULL,5,1,NULL,NULL,'1979-05-05','Manila','Male','Single',NULL,169.00,64.00,NULL,'09120000004','50 Rizal St., Manila',5,5,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2023-05-05 00:00:00'),(27,'Juan',NULL,'Bautista',NULL,6,1,1,1,1,NULL,3,0,NULL,'2015-06-06','1980-06-06','Manila','Male','Single',NULL,170.00,65.00,NULL,'09120000005','60 Rizal St., Manila',1,1,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(28,'Pedro',NULL,'Acosta',NULL,7,1,1,1,1,NULL,5,1,NULL,NULL,'1981-07-07','Manila','Male','Single',NULL,171.00,66.00,NULL,'09120000006','70 Rizal St., Manila',2,2,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2025-07-07 00:00:00'),(29,'Manuel',NULL,'Velasquez',NULL,8,1,1,1,1,NULL,6,0,NULL,'2017-08-08','1982-08-08','Manila','Male','Single',NULL,172.00,67.00,NULL,'09120000007','80 Rizal St., Manila',3,3,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(30,'Alejandro',NULL,'Perez',NULL,9,1,1,1,1,NULL,2,0,NULL,'2018-09-09','1983-09-09','Manila','Male','Single',NULL,173.00,68.00,NULL,'09120000008','90 Rizal St., Manila',4,4,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(31,'Ricardo',NULL,'Diaz',NULL,10,1,1,1,1,NULL,5,1,NULL,NULL,'1984-10-10','Manila','Male','Single',NULL,174.00,69.00,NULL,'09120000009','100 Rizal St., Manila',5,5,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2024-10-10 00:00:00'),(32,'Gabriel',NULL,'Romero',NULL,11,1,1,1,1,NULL,6,0,NULL,'2020-11-11','1985-11-11','Manila','Male','Single',NULL,175.00,70.00,NULL,'09120000010','110 Rizal St., Manila',1,1,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(33,'Eduardo',NULL,'Vega',NULL,12,1,1,1,1,NULL,3,0,NULL,'2021-12-12','1986-12-12','Manila','Male','Single',NULL,176.00,71.00,NULL,'09120000011','120 Rizal St., Manila',2,2,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(34,'Andres',NULL,'Salazar',NULL,13,1,1,1,1,NULL,6,0,NULL,'2022-01-13','1987-01-13','Manila','Male','Single',NULL,177.00,72.00,NULL,'09120000012','130 Rizal St., Manila',3,3,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(35,'Fernando',NULL,'Soto',NULL,14,1,1,1,1,NULL,5,1,NULL,NULL,'1988-02-14','Manila','Male','Single',NULL,178.00,73.00,NULL,'09120000013','140 Rizal St., Manila',4,4,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2024-02-14 00:00:00'),(36,'Daniel',NULL,'Cabrera',NULL,15,1,1,1,1,NULL,3,0,NULL,'2024-03-15','1989-03-15','Manila','Male','Single',NULL,179.00,74.00,NULL,'09120000014','150 Rizal St., Manila',5,5,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(37,'Arturo',NULL,'Gonzalez',NULL,1,1,1,1,1,NULL,1,1,NULL,'2025-04-16','1990-04-16','Manila','Male','Single',NULL,165.00,75.00,NULL,'09120000015','160 Rizal St., Manila',1,1,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(38,'Hector',NULL,'Gomez',NULL,2,1,1,1,1,NULL,5,1,NULL,NULL,'1991-05-17','Manila','Male','Single',NULL,166.00,76.00,NULL,'09120000016','170 Rizal St., Manila',2,2,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2023-05-17 00:00:00'),(39,'Raul',NULL,'Chavez',NULL,3,1,1,1,1,NULL,4,0,NULL,'2011-06-18','1992-06-18','Manila','Male','Single',NULL,167.00,77.00,NULL,'09120000017','180 Rizal St., Manila',3,3,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(40,'Oscar',NULL,'Mendoza',NULL,4,1,1,1,1,NULL,5,1,NULL,NULL,'1993-07-19','Manila','Male','Single',NULL,168.00,78.00,NULL,'09120000018','190 Rizal St., Manila',4,4,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2025-07-19 00:00:00'),(41,'Julio',NULL,'Rojas',NULL,5,1,1,1,1,NULL,5,1,NULL,NULL,'1994-08-20','Manila','Male','Single',NULL,169.00,79.00,NULL,'09120000019','200 Rizal St., Manila',5,5,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-20 00:00:00'),(42,'Felipe',NULL,'Miranda',NULL,6,1,1,1,1,NULL,6,0,NULL,'2014-09-21','1995-09-21','Manila','Male','Single',NULL,170.00,60.00,NULL,'09120000020','210 Rizal St., Manila',1,1,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(43,'Ramon',NULL,'Campos',NULL,7,1,1,1,1,NULL,2,0,NULL,'2015-10-22','1996-10-22','Manila','Male','Single',NULL,171.00,61.00,NULL,'09120000021','220 Rizal St., Manila',2,2,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(44,'Sergio',NULL,'Hernandez',NULL,8,1,1,1,1,NULL,5,1,NULL,NULL,'1997-11-23','Manila','Male','Single',NULL,172.00,62.00,NULL,'09120000022','230 Rizal St., Manila',3,3,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2025-11-23 00:00:00'),(45,'Alfredo',NULL,'Rivera',NULL,9,1,1,1,1,NULL,5,1,NULL,NULL,'1998-12-24','Manila','Male','Single',NULL,173.00,63.00,NULL,'09120000023','240 Rizal St., Manila',4,4,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-12-24 00:00:00'),(46,'Ernesto',NULL,'Gutierrez',NULL,10,1,1,1,1,NULL,6,0,NULL,'2018-01-25','1999-01-25','Manila','Male','Single',NULL,174.00,64.00,NULL,'09120000024','250 Rizal St., Manila',5,5,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(47,'Roberto',NULL,'Aguilar',NULL,11,1,1,1,1,NULL,3,0,NULL,'2019-02-26','2000-02-26','Manila','Male','Single',NULL,175.00,65.00,NULL,'09120000025','260 Rizal St., Manila',1,1,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(48,'Rodrigo',NULL,'Medina',NULL,12,1,1,1,1,NULL,4,0,NULL,'2020-03-27','2001-03-27','Manila','Male','Single',NULL,176.00,66.00,NULL,'09120000026','270 Rizal St., Manila',2,2,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(49,'Enrique',NULL,'Guerrero',NULL,13,1,1,1,1,NULL,3,0,NULL,'2021-04-28','1975-04-28','Manila','Male','Single',NULL,177.00,67.00,NULL,'09120000027','280 Rizal St., Manila',3,3,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(50,'Victor',NULL,'Rios',NULL,14,1,1,1,1,NULL,1,1,NULL,'2022-05-01','1976-05-01','Manila','Male','Single',NULL,178.00,68.00,NULL,'09120000028','290 Rizal St., Manila',4,4,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(51,'Mario',NULL,'Lopez',NULL,15,1,1,1,1,NULL,2,0,NULL,'2023-06-02','1977-06-02','Manila','Male','Single',NULL,179.00,69.00,NULL,'09120000029','300 Rizal St., Manila',5,5,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(52,'Jorge',NULL,'Flores',NULL,1,1,1,1,1,NULL,5,1,NULL,NULL,'1978-07-03','Manila','Male','Single',NULL,165.00,70.00,NULL,'09120000030','310 Rizal St., Manila',1,1,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2025-07-03 00:00:00'),(53,'Alberto',NULL,'Ortiz',NULL,2,1,1,1,1,NULL,3,0,NULL,'2025-08-04','1979-08-04','Manila','Male','Single',NULL,166.00,71.00,NULL,'09120000031','320 Rizal St., Manila',2,2,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(54,'Gustavo',NULL,'Ramos',NULL,3,1,1,1,1,NULL,6,0,NULL,'2010-09-05','1980-09-05','Manila','Male','Single',NULL,167.00,72.00,NULL,'09120000032','330 Rizal St., Manila',3,3,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(55,'Ruben',NULL,'Herrera',NULL,4,1,1,1,1,NULL,6,0,NULL,'2011-10-06','1981-10-06','Manila','Male','Single',NULL,168.00,73.00,NULL,'09120000033','340 Rizal St., Manila',4,4,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(56,'Ignacio',NULL,'Fuentes',NULL,5,1,1,1,1,NULL,3,0,NULL,'2012-11-07','1982-11-07','Manila','Male','Single',NULL,169.00,74.00,NULL,'09120000034','350 Rizal St., Manila',5,5,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(57,'Domingo',NULL,'Padilla',NULL,6,1,1,1,1,NULL,6,0,NULL,'2013-12-08','1983-12-08','Manila','Male','Single',NULL,170.00,75.00,NULL,'09120000035','360 Rizal St., Manila',1,1,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(58,'Bernardo',NULL,'Rodriguez',NULL,7,1,1,1,1,NULL,6,0,NULL,'2014-01-09','1984-01-09','Manila','Male','Single',NULL,171.00,76.00,NULL,'09120000036','370 Rizal St., Manila',2,2,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(59,'Aurelio',NULL,'Torres',NULL,8,1,1,1,1,NULL,3,0,NULL,'2015-02-10','1985-02-10','Manila','Male','Single',NULL,172.00,77.00,NULL,'09120000037','380 Rizal St., Manila',3,3,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(60,'Celestino',NULL,'Morales',NULL,9,1,1,1,1,NULL,6,0,NULL,'2016-03-11','1986-03-11','Manila','Male','Single',NULL,173.00,78.00,NULL,'09120000038','390 Rizal St., Manila',4,4,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(61,'Dionisio',NULL,'Jimenez',NULL,10,1,1,1,1,NULL,2,0,NULL,'2017-04-12','1987-04-12','Manila','Male','Single',NULL,174.00,79.00,NULL,'09120000039','400 Rizal St., Manila',5,5,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(62,'Esteban',NULL,'Delgado',NULL,11,1,1,1,1,NULL,5,1,NULL,NULL,'1988-05-13','Manila','Male','Single',NULL,175.00,60.00,NULL,'09120000040','410 Rizal St., Manila',1,1,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2023-05-13 00:00:00'),(63,'Fabian',NULL,'Navarro',NULL,12,1,1,1,1,NULL,6,0,NULL,'2019-06-14','1989-06-14','Manila','Male','Single',NULL,176.00,61.00,NULL,'09120000041','420 Rizal St., Manila',2,2,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(64,'Gerardo',NULL,'Santos',NULL,13,1,1,1,1,NULL,5,1,NULL,NULL,'1990-07-15','Manila','Male','Single',NULL,177.00,62.00,NULL,'09120000042','430 Rizal St., Manila',3,3,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2025-07-15 00:00:00'),(65,'Hilario',NULL,'Martinez',NULL,14,1,1,1,1,NULL,2,0,NULL,'2021-08-16','1991-08-16','Manila','Male','Single',NULL,178.00,63.00,NULL,'09120000043','440 Rizal St., Manila',4,4,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(66,'Isidro',NULL,'Ramirez',NULL,15,1,1,1,1,NULL,2,0,NULL,'2022-09-17','1992-09-17','Manila','Male','Single',NULL,179.00,64.00,NULL,'09120000044','450 Rizal St., Manila',5,5,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(67,'Jacinto',NULL,'Reyes',NULL,1,1,1,1,1,NULL,5,1,NULL,NULL,'1993-10-18','Manila','Male','Single',NULL,165.00,65.00,NULL,'09120000045','460 Rizal St., Manila',1,1,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2024-10-18 00:00:00'),(68,'Leandro',NULL,'Castillo',NULL,2,1,1,1,1,NULL,4,0,NULL,'2024-11-19','1994-11-19','Manila','Male','Single',NULL,166.00,66.00,NULL,'09120000046','470 Rizal St., Manila',2,2,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(69,'Maximo',NULL,'Munoz',NULL,3,1,1,1,1,NULL,2,0,NULL,'2025-12-20','1995-12-20','Manila','Male','Single',NULL,167.00,67.00,NULL,'09120000047','480 Rizal St., Manila',3,3,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(70,'Nicanor',NULL,'Espinoza',NULL,4,1,1,1,1,NULL,1,1,NULL,'2010-01-21','1996-01-21','Manila','Male','Single',NULL,168.00,68.00,NULL,'09120000048','490 Rizal St., Manila',4,4,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(71,'Paciano',NULL,'Lara',NULL,5,1,1,1,1,NULL,3,0,NULL,'2011-02-22','1997-02-22','Manila','Male','Single',NULL,169.00,69.00,NULL,'09120000049','500 Rizal St., Manila',5,5,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(72,'Miguel',NULL,'Martinez',NULL,6,1,1,1,1,NULL,4,0,NULL,'2012-03-23','1998-03-23','Manila','Male','Single',NULL,170.00,70.00,NULL,'09120000050','510 Rizal St., Manila',1,1,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(73,'Jose',NULL,'Ramirez',NULL,7,1,1,1,1,NULL,5,1,NULL,NULL,'1999-04-24','Manila','Male','Single',NULL,171.00,71.00,NULL,'09120000051','520 Rizal St., Manila',2,2,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-04-24 00:00:00'),(74,'Antonio',NULL,'Reyes',NULL,8,1,1,1,1,NULL,3,0,NULL,'2014-05-25','2000-05-25','Manila','Male','Single',NULL,172.00,72.00,NULL,'09120000052','530 Rizal St., Manila',3,3,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(75,'Luis',NULL,'Castillo',NULL,9,1,1,1,1,NULL,6,0,NULL,'2015-06-26','2001-06-26','Manila','Male','Single',NULL,173.00,73.00,NULL,'09120000053','540 Rizal St., Manila',4,4,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(76,'Carlos',NULL,'Munoz',NULL,10,1,1,1,1,NULL,2,0,NULL,'2016-07-27','1975-07-27','Manila','Male','Single',NULL,174.00,74.00,NULL,'09120000054','550 Rizal St., Manila',5,5,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(77,'Juan',NULL,'Espinoza',NULL,11,1,1,1,1,NULL,1,1,NULL,'2017-08-28','1976-08-28','Manila','Male','Single',NULL,175.00,75.00,NULL,'09120000055','560 Rizal St., Manila',1,1,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(78,'Pedro',NULL,'Lara',NULL,12,1,1,1,1,NULL,1,1,NULL,'2018-09-01','1977-09-01','Manila','Male','Single',NULL,176.00,76.00,NULL,'09120000056','570 Rizal St., Manila',2,2,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(79,'Manuel',NULL,'Garcia',NULL,13,1,1,1,1,NULL,5,1,NULL,NULL,'1978-10-02','Manila','Male','Single',NULL,177.00,77.00,NULL,'09120000057','580 Rizal St., Manila',3,3,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2024-10-02 00:00:00'),(80,'Alejandro',NULL,'Sanchez',NULL,14,1,1,1,1,NULL,5,1,NULL,NULL,'1979-11-03','Manila','Male','Single',NULL,178.00,78.00,NULL,'09120000058','590 Rizal St., Manila',4,4,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2025-11-03 00:00:00'),(81,'Ricardo',NULL,'Cruz',NULL,15,1,1,1,1,NULL,4,0,NULL,'2021-12-04','1980-12-04','Manila','Male','Single',NULL,179.00,79.00,NULL,'09120000059','600 Rizal St., Manila',5,5,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(82,'Gabriel',NULL,'Vargas',NULL,1,1,1,1,1,NULL,3,0,NULL,'2022-01-05','1981-01-05','Manila','Male','Single',NULL,165.00,60.00,NULL,'09120000060','610 Rizal St., Manila',1,1,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(83,'Eduardo',NULL,'Ruiz',NULL,2,1,1,1,1,NULL,3,0,NULL,'2023-02-06','1982-02-06','Manila','Male','Single',NULL,166.00,61.00,NULL,'09120000061','620 Rizal St., Manila',2,2,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(84,'Andres',NULL,'Bautista',NULL,3,1,1,1,1,NULL,1,1,NULL,'2024-03-07','1983-03-07','Manila','Male','Single',NULL,167.00,62.00,NULL,'09120000062','630 Rizal St., Manila',3,3,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(85,'Fernando',NULL,'Acosta',NULL,4,1,1,1,1,NULL,5,1,NULL,NULL,'1984-04-08','Manila','Male','Single',NULL,168.00,63.00,NULL,'09120000063','640 Rizal St., Manila',4,4,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-04-08 00:00:00'),(86,'Daniel',NULL,'Velasquez',NULL,5,1,1,1,1,NULL,1,1,NULL,'2010-05-09','1985-05-09','Manila','Male','Single',NULL,169.00,64.00,NULL,'09120000064','650 Rizal St., Manila',5,5,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(87,'Arturo',NULL,'Perez',NULL,6,1,1,1,1,NULL,5,1,NULL,NULL,'1986-06-10','Manila','Male','Single',NULL,170.00,65.00,NULL,'09120000065','660 Rizal St., Manila',1,1,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2024-06-10 00:00:00'),(88,'Hector',NULL,'Diaz',NULL,7,1,1,1,1,NULL,4,0,NULL,'2012-07-11','1987-07-11','Manila','Male','Single',NULL,171.00,66.00,NULL,'09120000066','670 Rizal St., Manila',2,2,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(89,'Raul',NULL,'Romero',NULL,8,1,1,1,1,NULL,4,0,NULL,'2013-08-12','1988-08-12','Manila','Male','Single',NULL,172.00,67.00,NULL,'09120000067','680 Rizal St., Manila',3,3,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(90,'Oscar',NULL,'Vega',NULL,9,1,1,1,1,NULL,5,1,NULL,NULL,'1989-09-13','Manila','Male','Single',NULL,173.00,68.00,NULL,'09120000068','690 Rizal St., Manila',4,4,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2023-09-13 00:00:00'),(91,'Julio',NULL,'Salazar',NULL,10,1,1,1,1,NULL,3,0,NULL,'2015-10-14','1990-10-14','Manila','Male','Single',NULL,174.00,69.00,NULL,'09120000069','700 Rizal St., Manila',5,5,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(92,'Felipe',NULL,'Soto',NULL,11,1,1,1,1,NULL,6,0,NULL,'2016-11-15','1991-11-15','Manila','Male','Single',NULL,175.00,70.00,NULL,'09120000070','710 Rizal St., Manila',1,1,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(93,'Ramon',NULL,'Cabrera',NULL,12,1,1,1,1,NULL,6,0,NULL,'2017-12-16','1992-12-16','Manila','Male','Single',NULL,176.00,71.00,NULL,'09120000071','720 Rizal St., Manila',2,2,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(94,'Sergio',NULL,'Gonzalez',NULL,13,1,1,1,1,NULL,1,1,NULL,'2018-01-17','1993-01-17','Manila','Male','Single',NULL,177.00,72.00,NULL,'09120000072','730 Rizal St., Manila',3,3,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(95,'Alfredo',NULL,'Gomez',NULL,14,1,1,1,1,NULL,1,1,NULL,'2019-02-18','1994-02-18','Manila','Male','Single',NULL,178.00,73.00,NULL,'09120000073','740 Rizal St., Manila',4,4,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(96,'Ernesto',NULL,'Chavez',NULL,15,1,1,1,1,NULL,5,1,NULL,NULL,'1995-03-19','Manila','Male','Single',NULL,179.00,74.00,NULL,'09120000074','750 Rizal St., Manila',5,5,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2025-03-19 00:00:00'),(97,'Roberto',NULL,'Mendoza',NULL,1,1,1,1,1,NULL,5,1,NULL,NULL,'1996-04-20','Manila','Male','Single',NULL,165.00,75.00,NULL,'09120000075','760 Rizal St., Manila',1,1,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-04-20 00:00:00'),(98,'Rodrigo',NULL,'Rojas',NULL,2,1,1,1,1,NULL,5,1,NULL,NULL,'1997-05-21','Manila','Male','Single',NULL,166.00,76.00,NULL,'09120000076','770 Rizal St., Manila',2,2,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2023-05-21 00:00:00'),(99,'Enrique',NULL,'Miranda',NULL,3,1,1,1,1,NULL,1,1,NULL,'2023-06-22','1998-06-22','Manila','Male','Single',NULL,167.00,77.00,NULL,'09120000077','780 Rizal St., Manila',3,3,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(100,'Victor',NULL,'Campos',NULL,4,1,1,1,1,NULL,5,1,NULL,NULL,'1999-07-23','Manila','Male','Single',NULL,168.00,78.00,NULL,'09120000078','790 Rizal St., Manila',4,4,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2025-07-23 00:00:00'),(101,'Mario',NULL,'Hernandez',NULL,5,1,1,1,1,NULL,4,0,NULL,'2025-08-24','2000-08-24','Manila','Male','Single',NULL,169.00,79.00,NULL,'09120000079','800 Rizal St., Manila',5,5,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(102,'Jorge',NULL,'Rivera',NULL,6,1,1,1,1,NULL,6,0,NULL,'2010-09-25','2001-09-25','Manila','Male','Single',NULL,170.00,60.00,NULL,'09120000080','810 Rizal St., Manila',1,1,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(103,'Alberto',NULL,'Gutierrez',NULL,7,1,1,1,1,NULL,4,0,NULL,'2011-10-26','1975-10-26','Manila','Male','Single',NULL,171.00,61.00,NULL,'09120000081','820 Rizal St., Manila',2,2,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(104,'Gustavo',NULL,'Aguilar',NULL,8,1,1,1,1,NULL,3,0,NULL,'2012-11-27','1976-11-27','Manila','Male','Single',NULL,172.00,62.00,NULL,'09120000082','830 Rizal St., Manila',3,3,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(105,'Ruben',NULL,'Medina',NULL,9,1,1,1,1,NULL,5,1,NULL,NULL,'1977-12-28','Manila','Male','Single',NULL,173.00,63.00,NULL,'09120000083','840 Rizal St., Manila',4,4,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-12-28 00:00:00'),(106,'Ignacio',NULL,'Guerrero',NULL,10,1,1,1,1,NULL,1,1,NULL,'2014-01-01','1978-01-01','Manila','Male','Single',NULL,174.00,64.00,NULL,'09120000084','850 Rizal St., Manila',5,5,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(107,'Domingo',NULL,'Rios',NULL,11,1,1,1,1,NULL,6,0,NULL,'2015-02-02','1979-02-02','Manila','Male','Single',NULL,175.00,65.00,NULL,'09120000085','860 Rizal St., Manila',1,1,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:58'),(108,'Bernardo',NULL,'Lopez',NULL,12,1,1,1,1,NULL,4,0,NULL,'2016-03-03','1980-03-03','Manila','Male','Single',NULL,176.00,66.00,NULL,'09120000086','870 Rizal St., Manila',2,2,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(109,'Aurelio',NULL,'Flores',NULL,13,1,1,1,1,NULL,5,1,NULL,NULL,'1981-04-04','Manila','Male','Single',NULL,177.00,67.00,NULL,'09120000087','880 Rizal St., Manila',3,3,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-04-04 00:00:00'),(110,'Celestino',NULL,'Ortiz',NULL,14,1,1,1,1,NULL,1,1,NULL,'2018-05-05','1982-05-05','Manila','Male','Single',NULL,178.00,68.00,NULL,'09120000088','890 Rizal St., Manila',4,4,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(111,'Dionisio',NULL,'Ramos',NULL,15,1,1,1,1,NULL,2,0,NULL,'2019-06-06','1983-06-06','Manila','Male','Single',NULL,179.00,69.00,NULL,'09120000089','900 Rizal St., Manila',5,5,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(112,'Esteban',NULL,'Herrera',NULL,1,1,1,1,1,NULL,4,0,NULL,'2020-07-07','1984-07-07','Manila','Male','Single',NULL,165.00,70.00,NULL,'09120000090','910 Rizal St., Manila',1,1,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(113,'Fabian',NULL,'Fuentes',NULL,2,1,1,1,1,NULL,3,0,NULL,'2021-08-08','1985-08-08','Manila','Male','Single',NULL,166.00,71.00,NULL,'09120000091','920 Rizal St., Manila',2,2,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(114,'Gerardo',NULL,'Padilla',NULL,3,1,1,1,1,NULL,3,0,NULL,'2022-09-09','1986-09-09','Manila','Male','Single',NULL,167.00,72.00,NULL,'09120000092','930 Rizal St., Manila',3,3,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(115,'Hilario',NULL,'Rodriguez',NULL,4,1,1,1,1,NULL,6,0,NULL,'2023-10-10','1987-10-10','Manila','Male','Single',NULL,168.00,73.00,NULL,'09120000093','940 Rizal St., Manila',4,4,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(116,'Isidro',NULL,'Torres',NULL,5,1,1,1,1,NULL,3,0,NULL,'2024-11-11','1988-11-11','Manila','Male','Single',NULL,169.00,74.00,NULL,'09120000094','950 Rizal St., Manila',5,5,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(117,'Jacinto',NULL,'Morales',NULL,6,1,1,1,1,NULL,6,0,NULL,'2025-12-12','1989-12-12','Manila','Male','Single',NULL,170.00,75.00,NULL,'09120000095','960 Rizal St., Manila',1,1,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(118,'Leandro',NULL,'Jimenez',NULL,7,1,1,1,1,NULL,5,1,NULL,NULL,'1990-01-13','Manila','Male','Single',NULL,171.00,76.00,NULL,'09120000096','970 Rizal St., Manila',2,2,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2023-01-13 00:00:00'),(119,'Maximo',NULL,'Delgado',NULL,8,1,1,1,1,NULL,6,0,NULL,'2011-02-14','1991-02-14','Manila','Male','Single',NULL,172.00,77.00,NULL,'09120000097','980 Rizal St., Manila',3,3,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(120,'Nicanor',NULL,'Navarro',NULL,9,1,1,1,1,NULL,1,1,NULL,'2012-03-15','1992-03-15','Manila','Male','Single',NULL,173.00,78.00,NULL,'09120000098','990 Rizal St., Manila',4,4,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(121,'Paciano',NULL,'Santos',NULL,10,1,1,1,1,NULL,6,0,NULL,'2013-04-16','1993-04-16','Manila','Male','Single',NULL,174.00,79.00,NULL,'09120000099','1000 Rizal St., Manila',5,5,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(122,'Miguel',NULL,'Rodriguez',NULL,11,1,1,1,1,NULL,3,0,NULL,'2014-05-17','1994-05-17','Manila','Male','Single',NULL,175.00,60.00,NULL,'09120000100','1010 Rizal St., Manila',1,1,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(123,'Jose',NULL,'Torres',NULL,12,1,1,1,1,NULL,2,0,NULL,'2015-06-18','1995-06-18','Manila','Male','Single',NULL,176.00,61.00,NULL,'09120000101','1020 Rizal St., Manila',2,2,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(124,'Antonio',NULL,'Morales',NULL,13,1,1,1,1,NULL,1,1,NULL,'2016-07-19','1996-07-19','Manila','Male','Single',NULL,177.00,62.00,NULL,'09120000102','1030 Rizal St., Manila',3,3,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(125,'Luis',NULL,'Jimenez',NULL,14,1,1,1,1,NULL,2,0,NULL,'2017-08-20','1997-08-20','Manila','Male','Single',NULL,178.00,63.00,NULL,'09120000103','1040 Rizal St., Manila',4,4,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(126,'Carlos',NULL,'Delgado',NULL,15,1,1,1,1,NULL,1,1,NULL,'2018-09-21','1998-09-21','Manila','Male','Single',NULL,179.00,64.00,NULL,'09120000104','1050 Rizal St., Manila',5,5,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(127,'Juan',NULL,'Navarro',NULL,1,1,1,1,1,NULL,4,0,NULL,'2019-10-22','1999-10-22','Manila','Male','Single',NULL,165.00,65.00,NULL,'09120000105','1060 Rizal St., Manila',1,1,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(128,'Pedro',NULL,'Santos',NULL,2,1,1,1,1,NULL,2,0,NULL,'2020-11-23','2000-11-23','Manila','Male','Single',NULL,166.00,66.00,NULL,'09120000106','1070 Rizal St., Manila',2,2,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(129,'Manuel',NULL,'Martinez',NULL,3,1,1,1,1,NULL,6,0,NULL,'2021-12-24','2001-12-24','Manila','Male','Single',NULL,167.00,67.00,NULL,'09120000107','1080 Rizal St., Manila',3,3,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(130,'Alejandro',NULL,'Ramirez',NULL,4,1,1,1,1,NULL,4,0,NULL,'2022-01-25','1975-01-25','Manila','Male','Single',NULL,168.00,68.00,NULL,'09120000108','1090 Rizal St., Manila',4,4,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(131,'Ricardo',NULL,'Reyes',NULL,5,1,1,1,1,NULL,5,1,NULL,NULL,'1976-02-26','Manila','Male','Single',NULL,169.00,69.00,NULL,'09120000109','1100 Rizal St., Manila',5,5,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2024-02-26 00:00:00'),(132,'Gabriel',NULL,'Castillo',NULL,6,1,1,1,1,NULL,4,0,NULL,'2024-03-27','1977-03-27','Manila','Male','Single',NULL,170.00,70.00,NULL,'09120000110','1110 Rizal St., Manila',1,1,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(133,'Eduardo',NULL,'Munoz',NULL,7,1,1,1,1,NULL,6,0,NULL,'2025-04-28','1978-04-28','Manila','Male','Single',NULL,171.00,71.00,NULL,'09120000111','1120 Rizal St., Manila',2,2,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(134,'Andres',NULL,'Espinoza',NULL,8,1,1,1,1,NULL,1,1,NULL,'2010-05-01','1979-05-01','Manila','Male','Single',NULL,172.00,72.00,NULL,'09120000112','1130 Rizal St., Manila',3,3,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(135,'Fernando',NULL,'Lara',NULL,9,1,1,1,1,NULL,6,0,NULL,'2011-06-02','1980-06-02','Manila','Male','Single',NULL,173.00,73.00,NULL,'09120000113','1140 Rizal St., Manila',4,4,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(136,'Daniel',NULL,'Garcia',NULL,10,1,1,1,1,NULL,5,1,NULL,NULL,'1981-07-03','Manila','Male','Single',NULL,174.00,74.00,NULL,'09120000114','1150 Rizal St., Manila',5,5,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2025-07-03 00:00:00'),(137,'Arturo',NULL,'Sanchez',NULL,11,1,1,1,1,NULL,6,0,NULL,'2013-08-04','1982-08-04','Manila','Male','Single',NULL,175.00,75.00,NULL,'09120000115','1160 Rizal St., Manila',1,1,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(138,'Hector',NULL,'Cruz',NULL,12,1,1,1,1,NULL,6,0,NULL,'2014-09-05','1983-09-05','Manila','Male','Single',NULL,176.00,76.00,NULL,'09120000116','1170 Rizal St., Manila',2,2,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(139,'Raul',NULL,'Vargas',NULL,13,1,1,1,1,NULL,4,0,NULL,'2015-10-06','1984-10-06','Manila','Male','Single',NULL,177.00,77.00,NULL,'09120000117','1180 Rizal St., Manila',3,3,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(140,'Oscar',NULL,'Ruiz',NULL,14,1,1,1,1,NULL,1,1,NULL,'2016-11-07','1985-11-07','Manila','Male','Single',NULL,178.00,78.00,NULL,'09120000118','1190 Rizal St., Manila',4,4,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(141,'Julio',NULL,'Bautista',NULL,15,1,1,1,1,NULL,3,0,NULL,'2017-12-08','1986-12-08','Manila','Male','Single',NULL,179.00,79.00,NULL,'09120000119','1200 Rizal St., Manila',5,5,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(142,'Felipe',NULL,'Acosta',NULL,1,1,1,1,1,NULL,2,0,NULL,'2018-01-09','1987-01-09','Manila','Male','Single',NULL,165.00,60.00,NULL,'09120000120','1210 Rizal St., Manila',1,1,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(143,'Ramon',NULL,'Velasquez',NULL,2,1,1,1,1,NULL,5,1,NULL,NULL,'1988-02-10','Manila','Male','Single',NULL,166.00,61.00,NULL,'09120000121','1220 Rizal St., Manila',2,2,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2024-02-10 00:00:00'),(144,'Sergio',NULL,'Perez',NULL,3,1,1,1,1,NULL,4,0,NULL,'2020-03-11','1989-03-11','Manila','Male','Single',NULL,167.00,62.00,NULL,'09120000122','1230 Rizal St., Manila',3,3,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(145,'Alfredo',NULL,'Diaz',NULL,4,1,1,1,1,NULL,4,0,NULL,'2021-04-12','1990-04-12','Manila','Male','Single',NULL,168.00,63.00,NULL,'09120000123','1240 Rizal St., Manila',4,4,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(146,'Ernesto',NULL,'Romero',NULL,5,1,1,1,1,NULL,3,0,NULL,'2022-05-13','1991-05-13','Manila','Male','Single',NULL,169.00,64.00,NULL,'09120000124','1250 Rizal St., Manila',5,5,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(147,'Roberto',NULL,'Vega',NULL,6,1,1,1,1,NULL,3,0,NULL,'2023-06-14','1992-06-14','Manila','Male','Single',NULL,170.00,65.00,NULL,'09120000125','1260 Rizal St., Manila',1,1,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(148,'Rodrigo',NULL,'Salazar',NULL,7,1,1,1,1,NULL,4,0,NULL,'2024-07-15','1993-07-15','Manila','Male','Single',NULL,171.00,66.00,NULL,'09120000126','1270 Rizal St., Manila',2,2,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(149,'Enrique',NULL,'Soto',NULL,8,1,1,1,1,NULL,6,0,NULL,'2025-08-16','1994-08-16','Manila','Male','Single',NULL,172.00,67.00,NULL,'09120000127','1280 Rizal St., Manila',3,3,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(150,'Victor',NULL,'Cabrera',NULL,9,1,1,1,1,NULL,1,1,NULL,'2010-09-17','1995-09-17','Manila','Male','Single',NULL,173.00,68.00,NULL,'09120000128','1290 Rizal St., Manila',4,4,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(151,'Mario',NULL,'Gonzalez',NULL,10,1,1,1,1,NULL,6,0,NULL,'2011-10-18','1996-10-18','Manila','Male','Single',NULL,174.00,69.00,NULL,'09120000129','1300 Rizal St., Manila',5,5,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(152,'Jorge',NULL,'Gomez',NULL,11,1,1,1,1,NULL,6,0,NULL,'2012-11-19','1997-11-19','Manila','Male','Single',NULL,175.00,70.00,NULL,'09120000130','1310 Rizal St., Manila',1,1,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(153,'Alberto',NULL,'Chavez',NULL,12,1,1,1,1,NULL,2,0,NULL,'2013-12-20','1998-12-20','Manila','Male','Single',NULL,176.00,71.00,NULL,'09120000131','1320 Rizal St., Manila',2,2,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(154,'Gustavo',NULL,'Mendoza',NULL,13,1,1,1,1,NULL,6,0,NULL,'2014-01-21','1999-01-21','Manila','Male','Single',NULL,177.00,72.00,NULL,'09120000132','1330 Rizal St., Manila',3,3,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(155,'Ruben',NULL,'Rojas',NULL,14,1,1,1,1,NULL,6,0,NULL,'2015-02-22','2000-02-22','Manila','Male','Single',NULL,178.00,73.00,NULL,'09120000133','1340 Rizal St., Manila',4,4,2,2,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(156,'Ignacio',NULL,'Miranda',NULL,15,1,1,1,1,NULL,3,0,NULL,'2016-03-23','2001-03-23','Manila','Male','Single',NULL,179.00,74.00,NULL,'09120000134','1350 Rizal St., Manila',5,5,3,3,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(157,'Domingo',NULL,'Campos',NULL,1,1,1,1,1,NULL,3,0,NULL,'2017-04-24','1975-04-24','Manila','Male','Single',NULL,165.00,75.00,NULL,'09120000135','1360 Rizal St., Manila',1,1,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(158,'Bernardo',NULL,'Hernandez',NULL,2,1,1,1,1,NULL,3,0,NULL,'2018-05-25','1976-05-25','Manila','Male','Single',NULL,166.00,76.00,NULL,'09120000136','1370 Rizal St., Manila',2,2,1,1,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(159,'Aurelio',NULL,'Rivera',NULL,3,1,1,1,1,NULL,5,1,NULL,NULL,'1977-06-26','Manila','Male','Single',NULL,167.00,77.00,NULL,'09120000137','1380 Rizal St., Manila',3,3,2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2024-06-26 00:00:00'),(160,'Celestino',NULL,'Gutierrez',NULL,4,1,1,1,1,NULL,1,1,NULL,'2020-07-27','1978-07-27','Manila','Male','Single',NULL,168.00,78.00,NULL,'09120000138','1390 Rizal St., Manila',4,4,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59'),(161,'Dionisio',NULL,'Aguilar',NULL,5,1,1,1,1,NULL,4,0,NULL,'2021-08-28','1979-08-28','Manila','Male','Single',NULL,169.00,79.00,NULL,'09120000139','1400 Rizal St., Manila',5,5,4,4,NULL,NULL,NULL,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,0,0,0,NULL,NULL,NULL,NULL,'2026-08-26 05:24:59');
/*!40000 ALTER TABLE `tbl_personnel_info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_personnel_sea_service`
--

DROP TABLE IF EXISTS `tbl_personnel_sea_service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_personnel_sea_service` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `personnel_id` int(11) NOT NULL,
  `vessel_id` int(11) NOT NULL,
  `rank_id` int(11) DEFAULT NULL,
  `port` varchar(200) DEFAULT NULL,
  `date_from` date NOT NULL,
  `date_to` date DEFAULT NULL,
  `remarks` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pss_pid` (`personnel_id`),
  KEY `fk_pss_vsl` (`vessel_id`),
  CONSTRAINT `fk_pss_pid` FOREIGN KEY (`personnel_id`) REFERENCES `tbl_personnel_info` (`id`),
  CONSTRAINT `fk_pss_vsl` FOREIGN KEY (`vessel_id`) REFERENCES `tbl_vessels` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_personnel_sea_service`
--

LOCK TABLES `tbl_personnel_sea_service` WRITE;
/*!40000 ALTER TABLE `tbl_personnel_sea_service` DISABLE KEYS */;
INSERT INTO `tbl_personnel_sea_service` VALUES (1,1,1,2,'Manila','2022-01-15','2023-01-14','Completed contract'),(2,1,2,2,'Cebu','2020-03-01','2021-02-28','Completed contract'),(3,2,2,3,'Cebu','2023-06-01','2024-05-31','Completed contract'),(4,3,3,5,'Singapore','2022-08-10','2023-08-09','Completed contract'),(5,4,1,1,'Manila','2021-05-01','2022-04-30','Completed contract'),(6,6,4,6,'Hong Kong','2023-01-01','2023-12-31','Completed contract'),(7,7,1,9,'Manila','2023-03-15','2024-03-14','Completed contract'),(8,8,3,12,'Singapore','2022-07-01','2023-06-30','Completed contract'),(9,9,2,7,'Hong Kong','2024-01-01',NULL,'Current contract'),(10,11,4,2,'Hong Kong','2023-09-01','2024-08-31','Completed contract');
/*!40000 ALTER TABLE `tbl_personnel_sea_service` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_principals`
--

DROP TABLE IF EXISTS `tbl_principals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_principals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_principals`
--

LOCK TABLES `tbl_principals` WRITE;
/*!40000 ALTER TABLE `tbl_principals` DISABLE KEYS */;
INSERT INTO `tbl_principals` VALUES (1,'Mitsui O.S.K. Lines'),(2,'Nippon Yusen Kaisha'),(3,'Evergreen Marine Corp');
/*!40000 ALTER TABLE `tbl_principals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_provinces`
--

DROP TABLE IF EXISTS `tbl_provinces`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_provinces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `provinces` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_provinces`
--

LOCK TABLES `tbl_provinces` WRITE;
/*!40000 ALTER TABLE `tbl_provinces` DISABLE KEYS */;
INSERT INTO `tbl_provinces` VALUES (1,'Metro Manila'),(2,'Cebu'),(3,'Batangas'),(4,'Pangasinan'),(5,'Cavite');
/*!40000 ALTER TABLE `tbl_provinces` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_rank`
--

DROP TABLE IF EXISTS `tbl_rank`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_rank` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rank_code` varchar(50) NOT NULL,
  `rank_type` varchar(50) NOT NULL,
  `sequence` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_rank`
--

LOCK TABLES `tbl_rank` WRITE;
/*!40000 ALTER TABLE `tbl_rank` DISABLE KEYS */;
INSERT INTO `tbl_rank` VALUES (1,'MASTER','Deck',1),(2,'CHIEF OFFICER','Deck',2),(3,'2ND OFFICER','Deck',3),(4,'3RD OFFICER','Deck',4),(5,'CHIEF ENGINEER','Engine',1),(6,'2ND ENGINEER','Engine',2),(7,'3RD ENGINEER','Engine',3),(8,'4TH ENGINEER','Engine',4),(9,'BOSUN','Rating',1),(10,'AB SEAMAN','Rating',2),(11,'OS','Rating',3),(12,'CHIEF COOK','Catering',1),(13,'STEWARD','Catering',2),(14,'DECK CADET','Cadet',1),(15,'ENGINE CADET','Cadet',2);
/*!40000 ALTER TABLE `tbl_rank` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_relationship`
--

DROP TABLE IF EXISTS `tbl_relationship`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_relationship` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `relationship` varchar(80) NOT NULL,
  `remarks` varchar(200) DEFAULT NULL,
  `sequence` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_relationship`
--

LOCK TABLES `tbl_relationship` WRITE;
/*!40000 ALTER TABLE `tbl_relationship` DISABLE KEYS */;
INSERT INTO `tbl_relationship` VALUES (1,'Spouse',NULL,1),(2,'Child',NULL,2),(3,'Parent',NULL,3),(4,'Sibling',NULL,4),(5,'Others',NULL,5);
/*!40000 ALTER TABLE `tbl_relationship` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_religion`
--

DROP TABLE IF EXISTS `tbl_religion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_religion` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `religion` varchar(80) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_religion`
--

LOCK TABLES `tbl_religion` WRITE;
/*!40000 ALTER TABLE `tbl_religion` DISABLE KEYS */;
INSERT INTO `tbl_religion` VALUES (1,'Roman Catholic'),(2,'Islam'),(3,'Iglesia ni Cristo'),(4,'Seventh Day Adventist'),(5,'Others (Please specify)');
/*!40000 ALTER TABLE `tbl_religion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_school`
--

DROP TABLE IF EXISTS `tbl_school`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_school` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `school_name` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_school`
--

LOCK TABLES `tbl_school` WRITE;
/*!40000 ALTER TABLE `tbl_school` DISABLE KEYS */;
INSERT INTO `tbl_school` VALUES (1,'Philippine Maritime Institute'),(2,'John B. Lacson Foundation Maritime University'),(3,'Philippine Merchant Marine Academy'),(4,'STI College'),(5,'AMA Computer University'),(6,'Others (Please specify)');
/*!40000 ALTER TABLE `tbl_school` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_type_of_vessel`
--

DROP TABLE IF EXISTS `tbl_type_of_vessel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_type_of_vessel` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `typeOfVessel` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_type_of_vessel`
--

LOCK TABLES `tbl_type_of_vessel` WRITE;
/*!40000 ALTER TABLE `tbl_type_of_vessel` DISABLE KEYS */;
INSERT INTO `tbl_type_of_vessel` VALUES (1,'Bulk Carrier'),(2,'Container Ship'),(3,'Tanker'),(4,'General Cargo'),(5,'LNG/LPG Carrier'),(6,'Passenger / RORO');
/*!40000 ALTER TABLE `tbl_type_of_vessel` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_user_access`
--

DROP TABLE IF EXISTS `tbl_user_access`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_user_access` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `Access_ID` int(11) NOT NULL,
  `UserType_ID` int(11) NOT NULL,
  `CustomizedUser` int(11) NOT NULL DEFAULT 0,
  `Access_type` varchar(50) NOT NULL DEFAULT 'Allow',
  PRIMARY KEY (`id`),
  KEY `fk_ua_acc` (`Access_ID`),
  KEY `fk_ua_utyp` (`UserType_ID`),
  CONSTRAINT `fk_ua_acc` FOREIGN KEY (`Access_ID`) REFERENCES `tbl_user_access_list` (`id`),
  CONSTRAINT `fk_ua_utyp` FOREIGN KEY (`UserType_ID`) REFERENCES `tbl_user_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_user_access`
--

LOCK TABLES `tbl_user_access` WRITE;
/*!40000 ALTER TABLE `tbl_user_access` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_user_access` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_user_access_list`
--

DROP TABLE IF EXISTS `tbl_user_access_list`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_user_access_list` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `description` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=184 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_user_access_list`
--

LOCK TABLES `tbl_user_access_list` WRITE;
/*!40000 ALTER TABLE `tbl_user_access_list` DISABLE KEYS */;
INSERT INTO `tbl_user_access_list` VALUES (1,'Home'),(2,'Query Crew'),(51,'Query Crew Page'),(54,'Files (Personnel + Applicant)'),(55,'Personnel File'),(56,'Applicant File'),(70,'Crew Status'),(91,'PDS Reports'),(183,'Applicant Pool');
/*!40000 ALTER TABLE `tbl_user_access_list` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_user_assigned_vessel`
--

DROP TABLE IF EXISTS `tbl_user_assigned_vessel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_user_assigned_vessel` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `vessel_id` int(11) NOT NULL,
  `principal_id` int(11) DEFAULT NULL,
  `management_id` int(11) DEFAULT NULL,
  `owner_id` int(11) DEFAULT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`id`),
  KEY `fk_uav_uid` (`user_id`),
  KEY `fk_uav_vsl` (`vessel_id`),
  KEY `fk_uav_prin` (`principal_id`),
  KEY `fk_uav_mgmt` (`management_id`),
  CONSTRAINT `fk_uav_mgmt` FOREIGN KEY (`management_id`) REFERENCES `tbl_management` (`id`),
  CONSTRAINT `fk_uav_prin` FOREIGN KEY (`principal_id`) REFERENCES `tbl_principals` (`id`),
  CONSTRAINT `fk_uav_uid` FOREIGN KEY (`user_id`) REFERENCES `tbl_users` (`id`),
  CONSTRAINT `fk_uav_vsl` FOREIGN KEY (`vessel_id`) REFERENCES `tbl_vessels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_user_assigned_vessel`
--

LOCK TABLES `tbl_user_assigned_vessel` WRITE;
/*!40000 ALTER TABLE `tbl_user_assigned_vessel` DISABLE KEYS */;
/*!40000 ALTER TABLE `tbl_user_assigned_vessel` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_user_type`
--

DROP TABLE IF EXISTS `tbl_user_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_user_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_type` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_user_type`
--

LOCK TABLES `tbl_user_type` WRITE;
/*!40000 ALTER TABLE `tbl_user_type` DISABLE KEYS */;
INSERT INTO `tbl_user_type` VALUES (1,'MANNING_STAFF'),(2,'SUPER_ADMIN'),(3,'PRINCIPAL'),(4,'APPLICANT'),(5,'DOCUMENTATION_OFFICER'),(6,'ADMIN'),(7,'VESSEL_OWNER');
/*!40000 ALTER TABLE `tbl_user_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_users`
--

DROP TABLE IF EXISTS `tbl_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `fullname` varchar(200) NOT NULL,
  `type` varchar(50) NOT NULL,
  `management` int(11) DEFAULT NULL,
  `email_address` varchar(200) DEFAULT NULL,
  `viewcrewcontactdetails` tinyint(1) NOT NULL DEFAULT 0,
  `viewcreatecontract` tinyint(1) NOT NULL DEFAULT 0,
  `ccl_permission` tinyint(1) NOT NULL DEFAULT 0,
  `disable_user` tinyint(1) NOT NULL DEFAULT 0,
  `restrict_pw` tinyint(1) NOT NULL DEFAULT 0,
  `session_id` varchar(200) DEFAULT NULL,
  `date_time_logged_in` datetime DEFAULT NULL,
  `date_password_reset` datetime DEFAULT NULL,
  `date_added` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  KEY `fk_usr_mgmt` (`management`),
  CONSTRAINT `fk_usr_mgmt` FOREIGN KEY (`management`) REFERENCES `tbl_management` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_users`
--

LOCK TABLES `tbl_users` WRITE;
/*!40000 ALTER TABLE `tbl_users` DISABLE KEYS */;
INSERT INTO `tbl_users` VALUES (1,'demo.manning','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','Manning Staff Demo','MANNING_STAFF',1,NULL,1,1,1,0,0,NULL,NULL,NULL,'2026-08-12 21:20:45'),(2,'demo.superadmin','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','Super Admin Demo','SUPER_ADMIN',1,NULL,1,1,1,0,0,NULL,NULL,NULL,'2026-08-12 21:20:45'),(3,'demo.principal','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','Principal Demo','PRINCIPAL',1,NULL,0,0,0,0,0,NULL,NULL,NULL,'2026-08-12 21:20:45'),(4,'demo.applicant','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','Applicant Demo','APPLICANT',1,NULL,0,0,0,0,0,NULL,NULL,NULL,'2026-08-12 21:20:45'),(5,'demo.doc','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','Documentation Officer Demo','DOCUMENTATION_OFFICER',1,NULL,1,1,1,0,0,NULL,NULL,NULL,'2026-08-25 21:20:45'),(6,'demo.admin','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','Admin Demo','ADMIN',1,NULL,1,1,1,0,0,NULL,NULL,NULL,'2026-08-25 21:20:45'),(7,'demo.vesselowner','ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f','Vessel Owner Demo','VESSEL_OWNER',1,NULL,0,0,0,0,0,NULL,NULL,NULL,'2026-08-25 21:20:45');
/*!40000 ALTER TABLE `tbl_users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tbl_vessels`
--

DROP TABLE IF EXISTS `tbl_vessels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tbl_vessels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vesselName` varchar(200) NOT NULL,
  `agency` varchar(200) DEFAULT NULL,
  `active` varchar(10) NOT NULL DEFAULT 'Active',
  `VesselType` int(11) DEFAULT NULL,
  `principal` int(11) DEFAULT NULL,
  `management` int(11) DEFAULT NULL,
  `owner` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_vessels_vtype` (`VesselType`),
  KEY `fk_vessels_princ` (`principal`),
  KEY `fk_vessels_mgmt` (`management`),
  CONSTRAINT `fk_vessels_mgmt` FOREIGN KEY (`management`) REFERENCES `tbl_management` (`id`),
  CONSTRAINT `fk_vessels_princ` FOREIGN KEY (`principal`) REFERENCES `tbl_principals` (`id`),
  CONSTRAINT `fk_vessels_vtype` FOREIGN KEY (`VesselType`) REFERENCES `tbl_type_of_vessel` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tbl_vessels`
--

LOCK TABLES `tbl_vessels` WRITE;
/*!40000 ALTER TABLE `tbl_vessels` DISABLE KEYS */;
INSERT INTO `tbl_vessels` VALUES (1,'MV UMMI STAR','MOL Philippines','Active',1,1,1,NULL),(2,'MV PACIFIC DAWN','NYK Line','Active',2,2,1,NULL),(3,'MT MINDANAO','Evergreen','Active',3,3,1,NULL),(4,'MV CEBU PRIDE','MOL Philippines','Active',4,1,1,NULL);
/*!40000 ALTER TABLE `tbl_vessels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'ummi_crew'
--
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `spApplicantPoolSearchDisplay` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `spApplicantPoolSearchDisplay`(
  IN lastname_   VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN firstname_  VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN rank_       INT,
  IN ranktype_   VARCHAR(50)  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN vslexpID_   INT,
  IN datefrom_   DATE,
  IN dateto_     DATE
)
BEGIN
  SELECT
    pi.id,
    pi.lastname,
    pi.firstname,
    pi.middlename,
    pi.picture_id,
    pi.gender,
    r.rank_code AS rank_code,
    TIMESTAMPDIFF(YEAR, pi.date_of_birth, CURDATE()) AS age,
    pi.date_added AS date_applied,
    pi.applicant_contact_num
  FROM tbl_personnel_info pi
  LEFT JOIN tbl_rank r ON r.id = pi.position
  WHERE pi.crew_status = 5
    AND (lastname_  = '' OR pi.lastname  LIKE CONCAT('%', lastname_,  '%') COLLATE utf8mb4_unicode_ci)
    AND (firstname_ = '' OR pi.firstname LIKE CONCAT('%', firstname_, '%') COLLATE utf8mb4_unicode_ci)
    AND (rank_     IS NULL OR pi.position  = rank_)
    AND (ranktype_ = ''   OR r.rank_type   = ranktype_ COLLATE utf8mb4_unicode_ci)
    AND (datefrom_ IS NULL OR pi.date_added >= datefrom_)
    AND (dateto_   IS NULL OR pi.date_added <= dateto_)
    AND (vslexpID_ IS NULL OR EXISTS (
          SELECT 1 FROM tbl_personnel_sea_service pss
          JOIN tbl_vessels v ON v.id = pss.vessel_id
          WHERE pss.personnel_id = pi.id AND v.VesselType = vslexpID_
        ))
  ORDER BY pi.date_added DESC, pi.lastname;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `spQueryCrewSearchDisplay` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `spQueryCrewSearchDisplay`(
  IN `lastname_`        VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN `firstname_`       VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN `crewstatusID_`    INT,
  IN `crewavailbility_` INT,
  IN `activeInactive_`  VARCHAR(20)  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN `rankID_`          INT,
  IN `ranktypeID_`      VARCHAR(50)  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN `vesselID_`        INT,
  IN `vesselTypeExpID_` INT,
  IN `provinceID_`      INT,
  IN `cityID_`          INT,
  IN `cadetship_`       TINYINT,
  IN `jocap_`           TINYINT,
  IN `higherlic_`       TINYINT,
  IN `date_`            DATE,
  IN `userID_`          INT,
  IN `userType_`        VARCHAR(50)  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
)
BEGIN
  SELECT
    pi.id,
    pi.lastname,
    pi.firstname,
    pi.middlename,
    pi.picture_id,
    pi.gender,
    r.rank_code          AS rank_code,
    r.rank_type          AS rank_type,
    ds.meaning           AS crew_status_text,
    pi.crew_availability,
    TIMESTAMPDIFF(YEAR, pi.date_of_birth, CURDATE()) AS age,
    pr.provinces         AS province_name,
    ct.cities            AS city_name,
    pi.cadetship,
    pi.jocap,
    pi.higher_license,
    pi.emp_status,
    pi.date_hired,
    pi.crew_status,
    pi.date_of_birth,
    -- UC-CM-06: Vessel navigation link fields
    pi.assigned_vessel_id,
    av.vesselName        AS vessel_name,
    -- Last vessel (sea service history)
    pi.last_vessel_id,
    lv.vesselName        AS last_vessel_name,
    -- FR-CM-07: Status date for elapsed-time highlighting
    pi.status_date,
    -- Sea service duration
    (
      SELECT SUM(TIMESTAMPDIFF(YEAR, pss.date_from, IFNULL(pss.date_to, CURDATE())))
      FROM tbl_personnel_sea_service pss
      WHERE pss.personnel_id = pi.id
    )                    AS total_sea_service
  FROM `tbl_personnel_info` pi
  LEFT JOIN `tbl_rank`               r  ON r.id  = pi.position
  LEFT JOIN `tbl_dropdown_selection` ds ON ds.type = 'crew_status' AND ds.sequence = pi.crew_status
  LEFT JOIN `tbl_provinces`          pr ON pr.id  = pi.province
  LEFT JOIN `tbl_cities`             ct ON ct.id  = pi.city
  -- UC-CM-06: Join assigned vessel (ON BOARD / LINE UP link)
  LEFT JOIN `tbl_vessels`            av ON av.id  = pi.assigned_vessel_id
  -- Last vessel from sea service history
  LEFT JOIN `tbl_vessels`            lv ON lv.id  = pi.last_vessel_id
  WHERE 1=1
    AND (lastname_        = '' OR pi.lastname  LIKE CONCAT('%', lastname_,  '%') COLLATE utf8mb4_unicode_ci)
    AND (firstname_       = '' OR pi.firstname LIKE CONCAT('%', firstname_, '%') COLLATE utf8mb4_unicode_ci)
    AND (crewstatusID_    IS NULL OR pi.crew_status      = crewstatusID_)
    AND (crewavailbility_ IS NULL OR pi.crew_availability = crewavailbility_)
    AND (rankID_          IS NULL OR pi.position         = rankID_)
    AND (ranktypeID_      = ''   OR r.rank_type          = ranktypeID_ COLLATE utf8mb4_unicode_ci)
    AND (provinceID_      IS NULL OR pi.province         = provinceID_)
    AND (cityID_          IS NULL OR pi.city             = cityID_)
    AND (cadetship_ = 0 OR pi.cadetship      = 1)
    AND (jocap_     = 0 OR pi.jocap          = 1)
    AND (higherlic_ = 0 OR pi.higher_license = 1)
    AND (vesselTypeExpID_ IS NULL OR EXISTS (
          SELECT 1 FROM tbl_personnel_sea_service pss
          JOIN tbl_vessels v ON v.id = pss.vessel_id
          WHERE pss.personnel_id = pi.id AND v.VesselType = vesselTypeExpID_
        ))
    AND (vesselID_ IS NULL OR EXISTS (
          SELECT 1 FROM tbl_personnel_sea_service pss2
          WHERE pss2.personnel_id = pi.id AND pss2.vessel_id = vesselID_
        ))
  ORDER BY pi.lastname ASC, pi.firstname ASC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-08-26  5:26:30
