-- ============================================================
-- UMMI PDS — Crew Management Module
-- 03_seed_data.sql  |  Demo accounts + reference + sample crew
-- Password hash for "Demo123!" using SHA-256 (hex)
-- SHA2("Demo123!",256) = d7c2b64f96e8bdf3d45dfca0a8a5d32bca0d5c5de58fb2b8e7f8b7a6e1f0c4a2
-- (actual hash computed below by MySQL itself)
-- ============================================================
USE `ummi_crew`;

-- ===================== MANAGEMENT ============================
INSERT IGNORE INTO `tbl_management` (id, management) VALUES
  (1, 'UMMI Manning Office');

-- ===================== USER TYPES ============================
INSERT IGNORE INTO `tbl_user_type` (id, user_type) VALUES
  (1, 'MANNING_STAFF'),
  (2, 'SUPER_ADMIN'),
  (3, 'PRINCIPAL'),
  (4, 'APPLICANT');

-- ===================== DEMO ACCOUNTS =========================
-- Password: Demo123!
INSERT IGNORE INTO `tbl_users`
  (id, username, password, fullname, type, management, viewcrewcontactdetails, viewcreatecontract, disable_user)
VALUES
  (1, 'demo.manning',    SHA2('Demo123!',256), 'Manning Staff Demo',  'MANNING_STAFF', 1, 1, 1, 0),
  (2, 'demo.superadmin', SHA2('Demo123!',256), 'Super Admin Demo',    'SUPER_ADMIN',   1, 1, 1, 0),
  (3, 'demo.principal',  SHA2('Demo123!',256), 'Principal Demo',      'PRINCIPAL',     1, 0, 0, 0),
  (4, 'demo.applicant',  SHA2('Demo123!',256), 'Applicant Demo',      'APPLICANT',     1, 0, 0, 0);

-- ===================== PRINCIPALS ============================
INSERT IGNORE INTO `tbl_principals` (id, name) VALUES
  (1, 'Mitsui O.S.K. Lines'),
  (2, 'Nippon Yusen Kaisha'),
  (3, 'Evergreen Marine Corp');

-- ===================== VESSEL TYPES ==========================
INSERT IGNORE INTO `tbl_type_of_vessel` (id, typeOfVessel) VALUES
  (1, 'Bulk Carrier'),
  (2, 'Container Ship'),
  (3, 'Tanker'),
  (4, 'General Cargo'),
  (5, 'LNG/LPG Carrier'),
  (6, 'Passenger / RORO');

-- ===================== VESSELS ================================
INSERT IGNORE INTO `tbl_vessels` (id, vesselName, agency, active, VesselType, principal, management) VALUES
  (1, 'MV UMMI STAR',    'MOL Philippines', 'Active', 1, 1, 1),
  (2, 'MV PACIFIC DAWN', 'NYK Line',        'Active', 2, 2, 1),
  (3, 'MT MINDANAO',     'Evergreen',       'Active', 3, 3, 1),
  (4, 'MV CEBU PRIDE',   'MOL Philippines', 'Active', 4, 1, 1);

-- ===================== RANKS =================================
INSERT IGNORE INTO `tbl_rank` (id, rank_code, rank_type, sequence) VALUES
  (1,  'MASTER',          'Deck',    1),
  (2,  'CHIEF OFFICER',   'Deck',    2),
  (3,  '2ND OFFICER',     'Deck',    3),
  (4,  '3RD OFFICER',     'Deck',    4),
  (5,  'CHIEF ENGINEER',  'Engine',  1),
  (6,  '2ND ENGINEER',    'Engine',  2),
  (7,  '3RD ENGINEER',    'Engine',  3),
  (8,  '4TH ENGINEER',    'Engine',  4),
  (9,  'BOSUN',           'Rating',  1),
  (10, 'AB SEAMAN',       'Rating',  2),
  (11, 'OS',              'Rating',  3),
  (12, 'CHIEF COOK',      'Catering',1),
  (13, 'STEWARD',         'Catering',2),
  (14, 'DECK CADET',      'Cadet',   1),
  (15, 'ENGINE CADET',    'Cadet',   2);

