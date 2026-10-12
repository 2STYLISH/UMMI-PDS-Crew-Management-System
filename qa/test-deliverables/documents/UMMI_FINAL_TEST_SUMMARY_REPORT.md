# UMMI Crew Management System — Consolidated Final Test Summary Report (Cycle 1 & Cycle 2)

> **Document Identifier:** `UMMI_FINAL_TEST_SUMMARY_REPORT.md`  
> **Package Location:** [`qa/test-deliverables/documents/UMMI_FINAL_TEST_SUMMARY_REPORT.md`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/UMMI_FINAL_TEST_SUMMARY_REPORT.md)  
> **Execution Cycles Covered:** Cycle 1 (Initial Verification) & Cycle 2 (Automated & Focused Retest)  
> **Authoritative SRS Baseline:** [`documents/ByteMe SRS - UMMI.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/ByteMe%20SRS%20-%20UMMI.docx) (1,422,993 bytes | SHA-256: `96b220779905dd31f49083ad6606398812269825d4d0200a2657a0bca950ed45`)  
> **Authoritative Workbook with RTM:** [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Contains dedicated 11-column `RTM` tab with 304 mapping rows)  
> **Authoritative Execution Workbook:** [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Worksheets: `Cover Page`, `Test Plan`, `Summary`, `Cycle1`, `Cycle2`, `Lists`, `Evidence`)  
> **Target Staging Host:** Microsoft Azure App Service (`Southeast Asia`) | IIS 10.0 | ASP.NET 4.0 | Azure Database for MySQL 8.0  
> **Target Staging URL:** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`  
> **Release Recommendation:** **NOT YET READY FOR RELEASE** (Conditional staging availability for client review discussed separately)  

---

## 1. Project, Environment, and Test Objectives

### 1.1 Project Overview
The **Unitra Maritime Manila Inc. (UMMI) Crew Management System (Personal Data Sheet - PDS)** is an enterprise web application designed to govern maritime personnel operations. The module manages crew queries, multi-criteria filtering, comprehensive sea service records, crew profile inspections, statutory and medical checklist evaluations, crew change scheduling, applicant pool intake, applicant self-encoding portals, and optical character recognition (OCR) with AI-assisted resume data extraction.

### 1.2 Target Staging Environment Architecture
All test execution and verification occurred against the live deployed staging environment:
- **Cloud Infrastructure:** Microsoft Azure App Service (Plan: `Free F1`, Region: `Southeast Asia`)
- **Web Server:** Microsoft-IIS/10.0, running ASP.NET 4.0 (`.NET Framework` WebForms / VB.NET runtime)
- **Database Backend:** Azure Database for MySQL Flexible Server (`ummi-db-server`, MySQL 8.0 engine)
- **AI Processing Layer:** DeepInfra REST API integration (ephemeral OCR parsing and structured resume extraction)
- **Staging Endpoint:** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`

### 1.3 Core Test Objectives
The Quality Assurance campaign was structured across two rigorous execution cycles to achieve four overarching objectives:
1. **Specification Verification:** Validate all requirements established in the authoritative baseline specification ([`ByteMe SRS - UMMI.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/ByteMe%20SRS%20-%20UMMI.docx)), spanning 79 Functional Requirements, 17 active Security Rules, 28 Use Cases, and 8 Performance Requirements.
2. **Defect Remediation & Regression Containment:** Formally track all cataloged product defects (`DEF-CM-001` through `DEF-CM-020`) from initial discovery through staging deployment, verifying that code patches remediated identified flaws without inducing regression.
3. **Multi-Role Security & Boundary Enforcement:** Prove that role-based access control (RBAC), per-user permission overrides, document download endpoint authorization, and sensitive credential hashing enforce strict maritime data isolation.
4. **End-to-End Workflow Reliability:** Evaluate complex business processes including Crew Change List (CCL) lifecycle transitions, applicant invitation link validity, and AI-assisted data parsing with human-in-the-loop review.

---

## 2. Scope, Exclusions, Testing Methods, Tools, and Isolated Test Data

