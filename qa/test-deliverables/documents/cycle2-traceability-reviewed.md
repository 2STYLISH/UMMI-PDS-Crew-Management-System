# UMMI Crew Management System — Authoritative Requirements Traceability Matrix (Reviewed Baseline)

> **Document Status:** Authoritative Master Traceability Matrix (All 229 Distinct Cases Reconciled across Cycle 1 & Cycle 2)  
> **Authoritative SRS Baseline:** [`documents/ByteMe SRS - UMMI.docx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/ByteMe%20SRS%20-%20UMMI.docx) (1,422,993 bytes | SHA-256: `96b220779905dd31f49083ad6606398812269825d4d0200a2657a0bca950ed45`)  
> **Authoritative Workbook with RTM Worksheet:** [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Contains dedicated `RTM` tab with 11 columns)  
> **Authoritative Execution Workbook:** [`documents/QA TEST PLAN UMMI.xlsx`](file:///c:/Users/reila/UMMI-PDS-Crew-Management-System/qa/test-deliverables/documents/QA%20TEST%20PLAN%20UMMI.xlsx) (Worksheets: `Cycle1`, `Cycle2`, `Lists`, `Evidence`)  
> **Target Staging Environment:** Azure App Service (`Southeast Asia`) | IIS 10.0 | ASP.NET 4.0 | MySQL 8.0  
> **Staging URL:** `https://ummi-crew-hdccaegqbke9gwab.southeastasia-01.azurewebsites.net`  
> **Superseded Prior Version:** `qa/test-deliverables/documents/cycle2-traceability.md` (Preserved intact for audit history)

---

## 1. Executive Summary & Authoritative SRS Baseline Reconciliation

This authoritative Requirements Traceability Matrix (RTM) reconciles the complete QA test suite across **Cycle 1 (Initial Manual Verification)** and **Cycle 2 (Automated & Regression Retest)** against the **authoritative Software Requirements Specification (SRS)** (`ByteMe SRS - UMMI.docx`) packaged locally in `documents/`.

### Master Requirement Inventory (Authoritative SRS Baseline)
| Specification Category | Older Package Claim | Authoritative SRS Inventory | Active Scope & Identifiers |
| :--- | :---: | :---: | :--- |
| **Functional Requirements** | 64 | **79 Total (78 Active)** | `FR-CM-01` through `FR-CM-79` (Includes AI resume extraction `FR-CM-54..78` and dedicated Crew Change List `FR-CM-79`; `FR-CM-20` retired via `REQ-CM-006`) |
| **Security Rules** | 9 | **18 Total (17 Active)** | `SR-01` through `SR-18` (Excludes retired supplier approval `SR-03`; incorporates upload limits, encryption, DB isolation, content safety, and document retention `SR-18`) |
| **Use Cases** | 27 | **28** | `UC-CM-01` through `UC-CM-28` (Includes `UC-CM-07` Crew Change List and `UC-CM-28` AI-assisted self-encoding) |
| **Performance Requirements** | 6 | **8** | `PR-01` through `PR-08` (Includes AI parsing latency `PR-07` and extraction boundary limits `PR-08`) |

### Key Requirement Alignment Clarifications
1. **`FR-CM-13` (Body Mass Index Calculation):** The SRS Section 3.2.2 explicitly defines all numeric BMI thresholds: Underweight (< 18.5), Normal (18.5 to < 25), Overweight (25 to < 30), Obese (>= 30), with one-decimal display and suppression of blank/zero inputs. TC-CM-077's open gap is NOT undefined thresholds in the SRS, but rather unconfirmed evaluation basis (raw calculated float vs. rounded 1-decimal classification rule at boundaries), undefined UI badge color palette, and missing synthetic boundary test fixtures (`18.49/18.50`, `24.99/25.00`, `29.99/30.00`).
2. **`SR-07` (Audit Logging of Critical User Activities):** Defined in the SRS as audit logging for critical activities (profile views, applicant hiring, link generation). In the workbook test repository, `SR-07` has **no mapped test case** and is labeled `No mapped test`. Furthermore, password complexity enforcement cannot be declared verified merely because strong fixture passwords were created during administrative provisioning (`FIX-CM-001`). Dedicated negative password complexity testing remains unexecuted.
3. **`SR-11` & `SR-13` (AI Transport & Processing Controls):** Require payload minimalism, transmission over HTTPS, ephemeral processing, and zero model training. These requirements are technically configured via transient API parameters. SOC 2 certification and formal legal Data Protection Agreements (DPAs) are optional verification formats, not mandatory document formats stipulated by the SRS.
4. **`DEF-CM-020` (Ongoing Sea Service Duration):** The observed difference on Lucas 252 (contract 6 displaying 0.4 yr instead of 0.5 yr; 164 days vs 165 days) matches the previous UTC date. The UTC fallback explanation is maintained as an **inferred working hypothesis** because direct application pooled-session timezone telemetry was not captured.
5. **Super-Admin Bypass (`REQ-CM-001`):** The ability of Super-Admin to bypass per-user disabled settings for Crew Search and Applicant Pool is confirmed approved system design behavior, not a security flaw.
6. **`TC-CM-099` (Retired Scope):** In the authoritative SRS, Section 3 jumps from `FR-CM-19` to `FR-CM-21`. `FR-CM-20` appears only vestigially in `UC-CM-10` traceability. `TC-CM-099` (extra PDS columns) was retired from scope via `REQ-CM-006` and is classified as **Out of Scope**.
7. **Separation of Results from Coverage:** Recorded 'Passed' results with limited assertions (such as headless Playwright DOM checks without visual evidence, or positive-only paths) are not conflated with full requirement acceptance. Formal sign-off and UAT acceptance have not taken place.

---

## 2. Test Execution Lifecycle Breakdown (All 229 Distinct Cases)

| Metric | Count | Percentage | Definition & Scope |
| :--- | :---: | :---: | :--- |
| **Total Distinct Test Cases** | **229** | **100.0%** | Union of all unique test cases across Cycle 1 (191 cases) and Cycle 2 (142 cases) |
| **Latest Result: Passed** | **224** | **97.8%** | Satisfied conditions on latest evaluation (87 verified in Cycle 1 baseline; 137 verified in Cycle 2 retest) |
| **Latest Result: Failed (Open Defect)** | **1** | **0.4%** | `TC-CM-098` failed ongoing sea service duration check (`DEF-CM-020`) |
| **Latest Result: Blocked** | **1** | **0.4%** | `TC-CM-077` blocked pending evaluation basis, palette, and boundary fixtures (`REQ-CM-002`) |
| **Latest Result: Out of Scope** | **2** | **0.9%** | `TC-CM-099` (extra PDS columns retired via `REQ-CM-006`) and `TC-CM-185` (supplier approval retired via `REQ-CM-005`) |
| **Latest Result: Unverified** | **1** | **0.4%** | `TC-CM-222` unverified pending isolated database fault-injection environment (`QA-CM-001`) |

---

## 3. Master Traceability Table (All 229 Distinct Test Cases)

| Case ID | Feature / Scenario | Requirement Reference | Use Case Reference | Cycle 1 Result | Cycle 2 Result | Latest Recorded Result | Summary Description |
| :--- | :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **TC-CM-001** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Passed | Not Executed | **Passed** |  |
| **TC-CM-002** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Skipped | Passed | **Passed** | Manning Staff: Crew Search disabled |
| **TC-CM-003** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Passed | Not Executed | **Passed** |  |
| **TC-CM-004** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Skipped | Passed | **Passed** | Manning Staff: Applicant Pool disabled |
| **TC-CM-005** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Passed | Not Executed | **Passed** |  |
| **TC-CM-006** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Skipped | Passed | **Passed** | Documentation Officer: Crew Search disabled |
| **TC-CM-007** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Passed | Not Executed | **Passed** |  |
| **TC-CM-008** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Skipped | Passed | **Passed** | Documentation Officer: Applicant Pool disabled |
| **TC-CM-009** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Passed | Not Executed | **Passed** |  |
| **TC-CM-010** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Skipped | Passed | **Passed** | Admin: Crew Search disabled |
| **TC-CM-011** | Crew access | `FR-CM-51` | `UC-CM-01` | Passed | Not Executed | **Passed** | Super-Admin bypasses ordinary Crew Search permission |
| **TC-CM-012** |  | `FR-CM-52; FR-CM-53` | `UC-CM-13` | Passed | Not Executed | **Passed** |  |
| **TC-CM-013** |  | `FR-CM-52; FR-CM-53` | `UC-CM-13` | Skipped | Passed | **Passed** | Admin: Applicant Pool disabled |
| **TC-CM-014** |  | `FR-CM-52; FR-CM-53` | `UC-CM-13` | Passed | Not Executed | **Passed** |  |
| **TC-CM-015** |  | `FR-CM-51; FR-CM-53` | `UC-CM-01` | Skipped | Passed | **Passed** | Super-Admin: Crew Search always allowed (approved bypass) |
| **TC-CM-016** |  | `FR-CM-52; FR-CM-53` | `UC-CM-13` | Passed | Not Executed | **Passed** |  |
| **TC-CM-017** |  | `FR-CM-52; FR-CM-53` | `UC-CM-13` | Skipped | Passed | **Passed** | Super-Admin: Applicant Pool always allowed (approved bypass) |
| **TC-CM-018** | Applicant access | `FR-CM-52` | `UC-CM-13` | Passed | Not Executed | **Passed** | Super-Admin opens Applicant Pool |
| **TC-CM-019** |  | `FR-CM-52; FR-CM-53` | `UC-CM-14` | Passed | Passed | **Passed** | Principal: reject internal Applicant Pool access |
| **TC-CM-020** |  | `FR-CM-52; FR-CM-53` | `UC-CM-14` | Passed | Passed | **Passed** | Vessel Owner: reject internal Applicant Pool access |
| **TC-CM-021** |  | `FR-CM-01; FR-CM-10` | `UC-CM-01; UC-CM-03` | Passed | Passed | **Passed** | Initial crew search and audit |
| **TC-CM-022** |  | `FR-CM-01` | `UC-CM-01` | Passed | Not Executed | **Passed** |  |
| **TC-CM-023** |  | `FR-CM-01` | `UC-CM-01` | Passed | Not Executed | **Passed** |  |
| **TC-CM-024** |  | `FR-CM-01` | `UC-CM-01` | Passed | Not Executed | **Passed** |  |
| **TC-CM-025** |  | `FR-CM-01` | `UC-CM-01` | Passed | Not Executed | **Passed** |  |
| **TC-CM-026** |  | `FR-CM-01` | `UC-CM-01` | Passed | Passed | **Passed** | Search by Rank |
| **TC-CM-027** |  | `FR-CM-01` | `UC-CM-01` | Passed | Passed | **Passed** | Search by Rank type |
| **TC-CM-028** |  | `FR-CM-01` | `UC-CM-01` | Failed | Passed | **Passed** | Search by Assigned vessel |
| **TC-CM-029** |  | `FR-CM-01` | `UC-CM-01` | Skipped | Passed | **Passed** | Search by Province |
| **TC-CM-030** |  | `FR-CM-01` | `UC-CM-01` | Skipped | Passed | **Passed** | Search by City / municipality |
| **TC-CM-031** |  | `FR-CM-01` | `UC-CM-01` | Skipped | Passed | **Passed** | Search by Vessel type experience |
| **TC-CM-032** |  | `FR-CM-01` | `UC-CM-01` | Skipped | Passed | **Passed** | Search by Cadetship |
| **TC-CM-033** |  | `FR-CM-01` | `UC-CM-01` | Skipped | Passed | **Passed** | Search by JOCAP |
| **TC-CM-034** |  | `FR-CM-01` | `UC-CM-01` | Skipped | Passed | **Passed** | Search by Higher license |
| **TC-CM-035** | Crew search | `FR-CM-01` | `UC-CM-01` | Passed | Passed | **Passed** | Combine crew name, vessel and rank |
| **TC-CM-036** | Crew search | `FR-CM-01` | `UC-CM-01` | Unverified | Passed | **Passed** | Crew date range includes start and end dates |
| **TC-CM-037** |  | `FR-CM-01; FR-CM-04` | `UC-CM-01` | Passed | Not Executed | **Passed** |  |
| **TC-CM-038** |  | `FR-CM-01; FR-CM-10` | `UC-CM-01; UC-CM-03` | Passed | Not Executed | **Passed** |  |
| **TC-CM-039** |  | `FR-CM-05` | `UC-CM-02` | Passed | Not Executed | **Passed** |  |
| **TC-CM-040** | Crew search | `FR-CM-05; FR-CM-25` | `UC-CM-01; UC-CM-02; UC-CM-04` | Passed | Not Executed | **Passed** | Principal: hide internal search controls |
| **TC-CM-041** | Crew search | `FR-CM-02` | `UC-CM-01` | Unverified | Passed | **Passed** | Principal: status default and reference choices |
| **TC-CM-042** |  | `FR-CM-03` | `UC-CM-01` | Failed | Passed | **Passed** | Principal: isolate assigned vessels |
| **TC-CM-043** | Crew search | `FR-CM-05; FR-CM-25` | `UC-CM-01; UC-CM-02; UC-CM-04` | Passed | Passed | **Passed** | Vessel Owner: hide internal search controls |
| **TC-CM-044** | Crew search | `FR-CM-02` | `UC-CM-01` | Unverified | Passed | **Passed** | Vessel Owner: status default and reference choices |
| **TC-CM-045** |  | `FR-CM-03` | `UC-CM-01` | Failed | Passed | **Passed** | Vessel Owner: isolate assigned vessels |
| **TC-CM-046** | Vessel isolation | `FR-CM-03` | `UC-CM-01` | Unverified | Passed | **Passed** | User with no vessel assignments |
| **TC-CM-047** |  | `FR-CM-06` | `UC-CM-03` | Passed | Not Executed | **Passed** |  |
| **TC-CM-048** |  | `FR-CM-06` | `UC-CM-03` | Passed | Not Executed | **Passed** |  |
| **TC-CM-049** |  | `FR-CM-06` | `UC-CM-03` | Passed | Not Executed | **Passed** |  |
| **TC-CM-050** | Crew results | `FR-CM-06` | `UC-CM-03` | Failed | Passed | **Passed** | Vessel grouping and displayed fields |
| **TC-CM-051** | Crew results | `FR-CM-10` | `UC-CM-01; UC-CM-03` | Failed | Passed | **Passed** | Count and average age use all matches |
| **TC-CM-052** | Crew results | `FR-CM-07` | `UC-CM-03` | Not Executed | Passed | **Passed** | Active: elapsed date warnings |
| **TC-CM-053** | Crew results | `FR-CM-07` | `UC-CM-03` | Passed | Not Executed | **Passed** | Inactive: elapsed date warnings |
| **TC-CM-054** | Crew results | `FR-CM-07` | `UC-CM-03` | Passed | Not Executed | **Passed** | On Vacation: elapsed date warnings |
| **TC-CM-055** | Crew results | `FR-CM-07` | `UC-CM-03` | Unverified | Passed | **Passed** | Exact four/eight-month warning cutoffs |
| **TC-CM-056** |  | `FR-CM-09` | `UC-CM-05` | Passed | Not Executed | **Passed** |  |
| **TC-CM-057** | Crew profile navigation | `FR-CM-09` | `UC-CM-05` | Passed | Not Executed | **Passed** | Invalid crew reference returns to search |
| **TC-CM-058** | CCL navigation | `FR-CM-08` | `UC-CM-06` | Unverified | Passed | **Passed** | Manning Staff: open eligible vessel roster |
| **TC-CM-059** | CCL navigation | `FR-CM-08` | `UC-CM-06` | Unverified | Passed | **Passed** | Documentation Officer: open eligible vessel roster |
| **TC-CM-060** | CCL navigation | `FR-CM-08` | `UC-CM-06` | Unverified | Passed | **Passed** | Admin: open eligible vessel roster |
| **TC-CM-061** | CCL navigation | `FR-CM-08` | `UC-CM-06` | Unverified | Passed | **Passed** | Super-Admin: open eligible vessel roster |
| **TC-CM-062** | CCL navigation | `FR-CM-08` | `UC-CM-06` | Unverified | Passed | **Passed** | Hide unavailable CCL links |
| **TC-CM-063** | Crew profile | `FR-CM-11` | `UC-CM-07` | Failed | Passed | **Passed** | Complete Personnel Information Sheet |
| **TC-CM-064** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Passed | Passed | **Passed** | Manning Staff: contact-detail access on |
| **TC-CM-065** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Skipped | Passed | **Passed** | Manning Staff: contact-detail access off |
| **TC-CM-066** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Passed | Not Executed | **Passed** |  |
| **TC-CM-067** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Passed | Passed | **Passed** | Documentation Officer: contact-detail access off |
| **TC-CM-068** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Skipped | Passed | **Passed** | Admin: contact-detail access on |
| **TC-CM-069** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Skipped | Passed | **Passed** | Admin: contact-detail access off |
| **TC-CM-070** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Passed | Not Executed | **Passed** |  |
| **TC-CM-071** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Skipped | Passed | **Passed** | Super-Admin: contact-detail access off |
| **TC-CM-072** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Passed | Not Executed | **Passed** |  |
| **TC-CM-073** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Skipped | Passed | **Passed** | Principal: contact-detail access off |
| **TC-CM-074** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Skipped | Passed | **Passed** | Vessel Owner: contact-detail access on |
| **TC-CM-075** |  | `FR-CM-12; FR-CM-21` | `UC-CM-07; UC-CM-10` | Skipped | Passed | **Passed** | Vessel Owner: contact-detail access off |
| **TC-CM-076** | Crew profile | `FR-CM-13` | `UC-CM-07` | Unverified | Passed | **Passed** | BMI numerical calculation |
| **TC-CM-077** | Crew profile | `FR-CM-13` | `UC-CM-07` | Unverified | Blocked | **Blocked** | BMI classification boundaries |
| **TC-CM-078** | Statutory copy | `FR-CM-14` | `UC-CM-07` | Unverified | Passed | **Passed** | Copy SSS exactly |
| **TC-CM-079** | Statutory copy | `FR-CM-14` | `UC-CM-07` | Unverified | Passed | **Passed** | Copy TIN exactly |
| **TC-CM-080** | Statutory copy | `FR-CM-14` | `UC-CM-07` | Passed | Not Executed | **Passed** | Copy PhilHealth exactly |
| **TC-CM-081** | Statutory copy | `FR-CM-14` | `UC-CM-07` | Passed | Not Executed | **Passed** | Copy Pag-IBIG exactly |
| **TC-CM-082** | Statutory copy | `FR-CM-14` | `UC-CM-07` | Unverified | Passed | **Passed** | HMO informational display (revised expectation) |
| **TC-CM-083** | Crew documents | `FR-CM-15` | `UC-CM-08` | Passed | Not Executed | **Passed** | Personal Documents: display document fields |
| **TC-CM-084** | Crew documents | `FR-CM-15` | `UC-CM-08` | Passed | Not Executed | **Passed** | License: display document fields |
| **TC-CM-085** | Crew documents | `FR-CM-15` | `UC-CM-08` | Passed | Not Executed | **Passed** | Medical: display document fields |
| **TC-CM-086** | Crew documents | `FR-CM-15` | `UC-CM-08` | Passed | Not Executed | **Passed** | Training Certificate: display document fields |
| **TC-CM-087** | Crew documents | `FR-CM-15` | `UC-CM-08` | Passed | Not Executed | **Passed** | Out-Source Training: display document fields |
| **TC-CM-088** | Crew documents | `FR-CM-15` | `UC-CM-08` | Passed | Not Executed | **Passed** | UMMI Certificate: display document fields |
| **TC-CM-089** | Crew documents | `FR-CM-15` | `UC-CM-08` | Passed | Not Executed | **Passed** | Empty document category |
| **TC-CM-090** | Crew documents | `FR-CM-16` | `UC-CM-08` | Passed | Not Executed | **Passed** | Default document expiry warning |
| **TC-CM-091** | Crew documents | `FR-CM-16` | `UC-CM-08` | Passed | Not Executed | **Passed** | Type-specific expiry warning override |
| **TC-CM-092** | Crew documents | `FR-CM-16` | `UC-CM-08` | Unverified | Passed | **Passed** | Exact expiry warning threshold |
| **TC-CM-093** |  | `FR-CM-17` | `UC-CM-09` | Passed | Passed | **Passed** | Open correct scanned document |
| **TC-CM-094** | Crew documents | `FR-CM-15; FR-CM-17` | `UC-CM-09` | Passed | Passed | **Passed** | Record without a scan |
| **TC-CM-095** | Sea service | `FR-CM-18` | `UC-CM-09` | Passed | Not Executed | **Passed** | Display recorded service fields |
| **TC-CM-096** | Sea service | `FR-CM-18; FR-CM-19` | `UC-CM-09` | Unverified | Passed | **Passed** | Compute duration and combined total |
| **TC-CM-097** | Sea service | `FR-CM-19` | `UC-CM-09` | Passed | Not Executed | **Passed** | Empty history and empty contracts |
| **TC-CM-098** | Sea service | `FR-CM-19` | `UC-CM-09` | Unverified | Failed | **Failed** | Company contracts without prior history |
| **TC-CM-099** | Sea service | `FR-CM-20` | `UC-CM-09` | Unverified | Out of Scope | **Out of Scope** | Additional PDS-only columns (retired) |
| **TC-CM-100** | Assessments | `FR-CM-21` | `UC-CM-11` | Passed | Passed | **Passed** | Read-only assessment content |
| **TC-CM-101** | Assessments | `FR-CM-21` | `UC-CM-11` | Passed | Passed | **Passed** | No assessment records |
| **TC-CM-102** |  | `FR-CM-22` | `UC-CM-11` | Passed | Passed | **Passed** | Open assessment attachment |
| **TC-CM-103** |  | `FR-CM-23; FR-CM-24` | `UC-CM-13` | Unverified | Passed | **Passed** | Verify Benefit numbers |
| **TC-CM-104** |  | `FR-CM-23; FR-CM-24` | `UC-CM-13` | Unverified | Passed | **Passed** | Verify TIN |
| **TC-CM-105** | Statutory verification | `FR-CM-24` | `UC-CM-12` | Passed | Not Executed | **Passed** | Hide Verify for ordinary profile link |
| **TC-CM-106** | Statutory verification | `FR-CM-24` | `UC-CM-12` | Passed | Not Executed | **Passed** | Hide Verify for invalid verification type |
| **TC-CM-107** |  | `FR-CM-25; FR-CM-26` | `UC-CM-04` | Passed | Not Executed | **Passed** |  |
| **TC-CM-108** | Crew export | `FR-CM-25` | `UC-CM-04` | Passed | Not Executed | **Passed** | Export unavailable for Applicant status |
| **TC-CM-109** |  | `FR-CM-27; FR-CM-28` | `UC-CM-11` | Passed | Not Executed | **Passed** |  |
| **TC-CM-110** |  | `FR-CM-27; FR-CM-28` | `UC-CM-11` | Passed | Not Executed | **Passed** |  |
| **TC-CM-111** |  | `FR-CM-29; FR-CM-31` | `UC-CM-25` | Passed | Not Executed | **Passed** |  |
| **TC-CM-112** | Releasing checklist | `FR-CM-31` | `UC-CM-25` | Passed | Not Executed | **Passed** | Require specific vessel |
| **TC-CM-113** | Releasing checklist | `FR-CM-29` | `UC-CM-25` | Passed | Not Executed | **Passed** | Checklist unavailable outside Line Up |
| **TC-CM-114** | Releasing checklist | `FR-CM-30` | `UC-CM-25` | Passed | Not Executed | **Passed** | Documentation Officer: permitted checklist access |
| **TC-CM-115** | Releasing checklist | `FR-CM-30` | `UC-CM-25` | Passed | Not Executed | **Passed** | Admin: permitted checklist access |
| **TC-CM-116** | Releasing checklist | `FR-CM-30` | `UC-CM-25` | Passed | Not Executed | **Passed** | Super-Admin: permitted checklist access |
| **TC-CM-117** | Releasing checklist | `FR-CM-30` | `UC-CM-25; UC-CM-26` | Unverified | Passed | **Passed** | Manning Staff checklist permission |
| **TC-CM-118** | Releasing checklist | `FR-CM-30; SR-09` | `UC-CM-25` | Passed | Not Executed | **Passed** | Deny external-role checklist requests |
| **TC-CM-119** |  | `FR-CM-32` | `UC-CM-26` | Passed | Not Executed | **Passed** |  |
| **TC-CM-120** |  | `FR-CM-33` | `UC-CM-13` | Passed | Not Executed | **Passed** |  |
| **TC-CM-121** |  | `FR-CM-33` | `UC-CM-13` | Passed | Not Executed | **Passed** |  |
| **TC-CM-122** |  | `FR-CM-33` | `UC-CM-14` | Passed | Passed | **Passed** | Applicant search by Rank |
| **TC-CM-123** |  | `FR-CM-33` | `UC-CM-14` | Passed | Passed | **Passed** | Applicant search by Rank type |
| **TC-CM-124** |  | `FR-CM-33` | `UC-CM-13` | Passed | Not Executed | **Passed** |  |
| **TC-CM-125** | Applicant search | `FR-CM-33` | `UC-CM-13` | Unverified | Passed | **Passed** | Applicant search date boundaries |
| **TC-CM-126** | Applicant search | `FR-CM-33` | `UC-CM-13` | Passed | Not Executed | **Passed** | No matching applicants |
| **TC-CM-127** | Applicant search | `FR-CM-33` | `UC-CM-13` | Passed | Not Executed | **Passed** | Applicant result identity and summary |
| **TC-CM-128** | Applicant experience | `FR-CM-34` | `UC-CM-13` | Passed | Not Executed | **Passed** | Vessel experience summary popover |
| **TC-CM-129** | Applicant profile | `FR-CM-35` | `UC-CM-14` | Passed | Not Executed | **Passed** | Applicant profile opens for selected applicant |
| **TC-CM-130** | Applicant profile | `FR-CM-35` | `UC-CM-14` | Passed | Not Executed | **Passed** | Invalid applicant reference |
| **TC-CM-131** | Manual applicant | `FR-CM-36` | `UC-CM-15` | Passed | Not Executed | **Passed** | Open Add Applicant form |
| **TC-CM-132** |  | `FR-CM-36` | `UC-CM-16` | Unverified | Passed | **Passed** | Save valid manual applicant |
| **TC-CM-133** |  | `FR-CM-36` | `UC-CM-16` | Unverified | Passed | **Passed** | Reject missing and malformed manual data |
| **TC-CM-134** |  | `FR-CM-37; FR-CM-38` | `UC-CM-23` | Unverified | Passed | **Passed** | Confirm hiring changes only target applicant |
| **TC-CM-135** |  | `FR-CM-37` | `UC-CM-23` | Passed | Not Executed | **Passed** |  |
| **TC-CM-136** |  | `FR-CM-39; FR-CM-40` | `UC-CM-17` | Passed | Passed | **Passed** | Generate personalized Active link |
| **TC-CM-137** | Encoding link | `FR-CM-39` | `UC-CM-16` | Passed | Not Executed | **Passed** | Default validity is following day |
| **TC-CM-138** |  | `FR-CM-40` | `UC-CM-17` | Passed | Passed | **Passed** | Reject missing name |
| **TC-CM-139** |  | `FR-CM-40` | `UC-CM-17` | Passed | Passed | **Passed** | Reject missing email |
| **TC-CM-140** |  | `FR-CM-40` | `UC-CM-17` | Failed | Passed | **Passed** | Reject missing validity |
| **TC-CM-141** |  | `FR-CM-40` | `UC-CM-17` | Passed | Passed | **Passed** | Reject malformed email |
| **TC-CM-142** |  | `FR-CM-40` | `UC-CM-17` | Passed | Passed | **Passed** | Reject invalid calendar date |
| **TC-CM-143** | Encoding link validation | `FR-CM-39; FR-CM-40` | `UC-CM-17` | Unverified | Passed | **Passed** | Optional position and default validity |
| **TC-CM-144** |  | `FR-CM-41` | `UC-CM-18` | Passed | Passed | **Passed** | Compose encoding email without claiming delivery |
| **TC-CM-145** | Manage links | `FR-CM-42` | `UC-CM-19` | Passed | Passed | **Passed** | Link list fields and status filtering |
| **TC-CM-146** | Manage links | `FR-CM-42` | `UC-CM-18` | Unverified | Passed | **Passed** | Link list with more than fifty records |
| **TC-CM-147** | Manage links | `FR-CM-42` | `UC-CM-18` | Unverified | Passed | **Passed** | Empty filtered link list |
| **TC-CM-148** | Manage links | `FR-CM-43` | `UC-CM-18` | Passed | Not Executed | **Passed** | Past-validity links highlighted |
| **TC-CM-149** |  | `FR-CM-44` | `UC-CM-19` | Passed | Not Executed | **Passed** |  |
| **TC-CM-150** |  | `FR-CM-44` | `UC-CM-19` | Passed | Not Executed | **Passed** |  |
| **TC-CM-151** | Link status | `FR-CM-44` | `UC-CM-19` | Passed | Not Executed | **Passed** | Non-Active links cannot use inline status update |
| **TC-CM-152** | Link status | `FR-CM-44` | `UC-CM-19` | Unverified | Passed | **Passed** | Other selectable lifecycle transitions |
| **TC-CM-153** |  | `FR-CM-45` | `UC-CM-20` | Passed | Not Executed | **Passed** |  |
| **TC-CM-154** |  | `FR-CM-45` | `UC-CM-20` | Passed | Not Executed | **Passed** |  |
| **TC-CM-155** | Bulk expire | `FR-CM-45` | `UC-CM-20` | Passed | Not Executed | **Passed** | No links eligible for bulk expiration |
| **TC-CM-156** |  | `FR-CM-46` | `UC-CM-21` | Passed | Not Executed | **Passed** |  |
| **TC-CM-157** |  | `FR-CM-46` | `UC-CM-21` | Passed | Not Executed | **Passed** |  |
| **TC-CM-158** |  | `FR-CM-46` | `UC-CM-21` | Passed | Not Executed | **Passed** |  |
| **TC-CM-159** | Delete link | `FR-CM-46` | `UC-CM-21` | Passed | Not Executed | **Passed** | Active link deletion unavailable |
| **TC-CM-160** |  | `FR-CM-47` | `UC-CM-23` | Unverified | Passed | **Passed** | Resend existing Active link |
| **TC-CM-161** | Resend link | `FR-CM-47` | `UC-CM-22` | Passed | Not Executed | **Passed** | Resend unavailable for non-Active links |
| **TC-CM-162** |  | `FR-CM-48; FR-CM-50` | `UC-CM-25` | Passed | Passed | **Passed** | Valid Active link opens scoped form |
| **TC-CM-163** |  | `FR-CM-48; FR-CM-49; SR-08` | `UC-CM-25` | Failed | Passed | **Passed** | Deny missing link |
| **TC-CM-164** |  | `FR-CM-48; FR-CM-49; SR-08` | `UC-CM-25` | Failed | Passed | **Passed** | Deny unknown link |
| **TC-CM-165** |  | `FR-CM-48; FR-CM-49; SR-08` | `UC-CM-25` | Passed | Passed | **Passed** | Deny Expired link |
| **TC-CM-166** |  | `FR-CM-48; FR-CM-49; SR-08` | `UC-CM-25` | Passed | Passed | **Passed** | Deny Used link |
| **TC-CM-167** |  | `FR-CM-48; FR-CM-49; SR-08` | `UC-CM-25` | Passed | Passed | **Passed** | Deny Active link with past validity |
| **TC-CM-168** | Self-encoding | `FR-CM-48` | `UC-CM-25` | Passed | Passed | **Passed** | Applicant session cannot browse staff pages |
| **TC-CM-169** | Self-encoding | `FR-CM-44; FR-CM-48; FR-CM-49; SR-08` | `UC-CM-24` | Unverified | Passed | **Passed** | Link expiry cutoff and submit-after-expiry |
| **TC-CM-170** |  | `FR-CM-48` | `UC-CM-25` | Unverified | Passed | **Passed** | Submit valid applicant and consume link |
| **TC-CM-171** |  | `FR-CM-48` | `UC-CM-25` | Unverified | Passed | **Passed** | Validation retains valid entered data |
| **TC-CM-172** | Self-encoding | `FR-CM-48; SR-09` | `UC-CM-25` | Unverified | Passed | **Passed** | Repeated or concurrent submission does not duplicate |
| **TC-CM-173** | Performance | `PR-01` | `UC-CM-01` | Passed | Not Executed | **Passed** | Crew Search loads within 3 seconds |
| **TC-CM-174** | Performance | `PR-01` | `UC-CM-13` | Passed | Not Executed | **Passed** | Applicant Pool loads within 3 seconds |
| **TC-CM-175** | Performance | `PR-01` | `UC-CM-07` | Passed | Not Executed | **Passed** | Crew Profile loads within 3 seconds |
| **TC-CM-176** | Performance | `PR-02` | `UC-CM-01` | Passed | Not Executed | **Passed** | Crew search returns within 2 seconds |
| **TC-CM-177** | Performance | `PR-02` | `UC-CM-13` | Passed | Not Executed | **Passed** | Applicant search returns within 2 seconds |
| **TC-CM-178** | Performance | `PR-03` | `UC-CM-16` | Passed | Not Executed | **Passed** | Link Generation completes within 3 seconds |
| **TC-CM-179** | Performance | `PR-03` | `UC-CM-19` | Passed | Not Executed | **Passed** | Link Status Update completes within 3 seconds |
| **TC-CM-180** | Performance | `PR-04` | `UC-CM-04` | Passed | Not Executed | **Passed** | Crew Excel export completes within 5 seconds |
| **TC-CM-181** | Load | `PR-05` | `UC-CM-01; UC-CM-13; UC-CM-16; UC-CM-24` | Unverified | Passed | **Passed** | 50 concurrent internal users |
| **TC-CM-182** | Load | `PR-06` | `UC-CM-01; UC-CM-13; UC-CM-16; UC-CM-24` | Unverified | Passed | **Passed** | 100 concurrent total users |
| **TC-CM-183** |  | `SR-01` | `UC-CM-01; UC-CM-13` | Passed | Not Executed | **Passed** |  |
| **TC-CM-184** | Role definition | `SR-02` | `UC-CM-01; UC-CM-13` | Unverified | Passed | **Passed** | Confirm updated UMMI role terminology |
| **TC-CM-185** | Account approval | `N/A (SR-03 removed)` | `N/A` | Unverified | Out of Scope | **Out of Scope** | Supplier approval requirement retired |
| **TC-CM-186** | Credential storage | `SR-04` | `N/A` | Unverified | Passed | **Passed** | Review credential-storage controls |
| **TC-CM-187** | Transport security | `SR-05` | `UC-CM-01; UC-CM-07; UC-CM-11; UC-CM-24` | Failed | Passed | **Passed** | HTTPS for module traffic |
| **TC-CM-188** |  | `SR-06` | `UC-CM-08; UC-CM-11; UC-CM-12` | Unverified | Passed | **Passed** | Protected document and assessment access |
| **TC-CM-189** |  | `FR-CM-79` | `UC-CM-07` | Passed | Passed | **Passed** | Open the dedicated CCL and select a vessel |
| **TC-CM-190** |  | `FR-CM-79` | `UC-CM-07` | Passed | Passed | **Passed** | Display the selected vessel roster |
| **TC-CM-191** |  | `FR-CM-79` | `UC-CM-07` | Passed | Passed | **Passed** | Select an eligible outgoing crew member |
| **TC-CM-192** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Nominate an available reliever |
| **TC-CM-193** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Approve a reliever nomination |
| **TC-CM-194** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Reject a reliever nomination |
| **TC-CM-195** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Cancel a nomination |
| **TC-CM-196** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Create a crew-change schedule |
| **TC-CM-197** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Bulk-apply schedule values |
| **TC-CM-198** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Finalize schedule and generate EOC |
| **TC-CM-199** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Prevent invalid or duplicate finalization |
| **TC-CM-200** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Amend a finalized schedule |
| **TC-CM-201** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Cancel a finalized schedule |
| **TC-CM-202** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Enforce CCL action permissions |
| **TC-CM-203** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Manually record vessel and On Board status after sign-on |
| **TC-CM-204** |  | `FR-CM-79` | `UC-CM-07` | Not Executed | Passed | **Passed** | Verify the CCL audit trail |
| **TC-CM-205** |  | `FR-CM-54; FR-CM-68` | `UC-CM-25; UC-CM-28` | Not Executed | Passed | **Passed** | Keep AI assistance optional and preserve manual encoding |
| **TC-CM-206** |  | `FR-CM-55` | `UC-CM-25; UC-CM-28` | Not Executed | Passed | **Passed** | Upload multiple available documents |
| **TC-CM-207** |  | `FR-CM-56; FR-CM-57; SR-10` | `UC-CM-25; UC-CM-28` | Not Executed | Passed | **Passed** | Validate formats, content, readability, and configured limits |
| **TC-CM-208** |  | `FR-CM-58; FR-CM-59` | `UC-CM-28` | Not Executed | Passed | **Passed** | Use native PDF text and OCR when required |
| **TC-CM-209** | AI extraction | `FR-CM-60` | `UC-CM-28` | Not Executed | Passed | **Passed** | Extract present information without inventing missing values |
| **TC-CM-210** |  | `FR-CM-61; FR-CM-62` | `UC-CM-28` | Not Executed | Passed | **Passed** | Validate output and map only approved fields |
| **TC-CM-211** | AI reference mapping | `FR-CM-63` | `UC-CM-28` | Not Executed | Passed | **Passed** | Require human selection for unmatched references |
| **TC-CM-212** |  | `FR-CM-64` | `UC-CM-28` | Not Executed | Passed | **Passed** | Accept, edit, reject, and manually complete suggestions |
| **TC-CM-213** |  | `FR-CM-65` | `UC-CM-28` | Not Executed | Passed | **Passed** | Preserve existing values during partial, failed, cancelled, or repeated extracti |
| **TC-CM-214** | AI conflicts | `FR-CM-66` | `UC-CM-28` | Not Executed | Passed | **Passed** | Display conflicting values with their sources |
| **TC-CM-215** |  | `FR-CM-67` | `UC-CM-28` | Not Executed | Passed | **Passed** | Require approval before replacing values |
| **TC-CM-216** |  | `FR-CM-70` | `UC-CM-28` | Not Executed | Passed | **Passed** | Require AI-processing acknowledgment |
| **TC-CM-217** |  | `FR-CM-69; SR-18` | `UC-CM-28` | Not Executed | Passed | **Passed** | Clean temporary artifacts without deleting retained source documents |
| **TC-CM-218** |  | `FR-CM-71; SR-17` | `UC-CM-25; UC-CM-28` | Not Executed | Passed | **Passed** | Record privacy-safe AI and document events |
| **TC-CM-219** |  | `FR-CM-72; SR-14` | `UC-CM-25; UC-CM-28` | Not Executed | Passed | **Passed** | Prevent AI from directly writing applicant or personnel records |
| **TC-CM-220** |  | `FR-CM-73` | `UC-CM-25; UC-CM-28` | Not Executed | Passed | **Passed** | Retain and associate accepted original uploads |
| **TC-CM-221** |  | `FR-CM-74; SR-12` | `UC-CM-15; UC-CM-28` | Not Executed | Passed | **Passed** | Enforce authorized staff document access |
| **TC-CM-222** |  | `FR-CM-75` | `UC-CM-25` | Not Executed | Unverified | **Unverified** | Save record, document links, and link status atomically |
| **TC-CM-223** | AI source traceability | `FR-CM-76` | `UC-CM-28` | Not Executed | Passed | **Passed** | Identify source document and page |
| **TC-CM-224** |  | `FR-CM-77` | `UC-CM-28` | Not Executed | Passed | **Passed** | Distinguish suggestion and review states |
| **TC-CM-225** |  | `FR-CM-78` | `UC-CM-28` | Not Executed | Passed | **Passed** | Review repeating records and duplicates |
| **TC-CM-226** |  | `PR-07` | `UC-CM-28` | Not Executed | Passed | **Passed** | Return suggestions or failure within 60 seconds |
| **TC-CM-227** |  | `PR-08; FR-CM-68` | `UC-CM-28` | Not Executed | Passed | **Passed** | Recover from timeout or unavailable AI service |
| **TC-CM-228** |  | `SR-11; SR-13` | `UC-CM-28` | Not Executed | Passed | **Passed** | Protect processing communications and minimize provider data |
| **TC-CM-229** |  | `SR-15; SR-16` | `UC-CM-28` | Not Executed | Passed | **Passed** | Treat document content as untrusted and display it safely |

---

## 4. Requirements With No Explicit Mapped Test Cases

The following requirements defined in `ByteMe SRS - UMMI.docx` have no mapped test case in the workbook repository:

1. **`SR-07` (Audit Logging of Critical User Activities):**
   - *Specification:* The system shall log critical user activities such as profile views, applicant hiring, and link generation for auditing purposes.
   - *Coverage Status:* Labeled **No mapped test** in the RTM tab. Lacks a dedicated standalone test case in the workbook repository.
   - *Audit Note on Password Enforcement:* Password complexity enforcement cannot be declared verified merely because strong passwords were used during administrative provisioning (`FIX-CM-001`). Dedicated negative password complexity validation testing remains an open gap.

2. **`SR-03` (Supplier Account Approval — Retired Scope):**
   - *Specification:* Earlier drafts contained supplier account approval workflows. Formally removed from `ByteMe SRS - UMMI.docx`. `TC-CM-185` is classified as **Out of Scope** (`REQ-CM-005`).

---
*Reviewed and codified in accordance with authoritative QA delivery governance.*