-- ===================== REFERENCE DATA ========================
INSERT IGNORE INTO `tbl_religion` (id, religion) VALUES
  (1,'Roman Catholic'),(2,'Islam'),(3,'Iglesia ni Cristo'),(4,'Seventh Day Adventist'),(5,'Others');

INSERT IGNORE INTO `tbl_nationality` (id, nationality) VALUES
  (1,'Filipino'),(2,'Other');

INSERT IGNORE INTO `tbl_relationship` (id, relationship, sequence) VALUES
  (1,'Spouse',1),(2,'Child',2),(3,'Parent',3),(4,'Sibling',4),(5,'Others',5);

INSERT IGNORE INTO `tbl_school` (id, school_name) VALUES
  (1,'Philippine Maritime Institute'),
  (2,'John B. Lacson Foundation Maritime University'),
  (3,'Philippine Merchant Marine Academy'),
  (4,'STI College'),
  (5,'AMA Computer University'),
  (6,'Others');

INSERT IGNORE INTO `tbl_course` (id, course) VALUES
  (1,'Bachelor of Science in Marine Transportation'),
  (2,'Bachelor of Science in Marine Engineering'),
  (3,'Others');

-- ===================== PROVINCES / CITIES ====================
INSERT IGNORE INTO `tbl_provinces` (id, provinces) VALUES
  (1,'Metro Manila'),(2,'Cebu'),(3,'Batangas'),(4,'Pangasinan'),(5,'Cavite');

INSERT IGNORE INTO `tbl_cities` (id, cities, province) VALUES
  (1,'Manila',1),(2,'Quezon City',1),(3,'Makati',1),
  (4,'Cebu City',2),(5,'Mandaue',2),(6,'Lapu-Lapu',2),
  (7,'Batangas City',3),(8,'Lipa City',3),
  (9,'Dagupan City',4),(10,'Alaminos',4),
  (11,'Bacoor',5),(12,'Imus',5);

-- ===================== DROPDOWN SELECTIONS ===================
INSERT IGNORE INTO `tbl_dropdown_selection` (id, type, meaning, sequence) VALUES
  (1,'crew_status','ACTIVE',1),
  (2,'crew_status','INACTIVE',2),
  (3,'crew_status','ON BOARD',3),
  (4,'crew_status','ON VACATION',4),
  (5,'crew_status','APPLICANT',5),
  (6,'crew_status','LINE UP',6);

-- ===================== DOCUMENTS TEMPLATE ====================
INSERT IGNORE INTO `tbl_documents` (id, documentName, docType, month_expiry_warning, sequence) VALUES
  -- Personal
  (1, 'Passport',                        'Personal',  3, 1),
  (2, 'NBI Clearance',                   'Personal',  1, 2),
  (3, "Driver's License",                'Personal',  3, 3),
  (4, 'Birth Certificate',               'Personal',  0, 4),
  (5, 'Marriage Certificate',            'Personal',  0, 5),
  -- License
  (6, "Seafarer's Book (Seaman's Book)", 'License',   3, 1),
  (7, 'COC (Certificate of Competency)', 'License',   3, 2),
  (8, 'GOC (GMDSS)',                     'License',   3, 3),
  (9, "Officer's Watch Permit",          'License',   3, 4),
  -- Medical
  (10,'PEME (Pre-Employment Medical Exam)', 'Medical', 1, 1),
  (11,'Yellow Fever Vaccination',           'Medical', 6, 2),
  (12,'Drug Test Result',                   'Medical', 1, 3),
  -- Training
  (13,'STCW BST Certificate',   'Training', 6, 1),
  (14,'PDOS Certificate',       'Training', 12,2),
  (15,'APAT Certificate',       'Training', 12,3),
  (16,'PETE Certificate',       'Training', 12,4),
  (17,'Proficiency in Tanker',  'Training', 12,5),
  -- Outsource
  (18,'Flag State Certificate', 'Outsource',6, 1),
  -- UMMI
  (19,'UMMI Training Certificate','UMMI',  12,1),
  (20,'UMMI COE',                 'UMMI',   0, 2);