### 2.1 Scope of Verification
The verification scope encompasses all user-facing, administrative, and integration workflows defined in the SRS:
- **Crew Search & Query (`FR-CM-01..04`, `UC-CM-01`):** Multi-criteria filtering (rank, vessel, availability, province, status, license, cadetship, JOCAP), vessel grouping, result counts, and Excel list export.
- **Crew Profile Inspection (`FR-CM-05..24`, `UC-CM-02..13`):** 9-tab profile viewer (Basic Info, Licenses, Training/Certificates, Sea Service, Documents, Medical, Financial, Remarks, Activity Log), BMI calculation, and dynamic age computation.
- **Reports & Checklists (`FR-CM-25..27`, `UC-CM-26..27`):** Releasing checklist configuration, generation, and formatted export.
- **Applicant Pool & Self-Encoding Portals (`FR-CM-28..51`, `UC-CM-14..25`):** Applicant search, hiring transitions, tokenized link generation, email composition, link expiration boundaries, and applicant self-encoding.
- **Access Control & RBAC (`FR-CM-52..53`, `SR-01..02`):** Role-specific page access across Admin, Super-Admin, Manning Staff, Documentation Officer, Principal, and Vessel Owner.
- **AI-Assisted Document Extraction (`FR-CM-54..78`, `UC-CM-28`, `SR-10..18`, `PR-07..08`):** Multi-format resume upload (PDF/DOCX/PNG/JPEG), OCR parsing, suggestion review with scalar accept/reject controls, and transactional commitment.
- **Crew Change List Management (`FR-CM-79`, `UC-CM-07`):** Vessel-specific crew rosters, reliever nomination/approval, tentative and next scheduling, End of Contract (EOC) record creation/cancellation, and sign-on execution.

### 2.2 Formal Exclusions
1. **Retired Functional Scope (`REQ-CM-006` / `FR-CM-20`):** Extra PDS-only columns removed from Section 3 of the uploaded SRS baseline (`TC-CM-099` classified as **Out of Scope**).
2. **Retired Supplier Approval Scope (`REQ-CM-005` / `SR-03`):** Supplier account approval workflows removed from the SRS (`TC-CM-185` classified as **Out of Scope**).
3. **DeepInfra Internal Infrastructure:** Third-party cloud OCR backend internal code and training architecture (evaluated solely through API boundary inputs, response contracts, and latency benchmarks).
4. **Destructive Staging Fault Injection (`QA-CM-001` / `TC-CM-222`):** Mid-transaction database termination omitted on the shared staging environment to prevent database corruption.

### 2.3 Testing Methods & Automated Tooling
- **Testing Methods:** Manual exploratory testing (Cycle 1); automated end-to-end regression testing, headless DOM locator assertion, HTTP status code inspection, role-switched session emulation, and synthetic load testing (Cycle 2).
- **Automation Framework:** Playwright v1.40+ (TypeScript / Chromium headless & WebKit engines).
- **Performance Benchmarking:** k6 v0.48+ load generator and automated Playwright navigation timing probes.
- **Workbook & Delivery Governance:** Python 3.13 and openpyxl for bit-level integrity verification, formula preservation, and RTM generation.

### 2.4 Controlled Synthetic Test Data & Fixtures
Testing strictly avoided modifying live production data through isolated synthetic fixtures:
- **Role Control Accounts:** `admin_qa` (Admin), `superadmin_qa` (Super-Admin), `manning_qa` (Manning Staff), `doc_qa` (Documentation Officer), `owner_qa` (Vessel Owner), and `principal_qa` (Principal).
- **Isolated Vessel Entities:** `QA Vessel A` (ID 1) and `QA Vessel B` (ID 2).
- **Synthetic Crew Records:** Personnel IDs 167, 168, 245 through 254 (including Lucas ID 252 for contract duration evaluation).
- **Synthetic Applicant Links:** Tokenized self-encoding sessions (Link IDs 416, 417, 418).
- **Synthetic Test Documents:** Standardized test CVs (`sample_maritime_cv.pdf`), synthetic training certificates, and dummy assessment PDFs.

---

## 3. Separate Cycle 1 and Cycle 2 Summaries

