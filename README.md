# UMMI Crew Management Module
### ASP.NET Web Forms (.NET 4.8) | MySQL | Bootstrap 5 | Alpine.js
**Capstone Development Project — Independent Module v1.0**

---

## Quick Start (5 Steps)

### Step 1 — Prerequisites
| Requirement | Version | Notes |
|-------------|---------|-------|
| Visual Studio | 2022 (Community+) | With "ASP.NET and web development" workload |
| .NET Framework | 4.8 | Windows SDK |
| MySQL Server | 5.7 or 8.4.9 portable | localhost:3306, root, no password |
| NuGet | Latest | Comes with VS2022 |

### Step 2 — Database Setup
```
cd c:\UMMI\CrewMgmt
run_database_setup.bat
```
This creates the `ummi_crew` database, all 29 tables, stored procedures, and demo data.

To supply a custom MySQL path:
```
run_database_setup.bat "C:\mysql-8.4.9\bin\mysql.exe"
```

### Step 3 — Restore NuGet Packages
Open `CrewMgmt.sln` in Visual Studio, then:
```
Tools → NuGet Package Manager → Package Manager Console
> Update-Package -reinstall
```
Or from the root: `restore_packages.bat`

### Step 4 — Configure Connection String (if needed)
Edit `CrewMgmt\Web.config` line 4 if your MySQL credentials differ:
```xml
connectionString="server=localhost;port=3306;database=ummi_crew;uid=root;pwd=;"
```

### Step 5 — Run
Press **F5** in Visual Studio. IIS Express starts at `http://localhost:PORT/login.aspx`.

---

## Demo Accounts

| Username | Password | Role | Access |
|----------|----------|------|--------|
| `demo.manning` | `Demo123!` | MANNING_STAFF | Crew Search, Applicant Pool, Personnel File |
| `demo.superadmin` | `Demo123!` | SUPER_ADMIN | All of above + Activity Logs |
| `demo.principal` | `Demo123!` | PRINCIPAL | Crew Search (read-only, no contact details) |
| `demo.applicant` | `Demo123!` | APPLICANT | Self-Encode form only |

**Applicant link flow:** Login as `demo.manning`, go to **Applicant Pool → Generate Applicant Link**, copy the URL, and open it in a new browser tab/incognito window.

---

## Module Structure

```
CrewMgmt.sln
│
├─ Database\
│   ├─ 01_schema.sql              ← 29 tables (ERD v1.0)
│   ├─ 02_stored_procedures.sql   ← spQueryCrewSearchDisplay, spApplicantPoolSearchDisplay
│   └─ 03_seed_data.sql           ← 4 demo accounts + 15 crew + reference data
│
├─ App_Code\
│   ├─ CryptoHelper.vb            ← AES-256 Encrypt/Decrypt, SHA-256 hash
│   ├─ AuditHelper.vb             ← GetAdmin / GetPortalAct / GetPersonnelAct
│   ├─ DbHelper.vb                ← MySqlConnection factory + FillDataTable
│   ├─ ExportHelper.vb            ← ClosedXML Excel export
│   └─ RoleHelper.vb              ← CurrentRole, RequireLogin, RequireRole, CanViewContactDetails
│
├─ masterPage.Master              ← 4-role sidebar navigation + topbar
├─ login.aspx                     ← FormsAuth + encrypted applicant link handler
├─ Home.aspx                      ← Dashboard: stats, expiring docs, recent activity
│
├─ Crew\
│   ├─ QueryCrew.aspx             ← UC-CM-01..06 — Full crew search with 12 filters
│   ├─ ProfileViewer.aspx         ← UC-CM-07..12 — Profile: 6 doc tabs, sea service, BMI, family
│   └─ Print.aspx                 ← UC-CM-04 — Print crew list / data sheet
│
├─ Applicant\
│   ├─ ApplicantPool.aspx         ← UC-CM-13..23 — Pool search + link generation + hire
│   └─ SelfEncode.aspx            ← UC-CM-24 — 3-step self-encode form (accessible via link)
│
├─ Personnel\
│   ├─ PersonnelFile.aspx         ← WBS 1.4.1 — CRUD list with links to profile/COE/certs
│   ├─ COE.aspx                   ← WBS 1.4.2 — Certificate of Employment generator
│   ├─ Certificates.aspx          ← WBS 1.4.3 — APAT/PDOS/PETE with expiry colour-coding
│   ├─ TrainingCompliance.aspx    ← WBS 1.4.4 — Training doc compliance per rank
│   └─ ContractTracing.aspx       ← WBS 1.4.5 — Contract history with Gantt bars
│
├─ Settings\
│   └─ ActivityLogs.aspx          ← SUPER_ADMIN only — filterable audit log + Excel export
│
├─ css\site.css                   ← Full design system (Bootstrap 5 + custom tokens)
└─ scripts\site.js                ← Alpine.js stores + clipboard + loading overlay helpers
```