-- ===================== SAMPLE CREW (15 realistic seafarers) ==

-- 1. Active - On Board
INSERT IGNORE INTO `tbl_personnel_info`
  (id,firstname,middlename,lastname,position,religion,nationality,crew_status,crew_availability,
   date_of_birth,gender,civil_status,height,weight,email_address,applicant_contact_num,
   address,province,city,sss,tin,pagibig,philhealth,cadetship,jocap,higher_license,date_hired)
VALUES
(1,'Juan','Santos','Dela Cruz',2,1,1,3,0,'1985-03-15','Male','Married',175,75,
 'juan.delacruz@email.com','09171234567','123 Rizal St., Brgy. Bagong Buhay',1,1,
 '03-4567890-1','123-456-789-000','1234567890','12-345678901-2',0,0,1,'2010-06-01'),

(2,'Maria','Reyes','Santos',3,1,1,4,1,'1990-07-22','Female','Single',160,55,
 'maria.santos@email.com','09281234567','456 Mabini Ave, Cebu City',2,4,
 '03-5678901-2','234-567-890-000','2345678901','23-456789012-3',0,0,0,'2015-03-10'),

(3,'Roberto','Lim','Garcia',5,2,1,3,0,'1978-11-08','Male','Married',170,80,
 'roberto.garcia@email.com','09391234567','789 Bonifacio St., Batangas',3,7,
 '03-6789012-3','345-678-901-000','3456789012','34-567890123-4',0,1,1,'2005-01-15'),

(4,'Ernesto','Cruz','Bautista',1,1,1,4,1,'1972-05-30','Male','Married',168,78,
 'ernesto.bautista@email.com','09501234567','321 Luna St., Dagupan',4,9,
 '03-7890123-4','456-789-012-000','4567890123','45-678901234-5',0,0,1,'2000-08-20'),

(5,'Ana','Villanueva','Torres',4,1,1,1,1,'1992-12-01','Female','Single',158,52,
 'ana.torres@email.com','09611234567','654 Quezon Blvd, Bacoor',5,11,
 '03-8901234-5','567-890-123-000','5678901234','56-789012345-6',0,0,0,'2018-02-28'),

(6,'Carlos','Mendoza','Flores',6,1,1,1,1,'1988-09-14','Male','Married',172,77,
 'carlos.flores@email.com','09721234567','987 Del Pilar St., Manila',1,1,
 '03-9012345-6','678-901-234-000','6789012345','67-890123456-7',1,0,0,'2013-07-01'),

(7,'Jose','Aquino','Reyes',9,3,1,1,1,'1987-04-18','Male','Married',165,70,
 'jose.reyes@email.com','09831234567','147 Taft Ave, Makati',1,3,
 '04-0123456-7','789-012-345-000','7890123456','78-901234567-8',0,0,0,'2012-04-15'),

(8,'Patricia','Gonzales','Marquez',12,1,1,3,0,'1983-08-25','Female','Married',155,58,
 'patricia.marquez@email.com','09941234567','258 Shaw Blvd, Cebu City',2,4,
 '04-1234567-8','890-123-456-000','8901234567','89-012345678-9',0,0,0,'2008-11-30'),

(9,'Michael','Rivera','Castillo',7,1,1,1,1,'1993-02-14','Male','Single',175,73,
 'michael.castillo@email.com','09051234567','369 EDSA, Quezon City',1,2,
 '04-2345678-9','901-234-567-000','9012345678','90-123456789-0',0,0,0,'2019-09-01'),