### 3.1 Cycle 1 Summary: Initial Verification Baseline
- **Execution Purpose:** Initial manual and exploratory baseline execution against early Azure staging deployments.
- **Recorded Scope:** **191 distinct test cases** (Rows 11 to 299 in the workbook's `Cycle1` sheet).
- **Cycle 1 Outcome Distribution:**
  - **Passed:** **116 cases (60.7% of 191)**
  - **Failed:** **13 cases (6.8% of 191)** (Logged into the initial defect register: `DEF-CM-001`, `002`, `004`, `005`, `006`, `007`, `009`, `011`, `012`, `013`, `014`, `017`, `019`)
  - **Skipped:** **20 cases (10.5% of 191)** (Due to unconfigured staging features, e.g. per-user access toggles)
  - **Unverified:** **41 cases (21.5% of 191)** (Blocked pending deployment of automated fixtures and newer module builds)
  - **Untested / Blank:** **1 case (0.5% of 191)** (`TC-CM-052`, active elapsed date warnings)
  - **Total Distinct Cases:** **191 cases (100.0% of 191)**

> [!WARNING]
> #### Cycle 1 Evidence Limitation Notice
> **No screenshots or external execution logs were found in the reviewed records.** Test case results, actual textual observations, and tester assignments for Cycle 1 were recorded directly inside the workbook's `Cycle1` worksheet by assigned testers.
> 
> In accordance with delivery governance:
> 1. Testing is characterized as manual/exploratory because historical workbook entries record assigned tester names and manual test step observations; testing methodology is not inferred merely from the absence of screenshots.
> 2. No screenshots or external execution logs exist in the repository artifacts; we do not recreate historical screenshots, invent retroactive evidence, or relabel Cycle 2 screenshots as Cycle 1.
> 3. The 75 test cases that did not pass in Cycle 1 (13 Failed, 20 Skipped, 41 Unverified, 1 Untested) were formally targeted for automated closure during Cycle 2.

### 3.2 Cycle 2 Summary: Automated Retest & Regression Suite
- **Execution Purpose:** Automated regression testing, defect remediation verification, gap closure for unverified Cycle 1 cases, and full verification of the newly deployed CCL and AI Document Extraction modules.
- **Recorded Scope:** **142 distinct test cases** (Worksheet `Cycle2` and `Evidence`).
- **Cycle 2 Outcome Distribution:**
  - **Passed:** **137 cases (96.5% of 142)** (Satisfied all functional and DOM locator assertions)
  - **Failed:** **1 case (0.7% of 142)** (`TC-CM-098`, ongoing sea service Philippine operational date calculation error / `DEF-CM-020`)
  - **Blocked:** **1 case (0.7% of 142)** (`TC-CM-077`, BMI cutoff evaluation basis, badge palette, and boundary fixtures / `REQ-CM-002`)
  - **Out of Scope:** **2 cases (1.4% of 142)** (`TC-CM-099` extra PDS columns retired via `REQ-CM-006`; `TC-CM-185` supplier approval retired via `REQ-CM-005`)
  - **Unverified:** **1 case (0.7% of 142)** (`TC-CM-222`, atomic database transaction rollback / `QA-CM-001`)
  - **Total Distinct Cases:** **142 cases (100.0% of 142)**
- **Cycle 2 Evidence Composition:**
  - **Cases with Embedded Visual Screenshots:** **69 cases** supported by **246 embedded screenshots** in the workbook `Evidence` tab and 240 high-resolution PNG files under `evidence/Cycle2/`.
  - **Cases Verified via Headless Telemetry & Assertions:** **73 cases** verified headlessly via strict Playwright DOM assertions, locator visibility checks, and HTTP response codes archived in `evidence/shared/results/` (`cycle2-final-results.json`, `targeted-regression-results.json`, `four-fix-rerun-results.json`).
  - *Distinction:* Tester comments alone are classified as recorded observations; cases are classified as telemetry-supported only when case-specific assertions are identifiable in archived JSON logs.

---

## 4. Consolidated Latest Results Across All 229 Distinct Test Cases

### 4.1 Reconciliation of Unique Test Case Inventory
Reconciling the test suite across both cycles accounts for every case in the repository:
$$\text{Total Distinct Cases} = \text{Cycle 1 Distinct (191)} + \text{Cycle 2 Only (38)} = 229\text{ Distinct Cases}$$
- **Cases Present in Both Cycles:** **104 cases** (Present in both Cycle 1 and Cycle 2 workbook sheets; latest Cycle 2 recorded result supersedes Cycle 1)
- **Executed in Cycle 1 Only:** **87 cases** (Verified in Cycle 1 baseline; not targeted for re-execution in Cycle 2)
- **Executed in Cycle 2 Only:** **38 cases** (New feature scope: AI Extraction `TC-CM-205..229`, CCL extensions)
- **Total Master Test Inventory:** **229 distinct cases**

### 4.2 Master Consolidated Test Outcomes (Latest Recorded Result)
Using the latest recorded outcome for each unique case across both cycles yields the definitive quality profile:

| Latest Recorded Outcome | Case Count | Percentage (Denominator: 229) | Quality Definition & Scope |
| :--- | :---: | :---: | :--- |
| **Recorded Passed, including documented limitations** | **224** | **97.8%** | Recorded Passed in workbook evaluation (87 in Cycle 1 baseline, 137 in Cycle 2 retest). Cannot be designated as unconditionally fully verified across all 224 cases because cases TC-CM-182 (load quota), TC-CM-186 (database row inspection), TC-CM-220 (physical filesystem persistence), and TC-CM-228 (provider-side assurance) retain specific documented limitations. |
| **Failed (Active Defect)** | **1** | **0.4%** | `TC-CM-098` failed ongoing contract sea service duration (`DEF-CM-020`). |
| **Blocked** | **1** | **0.4%** | `TC-CM-077` blocked on boundary evaluation rule, badge palette, and synthetic fixtures (`REQ-CM-002`). |
| **Out of Scope (Retired)** | **2** | **0.9%** | `TC-CM-099` (extra PDS columns retired from SRS Section 3) and `TC-CM-185` (supplier approval retired from SRS). |
| **Unverified Scope** | **1** | **0.4%** | `TC-CM-222` unverified pending isolated database fault-injection environment (`QA-CM-001`). |
| **Total Test Repository** | **229** | **100.0%** | Comprehensive unique test inventory across Cycle 1 and Cycle 2. |

> [!NOTE]
> **Outcome Categorization & Scope Accounting:**  
> - **Cases with Recorded Pass-or-Fail Outcomes:** **225 cases (98.3% of 229)** (224 Recorded Passed, including documented limitations + 1 Failed). This metric reflects recorded outcome status in the workbook rather than unconditionally complete verification across all requirements.  
> - **Blocked / Unverified Cases:** **2 cases (0.9% of 229)** (1 Blocked `TC-CM-077` awaiting boundary evaluation rule, badge palette, and fixtures + 1 Unverified `TC-CM-222` awaiting isolated database fault injection).  
> - **Out of Scope (Retired from SRS):** **2 cases (0.9% of 229)** (`TC-CM-099` extra PDS columns retired via `REQ-CM-006`; `TC-CM-185` supplier approval retired via `REQ-CM-005`). These cases represent formally retired scope and are not categorized as partially attempted or gated work.

---

## 5. Requirements Coverage and Remaining Coverage Gaps

### 5.1 Specification Matrix Reconciliation
Every requirement defined in the authoritative uploaded specification ([`ByteMe SRS - UMMI.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/ByteMe%20SRS%20-%20UMMI.docx)) has been cataloged in the master RTM:

| SRS Requirement Category | Authoritative SRS Inventory | Verified / Mapped Cases | Unmapped / Gated Requirements |
| :--- | :---: | :---: | :--- |
| **Functional Requirements (`FR-CM`)** | **79 Total** (78 Active) | 78 Active Covered (`FR-CM-01..19`, `FR-CM-21..79`) | `FR-CM-20` retired via `REQ-CM-006` (`TC-CM-099` Out of Scope). |
| **Security Rules (`SR`)** | **18 Total** (17 Active) | 16 Active Covered (`SR-01..02`, `SR-04..06`, `SR-08..18`) | `SR-07` has **No mapped test** in workbook. `SR-03` retired via `REQ-CM-005` (`TC-CM-185` Out of Scope). |
| **Use Cases (`UC-CM`)** | **28 Active** | 28 Covered (`UC-CM-01` through `UC-CM-28`) | None. Full forward and backward tracing established. |
| **Performance Requirements (`PR`)** | **8 Active** | 7 Fully Passed (`PR-01..05`, `PR-07..08`) | `PR-06` (`TC-CM-182`) retained with Free F1 bandwidth quota limitation (`INC-CM-001`). |

### 5.2 Remaining Coverage Gaps & Boundary Clarifications
1. **`FR-CM-13` / `TC-CM-077` (Body Mass Index Gaps):**
   - *SRS Clarification:* `FR-CM-13` explicitly defines all numeric BMI classification thresholds: Underweight (< 18.5), Normal (18.5 to < 25), Overweight (25 to < 30), and Obese (>= 30), with one-decimal display and suppression of blank/zero inputs.
   - *Remaining Gaps:* `TC-CM-077` remains **Blocked** due to three engineering items: (a) unconfirmed evaluation basis at cutoffs (raw floating-point vs. rounded 1-decimal classification rule, e.g. whether `24.96` evaluates as Normal raw or Overweight rounded to `25.0`), (b) undefined UI badge palette colors (hex codes for Underweight, Normal, Overweight, Obese), and (c) missing synthetic boundary fixtures (`18.49/18.50`, `24.99/25.00`, `29.99/30.00`).
2. **`SR-07` (Audit Logging of Critical User Activities — No Mapped Test):**
   - *SRS Baseline:* The SRS requires logging critical user activities (profile views, applicant hiring, link generation) for auditing purposes.
   - *Coverage Status:* Labeled **No mapped test** in the RTM tab. Lacks a standalone test case in the workbook repository.
   - *Password Complexity Audit:* Password complexity enforcement cannot be declared verified merely because strong fixture passwords were used during administrative account provisioning (`FIX-CM-001`). Dedicated negative password complexity testing remains unexecuted.
3. **`SR-11` & `SR-13` (Configured Client Controls vs. Provider Assurance Limitations):**
   - *Verified Client-Side Controls:* Application API configuration parameters establish client-side payload minimalism (sending only necessary document fields) and HTTPS transit encryption.
   - *Provider-Side Assurance Limitations:* API parameters alone can establish configured request behavior, but they do NOT prove third-party provider-side zero retention, absence of model training, or encryption at rest within the external infrastructure. These aspects remain operational assurance limitations (`EVD-CM-002`).
   - *Optional Verification Formats:* Formal external certification documents (such as an executed Data Processing Agreement or SOC 2 certificate from DeepInfra) represent optional audit verification formats rather than mandatory document formats explicitly stipulated by the SRS text. Recorded test statuses reflect verified client-side request and response handling.
4. **`FR-CM-75` / `TC-CM-222` (Single-Submission Integrity & Rollback):**
   - Multi-record atomic rollback across database tables and physical file attachments during mid-transaction failures remains **Unverified** (`QA-CM-001`) due to staging safety constraints.

---

## 6. Product Defects, Fixes, Retests, and Regressions

### 6.1 Complete Defect Accounting (`DEF-CM-001` through `DEF-CM-020`)
A total of **20 application defects** were formally cataloged, tracked, and evaluated against deployed Azure staging builds:
- **Total Tracked Defects:** **20**
- **Resolved and Verified:** **19 (95.0% of 20)**
- **Active Open Defect:** **1 (5.0% of 20) — `DEF-CM-020`**

#### Defect Severity Breakdown
- **High Severity (10 defects):** `DEF-CM-002`, `003`, `004`, `005`, `006`, `010`, `012`, `013`, `015`, `019` (All 10 verified resolved)
- **Medium Severity (10 defects):** `DEF-CM-001`, `007`, `008`, `009`, `011`, `014`, `016`, `017`, `018`, `020` (9 verified resolved, 1 open)

### 6.2 Active Open Defect Deep-Dive: DEF-CM-020
- **Test Case:** `TC-CM-098` (Crew Search and Profile Sea Service Duration)
- **Requirement Reference:** `FR-CM-19` / `UC-CM-10`
- **Severity:** Medium | **Status:** **OPEN / FAILED**
- **Observed Discrepancy:** On staging build `d27298b`, calculating ongoing sea service for crew member Lucas (ID 252, contract 6) at `Oct 11 06:18:10 PHT` displayed `0.4 yr(s)`. The mathematically derived operational total at this Philippine operational timestamp was `0.5 yr(s)`.
- **Root Cause Classification:** **Inferred Working Hypothesis.** The calculated 164 days matches the previous UTC calendar date; fallback to a UTC `CURDATE()` evaluation is inferred. Direct application pooled-session timezone evidence (such as MySQL connection session timezones or IIS thread culture) was not captured during test execution.
- **Resolution Path:** Update application date calculation logic in both `QueryCrew.aspx.vb` and `ProfileViewer.aspx.vb` to explicitly evaluate ongoing service using Philippine Standard Time (`UTC+8`) as-of dates.

### 6.3 Regressions Encountered and Remediation Verification
During Cycle 2 verification, three specific regressions were caught and resolved:
1. **`DEF-CM-008` (Blank Outgoing Names in CCL Popups):** Create Schedule and Edit Schedule popups displayed blank outgoing crew names after commit `d27298b`. Verified resolved in build `c737536` via [`evidence/Cycle2/TC-CM-196/screenshots/TC-CM-196_ccl_fig12-ccl-create-schedule-names-verified.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-196/screenshots/TC-CM-196_ccl_fig12-ccl-create-schedule-names-verified.png).
2. **`DEF-CM-010` (Scalar Suggestion Rejection Runtime Error):** The initial implementation of scalar suggestion rejection threw runtime `TypeError: this.saveState is not a function`. Remediated in commit `b323bcd` (retested under deployed build `97fd151`) and verified error-free via [`evidence/Cycle2/TC-CM-212/screenshots/TC-CM-212_ai-retest_fig15-tc212-apply-replace-edit-verified.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-212/screenshots/TC-CM-212_ai-retest_fig15-tc212-apply-replace-edit-verified.png).
3. **`DEF-CM-016` (Vessel Grouping Header Recurrence):** Result grid flattened in earlier Cycle 2 runs. Re-verified on live staging with inline headers via [`evidence/Cycle2/TC-CM-050/screenshots/TC-CM-050_batch18_tc050-all-vessels-visual-grouping.png`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-050/screenshots/TC-CM-050_batch18_tc050-all-vessels-visual-grouping.png).

### 6.4 Non-Defect Operational Tracking Categories
To ensure strict delivery governance, non-defect engineering issues were tracked separately:
- **Environment Incidents (2):** `INC-CM-001` (Azure Free F1 100-VU bandwidth limit halting load tests at 5m 39s); `INC-CM-002` (Missing assessment PDF on staging storage restored via manual deployment).
- **Requirement Baseline Decisions (8):** `REQ-CM-001` (Approved Super-Admin bypass); `REQ-CM-002` (BMI boundary/palette gap); `REQ-CM-003` (Exact-timestamp link expiry equality); `REQ-CM-004` (Vessel dropdown scoping); `REQ-CM-005` (Supplier role removal); `REQ-CM-006` (PDS column retirement); `REQ-CM-007` (Role access scoping); `REQ-CM-008` (Date formatting & lifecycle warnings).
- **Evidence & Verification Limitations (3):** `EVD-CM-001` (Live MySQL row inspection firewalled); `EVD-CM-002` (Vendor DPA/SOC 2 optional format); `QA-CM-001` (Atomic rollback unverified).
- **Script Limitations (3):** `SCR-CM-001` (Browser process cleanup); `SCR-CM-002` (Permissive test oracle in ongoing sea service script); `SCR-CM-003` (Clock-expiry runner CSS parsing).

---

## 7. Functional, Negative, Boundary, Security, and Performance Findings

### 7.1 Representative Verified Evidence Register
All referenced evidence artifacts below correspond to verified physical files present on disk:

| Test Case | Scenario & Verification Classification | Requirement | Recorded Result | Primary Packaged Artifact Link | Image / Assertion Verification Finding |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **`TC-CM-050`** | Visual Vessel Grouping *(Happy Path)* | `FR-CM-06` | **Passed** | [`evidence/Cycle2/TC-CM-050/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-050/screenshots/TC-CM-050_batch18_tc050-all-vessels-visual-grouping.png) | Inline group headers rendered per vessel with correct crew counts and average age. |
| **`TC-CM-076`** | Profile BMI Display *(Happy Path)* | `FR-CM-13` | **Passed** | [`evidence/Cycle2/TC-CM-076/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-076/screenshots/TC-CM-076_batch18_tc076-bmi-a001-normal.png) | Calculated BMI formatted to 1 decimal place (`22.4 Normal`); zero/blank height/weight suppressed. |
| **`TC-CM-096`** | Overlapping Sea Service *(Boundary)* | `FR-CM-18; 19` | **Passed** | [`evidence/Cycle2/TC-CM-096/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-096/screenshots/TC-CM-096_phase2_fig07-tc096-sea-service-overlap-verified.png) | Concurrent service intervals merged culture-invariantly without double-counting elapsed days. |
| **`TC-CM-074`** | Vessel Owner Scoping *(Negative / Auth)* | `FR-CM-12` | **Passed** | [`evidence/Cycle2/TC-CM-074/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-074/screenshots/TC-CM-074_tc074-retest_02-oos-bonifacio-profile-attempt.png) | Direct profile URL tampering to unassigned crew is denied and verified via direct access attempt and Security audit retest (`tc074-retest_02` & `attachment-rerun_04`). Note: Empty vessel search results prove grid filtering exclusion, not direct profile authorization. |
| **`TC-CM-015`** | Super-Admin Access *(Approved Bypass)* | `FR-CM-53` | **Passed** | [`evidence/Cycle2/TC-CM-015/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-015/screenshots/TC-CM-015_per_user_access_tc015-superadmin-bypass-ui.png) | Super-Admin successfully accesses Crew Search despite per-user disabled settings (`REQ-CM-001`). |
| **`TC-CM-164`** | Expired / Invalid Token *(Negative)* | `FR-CM-48; SR-08` | **Passed** | [`evidence/Cycle2/TC-CM-164/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-164/screenshots/TC-CM-164_phase2_fig03-tc164-167-access-denied-page.png) | Malformed or expired token redirects immediately to `AccessDenied.aspx`; denial logged in audit trail. |
| **`TC-CM-169`** | Link Expiration Lifecycle *(Boundary)* | `FR-CM-44; SR-08` | **Passed** | `evidence/shared/results/targeted-regression-results.json` | Natural token expiry transitions link to Expired status. Exact-timestamp boundary equality remains separate (`REQ-CM-003`). |
| **`TC-CM-186`** | Credential Hashing *(Security)* | `SR-04` | **Passed (w/ Lim)**| [`evidence/Cycle2/TC-CM-186/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-186/screenshots/TC-CM-186_technical_fig17-tc186-login-generic-error-pbkdf2.png) | PBKDF2-HMAC-SHA256 (100k rounds, 256-bit salt) is verified via technical code review of `CryptoHelper.vb` and application compilation configs (`EVD-CM-001`). Note: The screenshot (`fig17`) demonstrates generic login error messaging without user enumeration, but does not itself prove database hash storage. |
| **`TC-CM-192`** | CCL Reliever Pool *(Functional)* | `FR-CM-79` | **Passed** | [`evidence/Cycle2/TC-CM-192/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-192/screenshots/TC-CM-192_ccl_fig10-ccl-reliever-search-pool-modal.png) | Reliever search modal returns available crew, correctly including On Vacation (Status 4) candidates. |
| **`TC-CM-196`** | CCL Schedule Outgoing Name *(Retest)* | `FR-CM-79` | **Passed** | [`evidence/Cycle2/TC-CM-196/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-196/screenshots/TC-CM-196_ccl_fig12-ccl-create-schedule-names-verified.png) | Verified regression fix for `DEF-CM-008`: outgoing crew name binds correctly in Create Schedule modal. |
| **`TC-CM-200`** | CCL Edit Schedule Amendment *(Retest)* | `FR-CM-79` | **Passed** | [`evidence/Cycle2/TC-CM-200/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-200/screenshots/TC-CM-200_ccl_fig13-ccl-edit-schedule-amendment-verified.png) | Finalized schedule amendment updates dates and preserves linked End of Contract record. |
| **`TC-CM-201`** | CCL Schedule Cancellation *(Lifecycle)* | `FR-CM-79` | **Passed** | [`evidence/Cycle2/TC-CM-201/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-201/screenshots/TC-CM-201_ccl_fig11-ccl-scheduling-lifecycle-regression.png) | Verified fix for `DEF-CM-007`: cancelling finalized schedule displays approved `Superseded` EOC status. |
| **`TC-CM-203`** | Manual Crew Sign-On *(Retest)* | `FR-CM-79` | **Passed** | [`evidence/Cycle2/TC-CM-203/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-203/screenshots/TC-CM-203_ccl_fig08-tc203-manual-crew-sign-on-modal.png) | Verified fix for `DEF-CM-013`: sign-on modal sets reliever assigned vessel and transitions status to On Board. |
| **`TC-CM-212`** | AI Suggestion Review *(Retest)* | `FR-CM-64` | **Passed** | [`evidence/Cycle2/TC-CM-212/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-212/screenshots/TC-CM-212_ai-retest_fig15-tc212-apply-replace-edit-verified.png) | Caption & content verified: `fig15` verifies apply/replace/edit suggestion interactions; `fig16` verifies full-page suggestion review. Explicit scalar Reject control verification is confirmed in `tc212-final-retest-summary.md` and `tc212-final-retest-results.json` (`DEF-CM-009/010` fixes). |
| **`TC-CM-220`** | Document Association & Retention *(Telemetry)* | `FR-CM-73` | **Passed (w/ Lim)**| [`evidence/Cycle2/TC-CM-221/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-221/screenshots/TC-CM-221_technical_fig18-tc221-protected-handler-document-view.png) | Protected document handler authorization verified via `fig18` (`CrewDocumentHandler.ashx`). Note: `fig18` and `fig19` prove route authorization, but do not establish physical server storage persistence or database record association (`EVD-CM-001`). |
| **`TC-CM-221`** | Static File Handler Block *(Security)* | `FR-CM-74; SR-12` | **Passed** | [`evidence/Cycle2/TC-CM-221/...`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/evidence/Cycle2/TC-CM-221/screenshots/TC-CM-221_technical_fig19-tc221-direct-static-file-404-block.png) | Verified fixes for `DEF-CM-004/005`: direct static URL requests to `/Uploads/documents/` return HTTP 404/403 block (`fig19`), distinguished from authorized handler delivery via `CrewDocumentHandler.ashx` (`fig18`). |
| **`TC-CM-228`** | AI Transport Controls *(Security)* | `SR-11; SR-13` | **Passed** | `evidence/shared/results/cycle2-final-results.json` | Configured HTTPS transport and payload minimalism verified via API request telemetry. Note: API parameters alone do not prove provider-side zero retention, no model training, or encryption at rest (`EVD-CM-002`). |

---

## 8. Evidence Limitations, Unresolved Risks, and Exit-Criteria Assessment

### 8.1 Documented Technical & Evidence Limitations
1. **Cycle 1 Evidence Retention:** Cycle 1 test execution results, observations, and tester assignments were recorded directly inside the workbook's `Cycle1` worksheet. Screenshots and raw network traces were not retained.
2. **`EVD-CM-001` (Live MySQL Row Inspection):** Adaptive PBKDF2 hashing is verified in code, compilation configs, and login workflows. Direct row inspection of the live Azure Database for MySQL was blocked by Azure firewall rules.
3. **`EVD-CM-002` (Third-Party AI Provider Assurance Limitations):** Client-side payload minimalism and HTTPS transport are verified via API parameters (`SR-11`, `SR-13`). However, API parameters alone do not prove provider-side zero retention, no model training, or encryption at rest within the external vendor's infrastructure. Formal contractual DPA or SOC 2 compliance certificates from DeepInfra remain unarchived.
4. **`QA-CM-001` (Atomic Transaction Rollback):** Verification of mid-failure rollback across records and storage attachments (`TC-CM-222`) requires an isolated fault-injection harness not executed on production staging.
5. **`INC-CM-001` (Azure Hosting Tier Quota Limitation):** Azure Free F1 staging tier halted peak 100-user load testing at 5m 39s due to daily bandwidth limits (`590.87 MiB` consumed against a `509.74 MiB` limit). Peak load certification requires scaling to a paid Azure tier.

### 8.2 Exit-Criteria Evaluation Against Test Plan
The Test Plan defines formal gating thresholds for release readiness:

| Test Plan Exit Criterion | Target Benchmark | Actual Measured Status | Exit Evaluation |
| :--- | :---: | :---: | :---: |
| **Consolidated Functional Pass Rate** | &ge; 95.0% | **97.8% (224 of 229 recorded passed, with documented limitations)** | **CONDITIONALLY MET** |
| **Critical / Blocker Open Defects** | 0 Open | **0 Open Critical / Blocker Defects** | **MET** |
| **High Severity Open Defects** | 0 Open | **0 Open High Severity Defects** (All 10 resolved) | **MET** |
| **Medium Severity Open Defects** | &le; 2 Open | **1 Open Medium Defect (`DEF-CM-020`)** | **UNRESOLVED DEFECT** |
| **Performance Steady-State Load** | 10 min @ 100 VUs | **Halted at 5m 39s due to Free F1 data out quota (`INC-CM-001`)** | **NOT MET** |
| **Documented Gaps & Limitations** | 100% Disclosed | All 8 gaps cataloged in RTM and reports | **DISCLOSED** |
| **Client Stakeholder UAT Sign-Off** | Signed Certificate | **No formal client sign-off, UAT approval, or release sign-off exists** | **NOT MET** |
| **Overall Exit Criteria Assessment** | All Criteria Met | **Multiple gating criteria remain unmet** | **EXIT CRITERIA NOT MET** |

---

## 9. Evidence-Based Release Recommendation

### Release Determination: NOT YET READY FOR RELEASE

> [!CAUTION]
> **Authoritative Release Decision: NOT YET READY FOR RELEASE**  
> Based on the recorded unresolved checks, unmet closure criteria, and absence of stakeholder sign-off, the authoritative release recommendation is **Not Yet Ready for Release**.
> 
> Unconditional production deployment is gated on resolving the following unmet criteria:
> 1. **Unresolved Application Defect (`DEF-CM-020`):** Ongoing sea service duration calculation on Lucas ID 252 contract 6 failed due to an operational date discrepancy between UTC server date and Philippine Standard Time. The defect remains **Open / Failed**.
> 2. **Unmet Performance Steady-State Certification:** Peak 100-user load testing (`TC-CM-182` / `INC-CM-001`) stopped at 5 minutes 39 seconds due to daily bandwidth quota exhaustion on the Azure Free F1 hosting tier. Full 10-minute steady-state performance certification requires execution on a paid hosting plan.
> 3. **Unmet Formal Sign-Off Criteria:** No formal client sign-off, independent testing sign-off, completed UAT certificate, or release approval exists.
> 4. **Unresolved Technical & Assurance Limitations:** Destructive database transaction rollback (`QA-CM-001` / `TC-CM-222`) remains unverified; live database credential row inspection (`EVD-CM-001` / `TC-CM-186`) remains firewalled; and third-party AI provider-side retention, training, and at-rest encryption policies (`EVD-CM-002` / `TC-CM-228`) cannot be verified from client API parameters alone.
> 
> ---
> 
> #### Separate Operational Note: Staging Availability for Client Review
> Independent of the production release gating decision, the staging web application remains deployed and conditionally operational on Azure. It is available for internal stakeholder inspection, demonstration, and structured client UAT preview walkthroughs, provided that all known limitations, open defect `DEF-CM-020`, and boundary gaps are explicitly disclosed to reviewing participants.

---

## 10. Top Three Improvements and Main Lessons from Testing

### 10.1 Top Three Priority Improvements for Development
1. **Explicit Cloud-to-Operational Timezone Normalization:**  
   Enforce explicit timezone conversions (e.g. `TimeZoneInfo.FindSystemTimeZoneById("Singapore Standard Time")` / `UTC+8`) across all date-dependent stored procedures and presentation code. Never rely on ambient server system clocks or database `CURDATE()` defaults when cloud hosts operate in UTC and maritime business operations execute in Philippine Standard Time.
2. **Formal Specification Standardization for BMI Boundaries & Palettes:**  
   Formally amend `FR-CM-13` to explicitly establish: (a) whether cutoff evaluations use raw floats or rounded 1-decimal numbers, (b) hex color codes for UI status badges, and (c) provision synthetic test records precisely at cutoff boundaries (`18.49/18.50`, `24.99/25.00`, `29.99/30.00`).
3. **Dedicated Ephemeral Fault-Injection Test Environment:**  
   Establish an isolated CI/CD staging slot with simulated database disconnections and fault-injection proxies to safely verify atomic multi-table rollbacks (`TC-CM-222` / `QA-CM-001`) without risking corruption of shared staging data.

### 10.2 Main Lessons Learned from the Testing Campaign
- **Distinguish Positive Fixtures from Security Verification:** Provisioning accounts with strong passwords in automated test fixtures proves that valid credentials authenticate successfully; it does *not* prove password complexity enforcement. Negative testing with weak, short, and malformed inputs is essential.
- **Differentiate Required Provider Controls from Optional Governance Formats:** Conflating mandatory engineering controls (HTTPS transport, payload minimalism, transient processing) with optional legal documentation formats (executed third-party DPAs or SOC 2 certificates) creates false-positive compliance blockers. Technical controls must be verified via network telemetry.
- **Maintain Traceable, Bit-Level Packaging Integrity:** Automated copy pipelines that compute and verify SHA-256 manifests prevent artifact corruption, link breakage, and file name collisions, ensuring complete defense fidelity.

---
*Report codified and delivered in accordance with authoritative QA delivery governance.*