---

## Use Case Coverage

| UC | Name | Page | Role |
|----|------|------|------|
| UC-CM-01 | Crew Search by Filters | QueryCrew.aspx | Manning, Admin, Principal |
| UC-CM-02 | Reset Search Filters | QueryCrew.aspx | Manning, Admin, Principal |
| UC-CM-03 | View Search Results | QueryCrew.aspx | Manning, Admin, Principal |
| UC-CM-04 | Print Crew List | Print.aspx | Manning, Admin |
| UC-CM-05 | Export Crew List (Excel) | QueryCrew.aspx | Manning, Admin |
| UC-CM-06 | Crew Count & Avg Age | QueryCrew.aspx | Manning, Admin, Principal |
| UC-CM-07 | View Crew Profile | ProfileViewer.aspx | Manning, Admin, Principal |
| UC-CM-08 | View Document Tabs | ProfileViewer.aspx | Manning, Admin, Principal |
| UC-CM-09 | Document Expiry Colour | ProfileViewer.aspx | Manning, Admin, Principal |
| UC-CM-10 | View Sea Service History | ProfileViewer.aspx | Manning, Admin |
| UC-CM-11 | View Family & HMO | ProfileViewer.aspx | Manning, Admin |
| UC-CM-12 | View Assessments | ProfileViewer.aspx | Manning, Admin |
| UC-CM-13 | Applicant Pool Search | ApplicantPool.aspx | Manning, Admin |
| UC-CM-14 | View Applicant Profiles | ApplicantPool.aspx | Manning, Admin |
| UC-CM-15 | Applicant Count & Avg Age | ApplicantPool.aspx | Manning, Admin |
| UC-CM-16 | View Vessel Experience | ApplicantPool.aspx | Manning, Admin |
| UC-CM-17 | Generate Applicant Link | ApplicantPool.aspx | Manning, Admin |
| UC-CM-18 | Display Generated Link | ApplicantPool.aspx | Manning, Admin |
| UC-CM-19 | Manage Links List | ApplicantPool.aspx | Manning, Admin |
| UC-CM-20 | Expire Applicant Link | ApplicantPool.aspx | Manning, Admin |
| UC-CM-21 | Link Expiry Colour-Coding | ApplicantPool.aspx | Manning, Admin |
| UC-CM-22 | Hire Applicant | ApplicantPool.aspx | Manning, Admin |
| UC-CM-23 | Add Applicant Manually | PersonnelFile.aspx | Manning, Admin |
| UC-CM-24 | Applicant Self-Encode | SelfEncode.aspx | Applicant |
| UC-CM-25 | COE / Certificate Generation | COE.aspx, Certificates.aspx | Manning, Admin |
| UC-CM-26 | Training Compliance Export | TrainingCompliance.aspx | Manning, Admin |

---

## Security Model

- **Authentication:** `FormsAuthentication` with 60-minute sliding session
- **URL encryption:** AES-256 CBC for all ID parameters (`?ID=`, `?e=`)
- **Role enforcement:** `RequireRole()` called at top of every Page_Load
- **Audit trail:** Every navigation, search, and data action logged to `tbl_activity_log`
- **Applicant links:** Time-limited encrypted tokens; expire after use or validity date

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | ASP.NET Web Forms (.NET 4.8), Bootstrap 5.3, Alpine.js 3.13 |
| Backend | VB.NET (.NET 4.8 host), App_Code modules |
| Database | MySQL 5.7 / 8.4 — MySql.Data ADO.NET 8.0.33 |
| Export | ClosedXML 0.90 (Excel) |
| Auth | FormsAuthentication + SHA-256 password hashing |

---

## Known Demo Limitations

1. **No SMTP** — Generated applicant links are shown in a modal/copy button (no email sending).
2. **File uploads** — Photo upload UI not yet wired; `~/Uploads/picture/` folder is ready.
3. **Leaflet map** — Province/city map prototype is a placeholder (CSS-ready, page not yet built).
4. **NuGet packages** — Must be restored before first build (`restore_packages.bat`).

---

*UMMI Manning Corporation — Capstone Project 2026*