(10,'Lourdes','Serrano','Padilla',3,1,1,2,0,'1989-06-30','Female','Single',162,57,
 'lourdes.padilla@email.com','09161234567','741 Quirino Ave, Lipa City',3,8,
 '04-3456789-0','012-345-678-000','0123456789','01-234567890-1',0,0,0,'2014-05-20'),

(11,'Ferdinand','Hidalgo','Navarro',2,2,1,1,1,'1986-10-05','Male','Married',173,76,
 'ferdinand.navarro@email.com','09271234567','852 Claro M. Recto, Mandaue',2,5,
 '04-4567890-1','123-456-780-000','1234567891','12-345678902-3',0,0,1,'2011-12-01'),

(12,'Gloria','Aguilar','Santos',13,1,1,4,1,'1991-03-22','Female','Single',157,54,
 'gloria.santos2@email.com','09381234567','963 Rizal Ave, Lapu-Lapu',2,6,
 '04-5678901-2','234-567-890-111','2345678902','23-456789013-4',0,0,0,'2017-07-15'),

-- 3 applicants
(13,'Angelo','Bernardo','Cruz',10,1,1,5,1,'1998-11-20','Male','Single',170,68,
 'angelo.cruz@email.com','09491234567','147 Gen. Luna, Manila',1,1,
 NULL,NULL,NULL,NULL,0,0,0,'2026-01-10'),

(14,'Josefa','Castillo','Morales',4,1,1,5,1,'1999-05-15','Female','Single',160,53,
 'josefa.morales@email.com','09601234567','258 Taft Ave, Cebu City',2,4,
 NULL,NULL,NULL,NULL,0,0,0,'2026-02-20'),

(15,'Renato','Lopez','Villanueva',14,1,1,5,1,'2000-08-08','Male','Single',168,65,
 'renato.villanueva@email.com','09711234567','369 Shaw, Bacoor',5,11,
 NULL,NULL,NULL,NULL,1,0,0,'2026-03-05');

-- ===================== SEA SERVICE HISTORY ===================
INSERT IGNORE INTO `tbl_personnel_sea_service`
  (id,personnel_id,vessel_id,rank_id,date_from,date_to,remarks) VALUES
  (1, 1, 1, 2, '2022-01-15', '2023-01-14', 'Completed contract'),
  (2, 1, 2, 2, '2020-03-01', '2021-02-28', 'Completed contract'),
  (3, 2, 2, 3, '2023-06-01', '2024-05-31', 'Completed contract'),
  (4, 3, 3, 5, '2022-08-10', '2023-08-09', 'Completed contract'),
  (5, 4, 1, 1, '2021-05-01', '2022-04-30', 'Completed contract'),
  (6, 6, 4, 6, '2023-01-01', '2023-12-31', 'Completed contract'),
  (7, 7, 1, 9, '2023-03-15', '2024-03-14', 'Completed contract'),
  (8, 8, 3, 12,'2022-07-01', '2023-06-30', 'Completed contract'),
  (9, 9, 2, 7, '2024-01-01', NULL,          'Current contract'),
  (10,11, 4, 2, '2023-09-01', '2024-08-31', 'Completed contract');

-- ===================== CONTRACTS =============================
INSERT IGNORE INTO `tbl_contracts`
  (id,personnel_id,vessel_id,rank_id,date_from,date_to,status,remarks) VALUES
  (1, 1, 1, 2, '2023-02-01', '2024-01-31', 'Completed', 'Regular 9-month contract'),
  (2, 3, 3, 5, '2023-09-01', NULL,          'Active',    'Current contract'),
  (3, 4, 1, 1, '2022-05-01', '2023-04-30', 'Completed', 'Completed full term'),
  (4, 8, 3, 12,'2023-07-01', NULL,          'Active',    'Current contract');

