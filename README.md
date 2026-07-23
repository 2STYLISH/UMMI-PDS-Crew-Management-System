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

## Tech Stack

| Layer | Technology |
|---|---|
| Application Framework | ASP.NET Web Forms (.NET Framework 4.8) |
| Backend Language | VB.NET |
| Database | MySQL 8.0 |
| Cloud Hosting | Microsoft Azure App Service |
| Version Control | GitHub |

---

## Environments

| Environment | Purpose | Profile |
|---|---|---|
| Production | Live UMMI operations | `pds-pdn` |
| UAT / Staging | Testing and User Acceptance Testing | `pds-pdn-uat` |
| Test Database | Isolated database for development and UAT | `db_pds_tst` |

> ⚠️ All development and testing activities must be conducted against the UAT environment only. Never test directly against the production environment.

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

## Getting Started

### Prerequisites
- Visual Studio 2019 or later
- .NET Framework 4.8
- MySQL 8.0
- Access to UMMI Azure publish profiles (provided by UMMI Technical Representative)

### Setup
1. Clone the repository
```bash
git clone https://github.com/[repo-url]/ummi-pds.git
```
2. Open the solution in Visual Studio
3. Configure the connection string in `Web.config` to point to `db_pds_tst` (test database)
4. Build the solution
5. Publish to the UAT environment using the `pds-pdn-uat` publish profile

> 🔒 Never commit connection strings, credentials, or Azure publish profiles to the repository.

---

## Branch Strategy

| Branch | Purpose |
|---|---|
| `main` | Production-ready code only |
| `develop` | Active development branch |
| `feature/[feature-name]` | Individual feature branches |

All changes must go through a Pull Request and be reviewed by the Lead Developer before merging to `develop`.

---

## WBS Reference

| Component | WBS Code |
|---|---|
| Crew Query & Search | 1.1 |
| Profile Viewer | 1.2 |
| Applicant Pool | 1.3 |
| Personnel File Management | 1.4 |

---

## License

This system is developed as an academic project under the Asia Pacific College PBL engagement with Unitra Maritime Manila Inc. All source code and documentation are the intellectual property of UMMI upon formal project handover on October 6, 2026.

---

*ByteMe — Asia Pacific College | APC 2025–2026 Term 3*
