# UMMI-PDS Crew Management Module
**ByteMe Development Team — Asia Pacific College**
> A crew management module built as an enhancement to the existing UMMI Personnel Data Sheet (PDS) System.

---

## Overview

The **UMMI-PDS Crew Management Module** is an internal web-based system developed for **Unitra Maritime Manila Inc. (UMMI)** — a maritime manning agency in the Philippines. The module extends the existing PDS System to support the full workflow for maritime crew and applicants, from search and review through recruitment, compliance monitoring, and personnel file management.

This project is developed under the **Asia Pacific College Project-Based Learning (PBL)** academic engagement.

---

## Features

### 1. Crew Query & Search
- Multi-criteria crew search with filters for rank, crew status, vessel assignment, geographic origin, and vessel experience
- Paginated search results with Excel export support
- Role-based visibility controls per department
- Audit trail logging for all search activity
- Crew count and average age summary

### 2. Profile Viewer
- Read-only crew profile with 9 sections
- BMI calculation and age auto-calculation
- Document compliance monitoring across 6 document categories (Personal, License, Medical, Training, Outsource, UMMI Certificates)
- Color-coded document expiry alerts (Green / Amber / Red)
- Statutory benefit display (SSS, PhilHealth, Pag-IBIG, TIN)
- Sea service history with auto-calculated service period and total years
- Scanned document image viewer

### 3. Applicant Pool
- Applicant search and listing with profile photo display
- Encrypted single-use onboarding link generation
- Link lifecycle tracking (Active / Expired / Used)
- Bulk link expiration by validity date
- Formal Applicant-to-Crew hiring workflow

### 4. Personnel File Management
- Full crew record CRUD management
- Certificate of Employment (COE) generation
- Training certificate creation (APAT / PDOS / PETE)
- STCW training compliance view
- Crew contract tracing

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

## Project Team

| Name | Role |
|---|---|
| Ryan Elijah S. Luar | Project Manager |
| Ishmael Neal D. Pablo | Lead Developer |
| Isaac Angelo D. Estabillo | Frontend Developer / Scrum Master |
| Jeross Reilan R. Perez | QA / Test Lead |

**Client:** Kazey Naval — Unitra Maritime Manila Inc. (UMMI)
**Adviser:** Felino Calderon — Asia Pacific College

---

## Project Timeline

| Phase | Period |
|---|---|
| Planning | April – May 2026 |
| Design | May – June 2026 |
| Development | July – September 2026 |
| UAT | September 21 – October 2, 2026 |
| Deployment & Handover | October 3 – 6, 2026 |

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
| Cloud Hosting | Microsoft Azure App Service |
| Version Control | GitHub |

---

## License

This system is developed as an academic project under the Asia Pacific College PBL engagement with Unitra Maritime Manila Inc. All source code and documentation are the intellectual property of UMMI upon formal project handover on October 6, 2026.

---

*ByteMe — Asia Pacific College | APC 2025–2026 Term 3*