-- ===================== FAMILY INFO ===========================
INSERT IGNORE INTO `tbl_personnel_family_info`
  (id,personnel_id,relationship,fname,lname,date_of_birth,contact,dependent) VALUES
  (1, 1, 1, 'Maria', 'Dela Cruz', '1987-06-10', '09171111111', 1),
  (2, 1, 2, 'Jose',  'Dela Cruz', '2010-01-05', NULL,          1),
  (3, 3, 1, 'Anna',  'Garcia',    '1980-03-15', '09391111111', 1),
  (4, 4, 1, 'Elena', 'Bautista',  '1974-09-20', '09501111111', 1),
  (5, 4, 2, 'Ramon', 'Bautista',  '2000-11-11', NULL,          0);

-- ===================== PERSONAL DOCUMENTS ====================
INSERT IGNORE INTO `tbl_personnel_documents`
  (id,personnel_id,document_id,document_num,date_issued,date_expiry) VALUES
  (1,  1, 1, 'P123456789', '2020-01-10', '2030-01-09'),
  (2,  1, 6, 'SB-2023-001','2023-01-15', '2028-01-14'),
  (3,  1, 7, 'COC-2022-01','2022-06-01', '2027-05-31'),
  (4,  1,10, 'PEME-001',   '2026-06-01', '2027-05-31'),
  (5,  1,13, 'BST-001',    '2021-03-01', '2026-03-01'), -- expiring soon!
  (6,  2, 1, 'P234567890', '2021-05-20', '2031-05-19'),
  (7,  2, 6, 'SB-2023-002','2023-05-01', '2028-04-30'),
  (8,  3, 1, 'P345678901', '2019-08-12', '2029-08-11'),
  (9,  3, 5, 'COE-001',    '2022-01-01', NULL),
  (10, 4, 1, 'P456789012', '2018-11-30', '2028-11-29');

-- ===================== COMMENTS / ASSESSMENTS ================
INSERT IGNORE INTO `tbl_personnel_comment`
  (id,personnel_id,comments,date_sent,principal_view,added_by_name) VALUES
  (1, 1, 'Excellent leadership. Highly recommended for promotion.', '2023-12-01', '0', 'Manning Staff Demo'),
  (2, 1, 'On time for sign-on. No disciplinary issues on record.', '2024-01-15', '0', 'Manning Staff Demo'),
  (3, 3, 'Strong engine room performance. JOCAP eligible.', '2023-09-15', '0', 'Manning Staff Demo'),
  (4, 4, 'Senior master with exemplary record. 24 years of experience.', '2024-02-01', '0', 'Super Admin Demo');

-- ===================== APPLICANT GENERATED LINK ==============
INSERT IGNORE INTO `tbl_applicant_generated_link`
  (id,fullname,email,position_applied,validity,status,date_generated,generated_by,link_token) VALUES
  (1, 'Pedro Magsaysay',     'pedro@email.com',   'AB SEAMAN',   '2026-08-31 23:59:59', 'Active',  '2026-08-01 09:00:00', 1, 'DEMO_TOKEN_001'),
  (2, 'Rosa Aguinaldo',      'rosa@email.com',    '3RD OFFICER', '2026-07-15 23:59:59', 'Expired', '2026-07-01 09:00:00', 1, 'DEMO_TOKEN_002'),
  (3, 'Andres Bonifacio Jr.','andres@email.com',  'OS',          '2026-09-30 23:59:59', 'Active',  '2026-08-05 10:00:00', 1, 'DEMO_TOKEN_003');

-- ===================== USER ACCESS LIST ======================
INSERT IGNORE INTO `tbl_user_access_list` (id, description) VALUES
  (1,  'Home'),
  (2,  'Query Crew'),
  (51, 'Query Crew Page'),
  (54, 'Files (Personnel + Applicant)'),
  (55, 'Personnel File'),
  (56, 'Applicant File'),
  (70, 'Crew Status'),
  (91, 'PDS Reports'),
  (183,'Applicant Pool');

SELECT 'Seed data inserted successfully.' AS Result;
